pragma solidity 0.4.20;

/**
 * @author Denver Brittain
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
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
  function increaseApproval (address _spender, uint _addedValue) returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success) {
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
 * @title StandardCrowdsale 
 * @dev StandardCrowdsale is a base contract for managing a token crowdsale.
 * This crowdsale has been modified to contain a presale start and end time 
 * with presale bonuses and an ongoing ICO that is not complete until all tokens
 * have been sold and transferred from the holding contract.
 * @dev from Crowdsale by Zepellin with a few differences, the most important of 
 * which are the tiered presale pricing structure, presale start 
 * and conclusion times, and the ongoing ICO."
 */
contract StandardCrowdsale {
    using SafeMath for uint256;

    // our token being sold
    StandardToken public token; 

    // presale has a start and end time, ICO only has a start time
    uint256 public icoStartTime;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    // funding is collected here
    address public wallet;

    // the number of tokens/wei distributed to a buyer depends on a number of factors
    // if the presale is active, the number of tokens a buyer receives per wei depends 
    // on the amount of wei sent: the tiered pricing structure
    // if the ICO is active, the buyer receives a fixed number of tokens/wei at the icoRate
    uint256 public icoRate;
    uint256 public tier1Rate;
    uint256 public tier2Rate;
    uint256 public tier3Rate;
    uint256 public tier4Rate;


    // total funds raised in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value in wei paid for purchase
     * @param amount (number) of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    // modified standard crowdsale must be supplied presale and ico tiers for token purchase rates
    function StandardCrowdsale(
        uint256 _icoStartTime,  
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _icoRate, 
        uint256 _tier1Rate,
        uint256 _tier2Rate,
        uint256 _tier3Rate,
        uint256 _tier4Rate,
        address _wallet) {

        require(_icoStartTime >= now);
        require(_icoRate > 0);
        require(_wallet != 0x0);

        icoStartTime = _icoStartTime;
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        tier1Rate = _tier1Rate;
        tier2Rate = _tier2Rate;
        tier3Rate = _tier3Rate;
        tier4Rate = _tier4Rate;

        icoRate = _icoRate;
        wallet = _wallet;

        token = createTokenContract(); 
    }

    function createTokenContract() internal returns(StandardToken) {
        return new StandardToken();
    }

    // buyers may purchase tokens through fallback function
    // if registered, simply send wei to contract during active presale
    // or ICO times to receive tokens
    function () payable {
        buyTokens();
    }

    // low level token purchase function
    function buyTokens() public payable {

        // purhcase must occur during either ICO or presale
        require(validPurchase()); 

        uint256 weiAmount = msg.value;

        // calculate token amount to be sent
        // set to ICO values and update for presale bonuses if necessary
        // accept a maximum of 600 ether during presale
        uint256 tokens = weiAmount.mul(icoRate);

        // if presale is active, confirm that purchase does not go over presale 
        // funding cap and calculate presale tokens to be transferred
        if ((now >= presaleStartTime && now < presaleEndTime) && weiRaised.add(weiAmount) <= 600 ether) {        
            if (weiAmount < 2 ether) 
                tokens = weiAmount.mul(tier1Rate);
            if (weiAmount >= 2 ether && weiAmount < 5 ether) 
                tokens = weiAmount.mul(tier2Rate);
            if (weiAmount >= 5 ether && weiAmount < 10 ether)
                tokens = weiAmount.mul(tier3Rate);
            if (weiAmount >= 10 ether)
                tokens = weiAmount.mul(tier4Rate);
        } 

        // update funds raised by new purchase
        weiRaised = weiRaised.add(weiAmount);

        require(token.transfer(msg.sender, tokens));
        TokenPurchase(msg.sender, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens from presale or ICO, includes funding cap check 
    function validPurchase() internal returns(bool) {
        bool withinPresalePeriod = now >= presaleStartTime;
        bool withinICOPeriod = now >= icoStartTime;
        bool nonZeroPurchase = msg.value != 0;
        return (withinPresalePeriod && nonZeroPurchase && weiRaised <= 600 ether) || (withinICOPeriod && nonZeroPurchase && weiRaised <= 3000 ether);
    }
}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is StandardCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached;
  }
}

/** 
 * @title WhitelistedCrowdsale
 * @dev WhitelistedCrowdsale is a contract for managing a 
 * token sale with a clearly defined whitelist of addresses 
 * who may purchase tokens. 
 * @dev WhitelistedCrowdsale based on RequestNetwork: https://github.com/RequestNetwork/RequestTokenSale 
*/ 
contract WhitelistedCrowdsale is StandardCrowdsale, Ownable {
    
    mapping(address=>bool) public registered;

    event RegistrationStatusChanged(address target, bool isRegistered);

    function changeRegistrationStatus(address target, bool isRegistered) public onlyOwner {
        registered[target] = isRegistered;
        RegistrationStatusChanged(target, isRegistered);
    }

    function changeRegistrationStatuses(address[] targets, bool isRegistered) public onlyOwner {
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], isRegistered);
        }
    }

    function validPurchase() internal returns (bool) {
        return super.validPurchase() && registered[msg.sender];
    }
}

/** 
 * @dev ApolloCoinToken definition. This is a very standard token definition that 
 * contains a few additional features to the typical ERC20 token including a timelock,
 * and a valid transfer destination check
*/
contract ApolloCoinToken is StandardToken, Ownable {
    string  public  constant name = "ApolloCoin";
    string  public  constant symbol = "APC";
    uint8   public  constant decimals = 18;

    uint    public  transferableStartTime;

    address public  tokenSaleContract;
    address public  earlyInvestorWallet;


    modifier onlyWhenTransferEnabled() {
        if ( now <= transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == earlyInvestorWallet || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) {
        require(to != address(this));
        _;
    }

    function ApolloCoinToken(uint tokenTotalAmount, uint _transferableStartTime, address _admin, address _earlyInvestorWallet) {
        
       // Mint total supply and permanently disable minting
       totalSupply = tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        transferableStartTime = _transferableStartTime;     // tokens may only be transferred after this time
        tokenSaleContract = msg.sender;
        earlyInvestorWallet = _earlyInvestorWallet;

        transferOwnership(_admin); 
    }

    function transfer(address _to, uint _value) public validDestination(_to) onlyWhenTransferEnabled returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public validDestination(_to) onlyWhenTransferEnabled returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    /**
     * @dev burn tokens
     * @param _value The amount to be burned.
     * @return always true (necessary in case of override)
     */
    function burn(uint _value) public onlyWhenTransferEnabled returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    /**
     * @dev burn tokens on behalf of someone
     * @param _from The address of the owner of the token
     * @param _value The amount to be burned
     * @return always true (necessary in case of override)
     */
    function burnFrom(address _from, uint256 _value) public onlyWhenTransferEnabled returns(bool) {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

    /**
     * @dev transfer to owner any tokens sent here by mistake 
     * @param token The address of the token to transfer
     * @param amount The amount to be transfered
     */
    function emergencyERC20Drain(ERC20 token, uint amount ) public onlyOwner {
        token.transfer(owner, amount);
    }
}

/**
 * @dev ApolloCoinTokenSale contract to define the transferrable start time, ICO hard cap, 
 * tiered presale bonuses, and distribution of tokens to devs, early investors, and ApolloCoin company wallets.
*/
contract ApolloCoinTokenSale is Ownable, CappedCrowdsale, WhitelistedCrowdsale {
   
    // hard cap on total ether collected 
    uint private constant HARD_CAP = 3000 ether;

    // total supply cap
    uint public constant TOTAL_APC_SUPPLY = 21000000;

    // ICO rate definition
    // buyers receive 900 APC per ETH sent
    uint private constant ICO_RATE = 900;

    // presale rate definitions 
    uint private constant TIER1_RATE = 1080;
    uint private constant TIER2_RATE = 1440;
    uint private constant TIER3_RATE = 1620;
    uint private constant TIER4_RATE = 1800; 

    // Tokens initialy distributed for the team (20%)
    address public constant TEAM_WALLET = 0xd55de4cdade91f8b3d0ad44e5bc0074840bcf287;
    uint public constant TEAM_AMOUNT = 4200000e18;

    // Tokens initialy distributed to early investors (35%)
    address public constant EARLY_INVESTOR_WALLET = 0x67e84a30d6c33f90e9aef0b9147455f4c8d85208;
    uint public constant EARLY_INVESTOR_AMOUNT = 7350000e18;

    // Tokens initialy distributed to the company (30%)
    // wallet also used to gather the ether of the token sale
    address private constant APOLLOCOIN_COMPANY_WALLET = 0x129c3e7ac8e80511d50a77d757bb040a1132f59c;
    uint public constant APOLLOCOIN_COMPANY_AMOUNT = 6300000e18;
    
    // tokens cannot be sent for 10 days following the start of the presale
    uint public constant NON_TRANSFERABLE_TIME = 10 days;    

    function ApolloCoinTokenSale(uint256 _icoStartTime, uint256 _presaleStartTime, uint256 _presaleEndTime) WhitelistedCrowdsale() CappedCrowdsale(HARD_CAP) StandardCrowdsale(_icoStartTime, _presaleStartTime, _presaleEndTime, ICO_RATE, TIER1_RATE, TIER2_RATE, TIER3_RATE, TIER4_RATE, APOLLOCOIN_COMPANY_WALLET) {
        token.transfer(TEAM_WALLET, TEAM_AMOUNT);

        token.transfer(EARLY_INVESTOR_WALLET, EARLY_INVESTOR_AMOUNT);

        token.transfer(APOLLOCOIN_COMPANY_WALLET, APOLLOCOIN_COMPANY_AMOUNT);
    }

    function createTokenContract () internal returns(StandardToken) {
        return new ApolloCoinToken(TOTAL_APC_SUPPLY, NON_TRANSFERABLE_TIME, APOLLOCOIN_COMPANY_WALLET, EARLY_INVESTOR_WALLET);
    }

    function drainRemainingToken () public onlyOwner {
        require(hasEnded());
        token.transfer(APOLLOCOIN_COMPANY_WALLET, token.balanceOf(this));
    }
  
}