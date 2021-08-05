// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./SafeMath.sol";

import "./ITorro.sol";
import "./ITorroFactory.sol";

/// @title ERC-20 Torro governing token.
/// @notice Contract for ERC-20 governing token.
/// @author ORayskiy - @robitnik_TorroDao
contract Torro is ITorro, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Structs.

  /// @notice structure to hold holder's information.
  struct Holder {
    uint256 balance;
    uint256 staked;
    mapping(address => uint256) allowances;
    mapping(uint256 => uint256) stakeLock;
    uint256 locked;
  }

  // Private data.

  uint8 constant private _decimals = 18;

  string private _name;
  string private _symbol;
  uint256 private _totalSupply;
  address private _dao;
  address private _factory;
  bool private _isMain;

  mapping(address => Holder) private _holders;
  EnumerableSet.AddressSet private _holderAddresses;

  // Events.

  /// @notice Event for dispatching when token transfer occurs.
  /// @param from address of tokens' sender.
  /// @param to address of tokens' reciever.
  /// @param amount amount of tokens sent.
	event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice Event for dispatching when tokens allowance has been approved.
  /// @param owner address of tokens' owner.
  /// @param spender address of tokens; spender.
  /// @param value amount of tokens approved for use.
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /// @notice Event for dispatching when tokens have been staked.
  /// @param owner address of tokens' owner that have been staked.
  /// @param amount amount of tokens that have been staked.
	event Stake(address indexed owner, uint256 amount);

  /// @notice Event for dispatching when tokens have been unstaked.
  /// @param owner address of tokens' owner that have been unstaked.
  /// @param amount amount of tokens that have been unstaked.
	event Unstake(address indexed owner, uint256 amount);
  
  /// @notice Event for dispatching when benefits have been added.
  event AddBenefits();

  // Constructor.

  constructor() public {
    __Ownable_init();

    _name = "Torro DAO Token";
    _symbol = "TORRO";
    _totalSupply = 1e23;
    _dao = address(0x0);
    _factory = address(0x0);
    _isMain = true;

    _holders[msg.sender].balance = _totalSupply;
    _holderAddresses.add(msg.sender);

	  emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  /// @notice Initializes governing token.
  /// @param dao_ address of cloned DAO.
  /// @param factory_ address of factory.
  /// @param supply_ total supply of tokens.
  function initializeCustom(address dao_, address factory_, uint256 supply_) public override initializer {
    __Ownable_init();

    _name = "Torro DAO Pool Token";
    _symbol = "TORRO_POOL";
    _totalSupply = supply_;
    _dao = dao_;
    _factory = factory_;
    _isMain = false;

    _holders[dao_].balance = _totalSupply;
    _holderAddresses.add(dao_);

    emit Transfer(address(0x0), dao_, _totalSupply);
  }

  // Public calls.

  /// @notice Token's name.
  /// @return string name of the token.
  function name() public override view returns (string memory) {
    return _name;
  }

  /// @notice Token's symbol.
  /// @return string symbol of the token.
  function symbol() public override view returns (string memory) {
    return _symbol;
  }

  /// @notice Token's decimals.
  /// @return uint8 demials of the token.
  function decimals() public override pure returns (uint8) {
    return _decimals;
  }

  /// @notice Token's total supply.
  /// @return uint256 total supply of the token.
	function totalSupply() public override view returns (uint256) {
		return _totalSupply;
	}

  /// @notice Count of token holders.
  /// @return uint256 number of token holders.
  function holdersCount() public override view returns (uint256) {
    return _holderAddresses.length();
  }

  /// @notice All token holders.
  /// @return array of addresses of token holders.
  function holders() public override view returns (address[] memory) {
    uint256 length = _holderAddresses.length();
    address[] memory holderAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      holderAddresses[i] = _holderAddresses.at(i);
    }
    return holderAddresses;
  }

  /// @notice Available balance for address.
  /// @param sender_ address to get available balance for.
  /// @return uint256 amount of tokens available for given address.
  function balanceOf(address sender_) public override view returns (uint256) {
    return _holders[sender_].balance;
  }

  /// @notice Staked balance for address.
  /// @param sender_ address to get staked balance for.
  /// @return uint256 amount of staked tokens for given address.
  function stakedOf(address sender_) public override view returns (uint256) {
    return _holders[sender_].staked;
  }

  /// @notice Total balance for address = available + staked.
  /// @param sender_ address to get total balance for.
  /// @return uint256 total amount of tokens for given address.
  function totalOf(address sender_) public override view returns (uint256) {
    return _holders[sender_].balance.add(_holders[sender_].staked);
  }

  /// @notice Locked staked balance for address
  /// @param sender_ address to get locked staked balance for.
  /// @return uint256 amount of locked staked tokens for given address.
  function lockedOf(address sender_) public override view returns (uint256) {
    return _holders[sender_].locked;
  }

  /// @notice Spending allowance.
  /// @param owner_ token owner address.
  /// @param spender_ token spender address.
  /// @return uint256 amount of owner's tokens that spender can use.
  function allowance(address owner_, address spender_) public override view returns (uint256) {
    return _holders[owner_].allowances[spender_];
  }

  /// @notice Unstaked supply of token.
  /// @return uint256 amount of tokens in circulation that are not staked.
  function unstakedSupply() public override view returns (uint256) {
    uint256 supply = 0;
    for (uint256 i = 0; i < _holderAddresses.length(); i++) {
      supply = supply.add(_holders[_holderAddresses.at(i)].balance);
    }
    return supply;
  }

  /// @notice Staked supply of token.
  /// @return uint256 amount of tokens in circulation that are staked.
  function stakedSupply() public override view returns (uint256) {
    uint256 supply = 0;
    for (uint256 i = 0; i < _holderAddresses.length(); i++) {
      supply = supply.add(_holders[_holderAddresses.at(i)].staked);
    }
    return supply;
  }

  // Public transactions.

  /// @notice Transfer tokens to recipient.
  /// @param recipient_ address of tokens' recipient.
  /// @param amount_ amount of tokens to transfer.
  /// @return bool true if successful.
  function transfer(address recipient_, uint256 amount_) public override returns (bool) {
    _transfer(msg.sender, recipient_, amount_);
    return true;
  }

  /// @notice Approve spender to spend an allowance.
  /// @param spender_ address that will be allowed to spend specified amount of tokens.
  /// @param amount_ amount of tokens that spender can spend.
  /// @return bool true if successful.
  function approve(address spender_, uint256 amount_) public override returns (bool) {
    _approve(msg.sender, spender_, amount_);
    return true;
  }

  /// @notice Approves DAO to spend tokens.
  /// @param owner_ address whose tokens DAO can spend.
  /// @param amount_ amount of tokens that DAO can spend.
  /// @return bool true if successful.
  function approveDao(address owner_, uint256 amount_) public override returns (bool) {
    require(msg.sender == _dao);
    _approve(owner_, _dao, amount_);
    return true;
  }

  /// @notice Locks account's staked tokens.
  /// @param owner_ address whose tokens should be locked.
  /// @param amount_ amount of tokens to lock.
  /// @param id_ lock id.
  function lockStakesDao(address owner_, uint256 amount_, uint256 id_) public override {
    require(msg.sender == _dao);
    Holder storage holder = _holders[owner_];
    require(holder.staked >= amount_);
    holder.stakeLock[id_] = amount_;
    holder.locked = holder.locked.add(amount_);
  }

  /// @notice Unlocks account's staked tokens.
  /// @param owner_ address whose tokens should be unlocked.
  /// @param id_ unlock id.
  function unlockStakesDao(address owner_, uint256 id_) public override {
    require(msg.sender == _dao);
    Holder storage holder = _holders[owner_];
    uint256 amount = holder.stakeLock[id_];
    if (amount > 0) {
      holder.locked = holder.locked.sub(amount);
    }
    delete holder.stakeLock[id_];
  }

  /// @notice Transfers tokens from owner to recipient by approved spender.
  /// @param owner_ address of tokens' owner whose tokens will be spent.
  /// @param recipient_ address of recipient that will recieve tokens.
  /// @param amount_ amount of tokens to be spent.
  /// @return bool true if successful.
  function transferFrom(address owner_, address recipient_, uint256 amount_) public override returns (bool) {
    require(_holders[owner_].allowances[msg.sender] >= amount_);
    _transfer(owner_, recipient_, amount_);
    _approve(owner_, msg.sender, _holders[owner_].allowances[msg.sender].sub(amount_));
    return true;
  }

  /// @notice Increases allowance for given spender.
  /// @param spender_ spender to increase allowance for.
  /// @param addedValue_ extra amount that spender can spend.
  /// @return bool true if successful.
  function increaseAllowance(address spender_, uint256 addedValue_) public override returns (bool) {
    _approve(msg.sender, spender_, _holders[msg.sender].allowances[spender_].add(addedValue_));
    return true;
  }

  /// @notice Decreases allowance for given spender.
  /// @param spender_ spender to decrease allowance for.
  /// @param subtractedValue_ removed amount that spender can spend.
  /// @return bool true if successful.
  function decreaseAllowance(address spender_, uint256 subtractedValue_) public override returns (bool) {
    _approve(msg.sender, spender_, _holders[msg.sender].allowances[spender_].sub(subtractedValue_));
    return true;
  }

  /// @notice Stake tokens.
  /// @param amount_ amount of tokens to be staked.
  /// @return bool true if successful.
	function stake(uint256 amount_) public override returns (bool) {
    require(amount_ >= 1e18);
    require(balanceOf(msg.sender) >= amount_);
    Holder storage holder = _holders[msg.sender];
    holder.balance = holder.balance.sub(amount_);
    holder.staked = holder.staked.add(amount_);
		emit Transfer(msg.sender, address(this), amount_);
		emit Stake(msg.sender, amount_);
    return true;
	}

  /// @notice Unstake tokens.
  /// @param amount_ amount of tokens to be unstaked.
  /// @return bool true if successful.
  function unstake(uint256 amount_) public override returns (bool) {
    require(stakedOf(msg.sender) >= amount_);
    Holder storage holder = _holders[msg.sender];
    require(holder.staked.sub(holder.locked) >= amount_);

    uint256 amount;
    if (_isMain) {
      uint256 burn = amount_ / 200;
      uint256 tempTotalSupply = _totalSupply.sub(burn);
      if (tempTotalSupply < 1e22) {
        burn = _totalSupply.sub(tempTotalSupply);
      }
      if (burn > 0) {
        amount = amount_.sub(burn);
        _totalSupply = _totalSupply.sub(burn);
        emit Transfer(msg.sender, address(0x0), burn);
      }
    } else {
      amount = amount_;
    }
    holder.staked = holder.staked.sub(amount_);
    holder.balance = holder.balance.add(amount);
    emit Transfer(address(this), msg.sender, amount);
    emit Unstake(msg.sender, amount_);
    return true;
  }

  /// @notice Functionality for DAO to add benefits for all stakers.
  /// @param amount_ amount of wei to be shared among stakers.
  function addBenefits(uint256 amount_) public override {
    require(msg.sender == _dao || ITorroFactory(_factory).isDao(msg.sender));
    for (uint256 i = 0; i < _holderAddresses.length(); i++) {
      address holder = _holderAddresses.at(i);
      uint256 staked = stakedOf(holder);
      if (staked > 0) {
        uint256 amount = staked.mul(amount_) / stakedSupply();
        if (amount > 0) {
          ITorroFactory(_factory).addBenefits(holder, amount);
        }
      }
    }

    // Emit event that benefits have been added for token.
    emit AddBenefits();
  }
  
  /// @notice Functionality to burn tokens.
  /// @param amount_ amount of tokens to burn.
  function burn(uint256 amount_) public override {
    Holder storage burner = _holders[msg.sender];
    require(burner.balance >= amount_);
    burner.balance = burner.balance.sub(amount_);
    _totalSupply = _totalSupply.sub(amount_);

    emit Transfer(msg.sender, address(0x0), amount_);
  }

  // Private transactions.

  /// @notice Main functionality for token trnasfer.
  /// @param sender_ address that sends tokens.
  /// @param recipient_ address that will recieve tokens.
  /// @param amount_ amount of tokens to be sent.
  function _transfer(address sender_, address recipient_, uint256 amount_) private {
    require(sender_ != address(0x0));
    require(recipient_ != address(0x0));

    Holder storage sender = _holders[sender_];
    Holder storage recipient = _holders[recipient_];

    require(sender.balance >= amount_);

    if (_holderAddresses.contains(recipient_)) {
      recipient.balance = recipient.balance.add(amount_);
    } else {
      recipient.balance = amount_;
      _holderAddresses.add(recipient_);
    }
    sender.balance = sender.balance.sub(amount_);
    if (totalOf(sender_) == 0) {
      _holderAddresses.remove(sender_);
    }

    emit Transfer(sender_, recipient_, amount_);
  }

  /// @notice Main functionality for token allowance approval.
  /// @param owner_ address whose tokens will be spent.
  /// @param spender_ address that will be able to spend tokens.
  /// @param amount_ amount of tokens that can be spent.
  function _approve(address owner_, address spender_, uint256 amount_) private {
    require(owner_ != address(0x0));
    require(spender_ != address(0x0));

    _holders[owner_].allowances[spender_] = amount_;

    emit Approval(owner_, spender_, amount_);
  }

  // Owner transactions.

  /// @notice Sets DAO and Factory addresses.
  /// @param dao_ DAO address that this token governs.
  /// @param factory_ Factory address.
  function setDaoFactoryAddresses(address dao_, address factory_) public override onlyOwner {
    _dao = dao_;
    _factory = factory_;
  }
}
