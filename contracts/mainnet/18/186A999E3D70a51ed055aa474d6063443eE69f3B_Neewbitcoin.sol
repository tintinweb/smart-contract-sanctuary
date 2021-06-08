/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ERC20 {

    uint256 totalsupply;
    address admin;
    
    string name_;
    string symbol_;
    uint8 decimal_;
    
    constructor (string memory _name, string memory _symbol, uint8 _decimal) {
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;

    }
    modifier onlyAdmin {
        require( msg.sender == admin, " Only Admin");
        _;
    }
    event Transfer (address indexed Sender, address indexed Receiver, uint256 NumTokens);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function name() public view returns (string memory){
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require ( balances[msg.sender] >= _value, "Insufficient funds");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( balances[_from]>=_value, "Insufficient tokens");
        require( allowed[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
          
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;  
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function _mint(uint256 _qty) internal onlyAdmin {
        totalsupply += _qty;
        balances[admin] += _qty;
        emit Transfer(address(0), admin, _qty);
    }
    
    function _burn(uint256 _qty) internal onlyAdmin {
        require( balances[msg.sender] >= _qty, " not enough tokens to burn");
        totalsupply -= _qty;
        balances[msg.sender] -= _qty;
        emit Transfer(msg.sender, address(0), _qty);
    }

    function _changeAdmin(address _newaddr) internal onlyAdmin {
        admin = _newaddr;
    }

}

contract Neewbitcoin is ERC20 {

    constructor () ERC20("Neewbitcoin", "NBTC", 0) {
        admin = msg.sender;
        _mint(1000000000000000);
    }

    function newOwner(address _newOwner) public onlyAdmin {
        _changeAdmin(_newOwner);

    }

    function mint(uint256 _qty) public onlyAdmin {
        _mint(_qty);
        
    }

    function burn(uint256 _qty) public onlyAdmin {
        _burn(_qty);
    }
    
}