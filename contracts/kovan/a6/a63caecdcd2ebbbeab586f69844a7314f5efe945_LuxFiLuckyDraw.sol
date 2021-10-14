// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//import "github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFConsumerBase.sol";
import "./VRFConsumerBase.sol";

contract LuxFiLuckyDraw is VRFConsumerBase {
    bytes32 internal keyHash;
    address internal owner;
    uint256 internal fee;
    uint256[] public randomResultArray;
    uint256 public randomResult;
    
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token Kovan Testnet
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
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