/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Lockup {


    address payable foilWallet;
    mapping(address => mapping(uint => uint256)) public deposites;
    
    // USDT instance
    IERC20 public usdt;
    
    //event 
    event Deposit(address userAddress,uint indexed side,uint256 amount);
    event Withdraw(uint256 amountAfterPercent);
    
    constructor(address payable _foilWallet,address _usdt) {
        require(_foilWallet != address(0),"The wallet address can not zero.");
        require(_usdt != address(0),"The USDT address can not zero.");
        foilWallet = _foilWallet;
        usdt = IERC20(_usdt);
    }
    
    
    function deposit(uint256 amount,uint side) payable external returns(bool){
        require(msg.value == amount);
        unchecked{
              deposites[msg.sender][side] = deposites[msg.sender][side] + (amount);
        }
        
        emit Deposit(msg.sender,side,amount);
      
        return true;
    }
    
    receive() external payable{
        
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function withdraw(uint256 percentage,uint side) external {
      
        uint256 amount = deposites[msg.sender][side];
        require(amount > 0 ,"Can not withdraw");
        uint256 amountAfterPercent ;
        unchecked{
              amountAfterPercent = amount * percentage / 1e4;
        }
       
        if(side == 1){
             usdt.transfer(foilWallet, amountAfterPercent);
                
        }
        else{
             foilWallet.transfer(amountAfterPercent);
        }
        
        emit Withdraw(amountAfterPercent);
       
    }
}