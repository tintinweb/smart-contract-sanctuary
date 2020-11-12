pragma solidity ^0.5.2;


contract PrimeFieldElement6 {
    uint256 internal constant K_MODULUS = 0x30000003000000010000000000000001;
    uint256 internal constant K_MODULUS_MASK = 0x3fffffffffffffffffffffffffffffff;
    uint256 internal constant K_MONTGOMERY_R = 0xffffff0fffffffafffffffffffffffb;
    uint256 internal constant K_MONTGOMERY_R_INV = 0x9000001200000096000000600000001;
    uint256 internal constant GENERATOR_VAL = 3;
    uint256 internal constant ONE_VAL = 1;
    uint256 internal constant GEN1024_VAL = 0x2361be682e1cc2d366e86e194024739f;

    function fromMontgomery(uint256 val) internal pure returns (uint256 res) {
        // uint256 res = fmul(val, kMontgomeryRInv);
        assembly {
            res := mulmod(
                val,
                0x9000001200000096000000600000001,
                0x30000003000000010000000000000001
            )
        }
        return res;
    }

    function fromMontgomeryBytes(bytes32 bs) internal pure returns (uint256) {
        // Assuming bs is a 256bit bytes object, in Montgomery form, it is read into a field
        // element.
        uint256 res = uint256(bs);
        return fromMontgomery(res);
    }

    function toMontgomeryInt(uint256 val) internal pure returns (uint256 res) {
        //uint256 res = fmul(val, kMontgomeryR);
        assembly {
            res := mulmod(
                val,
                0xffffff0fffffffafffffffffffffffb,
                0x30000003000000010000000000000001
            )
        }
        return res;
    }

    function fmul(uint256 a, uint256 b) internal pure returns (uint256 res) {
        //uint256 res = mulmod(a, b, kModulus);
        assembly {
            res := mulmod(a, b, 0x30000003000000010000000000000001)
        }
        return res;
    }

    function fadd(uint256 a, uint256 b) internal pure returns (uint256 res) {
        // uint256 res = addmod(a, b, kModulus);
        assembly {
            res := addmod(a, b, 0x30000003000000010000000000000001)
        }
        return res;
    }

    function fsub(uint256 a, uint256 b) internal pure returns (uint256 res) {
        // uint256 res = addmod(a, kModulus - b, kModulus);
        assembly {
            res := addmod(
                a,
                sub(0x30000003000000010000000000000001, b),
                0x30000003000000010000000000000001
            )
        }
        return res;
    }

    function fpow(uint256 val, uint256 exp) internal returns (uint256) {
        return expmod(val, exp, K_MODULUS);
    }

    function expmod(uint256 base, uint256 exponent, uint256 modulus)
        internal
        returns (uint256 res)
    {
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20) // Length of Base.
            mstore(add(p, 0x20), 0x20) // Length of Exponent.
            mstore(add(p, 0x40), 0x20) // Length of Modulus.
            mstore(add(p, 0x60), base) // Base.
            mstore(add(p, 0x80), exponent) // Exponent.
            mstore(add(p, 0xa0), modulus) // Modulus.
            // Call modexp precompile.
            if iszero(call(not(0), 0x05, 0, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            res := mload(p)
        }
    }

    function inverse(uint256 val) internal returns (uint256) {
        return expmod(val, K_MODULUS - 2, K_MODULUS);
    }
}
