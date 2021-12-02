/**
 *Submitted for verification at polygonscan.com on 2021-12-02
*/

pragma solidity 0.5.14;


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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

/**
 * @title FIN Oracle
 */
contract FixedPriceOracleFIN is Ownable {
    using SafeMath for uint256;

    // "MATIC / USD" price feed address
    AggregatorInterface public maticUsdChainLinkPriceFeed;

    // FIN token price in USD, with 8 decimal places
    uint256 public finPriceInUSD;

    // FIN token last updated timestamp
    uint256 public finLastUpdateTimestamp;

    // Pair Name: example: "FIN/MATIC"
    string public constant pairName = "FIN/MATIC";

    uint256 public constant ONE_MATIC = 10 ** 18;
    // 8 decimals USD rate returned by Chainlink Oracle, multiplier, divisor
    uint256 public constant USD_DECIMALS_MUL_DIV = 10 ** 8;
    uint256 public constant MATIC_NUMERATOR = ONE_MATIC * USD_DECIMALS_MUL_DIV;

    event FINPriceUpdated(uint256 priceInUSD, uint256 timestamp);

    /**
     * @dev Constructor of the contract
     */
    constructor(AggregatorInterface _maticUsdChainLinkPriceFeed) public {
        maticUsdChainLinkPriceFeed = _maticUsdChainLinkPriceFeed;
    }

    /**
     * @dev Only owner can set the FIN price in USD
     * @notice The price is in USD, upto 8 decimal places.
     */
    function setFINPriceInUSD(uint256 _price) public onlyOwner {
        finPriceInUSD = _price;
        finLastUpdateTimestamp = now;
        emit FINPriceUpdated(finPriceInUSD, finLastUpdateTimestamp);
    }

    /**
     * @dev returns the price of the a given token in MATIC
     * @return a token price in MATIC
     */
    function latestAnswer() public view returns (int256) {
        // example : finPriceInUSD = 20 000 000 = $0.2 (8 decimals)
        uint256 tokenPriceInUSD = finPriceInUSD;
        uint256 maticPriceInUSD = 0;

        // get the "MATIC / USD" pair rate in USD with 8 decimals
        // example `maticPriceInUSD = 200000000` = $2 per MATIC
        (maticPriceInUSD, ) = _getMaticUSDPrice();

        // 10^(18+8) / 200000000 = 500 000 000 000 000 000
        // means $1 = 500 000 000 000 000 000 MATIC
        uint256 maticPerUSD = MATIC_NUMERATOR.div(maticPriceInUSD);

        // 500 000 000 000 000 000 * 20 000 000 / (10^8) = 100 000 000 000 000 000 MATIC = 0.1 MATIC
        uint256 finPricePerTokenInMATIC = maticPerUSD.mul(tokenPriceInUSD).div(USD_DECIMALS_MUL_DIV);
        return toInt256(finPricePerTokenInMATIC);
    }

    /**
     * @dev Get the price in USD (8 decimals) from ChainLink and validate that the price is
     *      not expired.
     * @return returns the price in USD and the timestamp
     */
    function _getMaticUSDPrice() internal view returns (uint256 priceInUSD, uint256 timestamp) {
        timestamp = maticUsdChainLinkPriceFeed.latestTimestamp();
        // price should not be older than 1 hour
        uint256 expired = now.sub(1 hours);
        require(timestamp > expired, "Token price expired");

        int256 priceInUSD_8_decimal = maticUsdChainLinkPriceFeed.latestAnswer();
        priceInUSD = toUint256(priceInUSD_8_decimal);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < uint256(-1), "value doesn\'t fit in 256 bits");
        return int256(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "value must be positive");
        return uint256(value);
    }
}