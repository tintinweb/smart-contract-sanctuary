pragma solidity ^0.4.23;


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


/**
 * @title ERC20 interface (only needed methods)
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title QWoodDAOTokenSale
 * @dev The QWoodDAOTokenSale contract receive ether and other foreign tokens and exchange them to set tokens.
 */
contract QWoodDAOTokenSale is Pausable {
  using SafeMath for uint256;


  // Represents data of foreign token which can be exchange to token
  struct ReceivedToken {
    // name of foreign token
    string name;

    // number of token units a buyer gets per foreign token unit
    uint256 rate;

    // amount of raised foreign tokens
    uint256 raised;
  }


  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a ERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Map from token address to token data
  mapping (address => ReceivedToken) public receivedTokens;


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

  /**
   * Event for token purchase for token logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value foreign tokens units paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenForTokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * Event for change rate logging
   * @param newRate new number of token units a buyer gets per wei
   */
  event ChangeRate(uint256 newRate);

  /**
   * Event for add received token logging
   * @param tokenAddress address of added foreign token
   * @param name name of added token
   * @param rate number of token units a buyer gets per added foreign token unit
   */
  event AddReceivedToken(
    address indexed tokenAddress,
    string name,
    uint256 rate
  );

  /**
   * Event for remove received token logging
   * @param tokenAddress address of removed foreign token
   */
  event RemoveReceivedToken(address indexed tokenAddress);

  /**
   * Event for set new received token rate logging
   * @param tokenAddress address of foreign token
   * @param newRate new number of token units a buyer gets per added foreign token unit
   */
  event SetReceivedTokenRate(
    address indexed tokenAddress,
    uint256 newRate
  );

  /**
   * Event for send excess ether logging
   * @param beneficiary who gets excess ether
   * @param value excess weis
   */
  event SendEtherExcess(
    address indexed beneficiary,
    uint256 value
  );

  /**
   * Event for send tokens excess logging
   * @param beneficiary who gets tokens excess
   * @param value excess token units
   */
  event SendTokensExcess(
    address indexed beneficiary,
    uint256 value
  );

  /**
   * Event for logging received tokens from approveAndCall function
   * @param from who send tokens
   * @param amount amount of received purchased
   * @param tokenAddress address of token contract
   * @param extraData data attached to payment
   */
  event ReceivedTokens(
    address indexed from,
    uint256 amount,
    address indexed tokenAddress,
    bytes extraData
  );


  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor (
    uint256 _rate,
    address _wallet,
    ERC20 _token
  )
    public
  {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }


  // -----------------------------------------
  // External interface
  // -----------------------------------------

  /**
 * @dev fallback function ***DO NOT OVERRIDE***
 */
  function () whenNotPaused external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) whenNotPaused public payable {
    require(_beneficiary != address(0));

    uint256 weiAmount = msg.value;
    require(weiAmount != 0);

    uint256 tokenBalance = token.balanceOf(address(this));
    require(tokenBalance > 0);

    uint256 tokens = _getTokenAmount(address(0), weiAmount);

    if (tokens > tokenBalance) {
      tokens = tokenBalance;
      weiAmount = _inverseGetTokenAmount(address(0), tokens);

      uint256 senderExcess = msg.value.sub(weiAmount);
      msg.sender.transfer(senderExcess);

      emit SendEtherExcess(
        msg.sender,
        senderExcess
      );
    }

    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
  }

  /**
   * @dev Sets new rate.
   * @param _newRate New number of token units a buyer gets per wei
   */
  function setRate(uint256 _newRate) onlyOwner external {
    require(_newRate > 0);
    rate = _newRate;

    emit ChangeRate(_newRate);
  }

  /**
   * @dev Set new wallet address.
   * @param _newWallet New address where collected funds will be forwarded to
   */
  function setWallet(address _newWallet) onlyOwner external {
    require(_newWallet != address(0));
    wallet = _newWallet;
  }

  /**
   * @dev Set new token address.
   * @param _newToken New address of the token being sold
   */
  function setToken(ERC20 _newToken) onlyOwner external {
    require(_newToken != address(0));
    token = _newToken;
  }

  /**
   * @dev Withdraws any tokens from this contract to wallet.
   * @param _tokenContract The address of the foreign token
   */
  function withdrawTokens(ERC20 _tokenContract) onlyOwner external {
    require(_tokenContract != address(0));

    uint256 amount = _tokenContract.balanceOf(address(this));
    _tokenContract.transfer(wallet, amount);
  }

  /**
   * @dev Withdraws all ether from this contract to wallet.
   */
  function withdraw() onlyOwner external {
    wallet.transfer(address(this).balance);
  }

  /**
   * @dev Adds received foreign token.
   * @param _tokenAddress Address of the foreign token being added
   * @param _tokenName Name of the foreign token
   * @param _tokenRate Number of token units a buyer gets per foreign token unit
   */
  function addReceivedToken(
    ERC20 _tokenAddress,
    string _tokenName,
    uint256 _tokenRate
  )
    onlyOwner
    external
  {
    require(_tokenAddress != address(0));
    require(_tokenRate > 0);

    ReceivedToken memory _token = ReceivedToken({
      name: _tokenName,
      rate: _tokenRate,
      raised: 0
    });

    receivedTokens[_tokenAddress] = _token;

    emit AddReceivedToken(
      _tokenAddress,
      _token.name,
      _token.rate
    );
  }

  /**
   * @dev Removes received foreign token.
   * @param _tokenAddress Address of the foreign token being removed
   */
  function removeReceivedToken(ERC20 _tokenAddress) onlyOwner external {
    require(_tokenAddress != address(0));

    delete receivedTokens[_tokenAddress];

    emit RemoveReceivedToken(_tokenAddress);
  }

  /**
   * @dev Sets new rate for received foreign token.
   * @param _tokenAddress Address of the foreign token
   * @param _newTokenRate New number of token units a buyer gets per foreign token unit
   */
  function setReceivedTokenRate(
    ERC20 _tokenAddress,
    uint256 _newTokenRate
  )
    onlyOwner
    external
  {
    require(_tokenAddress != address(0));
    require(receivedTokens[_tokenAddress].rate > 0);
    require(_newTokenRate > 0);

    receivedTokens[_tokenAddress].rate = _newTokenRate;

    emit SetReceivedTokenRate(
      _tokenAddress,
      _newTokenRate
    );
  }

  /**
   * @dev Receives approved foreign tokens and exchange them to tokens.
   * @param _from Address of foreign tokens sender
   * @param _amount Amount of the foreign tokens
   * @param _tokenAddress Address of the foreign token contract
   * @param _extraData Data attached to payment
   */
  function receiveApproval(
    address _from,
    uint256 _amount,
    address _tokenAddress,
    bytes _extraData
  )
    whenNotPaused external
  {

    require(_from != address(0));
    require(_tokenAddress != address(0));
    require(receivedTokens[_tokenAddress].rate > 0); // check: token in receivedTokens
    require(_amount > 0);

    require(msg.sender == _tokenAddress);

    emit ReceivedTokens(
      _from,
      _amount,
      _tokenAddress,
      _extraData
    );

    _exchangeTokens(ERC20(_tokenAddress), _from, _amount);
  }

  /**
   * @dev Deposits foreign token and exchange them to tokens.
   * @param _tokenAddress Address of the foreign token
   * @param _amount Amount of the foreign tokens
   */
  function depositToken(
    ERC20 _tokenAddress,
    uint256 _amount
  )
    whenNotPaused external
  {
    // Remember to call ERC20(address).approve(this, amount)
    // or this contract will not be able to do the transfer on your behalf
    require(_tokenAddress != address(0));

    require(receivedTokens[_tokenAddress].rate > 0);
    require(_amount > 0);

    _exchangeTokens(_tokenAddress, msg.sender, _amount);
  }


  // -----------------------------------------
  // Internal interface
  // -----------------------------------------

  /**
   * @dev Exchanges foreign tokens to self token. Low-level exchange method.
   * @param _tokenAddress Address of the foreign token contract
   * @param _sender Sender address
   * @param _amount Number of tokens for exchange
   */
  function _exchangeTokens(
    ERC20 _tokenAddress,
    address _sender,
    uint256 _amount
  )
    internal
  {
    uint256 foreignTokenAmount = _amount;

    require(_tokenAddress.transferFrom(_sender, address(this), foreignTokenAmount));

    uint256 tokenBalance = token.balanceOf(address(this));
    require(tokenBalance > 0);

    uint256 tokens = _getTokenAmount(_tokenAddress, foreignTokenAmount);

    if (tokens > tokenBalance) {
      tokens = tokenBalance;
      foreignTokenAmount = _inverseGetTokenAmount(_tokenAddress, tokens);

      uint256 senderForeignTokenExcess = _amount.sub(foreignTokenAmount);
      _tokenAddress.transfer(_sender, senderForeignTokenExcess);

      emit SendTokensExcess(
        _sender,
        senderForeignTokenExcess
      );
    }

    receivedTokens[_tokenAddress].raised = receivedTokens[_tokenAddress].raised.add(foreignTokenAmount);

    _processPurchase(_sender, tokens);
    emit TokenForTokenPurchase(
      _sender,
      _sender,
      foreignTokenAmount,
      tokens
    );
  }

  /**
   * @dev Source of tokens.
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
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override to extend the way in which ether or foreign token unit is converted to tokens.
   * @param _tokenAddress Address of foreign token or 0 if ether to tokens
   * @param _amount Value in wei or foreign token units to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _amount (wei or foreign token units)
   */
  function _getTokenAmount(address _tokenAddress, uint256 _amount)
    internal view returns (uint256)
  {
    uint256 _rate;

    if (_tokenAddress == address(0)) {
      _rate = rate;
    } else {
      _rate = receivedTokens[_tokenAddress].rate;
    }

    return _amount.mul(_rate);
  }

  /**
   * @dev Get wei or foreign tokens amount. Inverse _getTokenAmount method.
   */
  function _inverseGetTokenAmount(address _tokenAddress, uint256 _tokenAmount)
    internal view returns (uint256)
  {
    uint256 _rate;

    if (_tokenAddress == address(0)) {
      _rate = rate;
    } else {
      _rate = receivedTokens[_tokenAddress].rate;
    }

    return _tokenAmount.div(_rate);
  }
}