/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IAddressResolver

// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

// Part: IReadProxy

interface IReadProxy {
    function target() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

// Part: ISynth

interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account)
        external
        view
        returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value)
        external
        returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// Part: ISynthetix

// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid()
        external
        view
        returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer)
        external
        view
        returns (uint256);

    function debtBalanceOf(address issuer, bytes32 currencyKey)
        external
        view
        returns (uint256);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer)
        external
        view
        returns (uint256 maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

    function synthsByAddress(address synthAddress)
        external
        view
        returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function totalIssuedSynthsExcludeEtherCollateral(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function transferableSynthetix(address account)
        external
        view
        returns (uint256 transferable);

    // Mutative Functions
    function burnSynths(uint256 amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint256 amount)
        external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint256 amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint256 amount)
        external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account, uint256 susdAmount)
        external
        returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint256 amount) external;

    function mintSecondaryRewards(uint256 amount) external;

    function burnSecondary(address account, uint256 amount) external;
}

// Part: ISystemStatus

interface ISystemStatus {
    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);
}

// Part: IUniV3

interface IUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

// Part: IWeth

interface IWeth {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// Part: OpenZeppelin/[email protected]/Address

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: ICurveFi

interface ICurveFi is IERC20 {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256) external view returns (address);

    function add_liquidity(
        // EURt
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // Compound, sAave
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // Iron Bank, Aave
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // 3Crv Metapools
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // Y and yBUSD
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // 3pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // sUSD
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);

    function get_dy(
        int128 from,
        int128 to,
        uint256 _from_amount
    ) external view returns (uint256);

    // EURt
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    // 3Crv Metapools
    function calc_token_amount(
        address _pool,
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // sUSD, Y pool, etc
    function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    // 3pool, Iron Bank, etc
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256);
}

// Part: IVault

interface IVault is IERC20 {
    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw() external returns (uint256);

    function token() external view returns (address);
}

// Part: IVirtualSynth

interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account)
        external
        view
        returns (uint256);

    function rate() external view returns (uint256);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint256);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}

// Part: OpenZeppelin/[email protected]/SafeERC20

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Part: IExchanger

// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint256 amount,
        uint256 refunded
    ) external view returns (uint256 amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey)
        external
        view
        returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey)
        external
        view
        returns (uint256);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(
        address account,
        bytes32 currencyKey
    ) external view returns (bool);

    function feeRateForExchange(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 exchangeFeeRate);

    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint256);

    function waitingPeriodSecs() external view returns (uint256);

    // Mutative functions
    function exchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeWithTracking(
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function exchangeWithVirtual(
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived, IVirtualSynth vSynth);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntries
        );

    function setLastExchangeRateForSynth(bytes32 currencyKey, uint256 rate)
        external;

    function resetLastExchangeRate(bytes32[] calldata currencyKeys) external;

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;
}

// File: FixedForexZap.sol

contract FixedForexZap {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IReadProxy internal constant readProxy =
        IReadProxy(0x4E3b31eB0E5CB73641EE1E65E7dCEFe520bA3ef2);
    ISystemStatus internal constant systemStatus =
        ISystemStatus(0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E); // this is how we check if our market is closed

    bytes32 internal constant TRACKING_CODE = "YEARN"; // this is our referral code for SNX volume incentives
    bytes32 internal constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";

    address internal constant uniswapv3 =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /* ========== CONSTRUCTOR ========== */

    constructor() public {
        // approve the uniV3 router to spend our zap tokens and our sETH (for zapping out)
        IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        IERC20 wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        IERC20 seth = IERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);

        weth.approve(uniswapv3, type(uint256).max);
        usdc.approve(uniswapv3, type(uint256).max);
        dai.approve(uniswapv3, type(uint256).max);
        usdt.safeApprove(uniswapv3, type(uint256).max);
        wbtc.approve(uniswapv3, type(uint256).max);
        seth.approve(uniswapv3, type(uint256).max);

        // approve our curve LPs to spend our synths
        IERC20 aud = IERC20(0xF48e200EAF9906362BB1442fca31e0835773b8B4);
        IERC20 chf = IERC20(0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d);
        IERC20 eur = IERC20(0xD71eCFF9342A5Ced620049e616c5035F1dB98620);
        IERC20 gbp = IERC20(0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F);
        IERC20 jpy = IERC20(0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d);
        IERC20 krw = IERC20(0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B);

        aud.approve(
            address(0x3F1B0278A9ee595635B61817630cC19DE792f506),
            type(uint256).max
        );
        chf.approve(
            address(0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c),
            type(uint256).max
        );
        eur.approve(
            address(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859),
            type(uint256).max
        );
        gbp.approve(
            address(0xD6Ac1CB9019137a896343Da59dDE6d097F710538),
            type(uint256).max
        );
        jpy.approve(
            address(0x8818a9bb44Fbf33502bE7c15c500d0C783B73067),
            type(uint256).max
        );
        krw.approve(
            address(0x8461A004b50d321CB22B7d034969cE6803911899),
            type(uint256).max
        );

        // approve our vaults to spend our curve LPs
        aud = IERC20(0x3F1B0278A9ee595635B61817630cC19DE792f506);
        chf = IERC20(0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c);
        eur = IERC20(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859);
        gbp = IERC20(0xD6Ac1CB9019137a896343Da59dDE6d097F710538);
        jpy = IERC20(0x8818a9bb44Fbf33502bE7c15c500d0C783B73067);
        krw = IERC20(0x8461A004b50d321CB22B7d034969cE6803911899);

        aud.approve(
            address(0x1b905331F7dE2748F4D6a0678e1521E20347643F),
            type(uint256).max
        );
        chf.approve(
            address(0x490bD0886F221A5F79713D3E84404355A9293C50),
            type(uint256).max
        );
        eur.approve(
            address(0x67e019bfbd5a67207755D04467D6A70c0B75bF60),
            type(uint256).max
        );
        gbp.approve(
            address(0x595a68a8c9D5C230001848B69b1947ee2A607164),
            type(uint256).max
        );
        jpy.approve(
            address(0x59518884EeBFb03e90a18ADBAAAB770d4666471e),
            type(uint256).max
        );
        krw.approve(
            address(0x528D50dC9a333f01544177a924893FA1F5b9F748),
            type(uint256).max
        );
    }

    /* ========== ZAP IN ========== */

    // zap in for sETH
    function zapIn(
        address _inputToken,
        uint256 _amount,
        address _vaultToken
    ) public payable {
        require(_amount > 0 || msg.value > 0); // dev: invalid token or ETH amount

        if (_inputToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // if we start with ETH
            //convert ETH to WETH
            IWeth weth = IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            _amount = msg.value;
            weth.deposit{value: _amount}();

            // swap for sETH
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // weth
                        uint24(500),
                        address(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb) // sETH
                    ),
                    address(this),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        } else if (
            // this is if we start with WETH
            _inputToken == address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        ) {
            //transfer token
            IERC20(_inputToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );

            // swap for sETH
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(_inputToken),
                        uint24(500),
                        address(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb) // sETH
                    ),
                    address(this),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        } else if (
            // this is DAI, 0.3% is much better liquidity sadly
            _inputToken == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)
        ) {
            //transfer token
            IERC20(_inputToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );

            // swap for sETH
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(_inputToken),
                        uint24(3000),
                        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // weth
                        uint24(500),
                        address(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb) // sETH
                    ),
                    address(this),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        } else {
            //transfer token
            IERC20(_inputToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );

            // this is if we start with any token but WETH or DAI
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(_inputToken),
                        uint24(500),
                        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // weth
                        uint24(500),
                        address(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb) // sETH
                    ),
                    address(this),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        }
        // check our output balance of sETH
        IERC20 seth = IERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);
        uint256 _sEthBalance = seth.balanceOf(address(this));

        // generate our synth currency key to check if enough time has elapsed
        address _synth;
        bytes32 _synthCurrencyKey;
        if (_vaultToken == 0x1b905331F7dE2748F4D6a0678e1521E20347643F) {
            // sAUD
            _synth = 0xF48e200EAF9906362BB1442fca31e0835773b8B4;
            _synthCurrencyKey = "sAUD";
        } else if (_vaultToken == 0x490bD0886F221A5F79713D3E84404355A9293C50) {
            // sCHF
            _synth = 0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d;
            _synthCurrencyKey = "sCHF";
        } else if (_vaultToken == 0x67e019bfbd5a67207755D04467D6A70c0B75bF60) {
            // sEUR
            _synth = 0xD71eCFF9342A5Ced620049e616c5035F1dB98620;
            _synthCurrencyKey = "sEUR";
        } else if (_vaultToken == 0x595a68a8c9D5C230001848B69b1947ee2A607164) {
            // sGBP
            _synth = 0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F;
            _synthCurrencyKey = "sGBP";
        } else if (_vaultToken == 0x59518884EeBFb03e90a18ADBAAAB770d4666471e) {
            // sJPY
            _synth = 0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d;
            _synthCurrencyKey = "sJPY";
        } else if (_vaultToken == 0x528D50dC9a333f01544177a924893FA1F5b9F748) {
            // sKRW
            _synth = 0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B;
            _synthCurrencyKey = "sKRW";
        } else {
            require(false); // dev: not a Fixed Forex vault token
        }

        // check if our forex markets are open
        require(!isMarketClosed(_synth)); // dev: synthetix forex markets currently closed

        // swap our sETH for our underlying synth
        exchangeSEthToSynth(_sEthBalance, _synthCurrencyKey);
    }

    function exchangeSEthToSynth(uint256 _amount, bytes32 _synthCurrencyKey)
        internal
    {
        // swap amount of sETH for Synth
        require(_amount > 0); // dev: invalid token or ETH amount

        bytes32 _sethCurrencyKey = "sETH";

        _synthetix().exchangeWithTrackingForInitiator(
            _sethCurrencyKey,
            _amount,
            _synthCurrencyKey,
            address(0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7),
            TRACKING_CODE
        );
    }

    function synthToVault(address _synth, uint256 _amount) external {
        require(_amount > 0); // dev: invalid token or ETH amount
        // make sure the user has the synth needed
        address _user = msg.sender;
        IERC20 synth = IERC20(_synth);
        uint256 _synthBalance = synth.balanceOf(_user);
        require(_synthBalance > 0); // dev: you don't hold any of the specified synth
        synth.transferFrom(_user, address(this), _amount);

        // generate our synth currency key first to check if enough time has elapsed
        bytes32 _synthCurrencyKey;
        if (_synth == 0xF48e200EAF9906362BB1442fca31e0835773b8B4) {
            // sAUD
            _synthCurrencyKey = "sAUD";
        } else if (_synth == 0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d) {
            // sCHF
            _synthCurrencyKey = "sCHF";
        } else if (_synth == 0xD71eCFF9342A5Ced620049e616c5035F1dB98620) {
            // sEUR
            _synthCurrencyKey = "sEUR";
        } else if (_synth == 0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F) {
            // sGBP
            _synthCurrencyKey = "sGBP";
        } else if (_synth == 0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d) {
            // sJPY
            _synthCurrencyKey = "sJPY";
        } else if (_synth == 0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B) {
            // sKRW
            _synthCurrencyKey = "sKRW";
        } else {
            require(false); // dev: not a Fixed Forex synth
        }

        // deposit our sToken to Curve but only if our trade has finalized
        require(checkWaitingPeriod(msg.sender, _synthCurrencyKey)); // dev: wait ~6mins for trade to finalize on synthetix

        if (_synth == 0xF48e200EAF9906362BB1442fca31e0835773b8B4) {
            // sAUD
            ICurveFi curve =
                ICurveFi(0x3F1B0278A9ee595635B61817630cC19DE792f506); // Curve LP/Pool
            curve.add_liquidity([0, _amount], 0);
            uint256 _poolBalance = curve.balanceOf(address(this));
            IVault(0x1b905331F7dE2748F4D6a0678e1521E20347643F).deposit(
                _poolBalance,
                _user
            );
        } else if (_synth == 0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d) {
            // sCHF
            ICurveFi curve =
                ICurveFi(0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c); // Curve LP/Pool
            curve.add_liquidity([0, _amount], 0);
            uint256 _poolBalance = curve.balanceOf(address(this));
            IVault(0x490bD0886F221A5F79713D3E84404355A9293C50).deposit(
                _poolBalance,
                _user
            );
        } else if (_synth == 0xD71eCFF9342A5Ced620049e616c5035F1dB98620) {
            // sEUR
            ICurveFi curve =
                ICurveFi(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859); // Curve LP/Pool
            curve.add_liquidity([0, _amount], 0);
            uint256 _poolBalance = curve.balanceOf(address(this));
            IVault(0x67e019bfbd5a67207755D04467D6A70c0B75bF60).deposit(
                _poolBalance,
                _user
            );
        } else if (_synth == 0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F) {
            // sGBP
            ICurveFi curve =
                ICurveFi(0xD6Ac1CB9019137a896343Da59dDE6d097F710538); // Curve LP/Pool
            curve.add_liquidity([0, _amount], 0);
            uint256 _poolBalance = curve.balanceOf(address(this));
            IVault(0x595a68a8c9D5C230001848B69b1947ee2A607164).deposit(
                _poolBalance,
                _user
            );
        } else if (_synth == 0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d) {
            // sJPY
            ICurveFi curve =
                ICurveFi(0x8818a9bb44Fbf33502bE7c15c500d0C783B73067); // Curve LP/Pool
            curve.add_liquidity([0, _amount], 0);
            uint256 _poolBalance = curve.balanceOf(address(this));
            IVault(0x59518884EeBFb03e90a18ADBAAAB770d4666471e).deposit(
                _poolBalance,
                _user
            );
        } else {
            // sKRW
            ICurveFi curve =
                ICurveFi(0x8461A004b50d321CB22B7d034969cE6803911899); // Curve LP/Pool
            curve.add_liquidity([0, _amount], 0);
            uint256 _poolBalance = curve.balanceOf(address(this));
            IVault(0x528D50dC9a333f01544177a924893FA1F5b9F748).deposit(
                _poolBalance,
                _user
            );
        }
    }

    /* ========== ZAP OUT ========== */

    // zap our tokens for sETH
    function zapOut(address _vaultToken, uint256 _amount) external {
        require(_amount > 0); // dev: invalid token or ETH amount
        address _user = msg.sender;

        // withdraw from our vault
        IVault _vault = IVault(_vaultToken);
        _vault.transferFrom(_user, address(this), _amount);
        _vault.withdraw();

        // withdraw from our Curve pool
        ICurveFi curve = ICurveFi(_vault.token()); // our curve pool is the underlying token for our vault
        uint256 _poolBalance = curve.balanceOf(address(this));
        curve.remove_liquidity_one_coin(_poolBalance, 1, 0);

        // check our output balance of synth
        address _synth = curve.coins(1); // our synth is the second token in each of the curve pools
        IERC20 synth = IERC20(_synth);
        uint256 _synthBalance = synth.balanceOf(address(this));

        // generate our synth currency key to check if enough time has elapsed
        bytes32 _synthCurrencyKey;
        if (_vaultToken == 0x1b905331F7dE2748F4D6a0678e1521E20347643F) {
            // sAUD
            _synthCurrencyKey = "sAUD";
        } else if (_vaultToken == 0x490bD0886F221A5F79713D3E84404355A9293C50) {
            // sCHF
            _synthCurrencyKey = "sCHF";
        } else if (_vaultToken == 0x67e019bfbd5a67207755D04467D6A70c0B75bF60) {
            // sEUR
            _synthCurrencyKey = "sEUR";
        } else if (_vaultToken == 0x595a68a8c9D5C230001848B69b1947ee2A607164) {
            // sGBP
            _synthCurrencyKey = "sGBP";
        } else if (_vaultToken == 0x59518884EeBFb03e90a18ADBAAAB770d4666471e) {
            // sJPY
            _synthCurrencyKey = "sJPY";
        } else if (_vaultToken == 0x528D50dC9a333f01544177a924893FA1F5b9F748) {
            // sKRW
            _synthCurrencyKey = "sKRW";
        } else {
            require(false); // dev: not a Fixed Forex vault token
        }

        // check if our forex markets are open
        require(!isMarketClosed(_synth)); // dev: synthetix forex markets currently closed

        // swap our sETH for our underlying synth
        exchangeSynthToSEth(_synthBalance, _synthCurrencyKey);
    }

    function exchangeSynthToSEth(uint256 _amount, bytes32 _synthCurrencyKey)
        internal
    {
        // swap amount of sETH for Synth
        require(_amount > 0); // dev: can't swap zero

        bytes32 _sethCurrencyKey = "sETH";

        _synthetix().exchangeWithTrackingForInitiator(
            _synthCurrencyKey,
            _amount,
            _sethCurrencyKey,
            address(0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7),
            TRACKING_CODE
        );
    }

    function sETHToWant(address _targetToken, uint256 _amount) external {
        // make sure that our synth trade has finalized
        bytes32 _sethCurrencyKey = "sETH";
        require(checkWaitingPeriod(msg.sender, _sethCurrencyKey)); // dev: wait ~6mins for trade to finalize on synthetix
        require(_amount > 0); // dev: invalid token or ETH amount

        //transfer sETH to zap
        address payable _user = msg.sender;
        IERC20 seth = IERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);
        uint256 _sethBalance = seth.balanceOf(_user);
        require(_sethBalance > 0); // dev: you don't hold any sETH
        seth.safeTransferFrom(_user, address(this), _amount);

        // this is if we want to end up with WETH
        if (
            _targetToken == address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        ) {
            // swap for sETH
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(seth),
                        uint24(500),
                        address(_targetToken)
                    ),
                    address(_user),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        } else if (
            _targetToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            // swap for WETH
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(seth),
                        uint24(500),
                        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) // weth
                    ),
                    address(this),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );

            //convert WETH to ETH
            address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            uint256 _output = IERC20(weth).balanceOf(address(this));
            if (_output > 0) {
                IWeth(weth).withdraw(_output);
                _user.transfer(_output);
            }
        } else if (
            // for DAI it's best to use 0.3% fee route
            _targetToken == address(0x6B175474E89094C44Da98b954EedeAC495271d0F)
        ) {
            // swap for DAI
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(seth),
                        uint24(500),
                        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
                        uint24(3000),
                        address(_targetToken)
                    ),
                    address(_user),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        } else {
            // this is if we want any token but WETH or DAI
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(seth),
                        uint24(500),
                        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
                        uint24(500),
                        address(_targetToken)
                    ),
                    address(_user),
                    block.timestamp,
                    _amount,
                    uint256(1)
                )
            );
        }
    }

    // include so our zap plays nicely with ether
    receive() external payable {}

    /* ========== HELPERS ========== */

    function _synthetix() internal view returns (ISynthetix) {
        return ISynthetix(resolver().getAddress(CONTRACT_SYNTHETIX));
    }

    function resolver() internal view returns (IAddressResolver) {
        return IAddressResolver(readProxy.target());
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(resolver().getAddress(CONTRACT_EXCHANGER));
    }

    function checkWaitingPeriod(address _user, bytes32 _synthCurrencyKey)
        internal
        view
        returns (bool freeToMove)
    {
        return
            // check if it's been >5 mins since we traded our sETH for our synth
            _exchanger().maxSecsLeftInWaitingPeriod(
                address(_user),
                _synthCurrencyKey
            ) == 0;
    }

    function isMarketClosed(address _synth) public view returns (bool) {
        // keep this public so we can always check if markets are open
        bytes32 _synthCurrencyKey;
        if (_synth == 0xF48e200EAF9906362BB1442fca31e0835773b8B4) {
            // sAUD
            _synthCurrencyKey = "sAUD";
        } else if (_synth == 0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d) {
            // sCHF
            _synthCurrencyKey = "sCHF";
        } else if (_synth == 0xD71eCFF9342A5Ced620049e616c5035F1dB98620) {
            // sEUR
            _synthCurrencyKey = "sEUR";
        } else if (_synth == 0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F) {
            // sGBP
            _synthCurrencyKey = "sGBP";
        } else if (_synth == 0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d) {
            // sJPY
            _synthCurrencyKey = "sJPY";
        } else {
            // sKRW
            _synthCurrencyKey = "sKRW";
        }

        // set up our arrays to use
        bool[] memory tradingSuspended;
        bytes32[] memory synthArray;

        // use our synth key
        synthArray = new bytes32[](1);
        synthArray[0] = _synthCurrencyKey;

        // check if trading is open or not. true = market is closed
        (tradingSuspended, ) = systemStatus.getSynthExchangeSuspensions(
            synthArray
        );
        return tradingSuspended[0];
    }
}