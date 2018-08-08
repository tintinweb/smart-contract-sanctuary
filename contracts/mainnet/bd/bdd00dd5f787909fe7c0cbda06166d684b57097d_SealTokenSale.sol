pragma solidity ^0.4.13;

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

contract SealTokenSale is Pausable {
  using SafeMath for uint256;

  /**
  * @dev Supporter struct to allow tracking supporters KYC status and referrer address
  */
  struct Supporter {
    bool hasKYC;
    address referrerAddress;
  }

  /**
  * @dev External Supporter struct to allow tracking reserved amounts by supporter
  */
  struct ExternalSupporter {
    uint256 reservedAmount;
  }

  /**
   * @dev Token Sale States
   */
  enum TokenSaleState {Private, Pre, Main, Finished}

  // Variables
  mapping(address => Supporter) public supportersMap; // Mapping with all the Token Sale participants (Private excluded)
  mapping(address => ExternalSupporter) public externalSupportersMap; // Mapping with external supporters
  SealToken public token; // ERC20 Token contract address
  address public vaultWallet; // Wallet address to which ETH and Company Reserve Tokens get forwarded
  address public airdropWallet; // Wallet address to which Unsold Tokens get forwarded
  address public kycWallet; // Wallet address for the KYC server
  uint256 public tokensSold; // How many tokens have been sold
  uint256 public tokensReserved; // How many tokens have been reserved
  uint256 public maxTxGasPrice; // Maximum transaction gas price allowed for fair-chance transactions
  TokenSaleState public currentState; // current Sale state

  uint256 public constant ONE_MILLION = 10 ** 6; // One million for token cap calculation reference
  uint256 public constant PRE_SALE_TOKEN_CAP = 384 * ONE_MILLION * 10 ** 18; // Maximum amount that can be sold during the Pre Sale period
  uint256 public constant TOKEN_SALE_CAP = 492 * ONE_MILLION * 10 ** 18; // Maximum amount of tokens that can be sold by this contract
  uint256 public constant TOTAL_TOKENS_SUPPLY = 1200 * ONE_MILLION * 10 ** 18; // Total supply that will be minted
  uint256 public constant MIN_ETHER = 0.1 ether; // Minimum ETH Contribution allowed during the crowd sale

  /* Minimum PreSale Contributions in Ether */
  uint256 public constant PRE_SALE_MIN_ETHER = 1 ether; // Minimum to get 10% Bonus Tokens
  uint256 public constant PRE_SALE_15_BONUS_MIN = 60 ether; // Minimum to get 15% Bonus Tokens
  uint256 public constant PRE_SALE_20_BONUS_MIN = 300 ether; // Minimum to get 20% Bonus Tokens
  uint256 public constant PRE_SALE_30_BONUS_MIN = 1200 ether; // Minimum to get 30% Bonus Tokens

  /* Rate */
  uint256 public tokenBaseRate; // Base rate

  uint256 public referrerBonusRate; // Referrer Bonus Rate with 2 decimals (250 for 2.5% bonus for example)
  uint256 public referredBonusRate; // Referred Bonus Rate with 2 decimals (250 for 2.5% bonus for example)

  /**
    * @dev Modifier to only allow Owner or KYC Wallet to execute a function
    */
  modifier onlyOwnerOrKYCWallet() {
    require(msg.sender == owner || msg.sender == kycWallet);
    _;
  }

  /**
  * Event for token purchase logging
  * @param purchaser The wallet address that bought the tokens
  * @param value How many Weis were paid for the purchase
  * @param amount The amount of tokens purchased
  */
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  /**
  * Event for token reservation 
  * @param wallet The beneficiary wallet address
  * @param amount The amount of tokens
  */
  event TokenReservation(address indexed wallet, uint256 amount);

  /**
  * Event for token reservation confirmation
  * @param wallet The beneficiary wallet address
  * @param amount The amount of tokens
  */
  event TokenReservationConfirmation(address indexed wallet, uint256 amount);

  /**
  * Event for token reservation cancellation
  * @param wallet The beneficiary wallet address
  * @param amount The amount of tokens
  */
  event TokenReservationCancellation(address indexed wallet, uint256 amount);

  /**
   * Event for kyc status change logging
   * @param user User address
   * @param isApproved KYC approval state
   */
  event KYC(address indexed user, bool isApproved);

  /**
   * Event for referrer set
   * @param user User address
   * @param referrerAddress Referrer address
   */
  event ReferrerSet(address indexed user, address indexed referrerAddress);

  /**
   * Event for referral bonus incomplete
   * @param userAddress User address
   * @param missingAmount Missing Amount
   */
  event ReferralBonusIncomplete(address indexed userAddress, uint256 missingAmount);

  /**
   * Event for referral bonus minted
   * @param userAddress User address
   * @param amount Amount minted
   */
  event ReferralBonusMinted(address indexed userAddress, uint256 amount);

  /**
   * Constructor
   * @param _vaultWallet Vault address
   * @param _airdropWallet Airdrop wallet address
   * @param _kycWallet KYC address
   * @param _tokenBaseRate Token Base rate (Tokens/ETH)
   * @param _referrerBonusRate Referrer Bonus rate (2 decimals, ex 250 for 2.5%)
   * @param _referredBonusRate Referred Bonus rate (2 decimals, ex 250 for 2.5%)
   * @param _maxTxGasPrice Maximum gas price allowed when buying tokens
   */
  function SealTokenSale(
    address _vaultWallet,
    address _airdropWallet,
    address _kycWallet,
    uint256 _tokenBaseRate,
    uint256 _referrerBonusRate,
    uint256 _referredBonusRate,
    uint256 _maxTxGasPrice
  )
  public
  {
    require(_vaultWallet != address(0));
    require(_airdropWallet != address(0));
    require(_kycWallet != address(0));
    require(_tokenBaseRate > 0);
    require(_referrerBonusRate > 0);
    require(_referredBonusRate > 0);
    require(_maxTxGasPrice > 0);

    vaultWallet = _vaultWallet;
    airdropWallet = _airdropWallet;
    kycWallet = _kycWallet;
    tokenBaseRate = _tokenBaseRate;
    referrerBonusRate = _referrerBonusRate;
    referredBonusRate = _referredBonusRate;
    maxTxGasPrice = _maxTxGasPrice;

    tokensSold = 0;
    tokensReserved = 0;

    token = new SealToken();

    // init sale state;
    currentState = TokenSaleState.Private;
  }

  /* fallback function can be used to buy tokens */
  function() public payable {
    buyTokens();
  }

  /* low level token purchase function */
  function buyTokens() public payable whenNotPaused {
    // Do not allow if gasprice is bigger than the maximum
    // This is for fair-chance for all contributors, so no one can
    // set a too-high transaction price and be able to buy earlier
    require(tx.gasprice <= maxTxGasPrice);

    // make sure we&#39;re in pre or main sale period
    require(isPublicTokenSaleRunning());

    // check if KYC ok
    require(userHasKYC(msg.sender));

    // check user is sending enough Wei for the stage&#39;s rules
    require(aboveMinimumPurchase());

    address sender = msg.sender;
    uint256 weiAmountSent = msg.value;

    // calculate token amount
    uint256 bonusMultiplier = getBonusMultiplier(weiAmountSent);
    uint256 newTokens = weiAmountSent.mul(tokenBaseRate).mul(bonusMultiplier).div(100);

    // check totals and mint the tokens
    checkTotalsAndMintTokens(sender, newTokens, false);

    // Log Event
    TokenPurchase(sender, weiAmountSent, newTokens);

    // forward the funds to the vault wallet
    vaultWallet.transfer(msg.value);
  }

  /**
  * @dev Reserve Tokens
  * @param _wallet Destination Address
  * @param _amount Amount of tokens
  */
  function reserveTokens(address _wallet, uint256 _amount) public onlyOwner {
    // check amount positive
    require(_amount > 0);
    // check destination address not null
    require(_wallet != address(0));

    // make sure that we&#39;re in private sale or presale
    require(isPrivateSaleRunning() || isPreSaleRunning());

    // check cap
    uint256 totalTokensReserved = tokensReserved.add(_amount);
    require(tokensSold + totalTokensReserved <= PRE_SALE_TOKEN_CAP);

    // update total reserved
    tokensReserved = totalTokensReserved;

    // save user reservation
    externalSupportersMap[_wallet].reservedAmount = externalSupportersMap[_wallet].reservedAmount.add(_amount);

    // Log Event
    TokenReservation(_wallet, _amount);
  }

  /**
  * @dev Confirm Reserved Tokens
  * @param _wallet Destination Address
  * @param _amount Amount of tokens
  */
  function confirmReservedTokens(address _wallet, uint256 _amount) public onlyOwner {
    // check amount positive
    require(_amount > 0);
    // check destination address not null
    require(_wallet != address(0));

    // make sure the sale hasn&#39;t ended yet
    require(!hasEnded());

    // check amount not more than reserved
    require(_amount <= externalSupportersMap[_wallet].reservedAmount);

    // check totals and mint the tokens
    checkTotalsAndMintTokens(_wallet, _amount, true);

    // Log Event
    TokenReservationConfirmation(_wallet, _amount);
  }

  /**
   * @dev Cancel Reserved Tokens
   * @param _wallet Destination Address
   * @param _amount Amount of tokens
   */
  function cancelReservedTokens(address _wallet, uint256 _amount) public onlyOwner {
    // check amount positive
    require(_amount > 0);
    // check destination address not null
    require(_wallet != address(0));

    // make sure the sale hasn&#39;t ended yet
    require(!hasEnded());

    // check amount not more than reserved
    require(_amount <= externalSupportersMap[_wallet].reservedAmount);

    // update total reserved
    tokensReserved = tokensReserved.sub(_amount);

    // update user reservation
    externalSupportersMap[_wallet].reservedAmount = externalSupportersMap[_wallet].reservedAmount.sub(_amount);

    // Log Event
    TokenReservationCancellation(_wallet, _amount);
  }

  /**
  * @dev Check totals and Mint tokens
  * @param _wallet Destination Address
  * @param _amount Amount of tokens
  */
  function checkTotalsAndMintTokens(address _wallet, uint256 _amount, bool _fromReservation) private {
    // check that we have not yet reached the cap
    uint256 totalTokensSold = tokensSold.add(_amount);

    uint256 totalTokensReserved = tokensReserved;
    if (_fromReservation) {
      totalTokensReserved = totalTokensReserved.sub(_amount);
    }

    if (isMainSaleRunning()) {
      require(totalTokensSold + totalTokensReserved <= TOKEN_SALE_CAP);
    } else {
      require(totalTokensSold + totalTokensReserved <= PRE_SALE_TOKEN_CAP);
    }

    // update contract state
    tokensSold = totalTokensSold;

    if (_fromReservation) {
      externalSupportersMap[_wallet].reservedAmount = externalSupportersMap[_wallet].reservedAmount.sub(_amount);
      tokensReserved = totalTokensReserved;
    }

    // mint the tokens
    token.mint(_wallet, _amount);

    address userReferrer = getUserReferrer(_wallet);

    if (userReferrer != address(0)) {
      // Mint Referrer bonus
      mintReferralShare(_amount, userReferrer, referrerBonusRate);

      // Mint Referred bonus
      mintReferralShare(_amount, _wallet, referredBonusRate);
    }
  }

  /**
   * @dev Mint Referral Share
   * @param _amount Amount of tokens
   * @param _userAddress User Address
   * @param _bonusRate Bonus rate (2 decimals)
   */
  function mintReferralShare(uint256 _amount, address _userAddress, uint256 _bonusRate) private {
    // calculate max tokens available
    uint256 currentCap;

    if (isMainSaleRunning()) {
      currentCap = TOKEN_SALE_CAP;
    } else {
      currentCap = PRE_SALE_TOKEN_CAP;
    }

    uint256 maxTokensAvailable = currentCap - tokensSold - tokensReserved;

    // check if we have enough tokens
    uint256 fullShare = _amount.mul(_bonusRate).div(10000);
    if (fullShare <= maxTokensAvailable) {
      // mint the tokens
      token.mint(_userAddress, fullShare);

      // update state
      tokensSold = tokensSold.add(fullShare);

      // log event
      ReferralBonusMinted(_userAddress, fullShare);
    }
    else {
      // mint the available tokens
      token.mint(_userAddress, maxTokensAvailable);

      // update state
      tokensSold = tokensSold.add(maxTokensAvailable);

      // log events

      ReferralBonusMinted(_userAddress, maxTokensAvailable);
      ReferralBonusIncomplete(_userAddress, fullShare - maxTokensAvailable);
    }
  }

  /**
  * @dev Start Presale
  */
  function startPreSale() public onlyOwner {
    // make sure we&#39;re in the private sale state
    require(currentState == TokenSaleState.Private);

    // move to presale
    currentState = TokenSaleState.Pre;
  }

  /**
  * @dev Go back to private sale
  */
  function goBackToPrivateSale() public onlyOwner {
    // make sure we&#39;re in the pre sale
    require(currentState == TokenSaleState.Pre);

    // go back to private
    currentState = TokenSaleState.Private;
  }

  /**
  * @dev Start Main sale
  */
  function startMainSale() public onlyOwner {
    // make sure we&#39;re in the presale state
    require(currentState == TokenSaleState.Pre);

    // move to main sale
    currentState = TokenSaleState.Main;
  }

  /**
  * @dev Go back to Presale
  */
  function goBackToPreSale() public onlyOwner {
    // make sure we&#39;re in the main sale
    require(currentState == TokenSaleState.Main);

    // go back to presale
    currentState = TokenSaleState.Pre;
  }

  /**
  * @dev Ends the operation of the contract
  */
  function finishContract() public onlyOwner {
    // make sure we&#39;re in the main sale
    require(currentState == TokenSaleState.Main);

    // make sure there are no pending reservations
    require(tokensReserved == 0);

    // mark sale as finished
    currentState = TokenSaleState.Finished;

    // send the unsold tokens to the airdrop wallet
    uint256 unsoldTokens = TOKEN_SALE_CAP.sub(tokensSold);
    token.mint(airdropWallet, unsoldTokens);

    // send the company reserve tokens to the vault wallet
    uint256 notForSaleTokens = TOTAL_TOKENS_SUPPLY.sub(TOKEN_SALE_CAP);
    token.mint(vaultWallet, notForSaleTokens);

    // finish the minting of the token, so that transfers are allowed
    token.finishMinting();

    // transfer ownership of the token contract to the owner,
    // so it isn&#39;t locked to be a child of the crowd sale contract
    token.transferOwnership(owner);
  }

  /**
  * @dev Updates the maximum allowed gas price that can be used when calling buyTokens()
  * @param _newMaxTxGasPrice The new maximum gas price
  */
  function updateMaxTxGasPrice(uint256 _newMaxTxGasPrice) public onlyOwner {
    require(_newMaxTxGasPrice > 0);
    maxTxGasPrice = _newMaxTxGasPrice;
  }

  /**
   * @dev Updates the token baserate
   * @param _tokenBaseRate The new token baserate in tokens/eth
   */
  function updateTokenBaseRate(uint256 _tokenBaseRate) public onlyOwner {
    require(_tokenBaseRate > 0);
    tokenBaseRate = _tokenBaseRate;
  }

  /**
   * @dev Updates the Vault Wallet address
   * @param _vaultWallet The new vault wallet
   */
  function updateVaultWallet(address _vaultWallet) public onlyOwner {
    require(_vaultWallet != address(0));
    vaultWallet = _vaultWallet;
  }

  /**
   * @dev Updates the KYC Wallet address
   * @param _kycWallet The new kyc wallet
   */
  function updateKYCWallet(address _kycWallet) public onlyOwner {
    require(_kycWallet != address(0));
    kycWallet = _kycWallet;
  }

  /**
  * @dev Approve user&#39;s KYC
  * @param _user User Address
  */
  function approveUserKYC(address _user) onlyOwnerOrKYCWallet public {
    require(_user != address(0));

    Supporter storage sup = supportersMap[_user];
    sup.hasKYC = true;
    KYC(_user, true);
  }

  /**
   * @dev Disapprove user&#39;s KYC
   * @param _user User Address
   */
  function disapproveUserKYC(address _user) onlyOwnerOrKYCWallet public {
    require(_user != address(0));

    Supporter storage sup = supportersMap[_user];
    sup.hasKYC = false;
    KYC(_user, false);
  }

  /**
   * @dev Approve user&#39;s KYC and sets referrer
   * @param _user User Address
   * @param _referrerAddress Referrer Address
   */
  function approveUserKYCAndSetReferrer(address _user, address _referrerAddress) onlyOwnerOrKYCWallet public {
    require(_user != address(0));

    Supporter storage sup = supportersMap[_user];
    sup.hasKYC = true;
    sup.referrerAddress = _referrerAddress;

    // log events
    KYC(_user, true);
    ReferrerSet(_user, _referrerAddress);
  }

  /**
  * @dev check if private sale is running
  */
  function isPrivateSaleRunning() public view returns (bool) {
    return (currentState == TokenSaleState.Private);
  }

  /**
  * @dev check if pre sale or main sale are running
  */
  function isPublicTokenSaleRunning() public view returns (bool) {
    return (isPreSaleRunning() || isMainSaleRunning());
  }

  /**
  * @dev check if pre sale is running
  */
  function isPreSaleRunning() public view returns (bool) {
    return (currentState == TokenSaleState.Pre);
  }

  /**
  * @dev check if main sale is running
  */
  function isMainSaleRunning() public view returns (bool) {
    return (currentState == TokenSaleState.Main);
  }

  /**
  * @dev check if sale has ended
  */
  function hasEnded() public view returns (bool) {
    return (currentState == TokenSaleState.Finished);
  }

  /**
  * @dev Check if user has passed KYC
  * @param _user User Address
  */
  function userHasKYC(address _user) public view returns (bool) {
    return supportersMap[_user].hasKYC;
  }

  /**
  * @dev Get User&#39;s referrer address
  * @param _user User Address
  */
  function getUserReferrer(address _user) public view returns (address) {
    return supportersMap[_user].referrerAddress;
  }

  /**
  * @dev Get User&#39;s reserved amount
  * @param _user User Address
  */
  function getReservedAmount(address _user) public view returns (uint256) {
    return externalSupportersMap[_user].reservedAmount;
  }

  /**
   * @dev Returns the bonus multiplier to calculate the purchase rate
   * @param _weiAmount Purchase amount
   */
  function getBonusMultiplier(uint256 _weiAmount) internal view returns (uint256) {
    if (isMainSaleRunning()) {
      return 100;
    }
    else if (isPreSaleRunning()) {
      if (_weiAmount >= PRE_SALE_30_BONUS_MIN) {
        // 30% bonus
        return 130;
      }
      else if (_weiAmount >= PRE_SALE_20_BONUS_MIN) {
        // 20% bonus
        return 120;
      }
      else if (_weiAmount >= PRE_SALE_15_BONUS_MIN) {
        // 15% bonus
        return 115;
      }
      else if (_weiAmount >= PRE_SALE_MIN_ETHER) {
        // 10% bonus
        return 110;
      }
      else {
        // Safeguard but this should never happen as aboveMinimumPurchase checks the minimum
        revert();
      }
    }
  }

  /**
   * @dev Check if the user is buying above the required minimum
   */
  function aboveMinimumPurchase() internal view returns (bool) {
    if (isMainSaleRunning()) {
      return msg.value >= MIN_ETHER;
    }
    else if (isPreSaleRunning()) {
      return msg.value >= PRE_SALE_MIN_ETHER;
    } else {
      return false;
    }
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract SealToken is MintableToken {
    // Constants
    string public constant name = "SealToken";
    string public constant symbol = "SEAL";
    uint8 public constant decimals = 18;

    /**
    * @dev Modifier to only allow transfers after the minting has been done
    */
    modifier onlyWhenTransferEnabled() {
        require(mintingFinished);
        _;
    }

    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

    function SealToken() public {
    }

    function transferFrom(address _from, address _to, uint256 _value) public        
        onlyWhenTransferEnabled
        validDestination(_to)         
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public
        onlyWhenTransferEnabled         
        returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval (address _spender, uint _addedValue) public
        onlyWhenTransferEnabled         
        returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        onlyWhenTransferEnabled         
        returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenTransferEnabled
        validDestination(_to)         
        returns (bool) {
        return super.transfer(_to, _value);
    }
}