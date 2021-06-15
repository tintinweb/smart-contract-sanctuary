/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.5.0;

contract KNK {
    
    address admin;
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        totalsupply = _qty;
        balances[msg.sender] = totalsupply;
        admin = msg.sender;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        
    }
    string name_;
    string symbol_;
    uint8 decimal_;
    
    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    
    uint256 totalsupply;
    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }
    
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        //balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    modifier justAdmin {
        require( msg.sender == admin, "Only admin is authorized");
        _;
    }
    
    function mint(uint256 _qty) public justAdmin {
        totalsupply += _qty;
        balances[admin] += _qty;
    }
    
    function burn(uint256 _qty) public justAdmin {
        require( balances[admin] >= _qty, "Not enough tokens to burn");
        totalsupply -= _qty;
        balances[admin] -= _qty;
    }
}