pragma solidity 0.5.17;
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


interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    }
    
interface POWER {
   
   function scaledPower(uint amount) external returns(bool);
   function totalPopping() external view returns (uint256);
 } 

interface OPERATORS {
    
   function scaledOperators(uint amount) external returns(bool);
   function totalPopping() external view returns (uint256);
   
 }
 
    
//======================================POPCORN CONTRACT=========================================//
contract PopcornToken is ERC20 {
    
    using SafeMath for uint256;
    
//======================================POPCORN EVENTS=========================================//
 
    event BurnEvent(address indexed pool, address indexed burnaddress, uint amount);
    event AddCornEvent(address indexed _from, address indexed pool, uint value);
    
   
    
    
   // ERC-20 Parameters
    string public name; 
    string public symbol;
    uint public decimals; 
    uint public totalSupply;
    
    
     //======================================POPPING POOLS=========================================//
    address public pool1;
    address public pool2;

    uint256 public power;
    uint256 public operators;
    uint256 operatorstotalpopping;
    uint256 powertotalpopping;
    
    // ERC-20 Mappings
    mapping(address => uint) public  balanceOf;
    mapping(address => mapping(address => uint)) public  allowance;
    
    
    // Public Parameters
    uint corns; 
    uint  bValue;
    uint  actualValue;
    uint  burnAmount;
    address administrator;
 
    
     
    // Public Mappings
    mapping(address=>bool) public Whitelisted;
    

    //=====================================CREATION=========================================//
    // Constructor
    constructor() public {
        name = "Popcorn Token"; 
        symbol = "CORN"; 
        decimals = 18; 
        corns = 1*10**decimals; 
        totalSupply = 2000000*corns;                                 
        
         
        administrator = msg.sender;
        balanceOf[administrator] = totalSupply; 
        emit Transfer(administrator, address(this), totalSupply);                                 
                                                          
        Whitelisted[administrator] = true;                                         
        
        
        
    }
    
//========================================CONFIGURATIONS=========================================//
    
       function machineries(address _power, address _operators) public onlyAdministrator returns (bool success) {
   
        pool1 = _power;
        pool2 = _operators;
        
        return true;
    }
    
    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyOperators() {
        require(msg.sender == pool2, "Authorization: Only the operators pool can call on this");
        _;
    }
    
    function whitelist(address _address) public onlyAdministrator returns (bool success) {
       Whitelisted[_address] = true;
        return true;
    }
    
    function unwhitelist(address _address) public onlyAdministrator returns (bool success) {
      Whitelisted[_address] = false;
        return true;
    }
    
    
    function Burn(uint _amount) public returns (bool success) {
       
       require(balanceOf[msg.sender] >= _amount, "You do not have the amount of tokens you wanna burn in your wallet");
       balanceOf[msg.sender] -= _amount;
       totalSupply -= _amount;
       emit BurnEvent(pool2, address(0x0), _amount);
       return true;
       
    }
    
    
   //========================================ERC20=========================================//
    // ERC20 Transfer function
    function transfer(address to, uint value) public  returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    
    // ERC20 Approve function
    function approve(address spender, uint value) public  returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    // ERC20 TransferFrom function
    function transferFrom(address from, address to, uint value) public  returns (bool success) {
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
  
    
    
    function _transfer(address _from, address _to, uint _value) private {
        
        require(balanceOf[_from] >= _value, 'Must not send more than balance');
        require(balanceOf[_to] + _value >= balanceOf[_to], 'Balance overflow');
        
        balanceOf[_from] -= _value;
        if(Whitelisted[msg.sender]){ 
        
          actualValue = _value;
          
        }else{
         
        bValue = mulDiv(_value, 10, 100); 
       
        actualValue = _value.sub(bValue); 
        
        
        power = mulDiv(bValue, 50, 100);
        powertotalpopping = powerTotalPopping();
        
        if(powertotalpopping > 0){
                    
                POWER(pool1).scaledPower(power);
                balanceOf[pool1] += power;
                emit AddCornEvent(_from, pool1, power);
                emit Transfer(_from, pool1, power);
                
                
                    
                }else{
                  
                 totalSupply -= power; 
                 emit BurnEvent(_from, address(0x0), power);
                    
        }
        
        
        
        operators = mulDiv(bValue, 30, 100);
        operatorstotalpopping = OperatorsTotalPopping();
        
        if(operatorstotalpopping > 0){
                    
                OPERATORS(pool2).scaledOperators(operators);
                balanceOf[pool2] += operators;
                emit AddCornEvent(_from, pool2, operators);
                emit Transfer(_from, pool2, operators);
                
                    
                }else{
                  
                totalSupply -= operators; 
                emit BurnEvent(_from, address(0x0), operators); 
                    
        }
        
        
        
        burnAmount = mulDiv(bValue, 20, 100);
        totalSupply -= burnAmount;
        emit BurnEvent(_from, address(0x0), burnAmount);
       
        }
        
        
       
       balanceOf[_to] += actualValue;
       emit Transfer(_from, _to, _value);
       
       
    }
    
 
  
  
  
    function powerTotalPopping() public view returns(uint){
        
        return POWER(pool1).totalPopping();
       
    }
    
    function OperatorsTotalPopping() public view returns(uint){
        
        return OPERATORS(pool2).totalPopping();
       
    }
    
   
    
     function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }
    
     function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }
    
   
}