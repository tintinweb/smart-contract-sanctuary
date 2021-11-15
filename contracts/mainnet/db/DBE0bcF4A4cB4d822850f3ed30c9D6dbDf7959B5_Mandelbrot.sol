// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
// All Rights Reserved
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @dev Pure-Solidity rendering of Mandelbrot and similar fractals.
 */
contract Mandelbrot is Ownable {
    /**
     * @dev Defines the fixed-point precision for non-integer numbers.
     *
     * The number 1 is represented as 1<<PRECISION, 0.5 as 1<<(PRECISION-1).
     * These values can be thought of as the binary equivalent of working in
     * cents vs dollars (100c = $1) which is the same 2 _decimal_ precision.
     *
     * Addition functions as normal. Multiplication results in twice as many
     * fractional bits so requires devision by the "dollar-equivalent":
     * 
     *   $1 × $2 = $2
     *   100c × 200c = 20,000 (extra precision) / 100 = $2
     *
     * The binary equivalent of this division is a right arithmetic shift (sar)
     * to maintain the sign. The specific value was chosen to avoid overflow
     * based on Mandelbrot escape conditions. Although it's possible to first
     * right-shift both the multiplier and multiplicand by PRECISION/2 and then
     * multiply in order to allow higher values, this changes gas from 8 to 11
     * as mul=5 and sar=3.
     */
    uint256 private constant PRECISION = 125;

    /**
     * @dev Pre-computed value for PRECISION+2.
     */
    uint256 private constant PRECISION_PLUS_2 = 127;

    /**
     * @dev The number 1 in @PRECISION fixed-point representation.
     *
     * This is useful for external callers, which should use ONE as bignum menas
     * of computing fractions.
     */
    int256 public constant ONE = 2**125;

    /**
     * @dev The number 2 in @PRECISION fixed-point representation.
     */
    int256 private constant TWO = 2**126;

    /**
     * @dev By now I think you can see the pattern.
     */
    int256 private constant FOUR = 2**127;

    /**
     * @dev You're gonna have to trust me on this one!
     */
    int256 private constant POINT_FOUR = 0xccccccccccccccccccccccccccccccc;

    /**
     * @dev Some bounds checks for inclusion in the cardioid, main bulb, etc.
     */
    int256 private constant QUARTER = 2**123;
    int256 private constant EIGHTH = 2**122;
    int256 private constant SIXTEENTH = 2**121;
    int256 private constant NEG_THREE_QUARTERS = 2**123 - 2**125;
    int256 private constant NEG_ONE_PT_TWO_FIVE = -(2**123 + 2**125);

    /**
     * @dev The number -2 in @PRECISION fixed-point representation.
     *
     * This is the lower bound of the parts of real and imaginary axes on which
     * fractals are defined.
     */
    int256 public constant NEG_TWO = -TWO;

    /**
     * @dev Supported Mandelbrot-derived fractals.
     *
     * The INVALID sentinel value MUST be last as it allows for rapid checking
     * of valid values with <.
     */
    enum Fractal {
        Mandelbrot,
        Mandelbar,
        Multi3,
        BurningShip,

        INVALID
    }

    /**
     * @dev Parameters for computing a patch in a fractal.
     */
    struct Patch {
        // Fixed-point values, not actually integers. See ONE.
        int256 minReal;
        int256 minImaginary;
        // Dimensions in pixels. Pixel width is controlled by zoomLog2.
        int256 width;
        int256 height;
        // For a full fractal, set equal width and height, and
        // zoomLog2 = log_2(width).
        int16 zoomLog2;
        uint8 maxIterations;
        Fractal fractal;
    }

    /**
     * @dev Computes escape times (pixel values) for a fractal rendering.
     *
     * These are the components that make up the final image when concatenated,
     * but are computed piecemeal to save compute time of any single call.
     */
    function patchPixels(Patch memory patch) public pure returns (bytes memory) {
        require(patch.width > 0, "Non-positive width");
        require(patch.height > 0, "Non-positive height");
        require(patch.zoomLog2 > 0, "Non-positive zoom");
        require(patch.fractal < Fractal.INVALID, "Unsupported fractal");

        // Mandelbrots are defined on [-2,2] (i.e. width 4 = 2^2), hence the use
        // of PRECISION+2. Every increment of zoomLog2 increases the
        // mangification of both axes 2× by halving the pixelWidth.
        int256 pixelWidth;
        {
            int16 zoomLog2 = patch.zoomLog2;
            assembly { pixelWidth := shl(sub(PRECISION_PLUS_2, zoomLog2), 1) }
        }
        int256 maxRe = patch.minReal + pixelWidth*patch.width;
        int256 maxIm = patch.minImaginary + pixelWidth*patch.height;

        // While this duplicates a lot of code, it saves having the if statement
        // inside the loops, which would be much less efficient.
        if (patch.fractal == Fractal.Mandelbrot) {
            return _mandelbrot(patch, pixelWidth, maxRe, maxIm);
        } else if (patch.fractal == Fractal.Mandelbar) {
            return _mandelbar(patch, pixelWidth, maxRe, maxIm);
        } else if (patch.fractal == Fractal.Multi3) {
            return _multi3(patch, pixelWidth, maxRe, maxIm);
        } else if (patch.fractal == Fractal.BurningShip) {
            return _burningShip(patch, pixelWidth, maxRe, maxIm);
        }
        // The check for patch.fractal < Fractal.INVALID makes this impossible,
        // but we still need a return value.
        return new bytes(0);
    }

    /**
     * @dev Computes the standard Mandelbrot.
     */
    function _mandelbrot(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        for (int256 cIm = patch.minImaginary; cIm < maxIm; cIm += pixelWidth) {
            for (int256 cRe = patch.minReal; cRe < maxRe; cRe += pixelWidth) {
                // Points in the Mandelbrot are expensive to compute by force
                // because they require maxIters iterations. Ruling out the two
                // largest areas adds a little more computation to other
                // regions, but is a net saving.
                //
                // From https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set#Border_tracing_/_edge_checking
                //
                // NOTE: to keep the stack small, all variable names are
                // overloaded with different meanings. It's ugly, but so be it.

                // TODO: the checks are only performed based on real ranges;
                // test if there's a benefit to computing |cIm| and limiting
                // further. At this point the speed-up is good enough to render
                // a 256x256 fairly quickly, for some subjective definition of
                // "fairly".

                // Inside the cardioid?
                if (cRe >= NEG_THREE_QUARTERS && cRe < POINT_FOUR) {
                    zRe = cRe - QUARTER;
                    zIm = cIm;
                    assembly {
                        reSq := shr(PRECISION, mul(zRe, zRe)) // (x - 1/4)^2
                        imSq := shr(PRECISION, mul(zIm, zIm)) // y^2
                        zIm := add(reSq, imSq) // q
                        zRe := add(zRe, zIm) // q + x - 1/4
                        zRe := sar(PRECISION, mul(zRe, zIm)) // q(q + x - 1/4)
                        imSq := shr(2, imSq) // y^2/4
                    }
                    if (zRe <= imSq) {
                        pixelIdx++;
                        continue;
                    }
                }
                
                // Inside the main bulb?
                if (cRe <= NEG_THREE_QUARTERS && cRe >= NEG_ONE_PT_TWO_FIVE) {
                    zRe = cRe + ONE;
                    zIm = cIm;
                    assembly {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                    }
                    if (reSq + imSq <= SIXTEENTH) {
                        pixelIdx++;
                        continue;
                    }
                }

                // Brute-force computation from here on. Variables now mean what
                // they say on the tin.

                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                zIm = cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                        
                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        zIm := add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm)))
                        zRe := add(cRe, sub(reSq, imSq))

                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Computes the "Mandelbar", taking the conjugate of z (hence bar).
     *
     * Also known as a "Tricorn". This differs from _mandelbrot() in that it has
     * no efficiency checks, initial zIm = -cIm (not cIm) and the zIm in the
     * assembly block is wrapped in sub(0, …). Each difference is noted with
     * comments.
     */
    function _mandelbar(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        for (int256 cIm = patch.minImaginary; cIm < maxIm; cIm += pixelWidth) {
            for (int256 cRe = patch.minReal; cRe < maxRe; cRe += pixelWidth) {
                // Note: there are no containment checks we can do to reduce
                // brute-force computation.

                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                // Note: the -cIm for the conjugate.
                zIm = -cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                        
                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        //
                        // Note: the sub(0, …) is the "bar" part of the fractal.
                        zIm := sub(0, add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm))))
                        zRe := add(cRe, sub(reSq, imSq))

                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Computes the 3-headed Multibrot, z_n -> z_n^4 + z_0;
     *
     * This is effectively the same as the Mandelbrot but we square z_n twice.
     * Each difference is noted with comments.
     */
    function _multi3(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        for (int256 cIm = patch.minImaginary; cIm < maxIm; cIm += pixelWidth) {
            for (int256 cRe = patch.minReal; cRe < maxRe; cRe += pixelWidth) {
                // As with the containment tests for the Mandelbrot cardioid and
                // bulb, variable names are sometimes used differently to reduce
                // stack usage. 

                assembly {
                    reSq := shr(PRECISION, mul(cRe, cRe))
                    imSq := shr(PRECISION, mul(cIm, cIm))
                    reSq := add(reSq, imSq) // |z^2|
                }
                if (reSq > FOUR) {
                    // There's odd behaviour in the [-2,-2] corner without this
                    // initial check.
                    pixels[pixelIdx] = bytes1(maxIters);
                    pixelIdx++;
                    continue;
                } else if (reSq < EIGHTH) {
                    // Multibrots have cardioid-oids (great word eh?) that grow
                    // in minimum radius as the power increases. The
                    // Mandelbrot's cardioid inverts to 0.25.
                    // 
                    // TODO: loosen this bound to rule out more computation.
                    pixelIdx++;
                    continue;
                }

                // Brute-force computation from here on. Variables now mean what
                // they say on the tin.

                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                zIm = cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))

                        // Note: instead of immediately checking for divergence,
                        // we complete z^2 and then check |z^2|^2 > 4 whereas
                        // the standard Mandelbrot checks |z|^2.
                        //
                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        //
                        // Note: unlike Mandelbrot, we don't add z_0 (c) yet.
                        zIm := sar(PRECISION, mul(add(zRe, zRe), zIm))
                        zRe := sub(reSq, imSq)
                        
                        // // Note: reSq + imSq = |z^2|^2
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))

                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // Note: same as above except adding c.
                        zIm := add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm)))
                        zRe := add(cRe, sub(reSq, imSq))

                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Computes the Burning Ship by using |Re| and |Im|.
     */
    function _burningShip(Patch memory patch, int256 pixelWidth, int256 maxRe, int256 maxIm) internal pure returns (bytes memory) {
        bytes memory pixels = new bytes(uint256(patch.width * patch.height));
        
        int256 zRe;
        int256 zIm;
        int256 reSq;
        int256 imSq;

        uint8 maxIters  = patch.maxIterations;
        uint256 pixelIdx = 0;
        // Note: the burning ship only looks like a ship when the imaginary axis
        // is flipped. Flipping the real is common too.
        for (int256 cIm = maxIm - pixelWidth; cIm >= patch.minImaginary; cIm -= pixelWidth) {
            for (int256 cRe = maxRe - pixelWidth; cRe >= patch.minReal; cRe -= pixelWidth) {
                // Technically z_0 = (0,0) but z_1 is always c, so skip that
                // iteration and eke out an extra iteration.
                zRe = cRe;
                zIm = cIm;
                uint8 pixelVal;
                assembly {
                    for { let i := 0 } lt(i, maxIters) { i := add(i, 1) } {
                        reSq := shr(PRECISION, mul(zRe, zRe))
                        imSq := shr(PRECISION, mul(zIm, zIm))
                        
                        if gt(add(reSq, imSq), FOUR) {
                            pixelVal := sub(maxIters, i)
                            i := maxIters
                        }

                        // (x+iy)^2 = (x^2 - y^2) + 2ixy
                        //
                        // mul is 5 gas but add is 3, so 2xy is mul(add(x,x),y) instead
                        // of mul(mul(x,y),2)
                        zIm := add(cIm, sar(PRECISION, mul(add(zRe, zRe), zIm)))
                        zRe := add(cRe, sub(reSq, imSq))

                        // Note: burning ship is identical to Mandelbrot except
                        // for the absolute values of real and imaginary.
                        if slt(zRe, 0) {
                            zRe := sub(0, zRe)
                        }
                        if slt(zIm, 0) {
                            zIm := sub(0, zIm)
                        }
                    } // for maxIters
                } // assembly

                pixels[pixelIdx] = bytes1(pixelVal);
                pixelIdx++;

            } // for cIm
        } // for cRe

        return pixels;
    }

    /**
     * @dev Precomputed pixels with their generating information.
     */
    struct CachedPatch {
        bytes pixels;
        Patch patch;
    }

    /**
     * @dev A cache of precomputed pixels.
     *
     * Key is patchCacheKey(patch).
     */
    mapping(uint256 => CachedPatch) public patchCache;

    /**
     * @dev Returns the key for the patchCache mapping of this patch.
     */
    function patchCacheKey(Patch memory patch) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(patch)));
    }

    /**
     * @dev Cache a precomputed patch of pixels.
     *
     * See verifyCachedPatch().
     */
    function cachePatch(bytes memory pixels, Patch memory patch) public onlyOwner {
        require(pixels.length == uint256(patch.width * patch.height), "Invalid dimensions");
        patchCache[patchCacheKey(patch)] = CachedPatch(pixels, patch);
    }

    /**
     * @dev Returns a cached patch, confirming existence.
     *
     * As mappings always return a value, width and height both > 0 is used as
     * a proxy for the patch having been cached. Those with 0 area are
     * redundant anyway.
     */
    function cachedPatch(uint256 cacheIdx) public view returns (CachedPatch memory) {
        CachedPatch memory cached = patchCache[cacheIdx];
        require(cached.patch.width > 0 && cached.patch.height > 0, "Patch not cached");
        return cached;
    }

    /**
     * @dev Recompute pixels for a patch and confirm that they match the cache.
     *
     * This contract works on a trust-but-verify model. If patchPixels() were to
     * be used in a transaction, the gas fee would make the entire project
     * infeasible. Instead, it's only used in (free, read-only) calls, and the
     * returned values are stored via cachePatch(), which is cheaper. It's
     * possible to recompute the patch at any time via another free call to
     * verifyCachedPatch().
     */
    function verifyCachedPatch(uint256 cacheIdx) public view returns (bool) {
        CachedPatch memory cached = cachedPatch(cacheIdx);
        bytes memory fresh = patchPixels(cached.patch);
        return keccak256(fresh) == keccak256(cached.pixels);
    }

    /**
     * @dev Returns a concatenated pixel buffer of cached patches.
     */
    function concatenatePatches(uint256[] memory patches) public view returns (bytes memory) {
        CachedPatch[] memory cached = new CachedPatch[](patches.length);

        uint256 len;
        for (uint i = 0; i < patches.length; i++) {
            cached[i] = cachedPatch(patches[i]);
            len += cached[i].pixels.length;
        }

        bytes memory buf = new bytes(len);
        uint idx;
        for (uint i = 0; i < cached.length; i++) {
            for (uint j = 0; j < cached[i].pixels.length; j++) {
                buf[idx] = cached[i].pixels[j];
                idx++;
            }
        }
        return buf;
    }
}

