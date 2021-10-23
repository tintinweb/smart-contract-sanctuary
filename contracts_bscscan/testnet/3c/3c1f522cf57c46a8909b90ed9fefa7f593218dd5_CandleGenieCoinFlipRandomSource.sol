/**
 *Submitted for verification at BscScan.com on 2021-10-22
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
     
                                                                        CG COINFLIP VRF
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

// CGCOINFLIP INTERFACE
abstract contract CandleGenieCoinFlip
{
    enum Position {None, Heads, Tails}
    enum Status {Idle, Flipping , Drop, Refunded}

    struct Bet 
    {
        address user;
        uint256 Index;
        uint256 flipId;
        uint256 flipTimestamp;
        uint256 dropTimestamp;
        uint256 betAmount;
        uint256 paidAmount;
        uint8 rewardMultiplier;
        Position guess;
        Position result;
        Status status;
        bool paid;
        bool vrfUsed;
    }
    
    function getBet(uint256 flipId) external virtual view returns (Bet memory);
    function getUserBetsLength(address user) external virtual view returns (uint256);
    function getUserBetId(address user, uint256 position) external virtual view returns (uint256);
    function getUserBets(address user, uint256 cursor, uint256 size) external virtual view returns (uint256[] memory, Bet[] memory, uint256);
    function Drop(uint256 flipId, int flipResult) external virtual;
    
}

contract CandleGenieCoinFlipRandomSource is VRFConsumerBase, ReentrancyGuard, Ownable 
{
    
    address constant public gameContractAddress = 0x18324b762940262B0C40E1b76d3387a9262E8C3e;
    CandleGenieCoinFlip internal gameContract;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public flipCount;
    uint8 internal pseudoPivot;
    

    constructor() 
        VRFConsumerBase(
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, // VRF Coordinator
            0x404460C6A5EdE2D891e8297795264fDe62ADBB75  // LINK Token
        )
    {
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10 ** 18; // 0.1 LINK
        
        // Hard Coded Contract
        gameContract = CandleGenieCoinFlip(gameContractAddress);

    }
    
    modifier onlyGameContract() 
    {
        require(msg.sender == gameContractAddress, "Only game contract allowed");
        _;
    }
    

    function transferLink(uint256 amount) external onlyOwner {
        transferLinkTokens(msg.sender, amount);
    }
    
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }
    

    function FlipWithVRF() external onlyGameContract returns (uint256 requestId) 
    {
        require(keyHash != bytes32(0), "Invalid key hash");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
           
        flipCount++;
        return uint256(requestRandomness(keyHash, fee));  
    }

    function FlipWithPSEUDO() external onlyGameContract returns (uint256 requestId) 
    {
        uint256 hash = uint256(keccak256(abi.encodePacked(flipCount + block.timestamp + block.number)));
        flipCount++;
        return hash;
    }
    

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override 
    {
        
        uint256 randomResult =  randomness % 100 + 1;

        int flipResult;
        if (randomResult < 50)
        {
            flipResult = 0;
        }
        else if (randomResult >= 50)
        {
            flipResult = 1;
        } 
        
        // Finalizing Flip
        finalizeFlip(uint256(requestId), randomness, flipResult);  
    }
    
    function fulfillPSEUDO(uint256 requestId) external onlyGameContract
    {

        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));
        uint256 randomResult =  randomness % 100 + 1;
        
        int flipResult; 
        
        if (pseudoPivot == 0)
        {
            if (randomResult < 50)
            {
                flipResult = 0;
            }
            else if (randomResult >= 50)
            {
                flipResult = 1;
            } 
            pseudoPivot = 1;
        }
        else if (pseudoPivot == 1)
        {
            if (randomResult > 50)
            {
                flipResult = 0;
            }
            else if (randomResult <= 50)
            {
                flipResult = 1;
            } 
            pseudoPivot = 0;
        }
        
        // Finalizing Flip
        finalizeFlip(uint256(requestId), randomness, flipResult);  
    }
    
    function finalizeFlip(uint256 requestId, uint256 randomness, int flipResult) internal
    {
        gameContract.Drop(uint256(requestId), flipResult);   
    }
    
    function getFlipPosition(CandleGenieCoinFlip.Position position) internal pure returns (int result)
    {
         if (position == CandleGenieCoinFlip.Position.Heads) return 0;
         if (position == CandleGenieCoinFlip.Position.Tails) return 1;
    }
    
    function revertResult(CandleGenieCoinFlip.Position position) internal pure returns (int result)
    {
         if (position == CandleGenieCoinFlip.Position.Heads) return 1;
         if (position == CandleGenieCoinFlip.Position.Tails) return 0;
    }

  
}