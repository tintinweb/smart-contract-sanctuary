/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity ^0.5.0;


contract CompressedCaller {

    function compressedCall(
        address target,
        uint256 totalLength,
        bytes memory zip
    )
        public
        payable
        returns (bytes memory result)
    {
        bytes memory zeros = new bytes(127);
        bytes memory data = new bytes(totalLength);
        uint index = 0;

        for (uint i = 0; i < zip.length; i++) {

            uint len = uint(uint8(zip[i]) & 0x7F);

            if ((zip[i] & 0x80) == 0) {
                memcpy(data, index, zip, i, len);
                i += len;
            } else {
                memcpy(data, index, zeros, 0, len);
            }

            index += len;
        }

        require(index == totalLength, "Uncompress error");

        bool success;
        (success, result) = target.call.value(msg.value)(data);
        require(success, "Decompressed call failed");
    }

    function memcpy(
        bytes memory destMem,
        uint dest,
        bytes memory srcMem,
        uint src,
        uint len
    )
        private
        pure
    {
        assembly {
            dest := add(add(destMem, 32), dest)
            src := add(add(srcMem, 32), src)

            // Copy word-length chunks while possible
            for { } not(lt(len, 32)) { len := sub(len, 32) } { // (!<) is the same as (>=)
                mstore(dest, mload(src))
                dest := add(dest, 32)
                src := add(src, 32)
            }

            // Copy remaining bytes
            let mask := sub(shl(1, mul(8, sub(32, len))), 1) // 256**(32-len) == 1<<(8*(32-len))
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

}