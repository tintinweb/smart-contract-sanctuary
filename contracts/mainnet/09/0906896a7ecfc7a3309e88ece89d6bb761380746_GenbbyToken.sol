pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        assert(c / a == b);
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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {

    uint256 public totalSupply;

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
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
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
 * @title Standard ERC20 token
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
        }
        else {
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

    bool public paused = false;

    event Pause();
    event Unpause();

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
 * @title Capped Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract CappedMintableToken is PausableToken {

    uint256 public hard_cap;
    // List of agents that are allowed to create new tokens
    mapping (address => bool) mintAgents;

    event MintingAgentChanged(address addr, bool state);
    event Mint(address indexed to, uint256 amount);

    /*
     * @dev Modifier to check if `msg.sender` is an agent allowed to create new tokens
     */
    modifier onlyMintAgent() {
        require(mintAgents[msg.sender]);
        _;
    }

    /**
     * @dev Owner can allow a crowdsale contract to mint new tokens
     */
    function setMintAgent(address addr, bool state) onlyOwner whenNotPaused  public {
        mintAgents[addr] = state;
        MintingAgentChanged(addr, state);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyMintAgent whenNotPaused public returns (bool) {
        require (totalSupply.add(_amount) <= hard_cap);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Gets if an specified address is allowed to mint tokens
     * @param _user The address to query if is allowed to mint tokens
     * @return An bool representing if the address passed is allowed to mint tokens 
     */
    function isMintAgent(address _user) public view returns (bool state) {
        return mintAgents[_user];
    }

}


/**
 * @title Platform Token
 * @dev Contract that allows the Genbby platform to work properly and being scalable
 */
contract PlatformToken is CappedMintableToken {

    mapping (address => bool) trustedContract;

    event TrustedContract(address addr, bool state);

    /**
     * @dev Modifier that check that `msg.sender` is an trusted contract
     */
    modifier onlyTrustedContract() {
        require(trustedContract[msg.sender]);
        _;
    }

    /**
     * @dev The owner can set a contract as a trusted contract
     */
    function setTrustedContract(address addr, bool state) onlyOwner whenNotPaused public {
        trustedContract[addr] = state;
        TrustedContract(addr, state);
    }

    /**
     * @dev Function that trusted contracts can use to perform any buying that users do in the platform
     */
    function buy(address who, uint256 amount) onlyTrustedContract whenNotPaused public {
        require (balances[who] >= amount);
        balances[who] = balances[who].sub(amount);
        totalSupply = totalSupply.sub(amount);
    }

    /**
     * @dev Function to check if a contract is marked as a trusted one
     * @param _contract The address of the contract to query of
     * @return A bool indicanting if the passed contract is considered as a trusted one
     */
    function isATrustedContract(address _contract) public view returns (bool state) {
        return trustedContract[_contract];
    }

}


/**
 * @title UpgradeAgent
 * @dev Interface of a contract that transfers tokens to itself
 * Inspired by Lunyr
 */
contract UpgradeAgent {

    function upgradeBalance(address who, uint256 amount) public;
    function upgradeAllowance(address _owner, address _spender, uint256 amount) public;
    function upgradePendingExchange(address _owner, uint256 amount) public;

}


/**
 * @title UpgradableToken
 * @dev Allows users to transfers their tokens to a new contract when the token is paused and upgrading 
 * It is like a guard for unexpected situations 
 */
contract UpgradableToken is PlatformToken {

    // The next contract where the tokens will be migrated
    UpgradeAgent public upgradeAgent;
    uint256 public totalSupplyUpgraded;
    bool public upgrading = false;

    event UpgradeBalance(address who, uint256 amount);
    event UpgradeAllowance(address owner, address spender, uint256 amount);
    event UpgradePendingExchange(address owner, uint256 value);
    event UpgradeStateChange(bool state);


    /**
     * @dev Modifier to make a function callable only when the contract is upgrading
     */
    modifier whenUpgrading() {
        require(upgrading);
        _;
    }

    /**
     * @dev Function that allows the `owner` to set the upgrade agent
     */
    function setUpgradeAgent(address addr) onlyOwner public {
        upgradeAgent = UpgradeAgent(addr);
    }

    /**
     * @dev called by the owner when token is paused, triggers upgrading state
     */
    function startUpgrading() onlyOwner whenPaused public {
        upgrading = true;
        UpgradeStateChange(true);
    }

    /**
     * @dev called by the owner then token is paused and upgrading, returns to a non-upgrading state
     */
    function stopUpgrading() onlyOwner whenPaused whenUpgrading public {
        upgrading = false;
        UpgradeStateChange(false);
    }

    /**
     * @dev Allows anybody to upgrade tokens from these contract to the new one
     */
    function upgradeBalanceOf(address who) whenUpgrading public {
        uint256 value = balances[who];
        require (value != 0);
        balances[who] = 0;
        totalSupply = totalSupply.sub(value);
        totalSupplyUpgraded = totalSupplyUpgraded.add(value);
        upgradeAgent.upgradeBalance(who, value);
        UpgradeBalance(who, value);
    }

    /**
     * @dev Allows anybody to upgrade allowances from these contract to the new one
     */
    function upgradeAllowance(address _owner, address _spender) whenUpgrading public {
        uint256 value = allowed[_owner][_spender];
        require (value != 0);
        allowed[_owner][_spender] = 0;
        upgradeAgent.upgradeAllowance(_owner, _spender, value);
        UpgradeAllowance(_owner, _spender, value);
    }

}

/**
 * @title Genbby Token
 * @dev Token setting
 */
contract GenbbyToken is UpgradableToken {

    string public contactInformation;
    string public name = "Genbby Token";
    string public symbol = "GG";
    uint256 public constant decimals = 18;
    uint256 public constant factor = 10 ** decimals;

    event UpgradeTokenInformation(string newName, string newSymbol);

    function GenbbyToken() public {
        hard_cap = (10 ** 9) * factor;
        contactInformation = &#39;https://genbby.com/&#39;;
    }

    function setTokenInformation(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
        UpgradeTokenInformation(name, symbol);
    }

    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
    }

    /*
     * @dev Do not allow direct deposits
     */
    function () public payable {
        revert();
    }

}