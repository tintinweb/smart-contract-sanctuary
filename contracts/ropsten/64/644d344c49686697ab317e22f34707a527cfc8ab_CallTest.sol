/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.4.0;

contract CallTest{
    
  function upgradeToAndCall(address implementation, bytes data)  public  {
   require(implementation.delegatecall(data));
  }
}