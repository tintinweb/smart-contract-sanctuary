pragma solidity 0.4.18;


contract UtilMath {
    uint public constant BIG_NUMBER = (uint(1)<<uint(200));

    function checkMultOverflow(uint x, uint y) public pure returns(bool) {
        if (y == 0) return false;
        return (((x*y) / y) != x);
    }

    function compactFraction(uint p, uint q, uint precision) public pure returns (uint, uint) {
        if (q < precision * precision) return (p, q);
        return compactFraction(p/precision, q/precision, precision);
    }

    /* solhint-disable code-complexity */
    function exp(uint p, uint q, uint precision) public pure returns (uint) {
        uint n = 0;
        uint nFact = 1;
        uint currentP = 1;
        uint currentQ = 1;

        uint sum = 0;
        uint prevSum = 0;

        while (true) {
            if (checkMultOverflow(currentP, precision)) return sum;
            if (checkMultOverflow(currentQ, nFact)) return sum;

            sum += (currentP * precision) / (currentQ * nFact);

            if (sum == prevSum) return sum;
            prevSum = sum;

            n++;

            if (checkMultOverflow(currentP, p)) return sum;
            if (checkMultOverflow(currentQ, q)) return sum;
            if (checkMultOverflow(nFact, n)) return sum;

            currentP *= p;
            currentQ *= q;
            nFact *= n;

            (currentP, currentQ) = compactFraction(currentP, currentQ, precision);
        }
    }
    /* solhint-enable code-complexity */

    function countLeadingZeros(uint p, uint q) public pure returns (uint) {
        uint denomator = (uint(1)<<255);
        for (int i = 255; i >= 0; i--) {
            if ((q*denomator)/denomator != q) {
                // overflow
                denomator = denomator/2;
                continue;
            }
            if (p/(q*denomator) > 0) return uint(i);
            denomator = denomator/2;
        }

        return uint(-1);
    }

    // log2 for a number that it in [1,2)
    function log2ForSmallNumber(uint x, uint numPrecisionBits) public pure returns (uint) {
        uint res = 0;
        uint one = (uint(1)<<numPrecisionBits);
        uint two = 2 * one;
        uint addition = one;

        require((x >= one) && (x <= two));
        require(numPrecisionBits < 125);

        for (uint i = numPrecisionBits; i > 0; i--) {
            x = (x*x) / one;
            addition = addition/2;
            if (x >= two) {
                x = x/2;
                res += addition;
            }
        }

        return res;
    }

    function logBase2 (uint p, uint q, uint numPrecisionBits) public pure returns (uint) {
        uint n = 0;
        uint precision = (uint(1)<<numPrecisionBits);

        if (p > q) {
            n = countLeadingZeros(p, q);
        }

        require(!checkMultOverflow(p, precision));
        require(!checkMultOverflow(n, precision));
        require(!checkMultOverflow(uint(1)<<n, q));

        uint y = p * precision / (q * (uint(1)<<n));
        uint log2Small = log2ForSmallNumber(y, numPrecisionBits);

        require(n*precision <= BIG_NUMBER);
        require(log2Small <= BIG_NUMBER);

        return n * precision + log2Small;
    }

    function ln(uint p, uint q, uint numPrecisionBits) public pure returns (uint) {
        uint ln2Numerator   = 6931471805599453094172;
        uint ln2Denomerator = 10000000000000000000000;

        uint log2x = logBase2(p, q, numPrecisionBits);

        require(!checkMultOverflow(ln2Numerator, log2x));

        return ln2Numerator * log2x / ln2Denomerator;
    }
}


contract LiquidityFormula is UtilMath {
    function pE(uint r, uint pMIn, uint e, uint precision) public pure returns (uint) {
        require(!checkMultOverflow(r, e));
        uint expRE = exp(r*e, precision*precision, precision);
        require(!checkMultOverflow(expRE, pMIn));
        return pMIn*expRE / precision;
    }

    function deltaTFunc(uint r, uint pMIn, uint e, uint deltaE, uint precision) public pure returns (uint) {
        uint pe = pE(r, pMIn, e, precision);
        uint rpe = r * pe;

        require(!checkMultOverflow(r, deltaE));
        uint erdeltaE = exp(r*deltaE, precision*precision, precision);

        require(erdeltaE >= precision);
        require(!checkMultOverflow(erdeltaE - precision, precision));
        require(!checkMultOverflow((erdeltaE - precision)*precision, precision));
        require(!checkMultOverflow((erdeltaE - precision)*precision*precision, precision));
        require(!checkMultOverflow(rpe, erdeltaE));
        require(!checkMultOverflow(r, pe));

        return (erdeltaE - precision) * precision * precision * precision / (rpe*erdeltaE);
    }

    function deltaEFunc(uint r, uint pMIn, uint e, uint deltaT, uint precision, uint numPrecisionBits)
        public pure
        returns (uint)
    {
        uint pe = pE(r, pMIn, e, precision);
        uint rpe = r * pe;

        require(!checkMultOverflow(rpe, deltaT));
        require(precision * precision + rpe * deltaT/precision > precision * precision);
        uint lnPart = ln(precision*precision + rpe*deltaT/precision, precision*precision, numPrecisionBits);

        require(!checkMultOverflow(r, pe));
        require(!checkMultOverflow(precision, precision));
        require(!checkMultOverflow(rpe, deltaT));
        require(!checkMultOverflow(lnPart, precision));

        return lnPart * precision / r;
    }
}
