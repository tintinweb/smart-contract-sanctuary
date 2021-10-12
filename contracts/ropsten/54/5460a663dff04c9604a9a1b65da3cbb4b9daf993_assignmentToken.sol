/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    uint256 constant MAXSUPPLY = 1000000;
    address public minter;
    uint256 supply = 50000;
    uint256 transCost = 1;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );
    
    mapping (address => uint) public balances;
    
    mapping (address => mapping(address => uint)) public allowances;
    constructor() {
        
        minter = msg.sender;
        balances[msg.sender] += supply;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        require(msg.sender == minter);
        require(totalSupply() + amount <= MAXSUPPLY);
        supply += amount;
        balances[receiver] += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount);
        balances[address(0)] += amount;
        balances[msg.sender] -= amount; 
        supply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        require(msg.sender == minter);
        address previousMinter = minter;
        minter = newMinter;
        emit MintershipTransfer(previousMinter,newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value+transCost);
        balances[_to] += _value;
        balances[msg.sender] -= (_value + transCost); 
        balances[minter] += transCost;
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, minter, transCost);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require (balances[_from] >= _value+transCost);
        require (allowances[_from][msg.sender] >= _value + transCost);
        balances[_to] += _value;
        balances[_from] -= _value+1;
        balances[minter] += transCost;
        emit Transfer(_from,_to,_value);
        emit Transfer(_from,minter,transCost);
        allowances[_from][msg.sender] -= _value + transCost;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        uint256 aa = allowances[_owner][_spender];
        return aa;
    }
}