/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.2;
contract TOken{
    uint private totalsupply=200000000000;
    string public name="Bucks";
    string public symbol="BKS";
    uint public decimal=9;
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
   
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
    constructor(){
        balances[msg.sender]=totalsupply;
    }
      function balanceof(address owner)public view returns(uint){
        return balances[owner];
        
    }
    function transfor(address to,uint value)public returns(bool){
        require(balanceof(msg.sender)>=value, 'balances too low');
        
        balances[to] +=value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender,to,value);
        return true;
    }
    function approve(address spender, uint value)public{
        allowances[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
   }
    function transferfrom(address from,address to,uint Value)public{
        require(balanceof(from)>=Value,"balance too low");
        require(allowances[from][msg.sender]>=Value,"allowances low");
      
        emit Transfer (from,to,Value);
        balances[to] +=Value;
        balances[from] -= Value;
        
    }
}
contract airDrop is TOken{
    
    using SafeMath for uint256;
    address payable public owner;
 
    uint256 public claimAmount;
    uint256 public referalAmount; 
    uint256 public startTime;
    uint256 public endTime;
    
    mapping(address => bool) public isClaim;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"not an owner");
        _;
    } 
    
    event Claimed(address _user, address _referrer);
    
    constructor() {
        owner = payable(0x64cB30A482e15F27e2db28c64DBB12D247F1f33c);
  
        claimAmount = 10000 * 1e8;
        referalAmount = 2000 * 1e8;
    //     startTime = block.timestamp;
    //     endTime = block.timestamp + 30 days;
    // }
    
    // receive() payable external{}
    }
    
    function claimAirDrop(address _referrer) public{
      //  require(!address(msg.sender).isContract(),"contracts not allowed");
        require(isClaim[msg.sender] == false,"can not claim twice");
        require(_referrer != address(0) && _referrer != msg.sender,"invalid referrer");
       // require(block.timestamp >= startTime && block.timestamp <= endTime,"time over");
        
        emit TOken.Transfer(owner, msg.sender, claimAmount);
        emit TOken.Transfer(owner, _referrer, referalAmount);
        
      //  isClaim[tx.origin] = true;
        
        emit Claimed(msg.sender, _referrer);
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