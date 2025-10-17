import React, { useState } from 'react';
import { Principal } from '@dfinity/principal';
import StatusMessage from './StatusMessage';
const TokenSender = ({ actor, updateSupply, decimals }) => {
    const [fromSubaccount, setFromSubaccount] = useState('');
    const [address, setAddress] = useState('');
    const [NFTName, setNFTName] = useState('');
    const [description, setDescription] = useState('');
    const [amount, setAmount] = useState();
    const [status, setStatus] = useState({ message: '', isSuccess: null });
    const handleSendTransaction = async (e) => {
        e.preventDefault();
        try {
            /*
            const result = await actor.icrc1_transfer({
              to: {
                owner: Principal.fromText(address),
                subaccount: []
              },
              fee: [],
              memo: [],
              from_subaccount: fromSubaccount ? [fromSubaccount] : [],
              created_at_time: [],
              amount: amount * Number(10 ** Number(decimals))
            });*/
            const result = await actor.icrcX_mint({
                token_id: 0,
                to: {
                    owner: Principal.fromText(address),
                    //subaccount: []
                },
                metadata: {
                    "icrc97:metadata": {
                        "name": NFTName,
                        "description": description,
                        "assets": {
                            "url": "https://taxlien.online/image/PIA18249/12345.jpg",
                            "mime": "image/jpeg",
                            "purpose": "icrc97:image"
                        }
                    }
                },
                //memo: [],
                override: true,
                //created_at_time: []
            });
            if ('Ok' in result) {
                setStatus({ message: 'Transfer successful', isSuccess: true });
                updateSupply();
            }
            else if ('Err' in result) {
                if ('InsufficientFunds' in result.Err) {
                    setStatus({
                        message: `Transfer failed: Insufficient funds. Available balance: ${result.Err.InsufficientFunds.balance}`,
                        isSuccess: false
                    });
                }
                else {
                    setStatus({
                        message: `Transfer failed: ${Object.keys(result.Err)[0]}`,
                        isSuccess: false
                    });
                }
            }
        }
        catch (error) {
            console.error('Transfer failed:', error);
            setStatus({
                message: 'Transfer failed: Unexpected error',
                isSuccess: false
            });
        }
    };
    const inputFields = [
        /*
        {
          name: 'fromSubaccount',
          value: fromSubaccount,
          setter: setFromSubaccount,
          placeholder: 'From Subaccount (optional)',
          type: 'text',
          required: false
        },*/
        {
            name: 'address',
            value: address,
            setter: setAddress,
            placeholder: 'Recipient Address',
            type: 'text',
            required: true
        },
        {
            name: 'NFTName',
            value: NFTName,
            setter: setNFTName,
            placeholder: 'NFT Name',
            type: 'text',
            default: 'Tax Lien NFT ...',
            required: true
        },
        {
            name: 'description',
            value: description,
            setter: setDescription,
            placeholder: 'Description',
            type: 'text',
            default: 'NFT for Tax Lien, USA, FL, POLK, ID:...',
            required: true
        },
        /*
        {
          name: 'amount',
          value: amount,
          setter: setAmount,
          placeholder: 'Amount',
          type: 'number',
          required: true,
          min: '0',
          step: '0.000001'
        }*/
    ];
    return (<div className="mb-8 rounded-lg bg-white p-8 shadow-md">
      <h2 className="mb-6 text-3xl font-bold text-gray-800">Mint NFT Token</h2>
      <form onSubmit={handleSendTransaction} className="space-y-6">
        {inputFields.map(({ name, value, setter, placeholder, type, required, min, step }) => (<input key={name} type={type} value={value} onChange={(e) => setter(e.target.value)} placeholder={placeholder} required={required} min={min} step={step} className="w-full rounded-md border px-3 py-2"/>))}
        <button type="submit" className="bg-infinite hover:bg-dark-infinite w-full rounded-md px-4 py-2 text-white">
          Mint NFT Token
        </button>
      </form>
      <StatusMessage message={status.message} isSuccess={status.isSuccess}/>
    </div>);
};
export default TokenSender;
