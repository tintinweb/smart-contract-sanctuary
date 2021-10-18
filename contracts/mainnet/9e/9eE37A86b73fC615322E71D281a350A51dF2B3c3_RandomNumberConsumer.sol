/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFConsumerBase.sol";

interface LinkTokenInterface {
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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

contract VRFRequestIDBase {

  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 internal randomResult;
    
    // For the storage of pseudo-random numbers
    uint internal nonce;
    event CreateRandomNumber(address indexed requester, uint randomNumber, uint maxNumber);
    mapping(address => mapping(uint => uint)) public randomNumberStorage;
    mapping(address => uint) public currentNonceForAddress;

    constructor() VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
        ) {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * (10**18); // 2 LINK
    }
    
    function getRandomNumber() public returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    // this costs less gas
    function emitRandomNumber(uint maxNumber_) public returns (uint) {
        uint _rand = uint(keccak256(abi.encodePacked(randomResult, currentNonceForAddress[msg.sender], block.timestamp, block.difficulty, msg.sender))) % (maxNumber_ + 1);
        currentNonceForAddress[msg.sender]++;
        emit CreateRandomNumber(msg.sender, _rand, maxNumber_); // emit event as a cheaper form of storage
        return _rand;
    }
    // this costs the most gas
    function storeRandomNumber(uint maxNumber_) public returns (uint) {
        uint _rand = uint(keccak256(abi.encodePacked(randomResult, currentNonceForAddress[msg.sender], block.timestamp, block.difficulty, msg.sender))) % (maxNumber_ + 1); 
        randomNumberStorage[msg.sender][currentNonceForAddress[msg.sender]] = _rand;
        currentNonceForAddress[msg.sender]++;
        return _rand;
    }
    // this is free!
    function returnRandomNumber(uint maxNumber_, uint nonce_) public view returns (uint) {
        uint _rand = uint(keccak256(abi.encodePacked(randomResult, nonce_, block.timestamp, block.difficulty, msg.sender))) % (maxNumber_ + 1);
        return _rand;
    }
    
    // this returns the lookup-value of the address's stored random numbers generated
    function getArrayOfStorageForAddress(address address_, uint startIndex_, uint endIndex_) public view returns (uint[] memory) {
        uint _arraySize = endIndex_ - startIndex_;
        uint[] memory _returnArray = new uint[](_arraySize);
        for (uint i = 0; i < _arraySize; i++) {
            _returnArray[i] = randomNumberStorage[address_][startIndex_ + i];
        }
        return _returnArray;
    }
}