/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    
    // Variables
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    // Keep Track balances and Allowances approved - transfer from your address to other address
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Events Logger
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed Spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require (balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
        
    }
    
    // _to : receiver , _from : sender, _value : no of tokens
    function _transfer(address _from, address _to, uint _value ) internal {
        
        // Ensure Sending to the  valid Address! 0x0 can be burn()???
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
    
    // Approve to spend on your behalf Like Exchanges or swaps for pool
    // Spender allowed to spend and approved/max amt to be spend
    // emits or logs the approved event
    // will return true after approving
    function approve(address _spender, uint256 _value) external returns(bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
    // Normal transfer Function after approving func approvesthe spender
    // from - address sending to , 
    function transferFrom(address _from, address _to, uint256 _value ) external returns(bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
}