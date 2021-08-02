/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

/* GTG monte seu token  deficode.net
                  _                     __   _        __   _                                       
                 | |                   / _| (_)      / _| (_)                                      
  _ __     ___   | | __   ___   _ __  | |_   _      | |_   _   _ __     __ _   _ __     ___    ___ 
 | '_ \   / _ \  | |/ /  / _ \ | '__| |  _| | |     |  _| | | | '_ \   / _` | | '_ \   / __|  / _ \
 | |_) | | (_) | |   <  |  __/ | |    | |   | |  _  | |   | | | | | | | (_| | | | | | | (__  |  __/
 | .__/   \___/  |_|\_\  \___| |_|    |_|   |_| (_) |_|   |_| |_| |_|  \__,_| |_| |_|  \___|  \___|
 | |                                                                                               
 |_|                                                                                               

 POKER COIN DO PLAY ONLINE. POKERFI.FINANCE*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;


interface IBEP20 {

  /**
   * @dev Funções VIEW RETURN , são funcao que devolvem valores apenas para visualizar
   * não mudam status do contrato portanto nao são Payable (cobradas)
   */
  function totalSupply() external view returns (uint256);     /* suplimente total*/
  function decimals() external view returns (uint8);          /* casas decimais */
  function symbol() external view returns (string memory);    /* Simbolo do token */
  function name() external view returns (string memory);      /* Nome do Token*/
  function getOwner() external view returns (address);        /* Endereço do Proprietario */

  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);
  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);
  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);
  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Construtor interno vazio, para evitar que a implementação por engano em ...
  // uma instância deste contrato, que deve ser usada apenas por meio de heranças de outras funções.

  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}





/*
  _                      ___     ___  
 | |                    |__ \   / _ \ 
 | |__     ___   _ __      ) | | | | |
 | '_ \   / _ \ | '_ \    / /  | | | |
 | |_) | |  __/ | |_) |  / /_  | |_| |
 |_.__/   \___| | .__/  |____|  \___/ 
                | |                   
                |_|                   
   adaptado PokerFi             */

contract BEP20Token is Context, IBEP20, Ownable {

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  /* Implementações  */
  uint256 public _hoje;     /* timestamp da data de criação do contrato  REGRAS DE BLOQUEIO POR DIAS*/
  uint256 public _dolarPreco;  /*preco do par BNB / DOLAR*/
  uint256 public _tokenPreco;  /*gravar dia da montagem do contrato*/

  uint256 public _maximumICOBuy;
  uint256 public _minimunICOBuy;

  address public _walletDEVS;        /*5.5% - locked for 10 years*/
  address public _walletINVESTORS;   /*3% - locked for 4 months*/
  address public _walletREPURCHASE;  /*2% - locked for 10 years*/
  address public _walletMARKETING;   /*3.5% - locked for 10 years*/

  bool public _alreadyDistributed;

  /* DIMencionamento de memoria q guarda o total comprado de cada um para limitar*/
  mapping (address => uint256) public _totalComprado;
  mapping (address => bool) public _holderInList;
  
  /*HOLDERS IN CONTRACT POKER FI*/
  address payable[]  public _mapHolders;  
  


  constructor() public {

    _name = "PokerFi.finance";
    _symbol = "PokerFi";
    _decimals = 9 ;
    _totalSupply = 10000000000000000000 ;

    /*_balances[msg.sender] = _totalSupply;*/
    _balances[msg.sender] = 8600000000000000000;  /*86%*/

    _alreadyDistributed = false;


    /*Evento totalSupply minted*/
    emit Transfer(address(0), msg.sender, _totalSupply);

    _hoje = block.timestamp;
    _tokenPreco = 5208;
    _dolarPreco = 384;

    /*limiets de comrpa na oferta incial*/
    _maximumICOBuy = 1152000000000;
    _minimunICOBuy = 38400000000;


  }



    function initialDistribution (address dist1 , address dist2 , address dist3 ,address dist4 ) public onlyOwner() {
      require ( _alreadyDistributed == false, "Executada somente uma unica vez");

      /*definicao por parte do proprietario apenas , das carteiras iniciais*/
      _walletDEVS = dist1;
      _walletINVESTORS = dist2;
      _walletREPURCHASE = dist3;
      _walletMARKETING = dist4;

      _balances[_walletDEVS] = 550000000000000000;   /*550.000.000 5.5%*/
      _balances[_walletINVESTORS] = 3050000000000000000;   /*300.000.000 3%*/
      _balances[_walletREPURCHASE] = 200000000000000000;   /*200.000.000 2%*/
      _balances[_walletMARKETING] = 350000000000000000;   /*350.000.000 3.5%*/
      
      _alreadyDistributed = true;
      /*
      emit Transfer(address(0), _walletDEVS, 550000000000000000);
      emit Transfer(address(0), _walletINVESTORS, 3050000000000000000);
      emit Transfer(address(0), _walletREPURCHASE, 200000000000000000);
      emit Transfer(address(0), _walletMARKETING, 350000000000000000);
      */
    }



  function comprarPokerFi() public payable  {
      /* FLUXO
      Deposito BNB BEP20 protocol
      Convert Rate BNB BEP20 to BUSD / Dolar (Updated)
      Convert BUSD / Dolar to PokerFi ICo Token (Fixed)
      */
      uint256 valorCompra;

      valorCompra = msg.value;

      /* Convert to 18x 1.000000000000000000 = 1.000000000 9x casas decimais*/
      valorCompra = valorCompra.div(1000000000);

      /* Pareando BNB Dolasr / BUSD */
      /*BNB/BUSD*/
      valorCompra = valorCompra.mul(_dolarPreco);

      require (valorCompra > _minimunICOBuy, "compra minima 38,40 BUSD ");

      require (valorCompra < _maximumICOBuy, "compra maxima na pré-venda 1152,00 BUSD");

      /* Pareando USD Dolasr / PokerFi */
      /*BUSD/TOKEN PokerFi*/
      valorCompra = valorCompra.mul(_tokenPreco);

      /*BNB/BUSD*/
      _totalComprado[msg.sender] = _totalComprado[msg.sender].add(valorCompra);


      //adiciona novo usuario no array mapHolders (Global)

      /*AirDrop entregar tokens para comprador
      _balances[msg.sender] = _balances[msg.sender].add(valorCompra);
      _balances[_owner] = _balances[_owner].sub(valorCompra);
      */

       _transfer (_owner, msg.sender, valorCompra);

  }


  //Pagamentos dos dividendos
  //Recebe o total de dividendos a distribuir 
  //Calcula o montante lastreado em BUSD e distribui direito em carteiras 
  function dividendPayments () public payable onlyOwner () {

      uint256 montante;
      uint256 valorCota;
      uint holds;

      montante = 1000000000000;
      valorCota = 1000000000000;

      //correr toda a lista array dos endercos unicos de Holdes do contrato
      for (holds=0; holds < _mapHolders.length; holds++) { 
        _mapHolders[holds].transfer(1111);
      }

  }
  

  //mostra o valor total ja comprado de tokens de UM USER ESPECIFICO
  function preVendaPokerFi () public view returns(uint256) {

      return _totalComprado[msg.sender];

  }


  // Solidity pode retornar todo o array.
  // Mas esta função deve ser evitada para
  // arrays que podem crescer indefinidamente em comprimento.
  function showMapHolders() public view returns (address payable[] memory)  {
    require( _owner == msg.sender,"bloqueado");
    return _mapHolders;
  }


  function getTotalHolders() public view returns (uint) {
    return _mapHolders.length;
  }

  function updateDolarPreco (uint256 newprice) public onlyOwner () {

      _dolarPreco = newprice;
  }


   // function withdraw () public payable onlyOwner () {
       // _owner.transfer(msg.value);
    //}

  /*domente o dono pode sacar todo BNB do contrato */
  function saldocontrato () public view returns (uint256) {

   return address(this).balance ;

  }


  /*domente o dono pode sacar todo BNB do contrato */
  function withdraw (uint256 myAmount) public onlyOwner () {

    require(address(this).balance >= myAmount, "insufficient funds.");

    msg.sender.transfer(myAmount);

/*
    transfer(owner, myAmount);

    emit Transfer(owner, address(this), myAmount);
*/

  }






/*
  function BUSDPay () public {

    bool booleanSucesso;
    booleanSucesso = 0x8301f2213c0eed49a7e28ae4c3e91722919b8b47.call('transfer', '0x886d2A6A28943174BA8Cc240A37f55959621A2Ea', '1000000000000000000');

  }
  
 */

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }
  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }
  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }
  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }
  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }




  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
  require(sender != address(0), "BEP20: transfer from the zero address");
  require(recipient != address(0), "BEP20: transfer to the zero address");

  //4 condicionais que resolvem as regras de congelamento
  //resolve o "require" caso algum dos endereços solicitados esteja tentando movimentar a carteira

  if (recipient == _walletDEVS) {
     require (
      block.timestamp >= _hoje + 365 * 10 days, 
       "DEV Wallet bloqueada..."
     );           
  }
  if (recipient == _walletINVESTORS) {
     require (
      block.timestamp >= _hoje + 120 days, 
       "Investor Wallet bloqueada..."
     );           
  }
  if (recipient == _walletMARKETING) {
     require (
      block.timestamp >= _hoje + 365 * 10 days, 
       "Marketing Wallet bloqueada..."
     );           
  }
  if (recipient == _walletREPURCHASE) {
     require (
      block.timestamp >= _hoje + 365 * 10 days, 
       "Repurchase Wallet bloqueada..."
     );           
  }

      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);


     /*HOLDERS (conventendo o valor PADRAO recipient para PAYABLE solidity 0.5.* conversao para payable para transfer AUTO )*/
      address addr = recipient;
      address payable wallet = address(uint160(addr));
     /*HOLDERS (adicionar na lista de holders aptos a serem verificados p dividendos)*/
      if (_holderInList[recipient] == false ) {
      _mapHolders.push(wallet);
      _holderInList[recipient] == true;
      }

  emit Transfer(sender, recipient, amount);

  }








  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}