//SourceUnit: SmattMillionsRNG.sol

pragma solidity ^0.5.0;

interface ISmartMillionsLottery {
    function setWinner(uint _lotteryId, uint256 entryId) external returns(bool);
}

contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    isOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier isOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

contract SmartMillionsRNG is Owned { // is ISmartMillionsRNG {
   
   address lotteryContractAddress = address(0);
   uint[] public previousSeeds;

   constructor() public {
       currentSeed = block.timestamp;
   }

   uint public constant MAX = uint(0) - uint(1); // using underflow to generate the maximum possible value
   uint public constant SCALE = 500;
   uint public constant SCALIFIER = MAX / SCALE;
   uint public constant OFFSET = 100;

   uint public lastRandom = 0;
   uint256 public randomRound = 0;

   event SeedUpdated(uint256 _randomRound, uint256 _newSeed);
   event RandomGenerated(uint256 _random);
   event LotteryWinnerRNG(uint256 _lotteryId, uint256 _random);

   uint256 public currentSeed;

   function setLotteryContractAddress(address lotteryAddress) public isOwner() {
       lotteryContractAddress = lotteryAddress;
   }

    function updateSeed(uint256 _randomRound, uint256 _seed) public isOwner() returns(bool) {
        currentSeed = _seed;
        previousSeeds.push(_seed);
        randomRound = _randomRound;
        emit SeedUpdated(_randomRound, currentSeed);
        return true;
    }

    function randomGen(uint256 useed, uint256 scale) private view returns(uint) {
        uint seed = uint(keccak256(abi.encodePacked(useed + block.timestamp)));
        uint scaled = seed / (MAX / scale);
        return scaled;
    }

   function getLatestRandom(uint256 scale) public returns(uint) {
      require(msg.sender == owner || msg.sender == lotteryContractAddress, 'not-owner-or-lottery');
      uint result = randomGen(currentSeed, scale);
      lastRandom = result;
      emit RandomGenerated(result);
      return result;
   }

   function lotteryRngCallback(uint256 lotteryId, uint256 entriesTotal) external {
       require(msg.sender == lotteryContractAddress, 'not-owner-or-lottery');
       ISmartMillionsLottery lotto = ISmartMillionsLottery(lotteryContractAddress);
       uint256 winner = getLatestRandom(entriesTotal);
       lotto.setWinner(lotteryId, winner);
       emit LotteryWinnerRNG(lotteryId, winner);
   }
}