/**
 *Submitted for verification at polygonscan.com on 2021-11-28
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

interface IRandomNumberConsumer {
    function getRandom(uint256 lotteryId) external;
}

interface IRaffle {
    function fulfill_random(uint) external;
    function addUserTicket(address _userAddress, uint256 ticketAmount) external;
    function addBalance() external payable;
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

interface IReference {
    function hasReferrer(address user) external view returns (bool);
    function setReferrer(address referrer) external;
    function getReferrer(address user) external view returns (address);
}

contract HippoPrediction is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //raffle variables
    IRaffle public raffle;
    uint256 public raffleTicketNormalizer = 10000000000000000;
    uint256 public raffleLogMultiplier = 15; //times 10
    uint256 public rewardTicketAmountForExecuteRound = 10;
    uint256 public rewardTicketAmountForCompleteVoting = 10;
    //------

    address public adminAddress; // address of the admin

    uint32 public intervalSeconds; // interval in seconds between two prediction rounds

    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate x10
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public raffleRate; // percent of treasury fee that will be sent to the raffle contract

    uint256 public currentEpoch; // current epoch for prediction round

    uint256 public constant MAX_TREASURY_FEE = 100; // 10%

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => Timestamps) public timestamps;
    mapping(address => uint256[]) public userRounds;

    //reference variables
    IReference public referenceSystem;
    uint256 public referrerBonus;
    uint256 public refereeBonus;
    mapping(address => uint256) public referrerBonuses; //keep referrer bonuses in a mapping, so they can claim total amount themselves
    //----------------

    //voting variables
    mapping(address => bool) public oracleExistence;
    address public selectedOracle;
    address public maxVotedOracle;
    uint256 public latestOracleUpdateTimestamp;
    uint256 public oracleVotingPeriod = 604800; //1 week in seconds
    uint256 public maxOracleVote;
    uint256 public currentOracleVoteRound;
    mapping(uint256 => mapping(address => bool)) public userVoteRounds; //[roundNo][userAddress]
    mapping(uint256 => mapping(address => uint256)) public oracleVotes; //[roundNo][oracleAddress]
    //----------------

    enum Position {
        Bull,
        Bear,
        Noresult
    }

    struct Round {
        int256 lockPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 bullBonusAmount;
        uint256 bearBonusAmount;
        uint80 lockOracleId;
        uint80 closeOracleId;
        address oracleAddress;
        bool oracleCalled;
        bool cancelled;
    }

    struct Timestamps {
        uint32 startTimestamp;
        uint32 lockTimestamp;
        uint32 closeTimestamp;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        uint256 refereeAmount;
        uint256 referrerAmount;
        bool claimed; // default false
    }

    event SetReferenceAddress(address referenceSystem, uint256 indexed epoch);
    event SetReferenceBonuses(uint256 referrerBonus, uint256 refereeBonus, uint256 indexed epoch);
    event ClaimReferrerBonus(address indexed sender, uint256 reward, uint256 indexed epoch);

    event AddOracle(address oracleAddress, uint256 indexed epoch);
    event RemoveOracle(address removedOracle, uint256 indexed epoch);
    event SetOraclesList(uint256 indexed epoch);
    event EmergencySetNewOracle(address oracle, uint256 indexed epoch);
    event CompleteOracleVoting(address oracle, uint256 maxOracleVote, uint256 indexed epoch);
    event OracleVote(address indexed sender, address oracle, uint256 indexed epoch);

    event NewBet(address indexed sender, uint256 indexed epoch, uint256 amount, uint8 position);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event EndRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);
    event LockRound(uint256 indexed epoch, uint256 indexed roundId, int256 price);

    event NewAdminAddress(address admin);
    event NewIntervalSeconds(uint32 intervalSeconds);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewOracle(address oracle);
    event SetOracleVotingPeriod(uint256 votingPeriod, uint256 indexed epoch);

    event RewardsCalculated(uint256 indexed epoch, uint8 roundResultPosition, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount);

    event StartRound(uint256 indexed epoch);
    event CancelRound(uint256 indexed epoch);
    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);

    event ReferrerBonus(address indexed user, address indexed referrer, uint256 amount, uint256 indexed currentEpoch);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor(
        address[] memory _oraclesList,
        uint32 _intervalSeconds,
        uint256 _minBetAmount,
        uint256 _treasuryFee,
        uint256 _raffleRate,
        uint256 _referrerBonus,
        uint256 _refereeBonus,
        address _referenceSystem
    ) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        require(_raffleRate + _referrerBonus + _refereeBonus <= 100, "cant be higher than 100%");
        require(_oraclesList.length > 0, "Oracles List is empty");

        selectedOracle = _oraclesList[0];
        for (uint256 i = 0; i < _oraclesList.length; i++) { 
            oracleExistence[_oraclesList[i]] = true;       
        }
        latestOracleUpdateTimestamp = block.timestamp;

        adminAddress = msg.sender;
        intervalSeconds = _intervalSeconds;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
        raffleRate = _raffleRate;

        rounds[0].cancelled = true;
        currentEpoch = 1;
        _startRound(currentEpoch);

        referenceSystem = IReference(_referenceSystem);
        referrerBonus = _referrerBonus;
        refereeBonus = _refereeBonus;
    }

    //------------------------
    //REFERENCE SYSTEM FUNCTIONS
    function setReferenceAddress(address _referenceSystem) external onlyAdmin {
        referenceSystem = IReference(_referenceSystem);

        emit SetReferenceAddress(_referenceSystem, currentEpoch);
    }

    function setReferenceBonuses(uint256 _referrerBonus, uint256 _refereeBonus) external onlyAdmin {
        require(raffleRate + _referrerBonus + _refereeBonus <= 100, "cant be higher than 100%");
        referrerBonus = _referrerBonus;
        refereeBonus = _refereeBonus;

        emit SetReferenceBonuses(referrerBonus, refereeBonus, currentEpoch);
    }

    function claimReferrerBonus() external nonReentrant onlyOwner {
        require(referrerBonuses[msg.sender] > 0, "user has no referrer bonuses");
        uint reward = referrerBonuses[msg.sender];
        referrerBonuses[msg.sender] = 0;
        _safeTransfer(address(msg.sender), reward);

        emit ClaimReferrerBonus(msg.sender, reward, currentEpoch);
    }
    //------------------------

    //------------------------
    //ORACLE VOTING FUNCTIONS

    function addOracle(address[] memory _oraclesList) external onlyAdmin {
        for (uint256 i = 0; i < _oraclesList.length; i++) { 
            oracleExistence[_oraclesList[i]] = true;       
            // Dummy check to make sure the interface implements this function properly
            AggregatorV3Interface(_oraclesList[i]).latestRoundData();

            emit AddOracle(_oraclesList[i], currentOracleVoteRound);
        }
    }

    function removeOracle(address[] memory _oraclesList) external onlyAdmin {
        for (uint256 i = 0; i < _oraclesList.length; i++) { 
            oracleExistence[_oraclesList[i]] = false;       

            emit RemoveOracle(_oraclesList[i], currentOracleVoteRound);
        }
    }

    function setOracleVotingPeriod(uint256 _votingPeriod) external onlyAdmin {
        oracleVotingPeriod = _votingPeriod;

        emit SetOracleVotingPeriod(_votingPeriod, currentOracleVoteRound);
    }

    //once the voting period is over, anyonce can call this function and complete the voting
    //this will set the next round to start with the new oracle
    //live round that was locked with old oracle will still get its ending price from the previous oracle
    function completeOracleVoting() external {
        require(block.timestamp >= latestOracleUpdateTimestamp + oracleVotingPeriod, "Voting is not over yet");

        selectedOracle = maxVotedOracle;
        latestOracleUpdateTimestamp = block.timestamp;
        maxOracleVote = 0;
        currentOracleVoteRound = currentOracleVoteRound + 1;

        //give reward to the caller
        raffle.addUserTicket(msg.sender, rewardTicketAmountForCompleteVoting);

        emit CompleteOracleVoting(selectedOracle, maxOracleVote, currentOracleVoteRound);
    }

    //community can vote for the new oracle. every user can vote once
    function voteForNewOracle(address _oracleAddress) external {
        require(!userVoteRounds[currentOracleVoteRound][msg.sender], "you have already voted");
        require(oracleExistence[_oracleAddress], "oracle is not available");
        
        userVoteRounds[currentOracleVoteRound][msg.sender] = true;
        oracleVotes[currentOracleVoteRound][_oracleAddress]++;
        if(oracleVotes[currentOracleVoteRound][_oracleAddress] > maxOracleVote){
             maxOracleVote = oracleVotes[currentOracleVoteRound][_oracleAddress];
             maxVotedOracle = _oracleAddress;
        }

        emit OracleVote(msg.sender, _oracleAddress, currentOracleVoteRound);
    }
    //------------------------
    //------------------------

    function setRaffleAddress(address _raffleAddress) external onlyAdmin {
        raffle = IRaffle(_raffleAddress);
    }

    function setRaffleRate(uint256 _raffleRate) external onlyAdmin {
        require(_raffleRate + referrerBonus + refereeBonus <= 100, "cant be higher than 100%");
        raffleRate = _raffleRate;
    }

    function setRaffleTicketNormalizer(uint256 _raffleTicketNormalizer) external onlyAdmin {
        raffleTicketNormalizer = _raffleTicketNormalizer;
    }

    function setRaffleLogMultiplier(uint256 _raffleLogMultiplier) external onlyAdmin {
        raffleLogMultiplier = _raffleLogMultiplier;
    }

    function setRewardTicketAmountForExecuteRound(uint256 _rewardTicketAmountForExecuteRound) external onlyAdmin {
        rewardTicketAmountForExecuteRound = _rewardTicketAmountForExecuteRound;
    }

    function setRewardTicketAmountForCompleteVoting(uint256 _rewardTicketAmountForCompleteVoting) external onlyAdmin {
        rewardTicketAmountForCompleteVoting = _rewardTicketAmountForCompleteVoting;
    }

    function _addUserTicket(address _userAddress, uint256 _amount) internal {
        //add user tickets to the raffle system
        //log2 function is used to have a higher bonus for simply betting on a round
        //to incentive betting on multiple rounds instead of a single round
        uint256 ticketAmount = (raffleLogMultiplier * log2x(_amount / raffleTicketNormalizer) / 10) + 1;
        raffle.addUserTicket(_userAddress, ticketAmount);
    }

    function log2x(uint x) public pure returns (uint y){
        assembly {
                let arg := x
                x := sub(x,1)
                x := or(x, div(x, 0x02))
                x := or(x, div(x, 0x04))
                x := or(x, div(x, 0x10))
                x := or(x, div(x, 0x100))
                x := or(x, div(x, 0x10000))
                x := or(x, div(x, 0x100000000))
                x := or(x, div(x, 0x10000000000000000))
                x := or(x, div(x, 0x100000000000000000000000000000000))
                x := add(x, 1)
                let m := mload(0x40)
                mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
                mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
                mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
                mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
                mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
                mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
                mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
                mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
                mstore(0x40, add(m, 0x100))
                let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
                let shift := 0x100000000000000000000000000000000000000000000000000000000000000
                let a := div(mul(x, magic), shift)
                y := div(mload(add(m,sub(255,a))), shift)
                y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
            }  
        }

    /**
     * @notice Bet bear position
     * @param epoch: epoch
     */
    function betBear(uint256 epoch) external payable nonReentrant notContract {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(_bettable(epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[epoch][msg.sender].amount == 0, "Can only bet once per round");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + amount;
        round.bearAmount = round.bearAmount + amount;

        //-------------------
        //Reference BonusPart
        //if the user has a referrer, set the referral bonuses and subtract it from the treasury amount
        uint refereeAmt = 0;
        uint referrerAmt = 0;

        //check and set referral bonuses
        if(referenceSystem.hasReferrer(msg.sender))
        {
            uint treasuryAmt = amount * treasuryFee / 1000;
            refereeAmt = treasuryAmt * refereeBonus / 100;
            referrerAmt = treasuryAmt * referrerBonus / 100;
            round.bearBonusAmount = round.bearBonusAmount + refereeAmt + referrerAmt;
        }
        //-------------------

        // Update user data
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        betInfo.refereeAmount = refereeAmt;
        betInfo.referrerAmount = referrerAmt;
        userRounds[msg.sender].push(epoch);

        //add user tickets to the raffle system
        _addUserTicket(msg.sender, amount);

        emit NewBet(msg.sender, epoch, amount, uint8(Position.Bear));
    }

    /**
     * @notice Bet bull position
     * @param epoch: epoch
     */
    function betBull(uint256 epoch) external payable nonReentrant notContract {
        require(epoch == currentEpoch, "Bet is too early/late");
        require(_bettable(epoch), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[epoch][msg.sender].amount == 0, "Can only bet once per round");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[epoch];
        round.totalAmount = round.totalAmount + amount;
        round.bullAmount = round.bullAmount + amount;

        //-------------------
        //Reference BonusPart
        //if the user has a referrer, set the referral bonuses and subtract it from the treasury amount
        uint refereeAmt = 0;
        uint referrerAmt = 0;
        uint treasuryAmt = amount * treasuryFee / 100;

        //check and set referral bonuses
        if(referenceSystem.hasReferrer(msg.sender))
        {
            refereeAmt = treasuryAmt * refereeBonus / 100;
            referrerAmt = treasuryAmt * referrerBonus / 100;
            round.bullBonusAmount = round.bullBonusAmount + refereeAmt + referrerAmt;
        }
        //-------------------

        // Update user data
        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        betInfo.refereeAmount = refereeAmt;
        betInfo.referrerAmount = referrerAmt;
        userRounds[msg.sender].push(epoch);

        //add user tickets to the raffle system
        _addUserTicket(msg.sender, amount);

        emit NewBet(msg.sender, epoch, amount, uint8(Position.Bull));
    }

    /**
     * @notice Claim reward for an array of epochs
     * @param epochs: array of epochs
     */
    function claim(uint256[] calldata epochs) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(timestamps[epochs[i]].startTimestamp != 0, "Round has not started");
            require(block.timestamp > timestamps[epochs[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;
            BetInfo storage betInfo = ledger[epochs[i]][msg.sender];
            Round memory round = rounds[epochs[i]];

            // Round valid, claim rewards
            if (round.oracleCalled && !round.cancelled) {
                require(claimable(epochs[i], msg.sender), "Not eligible for claim");
                
                //add referee bonus to the addedRewards on claim
                addedReward = (betInfo.amount * round.rewardAmount) / round.rewardBaseCalAmount + betInfo.refereeAmount;
                
                //if there is a referrer bonus, add it to that user's referrer bonus amount so they can claim it themselves
                if(betInfo.referrerAmount > 0)
                {
                    address referrerUser = referenceSystem.getReferrer(msg.sender);
                    referrerBonuses[referrerUser] = referrerBonuses[referrerUser] + betInfo.referrerAmount;

                    emit ReferrerBonus(msg.sender, referrerUser, betInfo.referrerAmount, epochs[i]);
                }
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(epochs[i], msg.sender), "Not eligible for refund");
                addedReward = betInfo.amount;
            }

            betInfo.claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) {
            _safeTransfer(address(msg.sender), reward);
        }
    }

    function executeRound() external {
        require(block.timestamp >= timestamps[currentEpoch].lockTimestamp, 'early');

        uint80 roundId;
        int256 price;
        uint256 updatedAt;

        (roundId, price, , updatedAt, ) = AggregatorV3Interface(rounds[currentEpoch].oracleAddress).latestRoundData();
        _lockCurrentRound(roundId, price, updatedAt);

        //end and calculate the live round only if it was not cancelled on locking
        Round storage liveRound = rounds[currentEpoch-1];
        if(!liveRound.cancelled && !liveRound.oracleCalled){
            (roundId, price, updatedAt) = _getOracleDataForPreviousRound(currentEpoch-1);
            _endRound(currentEpoch-1, roundId, price, updatedAt);
            _calculateRewards(currentEpoch-1);
        }

        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);

        //give reward to the caller
        raffle.addUserTicket(msg.sender, rewardTicketAmountForExecuteRound);
    }

    function _lockCurrentRound(uint80 oracleRoundId, int256 price, uint256 oracleUpdatedAt) internal {
        Round storage round = rounds[currentEpoch];
        Timestamps storage ts = timestamps[currentEpoch];

        //using intervalSeconds as locking buffer period
        //cant lock the round if intervalSeconds passed after the lockTimestamp
        //cant lock if oracle didnt update after startTimestamp
        //also cant lock if round timestamps are not set correctly (equals 0)
        if(ts.startTimestamp == 0 ||
            block.timestamp > ts.lockTimestamp + intervalSeconds ||
            oracleUpdatedAt < ts.startTimestamp){
            round.cancelled = true;
            emit CancelRound(currentEpoch);
        }
        else {
            round.lockPrice = price;
            round.lockOracleId = oracleRoundId;
            ts.lockTimestamp = uint32(block.timestamp);
            ts.closeTimestamp = uint32(block.timestamp) + intervalSeconds;
            emit LockRound(currentEpoch, oracleRoundId, round.lockPrice);
        }
    }

    function _startRound(uint256 epoch) internal {
        Timestamps storage ts = timestamps[epoch];
        ts.startTimestamp = uint32(block.timestamp);
        ts.lockTimestamp = uint32(block.timestamp) + intervalSeconds;
        ts.closeTimestamp = uint32(block.timestamp) + (intervalSeconds * 2);

        rounds[epoch].oracleAddress = selectedOracle;

        emit StartRound(epoch);
    }

    function _getOracleDataForPreviousRound(uint256 epoch) internal view returns (uint80, int256, uint256){
        uint80 roundId;
        int256 price;
        uint256 updatedAt;

        AggregatorV3Interface oracle = AggregatorV3Interface(rounds[epoch].oracleAddress);

        roundId = rounds[epoch].lockOracleId;

        if(roundId > 0){
            (uint80 latestRoundId, , , , ) = oracle.latestRoundData();

            if(roundId+1 <= latestRoundId){
                (uint80 _roundId, int256 _price, , uint256 _updatedAt, ) = oracle.getRoundData(roundId+1);

                while (_updatedAt < timestamps[epoch].closeTimestamp && (roundId+1) <= latestRoundId) {
                    (_roundId, _price, , _updatedAt, ) = oracle.getRoundData(roundId+1);
                    if(_updatedAt < timestamps[epoch].closeTimestamp){
                        roundId = _roundId;
                        price = _price;
                        updatedAt = _updatedAt;
                    }
                }
            }
        }
        else {
            (roundId, price, , updatedAt, ) = oracle.latestRoundData();

            while (updatedAt > timestamps[epoch].closeTimestamp) {
                (roundId, price, , updatedAt, ) = oracle.getRoundData(roundId-1);
            }
        }

        return (roundId, price, updatedAt);
    }

    function _endRound(uint256 epoch, uint80 oracleRoundId, int256 oraclePrice, uint256 oracleUpdatedAt) internal {
        Round storage round = rounds[epoch];
        Timestamps storage ts = timestamps[epoch];

        if(ts.startTimestamp == 0 ||
            oracleUpdatedAt > ts.closeTimestamp ||
            oracleUpdatedAt < ts.lockTimestamp){
            round.closeOracleId = oracleRoundId;
            round.cancelled = true;

            emit CancelRound(epoch);
        }
        else{
            round.closeOracleId = oracleRoundId;
            round.closePrice = oraclePrice;
            round.oracleCalled = true;

            emit EndRound(epoch, oracleRoundId, round.closePrice);
        }
    }


    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransfer(adminAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice Set buffer and interval (in seconds)
     * @dev Callable by admin
     */
    function setIntervalSeconds(uint32 _intervalSeconds) external onlyAdmin {
        intervalSeconds = _intervalSeconds;

        emit NewIntervalSeconds(_intervalSeconds);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(currentEpoch, minBetAmount);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentEpoch, treasuryFee);
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    function getTimestamp() public view returns (uint256) 
    {
        return block.timestamp;
    }

    function getCurrentRoundRemainingSeconds() public view returns (uint256) 
    {
        return timestamps[currentEpoch].lockTimestamp - block.timestamp;
    }
    

    /**
     * @notice Returns round epochs and bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.oracleCalled &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        return
            round.cancelled &&
            !betInfo.claimed &&
            block.timestamp > timestamps[epoch].closeTimestamp + intervalSeconds &&
            betInfo.amount != 0;
    }

    /**
     * @notice Calculate rewards for round
     * @param epoch: epoch
     */
    function _calculateRewards(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        if(!round.cancelled && rounds[epoch].rewardBaseCalAmount == 0 && rounds[epoch].rewardAmount == 0)
        {
            uint256 rewardBaseCalAmount;
            uint256 treasuryAmt;
            uint256 rewardAmount;
            uint256 raffleAmount;

            uint8 roundResultPosition = uint8(Position.Noresult);

            // Bull wins
            if (round.closePrice > round.lockPrice) {
                rewardBaseCalAmount = round.bullAmount;
                treasuryAmt = (round.totalAmount * treasuryFee) / 1000;
                rewardAmount = round.totalAmount - treasuryAmt;
                //decrease the reference system bonus we give to the users from the treasury amount
                treasuryAmt = treasuryAmt - round.bullBonusAmount;
                roundResultPosition = uint8(Position.Bull);
            }
            // Bear wins
            else if (round.closePrice < round.lockPrice) {
                rewardBaseCalAmount = round.bearAmount;
                treasuryAmt = (round.totalAmount * treasuryFee) / 1000;
                rewardAmount = round.totalAmount - treasuryAmt;
                //decrease the reference system bonus we give to the users from the treasury amount
                treasuryAmt = treasuryAmt - round.bearBonusAmount;
                roundResultPosition = uint8(Position.Bear);
            }
            // Refund on same price
            else {
                rewardBaseCalAmount = 0;
                rewardAmount = 0;
                treasuryAmt = 0;
                round.cancelled = true;
            }
            round.rewardBaseCalAmount = rewardBaseCalAmount;
            round.rewardAmount = rewardAmount;


            //send the raffle amount to the raffle contract and set it's round balance
            raffleAmount = treasuryAmt * raffleRate / 100;
            if(raffleAmount > 0){
                raffle.addBalance{value:raffleAmount}();
            }

            // Add to treasury
            treasuryAmount += treasuryAmt - raffleAmount;

            emit RewardsCalculated(epoch, roundResultPosition, rewardBaseCalAmount, rewardAmount, treasuryAmt);
        }
    }

    function _safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            timestamps[epoch].startTimestamp != 0 &&
            timestamps[epoch].lockTimestamp != 0 &&
            block.timestamp > timestamps[epoch].startTimestamp &&
            block.timestamp < timestamps[epoch].lockTimestamp;
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}