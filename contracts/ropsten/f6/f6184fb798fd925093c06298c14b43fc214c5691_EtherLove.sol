/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity ^0.4.18;

contract EtherLove {
   
    address Account2;
    address Owner;
  
   string loverOne;
   string loverTwo;
   string Contract;

   uint amount;
 
  constructor() public{
        Account2 = 0xa8ed6c761D14FDD5CBEA97911e718929b500b9E6;
        Owner = msg.sender;
    }



function () payable external{}
   
   function setInfo(string _loverOne, string _loverTwo,string _Contract,uint _amount) public payable {
       loverOne = _loverOne;
       loverTwo = _loverTwo;
       Contract = _Contract;
       amount = _amount;
       
        address(uint160(Account2)).transfer(amount);
      
       
       
   }


   function getLovers() public constant returns (string,string,string) {
       return (loverOne, loverTwo,Contract);
   }   
}