// File: @aragon/os/contracts/acl/IACLOracle.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IACLOracle {
    function canPerform(address who, address where, bytes32 what, uint256[] how) external view returns (bool);
}

// File: @aragon/os/contracts/acl/IACL.sol

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

// File: @aragon/os/contracts/common/IVaultRecoverable.sol

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

// File: @aragon/os/contracts/kernel/IKernel.sol

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

// File: @aragon/os/contracts/apps/IAragonApp.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract IAragonApp {
    // Includes appId and kernel methods:
    bytes4 internal constant ARAGON_APP_INTERFACE_ID = bytes4(0x54053e6c);

    function kernel() public view returns (IKernel);
    function appId() public view returns (bytes32);
}

// File: @aragon/os/contracts/common/UnstructuredStorage.sol

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

// File: @aragon/os/contracts/apps/AppStorage.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;





contract AppStorage is IAragonApp {
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

// File: @aragon/os/contracts/acl/ACLSyntaxSugar.sol

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

// File: @aragon/os/contracts/common/Uint256Helpers.sol

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: @aragon/os/contracts/common/TimeHelpers.sol

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

// File: @aragon/os/contracts/common/Initializable.sol

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

// File: @aragon/os/contracts/common/Petrifiable.sol

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

// File: @aragon/os/contracts/common/Autopetrified.sol

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

// File: @aragon/os/contracts/common/ConversionHelpers.sol

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

// File: @aragon/os/contracts/common/ReentrancyGuard.sol

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

// File: @aragon/os/contracts/lib/token/ERC20.sol

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

// File: @aragon/os/contracts/common/EtherTokenConstant.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

// File: @aragon/os/contracts/common/IsContract.sol

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

// File: @aragon/os/contracts/common/SafeERC20.sol

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

// File: @aragon/os/contracts/common/VaultRecoverable.sol

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

// File: @aragon/os/contracts/evmscript/IEVMScriptExecutor.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

// File: @aragon/os/contracts/evmscript/IEVMScriptRegistry.sol

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

// File: @aragon/os/contracts/kernel/KernelConstants.sol

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

// File: @aragon/os/contracts/evmscript/EVMScriptRunner.sol

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

// File: @aragon/os/contracts/lib/standards/ERC165.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}

// File: @aragon/os/contracts/apps/AragonApp.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;










// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is ERC165, AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
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

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == ARAGON_APP_INTERFACE_ID;
    }
}

// File: @aragon/os/contracts/apps/disputable/IAgreement.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract IAgreement {

    event ActionSubmitted(uint256 indexed actionId, address indexed disputable);
    event ActionClosed(uint256 indexed actionId);
    event ActionChallenged(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionSettled(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionDisputed(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionAccepted(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionVoided(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionRejected(uint256 indexed actionId, uint256 indexed challengeId);

    enum ChallengeState {
        Waiting,
        Settled,
        Disputed,
        Rejected,
        Accepted,
        Voided
    }

    function newAction(uint256 _disputableActionId, bytes _context, address _submitter) external returns (uint256);

    function closeAction(uint256 _actionId) external;

    function challengeAction(uint256 _actionId, uint256 _settlementOffer, bool _finishedSubmittingEvidence, bytes _context) external;

    function settleAction(uint256 _actionId) external;

    function disputeAction(uint256 _actionId, bool _finishedSubmittingEvidence) external;
}

// File: @aragon/os/contracts/apps/disputable/IDisputable.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;





contract IDisputable is ERC165 {
    // Includes setAgreement, onDisputableActionChallenged, onDisputableActionAllowed,
    // onDisputableActionRejected, onDisputableActionVoided, getAgreement, canChallenge, and canClose methods:
    bytes4 internal constant DISPUTABLE_INTERFACE_ID = bytes4(0xf3d3bb51);

    event AgreementSet(IAgreement indexed agreement);

    function setAgreement(IAgreement _agreement) external;

    function onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) external;

    function onDisputableActionAllowed(uint256 _disputableActionId) external;

    function onDisputableActionRejected(uint256 _disputableActionId) external;

    function onDisputableActionVoided(uint256 _disputableActionId) external;

    function getAgreement() external view returns (IAgreement);

    function canChallenge(uint256 _disputableActionId) external view returns (bool);

    function canClose(uint256 _disputableActionId) external view returns (bool);
}

// File: @aragon/os/contracts/lib/math/SafeMath64.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted for uint64, pragma ^0.4.24, and satisfying our linter rules
// Also optimized the mul() implementation, see https://github.com/aragon/aragonOS/pull/417

pragma solidity ^0.4.24;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/os/contracts/apps/disputable/DisputableAragonApp.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;







contract DisputableAragonApp is IDisputable, AragonApp {
    /* Validation errors */
    string internal constant ERROR_SENDER_NOT_AGREEMENT = "DISPUTABLE_SENDER_NOT_AGREEMENT";
    string internal constant ERROR_AGREEMENT_STATE_INVALID = "DISPUTABLE_AGREEMENT_STATE_INVAL";

    // This role is used to protect who can challenge actions in derived Disputable apps. However, it is not required
    // to be validated in the app itself as the connected Agreement is responsible for performing the check on a challenge.
    // bytes32 public constant CHALLENGE_ROLE = keccak256("CHALLENGE_ROLE");
    bytes32 public constant CHALLENGE_ROLE = 0xef025787d7cd1a96d9014b8dc7b44899b8c1350859fb9e1e05f5a546dd65158d;

    // bytes32 public constant SET_AGREEMENT_ROLE = keccak256("SET_AGREEMENT_ROLE");
    bytes32 public constant SET_AGREEMENT_ROLE = 0x8dad640ab1b088990c972676ada708447affc660890ec9fc9a5483241c49f036;

    // bytes32 internal constant AGREEMENT_POSITION = keccak256("aragonOS.appStorage.agreement");
    bytes32 internal constant AGREEMENT_POSITION = 0x6dbe80ccdeafbf5f3fff5738b224414f85e9370da36f61bf21c65159df7409e9;

    modifier onlyAgreement() {
        require(address(_getAgreement()) == msg.sender, ERROR_SENDER_NOT_AGREEMENT);
        _;
    }

    /**
    * @notice Challenge disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be challenged
    * @param _challengeId Identifier of the challenge in the context of the Agreement
    * @param _challenger Address that submitted the challenge
    */
    function onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) external onlyAgreement {
        _onDisputableActionChallenged(_disputableActionId, _challengeId, _challenger);
    }

    /**
    * @notice Allow disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be allowed
    */
    function onDisputableActionAllowed(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionAllowed(_disputableActionId);
    }

    /**
    * @notice Reject disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be rejected
    */
    function onDisputableActionRejected(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionRejected(_disputableActionId);
    }

    /**
    * @notice Void disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be voided
    */
    function onDisputableActionVoided(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionVoided(_disputableActionId);
    }

    /**
    * @notice Set Agreement to `_agreement`
    * @param _agreement Agreement instance to be set
    */
    function setAgreement(IAgreement _agreement) external auth(SET_AGREEMENT_ROLE) {
        IAgreement agreement = _getAgreement();
        require(agreement == IAgreement(0) && _agreement != IAgreement(0), ERROR_AGREEMENT_STATE_INVALID);

        AGREEMENT_POSITION.setStorageAddress(address(_agreement));
        emit AgreementSet(_agreement);
    }

    /**
    * @dev Tell the linked Agreement
    * @return Agreement
    */
    function getAgreement() external view returns (IAgreement) {
        return _getAgreement();
    }

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == DISPUTABLE_INTERFACE_ID;
    }

    /**
    * @dev Internal implementation of the `onDisputableActionChallenged` hook
    * @param _disputableActionId Identifier of the action to be challenged
    * @param _challengeId Identifier of the challenge in the context of the Agreement
    * @param _challenger Address that submitted the challenge
    */
    function _onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionRejected` hook
    * @param _disputableActionId Identifier of the action to be rejected
    */
    function _onDisputableActionRejected(uint256 _disputableActionId) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionAllowed` hook
    * @param _disputableActionId Identifier of the action to be allowed
    */
    function _onDisputableActionAllowed(uint256 _disputableActionId) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionVoided` hook
    * @param _disputableActionId Identifier of the action to be voided
    */
    function _onDisputableActionVoided(uint256 _disputableActionId) internal;

    /**
    * @dev Register a new disputable action in the Agreement
    * @param _disputableActionId Identifier of the action in the context of the Disputable
    * @param _context Link to human-readable context for the given action
    * @param _submitter Address that submitted the action
    * @return Unique identifier for the created action in the context of the Agreement
    */
    function _registerDisputableAction(uint256 _disputableActionId, bytes _context, address _submitter) internal returns (uint256) {
        IAgreement agreement = _ensureAgreement();
        return agreement.newAction(_disputableActionId, _context, _submitter);
    }

    /**
    * @dev Close disputable action in the Agreement
    * @param _actionId Identifier of the action in the context of the Agreement
    */
    function _closeDisputableAction(uint256 _actionId) internal {
        IAgreement agreement = _ensureAgreement();
        agreement.closeAction(_actionId);
    }

    /**
    * @dev Tell the linked Agreement
    * @return Agreement
    */
    function _getAgreement() internal view returns (IAgreement) {
        return IAgreement(AGREEMENT_POSITION.getStorageAddress());
    }

    /**
    * @dev Tell the linked Agreement or revert if it has not been set
    * @return Agreement
    */
    function _ensureAgreement() internal view returns (IAgreement) {
        IAgreement agreement = _getAgreement();
        require(agreement != IAgreement(0), ERROR_AGREEMENT_STATE_INVALID);
        return agreement;
    }
}

// File: @aragon/os/contracts/lib/math/SafeMath.sol

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

// File: @aragon/staking/interfaces/IStaking.sol

pragma solidity >=0.4 <=0.7;


interface IStaking {
    function allowManager(address _lockManager, uint256 _allowance, bytes _data) external;
    function allowManagerAndLock(uint256 _amount, address _lockManager, uint256 _allowance, bytes _data) external;
    function unlockAndRemoveManager(address _account, address _lockManager) external;
    function increaseLockAllowance(address _lockManager, uint256 _allowance) external;
    function decreaseLockAllowance(address _account, address _lockManager, uint256 _allowance) external;
    function lock(address _account, address _lockManager, uint256 _amount) external;
    function unlock(address _account, address _lockManager, uint256 _amount) external;
    function setLockManager(address _account, address _newLockManager) external;
    function transfer(address _to, uint256 _amount) external;
    function transferAndUnstake(address _to, uint256 _amount) external;
    function slash(address _account, address _to, uint256 _amount) external;
    function slashAndUnstake(address _account, address _to, uint256 _amount) external;

    function getLock(address _account, address _lockManager) external view returns (uint256 _amount, uint256 _allowance);
    function unlockedBalanceOf(address _account) external view returns (uint256);
    function lockedBalanceOf(address _user) external view returns (uint256);
    function getBalancesOf(address _user) external view returns (uint256 staked, uint256 locked);
    function canUnlock(address _sender, address _account, address _lockManager, uint256 _amount) external view returns (bool);
}

// File: @aragon/staking/interfaces/IStakingFactory.sol

pragma solidity >=0.4 <=0.7;



interface IStakingFactory {
    function existsInstance(/* ERC20 */ address token) external view returns (bool);
    function getInstance(/* ERC20 */ address token) external view returns (IStaking);
    function getOrCreateInstance(/* ERC20 */ address token) external returns (IStaking);
}

// File: @aragon/staking/interfaces/ILockManager.sol

pragma solidity >=0.4 <=0.7;


interface ILockManager {
    /**
     * @notice Check if `_user`'s by `_lockManager` can be unlocked
     * @param _user Owner of lock
     * @param _amount Amount of locked tokens to unlock
     * @return Whether given lock of given owner can be unlocked by given sender
     */
    function canUnlock(address _user, uint256 _amount) external view returns (bool);
}

// File: contracts/arbitration/IArbitrator.sol

pragma solidity ^0.4.24;



/**
* @title Arbitrator interface
* @dev This interface is the one used by `Agreement` as its dispute resolution protocol.
*      This interface was manually-copied from https://github.com/aragon/aragon-court/blob/v1.2.0/contracts/arbitration/IArbitrator.sol
*      since we are using different solidity versions.
*/
interface IArbitrator {
    /**
    * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
    * @param _possibleRulings Number of possible rulings allowed for the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identifier
    */
    function createDispute(uint256 _possibleRulings, bytes _metadata) external returns (uint256);

    /**
    * @dev Close the evidence period of a dispute
    * @param _disputeId Identifier of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(uint256 _disputeId) external;

    /**
    * @dev Execute the Arbitrable associated to a dispute based on its final ruling
    * @param _disputeId Identifier of the dispute to be executed
    */
    function executeRuling(uint256 _disputeId) external;

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell the subscription fees information for a subscriber to be up-to-date
    * @param _subscriber Address of the account paying the subscription fees for
    * @return recipient Address where the corresponding subscriptions fees must be transferred to
    * @return feeToken ERC20 token used for the subscription fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getSubscriptionFees(address _subscriber) external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);
}

// File: contracts/arbitration/IArbitrable.sol

pragma solidity ^0.4.24;




/**
* @title Arbitrable interface
* @dev This interface is implemented by `Agreement` so it can be used to submit disputes to an `IArbitrator`.
*      This interface was manually-copied from https://github.com/aragon/aragon-court/blob/v1.2.0/contracts/arbitration/IArbitrable.sol
*      since we are using different solidity versions.
*/
contract IArbitrable is ERC165 {
    bytes4 internal constant ARBITRABLE_INTERFACE_ID = bytes4(0x88f3ee69);

    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identifier of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);

    /**
    * @dev Emitted when new evidence is submitted for the IArbitrable instance's dispute
    * @param arbitrator IArbitrator submitting the evidence for
    * @param disputeId Identifier of the dispute receiving new evidence
    * @param submitter Address of the account submitting the evidence
    * @param evidence Data submitted for the evidence of the dispute
    * @param finished Whether or not the submitter has finished submitting evidence
    */
    event EvidenceSubmitted(IArbitrator indexed arbitrator, uint256 indexed disputeId, address indexed submitter, bytes evidence, bool finished);

    /**
    * @dev Submit evidence for a dispute
    * @param _disputeId Id of the dispute in the Court
    * @param _evidence Data submitted for the evidence related to the dispute
    * @param _finished Whether or not the submitter has finished submitting evidence
    */
    function submitEvidence(uint256 _disputeId, bytes _evidence, bool _finished) external;

    /**
    * @dev Give a ruling for a certain dispute, the account calling it must have rights to rule on the contract
    * @param _disputeId Identifier of the dispute to be ruled
    * @param _ruling Ruling given by the arbitrator, where 0 is reserved for "refused to make a decision"
    */
    function rule(uint256 _disputeId, uint256 _ruling) external;

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == ARBITRABLE_INTERFACE_ID;
    }
}

// File: contracts/arbitration/IAragonAppFeesCashier.sol

pragma solidity ^0.4.24;



/**
* @title AragonAppFeesCashier interface
* @dev This interface is derived from the `IArbitrator`'s subscriptions module.
*      It is used to pay the fees corresponding to the usage of a disputable app.
*      This interface was manually-copied from https://github.com/aragon/aragon-court/blob/v1.2.0/contracts/subscriptions/IAragonAppFeesCashier.sol
*      since we are using different solidity versions.
*/
interface IAragonAppFeesCashier {
    /**
    * @dev Emitted when an IAragonAppFeesCashier instance sets a new fee for an app
    * @param appId App identifier
    * @param token Token address to be used for the fees
    * @param amount Fee amount to be charged for the given app
    */
    event AppFeeSet(bytes32 indexed appId, ERC20 token, uint256 amount);

    /**
    * @dev Emitted when an IAragonAppFeesCashier instance unsets an app fee
    * @param appId App identifier
    */
    event AppFeeUnset(bytes32 indexed appId);

    /**
    * @dev Emitted when an IAragonAppFeesCashier instance receives a payment for an app
    * @param by Address paying the fees
    * @param appId App identifier
    * @param data Optional data
    */
    event AppFeePaid(address indexed by, bytes32 appId, bytes data);

    /**
    * @dev Set the fee amount and token to be used for an app
    * @param _appId App identifier
    * @param _token Token address to be used for the fees
    * @param _amount Fee amount to be charged for the given app
    */
    function setAppFee(bytes32 _appId, ERC20 _token, uint256 _amount) external;

    /**
    * @dev Set the fee amount and token to be used for a list of apps
    * @param _appIds List of app identifiers
    * @param _tokens List of token addresses to be used for the fees for each app
    * @param _amounts List of fee amounts to be charged for each app
    */
    function setAppFees(bytes32[] _appIds, ERC20[] _tokens, uint256[] _amounts) external;

    /**
    * @dev Remove the fee set for an app
    * @param _appId App identifier
    */
    function unsetAppFee(bytes32 _appId) external;

    /**
    * @dev Remove the fee set for a list of apps
    * @param _appIds List of app identifiers
    */
    function unsetAppFees(bytes32[] _appIds) external;

    /**
    * @dev Pay the fees corresponding to an app
    * @param _appId App identifier
    * @param _data Optional data input
    */
    function payAppFees(bytes32 _appId, bytes _data) external payable;

    /**
    * @dev Tell the fee token and amount set for a given app
    * @param _appId Identifier of the app being queried
    * @return token Fee token address set for the requested app
    * @return amount Fee token amount set for the requested app
    */
    function getAppFee(bytes32 _appId) external view returns (ERC20 token, uint256 amount);
}

// File: contracts/Agreement.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;
















contract Agreement is IArbitrable, ILockManager, IAgreement, IACLOracle, AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeERC20 for ERC20;

    /* Arbitrator outcomes constants */
    uint256 internal constant DISPUTES_POSSIBLE_OUTCOMES = 2;
    // Note that Aragon Court treats the possible outcomes as arbitrary numbers, leaving the Arbitrable (us) to define how to understand them.
    // Some outcomes [0, 1, and 2] are reserved by Aragon Court: "missing", "leaked", and "refused", respectively.
    // This Arbitrable introduces the concept of the submitter/challenger (a binary outcome) as 3/4.
    // Note that Aragon Court emits the lowest outcome in the event of a tie, and so for us, we prefer the submitter.
    uint256 internal constant DISPUTES_RULING_SUBMITTER = 3;
    uint256 internal constant DISPUTES_RULING_CHALLENGER = 4;

    /* Validation errors */
    string internal constant ERROR_SENDER_NOT_ALLOWED = "AGR_SENDER_NOT_ALLOWED";
    string internal constant ERROR_SIGNER_MUST_SIGN = "AGR_SIGNER_MUST_SIGN";
    string internal constant ERROR_SIGNER_ALREADY_SIGNED = "AGR_SIGNER_ALREADY_SIGNED";
    string internal constant ERROR_INVALID_SIGNING_SETTING = "AGR_INVALID_SIGNING_SETTING";
    string internal constant ERROR_INVALID_SETTLEMENT_OFFER = "AGR_INVALID_SETTLEMENT_OFFER";
    string internal constant ERROR_ACTION_DOES_NOT_EXIST = "AGR_ACTION_DOES_NOT_EXIST";
    string internal constant ERROR_CHALLENGE_DOES_NOT_EXIST = "AGR_CHALLENGE_DOES_NOT_EXIST";
    string internal constant ERROR_TOKEN_DEPOSIT_FAILED = "AGR_TOKEN_DEPOSIT_FAILED";
    string internal constant ERROR_TOKEN_TRANSFER_FAILED = "AGR_TOKEN_TRANSFER_FAILED";
    string internal constant ERROR_TOKEN_APPROVAL_FAILED = "AGR_TOKEN_APPROVAL_FAILED";
    string internal constant ERROR_TOKEN_NOT_CONTRACT = "AGR_TOKEN_NOT_CONTRACT";
    string internal constant ERROR_SETTING_DOES_NOT_EXIST = "AGR_SETTING_DOES_NOT_EXIST";
    string internal constant ERROR_ARBITRATOR_NOT_CONTRACT = "AGR_ARBITRATOR_NOT_CONTRACT";
    string internal constant ERROR_STAKING_FACTORY_NOT_CONTRACT = "AGR_STAKING_FACTORY_NOT_CONTRACT";
    string internal constant ERROR_ACL_ORACLE_SIGNER_MISSING = "AGR_ACL_ORACLE_SIGNER_MISSING";
    string internal constant ERROR_ACL_ORACLE_SIGNER_NOT_ADDRESS = "AGR_ACL_ORACLE_SIGNER_NOT_ADDR";

    /* Disputable related errors */
    string internal constant ERROR_SENDER_CANNOT_CHALLENGE_ACTION = "AGR_SENDER_CANT_CHALLENGE_ACTION";
    string internal constant ERROR_DISPUTABLE_NOT_CONTRACT = "AGR_DISPUTABLE_NOT_CONTRACT";
    string internal constant ERROR_DISPUTABLE_NOT_ACTIVE = "AGR_DISPUTABLE_NOT_ACTIVE";
    string internal constant ERROR_DISPUTABLE_ALREADY_ACTIVE = "AGR_DISPUTABLE_ALREADY_ACTIVE";
    string internal constant ERROR_COLLATERAL_REQUIREMENT_DOES_NOT_EXIST = "AGR_COL_REQ_DOES_NOT_EXIST";

    /* Action related errors */
    string internal constant ERROR_CANNOT_CHALLENGE_ACTION = "AGR_CANNOT_CHALLENGE_ACTION";
    string internal constant ERROR_CANNOT_CLOSE_ACTION = "AGR_CANNOT_CLOSE_ACTION";
    string internal constant ERROR_CANNOT_SETTLE_ACTION = "AGR_CANNOT_SETTLE_ACTION";
    string internal constant ERROR_CANNOT_DISPUTE_ACTION = "AGR_CANNOT_DISPUTE_ACTION";
    string internal constant ERROR_CANNOT_RULE_ACTION = "AGR_CANNOT_RULE_ACTION";
    string internal constant ERROR_CANNOT_SUBMIT_EVIDENCE = "AGR_CANNOT_SUBMIT_EVIDENCE";
    string internal constant ERROR_CANNOT_CLOSE_EVIDENCE_PERIOD = "AGR_CANNOT_CLOSE_EVIDENCE_PERIOD";

    // This role will be checked against the Disputable app when users try to challenge actions.
    // It is expected to be configured per Disputable app. For reference, see `canPerformChallenge()`.
    // bytes32 public constant CHALLENGE_ROLE = keccak256("CHALLENGE_ROLE");
    bytes32 public constant CHALLENGE_ROLE = 0xef025787d7cd1a96d9014b8dc7b44899b8c1350859fb9e1e05f5a546dd65158d;

    // bytes32 public constant CHANGE_AGREEMENT_ROLE = keccak256("CHANGE_AGREEMENT_ROLE");
    bytes32 public constant CHANGE_AGREEMENT_ROLE = 0x07813bca4905795fa22783885acd0167950db28f2d7a40b70f666f429e19f1d9;

    // bytes32 public constant MANAGE_DISPUTABLE_ROLE = keccak256("MANAGE_DISPUTABLE_ROLE");
    bytes32 public constant MANAGE_DISPUTABLE_ROLE = 0x2309a8cbbd5c3f18649f3b7ac47a0e7b99756c2ac146dda1ffc80d3f80827be6;

    event Signed(address indexed signer, uint256 settingId);
    event SettingChanged(uint256 settingId);
    event AppFeesCashierSynced(IAragonAppFeesCashier newAppFeesCashier);
    event DisputableAppActivated(address indexed disputable);
    event DisputableAppDeactivated(address indexed disputable);
    event CollateralRequirementChanged(address indexed disputable, uint256 collateralRequirementId);

    struct Setting {
        IArbitrator arbitrator;
        IAragonAppFeesCashier aragonAppFeesCashier; // Fees cashier to deposit action fees (linked to the selected arbitrator)
        string title;
        bytes content;
    }

    struct CollateralRequirement {
        ERC20 token;                        // ERC20 token to be used for collateral
        uint64 challengeDuration;           // Challenge duration, during which the submitter can raise a dispute
        uint256 actionAmount;               // Amount of collateral token to be locked from the submitter's staking pool when creating actions
        uint256 challengeAmount;            // Amount of collateral token to be locked from the challenger's own balance when challenging actions
        IStaking staking;                   // Staking pool cache for the collateral token -- will never change
    }

    struct DisputableInfo {
        bool activated;                                                     // Whether the Disputable app is active
        uint256 nextCollateralRequirementsId;                               // Identification number of the next collateral requirement
        mapping (uint256 => CollateralRequirement) collateralRequirements;  // List of collateral requirements indexed by ID
    }

    struct Action {
        DisputableAragonApp disputable;     // Disputable app that created the action
        uint256 disputableActionId;         // Identification number of the action on the Disputable app
        uint256 collateralRequirementId;    // Identification number of the collateral requirement applicable to the action
        uint256 settingId;                  // Identification number of the agreement setting applicable to the action
        address submitter;                  // Address that submitted the action
        bool closed;                        // Whether the action is closed (and cannot be challenged anymore)
        bytes context;                      // Link to a human-readable context for the given action
        uint256 lastChallengeId;            // Identification number of the action's most recent challenge, if any
    }

    struct ArbitratorFees {
        ERC20 token;                        // ERC20 token used for the arbitration fees
        uint256 amount;                     // Amount of arbitration fees
    }

    struct Challenge {
        uint256 actionId;                        // Identification number of the action associated to the challenge
        address challenger;                      // Address that challenged the action
        uint64 endDate;                          // Last date the submitter can raise a dispute against the challenge
        bytes context;                           // Link to a human-readable context for the challenge
        uint256 settlementOffer;                 // Amount of collateral tokens the challenger would accept without involving the arbitrator
        ArbitratorFees challengerArbitratorFees; // Arbitration fees paid by the challenger (in advance)
        ArbitratorFees submitterArbitratorFees;  // Arbitration fees paid by the submitter (on dispute creation)
        ChallengeState state;                    // Current state of the challenge
        bool submitterFinishedEvidence;          // Whether the action submitter has finished submitting evidence for the raised dispute
        bool challengerFinishedEvidence;         // Whether the action challenger has finished submitting evidence for the raised dispute
        uint256 disputeId;                       // Identification number of the dispute on the arbitrator
        uint256 ruling;                          // Ruling given from the arbitrator for the dispute
    }

    IStakingFactory public stakingFactory;                           // Staking factory, for finding each collateral token's staking pool

    uint256 private nextSettingId;
    mapping (uint256 => Setting) private settings;                  // List of historic agreement settings indexed by ID (starting at 1)
    mapping (address => uint256) private lastSettingSignedBy;       // Mapping of address => last agreement setting signed
    mapping (address => DisputableInfo) private disputableInfos;    // Mapping of Disputable app => disputable infos

    uint256 private nextActionId;
    mapping (uint256 => Action) private actions;                    // List of actions indexed by ID (starting at 1)

    uint256 private nextChallengeId;
    mapping (uint256 => Challenge) private challenges;              // List of challenges indexed by ID (starting at 1)
    mapping (uint256 => uint256) private challengeByDispute;        // Mapping of arbitrator's dispute ID => challenge ID

    /**
    * @notice Initialize Agreement for "`_title`" and content "`_content`", with arbitrator `_arbitrator` and staking factory `_factory`
    * @param _arbitrator Address of the IArbitrator that will be used to resolve disputes
    * @param _setAppFeesCashier Whether to integrate with the IArbitrator's fee cashier
    * @param _title String indicating a short description
    * @param _content Link to a human-readable text that describes the initial rules for the Agreement
    * @param _stakingFactory Staking factory for finding each collateral token's staking pool
    */
    function initialize(
        IArbitrator _arbitrator,
        bool _setAppFeesCashier,
        string _title,
        bytes _content,
        IStakingFactory _stakingFactory
    )
        external
    {
        initialized();
        require(isContract(address(_stakingFactory)), ERROR_STAKING_FACTORY_NOT_CONTRACT);

        stakingFactory = _stakingFactory;

        nextSettingId = 1;   // Agreement setting ID zero is considered the null agreement setting for further validations
        nextActionId = 1;    // Action ID zero is considered the null action for further validations
        nextChallengeId = 1; // Challenge ID zero is considered the null challenge for further validations
        _newSetting(_arbitrator, _setAppFeesCashier, _title, _content);
    }

    /**
    * @notice Update Agreement to title "`_title`" and content "`_content`", with arbitrator `_arbitrator`
    * @dev Initialization check is implicitly provided by the `auth()` modifier
    * @param _arbitrator Address of the IArbitrator that will be used to resolve disputes
    * @param _setAppFeesCashier Whether to integrate with the IArbitrator's fee cashier
    * @param _title String indicating a short description
    * @param _content Link to a human-readable text that describes the new rules for the Agreement
    */
    function changeSetting(
        IArbitrator _arbitrator,
        bool _setAppFeesCashier,
        string _title,
        bytes _content
    )
        external
        auth(CHANGE_AGREEMENT_ROLE)
    {
        _newSetting(_arbitrator, _setAppFeesCashier, _title, _content);
    }

    /**
    * @notice Sync app fees cashier address
    * @dev The app fees cashier address is being cached in the contract to save gas.
    *      This can be called permission-lessly to allow any account to re-sync the cashier when changed by the arbitrator.
    *      Initialization check is implicitly provided by `_getSetting()`, as valid settings can only be created after initialization.
    */
    function syncAppFeesCashier() external {
        Setting storage setting = _getSetting(_getCurrentSettingId());
        IAragonAppFeesCashier newAppFeesCashier = _getArbitratorFeesCashier(setting.arbitrator);
        IAragonAppFeesCashier currentAppFeesCashier = setting.aragonAppFeesCashier;

        // Sync the app fees cashier only if there was one set before and it's different from the arbitrator's current one
        if (currentAppFeesCashier != IAragonAppFeesCashier(0) && currentAppFeesCashier != newAppFeesCashier) {
            setting.aragonAppFeesCashier = newAppFeesCashier;
            emit AppFeesCashierSynced(newAppFeesCashier);
        }
    }

    /**
    * @notice Activate Disputable app `_disputableAddress`
    * @dev Initialization check is implicitly provided by the `auth()` modifier
    * @param _disputableAddress Address of the Disputable app
    * @param _collateralToken Address of the ERC20 token to be used for collateral
    * @param _actionAmount Amount of collateral tokens that will be locked every time an action is submitted
    * @param _challengeAmount Amount of collateral tokens that will be locked every time an action is challenged
    * @param _challengeDuration Challenge duration, during which the submitter can raise a dispute
    */
    function activate(
        address _disputableAddress,
        ERC20 _collateralToken,
        uint64 _challengeDuration,
        uint256 _actionAmount,
        uint256 _challengeAmount
    )
        external
        auth(MANAGE_DISPUTABLE_ROLE)
    {
        require(isContract(_disputableAddress), ERROR_DISPUTABLE_NOT_CONTRACT);

        DisputableInfo storage disputableInfo = disputableInfos[_disputableAddress];
        _ensureInactiveDisputable(disputableInfo);

        DisputableAragonApp disputable = DisputableAragonApp(_disputableAddress);
        disputableInfo.activated = true;

        // If the disputable app is being activated for the first time, then we need to set-up its initial collateral
        // requirement and set its Agreement reference to here.
        if (disputable.getAgreement() != IAgreement(this)) {
            disputable.setAgreement(IAgreement(this));
            uint256 nextId = disputableInfo.nextCollateralRequirementsId;
            disputableInfo.nextCollateralRequirementsId = nextId > 0 ? nextId : 1;
        }
        _changeCollateralRequirement(disputable, disputableInfo, _collateralToken, _challengeDuration, _actionAmount, _challengeAmount);

        emit DisputableAppActivated(disputable);
    }

    /**
    * @notice Deactivate Disputable app `_disputable`
    * @dev Initialization check is implicitly provided by the `auth()` modifier
    * @param _disputableAddress Address of the Disputable app to be deactivated
    */
    function deactivate(address _disputableAddress) external auth(MANAGE_DISPUTABLE_ROLE) {
        DisputableInfo storage disputableInfo = disputableInfos[_disputableAddress];
        _ensureActiveDisputable(disputableInfo);

        disputableInfo.activated = false;
        emit DisputableAppDeactivated(_disputableAddress);
    }

    /**
    * @notice Change `_disputable`'s collateral requirements
    * @dev Initialization check is implicitly provided by the `auth()` modifier
    * @param _disputable Address of the Disputable app
    * @param _collateralToken Address of the ERC20 token to be used for collateral
    * @param _actionAmount Amount of collateral tokens that will be locked every time an action is submitted
    * @param _challengeAmount Amount of collateral tokens that will be locked every time an action is challenged
    * @param _challengeDuration Challenge duration, during which the submitter can raise a dispute
    */
    function changeCollateralRequirement(
        DisputableAragonApp _disputable,
        ERC20 _collateralToken,
        uint64 _challengeDuration,
        uint256 _actionAmount,
        uint256 _challengeAmount
    )
        external
        auth(MANAGE_DISPUTABLE_ROLE)
    {
        DisputableInfo storage disputableInfo = disputableInfos[address(_disputable)];
        _ensureActiveDisputable(disputableInfo);

        _changeCollateralRequirement(_disputable, disputableInfo, _collateralToken, _challengeDuration, _actionAmount, _challengeAmount);
    }

    /**
    * @notice Sign the agreement up-to setting #`_settingId`
    * @dev Callable by any account; only accounts that have signed the latest version of the agreement can submit new disputable actions.
    *      Initialization check is implicitly provided by `_settingId < nextSettingId`, as valid settings can only be created after initialization.
    * @param _settingId Last setting ID the user is agreeing with
    */
    function sign(uint256 _settingId) external {
        uint256 lastSettingIdSigned = lastSettingSignedBy[msg.sender];
        require(lastSettingIdSigned < _settingId, ERROR_SIGNER_ALREADY_SIGNED);
        require(_settingId < nextSettingId, ERROR_INVALID_SIGNING_SETTING);

        lastSettingSignedBy[msg.sender] = _settingId;
        emit Signed(msg.sender, _settingId);
    }

    /**
    * @notice Register action #`_disputableActionId` from disputable `msg.sender` for submitter `_submitter` with context `_context`
    * @dev This function should be called from the Disputable app each time a new disputable action is created.
    *      Each disputable action ID must only be registered once; this is how the Agreement gets notified about each disputable action.
    *      Initialization check is implicitly provided by `_ensureActiveDisputable()` as Disputable apps can only be activated
    *      via `activate()` which already requires initialization.
    *      IMPORTANT: Note the responsibility of the Disputable app in terms of providing the correct `_submitter` parameter.
    *      Users are required to trust that all Disputable apps activated with this Agreement have implemented this correctly, as
    *      otherwise funds could be maliciously locked from the incorrect account on new actions.
    * @param _disputableActionId Identification number of the action on the Disputable app
    * @param _context Link to a human-readable context for the given action
    * @param _submitter Address that submitted the action
    * @return Unique identification number for the created action on the Agreement
    */
    function newAction(uint256 _disputableActionId, bytes _context, address _submitter) external returns (uint256) {
        DisputableInfo storage disputableInfo = disputableInfos[msg.sender];
        _ensureActiveDisputable(disputableInfo);

        uint256 currentSettingId = _getCurrentSettingId();
        uint256 lastSettingIdSigned = lastSettingSignedBy[_submitter];
        require(lastSettingIdSigned >= currentSettingId, ERROR_SIGNER_MUST_SIGN);

        // An initial collateral requirement is created when disputable apps are activated, thus length is always greater than 0
        uint256 currentCollateralRequirementId = disputableInfo.nextCollateralRequirementsId - 1;
        CollateralRequirement storage requirement = _getCollateralRequirement(disputableInfo, currentCollateralRequirementId);
        _lockBalance(requirement.staking, _submitter, requirement.actionAmount);

        // Pay action submission fees
        Setting storage setting = _getSetting(currentSettingId);
        DisputableAragonApp disputable = DisputableAragonApp(msg.sender);
        _payAppFees(setting, disputable, _submitter, id);

        uint256 id = nextActionId++;
        Action storage action = actions[id];
        action.disputable = disputable;
        action.disputableActionId = _disputableActionId;
        action.collateralRequirementId = currentCollateralRequirementId;
        action.settingId = currentSettingId;
        action.submitter = _submitter;
        action.context = _context;

        emit ActionSubmitted(id, msg.sender);
        return id;
    }

    /**
    * @notice Close action #`_actionId`
    * @dev This function closes actions that:
    *      - Are not currently challenged nor disputed, or
    *      - Were previously disputed but ruled in favour of the submitter or voided
    *      Disputable apps may call this method directly at the end of an action, but is also accessible in a permission-less manner
    *      in case the app does not close its own actions automatically (e.g. disputable votes that don't pass).
    *      Can be called multiple times; it does nothing if the action is already closed.
    *      Initialization check is implicitly provided by `_getAction()` as disputable actions can only be created via `newAction()`.
    * @param _actionId Identification number of the action to be closed
    */
    function closeAction(uint256 _actionId) external {
        Action storage action = _getAction(_actionId);
        if (action.closed) {
            return;
        }

        require(_canClose(action), ERROR_CANNOT_CLOSE_ACTION);
        (, CollateralRequirement storage requirement) = _getDisputableInfoFor(action);
        _unlockBalance(requirement.staking, action.submitter, requirement.actionAmount);
        _unsafeCloseAction(_actionId, action);
    }

    /**
    * @notice Challenge action #`_actionId`
    * @dev This is only callable by those who hold the CHALLENGE_ROLE on the related Disputable app.
    *      Can be called multiple times per action, until a challenge is successful (settled or ruled for challenger).
    *      Initialization check is implicitly provided by `_getAction()` as disputable actions can only be created via `newAction()`.
    * @param _actionId Identification number of the action to be challenged
    * @param _settlementOffer Amount of collateral tokens the challenger would accept for resolving the dispute without involving the arbitrator
    * @param _finishedEvidence Whether the challenger is finished submitting evidence with the challenge context
    * @param _context Link to a human-readable context for the challenge
    */
    function challengeAction(uint256 _actionId, uint256 _settlementOffer, bool _finishedEvidence, bytes _context) external {
        Action storage action = _getAction(_actionId);
        require(_canChallenge(action), ERROR_CANNOT_CHALLENGE_ACTION);

        (DisputableAragonApp disputable, CollateralRequirement storage requirement) = _getDisputableInfoFor(action);
        require(_canPerformChallenge(disputable, msg.sender), ERROR_SENDER_CANNOT_CHALLENGE_ACTION);
        require(_settlementOffer <= requirement.actionAmount, ERROR_INVALID_SETTLEMENT_OFFER);

        uint256 challengeId = _createChallenge(_actionId, action, msg.sender, requirement, _settlementOffer, _finishedEvidence, _context);
        action.lastChallengeId = challengeId;
        disputable.onDisputableActionChallenged(action.disputableActionId, challengeId, msg.sender);
        emit ActionChallenged(_actionId, challengeId);
    }

    /**
    * @notice Settle challenged action #`_actionId`, accepting the settlement offer
    * @dev This can be accessed by both the submitter (at any time) or any account (after the settlement period has passed).
    *      Can only be called once (if at all) per opened challenge.
    *      Initialization check is implicitly provided by `_getChallengedAction()` as disputable actions can only be created via `newAction()`.
    * @param _actionId Identification number of the action to be settled
    */
    function settleAction(uint256 _actionId) external {
        (Action storage action, Challenge storage challenge, uint256 challengeId) = _getChallengedAction(_actionId);
        address submitter = action.submitter;

        if (msg.sender == submitter) {
            require(_canSettle(challenge), ERROR_CANNOT_SETTLE_ACTION);
        } else {
            require(_canClaimSettlement(challenge), ERROR_CANNOT_SETTLE_ACTION);
        }

        (DisputableAragonApp disputable, CollateralRequirement storage requirement) = _getDisputableInfoFor(action);
        uint256 actionCollateral = requirement.actionAmount;
        uint256 settlementOffer = challenge.settlementOffer;

        // The settlement offer was already checked to be up-to the collateral amount upon challenge creation
        // However, we cap it to collateral amount to be safe
        // With this, we can avoid using SafeMath to calculate `unlockedAmount`
        uint256 slashedAmount = settlementOffer >= actionCollateral ? actionCollateral : settlementOffer;
        uint256 unlockedAmount = actionCollateral - slashedAmount;

        // Unlock and slash action collateral for settlement offer
        address challenger = challenge.challenger;
        IStaking staking = requirement.staking;
        _unlockBalance(staking, submitter, unlockedAmount);
        _slashBalance(staking, submitter, challenger, slashedAmount);

        // Transfer challenge collateral and challenger arbitrator fees back to the challenger
        _transferTo(requirement.token, challenger, requirement.challengeAmount);
        _transferTo(challenge.challengerArbitratorFees.token, challenger, challenge.challengerArbitratorFees.amount);

        challenge.state = ChallengeState.Settled;
        disputable.onDisputableActionRejected(action.disputableActionId);
        emit ActionSettled(_actionId, challengeId);
        _unsafeCloseAction(_actionId, action);
    }

    /**
    * @notice Dispute challenged action #`_actionId`, raising it to the arbitrator
    * @dev Only the action submitter can create a dispute for an action with an open challenge.
    *      Can only be called once (if at all) per opened challenge.
    *      Initialization check is implicitly provided by `_getChallengedAction()` as disputable actions can only be created via `newAction()`.
    * @param _actionId Identification number of the action to be disputed
    * @param _submitterFinishedEvidence Whether the submitter was finished submitting evidence with their action context
    */
    function disputeAction(uint256 _actionId, bool _submitterFinishedEvidence) external {
        (Action storage action, Challenge storage challenge, uint256 challengeId) = _getChallengedAction(_actionId);
        require(_canDispute(challenge), ERROR_CANNOT_DISPUTE_ACTION);

        address submitter = action.submitter;
        require(msg.sender == submitter, ERROR_SENDER_NOT_ALLOWED);

        IArbitrator arbitrator = _getArbitratorFor(action);
        bytes memory metadata = abi.encodePacked(appId(), action.lastChallengeId);
        uint256 disputeId = _createDispute(action, challenge, arbitrator, metadata);
        _submitEvidence(arbitrator, disputeId, submitter, action.context, _submitterFinishedEvidence);
        _submitEvidence(arbitrator, disputeId, challenge.challenger, challenge.context, challenge.challengerFinishedEvidence);

        challenge.state = ChallengeState.Disputed;
        challenge.submitterFinishedEvidence = _submitterFinishedEvidence;
        challenge.disputeId = disputeId;
        challengeByDispute[disputeId] = challengeId;
        emit ActionDisputed(_actionId, challengeId);
    }

    /**
    * @notice Submit evidence for dispute #`_disputeId`
    * @dev Only callable by the action submitter or challenger.
    *      Can be called as many times as desired until the dispute is over.
    *      Initialization check is implicitly provided by `_getDisputedAction()` as disputable actions can only be created via `newAction()`.
    * @param _disputeId Identification number of the dispute on the arbitrator
    * @param _evidence Evidence data to be submitted
    * @param _finished Whether the evidence submitter is now finished submitting evidence
    */
    function submitEvidence(uint256 _disputeId, bytes _evidence, bool _finished) external {
        (, Action storage action, , Challenge storage challenge) = _getDisputedAction(_disputeId);
        require(_isDisputed(challenge), ERROR_CANNOT_SUBMIT_EVIDENCE);

        IArbitrator arbitrator = _getArbitratorFor(action);
        if (msg.sender == action.submitter) {
            // If the submitter finished submitting evidence earlier, also emit this event as finished
            bool submitterFinishedEvidence = challenge.submitterFinishedEvidence || _finished;
            _submitEvidence(arbitrator, _disputeId, msg.sender, _evidence, submitterFinishedEvidence);
            challenge.submitterFinishedEvidence = submitterFinishedEvidence;
        } else if (msg.sender == challenge.challenger) {
            // If the challenger finished submitting evidence earlier, also emit this event as finished
            bool challengerFinishedEvidence = challenge.challengerFinishedEvidence || _finished;
            _submitEvidence(arbitrator, _disputeId, msg.sender, _evidence, challengerFinishedEvidence);
            challenge.challengerFinishedEvidence = challengerFinishedEvidence;
        } else {
            revert(ERROR_SENDER_NOT_ALLOWED);
        }
    }

    /**
    * @notice Close evidence submission period for dispute #`_disputeId`
    * @dev Callable by any account.
    *      Initialization check is implicitly provided by `_getDisputedAction()` as disputable actions can only be created via `newAction()`.
    * @param _disputeId Identification number of the dispute on the arbitrator
    */
    function closeEvidencePeriod(uint256 _disputeId) external {
        (, Action storage action, , Challenge storage challenge) = _getDisputedAction(_disputeId);
        require(_isDisputed(challenge), ERROR_CANNOT_SUBMIT_EVIDENCE);
        require(challenge.submitterFinishedEvidence && challenge.challengerFinishedEvidence, ERROR_CANNOT_CLOSE_EVIDENCE_PERIOD);

        IArbitrator arbitrator = _getArbitratorFor(action);
        arbitrator.closeEvidencePeriod(_disputeId);
    }

    /**
    * @notice Rule the action associated to dispute #`_disputeId` with ruling `_ruling`
    * @dev Can only be called once per challenge by the associated abitrator.
    *      Initialization check is implicitly provided by `_getDisputedAction()` as disputable actions can only be created via `newAction()`.
    * @param _disputeId Identification number of the dispute on the arbitrator
    * @param _ruling Ruling given by the arbitrator
    */
    function rule(uint256 _disputeId, uint256 _ruling) external {
        (uint256 actionId, Action storage action, uint256 challengeId, Challenge storage challenge) = _getDisputedAction(_disputeId);
        require(_isDisputed(challenge), ERROR_CANNOT_RULE_ACTION);

        IArbitrator arbitrator = _getArbitratorFor(action);
        require(arbitrator == IArbitrator(msg.sender), ERROR_SENDER_NOT_ALLOWED);

        challenge.ruling = _ruling;
        emit Ruled(arbitrator, _disputeId, _ruling);

        if (_ruling == DISPUTES_RULING_SUBMITTER) {
            _acceptAction(actionId, action, challengeId, challenge);
        } else if (_ruling == DISPUTES_RULING_CHALLENGER) {
            _rejectAction(actionId, action, challengeId, challenge);
        } else {
            _voidAction(actionId, action, challengeId, challenge);
        }
    }

    // Getter fns

    /**
    * @dev Tell the identification number of the current agreement setting
    * @return Identification number of the current agreement setting
    */
    function getCurrentSettingId() external view returns (uint256) {
        return _getCurrentSettingId();
    }

    /**
    * @dev Tell the information related to an agreement setting
    * @param _settingId Identification number of the agreement setting
    * @return arbitrator Address of the IArbitrator that will be used to resolve disputes
    * @return aragonAppFeesCashier Address of the fees cashier to deposit action fees (linked to the selected arbitrator)
    * @return title String indicating a short description
    * @return content Link to a human-readable text that describes the current rules for the Agreement
    */
    function getSetting(uint256 _settingId)
        external
        view
        returns (IArbitrator arbitrator, IAragonAppFeesCashier aragonAppFeesCashier, string title, bytes content)
    {
        Setting storage setting = _getSetting(_settingId);
        arbitrator = setting.arbitrator;
        aragonAppFeesCashier = setting.aragonAppFeesCashier;
        title = setting.title;
        content = setting.content;
    }

    /**
    * @dev Tell the information related to a Disputable app
    * @param _disputable Address of the Disputable app
    * @return activated Whether the Disputable app is active
    * @return currentCollateralRequirementId Identification number of the current collateral requirement
    */
    function getDisputableInfo(address _disputable) external view returns (bool activated, uint256 currentCollateralRequirementId) {
        DisputableInfo storage disputableInfo = disputableInfos[_disputable];
        activated = disputableInfo.activated;
        uint256 nextId = disputableInfo.nextCollateralRequirementsId;
        // Since `nextCollateralRequirementsId` is initialized to 1 when disputable apps are activated, it is safe to consider the
        // current collateral requirement ID of a disputable app as 0 if it has not been set yet, which means it was not activated yet.
        currentCollateralRequirementId = nextId == 0 ? 0 : nextId - 1;
    }

    /**
    * @dev Tell the information related to a collateral requirement of a Disputable app
    * @param _disputable Address of the Disputable app
    * @param _collateralRequirementId Identification number of the collateral requirement
    * @return collateralToken Address of the ERC20 token to be used for collateral
    * @return actionAmount Amount of collateral tokens that will be locked every time an action is created
    * @return challengeAmount Amount of collateral tokens that will be locked every time an action is challenged
    * @return challengeDuration Challenge duration, during which the submitter can raise a dispute
    */
    function getCollateralRequirement(address _disputable, uint256 _collateralRequirementId)
        external
        view
        returns (
            ERC20 collateralToken,
            uint64 challengeDuration,
            uint256 actionAmount,
            uint256 challengeAmount
        )
    {
        DisputableInfo storage disputableInfo = disputableInfos[_disputable];
        CollateralRequirement storage collateral = _getCollateralRequirement(disputableInfo, _collateralRequirementId);
        collateralToken = collateral.token;
        actionAmount = collateral.actionAmount;
        challengeAmount = collateral.challengeAmount;
        challengeDuration = collateral.challengeDuration;
    }

    /**
    * @dev Tell the information related to a signer
    * @param _signer Address of signer
    * @return lastSettingIdSigned Identification number of the last agreement setting signed by the signer
    * @return mustSign Whether the requested signer needs to sign the current agreement setting before submitting an action
    */
    function getSigner(address _signer) external view returns (uint256 lastSettingIdSigned, bool mustSign) {
        (lastSettingIdSigned, mustSign) = _getSigner(_signer);
    }

    /**
    * @dev Tell the information related to an action
    * @param _actionId Identification number of the action
    * @return disputable Address of the Disputable app that created the action
    * @return disputableActionId Identification number of the action on the Disputable app
    * @return collateralRequirementId Identification number of the collateral requirement applicable to the action
    * @return settingId Identification number of the agreement setting applicable to the action
    * @return submitter Address that submitted the action
    * @return closed Whether the action is closed
    * @return context Link to a human-readable context for the action
    * @return lastChallengeId Identification number of the action's most recent challenge, if any
    * @return lastChallengeActive Whether the action's most recent challenge is still ongoing
    */
    function getAction(uint256 _actionId)
        external
        view
        returns (
            address disputable,
            uint256 disputableActionId,
            uint256 collateralRequirementId,
            uint256 settingId,
            address submitter,
            bool closed,
            bytes context,
            uint256 lastChallengeId,
            bool lastChallengeActive
        )
    {
        Action storage action = _getAction(_actionId);

        disputable = action.disputable;
        disputableActionId = action.disputableActionId;
        collateralRequirementId = action.collateralRequirementId;
        settingId = action.settingId;
        submitter = action.submitter;
        closed = action.closed;
        context = action.context;
        lastChallengeId = action.lastChallengeId;

        if (lastChallengeId > 0) {
            (, Challenge storage challenge, ) = _getChallengedAction(_actionId);
            lastChallengeActive = _isWaitingChallengeAnswer(challenge) || _isDisputed(challenge);
        }
    }

    /**
    * @dev Tell the information related to an action challenge
    * @param _challengeId Identification number of the challenge
    * @return actionId Identification number of the action associated to the challenge
    * @return challenger Address that challenged the action
    * @return endDate Datetime of the last date the submitter can raise a dispute against the challenge
    * @return context Link to a human-readable context for the challenge
    * @return settlementOffer Amount of collateral tokens the challenger would accept for resolving the dispute without involving the arbitrator
    * @return state Current state of the challenge
    * @return submitterFinishedEvidence Whether the action submitter has finished submitting evidence for the associated dispute
    * @return challengerFinishedEvidence Whether the action challenger has finished submitting evidence for the associated dispute
    * @return disputeId Identification number of the associated dispute on the arbitrator
    * @return ruling Ruling given from the arbitrator for the dispute
    */
    function getChallenge(uint256 _challengeId)
        external
        view
        returns (
            uint256 actionId,
            address challenger,
            uint64 endDate,
            bytes context,
            uint256 settlementOffer,
            ChallengeState state,
            bool submitterFinishedEvidence,
            bool challengerFinishedEvidence,
            uint256 disputeId,
            uint256 ruling
        )
    {
        Challenge storage challenge = _getChallenge(_challengeId);

        actionId = challenge.actionId;
        challenger = challenge.challenger;
        endDate = challenge.endDate;
        context = challenge.context;
        settlementOffer = challenge.settlementOffer;
        state = challenge.state;
        submitterFinishedEvidence = challenge.submitterFinishedEvidence;
        challengerFinishedEvidence = challenge.challengerFinishedEvidence;
        disputeId = challenge.disputeId;
        ruling = challenge.ruling;
    }

    /**
    * @dev Tell the arbitration fees paid for an action challenge
    *      Split from `getChallenge()` due to “stack too deep issues”
    * @param _challengeId Identification number of the challenge
    * @return submitterArbitratorFeesToken ERC20 token used for the arbitration fees paid by the submitter (on dispute creation)
    * @return submitterArbitratorFeesAmount Amount of arbitration fees paid by the submitter (on dispute creation)
    * @return challengerArbitratorFeesToken ERC20 token used for the arbitration fees paid by the challenger (in advance)
    * @return challengerArbitratorFeesAmount Amount of arbitration fees paid by the challenger (in advance)
    */
    function getChallengeArbitratorFees(uint256 _challengeId)
        external
        view
        returns (
            ERC20 submitterArbitratorFeesToken,
            uint256 submitterArbitratorFeesAmount,
            ERC20 challengerArbitratorFeesToken,
            uint256 challengerArbitratorFeesAmount
        )
    {
        Challenge storage challenge = _getChallenge(_challengeId);

        submitterArbitratorFeesToken = challenge.submitterArbitratorFees.token;
        submitterArbitratorFeesAmount = challenge.submitterArbitratorFees.amount;
        challengerArbitratorFeesToken = challenge.challengerArbitratorFees.token;
        challengerArbitratorFeesAmount = challenge.challengerArbitratorFees.amount;
    }

    /**
    * @dev Tell whether an action can be challenged
    * @param _actionId Identification number of the action
    * @return True if the action can be challenged, false otherwise
    */
    function canChallenge(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canChallenge(action);
    }

    /**
    * @dev Tell whether an action can be manually closed.
    *      An action can be closed if it is allowed to:
    *       - Proceed in the context of this Agreement (see `_canProceed()`), and
    *       - Be closed in the context of the originating Disputable app
    * @param _actionId Identification number of the action
    * @return True if the action can be closed, false otherwise
    */
    function canClose(uint256 _actionId) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canClose(action);
    }

    /**
    * @dev Tell whether an action can be settled
    * @param _actionId Identification number of the action
    * @return True if the action can be settled, false otherwise
    */
    function canSettle(uint256 _actionId) external view returns (bool) {
        (, Challenge storage challenge, ) = _getChallengedAction(_actionId);
        return _canSettle(challenge);
    }

    /**
    * @dev Tell whether an action can be settled by claiming its challenge settlement
    * @param _actionId Identification number of the action
    * @return True if the action settlement can be claimed, false otherwise
    */
    function canClaimSettlement(uint256 _actionId) external view returns (bool) {
        (, Challenge storage challenge, ) = _getChallengedAction(_actionId);
        return _canClaimSettlement(challenge);
    }

    /**
    * @dev Tell whether an action can be disputed
    * @param _actionId Identification number of the action
    * @return True if the action can be disputed, false otherwise
    */
    function canDispute(uint256 _actionId) external view returns (bool) {
        (, Challenge storage challenge, ) = _getChallengedAction(_actionId);
        return _canDispute(challenge);
    }

    /**
    * @dev Tell whether an action's dispute can be ruled
    * @param _actionId Identification number of the action
    * @return True if the action's dispute can be ruled, false otherwise
    */
    function canRuleDispute(uint256 _actionId) external view returns (bool) {
        (, Challenge storage challenge, ) = _getChallengedAction(_actionId);
        return _isDisputed(challenge);
    }

    /**
    * @dev Tell whether an address can challenge an action
    * @param _actionId Identification number of the action
    * @param _challenger Address of the challenger
    * @return True if the challenger can challenge the action, false otherwise
    */
    function canPerformChallenge(uint256 _actionId, address _challenger) external view returns (bool) {
        Action storage action = _getAction(_actionId);
        return _canPerformChallenge(action.disputable, _challenger);
    }

    /**
    * @notice Tells whether an address has already signed the Agreement
    * @dev ACL oracle interface conformance
    * @return True if a parameterized address has signed the current version of the Agreement, false otherwise
    */
    function canPerform(address /* _grantee */, address /* _where */, bytes32 /* _what */, uint256[] _how)
        external
        view
        returns (bool)
    {
        // We currently expect the address as the only permission parameter because an ACL Oracle's `grantee`
        // argument is not provided with the original sender if the permission is set for ANY_ENTITY.
        require(_how.length > 0, ERROR_ACL_ORACLE_SIGNER_MISSING);
        require(_how[0] < 2**160, ERROR_ACL_ORACLE_SIGNER_NOT_ADDRESS);

        address signer = address(_how[0]);
        (, bool mustSign) = _getSigner(signer);
        return !mustSign;
    }

    /**
    * @dev ILockManager conformance.
    *      The Staking contract checks this on each request to unlock an amount managed by this Agreement.
    *      It always returns false to disable owners from unlocking their funds arbitrarily, as we
    *      want to control the release of the locked amount when actions are closed or settled.
    * @return Whether the request to unlock tokens of a given owner should be allowed
    */
    function canUnlock(address, uint256) external view returns (bool) {
        return false;
    }

    /**
    * @dev Disable built-in AragonApp token recovery escape hatch.
    *      This app is intended to hold users' funds and we do not want to allow them to be transferred to the default vault.
    * @return Always false
    */
    function allowRecoverability(address /* _token */) public view returns (bool) {
        return false;
    }

    // Internal fns

    /**
    * @dev Change agreement settings
    * @param _arbitrator Address of the IArbitrator that will be used to resolve disputes
    * @param _setAppFeesCashier Whether to integrate with the IArbitrator's fee cashier
    * @param _title String indicating a short description
    * @param _content Link to a human-readable text that describes the new rules for the Agreement
    */
    function _newSetting(IArbitrator _arbitrator, bool _setAppFeesCashier, string _title, bytes _content) internal {
        require(isContract(address(_arbitrator)), ERROR_ARBITRATOR_NOT_CONTRACT);

        uint256 id = nextSettingId++;
        Setting storage setting = settings[id];
        setting.title = _title;
        setting.content = _content;
        setting.arbitrator = _arbitrator;

        // Note that if the Agreement app didn't have an app fees cashier set at the start, then it must be explicitly set later.
        // Arbitrators must always have at least some sort of subscription module, and having the flexibility to turn this off
        // on the Agreement side can be useful.
        setting.aragonAppFeesCashier = _setAppFeesCashier ? _getArbitratorFeesCashier(_arbitrator) : IAragonAppFeesCashier(0);
        emit SettingChanged(id);
    }

    /**
    * @dev Change the collateral requirements of an active Disputable app
    * @param _disputable Address of the Disputable app
    * @param _disputableInfo Disputable info instance for the Disputable app
    * @param _collateralToken Address of the ERC20 token to be used for collateral
    * @param _actionAmount Amount of collateral tokens that will be locked every time an action is submitted
    * @param _challengeAmount Amount of collateral tokens that will be locked every time an action is challenged
    * @param _challengeDuration Challenge duration, during which the submitter can raise a dispute
    */
    function _changeCollateralRequirement(
        DisputableAragonApp _disputable,
        DisputableInfo storage _disputableInfo,
        ERC20 _collateralToken,
        uint64 _challengeDuration,
        uint256 _actionAmount,
        uint256 _challengeAmount
    )
        internal
    {
        require(isContract(address(_collateralToken)), ERROR_TOKEN_NOT_CONTRACT);

        IStaking staking = stakingFactory.getOrCreateInstance(_collateralToken);
        uint256 id = _disputableInfo.nextCollateralRequirementsId++;
        CollateralRequirement storage collateralRequirement = _disputableInfo.collateralRequirements[id];
        collateralRequirement.token = _collateralToken;
        collateralRequirement.challengeDuration = _challengeDuration;
        collateralRequirement.actionAmount = _actionAmount;
        collateralRequirement.challengeAmount = _challengeAmount;
        collateralRequirement.staking = staking;

        emit CollateralRequirementChanged(_disputable, id);
    }

    /**
    * @dev Pay transactions fees required for new actions
    * @param _setting Agreement setting instance, used to get Aragon App Fees Cashier
    * @param _disputable Address of the Disputable app, used to determine fees
    * @param _submitter Address that submitted the action
    * @param _actionId Identification number of the action being paid for
    */
    function _payAppFees(Setting storage _setting, DisputableAragonApp _disputable, address _submitter, uint256 _actionId) internal {
        // Get fees
        IAragonAppFeesCashier aragonAppFeesCashier = _setting.aragonAppFeesCashier;
        if (aragonAppFeesCashier == IAragonAppFeesCashier(0)) {
            return;
        }

        bytes32 appId = _disputable.appId();
        (ERC20 token, uint256 amount) = aragonAppFeesCashier.getAppFee(appId);

        if (amount == 0) {
            return;
        }

        // Pull the required amount from the fee token's staking pool and approve them to the cashier
        IStaking staking = stakingFactory.getOrCreateInstance(token);
        _lockBalance(staking, _submitter, amount);
        _slashBalance(staking, _submitter, address(this), amount);
        _approveFor(token, address(aragonAppFeesCashier), amount);

        // Pay fees
        aragonAppFeesCashier.payAppFees(appId, abi.encodePacked(_actionId));
    }

    /**
    * @dev Close an action
    *      This function does not perform any checks about the action status; callers must have already ensured the action can be closed.
    * @param _actionId Identification number of the action being closed
    * @param _action Action instance being closed
    */
    function _unsafeCloseAction(uint256 _actionId, Action storage _action) internal {
        _action.closed = true;
        emit ActionClosed(_actionId);
    }

    /**
    * @dev Challenge an action
    * @param _actionId Identification number of the action being challenged
    * @param _action Action instance being challenged
    * @param _challenger Address challenging the action
    * @param _requirement Collateral requirement instance applicable to the challenge
    * @param _settlementOffer Amount of collateral tokens the challenger would accept for resolving the dispute without involving the arbitrator
    * @param _finishedSubmittingEvidence Whether the challenger is finished submitting evidence with the challenge context
    * @param _context Link to a human-readable context for the challenge
    * @return Identification number for the created challenge
    */
    function _createChallenge(
        uint256 _actionId,
        Action storage _action,
        address _challenger,
        CollateralRequirement storage _requirement,
        uint256 _settlementOffer,
        bool _finishedSubmittingEvidence,
        bytes _context
    )
        internal
        returns (uint256)
    {
        // Store challenge
        uint256 challengeId = nextChallengeId++;
        Challenge storage challenge = challenges[challengeId];
        challenge.actionId = _actionId;
        challenge.challenger = _challenger;
        challenge.endDate = getTimestamp64().add(_requirement.challengeDuration);
        challenge.context = _context;
        challenge.settlementOffer = _settlementOffer;
        challenge.challengerFinishedEvidence = _finishedSubmittingEvidence;

        // Pull challenge collateral
        _depositFrom(_requirement.token, _challenger, _requirement.challengeAmount);

        // Pull pre-paid arbitrator fees from challenger
        IArbitrator arbitrator = _getArbitratorFor(_action);
        (, ERC20 feeToken, uint256 feeAmount) = arbitrator.getDisputeFees();
        challenge.challengerArbitratorFees.token = feeToken;
        challenge.challengerArbitratorFees.amount = feeAmount;
        _depositFrom(feeToken, _challenger, feeAmount);

        return challengeId;
    }

    /**
    * @dev Dispute an action
    * @param _action Action instance being disputed
    * @param _challenge Currently open challenge instance for the action
    * @return _arbitrator Address of the IArbitrator applicable to the action
    * @return _metadata Metadata content to be used for the dispute
    * @return Identification number of the dispute created on the arbitrator
    */
    function _createDispute(Action storage _action, Challenge storage _challenge, IArbitrator _arbitrator, bytes memory _metadata)
        internal
        returns (uint256)
    {
        // Pull arbitration fees from submitter
        (address disputeFeeRecipient, ERC20 feeToken, uint256 feeAmount) = _arbitrator.getDisputeFees();
        _challenge.submitterArbitratorFees.token = feeToken;
        _challenge.submitterArbitratorFees.amount = feeAmount;

        address submitter = _action.submitter;
        _depositFrom(feeToken, submitter, feeAmount);

        // Create dispute. The arbitrator should pull its arbitration fees (if any) from this Agreement on `createDispute()`.
        _approveFor(feeToken, disputeFeeRecipient, feeAmount);
        uint256 disputeId = _arbitrator.createDispute(DISPUTES_POSSIBLE_OUTCOMES, _metadata);

        return disputeId;
    }

    /**
    * @dev Submit evidence for a dispute on an arbitrator
    * @param _arbitrator Arbitrator to submit evidence on
    * @param _disputeId Identification number of the dispute on the arbitrator
    * @param _submitter Address submitting the evidence
    * @param _evidence Evidence data to be submitted
    * @param _finished Whether the submitter is now finished submitting evidence
    */
    function _submitEvidence(IArbitrator _arbitrator, uint256 _disputeId, address _submitter, bytes _evidence, bool _finished) internal {
        if (_evidence.length > 0) {
            emit EvidenceSubmitted(_arbitrator, _disputeId, _submitter, _evidence, _finished);
        }
    }

    /**
    * @dev Reject an action ("accept challenge")
    * @param _actionId Identification number of the action to be rejected
    * @param _action Action instance to be rejected
    * @param _challengeId Current challenge identification number for the action
    * @param _challenge Current challenge instance for the action
    */
    function _rejectAction(uint256 _actionId, Action storage _action, uint256 _challengeId, Challenge storage _challenge) internal {
        _challenge.state = ChallengeState.Accepted;

        address challenger = _challenge.challenger;
        (DisputableAragonApp disputable, CollateralRequirement storage requirement) = _getDisputableInfoFor(_action);

        // Transfer action collateral, challenge collateral, and challenger arbitrator fees to the challenger
        _slashBalance(requirement.staking, _action.submitter, challenger, requirement.actionAmount);
        _transferTo(requirement.token, challenger, requirement.challengeAmount);
        _transferTo(_challenge.challengerArbitratorFees.token, challenger, _challenge.challengerArbitratorFees.amount);
        disputable.onDisputableActionRejected(_action.disputableActionId);
        emit ActionRejected(_actionId, _challengeId);
        _unsafeCloseAction(_actionId, _action);
    }

    /**
    * @dev Accept an action ("reject challenge")
    * @param _actionId Identification number of the action to be accepted
    * @param _action Action instance to be accepted
    * @param _challengeId Current challenge identification number for the action
    * @param _challenge Current challenge instance for the action
    */
    function _acceptAction(uint256 _actionId, Action storage _action, uint256 _challengeId, Challenge storage _challenge) internal {
        _challenge.state = ChallengeState.Rejected;

        address submitter = _action.submitter;
        (DisputableAragonApp disputable, CollateralRequirement storage requirement) = _getDisputableInfoFor(_action);

        // Transfer challenge collateral and challenger arbitrator fees to the submitter
        _transferTo(requirement.token, submitter, requirement.challengeAmount);
        _transferTo(_challenge.challengerArbitratorFees.token, submitter, _challenge.challengerArbitratorFees.amount);
        disputable.onDisputableActionAllowed(_action.disputableActionId);
        emit ActionAccepted(_actionId, _challengeId);

        // Note that the action still continues after this ruling and will be closed at a future date
    }

    /**
    * @dev Void an action ("void challenge")
    * @param _actionId Identification number of the action to be voided
    * @param _action Action instance to be voided
    * @param _challengeId Current challenge identification number for the action
    * @param _challenge Current challenge instance for the action
    */
    function _voidAction(uint256 _actionId, Action storage _action, uint256 _challengeId, Challenge storage _challenge) internal {
        _challenge.state = ChallengeState.Voided;

        (DisputableAragonApp disputable, CollateralRequirement storage requirement) = _getDisputableInfoFor(_action);
        address challenger = _challenge.challenger;

        // Return challenge collateral to the challenger, and split the challenger arbitrator fees between the challenger and the submitter
        _transferTo(requirement.token, challenger, requirement.challengeAmount);
        ERC20 challengerArbitratorFeesToken = _challenge.challengerArbitratorFees.token;
        uint256 challengerArbitratorFeesAmount = _challenge.challengerArbitratorFees.amount;
        uint256 submitterPayBack = challengerArbitratorFeesAmount / 2;
        // No need for Safemath because of previous computation
        uint256 challengerPayBack = challengerArbitratorFeesAmount - submitterPayBack;
        _transferTo(challengerArbitratorFeesToken, _action.submitter, submitterPayBack);
        _transferTo(challengerArbitratorFeesToken, challenger, challengerPayBack);
        disputable.onDisputableActionVoided(_action.disputableActionId);
        emit ActionVoided(_actionId, _challengeId);

        // Note that the action still continues after this ruling and will be closed at a future date
    }

    /**
    * @dev Lock some tokens in the staking pool for a user
    * @param _staking Staking pool for the ERC20 token to be locked
    * @param _user Address of the user to lock tokens for
    * @param _amount Amount of collateral tokens to be locked
    */
    function _lockBalance(IStaking _staking, address _user, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        _staking.lock(_user, address(this), _amount);
    }

    /**
    * @dev Unlock some tokens in the staking pool for a user
    * @param _staking Staking pool for the ERC20 token to be unlocked
    * @param _user Address of the user to unlock tokens for
    * @param _amount Amount of collateral tokens to be unlocked
    */
    function _unlockBalance(IStaking _staking, address _user, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        _staking.unlock(_user, address(this), _amount);
    }

    /**
    * @dev Slash some tokens in the staking pool from a user to a recipient
    * @param _staking Staking pool for the ERC20 token to be slashed
    * @param _user Address of the user to be slashed
    * @param _recipient Address receiving the slashed tokens
    * @param _amount Amount of collateral tokens to be slashed
    */
    function _slashBalance(IStaking _staking, address _user, address _recipient, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        _staking.slashAndUnstake(_user, _recipient, _amount);
    }

    /**
    * @dev Transfer tokens to an address
    * @param _token ERC20 token to be transferred
    * @param _to Address receiving the tokens
    * @param _amount Amount of tokens to be transferred
    */
    function _transferTo(ERC20 _token, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            require(_token.safeTransfer(_to, _amount), ERROR_TOKEN_TRANSFER_FAILED);
        }
    }

    /**
    * @dev Deposit tokens from an address to this Agreement
    * @param _token ERC20 token to be transferred
    * @param _from Address transferring the tokens
    * @param _amount Amount of tokens to be transferred
    */
    function _depositFrom(ERC20 _token, address _from, uint256 _amount) internal {
        if (_amount > 0) {
            require(_token.safeTransferFrom(_from, address(this), _amount), ERROR_TOKEN_DEPOSIT_FAILED);
        }
    }

    /**
    * @dev Approve tokens held by this Agreement to another address
    * @param _token ERC20 token used for the arbitration fees
    * @param _to Address to be approved
    * @param _amount Amount of `_arbitrationFeeToken` tokens to be approved
    */
    function _approveFor(ERC20 _token, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            // To be safe, we first set the allowance to zero in case there is a remaining approval for the arbitrator.
            // This is not strictly necessary for ERC20s, but some tokens, e.g. MiniMe (ANT and ANJ),
            // revert on an approval if an outstanding allowance exists
            require(_token.safeApprove(_to, 0), ERROR_TOKEN_APPROVAL_FAILED);
            require(_token.safeApprove(_to, _amount), ERROR_TOKEN_APPROVAL_FAILED);
        }
    }

    /**
    * @dev Fetch an agreement setting instance by identification number
    * @param _settingId Identification number of the agreement setting
    * @return Agreement setting instance associated to the given identification number
    */
    function _getSetting(uint256 _settingId) internal view returns (Setting storage) {
        require(_settingId > 0 && _settingId < nextSettingId, ERROR_SETTING_DOES_NOT_EXIST);
        return settings[_settingId];
    }

    /**
    * @dev Tell the identification number of the current agreement setting
    * @return Identification number of the current agreement setting
    */
    function _getCurrentSettingId() internal view returns (uint256) {
        // An initial setting is created during initialization, thus after initialization, length will be always greater than 0
        return nextSettingId == 0 ? 0 : nextSettingId - 1;
    }

    /**
    * @dev Tell the arbitrator to be used for an action
    * @param _action Action instance
    * @return arbitrator Address of the IArbitrator that will be used to resolve disputes
    */
    function _getArbitratorFor(Action storage _action) internal view returns (IArbitrator) {
        Setting storage setting = _getSetting(_action.settingId);
        return setting.arbitrator;
    }

    /**
    * @dev Tell the app fees cashier instance associated to an arbitrator
    * @param _arbitrator Arbitrator querying the app fees cashier for
    * @return Address of the app fees cashier associated to the arbitrator
    */
    function _getArbitratorFeesCashier(IArbitrator _arbitrator) internal view returns (IAragonAppFeesCashier) {
        (address cashier,,) = _arbitrator.getSubscriptionFees(address(this));
        return IAragonAppFeesCashier(cashier);
    }

    /**
    * @dev Ensure a Disputable app is activate
    * @param _disputableInfo Disputable info of the app
    */
    function _ensureActiveDisputable(DisputableInfo storage _disputableInfo) internal view {
        require(_disputableInfo.activated, ERROR_DISPUTABLE_NOT_ACTIVE);
    }

    /**
    * @dev Ensure a Disputable app is inactive
    * @param _disputableInfo Disputable info of the app
    */
    function _ensureInactiveDisputable(DisputableInfo storage _disputableInfo) internal view {
        require(!_disputableInfo.activated, ERROR_DISPUTABLE_ALREADY_ACTIVE);
    }

    /**
    * @dev Tell the disputable-related information about an action
    * @param _action Action instance
    * @return disputable Address of the Disputable app associated to the action
    * @return requirement Collateral requirement instance applicable to the action
    */
    function _getDisputableInfoFor(Action storage _action)
        internal
        view
        returns (DisputableAragonApp disputable, CollateralRequirement storage requirement)
    {
        disputable = _action.disputable;
        DisputableInfo storage disputableInfo = disputableInfos[address(disputable)];
        requirement = _getCollateralRequirement(disputableInfo, _action.collateralRequirementId);
    }

    /**
    * @dev Fetch the collateral requirement instance by identification number for a Disputable app
    * @param _disputableInfo Disputable info instance
    * @param _collateralRequirementId Identification number of the collateral requirement
    * @return Collateral requirement instance associated to the given identification number
    */
    function _getCollateralRequirement(DisputableInfo storage _disputableInfo, uint256 _collateralRequirementId)
        internal
        view
        returns (CollateralRequirement storage)
    {
        bool exists = _collateralRequirementId > 0 && _collateralRequirementId < _disputableInfo.nextCollateralRequirementsId;
        require(exists, ERROR_COLLATERAL_REQUIREMENT_DOES_NOT_EXIST);
        return _disputableInfo.collateralRequirements[_collateralRequirementId];
    }

    /**
    * @dev Tell the information related to a signer
    * @param _signer Address of signer
    * @return lastSettingIdSigned Identification number of the last agreement setting signed by the signer
    * @return mustSign Whether the signer needs to sign the current agreement setting before submitting an action
    */
    function _getSigner(address _signer) internal view returns (uint256 lastSettingIdSigned, bool mustSign) {
        lastSettingIdSigned = lastSettingSignedBy[_signer];
        mustSign = lastSettingIdSigned < _getCurrentSettingId();
    }

    /**
    * @dev Fetch an action instance by identification number
    * @param _actionId Identification number of the action
    * @return Action instance associated to the given identification number
    */
    function _getAction(uint256 _actionId) internal view returns (Action storage) {
        require(_actionId > 0 && _actionId < nextActionId, ERROR_ACTION_DOES_NOT_EXIST);
        return actions[_actionId];
    }

    /**
    * @dev Fetch a challenge instance by identification number
    * @param _challengeId Identification number of the challenge
    * @return Challenge instance associated to the given identification number
    */
    function _getChallenge(uint256 _challengeId) internal view returns (Challenge storage) {
        require(_existChallenge(_challengeId), ERROR_CHALLENGE_DOES_NOT_EXIST);
        return challenges[_challengeId];
    }

    /**
    * @dev Fetch an action instance along with its most recent challenge by identification number
    * @param _actionId Identification number of the action
    * @return action Action instance associated to the given identification number
    * @return challenge Most recent challenge instance associated to the action
    * @return challengeId Identification number of the most recent challenge associated to the action
    */
    function _getChallengedAction(uint256 _actionId)
        internal
        view
        returns (Action storage action, Challenge storage challenge, uint256 challengeId)
    {
        action = _getAction(_actionId);
        challengeId = action.lastChallengeId;
        challenge = _getChallenge(challengeId);
    }

    /**
    * @dev Fetch a dispute's associated action and challenge instance
    * @param _disputeId Identification number of the dispute on the arbitrator
    * @return actionId Identification number of the action associated to the dispute
    * @return action Action instance associated to the dispute
    * @return challengeId Identification number of the challenge associated to the dispute
    * @return challenge Current challenge instance associated to the dispute
    */
    function _getDisputedAction(uint256 _disputeId)
        internal
        view
        returns (uint256 actionId, Action storage action, uint256 challengeId, Challenge storage challenge)
    {
        challengeId = challengeByDispute[_disputeId];
        challenge = _getChallenge(challengeId);
        actionId = challenge.actionId;
        action = _getAction(actionId);
    }

    /**
    * @dev Tell whether a challenge exists
    * @param _challengeId Identification number of the challenge
    * @return True if the requested challenge exists, false otherwise
    */
    function _existChallenge(uint256 _challengeId) internal view returns (bool) {
        return _challengeId > 0 && _challengeId < nextChallengeId;
    }

    /**
    * @dev Tell whether an action can be manually closed
    * @param _action Action instance
    * @return True if the action can be closed, false otherwise
    */
    function _canClose(Action storage _action) internal view returns (bool) {
        if (!_canProceed(_action)) {
            return false;
        }

        DisputableAragonApp disputable = _action.disputable;
        // Assume that the Disputable app does not need to be checked if it's the one asking us to close an action
        return DisputableAragonApp(msg.sender) == disputable || disputable.canClose(_action.disputableActionId);
    }

    /**
    * @dev Tell whether an action can be challenged
    * @param _action Action instance
    * @return True if the action can be challenged, false otherwise
    */
    function _canChallenge(Action storage _action) internal view returns (bool) {
        return _canProceed(_action) && _action.disputable.canChallenge(_action.disputableActionId);
    }

    /**
    * @dev Tell whether an action can proceed to another state.
    * @dev An action can proceed if it is:
    *       - Not closed
    *       - Not currently challenged or disputed, and
    *       - Not already settled or had a dispute rule in favour of the challenger (the action will have been closed automatically)
    * @param _action Action instance
    * @return True if the action can proceed, false otherwise
    */
    function _canProceed(Action storage _action) internal view returns (bool) {
        // If the action was already closed, return false
        if (_action.closed) {
            return false;
        }

        uint256 challengeId = _action.lastChallengeId;

        // If the action has not been challenged yet, return true
        if (!_existChallenge(challengeId)) {
            return true;
        }

        // If the action was previously challenged but ruled in favour of the submitter or voided, return true
        Challenge storage challenge = challenges[challengeId];
        ChallengeState state = challenge.state;
        return state == ChallengeState.Rejected || state == ChallengeState.Voided;
    }

    /**
    * @dev Tell whether a challenge can be settled
    * @param _challenge Challenge instance
    * @return True if the challenge can be settled, false otherwise
    */
    function _canSettle(Challenge storage _challenge) internal view returns (bool) {
        return _isWaitingChallengeAnswer(_challenge);
    }

    /**
    * @dev Tell whether a challenge settlement can be claimed
    * @param _challenge Challenge instance
    * @return True if the challenge settlement can be claimed, false otherwise
    */
    function _canClaimSettlement(Challenge storage _challenge) internal view returns (bool) {
        return _isWaitingChallengeAnswer(_challenge) && getTimestamp() >= uint256(_challenge.endDate);
    }

    /**
    * @dev Tell whether a challenge can be disputed
    * @param _challenge Challenge instance
    * @return True if the challenge can be disputed, false otherwise
    */
    function _canDispute(Challenge storage _challenge) internal view returns (bool) {
        return _isWaitingChallengeAnswer(_challenge) && uint256(_challenge.endDate) > getTimestamp();
    }

    /**
    * @dev Tell whether a challenge is waiting to be answered
    * @param _challenge Challenge instance
    * @return True if the challenge is waiting to be answered, false otherwise
    */
    function _isWaitingChallengeAnswer(Challenge storage _challenge) internal view returns (bool) {
        return _challenge.state == ChallengeState.Waiting;
    }

    /**
    * @dev Tell whether a challenge is disputed
    * @param _challenge Challenge instance
    * @return True if the challenge is disputed, false otherwise
    */
    function _isDisputed(Challenge storage _challenge) internal view returns (bool) {
        return _challenge.state == ChallengeState.Disputed;
    }

    /**
    * @dev Tell whether an address has permission to challenge actions on a specific Disputable app
    * @param _disputable Address of the Disputable app
    * @param _challenger Address of the challenger
    * @return True if the challenger can challenge actions on the Disputable app, false otherwise
    */
    function _canPerformChallenge(DisputableAragonApp _disputable, address _challenger) internal view returns (bool) {
        IKernel currentKernel = kernel();
        if (currentKernel == IKernel(0)) {
            return false;
        }

        // To make sure the challenger address is reachable by ACL oracles, we need to pass it as the first argument.
        // Permissions set with ANY_ENTITY do not provide the original sender's address into the ACL Oracle's `grantee` argument.
        bytes memory params = ConversionHelpers.dangerouslyCastUintArrayToBytes(arr(_challenger));
        return currentKernel.hasPermission(_challenger, address(_disputable), CHALLENGE_ROLE, params);
    }
}