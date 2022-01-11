// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Library for Merkle proofs
pragma solidity ^0.8.0;

import "./CartesiMath.sol";

library Merkle {
    using CartesiMath for uint256;

    uint128 constant L_WORD_SIZE = 3; // word = 8 bytes, log = 3
    // number of hashes in EMPTY_TREE_HASHES
    uint128 constant EMPTY_TREE_SIZE = 1952; // 61*32=1952. 32 bytes per 61 indexes (64 words)

    // merkle root hashes of trees of zero concatenated
    // 32 bytes for each root, first one is keccak(0), second one is
    // keccak(keccack(0), keccak(0)) and so on

    bytes constant EMPTY_TREE_HASHES =
        hex"011b4d03dd8c01f1049143cf9c4c817e4b167f1d1b83e5c6f0f10d89ba1e7bce4d9470a821fbe90117ec357e30bad9305732fb19ddf54a07dd3e29f440619254ae39ce8537aca75e2eff3e38c98011dfe934e700a0967732fc07b430dd656a233fc9a15f5b4869c872f81087bb6104b7d63e6f9ab47f2c43f3535eae7172aa7f17d2dd614cddaa4d879276b11e0672c9560033d3e8453a1d045339d34ba601b9c37b8b13ca95166fb7af16988a70fcc90f38bf9126fd833da710a47fb37a55e68e7a427fa943d9966b389f4f257173676090c6e95f43e2cb6d65f8758111e30930b0b9deb73e155c59740bacf14a6ff04b64bb8e201a506409c3fe381ca4ea90cd5deac729d0fdaccc441d09d7325f41586ba13c801b7eccae0f95d8f3933efed8b96e5b7f6f459e9cb6a2f41bf276c7b85c10cd4662c04cbbb365434726c0a0c9695393027fb106a8153109ac516288a88b28a93817899460d6310b71cf1e6163e8806fa0d4b197a259e8c3ac28864268159d0ac85f8581ca28fa7d2c0c03eb91e3eee5ca7a3da2b3053c9770db73599fb149f620e3facef95e947c0ee860b72122e31e4bbd2b7c783d79cc30f60c6238651da7f0726f767d22747264fdb046f7549f26cc70ed5e18baeb6c81bb0625cb95bb4019aeecd40774ee87ae29ec517a71f6ee264c5d761379b3d7d617ca83677374b49d10aec50505ac087408ca892b573c267a712a52e1d06421fe276a03efb1889f337201110fdc32a81f8e152499af665835aabfdc6740c7e2c3791a31c3cdc9f5ab962f681b12fc092816a62f27d86025599a41233848702f0cfc0437b445682df51147a632a0a083d2d38b5e13e466a8935afff58bb533b3ef5d27fba63ee6b0fd9e67ff20af9d50deee3f8bf065ec220c1fd4ba57e341261d55997f85d66d32152526736872693d2b437a233e2337b715f6ac9a6a272622fdc2d67fcfe1da3459f8dab4ed7e40a657a54c36766c5e8ac9a88b35b05c34747e6507f6b044ab66180dc76ac1a696de03189593fedc0d0dbbd855c8ead673544899b0960e4a5a7ca43b4ef90afe607de7698caefdc242788f654b57a4fb32a71b335ef6ff9a4cc118b282b53bdd6d6192b7a82c3c5126b9c7e33c8e5a5ac9738b8bd31247fb7402054f97b573e8abb9faad219f4fd085aceaa7f542d787ee4196d365f3cc566e7bbcfbfd451230c48d804c017d21e2d8fa914e2559bb72bf0ab78c8ab92f00ef0d0d576eccdd486b64138a4172674857e543d1d5b639058dd908186597e366ad5f3d9c7ceaff44d04d1550b8d33abc751df07437834ba5acb32328a396994aebb3c40f759c2d6d7a3cb5377e55d5d218ef5a296dda8ddc355f3f50c3d0b660a51dfa4d98a6a5a33564556cf83c1373a814641d6a1dcef97b883fee61bb84fe60a3409340217e629cc7e4dcc93b85d8820921ff5826148b60e6939acd7838e1d7f20562bff8ee4b5ec4a05ad997a57b9796fdcb2eda87883c2640b072b140b946bfdf6575cacc066fdae04f6951e63624cbd316a677cad529bbe4e97b9144e4bc06c4afd1de55dd3e1175f90423847a230d34dfb71ed56f2965a7f6c72e6aa33c24c303fd67745d632656c5ef90bec80f4f5d1daa251988826cef375c81c36bf457e09687056f924677cb0bccf98dff81e014ce25f2d132497923e267363963cdf4302c5049d63131dc03fd95f65d8b6aa5934f817252c028c90f56d413b9d5d10d89790707dae2fabb249f649929927c21dd71e3f656826de5451c5da375aadecbd59d5ebf3a31fae65ac1b316a1611f1b276b26530f58d7247df459ce1f86db1d734f6f811932f042cee45d0e455306d01081bc3384f82c5fb2aacaa19d89cdfa46cc916eac61121475ba2e6191b4feecbe1789717021a158ace5d06744b40f551076b67cd63af60007f8c99876e1424883a45ec49d497ddaf808a5521ca74a999ab0b3c7aa9c80f85e93977ec61ce68b20307a1a81f71ca645b568fcd319ccbb5f651e87b707d37c39e15f945ea69e2f7c7d2ccc85b7e654c07e96f0636ae4044fe0e38590b431795ad0f8647bdd613713ada493cc17efd313206380e6a685b8198475bbd021c6e9d94daab2214947127506073e44d5408ba166c512a0b86805d07f5a44d3c41706be2bc15e712e55805248b92e8677d90f6d284d1d6ffaff2c430657042a0e82624fa3717b06cc0a6fd12230ea586dae83019fb9e06034ed2803c98d554b93c9a52348cafff75c40174a91f9ae6b8647854a156029f0b88b83316663ce574a4978277bb6bb27a31085634b6ec78864b6d8201c7e93903d75815067e378289a3d072ae172dafa6a452470f8d645bebfad9779594fc0784bb764a22e3a8181d93db7bf97893c414217a618ccb14caa9e92e8c61673afc9583662e812adba1f87a9c68202d60e909efab43c42c0cb00695fc7f1ffe67c75ca894c3c51e1e5e731360199e600f6ced9a87b2a6a87e70bf251bb5075ab222138288164b2eda727515ea7de12e2496d4fe42ea8d1a120c03cf9c50622c2afe4acb0dad98fd62d07ab4e828a94495f6d1ab973982c7ccbe6c1fae02788e4422ae22282fa49cbdb04ba54a7a238c6fc41187451383460762c06d1c8a72b9cd718866ad4b689e10c9a8c38fe5ef045bd785b01e980fc82c7e3532ce81876b778dd9f1ceeba4478e86411fb6fdd790683916ca832592485093644e8760cd7b4c01dba1ccc82b661bf13f0e3f34acd6b88";

    /// @notice Gets merkle root hash of drive with a replacement
    /// @param _position position of _drive
    /// @param _logSizeOfReplacement log2 of size the replacement
    /// @param _logSizeOfFullDrive log2 of size the full drive, which can be the entire machine
    /// @param _replacement hash of the replacement
    /// @param siblings of replacement that merkle root can be calculated
    function getRootAfterReplacementInDrive(
        uint256 _position,
        uint256 _logSizeOfReplacement,
        uint256 _logSizeOfFullDrive,
        bytes32 _replacement,
        bytes32[] calldata siblings
    ) public pure returns (bytes32) {
        require(
            _logSizeOfFullDrive >= _logSizeOfReplacement &&
                _logSizeOfReplacement >= 3 &&
                _logSizeOfFullDrive <= 64,
            "3 <= logSizeOfReplacement <= logSizeOfFullDrive <= 64"
        );

        uint256 size = 1 << _logSizeOfReplacement;

        require(((size - 1) & _position) == 0, "Position is not aligned");
        require(
            siblings.length == _logSizeOfFullDrive - _logSizeOfReplacement,
            "Proof length does not match"
        );

        for (uint256 i; i < siblings.length; i++) {
            if ((_position & (size << i)) == 0) {
                _replacement = keccak256(
                    abi.encodePacked(_replacement, siblings[i])
                );
            } else {
                _replacement = keccak256(
                    abi.encodePacked(siblings[i], _replacement)
                );
            }
        }

        return _replacement;
    }

    /// @notice Gets precomputed hash of zero in empty tree hashes
    /// @param _index of hash wanted
    /// @dev first index is keccak(0), second index is keccak(keccak(0), keccak(0))
    function getEmptyTreeHashAtIndex(uint256 _index)
        public
        pure
        returns (bytes32)
    {
        uint256 start = _index * 32;
        require(EMPTY_TREE_SIZE >= start + 32, "index out of bounds");
        bytes32 hashedZeros;
        bytes memory zeroTree = EMPTY_TREE_HASHES;

        // first word is length, then skip index words
        assembly {
            hashedZeros := mload(add(add(zeroTree, 0x20), start))
        }
        return hashedZeros;
    }

    /// @notice get merkle root of generic array of bytes
    /// @param _data array of bytes to be merklelized
    /// @param _log2Size log2 of total size of the drive
    /// @dev _data is padded with zeroes until is multiple of 8
    /// @dev root is completed with zero tree until log2size is complete
    /// @dev hashes are taken word by word (8 bytes by 8 bytes)
    function getMerkleRootFromBytes(bytes calldata _data, uint256 _log2Size)
        public
        pure
        returns (bytes32)
    {
        require(_log2Size >= 3 && _log2Size <= 64, "range of log2Size: [3,64]");

        // if _data is empty return pristine drive of size log2size
        if (_data.length == 0) return getEmptyTreeHashAtIndex(_log2Size - 3);

        // total size of the drive in words
        uint256 size = 1 << (_log2Size - 3);
        require(
            size << L_WORD_SIZE >= _data.length,
            "data is bigger than drive"
        );
        // the stack depth is log2(_data.length / 8) + 2
        uint256 stack_depth = 2 +
            ((_data.length) >> L_WORD_SIZE).getLog2Floor();
        bytes32[] memory stack = new bytes32[](stack_depth);

        uint256 numOfHashes; // total number of hashes on stack (counting levels)
        uint256 stackLength; // total length of stack
        uint256 numOfJoins; // number of hashes of the same level on stack
        uint256 topStackLevel; // hash level of the top of the stack

        while (numOfHashes < size) {
            if ((numOfHashes << L_WORD_SIZE) < _data.length) {
                // we still have words to hash
                stack[stackLength] = getHashOfWordAtIndex(_data, numOfHashes);
                numOfHashes++;

                numOfJoins = numOfHashes;
            } else {
                // since padding happens in hashOfWordAtIndex function
                // we only need to complete the stack with pre-computed
                // hash(0), hash(hash(0),hash(0)) and so on
                topStackLevel = numOfHashes.ctz();

                stack[stackLength] = getEmptyTreeHashAtIndex(topStackLevel);

                //Empty Tree Hash summarizes many hashes
                numOfHashes = numOfHashes + (1 << topStackLevel);
                numOfJoins = numOfHashes >> topStackLevel;
            }

            stackLength++;

            // while there are joins, hash top of stack together
            while (numOfJoins & 1 == 0) {
                bytes32 h2 = stack[stackLength - 1];
                bytes32 h1 = stack[stackLength - 2];

                stack[stackLength - 2] = keccak256(abi.encodePacked(h1, h2));
                stackLength = stackLength - 1; // remove hashes from stack

                numOfJoins = numOfJoins >> 1;
            }
        }
        require(stackLength == 1, "stack error");

        return stack[0];
    }

    /// @notice Get the hash of a word in an array of bytes
    /// @param _data array of bytes
    /// @param _wordIndex index of word inside the bytes to get the hash of
    /// @dev if word is incomplete (< 8 bytes) it gets padded with zeroes
    function getHashOfWordAtIndex(bytes calldata _data, uint256 _wordIndex)
        public
        pure
        returns (bytes32)
    {
        uint256 start = _wordIndex << L_WORD_SIZE;
        uint256 end = start + (1 << L_WORD_SIZE);

        // TODO: in .lua this just returns zero, but this might be more consistent
        require(start <= _data.length, "word out of bounds");

        if (end <= _data.length) {
            return keccak256(abi.encodePacked(_data[start:end]));
        }

        // word is incomplete
        // fill paddedSlice with incomplete words - the rest is going to be bytes(0)
        bytes memory paddedSlice = new bytes(8);
        uint256 remaining = _data.length - start;

        for (uint256 i; i < remaining; i++) {
            paddedSlice[i] = _data[start + i];
        }

        return keccak256(paddedSlice);
    }

    /// @notice Calculate the root of Merkle tree from an array of power of 2 elements
    /// @param hashes The array containing power of 2 elements
    /// @return byte32 the root hash being calculated
    function calculateRootFromPowerOfTwo(bytes32[] memory hashes)
        public
        pure
        returns (bytes32)
    {
        // revert when the input is not of power of 2
        require((hashes.length).isPowerOf2(), "array len not power of 2");

        if (hashes.length == 1) {
            return hashes[0];
        } else {
            bytes32[] memory newHashes = new bytes32[](hashes.length >> 1);

            for (uint256 i; i < hashes.length; i += 2) {
                newHashes[i >> 1] = keccak256(
                    abi.encodePacked(hashes[i], hashes[i + 1])
                );
            }

            return calculateRootFromPowerOfTwo(newHashes);
        }
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CartesiMath
/// @author Felipe Argento
pragma solidity ^0.8.0;

library CartesiMath {
    // mapping values are packed as bytes3 each
    // see test/TestCartesiMath.ts for decimal values
    bytes constant log2tableTimes1M =
        hex"0000000F4240182F421E8480236E082771822AD63A2DC6C0305E8532B04834C96736B3C23876D73A187A3B9D4A3D09003E5EA63FA0C540D17741F28843057D440BA745062945F60246DC1047B917488DC7495ABA4A207C4ADF8A4B98544C4B404CF8AA4DA0E64E44434EE3054F7D6D5013B750A61A5134C851BFF05247BD52CC58534DE753CC8D54486954C19C55384255AC75561E50568DE956FB575766B057D00758376F589CFA5900BA5962BC59C3135A21CA5A7EF15ADA945B34BF5B8D805BE4DF5C3AEA5C8FA95CE3265D356C5D86835DD6735E25455E73005EBFAD5F0B525F55F75F9FA25FE85A60302460770860BD0A61023061467F6189FD61CCAE620E98624FBF62902762CFD5630ECD634D12638AA963C7966403DC643F7F647A8264B4E864EEB56527EC6560906598A365D029660724663D9766738566A8F066DDDA6712476746386779AF67ACAF67DF3A6811526842FA68743268A4FC68D55C6905536934E169640A6992CF69C13169EF326A1CD46A4A186A76FF6AA38C6ACFC0";

    /// @notice Approximates log2 * 1M
    /// @param _num number to take log2 * 1M of
    /// @return approximate log2 times 1M
    function log2ApproxTimes1M(uint256 _num) public pure returns (uint256) {
        require(_num > 0, "Number cannot be zero");
        uint256 leading = 0;

        if (_num == 1) return 0;

        while (_num > 128) {
            _num = _num >> 1;
            leading += 1;
        }
        return (leading * uint256(1000000)) + (getLog2TableTimes1M(_num));
    }

    /// @notice navigates log2tableTimes1M
    /// @param _num number to take log2 of
    /// @return result after table look-up
    function getLog2TableTimes1M(uint256 _num) public pure returns (uint256) {
        bytes3 result = 0;
        for (uint8 i = 0; i < 3; i++) {
            bytes3 tempResult = log2tableTimes1M[(_num - 1) * 3 + i];
            result = result | (tempResult >> (i * 8));
        }

        return uint256(uint24(result));
    }

    /// @notice get floor of log2 of number
    /// @param _num number to take floor(log2) of
    /// @return floor(log2) of _num
   function getLog2Floor(uint256 _num) public pure returns (uint8) {
       require(_num != 0, "log of zero is undefined");

       return uint8(255 - clz(_num));
    }

    /// @notice checks if a number is Power of 2
    /// @param _num number to check
    /// @return true if number is power of 2, false if not
    function isPowerOf2(uint256 _num) public pure returns (bool) {
        if (_num == 0) return false;

        return _num & (_num - 1) == 0;
    }

    /// @notice count trailing zeros
    /// @param _num number you want the ctz of
    /// @dev this a binary search implementation
    function ctz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) { n = n + 128; _num = _num >> 128; }
        if (_num & 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF == 0) { n = n + 64; _num = _num >> 64; }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF == 0) { n = n + 32; _num = _num >> 32; }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000FFFF == 0) { n = n + 16; _num = _num >> 16; }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000000000FF == 0) { n = n +  8; _num = _num >>  8; }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000000F == 0) { n = n +  4; _num = _num >>  4; }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000003 == 0) { n = n +  2; _num = _num >>  2; }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000001 == 0) { n = n +  1; }

        return n;
    }

    /// @notice count leading zeros
    /// @param _num number you want the clz of
    /// @dev this a binary search implementation
    function clz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 == 0) { n = n + 128; _num = _num << 128; }
        if (_num & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 == 0) { n = n + 64; _num = _num << 64; }
        if (_num & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 == 0) { n = n + 32; _num = _num << 32; }
        if (_num & 0xFFFF000000000000000000000000000000000000000000000000000000000000 == 0) { n = n + 16; _num = _num << 16; }
        if (_num & 0xFF00000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  8; _num = _num <<  8; }
        if (_num & 0xF000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  4; _num = _num <<  4; }
        if (_num & 0xC000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  2; _num = _num <<  2; }
        if (_num & 0x8000000000000000000000000000000000000000000000000000000000000000 == 0) { n = n +  1; }

        return n;
    }
}