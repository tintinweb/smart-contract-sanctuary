pragma solidity ^0.4.25;

//string可能導致web3接收問題

contract InfoContract {

   uint Info;
   

   function setInfo(uint _Info) public {
       Info = _Info;
   }

   function getInfo() public constant returns (uint) {
       return Info;
   }
}