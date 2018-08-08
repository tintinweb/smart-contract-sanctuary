pragma solidity 0.4.24;

/**
 * @title ERC20 Interface
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Lockable Token
 * @author info@yggdrash.io
 */
contract Lockable {
    bool public tokenTransfer;
    address public owner;

    /**
     * @dev They can transfer even if tokenTranser flag is false.
     */
    mapping(address => bool) public unlockAddress;

    /**
     * @dev They cannot transfer even if tokenTransfer flag is true.
     */
    mapping(address => bool) public lockAddress;

    event Locked(address lockAddress, bool status);
    event Unlocked(address unlockedAddress, bool status);

    /**
     * @dev check whether can tranfer tokens or not.
     */
    modifier isTokenTransfer {
        if(!tokenTransfer) {
            require(unlockAddress[msg.sender]);
        }
        _;
    }

    /**
     * @dev check whether registered in lockAddress or not
     */
    modifier checkLock {
        require(!lockAddress[msg.sender]);
        _;
    }

    modifier isOwner
    {
        require(owner == msg.sender);
        _;
    }

    constructor()
    public
    {
        tokenTransfer = false;
        owner = msg.sender;
    }

    /**
     * @dev add or remove in lockAddress(blacklist)
     */
    function setLockAddress(address target, bool status)
    external
    isOwner
    {
        require(owner != target);
        lockAddress[target] = status;
        emit Locked(target, status);
    }

    /**
     * @dev add or remove in unlockAddress(whitelist)
     */
    function setUnlockAddress(address target, bool status)
    external
    isOwner
    {
        unlockAddress[target] = status;
        emit Unlocked(target, status);
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
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title YGGDRASH Token Contract.
 * @author info@yggdrash.io
 * @notice This contract is the updated version that fixes the unlocking bug.
 * This source code is audited by external auditors.
 */
contract YeedToken is ERC20, Lockable {

    string public constant name = "YGGDRASH";
    string public constant symbol = "YEED";
    uint8 public constant decimals = 18;

    /**
     * @dev If this flag is true, admin can use enableTokenTranfer(), emergencyTransfer().
     */
    bool public adminMode;

    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _approvals;
    uint256 internal _supply;

    event TokenBurned(address burnAddress, uint256 amountOfTokens);
    event SetTokenTransfer(bool transfer);
    event SetAdminMode(bool adminMode);
    event EmergencyTransfer(address indexed from, address indexed to, uint256 value);

    modifier isAdminMode {
        require(adminMode);
        _;
    }

    constructor(uint256 initial_balance)
    public
    {
        require(initial_balance != 0);
        _supply = initial_balance;
        _balances[msg.sender] = initial_balance;
        emit Transfer(address(0), msg.sender, initial_balance);
    }

    function totalSupply()
    public
    view
    returns (uint256) {
        return _supply;
    }

    function balanceOf(address who)
    public
    view
    returns (uint256) {
        return _balances[who];
    }

    function transfer(address to, uint256 value)
    public
    isTokenTransfer
    checkLock
    returns (bool) {
        require(to != address(0));
        require(_balances[msg.sender] >= value);

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    returns (uint256) {
        return _approvals[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value)
    public
    isTokenTransfer
    checkLock
    returns (bool success) {
        require(!lockAddress[from]);
        require(_balances[from] >= value);
        require(_approvals[from][msg.sender] >= value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
    public
    checkLock
    returns (bool) {
        _approvals[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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
    function increaseApproval(address _spender, uint256 _addedValue)
    public
    checkLock
    returns (bool) {
        _approvals[msg.sender][_spender] = (
        _approvals[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, _approvals[msg.sender][_spender]);
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
    function decreaseApproval(address _spender, uint256 _subtractedValue)
    public
    checkLock
    returns (bool) {
        uint256 oldValue = _approvals[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            _approvals[msg.sender][_spender] = 0;
        } else {
            _approvals[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _approvals[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Burn tokens can only use by owner
     */
    function burnTokens(uint256 tokensAmount)
    public
    isAdminMode
    isOwner
    {
        require(_balances[msg.sender] >= tokensAmount);

        _balances[msg.sender] = _balances[msg.sender].sub(tokensAmount);
        _supply = _supply.sub(tokensAmount);
        emit TokenBurned(msg.sender, tokensAmount);
    }

    /**
     * @dev Set the tokenTransfer flag.
     * If true, 
     * - unregistered lockAddress can transfer()
     * - registered lockAddress can not transfer()
     * If false, 
     * - registered unlockAddress & unregistered lockAddress 
     * - can transfer(), unregistered unlockAddress can not transfer()
     */
    function setTokenTransfer(bool _tokenTransfer)
    external
    isAdminMode
    isOwner
    {
        tokenTransfer = _tokenTransfer;
        emit SetTokenTransfer(tokenTransfer);
    }

    function setAdminMode(bool _adminMode)
    public
    isOwner
    {
        adminMode = _adminMode;
        emit SetAdminMode(adminMode);
    }

    /**
     * @dev In emergency situation, 
     * admin can use emergencyTransfer() for protecting user&#39;s token.
     */
    function emergencyTransfer(address emergencyAddress)
    public
    isAdminMode
    isOwner
    returns (bool success) {
        require(emergencyAddress != owner);
        _balances[owner] = _balances[owner].add(_balances[emergencyAddress]);

        emit Transfer(emergencyAddress, owner, _balances[emergencyAddress]);
        emit EmergencyTransfer(emergencyAddress, owner, _balances[emergencyAddress]);
    
        _balances[emergencyAddress] = 0;
        return true;
    }
}