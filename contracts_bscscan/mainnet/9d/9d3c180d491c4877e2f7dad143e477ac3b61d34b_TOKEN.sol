/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity 0.5.11;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ERC20Basic
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
contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf(msg.sender));

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
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf(_from) >= _value);
        require(balances[_to].add(_value) > balances[_to]); // Check for overflows
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
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

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until 
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is StandardToken {
    event Pause();
    event Unpause();

    bool public paused = false;

    address public founder;
    
    /**
    * @dev modifier to allow actions only when the contract IS paused
    */
    modifier whenNotPaused() {
        require(!paused || msg.sender == founder);
        _;
    }

    /**
    * @dev modifier to allow actions only when the contract IS NOT paused
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


contract PausableToken is Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    //The functions below surve no real purpose. Even if one were to approve another to spend
    //tokens on their behalf, those tokens will still only be transferable when the token contract
    //is not paused.

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

contract TOKEN is PausableToken {

    string public name;
    string public symbol;
    uint8 public decimals;

    /**
    * @dev Constructor that gives the founder all of the existing tokens.
    */
    constructor() public {
        name = "WASMCOIN";
        symbol = "WASM";
        decimals = 14;
        totalSupply = 1200000000000000000000000;
        founder = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    /** @dev Fires on every freeze of tokens
     *  @param _owner address The owner address of frozen tokens.
     *  @param amount uint256 The amount of tokens frozen
     */
    event TokenFreezeEvent(address indexed _owner, uint256 amount);

    /** @dev Fires on every unfreeze of tokens
     *  @param _owner address The owner address of unfrozen tokens.
     *  @param amount uint256 The amount of tokens unfrozen
     */
    event TokenUnfreezeEvent(address indexed _owner, uint256 amount);
    event TokensBurned(address indexed _owner, uint256 _tokens);

    
    mapping(address => uint256) internal frozenTokenBalances;

    function freezeTokens(address _owner, uint256 _value) public onlyOwner {
        require(_value <= balanceOf(_owner));
        uint256 oldFrozenBalance = getFrozenBalance(_owner);
        uint256 newFrozenBalance = oldFrozenBalance.add(_value);
        setFrozenBalance(_owner,newFrozenBalance);
        emit TokenFreezeEvent(_owner,_value);
    }
    
    function unfreezeTokens(address _owner, uint256 _value) public onlyOwner {
        require(_value <= getFrozenBalance(_owner));
        uint256 oldFrozenBalance = getFrozenBalance(_owner);
        uint256 newFrozenBalance = oldFrozenBalance.sub(_value);
        setFrozenBalance(_owner,newFrozenBalance);
        emit TokenUnfreezeEvent(_owner,_value);
    }
    
    
    function setFrozenBalance(address _owner, uint256 _newValue) internal {
        frozenTokenBalances[_owner]=_newValue;
    }

    function balanceOf(address _owner) view public returns(uint256)  {
        return getTotalBalance(_owner).sub(getFrozenBalance(_owner));
    }

    function getTotalBalance(address _owner) view public returns(uint256) {
        return balances[_owner];   
    }
    /**
     * @dev Gets the amount of tokens which belong to the specified address BUT are frozen now.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount of frozen tokens owned by the passed address.
    */

    function getFrozenBalance(address _owner) view public returns(uint256) {
        return frozenTokenBalances[_owner];   
    }
    
    /*
    * @dev Token burn function
    * @param _tokens uint256 amount of tokens to burn
    */
    function burnTokens(uint256 _tokens) public onlyOwner {
        require(balanceOf(msg.sender) >= _tokens);
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        emit TokensBurned(msg.sender, _tokens);
    }
}