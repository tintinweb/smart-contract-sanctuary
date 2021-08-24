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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

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
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Withdrawable {
    event Withdraw(address token, address to, uint256 amount);

    /*
    @notice Allows to withdraw amount of token to specified address.
    Works only with tokens and not Ether so token parameter is required to be non-zero address.

    @param token address of the token, mustn't be 0 address
    @param to address to withdraw to, mustn't be 0 address
    @param amount amount to withdraw, must be greater than 0
    */
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) internal {
        require(token != address(0), "Invalid token");
        require(to != address(0), "Invalid to");
        require(token != to, "Cannot withdraw to token");
        require(amount > 0, "Invalid amount");

        IERC20(token).transfer(to, amount);

        emit Withdraw(token, to, amount);
    }

    function withdraw(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        withdraw(address(token), to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Withdrawable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Yield is Withdrawable, Ownable {
    using SafeMath for uint256;

    /*
    @notice Balances of shares of each bucket for each address
    */
    mapping(uint256 => mapping(address => uint256)) private _shares;

    /*
    @notice Total reserves stored in a bucket
    */
    mapping(uint256 => uint256) private _reserves;

    /*
    @notice Total shares minted in a bucket
    */
    mapping(uint256 => uint256) private _totalShares;

    /*
    @notice Oracle for determining price of the asset and hence the winning bucket
    */
    AggregatorV3Interface private oracle;

    /*
    @notice Keeps track of when the last round occured.
    */
    uint256 private lastRoundTimestamp;

    /*
    @notice The duration for each round before selecting a winning bucket.
    */
    uint256 public roundDuration = 5 minutes;

    /*
    @notice Initial minimum price at which shares can be bought.
    */
    uint256 public immutable initialMinPrice;

    /*
    @notice Incremental of the value for buckets
    */
    uint256 public immutable increment;

    /*
    @notice Starting value of initial bucket
    */
    uint256 public immutable startingValue;

    /*
    @dev Token used for payments
    */
    IERC20 private immutable baseToken;

    /*
    @dev stores the amount of fees accumulated. Resets on fees withdrawal.
    */
    uint256 private accumulatedFees;

    /*
    @notice The numerator used for fee calculation.

    @dev default value set together with denominator to represent 0.5% fee.
    */
    uint16 public feeNumerator = 5;

    /*
    @notice The denominator used for fee calculation.

    @dev default value set together with numerator to represent 0.5% fee.
    */
    uint16 public feeDenominator = 1000;

    /*
    @notice the distance from winning buckets that game considers when redistributing funds
    */
    uint16 public maxDistance = 100;

    /*
    @notice the numerator used for toll calculation upon selecting a winning bucket

    @dev default value set together with denominator to represet 1% toll step
    */
    uint16 public tollNumerator = 1;

    /*
    @notice the denominator used for toll calculation upon selecting a winning bucket

    @dev default value set together with numerator to represet 1% toll step
    */
    uint16 public tollDenominator = 100;

    event Mint(address to, uint256 bucket, uint256 amountShares, uint256 amountToken);
    event Burn(address from, uint256 bucket, uint256 amountShares, uint256 amountToken);
    event Swap(address swapper, uint256 bucketFrom, uint256 bucketTo);
    event FinishRound(uint256 winningBucketId, int256 offset, int256 price, uint256 winnings);

    /*
    @param _startingValue starting value of the asset
    @param _increment the increment used for each bucket
    @param _initialMinPrice initial minimum share price for empty buckets
    @param _baseToken the token that will be used for minting and burning shares
    @param _oracle oracle used for price feeds
    */
    constructor(
        uint256 _startingValue,
        uint256 _increment,
        uint256 _initialMinPrice,
        address _baseToken,
        address _oracle
    ) {
        startingValue = _startingValue;
        increment = _increment;
        initialMinPrice = _initialMinPrice;
        lastRoundTimestamp = block.timestamp;
        baseToken = IERC20(_baseToken);
        oracle = AggregatorV3Interface(_oracle);
    }

    /*
    @notice Calculates the deterministic id of a bucket based on starting parameters and a given value.
    The id is calculated by finding the offset from the starting value and calculating hash of
    initialValue, valueIncrement and found offset.

    @dev The algorithm is rather simple.
    Let's assume that
    - S is the initialValue
    - I is the valueIncrement
    - V is value

    First we need to round the value, so we divide and multiply by I
    Rounded = (V / I) * I (I used brackets to note ethat V / I will return an int and that then this will be multiplied by I again)

    Once we have this rounded value we have to calculate the offset:
    - if V < S then the offset will be negative, so we cannot use uint256 but because we need to enforce parameters as uint256 then we change the order
      of the parameters. In this case we do (-1 * (S - Rounded)) / I
    - if V >= S then the offset will be positive, so we can just do (Rounded - S) / I

    Having all those values we can now calculate the id by hashing the three parameters: S, I and found offset

    @param value value for which bucket id has to be found

    @return bucket id based on parameters
    */
    function getBucketId(uint256 value) external view returns (uint256 bucketId) {
        (, bucketId) = _getBucketIdAndOffset(value);
    }

    function _getBucketIdAndOffset(uint256 value) internal view returns (int256 offset, uint256 bucketId) {
        uint256 rounded = value.div(increment).mul(increment);
        if (value < startingValue) {
            offset = -1 * int256(startingValue.sub(rounded).div(increment));
        } else {
            offset = int256(rounded.sub(startingValue).div(increment));
        }
        bucketId = _determineBucketIdForOffset(offset);
    }

    function _determineBucketIdForOffset(int256 offset) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(startingValue, increment, offset)));
    }

    /*
    @notice Allows to mint new shares in exchange for tokens.

    @param to address to which minted shares should be assigned
    @param bucket bucket in which to mint shares
    @param amountOutShares amount of shares to mint
    */
    function mintShares(
        address to,
        uint256 bucket,
        uint256 amountOutShares
    ) external {
        require(to != address(0), "Cannot mint to empty address");
        require(amountOutShares > 0, "amountOutShares must not be zero");

        (uint256 total, uint256 fee) = _getSharesAmountIn(bucket, amountOutShares);
        
        baseToken.transferFrom(to, address(this), total);

        _reserves[bucket] += (total - fee);
        _totalShares[bucket] += amountOutShares;
        _shares[bucket][to] += amountOutShares;
        accumulatedFees += fee;

        emit Mint(to, bucket, amountOutShares, total);
    }

    /*
    @notice Allows to burn shares and receive their token value back.

    @param to address to which funds from burning shares should be transferred
    @param bucket bucket in which to burn shares
    @param amountInShares amount of shares to burn
    */
    function burnShares(
        address to,
        uint256 bucket,
        uint256 amountInShares
    ) external {
        require(to != address(0), "Cannot mint to empty address");
        require(_shares[bucket][to] >= amountInShares, "Not enough shares");

        (uint256 total, uint256 fee) = _getSharesAmountIn(bucket, amountInShares);
        uint256 value = total - fee;

        _reserves[bucket] -= value;
        _totalShares[bucket] -= amountInShares;
        _shares[bucket][to] -= amountInShares;
        baseToken.transfer(to, value);

        emit Burn(to, bucket, amountInShares, value);
    }

    /*
    @notice Calculates how many tokens have to be spent to obtain amountOut shares.

    @param bucket the bucket to use for calculations
    @param amountOut expected amount of shares to buy

    @return the amount of tokens needed to obtain amountOut shares
    */
    function getSharesAmountIn(uint256 bucket, uint256 amountOut) external view returns (uint256 amountIn) {
        (amountIn, ) = _getSharesAmountIn(bucket, amountOut);
    }

    function _getSharesAmountIn(uint256 bucket, uint256 amountOut) internal view returns (uint256 amountIn, uint256 fee) {
        require(amountOut > 0, "Insufficient output amount");
        uint256 basePrice;
        if (_totalShares[bucket] == 0) {
            basePrice = initialMinPrice.mul(amountOut);
        } else {
            basePrice = _reserves[bucket].div(_totalShares[bucket]).mul(amountOut);
        }
        fee = basePrice.mul(feeNumerator).div(feeDenominator);
        amountIn = basePrice + fee;
    }

    /*
    @notice returns the amount of shares one can buy with specified amount of tokens
    
    @param bucket the bucket to use for calculation
    @param amountIn desired amount to spend

    @return the amount of shares that can be obtained for amountIn tokens
    */
    function getSharesAmountOut(uint256 bucket, uint256 amountIn) external view returns (uint256) {
        return _getSharesAmountOut(bucket, amountIn);
    }

    function _getSharesAmountOut(uint256 bucket, uint256 amountIn) internal view returns (uint256) {
        if (amountIn == 0) {
            return 0;
        }

        uint256 price = (_totalShares[bucket] == 0) ? initialMinPrice : _reserves[bucket].div(_totalShares[bucket]);
        return amountIn.mul(feeDenominator - feeNumerator).div(feeDenominator).div(price);
    }

    /*
    @notice Finishes a round by selecting a winning bucket using an external oracle. After selecting
    the winning bucket funds from losing buckets are redistributed so that losing buckets lose token reserves
    which are then added to the token reserves in the winning bucket.

    Problems:
    - Should we use only block.timestamp or maybe verify with oracle's timestamps too?
    */
    function finishRound() external onlyOwner {
        require(lastRoundTimestamp + roundDuration <= block.timestamp, "Round is still in progress");
        (, int256 price, , , ) = oracle.latestRoundData();
        uint8 decimals = oracle.decimals();
        (int256 offset, uint256 winningBucketId) = _getBucketIdAndOffset(uint256(price).mul(10**decimals));
        uint256 winnings = 0;
        int16 _maxDistance = int16(maxDistance);
        for (int256 i = offset - _maxDistance; i <= offset + _maxDistance; i++) {
            if (offset == i) {
                continue;
            } else {
                uint256 distance = uint256(offset - i < 0 ? i - offset : offset - i);
                uint256 losingBucketId = _determineBucketIdForOffset(offset + i);
                uint256 bucketToll = _reserves[losingBucketId].mul(distance * tollNumerator).div(tollDenominator);
                _reserves[losingBucketId] -= bucketToll;
                winnings += bucketToll;
            }
        }
        _reserves[winningBucketId] += winnings;
        lastRoundTimestamp = block.timestamp;

        emit FinishRound(winningBucketId, offset, price, winnings);
    }

    /*
    @notice Swaps all shares from one bucket to shares in another bucket.
    Shares in first bucket are burnt virtually so that the received token amount can then be used to virtually mint
    shares in the second bucket. Minting includes regular fee.
    If there are leftover tokens they are transferred to the swapper account.

    @param swapper the account which wants to swap shares
    @param bucketFrom bucket that should burn shares
    @param bucketTo bucket where shares should be minted
    */
    function swap(
        address swapper,
        uint256 bucketFrom,
        uint256 bucketTo
    ) external {
        require(_shares[bucketFrom][swapper] > 0, "No owned shares in source bucket");

        //calculate the value of all shares of the swapper in the source bucket
        (uint256 sourceTotal, uint256 sourceFee) = _getSharesAmountIn(bucketFrom, _shares[bucketFrom][swapper]);
        uint256 sourceValue = sourceTotal - sourceFee;

        //calculate the amount of shares swapper is able to buy in the dest bucket with the funds available from "burning" shares in source bucket
        uint256 amountOut = _getSharesAmountOut(bucketTo, sourceValue);
        (uint256 amountIn, uint256 destFee) = _getSharesAmountIn(bucketTo, amountOut);

        //updates states of the buckets
        _reserves[bucketFrom] -= sourceValue;
        _totalShares[bucketFrom] -= _shares[bucketFrom][swapper];
        _shares[bucketFrom][swapper] = 0;

        _reserves[bucketTo] += amountIn - destFee;
        _totalShares[bucketTo] += amountOut;
        _shares[bucketTo][swapper] += amountOut;
        accumulatedFees += destFee;

        if (sourceValue - amountIn > 0) {
            baseToken.transfer(swapper, sourceValue - amountIn);
        }

        emit Swap(swapper, bucketFrom, bucketTo);
    }

    /*
    @notice Returns the number of shares owned by the account in a bucket.

    @param bucket the bucket id
    @param account the account 
    
    @return balance of shares held in a bucket by the account
    */
    function balanceOf(uint256 bucket, address account) external view returns (uint256) {
        return _shares[bucket][account];
    }

    /*
    @notice Returns the total amount of shares in a bucket.

    @param bucket the bucket id

    @return total shares in a bucket
    */
    function totalShares(uint256 bucket) external view returns (uint256) {
        return _totalShares[bucket];
    }

    /*
    @notice Returns the total token reserves in a bucket.

    @param bucket the bucket id

    @return total token reserves in a bucket
    */
    function reserves(uint256 bucket) external view returns (uint256) {
        return _reserves[bucket];
    }

    /*
    @notice Allows withdrawal of accumulated fees.

    @param to address to withdraw accumulated fees to
    */
    function withdrawFees(address to) external onlyOwner {
        withdraw(baseToken, to, accumulatedFees);
        accumulatedFees = 0;
    }

    function setFee(uint16 numerator, uint16 denominator) external onlyOwner {
        require(denominator > 0, "Fee denominator must not be zero");
        feeNumerator = numerator;
        feeDenominator = denominator;
    }

    function setRoundDuration(uint256 _roundDuration) external onlyOwner {
        require(_roundDuration > 0, "Round duration must not be zero");
        roundDuration = _roundDuration;
    }

    function setMaxDistance(uint16 _maxDistance) external onlyOwner {
        require(_maxDistance > 0, "Max distance must not be zero");
        maxDistance = _maxDistance;
    }

    function setToll(uint16 numerator, uint16 denominator) external onlyOwner {
        require(denominator > 0, "Toll denominator must not be zero");
        tollNumerator = numerator;
        tollDenominator = denominator;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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