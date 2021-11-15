// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

contract ChainIdVerifier {
    function verifyChain(uint256 expectedChainId) external {
        require(expectedChainId == block.chainid, "INVALID_CHAIN_ID");
    }
}

