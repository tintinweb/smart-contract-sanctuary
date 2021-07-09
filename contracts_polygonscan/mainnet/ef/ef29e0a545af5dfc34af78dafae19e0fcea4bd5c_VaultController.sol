/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
contract ReentrancyGuard {
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

interface IStrategy {
    event Deposit(address token, uint256 amount);
    event Withdraw(address token, uint256 amount, address to);
    event Harvest(uint256 priceShareBefore, uint256 priceShareAfter, address compoundToken, uint256 compoundBalance, address profitToken, uint256 reserveFundAmount);

    function baseToken() external view returns (address);

    function deposit() external;

    function withdraw(address _asset) external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function withdrawToController(uint256 _amount) external;

    function skim() external;

    function harvest(address _mergedStrategy) external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function beforeDeposit() external;
}

interface IVault {
    function cap() external view returns (uint256);

    function getVaultMaster() external view returns (address);

    function balance() external view returns (uint256);

    function token() external view returns (address);

    function available() external view returns (uint256);

    function accept(address _input) external view returns (bool);

    function openHarvest() external view returns (bool);

    function earn() external;

    function harvest(address reserve, uint256 amount) external;

    function addNewCompound(uint256, uint256) external;

    function withdraw_fee(uint256 _shares) external view returns (uint256);

    function calc_token_amount_deposit(uint256 _amount) external view returns (uint256);

    function calc_token_amount_withdraw(uint256 _shares) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256 _amount, uint256 _min_mint_amount) external returns (uint256);

    function depositFor(
        address _to,
        uint256 _amount,
        uint256 _min_mint_amount
    ) external returns (uint256 _mint_amount);

    function withdraw(uint256 _shares, uint256 _min_output_amount) external returns (uint256);

    function withdrawFor(
        address _account,
        uint256 _shares,
        uint256 _min_output_amount
    ) external returns (uint256 _output_amount);

    function harvestStrategy(address _strategy) external;

    function harvestAllStrategies() external;
}

interface IController {
    function vault() external view returns (IVault);

    function getStrategyCount() external view returns (uint256);

    function strategies(uint256 _stratId)
        external
        view
        returns (
            address _strategy,
            uint256 _quota,
            uint256 _percent
        );

    function getBestStrategy() external view returns (address _strategy);

    function want() external view returns (address);

    function balanceOf() external view returns (uint256);

    function withdraw_fee(uint256 _amount) external view returns (uint256); // eg. 3CRV => pJar: 0.5% (50/10000)

    function investDisabled() external view returns (bool);

    function withdraw(uint256) external returns (uint256 _withdrawFee);

    function earn(address _token, uint256 _amount) external;

    function harvestStrategy(address _strategy) external;

    function harvestAllStrategies() external;

    function beforeDeposit() external;

    function withdrawFee(uint256) external view returns (uint256); // pJar: 0.5% (50/10000)
}

contract VaultController is IController, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public strategist;
    address public timelock = address(0xe59511c0eF42FB3C419Ac2651406b7b8822328E1);

    struct StrategyInfo {
        address strategy;
        uint256 quota; // set = 0 to disable
        uint256 percent;
    }

    IVault public override vault;
    string public name = "VaultController";

    address public override want;
    uint256 public strategyLength;

    // stratId => StrategyInfo
    mapping(uint256 => StrategyInfo) public override strategies;

    mapping(address => bool) public approvedStrategies;

    bool public override investDisabled;

    address public lazySelectedBestStrategy; // we pre-set the best strategy to avoid gas cost of iterating the array
    uint256 public lastHarvestAllTimeStamp;

    uint256 public withdrawalFee = 0; // over 10000
    bool internal _initialized = false;

    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);
    event LogNewWithdrawalFee(uint256 withdrawalFee);
    event LogNewGovernance(address governance);
    event LogNewStrategist(address strategist);
    event LogNewTimelock(address timelock);

    function initialize(IVault _vault, string memory _name) public {
        require(_initialized == false, "Strategy: Initialize must be false.");
        require(address(_vault) != address(0), "!_vault");
        vault = _vault;
        want = vault.token();
        governance = msg.sender;
        strategist = msg.sender;
        name = _name;
        timelock = address(0xe59511c0eF42FB3C419Ac2651406b7b8822328E1);
        _initialized = true;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "!timelock");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!authorized");
        _;
    }

    function setVault(IVault _vault) external onlyTimelock {
        require(address(_vault) != address(0), "!_vault");
        vault = _vault;
        want = vault.token();
    }

    function setName(string memory _name) external onlyGovernance {
        name = _name;
    }

    function setTimelock(address _timelock) external onlyTimelock {
        timelock = _timelock;
        emit LogNewTimelock(timelock);
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit LogNewGovernance(governance);
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
        emit LogNewStrategist(strategist);
    }

    function approveStrategy(address _strategy) external onlyGovernance {
        approvedStrategies[_strategy] = true;
    }

    function revokeStrategy(address _strategy) external onlyGovernance {
        approvedStrategies[_strategy] = false;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
        require(_withdrawalFee <= 100, "withdrawalFee over 1%");
        withdrawalFee = _withdrawalFee;
        emit LogNewWithdrawalFee(withdrawalFee);
    }

    function setStrategyLength(uint256 _length) external onlyStrategist {
        strategyLength = _length;
    }

    // stratId => StrategyInfo
    function setStrategyInfo(
        uint256 _sid,
        address _strategy,
        uint256 _quota,
        uint256 _percent
    ) external onlyStrategist {
        require(approvedStrategies[_strategy], "!approved");
        strategies[_sid].strategy = _strategy;
        strategies[_sid].quota = _quota;
        strategies[_sid].percent = _percent;
    }

    function setInvestDisabled(bool _investDisabled) external onlyStrategist {
        investDisabled = _investDisabled;
    }

    function setLazySelectedBestStrategy(address _strategy) external onlyStrategist {
        require(approvedStrategies[_strategy], "!approved");
        require(IStrategy(_strategy).baseToken() == want, "!want");
        lazySelectedBestStrategy = _strategy;
    }

    function getStrategyCount() external view override returns (uint256 _strategyCount) {
        _strategyCount = strategyLength;
    }

    function getBestStrategy() public view override returns (address _strategy) {
        if (lazySelectedBestStrategy != address(0)) {
            return lazySelectedBestStrategy;
        }
        _strategy = address(0);
        if (strategyLength == 0) return _strategy;
        if (strategyLength == 1) return strategies[0].strategy;
        uint256 _totalBal = balanceOf();
        if (_totalBal == 0) return strategies[0].strategy; // first depositor, simply return the first strategy
        uint256 _bestDiff = 201;
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            StrategyInfo storage sinfo = strategies[_sid];
            uint256 _stratBal = IStrategy(sinfo.strategy).balanceOf();
            if (_stratBal < sinfo.quota) {
                uint256 _diff = _stratBal.add(_totalBal).mul(100).div(_totalBal).sub(sinfo.percent); // [100, 200] - [percent]
                if (_diff < _bestDiff) {
                    _bestDiff = _diff;
                    _strategy = sinfo.strategy;
                }
            }
        }
        if (_strategy == address(0)) {
            _strategy = strategies[0].strategy;
        }
    }

    function beforeDeposit() external override onlyAuthorized {
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            IStrategy(strategies[_sid].strategy).beforeDeposit();
        }
    }

    function earn(address _token, uint256 _amount) external override onlyAuthorized {
        address _strategy = getBestStrategy();
        if (_strategy == address(0) || IStrategy(_strategy).baseToken() != _token) {
            // forward to vault and then call earnExtra() by its governance
            IERC20(_token).safeTransfer(address(vault), _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
            IStrategy(_strategy).deposit();
        }
    }

    function withdraw_fee(uint256 _amount) external view override returns (uint256) {
        address _strategy = getBestStrategy();
        return (_strategy == address(0)) ? 0 : withdrawFee(_amount);
    }

    function balanceOf() public view override returns (uint256 _totalBal) {
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            _totalBal = _totalBal.add(IStrategy(strategies[_sid].strategy).balanceOf());
        }
    }

    function withdrawAll(address _strategy) external onlyStrategist {
        // WithdrawAll sends 'want' to 'vault'
        IStrategy(_strategy).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyStrategist {
        IERC20(_token).safeTransfer(address(vault), _amount);
    }

    function inCaseStrategyGetStuck(address _strategy, address _token) external onlyStrategist {
        IStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(address(vault), IERC20(_token).balanceOf(address(this)));
    }

    // note that some strategies do not allow controller to harvest
    function harvestStrategy(address _strategy) external override onlyAuthorized {
        IStrategy(_strategy).harvest(address(0));
    }

    function harvestAllStrategies() external override onlyAuthorized nonReentrant {
        address _bestStrategy = getBestStrategy(); // to send all harvested WETH and proceed the profit sharing all-in-one here
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            address _strategy = strategies[_sid].strategy;
            if (_strategy != _bestStrategy) {
                IStrategy(_strategy).harvest(_bestStrategy);
            }
        }
        if (_bestStrategy != address(0)) {
            IStrategy(_bestStrategy).harvest(address(0));
        }
        lastHarvestAllTimeStamp = block.timestamp;
    }

    function switchFund(
        IStrategy _srcStrat,
        IStrategy _destStrat,
        uint256 _amount
    ) external onlyTimelock {
        require(approvedStrategies[address(_destStrat)], "!approved");
        require(_srcStrat.baseToken() == want, "!_srcStrat.baseToken");
        require(_destStrat.baseToken() == want, "!_destStrat.baseToken");
        _srcStrat.withdrawToController(_amount);
        IERC20(want).safeTransfer(address(_destStrat), IERC20(want).balanceOf(address(this)));
        _destStrat.deposit();
    }

    function withdrawFee(uint256 _amount) public view override returns (uint256) {
        return _amount.mul(withdrawalFee).div(10000);
    }

    function withdraw(uint256 _amount) external override onlyAuthorized returns (uint256 _withdrawFee) {
        _withdrawFee = 0;
        uint256 _toWithdraw = _amount;
        for (uint256 _sid = 0; _sid < strategyLength; _sid++) {
            IStrategy _strategy = IStrategy(strategies[_sid].strategy);
            uint256 _stratBal = _strategy.balanceOf();
            if (_toWithdraw < _stratBal) {
                _strategy.withdraw(_toWithdraw);
                _withdrawFee = _withdrawFee.add(withdrawFee(_toWithdraw));
                return _withdrawFee;
            }
            _strategy.withdrawAll();
            _withdrawFee = _withdrawFee.add(withdrawFee(_stratBal));
            if (_stratBal == _toWithdraw) {
                return _withdrawFee;
            }
            _toWithdraw = _toWithdraw.sub(_stratBal);
        }
        return _withdrawFee;
    }

    /**
     * @dev This is from Timelock contract, the governance should be a Timelock contract before calling this emergency function
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyTimelock returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string(abi.encodePacked(name, "::executeTransaction: Transaction execution reverted.")));

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}

contract VaultControllerCreator {
    event NewController(address controller);

    function create() external returns (address) {
        VaultController controller = new VaultController();
        emit NewController(address(controller));

        return address(controller);
    }
}