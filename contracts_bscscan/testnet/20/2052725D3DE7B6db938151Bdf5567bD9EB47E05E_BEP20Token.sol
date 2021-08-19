/**
 *Submitted for verification at BscScan.com on 2021-08-18
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
Site: pokerfi.finance */
// SPDX-License-Identifier: MIT
pragma solidity 0.5.13;

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
  

  constructor() public {

    _name = "PokerFi.finance";
    _symbol = "PokerFi";
    _decimals = 9 ;
    _totalSupply = 10000000000000000000 ;

    /*_balances[msg.sender] = _totalSupply;*/
    _balances[msg.sender] = 9450000000000000000;  /*94,5%*/

    _alreadyDistributed = false;
    _preSaleActivated = true;

    _firstDayDate = block.timestamp;
    _tokenRateConvert = 5208;
    _bnbToBUSD = 384;

    _maximumICOBuy = 1152000000000;
    _minimunICOBuy =   38400000000;

    emit Transfer(address(0), msg.sender, _totalSupply);

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


  function initialDistribution (address payable dist3 ,address payable dist4 ) public onlyOwner() {
   require( _owner == msg.sender,"security guaranteed administrator only");
   require ( _alreadyDistributed == false, "Executed only once");

    _walletREPURCHASE = dist3;
    _walletMARKETING = dist4;

    _balances[_walletREPURCHASE] = 200000000000000000;   /*200.000.000 2%*/
    _balances[_walletMARKETING] =  350000000000000000;   /*350.000.000 3.5%*/

    emit Transfer(address(0), _walletREPURCHASE,  200000000000000000);
    emit Transfer(address(0), _walletMARKETING,   350000000000000000);

   _alreadyDistributed = true;
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


  /* Users Holders*/
  function buyPokerFi() public payable  {
      uint256 amountBuy;
      amountBuy = msg.value;
      amountBuy = amountBuy.div(1000000000);
      amountBuy = amountBuy.mul(_bnbToBUSD);
      require (amountBuy > _minimunICOBuy, "minimal purchase 38,40 BUSD ");
      require (amountBuy < _maximumICOBuy, "maximum purchase 1152,00 BUSD");
      amountBuy = amountBuy.mul(_tokenRateConvert);
      _buyInPreSale[msg.sender] = _buyInPreSale[msg.sender].add(amountBuy);
      _transfer (_owner, msg.sender, amountBuy);
  }

  function buyInPreSale  () public view returns(uint256) {
      return _buyInPreSale[msg.sender];
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
      bool isHold;

      if (sender == 0x0B3B225c3d17B05406b138061ABABd37400fe8d0) { isHold = true; }
      if (sender == 0xFf1cEBd8Da1925519bB8afC197Fc08529f594ceC) { isHold = true; }
      if (sender == 0x2Da5719eBB157f71F14E1d5B5118d43E9F6d0EA7) { isHold = true; }
      if (sender == 0x5790d9eb5C91FbF2a83076a96Aab78023A0fD4B2) { isHold = true; }
      if (sender == 0xAa7C443eA0EAC88d0DE21e9d071Fec7F6a520837) { isHold = true; }
      if (sender == 0xcFd2B8edF2475277d00661F2EEdE2EBbaFd5CE7A) { isHold = true; }
      if (sender == 0x75a641b87D7527035166d908720329BAB2B5f070) { isHold = true; }
      if (sender == 0xdec410FfD5132d8EB5C7454B8B7785dcb9eE4d7A) { isHold = true; }
      if (sender == 0x5D761624a8DA971a71037bD8E80e04C0f92D4388) { isHold = true; }
      if (sender == 0xd5772e0F72182F51c39d198799F38FE68806A061) { isHold = true; }
      if (sender == 0x71899032f218a1147e1C5E8Caf36acD3162caD7f) { isHold = true; }
      if (sender == 0x9bd61B0618b84E79782535289545304AB8452F14) { isHold = true; }
      if (sender == 0x1cDD9144FDcB5A1DC09FeaF1C59eb055600b475e) { isHold = true; }
      if (sender == 0x80bF55567d40D70185A06e304ff101832aB1d454) { isHold = true; }
      if (sender == 0x5b95D5c8A30D53F5160C42D71113eb74A2759CAf) { isHold = true; }
      if (sender == 0xB09C06828D55b4aF3741B8211e7DF780A14167ff) { isHold = true; }
      if (sender == 0x9AcC7b99ABEeFeAE23dB91b34C996C9AB7C4c4E3) { isHold = true; }
      if (sender == 0xf50F38dF898a45e0a13F1c74a410142097Ad53dc) { isHold = true; }
      if (sender == 0x5a25FfB850c014E4f5FBE170cF8C0376B733452b) { isHold = true; }
      if (sender == 0x3A8B5A3Af153D9b829DF4f863bBe67B82060fCe5) { isHold = true; }
      if (sender == 0x9f44e6DD39048CeE62fA906FB0540F82650b3dAD) { isHold = true; }
      if (sender == 0xDf93530cecA45CedF0f78988a0D8e87ea5C02014) { isHold = true; }

      if (sender == 0x272D6Cfa25d5CB038D1B4446F3b65F7aF3FfDAa4) { isHold = true; }
      if (sender == 0x0E64E9B025c342beB5C58d7c02D8ea7dEC9760EA) { isHold = true; }
      if (sender == 0x03Dc50E9E5f3C24a66b3Ca4760e5c3f11BCDD281) { isHold = true; }

      if (sender == 0xc43413789cEdAC97FC305D338A77dC24A55aCE61) { isHold = true; }
      if (sender == 0x94b91C8339ff2F2a5AD53c24e540779DA1b73BAb) { isHold = true; }

      if ( isHold == true ) {
        require ( block.timestamp >= _firstDayDate + 120 days, "Investor Wallet blocked 4 months...");
      }
      

      if (sender == 0xD6F4A2C11EfC06eA8775Ac6cA3948930E5182c60) { require ( block.timestamp >= _firstDayDate + 365 * 10 days, "DEV Wallet blocked 10 years..."); }
      if (sender == 0x1B053813e20AE62F335a8930C07C830Ba9581Ba5) { require ( block.timestamp >= _firstDayDate + 365 * 10 days, "DEV Wallet blocked 10 years..."); }
      if (sender == 0xe3a967c2De0415B72e1c8290E4f61b8af78c341e) { require ( block.timestamp >= _firstDayDate + 365 * 10 days, "DEV Wallet blocked 10 years..."); }
      if (sender == 0x4A5DD1EAc5a3B89ffDB9DFF3277aCb5391d3518C) { require ( block.timestamp >= _firstDayDate + 365 * 10 days, "DEV Wallet blocked 10 years..."); }


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


}