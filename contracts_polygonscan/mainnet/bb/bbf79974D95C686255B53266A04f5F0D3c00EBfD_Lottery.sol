/**
 *Submitted for verification at polygonscan.com on 2021-08-05
*/

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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


interface ITicket {
    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns (uint256);

    function getNumberOfTickets(uint256 _lotteryID) external view returns (uint256);

    function getTicketNumbers(uint256 _ticketID) external view returns (uint16[] memory);

    function getOwnerOfTicket(uint256 _ticketID) external view returns (address);

    function getTicketClaimStatus(uint256 _ticketID) external view returns (bool);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function batchMint(
        address _to,
        uint256 _lottoID,
        uint8 _numberOfTickets,
        uint16[] calldata _numbers
    ) external returns (uint256[] memory);

    function claimTicket(uint256 _ticketId, uint256 _lotteryId) external returns (bool);

    function countMatch(
        uint256 _lotteryId,
        uint16[] calldata _winningNumbers
    ) external view returns (uint256[] memory results);
}


interface IPrizeReservePool {
    /**
     * Funding a minimal amount when prize pool is empty
     * @param amount amount of IRON to be set as prize
     */
    function fund(uint256 amount) external;
}


interface IBasisAsset {
    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;
}


contract Lottery is Initializable {
    // governance
    address public operator;

    // using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // The distribution for prize money
    // 1500000 ~ 1.5/, 30000000 ~ 30, 300000000 ~ 300, 1000000000 ~ 1000, 500000 ~ 50% (jackpot)
    uint256[5] public prizeDistribution;

    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The numbers drawn
    }

    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID; // ID for lotto
        Status lotteryStatus; // Status for lotto
        uint256 prizePool; // The amount of DogeLand for prize money
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint16[] winningNumbers; // The winning numbers
        uint256[] winners; // the winners of each prize
    }

    // State variables
    // Instance of DogeLand token (collateral currency for lotto)
    IERC20 public dogeL;
    // Storing of the ticket
    ITicket public ticket;
    // Request ID for random number
    bytes32 internal requestId;

    // Counter for lottery IDs
    uint256 private lotteryIdCounter;

    // These stated is fixed due to technical implementation
    // Lottery size, power number not included
    uint8 public constant sizeOfLottery = 6;
    // precision for all distribution
    uint256 public constant PRECISION = 1e6;
    uint256 public unclaimedPrize;
    address public controller;

    // Max range for numbers (starting at 0)
    uint16 public maxValidRange;

    // settings for lotto, will be applied to newly created lotto
    uint256 public startingPrize;
    uint256 public costPerticket; // Cost per ticket in $DogeLand

    // Max ticket can buy
    uint256 public maxTicketLimit;

    address public prizeReservePool;

    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries;
    uint256 public defaultDuration = 8 hours;

    bool public upgraded = false;

    uint256 public currentSeed = 0;

    // Tax fee
    uint256 public taxFee = 100000; // default 10%
    uint256 public totalBurn = 0;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event NewBatchMint(address indexed minter, uint256[] ticketIDs, uint16[] numbers, uint256 pricePaid);

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event LotterySettingsUpdated(
        uint16 maxValidRange,
        uint256 startingPrize,
        uint256 costPerTicket
    );

    event LotteryOpened(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClosed(uint256 lotteryId, uint256 ticketSupply);

    event WinnersDrawn(uint256[] numbers);

    event GovernanceWithdraw(address indexed user, address indexed token, uint256 amount, address indexed to);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------
    modifier onlyOperator() {
        require(operator == msg.sender, "caller is not the operator");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only controller");
        _;
    }

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier notUpgraded() {
        require(upgraded == false, "This contract was upgraded");
        _;
    }

    function initialize(
        address _dogeL,
        address _ticket,
        address _prizeReservePool,
        address _operator,
        address _controller,
        uint256 _taxFee,
        uint256[5] memory _prizeDistribution
    ) external initializer {
        require(
            _ticket != address(0) &&
            _prizeReservePool != address(0) &&
            _dogeL != address(0),
            "Contracts cannot be 0 address"
        );
        dogeL = IERC20(_dogeL);
        ticket = ITicket(_ticket);
        prizeReservePool = _prizeReservePool;
        taxFee = _taxFee;
        prizeDistribution = _prizeDistribution;
        controller = _controller;
        operator = _operator;
        maxTicketLimit = 100;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function costToBuyTickets(uint256 numberOfTickets) external view returns (uint256 totalCost) {
        // solidity 0.8 auto handle overflow
        uint256 pricePerTicket = costPerticket;
        totalCost = pricePerTicket * numberOfTickets;
    }

    function getBasicLottoInfo(uint256 lotteryId) external view returns (LottoInfo memory) {
        return (allLotteries[lotteryId]);
    }

    function getCurrentLotto() external view returns (LottoInfo memory) {
        require(lotteryIdCounter > 0, "no lottery created");
        return allLotteries[lotteryIdCounter];
    }

    function getCurrentTotalPrize() public view returns (uint256 totalPrize) {
        totalPrize = dogeL.balanceOf(address(this)) - unclaimedPrize;
    }

    function getMaxRange() external view returns (uint16) {
        return maxValidRange;
    }

    function _genNextSeed(uint256 _newHash) internal view returns (uint256) {
        return currentSeed ^ _newHash ^ uint256(blockhash(block.number - 1));
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function autoStartLotto() external onlyController returns (uint256) {
        uint256 startTime;
        uint256 closingTime;
        uint256 currentTime = block.timestamp;
        if (lotteryIdCounter > 0) {
            startTime = allLotteries[lotteryIdCounter].closingTimestamp;
            // check if last closing time is too far ago
            startTime = startTime + defaultDuration < currentTime ? currentTime : startTime;
        } else {
            startTime = currentTime;
        }

        closingTime = startTime + defaultDuration;
        return _createNewLotto(startTime, closingTime);
    }

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOperator)

    /**
     * manually start by admin, by pass auto duration
     */
    function manualStartLotto(uint256 _startingTime, uint256 _closingTime) external onlyController returns (uint256) {
        return _createNewLotto(_startingTime, _closingTime);
    }


    function setController(address _controller) external onlyOperator {
        require(_controller != address(0), "Contracts cannot be 0 address");
        controller = _controller;
    }

    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "Contracts cannot be 0 address");
        operator = newOperator;
    }

    function setPrizeReservePool(address _prizeReservePool) external onlyOperator {
        require(_prizeReservePool != address(0), "Contracts cannot be 0 address");
        prizeReservePool = _prizeReservePool;
    }

    function setTicket(address _ticket) external onlyOperator {
        require(_ticket != address(0), "Contracts cannot be 0 address");
        ticket = ITicket(_ticket);
    }

    function setTaxFee(uint256 _taxFee) external onlyOperator {
        require(_taxFee < 500000, " < 50%");
        taxFee = _taxFee;
    }

    function setMaxTicketLimit(uint256 _maxTicketLimit) external onlyOperator {
        require(_maxTicketLimit > 0, ">0");
        maxTicketLimit = _maxTicketLimit;
    }

    function upgradeNewLottoContract(address newLottoContract) external onlyOperator {
        require(
            allLotteries[lotteryIdCounter].lotteryStatus == Status.Completed,
            "Lottery State must be completed into to upgrade"
        );
        require(newLottoContract != address(0), "Invalid contract");
        uint256 _movableAmount = getCurrentTotalPrize();
        upgraded = true;
        dogeL.safeTransfer(newLottoContract, _movableAmount);
    }

    function updateLottoSettings(
        uint16 _maxValidRange,
        uint256 _costPerTicket,
        uint256 _startingPrize
    ) external onlyOperator {
        require(_maxValidRange >= 6, "Range of number must be 6 at least");
        require(_startingPrize != 0 && _costPerTicket != 0, "Prize or cost cannot be 0");

        maxValidRange = _maxValidRange;
        startingPrize = _startingPrize;
        costPerticket = _costPerTicket;

        emit LotterySettingsUpdated(
            maxValidRange,
            startingPrize,
            costPerticket
        );
    }

    function updatePrizeDistribution(
        uint256[5] memory _prizeDistribution
    ) external onlyOperator {
        prizeDistribution = _prizeDistribution;
    }

    function updateDefaultDuration(uint256 _duration) external onlyOperator {
        require(_duration > 0, "Duration cannot be 0");
        defaultDuration = _duration;
    }

    function numbersDrawn(
        uint256 lotteryId
    ) external onlyController() notUpgraded {
        LottoInfo storage _currLotto = allLotteries[lotteryId];
        if (_currLotto.lotteryStatus == Status.NotStarted) {
            if (_currLotto.startingTimestamp <= block.timestamp) {
                _currLotto.lotteryStatus = Status.Open;
            }
        }
        // Checks that the lottery is past the closing block
        require(_currLotto.closingTimestamp <= block.timestamp, "Cannot set winning numbers during lottery");
        // Checks lottery numbers have not already been drawn
        require(_currLotto.lotteryStatus == Status.Open, "Lottery State incorrect for draw");
        // Sets lottery status to closed
        _currLotto.lotteryStatus = Status.Closed;
        // Sets prize pool
        _currLotto.prizePool = getCurrentTotalPrize();
        require(_currLotto.lotteryStatus == Status.Closed, "Draw numbers first");
        currentSeed = _genNextSeed(0);
        uint256 _randomNumber = currentSeed;
        _currLotto.winningNumbers = _split(_randomNumber);
        uint256[] memory matches = ticket.countMatch(lotteryId, _currLotto.winningNumbers);
        _currLotto.lotteryStatus = Status.Completed;
        uint256 _totalPrize = 0;
        // jackpot
        _currLotto.winners[0] = matches[0];
        if (matches[0] > 0) {
            _totalPrize =  (getCurrentTotalPrize() * prizeDistribution[0]) / PRECISION;
        }
        for (uint256 i = 1; i < prizeDistribution.length; i++) {
            _currLotto.winners[i] = matches[i];
            if (matches[i] > 0) {
                _totalPrize = _totalPrize + (matches[i] * prizeDistribution[i] * 1e18 ) / PRECISION;
            }
        }
        if (_totalPrize > 0) {
            _addUnclaimedPrize(_totalPrize);
        }

        emit LotteryClosed(lotteryId, ticket.getTotalSupply());
    }

    //-------------------------------------------------------------------------
    // General Access Functions

    function batchBuyLottoTicket(
        uint256 _lotteryId,
        uint8 _numberOfTickets,
        uint16[] memory _chosenNumbersForEachTicket,
        uint256 _userRandomHash
    ) external notContract() notUpgraded {
        // Ensuring the lottery is within a valid time
        uint256 currentTime = block.timestamp;
        LottoInfo storage _currLotto = allLotteries[_lotteryId];
        require(currentTime >= _currLotto.startingTimestamp, "Invalid time for mint:start");
        require(currentTime < _currLotto.closingTimestamp, "Invalid time for mint:end");

        if (_currLotto.lotteryStatus == Status.NotStarted) {
            if (_currLotto.startingTimestamp <= block.timestamp) {
                _currLotto.lotteryStatus = Status.Open;
            }
        }

        require(_currLotto.lotteryStatus == Status.Open, "Lottery not in state for mint");
        // sort
        for (uint256 index = 0; index < _chosenNumbersForEachTicket.length; index++) {
            uint256 k = (index + 1) % sizeOfLottery;
            if (k == 0) {
                for (uint256 i = index - 5; i < index + 1; i++) {
                    for (uint256 j = index - 5 ; j < 2 * index - i - 5 ; j++)
                        if (_chosenNumbersForEachTicket[j] > _chosenNumbersForEachTicket[j + 1]) {
                            uint16 temp = _chosenNumbersForEachTicket[j];
                            _chosenNumbersForEachTicket[j] = _chosenNumbersForEachTicket[j + 1];
                            _chosenNumbersForEachTicket[j + 1] = temp;
                        }
                }
            }
        }

        validateTicketNumbers(_numberOfTickets, _chosenNumbersForEachTicket);
        uint256 totalCost = this.costToBuyTickets(_numberOfTickets);

        // Batch mints the user their tickets
        uint256[] memory ticketIds =
        ticket.batchMint(msg.sender, _lotteryId, _numberOfTickets, _chosenNumbersForEachTicket);

        // Emitting event with all information
        emit NewBatchMint(msg.sender, ticketIds, _chosenNumbersForEachTicket, totalCost);

        // Transfers the required dogeL to this contract
        dogeL.safeTransferFrom(msg.sender, address(this), totalCost);

        currentSeed = _genNextSeed(_userRandomHash);
    }

    function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract() {
        // Checking the lottery is in a valid time for claiming
        require(allLotteries[_lotteryId].closingTimestamp <= block.timestamp, "Wait till end to claim");
        // Checks the lottery winning numbers are available
        require(allLotteries[_lotteryId].lotteryStatus == Status.Completed, "Winning Numbers not chosen yet");
        require(ticket.getOwnerOfTicket(_tokenId) == msg.sender, "Only the owner can claim");
        // Sets the claim of the ticket to true (if claimed, will revert)
        require(ticket.claimTicket(_tokenId, _lotteryId), "Numbers for ticket invalid");
        // Getting the number of matching tickets
        uint8 matchingNumbers =
        _getNumberOfMatching(ticket.getTicketNumbers(_tokenId), allLotteries[_lotteryId].winningNumbers);
        // Getting the prize amount for those matching tickets
        uint256 prizeAmount = _prizeForMatching(matchingNumbers, _lotteryId);
        uint256 taxAmount = 0;
        if (taxFee > 0) {
            taxAmount = (prizeAmount * taxFee) / PRECISION;
            prizeAmount = prizeAmount - taxAmount;
            totalBurn = totalBurn + taxAmount;
        }
        // Transfering the user their winnings
        _claimPrize(msg.sender, prizeAmount);
        // Burn
        if (taxAmount > 0) {
            IBasisAsset(address(dogeL)).burn(taxAmount);
        }
    }

    function batchClaimRewards(uint256 _lotteryId, uint256[] calldata _ticketIds) external notContract() {
        require(_ticketIds.length <= maxTicketLimit, "Batch claim too large");
        // Checking the lottery is in a valid time for claiming
        require(allLotteries[_lotteryId].closingTimestamp <= block.timestamp, "Wait till end to claim");
        // Checks the lottery winning numbers are available
        require(allLotteries[_lotteryId].lotteryStatus == Status.Completed, "Winning Numbers not chosen yet");
        // Creates a storage for all winnings
        uint256 totalPrize = 0;
        uint256 taxAmount = 0;
        // Loops through each submitted token
        for (uint256 i = 0; i < _ticketIds.length; i++) {
            // Checks user is owner (will revert entire call if not)
            require(ticket.getOwnerOfTicket(_ticketIds[i]) == msg.sender, "Only the owner can claim");
            // If token has already been claimed, skip token
            if (ticket.getTicketClaimStatus(_ticketIds[i])) {
                continue;
            }
            // Claims the ticket (will only revert if numbers invalid)
            require(ticket.claimTicket(_ticketIds[i], _lotteryId), "Numbers for ticket invalid");
            // Getting the number of matching tickets
            uint8 matchingNumbers =
            _getNumberOfMatching(ticket.getTicketNumbers(_ticketIds[i]), allLotteries[_lotteryId].winningNumbers);
            // Getting the prize amount for those matching tickets
            uint256 prizeAmount = _prizeForMatching(matchingNumbers, _lotteryId);
            totalPrize = totalPrize + prizeAmount;
        }
        if (taxFee > 0) {
            taxAmount = (totalPrize * taxFee) / PRECISION;
            totalPrize = totalPrize - taxAmount;
            totalBurn = totalBurn + taxAmount;
        }
        // Transferring the user their winnings
        _claimPrize(msg.sender, totalPrize);
        // Burn
        if (taxAmount > 0) {
            IBasisAsset(address(dogeL)).burn(taxAmount);
        }
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
    function _createNewLotto(uint256 _startingTimestamp, uint256 _closingTimestamp)
    internal
    notUpgraded
    returns (uint256 lotteryId)
    {
        require(_startingTimestamp != 0 && _startingTimestamp < _closingTimestamp, "Timestamps for lottery invalid");
        require(
            lotteryIdCounter == 0 || allLotteries[lotteryIdCounter].lotteryStatus == Status.Completed,
            "current lottery is not completed"
        );
        // Incrementing lottery ID
        lotteryIdCounter = lotteryIdCounter + 1;
        lotteryId = lotteryIdCounter;
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery);
        uint256[] memory winnersCount = new uint256[](prizeDistribution.length);
        Status lotteryStatus;
        if (_startingTimestamp > block.timestamp) {
            lotteryStatus = Status.NotStarted;
        } else {
            lotteryStatus = Status.Open;
        }

        //transfer from reserve pool to poolPrize if current < minPrize
        if (getCurrentTotalPrize() < startingPrize) {
            IPrizeReservePool(prizeReservePool).fund(startingPrize - getCurrentTotalPrize());
        }

        // Saving data in struct
        LottoInfo memory newLottery =
        LottoInfo(
            lotteryId,
            lotteryStatus,
            startingPrize,
            _startingTimestamp,
            _closingTimestamp,
            winningNumbers,
            winnersCount
        );
        allLotteries[lotteryId] = newLottery;

        // Emitting important information around new lottery.
        emit LotteryOpened(lotteryId, ticket.getTotalSupply());
    }

    function _getNumberOfMatching(uint16[] memory _usersNumbers, uint16[] memory _winningNumbers)
    internal
    pure
    returns (uint8 noOfMatching)
    {
        // Loops through all winning numbers
        for (uint256 i = 0; i < _winningNumbers.length; i++) {
            for (uint256 j = 0; j < _usersNumbers.length ; j++) {
                // If the winning numbers and user numbers match
                if (_usersNumbers[i] == _winningNumbers[j]) {
                    // The number of matching numbers increases
                    noOfMatching += 1;
                }
            }
        }
    }

    function _claimPrize(address _winner, uint256 _amount) internal {
        unclaimedPrize = unclaimedPrize - _amount;
        dogeL.safeTransfer(_winner, _amount);
    }

    function _addUnclaimedPrize(uint256 amount) internal {
        unclaimedPrize = unclaimedPrize + amount;
    }

    /**
     * @param   _noOfMatching: The number of matching numbers the user has
     * @param   _lotteryId: The ID of the lottery the user is claiming on
     * @return  prize  The prize amount in cake the user is entitled to
     */
    function _prizeForMatching(uint8 _noOfMatching, uint256 _lotteryId) public view returns (uint256 prize) {
        prize = 0;
        // Getting the percentage of the pool the user has won
        uint256 prizeIndex = sizeOfLottery - _noOfMatching;
        uint256 perOfPool = prizeDistribution[prizeIndex];
        if (_noOfMatching < 6) {
            prize = (prizeDistribution[prizeIndex] * costPerticket) / PRECISION;
        } else {
            // jackpot
            uint256 numberOfWinners = allLotteries[_lotteryId].winners[prizeIndex];
            if (numberOfWinners > 0) {
                prize =  (allLotteries[_lotteryId].prizePool * perOfPool * (PRECISION)) /
                numberOfWinners /
                (PRECISION ** 2);
            }
        }
    }

    function _split(uint256 _randomNumber) internal view returns (uint16[] memory) {
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery);

        uint16[] memory array = new uint16[](maxValidRange);
        for (uint16 i = 0; i < maxValidRange; i++) {
            array[i] = i + 1;
        }

        uint16 temp;

        for (uint256 i = array.length - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(_randomNumber, i))) % i;
            temp = array[i];
            array[i] = array[j];
            array[j] = temp;
        }

        for (uint256 i = 0; i < sizeOfLottery; i++) {
            winningNumbers[i] = array[i];
        }

        for (uint256 i = 0; i < sizeOfLottery; i++) {
            for (uint256 j = 0; j < sizeOfLottery - i - 1; j++)
                if (winningNumbers[j] > winningNumbers[j + 1]) {
                    uint16 tmp = winningNumbers[j];
                    winningNumbers[j] = winningNumbers[j + 1];
                    winningNumbers[j + 1] = tmp;
                }
        }

        return winningNumbers;
    }

    function validateTicketNumbers(uint8 _numberOfTickets, uint16[] memory _numbers) internal view {
        require(_numberOfTickets <= maxTicketLimit, "Batch mint too large");
        require(_numbers.length == _numberOfTickets * sizeOfLottery, "Invalid chosen numbers");
        for (uint256 i = 0; i < _numbers.length; i++) {
            require(_numbers[i] > 0 && _numbers[i] <= maxValidRange, "out of range: number");
            uint256 k = (i + 1) % sizeOfLottery;
            if (k == 0) {
                require(_numbers[i] != _numbers[i - 1], "duplicate number");
                require(_numbers[i - 1] != _numbers[i - 2], "duplicate number");
                require(_numbers[i - 2] != _numbers[i - 3], "duplicate number");
                require(_numbers[i - 3] != _numbers[i - 4], "duplicate number");
                require(_numbers[i - 4] != _numbers[i - 5], "duplicate number");
            }
        }
    }

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IERC20(_token).safeTransfer(_to, _amount);
        emit GovernanceWithdraw(msg.sender, _token, _amount, _to);
    }
}