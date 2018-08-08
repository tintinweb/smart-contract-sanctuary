pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value);
    function approve(address spender, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
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
    * @param _value uint256 the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    /**
    * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifing the amount of tokens still avaible for the spender.
    */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title TKRPToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract TKRPToken is StandardToken {
    event Destroy(address indexed _from);

    string public name = "TKRPToken";
    string public symbol = "TKRP";
    uint256 public decimals = 18;
    uint256 public initialSupply = 500000;

    /**
    * @dev Contructor that gives the sender all tokens
    */
    function TKRPToken() {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    /**
    * @dev Destroys tokens from an address, this process is irrecoverable.
    * @param _from The address to destroy the tokens from.
    */
    function destroyFrom(address _from) onlyOwner returns (bool) {
        uint256 balance = balanceOf(_from);
        require(balance > 0);

        balances[_from] = 0;
        totalSupply = totalSupply.sub(balance);

        Destroy(_from);
    }
}

/**
 * @title TKRToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract TKRToken is StandardToken {
    event Destroy(address indexed _from, address indexed _to, uint256 _value);

    string public name = "TKRToken";
    string public symbol = "TKR";
    uint256 public decimals = 18;
    uint256 public initialSupply = 65500000 * 10 ** 18;

    /**
    * @dev Contructor that gives the sender all tokens
    */
    function TKRToken() {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    /**
    * @dev Destroys tokens, this process is irrecoverable.
    * @param _value The amount to destroy.
    */
    function destroy(uint256 _value) onlyOwner returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Destroy(msg.sender, 0x0, _value);
    }
}

/**
 * @title Crowdsale
 * @dev Smart contract which collects ETH and in return transfers the TKRToken to the contributors
 * Log events are emitted for each transaction 
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;

    /* 
    * Stores the contribution in wei
    * Stores the amount received in TKR
    */
    struct Contributor {
        uint256 contributed;
        uint256 received;
    }

    /* Backers are keyed by their address containing a Contributor struct */
    mapping(address => Contributor) public contributors;

    /* Events to emit when a contribution has successfully processed */
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);
    event MigratedTokens(address indexed _address, uint256 value);

    /* Constants */
    uint256 public constant TOKEN_CAP = 58500000 * 10 ** 18;
    uint256 public constant MINIMUM_CONTRIBUTION = 10 finney;
    uint256 public constant TOKENS_PER_ETHER = 5000 * 10 ** 18;
    uint256 public constant CROWDSALE_DURATION = 30 days;

    /* Public Variables */
    TKRToken public token;
    TKRPToken public preToken;
    address public crowdsaleOwner;
    uint256 public etherReceived;
    uint256 public tokensSent;
    uint256 public crowdsaleStartTime;
    uint256 public crowdsaleEndTime;

    /* Modifier to check whether the crowdsale is running */
    modifier crowdsaleRunning() {
        require(now < crowdsaleEndTime && crowdsaleStartTime != 0);
        _;
    }

    /**
    * @dev Fallback function which invokes the processContribution function
    * @param _tokenAddress TKR Token address
    * @param _to crowdsale owner address
    */
    function Crowdsale(address _tokenAddress, address _preTokenAddress, address _to) {
        token = TKRToken(_tokenAddress);
        preToken = TKRPToken(_preTokenAddress);
        crowdsaleOwner = _to;
    }

    /**
    * @dev Fallback function which invokes the processContribution function
    */
    function() crowdsaleRunning payable {
        processContribution(msg.sender);
    }

    /**
    * @dev Starts the crowdsale
    */
    function start() onlyOwner {
        require(crowdsaleStartTime == 0);

        crowdsaleStartTime = now;            
        crowdsaleEndTime = now + CROWDSALE_DURATION;    
    }

    /**
    * @dev A backup fail-safe drain if required
    */
    function drain() onlyOwner {
        assert(crowdsaleOwner.send(this.balance));
    }

    /**
    * @dev Finalizes the crowdsale and sends funds
    */
    function finalize() onlyOwner {
        require((crowdsaleStartTime != 0 && now > crowdsaleEndTime) || tokensSent == TOKEN_CAP);

        uint256 remainingBalance = token.balanceOf(this);
        if (remainingBalance > 0) token.destroy(remainingBalance);

        assert(crowdsaleOwner.send(this.balance));
    }

    /**
    * @dev Migrates TKRP tokens to TKR token at a rate of 1:1 during the Crowdsale.
    */
    function migrate() crowdsaleRunning {
        uint256 preTokenBalance = preToken.balanceOf(msg.sender);
        require(preTokenBalance != 0);
        uint256 tokenBalance = preTokenBalance * 10 ** 18;

        preToken.destroyFrom(msg.sender);
        token.transfer(msg.sender, tokenBalance);
        MigratedTokens(msg.sender, tokenBalance);
    }

    /**
    * @dev Processes the contribution given, sends the tokens and emits events
    * @param sender The address of the contributor
    */
    function processContribution(address sender) internal {
        require(msg.value >= MINIMUM_CONTRIBUTION);

        // // /* Calculate total (+bonus) amount to send, throw if it exceeds cap*/
        uint256 contributionInTokens = bonus(msg.value.mul(TOKENS_PER_ETHER).div(1 ether));
        require(contributionInTokens.add(tokensSent) <= TOKEN_CAP);

        /* Send the tokens */
        token.transfer(sender, contributionInTokens);

        /* Create a contributor struct and store the contributed/received values */
        Contributor storage contributor = contributors[sender];
        contributor.received = contributor.received.add(contributionInTokens);
        contributor.contributed = contributor.contributed.add(msg.value);

        // /* Update the total amount of tokens sent and ether received */
        etherReceived = etherReceived.add(msg.value);
        tokensSent = tokensSent.add(contributionInTokens);

        // /* Emit log events */
        TokensSent(sender, contributionInTokens);
        ContributionReceived(sender, msg.value);
    }

    /**
    * @dev Calculates the bonus amount based on the contribution date
    * @param amount The contribution amount given
    */
    function bonus(uint256 amount) internal constant returns (uint256) {
        /* This adds a bonus 20% such as 100 + 100/5 = 120 */
        if (now < crowdsaleStartTime.add(2 days)) return amount.add(amount.div(5));

        /* This adds a bonus 10% such as 100 + 100/10 = 110 */
        if (now < crowdsaleStartTime.add(14 days)) return amount.add(amount.div(10));

        /* This adds a bonus 5% such as 100 + 100/20 = 105 */
        if (now < crowdsaleStartTime.add(21 days)) return amount.add(amount.div(20));

        /* No bonus is given */
        return amount;
    }
}