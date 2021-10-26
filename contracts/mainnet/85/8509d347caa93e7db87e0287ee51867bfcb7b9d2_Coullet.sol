// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolver3D.sol";

/**
 * @notice Pure-Solidity, numerical solution of the chaotic, three-dimensional
 * Coullet system of differential equations.
 * @dev This implements all the necessary algorithms needed for the numerical
 * treatment of the equations and the 2D projection of the data. See also
 * `IAttractorSolver` and `AttractorSolver` for more context.
 * @author David Huber (@cxkoda)
 */
contract Coullet is AttractorSolver3D {
    /**
     * @notice The parameters of the dynamical system and some handy constants.
     * @dev Unfortunately, we have to write them out to be usable in inline
     * assembly. The occasionally added, negligible term is to make the number
     * dividable without rest - otherwise there will be conversion issues.
     */
    int256 private constant ALPHA = ((8 * 2**64 - 8) / 10) * 2**32;
    int256 private constant BETA = ((-11 * 2**64 - 4) / 10) * 2**32;
    int256 private constant GAMMA = ((-45 * 2**64 - 80) / 100) * 2**32;
    int256 private constant DELTA = ((-1 * 2**64 - 84) / 100) * 2**32;

    // -------------------------
    //
    //  Base Interface
    //
    // -------------------------

    /**
     * @notice See `IAttractorSolver.getSystemType`.
     */
    function getSystemType() public pure override returns (string memory) {
        return "Coullet";
    }

    /**
     * @notice See `IAttractorSolver.getSystemType`.
     * @dev The random range was manually tuned such that the system consistenly
     * reaches the attractor.
     */
    function getRandomStartingPoint(uint256 randomSeed)
        external
        view
        virtual
        override
        returns (StartingPoint memory startingPoint)
    {
        startingPoint.startingPoint = new int256[](DIM);
        int256 randNumber;
        int256 range = ONE/ 2**9;

        (randomSeed, randNumber) = _random(randomSeed, range);
        startingPoint.startingPoint[0] = ONE + randNumber;

        (randomSeed, randNumber) = _random(randomSeed, range);
        startingPoint.startingPoint[1] = ONE;

        (randomSeed, randNumber) = _random(randomSeed, range);
        startingPoint.startingPoint[2] = ONE;
    }

    /**
     * @notice See `AttractorSolver3D._getDefaultProjectionScale`.
     */
    function _getDefaultProjectionScale()
        internal
        pure
        override
        returns (int256)
    {
        return 4 * ONE;
    }

    /**
     * @notice See `AttractorSolver3D._getDefaultProjectionOffset`.
     */
    function _getDefaultProjectionOffset()
        internal
        pure
        override
        returns (int256[] memory offset)
    {
        offset = new int256[](DIM);
    }

    // -------------------------
    //
    //  Number Crunching
    //
    // -------------------------

    /**
     * @dev The following the heart-piece of every attractor solver.
     * Here the system of ODEs (in the form `u' = f(u)`) will be solved
     * numerically using the explicit, classical Runge-Kutta 4 method (aka RK4).
     * Such a high order scheme is needed to maintain numerical stability while
     * reducing the amount of timesteps needed to obtain a solution for the
     * considered systems. Before storing the results, points and tangents are
     * projected to 2D.
     * Warning: The returns are given as fixed-point numbers with reduced
     * precision (6) and width (16 bit). See `AttractorSolution` and
     * `AttractorSolver`.
     * @return points contains every `skip` point of the numerical solution. It
     * includes the starting point at the first position.
     * @return tangents contains the tangents (i.e. the ODEs RHS) at the
     * position of `points`.
     */
    function _solve(
        SolverParameters memory solverParameters,
        StartingPoint3D memory startingPoint,
        ProjectionParameters3D memory projectionParameters
    )
        internal
        pure
        override
        returns (bytes memory points, bytes memory tangents)
    {
        // Some handy aliases
        uint256 numberOfIterations = solverParameters.numberOfIterations;
        uint256 dt = solverParameters.dt;
        uint8 skip = solverParameters.skip;

        assembly {
            // Allocate space for the results
            // 2 bytes (16-bit) * 2 coordinates * amount of pairs in storage
            let length := mul(4, add(1, div(numberOfIterations, skip)))

            function allocate(size_) -> ptr {
                // Get free memory pointer
                ptr := mload(0x40)
                // Set allocation length
                mstore(ptr, size_)

                // Actually allocate 2 * 32B more:
                // Dynamic array length info (32B) and some free buffer space at
                // the end (such that we can safely write over array boundaries)
                mstore(0x40, add(ptr, add(size_, 0x40)))
            }
            points := allocate(length)
            tangents := allocate(length)
        }

        // Temporary space to store the current point and tangent
        int256[DIM] memory point = startingPoint.startingPoint;
        int256[DIM] memory tangent;

        // Temporary space for the weighted sum of intermediate RHS evaluations
        // needed for Runge-Kutta schemes.
        int256[DIM] memory rhsSum;

        // Parental Advisory: Explicit Yul Content
        // You and people around you may be exposed to content that you find
        // objectionable and/or offensive.
        // All stunts were performed by trained professionals, don't try this
        // at home. The producer of this code is not responsible for any
        // personal injury or damage.
        assembly {
            /**
             * @notice Reduce accuracy and range of number and stores it in a
             * buffer.
             * @dev Used to store simulation results in `points` and `tangents`
             *  as pairs of 16-bit numbers in row-major order. See also
             * `AttractorSolution`.
             */
            function storeData(bufferPos_, x_, y_) -> newBufferPos {
                // First we reduce the accuracy of the x coordinate for storing.
                // This not necessary for y because we will overwrite the extra
                // bits later anyways.
                x_ := sar(PRECISION_REDUCTION_SAR, x_)

                // Stack both numbers together, shift them all the way
                // to the left and write them to the buffer directly as 32B
                // chunks to save gas.
                // Because this operation could easily write over buffer
                // bounds, we added some extra space at the end earlier.
                mstore(
                    bufferPos_,
                    or(shl(240, x_), shr(16, shl(RANGE_REDUCTION_SHL, y_)))
                )

                newBufferPos := add(bufferPos_, 4)
            }

            /**
             * @notice Compute the projected x-coordinate of a 3D point.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis1 * (point_ - parameters_.offset)`,
             * with `*` being the scalar product.
             */
            function projectPointX(point_, parameters_) -> x {
                let axis1 := mload(parameters_)
                let offset_ := mload(add(parameters_, 0x40))
                {
                    let component := sub(mload(point_), mload(offset_))
                    x := mul(component, mload(axis1))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x20)),
                        mload(add(offset_, 0x20))
                    )
                    x := add(x, mul(component, mload(add(axis1, 0x20))))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x40)),
                        mload(add(offset_, 0x40))
                    )
                    x := add(x, mul(component, mload(add(axis1, 0x40))))
                }
                x := sar(PRECISION, x)
            }

            /**
             * @notice Compute the projected y-coordinate of a 3D point.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis2 * (point_ - parameters_.offset)`,
             * with `*` being the scalar product.
             */
            function projectPointY(point_, parameters_) -> y {
                let axis2 := mload(add(parameters_, 0x20))
                let offset_ := mload(add(parameters_, 0x40))
                {
                    let component := sub(mload(point_), mload(offset_))
                    y := mul(component, mload(axis2))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x20)),
                        mload(add(offset_, 0x20))
                    )
                    y := add(y, mul(component, mload(add(axis2, 0x20))))
                }
                {
                    let component := sub(
                        mload(add(point_, 0x40)),
                        mload(add(offset_, 0x40))
                    )
                    y := add(y, mul(component, mload(add(axis2, 0x40))))
                }
                y := sar(PRECISION, y)
            }

            /**
             * @notice Compute the projected x-coordinate of a 3D tangent.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis1 * point_`, with `*` being the scalar product.
             * The offset must not to be considered for directions.
             */
            function projectDirectionX(direction, parameters_) -> x {
                let axis1 := mload(parameters_)
                let offset_ := mload(add(parameters_, 0x40))
                x := mul(mload(direction), mload(axis1))
                x := add(
                    x,
                    mul(mload(add(direction, 0x20)), mload(add(axis1, 0x20)))
                )
                x := add(
                    x,
                    mul(mload(add(direction, 0x40)), mload(add(axis1, 0x40)))
                )
                x := sar(PRECISION, x)
            }

            /**
             * @notice Compute the projected y-coordinate of a 3D tangent.
             * @dev It implements the linear algebra calculation
             * `parameters_.axis2 * point_`, with `*` being the scalar product.
             * The offset must not to be considered for directions.
             */
            function projectDirectionY(direction, parameters_) -> y {
                let axis2 := mload(add(parameters_, 0x20))
                let offset_ := mload(add(parameters_, 0x40))
                y := mul(mload(direction), mload(axis2))
                y := add(
                    y,
                    mul(mload(add(direction, 0x20)), mload(add(axis2, 0x20)))
                )
                y := add(
                    y,
                    mul(mload(add(direction, 0x40)), mload(add(axis2, 0x40)))
                )
                y := sar(PRECISION, y)
            }

            // -------------------------
            //
            //  The actual work
            //
            // -------------------------

            // Store the starting point
            {
                let x := projectPointX(point, projectionParameters)
                let y := projectPointY(point, projectionParameters)
                let tmp := storeData(add(points, 0x20), x, y)
            }

            // A frequently used value in the RK4 scheme
            let dtSixth := div(dt, 6)

            // Rolling pointers to the current location in the output buffers
            let posPoints := add(points, 0x24)
            let posTangents := add(tangents, 0x20)

            // Loop over the amount of timesteps that need to be done
            for {
                let iter := 0
            } lt(iter, numberOfIterations) {
                iter := add(iter, 1)
            } {
                // The following updates the system's state by performing
                // as single time step according to the RK4 scheme. It is
                // generally used to solve systems of ODEs in the form of
                // `u' = f(u)`, where `f` is aka right-hand-side (rhs).
                //
                // The scheme can be summarized as follows:
                // rhs0 = f(uOld)
                // rhs1 = f(uOld + dt/2 * rhs0)
                // rhs2 = f(uOld + dt/2 * rhs1)
                // rhs3 = f(uOld + dt * rhs2)
                // rhsSum = rhs0 + 2 * rhs1 + 2 * rhs2 + rhs3
                // uNew = uOld + dt/6 * rhsSum
                //
                // A lot of code is repeatedly inlined for better efficiency.
                {
                    // Compute intermediate steps and weighted rhs sum
                    {
                        let dxdt
                        let dydt
                        let dzdt

                        // RK4 intermediate step 0
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the rhs for the current intermediate step
                            // Precompute x^3
                            let x3 := sar(
                                PRECISION,
                                mul(x, sar(PRECISION, mul(x, x)))
                            )
                            // x' = y
                            dxdt := y
                            // y' = z
                            dydt := z
                            // z' = a x + b y + c z + d x^3
                            dzdt := sar(
                                PRECISION,
                                add(
                                    mul(ALPHA, x),
                                    add(
                                        mul(BETA, y),
                                        add(mul(GAMMA, z), mul(DELTA, x3))
                                    )
                                )
                            )

                            // Initialise the `rhsSum` with the current `rhs0`
                            mstore(rhsSum, dxdt)
                            mstore(add(rhsSum, 0x20), dydt)
                            mstore(add(rhsSum, 0x40), dzdt)

                            // Since the rhs f(uOld) will be used to compute a
                            // tangent later, we'll store it here to prevent
                            // an unnecessay recompuation.
                            mstore(tangent, dxdt)
                            mstore(add(tangent, 0x20), dydt)
                            mstore(add(tangent, 0x40), dzdt)
                        }

                        // RK4 intermediate step 1
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the current intermediate state.
                            // Precision + 1 for dt / 2
                            x := add(x, sar(PRECISION_PLUS_1, mul(dxdt, dt)))
                            y := add(y, sar(PRECISION_PLUS_1, mul(dydt, dt)))
                            z := add(z, sar(PRECISION_PLUS_1, mul(dzdt, dt)))

                            // Compute the rhs for the current intermediate step
                            // Precompute x^3
                            let x3 := sar(
                                PRECISION,
                                mul(x, sar(PRECISION, mul(x, x)))
                            )
                            // x' = y
                            dxdt := y
                            // y' = z
                            dydt := z
                            // z' = a x + b y + c z + d x^3
                            dzdt := sar(
                                PRECISION,
                                add(
                                    mul(ALPHA, x),
                                    add(
                                        mul(BETA, y),
                                        add(mul(GAMMA, z), mul(DELTA, x3))
                                    )
                                )
                            )

                            // Add `rhs1` to the `rhsSum`.
                            // shl for adding it twice.
                            mstore(rhsSum, add(mload(rhsSum), shl(1, dxdt)))
                            mstore(
                                add(rhsSum, 0x20),
                                add(mload(add(rhsSum, 0x20)), shl(1, dydt))
                            )
                            mstore(
                                add(rhsSum, 0x40),
                                add(mload(add(rhsSum, 0x40)), shl(1, dzdt))
                            )
                        }

                        // RK4 intermediate step 2
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the current intermediate state.
                            // Precision + 1 for dt / 2
                            x := add(x, sar(PRECISION_PLUS_1, mul(dxdt, dt)))
                            y := add(y, sar(PRECISION_PLUS_1, mul(dydt, dt)))
                            z := add(z, sar(PRECISION_PLUS_1, mul(dzdt, dt)))

                            // Compute the rhs for the current intermediate step
                            // Precompute x^3
                            let x3 := sar(
                                PRECISION,
                                mul(x, sar(PRECISION, mul(x, x)))
                            )
                            // x' = y
                            dxdt := y
                            // y' = z
                            dydt := z
                            // z' = a x + b y + c z + d x^3
                            dzdt := sar(
                                PRECISION,
                                add(
                                    mul(ALPHA, x),
                                    add(
                                        mul(BETA, y),
                                        add(mul(GAMMA, z), mul(DELTA, x3))
                                    )
                                )
                            )

                            // Add `rhs2` to the `rhsSum`.
                            // shl for adding it twice.
                            mstore(rhsSum, add(mload(rhsSum), shl(1, dxdt)))
                            mstore(
                                add(rhsSum, 0x20),
                                add(mload(add(rhsSum, 0x20)), shl(1, dydt))
                            )
                            mstore(
                                add(rhsSum, 0x40),
                                add(mload(add(rhsSum, 0x40)), shl(1, dzdt))
                            )
                        }

                        // RK4 intermediate step 3
                        {
                            // Load the current point aka `uOld`.
                            let x := mload(point)
                            let y := mload(add(point, 0x20))
                            let z := mload(add(point, 0x40))

                            // Compute the current intermediate state.
                            x := add(x, sar(PRECISION, mul(dxdt, dt)))
                            y := add(y, sar(PRECISION, mul(dydt, dt)))
                            z := add(z, sar(PRECISION, mul(dzdt, dt)))

                            // Compute the rhs for the current intermediate step
                            // Precompute x^3
                            let x3 := sar(
                                PRECISION,
                                mul(x, sar(PRECISION, mul(x, x)))
                            )
                            // x' = y
                            dxdt := y
                            // y' = z
                            dydt := z
                            // z' = a x + b y + c z + d x^3
                            dzdt := sar(
                                PRECISION,
                                add(
                                    mul(ALPHA, x),
                                    add(
                                        mul(BETA, y),
                                        add(mul(GAMMA, z), mul(DELTA, x3))
                                    )
                                )
                            )

                            // Add `rhs3` to the `rhsSum`.
                            mstore(rhsSum, add(mload(rhsSum), dxdt))
                            mstore(
                                add(rhsSum, 0x20),
                                add(mload(add(rhsSum, 0x20)), dydt)
                            )
                            mstore(
                                add(rhsSum, 0x40),
                                add(mload(add(rhsSum, 0x40)), dzdt)
                            )
                        }
                    }

                    // Compute the new point aka `uNew`.
                    {
                        // Load the current point aka `uOld`.
                        let x := mload(point)
                        let y := mload(add(point, 0x20))
                        let z := mload(add(point, 0x40))

                        // Compute `uNew = dt/6 * rhsSum`
                        x := add(x, sar(PRECISION, mul(mload(rhsSum), dtSixth)))
                        y := add(
                            y,
                            sar(
                                PRECISION,
                                mul(mload(add(rhsSum, 0x20)), dtSixth)
                            )
                        )
                        z := add(
                            z,
                            sar(
                                PRECISION,
                                mul(mload(add(rhsSum, 0x40)), dtSixth)
                            )
                        )

                        // Update the point / state of the system.
                        mstore(point, x)
                        mstore(add(point, 0x20), y)
                        mstore(add(point, 0x40), z)
                    }
                }

                // Check if we are at a step where we have to store the point
                // to the results.
                if eq(addmod(iter, 1, skip), 0) {
                    // If so, project and store the 2D data
                    let x := projectPointX(point, projectionParameters)
                    let y := projectPointY(point, projectionParameters)
                    posPoints := storeData(posPoints, x, y)
                }

                // Check if we are at a step where we have to store the tangent
                // to the results. This is not the same as for points since
                // tangents corresponds to `f(uOld)`. The two are seperated by
                // one iteration.
                if eq(mod(iter, skip), 0) {
                    // Tangent will be used by renders to generate cubic Bezier
                    // curves. Following the rhs by `dtTangent = skip * dt / 3`
                    // yields optimal results for this.
                    let dtTangent := shl(1, mul(dtSixth, skip))

                    let x := sar(
                        PRECISION,
                        mul(
                            dtTangent,
                            projectDirectionX(tangent, projectionParameters)
                        )
                    )
                    let y := sar(
                        PRECISION,
                        mul(
                            dtTangent,
                            projectDirectionY(tangent, projectionParameters)
                        )
                    )
                    posTangents := storeData(posTangents, x, y)
                }
            }

            // Using a `skip` that divides `numberOfIterations` without rest
            // results in tangents being one entry short at the end.
            // Let's compute and add this one manually.
            if eq(mod(numberOfIterations, skip), 0) {
                {
                    let dxdt
                    let dydt
                    let dzdt

                    // Compute the tangent aka in analogy to the in the 0th
                    // intermediate step of the RK4 scheme
                    // I am sure you know the drill by now.
                    {
                        let x := mload(point)
                        let y := mload(add(point, 0x20))
                        let z := mload(add(point, 0x40))

                        let x3 := sar(
                            PRECISION,
                            mul(x, sar(PRECISION, mul(x, x)))
                        )

                        // x' = y
                        dxdt := y
                        // y' = z
                        dydt := z
                        // z' = a x + b y + c z + d x^3
                        dzdt := sar(
                            PRECISION,
                            add(
                                mul(ALPHA, x),
                                add(
                                    mul(BETA, y),
                                    add(mul(GAMMA, z), mul(DELTA, x3))
                                )
                            )
                        )

                        mstore(tangent, dxdt)
                        mstore(add(tangent, 0x20), dydt)
                        mstore(add(tangent, 0x40), dzdt)
                    }

                    // Project and store the tangent. Same as at the end of the
                    // main loop, see above.
                    {
                        let dtTangent := shl(1, mul(dtSixth, skip))

                        let x := sar(
                            PRECISION,
                            mul(
                                dtTangent,
                                projectDirectionX(tangent, projectionParameters)
                            )
                        )
                        let y := sar(
                            PRECISION,
                            mul(
                                dtTangent,
                                projectDirectionY(tangent, projectionParameters)
                            )
                        )
                        posTangents := storeData(posTangents, x, y)
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolver.sol";
import "../utils/MathHelpers.sol";

/**
 * @notice Base class for three-dimensional attractor simulators.
 * @dev Partial specialisation of `AttractorSolver` for three-dimensional
 * systems.
 * @author David Huber (@cxkoda)
 */
abstract contract AttractorSolver3D is AttractorSolver {
    uint8 internal constant DIM = 3;

    /**
     * @notice Three-dimensional starting point (see `StartingPoint`).
     * @dev This type will be used internally for the 3D solvers.
     */
    struct StartingPoint3D {
        int256[DIM] startingPoint;
    }

    /**
     * @notice Three-dimensional projection parameters point (see
     * `ProjectionParameters`).
     * @dev This type will be used internally for the 3D solvers.
     */
    struct ProjectionParameters3D {
        int256[DIM] axis1;
        int256[DIM] axis2;
        int256[DIM] offset;
    }

    /**
     * @notice See `IAttractorSolver.getDimensionality`.
     */
    function getDimensionality() public pure virtual override returns (uint8) {
        return DIM;
    }

    /**
     * @notice Converts dynamic to static arrays.
     * @dev Converts only arrays with length `DIM`
     */
    function _convertDynamicToStaticArray(int256[] memory input)
        internal
        pure
        returns (int256[DIM] memory output)
    {
        require(input.length == DIM);
        for (uint256 dim = 0; dim < DIM; ++dim) {
            output[dim] = input[dim];
        }
    }

    /**
     * @notice Converts dynamic to static arrays.
     * @dev Only applicable to arrays with length `DIM`
     */
    function _parseStartingPoint(StartingPoint memory startingPoint_)
        internal
        pure
        returns (StartingPoint3D memory startingPoint)
    {
        startingPoint.startingPoint = _convertDynamicToStaticArray(
            startingPoint_.startingPoint
        );
    }

    /**
     * @dev Converts dynamical length projections parameters to static ones
     * for internal use.
     */
    function _parseProjectionParameters(
        ProjectionParameters memory projectionParameters_
    )
        internal
        pure
        returns (ProjectionParameters3D memory projectionParameters)
    {
        require(isValidProjectionParameters(projectionParameters_));
        projectionParameters.axis1 = _convertDynamicToStaticArray(
            projectionParameters_.axis1
        );
        projectionParameters.axis2 = _convertDynamicToStaticArray(
            projectionParameters_.axis2
        );
        projectionParameters.offset = _convertDynamicToStaticArray(
            projectionParameters_.offset
        );
    }

    /**
     * @notice See `IAttractorSolver.getDefaultProjectionParameters`.
     * @dev The implementation relies on spherical Fibonacci lattices from
     * `MathHelpers` to compute the direction of the axes. Their normalisation
     * and offset is delegated to specialisations of `_getDefaultProjectionScale`
     * and `_getDefaultProjectionOffset` depending on the system.
     */
    function getDefaultProjectionParameters(uint256 editionId)
        external
        view
        virtual
        override
        returns (ProjectionParameters memory projectionParameters)
    {
        projectionParameters.offset = _getDefaultProjectionOffset();

        projectionParameters.axis1 = new int256[](DIM);
        projectionParameters.axis2 = new int256[](DIM);

        // Make some chaos
        uint256 fiboIdx = (editionId * 61 + 13) % 128;

        (int256[DIM] memory axis1, int256[DIM] memory axis2) = MathHelpers
            .getFibonacciSphericalAxes(fiboIdx, 128);

        int256 scale = _getDefaultProjectionScale();
        // Apply length and store back
        for (uint8 dim; dim < DIM; dim++) {
            projectionParameters.axis1[dim] = (scale * axis1[dim])/ONE;
            projectionParameters.axis2[dim] = (scale * axis2[dim])/ONE;
        }
    }

    /**
     * @notice See `IAttractorSolver.computeSolution`.
     */
    function computeSolution(
        SolverParameters calldata solverParameters,
        StartingPoint calldata startingPoint,
        ProjectionParameters calldata projectionParameters
    )
        external
        pure
        override
        onlyValidProjectionParameters(projectionParameters)
        returns (AttractorSolution memory solution)
    {
        // Delegate and repack the solution
        (solution.points, solution.tangents) = _solve(
            solverParameters,
            _parseStartingPoint(startingPoint),
            _parseProjectionParameters(projectionParameters)
        );
        // Compute the timestep between points in the output considering that
        // not all simulated points will be stored.
        solution.dt = solverParameters.dt * solverParameters.skip;
    }

    /**
     * @dev The simulaton routine to be implemented for the individual systems.
     * This intermediate interface was introduced to make variables more
     * easility accessibly in assembly code.
     */
    function _solve(
        SolverParameters memory solverParameters,
        StartingPoint3D memory startingPoint,
        ProjectionParameters3D memory projectionParameters
    )
        internal
        pure
        virtual
        returns (bytes memory points, bytes memory tangents);

    /**
     * @dev Retuns the default length of the projection axes for the
     * respective system.
     * Attention: Here we use integers instead of fixed-point numbers for
     * simplicity.
     */
    function _getDefaultProjectionScale()
        internal
        pure
        virtual
        returns (int256);

    /**
     * @dev Returns the default offset of the projection for the respective
     * system.
     */
    function _getDefaultProjectionOffset()
        internal
        pure
        virtual
        returns (int256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./IAttractorSolver.sol";

/**
 * @notice Base class for attractor simulators.
 * @dev The contract implements some convenient routines shared across
 * different AttractorSolvers.
 * @author David Huber (@cxkoda)
 */
abstract contract AttractorSolver is IAttractorSolver {
    /**
     * @notice The fixed-number precision used throughout this project.
     */
    uint8 public constant PRECISION = 96;
    uint8 internal constant PRECISION_PLUS_1 = 97;
    int256 internal constant ONE = 2**96;

    /**
     * @dev The simulation results (see `AttractorSolution`) will be stored as
     * 16-bit fixed-point values with precision 6. This implies a right shift
     * of internally used (higher-precision) values by 96-6=90.
     * Reducing the width to 16-bit at a precision of 6 futher means that the 
     * left 256-96-10=150 bits of the original (256 bit) number will be dropped.
     */
    uint256 internal constant PRECISION_REDUCTION_SAR = 90;
    uint256 internal constant RANGE_REDUCTION_SHL = 150;

    /**
     * @notice See `IAttractorSolver.getFixedPointPrecision`.
     */
    function getFixedPointPrecision() external pure override returns (uint8) {
        return PRECISION;
    }

    /**
     * @notice See `IAttractorSolver.isValidProjectionParameters`
     * @dev Performs a simple dimensionality check.
     */
    function isValidProjectionParameters(
        ProjectionParameters memory projectionParameters
    ) public pure override returns (bool) {
        return
            (projectionParameters.axis1.length == getDimensionality()) &&
            (projectionParameters.axis2.length == getDimensionality()) &&
            (projectionParameters.offset.length == getDimensionality());
    }

    /**
     * @dev Modifier checking for `isValidProjectionParameters`.
     */
    modifier onlyValidProjectionParameters(
        ProjectionParameters memory projectionParameters
    ) {
        require(
            isValidProjectionParameters(projectionParameters),
            "Invalid Projection Parameters"
        );
        _;
    }

    /**
     * @notice Compute a random number in a given `range` around zero.
     * @dev Computes deterministic PRNs based on a given input `seed`. The
     * values are distributed quasi-equally in the interval `[-range, range]`.
     * @return newSeed To be used in the next function call.
     */
    function _random(uint256 seed, int256 range)
        internal
        pure
        returns (uint256 newSeed, int256 randomNumber)
    {
        newSeed = uint256(keccak256(abi.encode(seed)));
        randomNumber = int256(newSeed);
        assembly {
            randomNumber := sub(mod(newSeed, shl(1, range)), range)
        }
    }

    /**
     * @notice See `IAttractorSolver.getDimensionality`.
     */
    function getDimensionality() public pure virtual override returns (uint8);
}

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

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolution.sol";

/**
 * @notice Parameters going to the numerical ODE solver.
 * @param numberOfIterations Total number of iterations.
 * @param dt Timestep increment in each iteration
 * @param skip Amount of iterations between storing two points.
 * @dev `numberOfIterations` has to be dividable without rest by `skip`.
 */
struct SolverParameters {
    uint256 numberOfIterations;
    uint256 dt;
    uint8 skip;
}

/**
 * @notice Parameters going to the projection routines.
 * @dev The lengths of all fields have to match the dimensionality of the
 * considered system.
 * @param axis1 First projection axis (horizontal image coordinate)
 * @param axis2 Second projection axis (vertical image coordinate)
 * @param offset Offset applied before projecting.
 */
struct ProjectionParameters {
    int256[] axis1;
    int256[] axis2;
    int256[] offset;
}

/**
 * @notice Starting point for the numerical simulation
 * @dev The length of the starting point has to match the dimensionality of the
 * considered system.
 * I agree, this struct looks kinda dumb, but I really like speaking types.
 * So as long as we don't have typedefs for non-elementary types, we are stuck
 * with this cruelty.
 */
struct StartingPoint {
    int256[] startingPoint;
}

/**
 * @notice Interface for simulators of chaotic systems.
 * @dev Implementations of this interface will contain the mathematical
 * description of the underlying differential equations, deal with its numerical
 * solution and the 2D projection of the results.
 * Implementations will internally use fixed-point numbers with a precision of
 * 96 bits by convention.
 * @author David Huber (@cxkoda)
 */
interface IAttractorSolver {
    /**
     * @notice Simulates the evolution of a chaotic system.
     * @dev This is the core piece of this class that performs everything
     * at once. All relevant algorithm for the evaluation of the ODEs
     * the numerical scheme, the projection and storage are contained within
     * this method for performance reasons.
     * @return An `AttractorSolution` containing already projected 2D points
     * and tangents to them.
     */
    function computeSolution(
        SolverParameters calldata,
        StartingPoint calldata,
        ProjectionParameters calldata
    ) external pure returns (AttractorSolution memory);

    /**
     * @notice Generates a random starting point for the system.
     */
    function getRandomStartingPoint(uint256 randomSeed)
        external
        view
        returns (StartingPoint memory);

    /**
     * @notice Generates the default projection for a given edition of the
     * system.
     */
    function getDefaultProjectionParameters(uint256 editionId)
        external
        view
        returns (ProjectionParameters memory);

    /**
     * @notice Returns the type/name of the dynamical system.
     */
    function getSystemType() external pure returns (string memory);

    /**
     * @notice Returns the dimensionality of the dynamical system (number of
     * ODEs).
     */
    function getDimensionality() external pure returns (uint8);

    /**
     * @notice Returns the precision of the internally used fixed-point numbers.
     * @dev The solvers operate on fixed-point numbers with a given PRECISION,
     * i.e. the amount of bits reserved for decimal places.
     * By convention, this method will return 96 throughout the project.
     */
    function getFixedPointPrecision() external pure returns (uint8);

    /**
     * @notice Checks if given `ProjectionParameters` are valid`
     */
    function isValidProjectionParameters(ProjectionParameters memory)
        external
        pure
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice The data struct that will be passed from the solver to the renderer.
 * @dev `points` and `tangents` both contain pairs of 16-bit fixed-point numbers
 * with a PRECISION of 6 in row-major order.`dt` is given in the fixed-point
 * respresentation used by the solvers and corresponds to the time step between 
 * the datapoints.
 */
struct AttractorSolution {
    bytes points;
    bytes tangents;
    uint256 dt;
}