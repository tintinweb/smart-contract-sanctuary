/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {

    uint256 maxSupply = 1000000;
    address public minter;
    uint256 supply = 50000;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

        mapping(address => uint256) public balances;
        mapping(address => mapping(address => uint256)) public allowances;
    constructor() {balances[msg.sender]=supply;}

    function totalSupply() public view returns (uint256) {
            return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
            return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
            require(msg.sender == minter);
            require(amount < maxSupply);
            balances[receiver] += amount;
            return true;
    }

    function burn(uint256 amount) public returns (bool) {
            require(balances[msg.sender] >= amount);  
            balances[msg.sender] -= amount;           
            supply -= amount;                      
            burn(amount);
            return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
            emit MintershipTransfer(minter, newMinter);
            return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_value <= 1);
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(allowances[_from][msg.sender] >= _value);
        require(_value >= 1);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender]= _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }
}