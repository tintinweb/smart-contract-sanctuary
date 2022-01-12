/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.8.0;
contract Checklength {  
    function mine(string memory s) public pure returns (uint256) {
    return bytes(s).length;
    }
}