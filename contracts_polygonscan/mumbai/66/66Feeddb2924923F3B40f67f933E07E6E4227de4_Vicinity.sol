// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

abstract contract VicinityAccess is Ownable, AccessControlEnumerable {
	bytes32 internal constant MINTER_ROLE_NAME = "minter";
	bytes32 internal constant AIRDROP_ROLE_NAME = "airdrop";

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}
	
	modifier onlyOwnerOrRole(bytes32 role) {
		if (msg.sender != owner()) {
			_checkRole(role, msg.sender);
		}
		_;
	}
	
	/**
	 * This will throw an exception. You cannot renounce ownership. 
	 * You can only transfer to another address.
	 */
	function renounceOwnership() public override onlyOwner {
		revert("You cannot renounce ownership. You can only transfer to another address.");
	}
	
	/**
	 * Make another account the owner of this contract.
	 * @param newOwner the new owner.
	 */
	function transferOwnership(address newOwner) public virtual override onlyOwner {
		super.transferOwnership(newOwner);
		grantRole(DEFAULT_ADMIN_ROLE, newOwner);
	}
	
	/**
	 * Take the role away from the account. This will throw an exception
	 * if you try to take the admin role (0x00) away from the owner.
	 */ 
	function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
		require(
			role != DEFAULT_ADMIN_ROLE || account != owner(),
			"You cannot revoke admin from the contract owner."
		);
		super.revokeRole(role, account);
	}
   
	function grantRole(bytes32 role, address account) public virtual override onlyOwner onlyRole(getRoleAdmin(role)) {
		require(
			role == DEFAULT_ADMIN_ROLE ,
			"You cannot give admin role to other user."
		);
		super.grantRole(role, account);
	}
	
	/**
	 * Take a role away from yourself. This will throw an exception if you 
	 * are the contract owner and you are trying to renounce the admin role (0x00).
	 */
	function renounceRole(bytes32 role, address account) public virtual override {
		require(
			role != DEFAULT_ADMIN_ROLE || account != owner(),
			"The contract owner cannot renounce admin."
		);
		super.renounceRole(role, account);
	}
}

/**
 * A token for charity NFT auctions.
 */
contract Vicinity is ERC20, VicinityAccess, Pausable {
	using SafeMath for uint256;

	uint256 public airdropcount = 0;
	mapping (address => uint256) private time;
	mapping (address => uint256) private _lockedAmount;
	mapping (address => bool) public isBlackListed;
	
	event DestroyedBlackFunds(address _blackListedUser, uint _balance);
	event AddedBlackList(address _user);
	event RemovedBlackList(address _user);
	
	/**
	 * @dev Deploy the new token contract.
	 * @param name the name of the token.
	 * @param symbol the token symbol.
	 * @param initialSupply the initial supply of tokens, in wei.
	 */
	constructor(
		string memory name, 
		string memory symbol,
		uint256 initialSupply
	) ERC20(name, symbol) {
		if (initialSupply > 0) {
			_mint(msg.sender, initialSupply);
		}
	}
	
	/**
	 * @dev time calculator for locked tokens
	 */ 
	function addLockingTime(address lockingAddress,uint256 lockingTime, uint256 amount) internal returns (bool){
		time[lockingAddress] = block.timestamp + (lockingTime * 1 days);
		_lockedAmount[lockingAddress] = _lockedAmount[lockingAddress].add(amount);
		return true;
	}
	
	/**
	 * @dev check for time based lock
	 * @param _address address to check for locking time
	 * @return time in block format
	 */
	function checkLockingTimeByAddress(address _address) public view returns(uint256){
		if (block.timestamp < time[_address]) {
			return _lockedAmount[_address];
		}
		
		return 0;
	}
	
	/**
	 * @dev return locking status
	 * @param userAddress address of to check
	 * @return locking status in true or false
	 */
	function getLockingStatus(address userAddress) public view returns(bool){
		return block.timestamp < time[userAddress];
	}
	
	/**
	 * @dev  Decrease locking time
	 * @param _affectiveAddress Address of the locked address
	 * @param _decreasedTime Time in days to be affected
	 */
	function decreaseLockingTimeByAddress(address _affectiveAddress, uint _decreasedTime) 
			external whenNotPaused onlyOwnerOrRole(MINTER_ROLE_NAME) returns(bool){
		require(
			_decreasedTime > 0 && time[_affectiveAddress] > block.timestamp, 
			"Please check address status or Incorrect input"
		);
		time[_affectiveAddress] = time[_affectiveAddress] - (_decreasedTime * 1 days);
		return true;
	}
	
	function increaseLockingTimeByAddress(address _affectiveAddress, uint _increasedTime) 
			external whenNotPaused onlyOwnerOrRole(MINTER_ROLE_NAME) returns(bool){
		require(
			_increasedTime > 0 && time[_affectiveAddress] > block.timestamp, 
			"Please check address status or Incorrect input"
		);
		time[_affectiveAddress] = time[_affectiveAddress] + (_increasedTime * 1 days);
		return true;
	}
	
	modifier checkLocking(address _address,uint256 requestedAmount){
		if(block.timestamp < time[_address]){
			require(
				!( balanceOf(_address).sub(_lockedAmount[_address]) < requestedAmount), 
				"Insufficient unlocked balance"
			);
		}
		_;
	}
	
	/* ----------------------------------------------------------------------------
	 * Transfer, allow, mint and burn functions
	 * ----------------------------------------------------------------------------
	 */
	
	/**
	 * @dev Mint some coins.
	 * @param account The account to receive the newly minted coins.
	 * @param amount The number of coins to mint, in wei.
	 */
	function mint(address account, uint256 amount) 
			public whenNotPaused onlyOwnerOrRole(MINTER_ROLE_NAME) {
		super._mint(account, amount);
	}
	
	/**
	 * @dev Burns a specific amount of tokens.
	 * @param amount The amount of token to be burned, in wei.
	 */
	function burn(uint256 amount) public whenNotPaused 
			onlyOwnerOrRole(MINTER_ROLE_NAME) {
		_burn(msg.sender, amount);
	}
	
	/**
	 * @dev Burns a specific amount of tokens.
	 * @param account The account from which to burn the tokens.
	 * @param amount The number of token to be burned, in wei.
	 */
	function burnFrom(address account, uint256 amount) 
			public onlyOwnerOrRole(MINTER_ROLE_NAME) {
		_burn(account, amount);
	}
	
	/**
	 * @dev Transfer token to a specified address.
	 * @param to The address to transfer to.
	 * @param value The amount to be transferred, in wei.
	 */
	function transfer(address to, uint256 value) public whenNotPaused 
			checkLocking(msg.sender,value) override returns (bool) {
		require(!isBlackListed[msg.sender]);
		_transfer(msg.sender, to, value);
		return true;
	}
	
	/**
	 * @dev Transfer tokens from one address to another.
	 * Note that while this function emits an Approval event, this is not required as per the specification,
	 * and other compliant implementations may not emit the event.
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 the amount of tokens to be transferred, in wei
	 */
	function transferFrom(address from, address to, uint256 value) public whenNotPaused 
			checkLocking(msg.sender,value) override returns (bool) {
		require(!isBlackListed[msg.sender]);
		_transfer(from, to, value);
		_approve(
			from, msg.sender, allowance(from, msg.sender).sub(
				value,"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}
	
	/**
	 * @dev Transfer tokens to a specified address (For Only Owner or Minter)
	 * @param to The address to transfer to.
	 * @param value The amount to be transferred, in wei.
	 * @return Transfer status in true or false
	 */
	function transferLockedTokens(address to, uint256 value, uint8 lockingTime) 
			public whenNotPaused onlyOwnerOrRole(MINTER_ROLE_NAME) returns (bool) {
		addLockingTime(to,lockingTime,value);
		_transfer(msg.sender, to, value);
		return true;
	}
	
	/**
	 * @dev withdraw locked tokens only (For Only Owner or Minter)
	 * @param from locked address
	 * @param to address to be transfer tokens
	 * @param value amount of tokens to unlock and transfer, in wei
	 * @return transfer status
	 */
	function GetBackLockedTokens(address from, address to, uint256 value) 
			external whenNotPaused onlyOwnerOrRole(MINTER_ROLE_NAME) returns (bool){
		require(
			(_lockedAmount[from] >= value) && (block.timestamp < time[from]), 
			"Insufficient unlocked balance"
		);
		require(
			from != address(0) && to != address(0), 
			"Invalid address"
		);
		
		_lockedAmount[from] = _lockedAmount[from].sub(value);
		_transfer(from,to,value);
		return true;
	}
	
	/**
	 * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. 
	 * Maximum limit is 200 addresses in one time.
	 * @param _addresses array of address in serial order
	 * @param _amount amount in serial order with respect to address array, in wei
	 */
	function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) 
			public whenNotPaused onlyOwnerOrRole(AIRDROP_ROLE_NAME) returns (bool){
		require(
			_addresses.length == _amount.length,
			"Invalid Array"
		);
		
		uint256 count = _addresses.length;
		for (uint256 i = 0; i < count; i++){
			_transfer(msg.sender, _addresses[i], _amount[i]);
			airdropcount = airdropcount + 1;
		}
		return true;
	}
	
	/**
	 * @dev Locked Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. 
	 Maximum limit is 200 addresses in one time.
	 * @param _addresses array of address in serial order
	 * @param _amount amount in serial order with respect to address array, in wei
	 * @param _lockedTime the number of days to lock the airdrop.
	 */
	function lockedAirdropByOwner(
		address[] memory _addresses, uint256[] memory _amount,uint8[] memory _lockedTime
	) public whenNotPaused onlyOwnerOrRole(AIRDROP_ROLE_NAME) returns (bool){
		require(
			_addresses.length == _amount.length,
			"Invalid amounts Array"
		);
		require(
			_addresses.length == _lockedTime.length,
			"Invalid lockedTime Array"
		);
		
		uint256 count = _addresses.length;
		for (uint256 i = 0; i < count; i++){
			addLockingTime(_addresses[i],_lockedTime[i],_amount[i]);
			_transfer(msg.sender, _addresses[i], _amount[i]);
			airdropcount = airdropcount + 1;
		}
		return true;
	}
	
	function addBlackList (address _evilUser) public onlyOwner {
		isBlackListed[_evilUser] = true;
		emit AddedBlackList(_evilUser);
	}

	function removeBlackList (address _clearedUser) public onlyOwner {
		isBlackListed[_clearedUser] = false;
		emit RemovedBlackList(_clearedUser);
	}

	function destroyBlackFunds (address _blackListedUser) public onlyOwner {
		require(isBlackListed[_blackListedUser]);
		uint dirtyFunds = balanceOf(_blackListedUser);
		_burn(_blackListedUser, dirtyFunds);
		emit  DestroyedBlackFunds(_blackListedUser, dirtyFunds);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	function withdrawn(address payable _to) public onlyOwner returns(bool){
		_transfer(address(this), _to, balanceOf(address(this)));
		return true;    
	}

	function withdrawnTokens(uint256 _amount, address _to, address _tokenContract) public onlyOwner returns(bool){
		IERC20 tokenContract = IERC20(_tokenContract);
		tokenContract.transfer(_to, _amount);
		return true;    
	}

	receive() external payable {}	
}