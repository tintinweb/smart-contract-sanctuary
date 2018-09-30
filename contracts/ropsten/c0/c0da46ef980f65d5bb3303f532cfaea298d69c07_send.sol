pragma solidity ^0.4.25;
contract send{
    mapping (address => uint) balances;
    function sendbal(address to,uint amount) public payable{
        if(balances[msg.sender]>amount)
        {
        balances[msg.sender]-=amount;
        balances[to]+=amount;
        }
   }
}