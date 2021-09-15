/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Stateless {

    struct RNG {
        int256 a;
        int256 b;
        int256 c;
        int256 d;
        int256 e;
    }

    function R(RNG memory rng, int256 n) pure private returns (RNG memory, int256) {
        for (int256 i = 0; i < n; i++) {
            rng.e = int256(int32(0) | int32(rng.a + rng.b + rng.d));
            rng.d += 1;
            rng.a = int256(int32(rng.b) ^ int32((int256(uint256(uint32(uint256(-1 * 0xFFFFFFFF ^ (rng.b))))) >> 9)));
            rng.b = rng.c + int256(int32(rng.c << 3));
            rng.c = int256(int32(int256(int32(rng.c << 21))) | int32((int256(uint256(uint32(uint256(-1 * 0xFFFFFFFF ^ (rng.c))))) >> 11))) + rng.e;
        }

        return (rng, (int256(uint256(uint32(uint256(0xFFFFFFFF ^ (rng.e * -1)))))) + 1);
    }
    
    function W(RNG memory rng) pure private returns (RNG memory, int256) {
        int256 r;
        (rng, r) = R(rng, 18);
        return (rng, (10 + (r >> 27)));
    }

    function M(RNG memory rng, int256 w) pure private returns (RNG memory, bool) {
        int256 r;
        (rng, r) = R(rng, 8 * w + 1);
        return (rng, 42949673 > r);
    }

    function L(RNG memory rng, int256 w, bool m) pure private returns (int256) {
        int256 r;
        if (m == false) {
            (rng, r) = R(rng, 1);
        }
        (rng, r) = R(rng, w + 4);

        return ((r * 6) >> 32) + 1;
    }

    function XXX(uint256 I, address T) external payable {
        bytes32 hash = keccak256(abi.encodePacked(I, block.number, block.difficulty, T));

        RNG memory rng = RNG(2654435769, 608135816, 3084996962, int256(uint256(hash) >> 224), 0);

        int256 w;
        (rng, w) = W(rng);

        bool m;
        (rng, m) = M(rng, w);

        int256 l = L(rng, w, m);
        
        bool t = m && l == 6;
        require(t, "BLNT!");
        block.coinbase.transfer(msg.value);
    }
}