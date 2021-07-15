/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.6.12;
 contract test {
     uint256 private _tTotal = 1000000000 * 10**2 * 10**6;
     function totalSupply() public view returns (uint256) {
        return _tTotal;
     }
 }