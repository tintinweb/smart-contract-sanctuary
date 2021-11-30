/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

// File: contracts/lib/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath div 0"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub b > a");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath add overflow");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath mod 0");
        return a % b;
    }
}

// File: contracts/schnorr/Bn128.sol

pragma solidity ^0.4.24;


contract Bn128 {
    using SafeMath for uint;
    
    uint256 constant gx = 0x1;
    uint256 constant gy = 0x2;

    /// @dev Order is the number of elements in both G₁ and G₂: 36u⁴+36u³+18u²+6u+1.
    uint256 constant order = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function getGx() public pure returns (uint256) {
        return gx;
    }

    function getGy() public pure returns (uint256) {
        return gy;
    }

    function getOrder() public pure returns (uint256) {
        return order;
    }

    function ecadd(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public view returns (uint256 x3, uint256 y3) {
        uint256[2] memory outValue;
        uint256[4] memory input;
        input[0] = x1;
        input[1] = y1;
        input[2] = x2;
        input[3] = y2;

        assembly {
            if iszero(staticcall(gas, 0x06, input, 0x80, outValue, 0x40)) {
                revert(0, 0)
            }
        }

        x3 = outValue[0];
        y3 = outValue[1];
    }

    function ecmul(
        uint256 x1,
        uint256 y1,
        uint256 scalar
    ) public view returns (uint256 x2, uint256 y2) {
        uint256[2] memory outValue;
        uint256[3] memory input;
        input[0] = x1;
        input[1] = y1;
        input[2] = scalar;

        assembly {
            if iszero(staticcall(gas, 0x07, input, 0x60, outValue, 0x40)) {
                revert(0, 0)
            }
        }

        x2 = outValue[0];
        y2 = outValue[1];
    }
}

// File: contracts/schnorr/Bn128SchnorrVerifier.sol

pragma solidity ^0.4.24;


contract Bn128SchnorrVerifier is Bn128 {
    struct Point {
        uint256 x; uint256 y;
    }

    struct Verification {
        Point groupKey;
        Point randomPoint;
        uint256 signature;
        bytes32 message;

        uint256 _hash;
        Point _left;
        Point _right;
    }

    function h(bytes32 m, uint256 a, uint256 b) public pure returns (uint256) {
        return uint256(sha256(abi.encodePacked(m, a, b)));
    }

    // function cmul(Point p, uint256 scalar) public pure returns (uint256, uint256) {
    function cmul(uint256 x, uint256 y, uint256 scalar) public view returns (uint256, uint256) {
        return ecmul(x, y, scalar);
    }

    function sg(uint256 sig_s) public view returns (uint256, uint256) {
        return ecmul(getGx(), getGy(), sig_s);
    }

    // function cadd(Point a, Point b) public pure returns (uint256, uint256) {
    function cadd(uint256 ax, uint256 ay, uint256 bx, uint256 by) public view returns (uint256, uint256) {
        return ecadd(ax, ay, bx, by);
    }

    function verify(bytes32 signature, bytes32 groupKeyX, bytes32 groupKeyY, bytes32 randomPointX, bytes32 randomPointY, bytes32 message)
        public
        view
        returns(bool)
    {
        bool flag = false;
        Verification memory state;

        state.signature = uint256(signature);
        state.groupKey.x = uint256(groupKeyX);
        state.groupKey.y = uint256(groupKeyY);
        state.randomPoint.x = uint256(randomPointX);
        state.randomPoint.y = uint256(randomPointY);
        state.message = message;

        state._hash = h(state.message, state.randomPoint.x, state.randomPoint.y);

        /// change to bn256 range.
        state._hash = uint256(state._hash).mod(getOrder());

        (state._left.x, state._left.y) = sg(state.signature);
        Point memory rightPart;
        (rightPart.x, rightPart.y) = cmul(state.groupKey.x, state.groupKey.y, state._hash);
        (state._right.x, state._right.y) = cadd(state.randomPoint.x, state.randomPoint.y, rightPart.x, rightPart.y);

        flag = state._left.x == state._right.x && state._left.y == state._right.y;

        return flag;
    }
}