/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

//chainlink oracle interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData() external view returns (
        uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt,uint80 answeredInRound);
}

//prediction contracts are owned by the PredictionFactory contract
contract Prediction is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Round {
        bool oracleCalled;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmount;
        uint256 bullBonusAmount;
        uint256 bearBonusAmount;
        int256 lockPrice;
        int256 closePrice;
    }

    struct Timestamps {
        uint32 startTimestamp;
        uint32 lockTimestamp;
        uint32 closeTimestamp;
    }

    enum Position {Bull, Bear, Undefined}

    struct BetInfo {
        Position position;
        uint256 amount;
        uint256 refereeAmount;
        uint256 referrerAmount;
        uint256 stakingAmount;
        bool claimed;
    }

    IERC20 public betToken;

    mapping(uint256 => Round) public rounds;
    mapping(uint256 => Timestamps) public timestamps;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256) public userReferenceBonuses;
    mapping(address => uint256) public totalUserReferenceBonuses;
    uint256 public currentEpoch;
    uint32 public intervalSeconds;
    uint256 public treasuryAmount;
    AggregatorV3Interface public oracle;
    uint256 public oracleLatestRoundId;

    uint256 public constant TOTAL_RATE = 100;
    uint256 public rewardRate;
    uint256 public treasuryRate;
    uint256 public referrerRate;
    uint256 public refereeRate;
    uint256 public minBetAmount;

    bool public genesisStartOnce = false;
    bool public genesisLockOnce = false;

    bool public initialized = false;

    IReferral public referralSystem;
    IStaker public staker;
    uint[] public stakingBonuses;

    event PredictionsStartRound(uint256 indexed epoch, uint256 blockNumber);
    event PredictionsLockRound(uint256 indexed epoch, uint256 blockNumber, int256 price);
    event PredictionsEndRound(uint256 indexed epoch, uint256 blockNumber, int256 price);
    event PredictionsPause(uint256 epoch);
    event PredictionsUnpause(uint256 epoch);
    event PredictionsBet(address indexed sender, uint256 indexed currentEpoch, uint256 amount, uint256 refereeAmount, uint256 stakingAmount, uint8 position);
    event PredictionsClaim(address indexed sender, uint256 indexed currentEpoch, uint256 amount);
    event PredictionsRewardsCalculated(uint256 indexed currentEpoch, uint8 position, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount);
    event PredictionsReferrerBonus(address indexed user, address indexed referrer, uint256 amount, uint256 indexed currentEpoch);
    event PredictionsSetReferralRates(uint256 currentEpoch, uint256 _referrerRate, uint256 _refereeRate);
    event PredictionsSetOracle(uint256 currentEpoch, address _oracle);
    event PredictionsSetTreasuryRate(uint256 currentEpoch, uint256 _treasuryRate);
    event PredictionsSetStakingLevelBonuses(uint256 currentEpoch, uint256[] _bonuses);

    constructor() {
        //index 0 for staking bonuses is always 0
        stakingBonuses.push(0);
    }

    function initialize(
        AggregatorV3Interface _oracle,
        uint32 _intervalSeconds,
        uint256 _minBetAmount,
        IERC20 _betToken,
        uint256 _treasuryRate,
        uint256 _referrerRate,
        uint256 _refereeRate,
        address _referralSystemAddress,
        address _stakerAddress
    ) external onlyOwner {
        require(!initialized);
        require(_treasuryRate <= 10, "<10");
        require(_referrerRate + _refereeRate <= 100, "<100");
        require(_minBetAmount > 100000, ">100000");

        initialized = true;

        oracle = _oracle;
        intervalSeconds = _intervalSeconds;
        minBetAmount = _minBetAmount;

        betToken = _betToken;

        rewardRate = TOTAL_RATE - _treasuryRate;
        treasuryRate = _treasuryRate;
        referrerRate = _referrerRate;
        refereeRate = _refereeRate;

        referralSystem = IReferral(_referralSystemAddress);
        staker = IStaker(_stakerAddress);
    }

    /**
     * @dev set interval blocks
     * callable by owner
     */
    function setIntervalSeconds(uint32 _intervalSeconds) external onlyOwner whenPaused {
        intervalSeconds = _intervalSeconds;
    }


    /**
     * @dev set Oracle address
     * callable by owner
     */
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0));
        oracle = AggregatorV3Interface(_oracle);
        emit PredictionsSetOracle(currentEpoch, _oracle);
    }

    /**
     * @dev set treasury rate
     * callable by owner
     */
    function setTreasuryRate(uint256 _treasuryRate) external onlyOwner {
        require(_treasuryRate <= 10, "<10");

        rewardRate = TOTAL_RATE - _treasuryRate;
        treasuryRate = _treasuryRate;
        
        emit PredictionsSetTreasuryRate(currentEpoch, _treasuryRate);
    }

    /**
     * @dev set minBetAmount
     * callable by owner
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyOwner {
        require(_minBetAmount > 100000, ">100000");
        minBetAmount = _minBetAmount;
    }

    /**
     * @dev Start genesis round
     */
    function genesisStartRound() external onlyOwner whenNotPaused {
        require(!genesisStartOnce);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        genesisStartOnce = true;
    }

    /**
     * @dev Lock genesis round, intervalSeconds is used as the buffer period
     */
    function genesisLockRound() external onlyOwner whenNotPaused {
        require(genesisStartOnce, "req genesisStart");
        require(!genesisLockOnce);
        require(block.timestamp <= timestamps[currentEpoch].lockTimestamp + intervalSeconds,">buffer");

        int256 currentPrice = _getPriceFromOracle();
        _safeLockRound(currentEpoch, currentPrice);

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        genesisLockOnce = true;
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function executeRound() external whenNotPaused {
        require(genesisStartOnce && genesisLockOnce, "req genesis");

        int256 currentPrice = _getPriceFromOracle();
        // CurrentEpoch refers to previous round (n-1)
        _safeLockRound(currentEpoch, currentPrice);
        _safeEndRound(currentEpoch - 1, currentPrice);
        _calculateRewards(currentEpoch - 1);

        // Increment currentEpoch to current round (n)
        currentEpoch = currentEpoch + 1;
        _safeStartRound(currentEpoch);
    }

    /**
     * @dev Bet bear position
     */
    function betBear(uint256 epoch, address user, uint256 amount) external whenNotPaused nonReentrant onlyOwner {
        require(epoch == currentEpoch, "Bet earlylate");
        require(_bettable(currentEpoch), "not bettable");
        require(amount >= minBetAmount);
        require(ledger[currentEpoch][user].amount == 0, "alreadybet");

        // Update round data
        Round storage round = rounds[currentEpoch];
        round.bearAmount = round.bearAmount + amount;

        //if the user has a referrer, set the referral bonuses and subtract it from the treasury amount
        uint refereeAmt = 0;
        uint referrerAmt = 0;
        uint stakingAmt = 0;
        uint treasuryAmt = amount * treasuryRate / TOTAL_RATE;
        
        //check and set referral bonuses
        if(referralSystem.hasReferrer(user))
        {
            refereeAmt = treasuryAmt * refereeRate / 100;
            referrerAmt = treasuryAmt * referrerRate / 100;
            round.bearBonusAmount = round.bearBonusAmount + refereeAmt + referrerAmt;
        }

        //check and set staking bonuses
        uint stakingLvl = staker.getUserStakingLevel(user);
        if(stakingLvl >= stakingBonuses.length)
            stakingLvl = stakingBonuses.length - 1;

        if(stakingLvl > 0)
        {
            stakingAmt = treasuryAmt * stakingBonuses[stakingLvl] / 100;
            round.bearBonusAmount = round.bearBonusAmount + stakingAmt;
        }

        //round treasury amount includes the staking and referral bonuses until the calculation
        //these amounts will be deducted on rewards calculation
        round.treasuryAmount = round.treasuryAmount + treasuryAmt;

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][user];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        betInfo.refereeAmount = refereeAmt;
        betInfo.referrerAmount = referrerAmt;
        betInfo.stakingAmount = stakingAmt;

        emit PredictionsBet(user, epoch, amount, refereeAmt, stakingAmt, uint8(Position.Bear));
    }

    /**
     * @dev Bet bull position
     */
    function betBull(uint256 epoch, address user, uint256 amount) external whenNotPaused nonReentrant onlyOwner {
        require(epoch == currentEpoch, "Bet earlylate");
        require(_bettable(currentEpoch), "not bettable");
        require(amount >= minBetAmount);
        require(ledger[currentEpoch][user].amount == 0, "alreadybet");

        // Update round data
        Round storage round = rounds[currentEpoch];
        round.bullAmount = round.bullAmount + amount;

        //if the user has a referrer, set the referral bonuses and subtract it from the treasury amount
        uint refereeAmt = 0;
        uint referrerAmt = 0;
        uint stakingAmt = 0;
        uint treasuryAmt = amount * treasuryRate / TOTAL_RATE;

        //check and set referral bonuses
        if(referralSystem.hasReferrer(user))
        {
            refereeAmt = treasuryAmt * refereeRate / 100;
            referrerAmt = treasuryAmt * referrerRate / 100;
            round.bullBonusAmount = round.bullBonusAmount + refereeAmt + referrerAmt;
        }

        //check and set staking bonuses
        uint stakingLvl = staker.getUserStakingLevel(user);
        if(stakingLvl >= stakingBonuses.length)
            stakingLvl = stakingBonuses.length - 1;

        if(stakingLvl > 0)
        {
            stakingAmt = treasuryAmt * stakingBonuses[stakingLvl] / 100;
            round.bullBonusAmount = round.bullBonusAmount + stakingAmt;
        }

        //round treasury amount includes the staking and referral bonuses until the calculation
        //these amounts will be deducted on rewards calculation
        round.treasuryAmount = round.treasuryAmount + treasuryAmt;

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][user];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        betInfo.refereeAmount = refereeAmt;
        betInfo.referrerAmount = referrerAmt;
        betInfo.stakingAmount = stakingAmt;

        emit PredictionsBet(user, epoch, amount, refereeAmt, stakingAmt, uint8(Position.Bull));
    }

    function hasReferenceBonus(address _user) external view returns (bool) {
        return userReferenceBonuses[_user] > 0;
    }

    function claimReferenceBonus(address _user) external nonReentrant onlyOwner {
        require(userReferenceBonuses[_user] > 0, "nobonuses");
        uint reward = userReferenceBonuses[_user];
        userReferenceBonuses[_user] = 0;
        betToken.safeTransfer(_user, reward);
    }

    /**
     * @dev Claim reward
     */
    function claim(address user, uint256[] calldata epochs) external nonReentrant onlyOwner {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(timestamps[epochs[i]].startTimestamp != 0);
            require(block.timestamp > timestamps[epochs[i]].closeTimestamp);

            uint256 addedReward = 0;
            BetInfo storage betInfo = ledger[epochs[i]][user];

            // Round valid, claim rewards
            if (rounds[epochs[i]].oracleCalled) {
                require(claimable(epochs[i], user), "No claim");
                Round memory round = rounds[epochs[i]];
                addedReward = betInfo.amount * round.rewardAmount / round.rewardBaseCalAmount + betInfo.refereeAmount + betInfo.stakingAmount;

                //if there is a referrer bonus, add it to that user's referrer bonus amount so they can claim it themselves
                if(betInfo.referrerAmount > 0)
                {
                    address referrerUser = referralSystem.getReferrer(user);
                    userReferenceBonuses[referrerUser] = userReferenceBonuses[referrerUser] + betInfo.referrerAmount;
                    totalUserReferenceBonuses[referrerUser] = totalUserReferenceBonuses[referrerUser] + betInfo.referrerAmount;

                    emit PredictionsReferrerBonus(user, referrerUser, betInfo.referrerAmount, epochs[i]);
                }
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(epochs[i], user), "No refund");
                addedReward = betInfo.amount;
            }

            betInfo.claimed = true;
            reward = reward + addedReward;

            emit PredictionsClaim(user, epochs[i], addedReward);
        }

        if (reward > 0) {
            betToken.safeTransfer(user, reward);
        }
    }

    /**
     * @dev Claim all rewards in treasury
     * callable by owner
     */
    function claimTreasury(address _recipient) external nonReentrant onlyOwner {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        betToken.safeTransfer(_recipient, currentTreasuryAmount);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();

        emit PredictionsPause(currentEpoch);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external onlyOwner whenPaused {
        genesisStartOnce = false;
        genesisLockOnce = false;
        _unpause();

        emit PredictionsUnpause(currentEpoch);
    }

    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled && betInfo.amount > 0 && !betInfo.claimed &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        return !round.oracleCalled && block.timestamp > (timestamps[epoch].closeTimestamp + intervalSeconds) && betInfo.amount != 0 && !betInfo.claimed;
    }

    function oracleInfo() external view returns (address) {
        return address(oracle);
    }

    /**
     * @dev Start round
     * Previous round n-2 must end
     */
    function _safeStartRound(uint256 epoch) internal {
        require(genesisStartOnce, "req gnsstart");
        require(timestamps[epoch - 2].closeTimestamp != 0);
        require(block.timestamp >= timestamps[epoch - 2].closeTimestamp);
        _startRound(epoch);
    }

    function _startRound(uint256 epoch) internal {
        Timestamps storage ts = timestamps[epoch];
        ts.startTimestamp = uint32(block.timestamp);
        ts.lockTimestamp = uint32(block.timestamp) + intervalSeconds;
        ts.closeTimestamp = uint32(block.timestamp) + (intervalSeconds * 2);

        emit PredictionsStartRound(epoch, block.timestamp);
    }

    /**
     * @dev Lock round, intervalSeconds is used as the buffer period
     */
    function _safeLockRound(uint256 epoch, int256 price) internal {
        require(timestamps[epoch].startTimestamp != 0);
        require(block.timestamp >= timestamps[epoch].lockTimestamp);
        require(block.timestamp <= timestamps[epoch].lockTimestamp + intervalSeconds, ">buffer");
        _lockRound(epoch, price);
    }

    function _lockRound(uint256 epoch, int256 price) internal {
        Round storage round = rounds[epoch];
        round.lockPrice = price;

        emit PredictionsLockRound(epoch, block.timestamp, round.lockPrice);
    }

    /**
     * @dev End round, intervalSeconds is used as the buffer period
     */
    function _safeEndRound(uint256 epoch, int256 price) internal {
        require(timestamps[epoch].lockTimestamp != 0);
        require(block.timestamp >= timestamps[epoch].closeTimestamp);
        require(block.timestamp <= timestamps[epoch].closeTimestamp + intervalSeconds, ">buffer");
        _endRound(epoch, price);
    }

    function _endRound(uint256 epoch, int256 price) internal {
        Round storage round = rounds[epoch];
        round.closePrice = price;
        round.oracleCalled = true;

        emit PredictionsEndRound(epoch, block.timestamp, round.closePrice);
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(uint256 epoch) internal {
        require(rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0);
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;
        uint8 position = uint8(Position.Undefined);
        // Bull wins
        if (round.closePrice > round.lockPrice) {
            rewardBaseCalAmount = round.bullAmount;
            //round treasury amount includes the referral bonuses at this stage, so deducting it from the total amount
            rewardAmount = round.bearAmount + round.bullAmount - round.treasuryAmount;
            //bonus amount from the fees of the winning side is deducted from the total treasury amount
            treasuryAmt = round.treasuryAmount - round.bullBonusAmount;
            position = uint8(Position.Bull);
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) {
            rewardBaseCalAmount = round.bearAmount;
            //round treasury amount includes the referral bonuses at this stage, so deducting it from the total amount
            rewardAmount = round.bearAmount + round.bullAmount - round.treasuryAmount;
            //bonus amount from the fees of the winning side is deducted from the total treasury amount
            treasuryAmt = round.treasuryAmount - round.bearBonusAmount;
            position = uint8(Position.Bear);
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = round.bearAmount + round.bullAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.treasuryAmount = treasuryAmt;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount = treasuryAmount + treasuryAmt;

        emit PredictionsRewardsCalculated(epoch, position, rewardBaseCalAmount, rewardAmount, treasuryAmt);
    }

    /**
     * @dev Get latest recorded price from oracle
     * If it has not updated, it would be invalid
     */
    function _getPriceFromOracle() internal returns (int256) {
        (uint80 roundId, int256 price, , , ) = oracle.latestRoundData();
        require(roundId > oracleLatestRoundId, "same oracle rnd");
        oracleLatestRoundId = uint256(roundId);
        return price;
    }

    /**
     * @dev Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current block must be within startTimestamp and lockTimestamp
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            timestamps[epoch].startTimestamp != 0 &&
            timestamps[epoch].lockTimestamp != 0 &&
            block.timestamp > timestamps[epoch].startTimestamp &&
            block.timestamp < timestamps[epoch].lockTimestamp;
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address _token, uint256 _amount, address receiver) external nonReentrant onlyOwner {
        IERC20(_token).safeTransfer(receiver, _amount);
    }

    function setReferralRates(uint256 _referrerRate, uint256 _refereeRate) external onlyOwner {
        require(_referrerRate + _refereeRate + stakingBonuses[stakingBonuses.length - 1] <= 100, "<100");
        referrerRate = _referrerRate;
        refereeRate = _refereeRate;

        emit PredictionsSetReferralRates(currentEpoch, _referrerRate, _refereeRate);
    }

    function setStaker(address _stakerAddress) external onlyOwner {
        staker = IStaker(_stakerAddress);
    }

    function setReferralSystem(address _referralSystemAddress) external onlyOwner {
        referralSystem = IReferral(_referralSystemAddress);
    }

    function setStakingLevelBonuses(uint256[] calldata _bonuses) external onlyOwner {
        require(_bonuses.length > 0 && _bonuses[0] == 0, "l0is0");
        require(_bonuses[_bonuses.length - 1] + refereeRate + referrerRate <= 100, "<100");
        for (uint256 i = 0; i < _bonuses.length - 1; i++) {
            require(_bonuses[i] <= _bonuses[i+1],"reqhigher");
        }
        stakingBonuses = _bonuses;
        emit PredictionsSetStakingLevelBonuses(currentEpoch, _bonuses);
    }

}

interface IStaker {
    function deposit(uint _amount, uint _stakingLevel) external returns (bool);
    function withdraw(uint256 _amount) external returns (bool);
    function getUserStakingLevel(address _user) external view returns (uint);
}

contract PredictionStaker is IStaker, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;

    struct stakingInfo {
        uint amount;
        uint releaseDate;
        uint stakingLevel;
        uint requiredAmount;
    }

    struct stakingType {
        uint duration;
        uint requiredAmount;
    }

    mapping(address => stakingInfo) public userStakeInfo; 
    mapping(uint => stakingType) public stakingLevels;
    uint public maxStakingLevel;

    event PredictionsStakingSetToken(address indexed tokenAddress);
    event PredictionsStakingSetLevel(uint levelNo, uint duration, uint requiredAmount);
    event PredictionsStakingDeposit(address indexed user, uint256 amount, uint256 stakingLevel, uint256 releaseDate);
    event PredictionsStakingWithdraw(address indexed user, uint256 amount, uint256 stakingLevel);

    function setStakingToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0));
        stakingToken = IERC20(_tokenAddress);
        emit PredictionsStakingSetToken(_tokenAddress);
    }

    function setStakingLevel(uint _levelNo, uint _duration, uint _requiredAmount) external onlyOwner {
        require(_levelNo > 0, "level 0 should be empty");

        stakingLevels[_levelNo].duration = _duration;
        stakingLevels[_levelNo].requiredAmount = _requiredAmount;
        if(_levelNo>maxStakingLevel)
        {
            maxStakingLevel = _levelNo;
        }
        emit PredictionsStakingSetLevel(_levelNo, _duration, _requiredAmount);
    }

    function getStakingLevel(uint _levelNo) external view returns (uint duration, uint requiredAmount) {
        require(_levelNo <= maxStakingLevel, "Given staking level does not exist.");
        require(_levelNo > 0, "level 0 is not available");
        return(stakingLevels[_levelNo].duration, stakingLevels[_levelNo].requiredAmount);
    }

    function deposit(uint _amount, uint _stakingLevel) override external returns (bool){
        require(_stakingLevel > 0, "level 0 is not available");
        require(_amount > 0, "amount is 0");
        require(maxStakingLevel >= _stakingLevel, "Given staking level does not exist.");
        require(userStakeInfo[msg.sender].stakingLevel < _stakingLevel, "User already has a higher or same stake");
        require(userStakeInfo[msg.sender].amount + _amount == stakingLevels[_stakingLevel].requiredAmount, "You need to stake required amount.");
        
        userStakeInfo[msg.sender].amount = userStakeInfo[msg.sender].amount + _amount;

        userStakeInfo[msg.sender].stakingLevel = _stakingLevel;
        userStakeInfo[msg.sender].requiredAmount = stakingLevels[_stakingLevel].requiredAmount;
        userStakeInfo[msg.sender].releaseDate = block.timestamp + stakingLevels[_stakingLevel].duration;

        emit PredictionsStakingDeposit(msg.sender, _amount, _stakingLevel, userStakeInfo[msg.sender].releaseDate);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        return true;
    }

    function withdraw(uint256 _amount) override external nonReentrant returns (bool) {
        require(userStakeInfo[msg.sender].amount >= _amount, "You do not have the entered amount.");
        require(userStakeInfo[msg.sender].releaseDate <= block.timestamp ||
                userStakeInfo[msg.sender].amount - _amount >= stakingLevels[userStakeInfo[msg.sender].stakingLevel].requiredAmount, 
                "You can't withdraw until your staking period is complete.");
        userStakeInfo[msg.sender].amount = userStakeInfo[msg.sender].amount - _amount;
        if(userStakeInfo[msg.sender].amount < stakingLevels[userStakeInfo[msg.sender].stakingLevel].requiredAmount)
        {
            userStakeInfo[msg.sender].stakingLevel = 0;
        }
        stakingToken.safeTransfer(msg.sender, _amount);

        emit PredictionsStakingWithdraw(msg.sender, _amount, userStakeInfo[msg.sender].stakingLevel);

        return true;
    }

    function getUserStakingLevel(address _user) override external view returns (uint) {
        return userStakeInfo[_user].stakingLevel;
    }

    function getUserBalance(address _user) external view returns (uint) {
        return userStakeInfo[_user].amount;
    }
}

interface IReferral {
    function hasReferrer(address user) external view returns (bool);
    function isLocked(address user) external view returns (bool);
    function lockAddress(address user) external;
    function setReferrer(address referrer) external;
    function getReferrer(address user) external view returns (address);
    function getReferredUsers(address referrer) external view returns (address[] memory) ;
}

contract PredictionReferral is IReferral, Ownable {
    //map of referred user to the their referrer
    mapping(address => address) public userReferrer; 
    //map of a user to an array of all users referred by them
    mapping(address => address[]) public referredUsers; 
    mapping(address => bool) public userExistence;
    mapping(address => bool) public userLocked;
    uint public referrerCount;
    uint public referredCount;
    address public factoryAddress;

    event PredictionsReferralEnable(address indexed user);
    event PredictionsSetReferrer(address indexed user, address indexed referrer);

    //set factory address that will send lock command
    function setFactory(address _factoryAddress) external onlyOwner {
        require(_factoryAddress != address(0));
        factoryAddress = _factoryAddress;
    }

    //address can only be locked from the factory contract
    function lockAddress(address user) override external {
        require(msg.sender == factoryAddress, "You dont have the permission to lock.");
        userLocked[user] = true;
    }

    function enableAddress() external {
        require(!userExistence[msg.sender], "This address is already enabled");
        userExistence[msg.sender] = true;

        emit PredictionsReferralEnable(msg.sender);
    }

    function setReferrer(address referrer) override external {
        require(userReferrer[msg.sender] == address(0), "You already have a referrer.");
        require(!userLocked[msg.sender], "You can not set a referrer after making a bet.");
        require(msg.sender != referrer, "You can not refer your own address.");
        require(userExistence[referrer], "The referrer address is not in the system.");
        userReferrer[msg.sender] = referrer;
        userLocked[msg.sender] = true;
        referredCount++;
        if(referredUsers[referrer].length == 0){
            referrerCount++;
        }
        referredUsers[referrer].push(msg.sender);

        emit PredictionsSetReferrer(msg.sender, referrer);
    }

    //GET FUNCTIONS

    function hasReferrer(address user) override external view virtual returns (bool) {
        return userReferrer[user] != address(0);
    }

    function isLocked(address user) override external view virtual returns (bool) {
        return userLocked[user];
    }

    function getReferrer(address user) override external view returns (address) {
        return userReferrer[user];
    }

    function getReferredUsers(address referrer) override external view returns (address[] memory) {
        return referredUsers[referrer];
    }
}

contract PredictionFactory is Ownable {
    using SafeERC20 for IERC20;
    
    uint256 public predictionCount;
    address public adminAddress;
    address public operatorAddress;

    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => IERC20) public betTokens;
 
    IReferral public referralSystem;
    IStaker public staker;

    constructor(
        address _adminAddress,
        address _operatorAddress,
        address _referralSystemAddress,
        address _stakerSystemAddress
    ) {
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        referralSystem = IReferral(_referralSystemAddress);
        staker = IStaker(_stakerSystemAddress);
    }

    function createPrediction(
        AggregatorV3Interface _oracle,
        uint32 _intervalSeconds,
        uint256 _minBetAmount,
        IERC20 _betToken,
        uint256 _treasuryRate,
        uint256 _referrerRate,
        uint256 _refereeRate
    ) external onlyAdmin {
        Prediction pred = new Prediction();

        betTokens[predictionCount] = _betToken;
        predictions[predictionCount++] = pred;

        pred.initialize(
            _oracle,
            _intervalSeconds,
            _minBetAmount,
            _betToken,
            _treasuryRate, 
            _referrerRate,    
            _refereeRate,   
            address(referralSystem),
            address(staker)
        );
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "no contract");
        require(msg.sender == tx.origin, "no proxy contract");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "adm");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "op");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "adm|op");
        _;
    }

    /**
     * @dev set admin address
     * callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0));
        adminAddress = _adminAddress;
    }

    /**
     * @dev set operator address
     * callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0));
        operatorAddress = _operatorAddress;
    }

    /**
     * @dev set interval Seconds
     * callable by admin
     */
    function setIntervalSeconds(uint256 _index, uint32 _intervalSeconds) external onlyAdmin {
        predictions[_index].setIntervalSeconds(_intervalSeconds);
    }

    /**
     * @dev set Oracle address
     * callable by admin
     */
    function setOracle(uint256 _index, address _oracle) external onlyAdmin {
        predictions[_index].setOracle(_oracle);
    }

    /**
     * @dev set treasury rate
     * callable by admin
     */
    function setTreasuryRate(uint256 _index, uint256 _treasuryRate) external onlyAdmin {
        predictions[_index].setTreasuryRate(_treasuryRate);
    }


    function setMinBetAmount(uint256 _index, uint256 _minBetAmount) external onlyAdmin {
        predictions[_index].setMinBetAmount(_minBetAmount);
    }

    /**
     * @dev Start genesis round
     */
    function genesisStartRound(uint256 _index) external onlyOperator {
        predictions[_index].genesisStartRound();
    }

    /**
     * @dev Lock genesis round
     */
    function genesisLockRound(uint256 _index) external onlyOperator {
        predictions[_index].genesisLockRound();
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function executeRound(uint256 _index) external {
        predictions[_index].executeRound();
    }

    /**
     * @dev Bet bear position
     */
    function betBear(uint256 _index, uint256 epoch, uint256 amount) external notContract {
        Prediction pred = predictions[_index];
        betTokens[_index].safeTransferFrom(msg.sender, address(pred), amount);
        pred.betBear(epoch, msg.sender, amount);
        if(!referralSystem.isLocked(msg.sender))
        {
            referralSystem.lockAddress(msg.sender);
        }
    }

    /**
     * @dev Bet bull position
     */
    function betBull(uint256 _index, uint256 epoch, uint256 amount) external notContract {
        Prediction pred = predictions[_index];
        betTokens[_index].safeTransferFrom(msg.sender, address(pred), amount);
        pred.betBull(epoch, msg.sender, amount);
        if(!referralSystem.isLocked(msg.sender))
        {
            referralSystem.lockAddress(msg.sender);
        }
    }

    function claimAllPredictions(uint256[] calldata indeces, uint256[][] calldata epochs) external notContract {
        require(indeces.length == epochs.length);
        for (uint256 i = 0; i < indeces.length; i++) {
            predictions[indeces[i]].claim(msg.sender, epochs[i]);
        }
    }

    function claim(uint256 _index, uint256[] calldata epochs) external notContract {
        predictions[_index].claim(msg.sender, epochs);
    }

    function claimAllReferenceBonuses(uint256[] calldata indeces) external notContract {
        for (uint256 i = 0; i < indeces.length; i++) {
            predictions[indeces[i]].claimReferenceBonus(msg.sender);
        }
    }

    function claimReferenceBonus(uint256 _index) external notContract {
        predictions[_index].claimReferenceBonus(msg.sender);
    }

    /**
     * @dev Claim all rewards in treasury
     * callable by admin
     */
    function claimTreasury(uint256 _index) external onlyAdmin {
        predictions[_index].claimTreasury(adminAddress);
    }

    /**
     * @dev called by the admin to pause, triggers stopped state
     */
    function pause(uint256 _index) external onlyAdminOrOperator {
        predictions[_index].pause();
    }

    /**
     * @dev called by the admin to unpause, returns to normal state
     */
    function unpause(uint256 _index) external onlyAdminOrOperator {
        predictions[_index].unpause();
    }

     /**
     * @dev It allows the owner to recover tokens sent to the contract by mistake
     */
    function recoverToken(uint256 _index, address _token, uint256 _amount) external onlyAdmin {
        predictions[_index].recoverToken(_token, _amount, msg.sender);
    }

    // Read Functions

    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function claimable(uint256 _index, uint256 epoch, address user) external view returns (bool) {
        return predictions[_index].claimable(epoch, user);
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     */
    function refundable(uint256 _index, uint256 epoch, address user) external view returns (bool) {
        return predictions[_index].refundable(epoch, user);
    }

    /**
     * @dev Get the oracle address for the specified prediction
     */
    function getOracleInfo(uint256 _index) external view returns (address) {
        return predictions[_index].oracleInfo();
    }


    //STAKING AND REFERENCE SYSTEM FUNCTIONS

    function setStaker(uint256 _index, address _stakerAddress) external onlyAdmin {
        staker = IStaker(_stakerAddress);
        predictions[_index].setStaker(_stakerAddress);
    }

    function setStakingLevelBonuses(uint256 _index, uint256[] calldata _bonuses) external onlyAdmin {
        predictions[_index].setStakingLevelBonuses(_bonuses);
    }

    function setReferralSystem(uint256 _index, address _referralSystemAddress) external onlyAdmin {
        referralSystem = IReferral(_referralSystemAddress);
        predictions[_index].setReferralSystem(_referralSystemAddress);
    }

    function setReferralRates(uint256 _index, uint256 _referrerRate, uint256 _refereeRate) external onlyAdmin {
        predictions[_index].setReferralRates(_referrerRate, _refereeRate);
    }
}