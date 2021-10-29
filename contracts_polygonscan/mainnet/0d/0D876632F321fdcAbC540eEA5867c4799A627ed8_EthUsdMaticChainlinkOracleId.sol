/**
 *Submitted for verification at polygonscan.com on 2021-10-29
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts/oracles/onchainSubIds/chainlink/EthUsdMaticOracleSubId.sol

pragma solidity =0.6.6;


interface IShortAggregatorInterface {
  function latestAnswer() external view returns (int256);
}

contract EthUsdMaticOracleSubId {
  using SafeMath for uint256;

  function getResult() public view returns (uint256) {
    // Instance of Chainlink ETH/USD price feed
    uint256 ethUsdPrice = uint256(IShortAggregatorInterface(0xF9680D99D6C9589e2a93a78A04A279e509205945).latestAnswer());

    // Data are provided with 8 decimals, adjust to 18 decimals
    uint256 result = ethUsdPrice.mul(1e10);

    return result;
  }
}

// File: contracts/oracles/chainlink/EthUsdMaticChainlinkOracleId.sol

pragma solidity =0.6.6;


/// @title Opium.Interface.IOracleId contract is an interface that every oracleId should implement
interface IOracleId {
    /// @notice Requests data from `oracleId` one time
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(uint256 timestamp) external payable;

    /// @notice Requests data from `oracleId` multiple times
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(uint256 timestamp, uint256 period, uint256 times) external payable;

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice() external returns (uint256 fetchPrice);

    // Event with oracleId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

interface IOracleAggregator {
  function __callback(uint256 timestamp, uint256 data) external;
  function hasData(address oracleId, uint256 timestamp) external view returns(bool result);
}

contract EthUsdMaticChainlinkOracleId is EthUsdMaticOracleSubId, IOracleId {
  event Provided(uint256 indexed timestamp, uint256 result);

  // Opium
  IOracleAggregator public oracleAggregator;

  // Governance
  address public _owner;
  uint256 public EMERGENCY_PERIOD;

  modifier onlyOwner() {
    require(_owner == msg.sender, "N.O"); // N.O = not an owner
    _;
  }

  constructor(IOracleAggregator _oracleAggregator, uint256 _emergencyPeriod) public {
    // Opium
    oracleAggregator = _oracleAggregator;

    // Governance
    _owner = msg.sender;
    EMERGENCY_PERIOD = _emergencyPeriod;
    /*
    {
      "author": "Opium.Team",
      "description": "ETH/USD Oracle ID",
      "asset": "ETH/USD",
      "type": "onchain",
      "source": "chainlink",
      "logic": "none",
      "path": "latestAnswer()"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"description\":\"ETH/USD Oracle ID\",\"asset\":\"ETH/USD\",\"type\":\"onchain\",\"source\":\"chainlink\",\"logic\":\"none\",\"path\":\"latestAnswer()\"}");
  }

  /** OPIUM INTERFACE */
  function fetchData(uint256 _timestamp) external payable override {
    _timestamp;
    revert("N.S"); // N.S = not supported
  }

  function recursivelyFetchData(uint256 _timestamp, uint256 _period, uint256 _times) external payable override {
    _timestamp;
    _period;
    _times;
    revert("N.S"); // N.S = not supported
  }

  function calculateFetchPrice() external override returns (uint256) {
    return 0;
  }
  
  /** RESOLVER */
  function _callback(uint256 _timestamp) public {
    require(
      !oracleAggregator.hasData(address(this), _timestamp) &&
      _timestamp < now,
      "N.A" // N.A = Only when no data and after timestamp allowed
    );

    uint256 result = getResult();
    oracleAggregator.__callback(_timestamp, result);

    emit Provided(_timestamp, result);
  }

  /** GOVERNANCE */
  /** 
    Emergency callback allows to push data manually in case EMERGENCY_PERIOD elapsed and no data were provided
   */
  function emergencyCallback(uint256 _timestamp, uint256 _result) public onlyOwner {
    require(
      !oracleAggregator.hasData(address(this), _timestamp) &&
      _timestamp + EMERGENCY_PERIOD  < now,
      "N.E" // N.E = Only when no data and after emergency period allowed
    );

    oracleAggregator.__callback(_timestamp, _result);

    emit Provided(_timestamp, _result);
  }

  function changeOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    _owner = _newOwner;
  }

  function changeEmergencyPeriod(uint256 _newEmergencyPeriod) public onlyOwner {
    EMERGENCY_PERIOD = _newEmergencyPeriod;
  }
}