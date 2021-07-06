// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WhirlpoolConsumer.sol";

contract Jelly is WhirlpoolConsumer {
  enum JellyType {
    Strawberry,
    Watermelon
  }

  struct JellyBet {
    JellyType bet;
    address creator;
    address joiner;
    uint256 value;
  }

  mapping(address => address) public referrers;
  mapping(uint64 => JellyBet) public bets;

  uint16 public constant MAX_COMMISSION_RATE = 1000;

  uint16 public commissionRate = 500;
  uint16 public referralRate = 100;
  uint16 public cancellationFee = 100;

  uint64 public numBets = 0;

  uint256 public minBet = 0.01 ether;

  event BetCreated(uint64 id, address creator, JellyType bet, uint256 value);
  event BetCancelled(uint64 id);
  event BetAccepted(uint64 id, address joiner);
  event BetConcluded(uint64 id, address referrer, JellyType result);

  constructor(address _whirlpool) WhirlpoolConsumer(_whirlpool) {}

  function createBet(JellyType bet, address referrer) external payable {
    require(msg.value >= minBet, "Jelly: Bet amount is lower than minimum bet amount");

    uint64 id = numBets;

    bets[id].creator = msg.sender;
    bets[id].value = msg.value;
    bets[id].bet = bet;

    referrers[msg.sender] = referrer;

    emit BetCreated(numBets, msg.sender, bet, msg.value);

    numBets += 1;
  }

  function cancelBet(uint64 id) external {
    require(bets[id].creator == msg.sender, "Jelly: You didn't create this bet");

    uint256 fee = (bets[id].value * cancellationFee) / 10000;
    require(send(msg.sender, bets[id].value, fee, address(0)), "Jelly: Cancel bet failed");

    emit BetCancelled(id);
    delete bets[id];
  }

  function acceptBet(uint64 id, address referrer) external payable {
    require(bets[id].value != 0, "Jelly: Bet is unavailable");
    require(bets[id].joiner == address(0), "Jelly: Bet is already accepted");
    require(msg.value == bets[id].value, "Jelly: Unfair bet");

    bets[id].joiner = msg.sender;
    referrers[msg.sender] = referrer;

    emit BetAccepted(id, bets[id].joiner);

    _requestRandomness(id);
  }

  function concludeBet(uint64 id, JellyType result) internal {
    require(bets[id].value != 0, "Jelly: Bet is unavailable");
    require(bets[id].joiner != address(0), "Jelly: Bet isn't already accepted");

    uint256 reward = bets[id].value * 2;
    uint256 fee = (reward * commissionRate) / 10000;
    address winner = result == bets[id].bet ? bets[id].creator : bets[id].joiner;

    require(send(winner, reward, fee, referrers[winner]), "Jelly: Reward failed");

    emit BetConcluded(id, referrers[winner], result);

    delete bets[id];
  }

  function _consumeRandomness(uint64 id, uint256 randomness) internal override {
    concludeBet(id, JellyType(randomness % 2));
  }

  function setCommissionRate(uint16 val) external onlyOwner {
    require(val <= MAX_COMMISSION_RATE, "Jelly: Value exceeds max amount");
    commissionRate = val;
  }

  function setReferralRate(uint16 val) external onlyOwner {
    require(val <= commissionRate, "Jelly: Value exceeds max amount");
    referralRate = val;
  }

  function setCancellationFee(uint16 val) external onlyOwner {
    require(val <= commissionRate, "Jelly: Value exceeds max amount");
    cancellationFee = val;
  }

  function setMinBet(uint256 val) external onlyOwner {
    minBet = val;
  }

  function send(
    address to,
    uint256 amount,
    uint256 fee,
    address referrer
  ) internal returns (bool) {
    (bool sent, ) = to.call{ value: amount - fee }("");
    if (fee == 0) return sent;

    if (referrer != address(0)) {
      uint256 refBonus = (amount * referralRate) / 10000;
      (bool sentToRef, ) = referrer.call{ value: refBonus }("");
      if (sentToRef) fee -= refBonus;
      sent = sent && sentToRef;
    }

    (bool sentFee, ) = owner().call{ value: fee }("");
    return sent && sentFee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWhirlpoolConsumer.sol";
import "./interfaces/IWhirlpool.sol";

abstract contract WhirlpoolConsumer is Ownable, IWhirlpoolConsumer {
  IWhirlpool whirlpool;
  mapping(bytes32 => uint64) internal activeRequests;

  bool public whirlpoolEnabled = false;

  constructor(address _whirlpool) {
    whirlpool = IWhirlpool(_whirlpool);
  }

  function _requestRandomness(uint64 id) internal {
    if (whirlpoolEnabled) {
      bytes32 requestId = whirlpool.request();
      activeRequests[requestId] = id;
    } else {
      _consumeRandomness(
        id,
        uint256(
          keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.gaslimit, block.coinbase, block.number))
        )
      );
    }
  }

  function consumeRandomness(bytes32 requestId, uint256 randomness) external override onlyWhirlpoolOrOwner {
    _consumeRandomness(activeRequests[requestId], randomness);
    delete activeRequests[requestId];
  }

  function enableWhirlpool() external onlyOwner {
    whirlpool.addConsumer(address(this));
    whirlpoolEnabled = true;
  }

  function disableWhirlpool() external onlyOwner {
    whirlpoolEnabled = false;
  }

  function _consumeRandomness(uint64 id, uint256 randomness) internal virtual;

  modifier onlyWhirlpoolOrOwner() {
    require(
      msg.sender == address(whirlpool) || msg.sender == owner(),
      "WhirlpoolConsumer: Only whirlpool or owner can call this function"
    );
    _;
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

interface IWhirlpoolConsumer {
  function consumeRandomness(bytes32 requestId, uint256 randomness) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhirlpool {
  function request() external returns (bytes32);

  function setKeyHash(bytes32 _keyHash) external;

  function setFee(uint256 _fee) external;

  function addConsumer(address consumerAddress) external;

  function deleteConsumer(address consumerAddress) external;

  function withdrawLink() external;
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