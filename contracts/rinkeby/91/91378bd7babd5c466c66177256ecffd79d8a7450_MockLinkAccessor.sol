/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// File: contracts/interfaces/INFTMaster.sol

interface INFTMaster {
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

// File: contracts/interfaces/ILinkAccessor.sol

interface ILinkAccessor {
    function requestRandomness(uint256 userProvidedSeed_) external returns(bytes32);
}

// File: contracts/mock/MockLinkAccessor.sol

contract MockLinkAccessor is ILinkAccessor {

    INFTMaster public nftMaster;
    uint256 public randomness;
    bytes32 public requestId;

    constructor(
        INFTMaster nftMaster_
    ) public {
        nftMaster = nftMaster_;
    }

    function setRandomness(uint256 randomness_) external {
        randomness = randomness_;
    }

    function triggerRandomness() external {
        nftMaster.fulfillRandomness(requestId, randomness);
    }

    function requestRandomness(uint256 userProvidedSeed_) public override returns(bytes32) {
        requestId = blockhash(block.number);
        return requestId;
    }
}