pragma solidity ^0.4.19;

/**
 * BRX.SPACE (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="593a36372d383a2d193b2b21772a29383a3c">[email&#160;protected]</a>)
 * 
 * BRX token is a virtual token, governed by ERC20-compatible
 * Ethereum Smart Contract and secured by Ethereum Blockchain
 *
 * The official website is https://brx.space
 * 
 * The uints are all in wei and atto tokens (*10^-18)

 * The contract code itself, as usual, is at the end, after all the connected libraries
 * Developed by 262dfb6c55bf6ac215fac30181bdbfb8a2872cc7e3ea7cffe3a001621bb559e2
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }
  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * Fix for the ERC20 short address attack  
   */
  modifier onlyPayloadSize(uint size) {
   require(msg.data.length >= size + 4);
   _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0) &&
        _value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint balance) {
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

  mapping (address => mapping (address => uint)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_to != address(0) &&
        _value <= balances[_from] &&
        _value <= allowed[_from][msg.sender]);

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
  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract BRXToken is StandardToken, Ownable {
  using SafeMath for uint;

  //---------------  Info for ERC20 explorers  -----------------//
  string public constant name = "BRX Coin";
  string public constant symbol = "BRX";
  uint8 public constant decimals = 18;

  //----------------------  Constants  -------------------------//
  uint private constant atto = 1000000000000000000;
  uint private constant INITIAL_SUPPLY = 15000000 * atto; // 15 mln BRX. Impossible to mint more than this
  uint public totalSupply = INITIAL_SUPPLY;

  //----------------------  Variables  -------------------------//
  // Made up ICO address (designating the token pool reserved for ICO, no one has access to it)
  address public ico_address = 0x1F01f01f01f01F01F01f01F01F01f01F01f01F01;
  address public teamWallet = 0x58096c1dCd5f338530770B1f6Fe0AcdfB90Cc87B;
  address public addrBRXPay = 0x2F02F02F02F02f02f02f02f02F02F02f02f02f02;

  uint private current_supply = 0; // Holding the number of all the coins in existence
  uint private ico_starting_supply = 0; // How many atto tokens *were* available for sale at the beginning of the ICO
  uint private current_price_atto_tokens_per_wei = 0; // Holding current price (determined by the algorithm in buy())

  //--------------  Flags describing ICO stages  ---------------//
  bool private preSoldSharesDistributed = false; // Prevents accidental re-distribution of shares
  bool private isICOOpened = false;
  bool private isICOClosed = false;
  // 3 stages:
  // Contract has just been deployed and initialized. isICOOpened == false, isICOClosed == false
  // ICO has started, now anybody can buy(). isICOOpened == true, isICOClosed == false
  // ICO has finished, now the team can receive the ether. isICOOpened == false, isICOClosed == true

  //-------------------  Founder Members  ----------------------//
  uint public founderMembers = 0;
  mapping(uint => address) private founderOwner;
  mapping(address => uint) founderMembersInvest;
  
  //----------------------  Premiums  --------------------------//
  uint[] private premiumPacks;
  mapping(address => bool) private premiumICOMember;
  mapping(address => uint) private premiumPacksPaid;
  mapping(address => bool) public frozenAccounts;

  //-----------------------  Events  ---------------------------//
  event ICOOpened();
  event ICOClosed();

  event PriceChanged(uint old_price, uint new_price);
  event SupplyChanged(uint supply, uint old_supply);

  event FrozenFund(address _from, bool _freeze);

  event BRXAcquired(address account, uint amount_in_wei, uint amount_in_brx);
  event BRXNewFounder(address account, uint amount_in_brx);

  // ***************************************************************************
  // Constructor

  function BRXToken() public {
    // Some percentage of the tokens is already reserved by early employees and investors
    // Here we&#39;re initializing their balances
    distributePreSoldShares();

    // Starting price
    current_price_atto_tokens_per_wei = calculateCurrentPrice(1);

    // Some other initializations
    premiumPacks.length = 0;
  }

  // Sending ether directly to the contract invokes buy() and assigns tokens to the sender
  function () public payable {
    buy();
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(
    address tokenAddress, uint tokens
  ) public onlyOwner
    returns (bool success) {
    return StandardToken(tokenAddress).transfer(owner, tokens);
  }

  // ***************************************************************************

  // Buy token by sending ether here
  //
  // Price is being determined by the algorithm in recalculatePrice()
  // You can also send the ether directly to the contract address
  function buy() public payable {
    require(msg.value != 0 && isICOOpened == true && isICOClosed == false);

    // Deciding how many tokens can be bought with the ether received
    uint tokens = getAttoTokensAmountPerWeiInternal(msg.value);

    // Don&#39;t allow to buy more than 1% per transaction (secures from huge investors swalling the whole thing in 1 second)
    uint allowedInOneTransaction = current_supply / 100;
    require(tokens < allowedInOneTransaction &&
        tokens <= balances[ico_address]);

    // Transfer from the ICO pool
    balances[ico_address] = balances[ico_address].sub(tokens); // if not enough, will throw
    balances[msg.sender] = balances[msg.sender].add(tokens);
    premiumICOMember[msg.sender] = true;
    
    // Check if sender has become a founder member
    if (balances[msg.sender] >= 2000000000000000000000) {
        if (founderMembersInvest[msg.sender] == 0) {
            founderOwner[founderMembers] = msg.sender;
            founderMembers++; BRXNewFounder(msg.sender, balances[msg.sender]);
        }
        founderMembersInvest[msg.sender] = balances[msg.sender];
    }

    // Kick the price changing algo
    uint old_price = current_price_atto_tokens_per_wei;
    current_price_atto_tokens_per_wei = calculateCurrentPrice(getAttoTokensBoughtInICO());
    if (current_price_atto_tokens_per_wei == 0) current_price_atto_tokens_per_wei = 1; // in case it is too small that it gets rounded to zero
    if (current_price_atto_tokens_per_wei > old_price) current_price_atto_tokens_per_wei = old_price; // in case some weird overflow happens

    // Broadcasting price change event
    if (old_price != current_price_atto_tokens_per_wei) PriceChanged(old_price, current_price_atto_tokens_per_wei);

    // Broadcasting the buying event
    BRXAcquired(msg.sender, msg.value, tokens);
  }

  // Formula for the dynamic price change algorithm
  function calculateCurrentPrice(
    uint attoTokensBought
  ) private pure
    returns (uint result) {
    // see http://www.wolframalpha.com/input/?i=f(x)+%3D+395500000+%2F+(x+%2B+150000)+-+136
    // mixing safe and usual math here because the division will throw on inconsistency
    return (395500000 / ((attoTokensBought / atto) + 150000)).sub(136);
  }

  // ***************************************************************************
  // Functions for the contract owner

  function openICO() public onlyOwner {
    require(isICOOpened == false && isICOClosed == false);
    isICOOpened = true;

    ICOOpened();
  }
  function closeICO() public onlyOwner {
    require(isICOClosed == false && isICOOpened == true);

    isICOOpened = false;
    isICOClosed = true;

    // Redistribute ICO Tokens that were not bought as the first premiums
    premiumPacks.length = 1;
    premiumPacks[0] = balances[ico_address];
    balances[ico_address] = 0;

    ICOClosed();
  }
  function pullEtherFromContract() public onlyOwner {
    require(isICOClosed == true); // Only when ICO is closed
    if (!teamWallet.send(this.balance)) {
      revert();
    }
  }
  function freezeAccount(
    address _from, bool _freeze
  ) public onlyOwner
    returns (bool) {
    frozenAccounts[_from] = _freeze;
    FrozenFund(_from, _freeze);  
    return true;
  }
  function setNewBRXPay(
    address newBRXPay
  ) public onlyOwner {
    require(newBRXPay != address(0));
    addrBRXPay = newBRXPay;
  }
  function transferFromBRXPay(
    address _from, address _to, uint _value
  ) public allowedPayments
    returns (bool) {
    require(msg.sender == addrBRXPay && balances[_to].add(_value) > balances[_to] &&
    _value <= balances[_from] && !frozenAccounts[_from] &&
    !frozenAccounts[_to] && _to != address(0));
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function setCurrentPricePerWei(
    uint _new_price  
  ) public onlyOwner
  returns (bool) {
    require(isICOClosed == true && _new_price > 0); // Only when ICO is closed
    uint old_price = current_price_atto_tokens_per_wei;
    current_price_atto_tokens_per_wei = _new_price;
    PriceChanged(old_price, current_price_atto_tokens_per_wei);
  }

  // ***************************************************************************
  // Some percentage of the tokens is already reserved by early employees and investors
  // Here we&#39;re initializing their balances

  function distributePreSoldShares() private onlyOwner {
    // Making it impossible to call this function twice
    require(preSoldSharesDistributed == false);
    preSoldSharesDistributed = true;

    // Values are in atto tokens
    balances[0xAEC5cbcCF89fc25e955A53A5a015f7702a14b629] = 7208811 * atto;
    balances[0xAECDCB2a8e2cFB91869A9af30050BEa038034949] = 4025712 * atto;
    balances[0xAECF0B1b6897195295FeeD1146F3732918a5b3E4] = 300275 * atto;
    balances[0xAEC80F0aC04f389E84F3f4b39827087e393EB229] = 150000 * atto;
    balances[0xAECc9545385d858D3142023d3c298a1662Aa45da] = 150000 * atto;
    balances[0xAECE71616d07F609bd2CbD4122FbC9C4a2D11A9D] = 90000 * atto;
    balances[0xAECee3E9686825e0c8ea65f1bC8b1aB613545B8e] = 75000 * atto;
    balances[0xAECC8E8908cE17Dd6dCFFFDCCD561696f396148F] = 202 * atto;
    current_supply = (7208811 + 4025712 + 300275 + 150000 + 150000 + 90000 + 75000 + 202) * atto;

    // Sending the rest to ICO pool
    balances[ico_address] = INITIAL_SUPPLY.sub(current_supply);

    // Initializing the supply variables
    ico_starting_supply = balances[ico_address];
    current_supply = INITIAL_SUPPLY;
    SupplyChanged(0, current_supply);
  }

  // ***************************************************************************
  // Some useful getters (although you can just query the public variables)

  function getIcoStatus() public view
    returns (string result) {
    return (isICOClosed) ? &#39;closed&#39; : (isICOOpened) ? &#39;opened&#39; : &#39;not opened&#39; ;
  }
  function getCurrentPricePerWei() public view
    returns (uint result) {
    return current_price_atto_tokens_per_wei;
  }
  function getAttoTokensAmountPerWeiInternal(
    uint value
  ) public payable
    returns (uint result) {
    return value * current_price_atto_tokens_per_wei;
  }
  function getAttoTokensAmountPerWei(
    uint value
  ) public view
  returns (uint result) {
    return value * current_price_atto_tokens_per_wei;
  }
  function getAttoTokensLeftForICO() public view
    returns (uint result) {
    return balances[ico_address];
  }
  function getAttoTokensBoughtInICO() public view
    returns (uint result) {
    return ico_starting_supply - getAttoTokensLeftForICO();
  }
  function getPremiumPack(uint index) public view
    returns (uint premium) {
    return premiumPacks[index];
  }
  function getPremiumsAvailable() public view
    returns (uint length) {
    return premiumPacks.length;
  }
  function getBalancePremiumsPaid(
    address account
  ) public view
    returns (uint result) {
    return premiumPacksPaid[account];
  }
  function getAttoTokensToBeFounder() public view
  returns (uint result) {
    return 2000000000000000000000 / getCurrentPricePerWei();
  }
  function getFounderMembersInvest(
    address account
  ) public view
    returns (uint result) {
    return founderMembersInvest[account];
  }
  function getFounderMember(
    uint index
  ) public onlyOwner view
    returns (address account) {
    require(founderMembers >= index && founderOwner[index] != address(0));
    return founderOwner[index];
  }

  // ***************************************************************************
  // Premiums

  function sendPremiumPack(
    uint amount
  ) public onlyOwner allowedPayments {
    premiumPacks.length += 1;
    premiumPacks[premiumPacks.length-1] = amount;
    balances[msg.sender] = balances[msg.sender].sub(amount); // will throw and revert the whole thing if doesn&#39;t have this amount
  }
  function getPremiums() public allowedPayments
    returns (uint amount) {
    require(premiumICOMember[msg.sender]);
    if (premiumPacks.length > premiumPacksPaid[msg.sender]) {
      uint startPackIndex = premiumPacksPaid[msg.sender];
      uint finishPackIndex = premiumPacks.length - 1;
      uint owingTotal = 0;
      for(uint i = startPackIndex; i <= finishPackIndex; i++) {
        if (current_supply != 0) { // just in case
          uint owing = balances[msg.sender] * premiumPacks[i] / current_supply;
          balances[msg.sender] = balances[msg.sender].add(owing);
          owingTotal = owingTotal + owing;
        }
      }
      premiumPacksPaid[msg.sender] = premiumPacks.length;
      return owingTotal;
    } else {
      revert();
    }
  }

  // ***************************************************************************
  // Overriding payment functions to take control over the logic

  modifier allowedPayments() {
    // Don&#39;t allow to transfer coins until the ICO ends
    require(isICOOpened == false && isICOClosed == true && !frozenAccounts[msg.sender]);
    _;
  }
  
  function transferFrom(
    address _from, address _to, uint _value
  ) public allowedPayments
    returns (bool) {
    super.transferFrom(_from, _to, _value);
  }
  
  function transfer(
    address _to, uint _value
  ) public onlyPayloadSize(2 * 32) allowedPayments
    returns (bool) {
    super.transfer(_to, _value);
  }

}