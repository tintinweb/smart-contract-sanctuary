/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.4.26;
  
// Creating a contract
contract SimpleContract
{
  // Defining a function to
  // return a string
  function get_output() public pure returns (string) 
  {
      return ("Hi, your contract ran successfully");
  }
}