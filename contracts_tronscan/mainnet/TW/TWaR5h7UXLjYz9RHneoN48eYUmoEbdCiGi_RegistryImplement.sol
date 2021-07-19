//SourceUnit: flat_Registry.sol

/**
 *  :::==== :::====  :::  === :::===== :::  === :::===  :::==== 
 *  :::==== :::  === :::  === :::      :::  === :::     :::  ===
 *    ===   =======  ===  === ======   ===  ===  =====  ===  ===
 *    ===   === ===  ===  === ===      ===  ===     === ===  ===
 *    ===   ===  ===  ======  ========  ======  ======  ======= 
 */

pragma solidity ^0.6.0;

/**
 * @dev Interface of the TRC20 standard as defined in the TIP.
 */
interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.6.0;

interface RegistryClone {
    function syncAttributeValue(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) external;
}

contract Registry {
    struct AttributeData {
        uint256 value;
        bytes32 notes;
        address adminAddr;
        uint256 timestamp;
    }

    // never remove any storage variables
    address public owner;
    address public pendingOwner;
    bool initialized;

    // Stores arbitrary attributes for users. An example use case is an ITRC20
    // token that requires its users to go through a KYC/AML check - in this case
    // a validator can set an account's "hasPassedKYC/AML" attribute to 1 to indicate
    // that account can use the token. This mapping stores that value (1, in the
    // example) as well as which validator last set the value and at what time,
    // so that e.g. the check can be renewed at appropriate intervals.
    mapping(address => mapping(bytes32 => AttributeData)) attributes;
    // The logic governing who is allowed to set what attributes is abstracted as
    // this accessManager, so that it may be replaced by the owner as needed
    bytes32 constant WRITE_PERMISSION = keccak256("canWriteTo-");
    mapping(bytes32 => RegistryClone[]) subscribers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetAttribute(address indexed who, bytes32 attribute, uint256 value, bytes32 notes, address indexed adminAddr);
    event SetManager(address indexed oldManager, address indexed newManager);
    event StartSubscription(bytes32 indexed attribute, RegistryClone indexed subscriber);
    event StopSubscription(bytes32 indexed attribute, RegistryClone indexed subscriber);

    /**
    * @dev sets the original `owner` of the contract to the sender
    * at construction. Must then be reinitialized 
    */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
        initialized = true;
    }

    // Allows a write if either a) the writer is that Registry's owner, or
    // b) the writer is writing to attribute foo and that writer already has
    // the canWriteTo-foo attribute set (in that same Registry)
    function confirmWrite(bytes32 _attribute, address _admin) internal view returns (bool) {
        return (_admin == owner || hasAttribute(_admin, keccak256(abi.encodePacked(WRITE_PERMISSION ^ _attribute))));
    }

    // Writes are allowed only if the accessManager approves
    function setAttribute(
        address _who,
        bytes32 _attribute,
        uint256 _value,
        bytes32 _notes
    ) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, _notes, msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, _notes, msg.sender);

        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    function subscribe(bytes32 _attribute, RegistryClone _syncer) external onlyOwner {
        subscribers[_attribute].push(_syncer);
        emit StartSubscription(_attribute, _syncer);
    }

    function unsubscribe(bytes32 _attribute, uint256 _index) external onlyOwner {
        uint256 length = subscribers[_attribute].length;
        require(_index < length);
        emit StopSubscription(_attribute, subscribers[_attribute][_index]);
        subscribers[_attribute][_index] = subscribers[_attribute][length - 1];
        subscribers[_attribute].pop();
    }

    function subscriberCount(bytes32 _attribute) public view returns (uint256) {
        return subscribers[_attribute].length;
    }

    function setAttributeValue(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, "", msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, "", msg.sender);
        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    // Returns true if the uint256 value stored for this attribute is non-zero
    function hasAttribute(address _who, bytes32 _attribute) public view returns (bool) {
        return attributes[_who][_attribute].value != 0;
    }

    // Returns the exact value of the attribute, as well as its metadata
    function getAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (
            uint256,
            bytes32,
            address,
            uint256
        )
    {
        AttributeData memory data = attributes[_who][_attribute];
        return (data.value, data.notes, data.adminAddr, data.timestamp);
    }

    function getAttributeValue(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].value;
    }

    function getAttributeAdminAddr(address _who, bytes32 _attribute) public view returns (address) {
        return attributes[_who][_attribute].adminAddr;
    }

    function getAttributeTimestamp(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].timestamp;
    }

    function syncAttribute(
        bytes32 _attribute,
        uint256 _startIndex,
        address[] calldata _addresses
    ) external {
        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > _startIndex) {
            RegistryClone target = targets[index];
            for (uint256 i = _addresses.length; i-- > 0; ) {
                address who = _addresses[i];
                target.syncAttributeValue(who, _attribute, attributes[who][_attribute].value);
            }
        }
    }

    function reclaimTrx(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(ITRC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
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