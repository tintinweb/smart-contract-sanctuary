/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.16;

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }
}

contract ERC20{
    
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value)external returns(bool);
    function approve(address _spender,uint _value)external returns(bool);
    function transferFrom(address _from,address _to,uint256 _value)external returns(bool);
    function allowance(address _owner, address _spender)external view returns(uint256);
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
}

contract Seekcoin is ERC20{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public _totalSupply;
    address public owner;
    
    mapping(address => uint)public balances;
    mapping(address => mapping (address => uint)) public allowed;
    
   
    
    constructor()public{
        name = "SEEKCOIN";
        symbol = "seek";
        decimals = 18;
        //_totalSupply = 300000*(10**uint256(decimals));
        _totalSupply = 300000000000000000000;
        owner = msg.sender;
        balances[owner] = balances[owner].add(_totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "UnAuthorized");
         _;
     }
    
      /**
     * @dev allowance : Check approved balance
     */
    
    function allowance(address _owner,address _spender)external view returns(uint256){
        return allowed[_owner][_spender];
    }
    
     /**
     * @dev approve : Approve token for spender
     */ 
    
    function approve(address _spender,uint256 _value)external returns(bool){
        require(_spender != address(0), "invalid");
        require(_value <= balances[msg.sender], "insufficient");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
    }
   
    /**
     * @dev transfer : Transfer token to another etherum address
     */ 
    
    function transfer(address _to,uint256 _value)external returns(bool){
        require(_to != address(0), "invalid");
        require(_value > 0, "insufficient");
        require(balances[msg.sender] >= _value,"insufficeient amount");
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
    /**
     * @dev transferFrom : Transfer token after approval 
     */ 
    
    function transferFrom(address _from,address _to,uint256 _value)external returns(bool){
        require(_from != address(0), "invalid");
        require(_to != address(0), "invalid");
         require(_value <= balances[_from], "Insufficient Balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient Allowance");
        balances[_from] = balances[_from].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }
    
   
     /**
     * @dev totalSupply : Display total supply of token
     */ 
    
    function totalSupply()public view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev balanceOf : Display token balance of given address
     */ 
   
    function balanceOf(address account)external view returns(uint256){
       return balances[account];
    }
    
   function mint( address account,uint256 amount) external onlyOwner {
          require(account != address(0),"ERC20: mint to the zero address");
          balances[account] = balances[account].add(amount);
          _totalSupply = _totalSupply.add(amount);
          emit Transfer(address(0), account, amount);
        
    }
  
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    balances[account] = balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
    
   
}