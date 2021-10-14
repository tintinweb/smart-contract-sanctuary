/**
 *Submitted for verification at arbiscan.io on 2021-10-14
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
    address private _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_governance == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_governance, newOwner);
        _governance = newOwner;
    }
}

// File: contracts/strategies/StabilizeStrategyGLPV1.sol

pragma solidity =0.6.6;

// This is a strategy is an absoluste stake strategy, fsGLP passively earns both WETH + esGMX
// esGMX is permanently staked to earn more esGMX and WETH
// WETH is used to mint more fsGLP
// GMX disables normal transferring of fsGLP and esGMX so must use other subroutines

interface StabilizeBank{
    function depositSTBZ(address _credit, uint256 amount) external;
}

interface SushiLikeRouter {
    function swapExactETHForTokens(uint, address[] calldata, address, uint) external payable returns (uint[] memory);
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory); // For a value in, it calculates value out
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface GLPManager{
    function lastAddedAt(address _sender) external view returns (uint256);
    function cooldownDuration() external view returns (uint256);
}

interface GMXRewardRouter{
    function glpManager() external view returns (address);
    function signalTransfer(address _receiver) external; // Used to transfer esGMX to new strategy
    function acceptTransfer(address _sender) external; // Used to accept esGMX from old strategy
    function feeGlpTracker() external view returns (address); // Reward tracker for WETH rewards for fsGLP
    function stakedGlpTracker() external view returns (address); // Reward tracker for esGMX rewards for fsGLP
    function stakedGmxTracker() external view returns (address); // Reward tracker for esGMX rewards for esGMX
    function bonusGmxTracker() external view returns (address); // Reward tracker/token for bonusGMX rewards for esGMX
    function feeGmxTracker() external view returns (address); // Reward tracker/token for WETH rewards for esGMX/bonusGMX
    function claim() external; // This will claim esGMX and WETH for a user
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function stakeEsGmx(uint256 _amount) external; // This is used to stake esGMX
    function unstakeEsGmx(uint256 _amount) external;
}

interface GMXRewardTracker {
    function claimable(address _account) external view returns (uint256);
}

interface zsToken {
    function getCurrentStrategy() external view returns (address); 
}

interface GMXVault {
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

contract StabilizeStrategyGLPV1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public bankAddress; // Address to the STBZ buyback bank
    address public treasuryAddress; // Dev treasury account
    address public zsTokenAddress; // The address of the controlling zs-Token
    
    uint256 constant DIVISION_FACTOR = 100000;
    bool public buybackActive = true; // Buybacks can be activated by governance
    bool public buyMoreActive = true; // Governance can disable the strat from buying more fsGLP
    uint256 public lastTradeTime = 0;
    uint256 public lastActionBalance = 0; // Balance before last deposit or withdraw
    
    // Depositor info
    uint256 public percentDepositor = 90000; // 1000 = 1%, depositors earn 90% of all gains
    uint256 public percentExecutor = 10000; // 10000 = 10% of WETH goes to executor, 5% of total profit.
    // Anything left over goes towards buyback bank
    
    // Executor info
    uint256 public minGain = 2e14; // Minimum amount of gain (normalized) needed before paying executors
    uint256 public maxPercentStipend = 30000; // The maximum amount of WETH profit that can be allocated to the executor for gas in percent
    uint256 public gasPrice = 1500000000; // 1.5 Gwei, governance can change
    uint256 public gasStipend = 3000000; // This is the gas units that are covered by executing a trade taken from the WETH profit
    
    // Token information
    // This strategy accepts fsGLP
    struct TokenInfo {
        IERC20 token; // Reference of token
        uint256 decimals; // Decimals of token
    }
    
    TokenInfo[] private tokenList; // An array of tokens accepted as deposits

    // Strategy specific variables
    address constant SUSHI_ROUTER = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address constant GMX_REWARD_ROUTER = address(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1);
    
    address constant WETH_ADDRESS = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address constant STBZ_ADDRESS = address(0x2C110867CA90e43D372C1C2E92990B00EA32818b);
    address constant ESGMX_ADDRESS = address(0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA);
    address constant GMX_VAULT = address(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    address constant USDT_ADDRESS = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address constant USDC_ADDRESS = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address constant WRAPPED_FSGLP = address(0x01AF26b74409d10e15b102621EDd29c326ba1c55); // Used to move around fsGLP
    
    constructor(
        address _treasury,
        address _bank,
        address _zsToken
    ) public {
        treasuryAddress = _treasury;
        bankAddress = _bank;
        zsTokenAddress = _zsToken;
        setupWithdrawTokens();
    }

    // Initialization functions
    
    receive() external payable {
        
    }
    
    function setupWithdrawTokens() internal {
        // Start with fsGLP
        IERC20 _token = IERC20(address(0x1aDDD80E6039594eE970E5872D247bf0414C8903));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals()
            })
        );
    }
    
    // Modifier
    modifier onlyZSToken() {
        require(zsTokenAddress == _msgSender(), "Call not sent from the zs-Token");
        _;
    }
    
    // Read functions
    
    function rewardTokensCount() external view returns (uint256) {
        return tokenList.length;
    }
    
    function rewardTokenAddress(uint256 _pos) external view returns (address) {
        require(_pos < tokenList.length,"No token at that position");
        return address(tokenList[_pos].token);
    }
    
    function balance() public view returns (uint256) {
        return getNormalizedTotalBalance(address(this));
    }
    
    function getNormalizedTotalBalance(address _address) public view returns (uint256) {
        // Get the balance of the atokens+tokens at this address
        uint256 _balance = 0;
        uint256 _length = tokenList.length;
        for(uint256 i = 0; i < _length; i++){
            uint256 _bal = tokenList[i].token.balanceOf(_address);
            _bal = _bal.mul(1e18).div(10**tokenList[i].decimals);
            _balance = _balance.add(_bal); // This has been normalized to 1e18 decimals
        }
        return _balance;
    }
    
    function withdrawTokenReserves() public view returns (address, uint256) {
        (uint256 targetID, uint256 _bal) = withdrawTokenReservesID();
        if(_bal == 0){
            return (address(0), _bal);
        }else{
            return (address(tokenList[targetID].token), _bal);
        }
    }
    
    function withdrawTokenReservesID() internal view returns (uint256, uint256) {
        return (0, tokenList[0].token.balanceOf(address(this)));
    }
    
    function withdrawLocked() public view returns (bool) {
        // GMX has a cool down feature that prevents moving around tokens right after liquidity added
        // liquidity is only added when the strat buys more GLP with ETH earned via GMX, which locks the strat withdrawals for 15 minutes
        address glpManagerAddress = GMXRewardRouter(GMX_REWARD_ROUTER).glpManager();
        if(block.timestamp < GLPManager(glpManagerAddress).lastAddedAt(address(this)).add(GLPManager(glpManagerAddress).cooldownDuration())){
            return true;
        }else{
            return false;
        }
    }
    
    // Write functions
    
    function enter() external onlyZSToken {
        deposit(false);
    }
    
    function exit() external onlyZSToken {
        // The ZS token vault is removing all tokens from this strategy
        withdraw(_msgSender(),1,1, false);
    }
    
    function deposit(bool nonContract) public onlyZSToken {
        // Only the ZS token can call the function
        if(nonContract == true){} // Do not do anything on withdraw or deposit, only restake via bot network
        lastActionBalance = balance();
    }
    
    // Test function
    /*
    function testDeposit() external payable {
        WETH(WETH_ADDRESS).deposit{value: msg.value}();
    }
    */
    
    // GMX functions
    function checkStakeProfit() internal view returns (uint256) {
        uint256 wethEarned = IERC20(WETH_ADDRESS).balanceOf(address(this));
        address feeGMX = GMXRewardRouter(GMX_REWARD_ROUTER).feeGmxTracker();
        address feeGLP = GMXRewardRouter(GMX_REWARD_ROUTER).feeGlpTracker();
        wethEarned = GMXRewardTracker(feeGMX).claimable(address(this)).add(wethEarned);
        wethEarned = GMXRewardTracker(feeGLP).claimable(address(this)).add(wethEarned);
        return wethEarned;
    }
    
    function redeemStakeProfit() internal {
        if(buyMoreActive == false){return;} // Stop this feature
        GMXRewardRouter(GMX_REWARD_ROUTER).claim(); // This will pull WETH and esGMX from contracts
        uint256 _bal = IERC20(ESGMX_ADDRESS).balanceOf(address(this));
        if(_bal > 0){
            // We will restake the esGMX into the contract
            IERC20(ESGMX_ADDRESS).safeApprove(GMX_REWARD_ROUTER, 0);
            IERC20(ESGMX_ADDRESS).safeApprove(GMX_REWARD_ROUTER, _bal);
            GMXRewardRouter(GMX_REWARD_ROUTER).stakeEsGmx(_bal); // This is permanently locked to increase reward rate
        }
        _bal = IERC20(WETH_ADDRESS).balanceOf(address(this));
        // Take a percent of the balance and turn it into more fsGLP
        if(_bal > 0){
            uint256 sellAmount = _bal.mul(percentDepositor).div(DIVISION_FACTOR);
            // Figure out if we want to convert straight WETH or convert to USDC or USDT
            address targetToken = lowestTaxedToken();
            if(targetToken != WETH_ADDRESS){
                // Sell WETH on Sushiswap for target
                SushiLikeRouter router = SushiLikeRouter(SUSHI_ROUTER);
                address[] memory path = new address[](2);
                path[0] = WETH_ADDRESS;
                path[1] = targetToken;
                IERC20(WETH_ADDRESS).safeApprove(address(router), 0);
                IERC20(WETH_ADDRESS).safeApprove(address(router), sellAmount);
                _bal = IERC20(targetToken).balanceOf(address(this));
                router.swapExactTokensForTokens(sellAmount, 1, path, address(this), now.add(60)); // Get target
                sellAmount = IERC20(targetToken).balanceOf(address(this)).sub(_bal);
            }
            // Now mint more fsGLP to this address using the target token
            address glpManager = GMXRewardRouter(GMX_REWARD_ROUTER).glpManager();
            IERC20(targetToken).safeApprove(glpManager, 0);
            IERC20(targetToken).safeApprove(glpManager, sellAmount); // The actual address that pulls tokens
            GMXRewardRouter(GMX_REWARD_ROUTER).mintAndStakeGlp(targetToken, sellAmount, 1, 1);
        }
    }
    
    function lowestTaxedToken() internal view returns (address) {
        uint256 mintFee = GMXVault(GMX_VAULT).mintBurnFeeBasisPoints();
        uint256 taxFee = GMXVault(GMX_VAULT).taxBasisPoints();
        address token = WETH_ADDRESS;
        uint256 fee = GMXVault(GMX_VAULT).getFeeBasisPoints(WETH_ADDRESS, 1e18, mintFee, taxFee, true);
        for(uint256 i = 0; i < 2; i++){
            address otherAddress = USDC_ADDRESS;
            if(i == 1){
                otherAddress = USDT_ADDRESS;
            }
            uint256 otherFee = GMXVault(GMX_VAULT).getFeeBasisPoints(otherAddress, 1e18, mintFee, taxFee, true);
            if(otherFee < fee){
                fee = otherFee;
                token = otherAddress;
            }
        }
        return token;
    }
    
    function checkAndSwapTokens(address _executor) internal {
        lastTradeTime = now;
        redeemStakeProfit();
        IERC20 weth = IERC20(WETH_ADDRESS);
        uint256 _wethBalance = weth.balanceOf(address(this));
        if(_wethBalance > 0){
            // Split the rest between the executor and buyback
            // This is pure profit, figure out allocation
            if(_executor != address(0)){
                // Executors will get a gas reimbursement in WETH and a percent of the remaining
                uint256 maxGasFee = gasPrice.mul(gasStipend); // This is gas stipend in wei
                uint256 gasFee = tx.gasprice.mul(gasStipend); // This is gas fee requested
                if(gasFee > maxGasFee){
                    gasFee = maxGasFee; // Gas fee cannot be greater than the maximum
                }
                uint256 executorAmount = gasFee;
                if(gasFee >= _wethBalance.mul(maxPercentStipend).div(DIVISION_FACTOR)){
                    executorAmount = _wethBalance.mul(maxPercentStipend).div(DIVISION_FACTOR); // The executor will get the entire amount up to point
                }else{
                    // Add the executor percent on top of gas fee
                    executorAmount = _wethBalance.sub(gasFee).mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee);
                }
                if(executorAmount > 0){
                    // Convert to ETH
                    WETH(WETH_ADDRESS).withdraw(executorAmount); // Convert some WETH into 
                    _wethBalance = weth.balanceOf(address(this)); // Recalculate WETH in contract
                    payable(_executor).transfer(executorAmount); // Transfer to executor
                }
            }
            if(_wethBalance > 0){
                if(buybackActive == true){
                    doSTBZBuyback(_wethBalance); // Buy STBZ with the WETH
                }else{
                    weth.safeTransfer(treasuryAddress, _wethBalance); // Send to the dev treasury 
                }
            }                
        }
    }
    
    function expectedProfit(bool inWETHForExecutor) external view returns (
        uint256 // Profit amount
        ) {
        // This view will return the amount of gain a forced swap will make on the next call

        uint256 _normalizedGain = checkStakeProfit(); // ETH is already normalized
        
        if(_normalizedGain <= minGain){
            _normalizedGain = 0;
        }
        
        if(inWETHForExecutor == false){
            return (_normalizedGain);
        }else{
            if(_normalizedGain == 0){
                return (0);
            }
            // Calculate how much WETH the executor would make as profit
            uint256 estimate = _normalizedGain.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR);
            // Now calculate the amount going to the executor
            uint256 gasFee = gasPrice.mul(gasStipend); // This is gas stipend in wei
            if(gasFee >= estimate.mul(maxPercentStipend).div(DIVISION_FACTOR)){ // Max percent of total
                return estimate.mul(maxPercentStipend).div(DIVISION_FACTOR); // The executor will get max percent of total
            }else{
                estimate = estimate.sub(gasFee); // Subtract fee from remaining balance
                return estimate.mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee); // Executor amount with fee added
            }
        }  
    }
    
    function doSTBZBuyback(uint256 _amount) internal {
        SushiLikeRouter router = SushiLikeRouter(SUSHI_ROUTER);
        address[] memory path = new address[](2);
        path[0] = WETH_ADDRESS;
        path[1] = STBZ_ADDRESS;
        IERC20(WETH_ADDRESS).safeApprove(address(router), 0);
        IERC20(WETH_ADDRESS).safeApprove(address(router), _amount);
        router.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(60)); // Get STBZ
        uint256 _bal = IERC20(STBZ_ADDRESS).balanceOf(address(this));
        if(_bal > 0){
            IERC20(STBZ_ADDRESS).safeApprove(bankAddress, 0);
            IERC20(STBZ_ADDRESS).safeApprove(bankAddress, _bal);  
            StabilizeBank(bankAddress).depositSTBZ(zsTokenAddress, _bal); // This will pull the balance
        }
        return;
    }
    
    function withdraw(address _depositor, uint256 _share, uint256 _total, bool nonContract) public onlyZSToken returns (uint256) {
        require(balance() > 0, "There are no tokens in this strategy");
        if(nonContract == true){}
        uint256 withdrawAmount = 0;
        uint256 _balance = balance();
        if(_share < _total){
            uint256 _myBalance = _balance.mul(_share).div(_total);
            withdrawOne(_depositor, _myBalance, false); // This will withdraw based on token balance
            withdrawAmount = _myBalance;
        }else{
            // We are all shares, transfer all
            withdrawOne(_depositor, _balance, true);
            withdrawAmount = _balance;
        }       
        lastActionBalance = balance();
        
        return withdrawAmount;
    }
    
    // This will withdraw the token from the contract
    function withdrawOne(address _receiver, uint256 _withdrawAmount, bool _takeAll) internal {
        if(_takeAll == true){
            // Send the entire balance
            uint256 _bal = tokenList[0].token.balanceOf(address(this));
            if(_bal > 0){
                IERC20(WRAPPED_FSGLP).safeTransfer(_receiver, _bal);
            }
            return;
        }

        // Determine the balance left
        uint256 _normalizedBalance = tokenList[0].token.balanceOf(address(this)).mul(1e18).div(10**tokenList[0].decimals);
        if(_normalizedBalance <= _withdrawAmount){
            // Withdraw the entire balance of this token
            if(_normalizedBalance > 0){
                _withdrawAmount = _withdrawAmount.sub(_normalizedBalance);
                IERC20(WRAPPED_FSGLP).safeTransfer(_receiver, tokenList[0].token.balanceOf(address(this)));                    
            }
        }else{
            // Withdraw a partial amount of this token
            if(_withdrawAmount > 0){
                // Convert the withdraw amount to the token's decimal amount
                uint256 _balance = _withdrawAmount.mul(10**tokenList[0].decimals).div(1e18);
                _withdrawAmount = 0;
                IERC20(WRAPPED_FSGLP).safeTransfer(_receiver, _balance);
            }
        }
    }
    
    function executorSwapTokens(address _executor, uint256 _minSecSinceLastTrade, uint256 _deadlineTime) external {
        // Function designed to promote trading with incentive
        require(now <= _deadlineTime, "Deadline has expired, aborting trade");
        require(now.sub(lastTradeTime) > _minSecSinceLastTrade, "The last trade was too recent");
        require(_msgSender() == tx.origin, "Contracts cannot interact with this function");
        checkAndSwapTokens(_executor);
    }
    
    // Governance functions
    function governanceSwapTokens() external onlyGovernance {
        // This is function that force trade tokens at anytime. It can only be called by governance
        checkAndSwapTokens(governance());
    }
    
    function governanceToggleBuyMore(bool _enable) external onlyGovernance {
        // Governance can disable/enable the buymore feature
        buyMoreActive = _enable;
    }
    
    function governanceStartMoveEsGMX(address _target) external onlyGovernance {
        // fsGLP must be removed for this function to operate
        require(zsToken(zsTokenAddress).getCurrentStrategy() != address(this), "Tokens not yet pulled from strategy");
        GMXRewardRouter(GMX_REWARD_ROUTER).signalTransfer(_target); // Used to move esGMX
    }
    
    function governanceFinishMoveEsGMX(address _sender) external onlyGovernance {
        // Obtain tokens from another address
        GMXRewardRouter(GMX_REWARD_ROUTER).acceptTransfer(_sender); // Used to receive esGMX
    }

    // Change the trading conditions used by the strategy without timelock
    // --------------------
    function governanceChangeTradingConditions(
                                    uint256 _pStipend,
                                    uint256 _maxStipend,
                                    uint256 _minGain,
                                    uint256 _gasPrice) external onlyGovernance {
        // Changes a lot of trading parameters in one call
        require(_pStipend <= 100000,"Percent cannot be greater than 100%");
        maxPercentStipend = _pStipend;
        gasStipend = _maxStipend;
        minGain = _minGain;
        gasPrice = _gasPrice;
    }
    // --------------------
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[2] private _timelock_data;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        if(balance() > 0){ // Timelock only applies when balance exists
            require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        }
        _;
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the treasury address
    // --------------------
    function startChangeDevTreasury(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeDevTreasury() external onlyGovernance timelockConditionsMet(2) {
        treasuryAddress = _timelock_address;
    }
    // --------------------
    
    // Change the ba address
    // --------------------
    function startChangeBank(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishChangeBank() external onlyGovernance timelockConditionsMet(3) {
        bankAddress = _timelock_address;
    }
    // --------------------
    
    // Change the zsToken address
    // --------------------
    function startChangeZSToken(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_address = _address;
    }
    
    function finishChangeZSToken() external onlyGovernance timelockConditionsMet(4) {
        zsTokenAddress = _timelock_address;
    }
    // --------------------
    
    // Change the strategy allocations between the parties
    // --------------------
    
    function startChangeStrategyAllocations(uint256 _pDepositors, 
                                            uint256 _pExecutor) external onlyGovernance {
        // Changes strategy allocations in one call
        require(_pDepositors <= 100000 && _pExecutor <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 5;
        _timelock_data[0] = _pDepositors;
        _timelock_data[1] = _pExecutor;
    }
    
    function finishChangeStrategyAllocations() external onlyGovernance timelockConditionsMet(5) {
        percentDepositor = _timelock_data[0];
        percentExecutor = _timelock_data[1];
    }
    // --------------------
}