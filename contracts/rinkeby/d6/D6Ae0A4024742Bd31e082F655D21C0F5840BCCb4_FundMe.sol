// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
//definindo qual a versão suportada, nesse caso, apenas a versão 0.7.0

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address=>uint256) public addressToContribution;//um mapping de endereços para números inteiros
    address[] public funders;//um array de endereços dos contribuintes
    address owner;//o endereço do criador do contrato inteligente

    uint256 constant minimumUSD = 80 * 10 ** 18;/*definição do valor mínimo. Ele é uma constante, e define que o valor
    mínimo é de $80. A multiplicação no final ocorre para manter coerência com as casas decimais do WEI. */

    constructor(){/*o constructor é uma função que é chamada no momento de criação da classe, nesse caso do contrato
    inteligente. Dessa forma, ela é a primeira a ser chamada, e só é executada uma única vez por contrato. */
        owner = msg.sender;/*atribuindo a variável owner (proprietário) o endereço do remetente da transação. Nesse caso,
        como o contrato é criado pelo próprio desenvolvedor, ele próprio será considerado o owner. */
    }

    modifier onlyOwner{/*um modifier é uma propriedade que pode ser aplicada a funções, e outros conjuntos de um
    contrato inteligente. Ele consiste em um bloco de código que será executado, a depender da ordem definida em seu
    interior. Com isso, ele é utilizado para construir critérios e condições de execução dos contratos inteligentes,
    que vão se repetir várias vezes. Um exemplo é esse próprio modifier, que é a validação se o usuário que tenta 
    realizar a operação é o criador do contrato inteligente. */
        _;//define que esse código será executado após um função qualquer ser realizada
        require(msg.sender == owner);/*a função require é nativa dos contratos inteligentes. Ela é uma alternativa a
        um bloco if else, visto que, caso a condição passada seja atendida, o código segue, já se ela não for, a 
        transação vai falhar. */
    }

    modifier onlySufficientAmount{/*este é um modifier que verifica se o valor enviado é suficiente. */
        require(convertETHToUSD(msg.value) >= minimumUSD, "insufficient ETH amount!");/*aqui temos a chamada da função
        convertETHToUSD, que vai retornar o valor passado em WEI para um em dólar. Nessa situação, caso esse valor 
        seja menor que o mínimo, a transação vai ser revertida com a mensagem contida no segundo parâmetro. */
        _;//essa expressão determina que o modifier vai ser executado antes da função que ele é aplicado
    }

    function fund() public onlySufficientAmount payable{/*a função fund é pública, e possui o modificador onlySufficientAmount
    que foi definido anteriormente. Dessa forma, antes da execução do código contido ali a verificação do modificador
    será executada. Ela também possui o identificar payable, que determina a possibilidade de movimentação de valores
    em seu código(ou seja, ela pode enviar e receber valores). */
        addressToContribution[msg.sender] += msg.value;/*criação de uma key com o endereço do remetente, contendo a soma
        do valor existente com o novo valor enviado. (por padrão o valor inicial é de zero). */
        if(addressToContribution[msg.sender] == msg.value){/*aqui temos a validação se o remetente já enviou algum valor
        antes da transação atual. */
            funders.push(msg.sender);//aqui adicionamos no fim do array funders o endereço do remetente.
        }
    }

    function getEthPrice() public view returns(uint256){//essa função retorna a última cotação do par ETH/USD
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);/*o pricefeed
        recebe o AggregatorV3Interface com o endereço do par ETH/USD da rede Kovan. Permitindo que ele realize diversas
        operações, como a obtenção do valor do atual do par.*/
        (,int price,,,) = priceFeed.latestRoundData();/*o retorno da função latestRoundData é uma tupla, uma estrutura
        análoga aos objetos no Javascript. Dessa forma, ela retorna mais de um valor. Para obtermos apenas o que é interessante
        deixamos espaços vazios para os retornos não relevantes, e preenchemos apenas o desejado. */
        return uint256(price * 10000000000);/*conversão do valor de int para uint256, e o acréscimo de 8 casas "decimais".
        Como estamos lidando com o WEI, todas as primeiras 18  casas são necessárias, visto que 1 seguido de dezoito zeros
        é a quantidade de WEI necessária para totalizar um ETH. Com isso, os valores em dólar devem seguir tal padrão, com
        dezoito casas antecedendo o dólar, para permitir uma conversão de igual patamar. */
    }

    function convertETHToUSD(uint256 _ethAmount) public view returns (uint256){//função que converte um montante em ETH para USD
        //uint256 ethPrice = getEthPrice();
        uint256 ethPrice = 3204000000000000000000;
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1000000000000000000;/*aqui temos a conversão de um valor para
        a cotação atual (qtd * valor unitário). O único elemento distinto é a divisão, que nesse caso é utilizada para
        retirar as casas "decimais" adicionais. Como o WEI é um número muito pequeno, e não existem números com ponto
        flutuante no Solidity, temos de retirar o "excesso" que vem após multiplicar dois números muito extensos. que
        na verdade só representam números muito pequenos. */
        return ethAmountInUsd;
    }

    function withdraw() payable onlyOwner public{/*função que permite o saque dos valores presentes no contrato inteligente
    ela é payable (permite transações), pública e tem o modificador onlyOwner (só o criador do contrato pode utilizar
    essa função. */
        address payable addressPayable = payable(msg.sender);/*existem dois tipos de address, o comum e o payable. O 
        primeiro não permite transações, já o segundo sim. Dessa forma, só estamos obtendo o tipo que é desejado (o segundo
        ou seja, o que permite as transações. */
        uint256 balance = address(this).balance;/*atribuimos o balance (valor disponível no endereço) do this(palavra
        reservada que faz referência ao contrato inteligente em que está presente, ou seja, ao próprio contrato em
        que ela está sendo chamada. No nosso caso, esse é o endereço do FundMe. */
        addressPayable.transfer(balance);//transferimos o balance do atual contrato para o endereço do remetente.

        for(uint256 i = 0; i < (funders.length - 1); i++){//aqui estamos limpando as contribuções presentes no mapping
            addressToContribution[funders[i]] = 0;
        }

        funders = new address[](0);//e limpando o array funders.
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}