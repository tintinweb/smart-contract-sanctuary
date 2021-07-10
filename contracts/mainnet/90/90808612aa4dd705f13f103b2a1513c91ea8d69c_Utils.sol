/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity 0.5.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @title The interface for the Kyber Network smart contract
 * @author Zefram Lou (Zebang Liu)
 */
interface IKyberNetwork {
    function getExpectedRate(
        ERC20Detailed src,
        ERC20Detailed dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        ERC20Detailed src,
        uint256 srcAmount,
        ERC20Detailed dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint256);
}


/**
 * @title The smart contract for useful utility functions and constants.
 * @author Zefram Lou (Zebang Liu)
 */
contract Utils {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;

    /**
     * @notice Checks if `_token` is a valid token.
     * @param _token the token's address
     */
    modifier isValidToken(address _token) {
        require(_token != address(0));
        if (_token != address(ETH_TOKEN_ADDRESS)) {
            require(isContract(_token));
        }
        _;
    }

    address public USDC_ADDR;
    address payable public KYBER_ADDR;
    address payable public ONEINCH_ADDR;

    bytes public constant PERM_HINT = "PERM";

    // The address Kyber Network uses to represent Ether
    ERC20Detailed internal constant ETH_TOKEN_ADDRESS =
        ERC20Detailed(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ERC20Detailed internal usdc;
    IKyberNetwork internal kyber;

    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 internal constant MAX_DECIMALS = 18;

    constructor(
        address _usdcAddr,
        address payable _kyberAddr,
        address payable _oneInchAddr
    ) public {
        USDC_ADDR = _usdcAddr;
        KYBER_ADDR = _kyberAddr;
        ONEINCH_ADDR = _oneInchAddr;

        usdc = ERC20Detailed(_usdcAddr);
        kyber = IKyberNetwork(_kyberAddr);
    }

    /**
     * @notice Get the number of decimals of a token
     * @param _token the token to be queried
     * @return number of decimals
     */
    function getDecimals(ERC20Detailed _token) internal view returns (uint256) {
        if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
            return uint256(ETH_DECIMALS);
        }
        return uint256(_token.decimals());
    }

    /**
     * @notice Get the token balance of an account
     * @param _token the token to be queried
     * @param _addr the account whose balance will be returned
     * @return token balance of the account
     */
    function getBalance(ERC20Detailed _token, address _addr)
        internal
        view
        returns (uint256)
    {
        if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
            return uint256(_addr.balance);
        }
        return uint256(_token.balanceOf(_addr));
    }

    /**
     * @notice Calculates the rate of a trade. The rate is the price of the source token in the dest token, in 18 decimals.
     *         Note: the rate is on the token level, not the wei level, so for example if 1 Atoken = 10 Btoken, then the rate
     *         from A to B is 10 * 10**18, regardless of how many decimals each token uses.
     * @param srcAmount amount of source token
     * @param destAmount amount of dest token
     * @param srcDecimals decimals used by source token
     * @param dstDecimals decimals used by dest token
     */
    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return ((destAmount * PRECISION) /
                ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return ((destAmount *
                PRECISION *
                (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    /**
     * @notice Wrapper function for doing token conversion on Kyber Network
     * @param _srcToken the token to convert from
     * @param _srcAmount the amount of tokens to be converted
     * @param _destToken the destination token
     * @return _destPriceInSrc the price of the dest token, in terms of source tokens
     *         _srcPriceInDest the price of the source token, in terms of dest tokens
     *         _actualDestAmount actual amount of dest token traded
     *         _actualSrcAmount actual amount of src token traded
     */
    function __kyberTrade(
        ERC20Detailed _srcToken,
        uint256 _srcAmount,
        ERC20Detailed _destToken
    )
        internal
        returns (
            uint256 _destPriceInSrc,
            uint256 _srcPriceInDest,
            uint256 _actualDestAmount,
            uint256 _actualSrcAmount
        )
    {
        require(_srcToken != _destToken);

        uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
        uint256 msgValue;
        if (_srcToken != ETH_TOKEN_ADDRESS) {
            msgValue = 0;
            _srcToken.safeApprove(KYBER_ADDR, 0);
            _srcToken.safeApprove(KYBER_ADDR, _srcAmount);
        } else {
            msgValue = _srcAmount;
        }
        _actualDestAmount = kyber.tradeWithHint.value(msgValue)(
            _srcToken,
            _srcAmount,
            _destToken,
            toPayableAddr(address(this)),
            MAX_QTY,
            1,
            address(0),
            PERM_HINT
        );
        _actualSrcAmount = beforeSrcBalance.sub(
            getBalance(_srcToken, address(this))
        );
        require(_actualDestAmount > 0 && _actualSrcAmount > 0);
        _destPriceInSrc = calcRateFromQty(
            _actualDestAmount,
            _actualSrcAmount,
            getDecimals(_destToken),
            getDecimals(_srcToken)
        );
        _srcPriceInDest = calcRateFromQty(
            _actualSrcAmount,
            _actualDestAmount,
            getDecimals(_srcToken),
            getDecimals(_destToken)
        );
    }

    /**
     * @notice Wrapper function for doing token conversion on 1inch
     * @param _srcToken the token to convert from
     * @param _srcAmount the amount of tokens to be converted
     * @param _destToken the destination token
     * @return _destPriceInSrc the price of the dest token, in terms of source tokens
     *         _srcPriceInDest the price of the source token, in terms of dest tokens
     *         _actualDestAmount actual amount of dest token traded
     *         _actualSrcAmount actual amount of src token traded
     */
    function __oneInchTrade(
        ERC20Detailed _srcToken,
        uint256 _srcAmount,
        ERC20Detailed _destToken,
        bytes memory _calldata
    )
        public  
        returns (
            uint256 _destPriceInSrc,
            uint256 _srcPriceInDest,
            uint256 _actualDestAmount,
            uint256 _actualSrcAmount
        )
    {
        require(_srcToken != _destToken);

        uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
        uint256 beforeDestBalance = getBalance(_destToken, address(this));
        // Note: _actualSrcAmount is being used as msgValue here, because otherwise we'd run into the stack too deep error
        if (_srcToken != ETH_TOKEN_ADDRESS) {
            _actualSrcAmount = 0;
            _srcToken.safeApprove(ONEINCH_ADDR, 0);
            _srcToken.safeApprove(ONEINCH_ADDR, _srcAmount);
        } else {
            _actualSrcAmount = _srcAmount;
        }

        // trade through 1inch proxy
        (bool success, ) = ONEINCH_ADDR.call.value(_actualSrcAmount)(_calldata);
        require(success);

        // calculate trade amounts and price
        _actualDestAmount = getBalance(_destToken, address(this)).sub(
            beforeDestBalance
        );
        _actualSrcAmount = beforeSrcBalance.sub(
            getBalance(_srcToken, address(this))
        );
        require(_actualDestAmount > 0 && _actualSrcAmount > 0);
        _destPriceInSrc = calcRateFromQty(
            _actualDestAmount,
            _actualSrcAmount,
            getDecimals(_destToken),
            getDecimals(_srcToken)
        );
        _srcPriceInDest = calcRateFromQty(
            _actualSrcAmount,
            _actualDestAmount,
            getDecimals(_srcToken),
            getDecimals(_destToken)
        );
    }

    /**
     * @notice Checks if an Ethereum account is a smart contract
     * @param _addr the account to be checked
     * @return True if the account is a smart contract, false otherwise
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        if (_addr == address(0)) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function toPayableAddr(address _addr)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(_addr));
    }
}