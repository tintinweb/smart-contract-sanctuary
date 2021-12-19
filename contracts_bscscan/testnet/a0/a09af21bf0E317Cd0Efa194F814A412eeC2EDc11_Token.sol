/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// File: openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: src\contracts\Token.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract Token {
    using SafeMath for uint; 
    
    // Variables
    string public name = "AquagoatDex Token";
    string public symbol = 'AQDEX'; 
    uint256 public decimals = 18; 
    uint256 public totalSupply; 
    mapping(address => uint256) public balanceOf; 
    mapping(address => mapping(address => uint256)) public allowance; 

    // Events 
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Approval(address indexed owner, address indexed spender, uint256 value); 

    constructor() public {
        totalSupply = 1000000 * (10 ** decimals); 
        balanceOf[msg.sender] = totalSupply; 
    }

    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(balanceOf[msg.sender] >= _value); 
        _transfer(msg.sender, _to, _value); 
        return true; 
    } 
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from].sub(_value);  
        balanceOf[_to] = balanceOf[_to].add(_value); 
        emit Transfer(_from, _to, _value); 
    }


    function approve(address _spender, uint256 _value) public returns(bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value; 
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_value <= balanceOf[_from]); 
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); 
        _transfer(_from, _to, _value); 
        return true; 
    }
}