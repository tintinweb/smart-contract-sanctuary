/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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



pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title HashPredictionV1
 */
contract HashPredictionV1 is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator

    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public currentBlock = block.number; // current Block for prediction round


    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    address public betToken;

    bytes32 public EMPTY_HASH = blockhash(0); // empty hash 0x00000000000

    mapping(uint256 => mapping(address => BetInfoBS)) public ledgerBS; //bet small or big
    mapping(uint256 => mapping(address => BetInfoOE)) public ledgerOE; //bet odd or even
    mapping(uint256 => Round) rounds;
    mapping(address => uint256[]) public userRoundsBS;
    mapping(address => uint256[]) public userRoundsOE;

    enum Position {
        Default,
        Big,
        Small,
        Odd,
        Even
    }

    struct Round {
        uint256 blockNum;
        bytes32 blockHash;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 totalBSAmount;
        uint256 totalOEAmount;
        uint256 bigAmount;
        uint256 smallAmount;
        uint256 oddAmount;
        uint256 evenAmount;
        uint256 rewardBSBaseCalAmount;
        uint256 rewardBSAmount;
        uint256 rewardOEBaseCalAmount;
        uint256 rewardOEAmount;
        Position BSResult;
        Position OEResult;

    }

    struct BetInfoBS {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    struct BetInfoOE {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    event BetBig(address indexed sender, uint256 indexed blockNum, uint256 amount);
    event BetSmall(address indexed sender, uint256 indexed blockNum, uint256 amount);
    event BetOdd(address indexed sender, uint256 indexed blockNum, uint256 amount);
    event BetEven(address indexed sender, uint256 indexed blockNum, uint256 amount);

    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);

    event NewAdminAddress(address admin);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewOperatorAddress(address operator);

    event Pause(uint256 indexed epoch);
    event BSRewardsCalculated(
        uint256 indexed blockNum,
        uint256 rewardBSBaseCalAmount,
        uint256 rewardBSAmount,
        uint256 treasuryBSAmount
    );
    event OERewardsCalculated(
        uint256 indexed blockNum,
        uint256 rewardOEBaseCalAmount,
        uint256 rewardOEAmount,
        uint256 treasuryOEAmount
    );

    event TokenRecovery(address indexed token, uint256 amount);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed epoch);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @param _adminAddress: admin address
     * @param _operatorAddress: operator address
     * @param _minBetAmount: minimum bet amounts (in wei)
     * @param _treasuryFee: treasury fee (1000 = 10%)
     * @param _betToken: token address for bet(USDT)
     */
    constructor(
        address _adminAddress,
        address _operatorAddress,
        uint256 _minBetAmount,
        uint256 _treasuryFee,
        address _betToken
    ) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
        betToken = _betToken;
    }

    /**
     * @notice Bet big position
     * @param amount: amount to bet
     */
    function betBig(uint256 amount) external  whenNotPaused nonReentrant notContract {
        require(_bettable(), "block num too close");
        require(amount >= minBetAmount, "Bet amount must be greater than minBetAmount");
        uint256 nextBlock = _nextBlockNum();
        require(ledgerBS[nextBlock][msg.sender].amount == 0, "Can only bet once per round");
        IERC20(betToken).safeTransferFrom(address(msg.sender),address(this), amount);
        // Update round data
        Round storage round = rounds[nextBlock];
        round.blockNum = nextBlock;
        round.totalBSAmount = round.totalBSAmount + amount;
        round.bigAmount = round.bigAmount + amount;

        // Update user data
        BetInfoBS storage betInfoBS = ledgerBS[nextBlock][msg.sender];
        betInfoBS.position = Position.Big;
        betInfoBS.amount = amount;
        userRoundsBS[msg.sender].push(nextBlock);

        emit BetBig(msg.sender, nextBlock, amount);
    }

    /**
     * @notice Bet small position
     * @param amount: amount to bet
     */
     function betSmall(uint256 amount) external  whenNotPaused nonReentrant notContract {
        require(_bettable(), "block num too close");
        require(amount >= minBetAmount, "Bet amount must be greater than minBetAmount");
        uint256  nextBlock = _nextBlockNum();
        require(ledgerBS[nextBlock][msg.sender].amount == 0, "Can only bet once per round");
        IERC20(betToken).safeTransferFrom(address(msg.sender),address(this), amount);
        // Update round data
        Round storage round = rounds[nextBlock];
        round.blockNum = nextBlock;
        round.totalBSAmount = round.totalBSAmount + amount;
        round.smallAmount = round.smallAmount + amount;

        // Update user data
        BetInfoBS storage betInfoBS = ledgerBS[nextBlock][msg.sender];
        betInfoBS.position = Position.Small;
        betInfoBS.amount = amount;
        userRoundsBS[msg.sender].push(nextBlock);

        emit BetSmall(msg.sender, nextBlock, amount);
    }

    /**
     * @notice Bet odd position
     * @param amount: amount to bet
     */
    function betOdd(uint256 amount) external  whenNotPaused nonReentrant notContract {
        require(_bettable(), "block num too close");
        require(amount >= minBetAmount, "Bet amount must be greater than minBetAmount");
        uint256  nextBlock = _nextBlockNum();
        require(ledgerOE[nextBlock][msg.sender].amount == 0, "Can only bet once per round");
        IERC20(betToken).safeTransferFrom(address(msg.sender),address(this), amount);
        // Update round data
        Round storage round = rounds[nextBlock];
        round.blockNum = nextBlock;
        round.totalOEAmount = round.totalOEAmount + amount;
        round.oddAmount = round.oddAmount + amount;

        // Update user data
        BetInfoOE storage betInfoOE = ledgerOE[nextBlock][msg.sender];
        betInfoOE.position = Position.Odd;
        betInfoOE.amount = amount;
        userRoundsOE[msg.sender].push(nextBlock);

        emit BetOdd(msg.sender, nextBlock, amount);
    }

    /**
     * @notice Bet even position
     * @param amount: amount to bet
     */
     function betEven(uint256 amount) external  whenNotPaused nonReentrant notContract {
        require(_bettable(), "block num too close");
        require(amount >= minBetAmount, "Bet amount must be greater than minBetAmount");
        uint256  nextBlock = _nextBlockNum();
        require(ledgerOE[nextBlock][msg.sender].amount == 0, "Can only bet once per round");
        IERC20(betToken).safeTransferFrom(address(msg.sender),address(this), amount);
        // Update round data
        Round storage round = rounds[nextBlock];
        round.blockNum = nextBlock;
        round.totalOEAmount = round.totalOEAmount + amount;
        round.evenAmount = round.evenAmount + amount;

        // Update user data
        BetInfoOE storage betInfoOE = ledgerOE[nextBlock][msg.sender];
        betInfoOE.position = Position.Even;
        betInfoOE.amount = amount;
        userRoundsOE[msg.sender].push(nextBlock);

        emit BetEven(msg.sender, nextBlock, amount);
    }

    /**
     * @notice Claim BS reward for an array of blockNums
     * @param blockNums: array of blockNums
     */
    function claimBS(uint256[] calldata blockNums) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < blockNums.length; i++) {
            require(block.timestamp > rounds[blockNums[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

            require(claimableBS(blockNums[i], msg.sender), "Not eligible for claim");
            Round memory round = rounds[blockNums[i]];
            addedReward = (ledgerBS[blockNums[i]][msg.sender].amount * round.rewardBSAmount) / round.rewardBSBaseCalAmount;
            


            ledgerBS[blockNums[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, blockNums[i], addedReward);
        }

        if (reward > 0) {
            IERC20(betToken).safeTransfer(address(msg.sender), reward);
        }
    }

    /**
     * @notice Claim OD reward for an array of blockNums
     * @param blockNums: array of blockNums
     */
    function claimOE(uint256[] calldata blockNums) external nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < blockNums.length; i++) {
            require(block.timestamp > rounds[blockNums[i]].closeTimestamp, "Round has not ended");

            uint256 addedReward = 0;

            require(claimableOE(blockNums[i], msg.sender), "Not eligible for claim");
            Round memory round = rounds[blockNums[i]];
            addedReward = (ledgerOE[blockNums[i]][msg.sender].amount * round.rewardOEAmount) / round.rewardOEBaseCalAmount;
            


            ledgerOE[blockNums[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, blockNums[i], addedReward);
        }

        if (reward > 0) {
            IERC20(betToken).safeTransfer(address(msg.sender), reward);
        }
    }





    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdminOrOperator {
        _pause();

        emit Pause(currentBlock);
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        IERC20(betToken).safeTransfer(adminAddress, currentTreasuryAmount);
        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external whenPaused onlyAdmin {
        _unpause();

        emit Unpause(currentBlock);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external whenPaused onlyAdmin {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(currentBlock, minBetAmount);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }




    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentBlock, treasuryFee);
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

    /**
     * @notice Returns blockNums and BS bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserRoundsBS(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfoBS[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRoundsBS[user].length - cursor) {
            length = userRoundsBS[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfoBS[] memory betInfo = new BetInfoBS[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRoundsBS[user][cursor + i];
            betInfo[i] = ledgerBS[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }


    /**
     * @notice Returns blockNums and OD bet information for a user that has participated
     * @param user: user address
     * @param cursor: cursor
     * @param size: size
     */
     function getUserRoundsOE(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfoOE[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRoundsOE[user].length - cursor) {
            length = userRoundsOE[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfoOE[] memory betInfo = new BetInfoOE[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRoundsOE[user][cursor + i];
            betInfo[i] = ledgerOE[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }


    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param blockNum: blockNum
     * @param user: user address
     */
    function claimableBS(uint256 blockNum, address user) public view returns (bool) {
        BetInfoBS memory betInfo = ledgerBS[blockNum][user];
        Round memory round = rounds[blockNum];

        return 
            round.BSResult == betInfo.position &&
            !betInfo.claimed &&
            betInfo.amount != 0;
    }


    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param blockNum: blockNum
     * @param user: user address
     */
    function claimableOE(uint256 blockNum, address user) public view returns (bool) {
    BetInfoOE memory betInfo = ledgerOE[blockNum][user];
    Round memory round = rounds[blockNum];

    return 
        round.OEResult == betInfo.position &&
        !betInfo.claimed &&
        betInfo.amount != 0 ;
    }



    /** 
     * @notice make draw
    */
   function draw() external whenNotPaused onlyOperator{
       uint256  nextBlockNum = _nextBlockNum();
       bytes32  nextBlockHash = blockhash(nextBlockNum);
       require(nextBlockHash != EMPTY_HASH,'empty hash!');
       Round storage round = rounds[nextBlockNum];
       require(round.blockHash == EMPTY_HASH,'round hash not empty!');
       if (isBig(nextBlockNum)) {
            round.BSResult = Position.Big;
       }
       else{
            round.BSResult = Position.Small;
       }

       if(isOdd(nextBlockNum)) {
           round.OEResult = Position.Odd;
       }
       else{
            round.OEResult = Position.Even;
       }
       round.blockHash = nextBlockHash;
       round.closeTimestamp = block.timestamp;
       currentBlock = nextBlockNum;
       _calculateRewards(currentBlock);

   }

    /** 
     * @notice make draw with designative
    */
     function drawDesignative(uint256 blockNum,bytes32 blockHash,bytes32 blockHashNext) external whenNotPaused onlyOperator{
        require(blockHash != EMPTY_HASH,'empty hash!');
        require(blockNum < block.number && (blockNum - currentBlock) % 100 == 0,'wrong block num!');
        Round storage round = rounds[blockNum];
        require(round.blockHash == EMPTY_HASH,'round hash not empty!');
        drawInteral(blockHashNext);
        if (isBig(blockNum)) {
             round.BSResult = Position.Big;
        }
        else{
             round.BSResult = Position.Small;
        }
 
        if(isOdd(blockNum)) {
            round.OEResult = Position.Odd;
        }
        else{
             round.OEResult = Position.Even;
        }
        round.blockHash = blockHash;
        round.closeTimestamp = block.timestamp;
        currentBlock = blockNum;
        _calculateRewards(currentBlock);
 
    }

    function drawInteral(bytes32 blockHash) internal {
        uint256  nextBlockNum = _nextBlockNum();
        bytes32  nextBlockHash = blockHash;
        require(nextBlockHash != EMPTY_HASH,'empty hash!');
        Round storage round = rounds[nextBlockNum];
        require(round.blockHash == EMPTY_HASH,'round hash not empty!');
        if (isBig(nextBlockNum)) {
             round.BSResult = Position.Big;
        }
        else{
             round.BSResult = Position.Small;
        }
 
        if(isOdd(nextBlockNum)) {
            round.OEResult = Position.Odd;
        }
        else{
             round.OEResult = Position.Even;
        }
        round.blockHash = nextBlockHash;
        round.closeTimestamp = block.timestamp;
        currentBlock = nextBlockNum;
        _calculateRewards(currentBlock);
    }

    /**
     * @notice judge the hash result
     * @param num: block number
     */
    function isOdd(uint256 num) public view returns (bool result) {
        return uint8(blockhash(num)[31]) % 2 == 1;
    }

    function isBig(uint256 num) public view returns (bool result) {
        return uint8(blockhash(num)[31]) >= 128;
    } 



    /**
     * @notice Calculate rewards for round
     * @param blockNum: blockNum
     */
    function _calculateRewards(uint256 blockNum) internal {
        require(rounds[blockNum].rewardOEBaseCalAmount == 0 && rounds[blockNum].rewardOEAmount == 0 && rounds[blockNum].rewardBSBaseCalAmount == 0 && rounds[blockNum].rewardBSAmount == 0, "Rewards calculated");
        Round storage round = rounds[blockNum];
        uint256 rewardBSBaseCalAmount;
        uint256 rewardOEBaseCalAmount;
        uint256 rewardBSAmount;
        uint256 rewardOEAmount;
        uint256 treasuryAmt;


        // Big wins
        if (round.BSResult == Position.Big){
            rewardBSBaseCalAmount = round.bigAmount;
            treasuryAmt = (round.totalBSAmount * treasuryFee) / 10000;
            rewardBSAmount = round.totalBSAmount - treasuryAmt;
        }
        // Small wins
        else {
            rewardBSBaseCalAmount = round.smallAmount;
            treasuryAmt = (round.totalBSAmount * treasuryFee) / 10000;
            rewardBSAmount = round.totalBSAmount - treasuryAmt;
        }
        // Odd wins
        if (round.OEResult == Position.Odd){
            rewardOEBaseCalAmount = round.oddAmount;
            treasuryAmt = (round.totalOEAmount * treasuryFee) / 10000;
            rewardOEAmount = round.totalOEAmount - treasuryAmt;
        }
        // Even wins
        else {
            rewardOEBaseCalAmount = round.evenAmount;
            treasuryAmt = (round.totalOEAmount * treasuryFee) / 10000;
            rewardOEAmount = round.totalOEAmount - treasuryAmt;
        }
        round.rewardBSBaseCalAmount = rewardBSBaseCalAmount;
        round.rewardBSAmount = rewardBSAmount;

        round.rewardOEBaseCalAmount = rewardOEBaseCalAmount;
        round.rewardOEAmount = rewardOEAmount;

        // Add to treasury
        treasuryAmount += treasuryAmt;

        emit BSRewardsCalculated(blockNum, rewardBSBaseCalAmount, rewardBSAmount, treasuryAmt);
        emit OERewardsCalculated(blockNum, rewardOEBaseCalAmount, rewardOEAmount, treasuryAmt);
    }



    /**
     * @notice Transfer BNB in a safe way
     * @param to: address to transfer BNB to
     * @param value: BNB amount to transfer (in wei)
     */
    function _safeTransferBNB(address to, uint256 value) external onlyOwner {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }


    /**
     * @notice Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current timestamp must be within startTimestamp and closeTimestamp
     */
    function _bettable() internal view returns (bool) {
        return block.number - currentBlock < 80;
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


    /**
     * @notice Returns next prediction block number
     */
    function _nextBlockNum() internal view returns (uint256) {
        return currentBlock + 100;
    }


    function getRounds(uint256 blockNum) public view returns (Round memory) {
        return rounds[blockNum];
    }
}