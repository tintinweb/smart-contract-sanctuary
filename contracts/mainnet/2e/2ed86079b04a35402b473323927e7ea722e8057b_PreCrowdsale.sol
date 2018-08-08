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
        if (msg.sender != owner) {
            throw;
        }
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
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

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
        if (balance == 0) throw;

        balances[_from] = 0;
        totalSupply = totalSupply.sub(balance);

        Destroy(_from);
    }
}

/**
 * @title PreCrowdsale
 * @dev Smart contract which collects ETH and in return transfers the TKRPToken to the contributors
 * Log events are emitted for each transaction 
 */
contract PreCrowdsale is Ownable {
    using SafeMath for uint256;

    /* Constants */
    uint256 public constant TOKEN_CAP = 500000;
    uint256 public constant MINIMUM_CONTRIBUTION = 10 finney;
    uint256 public constant TOKENS_PER_ETHER = 10000;
    uint256 public constant PRE_CROWDSALE_DURATION = 5 days;

    /* Public Variables */
    TKRPToken public token;
    address public preCrowdsaleOwner;
    uint256 public tokensSent;
    uint256 public preCrowdsaleStartTime;
    uint256 public preCrowdsaleEndTime;
    bool public crowdSaleIsRunning = false;

    /**
    * @dev Fallback function which invokes the processContribution function
    * @param _tokenAddress TKRP Token address
    * @param _to preCrowdsale owner address
    */
    function PreCrowdsale(address _tokenAddress, address _to) {
        token = TKRPToken(_tokenAddress);
        preCrowdsaleOwner = _to;
    }

    /**
    * @dev Fallback function which invokes the processContribution function
    */
    function() payable {
        if (!crowdSaleIsRunning) throw;
        if (msg.value < MINIMUM_CONTRIBUTION) throw;

        uint256 contributionInTokens = msg.value.mul(TOKENS_PER_ETHER).div(1 ether);
        if (contributionInTokens.add(tokensSent) > TOKEN_CAP) throw; 

        /* Send the tokens */
        token.transfer(msg.sender, contributionInTokens);
        tokensSent = tokensSent.add(contributionInTokens);
    }

    /**
    * @dev Starts the preCrowdsale
    */
    function start() onlyOwner {
        if (preCrowdsaleStartTime != 0) throw;

        crowdSaleIsRunning = true;
        preCrowdsaleStartTime = now;            
        preCrowdsaleEndTime = now + PRE_CROWDSALE_DURATION;    
    }

    /**
    * @dev A backup fail-safe drain if required
    */
    function drain() onlyOwner {
        if (!preCrowdsaleOwner.send(this.balance)) throw;
    }

    /**
    * @dev Finalizes the preCrowdsale and sends funds
    */
    function finalize() onlyOwner {
        if ((preCrowdsaleStartTime == 0 || now < preCrowdsaleEndTime) && tokensSent != TOKEN_CAP) {
            throw;
        }

        if (!preCrowdsaleOwner.send(this.balance)) throw;
        crowdSaleIsRunning = false;
    }
}