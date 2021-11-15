pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // require(_b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = _a / _b;
        // require(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

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

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* https://github.com/ethereum/EIPs/issues/20
* Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


/**
* @title Pausable token
* @dev StandardToken modified with pausable transfers.
**/
contract PausableERC20Token is StandardToken, Pausable {

    function transfer(
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        whenNotPaused
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        whenNotPaused
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


/**
* @title Burnable Pausable Token
* @dev Pausable Token that can be irreversibly burned (destroyed).
*/
contract BurnablePausableERC20Token is PausableERC20Token {

    mapping (address => mapping (address => uint256)) internal allowedBurn;

    event Burn(address indexed burner, uint256 value);

    event ApprovalBurn(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function allowanceBurn(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowedBurn[_owner][_spender];
    }

    function approveBurn(address _spender, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        allowedBurn[msg.sender][_spender] = _value;
        emit ApprovalBurn(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(
        uint256 _value
    ) 
        public
        whenNotPaused
    {
        _burn(msg.sender, _value);
    }

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _value uint256 The amount of token to be burned
    */
    function burnFrom(
        address _from, 
        uint256 _value
    ) 
        public 
        whenNotPaused
    {
        require(_value <= allowedBurn[_from][msg.sender]);
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        allowedBurn[_from][msg.sender] = allowedBurn[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

    function _burn(
        address _who, 
        uint256 _value
    ) 
        internal 
        whenNotPaused
    {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function increaseBurnApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        whenNotPaused
        returns (bool)
    {
        allowedBurn[msg.sender][_spender] = (
        allowedBurn[msg.sender][_spender].add(_addedValue));
        emit ApprovalBurn(msg.sender, _spender, allowedBurn[msg.sender][_spender]);
        return true;
    }

    function decreaseBurnApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        whenNotPaused
        returns (bool)
    {
        uint256 oldValue = allowedBurn[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowedBurn[msg.sender][_spender] = 0;
        } else {
            allowedBurn[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit ApprovalBurn(msg.sender, _spender, allowedBurn[msg.sender][_spender]);
        return true;
    }
}

contract FreezableBurnablePausableERC20Token is BurnablePausableERC20Token {
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function freezeAccount(
        address target,
        bool freeze
    )
        public
        onlyOwner
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function transfer(
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(!frozenAccount[msg.sender], "Sender account freezed");
        require(!frozenAccount[_to], "Receiver account freezed");

        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(!frozenAccount[msg.sender], "Spender account freezed");
        require(!frozenAccount[_from], "Sender account freezed");
        require(!frozenAccount[_to], "Receiver account freezed");

        return super.transferFrom(_from, _to, _value);
    }

    function burn(
        uint256 _value
    ) 
        public
        whenNotPaused
    {
        require(!frozenAccount[msg.sender], "Sender account freezed");

        return super.burn(_value);
    }

    function burnFrom(
        address _from, 
        uint256 _value
    ) 
        public 
        whenNotPaused
    {
        require(!frozenAccount[msg.sender], "Spender account freezed");
        require(!frozenAccount[_from], "Sender account freezed");

        return super.burnFrom(_from, _value);
    }
}

/**
* @title MAX
* @dev Token that is ERC20 compatible, Pausableb, Burnable, Ownable with SafeMath.
*/
contract TeaCoin is FreezableBurnablePausableERC20Token {

    /** Token Setting: You are free to change any of these
    * @param name string The name of your token (can be not unique)
    * @param symbol string The symbol of your token (can be not unique, can be more than three characters)
    * @param decimals uint8 The accuracy decimals of your token (conventionally be 18)
    * Read this to choose decimals: https://ethereum.stackexchange.com/questions/38704/why-most-erc-20-tokens-have-18-decimals
    * @param INITIAL_SUPPLY uint256 The total supply of your token. Example default to be "10000". Change as you wish.
    **/
    string public constant name = "雲普發普洱生茶21191";
    string public constant symbol = "TEA21191";
    uint8 public constant decimals = 0;

    uint256 public constant INITIAL_SUPPLY = 100 * (10 ** uint256(decimals));
    string public constant tokenURI = "ipfs://bafkreifo6agvnjahdariznbxxqdhgabs5duvlgbgzhg6fjg5vbr7f3rghe";

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    * Literally put all the issued money in your pocket
    */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
}

