// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol


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

// File: openzeppelin-solidity/contracts/GSN/Context.sol


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/access/Roles.sol


/**
 * @title Roles
 * @notice copied from openzeppelin-solidity
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/access/WhitelistAdminRole.sol



/**
 * @title WhitelistAdminRole
 * @notice copied from openzeppelin-solidity
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: contracts/access/WhitelistedRole.sol



/**
 * @title WhitelistedRole
 * @notice copied from openzeppelin-solidity
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/oracle/ICADConversionOracle.sol


/**
 * @title ICADRateOracle
 * @notice provides interface for converting USD stable coins to CAD
*/
interface ICADConversionOracle {

    /**
     * @notice convert USD amount to CAD amount
     * @param amount     amount of USD in 18 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdToCad(uint256 amount) external view returns (uint256);

    /**
     * @notice convert Dai amount to CAD amount
     * @param amount     amount of dai in 18 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function daiToCad(uint256 amount) external view returns (uint256);

    /**
     * @notice convert USDC amount to CAD amount
     * @param amount     amount of USDC in 6 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdcToCad(uint256 amount) external view returns (uint256);


    /**
     * @notice convert USDT amount to CAD amount
     * @param amount     amount of USDT in 6 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdtToCad(uint256 amount) external view returns (uint256);


    /**
     * @notice convert CAD amount to USD amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USD in 18 decimal places
     */
    function cadToUsd(uint256 amount) external view returns (uint256);

    /**
     * @notice convert CAD amount to Dai amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of Dai in 18 decimal places
     */
    function cadToDai(uint256 amount) external view returns (uint256);

    /**
     * @notice convert CAD amount to USDC amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USDC in 6 decimal places
     */
    function cadToUsdc(uint256 amount) external view returns (uint256);

    /**
     * @notice convert CAD amount to USDT amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USDT in 6 decimal places
     */
    function cadToUsdt(uint256 amount) external view returns (uint256);
}

// File: contracts/oracle/ManagedCADChainlinkRateOracle.sol



/**
 * @title ManagedCADChainlinkRateOracle
 * @notice Provides a USD/CAD rate source managed by admin, and Chainlink powered DAI/USDC/USDT conversion rates.
 *  USDC is treated as always 1 USD, and used as anchor to calculate Dai and USDT rates
*/
contract ManagedCADChainlinkRateOracle is ICADConversionOracle, WhitelistedRole {
    using SafeMath for uint256;

    event ManagedRateUpdated(uint256 value, uint256 timestamp);

    // exchange rate stored as an integer
    uint256 public _USDToCADRate;

    // specifies how many decimal places have been converted into integer
    uint256 public _granularity;

    // specifies the time the exchange was last updated
    uint256 public _timestamp;

    // Chainlink price feed for Dai/Eth pair
    AggregatorV3Interface public daiEthPriceFeed;

    // Chainlink price feed for USDC/Eth pair
    AggregatorV3Interface public usdcEthPriceFeed;

    // Chainlink price feed for USDT/Eth pair
    AggregatorV3Interface public usdtEthPriceFeed;


    constructor(
        uint256 value,
        uint256 granularity,

        address daiEthAggregatorAddress,
        address usdcEthAggregatorAddress,
        address usdtEthAggregatorAddress
    ) public {
        _USDToCADRate = value;
        _granularity = granularity;
        _timestamp = block.timestamp;

        daiEthPriceFeed = AggregatorV3Interface(daiEthAggregatorAddress);
        usdcEthPriceFeed = AggregatorV3Interface(usdcEthAggregatorAddress);
        usdtEthPriceFeed = AggregatorV3Interface(usdtEthAggregatorAddress);

        _addWhitelisted(msg.sender);
    }

    /**
     * @notice admin can update the exchange rate
     * @param value         the new exchange rate
     * @param granularity   number of decimal places the exchange value is accurate to
     * @return  true if success
     */
    function updateManagedRate(uint256 value, uint256 granularity) external onlyWhitelisted returns (bool) {
        require(value > 0, "Exchange rate cannot be zero");
        require(granularity > 0, "Granularity cannot be zero");

        _USDToCADRate = value;
        _granularity = granularity;
        _timestamp = block.timestamp;

        emit ManagedRateUpdated(value, granularity);
        return true;
    }

     /**
     * @notice return the current managed values
     * @return latest USD to CAD exchange rate, granularity, and timestamp
     */
    function getManagedRate() external view returns (uint256, uint256, uint256) {
        return (_USDToCADRate, _granularity, _timestamp);
    }

    /**
     * @notice convert USD amount to CAD amount
     * @param amount     amount of USD in 18 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdToCad(uint256 amount) public view virtual override returns (uint256) {
        return amount.mul(_USDToCADRate).div(10 ** _granularity);
    }

    /**
     * @notice convert Dai amount to CAD amount
     * @param amount     amount of dai in 18 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function daiToCad(uint256 amount) external view virtual override returns (uint256) {
        (, int256 daiEthPrice, , uint256 daiEthTimeStamp,) = daiEthPriceFeed.latestRoundData();
        require(daiEthTimeStamp > 0, "Dai Chainlink Oracle data temporarily incomplete");
        require(daiEthPrice > 0, "Invalid Chainlink Oracle Dai price");

        (, int256 usdcEthPrice, , uint256 usdcEthTimeStamp,) = usdcEthPriceFeed.latestRoundData();
        require(usdcEthTimeStamp > 0, "USDC conversion Chainlink Oracle data temporarily incomplete");
        require(usdcEthPrice > 0, "Invalid Chainlink Oracle USDC conversion price");

        return amount.mul(_USDToCADRate).mul(uint256(daiEthPrice)).div(uint256(usdcEthPrice)).div(10 ** _granularity);
    }

    /**
     * @notice convert USDC amount to CAD amount
     * @param amount     amount of USDC in 6 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdcToCad(uint256 amount) external view virtual override returns (uint256) {
        // USDT has 6 decimals
        return usdToCad(amount.mul(1e12));
    }

    /**
     * @notice convert USDT amount to CAD amount
     * @param amount     amount of USDT in 6 decimal places
     * @return amount of CAD in 18 decimal places
     */
    function usdtToCad(uint256 amount) external view virtual override returns (uint256) {
        (, int256 usdtEthPrice, , uint256 usdtEthTimeStamp,) = usdtEthPriceFeed.latestRoundData();
        require(usdtEthTimeStamp > 0, "USDT Chainlink Oracle data temporarily incomplete");
        require(usdtEthPrice > 0, "Invalid Chainlink Oracle USDT price");

        (, int256 usdcEthPrice, , uint256 usdcEthTimeStamp,) = usdcEthPriceFeed.latestRoundData();
        require(usdcEthTimeStamp > 0, "USDC conversion Chainlink Oracle data temporarily incomplete");
        require(usdcEthPrice > 0, "Invalid Chainlink Oracle USDC conversion price");

        // USDT has 6 decimals
        return amount.mul(1e12).mul(_USDToCADRate).mul(uint256(usdtEthPrice)).div(uint256(usdcEthPrice)).div(10 ** _granularity);
    }


    /**
     * @notice convert CAD amount to USD amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USD in 18 decimal places
     */
    function cadToUsd(uint256 amount) public view virtual override returns (uint256) {
        return amount.mul(10 ** _granularity).div(_USDToCADRate);
    }

    /**
     * @notice convert CAD amount to Dai amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of Dai in 18 decimal places
     */
    function cadToDai(uint256 amount) external view virtual override returns (uint256) {
        (, int256 daiEthPrice, , uint256 daiEthTimeStamp,) = daiEthPriceFeed.latestRoundData();
        require(daiEthTimeStamp > 0, "Dai Chainlink Oracle data temporarily incomplete");
        require(daiEthPrice > 0, "Invalid Chainlink Oracle Dai price");

        (, int256 usdcEthPrice, , uint256 usdcEthTimeStamp,) = usdcEthPriceFeed.latestRoundData();
        require(usdcEthTimeStamp > 0, "USDC conversion Chainlink Oracle data temporarily incomplete");
        require(usdcEthPrice > 0, "Invalid Chainlink Oracle USDC conversion price");

        return amount.mul(10 ** _granularity).mul(uint256(usdcEthPrice)).div(uint256(daiEthPrice)).div(_USDToCADRate);
    }

    /**
     * @notice convert CAD amount to USDC amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USDC in 6 decimal places
     */
    function cadToUsdc(uint256 amount) external view virtual override returns (uint256) {
        return cadToUsd(amount).div(1e12);
    }

    /**
     * @notice convert CAD amount to USDT amount
     * @param amount     amount of CAD in 18 decimal places
     * @return amount of USDT in 6 decimal places
     */
    function cadToUsdt(uint256 amount) external view virtual override returns (uint256) {
        (, int256 usdtEthPrice, , uint256 usdtEthTimeStamp,) = usdtEthPriceFeed.latestRoundData();
        require(usdtEthTimeStamp > 0, "USDT Chainlink Oracle data temporarily incomplete");
        require(usdtEthPrice > 0, "Invalid Chainlink Oracle USDT price");

        (, int256 usdcEthPrice, , uint256 usdcEthTimeStamp,) = usdcEthPriceFeed.latestRoundData();
        require(usdcEthTimeStamp > 0, "USDC conversion Chainlink Oracle data temporarily incomplete");
        require(usdcEthPrice > 0, "Invalid Chainlink Oracle USDC conversion price");

        return amount.mul(10 ** _granularity).mul(uint256(usdcEthPrice)).div(uint256(usdtEthPrice)).div(_USDToCADRate).div(1e12);
    }
}