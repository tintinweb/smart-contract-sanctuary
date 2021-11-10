// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "VRFConsumerBase.sol";
import "Ownable.sol";

contract BillionairesChainlinkVRFConsumer is Ownable, VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public currentRandomIndex;
    uint256 public constant BB_SUPPLY = 13337;
    mapping(uint256 => uint256) public randomSeedHistory;
    mapping(bytes32 => uint256) public chainLinkRequestIdToSeedIndex;

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     *
     * Network: ETH Mainnet
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * LINK token address: 0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     *
     * Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     *
     * Network: ETH Mainnet
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * LINK token address: 0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     */
    constructor()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        // fee = 0.1 * 10 ** 18; // 0.1 LINK RINKEBY!! (Varies by network)
        fee = 0.0001 * 10**18; // 0.1 Polygon (Varies by network)
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomSeedHistory[++currentRandomIndex] = randomness;
        chainLinkRequestIdToSeedIndex[requestId] = currentRandomIndex;
    }

    /**
     * Use solidity PRNG to generate random number for a given Chainlink seed
     */
    function randomNumberFromSeedIndex(uint256 seedIndex, uint256 rollNumber)
        public
        view
        returns (uint256)
    {
        uint256 seed = randomSeedHistory[seedIndex];
        require(seed > 0, "No seed exists at the provided index");
        uint256 random = uint256(keccak256(abi.encodePacked(seed, rollNumber)));
        return random;
    }

    function billionaireIDFromSeedIndex(uint256 seedIndex, uint256 rollNumber)
        public
        view
        returns (uint256)
    {
        return
            (randomNumberFromSeedIndex(seedIndex, rollNumber) % BB_SUPPLY) + 1;
    }
}