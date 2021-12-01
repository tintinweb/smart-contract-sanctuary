/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.8.7;

contract Sum {

    uint public n;

    constructor () {
        n = 0;
    }

    function setN(uint _n) public {
        n = _n;
    }
}