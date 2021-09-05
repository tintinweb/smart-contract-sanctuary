/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract WrappedILK {
	/* Variables */
	uint256 private _totalSupply;
	address private _owner;
	address private _admin;
	bool    private _paused;
	string  private _name;
	string  private _symbol;
	uint8   private _decimals;
	mapping (address => uint256)                      private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;

	/* Modifiers */
	modifier onlyOwner() {
		require( _owner == msg.sender, "Caller is not the owner" );
		_;
	}
	modifier onlyAdmin() {
		require( _admin == msg.sender, "Caller is not admin" );
		_;
	}
	modifier whenNotPaused() {
		require( ! _paused, "Paused" );
		_;
	}
	modifier whenPaused() {
		require( _paused, "Not paused" );
		_;
	}

	/* Externals */
	function initialize(address owner_, address admin_, bool isLibrary) public returns (bool) {
		require( owner_ != address(0), "New owner has zero address" );
		require( admin_ != address(0), "Admin has zero address" );
		_owner    = owner_;
		_admin    = admin_;
		_name     = "Wrapped Inlock token";
		_symbol   = "WILK";
		_decimals = 8;
		if ( ! isLibrary ) {
			emit Transfer(address(this), address(this), 0);
			emit OwnershipTransferred(address(0), owner_);
			emit NewAdmin(address(0), admin_);
		}
		return true;
	}
	function transfer(address recipient_, uint256 amount_) external returns (bool) {
		_transfer(msg.sender, recipient_, amount_);
		return true;
	}
	function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool) {
		_transfer(sender_, recipient_, amount_);
		uint256 currentAllowance = _allowances[sender_][msg.sender];
		require( currentAllowance >= amount_, "Transfer amount exceeds allowance" );
		unchecked {
			_approve(sender_, msg.sender, currentAllowance - amount_);
		}
		return true;
	}
	function approve(address spender_, uint256 amount_) external returns (bool) {
		_approve(msg.sender, spender_, amount_);
		return true;
	}
	function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool) {
		_approve(msg.sender, spender_, _allowances[msg.sender][spender_] + addedValue_);
		return true;
	}
	function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool) {
		uint256 currentAllowance = _allowances[msg.sender][spender_];
		require( currentAllowance >= subtractedValue_, "Decreased allowance below zero" );
		unchecked {
			_approve(msg.sender, spender_, currentAllowance - subtractedValue_);
		}
		return true;
	}
	function pause() external whenNotPaused onlyOwner {
		_paused = true;
		emit Paused();
	}
	function unpause() external whenPaused onlyOwner {
		_paused = false;
		emit Unpaused();
	}
	function transferOwnership(address newOwner_) external onlyOwner {
		require( newOwner_ != address(0), "New owner has zero address" );
		emit OwnershipTransferred(_owner, newOwner_);
		_owner = newOwner_;
	}
	function changeAdmin(address newAdmin_) external onlyOwner {
		require( newAdmin_ != address(0), "Admin has zero address" );
		emit NewAdmin(_admin, newAdmin_);
		_admin = newAdmin_;
	}
	function mint(address to_, uint256 amount_) external onlyAdmin whenNotPaused {
		require( to_ != address(0), "Mint to the zero address" );
		_totalSupply += amount_;
		_balances[to_] += amount_;
		emit Transfer(address(0), to_, amount_);
	}
	function burn(address from_, uint256 amount_) external onlyAdmin whenNotPaused {
		require( from_ != address(0), "Burn from the zero address" );
		uint256 accountBalance = _balances[from_];
		require( accountBalance >= amount_, "Burn amount exceeds balance" );
		unchecked {
			_balances[from_] = accountBalance - amount_;
		}
		_totalSupply -= amount_;
		emit Transfer(from_, address(0), amount_);
	}

	/* Constants */
	function name() external view returns (string memory) {
		return _name;
	}
	function symbol() external view returns (string memory) {
		return _symbol;
	}
	function decimals() external view returns (uint8) {
		return _decimals;
	}
	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}
	function balanceOf(address account_) external view returns (uint256) {
		return _balances[account_];
	}
	function allowance(address owner_, address spender_) external view returns (uint256) {
		return _allowances[owner_][spender_];
	}
	function paused() external view returns (bool) {
		return _paused;
	}
	function owner() external view returns (address) {
		return _owner;
	}
	function admin() public view returns (address) {
		return _admin;
	}

	/* Internals */
	function _transfer(address sender_, address recipient_, uint256 amount_) internal whenNotPaused {
		require( sender_ != address(0), "Transfer from the zero address" );
		require( recipient_ != address(0), "Transfer to the zero address" );
		require( sender_ != recipient_, "Transfer to himself" );
		uint256 senderBalance = _balances[sender_];
		require( senderBalance >= amount_, "Transfer amount exceeds balance" );
		unchecked {
			_balances[sender_] = senderBalance - amount_;
		}
		_balances[recipient_] += amount_;
		emit Transfer(sender_, recipient_, amount_);
	}
	function _approve(address owner_, address spender_, uint256 amount_) internal whenNotPaused {
		require( owner_ != address(0), "Approve from the zero address" );
		require( spender_ != address(0), "Approve to the zero address" );
		_allowances[owner_][spender_] = amount_;
		emit Approval(owner_, spender_, amount_);
	}

	/* Events */
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event NewAdmin(address indexed previousAdmin, address indexed newAdmin);
	event Paused();
	event Unpaused();
}