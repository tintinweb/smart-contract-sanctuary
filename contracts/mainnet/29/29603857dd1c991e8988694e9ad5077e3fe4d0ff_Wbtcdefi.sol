/**
 *Submitted for verification at Etherscan.io on 2020-11-28
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by .
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves  tokens from the caller's account to .
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that  will be
     * allowed to spend on behalf of  through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets  as the allowance of  over the caller's tokens.
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
     * @dev Moves  tokens from  to  using the
     * allowance mechanism.  is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when  tokens are moved from one account () to
     * another ().
     *
     * Note that  may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a  for an  is set by
     * a call to {approve}.  is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.6.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a  statement to your contract,
 * which allows you to call the safe operations as , etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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


pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 *  restores this intuition by reverting the transaction when an
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
     * Counterpart to Solidity's  operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's ~ operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's ~ operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's  operator.
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's  operator. Note: this function uses a
     *  opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's  operator. Note: this function uses a
     *  opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's  operator. This function uses a
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's  operator. This function uses a
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if  is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others,  will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's : sends  wei to
     * , forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by , making them unable to receive funds via
     * . {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to , care must be
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
     * @dev Performs a Solidity function call using a low level . A
     * plain is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If  reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[].
     *
     * Requirements:
     *
     * -  must be a contract.
     * - calling  with  must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[], but with
     *  as a fallback revert reason when  reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[],
     * but also transferring  wei to .
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least .
     * - the called Solidity function must be .
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[], but
     * with  as a fallback revert reason when  reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.6;

contract Wbtcdefi {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	// USDT contract  Decimals: 6
	IERC20 public  investToken;
    Token public tevvoToken;

    address public owner;
    address public refundAllocation;
    uint256 private houseFee = 2;
    uint256 private poolTime = 24 hours;
    uint256 private payoutPeriod = 24 hours;
    uint256 private dailyWinPool = 5;
    uint256 private incomeTimes = 30;
    uint256 private incomeDivide = 10;
    uint256 public roundID;
    uint256 public currUserID;
    uint256 public m1 = 0;
    uint256 public m2 = 0;
    uint256 public totalDeposit = 0;
    uint256 public totalWithdrawn = 0;
    uint256[4] private awardPercentage;

    struct Leaderboard {
        uint256 amt;
        address addr;
    }

    Leaderboard[4] public topSponsors;
    
    Leaderboard[4] public lastTopSponsors;
    uint256[4] public lastTopSponsorsWinningAmount;
    address [] public admins;
    uint256 rate = 100000000000000000;// 1 ETH = 100 TVO tokens
        

    mapping (uint => address) public userList;
    mapping (uint256 => DataStructs.DailyRound) public round;
    mapping (address => DataStructs.User) public player;
    mapping (address => bool) public isLeader;
    mapping (address => DataStructs.PlayerEarnings) public playerEarnings;
    mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_; 

    /****************************  EVENTS   *****************************************/

    event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
    event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
    event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);
    event dailyPayoutEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event roundAwardsEvent(address indexed _playerAddress, uint256 indexed _amount);
    event ownershipTransferred(address indexed owner, address indexed newOwner);



    constructor (address _investToken,address _admin, address _tokenToBeUsed, address _refundAllocation) public {
         owner = msg.sender;
         refundAllocation = _refundAllocation;
         investToken = IERC20(_investToken);
         tevvoToken = Token(_tokenToBeUsed);
         roundID = 1;
         round[1].startTime = now;
         round[1].endTime = now + poolTime;
         awardPercentage[0] = 40;
         awardPercentage[1] = 30;
         awardPercentage[2] = 20;
         awardPercentage[3] = 10;
         
         
        currUserID++;
         
        player[_admin].id = currUserID;
        player[_admin].incomeLimitLeft = 500000000000000000000000;
        player[_admin].lastSettledTime = now;
        player[_admin].referralCount = 20;
        playerEarnings[_admin].withdrawableAmount = 15000000000000000000000;
        userList[currUserID] = _admin;
         
         
    }
    
    /****************************  MODIFIERS    *****************************************/
    
    
    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 100000000000000000 || _eth == 0, "Minimum contribution amount is 0.1 ETH");
        _;
    }

    /**
     * @dev sets permissible values for incoming tx
     */
    modifier isallowedValue(uint256 _eth) {
        require(_eth % 100000000000000000 == 0 || _eth == 0, "Only in multiples of 0.1");
        _;
    }
    
    /**
     * @dev allows only the user to run the function
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }


    /****************************  CORE LOGIC    *****************************************/


    //function to maintain the business logic 
    function registerUser(uint256 _referrerID) 
    public
    isWithinLimits(msg.value)
    isallowedValue(msg.value)
    payable {
        
        require(_referrerID > 0 && _referrerID <= currUserID, "Incorrect Referrer ID");
        require(msg.value > 0, "Sorry, incorrect amount");
        address _referrer = userList[_referrerID];
    
        uint256 amount = msg.value;
        if (player[msg.sender].id <= 0) { //if player is a new joinee
        
            currUserID++;
            player[msg.sender].id = currUserID;
            player[msg.sender].lastSettledTime = now;
            player[msg.sender].currInvestment = amount;
            player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
            player[msg.sender].totalInvestment = amount;
            player[msg.sender].referrer = _referrer;
            playerEarnings[msg.sender].withdrawableAmount = amount.mul(15).div(incomeDivide);
            userList[currUserID] = msg.sender;
            
            player[_referrer].referralCount = player[_referrer].referralCount.add(1);
            
            if(_referrer == owner) {
                player[owner].directsIncome = player[owner].directsIncome.add(amount.mul(20).div(100));
                player[owner].totalVolETH += amount;
            }
            else {
                plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                player[_referrer].totalVolETH += amount;
                addSponsorToPool(_referrer);
                //directsReferralBonus(msg.sender, amount);
                investToken.safeTransferFrom(address(msg.sender), address(this), amount);
            }
                
              emit registerUserEvent(msg.sender, _referrer);
        }
            //if the player has already joined earlier
        else {
            withdrawEarnings();
            amount += playerEarnings[msg.sender].lockedAmount; 
            require(player[msg.sender].incomeLimitLeft == 0, "limit is still remaining");
            require(playerEarnings[msg.sender].lockedAmount == player[msg.sender].currInvestment.mul(15).div(incomeDivide));
            _referrer = player[msg.sender].referrer;
            playerEarnings[msg.sender].lockedAmount = 0;
            
            player[msg.sender].lastSettledTime = now;
            player[msg.sender].currInvestment = amount;
            player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
            player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
            playerEarnings[msg.sender].withdrawableAmount = amount.mul(15).div(incomeDivide);
            
            if(_referrer == owner) {
                player[owner].directsIncome = player[owner].directsIncome.add(amount.mul(20).div(100));
                player[owner].totalVolETH += amount;
            }
            else {
                plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                addSponsorToPool(_referrer);
                //directsReferralBonus(msg.sender, amount);
                investToken.safeTransferFrom(address(msg.sender), address(this), amount);
            }
        }
            
            //add amount to daily pool
            round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
            //transfer 2% to  admin
            
            investToken.safeTransfer( address(uint160(owner)), amount.mul(houseFee).div(100));
		    for(uint i=0; i<admins.length; i++){
		        investToken.safeTransfer( address(uint160(admins[i])), amount.div(100));
		    }
	    	investToken.safeTransfer( address(uint160(refundAllocation)), amount.mul(3).div(100));
            
            
            
            
            
            
//            address(uint160(owner)).transfer(amount.mul(houseFee).div(100));
           
//            for(uint i=0; i<admins.length; i++){
//                address(uint160(admins[i])).transfer(amount.div(100));
//            }
            
//            address(uint160(refundAllocation)).transfer(amount.mul(3).div(100));
            
            //calculate token rewards
//            uint256 tokensToAward = amount.div(rate).mul(10e18);
//            tevvoToken.transfer(msg.sender,tokensToAward);
                
            //check if round time has finished
            if (now > round[roundID].endTime && round[roundID].ended == false) {
                startNextRound();
            }
            totalDeposit += amount;
            
            emit investmentEvent (msg.sender, amount);
    }
    
    function directsReferralBonus(address _playerAddress, uint256 amount)
    private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        
        if(isLeader[_nextReferrer] == true){
            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(30).div(100)) {
                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(30).div(100));
                player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(30).div(100));
            
                emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.mul(30).div(100), now);                        
            }
            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(player[_nextReferrer].incomeLimitLeft);
                m1 = m1.add(amount.mul(30).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                player[_nextReferrer].incomeLimitLeft = 0;
            }
            else  {
                m1 = m1.add(amount.mul(30).div(100)); //make a note of the missed commission;
            }
        }
        else {
            if (player[_nextReferrer].incomeLimitLeft >= amount.mul(20).div(100)) {
                player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.mul(20).div(100));
                player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(amount.mul(20).div(100));
            
                emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.mul(20).div(100), now);                        
            }
            else if(player[_nextReferrer].incomeLimitLeft !=0) {
                player[_nextReferrer].directsIncome = player[_nextReferrer].directsIncome.add(player[_nextReferrer].incomeLimitLeft);
                m1 = m1.add(amount.mul(20).div(100).sub(player[_nextReferrer].incomeLimitLeft));
                emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                player[_nextReferrer].incomeLimitLeft = 0;
            }
            else  {
                m1 = m1.add(amount.mul(20).div(100)); //make a note of the missed commission;
            }
        }
    }
    

    //function to manage the matching bonus from the daily ROI
    function roiReferralBonus(address _playerAddress, uint256 amount)
    private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint256 _amountLeft = amount.div(2);
        uint i;

        for(i=0; i < 25; i++) {
            
            if (_nextReferrer != address(0x0)) {
                if(i == 0) {
                    if (player[_nextReferrer].incomeLimitLeft >= amount.div(2)) {
                        player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(2));
                        player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.div(2));
                        
                        emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(2), now);
                        
                    } else if(player[_nextReferrer].incomeLimitLeft !=0) {
                        player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                        m2 = m2.add(amount.div(2).sub(player[_nextReferrer].incomeLimitLeft));
                        emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                        player[_nextReferrer].incomeLimitLeft = 0;
                        
                    }
                    else {
                        m2 = m2.add(amount.div(2)); 
                    }
                    _amountLeft = _amountLeft.sub(amount.div(2));                
                }
                else { // for users 2-25
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.div(20)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(20));
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.div(20));
                            
                            emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(20), now);
                        
                        }else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            m2 = m2.add(amount.div(20).sub(player[_nextReferrer].incomeLimitLeft));
                            emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                            player[_nextReferrer].incomeLimitLeft = 0;                        
                        }
                        else {
                            m2 = m2.add(amount.div(20)); 
                        }
                    }
                    else {
                         m2 = m2.add(amount.div(20)); //make a note of the missed commission;
                    }
                }
            }   
            else {
                    m2 = m2.add((uint(25).sub(i)).mul(amount.div(20)).add(_amountLeft)); 
                    break;                
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }
    

    //method to settle and withdraw the daily ROI
    function settleIncome(address _playerAddress)
    private {
        
            
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;
            
        if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {
            
            //calculate how much time has passed since last settlement
            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;
            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);
            
            currInvestedAmount = player[_playerAddress].currInvestment;
            //calculate 2.5% of his invested amount
            _dailyIncome = currInvestedAmount.div(40);
            //check his income limit remaining
            if (player[_playerAddress].incomeLimitLeft >= _dailyIncome.mul(remainingTimeForPayout)) {
                player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                emit dailyPayoutEvent( _playerAddress, _dailyIncome.mul(remainingTimeForPayout), now);
                roiReferralBonus(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
            }
            //if person income limit lesser than the daily ROI
            else if(player[_playerAddress].incomeLimitLeft !=0) {
                uint256 temp;
                temp = player[_playerAddress].incomeLimitLeft;                 
                player[_playerAddress].incomeLimitLeft = 0;
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(temp);
                player[_playerAddress].lastSettledTime = now;
                emit dailyPayoutEvent( _playerAddress, temp, now);
                roiReferralBonus(_playerAddress, temp);
            }         
        }
        
    }
    

    //function to allow users to withdraw their earnings
    function withdrawEarnings() 
    public {
        
        address _playerAddress = msg.sender;
        
        //settle the daily dividend
        settleIncome(_playerAddress);
        
        uint256 _earnings =
                    player[_playerAddress].dailyIncome +
                    player[_playerAddress].directsIncome +
                    player[_playerAddress].roiReferralIncome +
                    player[_playerAddress].sponsorPoolIncome ;
                    
        uint256 contractBalance = investToken.balanceOf(address(this));
        require(contractBalance >= _earnings, "Oops, short of amount in contract");

        //can only withdraw if they have some earnings.         
        if(_earnings > 0) {
            if(_earnings <= playerEarnings[msg.sender].withdrawableAmount) {
                playerEarnings[msg.sender].withdrawableAmount -= _earnings;
            }
            else {
                playerEarnings[msg.sender].lockedAmount += _earnings.sub(playerEarnings[msg.sender].withdrawableAmount);
                _earnings = playerEarnings[msg.sender].withdrawableAmount;
                playerEarnings[msg.sender].withdrawableAmount = 0;
            }
            
            player[_playerAddress].dailyIncome = 0;
            player[_playerAddress].directsIncome = 0;
            player[_playerAddress].roiReferralIncome = 0;
            player[_playerAddress].sponsorPoolIncome = 0;
            
            totalWithdrawn += _earnings;
            investToken.safeTransfer( msg.sender, _earnings);
//            address(uint160(_playerAddress)).transfer(_earnings);
            emit withdrawEvent(_playerAddress, _earnings, now);
        }
        
        if (now > round[roundID].endTime && round[roundID].ended == false) {
                startNextRound();
            }
    }
    
    
    //To start the new round for daily pool
    function startNextRound()
    private
     {
        uint256 _roundID = roundID;
       
        uint256 _poolAmount = round[roundID].pool;
        
            if (_poolAmount >= 10 ether) {
                round[_roundID].ended = true;
                uint256 distributedSponsorAwards = awardTopPromoters();
                
                _roundID++;
                roundID++;
                round[_roundID].startTime = now;
                round[_roundID].endTime = now.add(poolTime);
                round[_roundID].pool = _poolAmount.sub(distributedSponsorAwards);
            }
            else {
                round[_roundID].startTime = now;
                round[_roundID].endTime = now.add(poolTime);
                round[_roundID].pool = _poolAmount;
            }
        
    }


    
    function addSponsorToPool(address _add)
        private
        returns (bool)
    {
        if (_add == address(0x0)){
            return false;
        }

        uint256 _amt = plyrRnds_[_add][roundID].ethVolume;
        // if the amount is less than the last on the leaderboard, reject
        if (topSponsors[3].amt >= _amt){
            return false;
        }

        address firstAddr = topSponsors[0].addr;
        uint256 firstAmt = topSponsors[0].amt;
        
        address secondAddr = topSponsors[1].addr;
        uint256 secondAmt = topSponsors[1].amt;
        
        address thirdAddr = topSponsors[2].addr;
        uint256 thirdAmt = topSponsors[2].amt;
        


        // if the user should be at the top
        if (_amt > topSponsors[0].amt){

            if (topSponsors[0].addr == _add){
                topSponsors[0].amt = _amt;
                return true;
            }
            //if user is at the second position already and will come on first
            else if (topSponsors[1].addr == _add){

                topSponsors[0].addr = _add;
                topSponsors[0].amt = _amt;
                topSponsors[1].addr = firstAddr;
                topSponsors[1].amt = firstAmt;
                return true;
            }
            //if user is at the third position and will come on first
            else if (topSponsors[2].addr == _add) {
                topSponsors[0].addr = _add;
                topSponsors[0].amt = _amt;
                topSponsors[1].addr = firstAddr;
                topSponsors[1].amt = firstAmt;
                topSponsors[2].addr = secondAddr;
                topSponsors[2].amt = secondAmt;
                return true;
            }
            else{

                topSponsors[0].addr = _add;
                topSponsors[0].amt = _amt;
                topSponsors[1].addr = firstAddr;
                topSponsors[1].amt = firstAmt;
                topSponsors[2].addr = secondAddr;
                topSponsors[2].amt = secondAmt;
                topSponsors[3].addr = thirdAddr;
                topSponsors[3].amt = thirdAmt;
                return true;
            }
        }
        // if the user should be at the second position
        else if (_amt > topSponsors[1].amt){

            if (topSponsors[1].addr == _add){
                topSponsors[1].amt = _amt;
                return true;
            }
            //if user is at the third position, move it to second
            else if(topSponsors[2].addr == _add) {
                topSponsors[1].addr = _add;
                topSponsors[1].amt = _amt;
                topSponsors[2].addr = secondAddr;
                topSponsors[2].amt = secondAmt;
                return true;
            }
            else{
                topSponsors[1].addr = _add;
                topSponsors[1].amt = _amt;
                topSponsors[2].addr = secondAddr;
                topSponsors[2].amt = secondAmt;
                topSponsors[3].addr = thirdAddr;
                topSponsors[3].amt = thirdAmt;
                return true;
            }
        }
        //if the user should be at third position
        else if(_amt > topSponsors[2].amt){
            if(topSponsors[2].addr == _add) {
                topSponsors[2].amt = _amt;
                return true;
            }
            else {
                topSponsors[2].addr = _add;
                topSponsors[2].amt = _amt;
                topSponsors[3].addr = thirdAddr;
                topSponsors[3].amt = thirdAmt;
            }
        }
        // if the user should be at the fourth position
        else if (_amt > topSponsors[3].amt){

             if (topSponsors[3].addr == _add){
                topSponsors[3].amt = _amt;
                return true;
            }
            
            else{
                topSponsors[3].addr = _add;
                topSponsors[3].amt = _amt;
                return true;
            }
        }
    }


    function awardTopPromoters() 
        private 
        returns (uint256)
        {
            uint256 totAmt = round[roundID].pool.mul(10).div(100);
            uint256 distributedAmount;
            uint256 i;
       

            for (i = 0; i< 4; i++) {
                if (topSponsors[i].addr != address(0x0)) {
                    if (player[topSponsors[i].addr].incomeLimitLeft >= totAmt.mul(awardPercentage[i]).div(100)) {
                        player[topSponsors[i].addr].incomeLimitLeft = player[topSponsors[i].addr].incomeLimitLeft.sub(totAmt.mul(awardPercentage[i]).div(100));
                        player[topSponsors[i].addr].sponsorPoolIncome = player[topSponsors[i].addr].sponsorPoolIncome.add(totAmt.mul(awardPercentage[i]).div(100));                                                
                        emit roundAwardsEvent(topSponsors[i].addr, totAmt.mul(awardPercentage[i]).div(100));
                    }
                    else if(player[topSponsors[i].addr].incomeLimitLeft !=0) {
                        player[topSponsors[i].addr].sponsorPoolIncome = player[topSponsors[i].addr].sponsorPoolIncome.add(player[topSponsors[i].addr].incomeLimitLeft);
                        m2 = m2.add((totAmt.mul(awardPercentage[i]).div(100)).sub(player[topSponsors[i].addr].incomeLimitLeft));
                        emit roundAwardsEvent(topSponsors[i].addr,player[topSponsors[i].addr].incomeLimitLeft);
                        player[topSponsors[i].addr].incomeLimitLeft = 0;
                    }
                    else {
                        m2 = m2.add(totAmt.mul(awardPercentage[i]).div(100));
                    }

                    distributedAmount = distributedAmount.add(totAmt.mul(awardPercentage[i]).div(100));
                    lastTopSponsors[i].addr = topSponsors[i].addr;
                    lastTopSponsors[i].amt = topSponsors[i].amt;
                    lastTopSponsorsWinningAmount[i] = totAmt.mul(awardPercentage[i]).div(100);
                    topSponsors[i].addr = address(0x0);
                    topSponsors[i].amt = 0;
                }
            }
            return distributedAmount;
        }

  
    function withdrawAdminFees(uint256 _amount, address _receiver, uint256 _numberUI) public onlyOwner {

        if(_numberUI == 1 && m1 >= _amount) {
            if(_amount > 0) {
                if(address(this).balance >= _amount) {
                    m1 = m1.sub(_amount);
                    address(uint160(_receiver)).transfer(_amount);
                }
            }
        }
        else if(_numberUI == 2 && m2 >= _amount) {
            if(_amount > 0) {
                if(address(this).balance >= _amount) {
                    m2 = m2.sub(_amount);
                    address(uint160(_receiver)).transfer(_amount);
                }
            }
        }
    }
    
    function takeRemainingTVOTokens() public onlyOwner {
        tevvoToken.transfer(owner,tevvoToken.balanceOf(address(this)));
    }
    
    function addAdmin(address _adminAddress) public onlyOwner returns(address [] memory){

        if(admins.length < 5) {
                admins.push(_adminAddress);
            }
        return admins;
    }
    
    function removeAdmin(address  _adminAddress) public onlyOwner returns(address[] memory){

        for(uint i=0; i < admins.length; i++){
            if(admins[i] == _adminAddress) {
                admins[i] = admins[admins.length-1];
                delete admins[admins.length-1];
                admins.pop();
            }
        }
        return admins;

    }
    
    function drawPool() public onlyOwner {
            startNextRound();
        }
        
        function addLeader (address _leaderAddress) public onlyOwner {
            require(isLeader[_leaderAddress] == false,"leader already added");
            
            isLeader[_leaderAddress] = true;
        }

     /* @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}




interface Token {
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function decimals()external view returns (uint8);
}

library DataStructs {

        struct DailyRound {
            uint256 startTime;
            uint256 endTime;
            bool ended; //has daily round ended
            uint256 pool; //amount in the pool;
        }

        struct User {
            uint256 id;
            uint256 totalInvestment;
            uint256 directsIncome;
            uint256 roiReferralIncome;
            uint256 currInvestment;
            uint256 dailyIncome;            
            uint256 lastSettledTime;
            uint256 incomeLimitLeft;
            uint256 sponsorPoolIncome;
            uint256 referralCount;
            address referrer;
            uint256 totalVolETH;
        }
        struct PlayerEarnings {
            uint256 withdrawableAmount;
            uint256 lockedAmount;
        }

        struct PlayerDailyRounds {
            uint256 ethVolume;
        }
}