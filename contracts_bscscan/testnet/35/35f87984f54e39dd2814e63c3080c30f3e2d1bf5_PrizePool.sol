/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;



interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




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
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
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
    
  
     address payable private wallet_prizePool_1 = payable(0xcf427cffaF76027Ee1bc5540F283cEa650ee96bf);
     address payable private wallet_prizePool_2 = payable(0xA3C0A499C29E5e73Ee8540BCc9508987cACae495);
     address payable private wallet_prizePool_3 = payable(0x7D15025D421c5fF186017e8809C584De9036772A);
     address payable private wallet_devFee = payable(0x9266EfB1f7938D564C5cbf9a2De6545Df3e463BF);
     
    
  
  
    
    
    receive() external payable {}
    
    
     //manually purge BNB from contract to promo wallet
    function distributeBNB(uint256 bnbAmount) public onlyOwner {
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
    
    
    
     function sendToWallet(uint256 amount, address payable sendTo) private {
            sendTo.transfer(amount);
        }

        // SEND RANDOM 

    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }



        
   
        
        
    }