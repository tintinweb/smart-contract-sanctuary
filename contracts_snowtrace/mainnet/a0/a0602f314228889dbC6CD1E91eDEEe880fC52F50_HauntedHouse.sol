/**
 *Submitted for verification at snowtrace.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBOOFI is IERC20 {
    function mint(address dest, uint256 amount) external;
}

interface IZBOOFI is IERC20 {
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
    function currentExchangeRate() external view returns(uint256);
}

interface IRewarder {
    function onZBoofiReward(address depositToken, address user, address recipient, uint256 zboofiAmount, uint256 newShareAmount) external;
    function pendingTokens(address depositToken, address user, uint256 zboofiAmount) external view returns (address[] memory, uint256[] memory);
}

//owned by the HauntedHouse contract
interface IBoofiStrategy {
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(address caller, address to, uint256 tokenAmount, uint256 shareAmount) external;
    function inCaseTokensGetStuck(IERC20 token, address to, uint256 amount) external;
    function setAllowances() external;
    function revokeAllowance(address token, address spender) external;
    function migrate(address newStrategy) external;
    function onMigration() external;
    function pendingTokens(address depositToken, address user, uint256 boofiAmount) external view returns (address[] memory, uint256[] memory);
    function transferOwnership(address newOwner) external;
}

interface IOracle {
    function getPrice(address token) external returns (uint256);
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

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// The HauntedHouse is the master of BOOFI. He can make BOOFI and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BOOFI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract HauntedHouse is Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many shares the user currently has
        int256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each accepted token.
    struct TokenInfo {
        IRewarder rewarder; // Address of rewarder for token
        IBoofiStrategy strategy; // Address of strategy for token
        uint256 multiplier; // multiplier for this token
        uint256 lastRewardTime; // Last time that BOOFI distribution occurred for this token
        uint256 lastCumulativeReward; // Value of cumulativeAvgZboofiPerWeightedDollar at last update
        uint256 storedPrice; // Latest value of token
        uint256 accZBOOFIPerShare; // Accumulated BOOFI per share, times ACC_BOOFI_PRECISION.
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
        uint256 totalShares; //total number of shares for the token
        uint256 totalTokens; //total number of tokens deposited
    }

    // The BOOFI TOKEN!
    IBOOFI public immutable BOOFI;
    // The ZBOOFI TOKEN
    IZBOOFI public immutable ZBOOFI;
    // The timestamp when BOOFI mining starts.
    uint256 public startTime;

    // reward and approximate TVL tracking
    uint256 public totalValueLocked;
    uint256 public weightedTotalValueLocked;
    uint256 public cumulativeAvgZboofiPerWeightedDollar;
    uint256 public lastAvgUpdateTimestamp;

    //endowment addresses
    address public dev;
    address public marketingAndCommunity;
    address public foundation;
    //address to receive BOOFI purchased by strategies
    address public strategyPool;

    uint256 public constant devBips = 500;
    uint256 public constant marketingAndCommunityBips = 600;
    uint256 public constant foundationBips = 1400;
    uint256 public constant totalMintBips = 2500;

    //amount withdrawable by endowments
    uint256 public endowmentBal;

    //performance fee address -- receives performance fees from strategies
    address public performanceFeeAddress;
    //address that controls updating prices of deposited tokens
    address public priceUpdater;

    // amount of BOOFI emitted per second
    uint256 public boofiEmissionPerSecond;

    //whether the onlyApprovedContractOrEOA is turned on or off
    bool public onlyApprovedContractOrEOAStatus;

    //whether auto-updating of prices is turned on or off
    bool public autoUpdatePrices;
    //address of oracle for auto-updates
    address public oracle;

    uint256 internal constant ACC_BOOFI_PRECISION = 1e18;
    uint256 internal constant BOOFI_PRECISION_SQUARED = 1e36;
    uint256 internal constant MAX_BIPS = 10000;
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // list of currently approved tokens
    address[] public approvedTokenList;
    //mapping to track token positions in approvedTokenList
    mapping(address => uint256) public tokenListPosition;
    //mapping for tracking contracts approved to build on top of this one
    mapping(address => bool) public approvedContracts;
    //mapping for tracking whether or not a token is approved for deposit
    mapping(address => bool) public approvedTokens;
    // Info for all accepted tokens
    mapping(address => TokenInfo) public tokenParameters;
    // tracks if tokens have been added before, to ensure they are not added multiple times
    mapping(address => bool) public tokensAdded;
    // Info of each user that stakes tokens. stored as userInfo[token][userAddress]
    mapping(address => mapping(address => UserInfo)) public userInfo;
    //tracks historic deposits of each address. deposits[token][user] is the total deposits for that user of that token
    mapping(address => mapping(address => uint256)) public deposits;
    //tracks historic withdrawals of each address. deposits[token][user] is the total withdrawals for that user of that token
    mapping(address => mapping(address => uint256)) public withdrawals;

    /**
     * @notice Throws if called by non-approved smart contract
     */
    modifier onlyApprovedContractOrEOA() {
        if (onlyApprovedContractOrEOAStatus) {
            require(tx.origin == msg.sender || approvedContracts[msg.sender], "HauntedHouse::onlyApprovedContractOrEOA");
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
    event FoundationSet(address indexed oldAddress, address indexed newAddress);
    event StrategyPoolSet(address indexed oldAddress, address indexed newAddress);
    event OracleSet(address indexed oldAddress, address indexed newAddress);

    constructor(
        IBOOFI _BOOFI,
        IZBOOFI _ZBOOFI,
        uint256 _startTime,
        address _dev,
        address _marketingAndCommunity,
        address _foundation,
        address _strategyPool,
        uint256 _boofiEmissionPerSecond 
    ) {
        require(_startTime > block.timestamp, "must start in future");
        BOOFI = _BOOFI;
        ZBOOFI = _ZBOOFI;
        _BOOFI.approve(address(_ZBOOFI), MAX_UINT);
        startTime = _startTime;
        dev = _dev;
        marketingAndCommunity = _marketingAndCommunity;
        foundation = _foundation;
        strategyPool = _strategyPool;
        boofiEmissionPerSecond = _boofiEmissionPerSecond;
        //update this value so function '_globalUpdate()' will do nothing before _startTime
        lastAvgUpdateTimestamp = _startTime;
        emit DevSet(address(0), _dev);
        emit MarketingAndCommunitySet(address(0), _marketingAndCommunity);
        emit FoundationSet(address(0), _foundation);
        emit StrategyPoolSet(address(0), _strategyPool);
        emit BoofiEmissionSet(_boofiEmissionPerSecond);
    }

    //VIEW FUNCTIONS
    function tokenListLength() public view returns (uint256) {
        return approvedTokenList.length;
    }

    // returns full array of currently approved tokens
    function tokenList() public view returns (address[] memory) {
        address[] memory tokens = new address[](tokenListLength());
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = approvedTokenList[i];
        }
        return tokens;
    }

    // View function to see total pending reward in zBOOFI on frontend.
    function pendingZBOOFI(address token, address userAddress) public view returns (uint256) {
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][userAddress];
        uint256 accZBOOFIPerShare = tokenInfo.accZBOOFIPerShare;
        uint256 poolShares = tokenInfo.totalShares;
        //mimic global update
        uint256 globalCumulativeAverage = cumulativeAvgZboofiPerWeightedDollar;
        if (block.timestamp > lastAvgUpdateTimestamp) {
            uint256 newBOOFI  = reward(lastAvgUpdateTimestamp, block.timestamp);
            uint256 endowmentAmount = (newBOOFI * totalMintBips) / MAX_BIPS;
            uint256 finalAmount = newBOOFI - endowmentAmount;
            //convert BOOFI to zBOOFI. factor of 1e18 is because of exchange rate scaling
            uint256 newZBOOFI = (finalAmount * 1e18) / ZBOOFI.currentExchangeRate();
            //NOTE: large scaling here, as divisor is enormous
            globalCumulativeAverage += (newZBOOFI * BOOFI_PRECISION_SQUARED) / weightedTotalValueLocked;
        }
        //mimic single token update
        if (block.timestamp > tokenInfo.lastRewardTime) {
            uint256 cumulativeRewardDiff = (cumulativeAvgZboofiPerWeightedDollar - tokenInfo.lastCumulativeReward);
            //NOTE: inverse scaling to that performed in calculating cumulativeAvgZboofiPerWeightedDollar
            uint256 zboofiReward = (cumulativeRewardDiff * tokenWeightedValueLocked(token)) / BOOFI_PRECISION_SQUARED;
            if (zboofiReward > 0) {
                accZBOOFIPerShare += (zboofiReward * ACC_BOOFI_PRECISION) / poolShares;
            }
        }
        return _toUInt256(int256((user.amount * accZBOOFIPerShare) / ACC_BOOFI_PRECISION) - user.rewardDebt);
    }

    // view function to get all pending rewards, from HauntedHouse, Strategy, and Rewarder
    function pendingTokens(address token, address user) external view 
        returns (address[] memory, uint256[] memory) {
        uint256 zboofiAmount = pendingZBOOFI(token, user);
        (address[] memory strategyTokens, uint256[] memory strategyRewards) = 
            tokenParameters[token].strategy.pendingTokens(token, user, zboofiAmount);
        address[] memory rewarderTokens;
        uint256[] memory rewarderRewards;
        if (address(tokenParameters[token].rewarder) != address(0)) {
            (rewarderTokens, rewarderRewards) = 
                tokenParameters[token].rewarder.pendingTokens(token, user, zboofiAmount);
        }
        //default number of rewards for just zBOOFI
        uint256 rewardsLength = 1; 
        for (uint256 i = 0; i < rewarderTokens.length; i++) {
            rewardsLength += 1;
        }
        for (uint256 j = 0; j < strategyTokens.length; j++) {
            if (strategyTokens[j] != address(0)) {
                rewardsLength += 1;
            }
        }
        address[] memory _rewardTokens = new address[](rewardsLength);
        uint256[] memory _pendingAmounts = new uint256[](rewardsLength);
        _rewardTokens[0] = address(ZBOOFI);
        _pendingAmounts[0] = pendingZBOOFI(token, user);
        for (uint256 k = 0; k < rewarderTokens.length; k++) {
            _rewardTokens[k + 2] = rewarderTokens[k];
            _pendingAmounts[k + 2] = rewarderRewards[k];
        }
        for (uint256 m = 0; m < strategyTokens.length; m++) {
            if (strategyTokens[m] != address(0)) {
                _rewardTokens[m + 2 + rewarderTokens.length] = strategyTokens[m];
                _pendingAmounts[m + 2 + rewarderRewards.length] = strategyRewards[m];                
            }
        }
        return(_rewardTokens, _pendingAmounts);
    }

    //returns user profits in LP (returns zero in the event that user has losses due to previous withdrawal fees)
    function profitInLP(address token, address userAddress) public view returns(uint256) {
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][userAddress];
        uint256 userDeposits = deposits[token][userAddress];
        uint256 userWithdrawals = withdrawals[token][userAddress];
        uint256 lpFromShares = (user.amount * tokenInfo.totalTokens) / tokenInfo.totalShares;
        uint256 totalAssets = userWithdrawals + lpFromShares;
        if(totalAssets >= userDeposits) {
            return (totalAssets - userDeposits);
        } else {
            return 0;
        }
    }

    // Return reward over the period _from to _to.
    function reward(uint256 _lastRewardTime, uint256 _currentTime) public view returns (uint256) {
        return ((_currentTime - _lastRewardTime) * boofiEmissionPerSecond);
    }

    //convenience function to get the annualized emission of BOOFI at the current emission rate, after endowment distribution
    function boofiPerYear() public view returns (uint256) {
        //31536000 = seconds per year = 365 * 24 * 60 * 60
        return (boofiEmissionPerSecond * 31536000) * (MAX_BIPS - totalMintBips) / MAX_BIPS;
    }

    //convenience function to get the annualized emission of zBOOFI at the current emission rate, at the current exchange rate
    function zboofiPerYear() public view returns (uint256) {
        return (boofiPerYear() * 1e18) / ZBOOFI.currentExchangeRate();
    }

    //convenience function to get the emission of zBOOFI per second at the current emission rate, at the current exchange rate
    function zboofiPerSecond() public view returns (uint256) {
        return (boofiEmissionPerSecond * 1e18) / ZBOOFI.currentExchangeRate();
    }

    //function to get current value locked from a single token
    function tokenValueLocked(address token) public view returns (uint256) {
        return (tokenParameters[token].totalTokens * tokenParameters[token].storedPrice);
    }

    //get current value locked for a single token, multiplied by the token's multiplier
    function tokenWeightedValueLocked(address token) public view returns (uint256) {
        return (tokenValueLocked(token) * tokenParameters[token].multiplier);
    }

    //convenience function to get the annualized emission of ZBOOFI at the current emission + exchange rates, to depositors of a given token
    function zboofiPerYearToToken(address token) public view returns(uint256) {
        return ((zboofiPerYear() * tokenWeightedValueLocked(token)) / weightedTotalValueLocked);
    }

    //convenience function to get the shares of a single user for a token
    function userShares(address token, address user) public view returns(uint256) {
        return userInfo[token][user].amount;
    }

    //WRITE FUNCTIONS
    /// @notice Update reward variables of the given token.
    /// @param token The address of the deposited token.
    function updateTokenRewards(address token) public onlyApprovedContractOrEOA {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //short circuit update if there are no deposits of the token or it has a zero multiplier
        uint256 tokenShares = tokenInfo.totalShares;
        if (tokenShares == 0 || tokenInfo.multiplier == 0) {
            tokenInfo.lastRewardTime = block.timestamp;
            tokenInfo.lastCumulativeReward = cumulativeAvgZboofiPerWeightedDollar;
            return;
        }
        // perform global update
        _globalUpdate();
        //perform update just for token
        _tokenUpdate(token);
    }

    // Update reward variables for all approved tokens. Be careful of gas spending!
    function massUpdateTokens() public onlyApprovedContractOrEOA {
        uint256 length = tokenListLength();
        _globalUpdate();
        for (uint256 i = 0; i < length; i++) {
            _tokenUpdate(approvedTokenList[i]);
        }
    }

    /// @notice Deposit tokens to HauntedHouse for BOOFI allocation.
    /// @param token The address of the token to deposit
    /// @param amount Token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(address token, uint256 amount, address to) external onlyApprovedContractOrEOA {
        require(approvedTokens[token], "token is not approved for deposit");
        updateTokenRewards(token);
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
            uint256 newValueLocked = tokenInfo.storedPrice * amount;
            totalValueLocked += newValueLocked;
            weightedTotalValueLocked += (newValueLocked * tokenInfo.multiplier);

            //track deposit for profit tracking
            deposits[token][to] += amount;

            //rewarder logic
            IRewarder _rewarder = tokenInfo.rewarder;
            if (address(_rewarder) != address(0)) {
                _rewarder.onZBoofiReward(token, msg.sender, to, 0, user.amount);
            }
            emit Deposit(msg.sender, token, amount, to);
        }
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param token The address of the deposited token.
    /// @param to Receiver of BOOFI rewards.
    function harvest(address token, address to) external onlyApprovedContractOrEOA {
        updateTokenRewards(token);
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
            _rewarder.onZBoofiReward(token, msg.sender, to, pendingZBoofi, user.amount);
        }

        emit Harvest(msg.sender, token, pendingZBoofi);
    }

    /// @notice Withdraw tokens from HauntedHouse.
    /// @param token The address of the withdrawn token.
    /// @param amountShares amount of shares to withdraw.
    /// @param to Receiver of the tokens.
    function withdraw(address token, uint256 amountShares, address to) external onlyApprovedContractOrEOA {
        updateTokenRewards(token);
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];
        require(user.amount >= amountShares, "withdraw: not good");

        if (amountShares > 0) {
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
            uint256 rewardDebtOfShares = ((amountShares * tokenInfo.accZBOOFIPerShare) / ACC_BOOFI_PRECISION);
            user.rewardDebt -= int256(rewardDebtOfShares);
            emit Withdraw(msg.sender, token, amountShares, to);
        }

        //rewarder logic
        IRewarder _rewarder = tokenInfo.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onZBoofiReward(token, msg.sender, to, 0, user.amount);
        }
    }

    /// @notice Withdraw LP tokens from HauntedHouse.
    /// @param token The address of the withdrawn token.
    /// @param amountShares amount of shares to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdrawAndHarvest(address token, uint256 amountShares, address to) external onlyApprovedContractOrEOA {
        updateTokenRewards(token);
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];
        require(user.amount >= amountShares, "withdraw: not good");

        //find all time ZBOOFI rewards for all of user's shares
        uint256 accumulatedZBoofi = (user.amount * tokenInfo.accZBOOFIPerShare) / ACC_BOOFI_PRECISION;
        //subtract out the rewards they have already been entitled to
        uint256 pendingZBoofi = _toUInt256(int256(accumulatedZBoofi) - user.rewardDebt);

        if (amountShares > 0) {
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
            _rewarder.onZBoofiReward(token, msg.sender, to, pendingZBoofi, user.amount);
        }

        emit Harvest(msg.sender, token, pendingZBoofi);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param token The address of the withdrawn token.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(address token, address to) external onlyApprovedContractOrEOA {
        //skip token update
        TokenInfo storage tokenInfo = tokenParameters[token];
        UserInfo storage user = userInfo[token][msg.sender];
        uint256 amountShares = user.amount;
        if (amountShares > 0) {
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
            _rewarder.onZBoofiReward(token, msg.sender, to, 0, 0);
        }        
    }

    //distribute pending endowment funds. callable by anyone.
    function distributeEndowment() external {
        uint256 totalToSend = endowmentBal;
        endowmentBal = 0;
        uint256 toDev = (totalToSend * devBips) / MAX_BIPS;
        uint256 toMarketingAndCommunity = (totalToSend * marketingAndCommunityBips) / MAX_BIPS;
        uint256 toFoundation = (totalToSend * foundationBips) / MAX_BIPS;
        _safeZBOOFITransfer(dev, toDev);
        _safeZBOOFITransfer(marketingAndCommunity, toMarketingAndCommunity);
        _safeZBOOFITransfer(foundation, toFoundation);
    }

    //OWNER-ONLY FUNCTIONS
    //needs to be public as it can be called internally, inside the 'add' function
    function addApprovedToken(address token) public onlyOwner {
        require(!approvedTokens[token], "token already approved");
        approvedTokens[token] = true;
        tokenListPosition[token] = tokenListLength();
        approvedTokenList.push(token);
    }

    function removeApprovedToken(address token) external onlyOwner {
        require(approvedTokens[token], "token already not approved");
        approvedTokens[token] = false;
        address lastTokenInList = approvedTokenList[tokenListLength() - 1];
        tokenListPosition[lastTokenInList] = tokenListPosition[token];
        approvedTokenList.pop();
    }

    /// @notice Add parameters to a new token. Can only be called by the owner.
    /// @param token the token address
    /// @param _withdrawFeeBP withdrawal fee of the token.
    /// @param _multiplier token multiplier for weighted TVL
    /// @param _rewarder Address of the rewarder delegate.
    /// @param _strategy Address of the strategy delegate.
    function add(address token, uint16 _withdrawFeeBP, uint256 _multiplier, IRewarder _rewarder, IBoofiStrategy _strategy)
        external onlyOwner {
        require(
            _withdrawFeeBP <= 1000,
            "add: withdrawal fee input too high"
        );
        //track adding token
        require(!tokensAdded[token], "cannot add same token twice");
        tokensAdded[token] = true;
        //approve token if it is not already approved
        if (!approvedTokens[token]) {
            addApprovedToken(token);
        }
        //do global update to rewards before adding new token
        _globalUpdate();
        uint256 _lastRewardTime =
            block.timestamp > startTime ? block.timestamp : startTime;
        tokenParameters[token] = (
            TokenInfo({
                rewarder: _rewarder, // Address of rewarder for token
                strategy: _strategy, // Address of strategy for token
                multiplier: _multiplier, // multiplier for this token
                lastRewardTime: _lastRewardTime, // Last time that BOOFI distribution occurred for this token
                lastCumulativeReward: cumulativeAvgZboofiPerWeightedDollar, // Value of cumulativeAvgZboofiPerWeightedDollar at last update
                storedPrice: 0, // Latest value of token
                accZBOOFIPerShare: 0, // Accumulated BOOFI per share, times ACC_BOOFI_PRECISION.
                withdrawFeeBP: _withdrawFeeBP, // Withdrawal fee in basis points
                totalShares: 0, //total number of shares for the token
                totalTokens: 0 //total number of tokens deposited
            })
        );
    }

    /// @notice Update the given tokens parameters. Can only be called by the owner.
    /// @param token the token address
    /// @param _withdrawFeeBP New withdrawal fee of the token.
    /// @param _multiplier new token multiplier for weighted TVL
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(
        address token, 
        uint16 _withdrawFeeBP,
        uint256 _multiplier,
        IRewarder _rewarder,
        bool overwrite
    ) external onlyOwner {
        require(
            _withdrawFeeBP <= 1000,
            "set: withdrawal fee input too high"
        );
        //do global update to rewards before updating token
        _globalUpdate();
        tokenParameters[token].withdrawFeeBP = _withdrawFeeBP;
        weightedTotalValueLocked -= tokenWeightedValueLocked(token);
        tokenParameters[token].multiplier = _multiplier;
        weightedTotalValueLocked += tokenWeightedValueLocked(token);
        if (overwrite) { tokenParameters[token].rewarder = _rewarder; }
    }

    //used to migrate from using one strategy to another
    function migrateStrategy(address token, IBoofiStrategy newStrategy) external onlyOwner {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //migrate funds from old strategy to new one
        tokenInfo.strategy.migrate(address(newStrategy));
        //update strategy in storage
        tokenInfo.strategy = newStrategy;
        newStrategy.onMigration();
    }

    //used in emergencies, or if setup of a strategy fails
    function setStrategy(address token, IBoofiStrategy newStrategy, bool transferOwnership, address newOwner) 
        external onlyOwner {
        TokenInfo storage tokenInfo = tokenParameters[token];
        if (transferOwnership) {
            tokenInfo.strategy.transferOwnership(newOwner);
        }
        tokenInfo.strategy = newStrategy;
    }

    function manualMint(address dest, uint256 amount) external onlyOwner {
        BOOFI.mint(dest, amount);
    }

    function setDev(address _dev) external onlyOwner {
        require(_dev != address(0));
        emit DevSet(dev, _dev);
        dev = _dev;
    }

    function setMarketingAndCommunity(address _marketingAndCommunity) external onlyOwner {
        require(_marketingAndCommunity != address(0));
        emit MarketingAndCommunitySet(marketingAndCommunity, _marketingAndCommunity);
        marketingAndCommunity = _marketingAndCommunity;
    }

    function setFoundation(address _foundation) external onlyOwner {
        require(_foundation != address(0));
        emit FoundationSet(foundation, _foundation);
        foundation = _foundation;
    }

    function setStrategyPool(address _strategyPool) external onlyOwner {
        require(_strategyPool != address(0));
        emit StrategyPoolSet(strategyPool, _strategyPool);
        strategyPool = _strategyPool;
    }

    function setPriceUpdater(address _priceUpdater) external onlyOwner {
        require(_priceUpdater != address(0));
        priceUpdater = _priceUpdater;
    }

    function setBoofiEmission(uint256 newBoofiEmissionPerSecond) external onlyOwner {
        _globalUpdate();
        boofiEmissionPerSecond = newBoofiEmissionPerSecond;
        emit BoofiEmissionSet(newBoofiEmissionPerSecond);
    }

    //ACCESS CONTROL FUNCTIONS
    function modifyApprovedContracts(address[] calldata contracts, bool[] calldata statuses) external onlyOwner {
        require(contracts.length == statuses.length, "input length mismatch");
        for (uint256 i = 0; i < contracts.length; i++) {
            approvedContracts[contracts[i]] = statuses[i];
        }
    }

    function setOnlyApprovedContractOrEOAStatus(bool newStatus) external onlyOwner {
        onlyApprovedContractOrEOAStatus = newStatus;
    }

    function setAutoUpdatePrices(bool newStatus) external onlyOwner {
        autoUpdatePrices = newStatus;
    }

    function setOracle(address _oracle) external onlyOwner {
        emit OracleSet(oracle, _oracle);
        oracle = _oracle;
    }

    //STRATEGY MANAGEMENT FUNCTIONS
    function inCaseTokensGetStuck(address token, address to, uint256 amount) external onlyOwner {
        IBoofiStrategy strat = tokenParameters[token].strategy;
        strat.inCaseTokensGetStuck(IERC20(token), to, amount);
    }

    function setAllowances(address token) external onlyOwner {
        IBoofiStrategy strat = tokenParameters[token].strategy;
        strat.setAllowances();
    }

    function revokeAllowance(address token, address targetToken, address spender) external onlyOwner {
        IBoofiStrategy strat = tokenParameters[token].strategy;
        strat.revokeAllowance(targetToken, spender);
    }

    //STRATEGY-ONLY FUNCTIONS
    //an autocompounding strategy calls this function to account for new LP tokens that it earns
    function accountAddedLP(address token, uint256 amount) external {
        TokenInfo storage tokenInfo = tokenParameters[token];
        require(msg.sender == address(tokenInfo.strategy), "only callable by strategy contract");
        tokenInfo.totalTokens += amount;
    }

    //PRICE UPDATER-ONLY FUNCTIONS
    //update price of a single token
    function updatePrice(address token, uint256 newPrice) external {
        require(msg.sender == priceUpdater, "only callable by priceUpdater");
        _updatePrice(token, newPrice);
    }

    //update prices for an array of tokens
    function updatePrices(address[] memory tokens, uint256[] memory newPrices) external {
        require(msg.sender == priceUpdater, "only callable by priceUpdater");
        _updatePrices(tokens, newPrices);
    }

    //INTERNAL FUNCTIONS
    // Safe ZBOOFI transfer function, just in case if rounding error causes contract to not have enough ZBOOFIs.
    function _safeZBOOFITransfer(address _to, uint256 _amount) internal {
        uint256 boofiBal = ZBOOFI.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > boofiBal) {
            transferSuccess = ZBOOFI.transfer(_to, boofiBal);
        } else {
            transferSuccess = ZBOOFI.transfer(_to, _amount);
        }
        require(transferSuccess, "_safeZBOOFITransfer: transfer failed");
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
        require(transferSuccess, "_safeBOOFITransfer: transfer failed");
    }

    function _globalUpdate() internal {
        //only need to update a max of once per second. also skip all logic if no value locked
        if (block.timestamp > lastAvgUpdateTimestamp && weightedTotalValueLocked > 0) {
            uint256 newBOOFI  = reward(lastAvgUpdateTimestamp, block.timestamp);
            BOOFI.mint(address(this), newBOOFI);
            uint256 endowmentAmount = (newBOOFI * totalMintBips) / MAX_BIPS;
            endowmentBal += endowmentAmount;
            uint256 finalAmount = newBOOFI - endowmentAmount;
            uint256 zboofiBefore = ZBOOFI.balanceOf(address(this));
            ZBOOFI.enter(finalAmount);
            uint256 newZBOOFI = ZBOOFI.balanceOf(address(this)) - zboofiBefore;
            //update global average for all pools
            //NOTE: large scaling here, as divisor is enormous
            cumulativeAvgZboofiPerWeightedDollar += (newZBOOFI * BOOFI_PRECISION_SQUARED) / weightedTotalValueLocked;
            //update stored value for last time of global update
            lastAvgUpdateTimestamp = block.timestamp;
        }
    }

    function _tokenUpdate(address token) internal {
        TokenInfo storage tokenInfo = tokenParameters[token];
        //only need to update a max of once per second
        if (block.timestamp > tokenInfo.lastRewardTime) {
            uint256 cumulativeRewardDiff = (cumulativeAvgZboofiPerWeightedDollar - tokenInfo.lastCumulativeReward);
            //NOTE: inverse scaling to that performed in calculating cumulativeAvgZboofiPerWeightedDollar
            uint256 zboofiReward = (cumulativeRewardDiff * tokenWeightedValueLocked(token)) / BOOFI_PRECISION_SQUARED;
            if (zboofiReward > 0) {
                tokenInfo.accZBOOFIPerShare += (zboofiReward * ACC_BOOFI_PRECISION) / tokenInfo.totalShares;
            }
            //update stored rewards for token
            tokenInfo.lastRewardTime = block.timestamp;
            tokenInfo.lastCumulativeReward = cumulativeAvgZboofiPerWeightedDollar;
        }
        if (autoUpdatePrices) {
            uint256 newPrice = IOracle(oracle).getPrice(token);
            _updatePrice(token, newPrice);
        }
    }

    function _toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }

    function _updatePrice(address token, uint256 newPrice) internal {
        //perform global update to rewards
        _globalUpdate();
        TokenInfo storage tokenInfo = tokenParameters[token];
        //subtract out old values
        uint256 oldValueLocked = tokenInfo.storedPrice * tokenInfo.totalTokens;
        totalValueLocked -= oldValueLocked;
        weightedTotalValueLocked -= (oldValueLocked * tokenInfo.multiplier);
        //update price and add in new values
        tokenInfo.storedPrice = newPrice;
        uint256 newValueLocked = newPrice * tokenInfo.totalTokens;
        totalValueLocked += newValueLocked;
        weightedTotalValueLocked += (newValueLocked * tokenInfo.multiplier);
    }

    function _updatePrices(address[] memory tokens, uint256[] memory newPrices) internal {
        require(tokens.length == newPrices.length, "input length mismatch");
        //perform global update to rewards
        _globalUpdate();
        for (uint256 i = 0; i < tokens.length; i++) {
            TokenInfo storage tokenInfo = tokenParameters[tokens[i]];
            //subtract out old values
            uint256 oldValueLocked = tokenInfo.storedPrice * tokenInfo.totalTokens;
            totalValueLocked -= oldValueLocked;
            weightedTotalValueLocked -= (oldValueLocked * tokenInfo.multiplier);
            //update price and add in new values
            tokenInfo.storedPrice = newPrices[i];
            uint256 newValueLocked = newPrices[i] * tokenInfo.totalTokens;
            totalValueLocked += newValueLocked;
            weightedTotalValueLocked += (newValueLocked * tokenInfo.multiplier);
        }
    }
}