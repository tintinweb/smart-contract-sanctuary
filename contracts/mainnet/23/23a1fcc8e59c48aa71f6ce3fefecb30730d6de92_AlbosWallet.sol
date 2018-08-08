pragma solidity ^0.4.24;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
    
  mapping (address => bool) public staff;
  mapping (address => uint256) balances;
  uint256 totalSupply_;
  mapping (address => uint256) public uniqueTokens;
  mapping (address => uint256) public preSaleTokens;
  mapping (address => uint256) public crowdSaleTokens;
  mapping (address => uint256) public freezeTokens;
  mapping (address => uint256) public freezeTimeBlock;
  uint256 public launchTime = 999999999999999999999999999999;
  uint256 public totalFreezeTokens = 0;
  bool public listing = false;
  bool public freezing = true;
  address public agentAddress;
  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  modifier afterListing() {
    require(listing == true || owner == msg.sender || agentAddress == msg.sender);
    _;
  }
  
  function checkVesting(address sender) public view returns (uint256) {
    if (now >= launchTime.add(270 days)) {
        return balances[sender];
    } else if (now >= launchTime.add(180 days)) {
        return balances[sender].sub(uniqueTokens[sender].mul(35).div(100));
    } else if (now >= launchTime.add(120 days)) {
        return balances[sender].sub(uniqueTokens[sender].mul(7).div(10));
    } else if (now >= launchTime.add(90 days)) {
        return balances[sender].sub((uniqueTokens[sender].mul(7).div(10)).add(crowdSaleTokens[sender].mul(2).div(10)));
    } else if (now >= launchTime.add(60 days)) {
        return balances[sender].sub(uniqueTokens[sender].add(preSaleTokens[sender].mul(3).div(10)).add(crowdSaleTokens[sender].mul(4).div(10)));
    } else if (now >= launchTime.add(30 days)) {
        return balances[sender].sub(uniqueTokens[sender].add(preSaleTokens[sender].mul(6).div(10)).add(crowdSaleTokens[sender].mul(6).div(10)));
    } else {
        return balances[sender].sub(uniqueTokens[sender].add(preSaleTokens[sender].mul(9).div(10)).add(crowdSaleTokens[sender].mul(8).div(10)));
    }
  }
  
  function checkVestingWithFrozen(address sender) public view returns (uint256) {
    if (freezing) {
        
      if (freezeTimeBlock[sender] <= now) {
          return checkVesting(sender);
      } else {
          return checkVesting(sender).sub(freezeTokens[sender]);
      }
    
    } else {
        return checkVesting(sender);
    }
  }
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) afterListing public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    if (!staff[msg.sender]) {
        require(_value <= checkVestingWithFrozen(msg.sender));
    }

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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    if (!staff[_owner]) {
        return checkVestingWithFrozen(_owner);
    }
    return balances[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) afterListing public {
    require(_value <= balances[msg.sender]);
    if (!staff[msg.sender]) {
        require(_value <= checkVestingWithFrozen(msg.sender));
    }
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract StandardToken is ERC20, BurnableToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) afterListing public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    if (!staff[_from]) {
        require(_value <= checkVestingWithFrozen(_from));
    }

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
}

contract AlbosWallet is Ownable {
  using SafeMath for uint256;

  uint256 public withdrawFoundersTokens;
  uint256 public withdrawReservedTokens;

  address public foundersAddress;
  address public reservedAddress;

  AlbosToken public albosAddress;
  
  constructor(address _albosAddress, address _foundersAddress, address _reservedAddress) public {
    albosAddress = AlbosToken(_albosAddress);
    owner = albosAddress;

    foundersAddress = _foundersAddress;
    reservedAddress = _reservedAddress;
  }

  modifier onlyFounders() {
    require(msg.sender == foundersAddress);
    _;
  }

  modifier onlyReserved() {
    require(msg.sender == reservedAddress);
    _;
  }

  function viewFoundersTokens() public view returns (uint256) {
    if (now >= albosAddress.launchTime().add(270 days)) {
      return albosAddress.foundersSupply();
    } else if (now >= albosAddress.launchTime().add(180 days)) {
      return albosAddress.foundersSupply().mul(65).div(100);
    } else if (now >= albosAddress.launchTime().add(90 days)) {
      return albosAddress.foundersSupply().mul(3).div(10);
    } else {
      return 0;
    }
  }

  function viewReservedTokens() public view returns (uint256) {
    if (now >= albosAddress.launchTime().add(270 days)) {
      return albosAddress.reservedSupply();
    } else if (now >= albosAddress.launchTime().add(180 days)) {
      return albosAddress.reservedSupply().mul(65).div(100);
    } else if (now >= albosAddress.launchTime().add(90 days)) {
      return albosAddress.reservedSupply().mul(3).div(10);
    } else {
      return 0;
    }
  }

  function getFoundersTokens(uint256 _tokens) public onlyFounders {
    uint256 tokens = _tokens.mul(10 ** 18);
    require(withdrawFoundersTokens.add(tokens) <= viewFoundersTokens());
    albosAddress.transfer(foundersAddress, tokens);
    withdrawFoundersTokens = withdrawFoundersTokens.add(tokens);
  }

  function getReservedTokens(uint256 _tokens) public onlyReserved {
    uint256 tokens = _tokens.mul(10 ** 18);
    require(withdrawReservedTokens.add(tokens) <= viewReservedTokens());
    albosAddress.transfer(reservedAddress, tokens);
    withdrawReservedTokens = withdrawReservedTokens.add(tokens);
  }
}

contract AlbosToken is StandardToken {
  string constant public name = "ALBOS Token";
  string constant public symbol = "ALB";
  uint256 public decimals = 18;
  
  uint256 public INITIAL_SUPPLY = uint256(28710000000).mul(10 ** decimals); // 28,710,000,000 tokens
  uint256 public foundersSupply = uint256(4306500000).mul(10 ** decimals); // 4,306,500,000 tokens
  uint256 public reservedSupply = uint256(2871000000).mul(10 ** decimals); // 2,871,000,000 tokens
  AlbosWallet public albosWallet;
  
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[address(this)] = totalSupply_;
    emit Transfer(0x0, address(this), totalSupply_);

    agentAddress = msg.sender;
    staff[owner] = true;
    staff[agentAddress] = true;
  }
  
  modifier onlyAgent() {
    require(msg.sender == agentAddress || msg.sender == owner);
    _;
  }

  function startListing() public onlyOwner {
    require(!listing);
    launchTime = now;
    listing = true;
  }

  function setTeamContract(address _albosWallet) external onlyOwner {

    albosWallet = AlbosWallet(_albosWallet);

    balances[address(albosWallet)] = balances[address(albosWallet)].add(foundersSupply).add(reservedSupply);
    balances[address(this)] = balances[address(this)].sub(foundersSupply).sub(reservedSupply);
     emit Transfer(address(this), address(albosWallet), balances[address(albosWallet)]);
  }

  function addUniqueSaleTokens(address sender, uint256 amount) external onlyAgent {
    uniqueTokens[sender] = uniqueTokens[sender].add(amount);
    
    balances[address(this)] = balances[address(this)].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit Transfer(address(this), sender, amount);
  }
  
  function addUniqueSaleTokensMulti(address[] sender, uint256[] amount) external onlyAgent {
    require(sender.length > 0 && sender.length == amount.length);
    
    for(uint i = 0; i < sender.length; i++) {
      uniqueTokens[sender[i]] = uniqueTokens[sender[i]].add(amount[i]);
      balances[address(this)] = balances[address(this)].sub(amount[i]);
      balances[sender[i]] = balances[sender[i]].add(amount[i]);
      emit Transfer(address(this), sender[i], amount[i]);
    }
  }
  
  function addPrivateSaleTokens(address sender, uint256 amount) external onlyAgent {
    balances[address(this)] = balances[address(this)].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit Transfer(address(this), sender, amount);
  }
  
  function addPrivateSaleTokensMulti(address[] sender, uint256[] amount) external onlyAgent {
    require(sender.length > 0 && sender.length == amount.length);
    
    for(uint i = 0; i < sender.length; i++) {
      balances[address(this)] = balances[address(this)].sub(amount[i]);
      balances[sender[i]] = balances[sender[i]].add(amount[i]);
      emit Transfer(address(this), sender[i], amount[i]);
    }
  }
  
  function addPreSaleTokens(address sender, uint256 amount) external onlyAgent {
    preSaleTokens[sender] = preSaleTokens[sender].add(amount);
    
    balances[address(this)] = balances[address(this)].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit Transfer(address(this), sender, amount);
  }
  
  function addPreSaleTokensMulti(address[] sender, uint256[] amount) external onlyAgent {
    require(sender.length > 0 && sender.length == amount.length);
    
    for(uint i = 0; i < sender.length; i++) {
      preSaleTokens[sender[i]] = preSaleTokens[sender[i]].add(amount[i]);
      balances[address(this)] = balances[address(this)].sub(amount[i]);
      balances[sender[i]] = balances[sender[i]].add(amount[i]);
      emit Transfer(address(this), sender[i], amount[i]);
    }
  }
  
  function addCrowdSaleTokens(address sender, uint256 amount) external onlyAgent {
    crowdSaleTokens[sender] = crowdSaleTokens[sender].add(amount);
    
    balances[address(this)] = balances[address(this)].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit Transfer(address(this), sender, amount);
  }

  function addCrowdSaleTokensMulti(address[] sender, uint256[] amount) external onlyAgent {
    require(sender.length > 0 && sender.length == amount.length);
    
    for(uint i = 0; i < sender.length; i++) {
      crowdSaleTokens[sender[i]] = crowdSaleTokens[sender[i]].add(amount[i]);
      balances[address(this)] = balances[address(this)].sub(amount[i]);
      balances[sender[i]] = balances[sender[i]].add(amount[i]);
      emit Transfer(address(this), sender[i], amount[i]);
    }
  }
  
  function addFrostTokens(address sender, uint256 amount, uint256 blockTime) public onlyAgent {

    totalFreezeTokens = totalFreezeTokens.add(amount);
    require(totalFreezeTokens <= totalSupply_.mul(2).div(10));

    freezeTokens[sender] = amount;
    freezeTimeBlock[sender] = blockTime;
  }
  
  function transferAndFrostTokens(address sender, uint256 amount, uint256 blockTime) external onlyAgent {
    balances[address(this)] = balances[address(this)].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit Transfer(address(this), sender, amount);
    addFrostTokens(sender, amount, blockTime);
  }
  
  function addFrostTokensMulti(address[] sender, uint256[] amount, uint256[] blockTime) external onlyAgent {
    require(sender.length > 0 && sender.length == amount.length && amount.length == blockTime.length);

    for(uint i = 0; i < sender.length; i++) {
      totalFreezeTokens = totalFreezeTokens.add(amount[i]);
      freezeTokens[sender[i]] = amount[i];
      freezeTimeBlock[sender[i]] = blockTime[i];
    }
    require(totalFreezeTokens <= totalSupply_.mul(2).div(10));
  }
  
  function transferAgent(address _agent) external onlyOwner {
    agentAddress = _agent;
  }

  function addStaff(address _staff) external onlyOwner {
    staff[_staff] = true;
  }

  function killFrost() external onlyOwner {
    freezing = false;
  }
}