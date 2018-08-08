pragma solidity ^0.4.23;

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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
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

        _forwardFunds();
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal view
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) != 0);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _allocateTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.transfer(_beneficiary, _tokenAmount);
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
        _allocateTokens(_beneficiary, _tokenAmount);
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
    function balanceOf(address _owner) public view returns (uint256) {
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

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
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
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
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
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
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
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    returns (bool)
    {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(
        address _to,
        uint256 _amount
    )
    hasMintPermission
    canMint
    public
    returns (bool)
    {
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
    function finishMinting() onlyOwner canMint external returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param _cap Max amount of wei to be contributed
     */
    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() external view returns (bool) {
        return weiRaised >= cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal view
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }

}

/**
 * @title IndividuallyCappedCrowdsale
 * @dev Crowdsale with individual contributor cap and minimum investment limit.
 */
contract IndividuallyCappedCrowdsale is Crowdsale, CappedCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) public contributions;
    uint256 public individualCap;
    uint256 public miniumInvestment;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale and minimum limit for individuals.
     * @param _individualCap Max amount of wei that can be contributed by individuals
     * @param _miniumInvestment Min amount of wei that can be contributed by individuals
     */
    constructor(uint256 _individualCap, uint256 _miniumInvestment) public {
        require(_individualCap > 0);
        require(_miniumInvestment > 0);
        individualCap = _individualCap;
        miniumInvestment = _miniumInvestment;
    }


    /**
     * @dev Extend parent behavior requiring purchase to respect the contributor&#39;s funding cap.
     * @param _beneficiary Address of contributor
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount <= individualCap);
        require(_weiAmount >= miniumInvestment);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}


contract Namahecrowdsale is Pausable, IndividuallyCappedCrowdsale {

    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;
    bool public isFinalized = false;

    bool public quarterFirst = true;
    bool public quarterSecond = true;
    bool public quarterThird = true;
    bool public quarterFourth = true;

    uint256 public rate = 1000;
    bool public preAllocationsPending = true;         // Indicates if pre allocations are pending
    uint256 public totalAllocated = 0;
    mapping(address => uint256) public allocated;     // To track allocated tokens
    address[] public allocatedAddresses;              // To track list of contributors

    address public constant _controller  = 0x6E21c63511b0dD8f2C67BB5230C5b831f6cd7986;
    address public constant _reserve     = 0xE4627eE46f9E0071571614ca86441AFb42972A66;
    address public constant _promo       = 0x894387C61144f1F3a2422D17E61638B3263286Ee;
    address public constant _holding     = 0xC7592b24b4108b387A9F413fa4eA2506a7F32Ae9;

    address public constant _founder_one = 0x3f7dB633ABAb31A687dd1DFa0876Df12Bfc18DBE;
    address public constant _founder_two = 0xCDb0EF350717d743d47A358EADE1DF2CB71c1E4F;

    uint256 public constant PROMO_TOKEN_AMOUNT   = 6000000E18; // Promotional 6,000,000;
    uint256 public constant RESERVE_TOKEN_AMOUNT = 24000000E18; // Reserved tokens 24,000,000;
    uint256 public constant TEAM_TOKEN_AMOUNT    = 15000000E18; // Team and Advisors 15,000,000 each;

    uint256 public constant QUARTERLY_RELEASE    = 3750000E18; // To allocate 3,750,000;

    MintableToken public token;

    event AllocationApproved(address indexed purchaser, uint256 amount);
    event Finalized();

    constructor (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _cap,
        uint256 _miniumInvestment,
        uint256 _individualCap,
        MintableToken _token
    )

    public
    Crowdsale(rate, _controller, _token)
    CappedCrowdsale(_cap)
    IndividuallyCappedCrowdsale(_individualCap, _miniumInvestment)
    {
        openingTime = _openingTime;
        closingTime = _closingTime;
        token = _token;

    }

    /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    /**
    * @dev Complete pre-allocations to team, promotions and reserve pool
    */
    function doPreAllocations() external onlyOwner returns (bool) {
        require(preAllocationsPending);

        //Allocate promo tokens immediately
        token.transfer(_promo, PROMO_TOKEN_AMOUNT);

        //Allocate team tokens _team account through internal method
        //_allocateTokens(_team, TEAM_TOKEN_AMOUNT);
        _allocateTokens(_founder_one, TEAM_TOKEN_AMOUNT);
        _allocateTokens(_founder_two, TEAM_TOKEN_AMOUNT);

        //Allocate reserved tokens to _reserve account through internal method
        _allocateTokens(_reserve, RESERVE_TOKEN_AMOUNT);

        totalAllocated = totalAllocated.add(PROMO_TOKEN_AMOUNT);
        preAllocationsPending = false;
        return true;
    }

    /**
    * @dev Approves tokens allocated to a beneficiary
    * @param _beneficiary Token purchaser
    */
    function approveAllocation(address _beneficiary) external onlyOwner returns (bool) {
        require(_beneficiary != address(0));
        require(_beneficiary != _founder_one);
        require(_beneficiary != _founder_two);
        require(_beneficiary != _reserve);

        uint256 allocatedTokens = allocated[_beneficiary];
        token.transfer(_beneficiary, allocated[_beneficiary]);
        allocated[_beneficiary] = 0;
        emit AllocationApproved(_beneficiary, allocatedTokens);

        return true;
    }

    /**
    * @dev Release reserved tokens to _reserve address only after vesting period
    */
    function releaseReservedTokens() external onlyOwner {
        require(block.timestamp > (openingTime.add(52 weeks)));
        require(allocated[_reserve] > 0);

        token.transfer(_reserve, RESERVE_TOKEN_AMOUNT);
        allocated[_reserve] = 0;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() external onlyOwner {
        require(!isFinalized);
        require(hasClosed());
        require(!preAllocationsPending);

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
     * @dev Extends crowdsale end date
     */
    function extendCrowdsale(uint256 _closingTime) external onlyOwner {
        require(_closingTime > closingTime);
        require(block.timestamp <= openingTime.add(36 weeks));

        closingTime = _closingTime;
    }

    /**
     * @dev Every quarter release, 25% of token to the founders
     */
    function releaseFounderTokens() external onlyOwner returns (bool) {
        if (quarterFirst && block.timestamp >= (openingTime.add(10 weeks))) {
            quarterFirst = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);

        }

        if (quarterSecond && block.timestamp >= (openingTime.add(22 weeks))) {
            quarterSecond = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
        }

        if (quarterThird && block.timestamp >= (openingTime.add(34 weeks))) {
            quarterThird = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
        }

        if (quarterFourth && block.timestamp >= (openingTime.add(46 weeks))) {
            quarterFourth = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
        }

        return true;
    }

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    /**
    * @dev Returns rate as per bonus structure
    * @return Rate
    */
    function getRate() public view returns (uint256) {

        if (block.timestamp <= (openingTime.add(14 days))) {return rate.add(200);}
        if (block.timestamp <= (openingTime.add(28 days))) {return rate.add(100);}
        if (block.timestamp <= (openingTime.add(49 days))) {return rate.add(50);}

        return rate;
    }

    /**
    * @dev Releases unapproved tokens to _holding address. Only called during finalization.
    */
    function reclaimAllocated() internal {

        uint256 unapprovedTokens = 0;
        for (uint256 i = 0; i < allocatedAddresses.length; i++) {
            // skip counting _team and _reserve allocations
            if (allocatedAddresses[i] != _founder_one && allocatedAddresses[i] != _founder_two && allocatedAddresses[i] != _reserve) {
                unapprovedTokens = unapprovedTokens.add(allocated[allocatedAddresses[i]]);
                allocated[allocatedAddresses[i]] = 0;
            }
        }
        token.transfer(_holding, unapprovedTokens);
    }

    /**
    * @dev Reclaim remaining tokens after crowdsale is complete. Tokens allocated to
    * _team and _balance will be left out to arrive at balance tokens.
    */
    function reclaimBalanceTokens() internal {

        uint256 balanceTokens = token.balanceOf(this);
        balanceTokens = balanceTokens.sub(allocated[_founder_one]);
        balanceTokens = balanceTokens.sub(allocated[_founder_two]);
        balanceTokens = balanceTokens.sub(allocated[_reserve]);
        token.transfer(_controller, balanceTokens);
    }

    /**
    * @dev Overridden to add finalization logic.
    */
    function finalization() internal {
        reclaimAllocated();
        reclaimBalanceTokens();
    }

    /**
    * @dev Overridden to adjust the rate including bonus
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the given _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenAmount = _weiAmount.mul(getRate());
        return tokenAmount;
    }

    /**
    * @dev Extend parent behavior requiring to be within contributing period.
    * If purchases are paused, transactions fail.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen whenNotPaused {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /**
    * @dev Overriden method to update tokens allocated to a beneficiary
    * @param _beneficiary Address sending ether
    * @param _tokenAmount Number of token to be allocated
    */
    function _allocateTokens(address _beneficiary, uint256 _tokenAmount) internal {
        //token.transfer(_beneficiary, _tokenAmount);
        require(token.balanceOf(this) >= totalAllocated.add(_tokenAmount));
        allocated[_beneficiary] = allocated[_beneficiary].add(_tokenAmount);
        totalAllocated = totalAllocated.add(_tokenAmount);
        allocatedAddresses.push(_beneficiary);

    }
}