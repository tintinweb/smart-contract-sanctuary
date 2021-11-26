/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

error TestError(uint256);

contract Test {
    uint256 x = 5;
    uint256 y = 0;

    function testFunction() external returns(uint256) {
        ++x;
        return x/y;
    }

    function testAssert() external {
        ++x;
        assert(x == 0);
    }

    function testNew(uint256 size) external {
        ++x;
        uint256[] memory testArray = new uint256[](size);
    }

    receive() external payable {
        //bytes memory testData = msg.data;
    }

    function testError() external {
        revert TestError(x);
    }
}