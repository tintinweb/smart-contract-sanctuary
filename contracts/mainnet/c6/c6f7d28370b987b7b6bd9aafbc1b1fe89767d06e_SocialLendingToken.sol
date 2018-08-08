pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

/*
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /*
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

    /*
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /*
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/*
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

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
 * @title ERC223 interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 is ERC20 {
    function transfer(address to, uint value, bytes data) public returns (bool ok);

    function transferFrom(address from, address to, uint value, bytes data) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) allowed;


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
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * @title Standard ERC223 token
 */
contract Standard223Token is ERC223, StandardToken {
    //function that is called when a user or another contract wants to transfer funds
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        //filtering if the target is a contract with bytecode inside it
        require(super.transfer(_to, _value));
        // do a normal token transfer
        if (isContract(_to)) return contractFallback(msg.sender, _to, _value, _data);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool success) {
        require(super.transferFrom(_from, _to, _value));
        // do a normal token transfer
        if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
        return true;
    }

    //function that is called when transaction target is a contract
    function contractFallback(address _from, address _to, uint _value, bytes _data) private returns (bool success) {
        ERC223Receiver receiver = ERC223Receiver(_to);
        return receiver.tokenFallback(_from, _value, _data);
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) internal view returns (bool is_contract) {
        // retrieve the size of the code on target address, this needs assembly
        uint length;
        assembly {length := extcodesize(_addr)}
        return length > 0;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is Standard223Token, Ownable {
    event Mint(address indexed to, uint256 amount);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        require(!isContract(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
}

/**
 * @title Frozen token
 * @dev Simple ERC20 Token example, with freeze token of one account
 */
contract FrozenToken is Ownable {
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    modifier requireNotFrozen(address from){
        require(!frozenAccount[from]);
        _;
    }
}


contract ERC223Receiver {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool ok);
}



/**
 * ERC20 token
 * SLT
 */
contract SocialLendingToken is Pausable, BurnableToken, MintableToken, FrozenToken {

    string public name;
    string public symbol;
    uint public decimals;


    function SocialLendingToken(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        totalSupply_ = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[msg.sender] = _initialSupply;
        Transfer(0x0, msg.sender, _initialSupply);
    }

    function transfer(address _to, uint _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_to) returns (bool) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_from) requireNotFrozen(_to) returns (bool) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    function approve(address _spender, uint _value) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_spender) returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    ////ERC223
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_to) returns (bool success) {
        return super.transfer(_to, _value, _data);
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public whenNotPaused requireNotFrozen(msg.sender) requireNotFrozen(_from) requireNotFrozen(_to) returns (bool success) {
        return super.transferFrom(_from, _to, _value, _data);
    }

    event Airdrop(address indexed from, uint addressCount, uint totalAmount);
    event AirdropDiff(address indexed from, uint addressCount, uint totalAmount);
    
    /**
     * @dev airdrop token to address list, each address distributes the same number of token
     *
     * @param _addresses address list to distributes
     * @param _value Amount of tokens.
     */
    function airdrop(uint _value,address[] _addresses) public whenNotPaused onlyOwner returns (bool success){
        uint addressCount = _addresses.length;
        require(addressCount > 0 && addressCount <= 1000);
        uint totalAmount = _value.mul(addressCount);
        require(_value > 0 && balances[msg.sender] >= totalAmount);

        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        for(uint i=0; i<addressCount; i++){
            require(_addresses[i] != address(0));
            balances[_addresses[i]] = balances[_addresses[i]].add(_value);
            Transfer(msg.sender, _addresses[i], _value);
        }
        Airdrop(msg.sender,addressCount,totalAmount);
        return true;
    }
    
    function airdropDiff(uint[] _values,address[] _addresses) public whenNotPaused onlyOwner returns (bool success){
        uint addressCount = _addresses.length;

        require(addressCount == _values.length);
        require(addressCount > 0 && addressCount <= 1000);

        uint totalAmount = 0;
        for(uint i=0; i<addressCount; i++){
            require(_values[i] > 0 );
            totalAmount = totalAmount.add(_values[i]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        for(uint j=0; j<addressCount; j++){
            require(_addresses[j] != address(0));
            balances[_addresses[j]] = balances[_addresses[j]].add(_values[j]);
            Transfer(msg.sender, _addresses[j], _values[j]);
        }
        AirdropDiff(msg.sender,addressCount,totalAmount);
        return true;
    }
}