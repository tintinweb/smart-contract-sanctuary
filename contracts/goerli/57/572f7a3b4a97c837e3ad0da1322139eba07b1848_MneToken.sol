// SPDX-License-Identifier: MIT
// La monnaie - translates to coins/currency.
pragma solidity >=0.4.2;
import "./SafeMath.sol";

contract MneToken {
    using SafeMath for uint256;
    string public name = "La Monnaie";
    string public symbol = "MNE";
    string public standard = "La Monnaie v1.0";
    uint8 public decimals = 5;
    uint256 public totalSupply;

    // `owner` approves `spender` to transfer `value` MNE tokens
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    
    mapping(address => uint256) public balanceOf; // think of this like a hash map
    mapping(address => mapping(address => uint256)) public allowance;
    // maps owner address to a nested mapping of approved address and value.

    constructor(uint256 _initial_supply) public {
        balanceOf[msg.sender] = _initial_supply; // sender - the address that calls this function
        // the test to check total supply fails when the balance of the the 
        // sender is not set.
        totalSupply = _initial_supply;
        emit Transfer(address(0), msg.sender, totalSupply);
        // allocate initial supply
        
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
 
        emit Transfer(msg.sender, _to, _value);
        return true; 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balanceOf[_from] >= _value, "Sender must have sufficient tokens to transfer.");
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] =  balanceOf[_to].add(_value);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}