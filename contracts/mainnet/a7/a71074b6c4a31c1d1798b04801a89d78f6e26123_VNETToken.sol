pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);


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
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Rescue compatible ERC20Basic Token
     *
     * @param _token ERC20Basic The address of the token contract
     */
    function rescueTokens(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        assert(_token.transfer(owner, balance));
    }

    /**
     * @dev Withdraw Ether
     */
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
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
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


/**
 * @title Basic token, Lockable
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => uint256) lockedBalanceMap;    // locked balance: address => amount
    mapping(address => uint256) releaseTimeMap;      // release time: address => timestamp

    event BalanceLocked(address indexed _addr, uint256 _amount);


    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev function to make sure the balance is not locked
     * @param _addr address
     * @param _value uint256
     */
    function checkNotLocked(address _addr, uint256 _value) internal view returns (bool) {
        uint256 balance = balances[_addr].sub(_value);
        if (releaseTimeMap[_addr] > block.timestamp && balance < lockedBalanceMap[_addr]) {
            revert();
        }
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        checkNotLocked(msg.sender, _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return Amount.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Gets the locked balance of the specified address.
     * @param _owner The address to query.
     * @return Amount.
     */
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        return lockedBalanceMap[_owner];
    }

    /**
     * @dev Gets the release timestamp of the specified address if it has a locked balance.
     * @param _owner The address to query.
     * @return Timestamp.
     */
    function releaseTimeOf(address _owner) public view returns (uint256) {
        return releaseTimeMap[_owner];
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
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

        checkNotLocked(_from, _value);

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
 * @title Abstract Standard ERC20 token
 */
contract AbstractToken is Ownable, StandardToken {
    string public name;
    string public symbol;
    uint256 public decimals;

    string public value;        // Stable Value
    string public description;  // Description
    string public website;      // Website
    string public email;        // Email
    string public news;         // Latest News
    uint256 public cap;         // Cap Limit


    mapping (address => bool) public mintAgents;  // Mint Agents

    event Mint(address indexed _to, uint256 _amount);
    event MintAgentChanged(address _addr, bool _state);
    event NewsPublished(string _news);


    /**
     * @dev Set Info
     * 
     * @param _description string
     * @param _website string
     * @param _email string
     */
    function setInfo(string _description, string _website, string _email) external onlyOwner returns (bool) {
        description = _description;
        website = _website;
        email = _email;
        return true;
    }

    /**
     * @dev Set News
     * 
     * @param _news string
     */
    function setNews(string _news) external onlyOwner returns (bool) {
        news = _news;
        emit NewsPublished(_news);
        return true;
    }

    /**
     * @dev Set a mint agent address
     * 
     * @param _addr  address  The address that will receive the minted tokens.
     * @param _state bool     The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function setMintAgent(address _addr, bool _state) onlyOwner public returns (bool) {
        mintAgents[_addr] = _state;
        emit MintAgentChanged(_addr, _state);
        return true;
    }

    /**
     * @dev Constructor
     */
    constructor() public {
        setMintAgent(msg.sender, true);
    }
}


/**
 * @dev VNET Token for Vision Network Project
 */
contract VNETToken is Ownable, AbstractToken {
    event Donate(address indexed _from, uint256 _amount);


    /**
     * @dev Constructor
     */
    constructor() public {
        name = "VNET Token";
        symbol = "VNET";
        decimals = 6;
        value = "1 Token = 100 GByte client newtwork traffic flow";

        // 35 Billion Total
        cap = 35000000000 * (10 ** decimals);
    }

    /**
     * @dev Sending eth to this contract will be considered as a donation
     */
    function () public payable {
        emit Donate(msg.sender, msg.value);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) external returns (bool) {
        require(mintAgents[msg.sender] && totalSupply_.add(_amount) <= cap);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to mint tokens, and lock some of them with a release time
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @param _lockedAmount The amount of tokens to be locked.
     * @param _releaseTime The timestamp about to release, which could be set just once.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithLock(address _to, uint256 _amount, uint256 _lockedAmount, uint256 _releaseTime) external returns (bool) {
        require(mintAgents[msg.sender] && totalSupply_.add(_amount) <= cap);
        require(_amount >= _lockedAmount);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        lockedBalanceMap[_to] = lockedBalanceMap[_to] > 0 ? lockedBalanceMap[_to].add(_lockedAmount) : _lockedAmount;
        releaseTimeMap[_to] = releaseTimeMap[_to] > 0 ? releaseTimeMap[_to] : _releaseTime;
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        emit BalanceLocked(_to, _lockedAmount);
        return true;
    }
}