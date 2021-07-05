/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Etheria Helper v0.9.0
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to 0x7d0cBA86128957633156FBFF6A88D9A278eF32e2
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------

interface IEtheria {
    function getOwner(uint8 col, uint8 row) external view returns(address);
    function getName(uint8 col, uint8 row) external view returns(string memory);
    function getStatus(uint8 col, uint8 row) external view returns(string memory);
    function getLastFarm(uint8 col, uint8 row) external view returns (uint);
    // function getBlocks(uint8 col, uint8 row) external view returns (int8[5][] memory);
}

contract EtheriaHelper {

    uint private constant SIZE = 33;
    
    IEtheria public constant etheria = IEtheria(0xB21f8684f23Dbb1008508B4DE91a0aaEDEbdB7E4);
    
    function owners() external view returns(address[] memory ) {
        address[] memory result = new address[](SIZE * SIZE);
        for (uint8 row = 0; row < SIZE; row++) {
            for (uint8 col = 0; col < SIZE; col++) {
                result[row * SIZE + col] = etheria.getOwner(col, row);
            }
        }
        return result;
    }

    function names() external view returns(string[] memory ) {
        string[] memory result = new string[](SIZE * SIZE);
        for (uint8 row = 0; row < SIZE; row++) {
            for (uint8 col = 0; col < SIZE; col++) {
                result[row * SIZE + col] = etheria.getName(col, row);
            }
        }
        return result;
    }

    function statuses() external view returns(string[] memory ) {
        string[] memory result = new string[](SIZE * SIZE);
        for (uint8 row = 0; row < SIZE; row++) {
            for (uint8 col = 0; col < SIZE; col++) {
                result[row * SIZE + col] = etheria.getStatus(col, row);
            }
        }
        return result;
    }

    function lastFarms() external view returns(uint[] memory ) {
        uint[] memory result = new uint[](SIZE * SIZE);
        for (uint8 row = 0; row < SIZE; row++) {
            for (uint8 col = 0; col < SIZE; col++) {
                result[row * SIZE + col] = etheria.getLastFarm(col, row);
            }
        }
        return result;
    }
}