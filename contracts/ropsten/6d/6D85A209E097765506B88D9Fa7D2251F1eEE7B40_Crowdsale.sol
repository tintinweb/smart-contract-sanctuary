pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/**
 * @title Assegura contratos contra o ataque de reentrada (Reentrancy Attack).
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3240575f515d7200">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1d7c71786578645d7074657f6469786e337472">[email&#160;protected]</a>>
 * @dev Se voce marca uma funcao como `nonReentrant`, voce tambem deve
 * marca-la como `external`.
 */
contract ReentrancyGuard {

  /// @dev contador para assegurar mutex lock com somente uma operacao SSTORE
  uint256 private _guardCounter;

  constructor() internal {
    // O contador comeca com 1 para prevenir mudar de zero para um valor
    // nao-zero, o que a torna menos custosa do que o contrario.
    _guardCounter = 1;
  }

  /**
   * @dev Previne que um contrato chame ele msesmo, diretamente ou indiretamente.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }
}

/**
 * @title Interface para executar funcoes do contrado dono do token.
 * @dev Somente com essa interface eh possivel executar as funcoes
 * do token, sem ele nao eh possivel saber se a funcao existe ou nao.
 * Caso utilize alguma outra funcao alem das padroes, coloca-las aqui.
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external
     view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external
     returns (bool);

  function transferFrom(address from, address to, uint256 value) external
     returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Crowdsale (venda em massa)
 * @dev Crowdsale eh um contrato basico para permitir que investidores
 * comprem tokens com ether. Esse contrato pode ser extendido (ou herdado)
 * para adicionar mais funcionalidades.
 */
contract Crowdsale is ReentrancyGuard {
  using SafeMath for uint256;

  // Criador/dono do Crowdsale
  address private _owner;

  // O token sendo vendido
  IERC20 private _token;

  // Carteira no qual os fundos serao enviados ao final do Crowdsale
  address private _wallet;

  // Quantidade de tokens por wei.
  // A taxa eh a conversao entre wei e a menor, indivisivel, unidade de token.
  // Entao, se voce usa uma taxa de 1 com um token de 3 decimais chamado TOK
  // 1 wei te dara 1 unidade, ou 0.001 TOK.
  uint256 private _rate;

  // Quantidade de wei recebido
  uint256 private _weiRaised;

  bool private _finalized = false;

  event CrowdsaleFinalized();


  /**
   * Evento para log de compra de token
   * @param purchaser quem pagou pelos tokens
   * @param beneficiary quem recebeu os tokens
   * @param value weis pagos para recebe-los
   * @param amount quantidade de tokens recebidos
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param rate Numero de tokens que um comprador recebera por wei
   * @param wallet Endereco nos quais os fundos coletados serao enviados
   * @param token Endereco do contrato do token
   */
  constructor(uint256 rate, address wallet, IERC20 token) public payable {
    require(rate > 0);
    require(wallet != address(0));
    require(token != address(0));

    _rate = rate;
    _wallet = wallet;
    _token = token;
    _owner = msg.sender;
  }

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   * Funcao basica para receber weis e enviar tokens caso nenhum parametro
   * ou funcao seja enviado ou chamado.
   * Note that other contracts will transfer fund with a base gas stipend
   * of 2300, which is not enough to call buyTokens. Consider calling
   * buyTokens directly when purchasing tokens from a contract.
  */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @return o token que esta sendo vendido.
  */
  function token() public view returns(IERC20) {
    return _token;
  }

  /**
   * @return o endereco no qual os fundos estao sendo coletados.
  */
  function wallet() public view returns(address) {
    return _wallet;
  }

  /**
   * @return a quantidade de tokens que eh recebido por wei.
  */
  function rate() public view returns(uint256) {
    return _rate;
  }

  /**
   * @return a quantidade de fundos coletados (em wei).
  */
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }
  /**
   * @return se o Crowdsale terminou ou nao.
  */
  function finalized() public view returns (bool) {
    return _finalized;
  }

  /**
   * @dev Deve ser chamada quando o Crowdsale eh terminado.
   * Caso isso aconteca apos uma data especificada, chamar esta funcao.
   * No momento deve ser chamada pelo criador.
  */
  function finalize() public {
    require(!_finalized);
    require(msg.sender == _owner);

    _finalized = true;

    _finalization();
    emit CrowdsaleFinalized();
  }

  /**
   * @dev Envia os weis coletados para a carteira especificada na criacao.
   * do contrato.
  */
  function _finalization() internal {
    uint256 totalAmount;
    totalAmount = _token.balanceOf(address(this));
    _token.transfer(_owner, totalAmount);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * This function has a non-reentrancy guard, so it shouldn&#39;t be called by
   * another `nonReentrant` function.
   * @param beneficiary Endereco recebedor dos tokens
   */
  function buyTokens(address beneficiary) public nonReentrant payable {
    require(!_finalized);
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // calcula a quantidade de tokens a serem enviados
    uint256 tokens = _getTokenAmount(weiAmount);

    // atualiza quantidade de fundos coletados
    _weiRaised = _weiRaised.add(weiAmount);

    _deliverTokens(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds();
  }
  /**
   * @dev Validacao simples antes de concretizar a compra.
   * Pode (e deve) ser extendida.
   * @param beneficiary Endereco do recebedor dos tokens
   * @param weiAmount Quantidade de weis recebidos na transacao.
   */
  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal pure {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

  /**
   * @dev Realiza a compra de tokens utilizando o a funcao de transferencia
   * do contrato do token.
   * @param beneficiary Endereco de quem recebera os tokens.
   * @param tokenAmount Numero de tokens a serem transferidos.
   */
  function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
    _token.transfer(beneficiary, tokenAmount);
  }

  /**
   * @dev Calcula a quantidade de tokens por wei.
   * @param weiAmount quantidade em weis a ser convertida
   * @return Numero de tokens que eh possivel comprar
   */
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(_rate);
  }

  /**
   * @dev Envia o ether coletado para a carteira.
   */
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }

  function owner() public view returns(address) {
    return _owner;
  }
}