/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    uint256 constant MAXSUPPLY = 1000000;
    uint256 constant Initialsupply = 50000;
    uint256 constant fee = 1;
    address public minter;
    uint256 Totalsupply = Initialsupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    
    constructor()  {minter=msg.sender;
        balances[msg.sender]=Totalsupply;}

    function totalSupply() public view returns (uint256) {
        return Totalsupply;}

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];}

    function mint(address receiver, uint256 amount) public returns (bool) {
        require(msg.sender == minter);
        require(Totalsupply+ amount <= MAXSUPPLY);
        balances[receiver] += amount;
        Totalsupply += amount;
        return true;
        }

    function burn(uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        Totalsupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
        }

    function transferMintership(address newMinter) public returns (bool) {
        require(msg.sender ==minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
        }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(fee <= _value);
        balances[_to]+=(_value - fee);
        balances[msg.sender] -= _value;
        balances[minter] += fee;
        emit Transfer(msg.sender, _to, _value);
        return true;
        }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_value <= balances[_from]);
        require(allowances[_from][msg.sender] >= _value);
        require(fee <= _value);
        balances[_from] -= _value;
        balances[_to] += (_value - fee);
        balances[minter] += fee;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
        }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {return allowances[_owner][_spender];}
}