// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/oracle/IExchangeRateOracle.sol


/**
 * @title IExchangeRateOracle
 * @notice provides interface for fetching exchange rate values onchain, underlying implementations could use different oracles.
*/
interface IExchangeRateOracle {

    /**
     * @notice return the value and the value's timestamp given a request ID
     * @dev use granularity instead of defaulting to 18 for future oracle integrations
     * @param requestId     a number that specifies the exchange rate pair
     * @return false if could not get value, true with valid value, granularity, and timestamp if could get value
     */
    function getCurrentValue(uint256 requestId) external view returns (bool, uint256, uint256, uint256);
}

// File: contracts/acquisition/ITokenPool.sol


/**
 * @title ITokenPool
 * @notice provides interface for token pool where ERC20 tokens can be deposited and withdraw
*/
interface ITokenPool {

    /**
    * @notice deposit token into the pool from the source
    * @param amount     amount of token to deposit
    * @return true if success
    */
    function depositAssetToken(uint256 amount) external returns (bool);

    /**
    * @notice withdraw token from the pool back to the source
    * @param amount     amount of token to withdraw
    * @return true if success
    */
    function withdrawAssetToken(uint256 amount) external returns (bool);
}

// File: contracts/acquisition/FixedPriceCADSingleSourceTokenPool.sol


/**
 * @title FixedPriceCADSingleSourceTokenPool
 * @notice Convert USD into a wToken in CAD. wToken is transfered from a single-source pool to the sender of USD, while USD is transferred to the source.
*/
contract FixedPriceCADSingleSourceTokenPool is ITokenPool {
    using SafeMath for uint256;

    event TokenDeposited(uint256 amount);
    event TokenWithdrawn(uint256 amount);

    event TokenTransaction(address indexed from, address to, uint256 tokenAmount, uint256 usdAmount);

    // source where the wTokens come from
    address public _poolSource;

    // address of the wToken
    IERC20 public _wToken;

    // address of the USD to CAD oracle
    IExchangeRateOracle public _oracle;

    // wTokens, if fix-priced in CAD, will not require more than 2 decimals
    uint256 public _fixedPriceCADCent;

    // Dai contract
    IERC20 public _daiContract;

    // USDC contract
    IERC20 public _usdcContract;

    // USDT contract
    IERC20 public _usdtContract;


    constructor(
        address poolSource,
        address tokenAddress,
        address oracleAddress,
        uint256 fixedPriceCADCent,

        address daiContractddress,
        address usdcContractAddress,
        address usdtContractAddress
    ) public {
        _poolSource = poolSource;
        _wToken = IERC20(tokenAddress);
        _oracle = IExchangeRateOracle(oracleAddress);
        _fixedPriceCADCent = fixedPriceCADCent;

        _daiContract = IERC20(daiContractddress);
        _usdcContract = IERC20(usdcContractAddress);
        _usdtContract = IERC20(usdtContractAddress);
    }

    /**
    * @notice deposit token into the pool from the source
    * @param amount     amount of token to deposit
    * @return true if success
    */
    function depositAssetToken(uint256 amount) external virtual override returns (bool) {
        require(msg.sender == _poolSource, "Only designated source can deposit token");
        require(amount > 0, "Amount must be greater than 0");

        _wToken.transferFrom(_poolSource, address(this), amount);

        emit TokenDeposited(amount);
        return true;
    }

    /**
    * @notice withdraw token from the pool back to the source
    * @param amount     amount of token to withdraw
    * @return true if success
    */
    function withdrawAssetToken(uint256 amount) external virtual override returns (bool) {
        require(msg.sender == _poolSource, "Only designated source can withdraw token");
        require(amount > 0, "Amount must be greater than 0");

        _wToken.transfer(_poolSource, amount);

        emit TokenWithdrawn(amount);
        return true;
    }

    /**
    * @notice generic function for handling USD deposits and transfer of wTokens as a result
    * @param usdAmount      amount of USD to deposit
    * @param to             address to receive the resulting wTokens
    * @param usdType        1 for Dai, 2 for USDC, 3 for USDT
    * @return true if success
    */
    function depositTo(uint256 usdAmount, address to, uint32 usdType) internal returns (bool) {
        require(usdAmount > 0, "USD amount must be greater than 0");
        require(to != address(0), "Recipient cannot be zero address");

        uint256 usdAmountInWad = usdAmount;
        if (usdType > 1) {
            // USDC and USDT both have 6 decimals, need to change to 18
            usdAmountInWad = usdAmount.mul(1e12);
        }


        // check if there is enough wToken supply to make the conversion
        uint256 tokenAmount = usdToToken(usdAmountInWad);

        // through not strictly needed, useful to have a clear message for this error case
        require(_wToken.balanceOf(address(this)) >= tokenAmount, "Insufficient token supply in the pool");

        // transfer corresponding USD tokens to source of wTokens
        if (usdType == 1) {
            _daiContract.transferFrom(msg.sender, _poolSource, usdAmount);
        } else if (usdType == 2) {
            _usdcContract.transferFrom(msg.sender, _poolSource, usdAmount);
        } else if (usdType == 3) {
            _usdtContract.transferFrom(msg.sender, _poolSource, usdAmount);
        } else {
            revert("Unsupported USD type");
        }

        // transfer wToken to recipient
        _wToken.transfer(to, tokenAmount);

        emit TokenTransaction(msg.sender, to, tokenAmount, usdAmountInWad);
        return true;
    }

    /**
    * @notice deposit Dai and get back wTokens
    * @param usdAmount      amount of Dai to deposit
    * @return true if success
    */
    function depositDai(uint256 usdAmount) external returns (bool) {
        return depositTo(usdAmount, msg.sender, 1);
    }

    /**
    * @notice deposit USDC and get back wTokens
    * @param usdAmount      amount of USDC to deposit
    * @return true if success
    */
    function depositUSDC(uint256 usdAmount) external returns (bool) {
        return depositTo(usdAmount, msg.sender, 2);
    }

    /**
    * @notice deposit USDT and get back wTokens
    * @param usdAmount      amount of USDT to deposit
    * @return true if success
    */
    function depositUSDT(uint256 usdAmount) external returns (bool) {
        return depositTo(usdAmount, msg.sender, 3);
    }

    /**
    * @notice given an USD amount, calculate resulting wToken amount
    * @param usdAmount      amount of USD for conversion
    * @return amount of resulting wTokens
    */
    function usdToToken(uint256 usdAmount) public view returns (uint256) {
        (bool success, uint256 USDToCADRate, uint256 granularity,) = _oracle.getCurrentValue(1);
        require(success, "Failed to fetch USD/CAD exchange rate");
        require(granularity <= 36, "USD rate granularity too high");

        // use mul before div
        return usdAmount.mul(USDToCADRate).mul(100).div(10 ** granularity).div(_fixedPriceCADCent);
    }

    /**
    * @notice view how many tokens are currently available
    * @return amount of tokens available in the pool
    */
    function tokensAvailable() public view returns (uint256) {
        return _wToken.balanceOf(address(this));
    }

    /**
    * @notice view max amount of USD deposit that can be accepted
    * @return max amount of USD deposit (18 decimal places)
    */
    function availableTokenInUSD() external view returns (uint256) {
        (bool success, uint256 USDToCADRate, uint256 granularity,) = _oracle.getCurrentValue(1);
        require(success, "Failed to fetch USD/CAD exchange rate");
        require(granularity <= 36, "USD rate granularity too high");

        uint256 tokenAmount = tokensAvailable();

        return tokenAmount.mul(_fixedPriceCADCent).mul(10 ** granularity).div(100).div(USDToCADRate);
    }
}