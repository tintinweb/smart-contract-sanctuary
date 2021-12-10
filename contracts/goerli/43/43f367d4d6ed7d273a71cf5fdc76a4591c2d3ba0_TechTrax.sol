/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;
 
contract TechTrax {
 
    constructor (uint256 _qty) public {
 
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_   = "TechTrax";
        symbol_ = "TRX";
        decimals_ = 0;
 
    }
 
    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    uint256 tsupply ;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
          require( balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value );
        return true;
 
    }
 
}