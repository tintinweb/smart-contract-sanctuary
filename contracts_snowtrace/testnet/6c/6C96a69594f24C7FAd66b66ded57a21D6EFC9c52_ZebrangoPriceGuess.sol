// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./Ownable.sol";

import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";



contract ZebrangoPriceGuess is Pausable , ReentrancyGuard, Ownable{


    AggregatorV3Interface public oracle;

    //genesisRound
    bool public genesisLocked = false;
    bool public genesisStarted = false;

    //operators
    address public admin;
    address public operator;
    address public govAddress;

    //Timing settings
    uint256 public bufferSeconds;
    uint256 public intervalSeconds;


    uint256 public minBet;
    uint256 public fee; //fee rate 200 = 2%
    uint256 public reserve; //reserve amount

    uint256 public currentRound; //current round

    uint256 public oracleLatestRoundId;
    uint256 public oracleUpdateAllowance;

    uint256 public constant MAX_FEE = 1000;

    mapping(uint256 => mapping(address => BetInfo)) public docs;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[] ) public userRounds;

    enum Stand {
        Up,Down
    }
    struct Round {
        uint256 episode;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockprice;
        int256 closeprice;
        uint256 lockOracleId;
        uint256 closeOracleID;
        uint256 totalAmount;
        uint256 upAmount;
        uint256 downAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;

    }

    struct BetInfo {
        Stand stand;
        uint256 amount;
        bool claimed; // Default false
   }

    event BetUp(address indexed sender, uint256 indexed episode, uint256 amount);
    event BetDown(address indexed sender, uint256 indexed episode, uint256 amount);
    event Claim(address indexed sender, uint256 indexed episode, uint256 amount);
    event EndRound(uint256 indexed episode, uint256 indexed roundId, int256 price);
    event LockRound(uint256 indexed episode, uint256 indexed roundId, int256 price);
    event NewAdminAddress(address admin);
    event NewBufferAndIntervalSeconds(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewMinBetAmount(uint256 indexed episode, uint256 minBet);
    event NewFee(uint256 indexed episode, uint256 Fee);
    event NewOperatorAddress(address operator);
    event NewOracle(address oracle);
    event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);
    event Pause(uint256 indexed episode);
    event RewardsCalculated(
        uint256 indexed episode,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );
    event StartRound(uint256 indexed episode);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed episode);


    //modifers
    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }
    modifier onlyOperator() {
        require(msg.sender == operator, "operator");
        _;
    }
    modifier onlyAdminOrOperator (){
        require(msg.sender == admin || msg.sender == operator, "not admin nor operator");
        _;
    }

    modifier onlyGov(){
      require(msg.sender == govAddress, "can only Called by the governance contract.");
      _;
    }

    constructor(address _oracleAddress,address _adminAddress,address _operatorAddress, address _govAddress,uint256 _intervalSeconds,uint256 _bufferSeconds,uint256 _minBet,uint256 _oracleUpdateAllowance,uint256 _fee){

        require(_fee <= MAX_FEE , "the fee is too high.");

        oracle = AggregatorV3Interface(_oracleAddress);
        admin = _adminAddress;
        operator = _operatorAddress;
        govAddress = _govAddress;
        intervalSeconds = _intervalSeconds;
        bufferSeconds = _bufferSeconds;
        minBet = _minBet;
        oracleUpdateAllowance = _oracleUpdateAllowance;
        fee = _fee;
        }



    // bet the Price will go up.
    function betUp (uint256 episode) external payable whenNotPaused nonReentrant{
          require(episode == currentRound ,"Bet is too early / late");
          require(_bettable(episode), "round is not bettable");
          require(msg.value >= minBet, "Bet amout is too low");
          require(docs[episode][msg.sender].amount == 0 , "can only bet once");



          //update rounds Date
          uint256 amount = msg.value;
          Round storage round = rounds[episode];
          round.totalAmount +=  amount;
          round.upAmount += amount;

          //update user data
          BetInfo storage betInfo = docs[episode][msg.sender];
          betInfo.stand = Stand.Up;
          betInfo.amount = amount;

          userRounds[msg.sender].push(episode);

          emit BetUp(msg.sender, episode, amount);

    }
    // bet the Price will go down.
    function betDown(uint256 episode) external payable whenNotPaused nonReentrant {

          require(episode == currentRound , "bet is too early/late.");
          require(_bettable(episode) , "round is not bettable.");
          require(msg.value >= minBet, "bet is too low.");
          require(docs[episode][msg.sender].amount == 0 ,"can only bet Once.");


          //update round data
          uint256 amount = msg.value;
          Round storage round = rounds[episode];
          round.totalAmount += amount;
          round.downAmount += amount;

          //update userData

          BetInfo storage betInfo = docs[episode][msg.sender];
          betInfo.stand = Stand.Down;
          betInfo.amount = amount;

          userRounds[msg.sender].push(episode);

          emit BetDown(msg.sender, episode, amount);
    }

    function claim(uint256 [] calldata episodes) external nonReentrant{
      uint256 reward;

      for (uint256 i=0; i < episodes.length; i++){
        require(rounds[episodes[i]].startTimestamp != 0, "round has not started yet.");
        require(block.timestamp > rounds[episodes[i]].closeTimestamp, "round did not finish yet.");

        uint256 addedReward = 0;

        if(rounds[episodes[i]].oracleCalled){
          require(claimable(episodes[i] , msg.sender) , "not Claimable.");
          Round memory round = rounds[episodes[i]];
          addedReward = (docs[episodes[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
        }
        else{
          require(refundable(episodes[i], msg.sender), "not refundable");
          addedReward = docs[episodes[i]][msg.sender].amount;
        }
        docs[episodes[i]][msg.sender].claimed = true;
        reward += addedReward;
        emit Claim(msg.sender, episodes[i] , addedReward);
      }
      if (reward > 0 ){
        _safeTransfer(msg.sender, reward);
      }
    }




   function setFee(uint256 _fee) external whenPaused onlyAdmin {
       require(_fee <= MAX_FEE, "Treasury fee too high");
       fee = _fee;
       emit NewFee(currentRound, fee);
   }


   function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds)
          external
          whenPaused
          onlyAdmin
      {
          require(_bufferSeconds < _intervalSeconds, "bufferSeconds must be inferior to intervalSeconds");
          bufferSeconds = _bufferSeconds;
          intervalSeconds = _intervalSeconds;

          emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
      }


      function setMinBetAmount(uint256 _minBetAmount) external whenPaused onlyAdmin {
          require(_minBetAmount != 0, "Must be superior to 0");
          minBet = _minBetAmount;

          emit NewMinBetAmount(currentRound, minBet);
      }
      function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        admin = _adminAddress;

        emit NewAdminAddress(_adminAddress);
      }

      function setOperator(address _operatorAddress) external onlyAdmin {
      require(_operatorAddress != address(0), "Cannot be zero address");
      operator = _operatorAddress;

      emit NewOperatorAddress(_operatorAddress);
      }

      function setOracle(address _oracle) external whenPaused onlyAdmin {
        require(_oracle != address(0), "Cannot be zero address");
        oracleLatestRoundId = 0;
        oracle = AggregatorV3Interface(_oracle);

        // Dummy check to make sure the interface implements this function properly
        oracle.latestRoundData();

        emit NewOracle(_oracle);
      }

      function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external whenPaused onlyAdmin {
     oracleUpdateAllowance = _oracleUpdateAllowance;

     emit NewOracleUpdateAllowance(_oracleUpdateAllowance);
 }





    function executeRound() external whenNotPaused onlyOperator {
      require(genesisStarted && genesisLocked , "can only run after Genesis round is started and locked");
      (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();
      oracleLatestRoundId = uint256(currentRoundId);

      //current episodes
      _safeLockRound(currentRound , currentRoundId, currentPrice);
      _safeEndRound(currentRound - 1, currentRoundId, currentPrice);
      _calculateRewards(currentRound - 1);

      currentRound = currentRound + 1;
      _safeStartRound(currentRound);

    }

    function _calculateRewards(uint256 episode) internal {
      require(rounds[episode].rewardBaseCalAmount == 0 && rounds[episode].rewardAmount == 0, "rewards already calculated.");
      Round storage round = rounds[episode];
      uint256 rewardBaseCalAmount;
      uint256 feeAmount;
      uint256 rewardAmount;

      // Up wins

      if(round.closeprice > round.lockprice) {
        rewardBaseCalAmount = round.upAmount;
        feeAmount = (round.totalAmount * fee) / 10000;
        rewardAmount = round.totalAmount - feeAmount;
      }
      // down wins
      else if(round.closeprice < round.lockprice){
        rewardBaseCalAmount = round.downAmount;
        feeAmount = (round.totalAmount * fee) / 10000;
        rewardAmount = round.totalAmount - feeAmount;
      }
      //Reserve Wins!
      else{
        rewardBaseCalAmount = 0;
        rewardAmount = 0;
        feeAmount = round.totalAmount;
      }
      round.rewardBaseCalAmount = rewardBaseCalAmount;
      round.rewardAmount = rewardAmount;
      reserve += feeAmount;

      emit RewardsCalculated(episode, rewardBaseCalAmount, rewardAmount, feeAmount);
    }

    function genesisStartRound() external whenNotPaused onlyOperator {
      require(!genesisStarted, "can only run once.");
      currentRound = currentRound + 1;
      _startRound(currentRound);
      genesisStarted = true;
    }

    function genesisLockRound() external whenNotPaused onlyOperator{
      require(genesisStarted, "can only run after genesis is started.");
      require(!genesisLocked, "can only run once.");
      (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle();
      oracleLatestRoundId = uint256(currentRoundId);
      _safeLockRound(currentRound, currentRoundId, currentPrice);

      currentRound = currentRound + 1;
      _startRound(currentRound);
      genesisLocked = true;

    }

    function _safeTransfer(address to, uint256 value) internal {
      (bool success, )  = to.call{value: value}("");
      require(success , "Transfer Failed.");
    }

    function _startRound(uint256 episode) internal {
      Round storage round = rounds[episode];
      round.startTimestamp = block.timestamp;
      round.lockTimestamp = block.timestamp + intervalSeconds;
      round.closeTimestamp = block.timestamp + (2 * intervalSeconds);
      round.episode = episode;
      round.totalAmount = 0;

      emit StartRound(episode);
    }

    function _safeEndRound(uint256 episode, uint256 roundId, int256 price) internal {
      require(rounds[episode].lockTimestamp != 0 , "can only end round after locking it");
      require(block.timestamp <= rounds[episode].closeTimestamp + bufferSeconds, "Can only end round within bufferSeconds");
      require(block.timestamp >= rounds[episode].closeTimestamp , "Can only end round within bufferSeconds");
      Round storage round = rounds[episode];
      round.closeprice = price;
      round.closeOracleID = roundId;
      round.oracleCalled = true;

      emit EndRound(episode, roundId, price);
    }

    function _safeLockRound(uint256 episode, uint256 roundId, int256 price) internal {
      require(rounds[episode].startTimestamp != 0, "can only lock after the round has started.");
      require(block.timestamp >= rounds[episode].lockTimestamp, "can only lock within buffer seconds.");
      require(block.timestamp <= rounds[episode].lockTimestamp + bufferSeconds , "can only lock within buffer seconds.");
      Round storage round = rounds[episode];
      round.closeTimestamp = block.timestamp + intervalSeconds;
      round.lockprice = price;
      round.lockOracleId = roundId;

      emit LockRound(episode, roundId, price);
    }

    function _safeStartRound(uint256 episode) internal {
      require(genesisStarted, "Can only after genesis is started");
      require(rounds[episode - 2].closeTimestamp != 0, "can only start this round after round n-2 is finished.");
      require(block.timestamp >= rounds[episode -2].closeTimestamp, "can only start new round after round n-2 close timestamp.");
      _startRound(episode);
    }

    function _getPriceFromOracle() internal view returns(uint80, int256){
      uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
      (uint80 roundId, int256 price , , uint256 timestamp, ) = oracle.latestRoundData();
      require(timestamp <= leastAllowedTimestamp, "oracle update exceeded the allowed max lockTimestamp.");
      require(uint256(roundId) > oracleLatestRoundId , "oracle update roundId must be larger than oracle last update");
      return (roundId, price);

    }

    //determin if the round is valid
    function _bettable(uint256 episode) internal view returns (bool) {
    return
            rounds[episode].startTimestamp != 0 &&
            rounds[episode].lockTimestamp != 0 &&
            block.timestamp >= rounds[episode].startTimestamp &&
            block.timestamp < rounds[episode].lockTimestamp;
    }

    function claimable(uint256 episode, address user) public view returns (bool){
      BetInfo memory betInfo = docs[episode][user];
      Round memory round = rounds[episode];
      if (round.lockprice == round.closeprice){
        return false;
      }
      return
        round.oracleCalled &&
        betInfo.amount != 0 &&
        !betInfo.claimed &&
        ((round.closeprice > round.lockprice && betInfo.stand == Stand.Up) ||
                (round.closeprice < round.lockprice && betInfo.stand == Stand.Down));
    }

    function refundable(uint256 episode, address user) public view returns (bool) {
            BetInfo memory betInfo = docs[episode][user];
            Round memory round = rounds[episode];
            return
                !round.oracleCalled &&
                !betInfo.claimed &&
                block.timestamp > round.closeTimestamp + bufferSeconds &&
                betInfo.amount != 0;
        }



    function withdrowGov()external onlyGov returns(uint256 _amt){
        uint256 currentAmount = reserve;
        _safeTransfer(govAddress, currentAmount);
        reserve = 0;
        _amt = currentAmount;
    }

    /**
   * @notice Returns round epochs and bet information for a user that has participated
   * @param user: user address
   * @param cursor: cursor
   * @param size: size
   */
  function getUserRounds(
      address user,
      uint256 cursor,
      uint256 size
  )
      external
      view
      returns (
          uint256[] memory,
          BetInfo[] memory,
          uint256
      )
  {
      uint256 length = size;

      if (length > userRounds[user].length - cursor) {
          length = userRounds[user].length - cursor;
      }

      uint256[] memory values = new uint256[](length);
      BetInfo[] memory betInfo = new BetInfo[](length);

      for (uint256 i = 0; i < length; i++) {
          values[i] = userRounds[user][cursor + i];
          betInfo[i] = docs[values[i]][user];
      }

      return (values, betInfo, cursor + length);
  }
  /**
   * @notice Returns round epochs length
   * @param user: user address
   */
  function getUserRoundsLength(address user) external view returns (uint256) {
      return userRounds[user].length;
  }

    /**
   * @notice called by the admin to pause, triggers stopped state
   * @dev Callable by admin or operator
   */
  function pause() external whenNotPaused onlyAdminOrOperator {
      _pause();

      emit Pause(currentRound);
  }

  /**
 * @notice called by the admin to unpause, returns to normal state
 * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
 */
function unpause() external whenPaused onlyAdmin {
    genesisStarted = false;
    genesisLocked = false;
    _unpause();

    emit Unpause(currentRound);
}


    fallback ()external payable{

    }
    receive()external payable{

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";



pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}