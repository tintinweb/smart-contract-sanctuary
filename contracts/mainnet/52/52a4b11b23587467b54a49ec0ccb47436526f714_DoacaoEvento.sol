pragma solidity ^0.4.21;

contract DoacaoEvento {
    address public responsavel;
    enum StatusDoacao{ABERTO, FECHADO, SACADO}
    StatusDoacao public statusDoacao;
    address public ong;
    
    Doador[] public doadores;  
    
    event LogDoacaoRecebida(address doador, uint256 value);
    event LogSaqueEfetuado(uint dataHora);
    event LogOngInformada(address doador);
     
    struct Doador {
        address doador;
        uint256 valor;
        uint256 dataHora;
    }
    
    function DoacaoEvento() public {
        responsavel = msg.sender;
        statusDoacao = StatusDoacao.ABERTO;
    }
    
    modifier apenasResponsavel() {
        require(msg.sender == responsavel);
        _;
    }

    function informarOng(address _ong) public apenasResponsavel {
        emit LogOngInformada(_ong);
        ong = _ong;
    }
    
    function fecharDoacoes() public apenasResponsavel {
        require(statusDoacao == StatusDoacao.ABERTO);
        statusDoacao = StatusDoacao.FECHADO;
    }
    
    function abrirDoacoes() public apenasResponsavel {
        statusDoacao = StatusDoacao.ABERTO;
    }  
    
    function sacarDoacoes() public {
        require(msg.sender == ong && address(this).balance > 0 && statusDoacao == StatusDoacao.FECHADO);
        statusDoacao = StatusDoacao.SACADO;
        emit LogSaqueEfetuado(block.timestamp);
        msg.sender.transfer(address(this).balance);
    }
    
    // fun&#231;&#227;o callback
    function() public payable {
        require(msg.value > 0 && statusDoacao == StatusDoacao.ABERTO);
        emit LogDoacaoRecebida(msg.sender, msg.value);
        Doador memory d = Doador(msg.sender, msg.value, block.timestamp);
        doadores.push(d);
    }
}