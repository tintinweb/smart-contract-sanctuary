/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    //mapping is a key value pair e.g address maps to an unsigned int - it's used track who owns what in the smart contract
    //these below keep track of balances and allowances approved.
    mapping(address => uint256) public balanceOf; //basically this mapping is a statement of acccount in bank terms
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value); // a record of the transfer event
    //corresponding to the tranfer function below. - account it's coming from (address from to address to)
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Internal function transfer can only be called by this contract
    //  Emit Transfer Event event 
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Starts with Guard condition to Ensure sending is to valid address
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    // this function allows a spender to spend on your behalf. gives permissions to the spender 
    // so if you list the token on an exchange, So if you list your token on an exchange, the seller sells it for you.
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// return true, success once transfered from original account    
    // Allow _spender to spend up to the _value input on your behalf
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}