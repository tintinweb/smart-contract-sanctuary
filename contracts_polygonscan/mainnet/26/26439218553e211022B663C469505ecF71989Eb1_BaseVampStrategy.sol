/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/IACVault.sol

pragma solidity ^0.6.0;

//Autocompounder Vault
interface IACVault {
     function deposit(uint _amount) external;
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/IUniswapRouterEth.sol

pragma solidity ^0.6.0;

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/IVault.sol

pragma solidity ^0.6.0;

//Vampire Vault Interface
interface IVault {
    function depositRewards(uint256 pid, uint256 amt) external;
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/IRewardPool.sol

pragma solidity ^0.6.0;

interface IRewardPool {
    function deposit(uint256 amount) external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function balanceOf(address account) external view returns (uint256);
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/Context.sol

pragma solidity >=0.6.0 <0.8.0;
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/Pausable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/StratManager.sol

pragma solidity ^0.6.12;



contract StratManager is Ownable, Pausable {
    /**
     * @dev Raven Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat
     * {strategist} - Address of the strategy author/deployer where strategist fee will go.
     * {vault} - Address of the vault that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public keeper;
    address public strategist;
    address public unirouter;   //Main router of where the LP is stationed
    address public vault;
    address public ravenFeeRecipient;
    address public boostContract;

    event KeeperChanged(address newKeeper);
    event StrategistChanged(address newStrategist);
    event BoostContractChanged(address newBoostContract); 

    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     * @param _strategist address where strategist fees go.
     * @param _unirouter router to use for swaps
     * @param _vault address of parent vault.
     * @param _ravenFeeRecipient address where to send Raven's fees.
     */
    constructor(
        address _keeper,
        address _strategist,
        address _unirouter,
        address _vault,
        address _ravenFeeRecipient
    ) public {
        require(_keeper != address(0));
        keeper = _keeper;
        require(_strategist != address(0));
        strategist = _strategist;
        require(_unirouter != address(0));
        unirouter = _unirouter;
        require(_vault != address(0));
        vault = _vault;
        require(_ravenFeeRecipient != address(0));
        ravenFeeRecipient = _ravenFeeRecipient;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
        emit KeeperChanged(_keeper);
    }

    
    /**
     * @dev Updates address where strategist fee earnings will go.
     * @param _strategist new strategist address.
     */
    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "!strategist");
        strategist = _strategist;
        emit StrategistChanged(_strategist);
    }

    /**
     * dev Updates router that will be used for swaps.
     * param _unirouter new unirouter address.
     *
    function setUnirouter(address _unirouter) external onlyOwner {
        require(unirouter == address(0));
        unirouter = _unirouter;
    }
    *

    /**
     * dev Updates parent vault.
     * param _vault new vault address.
     *
    function setVault(address _vault) external onlyOwner {
        require(vault == address(0));
        vault = _vault;
    }
    */
    function setBoostContract(address _boostContract) internal {
        boostContract = _boostContract;
        emit BoostContractChanged(_boostContract);
    }

    /**
     * dev Updates raven fee recipient.
     * param _ravenFeeRecipient new raven fee recipient address.
     *
    function setravenFeeRecipient(address _ravenFeeRecipient) external onlyOwner {
        ravenFeeRecipient = _ravenFeeRecipient;
    }
    */

}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/FeeManager.sol

pragma solidity ^0.6.12;

abstract contract FeeManager is StratManager {
    uint constant public STRATEGIST_FEE = 100; // 100 / 10000 * 100% = 1.0%
    uint constant public MAX_FEE = 1000;      
    uint constant public MAX_CALL_FEE = 115; //115 / 10000 * 100% = 1.15%

    uint constant public WITHDRAWAL_FEE = 10;
    uint constant public WITHDRAWAL_MAX = 10000;
    
    //uint public FEE_CAP = 10000; //Cap at 10000 matic / harvest

    uint public callFee = 111;
    uint public ravenFee = MAX_FEE - STRATEGIST_FEE - callFee;
    
    uint public totalFee = 35;      // 35/1000 * 100% = 3.5%

    event CallFeeUpdate(uint256 fee);
    event FeeCapUpdate(uint256 fee);
    event TotalFeeUpdate(uint256 fee);


    function setCallFee(uint256 _fee) external onlyManager {
        require(_fee <= MAX_CALL_FEE, "!cap");
        
        callFee = _fee;
        ravenFee = MAX_FEE - STRATEGIST_FEE - callFee;
        emit CallFeeUpdate(_fee);
    }
    
    /*function setFeeCap(uint256 _fee) external onlyManager {
        FEE_CAP = _fee;
        emit FeeCapUpdate(_fee);
    }*/
    
    function setTotalFee(uint256 _fee) external onlyManager {
        require(_fee <= 50);    // 5% fee capped
        totalFee = _fee;
        emit TotalFeeUpdate(_fee);
    }
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/Address.sol

pragma solidity >=0.6.0 <0.8.0;
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
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;
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

// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;



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
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/AbstractVampireStrategyV1.sol

pragma solidity ^0.6.0;








abstract contract AbstractVampireStrategyV1 is StratManager, FeeManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public lpToken; // Token we deposit to earn yield
    address public want;    // The token we swap into from rewards
    address public reward;  // The token this farm rewards
    
    address public stakingContract; // Where we deposit the tokens to earn yield
    
    uint256 public pid;
    
    bool public isBoosted;
    
    event StratHarvest(address indexed harvester);  //Fired after every harvest
    event StratBoosted(bool b);
    event DepositRewards(uint256 amt);
    
    constructor(
        address _lpToken,
        address _want,
        address _stakingContract,
        address _vault,     //Vault that owns this strategy
        address _unirouter, //Main router we use for converting reward to native (ex: SushiRouter if we go from sushi to matic)
        address _keeper,
        address _strategist, 
        address _ravenTreasury,
        uint256 _pid
    ) StratManager(_keeper, _strategist, _unirouter, _vault, _ravenTreasury) public {
        require(_lpToken != address(0));
        lpToken = _lpToken; // lp token we need to deposit to the stakingContract
        require(_want != address(0));
        want = _want;       // token we 'want' to get in return (AC receipt Token)
        require(_stakingContract != address(0));
        stakingContract = _stakingContract; // where we deposit the LP tokens 
        _giveAllowances();  // gives the necessary routers permissions to spend the tokens
        pid = _pid;         // this strategy's pool id in it's vault [DO NOT MESS THIS UP]
    }
    
    
    /*
    =========================
    ===== INTO STRATEGY ===== 
    =========================
    */
    
    // puts the funds to work
    function deposit() public whenNotPaused {
        require(msg.sender == vault || msg.sender == boostContract, "!vault or boostContract"); 
        uint256 wantBal = IERC20(lpToken).balanceOf(address(this));
        if (wantBal > 0) {
            IRewardPool(stakingContract).stake(wantBal);
        }
    }
    
    function claimRewards() public { 
        require(msg.sender == vault || msg.sender == boostContract, "!vault or boostContract"); 
        IRewardPool(stakingContract).getReward();
    }
    
    /*
    ===========================
    ===== OUT OF STRATEGY ===== 
    ===========================
    */
    
    //How the vault pulls the tokens back.  Any users who want their tokens should go through the vault.
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault || msg.sender == boostContract, "!vault or boostContract"); 

        uint256 wantBal = IERC20(lpToken).balanceOf(address(this));

        if (wantBal < _amount) {
            IRewardPool(stakingContract).withdraw(_amount.sub(wantBal));
            wantBal = IERC20(lpToken).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        /*if (tx.origin == owner() || paused()) {
            IERC20(lpToken).safeTransfer(msg.sender, wantBal);
        } else {
            uint256 withdrawalFee = wantBal.mul(WITHDRAWAL_FEE).div(WITHDRAWAL_MAX);
            IERC20(lpToken).safeTransfer(msg.sender, wantBal.sub(withdrawalFee));
        }*/
        IERC20(lpToken).safeTransfer(msg.sender, wantBal);
    }
    
    //Sends the rewards to the vault and tells it how much it's sending
    function sendRewardsToVault() internal {
        uint256 bal = balanceOfWant();
        IVault(vault).depositRewards(pid, bal); // write how much we're sending to the vault
        IERC20(want).safeTransfer(vault, bal);  // send the reward tokens to the vault
        emit DepositRewards(bal);
    }
    
    
    /*
    =======================
    ===== CONVERSIONS ===== 
    =======================
    */
    
    //Converts the reward tokens into the output token we're looking for
    function swapRewardsToWant() internal virtual {}
    
    // performance fees
    function chargeFees() internal virtual {}
    
    /*
    =========================
    ===== BOT FUNCTIONS ===== 
    =========================
    */
    
    // Harvests the rewards, charges the fees, converts to the token we want to reward and deposits them back to the vault
    function harvest() public whenNotPaused onlyVault { //onlyEOA {
        if(balanceOfPool() > 0) {   //Prevent trying to claim and swap when we have 0 LP staked
            IRewardPool(stakingContract).getReward();
            chargeFees();
            swapRewardsToWant();
        }
        sendRewardsToVault();
        emit StratHarvest(msg.sender);
    }
    
    /*
    ======================
    ===== STRAT INFO ===== 
    ======================
    */
    
    // sets whether or not this strat is boosted so we know where to withdraw through
    function setBoosted(bool _isBoosted, address _boostContract) external onlyVault {
        setBoostContract(_boostContract);
        isBoosted = _isBoosted;
        emit StratBoosted(_isBoosted);
    }
    
    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }
    
    // calculate the total underlaying lp held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfLP().add(balanceOfPool());
    }
    
    // it calculates how many lpTokens this contract holds.
    function balanceOfLP() public view returns (uint256) {
        return IERC20(lpToken).balanceOf(address(this));
    }
    
    // it calculates how much 'lp' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return IRewardPool(stakingContract).balanceOf(address(this));
    }
    
    /*
    ======================
    ===== MODERATION ===== 
    ======================
    */
    
    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        IRewardPool(stakingContract).withdraw(balanceOfPool());

        uint256 wantBal = IERC20(lpToken).balanceOf(address(this));
        IERC20(lpToken).transfer(vault, wantBal);
    }
    
    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IRewardPool(stakingContract).withdraw(balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }
    
    function allow() public onlyOwner {
        _giveAllowances();
    }
    
    //Allowances might have to be changed on an individual level
    function _giveAllowances() internal virtual {}
    
    function _removeAllowances() internal virtual {}
    
    
    /*
    ====================
    ===== MODIFIER ===== 
    ====================
    */
    
    modifier onlyVault() {
        require(msg.sender == vault, "!Vault");
        _;
    }
    
}
// File: RavenAC/moe-raven-contracts-main/Vampire_Vault/Unflattened_VampVaultV3/BaseVampStrategy.sol

//SPDX-License-Identifier: BSL 1.1 
pragma solidity ^0.6.0;







// This is an example of an Vampire Vault Strategy for a singular Token
// Claims Elk rewards and then deposits it into single staked autocompounding elk
contract BaseVampStrategy is AbstractVampireStrategyV1 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public autoVault = address(0x640Ee5105B01b612668b599A879da3E230A8d0FE); //autocompounding vault that pays out receipt tokens to depositors

    //Remove excess constants as needed per strategy
    //address constant public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address constant public matic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address constant public elk = address(0xE1C110E1B1b4A1deD0cAf3E42BfBdbB7b5d7cE1C);
    //address constant public quick = address(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    //address constant public sushi = address(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    //address constant public dquick = address(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
    
    //address public elkRouter = address(0xf38a7A7Ac2D745E2204c13F824c00139DF831FFf);
    //address public sushiRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    //address public quickRouter = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    
    address[] public rewardToMatic;// = [reward, matic];
    //address[] public rewardToEth = [reward, eth];
    //address[] public maticToElk = [matic, elk];      // path to get elk
    
    constructor(
        address _lpToken,
        address _stakingContract,
        address _vault,     //Vault that owns this strategy
        address _unirouter, //Main router we use for converting reward to native (ex: SushiRouter if we go from sushi to matic)
        address _keeper,
        address _strategist, 
        address _ravenTreasury,
        uint256 _pid,
        address _reward
        ) public AbstractVampireStrategyV1(_lpToken, autoVault, _stakingContract, _vault, _unirouter, _keeper, _strategist, _ravenTreasury, _pid) {
            require(_reward != address(0));
            reward = _reward;
            rewardToMatic = [reward, matic];
        }
        
    /*
    =======================
    ===== CONVERSIONS ===== 
    =======================
    */
    
    //Converts the reward tokens into the output token we're looking for
    function swapRewardsToWant() override internal {
        //Change this as needed for different strategiess
        
        IACVault(want).deposit(IERC20(elk).balanceOf(address(this)));
    }
    
    // performance fees
    function chargeFees() override internal {
        uint256 toMatic = IERC20(reward).balanceOf(address(this)).mul(totalFee).div(1000); //3.5% fees on txn
        
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(toMatic, 0, rewardToMatic, address(this), now);

        uint256 maticBal = IERC20(matic).balanceOf(address(this));  

        uint256 callFeeAmount = maticBal.mul(callFee).div(MAX_FEE); //Goes to paying for gas
        IERC20(matic).safeTransfer(keeper, callFeeAmount);

        uint256 ravenFeeAmount = maticBal.mul(ravenFee).div(MAX_FEE);   //This goes to the raven treasury
        IERC20(matic).safeTransfer(ravenFeeRecipient, ravenFeeAmount);

        uint256 strategistFee = maticBal.mul(STRATEGIST_FEE).div(MAX_FEE);  //This is the strategist address
        IERC20(matic).safeTransfer(strategist, strategistFee);
    }
        
        
    /*
    =====================
    ===== APPROVALS ===== 
    =====================
    */
    
    //Allowances might have to be changed on an individual level
    function _giveAllowances() override internal {
        IERC20(lpToken).safeApprove(stakingContract, uint(0)); //Make sure we can stake the LP
        //IERC20(want).safeApprove(vault, uint256(0));         
        IERC20(elk).safeApprove(want, uint256(0));  
        IERC20(elk).safeApprove(unirouter, uint256(0));     //Make sure we can sell the Rewards
        //IERC20(matic).safeApprove(elkRouter, uint256(0));
        //IERC20(elk).safeApprove(elkRouter, uint256(0));
        
        IERC20(lpToken).safeApprove(stakingContract, uint(-1)); //Make sure we can stake the LP
        //IERC20(want).safeApprove(vault, uint256(-1));           
        IERC20(elk).safeApprove(want, uint256(-1));     // Make sure we can deposit the elk rewards into the single stake vault
        IERC20(elk).safeApprove(unirouter, uint256(-1));     //Make sure we can sell the Rewards for fees
        //IERC20(matic).safeApprove(elkRouter, uint256(-1));
        //IERC20(elk).safeApprove(elkRouter, uint256(-1));
    }
    
    function _removeAllowances() override internal {
        IERC20(lpToken).safeApprove(stakingContract, uint(0)); //block stakingContract
        //IERC20(want).safeApprove(vault, uint256(0));         //Block vault
        IERC20(elk).safeApprove(want, uint256(0));  
        IERC20(elk).safeApprove(unirouter, uint256(0));             //Block router
        //IERC20(matic).safeApprove(elkRouter, uint256(0));
        //IERC20(elk).safeApprove(elkRouter, uint256(0));
    }
}