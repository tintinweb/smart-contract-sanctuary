/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

pragma solidity ^0.4.19;

contract SimpleStorage {
    uint public data;
    
    function set(uint x) public {
        data = x;
    }
}