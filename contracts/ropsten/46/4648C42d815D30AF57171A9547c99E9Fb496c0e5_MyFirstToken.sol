/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity 0.5.0;

contract MyFirstToken {
    
    constructor (uint256 _qty, uint8 _decimal) public {
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_ = "My First Token";
        symbol_ = "MFT";
        decimal_ = _decimal;
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
    
    
    uint256 tsupply;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    
    mapping ( address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    event Transfer(address indexed Sender, address indexed Receiver, uint256 Amount);
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Not enough token to spend");
        require(allowances[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    mapping(address => mapping(address => uint256)) allowances;
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
}
/*
Receipient 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
Spender. 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
Owner 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c

*/