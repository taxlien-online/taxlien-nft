import React from 'react';
import InternetIdentity from './InternetIdentity';
const Header = ({ actor, setActor, isAuthenticated, setIsAuthenticated, tokenCreated, setTokenCreated }) => {
    const handleDeleteToken = async () => {
        try {
            const result = await actor.delete_token();
            if ('Ok' in result) {
                setTokenCreated(false);
            }
            else if ('Err' in result) {
                console.error('Failed to delete token:', result.Err);
                alert('Failed to delete token: ' + result.Err);
            }
        }
        catch (error) {
            console.error('Error deleting token:', error);
        }
    };
    return (<header className="bg-infinite mb-2 p-4 text-white">
      <div className="mx-auto flex flex-row flex-wrap items-center justify-between gap-2">
        <h1 className="text-4xl font-bold">NFT Wallet</h1>
        <div className="flexitems-center">
          <InternetIdentity setActor={setActor} isAuthenticated={isAuthenticated} setIsAuthenticated={setIsAuthenticated}/>
          {false /*FIX isAuthenticated && tokenCreated*/ && (<button onClick={handleDeleteToken} className="ml-4 transform rounded-lg bg-red-500 px-3 py-1 text-sm font-bold text-white shadow-md transition duration-300 ease-in-out hover:scale-105 hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50">
              Delete Token
            </button>)}
        </div>
      </div>
    </header>);
};
export default Header;
