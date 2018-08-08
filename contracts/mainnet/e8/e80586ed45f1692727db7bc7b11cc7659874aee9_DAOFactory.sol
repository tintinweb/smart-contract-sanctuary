//File: contracts/acl/IACL.sol
pragma solidity ^0.4.18;


interface IACL {
    function initialize(address permissionsCreator) public;
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

//File: contracts/kernel/IKernel.sol
pragma solidity ^0.4.18;



interface IKernel {
    event SetApp(bytes32 indexed namespace, bytes32 indexed name, bytes32 indexed id, address app);

    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 name, address app) public returns (bytes32 id);
    function getApp(bytes32 id) public view returns (address);
}
//File: contracts/kernel/KernelStorage.sol
pragma solidity 0.4.18;


contract KernelConstants {
    bytes32 constant public CORE_NAMESPACE = keccak256("core");
    bytes32 constant public APP_BASES_NAMESPACE = keccak256("base");
    bytes32 constant public APP_ADDR_NAMESPACE = keccak256("app");

    bytes32 constant public KERNEL_APP_ID = keccak256("kernel.aragonpm.eth");
    bytes32 constant public KERNEL_APP = keccak256(CORE_NAMESPACE, KERNEL_APP_ID);

    bytes32 constant public ACL_APP_ID = keccak256("acl.aragonpm.eth");
    bytes32 constant public ACL_APP = keccak256(APP_ADDR_NAMESPACE, ACL_APP_ID);
}


contract KernelStorage is KernelConstants {
    mapping (bytes32 => address) public apps;
}

//File: contracts/acl/ACLSyntaxSugar.sol
pragma solidity 0.4.18;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[] r) {}

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

//File: contracts/apps/IAppProxy.sol
pragma solidity 0.4.18;

interface IAppProxy {
    function isUpgradeable() public pure returns (bool);
    function getCode() public view returns (address);
}

//File: contracts/apps/AppStorage.sol
pragma solidity ^0.4.18;




contract AppStorage {
    IKernel public kernel;
    bytes32 public appId;
    address internal pinnedCode; // used by Proxy Pinned
    uint256 internal initializationBlock; // used by Initializable
    uint256[95] private storageOffset; // forces App storage to start at after 100 slots
    uint256 private offset;
}

//File: contracts/common/Initializable.sol
pragma solidity ^0.4.18;




contract Initializable is AppStorage {
    modifier onlyInit {
        require(initializationBlock == 0);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        initializationBlock = getBlockNumber();
    }

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }
}

//File: contracts/common/DelegateProxy.sol
pragma solidity 0.4.18;


contract DelegateProxy {
    /**
    * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
    * @param _dst Destination address to perform the delegatecall
    * @param _calldata Calldata for the delegatecall
    */
    function delegatedFwd(address _dst, bytes _calldata) internal {
        require(isContract(_dst));
        assembly {
            let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function isContract(address _target) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

//File: contracts/apps/AppProxyBase.sol
pragma solidity 0.4.18;







contract AppProxyBase is IAppProxy, AppStorage, DelegateProxy, KernelConstants {
    /**
    * @dev Initialize AppProxy
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    function AppProxyBase(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public {
        kernel = _kernel;
        appId = _appId;

        // Implicit check that kernel is actually a Kernel
        // The EVM doesn&#39;t actually provide a way for us to make sure, but we can force a revert to
        // occur if the kernel is set to 0x0 or a non-code address when we try to call a method on
        // it.
        address appCode = getAppBase(appId);

        // If initialize payload is provided, it will be executed
        if (_initializePayload.length > 0) {
            require(isContract(appCode));
            // Cannot make delegatecall as a delegateproxy.delegatedFwd as it
            // returns ending execution context and halts contract deployment
            require(appCode.delegatecall(_initializePayload));
        }
    }

    function getAppBase(bytes32 _appId) internal view returns (address) {
        return kernel.getApp(keccak256(APP_BASES_NAMESPACE, _appId));
    }

    function () payable public {
        address target = getCode();
        require(target != 0); // if app code hasn&#39;t been set yet, don&#39;t call
        delegatedFwd(target, msg.data);
    }
}
//File: contracts/apps/AppProxyUpgradeable.sol
pragma solidity 0.4.18;




contract AppProxyUpgradeable is AppProxyBase {
    address public pinnedCode;

    /**
    * @dev Initialize AppProxyUpgradeable (makes it an upgradeable Aragon app)
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    function AppProxyUpgradeable(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
             AppProxyBase(_kernel, _appId, _initializePayload) public
    {

    }

    function getCode() public view returns (address) {
        return getAppBase(appId);
    }

    function isUpgradeable() public pure returns (bool) {
        return true;
    }
}

//File: contracts/apps/AppProxyPinned.sol
pragma solidity 0.4.18;




contract AppProxyPinned is AppProxyBase {
    /**
    * @dev Initialize AppProxyPinned (makes it an un-upgradeable Aragon app)
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    function AppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
             AppProxyBase(_kernel, _appId, _initializePayload) public
    {
        pinnedCode = getAppBase(appId);
        require(pinnedCode != address(0));
    }

    function getCode() public view returns (address) {
        return pinnedCode;
    }

    function isUpgradeable() public pure returns (bool) {
        return false;
    }

    function () payable public {
        delegatedFwd(getCode(), msg.data);
    }
}
//File: contracts/factory/AppProxyFactory.sol
pragma solidity 0.4.18;





contract AppProxyFactory {
    event NewAppProxy(address proxy);

    function newAppProxy(IKernel _kernel, bytes32 _appId) public returns (AppProxyUpgradeable) {
        return newAppProxy(_kernel, _appId, new bytes(0));
    }

    function newAppProxy(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyUpgradeable) {
        AppProxyUpgradeable proxy = new AppProxyUpgradeable(_kernel, _appId, _initializePayload);
        NewAppProxy(address(proxy));
        return proxy;
    }

    function newAppProxyPinned(IKernel _kernel, bytes32 _appId) public returns (AppProxyPinned) {
        return newAppProxyPinned(_kernel, _appId, new bytes(0));
    }

    function newAppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyPinned) {
        AppProxyPinned proxy = new AppProxyPinned(_kernel, _appId, _initializePayload);
        NewAppProxy(address(proxy));
        return proxy;
    }
}

//File: contracts/kernel/Kernel.sol
pragma solidity 0.4.18;









contract Kernel is IKernel, KernelStorage, Initializable, AppProxyFactory, ACLSyntaxSugar {
    bytes32 constant public APP_MANAGER_ROLE = keccak256("APP_MANAGER_ROLE");

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initializes a kernel instance along with its ACL and sets `_permissionsCreator` as the entity that can create other permissions
    * @param _baseAcl Address of base ACL app
    * @param _permissionsCreator Entity that will be given permission over createPermission
    */
    function initialize(address _baseAcl, address _permissionsCreator) onlyInit public {
        initialized();

        IACL acl = IACL(newAppProxy(this, ACL_APP_ID));

        _setApp(APP_BASES_NAMESPACE, ACL_APP_ID, _baseAcl);
        _setApp(APP_ADDR_NAMESPACE, ACL_APP_ID, acl);

        acl.initialize(_permissionsCreator);
    }

    /**
    * @dev Create a new instance of an app linked to this kernel and set its base
    *      implementation if it was not already set
    * @param _name Name of the app
    * @param _appBase Address of the app&#39;s base implementation
    * @return AppProxy instance
    */
    function newAppInstance(bytes32 _name, address _appBase) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (IAppProxy appProxy) {
        _setAppIfNew(APP_BASES_NAMESPACE, _name, _appBase);
        appProxy = newAppProxy(this, _name);
    }

    /**
    * @dev Create a new pinned instance of an app linked to this kernel and set
    *      its base implementation if it was not already set
    * @param _name Name of the app
    * @param _appBase Address of the app&#39;s base implementation
    * @return AppProxy instance
    */
    function newPinnedAppInstance(bytes32 _name, address _appBase) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (IAppProxy appProxy) {
        _setAppIfNew(APP_BASES_NAMESPACE, _name, _appBase);
        appProxy = newAppProxyPinned(this, _name);
    }

    /**
    * @dev Set the resolving address of an app instance or base implementation
    * @param _namespace App namespace to use
    * @param _name Name of the app
    * @param _app Address of the app
    * @return ID of app
    */
    function setApp(bytes32 _namespace, bytes32 _name, address _app) auth(APP_MANAGER_ROLE, arr(_namespace, _name)) kernelIntegrity public returns (bytes32 id) {
        return _setApp(_namespace, _name, _app);
    }

    /**
    * @dev Get the address of an app instance or base implementation
    * @param _id App identifier
    * @return Address of the app
    */
    function getApp(bytes32 _id) public view returns (address) {
        return apps[_id];
    }

    /**
    * @dev Get the installed ACL app
    * @return ACL app
    */
    function acl() public view returns (IACL) {
        return IACL(getApp(ACL_APP));
    }

    /**
    * @dev Function called by apps to check ACL on kernel or to check permission status
    * @param _who Sender of the original call
    * @param _where Address of the app
    * @param _what Identifier for a group of actions in app
    * @param _how Extra data for ACL auth
    * @return boolean indicating whether the ACL allows the role or not
    */
    function hasPermission(address _who, address _where, bytes32 _what, bytes _how) public view returns (bool) {
        return acl().hasPermission(_who, _where, _what, _how);
    }

    function _setApp(bytes32 _namespace, bytes32 _name, address _app) internal returns (bytes32 id) {
        id = keccak256(_namespace, _name);
        apps[id] = _app;
        SetApp(_namespace, _name, id, _app);
    }

    function _setAppIfNew(bytes32 _namespace, bytes32 _name, address _app) internal returns (bytes32 id) {
        id = keccak256(_namespace, _name);

        if (_app != address(0)) {
            address app = getApp(id);
            if (app != address(0)) {
                require(app == _app);
            } else {
                apps[id] = _app;
                SetApp(_namespace, _name, id, _app);
            }
        }
    }

    modifier auth(bytes32 _role, uint256[] memory params) {
        bytes memory how;
        uint256 byteLength = params.length * 32;
        assembly {
            how := params // forced casting
            mstore(how, byteLength)
        }
        // Params is invalid from this point fwd
        require(hasPermission(msg.sender, address(this), _role, how));
        _;
    }

    modifier kernelIntegrity {
        _; // After execution check integrity
        address kernel = getApp(KERNEL_APP);
        uint256 size;
        assembly { size := extcodesize(kernel) }
        require(size > 0);
    }
}

//File: contracts/kernel/KernelProxy.sol
pragma solidity 0.4.18;





contract KernelProxy is KernelStorage, DelegateProxy {
    /**
    * @dev KernelProxy is a proxy contract to a kernel implementation. The implementation
    *      can update the reference, which effectively upgrades the contract
    * @param _kernelImpl Address of the contract used as implementation for kernel
    */
    function KernelProxy(address _kernelImpl) public {
        apps[keccak256(CORE_NAMESPACE, KERNEL_APP_ID)] = _kernelImpl;
    }

    /**
    * @dev All calls made to the proxy are forwarded to the kernel implementation via a delegatecall
    * @return Any bytes32 value the implementation returns
    */
    function () payable public {
        delegatedFwd(apps[KERNEL_APP], msg.data);
    }
}
//File: contracts/evmscript/IEVMScriptExecutor.sol
pragma solidity ^0.4.18;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
}

//File: contracts/evmscript/IEVMScriptRegistry.sol
pragma solidity 0.4.18;


contract EVMScriptRegistryConstants {
    bytes32 constant public EVMSCRIPT_REGISTRY_APP_ID = keccak256("evmreg.aragonpm.eth");
    bytes32 constant public EVMSCRIPT_REGISTRY_APP = keccak256(keccak256("app"), EVMSCRIPT_REGISTRY_APP_ID);
}


interface IEVMScriptRegistry {
    function addScriptExecutor(address executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    function getScriptExecutor(bytes script) public view returns (address);
}
//File: contracts/evmscript/ScriptHelpers.sol
pragma solidity 0.4.18;


library ScriptHelpers {
    // To test with JS and compare with actual encoder. Maintaining for reference.
    // t = function() { return IEVMScriptExecutor.at(&#39;0x4bcdd59d6c77774ee7317fc1095f69ec84421e49&#39;).contract.execScript.getData(...[].slice.call(arguments)).slice(10).match(/.{1,64}/g) }
    // run = function() { return ScriptHelpers.new().then(sh => { sh.abiEncode.call(...[].slice.call(arguments)).then(a => console.log(a.slice(2).match(/.{1,64}/g)) ) }) }
    // This is truly not beautiful but lets no daydream to the day solidity gets reflection features

    function abiEncode(bytes _a, bytes _b, address[] _c) public pure returns (bytes d) {
        return encode(_a, _b, _c);
    }

    function encode(bytes memory _a, bytes memory _b, address[] memory _c) internal pure returns (bytes memory d) {
        // A is positioned after the 3 position words
        uint256 aPosition = 0x60;
        uint256 bPosition = aPosition + 32 * abiLength(_a);
        uint256 cPosition = bPosition + 32 * abiLength(_b);
        uint256 length = cPosition + 32 * abiLength(_c);

        d = new bytes(length);
        assembly {
            // Store positions
            mstore(add(d, 0x20), aPosition)
            mstore(add(d, 0x40), bPosition)
            mstore(add(d, 0x60), cPosition)
        }

        // Copy memory to correct position
        copy(d, getPtr(_a), aPosition, _a.length);
        copy(d, getPtr(_b), bPosition, _b.length);
        copy(d, getPtr(_c), cPosition, _c.length * 32); // 1 word per address
    }

    function abiLength(bytes memory _a) internal pure returns (uint256) {
        // 1 for length +
        // memory words + 1 if not divisible for 32 to offset word
        return 1 + (_a.length / 32) + (_a.length % 32 > 0 ? 1 : 0);
    }

    function abiLength(address[] _a) internal pure returns (uint256) {
        // 1 for length + 1 per item
        return 1 + _a.length;
    }

    function copy(bytes _d, uint256 _src, uint256 _pos, uint256 _length) internal pure {
        uint dest;
        assembly {
            dest := add(add(_d, 0x20), _pos)
        }
        memcpy(dest, _src, _length + 32);
    }

    function getPtr(bytes memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getPtr(address[] memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getSpecId(bytes _script) internal pure returns (uint32) {
        return uint32At(_script, 0);
    }

    function uint256At(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(_data, add(0x20, _location)))
        }
    }

    function addressAt(bytes _data, uint256 _location) internal pure returns (address result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000),
            0x1000000000000000000000000)
        }
    }

    function uint32At(bytes _data, uint256 _location) internal pure returns (uint32 result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffff00000000000000000000000000000000000000000000000000000000),
            0x100000000000000000000000000000000000000000000000000000000)
        }
    }

    function locationOf(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := add(_data, add(0x20, _location))
        }
    }

    function toBytes(bytes4 _sig) internal pure returns (bytes) {
        bytes memory payload = new bytes(4);
        payload[0] = bytes1(_sig);
        payload[1] = bytes1(_sig << 8);
        payload[2] = bytes1(_sig << 16);
        payload[3] = bytes1(_sig << 24);
        return payload;
    }

    function memcpy(uint _dest, uint _src, uint _len) public pure {
        uint256 src = _src;
        uint256 dest = _dest;
        uint256 len = _len;

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}
//File: contracts/evmscript/EVMScriptRunner.sol
pragma solidity ^0.4.18;








contract EVMScriptRunner is AppStorage, EVMScriptRegistryConstants {
    using ScriptHelpers for bytes;

    function runScript(bytes _script, bytes _input, address[] _blacklist) protectState internal returns (bytes output) {
        // TODO: Too much data flying around, maybe extracting spec id here is cheaper
        address executorAddr = getExecutor(_script);
        require(executorAddr != address(0));

        bytes memory calldataArgs = _script.encode(_input, _blacklist);
        bytes4 sig = IEVMScriptExecutor(0).execScript.selector;

        require(executorAddr.delegatecall(sig, calldataArgs));

        return returnedDataDecoded();
    }

    function getExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getExecutorRegistry().getScriptExecutor(_script));
    }

    // TODO: Internal
    function getExecutorRegistry() internal view returns (IEVMScriptRegistry) {
        address registryAddr = kernel.getApp(EVMSCRIPT_REGISTRY_APP);
        return IEVMScriptRegistry(registryAddr);
    }

    /**
    * @dev copies and returns last&#39;s call data. Needs to ABI decode first
    */
    function returnedDataDecoded() internal view returns (bytes ret) {
        assembly {
            let size := returndatasize
            switch size
            case 0 {}
            default {
                ret := mload(0x40) // free mem ptr get
                mstore(0x40, add(ret, add(size, 0x20))) // free mem ptr set
                returndatacopy(ret, 0x20, sub(size, 0x20)) // copy return data
            }
        }
        return ret;
    }

    modifier protectState {
        address preKernel = kernel;
        bytes32 preAppId = appId;
        _; // exec
        require(kernel == preKernel);
        require(appId == preAppId);
    }
}
//File: contracts/apps/AragonApp.sol
pragma solidity ^0.4.18;







contract AragonApp is AppStorage, Initializable, ACLSyntaxSugar, EVMScriptRunner {
    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)));
        _;
    }

    modifier authP(bytes32 _role, uint256[] params) {
        require(canPerform(msg.sender, _role, params));
        _;
    }

    function canPerform(address _sender, bytes32 _role, uint256[] params) public view returns (bool) {
        bytes memory how; // no need to init memory as it is never used
        if (params.length > 0) {
            uint256 byteLength = params.length * 32;
            assembly {
                how := params // forced casting
                mstore(how, byteLength)
            }
        }
        return address(kernel) == 0 || kernel.hasPermission(_sender, address(this), _role, how);
    }
}

//File: contracts/acl/ACL.sol
pragma solidity 0.4.18;






interface ACLOracle {
    function canPerform(address who, address where, bytes32 what) public view returns (bool);
}


contract ACL is IACL, AragonApp, ACLHelpers {
    bytes32 constant public CREATE_PERMISSIONS_ROLE = keccak256("CREATE_PERMISSIONS_ROLE");

    // whether a certain entity has a permission
    mapping (bytes32 => bytes32) permissions; // 0 for no permission, or parameters id
    mapping (bytes32 => Param[]) public permissionParams;

    // who is the manager of a permission
    mapping (bytes32 => address) permissionManager;

    enum Op { NONE, EQ, NEQ, GT, LT, GTE, LTE, NOT, AND, OR, XOR, IF_ELSE, RET } // op types

    struct Param {
        uint8 id;
        uint8 op;
        uint240 value; // even though value is an uint240 it can store addresses
        // in the case of 32 byte hashes losing 2 bytes precision isn&#39;t a huge deal
        // op and id take less than 1 byte each so it can be kept in 1 sstore
    }

    uint8 constant BLOCK_NUMBER_PARAM_ID = 200;
    uint8 constant TIMESTAMP_PARAM_ID    = 201;
    uint8 constant SENDER_PARAM_ID       = 202;
    uint8 constant ORACLE_PARAM_ID       = 203;
    uint8 constant LOGIC_OP_PARAM_ID     = 204;
    uint8 constant PARAM_VALUE_PARAM_ID  = 205;
    // TODO: Add execution times param type?

    bytes32 constant public EMPTY_PARAM_HASH = keccak256(uint256(0));
    address constant ANY_ENTITY = address(-1);

    modifier onlyPermissionManager(address _app, bytes32 _role) {
        require(msg.sender == getPermissionManager(_app, _role));
        _;
    }

    event SetPermission(address indexed entity, address indexed app, bytes32 indexed role, bool allowed);
    event ChangePermissionManager(address indexed app, bytes32 indexed role, address indexed manager);

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initializes an ACL instance and sets `_permissionsCreator` as the entity that can create other permissions
    * @param _permissionsCreator Entity that will be given permission over createPermission
    */
    function initialize(address _permissionsCreator) onlyInit public {
        initialized();
        require(msg.sender == address(kernel));

        _createPermission(_permissionsCreator, this, CREATE_PERMISSIONS_ROLE, _permissionsCreator);
    }

    /**
    * @dev Creates a permission that wasn&#39;t previously set. Access is limited by the ACL.
    *      If a created permission is removed it is possible to reset it with createPermission.
    * @notice Create a new permission granting `_entity` the ability to perform actions of role `_role` on `_app` (setting `_manager` as the permission manager)
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    * @param _manager Address of the entity that will be able to grant and revoke the permission further.
    */
    function createPermission(address _entity, address _app, bytes32 _role, address _manager) external {
        require(hasPermission(msg.sender, address(this), CREATE_PERMISSIONS_ROLE));

        _createPermission(_entity, _app, _role, _manager);
    }

    /**
    * @dev Grants permission if allowed. This requires `msg.sender` to be the permission manager
    * @notice Grants `_entity` the ability to perform actions of role `_role` on `_app`
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    */
    function grantPermission(address _entity, address _app, bytes32 _role)
        external
    {
        grantPermissionP(_entity, _app, _role, new uint256[](0));
    }

    /**
    * @dev Grants a permission with parameters if allowed. This requires `msg.sender` to be the permission manager
    * @notice Grants `_entity` the ability to perform actions of role `_role` on `_app`
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    * @param _params Permission parameters
    */
    function grantPermissionP(address _entity, address _app, bytes32 _role, uint256[] _params)
        onlyPermissionManager(_app, _role)
        public
    {
        require(!hasPermission(_entity, _app, _role));

        bytes32 paramsHash = _params.length > 0 ? _saveParams(_params) : EMPTY_PARAM_HASH;
        _setPermission(_entity, _app, _role, paramsHash);
    }

    /**
    * @dev Revokes permission if allowed. This requires `msg.sender` to be the the permission manager
    * @notice Revokes `_entity` the ability to perform actions of role `_role` on `_app`
    * @param _entity Address of the whitelisted entity to revoke access from
    * @param _app Address of the app in which the role will be revoked
    * @param _role Identifier for the group of actions in app being revoked
    */
    function revokePermission(address _entity, address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        require(hasPermission(_entity, _app, _role));

        _setPermission(_entity, _app, _role, bytes32(0));
    }

    /**
    * @notice Sets `_newManager` as the manager of the permission `_role` in `_app`
    * @param _newManager Address for the new manager
    * @param _app Address of the app in which the permission management is being transferred
    * @param _role Identifier for the group of actions being transferred
    */
    function setPermissionManager(address _newManager, address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        _setPermissionManager(_newManager, _app, _role);
    }

    /**
    * @dev Get manager for permission
    * @param _app Address of the app
    * @param _role Identifier for a group of actions in app
    * @return address of the manager for the permission
    */
    function getPermissionManager(address _app, bytes32 _role) public view returns (address) {
        return permissionManager[roleHash(_app, _role)];
    }

    /**
    * @dev Function called by apps to check ACL on kernel or to check permission statu
    * @param _who Sender of the original call
    * @param _where Address of the app
    * @param _where Identifier for a group of actions in app
    * @param _how Permission parameters
    * @return boolean indicating whether the ACL allows the role or not
    */
    function hasPermission(address _who, address _where, bytes32 _what, bytes memory _how) public view returns (bool) {
        uint256[] memory how;
        uint256 intsLength = _how.length / 32;
        assembly {
            how := _how // forced casting
            mstore(how, intsLength)
        }
        // _how is invalid from this point fwd
        return hasPermission(_who, _where, _what, how);
    }

    function hasPermission(address _who, address _where, bytes32 _what, uint256[] memory _how) public view returns (bool) {
        bytes32 whoParams = permissions[permissionHash(_who, _where, _what)];
        if (whoParams != bytes32(0) && evalParams(whoParams, _who, _where, _what, _how)) {
            return true;
        }

        bytes32 anyParams = permissions[permissionHash(ANY_ENTITY, _where, _what)];
        if (anyParams != bytes32(0) && evalParams(anyParams, ANY_ENTITY, _where, _what, _how)) {
            return true;
        }

        return false;
    }

    function hasPermission(address _who, address _where, bytes32 _what) public view returns (bool) {
        uint256[] memory empty = new uint256[](0);
        return hasPermission(_who, _where, _what, empty);
    }

    /**
    * @dev Internal createPermission for access inside the kernel (on instantiation)
    */
    function _createPermission(address _entity, address _app, bytes32 _role, address _manager) internal {
        // only allow permission creation (or re-creation) when there is no manager
        require(getPermissionManager(_app, _role) == address(0));

        _setPermission(_entity, _app, _role, EMPTY_PARAM_HASH);
        _setPermissionManager(_manager, _app, _role);
    }

    /**
    * @dev Internal function called to actually save the permission
    */
    function _setPermission(address _entity, address _app, bytes32 _role, bytes32 _paramsHash) internal {
        permissions[permissionHash(_entity, _app, _role)] = _paramsHash;

        SetPermission(_entity, _app, _role, _paramsHash != bytes32(0));
    }

    function _saveParams(uint256[] _encodedParams) internal returns (bytes32) {
        bytes32 paramHash = keccak256(_encodedParams);
        Param[] storage params = permissionParams[paramHash];

        if (params.length == 0) { // params not saved before
            for (uint256 i = 0; i < _encodedParams.length; i++) {
                uint256 encodedParam = _encodedParams[i];
                Param memory param = Param(decodeParamId(encodedParam), decodeParamOp(encodedParam), uint240(encodedParam));
                params.push(param);
            }
        }

        return paramHash;
    }

    function evalParams(
        bytes32 _paramsHash,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) internal view returns (bool)
    {
        if (_paramsHash == EMPTY_PARAM_HASH) {
            return true;
        }

        return evalParam(_paramsHash, 0, _who, _where, _what, _how);
    }

    function evalParam(
        bytes32 _paramsHash,
        uint32 _paramId,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) internal view returns (bool)
    {
        if (_paramId >= permissionParams[_paramsHash].length) {
            return false; // out of bounds
        }

        Param memory param = permissionParams[_paramsHash][_paramId];

        if (param.id == LOGIC_OP_PARAM_ID) {
            return evalLogic(param, _paramsHash, _who, _where, _what, _how);
        }

        uint256 value;
        uint256 comparedTo = uint256(param.value);

        // get value
        if (param.id == ORACLE_PARAM_ID) {
            value = ACLOracle(param.value).canPerform(_who, _where, _what) ? 1 : 0;
            comparedTo = 1;
        } else if (param.id == BLOCK_NUMBER_PARAM_ID) {
            value = blockN();
        } else if (param.id == TIMESTAMP_PARAM_ID) {
            value = time();
        } else if (param.id == SENDER_PARAM_ID) {
            value = uint256(msg.sender);
        } else if (param.id == PARAM_VALUE_PARAM_ID) {
            value = uint256(param.value);
        } else {
            if (param.id >= _how.length) {
                return false;
            }
            value = uint256(uint240(_how[param.id])); // force lost precision
        }

        if (Op(param.op) == Op.RET) {
            return uint256(value) > 0;
        }

        return compare(value, Op(param.op), comparedTo);
    }

    function evalLogic(Param _param, bytes32 _paramsHash, address _who, address _where, bytes32 _what, uint256[] _how) internal view returns (bool) {
        if (Op(_param.op) == Op.IF_ELSE) {
            var (condition, success, failure) = decodeParamsList(uint256(_param.value));
            bool result = evalParam(_paramsHash, condition, _who, _where, _what, _how);

            return evalParam(_paramsHash, result ? success : failure, _who, _where, _what, _how);
        }

        var (v1, v2,) = decodeParamsList(uint256(_param.value));
        bool r1 = evalParam(_paramsHash, v1, _who, _where, _what, _how);

        if (Op(_param.op) == Op.NOT) {
            return !r1;
        }

        if (r1 && Op(_param.op) == Op.OR) {
            return true;
        }

        if (!r1 && Op(_param.op) == Op.AND) {
            return false;
        }

        bool r2 = evalParam(_paramsHash, v2, _who, _where, _what, _how);

        if (Op(_param.op) == Op.XOR) {
            return (r1 && !r2) || (!r1 && r2);
        }

        return r2; // both or and and depend on result of r2 after checks
    }

    function compare(uint256 _a, Op _op, uint256 _b) internal pure returns (bool) {
        if (_op == Op.EQ)  return _a == _b;                              // solium-disable-line lbrace
        if (_op == Op.NEQ) return _a != _b;                              // solium-disable-line lbrace
        if (_op == Op.GT)  return _a > _b;                               // solium-disable-line lbrace
        if (_op == Op.LT)  return _a < _b;                               // solium-disable-line lbrace
        if (_op == Op.GTE) return _a >= _b;                              // solium-disable-line lbrace
        if (_op == Op.LTE) return _a <= _b;                              // solium-disable-line lbrace
        return false;
    }

    /**
    * @dev Internal function that sets management
    */
    function _setPermissionManager(address _newManager, address _app, bytes32 _role) internal {
        permissionManager[roleHash(_app, _role)] = _newManager;
        ChangePermissionManager(_app, _role, _newManager);
    }

    function roleHash(address _where, bytes32 _what) pure internal returns (bytes32) {
        return keccak256(uint256(1), _where, _what);
    }

    function permissionHash(address _who, address _where, bytes32 _what) pure internal returns (bytes32) {
        return keccak256(uint256(2), _who, _where, _what);
    }

    function time() internal view returns (uint64) { return uint64(block.timestamp); } // solium-disable-line security/no-block-members

    function blockN() internal view returns (uint256) { return block.number; }
}

//File: contracts/evmscript/EVMScriptRegistry.sol
pragma solidity 0.4.18;








contract EVMScriptRegistry is IEVMScriptRegistry, EVMScriptRegistryConstants, AragonApp {
    using ScriptHelpers for bytes;

    // WARN: Manager can censor all votes and the like happening in an org
    bytes32 constant public REGISTRY_MANAGER_ROLE = bytes32(1);

    struct ExecutorEntry {
        address executor;
        bool enabled;
    }

    ExecutorEntry[] public executors;

    function initialize() onlyInit public {
        initialized();
        // Create empty record to begin executor IDs at 1
        executors.push(ExecutorEntry(address(0), false));
    }

    function addScriptExecutor(address _executor) external auth(REGISTRY_MANAGER_ROLE) returns (uint id) {
        return executors.push(ExecutorEntry(_executor, true));
    }

    function disableScriptExecutor(uint256 _executorId) external auth(REGISTRY_MANAGER_ROLE) {
        executors[_executorId].enabled = false;
    }

    function getScriptExecutor(bytes _script) public view returns (address) {
        uint256 id = _script.getSpecId();

        if (id == 0 || id >= executors.length) {
            return address(0);
        }

        ExecutorEntry storage entry = executors[id];
        return entry.enabled ? entry.executor : address(0);
    }
}

//File: contracts/evmscript/executors/CallsScript.sol
pragma solidity ^0.4.18;

// Inspired by https://github.com/reverendus/tx-manager





contract CallsScript is IEVMScriptExecutor {
    using ScriptHelpers for bytes;

    uint256 constant internal SCRIPT_START_LOCATION = 4;

    event LogScriptCall(address indexed sender, address indexed src, address indexed dst);

    /**
    * @notice Executes a number of call scripts
    * @param _script [ specId (uint32) ] many calls with this structure ->
    *    [ to (address: 20 bytes) ] [ calldataLength (uint32: 4 bytes) ] [ calldata (calldataLength bytes) ]
    * @param _input Input is ignored in callscript
    * @param _blacklist Addresses the script cannot call to, or will revert.
    * @return always returns empty byte array
    */
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        uint256 location = SCRIPT_START_LOCATION; // first 32 bits are spec id
        while (location < _script.length) {
            address contractAddress = _script.addressAt(location);
            // Check address being called is not blacklist
            for (uint i = 0; i < _blacklist.length; i++) {
                require(contractAddress != _blacklist[i]);
            }

            // logged before execution to ensure event ordering in receipt
            // if failed entire execution is reverted regardless
            LogScriptCall(msg.sender, address(this), contractAddress);

            uint256 calldataLength = uint256(_script.uint32At(location + 0x14));
            uint256 calldataStart = _script.locationOf(location + 0x14 + 0x04);

            assembly {
                let success := call(sub(gas, 5000), contractAddress, 0, calldataStart, calldataLength, 0, 0)
                switch success case 0 { revert(0, 0) }
            }

            location += (0x14 + 0x04 + calldataLength);
        }
    }
}
//File: contracts/evmscript/executors/DelegateScript.sol
pragma solidity 0.4.18;





interface DelegateScriptTarget {
    function exec() public;
}


contract DelegateScript is IEVMScriptExecutor {
    using ScriptHelpers for *;

    uint256 constant internal SCRIPT_START_LOCATION = 4;

    /**
    * @notice Executes script by delegatecall into a contract
    * @param _script [ specId (uint32) ][ contract address (20 bytes) ]
    * @param _input ABI encoded call to be made to contract (if empty executes default exec() function)
    * @param _blacklist If any address is passed, will revert.
    * @return Call return data
    */
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        require(_blacklist.length == 0); // dont have ability to control bans, so fail.

        // Script should be spec id + address (20 bytes)
        require(_script.length == SCRIPT_START_LOCATION + 20);
        return delegate(_script.addressAt(SCRIPT_START_LOCATION), _input);
    }

    /**
    * @dev Delegatecall to contract with input data
    */
    function delegate(address _addr, bytes memory _input) internal returns (bytes memory output) {
        require(isContract(_addr));
        require(_addr.delegatecall(_input.length > 0 ? _input : defaultInput()));
        return returnedData();
    }

    function isContract(address _target) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }

    function defaultInput() internal pure returns (bytes) {
        return DelegateScriptTarget(0).exec.selector.toBytes();
    }

    /**
    * @dev copies and returns last&#39;s call data
    */
    function returnedData() internal view returns (bytes ret) {
        assembly {
            let size := returndatasize
            ret := mload(0x40) // free mem ptr get
            mstore(0x40, add(ret, add(size, 0x20))) // free mem ptr set
            mstore(ret, size) // set array length
            returndatacopy(add(ret, 0x20), 0, size) // copy return data
        }
        return ret;
    }
}
//File: contracts/evmscript/executors/DeployDelegateScript.sol
pragma solidity 0.4.18;



// Inspired by: https://github.com/dapphub/ds-proxy/blob/master/src/proxy.sol


contract DeployDelegateScript is DelegateScript {
    uint256 constant internal SCRIPT_START_LOCATION = 4;

    mapping (bytes32 => address) cache;

    /**
    * @notice Executes script by delegatecall into a deployed contract (exec() function)
    * @param _script [ specId (uint32) ][ contractInitcode (bytecode) ]
    * @param _input ABI encoded call to be made to contract (if empty executes default exec() function)
    * @param _blacklist If any address is passed, will revert.
    * @return Call return data
    */
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        require(_blacklist.length == 0); // dont have ability to control bans, so fail.

        bytes32 id = keccak256(_script);
        address deployed = cache[id];
        if (deployed == address(0)) {
            deployed = deploy(_script);
            cache[id] = deployed;
        }

        return DelegateScript.delegate(deployed, _input);
    }

    /**
    * @dev Deploys contract byte code to network
    */
    function deploy(bytes _script) internal returns (address addr) {
        assembly {
            // 0x24 = 0x20 (length) + 0x04 (spec id uint32)
            // Length of code is 4 bytes less than total script size
            addr := create(0, add(_script, 0x24), sub(mload(_script), 0x04))
            switch iszero(extcodesize(addr))
            case 1 { revert(0, 0) } // throw if contract failed to deploy
        }
    }
}
//File: contracts/factory/EVMScriptRegistryFactory.sol
pragma solidity 0.4.18;












contract EVMScriptRegistryFactory is AppProxyFactory, EVMScriptRegistryConstants {
    address public baseReg;
    address public baseCalls;
    address public baseDel;
    address public baseDeployDel;

    function EVMScriptRegistryFactory() public {
        baseReg = address(new EVMScriptRegistry());
        baseCalls = address(new CallsScript());
        baseDel = address(new DelegateScript());
        baseDeployDel = address(new DeployDelegateScript());
    }

    function newEVMScriptRegistry(Kernel _dao, address _root) public returns (EVMScriptRegistry reg) {
        reg = EVMScriptRegistry(_dao.newPinnedAppInstance(EVMSCRIPT_REGISTRY_APP_ID, baseReg));
        reg.initialize();

        ACL acl = ACL(_dao.acl());

        _dao.setApp(_dao.APP_ADDR_NAMESPACE(), EVMSCRIPT_REGISTRY_APP_ID, reg);
        acl.createPermission(this, reg, reg.REGISTRY_MANAGER_ROLE(), this);

        reg.addScriptExecutor(baseCalls);     // spec 1 = CallsScript
        reg.addScriptExecutor(baseDel);       // spec 2 = DelegateScript
        reg.addScriptExecutor(baseDeployDel); // spec 3 = DeployDelegateScript

        acl.revokePermission(this, reg, reg.REGISTRY_MANAGER_ROLE());
        acl.setPermissionManager(_root, reg, reg.REGISTRY_MANAGER_ROLE());

        return reg;
    }
}

//File: contracts/factory/DAOFactory.sol
pragma solidity 0.4.18;









contract DAOFactory {
    address public baseKernel;
    address public baseACL;
    EVMScriptRegistryFactory public regFactory;

    event DeployDAO(address dao);
    event DeployEVMScriptRegistry(address reg);

    function DAOFactory(address _baseKernel, address _baseACL, address _regFactory) public {
        // No need to init as it cannot be killed by devops199
        if (_regFactory != address(0)) {
            regFactory = EVMScriptRegistryFactory(_regFactory);
        }

        baseKernel = _baseKernel;
        baseACL = _baseACL;
    }

    /**
    * @param _root Address that will be granted control to setup DAO permissions
    */
    function newDAO(address _root) public returns (Kernel dao) {
        dao = Kernel(new KernelProxy(baseKernel));

        address initialRoot = address(regFactory) != address(0) ? this : _root;
        dao.initialize(baseACL, initialRoot);

        ACL acl = ACL(dao.acl());

        if (address(regFactory) != address(0)) {
            bytes32 permRole = acl.CREATE_PERMISSIONS_ROLE();
            bytes32 appManagerRole = dao.APP_MANAGER_ROLE();

            acl.grantPermission(regFactory, acl, permRole);

            acl.createPermission(regFactory, dao, appManagerRole, this);

            EVMScriptRegistry reg = regFactory.newEVMScriptRegistry(dao, _root);
            DeployEVMScriptRegistry(address(reg));

            acl.revokePermission(regFactory, dao, appManagerRole);
            acl.grantPermission(_root, acl, permRole);

            acl.setPermissionManager(address(0), dao, appManagerRole);
            acl.setPermissionManager(_root, acl, permRole);
        }

        DeployDAO(dao);
    }
}