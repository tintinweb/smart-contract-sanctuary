/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.16 <0.9.0;
contract Storage {
uint storedData;
function set(uint x) public {
storedData = x;
}
function get() public view returns (uint) {
return storedData;
}
}