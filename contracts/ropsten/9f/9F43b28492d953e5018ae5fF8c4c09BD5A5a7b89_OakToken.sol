/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity 0.5.0;

contract OakToken {
    
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimal;
    }
    string name_;
    function name() public view returns (string memory){
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory){
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8){
        return decimals_;
    }
    uint256 tsupply; // Total number of tokens in contract
    function totalSupply() public view returns (uint256) {
            return tsupply;
    }
    
    mapping (address => uint256) balances; 
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success){
        require( balances[msg.sender] >= _value, " Error: Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        /*        
        a += 10 // Increase value of a by 10.
        a -= 10 // Decrease value of a by 10
        */
    }
    
}