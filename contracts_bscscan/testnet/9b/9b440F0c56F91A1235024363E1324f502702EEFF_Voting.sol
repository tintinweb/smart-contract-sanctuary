/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity 0.6.12;
interface dzruptToken {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
contract Voting{
struct poll{
        uint pollId;
        uint startTime;
        uint endTime;
        uint totalVotes;
        string description;
        address entreprenur;
        mapping(address => uint)pollperson;
    }
    
    struct vote{
        address person;
        uint voteAmount;
        bool withdrawApproval;
        bool voteStatus;
        bool withdrawStatus;
    }
    
    modifier onlyowner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    
     modifier isLock() {
        require(lockStatus == false, "Ewaso: Contract Locked");
        _;
    }
    
     event FailSafe(address indexed user, uint value, uint time);
     event AddPoll(uint pollid,address indexed enterprenur, uint starttime,uint endtime, string describe);
     event Poll(address indexed user, address indexed enterprenur,uint pollid,uint amount, uint time);
     event Withdraw(address indexed user,uint pollid,uint amount,uint time);
    
    address public owner;
    using SafeMath for uint256;
     uint public pool;
     dzruptToken public token;
     bool public lockStatus;
    constructor(address _owner,address _token)public{
        owner = _owner;
        token = dzruptToken(_token);
        
    }

    mapping(uint =>poll)public pools;
    mapping(address => mapping(uint => vote))public voters;
    
  function createPoll(address _enterprenur,uint starttime,uint endtime,string memory _describe)public onlyowner{
       pool++;
       pools[pool].pollId = pool;
       pools[pool].startTime = starttime;
       pools[pool].endTime = endtime;
       pools[pool].totalVotes = 0;
       pools[pool].description = _describe;
       pools[pool].entreprenur = _enterprenur;
       emit AddPoll(pool,_enterprenur,pools[pool].startTime,pools[pool].endTime,_describe);
   }
   
   function _poll(uint _pollid,address _candidate,uint amount)public isLock {
       require(pools[_pollid].entreprenur == _candidate,"Wrong canditate for this poll id");
       require(block.timestamp > pools[_pollid].startTime,"Not yet started");
       require(block.timestamp < pools[_pollid].endTime,"poll finished");
       require(token.transferFrom(msg.sender,address(this),amount));
       pools[_pollid].pollperson[_candidate] = pools[_pollid].pollperson[_candidate].add(amount);
       pools[_pollid].totalVotes++;
       voters[msg.sender][_pollid].person = _candidate;
       voters[msg.sender][_pollid].voteAmount = voters[msg.sender][_pollid].voteAmount.add(amount);
       voters[msg.sender][_pollid].withdrawApproval = false;
       voters[msg.sender][_pollid].voteStatus = true;
       voters[msg.sender][_pollid].withdrawStatus = false;
       emit Poll(msg.sender,_candidate,_pollid,amount,block.timestamp);
   }
   
   function withdraw(uint _pollid)public isLock {
       require( voters[msg.sender][_pollid].withdrawApproval == true,"Not approved to withdraw");
       require(block.timestamp > pools[_pollid].endTime,"pool not yet finish");
       uint amount = voters[msg.sender][_pollid].voteAmount;
       token.transfer(msg.sender,amount);
       voters[msg.sender][_pollid].withdrawStatus = true;
       emit Withdraw(msg.sender,_pollid,amount,block.timestamp);
   }
   
   function getApprove(address _user,uint _pollid)public onlyowner{
       require(voters[_user][_pollid].withdrawApproval == false,"Already approved");
       require(block.timestamp > pools[_pollid].endTime,"poll not yet finished");
       voters[_user][_pollid].withdrawApproval = true;
   }
   
    /**
     * @dev failSafe: Returns transfer trx
     */
    function failSafe(address  _toUser, uint _amount) public onlyowner returns(bool) {
        require(_toUser != address(0), "Ewaso: Invalid Address");
        require(token.balanceOf(address(this)) >= _amount, "Ewaso: Insufficient balance");
        token.transfer(_toUser,_amount);
        emit FailSafe(_toUser, _amount, block.timestamp);
        return true;
    }

    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyowner returns(bool) {
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