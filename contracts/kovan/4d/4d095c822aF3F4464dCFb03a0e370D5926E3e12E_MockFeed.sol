/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: MockFeed.sol

/**
 * Used for testing purpose only.
 */
contract MockFeed {
    // NOTE: mainnet chain link oracle: 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
    // Rinkeby: IChainLinkFeed(0xc3fFAC889CEB6c556CA36c04F69E68253bdB5218);
    // BSC Testnet: 0xd1F2F23Dc2871D575d226B0B982657b13F81A112
    // hardcode gas price to 1 GWei for unit testing.
    uint public gasPrice = 1000000000;

    function latestAnswer() external view returns (int256) {
        return int256(gasPrice);
    }

    function updateGasPrice(uint newGasPrice) external {
        gasPrice = newGasPrice;
    }
}