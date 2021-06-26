/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

pragma solidity ^0.8.4;

contract testContract {

    uint256 f;
    uint256 a;

    constructor (uint256 _f) {
        f = _f;
        a = 0;
    }

    function setP(uint256 _f) payable public {
        f = _f;
        a = msg.value;
    }

    function getF () view public returns (uint256) {
        return f;
    }
    
    function getA () view public returns (uint256) {
        return a;
    }
}