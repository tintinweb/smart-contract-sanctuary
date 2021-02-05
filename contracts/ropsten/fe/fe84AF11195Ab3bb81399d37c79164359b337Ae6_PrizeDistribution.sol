/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/*
* TODO:
* We should allow pseudonymous users to provide backing for
* competitions by guaranteeing prize pools.
* They will earn a commission for doing this.
*/

/*
* TODO:
* We should add support for generic ERC20 tokens.
* The creator of a competition can set the asset contract that should
* be used for the prize pool / entrance fees.
*/

/*
* TODO:
* The owner of the contract should be able to define
* tiered commission rates, so higher % can be charged on
* competitions with a small prize pool, and smaller on
* large prize pools.
*/

contract PrizeDistribution is Ownable {

  using SafeMath for uint256;

  /**
   * @dev Throws if competition does not exist.
   */
  modifier competitionExists(uint256 _competitionId) {
    require(competitions[_competitionId].valid,
      "The competition does not exist.");
    _;
  }

  struct Competition {
    string title;
    address owner;
    string externalReference;
    uint256 entryFee;
    uint256 startBlock;
    uint256 endBlock;
    bool valid;
    bool canceled;
    bool commissionPaid;
    bool prizesPaid;
    uint256 commissionRate;
    uint256 stakeToPrizeRatio;
    address[] players;
    uint256[] prizeDistribution;
    address[] playerRanks;
    mapping (address => uint256) deposits;
  }

  mapping (uint => Competition) public competitions;
  uint256 public competitionCount = 0;
  uint256 public commissionRate;
  uint256 public maxPlayers;

  /**
  * @dev Sets the commission rate charged on competitions and max players
  * permitted in a single competition on creation of the contract.
  */
  constructor(
    uint256 _commissionRate,
    uint256 _maxPlayers
  ) public {
    maxPlayers = _maxPlayers;
    updateCommissionRate(_commissionRate);
  }

  /**
  * @dev Updates the commission rate used for competitions.
  */
  function updateCommissionRate(uint256 _commissionRate) public onlyOwner {
    require(_commissionRate <= 1000, "Commission rate must be <= 1000.");
    commissionRate = _commissionRate;
  }

  /**
  * @dev Returns the commission that is charged by the smart contract on
  * prize pools. A number between 0 and 1000, where 1000 = 100%.
  *
  * The commission is redeemable by the owner of the contract.
  */
  function getCommissionRate() public view returns (uint256) {
    return commissionRate;
  }

  /**
  * @dev Returns the number of created competitions.
  */
  function getCompetitionCount() public view returns (uint256) {
    return competitionCount;
  }

  /**
  * @dev Returns a competition by ID.
  */
  function getCompetition(
    uint _competitionId
  ) public competitionExists(_competitionId) view returns (
    string memory,
    address,
    string memory,
    uint256,
    uint256,
    uint256,
    bool,
    uint256,
    uint256,
    uint256,
    uint256
  ) {
    Competition storage competition = competitions[_competitionId];
    return (
      competition.title,
      competition.owner,
      competition.externalReference,
      competition.entryFee,
      competition.startBlock,
      competition.endBlock,
      competition.canceled,
      competition.players.length,
      competition.commissionRate,
      competition.stakeToPrizeRatio,
      competition.commissionRate
    );
  }

  /**
  * @dev Returns try if the prizes have been paid
  */
  function isCompetitionPaid(
    uint _competitionId
  ) public view competitionExists(_competitionId) returns (bool) {
    Competition storage competition = competitions[_competitionId];
    return competition.prizesPaid;
  }

  /**
  * @dev Returns true if competition has been canceled by owner
  */
  function isCompetitionCanceled(
    uint _competitionId
  ) public view competitionExists(_competitionId) returns (bool) {
    Competition storage competition = competitions[_competitionId];
    return competition.canceled;
  }

  /**
  * @dev Anybody can create new competitions, and they will be deemed to be
  * the owner of the competition.
  */
  function createCompetition(
    string memory _title,
    string memory _externalReference,
    uint256 _entryFee,
    uint256 _startBlock,
    uint256 _endBlock
  ) public {
    require(_startBlock > block.number,
      "The start block must be after the current block.");
    require(_endBlock > _startBlock,
      "The end block must be after the start block.");
    require(_entryFee > 0,
      "There must be a fee to enter the competition.");
    address[] memory _players;
    address[] memory _playerRanks;
    uint256[] memory _distribution;
    competitions[competitionCount] = Competition({
      title: _title,
      owner: msg.sender,
      externalReference: _externalReference,
      entryFee: _entryFee,
      startBlock: _startBlock,
      endBlock: _endBlock,
      valid: true,
      canceled: false,
      commissionPaid: false,
      prizesPaid: false,
      commissionRate: commissionRate,
      players: _players,
      prizeDistribution: _distribution,
      playerRanks: _playerRanks,
      stakeToPrizeRatio: 50
    });
    competitionCount += 1;
  }

  /**
   * @dev Anyone can enter a competition provided it is not full, has not
   * already started, has not been canceled, and they pay the required
   * entrance fee.
   */
  function enterCompetition(
    uint256 _competitionId
  ) public competitionExists(_competitionId) payable {
    Competition storage competition = competitions[_competitionId];
    require(msg.value == competition.entryFee,
      "You must deposit the exact entry fee in Ether.");
    require(competition.deposits[msg.sender] == 0x0,
      "You have already entered this competition.");
    require(!competition.canceled,
      "This competition has been canceled.");
    require(block.number < competition.startBlock,
      "This competition has already started.");
    require(competition.players.length < maxPlayers,
      "This competition is already full.");
    competition.deposits[msg.sender] = msg.value;
    competition.players.push(msg.sender);
  }

  /**
   * @dev The owner of a competition can cancel it if it has not started.
   */
  function cancelCompetition(
    uint256 _competitionId
  ) public competitionExists(_competitionId) {
    Competition storage competition = competitions[_competitionId];
    require(competition.owner == msg.sender,
      "Only the owner of a competition can cancel it.");
    require(!competition.canceled,
      "The competition has already been canceled.");
    require(competition.startBlock > block.number,
      "You cannot cancel the competition because it has already started.");
    competitions[_competitionId].canceled = true;
    for(uint256 i=0; i<competition.players.length; i++) {
      returnEntryFee(_competitionId, address(uint160(competition.players[i])));
    }
  }

  /**
   * @dev Returns a player's entrance fee (called internally on cancel).
   */
  function returnEntryFee(
    uint256 _competitionId,
    address payable _player
  ) internal {
    Competition storage competition = competitions[_competitionId];
    uint256 playerDeposit = competition.deposits[_player];
    _player.transfer(playerDeposit);
    competitions[_competitionId].deposits[_player] = 0;
  }

  /**
  * @dev Builds the prize distribution for a competition
  */
  function buildDistribution(
    uint256 _playerCount,
    uint256 _stakeToPrizeRatio,
    uint256 _competitionId
  ) internal view returns (uint256[] memory) {
    uint256[] memory prizeModel = buildFibPrizeModel(_playerCount);
    uint256[] memory distributions = new uint[](_playerCount);
    uint256 prizePool = getPrizePoolLessCommission(_competitionId);
    for (uint256 i=0; i<prizeModel.length; i++) {
      uint256 constantPool = prizePool.mul(_stakeToPrizeRatio).div(100);
      uint256 variablePool = prizePool.sub(constantPool);
      uint256 constantPart = constantPool.div(_playerCount);
      uint256 variablePart = variablePool.mul(prizeModel[i]).div(100);
      uint256 prize = constantPart.add(variablePart);
      distributions[i] = prize;
    }
    return distributions;
  }

  /**
  * @dev Builds the Fibonacci distribution used to allocate prizes
  */
  function buildFibPrizeModel(
    uint256 _playerCount
  ) internal pure returns (uint256[] memory) {
    uint256[] memory fib = new uint[](_playerCount);
    uint256 skew = 5;
    for (uint256 i=0; i<_playerCount; i++) {
      if (i <= 1) {
        fib[i] = 1;
      } else {
        // as skew increases, more winnings go towards the top quartile
        fib[i] = ((fib[i.sub(1)].mul(skew)).div(_playerCount)).add(fib[i.sub(2)]);
      }
    }
    uint256 fibSum = getArraySum(fib);
    for (uint256 i=0; i<fib.length; i++) {
      fib[i] = (fib[i].mul(100)).div(fibSum);
    }
    return fib;
  }

  /**
  * @dev Utility function to sum an array of uint256
  */
  function getArraySum(
    uint256[] memory _array
  ) internal pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i=0; i<_array.length; i++) {
      sum = sum.add(_array[i]);
    }
    return sum;
  }

  /**
   * @dev The owner of the smart contract can call this function to submit
   * the rank of each player once the competition has finished.
   *
   * Note: the owner does not need to necessarily be a sigle actor. The owner
   * of the contract could be a Multisig wallet with multiple signatories
   * required, resulting in this function performing the role of an oracle.
   */
  function submitPlayersByRank(
    uint256 _competitionId,
    address[] memory _players
  ) public competitionExists(_competitionId) onlyOwner {
    Competition storage competition = competitions[_competitionId];
    require(_players.length == competition.players.length,
      "You must submit ranks for every player in the competition.");
    require(competition.endBlock < block.number,
      "The competition has not finished yet.");
    competitions[_competitionId].playerRanks.length = 0;
    competition.prizeDistribution = buildDistribution(
      competition.players.length,
      competition.stakeToPrizeRatio,
      _competitionId
    );
    for(uint i=0; i<_players.length; i++) {
      require(competition.deposits[_players[i]] > 0,
        "You submitted a player that has not entered the competition.");
      competitions[_competitionId].playerRanks.push(_players[i]);
    }
  }

  /**
   * @dev Returns the prize distribution for a given competition
   */
  function getPrizeDistribution(
    uint256 _competitionId
  ) public competitionExists(_competitionId) view returns(uint256[] memory) {
    Competition storage competition = competitions[_competitionId];
    return competition.prizeDistribution;
  }

  /**
   * @dev If the the player ranks have been set by the owner, then
   * anybody can call this function and the prizes will be distributed to
   * the original depositors according the prize distribution and player ranks.
   */
  function withdrawPrizes(
    uint256 _competitionId
  ) public competitionExists(_competitionId) {
    Competition storage competition = competitions[_competitionId];
    require(!competition.canceled,
      "This competition was canceled. There are no prizes to withdraw.");
    require(!competition.prizesPaid, "The prizes have already been paid.");
    require(competition.playerRanks.length > 0,
      "The player ranks have not been set yet.");
    for(uint256 i=0; i<competition.players.length; i++) {
      address(uint160(competition.playerRanks[i]))
        .transfer(competition.prizeDistribution[i]);
    }
    competition.prizesPaid = true;
  }

  function getPrizePoolLessCommission(
    uint256 _competitionId
  ) public competitionExists(_competitionId) view returns(uint256) {
    Competition storage competition = competitions[_competitionId];
    uint256 totalPrizePool = (competition.players.length
                              .mul(competition.entryFee))
                              .sub(getCommission(_competitionId));
    return totalPrizePool;
  }

  /**
  * @dev Anybody can withdraw unpaid commission to the contract owner.
  */
  function withdrawCommission(
    uint256 _competitionId
  ) public competitionExists(_competitionId) {
    Competition storage competition = competitions[_competitionId];
    require(!competition.commissionPaid,
      "The commission has already been paid out.");
    require(competition.startBlock < block.number,
      "The competition has not started yet.");
    address(uint160(owner())).transfer(getCommission(_competitionId));
    competition.commissionPaid = true;
  }

  /**
  * @dev Calculates the commission charged on a competition prize pool.
  */
  function getCommission(
    uint256 _competitionId
  ) public competitionExists(_competitionId) view returns(uint256) {
    Competition storage competition = competitions[_competitionId];
    return competition.players.length
            .mul(competition.entryFee)
            .mul(competition.commissionRate)
            .div(1000);
  }

  /**
   * @dev Ensures that it is not possible for Ether to enter the contract
   * unless through the context of entering a competition and paying then
   * correct entrance fee.
   */
  function() external payable {
    revert("You must not send Ether directly to this contract.");
  }
}