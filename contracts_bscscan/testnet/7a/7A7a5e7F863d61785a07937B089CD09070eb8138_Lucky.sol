/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.6.12;
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	function sub( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
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
	function div( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}
	function mod( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}
abstract contract Context {
	function _msgSender() internal view virtual returns (address ) {
		return msg.sender;
	}
	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}
}
library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);
		(bool success, ) = recipient.call{ value: amount }("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}
	function functionCall(address target, bytes memory data) internal returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}
	function functionCall( address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue( address target, bytes memory data, uint256 value ) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				"Address: low-level call with value failed"
			);
	}
	function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage ) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		return _functionCallWithValue(target, data, value, errorMessage);
	}
	function _functionCallWithValue( address target, bytes memory data, uint256 weiValue, string memory errorMessage ) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) =
			target.call{ value: weiValue }(data);
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}
contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);
	constructor() public {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}
	function owner() public view returns (address) { return _owner; }
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}
	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval( address indexed owner, address indexed spender, uint256 value);
}
contract Lucky is IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;
	mapping(address => uint256) private _balances;
	mapping(address => bool) private _operators;
	mapping(address => mapping(address => uint256)) private _allowances;
	uint256 private _totalSupply;
	string private _name;
	string private _symbol;
	uint8 private _decimals;
	constructor() public {
		_name = "Lucky";
		_symbol = "LUCKY";
		_decimals = 18; 
	}
	function name() public view returns (string memory) {
		return _name;
	}
	function symbol() public view returns (string memory) {
		return _symbol;
	}
	function decimals() public view returns (uint8) {
		return _decimals;
	}
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}
	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}
	function transfer(address recipient, uint256 amount) public virtual override returns (bool)
	{
		_transfer(_msgSender(), recipient, amount);
		return true;
	}
	function allowance(address owner, address spender) public view virtual override returns (uint256)
	{
		return _allowances[owner][spender];
	}
	function approve(address spender, uint256 amount) public virtual override returns (bool)
	{
		_approve(_msgSender(), spender, amount);
		return true;
	}
	function transferFrom( address sender, address recipient, uint256 amount ) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}
	function mint(address account, uint256 amount) public virtual override returns (bool)
	{
		require(
			_operators[_msgSender()] == true,
			"ERC20: caller is not token operator"
		);
		_mint(account, amount);
		return true;
	}
	function burn(address account, uint256 amount) public virtual override returns (bool)
	{ 
		require(
			_operators[_msgSender()] == true,
			"ERC20: caller is not token operator"
		);
		_burn(account, amount);
		return true;
	}
	function addOperator(address account) public virtual override onlyOwner
		returns (bool)
	{
		_operators[account] = true;
		return true;
	}

	function removeOperator(address account) public virtual override onlyOwner returns (bool)
	{
		_operators[account] = false;
		return false;
	}
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
	{
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(
				subtractedValue,
				"ERC20: decreased allowance below zero"
			)
		);
		return true;
	}
	function _transfer( address sender, address recipient, uint256 amount ) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = _balances[sender].sub(
			amount,
			"ERC20: transfer amount exceeds balance"
		);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");
		_beforeTokenTransfer(address(0), account, amount);
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}
	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");
		_beforeTokenTransfer(account, address(0), amount);
		_balances[account] = _balances[account].sub(
			amount,
			"ERC20: burn amount exceeds balance"
		);
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}
	function _approve( address owner, address spender, uint256 amount ) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	function _setupDecimals(uint8 decimals_) internal {
		_decimals = decimals_;
	}
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}