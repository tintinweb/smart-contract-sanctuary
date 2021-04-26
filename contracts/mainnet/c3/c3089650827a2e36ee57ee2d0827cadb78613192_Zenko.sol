/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

/// SPDX-License-Identifier: MIT
/*
▄▄█    ▄   ██   █▄▄▄▄ ▄█ 
██     █  █ █  █  ▄▀ ██ 
██ ██   █ █▄▄█ █▀▀▌  ██ 
▐█ █ █  █ █  █ █  █  ▐█ 
 ▐ █  █ █    █   █    ▐ 
   █   ██   █   ▀   
           ▀          */
/// Special thanks to Keno, Boring and Gonpachi for review and continued inspiration.
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
/// @notice Arbitrary call helper for Inari.
contract Zenko {
    function zenko(
        address to, 
        uint256 value, 
        bytes calldata data
    ) external payable returns (bool success, bytes memory result) {
        (success, result) = to.call{value: value}(data);
        require(success);
    }
}