pragma solidity ^0.4.19;




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



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


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


contract ThinkCoin is MintableToken {
  string public name = "ThinkCoin";
  string public symbol = "TCO";
  uint8 public decimals = 18;
  uint256 public cap;

  function ThinkCoin(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
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

  function() public payable {
    revert();
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

  function LockingContract(ERC20 _tokenContract, uint256 _lockingDuration) public {
    require(_lockingDuration > 0);
    unlockTime = now.add(_lockingDuration);
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
    require(tokenBalance == totalTokens.add(_tokenAmount));

    tokens[_beneficiary] = tokens[_beneficiary].add(_tokenAmount);
    totalTokens = totalTokens.add(_tokenAmount);
    NotedTokens(_beneficiary, _tokenAmount);
  }

  function releaseTokens(address _beneficiary) public onlyWhenUnlocked {
    uint256 amount = tokens[_beneficiary];
    tokens[_beneficiary] = 0;
    require(tokenContract.transfer(_beneficiary, amount)); 
    totalTokens = totalTokens.sub(amount);
    ReleasedTokens(_beneficiary);
  }

  function reduceLockingTime(uint256 _newUnlockTime) public onlyOwner onlyWhenLocked {
    require(_newUnlockTime >= now);
    require(_newUnlockTime < unlockTime);
    unlockTime = _newUnlockTime;
    ReducedLockingTime(_newUnlockTime);
  }
}





contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;

  event MintProposed(address indexed _beneficiary, uint256 _tokenAmount);
  event MintLockedProposed(address indexed _beneficiary, uint256 _tokenAmount);
  event MintApproved(address indexed _beneficiary, uint256 _tokenAmount);
  event MintLockedApproved(address indexed _beneficiary, uint256 _tokenAmount);
  event MintedAllocation(address indexed _beneficiary, uint256 _tokenAmount);
  event ProposerChanged(address _newProposer);
  event ApproverChanged(address _newApprover);

  ThinkCoin public token;
  LockingContract public lockingContract;
  address public proposer; // proposes mintages of tokens
  address public approver; // approves proposed mintages
  mapping(address => uint256) public mintProposals;
  mapping(address => uint256) public mintLockedProposals;
  uint256 public proposedTotal = 0;
  uint256 public saleCap;
  uint256 public saleStartTime;
  uint256 public saleEndTime;

  function Crowdsale(ThinkCoin _token,
                     uint256 _lockingPeriod,
                     address _proposer,
                     address _approver,
                     uint256 _saleCap,
                     uint256 _saleStartTime,
                     uint256 _saleEndTime
                     ) public {
    require(_saleCap > 0);
    require(_saleStartTime < _saleEndTime);
    require(_saleEndTime > now);
    require(_lockingPeriod > 0);
    require(_proposer != _approver);
    require(_saleStartTime >= now);
    require(_saleCap <= _token.cap());
    require(address(_token) != 0x0);

    token = _token;
    lockingContract = new LockingContract(token, _lockingPeriod);    
    proposer = _proposer;
    approver = _approver;
    saleCap = _saleCap;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;
  }

  modifier saleStarted() {
    require(now >= saleStartTime);
    _;
  }

  modifier saleNotEnded() {
    require(now < saleEndTime);
    _;
  }

  modifier saleEnded() {
    require(now >= saleEndTime);
    _;
  }

  modifier onlyProposer() {
    require(msg.sender == proposer);
    _;
  }

  modifier onlyApprover() {
    require(msg.sender == approver);
    _;
  }

  function exceedsSaleCap(uint256 _additionalAmount) internal view returns(bool) {
    uint256 totalSupply = token.totalSupply();
    return totalSupply.add(_additionalAmount) > saleCap;
  }

  modifier notExceedingSaleCap(uint256 _amount) {
    require(!exceedsSaleCap(_amount));
    _;
  }

  function proposeMint(address _beneficiary, uint256 _tokenAmount) public onlyProposer saleStarted saleNotEnded
                                                                          notExceedingSaleCap(proposedTotal.add(_tokenAmount)) {
    require(_tokenAmount > 0);
    require(mintProposals[_beneficiary] == 0);
    proposedTotal = proposedTotal.add(_tokenAmount);
    mintProposals[_beneficiary] = _tokenAmount;
    MintProposed(_beneficiary, _tokenAmount);
  }

  function proposeMintLocked(address _beneficiary, uint256 _tokenAmount) public onlyProposer saleStarted saleNotEnded
                                                                         notExceedingSaleCap(proposedTotal.add(_tokenAmount)) {
    require(_tokenAmount > 0);
    require(mintLockedProposals[_beneficiary] == 0);
    proposedTotal = proposedTotal.add(_tokenAmount);
    mintLockedProposals[_beneficiary] = _tokenAmount;
    MintLockedProposed(_beneficiary, _tokenAmount);
  }

  function clearProposal(address _beneficiary) public onlyApprover {
    proposedTotal = proposedTotal.sub(mintProposals[_beneficiary]);
    mintProposals[_beneficiary] = 0;
  }

  function clearProposalLocked(address _beneficiary) public onlyApprover {
    proposedTotal = proposedTotal.sub(mintLockedProposals[_beneficiary]);
    mintLockedProposals[_beneficiary] = 0;
  }

  function approveMint(address _beneficiary, uint256 _tokenAmount) public onlyApprover saleStarted
                                                                   notExceedingSaleCap(_tokenAmount) {
    require(_tokenAmount > 0);
    require(mintProposals[_beneficiary] == _tokenAmount);
    mintProposals[_beneficiary] = 0;
    token.mint(_beneficiary, _tokenAmount);
    MintApproved(_beneficiary, _tokenAmount);
  }

  function approveMintLocked(address _beneficiary, uint256 _tokenAmount) public onlyApprover saleStarted
                                                                         notExceedingSaleCap(_tokenAmount) {
    require(_tokenAmount > 0);
    require(mintLockedProposals[_beneficiary] == _tokenAmount);
    mintLockedProposals[_beneficiary] = 0;
    token.mint(lockingContract, _tokenAmount);
    lockingContract.noteTokens(_beneficiary, _tokenAmount);
    MintLockedApproved(_beneficiary, _tokenAmount);
  }

  function mintAllocation(address _beneficiary, uint256 _tokenAmount) public onlyOwner saleEnded {
    require(_tokenAmount > 0);
    token.mint(_beneficiary, _tokenAmount);
    MintedAllocation(_beneficiary, _tokenAmount);
  }

  function finishMinting() public onlyOwner saleEnded {
    require(proposedTotal == 0);
    token.finishMinting();
    transferTokenOwnership();
  }

  function transferTokenOwnership() public onlyOwner saleEnded {
    token.transferOwnership(msg.sender);
  }

  function changeProposer(address _newProposer) public onlyOwner {
    require(_newProposer != approver);
    proposer = _newProposer;
    ProposerChanged(_newProposer);
  }

  function changeApprover(address _newApprover) public onlyOwner {
    require(_newApprover != proposer);
    approver = _newApprover;
    ApproverChanged(_newApprover);
  }
}