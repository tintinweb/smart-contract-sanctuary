/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity 0.8.6;
enum EventState  {Active, Hold, Finished, Canceled}
    enum CompareSign {Equal, MoreOrEqual, LessOrEqual, More, Less, NotEqual}
    enum GameState {Active, Deprecated, Expired}
    enum BetState {Done, Canceled, Claimed}
    enum BetResult {Undefined, Win, Lose}
    
    //Game that available in GamePool
    struct Game {
        address eventContract;
        string name;
        address rewardModelContract;
        GameState state; 

    }

    //Users bet
    struct Bet {
        address eventContract;
        uint256 eventId;
        uint8 eventOutcomeIndex;
        uint256 betAmount;
        uint256 betTimestamp;
        BetState currentState;
        BetResult result;
    }

    //This  structure will used for reflect possible game event result
    // and bets that were made on this outcome
    struct Outcome {
        CompareSign compare;
        int256 expectedValue;
        int256 weiRaised;
        uint256 betCount;
        bool isWin;
    }
    
    struct GamblingEvent {
        address creator;
        EventState state;
        uint256 expirationTime;
        uint256 orderDeadLineTime;
        string  eventAssetSymbol;
        Outcome[2] outcome;
        int256 oraclePrice;
    }

    struct EventSettle {
        uint256 fundReward;
        uint256 creatorReward;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// Part: IGammbleGame

interface IGammbleGame  {
function createEvent(
        uint256 _expire, 
        uint256 _orderDeadLine, 
        string  memory _assetSymbol,
        Outcome[2] memory _outcomes
)  external; 
        
function incBetCountForOutcome(uint256 _evevntId, uint256 _outcomeId, uint256 _amount) external returns(bool);

function decBetCountForOutcome(uint256 _evevntId, uint256 _outcomeId, uint256 _amount) external returns(bool);

function checkStateWithSave(uint256 _evevntId) external;

function getEvent(uint256 _id) external view returns(GamblingEvent memory);

function getEventCount() external view returns(uint256); 

function isEventExist(uint256 _id) external view returns(bool);

function isWinWithAmount(
        uint256 _eventId, 
        uint8 _outcomeIndex, 
        uint256 _betAmount
    ) 
        external 
        returns (bool, uint256);

}

// Part: IRewardModel

interface IRewardModel {
    function getFundPercent() external view returns (uint256);
    function getEventCreatorPercent() external view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/Address

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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeERC20

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: GamblePool.sol

contract GamblePool is Ownable {
    using SafeERC20 for IERC20;
    
    
    uint256 constant public CANCEL_BET_PENALTY_PERCENT = 30;
    uint256 constant public MIN_BET_AMOUNT = 1000; 
    address immutable public projectToken;
    uint256 public totalStaked;
    uint256 public inBetsAmount;  //Main acount with amount of tokens that are frozen in bets.

    //Users balance in this pool
    mapping(address => uint256) private balances;

    //Users bets
    mapping(address => Bet[]) private userBets;

    //map from gameId from eventid to fund share amount
    mapping(uint256 => mapping(uint256 => EventSettle)) public eventsSettlement;

    mapping(address => bool) public enabledFunds;

    Game[] public games;

    //Main acount with amount of tokens for distribution
    // accordingly game tokenomic
    uint256 public fundBalance; 

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event NewBet(
        address indexed better,
        uint256 _gameId,
        uint256 _eventId,
        uint8   _eventOutcomeIndex,
        uint256 _betAmount
    );
    event WinClaimed(
        address indexed better,
        uint256 betId,
        uint256 amount 
    );

    event FundStateChanged(address fund, bool state);
    
    constructor (address _token) {
        projectToken = _token;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cant stake zero");
        require(
            IERC20(projectToken).transferFrom(msg.sender, address(this), _amount)
        );
        _increaseTotalAmount(msg.sender, _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Cant withdraw zero");
        require(_availableAmount(msg.sender) >= _amount);
        _decreaseTotalAmount(msg.sender, _amount);
        require(
            IERC20(projectToken).transfer(msg.sender, _amount)
        );
        emit Withdrawn(msg.sender, _amount);
    }

    //TODO  add restrictions:fee or who can create
    function createEvent(
        uint256 _gameId,
        uint256 _expire, 
        uint256 _orderDeadLine, 
        string  memory _assetSymbol,
        Outcome[2] memory _outcomes
    )
        external
    {
        Game memory g = games[_gameId];
        require(g.state == GameState.Active, "Sorry game is not available");
        //TODO some  checs  and fee if need
        IGammbleGame(g.eventContract).createEvent(_expire, _orderDeadLine, _assetSymbol, _outcomes);

    }


    function makeBet(
        uint256 _gameId,
        uint256 _eventId,
        uint8   _eventOutcomeIndex,
        uint256 _betAmount
    ) 
        external 
        returns (bool)
    {
        //TODO some check
        require(_betAmount >= MIN_BET_AMOUNT, "Your bet is too small");
        require(_availableAmount(msg.sender) >= _betAmount, "Need more in stake");
        Game storage g = games[_gameId];
        require(IGammbleGame(g.eventContract).isEventExist(_eventId), 
            "Seems like this event does not exist yet"
        );
        //1. Register new bet in Game contract
        if (IGammbleGame(g.eventContract).incBetCountForOutcome(
                _eventId,
                _eventOutcomeIndex, 
                _betAmount
            )
        ) 
        //If incBetCountForOutcome returns true then:
        {
            //2. Add new bet in betStorage
            _addBet(msg.sender, Bet({
                eventContract: g.eventContract,
                eventId: _eventId,
                eventOutcomeIndex: _eventOutcomeIndex,
                betAmount: _betAmount,
                betTimestamp: block.timestamp,
                currentState: BetState.Done,
                result: BetResult.Undefined
            }
            ));
         
            //3. change internal balance
            balances[msg.sender] -= _betAmount;
            inBetsAmount += _betAmount;
            emit NewBet(
                msg.sender,
                _gameId,
                _eventId,
                _eventOutcomeIndex,
                _betAmount
            );
            return true;
        } else {
            return false;
        }    
    }

    function cancelBet(uint256 _betId) external {
        //TODO more  checks
        Bet storage b = userBets[msg.sender][_betId];
        if (IGammbleGame(b.eventContract).decBetCountForOutcome(
                b.eventId,
                b.eventOutcomeIndex, 
                b.betAmount
            ))
        {
            //3. change internal balance
            inBetsAmount -= b.betAmount;
            uint256 penalty = b.betAmount / 100 * CANCEL_BET_PENALTY_PERCENT;
            fundBalance += penalty;
            balances[msg.sender] += b.betAmount - penalty; 
            _cancelBet(msg.sender, _betId);
        }

        
    }

    function claimBet(uint256 _betId) external {
        Bet storage b = userBets[msg.sender][_betId];
        require(b.currentState == BetState.Done);
        // GamblingEvent memory e = 
        //     IGammbleGame(b.eventContract).getEvent(b.eventId);
        (bool isWin, uint256 prize) = IGammbleGame(b.eventContract).isWinWithAmount(
            b.eventId, 
            b.eventOutcomeIndex, 
            b.betAmount
        );
        if (isWin == true) {
            ///////////////// WIN CASE /////////////////
            //1. Lets return better own amount + prize
            inBetsAmount -= (b.betAmount + prize);
            balances[msg.sender] += (b.betAmount + prize);
            //save result in bet
            b.result = BetResult.Win;
            emit WinClaimed(msg.sender, _betId, prize);
        } else {
            ///////////////// LOSS CASE /////////////////
            //save result in bet
            b.result = BetResult.Lose;
        }
        //save new (and last) state in bet
        b.currentState = BetState.Claimed;
        
    }

    function withdrawToFund(address _fund, uint256 _amount) external {
        require(enabledFunds[_fund], "This fund is disabled or unknown");
        IERC20(projectToken).safeTransfer(_fund, _amount);
        fundBalance -= _amount;
    }

    //////////////////////////////////////////////////////
    ////    Admin functions    ///////////////////////////
    //////////////////////////////////////////////////////

    function addGame(
        address _eventContract, 
        string memory _name, 
        address _rewardModel
    ) 

        external onlyOwner

    {
        games.push(
            Game({
                eventContract: _eventContract,
                name: _name,
                rewardModelContract: _rewardModel,
                state: GameState.Active
            })
        );
        //TODO  add event
    }

    function setGameState(uint256 _id, GameState _state) external onlyOwner {
        Game storage g = games[_id];
        g.state = _state;
    }

    function settleGameEvent(uint256 _gameId, uint256 _eventId) external onlyOwner {
        require(eventsSettlement[_gameId][_eventId].fundReward == 0, "Event already settled");
        Game memory g = games[_gameId];
        uint256 fundPercent = IRewardModel(g.rewardModelContract).getFundPercent();
        uint256 fReward;
        GamblingEvent memory e = 
            IGammbleGame(g.eventContract).getEvent(_eventId);
        require(e.state == EventState.Finished, "Event is not finished yet"); 
        // lets get fund reward share from this event   
        for (uint8 i = 0; i < e.outcome.length; i ++) {
            if (e.outcome[i].isWin == false) {
                fReward += 
                    uint256(e.outcome[i].weiRaised)
                    * fundPercent //funds share, %
                    * 1e6 //scale denominator
                    /100  //%
                    /1e6; //scale denominator
            }
        }

        //Settlement
        inBetsAmount -= fReward;
        fundBalance  += fReward;

        //Save that this event is settled
        eventsSettlement[_gameId][_eventId].fundReward = fReward;

    }

    function setFundState(address _fund, bool _isEnabled) external onlyOwner {
        enabledFunds[_fund] = _isEnabled;
        emit FundStateChanged(_fund, _isEnabled);
    }


    //////////////////////////////////////////////////////////////////////////////////

    function getGamesCount() external view returns (uint256) {
        return games.length;
    }

    function getUsersBetsCount(address _user) external view returns(uint256) {
        return userBets[_user].length;
    }

    function getUsersBetByIndex(address _user, uint256 _index) external view returns (Bet memory) {
        return userBets[_user][_index];
    }

    function getUserBalance(address _user) external view returns(uint256) {
        //TODO  may be need to refactor.just balances[_user]
        return _availableAmount(_user);
    }

    ////////////////////////////////////////////////////////
    /////                         Internals         ////////
    ////////////////////////////////////////////////////////
    function _addBet(address _user, Bet memory _bet) internal {
        Bet[] storage bets = userBets[_user];
        bets.push(_bet);

    }
     
    function _cancelBet(address _user, uint256 _betId) internal {
        Bet[] storage bets = userBets[_user];
        bets[_betId].currentState = BetState.Canceled;
    }

    function _increaseTotalAmount(address _user, uint256 _amount) internal {
        balances[_user] += _amount;
        totalStaked += _amount;
    }

    function _decreaseTotalAmount(address _user, uint256 _amount) internal {
        balances[_user] -= _amount;
        totalStaked -= _amount;
    }

    function _availableAmount(address _user) internal view returns (uint256) {
        return balances[_user]; 
    }

}