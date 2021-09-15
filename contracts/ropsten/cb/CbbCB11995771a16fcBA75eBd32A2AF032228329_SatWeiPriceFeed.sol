pragma solidity 0.5.17;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../external/IMedianizer.sol";
import "../interfaces/ISatWeiPriceFeed.sol";

/// @notice satoshi/wei price feed.
/// @dev Used ETH/USD medianizer values converted to sat/wei.
contract SatWeiPriceFeed is Ownable, ISatWeiPriceFeed {
    using SafeMath for uint256;

    bool private _initialized = false;
    address internal tbtcSystemAddress;

    IMedianizer[] private ethBtcFeeds;

    constructor() public {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @notice Initialises the addresses of the ETHBTC price feeds.
    /// @param _tbtcSystemAddress Address of the `TBTCSystem` contract. Used for access control.
    /// @param _ETHBTCPriceFeed The ETHBTC price feed address.
    function initialize(
        address _tbtcSystemAddress,
        IMedianizer _ETHBTCPriceFeed
    ) external onlyOwner {
        require(!_initialized, "Already initialized.");
        tbtcSystemAddress = _tbtcSystemAddress;
        ethBtcFeeds.push(_ETHBTCPriceFeed);
        _initialized = true;
    }

    /// @notice Get the current price of 1 satoshi in wei.
    /// @dev This does not account for any 'Flippening' event.
    /// @return The price of one satoshi in wei.
    function getPrice() external view onlyTbtcSystem returns (uint256) {
        bool ethBtcActive = false;
        uint256 ethBtc = 0;

        for (uint256 i = 0; i < ethBtcFeeds.length; i++) {
            (ethBtc, ethBtcActive) = ethBtcFeeds[i].peek();
            if (ethBtcActive) {
                break;
            }
        }

        require(ethBtcActive, "Price feed offline");

        // convert eth/btc to sat/wei
        // We typecast down to uint128, because the first 128 bits of
        // the medianizer value is unrelated to the price.
        return uint256(10**28).div(uint256(uint128(ethBtc)));
    }

    /// @notice Get the first active Medianizer contract from the ethBtcFeeds array.
    /// @return The address of the first Active Medianizer. address(0) if none found
    function getWorkingEthBtcFeed() external view returns (address) {
        bool ethBtcActive;

        for (uint256 i = 0; i < ethBtcFeeds.length; i++) {
            (, ethBtcActive) = ethBtcFeeds[i].peek();
            if (ethBtcActive) {
                return address(ethBtcFeeds[i]);
            }
        }
        return address(0);
    }

    /// @notice Add _newEthBtcFeed to internal ethBtcFeeds array.
    /// @dev IMedianizer must be active in order to add.
    function addEthBtcFeed(IMedianizer _newEthBtcFeed) external onlyTbtcSystem {
        bool ethBtcActive;
        (, ethBtcActive) = _newEthBtcFeed.peek();
        require(ethBtcActive, "Cannot add inactive feed");
        ethBtcFeeds.push(_newEthBtcFeed);
    }

    /// @notice Function modifier ensures modified function is only called by tbtcSystemAddress.
    modifier onlyTbtcSystem() {
        require(
            msg.sender == tbtcSystemAddress,
            "Caller must be tbtcSystem contract"
        );
        _;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity 0.5.17;

import "../external/IMedianizer.sol";

/// @notice satoshi/wei price feed interface.
interface ISatWeiPriceFeed {
    /// @notice Get the current price of 1 satoshi in wei.
    /// @dev This does not account for any 'Flippening' event.
    /// @return The price of one satoshi in wei.
    function getPrice() external view returns (uint256);

    /// @notice add a new ETH/BTC meidanizer to the internal ethBtcFeeds array
    function addEthBtcFeed(IMedianizer _ethBtcFeed) external;
}

pragma solidity 0.5.17;

/// @notice A medianizer price feed.
/// @dev Based off the MakerDAO medianizer (https://github.com/makerdao/median)
interface IMedianizer {
    /// @notice Get the current price.
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    function read() external view returns (uint256);

    /// @notice Get the current price and check if the price feed is active
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    /// @return true if price is > 0, else returns false
    function peek() external view returns (uint256, bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}