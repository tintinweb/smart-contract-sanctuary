/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract SplitIt {
    address private _walletA = 0xFCC70898C5ed943297432F44De0B8Beeb1B035C7;
    address private _walletB = 0x662B2405D1d06E8984d8ef98870008F74C3B0C9e;

    fallback() external payable {
        bool success = false;
        (success,) = _walletA.call{value : msg.value * 95 / 100}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _walletB.call{value : msg.value * 5 / 100}("");
        require(success2, "Failed to send2");
    }
}