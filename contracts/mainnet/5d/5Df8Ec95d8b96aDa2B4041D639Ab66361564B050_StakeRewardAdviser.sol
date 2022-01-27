// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./actions/StakingMsgProcessor.sol";
import "./interfaces/IRewardAdviser.sol";
import "./utils/Utils.sol";

/**
 * @title StakeRewardAdviser
 * @notice It "advises" the "RewardMaster" on staking rewards ("shares").
 * @dev It acts as the "RewardAdviser" for the "RewardMaster": the latter calls
 * this contract to process messages from the "Staking" contract.
 */
contract StakeRewardAdviser is StakingMsgProcessor, Utils, IRewardAdviser {
    // solhint-disable var-name-mixedcase
    bytes4 private immutable STAKED;
    bytes4 private immutable UNSTAKED;
    uint256 public immutable FACTOR;
    // solhint-enable var-name-mixedcase

    uint256 private constant SCALE = 1e9;

    constructor(bytes4 stakeType, uint256 stakeAmountToSharesScaledFactor) {
        require(
            stakeType != bytes4(0) && stakeAmountToSharesScaledFactor != 0,
            "PSA:E1"
        );
        STAKED = _encodeStakeActionType(stakeType);
        UNSTAKED = _encodeUnstakeActionType(stakeType);
        FACTOR = stakeAmountToSharesScaledFactor;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        view
        override
        returns (Advice memory)
    {
        (address staker, uint96 amount, , , , , ) = _unpackStakingActionMsg(
            message
        );
        require(staker != address(0), "PSA: unexpected zero staker");
        require(amount != 0, "PSA: unexpected zero amount");

        uint256 shares = (uint256(amount) * FACTOR) / SCALE;

        if (action == STAKED) {
            return
                Advice(
                    staker, // createSharesFor
                    safe96(shares), // sharesToCreate
                    address(0), // redeemSharesFrom
                    0, // sharesToRedeem
                    address(0) // sendRewardTo
                );
        }
        if (action == UNSTAKED) {
            return
                Advice(
                    address(0), // createSharesFor
                    0, // sharesToCreate
                    staker, // redeemSharesFrom
                    safe96(shares), // sharesToRedeem
                    staker // sendRewardTo
                );
        }

        revert("PSA: unsupported action");
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "../interfaces/IStakingTypes.sol";

abstract contract StakingMsgProcessor {
    bytes4 internal constant STAKE_ACTION = bytes4(keccak256("stake"));
    bytes4 internal constant UNSTAKE_ACTION = bytes4(keccak256("unstake"));

    function _encodeStakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(STAKE_ACTION, stakeType)));
    }

    function _encodeUnstakeActionType(bytes4 stakeType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(UNSTAKE_ACTION, stakeType)));
    }

    function _packStakingActionMsg(
        address staker,
        IStakingTypes.Stake memory stake,
        bytes calldata data
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                staker, // address
                stake.amount, // uint96
                stake.id, // uint32
                stake.stakedAt, // uint32
                stake.lockedTill, // uint32
                stake.claimedAt, // uint32
                data // bytes
            );
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _unpackStakingActionMsg(bytes memory message)
        internal
        pure
        returns (
            address staker,
            uint96 amount,
            uint32 id,
            uint32 stakedAt,
            uint32 lockedTill,
            uint32 claimedAt,
            bytes memory data
        )
    {
        // staker, amount, id and 3 timestamps occupy exactly 48 bytes
        // (`data` may be of zero length)
        require(message.length >= 48, "SMP: unexpected msg length");

        uint256 stakerAndAmount;
        uint256 idAndStamps;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // the 1st word (32 bytes) contains the `message.length`
            // we need the (entire) 2nd word ..
            stakerAndAmount := mload(add(message, 0x20))
            // .. and (16 bytes of) the 3rd word
            idAndStamps := mload(add(message, 0x40))
        }

        staker = address(uint160(stakerAndAmount >> 96));
        amount = uint96(stakerAndAmount & 0xFFFFFFFFFFFFFFFFFFFFFFFF);

        id = uint32((idAndStamps >> 224) & 0xFFFFFFFF);
        stakedAt = uint32((idAndStamps >> 192) & 0xFFFFFFFF);
        lockedTill = uint32((idAndStamps >> 160) & 0xFFFFFFFF);
        claimedAt = uint32((idAndStamps >> 128) & 0xFFFFFFFF);

        uint256 dataLength = message.length - 48;
        data = new bytes(dataLength);
        for (uint256 i = 0; i < dataLength; i++) {
            data[i] = message[i + 48];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardAdviser {
    struct Advice {
        // advice on new "shares" (in the reward pool) to create
        address createSharesFor;
        uint96 sharesToCreate;
        // advice on "shares" to redeem
        address redeemSharesFrom;
        uint96 sharesToRedeem;
        // advice on address the reward against redeemed shares to send to
        address sendRewardTo;
    }

    function getRewardAdvice(bytes4 action, bytes memory message)
        external
        returns (Advice memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

abstract contract Utils {
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

interface IStakingTypes {
    // Stake type terms
    struct Terms {
        // if stakes of this kind allowed
        bool isEnabled;
        // if messages on stakes to be sent to the {RewardMaster}
        bool isRewarded;
        // limit on the minimum amount staked, no limit if zero
        uint32 minAmountScaled;
        // limit on the maximum amount staked, no limit if zero
        uint32 maxAmountScaled;
        // Stakes not accepted before this time, has no effect if zero
        uint32 allowedSince;
        // Stakes not accepted after this time, has no effect if zero
        uint32 allowedTill;
        // One (at least) of the following three params must be non-zero
        // if non-zero, overrides both `exactLockPeriod` and `minLockPeriod`
        uint32 lockedTill;
        // ignored if non-zero `lockedTill` defined, overrides `minLockPeriod`
        uint32 exactLockPeriod;
        // has effect only if both `lockedTill` and `exactLockPeriod` are zero
        uint32 minLockPeriod;
    }

    struct Stake {
        // index in the `Stake[]` array of `stakes`
        uint32 id;
        // defines Terms
        bytes4 stakeType;
        // time this stake was created at
        uint32 stakedAt;
        // time this stake can be claimed at
        uint32 lockedTill;
        // time this stake was claimed at (unclaimed if 0)
        uint32 claimedAt;
        // amount of tokens on this stake (assumed to be less 1e27)
        uint96 amount;
        // address stake voting power is delegated to
        address delegatee;
    }
}