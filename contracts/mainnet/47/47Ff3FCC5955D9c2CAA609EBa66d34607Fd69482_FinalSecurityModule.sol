// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// File: contracts/lib/EIP712.sol

// Copyright 2017 Loopring Technology Limited.

library EIP712
{
    struct Domain {
        string  name;
        string  version;
        address verifyingContract;
    }

    bytes32 constant internal EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    string constant internal EIP191_HEADER = "\x19\x01";

    function hash(Domain memory domain)
        internal
        pure
        returns (bytes32)
    {
        uint _chainid;
        assembly { _chainid := chainid() }

        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                _chainid,
                domain.verifyingContract
            )
        );
    }

    function hashPacked(
        bytes32 domainSeperator,
        bytes   memory encodedData
        )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(EIP191_HEADER, domainSeperator, keccak256(encodedData))
        );
    }
}

// File: contracts/thirdparty/BytesUtil.sol

//Mainly taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

library BytesUtil {
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint24(bytes memory _bytes, uint _start) internal  pure returns (uint24) {
        require(_bytes.length >= (_start + 3));
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4(bytes memory _bytes, uint _start) internal  pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function fastSHA256(
        bytes memory data
        )
        internal
        view
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](1);
        bool success;
        assembly {
             let ptr := add(data, 32)
             success := staticcall(sub(gas(), 2000), 2, ptr, mload(data), add(result, 32), 32)
        }
        require(success, "SHA256_FAILED");
        return result[0];
    }
}

// File: contracts/lib/AddressUtil.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Utility Functions for addresses
/// @author Daniel Wang - <daniel@loopring.org>
/// @author Brecht Devos - <brecht@loopring.org>
library AddressUtil
{
    using AddressUtil for *;

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(addr) }
        return (codehash != 0x0 &&
                codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function toPayable(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return payable(addr);
    }

    // Works like address.send but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.toPayable();
        /* solium-disable-next-line */
        (success,) = recipient.call{value: amount, gas: gasLimit}("");
    }

    // Works like address.transfer but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETHAndVerify(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.sendETH(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }

    // Works like call but is slightly more efficient when data
    // needs to be copied from memory to do the call.
    function fastCall(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bool success, bytes memory returnData)
    {
        if (to != address(0)) {
            assembly {
                // Do the call
                success := call(gasLimit, to, value, add(data, 32), mload(data), 0, 0)
                // Copy the return data
                let size := returndatasize()
                returnData := mload(0x40)
                mstore(returnData, size)
                returndatacopy(add(returnData, 32), 0, size)
                // Update free memory pointer
                mstore(0x40, add(returnData, add(32, size)))
            }
        }
    }

    // Like fastCall, but throws when the call is unsuccessful.
    function fastCallAndVerify(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = fastCall(to, gasLimit, value, data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

// File: contracts/lib/ERC1271.sol

// Copyright 2017 Loopring Technology Limited.

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
        bytes32      _hash,
        bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValueB32);
}

// File: contracts/lib/MathUint.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Utility Functions for uint
/// @author Daniel Wang - <daniel@loopring.org>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}

// File: contracts/lib/SignatureUtil.sol

// Copyright 2017 Loopring Technology Limited.






/// @title SignatureUtil
/// @author Daniel Wang - <daniel@loopring.org>
/// @dev This method supports multihash standard. Each signature's last byte indicates
///      the signature's type.
library SignatureUtil
{
    using BytesUtil     for bytes;
    using MathUint      for uint;
    using AddressUtil   for address;

    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP_712,
        ETH_SIGN,
        WALLET   // deprecated
    }

    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function verifySignatures(
        bytes32          signHash,
        address[] memory signers,
        bytes[]   memory signatures
        )
        internal
        view
        returns (bool)
    {
        require(signers.length == signatures.length, "BAD_SIGNATURE_DATA");
        address lastSigner;
        for (uint i = 0; i < signers.length; i++) {
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];
            if (!verifySignature(signHash, signers[i], signatures[i])) {
                return false;
            }
        }
        return true;
    }

    function verifySignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        internal
        view
        returns (bool)
    {
        if (signer == address(0)) {
            return false;
        }

        return signer.isContract()?
            verifyERC1271Signature(signHash, signer, signature):
            verifyEOASignature(signHash, signer, signature);
    }

    function recoverECDSASigner(
        bytes32      signHash,
        bytes memory signature
        )
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            return address(0);
        }

        bytes32 r;
        bytes32 s;
        uint8   v;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := and(mload(add(signature, 0x41)), 0xff)
        }
        // See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v == 27 || v == 28) {
            return ecrecover(signHash, v, r, s);
        } else {
            return address(0);
        }
    }

    function verifyEOASignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        private
        pure
        returns (bool success)
    {
        if (signer == address(0)) {
            return false;
        }

        uint signatureTypeOffset = signature.length.sub(1);
        SignatureType signatureType = SignatureType(signature.toUint8(signatureTypeOffset));

        // Strip off the last byte of the signature by updating the length
        assembly {
            mstore(signature, signatureTypeOffset)
        }

        if (signatureType == SignatureType.EIP_712) {
            success = (signer == recoverECDSASigner(signHash, signature));
        } else if (signatureType == SignatureType.ETH_SIGN) {
            bytes32 hash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", signHash)
            );
            success = (signer == recoverECDSASigner(hash, signature));
        } else {
            success = false;
        }

        // Restore the signature length
        assembly {
            mstore(signature, add(signatureTypeOffset, 1))
        }

        return success;
    }

    function verifyERC1271Signature(
        bytes32 signHash,
        address signer,
        bytes   memory signature
        )
        private
        view
        returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            ERC1271.isValidSignature.selector,
            signHash,
            signature
        );
        (bool success, bytes memory result) = signer.staticcall(callData);
        return (
            success &&
            result.length == 32 &&
            result.toBytes4(0) == ERC1271_MAGICVALUE
        );
    }
}

// File: contracts/lib/Ownable.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Ownable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// File: contracts/iface/Wallet.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Wallet
/// @dev Base contract for smart wallets.
///      Sub-contracts must NOT use non-default constructor to initialize
///      wallet states, instead, `init` shall be used. This is to enable
///      proxies to be deployed in front of the real wallet contract for
///      saving gas.
///
/// @author Daniel Wang - <daniel@loopring.org>
interface Wallet
{
    function version() external pure returns (string memory);

    function owner() external view returns (address);

    /// @dev Set a new owner.
    function setOwner(address newOwner) external;

    /// @dev Adds a new module. The `init` method of the module
    ///      will be called with `address(this)` as the parameter.
    ///      This method must throw if the module has already been added.
    /// @param _module The module's address.
    function addModule(address _module) external;

    /// @dev Removes an existing module. This method must throw if the module
    ///      has NOT been added or the module is the wallet's only module.
    /// @param _module The module's address.
    function removeModule(address _module) external;

    /// @dev Checks if a module has been added to this wallet.
    /// @param _module The module to check.
    /// @return True if the module exists; False otherwise.
    function hasModule(address _module) external view returns (bool);

    /// @dev Binds a method from the given module to this
    ///      wallet so the method can be invoked using this wallet's default
    ///      function.
    ///      Note that this method must throw when the given module has
    ///      not been added to this wallet.
    /// @param _method The method's 4-byte selector.
    /// @param _module The module's address. Use address(0) to unbind the method.
    function bindMethod(bytes4 _method, address _module) external;

    /// @dev Returns the module the given method has been bound to.
    /// @param _method The method's 4-byte selector.
    /// @return _module The address of the bound module. If no binding exists,
    ///                 returns address(0) instead.
    function boundMethodModule(bytes4 _method) external view returns (address _module);

    /// @dev Performs generic transactions. Any module that has been added to this
    ///      wallet can use this method to transact on any third-party contract with
    ///      msg.sender as this wallet itself.
    ///
    ///      Note: 1) this method must ONLY allow invocations from a module that has
    ///      been added to this wallet. The wallet owner shall NOT be permitted
    ///      to call this method directly. 2) Reentrancy inside this function should
    ///      NOT cause any problems.
    ///
    /// @param mode The transaction mode, 1 for CALL, 2 for DELEGATECALL.
    /// @param to The desitination address.
    /// @param value The amount of Ether to transfer.
    /// @param data The data to send over using `to.call{value: value}(data)`
    /// @return returnData The transaction's return value.
    function transact(
        uint8    mode,
        address  to,
        uint     value,
        bytes    calldata data
        )
        external
        returns (bytes memory returnData);
}

// File: contracts/iface/Module.sol

// Copyright 2017 Loopring Technology Limited.




/// @title Module
/// @dev Base contract for all smart wallet modules.
///
/// @author Daniel Wang - <daniel@loopring.org>
interface Module
{
    /// @dev Activates the module for the given wallet (msg.sender) after the module is added.
    ///      Warning: this method shall ONLY be callable by a wallet.
    function activate() external;

    /// @dev Deactivates the module for the given wallet (msg.sender) before the module is removed.
    ///      Warning: this method shall ONLY be callable by a wallet.
    function deactivate() external;
}

// File: contracts/lib/ERC20.sol

// Copyright 2017 Loopring Technology Limited.


/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract ERC20
{
    function totalSupply()
        public
        view
        virtual
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        virtual
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        virtual
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        virtual
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        virtual
        returns (bool);
}

// File: contracts/iface/ModuleRegistry.sol

// Copyright 2017 Loopring Technology Limited.


/// @title ModuleRegistry
/// @dev A registry for modules.
///
/// @author Daniel Wang - <daniel@loopring.org>
interface ModuleRegistry
{
	/// @dev Registers and enables a new module.
    function registerModule(address module) external;

    /// @dev Disables a module
    function disableModule(address module) external;

    /// @dev Returns true if the module is registered and enabled.
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns the list of enabled modules.
    function enabledModules() external view returns (address[] memory _modules);

    /// @dev Returns the number of enbaled modules.
    function numOfEnabledModules() external view returns (uint);

    /// @dev Returns true if the module is ever registered.
    function isModuleRegistered(address module) external view returns (bool);
}

// File: contracts/base/Controller.sol

// Copyright 2017 Loopring Technology Limited.



/// @title Controller
///
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract Controller
{
    function moduleRegistry()
        external
        view
        virtual
        returns (ModuleRegistry);

    function walletFactory()
        external
        view
        virtual
        returns (address);
}

// File: contracts/iface/PriceOracle.sol

// Copyright 2017 Loopring Technology Limited.


/// @title PriceOracle
interface PriceOracle
{
    // @dev Return's the token's value in ETH
    function tokenValue(address token, uint amount)
        external
        view
        returns (uint value);
}

// File: contracts/lib/Claimable.sol

// Copyright 2017 Loopring Technology Limited.



/// @title Claimable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/base/DataStore.sol

// Copyright 2017 Loopring Technology Limited.



/// @title DataStore
/// @dev Modules share states by accessing the same storage instance.
///      Using ModuleStorage will achieve better module decoupling.
///
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract DataStore
{
    modifier onlyWalletModule(address wallet)
    {
        requireWalletModule(wallet);
        _;
    }

    function requireWalletModule(address wallet) view internal
    {
        require(Wallet(wallet).hasModule(msg.sender), "UNAUTHORIZED");
    }
}

// File: contracts/stores/HashStore.sol

// Copyright 2017 Loopring Technology Limited.




/// @title HashStore
/// @dev This store maintains all hashes for SignedRequest.
contract HashStore is DataStore
{
    // wallet => hash => consumed
    mapping(address => mapping(bytes32 => bool)) public hashes;

    constructor() {}

    function verifyAndUpdate(address wallet, bytes32 hash)
        external
    {
        require(!hashes[wallet][hash], "HASH_EXIST");
        requireWalletModule(wallet);
        hashes[wallet][hash] = true;
    }
}

// File: contracts/thirdparty/SafeCast.sol

// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol



/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "SafeCast: value doesn\'t fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/stores/QuotaStore.sol

// Copyright 2017 Loopring Technology Limited.





/// @title QuotaStore
/// @dev This store maintains daily spending quota for each wallet.
///      A rolling daily limit is used.
contract QuotaStore is DataStore
{
    using MathUint for uint;
    using SafeCast for uint;

    uint128 public constant MAX_QUOTA = uint128(-1);

    // Optimized to fit into 64 bytes (2 slots)
    struct Quota
    {
        uint128 currentQuota;
        uint128 pendingQuota;
        uint128 spentAmount;
        uint64  spentTimestamp;
        uint64  pendingUntil;
    }

    mapping (address => Quota) public quotas;

    event QuotaScheduled(
        address wallet,
        uint    pendingQuota,
        uint64  pendingUntil
    );

    constructor()
        DataStore()
    {
    }

    // 0 for newQuota indicates unlimited quota, or daily quota is disabled.
    function changeQuota(
        address wallet,
        uint    newQuota,
        uint    effectiveTime
        )
        external
        onlyWalletModule(wallet)
    {
        require(newQuota <= MAX_QUOTA, "INVALID_VALUE");
        if (newQuota == MAX_QUOTA) {
            newQuota = 0;
        }

        quotas[wallet].currentQuota = currentQuota(wallet).toUint128();
        quotas[wallet].pendingQuota = newQuota.toUint128();
        quotas[wallet].pendingUntil = effectiveTime.toUint64();

        emit QuotaScheduled(
            wallet,
            newQuota,
            quotas[wallet].pendingUntil
        );
    }

    function checkAndAddToSpent(
        address     wallet,
        address     token,
        uint        amount,
        PriceOracle priceOracle
        )
        external
    {
        Quota memory q = quotas[wallet];
        uint available = _availableQuota(q);
        if (available != MAX_QUOTA) {
            uint value = (token == address(0)) ?
                amount :
                priceOracle.tokenValue(token, amount);
            if (value > 0) {
                require(available >= value, "QUOTA_EXCEEDED");
                requireWalletModule(wallet);
                _addToSpent(wallet, q, value);
            }
        }
    }

    function addToSpent(
        address wallet,
        uint    amount
        )
        external
        onlyWalletModule(wallet)
    {
        _addToSpent(wallet, quotas[wallet], amount);
    }

    // Returns 0 to indiciate unlimited quota
    function currentQuota(address wallet)
        public
        view
        returns (uint)
    {
        return _currentQuota(quotas[wallet]);
    }

    // Returns 0 to indiciate unlimited quota
    function pendingQuota(address wallet)
        public
        view
        returns (
            uint __pendingQuota,
            uint __pendingUntil
        )
    {
        return _pendingQuota(quotas[wallet]);
    }

    function spentQuota(address wallet)
        public
        view
        returns (uint)
    {
        return _spentQuota(quotas[wallet]);
    }

    function availableQuota(address wallet)
        public
        view
        returns (uint)
    {
        return _availableQuota(quotas[wallet]);
    }

    function hasEnoughQuota(
        address wallet,
        uint    requiredAmount
        )
        public
        view
        returns (bool)
    {
        return _hasEnoughQuota(quotas[wallet], requiredAmount);
    }

    // Internal

    function _currentQuota(Quota memory q)
        private
        view
        returns (uint)
    {
        return q.pendingUntil <= block.timestamp ? q.pendingQuota : q.currentQuota;
    }

    function _pendingQuota(Quota memory q)
        private
        view
        returns (
            uint __pendingQuota,
            uint __pendingUntil
        )
    {
        if (q.pendingUntil > 0 && q.pendingUntil > block.timestamp) {
            __pendingQuota = q.pendingQuota;
            __pendingUntil = q.pendingUntil;
        }
    }

    function _spentQuota(Quota memory q)
        private
        view
        returns (uint)
    {
        uint timeSinceLastSpent = block.timestamp.sub(q.spentTimestamp);
        if (timeSinceLastSpent < 1 days) {
            return uint(q.spentAmount).sub(timeSinceLastSpent.mul(q.spentAmount) / 1 days);
        } else {
            return 0;
        }
    }

    function _availableQuota(Quota memory q)
        private
        view
        returns (uint)
    {
        uint quota = _currentQuota(q);
        if (quota == 0) {
            return MAX_QUOTA;
        }
        uint spent = _spentQuota(q);
        return quota > spent ? quota - spent : 0;
    }

    function _hasEnoughQuota(
        Quota   memory q,
        uint    requiredAmount
        )
        private
        view
        returns (bool)
    {
        return _availableQuota(q) >= requiredAmount;
    }

    function _addToSpent(
        address wallet,
        Quota   memory q,
        uint    amount
        )
        private
    {
        Quota storage s = quotas[wallet];
        s.spentAmount = _spentQuota(q).add(amount).toUint128();
        s.spentTimestamp = uint64(block.timestamp);
    }
}

// File: contracts/stores/Data.sol

// Copyright 2017 Loopring Technology Limited.


library Data
{
    enum GuardianStatus {
        REMOVE,    // Being removed or removed after validUntil timestamp
        ADD        // Being added or added after validSince timestamp.
    }

    // Optimized to fit into 32 bytes (1 slot)
    struct Guardian
    {
        address addr;
        uint8   status;
        uint64  timestamp; // validSince if status = ADD; validUntil if adding = REMOVE;
    }
}

// File: contracts/stores/GuardianStore.sol

// Copyright 2017 Loopring Technology Limited.






/// @title GuardianStore
///
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract GuardianStore is DataStore
{
    using MathUint      for uint;
    using SafeCast      for uint;

    struct Wallet
    {
        address    inheritor;
        uint32     inheritWaitingPeriod;
        uint64     lastActive; // the latest timestamp the owner is considered to be active
        bool       locked;

        Data.Guardian[]            guardians;
        mapping (address => uint)  guardianIdx;
    }

    mapping (address => Wallet) public wallets;

    constructor() DataStore() {}

    function isGuardian(
        address wallet,
        address addr,
        bool    includePendingAddition
        )
        public
        view
        returns (bool)
    {
        Data.Guardian memory g = _getGuardian(wallet, addr);
        return _isActiveOrPendingAddition(g, includePendingAddition);
    }

    function guardians(
        address wallet,
        bool    includePendingAddition
        )
        public
        view
        returns (Data.Guardian[] memory _guardians)
    {
        Wallet storage w = wallets[wallet];
        _guardians = new Data.Guardian[](w.guardians.length);
        uint index = 0;
        for (uint i = 0; i < w.guardians.length; i++) {
            Data.Guardian memory g = w.guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                _guardians[index] = g;
                index++;
            }
        }
        assembly { mstore(_guardians, index) }
    }

    function numGuardians(
        address wallet,
        bool    includePendingAddition
        )
        public
        view
        returns (uint count)
    {
        Wallet storage w = wallets[wallet];
        for (uint i = 0; i < w.guardians.length; i++) {
            Data.Guardian memory g = w.guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                count++;
            }
        }
    }

    function removeAllGuardians(address wallet)
        external
    {
        Wallet storage w = wallets[wallet];
        uint size = w.guardians.length;
        if (size == 0) return;

        requireWalletModule(wallet);
        for (uint i = 0; i < w.guardians.length; i++) {
            delete w.guardianIdx[w.guardians[i].addr];
        }
        delete w.guardians;
    }

    function cancelPendingGuardians(address wallet)
        external
    {
        bool cancelled = false;
        Wallet storage w = wallets[wallet];
        for (uint i = 0; i < w.guardians.length; i++) {
            Data.Guardian memory g = w.guardians[i];
            if (_isPendingAddition(g)) {
                w.guardians[i].status = uint8(Data.GuardianStatus.REMOVE);
                w.guardians[i].timestamp = 0;
                cancelled = true;
            }
            if (_isPendingRemoval(g)) {
                w.guardians[i].status = uint8(Data.GuardianStatus.ADD);
                w.guardians[i].timestamp = 0;
                cancelled = true;
            }
        }
        if (cancelled) {
            requireWalletModule(wallet);
        }
        _cleanRemovedGuardians(wallet, true);
    }

    function cleanRemovedGuardians(address wallet)
        external
    {
        _cleanRemovedGuardians(wallet, true);
    }

    function addGuardian(
        address wallet,
        address addr,
        uint    validSince,
        bool    alwaysOverride
        )
        external
        onlyWalletModule(wallet)
        returns (uint)
    {
        require(validSince >= block.timestamp, "INVALID_VALID_SINCE");
        require(addr != address(0), "ZERO_ADDRESS");

        Wallet storage w = wallets[wallet];
        uint pos = w.guardianIdx[addr];

        if(pos == 0) {
            // Add the new guardian
            Data.Guardian memory g = Data.Guardian(
                addr,
                uint8(Data.GuardianStatus.ADD),
                validSince.toUint64()
            );
            w.guardians.push(g);
            w.guardianIdx[addr] = w.guardians.length;

            _cleanRemovedGuardians(wallet, false);
            return validSince;
        }

        Data.Guardian memory g = w.guardians[pos - 1];

        if (_isRemoved(g)) {
            w.guardians[pos - 1].status = uint8(Data.GuardianStatus.ADD);
            w.guardians[pos - 1].timestamp = validSince.toUint64();
            return validSince;
        }

        if (_isPendingRemoval(g)) {
            w.guardians[pos - 1].status = uint8(Data.GuardianStatus.ADD);
            w.guardians[pos - 1].timestamp = 0;
            return 0;
        }

        if (_isPendingAddition(g)) {
            if (!alwaysOverride) return g.timestamp;

            w.guardians[pos - 1].timestamp = validSince.toUint64();
            return validSince;
        }

        require(_isAdded(g), "UNEXPECTED_RESULT");
        return 0;
    }

    function removeGuardian(
        address wallet,
        address addr,
        uint    validUntil,
        bool    alwaysOverride
        )
        external
        onlyWalletModule(wallet)
        returns (uint)
    {
        require(validUntil >= block.timestamp, "INVALID_VALID_UNTIL");
        require(addr != address(0), "ZERO_ADDRESS");

        Wallet storage w = wallets[wallet];
        uint pos = w.guardianIdx[addr];
        require(pos > 0, "GUARDIAN_NOT_EXISTS");

        Data.Guardian memory g = w.guardians[pos - 1];

        if (_isAdded(g)) {
            w.guardians[pos - 1].status = uint8(Data.GuardianStatus.REMOVE);
            w.guardians[pos - 1].timestamp = validUntil.toUint64();
            return validUntil;
        }

        if (_isPendingAddition(g)) {
            w.guardians[pos - 1].status = uint8(Data.GuardianStatus.REMOVE);
            w.guardians[pos - 1].timestamp = 0;
            return 0;
        }

        if (_isPendingRemoval(g)) {
            if (!alwaysOverride) return g.timestamp;

            w.guardians[pos - 1].timestamp = validUntil.toUint64();
            return validUntil;
        }

        require(_isRemoved(g), "UNEXPECTED_RESULT");
        return 0;
    }

    // ---- internal functions ---

    function _getGuardian(
        address wallet,
        address addr
        )
        private
        view
        returns (Data.Guardian memory)
    {
        Wallet storage w = wallets[wallet];
        uint pos = w.guardianIdx[addr];
        if (pos > 0) {
            return w.guardians[pos - 1];
        }
    }

    function _isAdded(Data.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(Data.GuardianStatus.ADD) &&
            guardian.timestamp <= block.timestamp;
    }

    function _isPendingAddition(Data.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(Data.GuardianStatus.ADD) &&
            guardian.timestamp > block.timestamp;
    }

    function _isRemoved(Data.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(Data.GuardianStatus.REMOVE) &&
            guardian.timestamp <= block.timestamp;
    }

    function _isPendingRemoval(Data.Guardian memory guardian)
        private
        view
        returns (bool)
    {
         return guardian.status == uint8(Data.GuardianStatus.REMOVE) &&
            guardian.timestamp > block.timestamp;
    }

    function _isActive(Data.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return _isAdded(guardian) || _isPendingRemoval(guardian);
    }

    function _isActiveOrPendingAddition(
        Data.Guardian memory guardian,
        bool includePendingAddition
        )
        private
        view
        returns (bool)
    {
        return _isActive(guardian) || includePendingAddition && _isPendingAddition(guardian);
    }

    function _cleanRemovedGuardians(
        address wallet,
        bool    force
        )
        private
    {
        Wallet storage w = wallets[wallet];
        uint count = w.guardians.length;
        if (!force && count < 10) return;

        for (int i = int(count) - 1; i >= 0; i--) {
            Data.Guardian memory g = w.guardians[uint(i)];
            if (_isRemoved(g)) {
                Data.Guardian memory lastGuardian = w.guardians[w.guardians.length - 1];

                if (g.addr != lastGuardian.addr) {
                    w.guardians[uint(i)] = lastGuardian;
                    w.guardianIdx[lastGuardian.addr] = uint(i) + 1;
                }
                w.guardians.pop();
                delete w.guardianIdx[g.addr];
            }
        }
    }
}

// File: contracts/stores/SecurityStore.sol

// Copyright 2017 Loopring Technology Limited.


/// @title SecurityStore
///
/// @author Daniel Wang - <daniel@loopring.org>
contract SecurityStore is GuardianStore
{
    using MathUint for uint;
    using SafeCast for uint;

    constructor() GuardianStore() {}

    function setLock(
        address wallet,
        bool    locked
        )
        external
        onlyWalletModule(wallet)
    {
        wallets[wallet].locked = locked;
    }

    function touchLastActive(address wallet)
        external
        onlyWalletModule(wallet)
    {
        wallets[wallet].lastActive = uint64(block.timestamp);
    }

    function touchLastActiveWhenRequired(
        address wallet,
        uint    minInternval
        )
        external
    {
        if (wallets[wallet].inheritor != address(0) &&
            block.timestamp > lastActive(wallet) + minInternval) {
            requireWalletModule(wallet);
            wallets[wallet].lastActive = uint64(block.timestamp);
        }
    }

    function setInheritor(
        address wallet,
        address who,
        uint32 _inheritWaitingPeriod
        )
        external
        onlyWalletModule(wallet)
    {
        wallets[wallet].inheritor = who;
        wallets[wallet].inheritWaitingPeriod = _inheritWaitingPeriod;
        wallets[wallet].lastActive = uint64(block.timestamp);
    }

    function isLocked(address wallet)
        public
        view
        returns (bool)
    {
        return wallets[wallet].locked;
    }

    function lastActive(address wallet)
        public
        view
        returns (uint)
    {
        return wallets[wallet].lastActive;
    }

    function inheritor(address wallet)
        public
        view
        returns (
            address _who,
            uint    _effectiveTimestamp
        )
    {
        address _inheritor = wallets[wallet].inheritor;
        if (_inheritor == address(0)) {
             return (address(0), 0);
        }

        uint32 _inheritWaitingPeriod = wallets[wallet].inheritWaitingPeriod;
        if (_inheritWaitingPeriod == 0) {
            return (address(0), 0);
        }

        uint64 _lastActive = wallets[wallet].lastActive;

        if (_lastActive == 0) {
            _lastActive = uint64(block.timestamp);
        }

        _who = _inheritor;
        _effectiveTimestamp = _lastActive + _inheritWaitingPeriod;
    }
}

// File: contracts/lib/AddressSet.sol

// Copyright 2017 Loopring Technology Limited.


/// @title AddressSet
/// @author Daniel Wang - <daniel@loopring.org>
contract AddressSet
{
    struct Set
    {
        address[] addresses;
        mapping (address => uint) positions;
        uint count;
    }
    mapping (bytes32 => Set) private sets;

    function addAddressToSet(
        bytes32 key,
        address addr,
        bool    maintainList
        ) internal
    {
        Set storage set = sets[key];
        require(set.positions[addr] == 0, "ALREADY_IN_SET");

        if (maintainList) {
            require(set.addresses.length == set.count, "PREVIOUSLY_NOT_MAINTAILED");
            set.addresses.push(addr);
        } else {
            require(set.addresses.length == 0, "MUST_MAINTAIN");
        }

        set.count += 1;
        set.positions[addr] = set.count;
    }

    function removeAddressFromSet(
        bytes32 key,
        address addr
        )
        internal
    {
        Set storage set = sets[key];
        uint pos = set.positions[addr];
        require(pos != 0, "NOT_IN_SET");

        delete set.positions[addr];
        set.count -= 1;

        if (set.addresses.length > 0) {
            address lastAddr = set.addresses[set.count];
            if (lastAddr != addr) {
                set.addresses[pos - 1] = lastAddr;
                set.positions[lastAddr] = pos;
            }
            set.addresses.pop();
        }
    }

    function removeSet(bytes32 key)
        internal
    {
        delete sets[key];
    }

    function isAddressInSet(
        bytes32 key,
        address addr
        )
        internal
        view
        returns (bool)
    {
        return sets[key].positions[addr] != 0;
    }

    function numAddressesInSet(bytes32 key)
        internal
        view
        returns (uint)
    {
        Set storage set = sets[key];
        return set.count;
    }

    function addressesInSet(bytes32 key)
        internal
        view
        returns (address[] memory)
    {
        Set storage set = sets[key];
        require(set.count == set.addresses.length, "NOT_MAINTAINED");
        return sets[key].addresses;
    }
}

// File: contracts/lib/OwnerManagable.sol

// Copyright 2017 Loopring Technology Limited.




contract OwnerManagable is Claimable, AddressSet
{
    bytes32 internal constant MANAGER = keccak256("__MANAGED__");

    event ManagerAdded  (address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyManager
    {
        require(isManager(msg.sender), "NOT_MANAGER");
        _;
    }

    modifier onlyOwnerOrManager
    {
        require(msg.sender == owner || isManager(msg.sender), "NOT_OWNER_OR_MANAGER");
        _;
    }

    constructor() Claimable() {}

    /// @dev Gets the managers.
    /// @return The list of managers.
    function managers()
        public
        view
        returns (address[] memory)
    {
        return addressesInSet(MANAGER);
    }

    /// @dev Gets the number of managers.
    /// @return The numer of managers.
    function numManagers()
        public
        view
        returns (uint)
    {
        return numAddressesInSet(MANAGER);
    }

    /// @dev Checks if an address is a manger.
    /// @param addr The address to check.
    /// @return True if the address is a manager, False otherwise.
    function isManager(address addr)
        public
        view
        returns (bool)
    {
        return isAddressInSet(MANAGER, addr);
    }

    /// @dev Adds a new manager.
    /// @param manager The new address to add.
    function addManager(address manager)
        public
        onlyOwner
    {
        addManagerInternal(manager);
    }

    /// @dev Removes a manager.
    /// @param manager The manager to remove.
    function removeManager(address manager)
        public
        onlyOwner
    {
        removeAddressFromSet(MANAGER, manager);
        emit ManagerRemoved(manager);
    }

    function addManagerInternal(address manager)
        internal
    {
        addAddressToSet(MANAGER, manager, true);
        emit ManagerAdded(manager);
    }
}

// File: contracts/stores/WhitelistStore.sol

// Copyright 2017 Loopring Technology Limited.





/// @title WhitelistStore
/// @dev This store maintains a wallet's whitelisted addresses.
contract WhitelistStore is DataStore, AddressSet, OwnerManagable
{
    bytes32 internal constant DAPPS = keccak256("__DAPPS__");

    // wallet => whitelisted_addr => effective_since
    mapping(address => mapping(address => uint)) public effectiveTimeMap;

    event Whitelisted(
        address wallet,
        address addr,
        bool    whitelisted,
        uint    effectiveTime
    );

    event DappWhitelisted(
        address addr,
        bool    whitelisted
    );

    constructor() DataStore() {}

    function addToWhitelist(
        address wallet,
        address addr,
        uint    effectiveTime
        )
        external
        onlyWalletModule(wallet)
    {
        addAddressToSet(_walletKey(wallet), addr, true);
        uint effective = effectiveTime >= block.timestamp ? effectiveTime : block.timestamp;
        effectiveTimeMap[wallet][addr] = effective;
        emit Whitelisted(wallet, addr, true, effective);
    }

    function removeFromWhitelist(
        address wallet,
        address addr
        )
        external
        onlyWalletModule(wallet)
    {
        removeAddressFromSet(_walletKey(wallet), addr);
        delete effectiveTimeMap[wallet][addr];
        emit Whitelisted(wallet, addr, false, 0);
    }

    function addDapp(address addr)
        external
        onlyManager
    {
        addAddressToSet(DAPPS, addr, true);
        emit DappWhitelisted(addr, true);
    }

    function removeDapp(address addr)
        external
        onlyManager
    {
        removeAddressFromSet(DAPPS, addr);
        emit DappWhitelisted(addr, false);
    }

    function whitelist(address wallet)
        public
        view
        returns (
            address[] memory addresses,
            uint[]    memory effectiveTimes
        )
    {
        addresses = addressesInSet(_walletKey(wallet));
        effectiveTimes = new uint[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            effectiveTimes[i] = effectiveTimeMap[wallet][addresses[i]];
        }
    }

    function isWhitelisted(
        address wallet,
        address addr
        )
        public
        view
        returns (
            bool isWhitelistedAndEffective,
            uint effectiveTime
        )
    {
        effectiveTime = effectiveTimeMap[wallet][addr];
        isWhitelistedAndEffective = effectiveTime > 0 && effectiveTime <= block.timestamp;
    }

    function whitelistSize(address wallet)
        public
        view
        returns (uint)
    {
        return numAddressesInSet(_walletKey(wallet));
    }

    function dapps()
        public
        view
        returns (
            address[] memory addresses
        )
    {
        return addressesInSet(DAPPS);
    }

    function isDapp(
        address addr
        )
        public
        view
        returns (bool)
    {
        return isAddressInSet(DAPPS, addr);
    }

    function numDapps()
        public
        view
        returns (uint)
    {
        return numAddressesInSet(DAPPS);
    }

    function isDappOrWhitelisted(
        address wallet,
        address addr
        )
        public
        view
        returns (bool res)
    {
        (res,) = isWhitelisted(wallet, addr);
        return res || isAddressInSet(DAPPS, addr);
    }

    function _walletKey(address addr)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("__WHITELIST__", addr));
    }

}

// File: contracts/thirdparty/strings.sol

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <arachnid@notdot.net>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */


/* solium-disable */
library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
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

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint256(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint256(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint256(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint256(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to kblock.timestamp whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(-1); // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// File: contracts/thirdparty/ens/ENS.sol

// Taken from Argent's code base - https://github.com/argentlabs/argent-contracts/blob/develop/contracts/ens/ENS.sol
// with few modifications.


/**
 * ENS Registry interface.
 */
interface ENSRegistry {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}


/**
 * ENS Resolver interface.
 */
abstract contract ENSResolver {
    function addr(bytes32 _node) public view virtual returns (address);
    function setAddr(bytes32 _node, address _addr) public virtual;
    function name(bytes32 _node) public view virtual returns (string memory);
    function setName(bytes32 _node, string memory _name) public virtual;
}

/**
 * ENS Reverse Registrar interface.
 */
abstract contract ENSReverseRegistrar {
    function claim(address _owner) public virtual returns (bytes32 _node);
    function claimWithResolver(address _owner, address _resolver) public virtual returns (bytes32);
    function setName(string memory _name) public virtual returns (bytes32);
    function node(address _addr) public view virtual returns (bytes32);
}

// File: contracts/thirdparty/ens/ENSConsumer.sol

// Taken from Argent's code base - https://github.com/argentlabs/argent-contracts/blob/develop/contracts/ens/ENSConsumer.sol
// with few modifications.




/**
 * @title ENSConsumer
 * @dev Helper contract to resolve ENS names.
 * @author Julien Niset - <julien@argent.im>
 */
contract ENSConsumer {

    using strings for *;

    // namehash('addr.reverse')
    bytes32 public constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    // the address of the ENS registry
    address immutable ensRegistry;

    /**
    * @dev No address should be provided when deploying on Mainnet to avoid storage cost. The
    * contract will use the hardcoded value.
    */
    constructor(address _ensRegistry) {
        ensRegistry = _ensRegistry;
    }

    /**
    * @dev Resolves an ENS name to an address.
    * @param _node The namehash of the ENS name.
    */
    function resolveEns(bytes32 _node) public view returns (address) {
        address resolver = getENSRegistry().resolver(_node);
        return ENSResolver(resolver).addr(_node);
    }

    /**
    * @dev Gets the official ENS registry.
    */
    function getENSRegistry() public view returns (ENSRegistry) {
        return ENSRegistry(ensRegistry);
    }

    /**
    * @dev Gets the official ENS reverse registrar.
    */
    function getENSReverseRegistrar() public view returns (ENSReverseRegistrar) {
        return ENSReverseRegistrar(getENSRegistry().owner(ADDR_REVERSE_NODE));
    }
}

// File: contracts/thirdparty/ens/BaseENSManager.sol

// Taken from Argent's code base - https://github.com/argentlabs/argent-contracts/blob/develop/contracts/ens/ArgentENSManager.sol
// with few modifications.







/**
 * @dev Interface for an ENS Mananger.
 */
interface IENSManager {
    function changeRootnodeOwner(address _newOwner) external;

    function isAvailable(bytes32 _subnode) external view returns (bool);

    function resolveName(address _wallet) external view returns (string memory);

    function register(
        address _wallet,
        address _owner,
        string  calldata _label,
        bytes   calldata _approval
    ) external;
}

/**
 * @title BaseENSManager
 * @dev Implementation of an ENS manager that orchestrates the complete
 * registration of subdomains for a single root (e.g. argent.eth).
 * The contract defines a manager role who is the only role that can trigger the registration of
 * a new subdomain.
 * @author Julien Niset - <julien@argent.im>
 */
contract BaseENSManager is IENSManager, OwnerManagable, ENSConsumer {

    using strings for *;
    using BytesUtil     for bytes;
    using MathUint      for uint;

    // The managed root name
    string public rootName;
    // The managed root node
    bytes32 public immutable rootNode;
    // The address of the ENS resolver
    address public ensResolver;

    // *************** Events *************************** //

    event RootnodeOwnerChange(bytes32 indexed _rootnode, address indexed _newOwner);
    event ENSResolverChanged(address addr);
    event Registered(address indexed _wallet, address _owner, string _ens);
    event Unregistered(string _ens);

    // *************** Constructor ********************** //

    /**
     * @dev Constructor that sets the ENS root name and root node to manage.
     * @param _rootName The root name (e.g. argentx.eth).
     * @param _rootNode The node of the root name (e.g. namehash(argentx.eth)).
     */
    constructor(string memory _rootName, bytes32 _rootNode, address _ensRegistry, address _ensResolver)
        ENSConsumer(_ensRegistry)
    {
        rootName = _rootName;
        rootNode = _rootNode;
        ensResolver = _ensResolver;
    }

    // *************** External Functions ********************* //

    /**
     * @dev This function must be called when the ENS Manager contract is replaced
     * and the address of the new Manager should be provided.
     * @param _newOwner The address of the new ENS manager that will manage the root node.
     */
    function changeRootnodeOwner(address _newOwner) external override onlyOwner {
        getENSRegistry().setOwner(rootNode, _newOwner);
        emit RootnodeOwnerChange(rootNode, _newOwner);
    }

    /**
     * @dev Lets the owner change the address of the ENS resolver contract.
     * @param _ensResolver The address of the ENS resolver contract.
     */
    function changeENSResolver(address _ensResolver) external onlyOwner {
        require(_ensResolver != address(0), "WF: address cannot be null");
        ensResolver = _ensResolver;
        emit ENSResolverChanged(_ensResolver);
    }

    /**
    * @dev Lets the manager assign an ENS subdomain of the root node to a target address.
    * Registers both the forward and reverse ENS.
    * @param _wallet The wallet which owns the subdomain.
    * @param _owner The wallet's owner.
    * @param _label The subdomain label.
    * @param _approval The signature of _wallet, _owner and _label by a manager.
    */
    function register(
        address _wallet,
        address _owner,
        string  calldata _label,
        bytes   calldata _approval
        )
        external
        override
        onlyManager
    {
        verifyApproval(_wallet, _owner, _label, _approval);

        ENSRegistry _ensRegistry = getENSRegistry();
        ENSResolver _ensResolver = ENSResolver(ensResolver);
        bytes32 labelNode = keccak256(abi.encodePacked(_label));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));
        address currentOwner = _ensRegistry.owner(node);
        require(currentOwner == address(0), "AEM: _label is alrealdy owned");

        // Forward ENS
        _ensRegistry.setSubnodeOwner(rootNode, labelNode, address(this));
        _ensRegistry.setResolver(node, address(_ensResolver));
        _ensRegistry.setOwner(node, _wallet);
        _ensResolver.setAddr(node, _wallet);

        // Reverse ENS
        strings.slice[] memory parts = new strings.slice[](2);
        parts[0] = _label.toSlice();
        parts[1] = rootName.toSlice();
        string memory name = ".".toSlice().join(parts);
        bytes32 reverseNode = getENSReverseRegistrar().node(_wallet);
        _ensResolver.setName(reverseNode, name);

        emit Registered(_wallet, _owner, name);
    }

    // *************** Public Functions ********************* //

    /**
    * @dev Resolves an address to an ENS name
    * @param _wallet The ENS owner address
    */
    function resolveName(address _wallet) public view override returns (string memory) {
        bytes32 reverseNode = getENSReverseRegistrar().node(_wallet);
        return ENSResolver(ensResolver).name(reverseNode);
    }

    /**
     * @dev Returns true is a given subnode is available.
     * @param _subnode The target subnode.
     * @return true if the subnode is available.
     */
    function isAvailable(bytes32 _subnode) public view override returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(rootNode, _subnode));
        address currentOwner = getENSRegistry().owner(node);
        if(currentOwner == address(0)) {
            return true;
        }
        return false;
    }

    function verifyApproval(
        address _wallet,
        address _owner,
        string  calldata _label,
        bytes   calldata _approval
        )
        internal
        view
    {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _wallet,
                _owner,
                _label
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                messageHash
            )
        );

        address signer = SignatureUtil.recoverECDSASigner(hash, _approval);
        require(isManager(signer), "UNAUTHORIZED");
    }

}

// File: contracts/modules/ControllerImpl.sol

// Copyright 2017 Loopring Technology Limited.










/// @title ControllerImpl
/// @dev Basic implementation of a Controller.
///
/// @author Daniel Wang - <daniel@loopring.org>
contract ControllerImpl is Claimable, Controller
{
    HashStore           public immutable hashStore;
    QuotaStore          public immutable quotaStore;
    SecurityStore       public immutable securityStore;
    WhitelistStore      public immutable whitelistStore;
    ModuleRegistry      public immutable override moduleRegistry;
    address             public override  walletFactory;
    address             public immutable feeCollector;
    BaseENSManager      public immutable ensManager;
    PriceOracle         public priceOracle;

    event AddressChanged(
        string   name,
        address  addr
    );

    constructor(
        HashStore         _hashStore,
        QuotaStore        _quotaStore,
        SecurityStore     _securityStore,
        WhitelistStore    _whitelistStore,
        ModuleRegistry    _moduleRegistry,
        address           _feeCollector,
        BaseENSManager    _ensManager,
        PriceOracle       _priceOracle
        )
    {
        hashStore = _hashStore;
        quotaStore = _quotaStore;
        securityStore = _securityStore;
        whitelistStore = _whitelistStore;
        moduleRegistry = _moduleRegistry;

        require(_feeCollector != address(0), "ZERO_ADDRESS");
        feeCollector = _feeCollector;

        ensManager = _ensManager;
        priceOracle = _priceOracle;
    }

    function initWalletFactory(address _walletFactory)
        external
        onlyOwner
    {
        require(walletFactory == address(0), "INITIALIZED_ALREADY");
        require(_walletFactory != address(0), "ZERO_ADDRESS");
        walletFactory = _walletFactory;
        emit AddressChanged("WalletFactory", walletFactory);
    }

    function setPriceOracle(PriceOracle _priceOracle)
        external
        onlyOwner
    {
        priceOracle = _priceOracle;
        emit AddressChanged("PriceOracle", address(priceOracle));
    }
}

// File: contracts/modules/base/BaseModule.sol

// Copyright 2017 Loopring Technology Limited.








/// @title BaseModule
/// @dev This contract implements some common functions that are likely
///      be useful for all modules.
///
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract BaseModule is Module
{
    using MathUint      for uint;
    using AddressUtil   for address;

    event Activated   (address wallet);
    event Deactivated (address wallet);

    ModuleRegistry public immutable moduleRegistry;
    SecurityStore  public immutable securityStore;
    WhitelistStore public immutable whitelistStore;
    QuotaStore     public immutable quotaStore;
    HashStore      public immutable hashStore;
    address        public immutable walletFactory;
    PriceOracle    public immutable priceOracle;
    address        public immutable feeCollector;

    function logicalSender()
        internal
        view
        virtual
        returns (address payable)
    {
        return msg.sender;
    }

    modifier onlyWalletOwner(address wallet, address addr)
        virtual
    {
        require(Wallet(wallet).owner() == addr, "NOT_WALLET_OWNER");
        _;
    }

    modifier notWalletOwner(address wallet, address addr)
        virtual
    {
        require(Wallet(wallet).owner() != addr, "IS_WALLET_OWNER");
        _;
    }

    modifier eligibleWalletOwner(address addr)
    {
        require(addr != address(0) && !addr.isContract(), "INVALID_OWNER");
        _;
    }

    constructor(ControllerImpl _controller)
    {
        moduleRegistry = _controller.moduleRegistry();
        securityStore = _controller.securityStore();
        whitelistStore = _controller.whitelistStore();
        quotaStore = _controller.quotaStore();
        hashStore = _controller.hashStore();
        walletFactory = _controller.walletFactory();
        priceOracle = _controller.priceOracle();
        feeCollector = _controller.feeCollector();
    }

    /// @dev This method will cause an re-entry to the same module contract.
    function activate()
        external
        override
        virtual
    {
        address wallet = logicalSender();
        bindMethods(wallet);
        emit Activated(wallet);
    }

    /// @dev This method will cause an re-entry to the same module contract.
    function deactivate()
        external
        override
        virtual
    {
        address wallet = logicalSender();
        unbindMethods(wallet);
        emit Deactivated(wallet);
    }

    ///.@dev Gets the list of methods for binding to wallets.
    ///      Sub-contracts should override this method to provide methods for
    ///      wallet binding.
    /// @return methods A list of method selectors for binding to the wallet
    ///         when this module is activated for the wallet.
    function bindableMethods()
        public
        pure
        virtual
        returns (bytes4[] memory methods)
    {
    }

    // ===== internal & private methods =====

    /// @dev Binds all methods to the given wallet.
    function bindMethods(address wallet)
        internal
    {
        Wallet w = Wallet(wallet);
        bytes4[] memory methods = bindableMethods();
        for (uint i = 0; i < methods.length; i++) {
            w.bindMethod(methods[i], address(this));
        }
    }

    /// @dev Unbinds all methods from the given wallet.
    function unbindMethods(address wallet)
        internal
    {
        Wallet w = Wallet(wallet);
        bytes4[] memory methods = bindableMethods();
        for (uint i = 0; i < methods.length; i++) {
            w.bindMethod(methods[i], address(0));
        }
    }

    function transactCall(
        address wallet,
        address to,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bytes memory)
    {
        return Wallet(wallet).transact(uint8(1), to, value, data);
    }

    // Special case for transactCall to support transfers on "bad" ERC20 tokens
    function transactTokenTransfer(
        address wallet,
        address token,
        address to,
        uint    amount
        )
        internal
    {
        if (token == address(0)) {
            transactCall(wallet, to, amount, "");
            return;
        }

        bytes memory txData = abi.encodeWithSelector(
            ERC20.transfer.selector,
            to,
            amount
        );
        bytes memory returnData = transactCall(wallet, token, 0, txData);
        // `transactCall` will revert if the call was unsuccessful.
        // The only extra check we have to do is verify if the return value (if there is any) is correct.
        bool success = returnData.length == 0 ? true :  abi.decode(returnData, (bool));
        require(success, "ERC20_TRANSFER_FAILED");
    }

    // Special case for transactCall to support approvals on "bad" ERC20 tokens
    function transactTokenApprove(
        address wallet,
        address token,
        address spender,
        uint    amount
        )
        internal
    {
        require(token != address(0), "INVALID_TOKEN");
        bytes memory txData = abi.encodeWithSelector(
            ERC20.approve.selector,
            spender,
            amount
        );
        bytes memory returnData = transactCall(wallet, token, 0, txData);
        // `transactCall` will revert if the call was unsuccessful.
        // The only extra check we have to do is verify if the return value (if there is any) is correct.
        bool success = returnData.length == 0 ? true :  abi.decode(returnData, (bool));
        require(success, "ERC20_APPROVE_FAILED");
    }

    function transactDelegateCall(
        address wallet,
        address to,
        uint    value,
        bytes   calldata data
        )
        internal
        returns (bytes memory)
    {
        return Wallet(wallet).transact(uint8(2), to, value, data);
    }

    function transactStaticCall(
        address wallet,
        address to,
        bytes   calldata data
        )
        internal
        returns (bytes memory)
    {
        return Wallet(wallet).transact(uint8(3), to, 0, data);
    }

    function reimburseGasFee(
        address     wallet,
        address     recipient,
        address     gasToken,
        uint        gasPrice,
        uint        gasAmount
        )
        internal
    {
        uint gasCost = gasAmount.mul(gasPrice);

        quotaStore.checkAndAddToSpent(
            wallet,
            gasToken,
            gasAmount,
            priceOracle
        );

        transactTokenTransfer(wallet, gasToken, recipient, gasCost);
    }
}

// File: contracts/modules/base/MetaTxAware.sol

// Copyright 2017 Loopring Technology Limited.




/// @title MetaTxAware
/// @author Daniel Wang - <daniel@loopring.org>
///
/// The design of this contract is inspired by GSN's contract codebase:
/// https://github.com/opengsn/gsn/contracts
///
/// @dev Inherit this abstract contract to make a module meta-transaction
///      aware. `msgSender()` shall be used to replace `msg.sender` for
///      verifying permissions.
abstract contract MetaTxAware
{
    using AddressUtil for address;
    using BytesUtil   for bytes;

    address public immutable metaTxForwarder;

    constructor(address _metaTxForwarder)
    {
        metaTxForwarder = _metaTxForwarder;
    }

    modifier txAwareHashNotAllowed()
    {
        require(txAwareHash() == 0, "INVALID_TX_AWARE_HASH");
        _;
    }

    /// @dev Return's the function's logicial message sender. This method should be
    // used to replace `msg.sender` for all meta-tx enabled functions.
    function msgSender()
        internal
        view
        returns (address payable)
    {
        if (msg.data.length >= 56 && msg.sender == metaTxForwarder) {
            return msg.data.toAddress(msg.data.length - 52).toPayable();
        } else {
            return msg.sender;
        }
    }

    function txAwareHash()
        internal
        view
        returns (bytes32)
    {
        if (msg.data.length >= 56 && msg.sender == metaTxForwarder) {
            return msg.data.toBytes32(msg.data.length - 32);
        } else {
            return 0;
        }
    }
}

// File: contracts/modules/base/MetaTxModule.sol

// Copyright 2017 Loopring Technology Limited.






/// @title MetaTxModule
/// @dev Base contract for all modules that support meta-transactions.
///
/// @author Daniel Wang - <daniel@loopring.org>
///
/// The design of this contract is inspired by GSN's contract codebase:
/// https://github.com/opengsn/gsn/contracts
abstract contract MetaTxModule is MetaTxAware, BaseModule
{
    using SignatureUtil for bytes32;

    constructor(
        ControllerImpl _controller,
        address        _metaTxForwarder
        )
        MetaTxAware(_metaTxForwarder)
        BaseModule(_controller)
    {
    }

   function logicalSender()
        internal
        view
        virtual
        override
        returns (address payable)
    {
        return msgSender();
    }
}

// File: contracts/modules/security/GuardianUtils.sol

// Copyright 2017 Loopring Technology Limited.




/// @title GuardianUtils
/// @author Brecht Devos - <brecht@loopring.org>
library GuardianUtils
{
    enum SigRequirement
    {
        MAJORITY_OWNER_NOT_ALLOWED,
        MAJORITY_OWNER_ALLOWED,
        MAJORITY_OWNER_REQUIRED,
        OWNER_OR_ANY_GUARDIAN,
        ANY_GUARDIAN
    }

    function requireMajority(
        SecurityStore   securityStore,
        address         wallet,
        address[]       memory signers,
        SigRequirement  requirement
        )
        internal
        view
        returns (bool)
    {
        // We always need at least one signer
        if (signers.length == 0) {
            return false;
        }

        // Calculate total group sizes
        Data.Guardian[] memory allGuardians = securityStore.guardians(wallet, false);
        require(allGuardians.length > 0, "NO_GUARDIANS");

        address lastSigner;
        bool walletOwnerSigned = false;
        address owner = Wallet(wallet).owner();
        for (uint i = 0; i < signers.length; i++) {
            // Check for duplicates
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];

            if (signers[i] == owner) {
                walletOwnerSigned = true;
            } else {
                require(_isWalletGuardian(allGuardians, signers[i]), "SIGNER_NOT_GUARDIAN");
            }
        }

        if (requirement == SigRequirement.OWNER_OR_ANY_GUARDIAN) {
            return signers.length == 1;
        } else if (requirement == SigRequirement.ANY_GUARDIAN) {
            require(!walletOwnerSigned, "WALLET_OWNER_SIGNATURE_NOT_ALLOWED");
            return signers.length == 1;
        }

        // Check owner requirements
        if (requirement == SigRequirement.MAJORITY_OWNER_REQUIRED) {
            require(walletOwnerSigned, "WALLET_OWNER_SIGNATURE_REQUIRED");
        } else if (requirement == SigRequirement.MAJORITY_OWNER_NOT_ALLOWED) {
            require(!walletOwnerSigned, "WALLET_OWNER_SIGNATURE_NOT_ALLOWED");
        }

        uint numExtendedSigners = allGuardians.length;
        if (walletOwnerSigned) {
            numExtendedSigners += 1;
            require(signers.length > 1, "NO_GUARDIAN_SIGNED_BESIDES_OWNER");
        }

        return _hasMajority(signers.length, numExtendedSigners);
    }

    function _isWalletGuardian(
        Data.Guardian[] memory allGuardians,
        address signer
        )
        private
        pure
        returns (bool)
    {
        for (uint i = 0; i < allGuardians.length; i++) {
            if (allGuardians[i].addr == signer) {
                return true;
            }
        }
        return false;
    }

    function _hasMajority(
        uint signed,
        uint total
        )
        private
        pure
        returns (bool)
    {
        return total > 0 && signed >= (total >> 1) + 1;
    }
}

// File: contracts/modules/security/SignedRequest.sol

// Copyright 2017 Loopring Technology Limited.







/// @title SignedRequest
/// @dev Utility library for better handling of signed wallet requests.
///      This library must be deployed and linked to other modules.
///
/// @author Daniel Wang - <daniel@loopring.org>
library SignedRequest {
    using SignatureUtil for bytes32;

    struct Request {
        address[] signers;
        bytes[]   signatures;
        uint      validUntil;
        address   wallet;
    }

    function verifyRequest(
        HashStore                    hashStore,
        SecurityStore                securityStore,
        bytes32                      domainSeperator,
        bytes32                      txAwareHash,
        GuardianUtils.SigRequirement sigRequirement,
        Request memory               request,
        bytes   memory               encodedRequest
        )
        public
    {
        require(block.timestamp <= request.validUntil, "EXPIRED_SIGNED_REQUEST");

        bytes32 _txAwareHash = EIP712.hashPacked(domainSeperator, encodedRequest);

        // If txAwareHash from the meta-transaction is non-zero,
        // we must verify it matches the hash signed by the respective signers.
        require(
            txAwareHash == 0 || txAwareHash == _txAwareHash,
            "TX_INNER_HASH_MISMATCH"
        );

        // Save hash to prevent replay attacks
        hashStore.verifyAndUpdate(request.wallet, _txAwareHash);

        require(
            _txAwareHash.verifySignatures(request.signers, request.signatures),
            "INVALID_SIGNATURES"
        );

        require(
            GuardianUtils.requireMajority(
                securityStore,
                request.wallet,
                request.signers,
                sigRequirement
            ),
            "PERMISSION_DENIED"
        );
    }
}

// File: contracts/modules/security/SecurityModule.sol

// Copyright 2017 Loopring Technology Limited.





/// @title SecurityStore
///
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract SecurityModule is MetaTxModule
{

    // The minimal number of guardians for recovery and locking.
    uint public constant TOUCH_GRACE_PERIOD = 30 days;

    event WalletLocked(
        address indexed wallet,
        address         by,
        bool            locked
    );

    constructor(
        ControllerImpl _controller,
        address        _metaTxForwarder
        )
        MetaTxModule(_controller, _metaTxForwarder)
    {
    }

    modifier onlyFromWalletOrOwnerWhenUnlocked(address wallet)
    {
        address payable _logicalSender = logicalSender();
        // If the wallet's signature verfication passes, the wallet must be unlocked.
        require(
            _logicalSender == wallet ||
            (_logicalSender == Wallet(wallet).owner() && !_isWalletLocked(wallet)),
             "NOT_FROM_WALLET_OR_OWNER_OR_WALLET_LOCKED"
        );
        securityStore.touchLastActiveWhenRequired(wallet, TOUCH_GRACE_PERIOD);
        _;
    }

    modifier onlyWalletGuardian(address wallet, address guardian)
    {
        require(securityStore.isGuardian(wallet, guardian, false), "NOT_GUARDIAN");
        _;
    }

    modifier notWalletGuardian(address wallet, address guardian)
    {
        require(!securityStore.isGuardian(wallet, guardian, false), "IS_GUARDIAN");
        _;
    }

    // ----- internal methods -----

    function _lockWallet(address wallet, address by, bool locked)
        internal
    {
        securityStore.setLock(wallet, locked);
        emit WalletLocked(wallet, by, locked);
    }

    function _isWalletLocked(address wallet)
        internal
        view
        returns (bool)
    {
        return securityStore.isLocked(wallet);
    }

    function _updateQuota(
        QuotaStore qs,
        address    wallet,
        address    token,
        uint       amount
        )
        internal
    {
        if (amount == 0) return;
        if (qs == QuotaStore(0)) return;

        qs.checkAndAddToSpent(
            wallet,
            token,
            amount,
            priceOracle
        );
    }
}

// File: contracts/modules/security/GuardianModule.sol

// Copyright 2017 Loopring Technology Limited.




/// @title GuardianModule
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract GuardianModule is SecurityModule
{
    using SignatureUtil for bytes32;
    using AddressUtil   for address;

    bytes32 public immutable GUARDIAN_DOMAIN_SEPERATOR;

    uint public constant MAX_GUARDIANS           = 10;
    uint public constant GUARDIAN_PENDING_PERIOD = 3 days;

    bytes32 public constant ADD_GUARDIAN_TYPEHASH = keccak256(
        "addGuardian(address wallet,uint256 validUntil,address guardian)"
    );
    bytes32 public constant REMOVE_GUARDIAN_TYPEHASH = keccak256(
        "removeGuardian(address wallet,uint256 validUntil,address guardian)"
    );
    bytes32 public constant RECOVER_TYPEHASH = keccak256(
        "recover(address wallet,uint256 validUntil,address newOwner)"
    );
    bytes32 public constant LOCK_TYPEHASH = keccak256(
        "lock(address wallet,uint256 validUntil)"
    );
    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "unlock(address wallet,uint256 validUntil)"
    );

    event GuardianAdded   (address indexed wallet, address guardian, uint effectiveTime);
    event GuardianRemoved (address indexed wallet, address guardian, uint effectiveTime);
    event Recovered       (address indexed wallet, address newOwner);

    constructor()
    {
        GUARDIAN_DOMAIN_SEPERATOR = EIP712.hash(
            EIP712.Domain("GuardianModule", "1.2.0", address(this))
        );
    }

    function addGuardian(
        address wallet,
        address guardian
        )
        external
        txAwareHashNotAllowed()
        onlyFromWalletOrOwnerWhenUnlocked(wallet)
        notWalletOwner(wallet, guardian)
    {
        _addGuardian(wallet, guardian, GUARDIAN_PENDING_PERIOD, false);
    }

    function addGuardianWA(
        SignedRequest.Request calldata request,
        address guardian
        )
        external
        notWalletOwner(request.wallet, guardian)
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            GUARDIAN_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.MAJORITY_OWNER_REQUIRED,
            request,
            abi.encode(
                ADD_GUARDIAN_TYPEHASH,
                request.wallet,
                request.validUntil,
                guardian
            )
        );

        _addGuardian(request.wallet, guardian, 0, true);
    }

    function removeGuardian(
        address wallet,
        address guardian
        )
        external
        txAwareHashNotAllowed()
        onlyFromWalletOrOwnerWhenUnlocked(wallet)
    {
        _removeGuardian(wallet, guardian, GUARDIAN_PENDING_PERIOD, false);
    }

    function removeGuardianWA(
        SignedRequest.Request calldata request,
        address guardian
        )
        external
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            GUARDIAN_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.MAJORITY_OWNER_REQUIRED,
            request,
            abi.encode(
                REMOVE_GUARDIAN_TYPEHASH,
                request.wallet,
                request.validUntil,
                guardian
            )
        );

        _removeGuardian(request.wallet, guardian, 0, true);
    }

    function lock(address wallet)
        external
        txAwareHashNotAllowed()
    {
        address payable _logicalSender = logicalSender();
        require(
            _logicalSender == wallet ||
            _logicalSender == Wallet(wallet).owner() ||
            securityStore.isGuardian(wallet, _logicalSender, false),
            "NOT_FROM_WALLET_OR_OWNER_OR_GUARDIAN"
        );

        _lockWallet(wallet, _logicalSender, true);
    }

    function lockWA(
        SignedRequest.Request calldata request
        )
        external
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            GUARDIAN_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.OWNER_OR_ANY_GUARDIAN,
            request,
            abi.encode(
                LOCK_TYPEHASH,
                request.wallet,
                request.validUntil
            )
        );

        _lockWallet(request.wallet, request.signers[0], true);
    }

    function unlock(
        SignedRequest.Request calldata request
        )
        external
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            GUARDIAN_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.MAJORITY_OWNER_REQUIRED,
            request,
            abi.encode(
                UNLOCK_TYPEHASH,
                request.wallet,
                request.validUntil
            )
        );

        _lockWallet(request.wallet, address(this), false);
    }

    /// @dev Recover a wallet by setting a new owner.
    /// @param request The general request object.
    /// @param newOwner The new owner address to set.
    function recover(
        SignedRequest.Request calldata request,
        address newOwner
        )
        external
        notWalletOwner(request.wallet, newOwner)
        eligibleWalletOwner(newOwner)
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            GUARDIAN_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.MAJORITY_OWNER_NOT_ALLOWED,
            request,
            abi.encode(
                RECOVER_TYPEHASH,
                request.wallet,
                request.validUntil,
                newOwner
            )
        );

        SecurityStore ss = securityStore;
        if (ss.isGuardian(request.wallet, newOwner, true)) {
            ss.removeGuardian(request.wallet, newOwner, block.timestamp, true);
        }

        Wallet(request.wallet).setOwner(newOwner);
        _lockWallet(request.wallet, address(this), false);
        ss.cancelPendingGuardians(request.wallet);

        emit Recovered(request.wallet, newOwner);
    }

    function isLocked(address wallet)
        public
        view
        returns (bool)
    {
        return _isWalletLocked(wallet);
    }

    // ---- internal functions ---

    function _addGuardian(
        address wallet,
        address guardian,
        uint    pendingPeriod,
        bool    alwaysOverride
        )
        private
    {
        require(guardian != wallet, "INVALID_ADDRESS");
        require(guardian != address(0), "ZERO_ADDRESS");

        SecurityStore ss = securityStore;
        uint numGuardians = ss.numGuardians(wallet, true);
        require(numGuardians < MAX_GUARDIANS, "TOO_MANY_GUARDIANS");

        uint validSince = block.timestamp;
        if (numGuardians >= 2) {
            validSince = block.timestamp + pendingPeriod;
        }
        validSince = ss.addGuardian(wallet, guardian, validSince, alwaysOverride);
        emit GuardianAdded(wallet, guardian, validSince);
    }

    function _removeGuardian(
        address wallet,
        address guardian,
        uint    pendingPeriod,
        bool    alwaysOverride
        )
        private
    {
        uint validUntil = block.timestamp + pendingPeriod;
        SecurityStore ss = securityStore;
        validUntil = ss.removeGuardian(wallet, guardian, validUntil, alwaysOverride);
        emit GuardianRemoved(wallet, guardian, validUntil);
    }
}

// File: contracts/modules/security/InheritanceModule.sol

// Copyright 2017 Loopring Technology Limited.



/// @title InheritanceModule
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract InheritanceModule is SecurityModule
{
    using AddressUtil   for address;
    using SignatureUtil for bytes32;

    event Inherited(
        address indexed wallet,
        address         inheritor,
        address         newOwner
    );

    event InheritorChanged(
        address indexed wallet,
        address         inheritor,
        uint32          waitingPeriod
    );

    function inheritor(address wallet)
        public
        view
        returns (address _inheritor, uint _effectiveTimestamp)
    {
        return securityStore.inheritor(wallet);
    }

    function inherit(
        address wallet,
        address newOwner
        )
        external
        txAwareHashNotAllowed()
        eligibleWalletOwner(newOwner)
        notWalletOwner(wallet, newOwner)
    {
        SecurityStore ss = securityStore;
        (address _inheritor, uint _effectiveTimestamp) = ss.inheritor(wallet);

        require(_effectiveTimestamp != 0 && _inheritor != address(0), "NO_INHERITOR");
        require(_effectiveTimestamp <= block.timestamp, "TOO_EARLY");
        require(_inheritor == logicalSender(), "UNAUTHORIZED");

        ss.removeAllGuardians(wallet);
        ss.setInheritor(wallet, address(0), 0);
        _lockWallet(wallet, address(this), false);

        Wallet(wallet).setOwner(newOwner);

        emit Inherited(wallet, _inheritor, newOwner);
    }

    function setInheritor(
        address wallet,
        address _inheritor,
        uint32  _waitingPeriod
        )
        external
        txAwareHashNotAllowed()
        onlyFromWalletOrOwnerWhenUnlocked(wallet)
    {
        require(
            _inheritor == address(0) && _waitingPeriod == 0 ||
            _inheritor != address(0) &&
            _waitingPeriod >= TOUCH_GRACE_PERIOD * 2 &&
            _waitingPeriod <= 3650 days,
            "INVALID_INHERITOR_OR_WAITING_PERIOD"
        );

        securityStore.setInheritor(wallet, _inheritor, _waitingPeriod);
        emit InheritorChanged(wallet, _inheritor, _waitingPeriod);
    }
}

// File: contracts/modules/security/WhitelistModule.sol

// Copyright 2017 Loopring Technology Limited.




/// @title WhitelistModule
/// @dev Manages whitelisted addresses.
/// @author Daniel Wang - <daniel@loopring.org>
abstract contract WhitelistModule is SecurityModule
{
    using MathUint      for uint;

    bytes32 public immutable WHITELIST_DOMAIN_SEPERATOR;

    uint public constant WHITELIST_PENDING_PERIOD = 1 days;

    bytes32 public constant ADD_TO_WHITELIST_TYPEHASH = keccak256(
        "addToWhitelist(address wallet,uint256 validUntil,address addr)"
    );
    bytes32 public constant REMOVE_FROM_WHITELIST_TYPEHASH = keccak256(
        "removeFromWhitelist(address wallet,uint256 validUntil,address addr)"
    );

    constructor()
    {
        WHITELIST_DOMAIN_SEPERATOR = EIP712.hash(
            EIP712.Domain("WhitelistModule", "1.2.0", address(this))
        );
    }

    function addToWhitelist(
        address wallet,
        address addr
        )
        external
        txAwareHashNotAllowed()
        onlyFromWalletOrOwnerWhenUnlocked(wallet)
    {
        whitelistStore.addToWhitelist(
            wallet,
            addr,
            block.timestamp.add(WHITELIST_PENDING_PERIOD)
        );
    }

    function addToWhitelistWA(
        SignedRequest.Request calldata request,
        address addr
        )
        external
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            WHITELIST_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.MAJORITY_OWNER_REQUIRED,
            request,
            abi.encode(
                ADD_TO_WHITELIST_TYPEHASH,
                request.wallet,
                request.validUntil,
                addr
            )
        );

        whitelistStore.addToWhitelist(
            request.wallet,
            addr,
            block.timestamp
        );
    }

    function removeFromWhitelist(
        address wallet,
        address addr
        )
        external
        txAwareHashNotAllowed()
        onlyFromWalletOrOwnerWhenUnlocked(wallet)
    {
        whitelistStore.removeFromWhitelist(wallet, addr);
    }

    function removeFromWhitelistWA(
        SignedRequest.Request calldata request,
        address addr
        )
        external
    {
        SignedRequest.verifyRequest(
            hashStore,
            securityStore,
            WHITELIST_DOMAIN_SEPERATOR,
            txAwareHash(),
            GuardianUtils.SigRequirement.MAJORITY_OWNER_REQUIRED,
            request,
            abi.encode(
                REMOVE_FROM_WHITELIST_TYPEHASH,
                request.wallet,
                request.validUntil,
                addr
            )
        );

        whitelistStore.removeFromWhitelist(request.wallet, addr);
    }

    function getWhitelist(address wallet)
        public
        view
        returns (
            address[] memory addresses,
            uint[]    memory effectiveTimes
        )
    {
        return whitelistStore.whitelist(wallet);
    }

    function isWhitelisted(
        address wallet,
        address addr)
        public
        view
        returns (
            bool isWhitelistedAndEffective,
            uint effectiveTime
        )
    {
        return whitelistStore.isWhitelisted(wallet, addr);
    }
}

// File: contracts/modules/security/FinalSecurityModule.sol

// Copyright 2017 Loopring Technology Limited.





/// @title FinalSecurityModule
/// @dev This module combines multiple small modules to
///      minimize the number of modules to reduce gas used
///      by wallet creation.
contract FinalSecurityModule is
    GuardianModule,
    InheritanceModule,
    WhitelistModule
{
    ControllerImpl private immutable controller_;

    constructor(
        ControllerImpl _controller,
        address        _metaTxForwarder
        )
        SecurityModule(_controller, _metaTxForwarder)
        GuardianModule()
        InheritanceModule()
        WhitelistModule()
    {
        controller_ = _controller;
    }
}