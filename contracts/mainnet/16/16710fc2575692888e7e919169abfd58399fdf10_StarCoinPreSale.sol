pragma solidity 0.4.20;

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

/**
 * @title StarCoin
 *
 * @dev Burnable Ownable ERC20 token
 */
contract StarCoin is MintableToken {

  string public constant name = "StarCoin";
  string public constant symbol = "STAR";
  uint8 public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 40000000 * 1 ether; //40M tokens accroding to https://starflow.com/ico/
  uint public constant MAXIMUM_SUPPLY = 100000000 * 1 ether; // 100M tokens is maximum according to https://starflow.com/ico/

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

  /** The function can be called only before or after the tokens have been released */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  /** Restrict minting by the MAXIMUM_SUPPLY allowed **/
  modifier bellowMaximumSupply(uint _amount) {
    require(_amount + totalSupply_ < MAXIMUM_SUPPLY);
    _;
  }


  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function StarCoin() {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }


  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  function release() onlyReleaseAgent inReleaseState(false) public {
    released = true;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);
    transferAgents[addr] = state;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call Burnable.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call Burnable.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

    /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) onlyOwner canMint bellowMaximumSupply(_amount) public returns (bool) {
    return super.mint(_to, _amount);
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    return super.finishMinting();
  }


}

contract InvestorWhiteList is Ownable {
  mapping (address => bool) public investorWhiteList;

  mapping (address => address) public referralList;

  function InvestorWhiteList() {

  }

  function addInvestorToWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && !investorWhiteList[investor]);
    investorWhiteList[investor] = true;
  }

  function removeInvestorFromWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && investorWhiteList[investor]);
    investorWhiteList[investor] = false;
  }

  //when new user will contribute ICO contract will automatically send bonus to referral
  function addReferralOf(address investor, address referral) external onlyOwner {
    require(investor != 0x0 && referral != 0x0 && referralList[investor] == 0x0 && investor != referral);
    referralList[investor] = referral;
  }

  function isAllowed(address investor) constant external returns (bool result) {
    return investorWhiteList[investor];
  }

  function getReferralOf(address investor) constant external returns (address result) {
    return referralList[investor];
  }
}

contract StarCoinPreSale is Pausable {
  using SafeMath for uint;

  string public constant name = "StarCoin Token ICO";

  StarCoin public token;

  address public beneficiary;

  InvestorWhiteList public investorWhiteList;

  uint public starEthRate;

  uint public hardCap;

  uint public softCap;

  uint public collected = 0;

  uint public tokensSold = 0;

  uint public weiRefunded = 0;

  uint public startBlock;

  uint public endBlock;

  bool public softCapReached = false;

  bool public crowdsaleFinished = false;

  mapping (address => uint) public deposited;

  uint constant VOLUME_20_REF_7 = 5000 ether;

  uint constant VOLUME_15_REF_6 = 2000 ether;

  uint constant VOLUME_12d5_REF_5d5 = 1000 ether;

  uint constant VOLUME_10_REF_5 = 500 ether;

  uint constant VOLUME_7_REF_4 = 250 ether;

  uint constant VOLUME_5_REF_3 = 100 ether;

  event SoftCapReached(uint softCap);

  event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);

  event NewReferralTransfer(address indexed investor, address indexed referral, uint tokenAmount);

  event Refunded(address indexed holder, uint amount);

  modifier icoActive() {
    require(block.number >= startBlock && block.number < endBlock);
    _;
  }

  modifier icoEnded() {
    require(block.number >= endBlock);
    _;
  }

  modifier minInvestment() {
    require(msg.value >= 0.1 * 1 ether);
    _;
  }

  modifier inWhiteList() {
    require(investorWhiteList.isAllowed(msg.sender));
    _;
  }

  function StarCoinPreSale(
    uint _hardCapSTAR,
    uint _softCapSTAR,
    address _token,
    address _beneficiary,
    address _investorWhiteList,
    uint _baseStarEthPrice,

    uint _startBlock,
    uint _endBlock
  ) {
    hardCap = _hardCapSTAR.mul(1 ether);
    softCap = _softCapSTAR.mul(1 ether);

    token = StarCoin(_token);
    beneficiary = _beneficiary;
    investorWhiteList = InvestorWhiteList(_investorWhiteList);

    startBlock = _startBlock;
    endBlock = _endBlock;

    starEthRate = _baseStarEthPrice;
  }

  function() payable minInvestment inWhiteList {
    doPurchase();
  }

  function refund() external icoEnded {
    require(softCapReached == false);
    require(deposited[msg.sender] > 0);

    uint refund = deposited[msg.sender];

    deposited[msg.sender] = 0;
    msg.sender.transfer(refund);

    weiRefunded = weiRefunded.add(refund);
    Refunded(msg.sender, refund);
  }

  function withdraw() external onlyOwner {
    require(softCapReached);
    beneficiary.transfer(collected);
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  function calculateBonus(uint tokens) internal constant returns (uint bonus) {
    if (msg.value >= VOLUME_20_REF_7) {
      return tokens.mul(20).div(100);
    }

    if (msg.value >= VOLUME_15_REF_6) {
      return tokens.mul(15).div(100);
    }

    if (msg.value >= VOLUME_12d5_REF_5d5) {
      return tokens.mul(125).div(1000);
    }

    if (msg.value >= VOLUME_10_REF_5) {
      return tokens.mul(10).div(100);
    }

    if (msg.value >= VOLUME_7_REF_4) {
      return tokens.mul(7).div(100);
    }

    if (msg.value >= VOLUME_5_REF_3) {
      return tokens.mul(5).div(100);
    }

    return 0;
  }

  function calculateReferralBonus(uint tokens) internal constant returns (uint bonus) {
    if (msg.value >= VOLUME_20_REF_7) {
      return tokens.mul(7).div(100);
    }

    if (msg.value >= VOLUME_15_REF_6) {
      return tokens.mul(6).div(100);
    }

    if (msg.value >= VOLUME_12d5_REF_5d5) {
      return tokens.mul(55).div(1000);
    }

    if (msg.value >= VOLUME_10_REF_5) {
      return tokens.mul(5).div(100);
    }

    if (msg.value >= VOLUME_7_REF_4) {
      return tokens.mul(4).div(100);
    }

    if (msg.value >= VOLUME_5_REF_3) {
      return tokens.mul(3).div(100);
    }

    return 0;
  }

  function setNewWhiteList(address newWhiteList) external onlyOwner {
    require(newWhiteList != 0x0);
    investorWhiteList = InvestorWhiteList(newWhiteList);
  }

  function doPurchase() private icoActive whenNotPaused {
    require(!crowdsaleFinished);

    uint tokens = msg.value.mul(starEthRate);
    uint referralBonus = calculateReferralBonus(tokens);
    address referral = investorWhiteList.getReferralOf(msg.sender);

    tokens = tokens.add(calculateBonus(tokens));

    uint newTokensSold = tokensSold.add(tokens);

    if (referralBonus > 0 && referral != 0x0) {
      newTokensSold = newTokensSold.add(referralBonus);
    }

    require(newTokensSold <= hardCap);

    if (!softCapReached && newTokensSold >= softCap) {
      softCapReached = true;
      SoftCapReached(softCap);
    }

    collected = collected.add(msg.value);

    tokensSold = newTokensSold;

    deposited[msg.sender] = deposited[msg.sender].add(msg.value);

    token.transfer(msg.sender, tokens);
    NewContribution(msg.sender, tokens, msg.value);

    if (referralBonus > 0 && referral != 0x0) {
      token.transfer(referral, referralBonus);
      NewReferralTransfer(msg.sender, referral, referralBonus);
    }
  }

  function transferOwnership(address newOwner) onlyOwner icoEnded {
    super.transferOwnership(newOwner);
  }
}