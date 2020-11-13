pragma solidity ^0.6.0;

import "../implementation/FixedPoint.sol";


// Wraps the FixedPoint library for testing purposes.
contract FixedPointTest {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for uint256;
    using SafeMath for uint256;

    function wrapFromUnscaledUint(uint256 a) external pure returns (uint256) {
        return FixedPoint.fromUnscaledUint(a).rawValue;
    }

    function wrapIsEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isEqual(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isEqual(b);
    }

    function wrapIsGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThan(FixedPoint.Unsigned(b));
    }

    function wrapIsGreaterThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThan(b);
    }

    function wrapMixedIsGreaterThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isGreaterThanOrEqual(b);
    }

    function wrapMixedIsGreaterThanOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isGreaterThan(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsGreaterThanOrEqualOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isGreaterThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapIsLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThan(FixedPoint.Unsigned(b));
    }

    function wrapIsLessThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThan(b);
    }

    function wrapMixedIsLessThanOrEqual(uint256 a, uint256 b) external pure returns (bool) {
        return FixedPoint.Unsigned(a).isLessThanOrEqual(b);
    }

    function wrapMixedIsLessThanOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isLessThan(FixedPoint.Unsigned(b));
    }

    function wrapMixedIsLessThanOrEqualOpposite(uint256 a, uint256 b) external pure returns (bool) {
        return a.isLessThanOrEqual(FixedPoint.Unsigned(b));
    }

    function wrapMin(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).min(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapMax(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).max(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).add(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).add(b).rawValue;
    }

    function wrapSub(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).sub(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedSub(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).sub(b).rawValue;
    }

    // The second uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedSubOpposite(uint256 a, uint256 b) external pure returns (uint256) {
        return a.sub(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapMul(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mul(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapMulCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mulCeil(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedMul(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mul(b).rawValue;
    }

    function wrapMixedMulCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).mulCeil(b).rawValue;
    }

    function wrapDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).div(FixedPoint.Unsigned(b)).rawValue;
    }

    function wrapDivCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).divCeil(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).div(b).rawValue;
    }

    function wrapMixedDivCeil(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).divCeil(b).rawValue;
    }

    // The second uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapMixedDivOpposite(uint256 a, uint256 b) external pure returns (uint256) {
        return a.div(FixedPoint.Unsigned(b)).rawValue;
    }

    // The first uint256 is interpreted with a scaling factor and is converted to an `Unsigned` directly.
    function wrapPow(uint256 a, uint256 b) external pure returns (uint256) {
        return FixedPoint.Unsigned(a).pow(b).rawValue;
    }
}
