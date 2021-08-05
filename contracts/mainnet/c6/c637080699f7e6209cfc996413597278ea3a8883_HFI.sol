/**
 *Submitted for verification at Etherscan.io on 2020-12-31
*/

//HORNET.FINANCE ERC20 TOKEN CONTRACT
//HTTPS://WWW.HORNET.FINANCE
pragma solidity ^0.6.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes memory) {this; return msg.data;}}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {address msgSender = _msgSender();_owner = msgSender;emit OwnershipTransferred(address(0), msgSender);}
    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {require(_owner == _msgSender(), "Ownable: caller is not the owner");_;}
    function renounceOwnership() public virtual onlyOwner {emit OwnershipTransferred(_owner, address(0));_owner = address(0);}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address");emit OwnershipTransferred(_owner, newOwner);_owner = newOwner;}}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;require(c >= a, "SafeMath: addition overflow");return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage);uint256 c = a - b;return c;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}
    uint256 c = a * b;require(c / a == b, "SafeMath: multiplication overflow");return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b > 0, errorMessage);
    uint256 c = a / b;return c;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;}}
library Address {
    function isContract(address account) internal view returns (bool) {uint256 size;assembly { size := extcodesize(account) }return size > 0;}
    function sendValue(address payable recipient, uint256 amount) internal {require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");require(success, "Address: unable to send value, recipient may have reverted");}
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return _functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {require(address(this).balance >= value, "Address: insufficient balance for call");return _functionCallWithValue(target, data, value, errorMessage);}
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {require(isContract(target), "Address: call to non-contract");(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);if (success) {return returndata;} else {if (returndata.length > 0) {assembly {let returndata_size := mload(returndata)revert(add(32, returndata), returndata_size)}} else {revert(errorMessage);}}}}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);}
interface IUniswapV2Router {
    function WETH() external pure returns (address);}
contract ERC20 is Context, IERC20 {using SafeMath for uint256;using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol) public {_name = name;_symbol = symbol;_decimals = 18;}
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {_transfer(_msgSender(), recipient, amount);return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {_approve(_msgSender(), spender, amount);return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {_transfer(sender, recipient, amount);_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));return true;}
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {require(sender != address(0), "ERC20: transfer from the zero address");require(recipient != address(0), "ERC20: transfer to the zero address");_beforeTokenTransfer(sender, recipient, amount);_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");_balances[recipient] = _balances[recipient].add(amount);emit Transfer(sender, recipient, amount);}
    function _mint(address account, uint256 amount) internal virtual {require(account != address(0), "ERC20: mint to the zero address");_beforeTokenTransfer(address(0), account, amount);_totalSupply = _totalSupply.add(amount);_balances[account] = _balances[account].add(amount);emit Transfer(address(0), account, amount);}
    function _burn(address account, uint256 amount) internal virtual {require(account != address(0), "ERC20: burn from the zero address");_beforeTokenTransfer(account, address(0), amount);_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");_totalSupply = _totalSupply.sub(amount);emit Transfer(account, address(0), amount);}
    function _approve(address owner, address spender, uint256 amount) internal virtual {require(owner != address(0), "ERC20: approve from the zero address");require(spender != address(0), "ERC20: approve to the zero address");_allowances[owner][spender] = amount;emit Approval(owner, spender, amount);}
    function _setupDecimals(uint8 decimals_) internal {_decimals = decimals_;}
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }}
    abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {_burn(_msgSender(), amount);}
    function burnFrom(address account, uint256 amount) public virtual {uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");_approve(account, _msgSender(), decreasedAllowance);_burn(account, amount);}}
contract HFI is ERC20Burnable, Ownable {IUniswapV2Factory internal uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);IUniswapV2Router internal uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapPair;
    mapping (address => bool) internal whitelistedSenders;
    mapping (address => bool) internal whitelistedRecipients;
    constructor() public Ownable()ERC20("Hornet.Finance", "HFI"){_mint(msg.sender, 10000 * 10**18);uniswapPair = createUniswapPairMainnet();setWhitelistedSender(msg.sender, true);setWhitelistedSender(uniswapPair, true);}
    function createUniswapPairMainnet() public virtual returns (address) {require(uniswapPair == address(0), "Hornet: hive already exists");return uniswapFactory.createPair(address(uniswapRouter.WETH()),address(this));}
    function setWhitelistedSender(address _address, bool _whitelisted) public onlyOwner {whitelistedSenders[_address] = _whitelisted;}    
    function _isWhitelistedSender(address _sender) internal view returns (bool) {return whitelistedSenders[_sender];}
    function setWhitelistedRecipient(address _recipient, bool _whitelisted) public onlyOwner {whitelistedRecipients[_recipient] = _whitelisted;}    
    function _isWhitelistedRecipient(address _recipient) internal view returns (bool) {return whitelistedRecipients[_recipient];}    
    function _transfer(address _sender, address _recipient, uint256 _amount) 
    internal override {if (!_isWhitelistedSender(_sender) && !_isWhitelistedRecipient(_recipient)) {uint256 burnAmount = _amount.div(20);super._burn(_sender, burnAmount);_amount = _amount.sub(burnAmount);}super._transfer(_sender, _recipient, _amount);}}