/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

// import './interfaces/IERC20.sol';
// import './Library/SafeMath.sol';
// import './libraries/Address.sol';
// import './TokenContract.sol';


// Bep20 standards for token creation



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
        // require(c / a == b, "SafeMath: multiplication overflow");

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


contract  OPT {
    
    using SafeMath for uint256;
    // using Address for address;
    
    address payable public owner;  
    string public  name;
    string public  symbol;
    uint8 public  decimals;
    uint256 public  totalSupply;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
    
    event Freeze(address target, bool frozen);
    event Unfreeze(address target, bool frozen);
    event Burn(address target, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner,"not an owner");
        _;
    }

    modifier whenNotFrozen(address target) {
        require(!frozen[target],"BEP20: account is freeze already");
        _;
    }

    modifier whenFrozen(address target){
        require(frozen[target],"BEP20: tokens is not freeze");
        _;
    }
    
    constructor(address payable _owner) {
        owner = _owner;
        name = "OPT Token";
        symbol = "opt";
        decimals = 18;
        totalSupply = 100000000e18;   
        balances[owner] = totalSupply;
    }
    
    function balanceOf(address _owner) view public  returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public   returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public  whenNotFrozen(msg.sender){
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        // emit Transfer(msg.sender,_to,_amount);
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public   whenNotFrozen(msg.sender){
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        // emit Transfer(_from, _to, _amount);
    }
  
    function approve(address _spender, uint256 _amount) public  whenNotFrozen(msg.sender){
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        // emit Approval(msg.sender, _spender, _amount);
    }

    function FreezeAcc(address target) onlyOwner public whenNotFrozen(target) returns (bool) {
        frozen[target]=true;
        emit Freeze(target, true);
        return true;
    }

    function UnfreezeAcc(address target) onlyOwner public whenFrozen(target) returns (bool) {
        frozen[target]=false;
        emit Unfreeze(target, false);
        return true;
    }
    
    function burn(uint256 _value) public whenNotFrozen(msg.sender){
        require(balances[msg.sender] >= _value, "BEP20: user balance is insufficient");   
        
        balances[msg.sender] =balances[msg.sender].sub(_value);
        totalSupply =totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
    
}