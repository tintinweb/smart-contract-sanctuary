// File: contracts/SafeMath.sol

pragma solidity ^0.4.26;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/Ownable.sol

pragma solidity ^0.4.26;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Gather_coin.sol

pragma solidity ^0.4.26;




/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 /**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event Mintai(address indexed owner, address indexed msgSender, uint256 msgSenderBalance, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  mapping(address=>uint256) mintPermissions;

  uint256 public maxMintLimit;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(checkMintPermission(msg.sender));
    _;
  }

  function checkMintPermission(address _minter) private view returns (bool) {
    if (_minter == owner) {
      return true;
    }

    return mintPermissions[_minter] > 0;

  }

  function setMinter(address _minter, uint256 _amount) public onlyOwner {
    require(_minter != owner);
    mintPermissions[_minter] = _amount;
  }

  /**
   * @dev Function to mint tokens. Delegates minting to internal function
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    return mintInternal(_to, _amount);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mintInternal(address _to, uint256 _amount) internal returns (bool) {
    if (msg.sender != owner) {
      mintPermissions[msg.sender] = mintPermissions[msg.sender].sub(_amount);
    }

    totalSupply_ = totalSupply_.add(_amount);
    require(totalSupply_ <= maxMintLimit);

    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function mintAllowed(address _minter) public view returns (uint256) {
    return mintPermissions[_minter];
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract GatherToken is MintableToken {

  string public constant name = "Gather";
  string public constant symbol = "GTH";
  uint32 public constant decimals = 18;

  bool public transferPaused = true;

  constructor() public {
    maxMintLimit = 400000000 * (10 ** uint(decimals));
  }

  function unpauseTransfer() public onlyOwner {
    transferPaused = false;
  }

  function pauseTransfer() public onlyOwner {
    transferPaused = true;
  }

  // The modifier checks, if address can send tokens or not at current contract state.
  modifier tranferable() {
    require(!transferPaused, "Gath3r: Token transfer is pauses");
    _;
  }

  function transferFrom(address _from, address _to, uint256 _value) public tranferable returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public tranferable returns (bool) {
    return super.transfer(_to, _value);
  }
}

// File: contracts/VestingPool.sol

pragma solidity ^0.4.26;





contract VestingPool is Ownable {
  using SafeMath for uint256;

  // The token being vested
  GatherToken public token;

  // Category name identifiers
  bytes32 public privateCategory = keccak256("privateCategory");
  bytes32 public platformCategory = keccak256("platformCategory");
  bytes32 public seedCategory = keccak256("seedCategory");
  bytes32 public foundationCategory = keccak256("foundationCategory");
  bytes32 public marketingCategory = keccak256("marketingCategory");
  bytes32 public teamCategory = keccak256("teamCategory");
  bytes32 public advisorCategory = keccak256("advisorCategory");

  bool public isVestingStarted;
  uint256 public vestingStartDate;

  struct vestingInfo {
    uint256 limit;
    uint256 released;
    uint256[] scheme;
    mapping(address => bool) adminEmergencyFirstApprove;
    mapping(address => bool) adminEmergencySecondApprove;
    bool multiownedEmergencyFirstApprove;
    bool multiownedEmergencySecondApprove;
    uint256 initEmergencyDate;
  }

  mapping(bytes32 => vestingInfo) public vesting;

  uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint32 private constant SECONDS_PER_MONTH = SECONDS_PER_DAY * 30;

  address public admin1address;
  address public admin2address;

  event Withdraw(address _to, uint256 _amount);


  constructor(address _token) public {
    require(_token != address(0), "Gath3r: Token address must be set for vesting");

    token = GatherToken(_token);

    // Setup vesting data for each category
    _initVestingData();
  }

  modifier isNotStarted() {
    require(!isVestingStarted, "Gath3r: Vesting is already started");
    _;
  }

  modifier isStarted() {
    require(isVestingStarted, "Gath3r: Vesting is not started yet");
    _;
  }

  modifier approvedByAdmins(bytes32 _category) {
    require(vesting[_category].adminEmergencyFirstApprove[admin1address], "Gath3r: Emergency transfer must be approved by Admin 1");
    require(vesting[_category].adminEmergencyFirstApprove[admin2address], "Gath3r: Emergency transfer must be approved by Admin 2");
    require(vesting[_category].adminEmergencySecondApprove[admin1address], "Gath3r: Emergency transfer must be approved twice by Admin 1");
    require(vesting[_category].adminEmergencySecondApprove[admin2address], "Gath3r: Emergency transfer must be approved twice by Admin 2");
    _;
  }

  modifier approvedByMultiowned(bytes32 _category) {
    require(vesting[_category].multiownedEmergencyFirstApprove, "Gath3r: Emergency transfer must be approved by Multiowned");
    require(vesting[_category].multiownedEmergencySecondApprove, "Gath3r: Emergency transfer must be approved twice by Multiowned");
    _;
  }

  function startVesting() public onlyOwner isNotStarted {
    vestingStartDate = now;
    isVestingStarted = true;
  }

  // Two Admins for emergency transfer
  function addAdmin1address(address _admin) public onlyOwner {
    require(_admin != address(0), "Gath3r: Admin 1 address must be exist for emergency transfer");
    _resetAllAdminApprovals(_admin);
    admin1address = _admin;
  }

  function addAdmin2address(address _admin) public onlyOwner {
    require(_admin != address(0), "Gath3r: Admin 2 address must be exist for emergency transfer");
    _resetAllAdminApprovals(_admin);
    admin2address = _admin;
  }

  function multipleWithdraw(address[] _addresses, uint256[] _amounts, bytes32 _category) public onlyOwner isStarted {
    require(_addresses.length == _amounts.length, "Gath3r: Amount of adddresses must be equal withdrawal amounts length");

    uint256 withdrawalAmount;
    uint256 availableAmount = getAvailableAmountFor(_category);
    for(uint i = 0; i < _amounts.length; i++) {
      withdrawalAmount = withdrawalAmount.add(_amounts[i]);
    }
    require(withdrawalAmount <= availableAmount, "Gath3r: Withdraw amount more than available limit");

    for(i = 0; i < _addresses.length; i++) {
      _withdraw(_addresses[i], _amounts[i], _category);
    }
  }

  function getAvailableAmountFor(bytes32 _category) public view returns (uint256) {
    uint256 currentMonth = now.sub(vestingStartDate).div(SECONDS_PER_MONTH);
    uint256 totalUnlockedAmount;

    for(uint8 i = 0; i <= currentMonth; i++ ) {
      totalUnlockedAmount = totalUnlockedAmount.add(vesting[_category].scheme[i]);
    }

    return totalUnlockedAmount.sub(vesting[_category].released);
  }

  function firstAdminEmergencyApproveFor(bytes32 _category, address _admin) public onlyOwner {
    require(_admin == admin1address || _admin == admin2address, "Gath3r: Approve for emergency address must be from admin address");
    require(!vesting[_category].adminEmergencyFirstApprove[_admin]);

    if (vesting[_category].initEmergencyDate == 0) {
      vesting[_category].initEmergencyDate = now;
    }
    vesting[_category].adminEmergencyFirstApprove[_admin] = true;
  }

  function secondAdminEmergencyApproveFor(bytes32 _category, address _admin) public onlyOwner {
    require(_admin == admin1address || _admin == admin2address, "Gath3r: Approve for emergency address must be from admin address");
    require(vesting[_category].adminEmergencyFirstApprove[_admin]);
    require(now.sub(vesting[_category].initEmergencyDate) > SECONDS_PER_DAY);

    vesting[_category].adminEmergencySecondApprove[_admin] = true;
  }

  function firstMultiownedEmergencyApproveFor(bytes32 _category) public onlyOwner {
    require(!vesting[_category].multiownedEmergencyFirstApprove);

    if (vesting[_category].initEmergencyDate == 0) {
      vesting[_category].initEmergencyDate = now;
    }
    vesting[_category].multiownedEmergencyFirstApprove = true;
  }

  function secondMultiownedEmergencyApproveFor(bytes32 _category) public onlyOwner {
    require(vesting[_category].multiownedEmergencyFirstApprove, "Gath3r: Second multiowned approval must be after fisrt multiowned approval");
    require(now.sub(vesting[_category].initEmergencyDate) > SECONDS_PER_DAY);

    vesting[_category].multiownedEmergencySecondApprove = true;
  }

  function emergencyTransferFor(bytes32 _category, address _to) public onlyOwner approvedByAdmins(_category) approvedByMultiowned(_category) {
    require(_to != address(0), "Gath3r: Address must be transmit for emergency transfer");
    uint256 limit = vesting[_category].limit;
    uint256 released = vesting[_category].released;
    uint256 availableAmount = limit.sub(released);
    _withdraw(_to, availableAmount, _category);
  }

  function _withdraw(address _beneficiary, uint256 _amount, bytes32 _category) internal {
    token.transfer(_beneficiary, _amount);
    vesting[_category].released = vesting[_category].released.add(_amount);

    emit Withdraw(_beneficiary, _amount);
  }

  function _resetAllAdminApprovals(address _admin) internal {
    vesting[seedCategory].adminEmergencyFirstApprove[_admin] = false;
    vesting[seedCategory].adminEmergencySecondApprove[_admin] = false;
    vesting[foundationCategory].adminEmergencyFirstApprove[_admin] = false;
    vesting[foundationCategory].adminEmergencySecondApprove[_admin] = false;
    vesting[marketingCategory].adminEmergencyFirstApprove[_admin] = false;
    vesting[marketingCategory].adminEmergencySecondApprove[_admin] = false;
    vesting[teamCategory].adminEmergencyFirstApprove[_admin] = false;
    vesting[teamCategory].adminEmergencySecondApprove[_admin] = false;
    vesting[advisorCategory].adminEmergencyFirstApprove[_admin] = false;
    vesting[advisorCategory].adminEmergencySecondApprove[_admin] = false;
  }

  function _amountWithPrecision(uint256 _amount) internal view returns (uint256) {
    return _amount.mul(10 ** uint(token.decimals()));
  }

  // Vesting data for public sale category
  function _initVestingData() internal {
    // Vesting data for private sale category
    vesting[privateCategory].limit = _expandToDecimals(20000000);
    vesting[privateCategory].scheme = [
      /* initial amount */
      10500000,
      /* M+1 M+2 */
      10500000, 9000000
    ];

    // Vesting data for platform category
    vesting[platformCategory].limit = _expandToDecimals(30000000);
    vesting[platformCategory].scheme = [
      /* initial amount */
      30000000
    ];

    // Vesting data for seed category
    vesting[seedCategory].limit = _expandToDecimals(22522500);
    vesting[seedCategory].scheme = [
      /* initial amount */
      5630625,
      /* M+1 M+2 M+3 M+4 M+5 */
      3378375, 3378375, 3378375, 3378375, 3378375
    ];

    // Vesting data for foundation category
    vesting[foundationCategory].limit = _expandToDecimals(193477500);
    vesting[foundationCategory].scheme = [
      /* initial amount */
      0,
      /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 M+10 M+11 M+12 */
      0, 0, 0, 0, 0, 6000000, 6000000, 6000000, 6000000, 6000000, 6000000, 6000000,
      /* Y+2 */
      4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000,
      /* Y+3 */
      4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000, 4000000,
      /* Y+4 */
      3000000, 3000000, 3000000, 3000000, 3000000, 3000000, 3000000, 3000000, 3000000, 3000000, 3000000, 3000000,
      /* Y+5 */
      19477500
    ];

    // Vesting data for marketing category
    vesting[marketingCategory].limit = _expandToDecimals(50000000);
    vesting[marketingCategory].scheme = [
      /* initial amount */
      0,
      /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 M+10 M+11 M+12 */
      0, 0, 2000000, 2000000, 2000000, 2000000, 2000000, 2000000, 2000000, 2000000, 2000000, 2000000,
      /* Y+2 */
      1500000, 1500000, 1500000, 1500000, 1500000, 1500000, 1500000, 1500000, 1500000, 1500000, 1500000, 1500000,
      /* Y+3 */
      1000000, 1000000, 1000000, 1000000, 1000000, 1000000, 1000000, 1000000, 1000000, 1000000, 1000000, 1000000
    ];

    // Vesting data for team category
    vesting[teamCategory].limit = _expandToDecimals(50000000);
    vesting[teamCategory].scheme = [
      /* initial amount */
      0,
      /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 M+10 M+11 M+12 */
      0, 0, 0, 0, 0, 7000000, 0, 0, 0, 7000000, 0, 0,
      /* Y+2 */
      0, 7000000, 0, 0, 0, 7000000, 0, 0, 7000000, 0, 0, 0,
      /* Y+3 */
      0, 7500000, 0, 0, 0, 7500000
    ];

    // Vesting data for advisor category
    vesting[advisorCategory].limit = _expandToDecimals(24000000);
    vesting[advisorCategory].scheme = [
      /* initial amount */
      0,
      /* M+1 M+2 M+3 M+4 M+5 M+6 M+7 M+8 M+9 */
      0, 0, 6000000, 6000000, 4500000, 4500000, 0, 1500000, 1500000
    ];

    _expandToDecimalsVestingScheme(privateCategory);
    _expandToDecimalsVestingScheme(platformCategory);
    _expandToDecimalsVestingScheme(seedCategory);
    _expandToDecimalsVestingScheme(foundationCategory);
    _expandToDecimalsVestingScheme(marketingCategory);
    _expandToDecimalsVestingScheme(teamCategory);
    _expandToDecimalsVestingScheme(advisorCategory);
  }

  function _expandToDecimalsVestingScheme(bytes32 _category) internal returns (uint256[]) {
    for(uint i = 0; i < vesting[_category].scheme.length; i++) {
      vesting[_category].scheme[i] = _expandToDecimals(vesting[_category].scheme[i]);
    }
  }

  function _expandToDecimals(uint256 _amount) internal view returns (uint256) {
    return _amount.mul(10 ** uint(18));
  }
}

// File: contracts/multiowned.sol

// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

// Code taken from https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol
// Audit, refactoring and improvements by github.com/Eenae

// @authors:
// Gav Wood <g@ethdev.com>
// inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.

pragma solidity ^0.4.26;


/// note: during any ownership changes all pending operations (waiting for more signatures) are cancelled
// TODO acceptOwnership
contract multiowned {

  // TYPES

  // struct for the status of a pending operation.
  struct MultiOwnedOperationPendingState {
    // count of confirmations needed
    uint yetNeeded;

    // bitmap of confirmations where owner #ownerIndex's decision corresponds to 2**ownerIndex bit
    uint ownersDone;

    // position of this operation key in m_multiOwnedPendingIndex
    uint index;
  }

  // EVENTS

  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);
  event FinalConfirmation(address owner, bytes32 operation);
  event Op(bytes32 operation);

  // some others are in the case of an owner changing.
  event OwnerChanged(address oldOwner, address newOwner);
  event OwnerAdded(address newOwner);
  event OwnerRemoved(address oldOwner);

  // the last one is emitted if the required signatures change
  event RequirementChanged(uint newRequirement);

  // MODIFIERS

  // simple single-sig function modifier.
  modifier onlyowner {
    require(isOwner(msg.sender));
    _;
  }
  // multi-sig function modifier: the operation must have an intrinsic hash in order
  // that later attempts can be realised as the same underlying operation and
  // thus count as confirmations.
  modifier onlymanyowners(bytes32 _operation) {
    if (confirmAndCheck(_operation)) {
      _;
    }
    // Even if required number of confirmations has't been collected yet,
    // we can't throw here - because changes to the state have to be preserved.
    // But, confirmAndCheck itself will throw in case sender is not an owner.
  }

  modifier onlyallowners(bytes32 _operation) {
    if (confirmAndCheckForAll(_operation)) {
      _;
    }
  }

  modifier onlyalmostallowners(bytes32 _operation) {
    if (confirmAndCheckForAlmostAll(_operation)) {
      _;
    }
  }

  modifier validNumOwners(uint _numOwners) {
    require(_numOwners > 0 && _numOwners <= c_maxOwners);
    _;
  }

  modifier multiOwnedValidRequirement(uint _required, uint _numOwners) {
    require(_required > 0 && _required <= _numOwners);
    _;
  }

  modifier ownerExists(address _address) {
    require(isOwner(_address));
    _;
  }

  modifier ownerDoesNotExist(address _address) {
    require(!isOwner(_address));
    _;
  }

  modifier multiOwnedOperationIsActive(bytes32 _operation) {
    require(isOperationActive(_operation));
    _;
  }

  // METHODS

  // constructor is given number of sigs required to do protected "onlymanyowners" transactions
  // as well as the selection of addresses capable of confirming them (msg.sender is not added to the owners!).
  constructor(address[] _owners, uint _required)
      public
      validNumOwners(_owners.length)
      multiOwnedValidRequirement(_required, _owners.length)
  {
    assert(c_maxOwners <= 255);

    require(_owners.length == 6, "Gath3r: Number of total multisig owners must be equal to 6");
    require(_required == 3, "Gath3r: Number of required multisig owners must be equal to 3");

    m_numOwners = _owners.length;
    m_multiOwnedRequired = _required;

    for (uint i = 0; i < _owners.length; ++i)
    {
      address owner = _owners[i];
      // invalid and duplicate addresses are not allowed
      require(0 != owner && !isOwner(owner) /* not isOwner yet! */);

      uint currentOwnerIndex = checkOwnerIndex(i + 1 /* first slot is unused */);
      m_owners[currentOwnerIndex] = owner;
      m_ownerIndex[owner] = currentOwnerIndex;
    }

    assertOwnersAreConsistent();
  }

  /// @notice replaces an owner `_from` with another `_to`.
  /// @param _from address of owner to replace
  /// @param _to address of new owner
  // All pending operations will be canceled!
  function changeOwner(address _from, address _to)
      external
      ownerExists(_from)
      ownerDoesNotExist(_to)
      onlyalmostallowners(keccak256(msg.data))
  {
    assertOwnersAreConsistent();

    clearPending();
    uint ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
    m_owners[ownerIndex] = _to;
    m_ownerIndex[_from] = 0;
    m_ownerIndex[_to] = ownerIndex;

    assertOwnersAreConsistent();
    emit OwnerChanged(_from, _to);
  }

  /// @notice adds an owner
  /// @param _owner address of new owner
  // All pending operations will be canceled!
  function addOwner(address _owner)
      external
      ownerDoesNotExist(_owner)
      validNumOwners(m_numOwners + 1)
      onlyalmostallowners(keccak256(msg.data))
  {
    assertOwnersAreConsistent();

    clearPending();
    m_numOwners++;
    m_owners[m_numOwners] = _owner;
    m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

    assertOwnersAreConsistent();
    OwnerAdded(_owner);
  }

  /// @notice removes an owner
  /// @param _owner address of owner to remove
  // All pending operations will be canceled!
  function removeOwner(address _owner)
    external
    ownerExists(_owner)
    validNumOwners(m_numOwners - 1)
    multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
    onlyalmostallowners(keccak256(msg.data))
  {
    assertOwnersAreConsistent();

    clearPending();
    uint ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
    m_owners[ownerIndex] = 0;
    m_ownerIndex[_owner] = 0;
    //make sure m_numOwners is equal to the number of owners and always points to the last owner
    reorganizeOwners();

    assertOwnersAreConsistent();
    OwnerRemoved(_owner);
  }

  /// @notice changes the required number of owner signatures
  /// @param _newRequired new number of signatures required
  // All pending operations will be canceled!
  function changeRequirement(uint _newRequired)
    external
    multiOwnedValidRequirement(_newRequired, m_numOwners)
    onlymanyowners(keccak256(msg.data))
  {
    m_multiOwnedRequired = _newRequired;
    clearPending();
    RequirementChanged(_newRequired);
  }

  /// @notice Gets an owner by 0-indexed position
  /// @param ownerIndex 0-indexed owner position
  function getOwner(uint ownerIndex) public view returns (address) {
    return m_owners[ownerIndex + 1];
  }

  /// @notice Gets owners
  /// @return memory array of owners
  function getOwners() public view returns (address[]) {
    address[] memory result = new address[](m_numOwners);
    for (uint i = 0; i < m_numOwners; i++)
      result[i] = getOwner(i);

    return result;
  }

  /// @notice checks if provided address is an owner address
  /// @param _addr address to check
  /// @return true if it's an owner
  function isOwner(address _addr) public view returns (bool) {
    return m_ownerIndex[_addr] > 0;
  }

  /// @notice Tests ownership of the current caller.
  /// @return true if it's an owner
  // It's advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
  // addOwner/changeOwner and to isOwner.
  function amIOwner() external view onlyowner returns (bool) {
    return true;
  }

  /// @notice Revokes a prior confirmation of the given operation
  /// @param _operation operation value, typically keccak256(msg.data)
  function revoke(bytes32 _operation)
    external
    multiOwnedOperationIsActive(_operation)
    onlyowner
  {
    uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];
    require(pending.ownersDone & ownerIndexBit > 0);

    assertOperationIsConsistent(_operation);

    pending.yetNeeded++;
    pending.ownersDone -= ownerIndexBit;

    assertOperationIsConsistent(_operation);
    Revoke(msg.sender, _operation);
  }

  /// @notice Checks if owner confirmed given operation
  /// @param _operation operation value, typically keccak256(msg.data)
  /// @param _owner an owner address
  function hasConfirmed(bytes32 _operation, address _owner)
    external
    view
    multiOwnedOperationIsActive(_operation)
    ownerExists(_owner)
    returns (bool)
  {
    return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
  }

  // INTERNAL METHODS

  function confirmAndCheck(bytes32 _operation)
    private
    onlyowner
    returns (bool)
  {
    if (512 == m_multiOwnedPendingIndex.length)
      // In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
      // we won't be able to do it because of block gas limit.
      // Yes, pending confirmations will be lost. Dont see any security or stability implications.
      // TODO use more graceful approach like compact or removal of clearPending completely
      clearPending();

    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];

    // if we're not yet working on this operation, switch over and reset the confirmation status.
    if (! isOperationActive(_operation)) {
      // reset count of confirmations needed.
      pending.yetNeeded = m_multiOwnedRequired;
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = m_multiOwnedPendingIndex.length++;
      m_multiOwnedPendingIndex[pending.index] = _operation;
      assertOperationIsConsistent(_operation);
    }

    // determine the bit to set for this owner.
    uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
    // make sure we (the message sender) haven't confirmed this operation previously.
    if (pending.ownersDone & ownerIndexBit == 0) {
      // ok - check if count is enough to go ahead.
      assert(pending.yetNeeded > 0);
      if (pending.yetNeeded == 1) {
        // enough confirmations: reset and run interior.
        delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
        delete m_multiOwnedPending[_operation];
        FinalConfirmation(msg.sender, _operation);
        return true;
      }
      else
      {
        // not enough: record that this owner in particular confirmed.
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
        assertOperationIsConsistent(_operation);
        Confirmation(msg.sender, _operation);
      }
    }
  }

  function confirmAndCheckForAll(bytes32 _operation)
    private
    onlyowner
    returns (bool)
  {
    if (512 == m_multiOwnedPendingIndex.length)
      // In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
      // we won't be able to do it because of block gas limit.
      // Yes, pending confirmations will be lost. Dont see any security or stability implications.
      // TODO use more graceful approach like compact or removal of clearPending completely
      clearPending();

    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];

    // if we're not yet working on this operation, switch over and reset the confirmation status.
    if (! isOperationActive(_operation)) {
      // reset count of confirmations needed.
      pending.yetNeeded = m_numOwners;
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = m_multiOwnedPendingIndex.length++;
      m_multiOwnedPendingIndex[pending.index] = _operation;
      assertOperationIsConsistentForAll(_operation);
    }

    // determine the bit to set for this owner.
    uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
    // make sure we (the message sender) haven't confirmed this operation previously.
    if (pending.ownersDone & ownerIndexBit == 0) {
      // ok - check if count is enough to go ahead.
      assert(pending.yetNeeded > 0);
      if (pending.yetNeeded == 1) {
        // enough confirmations: reset and run interior.
        delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
        delete m_multiOwnedPending[_operation];
        FinalConfirmation(msg.sender, _operation);
        return true;
      }
      else
      {
        // not enough: record that this owner in particular confirmed.
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
        assertOperationIsConsistentForAll(_operation);
        Confirmation(msg.sender, _operation);
      }
    }
  }

  function confirmAndCheckForAlmostAll(bytes32 _operation)
    private
    onlyowner
    returns (bool)
  {
    if (512 == m_multiOwnedPendingIndex.length)
      // In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
      // we won't be able to do it because of block gas limit.
      // Yes, pending confirmations will be lost. Dont see any security or stability implications.
      // TODO use more graceful approach like compact or removal of clearPending completely
      clearPending();

    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];

    // if we're not yet working on this operation, switch over and reset the confirmation status.
    if (! isOperationActive(_operation)) {
      // reset count of confirmations needed.
      pending.yetNeeded = m_numOwners - 1;
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = m_multiOwnedPendingIndex.length++;
      m_multiOwnedPendingIndex[pending.index] = _operation;
      assertOperationIsConsistentForAlmostAll(_operation);
    }

    // determine the bit to set for this owner.
    uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
    // make sure we (the message sender) haven't confirmed this operation previously.
    if (pending.ownersDone & ownerIndexBit == 0) {
      // ok - check if count is enough to go ahead.
      assert(pending.yetNeeded > 0);
      if (pending.yetNeeded == 1) {
        // enough confirmations: reset and run interior.
        delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
        delete m_multiOwnedPending[_operation];
        FinalConfirmation(msg.sender, _operation);
        return true;
      }
      else
      {
        // not enough: record that this owner in particular confirmed.
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
        assertOperationIsConsistentForAlmostAll(_operation);
        Confirmation(msg.sender, _operation);
      }
    }
  }

  // Reclaims free slots between valid owners in m_owners.
  // TODO given that its called after each removal, it could be simplified.
  function reorganizeOwners() private {
    uint free = 1;
    while (free < m_numOwners)
    {
      // iterating to the first free slot from the beginning
      while (free < m_numOwners && m_owners[free] != 0) free++;

      // iterating to the first occupied slot from the end
      while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;

      // swap, if possible, so free slot is located at the end after the swap
      if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
      {
        // owners between swapped slots should't be renumbered - that saves a lot of gas
        m_owners[free] = m_owners[m_numOwners];
        m_ownerIndex[m_owners[free]] = free;
        m_owners[m_numOwners] = 0;
      }
    }
  }

  function clearPending() private onlyowner {
    uint length = m_multiOwnedPendingIndex.length;
    // TODO block gas limit
    for (uint i = 0; i < length; ++i) {
      if (m_multiOwnedPendingIndex[i] != 0)
        delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
    }
    delete m_multiOwnedPendingIndex;
  }

  function checkOwnerIndex(uint ownerIndex) private pure returns (uint) {
    assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
    return ownerIndex;
  }

  function makeOwnerBitmapBit(address owner) private view returns (uint) {
    uint ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
    return 2 ** ownerIndex;
  }

  function isOperationActive(bytes32 _operation) private view returns (bool) {
    return 0 != m_multiOwnedPending[_operation].yetNeeded;
  }


  function assertOwnersAreConsistent() private view {
    assert(m_numOwners > 0);
    assert(m_numOwners <= c_maxOwners);
    assert(m_owners[0] == 0);
    assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
  }

  function assertOperationIsConsistent(bytes32 _operation) private view {
    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];
    assert(0 != pending.yetNeeded);
    assert(m_multiOwnedPendingIndex[pending.index] == _operation);
    assert(pending.yetNeeded <= m_multiOwnedRequired);
  }

  function assertOperationIsConsistentForAll(bytes32 _operation) private view {
    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];
    assert(0 != pending.yetNeeded);
    assert(m_multiOwnedPendingIndex[pending.index] == _operation);
    assert(pending.yetNeeded <= m_numOwners);
  }

  function assertOperationIsConsistentForAlmostAll(bytes32 _operation) private view {
    MultiOwnedOperationPendingState pending = m_multiOwnedPending[_operation];
    assert(0 != pending.yetNeeded);
    assert(m_multiOwnedPendingIndex[pending.index] == _operation);
    assert(pending.yetNeeded <= m_numOwners - 1);
  }


  // FIELDS

  uint constant c_maxOwners = 250;

  // the number of owners that must confirm the same operation before it is run.
  uint256 public m_multiOwnedRequired;


  // pointer used to find a free slot in m_owners
  uint public m_numOwners;

  // list of owners (addresses),
  // slot 0 is unused so there are no owner which index is 0.
  // TODO could we save space at the end of the array for the common case of <10 owners? and should we?
  address[256] internal m_owners;

  // index on the list of owners to allow reverse lookup: owner address => index in m_owners
  mapping(address => uint) internal m_ownerIndex;


  // the ongoing operations.
  mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
  bytes32[] internal m_multiOwnedPendingIndex;
}

// File: contracts/VestingPoolController.sol

pragma solidity ^0.4.26;






contract VestingPoolController is multiowned {

  VestingPool public vestingPool;

  // Category name identifiers
  bytes32 public privateCategory = keccak256("privateCategory");
  bytes32 public platformCategory = keccak256("platformCategory");
  bytes32 public seedCategory = keccak256("seedCategory");
  bytes32 public foundationCategory = keccak256("foundationCategory");
  bytes32 public marketingCategory = keccak256("marketingCategory");
  bytes32 public teamCategory = keccak256("teamCategory");
  bytes32 public advisorCategory = keccak256("advisorCategory");


  constructor(address[] _owners, uint _required, address _vestingPoolAddress) multiowned(_owners, _required) public {
    vestingPool = VestingPool(_vestingPoolAddress);
  }

  function startVesting() public onlymanyowners(keccak256(msg.data)) {
    vestingPool.startVesting();
  }

  // Withdraw
  function privateWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, privateCategory);
  }

  function platformWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, platformCategory);
  }

  function seedWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, seedCategory);
  }

  function foundationWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, foundationCategory);
  }

  function marketingWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, marketingCategory);
  }

  function teamWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, teamCategory);
  }

  function advisorWithdraw(address[] _beneficiaries, uint256[] _amounts) public onlymanyowners(keccak256(msg.data)) {
    vestingPool.multipleWithdraw(_beneficiaries, _amounts, advisorCategory);
  }

  // Get available amount
  function getAvailableAmountForPrivate() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(privateCategory);
  }
  function getAvailableAmountForPlatform() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(platformCategory);
  }

  function getAvailableAmountForSeed() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(seedCategory);
  }

  function getAvailableAmountForFoundation() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(foundationCategory);
  }

  function getAvailableAmountForMarketing() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(marketingCategory);
  }

  function getAvailableAmountForTeam() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(teamCategory);
  }

  function getAvailableAmountForAdvisor() public view returns (uint256) {
    return vestingPool.getAvailableAmountFor(advisorCategory);
  }

  // Add Admin 1
  function addAdmin1(address _admin) public onlyowner {
    vestingPool.addAdmin1address(_admin);
  }
  // Add Admin 2
  function addAdmin2(address _admin) public onlyowner {
    vestingPool.addAdmin2address(_admin);
  }

  // Approve for emergency transfer from admin for each category
  function firstAdminEmergencyApproveFor(bytes32 _category) public {
    vestingPool.firstAdminEmergencyApproveFor(_category, msg.sender);
  }

  function secondAdminEmergencyApproveFor(bytes32 _category) public {
    vestingPool.secondAdminEmergencyApproveFor(_category, msg.sender);
  }

  // Approve from multiowned for each category
  function firstMultiownedEmergencyApproveFor(bytes32 _category) public onlyallowners(keccak256(msg.data)) {
    vestingPool.firstMultiownedEmergencyApproveFor(_category);
  }

  function secondMultiownedEmergencyApproveFor(bytes32 _category) public onlyallowners(keccak256(msg.data)) {
    vestingPool.secondMultiownedEmergencyApproveFor(_category);
  }

  // Emergency transfer for each category
  function emergencyTransferFor(bytes32 _category, address _wallet) public onlyowner {
    vestingPool.emergencyTransferFor(_category, _wallet);
  }

  function transferOwnership(address _newOwner) public onlyalmostallowners(keccak256(msg.data)) {
    vestingPool.transferOwnership(_newOwner);
  }
}