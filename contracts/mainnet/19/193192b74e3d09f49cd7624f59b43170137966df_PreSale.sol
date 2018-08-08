pragma solidity ^0.4.18;

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
        Transfer(msg.sender, _to, _value);
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
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    function _burn(address _burner, uint256 _value) internal {
        require(_value <= balances[_burner]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_burner] = balances[_burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(_burner, _value);
        Transfer(_burner, address(0), _value);
    }

}


contract DividendPayoutToken is BurnableToken, MintableToken {

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

    function burn() public {
        address burner = msg.sender;

        // balance before burning tokens
        uint256 oldBalance = balances[burner];

        super._burn(burner, oldBalance);

        uint256 burnedClaims = dividendPayments[burner];
        dividendPayments[burner] = dividendPayments[burner].sub(burnedClaims);
        totalDividendPayments = totalDividendPayments.sub(burnedClaims);

        SaleInterface(owner).refund(burner);
    }

}

contract RicoToken is DividendPayoutToken {

    string public constant name = "Rico";

    string public constant symbol = "Rico";

    uint8 public constant decimals = 18;

}


// Interface for PreSale and CrowdSale contracts with refund function
contract SaleInterface {

    function refund(address _to) public;

}


contract ReentrancyGuard {

    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private reentrancy_lock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }

}

contract PreSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // The token being sold
    RicoToken public token;
    address tokenContractAddress;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // Address where funds are transferred after success end of PreSale
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    uint256 public minimumInvest; // in wei

    uint256 public softCap; // in wei
    uint256 public hardCap; // in wei

    // investors => amount of money
    mapping(address => uint) public balances;

    // Amount of wei raised
    uint256 public weiRaised;

    // PreSale bonus in percent
    uint256 bonusPercent;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function PreSale() public
    {
        startTime = 1524303600;
        endTime = startTime + 20 * 1 minutes;

        wallet = 0x34FCc63E538f39a0E68E0f01A901713eF9Dd235c;
        token = new RicoToken();

        // minimumInvest in wei
        minimumInvest = 0.0001 ether;

        // 1 token for approximately 0.00015 eth
        rate = 6667;

        softCap = 0.0150 ether;
        hardCap = 0.1500 ether;
        bonusPercent = 50;
    }

    // @return true if the transaction can buy tokens
    modifier saleIsOn() {
        bool withinPeriod = now >= startTime && now <= endTime;
        require(withinPeriod);
        _;
    }

    modifier isUnderHardCap() {
        require(weiRaised < hardCap);
        _;
    }

    modifier refundAllowed() {
        require(weiRaised < softCap && now > endTime);
        _;
    }

    // @return true if PreSale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // Refund ether to the investors (invoke from only token)
    function refund(address _to) public refundAllowed {
        require(msg.sender == tokenContractAddress);

        uint256 valueToReturn = balances[_to];

        // update states
        balances[_to] = 0;
        weiRaised = weiRaised.sub(valueToReturn);

        _to.transfer(valueToReturn);
    }

    // Get amount of tokens
    // @param value weis paid for tokens
    function getTokenAmount(uint256 _value) internal view returns (uint256) {
        return _value.mul(rate);
    }

    // Send weis to the wallet
    function forwardFunds(uint256 _value) internal {
        wallet.transfer(_value);
    }

    // Success finish of PreSale
    function finishPreSale() public onlyOwner {
        require(weiRaised >= softCap);
        require(weiRaised >= hardCap || now > endTime);

        if (now < endTime) {
            endTime = now;
        }

        forwardFunds(this.balance);
        token.transferOwnership(owner);
    }

    // Change owner of token after end of PreSale if Soft Cap has not raised
    function changeTokenOwner() public onlyOwner {
        require(now > endTime && weiRaised < softCap);
        token.transferOwnership(owner);
    }

    // low level token purchase function
    function buyTokens(address _beneficiary) saleIsOn isUnderHardCap nonReentrant public payable {
        require(_beneficiary != address(0));
        require(msg.value >= minimumInvest);

        uint256 weiAmount = msg.value;
        uint256 tokens = getTokenAmount(weiAmount);
        tokens = tokens.add(tokens.mul(bonusPercent).div(100));

        token.mint(_beneficiary, tokens);

        // update states
        weiRaised = weiRaised.add(weiAmount);
        balances[_beneficiary] = balances[_beneficiary].add(weiAmount);

        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

    function() external payable {
        buyTokens(msg.sender);
    }
}