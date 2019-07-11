/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.24;

contract ERC20{
    
function totalsupply() public view returns (uint256);
function balanceof(address _who) public view returns(uint256);
function transfer(address _to, uint256 _value) public returns (bool);
function burnToken(uint256 _value) public returns (bool);
}





contract MYOS is ERC20{
    
    mapping (address => uint256) public balanceOfuser;
    
    uint256 totalTokens;
    string public name;
    string public symbol;
    uint256 public decimals;

constructor() public {
    totalTokens= 1000 * 10**18;
    balanceOfuser[msg.sender]=totalTokens;
    name= "bharti";
    symbol="abc";
    decimals=10;
}
function transfer(address _to, uint256 _value) public returns (bool) {
     require(_value <= balanceOfuser[msg.sender]);
     balanceOfuser[msg.sender] = balanceOfuser[msg.sender]- _value;
     return true;
   }
   
   function balanceof(address _who) public constant returns (uint256 ) {
       return balanceOfuser[_who];
   }
   function totalsupply() public constant returns (uint256){
       return  totalTokens;
   }
   function burnToken(uint256 _value) public returns (bool){
       require(_value>0);
       require (balanceOfuser[msg.sender]>=_value);
       balanceOfuser[msg.sender]= balanceOfuser[msg.sender]-(_value);
       totalTokens= totalTokens-(_value);
       return true;
   }
       
   
   }