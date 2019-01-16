pragma solidity 0.4.25;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


/*
 * @title Manageable
 * @dev The Manageable contract has an manager addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Manageable is Ownable {
    mapping(address => bool) public listOfManagers;

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);

    modifier onlyManager() {
        require(listOfManagers[msg.sender]);
        _;
    }

    function addManager(address _manager) public onlyOwner returns (bool success) {
        require(_manager != address(0));
        require(!listOfManagers[_manager]);

        listOfManagers[_manager] = true;
        emit ManagerAdded(_manager);

        return true;
    }

    function removeManager(address _manager) public onlyOwner returns (bool) {
        require(listOfManagers[_manager]);

        listOfManagers[_manager] = false;
        emit ManagerRemoved(_manager);

        return true;
    }
}


/*
 * @title Freezable
 * @dev The Freezable contract allows managers to freeze entire balance on accounts.
 */
contract Freezable is Manageable {
    mapping(address => bool) public freeze;

    event AccountFrozen(address account);
    event AccountUnfrozen(address account);

    modifier whenNotFrozen() {
        require(!freeze[msg.sender]);
        _;
    }

    function freezeAccount(address _account) public onlyManager returns (bool) {
        require(!freeze[_account]);

        freeze[_account] = true;
        emit AccountFrozen(_account);

        return true;
    }

    function freezeAccounts(address[] _accounts) public onlyManager returns (bool) {

        for (uint i = 0; i < _accounts.length; i++) {
            if (!freeze[_accounts[i]]) {
                freeze[_accounts[i]] = true;
                emit AccountFrozen(_accounts[i]);
            }
        }

        return true;
    }

    function unfreezeAccount (address _account) public onlyManager returns (bool) {
        require(freeze[_account]);

        freeze[_account] = false;
        emit AccountUnfrozen(_account);

        return true;
    }



    function unfreezeAccounts(address[] _accounts) public onlyManager returns (bool) {

        for (uint i = 0; i < _accounts.length; i++) {
            if (freeze[_accounts[i]]) {
                freeze[_accounts[i]] = false;
                emit AccountUnfrozen(_accounts[i]);
            }
        }

        return true;
    }
}


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address who, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed who, address indexed spender, uint256 value);
}


contract Hearts is ERC20, Freezable {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

    uint256 totalSupply_;

    string public name = hex"E29DA4";
    string public symbol = hex"E29DA4";
    uint8 public decimals = 18;

    constructor() public { }

    /**
     * @dev Function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param _account The account that will receive the created tokens.
     * @param _amount The amount that will be created.
     */
    function mint(address _account, uint256 _amount) external onlyManager {
        require(_account != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Function that mints an amount of the token and assigns it to
     * an accounts. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param _accounts The accounts that will receive the created tokens.
     * @param _amounts The amounts that will be created.
     */
    function multiMint(address[] _accounts, uint256[] _amounts) external onlyManager {
        require(_accounts.length > 0);
        for (uint i = 0; i < _accounts.length; i++) {
            totalSupply_ = totalSupply_.add(_amounts[i]);
            balances[_accounts[i]] = balances[_accounts[i]].add(_amounts[i]);
            emit Transfer(address(0), _accounts[i], _amounts[i]);
        }
    }

    /**
     * @dev Reclaim all ERC20Basic compatible tokens
     * @param token ERC20B The address of the token contract
     */
    function reclaimToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _who The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotFrozen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotFrozen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

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
    function approve(address _spender, uint256 _value) public whenNotFrozen returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _who address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _who, address _spender) public view returns (uint256) {
        return allowed[_who][_spender];
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
    function increaseApproval(address _spender, uint _addedValue) public whenNotFrozen returns (bool) {
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
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotFrozen returns (bool) {
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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
}