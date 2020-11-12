/**
 *Submitted for verification at Etherscan.io on 2020-02-11
*/

// File: @aragon/os/contracts/common/EtherTokenConstant.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

// File: @aragon/apps-agent/contracts/standards/ERC1271.sol

pragma solidity 0.4.24;

// ERC1271 on Feb 12th, 2019: https://github.com/ethereum/EIPs/blob/a97dc434930d0ccc4461c97d8c7a920dc585adf2/EIPS/eip-1271.md
// Using `isValidSignature(bytes32,bytes)` even though the standard still hasn't been modified
// Rationale: https://github.com/ethereum/EIPs/issues/1271#issuecomment-462719728


contract ERC1271 {
    bytes4 constant public ERC1271_INTERFACE_ID = 0xfb855dc9; // this.isValidSignature.selector

    bytes4 constant public ERC1271_RETURN_VALID_SIGNATURE =   0x20c13b0b; // TODO: Likely needs to be updated
    bytes4 constant public ERC1271_RETURN_INVALID_SIGNATURE = 0x00000000;

    /**
    * @dev Function must be implemented by deriving contract
    * @param _hash Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    * @return A bytes4 magic value 0x20c13b0b if the signature check passes, 0x00000000 if not
    *
    * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    * MUST allow external calls
    */
    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4);

    function returnIsValidSignatureMagicNumber(bool isValid) internal pure returns (bytes4) {
        return isValid ? ERC1271_RETURN_VALID_SIGNATURE : ERC1271_RETURN_INVALID_SIGNATURE;
    }
}


contract ERC1271Bytes is ERC1271 {
    /**
    * @dev Default behavior of `isValidSignature(bytes,bytes)`, can be overloaded for custom validation
    * @param _data Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    * @return A bytes4 magic value 0x20c13b0b if the signature check passes, 0x00000000 if not
    *
    * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    * MUST allow external calls
    */
    function isValidSignature(bytes _data, bytes _signature) public view returns (bytes4) {
        return isValidSignature(keccak256(_data), _signature);
    }
}

// File: @aragon/apps-agent/contracts/SignatureValidator.sol

pragma solidity 0.4.24;

// Inspired by https://github.com/horizon-games/multi-token-standard/blob/319740cf2a78b8816269ae49a09c537b3fd7303b/contracts/utils/SignatureValidator.sol
// This should probably be moved into aOS: https://github.com/aragon/aragonOS/pull/442



library SignatureValidator {
    enum SignatureMode {
        Invalid, // 0x00
        EIP712,  // 0x01
        EthSign, // 0x02
        ERC1271, // 0x03
        NMode    // 0x04, to check if mode is specified, leave at the end
    }

    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 public constant ERC1271_RETURN_VALID_SIGNATURE = 0x20c13b0b;
    uint256 internal constant ERC1271_ISVALIDSIG_MAX_GAS = 250000;

    string private constant ERROR_INVALID_LENGTH_POP_BYTE = "SIGVAL_INVALID_LENGTH_POP_BYTE";

    /// @dev Validates that a hash was signed by a specified signer.
    /// @param hash Hash which was signed.
    /// @param signer Address of the signer.
    /// @param signature ECDSA signature along with the mode (0 = Invalid, 1 = EIP712, 2 = EthSign, 3 = ERC1271) {mode}{r}{s}{v}.
    /// @return Returns whether signature is from a specified user.
    function isValidSignature(bytes32 hash, address signer, bytes signature) internal view returns (bool) {
        if (signature.length == 0) {
            return false;
        }

        uint8 modeByte = uint8(signature[0]);
        if (modeByte >= uint8(SignatureMode.NMode)) {
            return false;
        }
        SignatureMode mode = SignatureMode(modeByte);

        if (mode == SignatureMode.EIP712) {
            return ecVerify(hash, signer, signature);
        } else if (mode == SignatureMode.EthSign) {
            return ecVerify(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                signer,
                signature
            );
        } else if (mode == SignatureMode.ERC1271) {
            // Pop the mode byte before sending it down the validation chain
            return safeIsValidSignature(signer, hash, popFirstByte(signature));
        } else {
            return false;
        }
    }

    function ecVerify(bytes32 hash, address signer, bytes memory signature) private pure returns (bool) {
        (bool badSig, bytes32 r, bytes32 s, uint8 v) = unpackEcSig(signature);

        if (badSig) {
            return false;
        }

        return signer == ecrecover(hash, v, r, s);
    }

    function unpackEcSig(bytes memory signature) private pure returns (bool badSig, bytes32 r, bytes32 s, uint8 v) {
        if (signature.length != 66) {
            badSig = true;
            return;
        }

        v = uint8(signature[65]);
        assembly {
            r := mload(add(signature, 33))
            s := mload(add(signature, 65))
        }

        // Allow signature version to be 0 or 1
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            badSig = true;
        }
    }

    function popFirstByte(bytes memory input) private pure returns (bytes memory output) {
        uint256 inputLength = input.length;
        require(inputLength > 0, ERROR_INVALID_LENGTH_POP_BYTE);

        output = new bytes(inputLength - 1);

        if (output.length == 0) {
            return output;
        }

        uint256 inputPointer;
        uint256 outputPointer;
        assembly {
            inputPointer := add(input, 0x21)
            outputPointer := add(output, 0x20)
        }
        memcpy(outputPointer, inputPointer, output.length);
    }

    function safeIsValidSignature(address validator, bytes32 hash, bytes memory signature) private view returns (bool) {
        bytes memory data = abi.encodeWithSelector(ERC1271(validator).isValidSignature.selector, hash, signature);
        bytes4 erc1271Return = safeBytes4StaticCall(validator, data, ERC1271_ISVALIDSIG_MAX_GAS);
        return erc1271Return == ERC1271_RETURN_VALID_SIGNATURE;
    }

    function safeBytes4StaticCall(address target, bytes data, uint256 maxGas) private view returns (bytes4 ret) {
        uint256 gasLeft = gasleft();

        uint256 callGas = gasLeft > maxGas ? maxGas : gasLeft;
        bool ok;
        assembly {
            ok := staticcall(callGas, target, add(data, 0x20), mload(data), 0, 0)
        }

        if (!ok) {
            return;
        }

        uint256 size;
        assembly { size := returndatasize }
        if (size != 32) {
            return;
        }

        assembly {
            let ptr := mload(0x40)       // get next free memory ptr
            returndatacopy(ptr, 0, size) // copy return from above `staticcall`
            ret := mload(ptr)            // read data at ptr and set it to be returned
        }

        return ret;
    }

    // From: https://github.com/Arachnid/solidity-stringutils/blob/01e955c1d6/src/strings.sol
    function memcpy(uint256 dest, uint256 src, uint256 len) private pure {
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

// File: @aragon/apps-agent/contracts/standards/IERC165.sol

pragma solidity 0.4.24;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}

// File: @aragon/os/contracts/common/UnstructuredStorage.sol

/*
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/acl/IACL.sol

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/apps/AppStorage.sol

/*
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/acl/ACLSyntaxSugar.sol

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/common/IsContract.sol

/*
 * SPDX-License-Identitifer:    MIT
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
}

// File: @aragon/os/contracts/common/VaultRecoverable.sol

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

// File: @aragon/os/contracts/evmscript/IEVMScriptRegistry.sol

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/apps/AragonApp.sol

/*
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/common/DepositableStorage.sol

pragma solidity 0.4.24;



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

// File: @aragon/apps-vault/contracts/Vault.sol

pragma solidity 0.4.24;







contract Vault is EtherTokenConstant, AragonApp, DepositableStorage {
    using SafeERC20 for ERC20;

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    string private constant ERROR_DATA_NON_ZERO = "VAULT_DATA_NON_ZERO";
    string private constant ERROR_NOT_DEPOSITABLE = "VAULT_NOT_DEPOSITABLE";
    string private constant ERROR_DEPOSIT_VALUE_ZERO = "VAULT_DEPOSIT_VALUE_ZERO";
    string private constant ERROR_TRANSFER_VALUE_ZERO = "VAULT_TRANSFER_VALUE_ZERO";
    string private constant ERROR_SEND_REVERTED = "VAULT_SEND_REVERTED";
    string private constant ERROR_VALUE_MISMATCH = "VAULT_VALUE_MISMATCH";
    string private constant ERROR_TOKEN_TRANSFER_FROM_REVERTED = "VAULT_TOKEN_TRANSFER_FROM_REVERT";
    string private constant ERROR_TOKEN_TRANSFER_REVERTED = "VAULT_TOKEN_TRANSFER_REVERTED";

    event VaultTransfer(address indexed token, address indexed to, uint256 amount);
    event VaultDeposit(address indexed token, address indexed sender, uint256 amount);

    /**
    * @dev On a normal send() or transfer() this fallback is never executed as it will be
    *      intercepted by the Proxy (see aragonOS#281)
    */
    function () external payable isInitialized {
        require(msg.data.length == 0, ERROR_DATA_NON_ZERO);
        _deposit(ETH, msg.value);
    }

    /**
    * @notice Initialize Vault app
    * @dev As an AragonApp it needs to be initialized in order for roles (`auth` and `authP`) to work
    */
    function initialize() external onlyInit {
        initialized();
        setDepositable(true);
    }

    /**
    * @notice Deposit `_value` `_token` to the vault
    * @param _token Address of the token being transferred
    * @param _value Amount of tokens being transferred
    */
    function deposit(address _token, uint256 _value) external payable isInitialized {
        _deposit(_token, _value);
    }

    /**
    * @notice Transfer `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    /* solium-disable-next-line function-order */
    function transfer(address _token, address _to, uint256 _value)
        external
        authP(TRANSFER_ROLE, arr(_token, _to, _value))
    {
        require(_value > 0, ERROR_TRANSFER_VALUE_ZERO);

        if (_token == ETH) {
            require(_to.send(_value), ERROR_SEND_REVERTED);
        } else {
            require(ERC20(_token).safeTransfer(_to, _value), ERROR_TOKEN_TRANSFER_REVERTED);
        }

        emit VaultTransfer(_token, _to, _value);
    }

    function balance(address _token) public view returns (uint256) {
        if (_token == ETH) {
            return address(this).balance;
        } else {
            return ERC20(_token).staticBalanceOf(address(this));
        }
    }

    /**
    * @dev Disable recovery escape hatch, as it could be used
    *      maliciously to transfer funds away from the vault
    */
    function allowRecoverability(address) public view returns (bool) {
        return false;
    }

    function _deposit(address _token, uint256 _value) internal {
        require(isDepositable(), ERROR_NOT_DEPOSITABLE);
        require(_value > 0, ERROR_DEPOSIT_VALUE_ZERO);

        if (_token == ETH) {
            // Deposit is implicit in this case
            require(msg.value == _value, ERROR_VALUE_MISMATCH);
        } else {
            require(
                ERC20(_token).safeTransferFrom(msg.sender, address(this), _value),
                ERROR_TOKEN_TRANSFER_FROM_REVERTED
            );
        }

        emit VaultDeposit(_token, msg.sender, _value);
    }
}

// File: @aragon/os/contracts/common/IForwarder.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IForwarder {
    function isForwarder() external pure returns (bool);

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function canForward(address sender, bytes evmCallScript) public view returns (bool);

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function forward(bytes evmCallScript) public;
}

// File: @aragon/apps-agent/contracts/Agent.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;







contract Agent is IERC165, ERC1271Bytes, IForwarder, IsContract, Vault {
    /* Hardcoded constants to save gas
    bytes32 public constant EXECUTE_ROLE = keccak256("EXECUTE_ROLE");
    bytes32 public constant SAFE_EXECUTE_ROLE = keccak256("SAFE_EXECUTE_ROLE");
    bytes32 public constant ADD_PROTECTED_TOKEN_ROLE = keccak256("ADD_PROTECTED_TOKEN_ROLE");
    bytes32 public constant REMOVE_PROTECTED_TOKEN_ROLE = keccak256("REMOVE_PROTECTED_TOKEN_ROLE");
    bytes32 public constant ADD_PRESIGNED_HASH_ROLE = keccak256("ADD_PRESIGNED_HASH_ROLE");
    bytes32 public constant DESIGNATE_SIGNER_ROLE = keccak256("DESIGNATE_SIGNER_ROLE");
    bytes32 public constant RUN_SCRIPT_ROLE = keccak256("RUN_SCRIPT_ROLE");
    */

    bytes32 public constant EXECUTE_ROLE = 0xcebf517aa4440d1d125e0355aae64401211d0848a23c02cc5d29a14822580ba4;
    bytes32 public constant SAFE_EXECUTE_ROLE = 0x0a1ad7b87f5846153c6d5a1f761d71c7d0cfd122384f56066cd33239b7933694;
    bytes32 public constant ADD_PROTECTED_TOKEN_ROLE = 0x6eb2a499556bfa2872f5aa15812b956cc4a71b4d64eb3553f7073c7e41415aaa;
    bytes32 public constant REMOVE_PROTECTED_TOKEN_ROLE = 0x71eee93d500f6f065e38b27d242a756466a00a52a1dbcd6b4260f01a8640402a;
    bytes32 public constant ADD_PRESIGNED_HASH_ROLE = 0x0b29780bb523a130b3b01f231ef49ed2fa2781645591a0b0a44ca98f15a5994c;
    bytes32 public constant DESIGNATE_SIGNER_ROLE = 0x23ce341656c3f14df6692eebd4757791e33662b7dcf9970c8308303da5472b7c;
    bytes32 public constant RUN_SCRIPT_ROLE = 0xb421f7ad7646747f3051c50c0b8e2377839296cd4973e27f63821d73e390338f;

    uint256 public constant PROTECTED_TOKENS_CAP = 10;

    bytes4 private constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    string private constant ERROR_TARGET_PROTECTED = "AGENT_TARGET_PROTECTED";
    string private constant ERROR_PROTECTED_TOKENS_MODIFIED = "AGENT_PROTECTED_TOKENS_MODIFIED";
    string private constant ERROR_PROTECTED_BALANCE_LOWERED = "AGENT_PROTECTED_BALANCE_LOWERED";
    string private constant ERROR_TOKENS_CAP_REACHED = "AGENT_TOKENS_CAP_REACHED";
    string private constant ERROR_TOKEN_NOT_ERC20 = "AGENT_TOKEN_NOT_ERC20";
    string private constant ERROR_TOKEN_ALREADY_PROTECTED = "AGENT_TOKEN_ALREADY_PROTECTED";
    string private constant ERROR_TOKEN_NOT_PROTECTED = "AGENT_TOKEN_NOT_PROTECTED";
    string private constant ERROR_DESIGNATED_TO_SELF = "AGENT_DESIGNATED_TO_SELF";
    string private constant ERROR_CAN_NOT_FORWARD = "AGENT_CAN_NOT_FORWARD";

    mapping (bytes32 => bool) public isPresigned;
    address public designatedSigner;
    address[] public protectedTokens;

    event SafeExecute(address indexed sender, address indexed target, bytes data);
    event Execute(address indexed sender, address indexed target, uint256 ethValue, bytes data);
    event AddProtectedToken(address indexed token);
    event RemoveProtectedToken(address indexed token);
    event PresignHash(address indexed sender, bytes32 indexed hash);
    event SetDesignatedSigner(address indexed sender, address indexed oldSigner, address indexed newSigner);

    /**
    * @notice Execute '`@radspec(_target, _data)`' on `_target``_ethValue == 0 ? '' : ' (Sending' + @tokenAmount(0x0000000000000000000000000000000000000000, _ethValue) + ')'`
    * @param _target Address where the action is being executed
    * @param _ethValue Amount of ETH from the contract that is sent with the action
    * @param _data Calldata for the action
    * @return Exits call frame forwarding the return data of the executed call (either error or success data)
    */
    function execute(address _target, uint256 _ethValue, bytes _data)
        external // This function MUST always be external as the function performs a low level return, exiting the Agent app execution context
        authP(EXECUTE_ROLE, arr(_target, _ethValue, uint256(_getSig(_data)))) // bytes4 casted as uint256 sets the bytes as the LSBs
    {
        bool result = _target.call.value(_ethValue)(_data);

        if (result) {
            emit Execute(msg.sender, _target, _ethValue, _data);
        }

        assembly {
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, returndatasize) }
            default { return(ptr, returndatasize) }
        }
    }

    /**
    * @notice Execute '`@radspec(_target, _data)`' on `_target` ensuring that protected tokens can't be spent
    * @param _target Address where the action is being executed
    * @param _data Calldata for the action
    * @return Exits call frame forwarding the return data of the executed call (either error or success data)
    */
    function safeExecute(address _target, bytes _data)
        external // This function MUST always be external as the function performs a low level return, exiting the Agent app execution context
        authP(SAFE_EXECUTE_ROLE, arr(_target, uint256(_getSig(_data)))) // bytes4 casted as uint256 sets the bytes as the LSBs
    {
        uint256 protectedTokensLength = protectedTokens.length;
        address[] memory protectedTokens_ = new address[](protectedTokensLength);
        uint256[] memory balances = new uint256[](protectedTokensLength);

        for (uint256 i = 0; i < protectedTokensLength; i++) {
            address token = protectedTokens[i];
            require(_target != token, ERROR_TARGET_PROTECTED);
            // we copy the protected tokens array to check whether the storage array has been modified during the underlying call
            protectedTokens_[i] = token;
            // we copy the balances to check whether they have been modified during the underlying call
            balances[i] = balance(token);
        }

        bool result = _target.call(_data);

        bytes32 ptr;
        uint256 size;
        assembly {
            size := returndatasize
            ptr := mload(0x40)
            mstore(0x40, add(ptr, returndatasize))
            returndatacopy(ptr, 0, returndatasize)
        }

        if (result) {
            // if the underlying call has succeeded, we check that the protected tokens
            // and their balances have not been modified and return the call's return data
            require(protectedTokens.length == protectedTokensLength, ERROR_PROTECTED_TOKENS_MODIFIED);
            for (uint256 j = 0; j < protectedTokensLength; j++) {
                require(protectedTokens[j] == protectedTokens_[j], ERROR_PROTECTED_TOKENS_MODIFIED);
                require(balance(protectedTokens[j]) >= balances[j], ERROR_PROTECTED_BALANCE_LOWERED);
            }

            emit SafeExecute(msg.sender, _target, _data);

            assembly {
                return(ptr, size)
            }
        } else {
            // if the underlying call has failed, we revert and forward returned error data
            assembly {
                revert(ptr, size)
            }
        }
    }

    /**
    * @notice Add `_token.symbol(): string` to the list of protected tokens
    * @param _token Address of the token to be protected
    */
    function addProtectedToken(address _token) external authP(ADD_PROTECTED_TOKEN_ROLE, arr(_token)) {
        require(protectedTokens.length < PROTECTED_TOKENS_CAP, ERROR_TOKENS_CAP_REACHED);
        require(_isERC20(_token), ERROR_TOKEN_NOT_ERC20);
        require(!_tokenIsProtected(_token), ERROR_TOKEN_ALREADY_PROTECTED);

        _addProtectedToken(_token);
    }

    /**
    * @notice Remove `_token.symbol(): string` from the list of protected tokens
    * @param _token Address of the token to be unprotected
    */
    function removeProtectedToken(address _token) external authP(REMOVE_PROTECTED_TOKEN_ROLE, arr(_token)) {
        require(_tokenIsProtected(_token), ERROR_TOKEN_NOT_PROTECTED);

        _removeProtectedToken(_token);
    }

    /**
    * @notice Pre-sign hash `_hash`
    * @param _hash Hash that will be considered signed regardless of the signature checked with 'isValidSignature()'
    */
    function presignHash(bytes32 _hash)
        external
        authP(ADD_PRESIGNED_HASH_ROLE, arr(_hash))
    {
        isPresigned[_hash] = true;

        emit PresignHash(msg.sender, _hash);
    }

    /**
    * @notice Set `_designatedSigner` as the designated signer of the app, which will be able to sign messages on behalf of the app
    * @param _designatedSigner Address that will be able to sign messages on behalf of the app
    */
    function setDesignatedSigner(address _designatedSigner)
        external
        authP(DESIGNATE_SIGNER_ROLE, arr(_designatedSigner))
    {
        // Prevent an infinite loop by setting the app itself as its designated signer.
        // An undetectable loop can be created by setting a different contract as the
        // designated signer which calls back into `isValidSignature`.
        // Given that `isValidSignature` is always called with just 50k gas, the max
        // damage of the loop is wasting 50k gas.
        require(_designatedSigner != address(this), ERROR_DESIGNATED_TO_SELF);

        address oldDesignatedSigner = designatedSigner;
        designatedSigner = _designatedSigner;

        emit SetDesignatedSigner(msg.sender, oldDesignatedSigner, _designatedSigner);
    }

    // Forwarding fns

    /**
    * @notice Tells whether the Agent app is a forwarder or not
    * @dev IForwarder interface conformance
    * @return Always true
    */
    function isForwarder() external pure returns (bool) {
        return true;
    }

    /**
    * @notice Execute the script as the Agent app
    * @dev IForwarder interface conformance. Forwards any token holder action.
    * @param _evmScript Script being executed
    */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript), ERROR_CAN_NOT_FORWARD);

        bytes memory input = ""; // no input
        address[] memory blacklist = new address[](0); // no addr blacklist, can interact with anything
        runScript(_evmScript, input, blacklist);
        // We don't need to emit an event here as EVMScriptRunner will emit ScriptResult if successful
    }

    /**
    * @notice Tells whether `_sender` can forward actions or not
    * @dev IForwarder interface conformance
    * @param _sender Address of the account intending to forward an action
    * @return True if the given address can run scripts, false otherwise
    */
    function canForward(address _sender, bytes _evmScript) public view returns (bool) {
        // Note that `canPerform()` implicitly does an initialization check itself
        return canPerform(_sender, RUN_SCRIPT_ROLE, arr(_getScriptACLParam(_evmScript)));
    }

    // ERC-165 conformance

    /**
     * @notice Tells whether this contract supports a given ERC-165 interface
     * @param _interfaceId Interface bytes to check
     * @return True if this contract supports the interface
     */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == ERC1271_INTERFACE_ID ||
            _interfaceId == ERC165_INTERFACE_ID;
    }

    // ERC-1271 conformance

    /**
     * @notice Tells whether a signature is seen as valid by this contract through ERC-1271
     * @param _hash Arbitrary length data signed on the behalf of address (this)
     * @param _signature Signature byte array associated with _data
     * @return The ERC-1271 magic value if the signature is valid
     */
    function isValidSignature(bytes32 _hash, bytes _signature) public view returns (bytes4) {
        // Short-circuit in case the hash was presigned. Optimization as performing calls
        // and ecrecover is more expensive than an SLOAD.
        if (isPresigned[_hash]) {
            return returnIsValidSignatureMagicNumber(true);
        }

        bool isValid;
        if (designatedSigner == address(0)) {
            isValid = false;
        } else {
            isValid = SignatureValidator.isValidSignature(_hash, designatedSigner, _signature);
        }

        return returnIsValidSignatureMagicNumber(isValid);
    }

    // Getters

    function getProtectedTokensLength() public view isInitialized returns (uint256) {
        return protectedTokens.length;
    }

    // Internal fns

    function _addProtectedToken(address _token) internal {
        protectedTokens.push(_token);

        emit AddProtectedToken(_token);
    }

    function _removeProtectedToken(address _token) internal {
        protectedTokens[_protectedTokenIndex(_token)] = protectedTokens[protectedTokens.length - 1];
        protectedTokens.length--;

        emit RemoveProtectedToken(_token);
    }

    function _isERC20(address _token) internal view returns (bool) {
        if (!isContract(_token)) {
            return false;
        }

        // Throwaway sanity check to make sure the token's `balanceOf()` does not error (for now)
        balance(_token);

        return true;
    }

    function _protectedTokenIndex(address _token) internal view returns (uint256) {
        for (uint i = 0; i < protectedTokens.length; i++) {
            if (protectedTokens[i] == _token) {
              return i;
            }
        }

        revert(ERROR_TOKEN_NOT_PROTECTED);
    }

    function _tokenIsProtected(address _token) internal view returns (bool) {
        for (uint256 i = 0; i < protectedTokens.length; i++) {
            if (protectedTokens[i] == _token) {
                return true;
            }
        }

        return false;
    }

    function _getScriptACLParam(bytes _evmScript) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_evmScript)));
    }

    function _getSig(bytes _data) internal pure returns (bytes4 sig) {
        if (_data.length < 4) {
            return;
        }

        assembly { sig := mload(add(_data, 0x20)) }
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

// File: @aragon/apps-shared-minime/contracts/ITokenController.sol

pragma solidity ^0.4.24;

/// @dev The token controller contract must implement these functions


interface ITokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) external payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) external returns(bool);
}

// File: @aragon/apps-shared-minime/contracts/MiniMeToken.sol

pragma solidity ^0.4.24;

/*
    Copyright 2016, Jordi Baylina
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MiniMeToken Contract
/// @author Jordi Baylina
/// @dev This token contract's goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO's
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.


contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    address public controller;

    function Controlled()  public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController  public {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data
    ) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "MMT_0.1"; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeToken(
        MiniMeTokenFactory _tokenFactory,
        MiniMeToken _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount)
                return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != 0) && (_to != address(this)));
        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            // Adding the ` == true` makes the linter shut up so...
            require(ITokenController(controller).onTransfer(_from, _to, _amount) == true);
        }
        // First update the balance array with the new value for the address
        //  sending the tokens
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
        // Then update the balance array with the new value for the address
        //  receiving the tokens
        var previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
        // An event to make the transfer easy to find on the blockchain
        Transfer(_from, _to, _amount);
        return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            // Adding the ` == true` makes the linter shut up so...
            require(ITokenController(controller).onApprove(msg.sender, _spender, _amount) == true);
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        _spender.receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) public returns(MiniMeToken)
    {
        uint256 snapshot = _snapshotBlock == 0 ? block.number - 1 : _snapshotBlock;

        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            snapshot,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
        );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), snapshot);
        return cloneToken;
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0)
            return false;

        assembly {
            size := extcodesize(_addr)
        }

        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () external payable {
        require(isContract(controller));
        // Adding the ` == true` makes the linter shut up so...
        require(ITokenController(controller).proxyPayment.value(msg.value)(msg.sender) == true);
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController public {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


////////////////
// MiniMeTokenFactory
////////////////

/// @dev This contract is used to generate clone contracts from a contract.
///  In solidity this is the way to create a contract from a contract of the
///  same class
contract MiniMeTokenFactory {

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createCloneToken(
        MiniMeToken _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken)
    {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
        );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

// File: @aragon/apps-voting/contracts/Voting.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;







contract Voting is IForwarder, AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    bytes32 public constant CREATE_VOTES_ROLE = keccak256("CREATE_VOTES_ROLE");
    bytes32 public constant MODIFY_SUPPORT_ROLE = keccak256("MODIFY_SUPPORT_ROLE");
    bytes32 public constant MODIFY_QUORUM_ROLE = keccak256("MODIFY_QUORUM_ROLE");

    uint64 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10^16; 100% = 10^18

    string private constant ERROR_NO_VOTE = "VOTING_NO_VOTE";
    string private constant ERROR_INIT_PCTS = "VOTING_INIT_PCTS";
    string private constant ERROR_CHANGE_SUPPORT_PCTS = "VOTING_CHANGE_SUPPORT_PCTS";
    string private constant ERROR_CHANGE_QUORUM_PCTS = "VOTING_CHANGE_QUORUM_PCTS";
    string private constant ERROR_INIT_SUPPORT_TOO_BIG = "VOTING_INIT_SUPPORT_TOO_BIG";
    string private constant ERROR_CHANGE_SUPPORT_TOO_BIG = "VOTING_CHANGE_SUPP_TOO_BIG";
    string private constant ERROR_CAN_NOT_VOTE = "VOTING_CAN_NOT_VOTE";
    string private constant ERROR_CAN_NOT_EXECUTE = "VOTING_CAN_NOT_EXECUTE";
    string private constant ERROR_CAN_NOT_FORWARD = "VOTING_CAN_NOT_FORWARD";
    string private constant ERROR_NO_VOTING_POWER = "VOTING_NO_VOTING_POWER";

    enum VoterState { Absent, Yea, Nay }

    struct Vote {
        bool executed;
        uint64 startDate;
        uint64 snapshotBlock;
        uint64 supportRequiredPct;
        uint64 minAcceptQuorumPct;
        uint256 yea;
        uint256 nay;
        uint256 votingPower;
        bytes executionScript;
        mapping (address => VoterState) voters;
    }

    MiniMeToken public token;
    uint64 public supportRequiredPct;
    uint64 public minAcceptQuorumPct;
    uint64 public voteTime;

    // We are mimicing an array, we use a mapping instead to make app upgrade more graceful
    mapping (uint256 => Vote) internal votes;
    uint256 public votesLength;

    event StartVote(uint256 indexed voteId, address indexed creator, string metadata);
    event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);
    event ExecuteVote(uint256 indexed voteId);
    event ChangeSupportRequired(uint64 supportRequiredPct);
    event ChangeMinQuorum(uint64 minAcceptQuorumPct);

    modifier voteExists(uint256 _voteId) {
        require(_voteId < votesLength, ERROR_NO_VOTE);
        _;
    }

    /**
    * @notice Initialize Voting app with `_token.symbol(): string` for governance, minimum support of `@formatPct(_supportRequiredPct)`%, minimum acceptance quorum of `@formatPct(_minAcceptQuorumPct)`%, and a voting duration of `@transformTime(_voteTime)`
    * @param _token MiniMeToken Address that will be used as governance token
    * @param _supportRequiredPct Percentage of yeas in casted votes for a vote to succeed (expressed as a percentage of 10^18; eg. 10^16 = 1%, 10^18 = 100%)
    * @param _minAcceptQuorumPct Percentage of yeas in total possible votes for a vote to succeed (expressed as a percentage of 10^18; eg. 10^16 = 1%, 10^18 = 100%)
    * @param _voteTime Seconds that a vote will be open for token holders to vote (unless enough yeas or nays have been cast to make an early decision)
    */
    function initialize(
        MiniMeToken _token,
        uint64 _supportRequiredPct,
        uint64 _minAcceptQuorumPct,
        uint64 _voteTime
    )
        external
        onlyInit
    {
        initialized();

        require(_minAcceptQuorumPct <= _supportRequiredPct, ERROR_INIT_PCTS);
        require(_supportRequiredPct < PCT_BASE, ERROR_INIT_SUPPORT_TOO_BIG);

        token = _token;
        supportRequiredPct = _supportRequiredPct;
        minAcceptQuorumPct = _minAcceptQuorumPct;
        voteTime = _voteTime;
    }

    /**
    * @notice Change required support to `@formatPct(_supportRequiredPct)`%
    * @param _supportRequiredPct New required support
    */
    function changeSupportRequiredPct(uint64 _supportRequiredPct)
        external
        authP(MODIFY_SUPPORT_ROLE, arr(uint256(_supportRequiredPct), uint256(supportRequiredPct)))
    {
        require(minAcceptQuorumPct <= _supportRequiredPct, ERROR_CHANGE_SUPPORT_PCTS);
        require(_supportRequiredPct < PCT_BASE, ERROR_CHANGE_SUPPORT_TOO_BIG);
        supportRequiredPct = _supportRequiredPct;

        emit ChangeSupportRequired(_supportRequiredPct);
    }

    /**
    * @notice Change minimum acceptance quorum to `@formatPct(_minAcceptQuorumPct)`%
    * @param _minAcceptQuorumPct New acceptance quorum
    */
    function changeMinAcceptQuorumPct(uint64 _minAcceptQuorumPct)
        external
        authP(MODIFY_QUORUM_ROLE, arr(uint256(_minAcceptQuorumPct), uint256(minAcceptQuorumPct)))
    {
        require(_minAcceptQuorumPct <= supportRequiredPct, ERROR_CHANGE_QUORUM_PCTS);
        minAcceptQuorumPct = _minAcceptQuorumPct;

        emit ChangeMinQuorum(_minAcceptQuorumPct);
    }

    /**
    * @notice Create a new vote about "`_metadata`"
    * @param _executionScript EVM script to be executed on approval
    * @param _metadata Vote metadata
    * @return voteId Id for newly created vote
    */
    function newVote(bytes _executionScript, string _metadata) external auth(CREATE_VOTES_ROLE) returns (uint256 voteId) {
        return _newVote(_executionScript, _metadata, true, true);
    }

    /**
    * @notice Create a new vote about "`_metadata`"
    * @param _executionScript EVM script to be executed on approval
    * @param _metadata Vote metadata
    * @param _castVote Whether to also cast newly created vote
    * @param _executesIfDecided Whether to also immediately execute newly created vote if decided
    * @return voteId id for newly created vote
    */
    function newVote(bytes _executionScript, string _metadata, bool _castVote, bool _executesIfDecided)
        external
        auth(CREATE_VOTES_ROLE)
        returns (uint256 voteId)
    {
        return _newVote(_executionScript, _metadata, _castVote, _executesIfDecided);
    }

    /**
    * @notice Vote `_supports ? 'yes' : 'no'` in vote #`_voteId`
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @param _voteId Id for vote
    * @param _supports Whether voter supports the vote
    * @param _executesIfDecided Whether the vote should execute its action if it becomes decided
    */
    function vote(uint256 _voteId, bool _supports, bool _executesIfDecided) external voteExists(_voteId) {
        require(_canVote(_voteId, msg.sender), ERROR_CAN_NOT_VOTE);
        _vote(_voteId, _supports, msg.sender, _executesIfDecided);
    }

    /**
    * @notice Execute vote #`_voteId`
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @param _voteId Id for vote
    */
    function executeVote(uint256 _voteId) external voteExists(_voteId) {
        _executeVote(_voteId);
    }

    // Forwarding fns

    function isForwarder() external pure returns (bool) {
        return true;
    }

    /**
    * @notice Creates a vote to execute the desired action, and casts a support vote if possible
    * @dev IForwarder interface conformance
    * @param _evmScript Start vote with script
    */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript), ERROR_CAN_NOT_FORWARD);
        _newVote(_evmScript, "", true, true);
    }

    function canForward(address _sender, bytes) public view returns (bool) {
        // Note that `canPerform()` implicitly does an initialization check itself
        return canPerform(_sender, CREATE_VOTES_ROLE, arr());
    }

    // Getter fns

    /**
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    */
    function canExecute(uint256 _voteId) public view voteExists(_voteId) returns (bool) {
        return _canExecute(_voteId);
    }

    /**
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    */
    function canVote(uint256 _voteId, address _voter) public view voteExists(_voteId) returns (bool) {
        return _canVote(_voteId, _voter);
    }

    function getVote(uint256 _voteId)
        public
        view
        voteExists(_voteId)
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 minAcceptQuorum,
            uint256 yea,
            uint256 nay,
            uint256 votingPower,
            bytes script
        )
    {
        Vote storage vote_ = votes[_voteId];

        open = _isVoteOpen(vote_);
        executed = vote_.executed;
        startDate = vote_.startDate;
        snapshotBlock = vote_.snapshotBlock;
        supportRequired = vote_.supportRequiredPct;
        minAcceptQuorum = vote_.minAcceptQuorumPct;
        yea = vote_.yea;
        nay = vote_.nay;
        votingPower = vote_.votingPower;
        script = vote_.executionScript;
    }

    function getVoterState(uint256 _voteId, address _voter) public view voteExists(_voteId) returns (VoterState) {
        return votes[_voteId].voters[_voter];
    }

    // Internal fns

    function _newVote(bytes _executionScript, string _metadata, bool _castVote, bool _executesIfDecided)
        internal
        returns (uint256 voteId)
    {
        uint64 snapshotBlock = getBlockNumber64() - 1; // avoid double voting in this very block
        uint256 votingPower = token.totalSupplyAt(snapshotBlock);
        require(votingPower > 0, ERROR_NO_VOTING_POWER);

        voteId = votesLength++;

        Vote storage vote_ = votes[voteId];
        vote_.startDate = getTimestamp64();
        vote_.snapshotBlock = snapshotBlock;
        vote_.supportRequiredPct = supportRequiredPct;
        vote_.minAcceptQuorumPct = minAcceptQuorumPct;
        vote_.votingPower = votingPower;
        vote_.executionScript = _executionScript;

        emit StartVote(voteId, msg.sender, _metadata);

        if (_castVote && _canVote(voteId, msg.sender)) {
            _vote(voteId, true, msg.sender, _executesIfDecided);
        }
    }

    function _vote(
        uint256 _voteId,
        bool _supports,
        address _voter,
        bool _executesIfDecided
    ) internal
    {
        Vote storage vote_ = votes[_voteId];

        // This could re-enter, though we can assume the governance token is not malicious
        uint256 voterStake = token.balanceOfAt(_voter, vote_.snapshotBlock);
        VoterState state = vote_.voters[_voter];

        // If voter had previously voted, decrease count
        if (state == VoterState.Yea) {
            vote_.yea = vote_.yea.sub(voterStake);
        } else if (state == VoterState.Nay) {
            vote_.nay = vote_.nay.sub(voterStake);
        }

        if (_supports) {
            vote_.yea = vote_.yea.add(voterStake);
        } else {
            vote_.nay = vote_.nay.add(voterStake);
        }

        vote_.voters[_voter] = _supports ? VoterState.Yea : VoterState.Nay;

        emit CastVote(_voteId, _voter, _supports, voterStake);

        if (_executesIfDecided && _canExecute(_voteId)) {
            // We've already checked if the vote can be executed with `_canExecute()`
            _unsafeExecuteVote(_voteId);
        }
    }

    function _executeVote(uint256 _voteId) internal {
        require(_canExecute(_voteId), ERROR_CAN_NOT_EXECUTE);
        _unsafeExecuteVote(_voteId);
    }

    /**
    * @dev Unsafe version of _executeVote that assumes you have already checked if the vote can be executed
    */
    function _unsafeExecuteVote(uint256 _voteId) internal {
        Vote storage vote_ = votes[_voteId];

        vote_.executed = true;

        bytes memory input = new bytes(0); // TODO: Consider input for voting scripts
        runScript(vote_.executionScript, input, new address[](0));

        emit ExecuteVote(_voteId);
    }

    function _canExecute(uint256 _voteId) internal view returns (bool) {
        Vote storage vote_ = votes[_voteId];

        if (vote_.executed) {
            return false;
        }

        // Voting is already decided
        if (_isValuePct(vote_.yea, vote_.votingPower, vote_.supportRequiredPct)) {
            return true;
        }

        // Vote ended?
        if (_isVoteOpen(vote_)) {
            return false;
        }
        // Has enough support?
        uint256 totalVotes = vote_.yea.add(vote_.nay);
        if (!_isValuePct(vote_.yea, totalVotes, vote_.supportRequiredPct)) {
            return false;
        }
        // Has min quorum?
        if (!_isValuePct(vote_.yea, vote_.votingPower, vote_.minAcceptQuorumPct)) {
            return false;
        }

        return true;
    }

    function _canVote(uint256 _voteId, address _voter) internal view returns (bool) {
        Vote storage vote_ = votes[_voteId];

        return _isVoteOpen(vote_) && token.balanceOfAt(_voter, vote_.snapshotBlock) > 0;
    }

    function _isVoteOpen(Vote storage vote_) internal view returns (bool) {
        return getTimestamp64() < vote_.startDate.add(voteTime) && !vote_.executed;
    }

    /**
    * @dev Calculates whether `_value` is more than a percentage `_pct` of `_total`
    */
    function _isValuePct(uint256 _value, uint256 _total, uint256 _pct) internal pure returns (bool) {
        if (_total == 0) {
            return false;
        }

        uint256 computedPct = _value.mul(PCT_BASE) / _total;
        return computedPct > _pct;
    }
}

// File: @aragon/ppf-contracts/contracts/IFeed.sol

pragma solidity ^0.4.18;

interface IFeed {
    function ratePrecision() external pure returns (uint256);
    function get(address base, address quote) external view returns (uint128 xrt, uint64 when);
}

// File: @aragon/apps-finance/contracts/Finance.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;










contract Finance is EtherTokenConstant, IsContract, AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeERC20 for ERC20;

    bytes32 public constant CREATE_PAYMENTS_ROLE = keccak256("CREATE_PAYMENTS_ROLE");
    bytes32 public constant CHANGE_PERIOD_ROLE = keccak256("CHANGE_PERIOD_ROLE");
    bytes32 public constant CHANGE_BUDGETS_ROLE = keccak256("CHANGE_BUDGETS_ROLE");
    bytes32 public constant EXECUTE_PAYMENTS_ROLE = keccak256("EXECUTE_PAYMENTS_ROLE");
    bytes32 public constant MANAGE_PAYMENTS_ROLE = keccak256("MANAGE_PAYMENTS_ROLE");

    uint256 internal constant NO_SCHEDULED_PAYMENT = 0;
    uint256 internal constant NO_TRANSACTION = 0;
    uint256 internal constant MAX_SCHEDULED_PAYMENTS_PER_TX = 20;
    uint256 internal constant MAX_UINT256 = uint256(-1);
    uint64 internal constant MAX_UINT64 = uint64(-1);
    uint64 internal constant MINIMUM_PERIOD = uint64(1 days);

    string private constant ERROR_COMPLETE_TRANSITION = "FINANCE_COMPLETE_TRANSITION";
    string private constant ERROR_NO_SCHEDULED_PAYMENT = "FINANCE_NO_SCHEDULED_PAYMENT";
    string private constant ERROR_NO_TRANSACTION = "FINANCE_NO_TRANSACTION";
    string private constant ERROR_NO_PERIOD = "FINANCE_NO_PERIOD";
    string private constant ERROR_VAULT_NOT_CONTRACT = "FINANCE_VAULT_NOT_CONTRACT";
    string private constant ERROR_SET_PERIOD_TOO_SHORT = "FINANCE_SET_PERIOD_TOO_SHORT";
    string private constant ERROR_NEW_PAYMENT_AMOUNT_ZERO = "FINANCE_NEW_PAYMENT_AMOUNT_ZERO";
    string private constant ERROR_NEW_PAYMENT_INTERVAL_ZERO = "FINANCE_NEW_PAYMENT_INTRVL_ZERO";
    string private constant ERROR_NEW_PAYMENT_EXECS_ZERO = "FINANCE_NEW_PAYMENT_EXECS_ZERO";
    string private constant ERROR_NEW_PAYMENT_IMMEDIATE = "FINANCE_NEW_PAYMENT_IMMEDIATE";
    string private constant ERROR_RECOVER_AMOUNT_ZERO = "FINANCE_RECOVER_AMOUNT_ZERO";
    string private constant ERROR_DEPOSIT_AMOUNT_ZERO = "FINANCE_DEPOSIT_AMOUNT_ZERO";
    string private constant ERROR_ETH_VALUE_MISMATCH = "FINANCE_ETH_VALUE_MISMATCH";
    string private constant ERROR_BUDGET = "FINANCE_BUDGET";
    string private constant ERROR_EXECUTE_PAYMENT_NUM = "FINANCE_EXECUTE_PAYMENT_NUM";
    string private constant ERROR_EXECUTE_PAYMENT_TIME = "FINANCE_EXECUTE_PAYMENT_TIME";
    string private constant ERROR_PAYMENT_RECEIVER = "FINANCE_PAYMENT_RECEIVER";
    string private constant ERROR_TOKEN_TRANSFER_FROM_REVERTED = "FINANCE_TKN_TRANSFER_FROM_REVERT";
    string private constant ERROR_TOKEN_APPROVE_FAILED = "FINANCE_TKN_APPROVE_FAILED";
    string private constant ERROR_PAYMENT_INACTIVE = "FINANCE_PAYMENT_INACTIVE";
    string private constant ERROR_REMAINING_BUDGET = "FINANCE_REMAINING_BUDGET";

    // Order optimized for storage
    struct ScheduledPayment {
        address token;
        address receiver;
        address createdBy;
        bool inactive;
        uint256 amount;
        uint64 initialPaymentTime;
        uint64 interval;
        uint64 maxExecutions;
        uint64 executions;
    }

    // Order optimized for storage
    struct Transaction {
        address token;
        address entity;
        bool isIncoming;
        uint256 amount;
        uint256 paymentId;
        uint64 paymentExecutionNumber;
        uint64 date;
        uint64 periodId;
    }

    struct TokenStatement {
        uint256 expenses;
        uint256 income;
    }

    struct Period {
        uint64 startTime;
        uint64 endTime;
        uint256 firstTransactionId;
        uint256 lastTransactionId;
        mapping (address => TokenStatement) tokenStatement;
    }

    struct Settings {
        uint64 periodDuration;
        mapping (address => uint256) budgets;
        mapping (address => bool) hasBudget;
    }

    Vault public vault;
    Settings internal settings;

    // We are mimicing arrays, we use mappings instead to make app upgrade more graceful
    mapping (uint256 => ScheduledPayment) internal scheduledPayments;
    // Payments start at index 1, to allow us to use scheduledPayments[0] for transactions that are not
    // linked to a scheduled payment
    uint256 public paymentsNextIndex;

    mapping (uint256 => Transaction) internal transactions;
    uint256 public transactionsNextIndex;

    mapping (uint64 => Period) internal periods;
    uint64 public periodsLength;

    event NewPeriod(uint64 indexed periodId, uint64 periodStarts, uint64 periodEnds);
    event SetBudget(address indexed token, uint256 amount, bool hasBudget);
    event NewPayment(uint256 indexed paymentId, address indexed recipient, uint64 maxExecutions, string reference);
    event NewTransaction(uint256 indexed transactionId, bool incoming, address indexed entity, uint256 amount, string reference);
    event ChangePaymentState(uint256 indexed paymentId, bool active);
    event ChangePeriodDuration(uint64 newDuration);
    event PaymentFailure(uint256 paymentId);

    // Modifier used by all methods that impact accounting to make sure accounting period
    // is changed before the operation if needed
    // NOTE: its use **MUST** be accompanied by an initialization check
    modifier transitionsPeriod {
        bool completeTransition = _tryTransitionAccountingPeriod(getMaxPeriodTransitions());
        require(completeTransition, ERROR_COMPLETE_TRANSITION);
        _;
    }

    modifier scheduledPaymentExists(uint256 _paymentId) {
        require(_paymentId > 0 && _paymentId < paymentsNextIndex, ERROR_NO_SCHEDULED_PAYMENT);
        _;
    }

    modifier transactionExists(uint256 _transactionId) {
        require(_transactionId > 0 && _transactionId < transactionsNextIndex, ERROR_NO_TRANSACTION);
        _;
    }

    modifier periodExists(uint64 _periodId) {
        require(_periodId < periodsLength, ERROR_NO_PERIOD);
        _;
    }

    /**
     * @notice Deposit ETH to the Vault, to avoid locking them in this Finance app forever
     * @dev Send ETH to Vault. Send all the available balance.
     */
    function () external payable isInitialized transitionsPeriod {
        require(msg.value > 0, ERROR_DEPOSIT_AMOUNT_ZERO);
        _deposit(
            ETH,
            msg.value,
            "Ether transfer to Finance app",
            msg.sender,
            true
        );
    }

    /**
    * @notice Initialize Finance app for Vault at `_vault` with period length of `@transformTime(_periodDuration)`
    * @param _vault Address of the vault Finance will rely on (non changeable)
    * @param _periodDuration Duration in seconds of each period
    */
    function initialize(Vault _vault, uint64 _periodDuration) external onlyInit {
        initialized();

        require(isContract(_vault), ERROR_VAULT_NOT_CONTRACT);
        vault = _vault;

        require(_periodDuration >= MINIMUM_PERIOD, ERROR_SET_PERIOD_TOO_SHORT);
        settings.periodDuration = _periodDuration;

        // Reserve the first scheduled payment index as an unused index for transactions not linked
        // to a scheduled payment
        scheduledPayments[0].inactive = true;
        paymentsNextIndex = 1;

        // Reserve the first transaction index as an unused index for periods with no transactions
        transactionsNextIndex = 1;

        // Start the first period
        _newPeriod(getTimestamp64());
    }

    /**
    * @notice Deposit `@tokenAmount(_token, _amount)`
    * @dev Deposit for approved ERC20 tokens or ETH
    * @param _token Address of deposited token
    * @param _amount Amount of tokens sent
    * @param _reference Reason for payment
    */
    function deposit(address _token, uint256 _amount, string _reference) external payable isInitialized transitionsPeriod {
        require(_amount > 0, ERROR_DEPOSIT_AMOUNT_ZERO);
        if (_token == ETH) {
            // Ensure that the ETH sent with the transaction equals the amount in the deposit
            require(msg.value == _amount, ERROR_ETH_VALUE_MISMATCH);
        }

        _deposit(
            _token,
            _amount,
            _reference,
            msg.sender,
            true
        );
    }

    /**
    * @notice Create a new payment of `@tokenAmount(_token, _amount)` to `_receiver` for '`_reference`'
    * @dev Note that this function is protected by the `CREATE_PAYMENTS_ROLE` but uses `MAX_UINT256`
    *      as its interval auth parameter (as a sentinel value for "never repeating").
    *      While this protects against most cases (you typically want to set a baseline requirement
    *      for interval time), it does mean users will have to explicitly check for this case when
    *      granting a permission that includes a upperbound requirement on the interval time.
    * @param _token Address of token for payment
    * @param _receiver Address that will receive payment
    * @param _amount Tokens that are paid every time the payment is due
    * @param _reference String detailing payment reason
    */
    function newImmediatePayment(address _token, address _receiver, uint256 _amount, string _reference)
        external
        // Use MAX_UINT256 as the interval parameter, as this payment will never repeat
        // Payment time parameter is left as the last param as it was added later
        authP(CREATE_PAYMENTS_ROLE, _arr(_token, _receiver, _amount, MAX_UINT256, uint256(1), getTimestamp()))
        transitionsPeriod
    {
        require(_amount > 0, ERROR_NEW_PAYMENT_AMOUNT_ZERO);

        _makePaymentTransaction(
            _token,
            _receiver,
            _amount,
            NO_SCHEDULED_PAYMENT,   // unrelated to any payment id; it isn't created
            0,   // also unrelated to any payment executions
            _reference
        );
    }

    /**
    * @notice Create a new payment of `@tokenAmount(_token, _amount)` to `_receiver` for `_reference`, executing `_maxExecutions` times at intervals of `@transformTime(_interval)`
    * @dev See `newImmediatePayment()` for limitations on how the interval auth parameter can be used
    * @param _token Address of token for payment
    * @param _receiver Address that will receive payment
    * @param _amount Tokens that are paid every time the payment is due
    * @param _initialPaymentTime Timestamp for when the first payment is done
    * @param _interval Number of seconds that need to pass between payment transactions
    * @param _maxExecutions Maximum instances a payment can be executed
    * @param _reference String detailing payment reason
    */
    function newScheduledPayment(
        address _token,
        address _receiver,
        uint256 _amount,
        uint64 _initialPaymentTime,
        uint64 _interval,
        uint64 _maxExecutions,
        string _reference
    )
        external
        // Payment time parameter is left as the last param as it was added later
        authP(CREATE_PAYMENTS_ROLE, _arr(_token, _receiver, _amount, uint256(_interval), uint256(_maxExecutions), uint256(_initialPaymentTime)))
        transitionsPeriod
        returns (uint256 paymentId)
    {
        require(_amount > 0, ERROR_NEW_PAYMENT_AMOUNT_ZERO);
        require(_interval > 0, ERROR_NEW_PAYMENT_INTERVAL_ZERO);
        require(_maxExecutions > 0, ERROR_NEW_PAYMENT_EXECS_ZERO);

        // Token budget must not be set at all or allow at least one instance of this payment each period
        require(!settings.hasBudget[_token] || settings.budgets[_token] >= _amount, ERROR_BUDGET);

        // Don't allow creating single payments that are immediately executable, use `newImmediatePayment()` instead
        if (_maxExecutions == 1) {
            require(_initialPaymentTime > getTimestamp64(), ERROR_NEW_PAYMENT_IMMEDIATE);
        }

        paymentId = paymentsNextIndex++;
        emit NewPayment(paymentId, _receiver, _maxExecutions, _reference);

        ScheduledPayment storage payment = scheduledPayments[paymentId];
        payment.token = _token;
        payment.receiver = _receiver;
        payment.amount = _amount;
        payment.initialPaymentTime = _initialPaymentTime;
        payment.interval = _interval;
        payment.maxExecutions = _maxExecutions;
        payment.createdBy = msg.sender;

        // We skip checking how many times the new payment was executed to allow creating new
        // scheduled payments before having enough vault balance
        _executePayment(paymentId);
    }

    /**
    * @notice Change period duration to `@transformTime(_periodDuration)`, effective for next accounting period
    * @param _periodDuration Duration in seconds for accounting periods
    */
    function setPeriodDuration(uint64 _periodDuration)
        external
        authP(CHANGE_PERIOD_ROLE, arr(uint256(_periodDuration), uint256(settings.periodDuration)))
        transitionsPeriod
    {
        require(_periodDuration >= MINIMUM_PERIOD, ERROR_SET_PERIOD_TOO_SHORT);
        settings.periodDuration = _periodDuration;
        emit ChangePeriodDuration(_periodDuration);
    }

    /**
    * @notice Set budget for `_token.symbol(): string` to `@tokenAmount(_token, _amount, false)`, effective immediately
    * @param _token Address for token
    * @param _amount New budget amount
    */
    function setBudget(
        address _token,
        uint256 _amount
    )
        external
        authP(CHANGE_BUDGETS_ROLE, arr(_token, _amount, settings.budgets[_token], uint256(settings.hasBudget[_token] ? 1 : 0)))
        transitionsPeriod
    {
        settings.budgets[_token] = _amount;
        if (!settings.hasBudget[_token]) {
            settings.hasBudget[_token] = true;
        }
        emit SetBudget(_token, _amount, true);
    }

    /**
    * @notice Remove spending limit for `_token.symbol(): string`, effective immediately
    * @param _token Address for token
    */
    function removeBudget(address _token)
        external
        authP(CHANGE_BUDGETS_ROLE, arr(_token, uint256(0), settings.budgets[_token], uint256(settings.hasBudget[_token] ? 1 : 0)))
        transitionsPeriod
    {
        settings.budgets[_token] = 0;
        settings.hasBudget[_token] = false;
        emit SetBudget(_token, 0, false);
    }

    /**
    * @notice Execute pending payment #`_paymentId`
    * @dev Executes any payment (requires role)
    * @param _paymentId Identifier for payment
    */
    function executePayment(uint256 _paymentId)
        external
        authP(EXECUTE_PAYMENTS_ROLE, arr(_paymentId, scheduledPayments[_paymentId].amount))
        scheduledPaymentExists(_paymentId)
        transitionsPeriod
    {
        _executePaymentAtLeastOnce(_paymentId);
    }

    /**
    * @notice Execute pending payment #`_paymentId`
    * @dev Always allow receiver of a payment to trigger execution
    *      Initialization check is implicitly provided by `scheduledPaymentExists()` as new
    *      scheduled payments can only be created via `newScheduledPayment(),` which requires initialization
    * @param _paymentId Identifier for payment
    */
    function receiverExecutePayment(uint256 _paymentId) external scheduledPaymentExists(_paymentId) transitionsPeriod {
        require(scheduledPayments[_paymentId].receiver == msg.sender, ERROR_PAYMENT_RECEIVER);
        _executePaymentAtLeastOnce(_paymentId);
    }

    /**
    * @notice `_active ? 'Activate' : 'Disable'` payment #`_paymentId`
    * @dev Note that we do not require this action to transition periods, as it doesn't directly
    *      impact any accounting periods.
    *      Not having to transition periods also makes disabling payments easier to prevent funds
    *      from being pulled out in the event of a breach.
    * @param _paymentId Identifier for payment
    * @param _active Whether it will be active or inactive
    */
    function setPaymentStatus(uint256 _paymentId, bool _active)
        external
        authP(MANAGE_PAYMENTS_ROLE, arr(_paymentId, uint256(_active ? 1 : 0)))
        scheduledPaymentExists(_paymentId)
    {
        scheduledPayments[_paymentId].inactive = !_active;
        emit ChangePaymentState(_paymentId, _active);
    }

    /**
     * @notice Send tokens held in this contract to the Vault
     * @dev Allows making a simple payment from this contract to the Vault, to avoid locked tokens.
     *      This contract should never receive tokens with a simple transfer call, but in case it
     *      happens, this function allows for their recovery.
     * @param _token Token whose balance is going to be transferred.
     */
    function recoverToVault(address _token) external isInitialized transitionsPeriod {
        uint256 amount = _token == ETH ? address(this).balance : ERC20(_token).staticBalanceOf(address(this));
        require(amount > 0, ERROR_RECOVER_AMOUNT_ZERO);

        _deposit(
            _token,
            amount,
            "Recover to Vault",
            address(this),
            false
        );
    }

    /**
    * @notice Transition accounting period if needed
    * @dev Transitions accounting periods if needed. For preventing OOG attacks, a maxTransitions
    *      param is provided. If more than the specified number of periods need to be transitioned,
    *      it will return false.
    * @param _maxTransitions Maximum periods that can be transitioned
    * @return success Boolean indicating whether the accounting period is the correct one (if false,
    *                 maxTransitions was surpased and another call is needed)
    */
    function tryTransitionAccountingPeriod(uint64 _maxTransitions) external isInitialized returns (bool success) {
        return _tryTransitionAccountingPeriod(_maxTransitions);
    }

    // Getter fns

    /**
    * @dev Disable recovery escape hatch if the app has been initialized, as it could be used
    *      maliciously to transfer funds in the Finance app to another Vault
    *      finance#recoverToVault() should be used to recover funds to the Finance's vault
    */
    function allowRecoverability(address) public view returns (bool) {
        return !hasInitialized();
    }

    function getPayment(uint256 _paymentId)
        public
        view
        scheduledPaymentExists(_paymentId)
        returns (
            address token,
            address receiver,
            uint256 amount,
            uint64 initialPaymentTime,
            uint64 interval,
            uint64 maxExecutions,
            bool inactive,
            uint64 executions,
            address createdBy
        )
    {
        ScheduledPayment storage payment = scheduledPayments[_paymentId];

        token = payment.token;
        receiver = payment.receiver;
        amount = payment.amount;
        initialPaymentTime = payment.initialPaymentTime;
        interval = payment.interval;
        maxExecutions = payment.maxExecutions;
        executions = payment.executions;
        inactive = payment.inactive;
        createdBy = payment.createdBy;
    }

    function getTransaction(uint256 _transactionId)
        public
        view
        transactionExists(_transactionId)
        returns (
            uint64 periodId,
            uint256 amount,
            uint256 paymentId,
            uint64 paymentExecutionNumber,
            address token,
            address entity,
            bool isIncoming,
            uint64 date
        )
    {
        Transaction storage transaction = transactions[_transactionId];

        token = transaction.token;
        entity = transaction.entity;
        isIncoming = transaction.isIncoming;
        date = transaction.date;
        periodId = transaction.periodId;
        amount = transaction.amount;
        paymentId = transaction.paymentId;
        paymentExecutionNumber = transaction.paymentExecutionNumber;
    }

    function getPeriod(uint64 _periodId)
        public
        view
        periodExists(_periodId)
        returns (
            bool isCurrent,
            uint64 startTime,
            uint64 endTime,
            uint256 firstTransactionId,
            uint256 lastTransactionId
        )
    {
        Period storage period = periods[_periodId];

        isCurrent = _currentPeriodId() == _periodId;

        startTime = period.startTime;
        endTime = period.endTime;
        firstTransactionId = period.firstTransactionId;
        lastTransactionId = period.lastTransactionId;
    }

    function getPeriodTokenStatement(uint64 _periodId, address _token)
        public
        view
        periodExists(_periodId)
        returns (uint256 expenses, uint256 income)
    {
        TokenStatement storage tokenStatement = periods[_periodId].tokenStatement[_token];
        expenses = tokenStatement.expenses;
        income = tokenStatement.income;
    }

    /**
    * @dev We have to check for initialization as periods are only valid after initializing
    */
    function currentPeriodId() public view isInitialized returns (uint64) {
        return _currentPeriodId();
    }

    /**
    * @dev We have to check for initialization as periods are only valid after initializing
    */
    function getPeriodDuration() public view isInitialized returns (uint64) {
        return settings.periodDuration;
    }

    /**
    * @dev We have to check for initialization as budgets are only valid after initializing
    */
    function getBudget(address _token) public view isInitialized returns (uint256 budget, bool hasBudget) {
        budget = settings.budgets[_token];
        hasBudget = settings.hasBudget[_token];
    }

    /**
    * @dev We have to check for initialization as budgets are only valid after initializing
    */
    function getRemainingBudget(address _token) public view isInitialized returns (uint256) {
        return _getRemainingBudget(_token);
    }

    /**
    * @dev We have to check for initialization as budgets are only valid after initializing
    */
    function canMakePayment(address _token, uint256 _amount) public view isInitialized returns (bool) {
        return _canMakePayment(_token, _amount);
    }

    /**
    * @dev Initialization check is implicitly provided by `scheduledPaymentExists()` as new
    *      scheduled payments can only be created via `newScheduledPayment(),` which requires initialization
    */
    function nextPaymentTime(uint256 _paymentId) public view scheduledPaymentExists(_paymentId) returns (uint64) {
        return _nextPaymentTime(_paymentId);
    }

    // Internal fns

    function _deposit(address _token, uint256 _amount, string _reference, address _sender, bool _isExternalDeposit) internal {
        _recordIncomingTransaction(
            _token,
            _sender,
            _amount,
            _reference
        );

        if (_token == ETH) {
            vault.deposit.value(_amount)(ETH, _amount);
        } else {
            // First, transfer the tokens to Finance if necessary
            // External deposit will be false when the assets were already in the Finance app
            // and just need to be transferred to the Vault
            if (_isExternalDeposit) {
                // This assumes the sender has approved the tokens for Finance
                require(
                    ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount),
                    ERROR_TOKEN_TRANSFER_FROM_REVERTED
                );
            }
            // Approve the tokens for the Vault (it does the actual transferring)
            require(ERC20(_token).safeApprove(vault, _amount), ERROR_TOKEN_APPROVE_FAILED);
            // Finally, initiate the deposit
            vault.deposit(_token, _amount);
        }
    }

    function _executePayment(uint256 _paymentId) internal returns (uint256) {
        ScheduledPayment storage payment = scheduledPayments[_paymentId];
        require(!payment.inactive, ERROR_PAYMENT_INACTIVE);

        uint64 paid = 0;
        while (_nextPaymentTime(_paymentId) <= getTimestamp64() && paid < MAX_SCHEDULED_PAYMENTS_PER_TX) {
            if (!_canMakePayment(payment.token, payment.amount)) {
                emit PaymentFailure(_paymentId);
                break;
            }

            // The while() predicate prevents these two from ever overflowing
            payment.executions += 1;
            paid += 1;

            // We've already checked the remaining budget with `_canMakePayment()`
            _unsafeMakePaymentTransaction(
                payment.token,
                payment.receiver,
                payment.amount,
                _paymentId,
                payment.executions,
                ""
            );
        }

        return paid;
    }

    function _executePaymentAtLeastOnce(uint256 _paymentId) internal {
        uint256 paid = _executePayment(_paymentId);
        if (paid == 0) {
            if (_nextPaymentTime(_paymentId) <= getTimestamp64()) {
                revert(ERROR_EXECUTE_PAYMENT_NUM);
            } else {
                revert(ERROR_EXECUTE_PAYMENT_TIME);
            }
        }
    }

    function _makePaymentTransaction(
        address _token,
        address _receiver,
        uint256 _amount,
        uint256 _paymentId,
        uint64 _paymentExecutionNumber,
        string _reference
    )
        internal
    {
        require(_getRemainingBudget(_token) >= _amount, ERROR_REMAINING_BUDGET);
        _unsafeMakePaymentTransaction(_token, _receiver, _amount, _paymentId, _paymentExecutionNumber, _reference);
    }

    /**
    * @dev Unsafe version of _makePaymentTransaction that assumes you have already checked the
    *      remaining budget
    */
    function _unsafeMakePaymentTransaction(
        address _token,
        address _receiver,
        uint256 _amount,
        uint256 _paymentId,
        uint64 _paymentExecutionNumber,
        string _reference
    )
        internal
    {
        _recordTransaction(
            false,
            _token,
            _receiver,
            _amount,
            _paymentId,
            _paymentExecutionNumber,
            _reference
        );

        vault.transfer(_token, _receiver, _amount);
    }

    function _newPeriod(uint64 _startTime) internal returns (Period storage) {
        // There should be no way for this to overflow since each period is at least one day
        uint64 newPeriodId = periodsLength++;

        Period storage period = periods[newPeriodId];
        period.startTime = _startTime;

        // Be careful here to not overflow; if startTime + periodDuration overflows, we set endTime
        // to MAX_UINT64 (let's assume that's the end of time for now).
        uint64 endTime = _startTime + settings.periodDuration - 1;
        if (endTime < _startTime) { // overflowed
            endTime = MAX_UINT64;
        }
        period.endTime = endTime;

        emit NewPeriod(newPeriodId, period.startTime, period.endTime);

        return period;
    }

    function _recordIncomingTransaction(
        address _token,
        address _sender,
        uint256 _amount,
        string _reference
    )
        internal
    {
        _recordTransaction(
            true, // incoming transaction
            _token,
            _sender,
            _amount,
            NO_SCHEDULED_PAYMENT, // unrelated to any existing payment
            0, // and no payment executions
            _reference
        );
    }

    function _recordTransaction(
        bool _incoming,
        address _token,
        address _entity,
        uint256 _amount,
        uint256 _paymentId,
        uint64 _paymentExecutionNumber,
        string _reference
    )
        internal
    {
        uint64 periodId = _currentPeriodId();
        TokenStatement storage tokenStatement = periods[periodId].tokenStatement[_token];
        if (_incoming) {
            tokenStatement.income = tokenStatement.income.add(_amount);
        } else {
            tokenStatement.expenses = tokenStatement.expenses.add(_amount);
        }

        uint256 transactionId = transactionsNextIndex++;

        Transaction storage transaction = transactions[transactionId];
        transaction.token = _token;
        transaction.entity = _entity;
        transaction.isIncoming = _incoming;
        transaction.amount = _amount;
        transaction.paymentId = _paymentId;
        transaction.paymentExecutionNumber = _paymentExecutionNumber;
        transaction.date = getTimestamp64();
        transaction.periodId = periodId;

        Period storage period = periods[periodId];
        if (period.firstTransactionId == NO_TRANSACTION) {
            period.firstTransactionId = transactionId;
        }

        emit NewTransaction(transactionId, _incoming, _entity, _amount, _reference);
    }

    function _tryTransitionAccountingPeriod(uint64 _maxTransitions) internal returns (bool success) {
        Period storage currentPeriod = periods[_currentPeriodId()];
        uint64 timestamp = getTimestamp64();

        // Transition periods if necessary
        while (timestamp > currentPeriod.endTime) {
            if (_maxTransitions == 0) {
                // Required number of transitions is over allowed number, return false indicating
                // it didn't fully transition
                return false;
            }
            // We're already protected from underflowing above
            _maxTransitions -= 1;

            // If there were any transactions in period, record which was the last
            // In case 0 transactions occured, first and last tx id will be 0
            if (currentPeriod.firstTransactionId != NO_TRANSACTION) {
                currentPeriod.lastTransactionId = transactionsNextIndex.sub(1);
            }

            // New period starts at end time + 1
            currentPeriod = _newPeriod(currentPeriod.endTime.add(1));
        }

        return true;
    }

    function _canMakePayment(address _token, uint256 _amount) internal view returns (bool) {
        return _getRemainingBudget(_token) >= _amount && vault.balance(_token) >= _amount;
    }

    function _currentPeriodId() internal view returns (uint64) {
        // There is no way for this to overflow if protected by an initialization check
        return periodsLength - 1;
    }

    function _getRemainingBudget(address _token) internal view returns (uint256) {
        if (!settings.hasBudget[_token]) {
            return MAX_UINT256;
        }

        uint256 budget = settings.budgets[_token];
        uint256 spent = periods[_currentPeriodId()].tokenStatement[_token].expenses;

        // A budget decrease can cause the spent amount to be greater than period budget
        // If so, return 0 to not allow more spending during period
        if (spent >= budget) {
            return 0;
        }

        // We're already protected from the overflow above
        return budget - spent;
    }

    function _nextPaymentTime(uint256 _paymentId) internal view returns (uint64) {
        ScheduledPayment storage payment = scheduledPayments[_paymentId];

        if (payment.executions >= payment.maxExecutions) {
            return MAX_UINT64; // re-executes in some billions of years time... should not need to worry
        }

        // Split in multiple lines to circumvent linter warning
        uint64 increase = payment.executions.mul(payment.interval);
        uint64 nextPayment = payment.initialPaymentTime.add(increase);
        return nextPayment;
    }

    // Syntax sugar

    function _arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e, uint256 _f) internal pure returns (uint256[] r) {
        r = new uint256[](6);
        r[0] = uint256(_a);
        r[1] = uint256(_b);
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
        r[5] = _f;
    }

    // Mocked fns (overrided during testing)
    // Must be view for mocking purposes

    function getMaxPeriodTransitions() internal view returns (uint64) { return MAX_UINT64; }
}

// File: @aragon/apps-payroll/contracts/Payroll.sol

pragma solidity 0.4.24;










/**
 * @title Payroll in multiple currencies
 */
contract Payroll is EtherTokenConstant, IForwarder, IsContract, AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    /* Hardcoded constants to save gas
    * bytes32 constant public ADD_EMPLOYEE_ROLE = keccak256("ADD_EMPLOYEE_ROLE");
    * bytes32 constant public TERMINATE_EMPLOYEE_ROLE = keccak256("TERMINATE_EMPLOYEE_ROLE");
    * bytes32 constant public SET_EMPLOYEE_SALARY_ROLE = keccak256("SET_EMPLOYEE_SALARY_ROLE");
    * bytes32 constant public ADD_BONUS_ROLE = keccak256("ADD_BONUS_ROLE");
    * bytes32 constant public ADD_REIMBURSEMENT_ROLE = keccak256("ADD_REIMBURSEMENT_ROLE");
    * bytes32 constant public MANAGE_ALLOWED_TOKENS_ROLE = keccak256("MANAGE_ALLOWED_TOKENS_ROLE");
    * bytes32 constant public MODIFY_PRICE_FEED_ROLE = keccak256("MODIFY_PRICE_FEED_ROLE");
    * bytes32 constant public MODIFY_RATE_EXPIRY_ROLE = keccak256("MODIFY_RATE_EXPIRY_ROLE");
    */

    bytes32 constant public ADD_EMPLOYEE_ROLE = 0x9ecdc3c63716b45d0756eece5fe1614cae1889ec5a1ce62b3127c1f1f1615d6e;
    bytes32 constant public TERMINATE_EMPLOYEE_ROLE = 0x69c67f914d12b6440e7ddf01961214818d9158fbcb19211e0ff42800fdea9242;
    bytes32 constant public SET_EMPLOYEE_SALARY_ROLE = 0xea9ac65018da2421cf419ee2152371440c08267a193a33ccc1e39545d197e44d;
    bytes32 constant public ADD_BONUS_ROLE = 0xceca7e2f5eb749a87aaf68f3f76d6b9251aa2f4600f13f93c5a4adf7a72df4ae;
    bytes32 constant public ADD_REIMBURSEMENT_ROLE = 0x90698b9d54427f1e41636025017309bdb1b55320da960c8845bab0a504b01a16;
    bytes32 constant public MANAGE_ALLOWED_TOKENS_ROLE = 0x0be34987c45700ee3fae8c55e270418ba903337decc6bacb1879504be9331c06;
    bytes32 constant public MODIFY_PRICE_FEED_ROLE = 0x74350efbcba8b85341c5bbf70cc34e2a585fc1463524773a12fa0a71d4eb9302;
    bytes32 constant public MODIFY_RATE_EXPIRY_ROLE = 0x79fe989a8899060dfbdabb174ebb96616fa9f1d9dadd739f8d814cbab452404e;

    uint256 internal constant MAX_ALLOWED_TOKENS = 20; // prevent OOG issues with `payday()`
    uint64 internal constant MIN_RATE_EXPIRY = uint64(1 minutes); // 1 min == ~4 block window to mine both a price feed update and a payout

    uint256 internal constant MAX_UINT256 = uint256(-1);
    uint64 internal constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_EMPLOYEE_DOESNT_EXIST = "PAYROLL_EMPLOYEE_DOESNT_EXIST";
    string private constant ERROR_NON_ACTIVE_EMPLOYEE = "PAYROLL_NON_ACTIVE_EMPLOYEE";
    string private constant ERROR_SENDER_DOES_NOT_MATCH = "PAYROLL_SENDER_DOES_NOT_MATCH";
    string private constant ERROR_FINANCE_NOT_CONTRACT = "PAYROLL_FINANCE_NOT_CONTRACT";
    string private constant ERROR_TOKEN_ALREADY_SET = "PAYROLL_TOKEN_ALREADY_SET";
    string private constant ERROR_MAX_ALLOWED_TOKENS = "PAYROLL_MAX_ALLOWED_TOKENS";
    string private constant ERROR_MIN_RATES_MISMATCH = "PAYROLL_MIN_RATES_MISMATCH";
    string private constant ERROR_TOKEN_ALLOCATION_MISMATCH = "PAYROLL_TOKEN_ALLOCATION_MISMATCH";
    string private constant ERROR_NOT_ALLOWED_TOKEN = "PAYROLL_NOT_ALLOWED_TOKEN";
    string private constant ERROR_DISTRIBUTION_NOT_FULL = "PAYROLL_DISTRIBUTION_NOT_FULL";
    string private constant ERROR_INVALID_PAYMENT_TYPE = "PAYROLL_INVALID_PAYMENT_TYPE";
    string private constant ERROR_NOTHING_PAID = "PAYROLL_NOTHING_PAID";
    string private constant ERROR_CAN_NOT_FORWARD = "PAYROLL_CAN_NOT_FORWARD";
    string private constant ERROR_EMPLOYEE_NULL_ADDRESS = "PAYROLL_EMPLOYEE_NULL_ADDRESS";
    string private constant ERROR_EMPLOYEE_ALREADY_EXIST = "PAYROLL_EMPLOYEE_ALREADY_EXIST";
    string private constant ERROR_FEED_NOT_CONTRACT = "PAYROLL_FEED_NOT_CONTRACT";
    string private constant ERROR_EXPIRY_TIME_TOO_SHORT = "PAYROLL_EXPIRY_TIME_TOO_SHORT";
    string private constant ERROR_PAST_TERMINATION_DATE = "PAYROLL_PAST_TERMINATION_DATE";
    string private constant ERROR_EXCHANGE_RATE_TOO_LOW = "PAYROLL_EXCHANGE_RATE_TOO_LOW";
    string private constant ERROR_LAST_PAYROLL_DATE_TOO_BIG = "PAYROLL_LAST_DATE_TOO_BIG";
    string private constant ERROR_INVALID_REQUESTED_AMOUNT = "PAYROLL_INVALID_REQUESTED_AMT";

    enum PaymentType { Payroll, Reimbursement, Bonus }

    struct Employee {
        address accountAddress; // unique, but can be changed over time
        uint256 denominationTokenSalary; // salary per second in denomination Token
        uint256 accruedSalary; // keep track of any leftover accrued salary when changing salaries
        uint256 bonus;
        uint256 reimbursements;
        uint64 lastPayroll;
        uint64 endDate;
        address[] allocationTokenAddresses;
        mapping(address => uint256) allocationTokens;
    }

    Finance public finance;
    address public denominationToken;
    IFeed public feed;
    uint64 public rateExpiryTime;

    // Employees start at index 1, to allow us to use employees[0] to check for non-existent employees
    uint256 public nextEmployee;
    mapping(uint256 => Employee) internal employees;     // employee ID -> employee
    mapping(address => uint256) internal employeeIds;    // employee address -> employee ID

    mapping(address => bool) internal allowedTokens;

    event AddEmployee(
        uint256 indexed employeeId,
        address indexed accountAddress,
        uint256 initialDenominationSalary,
        uint64 startDate,
        string role
    );
    event TerminateEmployee(uint256 indexed employeeId, uint64 endDate);
    event SetEmployeeSalary(uint256 indexed employeeId, uint256 denominationSalary);
    event AddEmployeeAccruedSalary(uint256 indexed employeeId, uint256 amount);
    event AddEmployeeBonus(uint256 indexed employeeId, uint256 amount);
    event AddEmployeeReimbursement(uint256 indexed employeeId, uint256 amount);
    event ChangeAddressByEmployee(uint256 indexed employeeId, address indexed newAccountAddress, address indexed oldAccountAddress);
    event DetermineAllocation(uint256 indexed employeeId);
    event SendPayment(
        uint256 indexed employeeId,
        address indexed accountAddress,
        address indexed token,
        uint256 amount,
        uint256 exchangeRate,
        string paymentReference
    );
    event SetAllowedToken(address indexed token, bool allowed);
    event SetPriceFeed(address indexed feed);
    event SetRateExpiryTime(uint64 time);

    // Check employee exists by ID
    modifier employeeIdExists(uint256 _employeeId) {
        require(_employeeExists(_employeeId), ERROR_EMPLOYEE_DOESNT_EXIST);
        _;
    }

    // Check employee exists and is still active
    modifier employeeActive(uint256 _employeeId) {
        // No need to check for existence as _isEmployeeIdActive() is false for non-existent employees
        require(_isEmployeeIdActive(_employeeId), ERROR_NON_ACTIVE_EMPLOYEE);
        _;
    }

    // Check sender matches an existing employee
    modifier employeeMatches {
        require(employees[employeeIds[msg.sender]].accountAddress == msg.sender, ERROR_SENDER_DOES_NOT_MATCH);
        _;
    }

    /**
     * @notice Initialize Payroll app for Finance at `_finance` and price feed at `_priceFeed`, setting denomination token to `_token` and exchange rate expiry time to `@transformTime(_rateExpiryTime)`
     * @dev Note that we do not require _denominationToken to be a contract, as it may be a "fake"
     *      address used by the price feed to denominate fiat currencies
     * @param _finance Address of the Finance app this Payroll app will rely on for payments (non-changeable)
     * @param _denominationToken Address of the denomination token used for salary accounting
     * @param _priceFeed Address of the price feed
     * @param _rateExpiryTime Acceptable expiry time in seconds for the price feed's exchange rates
     */
    function initialize(Finance _finance, address _denominationToken, IFeed _priceFeed, uint64 _rateExpiryTime) external onlyInit {
        initialized();

        require(isContract(_finance), ERROR_FINANCE_NOT_CONTRACT);
        finance = _finance;

        denominationToken = _denominationToken;
        _setPriceFeed(_priceFeed);
        _setRateExpiryTime(_rateExpiryTime);

        // Employees start at index 1, to allow us to use employees[0] to check for non-existent employees
        nextEmployee = 1;
    }

    /**
     * @notice `_allowed ? 'Add' : 'Remove'` `_token.symbol(): string` `_allowed ? 'to' : 'from'` the set of allowed tokens
     * @param _token Address of the token to be added or removed from the list of allowed tokens for payments
     * @param _allowed Boolean to tell whether the given token should be added or removed from the list
     */
    function setAllowedToken(address _token, bool _allowed) external authP(MANAGE_ALLOWED_TOKENS_ROLE, arr(_token)) {
        require(allowedTokens[_token] != _allowed, ERROR_TOKEN_ALREADY_SET);
        allowedTokens[_token] = _allowed;
        emit SetAllowedToken(_token, _allowed);
    }

    /**
     * @notice Set the price feed for exchange rates to `_feed`
     * @param _feed Address of the new price feed instance
     */
    function setPriceFeed(IFeed _feed) external authP(MODIFY_PRICE_FEED_ROLE, arr(_feed, feed)) {
        _setPriceFeed(_feed);
    }

    /**
     * @notice Set the acceptable expiry time for the price feed's exchange rates to `@transformTime(_time)`
     * @dev Exchange rates older than the given value won't be accepted for payments and will cause payouts to revert
     * @param _time The expiration time in seconds for exchange rates
     */
    function setRateExpiryTime(uint64 _time) external authP(MODIFY_RATE_EXPIRY_ROLE, arr(uint256(_time), uint256(rateExpiryTime))) {
        _setRateExpiryTime(_time);
    }

    /**
     * @notice Add employee with address `_accountAddress` to payroll with an salary of `_initialDenominationSalary` per second, starting on `@formatDate(_startDate)`
     * @param _accountAddress Employee's address to receive payroll
     * @param _initialDenominationSalary Employee's salary, per second in denomination token
     * @param _startDate Employee's starting timestamp in seconds (it actually sets their initial lastPayroll value)
     * @param _role Employee's role
     */
    function addEmployee(address _accountAddress, uint256 _initialDenominationSalary, uint64 _startDate, string _role)
        external
        authP(ADD_EMPLOYEE_ROLE, arr(_accountAddress, _initialDenominationSalary, uint256(_startDate)))
    {
        _addEmployee(_accountAddress, _initialDenominationSalary, _startDate, _role);
    }

    /**
     * @notice Add `_amount` to bonus for employee #`_employeeId`
     * @param _employeeId Employee's identifier
     * @param _amount Amount to be added to the employee's bonuses in denomination token
     */
    function addBonus(uint256 _employeeId, uint256 _amount)
        external
        authP(ADD_BONUS_ROLE, arr(_employeeId, _amount))
        employeeActive(_employeeId)
    {
        _addBonus(_employeeId, _amount);
    }

    /**
     * @notice Add `_amount` to reimbursements for employee #`_employeeId`
     * @param _employeeId Employee's identifier
     * @param _amount Amount to be added to the employee's reimbursements in denomination token
     */
    function addReimbursement(uint256 _employeeId, uint256 _amount)
        external
        authP(ADD_REIMBURSEMENT_ROLE, arr(_employeeId, _amount))
        employeeActive(_employeeId)
    {
        _addReimbursement(_employeeId, _amount);
    }

    /**
     * @notice Set employee #`_employeeId`'s salary to `_denominationSalary` per second
     * @dev This reverts if either the employee's owed salary or accrued salary overflows, to avoid
     *      losing any accrued salary for an employee due to the employer changing their salary.
     * @param _employeeId Employee's identifier
     * @param _denominationSalary Employee's new salary, per second in denomination token
     */
    function setEmployeeSalary(uint256 _employeeId, uint256 _denominationSalary)
        external
        authP(SET_EMPLOYEE_SALARY_ROLE, arr(_employeeId, _denominationSalary, employees[_employeeId].denominationTokenSalary))
        employeeActive(_employeeId)
    {
        Employee storage employee = employees[_employeeId];

        // Accrue employee's owed salary; don't cap to revert on overflow
        uint256 owed = _getOwedSalarySinceLastPayroll(employee, false);
        _addAccruedSalary(_employeeId, owed);

        // Update employee to track the new salary and payment date
        employee.lastPayroll = getTimestamp64();
        employee.denominationTokenSalary = _denominationSalary;

        emit SetEmployeeSalary(_employeeId, _denominationSalary);
    }

    /**
     * @notice Terminate employee #`_employeeId` on `@formatDate(_endDate)`
     * @param _employeeId Employee's identifier
     * @param _endDate Termination timestamp in seconds
     */
    function terminateEmployee(uint256 _employeeId, uint64 _endDate)
        external
        authP(TERMINATE_EMPLOYEE_ROLE, arr(_employeeId, uint256(_endDate)))
        employeeActive(_employeeId)
    {
        _terminateEmployee(_employeeId, _endDate);
    }

    /**
     * @notice Change your employee account address to `_newAccountAddress`
     * @dev Initialization check is implicitly provided by `employeeMatches` as new employees can
     *      only be added via `addEmployee(),` which requires initialization.
     *      As the employee is allowed to call this, we enforce non-reentrancy.
     * @param _newAccountAddress New address to receive payments for the requesting employee
     */
    function changeAddressByEmployee(address _newAccountAddress) external employeeMatches nonReentrant {
        uint256 employeeId = employeeIds[msg.sender];
        address oldAddress = employees[employeeId].accountAddress;

        _setEmployeeAddress(employeeId, _newAccountAddress);
        // Don't delete the old address until after setting the new address to check that the
        // employee specified a new address
        delete employeeIds[oldAddress];

        emit ChangeAddressByEmployee(employeeId, _newAccountAddress, oldAddress);
    }

    /**
     * @notice Set the token distribution for your payments
     * @dev Initialization check is implicitly provided by `employeeMatches` as new employees can
     *      only be added via `addEmployee(),` which requires initialization.
     *      As the employee is allowed to call this, we enforce non-reentrancy.
     * @param _tokens Array of token addresses; they must belong to the list of allowed tokens
     * @param _distribution Array with each token's corresponding proportions (must be integers summing to 100)
     */
    function determineAllocation(address[] _tokens, uint256[] _distribution) external employeeMatches nonReentrant {
        // Check array lengthes match
        require(_tokens.length <= MAX_ALLOWED_TOKENS, ERROR_MAX_ALLOWED_TOKENS);
        require(_tokens.length == _distribution.length, ERROR_TOKEN_ALLOCATION_MISMATCH);

        uint256 employeeId = employeeIds[msg.sender];
        Employee storage employee = employees[employeeId];

        // Delete previous token allocations
        address[] memory previousAllowedTokenAddresses = employee.allocationTokenAddresses;
        for (uint256 j = 0; j < previousAllowedTokenAddresses.length; j++) {
            delete employee.allocationTokens[previousAllowedTokenAddresses[j]];
        }
        delete employee.allocationTokenAddresses;

        // Set distributions only if given tokens are allowed
        for (uint256 i = 0; i < _tokens.length; i++) {
            employee.allocationTokenAddresses.push(_tokens[i]);
            employee.allocationTokens[_tokens[i]] = _distribution[i];
        }

        _ensureEmployeeTokenAllocationsIsValid(employee);
        emit DetermineAllocation(employeeId);
    }

    /**
     * @notice Request your `_type == 0 ? 'salary' : _type == 1 ? 'reimbursements' : 'bonus'`
     * @dev Reverts if no payments were made.
     *      Initialization check is implicitly provided by `employeeMatches` as new employees can
     *      only be added via `addEmployee(),` which requires initialization.
     *      As the employee is allowed to call this, we enforce non-reentrancy.
     * @param _type Payment type being requested (Payroll, Reimbursement or Bonus)
     * @param _requestedAmount Requested amount to pay for the payment type. Must be less than or equal to total owed amount for the payment type, or zero to request all.
     * @param _minRates Array of employee's minimum acceptable rates for their allowed payment tokens
     */
    function payday(PaymentType _type, uint256 _requestedAmount, uint256[] _minRates) external employeeMatches nonReentrant {
        uint256 paymentAmount;
        uint256 employeeId = employeeIds[msg.sender];
        Employee storage employee = employees[employeeId];
        _ensureEmployeeTokenAllocationsIsValid(employee);
        require(_minRates.length == 0 || _minRates.length == employee.allocationTokenAddresses.length, ERROR_MIN_RATES_MISMATCH);

        // Do internal employee accounting
        if (_type == PaymentType.Payroll) {
            // Salary is capped here to avoid reverting at this point if it becomes too big
            // (so employees aren't DDOSed if their salaries get too large)
            // If we do use a capped value, the employee's lastPayroll date will be adjusted accordingly
            uint256 totalOwedSalary = _getTotalOwedCappedSalary(employee);
            paymentAmount = _ensurePaymentAmount(totalOwedSalary, _requestedAmount);
            _updateEmployeeAccountingBasedOnPaidSalary(employee, paymentAmount);
        } else if (_type == PaymentType.Reimbursement) {
            uint256 owedReimbursements = employee.reimbursements;
            paymentAmount = _ensurePaymentAmount(owedReimbursements, _requestedAmount);
            employee.reimbursements = owedReimbursements.sub(paymentAmount);
        } else if (_type == PaymentType.Bonus) {
            uint256 owedBonusAmount = employee.bonus;
            paymentAmount = _ensurePaymentAmount(owedBonusAmount, _requestedAmount);
            employee.bonus = owedBonusAmount.sub(paymentAmount);
        } else {
            revert(ERROR_INVALID_PAYMENT_TYPE);
        }

        // Actually transfer the owed funds
        require(_transferTokensAmount(employeeId, _type, paymentAmount, _minRates), ERROR_NOTHING_PAID);
        _removeEmployeeIfTerminatedAndPaidOut(employeeId);
    }

    // Forwarding fns

    /**
     * @dev IForwarder interface conformance. Tells whether the Payroll app is a forwarder or not.
     * @return Always true
     */
    function isForwarder() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Execute desired action as an active employee
     * @dev IForwarder interface conformance. Allows active employees to run EVMScripts in the context of the Payroll app.
     * @param _evmScript Script being executed
     */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript), ERROR_CAN_NOT_FORWARD);
        bytes memory input = new bytes(0); // TODO: Consider input for this

        // Add the Finance app to the blacklist to disallow employees from executing actions on the
        // Finance app from Payroll's context (since Payroll requires permissions on Finance)
        address[] memory blacklist = new address[](1);
        blacklist[0] = address(finance);

        runScript(_evmScript, input, blacklist);
    }

    /**
     * @dev IForwarder interface conformance. Tells whether a given address can forward actions or not.
     * @param _sender Address of the account intending to forward an action
     * @return True if the given address is an active employee, false otherwise
     */
    function canForward(address _sender, bytes) public view returns (bool) {
        return _isEmployeeIdActive(employeeIds[_sender]);
    }

    // Getter fns

    /**
     * @dev Return employee's identifier by their account address
     * @param _accountAddress Employee's address to receive payments
     * @return Employee's identifier
     */
    function getEmployeeIdByAddress(address _accountAddress) public view returns (uint256) {
        require(employeeIds[_accountAddress] != uint256(0), ERROR_EMPLOYEE_DOESNT_EXIST);
        return employeeIds[_accountAddress];
    }

    /**
     * @dev Return all information for employee by their ID
     * @param _employeeId Employee's identifier
     * @return Employee's address to receive payments
     * @return Employee's salary, per second in denomination token
     * @return Employee's accrued salary
     * @return Employee's bonus amount
     * @return Employee's reimbursements amount
     * @return Employee's last payment date
     * @return Employee's termination date (max uint64 if none)
     * @return Employee's allowed payment tokens
     */
    function getEmployee(uint256 _employeeId)
        public
        view
        employeeIdExists(_employeeId)
        returns (
            address accountAddress,
            uint256 denominationSalary,
            uint256 accruedSalary,
            uint256 bonus,
            uint256 reimbursements,
            uint64 lastPayroll,
            uint64 endDate,
            address[] allocationTokens
        )
    {
        Employee storage employee = employees[_employeeId];

        accountAddress = employee.accountAddress;
        denominationSalary = employee.denominationTokenSalary;
        accruedSalary = employee.accruedSalary;
        bonus = employee.bonus;
        reimbursements = employee.reimbursements;
        lastPayroll = employee.lastPayroll;
        endDate = employee.endDate;
        allocationTokens = employee.allocationTokenAddresses;
    }

    /**
     * @dev Get owed salary since last payroll for an employee. It will take into account the accrued salary as well.
     *      The result will be capped to max uint256 to avoid having an overflow.
     * @return Employee's total owed salary: current owed payroll since the last payroll date, plus the accrued salary.
     */
    function getTotalOwedSalary(uint256 _employeeId) public view employeeIdExists(_employeeId) returns (uint256) {
        return _getTotalOwedCappedSalary(employees[_employeeId]);
    }

    /**
     * @dev Get an employee's payment allocation for a token
     * @param _employeeId Employee's identifier
     * @param _token Token to query the payment allocation for
     * @return Employee's payment allocation for the token being queried
     */
    function getAllocation(uint256 _employeeId, address _token) public view employeeIdExists(_employeeId) returns (uint256) {
        return employees[_employeeId].allocationTokens[_token];
    }

    /**
     * @dev Check if a token is allowed to be used for payments
     * @param _token Address of the token to be checked
     * @return True if the given token is allowed, false otherwise
     */
    function isTokenAllowed(address _token) public view isInitialized returns (bool) {
        return allowedTokens[_token];
    }

    // Internal fns

    /**
     * @dev Set the price feed used for exchange rates
     * @param _feed Address of the new price feed instance
     */
    function _setPriceFeed(IFeed _feed) internal {
        require(isContract(_feed), ERROR_FEED_NOT_CONTRACT);
        feed = _feed;
        emit SetPriceFeed(feed);
    }

    /**
     * @dev Set the exchange rate expiry time in seconds.
     *      Exchange rates older than the given value won't be accepted for payments and will cause
     *      payouts to revert.
     * @param _time The expiration time in seconds for exchange rates
     */
    function _setRateExpiryTime(uint64 _time) internal {
        // Require a sane minimum for the rate expiry time
        require(_time >= MIN_RATE_EXPIRY, ERROR_EXPIRY_TIME_TOO_SHORT);
        rateExpiryTime = _time;
        emit SetRateExpiryTime(rateExpiryTime);
    }

    /**
     * @dev Add a new employee to Payroll
     * @param _accountAddress Employee's address to receive payroll
     * @param _initialDenominationSalary Employee's salary, per second in denomination token
     * @param _startDate Employee's starting timestamp in seconds
     * @param _role Employee's role
     */
    function _addEmployee(address _accountAddress, uint256 _initialDenominationSalary, uint64 _startDate, string _role) internal {
        uint256 employeeId = nextEmployee++;

        _setEmployeeAddress(employeeId, _accountAddress);

        Employee storage employee = employees[employeeId];
        employee.denominationTokenSalary = _initialDenominationSalary;
        employee.lastPayroll = _startDate;
        employee.endDate = MAX_UINT64;

        emit AddEmployee(employeeId, _accountAddress, _initialDenominationSalary, _startDate, _role);
    }

    /**
     * @dev Add amount to an employee's bonuses
     * @param _employeeId Employee's identifier
     * @param _amount Amount be added to the employee's bonuses in denomination token
     */
    function _addBonus(uint256 _employeeId, uint256 _amount) internal {
        Employee storage employee = employees[_employeeId];
        employee.bonus = employee.bonus.add(_amount);
        emit AddEmployeeBonus(_employeeId, _amount);
    }

    /**
     * @dev Add amount to an employee's reimbursements
     * @param _employeeId Employee's identifier
     * @param _amount Amount be added to the employee's reimbursements in denomination token
     */
    function _addReimbursement(uint256 _employeeId, uint256 _amount) internal {
        Employee storage employee = employees[_employeeId];
        employee.reimbursements = employee.reimbursements.add(_amount);
        emit AddEmployeeReimbursement(_employeeId, _amount);
    }

    /**
     * @dev Add amount to an employee's accrued salary
     * @param _employeeId Employee's identifier
     * @param _amount Amount be added to the employee's accrued salary in denomination token
     */
    function _addAccruedSalary(uint256 _employeeId, uint256 _amount) internal {
        Employee storage employee = employees[_employeeId];
        employee.accruedSalary = employee.accruedSalary.add(_amount);
        emit AddEmployeeAccruedSalary(_employeeId, _amount);
    }

    /**
     * @dev Set an employee's account address
     * @param _employeeId Employee's identifier
     * @param _accountAddress Employee's address to receive payroll
     */
    function _setEmployeeAddress(uint256 _employeeId, address _accountAddress) internal {
        // Check address is non-null
        require(_accountAddress != address(0), ERROR_EMPLOYEE_NULL_ADDRESS);
        // Check address isn't already being used
        require(employeeIds[_accountAddress] == uint256(0), ERROR_EMPLOYEE_ALREADY_EXIST);

        employees[_employeeId].accountAddress = _accountAddress;

        // Create IDs mapping
        employeeIds[_accountAddress] = _employeeId;
    }

    /**
     * @dev Terminate employee on end date
     * @param _employeeId Employee's identifier
     * @param _endDate Termination timestamp in seconds
     */
    function _terminateEmployee(uint256 _employeeId, uint64 _endDate) internal {
        // Prevent past termination dates
        require(_endDate >= getTimestamp64(), ERROR_PAST_TERMINATION_DATE);
        employees[_employeeId].endDate = _endDate;
        emit TerminateEmployee(_employeeId, _endDate);
    }

    /**
     * @dev Loop over allowed tokens to send requested amount to the employee in their desired allocation
     * @param _employeeId Employee's identifier
     * @param _totalAmount Total amount to be transferred to the employee distributed in accordance to the employee's token allocation.
     * @param _type Payment type being transferred (Payroll, Reimbursement or Bonus)
     * @param _minRates Array of employee's minimum acceptable rates for their allowed payment tokens
     * @return True if there was at least one token transfer
     */
    function _transferTokensAmount(uint256 _employeeId, PaymentType _type, uint256 _totalAmount, uint256[] _minRates) internal returns (bool somethingPaid) {
        if (_totalAmount == 0) {
            return false;
        }

        Employee storage employee = employees[_employeeId];
        address employeeAddress = employee.accountAddress;
        string memory paymentReference = _paymentReferenceFor(_type);

        address[] storage allocationTokenAddresses = employee.allocationTokenAddresses;
        for (uint256 i = 0; i < allocationTokenAddresses.length; i++) {
            address token = allocationTokenAddresses[i];
            uint256 tokenAllocation = employee.allocationTokens[token];
            if (tokenAllocation != uint256(0)) {
                // Get the exchange rate for the payout token in denomination token,
                // as we do accounting in denomination tokens
                uint256 exchangeRate = _getExchangeRateInDenominationToken(token);
                require(_minRates.length > 0 ? exchangeRate >= _minRates[i] : exchangeRate > 0, ERROR_EXCHANGE_RATE_TOO_LOW);

                // Convert amount (in denomination tokens) to payout token and apply allocation
                uint256 tokenAmount = _totalAmount.mul(exchangeRate).mul(tokenAllocation);
                // Divide by 100 for the allocation percentage and by the exchange rate precision
                tokenAmount = tokenAmount.div(100).div(feed.ratePrecision());

                // Finance reverts if the payment wasn't possible
                finance.newImmediatePayment(token, employeeAddress, tokenAmount, paymentReference);
                emit SendPayment(_employeeId, employeeAddress, token, tokenAmount, exchangeRate, paymentReference);
                somethingPaid = true;
            }
        }
    }

    /**
     * @dev Remove employee if there are no owed funds and employee's end date has been reached
     * @param _employeeId Employee's identifier
     */
    function _removeEmployeeIfTerminatedAndPaidOut(uint256 _employeeId) internal {
        Employee storage employee = employees[_employeeId];

        if (
            employee.lastPayroll == employee.endDate &&
            (employee.accruedSalary == 0 && employee.bonus == 0 && employee.reimbursements == 0)
        ) {
            delete employeeIds[employee.accountAddress];
            delete employees[_employeeId];
        }
    }

    /**
     * @dev Updates the accrued salary and payroll date of an employee based on a payment amount and
     *      their currently owed salary since last payroll date
     * @param _employee Employee struct in storage
     * @param _paymentAmount Amount being paid to the employee
     */
    function _updateEmployeeAccountingBasedOnPaidSalary(Employee storage _employee, uint256 _paymentAmount) internal {
        uint256 accruedSalary = _employee.accruedSalary;

        if (_paymentAmount <= accruedSalary) {
            // Employee is only cashing out some previously owed salary so we don't need to update
            // their last payroll date
            // No need to use SafeMath as we already know _paymentAmount <= accruedSalary
            _employee.accruedSalary = accruedSalary - _paymentAmount;
            return;
        }

        // Employee is cashing out some of their currently owed salary so their last payroll date
        // needs to be modified based on the amount of salary paid
        uint256 currentSalaryPaid = _paymentAmount;
        if (accruedSalary > 0) {
            // Employee is cashing out a mixed amount between previous and current owed salaries;
            // first use up their accrued salary
            // No need to use SafeMath here as we already know _paymentAmount > accruedSalary
            currentSalaryPaid = _paymentAmount - accruedSalary;
            // We finally need to clear their accrued salary
            _employee.accruedSalary = 0;
        }

        uint256 salary = _employee.denominationTokenSalary;
        uint256 timeDiff = currentSalaryPaid.div(salary);

        // If they're being paid an amount that doesn't match perfectly with the adjusted time
        // (up to a seconds' worth of salary), add the second and put the extra remaining salary
        // into their accrued salary
        uint256 extraSalary = currentSalaryPaid % salary;
        if (extraSalary > 0) {
            timeDiff = timeDiff.add(1);
            _employee.accruedSalary = salary - extraSalary;
        }

        uint256 lastPayrollDate = uint256(_employee.lastPayroll).add(timeDiff);
        // Even though this function should never receive a currentSalaryPaid value that would
        // result in the lastPayrollDate being higher than the current time,
        // let's double check to be safe
        require(lastPayrollDate <= uint256(getTimestamp64()), ERROR_LAST_PAYROLL_DATE_TOO_BIG);
        // Already know lastPayrollDate must fit in uint64 from above
        _employee.lastPayroll = uint64(lastPayrollDate);
    }

    /**
     * @dev Tell whether an employee is registered in this Payroll or not
     * @param _employeeId Employee's identifier
     * @return True if the given employee ID belongs to an registered employee, false otherwise
     */
    function _employeeExists(uint256 _employeeId) internal view returns (bool) {
        return employees[_employeeId].accountAddress != address(0);
    }

    /**
     * @dev Tell whether an employee has a valid token allocation or not.
     *      A valid allocation is one that sums to 100 and only includes allowed tokens.
     * @param _employee Employee struct in storage
     * @return Reverts if employee's allocation is invalid
     */
    function _ensureEmployeeTokenAllocationsIsValid(Employee storage _employee) internal view {
        uint256 sum = 0;
        address[] memory allocationTokenAddresses = _employee.allocationTokenAddresses;
        for (uint256 i = 0; i < allocationTokenAddresses.length; i++) {
            address token = allocationTokenAddresses[i];
            require(allowedTokens[token], ERROR_NOT_ALLOWED_TOKEN);
            sum = sum.add(_employee.allocationTokens[token]);
        }
        require(sum == 100, ERROR_DISTRIBUTION_NOT_FULL);
    }

    /**
     * @dev Tell whether an employee is still active or not
     * @param _employee Employee struct in storage
     * @return True if the employee exists and has an end date that has not been reached yet, false otherwise
     */
    function _isEmployeeActive(Employee storage _employee) internal view returns (bool) {
        return _employee.endDate >= getTimestamp64();
    }

    /**
     * @dev Tell whether an employee id is still active or not
     * @param _employeeId Employee's identifier
     * @return True if the employee exists and has an end date that has not been reached yet, false otherwise
     */
    function _isEmployeeIdActive(uint256 _employeeId) internal view returns (bool) {
        return _isEmployeeActive(employees[_employeeId]);
    }

    /**
     * @dev Get exchange rate for a token based on the denomination token.
     *      As an example, if the denomination token was USD and ETH's price was 100USD,
     *      this would return 0.01 * precision rate for ETH.
     * @param _token Token to get price of in denomination tokens
     * @return Exchange rate (multiplied by the PPF rate precision)
     */
    function _getExchangeRateInDenominationToken(address _token) internal view returns (uint256) {
        // xrt is the number of `_token` that can be exchanged for one `denominationToken`
        (uint128 xrt, uint64 when) = feed.get(
            denominationToken,  // Base (e.g. USD)
            _token              // Quote (e.g. ETH)
        );

        // Check the price feed is recent enough
        if (getTimestamp64().sub(when) >= rateExpiryTime) {
            return 0;
        }

        return uint256(xrt);
    }

    /**
     * @dev Get owed salary since last payroll for an employee
     * @param _employee Employee struct in storage
     * @param _capped Safely cap the owed salary at max uint
     * @return Owed salary in denomination tokens since last payroll for the employee.
     *         If _capped is false, it reverts in case of an overflow.
     */
    function _getOwedSalarySinceLastPayroll(Employee storage _employee, bool _capped) internal view returns (uint256) {
        uint256 timeDiff = _getOwedPayrollPeriod(_employee);
        if (timeDiff == 0) {
            return 0;
        }
        uint256 salary = _employee.denominationTokenSalary;

        if (_capped) {
            // Return max uint if the result overflows
            uint256 result = salary * timeDiff;
            return (result / timeDiff != salary) ? MAX_UINT256 : result;
        } else {
            return salary.mul(timeDiff);
        }
    }

    /**
     * @dev Get owed payroll period for an employee
     * @param _employee Employee struct in storage
     * @return Owed time in seconds since the employee's last payroll date
     */
    function _getOwedPayrollPeriod(Employee storage _employee) internal view returns (uint256) {
        // Get the min of current date and termination date
        uint64 date = _isEmployeeActive(_employee) ? getTimestamp64() : _employee.endDate;

        // Make sure we don't revert if we try to get the owed salary for an employee whose last
        // payroll date is now or in the future
        // This can happen either by adding new employees with start dates in the future, to allow
        // us to change their salary before their start date, or by terminating an employee and
        // paying out their full owed salary
        if (date <= _employee.lastPayroll) {
            return 0;
        }

        // Return time diff in seconds, no need to use SafeMath as the underflow was covered by the previous check
        return uint256(date - _employee.lastPayroll);
    }

    /**
     * @dev Get owed salary since last payroll for an employee. It will take into account the accrued salary as well.
     *      The result will be capped to max uint256 to avoid having an overflow.
     * @param _employee Employee struct in storage
     * @return Employee's total owed salary: current owed payroll since the last payroll date, plus the accrued salary.
     */
    function _getTotalOwedCappedSalary(Employee storage _employee) internal view returns (uint256) {
        uint256 currentOwedSalary = _getOwedSalarySinceLastPayroll(_employee, true); // cap amount
        uint256 totalOwedSalary = currentOwedSalary + _employee.accruedSalary;
        if (totalOwedSalary < currentOwedSalary) {
            totalOwedSalary = MAX_UINT256;
        }
        return totalOwedSalary;
    }

    /**
     * @dev Get payment reference for a given payment type
     * @param _type Payment type to query the reference of
     * @return Payment reference for the given payment type
     */
    function _paymentReferenceFor(PaymentType _type) internal pure returns (string memory) {
        if (_type == PaymentType.Payroll) {
            return "Employee salary";
        } else if (_type == PaymentType.Reimbursement) {
            return "Employee reimbursement";
        } if (_type == PaymentType.Bonus) {
            return "Employee bonus";
        }
        revert(ERROR_INVALID_PAYMENT_TYPE);
    }

    function _ensurePaymentAmount(uint256 _owedAmount, uint256 _requestedAmount) private pure returns (uint256) {
        require(_owedAmount > 0, ERROR_NOTHING_PAID);
        require(_owedAmount >= _requestedAmount, ERROR_INVALID_REQUESTED_AMOUNT);
        return _requestedAmount > 0 ? _requestedAmount : _owedAmount;
    }
}

// File: @aragon/apps-token-manager/contracts/TokenManager.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

/* solium-disable function-order */

pragma solidity 0.4.24;







contract TokenManager is ITokenController, IForwarder, AragonApp {
    using SafeMath for uint256;

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant ISSUE_ROLE = keccak256("ISSUE_ROLE");
    bytes32 public constant ASSIGN_ROLE = keccak256("ASSIGN_ROLE");
    bytes32 public constant REVOKE_VESTINGS_ROLE = keccak256("REVOKE_VESTINGS_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    uint256 public constant MAX_VESTINGS_PER_ADDRESS = 50;

    string private constant ERROR_CALLER_NOT_TOKEN = "TM_CALLER_NOT_TOKEN";
    string private constant ERROR_NO_VESTING = "TM_NO_VESTING";
    string private constant ERROR_TOKEN_CONTROLLER = "TM_TOKEN_CONTROLLER";
    string private constant ERROR_MINT_RECEIVER_IS_TM = "TM_MINT_RECEIVER_IS_TM";
    string private constant ERROR_VESTING_TO_TM = "TM_VESTING_TO_TM";
    string private constant ERROR_TOO_MANY_VESTINGS = "TM_TOO_MANY_VESTINGS";
    string private constant ERROR_WRONG_CLIFF_DATE = "TM_WRONG_CLIFF_DATE";
    string private constant ERROR_VESTING_NOT_REVOKABLE = "TM_VESTING_NOT_REVOKABLE";
    string private constant ERROR_REVOKE_TRANSFER_FROM_REVERTED = "TM_REVOKE_TRANSFER_FROM_REVERTED";
    string private constant ERROR_CAN_NOT_FORWARD = "TM_CAN_NOT_FORWARD";
    string private constant ERROR_BALANCE_INCREASE_NOT_ALLOWED = "TM_BALANCE_INC_NOT_ALLOWED";
    string private constant ERROR_ASSIGN_TRANSFER_FROM_REVERTED = "TM_ASSIGN_TRANSFER_FROM_REVERTED";

    struct TokenVesting {
        uint256 amount;
        uint64 start;
        uint64 cliff;
        uint64 vesting;
        bool revokable;
    }

    // Note that we COMPLETELY trust this MiniMeToken to not be malicious for proper operation of this contract
    MiniMeToken public token;
    uint256 public maxAccountTokens;

    // We are mimicing an array in the inner mapping, we use a mapping instead to make app upgrade more graceful
    mapping (address => mapping (uint256 => TokenVesting)) internal vestings;
    mapping (address => uint256) public vestingsLengths;

    // Other token specific events can be watched on the token address directly (avoids duplication)
    event NewVesting(address indexed receiver, uint256 vestingId, uint256 amount);
    event RevokeVesting(address indexed receiver, uint256 vestingId, uint256 nonVestedAmount);

    modifier onlyToken() {
        require(msg.sender == address(token), ERROR_CALLER_NOT_TOKEN);
        _;
    }

    modifier vestingExists(address _holder, uint256 _vestingId) {
        // TODO: it's not checking for gaps that may appear because of deletes in revokeVesting function
        require(_vestingId < vestingsLengths[_holder], ERROR_NO_VESTING);
        _;
    }

    /**
    * @notice Initialize Token Manager for `_token.symbol(): string`, whose tokens are `transferable ? 'not' : ''` transferable`_maxAccountTokens > 0 ? ' and limited to a maximum of ' + @tokenAmount(_token, _maxAccountTokens, false) + ' per account' : ''`
    * @param _token MiniMeToken address for the managed token (Token Manager instance must be already set as the token controller)
    * @param _transferable whether the token can be transferred by holders
    * @param _maxAccountTokens Maximum amount of tokens an account can have (0 for infinite tokens)
    */
    function initialize(
        MiniMeToken _token,
        bool _transferable,
        uint256 _maxAccountTokens
    )
        external
        onlyInit
    {
        initialized();

        require(_token.controller() == address(this), ERROR_TOKEN_CONTROLLER);

        token = _token;
        maxAccountTokens = _maxAccountTokens == 0 ? uint256(-1) : _maxAccountTokens;

        if (token.transfersEnabled() != _transferable) {
            token.enableTransfers(_transferable);
        }
    }

    /**
    * @notice Mint `@tokenAmount(self.token(): address, _amount, false)` tokens for `_receiver`
    * @param _receiver The address receiving the tokens, cannot be the Token Manager itself (use `issue()` instead)
    * @param _amount Number of tokens minted
    */
    function mint(address _receiver, uint256 _amount) external authP(MINT_ROLE, arr(_receiver, _amount)) {
        require(_receiver != address(this), ERROR_MINT_RECEIVER_IS_TM);
        _mint(_receiver, _amount);
    }

    /**
    * @notice Mint `@tokenAmount(self.token(): address, _amount, false)` tokens for the Token Manager
    * @param _amount Number of tokens minted
    */
    function issue(uint256 _amount) external authP(ISSUE_ROLE, arr(_amount)) {
        _mint(address(this), _amount);
    }

    /**
    * @notice Assign `@tokenAmount(self.token(): address, _amount, false)` tokens to `_receiver` from the Token Manager's holdings
    * @param _receiver The address receiving the tokens
    * @param _amount Number of tokens transferred
    */
    function assign(address _receiver, uint256 _amount) external authP(ASSIGN_ROLE, arr(_receiver, _amount)) {
        _assign(_receiver, _amount);
    }

    /**
    * @notice Burn `@tokenAmount(self.token(): address, _amount, false)` tokens from `_holder`
    * @param _holder Holder of tokens being burned
    * @param _amount Number of tokens being burned
    */
    function burn(address _holder, uint256 _amount) external authP(BURN_ROLE, arr(_holder, _amount)) {
        // minime.destroyTokens() never returns false, only reverts on failure
        token.destroyTokens(_holder, _amount);
    }

    /**
    * @notice Assign `@tokenAmount(self.token(): address, _amount, false)` tokens to `_receiver` from the Token Manager's holdings with a `_revokable : 'revokable' : ''` vesting starting at `@formatDate(_start)`, cliff at `@formatDate(_cliff)` (first portion of tokens transferable), and completed vesting at `@formatDate(_vested)` (all tokens transferable)
    * @param _receiver The address receiving the tokens, cannot be Token Manager itself
    * @param _amount Number of tokens vested
    * @param _start Date the vesting calculations start
    * @param _cliff Date when the initial portion of tokens are transferable
    * @param _vested Date when all tokens are transferable
    * @param _revokable Whether the vesting can be revoked by the Token Manager
    */
    function assignVested(
        address _receiver,
        uint256 _amount,
        uint64 _start,
        uint64 _cliff,
        uint64 _vested,
        bool _revokable
    )
        external
        authP(ASSIGN_ROLE, arr(_receiver, _amount))
        returns (uint256)
    {
        require(_receiver != address(this), ERROR_VESTING_TO_TM);
        require(vestingsLengths[_receiver] < MAX_VESTINGS_PER_ADDRESS, ERROR_TOO_MANY_VESTINGS);
        require(_start <= _cliff && _cliff <= _vested, ERROR_WRONG_CLIFF_DATE);

        uint256 vestingId = vestingsLengths[_receiver]++;
        vestings[_receiver][vestingId] = TokenVesting(
            _amount,
            _start,
            _cliff,
            _vested,
            _revokable
        );

        _assign(_receiver, _amount);

        emit NewVesting(_receiver, vestingId, _amount);

        return vestingId;
    }

    /**
    * @notice Revoke vesting #`_vestingId` from `_holder`, returning unvested tokens to the Token Manager
    * @param _holder Address whose vesting to revoke
    * @param _vestingId Numeric id of the vesting
    */
    function revokeVesting(address _holder, uint256 _vestingId)
        external
        authP(REVOKE_VESTINGS_ROLE, arr(_holder))
        vestingExists(_holder, _vestingId)
    {
        TokenVesting storage v = vestings[_holder][_vestingId];
        require(v.revokable, ERROR_VESTING_NOT_REVOKABLE);

        uint256 nonVested = _calculateNonVestedTokens(
            v.amount,
            getTimestamp(),
            v.start,
            v.cliff,
            v.vesting
        );

        // To make vestingIds immutable over time, we just zero out the revoked vesting
        // Clearing this out also allows the token transfer back to the Token Manager to succeed
        delete vestings[_holder][_vestingId];

        // transferFrom always works as controller
        // onTransfer hook always allows if transfering to token controller
        require(token.transferFrom(_holder, address(this), nonVested), ERROR_REVOKE_TRANSFER_FROM_REVERTED);

        emit RevokeVesting(_holder, _vestingId, nonVested);
    }

    // ITokenController fns
    // `onTransfer()`, `onApprove()`, and `proxyPayment()` are callbacks from the MiniMe token
    // contract and are only meant to be called through the managed MiniMe token that gets assigned
    // during initialization.

    /*
    * @dev Notifies the controller about a token transfer allowing the controller to decide whether
    *      to allow it or react if desired (only callable from the token).
    *      Initialization check is implicitly provided by `onlyToken()`.
    * @param _from The origin of the transfer
    * @param _to The destination of the transfer
    * @param _amount The amount of the transfer
    * @return False if the controller does not authorize the transfer
    */
    function onTransfer(address _from, address _to, uint256 _amount) external onlyToken returns (bool) {
        return _isBalanceIncreaseAllowed(_to, _amount) && _transferableBalance(_from, getTimestamp()) >= _amount;
    }

    /**
    * @dev Notifies the controller about an approval allowing the controller to react if desired
    *      Initialization check is implicitly provided by `onlyToken()`.
    * @return False if the controller does not authorize the approval
    */
    function onApprove(address, address, uint) external onlyToken returns (bool) {
        return true;
    }

    /**
    * @dev Called when ether is sent to the MiniMe Token contract
    *      Initialization check is implicitly provided by `onlyToken()`.
    * @return True if the ether is accepted, false for it to throw
    */
    function proxyPayment(address) external payable onlyToken returns (bool) {
        return false;
    }

    // Forwarding fns

    function isForwarder() external pure returns (bool) {
        return true;
    }

    /**
    * @notice Execute desired action as a token holder
    * @dev IForwarder interface conformance. Forwards any token holder action.
    * @param _evmScript Script being executed
    */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript), ERROR_CAN_NOT_FORWARD);
        bytes memory input = new bytes(0); // TODO: Consider input for this

        // Add the managed token to the blacklist to disallow a token holder from executing actions
        // on the token controller's (this contract) behalf
        address[] memory blacklist = new address[](1);
        blacklist[0] = address(token);

        runScript(_evmScript, input, blacklist);
    }

    function canForward(address _sender, bytes) public view returns (bool) {
        return hasInitialized() && token.balanceOf(_sender) > 0;
    }

    // Getter fns

    function getVesting(
        address _recipient,
        uint256 _vestingId
    )
        public
        view
        vestingExists(_recipient, _vestingId)
        returns (
            uint256 amount,
            uint64 start,
            uint64 cliff,
            uint64 vesting,
            bool revokable
        )
    {
        TokenVesting storage tokenVesting = vestings[_recipient][_vestingId];
        amount = tokenVesting.amount;
        start = tokenVesting.start;
        cliff = tokenVesting.cliff;
        vesting = tokenVesting.vesting;
        revokable = tokenVesting.revokable;
    }

    function spendableBalanceOf(address _holder) public view isInitialized returns (uint256) {
        return _transferableBalance(_holder, getTimestamp());
    }

    function transferableBalance(address _holder, uint256 _time) public view isInitialized returns (uint256) {
        return _transferableBalance(_holder, _time);
    }

    /**
    * @dev Disable recovery escape hatch for own token,
    *      as the it has the concept of issuing tokens without assigning them
    */
    function allowRecoverability(address _token) public view returns (bool) {
        return _token != address(token);
    }

    // Internal fns

    function _assign(address _receiver, uint256 _amount) internal {
        require(_isBalanceIncreaseAllowed(_receiver, _amount), ERROR_BALANCE_INCREASE_NOT_ALLOWED);
        // Must use transferFrom() as transfer() does not give the token controller full control
        require(token.transferFrom(address(this), _receiver, _amount), ERROR_ASSIGN_TRANSFER_FROM_REVERTED);
    }

    function _mint(address _receiver, uint256 _amount) internal {
        require(_isBalanceIncreaseAllowed(_receiver, _amount), ERROR_BALANCE_INCREASE_NOT_ALLOWED);
        token.generateTokens(_receiver, _amount); // minime.generateTokens() never returns false
    }

    function _isBalanceIncreaseAllowed(address _receiver, uint256 _inc) internal view returns (bool) {
        // Max balance doesn't apply to the token manager itself
        if (_receiver == address(this)) {
            return true;
        }
        return token.balanceOf(_receiver).add(_inc) <= maxAccountTokens;
    }

    /**
    * @dev Calculate amount of non-vested tokens at a specifc time
    * @param tokens The total amount of tokens vested
    * @param time The time at which to check
    * @param start The date vesting started
    * @param cliff The cliff period
    * @param vested The fully vested date
    * @return The amount of non-vested tokens of a specific grant
    *  transferableTokens
    *   |                         _/--------   vestedTokens rect
    *   |                       _/
    *   |                     _/
    *   |                   _/
    *   |                 _/
    *   |                /
    *   |              .|
    *   |            .  |
    *   |          .    |
    *   |        .      |
    *   |      .        |
    *   |    .          |
    *   +===+===========+---------+----------> time
    *      Start       Cliff    Vested
    */
    function _calculateNonVestedTokens(
        uint256 tokens,
        uint256 time,
        uint256 start,
        uint256 cliff,
        uint256 vested
    )
        private
        pure
        returns (uint256)
    {
        // Shortcuts for before cliff and after vested cases.
        if (time >= vested) {
            return 0;
        }
        if (time < cliff) {
            return tokens;
        }

        // Interpolate all vested tokens.
        // As before cliff the shortcut returns 0, we can just calculate a value
        // in the vesting rect (as shown in above's figure)

        // vestedTokens = tokens * (time - start) / (vested - start)
        // In assignVesting we enforce start <= cliff <= vested
        // Here we shortcut time >= vested and time < cliff,
        // so no division by 0 is possible
        uint256 vestedTokens = tokens.mul(time.sub(start)) / vested.sub(start);

        // tokens - vestedTokens
        return tokens.sub(vestedTokens);
    }

    function _transferableBalance(address _holder, uint256 _time) internal view returns (uint256) {
        uint256 transferable = token.balanceOf(_holder);

        // This check is not strictly necessary for the current version of this contract, as
        // Token Managers now cannot assign vestings to themselves.
        // However, this was a possibility in the past, so in case there were vestings assigned to
        // themselves, this will still return the correct value (entire balance, as the Token
        // Manager does not have a spending limit on its own balance).
        if (_holder != address(this)) {
            uint256 vestingsCount = vestingsLengths[_holder];
            for (uint256 i = 0; i < vestingsCount; i++) {
                TokenVesting storage v = vestings[_holder][i];
                uint256 nonTransferable = _calculateNonVestedTokens(
                    v.amount,
                    _time,
                    v.start,
                    v.cliff,
                    v.vesting
                );
                transferable = transferable.sub(nonTransferable);
            }
        }

        return transferable;
    }
}

// File: @aragon/apps-survey/contracts/Survey.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;






contract Survey is AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    bytes32 public constant CREATE_SURVEYS_ROLE = keccak256("CREATE_SURVEYS_ROLE");
    bytes32 public constant MODIFY_PARTICIPATION_ROLE = keccak256("MODIFY_PARTICIPATION_ROLE");

    uint64 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10^16; 100% = 10^18
    uint256 public constant ABSTAIN_VOTE = 0;

    string private constant ERROR_MIN_PARTICIPATION = "SURVEY_MIN_PARTICIPATION";
    string private constant ERROR_NO_SURVEY = "SURVEY_NO_SURVEY";
    string private constant ERROR_NO_VOTING_POWER = "SURVEY_NO_VOTING_POWER";
    string private constant ERROR_CAN_NOT_VOTE = "SURVEY_CAN_NOT_VOTE";
    string private constant ERROR_VOTE_WRONG_INPUT = "SURVEY_VOTE_WRONG_INPUT";
    string private constant ERROR_VOTE_WRONG_OPTION = "SURVEY_VOTE_WRONG_OPTION";
    string private constant ERROR_NO_STAKE = "SURVEY_NO_STAKE";
    string private constant ERROR_OPTIONS_NOT_ORDERED = "SURVEY_OPTIONS_NOT_ORDERED";
    string private constant ERROR_NO_OPTION = "SURVEY_NO_OPTION";

    struct OptionCast {
        uint256 optionId;
        uint256 stake;
    }

    /* Allows for multiple option votes.
     * Index 0 is always used for the ABSTAIN_VOTE option, that's calculated automatically by the
     * contract.
     */
    struct MultiOptionVote {
        uint256 optionsCastedLength;
        // `castedVotes` simulates an array
        // Each OptionCast in `castedVotes` must be ordered by ascending option IDs
        mapping (uint256 => OptionCast) castedVotes;
    }

    struct SurveyStruct {
        uint64 startDate;
        uint64 snapshotBlock;
        uint64 minParticipationPct;
        uint256 options;
        uint256 votingPower;                    // total tokens that can cast a vote
        uint256 participation;                  // tokens that casted a vote

        // Note that option IDs are from 1 to `options`, due to ABSTAIN_VOTE taking 0
        mapping (uint256 => uint256) optionPower;       // option ID -> voting power for option
        mapping (address => MultiOptionVote) votes;     // voter -> options voted, with its stakes
    }

    MiniMeToken public token;
    uint64 public minParticipationPct;
    uint64 public surveyTime;

    // We are mimicing an array, we use a mapping instead to make app upgrade more graceful
    mapping (uint256 => SurveyStruct) internal surveys;
    uint256 public surveysLength;

    event StartSurvey(uint256 indexed surveyId, address indexed creator, string metadata);
    event CastVote(uint256 indexed surveyId, address indexed voter, uint256 option, uint256 stake, uint256 optionPower);
    event ResetVote(uint256 indexed surveyId, address indexed voter, uint256 option, uint256 previousStake, uint256 optionPower);
    event ChangeMinParticipation(uint64 minParticipationPct);

    modifier acceptableMinParticipationPct(uint64 _minParticipationPct) {
        require(_minParticipationPct > 0 && _minParticipationPct <= PCT_BASE, ERROR_MIN_PARTICIPATION);
        _;
    }

    modifier surveyExists(uint256 _surveyId) {
        require(_surveyId < surveysLength, ERROR_NO_SURVEY);
        _;
    }

    /**
    * @notice Initialize Survey app with `_token.symbol(): string` for governance, minimum acceptance participation of `@formatPct(_minParticipationPct)`%, and a voting duration of `@transformTime(_surveyTime)`
    * @param _token MiniMeToken address that will be used as governance token
    * @param _minParticipationPct Percentage of total voting power that must participate in a survey for it to be taken into account (expressed as a 10^18 percentage, (eg 10^16 = 1%, 10^18 = 100%)
    * @param _surveyTime Seconds that a survey will be open for token holders to vote
    */
    function initialize(
        MiniMeToken _token,
        uint64 _minParticipationPct,
        uint64 _surveyTime
    )
        external
        onlyInit
        acceptableMinParticipationPct(_minParticipationPct)
    {
        initialized();

        token = _token;
        minParticipationPct = _minParticipationPct;
        surveyTime = _surveyTime;
    }

    /**
    * @notice Change minimum acceptance participation to `@formatPct(_minParticipationPct)`%
    * @param _minParticipationPct New acceptance participation
    */
    function changeMinAcceptParticipationPct(uint64 _minParticipationPct)
        external
        authP(MODIFY_PARTICIPATION_ROLE, arr(uint256(_minParticipationPct), uint256(minParticipationPct)))
        acceptableMinParticipationPct(_minParticipationPct)
    {
        minParticipationPct = _minParticipationPct;

        emit ChangeMinParticipation(_minParticipationPct);
    }

    /**
    * @notice Create a new non-binding survey about "`_metadata`"
    * @param _metadata Survey metadata
    * @param _options Number of options voters can decide between
    * @return surveyId id for newly created survey
    */
    function newSurvey(string _metadata, uint256 _options) external auth(CREATE_SURVEYS_ROLE) returns (uint256 surveyId) {
        uint64 snapshotBlock = getBlockNumber64() - 1; // avoid double voting in this very block
        uint256 votingPower = token.totalSupplyAt(snapshotBlock);
        require(votingPower > 0, ERROR_NO_VOTING_POWER);

        surveyId = surveysLength++;

        SurveyStruct storage survey = surveys[surveyId];
        survey.startDate = getTimestamp64();
        survey.snapshotBlock = snapshotBlock; // avoid double voting in this very block
        survey.minParticipationPct = minParticipationPct;
        survey.options = _options;
        survey.votingPower = votingPower;

        emit StartSurvey(surveyId, msg.sender, _metadata);
    }

    /**
    * @notice Reset previously casted vote in survey #`_surveyId`, if any.
    * @dev Initialization check is implicitly provided by `surveyExists()` as new surveys can only
    *      be created via `newSurvey(),` which requires initialization
    * @param _surveyId Id for survey
    */
    function resetVote(uint256 _surveyId) external surveyExists(_surveyId) {
        require(canVote(_surveyId, msg.sender), ERROR_CAN_NOT_VOTE);

        _resetVote(_surveyId);
    }

    /**
    * @notice Vote for multiple options in survey #`_surveyId`.
    * @dev Initialization check is implicitly provided by `surveyExists()` as new surveys can only
    *      be created via `newSurvey(),` which requires initialization
    * @param _surveyId Id for survey
    * @param _optionIds Array with indexes of supported options
    * @param _stakes Number of tokens assigned to each option
    */
    function voteOptions(uint256 _surveyId, uint256[] _optionIds, uint256[] _stakes)
        external
        surveyExists(_surveyId)
    {
        require(_optionIds.length == _stakes.length && _optionIds.length > 0, ERROR_VOTE_WRONG_INPUT);
        require(canVote(_surveyId, msg.sender), ERROR_CAN_NOT_VOTE);

        _voteOptions(_surveyId, _optionIds, _stakes);
    }

    /**
    * @notice Vote option #`_optionId` in survey #`_surveyId`.
    * @dev Initialization check is implicitly provided by `surveyExists()` as new surveys can only
    *      be created via `newSurvey(),` which requires initialization
    * @dev It will use the whole balance.
    * @param _surveyId Id for survey
    * @param _optionId Index of supported option
    */
    function voteOption(uint256 _surveyId, uint256 _optionId) external surveyExists(_surveyId) {
        require(canVote(_surveyId, msg.sender), ERROR_CAN_NOT_VOTE);

        SurveyStruct storage survey = surveys[_surveyId];
        // This could re-enter, though we can asume the governance token is not maliciuous
        uint256 voterStake = token.balanceOfAt(msg.sender, survey.snapshotBlock);
        uint256[] memory options = new uint256[](1);
        uint256[] memory stakes = new uint256[](1);
        options[0] = _optionId;
        stakes[0] = voterStake;

        _voteOptions(_surveyId, options, stakes);
    }

    // Getter fns

    function canVote(uint256 _surveyId, address _voter) public view surveyExists(_surveyId) returns (bool) {
        SurveyStruct storage survey = surveys[_surveyId];

        return _isSurveyOpen(survey) && token.balanceOfAt(_voter, survey.snapshotBlock) > 0;
    }

    function getSurvey(uint256 _surveyId)
        public
        view
        surveyExists(_surveyId)
        returns (
            bool open,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 minParticipation,
            uint256 votingPower,
            uint256 participation,
            uint256 options
        )
    {
        SurveyStruct storage survey = surveys[_surveyId];

        open = _isSurveyOpen(survey);
        startDate = survey.startDate;
        snapshotBlock = survey.snapshotBlock;
        minParticipation = survey.minParticipationPct;
        votingPower = survey.votingPower;
        participation = survey.participation;
        options = survey.options;
    }

    /**
    * @dev This is not meant to be used on-chain
    */
    /* solium-disable-next-line function-order */
    function getVoterState(uint256 _surveyId, address _voter)
        external
        view
        surveyExists(_surveyId)
        returns (uint256[] options, uint256[] stakes)
    {
        MultiOptionVote storage vote = surveys[_surveyId].votes[_voter];

        if (vote.optionsCastedLength == 0) {
            return (new uint256[](0), new uint256[](0));
        }

        options = new uint256[](vote.optionsCastedLength + 1);
        stakes = new uint256[](vote.optionsCastedLength + 1);
        for (uint256 i = 0; i <= vote.optionsCastedLength; i++) {
            options[i] = vote.castedVotes[i].optionId;
            stakes[i] = vote.castedVotes[i].stake;
        }
    }

    function getOptionPower(uint256 _surveyId, uint256 _optionId) public view surveyExists(_surveyId) returns (uint256) {
        SurveyStruct storage survey = surveys[_surveyId];
        require(_optionId <= survey.options, ERROR_NO_OPTION);

        return survey.optionPower[_optionId];
    }

    function isParticipationAchieved(uint256 _surveyId) public view surveyExists(_surveyId) returns (bool) {
        SurveyStruct storage survey = surveys[_surveyId];
        // votingPower is always > 0
        uint256 participationPct = survey.participation.mul(PCT_BASE) / survey.votingPower;
        return participationPct >= survey.minParticipationPct;
    }

    // Internal fns

    /*
    * @dev Assumes the survey exists and that msg.sender can vote
    */
    function _resetVote(uint256 _surveyId) internal {
        SurveyStruct storage survey = surveys[_surveyId];
        MultiOptionVote storage previousVote = survey.votes[msg.sender];
        if (previousVote.optionsCastedLength > 0) {
            // Voter removes their vote (index 0 is the abstain vote)
            for (uint256 i = 1; i <= previousVote.optionsCastedLength; i++) {
                OptionCast storage previousOptionCast = previousVote.castedVotes[i];
                uint256 previousOptionPower = survey.optionPower[previousOptionCast.optionId];
                uint256 currentOptionPower = previousOptionPower.sub(previousOptionCast.stake);
                survey.optionPower[previousOptionCast.optionId] = currentOptionPower;

                emit ResetVote(_surveyId, msg.sender, previousOptionCast.optionId, previousOptionCast.stake, currentOptionPower);
            }

            // Compute previously casted votes (i.e. substract non-used tokens from stake)
            uint256 voterStake = token.balanceOfAt(msg.sender, survey.snapshotBlock);
            uint256 previousParticipation = voterStake.sub(previousVote.castedVotes[0].stake);
            // And remove it from total participation
            survey.participation = survey.participation.sub(previousParticipation);

            // Reset previously voted options
            delete survey.votes[msg.sender];
        }
    }

    /*
    * @dev Assumes the survey exists and that msg.sender can vote
    */
    function _voteOptions(uint256 _surveyId, uint256[] _optionIds, uint256[] _stakes) internal {
        SurveyStruct storage survey = surveys[_surveyId];
        MultiOptionVote storage senderVotes = survey.votes[msg.sender];

        // Revert previous votes, if any
        _resetVote(_surveyId);

        uint256 totalVoted = 0;
        // Reserve first index for ABSTAIN_VOTE
        senderVotes.castedVotes[0] = OptionCast({ optionId: ABSTAIN_VOTE, stake: 0 });
        for (uint256 optionIndex = 1; optionIndex <= _optionIds.length; optionIndex++) {
            // Voters don't specify that they're abstaining,
            // but we still keep track of this by reserving the first index of a survey's votes.
            // We subtract 1 from the indexes of the arrays passed in by the voter to account for this.
            uint256 optionId = _optionIds[optionIndex - 1];
            uint256 stake = _stakes[optionIndex - 1];

            require(optionId != ABSTAIN_VOTE && optionId <= survey.options, ERROR_VOTE_WRONG_OPTION);
            require(stake > 0, ERROR_NO_STAKE);
            // Let's avoid repeating an option by making sure that ascending order is preserved in
            // the options array by checking that the current optionId is larger than the last one
            // we added
            require(senderVotes.castedVotes[optionIndex - 1].optionId < optionId, ERROR_OPTIONS_NOT_ORDERED);

            // Register voter amount
            senderVotes.castedVotes[optionIndex] = OptionCast({ optionId: optionId, stake: stake });

            // Add to total option support
            survey.optionPower[optionId] = survey.optionPower[optionId].add(stake);

            // Keep track of stake used so far
            totalVoted = totalVoted.add(stake);

            emit CastVote(_surveyId, msg.sender, optionId, stake, survey.optionPower[optionId]);
        }

        // Compute and register non used tokens
        // Implictly we are doing require(totalVoted <= voterStake) too
        // (as stated before, index 0 is for ABSTAIN_VOTE option)
        uint256 voterStake = token.balanceOfAt(msg.sender, survey.snapshotBlock);
        senderVotes.castedVotes[0].stake = voterStake.sub(totalVoted);

        // Register number of options voted
        senderVotes.optionsCastedLength = _optionIds.length;

        // Add voter tokens to participation
        survey.participation = survey.participation.add(totalVoted);
        assert(survey.participation <= survey.votingPower);
    }

    function _isSurveyOpen(SurveyStruct storage _survey) internal view returns (bool) {
        return getTimestamp64() < _survey.startDate.add(surveyTime);
    }
}

// File: @aragon/os/contracts/acl/IACLOracle.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IACLOracle {
    function canPerform(address who, address where, bytes32 what, uint256[] how) external view returns (bool);
}

// File: @aragon/os/contracts/acl/ACL.sol

pragma solidity 0.4.24;








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

    uint256 internal constant ORACLE_CHECK_GAS = 30000;

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
        uint256 oracleCheckGas = ORACLE_CHECK_GAS;

        bool ok;
        assembly {
            ok := staticcall(oracleCheckGas, _oracleAddr, add(checkCalldata, 0x20), mload(checkCalldata), 0, 0)
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

// File: @aragon/os/contracts/apm/Repo.sol

pragma solidity 0.4.24;



/* solium-disable function-order */
// Allow public initialize() to be first
contract Repo is AragonApp {
    /* Hardcoded constants to save gas
    bytes32 public constant CREATE_VERSION_ROLE = keccak256("CREATE_VERSION_ROLE");
    */
    bytes32 public constant CREATE_VERSION_ROLE = 0x1f56cfecd3595a2e6cc1a7e6cb0b20df84cdbd92eff2fee554e70e4e45a9a7d8;

    string private constant ERROR_INVALID_BUMP = "REPO_INVALID_BUMP";
    string private constant ERROR_INVALID_VERSION = "REPO_INVALID_VERSION";
    string private constant ERROR_INEXISTENT_VERSION = "REPO_INEXISTENT_VERSION";

    struct Version {
        uint16[3] semanticVersion;
        address contractAddress;
        bytes contentURI;
    }

    uint256 internal versionsNextIndex;
    mapping (uint256 => Version) internal versions;
    mapping (bytes32 => uint256) internal versionIdForSemantic;
    mapping (address => uint256) internal latestVersionIdForContract;

    event NewVersion(uint256 versionId, uint16[3] semanticVersion);

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initialize this Repo
    */
    function initialize() public onlyInit {
        initialized();
        versionsNextIndex = 1;
    }

    /**
    * @notice Create new version with contract `_contractAddress` and content `@fromHex(_contentURI)`
    * @param _newSemanticVersion Semantic version for new repo version
    * @param _contractAddress address for smart contract logic for version (if set to 0, it uses last versions' contractAddress)
    * @param _contentURI External URI for fetching new version's content
    */
    function newVersion(
        uint16[3] _newSemanticVersion,
        address _contractAddress,
        bytes _contentURI
    ) public auth(CREATE_VERSION_ROLE)
    {
        address contractAddress = _contractAddress;
        uint256 lastVersionIndex = versionsNextIndex - 1;

        uint16[3] memory lastSematicVersion;

        if (lastVersionIndex > 0) {
            Version storage lastVersion = versions[lastVersionIndex];
            lastSematicVersion = lastVersion.semanticVersion;

            if (contractAddress == address(0)) {
                contractAddress = lastVersion.contractAddress;
            }
            // Only allows smart contract change on major version bumps
            require(
                lastVersion.contractAddress == contractAddress || _newSemanticVersion[0] > lastVersion.semanticVersion[0],
                ERROR_INVALID_VERSION
            );
        }

        require(isValidBump(lastSematicVersion, _newSemanticVersion), ERROR_INVALID_BUMP);

        uint256 versionId = versionsNextIndex++;
        versions[versionId] = Version(_newSemanticVersion, contractAddress, _contentURI);
        versionIdForSemantic[semanticVersionHash(_newSemanticVersion)] = versionId;
        latestVersionIdForContract[contractAddress] = versionId;

        emit NewVersion(versionId, _newSemanticVersion);
    }

    function getLatest() public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(versionsNextIndex - 1);
    }

    function getLatestForContractAddress(address _contractAddress)
        public
        view
        returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI)
    {
        return getByVersionId(latestVersionIdForContract[_contractAddress]);
    }

    function getBySemanticVersion(uint16[3] _semanticVersion)
        public
        view
        returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI)
    {
        return getByVersionId(versionIdForSemantic[semanticVersionHash(_semanticVersion)]);
    }

    function getByVersionId(uint _versionId) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        require(_versionId > 0 && _versionId < versionsNextIndex, ERROR_INEXISTENT_VERSION);
        Version storage version = versions[_versionId];
        return (version.semanticVersion, version.contractAddress, version.contentURI);
    }

    function getVersionsCount() public view returns (uint256) {
        return versionsNextIndex - 1;
    }

    function isValidBump(uint16[3] _oldVersion, uint16[3] _newVersion) public pure returns (bool) {
        bool hasBumped;
        uint i = 0;
        while (i < 3) {
            if (hasBumped) {
                if (_newVersion[i] != 0) {
                    return false;
                }
            } else if (_newVersion[i] != _oldVersion[i]) {
                if (_oldVersion[i] > _newVersion[i] || _newVersion[i] - _oldVersion[i] != 1) {
                    return false;
                }
                hasBumped = true;
            }
            i++;
        }
        return hasBumped;
    }

    function semanticVersionHash(uint16[3] version) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(version[0], version[1], version[2]));
    }
}

// File: @aragon/os/contracts/apm/APMNamehash.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract APMNamehash {
    /* Hardcoded constants to save gas
    bytes32 internal constant APM_NODE = keccak256(abi.encodePacked(ETH_TLD_NODE, keccak256(abi.encodePacked("aragonpm"))));
    */
    bytes32 internal constant APM_NODE = 0x9065c3e7f7b7ef1ef4e53d2d0b8e0cef02874ab020c1ece79d5f0d3d0111c0ba;

    function apmNamehash(string name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(APM_NODE, keccak256(bytes(name))));
    }
}

// File: @aragon/os/contracts/kernel/KernelStorage.sol

pragma solidity 0.4.24;


contract KernelStorage {
    // namespace => app id => address
    mapping (bytes32 => mapping (bytes32 => address)) public apps;
    bytes32 public recoveryVaultAppId;
}

// File: @aragon/os/contracts/lib/misc/ERCProxy.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract ERCProxy {
    uint256 internal constant FORWARDING = 1;
    uint256 internal constant UPGRADEABLE = 2;

    function proxyType() public pure returns (uint256 proxyTypeId);
    function implementation() public view returns (address codeAddr);
}

// File: @aragon/os/contracts/common/DelegateProxy.sol

pragma solidity 0.4.24;




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

// File: @aragon/os/contracts/common/DepositableDelegateProxy.sol

pragma solidity 0.4.24;




contract DepositableDelegateProxy is DepositableStorage, DelegateProxy {
    event ProxyDeposit(address sender, uint256 value);

    function () external payable {
        // send / transfer
        if (gasleft() < FWD_GAS_LIMIT) {
            require(msg.value > 0 && msg.data.length == 0);
            require(isDepositable());
            emit ProxyDeposit(msg.sender, msg.value);
        } else { // all calls except for send or transfer
            address target = implementation();
            delegatedFwd(target, msg.data);
        }
    }
}

// File: @aragon/os/contracts/apps/AppProxyBase.sol

pragma solidity 0.4.24;






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

// File: @aragon/os/contracts/apps/AppProxyUpgradeable.sol

pragma solidity 0.4.24;



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

// File: @aragon/os/contracts/apps/AppProxyPinned.sol

pragma solidity 0.4.24;





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

// File: @aragon/os/contracts/factory/AppProxyFactory.sol

pragma solidity 0.4.24;




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

// File: @aragon/os/contracts/kernel/Kernel.sol

pragma solidity 0.4.24;













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

// File: @aragon/os/contracts/lib/ens/AbstractENS.sol

// See https://github.com/ensdomains/ens/blob/7e377df83f/contracts/AbstractENS.sol

pragma solidity ^0.4.15;


interface AbstractENS {
    function owner(bytes32 _node) public constant returns (address);
    function resolver(bytes32 _node) public constant returns (address);
    function ttl(bytes32 _node) public constant returns (uint64);
    function setOwner(bytes32 _node, address _owner) public;
    function setSubnodeOwner(bytes32 _node, bytes32 label, address _owner) public;
    function setResolver(bytes32 _node, address _resolver) public;
    function setTTL(bytes32 _node, uint64 _ttl) public;

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed _node, address _owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed _node, address _resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed _node, uint64 _ttl);
}

// File: @aragon/os/contracts/lib/ens/ENS.sol

// See https://github.com/ensdomains/ens/blob/7e377df83f/contracts/ENS.sol

pragma solidity ^0.4.0;


/**
 * The ENS registry contract.
 */
contract ENS is AbstractENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

    // Permits modifications only by the owner of the specified node.
    modifier only_owner(bytes32 node) {
        if (records[node].owner != msg.sender) throw;
        _;
    }

    /**
     * Constructs a new ENS registrar.
     */
    function ENS() public {
        records[0].owner = msg.sender;
    }

    /**
     * Returns the address that owns the specified node.
     */
    function owner(bytes32 node) public constant returns (address) {
        return records[node].owner;
    }

    /**
     * Returns the address of the resolver for the specified node.
     */
    function resolver(bytes32 node) public constant returns (address) {
        return records[node].resolver;
    }

    /**
     * Returns the TTL of a node, and any records associated with it.
     */
    function ttl(bytes32 node) public constant returns (uint64) {
        return records[node].ttl;
    }

    /**
     * Transfers ownership of a node to a new address. May only be called by the current
     * owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 node, address owner) only_owner(node) public {
        Transfer(node, owner);
        records[node].owner = owner;
    }

    /**
     * Transfers ownership of a subnode keccak256(node, label) to a new address. May only be
     * called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) public {
        var subnode = keccak256(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

    /**
     * Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address resolver) only_owner(node) public {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

    /**
     * Sets the TTL for the specified node.
     * @param node The node to update.
     * @param ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) public {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

// File: @aragon/os/contracts/lib/ens/PublicResolver.sol

// See https://github.com/ensdomains/ens/blob/7e377df83f/contracts/PublicResolver.sol

pragma solidity ^0.4.0;


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

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

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
    }

    AbstractENS ens;
    mapping(bytes32=>Record) records;

    modifier only_owner(bytes32 node) {
        if (ens.owner(node) != msg.sender) throw;
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The ENS registrar contract.
     */
    function PublicResolver(AbstractENS ensAddr) public {
        ens = ensAddr;
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
               interfaceID == INTERFACE_META_ID;
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public constant returns (address ret) {
        ret = records[node].addr;
    }

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address addr) only_owner(node) public {
        records[node].addr = addr;
        AddrChanged(node, addr);
    }

    /**
     * Returns the content hash associated with an ENS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The ENS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) public constant returns (bytes32 ret) {
        ret = records[node].content;
    }

    /**
     * Sets the content hash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) only_owner(node) public {
        records[node].content = hash;
        ContentChanged(node, hash);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public constant returns (string ret) {
        ret = records[node].name;
    }

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string name) only_owner(node) public {
        records[node].name = name;
        NameChanged(node, name);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) public constant returns (uint256 contentType, bytes data) {
        var record = records[node];
        for(contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes data) only_owner(node) public {
        // Content types must be powers of 2
        if (((contentType - 1) & contentType) != 0) throw;

        records[node].abis[contentType] = data;
        ABIChanged(node, contentType);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x, y the X and Y coordinates of the curve point for the public key.
     */
    function pubkey(bytes32 node) public constant returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) only_owner(node) public {
        records[node].pubkey = PublicKey(x, y);
        PubkeyChanged(node, x, y);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string key) public constant returns (string ret) {
        ret = records[node].text[key];
    }

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string key, string value) only_owner(node) public {
        records[node].text[key] = value;
        TextChanged(node, key, key);
    }
}

// File: @aragon/os/contracts/kernel/KernelProxy.sol

pragma solidity 0.4.24;







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

// File: @aragon/os/contracts/evmscript/ScriptHelpers.sol

/*
 * SPDX-License-Identitifer:    MIT
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

// File: @aragon/os/contracts/evmscript/EVMScriptRegistry.sol

pragma solidity 0.4.24;






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

// File: @aragon/os/contracts/evmscript/executors/BaseEVMScriptExecutor.sol

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;




contract BaseEVMScriptExecutor is IEVMScriptExecutor, Autopetrified {
    uint256 internal constant SCRIPT_START_LOCATION = 4;
}

// File: @aragon/os/contracts/evmscript/executors/CallsScript.sol

pragma solidity 0.4.24;

// Inspired by https://github.com/reverendus/tx-manager




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

// File: @aragon/os/contracts/factory/EVMScriptRegistryFactory.sol

pragma solidity 0.4.24;







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

// File: @aragon/os/contracts/factory/DAOFactory.sol

pragma solidity 0.4.24;








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
    constructor(IKernel _baseKernel, IACL _baseACL, EVMScriptRegistryFactory _regFactory) public {
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

// File: @aragon/id/contracts/ens/IPublicResolver.sol

pragma solidity ^0.4.0;


interface IPublicResolver {
    function supportsInterface(bytes4 interfaceID) constant returns (bool);
    function addr(bytes32 node) constant returns (address ret);
    function setAddr(bytes32 node, address addr);
    function hash(bytes32 node) constant returns (bytes32 ret);
    function setHash(bytes32 node, bytes32 hash);
}

// File: @aragon/id/contracts/IFIFSResolvingRegistrar.sol

pragma solidity 0.4.24;



interface IFIFSResolvingRegistrar {
    function register(bytes32 _subnode, address _owner) external;
    function registerWithResolver(bytes32 _subnode, address _owner, IPublicResolver _resolver) public;
}

// File: @aragon/templates-shared/contracts/BaseTemplate.sol

pragma solidity 0.4.24;




















contract BaseTemplate is APMNamehash, IsContract {
    using Uint256Helpers for uint256;

    /* Hardcoded constant to save gas
    * bytes32 constant internal AGENT_APP_ID = apmNamehash("agent");                  // agent.aragonpm.eth
    * bytes32 constant internal VAULT_APP_ID = apmNamehash("vault");                  // vault.aragonpm.eth
    * bytes32 constant internal VOTING_APP_ID = apmNamehash("voting");                // voting.aragonpm.eth
    * bytes32 constant internal SURVEY_APP_ID = apmNamehash("survey");                // survey.aragonpm.eth
    * bytes32 constant internal PAYROLL_APP_ID = apmNamehash("payroll");              // payroll.aragonpm.eth
    * bytes32 constant internal FINANCE_APP_ID = apmNamehash("finance");              // finance.aragonpm.eth
    * bytes32 constant internal TOKEN_MANAGER_APP_ID = apmNamehash("token-manager");  // token-manager.aragonpm.eth
    */
    bytes32 constant internal AGENT_APP_ID = 0x9ac98dc5f995bf0211ed589ef022719d1487e5cb2bab505676f0d084c07cf89a;
    bytes32 constant internal VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
    bytes32 constant internal VOTING_APP_ID = 0x9fa3927f639745e587912d4b0fea7ef9013bf93fb907d29faeab57417ba6e1d4;
    bytes32 constant internal PAYROLL_APP_ID = 0x463f596a96d808cb28b5d080181e4a398bc793df2c222f6445189eb801001991;
    bytes32 constant internal FINANCE_APP_ID = 0xbf8491150dafc5dcaee5b861414dca922de09ccffa344964ae167212e8c673ae;
    bytes32 constant internal TOKEN_MANAGER_APP_ID = 0x6b20a3010614eeebf2138ccec99f028a61c811b3b1a3343b6ff635985c75c91f;
    bytes32 constant internal SURVEY_APP_ID = 0x030b2ab880b88e228f2da5a3d19a2a31bc10dbf91fb1143776a6de489389471e;

    string constant private ERROR_ENS_NOT_CONTRACT = "TEMPLATE_ENS_NOT_CONTRACT";
    string constant private ERROR_DAO_FACTORY_NOT_CONTRACT = "TEMPLATE_DAO_FAC_NOT_CONTRACT";
    string constant private ERROR_ARAGON_ID_NOT_PROVIDED = "TEMPLATE_ARAGON_ID_NOT_PROVIDED";
    string constant private ERROR_ARAGON_ID_NOT_CONTRACT = "TEMPLATE_ARAGON_ID_NOT_CONTRACT";
    string constant private ERROR_MINIME_FACTORY_NOT_PROVIDED = "TEMPLATE_MINIME_FAC_NOT_PROVIDED";
    string constant private ERROR_MINIME_FACTORY_NOT_CONTRACT = "TEMPLATE_MINIME_FAC_NOT_CONTRACT";
    string constant private ERROR_CANNOT_CAST_VALUE_TO_ADDRESS = "TEMPLATE_CANNOT_CAST_VALUE_TO_ADDRESS";
    string constant private ERROR_INVALID_ID = "TEMPLATE_INVALID_ID";

    ENS internal ens;
    DAOFactory internal daoFactory;
    MiniMeTokenFactory internal miniMeFactory;
    IFIFSResolvingRegistrar internal aragonID;

    event DeployDao(address dao);
    event SetupDao(address dao);
    event DeployToken(address token);
    event InstalledApp(address appProxy, bytes32 appId);

    constructor(DAOFactory _daoFactory, ENS _ens, MiniMeTokenFactory _miniMeFactory, IFIFSResolvingRegistrar _aragonID) public {
        require(isContract(address(_ens)), ERROR_ENS_NOT_CONTRACT);
        require(isContract(address(_daoFactory)), ERROR_DAO_FACTORY_NOT_CONTRACT);

        ens = _ens;
        aragonID = _aragonID;
        daoFactory = _daoFactory;
        miniMeFactory = _miniMeFactory;
    }

    /**
    * @dev Create a DAO using the DAO Factory and grant the template root permissions so it has full
    *      control during setup. Once the DAO setup has finished, it is recommended to call the
    *      `_transferRootPermissionsFromTemplateAndFinalizeDAO()` helper to transfer the root
    *      permissions to the end entity in control of the organization.
    */
    function _createDAO() internal returns (Kernel dao, ACL acl) {
        dao = daoFactory.newDAO(this);
        emit DeployDao(address(dao));
        acl = ACL(dao.acl());
        _createPermissionForTemplate(acl, dao, dao.APP_MANAGER_ROLE());
    }

    /* ACL */

    function _createPermissions(ACL _acl, address[] memory _grantees, address _app, bytes32 _permission, address _manager) internal {
        _acl.createPermission(_grantees[0], _app, _permission, address(this));
        for (uint256 i = 1; i < _grantees.length; i++) {
            _acl.grantPermission(_grantees[i], _app, _permission);
        }
        _acl.revokePermission(address(this), _app, _permission);
        _acl.setPermissionManager(_manager, _app, _permission);
    }

    function _createPermissionForTemplate(ACL _acl, address _app, bytes32 _permission) internal {
        _acl.createPermission(address(this), _app, _permission, address(this));
    }

    function _removePermissionFromTemplate(ACL _acl, address _app, bytes32 _permission) internal {
        _acl.revokePermission(address(this), _app, _permission);
        _acl.removePermissionManager(_app, _permission);
    }

    function _transferRootPermissionsFromTemplateAndFinalizeDAO(Kernel _dao, address _to) internal {
        _transferRootPermissionsFromTemplateAndFinalizeDAO(_dao, _to, _to);
    }

    function _transferRootPermissionsFromTemplateAndFinalizeDAO(Kernel _dao, address _to, address _manager) internal {
        ACL _acl = ACL(_dao.acl());
        _transferPermissionFromTemplate(_acl, _dao, _to, _dao.APP_MANAGER_ROLE(), _manager);
        _transferPermissionFromTemplate(_acl, _acl, _to, _acl.CREATE_PERMISSIONS_ROLE(), _manager);
        emit SetupDao(_dao);
    }

    function _transferPermissionFromTemplate(ACL _acl, address _app, address _to, bytes32 _permission, address _manager) internal {
        _acl.grantPermission(_to, _app, _permission);
        _acl.revokePermission(address(this), _app, _permission);
        _acl.setPermissionManager(_manager, _app, _permission);
    }

    /* AGENT */

    function _installDefaultAgentApp(Kernel _dao) internal returns (Agent) {
        bytes memory initializeData = abi.encodeWithSelector(Agent(0).initialize.selector);
        Agent agent = Agent(_installDefaultApp(_dao, AGENT_APP_ID, initializeData));
        // We assume that installing the Agent app as a default app means the DAO should have its
        // Vault replaced by the Agent. Thus, we also set the DAO's recovery app to the Agent.
        _dao.setRecoveryVaultAppId(AGENT_APP_ID);
        return agent;
    }

    function _installNonDefaultAgentApp(Kernel _dao) internal returns (Agent) {
        bytes memory initializeData = abi.encodeWithSelector(Agent(0).initialize.selector);
        return Agent(_installNonDefaultApp(_dao, AGENT_APP_ID, initializeData));
    }

    function _createAgentPermissions(ACL _acl, Agent _agent, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _agent, _agent.EXECUTE_ROLE(), _manager);
        _acl.createPermission(_grantee, _agent, _agent.RUN_SCRIPT_ROLE(), _manager);
    }

    /* VAULT */

    function _installVaultApp(Kernel _dao) internal returns (Vault) {
        bytes memory initializeData = abi.encodeWithSelector(Vault(0).initialize.selector);
        return Vault(_installDefaultApp(_dao, VAULT_APP_ID, initializeData));
    }

    function _createVaultPermissions(ACL _acl, Vault _vault, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _vault, _vault.TRANSFER_ROLE(), _manager);
    }

    /* VOTING */

    function _installVotingApp(Kernel _dao, MiniMeToken _token, uint64[3] memory _votingSettings) internal returns (Voting) {
        return _installVotingApp(_dao, _token, _votingSettings[0], _votingSettings[1], _votingSettings[2]);
    }

    function _installVotingApp(
        Kernel _dao,
        MiniMeToken _token,
        uint64 _support,
        uint64 _acceptance,
        uint64 _duration
    )
        internal returns (Voting)
    {
        bytes memory initializeData = abi.encodeWithSelector(Voting(0).initialize.selector, _token, _support, _acceptance, _duration);
        return Voting(_installNonDefaultApp(_dao, VOTING_APP_ID, initializeData));
    }

    function _createVotingPermissions(
        ACL _acl,
        Voting _voting,
        address _settingsGrantee,
        address _createVotesGrantee,
        address _manager
    )
        internal
    {
        _acl.createPermission(_settingsGrantee, _voting, _voting.MODIFY_QUORUM_ROLE(), _manager);
        _acl.createPermission(_settingsGrantee, _voting, _voting.MODIFY_SUPPORT_ROLE(), _manager);
        _acl.createPermission(_createVotesGrantee, _voting, _voting.CREATE_VOTES_ROLE(), _manager);
    }

    /* SURVEY */

    function _installSurveyApp(Kernel _dao, MiniMeToken _token, uint64 _minParticipationPct, uint64 _surveyTime) internal returns (Survey) {
        bytes memory initializeData = abi.encodeWithSelector(Survey(0).initialize.selector, _token, _minParticipationPct, _surveyTime);
        return Survey(_installNonDefaultApp(_dao, SURVEY_APP_ID, initializeData));
    }

    function _createSurveyPermissions(ACL _acl, Survey _survey, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _survey, _survey.CREATE_SURVEYS_ROLE(), _manager);
        _acl.createPermission(_grantee, _survey, _survey.MODIFY_PARTICIPATION_ROLE(), _manager);
    }

    /* PAYROLL */

    function _installPayrollApp(
        Kernel _dao,
        Finance _finance,
        address _denominationToken,
        IFeed _priceFeed,
        uint64 _rateExpiryTime
    )
        internal returns (Payroll)
    {
        bytes memory initializeData = abi.encodeWithSelector(
            Payroll(0).initialize.selector,
            _finance,
            _denominationToken,
            _priceFeed,
            _rateExpiryTime
        );
        return Payroll(_installNonDefaultApp(_dao, PAYROLL_APP_ID, initializeData));
    }

    /**
    * @dev Internal function to configure payroll permissions. Note that we allow defining different managers for
    *      payroll since it may be useful to have one control the payroll settings (rate expiration, price feed,
    *      and allowed tokens), and another one to control the employee functionality (bonuses, salaries,
    *      reimbursements, employees, etc).
    * @param _acl ACL instance being configured
    * @param _acl Payroll app being configured
    * @param _employeeManager Address that will receive permissions to handle employee payroll functionality
    * @param _settingsManager Address that will receive permissions to manage payroll settings
    * @param _permissionsManager Address that will be the ACL manager for the payroll permissions
    */
    function _createPayrollPermissions(
        ACL _acl,
        Payroll _payroll,
        address _employeeManager,
        address _settingsManager,
        address _permissionsManager
    )
        internal
    {
        _acl.createPermission(_employeeManager, _payroll, _payroll.ADD_BONUS_ROLE(), _permissionsManager);
        _acl.createPermission(_employeeManager, _payroll, _payroll.ADD_EMPLOYEE_ROLE(), _permissionsManager);
        _acl.createPermission(_employeeManager, _payroll, _payroll.ADD_REIMBURSEMENT_ROLE(), _permissionsManager);
        _acl.createPermission(_employeeManager, _payroll, _payroll.TERMINATE_EMPLOYEE_ROLE(), _permissionsManager);
        _acl.createPermission(_employeeManager, _payroll, _payroll.SET_EMPLOYEE_SALARY_ROLE(), _permissionsManager);

        _acl.createPermission(_settingsManager, _payroll, _payroll.MODIFY_PRICE_FEED_ROLE(), _permissionsManager);
        _acl.createPermission(_settingsManager, _payroll, _payroll.MODIFY_RATE_EXPIRY_ROLE(), _permissionsManager);
        _acl.createPermission(_settingsManager, _payroll, _payroll.MANAGE_ALLOWED_TOKENS_ROLE(), _permissionsManager);
    }

    function _unwrapPayrollSettings(
        uint256[4] memory _payrollSettings
    )
        internal pure returns (address denominationToken, IFeed priceFeed, uint64 rateExpiryTime, address employeeManager)
    {
        denominationToken = _toAddress(_payrollSettings[0]);
        priceFeed = IFeed(_toAddress(_payrollSettings[1]));
        rateExpiryTime = _payrollSettings[2].toUint64();
        employeeManager = _toAddress(_payrollSettings[3]);
    }

    /* FINANCE */

    function _installFinanceApp(Kernel _dao, Vault _vault, uint64 _periodDuration) internal returns (Finance) {
        bytes memory initializeData = abi.encodeWithSelector(Finance(0).initialize.selector, _vault, _periodDuration);
        return Finance(_installNonDefaultApp(_dao, FINANCE_APP_ID, initializeData));
    }

    function _createFinancePermissions(ACL _acl, Finance _finance, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _finance, _finance.EXECUTE_PAYMENTS_ROLE(), _manager);
        _acl.createPermission(_grantee, _finance, _finance.MANAGE_PAYMENTS_ROLE(), _manager);
    }

    function _createFinanceCreatePaymentsPermission(ACL _acl, Finance _finance, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _finance, _finance.CREATE_PAYMENTS_ROLE(), _manager);
    }

    function _grantCreatePaymentPermission(ACL _acl, Finance _finance, address _to) internal {
        _acl.grantPermission(_to, _finance, _finance.CREATE_PAYMENTS_ROLE());
    }

    function _transferCreatePaymentManagerFromTemplate(ACL _acl, Finance _finance, address _manager) internal {
        _acl.setPermissionManager(_manager, _finance, _finance.CREATE_PAYMENTS_ROLE());
    }

    /* TOKEN MANAGER */

    function _installTokenManagerApp(
        Kernel _dao,
        MiniMeToken _token,
        bool _transferable,
        uint256 _maxAccountTokens
    )
        internal returns (TokenManager)
    {
        TokenManager tokenManager = TokenManager(_installNonDefaultApp(_dao, TOKEN_MANAGER_APP_ID));
        _token.changeController(tokenManager);
        tokenManager.initialize(_token, _transferable, _maxAccountTokens);
        return tokenManager;
    }

    function _createTokenManagerPermissions(ACL _acl, TokenManager _tokenManager, address _grantee, address _manager) internal {
        _acl.createPermission(_grantee, _tokenManager, _tokenManager.MINT_ROLE(), _manager);
        _acl.createPermission(_grantee, _tokenManager, _tokenManager.BURN_ROLE(), _manager);
    }

    function _mintTokens(ACL _acl, TokenManager _tokenManager, address[] memory _holders, uint256[] memory _stakes) internal {
        _createPermissionForTemplate(_acl, _tokenManager, _tokenManager.MINT_ROLE());
        for (uint256 i = 0; i < _holders.length; i++) {
            _tokenManager.mint(_holders[i], _stakes[i]);
        }
        _removePermissionFromTemplate(_acl, _tokenManager, _tokenManager.MINT_ROLE());
    }

    function _mintTokens(ACL _acl, TokenManager _tokenManager, address[] memory _holders, uint256 _stake) internal {
        _createPermissionForTemplate(_acl, _tokenManager, _tokenManager.MINT_ROLE());
        for (uint256 i = 0; i < _holders.length; i++) {
            _tokenManager.mint(_holders[i], _stake);
        }
        _removePermissionFromTemplate(_acl, _tokenManager, _tokenManager.MINT_ROLE());
    }

    function _mintTokens(ACL _acl, TokenManager _tokenManager, address _holder, uint256 _stake) internal {
        _createPermissionForTemplate(_acl, _tokenManager, _tokenManager.MINT_ROLE());
        _tokenManager.mint(_holder, _stake);
        _removePermissionFromTemplate(_acl, _tokenManager, _tokenManager.MINT_ROLE());
    }

    /* EVM SCRIPTS */

    function _createEvmScriptsRegistryPermissions(ACL _acl, address _grantee, address _manager) internal {
        EVMScriptRegistry registry = EVMScriptRegistry(_acl.getEVMScriptRegistry());
        _acl.createPermission(_grantee, registry, registry.REGISTRY_MANAGER_ROLE(), _manager);
        _acl.createPermission(_grantee, registry, registry.REGISTRY_ADD_EXECUTOR_ROLE(), _manager);
    }

    /* APPS */

    function _installNonDefaultApp(Kernel _dao, bytes32 _appId) internal returns (address) {
        return _installNonDefaultApp(_dao, _appId, new bytes(0));
    }

    function _installNonDefaultApp(Kernel _dao, bytes32 _appId, bytes memory _initializeData) internal returns (address) {
        return _installApp(_dao, _appId, _initializeData, false);
    }

    function _installDefaultApp(Kernel _dao, bytes32 _appId) internal returns (address) {
        return _installDefaultApp(_dao, _appId, new bytes(0));
    }

    function _installDefaultApp(Kernel _dao, bytes32 _appId, bytes memory _initializeData) internal returns (address) {
        return _installApp(_dao, _appId, _initializeData, true);
    }

    function _installApp(Kernel _dao, bytes32 _appId, bytes memory _initializeData, bool _setDefault) internal returns (address) {
        address latestBaseAppAddress = _latestVersionAppBase(_appId);
        address instance = address(_dao.newAppInstance(_appId, latestBaseAppAddress, _initializeData, _setDefault));
        emit InstalledApp(instance, _appId);
        return instance;
    }

    function _latestVersionAppBase(bytes32 _appId) internal view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(_appId)).addr(_appId));
        (,base,) = repo.getLatest();
    }

    /* TOKEN */

    function _createToken(string memory _name, string memory _symbol, uint8 _decimals) internal returns (MiniMeToken) {
        require(address(miniMeFactory) != address(0), ERROR_MINIME_FACTORY_NOT_PROVIDED);
        MiniMeToken token = miniMeFactory.createCloneToken(MiniMeToken(address(0)), 0, _name, _decimals, _symbol, true);
        emit DeployToken(address(token));
        return token;
    }

    function _ensureMiniMeFactoryIsValid(address _miniMeFactory) internal view {
        require(isContract(address(_miniMeFactory)), ERROR_MINIME_FACTORY_NOT_CONTRACT);
    }

    /* IDS */

    function _validateId(string memory _id) internal pure {
        require(bytes(_id).length > 0, ERROR_INVALID_ID);
    }

    function _registerID(string memory _name, address _owner) internal {
        require(address(aragonID) != address(0), ERROR_ARAGON_ID_NOT_PROVIDED);
        aragonID.register(keccak256(abi.encodePacked(_name)), _owner);
    }

    function _ensureAragonIdIsValid(address _aragonID) internal view {
        require(isContract(address(_aragonID)), ERROR_ARAGON_ID_NOT_CONTRACT);
    }

    /* HELPERS */

    function _toAddress(uint256 _value) private pure returns (address) {
        require(_value <= uint160(-1), ERROR_CANNOT_CAST_VALUE_TO_ADDRESS);
        return address(_value);
    }
}

// File: @ablack/fundraising-bancor-formula/contracts/interfaces/IBancorFormula.sol

pragma solidity 0.4.24;

/*
    Bancor Formula interface
*/
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256);
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256);
}

// File: @ablack/fundraising-bancor-formula/contracts/utility/Utils.sol

pragma solidity 0.4.24;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    constructor() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

// File: @ablack/fundraising-bancor-formula/contracts/BancorFormula.sol

pragma solidity 0.4.24;




contract BancorFormula is IBancorFormula, Utils {
    using SafeMath for uint256;


    string public version = '0.3';

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
        Auto-generated via 'PrintIntScalingFactors.py'
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
        Auto-generated via 'PrintLn2ScalingFactors.py'
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
        Auto-generated via 'PrintFunctionConstructor.py'
    */
    uint256[128] private maxExpArray;
    constructor() public {
    //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
    //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
    //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
    //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
    //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
    //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
    //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
    //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
    //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
    //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
    //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
    //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
    //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
    //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
    //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
    //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
    //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
    //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
    //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
    //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
    //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
    //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
    //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
    //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
    //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
    //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
    //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
    //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
    //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
    //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
    //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
    //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
        @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
        calculates the return for a given conversion (in the main token)

        Formula:
        Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)

        @param _supply              token total supply
        @param _connectorBalance    total connector balance
        @param _connectorWeight     connector weight, represented in ppm, 1-1000000
        @param _depositAmount       deposit amount, in connector token

        @return purchase return amount
    */
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

        // special case for 0 deposit amount
        if (_depositAmount == 0)
            return 0;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return _supply.mul(_depositAmount) / _connectorBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount.add(_connectorBalance);
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
        @dev given a token supply, connector balance, weight and a sell amount (in the main token),
        calculates the return for a given conversion (in the connector token)

        Formula:
        Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))

        @param _supply              token total supply
        @param _connectorBalance    total connector
        @param _connectorWeight     constant connector Weight, represented in ppm, 1-1000000
        @param _sellAmount          sell amount, in the token itself

        @return sale return amount
    */
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

        // special case for 0 sell amount
        if (_sellAmount == 0)
            return 0;

        // special case for selling the entire supply
        if (_sellAmount == _supply)
            return _connectorBalance;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return _connectorBalance.mul(_sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 temp1 = _connectorBalance.mul(result);
        uint256 temp2 = _connectorBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
        @dev given two connector balances/weights and a sell amount (in the first connector token),
        calculates the return for a conversion from the first connector token to the second connector token (in the second connector token)

        Formula:
        Return = _toConnectorBalance * (1 - (_fromConnectorBalance / (_fromConnectorBalance + _amount)) ^ (_fromConnectorWeight / _toConnectorWeight))

        @param _fromConnectorBalance    input connector balance
        @param _fromConnectorWeight     input connector weight, represented in ppm, 1-1000000
        @param _toConnectorBalance      output connector balance
        @param _toConnectorWeight       output connector weight, represented in ppm, 1-1000000
        @param _amount                  input connector amount

        @return second connector amount
    */
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256) {
        // validate input
        require(_fromConnectorBalance > 0 && _fromConnectorWeight > 0 && _fromConnectorWeight <= MAX_WEIGHT && _toConnectorBalance > 0 && _toConnectorWeight > 0 && _toConnectorWeight <= MAX_WEIGHT);

        // special case for equal weights
        if (_fromConnectorWeight == _toConnectorWeight)
            return _toConnectorBalance.mul(_amount) / _fromConnectorBalance.add(_amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = _fromConnectorBalance.add(_amount);
        (result, precision) = power(baseN, _fromConnectorBalance, _fromConnectorWeight, _toConnectorWeight);
        uint256 temp1 = _toConnectorBalance.mul(result);
        uint256 temp2 = _toConnectorBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
        General Description:
            Determine a value of precision.
            Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
            Return the result along with the precision used.

        Detailed Description:
            Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
            The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
            The larger "precision" is, the more accurately this value represents the real value.
            However, the larger "precision" is, the more bits are required in order to store this value.
            And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
            This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
            Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
            This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
            This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
        Compute log(x / FIXED_1) * FIXED_1.
        This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
    */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
        Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x)
                lo = mid;
            else
                hi = mid;
        }

        if (maxExpArray[hi] >= _x)
            return hi;
        if (maxExpArray[lo] >= _x)
            return lo;

        require(false);
        return 0;
    }

    /**
        This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
        Return log(x / FIXED_1) * FIXED_1
        Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalLog.py'
        Detailed description:
        - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
        - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
        - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
        - The natural logarithm of the input is calculated by summing up the intermediate results above
        - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
    */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;} // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;} // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;} // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;} // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;} // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;} // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;} // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;} // add 1 / 2^8

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                      // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
        Return e ^ (x / FIXED_1) * FIXED_1
        Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalExp.py'
        Detailed description:
        - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
        - The exponentiation of each binary exponent is given (pre-calculated)
        - The exponentiation of r is calculated via Taylor series for e^x, where x = r
        - The exponentiation of the input is calculated by multiplying the intermediate results above
        - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
    */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }
}

// File: @ablack/fundraising-shared-interfaces/contracts/IAragonFundraisingController.sol

pragma solidity 0.4.24;


contract IAragonFundraisingController {
    function openTrading() external;
    function updateTappedAmount(address _token) external;
    function collateralsToBeClaimed(address _collateral) public view returns (uint256);
    function balanceOf(address _who, address _token) public view returns (uint256);
}

// File: @ablack/fundraising-batched-bancor-market-maker/contracts/BatchedBancorMarketMaker.sol

pragma solidity 0.4.24;












contract BatchedBancorMarketMaker is EtherTokenConstant, IsContract, AragonApp {
    using SafeERC20 for ERC20;
    using SafeMath  for uint256;

    /**
    Hardcoded constants to save gas
    bytes32 public constant OPEN_ROLE                    = keccak256("OPEN_ROLE");
    bytes32 public constant UPDATE_FORMULA_ROLE          = keccak256("UPDATE_FORMULA_ROLE");
    bytes32 public constant UPDATE_BENEFICIARY_ROLE      = keccak256("UPDATE_BENEFICIARY_ROLE");
    bytes32 public constant UPDATE_FEES_ROLE             = keccak256("UPDATE_FEES_ROLE");
    bytes32 public constant ADD_COLLATERAL_TOKEN_ROLE    = keccak256("ADD_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant REMOVE_COLLATERAL_TOKEN_ROLE = keccak256("REMOVE_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant UPDATE_COLLATERAL_TOKEN_ROLE = keccak256("UPDATE_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant OPEN_BUY_ORDER_ROLE          = keccak256("OPEN_BUY_ORDER_ROLE");
    bytes32 public constant OPEN_SELL_ORDER_ROLE         = keccak256("OPEN_SELL_ORDER_ROLE");
    */
    bytes32 public constant OPEN_ROLE                    = 0xefa06053e2ca99a43c97c4a4f3d8a394ee3323a8ff237e625fba09fe30ceb0a4;
    bytes32 public constant UPDATE_FORMULA_ROLE          = 0xbfb76d8d43f55efe58544ea32af187792a7bdb983850d8fed33478266eec3cbb;
    bytes32 public constant UPDATE_BENEFICIARY_ROLE      = 0xf7ea2b80c7b6a2cab2c11d2290cb005c3748397358a25e17113658c83b732593;
    bytes32 public constant UPDATE_FEES_ROLE             = 0x5f9be2932ed3a723f295a763be1804c7ebfd1a41c1348fb8bdf5be1c5cdca822;
    bytes32 public constant ADD_COLLATERAL_TOKEN_ROLE    = 0x217b79cb2bc7760defc88529853ef81ab33ae5bb315408ce9f5af09c8776662d;
    bytes32 public constant REMOVE_COLLATERAL_TOKEN_ROLE = 0x2044e56de223845e4be7d0a6f4e9a29b635547f16413a6d1327c58d9db438ee2;
    bytes32 public constant UPDATE_COLLATERAL_TOKEN_ROLE = 0xe0565c2c43e0d841e206bb36a37f12f22584b4652ccee6f9e0c071b697a2e13d;
    bytes32 public constant OPEN_BUY_ORDER_ROLE          = 0xa589c8f284b76fc8d510d9d553485c47dbef1b0745ae00e0f3fd4e28fcd77ea7;
    bytes32 public constant OPEN_SELL_ORDER_ROLE         = 0xd68ba2b769fa37a2a7bd4bed9241b448bc99eca41f519ef037406386a8f291c0;

    uint256 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10 ** 16; 100% = 10 ** 18
    uint32  public constant PPM      = 1000000;

    string private constant ERROR_CONTRACT_IS_EOA                = "MM_CONTRACT_IS_EOA";
    string private constant ERROR_INVALID_BENEFICIARY            = "MM_INVALID_BENEFICIARY";
    string private constant ERROR_INVALID_BATCH_BLOCKS           = "MM_INVALID_BATCH_BLOCKS";
    string private constant ERROR_INVALID_PERCENTAGE             = "MM_INVALID_PERCENTAGE";
    string private constant ERROR_INVALID_RESERVE_RATIO          = "MM_INVALID_RESERVE_RATIO";
    string private constant ERROR_INVALID_TM_SETTING             = "MM_INVALID_TM_SETTING";
    string private constant ERROR_INVALID_COLLATERAL             = "MM_INVALID_COLLATERAL";
    string private constant ERROR_INVALID_COLLATERAL_VALUE       = "MM_INVALID_COLLATERAL_VALUE";
    string private constant ERROR_INVALID_BOND_AMOUNT            = "MM_INVALID_BOND_AMOUNT";
    string private constant ERROR_ALREADY_OPEN                   = "MM_ALREADY_OPEN";
    string private constant ERROR_NOT_OPEN                       = "MM_NOT_OPEN";
    string private constant ERROR_COLLATERAL_ALREADY_WHITELISTED = "MM_COLLATERAL_ALREADY_WHITELISTED";
    string private constant ERROR_COLLATERAL_NOT_WHITELISTED     = "MM_COLLATERAL_NOT_WHITELISTED";
    string private constant ERROR_NOTHING_TO_CLAIM               = "MM_NOTHING_TO_CLAIM";
    string private constant ERROR_BATCH_NOT_OVER                 = "MM_BATCH_NOT_OVER";
    string private constant ERROR_BATCH_CANCELLED                = "MM_BATCH_CANCELLED";
    string private constant ERROR_BATCH_NOT_CANCELLED            = "MM_BATCH_NOT_CANCELLED";
    string private constant ERROR_SLIPPAGE_EXCEEDS_LIMIT         = "MM_SLIPPAGE_EXCEEDS_LIMIT";
    string private constant ERROR_INSUFFICIENT_POOL_BALANCE      = "MM_INSUFFICIENT_POOL_BALANCE";
    string private constant ERROR_TRANSFER_FROM_FAILED           = "MM_TRANSFER_FROM_FAILED";

    struct Collateral {
        bool    whitelisted;
        uint256 virtualSupply;
        uint256 virtualBalance;
        uint32  reserveRatio;
        uint256 slippage;
    }

    struct MetaBatch {
        bool           initialized;
        uint256        realSupply;
        uint256        buyFeePct;
        uint256        sellFeePct;
        IBancorFormula formula;
        mapping(address => Batch) batches;
    }

    struct Batch {
        bool    initialized;
        bool    cancelled;
        uint256 supply;
        uint256 balance;
        uint32  reserveRatio;
        uint256 slippage;
        uint256 totalBuySpend;
        uint256 totalBuyReturn;
        uint256 totalSellSpend;
        uint256 totalSellReturn;
        mapping(address => uint256) buyers;
        mapping(address => uint256) sellers;
    }

    IAragonFundraisingController   public controller;
    TokenManager                   public tokenManager;
    ERC20                          public token;
    Vault                          public reserve;
    address                        public beneficiary;
    IBancorFormula                 public formula;

    uint256                        public batchBlocks;
    uint256                        public buyFeePct;
    uint256                        public sellFeePct;

    bool                           public isOpen;
    uint256                        public tokensToBeMinted;
    mapping(address => uint256)    public collateralsToBeClaimed;
    mapping(address => Collateral) public collaterals;
    mapping(uint256 => MetaBatch)  public metaBatches;

    event UpdateBeneficiary      (address indexed beneficiary);
    event UpdateFormula          (address indexed formula);
    event UpdateFees             (uint256 buyFeePct, uint256 sellFeePct);
    event NewMetaBatch           (uint256 indexed id, uint256 supply, uint256 buyFeePct, uint256 sellFeePct, address formula);
    event NewBatch               (
        uint256 indexed id,
        address indexed collateral,
        uint256 supply,
        uint256 balance,
        uint32  reserveRatio,
        uint256 slippage)
    ;
    event CancelBatch            (uint256 indexed id, address indexed collateral);
    event AddCollateralToken     (
        address indexed collateral,
        uint256 virtualSupply,
        uint256 virtualBalance,
        uint32  reserveRatio,
        uint256 slippage
    );
    event RemoveCollateralToken  (address indexed collateral);
    event UpdateCollateralToken  (
        address indexed collateral,
        uint256 virtualSupply,
        uint256 virtualBalance,
        uint32  reserveRatio,
        uint256 slippage
    );
    event Open                   ();
    event OpenBuyOrder           (address indexed buyer, uint256 indexed batchId, address indexed collateral, uint256 fee, uint256 value);
    event OpenSellOrder          (address indexed seller, uint256 indexed batchId, address indexed collateral, uint256 amount);
    event ClaimBuyOrder          (address indexed buyer, uint256 indexed batchId, address indexed collateral, uint256 amount);
    event ClaimSellOrder         (address indexed seller, uint256 indexed batchId, address indexed collateral, uint256 fee, uint256 value);
    event ClaimCancelledBuyOrder (address indexed buyer, uint256 indexed batchId, address indexed collateral, uint256 value);
    event ClaimCancelledSellOrder(address indexed seller, uint256 indexed batchId, address indexed collateral, uint256 amount);
    event UpdatePricing          (
        uint256 indexed batchId,
        address indexed collateral,
        uint256 totalBuySpend,
        uint256 totalBuyReturn,
        uint256 totalSellSpend,
        uint256 totalSellReturn
    );


    /***** external function *****/

    /**
     * @notice Initialize market maker
     * @param _controller   The address of the controller contract
     * @param _tokenManager The address of the [bonded token] token manager contract
     * @param _reserve      The address of the reserve [pool] contract
     * @param _beneficiary  The address of the beneficiary [to whom fees are to be sent]
     * @param _formula      The address of the BancorFormula [computation] contract
     * @param _batchBlocks  The number of blocks batches are to last
     * @param _buyFeePct    The fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct   The fee to be deducted from sell orders [in PCT_BASE]
    */
    function initialize(
        IAragonFundraisingController _controller,
        TokenManager                 _tokenManager,
        IBancorFormula               _formula,
        Vault                        _reserve,
        address                      _beneficiary,
        uint256                      _batchBlocks,
        uint256                      _buyFeePct,
        uint256                      _sellFeePct
    )
        external
        onlyInit
    {
        initialized();

        require(isContract(_controller),                             ERROR_CONTRACT_IS_EOA);
        require(isContract(_tokenManager),                           ERROR_CONTRACT_IS_EOA);
        require(isContract(_formula),                                ERROR_CONTRACT_IS_EOA);
        require(isContract(_reserve),                                ERROR_CONTRACT_IS_EOA);
        require(_beneficiaryIsValid(_beneficiary),                   ERROR_INVALID_BENEFICIARY);
        require(_batchBlocks > 0,                                    ERROR_INVALID_BATCH_BLOCKS);
        require(_feeIsValid(_buyFeePct) && _feeIsValid(_sellFeePct), ERROR_INVALID_PERCENTAGE);
        require(_tokenManagerSettingIsValid(_tokenManager),          ERROR_INVALID_TM_SETTING);

        controller = _controller;
        tokenManager = _tokenManager;
        token = ERC20(tokenManager.token());
        formula = _formula;
        reserve = _reserve;
        beneficiary = _beneficiary;
        batchBlocks = _batchBlocks;
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;
    }

    /* generic settings related function */

    /**
     * @notice Open market making [enabling users to open buy and sell orders]
    */
    function open() external auth(OPEN_ROLE) {
        require(!isOpen, ERROR_ALREADY_OPEN);

        _open();
    }

    /**
     * @notice Update formula to `_formula`
     * @param _formula The address of the new BancorFormula [computation] contract
    */
    function updateFormula(IBancorFormula _formula) external auth(UPDATE_FORMULA_ROLE) {
        require(isContract(_formula), ERROR_CONTRACT_IS_EOA);

        _updateFormula(_formula);
    }

    /**
     * @notice Update beneficiary to `_beneficiary`
     * @param _beneficiary The address of the new beneficiary [to whom fees are to be sent]
    */
    function updateBeneficiary(address _beneficiary) external auth(UPDATE_BENEFICIARY_ROLE) {
        require(_beneficiaryIsValid(_beneficiary), ERROR_INVALID_BENEFICIARY);

        _updateBeneficiary(_beneficiary);
    }

    /**
     * @notice Update fees deducted from buy and sell orders to respectively `@formatPct(_buyFeePct)`% and `@formatPct(_sellFeePct)`%
     * @param _buyFeePct  The new fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct The new fee to be deducted from sell orders [in PCT_BASE]
    */
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external auth(UPDATE_FEES_ROLE) {
        require(_feeIsValid(_buyFeePct) && _feeIsValid(_sellFeePct), ERROR_INVALID_PERCENTAGE);

        _updateFees(_buyFeePct, _sellFeePct);
    }

    /* collateral tokens related functions */

    /**
     * @notice Add `_collateral.symbol(): string` as a whitelisted collateral token
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The price slippage below which each batch is to be kept for that collateral token [in PCT_BASE]
    */
    function addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage)
        external
        auth(ADD_COLLATERAL_TOKEN_ROLE)
    {
        require(isContract(_collateral) || _collateral == ETH, ERROR_INVALID_COLLATERAL);
        require(!_collateralIsWhitelisted(_collateral),        ERROR_COLLATERAL_ALREADY_WHITELISTED);
        require(_reserveRatioIsValid(_reserveRatio),           ERROR_INVALID_RESERVE_RATIO);

        _addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    /**
      * @notice Remove `_collateral.symbol(): string` as a whitelisted collateral token
      * @param _collateral The address of the collateral token to be un-whitelisted
    */
    function removeCollateralToken(address _collateral) external auth(REMOVE_COLLATERAL_TOKEN_ROLE) {
        require(_collateralIsWhitelisted(_collateral), ERROR_COLLATERAL_NOT_WHITELISTED);

        _removeCollateralToken(_collateral);
    }

    /**
     * @notice Update `_collateral.symbol(): string` collateralization settings
     * @param _collateral     The address of the collateral token whose collateralization settings are to be updated
     * @param _virtualSupply  The new virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The new virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The new reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The new price slippage below which each batch is to be kept for that collateral token [in PCT_BASE]
    */
    function updateCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage)
        external
        auth(UPDATE_COLLATERAL_TOKEN_ROLE)
    {
        require(_collateralIsWhitelisted(_collateral), ERROR_COLLATERAL_NOT_WHITELISTED);
        require(_reserveRatioIsValid(_reserveRatio),   ERROR_INVALID_RESERVE_RATIO);

        _updateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    /* market making related functions */

    /**
     * @notice Open a buy order worth `@tokenAmount(_collateral, _value)`
     * @param _buyer      The address of the buyer
     * @param _collateral The address of the collateral token to be spent
     * @param _value      The amount of collateral token to be spent
    */
    function openBuyOrder(address _buyer, address _collateral, uint256 _value) external payable auth(OPEN_BUY_ORDER_ROLE) {
        require(isOpen,                                                          ERROR_NOT_OPEN);
        require(_collateralIsWhitelisted(_collateral),                           ERROR_COLLATERAL_NOT_WHITELISTED);
        require(!_batchIsCancelled(_currentBatchId(), _collateral),              ERROR_BATCH_CANCELLED);
        require(_collateralValueIsValid(_buyer, _collateral, _value, msg.value), ERROR_INVALID_COLLATERAL_VALUE);

        _openBuyOrder(_buyer, _collateral, _value);
    }

    /**
     * @notice Open a sell order worth `@tokenAmount(self.token(): address, _amount)` against `_collateral.symbol(): string`
     * @param _seller     The address of the seller
     * @param _collateral The address of the collateral token to be returned
     * @param _amount     The amount of bonded token to be spent
    */
    function openSellOrder(address _seller, address _collateral, uint256 _amount) external auth(OPEN_SELL_ORDER_ROLE) {
        require(isOpen,                                             ERROR_NOT_OPEN);
        require(_collateralIsWhitelisted(_collateral),              ERROR_COLLATERAL_NOT_WHITELISTED);
        require(!_batchIsCancelled(_currentBatchId(), _collateral), ERROR_BATCH_CANCELLED);
        require(_bondAmountIsValid(_seller, _amount),               ERROR_INVALID_BOND_AMOUNT);

        _openSellOrder(_seller, _collateral, _amount);
    }

    /**
     * @notice Claim the results of `_buyer`'s `_collateral.symbol(): string` buy orders from batch #`_batchId`
     * @param _buyer      The address of the user whose buy orders are to be claimed
     * @param _batchId    The id of the batch in which buy orders are to be claimed
     * @param _collateral The address of the collateral token against which buy orders are to be claimed
    */
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) external nonReentrant isInitialized {
        require(_collateralIsWhitelisted(_collateral),       ERROR_COLLATERAL_NOT_WHITELISTED);
        require(_batchIsOver(_batchId),                      ERROR_BATCH_NOT_OVER);
        require(!_batchIsCancelled(_batchId, _collateral),   ERROR_BATCH_CANCELLED);
        require(_userIsBuyer(_batchId, _collateral, _buyer), ERROR_NOTHING_TO_CLAIM);

        _claimBuyOrder(_buyer, _batchId, _collateral);
    }

    /**
     * @notice Claim the results of `_seller`'s `_collateral.symbol(): string` sell orders from batch #`_batchId`
     * @param _seller     The address of the user whose sell orders are to be claimed
     * @param _batchId    The id of the batch in which sell orders are to be claimed
     * @param _collateral The address of the collateral token against which sell orders are to be claimed
    */
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) external nonReentrant isInitialized {
        require(_collateralIsWhitelisted(_collateral),         ERROR_COLLATERAL_NOT_WHITELISTED);
        require(_batchIsOver(_batchId),                        ERROR_BATCH_NOT_OVER);
        require(!_batchIsCancelled(_batchId, _collateral),     ERROR_BATCH_CANCELLED);
        require(_userIsSeller(_batchId, _collateral, _seller), ERROR_NOTHING_TO_CLAIM);

        _claimSellOrder(_seller, _batchId, _collateral);
    }

    /**
     * @notice Claim the investments of `_buyer`'s `_collateral.symbol(): string` buy orders from cancelled batch #`_batchId`
     * @param _buyer      The address of the user whose cancelled buy orders are to be claimed
     * @param _batchId    The id of the batch in which cancelled buy orders are to be claimed
     * @param _collateral The address of the collateral token against which cancelled buy orders are to be claimed
    */
    function claimCancelledBuyOrder(address _buyer, uint256 _batchId, address _collateral) external nonReentrant isInitialized {
        require(_batchIsCancelled(_batchId, _collateral),    ERROR_BATCH_NOT_CANCELLED);
        require(_userIsBuyer(_batchId, _collateral, _buyer), ERROR_NOTHING_TO_CLAIM);

        _claimCancelledBuyOrder(_buyer, _batchId, _collateral);
    }

    /**
     * @notice Claim the investments of `_seller`'s `_collateral.symbol(): string` sell orders from cancelled batch #`_batchId`
     * @param _seller     The address of the user whose cancelled sell orders are to be claimed
     * @param _batchId    The id of the batch in which cancelled sell orders are to be claimed
     * @param _collateral The address of the collateral token against which cancelled sell orders are to be claimed
    */
    function claimCancelledSellOrder(address _seller, uint256 _batchId, address _collateral) external nonReentrant isInitialized {
        require(_batchIsCancelled(_batchId, _collateral),      ERROR_BATCH_NOT_CANCELLED);
        require(_userIsSeller(_batchId, _collateral, _seller), ERROR_NOTHING_TO_CLAIM);

        _claimCancelledSellOrder(_seller, _batchId, _collateral);
    }

    /***** public view functions *****/

    function getCurrentBatchId() public view isInitialized returns (uint256) {
        return _currentBatchId();
    }

    function getCollateralToken(address _collateral) public view isInitialized returns (bool, uint256, uint256, uint32, uint256) {
        Collateral storage collateral = collaterals[_collateral];

        return (collateral.whitelisted, collateral.virtualSupply, collateral.virtualBalance, collateral.reserveRatio, collateral.slippage);
    }

    function getBatch(uint256 _batchId, address _collateral)
        public view isInitialized
        returns (bool, bool, uint256, uint256, uint32, uint256, uint256, uint256, uint256, uint256)
    {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];

        return (
            batch.initialized,
            batch.cancelled,
            batch.supply,
            batch.balance,
            batch.reserveRatio,
            batch.slippage,
            batch.totalBuySpend,
            batch.totalBuyReturn,
            batch.totalSellSpend,
            batch.totalSellReturn
        );
    }

    function getStaticPricePPM(uint256 _supply, uint256 _balance, uint32 _reserveRatio) public view isInitialized returns (uint256) {
        return _staticPricePPM(_supply, _balance, _reserveRatio);
    }

    /***** internal functions *****/

    /* computation functions */

    function _staticPricePPM(uint256 _supply, uint256 _balance, uint32 _reserveRatio) internal pure returns (uint256) {
        return uint256(PPM).mul(uint256(PPM)).mul(_balance).div(_supply.mul(uint256(_reserveRatio)));
    }

    function _currentBatchId() internal view returns (uint256) {
        return (block.number.div(batchBlocks)).mul(batchBlocks);
    }

    /* check functions */

    function _beneficiaryIsValid(address _beneficiary) internal pure returns (bool) {
        return _beneficiary != address(0);
    }

    function _feeIsValid(uint256 _fee) internal pure returns (bool) {
        return _fee < PCT_BASE;
    }

    function _reserveRatioIsValid(uint32 _reserveRatio) internal pure returns (bool) {
        return _reserveRatio <= PPM;
    }

    function _tokenManagerSettingIsValid(TokenManager _tokenManager) internal view returns (bool) {
        return _tokenManager.maxAccountTokens() == uint256(-1);
    }

    function _collateralValueIsValid(address _buyer, address _collateral, uint256 _value, uint256 _msgValue) internal view returns (bool) {
        if (_value == 0) {
            return false;
        }

        if (_collateral == ETH) {
            return _msgValue == _value;
        }

        return (
            _msgValue == 0 &&
            controller.balanceOf(_buyer, _collateral) >= _value &&
            ERC20(_collateral).allowance(_buyer, address(this)) >= _value
        );
    }

    function _bondAmountIsValid(address _seller, uint256 _amount) internal view returns (bool) {
        return _amount != 0 && tokenManager.spendableBalanceOf(_seller) >= _amount;
    }

    function _collateralIsWhitelisted(address _collateral) internal view returns (bool) {
        return collaterals[_collateral].whitelisted;
    }

    function _batchIsOver(uint256 _batchId) internal view returns (bool) {
        return _batchId < _currentBatchId();
    }

    function _batchIsCancelled(uint256 _batchId, address _collateral) internal view returns (bool) {
        return metaBatches[_batchId].batches[_collateral].cancelled;
    }

    function _userIsBuyer(uint256 _batchId, address _collateral, address _user) internal view returns (bool) {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];
        return batch.buyers[_user] > 0;
    }

    function _userIsSeller(uint256 _batchId, address _collateral, address _user) internal view returns (bool) {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];
        return batch.sellers[_user] > 0;
    }

    function _poolBalanceIsSufficient(address _collateral) internal view returns (bool) {
        return controller.balanceOf(address(reserve), _collateral) >= collateralsToBeClaimed[_collateral];
    }

    function _slippageIsValid(Batch storage _batch, address _collateral) internal view returns (bool) {
        uint256 staticPricePPM = _staticPricePPM(_batch.supply, _batch.balance, _batch.reserveRatio);
        uint256 maximumSlippage = _batch.slippage;

        // if static price is zero let's consider that every slippage is valid
        if (staticPricePPM == 0) {
            return true;
        }

        return _buySlippageIsValid(_batch, staticPricePPM, maximumSlippage) && _sellSlippageIsValid(_batch, staticPricePPM, maximumSlippage);
    }

    function _buySlippageIsValid(Batch storage _batch, uint256 _startingPricePPM, uint256 _maximumSlippage) internal view returns (bool) {
        /**
         * NOTE
         * the case where starting price is zero is handled
         * in the meta function _slippageIsValid()
        */

        /**
         * NOTE
         * slippage is valid if:
         * totalBuyReturn >= totalBuySpend / (startingPrice * (1 + maxSlippage))
         * totalBuyReturn >= totalBuySpend / ((startingPricePPM / PPM) * (1 + maximumSlippage / PCT_BASE))
         * totalBuyReturn >= totalBuySpend / ((startingPricePPM / PPM) * (1 + maximumSlippage / PCT_BASE))
         * totalBuyReturn >= totalBuySpend / ((startingPricePPM / PPM) * (PCT + maximumSlippage) / PCT_BASE)
         * totalBuyReturn * startingPrice * ( PCT + maximumSlippage) >= totalBuySpend * PCT_BASE * PPM
        */
        if (
            _batch.totalBuyReturn.mul(_startingPricePPM).mul(PCT_BASE.add(_maximumSlippage)) >=
            _batch.totalBuySpend.mul(PCT_BASE).mul(uint256(PPM))
        ) {
            return true;
        }

        return false;
    }

    function _sellSlippageIsValid(Batch storage _batch, uint256 _startingPricePPM, uint256 _maximumSlippage) internal view returns (bool) {
        /**
         * NOTE
         * the case where starting price is zero is handled
         * in the meta function _slippageIsValid()
        */

        // if allowed sell slippage >= 100%
        // then any sell slippage is valid
        if (_maximumSlippage >= PCT_BASE) {
            return true;
        }

        /**
         * NOTE
         * slippage is valid if
         * totalSellReturn >= startingPrice * (1 - maxSlippage) * totalBuySpend
         * totalSellReturn >= (startingPricePPM / PPM) * (1 - maximumSlippage / PCT_BASE) * totalBuySpend
         * totalSellReturn >= (startingPricePPM / PPM) * (PCT_BASE - maximumSlippage) * totalBuySpend / PCT_BASE
         * totalSellReturn * PCT_BASE * PPM = startingPricePPM * (PCT_BASE - maximumSlippage) * totalBuySpend
        */

        if (
            _batch.totalSellReturn.mul(PCT_BASE).mul(uint256(PPM)) >=
            _startingPricePPM.mul(PCT_BASE.sub(_maximumSlippage)).mul(_batch.totalSellSpend)
        ) {
            return true;
        }

        return false;
    }

    /* initialization functions */

    function _currentBatch(address _collateral) internal returns (uint256, Batch storage) {
        uint256 batchId = _currentBatchId();
        MetaBatch storage metaBatch = metaBatches[batchId];
        Batch storage batch = metaBatch.batches[_collateral];

        if (!metaBatch.initialized) {
            /**
             * NOTE
             * all collateral batches should be initialized with the same supply to
             * avoid price manipulation between different collaterals in the same meta-batch
             * we don't need to do the same with collateral balances as orders against one collateral
             * can't affect the pool's balance against another collateral and tap is a step-function
             * of the meta-batch duration
            */

            /**
             * NOTE
             * realSupply(metaBatch) = totalSupply(metaBatchInitialization) + tokensToBeMinted(metaBatchInitialization)
             * 1. buy and sell orders incoming during the current meta-batch and affecting totalSupply or tokensToBeMinted
             * should not be taken into account in the price computation [they are already a part of the batched pricing computation]
             * 2. the only way for totalSupply to be modified during a meta-batch [outside of incoming buy and sell orders]
             * is for buy orders from previous meta-batches to be claimed [and tokens to be minted]:
             * as such totalSupply(metaBatch) + tokenToBeMinted(metaBatch) will always equal totalSupply(metaBatchInitialization) + tokenToBeMinted(metaBatchInitialization)
            */
            metaBatch.realSupply = token.totalSupply().add(tokensToBeMinted);
            metaBatch.buyFeePct = buyFeePct;
            metaBatch.sellFeePct = sellFeePct;
            metaBatch.formula = formula;
            metaBatch.initialized = true;

            emit NewMetaBatch(batchId, metaBatch.realSupply, metaBatch.buyFeePct, metaBatch.sellFeePct, metaBatch.formula);
        }

        if (!batch.initialized) {
            /**
             * NOTE
             * supply(batch) = realSupply(metaBatch) + virtualSupply(batchInitialization)
             * virtualSupply can technically be updated during a batch: the on-going batch will still use
             * its value at the time of initialization [it's up to the updater to act wisely]
            */

            /**
             * NOTE
             * balance(batch) = poolBalance(batchInitialization) - collateralsToBeClaimed(batchInitialization) + virtualBalance(metaBatchInitialization)
             * 1. buy and sell orders incoming during the current batch and affecting poolBalance or collateralsToBeClaimed
             * should not be taken into account in the price computation [they are already a part of the batched price computation]
             * 2. the only way for poolBalance to be modified during a batch [outside of incoming buy and sell orders]
             * is for sell orders from previous meta-batches to be claimed [and collateral to be transfered] as the tap is a step-function of the meta-batch duration:
             * as such poolBalance(batch) - collateralsToBeClaimed(batch) will always equal poolBalance(batchInitialization) - collateralsToBeClaimed(batchInitialization)
             * 3. virtualBalance can technically be updated during a batch: the on-going batch will still use
             * its value at the time of initialization [it's up to the updater to act wisely]
            */
            controller.updateTappedAmount(_collateral);
            batch.supply = metaBatch.realSupply.add(collaterals[_collateral].virtualSupply);
            batch.balance = controller.balanceOf(address(reserve), _collateral).add(collaterals[_collateral].virtualBalance).sub(collateralsToBeClaimed[_collateral]);
            batch.reserveRatio = collaterals[_collateral].reserveRatio;
            batch.slippage = collaterals[_collateral].slippage;
            batch.initialized = true;

            emit NewBatch(batchId, _collateral, batch.supply, batch.balance, batch.reserveRatio, batch.slippage);
        }

        return (batchId, batch);
    }

    /* state modifiying functions */

    function _open() internal {
        isOpen = true;

        emit Open();
    }

    function _updateBeneficiary(address _beneficiary) internal {
        beneficiary = _beneficiary;

        emit UpdateBeneficiary(_beneficiary);
    }

    function _updateFormula(IBancorFormula _formula) internal {
        formula = _formula;

        emit UpdateFormula(address(_formula));
    }

    function _updateFees(uint256 _buyFeePct, uint256 _sellFeePct) internal {
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;

        emit UpdateFees(_buyFeePct, _sellFeePct);
    }

    function _cancelCurrentBatch(address _collateral) internal {
        (uint256 batchId, Batch storage batch) = _currentBatch(_collateral);
        if (!batch.cancelled) {
            batch.cancelled = true;

            // bought bonds are cancelled but sold bonds are due back
            // bought collaterals are cancelled but sold collaterals are due back
            tokensToBeMinted = tokensToBeMinted.sub(batch.totalBuyReturn).add(batch.totalSellSpend);
            collateralsToBeClaimed[_collateral] = collateralsToBeClaimed[_collateral].add(batch.totalBuySpend).sub(batch.totalSellReturn);

            emit CancelBatch(batchId, _collateral);
        }
    }

    function _addCollateralToken(address _collateral, uint256 _virtualSupply, uint256 _virtualBalance, uint32 _reserveRatio, uint256 _slippage)
        internal
    {
        collaterals[_collateral].whitelisted = true;
        collaterals[_collateral].virtualSupply = _virtualSupply;
        collaterals[_collateral].virtualBalance = _virtualBalance;
        collaterals[_collateral].reserveRatio = _reserveRatio;
        collaterals[_collateral].slippage = _slippage;

        emit AddCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    function _removeCollateralToken(address _collateral) internal {
        _cancelCurrentBatch(_collateral);

        Collateral storage collateral = collaterals[_collateral];
        delete collateral.whitelisted;
        delete collateral.virtualSupply;
        delete collateral.virtualBalance;
        delete collateral.reserveRatio;
        delete collateral.slippage;

        emit RemoveCollateralToken(_collateral);
    }

    function _updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage
    )
        internal
    {
        collaterals[_collateral].virtualSupply = _virtualSupply;
        collaterals[_collateral].virtualBalance = _virtualBalance;
        collaterals[_collateral].reserveRatio = _reserveRatio;
        collaterals[_collateral].slippage = _slippage;

        emit UpdateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    function _openBuyOrder(address _buyer, address _collateral, uint256 _value) internal {
        (uint256 batchId, Batch storage batch) = _currentBatch(_collateral);

        // deduct fee
        uint256 fee = _value.mul(metaBatches[batchId].buyFeePct).div(PCT_BASE);
        uint256 value = _value.sub(fee);

        // collect fee and collateral
        if (fee > 0) {
            _transfer(_buyer, beneficiary, _collateral, fee);
        }
        _transfer(_buyer, address(reserve), _collateral, value);

        // save batch
        uint256 deprecatedBuyReturn = batch.totalBuyReturn;
        uint256 deprecatedSellReturn = batch.totalSellReturn;

        // update batch
        batch.totalBuySpend = batch.totalBuySpend.add(value);
        batch.buyers[_buyer] = batch.buyers[_buyer].add(value);

        // update pricing
        _updatePricing(batch, batchId, _collateral);

        // update the amount of tokens to be minted and collaterals to be claimed
        tokensToBeMinted = tokensToBeMinted.sub(deprecatedBuyReturn).add(batch.totalBuyReturn);
        collateralsToBeClaimed[_collateral] = collateralsToBeClaimed[_collateral].sub(deprecatedSellReturn).add(batch.totalSellReturn);

        // sanity checks
        require(_slippageIsValid(batch, _collateral), ERROR_SLIPPAGE_EXCEEDS_LIMIT);

        emit OpenBuyOrder(_buyer, batchId, _collateral, fee, value);
    }

    function _openSellOrder(address _seller, address _collateral, uint256 _amount) internal {
        (uint256 batchId, Batch storage batch) = _currentBatch(_collateral);

        // burn bonds
        tokenManager.burn(_seller, _amount);

        // save batch
        uint256 deprecatedBuyReturn = batch.totalBuyReturn;
        uint256 deprecatedSellReturn = batch.totalSellReturn;

        // update batch
        batch.totalSellSpend = batch.totalSellSpend.add(_amount);
        batch.sellers[_seller] = batch.sellers[_seller].add(_amount);

        // update pricing
        _updatePricing(batch, batchId, _collateral);

        // update the amount of tokens to be minted and collaterals to be claimed
        tokensToBeMinted = tokensToBeMinted.sub(deprecatedBuyReturn).add(batch.totalBuyReturn);
        collateralsToBeClaimed[_collateral] = collateralsToBeClaimed[_collateral].sub(deprecatedSellReturn).add(batch.totalSellReturn);

        // sanity checks
        require(_slippageIsValid(batch, _collateral), ERROR_SLIPPAGE_EXCEEDS_LIMIT);
        require(_poolBalanceIsSufficient(_collateral), ERROR_INSUFFICIENT_POOL_BALANCE);

        emit OpenSellOrder(_seller, batchId, _collateral, _amount);
    }

    function _claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) internal {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];
        uint256 buyReturn = (batch.buyers[_buyer].mul(batch.totalBuyReturn)).div(batch.totalBuySpend);

        batch.buyers[_buyer] = 0;

        if (buyReturn > 0) {
            tokensToBeMinted = tokensToBeMinted.sub(buyReturn);
            tokenManager.mint(_buyer, buyReturn);
        }

        emit ClaimBuyOrder(_buyer, _batchId, _collateral, buyReturn);
    }

    function _claimSellOrder(address _seller, uint256 _batchId, address _collateral) internal {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];
        uint256 saleReturn = (batch.sellers[_seller].mul(batch.totalSellReturn)).div(batch.totalSellSpend);
        uint256 fee = saleReturn.mul(metaBatches[_batchId].sellFeePct).div(PCT_BASE);
        uint256 value = saleReturn.sub(fee);

        batch.sellers[_seller] = 0;

        if (value > 0) {
            collateralsToBeClaimed[_collateral] = collateralsToBeClaimed[_collateral].sub(saleReturn);
            reserve.transfer(_collateral, _seller, value);
        }
        if (fee > 0) {
            reserve.transfer(_collateral, beneficiary, fee);
        }


        emit ClaimSellOrder(_seller, _batchId, _collateral, fee, value);
    }

    function _claimCancelledBuyOrder(address _buyer, uint256 _batchId, address _collateral) internal {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];

        uint256 value = batch.buyers[_buyer];
        batch.buyers[_buyer] = 0;

        if (value > 0) {
            collateralsToBeClaimed[_collateral] = collateralsToBeClaimed[_collateral].sub(value);
            reserve.transfer(_collateral, _buyer, value);
        }

        emit ClaimCancelledBuyOrder(_buyer, _batchId, _collateral, value);
    }

    function _claimCancelledSellOrder(address _seller, uint256 _batchId, address _collateral) internal {
        Batch storage batch = metaBatches[_batchId].batches[_collateral];

        uint256 amount = batch.sellers[_seller];
        batch.sellers[_seller] = 0;

        if (amount > 0) {
            tokensToBeMinted = tokensToBeMinted.sub(amount);
            tokenManager.mint(_seller, amount);
        }

        emit ClaimCancelledSellOrder(_seller, _batchId, _collateral, amount);
    }

    function _updatePricing(Batch storage batch, uint256 _batchId, address _collateral) internal {
        // the situation where there are no buy nor sell orders can't happen [keep commented]
        // if (batch.totalSellSpend == 0 && batch.totalBuySpend == 0)
        //     return;

        // static price is the current exact price in collateral
        // per token according to the initial state of the batch
        // [expressed in PPM for precision sake]
        uint256 staticPricePPM = _staticPricePPM(batch.supply, batch.balance, batch.reserveRatio);

        // [NOTE]
        // if staticPrice is zero then resultOfSell [= 0] <= batch.totalBuySpend
        // so totalSellReturn will be zero and totalBuyReturn will be
        // computed normally along the formula

        // 1. we want to find out if buy orders are worth more sell orders [or vice-versa]
        // 2. we thus check the return of sell orders at the current exact price
        // 3. if the return of sell orders is larger than the pending buys,
        //    there are more sells than buys [and vice-versa]
        uint256 resultOfSell = batch.totalSellSpend.mul(staticPricePPM).div(uint256(PPM));

        if (resultOfSell > batch.totalBuySpend) {
            // >> sell orders are worth more than buy orders

            // 1. first we execute all pending buy orders at the current exact
            // price because there is at least one sell order for each buy order
            // 2. then the final sell return is the addition of this first
            // matched return with the remaining bonding curve return

            // the number of tokens bought as a result of all buy orders matched at the
            // current exact price [which is less than the total amount of tokens to be sold]
            batch.totalBuyReturn = batch.totalBuySpend.mul(uint256(PPM)).div(staticPricePPM);
            // the number of tokens left over to be sold along the curve which is the difference
            // between the original total sell order and the result of all the buy orders
            uint256 remainingSell = batch.totalSellSpend.sub(batch.totalBuyReturn);
            // the amount of collateral generated by selling tokens left over to be sold
            // along the bonding curve in the batch initial state [as if the buy orders
            // never existed and the sell order was just smaller than originally thought]
            uint256 remainingSellReturn = metaBatches[_batchId].formula.calculateSaleReturn(batch.supply, batch.balance, batch.reserveRatio, remainingSell);
            // the total result of all sells is the original amount of buys which were matched
            // plus the remaining sells which were executed along the bonding curve
            batch.totalSellReturn = batch.totalBuySpend.add(remainingSellReturn);
        } else {
            // >> buy orders are worth more than sell orders

            // 1. first we execute all pending sell orders at the current exact
            // price because there is at least one buy order for each sell order
            // 2. then the final buy return is the addition of this first
            // matched return with the remaining bonding curve return

            // the number of collaterals bought as a result of all sell orders matched at the
            // current exact price [which is less than the total amount of collateral to be spent]
            batch.totalSellReturn = resultOfSell;
            // the number of collaterals left over to be spent along the curve which is the difference
            // between the original total buy order and the result of all the sell orders
            uint256 remainingBuy = batch.totalBuySpend.sub(resultOfSell);
            // the amount of tokens generated by selling collaterals left over to be spent
            // along the bonding curve in the batch initial state [as if the sell orders
            // never existed and the buy order was just smaller than originally thought]
            uint256 remainingBuyReturn = metaBatches[_batchId].formula.calculatePurchaseReturn(batch.supply, batch.balance, batch.reserveRatio, remainingBuy);
            // the total result of all buys is the original amount of buys which were matched
            // plus the remaining buys which were executed along the bonding curve
            batch.totalBuyReturn = batch.totalSellSpend.add(remainingBuyReturn);
        }


        emit UpdatePricing(_batchId, _collateral, batch.totalBuySpend, batch.totalBuyReturn, batch.totalSellSpend, batch.totalSellReturn);
    }

    function _transfer(address _from, address _to, address _collateralToken, uint256 _amount) internal {
        if (_collateralToken == ETH) {
            _to.transfer(_amount);
        } else {
            require(ERC20(_collateralToken).safeTransferFrom(_from, _to, _amount), ERROR_TRANSFER_FROM_FAILED);
        }
    }
}

// File: @ablack/fundraising-shared-interfaces/contracts/IPresale.sol

pragma solidity 0.4.24;


contract IPresale {
    function open() external;
    function close() external;
    function contribute(address _contributor, uint256 _value) external payable;
    function refund(address _contributor, uint256 _vestedPurchaseId) external;
    function contributionToTokens(uint256 _value) public view returns (uint256);
    function contributionToken() public view returns (address);
 }

// File: @ablack/fundraising-shared-interfaces/contracts/ITap.sol

pragma solidity 0.4.24;


contract ITap {
     function updateBeneficiary(address _beneficiary) external;
     function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external;
     function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external;
     function addTappedToken(address _token, uint256 _rate, uint256 _floor) external;
     function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external;
     function resetTappedToken(address _token) external;
     function updateTappedAmount(address _token) external;
     function withdraw(address _token) external;
     function getMaximumWithdrawal(address _token) public view returns (uint256);
     function rates(address _token) public view returns (uint256);
 }

// File: @ablack/fundraising-aragon-fundraising/contracts/AragonFundraisingController.sol

pragma solidity 0.4.24;













contract AragonFundraisingController is EtherTokenConstant, IsContract, IAragonFundraisingController, AragonApp {
    using SafeERC20 for ERC20;
    using SafeMath  for uint256;

    /**
    Hardcoded constants to save gas
    bytes32 public constant UPDATE_BENEFICIARY_ROLE                    = keccak256("UPDATE_BENEFICIARY_ROLE");
    bytes32 public constant UPDATE_FEES_ROLE                           = keccak256("UPDATE_FEES_ROLE");
    bytes32 public constant ADD_COLLATERAL_TOKEN_ROLE                  = keccak256("ADD_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant REMOVE_COLLATERAL_TOKEN_ROLE               = keccak256("REMOVE_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant UPDATE_COLLATERAL_TOKEN_ROLE               = keccak256("UPDATE_COLLATERAL_TOKEN_ROLE");
    bytes32 public constant UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE  = keccak256("UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE");
    bytes32 public constant UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE = keccak256("UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE");
    bytes32 public constant ADD_TOKEN_TAP_ROLE                         = keccak256("ADD_TOKEN_TAP_ROLE");
    bytes32 public constant UPDATE_TOKEN_TAP_ROLE                      = keccak256("UPDATE_TOKEN_TAP_ROLE");
    bytes32 public constant OPEN_PRESALE_ROLE                          = keccak256("OPEN_PRESALE_ROLE");
    bytes32 public constant OPEN_TRADING_ROLE                          = keccak256("OPEN_TRADING_ROLE");
    bytes32 public constant CONTRIBUTE_ROLE                            = keccak256("CONTRIBUTE_ROLE");
    bytes32 public constant OPEN_BUY_ORDER_ROLE                        = keccak256("OPEN_BUY_ORDER_ROLE");
    bytes32 public constant OPEN_SELL_ORDER_ROLE                       = keccak256("OPEN_SELL_ORDER_ROLE");
    bytes32 public constant WITHDRAW_ROLE                              = keccak256("WITHDRAW_ROLE");
    */
    bytes32 public constant UPDATE_BENEFICIARY_ROLE                    = 0xf7ea2b80c7b6a2cab2c11d2290cb005c3748397358a25e17113658c83b732593;
    bytes32 public constant UPDATE_FEES_ROLE                           = 0x5f9be2932ed3a723f295a763be1804c7ebfd1a41c1348fb8bdf5be1c5cdca822;
    bytes32 public constant ADD_COLLATERAL_TOKEN_ROLE                  = 0x217b79cb2bc7760defc88529853ef81ab33ae5bb315408ce9f5af09c8776662d;
    bytes32 public constant REMOVE_COLLATERAL_TOKEN_ROLE               = 0x2044e56de223845e4be7d0a6f4e9a29b635547f16413a6d1327c58d9db438ee2;
    bytes32 public constant UPDATE_COLLATERAL_TOKEN_ROLE               = 0xe0565c2c43e0d841e206bb36a37f12f22584b4652ccee6f9e0c071b697a2e13d;
    bytes32 public constant UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE  = 0x5d94de7e429250eee4ff97e30ab9f383bea3cd564d6780e0a9e965b1add1d207;
    bytes32 public constant UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE = 0x57c9c67896cf0a4ffe92cbea66c2f7c34380af06bf14215dabb078cf8a6d99e1;
    bytes32 public constant ADD_TOKEN_TAP_ROLE                         = 0xbc9cb5e3f7ce81c4fd021d86a4bcb193dee9df315b540808c3ed59a81e596207;
    bytes32 public constant UPDATE_TOKEN_TAP_ROLE                      = 0xdb8c88bedbc61ea0f92e1ce46da0b7a915affbd46d1c76c4bbac9a209e4a8416;
    bytes32 public constant OPEN_PRESALE_ROLE                          = 0xf323aa41eef4850a8ae7ebd047d4c89f01ce49c781f3308be67303db9cdd48c2;
    bytes32 public constant OPEN_TRADING_ROLE                          = 0x26ce034204208c0bbca4c8a793d17b99e546009b1dd31d3c1ef761f66372caf6;
    bytes32 public constant CONTRIBUTE_ROLE                            = 0x9ccaca4edf2127f20c425fdd86af1ba178b9e5bee280cd70d88ac5f6874c4f07;
    bytes32 public constant OPEN_BUY_ORDER_ROLE                        = 0xa589c8f284b76fc8d510d9d553485c47dbef1b0745ae00e0f3fd4e28fcd77ea7;
    bytes32 public constant OPEN_SELL_ORDER_ROLE                       = 0xd68ba2b769fa37a2a7bd4bed9241b448bc99eca41f519ef037406386a8f291c0;
    bytes32 public constant WITHDRAW_ROLE                              = 0x5d8e12c39142ff96d79d04d15d1ba1269e4fe57bb9d26f43523628b34ba108ec;

    uint256 public constant TO_RESET_CAP = 10;

    string private constant ERROR_CONTRACT_IS_EOA = "FUNDRAISING_CONTRACT_IS_EOA";
    string private constant ERROR_INVALID_TOKENS  = "FUNDRAISING_INVALID_TOKENS";

    IPresale                 public presale;
    BatchedBancorMarketMaker public marketMaker;
    Agent                    public reserve;
    ITap                     public tap;
    address[]                public toReset;


    /***** external functions *****/

    /**
     * @notice Initialize Aragon Fundraising controller
     * @param _presale     The address of the presale contract
     * @param _marketMaker The address of the market maker contract
     * @param _reserve     The address of the reserve [pool] contract
     * @param _tap         The address of the tap contract
     * @param _toReset     The addresses of the tokens whose tap timestamps are to be reset [when presale is closed and trading is open]
    */
    function initialize(
        IPresale                 _presale,
        BatchedBancorMarketMaker _marketMaker,
        Agent                    _reserve,
        ITap                     _tap,
        address[]                _toReset
    )
        external
        onlyInit
    {
        require(isContract(_presale),           ERROR_CONTRACT_IS_EOA);
        require(isContract(_marketMaker),       ERROR_CONTRACT_IS_EOA);
        require(isContract(_reserve),           ERROR_CONTRACT_IS_EOA);
        require(isContract(_tap),               ERROR_CONTRACT_IS_EOA);
        require(_toReset.length < TO_RESET_CAP, ERROR_INVALID_TOKENS);

        initialized();

        presale = _presale;
        marketMaker = _marketMaker;
        reserve = _reserve;
        tap = _tap;

        for (uint256 i = 0; i < _toReset.length; i++) {
            require(_tokenIsContractOrETH(_toReset[i]), ERROR_INVALID_TOKENS);
            toReset.push(_toReset[i]);
        }
    }

    /* generic settings related function */

    /**
     * @notice Update beneficiary to `_beneficiary`
     * @param _beneficiary The address of the new beneficiary
    */
    function updateBeneficiary(address _beneficiary) external auth(UPDATE_BENEFICIARY_ROLE) {
        marketMaker.updateBeneficiary(_beneficiary);
        tap.updateBeneficiary(_beneficiary);
    }

    /**
     * @notice Update fees deducted from buy and sell orders to respectively `@formatPct(_buyFeePct)`% and `@formatPct(_sellFeePct)`%
     * @param _buyFeePct  The new fee to be deducted from buy orders [in PCT_BASE]
     * @param _sellFeePct The new fee to be deducted from sell orders [in PCT_BASE]
    */
    function updateFees(uint256 _buyFeePct, uint256 _sellFeePct) external auth(UPDATE_FEES_ROLE) {
        marketMaker.updateFees(_buyFeePct, _sellFeePct);
    }

    /* presale related functions */

    /**
     * @notice Open presale
    */
    function openPresale() external auth(OPEN_PRESALE_ROLE) {
        presale.open();
    }

    /**
     * @notice Close presale and open trading
    */
    function closePresale() external isInitialized {
        presale.close();
    }

    /**
     * @notice Contribute to the presale up to `@tokenAmount(self.contributionToken(): address, _value)`
     * @param _value The amount of contribution token to be spent
    */
    function contribute(uint256 _value) external payable auth(CONTRIBUTE_ROLE) {
        presale.contribute.value(msg.value)(msg.sender, _value);
    }

    /**
     * @notice Refund `_contributor`'s presale contribution #`_vestedPurchaseId`
     * @param _contributor      The address of the contributor whose presale contribution is to be refunded
     * @param _vestedPurchaseId The id of the contribution to be refunded
    */
    function refund(address _contributor, uint256 _vestedPurchaseId) external isInitialized {
        presale.refund(_contributor, _vestedPurchaseId);
    }

    /* market making related functions */

    /**
     * @notice Open trading [enabling users to open buy and sell orders]
    */
    function openTrading() external auth(OPEN_TRADING_ROLE) {
        for (uint256 i = 0; i < toReset.length; i++) {
            if (tap.rates(toReset[i]) != uint256(0)) {
                tap.resetTappedToken(toReset[i]);
            }
        }

        marketMaker.open();
    }

    /**
     * @notice Open a buy order worth `@tokenAmount(_collateral, _value)`
     * @param _collateral The address of the collateral token to be spent
     * @param _value      The amount of collateral token to be spent
    */
    function openBuyOrder(address _collateral, uint256 _value) external payable auth(OPEN_BUY_ORDER_ROLE) {
        marketMaker.openBuyOrder.value(msg.value)(msg.sender, _collateral, _value);
    }

    /**
     * @notice Open a sell order worth `@tokenAmount(self.token(): address, _amount)` against `_collateral.symbol(): string`
     * @param _collateral The address of the collateral token to be returned
     * @param _amount     The amount of bonded token to be spent
    */
    function openSellOrder(address _collateral, uint256 _amount) external auth(OPEN_SELL_ORDER_ROLE) {
        marketMaker.openSellOrder(msg.sender, _collateral, _amount);
    }

    /**
     * @notice Claim the results of `_collateral.symbol(): string` buy orders from batch #`_batchId`
     * @param _buyer      The address of the user whose buy orders are to be claimed
     * @param _batchId    The id of the batch in which buy orders are to be claimed
     * @param _collateral The address of the collateral token against which buy orders are to be claimed
    */
    function claimBuyOrder(address _buyer, uint256 _batchId, address _collateral) external isInitialized {
        marketMaker.claimBuyOrder(_buyer, _batchId, _collateral);
    }

    /**
     * @notice Claim the results of `_collateral.symbol(): string` sell orders from batch #`_batchId`
     * @param _seller     The address of the user whose sell orders are to be claimed
     * @param _batchId    The id of the batch in which sell orders are to be claimed
     * @param _collateral The address of the collateral token against which sell orders are to be claimed
    */
    function claimSellOrder(address _seller, uint256 _batchId, address _collateral) external isInitialized {
        marketMaker.claimSellOrder(_seller, _batchId, _collateral);
    }

    /* collateral tokens related functions */

    /**
     * @notice Add `_collateral.symbol(): string` as a whitelisted collateral token
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The price slippage below which each market making batch is to be kept for that collateral token [in PCT_BASE]
     * @param _rate           The rate at which that token is to be tapped [in wei / block]
     * @param _floor          The floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function addCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage,
        uint256 _rate,
        uint256 _floor
    )
    	external
        auth(ADD_COLLATERAL_TOKEN_ROLE)
    {
        marketMaker.addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
        if (_collateral != ETH) {
            reserve.addProtectedToken(_collateral);
        }
        if (_rate > 0) {
            tap.addTappedToken(_collateral, _rate, _floor);
        }
    }

    /**
     * @notice Re-add `_collateral.symbol(): string` as a whitelisted collateral token [if it has been un-whitelisted in the past]
     * @param _collateral     The address of the collateral token to be whitelisted
     * @param _virtualSupply  The virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The price slippage below which each market making batch is to be kept for that collateral token [in PCT_BASE]
    */
    function reAddCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage
    )
    	external
        auth(ADD_COLLATERAL_TOKEN_ROLE)
    {
        marketMaker.addCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    /**
      * @notice Remove `_collateral.symbol(): string` as a whitelisted collateral token
      * @param _collateral The address of the collateral token to be un-whitelisted
    */
    function removeCollateralToken(address _collateral) external auth(REMOVE_COLLATERAL_TOKEN_ROLE) {
        marketMaker.removeCollateralToken(_collateral);
        // the token should still be tapped to avoid being locked
        // the token should still be protected to avoid being spent
    }

    /**
     * @notice Update `_collateral.symbol(): string` collateralization settings
     * @param _collateral     The address of the collateral token whose collateralization settings are to be updated
     * @param _virtualSupply  The new virtual supply to be used for that collateral token [in wei]
     * @param _virtualBalance The new virtual balance to be used for that collateral token [in wei]
     * @param _reserveRatio   The new reserve ratio to be used for that collateral token [in PPM]
     * @param _slippage       The new price slippage below which each market making batch is to be kept for that collateral token [in PCT_BASE]
    */
    function updateCollateralToken(
        address _collateral,
        uint256 _virtualSupply,
        uint256 _virtualBalance,
        uint32  _reserveRatio,
        uint256 _slippage
    )
        external
        auth(UPDATE_COLLATERAL_TOKEN_ROLE)
    {
        marketMaker.updateCollateralToken(_collateral, _virtualSupply, _virtualBalance, _reserveRatio, _slippage);
    }

    /* tap related functions */

    /**
     * @notice Update maximum tap rate increase percentage to `@formatPct(_maximumTapRateIncreasePct)`%
     * @param _maximumTapRateIncreasePct The new maximum tap rate increase percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external auth(UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE) {
        tap.updateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }

    /**
     * @notice Update maximum tap floor decrease percentage to `@formatPct(_maximumTapFloorDecreasePct)`%
     * @param _maximumTapFloorDecreasePct The new maximum tap floor decrease percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external auth(UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE) {
        tap.updateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }

    /**
     * @notice Add tap for `_token.symbol(): string` with a rate of `@tokenAmount(_token, _rate)` per block and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token to be tapped
     * @param _rate  The rate at which that token is to be tapped [in wei / block]
     * @param _floor The floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function addTokenTap(address _token, uint256 _rate, uint256 _floor) external auth(ADD_TOKEN_TAP_ROLE) {
        tap.addTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Update tap for `_token.symbol(): string` with a rate of about `@tokenAmount(_token, 4 * 60 * 24 * 30 * _rate)` per month and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token whose tap is to be updated
     * @param _rate  The new rate at which that token is to be tapped [in wei / block]
     * @param _floor The new floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function updateTokenTap(address _token, uint256 _rate, uint256 _floor) external auth(UPDATE_TOKEN_TAP_ROLE) {
        tap.updateTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Update tapped amount for `_token.symbol(): string`
     * @param _token The address of the token whose tapped amount is to be updated
    */
    function updateTappedAmount(address _token) external {
        tap.updateTappedAmount(_token);
    }

    /**
     * @notice Transfer about `@tokenAmount(_token, self.getMaximumWithdrawal(_token): uint256)` from the reserve to the beneficiary
     * @param _token The address of the token to be transfered from the reserve to the beneficiary
    */
    function withdraw(address _token) external auth(WITHDRAW_ROLE) {
        tap.withdraw(_token);
    }

    /***** public view functions *****/

    function token() public view isInitialized returns (address) {
        return marketMaker.token();
    }

    function contributionToken() public view isInitialized returns (address) {
        return presale.contributionToken();
    }

    function getMaximumWithdrawal(address _token) public view isInitialized returns (uint256) {
        return tap.getMaximumWithdrawal(_token);
    }

    function collateralsToBeClaimed(address _collateral) public view isInitialized returns (uint256) {
        return marketMaker.collateralsToBeClaimed(_collateral);
    }

    function balanceOf(address _who, address _token) public view isInitialized returns (uint256) {
        uint256 balance = _token == ETH ? _who.balance : ERC20(_token).staticBalanceOf(_who);

        if (_who == address(reserve)) {
            return balance.sub(tap.getMaximumWithdrawal(_token));
        } else {
            return balance;
        }
    }

    /***** internal functions *****/

     function _tokenIsContractOrETH(address _token) internal view returns (bool) {
        return isContract(_token) || _token == ETH;
    }
}

// File: @ablack/fundraising-presale/contracts/Presale.sol

pragma solidity ^0.4.24;











contract Presale is IPresale, EtherTokenConstant, IsContract, AragonApp {
    using SafeERC20  for ERC20;
    using SafeMath   for uint256;
    using SafeMath64 for uint64;

    /**
    Hardcoded constants to save gas
    bytes32 public constant OPEN_ROLE       = keccak256("OPEN_ROLE");
    bytes32 public constant CONTRIBUTE_ROLE = keccak256("CONTRIBUTE_ROLE");
    */
    bytes32 public constant OPEN_ROLE       = 0xefa06053e2ca99a43c97c4a4f3d8a394ee3323a8ff237e625fba09fe30ceb0a4;
    bytes32 public constant CONTRIBUTE_ROLE = 0x9ccaca4edf2127f20c425fdd86af1ba178b9e5bee280cd70d88ac5f6874c4f07;

    uint256 public constant PPM = 1000000; // 0% = 0 * 10 ** 4; 1% = 1 * 10 ** 4; 100% = 100 * 10 ** 4

    string private constant ERROR_CONTRACT_IS_EOA          = "PRESALE_CONTRACT_IS_EOA";
    string private constant ERROR_INVALID_BENEFICIARY      = "PRESALE_INVALID_BENEFICIARY";
    string private constant ERROR_INVALID_CONTRIBUTE_TOKEN = "PRESALE_INVALID_CONTRIBUTE_TOKEN";
    string private constant ERROR_INVALID_GOAL             = "PRESALE_INVALID_GOAL";
    string private constant ERROR_INVALID_EXCHANGE_RATE    = "PRESALE_INVALID_EXCHANGE_RATE";
    string private constant ERROR_INVALID_TIME_PERIOD      = "PRESALE_INVALID_TIME_PERIOD";
    string private constant ERROR_INVALID_PCT              = "PRESALE_INVALID_PCT";
    string private constant ERROR_INVALID_STATE            = "PRESALE_INVALID_STATE";
    string private constant ERROR_INVALID_CONTRIBUTE_VALUE = "PRESALE_INVALID_CONTRIBUTE_VALUE";
    string private constant ERROR_INSUFFICIENT_BALANCE     = "PRESALE_INSUFFICIENT_BALANCE";
    string private constant ERROR_INSUFFICIENT_ALLOWANCE   = "PRESALE_INSUFFICIENT_ALLOWANCE";
    string private constant ERROR_NOTHING_TO_REFUND        = "PRESALE_NOTHING_TO_REFUND";
    string private constant ERROR_TOKEN_TRANSFER_REVERTED  = "PRESALE_TOKEN_TRANSFER_REVERTED";

    enum State {
        Pending,     // presale is idle and pending to be started
        Funding,     // presale has started and contributors can purchase tokens
        Refunding,   // presale has not reached goal within period and contributors can claim refunds
        GoalReached, // presale has reached goal within period and trading is ready to be open
        Closed       // presale has reached goal within period, has been closed and trading has been open
    }

    IAragonFundraisingController                    public controller;
    TokenManager                                    public tokenManager;
    ERC20                                           public token;
    address                                         public reserve;
    address                                         public beneficiary;
    address                                         public contributionToken;

    uint256                                         public goal;
    uint64                                          public period;
    uint256                                         public exchangeRate;
    uint64                                          public vestingCliffPeriod;
    uint64                                          public vestingCompletePeriod;
    uint256                                         public supplyOfferedPct;
    uint256                                         public fundingForBeneficiaryPct;
    uint64                                          public openDate;

    bool                                            public isClosed;
    uint64                                          public vestingCliffDate;
    uint64                                          public vestingCompleteDate;
    uint256                                         public totalRaised;
    mapping(address => mapping(uint256 => uint256)) public contributions; // contributor => (vestedPurchaseId => tokensSpent)

    event SetOpenDate (uint64 date);
    event Close       ();
    event Contribute  (address indexed contributor, uint256 value, uint256 amount, uint256 vestedPurchaseId);
    event Refund      (address indexed contributor, uint256 value, uint256 amount, uint256 vestedPurchaseId);


    /***** external function *****/

    /**
     * @notice Initialize presale
     * @param _controller               The address of the controller contract
     * @param _tokenManager             The address of the [bonded] token manager contract
     * @param _reserve                  The address of the reserve [pool] contract
     * @param _beneficiary              The address of the beneficiary [to whom a percentage of the raised funds is be to be sent]
     * @param _contributionToken        The address of the token to be used to contribute
     * @param _goal                     The goal to be reached by the end of that presale [in contribution token wei]
     * @param _period                   The period within which to accept contribution for that presale
     * @param _exchangeRate             The exchangeRate [= 1/price] at which [bonded] tokens are to be purchased for that presale [in PPM]
     * @param _vestingCliffPeriod       The period during which purchased [bonded] tokens are to be cliffed
     * @param _vestingCompletePeriod    The complete period during which purchased [bonded] tokens are to be vested
     * @param _supplyOfferedPct         The percentage of the initial supply of [bonded] tokens to be offered during that presale [in PPM]
     * @param _fundingForBeneficiaryPct The percentage of the raised contribution tokens to be sent to the beneficiary [instead of the fundraising reserve] when that presale is closed [in PPM]
     * @param _openDate                 The date upon which that presale is to be open [ignored if 0]
    */
    function initialize(
        IAragonFundraisingController _controller,
        TokenManager                 _tokenManager,
        address                      _reserve,
        address                      _beneficiary,
        address                      _contributionToken,
        uint256                      _goal,
        uint64                       _period,
        uint256                      _exchangeRate,
        uint64                       _vestingCliffPeriod,
        uint64                       _vestingCompletePeriod,
        uint256                      _supplyOfferedPct,
        uint256                      _fundingForBeneficiaryPct,
        uint64                       _openDate
    )
        external
        onlyInit
    {
        require(isContract(_controller),                                            ERROR_CONTRACT_IS_EOA);
        require(isContract(_tokenManager),                                          ERROR_CONTRACT_IS_EOA);
        require(isContract(_reserve),                                               ERROR_CONTRACT_IS_EOA);
        require(_beneficiary != address(0),                                         ERROR_INVALID_BENEFICIARY);
        require(isContract(_contributionToken) || _contributionToken == ETH,        ERROR_INVALID_CONTRIBUTE_TOKEN);
        require(_goal > 0,                                                          ERROR_INVALID_GOAL);
        require(_period > 0,                                                        ERROR_INVALID_TIME_PERIOD);
        require(_exchangeRate > 0,                                                  ERROR_INVALID_EXCHANGE_RATE);
        require(_vestingCliffPeriod > _period,                                      ERROR_INVALID_TIME_PERIOD);
        require(_vestingCompletePeriod > _vestingCliffPeriod,                       ERROR_INVALID_TIME_PERIOD);
        require(_supplyOfferedPct > 0 && _supplyOfferedPct <= PPM,                  ERROR_INVALID_PCT);
        require(_fundingForBeneficiaryPct >= 0 && _fundingForBeneficiaryPct <= PPM, ERROR_INVALID_PCT);

        initialized();

        controller = _controller;
        tokenManager = _tokenManager;
        token = ERC20(_tokenManager.token());
        reserve = _reserve;
        beneficiary = _beneficiary;
        contributionToken = _contributionToken;
        goal = _goal;
        period = _period;
        exchangeRate = _exchangeRate;
        vestingCliffPeriod = _vestingCliffPeriod;
        vestingCompletePeriod = _vestingCompletePeriod;
        supplyOfferedPct = _supplyOfferedPct;
        fundingForBeneficiaryPct = _fundingForBeneficiaryPct;

        if (_openDate != 0) {
            _setOpenDate(_openDate);
        }
    }

    /**
     * @notice Open presale [enabling users to contribute]
    */
    function open() external auth(OPEN_ROLE) {
        require(state() == State.Pending, ERROR_INVALID_STATE);
        require(openDate == 0,            ERROR_INVALID_STATE);

        _open();
    }

    /**
     * @notice Contribute to the presale up to `@tokenAmount(self.contributionToken(): address, _value)`
     * @param _contributor The address of the contributor
     * @param _value       The amount of contribution token to be spent
    */
    function contribute(address _contributor, uint256 _value) external payable nonReentrant auth(CONTRIBUTE_ROLE) {
        require(state() == State.Funding, ERROR_INVALID_STATE);
        require(_value != 0,              ERROR_INVALID_CONTRIBUTE_VALUE);

        if (contributionToken == ETH) {
            require(msg.value == _value, ERROR_INVALID_CONTRIBUTE_VALUE);
        } else {
            require(msg.value == 0,      ERROR_INVALID_CONTRIBUTE_VALUE);
        }

        _contribute(_contributor, _value);
    }

    /**
     * @notice Refund `_contributor`'s presale contribution #`_vestedPurchaseId`
     * @param _contributor      The address of the contributor whose presale contribution is to be refunded
     * @param _vestedPurchaseId The id of the contribution to be refunded
    */
    function refund(address _contributor, uint256 _vestedPurchaseId) external nonReentrant isInitialized {
        require(state() == State.Refunding, ERROR_INVALID_STATE);

        _refund(_contributor, _vestedPurchaseId);
    }

    /**
     * @notice Close presale and open trading
    */
    function close() external nonReentrant isInitialized {
        require(state() == State.GoalReached, ERROR_INVALID_STATE);

        _close();
    }

    /***** public view functions *****/

    /**
     * @notice Computes the amount of [bonded] tokens that would be purchased for `@tokenAmount(self.contributionToken(): address, _value)`
     * @param _value The amount of contribution tokens to be used in that computation
    */
    function contributionToTokens(uint256 _value) public view isInitialized returns (uint256) {
        return _value.mul(exchangeRate).div(PPM);
    }

    function contributionToken() public view isInitialized returns (address) {
        return contributionToken;
    }

    /**
     * @notice Returns the current state of that presale
    */
    function state() public view isInitialized returns (State) {
        if (openDate == 0 || openDate > getTimestamp64()) {
            return State.Pending;
        }

        if (totalRaised >= goal) {
            if (isClosed) {
                return State.Closed;
            } else {
                return State.GoalReached;
            }
        }

        if (_timeSinceOpen() < period) {
            return State.Funding;
        } else {
            return State.Refunding;
        }
    }

    /***** internal functions *****/

    function _timeSinceOpen() internal view returns (uint64) {
        if (openDate == 0) {
            return 0;
        } else {
            return getTimestamp64().sub(openDate);
        }
    }

    function _setOpenDate(uint64 _date) internal {
        require(_date >= getTimestamp64(), ERROR_INVALID_TIME_PERIOD);

        openDate = _date;
        _setVestingDatesWhenOpenDateIsKnown();

        emit SetOpenDate(_date);
    }

    function _setVestingDatesWhenOpenDateIsKnown() internal {
        vestingCliffDate = openDate.add(vestingCliffPeriod);
        vestingCompleteDate = openDate.add(vestingCompletePeriod);
    }

    function _open() internal {
        _setOpenDate(getTimestamp64());
    }

    function _contribute(address _contributor, uint256 _value) internal {
        uint256 value = totalRaised.add(_value) > goal ? goal.sub(totalRaised) : _value;
        if (contributionToken == ETH && _value > value) {
            msg.sender.transfer(_value.sub(value));
        }

        // (contributor) ~~~> contribution tokens ~~~> (presale)
        if (contributionToken != ETH) {
            require(ERC20(contributionToken).balanceOf(_contributor) >= value,                ERROR_INSUFFICIENT_BALANCE);
            require(ERC20(contributionToken).allowance(_contributor, address(this)) >= value, ERROR_INSUFFICIENT_ALLOWANCE);
            _transfer(contributionToken, _contributor, address(this), value);
        }
        // (mint ✨) ~~~> project tokens ~~~> (contributor)
        uint256 tokensToSell = contributionToTokens(value);
        tokenManager.issue(tokensToSell);
        uint256 vestedPurchaseId = tokenManager.assignVested(
            _contributor,
            tokensToSell,
            openDate,
            vestingCliffDate,
            vestingCompleteDate,
            true /* revokable */
        );
        totalRaised = totalRaised.add(value);
        // register contribution tokens spent in this purchase for a possible upcoming refund
        contributions[_contributor][vestedPurchaseId] = value;

        emit Contribute(_contributor, value, tokensToSell, vestedPurchaseId);
    }

    function _refund(address _contributor, uint256 _vestedPurchaseId) internal {
        // recall how much contribution tokens are to be refund for this purchase
        uint256 tokensToRefund = contributions[_contributor][_vestedPurchaseId];
        require(tokensToRefund > 0, ERROR_NOTHING_TO_REFUND);
        contributions[_contributor][_vestedPurchaseId] = 0;
        // (presale) ~~~> contribution tokens ~~~> (contributor)
        _transfer(contributionToken, address(this), _contributor, tokensToRefund);
        /**
         * NOTE
         * the following lines assume that _contributor has not transfered any of its vested tokens
         * for now TokenManager does not handle switching the transferrable status of its underlying token
         * there is thus no way to enforce non-transferrability during the presale phase only
         * this will be updated in a later version
        */
        // (contributor) ~~~> project tokens ~~~> (token manager)
        (uint256 tokensSold,,,,) = tokenManager.getVesting(_contributor, _vestedPurchaseId);
        tokenManager.revokeVesting(_contributor, _vestedPurchaseId);
        // (token manager) ~~~> project tokens ~~~> (burn 💥)
        tokenManager.burn(address(tokenManager), tokensSold);

        emit Refund(_contributor, tokensToRefund, tokensSold, _vestedPurchaseId);
    }

    function _close() internal {
        isClosed = true;

        // (presale) ~~~> contribution tokens ~~~> (beneficiary)
        uint256 fundsForBeneficiary = totalRaised.mul(fundingForBeneficiaryPct).div(PPM);
        if (fundsForBeneficiary > 0) {
            _transfer(contributionToken, address(this), beneficiary, fundsForBeneficiary);
        }
        // (presale) ~~~> contribution tokens ~~~> (reserve)
        uint256 tokensForReserve = contributionToken == ETH ? address(this).balance : ERC20(contributionToken).balanceOf(address(this));

        _transfer(contributionToken, address(this), reserve, tokensForReserve);
        // (mint ✨) ~~~> project tokens ~~~> (beneficiary)
        uint256 tokensForBeneficiary = token.totalSupply().mul(PPM.sub(supplyOfferedPct)).div(supplyOfferedPct);
        tokenManager.issue(tokensForBeneficiary);
        tokenManager.assignVested(
            beneficiary,
            tokensForBeneficiary,
            openDate,
            vestingCliffDate,
            vestingCompleteDate,
            false /* revokable */
        );
        // open trading
        controller.openTrading();

        emit Close();
    }

    function _transfer(address _token, address _from, address _to, uint256 _amount) internal {
        if (_token == ETH) {
            require(_from == address(this), ERROR_TOKEN_TRANSFER_REVERTED);
            require(_to != address(this),   ERROR_TOKEN_TRANSFER_REVERTED);
            _to.transfer(_amount);
        } else {
            if (_from == address(this)) {
                require(ERC20(_token).safeTransfer(_to, _amount), ERROR_TOKEN_TRANSFER_REVERTED);
            } else {
                require(ERC20(_token).safeTransferFrom(_from, _to, _amount), ERROR_TOKEN_TRANSFER_REVERTED);
            }
        }
    }
}

// File: @ablack/fundraising-tap/contracts/Tap.sol

pragma solidity 0.4.24;












contract Tap is ITap, TimeHelpers, EtherTokenConstant, IsContract, AragonApp {
    using SafeERC20 for ERC20;
    using SafeMath  for uint256;

    /**
    Hardcoded constants to save gas
    bytes32 public constant UPDATE_CONTROLLER_ROLE                     = keccak256("UPDATE_CONTROLLER_ROLE");
    bytes32 public constant UPDATE_RESERVE_ROLE                        = keccak256("UPDATE_RESERVE_ROLE");
    bytes32 public constant UPDATE_BENEFICIARY_ROLE                    = keccak256("UPDATE_BENEFICIARY_ROLE");
    bytes32 public constant UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE  = keccak256("UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE");
    bytes32 public constant UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE = keccak256("UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE");
    bytes32 public constant ADD_TAPPED_TOKEN_ROLE                      = keccak256("ADD_TAPPED_TOKEN_ROLE");
    bytes32 public constant REMOVE_TAPPED_TOKEN_ROLE                   = keccak256("REMOVE_TAPPED_TOKEN_ROLE");
    bytes32 public constant UPDATE_TAPPED_TOKEN_ROLE                   = keccak256("UPDATE_TAPPED_TOKEN_ROLE");
    bytes32 public constant RESET_TAPPED_TOKEN_ROLE                    = keccak256("RESET_TAPPED_TOKEN_ROLE");
    bytes32 public constant WITHDRAW_ROLE                              = keccak256("WITHDRAW_ROLE");
    */
    bytes32 public constant UPDATE_CONTROLLER_ROLE                     = 0x454b5d0dbb74f012faf1d3722ea441689f97dc957dd3ca5335b4969586e5dc30;
    bytes32 public constant UPDATE_RESERVE_ROLE                        = 0x7984c050833e1db850f5aa7476710412fd2983fcec34da049502835ad7aed4f7;
    bytes32 public constant UPDATE_BENEFICIARY_ROLE                    = 0xf7ea2b80c7b6a2cab2c11d2290cb005c3748397358a25e17113658c83b732593;
    bytes32 public constant UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE  = 0x5d94de7e429250eee4ff97e30ab9f383bea3cd564d6780e0a9e965b1add1d207;
    bytes32 public constant UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE = 0x57c9c67896cf0a4ffe92cbea66c2f7c34380af06bf14215dabb078cf8a6d99e1;
    bytes32 public constant ADD_TAPPED_TOKEN_ROLE                      = 0x5bc3b608e6be93b75a1c472a4a5bea3d31eabae46bf968e4bc4c7701562114dc;
    bytes32 public constant REMOVE_TAPPED_TOKEN_ROLE                   = 0xd76960be78bfedc5b40ce4fa64a2f8308f39dd2cbb1f9676dbc4ce87b817befd;
    bytes32 public constant UPDATE_TAPPED_TOKEN_ROLE                   = 0x83201394534c53ae0b4696fd49a933082d3e0525aa5a3d0a14a2f51e12213288;
    bytes32 public constant RESET_TAPPED_TOKEN_ROLE                    = 0x294bf52c518669359157a9fe826e510dfc3dbd200d44bf77ec9536bff34bc29e;
    bytes32 public constant WITHDRAW_ROLE                              = 0x5d8e12c39142ff96d79d04d15d1ba1269e4fe57bb9d26f43523628b34ba108ec;

    uint256 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10 ** 16; 100% = 10 ** 18

    string private constant ERROR_CONTRACT_IS_EOA            = "TAP_CONTRACT_IS_EOA";
    string private constant ERROR_INVALID_BENEFICIARY        = "TAP_INVALID_BENEFICIARY";
    string private constant ERROR_INVALID_BATCH_BLOCKS       = "TAP_INVALID_BATCH_BLOCKS";
    string private constant ERROR_INVALID_FLOOR_DECREASE_PCT = "TAP_INVALID_FLOOR_DECREASE_PCT";
    string private constant ERROR_INVALID_TOKEN              = "TAP_INVALID_TOKEN";
    string private constant ERROR_INVALID_TAP_RATE           = "TAP_INVALID_TAP_RATE";
    string private constant ERROR_INVALID_TAP_UPDATE         = "TAP_INVALID_TAP_UPDATE";
    string private constant ERROR_TOKEN_ALREADY_TAPPED       = "TAP_TOKEN_ALREADY_TAPPED";
    string private constant ERROR_TOKEN_NOT_TAPPED           = "TAP_TOKEN_NOT_TAPPED";
    string private constant ERROR_WITHDRAWAL_AMOUNT_ZERO     = "TAP_WITHDRAWAL_AMOUNT_ZERO";

    IAragonFundraisingController public controller;
    Vault                        public reserve;
    address                      public beneficiary;
    uint256                      public batchBlocks;
    uint256                      public maximumTapRateIncreasePct;
    uint256                      public maximumTapFloorDecreasePct;

    mapping (address => uint256) public tappedAmounts;
    mapping (address => uint256) public rates;
    mapping (address => uint256) public floors;
    mapping (address => uint256) public lastTappedAmountUpdates; // batch ids [block numbers]
    mapping (address => uint256) public lastTapUpdates;  // timestamps

    event UpdateBeneficiary               (address indexed beneficiary);
    event UpdateMaximumTapRateIncreasePct (uint256 maximumTapRateIncreasePct);
    event UpdateMaximumTapFloorDecreasePct(uint256 maximumTapFloorDecreasePct);
    event AddTappedToken                  (address indexed token, uint256 rate, uint256 floor);
    event RemoveTappedToken               (address indexed token);
    event UpdateTappedToken               (address indexed token, uint256 rate, uint256 floor);
    event ResetTappedToken                (address indexed token);
    event UpdateTappedAmount              (address indexed token, uint256 tappedAmount);
    event Withdraw                        (address indexed token, uint256 amount);


    /***** external functions *****/

    /**
     * @notice Initialize tap
     * @param _controller                 The address of the controller contract
     * @param _reserve                    The address of the reserve [pool] contract
     * @param _beneficiary                The address of the beneficiary [to whom funds are to be withdrawn]
     * @param _batchBlocks                The number of blocks batches are to last
     * @param _maximumTapRateIncreasePct  The maximum tap rate increase percentage allowed [in PCT_BASE]
     * @param _maximumTapFloorDecreasePct The maximum tap floor decrease percentage allowed [in PCT_BASE]
    */
    function initialize(
        IAragonFundraisingController _controller,
        Vault                        _reserve,
        address                      _beneficiary,
        uint256                      _batchBlocks,
        uint256                      _maximumTapRateIncreasePct,
        uint256                      _maximumTapFloorDecreasePct
    )
        external
        onlyInit
    {
        require(isContract(_controller),                                         ERROR_CONTRACT_IS_EOA);
        require(isContract(_reserve),                                            ERROR_CONTRACT_IS_EOA);
        require(_beneficiaryIsValid(_beneficiary),                               ERROR_INVALID_BENEFICIARY);
        require(_batchBlocks != 0,                                               ERROR_INVALID_BATCH_BLOCKS);
        require(_maximumTapFloorDecreasePctIsValid(_maximumTapFloorDecreasePct), ERROR_INVALID_FLOOR_DECREASE_PCT);

        initialized();

        controller = _controller;
        reserve = _reserve;
        beneficiary = _beneficiary;
        batchBlocks = _batchBlocks;
        maximumTapRateIncreasePct = _maximumTapRateIncreasePct;
        maximumTapFloorDecreasePct = _maximumTapFloorDecreasePct;
    }

    /**
     * @notice Update beneficiary to `_beneficiary`
     * @param _beneficiary The address of the new beneficiary [to whom funds are to be withdrawn]
    */
    function updateBeneficiary(address _beneficiary) external auth(UPDATE_BENEFICIARY_ROLE) {
        require(_beneficiaryIsValid(_beneficiary), ERROR_INVALID_BENEFICIARY);

        _updateBeneficiary(_beneficiary);
    }

    /**
     * @notice Update maximum tap rate increase percentage to `@formatPct(_maximumTapRateIncreasePct)`%
     * @param _maximumTapRateIncreasePct The new maximum tap rate increase percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) external auth(UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE) {
        _updateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }

    /**
     * @notice Update maximum tap floor decrease percentage to `@formatPct(_maximumTapFloorDecreasePct)`%
     * @param _maximumTapFloorDecreasePct The new maximum tap floor decrease percentage to be allowed [in PCT_BASE]
    */
    function updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) external auth(UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE) {
        require(_maximumTapFloorDecreasePctIsValid(_maximumTapFloorDecreasePct), ERROR_INVALID_FLOOR_DECREASE_PCT);

        _updateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }

    /**
     * @notice Add tap for `_token.symbol(): string` with a rate of `@tokenAmount(_token, _rate)` per block and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token to be tapped
     * @param _rate  The rate at which that token is to be tapped [in wei / block]
     * @param _floor The floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function addTappedToken(address _token, uint256 _rate, uint256 _floor) external auth(ADD_TAPPED_TOKEN_ROLE) {
        require(_tokenIsContractOrETH(_token), ERROR_INVALID_TOKEN);
        require(!_tokenIsTapped(_token),       ERROR_TOKEN_ALREADY_TAPPED);
        require(_tapRateIsValid(_rate),        ERROR_INVALID_TAP_RATE);

        _addTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Remove tap for `_token.symbol(): string`
     * @param _token The address of the token to be un-tapped
    */
    function removeTappedToken(address _token) external auth(REMOVE_TAPPED_TOKEN_ROLE) {
        require(_tokenIsTapped(_token), ERROR_TOKEN_NOT_TAPPED);

        _removeTappedToken(_token);
    }

    /**
     * @notice Update tap for `_token.symbol(): string` with a rate of `@tokenAmount(_token, _rate)` per block and a floor of `@tokenAmount(_token, _floor)`
     * @param _token The address of the token whose tap is to be updated
     * @param _rate  The new rate at which that token is to be tapped [in wei / block]
     * @param _floor The new floor above which the reserve [pool] balance for that token is to be kept [in wei]
    */
    function updateTappedToken(address _token, uint256 _rate, uint256 _floor) external auth(UPDATE_TAPPED_TOKEN_ROLE) {
        require(_tokenIsTapped(_token),                   ERROR_TOKEN_NOT_TAPPED);
        require(_tapRateIsValid(_rate),                   ERROR_INVALID_TAP_RATE);
        require(_tapUpdateIsValid(_token, _rate, _floor), ERROR_INVALID_TAP_UPDATE);

        _updateTappedToken(_token, _rate, _floor);
    }

    /**
     * @notice Reset tap timestamps for `_token.symbol(): string`
     * @param _token The address of the token whose tap timestamps are to be reset
    */
    function resetTappedToken(address _token) external auth(RESET_TAPPED_TOKEN_ROLE) {
        require(_tokenIsTapped(_token), ERROR_TOKEN_NOT_TAPPED);

        _resetTappedToken(_token);
    }

    /**
     * @notice Update tapped amount for `_token.symbol(): string`
     * @param _token The address of the token whose tapped amount is to be updated
    */
    function updateTappedAmount(address _token) external {
        require(_tokenIsTapped(_token), ERROR_TOKEN_NOT_TAPPED);

        _updateTappedAmount(_token);
    }

    /**
     * @notice Transfer about `@tokenAmount(_token, self.getMaximalWithdrawal(_token): uint256)` from `self.reserve()` to `self.beneficiary()`
     * @param _token The address of the token to be transfered
    */
    function withdraw(address _token) external auth(WITHDRAW_ROLE) {
        require(_tokenIsTapped(_token), ERROR_TOKEN_NOT_TAPPED);
        uint256 amount = _updateTappedAmount(_token);
        require(amount > 0, ERROR_WITHDRAWAL_AMOUNT_ZERO);

        _withdraw(_token, amount);
    }

    /***** public view functions *****/

    function getMaximumWithdrawal(address _token) public view isInitialized returns (uint256) {
        return _tappedAmount(_token);
    }

    function rates(address _token) public view isInitialized returns (uint256) {
        return rates[_token];
    }

    /***** internal functions *****/

    /* computation functions */

    function _currentBatchId() internal view returns (uint256) {
        return (block.number.div(batchBlocks)).mul(batchBlocks);
    }

    function _tappedAmount(address _token) internal view returns (uint256) {
        uint256 toBeKept = controller.collateralsToBeClaimed(_token).add(floors[_token]);
        uint256 balance = _token == ETH ? address(reserve).balance : ERC20(_token).staticBalanceOf(reserve);
        uint256 flow = (_currentBatchId().sub(lastTappedAmountUpdates[_token])).mul(rates[_token]);
        uint256 tappedAmount = tappedAmounts[_token].add(flow);
        /**
         * whatever happens enough collateral should be
         * kept in the reserve pool to guarantee that
         * its balance is kept above the floor once
         * all pending sell orders are claimed
        */

        /**
         * the reserve's balance is already below the balance to be kept
         * the tapped amount should be reset to zero
        */
        if (balance <= toBeKept) {
            return 0;
        }

        /**
         * the reserve's balance minus the upcoming tap flow would be below the balance to be kept
         * the flow should be reduced to balance - toBeKept
        */
        if (balance <= toBeKept.add(tappedAmount)) {
            return balance.sub(toBeKept);
        }

        /**
         * the reserve's balance minus the upcoming flow is above the balance to be kept
         * the flow can be added to the tapped amount
        */
        return tappedAmount;
    }

    /* check functions */

    function _beneficiaryIsValid(address _beneficiary) internal pure returns (bool) {
        return _beneficiary != address(0);
    }

    function _maximumTapFloorDecreasePctIsValid(uint256 _maximumTapFloorDecreasePct) internal pure returns (bool) {
        return _maximumTapFloorDecreasePct <= PCT_BASE;
    }

    function _tokenIsContractOrETH(address _token) internal view returns (bool) {
        return isContract(_token) || _token == ETH;
    }

    function _tokenIsTapped(address _token) internal view returns (bool) {
        return rates[_token] != uint256(0);
    }

    function _tapRateIsValid(uint256 _rate) internal pure returns (bool) {
        return _rate != 0;
    }

    function _tapUpdateIsValid(address _token, uint256 _rate, uint256 _floor) internal view returns (bool) {
        return _tapRateUpdateIsValid(_token, _rate) && _tapFloorUpdateIsValid(_token, _floor);
    }

    function _tapRateUpdateIsValid(address _token, uint256 _rate) internal view returns (bool) {
        uint256 rate = rates[_token];

        if (_rate <= rate) {
            return true;
        }

        if (getTimestamp() < lastTapUpdates[_token] + 30 days) {
            return false;
        }

        if (_rate.mul(PCT_BASE) <= rate.mul(PCT_BASE.add(maximumTapRateIncreasePct))) {
            return true;
        }

        return false;
    }

    function _tapFloorUpdateIsValid(address _token, uint256 _floor) internal view returns (bool) {
        uint256 floor = floors[_token];

        if (_floor >= floor) {
            return true;
        }

        if (getTimestamp() < lastTapUpdates[_token] + 30 days) {
            return false;
        }

        if (maximumTapFloorDecreasePct >= PCT_BASE) {
            return true;
        }

        if (_floor.mul(PCT_BASE) >= floor.mul(PCT_BASE.sub(maximumTapFloorDecreasePct))) {
            return true;
        }

        return false;
    }

    /* state modifying functions */

    function _updateTappedAmount(address _token) internal returns (uint256) {
        uint256 tappedAmount = _tappedAmount(_token);
        lastTappedAmountUpdates[_token] = _currentBatchId();
        tappedAmounts[_token] = tappedAmount;

        emit UpdateTappedAmount(_token, tappedAmount);

        return tappedAmount;
    }

    function _updateBeneficiary(address _beneficiary) internal {
        beneficiary = _beneficiary;

        emit UpdateBeneficiary(_beneficiary);
    }

    function _updateMaximumTapRateIncreasePct(uint256 _maximumTapRateIncreasePct) internal {
        maximumTapRateIncreasePct = _maximumTapRateIncreasePct;

        emit UpdateMaximumTapRateIncreasePct(_maximumTapRateIncreasePct);
    }

    function _updateMaximumTapFloorDecreasePct(uint256 _maximumTapFloorDecreasePct) internal {
        maximumTapFloorDecreasePct = _maximumTapFloorDecreasePct;

        emit UpdateMaximumTapFloorDecreasePct(_maximumTapFloorDecreasePct);
    }

    function _addTappedToken(address _token, uint256 _rate, uint256 _floor) internal {
        /**
         * NOTE
         * 1. if _token is tapped in the middle of a batch it will
         * reach the next batch faster than what it normally takes
         * to go through a batch [e.g. one block later]
         * 2. this will allow for a higher withdrawal than expected
         * a few blocks after _token is tapped
         * 3. this is not a problem because this extra amount is
         * static [at most rates[_token] * batchBlocks] and does
         * not increase in time
        */
        rates[_token] = _rate;
        floors[_token] = _floor;
        lastTappedAmountUpdates[_token] = _currentBatchId();
        lastTapUpdates[_token] = getTimestamp();

        emit AddTappedToken(_token, _rate, _floor);
    }

    function _removeTappedToken(address _token) internal {
        delete tappedAmounts[_token];
        delete rates[_token];
        delete floors[_token];
        delete lastTappedAmountUpdates[_token];
        delete lastTapUpdates[_token];

        emit RemoveTappedToken(_token);
    }

    function _updateTappedToken(address _token, uint256 _rate, uint256 _floor) internal {
        /**
         * NOTE
         * withdraw before updating to keep the reserve
         * actual balance [balance - virtual withdrawal]
         * continuous in time [though a floor update can
         * still break this continuity]
        */
        uint256 amount = _updateTappedAmount(_token);
        if (amount > 0) {
            _withdraw(_token, amount);
        }

        rates[_token] = _rate;
        floors[_token] = _floor;
        lastTapUpdates[_token] = getTimestamp();

        emit UpdateTappedToken(_token, _rate, _floor);
    }

    function _resetTappedToken(address _token) internal {
        tappedAmounts[_token] = 0;
        lastTappedAmountUpdates[_token] = _currentBatchId();
        lastTapUpdates[_token] = getTimestamp();

        emit ResetTappedToken(_token);
    }

    function _withdraw(address _token, uint256 _amount) internal {
        tappedAmounts[_token] = tappedAmounts[_token].sub(_amount);
        reserve.transfer(_token, beneficiary, _amount); // vault contract's transfer method already reverts on error

        emit Withdraw(_token, _amount);
    }
}

// File: contracts/AavegotchiTBCTemplate.sol

pragma solidity 0.4.24;










contract AavegotchiTBCTemplate is EtherTokenConstant, BaseTemplate {
    string    private constant ERROR_BAD_SETTINGS     = "FM_BAD_SETTINGS";
    string    private constant ERROR_MISSING_CACHE    = "FM_MISSING_CACHE";

    bool      private constant BOARD_TRANSFERABLE     = false;
    uint8     private constant BOARD_TOKEN_DECIMALS   = uint8(0);
    uint256   private constant BOARD_MAX_PER_ACCOUNT  = uint256(1);

    bool      private constant SHARE_TRANSFERABLE     = true;
    uint8     private constant SHARE_TOKEN_DECIMALS   = uint8(18);
    uint256   private constant SHARE_MAX_PER_ACCOUNT  = uint256(0);

    uint64    private constant DEFAULT_FINANCE_PERIOD = uint64(30 days);

    uint256   private constant BUY_FEE_PCT            = 0;
    uint256   private constant SELL_FEE_PCT           = 0;

    uint32    private constant DAI_RESERVE_RATIO      = 333333; // 33%
    uint32    private constant ANT_RESERVE_RATIO      = 10000;  // 1%

    bytes32   private constant BANCOR_FORMULA_ID      = 0xd71dde5e4bea1928026c1779bde7ed27bd7ef3d0ce9802e4117631eb6fa4ed7d;
    bytes32   private constant PRESALE_ID             = 0x5de9bbdeaf6584c220c7b7f1922383bcd8bbcd4b48832080afd9d5ebf9a04df5;
    bytes32   private constant MARKET_MAKER_ID        = 0xc2bb88ab974c474221f15f691ed9da38be2f5d37364180cec05403c656981bf0;
    bytes32   private constant ARAGON_FUNDRAISING_ID  = 0x668ac370eed7e5861234d1c0a1e512686f53594fcb887e5bcecc35675a4becac;
    bytes32   private constant TAP_ID                 = 0x82967efab7144b764bc9bca2f31a721269b6618c0ff4e50545737700a5e9c9dc;

    struct Cache {
        address dao;
        address boardTokenManager;
        address boardVoting;
        address vault;
        address finance;
        address shareVoting;
        address shareTokenManager;
        address reserve;
        address presale;
        address marketMaker;
        address tap;
        address controller;
    }

    address[] public collaterals;
    mapping (address => Cache) private cache;

    constructor(
        DAOFactory              _daoFactory,
        ENS                     _ens,
        MiniMeTokenFactory      _miniMeFactory,
        IFIFSResolvingRegistrar _aragonID,
        address                 _dai,
        address                 _ant
    )
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
        require(isContract(_dai), ERROR_BAD_SETTINGS);
        require(isContract(_ant), ERROR_BAD_SETTINGS);
        require(_dai != _ant,     ERROR_BAD_SETTINGS);

        collaterals.push(_dai);
        collaterals.push(_ant);
    }

    /***** external functions *****/

    function prepareInstance(
        string    _boardTokenName,
        string    _boardTokenSymbol,
        address[] _boardMembers,
        uint64[3] _boardVotingSettings,
        uint64    _financePeriod
    )
        external
    {
        require(_boardMembers.length > 0,         ERROR_BAD_SETTINGS);
        require(_boardVotingSettings.length == 3, ERROR_BAD_SETTINGS);

        // deploy DAO
        (Kernel dao, ACL acl) = _createDAO();
        // deploy board token
        MiniMeToken boardToken = _createToken(_boardTokenName, _boardTokenSymbol, BOARD_TOKEN_DECIMALS);
        // install board apps
        TokenManager tm = _installBoardApps(dao, boardToken, _boardVotingSettings, _financePeriod);
        // mint board tokens
        _mintTokens(acl, tm, _boardMembers, 1);
        // cache DAO
        _cacheDao(dao);
    }

    function installShareApps(
        string    _shareTokenName,
        string    _shareTokenSymbol,
        uint64[3] _shareVotingSettings
    )
        external
    {
        require(_shareVotingSettings.length == 3, ERROR_BAD_SETTINGS);
        _ensureBoardAppsCache();

        Kernel dao = _daoCache();
        // deploy share token
        MiniMeToken shareToken = _createToken(_shareTokenName, _shareTokenSymbol, SHARE_TOKEN_DECIMALS);
        // install share apps
        _installShareApps(dao, shareToken, _shareVotingSettings);
        // setup board apps permissions [now that share apps have been installed]
        _setupBoardPermissions(dao);
    }

    function installFundraisingApps(
        uint256 _goal,
        uint64  _period,
        uint256 _exchangeRate,
        uint64  _vestingCliffPeriod,
        uint64  _vestingCompletePeriod,
        uint256 _supplyOfferedPct,
        uint256 _fundingForBeneficiaryPct,
        uint64  _openDate,
        uint256 _batchBlocks,
        uint256 _maxTapRateIncreasePct,
        uint256 _maxTapFloorDecreasePct
    )
        external
    {
        _ensureShareAppsCache();

        Kernel dao = _daoCache();
        // install fundraising apps
        _installFundraisingApps(
            dao,
            _goal,
            _period,
            _exchangeRate,
            _vestingCliffPeriod,
            _vestingCompletePeriod,
            _supplyOfferedPct,
            _fundingForBeneficiaryPct,
            _openDate,
            _batchBlocks,
            _maxTapRateIncreasePct,
            _maxTapFloorDecreasePct
        );
        // setup share apps permissions [now that fundraising apps have been installed]
        _setupSharePermissions(dao);
        // setup fundraising apps permissions
        _setupFundraisingPermissions(dao);
    }

    function finalizeInstance(
        string     _id,
        uint256[2] _virtualSupplies,
        uint256[2] _virtualBalances,
        uint256[2] _slippages,
        uint256    _rateDAI,
        uint256    _floorDAI
    )
        external
    {
        require(bytes(_id).length > 0,        ERROR_BAD_SETTINGS);
        require(_virtualSupplies.length == 2, ERROR_BAD_SETTINGS);
        require(_virtualBalances.length == 2, ERROR_BAD_SETTINGS);
        require(_slippages.length == 2,       ERROR_BAD_SETTINGS);
        _ensureFundraisingAppsCache();

        Kernel dao = _daoCache();
        ACL acl = ACL(dao.acl());
        (, Voting shareVoting) = _shareAppsCache();

        // setup collaterals
        _setupCollaterals(dao, _virtualSupplies, _virtualBalances, _slippages, _rateDAI, _floorDAI);
        // setup EVM script registry permissions
        _createEvmScriptsRegistryPermissions(acl, shareVoting, shareVoting);
        // clear DAO permissions
        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, shareVoting, shareVoting);
        // register id
        _registerID(_id, address(dao));
        // clear cache
        _clearCache();
    }

    /***** internal apps installation functions *****/

    function _installBoardApps(Kernel _dao, MiniMeToken _token, uint64[3] _votingSettings, uint64 _financePeriod)
        internal
        returns (TokenManager)
    {
        TokenManager tm = _installTokenManagerApp(_dao, _token, BOARD_TRANSFERABLE, BOARD_MAX_PER_ACCOUNT);
        Voting voting = _installVotingApp(_dao, _token, _votingSettings);
        Vault vault = _installVaultApp(_dao);
        Finance finance = _installFinanceApp(_dao, vault, _financePeriod == 0 ? DEFAULT_FINANCE_PERIOD : _financePeriod);

        _cacheBoardApps(tm, voting, vault, finance);

        return tm;
    }

    function _installShareApps(Kernel _dao, MiniMeToken _shareToken, uint64[3] _shareVotingSettings)
        internal
    {
        TokenManager tm = _installTokenManagerApp(_dao, _shareToken, SHARE_TRANSFERABLE, SHARE_MAX_PER_ACCOUNT);
        Voting voting = _installVotingApp(_dao, _shareToken, _shareVotingSettings);

        _cacheShareApps(tm, voting);
    }

    function _installFundraisingApps(
        Kernel  _dao,
        uint256 _goal,
        uint64  _period,
        uint256 _exchangeRate,
        uint64  _vestingCliffPeriod,
        uint64  _vestingCompletePeriod,
        uint256 _supplyOfferedPct,
        uint256 _fundingForBeneficiaryPct,
        uint64  _openDate,
        uint256 _batchBlocks,
        uint256 _maxTapRateIncreasePct,
        uint256 _maxTapFloorDecreasePct
    )
        internal
    {
        _proxifyFundraisingApps(_dao);

        _initializePresale(
            _goal,
            _period,
            _exchangeRate,
            _vestingCliffPeriod,
            _vestingCompletePeriod,
            _supplyOfferedPct,
            _fundingForBeneficiaryPct,
            _openDate
        );
        _initializeMarketMaker(_batchBlocks);
        _initializeTap(_batchBlocks, _maxTapRateIncreasePct, _maxTapFloorDecreasePct);
        _initializeController();
    }

    function _proxifyFundraisingApps(Kernel _dao) internal {
        Agent reserve = _installNonDefaultAgentApp(_dao);
        Presale presale = Presale(_registerApp(_dao, PRESALE_ID));
        BatchedBancorMarketMaker marketMaker = BatchedBancorMarketMaker(_registerApp(_dao, MARKET_MAKER_ID));
        Tap tap = Tap(_registerApp(_dao, TAP_ID));
        AragonFundraisingController controller = AragonFundraisingController(_registerApp(_dao, ARAGON_FUNDRAISING_ID));

        _cacheFundraisingApps(reserve, presale, marketMaker, tap, controller);
    }

    /***** internal apps initialization functions *****/

    function _initializePresale(
        uint256 _goal,
        uint64  _period,
        uint256 _exchangeRate,
        uint64  _vestingCliffPeriod,
        uint64  _vestingCompletePeriod,
        uint256 _supplyOfferedPct,
        uint256 _fundingForBeneficiaryPct,
        uint64  _openDate
    )
        internal
    {
        _presaleCache().initialize(
            _controllerCache(),
            _shareTMCache(),
            _reserveCache(),
            _vaultCache(),
            collaterals[0],
            _goal,
            _period,
            _exchangeRate,
            _vestingCliffPeriod,
            _vestingCompletePeriod,
            _supplyOfferedPct,
            _fundingForBeneficiaryPct,
            _openDate
        );
    }

    function _initializeMarketMaker(uint256 _batchBlocks) internal {
        IBancorFormula bancorFormula = IBancorFormula(_latestVersionAppBase(BANCOR_FORMULA_ID));

        (,, Vault beneficiary,) = _boardAppsCache();
        (TokenManager shareTM,) = _shareAppsCache();
        (Agent reserve,, BatchedBancorMarketMaker marketMaker,, AragonFundraisingController controller) = _fundraisingAppsCache();

        marketMaker.initialize(controller, shareTM, bancorFormula, reserve, beneficiary, _batchBlocks, BUY_FEE_PCT, SELL_FEE_PCT);
    }

    function _initializeTap(uint256 _batchBlocks, uint256 _maxTapRateIncreasePct, uint256 _maxTapFloorDecreasePct) internal {
        (,, Vault beneficiary,) = _boardAppsCache();
        (Agent reserve,,, Tap tap, AragonFundraisingController controller) = _fundraisingAppsCache();

        tap.initialize(controller, reserve, beneficiary, _batchBlocks, _maxTapRateIncreasePct, _maxTapFloorDecreasePct);
    }

    function _initializeController() internal {
        (Agent reserve, Presale presale, BatchedBancorMarketMaker marketMaker, Tap tap, AragonFundraisingController controller) = _fundraisingAppsCache();
        address[] memory toReset = new address[](1);
        toReset[0] = collaterals[0];
        controller.initialize(presale, marketMaker, reserve, tap, toReset);
    }

    /***** internal setup functions *****/

    function _setupCollaterals(
        Kernel     _dao,
        uint256[2] _virtualSupplies,
        uint256[2] _virtualBalances,
        uint256[2] _slippages,
        uint256    _rateDAI,
        uint256    _floorDAI
    )
        internal
    {
        ACL acl = ACL(_dao.acl());
        (, Voting shareVoting) = _shareAppsCache();
        (,,,, AragonFundraisingController controller) = _fundraisingAppsCache();

        // create and grant ADD_COLLATERAL_TOKEN_ROLE to this template
        _createPermissionForTemplate(acl, address(controller), controller.ADD_COLLATERAL_TOKEN_ROLE());
        // add DAI both as a protected collateral and a tapped token
        controller.addCollateralToken(
            collaterals[0],
            _virtualSupplies[0],
            _virtualBalances[0],
            DAI_RESERVE_RATIO,
            _slippages[0],
            _rateDAI,
            _floorDAI
        );
        // add ANT as a protected collateral [but not as a tapped token]
        controller.addCollateralToken(
            collaterals[1],
            _virtualSupplies[1],
            _virtualBalances[1],
            ANT_RESERVE_RATIO,
            _slippages[1],
            0,
            0
        );
        // transfer ADD_COLLATERAL_TOKEN_ROLE
        _transferPermissionFromTemplate(acl, controller, shareVoting, controller.ADD_COLLATERAL_TOKEN_ROLE(), shareVoting);
    }

    /***** internal permissions functions *****/

    function _setupBoardPermissions(Kernel _dao) internal {
        ACL acl = ACL(_dao.acl());

        (TokenManager boardTM, Voting boardVoting, Vault vault, Finance finance) = _boardAppsCache();
        (, Voting shareVoting) = _shareAppsCache();

        // token manager
        _createTokenManagerPermissions(acl, boardTM, boardVoting, shareVoting);
        // voting
        _createVotingPermissions(acl, boardVoting, boardVoting, boardTM, shareVoting);
        // vault
        _createVaultPermissions(acl, vault, finance, shareVoting);
        // finance
        _createFinancePermissions(acl, finance, boardVoting, shareVoting);
        _createFinanceCreatePaymentsPermission(acl, finance, boardVoting, shareVoting);
    }

    function _setupSharePermissions(Kernel _dao) internal {
        ACL acl = ACL(_dao.acl());

        (TokenManager boardTM,,,) = _boardAppsCache();
        (TokenManager shareTM, Voting shareVoting) = _shareAppsCache();
        (, Presale presale, BatchedBancorMarketMaker marketMaker,,) = _fundraisingAppsCache();

        // token manager
        address[] memory grantees = new address[](2);
        grantees[0] = address(marketMaker);
        grantees[1] = address(presale);
        acl.createPermission(marketMaker, shareTM, shareTM.MINT_ROLE(),shareVoting);
        acl.createPermission(presale, shareTM, shareTM.ISSUE_ROLE(),shareVoting);
        acl.createPermission(presale, shareTM, shareTM.ASSIGN_ROLE(),shareVoting);
        acl.createPermission(presale, shareTM, shareTM.REVOKE_VESTINGS_ROLE(), shareVoting);
        _createPermissions(acl, grantees, shareTM, shareTM.BURN_ROLE(), shareVoting);
        // voting
        _createVotingPermissions(acl, shareVoting, shareVoting, boardTM, shareVoting);
    }

    function _setupFundraisingPermissions(Kernel _dao) internal {
        ACL acl = ACL(_dao.acl());

        (, Voting boardVoting,,) = _boardAppsCache();
        (, Voting shareVoting) = _shareAppsCache();
        (Agent reserve, Presale presale, BatchedBancorMarketMaker marketMaker, Tap tap, AragonFundraisingController controller) = _fundraisingAppsCache();

        // reserve
        address[] memory grantees = new address[](2);
        grantees[0] = address(tap);
        grantees[1] = address(marketMaker);
        acl.createPermission(shareVoting, reserve, reserve.SAFE_EXECUTE_ROLE(), shareVoting);
        acl.createPermission(controller, reserve, reserve.ADD_PROTECTED_TOKEN_ROLE(), shareVoting);
        _createPermissions(acl, grantees, reserve, reserve.TRANSFER_ROLE(), shareVoting);
        // presale
        acl.createPermission(controller, presale, presale.OPEN_ROLE(), shareVoting);
        acl.createPermission(controller, presale, presale.CONTRIBUTE_ROLE(), shareVoting);
        // market maker
        acl.createPermission(controller, marketMaker, marketMaker.OPEN_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.UPDATE_BENEFICIARY_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.UPDATE_FEES_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.ADD_COLLATERAL_TOKEN_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.REMOVE_COLLATERAL_TOKEN_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.UPDATE_COLLATERAL_TOKEN_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.OPEN_BUY_ORDER_ROLE(), shareVoting);
        acl.createPermission(controller, marketMaker, marketMaker.OPEN_SELL_ORDER_ROLE(), shareVoting);
        // tap
        acl.createPermission(controller, tap, tap.UPDATE_BENEFICIARY_ROLE(), shareVoting);
        acl.createPermission(controller, tap, tap.UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE(), shareVoting);
        acl.createPermission(controller, tap, tap.UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE(), shareVoting);
        acl.createPermission(controller, tap, tap.ADD_TAPPED_TOKEN_ROLE(), shareVoting);
        acl.createPermission(controller, tap, tap.UPDATE_TAPPED_TOKEN_ROLE(), shareVoting);
        acl.createPermission(controller, tap, tap.RESET_TAPPED_TOKEN_ROLE(), shareVoting);
        acl.createPermission(controller, tap, tap.WITHDRAW_ROLE(), shareVoting);
        // controller
        // ADD_COLLATERAL_TOKEN_ROLE is handled later [after collaterals have been added]
        acl.createPermission(shareVoting, controller, controller.UPDATE_BENEFICIARY_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.UPDATE_FEES_ROLE(), shareVoting);
        // acl.createPermission(shareVoting, controller, controller.ADD_COLLATERAL_TOKEN_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.REMOVE_COLLATERAL_TOKEN_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.UPDATE_COLLATERAL_TOKEN_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.UPDATE_MAXIMUM_TAP_RATE_INCREASE_PCT_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.UPDATE_MAXIMUM_TAP_FLOOR_DECREASE_PCT_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.ADD_TOKEN_TAP_ROLE(), shareVoting);
        acl.createPermission(shareVoting, controller, controller.UPDATE_TOKEN_TAP_ROLE(), shareVoting);
        acl.createPermission(boardVoting, controller, controller.OPEN_PRESALE_ROLE(), shareVoting);
        acl.createPermission(presale, controller, controller.OPEN_TRADING_ROLE(), shareVoting);
        acl.createPermission(address(-1), controller, controller.CONTRIBUTE_ROLE(), shareVoting);
        acl.createPermission(address(-1), controller, controller.OPEN_BUY_ORDER_ROLE(), shareVoting);
        acl.createPermission(address(-1), controller, controller.OPEN_SELL_ORDER_ROLE(), shareVoting);
        acl.createPermission(address(-1), controller, controller.WITHDRAW_ROLE(), shareVoting);
    }

    /***** internal cache functions *****/

    function _cacheDao(Kernel _dao) internal {
        Cache storage c = cache[msg.sender];

        c.dao = address(_dao);
    }

    function _cacheBoardApps(TokenManager _boardTM, Voting _boardVoting, Vault _vault, Finance _finance) internal {
        Cache storage c = cache[msg.sender];

        c.boardTokenManager = address(_boardTM);
        c.boardVoting = address(_boardVoting);
        c.vault = address(_vault);
        c.finance = address(_finance);
    }

    function _cacheShareApps(TokenManager _shareTM, Voting _shareVoting) internal {
        Cache storage c = cache[msg.sender];

        c.shareTokenManager = address(_shareTM);
        c.shareVoting = address(_shareVoting);
    }

    function _cacheFundraisingApps(Agent _reserve, Presale _presale, BatchedBancorMarketMaker _marketMaker, Tap _tap, AragonFundraisingController _controller) internal {
        Cache storage c = cache[msg.sender];

        c.reserve = address(_reserve);
        c.presale = address(_presale);
        c.marketMaker = address(_marketMaker);
        c.tap = address(_tap);
        c.controller = address(_controller);
    }

    function _daoCache() internal view returns (Kernel dao) {
        Cache storage c = cache[msg.sender];

        dao = Kernel(c.dao);
    }

    function _boardAppsCache() internal view returns (TokenManager boardTM, Voting boardVoting, Vault vault, Finance finance) {
        Cache storage c = cache[msg.sender];

        boardTM = TokenManager(c.boardTokenManager);
        boardVoting = Voting(c.boardVoting);
        vault = Vault(c.vault);
        finance = Finance(c.finance);
    }

    function _shareAppsCache() internal view returns (TokenManager shareTM, Voting shareVoting) {
        Cache storage c = cache[msg.sender];

        shareTM = TokenManager(c.shareTokenManager);
        shareVoting = Voting(c.shareVoting);
    }

    function _fundraisingAppsCache() internal view returns (
        Agent reserve,
        Presale presale,
        BatchedBancorMarketMaker marketMaker,
        Tap tap,
        AragonFundraisingController controller
    )
    {
        Cache storage c = cache[msg.sender];

        reserve = Agent(c.reserve);
        presale = Presale(c.presale);
        marketMaker = BatchedBancorMarketMaker(c.marketMaker);
        tap = Tap(c.tap);
        controller = AragonFundraisingController(c.controller);
    }

    function _clearCache() internal {
        Cache storage c = cache[msg.sender];

        delete c.dao;
        delete c.boardTokenManager;
        delete c.boardVoting;
        delete c.vault;
        delete c.finance;
        delete c.shareVoting;
        delete c.shareTokenManager;
        delete c.reserve;
        delete c.presale;
        delete c.marketMaker;
        delete c.tap;
        delete c.controller;
    }

    /**
     * NOTE
     * the following functions are only needed for the presale
     * initialization function [which we can't compile otherwise
     * because of a `stack too deep` error]
    */

    function _vaultCache() internal view returns (Vault vault) {
        Cache storage c = cache[msg.sender];

        vault = Vault(c.vault);
    }

    function _shareTMCache() internal view returns (TokenManager shareTM) {
        Cache storage c = cache[msg.sender];

        shareTM = TokenManager(c.shareTokenManager);
    }

    function _reserveCache() internal view returns (Agent reserve) {
        Cache storage c = cache[msg.sender];

        reserve = Agent(c.reserve);
    }

    function _presaleCache() internal view returns (Presale presale) {
        Cache storage c = cache[msg.sender];

        presale = Presale(c.presale);
    }

    function _controllerCache() internal view returns (AragonFundraisingController controller) {
        Cache storage c = cache[msg.sender];

        controller = AragonFundraisingController(c.controller);
    }

    /***** internal check functions *****/

    function _ensureBoardAppsCache() internal view {
        Cache storage c = cache[msg.sender];
        require(
            c.boardTokenManager != address(0) &&
            c.boardVoting != address(0) &&
            c.vault != address(0) &&
            c.finance != address(0),
            ERROR_MISSING_CACHE
        );
    }

    function _ensureShareAppsCache() internal view {
        Cache storage c = cache[msg.sender];
        require(
            c.shareTokenManager != address(0) &&
            c.shareVoting != address(0),
            ERROR_MISSING_CACHE
        );
    }

    function _ensureFundraisingAppsCache() internal view {
        Cache storage c = cache[msg.sender];
        require(
            c.reserve != address(0) &&
            c.presale != address(0) &&
            c.marketMaker != address(0) &&
            c.tap != address(0) &&
            c.controller != address(0),
            ERROR_MISSING_CACHE
        );
    }

    /***** internal utils functions *****/

    function _registerApp(Kernel _dao, bytes32 _appId) internal returns (address) {
        address proxy = _dao.newAppInstance(_appId, _latestVersionAppBase(_appId));

        emit InstalledApp(proxy, _appId);

        return proxy;
    }
}