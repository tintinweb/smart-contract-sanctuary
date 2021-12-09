// SPDX-License-Identifier: UNLICENCED
// Implementation Copyright 2021, the author; All rights reserved
//
// This contract is an on-chain implementation of a concept created and
// developed by John F Simon Jr in partnership with e•a•t•works and
// @fingerprintsDAO
pragma solidity 0.8.10;

import "./IEveryIconRepository.sol";
import "@divergencetech/ethier/contracts/random/PRNG.sol";
import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Every Icon library
/// @author @divergenceharri (@divergence_art)
library EveryIconLib {
    using DynamicBuffer for bytes;
    using PRNG for PRNG.Source;
    using Strings for uint256;

    /// @dev A set of contracts containing base icons from which designs are
    /// built. Each MUST hold exactly 32 icons, with the first 104 being
    /// "design" icons and the next 28 being the "random" ones.
    struct Repository {
        IEveryIconRepository[4] icons;
    }

    /// @notice Returns the i'th "design" icon from the Repository.
    function designIcon(Repository storage repo, uint256 i)
        internal
        view
        returns (uint256[4] memory)
    {
        require(i < 100, "Invalid design icon");
        return repo.icons[i / 32].icon(i % 32);
    }

    /// @notice Returns the i'th "random" icon from the Repository.
    function randomIcon(Repository storage repo, uint256 i)
        internal
        view
        returns (uint256[4] memory)
    {
        require(i < 28, "Invalid random icon");
        return repo.icons[3].icon(i + 4);
    }

    /// @dev Masks the block in which an icon was minted to encode it in the
    /// bottom row of the image.
    uint256 internal constant MINTING_BLOCK_MASK = 2**32 - 1;

    /// @notice Constructs icon from parameters, returning a buffer of 1024 bits
    function startingBits(
        Repository storage repo,
        Token memory token,
        uint256 mintingBlock,
        uint256 ticks
    ) internal view returns (uint256[4] memory) {
        uint256[4] memory di0 = designIcon(repo, token.designIcon0);
        uint256[4] memory di1 = designIcon(repo, token.designIcon1);
        uint256[4] memory ri = randomIcon(repo, token.randIcon);
        uint256[4] memory icon;

        // Start by combining inputs to get the base token
        //
        // The original JavaScript piece, which this contract mimics, inverts
        // bits for the 'ticking' of the icons. It's easier to correct for this
        // by inverting all of the incoming values and performing inverted
        // bitwise operations here, hence the ~((~x & ~y) | ~z) patterns.
        if (token.combMethod == 0) {
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = ~((~di0[i] & ~di1[i]) | ~ri[i]);
            }
        } else if (token.combMethod == 1) {
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = ~((~di0[i] & ~di1[i]) ^ ~ri[i]);
            }
        } else if (token.combMethod == 2) {
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = ~((~di0[i] | ~di1[i]) ^ ~ri[i]);
            }
        } else {
            // Although this won't be exposed to collectors, it allows for
            // testing of individual base icons via a different, inheriting
            // contract.
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = di0[i];
            }
        }

        // After combining icons, we clear the last row of the image and replace
        // it with a big-endian representation of the block number in which the
        // token was minted. We chose big-endian representation (in contrast to
        // 'ticks') to remain consistent with Solidity's handling of integers
        mintingBlock = mintingBlock & MINTING_BLOCK_MASK;
        icon[3] = (icon[3] & (~MINTING_BLOCK_MASK)) | mintingBlock;

        // Finally, we add 'ticks'. For a starting icon this will be equal to
        // zero, but the 'peekSVG' function is designed to see how far the icon
        // would have got based on the assumed iteration rate of 100 ticks per
        // second.
        //
        // This step is complicated by the fact that the icon animation is
        // effectively little-endian. We therefore need to increment from the
        // highest bit down.
        unchecked {
            // Although all values only ever contain a single bit, they're
            // defined as uint256 instead of bool to shift without the need for
            // casting.
            uint256 a;
            uint256 b;
            uint256 sum; // a+b
            uint256 carry;
            uint256 mask;

            // Breaking the loop based on a lack of further carry (instead of
            // only looping over each word once) allows for overflow should the
            // icon reach the end. This will never happen (see [1] for an
            // interesting explanation!), but conceptually it is a core part of
            // the artwork – otherwise it would be impossible for "every" icon
            // to be generated!
            //
            // [1] Schneider B. Applied Cryptography: Protocols, Algorithms, and
            //     Source Code in C; pp. 157–8.
            for (uint256 i = 0; ticks + carry > 0; i = (i + 1) % 4) {
                mask = 1 << 255;
                for (uint256 j = 0; j < 256 && ticks + carry > 0; j++) {
                    a = ticks & 1;
                    b = (icon[i] >> (255 - j)) & 1;
                    sum = a ^ b ^ carry;
                    icon[i] = (icon[i] & ~mask) | (sum << (255 - j));

                    carry = a + b + carry >= 2 ? 1 : 0;
                    ticks >>= 1;
                    mask >>= 1;
                }
            }
        }

        return icon;
    }

    /// @notice Metadata defining a token's icon.
    struct Token {
        uint8 designIcon0;
        uint8 designIcon1;
        uint8 randIcon;
        uint8 combMethod;
    }

    /// @notice Returns a static SVG from a 1024-bit buffer. This is used for thumbnails
    /// and in the OpenSea listing, before the viewer clicks into the animated version of
    /// a piece.
    function renderSVG(uint256[4] memory icon)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory svg = DynamicBuffer.allocate(2**16); // 64KB
        svg.appendSafe(
            abi.encodePacked(
                "<svg width='512' height='512' xmlns='http://www.w3.org/2000/svg'>",
                "<style>",
                "rect{width:16px;height:16px;stroke-width:1px;stroke:#c4c4c4}",
                ".b{fill:#000}",
                ".w{fill:#fff}",
                "</style>"
            )
        );

        uint256 x;
        uint256 y;
        bool bit;
        for (uint256 i = 0; i < 1024; i++) {
            x = (i % 32) * 16;
            y = (i / 32) * 16;
            bit = (icon[i / 256] >> (255 - (i % 256))) & 1 == 1;

            svg.appendSafe(
                abi.encodePacked(
                    "<rect x='",
                    x.toString(),
                    "' y='",
                    y.toString(),
                    "' class='",
                    bit ? "b" : "w",
                    "'/>"
                )
            );
        }

        svg.appendSafe("</svg>");
        return svg;
    }

    /// @notice Returns a random Token for an NFT which has not had its icon set
    /// by the cut-off point. Deterministically seeded from tokenId and
    /// mintingBlock.
    function randomToken(uint256 tokenId, uint256 mintingBlock)
        public
        pure
        returns (Token memory)
    {
        PRNG.Source src = PRNG.newSource(
            keccak256(abi.encodePacked(tokenId, mintingBlock))
        );

        return
            EveryIconLib.Token({
                designIcon0: uint8(src.readLessThan(100)),
                designIcon1: uint8(src.readLessThan(100)),
                randIcon: uint8(src.readLessThan(28)),
                combMethod: uint8(src.readLessThan(3))
            });
    }
}

// SPDX-License-Identifier: UNLICENCED
// Copyright 2021; All rights reserved
// Author: @divergenceharri (@divergence_art)

pragma solidity >=0.8.9 <0.9.0;

/// @title Every Icon Contract (Repository Interface)
/// @notice A common interface for the 4 Every Icon repositories.
interface IEveryIconRepository {
    function icon(uint256) external view returns (uint256[4] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.9 <0.9.0;

library PRNG {
    /**
    @notice A source of random numbers.
    @dev Pointer to a 4-word buffer of {seed, counter, entropy, remaining unread
    bits}. however, note that this is abstracted away by the API and SHOULD NOT
    be used. This layout MUST NOT be considered part of the public API and
    therefore not relied upon even within stable versions
     */
    type Source is uint256;

    /// @notice Layout within the buffer. 0x00 is the seed.
    uint256 private constant COUNTER = 0x20;
    uint256 private constant ENTROPY = 0x40;
    uint256 private constant REMAIN = 0x60;

    /**
    @notice Returns a new deterministic Source, differentiated only by the seed.
    @dev Use of PRNG.Source does NOT provide any unpredictability as generated
    numbers are entirely deterministic. Either a verifiable source of randomness
    such as Chainlink VRF, or a commit-and-reveal protocol MUST be used if
    unpredictability is required. The latter is only appropriate if the contract
    owner can be trusted within the specified threat model.
     */
    function newSource(bytes32 seed) internal pure returns (Source src) {
        assembly {
            src := mload(0x40)
            mstore(0x40, add(src, 0x80))
            mstore(src, seed)
        }
        // DO NOT call _refill() on the new Source as newSource() is also used
        // by loadSource(), which implements its own state modifications. The
        // first call to read() on a fresh Source will induce a call to
        // _refill().
    }

    /**
    @dev Hashes seed||counter, placing it in the entropy word, and resets the
    remaining bits to 256. Increments the counter BEFORE the refill (ie 0 is
    never used) as this simplifies round-tripping with store() and loadSource()
    because the stored counter state is the same as the one used for deriving
    the entropy pool.
     */
    function _refill(Source src) private pure {
        assembly {
            let ctr := add(src, COUNTER)
            mstore(ctr, add(1, mload(ctr)))
            mstore(add(src, ENTROPY), keccak256(src, 0x40))
            mstore(add(src, REMAIN), 256)
        }
    }

    /**
    @notice Returns the specified number of bits <= 256 from the Source.
    @dev It is safe to cast the returned value to a uint<bits>.
     */
    function read(Source src, uint256 bits)
        internal
        pure
        returns (uint256 sample)
    {
        require(bits <= 256, "PRNG: max 256 bits");

        uint256 remain;
        assembly {
            remain := mload(add(src, REMAIN))
        }
        if (remain > bits) {
            return readWithSufficient(src, bits);
        }

        uint256 extra = bits - remain;
        sample = readWithSufficient(src, remain);
        assembly {
            sample := shl(extra, sample)
        }

        _refill(src);
        sample = sample | readWithSufficient(src, extra);
    }

    /**
    @notice Returns the specified number of bits, assuming that there is
    sufficient entropy remaining. See read() for usage.
     */
    function readWithSufficient(Source src, uint256 bits)
        private
        pure
        returns (uint256 sample)
    {
        assembly {
            let pool := add(src, ENTROPY)
            let ent := mload(pool)
            sample := and(ent, sub(shl(bits, 1), 1))

            mstore(pool, shr(bits, ent))
            let rem := add(src, REMAIN)
            mstore(rem, sub(mload(rem), bits))
        }
    }

    /// @notice Returns a random boolean.
    function readBool(Source src) internal pure returns (bool) {
        return read(src, 1) == 1;
    }

    /**
    @notice Returns the number of bits needed to encode n.
    @dev Useful for calling readLessThan() multiple times with the same upper
    bound.
     */
    function bitLength(uint256 n) internal pure returns (uint16 bits) {
        assembly {
            for {
                let _n := n
            } gt(_n, 0) {
                _n := shr(1, _n)
            } {
                bits := add(bits, 1)
            }
        }
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling.
    @dev If the size of n is known, prefer readLessThan(Source, uint, uint16) as
    it skips the bit counting performed by this version; see bitLength().
     */
    function readLessThan(Source src, uint256 n)
        internal
        pure
        returns (uint256)
    {
        return readLessThan(src, n, bitLength(n));
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling
    from the range [0,2^bits).
    @dev For greatest efficiency, the value of bits should be the smallest
    number of bits required to capture n; if this is not known, use
    readLessThan(Source, uint) or bitLength(). Although rejections are reduced
    by using twice the number of bits, this increases the rate at which the
    entropy pool must be refreshed with a call to keccak256().

    TODO: benchmark higher number of bits for rejection vs hashing gas cost.
     */
    function readLessThan(
        Source src,
        uint256 n,
        uint16 bits
    ) internal pure returns (uint256 result) {
        // Discard results >= n and try again because using % will bias towards
        // lower values; e.g. if n = 13 and we read 4 bits then {13, 14, 15}%13
        // will select {0, 1, 2} twice as often as the other values.
        for (result = n; result >= n; result = read(src, bits)) {}
    }

    /**
    @notice Returns the internal state of the Source.
    @dev MUST NOT be considered part of the API and is subject to change without
    deprecation nor warning. Only exposed for testing.
     */
    function state(Source src)
        internal
        pure
        returns (
            uint256 seed,
            uint256 counter,
            uint256 entropy,
            uint256 remain
        )
    {
        assembly {
            seed := mload(src)
            counter := mload(add(src, COUNTER))
            entropy := mload(add(src, ENTROPY))
            remain := mload(add(src, REMAIN))
        }
    }

    /**
    @notice Stores the state of the Source in a 2-word buffer. See loadSource().
    @dev The layout of the stored state MUST NOT be considered part of the
    public API, and is subject to change without warning. It is therefore only
    safe to rely on stored Sources _within_ contracts, but not _between_ them.
     */
    function store(Source src, uint256[2] storage stored) internal {
        uint256 seed;
        // Counter will never be as high as 2^247 (because the sun will have
        // depleted by then) and remain is in [0,256], so pack them to save 20k
        // gas on an SSTORE.
        uint256 packed;
        assembly {
            seed := mload(src)
            packed := add(
                shl(9, mload(add(src, COUNTER))),
                mload(add(src, REMAIN))
            )
        }
        stored[0] = seed;
        stored[1] = packed;
        // Not storing the entropy as it can be recalculated later.
    }

    /**
    @notice Recreates a Source from the state stored with store().
     */
    function loadSource(uint256[2] storage stored)
        internal
        view
        returns (Source)
    {
        Source src = newSource(bytes32(stored[0]));
        uint256 packed = stored[1];
        uint256 counter = packed >> 9;
        uint256 remain = packed & 511;

        assembly {
            mstore(add(src, COUNTER), counter)
            mstore(add(src, REMAIN), remain)

            // Has the same effect on internal state as as _refill() then
            // read(256-rem).
            let ent := shr(sub(256, remain), keccak256(src, 0x40))
            mstore(add(src, ENTROPY), ent)
        }
        return src;
    }
}