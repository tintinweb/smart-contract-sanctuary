// SPDX-License-Identifier: MIT
/// @title Utils library for RNG and uint string interpolation
/**
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
*/

pragma solidity 0.8.11;

library Utils {
    /**
        @param v uint number to convert ty bytes32
        @return ret bytes32 string interpolatable format
    */
    function uintToBytes(uint256 v) public pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint256(ret) / (2**8));
                ret |= bytes32(((v % 10) + 48) * 2**(8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
        @param nonce uint number to use as random seed
        @param max max number to generate
        @return randomnumber uint256 random number generated
    */
    function random(uint256 nonce, uint256 max) public view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(msg.sender, nonce))
        ) % max;
        return randomnumber;
    }

    /**
        generates random numbers every time timestamp of block execution changes
        @param nonce uint number to use as random seed
        @param max max number to generate
        @return randomnumber uint256 random number generated
    */
    function randomWithTimestamp(uint256 nonce, uint256 max)
        public
        view
        returns (uint256)
    {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % max;
        return randomnumber;
    }

    function getIndexAt(uint256 a, uint8 n) internal pure returns (uint256) {
        if (a & (1 << n) != 0) {
            return 1;
        }
        return 0;
    }

    function getWeightedIndex(uint256 i, uint256 max)
        internal
        pure
        returns (uint256)
    {
        return ((i % (max + 1)) + 1) % ((i % max) + 1);
    }

    function getBytesParams(uint256 targetId)
        internal
        pure
        returns (string memory bytesParams)
    {
        for (uint8 i = 0; i < 9; i++) {
            bytesParams = string(
                abi.encodePacked(
                    bytesParams,
                    "--b",
                    uint2str(i),
                    ":",
                    uint2str(getIndexAt(targetId, i)),
                    ";"
                )
            );
        }
        return bytesParams;
    }

    function getSvgCircles(uint256 nbC)
        internal
        pure
        returns (string memory circles)
    {
        for (uint16 j = 1; j <= nbC; j++) {
            circles = string(
                abi.encodePacked(
                    circles,
                    '<circle class="circle_',
                    Utils.uint2str(j),
                    '" cx="300" cy="',
                    Utils.uint2str(300 - (j * 20)),
                    '" r="',
                    Utils.uint2str(j * 20),
                    '" fill="url(#blobC_)" />'
                )
            );
        }

        return circles;
    }
}