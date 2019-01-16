pragma solidity ^0.4.24;

interface Token {
  function name() external view returns (string n);
  function totalSupply() external view returns (uint totalSupplyValue);
  function balanceOf(address _owner) external view returns (uint balance);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
  function transfer(address _to, uint _value) external returns (bool success);
  function approve(address _spender, uint _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);

  function increaseApproval(address _spender, uint _addedValue) external returns (bool success);
  function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool success);

  function cap() external view returns (uint256 capValue);

  function paused() external view returns (bool isPaused);
  function pause() external;
  function unpause() external;

  function mintingFinished() external view returns (bool isMintingFinished);
  function finishMinting() external returns (bool success);
  function mint(address _to, uint256 _amount) external returns (bool success);

  function transferOwnership(address newOwner) external;

  function decimals() external view returns (uint256 _decimals);
  function decimalsFactor() external view returns (uint256 _decimalsFactor);
}


contract AraniumTokensale {
  using SafeMath for uint;

  uint public constant MILLION = 1000000;
  string public version = "0.0.1";

  bool public isFinalized = false;

  address tokenAddr;
  Token public token;
  uint256 public decimals;
  uint256 public decimalsFactor;
  address public owner;
  bool public paused = false;

  uint256 public crowdsaleCap;
  uint256 public priceWei;
  uint256 public totalWeiRaised;
  uint256 public totalTokensRaised;
  uint256 public numOfPhases;
  address public crowdsaleWallet;
  address public treasuryWallet;
  address public bootstrapPartnersWallet;
  address public marketingWallet;

  mapping(address => bool) public whitelist;
  mapping(address => uint256) public contributions; // -- wei
  mapping(address => uint256) public userAllocMin;
  mapping(address => uint256) public userAllocMax;

  uint256 public dummy; // -- test


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }


  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event ChangeFromPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Pause();
  event Unpause();
  event Finalized();


  constructor() public {
    // -- address _tokenAddr, uint256 _priceWei, address _crowdsaleWallet, address _treasuryWallet, address _bootstrapPartnersWallet, address _marketingWallet
    //require(_tokenAddr != address(0));
    //require(_crowdsaleWallet != address(0));
    //require(_treasuryWallet != address(0));
    //require(_bootstrapPartnersWallet != address(0));
    //require(_marketingWallet != address(0));
    //require(_priceWei > 0);

    owner = msg.sender;

    priceWei = 10000000000000000;
    //priceWei = 22133001633410;

    tokenAddr = 0xdbdf878665a348c205fe214e55bb4d4d33b335e2;
    //tokenAddr = 0x330D0519e59DBaC8911Ec24c4A022BD0fA7092CC; // -- local
    token = Token(tokenAddr);
    decimals = token.decimals();
    decimalsFactor = token.decimalsFactor();

    crowdsaleCap = 1330000000 * decimalsFactor;

    crowdsaleWallet = 0xd183089d7dE16CcE45A16f4b46af2F13d8ffa360;
    //crowdsaleWallet = 0x575e92A27486994c4d30C4908D85b963CE631366; // -- local

    /* -- Commented for testing.
    treasuryWallet = _treasuryWallet;
    bootstrapPartnersWallet = _bootstrapPartnersWallet;
    marketingWallet = _marketingWallet;
    token.mint(treasuryWallet, 2900000000);
    token.mint(bootstrapPartnersWallet, 820000000);
    token.mint(marketingWallet, 820000000);
    */
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  function addToWhitelist(address _beneficiary, uint _userAllocMin, uint _userAllocMax) external onlyOwner {
    require(whitelist[_beneficiary] != true);
    whitelist[_beneficiary] = true;
    userAllocMin[_beneficiary] = _userAllocMin;
    userAllocMax[_beneficiary] = _userAllocMax;
  }

  function addManyToWhitelist(address[] _beneficiaries, uint[] _userAllocMins, uint[] _userAllocMaxs) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      require(whitelist[_beneficiaries[i]] != true);
      whitelist[_beneficiaries[i]] = true;
      userAllocMin[_beneficiaries[i]] = _userAllocMins[i];
      userAllocMax[_beneficiaries[i]] = _userAllocMaxs[i];
    }
  }

  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    delete userAllocMin[_beneficiary];
    delete userAllocMax[_beneficiary];
  }

  function setUserAllocMin(address _beneficiary, uint256 _min) external onlyOwner {
    userAllocMin[_beneficiary] = _min;
  }

  function setUserAllocMax(address _beneficiary, uint256 _max) external onlyOwner {
    userAllocMax[_beneficiary] = _max;
  }

  function setUserAlloc(address _beneficiary, uint256 _min, uint _max) external onlyOwner {
    userAllocMin[_beneficiary] = _min;
    userAllocMax[_beneficiary] = _max;
  }

  function setUserAllocs(address[] _beneficiaries, uint256 _min, uint256 _max) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      userAllocMin[_beneficiaries[i]] = _min;
      userAllocMax[_beneficiaries[i]] = _max;
    }
  }

  function getUserRemainingAlloc(address _beneficiary) public view returns (uint256) {
    return userAllocMax[_beneficiary].sub(contributions[_beneficiary]);
  }

  function setPriceWei(uint _priceWei) public onlyOwner {
    require(_priceWei > 0);
    priceWei = _priceWei;
  }

  function() external payable {
    buyTokens(msg.sender, msg.value);
  }

  function buyTokens(address _beneficiary, uint _weiAmount) internal whenNotPaused isWhitelisted(_beneficiary) {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(contributions[_beneficiary].add(_weiAmount) >= userAllocMin[_beneficiary]);

    uint256 weiAmt = 0;
    uint256 changeAmt = 0;
    if (contributions[_beneficiary].add(_weiAmount) > userAllocMax[_beneficiary]) {
      weiAmt = userAllocMax[_beneficiary].sub(contributions[_beneficiary]);
      changeAmt = _weiAmount.sub(weiAmt);
    } else {
      weiAmt = _weiAmount;
    }

    uint256 tokens = weiAmt.mul(decimalsFactor).div(priceWei);
    require((totalTokensRaised.add(tokens)) < crowdsaleCap);

    token.mint(_beneficiary, tokens);
    totalWeiRaised = totalWeiRaised.add(weiAmt);
    totalTokensRaised = totalTokensRaised.add(tokens);
    contributions[_beneficiary] = contributions[_beneficiary].add(weiAmt);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmt, tokens);

    crowdsaleWallet.transfer(weiAmt);

    if (changeAmt > 0) {
      emit ChangeFromPurchase(msg.sender, _beneficiary, changeAmt);
      _beneficiary.transfer(changeAmt);
    }
  }


  function crowdsaleBalance() public view returns(uint) {
    return crowdsaleCap.sub(totalTokensRaised);
  }

  /**
   * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
   * This will prevent any accidental loss of tokens.
   * This can be used after the sale is over and tokens are unpaused.
   */
  function reclaimTokens() external onlyOwner {
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
  }

  // Must be called after crowdsale ends, to do some extra finalization
  function finalize() onlyOwner public {
    require(!isFinalized);

    doFinalize();
    emit Finalized();

    isFinalized = true;
    paused = true;
  }

  // Stops the minting and transfer token ownership to sale owner. Mints unsold tokens to owner
  function doFinalize() internal {
    token.mint(owner, crowdsaleBalance());
    token.finishMinting();
    token.transferOwnership(owner);
  }


  function setDummy(uint _w) public onlyOwner returns (uint) {
    dummy = _w.add(2); // -- test SafeMath
    return dummy;
  }

  function getTokenName() public view returns (string) {
    return token.name();
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