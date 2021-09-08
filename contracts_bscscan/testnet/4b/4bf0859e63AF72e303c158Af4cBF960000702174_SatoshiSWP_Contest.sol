/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later Or MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}



pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas 
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
        _guardCounter = 1;
    }
}


pragma solidity ^0.6.12;


contract SatoshiSWP_Contest is ReentrancyGuard {

  using SafeMath for uint256;

  IBEP20 public SATOSHI;
  //Contest finish time
  uint256 public finishTime;
  //Contest owner
  address payable public owner;

  struct Player {
    uint ts;
    uint winner_level;
    string confirm_mesg;
  }

  mapping(address => Player) players;

  address[] player_addresses;
  address[] winner_addresses;
  address[] cache;

  uint256 public winner_level;
  uint256 public entryPrice;
  // Allocation for first/sencond/third reward
  uint256[3] public allocation;
  uint8[3] public winner_numbers;

  enum ContestStates {
        IN_PROGRESS,
        COLLECTION_FINISHED,
        WINNER_PICKED
  }

  constructor (address _SATOSHI, uint256 _finishTime) public {
    require(_finishTime != 0, "Finish time cannot be 0.");

    owner = msg.sender;
    finishTime = _finishTime;
    allocation = [5000, 2700, 1500];
    winner_level = 3;
    winner_numbers = [1, 3, 10];
    entryPrice = 10000000000000000;

    SATOSHI = IBEP20(_SATOSHI);
  }

  //Function that can be called by creator to withdraw up to 50% of eth deposited. Contract will always hold 50% until contest is over.
  function withdraw(uint256 _amount) public onlyBy(owner) {
    require(address(this).balance > 0, "Insufficient balance");
    require(address(this).balance > _amount, "Amount is not valid");
    owner.transfer(_amount);
  }

  //Receive bnb and record player.
  function entry() public nonReentrant payable atState(ContestStates.IN_PROGRESS) {
    require(msg.value >= entryPrice, "Insufficient BNB");

    if (players[msg.sender].ts == 0) {
      player_addresses.push(msg.sender);
    }

    Player memory np = Player (now, 0, "");
    players[msg.sender] = np;
  }

  function draw (uint256 _externalRandomNumber) public onlyBy(owner) atState(ContestStates.COLLECTION_FINISHED) {
    uint i = 0;
    // Construct the winner_addresses array
    for (i=0; i<player_addresses.length; i++) {
        cache.push(player_addresses[i]);
    }
    
    bytes32 _structHash;
    uint256 _randomNumber;
    bytes32 _blockhash = blockhash(block.number-1);
    uint256 gasLeft = gasleft();
    uint winnerTotalNumber = winner_numbers[0] + winner_numbers[1] + winner_numbers[2];

    
    
  }

  function confirm (string memory _confirm_mesg) public atState(ContestStates.WINNER_PICKED) {
    bool is_winner = false;
    for (uint i=0; i<winner_addresses.length; i++) {
        if (msg.sender == winner_addresses[i]) {
            is_winner = true;
            break;
        }
    }
    require (players[msg.sender].winner_level > 0, "You are not winner");

    players[msg.sender].confirm_mesg = _confirm_mesg;
  }

  function playerInfo (address _addr) view public returns (Player memory) {
    Player memory p = players[_addr];

    return p;
  }

  function state() private view returns (ContestStates) {
    if (winner_addresses.length > 0) return ContestStates.WINNER_PICKED;
    if (now >= finishTime) return ContestStates.COLLECTION_FINISHED;
    //'now' generates a warning, but it does not concern this contract too much.
    //Just like with any crowdsale (see OpenZeppelin examples) it is ok to base limit
    //logic on 'now'. Worst case - someone will send us some ETH right after Contest
    //finished collection
    return ContestStates.IN_PROGRESS;
  }

  // Set the allocation for one reward
  function setAllocation(uint8 _allcation1, uint8 _allcation2, uint8 _allcation3) external onlyBy(owner) {
      allocation = [_allcation1, _allcation2, _allcation3];
  }

  // Set winner numbers
  function setWinderNumbers(uint8 _number1, uint8 _number2, uint8 _number3) external onlyBy(owner) {
      winner_numbers = [_number1, _number2, _number3];
  }

  function setEntryPrice(uint256 _entryPrice) external onlyBy(owner) {
      require(_entryPrice > 0, "price is not valid");
      entryPrice = _entryPrice;
  }

  function setFinishTime(uint256 _finishTime) external onlyBy(owner) {
      require(_finishTime > 0, "time is not valid");
      finishTime = _finishTime;
  }

  modifier atState(ContestStates _state) {
      require(state() == _state, "Invalid Contest state");
      _;
  }

  modifier onlyBy(address _account) {
      require(msg.sender == _account, "Function only avialable to Contest owner");
      _;
  }
}