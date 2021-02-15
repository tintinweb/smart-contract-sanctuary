/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

//import "./tokens.sol";
abstract contract IERC20 {
    function totalSupply() external virtual view returns (uint256);
    function balanceOf(address tokenOwner) external virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external virtual returns (bool success);
    function approve(address spender, uint256 tokens) external virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external virtual returns (bool success);
    function burnFrom(address account, uint256 amount) public virtual;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract SwapTokensContract {
    
    address public owner;
    address public tokenA;
    address public tokenB;
    
     
    address[] public swappers;
    mapping(address => bool) public hasSwapped;
    mapping(address => bool) public isSwapping;
    

    constructor(address _tokenA, address _tokenB) public {
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender;
    }
   
    
    function swapTokens(uint _amount) public {
       require(_amount > 0, "amount cannot be 0");
         IERC20(tokenA).transferFrom(msg.sender, address(this), _amount);
         IERC20(tokenB).transfer(msg.sender,_amount);
        if(!hasSwapped[msg.sender]) {
            swappers.push(msg.sender);
        }
        isSwapping[msg.sender] = true;
        hasSwapped[msg.sender] = true;
    }
   
  
    
    

   
}