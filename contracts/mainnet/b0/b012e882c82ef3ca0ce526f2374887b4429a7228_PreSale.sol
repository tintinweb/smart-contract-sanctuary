/**
 * @author https://github.com/Dmitx
 */

pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


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
        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}


/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }

}


contract DividendPayoutToken is CappedToken {

    // Dividends already claimed by investor
    mapping(address => uint256) public dividendPayments;
    // Total dividends claimed by all investors
    uint256 public totalDividendPayments;

    // invoke this function after each dividend payout
    function increaseDividendPayments(address _investor, uint256 _amount) onlyOwner public {
        dividendPayments[_investor] = dividendPayments[_investor].add(_amount);
        totalDividendPayments = totalDividendPayments.add(_amount);
    }

    //When transfer tokens decrease dividendPayments for sender and increase for receiver
    function transfer(address _to, uint256 _value) public returns (bool) {
        // balance before transfer
        uint256 oldBalanceFrom = balances[msg.sender];

        // invoke super function with requires
        bool isTransferred = super.transfer(_to, _value);

        uint256 transferredClaims = dividendPayments[msg.sender].mul(_value).div(oldBalanceFrom);
        dividendPayments[msg.sender] = dividendPayments[msg.sender].sub(transferredClaims);
        dividendPayments[_to] = dividendPayments[_to].add(transferredClaims);

        return isTransferred;
    }

    //When transfer tokens decrease dividendPayments for token owner and increase for receiver
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // balance before transfer
        uint256 oldBalanceFrom = balances[_from];

        // invoke super function with requires
        bool isTransferred = super.transferFrom(_from, _to, _value);

        uint256 transferredClaims = dividendPayments[_from].mul(_value).div(oldBalanceFrom);
        dividendPayments[_from] = dividendPayments[_from].sub(transferredClaims);
        dividendPayments[_to] = dividendPayments[_to].add(transferredClaims);

        return isTransferred;
    }

}

contract IcsToken is DividendPayoutToken {

    string public constant name = "Interexchange Crypstock System";

    string public constant symbol = "ICS";

    uint8 public constant decimals = 18;

    // set Total Supply in 500 000 000 tokens
    constructor() public
    CappedToken(5e8 * 1e18) {}

}

contract HicsToken is DividendPayoutToken {

    string public constant name = "Interexchange Crypstock System Heritage Token";

    string public constant symbol = "HICS";

    uint8 public constant decimals = 18;

    // set Total Supply in 50 000 000 tokens
    constructor() public
    CappedToken(5e7 * 1e18) {}

}


/**
 * @title Helps contracts guard against reentrancy attacks.
 */
contract ReentrancyGuard {

    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private reentrancyLock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

contract PreSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // T4T Token
    ERC20 public t4tToken;

    // Tokens being sold
    IcsToken public icsToken;
    HicsToken public hicsToken;

    // Timestamps of period
    uint64 public startTime;
    uint64 public endTime;
    uint64 public endPeriodA;
    uint64 public endPeriodB;
    uint64 public endPeriodC;

    // Address where funds are transferred
    address public wallet;

    // How many token units a buyer gets per 1 wei
    uint256 public rate;

    // How many token units a buyer gets per 1 token T4T
    uint256 public rateT4T;

    uint256 public minimumInvest; // in tokens

    uint256 public hicsTokenPrice;  // in tokens

    // Max HICS Token distribution in PreSale
    uint256 public capHicsToken;  // in tokens

    uint256 public softCap; // in tokens

    // investors => amount of money
    mapping(address => uint) public balances;  // in tokens

    // wei which has stored on PreSale contract
    mapping(address => uint) balancesForRefund;  // in wei (not public: only for refund)

    // T4T which has stored on PreSale contract
    mapping(address => uint) balancesForRefundT4T;  // in T4T tokens (not public: only for refund)

    // Amount of wei raised in PreSale Contract
    uint256 public weiRaised;

    // Number of T4T raised in PreSale Contract
    uint256 public t4tRaised;

    // Total number of token emitted
    uint256 public totalTokensEmitted;  // in tokens

    // Total money raised (number of tokens without bonuses)
    uint256 public totalRaised;  // in tokens

    /**
     * events for tokens purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param tokens purchased
     */
    event IcsTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 tokens);
    event HicsTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 tokens);

    /**
    * @dev Constructor of PreSale
    *
    * @notice Duration of bonus periods, start and end timestamps, minimum invest,
    * minimum invest to get HICS Token, token price, Soft Cap and HICS Hard Cap are set
    * in body of PreSale constructor.
    *
    * @param _wallet for withdrawal ether
    * @param _icsToken ICS Token address
    * @param _hicsToken HICS Token address
    * @param _erc20Token T4T Token address
    */
    constructor(
        address _wallet,
        address _icsToken,
        address _hicsToken,
        address _erc20Token) public
    {
        require(_wallet != address(0));
        require(_icsToken != address(0));
        require(_hicsToken != address(0));
        require(_erc20Token != address(0));

        // periods of PreSale&#39;s bonus and PreSale&#39;s time
        startTime = 1528675200;  // 1528675200 - 11.06.2018 00:00 UTC
        endPeriodA = 1529107200; // 1529107200 - 16.06.2018 00:00 UTC
        endPeriodB = 1529798400; // 1529798400 - 24.06.2018 00:00 UTC
        endPeriodC = 1530489600; // 1530489600 - 02.07.2018 00:00 UTC
        endTime = 1531353600;    // 1531353600 - 12.07.2018 00:00 UTC

        // check valid of periods
        bool validPeriod = now < startTime && startTime < endPeriodA 
                        && endPeriodA < endPeriodB && endPeriodB < endPeriodC 
                        && endPeriodC < endTime;
        require(validPeriod);

        wallet = _wallet;
        icsToken = IcsToken(_icsToken);
        hicsToken = HicsToken(_hicsToken);

        // set T4T token address
        t4tToken = ERC20(_erc20Token);

        // 4 tokens = 1 T4T token (1$)
        rateT4T = 4;

        // minimum invest in tokens
        minimumInvest = 4 * 1e18;  // 4 tokens = 1$

        // minimum invest to get HicsToken
        hicsTokenPrice = 2e4 * 1e18;  // 20 000 tokens = 5 000$

        // initial rate - 1 token for 25 US Cent
        // initial price - 1 ETH = 680 USD
        rate = 2720;  // number of tokens for 1 wei

        // in tokens
        softCap = 4e6 * 1e18;  // equals 1 000 000$

        capHicsToken = 15e6 * 1e18;  // 15 000 000 tokens
    }

    // @return true if the transaction can buy tokens
    modifier saleIsOn() {
        bool withinPeriod = now >= startTime && now <= endTime;
        require(withinPeriod);
        _;
    }

    // allowed refund in case of unsuccess PreSale
    modifier refundAllowed() {
        require(totalRaised < softCap && now > endTime);
        _;
    }

    // @return true if CrowdSale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // Refund ether to the investors in case of under Soft Cap end
    function refund() public refundAllowed nonReentrant {
        uint256 valueToReturn = balancesForRefund[msg.sender];

        // update states
        balancesForRefund[msg.sender] = 0;
        weiRaised = weiRaised.sub(valueToReturn);

        msg.sender.transfer(valueToReturn);
    }

    // Refund T4T tokens to the investors in case of under Soft Cap end
    function refundT4T() public refundAllowed nonReentrant {
        uint256 valueToReturn = balancesForRefundT4T[msg.sender];

        // update states
        balancesForRefundT4T[msg.sender] = 0;
        t4tRaised = t4tRaised.sub(valueToReturn);

        t4tToken.transfer(msg.sender, valueToReturn);
    }

    // Get bonus percent
    function _getBonusPercent() internal view returns(uint256) {

        if (now < endPeriodA) {
            return 40;
        }
        if (now < endPeriodB) {
            return 25;
        }
        if (now < endPeriodC) {
            return 20;
        }

        return 15;
    }

    // Get number of tokens with bonus
    // @param _value in tokens without bonus
    function _getTokenNumberWithBonus(uint256 _value) internal view returns (uint256) {
        return _value.add(_value.mul(_getBonusPercent()).div(100));
    }

    // Send weis to the wallet
    // @param _value in wei
    function _forwardFunds(uint256 _value) internal {
        wallet.transfer(_value);
    }

    // Send T4T tokens to the wallet
    // @param _value in T4T tokens
    function _forwardT4T(uint256 _value) internal {
        t4tToken.transfer(wallet, _value);
    }

    // Withdrawal eth from contract
    function withdrawalEth() public onlyOwner {
        require(totalRaised >= softCap);

        // withdrawal all eth from contract
        _forwardFunds(address(this).balance);
    }

    // Withdrawal T4T tokens from contract
    function withdrawalT4T() public onlyOwner {
        require(totalRaised >= softCap);

        // withdrawal all T4T tokens from contract
        _forwardT4T(t4tToken.balanceOf(address(this)));
    }

    // Success finish of PreSale
    function finishPreSale() public onlyOwner {
        require(totalRaised >= softCap);
        require(now > endTime);

        // withdrawal all eth from contract
        _forwardFunds(address(this).balance);

        // withdrawal all T4T tokens from contract
        _forwardT4T(t4tToken.balanceOf(address(this)));

        // transfer ownership of tokens to owner
        icsToken.transferOwnership(owner);
        hicsToken.transferOwnership(owner);
    }

    // Change owner of tokens after end of PreSale
    function changeTokensOwner() public onlyOwner {
        require(now > endTime);

        // transfer ownership of tokens to owner
        icsToken.transferOwnership(owner);
        hicsToken.transferOwnership(owner);
    }

    // Change rate
    // @param _rate for change
    function _changeRate(uint256 _rate) internal {
        require(_rate != 0);
        rate = _rate;
    }

    // buy ICS tokens
    function _buyIcsTokens(address _beneficiary, uint256 _value) internal {
        uint256 tokensWithBonus = _getTokenNumberWithBonus(_value);

        icsToken.mint(_beneficiary, tokensWithBonus);

        emit IcsTokenPurchase(msg.sender, _beneficiary, tokensWithBonus);
    }

    // buy HICS tokens
    function _buyHicsTokens(address _beneficiary, uint256 _value) internal {
        uint256 tokensWithBonus = _getTokenNumberWithBonus(_value);

        hicsToken.mint(_beneficiary, tokensWithBonus);

        emit HicsTokenPurchase(msg.sender, _beneficiary, tokensWithBonus);
    }

    // buy tokens - helper function
    // @param _beneficiary address of beneficiary
    // @param _value of tokens (1 token = 10^18)
    function _buyTokens(address _beneficiary, uint256 _value) internal {
        // calculate HICS token amount
        uint256 valueHics = _value.div(5);  // 20% HICS and 80% ICS Tokens

        if (_value >= hicsTokenPrice
        && hicsToken.totalSupply().add(_getTokenNumberWithBonus(valueHics)) < capHicsToken) {
            // 20% HICS and 80% ICS Tokens
            _buyIcsTokens(_beneficiary, _value - valueHics);
            _buyHicsTokens(_beneficiary, valueHics);
        } else {
            // 100% of ICS Tokens
            _buyIcsTokens(_beneficiary, _value);
        }

        // update states
        uint256 tokensWithBonus = _getTokenNumberWithBonus(_value);
        totalTokensEmitted = totalTokensEmitted.add(tokensWithBonus);
        balances[_beneficiary] = balances[_beneficiary].add(tokensWithBonus);

        totalRaised = totalRaised.add(_value);
    }

    // buy tokens for T4T tokens
    // @param _beneficiary address of beneficiary
    function buyTokensT4T(address _beneficiary) public saleIsOn {
        require(_beneficiary != address(0));

        uint256 valueT4T = t4tToken.allowance(_beneficiary, address(this));

        // check minimumInvest
        uint256 value = valueT4T.mul(rateT4T);
        require(value >= minimumInvest);

        // transfer T4T from _beneficiary to this contract
        require(t4tToken.transferFrom(_beneficiary, address(this), valueT4T));

        _buyTokens(_beneficiary, value);

        // only for buy using T4T tokens
        t4tRaised = t4tRaised.add(valueT4T);
        balancesForRefundT4T[_beneficiary] = balancesForRefundT4T[_beneficiary].add(valueT4T);
    }

    // manual transfer tokens by owner (e.g.: selling for fiat money)
    // @param _to address of beneficiary
    // @param _value of tokens (1 token = 10^18)
    function manualBuy(address _to, uint256 _value) public saleIsOn onlyOwner {
        require(_to != address(0));
        require(_value >= minimumInvest);

        _buyTokens(_to, _value);
    }

    // buy tokens with update rate state by owner
    // @param _beneficiary address of beneficiary
    // @param _rate new rate - how many token units a buyer gets per 1 wei
    function buyTokensWithUpdateRate(address _beneficiary, uint256 _rate) public saleIsOn onlyOwner payable {
        _changeRate(_rate);
        buyTokens(_beneficiary);
    }

    // low level token purchase function
    // @param _beneficiary address of beneficiary
    function buyTokens(address _beneficiary) saleIsOn public payable {
        require(_beneficiary != address(0));

        uint256 weiAmount = msg.value;
        uint256 value = weiAmount.mul(rate);
        require(value >= minimumInvest);

        _buyTokens(_beneficiary, value);

        // only for buy using PreSale contract
        weiRaised = weiRaised.add(weiAmount);
        balancesForRefund[_beneficiary] = balancesForRefund[_beneficiary].add(weiAmount);
    }

    function() external payable {
        buyTokens(msg.sender);
    }
}