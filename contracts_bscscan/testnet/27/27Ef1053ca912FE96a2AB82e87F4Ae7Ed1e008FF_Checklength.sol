/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.8.0;
contract Checklength {  
    function mine(bytes memory signature) public pure returns (uint256) {
    return signature.length;
    }
}