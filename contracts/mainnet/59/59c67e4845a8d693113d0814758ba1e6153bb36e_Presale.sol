/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ERC20Interface {
		function totalSupply() external view returns (uint256);
		function balanceOf(address tokenOwner) external view returns (uint balance);
		function allowance(address tokenOwner, address spender) external view returns (uint remaining);
		function transfer(address to, uint tokens) external returns (bool success);
		function approve(address spender, uint tokens) external returns (bool success);
		function transferFrom(address from, address to, uint tokens) external returns (bool success);

		event Transfer(address indexed from, address indexed to, uint tokens);
		event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Context {

	function _msgSender() internal view returns (address payable) {
		return payable(msg.sender);
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

contract ERC20 is Context{
	using SafeMath for uint256;

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	
	mapping (address => uint256) public _balances;

	mapping (address => mapping (address => uint256)) public _allowances;
	

	uint256 public totalSupply ;
	uint8 public decimals = 18;
	string public symbol;
	string public name;

	constructor (string memory _name, string memory _symbol, uint _totalSupply){
        name = _name;
        symbol = _symbol;
		totalSupply = _totalSupply;
    }
	
	function balanceOf(address account) public view returns (uint256) {
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
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function burn(uint256 amount) external {
		_burn(msg.sender,amount);
	}

	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: mint to the zero address");

		totalSupply = totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "ERC20: burn from the zero address");

		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		totalSupply = totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
	}

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor (){
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

contract Presale is Ownable, ERC20{
	
	ERC20Interface public USDT;

	uint USDTPrice;
	uint ETHPrice;

	uint presaleStartTime;
	uint presaleEndTime;

	bool public isExecutable;

	event Execute (address indexed from,uint256 indexed amount);

	constructor(address USDTAddress, uint256 _USDTPrice, uint256 _ETHPrice) ERC20("ICICB Voucher","VICICB",0){
		USDT = ERC20Interface(USDTAddress);
		USDTPrice = _USDTPrice;
		ETHPrice = _ETHPrice;
		presaleStartTime = block.timestamp;
		presaleEndTime = presaleStartTime + 30 days;
	}

	/* ------------ start to presale voucher ------------- */
	function setPresaleStartTime (uint _presaleStartTime) external onlyOwner {
		presaleStartTime = _presaleStartTime;
	}

	/* ------------ set endtime of presale voucher ------------- */
	function setPresaleEndTime (uint _presaleEndTime) external onlyOwner {
		presaleEndTime = _presaleEndTime;
	}

	/* ------------ start to execute voucher ------------- */
	function setExecutable (bool _isExecutable) external onlyOwner {
		isExecutable = _isExecutable;
	}

	function setTokenPrice(uint256 _USDTPrice, uint256 _ETHPrice) external onlyOwner {
		USDTPrice = _USDTPrice;
		ETHPrice = _ETHPrice;
	}

	function depositUSDT(uint256 amount, address recipient) external {
		require(presaleStartTime < block.timestamp && presaleEndTime >block.timestamp ,"presale Ended");
		USDT.transferFrom(msg.sender,address(this),amount);

		uint tokenAmount = amount*(USDTPrice);
		_balances[recipient] += tokenAmount;
		totalSupply += tokenAmount;
		emit Transfer(address(0),recipient,tokenAmount);
	}

	function depositETH(address recipient) public payable {
		require(presaleStartTime < block.timestamp && presaleEndTime >block.timestamp ,"presale Ended");
		payable(owner()).transfer(msg.value);
		uint tokenAmount = msg.value*ETHPrice;

		_balances[recipient] += tokenAmount;
		totalSupply += tokenAmount;
		emit Transfer(address(0),recipient,tokenAmount);
	}

	function execute(uint amount) public {
		require(_balances[msg.sender] >= amount && isExecutable,"execute is not available");
		_balances[msg.sender] -= amount;
		
		emit Execute(msg.sender, amount);
	}

	// claim tokens that sent by accidentally
	function claimToken(address token,address to,uint256 amount) external onlyOwner {
		ERC20Interface(token).transfer(to,amount);
	}

	function claimETH(address to, uint256 amount) external onlyOwner {
		payable(to).transfer(amount);
	}

	fallback() external payable {
		depositETH(msg.sender);
	}

	receive() external payable {
        depositETH(msg.sender);
    }
}