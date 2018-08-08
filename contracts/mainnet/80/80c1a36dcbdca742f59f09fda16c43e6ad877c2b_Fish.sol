pragma solidity ^ 0.4 .15;


/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}



/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath {

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  /**
   *
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) revert();
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)  returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract owned {
    address owner;

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract Fish is owned, StandardToken {

  string public constant TermsOfUse = "https://github.com/triangles-things/fish.project/blob/master/terms-of-use.md";

  /*
   * State variables
   */

  string public constant symbol = "FSH";
  string public constant name = "Fish";
  uint8 public constant decimals = 3;

  /*
   * Constructor function
   */

  function Fish() {
    owner = msg.sender;
    balances[msg.sender] = 1;                                                   // Owner can now be a referral
    totalSupply = 1;
    buyPrice_wie= 100000000000000;                                              // 100 szabo per one token. One unit = 1000 tokens. 1 ether = 10 units
    sellPrice_wie = buyPrice_wie * sell_ppc / 100;
  }

  function () payable { revert(); }

  /*
   * SECTION: PRICE GROWTH
   *
   * This section is responsible for daily price increase. Once per day the buy price will be increased 
   * through adjustPrice modifier. The price update happens before buy and sell functions are executed.
   * Contract owner has only one way to control the growth rate here - setGrowth.
   */

  // Growth rate is present in parts per million (ppm)
  uint32 public dailyGrowth_ppm = 6100;                                         // default growth is 20% (0.61% per day)
  uint public dailyGrowthUpdated_date = now;                                    // Don&#39;t update it on first day of contract
  
  uint32 private constant dailyGrowthMin_ppm =  6096;                           // 20% every month in price growth or 0.00610 daily
  uint32 private constant dailyGrowthMax_ppm = 23374;                           // 100% in growth every month or 0,02337 daily
  
  uint32 public constant sell_ppc = 90;                                         // Sell price is 90% of buy price

  event DailyGrowthUpdate(uint _newRate_ppm);
  event PriceAdjusted(uint _newBuyPrice_wei, uint _newSellPrice_wei);

  /*
   * MODIFIER
   * If last update happened more than one day ago, update the price, save the time of current price update
   * Adjust sell price and log the event
   */
  modifier adjustPrice() {
    if ( (dailyGrowthUpdated_date + 1 days) < now ) {
      dailyGrowthUpdated_date = now;
      buyPrice_wie = buyPrice_wie * (1000000 + dailyGrowth_ppm) / 1000000;
      sellPrice_wie = buyPrice_wie * sell_ppc / 100;
      PriceAdjusted(buyPrice_wie, sellPrice_wie);
    }
    _;
  }

  /* 
   * OWNER ONLY; EXTERNAL METHOD
   * setGrowth can accept values within range from 20% to 100% of growth per month (based on 30 days per month assumption).
   * 
   *   Formula is:
   *
   *       buyPrice_eth = buyPrice_eth * (1000000 + dailyGrowthMin_ppm) / 1000000;
   *       ^new value     ^current value  ^1.0061 (if dailyGrowth_ppm == 6100)
   *
   *       1.0061^30 = 1.20 (if dailyGrowth_ppm == 6100)
   *       1.023374^30 = 2 (if dailyGrowth_ppm == 23374)
   * 
   *  Some other daily rates
   *
   *   Per month -> Value in ppm
   *      1.3    ->  8783
   *      1.4    -> 11278
   *      1.5    -> 13607
   *      1.6    -> 15790
   *      1.7    -> 17844
   *      1.8    -> 19786
   */
  function setGrowth(uint32 _newGrowth_ppm) onlyOwner external returns(bool result) {
    if (_newGrowth_ppm >= dailyGrowthMin_ppm &&
        _newGrowth_ppm <= dailyGrowthMax_ppm
    ) {
      dailyGrowth_ppm = _newGrowth_ppm;
      DailyGrowthUpdate(_newGrowth_ppm);
      return true;
    } else {
      return false;
    }
  }

  /* 
   * SECTION: TRADING
   *
   * This section is responsible purely for trading the tokens. User can buy tokens, user can sell tokens.
   *
   */

  uint256 public sellPrice_wie;
  uint256 public buyPrice_wie;

  /*
   * EXTERNAL METHOD
   * User can buy arbitrary amount of tokens. Before amount of tokens will be calculated, the price of tokens 
   * has to be adjusted. This happens in adjustPrice modified before function call.
   *
   * Short description of this method
   *
   *   Calculate tokens that user is buying
   *   Assign awards ro refereals
   *   Add some bounty for new users who set referral before first buy
   *   Send tokens that belong to contract or if there is non issue more and send them to user
   *
   * Read -> https://github.com/triangles-things/fish.project/blob/master/terms-of-use.md
   */
  function buy() adjustPrice payable external {
    require(msg.value >= buyPrice_wie);
    var amount = safeDiv(msg.value, buyPrice_wie);

    assignBountryToReferals(msg.sender, amount);                                // First assign bounty

    // Buy discount if User is a new user and has set referral
    if ( balances[msg.sender] == 0 && referrals[msg.sender][0] != 0 ) {
      // Check that user has to wait at least two weeks before he get break even on what he will get
      amount = amount * (100 + landingDiscount_ppc) / 100;
    }

    issueTo(msg.sender, amount);
  }

  /*
   * EXTERNAL METHOD
   * User can sell tokens back to contract.
   *
   * Short description of this method
   *
   *   Adjust price
   *   Calculate tokens price that user is selling 
   *   Make all possible checks
   *   Transfer the money
   */
  function sell(uint256 _amount) adjustPrice external {
    require(_amount > 0 && balances[msg.sender] >= _amount);
    uint moneyWorth = safeMul(_amount, sellPrice_wie);
    require(this.balance > moneyWorth);                                         // We can&#39;t sell if we don&#39;t have enough money
    
    if (
        balances[this] + _amount > balances[this] &&
        balances[msg.sender] - _amount < balances[msg.sender]
    ) {
      balances[this] = safeAdd(balances[this], _amount);                        // adds the amount to owner&#39;s balance
      balances[msg.sender] = safeSub(balances[msg.sender], _amount);            // subtracts the amount from seller&#39;s balance
      if (!msg.sender.send(moneyWorth)) {                                       // sends ether to the seller. It&#39;s important
        revert();                                                               // to do this last to avoid recursion attacks
      } else {
        Transfer(msg.sender, this, _amount);                                    // executes an event reflecting on the change
      }        
    } else {
      revert();                                                                 // checks if the sender has enough to sell
    }  
  }

  /*
   * PRIVATE METHOD
   * Issue  new tokens to contract
   */
  function issueTo(address _beneficiary, uint256 _amount_tkns) private {
    if (
        balances[this] >= _amount_tkns
    ) {
      // All tokens are taken from balance
      balances[this] = safeSub(balances[this], _amount_tkns);
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _amount_tkns);
    } else {
      // Balance will be lowered and new tokens will be issued
      uint diff = safeSub(_amount_tkns, balances[this]);

      totalSupply = safeAdd(totalSupply, diff);
      balances[this] = 0;
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _amount_tkns);
    }
    
    Transfer(this, _beneficiary, _amount_tkns);
  }
  
  /*
   * SECTION: BOUNTIES
   *
   * This section describes all possible awards.
   */
    
  mapping(address => address[3]) referrals;
  mapping(address => uint256) bounties;

  uint32 public constant landingDiscount_ppc = 4;                               // Landing discount is 4%

  /*
   * EXTERNAL METHOD 
   * Set your referral first. You will get 4% more tokens on your first buy and trigger a
   * reward of whoever told you about this contract. A win-win scenario.
   */
  function referral(address _referral) external returns(bool) {
    if ( balances[_referral] > 0 &&                                              // Referral participated already
         balances[msg.sender] == 0  &&                                          // Sender is a new user
         referrals[msg.sender][0] == 0                                           // Not returning user. User can not reassign their referrals but they can assign them later on
    ) {
      var referral_referrals = referrals[_referral];
      referrals[msg.sender] = [_referral, referral_referrals[0], referral_referrals[1]];
      return true;
    }
    
    return false;
  }

  /*
   * PRIVATE METHOD
   * Award bounties to referrals.
   */ 
  function assignBountryToReferals(address _referralsOf, uint256 _amount) private {
    var refs = referrals[_referralsOf];
    
    if (refs[0] != 0) {
     issueTo(refs[0], (_amount * 4) / 100);                                     // 4% bounty to direct referral
      if (refs[1] != 0) {
        issueTo(refs[1], (_amount * 2) / 100);                                  // 2% bounty to referral of referral
        if (refs[2] != 0) {
          issueTo(refs[2], (_amount * 1) / 100);                                // 1% bounty to referral of referral of referral
       }
      }
    }
  }

  /*
   * OWNER ONLY; EXTERNAL METHOD
   * Santa is coming! Who ever made impact to promote the Fish and can prove it will get the bonus
   */
  function assignBounty(address _account, uint256 _amount) onlyOwner external returns(bool) {
    require(_amount > 0); 
     
    if (balances[_account] > 0 &&                                               // Account had participated already
        bounties[_account] + _amount <= 1000000                                 // no more than 100 token units per account
    ) {
      issueTo(_account, _amount);
      return true;
    } else {
      return false;
    }
  }
}