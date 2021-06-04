/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TokenBase {
	/* Variables */
	uint256 private _totalSupply;
	string  private _name;
	string  private _symbol;
	address private _owner;
	bool    private _paused;
	uint8   private _decimals;
	bool    private _initialized;
	mapping (address => uint256)                      private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;

	/* Modifiers */
	modifier onlyOwner() {
		require( _owner == msg.sender, "Caller is not the owner" );
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
	function initialize(address owner_, uint8 decimals_, string memory name_, string memory symbol_) public returns (bool) {
		require( ! _initialized, "Already initialized" );
		require( owner_ != address(0), "New owner has zero address" );
		_initialized = true;
		_owner       = owner_;
		_decimals    = decimals_;
		_name        = name_;
		_symbol      = symbol_;
		emit Transfer(address(this), address(this), 0);
		emit OwnershipTransferred(address(0), owner_);
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
	function pause() external onlyOwner {
		_pause();
	}
	function unpause() external onlyOwner {
		_unpause();
	}
	function transferOwnership(address newOwner_) external onlyOwner {
		require( newOwner_ != address(0), "New owner has zero address" );
		emit OwnershipTransferred(_owner, newOwner_);
		_owner = newOwner_;
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
	function initialized() external view returns (bool) {
		return _initialized;
	}

	/* Internals */
	function _transfer(address sender_, address recipient_, uint256 amount_) internal whenNotPaused {
		require( sender_ != address(0), "Transfer from the zero address" );
		require( recipient_ != address(0), "Transfer to the zero address" );
		uint256 senderBalance = _balances[sender_];
		require( senderBalance >= amount_, "Transfer amount exceeds balance" );
		unchecked {
			_balances[sender_] = senderBalance - amount_;
		}
		_balances[recipient_] += amount_;
		emit Transfer(sender_, recipient_, amount_);
	}
	function _mint(address account_, uint256 amount_) internal whenNotPaused {
		require( account_ != address(0), "Mint to the zero address" );
		_totalSupply += amount_;
		_balances[account_] += amount_;
		emit Transfer(address(0), account_, amount_);
	}
	function _burn(address account_, uint256 amount_) internal whenNotPaused {
		require( account_ != address(0), "Burn from the zero address" );
		uint256 accountBalance = _balances[account_];
		require( accountBalance >= amount_, "Burn amount exceeds balance" );
		unchecked {
			_balances[account_] = accountBalance - amount_;
		}
		_totalSupply -= amount_;
		emit Transfer(account_, address(0), amount_);
	}
	function _approve(address owner_, address spender_, uint256 amount_) internal whenNotPaused {
		require( owner_ != address(0), "Approve from the zero address" );
		require( spender_ != address(0), "Approve to the zero address" );
		_allowances[owner_][spender_] = amount_;
		emit Approval(owner_, spender_, amount_);
	}
	function _pause() internal whenNotPaused {
		_paused = true;
		emit Paused();
	}
	function _unpause() internal whenPaused {
		_paused = false;
		emit Unpaused();
	}

	/* Events */
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event Paused();
	event Unpaused();
}

contract WrappedHydra is TokenBase {
	/* Variables */
	address internal _signer;
	mapping (bytes32 => bool) internal _usedMessages;

	/* Externals */
	function initialize(address owner_, address signer_) external returns (bool) {
		require( signer_ != address(0), "Signer has zero address" );
		_signer = signer_;
		return super.initialize(owner_, 8, "Wrapped Hydra", "WHYD");
	}
	function mintWrappedHydra(bytes32 secret_, uint256 amount_, uint8 v_, bytes32 r_, bytes32 s_) external {
		checkSignature(
			keccak256(abi.encodePacked( msg.sender, secret_, amount_ )),
			v_,
			r_,
			s_
		);
		_mint(msg.sender, amount_);
		emit BridgedIn(msg.sender, amount_);
	}
	function burnWrappedHydra(bytes32 hydAddress_, bytes32 hydTXID_, uint256 amount_, uint8 v_, bytes32 r_, bytes32 s_) external {
		checkSignature(
			keccak256(abi.encodePacked( hydAddress_, hydTXID_, amount_ )),
			v_,
			r_,
			s_
		);
		_burn(msg.sender, amount_);
		emit BridgedOut(msg.sender, amount_);
	}
	function changeSigner(address newSigner_) external onlyOwner {
		require( newSigner_ != address(0), "Signer has zero address" );
		_signer = newSigner_;
		emit NewSigner(_signer);
	}

	/* Constants */
	function signer() public view returns (address) {
		return _signer;
	}

	/* Internals */
	function checkSignature(bytes32 messageHash_, uint8 v_, bytes32 r_, bytes32 s_) internal {
		require( uint256(s_)<=0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid signature s value" );
		require( v_ == 27 || v_ == 28, "Invalid signature v value" );
		require( ! _usedMessages[messageHash_], "Signature already used" );
		address signerAddress = ecrecover(messageHash_, v_, r_, s_);
		require( signerAddress == _signer, "Signature verification failed" );
		_usedMessages[messageHash_] = true;
	}

	/* Events */
	event BridgedIn(address indexed addr, uint256 indexed value);
	event BridgedOut(address indexed addr, uint256 indexed value);
	event NewSigner(address indexed addr);
}