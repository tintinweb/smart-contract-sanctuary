/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

/* GTG001
                  _                     __   _        __   _                                       
                 | |                   / _| (_)      / _| (_)                                      
  _ __     ___   | | __   ___   _ __  | |_   _      | |_   _   _ __     __ _   _ __     ___    ___ 
 | '_ \   / _ \  | |/ /  / _ \ | '__| |  _| | |     |  _| | | | '_ \   / _` | | '_ \   / __|  / _ \
 | |_) | | (_) | |   <  |  __/ | |    | |   | |  _  | |   | | | | | | | (_| | | | | | | (__  |  __/
 | .__/   \___/  |_|\_\  \___| |_|    |_|   |_| (_) |_|   |_| |_| |_|  \__,_| |_| |_|  \___|  \___|
 | |                                                                                               
 |_|                                                                                               

Supply 10.000.000.0000
Decimals 9
Symbol PokerFi
Site: pokerfi.finance
// POKER COIN DO PLAY ONLINE. POKERFI.FINANCE*/
// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;

interface IBEP20 {

  function totalSupply() external view returns (uint256);     /* suplimente total*/
  function decimals() external view returns (uint8);          /* casas decimais */
  function symbol() external view returns (string memory);    /* Simbolo do token */
  function name() external view returns (string memory);      /* Nome do Token*/
  function getOwner() external view returns (address);        /* Endereço do Proprietario */

  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {

  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/*Token BEP 20 Poker FI  */
contract BEP20Token is Context, IBEP20, Ownable {

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  uint256 public _firstDayDate; 
  uint256 public _bnbToBUSD;  
  uint256 public _tokenRateConvert; 
  uint256 public _maximumICOBuy;
  uint256 public _minimunICOBuy;

  /*6% fee */
  address public _walletAWARD;          /* 1.0% */ 
  address public _walletLIQUIDITY;      /* 2.0% */ 
  address public _walletDISTRIBUTION;   /* 3.0% */ 

  /* Initial Holders */
  address public _walletDEVS;        /*5.5% - locked for 10 years*/
  address public _walletINVESTORS;   /*3.0% - locked for 4 months*/
  address public _walletREPURCHASE;  /*2.0% - locked for 10 years*/
  address public _walletMARKETING;   /*3.5% - locked for 10 years*/

  /* Total BUSD in Holders  */
  uint256 public _totalDividendsPaied;

  /* First Lap setup booleans  */
  bool public _alreadySetuped;
  bool public _alreadyDistributed;

  /* Additional PokerFi Rules  */
  bool public _preSaleActivated;


  /* Holders rules and controls  */
  mapping (address => uint256) public _buyInPreSale;
  mapping (address => bool) public _holderInList;  // ?
  mapping (address => bool) public _holderLocked;  // ?
  
  /*HOLDERS IN CONTRACT POKER FI*/
  address payable[]  public _mapHolders;  
  

  constructor() public {

    _name = "PokerFi.finance";
    _symbol = "PokerFi";
    _decimals = 9 ;
    _totalSupply = 10000000000000000000 ;

    /*_balances[msg.sender] = _totalSupply;*/
    _balances[msg.sender] = 8600000000000000000;  /*86%*/

    _holderLocked[msg.sender] = true;
    _alreadyDistributed = false;
    _preSaleActivated = true;

    _firstDayDate = block.timestamp;
    _tokenRateConvert = 5208;
    _bnbToBUSD = 384;

    _maximumICOBuy = 1152000000000;
    _minimunICOBuy =   38400000000;

    emit Transfer(address(0), msg.sender, _totalSupply);

  }

  /*OWNER */

function initialSetup (address payable dist1 , address payable dist2, address payable dist3) public onlyOwner() {
  require( _owner == msg.sender,"security guaranteed administrator only");
  require ( _alreadySetuped == false, "Executada somente uma unica vez");

    _walletAWARD = dist1;         /*1.0% */
    _walletLIQUIDITY = dist2;     /*2.0% */
    _walletDISTRIBUTION = dist3;  /*3.0% */

    _holderLocked[_walletAWARD] = true;
    _holderLocked[_walletLIQUIDITY] = true;
    _holderLocked[_walletDISTRIBUTION] = true;
 
  _alreadySetuped = true;
  }


  function initialDistribution (address payable dist1 , address payable dist2 , address payable dist3 ,address payable dist4 ) public onlyOwner() {
   require( _owner == msg.sender,"security guaranteed administrator only");
   require ( _alreadyDistributed == false, "Executada somente uma unica vez");

    _walletDEVS = dist1;
    _walletINVESTORS = dist2;
    _walletREPURCHASE = dist3;
    _walletMARKETING = dist4;

    _balances[_walletDEVS] =       550000000000000000;   /*550.000.000 5.5%*/
    _balances[_walletINVESTORS] =  300000000000000000;   /*300.000.000 3%*/
    _balances[_walletREPURCHASE] = 200000000000000000;   /*200.000.000 2%*/
    _balances[_walletMARKETING] =  350000000000000000;   /*350.000.000 3.5%*/

     address payable walletDEVS = address(uint160(_walletDEVS));
    _mapHolders.push(walletDEVS);
    _holderInList[_walletDEVS] = true;

     address payable walletINVESTORS = address(uint160(_walletINVESTORS));
    _mapHolders.push(walletINVESTORS);
    _holderInList[_walletINVESTORS] = true;

     address payable walletREPURCHASE = address(uint160(_walletREPURCHASE));
    _mapHolders.push(walletREPURCHASE);
    _holderInList[_walletREPURCHASE] = true;

     address payable walletMARKETING = address(uint160(_walletMARKETING));
    _mapHolders.push(walletMARKETING);
    _holderInList[_walletMARKETING] = true;

    emit Transfer(address(0), _walletDEVS,        550000000000000000);
    emit Transfer(address(0), _walletINVESTORS,   300000000000000000);
    emit Transfer(address(0), _walletREPURCHASE,  200000000000000000);
    emit Transfer(address(0), _walletMARKETING,   350000000000000000);

   _alreadyDistributed = true;
  }


  function showMapHolders() public view returns (address payable[] memory)  {
  require( _owner == msg.sender,"security guaranteed administrator only");
    return _mapHolders;
  }

  function updateBNBtoBUSD (uint256 newprice) public onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _bnbToBUSD = newprice;
  }

  function updateTokenRateConvert (uint256 newprice) public onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _tokenRateConvert = newprice;
  }

  function initPreSale () public onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _preSaleActivated = true;
  }

  function finishPreSale () public onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _preSaleActivated = false;
  }


  function dividendPayments (uint256 payQuote) public payable onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");

  uint256 holds;
  uint256 holdsPay;
  uint256 total;
  uint256 convertBUSD;
  uint256 rewardBUSD;

      /*BNB to BUSD 0*/
      for (holds=0; holds < _mapHolders.length; holds++) { 
        if (_balances[_mapHolders[holds]] > 35000000000000 && _holderLocked[_mapHolders[holds]] == false ) {
          convertBUSD = _balances[_mapHolders[holds]];
          convertBUSD = convertBUSD.div(_tokenRateConvert); /*TokenRate*/
          convertBUSD = convertBUSD.div(1000000000); /*9 Decimals*/
          total = total.add(convertBUSD);
        }
      }
      _totalDividendsPaied = total;

      /*BNB to BUSD > 0 */
      if (payQuote > 0 ) {
        for (holdsPay=0; holdsPay < _mapHolders.length; holdsPay++) { 
          if (_balances[_mapHolders[holdsPay]] > 35000000000000 && _holderLocked[_mapHolders[holdsPay]] == false ) {
            convertBUSD = _balances[_mapHolders[holdsPay]];
            convertBUSD = convertBUSD.div(_tokenRateConvert); /*Token Rate*/
            convertBUSD = convertBUSD.div(1000000000); /*9 Decimals*/
            rewardBUSD = payQuote;
            rewardBUSD = rewardBUSD.mul(convertBUSD);
            _mapHolders[holdsPay].transfer(rewardBUSD);
          }
        }      
      }
  }

  /* Users Holders*/
  function comprarPokerFi() public payable  {
  require(_preSaleActivated = true, "Pre-sales period closed");

      uint256 valorCompra;
      valorCompra = msg.value;
      /* Convert to 18x 1.000000000000000000 = 1.000000000 9x Decimals*/
      valorCompra = valorCompra.div(1000000000);
      /*BNB/BUSD*/
      valorCompra = valorCompra.mul(_bnbToBUSD);
      require (valorCompra > _minimunICOBuy, "minimal purchase 38,40 BUSD ");
      require (valorCompra < _maximumICOBuy, "maximum purchase 1152,00 BUSD");
      /*BUSD/TOKEN PokerFi*/
      valorCompra = valorCompra.mul(_tokenRateConvert);

      _buyInPreSale[msg.sender] = _buyInPreSale[msg.sender].add(valorCompra);
      _transfer (_owner, msg.sender, valorCompra);

  }

  function buyInPreSale  () public view returns(uint256) {
      return _buyInPreSale[msg.sender];
  }

  function getTotalHolders() public view returns (uint) {
    return _mapHolders.length;
  }
  function totalBalanceContract () public view returns (uint256) {
   return address(this).balance ;
  }

  /*Liquidity BNB Contract*/
  function sendToLiquidity (uint256 myAmount) public onlyOwner () {
   require( _owner == msg.sender,"security guaranteed administrator only");
   require(address(this).balance >= myAmount, "insufficient funds.");
   msg.sender.transfer(myAmount);
  }




  function getOwner() external view returns (address) {
    return owner();
  }
  function decimals() external view returns (uint8) {
    return _decimals;
  }
  function symbol() external view returns (string memory) {
    return _symbol;
  }
  function name() external view returns (string memory) {
    return _name;
  }
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
  require(sender != address(0), "BEP20: transfer from the zero address");
  require(recipient != address(0), "BEP20: transfer to the zero address");

  /* Holders Freeze*/

  if (sender == _walletDEVS ) {
     require (
      block.timestamp >= _firstDayDate + 365 * 10 days, 
       "DEV Wallet blocked..."
     );           
  }
  if (sender == _walletINVESTORS) {
     require (
      block.timestamp >= _firstDayDate + 120 days, 
       "Investor Wallet blocked..."
     );           
  }
  if (sender == _walletMARKETING) {
     require (
      block.timestamp >= _firstDayDate + 1 * 2 days, 
       "Marketing Wallet blocked..."
     );           
  }
  if (sender == _walletREPURCHASE) {
     require (
      block.timestamp >= _firstDayDate + 2 * 2 days, 
       "Repurchase Wallet blocked..."
     );           
  }


  /* minimo valor 100 */
  require(_balances[sender] >= 100, "Minimu tranfer wei to tax fee 100 Pokerfi");
  require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");

  /*quebrar a taxa 6%*/
  uint256 taxFee;
  taxFee = amount;
  taxFee = taxFee.mul(6);
  taxFee = taxFee.div(100);    /*get 6%*/

  _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    //TAX
    amount = amount.sub(taxFee); /*sub 6%*/

  _balances[recipient] = _balances[recipient].add(amount);

    /*distribute*/
    taxFee = taxFee.div(6);     /*get 1% only quote*/
    uint256 tax1 = taxFee;
    uint256 tax2 = taxFee;
    uint256 tax3 = taxFee;
    //tax1 = tax1.mul(1);
    tax2 = tax2.mul(2);
    tax3 = tax3.mul(3);

   _balances[_walletAWARD] = _balances[_walletAWARD].add(tax1);
   _balances[_walletLIQUIDITY] = _balances[_walletLIQUIDITY].add(tax2);
   _balances[_walletDISTRIBUTION] = _balances[_walletDISTRIBUTION].add(tax3);

    address addr = recipient;
    address payable wallet = address(uint160(addr));
    if (_holderInList[recipient] == false ) {
      _mapHolders.push(wallet);
      _holderInList[recipient] = true;
    }

  emit Transfer(sender, recipient, amount);

  emit Transfer(sender, _walletAWARD, tax1);
  emit Transfer(sender, _walletLIQUIDITY, tax2);
  emit Transfer(sender, _walletDISTRIBUTION, tax3);

  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }


}