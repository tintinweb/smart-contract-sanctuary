pragma solidity 0.4.21;

// ----------------------------------------------------------------------------
// &#39;Digitize Coin Presale&#39; contract: https://digitizecoin.com 
//
// Digitize Coin - DTZ: 0x664e6db4044f23c95de63ec299aaa9b39c59328d
// SoftCap: 600 ether
// HardCap: 4000 ether - 26668000 tokens
// Tokens per 1 ether: 6667
// KYC: PICOPS https://picops.parity.io
//
// (c) Radek Ostrowski / http://startonchain.com - The MIT Licence.
// ----------------------------------------------------------------------------

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
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
    require(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------
// RefundVault for &#39;Digitize Coin&#39; project imported from:
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/crowdsale/distribution/utils/RefundVault.sol
//
// Radek Ostrowski / http://startonchain.com / https://digitizecoin.com 
// ----------------------------------------------------------------------------

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it to destination wallet if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed _beneficiary, uint256 _weiAmount);

  /**
   * @param _wallet Final vault address
   */
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param _contributor Contributor address
   */
  function deposit(address _contributor) onlyOwner public payable {
    require(state == State.Active);
    deposited[_contributor] = deposited[_contributor].add(msg.value); 
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param _contributor Contributor address
   */
  function refund(address _contributor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[_contributor];
    require(depositedValue > 0);
    deposited[_contributor] = 0;
    _contributor.transfer(depositedValue);
    emit Refunded(_contributor, depositedValue);
  }
}

/**
 * @title CutdownToken
 * @dev Some ERC20 interface methods used in this contract
 */
contract CutdownToken {
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

/**
 * @title Parity PICOPS Whitelist
 */
contract PICOPSCertifier {
    function certified(address) public constant returns (bool);
}

/**
 * @title DigitizeCoinPresale
 * @dev Desired amount of DigitizeCoin tokens for this sale must be allocated 
 * to this contract address prior to the sale start
 */
contract DigitizeCoinPresale is Ownable {
  using SafeMath for uint256;

  // token being sold
  CutdownToken public token;
  // KYC
  PICOPSCertifier public picopsCertifier;
  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  // start and end timestamps where contributions are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;
  uint256 public softCap;
  bool public hardCapReached;

  mapping(address => bool) public whitelist;

  // how many token units a buyer gets per wei
  uint256 public constant rate = 6667;

  // amount of raised money in wei
  uint256 public weiRaised;

  // amount of total contribution for each address
  mapping(address => uint256) public contributed;

  // minimum amount of ether allowed, inclusive
  uint256 public constant minContribution = 0.1 ether;

  // maximum contribution without KYC, exclusive
  uint256 public constant maxAnonymousContribution = 5 ether;

  /**
   * Custom events
   */
  event TokenPurchase(address indexed _purchaser, uint256 _value, uint256 _tokens);
  event PicopsCertifierUpdated(address indexed _oldCertifier, address indexed _newCertifier);
  event AddedToWhitelist(address indexed _who);
  event RemovedFromWhitelist(address indexed _who);
  event WithdrawnERC20Tokens(address indexed _tokenContract, address indexed _owner, uint256 _balance);
  event WithdrawnEther(address indexed _owner, uint256 _balance);

  // constructor
  function DigitizeCoinPresale(uint256 _startTime, uint256 _durationInDays, 
    uint256 _softCap, address _wallet, CutdownToken _token, address _picops) public {
    bool validTimes = _startTime >= now && _durationInDays > 0;
    bool validAddresses = _wallet != address(0) && _token != address(0) && _picops != address(0);
    require(validTimes && validAddresses);

    owner = msg.sender;
    startTime = _startTime;
    endTime = _startTime + (_durationInDays * 1 days);
    softCap = _softCap;
    token = _token;
    vault = new RefundVault(_wallet);
    picopsCertifier = PICOPSCertifier(_picops);
  }

  // fallback function used to buy tokens
  function () external payable {
    require(validPurchase());

    address purchaser = msg.sender;
    uint256 weiAmount = msg.value;
    uint256 chargedWeiAmount = weiAmount;
    uint256 tokensAmount = weiAmount.mul(rate);
    uint256 tokensDue = tokensAmount;
    uint256 tokensLeft = token.balanceOf(address(this));

    // if sending more then available, allocate all tokens and refund the rest of ether
    if(tokensAmount > tokensLeft) {
      chargedWeiAmount = tokensLeft.div(rate);
      tokensDue = tokensLeft;
      hardCapReached = true;
    } else if(tokensAmount == tokensLeft) {
      hardCapReached = true;
    }

    weiRaised = weiRaised.add(chargedWeiAmount);
    contributed[purchaser] = contributed[purchaser].add(chargedWeiAmount);
    token.transfer(purchaser, tokensDue);

    // refund if appropriate
    if(chargedWeiAmount < weiAmount) {
      purchaser.transfer(weiAmount - chargedWeiAmount);
    }
    emit TokenPurchase(purchaser, chargedWeiAmount, tokensDue);

    // forward funds to vault
    vault.deposit.value(chargedWeiAmount)(purchaser);
  }

  /**
   * @dev Checks whether funding soft cap was reached. 
   * @return Whether funding soft cap was reached
   */
  function softCapReached() public view returns (bool) {
    return weiRaised >= softCap;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime || hardCapReached;
  }

  function hasStarted() public view returns (bool) {
    return now >= startTime;
  }

  /**
   * @dev Contributors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(hasEnded() && !softCapReached());

    vault.refund(msg.sender);
  }

  /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalize() public onlyOwner {
    require(hasEnded());

    if (softCapReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = hasStarted() && !hasEnded();
    bool validContribution = msg.value >= minContribution;
    bool passKyc = picopsCertifier.certified(msg.sender);
    //check if contributor can possibly go over anonymous contibution limit
    bool anonymousAllowed = contributed[msg.sender].add(msg.value) < maxAnonymousContribution;
    bool allowedKyc = passKyc || anonymousAllowed;
    return withinPeriod && validContribution && allowedKyc;
  }

  // ability to set new certifier even after the sale started
  function setPicopsCertifier(address _picopsCertifier) onlyOwner public  {
    require(_picopsCertifier != address(picopsCertifier));
    emit PicopsCertifierUpdated(address(picopsCertifier), _picopsCertifier);
    picopsCertifier = PICOPSCertifier(_picopsCertifier);
  }

  function passedKYC(address _wallet) view public returns (bool) {
    return picopsCertifier.certified(_wallet);
  }

  // ability to add to whitelist even after the sale started
  function addToWhitelist(address[] _wallets) public onlyOwner {
    for (uint i = 0; i < _wallets.length; i++) {
      whitelist[_wallets[i]] = true;
      emit AddedToWhitelist(_wallets[i]);
    }
  }

  // ability to remove from whitelist even after the sale started
  function removeFromWhitelist(address[] _wallets) public onlyOwner {
    for (uint i = 0; i < _wallets.length; i++) {
      whitelist[_wallets[i]] = false;
      emit RemovedFromWhitelist(_wallets[i]);
    }
  }

  /**
   * @dev Allows to transfer out the ether balance that was forced into this contract, e.g with `selfdestruct`
   */
  function withdrawEther() onlyOwner public {
    require(hasEnded());
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0);
    owner.transfer(totalBalance);
    emit WithdrawnEther(owner, totalBalance);
  }
  
  /**
   * @dev Allows to transfer out the balance of arbitrary ERC20 tokens from the contract.
   * @param _token The contract address of the ERC20 token.
   */
  function withdrawERC20Tokens(CutdownToken _token) onlyOwner public {
    require(hasEnded());
    uint256 totalBalance = _token.balanceOf(address(this));
    require(totalBalance > 0);
    _token.transfer(owner, totalBalance);
    emit WithdrawnERC20Tokens(address(_token), owner, totalBalance);
  }
}