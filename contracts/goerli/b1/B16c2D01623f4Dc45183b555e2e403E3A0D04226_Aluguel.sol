/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

/*
SPDX-License-Identifier: CC-BY-4.0
(c) Desenvolvido por Jeff Prestes
This work is licensed under a Creative Commons Attribution 4.0 International License.

--- INSTRUCAO INICIAL DE UM CONTRATO SOLIDITY
É necessario na primeira linha sempre definir a versao do Solidity que estamos usando para que o compilador
saiba avaliar a sintaxe do seu contrato com base na 'regra gramatical' com a qual voce escreveu o contrato
Lembre-se: A sintaxe do Solidity pode mudar de versao em versao.
*/
pragma solidity 0.8.4;

/*
Voce usa a palavra chave *contract* para iniciar a declaracao do contrato, 
logo em seguida vem o nome do mesmo em maiuscula.
Depois vem as chaves, onde voce abre e fecha {  }

--- CHAVES {  }
Esta acao eh muito importante pois aqui voce diz ao compilador onde o 
o contrato comeca e onde ele termina. Isso tambem vale para:
- IF (condicao SE)
- FUNCTION (funcoes que podem ser chamadas pelas partes)
E outras palavras chaves que veremos mais adiante

As chaves dizem ao compilador onde um determinado bloco de acoes comeca
e onde termina. Todo o conteudo do bloco deve ser escrito com o recuo de 
um TAB a direita. Assim visualmente voce ou qualquer outro advogado programador
conseguira facilmente de maneira visual ver que aquele conjunto de instrucoes
pertencem a um determinado bloco.


--- NOMES
Os objetos (contrato, funcoes, variaveis, por exemplo) nao podem ter caracteres especiais
ex.: #| e nem conter espacos nos seus nomes.


--- COMENTARIOS
Repare que tudo que fica entre /*   * /  ou texto logo apos // eh ignorado
pelo compilador. Sao os chamados *comentarios* e os utilizaremos muito aqui.

*/
contract Aluguel {
    
/*
--- VARIAVEIS
    Para declarar variaveis em solidity primeiro voce define o tipo de dado, depois, se 
    ela for uma variavel para todo o contrato você define o tipo de visualizacao:
    *public* ou *private*, ou seja, ela esta acessivel as pessoas de fora do contrato 
    ou ela somente pode ser acessada pelas funcoes de dentro do contrato.
    */
    string             public                       locatario ;
//  ^-- tipo de dado  ˆ^-- modificador de acesso   ˆ^-- nome
    string public locador;
    uint256 private valor;
//          ^-- veja que com o modificador private o conteudo desta variavel
//              nao ficara disponivel externamente ao contrato. Repare que 
//              voce nao ve esse valor na janela do Remix.
    
/*
--- CONSTANTES
    Constantes sao semelhantes as variaveis porem como o nome ja diz elas 
    nao permitem que seus valores sejam alterados durante a execucao do
    contrato.
*/
    uint256 constant numeroMaximoLegalDeAlgueisParaMulta = 3;
//          ^-- so usar o modificador *constant* e pronto, o compilador
//              sabera que se trata de uma constante e nao de uma variavel.

/*    
--- PONTO E VIRGULA    
    Ao final de cada instrucao temos de colocar o ;  para dizer ao compilador
    que nossa instrucao finalizou. Repare isso nas linhas 50, 52, 53 e 64
*/


/*
--- FUNCAO CONSTRUTORA
    Um contrato pode ter uma funcao que eh chamada no momento da sua publicacao
    no Blockchain, ela eh chamada *constructor*. Ela eh util quando queremos 
    definir os parametros iniciais do contrato ou fazer alguma operacao assim 
    que o contrato foi publicado.
    No exemplo abaixo queremos fazer a "qualificacao" das partes no contrato,
    onde nos recebemos como parametros o nome das partes e o valor do Aluguel
    e atribuimos esses valores as variaveis do contrato que ficarao registradas
    no Blockchain e ficarao acessiveis as funcoes do contrato
*/
    constructor(string memory nomeLocador, string memory nomeLocatario, uint256 valorDoAluguel)  {
/*
--- PARAMETROS
    Parametros sao como variaveis porem o seu valor eh definido externamente, ou seja, 
    dizemos que uma funcao recebe um parametro. Note que a sintaxe eh muito parecida
    com a definicao da variavel de contrato, o que difere eh que nao precisamos definir
    o modificador de acesso ja que todos os parametros so sao validos dentro do bloco
    onde ele foi definido.
    A declaracao de parametros fica no primeiro par de parenteses (  ) e sao separados 
    por virgulas. A sua declaracao pode ser na mesma linha ou pode-se quebrar as linhas.
    Exemplo:
    
    constructor(
        string memory nomeLocador, 
        string memory nomeLocatario, 
        uint256 valorDoAluguel) 
    public {
    
    O exemplo acima tambem eh aceito pelo compilador.
    
    Alias, repare no exemplo acima que as variaveis do tipo string precisam do 
    modificador *memory* para dizer ao compilador que os dados dessas variaveis 
    so precisam ficar em memoria e nao serao gravados na Blockchain.
*/  

        locador = nomeLocador;
        locatario = nomeLocatario;
        valor = valorDoAluguel;
    }
 
 
/*
--- FUNCOES 
    Funcoes sao operacoes que podem ser chamadas de um contrato. Elas sao uteis
    para realizar alguma operacao ou fazer um calculo e retornar um valor.
    
    - As funcoes devem ter um nome.
    - As funcoes devem ter um modificador de acesso definindo se ela pode ser 
    acessada de fora do contrato ou nao (tal qual as variaveis) 
    - As funcoes podem ser usar o modificador *view*. Com esse modificador
    dizemos ao compilador que utilizaremos essa funcao para ver os dados
    de retorno e nao modificaremos nada dos dados na Blockchain.
    - As funcoes podem ou nao retorar valores. Leia em ingles "the function returns..."
    por isso quando escrevemos uma funcao que retorna algo, em sua declaracao,
    usamos *returns*. Dai dentro do segundo parenteses nos declaramos o tipo de dado
    do que vamos retornar.
*/
    function valorAtualDoAluguel() public view returns (uint256) {
        return valor;
//      ^-- veja que aqui usamos return no imperativo pois nos estamos
//          determinando ao compilador para retornar a quem chamou a
//          funcao o conteudo da variavel do contrato valor
    }
 
/*
    Note na forma de declarar a funcao abaixo. Pode haver quebra de linhas
    para facilitar a leitura humana (pois para o compilador isso nao fara 
    diferenca). Porem nunca se esqueca da sintaxe. Abrir e fechar os parenteses
    e tambem da chave de inicio e de fim da funcao onde voce diz ao compilador
    onde o bloco de instrucoes da sua funcao se inicia e onde o bloco acaba.
*/
    function simulaMulta( uint256 mesesRestantes, 
                    uint256 totalMesesContato) 
    public
    view
    returns(uint256 valorMulta) {
//         ^-- repare que o Solidity tambem permite criarmos uma variavel de retorno
        valorMulta = valor*numeroMaximoLegalDeAlgueisParaMulta;
        valorMulta = valorMulta/totalMesesContato;
        valorMulta = valorMulta*mesesRestantes;

/*  Repare que no exemplo acima reaproveitei a variavel *valorMulta*, pois como seu conteudo Pode
    variar eu fui alterando o seu valor com o resultado dos calculos.  */
        return valorMulta;
    } 
    
    
    function reajustaAluguel(uint256 percentualReajuste) public {
        uint256 valorDoAcrescimo = 0;
/*      Voce tambem pode declarar novas variaveis dentro das funcoes. Entretanto,
        elas ficam disponiveis somente dentro do limite do bloco da funcao. 
        Seguem as mesmas regras para a declaracao de variaveis de contrato exceto
        que elas nao precisam do modificador de acesso pois ja esta implicito que 
        seu conteudo so pode ser acessado dentro da funcao */
        
        valorDoAcrescimo = ((valor*percentualReajuste)/100);
/*                         ^-- Aqui usa-se as mesmas regras do Excel na criacao de formulas
                               matematicas. Coloco dentro de parenteses cada operacao e o 
                               compilador sabera que ele deve executar inicial a operacao 
                               que esta dentro e depois as demais de fora   */
        valor = valor + valorDoAcrescimo;
    }
    
}