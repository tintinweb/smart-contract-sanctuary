pragma solidity ^0.5.2;

import "./PrimeFieldElement6.sol";

contract HornerEvaluator is PrimeFieldElement6 {
    /*
      Computes the evaluation of a polynomial f(x) = sum(a_i * x^i) on the given point.
      The coefficients of the polynomial are given in
        a_0 = coefsStart[0], ..., a_{n-1} = coefsStart[n - 1]
      where n = nCoefs = friLastLayerDegBound. Note that coefsStart is not actually an array but
      a direct pointer.
      The function requires that n is divisible by 8.
    */
    function hornerEval(uint256 coefsStart, uint256 point, uint256 nCoefs)
        internal pure
        returns (uint256) {
        uint256 result = 0;
        uint256 prime = PrimeFieldElement6.K_MODULUS;

        require(nCoefs % 8 == 0, "Number of polynomial coefficients must be divisible by 8");
        require(nCoefs < 4096, "No more than 4096 coefficients are supported");

        assembly {
            let coefsPtr := add(coefsStart, mul(nCoefs, 0x20))
            for { } gt(coefsPtr, coefsStart) { } {
                // Reduce coefsPtr by 8 field elements.
                coefsPtr := sub(coefsPtr, 0x100)

                // Apply 4 Horner steps (result := result * point + coef).
                result :=
                    add(mload(add(coefsPtr, 0x80)), mulmod(
                    add(mload(add(coefsPtr, 0xa0)), mulmod(
                    add(mload(add(coefsPtr, 0xc0)), mulmod(
                    add(mload(add(coefsPtr, 0xe0)), mulmod(
                        result,
                    point, prime)),
                    point, prime)),
                    point, prime)),
                    point, prime))

                // Apply 4 additional Horner steps.
                result :=
                    add(mload(coefsPtr), mulmod(
                    add(mload(add(coefsPtr, 0x20)), mulmod(
                    add(mload(add(coefsPtr, 0x40)), mulmod(
                    add(mload(add(coefsPtr, 0x60)), mulmod(
                        result,
                    point, prime)),
                    point, prime)),
                    point, prime)),
                    point, prime))
            }
        }

        // Since the last operation was "add" (instead of "addmod"), we need to take result % prime.
        return result % prime;
    }
}
