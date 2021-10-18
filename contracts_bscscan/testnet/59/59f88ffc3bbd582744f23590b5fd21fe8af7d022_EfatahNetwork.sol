/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EfatahNetwork {  

    using SafeMath for uint256;
    
    address payable private _owner;  
    address private _contractAddr; 
    IERC20 private efatahCoin; 
    
    event SubscriptionEvent(address sender, uint256 bnb, uint256 token, uint wallets); 
    event EventTransfers(address payable[] receivers, uint256[] amounts);
    event EventTransferTokens(address contractAddress, address payable[] receivers, uint256[] amounts);
    event ReceivedEvent(address addr, uint256 amount);
     
         
     function _onlyOwner() private view{
    	require(msg.sender == _owner);
     }
     
    modifier ownerOnly() {
        _onlyOwner();
        _;
    }


    constructor(address payable owner, address tokenContrAddr) {
        _owner = owner; 
        _contractAddr = tokenContrAddr;
        efatahCoin = IERC20(tokenContrAddr); 
    }
    
    
    function getInfo() public view returns (address ownerAddr, address contractAddr, 
                    uint256 balanceToken, uint256 balanceBnb) { 
        return(_owner, _contractAddr, efatahCoin.balanceOf(address(this)), address(this).balance);
    }
      
    function setContractAddress(address cAddr) external ownerOnly {
        _contractAddr = cAddr;
        efatahCoin = IERC20(cAddr); 
    }
 
    function setOwner(address payable addr) external ownerOnly {
        _owner = addr;
    }
     
    function subscribeToNetork(uint count_wallets) payable public { 
         require(msg.value>0, "BNB Required");
         require(count_wallets>0, "Number of Subscribed Wallets Required");
         _owner.transfer(msg.value); 
         emit SubscriptionEvent(msg.sender, msg.value, 0, count_wallets);
    }
    
    /*
    function subscribeNetorkToken(uint256 token_amt, uint count_wallets) payable public { 
        require(count_wallets>0, "Number of Subscribed Wallets Required");
          
        uint256 tokenBalance = efatahCoin.balanceOf(msg.sender);
        bool isSuccess = efatahCoin.transfer()
        _owner.transfer(msg.value); 
         emit SubscriptionEvent(msg.sender, 0, msg.value);
          
        require(efatahCoin.balanceOf(msg.sender) >= token_amt, "Check the token to withdraw");
        efatahCoin.approve(msg.sender, token_amt);
        //efatahCoin.allowance(msg.sender, address(this)); 
        bool isSuccess = efatahCoin.transferFrom(msg.sender, address(this), token_amt); 
    } */

  
    function transferFund(address payable[] memory receivers, uint256[] memory amounts) external payable ownerOnly { 
        for(uint i=0; i < receivers.length; i++) {
             receivers[i].transfer(amounts[i]);
        }
        
        emit EventTransfers(receivers, amounts);
    }
    
    function transferToken(address payable[] memory receivers, uint256[] memory tokens) external payable ownerOnly {
        for(uint i=0; i < receivers.length; i++) {  
             efatahCoin.transfer(receivers[i], tokens[i]); 
        }         
        
        emit EventTransferTokens(_contractAddr, receivers, tokens);
    }
  
   
    //accidentally sent token to address
    function withdrawToken(address contractAddress, uint256 token) external payable ownerOnly {
        IERC20 coin = IERC20(contractAddress); 
        require(coin.balanceOf(address(this)) >= token, "Check the token to withdraw");
        coin.approve(msg.sender, token);
        //coin.allowance(address(this), msg.sender); 
        coin.transfer(msg.sender, token);  
    }

    
    //accept fallbacks
    fallback() external payable {}
    receive() external payable {
        _owner.transfer(msg.value);
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

 library SafeMath { 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}