pragma solidity ^0.4.25;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => bool) blockListed;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
        require(
            balances[msg.sender] >= _value
            && _value > 0
            && !blockListed[_to]
            && !blockListed[msg.sender]
        );

        // SafeMath.sub will throw if there is not enough balance.
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

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(
            _to != address(0)
            && balances[msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            && !blockListed[_to]
            && !blockListed[msg.sender]
        );

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
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
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

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
        emit Burn(burner, _value);
    }
}

contract Ownable {
    address internal owner;


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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

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

        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function addBlockeddUser(address user) public onlyOwner {
        blockListed[user] = true;
    }

    function removeBlockeddUser(address user) public onlyOwner  {
        blockListed[user] = false;
    }
}

contract PullPayment {
    using SafeMath for uint256;

    mapping(address => uint256) public payments;
    uint256 public totalPayments;

    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param dest The destination address of the funds.
    * @param amount The amount to transfer.
    */
    function asyncSend(address dest, uint256 amount) internal {
        payments[dest] = payments[dest].add(amount);
        totalPayments = totalPayments.add(amount);
    }

    /**
    * @dev withdraw accumulated balance, called by payee.
    */
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(this.balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        assert(payee.send(payment));
    }
}


contract AutoCoinToken is MintableToken {

  /**
   *  @string name - Token Name
   *  @string symbol - Token Symbol
   *  @uint8 decimals - Token Decimals
   *  @uint256 _totalSupply - Token Total Supply
  */

    string public constant name = "AUTO COIN";
    string public constant symbol = "AUTO COIN";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 400000000000000000000000000;

/** Constructor AutoCoinToken */
    constructor() public {
        totalSupply = _totalSupply;
    }
}

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
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


contract Crowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    /**
    *  @MintableToken token - Token Object
    *  @address wallet - Wallet Address
    *  @uint8 rate - Tokens per Ether
    *  @uint256 weiRaised - Total funds raised in Ethers
    */

    MintableToken internal token;
    address internal wallet;
    uint256 public rate;
    uint256 internal weiRaised;

    /**
    *  @uint256 privateSaleStartTime - Private-Sale Start Time
    *  @uint256 privateSaleEndTime - Private-Sale End Time
    *  @uint256 preSaleStartTime - Pre-Sale Start Time
    *  @uint256 preSaleEndTime - Pre-Sale End Time
    *  @uint256 preICOStartTime - Pre-ICO Start Time
    *  @uint256 preICOEndTime - Pre-ICO End Time
    *  @uint256 ICOstartTime - ICO Start Time
    *  @uint256 ICOEndTime - ICO End Time
    */
    
    uint256 public privateSaleStartTime;
    uint256 public privateSaleEndTime;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preICOStartTime;
    uint256 public preICOEndTime;
    uint256 public ICOstartTime;
    uint256 public ICOEndTime;
    
    /**
    *  @uint privateBonus - Private Bonus
    *  @uint preSaleBonus - Pre-Sale Bonus
    *  @uint preICOBonus - Pre-Sale Bonus
    *  @uint firstWeekBonus - ICO 1st Week Bonus
    *  @uint secondWeekBonus - ICO 2nd Week Bonus
    *  @uint thirdWeekBonus - ICO 3rd Week Bonus
    *  @uint forthWeekBonus - ICO 4th Week Bonus
    *  @uint fifthWeekBonus - ICO 5th Week Bonus
    */

    uint256 internal privateSaleBonus;
    uint256 internal preSaleBonus;
    uint256 internal preICOBonus;
    uint256 internal firstWeekBonus;
    uint256 internal secondWeekBonus;
    uint256 internal thirdWeekBonus;
    uint256 internal forthWeekBonus;
    uint256 internal fifthWeekBonus;

    uint256 internal weekOne;
    uint256 internal weekTwo;
    uint256 internal weekThree;
    uint256 internal weekFour;
    uint256 internal weekFive;


    uint256 internal privateSaleTarget;
    uint256 internal preSaleTarget;
    uint256 internal preICOTarget;

    /**
    *  @uint256 totalSupply - Total supply of tokens 
    *  @uint256 publicSupply - Total public Supply 
    *  @uint256 bountySupply - Total Bounty Supply
    *  @uint256 reservedSupply - Total Reserved Supply 
    *  @uint256 privateSaleSupply - Total Private Supply from Public Supply  
    *  @uint256 preSaleSupply - Total PreSale Supply from Public Supply 
    *  @uint256 preICOSupply - Total PreICO Supply from Public Supply
    *  @uint256 icoSupply - Total ICO Supply from Public Supply
    */

    uint256 public totalSupply = SafeMath.mul(400000000, 1 ether);
    uint256 internal publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),55);
    uint256 internal bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),6);
    uint256 internal reservedSupply = SafeMath.mul(SafeMath.div(totalSupply,100),39);
    uint256 internal privateSaleSupply = SafeMath.mul(24750000, 1 ether);
    uint256 internal preSaleSupply = SafeMath.mul(39187500, 1 ether);
    uint256 internal preICOSupply = SafeMath.mul(39187500, 1 ether);
    uint256 internal icoSupply = SafeMath.mul(116875000, 1 ether);


    /**
    *  @bool checkUnsoldTokens - Tokens will be added to bounty supply
    *  @bool upgradePreSaleSupply - Boolean variable updates when the PrivateSale tokens added to PreSale supply
    *  @bool upgradePreICOSupply - Boolean variable updates when the PreSale tokens added to PreICO supply
    *  @bool upgradeICOSupply - Boolean variable updates when the PreICO tokens added to ICO supply
    *  @bool grantFounderTeamSupply - Boolean variable updates when Team and Founder tokens minted
    */

    bool public checkUnsoldTokens;
    bool internal upgradePreSaleSupply;
    bool internal upgradePreICOSupply;
    bool internal upgradeICOSupply;



    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value Wei&#39;s paid for purchase
    * @param amount amount of tokens purchased
    */

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * function Crowdsale - Parameterized Constructor
    * @param _startTime - StartTime of Crowdsale
    * @param _endTime - EndTime of Crowdsale
    * @param _rate - Tokens against Ether
    * @param _wallet - MultiSignature Wallet Address
    */

    constructor(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) internal {
        
        require(_wallet != 0x0);

        token = createTokenContract();

        privateSaleStartTime = _startTime;
        privateSaleEndTime = 1537952399;
        preSaleStartTime = 1537952400;
        preSaleEndTime = 1541581199;
        preICOStartTime = 1541581200;
        preICOEndTime = 1544000399; 
        ICOstartTime = 1544000400;
        ICOEndTime = _endTime;

        rate = _rate;
        wallet = _wallet;

        privateSaleBonus = SafeMath.div(SafeMath.mul(rate,50),100);
        preSaleBonus = SafeMath.div(SafeMath.mul(rate,30),100);
        preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
        firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
        secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
        thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
        forthWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
        

        weekOne = SafeMath.add(ICOstartTime, 14 days);
        weekTwo = SafeMath.add(weekOne, 14 days);
        weekThree = SafeMath.add(weekTwo, 14 days);
        weekFour = SafeMath.add(weekThree, 14 days);
        weekFive = SafeMath.add(weekFour, 14 days);

        privateSaleTarget = SafeMath.mul(4500, 1 ether);
        preSaleTarget = SafeMath.mul(7125, 1 ether);
        preICOTarget = SafeMath.mul(7125, 1 ether);

        checkUnsoldTokens = false;
        upgradeICOSupply = false;
        upgradePreICOSupply = false;
        upgradePreSaleSupply = false;
    
    }

    /**
    * function createTokenContract - Mintable Token Created
    */

    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }
    
    /**
    * function Fallback - Receives Ethers
    */

    function () payable public {
        buyTokens(msg.sender);
    }

        /**
    * function preSaleTokens - Calculate Tokens in PreSale
    */

    function privateSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        require(privateSaleSupply > 0);
        require(weiAmount <= privateSaleTarget);

        tokens = SafeMath.add(tokens, weiAmount.mul(privateSaleBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));

        require(privateSaleSupply >= tokens);

        privateSaleSupply = privateSaleSupply.sub(tokens);        
        privateSaleTarget = privateSaleTarget.sub(weiAmount);

        return tokens;
    }


    /**
    * function preSaleTokens - Calculate Tokens in PreSale
    */

    function preSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        require(preSaleSupply > 0);
        require(weiAmount <= preSaleTarget);

        if (!upgradePreSaleSupply) {
            preSaleSupply = SafeMath.add(preSaleSupply, privateSaleSupply);
            preSaleTarget = SafeMath.add(preSaleTarget, privateSaleTarget);
            upgradePreSaleSupply = true;
        }

        tokens = SafeMath.add(tokens, weiAmount.mul(preSaleBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));

        require(preSaleSupply >= tokens);

        preSaleSupply = preSaleSupply.sub(tokens);        
        preSaleTarget = preSaleTarget.sub(weiAmount);
        return tokens;
    }

    /**
        * function preICOTokens - Calculate Tokens in PreICO
        */

    function preICOTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
            
        require(preICOSupply > 0);
        require(weiAmount <= preICOTarget);

        if (!upgradePreICOSupply) {
            preICOSupply = SafeMath.add(preICOSupply, preSaleSupply);
            preICOTarget = SafeMath.add(preICOTarget, preSaleTarget);
            upgradePreICOSupply = true;
        }

        tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        
        require(preICOSupply >= tokens);
        
        preICOSupply = preICOSupply.sub(tokens);        
        preICOTarget = preICOTarget.sub(weiAmount);
        return tokens;
    }

    /**
    * function icoTokens - Calculate Tokens in ICO
    */
    
    function icoTokens(uint256 weiAmount, uint256 tokens, uint256 accessTime) internal returns (uint256) {
            
        require(icoSupply > 0);

        if (!upgradeICOSupply) {
            icoSupply = SafeMath.add(icoSupply,preICOSupply);
            upgradeICOSupply = true;
        }
        
        if (accessTime <= weekOne) {
            tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwo) {
            tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
        } else if ( accessTime < weekThree ) {
            tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
        } else if ( accessTime < weekFour ) {
            tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
        } else if ( accessTime < weekFive ) {
            tokens = SafeMath.add(tokens, weiAmount.mul(fifthWeekBonus));
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        

        return tokens;
    }

    /**
    * function buyTokens - Collect Ethers and transfer tokens
    */

    function buyTokens(address beneficiary) whenNotPaused internal {

        require(beneficiary != 0x0);
        require(validPurchase());
        uint256 accessTime = now;
        uint256 tokens = 0;
        uint256 weiAmount = msg.value;

        require((weiAmount >= (100000000000000000)) && (weiAmount <= (20000000000000000000)));

        if ((accessTime >= privateSaleStartTime) && (accessTime < privateSaleEndTime)) {
            tokens = privateSaleTokens(weiAmount, tokens);
        } else if ((accessTime >= preSaleStartTime) && (accessTime < preSaleEndTime)) {
            tokens = preSaleTokens(weiAmount, tokens);
        } else if ((accessTime >= preICOStartTime) && (accessTime < preICOEndTime)) {
            tokens = preICOTokens(weiAmount, tokens);
        } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) { 
            tokens = icoTokens(weiAmount, tokens, accessTime);
        } else {
            revert();
        }
        
        publicSupply = publicSupply.sub(tokens);
        weiRaised = weiRaised.add(weiAmount);
        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    /**
    * function forwardFunds - Transfer funds to wallet
    */

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /**
    * function validPurchase - Checks the purchase is valid or not
    * @return true - Purchase is withPeriod and nonZero
    */

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= privateSaleStartTime && now <= ICOEndTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    /**
    * function hasEnded - Checks the ICO ends or not
    * @return true - ICO Ends
    */
    
    function hasEnded() public view returns (bool) {
        return now > ICOEndTime;
    }

    /**
    * function unsoldToken - Function used to transfer all 
    *               unsold public tokens to reserve supply
    */

    function unsoldToken() onlyOwner public {
        require(hasEnded());
        require(!checkUnsoldTokens);
        
        checkUnsoldTokens = true;
        bountySupply = SafeMath.add(bountySupply, publicSupply);
        publicSupply = 0;

    }

    /** 
    * function getTokenAddress - Get Token Address 
    */

    function getTokenAddress() onlyOwner view public returns (address) {
        return token;
    }
}

contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {
        return super.validPurchase() && weiRaised.add(msg.value) <= cap;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return super.hasEnded() || weiRaised >= cap;
    }
}

contract CrowdsaleFunctions is Crowdsale {

 /** 
  * function bountyFunds - Transfer bounty tokens via AirDrop
  * @param beneficiary address where owner wants to transfer tokens
  * @param tokens value of token
  */

    function bountyFunds(address[] beneficiary, uint256[] tokens) public onlyOwner {

        for (uint256 i = 0; i < beneficiary.length; i++) {
            tokens[i] = SafeMath.mul(tokens[i],1 ether); 

            require(beneficiary[i] != 0x0);
            require(bountySupply >= tokens[i]);
            
            bountySupply = SafeMath.sub(bountySupply,tokens[i]);
            token.mint(beneficiary[i], tokens[i]);
        }
    }


  /** 
   * function grantReservedToken - Transfer advisor,team and founder tokens  
   */

    function grantReservedToken(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != 0x0);
        require(reservedSupply > 0);

        tokens = SafeMath.mul(tokens,1 ether);
        require(reservedSupply >= tokens);
        reservedSupply = SafeMath.sub(reservedSupply,tokens);
        token.mint(beneficiary, tokens);
    }

/** 
 *.function transferToken - Used to transfer tokens to investors who pays us other than Ethers
 * @param beneficiary - Address where owner wants to transfer tokens
 * @param tokens -  Number of tokens
 */
    function transferToken(address beneficiary, uint256 tokens) onlyOwner public {
        
        require(beneficiary != 0x0);
        require(publicSupply > 0);
        tokens = SafeMath.mul(tokens,1 ether);
        require(publicSupply >= tokens);
        publicSupply = SafeMath.sub(publicSupply,tokens);
        token.mint(beneficiary, tokens);
    }

    function addBlockListed(address user) public onlyOwner {
        token.addBlockeddUser(user);
    }
    
    function removeBlockListed(address user) public onlyOwner {
        token.removeBlockeddUser(user);
    }
}

contract FinalizableCrowdsale is Crowdsale {
    using SafeMath for uint256;

    bool isFinalized = false;

    event Finalized();

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
    * @dev Can be overridden to add finalization logic. The overriding function
    * should call super.finalization() to ensure the chain of finalization is
    * executed entirely.
    */
    function finalization() internal view {
    }
}

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 public goal;
    bool private _goalReached = false;
    // refund vault used to hold funds while crowdsale is running
    RefundVault private vault;

    constructor(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    // We&#39;re overriding the fund forwarding from Crowdsale.
    // In addition to sending the funds, we want to call
    // the RefundVault deposit function
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    // vault finalization task, called when owner calls finalize()
    function finalization() internal view {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
        super.finalization();
    }

    function goalReached() public payable returns (bool) {
        if (weiRaised >= goal) {
            _goalReached = true;
            return true;
        } else if (_goalReached) {
            return true;
        } 
        else {
            return false;
        }
    }

    function updateGoalCheck() onlyOwner public {
        _goalReached = true;
    }

    function getVaultAddress() onlyOwner view public returns (address) {
        return vault;
    }
}

contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    constructor(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}