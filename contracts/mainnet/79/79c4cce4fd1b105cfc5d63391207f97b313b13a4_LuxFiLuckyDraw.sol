// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";

contract LuxFiLuckyDraw is VRFConsumerBase {
    bytes32 internal keyHash;
    address internal owner;
    uint256 internal fee;
    uint256[] public randomResultArray;
    uint256 public randomResult;
    
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator Mainnet
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token Ethereum Mainnet
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; //mainnet
        fee = 2 * 10 ** 18; // 2 LINK Mainnet(Varies by network)
        owner = 0x4C89D4ceB47cfc577AFA7398Add6d0f9984EC784;
    }
    
    function getRandomNumber() public returns (bytes32 requestId) {
        require (owner == msg.sender);
        return requestRandomness(keyHash, fee);
    }
    
    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
			//ideally make the lottery ticket format in LXF00001, LXF + 5 digits 
            expandedValues[i] = (uint256(keccak256(abi.encode(randomValue, i))) % 74675) + 1;
        }
        return expandedValues;
    }
	
    /* Callback function used by VRF Coordinator*/
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
	
    function drawResults() public {
        require (owner == msg.sender);
        randomResultArray = expand(randomResult, 66);
    }
	
    function getResults() external view returns (uint256[] memory) {
        return randomResultArray;
    }
}