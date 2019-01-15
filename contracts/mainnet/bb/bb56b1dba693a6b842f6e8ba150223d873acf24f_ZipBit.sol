pragma solidity ^0.4.24;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library Config {
    address constant internal BANK = 0x3F7199913BF60aD8653fa611e0A0fc8167C36D0D;
    uint constant internal INITIAL_SUPPLY = 50000000000000000000000000;

    function bank() internal pure returns (address) {
      return BANK;
    }
    
    function initial_supply() internal pure returns (uint) {
      return INITIAL_SUPPLY;
    }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract SuperInvestorRole {
  using Roles for Roles.Role;
  using Config for Config;
    
  address internal BANK = Config.bank();

  event SuperInvestorAdded(address indexed account);
  event SuperInvestorRemoved(address indexed account);

  Roles.Role private superInvestors;

  constructor() internal {
  }

  modifier onlyBank() {
    require(msg.sender == BANK);
    _;
  }
  
  modifier onlyBankOrSuperInvestor() {
    require(msg.sender == BANK || isSuperInvestor(msg.sender));
    _;
  }

  function isSuperInvestor(address account) public view returns (bool) {
    return superInvestors.has(account);
  }

  function addSuperInvestor(address account) public onlyBank {
    _addSuperInvestor(account);
  }

  function renounceSuperInvestor() public onlyBankOrSuperInvestor {
    _removeSuperInvestor(msg.sender);
  }

  function _addSuperInvestor(address account) internal {
    superInvestors.add(account);
    emit SuperInvestorAdded(account);
  }

  function _removeSuperInvestor(address account) internal {
    superInvestors.remove(account);
    emit SuperInvestorRemoved(account);
  }
}

contract InvestorRole is SuperInvestorRole {
  using Roles for Roles.Role;
  using Config for Config;
    
  address internal BANK = Config.bank();

  event InvestorAdded(address indexed account);
  event InvestorRemoved(address indexed account);

  Roles.Role private investors;

  constructor() internal {
  }
  
  modifier onlyInvestor() {
    require(isInvestor(msg.sender));
    _;
  }

  function isInvestor(address account) public view returns (bool) {
    return investors.has(account);
  }

  function addInvestor(address account) public onlyBankOrSuperInvestor {
    _addInvestor(account);
  }

  function renounceInvestor() public onlyInvestor() {
    _removeInvestor(msg.sender);
  }

  function _addInvestor(address account) internal {
    investors.add(account);
    emit InvestorAdded(account);
  }

  function _removeInvestor(address account) internal {
    investors.remove(account);
    emit InvestorRemoved(account);
  }
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract ERC20Mintable is ERC20, MinterRole {
  using Config for Config;
  
  address internal _bank = Config.bank();

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(_bank, value);
    return true;
  }
}

contract ERC20Burnable is ERC20 {
  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

interface IVest {
  function totalVested() external view returns (uint256);

  function vestedOf(address who) external view returns (uint256);
  
  event Vest(
    address indexed to,
    uint256 value
  );
}

contract Vest is IVest {
  using SafeMath for uint256;
  
  struct Beneficiary {
    address _address;
    uint256 startTime;
    uint256 _amount;
    uint256 _percent;
    bool monthly;
  }

  mapping (address => Beneficiary) beneficiaries;

  mapping (address => uint256) private _vestedBalances;

  uint256 private _totalVested;
  uint256 private beneficiariesCount;

  function totalVested() public view returns (uint256) {
    return _totalVested;
  }

  function vestedOf(address owner) public view returns (uint256) {
    return _vestedBalances[owner];
  }

  function _vest(address to, uint256 value, uint256 percent, bool monthly) internal {
    require(to != address(0));

    _totalVested = _totalVested.add(value);
    _vestedBalances[to] = _vestedBalances[to].add(value);

    addBeneficiary(to, now, value, percent, monthly);
    emit Vest(to, value);
  }

  function totalBeneficiaries() public view returns (uint256) {
    return beneficiariesCount;
  }

  function addBeneficiary (address to, uint256, uint256 value, uint256 percent, bool monthly) internal {
    beneficiariesCount ++;
    beneficiaries[to] = Beneficiary(to, now, value, percent, monthly);
  }
  
  function isBeneficiary (address _address) public view returns (bool) {
    if (beneficiaries[_address]._address != 0) {
      return true;
    } else {
      return false;
    }
  }

  function getBeneficiary (address _address) public view returns (address, uint256, uint256, uint256, bool) {
    Beneficiary storage b = beneficiaries[_address];
    return (b._address, b.startTime, b._amount, b._percent, b.monthly);
  }
  
  function _getLockedAmount(address _address) public view returns (uint256) {
    Beneficiary memory b = beneficiaries[_address];
    uint256 amount = b._amount;
    uint256 percent = b._percent;
    uint256 timeValue = _getTimeValue(_address);
    uint256 calcAmount = amount.mul(timeValue.mul(percent)).div(100);

    if (calcAmount >= amount) {
        return 0;
    } else {
        return amount.sub(calcAmount);
    }
  }
  
  function _getTimeValue(address _address) internal view returns (uint256) {
    Beneficiary memory b = beneficiaries[_address];
    uint256 startTime = b.startTime;
    uint256 presentTime = now;
    uint256 timeValue = presentTime.sub(startTime);
    bool monthly = b.monthly;

    if (monthly) {
      return timeValue.div(10 minutes);
    } else {
      return timeValue.div(120 minutes);  
    }
  }
}

contract SuperInvestable is SuperInvestorRole, InvestorRole {
  using SafeMath for uint256;
  using Config for Config;

  address internal BANK = Config.bank();
  uint256 public percent;
  
  struct Investor {
    address _address;
    uint256 _amount;
    uint256 _initialAmount;
    uint256 startTime;
  }
  
  mapping (address => Investor) investorList;
  
  modifier onlyBank() {
    require(msg.sender == BANK);
    _;
  }
  
  function setPercent (uint256 _percent) external onlyBank returns (bool) {
    percent = _percent;
    return true;
  }
  
  function addToInvestorList (address to, uint256 _amount, uint256 _initialAmount, uint256) internal {
    _addInvestor(to);
    investorList[to] = Investor(to, _amount, _initialAmount, now);
  }
      
  function getInvestor (address _address) internal view returns (address, uint256, uint256, uint256) {
    Investor storage i = investorList[_address];
    return (i._address, i._amount, i._initialAmount, i.startTime);
  }
  
  function _getInvestorLockedAmount (address _address) public view returns (uint256) {
    Investor memory i = investorList[_address];
    uint256 amount = i._amount;
    uint256 timeValue = _getTimeValue(_address);
    uint256 calcAmount = amount.mul(timeValue.mul(percent)).div(100);

    if (calcAmount >= amount) {
        return 0;
    } else {
        return amount.sub(calcAmount);
    }
  }
  
  function _getTimeValue (address _address) internal view returns (uint256) {
    Investor memory i = investorList[_address];
    uint256 startTime = i.startTime;
    uint256 presentTime = now;
    uint256 timeValue = presentTime.sub(startTime);

    return timeValue.div(1 minutes);
  }
}

contract ZipBit is ERC20Detailed, ERC20Mintable, ERC20Burnable, Vest, SuperInvestable {
    using Config for Config;

    uint internal INITIAL_SUPPLY = Config.initial_supply();
    address internal BANK = Config.bank();

    string internal _name = "ZipBit";
    string internal _symbol = "ZBT";
    uint8 internal _decimals = 18;

    modifier onlyBank() {
      require(msg.sender == BANK);
      _;
    }

    constructor()
      ERC20Detailed(_name, _symbol, _decimals)

    public 
    {
        _mint(BANK, INITIAL_SUPPLY);
        _addMinter(BANK);
        renounceMinter();
    }

    function vest(address _to, uint256 _amount, uint256 percent, bool monthly)
      onlyBank external returns (bool) {
      _vest(_to, _amount, percent, monthly);
      transfer(_to, _amount);
      return true;
    }

    /* Checks limit for the address 
    *  Checks if the address is a Beneficiary and checks the allowed transferrable first
    *  Then checks if address is a Super Investor and converts the recipient into an Investor
    *  Then checks if address is an Investor and checks the allowed transferrable
    *  Then returns if remaining balance after the transfer is gte to value
    */
    function checkLimit(address _address, uint256 value) internal view returns (bool) {
      uint256 remaining = balanceOf(_address).sub(value);
      
      if (isBeneficiary(_address) && isInvestor(_address)) {
        uint256 ilocked = _getInvestorLockedAmount(_address);
        uint256 locked = _getLockedAmount(_address);
        return remaining >= locked.add(ilocked);
      }
      
      if (isBeneficiary(_address)) {
        return remaining >= _getLockedAmount(_address);
      }
      
      if (isInvestor(_address)) {
        return remaining >= _getInvestorLockedAmount(_address);
      }
    }

    /* Checks if sender is a Beneficiary or an Investor then checks the limit
    *  Then checks if the sender is a superInvestor then converts the recipient to an investor
    *  Then proceeds to transfer the amount
    */
    function transfer(address to, uint256 value) public returns (bool) {
      if (isBeneficiary(msg.sender) || isInvestor(msg.sender)) {
        require(checkLimit(msg.sender, value));
      }

      if (isSuperInvestor(msg.sender)) {
        addToInvestorList(to, value, value, now);
      }

      _transfer(msg.sender, to, value);
      return true;
    }
    
    function bankBurnFrom(address account, uint256 value) external onlyBank {
      _burn(account, value);
    }
}