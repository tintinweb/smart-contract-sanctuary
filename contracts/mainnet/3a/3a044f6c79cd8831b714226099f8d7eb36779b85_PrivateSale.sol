pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
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

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

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

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method: 
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
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
    token.safeTransfer(_beneficiary, _tokenAmount);
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
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
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

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

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
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Ownable, TimedCrowdsale {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */





///@title This contract enables to create multiple contract administrators.
contract CustomAdmin is Ownable {
  ///@notice List of administrators.
  mapping(address => bool) public admins;

  event AdminAdded(address indexed _address);
  event AdminRemoved(address indexed _address);

  ///@notice Validates if the sender is actually an administrator.
  modifier onlyAdmin() {
    require(admins[msg.sender] || msg.sender == owner);
    _;
  }

  ///@notice Adds the specified address to the list of administrators.
  ///@param _address The address to add to the administrator list.
  function addAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(!admins[_address]);

    //The owner is already an admin and cannot be added.
    require(_address != owner);

    admins[_address] = true;

    emit AdminAdded(_address);
  }

  ///@notice Adds multiple addresses to the administrator list.
  ///@param _accounts The wallet addresses to add to the administrator list.
  function addManyAdmins(address[] _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address cannot be an admin.
      ///The owner is already an admin and cannot be assigned.
      ///The address cannot be an existing admin.
      if(account != address(0) && !admins[account] && account != owner){
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }
  }
  
  ///@notice Removes the specified address from the list of administrators.
  ///@param _address The address to remove from the administrator list.
  function removeAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(admins[_address]);

    //The owner cannot be removed as admin.
    require(_address != owner);

    admins[_address] = false;
    emit AdminRemoved(_address);
  }


  ///@notice Removes multiple addresses to the administrator list.
  ///@param _accounts The wallet addresses to remove from the administrator list.
  function removeManyAdmins(address[] _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

      ///Zero address can neither be added or removed from this list.
      ///The owner is the super admin and cannot be removed.
      ///The address must be an existing admin in order for it to be removed.
      if(account != address(0) && admins[account] && account != owner){
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }
  }
}

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */


 





///@title This contract enables you to create pausable mechanism to stop in case of emergency.
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool public paused = false;

  ///@notice Verifies whether the contract is not paused.
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  ///@notice Verifies whether the contract is paused.
  modifier whenPaused() {
    require(paused);
    _;
  }

  ///@notice Pauses the contract.
  function pause() external onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

  ///@notice Unpauses the contract and returns to normal state.
  function unpause() external onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}

/*
Copyright 2018 Binod Nirvan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */




///@title This contract enables to maintain a list of whitelisted wallets.
contract CustomWhitelist is CustomPausable {
  mapping(address => bool) public whitelist;

  event WhitelistAdded(address indexed _account);
  event WhitelistRemoved(address indexed _account);

  ///@notice Verifies if the account is whitelisted.
  modifier ifWhitelisted(address _account) {
    require(_account != address(0));
    require(whitelist[_account]);

    _;
  }

  ///@notice Adds an account to the whitelist.
  ///@param _account The wallet address to add to the whitelist.
  function addWhitelist(address _account) external whenNotPaused onlyAdmin {
    require(_account!=address(0));

    if(!whitelist[_account]) {
      whitelist[_account] = true;

      emit WhitelistAdded(_account);
    }
  }

  ///@notice Adds multiple accounts to the whitelist.
  ///@param _accounts The wallet addresses to add to the whitelist.
  function addManyWhitelist(address[] _accounts) external whenNotPaused onlyAdmin {
    for(uint8 i=0;i<_accounts.length;i++) {
      if(_accounts[i] != address(0) && !whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = true;

        emit WhitelistAdded(_accounts[i]);
      }
    }
  }

  ///@notice Removes an account from the whitelist.
  ///@param _account The wallet address to remove from the whitelist.
  function removeWhitelist(address _account) external whenNotPaused onlyAdmin {
    require(_account != address(0));
    if(whitelist[_account]) {
      whitelist[_account] = false;

      emit WhitelistRemoved(_account);
    }
  }

  ///@notice Removes multiple accounts from the whitelist.
  ///@param _accounts The wallet addresses to remove from the whitelist.
  function removeManyWhitelist(address[] _accounts) external whenNotPaused onlyAdmin {
    for(uint8 i=0;i<_accounts.length;i++) {
      if(_accounts[i] != address(0) && whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = false;
        
        emit WhitelistRemoved(_accounts[i]);
      }
    }
  }
}

/*
Copyright 2018 Binod Nirvan, Subramanian Venkatesan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/




///@title This contract keeps track of the VRH token price.
contract TokenPrice is CustomPausable {
  ///@notice The price per token in cents.
  uint256 public tokenPriceInCents;

  event TokenPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setTokenPrice(uint256 _cents) public onlyAdmin whenNotPaused {
    require(_cents > 0);
    
    emit TokenPriceChanged(_cents, tokenPriceInCents );
    tokenPriceInCents  = _cents;
  }
}

/*
Copyright 2018 Binod Nirvan, Subramanian Venkatesan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/




///@title This contract keeps track of Ether price.
contract EtherPrice is CustomPausable {
  uint256 public etherPriceInCents; //price of 1 ETH in cents

  event EtherPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setEtherPrice(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit EtherPriceChanged(_cents, etherPriceInCents);
    etherPriceInCents = _cents;
  }
}

/*
Copyright 2018 Binod Nirvan, Subramanian Venkatesan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

 


///@title This contract keeps track of Binance Coin price.
contract BinanceCoinPrice is CustomPausable {
  uint256 public binanceCoinPriceInCents;

  event BinanceCoinPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setBinanceCoinPrice(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit BinanceCoinPriceChanged(_cents, binanceCoinPriceInCents);
    binanceCoinPriceInCents = _cents;
  }
}

/*
Copyright 2018 Binod Nirvan, Subramanian Venkatesan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

 


///@title This contract keeps track of Credits Token price.
contract CreditsTokenPrice is CustomPausable {
  uint256 public creditsTokenPriceInCents;

  event CreditsTokenPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setCreditsTokenPrice(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit CreditsTokenPriceChanged(_cents, creditsTokenPriceInCents);
    creditsTokenPriceInCents = _cents;
  }
}

/*
Copyright 2018 Binod Nirvan, Subramanian Venkatesan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/






///@title This contract enables assigning bonus to crowdsale contributors.
contract BonusHolder is CustomPausable {
  using SafeMath for uint256;

  ///@notice The list of addresses and their respective bonuses.
  mapping(address => uint256) public bonusHolders;

  ///@notice The timestamp on which bonus will be available.
  uint256 public releaseDate;

  ///@notice The ERC20 token contract of the bonus coin.
  ERC20 public bonusCoin;

  ///@notice The total amount of bonus coins provided to the contributors.
  uint256 public bonusProvided;

  ///@notice The total amount of bonus withdrawn by the contributors.
  uint256 public bonusWithdrawn;

  event BonusReleaseDateSet(uint256 _releaseDate);
  event BonusAssigned(address indexed _address, uint _amount);
  event BonusWithdrawn(address indexed _address, uint _amount);

  ///@notice Constructs bonus holder.
  ///@param _bonusCoin The ERC20 token of the coin to hold bonus.
  constructor(ERC20 _bonusCoin) internal {
    bonusCoin = _bonusCoin;
  }

  ///@notice Enables the administrators to set the bonus release date.
  ///Please note that the release date can only be set once.
  ///@param _releaseDate The timestamp after which the bonus will be available.
  function setReleaseDate(uint256 _releaseDate) external onlyAdmin whenNotPaused {
    require(releaseDate == 0);
    require(_releaseDate > now);

    releaseDate = _releaseDate;

    emit BonusReleaseDateSet(_releaseDate);
  }

  ///@notice Assigns bonus tokens to the specific contributor.
  ///@param _investor The wallet address of the investor/contributor.
  ///@param _bonus The amount of bonus in token value.
  function assignBonus(address _investor, uint256 _bonus) internal {
    if(_bonus == 0){
      return;
    }

    bonusProvided = bonusProvided.add(_bonus);
    bonusHolders[_investor] = bonusHolders[_investor].add(_bonus);

    emit BonusAssigned(_investor, _bonus);
  }

  ///@notice Enables contributors to withdraw their bonus.
  ///The bonus can only be withdrawn after the release date.
  function withdrawBonus() external whenNotPaused {
    require(releaseDate != 0);
    require(now > releaseDate);

    uint256 amount = bonusHolders[msg.sender];
    require(amount > 0);

    bonusWithdrawn = bonusWithdrawn.add(amount);

    bonusHolders[msg.sender] = 0;
    require(bonusCoin.transfer(msg.sender, amount));

    emit BonusWithdrawn(msg.sender, amount);
  }

  ///@notice Returns the remaining bonus held on behalf of the crowdsale contributors by this contract.
  function getRemainingBonus() public view returns(uint256) {
    return bonusProvided.sub(bonusWithdrawn);
  }
}

/*
Copyright 2018 Virtual Rehab (http://virtualrehab.co)
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */












///@title Virtual Rehab Private Sale.
///@author Binod Nirvan, Subramanian Venkatesan (http://virtualrehab.co)
///@notice This contract enables contributors to participate in Virtual Rehab Private Sale.
///
///The Virtual Rehab Private Sale provides early investors with an opportunity
///to take part into the Virtual Rehab token sale ahead of the pre-sale and main sale launch.
///All early investors are expected to successfully complete KYC and whitelisting
///to contribute to the Virtual Rehab token sale.
///
///US investors must be accredited investors and must provide all requested documentation
///to validate their accreditation. We, unfortunately, do not accept contributions
///from non-accredited investors within the US along with any contribution
///from China, Republic of Korea, and New Zealand. Any questions or additional information needed
///can be sought by sending an e-mail to investors＠virtualrehab.co.
///
///Accepted Currencies: Ether, Binance Coin, Credits Token.
contract PrivateSale is TokenPrice, EtherPrice, BinanceCoinPrice, CreditsTokenPrice, BonusHolder, FinalizableCrowdsale, CustomWhitelist {
  ///@notice The ERC20 token contract of Binance Coin. Must be: 0xB8c77482e45F1F44dE1745F52C74426C631bDD52
  ERC20 public binanceCoin;

  ///@notice The ERC20 token contract of Credits Token. Must be: 0x46b9Ad944d1059450Da1163511069C718F699D31
  ERC20 public creditsToken;

  ///@notice The total amount of VRH tokens sold in the private round.
  uint256 public totalTokensSold;

  ///@notice The total amount of VRH tokens allocated for the private sale.
  uint256 public totalSaleAllocation;

  ///@notice The minimum contribution in dollar cent value.
  uint256 public minContributionInUSDCents;

  mapping(address => uint256) public assignedBonusRates;
  uint[3] public bonusLimits;
  uint[3] public bonusPercentages;

  ///@notice Signifies if the private sale was started.
  bool public initialized;

  event SaleInitialized();

  event MinimumContributionChanged(uint256 _newContribution, uint256 _oldContribution);
  event ClosingTimeChanged(uint256 _newClosingTime, uint256 _oldClosingTime);
  event FundsWithdrawn(address indexed _wallet, uint256 _amount);
  event ERC20Withdrawn(address indexed _contract, uint256 _amount);
  event TokensAllocatedForSale(uint256 _newAllowance, uint256 _oldAllowance);

  ///@notice Creates and constructs this private sale contract.
  ///@param _startTime The date and time of the private sale start.
  ///@param _endTime The date and time of the private sale end.
  ///@param _binanceCoin Binance coin contract. Must be: 0xB8c77482e45F1F44dE1745F52C74426C631bDD52.
  ///@param _creditsToken credits Token contract. Must be: 0x46b9Ad944d1059450Da1163511069C718F699D31.
  ///@param _vrhToken VRH token contract.
  constructor(uint256 _startTime, uint256 _endTime, ERC20 _binanceCoin, ERC20 _creditsToken, ERC20 _vrhToken) public
  TimedCrowdsale(_startTime, _endTime)
  Crowdsale(1, msg.sender, _vrhToken)
  BonusHolder(_vrhToken) {
    //require(address(_binanceCoin) == 0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
    //require(address(_creditsToken) == 0x46b9Ad944d1059450Da1163511069C718F699D31);
    binanceCoin = _binanceCoin;
    creditsToken = _creditsToken;
  }

  ///@notice Initializes the private sale.
  ///@param _etherPriceInCents Ether Price in cents
  ///@param _tokenPriceInCents VRHToken Price in cents
  ///@param _binanceCoinPriceInCents Binance Coin Price in cents
  ///@param _creditsTokenPriceInCents Credits Token Price in cents
  ///@param _minContributionInUSDCents The minimum contribution in dollar cent value
  function initializePrivateSale(uint _etherPriceInCents, uint _tokenPriceInCents, uint _binanceCoinPriceInCents, uint _creditsTokenPriceInCents, uint _minContributionInUSDCents) external onlyAdmin {
    require(!initialized);
    require(_etherPriceInCents > 0);
    require(_tokenPriceInCents > 0);
    require(_binanceCoinPriceInCents > 0);
    require(_creditsTokenPriceInCents > 0);
    require(_minContributionInUSDCents > 0);

    setEtherPrice(_etherPriceInCents);
    setTokenPrice(_tokenPriceInCents);
    setBinanceCoinPrice(_binanceCoinPriceInCents);
    setCreditsTokenPrice(_creditsTokenPriceInCents);
    setMinimumContribution(_minContributionInUSDCents);

    increaseTokenSaleAllocation();

    bonusLimits[0] = 25000000;
    bonusLimits[1] = 10000000;
    bonusLimits[2] = 1500000;

    bonusPercentages[0] = 50;
    bonusPercentages[1] = 40;
    bonusPercentages[2] = 35;


    initialized = true;

    emit SaleInitialized();
  }

  ///@notice Enables a contributor to contribute using Binance coin.
  function contributeInBNB() external ifWhitelisted(msg.sender) whenNotPaused onlyWhileOpen {
    require(initialized);

    ///Check the amount of Binance coins allowed to (be transferred by) this contract by the contributor.
    uint256 allowance = binanceCoin.allowance(msg.sender, this);
    require (allowance > 0, "You have not approved any Binance Coin for this contract to receive.");

    ///Calculate equivalent amount in dollar cent value.
    uint256 contributionCents  = convertToCents(allowance, binanceCoinPriceInCents, 18);


    if(assignedBonusRates[msg.sender] == 0) {
      require(contributionCents >= minContributionInUSDCents);
      assignedBonusRates[msg.sender] = getBonusPercentage(contributionCents);
    }

    ///Calculate the amount of tokens per the contribution.
    uint256 numTokens = contributionCents.mul(1 ether).div(tokenPriceInCents);

    ///Calculate the bonus based on the number of tokens and the dollar cent value.
    uint256 bonus = calculateBonus(numTokens, assignedBonusRates[msg.sender]);

    require(totalTokensSold.add(numTokens).add(bonus) <= totalSaleAllocation);

    ///Receive the Binance coins immediately.
    require(binanceCoin.transferFrom(msg.sender, this, allowance));

    ///Send the VRH tokens to the contributor.
    require(token.transfer(msg.sender, numTokens));

    ///Assign the bonus to be vested and later withdrawn.
    assignBonus(msg.sender, bonus);

    totalTokensSold = totalTokensSold.add(numTokens).add(bonus);
  }

  function contributeInCreditsToken() external ifWhitelisted(msg.sender) whenNotPaused onlyWhileOpen {
    require(initialized);

    ///Check the amount of Binance coins allowed to (be transferred by) this contract by the contributor.
    uint256 allowance = creditsToken.allowance(msg.sender, this);
    require (allowance > 0, "You have not approved any Credits Token for this contract to receive.");

    ///Calculate equivalent amount in dollar cent value.
    uint256 contributionCents = convertToCents(allowance, creditsTokenPriceInCents, 6);

    if(assignedBonusRates[msg.sender] == 0) {
      require(contributionCents >= minContributionInUSDCents);
      assignedBonusRates[msg.sender] = getBonusPercentage(contributionCents);
    }

    ///Calculate the amount of tokens per the contribution.
    uint256 numTokens = contributionCents.mul(1 ether).div(tokenPriceInCents);

    ///Calculate the bonus based on the number of tokens and the dollar cent value.
    uint256 bonus = calculateBonus(numTokens, assignedBonusRates[msg.sender]);

    require(totalTokensSold.add(numTokens).add(bonus) <= totalSaleAllocation);

    ///Receive the Credits Token immediately.
    require(creditsToken.transferFrom(msg.sender, this, allowance));

    ///Send the VRH tokens to the contributor.
    require(token.transfer(msg.sender, numTokens));

    ///Assign the bonus to be vested and later withdrawn.
    assignBonus(msg.sender, bonus);

    totalTokensSold = totalTokensSold.add(numTokens).add(bonus);
  }

  function setMinimumContribution(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit MinimumContributionChanged(minContributionInUSDCents, _cents);
    minContributionInUSDCents = _cents;
  }

  ///@notice The equivalent dollar amount of each contribution request.
  uint256 private amountInUSDCents;

  ///@notice Additional validation rules before token contribution is actually allowed.
  ///@param _beneficiary The contributor who wishes to purchase the VRH tokens.
  ///@param _weiAmount The amount of Ethers (in wei) wished to contribute.
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused ifWhitelisted(_beneficiary) {
    require(initialized);

    amountInUSDCents = convertToCents(_weiAmount, etherPriceInCents, 18);

    if(assignedBonusRates[_beneficiary] == 0) {
      require(amountInUSDCents >= minContributionInUSDCents);
      assignedBonusRates[_beneficiary] = getBonusPercentage(amountInUSDCents);
    }

    ///Continue validating the purchase.
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  ///@notice This function is automatically called when a contribution request passes all validations.
  ///@dev Overridden to keep track of the bonuses.
  ///@param _beneficiary The contributor who wishes to purchase the VRH tokens.
  ///@param _tokenAmount The amount of tokens wished to purchase.
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    ///amountInUSDCents is set on _preValidatePurchase
    uint256 bonus = calculateBonus(_tokenAmount, assignedBonusRates[_beneficiary]);

    ///Ensure that the sale does not exceed allocation.
    require(totalTokensSold.add(_tokenAmount).add(bonus) <= totalSaleAllocation);

    ///Assign bonuses so that they can be later withdrawn.
    assignBonus(_beneficiary, bonus);

    ///Update the sum of tokens sold during the private sale.
    totalTokensSold = totalTokensSold.add(_tokenAmount).add(bonus);

    ///Continue processing the purchase.
    super._processPurchase(_beneficiary, _tokenAmount);
  }

  ///@notice Calculates bonus.
  ///@param _tokenAmount The total amount in VRH tokens.
  ///@param _percentage bonus percentage.
  function calculateBonus(uint256 _tokenAmount, uint256 _percentage) public pure returns (uint256) {
    return _tokenAmount.mul(_percentage).div(100);
  }

  ///@notice Sets the bonus structure.
  ///The bonus limits must be in decreasing order.
  function setBonuses(uint[] _bonusLimits, uint[] _bonusPercentages) public onlyAdmin {
    require(_bonusLimits.length == _bonusPercentages.length);
    require(_bonusPercentages.length == 3);
    for(uint8 i=0;i<_bonusLimits.length;i++) {
      bonusLimits[i] = _bonusLimits[i];
      bonusPercentages[i] = _bonusPercentages[i];
    }
  }


  ///@notice Gets the bonus applicable for the supplied dollar cent value.
  function getBonusPercentage(uint _cents) view public returns(uint256) {
    for(uint8 i=0;i<bonusLimits.length;i++) {
      if(_cents >= bonusLimits[i]) {
        return bonusPercentages[i];
      }
    }
  }

  ///@notice Converts the amount of Ether (wei) or amount of any token having 18 decimal place divisible
  ///to cent value based on the cent price supplied.
  function convertToCents(uint256 _tokenAmount, uint256 _priceInCents, uint256 _decimals) public pure returns (uint256) {
    return _tokenAmount.mul(_priceInCents).div(10**_decimals);
  }

  ///@notice Calculates the number of VRH tokens for the supplied wei value.
  ///@param _weiAmount The total amount of Ether in wei value.
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(etherPriceInCents).div(tokenPriceInCents);
  }

  ///@dev Used only for test, drop this function before deployment.
  ///@param _weiAmount The total amount of Ether in wei value.
  function getTokenAmountForWei(uint256 _weiAmount) external view returns (uint256) {
    return _getTokenAmount(_weiAmount);
  }

  ///@notice Recalculates and/or reassigns the total tokens allocated for the private sale.
  function increaseTokenSaleAllocation() public whenNotPaused onlyAdmin {
    ///Check the allowance of this contract to spend.
    uint256 allowance = token.allowance(msg.sender, this);

    ///Get the current allocation.
    uint256 current = totalSaleAllocation;

    ///Update the total token allocation for the private sale.
    totalSaleAllocation = totalSaleAllocation.add(allowance);

    ///Transfer (receive) the allocated VRH tokens.
    require(token.transferFrom(msg.sender, this, allowance));

    emit TokensAllocatedForSale(totalSaleAllocation, current);
  }


  ///@notice Enables the admins to withdraw Binance coin
  ///or any ERC20 token accidentally sent to this contract.
  function withdrawToken(address _token) external onlyAdmin {
    bool isVRH = _token == address(token);
    ERC20 erc20 = ERC20(_token);

    uint256 balance = erc20.balanceOf(this);

    //This stops admins from stealing the allocated bonus of the investors.
    ///The bonus VRH tokens should remain in this contract.
    if(isVRH) {
      balance = balance.sub(getRemainingBonus());
      changeClosingTime(now);
    }

    require(erc20.transfer(msg.sender, balance));

    emit ERC20Withdrawn(_token, balance);
  }


  ///@dev Must be called after crowdsale ends, to do some extra finalization work.
  function finalizeCrowdsale() public onlyAdmin {
    require(!isFinalized);
    require(hasClosed());

    uint256 unsold = token.balanceOf(this).sub(bonusProvided);

    if(unsold > 0) {
      require(token.transfer(msg.sender, unsold));
    }

    isFinalized = true;

    emit Finalized();
  }

  ///@notice Signifies whether or not the private sale has ended.
  ///@return Returns true if the private sale has ended.
  function hasClosed() public view returns (bool) {
    return (totalTokensSold >= totalSaleAllocation) || super.hasClosed();
  }

  ///@dev Reverts the finalization logic.
  ///Use finalizeCrowdsale instead.
  function finalization() internal {
    revert();
  }

  ///@notice Stops the crowdsale contract from sending ethers.
  function _forwardFunds() internal {
    //Nothing to do here.
  }

  ///@notice Enables the admins to withdraw Ethers present in this contract.
  ///@param _amount Amount of Ether in wei value to withdraw.
  function withdrawFunds(uint256 _amount) external whenNotPaused onlyAdmin {
    require(_amount <= address(this).balance);

    msg.sender.transfer(_amount);

    emit FundsWithdrawn(msg.sender, _amount);
  }

  ///@notice Adjusts the closing time of the crowdsale.
  ///@param _closingTime The timestamp when the crowdsale is closed.
  function changeClosingTime(uint256 _closingTime) public whenNotPaused onlyAdmin {
    emit ClosingTimeChanged(_closingTime, closingTime);

    closingTime = _closingTime;
  }

  function getRemainingTokensForSale() public view returns(uint256) {
    return totalSaleAllocation.sub(totalTokensSold);
  }
}