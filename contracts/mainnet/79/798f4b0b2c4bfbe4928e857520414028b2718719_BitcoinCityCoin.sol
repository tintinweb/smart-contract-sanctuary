pragma solidity ^0.4.17;

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
    function Ownable()public {
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
    function transferOwnership(address newOwner)public onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }
}

/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* @dev https://github.com/ethereum/EIPs/issues/179
*/
contract ERC20Basic is Ownable {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value)public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
* @title ERC20 interface
* @dev https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value)public returns(bool);
    function approve(address spender, uint256 value)public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;

    /**
    * @dev Transfers tokens to a specified address.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    */
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
    
    /**
    * @dev Transfers tokens from one address to another.
    * @param _from The address which you want to send tokens from.
    * @param _to The address which you want to transfer to.
    * @param _value The amount of tokens to be transfered.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_value <= allowed[_from][msg.sender]);
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    /**
    * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value > 0)&&(_value <= balances[msg.sender]));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner The address which owns the funds.
    * @param _spender The address which will spend the funds.
    */
    function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Mintable token
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
    
    event Mint(address indexed to, uint256 amount);
    
    event MintFinished();

    bool public mintingFinished = false;
    
    /**
    * @dev Throws if called when minting is finished.
    */
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    /**
    * @dev Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }
    
    /**
    * @dev Function to stop minting new tokens.
    */
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is MintableToken {
    
    using SafeMath for uint;
    
    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint _value) public returns (bool success) {
        require((_value > 0) && (_value <= balances[msg.sender]));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        return true;
    }
 
    /**
    * @dev Burns a specific amount of tokens from another address.
    * @param _value The amount of tokens to be burned.
    * @param _from The address which you want to burn tokens from.
    */
    function burnFrom(address _from, uint _value) public returns (bool success) {
        require((balances[_from] > _value) && (_value <= allowed[_from][msg.sender]));
        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Burn(_from, _value);
        return true;
    }

    event Burn(address indexed burner, uint indexed value);
}

/**
 * @title SimpleTokenCoin
 * @dev SimpleToken is a standard ERC20 token with some additional functionality
 */
contract BitcoinCityCoin is BurnableToken {
    
    string public constant name = "Bitcoin City";
    
    string public constant symbol = "BCKEY";
    
    uint32 public constant decimals = 8;
    
    address private contractAddress;
    
    
    /**
    * @dev The SimpleTokenCoin constructor mints tokens to four addresses.
    */
    function BitcoinCityCoin()public {
       balances[0xb2DeC9309Ca7047a6257fC83a95fcFc23Ab821DC] = 500000000 * 10**decimals;
    }
    
    
     /**
    * @dev Sets the address of approveAndCall contract.
    * @param _address The address of approveAndCall contract.
    */
    function setContractAddress (address _address) public onlyOwner {
        contractAddress = _address;
    }
    
    /**
     * @dev Token owner can approve for spender to execute another function.
     * @param tokens Amount of tokens to execute function.
     * @param data Additional data.
     */
    function approveAndCall(uint tokens, bytes data) public returns (bool success) {
        approve(contractAddress, tokens);
        ApproveAndCallFallBack(contractAddress).receiveApproval(msg.sender, tokens, data);
        return true;
    }
}

interface ApproveAndCallFallBack { function receiveApproval(address from, uint256 tokens, bytes data) external; }