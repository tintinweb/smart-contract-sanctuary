/**
 *Submitted for verification at polygonscan.com on 2021-08-05
*/

// SPDX-License-Identifier: MIT
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
 * @title UnifiedLiquidityPool Interface
 */
interface IUnifiedLiquidityPool {
    /**
     * @dev External function to start staking. Only owner can call this function.
     * @param _initialStake Amount of GBTS token
     */
    function startStaking(uint256 _initialStake) external;

    /**
     * @dev External function for staking. This function can be called by any users.
     * @param _amount Amount of GBTS token
     */
    function stake(uint256 _amount) external;

    /**
     * @dev External function to exit staking. Users can withdraw their funds.
     * @param _amount Amount of sGBTS token
     */
    function exitStake(uint256 _amount) external;

    /**
     * @dev External function to allow sGBTS holder to deposit their token to earn direct deposits of GBTS into their wallets
     * @param _amount Amount of sGBTS
     */
    function addToDividendPool(uint256 _amount) external;

    /**
     * @dev External function for getting amount of sGBTS which caller in DividedPool holds.
     */
    function getBalanceofUserHoldInDividendPool() external returns (uint256);

    /**
     * @dev External function to withdraw from the dividendPool.
     * @param _amount Amount of sGBTS
     */
    function removeFromDividendPool(uint256 _amount) external;

    /**
     * @dev External function to check to see if the distributor has any sGBTS then distribute. Only distributes to one provider at a time.
     *      Only if the ULP has more then 45 million GBTS.
     */
    function distribute() external;

    /**
     * @dev External Admin function to adjust for casino Costs, i.e. VRF, developers, raffles ...
     *      When distributed to the new address the address will be readjusted back to the ULP.
     * @param _ulpDivAddr is the address to recieve the dividends
     */
    function changeULPDivs(address _ulpDivAddr) external;

    /**
     * @dev External function to unlock game for approval. This can be called by only owner.
     * @param _gameAddr Game Address
     */
    function unlockGameForApproval(address _gameAddr) external;

    /**
     * @dev External function to change game's approval. This is called by only owner.
     * @param _gameAddr Address of game
     * @param _approved Approve a game or not
     */
    function changeGameApproval(address _gameAddr, bool _approved) external;

    /**
     * @dev External function to get approved games list.
     */
    function getApprovedGamesList() external view returns (address[] memory);

    /**
     * @dev External function to send prize to winner. This is called by only approved games.
     * @param _winner Address of game winner
     * @param _prizeAmount Amount of GBTS token
     */
    function sendPrize(address _winner, uint256 _prizeAmount) external;

    /**
     * @dev External function to request Chainlink random number from ULP. This function can be called by only apporved games.
     */
    function requestRandomNumber() external returns (bytes32);

    /**
     * @dev External function to get new vrf number(Game number). This function can be called by only apporved games.
     * @param _requestId Batching Id of random number.
     */
    function getVerifiedRandomNumber(bytes32 _requestId)
        external
        returns (uint256);

    /**
     * @dev External function to check if the gameAddress is the approved game.
     * @param _gameAddress Game Address
     */
    function currentGameApproved(address _gameAddress) external returns (bool);

    /**
     * @dev External function to burn sGBTS token. Only called by owner.
     * @param _amount Amount of sGBTS
     */
    function burnULPsGbts(uint256 _amount) external;

    /**
     * @dev External function to change batch block space. Only called by owner.
     * @param _newChange Block space change amount
     */
    function changeBatchBlockSpace(uint256 _newChange) external;
}

contract Lottery is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    enum Status {
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The lottery has been closed and the numbers drawn
    }

    // All the needed info around a lottery
    struct LottoInfo {
        Status lotteryStatus; // Status for lotto
        uint256 costPerTicket; // Cost per ticket in GBTS
        uint16[3] prizeMultipliers; // Multiplier for 2, 3, and 4 matches
        uint256 startingBlock; // Block number for lotto start
        uint256 blockDelay; // Block delay
        uint256 closingBlock; // Block number for lotto close
        uint256 winningNumber; // The winning number
        uint256 betGBTS;
        bytes32 requestId;
    }

    event ticketsBought(
        uint256 indexed lottoID,
        address indexed buyer,
        uint16[] ticketList
    );
    event ticketsClaimed(uint256 indexed lottoID, address indexed claimer);
    event lotteryOpened(uint256 indexed lottoID, LottoInfo lotto);
    event lotteryClosed(uint256 indexed lottoID, LottoInfo lotto);
    event lotteryDrawn(uint256 indexed lottoID, LottoInfo lotto);
    event prizeMultipliersChanged(uint16[3] newMultipliers);
    event blockDelayChanged(uint256 newDelay);
    event ticketCostChanged(uint256 newCost);

    mapping(uint256 => mapping(uint16 => bool)) ticketPurchased; // Whether a given ticket sequence has been purchased
    mapping(uint256 => mapping(address => uint16[])) ticketList; // List of tickets the player owns
    mapping(uint256 => mapping(address => bool)) rewardsClaimed; // Whether the player's tickets have been paid out yet

    IERC20 GBTS;
    IUnifiedLiquidityPool ULP;

    LottoInfo[] public lotteryList;
    uint256 public costPerTicket;
    uint16[3] public prizeMultipliers;
    uint256 public blockDelay;
    uint256 public currentLottoID;

    uint256 constant gameId = 1;

    constructor(
        uint256 _costPerTicket,
        uint16[3] memory _prizeMultipliers,
        uint256 _blockDelay,
        address _GBTSAddr,
        address _ulpAddr
    ) {
        costPerTicket = _costPerTicket;
        prizeMultipliers = _prizeMultipliers;
        blockDelay = _blockDelay;
        GBTS = IERC20(_GBTSAddr);
        ULP = IUnifiedLiquidityPool(_ulpAddr);
        pushNewLotto();
    }

    // -------------------- External Functions --------------------

    /**
     * @dev Allow the player to buy a maximum of 100 total tickets
     * @param _ticketList list of tickets the player wants to buy
     */

    function buyTickets(uint16[] memory _ticketList)
        public
        nonReentrant
        whenNotPaused
    {
        require(
            _ticketList.length +
                ticketList[currentLottoID][msg.sender].length <=
                100,
            "Lottery: You cannot purchase more than 100 tickets total"
        );
        require(
            lotteryList[currentLottoID].lotteryStatus == Status.Open,
            "Lottery: Lottery is not open for ticket purchases."
        );
        uint256 _totalCost;
        for (uint8 i = 0; i < _ticketList.length; i++) {
            require(
                !ticketPurchased[currentLottoID][_ticketList[i]],
                "Lottery: Ticket not available for purchase"
            );
            require(
                _ticketList[i] <= 9999,
                "Lottery: Ticket numbers must be <= 9999"
            );
            _totalCost += lotteryList[currentLottoID].costPerTicket * 1 ether;
            ticketList[currentLottoID][msg.sender].push(_ticketList[i]);
            ticketPurchased[currentLottoID][_ticketList[i]] = true;
            lotteryList[currentLottoID].betGBTS +=
                lotteryList[currentLottoID].costPerTicket *
                1 ether;
        }
        GBTS.safeTransferFrom(msg.sender, address(ULP), _totalCost);
        emit ticketsBought(currentLottoID, msg.sender, _ticketList);
    }

    /**
     * @dev Allows anyone to close to lottery if the time is correct
     */

    function closeLottery() external nonReentrant {
        require(
            lotteryList[currentLottoID].lotteryStatus == Status.Open,
            "Lottery: Already closed."
        );
        require(
            block.number >=
                lotteryList[currentLottoID].startingBlock +
                    lotteryList[currentLottoID].blockDelay,
            "Lottery: Not ready to close lotto yet."
        );
        lotteryList[currentLottoID].lotteryStatus = Status.Closed;
        lotteryList[currentLottoID].requestId = ULP.requestRandomNumber();
        lotteryList[currentLottoID].closingBlock = block.number;
        emit lotteryClosed(currentLottoID, lotteryList[currentLottoID]);
    }

    /**
     * @dev Draws the lottery and starts a new one
     */
    function drawLottery() external nonReentrant {
        require(
            lotteryList[currentLottoID].lotteryStatus == Status.Closed,
            "Lottery: Lottery is not closed yet."
        );
        uint256 randomNumber = ULP.getVerifiedRandomNumber(
            lotteryList[currentLottoID].requestId
        );
        lotteryList[currentLottoID].winningNumber =
            uint256(
                keccak256(abi.encode(randomNumber, address(msg.sender), gameId))
            ) %
            10000;
        lotteryList[currentLottoID].lotteryStatus = Status.Completed;
        emit lotteryDrawn(currentLottoID, lotteryList[currentLottoID]);
        if (!paused()) {
            pushNewLotto();
        }
    }

    function restartLotto() external onlyOwner whenNotPaused {
        require(
            lotteryList[currentLottoID].lotteryStatus == Status.Completed,
            "Lottery: Last lotto still ongoing"
        );
        pushNewLotto();
    }

    /**
     * @dev Claim any potential GBTS prizes for a given lottoID
     * @param _lottoID the lotteryID from which to claim
     */

    function claimPrizes(uint256 _lottoID) public nonReentrant {
        require(_lottoID <= currentLottoID, "Lottery: lottoID out of bounds");
        require(
            !rewardsClaimed[_lottoID][msg.sender],
            "Lottery: Already claimed rewards for this lotto"
        );
        require(
            ticketList[_lottoID][msg.sender].length > 0,
            "Lottery: Sender has 0 tickets for this lotto"
        );
        require(
            lotteryList[_lottoID].lotteryStatus == Status.Completed,
            "Lottery: Lotto not over yet, cannot claim prizes"
        );
        uint16[3] memory _prizeMultipliers = lotteryList[_lottoID]
            .prizeMultipliers;
        uint16 _rewardMultiplier;
        uint256 _totalReward;
        for (uint8 i = 0; i < ticketList[_lottoID][msg.sender].length; i++) {
            _rewardMultiplier = getRewardMultiplier(
                getNumberMatching(
                    ticketList[_lottoID][msg.sender][i],
                    lotteryList[_lottoID].winningNumber
                ),
                _prizeMultipliers
            );
            if (_rewardMultiplier == 0) {
                continue;
            }
            _totalReward +=
                lotteryList[_lottoID].costPerTicket *
                _rewardMultiplier *
                1 ether;
        }
        ULP.sendPrize(msg.sender, _totalReward);
        rewardsClaimed[_lottoID][msg.sender] = true;
        emit ticketsClaimed(currentLottoID, msg.sender);
    }

    /**
     * @dev returns the prize multiplier array. Mostly used for testing, but could potentially but useful in the future.
     */

    function getPrizeMultipliers() public view returns (uint16[3] memory) {
        return prizeMultipliers;
    }

    // -------------------- Owner Functions --------------------
    function changePrizeMultipliers(uint16[3] memory _prizeMultipliers)
        external
        onlyOwner
    {
        require(
            _prizeMultipliers[0] > 0 &&
                _prizeMultipliers[1] > 0 &&
                _prizeMultipliers[2] > 0,
            "Lottery: Prize Multipliers must all be non-zero."
        );
        prizeMultipliers = _prizeMultipliers;
        emit prizeMultipliersChanged(_prizeMultipliers);
    }

    function changeDrawDelay(uint256 _blockDelay) external onlyOwner {
        require(_blockDelay > 30, "Lottery: Block delay must be at least 30.");
        blockDelay = _blockDelay;
        emit blockDelayChanged(_blockDelay);
    }

    function changeCostPerTicket(uint256 _costPerTicket) external onlyOwner {
        require(_costPerTicket > 0, "Lottery: Ticket cost cannot be zero.");
        costPerTicket = _costPerTicket;
        emit ticketCostChanged(_costPerTicket);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows owner to retreieve ERC-20 tokens that would otherwise be stuck
     * @param token The ERC-20 to transfer to the contract owner
     */
    function retrieveERC20(IERC20 token) external onlyOwner {
        require(
            address(token) != address(GBTS),
            "Lottery: Cannot withdraw GBTS using retreieveERC20"
        );
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    // -------------------- Internal Functions --------------------

    /**
     * @dev adds a new lottery struct to lotteryList
     */

    function pushNewLotto() internal {
        LottoInfo memory newLotto = LottoInfo(
            Status.Open,
            costPerTicket,
            prizeMultipliers,
            block.number,
            blockDelay,
            0,
            0,
            0,
            0
        );
        lotteryList.push(newLotto);
        currentLottoID = lotteryList.length - 1;
        emit lotteryOpened(currentLottoID, newLotto);
    }

    /**
     * @dev Determine how many of the player's numbers match the winning numbers
     * @param _ticketNumber 4 digit number representing the ticket
     * @param _winningNumber An 4 digit value representing the winning number
     *
     */

    function getNumberMatching(uint16 _ticketNumber, uint256 _winningNumber)
        internal
        pure
        returns (uint8 _numberMatching)
    {
        for (uint8 i = 0; i < 4; i++) {
            if (
                ((_ticketNumber / (10**i)) % 10) ==
                ((_winningNumber / (10**i)) % 10)
            ) {
                _numberMatching++;
            }
        }
    }

    /**
     * @dev Get the reward multiplier for a ticket
     * @param _numberMatching number of digits matching the drawn number
     * @param _prizeMultipliers array of multipliers (0 = 2 matched, 1 = 3 matched, 2 = 4 matched)
     *
     */

    function getRewardMultiplier(
        uint8 _numberMatching,
        uint16[3] memory _prizeMultipliers
    ) internal pure returns (uint16 _rewardMultiplier) {
        require(
            _numberMatching < 5,
            "Lottery: Something went seriously wrong. _numberMatching should never be >= 5"
        );
        if (_numberMatching < 2) {
            _rewardMultiplier = 0;
        } else {
            _rewardMultiplier = _prizeMultipliers[_numberMatching - 2];
        }
    }
}