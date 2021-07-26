/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.5.14;


/**
 * @notice Bitmap library to set or unset bits on bitmap value
 */
library BitmapLib {

    /**
     * @dev Sets the given bit in the bitmap value
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function setBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit not set, hence, set the bit
        if( ! isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 3 = 4th bit
            // mask = 0000 1000 = Left shift to create mask to find 4rd bit status
            uint128 mask = uint128(1) << _index;

            // Setting the corrospending bit in _bitmap
            // Performing OR (|) operation
            // 0001 0100 (_bitmap)
            // 0000 1000 (mask)
            // -------------------
            // 0001 1100 (result)
            return _bitmap | mask;
        }

        // Bit already set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Unsets the bit in given bitmap
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function unsetBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit is set, hence, unset the bit
        if(isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 2 = 3th bit
            // mask = 0000 0100 = Left shift to create mask to find 3rd bit status
            uint128 mask = uint128(1) << _index;

            // Performing Bitwise NOT(~) operation
            // 1111 1011 (mask)
            mask = ~mask;

            // Unsetting the corrospending bit in _bitmap
            // Performing AND (&) operation
            // 0001 0100 (_bitmap)
            // 1111 1011 (mask)
            // -------------------
            // 0001 0000 (result)
            return _bitmap & mask;
        }

        // Bit not set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Returns true if the corrosponding bit set in the bitmap
     * @param _bitmap Bitmap value to check
     * @param _index Index to check. Index range from 0 to 127
     * @return Returns true if bit is set, false otherwise
     */
    function isBitSet(uint128 _bitmap, uint8 _index) internal pure returns (bool) {
        require(_index < 128, "Index out of range for bit operation");
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Suppose `_index` is = 2 = 3th bit
        // 0000 0100 = Left shift to create mask to find 3rd bit status
        uint128 mask = uint128(1) << _index;

        // Example: When bit is set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 0100 (mask)
        // -------------------------
        // 0000 0100 (bitSet > 0)

        // Example: When bit is not set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 1000 (mask)
        // -------------------------
        // 0000 0000 (bitSet == 0)

        uint128 bitSet = _bitmap & mask;
        // Bit is set when greater than zero, else not set
        return bitSet > 0;
    }
}