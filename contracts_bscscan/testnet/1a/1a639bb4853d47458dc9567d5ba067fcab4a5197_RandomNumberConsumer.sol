/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

 
interface TOKEN {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
} 
abstract contract VRFConsumerBase {
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed, address _requester, uint256 _nonce) internal pure returns (uint256) {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }
    
    TOKEN immutable internal LINK = TOKEN(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    address immutable private vrfCoordinator =  0xa555fC018435bef5A13C6c6870a9d4C11DEC329C; 
    mapping(bytes32 => uint256) private nonces; 
  
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, 0)); 
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, 0, address(this), nonces[_keyHash]); 
        nonces[_keyHash] = nonces[_keyHash]+1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        setRandomNumber(requestId, randomness);
    }
    function setRandomNumber(bytes32 requestId, uint256 randomness) internal virtual;
}

contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
    uint256 internal fee = 1e17; // 0.1 LINK (Varies by network);
    
    uint256 public randomResult;
    bytes32 public _requestId;
    bytes32 public RandomNumber_requestId;
    event log(uint256 randomResult);
    
    constructor() VRFConsumerBase() {
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public  {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        RandomNumber_requestId=requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function setRandomNumber(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        _requestId = requestId;
        emit log(randomResult);
    } 
}