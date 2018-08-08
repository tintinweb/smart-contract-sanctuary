pragma solidity ^0.4.15;

/**
 * Ethino Crowdsale Contract
 *
 * This is the crowdsale contract for the Ethino token. It utilizes Majoolr&#39;s
 * CrowdsaleLib library to reduce custom source code surface area and increase overall
 * security.Majoolr provides smart contract services
 * and security reviews for contract deployments in addition to working on open
 * source projects in the Ethereum community.
 * For further information: ethino.com, majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

contract ENOCrowdsale {
  using DirectCrowdsaleLib for DirectCrowdsaleLib.DirectCrowdsaleStorage;

  DirectCrowdsaleLib.DirectCrowdsaleStorage sale;

  function ENOCrowdsale(
                address owner,
                uint256 capAmountInCents,
                uint256 startTime,
                uint256 endTime,
                uint256[] tokenPricePoints,
                uint256 fallbackExchangeRate,
                uint256 changeInterval,
                uint8 percentBurn,
                CrowdsaleToken token)
  {
  	sale.init(owner, capAmountInCents, startTime, endTime, tokenPricePoints, fallbackExchangeRate, changeInterval, percentBurn, token);
  }

  /*EVENTS*/

  event LogTokensBought(address indexed buyer, uint256 amount);
  event LogErrorMsg(uint256 amount, string Msg);
  event LogTokenPriceChange(uint256 amount, string Msg);
  event LogTokensWithdrawn(address indexed _bidder, uint256 Amount);
  event LogWeiWithdrawn(address indexed _bidder, uint256 Amount);
  event LogOwnerEthWithdrawn(address indexed owner, uint256 amount, string Msg);
  event LogNoticeMsg(address _buyer, uint256 value, string Msg);
  event LogErrorMsg(string Msg);

  /*FUNCTIONS*/

  // fallback function can be used to buy tokens
  function () payable {
    sendPurchase();
  }

  function sendPurchase() payable returns (bool) {
  	return sale.receivePurchase(msg.value);
  }

  function withdrawOwnerEth() returns (bool) {
  	return sale.withdrawOwnerEth();
  }

  function setTokenExchangeRate(uint256 _exchangeRate) returns (bool) {
    return sale.setTokenExchangeRate(_exchangeRate);
  }

  function setTokens() returns (bool) {
    return sale.setTokens();
  }

  function withdrawTokens() returns (bool) {
  	return sale.withdrawTokens();
  }

  function withdrawLeftoverWei() returns (bool) {
    return sale.withdrawLeftoverWei();
  }

  /*GETTERS*/

  function owner() constant returns (address) {
    return sale.base.owner;
  }

  function tokensPerEth() constant returns (uint256) {
    return sale.base.tokensPerEth;
  }

  function exchangeRate() constant returns (uint256) {
    return sale.base.exchangeRate;
  }

  function capAmount() constant returns (uint256) {
    return sale.base.capAmount;
  }

  function startTime() constant returns (uint256) {
    return sale.base.startTime;
  }

  function endTime() constant returns (uint256) {
    return sale.base.endTime;
  }

  function changeInterval() constant returns (uint256) {
    return sale.changeInterval;
  }

  function crowdsaleActive() constant returns (bool) {
  	return sale.crowdsaleActive();
  }

  function firstPriceChange() constant returns (uint256) {
    return sale.tokenPricePoints[1];
  }

  function crowdsaleEnded() constant returns (bool) {
  	return sale.crowdsaleEnded();
  }

  function ethRaised() constant returns (uint256) {
    return sale.base.ownerBalance;
  }

  function tokensSold() constant returns (uint256) {
    return sale.base.startingTokenBalance - sale.base.token.balanceOf(this);
  }

  function contributionAmount(address _buyer) constant returns (uint256) {
  	return sale.base.hasContributed[_buyer];
  }

  function tokenPurchaseAmount(address _buyer) constant returns (uint256) {
  	return sale.base.withdrawTokensMap[_buyer];
  }

  function leftoverWeiAmount(address _buyer) constant returns (uint256) {
    return sale.base.leftoverWei[_buyer];
  }
}

pragma solidity ^0.4.15;

/**
 * @title DirectCrowdsaleLib
 * @author Majoolr.io
 *
 * version 1.0.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The DirectCrowdsale Library provides functionality to create a initial coin offering
 * for a standard token sale with high supply where there is a direct ether to
 * token transfer.
 *
 * Majoolr provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library DirectCrowdsaleLib {
  using BasicMathLib for uint256;
  using CrowdsaleLib for CrowdsaleLib.CrowdsaleStorage;

  struct DirectCrowdsaleStorage {

  	CrowdsaleLib.CrowdsaleStorage base; // base storage from CrowdsaleLib

    uint256[] tokenPricePoints;    // price points at each price change interval in cents/token.

  	uint256 changeInterval;      // amount of time between changes in the price of the token
  	uint256 lastPriceChangeTime;  // time of the last change in token cost
  }

  event LogTokensBought(address indexed buyer, uint256 amount);
  event LogAddressCapExceeded(address indexed buyer, uint256 amount, string Msg);
  event LogErrorMsg(uint256 amount, string Msg);
  event LogTokenPriceChange(uint256 amount, string Msg);


  /// @dev Called by a crowdsale contract upon creation.
  /// @param self Stored crowdsale from crowdsale contract
  /// @param _owner Address of crowdsale owner
  /// @param _capAmountInCents Total to be raised in cents
  /// @param _startTime Timestamp of sale start time
  /// @param _endTime Timestamp of sale end time
  /// @param _tokenPricePoints Array of each price point during sale cents/token
  /// @param _fallbackExchangeRate Exchange rate of cents/ETH
  /// @param _changeInterval The number of seconds between each step
  /// @param _percentBurn Percentage of extra tokens to burn
  /// @param _token Token being sold
  function init(DirectCrowdsaleStorage storage self,
                address _owner,
                uint256 _capAmountInCents,
                uint256 _startTime,
                uint256 _endTime,
                uint256[] _tokenPricePoints,
                uint256 _fallbackExchangeRate,
                uint256 _changeInterval,
                uint8 _percentBurn,
                CrowdsaleToken _token)
  {
  	self.base.init(_owner,
                _tokenPricePoints[0],
                _fallbackExchangeRate,
                _capAmountInCents,
                _startTime,
                _endTime,
                _percentBurn,
                _token);

    require(_tokenPricePoints.length > 0);

    // if there is no increase or decrease in price, the time interval should also be zero
    if (_tokenPricePoints.length == 1) {
    	require(_changeInterval == 0);
    }
    self.tokenPricePoints = _tokenPricePoints;
  	self.changeInterval = _changeInterval;
  	self.lastPriceChangeTime = _startTime;
  }

  /// @dev Called when an address wants to purchase tokens
  /// @param self Stored crowdsale from crowdsale contract
  /// @param _amount amound of wei that the buyer is sending
  /// @return true on succesful purchase
  function receivePurchase(DirectCrowdsaleStorage storage self, uint256 _amount) returns (bool) {
    require(msg.sender != self.base.owner);
  	require(self.base.validPurchase());

    require((self.base.ownerBalance + _amount) <= self.base.capAmount);

  	// if the token price increase interval has passed, update the current day and change the token price
  	if ((self.changeInterval > 0) && (now >= (self.lastPriceChangeTime + self.changeInterval))) {
  		self.lastPriceChangeTime = self.lastPriceChangeTime + self.changeInterval;
      uint256 index = (now-self.base.startTime)/self.changeInterval;

      //prevents going out of bounds on the tokenPricePoints array
      if (self.tokenPricePoints.length <= index)
        index = self.tokenPricePoints.length - 1;

      self.base.changeTokenPrice(self.tokenPricePoints[index]);

      LogTokenPriceChange(self.base.tokensPerEth,"Token Price has changed!");
  	}

  	uint256 numTokens; //number of tokens that will be purchased
  	bool err;
    uint256 newBalance; //the new balance of the owner of the crowdsale
    uint256 weiTokens; //temp calc holder
    uint256 zeros; //for calculating token
    uint256 leftoverWei; //wei change for purchaser
    uint256 remainder; //temp calc holder

    // Find the number of tokens as a function in wei
    (err,weiTokens) = _amount.times(self.base.tokensPerEth);
    require(!err);

    if(self.base.tokenDecimals <= 18){
      zeros = 10**(18-uint256(self.base.tokenDecimals));
      numTokens = weiTokens/zeros;
      leftoverWei = weiTokens % zeros;
      self.base.leftoverWei[msg.sender] += leftoverWei;
    } else {
      zeros = 10**(uint256(self.base.tokenDecimals)-18);
      numTokens = weiTokens*zeros;
    }

    // can&#39;t overflow because it is under the cap
    self.base.hasContributed[msg.sender] += _amount - leftoverWei;

    require(numTokens <= self.base.token.balanceOf(this));

    // calculate the amout of ether in the owners balance
    (err,newBalance) = self.base.ownerBalance.plus(_amount-leftoverWei);
    require(!err);

    self.base.ownerBalance = newBalance;   // "deposit" the amount

    // can&#39;t overflow because it will be under the cap
	  self.base.withdrawTokensMap[msg.sender] += numTokens;

    //subtract tokens from owner&#39;s share
    (err,remainder) = self.base.withdrawTokensMap[self.base.owner].minus(numTokens);
    self.base.withdrawTokensMap[self.base.owner] = remainder;

	  LogTokensBought(msg.sender, numTokens);

    return true;
  }

  /*Functions "inherited" from CrowdsaleLib library*/

  function setTokenExchangeRate(DirectCrowdsaleStorage storage self, uint256 _exchangeRate) returns (bool) {
    return self.base.setTokenExchangeRate(_exchangeRate);
  }

  function setTokens(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.setTokens();
  }

  function withdrawTokens(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.withdrawTokens();
  }

  function withdrawLeftoverWei(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.withdrawLeftoverWei();
  }

  function withdrawOwnerEth(DirectCrowdsaleStorage storage self) returns (bool) {
    return self.base.withdrawOwnerEth();
  }

  function crowdsaleActive(DirectCrowdsaleStorage storage self) constant returns (bool) {
    return self.base.crowdsaleActive();
  }

  function crowdsaleEnded(DirectCrowdsaleStorage storage self) constant returns (bool) {
    return self.base.crowdsaleEnded();
  }

  function validPurchase(DirectCrowdsaleStorage storage self) constant returns (bool) {
    return self.base.validPurchase();
  }
}
pragma solidity ^0.4.15;

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This is an example token contract built using the Majoolr token library at
 * https://github.com/Majoolr/ethereum-libraries/tree/master/TokenLib. This
 * example does not use all of the functionality available, it is only
 * a barebones example of a basic ERC20 token contract.
 *
 * Majoolr provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

contract CrowdsaleToken {
  using TokenLib for TokenLib.TokenStorage;

  TokenLib.TokenStorage public token;

  function CrowdsaleToken(address owner,
                                string name,
                                string symbol,
                                uint8 decimals,
                                uint256 initialSupply,
                                bool allowMinting)
  {
    token.init(owner, name, symbol, decimals, initialSupply, allowMinting);
  }

  function name() constant returns (string) {
    return token.name;
  }

  function symbol() constant returns (string) {
    return token.symbol;
  }

  function decimals() constant returns (uint8) {
    return token.decimals;
  }

  function totalSupply() constant returns (uint256) {
    return token.totalSupply;
  }

  function initialSupply() constant returns (uint256) {
    return token.INITIAL_SUPPLY;
  }

  function balanceOf(address who) constant returns (uint256) {
    return token.balanceOf(who);
  }

  function allowance(address owner, address spender) constant returns (uint256) {
    return token.allowance(owner, spender);
  }

  function transfer(address to, uint value) returns (bool ok) {
    return token.transfer(to, value);
  }

  function transferFrom(address from, address to, uint value) returns (bool ok) {
    return token.transferFrom(from, to, value);
  }

  function approve(address spender, uint value) returns (bool ok) {
    return token.approve(spender, value);
  }

  function changeOwner(address newOwner) returns (bool ok) {
    return token.changeOwner(newOwner);
  }

  function burnToken(uint256 amount) returns (bool ok) {
    return token.burnToken(amount);
  }
}

pragma solidity ^0.4.15;

/**
 * @title CrowdsaleLib
 * @author Majoolr.io
 *
 * version 1.0.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Crowdsale Library provides basic functionality to create an initial coin
 * offering for different types of token sales.
 *
 * Majoolr provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library CrowdsaleLib {
  using BasicMathLib for uint256;

  struct CrowdsaleStorage {
  	address owner;     //owner of the crowdsale

  	uint256 tokensPerEth;  //number of tokens received per ether
  	uint256 capAmount; //Maximum amount to be raised in wei
  	uint256 startTime; //ICO start time, timestamp
  	uint256 endTime; //ICO end time, timestamp automatically calculated
    uint256 exchangeRate; //cents/ETH exchange rate at the time of the sale
    uint256 ownerBalance; //owner wei Balance
    uint256 startingTokenBalance; //initial amount of tokens for sale
    uint8 tokenDecimals; //stored token decimals for calculation later
    uint8 percentBurn; //percentage of extra tokens to burn
    bool tokensSet; //true if tokens have been prepared for crowdsale
    bool rateSet; //true if exchange rate has been set

    //shows how much wei an address has contributed
  	mapping (address => uint256) hasContributed;

    //For token withdraw function, maps a user address to the amount of tokens they can withdraw
  	mapping (address => uint256) withdrawTokensMap;

    // any leftover wei that buyers contributed that didn&#39;t add up to a whole token amount
    mapping (address => uint256) leftoverWei;

  	CrowdsaleToken token; //token being sold
  }

  // Indicates when an address has withdrawn their supply of tokens
  event LogTokensWithdrawn(address indexed _bidder, uint256 Amount);

  // Indicates when an address has withdrawn their supply of extra wei
  event LogWeiWithdrawn(address indexed _bidder, uint256 Amount);

  // Logs when owner has pulled eth
  event LogOwnerEthWithdrawn(address indexed owner, uint256 amount, string Msg);

  // Generic Notice message that includes and address and number
  event LogNoticeMsg(address _buyer, uint256 value, string Msg);

  // Indicates when an error has occurred in the execution of a function
  event LogErrorMsg(string Msg);

  /// @dev Called by a crowdsale contract upon creation.
  /// @param self Stored crowdsale from crowdsale contract
  /// @param _owner Address of crowdsale owner
  /// @param _tokenPriceInCents Price of tokens in cents
  /// @param _fallbackExchangeRate Exchange rate of cents/ETH
  /// @param _capAmountInCents Total to be raised in cents
  /// @param _startTime Timestamp of sale start time
  /// @param _endTime Timestamp of sale end time
  /// @param _percentBurn Percentage of extra tokens to burn
  /// @param _token Token being sold
  function init(CrowdsaleStorage storage self,
                address _owner,
                uint256 _tokenPriceInCents,
                uint256 _fallbackExchangeRate,
                uint256 _capAmountInCents,
                uint256 _startTime,
                uint256 _endTime,
                uint8 _percentBurn,
                CrowdsaleToken _token)
  {
  	require(self.capAmount == 0);
  	require(self.owner == 0);
    require(_endTime > _startTime);
    require(_tokenPriceInCents > 0);
    require(_capAmountInCents > 0);
    require(_owner > 0);
    require(_fallbackExchangeRate > 0);
    require(_percentBurn <= 100);
    self.owner = _owner;
    self.capAmount = ((_capAmountInCents/_fallbackExchangeRate) + 1)*(10**18);
    self.startTime = _startTime;
    self.endTime = _endTime;
    self.token = _token;
    self.tokenDecimals = _token.decimals();
    self.percentBurn = _percentBurn;
    self.exchangeRate = _fallbackExchangeRate;
    changeTokenPrice(self,_tokenPriceInCents);
  }

  /// @dev function to check if the crowdsale is currently active
  /// @param self Stored crowdsale from crowdsale contract
  /// @return success
  function crowdsaleActive(CrowdsaleStorage storage self) constant returns (bool) {
  	return (now >= self.startTime && now <= self.endTime);
  }

  /// @dev function to check if the crowdsale has ended
  /// @param self Stored crowdsale from crowdsale contract
  /// @return success
  function crowdsaleEnded(CrowdsaleStorage storage self) constant returns (bool) {
  	return now > self.endTime;
  }

  /// @dev function to check if a purchase is valid
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if the transaction can buy tokens
  function validPurchase(CrowdsaleStorage storage self) internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    if (crowdsaleActive(self) && nonZeroPurchase) {
      return true;
    } else {
      LogErrorMsg("Invalid Purchase! Check send time and amount of ether.");
      return false;
    }
  }

  /// @dev Function called by purchasers to pull tokens
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if tokens were withdrawn
  function withdrawTokens(CrowdsaleStorage storage self) returns (bool) {
    bool ok;

    if (self.withdrawTokensMap[msg.sender] == 0) {
      LogErrorMsg("Sender has no tokens to withdraw!");
      return false;
    }

    if (msg.sender == self.owner) {
      if((!crowdsaleEnded(self))){
        LogErrorMsg("Owner cannot withdraw extra tokens until after the sale!");
        return false;
      } else {
        if(self.percentBurn > 0){
          uint256 _burnAmount = (self.withdrawTokensMap[msg.sender] * self.percentBurn)/100;
          self.withdrawTokensMap[msg.sender] = self.withdrawTokensMap[msg.sender] - _burnAmount;
          ok = self.token.burnToken(_burnAmount);
          require(ok);
        }
      }
    }

    var total = self.withdrawTokensMap[msg.sender];
    self.withdrawTokensMap[msg.sender] = 0;
    ok = self.token.transfer(msg.sender, total);
    require(ok);
    LogTokensWithdrawn(msg.sender, total);
    return true;
  }

  /// @dev Function called by purchasers to pull leftover wei from their purchases
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if wei was withdrawn
  function withdrawLeftoverWei(CrowdsaleStorage storage self) returns (bool) {
    require(self.hasContributed[msg.sender] > 0);
    if (self.leftoverWei[msg.sender] == 0) {
      LogErrorMsg("Sender has no extra wei to withdraw!");
      return false;
    }

    var total = self.leftoverWei[msg.sender];
    self.leftoverWei[msg.sender] = 0;
    msg.sender.transfer(total);
    LogWeiWithdrawn(msg.sender, total);
    return true;
  }

  /// @dev send ether from the completed crowdsale to the owners wallet address
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if owner withdrew eth
  function withdrawOwnerEth(CrowdsaleStorage storage self) returns (bool) {
    if (!crowdsaleEnded(self)) {
      LogErrorMsg("Cannot withdraw owner ether until after the sale!");
      return false;
    }

    require(msg.sender == self.owner);
    require(self.ownerBalance > 0);

    uint256 amount = self.ownerBalance;
    self.ownerBalance = 0;
    self.owner.transfer(amount);
    LogOwnerEthWithdrawn(msg.sender,amount,"Crowdsale owner has withdrawn all funds!");

    return true;
  }

  /// @dev Function to change the price of the token
  /// @param self Stored crowdsale from crowdsale contract
  /// @param _newPrice new token price (amount of tokens per ether)
  /// @return true if the token price changed successfully
  function changeTokenPrice(CrowdsaleStorage storage self,uint256 _newPrice) internal returns (bool) {
  	require(_newPrice > 0);

    uint256 result;
    bool err;

    (err,result) = self.exchangeRate.dividedBy(_newPrice);
    require(!err);

  	self.tokensPerEth = result + 1;
    return true;
  }

  /// @dev function that is called three days before the sale to set the token and price
  /// @param self Stored Crowdsale from crowdsale contract
  /// @param _exchangeRate  ETH exchange rate expressed in cents/ETH
  /// @return true if the exchange rate has been set
  function setTokenExchangeRate(CrowdsaleStorage storage self, uint256 _exchangeRate) returns (bool) {
    require(msg.sender == self.owner);
    require((now > (self.startTime - 3 days)) && (now < (self.startTime)));
    require(!self.rateSet);   // the exchange rate can only be set once!
    require(self.token.balanceOf(this) > 0);
    require(_exchangeRate > 0);

    uint256 _capAmountInCents;
    uint256 _tokenPriceInCents;
    uint256 _tokenBalance;
    bool err;

    (err, _capAmountInCents) = self.exchangeRate.times(self.capAmount);
    require(!err);

    (err, _tokenPriceInCents) = self.exchangeRate.dividedBy(self.tokensPerEth);
    require(!err);

    _tokenBalance = self.token.balanceOf(this);
    self.withdrawTokensMap[msg.sender] = _tokenBalance;
    self.startingTokenBalance = _tokenBalance;
    self.tokensSet = true;

    self.exchangeRate = _exchangeRate;
    self.capAmount = (_capAmountInCents/_exchangeRate) + 1;
    changeTokenPrice(self,_tokenPriceInCents + 1);
    self.rateSet = true;

    LogNoticeMsg(msg.sender,self.tokensPerEth,"Owner has sent the exchange Rate and tokens bought per ETH!");
    return true;
  }

  /// @dev fallback function to set tokens if the exchange rate function was not called
  /// @param self Stored Crowdsale from crowdsale contract
  /// @return true if tokens set successfully
  function setTokens(CrowdsaleStorage storage self) returns (bool) {
    require(msg.sender == self.owner);
    require(!self.tokensSet);

    uint256 _tokenBalance;

    _tokenBalance = self.token.balanceOf(this);
    self.withdrawTokensMap[msg.sender] = _tokenBalance;
    self.startingTokenBalance = _tokenBalance;
    self.tokensSet = true;

    return true;
  }
}

pragma solidity ^0.4.15;

/**
 * @title TokenLib
 * @author Majoolr.io
 *
 * version 1.1.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Token Library provides functionality to create a variety of ERC20 tokens.
 * See https://github.com/Majoolr/ethereum-contracts for an example of how to
 * create a basic ERC20 token.
 *
 * Majoolr works on open source projects in the Ethereum community with the
 * purpose of testing, documenting, and deploying reusable code onto the
 * blockchain to improve security and usability of smart contracts. Majoolr
 * also strives to educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library TokenLib {
  using BasicMathLib for uint256;

  struct TokenStorage {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string name;
    string symbol;
    uint256 totalSupply;
    uint256 INITIAL_SUPPLY;
    address owner;
    uint8 decimals;
    bool stillMinting;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event OwnerChange(address from, address to);
  event Burn(address indexed burner, uint256 value);
  event MintingClosed(bool mintingClosed);

  /// @dev Called by the Standard Token upon creation.
  /// @param self Stored token from token contract
  /// @param _name Name of the new token
  /// @param _symbol Symbol of the new token
  /// @param _decimals Decimal places for the token represented
  /// @param _initial_supply The initial token supply
  /// @param _allowMinting True if additional tokens can be created, false otherwise
  function init(TokenStorage storage self,
                address _owner,
                string _name,
                string _symbol,
                uint8 _decimals,
                uint256 _initial_supply,
                bool _allowMinting)
  {
    require(self.INITIAL_SUPPLY == 0);
    self.name = _name;
    self.symbol = _symbol;
    self.totalSupply = _initial_supply;
    self.INITIAL_SUPPLY = _initial_supply;
    self.decimals = _decimals;
    self.owner = _owner;
    self.stillMinting = _allowMinting;
    self.balances[_owner] = _initial_supply;
  }

  /// @dev Transfer tokens from caller&#39;s account to another account.
  /// @param self Stored token from token contract
  /// @param _to Address to send tokens
  /// @param _value Number of tokens to send
  /// @return True if completed
  function transfer(TokenStorage storage self, address _to, uint256 _value) returns (bool) {
    bool err;
    uint256 balance;

    (err,balance) = self.balances[msg.sender].minus(_value);
    require(!err);
    self.balances[msg.sender] = balance;
    //It&#39;s not possible to overflow token supply
    self.balances[_to] = self.balances[_to] + _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /// @dev Authorized caller transfers tokens from one account to another
  /// @param self Stored token from token contract
  /// @param _from Address to send tokens from
  /// @param _to Address to send tokens to
  /// @param _value Number of tokens to send
  /// @return True if completed
  function transferFrom(TokenStorage storage self,
                        address _from,
                        address _to,
                        uint256 _value)
                        returns (bool)
  {
    var _allowance = self.allowed[_from][msg.sender];
    bool err;
    uint256 balanceOwner;
    uint256 balanceSpender;

    (err,balanceOwner) = self.balances[_from].minus(_value);
    require(!err);

    (err,balanceSpender) = _allowance.minus(_value);
    require(!err);

    self.balances[_from] = balanceOwner;
    self.allowed[_from][msg.sender] = balanceSpender;
    self.balances[_to] = self.balances[_to] + _value;

    Transfer(_from, _to, _value);
    return true;
  }

  /// @dev Retrieve token balance for an account
  /// @param self Stored token from token contract
  /// @param _owner Address to retrieve balance of
  /// @return balance The number of tokens in the subject account
  function balanceOf(TokenStorage storage self, address _owner) constant returns (uint256 balance) {
    return self.balances[_owner];
  }

  /// @dev Authorize an account to send tokens on caller&#39;s behalf
  /// @param self Stored token from token contract
  /// @param _spender Address to authorize
  /// @param _value Number of tokens authorized account may send
  /// @return True if completed
  function approve(TokenStorage storage self, address _spender, uint256 _value) returns (bool) {
    self.allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /// @dev Remaining tokens third party spender has to send
  /// @param self Stored token from token contract
  /// @param _owner Address of token holder
  /// @param _spender Address of authorized spender
  /// @return remaining Number of tokens spender has left in owner&#39;s account
  function allowance(TokenStorage storage self, address _owner, address _spender) constant returns (uint256 remaining) {
    return self.allowed[_owner][_spender];
  }

  /// @dev Authorize third party transfer by increasing/decreasing allowed rather than setting it
  /// @param self Stored token from token contract
  /// @param _spender Address to authorize
  /// @param _valueChange Increase or decrease in number of tokens authorized account may send
  /// @param _increase True if increasing allowance, false if decreasing allowance
  /// @return True if completed
  function approveChange (TokenStorage storage self, address _spender, uint256 _valueChange, bool _increase)
                          returns (bool)
  {
    uint256 _newAllowed;
    bool err;

    if(_increase) {
      (err, _newAllowed) = self.allowed[msg.sender][_spender].plus(_valueChange);
      require(!err);

      self.allowed[msg.sender][_spender] = _newAllowed;
    } else {
      if (_valueChange > self.allowed[msg.sender][_spender]) {
        self.allowed[msg.sender][_spender] = 0;
      } else {
        _newAllowed = self.allowed[msg.sender][_spender] - _valueChange;
        self.allowed[msg.sender][_spender] = _newAllowed;
      }
    }

    Approval(msg.sender, _spender, _newAllowed);
    return true;
  }

  /// @dev Change owning address of the token contract, specifically for minting
  /// @param self Stored token from token contract
  /// @param _newOwner Address for the new owner
  /// @return True if completed
  function changeOwner(TokenStorage storage self, address _newOwner) returns (bool) {
    require((self.owner == msg.sender) && (_newOwner > 0));

    self.owner = _newOwner;
    OwnerChange(msg.sender, _newOwner);
    return true;
  }

  /// @dev Mints additional tokens, new tokens go to owner
  /// @param self Stored token from token contract
  /// @param _amount Number of tokens to mint
  /// @return True if completed
  function mintToken(TokenStorage storage self, uint256 _amount) returns (bool) {
    require((self.owner == msg.sender) && self.stillMinting);
    uint256 _newAmount;
    bool err;

    (err, _newAmount) = self.totalSupply.plus(_amount);
    require(!err);

    self.totalSupply =  _newAmount;
    self.balances[self.owner] = self.balances[self.owner] + _amount;
    Transfer(0x0, self.owner, _amount);
    return true;
  }

  /// @dev Permanent stops minting
  /// @param self Stored token from token contract
  /// @return True if completed
  function closeMint(TokenStorage storage self) returns (bool) {
    require(self.owner == msg.sender);

    self.stillMinting = false;
    MintingClosed(true);
    return true;
  }

  /// @dev Permanently burn tokens
  /// @param self Stored token from token contract
  /// @param _amount Amount of tokens to burn
  /// @return True if completed
  function burnToken(TokenStorage storage self, uint256 _amount) returns (bool) {
      uint256 _newBalance;
      bool err;

      (err, _newBalance) = self.balances[msg.sender].minus(_amount);
      require(!err);

      self.balances[msg.sender] = _newBalance;
      self.totalSupply = self.totalSupply - _amount;
      Burn(msg.sender, _amount);
      Transfer(msg.sender, 0x0, _amount);
      return true;
  }
}

pragma solidity ^0.4.13;

/**
 * @title Basic Math Library
 * @author Majoolr.io
 *
 * version 1.1.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Basic Math Library is inspired by the Safe Math library written by
 * OpenZeppelin at https://github.com/OpenZeppelin/zeppelin-solidity/ .
 * Majoolr works on open source projects in the Ethereum community with the
 * purpose of testing, documenting, and deploying reusable code onto the
 * blockchain to improve security and usability of smart contracts. Majoolr
 * also strives to educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: majoolr.io, openzeppelin.org
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library BasicMathLib {
  event Err(string typeErr);

  /// @dev Multiplies two numbers and checks for overflow before returning.
  /// Does not throw but rather logs an Err event if there is overflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The product of a and b, or 0 if there is overflow
  function times(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      res := mul(a,b)
      switch or(iszero(b), eq(div(res,b), a))
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("times func overflow");
  }

  /// @dev Divides two numbers but checks for 0 in the divisor first.
  /// Does not throw but rather logs an Err event if 0 is in the divisor.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if `b` is 0
  /// @return res The quotient of a and b, or 0 if `b` is 0
  function dividedBy(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      switch iszero(b)
      case 0 {
        res := div(a,b)
        mstore(add(mload(0x40),0x20),res)
        return(mload(0x40),0x40)
      }
    }
    Err("tried to divide by zero");
    return (true, 0);
  }

  /// @dev Adds two numbers and checks for overflow before returning.
  /// Does not throw but rather logs an Err event if there is overflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The sum of a and b, or 0 if there is overflow
  function plus(uint256 a, uint256 b) constant returns (bool err, uint256 res) {
    assembly{
      res := add(a,b)
      switch and(eq(sub(res,b), a), or(gt(res,b),eq(res,b)))
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("plus func overflow");
  }

  /// @dev Subtracts two numbers and checks for underflow before returning.
  /// Does not throw but rather logs an Err event if there is underflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is underflow
  /// @return res The difference between a and b, or 0 if there is underflow
  function minus(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      res := sub(a,b)
      switch eq(and(eq(add(res,b), a), or(lt(res,a), eq(res,a))), 1)
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("minus func underflow");
  }
}