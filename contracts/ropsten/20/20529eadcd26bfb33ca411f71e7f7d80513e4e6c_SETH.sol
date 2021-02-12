/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

contract SETH {
    uint256 total = 0;
    string coinname = "SETH";
    string coinsymbol = "SETH";
    bytes32 gnonce = 0;
    bytes32 req = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
    address token_owner;
    
    constructor() {
        token_owner = msg.sender;
    }
    
    uint d = 2;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public spenderlimit;
    
    function name() public view returns (string memory) {
        return coinname;
    }
    
    function symbol() public view returns (string memory) {
        return coinsymbol;
    }
    
    function decimals() public view returns (uint8) {
        return 16;
    }
    
    function totalSupply() public view returns (uint256) {
        return total;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = balances[_owner];
        return balance;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value) {
            balances[_to] += _value;
            balances[msg.sender] -= _value;
            success = true;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        success = false;
        return false;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (spenderlimit[_from][msg.sender] >= _value && balances[_from] >= _value) {
            spenderlimit[_from][msg.sender] -= _value;
            balances[_to] += _value;
            balances[_from] -= _value;
            success = true;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        success = false;
        return false;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        spenderlimit[msg.sender][_spender] += _value;
        success = false;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = spenderlimit[_owner][_spender];
        return remaining;
    }
    
    /*
    function request(uint256 _value) public {
        require(token_owner == msg.sender);
        balances[msg.sender] += _value;
        total += _value;
    }
    */
    
    function chname(string memory _tokenname, string memory _tokensymbol) public {
        require(token_owner == msg.sender);
        coinsymbol = _tokensymbol;
        coinname = _tokenname;
    }
    
    function deposit() public payable {
        if (msg.value > 0) {
            total += msg.value;
            balances[msg.sender] += msg.value;
        }
    }
    
    receive() external payable {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
        }
    }
    
    function withdraw(uint256 _value) public {
        if (_value > 0 && balances[msg.sender] >= _value) {
            total -= _value;
            balances[msg.sender] -= _value;
            msg.sender.transfer(_value);
        }
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}