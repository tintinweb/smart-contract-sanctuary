pragma solidity ^ 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
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
    function totalSupply() public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require((_value != 0) && (allowed[msg.sender][_spender] != 0));

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Claimable {
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
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        return _mint(_to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Claimable {
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
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
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
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        // solium-disable-next-line security/no-block-members
        require(_releaseTime > block.timestamp);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    function canRelease() public view returns (bool){
        return block.timestamp >= releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solium-disable-next-line security/no-block-members
        require(canRelease());

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
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
contract Crowdsale{
    using SafeMath for uint256;

    enum TokenLockType { TYPE_NOT_LOCK, TYPE_SEED_INVESTOR, TYPE_PRE_SALE, TYPE_TEAM}
    uint256 internal constant UINT256_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint8 internal constant SEED_INVESTOR_BONUS_RATE = 50;
    uint256 internal constant MAX_SALECOUNT_PER_ADDRESS = 30;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per ether. eg: 1 ETH = 5000 ISC
    uint256 public rate = 5000;

    // Amount of wei raised
    uint256 public weiRaised;

    Phase[] internal phases;

    struct Phase {
        uint256 till;
        uint256 bonusRate;
    }

    uint256 public currentPhase = 0;
    mapping (address => uint256 ) public saleCount;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    /**
     * @param _wallet Address where collected funds will be forwarded to
     */
    function Crowdsale(address _wallet) public {
        require(_wallet != address(0));

        phases.push(Phase({ till: 1527782400, bonusRate: 30 })); // 2018/6/01 00:00 UTC +8
        phases.push(Phase({ till: 1531238400, bonusRate: 20 })); // 2018/07/11 00:00 UTC +8
        phases.push(Phase({ till: 1533916800, bonusRate: 10 })); // 2018/08/11 00:00 UTC +8
        phases.push(Phase({ till: UINT256_MAX, bonusRate: 0 })); // unlimited

        wallet = _wallet;
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

        uint256 nowTime = block.timestamp;
        // this loop moves phases and insures correct stage according to date
        while (currentPhase < phases.length && phases[currentPhase].till < nowTime) {
            currentPhase = currentPhase.add(1);
        }

        //check the min ether in pre-sale phase
        if (currentPhase == 0) {
            require(weiAmount >= 1 ether);
        }

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        // calculate token lock type
        TokenLockType lockType = _getTokenLockType(weiAmount);

        if (lockType != TokenLockType.TYPE_NOT_LOCK) {
            require(saleCount[_beneficiary].add(1) <= MAX_SALECOUNT_PER_ADDRESS);
            saleCount[_beneficiary] = saleCount[_beneficiary].add(1);
        }

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _deliverTokens(_beneficiary, tokens, lockType);
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
     * @dev Validation of an incoming purchase. Use require statements to revert state 
     *      when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(currentPhase < phases.length);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which 
     *      the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount, TokenLockType lockType) internal {

    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = _weiAmount.mul(rate);
        uint256 bonusRate = 0;
        if (_weiAmount >= 1000 ether) {
            bonusRate = SEED_INVESTOR_BONUS_RATE;
        } else {
            bonusRate = phases[currentPhase].bonusRate;
        }
        uint256 bonus = tokens.mul(bonusRate).div(uint256(100));        
        return tokens.add(bonus);
    }

    /**
     * @dev get the token lock type
     * @param _weiAmount Value in wei to be converted into tokens
     * @return token lock type
     */
    function _getTokenLockType(uint256 _weiAmount) internal view returns (TokenLockType) {
        TokenLockType lockType = TokenLockType.TYPE_NOT_LOCK;
        if (_weiAmount >= 1000 ether) {
            lockType = TokenLockType.TYPE_SEED_INVESTOR;
        } else if (currentPhase == 0 ) {
            lockType = TokenLockType.TYPE_PRE_SALE;
        }
        return lockType;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

contract StopableCrowdsale is Crowdsale, Claimable{

    bool public crowdsaleStopped = false;
    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyNotStopped {
        // solium-disable-next-line security/no-block-members
        require(!crowdsaleStopped);
        _;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyNotStopped {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function stopCrowdsale() public onlyOwner {
        require(!crowdsaleStopped);
        crowdsaleStopped = true;
    }

    function startCrowdsale() public onlyOwner {
        require(crowdsaleStopped);
        crowdsaleStopped = false;
    }
}


/**
 * @title ISCoin
 * @dev IS Coin contract
 */
contract ISCoin is PausableToken, MintableToken, BurnableToken, StopableCrowdsale {
    using SafeMath for uint256;

    string public name = "Imperial Star Coin";
    string public symbol = "ISC";
    uint8 public decimals = 18;

    mapping (address => address[] ) public balancesLocked;

    function ISCoin(address _wallet) public Crowdsale(_wallet) {}


    function setRate(uint256 _rate) public onlyOwner onlyNotStopped {
        require(_rate > 0);
        rate = _rate;
    }

    function setWallet(address _wallet) public onlyOwner onlyNotStopped {
        require(_wallet != address(0));
        wallet = _wallet;
    }    

    /**
     * @dev mint timelocked tokens for owner use
    */
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime) 
    public onlyOwner canMint returns (TokenTimelock) {
        return _mintTimelocked(_to, _amount, _releaseTime);
    }

    /**
     * @dev Gets the locked balance of the specified address.
     * @param _owner The address to query the locked balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOfLocked(address _owner) public view returns (uint256) {
        address[] memory timelockAddrs = balancesLocked[_owner];

        uint256 totalLockedBalance = 0;
        for (uint i = 0; i < timelockAddrs.length; i++) {
            totalLockedBalance = totalLockedBalance.add(balances[timelockAddrs[i]]);
        }
        
        return totalLockedBalance;
    }

    function releaseToken(address _owner) public {
        address[] memory timelockAddrs = balancesLocked[_owner];
        for (uint i = 0; i < timelockAddrs.length; i++) {
            TokenTimelock timelock = TokenTimelock(timelockAddrs[i]);
            if (timelock.canRelease() && balances[timelock] > 0) {
                timelock.release();
            }
        }
    }

    /**
     * @dev mint timelocked tokens
    */
    function _mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime)
    internal canMint returns (TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        balancesLocked[_to].push(timelock);
        _mint(timelock, _amount);
        return timelock;
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which 
     *      the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount, TokenLockType lockType) internal {
        if (lockType == TokenLockType.TYPE_NOT_LOCK) {
            _mint(_beneficiary, _tokenAmount);
        } else if (lockType == TokenLockType.TYPE_SEED_INVESTOR) {
            //seed insvestor will be locked for 6 months and then unlocked at one time
            _mintTimelocked(_beneficiary, _tokenAmount, now + 6 * 30 days);
        } else if (lockType == TokenLockType.TYPE_PRE_SALE) {
            //Pre-sale will be locked for 6 months and unlocked in 3 times(every 2 months)
            uint256 amount1 = _tokenAmount.mul(30).div(100);    //first unlock 30%
            uint256 amount2 = _tokenAmount.mul(30).div(100);    //second unlock 30%
            uint256 amount3 = _tokenAmount.sub(amount1).sub(amount2);   //third unlock 50%
            uint256 releaseTime1 = now + 2 * 30 days;
            uint256 releaseTime2 = now + 4 * 30 days;
            uint256 releaseTime3 = now + 6 * 30 days;
            _mintTimelocked(_beneficiary, amount1, releaseTime1);
            _mintTimelocked(_beneficiary, amount2, releaseTime2);
            _mintTimelocked(_beneficiary, amount3, releaseTime3);
        }
    }
}