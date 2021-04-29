/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// File @aragon/os/contracts/common/[email protected]

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


// File @aragon/os/contracts/acl/[email protected]

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


// File @aragon/os/contracts/common/[email protected]

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


// File @aragon/os/contracts/kernel/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


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


// File @aragon/os/contracts/apps/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


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


// File @aragon/os/contracts/acl/[email protected]

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


// File @aragon/os/contracts/common/[email protected]

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

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


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


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


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

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


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}


// File @aragon/os/contracts/common/[email protected]

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


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

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


// File @aragon/os/contracts/lib/token/[email protected]

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


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}


// File @aragon/os/contracts/common/[email protected]

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


// File @aragon/os/contracts/common/[email protected]

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;

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


// File @aragon/os/contracts/common/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;





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


// File @aragon/os/contracts/evmscript/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}


// File @aragon/os/contracts/evmscript/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

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


// File @aragon/os/contracts/kernel/[email protected]

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


// File @aragon/os/contracts/evmscript/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;




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


// File @aragon/os/contracts/apps/[email protected]

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;







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


// File @aragon/os/contracts/lib/math/[email protected]

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}


// File contracts/0.4.24/interfaces/IBeaconReportReceiver.sol

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;


/**
  * @title Interface defining a callback that the quorum will call on every quorum reached
  */
interface IBeaconReportReceiver {
    /**
      * @notice Callback to be called by the oracle contract upon the quorum is reached
      * @param _postTotalPooledEther total pooled ether on Lido right after the quorum value was reported
      * @param _preTotalPooledEther total pooled ether on Lido right before the quorum value was reported
      * @param _timeElapsed time elapsed in seconds between the last and the previous quorum
      */
    function processLidoOracleReport(uint256 _postTotalPooledEther,
                                     uint256 _preTotalPooledEther,
                                     uint256 _timeElapsed) external;
}


// File contracts/0.4.24/interfaces/ILido.sol

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;


/**
  * @title Liquid staking pool
  *
  * For the high-level description of the pool operation please refer to the paper.
  * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
  * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
  * only a small portion (buffer) of it.
  * It also mints new tokens for rewards generated at the ETH 2.0 side.
  */
interface ILido {
    /**
     * @dev From ISTETH interface, because "Interfaces cannot inherit".
     */
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    /**
      * @notice Stop pool routine operations
      */
    function stop() external;

    /**
      * @notice Resume pool routine operations
      */
    function resume() external;

    event Stopped();
    event Resumed();


    /**
      * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
      * @param _feeBasisPoints Fee rate, in basis points
      */
    function setFee(uint16 _feeBasisPoints) external;

    /**
      * @notice Set fee distribution: `_treasuryFeeBasisPoints` basis points go to the treasury, `_insuranceFeeBasisPoints` basis points go to the insurance fund, `_operatorsFeeBasisPoints` basis points go to node operators. The sum has to be 10 000.
      */
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints)
        external;

    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints);

    /**
      * @notice Returns fee distribution proportion
      */
    function getFeeDistribution() external view returns (uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints,
                                                         uint16 operatorsFeeBasisPoints);

    event FeeSet(uint16 feeBasisPoints);

    event FeeDistributionSet(uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints);


    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials hash of withdrawal multisignature key as accepted by
      *        the deposit_contract.deposit function
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes);


    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);


    /**
      * @notice Ether on the ETH 2.0 side reported by the oracle
      * @param _epoch Epoch id
      * @param _eth2balance Balance in wei on the ETH 2.0 side
      */
    function pushBeacon(uint256 _epoch, uint256 _eth2balance) external;


    // User functions

    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `_amount` of ether was sent to the deposit_contract.deposit function.
    event Unbuffered(uint256 amount);

    /**
      * @notice Issues withdrawal request. Large withdrawals will be processed only after the phase 2 launch.
      * @param _amount Amount of StETH to burn
      * @param _pubkeyHash Receiving address
      */
    function withdraw(uint256 _amount, bytes32 _pubkeyHash) external;

    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    event Withdrawal(address indexed sender, uint256 tokenAmount, uint256 sentFromBuffer,
                     bytes32 indexed pubkeyHash, uint256 etherAmount);


    // Info functions

    /**
      * @notice Gets the amount of Ether controlled by the system
      */
    function getTotalPooledEther() external view returns (uint256);

    /**
      * @notice Gets the amount of Ether temporary buffered on this contract balance
      */
    function getBufferedEther() external view returns (uint256);

    /**
      * @notice Returns the key values related to Beacon-side
      * @return depositedValidators - number of deposited validators
      * @return beaconValidators - number of Lido's validators visible in the Beacon state, reported by oracles
      * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of Lido validators)
      */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);
}


// File contracts/0.4.24/interfaces/ILidoOracle.sol

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;

/**
 * @title ETH 2.0 -> ETH oracle
 *
 * The goal of the oracle is to inform other parts of the system about balances controlled by the
 * DAO on the ETH 2.0 side. The balances can go up because of reward accumulation and can go down
 * because of slashing.
 */
interface ILidoOracle {
    event AllowedBeaconBalanceAnnualRelativeIncreaseSet(uint256 value);
    event AllowedBeaconBalanceRelativeDecreaseSet(uint256 value);
    event BeaconReportReceiverSet(address callback);
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event QuorumChanged(uint256 quorum);
    event ExpectedEpochIdUpdated(uint256 epochId);
    event BeaconSpecSet(
        uint64 epochsPerFrame,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    );
    event BeaconReported(
        uint256 epochId,
        uint128 beaconBalance,
        uint128 beaconValidators,
        address caller
    );
    event Completed(
        uint256 epochId,
        uint128 beaconBalance,
        uint128 beaconValidators
    );
    event PostTotalShares(
         uint256 postTotalPooledEther,
         uint256 preTotalPooledEther,
         uint256 timeElapsed,
         uint256 totalShares);
    event ContractVersionSet(uint256 version);

    /**
     * @notice Return the Lido contract address
     */
    function getLido() public view returns (ILido);

    /**
     * @notice Return the number of exactly the same reports needed to finalize the epoch
     */
    function getQuorum() public view returns (uint256);

    /**
     * @notice Return the upper bound of the reported balance possible increase in APR
     */
    function getAllowedBeaconBalanceAnnualRelativeIncrease() external view returns (uint256);

    /**
     * @notice Return the lower bound of the reported balance possible decrease
     */
    function getAllowedBeaconBalanceRelativeDecrease() external view returns (uint256);

    /**
     * @notice Set the upper bound of the reported balance possible increase in APR to `_value`
     */
    function setAllowedBeaconBalanceAnnualRelativeIncrease(uint256 _value) external;

    /**
     * @notice Set the lower bound of the reported balance possible decrease to `_value`
     */
    function setAllowedBeaconBalanceRelativeDecrease(uint256 _value) external;

    /**
     * @notice Return the receiver contract address to be called when the report is pushed to Lido
     */
    function getBeaconReportReceiver() external view returns (address);

    /**
     * @notice Set the receiver contract address to be called when the report is pushed to Lido
     */
    function setBeaconReportReceiver(address _addr) external;

    /**
     * @notice Return the current reporting bitmap, representing oracles who have already pushed
     * their version of report during the expected epoch
     */
    function getCurrentOraclesReportStatus() external view returns (uint256);

    /**
     * @notice Return the current reporting array size
     */
    function getCurrentReportVariantsSize() external view returns (uint256);

    /**
     * @notice Return the current reporting array element with the given index
     */
    function getCurrentReportVariant(uint256 _index)
        external
        view
        returns (
            uint64 beaconBalance,
            uint32 beaconValidators,
            uint16 count
        );

    /**
     * @notice Return epoch that can be reported by oracles
     */
    function getExpectedEpochId() external view returns (uint256);

    /**
     * @notice Return the current oracle member committee list
     */
    function getOracleMembers() external view returns (address[]);

    /**
     * @notice Return the initialized version of this contract starting from 0
     */
    function getVersion() external view returns (uint256);

    /**
     * @notice Return beacon specification data
     */
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        );

    /**
     * Updates beacon specification data
     */
    function setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    )
        external;

    /**
     * Returns the epoch calculated from current timestamp
     */
    function getCurrentEpochId() external view returns (uint256);

    /**
     * @notice Return currently reportable epoch (the first epoch of the current frame) as well as
     * its start and end times in seconds
     */
    function getCurrentFrame()
        external
        view
        returns (
            uint256 frameEpochId,
            uint256 frameStartTime,
            uint256 frameEndTime
        );

    /**
     * @notice Return last completed epoch
     */
    function getLastCompletedEpochId() external view returns (uint256);

    /**
     * @notice Report beacon balance and its change during the last frame
     */
    function getLastCompletedReportDelta()
        external
        view
        returns (
            uint256 postTotalPooledEther,
            uint256 preTotalPooledEther,
            uint256 timeElapsed
        );

    /**
     * @notice Initialize the contract v2 data, with sanity check bounds
     * (`_allowedBeaconBalanceAnnualRelativeIncrease`, `_allowedBeaconBalanceRelativeDecrease`)
     * @dev Original initialize function removed from v2 because it is invoked only once
     */
    function initialize_v2(
        uint256 _allowedBeaconBalanceAnnualRelativeIncrease,
        uint256 _allowedBeaconBalanceRelativeDecrease
    )
        external;

    /**
     * @notice Add `_member` to the oracle member committee list
     */
    function addOracleMember(address _member) external;

    /**
     * @notice Remove '_member` from the oracle member committee list
     */
    function removeOracleMember(address _member) external;

    /**
     * @notice Set the number of exactly the same reports needed to finalize the epoch to `_quorum`
     */
    function setQuorum(uint256 _quorum) external;

    /**
     * @notice Accept oracle committee member reports from the ETH 2.0 side
     * @param _epochId Beacon chain epoch
     * @param _beaconBalance Balance in gwei on the ETH 2.0 side (9-digit denomination)
     * @param _beaconValidators Number of validators visible in this epoch
     */
    function reportBeacon(uint256 _epochId, uint64 _beaconBalance, uint32 _beaconValidators) external;
}


// File contracts/0.4.24/oracle/ReportUtils.sol

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;

/**
 * Utility functions for effectively storing reports within a single storage slot
 *
 * +00 | uint16 | count            | 0..256  | number of reports received exactly like this
 * +16 | uint32 | beaconValidators | 0..1e9  | number of Lido's validators in beacon chain
 * +48 | uint64 | beaconBalance    | 0..1e18 | total amout of their balance
 *
 * Note that the 'count' is the leftmost field here. Thus it is possible to apply addition
 * operations to it when it is encoded, provided that you watch for the overflow.
 */
library ReportUtils {
    uint256 constant internal COUNT_OUTMASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000;

    function encode(uint64 beaconBalance, uint32 beaconValidators) internal pure returns (uint256) {
        return uint256(beaconBalance) << 48 | uint256(beaconValidators) << 16;
    }

    function decode(uint256 value) internal pure returns (uint64 beaconBalance, uint32 beaconValidators) {
        beaconBalance = uint64(value >> 48);
        beaconValidators = uint32(value >> 16);
    }

    function decodeWithCount(uint256 value)
        internal pure
        returns (
            uint64 beaconBalance,
            uint32 beaconValidators,
            uint16 count
        ) {
        beaconBalance = uint64(value >> 48);
        beaconValidators = uint32(value >> 16);
        count = uint16(value);
    }

    /// @notice Check if the given reports are different, not considering the counter of the first
    function isDifferent(uint256 value, uint256 that) internal pure returns(bool) {
        return (value & COUNT_OUTMASK) != that;
    }

    function getCount(uint256 value) internal pure returns(uint16) {
        return uint16(value);
    }
}


// File contracts/0.4.24/oracle/LidoOracle.sol

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
pragma solidity 0.4.24;




/**
 * @title Implementation of an ETH 2.0 -> ETH oracle
 *
 * The goal of the oracle is to inform other parts of the system about balances controlled by the
 * DAO on the ETH 2.0 side. The balances can go up because of reward accumulation and can go down
 * because of slashing.
 *
 * The timeline is divided into consecutive frames. Every oracle member may push its report once
 * per frame. When the equal reports reach the configurable 'quorum' value, this frame is
 * considered finalized and the resulting report is pushed to Lido.
 *
 * Not all frames may come to a quorum. Oracles may report only to the first epoch of the frame and
 * only if no quorum is reached for this epoch yet.
 */
contract LidoOracle is ILidoOracle, AragonApp {
    using SafeMath for uint256;
    using ReportUtils for uint256;

    struct BeaconSpec {
        uint64 epochsPerFrame;
        uint64 slotsPerEpoch;
        uint64 secondsPerSlot;
        uint64 genesisTime;
    }

    /// ACL
    bytes32 constant public MANAGE_MEMBERS =
        0xbf6336045918ae0015f4cdb3441a2fdbfaa4bcde6558c8692aac7f56c69fb067; // keccak256("MANAGE_MEMBERS")
    bytes32 constant public MANAGE_QUORUM =
        0xa5ffa9f45fa52c446078e834e1914561bd9c2ab1e833572d62af775da092ccbc; // keccak256("MANAGE_QUORUM")
    bytes32 constant public SET_BEACON_SPEC =
        0x16a273d48baf8111397316e6d961e6836913acb23b181e6c5fb35ec0bd2648fc; // keccak256("SET_BEACON_SPEC")
    bytes32 constant public SET_REPORT_BOUNDARIES =
        0x44adaee26c92733e57241cb0b26ffaa2d182ed7120ba3ecd7e0dce3635c01dc1; // keccak256("SET_REPORT_BOUNDARIES")
    bytes32 constant public SET_BEACON_REPORT_RECEIVER =
        0xe22a455f1bfbaf705ac3e891a64e156da92cb0b42cfc389158e6e82bd57f37be; // keccak256("SET_BEACON_REPORT_RECEIVER")

    /// Maximum number of oracle committee members
    uint256 public constant MAX_MEMBERS = 256;

    /// Eth1 denomination is 18 digits, while Eth2 has 9 digits. Because we work with Eth2
    /// balances and to support old interfaces expecting eth1 format, we multiply by this
    /// coefficient.
    uint128 internal constant DENOMINATION_OFFSET = 1e9;

    uint256 internal constant MEMBER_NOT_FOUND = uint256(-1);

    /// Number of exactly the same reports needed to finalize the epoch
    bytes32 internal constant QUORUM_POSITION =
        0xd43b42c1ba05a1ab3c178623a49b2cdb55f000ec70b9ccdba5740b3339a7589e; // keccak256("lido.LidoOracle.quorum")

    /// Address of the Lido contract
    bytes32 internal constant LIDO_POSITION =
        0xf6978a4f7e200f6d3a24d82d44c48bddabce399a3b8ec42a480ea8a2d5fe6ec5; // keccak256("lido.LidoOracle.lido")

    /// Storage for the actual beacon chain specification
    bytes32 internal constant BEACON_SPEC_POSITION =
        0x805e82d53a51be3dfde7cfed901f1f96f5dad18e874708b082adb8841e8ca909; // keccak256("lido.LidoOracle.beaconSpec")

    /// Version of the initialized contract data, v1 is 0
    bytes32 internal constant CONTRACT_VERSION_POSITION =
        0x75be19a3f314d89bd1f84d30a6c84e2f1cd7afc7b6ca21876564c265113bb7e4; // keccak256("lido.LidoOracle.contractVersion")

    /// Epoch that we currently collect reports
    bytes32 internal constant EXPECTED_EPOCH_ID_POSITION =
        0x65f1a0ee358a8a4000a59c2815dc768eb87d24146ca1ac5555cb6eb871aee915; // keccak256("lido.LidoOracle.expectedEpochId")

    /// The bitmask of the oracle members that pushed their reports
    bytes32 internal constant REPORTS_BITMASK_POSITION =
        0xea6fa022365e4737a3bb52facb00ddc693a656fb51ffb2b4bd24fb85bdc888be; // keccak256("lido.LidoOracle.reportsBitMask")

    /// Historic data about 2 last completed reports and their times
    bytes32 internal constant POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION =
        0xaa8433b13d2b111d4f84f6f374bc7acbe20794944308876aa250fa9a73dc7f53; // keccak256("lido.LidoOracle.postCompletedTotalPooledEther")
    bytes32 internal constant PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION =
        0x1043177539af09a67d747435df3ff1155a64cd93a347daaac9132a591442d43e; // keccak256("lido.LidoOracle.preCompletedTotalPooledEther")
    bytes32 internal constant LAST_COMPLETED_EPOCH_ID_POSITION =
        0xdad15c0beecd15610092d84427258e369d2582df22869138b4c5265f049f574c; // keccak256("lido.LidoOracle.lastCompletedEpochId")
    bytes32 internal constant TIME_ELAPSED_POSITION =
        0x8fe323f4ecd3bf0497252a90142003855cc5125cee76a5b5ba5d508c7ec28c3a; // keccak256("lido.LidoOracle.timeElapsed")

    /// Receiver address to be called when the report is pushed to Lido
    bytes32 internal constant BEACON_REPORT_RECEIVER_POSITION =
        0xb59039ed37776bc23c5d272e10b525a957a1dfad97f5006c84394b6b512c1564; // keccak256("lido.LidoOracle.beaconReportReceiver")

    /// Upper bound of the reported balance possible increase in APR, controlled by the governance
    bytes32 internal constant ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION =
        0x613075ab597bed8ce2e18342385ce127d3e5298bc7a84e3db68dc64abd4811ac; // keccak256("lido.LidoOracle.allowedBeaconBalanceAnnualRelativeIncrease")

    /// Lower bound of the reported balance possible decrease, controlled by the governance
    ///
    /// @notice When slashing happens, the balance may decrease at a much faster pace. Slashing are
    /// one-time events that decrease the balance a fair amount - a few percent at a time in a
    /// realistic scenario. Thus, instead of sanity check for an APR, we check if the plain relative
    /// decrease is within bounds.  Note that it's not annual value, its just one-jump value.
    bytes32 internal constant ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION =
        0x92ba7776ed6c5d13cf023555a94e70b823a4aebd56ed522a77345ff5cd8a9109; // keccak256("lido.LidoOracle.allowedBeaconBalanceDecrease")

    /// This variable is from v1: the last reported epoch, used only in the initializer
    bytes32 internal constant V1_LAST_REPORTED_EPOCH_ID_POSITION =
        0xfe0250ed0c5d8af6526c6d133fccb8e5a55dd6b1aa6696ed0c327f8e517b5a94; // keccak256("lido.LidoOracle.lastReportedEpochId")

    /// Contract structured storage
    address[] private members;                /// slot 0: oracle committee members
    uint256[] private currentReportVariants;  /// slot 1: reporting storage


    /**
     * @notice Return the Lido contract address
     */
    function getLido() public view returns (ILido) {
        return ILido(LIDO_POSITION.getStorageAddress());
    }

    /**
     * @notice Return the number of exactly the same reports needed to finalize the epoch
     */
    function getQuorum() public view returns (uint256) {
        return QUORUM_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the upper bound of the reported balance possible increase in APR
     */
    function getAllowedBeaconBalanceAnnualRelativeIncrease() external view returns (uint256) {
        return ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the lower bound of the reported balance possible decrease
     */
    function getAllowedBeaconBalanceRelativeDecrease() external view returns (uint256) {
        return ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.getStorageUint256();
    }

    /**
     * @notice Set the upper bound of the reported balance possible increase in APR to `_value`
     */
    function setAllowedBeaconBalanceAnnualRelativeIncrease(uint256 _value) external auth(SET_REPORT_BOUNDARIES) {
        ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION.setStorageUint256(_value);
        emit AllowedBeaconBalanceAnnualRelativeIncreaseSet(_value);
    }

    /**
     * @notice Set the lower bound of the reported balance possible decrease to `_value`
     */
    function setAllowedBeaconBalanceRelativeDecrease(uint256 _value) external auth(SET_REPORT_BOUNDARIES) {
        ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.setStorageUint256(_value);
        emit AllowedBeaconBalanceRelativeDecreaseSet(_value);
    }

    /**
     * @notice Return the receiver contract address to be called when the report is pushed to Lido
     */
    function getBeaconReportReceiver() external view returns (address) {
        return address(BEACON_REPORT_RECEIVER_POSITION.getStorageUint256());
    }

    /**
     * @notice Set the receiver contract address to `_addr` to be called when the report is pushed
     * @dev Specify 0 to disable this functionality
     */
    function setBeaconReportReceiver(address _addr) external auth(SET_BEACON_REPORT_RECEIVER) {
        BEACON_REPORT_RECEIVER_POSITION.setStorageUint256(uint256(_addr));
        emit BeaconReportReceiverSet(_addr);
    }

    /**
     * @notice Return the current reporting bitmap, representing oracles who have already pushed
     * their version of report during the expected epoch
     * @dev Every oracle bit corresponds to the index of the oracle in the current members list
     */
    function getCurrentOraclesReportStatus() external view returns (uint256) {
        return REPORTS_BITMASK_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the current reporting variants array size
     */
    function getCurrentReportVariantsSize() external view returns (uint256) {
        return currentReportVariants.length;
    }

    /**
     * @notice Return the current reporting array element with index `_index`
     */
    function getCurrentReportVariant(uint256 _index)
        external
        view
        returns (
            uint64 beaconBalance,
            uint32 beaconValidators,
            uint16 count
        )
    {
        return currentReportVariants[_index].decodeWithCount();
    }

    /**
     * @notice Returns epoch that can be reported by oracles
     */
    function getExpectedEpochId() external view returns (uint256) {
        return EXPECTED_EPOCH_ID_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the current oracle member committee list
     */
    function getOracleMembers() external view returns (address[]) {
        return members;
    }

    /**
     * @notice Return the initialized version of this contract starting from 0
     */
    function getVersion() external view returns (uint256) {
        return CONTRACT_VERSION_POSITION.getStorageUint256();
    }

    /**
     * @notice Return beacon specification data
     */
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        )
    {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        return (
            beaconSpec.epochsPerFrame,
            beaconSpec.slotsPerEpoch,
            beaconSpec.secondsPerSlot,
            beaconSpec.genesisTime
        );
    }

    /**
     * @notice Update beacon specification data
     */
    function setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    )
        external
        auth(SET_BEACON_SPEC)
    {
        _setBeaconSpec(
            _epochsPerFrame,
            _slotsPerEpoch,
            _secondsPerSlot,
            _genesisTime
        );
    }

    /**
     * @notice Return the epoch calculated from current timestamp
     */
    function getCurrentEpochId() external view returns (uint256) {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        return _getCurrentEpochId(beaconSpec);
    }

    /**
     * @notice Return currently reportable epoch (the first epoch of the current frame) as well as
     * its start and end times in seconds
     */
    function getCurrentFrame()
        external
        view
        returns (
            uint256 frameEpochId,
            uint256 frameStartTime,
            uint256 frameEndTime
        )
    {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint64 genesisTime = beaconSpec.genesisTime;
        uint64 secondsPerEpoch = beaconSpec.secondsPerSlot * beaconSpec.slotsPerEpoch;

        frameEpochId = _getFrameFirstEpochId(_getCurrentEpochId(beaconSpec), beaconSpec);
        frameStartTime = frameEpochId * secondsPerEpoch + genesisTime;
        frameEndTime = (frameEpochId + beaconSpec.epochsPerFrame) * secondsPerEpoch + genesisTime - 1;
    }

    /**
     * @notice Return last completed epoch
     */
    function getLastCompletedEpochId() external view returns (uint256) {
        return LAST_COMPLETED_EPOCH_ID_POSITION.getStorageUint256();
    }

    /**
     * @notice Report beacon balance and its change during the last frame
     */
    function getLastCompletedReportDelta()
        external
        view
        returns (
            uint256 postTotalPooledEther,
            uint256 preTotalPooledEther,
            uint256 timeElapsed
        )
    {
        postTotalPooledEther = POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION.getStorageUint256();
        preTotalPooledEther = PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION.getStorageUint256();
        timeElapsed = TIME_ELAPSED_POSITION.getStorageUint256();
    }

    /**
     * @notice Initialize the contract v2 data, with sanity check bounds
     * (`_allowedBeaconBalanceAnnualRelativeIncrease`, `_allowedBeaconBalanceRelativeDecrease`)
     * @dev Original initialize function removed from v2 because it is invoked only once
     */
    function initialize_v2(
        uint256 _allowedBeaconBalanceAnnualRelativeIncrease,
        uint256 _allowedBeaconBalanceRelativeDecrease
    )
        external
    {
        require(CONTRACT_VERSION_POSITION.getStorageUint256() == 0, "ALREADY_INITIALIZED");
        CONTRACT_VERSION_POSITION.setStorageUint256(1);
        emit ContractVersionSet(1);

        ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION
            .setStorageUint256(_allowedBeaconBalanceAnnualRelativeIncrease);
        emit AllowedBeaconBalanceAnnualRelativeIncreaseSet(_allowedBeaconBalanceAnnualRelativeIncrease);

        ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION
            .setStorageUint256(_allowedBeaconBalanceRelativeDecrease);
        emit AllowedBeaconBalanceRelativeDecreaseSet(_allowedBeaconBalanceRelativeDecrease);

        // set last completed epoch as V1's contract last reported epoch, in the vast majority of
        // cases this is true, in others the error is within a frame
        uint256 lastReportedEpoch = V1_LAST_REPORTED_EPOCH_ID_POSITION.getStorageUint256();
        LAST_COMPLETED_EPOCH_ID_POSITION.setStorageUint256(lastReportedEpoch);

        // set expected epoch to the first epoch for the next frame
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint256 expectedEpoch = _getFrameFirstEpochId(lastReportedEpoch, beaconSpec) + beaconSpec.epochsPerFrame;
        EXPECTED_EPOCH_ID_POSITION.setStorageUint256(expectedEpoch);
        emit ExpectedEpochIdUpdated(expectedEpoch);
    }

    /**
     * @notice Add `_member` to the oracle member committee list
     */
    function addOracleMember(address _member) external auth(MANAGE_MEMBERS) {
        require(address(0) != _member, "BAD_ARGUMENT");
        require(MEMBER_NOT_FOUND == _getMemberId(_member), "MEMBER_EXISTS");

        members.push(_member);
        require(members.length < MAX_MEMBERS, "TOO_MANY_MEMBERS");
        emit MemberAdded(_member);
    }

    /**
     * @notice Remove '_member` from the oracle member committee list
     */
    function removeOracleMember(address _member) external auth(MANAGE_MEMBERS) {
        uint256 index = _getMemberId(_member);
        require(index != MEMBER_NOT_FOUND, "MEMBER_NOT_FOUND");
        uint256 last = members.length - 1;
        if (index != last) members[index] = members[last];
        members.length--;
        emit MemberRemoved(_member);

        // delete the data for the last epoch, let remained oracles report it again
        REPORTS_BITMASK_POSITION.setStorageUint256(0);
        delete currentReportVariants;
    }

    /**
     * @notice Set the number of exactly the same reports needed to finalize the epoch to `_quorum`
     */
    function setQuorum(uint256 _quorum) external auth(MANAGE_QUORUM) {
        require(0 != _quorum, "QUORUM_WONT_BE_MADE");
        uint256 oldQuorum = QUORUM_POSITION.getStorageUint256();
        QUORUM_POSITION.setStorageUint256(_quorum);
        emit QuorumChanged(_quorum);

        // If the quorum value lowered, check existing reports whether it is time to push
        if (oldQuorum > _quorum) {
            (bool isQuorum, uint256 report) = _getQuorumReport(_quorum);
            if (isQuorum) {
                (uint64 beaconBalance, uint32 beaconValidators) = report.decode();
                _push(
                     EXPECTED_EPOCH_ID_POSITION.getStorageUint256(),
                     DENOMINATION_OFFSET * uint128(beaconBalance),
                     beaconValidators,
                     _getBeaconSpec()
                );
            }
        }
    }

    /**
     * @notice Accept oracle committee member reports from the ETH 2.0 side
     * @param _epochId Beacon chain epoch
     * @param _beaconBalance Balance in gwei on the ETH 2.0 side (9-digit denomination)
     * @param _beaconValidators Number of validators visible in this epoch
     */
    function reportBeacon(uint256 _epochId, uint64 _beaconBalance, uint32 _beaconValidators) external {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint256 expectedEpoch = EXPECTED_EPOCH_ID_POSITION.getStorageUint256();
        require(_epochId >= expectedEpoch, "EPOCH_IS_TOO_OLD");

        // if expected epoch has advanced, check that this is the first epoch of the current frame
        // and clear the last unsuccessful reporting
        if (_epochId > expectedEpoch) {
            require(_epochId == _getFrameFirstEpochId(_getCurrentEpochId(beaconSpec), beaconSpec), "UNEXPECTED_EPOCH");
            _clearReportingAndAdvanceTo(_epochId);
        }

        uint128 beaconBalanceEth1 = DENOMINATION_OFFSET * uint128(_beaconBalance);
        emit BeaconReported(_epochId, beaconBalanceEth1, _beaconValidators, msg.sender);

        // make sure the oracle is from members list and has not yet voted
        uint256 index = _getMemberId(msg.sender);
        require(index != MEMBER_NOT_FOUND, "MEMBER_NOT_FOUND");
        uint256 bitMask = REPORTS_BITMASK_POSITION.getStorageUint256();
        uint256 mask = 1 << index;
        require(bitMask & mask == 0, "ALREADY_SUBMITTED");
        REPORTS_BITMASK_POSITION.setStorageUint256(bitMask | mask);

        // push this report to the matching kind
        uint256 report = ReportUtils.encode(_beaconBalance, _beaconValidators);
        uint256 quorum = getQuorum();
        uint256 i = 0;

        // iterate on all report variants we already have, limited by the oracle members maximum
        while (i < currentReportVariants.length && currentReportVariants[i].isDifferent(report)) ++i;
        if (i < currentReportVariants.length) {
            if (currentReportVariants[i].getCount() + 1 >= quorum) {
                _push(_epochId, beaconBalanceEth1, _beaconValidators, beaconSpec);
            } else {
                ++currentReportVariants[i]; // increment report counter, see ReportUtils for details
            }
        } else {
            if (quorum == 1) {
                _push(_epochId, beaconBalanceEth1, _beaconValidators, beaconSpec);
            } else {
                currentReportVariants.push(report + 1);
            }
        }
    }

    /**
     * @notice Return beacon specification data
     */
    function _getBeaconSpec()
        internal
        view
        returns (BeaconSpec memory beaconSpec)
    {
        uint256 data = BEACON_SPEC_POSITION.getStorageUint256();
        beaconSpec.epochsPerFrame = uint64(data >> 192);
        beaconSpec.slotsPerEpoch = uint64(data >> 128);
        beaconSpec.secondsPerSlot = uint64(data >> 64);
        beaconSpec.genesisTime = uint64(data);
        return beaconSpec;
    }

    /**
     * @notice Return whether the `_quorum` is reached and the final report
     */
    function _getQuorumReport(uint256 _quorum) internal view returns (bool isQuorum, uint256 report) {
        // check most frequent cases first: all reports are the same or no reports yet
        if (currentReportVariants.length == 1) {
            return (currentReportVariants[0].getCount() >= _quorum, currentReportVariants[0]);
        } else if (currentReportVariants.length == 0) {
            return (false, 0);
        }

        // if more than 2 kind of reports exist, choose the most frequent
        uint256 maxind = 0;
        uint256 repeat = 0;
        uint16 maxval = 0;
        uint16 cur = 0;
        for (uint256 i = 0; i < currentReportVariants.length; ++i) {
            cur = currentReportVariants[i].getCount();
            if (cur >= maxval) {
                if (cur == maxval) {
                    ++repeat;
                } else {
                    maxind = i;
                    maxval = cur;
                    repeat = 0;
                }
            }
        }
        return (maxval >= _quorum && repeat == 0, currentReportVariants[maxind]);
    }

    /**
     * @notice Set beacon specification data
     */
    function _setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    )
        internal
    {
        require(_epochsPerFrame > 0, "BAD_EPOCHS_PER_FRAME");
        require(_slotsPerEpoch > 0, "BAD_SLOTS_PER_EPOCH");
        require(_secondsPerSlot > 0, "BAD_SECONDS_PER_SLOT");
        require(_genesisTime > 0, "BAD_GENESIS_TIME");

        uint256 data = (
            uint256(_epochsPerFrame) << 192 |
            uint256(_slotsPerEpoch) << 128 |
            uint256(_secondsPerSlot) << 64 |
            uint256(_genesisTime)
        );
        BEACON_SPEC_POSITION.setStorageUint256(data);
        emit BeaconSpecSet(
            _epochsPerFrame,
            _slotsPerEpoch,
            _secondsPerSlot,
            _genesisTime);
    }

    /**
     * @notice Push the given report to Lido and performs accompanying accounting
     * @param _epochId Beacon chain epoch, proven to be >= expected epoch and <= current epoch
     * @param _beaconBalanceEth1 Validators balance in eth1 (18-digit denomination)
     * @param _beaconSpec current beacon specification data
     */
    function _push(
        uint256 _epochId,
        uint128 _beaconBalanceEth1,
        uint128 _beaconValidators,
        BeaconSpec memory _beaconSpec
    )
        internal
    {
        emit Completed(_epochId, _beaconBalanceEth1, _beaconValidators);

        // now this frame is completed, so the expected epoch should be advanced to the first epoch
        // of the next frame
        _clearReportingAndAdvanceTo(_epochId + _beaconSpec.epochsPerFrame);

        // report to the Lido and collect stats
        ILido lido = getLido();
        uint256 prevTotalPooledEther = lido.totalSupply();
        lido.pushBeacon(_beaconValidators, _beaconBalanceEth1);
        uint256 postTotalPooledEther = lido.totalSupply();

        PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION.setStorageUint256(prevTotalPooledEther);
        POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION.setStorageUint256(postTotalPooledEther);
        uint256 timeElapsed = (_epochId - LAST_COMPLETED_EPOCH_ID_POSITION.getStorageUint256()) *
            _beaconSpec.slotsPerEpoch * _beaconSpec.secondsPerSlot;
        TIME_ELAPSED_POSITION.setStorageUint256(timeElapsed);
        LAST_COMPLETED_EPOCH_ID_POSITION.setStorageUint256(_epochId);

        // rollback on boundaries violation
        _reportSanityChecks(postTotalPooledEther, prevTotalPooledEther, timeElapsed);

        // emit detailed statistics and call the quorum delegate with this data
        emit PostTotalShares(postTotalPooledEther, prevTotalPooledEther, timeElapsed, lido.getTotalShares());
        IBeaconReportReceiver receiver = IBeaconReportReceiver(BEACON_REPORT_RECEIVER_POSITION.getStorageUint256());
        if (address(receiver) != address(0)) {
            receiver.processLidoOracleReport(postTotalPooledEther, prevTotalPooledEther, timeElapsed);
        }
    }

    /**
     * @notice Remove the current reporting progress and advances to accept the later epoch `_epochId`
     */
    function _clearReportingAndAdvanceTo(uint256 _epochId) internal {
        REPORTS_BITMASK_POSITION.setStorageUint256(0);
        EXPECTED_EPOCH_ID_POSITION.setStorageUint256(_epochId);
        delete currentReportVariants;
        emit ExpectedEpochIdUpdated(_epochId);
    }

    /**
     * @notice Performs logical consistency check of the Lido changes as the result of reports push
     * @dev To make oracles less dangerous, we limit rewards report by 10% _annual_ increase and 5%
     * _instant_ decrease in stake, with both values configurable by the governance in case of
     * extremely unusual circumstances.
     **/
    function _reportSanityChecks(
        uint256 _postTotalPooledEther,
        uint256 _preTotalPooledEther,
        uint256 _timeElapsed)
        internal
        view
    {
        if (_postTotalPooledEther >= _preTotalPooledEther) {
            // increase                 = _postTotalPooledEther - _preTotalPooledEther,
            // relativeIncrease         = increase / _preTotalPooledEther,
            // annualRelativeIncrease   = relativeIncrease / (timeElapsed / 365 days),
            // annualRelativeIncreaseBp = annualRelativeIncrease * 10000, in basis points 0.01% (1e-4)
            uint256 allowedAnnualRelativeIncreaseBp =
                ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION.getStorageUint256();
            // check that annualRelativeIncreaseBp <= allowedAnnualRelativeIncreaseBp
            require(uint256(10000 * 365 days).mul(_postTotalPooledEther - _preTotalPooledEther) <=
                    allowedAnnualRelativeIncreaseBp.mul(_preTotalPooledEther).mul(_timeElapsed),
                    "ALLOWED_BEACON_BALANCE_INCREASE");
        } else {
            // decrease           = _preTotalPooledEther - _postTotalPooledEther
            // relativeDecrease   = decrease / _preTotalPooledEther
            // relativeDecreaseBp = relativeDecrease * 10000, in basis points 0.01% (1e-4)
            uint256 allowedRelativeDecreaseBp =
                ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.getStorageUint256();
            // check that relativeDecreaseBp <= allowedRelativeDecreaseBp
            require(uint256(10000).mul(_preTotalPooledEther - _postTotalPooledEther) <=
                    allowedRelativeDecreaseBp.mul(_preTotalPooledEther),
                    "ALLOWED_BEACON_BALANCE_DECREASE");
        }
    }

    /**
     * @notice Return `_member` index in the members list or MEMBER_NOT_FOUND
     */
    function _getMemberId(address _member) internal view returns (uint256) {
        uint256 length = members.length;
        for (uint256 i = 0; i < length; ++i) {
            if (members[i] == _member) {
                return i;
            }
        }
        return MEMBER_NOT_FOUND;
    }

    /**
     * @notice Return the epoch calculated from current timestamp
     */
    function _getCurrentEpochId(BeaconSpec memory _beaconSpec) internal view returns (uint256) {
        return (_getTime() - _beaconSpec.genesisTime) / (_beaconSpec.slotsPerEpoch * _beaconSpec.secondsPerSlot);
    }

    /**
     * @notice Return the first epoch of the frame that `_epochId` belongs to
     */
    function _getFrameFirstEpochId(uint256 _epochId, BeaconSpec memory _beaconSpec) internal view returns (uint256) {
        return _epochId / _beaconSpec.epochsPerFrame * _beaconSpec.epochsPerFrame;
    }

    /**
     * @notice Return the current timestamp
     */
    function _getTime() internal view returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }
}