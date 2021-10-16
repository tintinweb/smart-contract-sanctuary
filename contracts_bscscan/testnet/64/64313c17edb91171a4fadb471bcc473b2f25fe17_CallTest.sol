/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.4.0;

contract CallTest{
    
  function dcall(address implementation, bytes data)  public  {
   require(implementation.delegatecall(data));
  }
}