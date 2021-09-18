/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Token {

    //uuint stands for unsigned integer
    // These are state variables
    
    // Unique name of the Token
    string public name;
    // The Symbol of the Token
    string public symbol;
    /**
     * The decimals of the Token: The least unit of the Token(For the US Dollars it is 00 means 2 decimals), for Ether it is 18 by convention
     */
    uint256 public decimals;
    // 
    uint256 public totalSupply;

    
    /**
     * The mapping keeps track of the balance based on the address of the user(It is deterministic, it will return the same value everytime)
     */ 
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Log the event of transfer, to keep track of transactions
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Token's cofiguration constructor
    // Local variables start with underscore("_")
    constructor(string memory _name, string memory _symbol, uint _decimals, uint256 initialsupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = initialsupply * 10**decimals;
        // msg.sender refers to the address of the account deploying the smart contract
        // We are assigning total supply to the mapping of the address
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        // If require returns false the compiler will ignore the remaining lines of the function
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        // Emiting the event
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}