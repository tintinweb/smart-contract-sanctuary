/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

pragma solidity ^0.8.0;

interface IERC20{
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract UsdcBank{
    IERC20 public usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    mapping (address => uint) userBal;
    
    function deposit(uint amount) public{
        // transfer tokens to contract address
        require(usdc.transferFrom(msg.sender, address(this), amount) == true);
        // update userBal
        userBal[msg.sender] += amount;
    }
    
    function withdraw(uint amount) public{
        // makes sure user only withdraw's what he/she deposited 
        require(userBal[msg.sender] >= amount);
        // withdraw from contract address
        require(usdc.transfer(msg.sender, amount) == true);
        // update userBal
        userBal[msg.sender] -= amount;
    }
}