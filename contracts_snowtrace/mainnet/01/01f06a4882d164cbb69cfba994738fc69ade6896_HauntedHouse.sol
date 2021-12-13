/**
 *Submitted for verification at snowtrace.io on 2021-12-13
*/

// File contracts/interfaces/IRewarder.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRewarder {
    function onZBoofiReward(address depositToken, address caller, address recipient, uint256 zboofiAmount, uint256 previousShareAmount, uint256 newShareAmount) external;
    function pendingTokens(address depositToken, address user) external view returns (address[] memory, uint256[] memory);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/interfaces/IBoofiStrategy.sol

pragma solidity >=0.5.0;

//owned by the HauntedHouse contract
interface IBoofiStrategy {
    //pending tokens for the user
    function pendingTokens(address user) external view returns(address[] memory tokens, uint256[] memory amounts);
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external;
    function migrate(address newStrategy) external;
    function onMigration() external;
    function transferOwnership(address newOwner) external;
    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external;
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/interfaces/IERC20WithPermit.sol

pragma solidity >=0.5.0;

interface IERC20WithPermit is IERC20Metadata {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/interfaces/IBOOFI.sol

pragma solidity >=0.5.0;

interface IBOOFI is IERC20WithPermit {
    function mint(address dest, uint256 amount) external;
}


// File contracts/interfaces/IZBOOFI.sol

pragma solidity >=0.5.0;

interface IZBOOFI is IERC20WithPermit {
    function enter(uint256 _amount) external;
    function enterFor(address _to, uint256 _amount) external;
    function leave(uint256 _share) external;
    function leaveTo(address _to, uint256 _share) external;
    function currentExchangeRate() external view returns(uint256);
    function expectedZBOOFI(uint256 amountBoofi) external view returns(uint256);
    function expectedBOOFI(uint256 amountZBoofi) external view returns(uint256);
}


// File contracts/interfaces/IOracle.sol

pragma solidity >=0.5.0;

interface IOracle {
    function getPrice(address token) external returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/HauntedHouse.sol

pragma solidity ^0.8.6;







contract HauntedHouse is Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many shares the user currently has
        int256 rewardDebt; // Reward debt. At any time, the amount of pending zBOOFI for a user is ((user.amount * accZBOOFIPerShare) / ACC_BOOFI_PRECISION) - user.rewardDebt
    }

    // Info of each accepted token.
    struct TokenInfo {
        IRewarder rewarder; // Address of rewarder for token
        IBoofiStrategy strategy; // Address of strategy for token
        uint256 lastRewardTime; // Last time that zBOOFI distribution occurred for this token
        uint256 lastCumulativeReward; // Value of cumulativeAvgZboofiPerWeightedValueLocked at last update
        uint256 storedPrice; // Latest value of token
        uint256 accZBOOFIPerShare; // Accumulated zBOOFI per share, times ACC_BOOFI_PRECISION.
        uint256 totalShares; //total number of shares for the token
        uint256 totalTokens; //total number of tokens deposited
        uint128 multiplier; // multiplier for this token
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
    }

    // The BOOFI TOKEN!
    IBOOFI public immutable BOOFI;
    // The ZBOOFI TOKEN
    IZBOOFI public immutable ZBOOFI;
    // The timestamp when mining starts.
    uint256 public startTime;

    // global reward and weighted TVL tracking
    uint256 public weightedTotalValueLocked;
    uint256 public cumulativeAvgZboofiPerWeightedValueLocked;
    uint256 public lastAvgUpdateTimestamp;

    //endowment addresses
    address public dev;
    address public marketingAndCommunity;
    address public partnership;
    address public foundation;
    address public zBoofiStaking;
    //address to receive BOOFI purchased by strategies
    address public strategyPool;
    //performance fee address -- receives "performance fees" from strategies
    address public performanceFeeAddress;

    uint256 public constant devBips = 625;
    uint256 public constant marketingAndCommunityBips = 625;
    uint256 public constant partnershipBips = 625;
    uint256 public constant foundationBips = 1750;
    uint256 public zBoofiStakingBips = 0;
    //sum of the above endowment bips
    uint256 public totalEndowmentBips = devBips + marketingAndCommunityBips + partnershipBips + foundationBips + zBoofiStakingBips;

    //amount currently withdrawable by endowments
    uint256 public endowmentBal;

    //address that controls updating prices of deposited tokens
    address public priceUpdater;

    // amount of BOOFI emitted per second
    uint256 public boofiEmissionPerSecond;

    //whether auto-updating of prices is turned on or off. off by default
    bool public autoUpdatePrices;
    //address of oracle for auto-updates
    address public oracle;

    uint256 internal constant ACC_BOOFI_PRECISION = 1e18;
    uint256 internal constant BOOFI_PRECISION_SQUARED = 1e36;
    uint256 internal constant MAX_BIPS = 10000;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // list of tokens currently approved for deposit
    address[] public approvedTokenList;
    //mapping to track token positions in approvedTokenList
    mapping(address => uint256) public tokenListPosition;
    //mapping for tracking contracts approved to call into this one
    mapping(address => bool) public approvedContracts;
    //mapping for tracking whether or not a token is approved for deposit
    mapping(address => bool) public approvedTokens;
    // Info for all accepted tokens
    mapping(address => TokenInfo) public tokenParameters;
    // tracks if tokens have been added before, to ensure they are not added multiple times
    mapping(address => bool) public tokensAdded;
    // Info of each user that stakes tokens. stored as userInfo[token][userAddress]
    mapping(address => mapping(address => UserInfo)) public userInfo;
    //tracks historic deposits of each address. deposits[token][user] is the total deposits of 'token' for 'user', cumulative over all time
    mapping(address => mapping(address => uint256)) public deposits;
    //tracks historic withdrawals of each address. deposits[token][user] is the total withdrawals of 'token' for 'user', cumulative over all time
    mapping(address => mapping(address => uint256)) public withdrawals;
    //access control roles -- given to owner by default, who can reassign as necessary
    //role 0 can modify the approved token list and add new tokens
    //role 1 can change token multipliers, rewarders, and withdrawFeeBPs
    //role 2 can adjust endowment, strategyPool, and price updater addresses
    //role 3 has ability to modify the BOOFI emission rate
    //role 4 controls access for other contracts, whether automatic price updating is on or off, and the oracle address for this
    //role 5 has strategy management powers
    mapping(uint256 => address) public roles;

    /**
     * @notice Throws if called by non-approved smart contract
     */
    modifier onlyApprovedContractOrEOA() {
        require(tx.origin == msg.sender || approvedContracts[msg.sender], "onlyApprovedContractOrEOA");
        _;
    }

    modifier onlyRole(uint256 role) {
        if (roles[role] == address(0)) {
            require(msg.sender == owner(), "only owner");
        } else {
            require(msg.sender == roles[role], "only role");            
        }
        _;
    }

    event Deposit(address indexed user, address indexed token, uint256 amount, address indexed to);
    event Withdraw(address indexed user, address indexed token, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, address indexed token, uint256 amount, address indexed to);
    event Harvest(address indexed user, address indexed token, uint256 amountBOOFI);
    event BoofiEmissionSet(uint256 newBoofiEmissionPerSecond);
    event DevSet(address indexed oldAddress, address indexed newAddress);
    event MarketingAndCommunitySet(address indexed oldAddress, address indexed newAddress);
    event PartnershipSet(address indexed oldAddress, address indexed newAddress);
    event FoundationSet(address indexed oldAddress, address indexed newAddress);
    event ZboofiStakingSet(address indexed oldAddress, address indexed newAddress);
    event StrategyPoolSet(address indexed oldAddress, address indexed newAddress);
    event PerformanceFeeAddressSet(address indexed oldAddress, address indexed newAddress);
    event PriceUpdaterSet(address indexed oldAddress, address indexed newAddress);
    event OracleSet(address indexed oldAddress, address indexed newAddress);
    event RoleTransferred(uint256 role, address indexed oldAddress, address indexed newAddress);

    constructor(
        IBOOFI _BOOFI,
        IZBOOFI _ZBOOFI,
        uint256 _startTime,
        address _dev,
        address _marketingAndCommunity,
        address _partnership,
        address _foundation,
        address _strategyPool,
        address _performanceFeeAddress,
        uint256 _boofiEmissionPerSecond 
    ) {
        require(_startTime > block.timestamp, "need future");
        BOOFI = _BOOFI;
        ZBOOFI = _ZBOOFI;
        _BOOFI.approve(address(_ZBOOFI), MAX_UINT);
        startTime = _startTime;
        setEndowment(0, _dev);
        setEndowment(1, _marketingAndCommunity);
        setEndowment(2, _partnership);
        setEndowment(3, _foundation);
        setStrategyPool(_strategyPool);
        setPerformanceFeeAddress(_performanceFeeAddress);
        boofiEmissionPerSecond = _boofiEmissionPerSecond;
        //update this value so function '_globalUpdate()' will do nothing before _startTime
        lastAvgUpdateTimestamp = _startTime;
        emit BoofiEmissionSet(_boofiEmissionPerSecond);
    }

    //VIEW FUNCTIONS
    function tokenListLength() public view returns (uint256) {
        return approvedTokenList.length;
    }

    function tokenList() external view returns (address[] memory) {
        return approvedTokenList;
    }

    // View function to see total pending reward in zBOOFI on frontend.
    function pendingZBOOFI(address token, address userAddress) public view returns (uint256) {
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][userAddress];
        uint256 accZBOOFIPerShare = tokenInfo.accZBOOFIPerShare;
        uint256 poolShares = tokenInfo.totalShares;
        //mimic global update
        uint256 globalCumulativeAverage = cumulativeAvgZboofiPerWeightedValueLocked;
        if (block.timestamp > lastAvgUpdateTimestamp && weightedTotalValueLocked > 0) {
            uint256 newBOOFI  = (block.timestamp - lastAvgUpdateTimestamp) * boofiEmissionPerSecond;
            uint256 endowmentAmount = (newBOOFI * totalEndowmentBips) / MAX_BIPS;
            uint256 finalAmount = newBOOFI - endowmentAmount;
            //convert BOOFI to zBOOFI. factor of 1e18 is because of exchange rate scaling
            uint256 newZBOOFI = ZBOOFI.expectedZBOOFI(finalAmount);
            //NOTE: large scaling here, as divisor is enormous
            globalCumulativeAverage += (newZBOOFI * BOOFI_PRECISION_SQUARED) / weightedTotalValueLocked;
        }
        //mimic single token update
        if (block.timestamp > tokenInfo.lastRewardTime) {
            uint256 cumulativeRewardDiff = (cumulativeAvgZboofiPerWeightedValueLocked - tokenInfo.lastCumulativeReward);
            //NOTE: inverse scaling to that performed in calculating cumulativeAvgZboofiPerWeightedValueLocked
            uint256 zboofiReward = (cumulativeRewardDiff * tokenWeightedValueLocked(token)) / BOOFI_PRECISION_SQUARED;
            if (zboofiReward > 0) {
                accZBOOFIPerShare += (zboofiReward * ACC_BOOFI_PRECISION) / poolShares;
            }
        }
        return _toUInt256(int256((user.amount * accZBOOFIPerShare) / ACC_BOOFI_PRECISION) - user.rewardDebt);
    }

    // view function to get all pending rewards, from HauntedHouse and Rewarder
    function pendingTokens(address token, address user) external view 
        returns (address[] memory, uint256[] memory) {
        (address[] memory strategyTokens, uint256[] memory strategyRewards) = IBoofiStrategy (tokenParameters[token].strategy).pendingTokens(user);
        address[] memory rewarderTokens;
        uint256[] memory rewarderRewards;
        if (address(tokenParameters[token].rewarder) != address(0)) {
            (rewarderTokens, rewarderRewards) = tokenParameters[token].rewarder.pendingTokens(token, user);
        }
        uint256 numStrategyTokens = strategyTokens.length;
        uint256 numRewarderTokens = rewarderTokens.length;        
        uint256 rewardsLength = 1 + numStrategyTokens + numRewarderTokens;
        address[] memory _rewardTokens = new address[](rewardsLength);
        uint256[] memory _pendingAmounts = new uint256[](rewardsLength);
        _rewardTokens[0] = address(ZBOOFI);
        _pendingAmounts[0] = pendingZBOOFI(token, user);
        for (uint256 i = 0; i < numStrategyTokens; i ++) {
            _rewardTokens[i + 1] = strategyTokens[i];
            _pendingAmounts[i + 1] = strategyRewards[i];
        }
        for (uint256 j = 0; j < numRewarderTokens; j++) {
            _rewardTokens[j + numStrategyTokens + 1] = rewarderTokens[j];
            _pendingAmounts[j + numStrategyTokens + 1] = rewarderRewards[j];
        }
        return(_rewardTokens, _pendingAmounts);
    }

    //returns user profits in LP (negative in the case that the user has net losses due to previous withdrawal fees)
    function profitInLP(address token, address userAddress) external view returns(int256) {
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][userAddress];
        uint256 userDeposits = deposits[token][userAddress];
        uint256 userWithdrawals = withdrawals[token][userAddress];
        uint256 lpFromShares = (user.amount * tokenInfo.totalTokens) / tokenInfo.totalShares;
        uint256 totalAssets = userWithdrawals + lpFromShares;
        return (int256(totalAssets) - int256(userDeposits));
    }

    //convenience function to get the emission of BOOFI at the current emission + exchange rates, to depositors of a given token, accounting for endowment distribution
    function boofiPerSecondToToken(address token) public view returns(uint256) {
        return ((boofiEmissionPerSecond * tokenWeightedValueLocked(token)) * (MAX_BIPS - totalEndowmentBips) / MAX_BIPS) / weightedTotalValueLocked;
    }

    //function to get the emission of zBOOFI per second at the current emission rate, at the current exchange rate, accounting for endowment distribution
    function zboofiPerSecond() external view returns (uint256) {
        return ZBOOFI.expectedZBOOFI((boofiEmissionPerSecond * (MAX_BIPS - totalEndowmentBips)) / MAX_BIPS);
    }

    //convenience function to get the annualized emission of ZBOOFI at the current emission + exchange rates, to depositors of a given token, accounting for endowment distribution
    function zboofiPerSecondToToken(address token) external view returns(uint256) {
        return ZBOOFI.expectedZBOOFI(boofiPerSecondToToken(token));
    }

    //function to get current value locked from a single token
    function tokenValueLocked(address token) public view returns (uint256) {
        return (tokenParameters[token].totalTokens * tokenParameters[token].storedPrice);
    }

    //get current value locked for a single token, multiplied by the token's multiplier
    function tokenWeightedValueLocked(address token) public view returns (uint256) {
        return (tokenValueLocked(token) * tokenParameters[token].multiplier);
    }

    //WRITE FUNCTIONS
    /// @notice Update reward variables of the given token.
    /// @param token The address of the deposited token.
    function updateTokenRewards(address token) external onlyApprovedContractOrEOA {
        _updateTokenRewards(token);
    }

    // Update reward variables for all approved tokens. Be careful of gas spending!
    function massUpdateTokens() external onlyApprovedContractOrEOA {
        uint256 length = tokenListLength();
        _globalUpdate();
        for (uint256 i = 0; i < length; i++) {
            _tokenUpdate(approvedTokenList[i]);
        }
    }

    /// @notice Deposit tokens to HauntedHouse for zBOOFI allocation.
    /// @param token The address of the token to deposit
    /// @param amount Token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(address token, uint256 amount, address to) external onlyApprovedContractOrEOA {
        _deposit(token, amount, to);
    }

    //convenience function
    function deposit(address token, uint256 amount) external onlyApprovedContractOrEOA {
        _deposit(token, amount, msg.sender);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param token The address of the deposited token.
    /// @param to Receiver of BOOFI rewards.
    function harvest(address token, address to) external onlyApprovedContractOrEOA {
        _harvest(token, to);
    }

    //convenience function
    function harvest(address token) external onlyApprovedContractOrEOA {
        _harvest(token, msg.sender);
    }

    /// @notice Withdraw tokens from HauntedHouse.
    /// @param token The address of the withdrawn token.
    /// @param amountShares amount of shares to withdraw.
    /// @param to Receiver of the tokens.
    function withdraw(address token, uint256 amountShares, address to) external onlyApprovedContractOrEOA {
        _withdraw(token, amountShares, to);
    }

    //convenience function
    function withdraw(address token, uint256 amountShares) external onlyApprovedContractOrEOA {
        _withdraw(token, amountShares, msg.sender);
    }

    /// @notice Withdraw tokens from HauntedHouse and harvest pending rewards
    /// @param token The address of the withdrawn token.
    /// @param amountShares amount of shares to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdrawAndHarvest(address token, uint256 amountShares, address to) external onlyApprovedContractOrEOA {
        _withdrawAndHarvest(token, amountShares, to);
    }

    //convenience function
    function withdrawAndHarvest(address token, uint256 amountShares) external onlyApprovedContractOrEOA {
        _withdrawAndHarvest(token, amountShares, msg.sender);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param token The address of the withdrawn token.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(address token, address to) external onlyApprovedContractOrEOA {
        _emergencyWithdraw(token, to);
    }

    //distribute pending endowment funds. callable by anyone.
    function distributeEndowment() external {
        uint256 totalToSend = endowmentBal;
        endowmentBal = 0;
        uint256 toDev = (totalToSend * devBips) / totalEndowmentBips;
        uint256 toMarketingAndCommunity = (totalToSend * marketingAndCommunityBips) / totalEndowmentBips;
        uint256 toPartnership = (totalToSend * partnershipBips) / totalEndowmentBips;
        uint256 toFoundation = (totalToSend * foundationBips) / totalEndowmentBips;
        if (zBoofiStakingBips > 0) {
            uint256 toZboofiStaking = (totalToSend * zBoofiStakingBips) / totalEndowmentBips;
            _safeBOOFITransfer(zBoofiStaking, toZboofiStaking); 
        }
        _safeBOOFITransfer(dev, toDev);
        _safeBOOFITransfer(marketingAndCommunity, toMarketingAndCommunity);
        _safeBOOFITransfer(partnership, toPartnership);
        _safeBOOFITransfer(foundation, toFoundation);
    }

    //ACCESS-CONTROLLED FUNCTIONS
    function setRole(uint256 role, address holder) external onlyOwner {
        emit RoleTransferred(role, roles[role], holder);
        roles[role] = holder;
    }

    //modifies whether 'token' is in the approved list of tokens or not. only approved tokens can be deposited.
    function modifyApprovedToken(address token, bool status) external onlyRole(0) {
        _modifyApprovedToken(token, status);
    }

    /// @notice Add parameters to a new token.
    /// @param token the token address
    /// @param _withdrawFeeBP withdrawal fee of the token.
    /// @param _multiplier token multiplier for weighted TVL
    /// @param _rewarder Address of the rewarder delegate.
    /// @param _strategy Address of the strategy delegate.
    function add(address token, uint16 _withdrawFeeBP, uint128 _multiplier, IRewarder _rewarder, IBoofiStrategy _strategy)
        external onlyRole(0) {
        require(
            _withdrawFeeBP <= 1000,
            "_withdrawFeeBP high"
        );
        //track adding token
        require(!tokensAdded[token], "cannot add token 2x");
        tokensAdded[token] = true;
        //approve token if it is not already approved
        _modifyApprovedToken(token, true);
        //do global update to rewards before adding new token
        _globalUpdate();
        uint256 _lastRewardTime =
            block.timestamp > startTime ? block.timestamp : startTime;
        tokenParameters[token] = (
            TokenInfo({
                rewarder: _rewarder, // Address of rewarder for token
                strategy: _strategy, // Address of strategy for token
                multiplier: _multiplier, // multiplier for this token
                lastRewardTime: _lastRewardTime, // Last time that zBOOFI distribution occurred for this token
                lastCumulativeReward: cumulativeAvgZboofiPerWeightedValueLocked, // Value of cumulativeAvgZboofiPerWeightedValueLocked at last update
                storedPrice: 0, // Latest value of token
                accZBOOFIPerShare: 0, // Accumulated zBOOFI per share, times ACC_BOOFI_PRECISION.
                withdrawFeeBP: _withdrawFeeBP, // Withdrawal fee in basis points
                totalShares: 0, //total number of shares for the token
                totalTokens: 0 //total number of tokens deposited
            })
        );
    }

    /// @notice Update the given token's withdrawal fee BIPS.
    /// @param token the token address
    /// @param _withdrawFeeBP new withdrawal fee BIPS value
    function changeWithdrawFeeBP(address token, uint16 _withdrawFeeBP) external onlyRole(1) {
        require(
            _withdrawFeeBP <= 1000,
            "_withdrawFeeBP high"
        );
        tokenParameters[token].withdrawFeeBP = _withdrawFeeBP;
    }

    /// @notice Update the given token's rewarder contract.
    /// @param token the token address
    /// @param _rewarder Address of the rewarder delegate.
    function changeRewarder(address token, IRewarder _rewarder) external onlyRole(1) {
        tokenParameters[token].rewarder = _rewarder;
    }

    /// @notice Update the given tokens' multiplier factors
    /// @param tokens the token addresses
    /// @param _multipliers new token multipliers for weighted TVL
    function changeMultipliers(address[] calldata tokens, uint128[] calldata _multipliers) external onlyRole(1) {
        require(tokens.length == _multipliers.length, "inputs");
        //do global update to rewards before updating token
        _globalUpdate();
        for (uint256 i = 0; i < tokens.length; i++) {
            weightedTotalValueLocked -= tokenWeightedValueLocked(tokens[i]);
            tokenParameters[tokens[i]].multiplier = _multipliers[i];
            weightedTotalValueLocked += tokenWeightedValueLocked(tokens[i]);
        }
    }

    function setEndowment(uint256 endowmentRole, address _newAddress) public onlyRole(2) {
        require(_newAddress != address(0));
        if (endowmentRole == 0) {
            emit DevSet(dev, _newAddress);
            dev = _newAddress;            
        } else if (endowmentRole == 1) {
            emit MarketingAndCommunitySet(marketingAndCommunity, _newAddress);
            marketingAndCommunity = _newAddress;
        } else if (endowmentRole == 2) {
            emit PartnershipSet(partnership, _newAddress);
            partnership = _newAddress;
        } else if (endowmentRole == 3) {
            emit FoundationSet(foundation, _newAddress);
            foundation = _newAddress;
        } else if (endowmentRole == 4) {
            emit ZboofiStakingSet(zBoofiStaking, _newAddress);
            zBoofiStaking = _newAddress;
        }
    }

    function setPerformanceFeeAddress(address _performanceFeeAddress) public onlyRole(2) {
        require(_performanceFeeAddress != address(0));
        emit PerformanceFeeAddressSet(performanceFeeAddress, _performanceFeeAddress);
        performanceFeeAddress = _performanceFeeAddress;
    }

    function setStrategyPool(address _strategyPool) public onlyRole(2) {
        require(_strategyPool != address(0));
        emit StrategyPoolSet(strategyPool, _strategyPool);
        strategyPool = _strategyPool;
    }

    function setZBoofiStakingBips(uint256 _zBoofiStakingBips) external onlyRole(2) {
        require(zBoofiStaking != address(0), "not set yet");
        require(totalEndowmentBips + _zBoofiStakingBips <= MAX_BIPS);
        totalEndowmentBips -= zBoofiStakingBips;
        totalEndowmentBips += _zBoofiStakingBips;
        zBoofiStakingBips = _zBoofiStakingBips;
    }

    function setPriceUpdater(address _priceUpdater) external onlyRole(2) {
        require(_priceUpdater != address(0));
        emit PriceUpdaterSet(priceUpdater, _priceUpdater);
        priceUpdater = _priceUpdater;
    }

    function setBoofiEmission(uint256 newBoofiEmissionPerSecond) external onlyRole(3) {
        _globalUpdate();
        boofiEmissionPerSecond = newBoofiEmissionPerSecond;
        emit BoofiEmissionSet(newBoofiEmissionPerSecond);
    }

    function modifyApprovedContracts(address[] calldata contracts, bool[] calldata statuses) external onlyRole(4) {
        require(contracts.length == statuses.length, "inputs");
        for (uint256 i = 0; i < contracts.length; i++) {
            approvedContracts[contracts[i]] = statuses[i];
        }
    }

    function setAutoUpdatePrices(bool newStatus) external onlyRole(4) {
        autoUpdatePrices = newStatus;
    }

    function setOracle(address _oracle) external onlyRole(4) {
        emit OracleSet(oracle, _oracle);
        oracle = _oracle;
    }

    //STRATEGY MANAGEMENT FUNCTIONS
    function inCaseTokensGetStuck(address token, address to, uint256 amount) external onlyRole(5) {
        IBoofiStrategy strat = tokenParameters[token].strategy;
        strat.inCaseTokensGetStuck(IERC20(token), to, amount);
    }

    function setPerformanceFeeBips(IBoofiStrategy strat, uint256 newPerformanceFeeBips) external onlyRole(5) {
        strat.setPerformanceFeeBips(newPerformanceFeeBips);
    }

    //used to migrate from using one strategy to another
    function migrateStrategy(address token, IBoofiStrategy newStrategy) external onlyRole(5) {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //migrate funds from old strategy to new one
        tokenInfo.strategy.migrate(address(newStrategy));
        //update strategy in storage
        tokenInfo.strategy = newStrategy;
        newStrategy.onMigration();
    }

    //used in emergencies, or if setup of a strategy fails
    function setStrategy(address token, IBoofiStrategy newStrategy, bool transferOwnership, address newOwner) 
        external onlyRole(5) {
        TokenInfo storage tokenInfo = tokenParameters[token];
        if (transferOwnership) {
            tokenInfo.strategy.transferOwnership(newOwner);
        }
        tokenInfo.strategy = newStrategy;
    }

    //STRATEGY-ONLY FUNCTIONS
    //an autocompounding strategy calls this function to account for new LP tokens that it earns
    function accountAddedLP(address token, uint256 amount) external {
        TokenInfo storage tokenInfo = tokenParameters[token];
        require(msg.sender == address(tokenInfo.strategy), "only strategy");
        tokenInfo.totalTokens += amount;
    }

    //PRICE UPDATER-ONLY FUNCTIONS
    //update price of a single token
    function updatePrice(address token, uint256 newPrice) external {
        require(msg.sender == priceUpdater, "only priceUpdater");
        //perform global update to rewards
        _globalUpdate();
        _tokenPriceUpdate(token, newPrice);
    }

    //update prices for an array of tokens
    function updatePrices(address[] memory tokens, uint256[] memory newPrices) external {
        require(msg.sender == priceUpdater, "only priceUpdater");
        require(tokens.length == newPrices.length, "inputs");
        //perform global update to rewards
        _globalUpdate();
        for (uint256 i = 0; i < tokens.length; i++) {
            _tokenPriceUpdate(tokens[i], newPrices[i]);
        }
    }

    //INTERNAL FUNCTIONS
    function _deposit(address token, uint256 amount, address to) internal {
        require(approvedTokens[token], "token not approved for deposit");
        _updateTokenRewards(token);
        TokenInfo storage tokenInfo = tokenParameters[token];
        if (amount > 0) {
            UserInfo storage user = userInfo[token][to];
            //find number of new shares from amount
            uint256 newShares;
            if (tokenInfo.totalShares > 0) {
                newShares = (amount * tokenInfo.totalShares) / tokenInfo.totalTokens;
            } else {
                newShares = amount;
            }

            //transfer tokens directly to strategy
            IERC20(token).safeTransferFrom(address(msg.sender), address(tokenInfo.strategy), amount);
            //tell strategy to deposit newly transferred tokens and process update
            tokenInfo.strategy.deposit(msg.sender, to, amount, newShares);

            //track new shares
            tokenInfo.totalShares += newShares;
            user.amount += newShares;
            user.rewardDebt += int256((newShares * tokenInfo.accZBOOFIPerShare) / ACC_BOOFI_PRECISION);

            tokenInfo.totalTokens += amount;
            weightedTotalValueLocked += (tokenInfo.storedPrice * amount * tokenInfo.multiplier);

            //track deposit for profit tracking
            deposits[token][to] += amount;

            //rewarder logic
            IRewarder _rewarder = tokenInfo.rewarder;
            if (address(_rewarder) != address(0)) {
                _rewarder.onZBoofiReward(token, msg.sender, to, 0, user.amount - newShares, user.amount);
            }
            emit Deposit(msg.sender, token, amount, to);
        } 
    }

    function _harvest(address token, address to) internal {
        _updateTokenRewards(token);
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];

        //find all time ZBOOFI rewards for all of user's shares
        uint256 accumulatedZBoofi = (user.amount * tokenInfo.accZBOOFIPerShare) / ACC_BOOFI_PRECISION;
        //subtract out the rewards they have already been entitled to
        uint256 pendingZBoofi = _toUInt256(int256(accumulatedZBoofi) - user.rewardDebt);
        //update user reward debt
        user.rewardDebt = int256(accumulatedZBoofi);

        //handle BOOFI rewards
        if (pendingZBoofi != 0) {
            _safeZBOOFITransfer(to, pendingZBoofi);
        }

        //call strategy to update
        tokenInfo.strategy.withdraw(msg.sender, to, 0, 0);
        
        //rewarder logic
        IRewarder _rewarder = tokenInfo.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onZBoofiReward(token, msg.sender, to, pendingZBoofi, user.amount, user.amount);
        }

        emit Harvest(msg.sender, token, pendingZBoofi);
    }

    function _withdraw(address token, uint256 amountShares, address to) internal {
        _updateTokenRewards(token);
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];
        require(user.amount >= amountShares, "withdraw: too much");

        if (amountShares > 0 && tokenInfo.totalShares > 0) {
            //find amount of LP tokens from shares
            uint256 lpFromShares = (amountShares * tokenInfo.totalTokens) / tokenInfo.totalShares;

            if (tokenInfo.withdrawFeeBP > 0 && tokenInfo.totalShares > amountShares) {
                uint256 withdrawFee = (lpFromShares * tokenInfo.withdrawFeeBP) / MAX_BIPS;
                uint256 lpToSend = (lpFromShares - withdrawFee);
                //track withdrawal for profit tracking
                withdrawals[token][to] += lpToSend;
                //track removed LP
                tokenInfo.totalTokens -= lpToSend;
                weightedTotalValueLocked -= (tokenInfo.storedPrice * lpToSend * tokenInfo.multiplier);
                //tell strategy to withdraw lpTokens, send to 'to', and process update
                tokenInfo.strategy.withdraw(msg.sender, to, lpToSend, amountShares);
            } else {
                //track withdrawal for profit tracking
                withdrawals[token][to] += lpFromShares;
                //track removed LP
                tokenInfo.totalTokens -= lpFromShares;
                weightedTotalValueLocked -= (tokenInfo.storedPrice * lpFromShares * tokenInfo.multiplier);
                //tell strategy to withdraw lpTokens, send to 'to', and process update
                tokenInfo.strategy.withdraw(msg.sender, to, lpFromShares, amountShares);
            }
            //track removed shares
            user.amount -= amountShares;
            tokenInfo.totalShares -= amountShares;
            uint256 rewardDebtOfShares = ((amountShares * tokenInfo.accZBOOFIPerShare) / ACC_BOOFI_PRECISION);
            user.rewardDebt -= int256(rewardDebtOfShares);
            emit Withdraw(msg.sender, token, amountShares, to);
        }

        //rewarder logic
        IRewarder _rewarder = tokenInfo.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onZBoofiReward(token, msg.sender, to, 0, user.amount + amountShares, user.amount);
        }
    }

    function _withdrawAndHarvest(address token, uint256 amountShares, address to) internal {
        _updateTokenRewards(token);
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];
        require(user.amount >= amountShares, "withdraw: too much");

        //find all time ZBOOFI rewards for all of user's shares
        uint256 accumulatedZBoofi = (user.amount * tokenInfo.accZBOOFIPerShare) / ACC_BOOFI_PRECISION;
        //subtract out the rewards they have already been entitled to
        uint256 pendingZBoofi = _toUInt256(int256(accumulatedZBoofi) - user.rewardDebt);

        if (amountShares > 0 && tokenInfo.totalShares > 0) {
            //find amount of LP tokens from shares
            uint256 lpFromShares = (amountShares * tokenInfo.totalTokens) / tokenInfo.totalShares;

            if (tokenInfo.withdrawFeeBP > 0 && tokenInfo.totalShares > amountShares) {
                uint256 withdrawFee = (lpFromShares * tokenInfo.withdrawFeeBP) / MAX_BIPS;
                uint256 lpToSend = (lpFromShares - withdrawFee);
                //track withdrawal for profit tracking
                withdrawals[token][to] += lpToSend;
                //track removed LP
                tokenInfo.totalTokens -= lpToSend;
                weightedTotalValueLocked -= (tokenInfo.storedPrice * lpToSend * tokenInfo.multiplier);
                //tell strategy to withdraw lpTokens, send to 'to', and process update
                tokenInfo.strategy.withdraw(msg.sender, to, lpToSend, amountShares);
            } else {
                //track withdrawal for profit tracking
                withdrawals[token][to] += lpFromShares;
                //track removed LP
                tokenInfo.totalTokens -= lpFromShares;
                weightedTotalValueLocked -= (tokenInfo.storedPrice * lpFromShares * tokenInfo.multiplier);
                //tell strategy to withdraw lpTokens, send to 'to', and process update
                tokenInfo.strategy.withdraw(msg.sender, to, lpFromShares, amountShares);
            }
            //track removed shares
            user.amount -= amountShares;
            tokenInfo.totalShares -= amountShares;
            emit Withdraw(msg.sender, token, amountShares, to);
        }

        //update user reward debt
        user.rewardDebt = int256(accumulatedZBoofi);

        //handle BOOFI rewards
        if (pendingZBoofi != 0) {
            _safeZBOOFITransfer(to, pendingZBoofi);
        }

        //call strategy to update, if it has not been called already
        if (amountShares == 0) {
            tokenInfo.strategy.withdraw(msg.sender, to, 0, 0);
        }
        
        //rewarder logic
        IRewarder _rewarder = tokenInfo.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onZBoofiReward(token, msg.sender, to, pendingZBoofi, user.amount + amountShares, user.amount);
        }

        emit Harvest(msg.sender, token, pendingZBoofi);
    }

    function _emergencyWithdraw(address token, address to) internal {
        //skip token update
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];
        uint256 amountShares = user.amount;
        if (amountShares > 0 && tokenInfo.totalShares > 0) {
            //find amount of LP tokens from shares
            uint256 lpFromShares = (amountShares * tokenInfo.totalTokens) / tokenInfo.totalShares;

            if (tokenInfo.withdrawFeeBP > 0 && tokenInfo.totalShares > amountShares) {
                uint256 withdrawFee = (lpFromShares * tokenInfo.withdrawFeeBP) / MAX_BIPS;
                uint256 lpToSend = (lpFromShares - withdrawFee);
                //track withdrawal for profit tracking
                withdrawals[token][to] += lpToSend;
                //track removed LP
                tokenInfo.totalTokens -= lpToSend;
                //tell strategy to withdraw lpTokens, send to 'to', and process update
                tokenInfo.strategy.withdraw(msg.sender, to, lpToSend, amountShares);
            } else {
                //track withdrawal for profit tracking
                withdrawals[token][to] += lpFromShares;
                //track removed LP
                tokenInfo.totalTokens -= lpFromShares;
                //tell strategy to withdraw lpTokens, send to 'to', and process update
                tokenInfo.strategy.withdraw(msg.sender, to, lpFromShares, amountShares);
            }
            //track removed shares
            user.amount -= amountShares;
            tokenInfo.totalShares -= amountShares;
            //update user reward debt
            user.rewardDebt = 0;
            emit EmergencyWithdraw(msg.sender, token, amountShares, to);
        }

        //rewarder logic
        IRewarder _rewarder = tokenInfo.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onZBoofiReward(token, msg.sender, to, 0, amountShares, 0);
        }     
    }

    // Safe ZBOOFI transfer function, just in case if rounding error causes contract to not have enough ZBOOFIs.
    function _safeZBOOFITransfer(address _to, uint256 _amount) internal {
        uint256 boofiBal = ZBOOFI.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > boofiBal) {
            transferSuccess = ZBOOFI.transfer(_to, boofiBal);
        } else {
            transferSuccess = ZBOOFI.transfer(_to, _amount);
        }
        require(transferSuccess, "_safeZBOOFITransfer");
    }

    // Safe BOOFI transfer function, just in case if rounding error causes contract to not have enough BOOFIs.
    function _safeBOOFITransfer(address _to, uint256 _amount) internal {
        uint256 boofiBal = BOOFI.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > boofiBal) {
            transferSuccess = BOOFI.transfer(_to, boofiBal);
        } else {
            transferSuccess = BOOFI.transfer(_to, _amount);
        }
        require(transferSuccess, "_safeBOOFITransfer");
    }

    function _globalUpdate() internal {
        //only need to update a max of once per second. also skip all logic if no value locked
        if (block.timestamp > lastAvgUpdateTimestamp && weightedTotalValueLocked > 0) {
            uint256 newBOOFI  = (block.timestamp - lastAvgUpdateTimestamp) * boofiEmissionPerSecond;
            BOOFI.mint(address(this), newBOOFI);
            uint256 endowmentAmount = (newBOOFI * totalEndowmentBips) / MAX_BIPS;
            endowmentBal += endowmentAmount;
            uint256 finalAmount = newBOOFI - endowmentAmount;
            uint256 zboofiBefore = ZBOOFI.balanceOf(address(this));
            ZBOOFI.enter(finalAmount);
            uint256 newZBOOFI = ZBOOFI.balanceOf(address(this)) - zboofiBefore;
            //update global average for all pools
            //NOTE: large scaling here, as divisor is enormous
            cumulativeAvgZboofiPerWeightedValueLocked += (newZBOOFI * BOOFI_PRECISION_SQUARED) / weightedTotalValueLocked;
            //update stored value for last time of global update
            lastAvgUpdateTimestamp = block.timestamp;
        }
    }

    function _tokenUpdate(address token) internal {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //only need to update a max of once per second
        if (block.timestamp > tokenInfo.lastRewardTime && tokenInfo.totalShares > 0) {
            uint256 cumulativeRewardDiff = (cumulativeAvgZboofiPerWeightedValueLocked - tokenInfo.lastCumulativeReward);
            //NOTE: inverse scaling to that performed in calculating cumulativeAvgZboofiPerWeightedValueLocked
            uint256 zboofiReward = (cumulativeRewardDiff * tokenWeightedValueLocked(token)) / BOOFI_PRECISION_SQUARED;
            if (zboofiReward > 0) {
                tokenInfo.accZBOOFIPerShare += (zboofiReward * ACC_BOOFI_PRECISION) / tokenInfo.totalShares;
            }
            //update stored rewards for token
            tokenInfo.lastRewardTime = block.timestamp;
            tokenInfo.lastCumulativeReward = cumulativeAvgZboofiPerWeightedValueLocked;
        }
        //trigger automatic price update only if mechanic is enabled and caller is an EOA
        if (autoUpdatePrices && msg.sender == tx.origin) {
            uint256 newPrice = IOracle(oracle).getPrice(token);
            _tokenPriceUpdate(token, newPrice);
        }
    }

    function _tokenPriceUpdate(address token, uint256 newPrice) internal {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //subtract out old values
        weightedTotalValueLocked -= (tokenInfo.storedPrice * tokenInfo.totalTokens * tokenInfo.multiplier);
        //update price and add in new values
        tokenInfo.storedPrice = newPrice;
        weightedTotalValueLocked += (newPrice * tokenInfo.totalTokens * tokenInfo.multiplier);
    }

    function _updateTokenRewards(address token) internal {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //short circuit update if there are no deposits of the token or it has a zero multiplier
        uint256 tokenShares = tokenInfo.totalShares;
        if (tokenShares == 0 || tokenInfo.multiplier == 0) {
            tokenInfo.lastRewardTime = block.timestamp;
            tokenInfo.lastCumulativeReward = cumulativeAvgZboofiPerWeightedValueLocked;
            return;
        }
        // perform global update
        _globalUpdate();
        //perform update just for token
        _tokenUpdate(token); 
    }

    function _modifyApprovedToken(address token, bool status) internal {
        if (!approvedTokens[token] && status) {
            approvedTokens[token] = true;
            tokenListPosition[token] = tokenListLength();
            approvedTokenList.push(token);
        } else if (approvedTokens[token] && !status) {
            approvedTokens[token] = false;
            address lastTokenInList = approvedTokenList[tokenListLength() - 1];
            approvedTokenList[tokenListPosition[token]] = lastTokenInList;
            tokenListPosition[lastTokenInList] = tokenListPosition[token];
            approvedTokenList.pop();
        }
    }

    function _toUInt256(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return 0;
        } else {
            return uint256(a);
        }        
    }
}