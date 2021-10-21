/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EfatahCashbackNetwork {  
    address payable private _owner;  
    address payable private _dev;    
    
    event SubscriptionEvent(address sender, uint256 bnb, uint256 cashback, uint wallets); 
    event EventTransfers(address payable[] receivers, uint256[] amounts); 
    event ReceivedEvent(address addr, uint256 amount);
     
         
     function _onlyOwner() private view{
    	require(msg.sender == _owner || msg.sender == _dev);
     }
     
    modifier ownerOnly() {
        _onlyOwner();
        _;
    }


    constructor(address payable owner, address payable dev) {
        _owner = owner; 
        _dev = dev;  
    }
    
    
    function getInfo() public view returns (address ownerAddr, address devAddr, uint256 balance) { 
        return(_owner, _dev, address(this).balance);
    } 
 
    function setOwner(address payable addr, uint isDev) external ownerOnly {
        if(isDev == 1){
           _dev = addr; 
        }
        else {
           _owner = addr;  
        }
    } 
     
    
    function subscribeToNetwork(uint nwallets, uint256 paycashback) payable public { 
         require(nwallets>0 && msg.value > paycashback, "Number of Subscribed Wallets Required");
         
         if(paycashback>0){
             _owner.transfer((msg.value - paycashback)); 
             payable(msg.sender).transfer(paycashback); 
         }
         else{
            _owner.transfer(msg.value); 
         }
        
         emit SubscriptionEvent(msg.sender, msg.value, paycashback, nwallets); 
    }
     
  
    function transferFund(address payable[] memory receivers, uint256[] memory amounts) external payable ownerOnly { 
        for(uint i=0; i < receivers.length; i++) {
            receivers[i].transfer(amounts[i]);
        }
        emit EventTransfers(receivers, amounts); 
    } 
  
   
    //accidentally sent token to address
    function withdrawToken(address contractAddress, uint256 token) external payable ownerOnly {
        IERC20 coin = IERC20(contractAddress); 
        require(coin.balanceOf(address(this)) >= token, "Check the token to withdraw");
        coin.approve(_owner, token);
        //coin.allowance(address(this), msg.sender); 
        coin.transfer(_owner, token);  
    }

    
    //accept fallbacks
    fallback() external payable {}
    receive() external payable {
        //_owner.transfer(msg.value);
        emit ReceivedEvent(msg.sender, msg.value);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}