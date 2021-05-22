pragma solidity >0.6.0;

import "./WalletContract.sol";


contract Ledger {
    
    mapping(address => address) wallets;
    
    
    
    
    constructor()public{
    }
    
    
    function createWallet()public {
        
        require(wallets[msg.sender] == address(0), "wallet already exists for the user");
        
        WalletContract wallet;
        wallet = new WalletContract(msg.sender);
        
        storeWalletaddress(address(wallet), msg.sender);
        
    }
    
    function storeWalletaddress(address walletAddress, address userAddress)private{
        wallets[userAddress] = walletAddress;
    }
    
    function searchWallet(address user)public view returns(address){
        return wallets[user];
        
    }
    
    
    
    
    
    
    
}

//daughter = new DaughterContract(_daughtersName, _daughtersAge);