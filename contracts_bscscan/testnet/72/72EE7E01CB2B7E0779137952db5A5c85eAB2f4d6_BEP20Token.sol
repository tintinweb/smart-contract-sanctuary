/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IBEP20 {

  function totalSupply() external view returns (uint256);  
  function decimals() external view returns (uint8);       
  function symbol() external view returns (string memory); 
  function name() external view returns (string memory);   
  function getOwner() external view returns (address);     

  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event TexasHoldemTournament(string indexed gameplay, uint256 indexed value);
  event PokerTournament(string indexed gameplay, uint256 indexed value);
  event PokerRakeback(string indexed gameplay, uint256 indexed value);
  event PokerCashback(string indexed gameplay, uint256 indexed value);
  event PokerPayBUSD(string indexed gameplay, uint256 indexed value);
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
    require( _owner == msg.sender,"security guaranteed administrator only");
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require( _owner == msg.sender,"security guaranteed administrator only");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require( _owner == msg.sender,"security guaranteed administrator only");
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

  /*6% fee */
  address public _walletAWARD;          /* 1.0% */ 
  address public _walletLIQUIDITY;      /* 2.0% */ 
  address public _walletDISTRIBUTION;   /* 3.0% */ 

  /* Initial Holders */
  address public _walletREPURCHASE;  /*2.0% - locked for 10 years*/
  address public _walletMARKETING;   /*3.5% - locked for 10 years*/
  
  /*burn*/
  address public _walletBURN;   /*burn*/

  /*Wallet POKER GAME PLAY*/
  address public _walletGAMEPLAY;    /*Wallet POKER GAME PLAY*/
    string public _texasHoldemTournament;
    string public _pokerTournament;
    string public _pokerRakeback;
    string public _pokerCashback;
    string public _pokerPayBUSD;
  uint256 public _texasHoldemTournamentU;
  uint256 public _pokerTournamentU;
  uint256 public _pokerRakebackU;
  uint256 public _pokerCashbackU;
  uint256 public _pokerPayBUSDU;

  /* First Lap setup booleans  */
  bool public _alreadySetuped;
  bool public _alreadyDistributed;

  /* Additional PokerFi Rules  */
  bool public _preSaleActivated;

  constructor() public {
    _name = "BabyokerFI.Finance";
    _symbol = "BabyPokerFI";
    _decimals = 9;
    _totalSupply = 10000000000;
    _balances[msg.sender] = 94500000000;  /*94,5%*/
    _alreadyDistributed = false;
    _alreadySetuped = false;
    _preSaleActivated = true;
    _firstDayDate = block.timestamp;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

function initialDistribution (address payable dist3 ,address payable dist4 ) public onlyOwner() {
  require( _owner == msg.sender,"security guaranteed administrator only");
  require ( _alreadyDistributed == false, "Executed only once");
  _walletREPURCHASE = dist3;
  _walletMARKETING = dist4;
  _balances[_walletREPURCHASE] = 200000000;   /*200.000.000 2%*/
  _balances[_walletMARKETING] =  350000000;   /*350.000.000 3.5%*/
  emit Transfer(address(0), _walletREPURCHASE,  200000000);
  emit Transfer(address(0), _walletMARKETING,   350000000);
  _alreadyDistributed = true;
}

/* OWNER */
function initialSetup (address payable dist1 , address payable dist2, address payable dist3) public onlyOwner() {
  require( _owner == msg.sender,"security guaranteed administrator only");
  require ( _alreadySetuped == false, "Executed only once");
    _walletAWARD = dist1;         /*1.0% */
    _walletLIQUIDITY = dist2;     /*2.0% */
    _walletDISTRIBUTION = dist3;  /*3.0% */
  _alreadySetuped = true;
  }

function gamePlaySetup (address payable dist1) public onlyOwner() {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _walletGAMEPLAY = dist1;         /*Poker Game Play Wallet% */
  }

function gameBurnSetup (address payable dist1) public onlyOwner() {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _walletBURN = dist1;         /*Poker Game Play Wallet% */
  }

  function initPreSale () public onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _preSaleActivated = true;
  }

  function finishPreSale () public onlyOwner () {
  require( _owner == msg.sender,"security guaranteed administrator only");
    _preSaleActivated = false;
  }

  function sendToLiquidity (uint256 myAmount) public onlyOwner () {
   require( _owner == msg.sender,"security guaranteed administrator only");
   require(address(this).balance >= myAmount, "insufficient funds.");
   msg.sender.transfer(myAmount);
  }

  function burnPokerFi (uint256 myAmount) public onlyOwner () {
   require( _owner == msg.sender,"security guaranteed administrator only");
   require( _balances[_walletBURN] >= myAmount,"not amount to burn");
  _burn(_walletBURN, myAmount);
  }

  function pokerPayBUSD (string memory gameplay, uint256 pot) public returns (bool) {
  require( _walletGAMEPLAY == msg.sender,"only game play wallet accept");
    _pokerPayBUSD = gameplay;
    _pokerPayBUSDU = pot;
  emit PokerPayBUSD (gameplay,pot);
  return true;
  }

  function pokerCashback (string memory gameplay, uint256 pot) public returns (bool) {
  require( _walletGAMEPLAY == msg.sender,"only game play wallet accept");
     _pokerCashback = gameplay;
    _pokerCashbackU = pot;
  emit PokerCashback(gameplay,pot);
  return true;
  }

  function pokerRakeback (string memory gameplay, uint256 pot) public returns (bool) {
  require( _walletGAMEPLAY == msg.sender,"only game play wallet accept");
    _pokerRakeback = gameplay;
    _pokerRakebackU = pot;
  emit PokerRakeback(gameplay,pot);
  return true;
  }

  function pokerTournament (string memory gameplay, uint256 pot) public returns (bool) {
  require( _walletGAMEPLAY == msg.sender,"only game play wallet accept");
    _pokerTournament = gameplay;
    _pokerTournamentU = pot;
  emit PokerTournament(gameplay,pot);
  return true;
  }

  function texasHoldemTournament (string memory gameplay, uint256 pot) public returns (bool) {
  require( _walletGAMEPLAY == msg.sender,"only game play wallet accept");
    _texasHoldemTournament = gameplay;
    _texasHoldemTournamentU = pot;
  emit TexasHoldemTournament(gameplay,pot);
  return true;
  }

  function totalBalanceContract () public view returns (uint256) {
   return address(this).balance ;
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

      if (sender == _walletMARKETING) {
         require (
          block.timestamp >= _firstDayDate + 365 * 10 days, 
           "Marketing Wallet blocked..."
         );           
      }
      if (sender == _walletREPURCHASE) {
         require (
          block.timestamp >= _firstDayDate + 365 * 10 days, 
           "Repurchase Wallet blocked..."
         );           
      }

          /* minimun to calc 100 wei*/
          require(_balances[sender] >= 100, "Minimu tranfer wei to tax fee 100 Pokerfi");
          require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");

          /*tax 6%*/
          uint256 taxFee;
          taxFee = amount;
          taxFee = taxFee.mul(6);
          taxFee = taxFee.div(100);    /*get 6%*/


          _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");



      if (_preSaleActivated == true){
          
          _balances[recipient] = _balances[recipient].add(amount);

          emit Transfer(sender, recipient, amount);
      }


      if (_preSaleActivated == false){
   
           amount = amount.sub(taxFee); /*sub 6%*/

          _balances[recipient] = _balances[recipient].add(amount);

          /*distribute*/
          taxFee = taxFee.div(6);     /*get 1% only quote*/
          uint256 tax1 = taxFee;
          uint256 tax2 = taxFee;
          uint256 tax3 = taxFee;
          tax2 = tax2.mul(2);
          tax3 = tax3.mul(3);

         _balances[_walletAWARD] = _balances[_walletAWARD].add(tax1);
         _balances[_walletLIQUIDITY] = _balances[_walletLIQUIDITY].add(tax2);
         _balances[_walletDISTRIBUTION] = _balances[_walletDISTRIBUTION].add(tax3);

          emit Transfer(sender, recipient, amount);

          emit Transfer(sender, _walletAWARD, tax1);
          emit Transfer(sender, _walletLIQUIDITY, tax2);
          emit Transfer(sender, _walletDISTRIBUTION, tax3);
      }
  }


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }


}