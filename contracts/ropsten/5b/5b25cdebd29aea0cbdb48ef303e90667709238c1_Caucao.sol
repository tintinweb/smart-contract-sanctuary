pragma solidity ^0.4.0;
contract Caucao {
    address public locador;
    address public locatario;
    address public arbitro;
    uint256 public valorCaucao;
    uint256 public valorSolicitado;
    uint256 public status;

    uint256 public constant aguardando_pagamento = 0;
    uint256 public constant em_vigencia = 1;
    uint256 public constant encerrado = 2;
    uint256 public constant caucao_solicitada = 3;
    uint256 public constant supervisao_arbitro = 4;

    constructor(
        address _locatario,
        address _arbitro,
        uint256 _valor
    ) public{
        locador = msg.sender;
        locatario = _locatario;
        arbitro = _arbitro;
        valorCaucao = _valor;
        status = aguardando_pagamento;
    }

    modifier seNaoDepositada(){
        require(status == aguardando_pagamento);
        _;
    }

    modifier emVigencia(){
        require(status == em_vigencia);
        _;
    }

    modifier caucaoSolicitada(){
        require(status == caucao_solicitada);
        _;
    }

    modifier supervisaoArbitro(){
        require(status == supervisao_arbitro);
        _;
    }

    modifier somenteArbitro(){
        require(msg.sender == arbitro);
        _;
    }

    modifier locadorOuLocatario(){
        require(msg.sender == locador || msg.sender == locatario);
        _;
    }

    function depositaCaucao() seNaoDepositada payable public{
        uint256 _valor = msg.value;

        if(_valor < valorCaucao){
            msg.sender.transfer(_valor);
        }else if(_valor > valorCaucao){
            msg.sender.transfer(valorCaucao - _valor);
            status = em_vigencia;
        }else if (_valor == valorCaucao){
            status = em_vigencia;
        }
        
    }

    function solicitaPagamento(uint256 _valor) locadorOuLocatario emVigencia public{
        if(_valor <= valorCaucao){ 
            valorSolicitado = _valor;
            status = caucao_solicitada;
        }
    }

    function aprovaPagamento(bool _aprovacao) locadorOuLocatario caucaoSolicitada public{
        if(_aprovacao == true){
            msg.sender.transfer(valorSolicitado);
            valorCaucao = valorCaucao - valorSolicitado;
        } else if (_aprovacao == false) {
            status = supervisao_arbitro;
        }
    }

    function arbitroAprovaPagamento(bool _aprovacao) somenteArbitro supervisaoArbitro public{
        if(_aprovacao){
            msg.sender.transfer(valorCaucao);
        }

        status = em_vigencia;
    }
}