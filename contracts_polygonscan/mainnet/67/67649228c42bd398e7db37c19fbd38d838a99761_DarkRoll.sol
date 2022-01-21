/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


interface IRandomNumberGenerator {
    function getRandomNumber(bytes32 keyHash) external returns (uint256 randomNumber);
}


interface IReferral {
    function set(address from, address to) external;

    function refOf(address to) external view returns (address);
}

/**
 *Submitted for verification at polygonscan.com on 2021-11-02
*/
/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/
contract DarkRoll is OwnableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // the address used for receiving withdrawing fee

    uint256 public balanceOfBet = 0; // Total balance of are not finished
    uint256 public lockBalanceForGame = 0; // Don't use share value

    bool public stopped = false;

    // Instance of DARK token (collateral currency for bet)
    IERC20 public dark;

    IRandomNumberGenerator public randomNumberGenerator;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    uint256 public noStakeFee;

    struct Bet {
        uint256 index;
        uint256 number;
        bool isOver;
        uint256 amount;
        address player;
        uint256 round;
        uint256 luckyNumber;
        uint256 seed;
        bool isFinished;
    }

    struct Player {
        uint256 totalBet;
        uint256 totalPayout;
        uint256 totalRefReward;
        uint256 totalJackpot;
        uint256 pendingReward;
        uint256 lastBetTime;
        bool paused;
    }

    // SETTING
    uint256 public HOUSE_RATE = 40; // 4%
    uint256 public JACKPOT_RATE = 20; // 2%
    uint256 public REFERRAL_RATE = 5; // 0.5% of bet amount for referral. max 0.5%
    uint256 public REWARD_LOCKED_PERIOD = 60; // 60s
    uint256 public DELAY_BET_TIME = 30; // 60s
    uint256 public MINIMUM_BET_AMOUNT = 2 ether;
    uint256 public MAX_PRIZE_PERCENT = 30; // 30% of balance
    uint256 public JACKPOT_NUMBER = 88;

    address public referralContract;

    // Just for display on app
    uint256 public totalBetOfGame = 0;
    uint256 public totalWinAmountOfGame = 0;
    uint256 public currentJackPotSize = 0;

    // Properties for game
    Bet[] public bets; // All bets of player
    mapping(address => uint256[]) public betsOf; // Store all bet of player
    mapping(address => Player) public players; // Store all bet of player

    event TransferWinner(address winner, uint256 betIndex, uint256 amount);
    event TransferLeaderBoard(address winner, uint256 round, uint256 amount);
    event NewBet(
        address player,
        uint256 round,
        uint256 index,
        uint256 number,
        bool isOver,
        uint256 amount
    );
    event DrawBet(
        address player,
        uint256 round,
        uint256 index,
        uint256 number,
        bool isOver,
        uint256 amount,
        bool isFinished,
        uint256 luckyNumber,
        uint256 winAmount,
        address referrer,
        uint256 commission
    );

    function initialize(address _dark,  address _randomNumberGenerator) external initializer {
        dark = IERC20(_dark);
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGenerator);
        __Ownable_init();

        bets.push(
            Bet({
        number: 0,
        isOver: false,
        amount: 0,
        player: address(0x0),
        round: 0,
        isFinished: true,
        luckyNumber: 0,
        index: 0,
        seed: 0
        })
        );
    }

    event NftLocked(address indexed user, uint256 tokenId);
    event NftUnlocked(address indexed user, uint256 tokenId);

    /**
    MODIFIER
     */

    modifier notStopped() {
        require(!stopped, "stopped");
        _;
    }

    modifier isStopped() {
        require(stopped, "not stopped");
        _;
    }

    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0);
        require(tx.origin == msg.sender);
        _;
    }

    /**
    GET FUNCTION
     */

    function getLastBetIndex(address add) public view returns (uint256) {
        if (betsOf[add].length == 0) return 0;
        return betsOf[add][betsOf[add].length - 1];
    }

    function totalNumberOfBets(address player) public view returns (uint256) {
        if (player != address(0x00)) return betsOf[player].length;
        else return bets.length;
    }


    /**
    BET RANGE
     */

    function balanceForGame(uint256 subAmount)
    public
    view
    returns (uint256 _bal)
    {
        _bal = dark.balanceOf(address(this)) - subAmount - balanceOfBet;
    }

    function calculatePrizeForBet(uint256 betAmount)
    public
    view
    returns (uint256)
    {
        uint256 bal = balanceForGame(betAmount);
        return (bal * MAX_PRIZE_PERCENT) / 100;
    }

    function betRange(
        uint256 number,
        bool isOver,
        uint256 amount
    ) public view returns (uint256 min, uint256 max) {
        uint256 currentWinChance = calculateWinChance(number, isOver);
        uint256 prize = calculatePrizeForBet(amount);
        min = MINIMUM_BET_AMOUNT;
        max = (prize * currentWinChance) / 100;
        if (max < MINIMUM_BET_AMOUNT) max = MINIMUM_BET_AMOUNT;
    }

    /**
    BET
     */

    function calculateWinChance(uint256 number, bool isOver)
    private
    pure
    returns (uint256)
    {
        return isOver ? 99 - number : number;
    }

    function calculateWinAmount(
        uint256 number,
        bool isOver,
        uint256 amount
    ) private view returns (uint256) {
        uint256 winAmount = amount * (1000 - HOUSE_RATE - JACKPOT_RATE - REFERRAL_RATE) / 10 / calculateWinChance(number, isOver);
        return winAmount;
    }

    /**
    DRAW WINNER
    */

    function checkWin(
        uint256 number,
        bool isOver,
        uint256 luckyNumber
    ) private pure returns (bool) {
        return
        (isOver && number < luckyNumber) ||
        (!isOver && number > luckyNumber);
    }

    function _getRandomNumber(uint256 _hash) internal returns (uint256) {
        IRandomNumberGenerator _rng = randomNumberGenerator;
        return _rng.getRandomNumber(bytes32(_hash));
    }

    function getLuckyNumber(uint256 betIndex)
    internal
    returns (uint256)
    {
        Bet memory bet = bets[betIndex];
        uint256 blockHash = uint256(blockhash(bet.round));
        if (blockHash == 0) {
            blockHash = uint256(blockhash(block.number - 1));
        }
        // return randomNumberGenerator.getRandomNumber(betIndex, bet.seed, bet.number, blockHash);
        return uint256(_getRandomNumber(uint256(uint160(msg.sender)) ^ betIndex ^ bet.seed ^ bet.number ^ blockHash)) % 100 + 100;
    }

    /**
    WRITE & PUBLIC FUNCTION
     */

    function _login(address ref) internal {
        if (referralContract != address(0x0)) {
            IReferral(referralContract).set(ref, msg.sender);
        }
    }

    function _newBet(uint256 betAmount, uint256 winAmount) internal {
        require(
            lockBalanceForGame + winAmount < balanceForGame(betAmount),
            "Balance is not enough for game"
        );
        lockBalanceForGame = lockBalanceForGame + winAmount;
        balanceOfBet = balanceOfBet + betAmount;
    }

    function _finishBet(uint256 betAmount, uint256 winAmount) internal {
        lockBalanceForGame = lockBalanceForGame - winAmount;
        balanceOfBet = balanceOfBet - betAmount;
    }

    function claimPendingReward() external notContract {
        require(block.timestamp - players[msg.sender].lastBetTime > REWARD_LOCKED_PERIOD, "Waiting more time!");
        require(dark.balanceOf(address (this)) >= players[msg.sender].pendingReward, "Not enough balance to claim!");
        require(!players[msg.sender].paused, "this account need to be check!");
        dark.safeTransfer(msg.sender, players[msg.sender].pendingReward);
        players[msg.sender].totalPayout += players[msg.sender].pendingReward;
        players[msg.sender].pendingReward = 0;
    }

    function placeBet(
        uint256 number,
        bool isOver,
        uint256 seed,
        address ref,
        uint256 amountBet
    ) external notStopped notContract {
        require(block.timestamp - players[msg.sender].lastBetTime > DELAY_BET_TIME, "bet too fast, calm down!");
        if (ref != address(0)) {
            _login(ref);
        }
        (uint256 minAmount, uint256 maxAmount) =
        betRange(number, isOver, amountBet);
        uint256 index = bets.length;
        require(minAmount > 0 && maxAmount > 0);
        require(
            isOver ? number >= 4 && number <= 98 : number >= 1 && number <= 95,
            "bet number not in range"
        );
        require(
            minAmount <= amountBet && amountBet <= maxAmount,
            "bet amount not in range"
        );
        require(
            bets[getLastBetIndex(msg.sender)].isFinished,
            "last best not finished"
        );
        // Transfers the required dark to this contract
        dark.safeTransferFrom(msg.sender, address(this), amountBet);

        uint256 winAmount = calculateWinAmount(number, isOver, amountBet);
        _newBet(amountBet, winAmount);

        totalBetOfGame += amountBet;

        betsOf[msg.sender].push(index);

        bets.push(
            Bet({
        index: index,
        number: number,
        isOver: isOver,
        amount: amountBet,
        player: msg.sender,
        round: block.number,
        isFinished: false,
        luckyNumber: 0,
        seed: seed
        })
        );
        //emit NewBet(msg.sender, block.number, index, number, isOver, amountBet, userStakedNft);
        _settleBet(index);
    }

    function refundBet(address add) external onlyOwner {
        uint256 betIndex = getLastBetIndex(add);
        Bet storage bet = bets[betIndex];
        require(
            !bet.isFinished &&
        bet.player == add &&
        block.number - bet.round > 10000
        );

        uint256 winAmount = calculateWinAmount(bet.number, bet.isOver, bet.amount);

        dark.safeTransfer(add, bet.amount);
        _finishBet(bet.amount, winAmount);

        bet.isFinished = true;
        bet.amount = 0;
    }

    /**
    Internal
     */
    function _settleBet(
        uint256 i
    ) internal {
        require(i < bets.length);

        Bet storage bet = bets[i];

        require(!bet.isFinished);

        uint256 luckyNum = getLuckyNumber(bet.index);
        require(luckyNum > 0);

        luckyNum -= 100;

        uint256 winAmount = calculateWinAmount(bet.number, bet.isOver, bet.amount);

        bet.luckyNumber = luckyNum;
        bet.isFinished = true;
        address referrer;
        uint256 commission;
        // update jackpot size
        currentJackPotSize += bet.amount * JACKPOT_RATE / 1000;

        // update bet time
        players[bet.player].lastBetTime = block.timestamp;

        if (referralContract != address(0x0)) {
            referrer = IReferral(referralContract).refOf(bet.player);
            if (referrer != address(0x0)) {
                commission =
                bet.amount * REFERRAL_RATE / 1000;
                players[referrer].totalRefReward += commission;
                players[referrer].pendingReward += commission;
            }
        }

        if (checkWin(bet.number, bet.isOver, luckyNum)) {
            totalWinAmountOfGame += winAmount;
            players[bet.player].totalBet += bet.amount;
            players[bet.player].pendingReward += winAmount;
            emit TransferWinner(bet.player, bet.index, winAmount);
        } else {
            players[bet.player].totalBet += bet.amount;
        }

        // check win jackpot
        if (luckyNum == JACKPOT_NUMBER) {
            currentJackPotSize = 0;
            players[bet.player].totalJackpot += currentJackPotSize;
            players[bet.player].pendingReward += currentJackPotSize;
        }

        _finishBet(bet.amount, winAmount);
        emit DrawBet(
            bet.player,
            bet.round,
            bet.index,
            bet.number,
            bet.isOver,
            bet.amount,
            bet.isFinished,
            bet.luckyNumber,
            winAmount,
            referrer,
            commission
        );
    }
    // ADMIN SETTERS
    function setRandomNumberGenerator(address _randomNumberGenerator) external onlyOwner {
        require(_randomNumberGenerator != address(0), "Contracts cannot be 0 address");
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGenerator);
    }


    function setMaxPrizePercent(uint256 level) external onlyOwner {
        require(MAX_PRIZE_PERCENT <= 100);
        MAX_PRIZE_PERCENT = level;
    }

    function setHouseRate(uint256 value) external onlyOwner {
        require(value >= 5 && value <= 100); // [0.5%, 10%]
        HOUSE_RATE = value;
    }

    function setJackpotRate(uint256 value) external onlyOwner {
        require(value >= 1 && value <= 50); // [0.1%, 5%]
        JACKPOT_RATE = value;
    }

    function setReferralRate(uint256 value) external onlyOwner {
        require(value >= 1 && value <= 50); // [0.1%, 5%]
        REFERRAL_RATE = value;
    }

    function setJackpotNumber(uint256 value) external onlyOwner {
        require(value >= 1 && value <= 99); // [0.1%, 5%]
        JACKPOT_NUMBER = value;
    }

    function setDelayBetTime(uint256 value) external onlyOwner {
        require(value >= 20 && value <= 300); // [20s, 300s]
        DELAY_BET_TIME = value;
    }

    function setRewardLockedPeriod(uint256 value) external onlyOwner {
        require(value >= 60 && value <= 7200); // [60s, 7200s]
        REWARD_LOCKED_PERIOD = value;
    }

    function setMinBet(uint256 value) external onlyOwner {
        require(value >= 2 ether && value <= 500 ether);
        MINIMUM_BET_AMOUNT = value;
    }

    function setReferral(address _referral) external onlyOwner {
        referralContract = _referral;
    }

    function setDark(address _dark) external onlyOwner {
        dark = IERC20(_dark);
    }

    function emergencyToken(IERC20 token, uint256 amount)
    external
    onlyOwner
    {
        token.safeTransfer(owner(), amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(
            amount + lockBalanceForGame <= dark.balanceOf(address(this)),
            "over available balance"
        );
        dark.safeTransfer(owner(), amount);
    }

    /** FOR EMERGENCY */
    function forceStopGame(uint256 confirm) external onlyOwner {
        require(confirm == 0x1, "Enter confirm code");
        stopped = true;
    }
}