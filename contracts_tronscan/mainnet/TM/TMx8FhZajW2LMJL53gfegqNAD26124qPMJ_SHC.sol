//SourceUnit: SHC.sol

pragma solidity ^0.5.8;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable
{
    bool private stopped;
    
    address public _owner;
    address public _admin;
    address private proposedOwner;
    mapping(address => bool) private _allowed;

    event Stopped();
    event Started();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Allowed(address indexed _address);
    event RemoveAllowed(address indexed _address);

    constructor () internal
    {
        stopped = false;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address)
    {
        return _owner;
    }

    modifier onlyOwner()
    {
        require(isOwner());
        _;
    }

    modifier onlyAllowed()
    {
        require(isAllowed() || isOwner());
        _;
    }

    modifier onlyWhenNotStopped()
    {
        require(!isStopped());
        _;
    }

    function isOwner() public view returns (bool)
    {
        return msg.sender == _owner;
    }

    function isAllowed() public view returns (bool)
    {
        return _allowed[msg.sender];
    }

    function allow(address _target) external onlyOwner returns (bool)
    {
        _allowed[_target] = true;
        emit Allowed(_target);
        return true;
    }

    function removeAllowed(address _target) external onlyOwner returns (bool)
    {
        _allowed[_target] = false;
        emit RemoveAllowed(_target);
        return true;
    }

    function isStopped() public view returns (bool)
    {
        if(isOwner() || isAllowed())
        {
            return false;
        }
        else
        {
            return stopped;
        }
    }

    function stop() public onlyOwner
    {
        _stop();
    }

    function start() public onlyOwner
    {
        _start();
    }

    function proposeOwner(address _proposedOwner) public onlyOwner
    {
        require(msg.sender != _proposedOwner);
        proposedOwner = _proposedOwner;
    }

    function claimOwnership() public
    {
        require(msg.sender == proposedOwner);

        emit OwnershipTransferred(_owner, proposedOwner);

        _owner = proposedOwner;
        proposedOwner = address(0);
    }

    function _stop() internal
    {
        emit Stopped();
        stopped = true;
    }

    function _start() internal
    {
        emit Started();
        stopped = false;
    }
}

contract BaseToken is Ownable
{
    using SafeMath for uint256;
    uint256 constant public decimals = 8;
    uint256 public totalSupply;

    struct Lock {
        uint256 amount;
        uint256 expiresAt;
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping ( address => uint256 )) public approvals;
    mapping (address => Lock[]) public lockup;
    mapping(address => bool) public lockedAddresses;

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Locked(address _who,uint256 _index);
    event UnlockedAll(address _who);
    event UnlockedIndex(address _who, uint256 _index);
    
    event Burn(address indexed from, uint256 indexed value);
    
    constructor() public
    {
        balances[msg.sender] = totalSupply;
    }

    modifier transferParamsValidation(address _from, address _to, uint256 _value)
    {
        require(_from != address(0));
        require(_to != address(0));
        require(_value > 0);
        require(balances[_from] >= _value);
        require(!isLocked(_from, _value));
        _;
    }
    
    modifier canTransfer(address _sender, uint256 _value) {
    require(!lockedAddresses[_sender]);
    require(_sender != address(0));
    

    _;
    }

    function balanceOf(address _who) view public returns (uint256)
    {
        return balances[_who];
    }

    function lockedBalanceOf(address _who) view public returns (uint256)
    {
        require(_who != address(0));

        uint256 lockedBalance = 0;
        if(lockup[_who].length > 0)
        {
            Lock[] storage locks = lockup[_who];

            uint256 length = locks.length;
            for (uint i = 0; i < length; i++)
            {
                if (now < locks[i].expiresAt)
                {
                    lockedBalance = lockedBalance.add(locks[i].amount);
                }
            }
        }

        return lockedBalance;
    }

    function allowance(address _owner, address _spender) view external returns (uint256)
    {
        return approvals[_owner][_spender];
    }

    function isLocked(address _who, uint256 _value) view public returns(bool)
    {
        uint256 lockedBalance = lockedBalanceOf(_who);
        uint256 balance = balanceOf(_who);

        if(lockedBalance <= 0)
        {
            return false;
        }
        else
        {
            return !(balance > lockedBalance && balance.sub(lockedBalance) >= _value);
        }
    }

    function transfer(address _to, uint256 _value) external onlyWhenNotStopped canTransfer(msg.sender, _value) transferParamsValidation(msg.sender, _to, _value) returns (bool)
    {
        
        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external onlyWhenNotStopped transferParamsValidation(_from, _to, _value) returns (bool)
    {
        require(approvals[_from][msg.sender] >= _value);

        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);

        _transfer(_from, _to, _value);

        return true;
    }
    
    // transferWithLock is only for airdrop or marketing purpose

    function transferWithLock(address _to, uint256 _value, uint256 _time) onlyOwner transferParamsValidation(msg.sender, _to, _value) external returns (bool)
    {
        require(_time > now);

        _lock(_to, _value, _time);
        _transfer(msg.sender, _to, _value);

        return true;
    }
    
    function addtokenLock(address _to, uint256 _value, uint256 _time) onlyOwner transferParamsValidation(msg.sender, _to, _value) external returns (bool)
    {
        require(_time > now);

        _lock(_to, _value, _time);


        return true;
    }
    
    // lockAddress is only for security accident prevention
    
    function lockAddress(address _addr, bool _locked) onlyOwner external
    {
        lockedAddresses[_addr] = _locked;
    }

    // approve is for transfer authentication
    function approve(address _spender, uint256 _value) external onlyWhenNotStopped returns (bool)
    {
        require(_spender != address(0));
        require(balances[msg.sender] >= _value);
        require(msg.sender != _spender);

        approvals[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    
    function unlock(address _who, uint256 _index) onlyOwner external returns (bool)
    {
        uint256 length = lockup[_who].length;
        require(length > _index);

        lockup[_who][_index] = lockup[_who][length - 1];
        lockup[_who].length--;

        emit UnlockedIndex(_who, _index);

        return true;
    }

    function unlockAll(address _who) onlyOwner external returns (bool)
    {
        require(lockup[_who].length > 0);

        delete lockup[_who];
        emit UnlockedAll(_who);

        return true;
    }
    
    // burn is for incubator fund or security accident prevention

    function burn(uint256 _value) external
    {
        require(balances[msg.sender] >= _value);
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);

        totalSupply = totalSupply.sub(_value);

        emit Burn(msg.sender, _value);
    }
    
    

    function _mint(address account, uint256 _value) internal 
    {
        require(account != address(0));

        totalSupply = totalSupply.add(_value);
        balances[account] = balances[account].add(_value);
        emit Transfer(address(0), account, _value);
    }

   
    function _transfer(address _from, address _to, uint256 _value) internal
    {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        
        emit Transfer(_from, _to, _value);
    }

    function _lock(address _who, uint256 _value, uint256 _dateTime) onlyOwner internal
    {
        lockup[_who].push(Lock(_value, _dateTime));

        emit Locked(_who, lockup[_who].length - 1);
    }

    // destruction is for token upgrade
    function destruction() onlyOwner public
    {
        selfdestruct(msg.sender);
    }
    
    
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title TRC20Mintable
 * @dev TRC20 minting logic
 */
contract TRC20Mintable is BaseToken, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
     
    
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}


contract SHC is BaseToken, TRC20Mintable
{
    using SafeMath for uint256;

    string constant public name    = 'SHC';
    string constant public symbol  = 'SHC';
    string constant public version = '1.0.0';


    constructor() public
    {
        totalSupply = 200000000000000000;
        balances[msg.sender] = totalSupply;
    }

}