/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

contract PrimeFieldElement0 {
    uint256 constant internal K_MODULUS =
    0x800000000000011000000000000000000000000000000000000000000000001;
    uint256 constant internal K_MODULUS_MASK =
    0x0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant internal K_MONTGOMERY_R =
    0x7fffffffffffdf0ffffffffffffffffffffffffffffffffffffffffffffffe1;
    uint256 constant internal K_MONTGOMERY_R_INV =
    0x40000000000001100000000000012100000000000000000000000000000000;
    uint256 constant internal GENERATOR_VAL = 3;
    uint256 constant internal ONE_VAL = 1;
    uint256 constant internal GEN1024_VAL =
    0x659d83946a03edd72406af6711825f5653d9e35dc125289a206c054ec89c4f1;

    function fromMontgomery(uint256 val) internal pure returns (uint256 res) {
        // uint256 res = fmul(val, kMontgomeryRInv);
        assembly {
            res := mulmod(val,
                          0x40000000000001100000000000012100000000000000000000000000000000,
                          0x800000000000011000000000000000000000000000000000000000000000001)
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
            res := mulmod(val,
                          0x7fffffffffffdf0ffffffffffffffffffffffffffffffffffffffffffffffe1,
                          0x800000000000011000000000000000000000000000000000000000000000001)
        }
        return res;
    }

    function fmul(uint256 a, uint256 b) internal pure returns (uint256 res) {
        //uint256 res = mulmod(a, b, kModulus);
        assembly {
            res := mulmod(a, b,
                0x800000000000011000000000000000000000000000000000000000000000001)
        }
        return res;
    }

    function fadd(uint256 a, uint256 b) internal pure returns (uint256 res) {
        // uint256 res = addmod(a, b, kModulus);
        assembly {
            res := addmod(a, b,
                0x800000000000011000000000000000000000000000000000000000000000001)
        }
        return res;
    }

    function fsub(uint256 a, uint256 b) internal pure returns (uint256 res) {
        // uint256 res = addmod(a, kModulus - b, kModulus);
        assembly {
            res := addmod(
                a,
                sub(0x800000000000011000000000000000000000000000000000000000000000001, b),
                0x800000000000011000000000000000000000000000000000000000000000001)
        }
        return res;
    }

    function fpow(uint256 val, uint256 exp) internal view returns (uint256) {
        return expmod(val, exp, K_MODULUS);
    }

    function expmod(uint256 base, uint256 exponent, uint256 modulus)
        internal view returns (uint256 res)
    {
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20)                  // Length of Base.
            mstore(add(p, 0x20), 0x20)       // Length of Exponent.
            mstore(add(p, 0x40), 0x20)       // Length of Modulus.
            mstore(add(p, 0x60), base)       // Base.
            mstore(add(p, 0x80), exponent)   // Exponent.
            mstore(add(p, 0xa0), modulus)    // Modulus.
            // Call modexp precompile.
            if iszero(staticcall(gas, 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            res := mload(p)
        }
    }

    function inverse(uint256 val) internal view returns (uint256) {
        return expmod(val, K_MODULUS - 2, K_MODULUS);
    }
}
