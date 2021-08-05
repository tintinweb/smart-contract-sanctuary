/**
 *Submitted for verification at Etherscan.io on 2020-06-04
*/

pragma solidity ^0.6.4;

contract brightIDsponsor {

 event Sponsor(address);

 // sponsor any address that attempts to call a function other than sponsor() in this contract.
 fallback() external payable {
  sponsor(msg.sender);
 }

 // sponsor any address that sends a transaction to this contract.
 receive() external payable {
   sponsor(msg.sender);
 }

 // sponsor any address provided as a parameter.
 function sponsor(address add) public {
   emit Sponsor(add);
 }
}