/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

//NOSSA HISTÓRIA

 //O Solar Token® é um ativo de armazenamento de Créditos energéticos e operada por meio de uma plataforma digital descentralizada como uma alternativa estratégica para alcançar avanços tecnológicos

//Reduzindo os custos dos sistemas fotovoltaicos fabricados atualmente reduzindo desperdícios e descontroles em créditos excedentes

//Além de promover dos produtos e serviços para os parceiros e mercado em geral.

 

//Serão realizadas atualizações no protejo para sua evolução, inserindo novas funcionalidades à medida que a adesão de seu ecossistema for sendo estabelecida, sempre pelo caminho da segurança institucional, sendo este o contexto mais importante, ao lado da viabilidade econômica e preservação do ambiente em que vivemos com o uso da inteligência coletiva.

//NOSSA VISÃO

//O Solar Token  é uma UtilityCoin que financiará o desenvolvimento de uma fotovoltaica Célula Orgânica extremamente maleável e da fácil instalação com eficiencia energética 33% mais eficiente que o concorrente chinês, e também em novos campos de pesquisa no setor energético e tem como principal objetivo reduzir os custos na produção de dispositivos e softwares  para geração, transporte  e controle eléctrico.

//NOSSA TECNOLOGIA

//Baseando na premissa que podemos contribuir para uma economia estável, buscamos construir nosso projeto com foco em pouca emissão de carbono, energia verde.

//Tendo isto em mente, decidimos usar a tecnologia da BlockChain Waves para escrever nosso código, contando com suporte de toda sua tecnologia, com ele será possível usar como reserva de valor, ações e moeda de troca através de carteiras digitais já conhecidas no mercado de criptomoedas, que aceitem o padrão BEP-20 como a Trust Wallet e Metamask por exemplo.

//OUR STORY

 //The Solar Token® is an Energy Credits storage asset and operated through a decentralized digital platform as a strategic alternative to achieve technological advances

//Reducing the costs of currently manufactured photovoltaic systems, reducing waste and uncontrolled excess credits

//In addition to promoting products and services to partners and the market in general.

 

//Updates will be carried out in the protejo for its evolution, adding new features as the adhesion of its ecosystem is being established, always along the path of institutional security, this being the most important context, along with economic viability and preservation of the environment in which we live with the use of intelligence  collective.

//OUR VISION

//Solar Token (SRT) is a UtilityCoin that will fund intelligence  in new fields of research in the energy sector and its main objective is to reduce costs in the production of devices and software  for generation, transport  and electrical control.

//OUR TECHNOLOGY

//Based on the premise that we can contribute to a stable economy, we seek to build our project with a focus on low carbon emissions, green energy.

//With this in mind, we decided to use BlockChain Waves technology to write our code, with the support of all its technology, with it it will be possible to use as a store of value, shares and exchange currency through digital portfolios already known in the cryptocurrency market , which accept the BEP-20 standard such as Trust Wallet and Metamask for example.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 100000000 * 10 ** 8;
    string public name = "Solar Token";
    string public symbol = "SRT";
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
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        balances[to] += value;
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
    
}