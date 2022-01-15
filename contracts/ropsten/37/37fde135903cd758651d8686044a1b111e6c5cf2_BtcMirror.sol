// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./bitmath.sol";

contract BtcMirror {
    event NewTip(uint256 blockHeight, bytes32 blockHash);

    uint256 public latestBlockHeight;
    mapping(uint256 => bytes32) public blockHeightToHash;

    uint256 public expectedTarget =
        0x0000000000000000000B8C8B0000000000000000000000000000000000000000;

    constructor() {
        bytes32 blockHash = 0x00000000000000000003f89a3b5dcf3b71687462c1742ebd70eff229661e468a;
        blockHeightToHash[718114] = blockHash;
        latestBlockHeight = 718114;
    }

    // Returns the Bitcoin block hash at a specific height.
    function getBlockHash(uint256 number) public view returns (bytes32) {
        return blockHeightToHash[number];
    }

    // Returns the height of the last submitted canonical Bitcoin chain.
    function getLatestBlockHeight() public view returns (uint256) {
        return latestBlockHeight;
    }

    // Submits a new Bitcoin chain segment.
    function submit(uint256 blockHeight, bytes calldata blockHeaders) public {
        uint256 numHeaders = blockHeaders.length / 80;
        require(numHeaders * 80 == blockHeaders.length, "wrong header length");
        require(numHeaders > 0, "must submit at least one block");

        // check that we have a new longest chain
        // TODO: also check that we have a new heaviest chain
        // we reject retargets to <25% prev difficulty per protocol.
        // so an attacker would need >20% total BTC hashpower to fool
        // this contract into accepting an alternate chain.
        require(
            blockHeight + numHeaders > latestBlockHeight,
            "chain segment too short"
        );

        for (uint256 i = 0; i < numHeaders; i++) {
            submitBlock(blockHeight + i, blockHeaders[80 * i:80 * (i + 1)]);
        }

        latestBlockHeight = blockHeight;
        emit NewTip(latestBlockHeight, getBlockHash(latestBlockHeight));
    }

    function submitBlock(uint256 blockHeight, bytes calldata blockHeader)
        private
    {
        assert(blockHeader.length == 80);

        bytes32 prevHash = bytes32(
            reverseBytes(uint256(bytes32(blockHeader[4:36])))
        );
        require(prevHash == blockHeightToHash[blockHeight - 1], "bad parent");

        uint256 blockHashNum = reverseBytes(
            uint256(sha256(abi.encode(sha256(blockHeader))))
        );

        // verify proof-of-work
        bytes32 bits = bytes32(blockHeader[72:76]);
        uint256 target = getTarget(bits);
        require(blockHashNum < target, "block hash above target");

        // support once-every-2016-blocks retargeting
        if (blockHeight % 2016 == 0) {
            require(target >> 2 < expectedTarget, "<25% difficulty retarget");
            expectedTarget = target;
        } else {
            require(target == expectedTarget, "wrong difficulty bits");
        }

        blockHeightToHash[blockHeight] = bytes32(blockHashNum);
    }

    function getTarget(bytes32 bits) public pure returns (uint256) {
        uint256 exp = uint8(bits[3]);
        uint256 mantissa = uint8(bits[2]);
        mantissa = (mantissa << 8) | uint8(bits[1]);
        mantissa = (mantissa << 8) | uint8(bits[0]);
        uint256 target = mantissa << (8 * (exp - 3));
        return target;
    }

    function reverseBytes(uint256 v) public pure returns (uint256) {
        // swap bytes
        uint256 b1 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
        v = ((v & b1) >> 8) | ((v & ~b1) << 8);

        // swap 2-byte long pairs
        uint256 b2 = 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000;
        v = ((v & b2) >> 16) | ((v & ~b2) << 16);

        // swap 4-byte long pairs
        uint256 b4 = 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000;
        v = ((v & b4) >> 32) | ((v & ~b4) << 32);

        // swap 8-byte long pairs
        uint256 b8 = 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000;
        v = ((v & b8) >> 64) | ((v & ~b8) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);

        return v;
    }

    function hashBlock(bytes calldata blockHeader)
        public
        pure
        returns (bytes32)
    {
        require(blockHeader.length == 80);
        require(abi.encodePacked(sha256(blockHeader)).length == 32);
        bytes32 blockHash = sha256(abi.encodePacked(sha256(blockHeader)));
        return blockHash;
    }
}