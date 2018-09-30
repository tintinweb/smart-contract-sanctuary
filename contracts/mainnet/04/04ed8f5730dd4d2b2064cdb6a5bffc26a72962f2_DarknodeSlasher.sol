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

/// @notice DarknodeRegistry is responsible for the registration and
/// deregistration of Darknodes.
contract DarknodeRegistry is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    /// @notice Darknode pods are shuffled after a fixed number of blocks.
    /// An Epoch stores an epoch hash used as an (insecure) RNG seed, and the
    /// blocknumber which restricts when the next epoch can be called.
    struct Epoch {
        uint256 epochhash;
        uint256 blocknumber;
    }

    uint256 public numDarknodes;
    uint256 public numDarknodesNextEpoch;
    uint256 public numDarknodesPreviousEpoch;

    /// Variables used to parameterize behavior.
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;
    address public slasher;

    /// When one of the above variables is modified, it is only updated when the
    /// next epoch is called. These variables store the values for the next epoch.
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;
    address public nextSlasher;

    /// The current and previous epoch
    Epoch public currentEpoch;
    Epoch public previousEpoch;

    /// Republic ERC20 token contract used to transfer bonds.
    RepublicToken public ren;

    /// Darknode Registry Store is the storage contract for darknodes.
    DarknodeRegistryStore public store;

    /// @notice Emitted when a darknode is registered.
    /// @param _darknodeID The darknode ID that was registered.
    /// @param _bond The amount of REN that was transferred as bond.
    event LogDarknodeRegistered(address _darknodeID, uint256 _bond);

    /// @notice Emitted when a darknode is deregistered.
    /// @param _darknodeID The darknode ID that was deregistered.
    event LogDarknodeDeregistered(address _darknodeID);

    /// @notice Emitted when a refund has been made.
    /// @param _owner The address that was refunded.
    /// @param _amount The amount of REN that was refunded.
    event LogDarknodeOwnerRefunded(address _owner, uint256 _amount);

    /// @notice Emitted when a new epoch has begun.
    event LogNewEpoch();

    /// @notice Emitted when a constructor parameter has been updated.
    event LogMinimumBondUpdated(uint256 previousMinimumBond, uint256 nextMinimumBond);
    event LogMinimumPodSizeUpdated(uint256 previousMinimumPodSize, uint256 nextMinimumPodSize);
    event LogMinimumEpochIntervalUpdated(uint256 previousMinimumEpochInterval, uint256 nextMinimumEpochInterval);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);

    /// @notice Only allow the owner that registered the darknode to pass.
    modifier onlyDarknodeOwner(address _darknodeID) {
        require(store.darknodeOwner(_darknodeID) == msg.sender, "must be darknode owner");
        _;
    }

    /// @notice Only allow unregistered darknodes.
    modifier onlyRefunded(address _darknodeID) {
        require(isRefunded(_darknodeID), "must be refunded or never registered");
        _;
    }

    /// @notice Only allow refundable darknodes.
    modifier onlyRefundable(address _darknodeID) {
        require(isRefundable(_darknodeID), "must be deregistered for at least one epoch");
        _;
    }

    /// @notice Only allowed registered nodes without a pending deregistration to
    /// deregister
    modifier onlyDeregisterable(address _darknodeID) {
        require(isDeregisterable(_darknodeID), "must be deregisterable");
        _;
    }

    /// @notice Only allow the Slasher contract.
    modifier onlySlasher() {
        require(slasher == msg.sender, "must be slasher");
        _;
    }

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    /// @param _renAddress The address of the RepublicToken contract.
    /// @param _storeAddress The address of the DarknodeRegistryStore contract.
    /// @param _minimumBond The minimum bond amount that can be submitted by a
    ///        Darknode.
    /// @param _minimumPodSize The minimum size of a Darknode pod.
    /// @param _minimumEpochInterval The minimum number of blocks between
    ///        epochs.
    constructor(
        string _VERSION,
        RepublicToken _renAddress,
        DarknodeRegistryStore _storeAddress,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochInterval
    ) public {
        VERSION = _VERSION;

        store = _storeAddress;
        ren = _renAddress;

        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;

        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;

        minimumEpochInterval = _minimumEpochInterval;
        nextMinimumEpochInterval = minimumEpochInterval;

        currentEpoch = Epoch({
            epochhash: uint256(blockhash(block.number - 1)),
            blocknumber: block.number
        });
        numDarknodes = 0;
        numDarknodesNextEpoch = 0;
        numDarknodesPreviousEpoch = 0;
    }

    /// @notice Register a darknode and transfer the bond to this contract. The
    /// caller must provide a public encryption key for the darknode as well as
    /// a bond in REN. The bond must be provided as an ERC20 allowance. The dark
    /// node will remain pending registration until the next epoch. Only after
    /// this period can the darknode be deregistered. The caller of this method
    /// will be stored as the owner of the darknode.
    ///
    /// @param _darknodeID The darknode ID that will be registered.
    /// @param _publicKey The public key of the darknode. It is stored to allow
    ///        other darknodes and traders to encrypt messages to the trader.
    /// @param _bond The bond that will be paid. It must be greater than, or
    ///        equal to, the minimum bond.
    function register(address _darknodeID, bytes _publicKey, uint256 _bond) external onlyRefunded(_darknodeID) {
        // REN allowance
        require(_bond >= minimumBond, "insufficient bond");
        // require(ren.allowance(msg.sender, address(this)) >= _bond);
        require(ren.transferFrom(msg.sender, address(this), _bond), "bond transfer failed");
        ren.transfer(address(store), _bond);

        // Flag this darknode for registration
        store.appendDarknode(
            _darknodeID,
            msg.sender,
            _bond,
            _publicKey,
            currentEpoch.blocknumber + minimumEpochInterval,
            0
        );

        numDarknodesNextEpoch += 1;

        // Emit an event.
        emit LogDarknodeRegistered(_darknodeID, _bond);
    }

    /// @notice Deregister a darknode. The darknode will not be deregistered
    /// until the end of the epoch. After another epoch, the bond can be
    /// refunded by calling the refund method.
    /// @param _darknodeID The darknode ID that will be deregistered. The caller
    ///        of this method store.darknodeRegisteredAt(_darknodeID) must be
    //         the owner of this darknode.
    function deregister(address _darknodeID) external onlyDeregisterable(_darknodeID) onlyDarknodeOwner(_darknodeID) {
        // Flag the darknode for deregistration
        store.updateDarknodeDeregisteredAt(_darknodeID, currentEpoch.blocknumber + minimumEpochInterval);
        numDarknodesNextEpoch -= 1;

        // Emit an event
        emit LogDarknodeDeregistered(_darknodeID);
    }

    /// @notice Progress the epoch if it is possible to do so. This captures
    /// the current timestamp and current blockhash and overrides the current
    /// epoch.
    function epoch() external {
        if (previousEpoch.blocknumber == 0) {
            // The first epoch must be called by the owner of the contract
            require(msg.sender == owner, "not authorized (first epochs)");
        }

        // Require that the epoch interval has passed
        require(block.number >= currentEpoch.blocknumber + minimumEpochInterval, "epoch interval has not passed");
        uint256 epochhash = uint256(blockhash(block.number - 1));

        // Update the epoch hash and timestamp
        previousEpoch = currentEpoch;
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocknumber: block.number
        });

        // Update the registry information
        numDarknodesPreviousEpoch = numDarknodes;
        numDarknodes = numDarknodesNextEpoch;

        // If any update functions have been called, update the values now
        if (nextMinimumBond != minimumBond) {
            minimumBond = nextMinimumBond;
            emit LogMinimumBondUpdated(minimumBond, nextMinimumBond);
        }
        if (nextMinimumPodSize != minimumPodSize) {
            minimumPodSize = nextMinimumPodSize;
            emit LogMinimumPodSizeUpdated(minimumPodSize, nextMinimumPodSize);
        }
        if (nextMinimumEpochInterval != minimumEpochInterval) {
            minimumEpochInterval = nextMinimumEpochInterval;
            emit LogMinimumEpochIntervalUpdated(minimumEpochInterval, nextMinimumEpochInterval);
        }
        if (nextSlasher != slasher) {
            slasher = nextSlasher;
            emit LogSlasherUpdated(slasher, nextSlasher);
        }

        // Emit an event
        emit LogNewEpoch();
    }

    /// @notice Allows the contract owner to transfer ownership of the
    /// DarknodeRegistryStore.
    /// @param _newOwner The address to transfer the ownership to.
    function transferStoreOwnership(address _newOwner) external onlyOwner {
        store.transferOwnership(_newOwner);
    }

    /// @notice Allows the contract owner to update the minimum bond.
    /// @param _nextMinimumBond The minimum bond amount that can be submitted by
    ///        a darknode.
    function updateMinimumBond(uint256 _nextMinimumBond) external onlyOwner {
        // Will be updated next epoch
        nextMinimumBond = _nextMinimumBond;
    }

    /// @notice Allows the contract owner to update the minimum pod size.
    /// @param _nextMinimumPodSize The minimum size of a pod.
    function updateMinimumPodSize(uint256 _nextMinimumPodSize) external onlyOwner {
        // Will be updated next epoch
        nextMinimumPodSize = _nextMinimumPodSize;
    }

    /// @notice Allows the contract owner to update the minimum epoch interval.
    /// @param _nextMinimumEpochInterval The minimum number of blocks between epochs.
    function updateMinimumEpochInterval(uint256 _nextMinimumEpochInterval) external onlyOwner {
        // Will be updated next epoch
        nextMinimumEpochInterval = _nextMinimumEpochInterval;
    }

    /// @notice Allow the contract owner to update the DarknodeSlasher contract
    /// address.
    /// @param _slasher The new slasher address.
    function updateSlasher(address _slasher) external onlyOwner {
        nextSlasher = _slasher;
    }

    /// @notice Allow the DarknodeSlasher contract to slash half of a darknode&#39;s
    /// bond and deregister it. The bond is distributed as follows:
    ///   1/2 is kept by the guilty prover
    ///   1/8 is rewarded to the first challenger
    ///   1/8 is rewarded to the second challenger
    ///   1/4 becomes unassigned
    /// @param _prover The guilty prover whose bond is being slashed
    /// @param _challenger1 The first of the two darknodes who submitted the challenge
    /// @param _challenger2 The second of the two darknodes who submitted the challenge
    function slash(address _prover, address _challenger1, address _challenger2)
        external
        onlySlasher
    {
        uint256 penalty = store.darknodeBond(_prover) / 2;
        uint256 reward = penalty / 4;

        // Slash the bond of the failed prover in half
        store.updateDarknodeBond(_prover, penalty);

        // If the darknode has not been deregistered then deregister it
        if (isDeregisterable(_prover)) {
            store.updateDarknodeDeregisteredAt(_prover, currentEpoch.blocknumber + minimumEpochInterval);
            numDarknodesNextEpoch -= 1;
            emit LogDarknodeDeregistered(_prover);
        }

        // Reward the challengers with less than the penalty so that it is not
        // worth challenging yourself
        ren.transfer(store.darknodeOwner(_challenger1), reward);
        ren.transfer(store.darknodeOwner(_challenger2), reward);
    }

    /// @notice Refund the bond of a deregistered darknode. This will make the
    /// darknode available for registration again. Anyone can call this function
    /// but the bond will always be refunded to the darknode owner.
    ///
    /// @param _darknodeID The darknode ID that will be refunded. The caller
    ///        of this method must be the owner of this darknode.
    function refund(address _darknodeID) external onlyRefundable(_darknodeID) {
        address darknodeOwner = store.darknodeOwner(_darknodeID);

        // Remember the bond amount
        uint256 amount = store.darknodeBond(_darknodeID);

        // Erase the darknode from the registry
        store.removeDarknode(_darknodeID);

        // Refund the owner by transferring REN
        ren.transfer(darknodeOwner, amount);

        // Emit an event.
        emit LogDarknodeOwnerRefunded(darknodeOwner, amount);
    }

    /// @notice Retrieves the address of the account that registered a darknode.
    /// @param _darknodeID The ID of the darknode to retrieve the owner for.
    function getDarknodeOwner(address _darknodeID) external view returns (address) {
        return store.darknodeOwner(_darknodeID);
    }

    /// @notice Retrieves the bond amount of a darknode in 10^-18 REN.
    /// @param _darknodeID The ID of the darknode to retrieve the bond for.
    function getDarknodeBond(address _darknodeID) external view returns (uint256) {
        return store.darknodeBond(_darknodeID);
    }

    /// @notice Retrieves the encryption public key of the darknode.
    /// @param _darknodeID The ID of the darknode to retrieve the public key for.
    function getDarknodePublicKey(address _darknodeID) external view returns (bytes) {
        return store.darknodePublicKey(_darknodeID);
    }

    /// @notice Retrieves a list of darknodes which are registered for the
    /// current epoch.
    /// @param _start A darknode ID used as an offset for the list. If _start is
    ///        0x0, the first dark node will be used. _start won&#39;t be
    ///        included it is not registered for the epoch.
    /// @param _count The number of darknodes to retrieve starting from _start.
    ///        If _count is 0, all of the darknodes from _start are
    ///        retrieved. If _count is more than the remaining number of
    ///        registered darknodes, the rest of the list will contain
    ///        0x0s.
    function getDarknodes(address _start, uint256 _count) external view returns (address[]) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        return getDarknodesFromEpochs(_start, count, false);
    }

    /// @notice Retrieves a list of darknodes which were registered for the
    /// previous epoch. See `getDarknodes` for the parameter documentation.
    function getPreviousDarknodes(address _start, uint256 _count) external view returns (address[]) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodesPreviousEpoch;
        }
        return getDarknodesFromEpochs(_start, count, true);
    }

    /// @notice Returns whether a darknode is scheduled to become registered
    /// at next epoch.
    /// @param _darknodeID The ID of the darknode to return
    function isPendingRegistration(address _darknodeID) external view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        return registeredAt != 0 && registeredAt > currentEpoch.blocknumber;
    }

    /// @notice Returns if a darknode is in the pending deregistered state. In
    /// this state a darknode is still considered registered.
    function isPendingDeregistration(address _darknodeID) external view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpoch.blocknumber;
    }

    /// @notice Returns if a darknode is in the deregistered state.
    function isDeregistered(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt <= currentEpoch.blocknumber;
    }

    /// @notice Returns if a darknode can be deregistered. This is true if the
    /// darknodes is in the registered state and has not attempted to
    /// deregister yet.
    function isDeregisterable(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        // The Darknode is currently in the registered state and has not been
        // transitioned to the pending deregistration, or deregistered, state
        return isRegistered(_darknodeID) && deregisteredAt == 0;
    }

    /// @notice Returns if a darknode is in the refunded state. This is true
    /// for darknodes that have never been registered, or darknodes that have
    /// been deregistered and refunded.
    function isRefunded(address _darknodeID) public view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }

    /// @notice Returns if a darknode is refundable. This is true for darknodes
    /// that have been in the deregistered state for one full epoch.
    function isRefundable(address _darknodeID) public view returns (bool) {
        return isDeregistered(_darknodeID) && store.darknodeDeregisteredAt(_darknodeID) <= previousEpoch.blocknumber;
    }

    /// @notice Returns if a darknode is in the registered state.
    function isRegistered(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, currentEpoch);
    }

    /// @notice Returns if a darknode was in the registered state last epoch.
    function isRegisteredInPreviousEpoch(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, previousEpoch);
    }

    /// @notice Returns if a darknode was in the registered state for a given
    /// epoch.
    /// @param _darknodeID The ID of the darknode
    /// @param _epoch One of currentEpoch, previousEpoch
    function isRegisteredInEpoch(address _darknodeID, Epoch _epoch) private view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= _epoch.blocknumber;
        bool notDeregistered = deregisteredAt == 0 || deregisteredAt > _epoch.blocknumber;
        // The Darknode has been registered and has not yet been deregistered,
        // although it might be pending deregistration
        return registered && notDeregistered;
    }

    /// @notice Returns a list of darknodes registered for either the current
    /// or the previous epoch. See `getDarknodes` for documentation on the
    /// parameters `_start` and `_count`.
    /// @param _usePreviousEpoch If true, use the previous epoch, otherwise use
    ///        the current epoch.
    function getDarknodesFromEpochs(address _start, uint256 _count, bool _usePreviousEpoch) private view returns (address[]) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }

        address[] memory nodes = new address[](count);

        // Begin with the first node in the list
        uint256 n = 0;
        address next = _start;
        if (next == 0x0) {
            next = store.begin();
        }

        // Iterate until all registered Darknodes have been collected
        while (n < count) {
            if (next == 0x0) {
                break;
            }
            // Only include Darknodes that are currently registered
            bool includeNext;
            if (_usePreviousEpoch) {
                includeNext = isRegisteredInPreviousEpoch(next);
            } else {
                includeNext = isRegistered(next);
            }
            if (!includeNext) {
                next = store.next(next);
                continue;
            }
            nodes[n] = next;
            next = store.next(next);
            n += 1;
        }
        return nodes;
    }
}

/// @notice The BrokerVerifier interface defines the functions that a settlement
/// layer&#39;s broker verifier contract must implement.
interface BrokerVerifier {

    /// @notice The function signature that will be called when a trader opens
    /// an order.
    ///
    /// @param _trader The trader requesting the withdrawal.
    /// @param _signature The 65-byte signature from the broker.
    /// @param _orderID The 32-byte order ID.
    function verifyOpenSignature(
        address _trader,
        bytes _signature,
        bytes32 _orderID
    ) external returns (bool);
}

/// @notice The Settlement interface defines the functions that a settlement
/// layer must implement.
/// Docs: https://github.com/republicprotocol/republic-sol/blob/nightly/docs/05-settlement.md
interface Settlement {
    function submitOrder(
        bytes _details,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external;

    function submissionGasPriceLimit() external view returns (uint256);

    function settle(
        bytes32 _buyID,
        bytes32 _sellID
    ) external;

    /// @notice orderStatus should return the status of the order, which should
    /// be:
    ///     0  - Order not seen before
    ///     1  - Order details submitted
    ///     >1 - Order settled, or settlement no longer possible
    function orderStatus(bytes32 _orderID) external view returns (uint8);
}

/// @notice SettlementRegistry allows a Settlement layer to register the
/// contracts used for match settlement and for broker signature verification.
contract SettlementRegistry is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    struct SettlementDetails {
        bool registered;
        Settlement settlementContract;
        BrokerVerifier brokerVerifierContract;
    }

    // Settlement IDs are 64-bit unsigned numbers
    mapping(uint64 => SettlementDetails) public settlementDetails;

    // Events
    event LogSettlementRegistered(uint64 settlementID, Settlement settlementContract, BrokerVerifier brokerVerifierContract);
    event LogSettlementUpdated(uint64 settlementID, Settlement settlementContract, BrokerVerifier brokerVerifierContract);
    event LogSettlementDeregistered(uint64 settlementID);

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    constructor(string _VERSION) public {
        VERSION = _VERSION;
    }

    /// @notice Returns the settlement contract of a settlement layer.
    function settlementRegistration(uint64 _settlementID) external view returns (bool) {
        return settlementDetails[_settlementID].registered;
    }

    /// @notice Returns the settlement contract of a settlement layer.
    function settlementContract(uint64 _settlementID) external view returns (Settlement) {
        return settlementDetails[_settlementID].settlementContract;
    }

    /// @notice Returns the broker verifier contract of a settlement layer.
    function brokerVerifierContract(uint64 _settlementID) external view returns (BrokerVerifier) {
        return settlementDetails[_settlementID].brokerVerifierContract;
    }

    /// @param _settlementID A unique 64-bit settlement identifier.
    /// @param _settlementContract The address to use for settling matches.
    /// @param _brokerVerifierContract The decimals to use for verifying
    ///        broker signatures.
    function registerSettlement(uint64 _settlementID, Settlement _settlementContract, BrokerVerifier _brokerVerifierContract) public onlyOwner {
        bool alreadyRegistered = settlementDetails[_settlementID].registered;
        
        settlementDetails[_settlementID] = SettlementDetails({
            registered: true,
            settlementContract: _settlementContract,
            brokerVerifierContract: _brokerVerifierContract
        });

        if (alreadyRegistered) {
            emit LogSettlementUpdated(_settlementID, _settlementContract, _brokerVerifierContract);
        } else {
            emit LogSettlementRegistered(_settlementID, _settlementContract, _brokerVerifierContract);
        }
    }

    /// @notice Deregisteres a settlement layer, clearing the details.
    /// @param _settlementID The unique 64-bit settlement identifier.
    function deregisterSettlement(uint64 _settlementID) external onlyOwner {
        require(settlementDetails[_settlementID].registered, "not registered");

        delete settlementDetails[_settlementID];

        emit LogSettlementDeregistered(_settlementID);
    }
}

/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

library Utils {

    /**
     * @notice Converts a number to its string/bytes representation
     *
     * @param _v the uint to convert
     */
    function uintToBytes(uint256 _v) internal pure returns (bytes) {
        uint256 v = _v;
        if (v == 0) {
            return "0";
        }

        uint256 digits = 0;
        uint256 v2 = v;
        while (v2 > 0) {
            v2 /= 10;
            digits += 1;
        }

        bytes memory result = new bytes(digits);

        for (uint256 i = 0; i < digits; i++) {
            result[digits - i - 1] = bytes1((v % 10) + 48);
            v /= 10;
        }

        return result;
    }

    /**
     * @notice Retrieves the address from a signature
     *
     * @param _hash the message that was signed (any length of bytes)
     * @param _signature the signature (65 bytes)
     */
    function addr(bytes _hash, bytes _signature) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory encoded = abi.encodePacked(prefix, uintToBytes(_hash.length), _hash);
        bytes32 prefixedHash = keccak256(encoded);

        return ECRecovery.recover(prefixedHash, _signature);
    }

}

/// @notice The Orderbook contract stores the state and priority of orders and
/// allows the Darknodes to easily reach consensus. Eventually, this contract
/// will only store a subset of order states, such as cancellation, to improve
/// the throughput of orders.
contract Orderbook is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    /// @notice OrderState enumerates the possible states of an order. All
    /// orders default to the Undefined state.
    enum OrderState {Undefined, Open, Confirmed, Canceled}

    /// @notice Order stores a subset of the public data associated with an order.
    struct Order {
        OrderState state;     // State of the order
        address trader;       // Trader that owns the order
        address confirmer;    // Darknode that confirmed the order in a match
        uint64 settlementID;  // The settlement that signed the order opening
        uint256 priority;     // Logical time priority of this order
        uint256 blockNumber;  // Block number of the most recent state change
        bytes32 matchedOrder; // Order confirmed in a match with this order
    }

    RepublicToken public ren;
    DarknodeRegistry public darknodeRegistry;
    SettlementRegistry public settlementRegistry;

    bytes32[] private orderbook;

    // Order details are exposed through directly accessing this mapping, or
    // through the getter functions below for each of the order&#39;s fields.
    mapping(bytes32 => Order) public orders;

    event LogFeeUpdated(uint256 previousFee, uint256 nextFee);
    event LogDarknodeRegistryUpdated(DarknodeRegistry previousDarknodeRegistry, DarknodeRegistry nextDarknodeRegistry);

    /// @notice Only allow registered dark nodes.
    modifier onlyDarknode(address _sender) {
        require(darknodeRegistry.isRegistered(address(_sender)), "must be registered darknode");
        _;
    }

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    /// @param _renAddress The address of the RepublicToken contract.
    /// @param _darknodeRegistry The address of the DarknodeRegistry contract.
    /// @param _settlementRegistry The address of the SettlementRegistry
    ///        contract.
    constructor(
        string _VERSION,
        RepublicToken _renAddress,
        DarknodeRegistry _darknodeRegistry,
        SettlementRegistry _settlementRegistry
    ) public {
        VERSION = _VERSION;
        ren = _renAddress;
        darknodeRegistry = _darknodeRegistry;
        settlementRegistry = _settlementRegistry;
    }

    /// @notice Allows the owner to update the address of the DarknodeRegistry
    /// contract.
    function updateDarknodeRegistry(DarknodeRegistry _newDarknodeRegistry) external onlyOwner {
        emit LogDarknodeRegistryUpdated(darknodeRegistry, _newDarknodeRegistry);
        darknodeRegistry = _newDarknodeRegistry;
    }

    /// @notice Open an order in the orderbook. The order must be in the
    /// Undefined state.
    ///
    /// @param _signature Signature of the message that defines the trader. The
    ///        message is "Republic Protocol: open: {orderId}".
    /// @param _orderID The hash of the order.
    function openOrder(uint64 _settlementID, bytes _signature, bytes32 _orderID) external {
        require(orders[_orderID].state == OrderState.Undefined, "invalid order status");

        address trader = msg.sender;

        // Verify the order signature
        require(settlementRegistry.settlementRegistration(_settlementID), "settlement not registered");
        BrokerVerifier brokerVerifier = settlementRegistry.brokerVerifierContract(_settlementID);
        require(brokerVerifier.verifyOpenSignature(trader, _signature, _orderID), "invalid broker signature");

        orders[_orderID] = Order({
            state: OrderState.Open,
            trader: trader,
            confirmer: 0x0,
            settlementID: _settlementID,
            priority: orderbook.length + 1,
            blockNumber: block.number,
            matchedOrder: 0x0
        });

        orderbook.push(_orderID);
    }

    /// @notice Confirm an order match between orders. The confirmer must be a
    /// registered Darknode and the orders must be in the Open state. A
    /// malicious confirmation by a Darknode will result in a bond slash of the
    /// Darknode.
    ///
    /// @param _orderID The hash of the order.
    /// @param _matchedOrderID The hashes of the matching order.
    function confirmOrder(bytes32 _orderID, bytes32 _matchedOrderID) external onlyDarknode(msg.sender) {
        require(orders[_orderID].state == OrderState.Open, "invalid order status");
        require(orders[_matchedOrderID].state == OrderState.Open, "invalid order status");

        orders[_orderID].state = OrderState.Confirmed;
        orders[_orderID].confirmer = msg.sender;
        orders[_orderID].matchedOrder = _matchedOrderID;
        orders[_orderID].blockNumber = block.number;

        orders[_matchedOrderID].state = OrderState.Confirmed;
        orders[_matchedOrderID].confirmer = msg.sender;
        orders[_matchedOrderID].matchedOrder = _orderID;
        orders[_matchedOrderID].blockNumber = block.number;
    }

    /// @notice Cancel an open order in the orderbook. An order can be cancelled
    /// by the trader who opened the order, or by the broker verifier contract.
    /// This allows the settlement layer to implement their own logic for
    /// cancelling orders without trader interaction (e.g. to ban a trader from
    /// a specific darkpool, or to use multiple order-matching platforms)
    ///
    /// @param _orderID The hash of the order.
    function cancelOrder(bytes32 _orderID) external {
        require(orders[_orderID].state == OrderState.Open, "invalid order state");

        // Require the msg.sender to be the trader or the broker verifier
        address brokerVerifier = address(settlementRegistry.brokerVerifierContract(orders[_orderID].settlementID));
        require(msg.sender == orders[_orderID].trader || msg.sender == brokerVerifier, "not authorized");

        orders[_orderID].state = OrderState.Canceled;
        orders[_orderID].blockNumber = block.number;
    }

    /// @notice returns status of the given orderID.
    function orderState(bytes32 _orderID) external view returns (OrderState) {
        return orders[_orderID].state;
    }

    /// @notice returns a list of matched orders to the given orderID.
    function orderMatch(bytes32 _orderID) external view returns (bytes32) {
        return orders[_orderID].matchedOrder;
    }

    /// @notice returns the priority of the given orderID.
    /// The priority is the index of the order in the orderbook.
    function orderPriority(bytes32 _orderID) external view returns (uint256) {
        return orders[_orderID].priority;
    }

    /// @notice returns the trader of the given orderID.
    /// Trader is the one who signs the message and does the actual trading.
    function orderTrader(bytes32 _orderID) external view returns (address) {
        return orders[_orderID].trader;
    }

    /// @notice returns the darknode address which confirms the given orderID.
    function orderConfirmer(bytes32 _orderID) external view returns (address) {
        return orders[_orderID].confirmer;
    }

    /// @notice returns the block number when the order being last modified.
    function orderBlockNumber(bytes32 _orderID) external view returns (uint256) {
        return orders[_orderID].blockNumber;
    }

    /// @notice returns the block depth of the orderId
    function orderDepth(bytes32 _orderID) external view returns (uint256) {
        if (orders[_orderID].blockNumber == 0) {
            return 0;
        }
        return (block.number - orders[_orderID].blockNumber);
    }

    /// @notice returns the number of orders in the orderbook
    function ordersCount() external view returns (uint256) {
        return orderbook.length;
    }

    /// @notice returns order details of the orders starting from the offset.
    function getOrders(uint256 _offset, uint256 _limit) external view returns (bytes32[], address[], uint8[]) {
        if (_offset >= orderbook.length) {
            return;
        }

        // If the provided limit is more than the number of orders after the offset,
        // decrease the limit
        uint256 limit = _limit;
        if (_offset + limit > orderbook.length) {
            limit = orderbook.length - _offset;
        }

        bytes32[] memory orderIDs = new bytes32[](limit);
        address[] memory traderAddresses = new address[](limit);
        uint8[] memory states = new uint8[](limit);

        for (uint256 i = 0; i < limit; i++) {
            bytes32 order = orderbook[i + _offset];
            orderIDs[i] = order;
            traderAddresses[i] = orders[order].trader;
            states[i] = uint8(orders[order].state);
        }

        return (orderIDs, traderAddresses, states);
    }
}

/// @notice A library for calculating and verifying order match details
library SettlementUtils {

    struct OrderDetails {
        uint64 settlementID;
        uint64 tokens;
        uint256 price;
        uint256 volume;
        uint256 minimumVolume;
    }

    /// @notice Calculates the ID of the order.
    /// @param details Order details that are not required for settlement
    ///        execution. They are combined as a single byte array.
    /// @param order The order details required for settlement execution.
    function hashOrder(bytes details, OrderDetails memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                details,
                order.settlementID,
                order.tokens,
                order.price,
                order.volume,
                order.minimumVolume
            )
        );
    }

    /// @notice Verifies that two orders match when considering the tokens,
    /// price, volumes / minimum volumes and settlement IDs. verifyMatchDetails is used
    /// my the DarknodeSlasher to verify challenges. Settlement layers may also
    /// use this function.
    /// @dev When verifying two orders for settlement, you should also:
    ///   1) verify the orders have been confirmed together
    ///   2) verify the orders&#39; traders are distinct
    /// @param _buy The buy order details.
    /// @param _sell The sell order details.
    function verifyMatchDetails(OrderDetails memory _buy, OrderDetails memory _sell) internal pure returns (bool) {

        // Buy and sell tokens should match
        if (!verifyTokens(_buy.tokens, _sell.tokens)) {
            return false;
        }

        // Buy price should be greater than sell price
        if (_buy.price < _sell.price) {
            return false;
        }

        // // Buy volume should be greater than sell minimum volume
        if (_buy.volume < _sell.minimumVolume) {
            return false;
        }

        // Sell volume should be greater than buy minimum volume
        if (_sell.volume < _buy.minimumVolume) {
            return false;
        }

        // Require that the orders were submitted to the same settlement layer
        if (_buy.settlementID != _sell.settlementID) {
            return false;
        }

        return true;
    }

    /// @notice Verifies that two token requirements can be matched and that the
    /// tokens are formatted correctly.
    /// @param _buyTokens The buy token details.
    /// @param _sellToken The sell token details.
    function verifyTokens(uint64 _buyTokens, uint64 _sellToken) internal pure returns (bool) {
        return ((
                uint32(_buyTokens) == uint32(_sellToken >> 32)) && (
                uint32(_sellToken) == uint32(_buyTokens >> 32)) && (
                uint32(_buyTokens >> 32) <= uint32(_buyTokens))
        );
    }
}

/// @notice Allows order confirmations to be challenged, penalizing darknodes
/// who have confirmed two mismatched orders.
contract DarknodeSlasher is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    DarknodeRegistry public trustedDarknodeRegistry;
    Orderbook public trustedOrderbook;

    mapping(bytes32 => bool) public orderSubmitted;
    mapping(bytes32 => mapping(bytes32 => bool)) public challengeSubmitted;
    mapping(bytes32 => SettlementUtils.OrderDetails) public orderDetails;
    mapping(bytes32 => address) public challengers;

    /// @notice Restricts calling a function to registered or deregistered darknodes
    modifier onlyDarknode() {
        require(
            trustedDarknodeRegistry.isRegistered(msg.sender) ||
            trustedDarknodeRegistry.isDeregistered(msg.sender),
            "must be darknode");
        _;
    }

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    /// @param _darknodeRegistry The address of the DarknodeRegistry contract
    /// @param _orderbook The address of the Orderbook contract
    constructor(string _VERSION, DarknodeRegistry _darknodeRegistry, Orderbook _orderbook) public {
        VERSION = _VERSION;
        trustedDarknodeRegistry = _darknodeRegistry;
        trustedOrderbook = _orderbook;
    }

    /// @notice Submits the details for one of the two orders of a challenge.
    /// The details are required to verify that the orders should not have been
    /// matched together. The parameters are the same as `submitOrder` in the
    /// Settlement interface.
    function submitChallengeOrder(
        bytes details,
        uint64 settlementID,
        uint64 tokens,
        uint256 price,
        uint256 volume,
        uint256 minimumVolume
    ) external onlyDarknode {
        SettlementUtils.OrderDetails memory order = SettlementUtils.OrderDetails({
            settlementID: settlementID,
            tokens: tokens,
            price: price,
            volume: volume,
            minimumVolume: minimumVolume
        });

        // Hash the order
        bytes32 orderID = SettlementUtils.hashOrder(details, order);

        // Check the order details haven&#39;t already been submitted
        require(!orderSubmitted[orderID], "already submitted");

        // Store the order details and the challenger
        orderDetails[orderID] = order;
        challengers[orderID] = msg.sender;
        orderSubmitted[orderID] = true;
    }

    /// @notice Submits a challenge for two orders. This challenge is a claim
    /// that two orders were confirmed that should not have been confirmed.
    /// Before calling this method, `submitOrder` must be called for both the
    /// `_buyID` and `_sellID` orders.
    ///
    /// @param _buyID The order ID of a buy order that was maliciously
    ///        confirmed with the `_sellID`.
    /// @param _sellID The order ID of a sell order that was maliciously
    ///        confirmed with the `_buyID`.
    function submitChallenge(bytes32 _buyID, bytes32 _sellID) external {
        // Check that the match hasn&#39;t been submitted previously
        require(!challengeSubmitted[_buyID][_sellID], "already challenged");

        // Check that the order details have been submitted
        require(orderSubmitted[_buyID], "details unavailable");
        require(orderSubmitted[_sellID], "details unavailable");

        // Check that the orders were submitted to one another
        require(trustedOrderbook.orderMatch(_buyID) == _sellID, "unconfirmed orders");

        // The challenge is valid if 1) the order details (prices, volumes,
        // settlement IDs or tokens) are not compatible, or if 2) the orders
        // where submitted by the same trader.
        bool mismatchedDetails = !SettlementUtils.verifyMatchDetails(orderDetails[_buyID], orderDetails[_sellID]);
        bool nondistinctTrader = trustedOrderbook.orderTrader(_buyID) == trustedOrderbook.orderTrader(_sellID);
        require(mismatchedDetails || nondistinctTrader, "invalid challenge");

        // Retrieve the guilty confirmer
        address confirmer = trustedOrderbook.orderConfirmer(_buyID);

        // Store that challenge has been submitted
        challengeSubmitted[_buyID][_sellID] = true;
        challengeSubmitted[_sellID][_buyID] = true;

        // Slash the bond of the confirmer
        trustedDarknodeRegistry.slash(confirmer, challengers[_buyID], challengers[_sellID]);
    }
}