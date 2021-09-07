//SourceUnit: context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: devRole.sol

pragma solidity ^0.6.0;
import "./context.sol";

contract DevRole is Context{

    event OwnershipTransfer(address indexed account);

    address public ownerAddr;
    bool public currentState;


    constructor () internal {
        _changeOwner(0xE087510765D03Ea2ccBA9e1c24C6A839a00d5dA3);
        currentState = true;

    }

    modifier onlyOwner() {
        require(_msgSender() == Owner(),"DevRole: caller is not owner");
        _;
      }

    modifier isNotPaused() {
        require(currentState,"DevRole : paused contract for action");
        _;
    }

    function changeState(bool _state) public onlyOwner returns(bool){
        require(_state != currentState,"DevRole : same state");
        currentState = _state;
        return _state;
    }

    function Owner() public view returns (address) {
        return ownerAddr;
    }

    function changeOwner(address account) external onlyOwner {
      _changeOwner(account);
    }

    function _changeOwner(address account)internal{
      require(account != address(0) && account != ownerAddr ,"DevRole: Address is Owner or zero address");
       ownerAddr = account;
       emit OwnershipTransfer(account);
    }
}


//SourceUnit: kraftlyTeamFund.sol

pragma solidity ^0.6.0;
import "./devRole.sol";
import "./safeMath.sol";

/*
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function burn(uint256 value) external;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
}

contract DevFund is Context,DevRole {

  using SafeMath for uint256;

  // start stamp of FUND LOCK period
  uint256 public startedAt;
  // time gap between two consecutive rounds
  uint256 public unlockPeriod;
  // total claimed round of DEV FUND (can be less than current round)
  uint256 public claimedRound;

  ITRC20 KTYinstance;


  event FundUnlocked(address indexed caller,uint256 amount);
  event FundBurned(address indexed caller,uint256 amount);


  constructor () public {
    // starting lock period from now
    startedAt = now;
    claimedRound = 0;
    unlockPeriod = 60 * 60 * 24 * 365 / 12; // Monthly unlock
    KTYinstance = ITRC20(0xC43c34b74c30818976d32827C1899c1fEf12629B);

   }


   /*
   * @dev returns completed (can be umclaimed) unlock round of KTY DEV fund
   *
   * total round can be 60, 60 * 1 Month = 5 Years
   */


   function unlockRound() public view returns (uint256) {
       uint256 _r = now.sub(startedAt).div(unlockPeriod);
       return _r <= 60 ? _r : 60;
   }

   /*
   * @dev returns KTY unlock amount/round for curent unlockable rounds
   */

   function periodicUnlockAmount() public view returns (uint256) {
     /*
      revert transaction all 60 round already claimed

      each round unlock =  KTY balance / unclaimable round
                        =  KTY balance / (60 - claimable round )
     */
     require(claimedRound <= 60,"DevFund : All round unlocked");
     uint256 _bal = KTYinstance.balanceOf(address(this));
     return _bal.div(uint256(60).sub(claimedRound)); // 15 Millions in 60 Months
   }

   /*
   * @title unlockFund
   * @dev returns total completed and claimed round,
   * this function is public with sender excpectation,and will release fund only to owner address
   */

   function unlockFund()
   public
   isNotPaused
   returns (uint256){
     uint256 _unlockRound = unlockRound();
     uint256 _roundLeft = _unlockRound.sub(claimedRound);
     require(_roundLeft > 0,"DevFund : Unlockable round already claimed");

     uint256 _totalUnlockAmount = periodicUnlockAmount().mul(_roundLeft);

     KTYinstance.transfer(ownerAddr,_totalUnlockAmount);

     claimedRound = _unlockRound;
     emit FundUnlocked(_msgSender(),_totalUnlockAmount);
     return _unlockRound;

   }

   /*
   * @title burnFromLock
   * @param amount to be burned from DEV funds
   * @dev given amount of KTY will be burned from total supply by address(this),
   * and ratio of amount will be reduced from all unclaimed round equally
   */
   function burnFromLock(uint256 amount)
   public
   isNotPaused
   onlyOwner
   returns (bool){
     require(claimedRound <= 60,"DevFund : All round unlocked");
     uint256 _bal = KTYinstance.balanceOf(address(this));
     require(_bal >= amount,"DevFund : Not enough account balance");
     KTYinstance.burn(amount);
     emit FundBurned(_msgSender(),amount);
     return true;
   }

}


//SourceUnit: safeMath.sol

pragma solidity ^0.6.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}