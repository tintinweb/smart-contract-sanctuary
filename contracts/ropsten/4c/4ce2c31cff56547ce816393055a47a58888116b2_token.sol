/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity ^0.8.0;

contract token{
    string name;
    string symbol;
    uint totalSupply;
    uint decimals;
    uint gasfee;
    address public owner;

    mapping (address=>uint) public balanceOf;

   constructor(uint _decimals,uint _totalSupply,uint _gasfee,string memory _name,string memory _symbol) public{
       decimals = _decimals;
       totalSupply = _totalSupply*10**18;
       gasfee=_gasfee;
       owner=msg.sender;
       balanceOf[owner]=totalSupply;
       name = _name;
       symbol = _symbol;
   }

   modifier enoughBalance(uint amount){
       require(balanceOf[msg.sender]>=amount);
       _;
   }

function transfer(address to,uint amount) public payable enoughBalance(amount){
    require(amount>0,"inefficient amount");
    balanceOf[msg.sender] -= amount;
    balanceOf[to] +=amount;
}

}