/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

 // safemath library
    library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
 }

contract Netleon{
    
   
     string public constant name = "Netleon";
     string public constant symbol = "NTL";
     uint8 public constant decimal = 18;
     uint256 totalSupply;
     using SafeMath for uint256;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed source, address indexed to, uint tokens);
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    // Constructor to add balances to each account
    constructor(uint256 total) public{
        totalSupply = total;
        balances[msg.sender]=totalSupply;
    }
    
    // function to transfer/send tokens to a person
    function transfer(address receiver, uint256 numTokens) public returns(bool)
    {
        require(numTokens <= balances[msg.sender],"Insufficient Balance");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[msg.sender].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    // function to allow a delegate/another person to spend tokens
    function approve(address delegate, uint256 numTokens) public returns(bool){
        require(numTokens <= balances[msg.sender],"Insufficient Balance");
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    // function to sell tokens to a third party/buyer through the delegate     
    function transferFrom(address owner, address buyer, uint256 numTokens) public returns(bool)
    {
        require(numTokens <= balances[owner], "Tokens exceeded Balance of Owner");
        require(numTokens <= allowed[owner][msg.sender], "Token exceeded allowed tokens");
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    //function to view balances
    function viewBalance(address owner) public view returns(uint)
    {
        return balances[owner];
    }
    
    // function to view total totalSupply
    function totalSup() public view returns(uint)
    {
        return totalSupply;
    }
    
    // function to view allowed tokens spendable by the delegate
    function allow(address owner, address delegate) public view returns(uint)
    {
        return allowed[owner][delegate];
    }
    
    
    
    
    
}