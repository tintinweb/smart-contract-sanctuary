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