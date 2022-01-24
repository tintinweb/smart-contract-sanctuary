/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity ^0.4.24;

contract Calculator {
    uint c;

    function add(uint a, uint b) public {
        c = a + b;
    }

    function sub(uint a, uint b) public {
        c = a - b;
    }

    function mul(uint a, uint b) public {
        c = a * b;
    }

    function div(uint a, uint b) public {
        require(b > 0, "The second parameter should be larger than 0");

        c = a / b;
    }

    function getResult() public view returns (uint x) {
        return c;
    }
}