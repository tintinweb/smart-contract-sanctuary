pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

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

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

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

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20Basic;

    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.safeTransfer(owner, balance);
    }
}

contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);


        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = true;
    }

    function remove(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = false;
    }

    function check(Role storage role, address addr)
    view
    internal
    {
        require(has(role, addr));
    }

    function has(Role storage role, address addr)
    view
    internal
    returns (bool)
    {
        return role.bearer[addr];
    }
}

contract RBAC {
    using Roles for Roles.Role;
    mapping (string => Roles.Role) private roles;
    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

    function checkRole(address _operator, string _role)
    view
    public
    {
        roles[_role].check(_operator);
    }

    function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
    {
        return roles[_role].has(_operator);
    }

    function addRole(address _operator, string _role)
    internal
    {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

    function removeRole(address _operator, string _role)
    internal
    {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

    modifier onlyRole(string _role)
    {
        checkRole(msg.sender, _role);
        _;
    }
}

contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";

    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

    function addAddressToWhitelist(address _operator)
    onlyOwner
    public
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    function whitelist(address _operator)
    public
    view
    returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

    function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }
}

contract DateKernel
{
    uint256 public unlockTime;
    constructor(uint256 _time) public {
        unlockTime = _time;
    }

    function determineDate() internal view
    returns (uint256 v)
    {
        uint256 n = now;
        uint256 ut = unlockTime;
        uint256 mo = 30 * 1 days;
        uint8 p = 10;
        assembly {
            if sgt(n, ut) {
                if or(slt(sub(n, ut), mo), eq(sub(n, ut), mo)) {
                    v := 1
                }
                if sgt(sub(n, ut), mo) {
                    v := add(div(sub(n, ut), mo), 1)
                }
                if or(eq(v, p), sgt(v, p)) {
                    v := p
                }
            }
        }
    }
}

contract Distributable is StandardToken, Ownable, Whitelist, DateKernel {
    using SafeMath for uint;
    event Distributed(uint256 amount);
    event MemberUpdated(address member, uint256 balance);
    struct member {
        uint256 lastWithdrawal;
        uint256 tokensTotal;
        uint256 tokensLeft;
    }

    mapping (address => member) public teams;

    function _transfer(address _from, address _to, uint256 _value) private returns (bool) {
        require(_value <= balances[_from]);
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function updateMember(address _who, uint256 _last, uint256 _total, uint256 _left) internal returns (bool) {
        teams[_who] = member(_last, _total, _left);
        emit MemberUpdated(_who, _left);
        return true;
    }
    
    function airdrop(address[] dests, uint256[] values) public onlyOwner {
        // This simple validation will catch most mistakes without consuming
        // too much gas.
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            transfer(dests[i], values[i]);
        }
    }

    function distributeTokens(address[] _member, uint256[] _amount)
    onlyOwner
    public
    returns (bool)
    {
        require(_member.length == _amount.length);
        for (uint256 i = 0; i < _member.length; i++) {
            updateMember(_member[i], 0, _amount[i], _amount[i]);
            addAddressToWhitelist(_member[i]);
        }
        emit Distributed(_member.length);
        return true;
    }

    function rewardController(address _member)
    internal
    returns (uint256)
    {
        member storage mbr = teams[_member];
        require(mbr.tokensLeft > 0, "You&#39;ve spent your share");
        uint256 multiplier;
        uint256 callback;
        uint256 curDate = determineDate();
        uint256 lastDate = mbr.lastWithdrawal;
        if(curDate > lastDate) {
            multiplier = curDate.sub(lastDate);
        } else if(curDate == lastDate) {
            revert("Its no time");
        }
        if(mbr.tokensTotal >= mbr.tokensLeft && mbr.tokensTotal > 0) {
            if(curDate == 10) {
                callback = mbr.tokensLeft;
            } else {
                callback = multiplier.mul((mbr.tokensTotal).div(10));
            }
        }
        updateMember(
            _member,
            curDate,
            mbr.tokensTotal,
            mbr.tokensLeft.sub(callback)
        );
        return callback;
    }

    function getDistributedToken()
    public
    onlyIfWhitelisted(msg.sender)
    returns(bool)
    {
        require(unlockTime > now);
        uint256 amount = rewardController(msg.sender);
        _transfer(this, msg.sender, amount);
        return true;
    }
}

contract TutorNinjaToken is Distributable, BurnableToken, CanReclaimToken, Claimable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public INITIAL_SUPPLY = 33e6 * (10 ** uint256(decimals));

    constructor()
    public
    DateKernel(1541030400)
    {
        name = "Tutor Ninja";
        symbol = "NTOK";
        decimals = 10;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    function() external {
        revert("Does not accept ether");
    }
}