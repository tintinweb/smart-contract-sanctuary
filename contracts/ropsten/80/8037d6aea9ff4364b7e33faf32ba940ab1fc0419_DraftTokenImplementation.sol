/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events.
 * Note that this isn&#39;t required by the specification, and other compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 internal _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
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
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param _from The address to transfer from.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
}


contract Ownable {

    // Owner of the contract
    address public owner;

    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Pausable is Ownable {
    address public pauser;
    bool public paused = false;

    event Pause();
    event Unpause();
    event PauserUpdated(address indexed previousPauser, address indexed newPauser);

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyPauser public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyPauser public {
        paused = false;
        emit Unpause();
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address _newPauser) onlyOwner public {
        require(_newPauser != address(0));
        emit PauserUpdated(pauser, _newPauser);
        pauser = _newPauser;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == pauser);
        _;
    }
}

/**
 * @title Blacklistable Token
 *
 * @dev Allows accounts to be blacklisted by a "blacklister" role/address.
 */
contract Blacklistable is Ownable {

    /** Address allowed to blacklist other account addresses. */
    address public blacklister;

    /** Mapping of account addresses that are blacklisted. */
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterUpdated(address indexed previousBlacklister, address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        require(msg.sender == blacklister);
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false);
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
    */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
    */
    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    /**
     * @dev Update the blacklister account to a new account address.
     * @param _newBlacklister The address of the new blacklister account
     */
    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0));
        emit BlacklisterUpdated(blacklister, _newBlacklister);
        blacklister = _newBlacklister;
    }
}

/**
 * @title DraftTokenImplementation
 *
 * @dev Version 1.0 draft token implementation for board demonstration purposes.
 *
 * @dev This requires further work to:
 *      - Further factor out code
 *      - Add security improvements (more refined roles, mint limits, etc.)
 *      - Separate storage into another contract
 */
contract DraftTokenImplementation is ERC20, Ownable, Pausable, Blacklistable {
    using SafeMath for uint256;

    /** Descriptive attributes, for display purposes. */
    string public name;
    string public symbol;
    uint8 public decimals;

    /** Account address allowed to mint new tokens tokens and burn existing tokens. */
    address public minter;

    /** Events emitted by function calls. */
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterUpdated(address indexed previousMinter, address indexed newMinter);

    event WipedAccount(address indexed blacklister, address indexed account);

    /**
     * Constructor
     */
    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        address _owner,
        address _pauser,
        address _blacklister,
        address _minter
    ) public {
        require(_owner != address(0));
        require(_pauser != address(0));
        require(_blacklister != address(0));
        require(_minter != address(0));

        // Supply is zero until tokens are minted
        _totalSupply = 0;

        // Set descriptive attributes
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        // Set account addresses for administrative roles
        owner = _owner;
        pauser = _pauser;
        blacklister = _blacklister;
        minter = _minter;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from,address _to, uint256 _value) public notBlacklisted(msg.sender) whenNotPaused notBlacklisted(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseAllowance(address _spender, uint _addedValue) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool) {
        return super.increaseAllowance(_spender, _addedValue);
    }

    function decreaseAllowance(address _spender, uint _subtractedValue) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool) {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }

    function mint(address _to, uint256 _value) public whenNotPaused onlyMinter notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        // Add the minted value to the total supply
        _totalSupply = _totalSupply.add(_value);

        // Increase the recipient balance by the minted value
        balances[_to] = balances[_to].add(_value);

        emit Mint(msg.sender, _to, _value);
        emit Transfer(address(0), _to, _value);

        return true;
    }

    function burn(uint256 _value) public whenNotPaused onlyMinter notBlacklisted(msg.sender) returns (bool) {
        require(_value > 0);
        require(balances[msg.sender] >= _value);

        // Subtract the burnt value from the total supply
        _totalSupply = _totalSupply.sub(_value);

        // Decrease the sender balance by the burnt value
        balances[msg.sender] = balances[msg.sender].sub(_value);

        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);

        return true;
    }

    /**
     * @dev update the minter role
     */
    function updateMinter(address _newMinter) public onlyOwner {
        require(_newMinter != address(0));
        emit MinterUpdated(minter, _newMinter);
        minter = _newMinter;
    }

    function wipeBlacklistedAccount(address _account) public whenNotPaused onlyBlacklister notBlacklisted(msg.sender) returns (bool) {
        require(isBlacklisted(_account));
        require(balances[_account] > 0);

        emit Burn(msg.sender, balances[_account]);
        emit Transfer(_account, address(0), balances[_account]);
        emit WipedAccount(msg.sender, _account);
        
        // Subtract the blacklisted account&#39;s balance from the total supply
        _totalSupply = _totalSupply.sub(balances[_account]);

        // Set the blacklisted account&#39;s balance to zero
        balances[_account] = balances[_account].sub(balances[_account]);

        return true;
    }

    /**
     * @dev Throws if called by any account other than the minter.
     * 
     */
    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }
}