// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface IVirtualBalanceWrapperFactory {
    function CreateVirtualBalanceWrapper(address op) external returns (address);
}

interface IVirtualBalanceWrapper {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdrawFor(address _for, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/SafeERC20.sol";
import "./common/IVirtualBalanceWrapper.sol";

interface ILendFlareToken {
    function future_epoch_time_write() external returns (uint256);

    function rate() external view returns (uint256);
}

interface IMinter {
    function minted(address addr, address self) external view returns (uint256);
}

interface IController {
    function gauge_relative_weight(
        address addr /* , uint256 time */
    ) external view returns (uint256);
}

contract LendFlareGauge {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant BOOST_WARMUP = 2 * 7 * 86400;
    uint256 constant WEEK = 604800;

    address public virtualBalance;
    uint256 public working_supply;
    uint256 public period;
    uint256 public inflation_rate;
    uint256 public future_epoch_time;

    address public lendFlareVotingEscrow;
    address public lendFlareToken;
    address public lendFlareTokenMinter;
    address public lendFlareGaugeModel;

    // uint256[100000000000000000000000000000] public period_timestamp;
    // uint256[100000000000000000000000000000] public integrate_inv_supply;

    mapping(uint256 => uint256) public period_timestamp;
    mapping(uint256 => uint256) public integrate_inv_supply;

    mapping(address => uint256) public integrate_inv_supply_of;
    mapping(address => uint256) public integrate_checkpoint_of;
    mapping(address => uint256) public integrate_fraction;
    mapping(address => uint256) public working_balances;

    event UpdateLiquidityLimit(
        address user,
        uint256 original_balance,
        uint256 original_supply,
        uint256 working_balance,
        uint256 working_supply
    );

    constructor(
        address _virtualBalance,
        address _lendFlareToken,
        address _lendFlareVotingEscrow,
        address _lendFlareGaugeModel,
        address _lendFlareTokenMinter
    ) public {
        virtualBalance = _virtualBalance;
        lendFlareVotingEscrow = _lendFlareVotingEscrow;
        lendFlareToken = _lendFlareToken;
        lendFlareTokenMinter = _lendFlareTokenMinter;
        lendFlareGaugeModel = _lendFlareGaugeModel;
    }

    function _update_liquidity_limit(
        address addr,
        uint256 l,
        uint256 L
    ) internal {
        uint256 voting_balance = IERC20(lendFlareVotingEscrow).balanceOf(addr);
        uint256 voting_total = IERC20(lendFlareVotingEscrow).totalSupply();
        uint256 lim = (l * TOKENLESS_PRODUCTION) / 100;

        if (
            voting_total > 0 &&
            block.timestamp > period_timestamp[0] + BOOST_WARMUP
        ) {
            lim +=
                (((L * voting_balance) / voting_total) *
                    (100 - TOKENLESS_PRODUCTION)) /
                100;
        }

        lim = min(l, lim);

        uint256 old_bal = working_balances[addr];

        working_balances[addr] = lim;

        uint256 _working_supply = working_supply + lim - old_bal;
        working_supply = _working_supply;

        emit UpdateLiquidityLimit(addr, l, L, lim, _working_supply);
    }

    function _checkpoint(address addr) internal {
        uint256 _period_time = period_timestamp[period];
        uint256 _integrate_inv_supply = integrate_inv_supply[period];
        uint256 rate = inflation_rate;
        uint256 new_rate = rate;
        uint256 prev_future_epoch = future_epoch_time;

        if (prev_future_epoch >= _period_time) {
            future_epoch_time = ILendFlareToken(lendFlareToken)
                .future_epoch_time_write();
            new_rate = ILendFlareToken(lendFlareToken).rate();
            inflation_rate = new_rate;
        }

        // Controller(_controller).checkpoint_gauge(address(this));

        uint256 _working_balance = working_balances[addr];
        uint256 _working_supply = working_supply;

        if (block.timestamp > _period_time) {
            uint256 prev_week_time = _period_time;
            uint256 week_time = min(
                ((_period_time + WEEK) / WEEK) * WEEK,
                block.timestamp
            );

            for (uint256 i = 0; i < 500; i++) {
                uint256 dt = week_time - prev_week_time;
                // uint256 w = IController(lendFlareGaugeModel).gauge_relative_weight(
                //     address(this),
                //     (prev_week_time / WEEK) * WEEK
                // );
                uint256 w = IController(lendFlareGaugeModel)
                    .gauge_relative_weight(address(this));

                if (_working_supply > 0) {
                    if (
                        prev_future_epoch >= prev_week_time &&
                        prev_future_epoch < week_time
                    ) {
                        _integrate_inv_supply +=
                            (rate * w * (prev_future_epoch - prev_week_time)) /
                            _working_supply;
                        rate = new_rate;
                        _integrate_inv_supply +=
                            (rate * w * (week_time - prev_future_epoch)) /
                            _working_supply;
                    } else {
                        _integrate_inv_supply +=
                            (rate * w * dt) /
                            _working_supply;
                    }

                    if (week_time == block.timestamp) break;

                    prev_week_time = week_time;
                    week_time = min(week_time + WEEK, block.timestamp);
                }
            }
        }

        period += 1;
        period_timestamp[period] = block.timestamp;
        integrate_inv_supply[period] = _integrate_inv_supply;

        integrate_fraction[addr] +=
            (_working_balance *
                (_integrate_inv_supply - integrate_inv_supply_of[addr])) /
            10**18;
        integrate_inv_supply_of[addr] = _integrate_inv_supply;
        integrate_checkpoint_of[addr] = block.timestamp;

        // _token: address = self.crv_token
        // _controller: address = self.controller
        // _period: int128 = self.period
        // _period_time: uint256 = self.period_timestamp[_period]
        // _integrate_inv_supply: uint256 = self.integrate_inv_supply[_period]
        // rate: uint256 = self.inflation_rate
        // new_rate: uint256 = rate
        // prev_future_epoch: uint256 = self.future_epoch_time
        // if prev_future_epoch >= _period_time:
        //     self.future_epoch_time = CRV20(_token).future_epoch_time_write()
        //     new_rate = CRV20(_token).rate()
        //     self.inflation_rate = new_rate
        // Controller(_controller).checkpoint_gauge(self)

        // _working_balance: uint256 = self.working_balances[addr]
        // _working_supply: uint256 = self.working_supply

        /* # Update integral of 1/supply
        if block.timestamp > _period_time:
            prev_week_time: uint256 = _period_time
            week_time: uint256 = min((_period_time + WEEK) / WEEK * WEEK, block.timestamp)

            for i in range(500):
                dt: uint256 = week_time - prev_week_time
                w: uint256 = Controller(_controller).gauge_relative_weight(self, prev_week_time / WEEK * WEEK)

                if _working_supply > 0:
                    if prev_future_epoch >= prev_week_time and prev_future_epoch < week_time:
                        # If we went across one or multiple epochs, apply the rate
                        # of the first epoch until it ends, and then the rate of
                        # the last epoch.
                        # If more than one epoch is crossed - the gauge gets less,
                        # but that'd meen it wasn't called for more than 1 year
                        _integrate_inv_supply += rate * w * (prev_future_epoch - prev_week_time) / _working_supply
                        rate = new_rate
                        _integrate_inv_supply += rate * w * (week_time - prev_future_epoch) / _working_supply
                    else:
                        _integrate_inv_supply += rate * w * dt / _working_supply
                    # On precisions of the calculation
                    # rate ~= 10e18
                    # last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    # _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    # The largest loss is at dt = 1
                    # Loss is 1e-9 - acceptable

                if week_time == block.timestamp:
                    break
                prev_week_time = week_time
                week_time = min(week_time + WEEK, block.timestamp)

        _period += 1
        self.period = _period
        self.period_timestamp[_period] = block.timestamp
        self.integrate_inv_supply[_period] = _integrate_inv_supply

        # Update user-specific integrals
        self.integrate_fraction[addr] += _working_balance * (_integrate_inv_supply - self.integrate_inv_supply_of[addr]) / 10 ** 18
        self.integrate_inv_supply_of[addr] = _integrate_inv_supply
        self.integrate_checkpoint_of[addr] = block.timestamp */
    }

    function user_checkpoint(address addr) public returns (bool) {
        _checkpoint(addr);
        // _update_liquidity_limit(addr,balanceOf[addr],totalSupply);
        _update_liquidity_limit(
            addr,
            IVirtualBalanceWrapper(virtualBalance).balanceOf(addr),
            IVirtualBalanceWrapper(virtualBalance).totalSupply()
        );

        return true;
    }

    function claimable_tokens(address addr) public returns (uint256) {
        _checkpoint(addr);
        // _update_liquidity_limit(addr,balanceOf[addr],totalSupply);
        // _update_liquidity_limit(
        //     addr,
        //     IVirtualBalanceWrapper(virtualBalance).balanceOf(addr),
        //     IVirtualBalanceWrapper(virtualBalance).totalSupply()
        // );

        return
            integrate_fraction[addr] -
            IMinter(lendFlareTokenMinter).minted(addr, address(this));
    }

    function integrate_checkpoint() public view returns (uint256) {
        return period_timestamp[period];
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./MockConvexInterfaces.sol";
import "../../libs/IERC20.sol";
import "../../libs/SafeERC20.sol";

interface ITokenMinter {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

interface IMockCRV {
    function mint(address user, uint256 value) external returns (bool);
}

contract MockConvexBooster {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    PoolInfo[100] public poolInfo;
    mapping(address => bool) public gaugeMap;

    address public mockCRV;

    constructor(address _mockCRV) public {
        /* Curve.fi DAI/USDC/USDT (3Crv) */
        mockCRV = _mockCRV;
    }

    function addPool(
        uint256 _pid,
        address _lpToken,
        address _token,
        address _crvRewards,
        address _stash
    ) public {
        poolInfo[_pid] = PoolInfo({
            lptoken: _lpToken,
            token: _token,
            gauge: address(0),
            crvRewards: _crvRewards,
            stash: _stash,
            shutdown: false
        });
        // poolInfo[9] = PoolInfo({
        //     lptoken: 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490,
        //     token: 0x30D9410ED1D5DA1F6C8391af5338C93ab8d4035C,
        //     gauge: 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A,
        //     crvRewards: 0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8,
        //     stash: 0x0000000000000000000000000000000000000000,
        //     shutdown: false
        // });
        // /* Curve.fi ETH/stETH (steCRV) */
        // poolInfo[25] = PoolInfo({
        //     lptoken: 0x06325440D014e39736583c165C2963BA99fAf14E,
        //     token: 0x9518c9063eB0262D791f38d8d6Eb0aca33c63ed0,
        //     gauge: 0x182B723a58739a9c974cFDB385ceaDb237453c28,
        //     crvRewards: 0x0A760466E1B4621579a82a39CB56Dda2F4E70f03,
        //     stash: 0x9710fD4e5CA524f1049EbeD8936c07C81b5EAB9f,
        //     shutdown: false
        // });
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        address lptoken = pool.lptoken;
        IERC20(lptoken).safeTransferFrom(msg.sender, address(this), _amount);

        address token = pool.token;

        if (_stake) {
            //mint here and send to rewards on user behalf
            ITokenMinter(token).mint(address(this), _amount);
            address rewardContract = pool.crvRewards;
            IERC20(token).safeApprove(rewardContract, 0);
            IERC20(token).safeApprove(rewardContract, _amount);
            IRewards(rewardContract).stakeFor(msg.sender, _amount);
        } else {
            //add user balance directly
            ITokenMinter(token).mint(msg.sender, _amount);
        }

        return true;
    }

    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address _from,
        address _to
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address lptoken = pool.lptoken;
        address token = pool.token;

        ITokenMinter(token).burn(_from, _amount);
        IERC20(lptoken).safeTransfer(_to, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public returns (bool) {
        _withdraw(_pid, _amount, msg.sender, msg.sender);
    }

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool) {
        address rewardContract = poolInfo[_pid].crvRewards;
        require(msg.sender == rewardContract, "!auth");

        _withdraw(_pid, _amount, msg.sender, _to);
        return true;
    }

    //claim crv and extra rewards and disperse to reward contracts
    function _earmarkRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        uint256 mintAmount = 2 ether;

        IMockCRV(mockCRV).mint(address(this), mintAmount);

        address rewardContract = pool.crvRewards;

        for (
            uint256 i = 0;
            i < IRewards(rewardContract).extraRewardsLength();
            i++
        ) {
            address extraReward = IRewards(rewardContract).extraRewards(i);

            address rewardToken = IVirtualBalanceRewardPool(extraReward)
                .rewardToken();

            IMockCRV(rewardToken).mint(extraReward, mintAmount);

            IVirtualBalanceRewardPool(extraReward).queueNewRewards(mintAmount);
        }

        IERC20(mockCRV).safeTransfer(rewardContract, mintAmount);
        IRewards(rewardContract).queueNewRewards(mintAmount);
    }

    function earmarkRewards(uint256 _pid) external returns (bool) {
        _earmarkRewards(_pid);

        return true;
    }

    // function claimRewards(uint256 _pid, address _gauge)
    //     external
    //     returns (bool)
    // {
    //     return true;
    // }

    // function earmarkRewards(uint256 _pid) external returns (bool) {
    //     return true;
    // }

    // //claim fees from curve distro contract, put in lockers' reward contract
    // function earmarkFees() external returns (bool) {
    //     return true;
    // }

    //callback from reward contract when crv is received.
    // function rewardClaimed(
    //     uint256 _pid,
    //     address _address,
    //     uint256 _amount
    // ) external returns (bool) {
    //     address rewardContract = poolInfo[_pid].crvRewards;

    //     //mint reward tokens
    //     // ITokenMinter(minter).mint(_address, _amount);

    //     return true;
    // }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function stakingToken() external returns (address);
    function extraRewards(uint256 idx) external view returns(address);
    function extraRewardsLength() external view returns (uint256);
}

interface IVirtualBalanceRewardPool {
    function rewardToken() external view returns(address);
    function queueNewRewards(uint256 _rewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeMath.sol";
import "./libs/IERC20.sol";
import "./libs/Ownable.sol";
import "./libs/ReentrancyGuard.sol";

/* interface SmartWalletChecker {
    function check(address) external returns (bool);
} */
interface IRewardVeLendFlarePool {
    function updateRewardState(address _user) external;
}

contract LendFlareVotingEscrow is Ownable, ReentrancyGuard {
    uint256 constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    uint256 private _totalSupply;

    string private _name = "Vote-escrowed LFT";
    string private _symbol = "VeLFT";
    uint256 private _decimals = 18;
    string private _version;

    address public token;
    // address public future_smart_wallet_checker;
    // address public smart_wallet_checker;

    uint256 public epoch;

    enum DepositTypes {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    struct Point {
        int128 bias;
        int128 slope; // dweight / dt
        uint256 ts; // timestamp
        uint256 blk; // block number
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    IRewardVeLendFlarePool[] public rewardVeLendFlarePool;

    // Point[100000000000000000Point000000000000] public point_history; // epoch -> unsigned point
    mapping(uint256 => Point) public point_history; // epoch -> unsigned point
    // mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
    mapping(address => mapping(uint256 => Point)) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes; // time -> signed slope change
    mapping(address => LockedBalance) public locked;

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        DepositTypes depositTypes,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    constructor(string memory version_, address token_addr_) public {
        _version = version_;
        token = token_addr_;
    }

    // function commit_smart_wallet_checker(address addr) public {
    //     future_smart_wallet_checker = addr;
    // }

    // function apply_smart_wallet_checker() public {
    //     smart_wallet_checker = future_smart_wallet_checker;
    // }

    // function assert_not_contract(address addr) public {
    //     require(addr != tx.origin);

    //     address checker = smart_wallet_checker;

    //     if (checker != address(0)) {
    //         SmartWalletChecker(checker).check(addr);
    //     }
    // }
    function rewardVeLendFlarePoolLength() external view returns (uint256) {
        return rewardVeLendFlarePool.length;
    }

    function addRewardVeLendFlarePool(address _v) external returns (bool) {
        rewardVeLendFlarePool.push(IRewardVeLendFlarePool(_v));

        return true;
    }

    function clearRewardVeLendFlarePool() external {
        delete rewardVeLendFlarePool;
    }

    function get_last_user_slope(address addr) external view returns (int128) {
        uint256 uepoch = user_point_epoch[addr];

        return user_point_history[addr][uepoch].slope;
    }

    function user_point_history_ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return user_point_history[_addr][_idx].ts;
    }

    function locked_end(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    function _checkpoint(
        address addr,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;

        int128 old_dslope;
        int128 new_dslope;

        if (addr != address(0)) {
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / int128(MAXTIME);
                // u_old.bias = u_old.slope * convert(old_locked.end - block.timestamp, int128);
                u_old.bias =
                    u_old.slope *
                    int128(old_locked.end - block.timestamp);
            }

            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / int128(MAXTIME);
                u_new.bias =
                    u_new.slope *
                    int128(new_locked.end - block.timestamp);
            }

            old_dslope = slope_changes[old_locked.end];

            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });

        if (epoch > 0) {
            last_point = point_history[epoch];
        }

        uint256 last_checkpoint = last_point.ts;
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0;

        if (block.timestamp > last_point.ts) {
            block_slope =
                (MULTIPLIER * (block.number - last_point.blk)) /
                (block.timestamp - last_point.ts);
        }

        uint256 t_i = (last_checkpoint / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            int128 d_slope = 0;

            if (t_i > block.timestamp) {
                t_i = block.timestamp;
            } else {
                d_slope = slope_changes[t_i];
            }

            //    last_point.bias -= last_point.slope * convert(t_i - last_checkpoint, int128);
            last_point.bias -= last_point.slope * int128(t_i - last_checkpoint);
            last_point.slope += d_slope;

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }

            last_checkpoint = t_i;
            last_point.ts = t_i;
            last_point.blk =
                initial_last_point.blk +
                (block_slope * (t_i - initial_last_point.ts)) /
                MULTIPLIER;

            epoch += 1;

            if (t_i == block.timestamp) {
                last_point.blk = block.number;
                break;
            } else {
                point_history[epoch] = last_point;
            }
        }

        if (addr != address(0)) {
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        point_history[epoch] = last_point;

        if (addr != address(0)) {
            if (old_locked.end > block.timestamp) {
                old_dslope += u_old.slope;

                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope;
                }

                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope;
                    slope_changes[new_locked.end] = new_dslope;
                }
            }

            uint256 user_epoch = user_point_epoch[addr] + 1;
            user_point_epoch[addr] = user_epoch;

            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[addr][user_epoch] = u_new;
        }
    }

    function _deposit_for(
        address _addr,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance memory locked_balance,
        DepositTypes depositTypes
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before + _value;
        LockedBalance memory old_locked = _locked;

        // _locked.amount += convert(_value, int128);
        _locked.amount += int128(_value);

        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }

        locked[_addr] = _locked;

        _checkpoint(_addr, old_locked, _locked);

        if (_value != 0) {
            IERC20(token).transferFrom(_addr, address(this), _value);
        }

        for (uint256 i = 0; i < rewardVeLendFlarePool.length; i++) {
            rewardVeLendFlarePool[i].updateRewardState(msg.sender);
        }

        emit Deposit(_addr, _value, _locked.end, depositTypes, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    function checkpoint() external {
        LockedBalance memory lb;

        for (uint256 i = 0; i < rewardVeLendFlarePool.length; i++) {
            rewardVeLendFlarePool[i].updateRewardState(msg.sender);
        }

        _checkpoint(address(0), lb, lb);
    }

    function deposit_for(address _addr, uint256 _value) external nonReentrant {
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(
            _addr,
            _value,
            0,
            locked[_addr],
            DepositTypes.DEPOSIT_FOR_TYPE
        );
    }

    function create_lock(uint256 _value, uint256 _unlock_time)
        external
        nonReentrant
    {
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "need non-zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            unlock_time > block.timestamp,
            "Can only lock until time in the future"
        );
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            _value,
            unlock_time,
            _locked,
            DepositTypes.CREATE_LOCK_TYPE
        );
    }

    function increase_amount(uint256 _value) external nonReentrant {
        LockedBalance memory _locked = locked[msg.sender];
        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(
            msg.sender,
            _value,
            0,
            _locked,
            DepositTypes.INCREASE_LOCK_AMOUNT
        );
    }

    function increase_unlock_time(uint256 _unlock_time) external nonReentrant {
        // assert_not_contract(msg.sender);

        LockedBalance memory _locked = locked[msg.sender];
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            0,
            unlock_time,
            _locked,
            DepositTypes.INCREASE_UNLOCK_TIME
        );
    }

    function withdraw() public {
        LockedBalance memory _locked = locked[msg.sender];

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        // uint256 value = convert(_locked.amount, uint256);
        uint256 value = uint256(_locked.amount);

        LockedBalance memory old_locked = _locked;
        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;

        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before - value;

        _checkpoint(msg.sender, old_locked, _locked);

        IERC20(token).transfer(msg.sender, value);

        for (uint256 i = 0; i < rewardVeLendFlarePool.length; i++) {
            rewardVeLendFlarePool[i].updateRewardState(msg.sender);
        }

        emit Withdraw(msg.sender, value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function find_block_epoch(uint256 _block, uint256 max_epoch)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = max_epoch;

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    function balanceOf(address addr, uint256 _t) public view returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = user_point_epoch[addr];

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[addr][_epoch];
            // last_point.bias -= last_point.slope * convert(_t - last_point.ts, int128);
            last_point.bias -= last_point.slope * int128(_t - last_point.ts);

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            // return convert(last_point.bias, uint256);
            return uint256(last_point.bias);
        }
    }

    function balanceOfAt(address addr, uint256 _block)
        public
        view
        returns (uint256)
    {
        require(_block <= block.number);

        uint256 _min = 0;
        uint256 _max = user_point_epoch[addr];

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (user_point_history[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[addr][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;

        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        // upoint.bias -= upoint.slope * convert(block_time - upoint.ts, int128);
        upoint.bias -= upoint.slope * int128(block_time - upoint.ts);

        if (upoint.bias >= 0) {
            // return convert(upoint.bias, uint256);
            return uint256(upoint.bias);
        } else {
            return 0;
        }
    }

    function supply_at(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory last_point = point;
        uint256 t_i = (last_point.ts / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            int128 d_slope = 0;

            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }

            // last_point.bias -= last_point.slope * convert(t_i - last_point.ts, int128);
            last_point.bias -= last_point.slope * int128(t_i - last_point.ts);

            if (t_i == t) break;

            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }

        // return convert(last_point.bias, uint256);
        return uint256(last_point.bias);
    }

    function totalSupply(uint256 t) public view returns (uint256) {
        if (t == 0) {
            t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory last_point = point_history[_epoch];

        return supply_at(last_point, t);
    }

    function totalSupplyAt(uint256 _block) public view returns (uint256) {
        require(_block <= block.number);

        uint256 _epoch = epoch;
        uint256 target_epoch = find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;

        if (target_epoch < _epoch) {
            Point memory point_next = point_history[target_epoch + 1];

            if (point.blk != point_next.blk) {
                dt =
                    ((_block - point.blk) * (point_next.ts - point.ts)) /
                    (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }

        return supply_at(point, point.ts + dt);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOf(account, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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

    constructor() internal {
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

pragma solidity =0.6.12;

import "./libs/SafeERC20.sol";
import "./libs/Ownable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract LiquidityTransformer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public lendflareToken;
    IUniswapV2Pair public uniswapPair;

    IUniswapV2Router02 public constant uniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable constant teamAddress =
        0x0779Cfc15116283792698Da362F9ACBd1C4b8abf;

    uint256 public constant liquifyTokens = 10000 * 1e18;
    // uint256 constant investmentDays = 7 days;
    uint256 constant investmentDays = 10 minutes;
    uint256 constant minInvest = 0.1 ether;
    uint256 public startedAt;

    struct Globals {
        uint256 totalUsers;
        uint256 transferedUsers;
        uint256 totalWeiContributed;
        bool liquidity;
    }

    Globals public globals;

    mapping(address => uint256) public investorBalances;
    mapping(address => uint256[2]) investorHistory;

    event UniSwapResult(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    modifier afterUniswapTransfer() {
        require(globals.liquidity == true, "forward liquidity first");
        _;
    }

    receive() external payable {
        revert();
    }

    constructor(address _lendflareToken) public {
        lendflareToken = IERC20(_lendflareToken);
        startedAt = block.timestamp;
        // UNISWAPPAIR = UniswapV2Pair(_uniswapPair);
    }

    function createPair() external {
        uniswapPair = IUniswapV2Pair(
            IUniswapV2Factory(factory()).createPair(WETH(), address(this))
        );
    }

    function reserve() external payable {
        require(globals.liquidity == false, "!globals.liquidity");
        require(msg.value >= minInvest, "investment below minimum");

        _reserve(msg.sender, msg.value);
    }

    function reserveWithToken(address _tokenAddress, uint256 _tokenAmount)
        external
    {
        require(globals.liquidity == false, "!globals.liquidity");

        IERC20 token = IERC20(_tokenAddress);

        token.transferFrom(msg.sender, address(this), _tokenAmount);

        token.approve(address(uniswapRouter), _tokenAmount);

        address[] memory _path = preparePath(_tokenAddress);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            _tokenAmount,
            0,
            _path,
            address(this),
            block.timestamp.add(2 hours)
        );

        require(amounts[1] >= minInvest, "investment below minimum");

        _reserve(msg.sender, amounts[1]);
    }

    function _reserve(address _senderAddress, uint256 _senderValue) internal {
        investorBalances[_senderAddress] += _senderValue;

        globals.totalWeiContributed += _senderValue;
        globals.totalUsers++;
    }

    function forwardLiquidity() external {
        require(
            block.timestamp >= startedAt.add(investmentDays),
            "Not over yet"
        );

        uint256 _fee = globals.totalWeiContributed.mul(100).div(1000);
        uint256 _balance = globals.totalWeiContributed.sub(_fee);

        teamAddress.transfer(_fee);

        uint256 half = liquifyTokens.div(2);

        lendflareToken.approve(address(uniswapRouter), half);

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = uniswapRouter.addLiquidityETH{value: _balance}(
                address(lendflareToken),
                half,
                0,
                0,
                address(0x0),
                block.timestamp.add(2 hours)
            );

        globals.liquidity = true;

        emit UniSwapResult(amountToken, amountETH, liquidity);
    }

    function getMyTokens() external afterUniswapTransfer {
        require(investorBalances[msg.sender] > 0, "!balance");

        // uint256 tokenBalance = IERC20(lendflareToken).balanceOf(address(this));
        uint256 half = liquifyTokens.div(2);
        uint256 otherHalf = liquifyTokens.sub(half);
        uint256 percent = investorBalances[msg.sender].mul(100e18).div(
            globals.totalWeiContributed
        );
        uint256 myTokens = otherHalf.mul(percent).div(100e18);

        investorHistory[msg.sender][0] = investorBalances[msg.sender];
        investorHistory[msg.sender][1] = myTokens;
        investorBalances[msg.sender] = 0;

        IERC20(lendflareToken).safeTransfer(msg.sender, myTokens);

        globals.transferedUsers++;

        if (globals.transferedUsers == globals.totalUsers) {
            uint256 surplusBalance = IERC20(lendflareToken).balanceOf(
                address(this)
            );

            if (surplusBalance > 0) {
                IERC20(lendflareToken).safeTransfer(
                    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                    surplusBalance
                );
            }
        }
    }

    /* view functions */
    function WETH() public pure returns (address) {
        return IUniswapV2Router02(uniswapRouter).WETH();
    }

    function factory() public pure returns (address) {
        return IUniswapV2Router02(uniswapRouter).factory();
    }

    function getInvestorHistory(address _sender)
        public
        view
        returns (uint256[2] memory)
    {
        return investorHistory[_sender];
    }

    function preparePath(address _tokenAddress)
        internal
        pure
        returns (address[] memory _path)
    {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";

interface ISponsoredContract {
    function getUserLendingState(bytes32 _lendingId)
        external
        view
        returns (uint256);
}

contract LiquidateSponsor is Ownable {
    enum LendingInfoState {
        NONE,
        WAITTING,
        CLOSED
    }

    struct LendingInfo {
        address user;
        uint256 expendGas;
        uint256 amount;
        LendingInfoState state;
    }

    bool public isPaused;
    address public liquidateSponsor;
    address public sponsoredContract;
    uint256 public totalSupply;
    uint256 public totalRequest;
    uint256 public sponsorAmount = 0.1 ether;

    mapping(bytes32 => LendingInfo) public lendingInfos;

    event SponsoredContribution(bytes32 sponsor, uint256 amount);
    event RequestSponsor(bytes32 sponsor, uint256 amount);
    event PayFee(
        bytes32 sponsor,
        address user,
        uint256 sponsorAmount,
        uint256 expendGas
    );

    modifier onlySponsor() {
        require(
            msg.sender == liquidateSponsor,
            "LiquidateSponsor: not a sponsor"
        );
        _;
    }

    constructor() public {
        liquidateSponsor = msg.sender;
    }

    function setSponsoredContract(address _s) external onlySponsor {
        sponsoredContract = _s;
    }

    function payFee(
        bytes32 _lendingId,
        address _user,
        uint256 _expendGas
    ) public {
        if (msg.sender == sponsoredContract && isPaused == false) {
            if (address(this).balance < sponsorAmount) {
                return;
            }

            LendingInfo storage lendingInfo = lendingInfos[_lendingId];

            if (
                lendingInfo.state == LendingInfoState.NONE ||
                lendingInfo.state == LendingInfoState.WAITTING
            ) {
                lendingInfo.expendGas = _expendGas;
                lendingInfo.state = LendingInfoState.CLOSED;

                payable(_user).transfer(sponsorAmount);

                emit PayFee(_lendingId, _user, sponsorAmount, _expendGas);
            }
        }
    }

    function addSponsor(bytes32 _lendingId, address _user) public payable {
        if (msg.sender == sponsoredContract && isPaused == false) {
            lendingInfos[_lendingId] = LendingInfo({
                user: _user,
                amount: msg.value,
                expendGas: 0,
                state: LendingInfoState.NONE
            });

            totalSupply += msg.value;
            totalRequest++;

            emit SponsoredContribution(_lendingId, msg.value);
        }
    }

    function requestSponsor(bytes32 _lendingId) public {
        if (msg.sender == sponsoredContract && isPaused == false) {
            LendingInfo storage lendingInfo = lendingInfos[_lendingId];

            if (address(this).balance < sponsorAmount) {
                lendingInfo.state = LendingInfoState.WAITTING;
                return;
            }

            if (
                lendingInfo.state == LendingInfoState.NONE ||
                lendingInfo.state == LendingInfoState.WAITTING
            ) {
                lendingInfo.state = LendingInfoState.CLOSED;

                payable(lendingInfo.user).transfer(lendingInfo.amount);

                totalRequest--;
            }

            emit RequestSponsor(_lendingId, lendingInfo.amount);
        }
    }

    // function manualSponsor(bytes32 _lendingId) public {
    //     if (isPaused == false) {
    //         LendingInfo storage lendingInfo = lendingInfos[_lendingId];

    //         require(msg.sender == lendingInfo.user, "!user");

    //         uint256 state = ISponsoredContract(sponsoredContract)
    //             .getUserLendingState(_lendingId);

    //         require(state == 1, "!state");

    //         if (address(this).balance < sponsorAmount) {
    //             lendingInfo.state = LendingInfoState.WAITTING;
    //             return;
    //         }

    //         if (
    //             lendingInfo.state == LendingInfoState.NONE ||
    //             lendingInfo.state == LendingInfoState.WAITTING
    //         ) {
    //             lendingInfo.state = LendingInfoState.CLOSED;

    //             payable(lendingInfo.user).transfer(lendingInfo.amount);

    //             totalRequest--;
    //         }
    //     }
    // }

    function refund() public onlyOwner {
        require(totalRequest == 0, "!totalRequest");
        require(address(this).balance > 0, "!balance");

        payable(owner()).transfer(address(this).balance);
    }

    function pause() external onlySponsor {
        isPaused = true;
    }

    function resume() external onlySponsor {
        isPaused = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeMath.sol";

interface ILiquidityGauge {
    function user_checkpoint(address _for) external;

    function integrate_fraction(address _for) external view returns (uint256);
}

interface ILendFlareToken {
    function mint(address _for, uint256 amount) external;
}

contract LendFlareTokenMinter {
    using SafeMath for uint256;

    address public token;

    mapping(address => mapping(address => uint256)) public minted; // user -> gauge -> value

    event Minted(address user, address gauge, uint256 amount);

    constructor(address _token) public {
        token = _token;
    }

    function _mint_for(address gauge_addr, address _for) internal {
        ILiquidityGauge(gauge_addr).user_checkpoint(_for);
        uint256 total_mint = ILiquidityGauge(gauge_addr).integrate_fraction(
            _for
        );
        uint256 to_mint = total_mint - minted[_for][gauge_addr];

        if (to_mint != 0) {
            ILendFlareToken(token).mint(_for, to_mint);
            minted[_for][gauge_addr] = total_mint;

            emit Minted(_for, gauge_addr, total_mint);
        }
    }

    function mint(address gauge_addr) public {
        _mint_for(gauge_addr, msg.sender);
    }

    function mint_many(address[8] memory gauge_addrs) public {
        for (uint256 i = 0; i < gauge_addrs.length; i++) {
            if (gauge_addrs[i] == address(0)) break;

            _mint_for(gauge_addrs[i], msg.sender);
        }
    }

    function mint_for(address gauge_addr, address _for) public {
        _mint_for(gauge_addr, _for);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";

contract LendFlareToken is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "LendFlare DAO Token";
    string private _symbol = "LFT";
    uint256 private _decimals = 18;

    /* 
    Allocation:
    =========
    * shareholders - 30%
    * emplyees - 3%
    * DAO-controlled reserve - 5%
    * Early users - 5%
    == 43% ==
    left for inflation: 57%
     */

    uint256 constant ONE_DAY = 86400;
    uint256 constant YEAR = ONE_DAY * 365;
    uint256 constant INITIAL_SUPPLY = 1303030303;
    uint256 constant INITIAL_RATE = (274815283 * 10**18) / YEAR; // leading to 43% premine
    uint256 constant RATE_REDUCTION_TIME = YEAR;
    uint256 constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024; // 2 ** (1/4) * 1e18
    uint256 constant RATE_DENOMINATOR = 10**18;

    int128 public mining_epoch;
    uint256 public start_epoch_time;
    uint256 public rate;
    uint256 public start_epoch_supply;

    address public minter;

    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event SetMinter(address minter);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() public {
        uint256 init_supply = INITIAL_SUPPLY * 10**_decimals;

        _balances[msg.sender] = init_supply;
        _totalSupply = init_supply;

        emit Transfer(address(0x0), msg.sender, init_supply);

        // start_epoch_time = block.timestamp + ONE_DAY - RATE_REDUCTION_TIME;
        start_epoch_time = block.timestamp - RATE_REDUCTION_TIME;
        mining_epoch = -1;
        rate = 0;
        start_epoch_supply = init_supply;
    }

    function _update_mining_parameters() internal {
        uint256 _rate = rate;
        uint256 _start_epoch_supply = start_epoch_supply;

        start_epoch_time += RATE_REDUCTION_TIME;
        mining_epoch += 1;

        if (_rate == 0) {
            _rate = INITIAL_RATE;
        } else {
            _start_epoch_supply += _rate * RATE_REDUCTION_TIME;
            start_epoch_supply = _start_epoch_supply;
            _rate = (_rate * RATE_DENOMINATOR) / RATE_REDUCTION_COEFFICIENT;
        }

        rate = _rate;

        emit UpdateMiningParameters(
            block.timestamp,
            _rate,
            _start_epoch_supply
        );
    }

    function update_mining_parameters() external {
        require(
            block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME,
            "too soon!"
        );

        _update_mining_parameters();
    }

    function start_epoch_time_write() external returns (uint256) {
        uint256 _start_epoch_time = start_epoch_time;

        if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();

            return start_epoch_time;
        }

        return _start_epoch_time;
    }

    function future_epoch_time_write() external returns (uint256) {
        uint256 _start_epoch_time = start_epoch_time;

        if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();

            return start_epoch_time + RATE_REDUCTION_TIME;
        }

        return _start_epoch_time + RATE_REDUCTION_TIME;
    }

    function _available_supply() internal view returns (uint256) {
        return start_epoch_supply + (block.timestamp - start_epoch_time) * rate;
    }

    function available_supply() public view returns (uint256) {
        return _available_supply();
    }

    function mintable_in_timeframe(uint256 start, uint256 end)
        external
        view
        returns (uint256)
    {
        require(start <= end, "start > end");

        uint256 to_mint = 0;
        uint256 current_epoch_time = start_epoch_time;
        uint256 current_rate = rate;

        if (end > current_epoch_time + RATE_REDUCTION_TIME) {
            current_epoch_time += RATE_REDUCTION_TIME;
            current_rate =
                (current_rate * RATE_DENOMINATOR) /
                RATE_REDUCTION_COEFFICIENT;
        }

        require(
            end <= current_epoch_time + RATE_REDUCTION_TIME,
            "too far in future"
        );

        // LendFlareToken will not work in 1000 years. Darn!
        for (uint256 i = 0; i < 999; i++) {
            if (end >= current_epoch_time) {
                uint256 current_end = end;

                if (current_end > current_epoch_time + RATE_REDUCTION_TIME) {
                    current_end = current_epoch_time + RATE_REDUCTION_TIME;
                }

                uint256 current_start = start;

                if (current_start >= current_epoch_time + RATE_REDUCTION_TIME) {
                    break;
                } else if (current_start < current_epoch_time) {
                    current_start = current_epoch_time;
                }

                to_mint += current_rate * (current_end - current_start);

                if (start >= current_epoch_time) break;

                current_epoch_time -= RATE_REDUCTION_TIME;
                current_rate =
                    (current_rate * RATE_REDUCTION_COEFFICIENT) /
                    RATE_DENOMINATOR;

                require(
                    current_rate <= INITIAL_RATE,
                    "This should never happen"
                );
            }
        }

        return to_mint;
    }

    function set_minter(address _minter) public onlyOwner {
        minter = _minter;

        emit SetMinter(_minter);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public returns (bool) {
        require(msg.sender == minter);
        require(account != address(0), "ERC20: mint to the zero address");

        if (block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();
        }

        _totalSupply = _totalSupply.add(amount);

        require(
            _totalSupply <= _available_supply(),
            "exceeds allowable mint amount"
        );

        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/SafeMath.sol";

contract LendFlareGaugeModel {
    using SafeMath for uint256;

    address[] public gauges;
    uint256 public n_gauges;

    mapping(address => uint256) gauge_weight;

    constructor(address _minter) public {}

    // 46650511811694184/1e18
    // 0.04665051181169418
    function add_gauge(address gauge, uint256 weight) public {
        n_gauges = n_gauges + 1;

        gauges.push(gauge);
        gauge_weight[gauge] = weight;
    }

    function gauge_relative_weight(address gauge)
        public
        view
        returns (uint256)
    {
        return gauge_weight[gauge];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "./libs/SafeMath.sol";
import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";

interface Controller {
    function vaults(address) external view returns (address);

    function rewards() external view returns (address);
}

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;
}

interface Mintr {
    function mint(address) external;
}

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}

interface yERC20 {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;
}

interface ICurveFi {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts)
        external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

interface VoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function withdraw() external;
}

contract CurveYCRVVoter {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant want =
        address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address public constant pool =
        address(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
    address public constant mintr =
        address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant crv =
        address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public constant escrow =
        address(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);

    address public governance;
    address public strategy;

    constructor() public {
        governance = msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "CurveYCRVVoter";
    }

    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(pool, 0);
            IERC20(want).safeApprove(pool, _want);
            Gauge(pool).deposit(_want);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == strategy, "!controller");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(strategy, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == strategy, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(want).safeTransfer(strategy, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == strategy, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(strategy, balance);
    }

    function _withdrawAll() internal {
        Gauge(pool).withdraw(Gauge(pool).balanceOf(address(this)));
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
        IERC20(crv).safeApprove(escrow, 0);
        IERC20(crv).safeApprove(escrow, _value);
        VoteEscrow(escrow).create_lock(_value, _unlockTime);
    }

    function increaseAmount(uint256 _value) external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
        IERC20(crv).safeApprove(escrow, 0);
        IERC20(crv).safeApprove(escrow, _value);
        VoteEscrow(escrow).increase_amount(_value);
    }

    function release() external {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!authorized"
        );
        VoteEscrow(escrow).withdraw();
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        Gauge(pool).withdraw(_amount);
        return _amount;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return Gauge(pool).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory) {
        require(
            msg.sender == strategy || msg.sender == governance,
            "!governance"
        );
        (bool success, bytes memory result) = to.call.value(value)(data);

        return (success, result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/Math.sol";
import "../libs/SafeMath.sol";
import "../libs/IERC20.sol";
import "../libs/SafeERC20.sol";
import "./ConvexInterfaces.sol";
import "../common/IVirtualBalanceWrapper.sol";

contract ConvexRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardToken;
    // uint256 public constant duration = 7 days;
    uint256 public constant duration = 10 minutes;

    address public operator;
    address public virtualBalance;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public newRewardRatio = 830;
    // uint256 private _totalSupply;

    address[] public extraRewards;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    // mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address _reward,
        address _virtualBalance,
        address _op
    ) public {
        rewardToken = _reward;
        virtualBalance = _virtualBalance;
        operator = _op;
    }

    function totalSupply() public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).totalSupply();
    }

    function balanceOf(address _for) public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
    }

    function extraRewardsLength() external view returns (uint256) {
        return extraRewards.length;
    }

    function addExtraReward(address _reward) external returns (bool) {
        // require(msg.sender == rewardManager, "!authorized");
        require(_reward != address(0), "!reward setting");

        extraRewards.push(_reward);
        return true;
    }

    function clearExtraRewards() external {
        // require(msg.sender == rewardManager, "!authorized");
        delete extraRewards;
    }

    modifier updateReward(address _for) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_for != address(0)) {
            rewards[_for] = earned(_for);
            userRewardPerTokenPaid[_for] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _for) public view returns (uint256) {
        return
            balanceOf(_for)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_for]))
                .div(1e18)
                .add(rewards[_for]);
    }

    function getReward(address _for, bool _claimExtras)
        public
        updateReward(_for)
    {
        uint256 reward = earned(_for);
        if (reward > 0) {
            rewards[_for] = 0;
            if (rewardToken != address(0)) {
                IERC20(rewardToken).safeTransfer(_for, reward);
            } else {
                payable(_for).transfer(reward);
            }

            emit RewardPaid(_for, reward);
        }

        if (_claimExtras) {
            for (uint256 i = 0; i < extraRewards.length; i++) {
                IConvexRewardPool(extraRewards[i]).getReward(_for, true);
            }
        }
    }

    function donate(uint256 _amount) external payable returns (bool) {
        if (rewardToken != address(0)) {
            IERC20(rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
            queuedRewards = queuedRewards.add(_amount);
        } else {
            queuedRewards = queuedRewards.add(msg.value);
        }
    }

    function queueNewRewards(uint256 _rewards) external {
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(_reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);

            _reward = _reward.add(leftover);
            rewardRate = _reward.div(duration);
        }

        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(_reward);
    }

    receive() external payable {}
}

contract ConvexRewardFactory {
    function CreateRewards(
        address _reward,
        address _virtualBalance,
        address _operator
    ) external returns (address) {
        ConvexRewardPool rewardPool = new ConvexRewardPool(
            _reward,
            _virtualBalance,
            _operator
        );

        return address(rewardPool);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface IConvexBooster {
    function deposit( uint256 _pid, uint256 _amount, bool _stake ) external returns (bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    function cliamStashToken( address _token, address _rewardAddress, address _lfRewardAddress, uint256 _rewards ) external;

    /* 
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }
     */
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
    function isShutdown() external view returns(bool);
    function minter() external view returns(address);
    function earmarkRewards(uint256) external returns(bool);
}

interface IConvexStaker {
    function deposit( address _sender, uint256 _pid, address _lpToken, uint256 _amount,address _rewardPool ) external;
    function withdraw( address _sender, uint256 _pid, address _lpToken, uint256 _amount,address _rewardPool ) external;
    function liquidate( address _liquidater, address _liquidateSender, uint256 _pid, address _lpToken, uint256 _amount, address _rewardPool ) external;
    function earmarkRewards(uint256,address _rewardPool) external returns(bool);
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
}

interface IOriginConvexRewardPool {
    function getReward() external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function withdrawAllAndUnwrap(bool claim) external;
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function withdrawAll(bool claim) external;
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function stakeFor(address _for, uint256 _amount) external returns(bool);
    function stakeAll() external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function earned(address account) external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardToken() external returns(address);
    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
}

interface IConvexRewardPool {
    // function stake(address _for, uint256 amount) external;
    // function stakeFor(address _for, uint256 amount) external;
    // function withdraw(address _for, uint256 amount) external;
    // function withdrawFor(address _for, uint256 amount) external;
    function queueNewRewards(uint256 _rewards) external;
    // function rewardToken() external returns(address);
    // function rewardConvexToken() external returns(address);

    function getReward(address _account, bool _claimExtras) external returns (bool);
    function earned(address account) external view returns (uint256);

    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
    function addExtraReward(address _reward) external returns(bool);

    // function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    /* 
    function clearExtraRewards() external; */
}

interface IConvexRewardFactory {
    function CreateRewards(address _reward, address _virtualBalance, address _operator) external returns (address);
}

interface ICurveSwap {
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity(uint256 _token_amount, uint256[] memory min_amounts) external;
    function coins(uint256 _coinId) external view returns(address);
    function balances(uint256 _coinId) external view returns(uint256);
}

interface IConvexStashRewardPool {
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getReward(address _account) external;
    function donate(uint256 _amount) external payable returns (bool);
    function queueNewRewards(uint256 _rewards) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/SafeERC20.sol";
import "./convex/ConvexInterfaces.sol";
import "./common/IVirtualBalanceWrapper.sol";
import "./convex/ConvexStashTokens.sol";

contract ConvexBooster {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public convexRewardFactory;
    address public virtualBalanceWrapperFactory;
    address public convexBooster;
    address public rewardCrvToken;

    struct PoolInfo {
        uint256 originConvexPid;
        address curveSwapAddress; /* like 3pool https://github.com/curvefi/curve-js/blob/master/src/constants/abis/abis-ethereum.ts */
        address lpToken;
        address originCrvRewards;
        address originStash;
        address virtualBalance;
        address rewardPool;
        // address stashToken;
        uint256 swapType;
        uint256 swapCoins;
    }

    PoolInfo[] public poolInfo;

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _convexBooster,
        address _convexRewardFactory,
        address _virtualBalanceWrapperFactory,
        address _rewardCrvToken
    ) public {
        convexRewardFactory = _convexRewardFactory;
        convexBooster = _convexBooster;
        virtualBalanceWrapperFactory = _virtualBalanceWrapperFactory;
        rewardCrvToken = _rewardCrvToken;
    }

    function addConvexPool(
        uint256 _originConvexPid,
        address _curveSwapAddress,
        uint256 _swapType,
        uint256 _swapCoins
    ) public {
        (
            address lpToken,
            ,
            ,
            address originCrvRewards,
            address originStash,
            bool shutdown
        ) = IConvexBooster(convexBooster).poolInfo(_originConvexPid);

        require(shutdown == false, "!shutdown");

        address virtualBalance = IVirtualBalanceWrapperFactory(
            virtualBalanceWrapperFactory
        ).CreateVirtualBalanceWrapper(address(this));

        address rewardPool = IConvexRewardFactory(convexRewardFactory)
            .CreateRewards(rewardCrvToken, virtualBalance, address(this));

        uint256 extraRewardsLength = IOriginConvexRewardPool(originCrvRewards)
            .extraRewardsLength();

        if (extraRewardsLength > 0) {
            for (uint256 i = 0; i < extraRewardsLength; i++) {
                address extraRewardToken = IOriginConvexRewardPool(
                    originCrvRewards
                ).extraRewards(i);

                address extraRewardPool = IConvexRewardFactory(
                    convexRewardFactory
                ).CreateRewards(
                        IOriginConvexRewardPool(extraRewardToken).rewardToken(),
                        virtualBalance,
                        address(this)
                    );

                IConvexRewardPool(rewardPool).addExtraReward(extraRewardPool);
            }
        }

        poolInfo.push(
            PoolInfo({
                originConvexPid: _originConvexPid,
                curveSwapAddress: _curveSwapAddress,
                lpToken: lpToken,
                originCrvRewards: originCrvRewards,
                originStash: originStash,
                virtualBalance: virtualBalance,
                rewardPool: rewardPool,
                swapType: _swapType,
                swapCoins: _swapCoins
            })
        );
    }

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        IERC20(pool.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // (
        //     address lpToken,
        //     address token,
        //     address gauge,
        //     address crvRewards,
        //     address stash,
        //     bool shutdown
        // ) = IConvexBooster(convexBooster).poolInfo(pool.convexPid);
        (, , , , , bool shutdown) = IConvexBooster(convexBooster).poolInfo(
            pool.originConvexPid
        );

        require(!shutdown, "!shutdown");

        IERC20(pool.lpToken).safeApprove(convexBooster, 0);
        IERC20(pool.lpToken).safeApprove(convexBooster, _amount);

        IConvexBooster(convexBooster).deposit(
            pool.originConvexPid,
            _amount,
            true
        );

        IVirtualBalanceWrapper(pool.virtualBalance).stakeFor(_user, _amount);

        emit Deposited(_user, _pid, _amount);

        return true;
    }

    function withdrawFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(
            _amount,
            true
        );
        IERC20(pool.lpToken).safeTransfer(_user, _amount);
        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(_user, _amount);

        if (IConvexRewardPool(pool.rewardPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardPool).getReward(_user, true);
        }

        return true;
    }

    // function earmarkRewards(uint256 _pid) external returns (bool) {
    //     PoolInfo storage pool = poolInfo[_pid];

    //     if (pool.stashToken != address(0)) {
    //         ConvexStashTokens(pool.stashToken).stashRewards();
    //     }

    //     // if (pool.stash != address(0)) {
    //     //     //claim extra rewards
    //     //     IConvexStash(pool.stash).claimRewards();
    //     //     //process extra rewards
    //     //     IConvexStash(pool.stash).processStash();
    //     // }

    //     // IConvexStaker(convexStaker).earmarkRewards(
    //     //     pool.convexPid,
    //     //     pool.rewardPool
    //     // );

    //     // new
    //     // IConvexBooster(booster).earmarkRewards(_pid);

    //     // address crv = IConvexRewardPool(_rewardPool).rewardToken();
    //     // address cvx = IConvexRewardPool(_rewardPool).rewardConvexToken();
    //     // uint256 crvBal = IERC20(crv).balanceOf(address(this));
    //     // uint256 cvxBal = IERC20(cvx).balanceOf(address(this));

    //     // if (cvxBal > 0) {
    //     //     IERC20(cvx).safeTransfer(_rewardPool, cvxBal);
    //     // }

    //     // if (crvBal > 0) {
    //     //     IERC20(crv).safeTransfer(_rewardPool, crvBal);

    //     //     IConvexRewardPool(_rewardPool).queueNewRewards(crvBal);
    //     // }

    //     return true;
    // }

    //claim fees from curve distro contract, put in lockers' reward contract
    // function earmarkFees() external returns (bool) {
    //     // //claim fee rewards
    //     // IStaker(staker).claimFees(feeDistro, feeToken);
    //     // //send fee rewards to reward contract
    //     // uint256 _balance = IERC20(feeToken).balanceOf(address(this));
    //     // IERC20(feeToken).safeTransfer(lockFees, _balance);
    //     // IRewards(lockFees).queueNewRewards(_balance);
    //     return true;
    // }

    function liquidate(
        uint256 _pid,
        int128 _coinId,
        address _user,
        uint256 _amount
    ) external returns (address, uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(
            _amount,
            true
        );

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(_user, _amount);

        IERC20(pool.lpToken).safeApprove(pool.curveSwapAddress, 0);
        IERC20(pool.lpToken).safeApprove(pool.curveSwapAddress, _amount);

        address underlyToken = ICurveSwap(pool.curveSwapAddress).coins(
            uint256(_coinId)
        );

        if (pool.swapType == 0) {
            ICurveSwap(pool.curveSwapAddress).remove_liquidity_one_coin(
                _amount,
                _coinId,
                0
            );
        }

        if (pool.swapType == 1) {
            uint256[] memory min_amounts = new uint256[](pool.swapCoins);

            ICurveSwap(pool.curveSwapAddress).remove_liquidity(
                _amount,
                min_amounts
            );
        }

        // eth
        if (underlyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            uint256 totalAmount = address(this).balance;

            msg.sender.transfer(totalAmount);

            return (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, totalAmount);
        } else {
            uint256 totalAmount = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(msg.sender, totalAmount);

            return (underlyToken, totalAmount);
        }
    }

    function cliamRewardToken(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        address originCrvRewards = pool.originCrvRewards;
        address currentCrvRewards = pool.rewardPool;

        IOriginConvexRewardPool(originCrvRewards).getReward(
            address(this),
            true
        );

        address rewardUnderlyToken = IOriginConvexRewardPool(originCrvRewards)
            .rewardToken();
        uint256 crvBalance = IERC20(rewardUnderlyToken).balanceOf(
            address(this)
        );

        if (crvBalance > 0) {
            IERC20(rewardUnderlyToken).safeTransfer(
                currentCrvRewards,
                crvBalance
            );

            IConvexRewardPool(originCrvRewards).queueNewRewards(crvBalance);
        }

        uint256 extraRewardsLength = IConvexRewardPool(currentCrvRewards)
            .extraRewardsLength();

        if (extraRewardsLength > 0) {
            for (uint256 i = 0; i < extraRewardsLength; i++) {
                address currentExtraReward = IConvexRewardPool(
                    currentCrvRewards
                ).extraRewards(i);
                address originExtraRewardToken = IOriginConvexRewardPool(
                    originCrvRewards
                ).extraRewards(i);
                address extraRewardUnderlyToken = IOriginConvexRewardPool(
                    originExtraRewardToken
                ).rewardToken();

                IOriginConvexRewardPool(originExtraRewardToken).getReward(
                    address(this),
                    true
                );

                uint256 extraBalance = IERC20(extraRewardUnderlyToken)
                    .balanceOf(address(this));

                if (extraBalance > 0) {
                    IERC20(extraRewardUnderlyToken).safeTransfer(
                        currentExtraReward,
                        extraBalance
                    );

                    IConvexRewardPool(currentExtraReward).queueNewRewards(
                        extraBalance
                    );
                }
            }
        }
    }

    function cliamAllRewardToken() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            cliamRewardToken(i);
        }
    }

    // function cliamStashToken(
    //     address _token,
    //     address _rewardAddress,
    //     address _lfRewardAddress,
    //     uint256 _rewards
    // ) public {
    //     IConvexStashRewardPool(_rewardAddress).getReward(address(this));

    //     IERC20(_token).safeTransfer(_lfRewardAddress, _rewards);

    //     IConvexStashRewardPool(_rewardAddress).queueNewRewards(_rewards);
    // }

    receive() external payable {}

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function totalSupplyOf(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        return IERC20(pool.lpToken).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/Math.sol";
import "../libs/IERC20.sol";
import "../libs/SafeERC20.sol";
import "../libs/Address.sol";
import "./ConvexInterfaces.sol";
import "./ConvexStashRewardPool.sol";

interface IConvexExtraRewardStash {
    function tokenCount() external view returns (uint256);

    function tokenInfo(uint256 _idx)
        external
        view
        returns (
            address token,
            address rewardAddress,
            uint256 lastActiveTime
        );
}

/* interface IConvexStashRewardPool {
    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account) external;
}

interface IConvexBooster {
    function cliamStashToken(
        address _token,
        address _rewardAddress,
        address _lfRewardAddress,
        uint256 _rewards
    ) external;
} */

contract ConvexStashTokens {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public convexStash;
    uint256 public pid;
    address public operator;
    address public virtualBalance;

    struct TokenInfo {
        address token;
        address originRewardAddress;
        uint256 originLastActiveTime;
        address rewardAddress;
    }

    // uint256 public tokenCount;
    // TokenInfo[] public tokenInfo;
    mapping(address => TokenInfo) tokenInfos;

    constructor(
        address _operator,
        address _virtualBalance,
        uint256 _pid,
        address _convexStash
    ) public {
        operator = _operator;
        virtualBalance = _virtualBalance;
        pid = _pid;
        convexStash = _convexStash;
    }

    function sync() public {
        require(msg.sender == operator, "!authorized");

        uint256 length = IConvexExtraRewardStash(convexStash).tokenCount();

        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                (
                    address token,
                    address rewardAddress,
                    uint256 lastActiveTime
                ) = IConvexExtraRewardStash(convexStash).tokenInfo(i);

                if (token == address(0)) continue;

                TokenInfo storage tokenInfo = tokenInfos[token];

                if (tokenInfo.token == address(0)) {
                    tokenInfo.token = token;
                    tokenInfo.originRewardAddress = rewardAddress;
                    tokenInfo.originLastActiveTime = lastActiveTime;
                    tokenInfo.rewardAddress = address(
                        new ConvexStashRewardPool(
                            token,
                            operator,
                            virtualBalance
                        )
                    );
                }
            }
        }
    }

    function stashRewards() external returns (bool) {
        require(msg.sender == operator, "!authorized");

        uint256 length = IConvexExtraRewardStash(convexStash).tokenCount();

        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                (
                    address token,
                    address rewardAddress,

                ) = IConvexExtraRewardStash(convexStash).tokenInfo(i);

                if (token == address(0)) continue;

                uint256 rewards = IConvexStashRewardPool(rewardAddress).earned(
                    address(this)
                );

                if (rewards > 0) {
                    IConvexBooster(operator).cliamStashToken(
                        token,
                        rewardAddress,
                        tokenInfos[token].rewardAddress,
                        rewards
                    );
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/Math.sol";
import "../libs/IERC20.sol";
import "../libs/SafeERC20.sol";
import "./ConvexInterfaces.sol";
import "../common/IVirtualBalanceWrapper.sol";

contract ConvexStashRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public constant duration = 7 days;

    address public operator;
    address public virtualBalance;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public newRewardRatio = 830;
    // uint256 private _totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    // mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address _reward,
        address _op,
        address _virtualBalance
    ) public {
        rewardToken = IERC20(_reward);
        operator = _op;
        virtualBalance = _virtualBalance;
    }

    // function totalSupply() public view returns (uint256) {
    //     return _totalSupply;
    // }

    // function balanceOf(address _for) public view returns (uint256) {
    //     return _balances[_for];
    // }

    modifier updateReward(address _for) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_for != address(0)) {
            rewards[_for] = earned(_for);
            userRewardPerTokenPaid[_for] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (IVirtualBalanceWrapper(virtualBalance).totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(IVirtualBalanceWrapper(virtualBalance).totalSupply())
            );
    }

    function earned(address _for) public view returns (uint256) {
        /* return
            balanceOf(_for)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_for]))
                .div(1e18)
                .add(rewards[_for]); */
        return
            IVirtualBalanceWrapper(virtualBalance)
                .balanceOf(_for)
                .mul(1 days)
                .div(1e18)
                .add(rewards[_for]);
    }

    function getReward(address _for) public updateReward(_for) {
        uint256 reward = earned(_for);
        if (reward > 0) {
            rewards[_for] = 0;
            rewardToken.safeTransfer(_for, reward);

            emit RewardPaid(_for, reward);
        }
    }

    function getReward() external {
        getReward(msg.sender);
    }

    function donate(uint256 _amount) external returns (bool) {
        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        queuedRewards = queuedRewards.add(_amount);
    }

    function queueNewRewards(uint256 _rewards) external {
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
        if (queuedRatio < newRewardRatio) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
    }

    function notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(_reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);

            _reward = _reward.add(leftover);
            rewardRate = _reward.div(duration);
        }

        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(_reward);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/Math.sol";
import "../libs/SafeMath.sol";
import "../libs/SafeERC20.sol";
import "./CompoundInterfaces.sol";
import "../common/IVirtualBalanceWrapper.sol";

contract CompoundTreasuryFund {
    using SafeERC20 for IERC20;

    address public operator;
    event WithdrawTo(address indexed user, uint256 amount);

    constructor(address _op) public {
        operator = _op;
    }

    function withdrawTo(
        address _asset,
        uint256 _amount,
        address _to
    ) external {
        require(msg.sender == operator, "!authorized");

        IERC20(_asset).safeTransfer(_to, _amount);

        emit WithdrawTo(_to, _amount);
    }

    function claimComp(
        address _comp,
        address _comptroller,
        address _to
    ) external returns (uint256, bool) {
        require(msg.sender == operator, "!authorized");

        ICompoundComptroller(_comptroller).claimComp(address(this));

        uint256 balanceOfComp = IERC20(_comp).balanceOf(address(this));

        if (balanceOfComp > 0) {
            IERC20(_comp).safeTransfer(_to, balanceOfComp);

            return (balanceOfComp, true);
        }

        return (0, false);
    }
}

// contract CompoundRewardPool {
//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;

//     address public rewardToken;
//     // uint256 public constant duration = 7 days;
//     uint256 public constant duration = 10 minutes;

//     address public operator;
//     address public virtualBalance;

//     uint256 public periodFinish = 0;
//     uint256 public rewardRate = 0;
//     uint256 public lastUpdateTime;
//     uint256 public rewardPerTokenStored;
//     uint256 public queuedRewards = 0;
//     uint256 public currentRewards = 0;
//     uint256 public historicalRewards = 0;
//     uint256 public newRewardRatio = 830;

//     mapping(address => uint256) public userRewardPerTokenPaid;
//     mapping(address => uint256) public rewards;

//     event RewardAdded(uint256 reward);
//     event Staked(address indexed user, uint256 amount);
//     event Withdrawn(address indexed user, uint256 amount);
//     event RewardPaid(address indexed user, uint256 reward);
//     event UpdateRewardState(address indexed user);

//     constructor(
//         address _reward,
//         address _virtualBalance,
//         address _op
//     ) public {
//         rewardToken = _reward;
//         virtualBalance = _virtualBalance;
//         operator = _op;
//     }

//     function totalSupply() public view returns (uint256) {
//         return IVirtualBalanceWrapper(virtualBalance).totalSupply();
//     }

//     function balanceOf(address _for) public view returns (uint256) {
//         return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
//     }

//     modifier updateReward(address _for) {
//         rewardPerTokenStored = rewardPerToken();
//         lastUpdateTime = lastTimeRewardApplicable();

//         if (_for != address(0)) {
//             rewards[_for] = earned(_for);
//             userRewardPerTokenPaid[_for] = rewardPerTokenStored;
//         }
//         _;
//     }

//     function lastTimeRewardApplicable() public view returns (uint256) {
//         return Math.min(block.timestamp, periodFinish);
//     }

//     function rewardPerToken() public view returns (uint256) {
//         if (totalSupply() == 0) {
//             return rewardPerTokenStored;
//         }
//         return
//             rewardPerTokenStored.add(
//                 lastTimeRewardApplicable()
//                     .sub(lastUpdateTime)
//                     .mul(rewardRate)
//                     .mul(1e18)
//                     .div(totalSupply())
//             );
//     }

//     function earned(address _for) public view returns (uint256) {
//         return
//             balanceOf(_for)
//                 .mul(rewardPerToken().sub(userRewardPerTokenPaid[_for]))
//                 .div(1e18)
//                 .add(rewards[_for]);
//     }

//     function getReward(address _for) public updateReward(_for) {
//         uint256 reward = earned(_for);

//         if (reward > 0) {
//             rewards[_for] = 0;

//             if (rewardToken != address(0)) {
//                 IERC20(rewardToken).safeTransfer(_for, reward);
//             } else {
//                 require(
//                     address(this).balance >= reward,
//                     "!address(this).balance"
//                 );

//                 payable(_for).transfer(reward);
//                 // transferOutEther(payable(_for), reward);
//             }

//             emit RewardPaid(_for, reward);
//         }
//     }

//     // function transferOutEther(address payable _for, uint256 amount) internal {
//     //     /* Send the Ether, with minimal gas and revert on failure */
//     //     _for.transfer(amount);
//     // }

//     function getReward() external {
//         getReward(msg.sender);
//     }

//     function donate(uint256 _amount) external payable returns (bool) {
//         if (rewardToken != address(0)) {
//             IERC20(rewardToken).safeTransferFrom(
//                 msg.sender,
//                 address(this),
//                 _amount
//             );
//             queuedRewards = queuedRewards.add(_amount);
//         } else {
//             queuedRewards = queuedRewards.add(msg.value);
//         }
//     }

//     function queueNewRewards(uint256 _rewards) external {
//         require(msg.sender == operator, "!authorized");

//         _rewards = _rewards.add(queuedRewards);

//         if (block.timestamp >= periodFinish) {
//             notifyRewardAmount(_rewards);
//             queuedRewards = 0;
//             return;
//         }

//         //et = now - (finish-duration)
//         uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
//         //current at now: rewardRate * elapsedTime
//         uint256 currentAtNow = rewardRate * elapsedTime;
//         uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
//         if (queuedRatio < newRewardRatio) {
//             notifyRewardAmount(_rewards);
//             queuedRewards = 0;
//         } else {
//             queuedRewards = _rewards;
//         }
//     }

//     function notifyRewardAmount(uint256 _reward)
//         internal
//         updateReward(address(0))
//     {
//         historicalRewards = historicalRewards.add(_reward);

//         if (block.timestamp >= periodFinish) {
//             rewardRate = _reward.div(duration);
//         } else {
//             uint256 remaining = periodFinish.sub(block.timestamp);
//             uint256 leftover = remaining.mul(rewardRate);

//             _reward = _reward.add(leftover);
//             rewardRate = _reward.div(duration);
//         }

//         currentRewards = _reward;
//         lastUpdateTime = block.timestamp;
//         periodFinish = block.timestamp.add(duration);

//         emit RewardAdded(_reward);
//     }

//     function updateRewardState(address _user) public updateReward(address(0)) {
//         emit UpdateRewardState(_user);
//     }

//     receive() external payable {}
// }

contract CompoundRewardPool {
    using Address for address;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardToken;
    uint256 public constant duration = 10 minutes;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    address public operator;
    address public virtualBalance;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardDenied(address indexed user, uint256 reward);
    event UpdateRewardState(address indexed user);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).totalSupply();
    }

    function balanceOf(address _for) public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
    }

    constructor(
        address _reward,
        address _virtualBalance,
        address _op
    ) public {
        rewardToken = _reward;
        virtualBalance = _virtualBalance;
        operator = _op;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    /// The implementation is semantically analogous to getReward(), but uses a push pattern
    /// instead of pull pattern.
    function pushReward(address recipient) public updateReward(recipient) {
        uint256 reward = earned(recipient);
        if (reward > 0) {
            rewards[recipient] = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, then
            // make sure that it is not on our greyList.
            IERC20(rewardToken).safeTransfer(recipient, reward);

            emit RewardPaid(recipient, reward);
        }
    }

    function queueNewRewards(uint256 _rewards) external {
        notifyRewardAmount(_rewards);
    }

    function getReward(address _for) public updateReward(_for) {
        uint256 reward = earned(_for);
        if (reward > 0) {
            rewards[_for] = 0;

            if (rewardToken != address(0)) {
                IERC20(rewardToken).safeTransfer(_for, reward);
            } else {
                require(
                    address(this).balance >= reward,
                    "!address(this).balance"
                );

                payable(_for).transfer(reward);
            }

            // IERC20(rewardToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        public
        updateReward(address(0))
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(
            reward < uint256(-1) / 1e18,
            "the notified reward cannot invoke multiplication overflow"
        );

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    function updateRewardState(address _user) public {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
    }

    receive() external payable {}
}

contract CompoundPoolFactory {
    function CreateRewardPool(
        address rewardToken,
        address virtualBalance,
        address op
    ) public returns (address) {
        CompoundRewardPool pool = new CompoundRewardPool(
            rewardToken,
            virtualBalance,
            op
        );

        return address(pool);
    }

    function CreateTreasuryFundPool(address op) public returns (address) {
        CompoundTreasuryFund pool = new CompoundTreasuryFund(op);

        return address(pool);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface ICompound {
    function borrow(uint256 borrowAmount) external returns (uint256);
    // function interestRateModel() external returns (InterestRateModel);
    // function comptroller() external view returns (ComptrollerInterface);
    // function balanceOf(address owner) external view returns (uint256);
    function isCToken(address) external view returns(bool);
    function comptroller() external view returns (ICompoundComptroller);
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function getAccountSnapshot(address account) external view returns ( uint256, uint256, uint256, uint256 );
    function accrualBlockNumber() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function borrowBalanceStored(address user) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function decimals() external view returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint);
    function interestRateModel() external view returns (address);
}

interface ICompoundCEther is ICompound {
    function repayBorrow() external payable;
    function mint() external payable;
}

interface ICompoundCErc20 is ICompound {
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function underlying() external returns(address); // like usdc usdt
}

interface ICompRewardPool {
    function stakeFor(address _for, uint256 amount) external;
    function withdrawFor(address _for, uint256 amount) external;
    function queueNewRewards(uint256 _rewards) external;
    function rewardToken() external returns(address);
    function rewardConvexToken() external returns(address);

    function getReward(address _account, bool _claimExtras) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256);
}

interface ICompRewardFactory {
    function CreateRewards(address _operator) external returns (address);
}

interface ICompoundTreasuryFund {
    function withdrawTo( address _asset, uint256 _amount, address _to ) external;
    // function borrowTo( address _asset, address _underlyAsset, uint256 _borrowAmount, address _to, bool _isErc20 ) external returns (uint256);
    // function repayBorrow( address _asset, bool _isErc20, uint256 _amount ) external payable;
    function claimComp( address _comp, address _comptroller, address _to ) external returns (uint256, bool);
}

interface ICompoundTreasuryFundFactory {
    function CreateTreasuryFund(address _operator) external returns (address);
}

interface ICompoundComptroller {
    /*** Assets You Are In ***/
    // 开启抵押
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    // 关闭抵押
    function exitMarket(address cToken) external returns (uint256);
    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);

    function claimComp(address holder) external;
    function claimComp(address holder, address[] memory cTokens) external;
    function getCompAddress() external view returns (address);
    function getAllMarkets() external view returns (address[] memory);
    function accountAssets(address user) external view returns (address[] memory);
    function markets(address _cToken) external view returns(bool isListed, uint collateralFactorMantissa);
}

interface ICompoundProxyUserTemplate {
    function init( address _op, address _treasuryFund, bytes32 _lendingId, address _user, address _rewardComp ) external;
    function borrow( address _asset, address payable _for, uint256 _lendingAmount, uint256 _interestAmount ) external;
    function borrowErc20( address _asset, address _token, address _for, uint256 _lendingAmount, uint256 _interestAmount ) external;
    function repayBorrowBySelf(address _asset,address _underlyingToken) external payable returns(uint256);
    function repayBorrow(address _asset, address payable _for) external payable returns(uint256);
    function repayBorrowErc20( address _asset, address _token,address _for, uint256 _amount ) external returns(uint256);
    function op() external view returns (address);
    function asset() external view returns (address);
    function user() external view returns (address);
    function recycle(address _asset,address _underlyingToken) external;
    function borrowBalanceStored(address _asset) external view returns (uint256);
}

interface ICompoundInterestRateModel {
    function blocksPerYear() external view returns (uint256);
}

interface ICompoundPoolFactory {
    // function CreateCompoundRewardPool(address rewardToken,address virtualBalance, address op) external returns (address);
    function CreateRewardPool(address rewardToken, address virtualBalance,address op) external returns (address);
    function CreateTreasuryFundPool(address op) external returns (address);
}

interface ICompoundInterestRewardPool {
    function donate(uint256 _amount) external payable returns (bool);
    function queueNewRewards(uint256 _rewards) external;
    function updateRewardState(address _user) external;
}

interface IRewardPool {
    function earned(address _for) external view returns (uint256);
    function getReward(address _for) external;
    function balanceOf(address _for) external view returns (uint256);
/* function getReward(address _account) external returns (bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address _for) external view returns (uint256); */
}

interface ILendFlareGague {
    function user_checkpoint(address addr) external returns (bool);
}

interface ILendFlareMinter {
    function mint_for(address gauge_addr, address _for) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/SafeERC20.sol";
import "./libs/Clones.sol";
import "./compound/CompoundInterfaces.sol";
import "./common/IVirtualBalanceWrapper.sol";

contract CompoundBooster {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public compoundComptroller;
    address public compoundProxyUserTemplate;
    address public virtualBalanceWrapperFactory;
    address public compoundPoolFactory;
    address public rewardCompToken;
    address public lendflareVotingEscrow;
    address public lendflareMinter;

    address public Lending;

    struct PoolInfo {
        address lpToken;
        address rewardCompPool;
        address rewardVeLendFlarePool;
        address rewardInterestPool;
        address treasuryFund;
        address virtualBalance;
        address lendflareGauge;
        bool isErc20;
        bool shutdown;
    }

    enum LendingInfoState {
        NONE,
        LOCK,
        UNLOCK,
        LIQUIDATE
    }

    struct LendingInfo {
        uint256 pid;
        address payable proxyUser;
        uint256 cTokens;
        address underlyToken;
        uint256 amount;
        uint256 borrowNumbers;
        uint256 startedBlock;
        LendingInfoState state;
    }

    PoolInfo[] public poolInfo;

    mapping(uint256 => uint256) public frozenCTokens;
    mapping(bytes32 => LendingInfo) public lendingInfos;
    mapping(uint256 => uint256) public interestTotal;

    event Minted(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    event Borrow(
        address indexed user,
        uint256 indexed pid,
        bytes32 indexed lendingId,
        uint256 lendingAmount,
        uint256 collateralAmount,
        uint256 interestAmount,
        uint256 borrowNumbers
    );
    event RepayBorrow(
        bytes32 indexed lendingId,
        address indexed user,
        uint256 amount,
        uint256 interestValue,
        bool isErc20
    );
    event Liquidate(
        bytes32 indexed lendingId,
        uint256 lendingAmount,
        uint256 interestValue
    );

    modifier onlyLending() {
        _;
    }

    function init(
        address _virtualBalanceWrapperFactory,
        address _compoundPoolFactory,
        address _rewardCompToken,
        address _lendflareVotingEscrow,
        address _compoundProxyUserTemplate
    ) public {
        virtualBalanceWrapperFactory = _virtualBalanceWrapperFactory;
        compoundPoolFactory = _compoundPoolFactory;
        rewardCompToken = _rewardCompToken;
        lendflareVotingEscrow = _lendflareVotingEscrow;

        compoundProxyUserTemplate = _compoundProxyUserTemplate;
    }

    function addPool(address _lpToken, bool _isErc20) public returns (bool) {
        address virtualBalance = IVirtualBalanceWrapperFactory(
            virtualBalanceWrapperFactory
        ).CreateVirtualBalanceWrapper(address(this));

        address rewardCompPool = ICompoundPoolFactory(compoundPoolFactory)
            .CreateRewardPool(
                rewardCompToken,
                address(virtualBalance),
                address(this)
            );

        address rewardVeLendFlarePool;
        address rewardInterestPool;

        if (_isErc20) {
            address underlyToken = ICompoundCErc20(_lpToken).underlying();
            rewardInterestPool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(underlyToken, virtualBalance, address(this));

            rewardVeLendFlarePool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(
                    underlyToken,
                    lendflareVotingEscrow,
                    address(this)
                );
        } else {
            rewardInterestPool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(address(0), virtualBalance, address(this));

            rewardVeLendFlarePool = ICompoundPoolFactory(compoundPoolFactory)
                .CreateRewardPool(
                    address(0),
                    lendflareVotingEscrow,
                    address(this)
                );
        }

        address treasuryFundPool = ICompoundPoolFactory(compoundPoolFactory)
            .CreateTreasuryFundPool(address(this));

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardCompPool: rewardCompPool,
                rewardVeLendFlarePool: rewardVeLendFlarePool,
                rewardInterestPool: rewardInterestPool,
                treasuryFund: treasuryFundPool,
                virtualBalance: virtualBalance,
                lendflareGauge: address(0),
                isErc20: _isErc20,
                shutdown: false
            })
        );

        return true;
    }

    function _mintEther(address lpToken, uint256 _amount) internal {
        ICompoundCEther(lpToken).mint{value: _amount}();
    }

    function _mintErc20(address lpToken, uint256 _amount) internal {
        ICompoundCErc20(lpToken).mint(_amount);
    }

    /**
        @param _amount 质押金额,将转入treasuryFunds
        @param _isCToken 是否参与转化为cToken,如果开启，_amount 将为 erc20的转化金额
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _isCToken
    ) public payable returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        if (!_isCToken) {
            if (pool.isErc20) {
                require(_amount > 0);

                address underlyToken = ICompoundCErc20(pool.lpToken)
                    .underlying();

                IERC20(underlyToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amount
                );

                IERC20(underlyToken).safeApprove(pool.lpToken, 0);
                IERC20(underlyToken).safeApprove(pool.lpToken, _amount);

                _mintErc20(pool.lpToken, _amount);
            } else {
                require(msg.value > 0 && _amount == 0);

                _mintEther(pool.lpToken, msg.value);
            }
        } else {
            IERC20(pool.lpToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        uint256 mintToken = IERC20(pool.lpToken).balanceOf(address(this));

        require(mintToken > 0, "mintToken = 0");

        IERC20(pool.lpToken).safeTransfer(pool.treasuryFund, mintToken);

        ICompoundInterestRewardPool(pool.rewardCompPool).updateRewardState(
            msg.sender
        );
        ICompoundInterestRewardPool(pool.rewardInterestPool).updateRewardState(
            msg.sender
        );


        IVirtualBalanceWrapper(pool.virtualBalance).stakeFor(
            msg.sender,
            mintToken
        );

        if (pool.lendflareGauge != address(0)) {
            ILendFlareGague(pool.lendflareGauge).user_checkpoint(msg.sender);
        }

        emit Deposited(msg.sender, _pid, mintToken);

        return true;
    }

    function withdraw(uint256 _pid, uint256 _amount) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 depositAmount = IRewardPool(pool.rewardCompPool).balanceOf(
            msg.sender
        );

        require(
            IERC20(pool.lpToken).balanceOf(pool.treasuryFund) >= _amount,
            "!Insufficient balance"
        );
        require(_amount <= depositAmount, "!depositAmount");

        ICompoundTreasuryFund(pool.treasuryFund).withdrawTo(
            pool.lpToken,
            _amount,
            msg.sender
        );

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(
            msg.sender,
            _amount
        );

        ICompoundInterestRewardPool(pool.rewardCompPool).updateRewardState(
            msg.sender
        );
        ICompoundInterestRewardPool(pool.rewardInterestPool).updateRewardState(
            msg.sender
        );

        return true;
    }

    function claimComp() external returns (bool) {
        address compAddress = ICompoundComptroller(compoundComptroller)
            .getCompAddress();

        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].shutdown) {
                continue;
            }

            (uint256 rewards, bool claimed) = ICompoundTreasuryFund(
                poolInfo[i].treasuryFund
            ).claimComp(
                    compAddress,
                    compoundComptroller,
                    poolInfo[i].rewardCompPool
                );

            if (claimed) {
                ICompoundInterestRewardPool(poolInfo[i].rewardCompPool)
                    .queueNewRewards(rewards);
            }
        }

        return true;
    }

    function setCompoundComptroller(address _v) public {
        require(_v != address(0), "!_v");

        compoundComptroller = _v;
    }

    function setLendflareMinter(address _v) public {
        require(_v != address(0), "!_v");

        lendflareMinter = _v;
    }

    function setLendFlareGauge(uint256 _pid, address _v) public {
        PoolInfo storage pool = poolInfo[_pid];

        require(pool.lendflareGauge == address(0), "!lendflareGauge");

        pool.lendflareGauge = _v;
    }

    receive() external payable {}

    function getRewards(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];

        if (IRewardPool(pool.rewardCompPool).earned(msg.sender) > 0) {
            IRewardPool(pool.rewardCompPool).getReward(msg.sender);
        }

        if (IRewardPool(pool.rewardInterestPool).earned(msg.sender) > 0) {
            IRewardPool(pool.rewardInterestPool).getReward(msg.sender);
        }

        ILendFlareMinter(lendflareMinter).mint_for(
            pool.lendflareGauge,
            msg.sender
        );
    }

    // function getVeLFTUserRewards(uint256 _pid) public {
    //     PoolInfo memory pool = poolInfo[_pid];

    //     if (IRewardPool(pool.rewardVeLendFlarePool).earned(msg.sender) > 0) {
    //         IRewardPool(pool.rewardVeLendFlarePool).getReward(msg.sender);
    //     }
    // }

    function getVeLFTUserRewards() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            PoolInfo memory pool = poolInfo[pid];

            if (
                IRewardPool(pool.rewardVeLendFlarePool).earned(msg.sender) > 0
            ) {
                IRewardPool(pool.rewardVeLendFlarePool).getReward(msg.sender);
            }
        }
    }

    /* lending interfaces */
    function cloneUserTemplate(
        uint256 _pid,
        bytes32 _lendingId,
        address _treasuryFund,
        address _sender
    ) internal {
        LendingInfo memory lendingInfo = lendingInfos[_lendingId];

        if (lendingInfo.startedBlock == 0) {
            address payable template = payable(
                Clones.clone(compoundProxyUserTemplate)
            );

            ICompoundProxyUserTemplate(template).init(
                address(this),
                _treasuryFund,
                _lendingId,
                _sender,
                rewardCompToken
            );

            lendingInfos[_lendingId] = LendingInfo({
                pid: _pid,
                proxyUser: template,
                cTokens: 0,
                underlyToken: address(0),
                amount: 0,
                startedBlock: 0,
                borrowNumbers: 0,
                state: LendingInfoState.NONE
            });
        }
    }

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _collateralAmount,
        uint256 _interestValue,
        uint256 _borrowNumbers
    ) public {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 exchangeRateStored = ICompound(pool.lpToken)
            .exchangeRateStored();
        uint256 cTokens = _collateralAmount.mul(1e18).div(exchangeRateStored);

        require(
            IERC20(pool.lpToken).balanceOf(pool.treasuryFund) >= cTokens,
            "!Insufficient balance"
        );

        frozenCTokens[_pid] = frozenCTokens[_pid].add(cTokens);
        interestTotal[_pid] = interestTotal[_pid].add(_interestValue);

        cloneUserTemplate(_pid, _lendingId, pool.treasuryFund, _user);

        LendingInfo storage lendingInfo = lendingInfos[_lendingId];

        lendingInfo.cTokens = cTokens;
        lendingInfo.amount = _lendingAmount;
        lendingInfo.startedBlock = block.number;
        lendingInfo.borrowNumbers = _borrowNumbers;
        lendingInfo.state = LendingInfoState.LOCK;

        ICompoundTreasuryFund(pool.treasuryFund).withdrawTo(
            pool.lpToken,
            cTokens,
            lendingInfo.proxyUser
        );

        if (pool.isErc20) {
            address underlyToken = ICompoundCErc20(pool.lpToken).underlying();

            lendingInfo.underlyToken = underlyToken;

            ICompoundProxyUserTemplate(lendingInfo.proxyUser).borrowErc20(
                pool.lpToken,
                underlyToken,
                _user,
                _lendingAmount,
                _interestValue
            );

            uint256 bal = IERC20(lendingInfo.underlyToken).balanceOf(
                address(this)
            );

            if (bal > 0) {
                uint256 exchangeReward = bal.mul(50).div(100);
                uint256 lendflareDeposterReward = bal.sub(exchangeReward);

                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardInterestPool,
                    exchangeReward
                );
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardVeLendFlarePool,
                    lendflareDeposterReward
                );

                ICompoundInterestRewardPool(pool.rewardInterestPool)
                    .queueNewRewards(exchangeReward);

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(lendflareDeposterReward);
            }
        } else {
            lendingInfo.underlyToken = address(0);

            ICompoundProxyUserTemplate(lendingInfo.proxyUser).borrow(
                pool.lpToken,
                payable(_user),
                _lendingAmount,
                _interestValue
            );

            uint256 bal = address(this).balance;

            if (bal > 0) {
                uint256 exchangeReward = bal.mul(50).div(100);
                uint256 lendflareDeposterReward = bal.sub(exchangeReward);

                payable(pool.rewardInterestPool).transfer(exchangeReward);
                payable(pool.rewardVeLendFlarePool).transfer(
                    lendflareDeposterReward
                );
                ICompoundInterestRewardPool(pool.rewardInterestPool)
                    .queueNewRewards(exchangeReward);

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(lendflareDeposterReward);
            }
        }

        emit Borrow(
            _user,
            _pid,
            _lendingId,
            _lendingAmount,
            _collateralAmount,
            _interestValue,
            _borrowNumbers
        );
    }

    function _repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _interestValue,
        bool _isErc20
    ) internal {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];
        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        require(lendingInfo.state == LendingInfoState.LOCK, "!LOCK");

        frozenCTokens[lendingInfo.pid] = frozenCTokens[lendingInfo.pid].sub(
            lendingInfo.cTokens
        );
        interestTotal[lendingInfo.pid] = interestTotal[lendingInfo.pid].sub(
            _interestValue
        );

        if (_isErc20) {
            uint256 bal = ICompoundProxyUserTemplate(lendingInfo.proxyUser)
                .repayBorrowErc20(
                    pool.lpToken,
                    lendingInfo.underlyToken,
                    _user,
                    _amount
                );

            if (bal > 0) {
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardVeLendFlarePool,
                    bal
                );

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(bal);
            }
        } else {
            uint256 bal = ICompoundProxyUserTemplate(lendingInfo.proxyUser)
                .repayBorrow{value: _amount}(pool.lpToken, payable(_user));

            if (bal > 0) {
                payable(pool.rewardVeLendFlarePool).transfer(bal);

                ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                    .queueNewRewards(bal);
            }
        }

        // ICompoundProxyUserTemplate(lendingInfo.proxyUser).recycle(
        //     pool.lpToken,
        //     lendingInfo.underlyToken
        // );

        lendingInfo.state = LendingInfoState.UNLOCK;

        emit RepayBorrow(_lendingId, _user, _amount, _interestValue, _isErc20);
    }

    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _interestValue
    ) external payable {
        _repayBorrow(_lendingId, _user, msg.value, _interestValue, false);
    }

    function repayBorrowErc20(
        bytes32 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _interestValue
    ) external {
        _repayBorrow(_lendingId, _user, _amount, _interestValue, true);
    }

    function liquidate(
        bytes32 _lendingId,
        uint256 _lendingAmount,
        uint256 _interestValue
    ) public payable returns (address) {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];
        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        require(lendingInfo.state == LendingInfoState.LOCK, "!LOCK");

        frozenCTokens[lendingInfo.pid] = frozenCTokens[lendingInfo.pid].sub(
            lendingInfo.cTokens
        );
        interestTotal[lendingInfo.pid] = interestTotal[lendingInfo.pid].sub(
            _interestValue
        );

        uint256 bal = ICompoundProxyUserTemplate(lendingInfo.proxyUser)
            .repayBorrowBySelf{value: msg.value}(
            pool.lpToken,
            lendingInfo.underlyToken
        );

        if (bal > 0) {
            uint256 exchangeReward = bal.mul(50).div(100);
            uint256 lendflareDeposterReward = bal.sub(exchangeReward);

            if (pool.isErc20) {
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardInterestPool,
                    exchangeReward
                );
                IERC20(lendingInfo.underlyToken).safeTransfer(
                    pool.rewardVeLendFlarePool,
                    lendflareDeposterReward
                );
            } else {
                payable(pool.rewardInterestPool).transfer(exchangeReward);
                payable(pool.rewardVeLendFlarePool).transfer(
                    lendflareDeposterReward
                );
            }

            ICompoundInterestRewardPool(pool.rewardInterestPool)
                .queueNewRewards(exchangeReward);
            ICompoundInterestRewardPool(pool.rewardVeLendFlarePool)
                .queueNewRewards(lendflareDeposterReward);
        }

        lendingInfo.state = LendingInfoState.UNLOCK;

        emit Liquidate(_lendingId, _lendingAmount, _interestValue);
    }

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function totalSupplyOf(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        return IERC20(pool.lpToken).balanceOf(address(this));
    }

    function getUtilizationRate(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 currentBal = IERC20(pool.lpToken).balanceOf(pool.treasuryFund);

        if (currentBal == 0 || frozenCTokens[_pid] == 0) {
            return 0;
        }

        return
            frozenCTokens[_pid].mul(1e18).div(
                currentBal.add(frozenCTokens[_pid])
            );
    }

    function getBorrowRatePerBlock(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        return ICompound(pool.lpToken).borrowRatePerBlock();
    }

    function getExchangeRateStored(uint256 _pid)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];

        return ICompound(pool.lpToken).exchangeRateStored();
    }

    function getCollateralFactorMantissa(uint256 _pid)
        public
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];

        ICompoundComptroller comptroller = ICompound(pool.lpToken)
            .comptroller();
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            pool.lpToken
        );

        return isListed ? collateralFactorMantissa : 800000000000000000;
    }

    function getLendingInfos(bytes32 _lendingId)
        public
        view
        returns (address payable, address)
    {
        LendingInfo memory lendingInfo = lendingInfos[_lendingId];

        return (lendingInfo.proxyUser, lendingInfo.underlyToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt)
        internal
        returns (address instance)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address master,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/SafeERC20.sol";
import "./CompoundInterfaces.sol";

contract CompoundProxyUserTemplate {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public op;
    address public treasuryFund;
    address public compReward;
    address public user;
    bytes32 public lendingId;
    bool public claimComp = true;
    bool private inited;
    bool private borrowed;

    event Receive(uint256 amount);
    event Success(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 returnBorrow,
        uint256 timeAt
    );
    event Fail(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 returnBorrow,
        uint256 timeAt
    );
    event RepayBorrow(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );
    event RepayBorrowErc20(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );
    event Recycle(
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 timeAt
    );

    modifier onlyInited() {
        require(inited, "!inited");
        _;
    }

    modifier onlyOp() {
        require(msg.sender == op, "!op");
        _;
    }

    constructor() public {
        inited = true;
    }

    function init(
        address _op,
        address _treasuryFund,
        bytes32 _lendingId,
        address _user,
        address _compReward
    ) public {
        require(!inited, "inited");

        op = _op;
        treasuryFund = _treasuryFund;
        user = _user;
        lendingId = _lendingId;
        compReward = _compReward;
        inited = true;
    }

    function borrow(
        address _asset,
        address payable _for,
        uint256 _lendingAmount,
        uint256 _interestAmount
    ) public onlyInited onlyOp {
        require(borrowed == false, "!borrowed");
        borrowed = true;

        autoEnterMarkets(_asset);
        autoClaimComp(_asset);

        uint256 borrowState = ICompoundCEther(_asset).borrow(_lendingAmount);

        if (borrowState == 0) {
            emit Success(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );

            _for.transfer(_lendingAmount.sub(_interestAmount));

            if (_interestAmount > 0) {
                msg.sender.transfer(_interestAmount);
            }
        } else {
            emit Fail(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );
            uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }
    }

    function borrowErc20(
        address _asset,
        address _token,
        address _for,
        uint256 _lendingAmount,
        uint256 _interestAmount
    ) public onlyInited onlyOp {
        require(borrowed == false, "!borrowed");
        borrowed = true;

        autoEnterMarkets(_asset);
        autoClaimComp(_asset);

        uint256 borrowState = ICompoundCErc20(_asset).borrow(_lendingAmount);

        // 0 on success, otherwise an Error code
        if (borrowState == 0) {
            emit Success(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );

            uint256 bal = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(_for, bal.sub(_interestAmount));

            if (_interestAmount > 0) {
                IERC20(_token).safeTransfer(msg.sender, _interestAmount);
            }
        } else {
            emit Fail(
                _asset,
                _for,
                _lendingAmount,
                borrowState,
                block.timestamp
            );
            
            uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }
    }

    function repayBorrowBySelf(address _asset, address _underlyToken)
        public
        payable
        onlyInited
        onlyOp
        returns (uint256)
    {
        autoClaimComp(_asset);

        uint256 borrows = borrowBalanceCurrent(_asset);
        uint256 bal;

        if (_underlyToken != address(0)) {
            IERC20(_underlyToken).safeApprove(_asset, 0);
            IERC20(_underlyToken).safeApprove(_asset, borrows);

            ICompoundCErc20(_asset).repayBorrow(borrows);

            /* uint256 bal = IERC20(_underlyToken).balanceOf(address(this));

            IERC20(_underlyToken).safeTransfer(_liquidatePool, bal); */
            bal = IERC20(_underlyToken).balanceOf(address(this));

            if (bal > 0) {
                IERC20(_underlyToken).safeTransfer(op, bal);
            }
        } else {
            ICompoundCEther(_asset).repayBorrow{value: borrows}();

            bal = address(this).balance;

            if (bal > 0) {
                // payable(_liquidatePool).transfer(address(this).balance);
                payable(op).transfer(bal);
            }
        }

        uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

        if (cTokenBal > 0) {
            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }

        emit Recycle(_asset, user, cTokenBal, block.timestamp);

        return bal;
    }

    function repayBorrow(address _asset, address payable _for)
        public
        payable
        onlyInited
        onlyOp
        returns (uint256)
    {
        autoClaimComp(_asset);

        uint256 received = msg.value;
        uint256 borrows = borrowBalanceCurrent(_asset);

        if (received > borrows) {
            ICompoundCEther(_asset).repayBorrow{value: borrows}();
            // _for.transfer(received - borrows);
        } else {
            ICompoundCEther(_asset).repayBorrow{value: received}();
        }
        // ICompoundCEther(_asset).repayBorrow{value: received}();

        uint256 bal = address(this).balance;

        if (bal > 0) {
            payable(op).transfer(bal);
        }

        uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

        if (cTokenBal > 0) {
            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }

        emit RepayBorrow(_asset, _for, msg.value, block.timestamp);

        return bal;
    }

    function repayBorrowErc20(
        address _asset,
        address _underlyToken,
        address _for,
        uint256 _amount
    ) public onlyInited onlyOp returns (uint256) {
        uint256 received = _amount;
        uint256 borrows = borrowBalanceCurrent(_asset);

        // IERC20(_underlyToken).safeApprove(_asset, 0);
        // IERC20(_underlyToken).safeApprove(_asset, _amount);

        // ICompoundCErc20(_asset).repayBorrow(received);
        IERC20(_underlyToken).safeApprove(_asset, 0);
        IERC20(_underlyToken).safeApprove(_asset, _amount);

        if (received > borrows) {
            ICompoundCErc20(_asset).repayBorrow(borrows);
            // IERC20(_underlyToken).safeTransfer(_for, received - borrows);
        } else {
            ICompoundCErc20(_asset).repayBorrow(received);
        }

        uint256 bal = IERC20(_underlyToken).balanceOf(address(this));

        if (bal > 0) {
            IERC20(_underlyToken).safeTransfer(op, bal);
        }

        uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

        if (cTokenBal > 0) {
            IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
        }

        emit RepayBorrow(_asset, _for, _amount, block.timestamp);

        return bal;

        // if (received > borrows) {

        //     ICompoundCErc20(_asset).repayBorrow(borrows);
        //     IERC20(_token).safeTransfer(_for, received - borrows);
        // } else {
        //     ICompoundCErc20(_asset).repayBorrow(received);
        // }

        // emit RepayBorrowErc20(
        //     _asset,
        //     _for,
        //     received - borrows,
        //     block.timestamp
        // );
    }

    function recycle(address _asset, address _underlyToken)
        external
        onlyInited
        onlyOp
    {
        uint256 borrows = borrowBalanceCurrent(_asset);

        if (borrows == 0) {
            if (_underlyToken != address(0)) {
                uint256 surplusBal = IERC20(_underlyToken).balanceOf(
                    address(this)
                );

                if (surplusBal > 0) {
                    IERC20(_underlyToken).safeTransfer(user, surplusBal);
                }
            } else {
                if (address(this).balance > 0) {
                    payable(user).transfer(address(this).balance);
                }
            }

            uint256 cTokenBal = IERC20(_asset).balanceOf(address(this));

            if (cTokenBal > 0) {
                IERC20(_asset).safeTransfer(treasuryFund, cTokenBal);
            }

            emit Recycle(_asset, user, cTokenBal, block.timestamp);
        }
    }

    function autoEnterMarkets(address _asset) internal {
        ICompoundComptroller comptroller = ICompound(_asset).comptroller();

        if (!comptroller.checkMembership(user, _asset)) {
            address[] memory cTokens = new address[](1);

            cTokens[0] = _asset;

            comptroller.enterMarkets(cTokens);
        }
    }

    function autoClaimComp(address _asset) internal {
        if (claimComp) {
            ICompoundComptroller comptroller = ICompound(_asset).comptroller();
            comptroller.claimComp(user);
            address comp = comptroller.getCompAddress();
            uint256 bal = IERC20(comp).balanceOf(address(this));

            IERC20(comp).safeTransfer(compReward, bal);

            ICompoundInterestRewardPool(compReward).queueNewRewards(bal);
        }
    }

    receive() external payable {
        emit Receive(msg.value);
    }

    function borrowBalanceCurrent(address _asset) public returns (uint256) {
        return ICompound(_asset).borrowBalanceCurrent(address(this));
    }

    /* views */
    function borrowBalanceStored(address _asset) public view returns (uint256) {
        return ICompound(_asset).borrowBalanceStored(address(this));
    }

    function getAccountSnapshot(address _asset)
        external
        view
        returns (
            uint256 compoundError,
            uint256 cTokenBalance,
            uint256 borrowBalance,
            uint256 exchangeRateMantissa
        )
    {
        (
            compoundError,
            cTokenBalance,
            borrowBalance,
            exchangeRateMantissa
        ) = ICompound(_asset).getAccountSnapshot(user);
    }

    function getAccountCurrentBalance(address _asset)
        public
        view
        returns (uint256)
    {
        uint256 blocks = block.number.sub(
            ICompound(_asset).accrualBlockNumber()
        );
        uint256 rate = ICompound(_asset).borrowRatePerBlock();
        uint256 borrowBalance = ICompound(_asset).borrowBalanceStored(user);

        return borrowBalance.add(blocks.mul(rate).mul(1e18));
    }

    /* 
        1e18*1e18/297200311178743141766115305/1e8 = 33.64734027477437
        33.64734027477437*1e18*297200311178743141766115305/1e36 = 10000000000
     */
    function getTokenToCToken(address _asset, uint256 _token)
        public
        view
        returns (uint256)
    {
        uint256 exchangeRate = ICompound(_asset).exchangeRateStored();
        uint256 tokens = _token.mul(1e18).mul(exchangeRate).div(
            ICompound(_asset).decimals()
        );

        return tokens;
    }

    function getCTokenToToken(address _asset, uint256 _cToken)
        public
        view
        returns (uint256)
    {
        uint256 exchangeRate = ICompound(_asset).exchangeRateStored();
        uint256 tokens = _cToken
            .mul(ICompound(_asset).decimals())
            .mul(exchangeRate)
            .mul(1e18);

        return tokens;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../libs/Math.sol";
import "../libs/SafeMath.sol";
import "../libs/IERC20.sol";
import "../libs/SafeERC20.sol";

contract VirtualBalanceWrapper {
    using SafeMath for uint256;

    address public operator;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _operator) public {
        operator = _operator;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stakeFor(address _for, uint256 _amount) public returns (bool) {
        require(msg.sender == operator, "!authorized");
        require(_amount > 0, "VirtualBalanceWrapper : Cannot stake 0");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_for] = _balances[_for].add(_amount);

        return true;
    }

    function withdrawFor(address _for, uint256 amount) public returns (bool) {
        require(msg.sender == operator, "!authorized");
        require(amount > 0, "RewardPool : Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[_for] = _balances[_for].sub(amount);

        return true;
    }
}

contract VirtualBalanceWrapperFactory {
    function CreateVirtualBalanceWrapper(address op) public returns (address) {
        VirtualBalanceWrapper virtualBalanceWrapper = new VirtualBalanceWrapper(
            op
        );

        return address(virtualBalanceWrapper);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./Ownable.sol";

contract Operators is Ownable {
    event NewOperator(address indexed _sender, address indexed _newOperator);
    event OperatorRemoval(
        address indexed _sender,
        address indexed _removedOperator
    );

    mapping(address => bool) private _operatorRole;

    constructor() public {
        _addOperator(_msgSender());
    }

    function _addOperator(address newOperator) private {
        _operatorRole[newOperator] = true;
        emit NewOperator(_msgSender(), newOperator);
    }

    function addOperator(address newOperator) external onlyOwner {
        require(
            !_isOperator(newOperator),
            "Operators: Address is already operator."
        );
        _addOperator(newOperator);
    }

    function addOperators(address[] memory newOperators) external onlyOwner {
        for (uint256 i = 0; i < newOperators.length; i++) {
            require(
                !_isOperator(newOperators[i]),
                "Operators: Address is already operator."
            );
            _addOperator(newOperators[i]);
        }
    }

    function _removeOperator(address operator) private {
        _operatorRole[operator] = false;
        emit OperatorRemoval(_msgSender(), operator);
    }

    function removeOperator(address operator) external onlyOwner {
        require(_isOperator(operator), "Operators: Address is not operator.");
        _removeOperator(operator);
    }

    function _isOperator(address someAddress) private view returns (bool) {
        return _operatorRole[someAddress];
    }

    modifier onlyOperators() {
        require(
            _isOperator(_msgSender()),
            "Operators: caller is not an operator."
        );
        _;
    }

    function isOperator() external view returns (bool) {
        return _isOperator(_msgSender());
    }

    function isOperatorAddress(address someAddress)
        external
        view
        onlyOperators
        returns (bool)
    {
        return _isOperator(someAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../../libs/SafeERC20.sol";

interface IMockToken is IERC20 {
    function mint(uint256 value) external returns (bool);

    function mint(address _to, uint256 _amount) external;
}

contract MockCompoundComptroller {
    address public mockToken; // mainnet 0xc00e94Cb662C3520282E6f5717214004A7f26888

    constructor(address _mockToken) public {
        mockToken = _mockToken;
    }

    function setMockToken(address _v) public {
        mockToken = _v;
    }

    function claimComp(address holder) public {
        IMockToken(mockToken).mint(holder, 10 ether);
    }

    /* function claimComp(address holder, address[] memory cTokens) public {}

    function claimComp(
        address[] memory holders,
        address[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) public {} */

    function getCompAddress() public view returns (address) {
        return mockToken;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeERC20.sol";

contract LendFlareTokenLocker {
    using SafeERC20 for IERC20;

    address public token;
    uint256 public start_time;
    uint256 public end_time;

    mapping(address => uint256) public initial_locked;
    mapping(address => uint256) public total_claimed;
    mapping(address => uint256) public disabled_at;
    mapping(address => bool) public fund_admins;

    uint256 public initial_locked_supply;
    uint256 public unallocated_supply;

    bool public can_disable;
    bool public fund_admins_enabled;

    address public admin;
    address public future_admin;

    event Fund(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 amount);
    event ToggleDisable(address recipient, bool disabled);
    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);

    constructor(
        address _token,
        uint256 _start_time,
        uint256 _end_time,
        bool _can_disable,
        address[4] memory _fund_admins
    ) public {
        assert(_start_time >= block.timestamp);
        assert(_end_time > _start_time);

        token = _token;
        admin = msg.sender;
        start_time = _start_time;
        end_time = _end_time;
        can_disable = _can_disable;

        bool _fund_admins_enabled;

        for (uint256 i = 0; i < _fund_admins.length; i++) {
            if (_fund_admins[i] != address(0)) {
                fund_admins[_fund_admins[i]] = true;

                if (!_fund_admins_enabled) {
                    _fund_admins_enabled = true;
                    fund_admins_enabled = true;
                }
            }
        }
    }

    function add_tokens(uint256 _amount) public {
        require(msg.sender == admin, "dev: admin only");

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        unallocated_supply += _amount;
    }

    function fund(address[100] memory _recipients, uint256[100] memory _amounts)
        public
    {
        if (msg.sender != admin) {
            require(fund_admins[msg.sender], "dev: admin only");
            require(fund_admins_enabled, "dev: fund admins disabled");
        }

        uint256 _total_amount;

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 amount = _amounts[i];
            address recipient = _recipients[i];

            if (recipient == address(0)) {
                break;
            }

            _total_amount += amount;

            initial_locked[recipient] += amount;
            emit Fund(recipient, amount);
        }

        initial_locked_supply += _total_amount;
        unallocated_supply -= _total_amount;
    }

    function toggle_disable(address _recipient) public {
        require(msg.sender == admin, "dev: admin only");
        require(can_disable, "Cannot disable");

        bool is_disabled = disabled_at[_recipient] == 0;

        if (is_disabled) {
            disabled_at[_recipient] = block.timestamp;
        } else {
            disabled_at[_recipient] = 0;
        }

        emit ToggleDisable(_recipient, is_disabled);
    }

    function disable_can_disable() public {
        require(msg.sender == admin, "dev: admin only");
        can_disable = false;
    }

    function disable_fund_admins() public {
        require(msg.sender == admin, "dev: admin only");
        fund_admins_enabled = false;
    }

    function claim() public {
        address addr = msg.sender;

        uint256 t = disabled_at[addr];

        if (t == 0) {
            t = block.timestamp;
        }

        uint256 claimable = _total_vested_of(addr, t) - total_claimed[addr];

        total_claimed[addr] += claimable;

        IERC20(token).safeTransfer(addr, claimable);

        emit Claim(addr, claimable);
    }

    function commit_transfer_ownership(address addr) public returns (bool) {
        require(msg.sender == admin, "dev: admin only");
        future_admin = addr;

        emit CommitOwnership(addr);

        return true;
    }

    function apply_transfer_ownership() public returns (bool) {
        require(msg.sender == admin, "dev: admin only");

        address _admin = future_admin;

        require(future_admin != address(0), "dev: admin not set");

        admin = _admin;

        emit ApplyOwnership(_admin);

        return true;
    }

    function _total_vested_of(address _recipient, uint256 _time)
        internal
        view
        returns (uint256)
    {
        if (_time == 0) _time = block.timestamp;

        uint256 start = start_time;
        uint256 end = end_time;
        uint256 locked = initial_locked[_recipient];

        if (_time < start) {
            return 0;
        }

        return min((locked * (_time - start)) / (end - start), locked);
    }

    function _total_vested() internal view returns (uint256) {
        uint256 start = start_time;
        uint256 end = end_time;
        uint256 locked = initial_locked_supply;

        if (block.timestamp < start) {
            return 0;
        }

        return
            min((locked * (block.timestamp - start)) / (end - start), locked);
    }

    function vestedSupply() public view returns (uint256) {
        return _total_vested();
    }

    function lockedSupply() public view returns (uint256) {
        return initial_locked_supply - _total_vested();
    }

    function vestedOf(address _recipient) public view returns (uint256) {
        return _total_vested_of(_recipient, block.timestamp);
    }

    function balanceOf(address _recipient) public view returns (uint256) {
        return
            _total_vested_of(_recipient, block.timestamp) -
            total_claimed[_recipient];
    }

    function lockedOf(address _recipient) public view returns (uint256) {
        return
            initial_locked[_recipient] -
            _total_vested_of(_recipient, block.timestamp);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./libs/SafeERC20.sol";

interface IConvexBooster {
    function liquidate(
        uint256 _convexPid,
        int128 _curveCoinId,
        address _user,
        uint256 _amount
    ) external returns (address, uint256);

    function depositFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function withdrawFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function poolInfo(uint256 _convexPid)
        external
        view
        returns (
            uint256 originConvexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardPool,
            uint256 swapType,
            uint256 swapCoins
        );
}

interface ICompoundBooster {
    function liquidate(
        bytes32 _lendingId,
        uint256 _lendingAmount,
        uint256 _interestValue
    ) external payable returns (address);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            address rewardPool,
            address rewardLendflareTokenPool,
            address treasuryFund,
            address rewardInterestPool,
            bool isErc20,
            bool shutdown
        );

    function getLendingInfos(bytes32 _lendingId)
        external
        view
        returns (address payable, address);

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _collateralAmount,
        uint256 _interestValue,
        uint256 _borrowNumbers
    ) external;

    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _interestValue
    ) external payable;

    function repayBorrowErc20(
        bytes32 _lendingId,
        address _user,
        uint256 _amount,
        uint256 _interestValue
    ) external;

    function getBorrowRatePerBlock(uint256 _pid)
        external
        view
        returns (uint256);

    function getExchangeRateStored(uint256 _pid)
        external
        view
        returns (uint256);

    function getBlocksPerYears(uint256 _pid, bool isSplit)
        external
        view
        returns (uint256);

    function getUtilizationRate(uint256 _pid) external view returns (uint256);

    function getCollateralFactorMantissa(uint256 _pid)
        external
        view
        returns (uint256);
}

interface ICurveSwap {
    // function get_virtual_price() external view returns (uint256);

    // lp to token 68900637075889600000000, 2
    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 _tokenId)
        external
        view
        returns (uint256);

    // token to lp params: [0,0,70173920000], false
    /* function calc_token_amount(uint256[] memory amounts, bool deposit)
        external
        view
        returns (uint256); */
}

interface ILiquidateSponsor {
    function addSponsor(bytes32 _lendingId, address _user) external payable;

    function requestSponsor(bytes32 _lendingId) external;

    function payFee(
        bytes32 _lendingId,
        address _user,
        uint256 _expendGas
    ) external;
}

contract ConvexCompoundGauge {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public convexBooster;
    address public compoundBooster;
    address public liquidateSponsor;

    uint256 public liquidateThresholdBlockNumbers;

    enum UserLendingState {
        LENDING,
        EXPIRED,
        LIQUIDATED
    }

    struct PoolInfo {
        uint256 convexPid;
        uint256[] supportPids;
        int128[] curveCoinIds;
        uint256 lendingThreshold;
        uint256 liquidateThreshold;
        uint256 borrowIndex;
    }

    struct UserLending {
        bytes32 lendingId;
        uint256 token0;
        uint256 token0Price;
        uint256 lendingAmount;
        uint256 supportPid;
        int128 curveCoinId;
        uint256 interestTotalValue;
        uint256 interestLendFlareValue;
        uint256 borrowNumbers;
        uint256 borrowBlocksLimit;
    }

    struct LendingInfo {
        address user;
        uint256 pid;
        uint256 userLendingId;
        uint256 borrowIndex;
        uint256 startedBlock;
        uint256 utilizationRate;
        uint256 compoundRatePerBlock;
        UserLendingState state;
    }

    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 supplyAmount;
    }

    struct Statistic {
        uint256 totalCollateral;
        uint256 totalBorrow;
        uint256 recentRepayAt;
    }

    struct LendingParams {
        uint256 lendingAmount;
        uint256 collateralAmount;
        uint256 interestTotalValue;
        uint256 interestLendFlareValue;
        uint256 lendingRate;
        uint256 utilizationRate;
        uint256 compoundRatePerBlock;
        address lpToken;
        uint256 token0Price;
    }

    PoolInfo[] public poolInfo;

    // user address => container
    mapping(address => UserLending[]) public userLendings;
    // lending id => user address
    mapping(bytes32 => LendingInfo) public lendings;
    // pool id => (borrowIndex => user lendingId)
    mapping(uint256 => mapping(uint256 => bytes32)) public poolLending;
    mapping(bytes32 => BorrowInfo) public borrowInfos;
    mapping(bytes32 => Statistic) public myStatistics;
    // number => block numbers
    mapping(uint256 => uint256) public borrowNumberLimit;

    event Borrow(
        bytes32 indexed lendingId,
        address user,
        uint256 token0,
        uint256 token0Price,
        uint256 lendingAmount,
        uint256 borrowBlocksLimit,
        UserLendingState state
    );

    event RepayBorrow(
        bytes32 indexed lendingId,
        address user,
        UserLendingState state
    );

    event Liquidate(
        bytes32 indexed lendingId,
        address user,
        uint256 liquidateAmount,
        uint256 gasSpent,
        UserLendingState state
    );

    function init(
        address _liquidateSponsor,
        address _convexBooster,
        address _compoundBooster
    ) public {
        liquidateSponsor = _liquidateSponsor;
        convexBooster = _convexBooster;
        compoundBooster = _compoundBooster;

        borrowNumberLimit[4] = 16;
        borrowNumberLimit[6] = 64;
        borrowNumberLimit[19] = 524288;
        borrowNumberLimit[20] = 1048576;
        borrowNumberLimit[21] = 2097152;

        liquidateThresholdBlockNumbers = 20;
    }

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowNumber,
        uint256 _supportPid
    ) public payable {
        require(borrowNumberLimit[_borrowNumber] != 0, "!borrowNumberLimit");
        require(msg.value == 0.1 ether, "!liquidateSponsor");

        _borrow(_pid, _supportPid, _borrowNumber, _token0);
    }

    function _getCurveInfo(
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _token0
    ) internal view returns (address lpToken, uint256 token0Price) {
        address curveSwapAddress;
        (, curveSwapAddress, lpToken, , , , , , ) = IConvexBooster(
            convexBooster
        ).poolInfo(_convexPid);
        token0Price = ICurveSwap(curveSwapAddress).calc_withdraw_one_coin(
            _token0,
            _curveCoinId
        );
    }

    function _borrow(
        uint256 _pid,
        uint256 _supportPid,
        uint256 _borrowNumber,
        uint256 _token0
    ) internal returns (LendingParams memory) {
        PoolInfo storage pool = poolInfo[_pid];

        pool.borrowIndex++;

        bytes32 lendingId = generateId(
            msg.sender,
            _pid,
            pool.borrowIndex + block.number
        );

        LendingParams memory lendingParams = getLendingInfo(
            _token0,
            pool.convexPid,
            pool.curveCoinIds[_supportPid],
            pool.supportPids[_supportPid],
            pool.lendingThreshold,
            pool.liquidateThreshold,
            _borrowNumber
        );

        IERC20(lendingParams.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _token0
        );

        IERC20(lendingParams.lpToken).safeApprove(convexBooster, 0);
        IERC20(lendingParams.lpToken).safeApprove(convexBooster, _token0);

        ICompoundBooster(compoundBooster).borrow(
            pool.supportPids[_supportPid],
            lendingId,
            msg.sender,
            lendingParams.lendingAmount,
            lendingParams.collateralAmount,
            lendingParams.interestLendFlareValue,
            _borrowNumber
        );

        IConvexBooster(convexBooster).depositFor(
            pool.convexPid,
            _token0,
            msg.sender
        );

        BorrowInfo storage borrowInfo = borrowInfos[
            getEncodePacked(_pid, pool.supportPids[_supportPid], address(0))
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.add(
            lendingParams.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.add(
            lendingParams.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            getEncodePacked(_pid, pool.supportPids[_supportPid], msg.sender)
        ];

        statistic.totalCollateral = statistic.totalCollateral.add(_token0);
        statistic.totalBorrow = statistic.totalBorrow.add(
            lendingParams.lendingAmount
        );

        userLendings[msg.sender].push(
            UserLending({
                lendingId: lendingId,
                token0: _token0,
                token0Price: lendingParams.token0Price,
                lendingAmount: lendingParams.lendingAmount,
                supportPid: pool.supportPids[_supportPid],
                curveCoinId: pool.curveCoinIds[_supportPid],
                interestTotalValue: lendingParams.interestTotalValue,
                interestLendFlareValue: lendingParams.interestLendFlareValue,
                borrowNumbers: _borrowNumber,
                borrowBlocksLimit: borrowNumberLimit[_borrowNumber]
            })
        );

        lendings[lendingId] = LendingInfo({
            user: msg.sender,
            pid: _pid,
            borrowIndex: pool.borrowIndex,
            userLendingId: userLendings[msg.sender].length - 1,
            startedBlock: block.number,
            utilizationRate: lendingParams.utilizationRate,
            compoundRatePerBlock: lendingParams.compoundRatePerBlock,
            state: UserLendingState.LENDING
        });

        poolLending[_pid][pool.borrowIndex] = lendingId;

        ILiquidateSponsor(liquidateSponsor).addSponsor{value: msg.value}(
            lendingId,
            msg.sender
        );

        emit Borrow(
            lendingId,
            msg.sender,
            _token0,
            lendingParams.token0Price,
            lendingParams.lendingAmount,
            borrowNumberLimit[_borrowNumber],
            UserLendingState.LENDING
        );
    }

    function _repayBorrow(
        bytes32 _lendingId,
        uint256 _amount,
        bool isErc20
    ) internal {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "!startedBlock");

        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];
        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            block.number <=
                lendingInfo.startedBlock.add(userLending.borrowBlocksLimit),
            "Expired"
        );

        uint256 payAmount = userLending
            .lendingAmount
            .add(userLending.interestTotalValue)
            .sub(userLending.interestLendFlareValue);
        uint256 maxAmount = payAmount.add(payAmount.mul(5).div(1000));

        require(
            _amount >= payAmount && _amount <= maxAmount,
            "amount range error"
        );

        lendingInfo.state = UserLendingState.EXPIRED;

        IConvexBooster(convexBooster).withdrawFor(
            pool.convexPid,
            userLending.token0,
            lendingInfo.user
        );

        BorrowInfo storage borrowInfo = borrowInfos[
            getEncodePacked(lendingInfo.pid, userLending.supportPid, address(0))
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            getEncodePacked(
                lendingInfo.pid,
                userLending.supportPid,
                lendingInfo.user
            )
        ];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );
        statistic.recentRepayAt = block.timestamp;

        if (isErc20) {
            (
                address payable proxyUser,
                address underlyToken
            ) = ICompoundBooster(compoundBooster).getLendingInfos(
                    userLending.lendingId
                );

            IERC20(underlyToken).safeTransferFrom(
                msg.sender,
                proxyUser,
                _amount
            );

            ICompoundBooster(compoundBooster).repayBorrowErc20(
                userLending.lendingId,
                lendingInfo.user,
                _amount,
                userLending.interestLendFlareValue
            );
        } else {
            ICompoundBooster(compoundBooster).repayBorrow{value: _amount}(
                userLending.lendingId,
                lendingInfo.user,
                userLending.interestLendFlareValue
            );
        }

        ILiquidateSponsor(liquidateSponsor).requestSponsor(
            userLending.lendingId
        );

        emit RepayBorrow(
            userLending.lendingId,
            lendingInfo.user,
            lendingInfo.state
        );
    }

    function repayBorrow(bytes32 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, false);
    }

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) public {
        _repayBorrow(_lendingId, _amount, true);
    }

    function liquidate(bytes32 _lendingId) public {
        uint256 gasStart = gasleft();
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "!startedBlock");

        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            lendingInfo.startedBlock.add(userLending.borrowNumbers).sub(
                liquidateThresholdBlockNumbers
            ) < block.number,
            "!borrowNumbers"
        );

        PoolInfo memory pool = poolInfo[lendingInfo.pid];

        lendingInfo.state = UserLendingState.LIQUIDATED;

        BorrowInfo storage borrowInfo = borrowInfos[
            getEncodePacked(lendingInfo.pid, userLending.supportPid, address(0))
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            getEncodePacked(
                lendingInfo.pid,
                userLending.supportPid,
                lendingInfo.user
            )
        ];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );

        (address payable proxyUser, ) = ICompoundBooster(compoundBooster)
            .getLendingInfos(userLending.lendingId);

        (address underlyToken, uint256 liquidateAmount) = IConvexBooster(
            convexBooster
        ).liquidate(
                pool.convexPid,
                userLending.curveCoinId,
                lendingInfo.user,
                userLending.token0
            );

        if (underlyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            ICompoundBooster(compoundBooster).liquidate{value: liquidateAmount}(
                userLending.lendingId,
                userLending.lendingAmount,
                userLending.interestLendFlareValue
            );
        } else {
            IERC20(underlyToken).safeTransfer(proxyUser, liquidateAmount);

            ICompoundBooster(compoundBooster).liquidate(
                userLending.lendingId,
                userLending.lendingAmount,
                userLending.interestLendFlareValue
            );
        }

        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);

        ILiquidateSponsor(liquidateSponsor).payFee(
            userLending.lendingId,
            msg.sender,
            gasSpent
        );

        emit Liquidate(
            userLending.lendingId,
            lendingInfo.user,
            liquidateAmount,
            gasSpent,
            lendingInfo.state
        );
    }

    function setBorrowNumberLimit(uint256 _number, uint256 _blockNumbers)
        public
    {
        borrowNumberLimit[_number] = _blockNumbers;
    }

    receive() external payable {}

    function addPool(
        uint256 _convexPid,
        uint256[] memory _supportPids,
        int128[] memory _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) public {
        poolInfo.push(
            PoolInfo({
                convexPid: _convexPid,
                supportPids: _supportPids,
                curveCoinIds: _curveCoinIds,
                lendingThreshold: _lendingThreshold,
                liquidateThreshold: _liquidateThreshold,
                borrowIndex: 0
            })
        );
    }

    function setLiquidateThresholdBlockNumbers(uint256 _blockNumbers) public {
        liquidateThresholdBlockNumbers = _blockNumbers;
    }

    /* function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    } */

    function generateId(
        address x,
        uint256 y,
        uint256 z
    ) public pure returns (bytes32) {
        /* return toBytes16(uint256(keccak256(abi.encodePacked(x, y, z)))); */
        return keccak256(abi.encodePacked(x, y, z));
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function cursor(
        uint256 _pid,
        uint256 _offset,
        uint256 _size
    ) public view returns (bytes32[] memory, uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 size = _offset + _size > pool.borrowIndex
            ? pool.borrowIndex - _offset
            : _size;
        uint256 index;

        bytes32[] memory userLendingIds = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            bytes32 userLendingId = poolLending[_pid][_offset + i];

            userLendingIds[index] = userLendingId;
            index++;
        }

        return (userLendingIds, pool.borrowIndex);
    }

    function calculateRepayAmount(bytes32 _lendingId)
        public
        view
        returns (uint256)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        if (lendingInfo.state == UserLendingState.LIQUIDATED) return 0;

        return userLending.lendingAmount.add(userLending.interestTotalValue).sub(userLending.interestLendFlareValue);
    }

    function getPoolSupportPids(uint256 _pid)
        public
        view
        returns (uint256[] memory)
    {
        PoolInfo memory pool = poolInfo[_pid];

        return pool.supportPids;
    }

    function getCurveCoinId(uint256 _pid, uint256 _supportPid)
        public
        view
        returns (int128)
    {
        PoolInfo memory pool = poolInfo[_pid];

        return pool.curveCoinIds[_supportPid];
    }

    function getUserLendingState(bytes32 _lendingId)
        public
        view
        returns (UserLendingState)
    {
        LendingInfo memory lendingInfo = lendings[_lendingId];

        return lendingInfo.state;
    }

    /* function getLiquidateInfo(bytes32 _lendingId)
        public
        view
        returns (bool, uint256)
    {
        LendingInfo memory lendingInfo = lendings[_lendingId];
        UserLending memory userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingId
        ];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        uint256 liquidateBlockNumbers = lendingInfo
            .startedBlock
            .add(userLending.borrowNumbers)
            .sub(liquidateThresholdBlockNumbers);

        if (liquidateBlockNumbers < block.number)
            return (true, liquidateBlockNumbers);

        return (false, liquidateBlockNumbers);
    } */

    function getLendingInfo(
        uint256 _token0,
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _compoundPid,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold,
        uint256 _borrowBlocks
    ) public view returns (LendingParams memory) {
        (address lpToken, uint256 token0Price) = _getCurveInfo(
            _convexPid,
            _curveCoinId,
            _token0
        );

        uint256 collateralFactorMantissa = ICompoundBooster(compoundBooster)
            .getCollateralFactorMantissa(_compoundPid);
        uint256 utilizationRate = ICompoundBooster(compoundBooster)
            .getUtilizationRate(_compoundPid);
        uint256 compoundRatePerBlock = ICompoundBooster(compoundBooster)
            .getBorrowRatePerBlock(_compoundPid);
        uint256 compoundRate = getCompoundRate(
            compoundRatePerBlock,
            _borrowBlocks
        );
        uint256 lendingRate;

        if (utilizationRate > 0) {
            lendingRate = getLendingRate(
                compoundRate,
                getAmplificationFactor(utilizationRate)
            );
        } else {
            lendingRate = compoundRate.sub(1e18);
        }

        uint256 lendflareRate = lendingRate - (compoundRate.sub(1e18));
        uint256 lendingAmount = (token0Price *
            1e18 *
            (1000 - _lendingThreshold - _liquidateThreshold)) /
            (1e18 + lendingRate) /
            1000;

        uint256 collateralAmount = lendingAmount
            .mul(compoundRate)
            .mul(1000)
            .div(800)
            .div(collateralFactorMantissa);

        uint256 interestTotalValue = lendingAmount.mul(lendingRate).div(1e18);
        uint256 interestLendFlareValue = lendingAmount.mul(lendflareRate).div(
            1e18
        );

        return
            LendingParams({
                lendingAmount: lendingAmount,
                collateralAmount: collateralAmount,
                interestTotalValue: interestTotalValue,
                interestLendFlareValue: interestLendFlareValue,
                lendingRate: lendingRate,
                utilizationRate: utilizationRate,
                compoundRatePerBlock: compoundRatePerBlock,
                lpToken: lpToken,
                token0Price: token0Price
            });
    }

    function getUserLendingsLength(address _user)
        public
        view
        returns (uint256)
    {
        return userLendings[_user].length;
    }

    function getCompoundRate(uint256 _compoundBlockRate, uint256 n)
        public
        pure
        returns (uint256)
    {
        _compoundBlockRate = _compoundBlockRate + (10**18);

        for (uint256 i = 1; i <= n; i++) {
            _compoundBlockRate = (_compoundBlockRate**2) / (10**18);
        }

        return _compoundBlockRate;
    }

    function getAmplificationFactor(uint256 _utilizationRate)
        public
        pure
        returns (uint256)
    {
        if (_utilizationRate <= 0.9 * 1e18) {
            return uint256(10).mul(_utilizationRate).div(9).add(1e18);
        }

        return uint256(20).mul(_utilizationRate).sub(16 * 1e18);
    }

    function getLendingRate(uint256 _compoundRate, uint256 _amplificationFactor)
        public
        pure
        returns (uint256)
    {
        return _compoundRate.sub(1e18).mul(_amplificationFactor).div(1e18);
    }

    function getEncodePacked(
        uint256 _pid,
        uint256 _supportPid,
        address _sender
    ) public pure returns (bytes32) {
        if (_sender == address(0)) {
            return generateId(_sender, _pid, _supportPid);
        }

        return generateId(_sender, _pid, _supportPid);
    }
}