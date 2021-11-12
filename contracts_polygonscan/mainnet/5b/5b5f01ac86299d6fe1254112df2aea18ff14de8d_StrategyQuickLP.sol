/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

/*
$$\      $$\  $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\  $$\   $$\  $$$$$$\  $$\      $$\  $$$$$$\  $$$$$$$\  
$$$\    $$$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$$\  $$ |$$  __$$\ $$ | $\  $$ |$$  __$$\ $$  __$$\ 
$$$$\  $$$$ |$$ /  $$ |$$ /  \__|$$ /  $$ |$$ |  $$ |$$ /  $$ |$$$$\ $$ |$$ /  \__|$$ |$$$\ $$ |$$ /  $$ |$$ |  $$ |
$$\$$\$$ $$ |$$$$$$$$ |$$ |      $$$$$$$$ |$$$$$$$  |$$ |  $$ |$$ $$\$$ |\$$$$$$\  $$ $$ $$\$$ |$$$$$$$$ |$$$$$$$  |
$$ \$$$  $$ |$$  __$$ |$$ |      $$  __$$ |$$  __$$< $$ |  $$ |$$ \$$$$ | \____$$\ $$$$  _$$$$ |$$  __$$ |$$  ____/ 
$$ |\$  /$$ |$$ |  $$ |$$ |  $$\ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |\$$$ |$$\   $$ |$$$  / \$$$ |$$ |  $$ |$$ |      
$$ | \_/ $$ |$$ |  $$ |\$$$$$$  |$$ |  $$ |$$ |  $$ | $$$$$$  |$$ | \$$ |\$$$$$$  |$$  /   \$$ |$$ |  $$ |$$ |      
\__|     \__|\__|  \__| \______/ \__|  \__|\__|  \__| \______/ \__|  \__| \______/ \__/     \__|\__|  \__|\__|      
*/

// SPDX-License-Identifier: GPL-3.0-or-later

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

interface IStrategy {
    event Deposit(address token, uint256 amount);
    event Withdraw(address token, uint256 amount, address to);

    function qlpToken() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdraw(address _asset) external returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function withdrawToController(uint256 _amount) external;

    function skim() external;
    function skimCLP() external;
    function skimRewards() external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);
}

interface IMagicBox {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from ,uint256 _amount) external;
    function transferOwnership(address newOwner) external;
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
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
abstract contract StrategyBase is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public override qlpToken;
    address public rewardToken;
    address public macaronMasterChef;  // Macaron MasterChef
    address public magicBoxToken;
    address public governance;
    address public timelock = address(0xE4e9DA65f2d2B03d269d3a96ac906e4ace9464a5);

    mapping(address => mapping(address => address[])) public pancakeswapPaths; // [input -> output] => uniswap_path

    bool internal _initialized = false;

    function initialize(
        address _qlpToken,
        address _rewardToken,
        address _macaronMasterChef,
        address _magicBoxToken
    ) internal {
        qlpToken = _qlpToken;
        rewardToken = _rewardToken;
        governance = msg.sender;
        macaronMasterChef = _macaronMasterChef;
        magicBoxToken = _magicBoxToken;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }
    
    modifier onlyController() {
        require(msg.sender == macaronMasterChef, "!macaronMasterChef");
        _;
    }
    
    modifier onlyAuth() {
        require(msg.sender == macaronMasterChef || msg.sender == governance, "!auth");
        _;
    }

    function getName() public pure virtual returns (string memory);

    function approveForSpender(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyGovernance {
        _token.safeApprove(_spender, _amount);
    }

    function deposit(uint256 _amount) external virtual override onlyAuth {}

    // This method use only migration
    function skim() external override onlyGovernance {
        IERC20(qlpToken).safeTransfer(governance, IERC20(qlpToken).balanceOf(address(this)));
        IERC20(rewardToken).safeTransfer(governance, IERC20(rewardToken).balanceOf(address(this)));
    }
    
    // This method use only migration
    function skimCLP() external override onlyGovernance {
        IERC20(qlpToken).safeTransfer(governance, IERC20(qlpToken).balanceOf(address(this)));
    }
    
    // This method use only migration
    function skimRewards() external override onlyGovernance {
        IERC20(rewardToken).safeTransfer(governance, IERC20(rewardToken).balanceOf(address(this)));
    }

    // Withdraw rewards and other tokens to govarnance
    function withdraw(address _asset) external override onlyGovernance returns (uint256 balance) {
        require(qlpToken != _asset, "lpPair");
        require(macaronMasterChef != address(0), "!macaronMasterChef");

        balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(macaronMasterChef, balance);
        emit Withdraw(_asset, balance, macaronMasterChef);
    }

    // Withdraw CLP amount to macaronMasterChef
    function withdrawToController(uint256 _amount) external override onlyAuth {
        require(macaronMasterChef != address(0), "!macaronMasterChef"); // additional protection so we don't burn the funds

        uint256 _balance = IERC20(qlpToken).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _unstakeSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(qlpToken).safeTransfer(macaronMasterChef, _amount);
        IMagicBox(magicBoxToken).burn(address(this), _amount);
        emit Withdraw(qlpToken, _amount, macaronMasterChef);
    }

    function _unstakeSome(uint256 _amount) internal virtual returns (uint256);

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external override onlyGovernance returns (uint256) {
        require(macaronMasterChef != address(0), "!macaronMasterChef");

        uint256 _balance = IERC20(qlpToken).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _unstakeSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(qlpToken).safeTransfer(address(macaronMasterChef), _amount);
        emit Withdraw(qlpToken, _amount, address(macaronMasterChef));
        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external override onlyGovernance returns (uint256 balance) {
        require(macaronMasterChef != address(0), "!macaronMasterChef");

        _unstakeAll();
        balance = IERC20(qlpToken).balanceOf(address(this));
        IERC20(qlpToken).safeTransfer(address(macaronMasterChef), balance);
        emit Withdraw(qlpToken, balance, address(macaronMasterChef));
    }

    function _unstakeAll() internal virtual;

    function claimReward() external virtual;

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() external view override returns (uint256) {
        return IERC20(qlpToken).balanceOf(address(this)).add(balanceOfPool());
    }

    function getTargetFarm() external view virtual returns (address);

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "_governance can't be 0x");
        governance = _governance;
    }
    
    function setController(address _macaronMasterChef) external onlyGovernance {
        require(_macaronMasterChef != address(0), "_macaronMasterChef can't be 0x");
        macaronMasterChef = _macaronMasterChef;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        require(_timelock != address(0), "_timelock can't be 0x");
        timelock = _timelock;
    }

    function setrewardToken(address _rewardToken) external onlyGovernance {
        require(_rewardToken != address(0), "_rewardToken can't be 0x");
        rewardToken = _rewardToken;
    }

    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    /**
     * @dev This is from Timelock contract.
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) external returns (bytes memory) {
        require(msg.sender == timelock, "!timelock");
        require(target != address(0), "target can't be 0x");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string(abi.encodePacked(getName(), "::executeTransaction: Transaction execution reverted.")));

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
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
contract StrategyQuickLP is StrategyBase {
    
    address public quickFarmChef;

    // qlpToken       =  (QUICK LP)
    // rewardToken =  (QUICK)
    function initialize(
        address _qlpToken,
        address _rewardToken,
        address _quickFarmChef,
        address _macaronMasterChef,
        address _magicBoxToken
    ) external {
        require(_initialized == false, "Strategy: Initialize must be false.");
        initialize(_qlpToken, _rewardToken, _macaronMasterChef, _magicBoxToken);

        require(_quickFarmChef != address(0), "_quickFarmChef can't be 0x");
        quickFarmChef = _quickFarmChef;

        IERC20(qlpToken).safeApprove(address(quickFarmChef), type(uint256).max);
        IERC20(qlpToken).safeApprove(address(_macaronMasterChef), type(uint256).max);
        IERC20(magicBoxToken).safeApprove(address(_macaronMasterChef), type(uint256).max);
        
        _initialized = true;
    }

    function getName() public pure override returns (string memory) {
        return "MacaronStrategyPancakeCLP";
    }

    function deposit(uint256 _amount) external override onlyAuth {
        uint256 _baseBal = IERC20(qlpToken).balanceOf(address(this));

        require(_baseBal >= _amount, 'Strategy: amount did not deposit');

        if (_baseBal > 0) {
            // stake Lp tokens on pcake
            _stakeCakeLP();
            // distribute rewards
            _rewardDistribution();
            // mint proof token for Lp tokes (this is necessary for MasterChef can withdraw Lp.)
            IMagicBox(magicBoxToken).mint(msg.sender, _amount);
        }
    }

    function _stakeCakeLP() internal {
        uint256 _baseBal = IERC20(qlpToken).balanceOf(address(this));
        IStakingRewards(quickFarmChef).stake(_baseBal);
        emit Deposit(qlpToken, _baseBal);
    }

    function _unstakeSome(uint256 _amount) internal override returns (uint256) {
        uint256 _stakedAmount = IStakingRewards(quickFarmChef).balanceOf(address(this));
        if (_amount > _stakedAmount) {
            _amount = _stakedAmount;
        }

        IStakingRewards(quickFarmChef).withdraw(_amount);
        IStakingRewards(quickFarmChef).getReward();
        _rewardDistribution();
    
        return _amount;
    }

    function _unstakeAll() internal override {
        IStakingRewards(quickFarmChef).exit();
        
        _rewardDistribution();
    }
    
    function _rewardDistribution() internal {
        uint256 _rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardBalance > 0) {
            //Send rewards to govarnance
            IERC20(rewardToken).safeTransfer(address(governance), _rewardBalance);
        }
    }

    function claimReward() external override onlyAuth {
        IStakingRewards(quickFarmChef).getReward();
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IStakingRewards(quickFarmChef).balanceOf(address(this));
        return amount;
    }

    function balanceOfPoolPending() external view returns (uint256) {
        return IStakingRewards(quickFarmChef).earned(address(this));
    }

    function getTargetFarm() external view override returns (address) {
        return quickFarmChef;
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external onlyGovernance {
        IStakingRewards(quickFarmChef).exit();

        uint256 baseBal = IERC20(qlpToken).balanceOf(address(this));
        IERC20(qlpToken).transfer(address(governance), baseBal);
    }

    function setQuickFarmChefContract(address _quickFarmChef) external onlyGovernance {
        require(_quickFarmChef != address(0), "_quickFarmChef can't be 0x");
        quickFarmChef = _quickFarmChef;
    }
    
    // For migrating
    function transferMagicBoxOwnership(address newOwner) external onlyGovernance {
        require(newOwner != address(0), "owner can't be 0x");
        IMagicBox(magicBoxToken).transferOwnership(newOwner);
    }
}