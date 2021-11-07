// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "VRFConsumerBase.sol";
import "Ownable.sol";
 
contract BillionairesChainlinkVRFConsumer is Ownable, VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public currentRandomIndex;
    uint256 public constant BB_SUPPLY = 13337;
    mapping (uint256 => uint256) public randomSeedHistory;
    mapping (bytes32 => uint256) public chainLinkRequestIdToSeedIndex;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        currentRandomIndex = 0;
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
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomSeedHistory[++currentRandomIndex] = randomness;
        chainLinkRequestIdToSeedIndex[requestId] = currentRandomIndex;
    }
    
    /**
     * Use solidity PRNG to generate random number for a given Chainlink seed
     */
    function randomNumberFromSeedIndex(uint256 seedIndex,uint256 rollNumber) public view returns (uint256){
        uint256 seed = randomSeedHistory[seedIndex];
        require(seed > 0, "No seed exists at the provided index");
        uint256 random = uint(keccak256(abi.encodePacked(seed,rollNumber)));
        return random;
    }
    function billionaireIDFromSeedIndex(uint256 seedIndex,uint256 rollNumber) public view returns (uint256){
        return (randomNumberFromSeedIndex(seedIndex,rollNumber) % BB_SUPPLY) + 1;
    }
}