/*

  << Wyvern Exchange >>

*/

pragma solidity 0.7.5;

import "./exchange/Exchange.sol";

/**
 * @title WyvernExchange
 * @author Wyvern Protocol Developers
 */
contract WyvernExchange is Exchange {

    string public constant name = "Wyvern Exchange";
  
    string public constant version = "3.1";

    string public constant codename = "Ancalagon";

    constructor (uint chainId, address[] memory registryAddrs, bytes memory customPersonalSignPrefix) public {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId,
            verifyingContract : address(this)
        }));
        for (uint ind = 0; ind < registryAddrs.length; ind++) {
          registries[registryAddrs[ind]] = true;
        }
        if (customPersonalSignPrefix.length > 0) {
          personalSignPrefix = customPersonalSignPrefix;
        }
    }

}

pragma solidity 0.7.5;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() virtual public view returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() virtual public pure returns (uint256 proxyTypeId);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback () external payable {
        address _impl = implementation();
        require(_impl != address(0), "Proxy implementation required");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

pragma solidity 0.7.5;

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract OwnedUpgradeabilityStorage {

    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

pragma solidity 0.7.5;

import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() override public view returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId Proxy type, 2 for forwarding proxy
     */
    function proxyType() override public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementation) internal {
        require(_implementation != implementation, "Proxy already uses this implementation");
        _implementation = implementation;
        emit Upgraded(implementation);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Only the proxy owner can call this method");
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(implementation);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Call failed after proxy upgrade");
    }
}

/*

  Token recipient. Modified very slightly from the example on http://ethereum.org/dao (just to index log parameters).

*/

pragma solidity 0.7.5;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenRecipient
 * @author Wyvern Protocol Developers
 */
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, address(this), value), "ERC20 token transfer failed");
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback () payable external {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

/*

  Proxy registry interface.

*/

pragma solidity 0.7.5;

import "./OwnableDelegateProxy.sol";

/**
 * @title ProxyRegistryInterface
 * @author Wyvern Protocol Developers
 */
interface ProxyRegistryInterface {

    function delegateProxyImplementation() external returns (address);

    function proxies(address owner) external returns (OwnableDelegateProxy);

}

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.

  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/

pragma solidity 0.7.5;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";
import "./ProxyRegistryInterface.sol";

/**
 * @title ProxyRegistry
 * @author Wyvern Protocol Developers
 */
contract ProxyRegistry is Ownable, ProxyRegistryInterface {

    /* DelegateProxy implementation contract. Must be initialized. */
    address public override delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public override proxies;

    /* Contracts pending access. */
    mapping(address => uint) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the Wyvern DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the Wyvern and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint public DELAY_PERIOD = 2 weeks;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0, "Contract is already allowed in registry, or pending");
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to enable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < block.timestamp), "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */
    function revokeAuthentication (address addr)
        public
        onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy()
        public
        returns (OwnableDelegateProxy proxy)
    {
        return registerProxyFor(msg.sender);
    }

    /**
     * Register a proxy contract with this registry, overriding any existing proxy
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyOverride()
        public
        returns (OwnableDelegateProxy proxy)
    {
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Can be called by any user
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyFor(address user)
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[user] == OwnableDelegateProxy(0), "User already has a proxy");
        proxy = new OwnableDelegateProxy(user, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", user, address(this)));
        proxies[user] = proxy;
        return proxy;
    }

    /**
     * Register multiple proxies contract with this registry
     *
     * @dev Can be called by any user
     * @return userProxies New AuthenticatedProxy contracts
     */
    function registerProxyForMultiple(address[] calldata users)
        external
        returns (OwnableDelegateProxy[] memory)
    {
        OwnableDelegateProxy[] memory userProxies = new OwnableDelegateProxy[](users.length);
        for (uint i = 0; i < users.length; i++) {
            require(proxies[users[i]] == OwnableDelegateProxy(0), "User already has a proxy");
            OwnableDelegateProxy proxy = new OwnableDelegateProxy(users[i], delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", users[i], address(this)));
            proxies[users[i]] = proxy;
            userProxies[i] = proxy;
        }
        return userProxies;
    }

    /**
     * Transfer access
     */
    function transferAccessTo(address from, address to)
        public
    {
        OwnableDelegateProxy proxy = proxies[from];

        /* CHECKS */
        require(OwnableDelegateProxy(msg.sender) == proxy, "Proxy transfer can only be called by the proxy");
        require(proxies[to] == OwnableDelegateProxy(0), "Proxy transfer has existing proxy as destination");

        /* EFFECTS */
        delete proxies[from];
        proxies[to] = proxy;
    }

}

/*

  OwnableDelegateProxy

*/

pragma solidity 0.7.5;

import "./proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author Wyvern Protocol Developers
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data)
        public
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }

}

/*

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

pragma solidity 0.7.5;

import "./ProxyRegistry.sol";
import "./TokenRecipient.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";

/**
 * @title AuthenticatedProxy
 * @author Wyvern Protocol Developers
 */
contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize (address addrUser, ProxyRegistry addrRegistry)
        public
    {
        require(!initialized, "Authenticated proxy already initialized");
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
        public
    {
        require(msg.sender == user, "Authenticated proxy can only be revoked by its user");
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes memory data)
        public payable
        returns (bool result)
    {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)), "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access");
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param data Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes memory data)
        public
    {
        require(proxy(dest, howToCall, data), "Proxy assertion failed");
    }

}

/*

  << Static Caller >>

*/

pragma solidity 0.7.5;

/**
 * @title StaticCaller
 * @author Wyvern Protocol Developers
 */
contract StaticCaller {

    function staticCall(address target, bytes memory data)
        internal
        view
        returns (bool result)
    {
        assembly {
            result := staticcall(gas(), target, add(data, 0x20), mload(data), mload(0x40), 0)
        }
        return result;
    }

    function staticCallUint(address target, bytes memory data)
        internal
        view
        returns (uint ret)
    {
        bool result;
        assembly {
            let size := 0x20
            let free := mload(0x40)
            result := staticcall(gas(), target, add(data, 0x20), mload(data), free, size)
            ret := mload(free)
        }
        require(result, "Static call failed");
        return ret;
    }

}

/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

pragma solidity 0.7.5;

/**
 * @title ReentrancyGuarded
 * @author Wyvern Protocol Developers
 */
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

/*

  << EIP 712 >>

*/

pragma solidity 0.7.5;

/**
 * @title EIP712
 * @author Wyvern Protocol Developers
 */
contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 DOMAIN_SEPARATOR;

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

}

/*

  << EIP 1271 >>

*/

pragma solidity 0.7.5;

abstract contract ERC1271 {

  // bytes4(keccak256("isValidSignature(bytes,bytes)")
  bytes4 constant internal MAGICVALUE = 0x20c13b0b;

  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param _data Arbitrary length data signed on the behalf of address(this)
   * @param _signature Signature byte array associated with _data
   *
   * MUST return the bytes4 magic value 0x20c13b0b when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */
  function isValidSignature(
      bytes memory _data,
      bytes memory _signature)
      virtual
      public
      view
      returns (bytes4 magicValue);
}

/*

  << Exchange Core >>

*/

pragma solidity 0.7.5;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../lib/StaticCaller.sol";
import "../lib/ReentrancyGuarded.sol";
import "../lib/EIP712.sol";
import "../lib/EIP1271.sol";
import "../registry/ProxyRegistryInterface.sol";
import "../registry/AuthenticatedProxy.sol";

/**
 * @title ExchangeCore
 * @author Wyvern Protocol Developers
 */
contract ExchangeCore is ReentrancyGuarded, StaticCaller, EIP712 {

    bytes4 constant internal EIP_1271_MAGICVALUE = 0x20c13b0b;
    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    /* Struct definitions. */

    /* An order, convenience struct. */
    struct Order {
        /* Order registry address. */
        address registry;
        /* Order maker address. */
        address maker;
        /* Order static target. */
        address staticTarget;
        /* Order static selector. */
        bytes4 staticSelector;
        /* Order static extradata. */
        bytes staticExtradata;
        /* Order maximum fill factor. */
        uint maximumFill;
        /* Order listing timestamp. */
        uint listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint salt;
    }

    /* A call, convenience struct. */
    struct Call {
        /* Target */
        address target;
        /* How to call */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata */
        bytes data;
    }

    /* Constants */

    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address registry,address maker,address staticTarget,bytes4 staticSelector,bytes staticExtradata,uint256 maximumFill,uint256 listingTime,uint256 expirationTime,uint256 salt)"
    );

    /* Variables */

    /* Trusted proxy registry contracts. */
    mapping(address => bool) public registries;

    /* Order fill status, by maker address then by hash. */
    mapping(address => mapping(bytes32 => uint)) public fills;

    /* Orders verified by on-chain approval.
       Alternative to ECDSA signatures so that smart contracts can place orders directly.
       By maker address, then by hash. */
    mapping(address => mapping(bytes32 => bool)) public approved;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Events */

    event OrderApproved     (bytes32 indexed hash, address registry, address indexed maker, address staticTarget, bytes4 staticSelector, bytes staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired);
    event OrderFillChanged  (bytes32 indexed hash, address indexed maker, uint newFill);
    event OrdersMatched     (bytes32 firstHash, bytes32 secondHash, address indexed firstMaker, address indexed secondMaker, uint newFirstFill, uint newSecondFill, bytes32 indexed metadata);
    event OrderCancelled          (bytes32 indexed hash);

    /* Functions */

    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Per EIP 712. */
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.registry,
            order.maker,
            order.staticTarget,
            order.staticSelector,
            keccak256(order.staticExtradata),
            order.maximumFill,
            order.listingTime,
            order.expirationTime,
            order.salt
        ));
    }

    function hashToSign(bytes32 orderHash)
        internal
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }

    function exists(address what)
        internal
        view
        returns (bool)
    {
        uint size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    function validateOrderParameters(Order memory order, bytes32 hash)
        internal
        view
        returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (order.listingTime > block.timestamp || (order.expirationTime != 0 && order.expirationTime <= block.timestamp)) {
            return false;
        }

        /* Order must not have already been completely filled. */
        if (fills[order.maker][hash] >= order.maximumFill) {
            return false;
        }

        /* Order static target must exist. */
        if (!exists(order.staticTarget)) {
            return false;
        }

        return true;
    }

    function validateOrderAuthorization(bytes32 hash, address maker, bytes memory signature)
        internal
        view
        returns (bool)
    {
        /* Memoized authentication. If order has already been partially filled, order must be authenticated. */
        if (fills[maker][hash] > 0) {
            return true;
        }

        /* Order authentication. Order must be either: */

        /* (a): sent by maker */
        if (maker == msg.sender) {
            return true;
        }

        /* (b): previously approved */
        if (approved[maker][hash]) {
            return true;
        }

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);

        /* Determine whether signer is a contract or account. */
        bool isContract = exists(maker);

        /* (c): Contract-only authentication: EIP/ERC 1271. */
        if (isContract) {
            if (ERC1271(maker).isValidSignature(abi.encodePacked(calculatedHashToSign), signature) == EIP_1271_MAGICVALUE) {
                return true;
            }
            return false;
        }

        /* (d): Account-only authentication: ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));

        if (signature.length > 65 && signature[signature.length-1] == 0x03) { // EthSign byte
            /* (d.1): Old way: order hash signed by maker using the prefixed personal_sign */
            if (ecrecover(keccak256(abi.encodePacked(personalSignPrefix,"32",calculatedHashToSign)), v, r, s) == maker) {
                return true;
            }
        }
        /* (d.2): New way: order hash signed by maker using sign_typed_data */
        else if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
            return true;
        }
        return false;
    }

    function encodeStaticCall(Order memory order, Call memory call, Order memory counterorder, Call memory countercall, address matcher, uint value, uint fill)
        internal
        pure
        returns (bytes memory)
    {
        /* This array wrapping is necessary to preserve static call target function stack space. */
        address[7] memory addresses = [order.registry, order.maker, call.target, counterorder.registry, counterorder.maker, countercall.target, matcher];
        AuthenticatedProxy.HowToCall[2] memory howToCalls = [call.howToCall, countercall.howToCall];
        uint[6] memory uints = [value, order.maximumFill, order.listingTime, order.expirationTime, counterorder.listingTime, fill];
        return abi.encodeWithSelector(order.staticSelector, order.staticExtradata, addresses, howToCalls, uints, call.data, countercall.data);
    }

    function executeStaticCall(Order memory order, Call memory call, Order memory counterorder, Call memory countercall, address matcher, uint value, uint fill)
        internal
        view
        returns (uint)
    {
        return staticCallUint(order.staticTarget, encodeStaticCall(order, call, counterorder, countercall, matcher, value, fill));
    }

    function executeCall(ProxyRegistryInterface registry, address maker, Call memory call, bool isFirstOrder)
        internal
        returns (bool)
    {
        /* Assert valid registry. */
        require(registries[address(registry)]);

        /* Assert target exists. */
        require(exists(call.target), "Call target does not exist");

        /* Retrieve delegate proxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(maker);

        /* Assert existence. */
        require(delegateProxy != OwnableDelegateProxy(0), "Delegate proxy does not exist for maker");

        /* Assert implementation. */
        require(delegateProxy.implementation() == registry.delegateProxyImplementation(), "Incorrect delegate proxy implementation for maker");

        /* Typecast. */
        AuthenticatedProxy proxy = AuthenticatedProxy(address(delegateProxy));

        /* Execute order. */
        if (isFirstOrder) {
            return proxy.proxy(call.target, call.howToCall, call.data);
        } else {
            return proxy.proxy{value: msg.value}(call.target, call.howToCall, call.data);
        }
    }

    function approveOrderHash(bytes32 hash)
        internal
    {
        /* CHECKS */

        /* Assert order has not already been approved. */
        require(!approved[msg.sender][hash], "Order has already been approved");

        /* EFFECTS */

        /* Mark order as approved. */
        approved[msg.sender][hash] = true;
    }

    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(order.maker == msg.sender, "Sender is not the maker of the order and thus not authorized to approve it");

        /* Calculate order hash. */
        bytes32 hash = hashOrder(order);

        /* Approve order hash. */
        approveOrderHash(hash);

        /* Log approval event. */
        emit OrderApproved(hash, order.registry, order.maker, order.staticTarget, order.staticSelector, order.staticExtradata, order.maximumFill, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
    }

    function setOrderFill(bytes32 hash, uint fill)
        internal
    {
        /* CHECKS */

        /* Assert fill is not already set. */
        require(fills[msg.sender][hash] != fill, "Fill is already set to the desired value");

        /* EFFECTS */

        /* Mark order as accordingly filled. */
        fills[msg.sender][hash] = fill;

        /* Log order fill change event. */
        emit OrderFillChanged(hash, msg.sender, fill);
    }

    function atomicMatch(Order memory firstOrder, Call memory firstCall, Order memory secondOrder, Call memory secondCall, bytes memory signatures, bytes32 metadata)
        internal
        reentrancyGuard
    {
        /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(firstOrder);

        /* Check first order validity. */
        require(validateOrderParameters(firstOrder, firstHash), "First order has invalid parameters");

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(secondOrder);

        /* Check second order validity. */
        require(validateOrderParameters(secondOrder, secondHash), "Second order has invalid parameters");

        /* Order must have not been canceled or already filled. */
        // Take array to avoid stack too deep
        bytes32[] memory hashToSigns = new bytes32[](2);
        hashToSigns[0] = hashToSign(firstHash);
        hashToSigns[1] = hashToSign(secondHash);
        require(!cancelledOrFinalized[hashToSigns[0]], "First order must have not been canceled or already filled");
        require(!cancelledOrFinalized[hashToSigns[1]], "Second order must have not been canceled or already filled");

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");

        {
            /* Calculate signatures (must be awkwardly decoded here due to stack size constraints). */
            (bytes memory firstSignature, bytes memory secondSignature) = abi.decode(signatures, (bytes, bytes));

            /* Check first order authorization. */
            require(validateOrderAuthorization(firstHash, firstOrder.maker, firstSignature), "First order failed authorization");

            /* Check second order authorization. */
            require(validateOrderAuthorization(secondHash, secondOrder.maker, secondSignature), "Second order failed authorization");
        }

        /* INTERACTIONS */

        /* Transfer any msg.value.
           This is the first "asymmetric" part of order matching: if an order requires Ether, it must be the first order. */
        // if (msg.value > 0) {
        //     address(uint160(firstOrder.maker)).transfer(msg.value);
        // }

        /* Execute first call, assert success.
           This is the second "asymmetric" part of order matching: execution of the second order can depend on state changes in the first order, but not vice-versa. */
        require(executeCall(ProxyRegistryInterface(firstOrder.registry), firstOrder.maker, firstCall, true), "First call failed");

        /* Execute second call, assert success. */
        require(executeCall(ProxyRegistryInterface(secondOrder.registry), secondOrder.maker, secondCall, false), "Second call failed");

        /* Static calls must happen after the effectful calls so that they can check the resulting state. */

        /* Fetch previous first order fill. */
        uint previousFirstFill = fills[firstOrder.maker][firstHash];

        /* Fetch previous second order fill. */
        uint previousSecondFill = fills[secondOrder.maker][secondHash];

        /* Execute first order static call, assert success, capture returned new fill. */
        uint firstFill = executeStaticCall(firstOrder, firstCall, secondOrder, secondCall, msg.sender, msg.value, previousFirstFill);

        /* Execute second order static call, assert success, capture returned new fill. */
        uint secondFill = executeStaticCall(secondOrder, secondCall, firstOrder, firstCall, msg.sender, msg.value, previousSecondFill);

        /* EFFECTS */

        /* Update first order fill, if necessary. */
        if (firstOrder.maker != msg.sender) {
            if (firstFill != previousFirstFill) {
                fills[firstOrder.maker][firstHash] = firstFill;
            } else {
                cancelledOrFinalized[hashToSigns[0]] = true;
            }
        }

        /* Update second order fill, if necessary. */
        if (secondOrder.maker != msg.sender) {
            if (secondFill != previousSecondFill) {
                fills[secondOrder.maker][secondHash] = secondFill;
            } else {
                cancelledOrFinalized[hashToSigns[1]] = true;
            }
        }

        /* LOGS */

        /* Log match event. */
        emit OrdersMatched(firstHash, secondHash, firstOrder.maker, secondOrder.maker, firstFill, secondFill, metadata);
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param signature ECDSA signature
     */
    function validateOrder(bytes32 hash, Order memory order, bytes memory signature)
        internal
        view
        returns (bool)
    {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order, hash)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Order authentication. */
        /* previously approved */
        if (approved[msg.sender][hash]) {
            return true;
        }

        /* ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        if (ecrecover(hash, v, r, s) == order.maker) {
            return true;
        }

        return false;
    }

    function requireValidOrder(Order memory order, bytes memory signature) internal view returns (bytes32) {
        bytes32 orderHash = hashOrder(order);
        bytes32 hash = hashToSign(orderHash);
        require(validateOrder(hash, order, signature));
        return hash;
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param signature ECDSA signature
     */
    function cancelOrder(Order memory order, bytes memory signature)
        internal
    {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, signature);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }
}

/*

  << Exchange >>

*/

pragma solidity 0.7.5;

import "./ExchangeCore.sol";

/**
 * @title Exchange
 * @author Wyvern Protocol Developers
 */
contract Exchange is ExchangeCore {

    /* external ABI-encodable method wrappers. */

    function hashOrder_(address registry, address maker, address staticTarget, bytes4 staticSelector, bytes calldata staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt)
        external
        pure
        returns (bytes32 hash)
    {
        return hashOrder(Order(registry, maker, staticTarget, staticSelector, staticExtradata, maximumFill, listingTime, expirationTime, salt));
    }

    function hashToSign_(bytes32 orderHash)
        external
        view
        returns (bytes32 hash)
    {
        return hashToSign(orderHash);
    }

    function validateOrderParameters_(address registry, address maker, address staticTarget, bytes4 staticSelector, bytes calldata staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt)
        external
        view
        returns (bool)
    {
        Order memory order = Order(registry, maker, staticTarget, staticSelector, staticExtradata, maximumFill, listingTime, expirationTime, salt);
        return validateOrderParameters(order, hashOrder(order));
    }

    function validateOrderAuthorization_(bytes32 hash, address maker, bytes calldata signature)
        external
        view
        returns (bool)
    {
        return validateOrderAuthorization(hash, maker, signature);
    }

    function approveOrderHash_(bytes32 hash)
        external
    {
        return approveOrderHash(hash);
    }

    function approveOrder_(address registry, address maker, address staticTarget, bytes4 staticSelector, bytes calldata staticExtradata, uint maximumFill, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired)
        external
    {
        return approveOrder(Order(registry, maker, staticTarget, staticSelector, staticExtradata, maximumFill, listingTime, expirationTime, salt), orderbookInclusionDesired);
    }

    function setOrderFill_(bytes32 hash, uint fill)
        external
    {
        return setOrderFill(hash, fill);
    }

    function atomicMatch_(uint[16] memory uints, bytes4[2] memory staticSelectors,
        bytes memory firstExtradata, bytes memory firstCalldata, bytes memory secondExtradata, bytes memory secondCalldata,
        uint8[2] memory howToCalls, bytes32 metadata, bytes memory signatures)
        public
        payable
    {
        return atomicMatch(
            Order(address(uints[0]), address(uints[1]), address(uints[2]), staticSelectors[0], firstExtradata, uints[3], uints[4], uints[5], uints[6]),
            Call(address(uints[7]), AuthenticatedProxy.HowToCall(howToCalls[0]), firstCalldata),
            Order(address(uints[8]), address(uints[9]), address(uints[10]), staticSelectors[1], secondExtradata, uints[11], uints[12], uints[13], uints[14]),
            Call(address(uints[15]), AuthenticatedProxy.HowToCall(howToCalls[1]), secondCalldata),
            signatures,
            metadata
        );
    }

    function cancelOrder_(uint[7] memory uints, bytes4 staticSelector, bytes memory extraData, bytes memory signature) public {
        return cancelOrder(
            Order(address(uints[0]), address(uints[1]), address(uints[2]), staticSelector, extraData, uints[3], uints[4], uints[5], uints[6]),
            signature
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}