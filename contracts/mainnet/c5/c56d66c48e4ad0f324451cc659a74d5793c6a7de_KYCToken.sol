pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    mapping(address => uint256) public balances;

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Freezing tokens
 */
contract Freezing is Ownable, ERC20Basic {
    using SafeMath for uint256;

    address tokenManager;

    bool freezingActive = true;

    event Freeze(address _holder, uint256 _amount);
    event Unfreeze(address _holder, uint256 _amount);

    // all freezing sum for every holder
    mapping(address => uint256) public freezeBalances;

    modifier onlyTokenManager() {
        assert(msg.sender == tokenManager);
        _;
    }

    /**
     * @dev Check freezing balance
     */
    modifier checkFreezing(address _holder, uint _value) {
        if (freezingActive) {
            require(balances[_holder].sub(_value) >= freezeBalances[_holder]);
        }
        _;
    }


    function setTokenManager(address _newManager) onlyOwner public {
        tokenManager = _newManager;
    }

    /**
     * @dev Enable freezing for contract
     */
    function onFreezing() onlyTokenManager public {
        freezingActive = true;
    }

    /**
     * @dev Disable freezing for contract
     */
    function offFreezing() onlyTokenManager public {
        freezingActive = false;
    }

    function Freezing() public {
        tokenManager = owner;
    }

    /**
     * @dev Returns freezing balance of _holder
     */
    function freezingBalanceOf(address _holder) public view returns (uint256) {
        return freezeBalances[_holder];
    }

    /**
     * @dev Freeze amount for user
     */
    function freeze(address _holder, uint _amount) public onlyTokenManager {
        assert(balances[_holder].sub(_amount.add(freezeBalances[_holder])) >= 0);

        freezeBalances[_holder] = freezeBalances[_holder].add(_amount);
        emit Freeze(_holder, _amount);
    }

    /**
     * @dev Unfreeze amount for user
     */
    function unfreeze(address _holder, uint _amount) public onlyTokenManager {
        assert(freezeBalances[_holder].sub(_amount) >= 0);

        freezeBalances[_holder] = freezeBalances[_holder].sub(_amount);
        emit Unfreeze(_holder, _amount);
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
}

/**
 * @title Roles of users
 */
contract VerificationStatus {
    enum Statuses {None, Self, Video, Agent, Service}
    Statuses constant defaultStatus = Statuses.None;

    event StatusChange(bytes32 _property, address _user, Statuses _status, address _caller);
}


/**
 * @title Roles of users
 *
 * @dev User roles for KYC Contract
 */
contract Roles is Ownable {

    // 0, 1, 2
    enum RoleItems {Person, Agent, Administrator}
    RoleItems constant defaultRole = RoleItems.Person;

    mapping (address => RoleItems) private roleList;

    /**
     * @dev Event for every change of role
     */
    event RoleChange(address _user, RoleItems _role, address _caller);

    /**
     * @dev for agent function
     */
    modifier onlyAgent() {
        assert(roleList[msg.sender] == RoleItems.Agent);
        _;
    }

    /**
     * @dev for administrator function
     */
    modifier onlyAdministrator() {
        assert(roleList[msg.sender] == RoleItems.Administrator || msg.sender == owner);
        _;
    }

    /**
     * @dev Save role for user
     */
    function _setRole(address _user, RoleItems _role) internal {
        emit RoleChange(_user, _role, msg.sender);
        roleList[_user] = _role;
    }

    /**
     * @dev reset role
     */
    function resetRole(address _user) onlyAdministrator public {
        _setRole(_user, RoleItems.Person);
    }

    /**
     * @dev Appointing agent by administrator or owner
     */
    function appointAgent(address _user) onlyAdministrator public {
        _setRole(_user, RoleItems.Agent);
    }

    /**
     * @dev Appointing administrator by owner
     */
    function appointAdministrator(address _user) onlyOwner public returns (bool) {
        _setRole(_user, RoleItems.Administrator);
        return true;
    }

    function getRole(address _user) public view returns (RoleItems) {
        return roleList[_user];
    }

}

/**
 * @title Storage for users data
 */
contract PropertyStorage is Roles, VerificationStatus {

    struct Property {
    Statuses status;
    bool exist;
    uint16 code;
    }

    mapping(address => mapping(bytes32 => Property)) private propertyStorage;

    // agent => property => status
    mapping(address => mapping(bytes32 => bool)) agentSign;

    event NewProperty(bytes32 _property, address _user, address _caller);

    modifier propertyExist(bytes32 _property, address _user) {
        assert(propertyStorage[_user][_property].exist);
        _;
    }

    /**
     *  @dev Compute hash for property before write into storage
     *
     *  @param _name Name of property (such as full_name, birthday, address etc.)
     *  @param _data Value of property
     */
    function computePropertyHash(string _name, string _data) pure public returns (bytes32) {
        return sha256(_name, _data);
    }

    function _addPropertyValue(bytes32 _property, address _user) internal {
        propertyStorage[_user][_property] = Property(
        Statuses.None,
        true,
        0
        );
        emit NewProperty(_property, _user, msg.sender);
    }

    /**
     * @dev Add data for any user by administrator
     */
    function addPropertyForUser(bytes32 _property, address _user) public onlyAdministrator returns (bool) {
        _addPropertyValue(_property, _user);
        return true;
    }

    /**
     *  @dev Add property for sender
     */
    function addProperty(bytes32 _property) public returns (bool) {
        _addPropertyValue(_property, msg.sender);
        return true;
    }

    /**
     * @dev Returns status of user data (may be self 1, video 2, agent 3 or Service 4)
     * @dev If verification is empty then it returns 0 (None)
     */
    function getPropertyStatus(bytes32 _property, address _user) public view propertyExist(_property, _user) returns (Statuses) {
        return propertyStorage[_user][_property].status;
    }

    /**
     * @dev when user upload documents administrator will call this function
     */
    function setPropertyStatus(bytes32 _property, address _user, Statuses _status) public onlyAdministrator returns (bool){
        _setPropertyStatus(_property, _user, _status);
        return true;
    }

    /**
     * @dev Agent sign on user data by agent
     */
    function setAgentVerificationByAgent(bytes32 _property, address _user) public onlyAgent {
        _setPropertyStatus(_property, _user, Statuses.Agent);
        _signPropertyByAgent(msg.sender, _user, _property);
    }

    /**
     * @dev Agent sign on user data by Admin
     */
    function setAgentVerificationByAdmin(address _agent, address _user, bytes32 _property) public onlyOwner {
        _setPropertyStatus(_property, _user, Statuses.Agent);
        _signPropertyByAgent(_agent, _user, _property);
    }

    /**
     * @dev Set verification status for user data
     */
    function _setPropertyStatus(bytes32 _property, address _user, Statuses _status) internal propertyExist(_property, _user) {
        propertyStorage[_user][_property].status = _status;
        emit StatusChange(_property, _user, _status, msg.sender);
    }

    /**
     * @dev Agent sign on user data
     */
    function _signPropertyByAgent(address _agent, address _user, bytes32 _property) internal {
        bytes32 _hash = _getHash(_user, _property);
        agentSign[_agent][_hash] = true;
    }

    /**
     * @dev To make sure that the agent has signed the user property
     */
    function checkAgentSign(address _agent, address _user, bytes32 _property) public view returns (bool) {
        bytes32 _hash = _getHash(_user, _property);
        return agentSign[_agent][_hash];
    }

    /**
     * @dev Get hash sum for property
     */
    function _getHash(address _user, bytes32 _property) public pure returns (bytes32) {
        return sha256(_user, _property);
    }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract ERC20BasicToken is ERC20Basic, Freezing {
    using SafeMath for uint256;

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
    function transfer(address _to, uint256 _value) checkFreezing(msg.sender, _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
contract KYCToken is ERC20BasicToken, ERC20, PropertyStorage {

    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 public totalSupply = 42000000000000000000000000;
    string public name = "KYC.Legal token";
    uint8 public decimals = 18;
    string public symbol = "KYC";

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function KYCToken() public {
        balances[msg.sender] = totalSupply;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) checkFreezing(_from, _value) public returns (bool) {
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
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

}