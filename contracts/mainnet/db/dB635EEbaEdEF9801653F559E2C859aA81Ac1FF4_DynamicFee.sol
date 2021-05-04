// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Num.sol";
import "./IDynamicFee.sol";

contract DynamicFee is IDynamicFee, Bronze, Num {

    function spow3(int _value)
    internal pure
    returns(int){
        return ((_value * _value) / iBONE) * _value / iBONE;
    }

    function calcExpStart(
        int _inBalance,
        int _outBalance
    )
    internal pure
    returns(int) {
        return (_inBalance - _outBalance) * iBONE / (_inBalance + _outBalance);
    }

    function calcSpotFee(
        int _expStart,
        uint _baseFee,
        uint _feeAmp,
        uint _maxFee
    )
    external pure override
    returns(uint) {
        if(_expStart >= 0) {
            return min(_baseFee + _feeAmp * uint(_expStart * _expStart) / BONE, _maxFee);
        } else {
            return _baseFee / 2;
        }
    }

    function calc(
        int[3] calldata _inRecord,
        int[3] calldata _outRecord,
        int _baseFee,
        int _feeAmp,
        int _maxFee
    )
    external pure override
    returns(int fee, int expStart)
    {

        expStart = calcExpStart(_inRecord[0], _outRecord[0]);
        int _expEnd = (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE /
            (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if(expStart >= 0) {
            fee = _baseFee + ((_feeAmp) * (spow3(_expEnd) - spow3(expStart))) * iBONE / (3 * (_expEnd - expStart));
        } else if(_expEnd <= 0) {
            fee = _baseFee / 2;
        } else {
            fee = calcExpEndFee(
                _inRecord,
                _outRecord,
                _baseFee,
                _feeAmp,
                _expEnd
            );
        }

        if(_maxFee <  fee) {
            fee = _maxFee;
        }

        if(iBONE / 1000 >  fee) {
            fee = iBONE / 1000;
        }
    }

    function calcExpEndFee(
        int[3] calldata _inRecord,
        int[3] calldata _outRecord,
        int _baseFee,
        int _feeAmp,
        int _expEnd
    )
        internal
        pure
        returns (int)
    {
        int inBalanceLeveraged = getLeveragedBalance(_inRecord[0], _inRecord[1]);
        int tokenAmountIn1 = inBalanceLeveraged * (_outRecord[0] - _inRecord[0]) * iBONE /
        (inBalanceLeveraged + getLeveragedBalance(_outRecord[0], _outRecord[1])) / iBONE;
        int inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int tokenAmountIn2 = inBalanceLeveragedChanged * (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE /
        (inBalanceLeveragedChanged + ((getLeveragedBalance(_outRecord[0], _outRecord[1]) - _outRecord[2] * iBONE))) / iBONE;

        int fee = tokenAmountIn1 * _baseFee / (iBONE * 2);
        fee = fee + tokenAmountIn2 * (_baseFee + _feeAmp * (_expEnd * _expEnd / iBONE) / 3) / iBONE;
        return fee * iBONE / (tokenAmountIn1 + tokenAmountIn2);
    }

    function getLeveragedBalance(
        int _balance,
        int _leverage
    )
    internal pure
    returns(int)
    {
        return _balance * _leverage;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Const.sol";

contract Num is Const {

    function toi(uint a)
        internal pure
        returns (uint)
    {
        return a / BONE;
    }

    function floor(uint a)
        internal pure
        returns (uint)
    {
        return toi(a) * BONE;
    }

    function add(uint a, uint b)
        internal pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(uint a, uint b)
        internal pure
        returns (uint c)
    {
        bool flag;
        (c, flag) = subSign(a, b);
        require(!flag, "SUB_UNDERFLOW");
    }

    function subSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint a, uint b)
        internal pure
        returns (uint c)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "MUL_OVERFLOW");
        c = c1 / BONE;
    }

    function div(uint a, uint b)
        internal pure
        returns (uint c)
    {
        require(b != 0, "DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "DIV_INTERNAL"); // mul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "DIV_INTERNAL"); //  add require
        c = c1 / b;
    }

    // DSMath.wpow
    function powi(uint a, uint n)
        internal pure
        returns (uint z)
    {
        z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = mul(a, a);

            if (n % 2 != 0) {
                z = mul(z, a);
            }
        }
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `powi` for `b^e` and `powK` for k iterations
    // of approximation of b^0.w
    function pow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_POW_BASE, "POW_BASE_TOO_LOW");
        require(base <= MAX_POW_BASE, "POW_BASE_TOO_HIGH");

        uint whole  = floor(exp);
        uint remain = sub(exp, whole);

        uint wholePow = powi(base, toi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = powApprox(base, remain, POW_PRECISION);
        return mul(wholePow, partialResult);
    }

    function powApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint sum)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = subSign(base, BONE);
        uint term = BONE;
        sum   = term;
        bool negative = false;


        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = subSign(a, sub(bigK, BONE));
            term = mul(term, mul(c, x));
            term = div(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sub(sum, term);
            } else {
                sum = add(sum, term);
            }
        }
    }

    function min(uint first, uint second)
        internal pure
        returns (uint)
    {
        if(first < second) {
            return first;
        }
        return second;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IDynamicFee {

    function calc(
        int[3] calldata _inRecord,
        int[3] calldata _outRecord,
        int _baseFee,
        int _feeAmp,
        int _maxFee
    )
    external
    returns(int fee, int expStart);

    function calcSpotFee(
        int _expStart,
        uint _baseFee,
        uint _feeAmp,
        uint _maxFee
    )
    external
    returns(uint);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Color.sol";

contract Const is Bronze {
    uint public constant BONE              = 10**18;
    int public constant  iBONE             = int(BONE);

    uint public constant MIN_POW_BASE      = 1 wei;
    uint public constant MAX_POW_BASE      = (2 * BONE) - 1 wei;
    uint public constant POW_PRECISION     = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

abstract contract Color {
    function getColor()
        external view virtual
        returns (bytes32);
}

contract Bronze is Color {
    function getColor()
        external view override
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}