/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * DOACOINS é a primeira criptomoeda de usabilidade convencional voltada para doação global. 
 * Objetivo: Mais que conscientização social, queremos através da nossa comunidade terceirizar e gerar o maior movimento destinado a doação e usabilidade global com a criptomoeda DOACOINS.
 * Missão: Cumpriremos com o incentivo de práticas sociais tais como (DOAÇÕES) que por muitas vezes são impraticáveis por diversos motivos perante a sociedade. 
 * O DOAS fará isso por cada membro da sua comunidade (Para cada DOAS comprado, será doado trimestralmente 0,05% da carteira de doação para as instituições devidamente cadastradas no site oficial).
 * Valores: Doar é mais que ajudar o próximo e por isso focamos nossos esforços em aumentar a segurança, a rapidez e o acesso para os setores que realmente precisam de auxílio. 
 * */
 
contract Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    string public name = "DoaCoinS";
    string public symbol = "DOAS";
    
    uint256 public numeroDeMoedas = 365000000;
    uint256 public casasDecimais = 9;
    
    uint256 public burnRate = 2; // Queima x% dos token transferidos de uma carteira para outra
    uint256 public liquityFee = 2; // Remuneração do Pool de liquidez 
    uint256 public donationPercentage = 12; // Cateira de doação x% dos token transferidos para essa carteira
    uint256 public foundersPercentage = 3; // Cateira de fundadores x% dos token transferidos para essa carteira
    uint256 public burnValueInitial = 35; // Queima x% dos token transferidos de uma carteira para outra no momento da criação dos tokens
    
    address public donationsWallet = 0xA9Add69Ad2113bcc413660D91e42EAbB21cC7893; // Carteira de doação
    address public foundersWallet = 0x8E5d48ca452D726E5F624E094Ca955a00b7bD29f; // Carteira de fundadores
    address public burnWalletInital = 0x2222222222222222222222222222222222222222; // Carteira de queima inicial
    address public burnWallet = 0x1111111111111111111111111111111111111111; // Carteira de queima
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    uint256 public totalSupply = numeroDeMoedas * 10 ** casasDecimais;
    uint256 public decimals = casasDecimais;
    
    address public contractOwner = msg.sender;
    
    constructor()  {
        uint256 donations = (totalSupply * donationPercentage) / 100;
        uint256 founders = (totalSupply * foundersPercentage) / 100;
        uint256 valueToBurn = (totalSupply * burnValueInitial) / 100;
       
        contractOwner = msg.sender;
        balances[burnWalletInital] = valueToBurn;
        balances[donationsWallet] = donations;
        balances[foundersWallet] = founders;
        balances[msg.sender] = totalSupply - donations - founders - valueToBurn;
    }
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Saldo insuficiente (balance too low)");
        uint256 valueToBurn = (value * burnRate / 100);
        uint256 valueToLiquityFee = (value * liquityFee / 100);
        balances[to] += value - valueToBurn - valueToLiquityFee;
        balances[burnWallet] += valueToBurn;
        balances[msg.sender] -= value;
        balances[msg.sender] += valueToLiquityFee;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, "Saldo insuficiente (balance too low)");
        require(allowance[from][msg.sender] >= value, "Sem permissao (allowance too low)");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    // transferencia das doações
    function transferDonation(address to, uint256 value) public returns(bool) {
        if(msg.sender == contractOwner) {
            require(balanceOf(donationsWallet) >= value, "Saldo insuficiente (balance too low)");
            require(allowance[donationsWallet][msg.sender] >= value, "Sem permissao (allowance too low)");
            balances[to] += value;
            balances[donationsWallet] -= value;
            emit Transfer(donationsWallet, to, value);
            return true;
        }
        return false;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function setBurnRate(uint256 value) public returns(bool) {
        burnRate = value; 
        return true;
    }
    
    function setLiquityFee(uint256 value) public returns(bool) {
        liquityFee = value;
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