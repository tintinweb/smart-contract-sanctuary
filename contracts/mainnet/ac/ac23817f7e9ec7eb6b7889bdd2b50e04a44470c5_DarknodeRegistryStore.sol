pragma solidity 0.4.24;

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
 * @notice LinkedList is a library for a circular double linked list.
 */
library LinkedList {

    /*
    * @notice A permanent NULL node (0x0) in the circular double linked list.
    * NULL.next is the head, and NULL.previous is the tail.
    */
    address public constant NULL = 0x0;

    /**
    * @notice A node points to the node before it, and the node after it. If
    * node.previous = NULL, then the node is the head of the list. If
    * node.next = NULL, then the node is the tail of the list.
    */
    struct Node {
        bool inList;
        address previous;
        address next;
    }

    /**
    * @notice LinkedList uses a mapping from address to nodes. Each address
    * uniquely identifies a node, and in this way they are used like pointers.
    */
    struct List {
        mapping (address => Node) list;
    }

    /**
    * @notice Insert a new node before an existing node.
    *
    * @param self The list being used.
    * @param target The existing node in the list.
    * @param newNode The next node to insert before the target.
    */
    function insertBefore(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");

        // It is expected that this value is sometimes NULL.
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

    /**
    * @notice Insert a new node after an existing node.
    *
    * @param self The list being used.
    * @param target The existing node in the list.
    * @param newNode The next node to insert after the target.
    */
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");

        // It is expected that this value is sometimes NULL.
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

    /**
    * @notice Remove a node from the list, and fix the previous and next
    * pointers that are pointing to the removed node. Removing anode that is not
    * in the list will do nothing.
    *
    * @param self The list being using.
    * @param node The node in the list to be removed.
    */
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "not in list");
        if (node == NULL) {
            return;
        }
        address p = self.list[node].previous;
        address n = self.list[node].next;

        self.list[p].next = n;
        self.list[n].previous = p;

        // Deleting the node should set this value to false, but we set it here for
        // explicitness.
        self.list[node].inList = false;
        delete self.list[node];
    }

    /**
    * @notice Insert a node at the beginning of the list.
    *
    * @param self The list being used.
    * @param node The node to insert at the beginning of the list.
    */
    function prepend(List storage self, address node) internal {
        // isInList(node) is checked in insertBefore

        insertBefore(self, begin(self), node);
    }

    /**
    * @notice Insert a node at the end of the list.
    *
    * @param self The list being used.
    * @param node The node to insert at the end of the list.
    */
    function append(List storage self, address node) internal {
        // isInList(node) is checked in insertBefore

        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
        // isInList(left) and isInList(right) are checked in remove

        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

    /**
    * @notice Get the node at the beginning of a double linked list.
    *
    * @param self The list being used.
    *
    * @return A address identifying the node at the beginning of the double
    * linked list.
    */
    function begin(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }

    /**
    * @notice Get the node at the end of a double linked list.
    *
    * @param self The list being used.
    *
    * @return A address identifying the node at the end of the double linked
    * list.
    */
    function end(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].previous;
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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

contract RepublicToken is PausableToken, BurnableToken {

    string public constant name = "Republic Token";
    string public constant symbol = "REN";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(decimals);

    /// @notice The RepublicToken Constructor.
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transferTokens(address beneficiary, uint256 amount) public onlyOwner returns (bool) {
        /* solium-disable error-reason */
        require(amount > 0);

        balances[owner] = balances[owner].sub(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        emit Transfer(owner, beneficiary, amount);

        return true;
    }
}

/// @notice This contract stores data and funds for the DarknodeRegistry
/// contract. The data / fund logic and storage have been separated to improve
/// upgradability.
contract DarknodeRegistryStore is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    /// @notice Darknodes are stored in the darknode struct. The owner is the
    /// address that registered the darknode, the bond is the amount of REN that
    /// was transferred during registration, and the public key is the
    /// encryption key that should be used when sending sensitive information to
    /// the darknode.
    struct Darknode {
        // The owner of a Darknode is the address that called the register
        // function. The owner is the only address that is allowed to
        // deregister the Darknode, unless the Darknode is slashed for
        // malicious behavior.
        address owner;

        // The bond is the amount of REN submitted as a bond by the Darknode.
        // This amount is reduced when the Darknode is slashed for malicious
        // behavior.
        uint256 bond;

        // The block number at which the Darknode is considered registered.
        uint256 registeredAt;

        // The block number at which the Darknode is considered deregistered.
        uint256 deregisteredAt;

        // The public key used by this Darknode for encrypting sensitive data
        // off chain. It is assumed that the Darknode has access to the
        // respective private key, and that there is an agreement on the format
        // of the public key.
        bytes publicKey;
    }

    /// Registry data.
    mapping(address => Darknode) private darknodeRegistry;
    LinkedList.List private darknodes;

    // RepublicToken.
    RepublicToken public ren;

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    /// @param _ren The address of the RepublicToken contract.
    constructor(
        string _VERSION,
        RepublicToken _ren
    ) public {
        VERSION = _VERSION;
        ren = _ren;
    }

    /// @notice Instantiates a darknode and appends it to the darknodes
    /// linked-list.
    ///
    /// @param _darknodeID The darknode&#39;s ID.
    /// @param _darknodeOwner The darknode&#39;s owner&#39;s address
    /// @param _bond The darknode&#39;s bond value
    /// @param _publicKey The darknode&#39;s public key
    /// @param _registeredAt The time stamp when the darknode is registered.
    /// @param _deregisteredAt The time stamp when the darknode is deregistered.
    function appendDarknode(
        address _darknodeID,
        address _darknodeOwner,
        uint256 _bond,
        bytes _publicKey,
        uint256 _registeredAt,
        uint256 _deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: _darknodeOwner,
            bond: _bond,
            publicKey: _publicKey,
            registeredAt: _registeredAt,
            deregisteredAt: _deregisteredAt
        });
        darknodeRegistry[_darknodeID] = darknode;
        LinkedList.append(darknodes, _darknodeID);
    }

    /// @notice Returns the address of the first darknode in the store
    function begin() external view onlyOwner returns(address) {
        return LinkedList.begin(darknodes);
    }

    /// @notice Returns the address of the next darknode in the store after the
    /// given address.
    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodes, darknodeID);
    }

    /// @notice Removes a darknode from the store and transfers its bond to the
    /// owner of this contract.
    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodeRegistry[darknodeID].bond;
        delete darknodeRegistry[darknodeID];
        LinkedList.remove(darknodes, darknodeID);
        require(ren.transfer(owner, bond), "bond transfer failed");
    }

    /// @notice Updates the bond of the darknode. If the bond is being
    /// decreased, the difference is sent to the owner of this contract.
    function updateDarknodeBond(address darknodeID, uint256 bond) external onlyOwner {
        uint256 previousBond = darknodeRegistry[darknodeID].bond;
        darknodeRegistry[darknodeID].bond = bond;
        if (previousBond > bond) {
            require(ren.transfer(owner, previousBond - bond), "cannot transfer bond");
        }
    }

    /// @notice Updates the deregistration timestamp of a darknode.
    function updateDarknodeDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodeRegistry[darknodeID].deregisteredAt = deregisteredAt;
    }

    /// @notice Returns the owner of a given darknode.
    function darknodeOwner(address darknodeID) external view onlyOwner returns (address) {
        return darknodeRegistry[darknodeID].owner;
    }

    /// @notice Returns the bond of a given darknode.
    function darknodeBond(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].bond;
    }

    /// @notice Returns the registration time of a given darknode.
    function darknodeRegisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].registeredAt;
    }

    /// @notice Returns the deregistration time of a given darknode.
    function darknodeDeregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].deregisteredAt;
    }

    /// @notice Returns the encryption public key of a given darknode.
    function darknodePublicKey(address darknodeID) external view onlyOwner returns (bytes) {
        return darknodeRegistry[darknodeID].publicKey;
    }
}