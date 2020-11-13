/**
 *Submitted for verification at Etherscan.io on 2020-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract RevertReasonParserTest {
    function emptyStringRevert() external pure  {
        revert("");
    }

    function test() external view returns(bytes memory, uint256) {
        try this.emptyStringRevert() {
        } catch (bytes memory reason) {
            return (reason, reason.length);
        }
    }
}