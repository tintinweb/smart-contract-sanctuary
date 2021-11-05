/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.9;
 
contract CompraVenda {

    address public comprador;
    address public vendedor; 

    string public matricula; 
    string public cartorio;

    uint public dataDeVencimento;

    bool public quitado = false;

    uint public valorTotal;
    uint public valorDaEntrada;
    uint public quantidadeDeParcelas;
    uint public porcentagemDaMulta; 
    uint public valorDaParcela;
    uint public valorEmAberto;
    
    event PagamentoEntrada(address _comprador, uint _ValorPagamento);
    event PagamentoParcela(address _comprador, uint _ValorPagamento);

    constructor(
        uint _valorTotal,
        uint _valorDaEntrada,
        uint _quantidadeDeParcelas,
        uint _porcentagemDaMulta,
        string memory _matricula,
        string memory _cartorio,
        address _vendedor
        
        )
    {
        vendedor = _vendedor;
        valorTotal = _valorTotal;
        valorDaEntrada = _valorDaEntrada;
        quantidadeDeParcelas = _quantidadeDeParcelas;
        porcentagemDaMulta = _porcentagemDaMulta;
        matricula = _matricula;
        cartorio = _cartorio;
        valorEmAberto = valorTotal;
        valorDaParcela = funcaoValorParcela();
    }

    function pagarEntrada() public payable returns (uint, string memory) {
        require(msg.value == valorDaEntrada, "Valor da entrada incorreto.");
        require(valorEmAberto == valorTotal, "Entrada ja foi paga.");
        comprador = msg.sender;
        payable(vendedor).transfer(msg.value);
        valorEmAberto = valorTotal - msg.value;
        dataDeVencimento = block.timestamp + 31 * 86400;
        emit PagamentoEntrada(comprador, msg.value);
        return(valorEmAberto, "valor em aberto");
    }

    function pagarParcela() public payable returns (uint, string memory) {
        require(msg.value == valorDaParcela, "Valor da parcela incorreto");
        require(valorEmAberto <= valorTotal-valorDaEntrada, "Entrada nao foi foi paga.");
        require(comprador == msg.sender, "Obrigado, somente o comprador pode executar essa funcao");
        require(block.timestamp <= dataDeVencimento, "Parcela com data de vencimento vencida");
        payable(vendedor).transfer(msg.value);
        dataDeVencimento = dataDeVencimento + 31 * 86400;
        valorEmAberto = valorEmAberto - msg.value;
        if(valorEmAberto == 0) {
            quitado = true;
        }
        emit PagamentoParcela(comprador, msg.value);
        return(valorEmAberto, "valor em aberto");
    }

    function funcaoValorParcela() public view returns (uint){
        uint calculoValorParcela = (valorTotal-valorDaEntrada)/quantidadeDeParcelas;
        return(calculoValorParcela);
    }

    function valorDaMulta() public view returns(uint, string memory) {
        require(comprador == msg.sender || vendedor == msg.sender, "Apenas o comprador ou vendedor podem executar");
        uint multa;
        if(block.timestamp > dataDeVencimento + 30 * 86400 && dataDeVencimento != 0) {
            
            multa = porcentagemDaMulta*valorTotal/100;
            } else { multa = 0;
            }
        return(multa, "valor da multa");
    }

}