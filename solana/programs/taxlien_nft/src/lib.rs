use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Transfer};

declare_id!("TaxL1enNFT1111111111111111111111111111111");

#[program]
pub mod taxlien_nft {
    use super::*;

    /// Initialize the program
    pub fn initialize(ctx: Context<Initialize>, treasury: Pubkey) -> Result<()> {
        let state = &mut ctx.accounts.state;
        state.authority = ctx.accounts.authority.key();
        state.treasury = treasury;
        state.next_token_id = 0;
        state.total_fees_collected = 0;
        state.bump = *ctx.bumps.get("state").unwrap();
        Ok(())
    }

    /// Mint a new Tax Lien NFT
    pub fn mint_tax_lien(
        ctx: Context<MintTaxLien>,
        data: TaxLienData,
        payment: u64,
    ) -> Result<()> {
        // Validations
        require!(data.state.len() > 0, TaxLienError::StateRequired);
        require!(data.county.len() > 0, TaxLienError::CountyRequired);
        require!(data.parcel_id.len() > 0, TaxLienError::ParcelIdRequired);
        require!(data.face_amount >= MIN_INVESTMENT, TaxLienError::InvestmentTooLow);
        require!(data.face_amount <= MAX_INVESTMENT, TaxLienError::InvestmentTooHigh);
        require!(data.property_value > data.face_amount, TaxLienError::InvalidPropertyValue);
        require!(data.apr >= MIN_APR && data.apr <= MAX_APR, TaxLienError::InvalidAPR);

        // Calculate service fee
        let service_fee = (data.face_amount * SERVICE_FEE_PERCENT) / 100;
        let total_required = data.face_amount + service_fee;
        require!(payment >= total_required, TaxLienError::InsufficientPayment);

        // Create NFT account
        let state = &mut ctx.accounts.state;
        let tax_lien = &mut ctx.accounts.tax_lien;
        
        tax_lien.id = state.next_token_id;
        tax_lien.state = data.state;
        tax_lien.county = data.county;
        tax_lien.parcel_id = data.parcel_id;
        tax_lien.face_amount = data.face_amount;
        tax_lien.property_value = data.property_value;
        tax_lien.apr = data.apr;
        tax_lien.issue_date = Clock::get()?.unix_timestamp;
        tax_lien.status = TaxLienStatus::Pending;
        tax_lien.investor = ctx.accounts.investor.key();
        tax_lien.invested_amount = payment;
        tax_lien.redemption_date = 0;
        tax_lien.bump = *ctx.bumps.get("tax_lien").unwrap();

        // Update state
        state.next_token_id += 1;
        state.total_fees_collected += service_fee;

        // Transfer service fee to treasury
        let cpi_accounts = Transfer {
            from: ctx.accounts.investor_token_account.to_account_info(),
            to: ctx.accounts.treasury_token_account.to_account_info(),
            authority: ctx.accounts.investor.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
        token::transfer(cpi_ctx, service_fee)?;

        emit!(TaxLienMinted {
            token_id: tax_lien.id,
            investor: ctx.accounts.investor.key(),
            parcel_id: tax_lien.parcel_id.clone(),
            face_amount: data.face_amount,
            apr: data.apr,
        });

        Ok(())
    }

    /// Update NFT status (deployer only)
    pub fn update_status(
        ctx: Context<UpdateStatus>,
        new_status: TaxLienStatus,
    ) -> Result<()> {
        let tax_lien = &mut ctx.accounts.tax_lien;
        
        // Validate status transition
        require!(
            is_valid_status_transition(&tax_lien.status, &new_status),
            TaxLienError::InvalidStatusTransition
        );

        let old_status = tax_lien.status.clone();
        tax_lien.status = new_status.clone();

        // Handle redemption date
        if new_status == TaxLienStatus::Redeemed {
            tax_lien.redemption_date = Clock::get()?.unix_timestamp;
        }

        emit!(StatusUpdated {
            token_id: tax_lien.id,
            old_status,
            new_status,
        });

        Ok(())
    }

    /// Redeem NFT and receive returns
    pub fn redeem_nft(ctx: Context<RedeemNFT>) -> Result<()> {
        let tax_lien = &ctx.accounts.tax_lien;
        
        require!(
            tax_lien.status == TaxLienStatus::Redeemed,
            TaxLienError::NotRedeemable
        );

        // Calculate returns
        let duration = tax_lien.redemption_date - tax_lien.issue_date;
        let annual_return = (tax_lien.face_amount as u128 * tax_lien.apr as u128) / 10000;
        let returns = (annual_return * duration as u128) / SECONDS_PER_YEAR;
        let payout = tax_lien.face_amount + returns as u64;

        // Transfer payout to investor
        let seeds = &[
            b"state",
            &[ctx.accounts.state.bump],
        ];
        let signer = &[&seeds[..]];

        let cpi_accounts = Transfer {
            from: ctx.accounts.vault_token_account.to_account_info(),
            to: ctx.accounts.investor_token_account.to_account_info(),
            authority: ctx.accounts.state.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new_with_signer(cpi_program, cpi_accounts, signer);
        token::transfer(cpi_ctx, payout)?;

        emit!(NFTRedeemed {
            token_id: tax_lien.id,
            investor: tax_lien.investor,
            payout,
            returns: returns as u64,
        });

        Ok(())
    }

    /// Claim property (when tax not paid)
    pub fn claim_property(ctx: Context<ClaimProperty>) -> Result<()> {
        let tax_lien = &ctx.accounts.tax_lien;
        
        require!(
            tax_lien.status == TaxLienStatus::Claimed,
            TaxLienError::NotClaimable
        );

        emit!(PropertyClaimed {
            token_id: tax_lien.id,
            investor: tax_lien.investor,
            property_value: tax_lien.property_value,
        });

        Ok(())
    }
}

// === CONTEXTS ===

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + State::SPACE,
        seeds = [b"state"],
        bump
    )]
    pub state: Account<'info, State>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct MintTaxLien<'info> {
    #[account(mut, seeds = [b"state"], bump = state.bump)]
    pub state: Account<'info, State>,
    
    #[account(
        init,
        payer = investor,
        space = 8 + TaxLienNFT::SPACE,
        seeds = [b"tax_lien", state.next_token_id.to_le_bytes().as_ref()],
        bump
    )]
    pub tax_lien: Account<'info, TaxLienNFT>,
    
    #[account(mut)]
    pub investor: Signer<'info>,
    
    #[account(mut)]
    pub investor_token_account: Account<'info, TokenAccount>,
    
    #[account(mut)]
    pub treasury_token_account: Account<'info, TokenAccount>,
    
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpdateStatus<'info> {
    #[account(seeds = [b"state"], bump = state.bump)]
    pub state: Account<'info, State>,
    
    #[account(mut)]
    pub tax_lien: Account<'info, TaxLienNFT>,
    
    #[account(mut, constraint = authority.key() == state.authority)]
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
pub struct RedeemNFT<'info> {
    #[account(seeds = [b"state"], bump = state.bump)]
    pub state: Account<'info, State>,
    
    #[account(mut, close = investor)]
    pub tax_lien: Account<'info, TaxLienNFT>,
    
    #[account(mut, constraint = investor.key() == tax_lien.investor)]
    pub investor: Signer<'info>,
    
    #[account(mut)]
    pub investor_token_account: Account<'info, TokenAccount>,
    
    #[account(mut)]
    pub vault_token_account: Account<'info, TokenAccount>,
    
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct ClaimProperty<'info> {
    #[account(mut, close = investor)]
    pub tax_lien: Account<'info, TaxLienNFT>,
    
    #[account(mut, constraint = investor.key() == tax_lien.investor)]
    pub investor: Signer<'info>,
}

// === STATE ===

#[account]
pub struct State {
    pub authority: Pubkey,
    pub treasury: Pubkey,
    pub next_token_id: u64,
    pub total_fees_collected: u64,
    pub bump: u8,
}

impl State {
    pub const SPACE: usize = 32 + 32 + 8 + 8 + 1;
}

#[account]
pub struct TaxLienNFT {
    pub id: u64,
    pub state: String,           // 50 bytes max
    pub county: String,          // 50 bytes max
    pub parcel_id: String,       // 50 bytes max
    pub face_amount: u64,
    pub property_value: u64,
    pub apr: u16,
    pub issue_date: i64,
    pub status: TaxLienStatus,
    pub investor: Pubkey,
    pub invested_amount: u64,
    pub redemption_date: i64,
    pub bump: u8,
}

impl TaxLienNFT {
    pub const SPACE: usize = 8 + 50 + 50 + 50 + 8 + 8 + 2 + 8 + 1 + 32 + 8 + 8 + 1;
}

// === TYPES ===

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub enum TaxLienStatus {
    Pending,
    Invested,
    Redeemed,
    Claimed,
    Cancelled,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct TaxLienData {
    pub state: String,
    pub county: String,
    pub parcel_id: String,
    pub face_amount: u64,
    pub property_value: u64,
    pub apr: u16,
}

// === EVENTS ===

#[event]
pub struct TaxLienMinted {
    pub token_id: u64,
    pub investor: Pubkey,
    pub parcel_id: String,
    pub face_amount: u64,
    pub apr: u16,
}

#[event]
pub struct StatusUpdated {
    pub token_id: u64,
    pub old_status: TaxLienStatus,
    pub new_status: TaxLienStatus,
}

#[event]
pub struct NFTRedeemed {
    pub token_id: u64,
    pub investor: Pubkey,
    pub payout: u64,
    pub returns: u64,
}

#[event]
pub struct PropertyClaimed {
    pub token_id: u64,
    pub investor: Pubkey,
    pub property_value: u64,
}

// === ERRORS ===

#[error_code]
pub enum TaxLienError {
    #[msg("State required")]
    StateRequired,
    #[msg("County required")]
    CountyRequired,
    #[msg("Parcel ID required")]
    ParcelIdRequired,
    #[msg("Investment too low")]
    InvestmentTooLow,
    #[msg("Investment too high")]
    InvestmentTooHigh,
    #[msg("Invalid property value")]
    InvalidPropertyValue,
    #[msg("Invalid APR")]
    InvalidAPR,
    #[msg("Insufficient payment")]
    InsufficientPayment,
    #[msg("Invalid status transition")]
    InvalidStatusTransition,
    #[msg("Not redeemable")]
    NotRedeemable,
    #[msg("Not claimable")]
    NotClaimable,
}

// === CONSTANTS ===

const MIN_INVESTMENT: u64 = 10_000_000; // 0.01 SOL (in lamports)
const MAX_INVESTMENT: u64 = 1_000_000_000_000; // 1000 SOL
const SERVICE_FEE_PERCENT: u64 = 3;
const MIN_APR: u16 = 800;  // 8%
const MAX_APR: u16 = 2400; // 24%
const SECONDS_PER_YEAR: u128 = 31_536_000;

// === HELPERS ===

fn is_valid_status_transition(from: &TaxLienStatus, to: &TaxLienStatus) -> bool {
    match (from, to) {
        (TaxLienStatus::Pending, TaxLienStatus::Invested) => true,
        (TaxLienStatus::Pending, TaxLienStatus::Cancelled) => true,
        (TaxLienStatus::Invested, TaxLienStatus::Redeemed) => true,
        (TaxLienStatus::Invested, TaxLienStatus::Claimed) => true,
        _ => false,
    }
}

