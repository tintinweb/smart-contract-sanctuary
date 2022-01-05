/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IPuzzle {
    function foo(uint256 _password, address _address, bytes memory _bytes) external;
    function collectPrize() external;
}

contract SolvePuzzle {
    IPuzzle puzzle = IPuzzle(0xDA62e1453aF5254c3c6bCc214F5312990c143ca0);
    address updateOwnerContract = 0x9AA0d5729ad089EFb8A82A6343A0498a6B248A66;
    uint256 password = 0x11f71fb22c2;

    function resolve() external {
        puzzle.foo(
            password, 
            updateOwnerContract, 
            abi.encodeWithSignature("updateOwner(address)", address(this))
        );

        puzzle.collectPrize();
    }
}