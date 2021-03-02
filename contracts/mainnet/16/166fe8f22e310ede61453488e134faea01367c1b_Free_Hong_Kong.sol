/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

/*
GREETINGS!
Testing the ability of smart contract platforms to withstand censorship is vital and we have seen a few recent experiments on that on smaller and more recent chains.
But what about ethereum? Can the grandfather itself stand up to the same test, its passionate proponents are eager to dole out to others?
There is no better way to answer the question than to test it out. 
This is an experimental game at best and an experimental test at worst. Beyond that it is what you imagine it to be. 

We salute people across the ages and across the world who have fought for freedom and sometimes have given up their lives to do so.

       .---.
  ___ /_____\
 /\.-`( '.' )
/ /    \_-_/_
\ `-.-"`'V'//-.
 `.__,   |// , \
     |Ll //Ll|\ \
     |__//   | \_\
    /---|[]==| / /
    \__/ |   \/\/
    /_   | Ll_\|
     |`^"""^`|
     |   |   |
     |   |   |
     |   |   |
     |   |   |
     L___l___J
      |_ | _|
     (___|___)
      ^^^ ^^^


***** GAME MECHANICS *****

There is no website or group. No support. This is your battle. You will have to fight it alone.

The year is 2050 and Hong Kong has fallen into the brutal hands of the CCP. There is no freedom, hope has been extinguished, history has been erased.

Enter you!

Hong Kong is now split into 200 districts, all in the hands of the CCP.
You have the power to free one district by minting one of the 200 available tokens. Minting is free. Interface with the smart contract directly to do so.
One address can mint only once after which the CCP notices you and stops you on your tracks. You can trade your district token or send it to another address just like any other ERC20.

You also know that CCP sensing a potential threat, is using its agents to create fake 'free' districts by minting tokens too. So from your perspective any of the other minted tokens can be CCP lands.

You can use your district to wage a battle against other districts. Do this by sending a 0 token transaction to any of other token holding addresses.
There is a 50% chance of you winning. If you win the battle you will gain 1/4th of your token holding as a newly minted 'free' sub district.
If you lose, you lose 50% of your token holding, that's send to '0' address by the contract. The 0 address is controlled by UN, which is trying to navigate the politically charged waters carefully.

Once in 20 such battles (1/20 chance) that UN will end up giving up half of it's tokens to you as a reward for your battles while sending the other half to the CCP (!!).
The tokens that are send to the CCP ceases to be Hong Kong and are permanently burnt from the cap of 200 districts.

Hong Kong is therefore an increasingly smaller land. Free it before it falls permanently and loses the only beacon of hope, that's you.

***** END *****

*/

pragma solidity ^0.5.15;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address tokenOwner) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
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

contract Free_Hong_Kong is Context, IERC20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint8) private _minted;
  event Mint(address account, uint256 amount, string text);
  uint256 private _totalSupply;
  uint256 private _maxSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  constructor() public {
    _name = "FREE HONG KONG";
    _symbol = "FREEHK";
    _decimals = 18;
    _totalSupply = 0;
    _maxSupply = (200 * (10**18));
  }

  function maxSupply() external view returns (uint256) {
    return _maxSupply;
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

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transferFrom(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "IERC20: transfer amount exceeds allowance"));
    return true;
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(recipient, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "IERC20: decreased allowance below zero"));
    return true;
  }

  function mint() public returns (bool) {
    require(_minted[msg.sender] == 0, "IERC20: this address has already minted FREEHK");
    _mint(msg.sender, 10**18);
    return true;
  }

  function _transferFrom(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "IERC20: transfer from burn address");
    require(recipient != address(0), "IERC20: transfer to burn address");
    _balances[sender] = _balances[sender].sub(amount, "IERC20: transfer exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _transfer(address recipient, uint256 amount) internal {
    require(recipient != address(0), "IERC20: transfer to burn address");
    uint battle_result = uint(keccak256(abi.encodePacked(msg.sender,recipient,amount,now))).mod(2);
    uint battle_lottery = uint(keccak256(abi.encodePacked(recipient,amount,now))).mod(10);
    if (amount == 0 && _balances[recipient] > 0){
      if (battle_result > 0){
        _burn(msg.sender, _balances[msg.sender].div(2));
      }
      else {
        _mint(msg.sender, _balances[msg.sender].div(4));
        if (battle_lottery < 1 && _balances[address(0)] > 0) {
          uint battle_bonus = _balances[address(0)].div(2);
          _balances[address(0)] = 0;
          _maxSupply = _maxSupply.sub(battle_bonus);
          _totalSupply = _totalSupply.sub(battle_bonus);
          _balances[msg.sender] = _balances[msg.sender].add(battle_bonus);
          emit Transfer(address(0), msg.sender, battle_bonus);
        }
      }
    }
    else{
      _transferFrom(msg.sender, recipient, amount);
    }
  }

  function _mint(address account, uint256 amount) internal {
    require(_totalSupply < _maxSupply, "IERC20: all 200 districts have already been minted");
    require(account != address(0), "IERC20: mint to burn address");
    _totalSupply = _totalSupply.add(amount);
    _minted[account] = 1;
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount > 0);
    _balances[account] = _balances[account].sub(amount);
    _balances[address(0)] = _balances[address(0)].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "IERC20: approval to burn address");
    require(spender != address(0), "IERC20: approval from burn address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function () external payable {
    revert();
  }
}