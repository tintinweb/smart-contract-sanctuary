/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Contador {
    uint256 count;

    constructor(uint256 _count) {
        count = _count;
    }

    function setCount(uint256 _count) public {
        count = _count;
    }

    function incrementCount() public {
        count += 1;
    }

    function getCount() public view returns(uint256) {
        return count;
    }

    function getNumber() public pure returns(uint256) {
        return 34;
    }

    

}