pragma solidity ^0.4.23;

// File: contracts/P4RTYRelay.sol

/*
 * Visit: https://p4rty.io
 * Discord: https://discord.gg/7y3DHYF
 * Copyright Mako Labs LLC 2018 All Rights Reseerved
*/

interface P4RTYRelay {
    /**
    * @dev Will relay to internal implementation
    * @param beneficiary Token purchaser
    * @param tokenAmount Number of tokens to be minted
    */
    function relay(address beneficiary, uint256 tokenAmount) external;
}

// File: contracts/ReinvestProxy.sol

/*
 * Visit: https://p4rty.io
 * Discord: https://discord.gg/7y3DHYF
 * Copyright Mako Labs LLC 2018 All Rights Reseerved
*/
interface ReinvestProxy {

    /// @dev Converts all incoming ethereum to tokens for the caller,
    function reinvestFor(address customer) external payable;

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

// File: contracts/P4.sol

/*
 * Visit: https://p4rty.io
 * Discord: https://discord.gg/7y3DHYF
 * Stable + DIVIS: Whale and Minow Friendly
 * Fees balanced for capital preservation for long term HODLERS
 * Active depositors rewarded with P4RTY tokens; sellers forgiveness, just 5%
 * 50% of ETH value in earned P4RTY token rewards
 * P4RTYRelay is notified on all dividend producing transactions
 *
 *
 * P4
 * The worry free way to earn ETH & P4RTY reward tokens
 *
 * -> What?
 * The first true Virtual Deposit Contract:
 * [✓] Pegged to ETH, P4 protects your ETH balance; .001 ETH per P4 token
 * [✓] The only VDC that is part of the P4RTY Entertainment Network
 * [✓] Earn ERC20 P4RTY tokens on all ETH deposit activities; send them to family and friends
 * [✓] Referrals permanently saved in contract; reliable income for supporters, at any scale
 * [✓] 15% dividends for token purchase, shared among all token holders.
 * [✓] 5% dividends for token selling, shared among all token holders.
 * [✓] 1% dividends for token transfer, shared among all token holders.
 * [✓] 4.5% of deposit on referrals.
 * [✓] 3% of deposit for maintenance fee on deposits for development, operations, and promotion
 * [✓] 100 tokens to activate referral links; .1 ETH
*/

contract P4 is Whitelist {


    /*=================================
    =            MODIFIERS            =
    =================================*/

    /// @dev Only people with tokens
    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    /// @dev Only people with profits
    modifier onlyDivis {
        require(myDividends(true) > 0);
        _;
    }


    /*==============================
    =            EVENTS            =
    ==============================*/

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onReinvestmentProxy(
        address indexed customerAddress,
        address indexed destinationAddress,
        uint256 ethereumReinvested
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    /// @dev 15% dividends for token purchase
    uint256  internal entryFee_ = 15;

    /// @dev 1% dividends for token transfer
    uint256  internal transferFee_ = 1;

    /// @dev 5% dividends for token selling
    uint256  internal exitFee_ = 5;

    /// @dev 30% of entryFee_  is given to referrer
    uint256  internal referralFee_ = 30;

    /// @dev 20% of entryFee/exit fee is given to maintainer
    uint256  internal maintenanceFee = 20;
    address  internal maintenanceAddress;

    uint256 constant internal tokenRatio_ = 1000;
    uint256 constant internal magnitude = 2 ** 64;

    /// @dev proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 100e18;


    /*=================================
     =            DATASETS            =
     ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    //on chain referral tracking
    mapping(address => address) public referrals;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

    P4RTYRelay public relay;


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    constructor(address relayAddress)  public {

        relay = P4RTYRelay(relayAddress);

        //assume caller as default
        updateMaintenanceAddress(msg.sender);
    }

    function updateMaintenanceAddress(address maintenance) onlyOwner public {
        maintenanceAddress = maintenance;
    }

    /// @dev Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
    function buyFor(address _customerAddress, address _referredBy) onlyWhitelisted public payable returns (uint256) {
        setReferral(_referredBy);
        return purchaseTokens(_customerAddress, msg.value);
    }

    /// @dev Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
    function buy(address _referredBy) public payable returns (uint256) {
        setReferral(_referredBy);
        return purchaseTokens(msg.sender, msg.value);
    }

    function setReferral(address _referredBy) internal {
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=_referredBy;
        }
    }

    /**
     * @dev Fallback function to handle ethereum that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    function() payable public {
        purchaseTokens(msg.sender, msg.value);
    }

    /// @dev Converts all of caller&#39;s dividends to tokens.
    function reinvest() onlyDivis public {
        address _customerAddress = msg.sender;

        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function reinvestByProxy(address _customerAddress) onlyWhitelisted public {
        // fetch dividends
        uint256 _dividends = dividendsOf(_customerAddress); // retrieve ref. bonus later in the code


        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        ReinvestProxy reinvestProxy =  ReinvestProxy(msg.sender);
        reinvestProxy.reinvestFor.value(_dividends)(_customerAddress);

        emit  onReinvestmentProxy(_customerAddress, msg.sender, _dividends);


    }

    /// @dev Alias of sell() and withdraw().
    function exit() external {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

        // lambo delivery service
        withdraw();
    }

    /// @dev Withdraws all of the callers earnings.
    function withdraw() onlyDivis public {

        address _customerAddress = msg.sender;
        // setup data
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        _customerAddress.transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }


    /// @dev Liquifies tokens to ethereum.
    function sell(uint256 _amountOfTokens) onlyTokenHolders public {
        address _customerAddress = msg.sender;


        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);


        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends,maintenanceFee),100);
        //maintenance and referral come out of the exitfee
        uint256 _dividends = SafeMath.sub(_undividedDividends, _maintenance);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _undividedDividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;


        //Apply maintenance fee as a referral
        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], _maintenance);

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }


    /**
     * @dev Transfer tokens from the caller to a new holder.
     *  Remember, there&#39;s a 15% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool){

        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if (myDividends(true) > 0) {
            withdraw();
        }

        // liquify a percentage of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        // fire event
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;
    }


    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/

    /**
     * @dev Method to view the current Ethereum stored in the contract
     *  Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /// @dev Retrieve the tokens owned by the caller.
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /// @dev Return the sell price of 1 individual token.
    function sellPrice() public view returns (uint256) {
        uint256 _ethereum = tokensToEthereum_(1e18);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        return _taxedEthereum;

    }

    /// @dev Return the buy price of 1 individual token.
    function buyPrice() public view returns (uint256) {
        uint256 _ethereum = tokensToEthereum_(1e18);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

        return _taxedEthereum;

    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(address _customerAddress, uint256 _incomingEthereum) internal returns (uint256) {
        // data setup
        address _referredBy = referrals[_customerAddress];
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends,maintenanceFee),100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);
        //maintenance and referral come out of the buyin
        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_referralBonus,_maintenance));
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        uint256 _tokenAllocation = SafeMath.div(_incomingEthereum,2);


        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        //Apply maintenance fee as a referral
        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], _maintenance);

        // is the user referred by a masternode?
        if (
        // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        // we can&#39;t give people infinite ethereum
        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        // really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        //Notifying the relay is simple and should represent the total economic activity which is the _incomingEthereum
        //Every player is a customer and mints their own tokens when the buy or reinvest, relay P4RTY 50/50
        relay.relay(maintenanceAddress,_tokenAllocation);
        relay.relay(_customerAddress,_tokenAllocation);

        // fire event
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }

    /**
     * @dev Calculate Token price based on an amount of incoming ethereum
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum) internal pure returns (uint256) {
        return SafeMath.mul(_ethereum, tokenRatio_);
    }

    /**
     * @dev Calculate token sell value.
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToEthereum_(uint256 _tokens) internal pure returns (uint256) {
        return SafeMath.div(_tokens, tokenRatio_);
    }

}

// File: contracts/P5.sol

// solhint-disable-line


/*
 * Visit: https://p4rty.io
 * Discord: https://discord.gg/7y3DHYF
 * Stable + DIVIS: Whale and Minow Friendly
 * Fees balanced for maximum dividends for ALL
 * Active depositors rewarded with P4RTY tokens; it is impossible to sell P5 is meant to be shared
 * 50% of ETH value in earned P4RTY token rewards
 * P4RTYRelay is notified on all dividend producing transactions
 *
 *
 * P5
 * The worry free way to earn A TON OF ETH & P4RTY reward tokens
 *
 * -> What?
 * The first Ethereum Bonded Pure Dividend Token:
 * [✓] Pegged to ETH, P5 maximizes your ETH  dividends; .001 ETH per P5 token
 * [✓] The only dividend printing press that is part of the P4RTY Entertainment Network
 * [✓] Earn ERC20 P4RTY tokens on all ETH deposit activities; send them to family and friends
 * [✓] Referrals permanently saved in contract; reliable income for supporters, at any scale
 * [✓] 99% dividends for token purchase, shared among all token holders.
 * [✓] 1% dividends for token transfer, shared among all token holders.
 * [✓] 4.75% of deposit on referrals.
 * [✓] 3.8% of deposit for maintenance fee on deposits for development, operations, and promotion
 * [✓] 100 tokens to activate referral links; 2 ETH
*/

contract P5 is P4 {

    /**
     * Constructor
     */
    constructor(address relayAddress) P4(relayAddress) public {
        /// @dev 99% dividends for token purchase
        entryFee_ = 99;

        /// @dev 1% dividends for token transfer
        transferFee_ = 1;

        /// @dev 5% dividends for token selling
        exitFee_ = 5;

        /// @dev 5% of entryFee_  is given to referrer
        referralFee_ = 5;

        /// @dev 4% of entryFee/exit fee is given to maintainer
        maintenanceFee = 4;
    }



    //Override unsupported functions; No selling of P5 tokens
    function sell(uint256 _amountOfTokens)  public{
        require(false && _amountOfTokens > 0);
    }

    //Instead of exiting use the transfer function and change someone&#39;s LIFE!!! P4RTY ON!!!
    function exit() external {
        require(false);
    }

}