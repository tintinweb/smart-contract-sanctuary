/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.0;

library SafeMath { // Only relevant functions
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  assert(b <= a);
  return a - b;
}
function add(uint256 a, uint256 b) internal pure returns (uint256)   {
  uint256 c = a + b;
  assert(c >= a);
  return c;
}
}



contract doco 
{
    
    uint256 public totalSupply_;
    bytes32 public name_;
    bytes32 public symbol_;
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
   
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to,uint tokens);
 

    constructor( ) public {

    //     name = "DOCOTEST TOKEN2";
    //     symbol = "DOCOTEST2";
        name_ = "0x444f434f544553542056322e30";
        symbol_ = "0x444f434f5445535432";
      
        totalSupply_ = 100000000000000000000000000;
    //   // seller = payable(msg.sender);
        balances[msg.sender] = totalSupply_;
    }
    
    function balanceOf(address tokenOwner) private view returns (uint) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver,uint numTokens) private returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate,uint numTokens) private returns (bool) {
        
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner,address delegate) private view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) private  returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function() external payable{}

}