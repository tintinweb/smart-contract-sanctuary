pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) _balances;

  mapping (address => mapping (address => uint256)) _allowed;

  uint256 _totalSupply;

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

  /**
  * @dev Quantidade total de tokens
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Informa o balanco do endereco especificado
  * @param owner O endereco do balanco buscado.
  * @return Um uint256 representando a quantidade de tokenes que o endereco buscado possue.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Informa a quantidade de tokens que um endereco pode gastar de outro endereco.
   * @param owner address O endereco do dono dos fundos.
   * @param spender address O endereco de quem pode gastar (&#39;gastador&#39;).
   * @return Um uint256 especificando a quantidade de tokens disponiveis para o endereco &#39;gastador&#39;.
   */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfere tokens para um endereco especificado
  * @param to Endereco de quem recebera os tokens.
  * @param value A quantidade de tokens a ser transferida.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Aprova que um usuario "gastador" possa transacionar com os tokens
   * da carteira que os liberou . Por medidas de seguranca, antes de poder
   * setar um novo valor para o usuario "gastador", os fundos devem ser zerados
   * para entao serem setados pelo valor correto.
   * @param spender O endereco que ira gastar os tokens.
   * @param value A quantidade de tokens que ele pode gastar.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    // Resolve o probma do double spending ao ter que zerar a
    // quantidade liberada de tokens antes de setar o valor
    // escolhido.
    require((value == 0) || (_allowed[msg.sender][spender] == 0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Relizada a transacao de um endereco &#39;gastador&#39;, utilizando o
   * endereco do possuidor real dos tokens.
   * @param from address Endereco de quem possui realmente os tokens
   * @param to address Endereco de quem ira receber os tokens
   * @param value uint256 A quantidade de tokens a ser transferida
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Queima tokens e retira da quantidade do
   * totalSupply. Os tokens nao estarao mais disponiveis para nenhum endereco.
   * @param value A quantidade de tokens a serem queimados.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
	}

  /**
   * @dev Incrementa a quantidade de tokens que uma conta &#39;gastadora&#39; pode
   * transacionar.
   * @param spender O endereco de quem ira transacionar os fundos.
   * @param addedValue A quantidade de tokens a ser incrementada.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
  	uint256 value;
    require(spender != address(0));
    // Verifica se o valor a ser subtraido eh maior do que o disponivel
    if (subtractedValue >= _allowed[msg.sender][spender])
    	value = 0;
  	else
  		value = _allowed[msg.sender][spender].sub(subtractedValue);

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /////////////////////////////////////////////////////////////////////////////
  //                    FUNCOES INTERNAS PARA USO COMUM                      //
  /////////////////////////////////////////////////////////////////////////////


  /**
  * @dev Funcao interna para transferencias
  * @param from O endereco de onde sera retirado os tokens.
  * @param to O endereco de quem recebera.
  * @param value A quantidade a ser transferida.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));
    require(value > 0);

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
	}

	function _burnFrom(address account, uint256 value) internal {
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
	}
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() internal view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Startable is ERC20, Ownable {
  bool internal _isTransferable = false;
  address internal _crowdsaleAddress;
    

function showCrowdsaleAddress() public view returns(address) {
    return _crowdsaleAddress;
  }
    
  // Funcoes abaixo relacionadas ao Crowdsale
  function setCrowdsaleAddress(address crowdsaleAddress) public onlyOwner {
    // Can only set one time.
    require(_crowdsaleAddress == 0x0);
    require(crowdsaleAddress != 0x0);
    _crowdsaleAddress = crowdsaleAddress;
    _balances[_crowdsaleAddress] = _totalSupply;
  }

  // Somente eh possivel realizar transferencias caso elas estejam liberadas
  // (apos o CrowdSale).
  modifier onlyWhenTransferEnabled() {
    if (!_isTransferable) {
      require(msg.sender == _owner || msg.sender == _crowdsaleAddress);
    }
    _;
  }

  function enableTransfer() public onlyOwner{
    _isTransferable = true;
  }

  function transfer(address to, uint256 value) public onlyWhenTransferEnabled returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public onlyWhenTransferEnabled returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function burn(uint256 value) public onlyWhenTransferEnabled {
    return super.burn(value);
  }

  function burnFrom(address from, uint256 value) public onlyWhenTransferEnabled {
    return super.burnFrom(from, value);
  }

}

contract RD2Token is Startable {
	string internal _name;
  string internal _symbol;
  uint8 internal _decimals;
  bool internal _isTransferable = false;

  constructor(string name, string symbol, uint8 decimals, uint256 totalSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  	_totalSupply = totalSupply;
	}

	/**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
 */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
 */
  function decimals() public view returns(uint8) {
    return _decimals;
	}

}