/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

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
    this;
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

contract BEP20 is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _presalebalances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _deployTime;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  bool private _setup;

  address public ContractAdr;
  address public DevAdr;
  address public MarketingAdr;
  address public LiquilityAdr;
  address public PresaleAdr;
  address public BuybackAdr;
  address public DeadAdr;

  uint256 public _rewardpool;
  uint256 public _devpool;
  uint256 public _marketingpool;
  uint256 public _liquilitypool;
  uint256 public _presalepool;
  uint256 public _buybackpool;

  uint256 public _sellTaxFee_Pool;
  uint256 public _sellTaxFee_Marketing;
  uint256 public _sellTaxFee_Burn;
  uint256 public _sellTaxFee;

  uint256 public _buyTaxFee_Pool;
  uint256 public _buyTaxFee_Marketing;
  uint256 public _buyTaxFee_Burn;
  uint256 public _buyTaxFee;

  uint256 public _impactFee;

  constructor() public {
    _name = "ChickenVsWolf TestNet";
    _symbol = "CVWT";
    _decimals = 18;
    _totalSupply = 100000000 * (10 ** 18);
    _balances[msg.sender] = _totalSupply;
    DeadAdr = 0x000000000000000000000000000000000000dEaD;
    _updateContract(address(this));
    _updateDev(msg.sender);
    _deployTime = block.timestamp;

    emit Transfer(address(0), msg.sender, _totalSupply);

    //Tekonomic div 1000//
    _rewardpool = 400;
    _devpool = 100;
    _marketingpool = 150;
    _liquilitypool = 200;
    _presalepool = 100;
    _buybackpool = 50;
    //Transection Tax div 1000//
    _sellTaxFee_Pool = 15;
    _sellTaxFee_Marketing = 40;
    _sellTaxFee_Burn = 5;
    _sellTaxFee = _sellTaxFee_Pool + _sellTaxFee_Marketing + _sellTaxFee_Burn;
    // total sell fee is 6%

    _buyTaxFee_Pool = 5;
    _buyTaxFee_Marketing = 5;
    _buyTaxFee_Burn = 5;
    _buyTaxFee = _buyTaxFee_Pool + _buyTaxFee_Marketing + _buyTaxFee_Burn;
    // total buy fee is 1.5%

    _impactFee = 249; // anti-bot with 24.9% tax
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

  function presalebalanceOf(address account) external view returns (uint256) {
    return _presalebalances[account];
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

  function mint(uint256 amount) public onlyOwner returns (bool) {
    require( 1 == 0,"BEP20: mint function has been disabled");
    _mint(_msgSender(), amount);
    return true;
  }

  function setupAddress(address a,address b,address c,address d) public onlyOwner returns (bool) {
    require( _setup == false,"BEP20: this function only use once");
    _setup = true;
    _updateMarketing(a);
    _updateLiquility(b);
    _updatePresale(c);
    _updateBuyback(d);

    _rewardpool = _rewardpool.mul(_totalSupply).div(1000);
    _devpool = _devpool.mul(_totalSupply).div(1000);
    _marketingpool = _marketingpool.mul(_totalSupply).div(1000);
    _liquilitypool = _liquilitypool.mul(_totalSupply).div(1000);
    _presalepool = _presalepool.mul(_totalSupply).div(1000);
    _buybackpool = _buybackpool.mul(_totalSupply).div(1000);

    _transfer(msg.sender,ContractAdr,_rewardpool);
    _transfer(msg.sender,MarketingAdr,_marketingpool);
    _transfer(msg.sender,LiquilityAdr,_liquilitypool);
    _transfer(msg.sender,PresaleAdr,_presalepool);
    _transfer(msg.sender,BuybackAdr,_buybackpool);

    emit Transfer(msg.sender, ContractAdr, _rewardpool);
    emit Transfer(msg.sender, MarketingAdr, _marketingpool);
    emit Transfer(msg.sender, LiquilityAdr, _liquilitypool);
    emit Transfer(msg.sender, PresaleAdr, _presalepool);
    emit Transfer(msg.sender, BuybackAdr, _buybackpool);

    return true;
  }

  function deposit() public payable {
    _presalebalances[msg.sender] = _presalebalances[msg.sender].add(msg.value);
  }

  function _updateContract(address input) public onlyOwner returns (bool) {
    ContractAdr = input;
    return true;
  }

  function _updateDev(address input) public onlyOwner returns (bool) {
    DevAdr = input;
    return true;
  }

  function _updateMarketing(address input) public onlyOwner returns (bool) {
    MarketingAdr = input;
    return true;
  }

  function _updateLiquility(address input) public onlyOwner returns (bool) {
    LiquilityAdr = input;
    return true;
  }

  function _updatePresale(address input) public onlyOwner returns (bool) {
    PresaleAdr = input;
    return true;
  }

  function _updateBuyback(address input) public onlyOwner returns (bool) {
    BuybackAdr = input;
    return true;
  }

  function _updateTaxSell_Pool(uint256 input) public onlyOwner returns (bool) {
    _sellTaxFee_Pool = input;
    _sellTaxFee = _sellTaxFee_Pool + _sellTaxFee_Marketing + _sellTaxFee_Burn;
    return true;
  }

  function _updateTaxSell_Market(uint256 input) public onlyOwner returns (bool) {
    _sellTaxFee_Marketing = input;
    _sellTaxFee = _sellTaxFee_Pool + _sellTaxFee_Marketing + _sellTaxFee_Burn;
    return true;
  }

  function _updateTaxSell_Burn(uint256 input) public onlyOwner returns (bool) {
    _sellTaxFee_Burn = input;
    _sellTaxFee = _sellTaxFee_Pool + _sellTaxFee_Marketing + _sellTaxFee_Burn;
    return true;
  }

  function _updateTaxBuy_Pool(uint256 input) public onlyOwner returns (bool) {
    _buyTaxFee_Pool = input;
    _buyTaxFee = _buyTaxFee_Pool + _buyTaxFee_Marketing + _buyTaxFee_Burn;
    return true;
  }

  function _updateTaxBuy_Market(uint256 input) public onlyOwner returns (bool) {
    _buyTaxFee_Marketing = input;
    _buyTaxFee = _buyTaxFee_Pool + _buyTaxFee_Marketing + _buyTaxFee_Burn;
    return true;
  }

  function _updateTaxBuy_Burn(uint256 input) public onlyOwner returns (bool) {
    _buyTaxFee_Burn = input;
    _buyTaxFee = _buyTaxFee_Pool + _buyTaxFee_Marketing + _buyTaxFee_Burn;
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    if ( sender == owner() || recipient == owner() ) {
                _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
    } else {
        if ( _setup == true ) {
            if ( recipient == LiquilityAdr) {                
                _balances[sender] = _balances[sender].sub(amount.mul(1000 - _sellTaxFee).div(1000), "BEP20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount.mul(1000 - _sellTaxFee).div(1000));
                _takeSellFee(sender,amount);
                emit Transfer(sender, recipient, amount.mul(1000 - _sellTaxFee).div(1000));        
            } else if ( sender == LiquilityAdr) {
                _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
                _takeBuyFee(recipient,amount);
            } else {
                _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
            }
        } else {
                _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
                amount = amount.mul(_impactFee).div(1000);
                _balances[recipient] = _balances[recipient].sub(amount);
                _balances[ContractAdr] = _balances[ContractAdr].add(amount);
                emit Transfer(recipient, ContractAdr, amount);
        }
    }
  }

  function _takeSellFee(address account, uint256 amount) internal {
    uint256 _fee = amount.mul(_sellTaxFee).div(1000);
    uint256 _feePool = amount.mul(_sellTaxFee_Pool).div(1000);
    uint256 _feeMarket = amount.mul(_sellTaxFee_Marketing).div(1000);
    uint256 _feeBurn = amount.mul(_sellTaxFee_Burn).div(1000);

    _balances[account] = _balances[account].sub(_fee);

    _balances[ContractAdr] = _balances[ContractAdr].add(_feePool);
    _balances[MarketingAdr] = _balances[MarketingAdr].add(_feeMarket);
    _balances[DeadAdr] = _balances[DeadAdr].add(_feeBurn);

    emit Transfer(account,ContractAdr, _feePool);
    emit Transfer(account,MarketingAdr, _feeMarket);
    emit Transfer(account,DeadAdr, _feeBurn);
  }

  function _takeBuyFee(address account, uint256 amount) internal {
    uint256 _fee = amount.mul(_buyTaxFee).div(1000);
    uint256 _feePool = amount.mul(_buyTaxFee_Pool).div(1000);
    uint256 _feeMarket = amount.mul(_buyTaxFee_Marketing).div(1000);
    uint256 _feeBurn = amount.mul(_buyTaxFee_Burn).div(1000);

    _balances[account] = _balances[account].sub(_fee);

    _balances[ContractAdr] = _balances[ContractAdr].add(_feePool);
    _balances[MarketingAdr] = _balances[MarketingAdr].add(_feeMarket);
    _balances[DeadAdr] = _balances[DeadAdr].add(_feeBurn);
    
    emit Transfer(account,ContractAdr, _feePool);
    emit Transfer(account,MarketingAdr, _feeMarket);
    emit Transfer(account,DeadAdr, _feeBurn);
  }

  function _mint(address account, uint256 amount) internal {
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