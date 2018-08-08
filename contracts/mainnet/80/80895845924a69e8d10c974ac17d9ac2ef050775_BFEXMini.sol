pragma solidity 0.4.24;


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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



contract BFEXMini is Ownable {

  using SafeMath for uint256;

  // Start and end timestamps
  uint public startTime;
  /* uint public endTime; */

  // BFEX Address where funds are collected
  address public wallet;
  address public feeWallet;

  // Whitelist Enable
  bool public whitelistEnable;

  // timeLimitEnable Enable
  bool public timeLimitEnable;

  mapping (address => bool) public whitelist;
  mapping (address => uint256) public bfexAmount; // 18 digits
  mapping (address => uint256) public weiParticipate;
  mapping (address => uint256) public balances;

  // Amount of wei raised
  uint256 public weiRaised = 0;

  // BFEX price pair with ETH
  uint256 public rate;
  uint256 public rateSecondTier;

  // Minimum ETH to participate
  uint256 public minimum;

  // number of contributor
  uint256 public contributor;

  // Maximun number of contributor
  uint256 public maxContributor;

  event BFEXParticipate(
    address sender,
    uint256 amount
  );

  event WhitelistState(
    address beneficiary,
    bool whitelistState
  );

  event LogWithdrawal(
    address receiver,
    uint amount
  );

  /* solhint-disable */
  constructor(address _wallet, address _feeWallet, uint256 _rate, uint256 _rateSecondTier, uint256 _minimum) public {

    require(_wallet != address(0));

    wallet = _wallet;
    feeWallet = _feeWallet;
    rate = _rate;
    rateSecondTier = _rateSecondTier;
    minimum = _minimum;
    whitelistEnable = true;
    timeLimitEnable = true;
    contributor = 0;
    maxContributor = 10001;
    startTime = 1528625400; // 06/10/2018 @ 10:10am (UTC)
  }
  /* solhint-enable */

  /**
   * @dev Fallback function that can be used to participate in token generation event.
   */
  function() external payable {
    getBFEX(msg.sender);
  }

  /**
   * @dev set rate of Token per 1 ETH
   * @param _rate of Token per 1 ETH
   */
  function setRate(uint _rate) public onlyOwner {
    rate = _rate;
  }

  /**
   * @dev setMinimum amount to participate
   * @param _minimum minimum amount in wei
   */
  function setMinimum(uint256 _minimum) public onlyOwner {
    minimum = _minimum;
  }

  /**
   * @dev setMinimum amount to participate
   * @param _max Maximum contributor allowed
   */
  function setMaxContributor(uint256 _max) public onlyOwner {
    maxContributor = _max;
  }

  /**
   * @dev Add single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
    emit WhitelistState(_beneficiary, true);
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Remove single address from whitelist.
   * @param _beneficiary Address to be removed from the whitelist
   */
  function removeFromWhiteList(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    emit WhitelistState(_beneficiary, false);
  }

  function isWhitelist(address _beneficiary) public view returns (bool whitelisted) {
    return whitelist[_beneficiary];
  }

  function checkBenefit(address _beneficiary) public view returns (uint256 bfex) {
    return bfexAmount[_beneficiary];
  }

  function checkContribution(address _beneficiary) public view returns (uint256 weiContribute) {
    return weiParticipate[_beneficiary];
  }
  /**
  * @dev getBfex function
  * @param _participant Address performing the bfex token participate
  */
  function getBFEX(address _participant) public payable {

    uint256 weiAmount = msg.value;

    _preApprove(_participant);
    require(_participant != address(0));
    require(weiAmount >= minimum);

    // calculate bfex token _participant will recieve
    uint256 bfexToken = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    // update ETH balance
    uint256 raise = weiAmount.div(1000).mul(955);
    uint256 fee = weiAmount.div(1000).mul(45);
    // update contributor count
    contributor += 1;

    balances[wallet] = balances[wallet].add(raise);
    balances[feeWallet] = balances[feeWallet].add(fee);

    bfexAmount[_participant] = bfexAmount[_participant].add(bfexToken);
    weiParticipate[_participant] = weiParticipate[_participant].add(weiAmount);

    emit BFEXParticipate(_participant, weiAmount);
  }

  /**
  * @dev calculate token amont
  * @param _weiAmount wei amont user are participate
  */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _rate;
    if (_weiAmount >= 0.1 ether && _weiAmount < 1 ether ) {
      _rate = rate;
    } else if (_weiAmount >= 1 ether ) {
      _rate = rateSecondTier;
    }
    uint256 bfex = _weiAmount.mul(_rate);
    /* bfex = bfex.div(1 ether); */
    return bfex;
  }

  /**
  * @dev check if address is on the whitelist
  * @param _participant address
  */
  function _preApprove(address _participant) internal view {
    require (maxContributor >= contributor);
    if (timeLimitEnable == true) {
      require (now >= startTime && now <= startTime + 1 days);
    }
    if (whitelistEnable == true) {
      require(isWhitelist(_participant));
      return;
    } else {
      return;
    }
  }

  /**
  * @dev disable whitelist state
  *
  */
  function disableWhitelist() public onlyOwner returns (bool whitelistState) {
    whitelistEnable = false;
    emit WhitelistState(msg.sender, whitelistEnable);
    return whitelistEnable;
  }

  /**
  * @dev enable whitelist state
  *
  */
  function enableWhitelist() public onlyOwner returns (bool whitelistState) {
    whitelistEnable = true;
    emit WhitelistState(msg.sender, whitelistEnable);
    return whitelistEnable;
  }

  function withdraw(uint _value) public returns (bool success) {
    require(balances[msg.sender] <= _value);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    msg.sender.transfer(_value);
    emit LogWithdrawal(msg.sender, _value);

    return true;
  }

  function checkBalance(address _account) public view returns (uint256 balance)  {
    return balances[_account];
  }
}