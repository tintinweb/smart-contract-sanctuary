/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.11;

interface IPuzzle {
    function foo(uint256 _password, address _address, bytes memory _bytes) external;
    function collectPrize() external;
    function owner() external view returns (address);
}

contract SolvePuzzle {
    IPuzzle puzzle = IPuzzle(0xDA62e1453aF5254c3c6bCc214F5312990c143ca0);
    address updateOwnerContract = 0xC84506767cfF96271E52262BC569229023178E2A;
    uint256 password = 0x11f71fb22c2;

    function updateOwner() external {
        puzzle.foo(
            password, 
            updateOwnerContract, 
            abi.encodeWithSignature("updateOwner(address)", address(this))
        );
    }

    function collect() external {
        puzzle.collectPrize();
    }

    function getOwner() external view returns(address) {
        return puzzle.owner();
    }
}