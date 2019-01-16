pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/LinkedListLib.sol

/**
 * @title LinkedListLib
 * @author Darryl Morris (o0ragman0o) and Modular.network
 *
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 * into the Modular-Network ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * It has been updated to add additional functionality and be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * version 1.1.1
 * Copyright (c) 2017 Modular Inc.
 * The MIT License (MIT)
 * https://github.com/Modular-network/ethereum-libraries/blob/master/LICENSE
 *
 * The LinkedListLib provides functionality for implementing data indexing using
 * a circlular linked list
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList{
        mapping (uint256 => mapping (bool => uint256)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self)
        public
        view returns (bool)
    {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, uint256 _node)
        public
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) public view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, uint256 _node)
        public view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond &#39;_node&#39; in direction `_direction`
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) private  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

// File: openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}

// File: contracts/QuantstampAuditData.sol

contract QuantstampAuditData is Whitelist {
  // the audit data has a whitelist of addresses of audit contracts that may interact with this contract
  using LinkedListLib for LinkedListLib.LinkedList;

  // constants used by LinkedListLib
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;

  // state of audit requests submitted to the contract
  enum AuditState {
    None,
    Queued,
    Assigned,
    Refunded,
    Completed,  // automated audit finished successfully and the report is available
    Error,      // automated audit failed to finish; the report contains detailed information about the error
    Expired,
    Resolved
  }

  // structure representing an audit
  struct Audit {
    address requestor;
    string contractUri;
    uint256 price;
    uint256 requestBlockNumber; // block number that audit was requested
    QuantstampAuditData.AuditState state;
    address auditor;       // the address of the node assigned to the audit
    uint256 assignBlockNumber;  // block number that audit was assigned
    string reportHash;     // stores the hash of audit report
    uint256 reportBlockNumber;  // block number that the payment and the audit report were submitted
    address registrar;  // address of the contract which registers this request
  }

  // map audits (requestId, Audit)
  mapping(uint256 => Audit) public audits;

  // token used to pay for audits. This contract assumes that the owner of the contract trusts token&#39;s code and
  // that transfer function (such as transferFrom, transfer) do the right thing
  StandardToken public token;

  // Once an audit node gets an audit request, the audit price is locked for this many blocks.
  // After that, the requestor can asks for a refund.
  uint256 public auditTimeoutInBlocks = 25;

  // maximum number of assigned audits per each auditor
  uint256 public maxAssignedRequests = 10;

  // map audit nodes to their minimum prices. Defaults to zero: the node accepts all requests.
  mapping(address => uint256) public minAuditPrice;

  // whitelist audit nodes
  LinkedListLib.LinkedList internal whitelistedNodesList;

  // For generating requestIds starting from 1
  uint256 private requestCounter;

  event WhitelistedNodeAdded(address addr);
  event WhitelistedNodeRemoved(address addr);

  /**
   * @dev The constructor creates an audit contract.
   * @param tokenAddress The address of a StandardToken that will be used to pay auditor nodes.
   */
  constructor (address tokenAddress) public {
    require(tokenAddress != address(0));
    token = StandardToken(tokenAddress);
  }

  function addAuditRequest (address requestor, string contractUri, uint256 price) public onlyWhitelisted returns(uint256) {
    // assign the next request ID
    uint256 requestId = ++requestCounter;
    // store the audit
    audits[requestId] = Audit(requestor, contractUri, price, block.number, AuditState.Queued, address(0), 0, "", 0, msg.sender);  // solhint-disable-line not-rely-on-time
    return requestId;
  }

  function getAuditContractUri(uint256 requestId) public view returns(string) {
    return audits[requestId].contractUri;
  }

  function getAuditRequestor(uint256 requestId) public view returns(address) {
    return audits[requestId].requestor;
  }

  function getAuditPrice (uint256 requestId) public view returns(uint256) {
    return audits[requestId].price;
  }

  function getAuditState (uint256 requestId) public view returns(AuditState) {
    return audits[requestId].state;
  }

  function getAuditRequestBlockNumber (uint256 requestId) public view returns(uint) {
    return audits[requestId].requestBlockNumber;
  }

  function setAuditState (uint256 requestId, AuditState state) public onlyWhitelisted {
    audits[requestId].state = state;
  }

  function getAuditAuditor (uint256 requestId) public view returns(address) {
    return audits[requestId].auditor;
  }

  function getAuditRegistrar (uint256 requestId) public view returns(address) {
    return audits[requestId].registrar;
  }

  function setAuditAuditor (uint256 requestId, address auditor) public onlyWhitelisted {
    audits[requestId].auditor = auditor;
  }

  function getAuditAssignBlockNumber (uint256 requestId) public view returns(uint) {
    return audits[requestId].assignBlockNumber;
  }

  function setAuditAssignBlockNumber (uint256 requestId, uint256 assignBlockNumber) public onlyWhitelisted {
    audits[requestId].assignBlockNumber = assignBlockNumber;
  }

  function setAuditReportHash (uint256 requestId, string reportHash) public onlyWhitelisted {
    audits[requestId].reportHash = reportHash;
  }

  function setAuditReportBlockNumber (uint256 requestId, uint256 reportBlockNumber) public onlyWhitelisted {
    audits[requestId].reportBlockNumber = reportBlockNumber;
  }

  function setAuditRegistrar (uint256 requestId, address registrar) public onlyWhitelisted {
    audits[requestId].registrar = registrar;
  }

  function setAuditTimeout (uint256 timeoutInBlocks) public onlyOwner {
    auditTimeoutInBlocks = timeoutInBlocks;
  }

  /**
   * @dev set the maximum number of audits any audit node can handle at any time.
   * @param maxAssignments maximum number of audit requests for each auditor
   */
  function setMaxAssignedRequests (uint256 maxAssignments) public onlyOwner {
    maxAssignedRequests = maxAssignments;
  }

  function getMinAuditPrice (address auditor) public view returns(uint256) {
    return minAuditPrice[auditor];
  }

  /**
   * @dev Allows the audit node to set its minimum price per audit in wei-QSP
   * @param price The minimum price.
   */
  function setMinAuditPrice(address auditor, uint256 price) public onlyWhitelisted {
    minAuditPrice[auditor] = price;
  }

  /**
   * @dev Returns true if a node is whitelisted
   * param node Node to check.
   */
  function isWhitelisted(address node) public view returns(bool) {
    return whitelistedNodesList.nodeExists(uint256(node));
  }

  /**
   * @dev Adds an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist
   */
  function addNodeToWhitelist(address addr) public onlyOwner returns(bool success) {
    if (whitelistedNodesList.insert(HEAD, uint256(addr), PREV)) {
      emit WhitelistedNodeAdded(addr);
      success = true;
    }
  }

  /**
   * @dev Removes an address from the whitelist linked-list
   * @param addr address
   * @return true if the address was removed from the whitelist,
   */
  function removeNodeFromWhitelist(address addr) public onlyOwner returns(bool success) {
    if (whitelistedNodesList.remove(uint256(addr)) != 0) {
      emit WhitelistedNodeRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev Given a whitelisted address, returns the next address from the whitelist
   * @param addr address
   * @return next address of the given param
   */
  function getNextWhitelistedNode(address addr) public view returns(address) {
    bool direction;
    uint256 next;
    (direction, next) = whitelistedNodesList.getAdjacent(uint256(addr), NEXT);
    return address(next);
  }
}

// File: contracts/QuantstampAuditMultiRequestData.sol

contract QuantstampAuditMultiRequestData is Whitelist {

  // As a multirequest consists of requests. The first and last requestId are inclusive.
  struct MultiRequest {
    address requestor;
    uint256 firstRequestId;
    uint256 lastRequestId;
    address registrar;
  }

  // mapping from multiRequestID to a range of generated individual requestIds
  mapping(uint256 => MultiRequest) public multiRequests;
  // mapping from individual audit to an associated multiRequestId
  mapping(uint256 => uint256) public requestIdToMultiRequestId;
  // MultiRequestId starts from 1
  uint256 private multiRequestIdCounter;
  // A map from multiRequestIDs to auditors assigned an audit.
  mapping(uint256 => mapping(address => bool)) internal multiRequestsAssignedToAuditor;

  function addMultiRequest(address requestor, uint256 firstRequestId, uint256 lastRequestId, address registrar) external onlyWhitelisted returns(uint256) {
    multiRequests[++multiRequestIdCounter] = MultiRequest(requestor, firstRequestId, lastRequestId, registrar);
    return multiRequestIdCounter;
  }

  function setMultiRequestRequestor(uint256 multiRequestId, address requestor) external onlyWhitelisted {
    multiRequests[multiRequestId].requestor = requestor;
  }

  function setMultiRequestFirstRequestId(uint256 multiRequestId, uint256 firstRequestId) external onlyWhitelisted {
    multiRequests[multiRequestId].firstRequestId = firstRequestId;
  }

  function setMultiRequestLastRequestId(uint256 multiRequestId, uint256 lastRequestId) external onlyWhitelisted {
    multiRequests[multiRequestId].lastRequestId = lastRequestId;
  }

  function setMultiRequestRegistrar(uint256 multiRequestId, address registrar) external onlyWhitelisted {
    multiRequests[multiRequestId].registrar = registrar;
  }

  function setRequestIdToMultiRequestId(uint256 requestId, uint256 multiRequestId) external onlyWhitelisted {
    requestIdToMultiRequestId[requestId] = multiRequestId;
  }

  function addAuditorToMultiRequestAssignment(uint256 multiRequestId, address auditor) external onlyWhitelisted {
    multiRequestsAssignedToAuditor[multiRequestId][auditor] = true;
  }

  function removeAuditorFromMultiRequestAssignment(uint256 multiRequestId, address auditor) external onlyWhitelisted {
    delete multiRequestsAssignedToAuditor[multiRequestId][auditor];
  }

  function getMultiRequestRequestor(uint256 multiRequestId) external view returns(address) {
    return multiRequests[multiRequestId].requestor;
  }

  function getMultiRequestFirstRequestId(uint256 multiRequestId) external view returns(uint256) {
    return multiRequests[multiRequestId].firstRequestId;
  }

  function getMultiRequestLastRequestId(uint256 multiRequestId) external view returns(uint256) {
    return multiRequests[multiRequestId].lastRequestId;
  }

  function getMultiRequestRegistrar(uint256 multiRequestId) external view returns(address) {
    return multiRequests[multiRequestId].registrar;
  }

  function getMultiRequestIdGivenRequestId(uint256 requestId) external view returns(uint256) {
    return requestIdToMultiRequestId[requestId];
  }

  function existsAuditorFromMultiRequestAssignment(uint256 multiRequestId, address auditor) external view returns(bool) {
    return multiRequestsAssignedToAuditor[multiRequestId][auditor];
  }

}

// File: contracts/QuantstampAuditReportData.sol

contract QuantstampAuditReportData is Whitelist {

  // mapping from requestId to a report
  mapping(uint256 => bytes) public reports;

  function setReport(uint256 requestId, bytes report) external onlyWhitelisted {
    reports[requestId] = report;
  }

  function getReport(uint256 requestId) external view returns(bytes) {
    return reports[requestId];
  }

}

// File: contracts/QuantstampAudit.sol

contract QuantstampAudit is Ownable, Pausable {
  using SafeMath for uint256;
  using LinkedListLib for LinkedListLib.LinkedList;

  // constants used by LinkedListLib
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;

  // mapping from an auditor address to the number of requests that it currently processes
  mapping(address => uint256) public assignedRequestCount;

  // increasingly sorted linked list of prices
  LinkedListLib.LinkedList internal priceList;
  // map from price to a list of request IDs
  mapping(uint256 => LinkedListLib.LinkedList) internal auditsByPrice;

  // list of request IDs of assigned audits (the list preserves temporal order of assignments)
  LinkedListLib.LinkedList internal assignedAudits;

  // contract that stores audit data (separate from the auditing logic)
  QuantstampAuditData public auditData;

  // contract that stores multirequest audit data
  QuantstampAuditMultiRequestData public multiRequestData;

  // contract that stores audit reports on-chain
  QuantstampAuditReportData public reportData;

  event LogAuditFinished(
    uint256 requestId,
    address auditor,
    QuantstampAuditData.AuditState auditResult
  );

  event LogAuditRequested(uint256 requestId,
    address requestor,
    string uri,
    uint256 price
  );

  event LogAuditAssigned(uint256 requestId,
    address auditor,
    address requestor,
    string uri,
    uint256 price,
    uint256 requestBlockNumber);

  /* solhint-disable event-name-camelcase */
  event LogReportSubmissionError_InvalidAuditor(uint256 requestId, address auditor);
  event LogReportSubmissionError_InvalidState(uint256 requestId, address auditor, QuantstampAuditData.AuditState state);
  event LogReportSubmissionError_InvalidResult(uint256 requestId, address auditor, QuantstampAuditData.AuditState state);
  event LogReportSubmissionError_ExpiredAudit(uint256 requestId, address auditor, uint256 allowanceBlockNumber);
  event LogAuditAssignmentError_ExceededMaxAssignedRequests(address auditor);
  event LogAuditAssignmentUpdate_Expired(uint256 requestId, uint256 allowanceBlockNumber);
  /* solhint-enable event-name-camelcase */

  event LogAuditQueueIsEmpty();

  event LogPayAuditor(uint256 requestId, address auditor, uint256 amount);
  event LogAuditNodePriceChanged(address auditor, uint256 amount);

  event LogRefund(uint256 requestId, address requestor, uint256 amount);
  event LogRefundInvalidRequestor(uint256 requestId, address requestor);
  event LogRefundInvalidState(uint256 requestId, QuantstampAuditData.AuditState state);
  event LogRefundInvalidFundsLocked(uint256 requestId, uint256 currentBlock, uint256 fundLockEndBlock);

  // the audit queue has elements, but none satisfy the minPrice of the audit node
  // amount corresponds to the current minPrice of the auditor
  event LogAuditNodePriceHigherThanRequests(address auditor, uint256 amount);

  event LogInvalidResolutionCall(uint256 requestId);
  event LogErrorReportResolved(uint256 requestId, address receiver, uint256 auditPrice);

  event LogMultiRequestRequested(uint256 multiRequestId, uint256 requestIdStart, uint256 requestIdEnd);
  event LogRequestAssignedFromMultiRequest(uint256 requestId, uint256 multiRequestId, address auditor);

  enum AuditAvailabilityState {
    Error,
    Ready,      // an audit is available to be picked up
    Empty,      // there is no audit request in the queue
    Exceeded,   // number of incomplete audit requests is reached the cap
    Underprice  // all queued audit requests are less than the expected price
  }

  /**
   * @dev The constructor creates an audit contract.
   * @param auditDataAddress The address of an AuditData that stores data used for performing audits.
   * @param reportDataAddress The address of a ReportData that stores audit reports.
   */
  constructor (address auditDataAddress, address multiRequestDataAddress, address reportDataAddress) public {
    require(auditDataAddress != address(0));
    require(multiRequestDataAddress != address(0));
    require(reportDataAddress != address(0));
    auditData = QuantstampAuditData(auditDataAddress);
    multiRequestData = QuantstampAuditMultiRequestData(multiRequestDataAddress);
    reportData = QuantstampAuditReportData(reportDataAddress);
  }

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(auditData.isWhitelisted(msg.sender));
    _;
  }

  /**
   * @dev Returns funds to the requestor.
   * @param requestId Unique ID of the audit request.
   */
  function refund(uint256 requestId) external returns(bool) {
    QuantstampAuditData.AuditState state = auditData.getAuditState(requestId);
    // check that the audit exists and is in a valid state
    if (state != QuantstampAuditData.AuditState.Queued &&
          state != QuantstampAuditData.AuditState.Assigned &&
            state != QuantstampAuditData.AuditState.Expired) {
      emit LogRefundInvalidState(requestId, state);
      return false;
    }
    address requestor = auditData.getAuditRequestor(requestId);
    if (requestor != msg.sender) {
      emit LogRefundInvalidRequestor(requestId, msg.sender);
      return;
    }
    uint256 refundBlockNumber = auditData.getAuditAssignBlockNumber(requestId) + auditData.auditTimeoutInBlocks();
    // check that the auditor has not recently started the audit (locking the funds)
    if (state == QuantstampAuditData.AuditState.Assigned) {
      if (block.number <= refundBlockNumber) {
        emit LogRefundInvalidFundsLocked(requestId, block.number, refundBlockNumber);
        return false;
      }
      // the request is expired but not detected by getNextAuditRequest
      updateAssignedAudits(requestId);
    } else if (state == QuantstampAuditData.AuditState.Queued) {
      // remove the request from the queue
      // note that if an audit node is currently assigned the request, it is already removed from the queue
      removeQueueElement(requestId);
    }

    // set the audit state to refunded
    auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Refunded);

    // return the funds to the user
    uint256 price = auditData.getAuditPrice(requestId);
    emit LogRefund(requestId, requestor, price);
    return auditData.token().transfer(requestor, price);
  }

  /**
   * @dev Submits a request to be audited multiple times
   * @param contractUri Identifier of the resource to audit.
   * @param price The total amount of tokens that will be paid per audit. The requester should
   * eventually pay price * count qsp.
   * @param count Number of audits by different Auditors
   */
  function multiRequestAudit(string contractUri, uint256 price, uint256 count) external whenNotPaused returns(uint256[]) {
    require(count > 1, "multiRequest must be more than one");
    require(price.mul(count) <= auditData.token().allowance(msg.sender, address(this)),
      "token transfer must be approved more than price*count");
    uint256[] memory result = new uint256[](count);
    uint256 newMultiRequestId = multiRequestData.addMultiRequest(address(msg.sender), 0, 0, address(this));
    for (uint256 i = 0; i < count; ++i) {
      result[i] = requestAudit(contractUri, price);
      multiRequestData.setRequestIdToMultiRequestId(result[i], newMultiRequestId);
    }
    multiRequestData.setMultiRequestFirstRequestId(newMultiRequestId, result[0]);
    multiRequestData.setMultiRequestLastRequestId(newMultiRequestId, result[result.length-1]);
    emit LogMultiRequestRequested(newMultiRequestId,
      multiRequestData.getMultiRequestFirstRequestId(newMultiRequestId),
      multiRequestData.getMultiRequestLastRequestId(newMultiRequestId));
    return result;
  }

  /**
   * @dev Submits audit request.
   * @param contractUri Identifier of the resource to audit.
   * @param price The total amount of tokens that will be paid for the audit.
   */
  function requestAudit(string contractUri, uint256 price) public whenNotPaused returns(uint256) {
    require(price > 0);
    // transfer tokens to this contract
    auditData.token().transferFrom(msg.sender, address(this), price);
    // store the audit
    uint256 requestId = auditData.addAuditRequest(msg.sender, contractUri, price);

    // TODO: use existing price instead of HEAD (optimization)
    queueAuditRequest(requestId, HEAD);

    emit LogAuditRequested(requestId, msg.sender, contractUri, price); // solhint-disable-line not-rely-on-time

    return requestId;
  }

  /**
   * @dev Submits the report and pays the auditor node for their work if the audit is completed.
   * @param requestId Unique identifier of the audit request.
   * @param auditResult Result of an audit.
   * @param report a compressed report. TODO, let&#39;s document the report format.
   */
  function submitReport(uint256 requestId, QuantstampAuditData.AuditState auditResult, bytes report) public onlyWhitelisted {
    if (QuantstampAuditData.AuditState.Completed != auditResult && QuantstampAuditData.AuditState.Error != auditResult) {
      emit LogReportSubmissionError_InvalidResult(requestId, msg.sender, auditResult);
      return;
    }

    QuantstampAuditData.AuditState auditState = auditData.getAuditState(requestId);
    if (auditState != QuantstampAuditData.AuditState.Assigned) {
      emit LogReportSubmissionError_InvalidState(requestId, msg.sender, auditState);
      return;
    }

    // the sender must be the auditor
    if (msg.sender != auditData.getAuditAuditor(requestId)) {
      emit LogReportSubmissionError_InvalidAuditor(requestId, msg.sender);
      return;
    }

    // remove the requestId from assigned queue
    updateAssignedAudits(requestId);

    // auditor should not send a report after its allowed period
    uint256 allowanceBlockNumber = auditData.getAuditAssignBlockNumber(requestId) + auditData.auditTimeoutInBlocks();
    if (allowanceBlockNumber < block.number) {
      // update assigned to expired state
      auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Expired);
      emit LogReportSubmissionError_ExpiredAudit(requestId, msg.sender, allowanceBlockNumber);
      return;
    }

    // update the audit information held in this contract
    auditData.setAuditState(requestId, auditResult);
    auditData.setAuditReportBlockNumber(requestId, block.number); // solhint-disable-line not-rely-on-time

    // validate the audit state
    require(isAuditFinished(requestId));

    // store reports on-chain
    reportData.setReport(requestId, report);

    emit LogAuditFinished(requestId, msg.sender, auditResult); // solhint-disable-line not-rely-on-time

    if (auditResult == QuantstampAuditData.AuditState.Completed) {
      uint256 auditPrice = auditData.getAuditPrice(requestId);
      auditData.token().transfer(msg.sender, auditPrice);
      emit LogPayAuditor(requestId, msg.sender, auditPrice);
    }
  }

  /**
   * @dev Determines who has to be paid for a given requestId recorded with an error status
   * @param requestId Unique identifier of the audit request.
   * @param toRequester The audit price goes to the requester or the audit node.
   */
  function resolveErrorReport(uint256 requestId, bool toRequester) public onlyOwner {
    QuantstampAuditData.AuditState auditState = auditData.getAuditState(requestId);
    if (auditState != QuantstampAuditData.AuditState.Error) {
      emit LogInvalidResolutionCall(requestId);
      return;
    }

    uint256 auditPrice = auditData.getAuditPrice(requestId);
    address receiver = toRequester ? auditData.getAuditRequestor(requestId) : auditData.getAuditAuditor(requestId);
    auditData.token().transfer(receiver, auditPrice);
    auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Resolved);
    emit LogErrorReportResolved(requestId, receiver, auditPrice);
  }

  /**
   * @dev Determines if there is an audit request available to be picked up by the caller
   */
  function anyRequestAvailable() public view returns(AuditAvailabilityState) {
    uint256 requestId;

    // only whitelisted nodes are able to call this function
    if (!auditData.isWhitelisted(msg.sender)) {
      return AuditAvailabilityState.Error;
    }

    // there are no audits in the queue
    if (!auditQueueExists()) {
      return AuditAvailabilityState.Empty;
    }

    // check if the auditor&#39;s assignment is not exceeded.
    if (assignedRequestCount[msg.sender] >= auditData.maxAssignedRequests()) {
      return AuditAvailabilityState.Exceeded;
    }

    requestId = anyAuditRequestMatchesPrice(auditData.getMinAuditPrice(msg.sender));
    if (requestId == 0) {
      return AuditAvailabilityState.Underprice;
    }
    return AuditAvailabilityState.Ready;
  }

  /**
   * @dev Finds a list of most expensive audits and assigns the oldest one to the auditor node.
   */
  function getNextAuditRequest() public onlyWhitelisted {
    // remove an expired audit request
    if (assignedAudits.listExists()) {
      bool exists;
      uint256 potentialExpiredRequestId;
      (exists, potentialExpiredRequestId) = assignedAudits.getAdjacent(HEAD, NEXT);
      uint256 allowanceBlockNumber = auditData.getAuditAssignBlockNumber(potentialExpiredRequestId) + auditData.auditTimeoutInBlocks();
      if (allowanceBlockNumber < block.number) {
        updateAssignedAudits(potentialExpiredRequestId);
        auditData.setAuditState(potentialExpiredRequestId, QuantstampAuditData.AuditState.Expired);
        emit LogAuditAssignmentUpdate_Expired(potentialExpiredRequestId, allowanceBlockNumber);
      }
    }

    AuditAvailabilityState isRequestAvailable = anyRequestAvailable();
    // there are no audits in the queue
    if (isRequestAvailable == AuditAvailabilityState.Empty) {
      emit LogAuditQueueIsEmpty();
      return;
    }

    // check if the auditor&#39;s assignment is not exceeded.
    if (isRequestAvailable == AuditAvailabilityState.Exceeded) {
      emit LogAuditAssignmentError_ExceededMaxAssignedRequests(msg.sender);
      return;
    }

    // there are no audits in the queue with a price high enough for the audit node
    uint256 minPrice = auditData.getMinAuditPrice(msg.sender);
    uint256 requestId = dequeueAuditRequest(minPrice);
    if (requestId == 0) {
      emit LogAuditNodePriceHigherThanRequests(msg.sender, minPrice);
      return;
    }

    auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Assigned);
    auditData.setAuditAuditor(requestId, msg.sender);
    auditData.setAuditAssignBlockNumber(requestId, block.number);
    assignedRequestCount[msg.sender]++;
    // push to the tail
    assignedAudits.push(requestId, PREV);

    assignMultirequest(requestId);

    emit LogAuditAssigned(
      requestId,
      auditData.getAuditAuditor(requestId),
      auditData.getAuditRequestor(requestId),
      auditData.getAuditContractUri(requestId),
      auditData.getAuditPrice(requestId),
      auditData.getAuditRequestBlockNumber(requestId));
  }

  /**
   * @dev Allows the audit node to set its minimum price per audit in wei-QSP
   * @param price The minimum price.
   */
  function setAuditNodePrice(uint256 price) public onlyWhitelisted {
    auditData.setMinAuditPrice(msg.sender, price);
    emit LogAuditNodePriceChanged(msg.sender, price);
  }

  /**
   * @dev Checks if an audit is finished. It is considered finished when the audit is either completed or failed.
   * @param requestId Unique ID of the audit request.
   */
  function isAuditFinished(uint256 requestId) public view returns(bool) {
    QuantstampAuditData.AuditState state = auditData.getAuditState(requestId);
    return state == QuantstampAuditData.AuditState.Completed || state == QuantstampAuditData.AuditState.Error;
  }

  /**
   * @dev Given a price, returns the next price from the priceList
   * @param price of the current node
   * @return next price in the linked list
   */
  function getNextPrice(uint256 price) public view returns(uint256) {
    bool exists;
    uint256 next;
    (exists, next) = priceList.getAdjacent(price, NEXT);
    return next;
  }

  /**
   * @dev Given a requestId, returns the next one from assignedAudits
   * @param requestId of the current node
   * @return next requestId in the linked list
   */
  function getNextAssignedRequest(uint256 requestId) public view returns(uint256) {
    bool exists;
    uint256 next;
    (exists, next) = assignedAudits.getAdjacent(requestId, NEXT);
    return next;
  }

  /**
   * @dev Given a price and a requestId, then function returns the next requestId with the same price
   * return 0, provided the given price does not exist in auditsByPrice
   * @param price of the current bucket
   * @param requestId unique Id of an requested audit
   * @return next requestId with the same price
   */
  function getNextAuditByPrice(uint256 price, uint256 requestId) public view returns(uint256) {
    bool exists;
    uint256 next;
    (exists, next) = auditsByPrice[price].getAdjacent(requestId, NEXT);
    return next;
  }

  /**
   * @dev Given a requestId, the function removes it from the list of audits and decreases the number of assigned
   * audits of the associated auditor
   * @param requestId unique Id of an requested audit
   */
  function updateAssignedAudits(uint256 requestId) internal {
    assignedAudits.remove(requestId);
    assignedRequestCount[auditData.getAuditAuditor(requestId)] =
      assignedRequestCount[auditData.getAuditAuditor(requestId)].sub(1);
  }

  /**
   * @dev Checks if the list of audits has any elements
   */
  function auditQueueExists() internal view returns(bool) {
    return priceList.listExists();
  }

  /**
   * @dev Adds an audit request to the queue
   * @param requestId Request ID.
   * @param existingPrice price of an existing audit in the queue (makes insertion O(1))
   */
  function queueAuditRequest(uint256 requestId, uint256 existingPrice) internal {
    uint256 price = auditData.getAuditPrice(requestId);
    if (!priceList.nodeExists(price)) {
      // if a price bucket doesn&#39;t exist, create it next to an existing one
      priceList.insert(priceList.getSortedSpot(existingPrice, price, NEXT), price, PREV);
    }
    // push to the tail
    auditsByPrice[price].push(requestId, PREV);
  }

  /**
   * @dev Evaluates if there is an audit price >= minPrice. Returns (false, 0) if there no audit with the desired price.
   * Note that there should not be any audit with price as 0. Also, this function evaluates if the given auditor has not
   * yet assigned to any individual audit of a multiRequest.
   * @param minPrice The minimum audit price.
   */
  function anyAuditRequestMatchesPrice(uint256 minPrice) internal view returns(uint256) {
    bool priceExists;
    uint256 price;
    uint256 requestId;
    uint256 multirequestId;

    // picks the tail of price buckets
    (priceExists, price) = priceList.getAdjacent(HEAD, PREV);
    // iterating in reverse order over price buckets for finding an appropriated request
    while (price != HEAD && price >= minPrice) {
      requestId = getNextAuditByPrice(price, HEAD);
      // iterating over requests in each price bucket. the iteration starts from older requests to younger ones.
      while (requestId != HEAD) {
        multirequestId = multiRequestData.getMultiRequestIdGivenRequestId(requestId);
        // if this request belongs to a multirequest, find out whether an auditor calling this function has been
        // already assigned to another request from the same multirequest.
        // true condition means that this request is not associated to a multirequest.
        if (multirequestId == 0 || !multiRequestData.existsAuditorFromMultiRequestAssignment(multirequestId, msg.sender)) {
          return requestId;
        } else {
          // the given auditor already audited an individual audit from this multi audit request. Let&#39;s
          // jump to the last individual associated requestId.
          requestId = multiRequestData.getMultiRequestLastRequestId(multirequestId);
        }
        requestId = getNextAuditByPrice(price, requestId);
      }
      (priceExists, price) = priceList.getAdjacent(price, PREV);
    }

    return 0;
  }

  /**
   * @dev Finds a list of most expensive audits and returns the oldest one that has a price >= minPrice
   * @param minPrice The minimum audit price.
   */
  function dequeueAuditRequest(uint256 minPrice) internal returns(uint256) {

    uint256 requestId;
    uint256 price;

    // picks the tail of price buckets
    // TODO seems the following statement is redundantly called from getNextAuditRequest. If this is the only place
    // to call dequeueAuditRequest, then removing the following line saves gas, but leaves dequeueAuditRequest
    // unsafe for further extension by noobies.
    requestId = anyAuditRequestMatchesPrice(minPrice);

    if (requestId > 0) {
      price = auditData.getAuditPrice(requestId);
      auditsByPrice[price].remove(requestId);
      // removes the price bucket if it contains no requests
      if (!auditsByPrice[price].listExists()) {
        priceList.remove(price);
      }
      return requestId;
    }
    return 0;
  }

  /**
   * @dev Removes an element from the list
   * @param requestId The Id of the request to be removed
   */
  function removeQueueElement(uint256 requestId) internal {
    uint256 price = auditData.getAuditPrice(requestId);

    // the node must exist in the list
    require(priceList.nodeExists(price));
    require(auditsByPrice[price].nodeExists(requestId));

    auditsByPrice[price].remove(requestId);
    if (!auditsByPrice[price].listExists()) {
      priceList.remove(price);
    }
  }

  /**
   * @dev Manages request if it is from a multirequest
   * @param requestId Unique ID of the audit request.
   */
  function assignMultirequest(uint256 requestId) internal {
    uint256 multirequestId = multiRequestData.getMultiRequestIdGivenRequestId(requestId);
    // record, if the requestId belongs to a multiRequestId
    if (multirequestId > 0) {
      multiRequestData.addAuditorToMultiRequestAssignment(multirequestId, msg.sender);
      emit LogRequestAssignedFromMultiRequest(requestId, multirequestId, msg.sender);
    }
  }
}