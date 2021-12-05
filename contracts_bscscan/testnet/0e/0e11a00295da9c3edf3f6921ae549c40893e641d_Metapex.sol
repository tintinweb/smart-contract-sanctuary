/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Metapex is SafeMath{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    /*create array to hold all balances */
    mapping(address=>uint256)public balanceOf;
    mapping(address=>uint256) public freezeOf;
    mapping(address=>uint256) public lockOf;
    mapping(address=>mapping(address=>uint256)) public allowance;

    /*public events on Blockchain that will notify clients*/
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from,uint256 value);
    event Unfreeze(address indexed from,uint256 value);
    event Lock(address indexed from,uint256 value);
    event Unlock(address indexed from,uint256 value);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        uint256 _initialSupply,
        uint8 _decimalUnits
        ) {
        balanceOf[msg.sender] = _initialSupply;              // Give the creator all initial tokens
        totalSupply = _initialSupply;                        // Update total supply
        name = "METAPEX";                                   // Set the name for display purposes
        symbol = "MTPX";                               // Set the symbol for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
		owner = msg.sender;                                 //set contract owner
		    
    }

        /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (_value <= 0) return; 
        require(balanceOf[msg.sender] >=_value,"not enough funds");
        //if (balanceOf[msg.sender] < _value) return;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return; // Check for overflows
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender],_value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.add(balanceOf[_to],_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place

    }

        /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public  returns (bool success) {
		if (_value <= 0) return false; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		if (_value <= 0) return false; 
        require(balanceOf[_from] >=_value,"not enough funds");
        //if (balanceOf[_from] < _value) return;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) return false;     // Check allowance
        balanceOf[_from] = SafeMath.sub(balanceOf[_from],_value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to],_value); 
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;

    }

    function burn(uint256 _value) public returns (bool success) {
        // Only the contract owner can call this function
        require(msg.sender == owner,"You are not owner");
        //if (balanceOf[msg.sender] < _value) return;            // Check if the sender has enough
		require(balanceOf[msg.sender] >=_value,"not enough funds");
        if (_value <= 0) return false;
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender],_value);           // Subtract from the sender
        totalSupply = SafeMath.sub(totalSupply,_value);   
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _account, uint256 _amount) public returns (bool) {
        // Only the contract owner can call this function
        require(msg.sender == owner,"You are not owner");
        totalSupply = SafeMath.add(totalSupply,_amount); 
        balanceOf[_account]=  SafeMath.add(balanceOf[_account],_amount);
        emit Transfer(owner, _account, _amount);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >=_value,"not enough funds");
        //if (balanceOf[msg.sender] < _value) return;            // Check if the sender has enough
		if (_value <= 0) return false; 
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.add(freezeOf[msg.sender], _value);                        // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >=_value,"not enough funds");
        //if (freezeOf[msg.sender] < _value) return;            // Check if the sender has enough
		if (_value <= 0) return false;
        freezeOf[msg.sender] = SafeMath.sub(freezeOf[msg.sender],_value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender],_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function transfers(address _from, address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner,"You are not owner");        
        if (_value <= 0) return false; 
        require(balanceOf[_from] >=_value,"not enough funds");
        //if (balanceOf[_from] < _value) return;
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;
        balanceOf[_from] = SafeMath.sub(balanceOf[_from],_value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.add(balanceOf[_to],_value);
        emit Transfer(_from, _to, _value);
        return true;        
    }


    function lock(address _from,uint256 _value) public returns (bool success) {
        require(msg.sender == owner,"You are not owner");
        require(balanceOf[_from] >=_value,"not enough funds");
        //if (balanceOf[msg.sender] < _value) return;            // Check if the sender has enough
		if (_value <= 0) return false; 
        balanceOf[_from] = SafeMath.sub(balanceOf[_from],_value);                      // Subtract from the sender
        lockOf[_from] = SafeMath.add(lockOf[_from],_value);                        // Updates totalSupply
        emit Lock(_from, _value);
        return true;
    }
    
    function unlock(address _from,uint256 _value) public returns (bool success) {
        require(msg.sender == owner,"You are not owner");
        require(lockOf[_from] >=_value,"not enough funds");
        //if (freezeOf[msg.sender] < _value) return;            // Check if the sender has enough
		if (_value <= 0) return false;
        lockOf[_from] = SafeMath.sub(lockOf[_from],_value);                      // Subtract from the sender
		balanceOf[_from] = SafeMath.add(balanceOf[_from],_value);
        emit Unlock(_from, _value);
        return true;
    }


}