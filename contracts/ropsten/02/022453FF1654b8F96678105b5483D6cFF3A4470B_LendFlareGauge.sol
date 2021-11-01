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

    uint256[100000000000000000000000000000] public period_timestamp;
    uint256[100000000000000000000000000000] public integrate_inv_supply;

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