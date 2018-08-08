pragma solidity ^ 0.4.19;

/**
 * @title GdprConfig
 * @dev Configuration for GDPR Cash token and crowdsale
*/
contract GdprConfig {

    // Token settings
    string public constant TOKEN_NAME = "GDPR Cash";
    string public constant TOKEN_SYMBOL = "GDPR";
    uint8 public constant TOKEN_DECIMALS = 18;

    // Smallest value of the GDPR
    uint256 public constant MIN_TOKEN_UNIT = 10 ** uint256(TOKEN_DECIMALS);
    // Minimum cap per purchaser on public sale ~ $100 in GDPR Cash
    uint256 public constant PURCHASER_MIN_TOKEN_CAP = 500 * MIN_TOKEN_UNIT;
    // Maximum cap per purchaser on first day of public sale ~ $2,000 in GDPR Cash
    uint256 public constant PURCHASER_MAX_TOKEN_CAP_DAY1 = 10000 * MIN_TOKEN_UNIT;
    // Maximum cap per purchaser on public sale ~ $20,000 in GDPR
    uint256 public constant PURCHASER_MAX_TOKEN_CAP = 100000 * MIN_TOKEN_UNIT;

    // Crowdsale rate GDPR / ETH
    uint256 public constant INITIAL_RATE = 7600; // 7600 GDPR for 1 ether

    // Initial distribution amounts
    uint256 public constant TOTAL_SUPPLY_CAP = 200000000 * MIN_TOKEN_UNIT;
    // 60% of the total supply cap
    uint256 public constant SALE_CAP = 120000000 * MIN_TOKEN_UNIT;
    // 10% tokens for the experts
    uint256 public constant EXPERTS_POOL_TOKENS = 20000000 * MIN_TOKEN_UNIT;
    // 10% tokens for marketing expenses
    uint256 public constant MARKETING_POOL_TOKENS = 20000000 * MIN_TOKEN_UNIT;
    // 9% founders&#39; distribution
    uint256 public constant TEAM_POOL_TOKENS = 18000000 * MIN_TOKEN_UNIT;
    // 1% for legal advisors
    uint256 public constant LEGAL_EXPENSES_TOKENS = 2000000 * MIN_TOKEN_UNIT;
    // 10% tokens for the reserve
    uint256 public constant RESERVE_POOL_TOKENS = 20000000 * MIN_TOKEN_UNIT;

    // Contract wallet addresses for initial allocation
    address public constant EXPERTS_POOL_ADDR = 0x289bB02deaF473c6Aa5edc4886A71D85c18F328B;
    address public constant MARKETING_POOL_ADDR = 0x7BFD82C978EDDce94fe12eBF364c6943c7cC2f27;
    address public constant TEAM_POOL_ADDR = 0xB4AfbF5F39895adf213194198c0ba316f801B24d;
    address public constant LEGAL_EXPENSES_ADDR = 0xf72931B08f8Ef3d8811aD682cE24A514105f713c;
    address public constant SALE_FUNDS_ADDR = 0xb8E81a87c6D96ed5f424F0A33F13b046C1f24a24;
    address public constant RESERVE_POOL_ADDR = 0x010aAA10BfB913184C5b2E046143c2ec8A037413;
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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract DetailedERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
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
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
    function balanceOf(address _owner) public view returns(uint256 balance) {
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
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
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
    function approve(address _spender, uint256 _value) public returns(bool) {
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
    function allowance(address _owner, address _spender) public view returns(uint256) {
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
    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
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
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
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
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
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
    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}



/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

    uint256 public cap;

    function CappedToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        require(totalSupply_.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}




/**
 * @title GdprCash
 * @dev GDPR Cash - the token used in the gdpr.cash network.
 *
 * All tokens are preminted and distributed at deploy time.
 * Transfers are disabled until the crowdsale is over. 
 * All unsold tokens are burned.
 */
contract GdprCash is DetailedERC20, CappedToken, GdprConfig {

    bool private transfersEnabled = false;
    address public crowdsale = address(0);

    /**
     * @dev Triggered on token burn
     */
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Transfers are restricted to the crowdsale and owner only
     *      until the crowdsale is over.
     */
    modifier canTransfer() {
        require(transfersEnabled || msg.sender == owner || msg.sender == crowdsale);
        _;
    }

    /**
     * @dev Restriected to the crowdsale only
     */
    modifier onlyCrowdsale() {
        require(msg.sender == crowdsale);
        _;
    }

    /**
     * @dev Constructor that sets name, symbol, decimals as well as a maximum supply cap.
     */
    function GdprCash() public
    DetailedERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS)
    CappedToken(TOTAL_SUPPLY_CAP) {
    }

    /**
     * @dev Sets the crowdsale. Can be invoked only once and by the owner
     * @param _crowdsaleAddr address The address of the crowdsale contract
     */
    function setCrowdsale(address _crowdsaleAddr) external onlyOwner {
        require(crowdsale == address(0));
        require(_crowdsaleAddr != address(0));
        require(!transfersEnabled);
        crowdsale = _crowdsaleAddr;

        // Generate sale tokens
        mint(crowdsale, SALE_CAP);

        // Distribute non-sale tokens to pools
        mint(EXPERTS_POOL_ADDR, EXPERTS_POOL_TOKENS);
        mint(MARKETING_POOL_ADDR, MARKETING_POOL_TOKENS);
        mint(TEAM_POOL_ADDR, TEAM_POOL_TOKENS);
        mint(LEGAL_EXPENSES_ADDR, LEGAL_EXPENSES_TOKENS);
        mint(RESERVE_POOL_ADDR, RESERVE_POOL_TOKENS);

        finishMinting();
    }

    /**
     * @dev Checks modifier and transfers
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transfer(address _to, uint256 _value)
        public canTransfer returns(bool)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Checks modifier and transfers
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public canTransfer returns(bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Enables token transfers.
     * Called when the token sale is successfully finalized
     */
    function enableTransfers() public onlyCrowdsale {
        transfersEnabled = true;
    }

    /**
    * @dev Burns a specific number of tokens.
    * @param _value uint256 The number of tokens to be burned.
    */
    function burn(uint256 _value) public onlyCrowdsale {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}





/**
 * @title GDPR Crowdsale
 * @dev GDPR Cash crowdsale contract. 
 */
contract GdprCrowdsale is Pausable {
    using SafeMath for uint256;

        // Token contract
        GdprCash public token;

    // Start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of raised money in wei
    uint256 public weiRaised = 0;

    // Total amount of tokens purchased
    uint256 public totalPurchased = 0;

    // Purchases
    mapping(address => uint256) public tokensPurchased;

    // Whether the crowdsale is finalized
    bool public isFinalized = false;

    // Crowdsale events
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
        uint256 amount);

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param amount amount of tokens purchased
    */
    event TokenPresale(
        address indexed purchaser,
        uint256 amount);

    /**
     * Event invoked when the rate is changed
     * @param newRate The new rate GDPR / ETH
     */
    event RateChange(uint256 newRate);

    /**
     * Triggered when ether is withdrawn to the sale wallet
     * @param amount How many funds to withdraw in wei
     */
    event FundWithdrawal(uint256 amount);

    /**
     * Event for crowdsale finalization
     */
    event Finalized();

    /**
     * @dev GdprCrowdsale contract constructor
     * @param _startTime uint256 Unix timestamp representing the crowdsale start time
     * @param _endTime uint256 Unix timestamp representing the crowdsale end time
     * @param _tokenAddress address Address of the GDPR Cash token contract
     */
    function GdprCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress
    ) public
    {
        require(_endTime > _startTime);
        require(_tokenAddress != address(0));

        startTime = _startTime;
        endTime = _endTime;
        token = GdprCash(_tokenAddress);
        rate = token.INITIAL_RATE();
        wallet = token.SALE_FUNDS_ADDR();
    }

    /**
     * @dev Fallback function is used to buy tokens.
     * It&#39;s the only entry point since `buyTokens` is internal.
     * When paused funds are not accepted.
     */
    function () public whenNotPaused payable {
        buyTokens(msg.sender, msg.value);
    }

    /**
     * @dev Sets a new start date as long as token sale hasn&#39;t started yet
     * @param _startTime uint256 Unix timestamp of the new start time
     */
    function setStartTime(uint256 _startTime) public onlyOwner {
        require(now < startTime);
        require(_startTime > now);
        require(_startTime < endTime);

        startTime = _startTime;
    }

    /**
     * @dev Sets a new end date as long as end date hasn&#39;t been reached
     * @param _endTime uint2t56 Unix timestamp of the new end time
     */
    function setEndTime(uint256 _endTime) public onlyOwner {
        require(now < endTime);
        require(_endTime > now);
        require(_endTime > startTime);

        endTime = _endTime;
    }

    /**
     * @dev Updates the GDPR/ETH conversion rate
     * @param _rate uint256 Updated conversion rate
     */
    function setRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        rate = _rate;
        RateChange(rate);
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() public onlyOwner {
        require(now > endTime);
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Anyone can check if the crowdsale is over
     * @return true if crowdsale has endeds
     */
    function hasEnded() public view returns(bool) {
        return now > endTime;
    }

    /**
     * @dev Transfers ether to the sale wallet
     * @param _amount uint256 The amount to withdraw. 
     * If 0 supplied transfers the entire balance.
     */
    function withdraw(uint256 _amount) public onlyOwner {
        require(this.balance > 0);
        require(_amount <= this.balance);
        uint256 balanceToSend = _amount;
        if (balanceToSend == 0) {
            balanceToSend = this.balance;
        }
        wallet.transfer(balanceToSend);
        FundWithdrawal(balanceToSend);
    }

    /**
     *  @dev Registers a presale order
     *  @param _participant address The address of the token purchaser
     *  @param _tokenAmount uin256 The amount of GDPR Cash (in wei) purchased
     */
    function addPresaleOrder(address _participant, uint256 _tokenAmount) external onlyOwner {
        require(now < startTime);

        // Update state
        tokensPurchased[_participant] = tokensPurchased[_participant].add(_tokenAmount);
        totalPurchased = totalPurchased.add(_tokenAmount);

        token.transfer(_participant, _tokenAmount);

        TokenPresale(
            _participant,
            _tokenAmount
        );
    }

    /**
     *  @dev Token purchase logic. Used internally.
     *  @param _participant address The address of the token purchaser
     *  @param _weiAmount uin256 The amount of ether in wei sent to the contract
     */
    function buyTokens(address _participant, uint256 _weiAmount) internal {
        require(_participant != address(0));
        require(now >= startTime);
        require(now < endTime);
        require(!isFinalized);
        require(_weiAmount != 0);

        // Calculate the token amount to be allocated
        uint256 tokens = _weiAmount.mul(rate);

        // Update state
        tokensPurchased[_participant] = tokensPurchased[_participant].add(tokens);
        totalPurchased = totalPurchased.add(tokens);
        // update state
        weiRaised = weiRaised.add(_weiAmount);

        require(totalPurchased <= token.SALE_CAP());
        require(tokensPurchased[_participant] >= token.PURCHASER_MIN_TOKEN_CAP());

        if (now < startTime + 86400) {
            // if still during the first day of token sale, apply different max cap
            require(tokensPurchased[_participant] <= token.PURCHASER_MAX_TOKEN_CAP_DAY1());
        } else {
            require(tokensPurchased[_participant] <= token.PURCHASER_MAX_TOKEN_CAP());
        }

        token.transfer(_participant, tokens);

        TokenPurchase(
            msg.sender,
            _participant,
            _weiAmount,
            tokens
        );
    }

    /**
     * @dev Additional finalization logic. 
     * Enables token transfers and burns all unsold tokens.
     */
    function finalization() internal {
        withdraw(0);
        burnUnsold();
        token.enableTransfers();
    }

    /**
     * @dev Burn all remaining (unsold) tokens.
     * This should be called automatically after sale finalization
     */
    function burnUnsold() internal {
        // All tokens held by this contract get burned
        token.burn(token.balanceOf(this));
    }
}