//SourceUnit: ewasoreward.sol

pragma solidity 0.5.14;

interface TRC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface EWASO{
    function contractCreation()external view returns(uint);
    function checkjointime(address user)external view returns(uint);
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
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers.
     * (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. 
     * (unsigned integer modulo),
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ewasoreward{
    
    using SafeMath for uint256;
    // Owner address
    address public owner;
    // Ewaso contract address
    EWASO public ewaso;
    // Token contract address
    TRC20 public token;
    // First 45 days amount
    uint public amount1 = 100e6;
     // Contract lock
    bool public lockStatus;
    // Bonus end time
    uint32 public endTime;
    
      // Failsafe event
    event FailSafe(address indexed user, uint value, uint time);
    event Claim(address indexed from,uint value,uint time);
    // Mapping address for bool
    mapping (address => bool)public claimed;
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ewaso: Only Owner");
        _;
    }
    
    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "Ewaso: Contract Locked");
        _;
    }
    
    /**
     * @dev Throws if called by other contract
     */
    modifier isContractcheck(address _user) {
        require(!isContract(_user), "Ewaso: Invalid address");
        _;
    }
    
    constructor(address _token,address _ewaso,address _owner,uint32 _endTime) public {
        token = TRC20(_token);
        owner = _owner;
        ewaso = EWASO(_ewaso);
        endTime = _endTime;
    }
    
    function claim(address _user) external isLock isContractcheck(msg.sender) {
        require(claimed[_user] == false, "Already claimed");
        uint joinTime = ewaso.checkjointime(_user);
        uint createTime = ewaso.contractCreation();
        require(joinTime > 0 && createTime > 0,"user not joined");
        require(joinTime < endTime,"Offers time over");
        token.transfer(_user,amount1);
        claimed[_user] = true;
        emit Claim(_user,amount1,block.timestamp);
    }
    
    function addToken(uint amount)public onlyOwner{
        token.transferFrom(owner,address(this),amount);
    }
    
    /**
     * @dev failSafe: Returns transfer trx
     */
    function failSafe(address _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Ewaso: Invalid Address");
        require(token.balanceOf(address(this)) >= _amount, "Ewaso: Insufficient balance");
        token.transfer(_toUser,_amount);
        emit FailSafe(_toUser, _amount, block.timestamp);
        return true;
    }
    
    function updateAmount(uint amt1)public onlyOwner{
        amount1 = amt1;
    }
    
    function updateTime(uint32 _time) public onlyOwner {
        endTime = _time;
    }
    
     /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
}