/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract DevToken{
    // Name
    string public name = "Dev Token";
    // Symble
    string public symble = "dev";
    // Decimal
    uint256 public decimals = 18;
    // TotalSupply
    uint256 public totalSupply;
    
    // 1000000000000000000000000
    // 0x2a1ff88cFf1436190f906616891a249228fC03ab
    // 0x2a1ff88cFf1436190f906616891a249228fC03ab

    // Transfer Event
    event Transfer(address indexed sender, address indexed to, uint256 amount);

    // Return Balance
    mapping( address => uint256 ) public balanceOf;


    // Constructor for totalsuplly
    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    // Transfer Function
    function transfer(address _to, uint256 _amount) public returns (bool success){
        // Balance Check
        require( balanceOf[msg.sender] >= _amount, "You have no enough balance!");
        // Balance reduce from send account
        balanceOf[msg.sender] -= _amount;
        // Balance Incrise to account
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // Approve Function
    mapping(address => mapping(address => uint256)) public allownce;
    // Approve Event
    event Approval( address indexed From, address indexed spender, uint256 amount);
    function approve(address _spender, uint256 _amount) public returns (bool success){
        allownce[msg.sender][_spender] += _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    //Transfer from 
    event TransferFrom(address From, address To, uint256 amount);
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
        require(balanceOf[_from] >= _amount, "You dont have enough balance!");
        require(allownce[_from][msg.sender] >= _amount, "You dont have spender balance!");
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        allownce[_from][msg.sender] -= _amount;
        emit TransferFrom(_from, _to, _amount);
        return true;
    }


}