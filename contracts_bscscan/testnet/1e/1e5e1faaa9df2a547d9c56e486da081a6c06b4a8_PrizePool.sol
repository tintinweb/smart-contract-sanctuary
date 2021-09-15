/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: Unlicensed

/*


Can we send tokens without the fees!

Need to enter... who to send to, how much to send

Add this contract address to 'Excluded from Fee' on Muso 


*/

pragma solidity ^0.8.2;





abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x9266EfB1f7938D564C5cbf9a2De6545Df3e463BF;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    
}




contract PrizePool is Ownable{
    
     //public wallets for people to check the current prize pool value 
     address payable public wallet_prizePool_1 = payable(0xcf427cffaF76027Ee1bc5540F283cEa650ee96bf);
     address payable public wallet_prizePool_2 = payable(0xA3C0A499C29E5e73Ee8540BCc9508987cACae495);
     address payable public wallet_prizePool_3 = payable(0x7D15025D421c5fF186017e8809C584De9036772A);
     
     
     //dev fee wallet
     address payable private wallet_devFee = payable(0x9266EfB1f7938D564C5cbf9a2De6545Df3e463BF);
     
    
  
  
    
    
    receive() external payable {}
    
    
    //manually purge BNB from contract to promo wallet
    function distributeSpecificBNB(uint256 bnbAmount) public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        if (bnbAmount > contractBNB) {bnbAmount = contractBNB;}
        
        uint256 toDev = bnbAmount/3;
        uint256 prizePool = bnbAmount-toDev;
        uint256 splitPrizePool = prizePool/6;
        uint256 toFirst = splitPrizePool*3;
        uint256 toSecond = splitPrizePool*2;
        uint256 toThird = splitPrizePool;

        sendToWallet(toDev, wallet_devFee);
        sendToWallet(toFirst, wallet_prizePool_1);
        sendToWallet(toSecond, wallet_prizePool_2);
        sendToWallet(toThird, wallet_prizePool_3);
        
        }
    }
    
     //manually purge ALL BNB from contract to promo wallet
    function distributeAllBNB() public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {

        uint256 toDev = contractBNB/3;
        uint256 prizePool = contractBNB-toDev;
        uint256 splitPrizePool = prizePool/6;
        uint256 toFirst = splitPrizePool*3;
        uint256 toSecond = splitPrizePool*2;
        uint256 toThird = splitPrizePool;

        sendToWallet(toDev, wallet_devFee);
        sendToWallet(toFirst, wallet_prizePool_1);
        sendToWallet(toSecond, wallet_prizePool_2);
        sendToWallet(toThird, wallet_prizePool_3);
        }
        
    }
    
    
    
    
     function sendToWallet(uint256 amount, address payable sendTo) private {
            sendTo.transfer(amount);
        }
        


        //they need to add the token to the contract first
        //once the token is on the contract need to forward it to the 'to' address

        // SYM TESTNET CONTRACT ID
        // 0x5e3D1c13c764a7C0C27B8985FC715BfBdF6B7174 




   
        
        
    }