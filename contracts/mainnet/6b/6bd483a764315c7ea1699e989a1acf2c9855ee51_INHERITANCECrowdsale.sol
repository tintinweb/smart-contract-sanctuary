pragma solidity ^0.4.18;


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
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract usingINHERITANCEConsts {
    uint constant TOKEN_DECIMALS = 18;
    uint8 constant TOKEN_DECIMALS_UINT8 = 18;
    uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    uint constant TEAM_TOKENS =   250000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant BOUNTY_TOKENS = 250000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant PREICO_TOKENS = 250000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant MINIMAL_PURCHASE = 0.1 ether;

    address constant TEAM_ADDRESS = 0x78cd8f794686ee8f6644447e961ef52776edf0cb;
    address constant BOUNTY_ADDRESS = 0xff823588500d3ecd7777a1cfa198958df4deea11;
    address constant PREICO_ADDRESS = 0xff823588500d3ecd7777a1cfa198958df4deea11;
    address constant COLD_WALLET = 0x439415b03708bde585856b46666f34b65af6a5c3;

    string constant TOKEN_NAME = "INHERITANCE";
    bytes32 constant TOKEN_SYMBOL = "IEI";
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
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) returns (bool) {
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
    function balanceOf(address _owner) constant returns (uint256 balance) {
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
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

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
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

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
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract INHERITANCEToken is usingINHERITANCEConsts, MintableToken, BurnableToken {
    /**
     * @dev Pause token transfer. After successfully finished crowdsale it becomes true.
     */
    bool public paused = true;
    /**
     * @dev Accounts who can transfer token even if paused. Works only during crowdsale.
     */
    mapping(address => bool) excluded;

    function name() constant public returns (string _name) {
        return TOKEN_NAME;
    }

    function symbol() constant public returns (bytes32 _symbol) {
        return TOKEN_SYMBOL;
    }

    function decimals() constant public returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }

    function crowdsaleFinished() onlyOwner {
        paused = false;
        finishMinting();
    }

    function addExcluded(address _toExclude) onlyOwner {
        excluded[_toExclude] = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(!paused || excluded[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(!paused || excluded[msg.sender]);
        return super.transfer(_to, _value);
    }

    /**
     * @dev Burn tokens from the specified address.
     * @param _from     address The address which you want to burn tokens from.
     * @param _value    uint    The amount of tokens to be burned.
     */
    function burnFrom(address _from, uint256 _value) returns (bool) {
        require(_value > 0);
        var allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        allowed[_from][msg.sender] = allowance.sub(_value);
        Burn(_from, _value);
        return true;
    }
}
contract INHERITANCERateProviderI {
    /**
     * @dev Calculate actual rate using the specified parameters.
     * @param buyer     Investor (buyer) address.
     * @param totalSold Amount of sold tokens.
     * @param amountWei Amount of wei to purchase.
     * @return ETH to Token rate.
     */
    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint);

    /**
     * @dev rate scale (or divider), to support not integer rates.
     * @return Rate divider.
     */
    function getRateScale() public constant returns (uint);

    /**
     * @return Absolute base rate.
     */
    function getBaseRate() public constant returns (uint);
}

contract INHERITANCERateProvider is usingINHERITANCEConsts, INHERITANCERateProviderI, Ownable {
    // rate calculate accuracy
    uint constant RATE_SCALE = 1000000;
    uint constant STEP_30 = 10000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant STEP_20 = 50000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant STEP_10 = 1000000000 * TOKEN_DECIMAL_MULTIPLIER;
    uint constant RATE_30 = 130000 * RATE_SCALE;
    uint constant RATE_20 = 120000 * RATE_SCALE;
    uint constant RATE_10 = 110000 * RATE_SCALE;
    uint constant BASE_RATE = 100000 * RATE_SCALE;

    struct ExclusiveRate {
        // be careful, accuracies this about 15 minutes
        uint32 workUntil;
        // exclusive rate or 0
        uint rate;
        // rate bonus percent, which will be divided by 1000 or 0
        uint16 bonusPercent1000;
        // flag to check, that record exists
        bool exists;
    }

    mapping(address => ExclusiveRate) exclusiveRate;

    function getRateScale() public constant returns (uint) {
        return RATE_SCALE;
    }

    function getBaseRate() public constant returns (uint) {
        return BASE_RATE;
    }

    function getRate(address buyer, uint totalSold, uint amountWei) public constant returns (uint) {
        uint rate;
        // apply sale
        if (totalSold < STEP_30) {
            rate = RATE_30;
        }
        else if (totalSold < STEP_20) {
            rate = RATE_20;
        }
        else if (totalSold < STEP_10) {
            rate = RATE_10;
        }
        else {
            rate = BASE_RATE;
        }

        // apply bonus for amount
        if (amountWei >= 100 ether) {
            rate += rate * 100 / 100;
        }
        else if (amountWei >= 50 ether) {
            rate += rate * 100 / 100;
        }
        else if (amountWei >= 10 ether) {
            rate += rate * 300 / 100;
        }
        else if (amountWei >= 4 ether) {
            rate += rate * 100 / 100;
        }
        else if (amountWei >= 2 ether) {
            rate += rate * 40 / 100;
        }
        else if (amountWei >= 1 ether) {
            rate += rate * 150 / 1000;
        }

        ExclusiveRate memory eRate = exclusiveRate[buyer];
        if (eRate.exists && eRate.workUntil >= now) {
            if (eRate.rate != 0) {
                rate = eRate.rate;
            }
            rate += rate * eRate.bonusPercent1000 / 1000;
        }
        return rate;
    }

    function setExclusiveRate(address _investor, uint _rate, uint16 _bonusPercent1000, uint32 _workUntil) onlyOwner {
        exclusiveRate[_investor] = ExclusiveRate(_workUntil, _rate, _bonusPercent1000, true);
    }

    function removeExclusiveRate(address _investor) onlyOwner {
        delete exclusiveRate[_investor];
    }
}
/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 *
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint;

    // The token being sold
    MintableToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint32 internal startTime;
    uint32 internal endTime;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint public weiRaised;

    /**
     * @dev Amount of already sold tokens.
     */
    uint public soldTokens;

    /**
     * @dev Maximum amount of tokens to mint.
     */
    uint internal hardCap;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    function Crowdsale(uint _startTime, uint _endTime, uint _hardCap, address _wallet) {
        require(_endTime >= _startTime);
        require(_wallet != 0x0);
        require(_hardCap > 0);

        token = createTokenContract();
        startTime = uint32(_startTime);
        endTime = uint32(_endTime);
        hardCap = _hardCap;
        wallet = _wallet;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

    /**
     * @dev this method might be overridden for implementing any sale logic.
     * @return Actual rate.
     */
    function getRate(uint amount) internal constant returns (uint);

    function getBaseRate() internal constant returns (uint);

    /**
     * @dev rate scale (or divider), to support not integer rates.
     * @return Rate divider.
     */
    function getRateScale() internal constant returns (uint) {
        return 1;
    }

    // fallback function can be used to buy tokens
    function() payable {
        buyTokens(msg.sender, msg.value);
    }

    // low level token purchase function
    function buyTokens(address beneficiary, uint amountWei) internal {
        require(beneficiary != 0x0);

        // total minted tokens
        uint totalSupply = token.totalSupply();

        // actual token minting rate (with considering bonuses and discounts)
        uint actualRate = getRate(amountWei);
        uint rateScale = getRateScale();

        require(validPurchase(amountWei, actualRate, totalSupply));

        // calculate token amount to be created
        uint tokens = amountWei.mul(actualRate).div(rateScale);

        // update state
        weiRaised = weiRaised.add(amountWei);
        soldTokens = soldTokens.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, amountWei, tokens);

        forwardFunds(amountWei);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds(uint amountWei) internal {
        wallet.transfer(amountWei);
    }

    /**
     * @dev Check if the specified purchase is valid.
     * @return true if the transaction can buy tokens
     */
    function validPurchase(uint _amountWei, uint _actualRate, uint _totalSupply) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = _amountWei != 0;
        bool hardCapNotReached = _totalSupply <= hardCap;

        return withinPeriod && nonZeroPurchase && hardCapNotReached;
    }

    /**
     * @dev Because of discount hasEnded might be true, but validPurchase returns false.
     * @return true if crowdsale event has ended
     */
    function hasEnded() public constant returns (bool) {
        return now > endTime || token.totalSupply() > hardCap;
    }

    /**
     * @return true if crowdsale event has started
     */
    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }
}

contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    function FinalizableCrowdsale(uint _startTime, uint _endTime, uint _hardCap, address _wallet)
            Crowdsale(_startTime, _endTime, _hardCap, _wallet) {
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() onlyOwner notFinalized {
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overriden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal {
    }

    modifier notFinalized() {
        require(!isFinalized);
        _;
    }
}

contract INHERITANCECrowdsale is usingINHERITANCEConsts, FinalizableCrowdsale {
    INHERITANCERateProviderI public rateProvider;

    function INHERITANCECrowdsale(
            uint _startTime,
            uint _endTime,
            uint _hardCapTokens
    )
            FinalizableCrowdsale(_startTime, _endTime, _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER, COLD_WALLET) {

        token.mint(TEAM_ADDRESS, TEAM_TOKENS);
        token.mint(BOUNTY_ADDRESS, BOUNTY_TOKENS);
        token.mint(PREICO_ADDRESS, PREICO_TOKENS);

        INHERITANCEToken(token).addExcluded(TEAM_ADDRESS);
        INHERITANCEToken(token).addExcluded(BOUNTY_ADDRESS);
        INHERITANCEToken(token).addExcluded(PREICO_ADDRESS);

        INHERITANCERateProvider provider = new INHERITANCERateProvider();
        provider.transferOwnership(owner);
        rateProvider = provider;
    }

    /**
     * @dev override token creation to integrate with MyWill token.
     */
    function createTokenContract() internal returns (MintableToken) {
        return new INHERITANCEToken();
    }

    /**
     * @dev override getRate to integrate with rate provider.
     */
    function getRate(uint _value) internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, soldTokens, _value);
    }

    function getBaseRate() internal constant returns (uint) {
        return rateProvider.getRate(msg.sender, soldTokens, MINIMAL_PURCHASE);
    }

    /**
     * @dev override getRateScale to integrate with rate provider.
     */
    function getRateScale() internal constant returns (uint) {
        return rateProvider.getRateScale();
    }

    /**
     * @dev Admin can set new rate provider.
     * @param _rateProviderAddress New rate provider.
     */
    function setRateProvider(address _rateProviderAddress) onlyOwner {
        require(_rateProviderAddress != 0);
        rateProvider = INHERITANCERateProviderI(_rateProviderAddress);
    }

    /**
     * @dev Admin can move end time.
     * @param _endTime New end time.
     */
    function setEndTime(uint _endTime) onlyOwner notFinalized {
        require(_endTime > startTime);
        endTime = uint32(_endTime);
    }

    function setHardCap(uint _hardCapTokens) onlyOwner notFinalized {
        require(_hardCapTokens * TOKEN_DECIMAL_MULTIPLIER > hardCap);
        hardCap = _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER;
    }

    function setStartTime(uint _startTime) onlyOwner notFinalized {
        require(_startTime < endTime);
        startTime = uint32(_startTime);
    }

    function addExcluded(address _address) onlyOwner notFinalized {
        INHERITANCEToken(token).addExcluded(_address);
    }

    function validPurchase(uint _amountWei, uint _actualRate, uint _totalSupply) internal constant returns (bool) {
        if (_amountWei < MINIMAL_PURCHASE) {
            return false;
        }
        return super.validPurchase(_amountWei, _actualRate, _totalSupply);
    }

    function finalization() internal {
        super.finalization();
        token.finishMinting();
        INHERITANCEToken(token).crowdsaleFinished();
        token.transferOwnership(owner);
    }
}