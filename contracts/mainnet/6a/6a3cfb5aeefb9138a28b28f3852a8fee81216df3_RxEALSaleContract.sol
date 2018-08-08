pragma solidity ^0.4.20;



/* ********** Zeppelin Solidity - v1.3.0 ********** */



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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



/* ********** RxEAL Token Contract ********** */



/**
 * @title RxEALTokenContract
 * @author RxEAL.com
 *
 * ERC20 Compatible token
 * Zeppelin Solidity - v1.3.0
 */

contract RxEALTokenContract is StandardToken {

  /* ********** Token Predefined Information ********** */

  // Predefine token info
  string public constant name = "RxEAL";
  string public constant symbol = "RXL";
  uint256 public constant decimals = 18;

  /* ********** Defined Variables ********** */

  // Total tokens supply 96 000 000
  // For ethereum wallets we added decimals constant
  uint256 public constant INITIAL_SUPPLY = 96000000 * (10 ** decimals);
  // Vault where tokens are stored
  address public vault = this;
  // Sale agent who has permissions to sell tokens
  address public salesAgent;
  // Array of token owners
  mapping (address => bool) public owners;

  /* ********** Events ********** */

  // Contract events
  event OwnershipGranted(address indexed _owner, address indexed revoked_owner);
  event OwnershipRevoked(address indexed _owner, address indexed granted_owner);
  event SalesAgentPermissionsTransferred(address indexed previousSalesAgent, address indexed newSalesAgent);
  event SalesAgentRemoved(address indexed currentSalesAgent);
  event Burn(uint256 value);

  /* ********** Modifiers ********** */

  // Throws if called by any account other than the owner
  modifier onlyOwner() {
    require(owners[msg.sender] == true);
    _;
  }

  /* ********** Functions ********** */

  // Constructor
  function RxEALTokenContract() {
    owners[msg.sender] = true;
    totalSupply = INITIAL_SUPPLY;
    balances[vault] = totalSupply;
  }

  // Allows the current owner to grant control of the contract to another account
  function grantOwnership(address _owner) onlyOwner public {
    require(_owner != address(0));
    owners[_owner] = true;
    OwnershipGranted(msg.sender, _owner);
  }

  // Allow the current owner to revoke control of the contract from another owner
  function revokeOwnership(address _owner) onlyOwner public {
    require(_owner != msg.sender);
    owners[_owner] = false;
    OwnershipRevoked(msg.sender, _owner);
  }

  // Transfer sales agent permissions to another account
  function transferSalesAgentPermissions(address _salesAgent) onlyOwner public {
    SalesAgentPermissionsTransferred(salesAgent, _salesAgent);
    salesAgent = _salesAgent;
  }

  // Remove sales agent from token
  function removeSalesAgent() onlyOwner public {
    SalesAgentRemoved(salesAgent);
    salesAgent = address(0);
  }

  // Transfer tokens from vault to account if sales agent is correct
  function transferTokensFromVault(address _from, address _to, uint256 _amount) public {
    require(salesAgent == msg.sender);
    balances[vault] = balances[vault].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(_from, _to, _amount);
  }

  // Allow the current owner to burn a specific amount of tokens from the vault
  function burn(uint256 _value) onlyOwner public {
    require(_value > 0);
    balances[vault] = balances[vault].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_value);
  }

}



/* ********** RxEAL Presale Contract ********** */



contract RxEALSaleContract {
  // Extend uint256 to use SafeMath functions
  using SafeMath for uint256;

  /* ********** Defined Variables ********** */

  // The token being sold
  RxEALTokenContract public token;

  // Start and end timestamps where sales are allowed (both inclusive)
  uint256 public startTime = 1520856000;
  uint256 public endTime = 1523448000;

  // Address where funds are collected
  address public wallet1 = 0x56E4e5d451dF045827e214FE10bBF99D730d9683;
  address public wallet2 = 0x8C0988711E60CfF153359Ab6CFC8d45565C6ce79;
  address public wallet3 = 0x0EdF5c34ddE2573f162CcfEede99EeC6aCF1c2CB;
  address public wallet4 = 0xcBdC5eE000f77f3bCc0eFeF0dc47d38911CBD45B;

  // How many token units a buyer gets per wei. Rate per ether equals rate * (10 ** token.decimals())
  // Cap in ethers

  // Rate and cap for tier 1
  uint256 public tier_rate_1 = 1800;
  uint256 public tier_cap_1 = 4800000;
  // Rate and cap for tier 2
  uint256 public tier_rate_2 = 1440;
  uint256 public tier_cap_2 = 14400000;
  // Rate and cap for tier 3
  uint256 public tier_rate_3 = 1320;
  uint256 public tier_cap_3 = 14400000;
  // Rate and cap for tier 4
  uint256 public tier_rate_4 = 1200;
  uint256 public tier_cap_4 = 14400000;

  uint256 public hard_cap;

  // Current tier
  uint8 public current_tier = 1;

  // Amount of raised money in wei
  uint256 public weiRaised;

  // Amount of sold tokens
  uint256 public soldTokens;
  uint256 public current_tier_sold_tokens;

  /* ********** Events ********** */

  // Event for token purchase logging
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);

  /* ********** Functions ********** */

  // Constructor
  function RxEALSaleContract() {
    token = RxEALTokenContract(0xD6682Db9106e0cfB530B697cA0EcDC8F5597CD15);

    tier_cap_1 = tier_cap_1 * (10 ** token.decimals());
    tier_cap_2 = tier_cap_2 * (10 ** token.decimals());
    tier_cap_3 = tier_cap_3 * (10 ** token.decimals());
    tier_cap_4 = tier_cap_4 * (10 ** token.decimals());

    hard_cap = tier_cap_1 + tier_cap_2 + tier_cap_3 + tier_cap_4;
  }

  // Fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // Tier calculation function
  function tier_action(
    uint8 tier,
    uint256 left_wei,
    uint256 tokens_amount,
    uint8 next_tier,
    uint256 tier_rate,
    uint256 tier_cap
  ) internal returns (uint256, uint256) {
    if (current_tier == tier) {
      // Tokens to be sold
      uint256 tokens_can_be_sold;
      // Temp tokens to be sold
      uint256 tokens_to_be_sold = left_wei.mul(tier_rate);
      // New temporary sold tier tokens
      uint256 new_tier_sold_tokens = current_tier_sold_tokens.add(tokens_to_be_sold);

      if (new_tier_sold_tokens >= tier_cap) {
        // If purchase reached tier cap

        // Calculate spare tokens
        uint256 spare_tokens = new_tier_sold_tokens.sub(tier_cap);
        // Tokens to be sold
        tokens_can_be_sold = tokens_to_be_sold.sub(spare_tokens);

        // Reset current tier sold tokens
        current_tier_sold_tokens = 0;
        // Switch to next tier
        current_tier = next_tier;
      } else {
        // If purchase not reached tier cap

        // Tokens to be sold
        tokens_can_be_sold = tokens_to_be_sold;
        // Update current tier sold tokens
        current_tier_sold_tokens = new_tier_sold_tokens;
      }

      // Wei to buy amount of tokens
      uint256 wei_amount = tokens_can_be_sold.div(tier_rate);
      // Spare wei amount
      left_wei = left_wei.sub(wei_amount);
      // Tokens to be sold in purchase
      tokens_amount = tokens_amount.add(tokens_can_be_sold);
    }

    return (left_wei, tokens_amount);
  }

  // Low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(validPurchase());

    uint256 left_wei = msg.value;
    uint256 tokens_amount;

    (left_wei, tokens_amount) = tier_action(1, left_wei, tokens_amount, 2, tier_rate_1, tier_cap_1);
    (left_wei, tokens_amount) = tier_action(2, left_wei, tokens_amount, 3, tier_rate_2, tier_cap_2);
    (left_wei, tokens_amount) = tier_action(3, left_wei, tokens_amount, 4, tier_rate_3, tier_cap_3);
    (left_wei, tokens_amount) = tier_action(4, left_wei, tokens_amount, 4, tier_rate_4, tier_cap_4);

    // Update state of raised wei amount and sold tokens ammount
    uint256 purchase_wei_amount = msg.value.sub(left_wei);
    weiRaised = weiRaised.add(purchase_wei_amount);
    soldTokens = soldTokens.add(tokens_amount);

    // If have spare wei, send it back to beneficiary
    if (left_wei > 0) {
      beneficiary.transfer(left_wei);
    }

    // Tranfer tokens from vault
    token.transferTokensFromVault(msg.sender, beneficiary, tokens_amount);
    TokenPurchase(msg.sender, beneficiary, purchase_wei_amount, tokens_amount);

    forwardFunds(purchase_wei_amount);
  }

  // Send wei to the fund collection wallets
  function forwardFunds(uint256 weiAmount) internal {
    uint256 value = weiAmount.div(4);

    // If buyer sends amount of wei that can not be divided to 4 without float point, send all wei to first wallet
    if (value.mul(4) != weiAmount) {
      wallet1.transfer(weiAmount);
    } else {
      wallet1.transfer(value);
      wallet2.transfer(value);
      wallet3.transfer(value);
      wallet4.transfer(value);
    }
  }

  // Validate if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinCap = soldTokens < hard_cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

  // Validate if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime || soldTokens >= hard_cap;
  }
}