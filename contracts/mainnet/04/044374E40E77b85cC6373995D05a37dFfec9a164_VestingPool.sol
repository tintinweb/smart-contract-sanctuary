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