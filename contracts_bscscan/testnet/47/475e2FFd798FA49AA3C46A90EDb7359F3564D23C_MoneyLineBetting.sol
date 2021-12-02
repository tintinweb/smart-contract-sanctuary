/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool public _paused = false;


  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner  whenNotPaused {
    _paused = true;
    emit Paused();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner  whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

contract MoneyLineBetting is Pausable {
    
    using SafeMath for uint256;
    
    struct user {
        uint256 depositAmount;
        uint256 rewardAmount;
        uint8 betTeam; // 1 for Team A and 2 for Team B and 3 for Draw
    }
    
    struct Match {
        string content;
        uint256 oddsFavouiteTeam;
        uint256 oddsUnderDogTeam;
        uint256 drawPoints;
        uint256 startTime;
        uint256 endTime;
        uint256[] bettingCounts;
        uint256 result;
        bool adminApprove;
    }
    
    Match[] public gameInfo;
    mapping (uint256 => mapping ( address => user)) public userInfo;
    
    address public gameAdmin;
    
    event _gameAdd(uint256 gameId,string content,uint256 oddsFavouiteTeamNo,uint256 oddsUnderDogTeamNo,bool adminApprove);
    event _bet(address indexed from,uint256 _gameId,uint256 _amount,uint256 _predictNo);
    event _gameResult(uint256 _gameid,uint256 _winningTeam,uint256 _time);
    event _claimEvent(address indexed from,uint256 _gameid,uint256 _amount,uint256 _time);
    
    constructor (address _gameAdmin) {
        gameAdmin = _gameAdmin;
    }
    
    function addGame(
        string memory _content,
        uint256 _oddsFavouiteTeamNo,
        uint256 _oddsUnderDogTeamNo,
        uint256 _drawNo,
        uint256 _startTime,
        uint256 _endTime) public whenNotPaused{
            
        require(_startTime > block.timestamp && _startTime < _endTime, "Betting :: StartTime is invalid");
        
        bool status = (msg.sender == gameAdmin);
        
        gameInfo.push(Match({
            content : _content,
            oddsFavouiteTeam : _oddsFavouiteTeamNo,
            oddsUnderDogTeam : _oddsUnderDogTeamNo,
            drawPoints : _drawNo,
            startTime : _startTime,
            endTime : _endTime,
            bettingCounts : new uint256[](3),
            result : 0,
            adminApprove : status
        }));
        
        emit _gameAdd(gameInfo.length - 1,_content,_oddsFavouiteTeamNo,_oddsUnderDogTeamNo,status);
    }
    
    function gameApprove(uint256 _gameId) public whenNotPaused {
        require(msg.sender == gameAdmin, "Betting :: GameAdmin only accessible");
        require(!gameInfo[_gameId].adminApprove, "Betting :: already approved");
        require(gameInfo[_gameId].startTime > block.timestamp, "Betting :: Expired");
        
        gameInfo[_gameId].adminApprove =true;
    }
    
    function bet(uint256 _gameId,uint8 _betTeam) external payable whenNotPaused {
        require(gameInfo[_gameId].startTime >= block.timestamp && gameInfo[_gameId].endTime < block.timestamp, "Betting :: Expired");
        require(gameInfo[_gameId].adminApprove, "Betting :: Admin should approved");
        require(_betTeam > 0 && _betTeam < 4 , "Betting :: predict No is invalid, 1 is TeamA, 2 is TeamB and 3 is Draw");
        
        user storage vars = userInfo[_gameId][msg.sender];
        
        require(vars.depositAmount == 0, "Betting :: Already Deposited");
        
        vars.depositAmount = msg.value;
        vars.betTeam = _betTeam;
        gameInfo[_gameId].bettingCounts[_betTeam]++;
            
        emit _bet(msg.sender,_gameId,msg.value,_betTeam);
    }
    
    function resultUpdate(uint256 _gameId,uint256 _result) public whenNotPaused{
        require(msg.sender == gameAdmin, "Betting :: GameAdmin only accessible");
        require(gameInfo[_gameId].endTime < block.timestamp, "Betting :: Match still not finished");
        require(gameInfo[_gameId].adminApprove, "Betting :: Admin should approved");
        require(_result > 0 && _result < 4 , "Betting :: predict No is invalid, 1 is TeamA, 2 is TeamB and 3 is Draw");
        
        gameInfo[_gameId].result = _result;
        
        emit _gameResult(_gameId,_result,block.timestamp);
    }
    
    function claimReward(uint256 _gameId) external whenNotPaused{
        user storage userVars = userInfo[_gameId][msg.sender];
        require(gameInfo[_gameId].result != 0, "Betting :: result still not announced");
        require(gameInfo[_gameId].result == userVars.betTeam, "Betting :: You're Loser");
        require(userVars.rewardAmount == 0, "Betting :: Already issued");
       
        uint256 winAmount;
        if(gameInfo[_gameId].result == 1){
            winAmount = userVars.depositAmount.add(userVars.depositAmount.div((gameInfo[_gameId].oddsFavouiteTeam).div(100)).mul(10 ** 18));
            
            userVars.rewardAmount = winAmount;
            
            payable(msg.sender).transfer(winAmount);
            
            emit _claimEvent(msg.sender,_gameId,winAmount,block.timestamp);
        }else if(gameInfo[_gameId].result == 2){
            winAmount = userVars.depositAmount.add(userVars.depositAmount.mul(gameInfo[_gameId].oddsFavouiteTeam).div(100 * (10 ** 18)));
            
            userVars.rewardAmount = winAmount;
            
            payable(msg.sender).transfer(winAmount);
            
            emit _claimEvent(msg.sender,_gameId,winAmount,block.timestamp);
        }else if(gameInfo[_gameId].result == 3){
            winAmount =  userVars.depositAmount.add(userVars.depositAmount.div((gameInfo[_gameId].oddsFavouiteTeam).div(100)).mul(10 ** 18));
            
            userVars.rewardAmount = winAmount;
            
            payable(msg.sender).transfer(winAmount);
            
            emit _claimEvent(msg.sender,_gameId,winAmount,block.timestamp);
        }
    }
    
    function addGameAdmin(address _gameAdmin) public onlyOwner{
        require(_gameAdmin != address(0), "Invalid Address");
         gameAdmin = _gameAdmin;
    }
    
    function gameLength() external view returns (uint256) {
        return gameInfo.length;
    }
}