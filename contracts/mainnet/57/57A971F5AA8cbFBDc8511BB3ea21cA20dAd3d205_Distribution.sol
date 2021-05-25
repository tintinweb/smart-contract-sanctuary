// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './SafeMath.sol';
import './Address.sol';
import './Context.sol';

contract VRFRequestIDBase {
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }
    function makeRequestId(
        bytes32 _keyHash,
        uint256 _vRFInputSeed
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

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
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMath for uint256;
    
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal virtual;

    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface immutable internal LINK;

    address immutable private vrfCoordinator;
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    constructor(
        address _vrfCoordinator,
        address _link
    ) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    
    bool private progress = false;
    uint256 private winner = 0;
    address private distributer;
    
    modifier onlyDistributer() {
        require(distributer == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Mainnet
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     */
    constructor(address _distributer) 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK
        distributer = _distributer;
    }
    
    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed) public onlyDistributer returns (bytes32 requestId) {        
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        require(!progress, "now getting an random number.");
        winner = 0;
        progress = true;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestId = 0;
        progress = false;
        winner = randomness;
    }

    function getWinner() external view onlyDistributer returns (uint256) {
        if(progress)
            return 0;
        return winner;
    }
}

contract Distribution is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    RandomNumberConsumer public rnGenerator;

    uint256 public _randomCallCount = 0;
    uint256 public _prevRandomCallCount = 0;

    uint256 public _punkWinner = 6500;
    uint256[] public _legendaryMonsterWinners;
    uint256[] public _ethWinners;
    uint256[] public _zedWinners;
    
    constructor () {
        rnGenerator = new RandomNumberConsumer(address(this));
    }

    function getRandomNumber() external onlyOwner {
        rnGenerator.getRandomNumber(_randomCallCount);
        _randomCallCount = _randomCallCount + 1;
    }

    // Function to distribute punk.
    function setPunkWinner() external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');
        require(_punkWinner == 6500, 'You already picked punk winner');

        _prevRandomCallCount = _randomCallCount;
        _punkWinner = rnGenerator.getWinner().mod(6400);
    }

    // Function to distribute legendary monster.
    function setLegendaryMonsterWinner() external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');
        
        _prevRandomCallCount = _randomCallCount;
        uint256 _tempWinner = rnGenerator.getWinner().mod(3884);
        for(uint i=0; i<_legendaryMonsterWinners.length; i++ ) {
            require(_legendaryMonsterWinners[i] != _tempWinner, 'Same winner already exists.');
        }
        _legendaryMonsterWinners.push(_tempWinner);
    }

    // Function to distribute eth.
    function setETHWinner() external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');
        
        _prevRandomCallCount = _randomCallCount;
        uint256 _tempWinner = rnGenerator.getWinner().mod(400) + 6000;
        for(uint i=0; i<_ethWinners.length; i++ ) {
            require(_ethWinners[i] != _tempWinner, 'Same winner already exists.');
        }
        _ethWinners.push(_tempWinner);
    }

    // Function to distribute zed.
    function setZedWinner() external onlyOwner {
        require(_prevRandomCallCount != _randomCallCount, "Please generate random number.");
        require(rnGenerator.getWinner() != 0, 'Please wait until random number generated.');
        
        _prevRandomCallCount = _randomCallCount;
        uint256 _tempWinner = rnGenerator.getWinner().mod(6400);
        for(uint i=0; i<_zedWinners.length; i++ ) {
            require(_zedWinners[i] != _tempWinner, 'Same winner already exists.');
        }
        _zedWinners.push(_tempWinner);
    }
}