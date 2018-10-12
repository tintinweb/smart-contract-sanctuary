pragma solidity ^0.4.24;
pragma solidity ^0.4.24;



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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract SingleLockingContract is Ownable {
    using SafeMath for uint256;

    /* --- EVENTS --- */

    event ReleasedTokens(address indexed _beneficiary);

    /* --- FIELDS --- */

    ERC20 public tokenContract;
    uint256 public unlockTime;
    address public beneficiary;

    /* --- MODIFIERS --- */

    modifier onlyWhenUnlocked() {
        require(!isLocked());
        _;
    }

    modifier onlyWhenLocked() {
        require(isLocked());
        _;
    }

    /* --- CONSTRUCTOR --- */

    function SingleLockingContract(ERC20 _tokenContract, uint256 _unlockTime, address _beneficiary) public {
        require(_unlockTime > now);
        require(address(_tokenContract) != 0x0);
        require(_beneficiary != 0x0);

        unlockTime = _unlockTime;
        tokenContract = _tokenContract;
        beneficiary = _beneficiary;
    }

    /* --- PUBLIC / EXTERNAL METHODS --- */

    function isLocked() public view returns(bool) {
        return now < unlockTime;
    }

    function balanceOf() public view returns (uint256 balance) {
        return tokenContract.balanceOf(address(this));
    }

    function releaseTokens() public onlyWhenUnlocked {
        require(msg.sender == owner || msg.sender == beneficiary);
        require(tokenContract.transfer(beneficiary, balanceOf())); 
        emit ReleasedTokens(beneficiary);
    }
}


contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}

contract LockingContract is Ownable {
    using SafeMath for uint256;

    event NotedTokens(address indexed _beneficiary, uint256 _tokenAmount);
    event ReleasedTokens(address indexed _beneficiary);
    event ReducedLockingTime(uint256 _newUnlockTime);

    ERC20 public tokenContract;
    mapping(address => uint256) public tokens;
    uint256 public totalTokens;
    uint256 public unlockTime;

    function isLocked() public view returns(bool) {
        return now < unlockTime;
    }

    modifier onlyWhenUnlocked() {
        require(!isLocked());
        _;
    }

    modifier onlyWhenLocked() {
        require(isLocked());
        _;
    }

    function LockingContract(ERC20 _tokenContract, uint256 _unlockTime) public {
        require(_unlockTime > now);
        require(address(_tokenContract) != 0x0);
        unlockTime = _unlockTime;
        tokenContract = _tokenContract;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokens[_owner];
    }

    // Should only be done from another contract.
    // To ensure that the LockingContract can release all noted tokens later,
    // one should mint/transfer tokens to the LockingContract&#39;s account prior to noting
    function noteTokens(address _beneficiary, uint256 _tokenAmount) external onlyOwner onlyWhenLocked {
        uint256 tokenBalance = tokenContract.balanceOf(this);
        require(tokenBalance >= totalTokens.add(_tokenAmount));

        tokens[_beneficiary] = tokens[_beneficiary].add(_tokenAmount);
        totalTokens = totalTokens.add(_tokenAmount);
        emit NotedTokens(_beneficiary, _tokenAmount);
    }

    function releaseTokens(address _beneficiary) public onlyWhenUnlocked {
        require(msg.sender == owner || msg.sender == _beneficiary);
        uint256 amount = tokens[_beneficiary];
        tokens[_beneficiary] = 0;
        require(tokenContract.transfer(_beneficiary, amount)); 
        totalTokens = totalTokens.sub(amount);
        emit ReleasedTokens(_beneficiary);
    }

    function reduceLockingTime(uint256 _newUnlockTime) public onlyOwner onlyWhenLocked {
        require(_newUnlockTime >= now);
        require(_newUnlockTime < unlockTime);
        unlockTime = _newUnlockTime;
        emit ReducedLockingTime(_newUnlockTime);
    }
}




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract CrowdfundableToken is MintableToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public cap;

    function CrowdfundableToken(uint256 _cap, string _name, string _symbol, uint8 _decimals) public {
        require(_cap > 0);
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        cap = _cap;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // override
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }

    // override
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(mintingFinished == true);
        return super.transfer(_to, _value);
    }

    // override
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(mintingFinished == true);
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint amount) public {
        totalSupply_ = totalSupply_.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
    }
}

contract AllSporterCoin is CrowdfundableToken {
    constructor() public 
        CrowdfundableToken(260000000 * (10**18), "AllSporter Coin", "ALL", 18) {
    }
}


contract Minter is Ownable {
    using SafeMath for uint;

    /* --- EVENTS --- */

    event Minted(address indexed account, uint etherAmount, uint tokenAmount);
    event Reserved(uint etherAmount);
    event MintedReserved(address indexed account, uint etherAmount, uint tokenAmount);
    event Unreserved(uint etherAmount);

    /* --- FIELDS --- */

    CrowdfundableToken public token;
    uint public saleEtherCap;
    uint public confirmedSaleEther;
    uint public reservedSaleEther;

    /* --- MODIFIERS --- */

    modifier onlyInUpdatedState() {
        updateState();
        _;
    }

    modifier upToSaleEtherCap(uint additionalEtherAmount) {
        uint totalEtherAmount = confirmedSaleEther.add(reservedSaleEther).add(additionalEtherAmount);
        require(totalEtherAmount <= saleEtherCap);
        _;
    }

    modifier onlyApprovedMinter() {
        require(canMint(msg.sender));
        _;
    }

    modifier atLeastMinimumAmount(uint etherAmount) {
        require(etherAmount >= getMinimumContribution());
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

    /* --- CONSTRUCTOR --- */

    constructor(CrowdfundableToken _token, uint _saleEtherCap) public onlyValidAddress(address(_token)) {
        require(_saleEtherCap > 0);

        token = _token;
        saleEtherCap = _saleEtherCap;
    }

    /* --- PUBLIC / EXTERNAL METHODS --- */

    function transferTokenOwnership() external onlyOwner {
        token.transferOwnership(owner);
    }

    function reserve(uint etherAmount) external
        onlyInUpdatedState
        onlyApprovedMinter
        upToSaleEtherCap(etherAmount)
        atLeastMinimumAmount(etherAmount)
    {
        reservedSaleEther = reservedSaleEther.add(etherAmount);
        updateState();
        emit Reserved(etherAmount);
    }

    function mintReserved(address account, uint etherAmount, uint tokenAmount) external
        onlyInUpdatedState
        onlyApprovedMinter
    {
        reservedSaleEther = reservedSaleEther.sub(etherAmount);
        confirmedSaleEther = confirmedSaleEther.add(etherAmount);
        require(token.mint(account, tokenAmount));
        updateState();
        emit MintedReserved(account, etherAmount, tokenAmount);
    }

    function unreserve(uint etherAmount) public
        onlyInUpdatedState
        onlyApprovedMinter
    {
        reservedSaleEther = reservedSaleEther.sub(etherAmount);
        updateState();
        emit Unreserved(etherAmount);
    }

    function mint(address account, uint etherAmount, uint tokenAmount) public
        onlyInUpdatedState
        onlyApprovedMinter
        upToSaleEtherCap(etherAmount)
    {
        confirmedSaleEther = confirmedSaleEther.add(etherAmount);
        require(token.mint(account, tokenAmount));
        updateState();
        emit Minted(account, etherAmount, tokenAmount);
    }

    // abstract
    function getMinimumContribution() public view returns(uint);

    // abstract
    function updateState() public;

    // abstract
    function canMint(address sender) public view returns(bool);

    // abstract
    function getTokensForEther(uint etherAmount) public view returns(uint);
}

contract DeferredKyc is Ownable {
    using SafeMath for uint;

    /* --- EVENTS --- */

    event AddedToKyc(address indexed investor, uint etherAmount, uint tokenAmount);
    event Approved(address indexed investor, uint etherAmount, uint tokenAmount);
    event Rejected(address indexed investor, uint etherAmount, uint tokenAmount);
    event RejectedWithdrawn(address indexed investor, uint etherAmount);
    event ApproverTransferred(address newApprover);
    event TreasuryUpdated(address newTreasury);

    /* --- FIELDS --- */

    address public treasury;
    Minter public minter;
    address public approver;
    mapping(address => uint) public etherInProgress;
    mapping(address => uint) public tokenInProgress;
    mapping(address => uint) public etherRejected;

    /* --- MODIFIERS --- */ 

    modifier onlyApprover() {
        require(msg.sender == approver);
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

    /* --- CONSTRUCTOR --- */

    constructor(Minter _minter, address _approver, address _treasury)
        public
        onlyValidAddress(address(_minter))
        onlyValidAddress(_approver)
        onlyValidAddress(_treasury)
    {
        minter = _minter;
        approver = _approver;
        treasury = _treasury;
    }

    /* --- PUBLIC / EXTERNAL METHODS --- */

    function updateTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function addToKyc(address investor) external payable onlyOwner {
        minter.reserve(msg.value);
        uint tokenAmount = minter.getTokensForEther(msg.value);
        require(tokenAmount > 0);
        emit AddedToKyc(investor, msg.value, tokenAmount);

        etherInProgress[investor] = etherInProgress[investor].add(msg.value);
        tokenInProgress[investor] = tokenInProgress[investor].add(tokenAmount);
    }

    function approve(address investor) external onlyApprover {
        minter.mintReserved(investor, etherInProgress[investor], tokenInProgress[investor]);
        emit Approved(investor, etherInProgress[investor], tokenInProgress[investor]);
        
        uint value = etherInProgress[investor];
        etherInProgress[investor] = 0;
        tokenInProgress[investor] = 0;
        treasury.transfer(value);
    }

    function reject(address investor) external onlyApprover {
        minter.unreserve(etherInProgress[investor]);
        emit Rejected(investor, etherInProgress[investor], tokenInProgress[investor]);

        etherRejected[investor] = etherRejected[investor].add(etherInProgress[investor]);
        etherInProgress[investor] = 0;
        tokenInProgress[investor] = 0;
    }

    function withdrawRejected() external {
        uint value = etherRejected[msg.sender];
        etherRejected[msg.sender] = 0;
        (msg.sender).transfer(value);
        emit RejectedWithdrawn(msg.sender, value);
    }

    function forceWithdrawRejected(address investor) external onlyApprover {
        uint value = etherRejected[investor];
        etherRejected[investor] = 0;
        (investor).transfer(value);
        emit RejectedWithdrawn(investor, value);
    }

    function transferApprover(address newApprover) external onlyApprover {
        approver = newApprover;
        emit ApproverTransferred(newApprover);
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}



contract Allocator is Ownable {
    using SafeMath for uint;

    /* --- CONSTANTS --- */

    uint constant public ETHER_AMOUNT = 0;

    // percentages
    uint constant public COMMUNITY_PERCENTAGE = 5;
    uint constant public ADVISORS_PERCENTAGE = 8;
    uint constant public CUSTOMER_PERCENTAGE = 15;
    uint constant public TEAM_PERCENTAGE = 17;
    uint constant public SALE_PERCENTAGE = 55;
    
    // locking
    uint constant public LOCKING_UNLOCK_TIME = 1602324000;

    // vesting
    uint constant public VESTING_START_TIME = 1568109600;
    uint constant public VESTING_CLIFF_DURATION = 10000;
    uint constant public VESTING_PERIOD = 50000;
    
    /* --- EVENTS --- */

    event Initialized();
    event AllocatedCommunity(address indexed account, uint tokenAmount);
    event AllocatedAdvisors(address indexed account, uint tokenAmount);
    event AllocatedCustomer(address indexed account, uint tokenAmount, address contractAddress);
    event AllocatedTeam(address indexed account, uint tokenAmount, address contractAddress);
    event LockedTokensReleased(address indexed account);
    event VestedTokensReleased(address indexed account);

    /* --- FIELDS --- */

    Minter public minter;
    bool public isInitialized = false;
    mapping(address => TokenVesting) public vestingContracts; // one customer => one TokenVesting contract
    mapping(address => SingleLockingContract) public lockingContracts; // one team => one SingleLockingContract

    // pools
    uint public communityPool;
    uint public advisorsPool;
    uint public customerPool;
    uint public teamPool;
    

    /* --- MODIFIERS --- */

    modifier initialized() {
        if (!isInitialized) {
            initialize();
        }
        _;
    }

    modifier validPercentage(uint percent) {
        require(percent >= 0 && percent <= 100);
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

    /* --- CONSTRUCTOR --- */

    constructor(Minter _minter)
    public
    validPercentage(COMMUNITY_PERCENTAGE)
    validPercentage(ADVISORS_PERCENTAGE)
    validPercentage(CUSTOMER_PERCENTAGE)
    validPercentage(TEAM_PERCENTAGE)
    validPercentage(SALE_PERCENTAGE)
    onlyValidAddress(_minter)
    {
        require(COMMUNITY_PERCENTAGE.add(ADVISORS_PERCENTAGE).add(CUSTOMER_PERCENTAGE).add(TEAM_PERCENTAGE).add(SALE_PERCENTAGE) == 100);
        minter = _minter;
    }

    /* --- PUBLIC / EXTERNAL METHODS --- */

    function releaseVested(address account) external initialized {
        require(msg.sender == account || msg.sender == owner);
        TokenVesting vesting = vestingContracts[account];
        vesting.release(minter.token());
        emit VestedTokensReleased(account);
    }

    function releaseLocked(address account) external initialized {
        require(msg.sender == account || msg.sender == owner);
        SingleLockingContract locking = lockingContracts[account];
        locking.releaseTokens();
        emit LockedTokensReleased(account);
    }

    function allocateCommunity(address account, uint tokenAmount) external initialized onlyOwner {
        communityPool = communityPool.sub(tokenAmount);
        minter.mint(account, ETHER_AMOUNT, tokenAmount);
        emit AllocatedCommunity(account, tokenAmount);
    }

    function allocateAdvisors(address account, uint tokenAmount) external initialized onlyOwner {
        advisorsPool = advisorsPool.sub(tokenAmount);
        minter.mint(account, ETHER_AMOUNT, tokenAmount);
        emit AllocatedAdvisors(account, tokenAmount);
    }

    // vesting
    function allocateCustomer(address account, uint tokenAmount) external initialized onlyOwner {
        customerPool = customerPool.sub(tokenAmount);
        if (address(vestingContracts[account]) == 0x0) {
            vestingContracts[account] = new TokenVesting(account, VESTING_START_TIME, VESTING_CLIFF_DURATION, VESTING_PERIOD, false);
        }
        minter.mint(address(vestingContracts[account]), ETHER_AMOUNT, tokenAmount);
        emit AllocatedCustomer(account, tokenAmount, address(vestingContracts[account]));
    }

    // locking
    function allocateTeam(address account, uint tokenAmount) external initialized onlyOwner {
        teamPool = teamPool.sub(tokenAmount);
        if (address(lockingContracts[account]) == 0x0) {
            lockingContracts[account] = new SingleLockingContract(minter.token(), LOCKING_UNLOCK_TIME, account);
        }
        minter.mint(lockingContracts[account], ETHER_AMOUNT, tokenAmount);
        emit AllocatedTeam(account, tokenAmount, address(lockingContracts[account]));
    }

    /* --- INTERNAL METHODS --- */

    function initialize() internal {
        isInitialized = true;
        CrowdfundableToken token = minter.token();
        uint tokensSold = token.totalSupply();
        uint tokensPerPercent = tokensSold.div(SALE_PERCENTAGE);

        communityPool = COMMUNITY_PERCENTAGE.mul(tokensPerPercent);
        advisorsPool = ADVISORS_PERCENTAGE.mul(tokensPerPercent);
        customerPool = CUSTOMER_PERCENTAGE.mul(tokensPerPercent);
        teamPool = TEAM_PERCENTAGE.mul(tokensPerPercent);

        emit Initialized();
    }
}