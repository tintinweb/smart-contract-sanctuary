/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.5.0;
contract MyContract{
    
string public tokenname;
string public symbol;
uint public totalSupply; 
uint public decimal ; 

address public owner;

mapping(address => mapping(address => uint)) allowed;

event Transfer(address indexed _from, address indexed _to, uint value);
event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
 
mapping(address=>uint) balances;
    
      constructor () public{
        tokenname = &#39;Noopur&#39;;
        symbol = "NPR";
        decimal = 0.0;
        totalSupply = 100;
        owner  =  msg.sender;
        balances[msg.sender] =  totalSupply;
    }
    
   function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - (_value);
        balances[_to] = balances[_to]+ (_value);
        return true;
    }
    
     function balanceOf(address _of) public view returns (uint balance) {
        return balances[_of];
    }
}