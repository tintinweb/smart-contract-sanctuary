/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "SDOACOINS";
    string public symbol = "SDOAS";
    
    uint public numeroDeMoedas = 365000000;
    uint public casasDecimais = 9;
    
    uint public burnRate = 2; // Queima x% dos token transferidos de uma carteira para outra
    uint public liquityFee = 2; // Remuneração do Pool de liquidez 
    uint public donationPercentage = 12; // Cateira de doação x% dos token transferidos para essa carteira
    uint public foundersPercentage = 3; // Cateira de fundadores x% dos token transferidos para essa carteira
    uint public burnValueInitial = 35; // Queima x% dos token transferidos de uma carteira para outra no momento da criação dos tokens
    
    address public donationsWallet = 0xA9Add69Ad2113bcc413660D91e42EAbB21cC7893; // Carteira de doação
    address public foundersWallet = 0x8E5d48ca452D726E5F624E094Ca955a00b7bD29f; // Carteira de fundadores
    address public burnWalletInital = 0x2222222222222222222222222222222222222222; // Carteira de queima inicial
    address public burnWallet = 0x1111111111111111111111111111111111111111; // Carteira de queima
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply = numeroDeMoedas * 10 ** casasDecimais;
    uint public decimals = casasDecimais;
    
    address public contractOwner = msg.sender;
    
    constructor() {
        uint donations = (totalSupply * donationPercentage) / 100;
        uint founders = (totalSupply * foundersPercentage) / 100;
        uint valueToBurn = (totalSupply * burnValueInitial) / 100;
       
        contractOwner = msg.sender;
        balances[burnWalletInital] = valueToBurn;
        balances[donationsWallet] = donations;
        balances[foundersWallet] = founders;
        balances[msg.sender] = totalSupply - donations - founders - valueToBurn;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        uint valueToBurn = (value * burnRate / 100);
        balances[to] += value - valueToBurn;
        balances[burnWallet] += valueToBurn;
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
    
    // transferencia das doações
    function transferDonation(address to, uint value) public returns(bool) {
        if(msg.sender == contractOwner) {
            require(balanceOf(donationsWallet) >= value, 'Saldo insuficiente (balance too low)');
            require(allowance[donationsWallet][msg.sender] >= value, 'Sem permissao (allowance too low)');
            balances[to] += value;
            balances[donationsWallet] -= value;
            emit Transfer(donationsWallet, to, value);
            return true;
        }
        return false;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    
    function resignOwnership(address to) public returns(bool) {
        if(msg.sender == contractOwner) {
            contractOwner = to;
            return true;
        }
        return false;
    }
    
}