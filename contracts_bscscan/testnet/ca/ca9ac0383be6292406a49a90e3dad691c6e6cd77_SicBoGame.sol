/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
// 
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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

// 
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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
// 
/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

contract SicBoGame  {
    struct BidTicket { 
        uint256 bid;
        uint256 time;
        uint256 value;
        uint256 currentTotal;
    }
    struct BidTicketHistory{
        BidTicket tiket;
        address player;
    }
    struct UserSummary{
        uint256 totalDeposit;
        uint256 totalWithdrawl;
        uint256[] unclaimRounds;
        uint256[] rounds;
    }
    struct GameRound{
        uint256 startTime;
        uint256 winningBid;
        uint256 dice1;
        uint256 dice2;
        uint256 dice3;
        uint256 limitAmount;
        uint256 drawingTime;
        uint256 totalAmountLow;
        uint256 totalAmountHigh;
        
    }
    struct Leader{
        address player;
        uint256 totalDeposit;
    }
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20; 
    address public adminAddress;
    address[] public users;
    IBEP20 public tokenAddress;
    mapping (uint256 => GameRound) public historyRounds;
    mapping (address => mapping(uint256=>BidTicket[])) public userInfo;//address=>round=>tiket
    mapping (address => mapping(uint256=>uint256)) public userRoundInfo;//address=>round=>bid
    mapping (address => UserSummary) public usersSummary;
    mapping (uint256 => BidTicketHistory[]) public historyRoundBids;
    address[] leadersBoard;
    uint256 public totalFee = 0;
    uint256 public round = 1;
    GameRound public currentRound;
    bool public alreadyRebalancedRound = false;
    bool public gameEnable = false;
    constructor(IBEP20 _tokenAddress) {
        adminAddress = msg.sender;   
        tokenAddress =_tokenAddress;
    }
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Sicbo: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }
    modifier canDeposit(){
        require (!alreadyRebalancedRound && block.timestamp >currentRound.startTime.add(14),"not time to deposit");
        _;
    }
    function transferAdmin(address _to) public onlyAdmin{
        adminAddress = _to;
    }
    function enableGame() public onlyAdmin{
        require(!gameEnable,'game already enabled');
        gameEnable = true;
    }
    function disableGame() public onlyAdmin{
        require(gameEnable,'game already disabled');
        gameEnable = false;
    }
    
    function getLengthPending(address _player) public view returns(uint256){
        return usersSummary[_player].unclaimRounds.length;
    }
    function rebalanceRound() private {
        if(!alreadyRebalancedRound && block.timestamp>currentRound.startTime.add(112)){
            alreadyRebalancedRound = true;
            currentRound.limitAmount = currentRound.totalAmountLow<currentRound.totalAmountHigh?currentRound.totalAmountLow:currentRound.totalAmountHigh;
        }
        
    }
    function drawing(uint256 _externalRandomNumber) public onlyAdmin {
        rebalanceRound();
        require(gameEnable,'game already disabled');
        require(block.timestamp>currentRound.startTime.add(117),"it's not time to draw yet");
        createWinningNumber(_externalRandomNumber);
        calFee();
        reset();
    }
    function getLastRoundDrawed() public view returns(GameRound memory){
        return historyRounds[round.sub(1)];
    }
    function createWinningNumber(uint256 _externalRandomNumber) private{
        bytes32 _structHash;
        uint256 _randomNumber;
        bytes32 _blockhash1 = blockhash(block.number-1);
        bytes32 _blockhash2 = blockhash(block.number-2);
        
        //dice1
        _structHash = keccak256(
            abi.encode(
                _blockhash1,
                block.timestamp,
                currentRound.totalAmountHigh,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, 6),1)}
        currentRound.dice1= _randomNumber;
        //dice2
         _structHash = keccak256(
            abi.encode(
                _blockhash2,
                block.timestamp,
                round,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, 6),1)}
        currentRound.dice2 = _randomNumber;
        // dice3
         _structHash = keccak256(
            abi.encode(
                block.difficulty,
                block.timestamp,
                block.number,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, 6),1)}
        currentRound.dice3 = _randomNumber;
        //winningBid
        if(currentRound.dice1.add(currentRound.dice2).add(currentRound.dice3)<11){
            currentRound.winningBid = 0;
        }
        else{
            currentRound.winningBid = 1;
        }
        //
        currentRound.drawingTime = block.timestamp;
        historyRounds[round] = currentRound;
    }
    function reset() private{
        round = round.add(1);
        currentRound =  GameRound(block.timestamp,0,0,0,0,0,0,0,0);
        alreadyRebalancedRound = false;
    }
    function calFee() private{
        totalFee = totalFee.add(currentRound.limitAmount.div(50));
    }
    function claimReward() public lock{
        uint256 rewardPending = calRewardPending(msg.sender);
        require(rewardPending>0,'nothing to claim');
        tokenAddress.safeTransfer(msg.sender, rewardPending);
        usersSummary[msg.sender].totalWithdrawl = usersSummary[msg.sender].totalWithdrawl.add(rewardPending);
        delete usersSummary[msg.sender].unclaimRounds;
    }
    function calRewardPending(address _player) public view returns (uint256)  {
        uint256 totalPending = 0;
        if(usersSummary[_player].unclaimRounds.length>0){
            uint256 lastRoundCheck = 0;
            uint256 lastRoundClaimable = round.sub(1);
            for(uint i = 0;i<usersSummary[_player].unclaimRounds.length;i++){
                if(usersSummary[_player].unclaimRounds[i]>lastRoundCheck && usersSummary[_player].unclaimRounds[i]<=lastRoundClaimable){
                    lastRoundCheck = usersSummary[_player].unclaimRounds[i];
                    totalPending = totalPending.add(getRewardPendingInRound(lastRoundCheck,_player));
                }
            }
        }
        return totalPending;
        
    }
    function getRewardPendingInRound(uint256 _round,address _player) private view returns (uint256) {
        uint256 totalPendingRound = 0;
        for(uint i=0;i<userInfo[_player][_round].length;i++){
            if(userInfo[_player][_round][i].currentTotal>=historyRounds[_round].limitAmount){
                totalPendingRound = totalPendingRound.add(userInfo[_player][_round][i].value);
            }
            else if(userInfo[_player][_round][i].currentTotal.add(userInfo[_player][_round][i].value)>historyRounds[_round].limitAmount){//
                uint256 validValue = historyRounds[_round].limitAmount.sub(userInfo[_player][_round][i].currentTotal);
                uint256 invalidValue = userInfo[_player][_round][i].value.sub(validValue);
                totalPendingRound = totalPendingRound.add(invalidValue);
                if(userInfo[_player][_round][i].bid==historyRounds[_round].winningBid){
                    totalPendingRound = totalPendingRound.add(validValue.div(100).mul(198));
                }
            }
            else{
                if(userInfo[_player][_round][i].bid==historyRounds[_round].winningBid){
                    totalPendingRound = totalPendingRound.add(userInfo[_player][_round][i].value.div(100).mul(198));
                }
            }
        }
        return totalPendingRound;
        
    }
    function deposit(uint256 _bid, uint256 _value) public lock canDeposit{
        require(gameEnable,'game is disabled');
        require(_bid<2,'bid invaild. 0 for low and 1 for high');
        require(userInfo[msg.sender][round].length==0 || userRoundInfo[msg.sender][round] == _bid , 'you played this round');
        //
        tokenAddress.safeTransferFrom(msg.sender, address(this), _value);
        if(_bid==0){
            addTicket(BidTicket(_bid,block.timestamp,_value,currentRound.totalAmountLow));
        }
        else{
            addTicket(BidTicket(_bid,block.timestamp,_value,currentRound.totalAmountHigh));
        }
        //
        
        if(usersSummary[msg.sender].totalDeposit==0){
            users.push(msg.sender);
        }
        usersSummary[msg.sender].totalDeposit = usersSummary[msg.sender].totalDeposit.add(_value);
        usersSummary[msg.sender].unclaimRounds.push(round);
        usersSummary[msg.sender].rounds.push(round);
        userRoundInfo[msg.sender][round] = _bid;
        updateToLeaderBoard();
        rebalanceRound();
        
    }
    function addTicket(BidTicket memory ticket) private{
         userInfo[msg.sender][round].push(ticket);
         historyRoundBids[round].push(BidTicketHistory(ticket,msg.sender));
         if(ticket.bid==0){
             currentRound.totalAmountLow = currentRound.totalAmountLow.add(ticket.value);
         }
         else{
            currentRound.totalAmountHigh = currentRound.totalAmountHigh.add(ticket.value);    
         }
    }
    function updateToLeaderBoard() private{
        
        if(leadersBoard.length==0){
            leadersBoard.push(msg.sender);
        }
        else if(leadersBoard.length<11 || usersSummary[msg.sender].totalDeposit>usersSummary[leadersBoard[leadersBoard.length.sub(1)]].totalDeposit)
        {
            address currentPlayer = msg.sender;
            address  playerTmp = msg.sender;
            for(uint i=0;i<leadersBoard.length;i++){
                if(usersSummary[currentPlayer].totalDeposit>usersSummary[leadersBoard[i]].totalDeposit){
                    playerTmp = leadersBoard[i];
                    leadersBoard[i] = currentPlayer;
                    currentPlayer = playerTmp;
                }
            }
            if(leadersBoard.length<10){
                leadersBoard.push(currentPlayer);
            }
        }
        
    }
    function withdrawalFee() public onlyAdmin {
        require(totalFee>0,'nothing to withdrawl');
        tokenAddress.safeTransfer(adminAddress, totalFee);
        totalFee = 0;
    }
    function getAmountByUserRound(address _player,uint256 _round, uint256 _bid) public view returns (uint256) {
        uint256 currentAmount = 0;
         for(uint i=0;i<userInfo[_player][_round].length;i++){
            BidTicket storage ticket = userInfo[_player][_round][i];
            if(ticket.bid == _bid){
                currentAmount = currentAmount.add(ticket.value);
            } 
        }
        return currentAmount;
    }
    function getHistoryByUser(address _player) public view returns (BidTicket[50] memory){
        uint numberOfRounds  = usersSummary[_player].rounds.length;
        BidTicket[50] memory listTicket;
        if(numberOfRounds>0){
            uint start = numberOfRounds>50?numberOfRounds-50:0;
            for(uint i=start;i<numberOfRounds;i++){
                if(userInfo[_player][usersSummary[_player].rounds[i]].length>0){
                    BidTicket memory ticket = userInfo[_player][usersSummary[_player].rounds[i]][0];
                    listTicket[i-start]=ticket;
                }
            }
        }
        return listTicket;
    }
    function getListTicketByUserAndRound(address _player,uint256 _round) public view returns (BidTicket[] memory){
        return userInfo[_player][_round];
    }
    function getListTicketByRound(uint256 _round) public view returns (BidTicketHistory[] memory){
        return historyRoundBids[_round];
    }
    function getLeaderBoard() public view returns (address[] memory){
        return leadersBoard;
    }
}