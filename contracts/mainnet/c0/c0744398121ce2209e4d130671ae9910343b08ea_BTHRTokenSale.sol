pragma solidity ^0.4.18;

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
 * @title Pausable token
 *
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

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
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
        totalSupply = totalSupply.add(_amount);
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

contract BethereumToken is MintableToken, PausableToken {
    string public constant name = "Bethereum";
    string public constant symbol = "BTHR";
    uint256 public constant decimals = 18;

    function BethereumToken(){
        pause();
    }

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    MintableToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _endTime, address _wallet) {

        require(_endTime >= now);
        require(_wallet != 0x0);

        token = createTokenContract();
        endTime = _endTime;
        wallet = _wallet;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (BethereumToken) {
        return new BethereumToken();
    }


    // fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {  }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }
}

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;
    
    bool public weiCapReached = false;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        
        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal {
    }
}

contract BTHRTokenSale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // Define sale
    uint public constant RATE = 17500;
    uint public constant TOKEN_SALE_LIMIT = 25000 * 1000000000000000000;

    uint256 public constant TOKENS_FOR_OPERATIONS = 400000000*(10**18);
    uint256 public constant TOKENS_FOR_SALE = 600000000*(10**18);

    uint public constant TOKENS_FOR_PRESALE = 315000000*(1 ether / 1 wei);

    uint public constant FRST_CRWDSALE_RATIO = TOKENS_FOR_PRESALE + 147875000*(1 ether / 1 wei);//30% bonus
    uint public constant SCND_CRWDSALE_RATIO = FRST_CRWDSALE_RATIO + 110687500*(1 ether / 1 wei);//15% bonus

    enum Phase {
        Created,//Inital phase after deploy
        PresaleRunning, //Presale phase
        Paused, //Pause phase between pre-sale and main token sale or emergency pause function
        ICORunning, //Crowdsale phase
        FinishingICO //Final phase when crowdsale is closed and time is up
    }

    Phase public currentPhase = Phase.Created;

    event LogPhaseSwitch(Phase phase);

    // Constructor
    function BTHRTokenSale(uint256 _end, address _wallet)
    FinalizableCrowdsale()
    Crowdsale(_end, _wallet) {
    }

    /// @dev Lets buy you some tokens.
    function buyTokens(address _buyer) public payable {
        // Available only if presale or crowdsale is running.
        require((currentPhase == Phase.PresaleRunning) || (currentPhase == Phase.ICORunning));
        require(_buyer != address(0));
        require(msg.value > 0);
        require(validPurchase());

        uint tokensWouldAddTo = 0;
        uint weiWouldAddTo = 0;
        
        uint256 weiAmount = msg.value;
        
        uint newTokens = msg.value.mul(RATE);
        
        weiWouldAddTo = weiRaised.add(weiAmount);
        
        require(weiWouldAddTo <= TOKEN_SALE_LIMIT);

        newTokens = addBonusTokens(token.totalSupply(), newTokens);
        
        tokensWouldAddTo = newTokens.add(token.totalSupply());
        require(tokensWouldAddTo <= TOKENS_FOR_SALE);
        
        token.mint(_buyer, newTokens);
        TokenPurchase(msg.sender, _buyer, weiAmount, newTokens);
        
        weiRaised = weiWouldAddTo;
        forwardFunds();
        if (weiRaised == TOKENS_FOR_SALE){
            weiCapReached = true;
        }
    }

    // @dev Adds bonus tokens by token supply bought by user
    // @param _totalSupply total supply of token bought during pre-sale/crowdsale
    // @param _newTokens tokens currently bought by user
    function addBonusTokens(uint256 _totalSupply, uint256 _newTokens) internal view returns (uint256) {

        uint returnTokens = 0;
        uint tokensToAdd = 0;
        uint tokensLeft = _newTokens;

        if(currentPhase == Phase.PresaleRunning){
            if(_totalSupply < TOKENS_FOR_PRESALE){
                if(_totalSupply + tokensLeft + tokensLeft.mul(50).div(100) > TOKENS_FOR_PRESALE){
                    tokensToAdd = TOKENS_FOR_PRESALE.sub(_totalSupply);
                    tokensToAdd = tokensToAdd.mul(100).div(150);
                    
                    returnTokens = returnTokens.add(tokensToAdd);
                    returnTokens = returnTokens.add(tokensToAdd.mul(50).div(100));
                    tokensLeft = tokensLeft.sub(tokensToAdd);
                    _totalSupply = _totalSupply.add(tokensToAdd.add(tokensToAdd.mul(50).div(100)));
                } else { 
                    returnTokens = returnTokens.add(tokensLeft).add(tokensLeft.mul(50).div(100));
                    tokensLeft = tokensLeft.sub(tokensLeft);
                }
            }
        } 
        
        if (tokensLeft > 0 && _totalSupply < FRST_CRWDSALE_RATIO) {
            
            if(_totalSupply + tokensLeft + tokensLeft.mul(30).div(100)> FRST_CRWDSALE_RATIO){
                tokensToAdd = FRST_CRWDSALE_RATIO.sub(_totalSupply);
                tokensToAdd = tokensToAdd.mul(100).div(130);
                returnTokens = returnTokens.add(tokensToAdd).add(tokensToAdd.mul(30).div(100));
                tokensLeft = tokensLeft.sub(tokensToAdd);
                _totalSupply = _totalSupply.add(tokensToAdd.add(tokensToAdd.mul(30).div(100)));
                
            } else { 
                returnTokens = returnTokens.add(tokensLeft);
                returnTokens = returnTokens.add(tokensLeft.mul(30).div(100));
                tokensLeft = tokensLeft.sub(tokensLeft);
            }
        }
        
        if (tokensLeft > 0 && _totalSupply < SCND_CRWDSALE_RATIO) {
            
            if(_totalSupply + tokensLeft + tokensLeft.mul(15).div(100) > SCND_CRWDSALE_RATIO){

                tokensToAdd = SCND_CRWDSALE_RATIO.sub(_totalSupply);
                tokensToAdd = tokensToAdd.mul(100).div(115);
                returnTokens = returnTokens.add(tokensToAdd).add(tokensToAdd.mul(15).div(100));
                tokensLeft = tokensLeft.sub(tokensToAdd);
                _totalSupply = _totalSupply.add(tokensToAdd.add(tokensToAdd.mul(15).div(100)));
            } else { 
                returnTokens = returnTokens.add(tokensLeft);
                returnTokens = returnTokens.add(tokensLeft.mul(15).div(100));
                tokensLeft = tokensLeft.sub(tokensLeft);
            }
        }
        
        if (tokensLeft > 0)  {
            returnTokens = returnTokens.add(tokensLeft);
            tokensLeft = tokensLeft.sub(tokensLeft);
        }
        return returnTokens;
    }

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool isRunning = ((currentPhase == Phase.ICORunning) || (currentPhase == Phase.PresaleRunning));
        return withinPeriod && nonZeroPurchase && isRunning;
    }

    function setSalePhase(Phase _nextPhase) public onlyOwner {
    
        bool canSwitchPhase
        =  (currentPhase == Phase.Created && _nextPhase == Phase.PresaleRunning)
        || (currentPhase == Phase.PresaleRunning && _nextPhase == Phase.Paused)
        || ((currentPhase == Phase.PresaleRunning || currentPhase == Phase.Paused)
        && _nextPhase == Phase.ICORunning)
        || (currentPhase == Phase.ICORunning && _nextPhase == Phase.Paused)
        || (currentPhase == Phase.Paused && _nextPhase == Phase.PresaleRunning)
        || (currentPhase == Phase.Paused && _nextPhase == Phase.FinishingICO)
        || (currentPhase == Phase.ICORunning && _nextPhase == Phase.FinishingICO);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }

    // Finalize
    function finalization() internal {
        uint256 toMint = TOKENS_FOR_OPERATIONS;
        token.mint(wallet, toMint);
        token.finishMinting();
        token.transferOwnership(wallet);
    }
}