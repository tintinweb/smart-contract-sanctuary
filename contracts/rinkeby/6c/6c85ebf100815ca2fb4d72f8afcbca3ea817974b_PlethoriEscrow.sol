/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20{
     function totalSupply() external view returns (uint256);
     function balanceOf(address account) external view returns (uint256);
     function transfer(address recipient, uint256 amount) external returns (bool);
     function allowance(address owner, address spender) external view returns (uint256);
     function approve(address spender, uint256 amount) external returns (bool);
     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract PlethoriEscrow {

    address public oldToken;
    address public newToken;
    address private admin;
    
    mapping(address => uint256) public balances;


    event Enter(address userAddress,uint256 amount);
    event Claim(address userAddress,uint256 amount);
    event Withdraw(address pleWallet, uint256 amount);

    modifier checkAddress(address token1,address token2) {
      require(token1 != address(0) || token2 != address(0),'The token address can not be zero.');
      _;
   }

   modifier onlyOwner{
       require(msg.sender == admin,'The owner is not admin');
       _;
   }

    
    constructor(address _oldToken,address _newToken) checkAddress(_oldToken,_newToken) {
        oldToken = _oldToken;
        newToken = _newToken;
        admin = msg.sender;
    }



    function getOldTokenBalance(address account) internal view returns(uint256){
        return IERC20(oldToken).balanceOf(account);
    }
    

   
    function enter(uint256 amount) external {
        require(amount > 0,"The amount can not be zero");
        uint256 oldTokenBalance = getOldTokenBalance(msg.sender);
        require(amount <= oldTokenBalance,"Insufficient token amount.");
        require(IERC20(oldToken).transferFrom(msg.sender, address(this), amount),"Insufficient token allowance");
        balances[msg.sender] = balances[msg.sender] + amount;
        emit Enter(msg.sender,amount);
 
    }
    
    function claim(uint256 amount) external {
        require(amount > 0,"The amount can not be zero");
        require(amount <= balances[msg.sender],"Insufficient token amount");
        require(IERC20(newToken).transfer(msg.sender, amount),"Could not transfer amount.");
        balances[msg.sender] = balances[msg.sender] - amount;
        emit Claim(msg.sender,amount);
    }


   function withdrawOldToken(uint256 amount,address pleWallet) external onlyOwner{
       require(amount > 0,"The amount can not be zero.");
       require(pleWallet != address(0),"This address can not be zero."); 
       IERC20(oldToken).transfer(pleWallet, amount);
       emit Withdraw(pleWallet,amount);
   }
}