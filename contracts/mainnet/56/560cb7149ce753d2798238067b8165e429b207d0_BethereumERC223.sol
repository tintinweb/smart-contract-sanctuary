/*
--------------------------------------------------------------------------------
The Bethereum [BETHER] Token Smart Contract

Credit:
Bethereum Limited

ERC20: https://github.com/ethereum/EIPs/issues/20
ERC223: https://github.com/ethereum/EIPs/issues/223

MIT Licence
--------------------------------------------------------------------------------
*/

/*
* Contract that is working with ERC223 tokens
*/

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) {
        /* Fix for Mist warning */
        _from;
        _value;
        _data;
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

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


contract BethereumERC223 is ERC223Interface {
    using SafeMath for uint256;

    /* Contract Constants */
    string public constant _name = "Bethereum";
    string public constant _symbol = "BETHER";
    uint8 public constant _decimals = 18;

    /* Contract Variables */
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

    /* Constructor initializes the owner&#39;s balance and the supply  */
    function BethereumERC223() {
        totalSupply = 244890382832398351471266750;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    /* ERC20 Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);

    /* ERC223 Events */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    /* Returns the balance of a particular account */
    function balanceOf(address _address) constant returns (uint256 balance) {
        return balances[_address];
    }

    /* Transfer the balance from the sender&#39;s address to the address _to */
    function transfer(address _to, uint _value) returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            bytes memory empty;
            if(isContract(_to)) {
                return transferToContract(_to, _value, empty);
            } else {
                return transferToAddress(_to, _value, empty);
            }
        } else {
            return false;
        }
    }

    /* Withdraws to address _to form the address _from up to the amount _value */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value
        && allowed[_from][msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /* Allows _spender to withdraw the _allowance amount form sender */
    function approve(address _spender, uint256 _allowance) returns (bool success) {
        allowed[msg.sender][_spender] = _allowance;
        Approval(msg.sender, _spender, _allowance);
        return true;
    }

    /* Checks how much _spender can withdraw from _owner */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* ERC223 Functions */
    /* Get the contract constant _name */
    function name() constant returns (string name) {
        return _name;
    }

    /* Get the contract constant _symbol */
    function symbol() constant returns (string symbol) {
        return _symbol;
    }

    /* Get the contract constant _decimals */
    function decimals() constant returns (uint8 decimals) {
        return _decimals;
    }

    /* Transfer the balance from the sender&#39;s address to the address _to with data _data */
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            if(isContract(_to)) {
                return transferToContract(_to, _value, _data);
            } else {
                return transferToAddress(_to, _value, _data);
            }
        } else {
            return false;
        }
    }

    /* Transfer function when _to represents a regular address */
    function transferToAddress(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /* Transfer function when _to represents a contract address, with the caveat
    that the contract needs to implement the tokenFallback function in order to receive tokens */
    function transferToContract(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /* Infers if whether _address is a contract based on the presence of bytecode */
    function isContract(address _address) internal returns (bool is_contract) {
        uint length;
        if (_address == 0) return false;
        assembly {
        length := extcodesize(_address)
        }
        if(length > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* Stops any attempt to send Ether to this contract */
    function () {
        throw;
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
contract PausableToken is BethereumERC223, Pausable {

    function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value, _data);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is BethereumERC223, Ownable {
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

contract BETHERTokenSale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // Define sale
    uint public constant RATE = 17500;
    uint public constant TOKEN_SALE_LIMIT = 25000 * 1000000000000000000;

    uint256 public constant TOKENS_FOR_OPERATIONS = 400000000*(10**18);
    uint256 public constant TOKENS_FOR_SALE = 600000000*(10**18);

    uint public constant TOKENS_FOR_PRESALE = 315000000*(1 ether / 1 wei);

    uint public BONUS_PERCENTAGE;

    enum Phase {
    Created,
    CrowdsaleRunning,
    Paused
    }

    Phase public currentPhase = Phase.Created;

    event LogPhaseSwitch(Phase phase);

    // Constructor
    function BETHERTokenSale(
    uint256 _end,
    address _wallet
    )
    FinalizableCrowdsale()
    Crowdsale(_end, _wallet) {
    }

    function setNewBonusScheme(uint _bonusPercentage) {
        BONUS_PERCENTAGE = _bonusPercentage;
    }

    function mintRawTokens(address _buyer, uint256 _newTokens) public onlyOwner {
        token.mint(_buyer, _newTokens);
    }

    /// @dev Lets buy you some tokens.
    function buyTokens(address _buyer) public payable {
        // Available only if presale or crowdsale is running.
        require(currentPhase == Phase.CrowdsaleRunning);
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
        uint returnTokens;
        uint tokens = _newTokens;
        returnTokens = tokens.add(tokens.mul(BONUS_PERCENTAGE).div(100));

        return returnTokens;
    }

    function setSalePhase(Phase _nextPhase) public onlyOwner {
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }

    function transferTokenOwnership(address _newOwner) {
        token.transferOwnership(_newOwner);
    }

    // Finalize
    function finalization() internal {
        uint256 toMint = TOKENS_FOR_OPERATIONS;
        token.mint(wallet, toMint);
        token.finishMinting();
        token.transferOwnership(wallet);
    }
}