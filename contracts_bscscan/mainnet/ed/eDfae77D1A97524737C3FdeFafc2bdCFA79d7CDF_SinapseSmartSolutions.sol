// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SinapseSmartSolutions is ERC20, Ownable {

    address public admin;

    constructor() ERC20('SINAPSE SMART SOLUTIONS', 'SNPST') {
        _mint(msg.sender, 500000000 * 10 ** 18);
        admin = msg.sender;
    }

    function mint(address to, uint amount) external {
        require(msg.sender == admin, 'Only admin');
        _mint(to, amount);
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

}

//Developed by KR Technology - https://krtecnology.website/
/**
 * SINAPSE NETWORK CRYPTO TECNOLOGIA LTDA - CONTRATO DE COMPRA E VENDA DE CRIPTO ATIVOS COM CLÁUSULA DE VANTAGENS E OUTRAS AVENÇAS
 */

//Pelo presente instrumento particular, as PARTES:
//SINAPSE NETWORK CRYPTO TECNOLOGIA LTDA, sociedade constituída sob as leis da República Federativa do Brasil, registada sob o número 32.107.470/0001-45, com sede na Av. Atlântica, 2650 – Cobertura – Sala 01 – Praia Campista, Macaé-RJ, sendo representante oficial do conglomerado de empresas que formou SINAPSE NETWORK, neste ato representada pelo seu representante legal, doravante denominada “SINAPSE SMART SOLUTIONS” ou “VENDEDORA”, e de outro lado;

//O ADQUIRENTE, pessoa física ou jurídica, capaz, interessada em firmar o presente CONTRATO, a qual preencheu devidamente o cadastro na plataforma da SINAPSE NETWORK e encaminhou os seus respectivos documentos, doravante denominado simplesmente “USUÁRIO”; sendo ambas as partes designadas, em conjunto, como “PARTES”, e isoladamente como “PARTE”.

/**
 * CONSIDERAÇÕES PRELIMINARES:
 */

//Considerando que a SINAPSE SMART SOLUTIONS, nos termos da legislação em vigor, dispõe de uma plataforma especializada na compra e venda de ativos digitais; 
//Considerando que a SINAPSE SMART SOLUTIONS é pessoa jurídica que se dedica à compra e venda de cripto ativos no Brasil;
//Considerando que a SINAPSE SMART SOLUTIONS possui interesse em TOKENIZAR parte de seus ativos relacionadas às suas atividades e expertises de negociação com o objetivo de negociá-los no mercado descentralizado de cripto ativos;
//Considerando que o USUÁRIO se declara conhecedor do mercado de cripto ativos;
//Considerando que o USUÁRIO declara possuir ciência que ativos digitais apresentam alta volatilidade e são considerados ativos de alto risco, podendo gerar prejuízos financeiros decorrentes de sua desvalorização;
//Considerando que o USUÁRIO declara possuir plena capacidade civil, dispondo de todas as faculdades necessárias para firmar este CONTRATO e assumir as obrigações aqui previstas;
//As PARTES celebram o presente “Contrato de Compra e Venda de Criptoativos com Cláusula de Prioridade” (“CONTRATO”), que se regerá pelas seguintes cláusulas e condições:

/**
 * 1.OBJETO DO CONTRATO E CARACTERÍSTICAS DOS SERVIÇOS
 */

//O presente CONTRATO tem por objeto a compra e venda de lote de TOKENS, disponibilizados pela SINAPSE NETWORK, na plataforma digital encontrada no endereço eletrônico oficial da empresa. A aquisição dos TOKENS pelo USUÁRIO se dará de acordo com as condições de preço e quantidade das regras e condições espelhadas na proposta de contratação, firmada no momento da aquisição. Os TOKENS oferecidos pela SINAPSE NETWORK poderão, conforme o caso, referirem-se à fração ideal de determinado ativo real, e, portanto, sua negociação, representará a cessão da titularidade da fração ideal do referido ativo real. Tais informações deverão constar da proposta de contratação (“NA PLATAFORMA OFICIAL DA SINAPSE SMART SOLUTIONS”). A SINAPSE SMART SOLUTIONS poderá aceitar como forma de pagamento, a seu exclusivo critério, a permuta por outras criptomoedas, as quais, se aceitas, estarão informadas em seu portal oficial. Formalizada a aquisição dos TOKENS, de acordo com as condições estabelecidas na proposta de contratação, realizada a abertura de uma carteira digital “wallet” ou indicação de wallet já existente, confirmada a assinatura digital deste contrato e confirmado o pagamento, o USUÁRIO receberá um e-mail informando a transferência dos TOKENS para sua carteira “wallet”. A SINAPSE SMART SOLUTIONS oferece ao USUÁRIO a possibilidade de lhes dar prioridade na compra de cotas empresariais ou ações da mesma, de acordo com as regras e condições estabelecidas na proposta de contratação escolhida pelo USUÁRIO no momento da aquisição dos TOKENS (“ANEXO XXXX”), cabendo ao USUÁRIO, caso queira, optar pelo direito de revenda dos TOKENS. A SINAPSE SMART SOLUTIONS disponibilizará produtos e serviços em tecnologia de operações de “TRADDING” em sua plataforma para que, querendo, o USUÁRIO possa adquiri-los com seus TOKENS, sob forma de um clube de vantagens ou assemelhados. O USUÁRIO poderá ainda utilizar a plataforma da SINAPSE SMART SOLUTIONS para emitir ordens para compra ou venda dos TOKENS adquiridos ou de outros cripto ativos diversos, sendo que tais transações serão efetuadas entre os próprios usuários da plataforma, ou diretamente com a SINAPSE SMART SOLUTIONS. Se realizadas operações entre os usuários, a SINAPSE SMART SOLUTIONS atuará apenas como intermediária, permitindo que os usuários negociem entre si diretamente, sem que a SINAPSE SMART SOLUTIONS participe das transações, cobrando apenas eventuais taxas de intermediação. Como condição para a utilização da plataforma, o USUÁRIO se compromete a não utilizar a plataforma da SINAPSE SMART SOLUTIONS para fins diretos ou indiretos de (i) infringir qualquer lei, regulamento ou contrato, nem praticar atos contrários à moral e aos bons costumes; (ii) praticar lavagem de dinheiro; e/ou (iii) financiar atividades e/ou organizações que envolvam terrorismo, crime organizado, tráfico de drogas, pessoas e/ou órgãos humanos. Para que seja possível emitir uma ordem de venda, o USUÁRIO deverá possuir TOKENS ou outros cripto ativos armazenados em sua WALLET. A SINAPSE SMART SOLUTIONS esclarece que pode custodiar dinheiro, fazer arbitragem de criptomoedas, não fazer trade, mineração ou outras operações de rentabilização de criptomoedas. A SINAPSE SMART SOLUTIONS submeterá as carteiras digitais administradas por revisões e controles bimestrais de compliance que verificarão os saldos das carteiras, garantindo a real existência dos ativos mostrados a você em nossa plataforma. O USUÁRIO é responsável, perante a SINAPSE SMART SOLUTIONS e perante quaisquer terceiros, inclusive autoridades locais a respeito do conteúdo das informações, a origem e a legitimidade dos ativos negociados na plataforma da SINAPSE SMART SOLUTIONS. As PARTES se obrigam a cumprir fielmente a legislação que trata da prevenção e combate às atividades ligadas à ocultação de bens e lavagem de dinheiro.

/**
 * 2. CADASTRO
 */

//2.1 Antes de iniciar seu relacionamento com a SINAPSE SMART SOLUTIONS, o USUÁRIO deverá fornecer todas as informações cadastrais solicitadas, enviando, inclusive, os documentos comprobatórios (RG, CPF e Comprovante de Residência) solicitados pela SINAPSE SMART SOLUTIONS. 
//2.2 O USUÁRIO declara estar ciente e concorda que é de sua exclusiva responsabilidade manter seu cadastro permanentemente atualizado perante a SINAPSE SMART SOLUTIONS, podendo a SINAPSE SMART SOLUTIONS recusar qualquer ordem do USUÁRIO que não estiver devidamente cadastrado ou que estiver com seu cadastro desatualizado.
//2.3 O USUÁRIO concorda com o processamento de seus dados pessoais fornecidos no contexto deste CONTRATO para os fins aqui descritos e também concorda, até a revogação a qualquer momento do armazenamento de seus dados além do prazo acima.
//2.4 Ao adquirir a partir de uma unidade do Token, o USUÁRIO poderá indicar o produto a terceiros e poderá fazer jus à remuneração por intermediação, conforme percentuais determinados pela SINAPSE SMART SOLUTIONS, indicados em seu site.
//2.5 O preenchimento do questionário de aptidão é obrigatório para a contratação dos serviços, podendo a SINAPSE SMART SOLUTIONS se negar a aceitar o cadastro.

/**
 * 3.REMUNERAÇÃO E TAXAS
 */

//3.1 Pelos serviços de custódia simples aqui contratados, a SINAPSE SMART SOLUTIONS não fará remuneração direta pré ou pós fixada dos ativos negociados em sua plataforma.
//3.2 SINAPSE SMART SOLUTIONS poderá implementar taxas de movimentação requeridas pelo cliente ou taxas de saques, as quais ficarão disponíveis em seu portal oficial.
//3.3 O USUÁRIO poderá vender seus Tokens a terceiros a qualquer momento.

/**
 * 4.OBRIGAÇÕES DO USUÁRIO
 */

//O USUÁRIO será responsável e encontra-se ciente: pelos atos que praticar e por suas omissões, bem como pela correção e veracidade dos documentos e informações apresentados, respondendo por todos os danos e prejuízos, diretos ou indiretos, eventualmente causados à SINAPSE SMART SOLUTIONS ou a terceiros, em especial com relação a quaisquer vícios relativos às informações e aos documentos necessários à prestação dos serviços ora contratados; por cumprir a legislação, as regras e os procedimentos operacionais aplicáveis à realização de operações; por assumir responsabilidade civil e criminal por todas e quaisquer informações prestadas à SINAPSE SMART SOLUTIONS; que quaisquer prejuízos sofridos em decorrência de suas decisões de comprar, vender ou manter criptomoedas são de sua inteira responsabilidade, eximindo a SINAPSE SMART SOLUTIONS de quaisquer responsabilidades por eventuais perdas;

/**
 * 5. DA RESPONSABILIDADE DA SINAPSE NETWORK
 */

//5.1 A responsabilidade da SINAPSE SMART SOLUTIONS não abrange danos especiais, danos de terceiros ou lucro cessante, sendo que qualquer responsabilidade estará limitada às condições da transação constante da proposta de contratação.
//5.2 A SINAPSE SMART SOLUTIONS não poderá ser responsabilizada por caso fortuito ou força maior, tais como, mas não se limitando a determinação de governos locais que impeçam a atividade da SINAPSE NETWORK, extinção do mercado de tokens ou cripto ativos, pandemias ou qualquer outro acontecimento de força maior.

/** 
 * 6. DO PRAZO E RESCISÃO
 */

//6.1 O presente CONTRATO e os serviços a ele relacionados entram em vigor na data de confirmação do cadastro e desde que este instrumento tenha sido aceito eletronicamente, permanecendo em vigência por prazo constante da proposta de contratação.
//6.2 Este contrato pode ser rescindido a pedido de qualquer das partes, mediante solicitação interna a plataforma.
//6.3 A mera rescisão do CONTRATO não impõe à SINAPSE SMART SOLUTIONS o dever de devolver os valores que lhe foram pagos pelo USUÁRIO, ou o dever de recomprar os TOKENS adquiridos pelo USUÁRIO.

/**
 * 7. DISPOSIÇÕES GERAIS
 */

//7.1 Cada um dos USUÁRIOS que aceitarem o presente CONTRATO, declara e garante que possui capacidade civil para fazê-lo ou para agir em nome da PARTE para a qual está assinando, vinculando essa PARTE e todos os que venham a apresentar reivindicações em nome dessa PARTE nos termos do presente instrumento.
//7.2 Os direitos e obrigações decorrentes deste CONTRATO não poderão ser cedidos a terceiros por qualquer das PARTES, sem o prévio e expresso consentimento da outra PARTE.
//7.3 Este CONTRATO é gravado com as cláusulas de irrevogabilidade e irretratabilidade, expressando, segundo seus termos e condições, a mais ampla vontade das PARTES.
//7.4 A nulidade de quaisquer das disposições ou cláusulas contidas neste CONTRATO não prejudicará as demais disposições nele contidas, as quais permanecerão válidas e produzirão seus regulares efeitos jurídicos, obrigando as PARTES.
//7.5. Fica pactuado como garantia deste, a prioridade na compra de frações empresariais, cotas empresariais ou ações que a SINAPSE SMART SOLUTIONS disponibilize publicamente aos seus USUÁRIOS, em caso de adversidades poderá ser acionado as garantias como forma de pagamento.
//7.6 Eventual tolerância de uma das PARTES com relação a qualquer infração ao presente CONTRATO cometida pela outra PARTE, não constituirá novação e nem renúncia aos direitos ou faculdades, tampouco alteração tácita deste CONTRATO, devendo ser considerada como mera liberalidade das PARTES.
//7.7 Todos os avisos, comunicações ou notificações a serem efetuados no âmbito deste CONTRATO, terão de ser apresentados formalmente, sendo que o USUÁRIO está ciente e concorda que a comunicação da SINAPSE SMART SOLUTIONS será exclusivamente por e-mail, através do endereço indicado pelo USUÁRIO no momento de contratação dos serviços ou outro indicado posteriormente, sendo considerando-se válidas todas as comunicações enviadas em tal correio eletrônico. Cada unidade de TOKEN SINAPSE pode corresponder, alternativamente, ao seguinte: 

//- Prioridade ou exclusividade na compra de frações de empresas administradas pela SINAPSE SMART SOLUTIONS; ou 

//- Prioridade ou exclusividade na compra de ações de empresas administradas pela SINAPSE SMART SOLUTIONS; ou 

//- Prioridade ou exclusividade na compra de cotas de empresas administradas pela SINAPSE SMART SOLUTIONS, ou 

//- Outros benefícios referenciados e atualizados na plataforma oficial da SINAPSE SMART SOLUTIONS

//SINAPSE NETWORK CRYPTO TECNOLOGIA LTDA