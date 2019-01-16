pragma solidity ^0.4.25;

// File: contracts/openzeppelin/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/openzeppelin/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/openzeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(_b > 0);
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract from https://github.com/zeppelinos/labs/blob/master/upgradeability_ownership/contracts/ownership/Ownable.sol
 * branch: master commit: 3887ab77b8adafba4a26ace002f3a684c1a3388b modified to:
 * 1) Add emit prefix to OwnershipTransferred event (7/13/18)
 * 2) Replace constructor with constructor syntax (7/13/18)
 * 3) consolidate OwnableStorage into this contract
 */
contract Ownable {

  // Owner of the contract
  address private _owner;

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev The constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setOwner(msg.sender);
  }

  /**
 * @dev Tells the address of the owner
 * @return the address of the owner
 */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

// File: contracts/Blacklistable.sol

/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
*/
contract Blacklistable is Ownable {

  address public blacklister;
  mapping(address => bool) internal blacklisted;

  event Blacklisted(address indexed _account);
  event UnBlacklisted(address indexed _account);
  event BlacklisterChanged(address indexed newBlacklister);

  /**
   * @dev Throws if called by any account other than the blacklister
  */
  modifier onlyBlacklister() {
    require(msg.sender == blacklister);
    _;
  }

  /**
   * @dev Throws if argument account is blacklisted
   * @param _account The address to check
  */
  modifier notBlacklisted(address _account) {
    require(blacklisted[_account] == false);
    _;
  }

  /**
   * @dev Checks if account is blacklisted
   * @param _account The address to check
  */
  function isBlacklisted(address _account) public view returns (bool) {
    return blacklisted[_account];
  }

  /**
   * @dev Adds account to blacklist
   * @param _account The address to blacklist
  */
  function blacklist(address _account) public onlyBlacklister {
    blacklisted[_account] = true;
    emit Blacklisted(_account);
  }

  /**
   * @dev Removes account from blacklist
   * @param _account The address to remove from the blacklist
  */
  function unBlacklist(address _account) public onlyBlacklister {
    blacklisted[_account] = false;
    emit UnBlacklisted(_account);
  }

  function updateBlacklister(address _newBlacklister) public onlyOwner {
    require(_newBlacklister != address(0));
    blacklister = _newBlacklister;
    emit BlacklisterChanged(blacklister);
  }
}

// File: contracts/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * Based on openzeppelin tag v1.10.0 commit: feb665136c0dae9912e08397c1a21c4af3651ef3
 * Modifications:
 * 1) Added pauser role, switched pause/unpause to be onlyPauser (6/14/2018)
 * 2) Removed whenNotPause/whenPaused from pause/unpause (6/14/2018)
 * 3) Removed whenPaused (6/14/2018)
 * 4) Switches ownable library to use zeppelinos (7/12/18)
 * 5) Remove constructor (7/13/18)
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PauserChanged(address indexed newAddress);


  address public pauser;
  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev throws if called by any account other than the pauser
   */
  modifier onlyPauser() {
    require(msg.sender == pauser);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser {
    paused = false;
    emit Unpause();
  }

  /**
   * @dev update the pauser role
   */
  function updatePauser(address _newPauser) public onlyOwner {
    require(_newPauser != address(0));
    pauser = _newPauser;
    emit PauserChanged(pauser);
  }

}

// File: contracts/sheets/DelegateContract.sol

contract DelegateContract is Ownable {
  address delegate_;

  event LogicContractChanged(address indexed newAddress);

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyFromAccept() {
    require(msg.sender == delegate_);
    _;
  }

  function setLogicContractAddress(address _addr) public onlyOwner {
    delegate_ = _addr;
    emit LogicContractChanged(_addr);
  }

  function isDelegate(address _addr) public view returns(bool) {
    return _addr == delegate_;
  }
}

// File: contracts/sheets/AllowanceSheet.sol

// A wrapper around the allowanceOf mapping.
contract AllowanceSheet is DelegateContract {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public allowanceOf;

  function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccept {
    allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
  }

  function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccept {
    allowanceOf[_tokenHolder][_spender] = _value;
  }
}

// File: contracts/sheets/BalanceSheet.sol

// A wrapper around the balanceOf mapping.
contract BalanceSheet is DelegateContract, AllowanceSheet {
  using SafeMath for uint256;

  uint256 internal totalSupply_ = 0;

  mapping (address => uint256) public balanceOf;

  function addBalance(address _addr, uint256 _value) public onlyFromAccept {
    balanceOf[_addr] = balanceOf[_addr].add(_value);
  }

  function subBalance(address _addr, uint256 _value) public onlyFromAccept {
    balanceOf[_addr] = balanceOf[_addr].sub(_value);
  }

  function increaseSupply(uint256 _amount) public onlyFromAccept {
    totalSupply_ = totalSupply_.add(_amount);
  }

  function decreaseSupply(uint256 _amount) public onlyFromAccept {
    totalSupply_ = totalSupply_.sub(_amount);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
}

// File: contracts\MarsTokenV1.sol

/**
 * @title MarsToken
 * @dev ERC20 Token backed by fiat reserves
 */
contract MarsTokenV1 is Ownable, ERC20, Pausable, Blacklistable {
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  string public currency;
  address public masterMinter;

  //mapping(address => uint256) internal balances;
  //mapping(address => mapping(address => uint256)) internal allowed;
  //uint256 internal totalSupply_ = 0;
  mapping(address => bool) internal minters;
  mapping(address => uint256) internal minterAllowed;

  event Mint(address indexed minter, address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 amount);
  event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
  event MinterRemoved(address indexed oldMinter);
  event MasterMinterChanged(address indexed newMasterMinter);
  event DestroyedBlackFunds(address indexed _account, uint256 _balance);

  BalanceSheet public balances;
  event BalanceSheetSet(address indexed sheet);

  /**
  * @dev ownership of the balancesheet contract
  * @param _sheet The address to of the balancesheet.
  */
  function setBalanceSheet(address _sheet) public onlyOwner returns (bool) {
    balances = BalanceSheet(_sheet);
    emit BalanceSheetSet(_sheet);
    return true;
  }

  constructor(
    string _name,
    string _symbol,
    string _currency,
    uint8 _decimals,
    address _masterMinter,
    address _pauser,
    address _blacklister
  ) public {
    require(_masterMinter != address(0));
    require(_pauser != address(0));
    require(_blacklister != address(0));

    name = _name;
    symbol = _symbol;
    currency = _currency;
    decimals = _decimals;
    masterMinter = _masterMinter;
    pauser = _pauser;
    blacklister = _blacklister;
    setOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than a minter
  */
  modifier onlyMinters() {
    require(minters[msg.sender] == true);
    _;
  }

  /**
  * @dev Function to mint tokens
  * @param _to The address that will receive the minted tokens.
  * @param _amount The amount of tokens to mint. Must be less than or equal to the minterAllowance of the caller.
  * @return A boolean that indicates if the operation was successful.
  */
  function mint(address _to, uint256 _amount) public whenNotPaused onlyMinters notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
    require(_to != address(0));
    require(_amount > 0);

    uint256 mintingAllowedAmount = minterAllowed[msg.sender];
    require(_amount <= mintingAllowedAmount);

    //totalSupply_ = totalSupply_.add(_amount);
    balances.increaseSupply(_amount);
    //balances[_to] = balances[_to].add(_amount);
    balances.addBalance(_to, _amount);
    minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
    emit Mint(msg.sender, _to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

  /**
  * @dev Throws if called by any account other than the masterMinter
  */
  modifier onlyMasterMinter() {
    require(msg.sender == masterMinter);
    _;
  }

  /**
  * @dev Get minter allowance for an account
  * @param minter The address of the minter
  */
  function minterAllowance(address minter) public view returns (uint256) {
    return minterAllowed[minter];
  }

  /**
  * @dev Checks if account is a minter
  * @param account The address to check
  */
  function isMinter(address account) public view returns (bool) {
    return minters[account];
  }

  /**
  * @dev Get allowed amount for an account
  * @param owner address The account owner
  * @param spender address The account spender
  */
  function allowance(address owner, address spender) public view returns (uint256) {
    //return allowed[owner][spender];
    return balances.allowanceOf(owner,spender);
  }

  /**
  * @dev Get totalSupply of token
  */
  function totalSupply() public view returns (uint256) {
    return balances.totalSupply();
  }

  /**
  * @dev Get token balance of an account
  * @param account address The account
  */
  function balanceOf(address account) public view returns (uint256) {
    //return balances[account];
    return balances.balanceOf(account);
  }

  /**
  * @dev Adds blacklisted check to approve
  * @return True if the operation was successful.
  */
  function approve(address _spender, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool) {
    require(_spender != address(0));
    //allowed[msg.sender][_spender] = _value;
    balances.setAllowance(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
  * @dev Transfer tokens from one address to another.
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amount of tokens to be transferred
  * @return bool success
  */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notBlacklisted(_to) notBlacklisted(msg.sender) notBlacklisted(_from) returns (bool) {
    require(_to != address(0));
    require(_value <= balances.balanceOf(_from));
    require(_value <= balances.allowanceOf(_from, msg.sender));

    //allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances.subAllowance(_from, msg.sender, _value);
    //balances[_from] = balances[_from].sub(_value);
    balances.subBalance(_from, _value);
    //balances[_to] = balances[_to].add(_value);
    balances.addBalance(_to, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @return bool success
  */
  function transfer(address _to, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
    require(_to != address(0));
    require(_value <= balances.balanceOf(msg.sender));

    //balances[msg.sender] = balances[msg.sender].sub(_value);
    balances.subBalance(msg.sender, _value);
    //balances[_to] = balances[_to].add(_value);
    balances.addBalance(_to, _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Function to add/update a new minter
  * @param minter The address of the minter
  * @param minterAllowedAmount The minting amount allowed for the minter
  * @return True if the operation was successful.
  */
  function configureMinter(address minter, uint256 minterAllowedAmount) public whenNotPaused onlyMasterMinter returns (bool) {
    minters[minter] = true;
    minterAllowed[minter] = minterAllowedAmount;
    emit MinterConfigured(minter, minterAllowedAmount);
    return true;
  }

  /**
  * @dev Function to remove a minter
  * @param minter The address of the minter to remove
  * @return True if the operation was successful.
  */
  function removeMinter(address minter) public onlyMasterMinter returns (bool) {
    minters[minter] = false;
    minterAllowed[minter] = 0;
    emit MinterRemoved(minter);
    return true;
  }

  /**
  * @dev allows a minter to burn some of its own tokens
  * Validates that caller is a minter and that sender is not blacklisted
  * amount is less than or equal to the minter&#39;s account balance
  * @param _amount uint256 the amount of tokens to be burned
  */
  function burn(uint256 _amount) public whenNotPaused onlyMinters notBlacklisted(msg.sender) {
    uint256 balance = balances.balanceOf(msg.sender);
    require(_amount > 0);
    require(balance >= _amount);

    //totalSupply_ = totalSupply_.sub(_amount);
    balances.decreaseSupply(_amount);
    //balances[msg.sender] = balance.sub(_amount);
    balances.subBalance(msg.sender, _amount);
    emit Burn(msg.sender, _amount);
    emit Transfer(msg.sender, address(0), _amount);
  }

  function updateMasterMinter(address _newMasterMinter) public onlyOwner {
    require(_newMasterMinter != address(0));
    masterMinter = _newMasterMinter;
    emit MasterMinterChanged(masterMinter);
  }

  /**
   * @dev Destroy funds of account from blacklist
   * @param _account The address to destory funds
  */
  function destroyBlackFunds(address _account) public onlyOwner {
    require(blacklisted[_account]);
    uint256 _balance = balances.balanceOf(_account);
    balances.subBalance(_account, _balance);
    balances.decreaseSupply(_balance);
    emit DestroyedBlackFunds(_account, _balance);
  }

}