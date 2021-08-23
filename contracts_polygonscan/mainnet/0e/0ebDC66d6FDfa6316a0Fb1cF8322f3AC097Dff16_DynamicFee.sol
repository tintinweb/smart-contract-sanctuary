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

import './Color.sol';
import './Num.sol';
import './IDynamicFee.sol';

contract DynamicFee is IDynamicFee, Bronze, Num {
    function spow3(int256 _value) internal pure returns (int256) {
        return (((_value * _value) / iBONE) * _value) / iBONE;
    }

    function calcExpStart(int256 _inBalance, int256 _outBalance) internal pure returns (int256) {
        return ((_inBalance - _outBalance) * iBONE) / (_inBalance + _outBalance);
    }

    function calc(
        int256[3] calldata _inRecord,
        int256[3] calldata _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _maxFee
    ) external pure override returns (int256 fee, int256 expStart) {
        expStart = calcExpStart(_inRecord[0], _outRecord[0]);

        int256 _expEnd =
            ((_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE) /
                (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if (expStart >= 0) {
            fee =
                _baseFee +
                (_feeAmp * (spow3(_expEnd) - spow3(expStart))) /
                (3 * (_expEnd - expStart));
        } else if (_expEnd <= 0) {
            fee = _baseFee;
        } else {
            fee = calcExpEndFee(_inRecord, _outRecord, _baseFee, _feeAmp, _expEnd);
        }

        if (_maxFee < fee) {
            fee = _maxFee;
        }

        if (iBONE / 1000 > fee) {
            fee = iBONE / 1000;
        }
    }

    function calcExpEndFee(
        int256[3] calldata _inRecord,
        int256[3] calldata _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _expEnd
    ) internal pure returns (int256) {
        int256 inBalanceLeveraged = getLeveragedBalance(_inRecord[0], _inRecord[1]);
        int256 tokenAmountIn1 =
            inBalanceLeveraged * (_outRecord[0] - _inRecord[0]) /
                (inBalanceLeveraged + getLeveragedBalance(_outRecord[0], _outRecord[1]));

        int256 inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int256 tokenAmountIn2 =
            inBalanceLeveragedChanged * (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) /
            (inBalanceLeveragedChanged + getLeveragedBalance(_outRecord[0], _outRecord[1]) - _outRecord[2] * iBONE);

        return (tokenAmountIn1 * _baseFee + tokenAmountIn2 * (_baseFee + (_feeAmp * ((_expEnd * _expEnd) / iBONE)) / (3 * iBONE))) /
            (tokenAmountIn1 + tokenAmountIn2);
    }

    function getLeveragedBalance(int256 _balance, int256 _leverage)
        internal
        pure
        returns (int256)
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

abstract contract Color {
    function getColor() external view virtual returns (bytes32);
}

contract Bronze is Color {
    function getColor() external view override returns (bytes32) {
        return bytes32('BRONZE');
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

import './Const.sol';

contract Num is Const {

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, 'ADD_OVERFLOW');
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        bool flag;
        (c, flag) = subSign(a, b);
        require(!flag, 'SUB_UNDERFLOW');
    }

    function subSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, 'MUL_OVERFLOW');
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, 'MUL_OVERFLOW');
        c = c1 / BONE;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0, 'DIV_ZERO');
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, 'DIV_INTERNAL'); // mul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, 'DIV_INTERNAL'); //  add require
        c = c1 / b;
    }

    function min(uint256 first, uint256 second) internal pure returns (uint256) {
        if (first < second) {
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
        int256[3] calldata _inRecord,
        int256[3] calldata _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _maxFee
    ) external pure returns (int256 fee, int256 expStart);
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

contract Const {
    uint8 public constant BONE_DECIMALS = 26;
    uint256 public constant BONE = 10**BONE_DECIMALS;
    int256 public constant iBONE = int256(BONE);
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