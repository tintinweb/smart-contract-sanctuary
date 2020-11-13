// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


/**
 * @title Snapshot
 * @notice Manages snapshots of size 128 bits (32 bits for timestamp, 96 bits for value)
 * 96 bits is enough for storing NU token values, and 32 bits should be OK for block numbers
 * @dev Since each storage slot can hold two snapshots, new slots are allocated every other TX. Thus, gas cost of adding snapshots is 51400 and 36400 gas, alternately.
 * Based on Aragon's Checkpointing (https://https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/Checkpointing.sol)
 * On average, adding snapshots spends ~6500 less gas than the 256-bit checkpoints of Aragon's Checkpointing
 */
library Snapshot {

    function encodeSnapshot(uint32 _time, uint96 _value) internal pure returns(uint128) {
        return uint128(uint256(_time) << 96 | uint256(_value));
    }

    function decodeSnapshot(uint128 _snapshot) internal pure returns(uint32 time, uint96 value){
        time = uint32(bytes4(bytes16(_snapshot)));
        value = uint96(_snapshot);
    }

    function addSnapshot(uint128[] storage _self, uint256 _value) internal {
        addSnapshot(_self, block.number, _value);
    }

    function addSnapshot(uint128[] storage _self, uint256 _time, uint256 _value) internal {
        uint256 length = _self.length;
        if (length != 0) {
            (uint32 currentTime, ) = decodeSnapshot(_self[length - 1]);
            if (uint32(_time) == currentTime) {
                _self[length - 1] = encodeSnapshot(uint32(_time), uint96(_value));
                return;
            } else if (uint32(_time) < currentTime){
                revert();
            }
        }
        _self.push(encodeSnapshot(uint32(_time), uint96(_value)));
    }

    function lastSnapshot(uint128[] storage _self) internal view returns (uint32, uint96) {
        uint256 length = _self.length;
        if (length > 0) {
            return decodeSnapshot(_self[length - 1]);
        }

        return (0, 0);
    }

    function lastValue(uint128[] storage _self) internal view returns (uint96) {
        (, uint96 value) = lastSnapshot(_self);
        return value;
    }

    function getValueAt(uint128[] storage _self, uint256 _time256) internal view returns (uint96) {
        uint32 _time = uint32(_time256);
        uint256 length = _self.length;

        // Short circuit if there's no checkpoints yet
        // Note that this also lets us avoid using SafeMath later on, as we've established that
        // there must be at least one checkpoint
        if (length == 0) {
            return 0;
        }

        // Check last checkpoint
        uint256 lastIndex = length - 1;
        (uint32 snapshotTime, uint96 snapshotValue) = decodeSnapshot(_self[length - 1]);
        if (_time >= snapshotTime) {
            return snapshotValue;
        }

        // Check first checkpoint (if not already checked with the above check on last)
        (snapshotTime, snapshotValue) = decodeSnapshot(_self[0]);
        if (length == 1 || _time < snapshotTime) {
            return 0;
        }

        // Do binary search
        // As we've already checked both ends, we don't need to check the last checkpoint again
        uint256 low = 0;
        uint256 high = lastIndex - 1;
        uint32 midTime;
        uint96 midValue;

        while (high > low) {
            uint256 mid = (high + low + 1) / 2; // average, ceil round
            (midTime, midValue) = decodeSnapshot(_self[mid]);

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // Note that we don't need SafeMath here because mid must always be greater than 0
                // from the while condition
                high = mid - 1;
            } else {
                // _time == midTime
                return midValue;
            }
        }

        (, snapshotValue) = decodeSnapshot(_self[low]);
        return snapshotValue;
    }
}
