// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";
import "./GuardianLib.sol";
import "./LockLib.sol";
import "./Utils.sol";


/// @title RecoverLib
/// @author Brecht Devos - <[email protected]>
library RecoverLib
{
    using GuardianLib   for Wallet;
    using LockLib       for Wallet;
    using ApprovalLib   for Wallet;
    using Utils         for address;

    event Recovered(address newOwner);

    bytes32 public constant RECOVER_TYPEHASH = keccak256(
        "recover(address wallet,uint256 validUntil,address newOwner,address[] newGuardians)"
    );

    /// @dev Recover a wallet by setting a new owner and guardians.
    /// @param approval The approval.
    /// @param newOwner The new owner address to set.
    /// @param newGuardians The new guardians addresses to set.
    function recover(
        Wallet   storage   wallet,
        bytes32            domainSeparator,
        Approval calldata  approval,
        address            newOwner,
        address[] calldata newGuardians
        )
        external
        returns (bytes32 approvedHash)
    {
        require(wallet.owner != newOwner, "IS_SAME_OWNER");
        require(newOwner.isValidWalletOwner(), "INVALID_NEW_WALLET_OWNER");

        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_NOT_ALLOWED,
            approval,
            abi.encode(
                RECOVER_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                newOwner,
                keccak256(abi.encodePacked(newGuardians))
            )
        );

        wallet.owner = newOwner;
        wallet.setLock(address(this), false);

        if (newGuardians.length > 0) {
            for (uint i = 0; i < newGuardians.length; i++) {
                require(newGuardians[i] != newOwner, "INVALID_NEW_WALLET_GUARDIAN");
            }
            wallet.removeAllGuardians();
            wallet.addGuardiansImmediately(newGuardians);
        } else {
            if (wallet.isGuardian(newOwner, true)) {
                wallet.deleteGuardian(newOwner, block.timestamp, true);
            }
            wallet.cancelPendingGuardians();
        }

        emit Recovered(newOwner);
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/EIP712.sol";
import "../../lib/SignatureUtil.sol";
import "./GuardianLib.sol";
import "./WalletData.sol";


/// @title ApprovalLib
/// @dev Utility library for better handling of signed wallet requests.
///      This library must be deployed and linked to other modules.
///
/// @author Daniel Wang - <[email protected]>
library ApprovalLib {
    using SignatureUtil for bytes32;

    function verifyApproval(
        Wallet  storage wallet,
        bytes32         domainSeparator,
        SigRequirement  sigRequirement,
        Approval memory approval,
        bytes    memory encodedRequest
        )
        internal
        returns (bytes32 approvedHash)
    {
        require(address(this) == approval.wallet, "INVALID_WALLET");
        require(block.timestamp <= approval.validUntil, "EXPIRED_SIGNED_REQUEST");

        approvedHash = EIP712.hashPacked(domainSeparator, keccak256(encodedRequest));

        // Save hash to prevent replay attacks
        require(!wallet.hashes[approvedHash], "HASH_EXIST");
        wallet.hashes[approvedHash] = true;

        require(
            approvedHash.verifySignatures(approval.signers, approval.signatures),
            "INVALID_SIGNATURES"
        );

        require(
            GuardianLib.requireMajority(
                wallet,
                approval.signers,
                sigRequirement
            ),
            "PERMISSION_DENIED"
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

enum SigRequirement
{
    MAJORITY_OWNER_NOT_ALLOWED,
    MAJORITY_OWNER_ALLOWED,
    MAJORITY_OWNER_REQUIRED,
    OWNER_OR_ANY_GUARDIAN,
    ANY_GUARDIAN
}

struct Approval
{
    address[] signers;
    bytes[]   signatures;
    uint      validUntil;
    address   wallet;
}

// Optimized to fit into 64 bytes (2 slots)
struct Quota
{
    uint128 currentQuota;
    uint128 pendingQuota;
    uint128 spentAmount;
    uint64  spentTimestamp;
    uint64  pendingUntil;
}

enum GuardianStatus
{
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

struct Wallet
{
    address owner;
    uint64  creationTimestamp;

    // relayer => nonce
    uint nonce;
    // hash => consumed
    mapping (bytes32 => bool) hashes;

    bool    locked;

    Guardian[] guardians;
    mapping (address => uint)  guardianIdx;

    address    inheritor;
    uint32     inheritWaitingPeriod;
    uint64     lastActive; // the latest timestamp the owner is considered to be active

    Quota quota;

    // whitelisted address => effective timestamp
    mapping (address => uint) whitelisted;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WalletData.sol";
import "./ApprovalLib.sol";
import "../../lib/SignatureUtil.sol";
import "../../thirdparty/SafeCast.sol";


/// @title GuardianModule
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang - <[email protected]>
library GuardianLib
{
    using AddressUtil   for address;
    using SafeCast      for uint;
    using SignatureUtil for bytes32;
    using ApprovalLib   for Wallet;

    uint public constant MAX_GUARDIANS           = 10;
    uint public constant GUARDIAN_PENDING_PERIOD = 3 days;

    bytes32 public constant ADD_GUARDIAN_TYPEHASH = keccak256(
        "addGuardian(address wallet,uint256 validUntil,address guardian)"
    );
    bytes32 public constant REMOVE_GUARDIAN_TYPEHASH = keccak256(
        "removeGuardian(address wallet,uint256 validUntil,address guardian)"
    );
    bytes32 public constant RESET_GUARDIANS_TYPEHASH = keccak256(
        "resetGuardians(address wallet,uint256 validUntil,address[] guardians)"
    );

    event GuardianAdded   (address guardian, uint effectiveTime);
    event GuardianRemoved (address guardian, uint effectiveTime);

    function addGuardiansImmediately(
        Wallet    storage wallet,
        address[] memory  _guardians
        )
        external
    {
        address guardian = address(0);
        for (uint i = 0; i < _guardians.length; i++) {
            require(_guardians[i] > guardian, "INVALID_ORDERING");
            guardian = _guardians[i];
            _addGuardian(wallet, guardian, 0, true);
        }
    }

    function addGuardian(
        Wallet storage wallet,
        address guardian
        )
        external
    {
        _addGuardian(wallet, guardian, GUARDIAN_PENDING_PERIOD, false);
    }

    function addGuardianWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address  guardian
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                ADD_GUARDIAN_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                guardian
            )
        );

        _addGuardian(wallet, guardian, 0, true);
    }

    function removeGuardian(
        Wallet storage wallet,
        address guardian
        )
        external
    {
        _removeGuardian(wallet, guardian, GUARDIAN_PENDING_PERIOD, false);
    }

    function removeGuardianWA(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval,
        address  guardian
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                REMOVE_GUARDIAN_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                guardian
            )
        );

        _removeGuardian(wallet, guardian, 0, true);
    }

    function resetGuardians(
        Wallet    storage  wallet,
        address[] calldata newGuardians
        )
        external
    {
        Guardian[] memory allGuardians = guardians(wallet, true);
        for (uint i = 0; i < allGuardians.length; i++) {
            _removeGuardian(wallet, allGuardians[i].addr, GUARDIAN_PENDING_PERIOD, false);
        }

        for (uint j = 0; j < newGuardians.length; j++) {
            _addGuardian(wallet, newGuardians[j], GUARDIAN_PENDING_PERIOD, false);
        }
    }

    function resetGuardiansWA(
        Wallet    storage  wallet,
        bytes32            domainSeparator,
        Approval  calldata approval,
        address[] calldata newGuardians
        )
        external
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                RESET_GUARDIANS_TYPEHASH,
                approval.wallet,
                approval.validUntil,
                keccak256(abi.encodePacked(newGuardians))
            )
        );

        removeAllGuardians(wallet);
        for (uint i = 0; i < newGuardians.length; i++) {
            _addGuardian(wallet, newGuardians[i], 0, true);
        }
    }

    function requireMajority(
        Wallet         storage wallet,
        address[]      memory  signers,
        SigRequirement         requirement
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
        Guardian[] memory allGuardians = guardians(wallet, false);
        require(allGuardians.length > 0, "NO_GUARDIANS");

        address lastSigner;
        bool walletOwnerSigned = false;
        address owner = wallet.owner;
        for (uint i = 0; i < signers.length; i++) {
            // Check for duplicates
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];

            if (signers[i] == owner) {
                walletOwnerSigned = true;
            } else {
                bool _isGuardian = false;
                for (uint j = 0; j < allGuardians.length; j++) {
                    if (allGuardians[j].addr == signers[i]) {
                        _isGuardian = true;
                        break;
                    }
                }
                require(_isGuardian, "SIGNER_NOT_GUARDIAN");
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

        return signers.length >= (numExtendedSigners >> 1) + 1;
    }

    function isGuardian(
        Wallet storage wallet,
        address addr,
        bool    includePendingAddition
        )
        public
        view
        returns (bool)
    {
        Guardian memory g = _getGuardian(wallet, addr);
        return _isActiveOrPendingAddition(g, includePendingAddition);
    }

    function guardians(
        Wallet storage wallet,
        bool    includePendingAddition
        )
        public
        view
        returns (Guardian[] memory _guardians)
    {
        _guardians = new Guardian[](wallet.guardians.length);
        uint index = 0;
        for (uint i = 0; i < wallet.guardians.length; i++) {
            Guardian memory g = wallet.guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                _guardians[index] = g;
                index++;
            }
        }
        assembly { mstore(_guardians, index) }
    }

    function numGuardians(
        Wallet storage wallet,
        bool    includePendingAddition
        )
        public
        view
        returns (uint count)
    {
        for (uint i = 0; i < wallet.guardians.length; i++) {
            Guardian memory g = wallet.guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                count++;
            }
        }
    }

     function removeAllGuardians(
        Wallet storage wallet
        )
        internal
    {
        uint size = wallet.guardians.length;
        if (size == 0) return;

        for (uint i = 0; i < wallet.guardians.length; i++) {
            delete wallet.guardianIdx[wallet.guardians[i].addr];
        }
        delete wallet.guardians;
    }

    function cancelPendingGuardians(Wallet storage wallet)
        internal
    {
        bool cancelled = false;
        for (uint i = 0; i < wallet.guardians.length; i++) {
            Guardian memory g = wallet.guardians[i];
            if (_isPendingAddition(g)) {
                wallet.guardians[i].status = uint8(GuardianStatus.REMOVE);
                wallet.guardians[i].timestamp = 0;
                cancelled = true;
            }
            if (_isPendingRemoval(g)) {
                wallet.guardians[i].status = uint8(GuardianStatus.ADD);
                wallet.guardians[i].timestamp = 0;
                cancelled = true;
            }
        }
        _cleanRemovedGuardians(wallet, true);
    }

    function storeGuardian(
        Wallet storage wallet,
        address addr,
        uint    validSince,
        bool    alwaysOverride
        )
        internal
        returns (uint)
    {
        require(validSince >= block.timestamp, "INVALID_VALID_SINCE");
        require(addr != address(0), "ZERO_ADDRESS");
        require(addr != address(this), "INVALID_ADDRESS");

        uint pos = wallet.guardianIdx[addr];

        if (pos == 0) {
            // Add the new guardian
            Guardian memory _g = Guardian(
                addr,
                uint8(GuardianStatus.ADD),
                validSince.toUint64()
            );
            wallet.guardians.push(_g);
            wallet.guardianIdx[addr] = wallet.guardians.length;

            _cleanRemovedGuardians(wallet, false);
            return validSince;
        }

        Guardian memory g = wallet.guardians[pos - 1];

        if (_isRemoved(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.ADD);
            wallet.guardians[pos - 1].timestamp = validSince.toUint64();
            return validSince;
        }

        if (_isPendingRemoval(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.ADD);
            wallet.guardians[pos - 1].timestamp = 0;
            return 0;
        }

        if (_isPendingAddition(g)) {
            if (!alwaysOverride) return g.timestamp;

            wallet.guardians[pos - 1].timestamp = validSince.toUint64();
            return validSince;
        }

        require(_isAdded(g), "UNEXPECTED_RESULT");
        return 0;
    }

    function deleteGuardian(
        Wallet storage wallet,
        address addr,
        uint    validUntil,
        bool    alwaysOverride
        )
        internal
        returns (uint)
    {
        require(validUntil >= block.timestamp, "INVALID_VALID_UNTIL");
        require(addr != address(0), "ZERO_ADDRESS");

        uint pos = wallet.guardianIdx[addr];
        require(pos > 0, "GUARDIAN_NOT_EXISTS");

        Guardian memory g = wallet.guardians[pos - 1];

        if (_isAdded(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.REMOVE);
            wallet.guardians[pos - 1].timestamp = validUntil.toUint64();
            return validUntil;
        }

        if (_isPendingAddition(g)) {
            wallet.guardians[pos - 1].status = uint8(GuardianStatus.REMOVE);
            wallet.guardians[pos - 1].timestamp = 0;
            return 0;
        }

        if (_isPendingRemoval(g)) {
            if (!alwaysOverride) return g.timestamp;

            wallet.guardians[pos - 1].timestamp = validUntil.toUint64();
            return validUntil;
        }

        require(_isRemoved(g), "UNEXPECTED_RESULT");
        return 0;
    }

    // --- Internal functions ---

    function _addGuardian(
        Wallet storage wallet,
        address guardian,
        uint    pendingPeriod,
        bool    alwaysOverride
        )
        internal
    {
        uint _numGuardians = numGuardians(wallet, true);
        require(_numGuardians < MAX_GUARDIANS, "TOO_MANY_GUARDIANS");
        require(guardian != wallet.owner, "GUARDIAN_CAN_NOT_BE_OWNER");

        uint validSince = block.timestamp;
        if (_numGuardians >= 2) {
            validSince = block.timestamp + pendingPeriod;
        }
        validSince = storeGuardian(wallet, guardian, validSince, alwaysOverride);
        emit GuardianAdded(guardian, validSince);
    }

    function _removeGuardian(
        Wallet storage wallet,
        address guardian,
        uint    pendingPeriod,
        bool    alwaysOverride
        )
        private
    {
        uint validUntil = block.timestamp + pendingPeriod;
        validUntil = deleteGuardian(wallet, guardian, validUntil, alwaysOverride);
        emit GuardianRemoved(guardian, validUntil);
    }

    function _getGuardian(
        Wallet storage wallet,
        address addr
        )
        private
        view
        returns (Guardian memory guardian)
    {
        uint pos = wallet.guardianIdx[addr];
        if (pos > 0) {
            guardian = wallet.guardians[pos - 1];
        }
    }

    function _isAdded(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(GuardianStatus.ADD) &&
            guardian.timestamp <= block.timestamp;
    }

    function _isPendingAddition(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(GuardianStatus.ADD) &&
            guardian.timestamp > block.timestamp;
    }

    function _isRemoved(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(GuardianStatus.REMOVE) &&
            guardian.timestamp <= block.timestamp;
    }

    function _isPendingRemoval(Guardian memory guardian)
        private
        view
        returns (bool)
    {
         return guardian.status == uint8(GuardianStatus.REMOVE) &&
            guardian.timestamp > block.timestamp;
    }

    function _isActive(Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return _isAdded(guardian) || _isPendingRemoval(guardian);
    }

    function _isActiveOrPendingAddition(
        Guardian memory guardian,
        bool includePendingAddition
        )
        private
        view
        returns (bool)
    {
        return _isActive(guardian) || includePendingAddition && _isPendingAddition(guardian);
    }

    function _cleanRemovedGuardians(
        Wallet storage wallet,
        bool    force
        )
        private
    {
        uint count = wallet.guardians.length;
        if (!force && count < 10) return;

        for (int i = int(count) - 1; i >= 0; i--) {
            Guardian memory g = wallet.guardians[uint(i)];
            if (_isRemoved(g)) {
                Guardian memory lastGuardian = wallet.guardians[wallet.guardians.length - 1];

                if (g.addr != lastGuardian.addr) {
                    wallet.guardians[uint(i)] = lastGuardian;
                    wallet.guardianIdx[lastGuardian.addr] = uint(i) + 1;
                }
                wallet.guardians.pop();
                delete wallet.guardianIdx[g.addr];
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ApprovalLib.sol";
import "./WalletData.sol";
import "./GuardianLib.sol";


/// @title LockLib
/// @author Brecht Devos - <[email protected]>
library LockLib
{
    using GuardianLib   for Wallet;
    using ApprovalLib   for Wallet;

    event WalletLocked (
        address         by,
        bool            locked
    );

    bytes32 public constant LOCK_TYPEHASH = keccak256(
        "lock(address wallet,uint256 validUntil)"
    );
    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "unlock(address wallet,uint256 validUntil)"
    );

    function lock(Wallet storage wallet)
        public
    {
        require(
            msg.sender == address(this) ||
            msg.sender == wallet.owner ||
            wallet.isGuardian(msg.sender, false),
            "NOT_FROM_WALLET_OR_OWNER_OR_GUARDIAN"
        );

        setLock(wallet, msg.sender, true);
    }

    function unlock(
        Wallet   storage  wallet,
        bytes32           domainSeparator,
        Approval calldata approval
        )
        public
        returns (bytes32 approvedHash)
    {
        approvedHash = wallet.verifyApproval(
            domainSeparator,
            SigRequirement.MAJORITY_OWNER_REQUIRED,
            approval,
            abi.encode(
                UNLOCK_TYPEHASH,
                approval.wallet,
                approval.validUntil
            )
        );

        setLock(wallet, msg.sender, false);
    }

    function setLock(
        Wallet storage wallet,
        address        by,
        bool           locked
        )
        internal
    {
        wallet.locked = locked;
        emit WalletLocked(by, locked);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WalletData.sol";
import "../../lib/AddressUtil.sol";

/// @title Utils
/// @author Brecht Devos - <[email protected]>
library Utils
{
    using AddressUtil for address;

    function isValidWalletOwner(address addr)
        view
        internal
        returns (bool)
    {
        return addr != address(0) && !addr.isContract();
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


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
        bytes32 domainSeparator,
        bytes32 dataHash
        )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                domainSeparator,
                dataHash
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../thirdparty/BytesUtil.sol";
import "./AddressUtil.sol";
import "./ERC1271.sol";
import "./MathUint.sol";


/// @title SignatureUtil
/// @author Daniel Wang - <[email protected]>
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

// SPDX-License-Identifier: UNLICENSED
// Taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for addresses
/// @author Daniel Wang - <[email protected]>
/// @author Brecht Devos - <[email protected]>
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
        bytes32      _hash,
        bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
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

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol

pragma solidity ^0.7.0;


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

