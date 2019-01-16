/**
 *  The Consumer Contract Wallet
 *  Copyright (C) 2018 Token Group Ltd
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.4.25;

/// @title Oracle converts ERC20 token amounts into equivalent ether amounts based on cryptocurrency exchange rates.
interface IOracle {
    function convert(address, uint) external view returns (bool, uint);
}

/// @title Ownable has an owner address and provides basic authorization control functions.
/// This contract is modified version of the MIT OpenZepplin Ownable contract
/// This contract doesn&#39;t allow for multiple changeOwner operations
/// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
contract Ownable {
    event TransferredOwnership(address _from, address _to);

    address private _owner;
    bool private _isTransferable;

    /// @dev Constructor sets the original owner of the contract and whether or not it is one time transferable.
    constructor(address _account, bool _transferable) internal {
        _owner = _account;
        _isTransferable = _transferable;
        emit TransferredOwnership(address(0), _account);
    }

    /// @dev Reverts if called by any account other than the owner.
    modifier onlyOwner() {
        require(_isOwner(), "sender is not an owner");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a new address.
    /// @param _account address to transfer ownership to.
    function transferOwnership(address _account) external onlyOwner {
        // Require that the ownership is transferable.
        require(_isTransferable, "ownership is not transferable");
        // Require that the new owner is not the zero address.
        require(_account != address(0), "owner cannot be set to zero address");
        // Set the transferable flag to false.
        _isTransferable = false;
        // Emit the ownership transfer event.
        emit TransferredOwnership(_owner, _account);
        // Set the owner to the provided address.
        _owner = _account;
    }

    /// @dev Allows the current owner to relinquish control of the contract.
    /// @notice Renouncing to ownership will leave the contract without an owner and unusable.
    /// It will not be possible to call the functions with the `onlyOwner` modifier anymore.
    function renounceOwnership() public onlyOwner {
        // Require that the ownership is transferable.
        require(_isTransferable, "ownership is not transferable");
        emit TransferredOwnership(_owner, address(0));
        // note that this could be terminal
        _owner = address(0);
    }

    /// @return the address of the owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @return true if the ownership is transferable.
    function isTransferable() public view returns (bool) {
        return _isTransferable;
    }

    /// @return true if sender is the owner of the contract.
    function _isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }
}

/// @title The Controller interface provides access to an external list of controllers.
interface IController {
    function isController(address) external view returns (bool);
}

/// @title Controller stores a list of controller addresses that can be used for authentication in other contracts.
contract Controller is IController {
    event AddedController(address _sender, address _controller);
    event RemovedController(address _sender, address _controller);

    mapping (address => bool) private _isController;
    uint private _controllerCount;

    /// @dev Constructor initializes the list of controllers with the provided address.
    /// @param _account address to add to the list of controllers.
    constructor(address _account) public {
        _addController(_account);
    }

    /// @dev Checks if message sender is a controller.
    modifier onlyController() {
        require(isController(msg.sender), "sender is not a controller");
        _;
    }

    /// @dev Add a new controller to the list of controllers.
    /// @param _account address to add to the list of controllers.
    function addController(address _account) external onlyController {
        _addController(_account);
    }

    /// @dev Remove a controller from the list of controllers.
    /// @param _account address to remove from the list of controllers.
    function removeController(address _account) external onlyController {
        _removeController(_account);
    }

    /// @return true if the provided account is a controller.
    function isController(address _account) public view returns (bool) {
        return _isController[_account];
    }

    /// @return the current number of controllers.
    function controllerCount() public view returns (uint) {
        return _controllerCount;
    }

    /// @dev Internal-only function that adds a new controller.
    function _addController(address _account) internal {
        require(!_isController[_account], "provided account is already a controller");
        _isController[_account] = true;
        _controllerCount++;
        emit AddedController(msg.sender, _account);
    }

    /// @dev Internal-only function that removes an existing controller.
    function _removeController(address _account) internal {
        require(_isController[_account], "provided account is not a controller");
        require(_controllerCount > 1, "cannot remove the last controller");
        _isController[_account] = false;
        _controllerCount--;
        emit RemovedController(msg.sender, _account);
    }
}

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant MULTIHASH_INTERFACE_ID = 0xe89401a1;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event MultihashChanged(bytes32 indexed node, bytes hash);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
        bytes multihash;
    }

    ENS ens;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The ENS registrar contract.
     */
    constructor(ENS ensAddr) public {
        ens = ensAddr;
    }

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

    /**
     * Sets the content hash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        emit ContentChanged(node, hash);
    }

    /**
     * Sets the multihash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The multihash to set
     */
    function setMultihash(bytes32 node, bytes hash) public only_owner(node) {
        records[node].multihash = hash;
        emit MultihashChanged(node, hash);
    }

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        emit NameChanged(node, name);
    }

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x, y the X and Y coordinates of the curve point for the public key.
     */
    function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

    /**
     * Returns the content hash associated with an ENS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The ENS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

    /**
     * Returns the multihash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated multihash.
     */
    function multihash(bytes32 node) public view returns (bytes) {
        return records[node].multihash;
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

    /**
     * Returns true if the resolver implements the interface specified by the provided hash.
     * @param interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == MULTIHASH_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}

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
        require(b > 0); // Solidity only automatically asserts when dividing by 0
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

/// @title ERC20 interface is a subset of the ERC20 specification.
interface ERC20 {
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}


/// @title ERC165 interface specifies a standard way of querying if a contract implements an interface.
interface ERC165 {
    function supportsInterface(bytes4) external view returns (bool);
}


/// @title Resolver returns the controller contract address.
interface IResolver {
    function addr(bytes32) external view returns (address);
}

/// @title Controllable implements access control functionality based on a controller set in ENS.
contract Controllable {
    /// @dev _ENS points to the ENS registry smart contract.
    ENS private _ENS;
    /// @dev Is the registered ENS name of the controller contract.
    bytes32 private _node;

    /// @dev Constructor initializes the controller contract object.
    /// @param _ens is the address of the ENS.
    /// @param _controllerName is the ENS name of the Controller.
    constructor(address _ens, bytes32 _controllerName) internal {
        _ENS = ENS(_ens);
        _node = _controllerName;
    }

    /// @dev Checks if message sender is the controller.
    modifier onlyController() {
        require(_isController(msg.sender), "sender is not a controller");
        _;
    }

    /// @return true if the provided account is the controller.
    function _isController(address _account) internal view returns (bool) {
        return IController(IResolver(_ENS.resolver(_node)).addr(_node)).isController(_account);
    }
}

/// @title Whitelist provides payee-whitelist functionality.
contract Whitelist is Controllable, Ownable {
    event AddedToWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistAddition(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistAddition(address _sender);

    event RemovedFromWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistRemoval(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistRemoval(address _sender);

    mapping(address => bool) public isWhitelisted;
    address[] private _pendingWhitelistAddition;
    address[] private _pendingWhitelistRemoval;
    bool public submittedWhitelistAddition;
    bool public submittedWhitelistRemoval;
    bool public initializedWhitelist;

    /// @dev Check if the provided addresses contain the owner or the zero-address address.
    modifier hasNoOwnerOrZeroAddress(address[] _addresses) {
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != owner(), "provided whitelist contains the owner address");
            require(_addresses[i] != address(0), "provided whitelist contains the zero address");
        }
        _;
    }

    /// @dev Check that neither addition nor removal operations have already been submitted.
    modifier noActiveSubmission() {
        require(!submittedWhitelistAddition && !submittedWhitelistRemoval, "whitelist operation has already been submitted");
        _;
    }

    /// @dev Getter for pending addition array.
    function pendingWhitelistAddition() external view returns(address[]) {
        return _pendingWhitelistAddition;
    }

    /// @dev Getter for pending removal array.
    function pendingWhitelistRemoval() external view returns(address[]) {
        return _pendingWhitelistRemoval;
    }

    /// @dev Getter for pending addition/removal array hash.
    function pendingWhitelistHash(address[] _pendingWhitelist) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_pendingWhitelist));
    }

    /// @dev Add initial addresses to the whitelist.
    /// @param _addresses are the Ethereum addresses to be whitelisted.
    function initializeWhitelist(address[] _addresses) external onlyOwner hasNoOwnerOrZeroAddress(_addresses) {
        // Require that the whitelist has not been initialized.
        require(!initializedWhitelist, "whitelist has already been initialized");
        // Add each of the provided addresses to the whitelist.
        for (uint i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
        }
        initializedWhitelist = true;
        // Emit the addition event.
        emit AddedToWhitelist(msg.sender, _addresses);
    }

    /// @dev Add addresses to the whitelist.
    /// @param _addresses are the Ethereum addresses to be whitelisted.
    function submitWhitelistAddition(address[] _addresses) external onlyOwner noActiveSubmission hasNoOwnerOrZeroAddress(_addresses)  {
        // Require that the whitelist has been initialized.
        require(initializedWhitelist, "whitelist has not been initialized");
        // Set the provided addresses to the pending addition addresses.
        _pendingWhitelistAddition = _addresses;
        // Flag the operation as submitted.
        submittedWhitelistAddition = true;
        // Emit the submission event.
        emit SubmittedWhitelistAddition(_addresses, pendingWhitelistHash(_pendingWhitelistAddition));
    }

    /// @dev Confirm pending whitelist addition.
    function confirmWhitelistAddition(bytes32 _hash) external onlyController {
        // Require that the whitelist addition has been submitted.
        require(submittedWhitelistAddition, "whitelist addition has not been submitted");

        // Require that confirmation hash and the hash of the pending whitelist addition match
        require(_hash == pendingWhitelistHash(_pendingWhitelistAddition), "hash of the pending white list addition do not match");

        // Whitelist pending addresses.
        for (uint i = 0; i < _pendingWhitelistAddition.length; i++) {
            isWhitelisted[_pendingWhitelistAddition[i]] = true;
        }
        // Emit the addition event.
        emit AddedToWhitelist(msg.sender, _pendingWhitelistAddition);
        // Reset pending addresses.
        delete _pendingWhitelistAddition;
        // Reset the submission flag.
        submittedWhitelistAddition = false;
    }

    /// @dev Cancel pending whitelist addition.
    function cancelWhitelistAddition(bytes32 _hash) external onlyController {
        // Require that confirmation hash and the hash of the pending whitelist addition match
        require(_hash == pendingWhitelistHash(_pendingWhitelistAddition), "hash of the pending white list addition does not match");
        // Reset pending addresses.
        delete _pendingWhitelistAddition;
        // Reset the submitted operation flag.
        submittedWhitelistAddition = false;
        // Emit the cancellation event.
        emit CancelledWhitelistAddition(msg.sender);
    }

    /// @dev Remove addresses from the whitelist.
    /// @param _addresses are the Ethereum addresses to be removed.
    function submitWhitelistRemoval(address[] _addresses) external onlyOwner noActiveSubmission {
        // Add the provided addresses to the pending addition list.
        _pendingWhitelistRemoval = _addresses;
        // Flag the operation as submitted.
        submittedWhitelistRemoval = true;
        // Emit the submission event.
        emit SubmittedWhitelistRemoval(_addresses, pendingWhitelistHash(_pendingWhitelistRemoval));
    }

    /// @dev Confirm pending removal of whitelisted addresses.
    function confirmWhitelistRemoval(bytes32 _hash) external onlyController {
        // Require that the pending whitelist is not empty and the operation has been submitted.
        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");
        require(_pendingWhitelistRemoval.length > 0, "pending whitelist removal is empty");
        // Require that confirmation hash and the hash of the pending whitelist removal match
        require(_hash == pendingWhitelistHash(_pendingWhitelistRemoval), "hash of the pending white list removal does not match the confirmed hash");
        // Remove pending addresses.
        for (uint i = 0; i < _pendingWhitelistRemoval.length; i++) {
            isWhitelisted[_pendingWhitelistRemoval[i]] = false;
        }
        // Emit the removal event.
        emit RemovedFromWhitelist(msg.sender, _pendingWhitelistRemoval);
        // Reset pending addresses.
        delete _pendingWhitelistRemoval;
        // Reset the submission flag.
        submittedWhitelistRemoval = false;
    }

    /// @dev Cancel pending removal of whitelisted addresses.
    function cancelWhitelistRemoval(bytes32 _hash) external onlyController {

        // Require that confirmation hash and the hash of the pending whitelist removal match
        require(_hash == pendingWhitelistHash(_pendingWhitelistRemoval), "hash of the pending white list removal do not match");

        // Reset pending addresses.
        delete _pendingWhitelistRemoval;
        // Reset the submitted operation flag.
        submittedWhitelistRemoval = false;
        // Emit the cancellation event.
        emit CancelledWhitelistRemoval(msg.sender);
    }
}


//// @title SpendLimit provides daily spend limit functionality.
contract SpendLimit is Controllable, Ownable {
    event SetSpendLimit(address _sender, uint _amount);
    event SubmittedSpendLimitChange(uint _amount);
    event CancelledSpendLimitChange(address _sender);

    using SafeMath for uint256;

    uint public spendLimit;
    uint private _spendLimitDay;
    uint private _spendAvailable;

    uint public pendingSpendLimit;
    bool public submittedSpendLimit;
    bool public initializedSpendLimit;

    /// @dev Constructor initializes the daily spend limit in wei.
    constructor(uint _spendLimit) internal {
        spendLimit = _spendLimit;
        _spendLimitDay = now;
        _spendAvailable = spendLimit;
    }

    /// @dev Returns the available daily balance - accounts for daily limit reset.
    /// @return amount of ether in wei.
    function spendAvailable() public view returns (uint) {
        if (now > _spendLimitDay + 24 hours) {
            return spendLimit;
        } else {
            return _spendAvailable;
        }
    }

    /// @dev Initialize a daily spend (aka transfer) limit for non-whitelisted addresses.
    /// @param _amount is the daily limit amount in wei.
    function initializeSpendLimit(uint _amount) external onlyOwner {
        // Require that the spend limit has not been initialized.
        require(!initializedSpendLimit, "spend limit has already been initialized");
        // Modify spend limit based on the provided value.
        _modifySpendLimit(_amount);
        // Flag the operation as initialized.
        initializedSpendLimit = true;
        // Emit the set limit event.
        emit SetSpendLimit(msg.sender, _amount);
    }

    /// @dev Set a daily transfer limit for non-whitelisted addresses.
    /// @param _amount is the daily limit amount in wei.
    function submitSpendLimit(uint _amount) external onlyOwner {
        // Require that the spend limit has been initialized.
        require(initializedSpendLimit, "spend limit has not been initialized");
        // Require that the operation has been submitted.
        require(!submittedSpendLimit, "spend limit has already been submitted");
        // Assign the provided amount to pending daily limit change.
        pendingSpendLimit = _amount;
        // Flag the operation as submitted.
        submittedSpendLimit = true;
        // Emit the submission event.
        emit SubmittedSpendLimitChange(_amount);
    }

    /// @dev Confirm pending set daily limit operation.
    function confirmSpendLimit(uint _amount) external onlyController {
        // Require that the operation has been submitted.
        require(submittedSpendLimit, "spend limit has not been submitted");
        // Require that pending and confirmed spend limit are the same
        require(pendingSpendLimit == _amount, "confirmed and submitted spend limits dont match");
        // Modify spend limit based on the pending value.
        _modifySpendLimit(pendingSpendLimit);
        // Emit the set limit event.
        emit SetSpendLimit(msg.sender, pendingSpendLimit);
        // Reset the submission flag.
        submittedSpendLimit = false;
        // Reset pending daily limit.
        pendingSpendLimit = 0;
    }

    /// @dev Cancel pending set daily limit operation.
    function cancelSpendLimit(uint _amount) external onlyController {
        // Require that pending and confirmed spend limit are the same
        require(pendingSpendLimit == _amount, "confirmed and cancelled spend limits dont match");
        // Reset pending daily limit.
        pendingSpendLimit = 0;
        // Reset the submitted operation flag.
        submittedSpendLimit = false;
        // Emit the cancellation event.
        emit CancelledSpendLimitChange(msg.sender);
    }

    // @dev Setter method for the available daily spend limit.
    function _setSpendAvailable(uint _amount) internal {
        _spendAvailable = _amount;
    }

    /// @dev Update available spend limit based on the daily reset.
    function _updateSpendAvailable() internal {
        if (now > _spendLimitDay.add(24 hours)) {
            // Advance the current day by how many days have passed.
            uint extraDays = now.sub(_spendLimitDay).div(24 hours);
            _spendLimitDay = _spendLimitDay.add(extraDays.mul(24 hours));
            // Set the available limit to the current spend limit.
            _spendAvailable = spendLimit;
        }
    }

    /// @dev Modify the spend limit and spend available based on the provided value.
    /// @dev _amount is the daily limit amount in wei.
    function _modifySpendLimit(uint _amount) private {
        // Account for the spend limit daily reset.
        _updateSpendAvailable();
        // Set the daily limit to the provided amount.
        spendLimit = _amount;
        // Lower the available limit if it&#39;s higher than the new daily limit.
        if (_spendAvailable > spendLimit) {
            _spendAvailable = spendLimit;
        }
    }
}


//// @title Asset store with extra security features.
contract Vault is Whitelist, SpendLimit, ERC165 {
    event Received(address _from, uint _amount);
    event Transferred(address _to, address _asset, uint _amount);

    using SafeMath for uint256;

    /// @dev Supported ERC165 interface ID.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7; // solium-disable-line uppercase

    /// @dev ENS points to the ENS registry smart contract.
    ENS private _ENS;
    /// @dev Is the registered ENS name of the oracle contract.
    bytes32 private _node;

    /// @dev Constructor initializes the vault with an owner address and spend limit. It also sets up the oracle and controller contracts.
    /// @param _owner is the owner account of the wallet contract.
    /// @param _transferable indicates whether the contract ownership can be transferred.
    /// @param _ens is the ENS public registry contract address.
    /// @param _oracleName is the ENS name of the Oracle.
    /// @param _controllerName is the ENS name of the controller.
    /// @param _spendLimit is the initial spend limit.
    constructor(address _owner, bool _transferable, address _ens, bytes32 _oracleName, bytes32 _controllerName, uint _spendLimit) SpendLimit(_spendLimit) Ownable(_owner, _transferable) Controllable(_ens, _controllerName) public {
        _ENS = ENS(_ens);
        _node = _oracleName;
    }

    /// @dev Checks if the value is not zero.
    modifier isNotZero(uint _value) {
        require(_value != 0, "provided value cannot be zero");
        _;
    }

    /// @dev Ether can be deposited from any source, so this contract must be payable by anyone.
    function() public payable {
        //TODO question: Why is this check here, is it necessary or are we building into a corner?
        require(msg.data.length == 0);
        emit Received(msg.sender, msg.value);
    }

    /// @dev Returns the amount of an asset owned by the contract.
    /// @param _asset address of an ERC20 token or 0x0 for ether.
    /// @return balance associated with the wallet address in wei.
    function balance(address _asset) external view returns (uint) {
        if (_asset != address(0)) {
            return ERC20(_asset).balanceOf(this);
        } else {
            return address(this).balance;
        }
    }

    /// @dev Transfers the specified asset to the recipient&#39;s address.
    /// @param _to is the recipient&#39;s address.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount of tokens to be transferred in base units.
    function transfer(address _to, address _asset, uint _amount) external onlyOwner isNotZero(_amount) {
        // Checks if the _to address is not the zero-address
        require(_to != address(0), "_to address cannot be set to 0x0");

        // If address is not whitelisted, take daily limit into account.
        if (!isWhitelisted[_to]) {
            // Update the available spend limit.
            _updateSpendAvailable();
            // Convert token amount to ether value.
            uint etherValue;
            bool tokenExists;
            if (_asset != address(0)) {
                (tokenExists, etherValue) = IOracle(PublicResolver(_ENS.resolver(_node)).addr(_node)).convert(_asset, _amount);
            } else {
                etherValue = _amount;
            }

            // If token is supported by our oracle or is ether
            // Check against the daily spent limit and update accordingly
            if (tokenExists || _asset == address(0)) {
                // Require that the value is under remaining limit.
                require(etherValue <= spendAvailable(), "transfer amount exceeds available spend limit");
                // Update the available limit.
                _setSpendAvailable(spendAvailable().sub(etherValue));
            }
        }
        // Transfer token or ether based on the provided address.
        if (_asset != address(0)) {
            require(ERC20(_asset).transfer(_to, _amount), "ERC20 token transfer was unsuccessful");
        } else {
            _to.transfer(_amount);
        }
        // Emit the transfer event.
        emit Transferred(_to, _asset, _amount);
    }

    /// @dev Checks for interface support based on ERC165.
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == _ERC165_INTERFACE_ID;
    }
}


//// @title Asset wallet with extra security features and gas top up management.
contract Wallet is Vault {
    event SetTopUpLimit(address _sender, uint _amount);
    event SubmittedTopUpLimitChange(uint _amount);
    event CancelledTopUpLimitChange(address _sender, uint _amount);

    event ToppedUpGas(address _sender, address _owner, uint _amount);

    using SafeMath for uint256;

    uint constant private MINIMUM_TOPUP_LIMIT = 1 finney; // solium-disable-line uppercase
    uint constant private MAXIMUM_TOPUP_LIMIT = 500 finney; // solium-disable-line uppercase

    uint public topUpLimit;
    uint private _topUpLimitDay;
    uint private _topUpAvailable;

    uint public pendingTopUpLimit;
    bool public submittedTopUpLimit;
    bool public initializedTopUpLimit;

    /// @dev Constructor initializes the wallet top up limit and the vault contract.
    /// @param _owner is the owner account of the wallet contract.
    /// @param _transferable indicates whether the contract ownership can be transferred.
    /// @param _ens is the address of the ENS.
    /// @param _oracleName is the ENS name of the Oracle.
    /// @param _controllerName is the ENS name of the Controller.
    /// @param _spendLimit is the initial spend limit.
    constructor(address _owner, bool _transferable, address _ens, bytes32 _oracleName, bytes32 _controllerName, uint _spendLimit) Vault(_owner, _transferable, _ens, _oracleName, _controllerName, _spendLimit) public {
        _topUpLimitDay = now;
        topUpLimit = MAXIMUM_TOPUP_LIMIT;
        _topUpAvailable = topUpLimit;
    }

    /// @dev Returns the available daily gas top up balance - accounts for daily limit reset.
    /// @return amount of gas in wei.
    function topUpAvailable() external view returns (uint) {
        if (now > _topUpLimitDay + 24 hours) {
            return topUpLimit;
        } else {
            return _topUpAvailable;
        }
    }

    /// @dev Initialize a daily gas top up limit.
    /// @param _amount is the gas top up amount in wei.
    function initializeTopUpLimit(uint _amount) external onlyOwner {
        // Require that the top up limit has not been initialized.
        require(!initializedTopUpLimit, "top up limit has already been initialized");
        // Require that the limit amount is within the acceptable range.
        require(MINIMUM_TOPUP_LIMIT <= _amount && _amount <= MAXIMUM_TOPUP_LIMIT, "top up amount is outside of the min/max range");
        // Modify spend limit based on the provided value.
        _modifyTopUpLimit(_amount);
        // Flag operation as initialized.
        initializedTopUpLimit = true;
        // Emit the set limit event.
        emit SetTopUpLimit(msg.sender, _amount);
    }

    /// @dev Set a daily top up top up limit.
    /// @param _amount is the daily top up limit amount in wei.
    function submitTopUpLimit(uint _amount) external onlyOwner {
        // Require that the top up limit has been initialized.
        require(initializedTopUpLimit, "top up limit has not been initialized");
        // Require that the operation has not been submitted.
        require(!submittedTopUpLimit, "top up limit has already been submitted");
        // Require that the limit amount is within the acceptable range.
        require(MINIMUM_TOPUP_LIMIT <= _amount && _amount <= MAXIMUM_TOPUP_LIMIT, "top up amount is outside of the min/max range");
        // Assign the provided amount to pending daily limit change.
        pendingTopUpLimit = _amount;
        // Flag the operation as submitted.
        submittedTopUpLimit = true;
        // Emit the submission event.
        emit SubmittedTopUpLimitChange(_amount);
    }

    /// @dev Confirm pending set top up limit operation.
    function confirmTopUpLimit(uint _amount) external onlyController {
        // Require that the operation has been submitted.
        require(submittedTopUpLimit, "top up limit has not been submitted");
        // Assert that the pending top up limit amount is within the acceptable range.
        require(MINIMUM_TOPUP_LIMIT <= pendingTopUpLimit && pendingTopUpLimit <= MAXIMUM_TOPUP_LIMIT, "top up amount is outside the min/max range");
        // Assert that confirmed and pending topup limit are the same.
        require(_amount == pendingTopUpLimit, "confirmed and pending topup limit are not same");
        // Modify top up limit based on the pending value.
        _modifyTopUpLimit(pendingTopUpLimit);
        // Emit the set limit event.
        emit SetTopUpLimit(msg.sender, pendingTopUpLimit);
        // Reset pending daily limit.
        pendingTopUpLimit = 0;
        // Reset the submission flag.
        submittedTopUpLimit = false;
    }

    /// @dev Cancel pending set top up limit operation.
    function cancelTopUpLimit(uint _amount) external onlyController {
        // Reset pending daily limit.
        pendingTopUpLimit = 0;
        // Reset the submitted operation flag.
        submittedTopUpLimit = false;
        // Emit the cancellation event.
        emit CancelledTopUpLimitChange(msg.sender, _amount);
    }

    /// @dev Refill owner&#39;s gas balance.
    /// @dev Revert if the transaction amount is too large
    /// @param _amount is the amount of ether to transfer to the owner account in wei.
    function topUpGas(uint _amount) external isNotZero(_amount) {
        // Require that the sender is either the owner or a controller.
        require(_isOwner() || _isController(msg.sender), "sender is neither an owner nor a controller");
        // Account for the top up limit daily reset.
        _updateTopUpAvailable();
        // Make sure the available top up amount is not zero.
        require(_topUpAvailable != 0, "available top up limit cannot be zero");
        // Fail if there isn&#39;t enough in the daily top up limit to perform topUp
        require(_amount <= _topUpAvailable, "available top up limit less than amount passed in");
        // Reduce the top up amount from available balance and transfer corresponding
        // ether to the owner&#39;s account.
        _topUpAvailable = _topUpAvailable.sub(_amount);
        owner().transfer(_amount);
        // Emit the gas top up event.
        emit ToppedUpGas(tx.origin, owner(), _amount);
    }

    /// @dev Modify the top up limit and top up available based on the provided value.
    /// @dev _amount is the daily limit amount in wei.
    function _modifyTopUpLimit(uint _amount) private {
        // Account for the top up limit daily reset.
        _updateTopUpAvailable();
        // Set the daily limit to the provided amount.
        topUpLimit = _amount;
        // Lower the available limit if it&#39;s higher than the new daily limit.
        if (_topUpAvailable > topUpLimit) {
            _topUpAvailable = topUpLimit;
        }
    }

    /// @dev Update available top up limit based on the daily reset.
    function _updateTopUpAvailable() private {
        if (now > _topUpLimitDay.add(24 hours)) {
            // Advance the current day by how many days have passed.
            uint extraDays = now.sub(_topUpLimitDay).div(24 hours);
            _topUpLimitDay = _topUpLimitDay.add(extraDays.mul(24 hours));
            // Set the available limit to the current top up limit.
            _topUpAvailable = topUpLimit;
        }
    }
}