/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity 0.4.26;

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

contract AtlantisOrigin{
    using SafeMath for uint256;
    string public name="Atlantis Origin";
    string public symbol="ATS";
    uint8 public decimals=18;
    uint256 public totalSupply= 2000000000 * 10**uint256(decimals);
    mapping(address=>uint256)public balanceOf;
    address private owner;
    address public feeaddr=0x554e0d3392B57178506a27f27D68FDAB93cd653E;
    uint256 public fee=2;
   
   
    function UPfee(uint256 _fee)public{
        require(owner==msg.sender);
        fee=_fee;
    }
    
    function UPfeeaddr(address _feeaddr)public{
        require(owner==msg.sender);
        feeaddr=_feeaddr;
    }
    
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    constructor()public{
      owner=msg.sender;
      balanceOf[owner]=totalSupply;
      emit Transfer(address(0), owner, totalSupply);   
    }
    
    
    function transfer(address _to, uint256 _value)public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
   
     function _transfer(address _from,address _to, uint256 _value)private returns(bool) {
        require(_to != 0x0,"err:");
		require(_value > 0,"err:");
        require (balanceOf[_from]>= _value);  
        require(balanceOf[_to] + _value > balanceOf[_to]); 
        
        balanceOf[_from] = balanceOf[_from].sub( _value);
        
        uint256 fee=_value.mul(fee).div(10**2);
        balanceOf[_to] = balanceOf[_to].add( _value.sub(fee));
        balanceOf[feeaddr] = balanceOf[feeaddr].add(fee);
        emit Transfer(_from, _to, _value);
     }
    
     function transferFrom(address _from, address _to, uint256 _value)public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]);     // Check allowance
        _transfer(_from,_to,_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)public returns (bool success) {
		require (_value > 0) ; 
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function() payable {
        
    }
    
    // transfer balance to owner
	function withdrawEther(uint256 amount) {
	    require(owner==msg.sender);
		owner.transfer(amount);
	}
}