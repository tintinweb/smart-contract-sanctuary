// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

interface IMultiVaultStrategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address _asset) external;
    function withdraw(uint _amount) external returns (uint);
    function withdrawToController(uint _amount) external;
    function skim() external;
    function harvest(address _mergedStrategy) external;
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
    function withdrawFee(uint) external view returns (uint); // pJar: 0.5% (50/10000)
}

interface IValueMultiVault {
    function cap() external view returns (uint);
    function getConverter(address _want) external view returns (address);
    function getVaultMaster() external view returns (address);
    function balance() external view returns (uint);
    function token() external view returns (address);
    function available(address _want) external view returns (uint);
    function accept(address _input) external view returns (bool);

    function claimInsurance() external;
    function earn(address _want) external;
    function harvest(address reserve, uint amount) external;

    function withdraw_fee(uint _shares) external view returns (uint);
    function calc_token_amount_deposit(uint[] calldata _amounts) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function convert_rate(address _input, uint _amount) external view returns (uint);
    function getPricePerFullShare() external view returns (uint);
    function get_virtual_price() external view returns (uint); // average dollar value of vault share token

    function deposit(address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function depositFor(address _account, address _to, address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function depositAll(uint[] calldata _amounts, uint _min_mint_amount) external returns (uint _mint_amount);
    function depositAllFor(address _account, address _to, uint[] calldata _amounts, uint _min_mint_amount) external returns (uint _mint_amount);
    function withdraw(uint _shares, address _output, uint _min_output_amount) external returns (uint);
    function withdrawFor(address _account, uint _shares, address _output, uint _min_output_amount) external returns (uint _output_amount);

    function harvestStrategy(address _strategy) external;
    function harvestWant(address _want) external;
    function harvestAllStrategies() external;
}

interface IShareConverter {
    function convert_shares_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);

    function convert_shares(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
}

interface Converter {
    function convert(address) external returns (uint);
}

contract MultiStablesVaultController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    address public governance;
    address public strategist;

    struct StrategyInfo {
        address strategy;
        uint quota; // set = 0 to disable
        uint percent;
    }

    IValueMultiVault public vault;

    address public basedWant;
    address[] public wantTokens; // sorted by preference

    // want => quota, length
    mapping(address => uint) public wantQuota;
    mapping(address => uint) public wantStrategyLength;

    // want => stratId => StrategyInfo
    mapping(address => mapping(uint => StrategyInfo)) public strategies;

    mapping(address => mapping(address => bool)) public approvedStrategies;

    mapping(address => bool) public investDisabled;
    IShareConverter public shareConverter; // converter for shares (3CRV <-> BCrv, etc ...)
    address public lazySelectedBestStrategy; // we pre-set the best strategy to avoid gas cost of iterating the array

    constructor(IValueMultiVault _vault) public {
        require(address(_vault) != address(0), "!_vault");
        vault = _vault;
        basedWant = vault.token();
        governance = msg.sender;
        strategist = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function approveStrategy(address _want, address _strategy) external {
        require(msg.sender == governance, "!governance");
        approvedStrategies[_want][_strategy] = true;
    }

    function revokeStrategy(address _want, address _strategy) external {
        require(msg.sender == governance, "!governance");
        approvedStrategies[_want][_strategy] = false;
    }

    function setWantQuota(address _want, uint _quota) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        wantQuota[_want] = _quota;
    }

    function setWantStrategyLength(address _want, uint _length) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        wantStrategyLength[_want] = _length;
    }

    // want => stratId => StrategyInfo
    function setStrategyInfo(address _want, uint _sid, address _strategy, uint _quota, uint _percent) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(approvedStrategies[_want][_strategy], "!approved");
        strategies[_want][_sid].strategy = _strategy;
        strategies[_want][_sid].quota = _quota;
        strategies[_want][_sid].percent = _percent;
    }

    function setShareConverter(IShareConverter _shareConverter) external {
        require(msg.sender == governance, "!governance");
        shareConverter = _shareConverter;
    }

    function setInvestDisabled(address _want, bool _investDisabled) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        investDisabled[_want] = _investDisabled;
    }

    function setWantTokens(address[] memory _wantTokens) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        delete wantTokens;
        uint _wlength = _wantTokens.length;
        for (uint i = 0; i < _wlength; ++i) {
            wantTokens.push(_wantTokens[i]);
        }
    }

    function getStrategyCount() external view returns(uint _strategyCount) {
        _strategyCount = 0;
        uint _wlength = wantTokens.length;
        for (uint i = 0; i < _wlength; i++) {
            _strategyCount = _strategyCount.add(wantStrategyLength[wantTokens[i]]);
        }
    }

    function wantLength() external view returns (uint) {
        return wantTokens.length;
    }

    function wantStrategyBalance(address _want) public view returns (uint) {
        uint _bal = 0;
        for (uint _sid = 0; _sid < wantStrategyLength[_want]; _sid++) {
            _bal = _bal.add(IMultiVaultStrategy(strategies[_want][_sid].strategy).balanceOf());
        }
        return _bal;
    }

    function want() external view returns (address) {
        if (lazySelectedBestStrategy != address(0)) {
            return IMultiVaultStrategy(lazySelectedBestStrategy).want();
        }
        uint _wlength = wantTokens.length;
        if (_wlength > 0) {
            if (_wlength == 1) {
                return wantTokens[0];
            }
            for (uint i = 0; i < _wlength; i++) {
                address _want = wantTokens[i];
                uint _bal = wantStrategyBalance(_want);
                if (_bal < wantQuota[_want]) {
                    return _want;
                }
            }
        }
        return basedWant;
    }

    function setLazySelectedBestStrategy(address _strategy) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        lazySelectedBestStrategy = _strategy;
    }

    function getBestStrategy(address _want) public view returns (address _strategy) {
        if (lazySelectedBestStrategy != address(0) && IMultiVaultStrategy(lazySelectedBestStrategy).want() == _want) {
            return lazySelectedBestStrategy;
        }
        uint _wantStrategyLength = wantStrategyLength[_want];
        _strategy = address(0);
        if (_wantStrategyLength == 0) return _strategy;
        uint _totalBal = wantStrategyBalance(_want);
        if (_totalBal == 0) {
            // first depositor, simply return the first strategy
            return strategies[_want][0].strategy;
        }
        uint _bestDiff = 201;
        for (uint _sid = 0; _sid < _wantStrategyLength; _sid++) {
            StrategyInfo storage sinfo = strategies[_want][_sid];
            uint _stratBal = IMultiVaultStrategy(sinfo.strategy).balanceOf();
            if (_stratBal < sinfo.quota) {
                uint _diff = _stratBal.add(_totalBal).mul(100).div(_totalBal).sub(sinfo.percent); // [100, 200] - [percent]
                if (_diff < _bestDiff) {
                    _bestDiff = _diff;
                    _strategy = sinfo.strategy;
                }
            }
        }
        if (_strategy == address(0)) {
            _strategy = strategies[_want][0].strategy;
        }
    }

    function earn(address _token, uint _amount) external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist");
        address _strategy = getBestStrategy(_token);
        if (_strategy == address(0) || IMultiVaultStrategy(_strategy).want() != _token) {
            // forward to vault and then call earnExtra() by its governance
            IERC20(_token).safeTransfer(address(vault), _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
            IMultiVaultStrategy(_strategy).deposit();
        }
    }

    function withdraw_fee(address _want, uint _amount) external view returns (uint) {
        address _strategy = getBestStrategy(_want);
        return (_strategy == address(0)) ? 0 : IMultiVaultStrategy(_strategy).withdrawFee(_amount);
    }

    function balanceOf(address _want, bool _sell) external view returns (uint _totalBal) {
        uint _wlength = wantTokens.length;
        if (_wlength == 0) {
            return 0;
        }
        _totalBal = 0;
        for (uint i = 0; i < _wlength; i++) {
            address wt = wantTokens[i];
            uint _bal = wantStrategyBalance(wt);
            if (wt != _want) {
                _bal = shareConverter.convert_shares_rate(wt, _want, _bal);
                if (_sell) {
                    _bal = _bal.mul(9998).div(10000); // minus 0.02% for selling
                }
            }
            _totalBal = _totalBal.add(_bal);
        }
    }

    function withdrawAll(address _strategy) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        // WithdrawAll sends 'want' to 'vault'
        IMultiVaultStrategy(_strategy).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint _amount) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        IERC20(_token).safeTransfer(address(vault), _amount);
    }

    function inCaseStrategyGetStuck(address _strategy, address _token) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        IMultiVaultStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(address(vault), IERC20(_token).balanceOf(address(this)));
    }

    function claimInsurance() external {
        require(msg.sender == governance, "!governance");
        vault.claimInsurance();
    }

    // note that some strategies do not allow controller to harvest
    function harvestStrategy(address _strategy) external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist && !vault");
        IMultiVaultStrategy(_strategy).harvest(address(0));
    }

    function harvestWant(address _want) external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist && !vault");
        uint _wantStrategyLength = wantStrategyLength[_want];
        address _firstStrategy = address(0); // to send all harvested WETH and proceed the profit sharing all-in-one here
        for (uint _sid = 0; _sid < _wantStrategyLength; _sid++) {
            StrategyInfo storage sinfo = strategies[_want][_sid];
            if (_firstStrategy == address(0)) {
                _firstStrategy = sinfo.strategy;
            } else {
                IMultiVaultStrategy(sinfo.strategy).harvest(_firstStrategy);
            }
        }
        if (_firstStrategy != address(0)) {
            IMultiVaultStrategy(_firstStrategy).harvest(address(0));
        }
    }

    function harvestAllStrategies() external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist && !vault");
        uint _wlength = wantTokens.length;
        address _firstStrategy = address(0); // to send all harvested WETH and proceed the profit sharing all-in-one here
        for (uint i = 0; i < _wlength; i++) {
            address _want = wantTokens[i];
            uint _wantStrategyLength = wantStrategyLength[_want];
            for (uint _sid = 0; _sid < _wantStrategyLength; _sid++) {
                StrategyInfo storage sinfo = strategies[_want][_sid];
                if (_firstStrategy == address(0)) {
                    _firstStrategy = sinfo.strategy;
                } else {
                    IMultiVaultStrategy(sinfo.strategy).harvest(_firstStrategy);
                }
            }
        }
        if (_firstStrategy != address(0)) {
            IMultiVaultStrategy(_firstStrategy).harvest(address(0));
        }
    }

    function switchFund(IMultiVaultStrategy _srcStrat, IMultiVaultStrategy _destStrat, uint _amount) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        _srcStrat.withdrawToController(_amount);
        address _srcWant = _srcStrat.want();
        address _destWant = _destStrat.want();
        if (_srcWant != _destWant) {
            _amount = IERC20(_srcWant).balanceOf(address(this));
            require(shareConverter.convert_shares_rate(_srcWant, _destWant, _amount) > 0, "rate=0");
            IERC20(_srcWant).safeTransfer(address(shareConverter), _amount);
            shareConverter.convert_shares(_srcWant, _destWant, _amount);
        }
        IERC20(_destWant).safeTransfer(address(_destStrat), IERC20(_destWant).balanceOf(address(this)));
        _destStrat.deposit();
    }

    function withdraw(address _want, uint _amount) external returns (uint _withdrawFee) {
        require(msg.sender == address(vault), "!vault");
        _withdrawFee = 0;
        uint _toWithdraw = _amount;
        uint _wantStrategyLength = wantStrategyLength[_want];
        uint _received;
        for (uint _sid = _wantStrategyLength; _sid > 0; _sid--) {
            StrategyInfo storage sinfo = strategies[_want][_sid - 1];
            IMultiVaultStrategy _strategy = IMultiVaultStrategy(sinfo.strategy);
            uint _stratBal = _strategy.balanceOf();
            if (_toWithdraw < _stratBal) {
                _received = _strategy.withdraw(_toWithdraw);
                _withdrawFee = _withdrawFee.add(_strategy.withdrawFee(_received));
                return _withdrawFee;
            }
            _received = _strategy.withdrawAll();
            _withdrawFee = _withdrawFee.add(_strategy.withdrawFee(_received));
            if (_received >= _toWithdraw) {
                return _withdrawFee;
            }
            _toWithdraw = _toWithdraw.sub(_received);
        }
        if (_toWithdraw > 0) {
            // still not enough, try to withdraw from other wants strategies
            uint _wlength = wantTokens.length;
            for (uint i = _wlength; i > 0; i--) {
                address wt = wantTokens[i - 1];
                if (wt != _want) {
                    (uint _wamt, uint _wdfee) = _withdrawOtherWant(_want, wt, _toWithdraw);
                    _withdrawFee = _withdrawFee.add(_wdfee);
                    if (_wamt >= _toWithdraw) {
                        return _withdrawFee;
                    }
                    _toWithdraw = _toWithdraw.sub(_wamt);
                }
            }
        }
        return _withdrawFee;
    }

    function _withdrawOtherWant(address _want, address _other, uint _amount) internal returns (uint _wantAmount, uint _withdrawFee) {
        // Check balance
        uint b = IERC20(_want).balanceOf(address(this));
        _withdrawFee = 0;
        if (b >= _amount) {
            _wantAmount = b;
        } else {
            uint _toWithdraw = _amount.sub(b);
            uint _toWithdrawOther = _toWithdraw.mul(101).div(100); // add 1% extra
            uint _otherBal = IERC20(_other).balanceOf(address(this));
            if (_otherBal < _toWithdrawOther) {
                uint _otherStrategyLength = wantStrategyLength[_other];
                for (uint _sid = _otherStrategyLength; _sid > 0; _sid--) {
                    StrategyInfo storage sinfo = strategies[_other][_sid - 1];
                    IMultiVaultStrategy _strategy = IMultiVaultStrategy(sinfo.strategy);
                    uint _stratBal = _strategy.balanceOf();
                    uint _needed = _toWithdrawOther.sub(_otherBal);
                    uint _wdamt = (_needed < _stratBal) ? _needed : _stratBal;
                    _strategy.withdrawToController(_wdamt);
                    _withdrawFee = _withdrawFee.add(_strategy.withdrawFee(_wdamt));
                    _otherBal = IERC20(_other).balanceOf(address(this));
                    if (_otherBal >= _toWithdrawOther) {
                        break;
                    }
                }
            }
            IERC20(_other).safeTransfer(address(shareConverter), _otherBal);
            shareConverter.convert_shares(_other, _want, _otherBal);
            _wantAmount = IERC20(_want).balanceOf(address(this));
        }
        IERC20(_want).safeTransfer(address(vault), _wantAmount);
    }
}