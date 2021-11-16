/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Token {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    string public name = "Coffeeland";
    string public symbol = "CFL";

    uint public numeroDeMoedas = 10000000000000000;
    uint public casasDecimais = 18;

    uint public burnRate = 0; //Queima de 1% de token transferidos de uma carteira para outra

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply = numeroDeMoedas * 10 ** casasDecimais;
    uint public decimals = casasDecimais;

    address public contractOwner;

    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        uint valueToBurn = (value * burnRate / 100);
        balances[to] += value - valueToBurn;
        balances[0xb3dBF14a88418b661a6c57c420a8b4FA63188610] += valueToBurn;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Saldo insuficiente (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Sem permissao (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;

    }

    function destroyTokens(uint value) public returns(bool) {
        if(msg.sender == contractOwner) {
            require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
            totalSupply -= value;
    	    balances[msg.sender] -= value;
            return true;
        }
        return false;
    }

    function resignOwnership() public returns(bool) {
        if(msg.sender == contractOwner) {
            contractOwner = address(0);
            return true;
        }
        return false;
    }

}