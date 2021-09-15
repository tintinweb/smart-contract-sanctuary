/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity 0.5.0;

contract Arjun {
    
    uint256 totalsupply;
    
    constructor (uint256 _tsupply) public {
        totalsupply = _tsupply;
        balances[msg.sender] = totalsupply;
        name_ = "Arjun Token";
        symbol_ = "ARJ";
        decimal_ = 0;
        
    }
    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    
    uint8 decimal_;
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }
    
    mapping(address => uint256) balances;
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
       return   balances[_owner];
    }
    event Transfer(address indexed Sender, address indexed Receipient, uint256 NumTokens);
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insuficient tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
}