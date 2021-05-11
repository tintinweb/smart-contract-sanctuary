pragma solidity 0.4.24;

import "../apps/AragonApp.sol";
import "../common/ConversionHelpers.sol";
import "../common/TimeHelpers.sol";
import "./ACLSyntaxSugar.sol";
import "./IACL.sol";
import "./IACLOracle.sol";


/* solium-disable function-order */
// Allow public initialize() to be first
contract ACL is IACL, TimeHelpers, AragonApp, ACLHelpers {
    /* Hardcoded constants to save gas
    bytes32 public constant CREATE_PERMISSIONS_ROLE = keccak256("CREATE_PERMISSIONS_ROLE");
    */
    bytes32 public constant CREATE_PERMISSIONS_ROLE = 0x0b719b33c83b8e5d300c521cb8b54ae9bd933996a14bef8c2f4e0285d2d2400a;

    enum Op { NONE, EQ, NEQ, GT, LT, GTE, LTE, RET, NOT, AND, OR, XOR, IF_ELSE } // op types

    struct Param {
        uint8 id;
        uint8 op;
        uint240 value; // even though value is an uint240 it can store addresses
        // in the case of 32 byte hashes losing 2 bytes precision isn't a huge deal
        // op and id take less than 1 byte each so it can be kept in 1 sstore
    }

    uint8 internal constant BLOCK_NUMBER_PARAM_ID = 200;
    uint8 internal constant TIMESTAMP_PARAM_ID    = 201;
    // 202 is unused
    uint8 internal constant ORACLE_PARAM_ID       = 203;
    uint8 internal constant LOGIC_OP_PARAM_ID     = 204;
    uint8 internal constant PARAM_VALUE_PARAM_ID  = 205;
    // TODO: Add execution times param type?

    /* Hardcoded constant to save gas
    bytes32 public constant EMPTY_PARAM_HASH = keccak256(uint256(0));
    */
    bytes32 public constant EMPTY_PARAM_HASH = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
    bytes32 public constant NO_PERMISSION = bytes32(0);
    address public constant ANY_ENTITY = address(-1);
    address public constant BURN_ENTITY = address(1); // address(0) is already used as "no permission manager"

    string private constant ERROR_AUTH_INIT_KERNEL = "ACL_AUTH_INIT_KERNEL";
    string private constant ERROR_AUTH_NO_MANAGER = "ACL_AUTH_NO_MANAGER";
    string private constant ERROR_EXISTENT_MANAGER = "ACL_EXISTENT_MANAGER";

    // Whether someone has a permission
    mapping (bytes32 => bytes32) internal permissions; // permissions hash => params hash
    mapping (bytes32 => Param[]) internal permissionParams; // params hash => params

    // Who is the manager of a permission
    mapping (bytes32 => address) internal permissionManager;

    event SetPermission(address indexed entity, address indexed app, bytes32 indexed role, bool allowed);
    event SetPermissionParams(address indexed entity, address indexed app, bytes32 indexed role, bytes32 paramsHash);
    event ChangePermissionManager(address indexed app, bytes32 indexed role, address indexed manager);

    modifier onlyPermissionManager(address _app, bytes32 _role) {
        require(msg.sender == getPermissionManager(_app, _role), ERROR_AUTH_NO_MANAGER);
        _;
    }

    modifier noPermissionManager(address _app, bytes32 _role) {
        // only allow permission creation (or re-creation) when there is no manager
        require(getPermissionManager(_app, _role) == address(0), ERROR_EXISTENT_MANAGER);
        _;
    }

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initialize an ACL instance and set `_permissionsCreator` as the entity that can create other permissions
    * @param _permissionsCreator Entity that will be given permission over createPermission
    */
    function initialize(address _permissionsCreator) public onlyInit {
        initialized();
        require(msg.sender == address(kernel()), ERROR_AUTH_INIT_KERNEL);

        _createPermission(_permissionsCreator, this, CREATE_PERMISSIONS_ROLE, _permissionsCreator);
    }

    /**
    * @dev Creates a permission that wasn't previously set and managed.
    *      If a created permission is removed it is possible to reset it with createPermission.
    *      This is the **ONLY** way to create permissions and set managers to permissions that don't
    *      have a manager.
    *      In terms of the ACL being initialized, this function implicitly protects all the other
    *      state-changing external functions, as they all require the sender to be a manager.
    * @notice Create a new permission granting `_entity` the ability to perform actions requiring `_role` on `_app`, setting `_manager` as the permission's manager
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    * @param _manager Address of the entity that will be able to grant and revoke the permission further.
    */
    function createPermission(address _entity, address _app, bytes32 _role, address _manager)
        external
        auth(CREATE_PERMISSIONS_ROLE)
        noPermissionManager(_app, _role)
    {
        _createPermission(_entity, _app, _role, _manager);
    }

    /**
    * @dev Grants permission if allowed. This requires `msg.sender` to be the permission manager
    * @notice Grant `_entity` the ability to perform actions requiring `_role` on `_app`
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
    * @notice Grant `_entity` the ability to perform actions requiring `_role` on `_app`
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    * @param _params Permission parameters
    */
    function grantPermissionP(address _entity, address _app, bytes32 _role, uint256[] _params)
        public
        onlyPermissionManager(_app, _role)
    {
        bytes32 paramsHash = _params.length > 0 ? _saveParams(_params) : EMPTY_PARAM_HASH;
        _setPermission(_entity, _app, _role, paramsHash);
    }

    /**
    * @dev Revokes permission if allowed. This requires `msg.sender` to be the the permission manager
    * @notice Revoke from `_entity` the ability to perform actions requiring `_role` on `_app`
    * @param _entity Address of the whitelisted entity to revoke access from
    * @param _app Address of the app in which the role will be revoked
    * @param _role Identifier for the group of actions in app being revoked
    */
    function revokePermission(address _entity, address _app, bytes32 _role)
        external
        onlyPermissionManager(_app, _role)
    {
        _setPermission(_entity, _app, _role, NO_PERMISSION);
    }

    /**
    * @notice Set `_newManager` as the manager of `_role` in `_app`
    * @param _newManager Address for the new manager
    * @param _app Address of the app in which the permission management is being transferred
    * @param _role Identifier for the group of actions being transferred
    */
    function setPermissionManager(address _newManager, address _app, bytes32 _role)
        external
        onlyPermissionManager(_app, _role)
    {
        _setPermissionManager(_newManager, _app, _role);
    }

    /**
    * @notice Remove the manager of `_role` in `_app`
    * @param _app Address of the app in which the permission is being unmanaged
    * @param _role Identifier for the group of actions being unmanaged
    */
    function removePermissionManager(address _app, bytes32 _role)
        external
        onlyPermissionManager(_app, _role)
    {
        _setPermissionManager(address(0), _app, _role);
    }

    /**
    * @notice Burn non-existent `_role` in `_app`, so no modification can be made to it (grant, revoke, permission manager)
    * @param _app Address of the app in which the permission is being burned
    * @param _role Identifier for the group of actions being burned
    */
    function createBurnedPermission(address _app, bytes32 _role)
        external
        auth(CREATE_PERMISSIONS_ROLE)
        noPermissionManager(_app, _role)
    {
        _setPermissionManager(BURN_ENTITY, _app, _role);
    }

    /**
    * @notice Burn `_role` in `_app`, so no modification can be made to it (grant, revoke, permission manager)
    * @param _app Address of the app in which the permission is being burned
    * @param _role Identifier for the group of actions being burned
    */
    function burnPermissionManager(address _app, bytes32 _role)
        external
        onlyPermissionManager(_app, _role)
    {
        _setPermissionManager(BURN_ENTITY, _app, _role);
    }

    /**
     * @notice Get parameters for permission array length
     * @param _entity Address of the whitelisted entity that will be able to perform the role
     * @param _app Address of the app
     * @param _role Identifier for a group of actions in app
     * @return Length of the array
     */
    function getPermissionParamsLength(address _entity, address _app, bytes32 _role) external view returns (uint) {
        return permissionParams[permissions[permissionHash(_entity, _app, _role)]].length;
    }

    /**
    * @notice Get parameter for permission
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app
    * @param _role Identifier for a group of actions in app
    * @param _index Index of parameter in the array
    * @return Parameter (id, op, value)
    */
    function getPermissionParam(address _entity, address _app, bytes32 _role, uint _index)
        external
        view
        returns (uint8, uint8, uint240)
    {
        Param storage param = permissionParams[permissions[permissionHash(_entity, _app, _role)]][_index];
        return (param.id, param.op, param.value);
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
        return hasPermission(_who, _where, _what, ConversionHelpers.dangerouslyCastBytesToUintArray(_how));
    }

    function hasPermission(address _who, address _where, bytes32 _what, uint256[] memory _how) public view returns (bool) {
        bytes32 whoParams = permissions[permissionHash(_who, _where, _what)];
        if (whoParams != NO_PERMISSION && evalParams(whoParams, _who, _where, _what, _how)) {
            return true;
        }

        bytes32 anyParams = permissions[permissionHash(ANY_ENTITY, _where, _what)];
        if (anyParams != NO_PERMISSION && evalParams(anyParams, ANY_ENTITY, _where, _what, _how)) {
            return true;
        }

        return false;
    }

    function hasPermission(address _who, address _where, bytes32 _what) public view returns (bool) {
        uint256[] memory empty = new uint256[](0);
        return hasPermission(_who, _where, _what, empty);
    }

    function evalParams(
        bytes32 _paramsHash,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) public view returns (bool)
    {
        if (_paramsHash == EMPTY_PARAM_HASH) {
            return true;
        }

        return _evalParam(_paramsHash, 0, _who, _where, _what, _how);
    }

    /**
    * @dev Internal createPermission for access inside the kernel (on instantiation)
    */
    function _createPermission(address _entity, address _app, bytes32 _role, address _manager) internal {
        _setPermission(_entity, _app, _role, EMPTY_PARAM_HASH);
        _setPermissionManager(_manager, _app, _role);
    }

    /**
    * @dev Internal function called to actually save the permission
    */
    function _setPermission(address _entity, address _app, bytes32 _role, bytes32 _paramsHash) internal {
        permissions[permissionHash(_entity, _app, _role)] = _paramsHash;
        bool entityHasPermission = _paramsHash != NO_PERMISSION;
        bool permissionHasParams = entityHasPermission && _paramsHash != EMPTY_PARAM_HASH;

        emit SetPermission(_entity, _app, _role, entityHasPermission);
        if (permissionHasParams) {
            emit SetPermissionParams(_entity, _app, _role, _paramsHash);
        }
    }

    function _saveParams(uint256[] _encodedParams) internal returns (bytes32) {
        bytes32 paramHash = keccak256(abi.encodePacked(_encodedParams));
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

    function _evalParam(
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
            return _evalLogic(param, _paramsHash, _who, _where, _what, _how);
        }

        uint256 value;
        uint256 comparedTo = uint256(param.value);

        // get value
        if (param.id == ORACLE_PARAM_ID) {
            value = checkOracle(IACLOracle(param.value), _who, _where, _what, _how) ? 1 : 0;
            comparedTo = 1;
        } else if (param.id == BLOCK_NUMBER_PARAM_ID) {
            value = getBlockNumber();
        } else if (param.id == TIMESTAMP_PARAM_ID) {
            value = getTimestamp();
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

    function _evalLogic(Param _param, bytes32 _paramsHash, address _who, address _where, bytes32 _what, uint256[] _how)
        internal
        view
        returns (bool)
    {
        if (Op(_param.op) == Op.IF_ELSE) {
            uint32 conditionParam;
            uint32 successParam;
            uint32 failureParam;

            (conditionParam, successParam, failureParam) = decodeParamsList(uint256(_param.value));
            bool result = _evalParam(_paramsHash, conditionParam, _who, _where, _what, _how);

            return _evalParam(_paramsHash, result ? successParam : failureParam, _who, _where, _what, _how);
        }

        uint32 param1;
        uint32 param2;

        (param1, param2,) = decodeParamsList(uint256(_param.value));
        bool r1 = _evalParam(_paramsHash, param1, _who, _where, _what, _how);

        if (Op(_param.op) == Op.NOT) {
            return !r1;
        }

        if (r1 && Op(_param.op) == Op.OR) {
            return true;
        }

        if (!r1 && Op(_param.op) == Op.AND) {
            return false;
        }

        bool r2 = _evalParam(_paramsHash, param2, _who, _where, _what, _how);

        if (Op(_param.op) == Op.XOR) {
            return r1 != r2;
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

    function checkOracle(IACLOracle _oracleAddr, address _who, address _where, bytes32 _what, uint256[] _how) internal view returns (bool) {
        bytes4 sig = _oracleAddr.canPerform.selector;

        // a raw call is required so we can return false if the call reverts, rather than reverting
        bytes memory checkCalldata = abi.encodeWithSelector(sig, _who, _where, _what, _how);

        bool ok;
        assembly {
            // send all available gas; if the oracle eats up all the gas, we will eventually revert
            // note that we are currently guaranteed to still have some gas after the call from
            // EIP-150's 63/64 gas forward rule
            ok := staticcall(gas, _oracleAddr, add(checkCalldata, 0x20), mload(checkCalldata), 0, 0)
        }

        if (!ok) {
            return false;
        }

        uint256 size;
        assembly { size := returndatasize }
        if (size != 32) {
            return false;
        }

        bool result;
        assembly {
            let ptr := mload(0x40)       // get next free memory ptr
            returndatacopy(ptr, 0, size) // copy return from above `staticcall`
            result := mload(ptr)         // read data at ptr and set it to result
            mstore(ptr, 0)               // set pointer memory to 0 so it still is the next free ptr
        }

        return result;
    }

    /**
    * @dev Internal function that sets management
    */
    function _setPermissionManager(address _newManager, address _app, bytes32 _role) internal {
        permissionManager[roleHash(_app, _role)] = _newManager;
        emit ChangePermissionManager(_app, _role, _newManager);
    }

    function roleHash(address _where, bytes32 _what) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ROLE", _where, _what));
    }

    function permissionHash(address _who, address _where, bytes32 _what) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("PERMISSION", _who, _where, _what));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

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

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
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

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IACLOracle {
    function canPerform(address who, address where, bytes32 what, uint256[] how) external view returns (bool);
}

pragma solidity 0.4.24;

import "./AppStorage.sol";
import "../common/DepositableDelegateProxy.sol";
import "../kernel/KernelConstants.sol";
import "../kernel/IKernel.sol";


contract AppProxyBase is AppStorage, DepositableDelegateProxy, KernelNamespaceConstants {
    /**
    * @dev Initialize AppProxy
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    constructor(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public {
        setKernel(_kernel);
        setAppId(_appId);

        // Implicit check that kernel is actually a Kernel
        // The EVM doesn't actually provide a way for us to make sure, but we can force a revert to
        // occur if the kernel is set to 0x0 or a non-code address when we try to call a method on
        // it.
        address appCode = getAppBase(_appId);

        // If initialize payload is provided, it will be executed
        if (_initializePayload.length > 0) {
            require(isContract(appCode));
            // Cannot make delegatecall as a delegateproxy.delegatedFwd as it
            // returns ending execution context and halts contract deployment
            require(appCode.delegatecall(_initializePayload));
        }
    }

    function getAppBase(bytes32 _appId) internal view returns (address) {
        return kernel().getApp(KERNEL_APP_BASES_NAMESPACE, _appId);
    }
}

pragma solidity 0.4.24;

import "../common/UnstructuredStorage.sol";
import "../common/IsContract.sol";
import "./AppProxyBase.sol";


contract AppProxyPinned is IsContract, AppProxyBase {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.appStorage.pinnedCode")
    bytes32 internal constant PINNED_CODE_POSITION = 0xdee64df20d65e53d7f51cb6ab6d921a0a6a638a91e942e1d8d02df28e31c038e;

    /**
    * @dev Initialize AppProxyPinned (makes it an un-upgradeable Aragon app)
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    constructor(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
        AppProxyBase(_kernel, _appId, _initializePayload)
        public // solium-disable-line visibility-first
    {
        setPinnedCode(getAppBase(_appId));
        require(isContract(pinnedCode()));
    }

    /**
     * @dev ERC897, the address the proxy would delegate calls to
     */
    function implementation() public view returns (address) {
        return pinnedCode();
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return FORWARDING;
    }

    function setPinnedCode(address _pinnedCode) internal {
        PINNED_CODE_POSITION.setStorageAddress(_pinnedCode);
    }

    function pinnedCode() internal view returns (address) {
        return PINNED_CODE_POSITION.getStorageAddress();
    }
}

pragma solidity 0.4.24;

import "./AppProxyBase.sol";


contract AppProxyUpgradeable is AppProxyBase {
    /**
    * @dev Initialize AppProxyUpgradeable (makes it an upgradeable Aragon app)
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    constructor(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
        AppProxyBase(_kernel, _appId, _initializePayload)
        public // solium-disable-line visibility-first
    {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @dev ERC897, the address the proxy would delegate calls to
     */
    function implementation() public view returns (address) {
        return getAppBase(appId());
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return UPGRADEABLE;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";
import "../kernel/IKernel.sol";


contract AppStorage {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION = 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION = 0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

    function kernel() public view returns (IKernel) {
        return IKernel(KERNEL_POSITION.getStorageAddress());
    }

    function appId() public view returns (bytes32) {
        return APP_ID_POSITION.getStorageBytes32();
    }

    function setKernel(IKernel _kernel) internal {
        KERNEL_POSITION.setStorageAddress(address(_kernel));
    }

    function setAppId(bytes32 _appId) internal {
        APP_ID_POSITION.setStorageBytes32(_appId);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./AppStorage.sol";
import "../acl/ACLSyntaxSugar.sol";
import "../common/Autopetrified.sol";
import "../common/ConversionHelpers.sol";
import "../common/ReentrancyGuard.sol";
import "../common/VaultRecoverable.sol";
import "../evmscript/EVMScriptRunner.sol";


// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
    * @dev Check whether an action can be performed by a sender for a particular role on this app
    * @param _sender Sender of the call
    * @param _role Role on this app
    * @param _params Permission params for the role
    * @return Boolean indicating whether the sender has the permissions to perform the action.
    *         Always returns false if the app hasn't been initialized yet.
    */
    function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return linkedKernel.hasPermission(
            _sender,
            address(this),
            _role,
            ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
        );
    }

    /**
    * @dev Get the recovery vault for the app
    * @return Recovery vault address for the app
    */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Petrifiable.sol";


contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}

pragma solidity ^0.4.24;


library ConversionHelpers {
    string private constant ERROR_IMPROPER_LENGTH = "CONVERSION_IMPROPER_LENGTH";

    function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {
        // Force cast the uint256[] into a bytes array, by overwriting its length
        // Note that the bytes array doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 byteLength = _input.length * 32;
        assembly {
            output := _input
            mstore(output, byteLength)
        }
    }

    function dangerouslyCastBytesToUintArray(bytes memory _input) internal pure returns (uint256[] memory output) {
        // Force cast the bytes array into a uint256[], by overwriting its length
        // Note that the uint256[] doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 intsLength = _input.length / 32;
        require(_input.length == intsLength * 32, ERROR_IMPROPER_LENGTH);

        assembly {
            output := _input
            mstore(output, intsLength)
        }
    }
}

pragma solidity 0.4.24;

import "../common/IsContract.sol";
import "../lib/misc/ERCProxy.sol";


contract DelegateProxy is ERCProxy, IsContract {
    uint256 internal constant FWD_GAS_LIMIT = 10000;

    /**
    * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
    * @param _dst Destination address to perform the delegatecall
    * @param _calldata Calldata for the delegatecall
    */
    function delegatedFwd(address _dst, bytes _calldata) internal {
        require(isContract(_dst));
        uint256 fwdGasLimit = FWD_GAS_LIMIT;

        assembly {
            let result := delegatecall(sub(gas, fwdGasLimit), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

pragma solidity 0.4.24;

import "./DelegateProxy.sol";
import "./DepositableStorage.sol";


contract DepositableDelegateProxy is DepositableStorage, DelegateProxy {
    event ProxyDeposit(address sender, uint256 value);

    function () external payable {
        uint256 forwardGasThreshold = FWD_GAS_LIMIT;
        bytes32 isDepositablePosition = DEPOSITABLE_POSITION;

        // Optimized assembly implementation to prevent EIP-1884 from breaking deposits, reference code in Solidity:
        // https://github.com/aragon/aragonOS/blob/v4.2.1/contracts/common/DepositableDelegateProxy.sol#L10-L20
        assembly {
            // Continue only if the gas left is lower than the threshold for forwarding to the implementation code,
            // otherwise continue outside of the assembly block.
            if lt(gas, forwardGasThreshold) {
                // Only accept the deposit and emit an event if all of the following are true:
                // the proxy accepts deposits (isDepositable), msg.data.length == 0, and msg.value > 0
                if and(and(sload(isDepositablePosition), iszero(calldatasize)), gt(callvalue, 0)) {
                    // Equivalent Solidity code for emitting the event:
                    // emit ProxyDeposit(msg.sender, msg.value);

                    let logData := mload(0x40) // free memory pointer
                    mstore(logData, caller) // add 'msg.sender' to the log data (first event param)
                    mstore(add(logData, 0x20), callvalue) // add 'msg.value' to the log data (second event param)

                    // Emit an event with one topic to identify the event: keccak256('ProxyDeposit(address,uint256)') = 0x15ee...dee1
                    log1(logData, 0x40, 0x15eeaa57c7bd188c1388020bcadc2c436ec60d647d36ef5b9eb3c742217ddee1)

                    stop() // Stop. Exits execution context
                }

                // If any of above checks failed, revert the execution (if ETH was sent, it is returned to the sender)
                revert(0, 0)
            }
        }

        address target = implementation();
        delegatedFwd(target, msg.data);
    }
}

pragma solidity 0.4.24;

import "./UnstructuredStorage.sol";


contract DepositableStorage {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.depositableStorage.depositable")
    bytes32 internal constant DEPOSITABLE_POSITION = 0x665fd576fbbe6f247aff98f5c94a561e3f71ec2d3c988d56f12d342396c50cea;

    function isDepositable() public view returns (bool) {
        return DEPOSITABLE_POSITION.getStorageBool();
    }

    function setDepositable(bool _depositable) internal {
        DEPOSITABLE_POSITION.setStorageBool(_depositable);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./TimeHelpers.sol";
import "./UnstructuredStorage.sol";


contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Initializable.sol";


contract Petrifiable is Initializable {
    // Use block UINT256_MAX (which should be never) as the initializable date
    uint256 internal constant PETRIFIED_BLOCK = uint256(-1);

    function isPetrified() public view returns (bool) {
        return getInitializationBlock() == PETRIFIED_BLOCK;
    }

    /**
    * @dev Function to be called by top level contract to prevent being initialized.
    *      Useful for freezing base contracts when they're used behind proxies.
    */
    function petrify() internal onlyInit {
        initializedAt(PETRIFIED_BLOCK);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";


contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }

    /**
    * @dev Static call into ERC20.totalSupply().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticTotalSupply(ERC20 _token) internal view returns (uint256) {
        bytes memory totalSupplyCallData = abi.encodeWithSelector(_token.totalSupply.selector);

        (bool success, uint256 totalSupply) = staticInvoke(_token, totalSupplyCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return totalSupply;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";
import "./EtherTokenConstant.sol";
import "./IsContract.sol";
import "./IVaultRecoverable.sol";
import "./SafeERC20.sol";


contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

pragma solidity 0.4.24;

import "../apps/AragonApp.sol";
import "./ScriptHelpers.sol";
import "./IEVMScriptExecutor.sol";
import "./IEVMScriptRegistry.sol";


/* solium-disable function-order */
// Allow public initialize() to be first
contract EVMScriptRegistry is IEVMScriptRegistry, EVMScriptRegistryConstants, AragonApp {
    using ScriptHelpers for bytes;

    /* Hardcoded constants to save gas
    bytes32 public constant REGISTRY_ADD_EXECUTOR_ROLE = keccak256("REGISTRY_ADD_EXECUTOR_ROLE");
    bytes32 public constant REGISTRY_MANAGER_ROLE = keccak256("REGISTRY_MANAGER_ROLE");
    */
    bytes32 public constant REGISTRY_ADD_EXECUTOR_ROLE = 0xc4e90f38eea8c4212a009ca7b8947943ba4d4a58d19b683417f65291d1cd9ed2;
    // WARN: Manager can censor all votes and the like happening in an org
    bytes32 public constant REGISTRY_MANAGER_ROLE = 0xf7a450ef335e1892cb42c8ca72e7242359d7711924b75db5717410da3f614aa3;

    uint256 internal constant SCRIPT_START_LOCATION = 4;

    string private constant ERROR_INEXISTENT_EXECUTOR = "EVMREG_INEXISTENT_EXECUTOR";
    string private constant ERROR_EXECUTOR_ENABLED = "EVMREG_EXECUTOR_ENABLED";
    string private constant ERROR_EXECUTOR_DISABLED = "EVMREG_EXECUTOR_DISABLED";
    string private constant ERROR_SCRIPT_LENGTH_TOO_SHORT = "EVMREG_SCRIPT_LENGTH_TOO_SHORT";

    struct ExecutorEntry {
        IEVMScriptExecutor executor;
        bool enabled;
    }

    uint256 private executorsNextIndex;
    mapping (uint256 => ExecutorEntry) public executors;

    event EnableExecutor(uint256 indexed executorId, address indexed executorAddress);
    event DisableExecutor(uint256 indexed executorId, address indexed executorAddress);

    modifier executorExists(uint256 _executorId) {
        require(_executorId > 0 && _executorId < executorsNextIndex, ERROR_INEXISTENT_EXECUTOR);
        _;
    }

    /**
    * @notice Initialize the registry
    */
    function initialize() public onlyInit {
        initialized();
        // Create empty record to begin executor IDs at 1
        executorsNextIndex = 1;
    }

    /**
    * @notice Add a new script executor with address `_executor` to the registry
    * @param _executor Address of the IEVMScriptExecutor that will be added to the registry
    * @return id Identifier of the executor in the registry
    */
    function addScriptExecutor(IEVMScriptExecutor _executor) external auth(REGISTRY_ADD_EXECUTOR_ROLE) returns (uint256 id) {
        uint256 executorId = executorsNextIndex++;
        executors[executorId] = ExecutorEntry(_executor, true);
        emit EnableExecutor(executorId, _executor);
        return executorId;
    }

    /**
    * @notice Disable script executor with ID `_executorId`
    * @param _executorId Identifier of the executor in the registry
    */
    function disableScriptExecutor(uint256 _executorId)
        external
        authP(REGISTRY_MANAGER_ROLE, arr(_executorId))
    {
        // Note that we don't need to check for an executor's existence in this case, as only
        // existing executors can be enabled
        ExecutorEntry storage executorEntry = executors[_executorId];
        require(executorEntry.enabled, ERROR_EXECUTOR_DISABLED);
        executorEntry.enabled = false;
        emit DisableExecutor(_executorId, executorEntry.executor);
    }

    /**
    * @notice Enable script executor with ID `_executorId`
    * @param _executorId Identifier of the executor in the registry
    */
    function enableScriptExecutor(uint256 _executorId)
        external
        authP(REGISTRY_MANAGER_ROLE, arr(_executorId))
        executorExists(_executorId)
    {
        ExecutorEntry storage executorEntry = executors[_executorId];
        require(!executorEntry.enabled, ERROR_EXECUTOR_ENABLED);
        executorEntry.enabled = true;
        emit EnableExecutor(_executorId, executorEntry.executor);
    }

    /**
    * @dev Get the script executor that can execute a particular script based on its first 4 bytes
    * @param _script EVMScript being inspected
    */
    function getScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        require(_script.length >= SCRIPT_START_LOCATION, ERROR_SCRIPT_LENGTH_TOO_SHORT);
        uint256 id = _script.getSpecId();

        // Note that we don't need to check for an executor's existence in this case, as only
        // existing executors can be enabled
        ExecutorEntry storage entry = executors[id];
        return entry.enabled ? entry.executor : IEVMScriptExecutor(0);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";
import "./IEVMScriptRegistry.sol";

import "../apps/AppStorage.sol";
import "../kernel/KernelConstants.sol";
import "../common/Initializable.sol";


contract EVMScriptRunner is AppStorage, Initializable, EVMScriptRegistryConstants, KernelNamespaceConstants {
    string private constant ERROR_EXECUTOR_UNAVAILABLE = "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED = "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(address indexed executor, bytes script, bytes input, bytes returnData);

    function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getEVMScriptRegistry().getScriptExecutor(_script));
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(bytes _script, bytes _input, address[] _blacklist)
        internal
        isInitialized
        protectState
        returns (bytes)
    {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(sig, _script, _input, _blacklist);

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas,                // forward all gas
                executor,           // address
                add(data, 0x20),    // calldata start
                mload(data),        // calldata length
                0,                  // don't write output (we'll handle this ourselves)
                0                   // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    // Need at least 0x40 bytes returned for properly ABI-encoded bytes values,
                    // revert with "EVMRUN_EXECUTOR_INVALID_RETURN"
                    // See remix: doing a `revert("EVMRUN_EXECUTOR_INVALID_RETURN")` always results in
                    // this memory layout
                    mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                    mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                    mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // reason length
                    mstore(add(output, 0x44), 0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000) // reason

                    revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                }
                default {
                    // Copy result
                    //
                    // Needs to perform an ABI decode for the expected `bytes` return type of
                    // `executor.execScript()` as solidity will automatically ABI encode the returned bytes as:
                    //    [ position of the first dynamic length return value = 0x20 (32 bytes) ]
                    //    [ output length (32 bytes) ]
                    //    [ output content (N bytes) ]
                    //
                    // Perform the ABI decode by ignoring the first 32 bytes of the return data
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize)) // free mem ptr set
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";


contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    */
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script) public view returns (IEVMScriptExecutor);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


library ScriptHelpers {
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
        assembly { mstore(add(payload, 0x20), _sig) }
        return payload;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../../common/Autopetrified.sol";
import "../IEVMScriptExecutor.sol";


contract BaseEVMScriptExecutor is IEVMScriptExecutor, Autopetrified {
    uint256 internal constant SCRIPT_START_LOCATION = 4;
}

pragma solidity 0.4.24;

// Inspired by https://github.com/reverendus/tx-manager

import "../ScriptHelpers.sol";
import "./BaseEVMScriptExecutor.sol";


contract CallsScript is BaseEVMScriptExecutor {
    using ScriptHelpers for bytes;

    /* Hardcoded constants to save gas
    bytes32 internal constant EXECUTOR_TYPE = keccak256("CALLS_SCRIPT");
    */
    bytes32 internal constant EXECUTOR_TYPE = 0x2dc858a00f3e417be1394b87c07158e989ec681ce8cc68a9093680ac1a870302;

    string private constant ERROR_BLACKLISTED_CALL = "EVMCALLS_BLACKLISTED_CALL";
    string private constant ERROR_INVALID_LENGTH = "EVMCALLS_INVALID_LENGTH";

    /* This is manually crafted in assembly
    string private constant ERROR_CALL_REVERTED = "EVMCALLS_CALL_REVERTED";
    */

    event LogScriptCall(address indexed sender, address indexed src, address indexed dst);

    /**
    * @notice Executes a number of call scripts
    * @param _script [ specId (uint32) ] many calls with this structure ->
    *    [ to (address: 20 bytes) ] [ calldataLength (uint32: 4 bytes) ] [ calldata (calldataLength bytes) ]
    * @param _blacklist Addresses the script cannot call to, or will revert.
    * @return Always returns empty byte array
    */
    function execScript(bytes _script, bytes, address[] _blacklist) external isInitialized returns (bytes) {
        uint256 location = SCRIPT_START_LOCATION; // first 32 bits are spec id
        while (location < _script.length) {
            // Check there's at least address + calldataLength available
            require(_script.length - location >= 0x18, ERROR_INVALID_LENGTH);

            address contractAddress = _script.addressAt(location);
            // Check address being called is not blacklist
            for (uint256 i = 0; i < _blacklist.length; i++) {
                require(contractAddress != _blacklist[i], ERROR_BLACKLISTED_CALL);
            }

            // logged before execution to ensure event ordering in receipt
            // if failed entire execution is reverted regardless
            emit LogScriptCall(msg.sender, address(this), contractAddress);

            uint256 calldataLength = uint256(_script.uint32At(location + 0x14));
            uint256 startOffset = location + 0x14 + 0x04;
            uint256 calldataStart = _script.locationOf(startOffset);

            // compute end of script / next location
            location = startOffset + calldataLength;
            require(location <= _script.length, ERROR_INVALID_LENGTH);

            bool success;
            assembly {
                success := call(
                    sub(gas, 5000),       // forward gas left - 5000
                    contractAddress,      // address
                    0,                    // no value
                    calldataStart,        // calldata start
                    calldataLength,       // calldata length
                    0,                    // don't write output
                    0                     // don't write output
                )

                switch success
                case 0 {
                    let ptr := mload(0x40)

                    switch returndatasize
                    case 0 {
                        // No error data was returned, revert with "EVMCALLS_CALL_REVERTED"
                        // See remix: doing a `revert("EVMCALLS_CALL_REVERTED")` always results in
                        // this memory layout
                        mstore(ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                        mstore(add(ptr, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                        mstore(add(ptr, 0x24), 0x0000000000000000000000000000000000000000000000000000000000000016) // reason length
                        mstore(add(ptr, 0x44), 0x45564d43414c4c535f43414c4c5f524556455254454400000000000000000000) // reason

                        revert(ptr, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                    }
                    default {
                        // Forward the full error data
                        returndatacopy(ptr, 0, returndatasize)
                        revert(ptr, returndatasize)
                    }
                }
                default { }
            }
        }
        // No need to allocate empty bytes for the return as this can only be called via an delegatecall
        // (due to the isInitialized modifier)
    }

    function executorType() external pure returns (bytes32) {
        return EXECUTOR_TYPE;
    }
}

pragma solidity 0.4.24;

import "../apps/AppProxyUpgradeable.sol";
import "../apps/AppProxyPinned.sol";


contract AppProxyFactory {
    event NewAppProxy(address proxy, bool isUpgradeable, bytes32 appId);

    /**
    * @notice Create a new upgradeable app instance on `_kernel` with identifier `_appId`
    * @param _kernel App's Kernel reference
    * @param _appId Identifier for app
    * @return AppProxyUpgradeable
    */
    function newAppProxy(IKernel _kernel, bytes32 _appId) public returns (AppProxyUpgradeable) {
        return newAppProxy(_kernel, _appId, new bytes(0));
    }

    /**
    * @notice Create a new upgradeable app instance on `_kernel` with identifier `_appId` and initialization payload `_initializePayload`
    * @param _kernel App's Kernel reference
    * @param _appId Identifier for app
    * @return AppProxyUpgradeable
    */
    function newAppProxy(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyUpgradeable) {
        AppProxyUpgradeable proxy = new AppProxyUpgradeable(_kernel, _appId, _initializePayload);
        emit NewAppProxy(address(proxy), true, _appId);
        return proxy;
    }

    /**
    * @notice Create a new pinned app instance on `_kernel` with identifier `_appId`
    * @param _kernel App's Kernel reference
    * @param _appId Identifier for app
    * @return AppProxyPinned
    */
    function newAppProxyPinned(IKernel _kernel, bytes32 _appId) public returns (AppProxyPinned) {
        return newAppProxyPinned(_kernel, _appId, new bytes(0));
    }

    /**
    * @notice Create a new pinned app instance on `_kernel` with identifier `_appId` and initialization payload `_initializePayload`
    * @param _kernel App's Kernel reference
    * @param _appId Identifier for app
    * @param _initializePayload Proxy initialization payload
    * @return AppProxyPinned
    */
    function newAppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyPinned) {
        AppProxyPinned proxy = new AppProxyPinned(_kernel, _appId, _initializePayload);
        emit NewAppProxy(address(proxy), false, _appId);
        return proxy;
    }
}

pragma solidity 0.4.24;

import "../kernel/IKernel.sol";
import "../kernel/Kernel.sol";
import "../kernel/KernelProxy.sol";

import "../acl/IACL.sol";
import "../acl/ACL.sol";

import "./EVMScriptRegistryFactory.sol";

contract DAOFactory {
    IKernel public baseKernel;
    IACL public baseACL;
    EVMScriptRegistryFactory public regFactory;

    event DeployDAO(address dao);
    event DeployEVMScriptRegistry(address reg);

    /**
     * @notice Create a new DAOFactory, creating DAOs with Kernels proxied to `_baseKernel`, ACLs proxied to `_baseACL`, and new EVMScriptRegistries created from `_regFactory`.
     * @param _baseKernel Base Kernel
     * @param _baseACL Base ACL
     * @param _regFactory EVMScriptRegistry factory
     */
    constructor(
        IKernel _baseKernel,
        IACL _baseACL,
        EVMScriptRegistryFactory _regFactory
    ) public {
        // No need to init as it cannot be killed by devops199
        if (address(_regFactory) != address(0)) {
            regFactory = _regFactory;
        }

        baseKernel = _baseKernel;
        baseACL = _baseACL;
    }

    /**
     * @notice Create a new DAO with `_root` set as the initial admin
     * @param _root Address that will be granted control to setup DAO permissions
     * @return Newly created DAO
     */
    function newDAO(address _root) public returns (Kernel) {
        Kernel dao = Kernel(new KernelProxy(baseKernel));

        if (address(regFactory) == address(0)) {
            dao.initialize(baseACL, _root);
        } else {
            dao.initialize(baseACL, this);

            ACL acl = ACL(dao.acl());
            bytes32 permRole = acl.CREATE_PERMISSIONS_ROLE();
            bytes32 appManagerRole = dao.APP_MANAGER_ROLE();

            acl.grantPermission(regFactory, acl, permRole);

            acl.createPermission(regFactory, dao, appManagerRole, this);

            EVMScriptRegistry reg = regFactory.newEVMScriptRegistry(dao);
            emit DeployEVMScriptRegistry(address(reg));

            // Clean up permissions
            // First, completely reset the APP_MANAGER_ROLE
            acl.revokePermission(regFactory, dao, appManagerRole);
            acl.removePermissionManager(dao, appManagerRole);

            // Then, make root the only holder and manager of CREATE_PERMISSIONS_ROLE
            acl.revokePermission(regFactory, acl, permRole);
            acl.revokePermission(this, acl, permRole);
            acl.grantPermission(_root, acl, permRole);
            acl.setPermissionManager(_root, acl, permRole);
        }

        emit DeployDAO(address(dao));

        return dao;
    }
}

pragma solidity 0.4.24;

import "../evmscript/IEVMScriptExecutor.sol";
import "../evmscript/EVMScriptRegistry.sol";

import "../evmscript/executors/CallsScript.sol";

import "../kernel/Kernel.sol";
import "../acl/ACL.sol";


contract EVMScriptRegistryFactory is EVMScriptRegistryConstants {
    EVMScriptRegistry public baseReg;
    IEVMScriptExecutor public baseCallScript;

    /**
    * @notice Create a new EVMScriptRegistryFactory.
    */
    constructor() public {
        baseReg = new EVMScriptRegistry();
        baseCallScript = IEVMScriptExecutor(new CallsScript());
    }

    /**
    * @notice Install a new pinned instance of EVMScriptRegistry on `_dao`.
    * @param _dao Kernel
    * @return Installed EVMScriptRegistry
    */
    function newEVMScriptRegistry(Kernel _dao) public returns (EVMScriptRegistry reg) {
        bytes memory initPayload = abi.encodeWithSelector(reg.initialize.selector);
        reg = EVMScriptRegistry(_dao.newPinnedAppInstance(EVMSCRIPT_REGISTRY_APP_ID, baseReg, initPayload, true));

        ACL acl = ACL(_dao.acl());

        acl.createPermission(this, reg, reg.REGISTRY_ADD_EXECUTOR_ROLE(), this);

        reg.addScriptExecutor(baseCallScript);     // spec 1 = CallsScript

        // Clean up the permissions
        acl.revokePermission(this, reg, reg.REGISTRY_ADD_EXECUTOR_ROLE());
        acl.removePermissionManager(reg, reg.REGISTRY_ADD_EXECUTOR_ROLE());

        return reg;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../acl/IACL.sol";
import "../common/IVaultRecoverable.sol";


interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}


// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 appId, address app) public;
    function getApp(bytes32 namespace, bytes32 appId) public view returns (address);
}

pragma solidity 0.4.24;

import "./IKernel.sol";
import "./KernelConstants.sol";
import "./KernelStorage.sol";
import "../acl/IACL.sol";
import "../acl/ACLSyntaxSugar.sol";
import "../common/ConversionHelpers.sol";
import "../common/IsContract.sol";
import "../common/Petrifiable.sol";
import "../common/VaultRecoverable.sol";
import "../factory/AppProxyFactory.sol";
import "../lib/misc/ERCProxy.sol";


// solium-disable-next-line max-len
contract Kernel is IKernel, KernelStorage, KernelAppIds, KernelNamespaceConstants, Petrifiable, IsContract, VaultRecoverable, AppProxyFactory, ACLSyntaxSugar {
    /* Hardcoded constants to save gas
    bytes32 public constant APP_MANAGER_ROLE = keccak256("APP_MANAGER_ROLE");
    */
    bytes32 public constant APP_MANAGER_ROLE = 0xb6d92708f3d4817afc106147d969e229ced5c46e65e0a5002a0d391287762bd0;

    string private constant ERROR_APP_NOT_CONTRACT = "KERNEL_APP_NOT_CONTRACT";
    string private constant ERROR_INVALID_APP_CHANGE = "KERNEL_INVALID_APP_CHANGE";
    string private constant ERROR_AUTH_FAILED = "KERNEL_AUTH_FAILED";

    /**
    * @dev Constructor that allows the deployer to choose if the base instance should be petrified immediately.
    * @param _shouldPetrify Immediately petrify this instance so that it can never be initialized
    */
    constructor(bool _shouldPetrify) public {
        if (_shouldPetrify) {
            petrify();
        }
    }

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initialize this kernel instance along with its ACL and set `_permissionsCreator` as the entity that can create other permissions
    * @param _baseAcl Address of base ACL app
    * @param _permissionsCreator Entity that will be given permission over createPermission
    */
    function initialize(IACL _baseAcl, address _permissionsCreator) public onlyInit {
        initialized();

        // Set ACL base
        _setApp(KERNEL_APP_BASES_NAMESPACE, KERNEL_DEFAULT_ACL_APP_ID, _baseAcl);

        // Create ACL instance and attach it as the default ACL app
        IACL acl = IACL(newAppProxy(this, KERNEL_DEFAULT_ACL_APP_ID));
        acl.initialize(_permissionsCreator);
        _setApp(KERNEL_APP_ADDR_NAMESPACE, KERNEL_DEFAULT_ACL_APP_ID, acl);

        recoveryVaultAppId = KERNEL_DEFAULT_VAULT_APP_ID;
    }

    /**
    * @dev Create a new instance of an app linked to this kernel
    * @notice Create a new upgradeable instance of `_appId` app linked to the Kernel, setting its code to `_appBase`
    * @param _appId Identifier for app
    * @param _appBase Address of the app's base implementation
    * @return AppProxy instance
    */
    function newAppInstance(bytes32 _appId, address _appBase)
        public
        auth(APP_MANAGER_ROLE, arr(KERNEL_APP_BASES_NAMESPACE, _appId))
        returns (ERCProxy appProxy)
    {
        return newAppInstance(_appId, _appBase, new bytes(0), false);
    }

    /**
    * @dev Create a new instance of an app linked to this kernel and set its base
    *      implementation if it was not already set
    * @notice Create a new upgradeable instance of `_appId` app linked to the Kernel, setting its code to `_appBase`. `_setDefault ? 'Also sets it as the default app instance.':''`
    * @param _appId Identifier for app
    * @param _appBase Address of the app's base implementation
    * @param _initializePayload Payload for call made by the proxy during its construction to initialize
    * @param _setDefault Whether the app proxy app is the default one.
    *        Useful when the Kernel needs to know of an instance of a particular app,
    *        like Vault for escape hatch mechanism.
    * @return AppProxy instance
    */
    function newAppInstance(bytes32 _appId, address _appBase, bytes _initializePayload, bool _setDefault)
        public
        auth(APP_MANAGER_ROLE, arr(KERNEL_APP_BASES_NAMESPACE, _appId))
        returns (ERCProxy appProxy)
    {
        _setAppIfNew(KERNEL_APP_BASES_NAMESPACE, _appId, _appBase);
        appProxy = newAppProxy(this, _appId, _initializePayload);
        // By calling setApp directly and not the internal functions, we make sure the params are checked
        // and it will only succeed if sender has permissions to set something to the namespace.
        if (_setDefault) {
            setApp(KERNEL_APP_ADDR_NAMESPACE, _appId, appProxy);
        }
    }

    /**
    * @dev Create a new pinned instance of an app linked to this kernel
    * @notice Create a new non-upgradeable instance of `_appId` app linked to the Kernel, setting its code to `_appBase`.
    * @param _appId Identifier for app
    * @param _appBase Address of the app's base implementation
    * @return AppProxy instance
    */
    function newPinnedAppInstance(bytes32 _appId, address _appBase)
        public
        auth(APP_MANAGER_ROLE, arr(KERNEL_APP_BASES_NAMESPACE, _appId))
        returns (ERCProxy appProxy)
    {
        return newPinnedAppInstance(_appId, _appBase, new bytes(0), false);
    }

    /**
    * @dev Create a new pinned instance of an app linked to this kernel and set
    *      its base implementation if it was not already set
    * @notice Create a new non-upgradeable instance of `_appId` app linked to the Kernel, setting its code to `_appBase`. `_setDefault ? 'Also sets it as the default app instance.':''`
    * @param _appId Identifier for app
    * @param _appBase Address of the app's base implementation
    * @param _initializePayload Payload for call made by the proxy during its construction to initialize
    * @param _setDefault Whether the app proxy app is the default one.
    *        Useful when the Kernel needs to know of an instance of a particular app,
    *        like Vault for escape hatch mechanism.
    * @return AppProxy instance
    */
    function newPinnedAppInstance(bytes32 _appId, address _appBase, bytes _initializePayload, bool _setDefault)
        public
        auth(APP_MANAGER_ROLE, arr(KERNEL_APP_BASES_NAMESPACE, _appId))
        returns (ERCProxy appProxy)
    {
        _setAppIfNew(KERNEL_APP_BASES_NAMESPACE, _appId, _appBase);
        appProxy = newAppProxyPinned(this, _appId, _initializePayload);
        // By calling setApp directly and not the internal functions, we make sure the params are checked
        // and it will only succeed if sender has permissions to set something to the namespace.
        if (_setDefault) {
            setApp(KERNEL_APP_ADDR_NAMESPACE, _appId, appProxy);
        }
    }

    /**
    * @dev Set the resolving address of an app instance or base implementation
    * @notice Set the resolving address of `_appId` in namespace `_namespace` to `_app`
    * @param _namespace App namespace to use
    * @param _appId Identifier for app
    * @param _app Address of the app instance or base implementation
    * @return ID of app
    */
    function setApp(bytes32 _namespace, bytes32 _appId, address _app)
        public
        auth(APP_MANAGER_ROLE, arr(_namespace, _appId))
    {
        _setApp(_namespace, _appId, _app);
    }

    /**
    * @dev Set the default vault id for the escape hatch mechanism
    * @param _recoveryVaultAppId Identifier of the recovery vault app
    */
    function setRecoveryVaultAppId(bytes32 _recoveryVaultAppId)
        public
        auth(APP_MANAGER_ROLE, arr(KERNEL_APP_ADDR_NAMESPACE, _recoveryVaultAppId))
    {
        recoveryVaultAppId = _recoveryVaultAppId;
    }

    // External access to default app id and namespace constants to mimic default getters for constants
    /* solium-disable function-order, mixedcase */
    function CORE_NAMESPACE() external pure returns (bytes32) { return KERNEL_CORE_NAMESPACE; }
    function APP_BASES_NAMESPACE() external pure returns (bytes32) { return KERNEL_APP_BASES_NAMESPACE; }
    function APP_ADDR_NAMESPACE() external pure returns (bytes32) { return KERNEL_APP_ADDR_NAMESPACE; }
    function KERNEL_APP_ID() external pure returns (bytes32) { return KERNEL_CORE_APP_ID; }
    function DEFAULT_ACL_APP_ID() external pure returns (bytes32) { return KERNEL_DEFAULT_ACL_APP_ID; }
    /* solium-enable function-order, mixedcase */

    /**
    * @dev Get the address of an app instance or base implementation
    * @param _namespace App namespace to use
    * @param _appId Identifier for app
    * @return Address of the app
    */
    function getApp(bytes32 _namespace, bytes32 _appId) public view returns (address) {
        return apps[_namespace][_appId];
    }

    /**
    * @dev Get the address of the recovery Vault instance (to recover funds)
    * @return Address of the Vault
    */
    function getRecoveryVault() public view returns (address) {
        return apps[KERNEL_APP_ADDR_NAMESPACE][recoveryVaultAppId];
    }

    /**
    * @dev Get the installed ACL app
    * @return ACL app
    */
    function acl() public view returns (IACL) {
        return IACL(getApp(KERNEL_APP_ADDR_NAMESPACE, KERNEL_DEFAULT_ACL_APP_ID));
    }

    /**
    * @dev Function called by apps to check ACL on kernel or to check permission status
    * @param _who Sender of the original call
    * @param _where Address of the app
    * @param _what Identifier for a group of actions in app
    * @param _how Extra data for ACL auth
    * @return Boolean indicating whether the ACL allows the role or not.
    *         Always returns false if the kernel hasn't been initialized yet.
    */
    function hasPermission(address _who, address _where, bytes32 _what, bytes _how) public view returns (bool) {
        IACL defaultAcl = acl();
        return address(defaultAcl) != address(0) && // Poor man's initialization check (saves gas)
            defaultAcl.hasPermission(_who, _where, _what, _how);
    }

    function _setApp(bytes32 _namespace, bytes32 _appId, address _app) internal {
        require(isContract(_app), ERROR_APP_NOT_CONTRACT);
        apps[_namespace][_appId] = _app;
        emit SetApp(_namespace, _appId, _app);
    }

    function _setAppIfNew(bytes32 _namespace, bytes32 _appId, address _app) internal {
        address app = getApp(_namespace, _appId);
        if (app != address(0)) {
            // The only way to set an app is if it passes the isContract check, so no need to check it again
            require(app == _app, ERROR_INVALID_APP_CHANGE);
        } else {
            _setApp(_namespace, _appId, _app);
        }
    }

    modifier auth(bytes32 _role, uint256[] memory _params) {
        require(
            hasPermission(msg.sender, address(this), _role, ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)),
            ERROR_AUTH_FAILED
        );
        _;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract KernelAppIds {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_APP_ID = apmNamehash("kernel");
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = apmNamehash("acl");
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = apmNamehash("vault");
    */
    bytes32 internal constant KERNEL_CORE_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
}


contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

pragma solidity 0.4.24;

import "./IKernel.sol";
import "./KernelConstants.sol";
import "./KernelStorage.sol";
import "../common/DepositableDelegateProxy.sol";
import "../common/IsContract.sol";


contract KernelProxy is IKernelEvents, KernelStorage, KernelAppIds, KernelNamespaceConstants, IsContract, DepositableDelegateProxy {
    /**
    * @dev KernelProxy is a proxy contract to a kernel implementation. The implementation
    *      can update the reference, which effectively upgrades the contract
    * @param _kernelImpl Address of the contract used as implementation for kernel
    */
    constructor(IKernel _kernelImpl) public {
        require(isContract(address(_kernelImpl)));
        apps[KERNEL_CORE_NAMESPACE][KERNEL_CORE_APP_ID] = _kernelImpl;

        // Note that emitting this event is important for verifying that a KernelProxy instance
        // was never upgraded to a malicious Kernel logic contract over its lifespan.
        // This starts the "chain of trust", that can be followed through later SetApp() events
        // emitted during kernel upgrades.
        emit SetApp(KERNEL_CORE_NAMESPACE, KERNEL_CORE_APP_ID, _kernelImpl);
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return UPGRADEABLE;
    }

    /**
    * @dev ERC897, the address the proxy would delegate calls to
    */
    function implementation() public view returns (address) {
        return apps[KERNEL_CORE_NAMESPACE][KERNEL_CORE_APP_ID];
    }
}

pragma solidity 0.4.24;


contract KernelStorage {
    // namespace => app id => address
    mapping (bytes32 => mapping (bytes32 => address)) public apps;
    bytes32 public recoveryVaultAppId;
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ERCProxy {
    uint256 internal constant FORWARDING = 1;
    uint256 internal constant UPGRADEABLE = 2;

    function proxyType() public pure returns (uint256 proxyTypeId);
    function implementation() public view returns (address codeAddr);
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

{
  "evmVersion": "byzantium",
  "libraries": {},
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}