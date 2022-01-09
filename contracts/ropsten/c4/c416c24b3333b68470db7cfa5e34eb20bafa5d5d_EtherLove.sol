/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

pragma solidity ^0.4.21;

contract EtherLove {

   string loverOne;
   string loverTwo;
   string Contract;

   function setInfo(string _loverOne, string _loverTwo,string _Contract) public {
       loverOne = _loverOne;
       loverTwo = _loverTwo;
       Contract = _Contract;
   }

   function getLovers() public constant returns (string,string,string) {
       return (loverOne, loverTwo,Contract);
   }   
}