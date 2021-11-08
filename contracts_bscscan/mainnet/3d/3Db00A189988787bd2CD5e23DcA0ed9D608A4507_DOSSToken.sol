/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
// DS-Cripto-License-Unicórinio-Parrudo-Paizão-do-Upa-World;P

//*O DOSS Token é o Token de transações da DS Cripto, baseado nos serviços consumidos
//* a DS Cripto queima 1% do lucro de transações uma vez ao mês.
//*O DOSS Token será a única moeda de consumo na plataforma da DS Cripto após implementação.
//* Todas as queimas de Token são interrompidas quando o Suprimento atingir o nível ideal
//* que é de 10 milhões.
//* O Token permanecerá distribuído em carteiras até sua total distribuição, serão distribuidos 5%
//*  para cada periodo de 6 meses.

pragma solidity ^0.8.2;
 
contract DOSSToken { 
 
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
 
    uint public totalSupply = 500000000 * 10 ** 8;
    string public name = "DOSS Token"; 
    string public symbol = "DOSS"; 
    uint public decimals = 8;
 
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
 
    constructor() {
        balances[msg.sender] = totalSupply;
    }
 
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
 
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Sem o Valor necessario');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
 
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Sem o Valor necessario (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Nao Autorizado');
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
 
}