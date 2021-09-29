/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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


pragma solidity ^0.5.0;

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

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



// File: @openzeppelin/contracts/token/TRC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
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
    function mint(address account, uint amount) external;

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

   // function burn(uint256 amount) external returns (bool);
    function burn(uint256 amount)  external;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address ) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address  recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/TRC20/SafeTRC20.sol

//pragma solidity ^0.5.0;




/**
 * @title SafeTRC20
 * @dev Wrappers around TRC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeTRC20 for TRC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeTRC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 _tokenAddress, address _to, uint256 _value) internal returns (bool success){
        //callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        bytes memory msg = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
        uint msgSize = msg.length;

        assembly {
            // pre-set scratch space to all bits set
            mstore(0x00, 0xff)

            // note: this requires tangerine whistle compatible EVM
            if iszero(call(gas(), _tokenAddress, 0, add(msg, 0x20), msgSize, 0x00, 0x20)) { revert(0, 0) }

            switch mload(0x00)
            case 0xff {
                // token is not fully ERC20 compatible, didn't return anything, assume it was successful
                success := 1
            }
            case 0x01 {
                success := 1
            }
            case 0x00 {
                success := 0
            }
            default {
                // unexpected value, what could this be?
                revert(0, 0)
            }
        }
        
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeBurn(IERC20 token, uint256 value) internal {

        callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
    //function burn(uint256 amount) public  ();

    function totalSupply() public view returns (uint256);
}

// File: contracts/IRewardDistributionRecipient.sol

pragma solidity ^0.5.0;



pragma solidity 0.5.8;
//import "Console.sol";

contract cfilAllswap {
    using SafeMath for uint256;

    struct User {
        address useraddress;
        uint256 Crfilnum;
        bool isentry;
        uint256 hadwithdraw;
        }

    struct IssueInfoNotLimit {  
        uint256 issuenumber;
        uint256 totalCfil;
        uint256 totalDepoistCrfil;
        uint256 ratio;
        uint256 fee;
        //uint256 needswapCfilNotLimit;
        //uint256 userlimit;
        mapping(address => User )  users;
        uint256 starttime;
        uint256 endtime;
        uint256 remainderCfil;
        uint256 swapoutCfil;
    }

    struct IssueInfoLimit {  
        uint256 issuenumber;
        uint256 totalCfil;
        uint256 totalDepoistCrfil;
        uint256 ratio;
        //uint256 needswapCfilLimit;
        uint256 userlimit;
        mapping(address => User )  users;
        uint256 allcrfillimit;
        uint256 swapoutCfil;
        uint256 starttime;
        uint256 endtime;
    }

    mapping(uint256 => IssueInfoNotLimit) public IssueInfoMapNotLimit;
    mapping(uint256 => IssueInfoLimit) public IssueInfoMapLimit;


    address public governance;
    IERC20 public CRFIL = IERC20(0xAE20BC46300BAb5d85612C6BC6EA87eA0F186035);  // CRFIL token CRFIL地址
    
    IERC20 public CFIL = IERC20(0x4eab1d37213B08C224E4C9C28efbA23DC493dFD2);  // CFIL token  DFIL地址
        
     event SetIssueInfoNumberNotLimit(uint256 number, uint256 totalCfil,uint256 ratio, uint256 fee,uint256 starttime,
         uint256 endtime);
    event SwapCfilNotLimit(address user,uint256 onenumber, uint256 amount);
    event WithdrawNotLimit(address user,uint256 onenumber, uint256 amount, uint256 crfllite);

    event SetIssueInfoNumberLimit(uint256 number, uint256 totalCfil,uint256 userlimit,uint256 ratio, uint256 starttime,
         uint256 endtime);
    event SwapCfilLimit(address user,uint256 onenumber, uint256 amount);
    event WithdrawLimit(address user,uint256 onenumber, uint256 amount, uint256 crfllite);

    mapping(uint256 => bool) public onemapLimit;
    mapping(uint256 => bool) public onemapNotLimit;
    mapping (address => bool) public owners;

    constructor( ) public {
        governance = msg.sender;
        owners[msg.sender] = true;
    }

    function addOwner(address _owner) public {
      require(msg.sender == governance, "!governance");
      owners[_owner] = true;
   }

   function removeOwner(address _owner) public {
      require(msg.sender == governance, "!governance");
      owners[_owner] = false;
   }
    
    function setIssueInfoNumberNotLimit(uint256 number, uint256 totalCfil,uint256 ratio, uint256 fee,uint256 starttime,
         uint256 endtime ) public { 
        require(number > 0, "Cannot input 0");
        //require(governance == msg.sender, "not governance");
        require(owners[msg.sender], "!owners");
        require(onemapNotLimit[number]== false, "had add number");
        
        //super.stake(amount);
         CFIL.transferFrom(msg.sender, address(this), totalCfil);
         IssueInfoMapNotLimit[number].issuenumber = number;
         IssueInfoMapNotLimit[number].totalCfil= totalCfil;
         //IssueInfoMapNotLimit[number].userlimit= userlimit;
         IssueInfoMapNotLimit[number].starttime= starttime;
         IssueInfoMapNotLimit[number].endtime= endtime;
         IssueInfoMapNotLimit[number].ratio= ratio;
         IssueInfoMapNotLimit[number].fee= fee;
         onemapNotLimit[number] = true;

        emit  SetIssueInfoNumberNotLimit( number,  totalCfil, ratio, fee, starttime,
          endtime);
    }

    function setIssueInfoNumberLimit(uint256 number, uint256 totalCfil,uint256 userlimit,uint256 ratio ,uint256 allcrfillimit,
    uint256 starttime,uint256 endtime ) public { 
        require(number > 0, "Cannot input 0");
        //require(governance == msg.sender, "not governance");
        require(owners[msg.sender], "!owners");
         require(onemapLimit[number]== false, "had add number");
        //super.stake(amount);
        
         CFIL.transferFrom(msg.sender, address(this), totalCfil);

         IssueInfoMapLimit[number].issuenumber = number;
         IssueInfoMapLimit[number].totalCfil= totalCfil;
         IssueInfoMapLimit[number].userlimit= userlimit;
         IssueInfoMapLimit[number].starttime= starttime;
         IssueInfoMapLimit[number].endtime= endtime;
         IssueInfoMapLimit[number].ratio= ratio;
        IssueInfoMapLimit[number].allcrfillimit= allcrfillimit;
         onemapLimit[number] = true;
        emit  SetIssueInfoNumberLimit( number,  totalCfil, userlimit,ratio, starttime,
          endtime);
    }

    
    function getIssueInfoMapNotLimit(uint256 onenumber) public view returns(uint256 issuenumber,
        uint256 totalCfil,
        uint256 totalDepoistCrfil,
        uint256 ratio,
        uint256 fee,
        uint256 starttime,
        uint256 endtime,
        uint256 remainderCfil,
        uint256 swapoutCfil) {
            
        IssueInfoNotLimit storage info=IssueInfoMapNotLimit[onenumber];
        return (info.issuenumber, info.totalCfil,
        info.totalDepoistCrfil,
        info.ratio,
        info.fee,
        //info.userlimit,
        info.starttime,
        info.endtime,
        info.totalCfil.sub(info.swapoutCfil),
        info.swapoutCfil
            );
        
    }

    function getIssueInfoMapLimit(uint256 onenumber) public view returns(uint256 issuenumber,
        uint256 totalCfil,
        uint256 totalDepoistCrfil,
        uint256 userlimit,
        uint256 ratio,
        uint256 starttime,
        uint256 endtime,
        uint256 remainderCfil,
        uint256 swapoutCfil) {
            
        IssueInfoLimit storage info=IssueInfoMapLimit[onenumber];
        return (info.issuenumber, info.totalCfil,
        info.totalDepoistCrfil,
        info.userlimit,
        info.ratio,
        info.starttime,
        info.endtime,
        info.totalCfil.sub(info.swapoutCfil),
        info.swapoutCfil
            );
        
    }
    

    function getUserInfoNotLimit(uint256 onenumber, address user) public view returns(        
       address useraddress,
        uint256 Crfilnum,
        bool isentry,
        uint256 hadwithdraw) {
            User storage info= IssueInfoMapNotLimit[onenumber].users[user];
            return (info.useraddress, info.Crfilnum, info.isentry, info.hadwithdraw);
            
        }

    function getUserInfoLimit(uint256 onenumber, address user) public view returns(        
       address useraddress,
        uint256 Crfilnum,
        bool isentry,
        uint256 hadwithdraw) {
            User storage info= IssueInfoMapLimit[onenumber].users[user];
            return (info.useraddress, info.Crfilnum, info.isentry, info.hadwithdraw);
            
        }

    
    function getCRFIL(uint number ,bool islimit  ) public {
        //require(governance == msg.sender, "not governance");
        require(owners[msg.sender], "!owners");
        if (islimit) {
            require(IssueInfoMapLimit[number].endtime<block.timestamp, "no end");
            uint re2= IssueInfoMapLimit[number].swapoutCfil.mul(IssueInfoMapLimit[number].ratio);
            CRFIL.transfer(msg.sender, re2);
        } else {
            require(IssueInfoMapNotLimit[number].endtime<block.timestamp, "no end");
            uint re= IssueInfoMapNotLimit[number].swapoutCfil.mul(IssueInfoMapNotLimit[number].ratio).mul(
                IssueInfoMapNotLimit[number].fee.add(1000)).div(1000);
            IssueInfoMapNotLimit[number].fee=0;
            CRFIL.transfer(msg.sender, re);
        }

    }
    
    function getCFIL(uint number ,bool islimit) public {
        //require(governance == msg.sender, "not governance");
        require(owners[msg.sender], "!owners");
        if (islimit) {
           // IssueInfoMapLimit[number]
            require(IssueInfoMapLimit[number].endtime<block.timestamp, "no end");
            uint256 re= IssueInfoMapLimit[number].totalCfil.sub(IssueInfoMapLimit[number].swapoutCfil);
            IssueInfoMapLimit[number].swapoutCfil=IssueInfoMapLimit[number].totalCfil;
            CFIL.transfer(msg.sender, re);
        } else {
            require(IssueInfoMapNotLimit[number].endtime<block.timestamp, "no end");
            uint256 re= IssueInfoMapNotLimit[number].totalCfil.sub(IssueInfoMapNotLimit[number].swapoutCfil);
            IssueInfoMapNotLimit[number].swapoutCfil=IssueInfoMapNotLimit[number].totalCfil;
            CFIL.transfer(msg.sender, re);
        }
    }
    
    
    function swapCfilNotLimit(uint256 onenumber, uint256 amount) public {
         require( IssueInfoMapNotLimit[onenumber].starttime <  block.timestamp, "not start");
         require( IssueInfoMapNotLimit[onenumber].endtime >  block.timestamp, "had  end");
         require(amount > 0, "not 0");
                  
         CRFIL.transferFrom(msg.sender, address(this), amount);
         IssueInfoMapNotLimit[onenumber].users[msg.sender].useraddress = msg.sender;
         IssueInfoMapNotLimit[onenumber].users[msg.sender].isentry = true;
         IssueInfoMapNotLimit[onenumber].users[msg.sender].Crfilnum = amount;
         IssueInfoMapNotLimit[onenumber].totalDepoistCrfil +=amount;
         //require(IssueInfoMapNotLimit[onenumber].totalDepoistCrfil.div(20) <= IssueInfoMapNotLimit[onenumber].totalCfil, "out totalCfil");
         emit SwapCfilNotLimit(msg.sender,onenumber,amount);
    }

    function swapCfilLimit(uint256 onenumber, uint256 amount) public {
         require( IssueInfoMapLimit[onenumber].starttime <  block.timestamp, "not start");
         require( IssueInfoMapLimit[onenumber].endtime >  block.timestamp, "had  end");
         require(amount > 0, "not 0");
         uint256 ratio=IssueInfoMapLimit[onenumber].ratio;
         require(amount.div(ratio) <= IssueInfoMapLimit[onenumber].userlimit, "out user limit");
        require( (IssueInfoMapLimit[onenumber].totalDepoistCrfil+amount)
        <=IssueInfoMapLimit[onenumber].allcrfillimit , "out all crfil limit" );

         CRFIL.transferFrom(msg.sender, address(this), amount);
         IssueInfoMapLimit[onenumber].users[msg.sender].useraddress = msg.sender;
         IssueInfoMapLimit[onenumber].users[msg.sender].isentry = true;
         IssueInfoMapLimit[onenumber].users[msg.sender].Crfilnum = amount;
         IssueInfoMapLimit[onenumber].totalDepoistCrfil +=amount;
         //require(IssueInfoMapLimit[onenumber].totalDepoistCrfil.div(ratio) <= IssueInfoMapLimit[onenumber].totalCfil, "out totalCfil");

         emit SwapCfilLimit(msg.sender,onenumber,amount);
    }

    
    function getuserSwapCfilNotLimit(uint256 onenumber, address user) public view returns(uint256 nsend, uint256 crfllite){
                 
         uint256 ratio= IssueInfoMapNotLimit[onenumber].ratio;
         uint256 totalDepoistCfil = IssueInfoMapNotLimit[onenumber].totalDepoistCrfil.div(ratio);
         //uint256 nsend;
         //uint256 crfllite;
  
         if (totalDepoistCfil<=  IssueInfoMapNotLimit[onenumber].totalCfil) {
             nsend=IssueInfoMapNotLimit[onenumber].users[user].Crfilnum.div(ratio);
            //IssueInfoMapNotLimit[onenumber].users[msg.sender].hadwithdraw = nsend;
         } else {
            uint256 totalDepoistCrfil = IssueInfoMapNotLimit[onenumber].totalDepoistCrfil;
            uint256 totalCfil =IssueInfoMapNotLimit[onenumber].totalCfil;
            uint256 usercrfil = IssueInfoMapNotLimit[onenumber].users[user].Crfilnum;
            
            nsend =  totalCfil.mul(usercrfil).div(totalDepoistCrfil);
            crfllite = usercrfil.sub(nsend.mul(ratio));
             
         }
        return (nsend,crfllite);
    }

    function getuserSwapCfilLimit(uint256 onenumber, address user) public view returns(uint256 cfils,  uint256 crfllite){
        // uint256 nsend=IssueInfoMapLimit[onenumber].users[user].Crfilnum.div(IssueInfoMapLimit[onenumber].ratio);
        
        // return (nsend,0);
         uint256 ratio= IssueInfoMapLimit[onenumber].ratio;
         uint256 totalDepoistCfil = IssueInfoMapLimit[onenumber].totalDepoistCrfil.div(ratio);
         uint256 nsend;
         uint256 crfllite;
  
         if (totalDepoistCfil<=  IssueInfoMapLimit[onenumber].totalCfil) {
             nsend=IssueInfoMapLimit[onenumber].users[user].Crfilnum.div(ratio);
            //IssueInfoMapNotLimit[onenumber].users[msg.sender].hadwithdraw = nsend;
         } else {
            uint256 totalDepoistCrfil = IssueInfoMapLimit[onenumber].totalDepoistCrfil;
            uint256 totalCfil =IssueInfoMapLimit[onenumber].totalCfil;
            uint256 usercrfil = IssueInfoMapLimit[onenumber].users[user].Crfilnum;
            
            nsend =  totalCfil.mul(usercrfil).div(totalDepoistCrfil);
            crfllite = usercrfil.sub(nsend.mul(ratio));
             
         }
        return (nsend,crfllite);
    }


    function withdrawNotLimit(uint256 onenumber) public {
         //require( IssueInfoMapNotLimit[onenumber].starttime <  block.timestamp, "not start");
         require( IssueInfoMapNotLimit[onenumber].endtime <  block.timestamp, "had  end");
         //require(amount > 0, "not 0");
         
        // require(amount.div(20) <= IssueInfoMapNotLimit[onenumber].userlimit, "out user limit");
         require(IssueInfoMapNotLimit[onenumber].users[msg.sender].isentry == true, "not swap" );
        require(IssueInfoMapNotLimit[onenumber].users[msg.sender].hadwithdraw == 0, "had swap" );
        uint256 ratio= IssueInfoMapNotLimit[onenumber].ratio;
         uint256 fee= IssueInfoMapNotLimit[onenumber].fee;
         uint256 totalDepoistCfil = IssueInfoMapNotLimit[onenumber].totalDepoistCrfil.div(ratio);
         uint256 nsend;
         uint256 crfllite;
         uint256 allcfil = CFIL.balanceOf(address(this));
         uint256 allcrfil = CRFIL.balanceOf(address(this));
         if (totalDepoistCfil<=  IssueInfoMapNotLimit[onenumber].totalCfil) {
             nsend=IssueInfoMapNotLimit[onenumber].users[msg.sender].Crfilnum.div(ratio);
             uint256 feeamount=IssueInfoMapNotLimit[onenumber].users[msg.sender].Crfilnum.mul(fee).div(1000);
             CRFIL.transferFrom(msg.sender, address(this), feeamount);
             if (nsend >allcfil) {
                 nsend = allcfil;
                 CFIL.transfer(msg.sender, nsend);
             } else {
                 CFIL.transfer(msg.sender, nsend);
             }
            IssueInfoMapNotLimit[onenumber].swapoutCfil=IssueInfoMapNotLimit[onenumber].swapoutCfil.add(nsend);

            //IssueInfoMapNotLimit[onenumber].users[msg.sender].hadwithdraw = nsend;
         } else {
            uint256 totalDepoistCrfil = IssueInfoMapNotLimit[onenumber].totalDepoistCrfil;
            uint256 totalCfil =IssueInfoMapNotLimit[onenumber].totalCfil;
            uint256 usercrfil = IssueInfoMapNotLimit[onenumber].users[msg.sender].Crfilnum;
            
            nsend =  totalCfil.mul(usercrfil).div(totalDepoistCrfil);
            uint256 feeamount2= nsend.mul(ratio).mul(fee).div(1000);
            
            crfllite = usercrfil.sub(nsend.mul(ratio));
            if (nsend >allcfil) {
                 nsend = allcfil;
                 CFIL.transfer(msg.sender, nsend);
             } else {
                 CFIL.transfer(msg.sender, nsend);
             }
            IssueInfoMapNotLimit[onenumber].swapoutCfil=IssueInfoMapNotLimit[onenumber].swapoutCfil.add(nsend);

             CRFIL.transferFrom(msg.sender, address(this), feeamount2);

             if (crfllite >allcrfil ) {
                 CRFIL.transfer(msg.sender, allcrfil);
             } else {
                 CRFIL.transfer(msg.sender, crfllite);
             }
             
         }
        IssueInfoMapNotLimit[onenumber].users[msg.sender].hadwithdraw = nsend;

         emit WithdrawNotLimit(msg.sender,onenumber, nsend,crfllite);
    }

    function withdrawLimit(uint256 onenumber) public {

         require( IssueInfoMapLimit[onenumber].endtime <  block.timestamp, "had  end");

         require(IssueInfoMapLimit[onenumber].users[msg.sender].isentry == true, "not swap" );
        require(IssueInfoMapLimit[onenumber].users[msg.sender].hadwithdraw == 0, "had swap" );
        uint256 ratio= IssueInfoMapLimit[onenumber].ratio;
         //uint256 fee= IssueInfoMapLimit[onenumber].fee;
         uint256 totalDepoistCfil = IssueInfoMapLimit[onenumber].totalDepoistCrfil.div(ratio);
         uint256 nsend;
         uint256 crfllite;
         uint256 allcfil = CFIL.balanceOf(address(this));
         uint256 allcrfil = CRFIL.balanceOf(address(this));
         if (totalDepoistCfil<=  IssueInfoMapLimit[onenumber].totalCfil) {
             nsend=IssueInfoMapLimit[onenumber].users[msg.sender].Crfilnum.div(ratio);

             if (nsend >allcfil) {
                 nsend = allcfil;
                 CFIL.transfer(msg.sender, nsend);
             } else {
                 CFIL.transfer(msg.sender, nsend);
             }
             
           IssueInfoMapLimit[onenumber].swapoutCfil=IssueInfoMapLimit[onenumber].swapoutCfil.add(nsend);

            //IssueInfoMapNotLimit[onenumber].users[msg.sender].hadwithdraw = nsend;
         } else {
            uint256 totalDepoistCrfil = IssueInfoMapLimit[onenumber].totalDepoistCrfil;
            uint256 totalCfil =IssueInfoMapLimit[onenumber].totalCfil;
            uint256 usercrfil = IssueInfoMapLimit[onenumber].users[msg.sender].Crfilnum;
            
            nsend =  totalCfil.mul(usercrfil).div(totalDepoistCrfil);
           // uint256 feeamount2= nsend.mul(ratio).mul(fee).div(1000);
            
            crfllite = usercrfil.sub(nsend.mul(ratio));
            if (nsend >allcfil) {
                 nsend = allcfil;
                 CFIL.transfer(msg.sender, nsend);
             } else {
                 CFIL.transfer(msg.sender, nsend);
             }
            IssueInfoMapLimit[onenumber].swapoutCfil=IssueInfoMapLimit[onenumber].swapoutCfil.add(nsend);

             if (crfllite >allcrfil ) {
                 CRFIL.transfer(msg.sender, allcrfil);
             } else {
                 CRFIL.transfer(msg.sender, crfllite);
             }
             
         }
        IssueInfoMapLimit[onenumber].users[msg.sender].hadwithdraw = nsend;

         emit WithdrawLimit(msg.sender,onenumber, nsend,crfllite);


    }
    
    


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


}