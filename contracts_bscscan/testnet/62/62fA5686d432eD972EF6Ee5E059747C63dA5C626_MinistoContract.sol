/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: GPL-3.0-or-late
/*
Programado por João Alvaro
Ministo Tech
d.: 11/07/2021
v.: 2
*/
pragma solidity 0.8.6;

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if(a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;

        return c;
    }
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public  {
        require(newOwner != address(0));

        owner = newOwner;
        emit OwnershipTransferred(owner);
    }
}

contract MinistoContract is Ownable {
    using SafeMath for uint;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "Ministo Smart Contract_v02";
    string public symbol = "MISC";
    uint public decimals = 18;

    //Variaveis do Contrato ministo abaixo.
    struct participacao{
        uint cotas;
        uint investBalance;
    }

    mapping (address => participacao) investidores;
    uint valordacota;
    address[] ContadorDeInvestidores;
    address ministo;

    //eventos de investimento
    event InvestimentoRealizado(address indexed _invest, uint indexed _cotas);
    event AlteraValor(uint indexed _valorCota);
    event Pagamento(address indexed _sender, uint indexed _pgto);
    event TrocoEnviado(address indexed _sender, uint indexed _troco);

    //eventos da coin
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[address(this)] = totalSupply;
        valordacota = 100 ether;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
        
    }
    
    function SaldoEtherContrato() public view returns(uint){
        return(address(this).balance);
    }
    
    /*
        Função que transfere valor de Token para um endereço destino.
    */

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient funds');
        balances[to] += value;
        balances[msg.sender] -= value;
        
        investidores[to].investBalance += value;
        investidores[to].cotas += 100*(value/totalSupply);
        investidores[msg.sender].investBalance -= value;
        investidores[msg.sender].cotas -= 100*(value/totalSupply);
        
        ContInvest(to);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'Quantia muito baixa');
        balances[to] += value;
        balances[from] -= value;
        
        investidores[to].investBalance += value;
        investidores[to].cotas += 100*(value/totalSupply);
        investidores[from].investBalance -= value;
        investidores[from].cotas -= 100*(value/totalSupply);
        
        //tenho que colocar aqui uma função para deletar da lista o investidor que ficar com zero moedas. 
        
        
        ContInvest(from);
        
        emit Transfer(from, to, value);
        return true;   
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    //funcoes onlyOwner
    
    function ValorDaCota(uint _valordacota) public {
        require(msg.sender == owner);
        valordacota = _valordacota;
        emit AlteraValor(valordacota);
    }
    
        //funcoes do contrato 

    function ContractTransfer(address to, uint value) public returns(bool) {
        require(balanceOf(address(this)) >= value, 'Saldo insuficiente');
        balances[msg.sender] += value;
        balances[address(this)] -= value;
        emit Transfer(address(this), to, value);
        return true;
    }
    
    function CompraCotas(uint QuantidadeDeCotas) public payable{
        require(msg.value >= valordacota*QuantidadeDeCotas, "Saldo insuficiente");
        require(balances[address(this)] > 0, "Nao ha cotas para negociacao via contrato.");
        
        investidores[msg.sender].cotas += QuantidadeDeCotas;
        uint numerodecotas = QuantidadeDeCotas*(10**18);
        investidores[msg.sender].investBalance += numerodecotas;
        ContractTransfer(msg.sender, numerodecotas);
        ContInvest(msg.sender);
       
        //para funcionar o resgate, deve colocar payable no endereço que será enviado o valor em ETHER 
        
        if(msg.value > valordacota*QuantidadeDeCotas){
            uint troco = msg.value - valordacota*QuantidadeDeCotas;
            payable(msg.sender).transfer(troco);
            emit TrocoEnviado(msg.sender, troco);
        }

        Resgate(payable(owner));
       
        emit InvestimentoRealizado(msg.sender, numerodecotas);
        
    }
    
    function QuantidadeDeInvestidores() view public returns(uint _totalInvest){
        return(ContadorDeInvestidores.length);
    }

    function ContInvest(address carteira) internal {
        uint i = 0;
        bool EstaNaLista = false;
        while( i != ContadorDeInvestidores.length){
            if(carteira == ContadorDeInvestidores[i]){
                EstaNaLista = true;
            }
            i ++;
        }
        if (EstaNaLista == false){
            ContadorDeInvestidores.push(carteira);
        }
    }
    
    function Resgate(address payable _carteira) internal{
        uint saldo;
        if (address(this).balance > 0){
            saldo = address(this).balance; 
            _carteira.transfer(saldo);
        } 
    }
    
    function PagamentoDeDividendos() payable public{
        require(msg.sender == owner, "Operacao nao autorizada para este usuario.");
        
        //Calculando a soma dos pagamentos.
        uint somatorio;
        for (uint p = 0; p < ContadorDeInvestidores.length; p++){
            somatorio += investidores[ContadorDeInvestidores[p]].investBalance;
        }
        
        //uint resto = address(this).balance % ContadorDeInvestidores.length;
        uint dividendo = address(this).balance;
        /*
        if(resto != 0){
            payable(owner).transfer(resto);
        }
        */
        for (uint p = 0; p < ContadorDeInvestidores.length; p++){
            uint pgto = (dividendo*(investidores[ContadorDeInvestidores[p]].investBalance))/somatorio;
            payable(ContadorDeInvestidores[p]).transfer(pgto);
            emit Pagamento(ContadorDeInvestidores[p], pgto);
        }
        
    }
    
    function close() public { 
        require(msg.sender == owner, "Voce nao pode executar esta operacao.");
        selfdestruct(payable(address(this))); 
    }
   
}