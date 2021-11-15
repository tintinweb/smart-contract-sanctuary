/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;

import "erc3k/contracts/IERC3000.sol";
import "@aragon/govern-core/contracts/Govern.sol";
import "@aragon/govern-contract-utils/contracts/minimal-proxies/ERC1167ProxyFactory.sol";
import "@aragon/govern-contract-utils/contracts/address-utils/AddressUtils.sol";

contract GovernFactory {
    using ERC1167ProxyFactory for address;
    using AddressUtils for address;
    
    address public base;

    constructor() public {
        setupBase();
    }

    function newGovern(IERC3000 _initialExecutor, bytes32 _salt) public returns (Govern govern) {
        if (_salt != bytes32(0)) {
            return Govern(base.clone2(_salt, abi.encodeWithSelector(govern.initialize.selector, _initialExecutor)).toPayable());
        } else {
            return new Govern(address(_initialExecutor));
        }
    }

    function setupBase() private {
        base = address(new Govern(address(2)));
    }
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
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "erc3k/contracts/IERC3000Executor.sol";
import "erc3k/contracts/IERC3000.sol";

import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";
import "@aragon/govern-contract-utils/contracts/adaptive-erc165/AdaptiveERC165.sol";
import "@aragon/govern-contract-utils/contracts/bitmaps/BitmapLib.sol";
import "@aragon/govern-contract-utils/contracts/address-utils/AddressUtils.sol";
import "@aragon/govern-contract-utils/contracts/erc20/ERC20.sol";
import "@aragon/govern-contract-utils/contracts/erc20/SafeERC20.sol";

import "./erc1271/ERC1271.sol";

contract Govern is IERC3000Executor, AdaptiveERC165, ERC1271, ACL {
    using BitmapLib for bytes32;
    using AddressUtils for address;
    using SafeERC20 for ERC20;

    string private constant ERROR_DEPOSIT_AMOUNT_ZERO = "GOVERN_DEPOSIT_AMOUNT_ZERO";
    string private constant ERROR_ETH_DEPOSIT_AMOUNT_MISMATCH = "GOVERN_ETH_DEPOSIT_AMOUNT_MISMATCH";
    string private constant ERROR_TOKEN_NOT_CONTRACT = "GOVERN_TOKEN_NOT_CONTRACT";
    string private constant ERROR_TOKEN_DEPOSIT_FAILED = "GOVERN_TOKEN_DEPOSIT_FAILED";
    string private constant ERROR_TOO_MANY_ACTIONS = "GOVERN_TOO_MANY_ACTIONS";
    string private constant ERROR_ACTION_CALL_FAILED = "GOVERN_ACTION_CALL_FAILED";
    string private constant ERROR_TOKEN_WITHDRAW_FAILED = "GOVERN_TOKEN_WITHDRAW_FAILED";
    string private constant ERROR_ETH_WITHDRAW_FAILED = "GOVERN_ETH_WITHDRAW_FAILED";

    bytes4 internal constant EXEC_ROLE = this.exec.selector;
    bytes4 internal constant WITHDRAW_ROLE = this.withdraw.selector;

    bytes4 internal constant REGISTER_STANDARD_ROLE = this.registerStandardAndCallback.selector;
    bytes4 internal constant SET_SIGNATURE_VALIDATOR_ROLE = this.setSignatureValidator.selector;
    uint256 internal constant MAX_ACTIONS = 256;

    ERC1271 signatureValidator;

    // ETHDeposited and Deposited are both needed. ETHDeposited makes sure that whoever sends funds
    // with `send/transfer`, receive function can still be executed without reverting due to gas cost
    // increases in EIP-2929. To still use `send/transfer`, access list is needed that has the address
    // of the contract(base contract) that is behind the proxy.
    event ETHDeposited(address sender, uint256 amount);

    event Deposited(address indexed sender, address indexed token, uint256 amount, string _reference);
    event Withdrawn(address indexed token, address indexed to, address from, uint256 amount, string _reference);

    constructor(address _initialExecutor) ACL(address(this)) public {
        initialize(_initialExecutor);
    }

    function initialize(address _initialExecutor) public initACL(address(this)) onlyInit("govern") {
        _grant(EXEC_ROLE, address(_initialExecutor));
        _grant(WITHDRAW_ROLE, address(this));

        // freeze the withdraw so that only GovernExecutor can call
        _freeze(WITHDRAW_ROLE);

        _grant(REGISTER_STANDARD_ROLE, address(this));
        _grant(SET_SIGNATURE_VALIDATOR_ROLE, address(this));

        _registerStandard(ERC3000_EXEC_INTERFACE_ID);
        _registerStandard(type(ERC1271).interfaceId);
    }

    receive () external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    fallback () external {
        _handleCallback(msg.sig, msg.data); // WARN: does a low-level return, any code below would be unreacheable
    }

    function deposit(address _token, uint256 _amount, string calldata _reference) external payable {
        require(_amount > 0, ERROR_DEPOSIT_AMOUNT_ZERO);

        if (_token == address(0)) {
            require(msg.value == _amount, ERROR_ETH_DEPOSIT_AMOUNT_MISMATCH);
        } else {
            require(_token.isContract(), ERROR_TOKEN_NOT_CONTRACT);
            require(ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount), ERROR_TOKEN_DEPOSIT_FAILED);
        }
        emit Deposited(msg.sender, _token, _amount, _reference);
    }

    function withdraw(address _token, address _from, address _to, uint256 _amount, string memory _reference) public auth(WITHDRAW_ROLE) {
        if (_token == address(0)) {
            (bool ok, ) = _to.call{value: _amount}("");
            require(ok, ERROR_ETH_WITHDRAW_FAILED);
        } else {
            require(ERC20(_token).safeTransfer(_to, _amount), ERROR_TOKEN_WITHDRAW_FAILED);
        }
        emit Withdrawn(_token, _to, _from, _amount, _reference);
    }

    function exec(ERC3000Data.Action[] memory actions, bytes32 allowFailuresMap, bytes32 memo) override public auth(EXEC_ROLE) returns (bytes32, bytes[] memory) {
        require(actions.length <= MAX_ACTIONS, ERROR_TOO_MANY_ACTIONS); // need to limit since we use 256-bit bitmaps

        bytes[] memory execResults = new bytes[](actions.length);
        bytes32 failureMap = BitmapLib.empty; // start with an empty bitmap

        for (uint256 i = 0; i < actions.length; i++) {
            // TODO: optimize with assembly
            (bool ok, bytes memory ret) = actions[i].to.call{value: actions[i].value}(actions[i].data);
            require(ok || allowFailuresMap.get(uint8(i)), ERROR_ACTION_CALL_FAILED);
            // if a call fails, flip that bit to signal failure
            failureMap = ok ? failureMap : failureMap.flip(uint8(i));
            execResults[i] = ret;
        }

        emit Executed(msg.sender, actions, memo, failureMap, execResults);

        return (failureMap, execResults);
    }

    function registerStandardAndCallback(bytes4 _interfaceId, bytes4 _callbackSig, bytes4 _magicNumber) external auth(REGISTER_STANDARD_ROLE) {
        _registerStandardAndCallback(_interfaceId, _callbackSig, _magicNumber);
    }

    function setSignatureValidator(ERC1271 _signatureValidator) external auth(SET_SIGNATURE_VALIDATOR_ROLE) {
        signatureValidator = _signatureValidator;
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) override public view returns (bytes4) {
        if (address(signatureValidator) == address(0)) return bytes4(0); // invalid magic number
        return signatureValidator.isValidSignature(_hash, _signature); // forward call to set validation contract
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

// Inspired by: https://github.com/optionality/clone-factory

pragma solidity ^0.6.8;

library ERC1167ProxyFactory {
    function clone(address _implementation) internal returns (address cloneAddr) {
        bytes memory createData = generateCreateData(_implementation);

        assembly {
            cloneAddr := create(0, add(createData, 0x20), 55)
        }

        require(cloneAddr != address(0), "proxy-factory: bad create");
    }

    function clone(address _implementation, bytes memory _initData) internal returns (address cloneAddr) {
        cloneAddr = clone(_implementation);
        (bool ok, bytes memory ret) = cloneAddr.call(_initData);

        require(ok, _getRevertMsg(ret));
    }

    function clone2(address _implementation, bytes32 _salt) internal returns (address cloneAddr) {
        bytes memory createData = generateCreateData(_implementation);

        assembly {
            cloneAddr := create2(0, add(createData, 0x20), 55, _salt)
        }

        require(cloneAddr != address(0), "proxy-factory: bad create2");
    }

    function clone2(address _implementation, bytes32 _salt, bytes memory _initData) internal returns (address cloneAddr) {
        cloneAddr = clone2(_implementation, _salt);
        (bool ok, bytes memory ret) = cloneAddr.call(_initData);

        require(ok, _getRevertMsg(ret));
    }

    function generateCreateData(address _implementation) internal pure returns (bytes memory) {
        return abi.encodePacked(
            //---- constructor -----
            bytes10(0x3d602d80600a3d3981f3),
            //---- proxy code -----
            bytes10(0x363d3d373d3d3d363d73),
            _implementation,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
    }

    // From: https://ethereum.stackexchange.com/a/83577
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return '';

        assembly {
            _returnData := add(_returnData, 0x04) // Slice the sighash.
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

library AddressUtils {
    
    function toPayable(address addr) internal pure returns (address payable) {
        return address(bytes20(addr));
    }

    /**
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     */
    function isContract(address addr) internal view returns (bool result) {
        assembly {
            result := iszero(iszero(extcodesize(addr)))
        }
    }
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
        uint256 executionDelay; // how many seconds to wait before being able to call `execute`.
        Collateral scheduleDeposit; // fees for scheduling
        Collateral challengeDeposit; // fees for challenging
        address resolver;  // resolver that will rule the disputes
        bytes rules; // rules of how DAO should be managed
        uint256 maxCalldataSize; // max calldatasize for the schedule
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    // Optional fields 
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);


    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

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

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/aragonOS/blob/next/contracts/common/SafeERC20.sol

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.6.8;

import "../address-utils/AddressUtils.sol";

import "./ERC20.sol";

library SafeERC20 {
    using AddressUtils for address;

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool ret)
    {
        if (!_addr.isContract()) {
            return false;
        }

        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas(),                // forward all
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize()

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := iszero(iszero(mload(ptr)))
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            _token.transfer.selector,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
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
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
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
        return invokeAndCheckSuccess(address(_token), approveCallData);
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

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-core/contracts/GovernRegistry.sol";

import "@aragon/govern-token/contracts/GovernTokenFactory.sol";
import "@aragon/govern-token/contracts/interfaces/IERC20.sol";
import "@aragon/govern-token/contracts/GovernMinter.sol";
import "@aragon/govern-token/contracts/libraries/TokenLib.sol";

import "./core-factories/GovernFactory.sol";
import "./core-factories/GovernQueueFactory.sol";

contract GovernBaseFactory {
    address internal constant ANY_ADDR = address(-1);
    uint256 internal constant MAX_SCHEDULE_ACCESS_LIST_ALLOWED = 10;
    
    string private constant ERROR_SCHEDULE_LIST_EXCEEDED = "basefactory: schedule list exceeded";

    GovernFactory public governFactory;
    GovernQueueFactory public queueFactory;
    GovernTokenFactory public tokenFactory;
    GovernRegistry public registry;
    
    constructor(
        GovernRegistry _registry,
        GovernFactory _governFactory,
        GovernQueueFactory _queueFactory,
        GovernTokenFactory _tokenFactory
    ) public {
        governFactory = _governFactory;
        queueFactory = _queueFactory;
        tokenFactory = _tokenFactory;
        registry = _registry;
    }

    function newGovern(
        TokenLib.TokenConfig calldata _token,
        address[] calldata _scheduleAccessList,
        bool _useProxies,
        ERC3000Data.Config calldata _config,
        string calldata _name
    ) external returns (Govern govern, GovernQueue queue) {
        require(_scheduleAccessList.length <= MAX_SCHEDULE_ACCESS_LIST_ALLOWED, ERROR_SCHEDULE_LIST_EXCEEDED);

        bytes32 salt = _useProxies ? keccak256(abi.encodePacked(_name)) : bytes32(0);

        queue = queueFactory.newQueue(address(this), _config, salt);
        govern = governFactory.newGovern(queue, salt);

        IERC20 token = _token.tokenAddress;
        GovernMinter minter;

        if (address(token) == address(0)) {
            (token, minter) = tokenFactory.newToken(
                govern,
                _token,
                _useProxies
            );

            // if both(scheduleDeposit and challengeDeposit) are non-zero, 
            // they have already been set and no need for a config change.
            if (_config.scheduleDeposit.token == address(0) || _config.challengeDeposit.token == address(0)) {
                // give base factory the permission so that it can change 
                // the config with new token in the same transaction
                queue.grant(queue.configure.selector, address(this));
                
                ERC3000Data.Config memory newConfig = ERC3000Data.Config({
                    executionDelay: _config.executionDelay,
                    scheduleDeposit: ERC3000Data.Collateral({
                        token: _config.scheduleDeposit.token != address(0) ? _config.scheduleDeposit.token : address(token),
                        amount: _config.scheduleDeposit.amount
                    }),
                    challengeDeposit: ERC3000Data.Collateral({
                        token:  _config.challengeDeposit.token != address(0) ? _config.challengeDeposit.token : address(token),
                        amount: _config.challengeDeposit.amount
                    }),
                    resolver: _config.resolver,
                    rules: _config.rules,
                    maxCalldataSize: _config.maxCalldataSize
                });

                queue.configure(newConfig);
                queue.revoke(queue.configure.selector, address(this));
            }
        }

        registry.register(govern, queue, token, address(minter), _name, "");
        
        uint256 bulkSize = _scheduleAccessList.length == 0 ? 7 : 6 + _scheduleAccessList.length;
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](bulkSize);
        
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, queue.execute.selector, ANY_ADDR);
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, queue.challenge.selector, ANY_ADDR);
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Grant, queue.configure.selector, address(govern));
        items[3] = ACLData.BulkItem(ACLData.BulkOp.Revoke, queue.ROOT_ROLE(), address(this));
        items[4] = ACLData.BulkItem(ACLData.BulkOp.Grant, queue.ROOT_ROLE(), address(govern));
        items[5] = ACLData.BulkItem(ACLData.BulkOp.Freeze, queue.ROOT_ROLE(), address(0));

        // If the schedule access list is empty, anyone can schedule
        // otherwise, only the addresses specified are allowed.
        if (_scheduleAccessList.length == 0) { 
            items[6] = ACLData.BulkItem(ACLData.BulkOp.Grant, queue.schedule.selector, ANY_ADDR);
        } else { 
            for (uint256 i = 0; i < _scheduleAccessList.length; i++) {
                items[6 + i] = ACLData.BulkItem(
                    ACLData.BulkOp.Grant, 
                    queue.schedule.selector, 
                    _scheduleAccessList[i]
                );
            }
        }

        queue.bulk(items);
    }
    
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;

import "erc3k/contracts/IERC3000.sol";
import "erc3k/contracts/IERC3000Executor.sol";
import "erc3k/contracts/IERC3000Registry.sol";

import "@aragon/govern-contract-utils/contracts/erc165/ERC165.sol";

contract GovernRegistry is IERC3000Registry {
    mapping(string => bool) public nameUsed;

    function register(
        IERC3000Executor _executor,
        IERC3000 _queue,
        IERC20 _token,
        address minter,
        string calldata _name,
        bytes calldata _initialMetadata
    ) override external
    {
        require(!nameUsed[_name], "registry: name used");

        nameUsed[_name] = true;

        emit Registered(_executor, _queue, _token, minter, msg.sender, _name);
        _setMetadata(_executor, _initialMetadata);
    }

    function setMetadata(bytes memory _metadata) override public {
        _setMetadata(IERC3000Executor(msg.sender), _metadata);
    }

    function _setMetadata(IERC3000Executor _executor, bytes memory _metadata) internal {
        emit SetMetadata(_executor, _metadata);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-contract-utils/contracts/minimal-proxies/ERC1167ProxyFactory.sol";
import "./libraries/TokenLib.sol";

import "erc3k/contracts/IERC3000Executor.sol";

import "./GovernToken.sol";
import "./GovernMinter.sol";
import "./MerkleDistributor.sol";

contract GovernTokenFactory {
    using ERC1167ProxyFactory for address;
    
    address public tokenBase;
    address public minterBase;
    address public distributorBase;

    event CreatedToken(GovernToken token, GovernMinter minter);

    constructor() public {
        setupBases();
    }

    function newToken(
        IERC3000Executor _governExecutor,
        TokenLib.TokenConfig calldata _token,
        bool _useProxies
    ) external returns (
        GovernToken token,
        GovernMinter minter
    ) {
        if (!_useProxies) {
            (token, minter) = _deployContracts(_token.tokenName, _token.tokenSymbol, _token.tokenDecimals);
        } else {
            token = GovernToken(tokenBase.clone(abi.encodeWithSelector(
                token.initialize.selector,
                address(this),
                _token.tokenName,
                _token.tokenSymbol,
                _token.tokenDecimals
            ))); 
            minter = GovernMinter(minterBase.clone(abi.encodeWithSelector(
                minter.initialize.selector,
                token,
                address(this),
                MerkleDistributor(distributorBase)
            )));
        }

        token.changeMinter(address(minter));
        
        if (_token.mintAmount > 0) {
            minter.mint(_token.mintAddress, _token.mintAmount, "initial mint");
        }

        if (_token.merkleRoot != bytes32(0)) {
            minter.merkleMint(_token.merkleRoot, _token.merkleMintAmount, _token.merkleTree, _token.merkleContext);
        }

        bytes4 mintRole = minter.mint.selector ^ minter.merkleMint.selector;
        bytes4 rootRole = minter.ROOT_ROLE();

        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](4);

        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, mintRole, address(_governExecutor));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, rootRole, address(_governExecutor));
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Revoke, mintRole, address(this));
        items[3] = ACLData.BulkItem(ACLData.BulkOp.Revoke, rootRole, address(this));

        minter.bulk(items);

        emit CreatedToken(token, minter);
    }

    function setupBases() private {
        distributorBase = address(new MerkleDistributor(ERC20(tokenBase), bytes32(0)));
        
        (GovernToken token, GovernMinter minter) = _deployContracts(
            "GovernToken base",
            "GTB",
            0
        );
        token.changeMinter(address(minter));

        // test the bases
        minter.mint(msg.sender, 1, "test mint");
        minter.merkleMint(bytes32(0), 1, "no tree", "test merkle mint");

        // store bases
        tokenBase = address(token);
        minterBase = address(minter);
    }

    function _deployContracts(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) internal returns (
        GovernToken token,
        GovernMinter minter
    ) {
        token = new GovernToken(address(this), _tokenName, _tokenSymbol, _tokenDecimals);
        minter = new GovernMinter(GovernToken(token), address(this), MerkleDistributor(distributorBase));
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";
import "@aragon/govern-contract-utils/contracts/minimal-proxies/ERC1167ProxyFactory.sol";

import "./GovernToken.sol";
import "./MerkleDistributor.sol";

contract GovernMinter is ACL {
    using ERC1167ProxyFactory for address;

    bytes4 constant internal MINT_ROLE =
        this.mint.selector ^
        this.merkleMint.selector
    ;

    GovernToken public token;
    address public distributorBase;

    event MintedSingle(address indexed to, uint256 amount, bytes context);
    event MintedMerkle(address indexed distributor, bytes32 indexed merkleRoot, uint256 totalAmount, bytes tree, bytes context);

    constructor(GovernToken _token, address _initialMinter, MerkleDistributor _distributorBase) ACL(_initialMinter) public {
        initialize(_token, _initialMinter, _distributorBase);
    }

    function initialize(GovernToken _token, address _initialMinter, MerkleDistributor _distributorBase) public initACL(_initialMinter) onlyInit("minter") {
        token = _token;
        distributorBase = address(_distributorBase);
        _grant(MINT_ROLE, _initialMinter);
    }

    function mint(address _to, uint256 _amount, bytes calldata _context) external auth(MINT_ROLE) {
        token.mint(_to, _amount);
        emit MintedSingle(_to, _amount, _context);
    }

    function merkleMint(bytes32 _merkleRoot, uint256 _totalAmount, bytes calldata _tree, bytes calldata _context) external auth(MINT_ROLE) returns (MerkleDistributor distributor) {
        address distributorAddr = distributorBase.clone(abi.encodeWithSelector(distributor.initialize.selector, token, _merkleRoot));
        token.mint(distributorAddr, _totalAmount);

        emit MintedMerkle(distributorAddr, _merkleRoot, _totalAmount, _tree, _context);

        return MerkleDistributor(distributorAddr);
    }

    function eject(address _newMinter) external auth(this.eject.selector) {
        token.changeMinter(_newMinter);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

import "../interfaces/IERC20.sol";

library TokenLib {
    
    struct TokenConfig {
        IERC20 tokenAddress;
        uint8  tokenDecimals;
        string tokenName;
        string tokenSymbol;
        address mintAddress; // initial minter address
        uint256 mintAmount; // how much to mint to initial minter address
        // merkle settings
        bytes32 merkleRoot; // merkle distribution root.
        uint256 merkleMintAmount; // how much to mint for the distributor.
        bytes merkleTree; // merkle tree object
        bytes merkleContext; // context/string what's the actual reason is...
    }
    
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-core/contracts/pipelines/GovernQueue.sol";
import "@aragon/govern-contract-utils/contracts/minimal-proxies/ERC1167ProxyFactory.sol";

contract GovernQueueFactory {
    using ERC1167ProxyFactory for address;

    address public base;

    constructor() public {
        setupBase();
    }

    function newQueue(address _aclRoot, ERC3000Data.Config memory _config, bytes32 _salt) public returns (GovernQueue queue) {
        if (_salt != bytes32(0)) {
            return GovernQueue(base.clone2(_salt, abi.encodeWithSelector(queue.initialize.selector, _aclRoot, _config)));
        } else {
            return new GovernQueue(_aclRoot, _config);
        }
    }

    function setupBase() private {
        ERC3000Data.Collateral memory noCollateral;
        ERC3000Data.Config memory config = ERC3000Data.Config(
            3600,  // how many seconds to wait before being able to call `execute`
            noCollateral,
            noCollateral,
            address(0),
            "",
            100000 // initial maxCalldatasize
        );
        base = address(new GovernQueue(address(2), config));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

import "./IERC3000.sol";
import "./IERC3000Executor.sol";

import "@aragon/govern-token/contracts/interfaces/IERC20.sol";

abstract contract IERC3000Registry {
    /**
     * @notice Registers a IERC3000Executor and IERC3000 contract by a name and with his metadata
     * @param executor IERC3000Executor contract
     * @param queue IERC3000 contract
     * @param name The name of this DAO
     * @param token Governance token of the DAO
     * @param initialMetadata Additional data to store for this DAO
     */
    function register(IERC3000Executor executor, IERC3000 queue, IERC20 token, address minter, string calldata name, bytes calldata initialMetadata) virtual external;
    event Registered(IERC3000Executor indexed executor, IERC3000 queue, IERC20 indexed token, address minter, address indexed registrant, string name);

    /**
     * @notice Sets or updates the metadata of a DAO
     * @param metadata Additional data to store for this DAO
     */
    function setMetadata(bytes memory metadata) virtual public;
    event SetMetadata(IERC3000Executor indexed executor, bytes metadata);
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

import '@aragon/govern-contract-utils/contracts/initializable/Initializable.sol';
import '@aragon/govern-contract-utils/contracts/safe-math/SafeMath.sol';

import './interfaces/IERC20.sol';

// Copied and slightly modified from https://github.com/aragon/aragon-network-token/blob/v2-v1.0.0/packages/v2/contracts/token.sol
// Lightweight token modelled after UNI-LP: https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/UniswapV2ERC20.sol
// Adds:
//   - An exposed `mint()` with minting role
//   - An exposed `burn()`
//   - ERC-3009 (`transferWithAuthorization()`)
contract GovernToken is IERC20, Initializable {
    using SafeMath for uint256;

    // bytes32 private constant EIP712DOMAIN_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // bytes32 private constant VERSION_HASH = keccak256("1")
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    //     keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    string public name;
    string public symbol;
    uint8 public decimals;

    address public minter;
    uint256 override public totalSupply;
    mapping (address => uint256) override public balanceOf;
    mapping (address => mapping (address => uint256)) override public allowance;

    // ERC-2612, ERC-3009 state
    mapping (address => uint256) public nonces;
    mapping (address => mapping (bytes32 => bool)) public authorizationState;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event ChangeMinter(address indexed minter);

    modifier onlyMinter {
        require(msg.sender == minter, "token: not minter");
        _;
    }

    constructor(address _initialMinter, string memory _name, string memory _symbol, uint8 _decimals) public {
        initialize(_initialMinter, _name, _symbol, _decimals);
    }

    function initialize(address _initialMinter, string memory _name, string memory _symbol, uint8 _decimals) public onlyInit("token") {
        _changeMinter(_initialMinter);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "token: bad sig");
    }

    function _changeMinter(address newMinter) internal {
        minter = newMinter;
        emit ChangeMinter(newMinter);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        require(to != address(this) && to != address(0), "token: bad to");

        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function getChainId() public pure returns (uint256 chainId) {
        assembly { chainId := chainid() }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_HASH,
                keccak256(abi.encodePacked(name)),
                VERSION_HASH,
                getChainId(),
                address(this)
            )
        );
    }

    function mint(address to, uint256 value) external onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function changeMinter(address newMinter) external onlyMinter {
        _changeMinter(newMinter);
    }

    function burn(uint256 value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function approve(address spender, uint256 value) override external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) override external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override external returns (bool) {
        uint256 fromAllowance = allowance[from][msg.sender];
        if (fromAllowance != uint256(-1)) {
            // Allowance is implicitly checked with SafeMath's underflow protection
            allowance[from][msg.sender] = fromAllowance.sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "token: auth expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(block.timestamp > validAfter, "token: auth wait");
        require(block.timestamp < validBefore, "token: auth expired");
        require(!authorizationState[from][nonce],  "token: auth used");

        bytes32 encodeData = keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

// Copied and modified from: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "@aragon/govern-contract-utils/contracts/erc20/SafeERC20.sol";
import "@aragon/govern-contract-utils/contracts/initializable/Initializable.sol";

contract MerkleDistributor is Initializable {
    
    using SafeERC20 for ERC20;

    ERC20 public token;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping (uint256 => uint256) private claimedBitMap;

    event Claimed(uint256 indexed index, address indexed to, uint256 amount);

    constructor(ERC20 _token, bytes32 _merkleRoot) public {
        initialize(_token, _merkleRoot);
    }

    function initialize(ERC20 _token, bytes32 _merkleRoot) public onlyInit("distributor") {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 _index, address _to, uint256 _amount, bytes32[] calldata _merkleProof) external {
        require(!isClaimed(_index), "dist: already claimed");
        require(_verifyBalanceOnTree(_index, _to, _amount, _merkleProof), "dist: proof failed");

        _setClaimed(_index);
        token.safeTransfer(_to, _amount);

        emit Claimed(_index, _to, _amount);
    }

    function unclaimedBalance(uint256 _index, address _to, uint256 _amount, bytes32[] memory _proof) public view returns (uint256) {
        if (isClaimed(_index)) return 0;
        return _verifyBalanceOnTree(_index, _to, _amount, _proof) ? _amount : 0;
    }

    function _verifyBalanceOnTree(uint256 _index, address _to, uint256 _amount, bytes32[] memory _proof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_index, _to, _amount));
        return MerkleProof.verify(_proof, merkleRoot, node);
    }

    function isClaimed(uint256 _index) public view returns (bool) {
        uint256 claimedWord_index = _index / 256;
        uint256 claimedBit_index = _index % 256;
        uint256 claimedWord = claimedBitMap[claimedWord_index];
        uint256 mask = (1 << claimedBit_index);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 _index) private {
        uint256 claimedWord_index = _index / 256;
        uint256 claimedBit_index = _index % 256;
        claimedBitMap[claimedWord_index] = claimedBitMap[claimedWord_index] | (1 << claimedBit_index);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math: overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "math: underflow");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2; // required for passing structs in calldata (fairly secure at this point)

import "erc3k/contracts/IERC3000.sol";

import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";
import "@aragon/govern-contract-utils/contracts/adaptive-erc165/AdaptiveERC165.sol";
import "@aragon/govern-contract-utils/contracts/deposits/DepositLib.sol";
import "@aragon/govern-contract-utils/contracts/erc20/SafeERC20.sol";
import '@aragon/govern-contract-utils/contracts/safe-math/SafeMath.sol';

import "../protocol/IArbitrable.sol";
import "../protocol/IArbitrator.sol";

library GovernQueueStateLib {
    enum State {
        None,
        Scheduled,
        Challenged,
        Approved,
        Rejected,
        Cancelled,
        Executed
    }

    struct Item {
        State state;
    }

    function checkState(Item storage _item, State _requiredState) internal view {
        require(_item.state == _requiredState, "queue: bad state");
    }

    function setState(Item storage _item, State _state) internal {
        _item.state = _state;
    }

    function checkAndSetState(Item storage _item, State _fromState, State _toState) internal {
        checkState(_item, _fromState);
        setState(_item, _toState);
    }
}

contract GovernQueue is IERC3000, IArbitrable, AdaptiveERC165, ACL {
    // Syntax sugar to enable method-calling syntax on types
    using ERC3000Data for *;
    using DepositLib for ERC3000Data.Collateral;
    using GovernQueueStateLib for GovernQueueStateLib.Item;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    // Map '4' as the 'allow' ruling; this implicitly maps '3' as the 'reject' ruling
    uint256 internal constant ALLOW_RULING = 4;

    // Permanent state
    bytes32 public configHash; // keccak256 hash of the current ERC3000Data.Config
    uint256 public nonce; // number of scheduled payloads so far
    mapping (bytes32 => GovernQueueStateLib.Item) public queue; // container hash -> execution state

    // Temporary state
    mapping (bytes32 => address) public challengerCache; // container hash -> challenger addr (used after challenging and before dispute resolution)
    mapping (bytes32 => mapping (IArbitrator => uint256)) public disputeItemCache; // container hash -> arbitrator addr -> dispute id (used between dispute creation and ruling)

    /**
     * @param _aclRoot account that will be given root permissions on ACL (commonly given to factory)
     * @param _initialConfig initial configuration parameters
     */
    constructor(address _aclRoot, ERC3000Data.Config memory _initialConfig)
        public
        ACL(_aclRoot) // note that this contract directly derives from ACL (ACL is local to contract and not global to system in Govern)
    {
        initialize(_aclRoot, _initialConfig);
    }

    function initialize(address _aclRoot, ERC3000Data.Config memory _initialConfig) public initACL(_aclRoot) onlyInit("queue") {
        _setConfig(_initialConfig);
        _registerStandard(type(IERC3000).interfaceId);
    }

     /**
     * @notice Schedules an action for execution, allowing for challenges and vetos on a defined time window. Pulls collateral from submitter into contract.
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     */
    function schedule(ERC3000Data.Container memory _container) // TO FIX: Container is in memory and function has to be public to avoid an unestrutable solidity crash
        public
        override
        auth(this.schedule.selector) // note that all functions in this contract are ACL protected (commonly some of them will be open for any addr to perform)
        returns (bytes32 containerHash)
    {
        // prevent griefing by front-running (the same container is sent by two different people and one must be challenged)
        // and ensure container hashes are unique
        require(_container.payload.nonce == ++nonce, "queue: bad nonce");
        // hash using ERC3000Data.hash(ERC3000Data.Config)
        bytes32 _configHash = _container.config.hash();
        // ensure that the hash of the config passed in the container matches the current config (implicit agreement approval by scheduler)
        require(_configHash == configHash, "queue: bad config");
        // ensure that the time delta to the execution timestamp provided in the payload is at least after the config's execution delay
        require(_container.payload.executionTime >= _container.config.executionDelay.add(block.timestamp), "queue: bad delay");
        // ensure that the submitter of the payload is also the sender of this call
        require(_container.payload.submitter == msg.sender, "queue: bad submitter");
        // Restrict the size of calldata to _container.config.maxCalldataSize to make sure challenge function stays callable
        uint calldataSize;
        assembly {
            calldataSize := calldatasize()
        }
        require(calldataSize <= _container.config.maxCalldataSize, "calldatasize: limit exceeded");
        // store and set container's hash
        containerHash = ERC3000Data.containerHash(_container.payload.hash(), _configHash);
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.None, // ensure that the state for this container is None
            GovernQueueStateLib.State.Scheduled // and if so perform a state transition to Scheduled
        );
        // we don't need to save any more state about the container in storage
        // we just authenticate the hash and assign it a state, since all future
        // actions regarding the container will need to provide it as a witness
        // all witnesses are logged from this contract at least once, so the
        // trust assumption should be the same as storing all on-chain (move complexity to clients)

        ERC3000Data.Collateral memory collateral = _container.config.scheduleDeposit;
        collateral.collectFrom(_container.payload.submitter); // pull collateral from submitter (requires previous approval)

        // the configured resolver may specify additional out-of-band payments for scheduling actions
        // schedule() leaves these requirements up to the callers of `schedule()` or other users to fulfill

        // emit an event to ensure data availability of all state that cannot be otherwise fetched (see how config isn't emitted since an observer should already have it)
        emit Scheduled(containerHash, _container.payload);
    }

    /**
     * @notice Executes an action after its execution delay has passed and its state hasn't been altered by a challenge or veto
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     */
    function execute(ERC3000Data.Container memory _container)
        public
        override
        auth(this.execute.selector) // in most instances this will be open for any addr, but leaving configurable for flexibility
        returns (bytes32 failureMap, bytes[] memory)
    {
        // ensure enough time has passed
        require(block.timestamp >= _container.payload.executionTime, "queue: wait more");

        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled, // note that we will revert here if the container wasn't previously scheduled
            GovernQueueStateLib.State.Executed
        );

        _container.config.scheduleDeposit.releaseTo(_container.payload.submitter); // release collateral to original submitter

        return _execute(_container.payload, containerHash);
    }

    /**
     * @notice Challenge a container in case its scheduling is illegal as per Config.rules. Pulls collateral and dispute fees from sender into contract
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param _reason Hint for case reviewers as to why the scheduled container is illegal
     */
    function challenge(ERC3000Data.Container memory _container, bytes memory _reason) auth(this.challenge.selector) override public returns (uint256 disputeId) {
        bytes32 containerHash = _container.hash();
        challengerCache[containerHash] = msg.sender; // cache challenger address while it is needed
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled,
            GovernQueueStateLib.State.Challenged
        );

        ERC3000Data.Collateral memory collateral = _container.config.challengeDeposit;
        collateral.collectFrom(msg.sender); // pull challenge collateral from sender

        // create dispute on arbitrator
        IArbitrator arbitrator = IArbitrator(_container.config.resolver);
        (address recipient, ERC20 feeToken, uint256 feeAmount) = arbitrator.getDisputeFees();
        require(feeToken.safeTransferFrom(msg.sender, address(this), feeAmount), "queue: bad fee pull");
        require(feeToken.safeApprove(recipient, feeAmount), "queue: bad approve");
        disputeId = arbitrator.createDispute(2, abi.encode(_container)); // create dispute sending full container ABI encoded (could prob just send payload to save gas)
        require(feeToken.safeApprove(recipient, 0), "queue: bad reset"); // reset just in case non-compliant tokens (that fail on non-zero to non-zero approvals) are used

        // submit both arguments as evidence and close evidence period. no more evidence can be submitted and a settlement can't happen (could happen off-protocol)
        arbitrator.submitEvidence(disputeId, _container.payload.submitter, _container.payload.proof);
        arbitrator.submitEvidence(disputeId, msg.sender, _reason);
        arbitrator.closeEvidencePeriod(disputeId);

        disputeItemCache[containerHash][arbitrator] = disputeId + 1; // cache a relation between disputeId and containerHash while needed

        emit Challenged(containerHash, msg.sender, _reason, disputeId, collateral);
    }

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param _disputeId disputeId in the arbitrator in which the dispute over the container was created
     */
    function resolve(ERC3000Data.Container memory _container, uint256 _disputeId) override public returns (bytes32 failureMap, bytes[] memory) {
        bytes32 containerHash = _container.hash();
        IArbitrator arbitrator = IArbitrator(_container.config.resolver);

        require(disputeItemCache[containerHash][arbitrator] == _disputeId + 1, "queue: bad dispute id");
        delete disputeItemCache[containerHash][arbitrator]; // release state to refund gas; no longer needed in state

        queue[containerHash].checkState(GovernQueueStateLib.State.Challenged);
        (address subject, uint256 ruling) = arbitrator.rule(_disputeId);
        require(subject == address(this), "queue: not subject");
        bool arbitratorApproved = ruling == ALLOW_RULING;

        queue[containerHash].setState(
            arbitratorApproved
              ? GovernQueueStateLib.State.Approved
              : GovernQueueStateLib.State.Rejected
        );

        emit Resolved(containerHash, msg.sender, arbitratorApproved);
        emit Ruled(arbitrator, _disputeId, ruling);

        if (arbitratorApproved) {
            return _executeApproved(_container);
        } else {
            return _settleRejection(_container);
        }
    }

    function veto(ERC3000Data.Container memory _container, bytes memory _reason) auth(this.veto.selector) override public {
        bytes32 containerHash = _container.hash();
        GovernQueueStateLib.Item storage item = queue[containerHash];

        if (item.state == GovernQueueStateLib.State.Challenged) {
            item.checkAndSetState(
                GovernQueueStateLib.State.Challenged,
                GovernQueueStateLib.State.Cancelled
            );

            address challenger = challengerCache[containerHash];
            // release state to refund gas; no longer needed in state
            delete challengerCache[containerHash];
            delete disputeItemCache[containerHash][IArbitrator(_container.config.resolver)];

            // release collateral to challenger and scheduler
            _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
            _container.config.challengeDeposit.releaseTo(challenger);
        } else {
            // If the given container doesn't have the state Challenged
            // has it to be the Scheduled state and otherwise should it throw as expected
            item.checkAndSetState(
                GovernQueueStateLib.State.Scheduled,
                GovernQueueStateLib.State.Cancelled
            );

            _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
        }

        emit Vetoed(containerHash, msg.sender, _reason);
    }

    /**
     * @notice Apply a new configuration for all *new* containers to be scheduled
     * @param _config A ERC3000Data.Config struct holding all the new params that will control the queue
     */
    function configure(ERC3000Data.Config memory _config)
        public
        override
        auth(this.configure.selector)
        returns (bytes32)
    {
        return _setConfig(_config);
    }

    // Internal

    function _executeApproved(ERC3000Data.Container memory _container) internal returns (bytes32 failureMap, bytes[] memory) {
        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Approved,
            GovernQueueStateLib.State.Executed
        );

        delete challengerCache[containerHash]; // release state to refund gas; no longer needed in state

        // release all collateral to submitter
        _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
        _container.config.challengeDeposit.releaseTo(_container.payload.submitter);

        return _execute(_container.payload, containerHash);
    }

    function _settleRejection(ERC3000Data.Container memory _container) internal returns (bytes32, bytes[] memory) {
        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Rejected,
            GovernQueueStateLib.State.Cancelled
        );

        address challenger = challengerCache[containerHash];
        delete challengerCache[containerHash]; // release state to refund gas; no longer needed in state

        // release all collateral to challenger
        _container.config.scheduleDeposit.releaseTo(challenger);
        _container.config.challengeDeposit.releaseTo(challenger);

        // return zero values as nothing is executed on rejection
    }

    function _execute(ERC3000Data.Payload memory _payload, bytes32 _containerHash) internal returns (bytes32, bytes[] memory) {
        emit Executed(_containerHash, msg.sender);
        return _payload.executor.exec(_payload.actions, _payload.allowFailuresMap, _containerHash);
    }

    function _setConfig(ERC3000Data.Config memory _config)
        internal
        returns (bytes32)
    {
        // validate collaterals by calling balanceOf on their interface
        if(_config.challengeDeposit.amount != 0 && _config.challengeDeposit.token != address(0)) {
            (bool ok, bytes memory value) = _config.challengeDeposit.token.call(
                abi.encodeWithSelector(ERC20.balanceOf.selector, address(this))
            );
            require(ok && value.length > 0, "queue: bad config");
        }

        if(_config.scheduleDeposit.amount != 0 && _config.scheduleDeposit.token != address(0)) {
            (bool ok, bytes memory value) = _config.scheduleDeposit.token.call(
                abi.encodeWithSelector(ERC20.balanceOf.selector, address(this))
            );
            require(ok && value.length > 0, "queue: bad config");
        }
        
        configHash = _config.hash();

        emit Configured(configHash, msg.sender, _config);

        return configHash;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

import "erc3k/contracts/ERC3000Data.sol";

import "../erc20/ERC20.sol";
import "../erc20/SafeERC20.sol";

library DepositLib {
    using SafeERC20 for ERC20;

    event Locked(address indexed token, address indexed from, uint256 amount);
    event Unlocked(address indexed token, address indexed to, uint256 amount);

    function collectFrom(ERC3000Data.Collateral memory _collateral, address _from) internal {
        if (_collateral.amount > 0) {
            ERC20 token = ERC20(_collateral.token);
            require(token.safeTransferFrom(_from, address(this), _collateral.amount), "deposit: bad token lock");

            emit Locked(_collateral.token, _from, _collateral.amount);
        }
    }

    function releaseTo(ERC3000Data.Collateral memory _collateral, address _to) internal {
        if (_collateral.amount > 0) {
            ERC20 token = ERC20(_collateral.token);
            require(token.safeTransfer(_to, _collateral.amount), "deposit: bad token release");

            emit Unlocked(_collateral.token, _to, _collateral.amount);
        }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/protocol/blob/f1b3361a160da92b9bb449c0a05dee0c30e41594/packages/evm/contracts/arbitration/IArbitrable.sol

pragma solidity ^0.6.8;

import "./IArbitrator.sol";

/**
* @dev The Arbitrable instances actually don't require to follow any specific interface.
*      Note that this is actually optional, although it does allow the Protocol to at least have a way to identify a specific set of instances.
*/
abstract contract IArbitrable {
    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identification number of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);
}

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/protocol/blob/f1b3361a160da92b9bb449c0a05dee0c30e41594/packages/evm/contracts/arbitration/IArbitrator.sol

pragma solidity ^0.6.8;

import "@aragon/govern-contract-utils/contracts/erc20/ERC20.sol";

interface IArbitrator {
    /**
    * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
    * @param _possibleRulings Number of possible rulings allowed for the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Submit evidence for a dispute
    * @param _disputeId Id of the dispute in the Protocol
    * @param _submitter Address of the account submitting the evidence
    * @param _evidence Data submitted for the evidence related to the dispute
    */
    function submitEvidence(uint256 _disputeId, address _submitter, bytes calldata _evidence) external;

    /**
    * @dev Close the evidence period of a dispute
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(uint256 _disputeId) external;

    /**
    * @notice Rule dispute #`_disputeId` if ready
    * @param _disputeId Identification number of the dispute to be ruled
    * @return subject Subject associated to the dispute
    * @return ruling Ruling number computed for the given dispute
    */
    function rule(uint256 _disputeId) external returns (address subject, uint256 ruling);

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell the payments recipient address
    * @return Address of the payments recipient module
    */
    function getPaymentsRecipient() external view returns (address);
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-token/contracts/GovernMinter.sol";
import "@aragon/govern-token/contracts/GovernToken.sol";

import "@aragon/govern-token/contracts/libraries/TokenLib.sol";

contract GovernTokenFactoryMock {
   
    event NewTokenCalledWith(address initialMinter, string _tokenName, string _tokenSymbol, uint8 tokenDecimals, address mintAddr, uint256 mintAmount, bool useProxies);
  
    function newToken(
        address _initialMinter,
        TokenLib.TokenConfig calldata _token,
        bool _useProxies
    ) external returns (
        GovernToken token,
        GovernMinter minter
    ) {
        emit NewTokenCalledWith(
            _initialMinter, 
            _token.tokenName, 
            _token.tokenSymbol, 
            _token.tokenDecimals, 
            _token.mintAddress, 
            _token.mintAmount, 
            _useProxies
        );

        token = GovernToken(address(this));
        minter = GovernMinter(address(this));
    }

   
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-core/contracts/pipelines/GovernQueue.sol";
import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";

contract GovernQueueFactoryMock  {
   
    event NewQueueCalledWith(address aclRoot, bytes32 salt);
    event BulkCalled(ACLData.BulkItem[] items);
    
    bytes4 public constant ROOT_ROLE = "0x";

    function schedule()  public pure  {}
    function execute()   public pure  {}
    function challenge() public pure  {}
    
    function configure(ERC3000Data.Config memory /*_config*/) public pure returns(bool)  {
        // TODO: emit events and catch it in the govern-base-factory-unit.test.ts
        return true;
    }

    // probably ACL inheritance can be used instead of implementing ACL functions again.

    function grant(bytes4 _role, address _who) public pure {
        // TODO: emit events and catch it in the govern-base-factory-unit.test.ts
    }

    function revoke(bytes4 _role, address _who) public pure {
        // TODO: emit events and catch it in the govern-base-factory-unit.test.ts
    }

    function bulk(ACLData.BulkItem[] memory items) public {
        emit BulkCalled(items);
    }

    function newQueue(address _aclRoot, ERC3000Data.Config memory /*_config*/, bytes32 _salt) public returns (GovernQueue queue) {
        /* 
            TODO:There seems to be a bug with waffle. After it's been fixed, emit the _config too and in the test,
            assert it. https://github.com/EthWorks/Waffle/issues/454
        */
        emit NewQueueCalledWith(_aclRoot, _salt);
        return GovernQueue(address(this));
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;

import "erc3k/contracts/IERC3000.sol";
import "@aragon/govern-core/contracts/Govern.sol";
import "@aragon/govern-contract-utils/contracts/address-utils/AddressUtils.sol";

contract GovernFactoryMock {

    using AddressUtils for address;

    event NewGovernCalledWith(IERC3000 executor, bytes32 salt);

    function newGovern(IERC3000 _initialExecutor, bytes32 _salt) public returns (Govern govern) {
        emit NewGovernCalledWith(_initialExecutor, _salt);
        return Govern(address(this).toPayable());
    }

}

