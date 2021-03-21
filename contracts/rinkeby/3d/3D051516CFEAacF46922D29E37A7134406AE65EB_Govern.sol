/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "erc3k/contracts/IERC3000Executor.sol";
import "erc3k/contracts/IERC3000.sol";

import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";
import "@aragon/govern-contract-utils/contracts/adaptive-erc165/AdaptiveERC165.sol";
import "@aragon/govern-contract-utils/contracts/bitmaps/BitmapLib.sol";

import "./erc1271/ERC1271.sol";

contract Govern is AdaptiveERC165 {
    using BitmapLib for bytes32;

    // bytes4 internal constant EXEC_ROLE = this.exec.selector;
    // bytes4 internal constant REGISTER_STANDARD_ROLE = this.registerStandardAndCallback.selector;
    // bytes4 internal constant SET_SIGNATURE_VALIDATOR_ROLE = this.setSignatureValidator.selector;
    uint256 internal constant MAX_ACTIONS = 256;


    event ETHDeposited(address indexed sender, uint256 value);

    constructor(address _initialExecutor)  public {
        initialize(_initialExecutor);
    }

    function initialize(address _initialExecutor) public {
        uint x = 401;
        // _registerStandard(ERC3000_EXEC_INTERFACE_ID);
        // _registerStandard(type(ERC1271).interfaceId);
    }


   

  
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC3000Data.sol";

abstract contract IERC3000Executor {
    bytes4 internal constant ERC3000_EXEC_INTERFACE_ID = this.exec.selector;

    /**
     * @notice Executes all given actions
     * @param actions A array of ERC3000Data.Action for later executing those
     * @param allowFailuresMap A map with the allowed failures
     * @param memo The hash of the ERC3000Data.Container
     * @return failureMap
     * @return execResults
     */
    function exec(ERC3000Data.Action[] memory actions, bytes32 allowFailuresMap, bytes32 memo) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Executed(address indexed actor, ERC3000Data.Action[] actions, bytes32 memo, bytes32 failureMap, bytes[] execResults);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC3000Data.sol";

abstract contract IERC3000 {
    /**
     * @notice Schedules an action for execution, allowing for challenges and vetos on a defined time window
     * @param container A Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @return containerHash
     */
    function schedule(ERC3000Data.Container memory container) virtual public returns (bytes32 containerHash);
    event Scheduled(bytes32 indexed containerHash, ERC3000Data.Payload payload);

    /**
     * @notice Executes an action after its execution delay has passed and its state hasn't been altered by a challenge or veto
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * MUST be an ERC3000Executor call: payload.executor.exec(payload.actions)
     * @return failureMap
     * @return execResults
     */
    function execute(ERC3000Data.Container memory container) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Executed(bytes32 indexed containerHash, address indexed actor);

    /**
     * @notice Challenge a container in case its scheduling is illegal as per Config.rules. Pulls collateral and dispute fees from sender into contract
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param reason Hint for case reviewers as to why the scheduled container is illegal
     * @return resolverId
     */
    function challenge(ERC3000Data.Container memory container, bytes memory reason) virtual public returns (uint256 resolverId);
    event Challenged(bytes32 indexed containerHash, address indexed actor, bytes reason, uint256 resolverId, ERC3000Data.Collateral collateral);

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param resolverId disputeId in the arbitrator in which the dispute over the container was created
     * @return failureMap
     * @return execResults
     */
    function resolve(ERC3000Data.Container memory container, uint256 resolverId) virtual public returns (bytes32 failureMap, bytes[] memory execResults);
    event Resolved(bytes32 indexed containerHash, address indexed actor, bool approved);

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param reason Justification for the veto
     */
    function veto(ERC3000Data.Container memory container, bytes memory reason) virtual public;
    event Vetoed(bytes32 indexed containerHash, address indexed actor, bytes reason);

    /**
     * @notice Apply a new configuration for all *new* containers to be scheduled
     * @param config A ERC3000Data.Config struct holding all the new params that will control the system
     * @return configHash
     */
    function configure(ERC3000Data.Config memory config) virtual public returns (bytes32 configHash);
    event Configured(bytes32 indexed configHash, address indexed actor, ERC3000Data.Config config);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "../initializable/Initializable.sol";

import "./IACLOracle.sol";

library ACLData {
    enum BulkOp { Grant, Revoke, Freeze }

    struct BulkItem {
        BulkOp op;
        bytes4 role;
        address who;
    }
}

contract ACL is Initializable {
    bytes4 public constant ROOT_ROLE =
        this.grant.selector
        ^ this.revoke.selector
        ^ this.freeze.selector
        ^ this.bulk.selector
    ;

    // "Who" constants
    address internal constant ANY_ADDR = address(-1);

    // "Access" flags
    address internal constant UNSET_ROLE = address(0);
    address internal constant FREEZE_FLAG = address(1); // Also used as "who"
    address internal constant ALLOW_FLAG = address(2);

    // Role -> Who -> Access flag (unset or allow) or ACLOracle (any other address denominates auth via ACLOracle)
    mapping (bytes4 => mapping (address => address)) public roles;

    event Granted(bytes4 indexed role, address indexed actor, address indexed who, IACLOracle oracle);
    event Revoked(bytes4 indexed role, address indexed actor, address indexed who);
    event Frozen(bytes4 indexed role, address indexed actor);

    modifier auth(bytes4 _role) {
        require(willPerform(_role, msg.sender, msg.data), "acl: auth");
        _;
    }

    modifier initACL(address _initialRoot) {
        // ACL might have been already initialized by constructors
        if (initBlocks["acl"] == 0) {
            _initializeACL(_initialRoot);
        } else {
            require(roles[ROOT_ROLE][_initialRoot] == ALLOW_FLAG, "acl: initial root misaligned");
        }
        _;
    }

    constructor(address _initialRoot) public initACL(_initialRoot) { }

    function grant(bytes4 _role, address _who) external auth(ROOT_ROLE) {
        _grant(_role, _who);
    }

    function grantWithOracle(bytes4 _role, address _who, IACLOracle _oracle) external auth(ROOT_ROLE) {
        _grantWithOracle(_role, _who, _oracle);
    }

    function revoke(bytes4 _role, address _who) external auth(ROOT_ROLE) {
        _revoke(_role, _who);
    }

    function freeze(bytes4 _role) external auth(ROOT_ROLE) {
        _freeze(_role);
    }

    function bulk(ACLData.BulkItem[] calldata items) external auth(ROOT_ROLE) {
        for (uint256 i = 0; i < items.length; i++) {
            ACLData.BulkItem memory item = items[i];

            if (item.op == ACLData.BulkOp.Grant) _grant(item.role, item.who);
            else if (item.op == ACLData.BulkOp.Revoke) _revoke(item.role, item.who);
            else if (item.op == ACLData.BulkOp.Freeze) _freeze(item.role);
        }
    }

    function willPerform(bytes4 _role, address _who, bytes memory _data) internal returns (bool) {
        // First check if the given who is auth'd, then if any address is auth'd
        return _checkRole(_role, _who, _data) || _checkRole(_role, ANY_ADDR, _data);
    }

    function isFrozen(bytes4 _role) public view returns (bool) {
        return roles[_role][FREEZE_FLAG] == FREEZE_FLAG;
    }

    function _initializeACL(address _initialRoot) internal onlyInit("acl") {
        _grant(ROOT_ROLE, _initialRoot);
    }

    function _grant(bytes4 _role, address _who) internal {
        _grantWithOracle(_role, _who, IACLOracle(ALLOW_FLAG));
    }

    function _grantWithOracle(bytes4 _role, address _who, IACLOracle _oracle) internal {
        require(!isFrozen(_role), "acl: frozen");
        require(_who != FREEZE_FLAG, "acl: bad freeze");

        roles[_role][_who] = address(_oracle);
        emit Granted(_role, msg.sender, _who, _oracle);
    }

    function _revoke(bytes4 _role, address _who) internal {
        require(!isFrozen(_role), "acl: frozen");

        roles[_role][_who] = UNSET_ROLE;
        emit Revoked(_role, msg.sender, _who);
    }

    function _freeze(bytes4 _role) internal {
        require(!isFrozen(_role), "acl: frozen");

        roles[_role][FREEZE_FLAG] = FREEZE_FLAG;
        emit Frozen(_role, msg.sender);
    }

    function _checkRole(bytes4 _role, address _who, bytes memory _data) internal returns (bool) {
        address accessFlagOrAclOracle = roles[_role][_who];
        if (accessFlagOrAclOracle != UNSET_ROLE) {
            if (accessFlagOrAclOracle == ALLOW_FLAG) return true;

            // Since it's not a flag, assume it's an ACLOracle and try-catch to skip failures
            try IACLOracle(accessFlagOrAclOracle).willPerform(_role, _who, _data) returns (bool allowed) {
                if (allowed) return true;
            } catch { }
        }

        return false;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

import "../erc165/ERC165.sol";

contract AdaptiveERC165 is ERC165 {
    // ERC165 interface ID -> whether it is supported
    mapping (bytes4 => bool) internal standardSupported;
    // Callback function signature -> magic number to return
    mapping (bytes4 => bytes32) internal callbackMagicNumbers;

    bytes32 internal constant UNREGISTERED_CALLBACK = bytes32(0);

    event RegisteredStandard(bytes4 interfaceId);
    event RegisteredCallback(bytes4 sig, bytes4 magicNumber);
    event ReceivedCallback(bytes4 indexed sig, bytes data);

    function supportsInterface(bytes4 _interfaceId) override virtual public view returns (bool) {
        return standardSupported[_interfaceId] || super.supportsInterface(_interfaceId);
    }

    function _handleCallback(bytes4 _sig, bytes memory _data) internal {
        bytes32 magicNumber = callbackMagicNumbers[_sig];
        require(magicNumber != UNREGISTERED_CALLBACK, "adap-erc165: unknown callback");

        emit ReceivedCallback(_sig, _data);

        // low-level return magic number
        assembly {
            mstore(0x00, magicNumber)
            return(0x00, 0x20)
        }
    }

    function _registerStandardAndCallback(bytes4 _interfaceId, bytes4 _callbackSig, bytes4 _magicNumber) internal {
        _registerStandard(_interfaceId);
        _registerCallback(_callbackSig, _magicNumber);
    }

    function _registerStandard(bytes4 _interfaceId) internal {
        standardSupported[_interfaceId] = true;
        emit RegisteredStandard(_interfaceId);
    }

    function _registerCallback(bytes4 _callbackSig, bytes4 _magicNumber) internal {
        callbackMagicNumbers[_callbackSig] = _magicNumber;
        emit RegisteredCallback(_callbackSig, _magicNumber);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

library BitmapLib {
    bytes32 constant internal empty = bytes32(0);

    function flip(bytes32 map, uint8 index) internal pure returns (bytes32) {
        return bytes32(uint256(map) ^ uint256(1) << index);
    }

    function get(bytes32 map, uint8 index) internal pure returns (bool) {
        return (uint256(map) >> index & 1) == 1;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

/**
* @title ERC1271 interface
* @dev see https://eips.ethereum.org/EIPS/eip-1271
*/
abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    /**
    * @dev Should return whether the signature provided is valid for the provided data
    * @param _hash Keccak256 hash of arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    *
    * MUST return the bytes4 magic value 0x1626ba7e when function passes.
    * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    * MUST allow external calls
    */
    function isValidSignature(bytes32 _hash, bytes memory _signature) virtual public view returns (bytes4 magicValue);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./IERC3000Executor.sol";

library ERC3000Data {
    // TODO: come up with a non-shitty name
    struct Container {
        Payload payload;
        Config config;
    }

    // WARN: Always remember to change the 'hash' function if modifying the struct
    struct Payload {
        uint256 nonce;
        uint256 executionTime;
        address submitter;
        IERC3000Executor executor;
        Action[] actions;
        bytes32 allowFailuresMap;
        bytes proof;
    }

    struct Action {
        address to;
        uint256 value;
        bytes data;
    }

    struct Config {
        uint256 executionDelay;
        Collateral scheduleDeposit;
        Collateral challengeDeposit;
        address resolver;
        bytes rules;
        uint256 maxCalldataSize;
    }

    struct Collateral {
        address token;
        uint256 amount;
    }

    function containerHash(bytes32 payloadHash, bytes32 configHash) internal view returns (bytes32) {
        uint chainId;
        assembly {
            chainId := chainid()
        }

        return keccak256(abi.encodePacked("erc3k-v1", address(this), chainId, payloadHash, configHash));
    }

    function hash(Container memory container) internal view returns (bytes32) {
        return containerHash(hash(container.payload), hash(container.config));
    }

    function hash(Payload memory payload) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                payload.nonce,
                payload.executionTime,
                payload.submitter,
                payload.executor,
                keccak256(abi.encode(payload.actions)),
                payload.allowFailuresMap,
                keccak256(payload.proof)
            )
        );
    }

    function hash(Config memory config) internal pure returns (bytes32) {
        return keccak256(abi.encode(config));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

contract Initializable {
    mapping (string => uint256) public initBlocks;

    event Initialized(string indexed key);

    modifier onlyInit(string memory key) {
        require(initBlocks[key] == 0, "initializable: already initialized");
        initBlocks[key] = block.number;
        _;
        emit Initialized(key);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

interface IACLOracle {
    function willPerform(bytes4 role, address who, bytes calldata data) external returns (bool allowed);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

abstract contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) virtual public view returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}