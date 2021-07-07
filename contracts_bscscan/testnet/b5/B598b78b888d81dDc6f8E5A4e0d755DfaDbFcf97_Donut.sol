// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Donut is Ownable {
  uint8 public constant MAX_MULTIPLIER = 16;
  uint8 public multiplier = 15;

  uint256 public minBet = 0.001 ether;
  uint256 public maxBet = 0.1 ether;

  struct DonutBet {
    uint8 bet;
    address creator;
    uint256 value;
    uint256 block;
  }

  mapping(uint64 => DonutBet) public bets;

  uint64 public numBets = 0;

  event BetPlaced(uint64 id, uint8 bet, address creator, uint256 value, uint256 block);
  event BetClaimed(uint64 id);

  function hasWon(uint64 id) public view returns (bool) {
    if (bets[id].value == 0) return false;

    bytes32 hash = blockhash(bets[id].block);

    if (hash == bytes32(0)) return false;

    return uint8(hash[31]) % 16 == bets[id].bet;
  }

  function placeBet(uint8 bet) external payable {
    require(msg.value >= minBet, "Donut: Bet amount is less than minimum");
    require(msg.value <= maxBet, "Donut: Bet amount is greater than maximum");

    uint64 id = numBets;

    bets[id].bet = bet;
    bets[id].creator = msg.sender;
    bets[id].value = msg.value;
    bets[id].block = block.number;

    emit BetPlaced(id, bet, msg.sender, msg.value, block.number);

    numBets += 1;
  }

  function claim(uint64 id) external {
    require(bets[id].creator == msg.sender, "Donut: You didn't create this bet");
    require(hasWon(id), "Donut: You didn't win");
    require(send(bets[id].creator, bets[id].value * 15), "Donut: Claim failed");

    emit BetClaimed(id);

    delete bets[id];
  }

  function setMinBet(uint256 val) external onlyOwner {
    minBet = val;
  }

  function setMaxBet(uint256 val) external onlyOwner {
    maxBet = val;
  }

  function setMultiplier(uint8 val) external onlyOwner {
    require(val <= MAX_MULTIPLIER, "Donut: Value exceeds max amount");

    multiplier = val;
  }

  function deposit() external payable {}

  function withdraw(uint256 amount) external onlyOwner {
    send(owner(), amount);
  }

  function send(address to, uint256 amount) internal returns (bool) {
    (bool sent, ) = to.call{ value: amount }("");
    return sent;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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