/**
 *Submitted for verification at Etherscan.io on 2020-11-28
*/

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

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {cs := extcodesize(self)}
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

interface IVaultMaster {
    function bank(address) view external returns (address);
    function isVault(address) view external returns (bool);
    function isController(address) view external returns (bool);
    function isStrategy(address) view external returns (bool);

    function slippage(address) view external returns (uint);
    function convertSlippage(address _input, address _output) view external returns (uint);

    function valueToken() view external returns (address);
    function govVault() view external returns (address);
    function insuranceFund() view external returns (address);
    function performanceReward() view external returns (address);

    function govVaultProfitShareFee() view external returns (uint);
    function gasFee() view external returns (uint);
    function insuranceFee() view external returns (uint);

    function withdrawalProtectionFee() view external returns (uint);
}

interface ICompositeVault {
    function cap() external view returns (uint);
    function getConverter() external view returns (address);
    function getVaultMaster() external view returns (address);
    function balance() external view returns (uint);
    function tvl() external view returns (uint); // total dollar value
    function token() external view returns (address);
    function available() external view returns (uint);
    function accept(address _input) external view returns (bool);

    function earn() external;
    function harvest(address reserve, uint amount) external;
    function addNewCompound(uint, uint) external;

    function withdraw_fee(uint _shares) external view returns (uint);
    function calc_token_amount_deposit(address _input, uint _amount) external view returns (uint);
    function calc_add_liquidity(uint _amount0, uint _amount1) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function calc_remove_liquidity(uint _shares) external view returns (uint _amount0, uint _amount1);

    function getPricePerFullShare() external view returns (uint);
    function get_virtual_price() external view returns (uint); // average dollar value of vault share token

    function deposit(address _input, uint _amount, uint _min_mint_amount) external returns (uint);
    function depositFor(address _account, address _to, address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function addLiquidity(uint _amount0, uint _amount1, uint _min_mint_amount) external returns (uint);
    function addLiquidityFor(address _account, address _to, uint _amount0, uint _amount1, uint _min_mint_amount) external returns (uint _mint_amount);
    function withdraw(uint _shares, address _output, uint _min_output_amount) external returns (uint);
    function withdrawFor(address _account, uint _shares, address _output, uint _min_output_amount) external returns (uint _output_amount);

    function harvestStrategy(address _strategy) external;
    function harvestAllStrategies() external;
}

interface ILpPairConverter {
    function lpPair() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function accept(address _input) external view returns (bool);
    function get_virtual_price() external view returns (uint);

    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function calc_add_liquidity(uint _amount0, uint _amount1) external view returns (uint);
    function calc_remove_liquidity(uint _shares) external view returns (uint _amount0, uint _amount1);

    function convert(address _input, address _output, address _to) external returns (uint _outputAmount);
    function add_liquidity(address _to) external returns (uint _outputAmount);
    function remove_liquidity(address _to) external returns (uint _amount0, uint _amount1);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint value) external returns (uint freed);
}

contract CompositeVaultBank is ContextUpgradeSafe {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI(uint8 _flag) {
        if ((_flag & 0x1) == 0) {
            _;
        } else {
            uint gasStart = gasleft();
            _;
            uint gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        }
    }

    address public governance;
    address public strategist; // who can call harvestXXX() and update reward rate

    IVaultMaster public vaultMaster;

    struct UserInfo {
        uint amount;
        uint rewardDebt;
        uint accumulatedEarned; // will accumulate every time user harvest
        uint lastStakeTime;
        uint unclaimedReward;
    }

    struct RewardPoolInfo {
        IERC20 rewardToken;     // Address of rewardPool token contract.
        uint lastRewardBlock;   // Last block number that rewardPool distribution occurs.
        uint endRewardBlock;    // Block number which rewardPool distribution ends.
        uint rewardPerBlock;    // Reward token amount to distribute per block.
        uint rewardLockedTime;  // Time to lock reward (in seconds).
        uint accRewardPerShare; // Accumulated rewardPool per share, times 1e18.
        uint totalPaidRewards;  // for stat only
    }

    mapping(address => RewardPoolInfo) public rewardPoolInfo; // vault address => reward info
    mapping(address => mapping(address => UserInfo)) public userInfo; // vault address => account => userInfo

    bool public acceptContractDepositor = false;
    mapping(address => bool) public whitelistedContract;

    event Deposit(address indexed vault, address indexed user, uint amount);
    event Withdraw(address indexed vault, address indexed user, uint amount);
    event RewardPaid(address indexed vault, address indexed user, uint reward);

    function initialize(IVaultMaster _vaultMaster) public initializer {
        vaultMaster = _vaultMaster;
        governance = msg.sender;
        strategist = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /**
     * @dev Throws if called by a not-whitelisted contract while we do not accept contract depositor.
     */
    modifier checkContract() {
        if (!acceptContractDepositor && !whitelistedContract[msg.sender]) {
            require(!address(msg.sender).isContract() && msg.sender == tx.origin, "contract not support");
        }
        _;
    }

    function setAcceptContractDepositor(bool _acceptContractDepositor) external onlyGovernance {
        acceptContractDepositor = _acceptContractDepositor;
    }

    function whitelistContract(address _contract) external onlyGovernance {
        whitelistedContract[_contract] = true;
    }

    function unwhitelistContract(address _contract) external onlyGovernance {
        whitelistedContract[_contract] = false;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function setVaultMaster(IVaultMaster _vaultMaster) external onlyGovernance {
        vaultMaster = _vaultMaster;
    }

    function addPool(address _vault, IERC20 _rewardToken, uint _startBlock, uint _endRewardBlock, uint _rewardPerBlock, uint _rewardLockedTime) external onlyGovernance {
        _startBlock = (block.number > _startBlock) ? block.number : _startBlock;
        require(_startBlock <= _endRewardBlock, "sVB>eVB");
        rewardPoolInfo[_vault].rewardToken = _rewardToken;
        rewardPoolInfo[_vault].lastRewardBlock = _startBlock;
        rewardPoolInfo[_vault].endRewardBlock = _endRewardBlock;
        rewardPoolInfo[_vault].rewardPerBlock = _rewardPerBlock;
        rewardPoolInfo[_vault].rewardLockedTime = _rewardLockedTime;
        rewardPoolInfo[_vault].accRewardPerShare = 0;
        rewardPoolInfo[_vault].totalPaidRewards = 0;
    }

    function updatePool(address _vault, uint _endRewardBlock, uint _rewardPerBlock, uint _rewardLockedTime) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        updateReward(_vault);
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        require(block.number <= rewardPool.endRewardBlock, "late");
        rewardPool.endRewardBlock = _endRewardBlock;
        rewardPool.rewardPerBlock = _rewardPerBlock;
        rewardPool.rewardLockedTime = _rewardLockedTime;
    }

    function updatePoolReward(address[] calldata _vaults, uint[] calldata _rewardPerBlocks) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        uint leng = _vaults.length;
        uint currTotalRwd = 0;
        uint updatedTotalRwd = 0;
        for (uint i = 0; i < leng; i++) {
            address _vault = _vaults[i];
            RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
            if (block.number < rewardPool.endRewardBlock) {
                updateReward(_vault);
                currTotalRwd = currTotalRwd.add(rewardPool.rewardPerBlock);
                updatedTotalRwd = updatedTotalRwd.add(_rewardPerBlocks[i]);
                rewardPool.rewardPerBlock = _rewardPerBlocks[i];
            }
        }
        require(currTotalRwd <= updatedTotalRwd.mul(4), "over increased");
        require(currTotalRwd.mul(4) >= updatedTotalRwd, "over decreased");
    }

    function updateReward(address _vault) public {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        uint _endRewardBlockApplicable = block.number > rewardPool.endRewardBlock ? rewardPool.endRewardBlock : block.number;
        if (_endRewardBlockApplicable > rewardPool.lastRewardBlock) {
            uint lpSupply = IERC20(address(_vault)).balanceOf(address(this));
            if (lpSupply > 0) {
                uint _numBlocks = _endRewardBlockApplicable.sub(rewardPool.lastRewardBlock);
                uint _incRewardPerShare = _numBlocks.mul(rewardPool.rewardPerBlock).mul(1e18).div(lpSupply);
                rewardPool.accRewardPerShare = rewardPool.accRewardPerShare.add(_incRewardPerShare);
            }
            rewardPool.lastRewardBlock = _endRewardBlockApplicable;
        }
    }

    function cap(ICompositeVault _vault) external view returns (uint) {
        return _vault.cap();
    }

    function approveForSpender(IERC20 _token, address _spender, uint _amount) external onlyGovernance {
        require(!vaultMaster.isVault(address(_token)), "vaultToken");
        _token.safeApprove(_spender, _amount);
    }

    function calculateMultiMinReceive(ICompositeVault[] calldata _vaults, address _input, uint[] calldata _amounts) external view returns (uint[] memory minReceives) {
        require(_vaults.length == _amounts.length, "Invalid input length data");
        uint leng = _vaults.length;
        minReceives = new uint[](leng);
        for (uint i = 0; i < leng; i++) {
            ICompositeVault vault = _vaults[i];
            minReceives[i] = ILpPairConverter(vault.getConverter()).convert_rate(_input, vault.token(), _amounts[i]);
        }
    }

    function depositMultiVault(ICompositeVault[] calldata _vaults, address _input, uint[] calldata _amounts, uint[] calldata _min_mint_amounts, bool _isStake, uint8 _flag) public discountCHI(_flag) {
        uint leng = _vaults.length;
        for (uint i = 0; i < leng; i++) {
            deposit(_vaults[i], _input, _amounts[i], _min_mint_amounts[i], _isStake, uint8(0));
        }
    }

    function deposit(ICompositeVault _vault, address _input, uint _amount, uint _min_mint_amount, bool _isStake, uint8 _flag) public discountCHI(_flag) checkContract {
        require(_vault.accept(_input), "vault does not accept this asset");
        require(_amount > 0, "!_amount");

        IERC20(_input).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_input).safeIncreaseAllowance(address(_vault), _amount);

        address _token = _vault.token();
        uint _mint_amount;
        if (_token == _input || (_flag & 0x10) > 0) { // bit #1 is to enable donate dust
            _mint_amount = _vault.deposit(_input, _amount, _min_mint_amount);
        } else {
            ILpPairConverter _cnvrt = ILpPairConverter(_vault.getConverter());
            IERC20 _token0 = IERC20(_cnvrt.token0());
            IERC20 _token1 = IERC20(_cnvrt.token1());
            uint _before0 = _token0.balanceOf(address(this));
            uint _before1 = _token1.balanceOf(address(this));
            _mint_amount = _vault.deposit(_input, _amount, _min_mint_amount);
            uint _after0 = _token0.balanceOf(address(this));
            uint _after1 = _token1.balanceOf(address(this));
            if (_after0 > _before0) {
                _token0.safeTransfer(msg.sender, _after0.sub(_before0));
            }
            if (_after1 > _before1) {
                _token1.safeTransfer(msg.sender, _after1.sub(_before1));
            }
        }
        if (!_isStake) {
            IERC20(address(_vault)).safeTransfer(msg.sender, _mint_amount);
        } else {
            _stakeVaultShares(address(_vault), _mint_amount);
        }
    }

    function transferVault(ICompositeVault _srcVault, ICompositeVault _destVault, uint _srcShares, uint _min_mint_amount, bool _isStake, uint8 _flag) public discountCHI(_flag) checkContract {
        address _srcVaultToken = _srcVault.token();
        require(_destVault.accept(_srcVaultToken), "_destVault does not accept _srcVault asset");
        require(_srcShares > 0, "!_srcShares");

        uint _depositAmt;
        {
            uint _wdAmt = _withdraw(address(_srcVault), _srcShares);
            uint _before = IERC20(_srcVaultToken).balanceOf(address(this));
            _srcVault.withdraw(_wdAmt, _srcVaultToken, 1);
            uint _after = IERC20(_srcVaultToken).balanceOf(address(this));
            _depositAmt = _after.sub(_before);
        }

        IERC20(_srcVaultToken).safeIncreaseAllowance(address(_destVault), _depositAmt);

        uint _mint_amount;
        if (_destVault.token() == _srcVaultToken || (_flag & 0x10) > 0) { // bit #1 is to enable donate dust
            _mint_amount = _destVault.deposit(_srcVaultToken, _depositAmt, _min_mint_amount);
        } else {
            IERC20 _token0;
            IERC20 _token1;
            {
                ILpPairConverter _cnvrt = ILpPairConverter(_destVault.getConverter());
                _token0 = IERC20(_cnvrt.token0());
                _token1 = IERC20(_cnvrt.token1());
            }
            uint _before0 = _token0.balanceOf(address(this));
            uint _before1 = _token1.balanceOf(address(this));
            _mint_amount = _destVault.deposit(_srcVaultToken, _depositAmt, _min_mint_amount);
            uint _after0 = _token0.balanceOf(address(this));
            uint _after1 = _token1.balanceOf(address(this));
            if (_after0 > _before0) {
                _token0.safeTransfer(msg.sender, _after0.sub(_before0));
            }
            if (_after1 > _before1) {
                _token1.safeTransfer(msg.sender, _after1.sub(_before1));
            }
        }

        if (!_isStake) {
            IERC20(address(_destVault)).safeTransfer(msg.sender, _mint_amount);
        } else {
            _stakeVaultShares(address(_destVault), _mint_amount);
        }
    }

    function stakeVaultShares(address _vault, uint _shares, uint8 _flag) public discountCHI(_flag) {
        uint _before = IERC20(address(_vault)).balanceOf(address(this));
        IERC20(address(_vault)).safeTransferFrom(msg.sender, address(this), _shares);
        uint _after = IERC20(address(_vault)).balanceOf(address(this));
        _shares = _after.sub(_before); // Additional check for deflationary tokens
        _stakeVaultShares(_vault, _shares);
    }

    function _stakeVaultShares(address _vault, uint _shares) internal {
        UserInfo storage user = userInfo[_vault][msg.sender];
        user.lastStakeTime = block.timestamp;
        updateReward(_vault);
        if (user.amount > 0) {
            getReward(_vault, msg.sender, uint8(0));
        }
        user.amount = user.amount.add(_shares);
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        user.rewardDebt = user.amount.mul(rewardPool.accRewardPerShare).div(1e18);
        emit Deposit(_vault, msg.sender, _shares);
    }

    function unfrozenStakeTime(address _vault, address _account) public view returns (uint) {
        UserInfo storage user = userInfo[_vault][_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        return user.lastStakeTime + rewardPool.rewardLockedTime;
    }

    function unstake(address _vault, uint _amount, uint8 _flag) public discountCHI(_flag) {
        UserInfo storage user = userInfo[_vault][msg.sender];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        updateReward(_vault);
        if (user.amount > 0) {
            getReward(_vault, msg.sender, uint8(0));
            if (user.lastStakeTime + rewardPool.rewardLockedTime > block.timestamp) {
                user.unclaimedReward = 0;
            } else if (user.unclaimedReward > 0) {
                safeTokenTransfer(rewardPool.rewardToken, msg.sender, user.unclaimedReward);
                user.unclaimedReward = 0;
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(address(_vault)).safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = user.amount.mul(rewardPool.accRewardPerShare).div(1e18);
        emit Withdraw(_vault, msg.sender, _amount);
    }

    function claimReward(address _vault, uint8 _flag) public discountCHI(_flag) {
        UserInfo storage user = userInfo[_vault][msg.sender];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        require(user.lastStakeTime + rewardPool.rewardLockedTime <= block.timestamp, "locked rewards");
        getReward(_vault, msg.sender, uint8(0));
        uint _pendingReward = user.unclaimedReward;
        if (_pendingReward > 0) {
            safeTokenTransfer(rewardPool.rewardToken, msg.sender, _pendingReward);
            user.unclaimedReward = 0;
        }
    }

    // using PUSH pattern
    function getReward(address _vault, address _account, uint8 _flag) public discountCHI(_flag) {
        updateReward(_vault);
        UserInfo storage user = userInfo[_vault][_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        uint _pendingReward = user.amount.mul(rewardPool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
        if (_pendingReward > 0) {
            user.accumulatedEarned = user.accumulatedEarned.add(_pendingReward);
            rewardPool.totalPaidRewards = rewardPool.totalPaidRewards.add(_pendingReward);
            // safeTokenTransfer(rewardPool.rewardToken, _account, _pendingReward);
            user.unclaimedReward = user.unclaimedReward.add(_pendingReward);
            emit RewardPaid(_vault, _account, _pendingReward);
            user.rewardDebt = user.amount.mul(rewardPool.accRewardPerShare).div(1e18);
        }
    }

    function pendingReward(address _vault, address _account) public view returns (uint _pending) {
        UserInfo storage user = userInfo[_vault][_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_vault];
        uint _accRewardPerShare = rewardPool.accRewardPerShare;
        uint lpSupply = IERC20(_vault).balanceOf(address(this));
        uint _endRewardBlockApplicable = block.number > rewardPool.endRewardBlock ? rewardPool.endRewardBlock : block.number;
        if (_endRewardBlockApplicable > rewardPool.lastRewardBlock && lpSupply != 0) {
            uint _numBlocks = _endRewardBlockApplicable.sub(rewardPool.lastRewardBlock);
            uint _incRewardPerShare = _numBlocks.mul(rewardPool.rewardPerBlock).mul(1e18).div(lpSupply);
            _accRewardPerShare = _accRewardPerShare.add(_incRewardPerShare);
        }
        _pending = user.amount.mul(_accRewardPerShare).div(1e18).sub(user.rewardDebt);
        _pending = _pending.add(user.unclaimedReward);
    }

    function shares_owner(address _vault, address _account) public view returns (uint) {
        return IERC20(_vault).balanceOf(_account).add(userInfo[_vault][_account].amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(address _vault, uint _shares, address _output, uint _min_output_amount, uint8 _flag) public discountCHI(_flag) {
        uint _wdAmt = _withdraw(_vault, _shares);
        ICompositeVault(_vault).withdrawFor(msg.sender, _wdAmt, _output, _min_output_amount);
    }

    function _withdraw(address _vault, uint _shares) internal returns (uint){
        uint _userBal = IERC20(address(_vault)).balanceOf(msg.sender);
        if (_shares > _userBal) {
            uint _need = _shares.sub(_userBal);
            require(_need <= userInfo[_vault][msg.sender].amount, "_userBal+staked < _shares");
            unstake(_vault, _need, uint8(0));
        }
        uint _before = IERC20(address(_vault)).balanceOf(address(this));
        IERC20(address(_vault)).safeTransferFrom(msg.sender, address(this), _shares);
        uint _after = IERC20(address(_vault)).balanceOf(address(this));
        return _after.sub(_before);
    }

    function exit(address _vault, address _output, uint _min_output_amount, uint8 _flag) external discountCHI(_flag) {
        unstake(_vault, userInfo[_vault][msg.sender].amount, uint8(0));
        withdraw(_vault, IERC20(address(_vault)).balanceOf(msg.sender), _output, _min_output_amount, uint8(0));
    }

    function withdraw_fee(ICompositeVault _vault, uint _shares) external view returns (uint) {
        return _vault.withdraw_fee(_shares);
    }

    function calc_token_amount_deposit(ICompositeVault _vault, address _input, uint _amount) external view returns (uint) {
        return _vault.calc_token_amount_deposit(_input, _amount);
    }

    function calc_token_amount_withdraw(ICompositeVault _vault, uint _shares, address _output) external view returns (uint) {
        return _vault.calc_token_amount_withdraw(_shares, _output);
    }

    function calc_transfer_vault_shares(ICompositeVault _srcVault, ICompositeVault _destVault, uint _srcShares) external view returns (uint) {
        address _srcVaultToken = _srcVault.token();
        uint _amount = _srcVault.calc_token_amount_withdraw(_srcShares, _srcVaultToken);
        return _destVault.calc_token_amount_deposit(_srcVaultToken, _amount);
    }

    function harvestAllStrategies(ICompositeVault _vault, uint8 _flag) external discountCHI(_flag) {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        _vault.harvestAllStrategies();
    }

    // Safe token transfer function, just in case if rounding error causes vinfo to not have enough token.
    function safeTokenTransfer(IERC20 _token, address _to, uint _amount) internal {
        uint bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20 _token, uint amount, address to) external {
        require(msg.sender == governance, "!governance");
        require(!vaultMaster.isVault(address(_token)), "vaultToken");
        _token.safeTransfer(to, amount);
    }
}