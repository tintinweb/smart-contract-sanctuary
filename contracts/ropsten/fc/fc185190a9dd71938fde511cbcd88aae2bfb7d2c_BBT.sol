pragma solidity ^0.4.24;


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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
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
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


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
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
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
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

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
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an address access to this role
     */
    function add(Role storage _role, address _addr)
        internal
    {
        _role.bearer[_addr] = true;
    }

    /**
     * @dev remove an address&#39; access to this role
     */
    function remove(Role storage _role, address _addr)
        internal
    {
        _role.bearer[_addr] = false;
    }

    /**
     * @dev check if an address has this role
     * // reverts
     */
    function check(Role storage _role, address _addr)
        internal
        view
    {
        require(has(_role, _addr));
    }

    /**
     * @dev check if an address has this role
     * @return bool
     */
    function has(Role storage _role, address _addr)
        internal
        view
        returns (bool)
    {
        return _role.bearer[_addr];
    }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

    /**
     * @dev reverts if addr does not have role
     * @param _operator address
     * @param _role the name of the role
     * // reverts
     */
    function checkRole(address _operator, string _role)
        public
        view
    {
        roles[_role].check(_operator);
    }

    /**
     * @dev determine if addr has role
     * @param _operator address
     * @param _role the name of the role
     * @return bool
     */
    function hasRole(address _operator, string _role)
        public
        view
        returns (bool)
    {
        return roles[_role].has(_operator);
    }

    /**
     * @dev add a role to an address
     * @param _operator address
     * @param _role the name of the role
     */
    function addRole(address _operator, string _role)
        internal
    {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

    /**
     * @dev remove a role from an address
     * @param _operator address
     * @param _role the name of the role
     */
    function removeRole(address _operator, string _role)
        internal
    {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param _role the name of the role
     * // reverts
     */
    modifier onlyRole(string _role)
    {
        checkRole(msg.sender, _role);
        _;
    }

    /**
     * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
     * @param _roles the names of the roles to scope access to
     * // reverts
     *
     * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
     *  see: https://github.com/ethereum/solidity/issues/2467
     */
    // modifier onlyRoles(string[] _roles) {
    //     bool hasAnyRole = false;
    //     for (uint8 i = 0; i < _roles.length; i++) {
    //         if (hasRole(msg.sender, _roles[i])) {
    //             hasAnyRole = true;
    //             break;
    //         }
    //     }

    //     require(hasAnyRole);

    //     _;
    // }
}

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";

    /**
     * @dev Throws if operator is not whitelisted.
     * @param _operator address
     */
    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev getter to determine if address is in whitelist
     */
    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param _operator address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn&#39;t in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren&#39;t in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

}

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library ArrayUtils {
    function findUpperBound(uint256[] storage _array, uint256 _element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = _array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (_array[mid] > _element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point at `low` is the exclusive upper bound. We will return the inclusive upper bound.

        if (low > 0 && _array[low - 1] == _element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

/**
 * @title SnapshotToken
 *
 * @dev An ERC20 token which enables taking snapshots of accounts&#39; balances.
 * @dev This can be useful to safely implement voting weighed by balance.
 */
contract SnapshotToken is StandardToken {
    using ArrayUtils for uint256[];

    // The 0 id represents no snapshot was taken yet.
    uint256 public currSnapshotId;

    mapping (address => uint256[]) internal snapshotIds;
    mapping (address => uint256[]) internal snapshotBalances;

    event Snapshot(uint256 id);

    function transfer(address _to, uint256 _value) public returns (bool) {
        _updateSnapshot(msg.sender);
        _updateSnapshot(_to);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _updateSnapshot(_from);
        _updateSnapshot(_to);
        return super.transferFrom(_from, _to, _value);
    }

    function snapshot() public returns (uint256) {
        currSnapshotId += 1;
        emit Snapshot(currSnapshotId);
        return currSnapshotId;
    }

    function balanceOfAt(address _account, uint256 _snapshotId) public view returns (uint256) {
        require(_snapshotId > 0 && _snapshotId <= currSnapshotId);

        uint256 idx = snapshotIds[_account].findUpperBound(_snapshotId);

        if (idx == snapshotIds[_account].length) {
            return balanceOf(_account);
        } else {
            return snapshotBalances[_account][idx];
        }
    }

    function _updateSnapshot(address _account) internal {
        if (_lastSnapshotId(_account) < currSnapshotId) {
            snapshotIds[_account].push(currSnapshotId);
            snapshotBalances[_account].push(balanceOf(_account));
        }
    }

    function _lastSnapshotId(address _account) internal view returns (uint256) {
        uint256[] storage snapshots = snapshotIds[_account];

        if (snapshots.length == 0) {
            return 0;
        } else {
            return snapshots[snapshots.length - 1];
        }
    }
}


contract BBT is BurnableToken, PausableToken, SnapshotToken, Whitelist {
    string public constant symbol = "BBT";
    string public constant name = "BonBon Token";
    uint8 public constant decimals = 18;
    uint256 private overrideTotalSupply_ = 10 * 1e9 * 1e18; //10 billion

    uint256 public circulation;
    address public teamWallet;
    uint256 public constant teamReservedRatio = 10;

    mapping (uint256 => uint256) private snapshotCirculations_;   //snapshotId => circulation

    event Mine(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event SetTeamWallet(address indexed from, address indexed teamWallet);
    event UnlockTeamBBT(address indexed teamWallet, uint256 amount, string source);

    /**
     * @dev make sure unreleased BBT is enough.
     */
    modifier hasEnoughUnreleasedBBT(uint256 _amount) {
        require(circulation.add(_amount) <= totalSupply_, "Unreleased BBT not enough.");
        _;
    }

    /**
     * @dev make sure dev team wallet is set.
     */
    modifier hasTeamWallet() {
        require(teamWallet != address(0), "Team wallet not set.");
        _;
    }

    constructor() public {
        totalSupply_ = overrideTotalSupply_;
    }

    /**
     * @dev make snapshot.
     */
    function snapshot()
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
        returns(uint256)
    {
        currSnapshotId += 1;
        snapshotCirculations_[currSnapshotId] = circulation;
        emit Snapshot(currSnapshotId);
        return currSnapshotId;
    }

    /**
     * @dev get BBT circulation by snapshot id.
     * @param _snapshotId snapshot id.
     */
    function circulationAt(uint256 _snapshotId)
        public
        view
        returns(uint256)
    {
        require(_snapshotId > 0 && _snapshotId <= currSnapshotId, "invalid snapshot id.");
        return snapshotCirculations_[_snapshotId];
    }

    /**
     * @dev setup team wallet.
     * @param _address address of team wallet.
     */
    function setTeamWallet(address _address)
        onlyOwner
        whenNotPaused
        public
        returns (bool)
    {
        teamWallet = _address;
        emit SetTeamWallet(msg.sender, _address);
        return true;
    }

    /**
     * @dev for authorized dapp mining BBT.
     * @param _to to which address BBT send to.
     * @param _amount how many BBT send.
     */
    function mine(address _to, uint256 _amount)
        onlyIfWhitelisted(msg.sender)
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns (bool)
    {
        releaseBBT(_to, _amount);

        //unlock dev team bbt
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), &#39;mine&#39;);

        emit Mine(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev owner release BBT to specified address.
     * @param _to which address release to.
     * @param _amount how many BBT release to.
     */
    function release(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        releaseBBT(_to, _amount);
        emit Release(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev owner release BBT and unlock corresponding ratio to dev team wallet.
     * @param _to which address release to.
     * @param _amount how many BBT release to.
     */
    function releaseAndUnlock(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        release(_to, _amount);

        //unlock dev team bbt
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), &#39;release&#39;);

        return true;
    }

    function getTeamUnlockAmountHelper(uint256 _amount)
        private
        pure
        returns(uint256)
    {
        return _amount.mul(teamReservedRatio).div(100 - teamReservedRatio);
    }

    function unlockTeamBBT(uint256 _unlockAmount, string _source)
        hasTeamWallet
        hasEnoughUnreleasedBBT(_unlockAmount)
        private
        returns(bool)
    {
        releaseBBT(teamWallet, _unlockAmount);
        emit UnlockTeamBBT(teamWallet, _unlockAmount, _source);
        return true;
    }

    /**
     * @dev update balance and circulation.
     */
    function releaseBBT(address _to, uint256 _amount)
        hasEnoughUnreleasedBBT(_amount)
        private
        returns(bool)
    {
        super._updateSnapshot(msg.sender);
        super._updateSnapshot(_to);

        balances[_to] = balances[_to].add(_amount);
        circulation = circulation.add(_amount);
    }
}