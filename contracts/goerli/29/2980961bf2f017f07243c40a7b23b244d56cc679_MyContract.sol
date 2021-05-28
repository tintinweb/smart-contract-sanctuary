/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.8.0;

contract MyContract {
 constructor () {}
 
 function f(uint256 n) public pure returns (uint256)  {
    uint256 j=0;
     while(j<n){
         j=j+1;
     }

 return j;
 }
}