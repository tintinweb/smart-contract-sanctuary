/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity 0.6.0;

contract Storage {
    
 address payable private owner;
 
 string TokenName="immanent";
 string TokenSymbol ="immi";
 uint totalSupply = 1000;
 
 constructor() public{
 owner = msg.sender;
 } 
 
 mapping(address => uint) balances;
 
function getInfo() public view returns(string memory,string memory,uint){
    string memory _TokenName = TokenName;
    string memory _TokenSymbol = TokenSymbol;
    uint _totalSupply = totalSupply;
    
    return(_TokenName,_TokenSymbol,_totalSupply);
}

function payment(address payable _to , uint value) public returns(bool){
    require( totalSupply >= value,"wrong value");
    totalSupply -= value;
    balances[_to] += value;
    return (true);
}
function balance(address addr) public view returns(uint){
    return balances[addr];
}

 function close() public { 
  selfdestruct(owner); 
 }
}