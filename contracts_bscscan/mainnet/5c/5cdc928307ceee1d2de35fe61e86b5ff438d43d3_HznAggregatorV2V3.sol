/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-28
*/

// File: @chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorInterface.sol

pragma solidity >=0.5.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: @chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// File: @chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol

pragma solidity >=0.5.0;



/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
  //
  // V2 Interface:
  //
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

  //
  // V3 Interface:
  //
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interface/iPancakeRouterV2.sol

pragma solidity ^0.5.16;

interface iPancakeRouterV2 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/hznAggregator.sol

pragma solidity ^0.5.16;





// interface iPancakeRouterV2 {
//     function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
// }

contract HznAggregatorV2V3 is AggregatorV2V3Interface {
    using SafeMath for uint;
    // using SafeDecimalMath for uint;

    uint public roundID = 0;
    uint public keyDecimals = 0;
    //here we simplify the window size as how many rounds we use to calculate th TWAP
    uint public windowSize = 0;
    uint public pcsWeight = 50;

    struct Entry {
        uint roundID;
        uint answer;
        uint originAnswer;
        uint startedAt;
        uint updatedAt;
        uint answeredInRound;
        uint priceCumulative;
    }

    mapping(uint => Entry) public entries;
    address owner;
    address operator;

    //pancakeRouterV2 contracat addresss
    address pancakeRouterV2Addr;

    //pancake swap path
    //should be [hzn,wbnb,busd(or other stable coin)]
    address[] path;

    //swap amount should be 1 hzn = 1e18
    uint amountIn;

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // event AnswerUpdated(uint256 indexed answer, uint256 timestamp);

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    modifier onlyOperator {
        _onlyOperator();
        _;
    }

    function _onlyOperator() private view {
        require(msg.sender == operator, "Only the contract owner may perform this action");
    }

    constructor(address _owner,
                uint _decimals,
                uint _windowSize,
                address _operator,
                address _pancakeV2,
                address[] memory _path,
                uint _amountIn) public {
        owner = _owner;
        keyDecimals = _decimals;
        windowSize = _windowSize;
        operator = _operator;
        pancakeRouterV2Addr = _pancakeV2;
        path = _path;
        amountIn = _amountIn;
    }

    //========  setters ================//
    function setDecimals(uint _decimals) external onlyOwner {
        keyDecimals = _decimals;
    }

    function setWindowSize(uint _windowSize)external onlyOwner  {
        windowSize = _windowSize;
    }

    function setAmountsOut(uint _amountIn,address[] calldata _path) external onlyOwner {
        amountIn = _amountIn;
        path = _path;
    }

    //========== add price================//
    /***
    this is for decentralized mode,
    when triggered by offline server , will query from pancake router v2 to get hzn busd price
    for mainnet
    https://bscscan.com/address/0x10ed43c718714eb63d5aa57b78b54704e256024e#readContract
    6. getAmountsOut

    amountIn: 1000000000000000000
    //means 1 hzn

    path:[0xc0eff7749b125444953ef89682201fb8c6a917cd,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xe9e7cea3dedca5984780bafc599bd69add087d56]
    //means :hzn -> wbnb -> busd

    output:
    amounts   uint256[] :  100000000000000000000   //1 hzn
    131032688024315468                             //0.00131 bnb
    72233046540554662116                           //0.7223 BUSD
     */
    function updateLatestAnswer() external onlyOperator {

        //todo get answer from pancake smart contract
        iPancakeRouterV2 ip = iPancakeRouterV2(pancakeRouterV2Addr);
        uint[] memory latest = ip.getAmountsOut(amountIn, path);
        uint answer = latest[latest.length - 1];


        if (entries[0].updatedAt > 0 ){
            roundID++;
        }

        entries[roundID] = calculateTWAP(roundID,answer,now);
        emit AnswerUpdated(int(answer), roundID, now);
    }

    function setLatestAnswer(uint answer) external onlyOperator {
        if (roundID > 0){
            roundID++;
        }
        entries[roundID] = calculateTWAP(roundID,answer,now);
        emit AnswerUpdated(int(answer), answer,now);
    }

    function setPCSWeight(uint weight) external onlyOwner {
        require(weight <= 100,"weight is greater than 100");
        pcsWeight = weight;
    }

    function setMixedAnwer(uint answer ) external onlyOperator {
        require(answer > 0 ,"answer should greater than 0");
        if (entries[0].updatedAt > 0 ){
            roundID++;
        }
        //1. get answer from pancake smart contract
        if (pcsWeight == 0){
            entries[roundID] = calculateTWAP(roundID,answer,now);
        }else{
            iPancakeRouterV2 ip = iPancakeRouterV2(pancakeRouterV2Addr);
            uint[] memory latest = ip.getAmountsOut(amountIn, path); 
            uint pAnswer = latest[latest.length - 1];

            uint newAnswer = answer.mul(100 - pcsWeight).add(pAnswer.mul(pcsWeight)).div(100);
            entries[roundID] = calculateTWAP(roundID,newAnswer,now);
        }

        emit AnswerUpdated(int(answer), answer,now);
    }


    function setPancakeRouterV2Addr(address _pancakeV2) external onlyOwner() {
        pancakeRouterV2Addr = _pancakeV2;
    }


    //====================interface ==================================
    function latestAnswer() external view returns (int256) {
        Entry memory entry = entries[roundID];
        return int256(entry.answer);
    }

    function latestTimestamp() external view returns (uint256){
        Entry memory entry = entries[roundID];
        return entry.updatedAt;
    }



    function latestRoundData()
        external
        view
        returns (
           uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return getRoundData(uint80(latestRound()));
    }

    function latestRound() public view returns (uint256) {
        return roundID;
    }

    function decimals() external view returns (uint8) {
        return uint8(keyDecimals);
    }

    function description() external view returns (string memory){
        return "hzn";
    }

    function version() external view returns (uint256){
        return 1;
    }

    function getAnswer(uint256 _roundId) external view returns (int256) {
        Entry memory entry = entries[_roundId];
        return int256(entry.answer);
    }

    function getTimestamp(uint256 _roundId) external view returns (uint256) {
        Entry memory entry = entries[_roundId];
        return entry.updatedAt;
    }

    function getRoundData(uint80 _roundId)
        public
        view
        returns (
           uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        Entry memory entry = entries[_roundId];
        // Emulate a Chainlink aggregator
        require(entry.updatedAt > 0, "No data present");
        return (uint80(entry.roundID), int256(entry.answer), entry.startedAt, entry.updatedAt, uint80(entry.answeredInRound));
    }


    function calculateTWAP(uint currentRoundId,uint answer,uint timestamp) internal view returns(Entry memory) {
        if (currentRoundId == 0 ){
            return  Entry({
                roundID: currentRoundId,
                answer: answer,
                originAnswer: answer,
                startedAt: timestamp,
                updatedAt: timestamp,
                answeredInRound: currentRoundId,
                priceCumulative: 0
            });
        }
        uint firstIdx = 0;
        if (windowSize >= currentRoundId) {
            firstIdx = 0;
        }else{
            firstIdx = currentRoundId - windowSize + 1;
        }
        Entry memory first = entries[firstIdx];
        Entry memory last = entries[currentRoundId - 1];

        if (first.roundID == last.roundID){
            return  Entry({
                roundID: currentRoundId,
                answer: answer,
                originAnswer: answer,
                startedAt: timestamp,
                updatedAt: timestamp,
                answeredInRound: currentRoundId,
                priceCumulative: last.priceCumulative.add(answer.mul(timestamp.sub(first.updatedAt)))
            });
        }

        uint current_priceCumulative = last.priceCumulative.add(answer.mul(timestamp.sub(last.updatedAt)));
        uint current_answer = (current_priceCumulative.sub(first.priceCumulative)).div(timestamp.sub(first.updatedAt));
        return Entry({
            roundID: currentRoundId,
            answer: current_answer,
            originAnswer: answer,
            startedAt: timestamp,
            updatedAt: timestamp,
            answeredInRound: currentRoundId,
            priceCumulative: current_priceCumulative
        });

    }
}