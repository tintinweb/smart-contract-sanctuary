// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library HodlLib {
    // The packed hodl item makes heavy use of bit packing
    // to minimize storage costs.
    struct PackedHodlItem {
        // Contains the fields of a packed `UnpackedHodlItem`. See the struct definition
        // below for more information.
        uint256 packedData;
        //
        // Mostly zero
        //
        // The creator address is only set if different than the `prpsBeneficiary`.
        address creator;
        // The dubiBeneficiary is only set if different than the `prpsBeneficiary`.
        address dubiBeneficiary;
        uint96 pendingLockedPrps;
    }

    // The unpacked hodl item contains the unpacked data of an hodl item from storage.
    // It minimizes storage reads, since only a single read from storage is necessary
    // in most cases to access all relevant data.
    //
    // NOTE: The bit-sizes of the fields are rounded up to the nearest Solidity type.
    struct UnpackedHodlItem {
        // The id of the hodl item is actually a uint20, but stored in a uint24 for
        // technical reasons. Allows for 2^20 = 1_048_576 hodls per address
        // Actual size: uint20
        uint24 id;
        // The hodl duration is stored using 9 bits and measured in days.
        // Technically, allowing for 2^9 = 512 days, but we cap it to 365 days.
        // In the remaining 3 bytes several 1-bit flags are stored like:
        // `hasDependentHodlOp` and `hasPendingLockedPrps`, etc.
        // Actual size: uint12
        uint16 duration;
        UnpackedFlags flags;
        // The last withdrawal timestamp in unix seconds (block timestamp). Defaults to
        // the creation date of the hodl.
        uint32 lastWithdrawal;
        // Storing the PRPS amount in a uint96 still allows to lock up to ~ 7 billion PRPS
        // which is plenty enough.
        uint96 lockedPrps;
        uint96 burnedLockedPrps;
    }

    struct UnpackedFlags {
        // True, if creator is not the PRPS beneficiary
        bool hasDifferentCreator;
        // True, if DUBI beneficiary is not the PRPS beneficiary
        bool hasDifferentDubiBeneficiary;
        bool hasDependentHodlOp;
        bool hasPendingLockedPrps;
    }

    // Struct that contains all unpacked data and the additional almost-always zero fields from
    // the packed hodl item - returned from `getHodl()` to be more user-friendly to consume.
    struct PrettyHodlItem {
        uint24 id;
        uint16 duration;
        UnpackedFlags flags;
        uint32 lastWithdrawal;
        uint96 lockedPrps;
        uint96 burnedLockedPrps;
        address creator;
        address dubiBeneficiary;
        uint96 pendingLockedPrps;
    }

    /**
     * @dev Pack an unpacked hodl item and return a uint256
     */
    function packHodlItem(UnpackedHodlItem memory _unpackedHodlItem)
        internal
        pure
        returns (uint256)
    {
        //
        // Allows for 2^20 = 1_048_576 hodls per address
        // uint20 id;
        //
        // The hodl duration is stored using 9 bits and measured in days.
        // Technically, allowing for 2^9 = 512 days, but we only need 365 days anyway.
        // uint9 durationAndFlags;
        //
        // Followed by 4 bits to hold 4 flags:
        // - `hasDifferentCreator`
        // - `hasDifferentDubiBeneficiarys`
        // - `hasDependentHodlOp`
        // - `hasPendingLockedPrps`
        //
        // The last withdrawal timestamp in unix seconds (block timestamp). Defaults to
        // the creation date of the hodl and uses 31 bits:
        // uint31 lastWithdrawal
        //
        // The PRPS amounts are stored in a uint96 which can hold up to ~ 7 billion PRPS
        // which is plenty enough.
        // uint96 lockedPrps;
        // uint96 burnedLockedPrps;
        //

        // Build the packed data according to the spec above.
        uint256 packedData;
        uint256 offset;

        // 1) Set first 20 bits to id
        // Since it is stored in a uint24 AND it with a bitmask where the first 20 bits are 1
        uint24 id = _unpackedHodlItem.id;
        uint24 idMask = (1 << 20) - 1;
        packedData |= uint256(id & idMask) << offset;
        offset += 20;

        // 2) Set next 9 bits to duration.
        // Since it is stored in a uint16 AND it with a bitmask where the first 9 bits are 1

        uint16 duration = _unpackedHodlItem.duration;
        uint16 durationMask = (1 << 9) - 1;
        packedData |= uint256(duration & durationMask) << offset;
        offset += 9;

        // 3) Set next 31 bits to withdrawal time
        // Since it is stored in a uint32 AND it with a bitmask where the first 31 bits are 1
        uint32 lastWithdrawal = _unpackedHodlItem.lastWithdrawal;
        uint32 lastWithdrawalMask = (1 << 31) - 1;
        packedData |= uint256(lastWithdrawal & lastWithdrawalMask) << offset;
        offset += 31;

        // 4) Set the 4 flags in the next 4 bits after lastWithdrawal.
        UnpackedFlags memory flags = _unpackedHodlItem.flags;
        if (flags.hasDifferentCreator) {
            // PRPS beneficiary is not the creator
            packedData |= 1 << (offset + 0);
        }

        if (flags.hasDifferentDubiBeneficiary) {
            // PRPS beneficiary is not the DUBI beneficiary
            packedData |= 1 << (offset + 1);
        }

        if (flags.hasDependentHodlOp) {
            packedData |= 1 << (offset + 2);
        }

        if (flags.hasPendingLockedPrps) {
            packedData |= 1 << (offset + 3);
        }

        offset += 4;

        // 5) Set next 96 bits to locked PRPS
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        packedData |= uint256(_unpackedHodlItem.lockedPrps) << offset;
        offset += 96;

        // 6) Set next 96 bits to burned locked PRPS
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        packedData |= uint256(_unpackedHodlItem.burnedLockedPrps) << offset;
        offset += 96;

        assert(offset == 256);

        return packedData;
    }

    /**
     * @dev Unpack a packed hodl item.
     */
    function unpackHodlItem(uint256 packedData)
        internal
        pure
        returns (UnpackedHodlItem memory)
    {
        UnpackedHodlItem memory _unpacked;
        uint256 offset;

        // 1) Read id from the first 20 bits
        uint24 id = uint24(packedData >> offset);
        uint24 idMask = (1 << 20) - 1;
        _unpacked.id = id & idMask;
        offset += 20;

        // 2) Read duration from the next 9 bits
        uint16 duration = uint16(packedData >> offset);
        uint16 durationMask = (1 << 9) - 1;
        _unpacked.duration = duration & durationMask;
        offset += 9;

        // 3) Read lastWithdrawal time from the next 31 bits
        uint32 lastWithdrawal = uint32(packedData >> offset);
        uint32 lastWithdrawalMask = (1 << 31) - 1;
        _unpacked.lastWithdrawal = lastWithdrawal & lastWithdrawalMask;
        offset += 31;

        // 4) Read the 4 flags from the next 4 bits
        UnpackedFlags memory flags = _unpacked.flags;

        flags.hasDifferentCreator = (packedData >> (offset + 0)) & 1 == 1;
        flags.hasDifferentDubiBeneficiary =
            (packedData >> (offset + 1)) & 1 == 1;
        flags.hasDependentHodlOp = (packedData >> (offset + 2)) & 1 == 1;
        flags.hasPendingLockedPrps = (packedData >> (offset + 3)) & 1 == 1;

        offset += 4;

        // 5) Read locked PRPS from the next 96 bits
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        _unpacked.lockedPrps = uint96(packedData >> offset);
        offset += 96;

        // 5) Read burned locked PRPS from the next 96 bits
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        _unpacked.burnedLockedPrps = uint96(packedData >> offset);
        offset += 96;

        assert(offset == 256);

        return _unpacked;
    }

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    struct PendingHodl {
        // HodlLib.PackedHodlItem;
        address creator;
        uint96 amountPrps;
        address dubiBeneficiary;
        uint96 dubiToMint;
        address prpsBeneficiary;
        uint24 hodlId;
        uint16 duration;
    }

    struct PendingRelease {
        uint24 hodlId;
        uint96 releasablePrps;
        // Required for look-up of hodl item
        address creator;
        // prpsBeneficiary is implied
    }

    struct PendingWithdrawal {
        address prpsBeneficiary;
        uint96 dubiToMint;
        // Required for look-up of hodl item
        address creator;
        uint24 hodlId;
    }

    function setLockedPrpsToPending(
        HodlLib.PackedHodlItem[] storage hodlsSender,
        uint96 amount
    ) public {
        // Sum of the PRPS that got marked pending or removed from pending hodls.
        uint96 totalLockedPrpsMarkedPending;
        uint256 length = hodlsSender.length;
        for (uint256 i = 0; i < length; i++) {
            HodlLib.PackedHodlItem storage packed = hodlsSender[i];
            HodlLib.UnpackedHodlItem memory unpacked = HodlLib.unpackHodlItem(
                packed.packedData
            );

            // Skip hodls which are occupied by pending releases/withdrawals, but
            // allow modifying hodls with already pending locked PRPS.
            if (unpacked.flags.hasDependentHodlOp) {
                continue;
            }

            uint96 remainingPendingPrps = amount - totalLockedPrpsMarkedPending;

            // Sanity check
            assert(remainingPendingPrps <= amount);

            // No more PRPS left to mark pending
            if (remainingPendingPrps == 0) {
                break;
            }

            // Remaining PRPS on the hodl that can be marked pending
            uint96 pendingLockedPrps;
            if (unpacked.flags.hasPendingLockedPrps) {
                pendingLockedPrps = packed.pendingLockedPrps;
            }

            uint96 remainingLockedPrps = unpacked.lockedPrps -
                unpacked.burnedLockedPrps -
                pendingLockedPrps;

            // Sanity check
            assert(remainingLockedPrps <= unpacked.lockedPrps);

            // Skip to next hodl if no PRPS left on hodl
            if (remainingLockedPrps == 0) {
                continue;
            }

            // Cap amount if the remaining PRPS on hodl is less than what still needs to be marked pending
            if (remainingPendingPrps > remainingLockedPrps) {
                remainingPendingPrps = remainingLockedPrps;
            }

            // Update pending PRPS on hodl
            uint96 updatedPendingPrpsOnHodl = pendingLockedPrps +
                remainingPendingPrps;

            // Total of pending PRPS on hodl may never exceed (locked - burned) PRPS.
            assert(
                updatedPendingPrpsOnHodl <=
                    unpacked.lockedPrps - unpacked.burnedLockedPrps
            );

            totalLockedPrpsMarkedPending += remainingPendingPrps;

            // Write updated hodl item to storage
            unpacked.flags.hasPendingLockedPrps = true;
            packed.pendingLockedPrps = updatedPendingPrpsOnHodl;
            packed.packedData = HodlLib.packHodlItem(unpacked);
        }

        require(totalLockedPrpsMarkedPending == amount, "H-14");
    }

    function revertLockedPrpsSetToPending(
        HodlLib.PackedHodlItem[] storage hodlsSender,
        uint96 amount
    ) public {
        require(amount > 0, "H-22");

        // Remaining pending PRPS to take from hodls
        uint96 remainingPendingLockedPrps = amount;
        uint256 length = hodlsSender.length;

        // Traverse hodls and remove pending locked PRPS until `amount`
        // is filled.
        for (uint256 i = 0; i < length; i++) {
            HodlLib.PackedHodlItem storage packed = hodlsSender[i];
            HodlLib.UnpackedHodlItem memory unpacked = HodlLib.unpackHodlItem(
                packed.packedData
            );

            if (
                !unpacked.flags.hasPendingLockedPrps ||
                unpacked.flags.hasDependentHodlOp
            ) {
                // Skip hodls without pending locked PRPS or when occupied
                // by pending releases and withdrawals
                continue;
            }

            // Hodl has pending locked PRPS

            // Ensure we do not remove more than what is needed
            uint96 remainingPendingPrpsOnHodl = packed.pendingLockedPrps;
            if (remainingPendingPrpsOnHodl > remainingPendingLockedPrps) {
                remainingPendingPrpsOnHodl = remainingPendingLockedPrps;
            }

            // The check above guarantees that this cannot underflow
            remainingPendingLockedPrps -= remainingPendingPrpsOnHodl;
            packed.pendingLockedPrps -= remainingPendingPrpsOnHodl;

            // Update hodl if all pending locked PRPS has been removed
            if (remainingPendingPrpsOnHodl == 0) {
                unpacked.flags.hasPendingLockedPrps = false;
                packed.packedData = HodlLib.packHodlItem(unpacked);
            }

            // Break loop if the remaining total pending PRPS is zero
            if (remainingPendingLockedPrps == 0) {
                // Done
                break;
            }
        }

        // Sanity check
        assert(remainingPendingLockedPrps == 0);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}