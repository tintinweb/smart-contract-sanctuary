/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice A point on the sphere with unit radius.
 * @dev Since we will be interested in 3D points in the end, it makes more
 * sense to just store trigonimetric values (and don't spend the effort
 * to invert to the actual angles).
 */
struct SphericalPoint {
    int256 sinAzimuth;
    int256 cosAzimuth;
    int256 sinAltitude;
    int256 cosAltitude;
}

/**
 * @notice Some special math functions used for `Strange Attractors`.
 * @dev The functions use fixed-point number with the same precision (96) as
 * the numerical solvers (see also `IAttractorSolver`).
 * @author David Huber (@cxkoda)
 */
library MathHelpers {
    uint8 public constant PRECISION = 96;

    /**
     * @dev Some handy constants.
     */
    int256 private constant ONE = 2**96;
    int256 public constant PI = 248902613312231085230521944622;
    int256 public constant PI_2 = 497805226624462170461043889244;
    int256 public constant MINUS_PI_2 = -497805226624462170461043889244;
    int256 public constant PI_0_5 = 124451306656115542615260972311;

    /**
     * @notice Taylor series coefficients for sin around 0.
     */
    int256 private constant COEFFICIENTS_SIN_1 = 2**96;
    int256 private constant COEFFICIENTS_SIN_3 = -(2**96 + 2) / 6;
    int256 private constant COEFFICIENTS_SIN_5 = (2**96 - 16) / 120;
    int256 private constant COEFFICIENTS_SIN_7 = -(2**96 + 944) / 5040;
    int256 private constant COEFFICIENTS_SIN_9 = (2**96 - 205696) / 362880;
    int256 private constant COEFFICIENTS_SIN_11 =
        -(2**96 + 34993664) / 39916800;

    /**
     * @notice A pure solidity approximation of the sine function.
     * @dev The implementation uses a broken Taylor series approximation to
     * compute values. The absolute error is <1e-3.
     */
    function sin(int256 x) public pure returns (int256 result) {
        assembly {
            // We remap the x to the range [-pi, pi] first, since the Taylor
            // series is most accurate there.

            // Attention: smod(-10, 2) = -10 but smod(-10, -2) = 0
            // We therefore shift the numbers to the positive side first
            x := add(smod(x, MINUS_PI_2), PI_2)

            // Restrict to the range [-pi, pi]
            x := sub(addmod(x, PI, PI_2), PI)

            let x2 := sar(PRECISION, mul(x, x))
            result := sar(
                PRECISION,
                mul(
                    x,
                    add(
                        COEFFICIENTS_SIN_1,
                        sar(
                            PRECISION,
                            mul(
                                x2,
                                add(
                                    COEFFICIENTS_SIN_3,
                                    sar(
                                        PRECISION,
                                        mul(
                                            x2,
                                            add(
                                                COEFFICIENTS_SIN_5,
                                                sar(
                                                    PRECISION,
                                                    mul(
                                                        x2,
                                                        add(
                                                            COEFFICIENTS_SIN_7,
                                                            sar(
                                                                PRECISION,
                                                                mul(
                                                                    x2,
                                                                    add(
                                                                        COEFFICIENTS_SIN_9,
                                                                        sar(
                                                                            PRECISION,
                                                                            mul(
                                                                                x2,
                                                                                COEFFICIENTS_SIN_11
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        }
    }

    /**
     * @notice Taylor series coefficients for cos around 0.
     */
    int256 private constant COEFFICIENTS_COS_2 = -(2**96 / 2);
    int256 private constant COEFFICIENTS_COS_4 = (2**96 - 16) / 24;
    int256 private constant COEFFICIENTS_COS_6 = -(2**96 + 224) / 720;
    int256 private constant COEFFICIENTS_COS_8 = (2**96 - 4096) / 40320;
    int256 private constant COEFFICIENTS_COS_10 = -(2**96 + 2334464) / 3628800;
    int256 private constant COEFFICIENTS_COS_12 =
        (2**96 - 204507136) / 479001600;

    /**
     * @notice A pure solidity approximation of the cosine function.
     * @dev The implementation uses a broken Taylor series approximation to
     * compute values. The absolute error is <1e-3.
     */
    function cos(int256 x) public pure returns (int256 result) {
        assembly {
            // We remap the x to the range [-pi, pi] first, since the Taylor
            // series is most accurate there.

            // Attention: smod(-10, 2) = -10 but smod(-10, -2) = 0
            // We therefore shift the numbers to the positive side first
            x := add(smod(x, MINUS_PI_2), PI_2)

            // Restrict to the range [-pi, pi]
            x := sub(addmod(x, PI, PI_2), PI)

            let x2 := sar(PRECISION, mul(x, x))

            result := add(
                ONE,
                sar(
                    PRECISION,
                    mul(
                        x2,
                        add(
                            COEFFICIENTS_COS_2,
                            sar(
                                PRECISION,
                                mul(
                                    x2,
                                    add(
                                        COEFFICIENTS_COS_4,
                                        sar(
                                            PRECISION,
                                            mul(
                                                x2,
                                                add(
                                                    COEFFICIENTS_COS_6,
                                                    sar(
                                                        PRECISION,
                                                        mul(
                                                            x2,
                                                            add(
                                                                COEFFICIENTS_COS_8,
                                                                sar(
                                                                    PRECISION,
                                                                    mul(
                                                                        x2,
                                                                        add(
                                                                            COEFFICIENTS_COS_10,
                                                                            sar(
                                                                                PRECISION,
                                                                                mul(
                                                                                    x2,
                                                                                    COEFFICIENTS_COS_12
                                                                                )
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        }
    }

    /**
     * @notice A pure solidity approximation of the square root function.
     * @dev The implementation uses the Babylonian method with a fixed amount of
     *  steps (for a predictable gas). The approximation is optimised for values
     * in the range of[0,1]. The absolute error is <1e-3.
     */
    function sqrt(int256 x) public pure returns (int256 result) {
        require(x >= 0, "Sqrt is only defined for positive numbers");
        assembly {
            result := x
            result := sar(1, add(div(shl(PRECISION, x), result), result))
            result := sar(1, add(div(shl(PRECISION, x), result), result))
            result := sar(1, add(div(shl(PRECISION, x), result), result))
            result := sar(1, add(div(shl(PRECISION, x), result), result))
            result := sar(1, add(div(shl(PRECISION, x), result), result))
            result := sar(1, add(div(shl(PRECISION, x), result), result))
            result := sar(1, add(div(shl(PRECISION, x), result), result))
        }
    }

    int256 private constant GOLDEN_RATIO = 128193859814280023944822833248;

    /**
     * @notice Computes quasi-equidistant points on a unit-sphere.
     * @dev The function employs Fibonacci lattices remapped to the unit-sphere
     * to compute `numPoints` different points in spherical coordinates. It
     * should be noted that we use the angle convention `altitude`(=theta) in
     * [-pi/2, pi/2].
     */
    function getFibonacciLatticeOnSphere(uint256 idx, uint256 numPoints)
        internal
        pure
        returns (SphericalPoint memory sphericalPoint)
    {
        require(idx >= 0 && idx < numPoints, "Index out of range");
        sphericalPoint.sinAltitude =
            (2 * ONE * int256(idx)) /
            int256(numPoints) -
            ONE;

        {
            int256 sinAltitude2 = sphericalPoint.sinAltitude;
            assembly {
                sinAltitude2 := sar(PRECISION, mul(sinAltitude2, sinAltitude2))
            }
            sphericalPoint.cosAltitude = sqrt(ONE - sinAltitude2);
        }

        {
            int256 azimuth;
            assembly {
                azimuth := smod(
                    div(shl(PRECISION, mul(PI_2, idx)), GOLDEN_RATIO),
                    PI_2
                )
            }
            sphericalPoint.cosAzimuth = cos(azimuth);
            sphericalPoint.sinAzimuth = sin(azimuth);
        }
    }

    /**
     * @notice Computes projection axes for different directions.
     * @dev Uses the directions provided by `getFibonacciLatticeOnSphere` to
     * compute two normalised, orthogonal axes. The are computed by rotating the
     * x-z projection plane first by `altitude` around -x and then by `azimuth`
     * around +z.
     */
    function getFibonacciSphericalAxes(uint256 idx, uint256 numPoints)
        external
        pure
        returns (int256[3] memory axis1, int256[3] memory axis2)
    {
        SphericalPoint memory sphericalPoint = getFibonacciLatticeOnSphere(
            idx,
            numPoints
        );

        axis1 = [sphericalPoint.cosAzimuth, sphericalPoint.sinAzimuth, 0];
        axis2 = [
            -sphericalPoint.sinAzimuth * sphericalPoint.sinAltitude,
            sphericalPoint.cosAzimuth * sphericalPoint.sinAltitude,
            sphericalPoint.cosAltitude
        ];

        assembly {
            let pos := axis2
            mstore(pos, sar(PRECISION, mload(pos)))
            pos := add(pos, 0x20)
            mstore(pos, sar(PRECISION, mload(pos)))
        }
    }
}