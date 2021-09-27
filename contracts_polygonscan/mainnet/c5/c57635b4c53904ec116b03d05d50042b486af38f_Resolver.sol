/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

pragma solidity ^0.8.6;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

interface IResolver {
    event NameChanged(bytes32 indexed node, string name);
    event AddressChanged(bytes32 indexed node, address newAddress);

    function setName(bytes32 node, string calldata name) external;
    function name(bytes32 node) external view returns (string memory);

    function setAddr(bytes32 node, address newAddress) external;
    function addr(bytes32 node) external view returns (address);
}

/**
    This is a very simplified Resolver, taken from ENS. We can use the full Public resolver to support the same
    features.
*/
contract Resolver is IResolver, Initializable {
    mapping(bytes32=>string) names;
    mapping(bytes32=>address) addresses;
    address owner;
    mapping(address=>bool) admins;

    modifier onlyAdmins() {
        require(isAdmin(), "[403] Only owner and admins are authorized.");
        _;
    }

    modifier authorised(bytes32 node) {
        require(isAuthorised(node), "[403] Sender is not authorized for node.");
        _;
    }

    function isAuthorised(bytes32 node) internal view returns(bool) {
        return msg.sender == owner || admins[msg.sender];
    }

    function isAdmin() public view returns(bool) {
        return msg.sender == owner || admins[msg.sender];
    }

    function addAdmin(address admin) public onlyAdmins {
        admins[admin] = true;
    }

    function removeAdmin(address admin) public onlyAdmins {
        delete admins[admin];
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function setName(bytes32 node, string calldata name) public override authorised(node) {
        names[node] = name;
        emit NameChanged(node, name);
    }

    function name(bytes32 node) public override view returns (string memory) {
        return names[node];
    }

    function setAddr(bytes32 node, address newAddress) public override authorised(node) {
        emit AddressChanged(node, newAddress);

        addresses[node] = newAddress;
    }

    function addr(bytes32 node) public override view returns (address) {
        return addresses[node];
    }
}