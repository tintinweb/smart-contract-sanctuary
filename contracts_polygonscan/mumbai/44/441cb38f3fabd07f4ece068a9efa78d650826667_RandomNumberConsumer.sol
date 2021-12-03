// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./IRandomCaller.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract RandomNumberConsumer is VRFConsumerBase,Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;
    
    IRandomCaller internal RandomCaller;

    // 每轮中奖的随机数
    mapping(uint256 => uint256) public randomNumbers;

    mapping(bytes32 => uint256) public roundNumberWithRequestId;
    
    event FulfillRandomness(uint256 roundNumber,uint256 randomness);
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Matic Mainnet
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     */
    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
    }
  
    /**
     * @notice Change the fee
     * @param _fee: new fee (in LINK)
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash: new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setRandomCaller(address caller) external onlyOwner{
        RandomCaller = IRandomCaller(caller);
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber(uint256 roundNumber) public returns (bytes32 requestId) {
        require(msg.sender == address(RandomCaller), "Only RandomCaller Call");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        
        requestId = requestRandomness(keyHash, fee);
        roundNumberWithRequestId[requestId] = roundNumber;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 roundNumber = roundNumberWithRequestId[requestId];

        randomNumbers[roundNumber] = randomness;

        emit FulfillRandomness(roundNumber,randomness);

        RandomCaller.randomCallback(roundNumber);
    }

    // Implement a withdraw function to avoid locking your LINK in the contract
    function withdrawLink() external {
        LINK.transfer(owner(),LINK.balanceOf(address(this)));
    }
    
    // 查看中奖号码
    function getWinningNumber(uint256 roundNumber)public view returns(uint256[] memory expandedValues){
        uint256 randomValue = randomNumbers[roundNumber];
        return expand(randomValue,6);
    }
    
    // 生成6位随机数
    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);

        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomValue, i*7))) % 30)+1;
        }
        return expandedValues;
    }
}