/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.6.0;
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

contract erc20token { 
    using SafeMath for uint256;
       string name;
      string symbol;
      uint Decimal;
      uint Totalsupply_;
    address payable public owner;
   
 
  mapping(address=>uint)balance;
  
 
  mapping(address=>mapping(address=>uint256))allowed; 
 
  
  
  
   event _transfer(address indexed _from, address indexed to, uint value );
    event approval(address indexed owner,address indexed spender,uint value);
   
  
       constructor()public{
        name = "ERC20basics";
        symbol = "ERC";
        Decimal = 18;
        Totalsupply_= 300000*(10**uint256(Decimal));
        owner = msg.sender;
     balance[owner] = balance[owner].add( Totalsupply_);
    }
      
        
        
    
    
    modifier onlyOwner() {
        require(msg.sender == owner, "UnAuthorized");
         _;
     }
  
 
  
  
   function Totalsupply()public  view returns(uint256){
         
         return Totalsupply_;
     }
     
     
     
   function balanceof(address _owner)public view returns(uint amount){
          
          return balance[_owner];
     }
     
     
     
     function approve(address _spender,uint _value) public  returns(bool){
         allowed[msg.sender][_spender]=_value;
         emit approval(msg.sender,_spender,_value);
         return true;
     } 
     
     
   
     function transfer(address _receiver,uint _amount)public  returns(bool success){
        require (balance[msg.sender]>=_amount);
        balance[msg.sender]-=_amount;
        balance[_receiver]+=_amount;
        emit _transfer(msg.sender,_receiver,_amount);
        return true;
     }
     
     function transferFrom(address _owner,address _to,uint _value)public returns(bool){
        require(balance[_owner] >= _value);
        require( allowed[_owner][msg.sender]>=_value);
        
          balance[_owner] -= _value;
           allowed[_owner][msg.sender] = allowed[_owner][msg.sender]-_value;
          balance[_to] += _value;
          emit _transfer(_owner,_to,_value);
          return true;
         
         
         
     }
     
     function allowance(address from, address to) public view returns (uint) {
        return allowed[from][to];
    }
    function Burn(uint _value)public  returns(bool success) {
        require( balance[msg.sender]>=_value);
        balance[msg.sender]-=_value;
        Totalsupply_-=_value;
        return true;
        
        
    }
    function BurnFrom(address _from,uint _value)public  returns(bool sucees){
        require(_value<=allowed[_from][msg.sender]);
         
         balance[_from]-=_value;
        
        Totalsupply_ -=_value;
        return true;
    }
     function mint(address _owner,uint _value)public returns(bool success){
         balance[_owner]+=_value;
         Totalsupply_+=_value;
         return true;
     }
    
     
}