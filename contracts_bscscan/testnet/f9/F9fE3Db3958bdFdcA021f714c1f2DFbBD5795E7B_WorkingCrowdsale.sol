pragma solidity ^0.4.23;

//import "./Crowdsale.sol";
import "./ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title WorkingCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WorkingCrowdsale is Ownable {
  using SafeMath for uint256;
  
  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );
  
  
  mapping(address => bool) public whitelist;
  
  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps_max;
  mapping(address => uint256) public caps_min;

  mapping(address => uint256) public balances;
  
  uint256 public openingTime;
  uint256 public closingTime;


  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }
  
  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token,uint256 _openingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;

    openingTime = _openingTime;
    closingTime = _openingTime + (12 hours);
  }
  
  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }
  

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
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
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }
  
  /**
   * @dev Sets a specific user's maximum contribution.
   * @param _beneficiary Address to be capped
   */
  function setUserCap(address _beneficiary, uint256 _cap_max, uint256 _cap_min) external onlyOwner {
    caps_max[_beneficiary] = _cap_max;
    caps_min[_beneficiary] = _cap_min;
  }

  /**
   * @dev Sets a group of users' maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   */
  function setGroupCap(
    address[] _beneficiaries,
    uint256 _cap_max,
    uint256 _cap_min
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      caps_max[_beneficiaries[i]] = _cap_max;
      caps_min[_beneficiaries[i]] = _cap_min;
    }
  }

  /**
   * @dev Returns the cap of a specific user.
   * @param _beneficiary Address whose cap is to be checked
   * @return Current cap for individual user
   */
  function getUserCapMax(address _beneficiary) public view returns (uint256) {
    return caps_max[_beneficiary];
  }

  function getUserCapMin(address _beneficiary) public view returns (uint256) {
    return caps_min[_beneficiary];
  }

  /**
   * @dev Returns the amount contributed so far by a sepecific user.
   * @param _beneficiary Address of contributor
   * @return User contribution so far
   */
  function getUserContribution(address _beneficiary)
    public view returns (uint256)
  {
    return contributions[_beneficiary];
  }
  
  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  function hasClosed_plus_30d() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime + (30 days);
  }

  function hasClosed_plus_60d() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime + (60 days);
  }

  function hasClosed_plus_90d() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime + (90 days);
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   */
  function withdrawTokens() public {
    require(hasClosed());
    uint256 amount = balances[msg.sender] / 4;
    require(amount > 0);
    //balances[msg.sender] = 0;
    _deliverTokens(msg.sender, _getTokenAmount(amount));
  }
  
    function withdrawTokens_a_30() public {
    require(hasClosed_plus_30d());
    uint256 amount = balances[msg.sender] / 4;
    require(amount > 0);
    //balances[msg.sender] = 0;
    _deliverTokens(msg.sender, _getTokenAmount(amount));
  }

    function withdrawTokens_a_60() public {
    require(hasClosed_plus_60d());
    uint256 amount = balances[msg.sender] / 4;
    require(amount > 0);
    //balances[msg.sender] = 0;
    _deliverTokens(msg.sender, _getTokenAmount(amount));
  }

    function withdrawTokens_a_90() public {
    require(hasClosed_plus_90d());
    uint256 amount = balances[msg.sender] / 4;
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, _getTokenAmount(amount));
  }
  
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
    onlyWhileOpen
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(contributions[_beneficiary].add(_weiAmount) <= caps_max[_beneficiary]);
    require(_weiAmount > caps_min[_beneficiary]);

  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

  /**
   * @dev Extend parent behavior to update user contributions
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }
  
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }
  
    /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }
  
    /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}