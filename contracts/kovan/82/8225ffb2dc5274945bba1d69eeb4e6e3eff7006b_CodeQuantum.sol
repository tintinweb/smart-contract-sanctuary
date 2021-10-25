/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CodeQuantum {
    
    // Variables to define tokennomics
    string public name = "Chores";
    string public symbol = "CHR";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;
    
    
    // This allows for a record of verified balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    
    // Transer event for token transfer & approval event for verified recordkeeping
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    
    // vars for functions  
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    // transfer all tokens to "bank" address, receiver of token will return bool true when address receives token
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    // Prevents tokens being sent to the wrong address and adds burn ability by sending to root 0x0 hash address
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
    
    // Allows for DEX to approve transactions before entering into transferFrom function adding to list of approvals on allowance of token
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    
    // Function allows for DEX to sell, transact, and swap tokens amoungst investors
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function burn (uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        return true;
        
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success){
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        
        return true;
        
        
    }
    
    
}