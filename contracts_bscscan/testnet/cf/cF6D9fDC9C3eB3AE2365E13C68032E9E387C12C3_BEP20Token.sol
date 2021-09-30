/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

/*
  _                          _         
 (X)   __ _    ___    ___   (X)  _ __  
 | |  / _` |  / __|  / _ \  | | | '_ \ 
 | | | (_| | | (__  | (_) | | | | | | |
 |_|  \__, |  \___|  \___/  |_| |_| |_|
         |_|                           

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
}

contract Context {

  constructor () internal { }
  
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }
  
    function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see 
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

/*Token BEP 20 IQCoin  */
contract BEP20Token is Context, IBEP20, Ownable {

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;


  uint256 public _firstDayDate; 

  /* 5% fee */
  address public _walletSTAKE;         
  /* 10% burn */
  address public _walletBURN;          

  /* Initial Holders */
  address payable public _owner;  


  /* Total BUSD in Holders  */
  uint256 public _totalDividendsPaied;

  /* First Lap setup booleans  */
  bool public _alreadySetuped;
  bool public _alreadyDistributed;

  /* Additional IQCoin Rules  */
  bool public _preSaleActivated;


  /* Holders rules and controls  */
  mapping (address => bool) public _holderInList;  
  mapping (address => bool) public _itsWhale;  
  
  /*HOLDERS IN CONTRACT IQCoin*/
  address payable[] public _mapHolders;  
  

  constructor() public {

    _name = "IQCOIN";
    _symbol = "IQCOIN";
    _decimals = 9 ;
    _totalSupply = 78000000000000000;

    _balances[msg.sender] = 78000000000000000;  /* distruibuicao inicial 100%*/

    _firstDayDate = block.timestamp;

    _itsWhale[msg.sender] = true;
    _alreadyDistributed = false;
    _preSaleActivated = true;

    emit Transfer(address(0), msg.sender, _totalSupply);

  }


/* OWNER */
  function initialSetup (address payable dist1, address payable dist2) public onlyOwner() {
    require( _owner == msg.sender,"security guaranteed administrator only");
    require ( _alreadySetuped == false, "Executed only once");

     _walletSTAKE = dist1;         /* carteita STAKE 5%*/

     _itsWhale[_walletSTAKE] = true;

     _walletBURN = dist2;         /* carteita BURN 10% */

     _itsWhale[_walletBURN] = true;

     //10% BRUN 
     _transfer (_owner, _walletBURN,  7800000000000000);

    _alreadySetuped = true;
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
  uint256 rewardBNB;
  uint256 totalStake;
  uint256 totalToPay;

      /* total in hold */
      if (payQuote == 0 ) {
          for (holds=0; holds < _mapHolders.length; holds++) { 
            if (_balances[_mapHolders[holds]] > 5000000000000 && _itsWhale[_mapHolders[holds]] == false ) {
              totalStake = _balances[_mapHolders[holds]];
              totalStake = totalStake.div(1000000000);  /*5000 Tokens*/
              total = total.add(totalStake);
            }
          }
          _totalDividendsPaied = total;
      }

      if (payQuote > 0 ) {
        for (holdsPay=0; holdsPay < _mapHolders.length; holdsPay++) { 
          if (_balances[_mapHolders[holdsPay]] > 5000000000000 && _itsWhale[_mapHolders[holdsPay]] == false ) {
            
            totalToPay = _balances[_mapHolders[holdsPay]];
            totalToPay = totalToPay.div(1000000000);  /*5000 Tokens*/

            rewardBNB = payQuote;
            rewardBNB = rewardBNB.mul(totalToPay);

            _mapHolders[holdsPay].transfer(rewardBNB);

          }
        }      
      }
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

  //whale (baleia)
  function whaleYes(address account) public onlyOwner () {
   require( _owner == msg.sender,"security guaranteed administrator only");
   _itsWhale[account] = true;
  }

  function whaleNo(address account) public onlyOwner () {
   require( _owner == msg.sender,"security guaranteed administrator only");
   _itsWhale[account] = false;
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


      /*whale lock*/    
      if (_itsWhale[sender] == false) {
        require(amount <= 15000000000000, "Maximum transfer 15k IQCoin");
      }



      /* minimun to calc 100 wei*/
      require(_balances[sender] >= 100, "Minimu tranfer wei to tax fee 100 IqCoin");
      require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");



      /*tax 5%*/
      uint256 taxFee;
      taxFee = amount;
      taxFee = taxFee.mul(5);
      taxFee = taxFee.div(100);    /*get 5%*/

      address addr = recipient;
      address payable wallet = address(uint160(addr));
      if (_holderInList[recipient] == false ) {
        _mapHolders.push(wallet);
        _holderInList[recipient] = true;
      }

      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");






      if (_preSaleActivated == true){
          
          _balances[recipient] = _balances[recipient].add(amount);

          emit Transfer(sender, recipient, amount);
      }


      if (_preSaleActivated == false){
   
      amount = amount.sub(taxFee); /*sub 5%*/

          _balances[recipient] = _balances[recipient].add(amount);

          _balances[_walletSTAKE] = _balances[_walletSTAKE].add(taxFee);

          emit Transfer(sender, recipient, amount);

          emit Transfer(sender, _walletSTAKE, taxFee);

                  /* tax 10% queima até atingir 10% volume total*/  
                  uint256 taxBurn;  
                  taxBurn = taxFee;
                  taxBurn = taxBurn.mul(2);

              if (_balances[_walletBURN] >= taxBurn ) {
                  _burn(_walletBURN, taxBurn);
              }    

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