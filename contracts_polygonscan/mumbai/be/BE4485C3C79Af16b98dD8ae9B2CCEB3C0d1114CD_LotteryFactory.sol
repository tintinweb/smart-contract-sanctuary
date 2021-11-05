/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/LotteryFactory.sol

pragma solidity ^0.8.7;


/// SPDX-License-Identifier: UNLICENSED

contract LotteryFactory is Ownable {

  address[] lotteries;
  mapping(address => uint) lotteryLog;

  function createLottery(string memory lotteryName, uint entryFee, uint maxEntries, uint maxEntriesPerPlayer) external onlyOwner {
    require(bytes(lotteryName).length > 0, "Missing lottery name");
    require(entryFee > 0, "Missing entry fee");
    require(maxEntries > 0, "Missing max entries");
    require(maxEntriesPerPlayer > 0, "Missing max entries per player");

    LotteryContract newLottery = new LotteryContract(lotteryName, entryFee, maxEntries, maxEntriesPerPlayer, msg.sender);
    lotteries.push(address(newLottery));
    lotteryLog[address(newLottery)] = block.timestamp;

    // event
    emit LotteryCreated(address(newLottery));
  }

  function getLotteries() public view returns(address[] memory) {
    return lotteries;
  }

  function getLotteryInception(address _address) public view returns(uint) {
    return lotteryLog[_address];
  }

  function deleteLottery(address lotteryAddress) external onlyOwner {
    delete lotteryLog[lotteryAddress];
    address[] memory updatedLotteries;
    for (uint256 index = 0; index < lotteries.length; index++) {
      if (lotteries[index] != lotteryAddress) {
        updatedLotteries[updatedLotteries.length] = lotteries[index];
      }
    }
    lotteries = updatedLotteries;
  }

  // Events
  event LotteryCreated(
    address lotteryAddress
  );
}

contract LotteryContract {
  string lotteryName;
  address manager;

  address[] players;

  // Variables for lottery information
  address payable winningAddress;
  bool public isLotteryLive;
  uint public maxEntries;
  uint public maxEntriesPerPlayer;
  uint public ethToParticipate; // need to set entry fee to a stable coin
  uint public revealTime; // will be set auto set to 1 hour after final entry
  
  uint devPercentage;
  uint winnerPercentage;
  uint charityPercentage;

  address payable devWallet = payable(0x2C15a9159B48335b007E58e783A809140F35a7C2);
  address payable charityWallet = payable(0x5118968c5f33EFb0c2fC5D8Ef9734fa65FF7A5eE);


  constructor(string memory _lotteryName, uint _entryFee, uint _maxEntries, uint _maxEntriesPerPlayer, address _manager) {
    lotteryName = _lotteryName;
    ethToParticipate = _entryFee;
    maxEntries = _maxEntries;
    maxEntriesPerPlayer = _maxEntriesPerPlayer;
    manager = _manager;

    devPercentage = 10;
    winnerPercentage = 50;
    charityPercentage = 40;
  }

  function setLotteryName(string memory _lotteryName) external restricted {
    lotteryName = _lotteryName;
  }

  function setEthToParticipate(uint _ethToParticipate) external restricted {
    ethToParticipate = _ethToParticipate;
  }

  function setRevealTime(uint _revealTime) external restricted {
    require(players.length == maxEntries);
    revealTime = _revealTime;
  }

  function setMaxEntries(uint _maxEntries) external restricted {
    maxEntries = _maxEntries < players.length ? players.length : _maxEntries;
  }

  function setDevWallet(address _address) external restricted {
    devWallet = payable(_address);
  }

  function setCharityWallet(address _address) external restricted {
    charityWallet = payable(_address);
  }

  function participate() public payable {
    require(isLotteryLive, "Lottery is not live");
    require(players.length < maxEntries, "Lottery is full");
    require(msg.value == ethToParticipate, "Invalid entry amount");
    require(isNewPlayer(msg.sender), "Already entered");

    players.push(msg.sender);

    // entry event
    emit PlayerParticipated(msg.sender, players.length);
    
    if (players.length == maxEntries) {
      revealTime = block.timestamp + 3600;
      emit LotteryFull(revealTime);
    }
  }

  function activateLottery() external restricted {
    require(ethToParticipate > 0, "Entry fee not set");
    require(maxEntriesPerPlayer > 0, "Max entries per player not set");
    require(maxEntries > 0, "Max entries not set");
    isLotteryLive = true;
  }

  function closeLottery() external restricted {
    isLotteryLive = false;
  }

  function checkWinner() public returns (address) {
    require(players.length > 0, "Lottery not started");
    require(players.length == maxEntries, "Lottery not full");
    require(revealTime > 0, "Reveal time not set");
    require(revealTime <= block.timestamp, "Results not released yet");

    if (winningAddress == address(0)) {
      uint index = drawIndex();
      winningAddress = payable(players[index]);
      transferWinnings();
      emit WinnerDeclared(winningAddress);
    }

    return winningAddress;
  }

  function transferWinnings() public restricted {
    require(winningAddress != address(0), "Winner not declared");
    require(address(this).balance > 0, "No balance to transfer");

    uint256 devAmount = (getBalance() * devPercentage / 100);
    uint256 charityAmount = (getBalance() * charityPercentage / 100);
    uint256 winnerAmount = (getBalance() * winnerPercentage / 100);
    
    devWallet.transfer(devAmount);
    charityWallet.transfer(charityAmount);
    winningAddress.transfer(winnerAmount);
  }

  // need to chainge to Chainlink VRF to go live
  function drawIndex() internal view returns (uint256 index) {
    uint256 i = uint(blockhash(block.number - 1)) % players.length;
    index = i;
  }

  function getPlayers() public view returns(address[] memory) {
    return players;
  }

  function getPlayersEntered() public view returns(uint) {
    return players.length;
  }

  function getAvailablePlayers() public view returns(uint) {
    return maxEntries - players.length;
  }

  // Private functions
  function isNewPlayer(address playerAddress) private view returns(bool) {
    if (players.length == 0) {
      return true;
    }
    for (uint256 index = 0; index < players.length; index++) {
      if (players[index] == playerAddress) return false;
    }
    return true;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  // Modifiers
  modifier restricted() {
    require(msg.sender == manager);
    _;
  }

  // Events
  event LotteryFull( uint revealTime );
  event WinnerDeclared( address winningAddress );
  event PlayerParticipated( address playerAddress, uint entryCount );
}