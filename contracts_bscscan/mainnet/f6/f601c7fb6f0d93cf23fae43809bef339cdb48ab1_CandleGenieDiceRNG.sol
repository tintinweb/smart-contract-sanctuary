/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

      ___           ___           ___           ___           ___       ___                    ___           ___           ___                       ___     
     /\  \         /\  \         /\__\         /\  \         /\__\     /\  \                  /\  \         /\  \         /\__\          ___        /\  \    
    /::\  \       /::\  \       /::|  |       /::\  \       /:/  /    /::\  \                /::\  \       /::\  \       /::|  |        /\  \      /::\  \   
   /:/\:\  \     /:/\:\  \     /:|:|  |      /:/\:\  \     /:/  /    /:/\:\  \              /:/\:\  \     /:/\:\  \     /:|:|  |        \:\  \    /:/\:\  \  
  /:/  \:\  \   /::\~\:\  \   /:/|:|  |__   /:/  \:\__\   /:/  /    /::\~\:\  \            /:/  \:\  \   /::\~\:\  \   /:/|:|  |__      /::\__\  /::\~\:\  \ 
 /:/__/ \:\__\ /:/\:\ \:\__\ /:/ |:| /\__\ /:/__/ \:|__| /:/__/    /:/\:\ \:\__\          /:/__/_\:\__\ /:/\:\ \:\__\ /:/ |:| /\__\  __/:/\/__/ /:/\:\ \:\__\
 \:\  \  \/__/ \/__\:\/:/  / \/__|:|/:/  / \:\  \ /:/  / \:\  \    \:\~\:\ \/__/          \:\  /\ \/__/ \:\~\:\ \/__/ \/__|:|/:/  / /\/:/  /    \:\~\:\ \/__/
  \:\  \            \::/  /      |:/:/  /   \:\  /:/  /   \:\  \    \:\ \:\__\             \:\ \:\__\    \:\ \:\__\       |:/:/  /  \::/__/      \:\ \:\__\  
   \:\  \           /:/  /       |::/  /     \:\/:/  /     \:\  \    \:\ \/__/              \:\/:/  /     \:\ \/__/       |::/  /    \:\__\       \:\ \/__/  
    \:\__\         /:/  /        /:/  /       \::/__/       \:\__\    \:\__\                 \::/  /       \:\__\         /:/  /      \/__/        \:\__\    
     \/__/         \/__/         \/__/         ~~            \/__/     \/__/                  \/__/         \/__/         \/__/                     \/__/  
     
                                                                     CG DICE RNG SOURCE
                                                                     
                                                                     [VERSION : 1.1.0]

                                                                   https://candlegenie.io


*/


// CONTEXT
abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// OWNABLE
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner can not be the ZERO address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// REENTRANCY GUARD
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// LINK TOKEN INTERFACE
interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// VRF ID BASE
contract VRFRequestIDBase {

  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// VRF COSUMER BASE
abstract contract VRFConsumerBase is VRFRequestIDBase {


    function fulfillRandomness(bytes32 requestId,uint256 randomness) internal virtual;
    
    
    uint256 constant private USER_SEED_PLACEHOLDER = 0;

    function requestRandomness(bytes32 _keyHash,uint256 _fee) internal returns (bytes32 requestId)
    {
      LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
      uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
      nonces[_keyHash] = nonces[_keyHash] + 1;
      return makeRequestId(_keyHash, vRFSeed);
    }
  
    function transferLinkTokens(address to, uint256 amount) internal 
    {
        LINK.transfer(to, amount);
    }

    LinkTokenInterface immutable internal LINK;
    address immutable private vrfCoordinator;


    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;


    constructor(address _vrfCoordinator,address _link) 
    {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }


    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external
    {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// DICE INTERFACE
abstract contract CandleGenieDice
{
    enum DiceRoll {None, One, Two, Three, Four, Five, Six}
    enum Status {Idle, Rolling , Drop, Refunded}

    struct Bet 
    {
        address user;
        uint256 Index;
        uint256 rollId;
        uint256 rollTimestamp;
        uint256 dropTimestamp;
        uint256 betAmount;
        uint256 paidAmount;
        uint8 rewardMultiplier;
        DiceRoll guess;
        DiceRoll result;
        Status status;
        bool paid;
        bool vrfUsed;
    }
    function getBet(uint256 rollId) external virtual view returns (Bet memory);
    function getUserBetsLength(address user) external virtual view returns (uint256);
    function getUserBetId(address user, uint256 position) external virtual view returns (uint256);
    function getUserBets(address user, uint256 cursor, uint256 size) external virtual view returns (uint256[] memory, Bet[] memory, uint256);
    function Drop(uint256 rollId, int rollResult) external virtual;
    
}

abstract contract CandleGenieDicePseudoGenerator
{
     function GenerateRandom() external virtual returns (uint256 random);
}

abstract contract CandleGenieDiceRollController
{
     function FinalizeRoll(uint256 requestId, uint256 randomness) external virtual;
}


contract CandleGenieDiceRNG is VRFConsumerBase, ReentrancyGuard, Ownable 
{
    
    // Game
    address public gameContractAddress;
    CandleGenieDice internal gameContract;

    // Pseudo Source
    address public pseudoGeneratorAddress;
    CandleGenieDicePseudoGenerator internal pseudoGeneratorContract;
  
    // Roll Control
    address public rollControllerAddress;
    CandleGenieDiceRollController internal rollControllerContract;
  
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public rollCount;

    
    constructor() 
        VRFConsumerBase(
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, // VRF Coordinator
            0x404460C6A5EdE2D891e8297795264fDe62ADBB75  // LINK Token
        )
    {
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10 ** 18; // 0.1 LINK  
    }
    
    modifier onlyGameContract() 
    {
        require(msg.sender == gameContractAddress, "Only game contract allowed");
        _;
    }
    
      function setGameContractAddress(address _gameContractAddress) external onlyOwner {
        
        gameContractAddress = _gameContractAddress;
        gameContract = CandleGenieDice(gameContractAddress);
    }

    function setPseudoGenerator(address _pseudoGeneratorAdress) external onlyOwner {
        
        pseudoGeneratorAddress = _pseudoGeneratorAdress;
        pseudoGeneratorContract = CandleGenieDicePseudoGenerator(pseudoGeneratorAddress);  
    }
    
    function setRollController(address _rollControllerAddress) external onlyOwner {
        
        rollControllerAddress = _rollControllerAddress;
        rollControllerContract = CandleGenieDiceRollController(rollControllerAddress);
    }
    
    function transferLink(address to, uint256 amount) external onlyOwner {
        transferLinkTokens(to, amount);
    }

    function SetRollCount(uint256 _rollCount) external onlyOwner 
    {
        rollCount = _rollCount;
    }
    
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }
    
    function RollWithVRF() external onlyGameContract returns (uint256 requestId) 
    {
        require(keyHash != bytes32(0), "Invalid key hash");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        require(pseudoGeneratorAddress != address(0), "Pseudo generator contract not set");  
        require(rollControllerAddress != address(0), "Roll controller contract not set");  
        
        rollCount++;
        return uint256(requestRandomness(keyHash, fee));  
    }

    function RollWithPSEUDO() external onlyGameContract returns (uint256 requestId) 
    {
        require(pseudoGeneratorAddress != address(0), "Pseudo generator contract not set");  
        require(rollControllerAddress != address(0), "Roll controller contract not set");  

        rollCount++;
        return uint256(keccak256(abi.encodePacked(rollCount + block.timestamp + block.number)));
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override 
    {
        rollControllerContract.FinalizeRoll(uint256(requestId), randomness); 
    }
    
    function fulfillPSEUDO(uint256 requestId) external onlyGameContract
    {
        uint256 randomness = pseudoGeneratorContract.GenerateRandom();
        rollControllerContract.FinalizeRoll(uint256(requestId), randomness); 
    }
    

}