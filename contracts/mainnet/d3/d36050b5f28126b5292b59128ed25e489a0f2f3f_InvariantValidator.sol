/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity 0.8.0;


interface MassetStructs {
    struct BassetPersonal {
        // Address of the bAsset
        address addr;
        // Address of the bAsset
        address integrator;
        // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
        bool hasTxFee; // takes a byte in storage
        // Status of the bAsset
        BassetStatus status;
    }

    struct BassetData {
        // 1 Basset * ratio / ratioScale == x Masset (relative value)
        // If ratio == 10e8 then 1 bAsset = 10 mAssets
        // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
        uint128 ratio;
        // Amount of the Basset that is held in Collateral
        uint128 vaultBalance;
    }

    // Status of the Basset - has it broken its peg?
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    struct BasketState {
        bool undergoingRecol;
        bool failed;
    }

    struct InvariantConfig {
        uint256 a;
        WeightLimits limits;
    }

    struct WeightLimits {
        uint128 min;
        uint128 max;
    }

    struct AmpData {
        uint64 initialA;
        uint64 targetA;
        uint64 rampStartTime;
        uint64 rampEndTime;
    }
}

abstract contract IInvariantValidator is MassetStructs {
    // Mint
    function computeMint(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint256 _rawInput,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);

    function computeMintMulti(
        BassetData[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _rawInputs,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);

    // Swap
    function computeSwap(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint8 _o,
        uint256 _rawInput,
        uint256 _feeRate,
        InvariantConfig memory _config
    ) external view virtual returns (uint256, uint256);

    // Redeem
    function computeRedeem(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint256 _mAssetQuantity,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);

    function computeRedeemExact(
        BassetData[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _rawOutputs,
        InvariantConfig memory _config
    ) external view virtual returns (uint256);
}

library Root {
    /**
     * @dev Returns the square root of a given number
     * @param x Input
     * @return y Square root of Input
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint256(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
/**
 * @title   InvariantValidator
 * @author  mStable
 * @notice  Builds on and enforces the StableSwap invariant conceived by Michael Egorov. (https://www.curve.fi/stableswap-paper.pdf)
 *          Derived by mStable and adapted for the needs of an mAsset, as described in MIP-7 (http://mips.mstable.org/MIPS/mip-7)
 *          Calculates and validates the result of Masset operations with respect to the invariant.
 *          This supports low slippage swaps and applies penalties towards min and max regions.
 * @dev     VERSION: 1.0
 *          DATE:    2021-02-04
 */
contract InvariantValidator is IInvariantValidator {
    uint256 internal constant A_PRECISION = 100;

    // Data used for determining max TVL during guarded launch
    uint256 public immutable startTime;
    uint256 public immutable startingCap;
    uint256 public immutable capFactor;

    constructor(uint256 _startingCap, uint256 _capFactor) {
        startTime = block.timestamp;
        startingCap = _startingCap;
        capFactor = _capFactor;
    }

    /***************************************
                    EXTERNAL
    ****************************************/

    /**
     * @notice Compute the amount of mAsset received for minting
     * with `quantity` amount of bAsset index `i`.
     * @param _bAssets      Array of all bAsset Data
     * @param _i            Index of bAsset with which to mint
     * @param _rawInput     Raw amount of bAsset to use in mint
     * @param _config       Generalised invariantConfig stored externally
     * @return mintAmount   Quantity of mAssets minted
     */
    function computeMint(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint256 _rawInput,
        InvariantConfig memory _config
    ) external view override returns (uint256 mintAmount) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        uint256 scaledInput = (_rawInput * _bAssets[_i].ratio) / 1e8;

        // 3. Add deposit to x and sum
        x[_i] += scaledInput;
        sum += scaledInput;
        // 4. Finalise mint
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        mintAmount = _computeMintOutput(x, sum, k0, _config.a);
    }

    /**
     * @notice Compute the amount of mAsset received for minting
     * with the given array of inputs.
     * @param _bAssets      Array of all bAsset Data
     * @param _indices      Indexes of bAssets with which to mint
     * @param _rawInputs    Raw amounts of bAssets to use in mint
     * @param _config       Generalised invariantConfig stored externally
     * @return mintAmount   Quantity of mAssets minted
     */
    function computeMintMulti(
        BassetData[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _rawInputs,
        InvariantConfig memory _config
    ) external view override returns (uint256 mintAmount) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);

        // 3. Add deposits to x and sum
        uint256 len = _indices.length;
        uint8 idx;
        uint256 scaledInput;
        for (uint256 i = 0; i < len; i++) {
            idx = _indices[i];
            scaledInput = (_rawInputs[i] * _bAssets[idx].ratio) / 1e8;
            x[idx] += scaledInput;
            sum += scaledInput;
        }
        // 4. Finalise mint
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        mintAmount = _computeMintOutput(x, sum, k0, _config.a);
    }

    /**
     * @notice Compute the amount of bAsset received for swapping
     * `quantity` amount of index `input_idx` to index `output_idx`.
     * @param _bAssets      Array of all bAsset Data
     * @param _i            Index of bAsset to swap IN
     * @param _o            Index of bAsset to swap OUT
     * @param _rawInput     Raw amounts of input bAsset to input
     * @param _feeRate      Swap fee rate to apply to output
     * @param _config       Generalised invariantConfig stored externally
     * @return bAssetOutputQuantity   Raw bAsset output quantity
     * @return scaledSwapFee          Swap fee collected, in mAsset terms
     */
    function computeSwap(
        BassetData[] calldata _bAssets,
        uint8 _i,
        uint8 _o,
        uint256 _rawInput,
        uint256 _feeRate,
        InvariantConfig memory _config
    ) external view override returns (uint256 bAssetOutputQuantity, uint256 scaledSwapFee) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Add deposits to x and sum
        uint256 scaledInput = (_rawInput * _bAssets[_i].ratio) / 1e8;
        x[_i] += scaledInput;
        sum += scaledInput;
        // 4. Calc total mAsset q
        uint256 k1 = _invariant(x, sum, _config.a);
        scaledSwapFee = ((k1 - k0) * _feeRate) / 1e18;
        // 5. Calc output bAsset
        uint256 newOutputReserve = _solveInvariant(x, _config.a, _o, k0 + scaledSwapFee);
        uint256 output = x[_o] - newOutputReserve - 1;
        bAssetOutputQuantity = (output * 1e8) / _bAssets[_o].ratio;
        // 6. Check for bounds
        x[_o] -= output;
        sum -= output;
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
    }

    /**
     * @notice Compute the amount of bAsset index `i` received for
     * redeeming `quantity` amount of mAsset.
     * @param _bAssets              Array of all bAsset Data
     * @param _o                    Index of output bAsset
     * @param _netMassetQuantity    Net amount of mAsset to redeem
     * @param _config               Generalised invariantConfig stored externally
     * @return rawOutputUnits       Raw bAsset output returned
     */
    function computeRedeem(
        BassetData[] calldata _bAssets,
        uint8 _o,
        uint256 _netMassetQuantity,
        InvariantConfig memory _config
    ) external view override returns (uint256 rawOutputUnits) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Compute bAsset output
        uint256 newOutputReserve = _solveInvariant(x, _config.a, _o, k0 - _netMassetQuantity);
        uint256 output = x[_o] - newOutputReserve - 1;
        rawOutputUnits = (output * 1e8) / _bAssets[_o].ratio;
        // 4. Check for max weight
        x[_o] -= output;
        sum -= output;
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
    }

    /**
     * @notice Compute the amount of mAsset required to redeem
     * a given selection of bAssets.
     * @param _bAssets          Array of all bAsset Data
     * @param _indices          Indexes of output bAssets
     * @param _rawOutputs       Desired raw bAsset outputs
     * @param _config           Generalised invariantConfig stored externally
     * @return totalmAssets     Amount of mAsset required to redeem bAssets
     */
    function computeRedeemExact(
        BassetData[] calldata _bAssets,
        uint8[] calldata _indices,
        uint256[] calldata _rawOutputs,
        InvariantConfig memory _config
    ) external view override returns (uint256 totalmAssets) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Sub deposits from x and sum
        uint256 len = _indices.length;
        uint256 ratioed;
        for (uint256 i = 0; i < len; i++) {
            ratioed = (_rawOutputs[i] * _bAssets[_indices[i]].ratio) / 1e8;
            x[_indices[i]] -= ratioed;
            sum -= ratioed;
        }
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        // 4. Get new value of reserves according to invariant
        uint256 k1 = _invariant(x, sum, _config.a);
        // 5. Total mAsset is the difference between values
        totalmAssets = k0 - k1;
    }

    /***************************************
                    INTERNAL
    ****************************************/

    /**
     * @dev Computes the actual mint output after adding mint inputs
     * to the vault balances. Also checks that tvl cap does not exceed
     * the cap, during guarded launch period.
     * @param _x            Scaled vaultBalances
     * @param _sum          Sum of vaultBalances, to avoid another loop
     * @param _k            Previous value of invariant, k, before addition
     * @param _a                Precise amplification coefficient
     * @return mintAmount   Amount of value added to invariant, in mAsset terms
     */
    function _computeMintOutput(
        uint256[] memory _x,
        uint256 _sum,
        uint256 _k,
        uint256 _a
    ) internal view returns (uint256 mintAmount) {
        // 1. Get value of reserves according to invariant
        uint256 kFinal = _invariant(_x, _sum, _a);
        // 2. Guarded launch - ensure TVL cap is not hit
        // e.g. 10 days after launch
        // e.g. 864000e18 / 86400 = 1.4e18 (1.4 weeks)
        uint256 weeksSinceLaunch = ((block.timestamp - startTime) * 1e18) / 604800;
        if (weeksSinceLaunch < 7e18) {
            // e.g. 1e19 + (15e18 * 2.04e36) = 1e19 + 3.06e55
            uint256 maxK = startingCap + ((capFactor * (weeksSinceLaunch**2)) / 1e36);
            require(kFinal <= maxK, "Cannot exceed TVL cap");
        }
        // 3. Total minted is the difference between values
        mintAmount = kFinal - _k;
    }

    /**
     * @dev Simply scaled raw reserve values and returns the sum
     * @param _bAssets  All bAssets
     * @return x        Scaled vault balances
     * @return sum      Sum of scaled vault balances
     */
    function _getReserves(BassetData[] memory _bAssets)
        internal
        pure
        returns (uint256[] memory x, uint256 sum)
    {
        uint256 len = _bAssets.length;
        x = new uint256[](len);
        uint256 r;
        for (uint256 i = 0; i < len; i++) {
            BassetData memory bAsset = _bAssets[i];
            r = (bAsset.vaultBalance * bAsset.ratio) / 1e8;
            x[i] = r;
            sum += r;
        }
    }

    /**
     * @dev Checks that no bAsset reserves exceed max weight
     * @param _x            Scaled bAsset reserves
     * @param _sum          Sum of x, precomputed
     * @param _limits       Config object containing max and min weights
     * @return inBounds     Bool, true if all assets are within bounds
     */
    function _inBounds(
        uint256[] memory _x,
        uint256 _sum,
        WeightLimits memory _limits
    ) internal pure returns (bool inBounds) {
        uint256 len = _x.length;
        inBounds = true;
        uint256 w;
        for (uint256 i = 0; i < len; i++) {
            w = (_x[i] * 1e18) / _sum;
            if (w > _limits.max || w < _limits.min) return false;
        }
    }

    /***************************************
                    INVARIANT
    ****************************************/

    /**
     * @dev Compute the invariant f(x) for a given array of supplies `x`.
     * @param _x        Scaled vault balances
     * @param _sum      Sum of scaled vault balances
     * @param _a        Precise amplification coefficient
     * @return k        Cumulative value of all assets according to the invariant
     */
    function _invariant(
        uint256[] memory _x,
        uint256 _sum,
        uint256 _a
    ) internal pure returns (uint256 k) {
        uint256 len = _x.length;

        if (_sum == 0) return 0;

        uint256 nA = _a * len;
        uint256 kPrev;
        k = _sum;

        for (uint256 i = 0; i < 256; i++) {
            uint256 kP = k;
            for (uint256 j = 0; j < len; j++) {
                kP = (kP * k) / (_x[j] * len);
            }
            kPrev = k;
            k =
                (((nA * _sum) / A_PRECISION + (kP * len)) * k) /
                (((nA - A_PRECISION) * k) / A_PRECISION + ((len + 1) * kP));
            if (_hasConverged(k, kPrev)) {
                return k;
            }
        }

        revert("Invariant did not converge");
    }

    /**
     * @dev Checks if a given solution has converged within a factor of 1
     * @param _k              Current solution k
     * @param _kPrev          Previous iteration solution
     * @return hasConverged   Bool, true if diff abs(k, kPrev) <= 1
     */
    function _hasConverged(uint256 _k, uint256 _kPrev) internal pure returns (bool) {
        if (_kPrev > _k) {
            return (_kPrev - _k) <= 1;
        } else {
            return (_k - _kPrev) <= 1;
        }
    }

    /**
     * @dev Solves the invariant for _i with respect to target K, given an array of reserves.
     * @param _x        Scaled reserve balances
     * @param _a        Precise amplification coefficient
     * @param _idx      Index of asset for which to solve
     * @param _targetK  Target invariant value K
     * @return y        New reserve of _i
     */
    function _solveInvariant(
        uint256[] memory _x,
        uint256 _a,
        uint8 _idx,
        uint256 _targetK
    ) internal pure returns (uint256 y) {
        uint256 len = _x.length;
        require(_idx >= 0 && _idx < len, "Invalid index");

        (uint256 sum_, uint256 nA, uint256 kP) = (0, _a * len, _targetK);

        for (uint256 i = 0; i < len; i++) {
            if (i != _idx) {
                sum_ += _x[i];
                kP = (kP * _targetK) / (_x[i] * len);
            }
        }

        uint256 c = (((kP * _targetK) * A_PRECISION) / nA) / len;
        uint256 g = (_targetK * (nA - A_PRECISION)) / nA;
        uint256 b = 0;

        if (g > sum_) {
            b = g - sum_;
            y = (Root.sqrt((b**2) + (4 * c)) + b) / 2 + 1;
        } else {
            b = sum_ - g;
            y = (Root.sqrt((b**2) + (4 * c)) - b) / 2 + 1;
        }

        if (y < 1e8) revert("Invalid solution");
    }
}