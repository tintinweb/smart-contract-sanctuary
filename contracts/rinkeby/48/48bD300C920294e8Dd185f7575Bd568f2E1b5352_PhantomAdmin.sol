/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Imports */
import {PhantomStorageMixin} from "PhantomStorageMixin.sol";

/**
 * @title PhantomAdmin
 */
contract PhantomAdmin is PhantomStorageMixin {
    constructor(address storageAddress) PhantomStorageMixin(storageAddress) {
        return;
    }

    function enableDebugMode() external {
        PhantomStorage().setBool(keccak256(abi.encodePacked("phantom.debug")), true);
    }

    function disableDebugMode() external {
        PhantomStorage().setBool(keccak256(abi.encodePacked("phantom.debug")), false);
    }

    function debugModeStatus() external view returns (bool) {
        return PhantomStorage().getBool(keccak256(abi.encodePacked("phantom.debug")));
    }

    //=================================================================================================================
    // Staking
    //=================================================================================================================

    function updateStakingRewardRate(uint256 newRewardRate) external {
        sPHM().updateRewardRate(newRewardRate);
    }

    function updateStakingCompoundingPeriodsPerYear(uint256 numPeriods) external {
        sPHM().updateCompoundingPeriodsPeriodYear(numPeriods);
    }

    //=================================================================================================================
    // Bonding
    //=================================================================================================================

    /**
    @notice % Add/Remove tokens from being bondable
    */
    function addTokenToBondingList(address inToken) public {
        PhantomStorage().setBool(keccak256(abi.encodePacked("phantom.bonding.type.is_valid", inToken)), true);
    }

    function addMultipleTokensToBondingList(address[] calldata inTokens) external {
        for (uint256 i = 0; i < inTokens.length; i += 1) {
            addTokenToBondingList(inTokens[i]);
        }
    }

    function removeTokenFromBondingList(address inToken) public {
        PhantomStorage().deleteBool(keccak256(abi.encodePacked("phantom.bonding.type.is_valid", inToken)));
    }

    function removeMultipleTokensToBondingList(address[] calldata inTokens) external {
        for (uint256 i = 0; i < inTokens.length; i += 1) {
            removeTokenFromBondingList(inTokens[i]);
        }
    }

    function isValidTokenForBond(address inToken) external view returns (bool) {
        return PhantomStorage().getBool(keccak256(abi.encodePacked("phantom.bonding.type.is_valid", inToken)));
    }

    //=================================================================================================================
    // Bond Types (Lengths)
    //=================================================================================================================

    /**
    @notice Add a new bondtype with vesting length in seconds
    */
    function addBondType(bytes calldata bondType, uint256 vestInSeconds) external {
        PhantomStorage().setBool(keccak256(abi.encodePacked("phantom.bonding.type.is_valid", bondType)), true);
        PhantomStorage().setUint(
            keccak256(abi.encodePacked("phantom.bonding.type.vest_length", bondType)),
            vestInSeconds
        );
    }

    /**
    @notice Remove a bond type
    */
    function removeBondType(bytes calldata bondType) external {
        PhantomStorage().deleteBool(keccak256(abi.encodePacked("phantom.bonding.type.is_valid", bondType)));
        PhantomStorage().deleteUint(keccak256(abi.encodePacked("phantom.bonding.type.vest_length", bondType)));
    }

    /**
    @notice Get info about a bond type
    */
    function infoOfBondType(bytes calldata bondType) external view returns (bool, uint256) {
        bool isValid = PhantomStorage().getBool(keccak256(abi.encodePacked("phantom.bonding.type.is_valid", bondType)));
        uint256 vestInBlocks = PhantomStorage().getUint(
            keccak256(abi.encodePacked("phantom.bonding.type.vest_length", bondType))
        );
        return (isValid, vestInBlocks);
    }

    //=================================================================================================================
    // Bond Multipliers
    //=================================================================================================================

    // 18 decimals 1e18 = 1x, 2e18 = 2x/100%, 3e18 = 3x/200%
    function setBondingMultiplierFor(
        bytes calldata inBondType,
        address inToken,
        uint256 value
    ) external {
        PhantomStorage().setUint(keccak256(abi.encodePacked("phantom.bonding.multiplier", inBondType, inToken)), value);
    }

    function bondingMultiplierFor(bytes calldata inBondType, address inToken) external view returns (uint256) {
        return PhantomStorage().getUint(keccak256(abi.encodePacked("phantom.bonding.multiplier", inBondType, inToken)));
    }
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import {PRBMathUD60x18} from "PRBMathUD60x18.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

/* Internal Imports */
import {PhantomStorageKeys} from "PhantomStorageKeys.sol";

/* Internal Interface Imports */
import {IPHM} from "IPHM.sol";
import {IsPHM} from "IsPHM.sol";
import {IgPHM} from "IgPHM.sol";
import {IPhantomAlphaSwap} from "IPhantomAlphaSwap.sol";
import {IPhantomBonding} from "IPhantomBonding.sol";
import {IPhantomFounders} from "IPhantomFounders.sol";
import {IPhantomSpiritRouter} from "IPhantomSpiritRouter.sol";
import {IPhantomStaking} from "IPhantomStaking.sol";
import {IPhantomStorage} from "IPhantomStorage.sol";
import {IPhantomTreasury} from "IPhantomTreasury.sol";
import {IPhantomVault} from "IPhantomVault.sol";
import {IPhantomStorageFactory} from "IPhantomStorageFactory.sol";
import {IPhantomStorageMixin} from "IPhantomStorageMixin.sol";

/**
 * @title PhantomStorageMixin
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice A Mixin used to provide access to all Phantom contracts with a base set of behaviour
 */
contract PhantomStorageMixin is PhantomStorageKeys, ReentrancyGuard, IPhantomStorageMixin {
    //=================================================================================================================
    // State Variables
    //=================================================================================================================

    uint256 constant ONE_18D = 1e18;
    address internal _storageAddress;
    bytes32 phantomStorage = "phantomStorage";

    // uint256 public contractVersion;

    function PhantomStorage() internal view returns (IPhantomStorage) {
        return IPhantomStorage(_storageAddress);
    }

    // uint256 public contractVersion;

    //=================================================================================================================
    // Constructor
    //=================================================================================================================

    constructor(address storageAddress) {
        _storageAddress = storageAddress;
    }

    //=================================================================================================================
    // Internal Functons
    //=================================================================================================================

    function getContractAddressByName(bytes32 contractName, bytes32 storageContractName)
        internal
        view
        returns (address)
    {
        address contractAddress = PhantomStorage().getAddress(
            keccak256(abi.encodePacked(PhantomStorageKeys.security.addressof, contractName))
        );
        if (contractAddress == address(0x0))
            revert PhantomStorageMixin__ContractNotFoundByNameOrIsOutdated(contractName);
        return contractAddress;
    }

    function PHM() internal view returns (IPHM) {
        return IPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.phm)));
    }

    function sPHM() internal view returns (IsPHM) {
        return IsPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.sphm)));
    }

    function gPHM() internal view returns (IgPHM) {
        return IgPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.gphm)));
    }

    function aPHM() internal view returns (IgPHM) {
        return IgPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.aphm)));
    }

    function fPHM() internal view returns (IgPHM) {
        return IgPHM(PhantomStorage().getAddress(keccak256(phantom.contracts.fphm)));
    }

    function PhantomTreasury() internal view returns (IPhantomTreasury) {
        return IPhantomTreasury(PhantomStorage().getAddress(keccak256(phantom.contracts.treasury)));
    }

    function PhantomSpiritRouter() internal view returns (IPhantomSpiritRouter) {
        return IPhantomSpiritRouter(PhantomStorage().getAddress(keccak256(phantom.contracts.spirit_router)));
    }

    function PhantomStaking() internal view returns (IPhantomStaking) {
        return IPhantomStaking(PhantomStorage().getAddress(keccak256(phantom.contracts.staking)));
    }

    function PhantomAlphaSwap() internal view returns (IPhantomAlphaSwap) {
        return IPhantomAlphaSwap(PhantomStorage().getAddress(keccak256(phantom.contracts.alphaswap)));
    }

    function PhantomFounders() internal view returns (IPhantomFounders) {
        return IPhantomFounders(PhantomStorage().getAddress(keccak256(phantom.contracts.founders)));
    }

    function PhantomBonding() internal view returns (IPhantomBonding) {
        return IPhantomBonding(PhantomStorage().getAddress(keccak256(phantom.contracts.bonding)));
    }

    function PhantomVault() internal view returns (IPhantomVault) {
        return IPhantomVault(PhantomStorage().getAddress(keccak256(phantom.contracts.vault)));
    }

    function standardAccountKeys() internal view returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](3);
        keys[0] = keccak256(phantom.treasury.account_keys.reserves);
        keys[1] = keccak256(phantom.treasury.account_keys.dao);
        keys[2] = keccak256(phantom.treasury.account_keys.venturecapital);
        return keys;
    }

    function standardAccountPercentages() internal pure returns (uint256[] memory) {
        uint256[] memory percentages = new uint256[](3);
        percentages[0] = ((0.85e18)); // reserves
        percentages[1] = ((0.05e18)); // dao
        percentages[2] = ((0.10e18)); // venturecapital
        return percentages;
    }

    function reserveKey() internal view returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](1);
        keys[0] = keccak256(phantom.treasury.account_keys.reserves);
        return keys;
    }

    function percentage100() internal pure returns (uint256[] memory) {
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = (1e18);
        return percentages;
    }

    //=================================================================================================================
    // Modifiers
    //=================================================================================================================

    modifier onlyRegisteredContracts() {
        if (!PhantomStorage().getBool(keccak256(abi.encodePacked("phantom.contract.registered", msg.sender))))
            revert PhantomStorageMixin__ContractNotFoundByAddressOrIsOutdated(msg.sender);
        _;
    }

    modifier onlyContract(
        bytes32 contractName,
        address inAddress,
        bytes32 storageContractName
    ) {
        if (
            inAddress !=
            PhantomStorage().getAddress(keccak256(abi.encodePacked(PhantomStorageKeys.security.name, contractName)))
        ) revert PhantomStorageMixin__ContractNotFoundByNameOrIsOutdated(contractName);
        _;
    }

    modifier onlyFromStorageGuardianOf(bytes32 storageContractName) {
        if (msg.sender != PhantomStorage().getGuardian()) revert PhantomStorageMixin__UserIsNotGuardian(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title PhantomStorageKeys
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Stores keys to use for lookup in the PhantomStorage() contract
 */
abstract contract PhantomStorageKeys {
    //=================================================================================================================
    // Declarations
    //=================================================================================================================

    _security internal security = _security("security.addressof", "security.name", "security.registered");

    _phantom internal phantom =
        _phantom(
            _contracts(
                "phantom.contracts.alphaswap",
                "phantom.contracts.founders",
                "phantom.contracts.staking",
                "phantom.contracts.stakingwarmup",
                "phantom.contracts.bonding",
                "phantom.contracts.phm",
                "phantom.contracts.sphm",
                "phantom.contracts.gphm",
                "phantom.contracts.aphm",
                "phantom.contracts.fphm",
                "phantom.contracts.vault",
                "phantom.contracts.treasury",
                "phantom.contracts.spirit_router",
                "phantom.contracts.yearn_router",
                "phantom.contracts.executor"
            ),
            _treasury(
                "phantom.treasury.approved.external.address",
                _treasuryaccounts(
                    "phantom.treasury.account_key.venturecapital",
                    "phantom.treasury.account_key.dao",
                    "phantom.treasury.account_key.reserves"
                ),
                "phantom.treasury.balance"
            ),
            _allocator(
                _tokens(
                    _token_addresses(
                        "phantom.allocator.tokens.address.dai",
                        "phantom.allocator.tokens.address.wftm",
                        "phantom.allocator.tokens.address.mim",
                        "phantom.allocator.tokens.address.dai_phm_lp",
                        "phantom.allocator.tokens.address.spirit"
                    ),
                    "phantom.allocator.tokens.destinations",
                    "phantom.allocator.tokens.dest_percentages",
                    "phantom.allocator.tokens.lp",
                    "phantom.allocator.tokens.single"
                )
            ),
            _bonding(
                _bonding_user("phantom.bonding.user.nonce", "phantom.bonding.user.first_unredeemed_nonce"),
                "phantom.bonding.vestingblocks",
                "phantom.bonding.discount",
                "phantom.bonding.is_redeemed",
                "phantom.bonding.payout",
                "phantom.bonding.vests_at_block",
                "phantom.bonding.is_valid"
            ),
            _staking("phantom.staking.rebaseCounter", "phantom.staking.nextRebaseDeadline"),
            _founder(
                _founder_claims(
                    "phantom.founder.claims.initialAmount",
                    "phantom.founder.claims.remainingAmount",
                    "phantom.founder.claims.lastClaim"
                ),
                _founder_wallet_changes("phantom.founder.changes.newOwner"),
                "phantom.founder.vestingStarts"
            ),
            _routing(
                "phantom.routing.spirit_router_address",
                "phantom.routing.spirit_factory_address",
                "phantom.routing.spirit_gauge_address",
                "phantom.routing.spirit_gauge_proxy_address"
            ),
            _governor(
                "phantom.governor.votingDelay",
                "phantom.governor.votingPeriod",
                "phantom.governor.quorumPercentage",
                "phantom.governor.proposalThreshold"
            )
        );

    //=================================================================================================================
    // Definitions
    //=================================================================================================================

    struct _security {
        bytes addressof;
        bytes name;
        bytes registered;
    }

    struct _phantom {
        _contracts contracts;
        _treasury treasury;
        _allocator allocator;
        _bonding bonding;
        _staking staking;
        _founder founder;
        _routing routing;
        _governor governor;
    }

    struct _treasury {
        bytes approved_address;
        _treasuryaccounts account_keys;
        bytes balances;
    }

    struct _allocator {
        _tokens tokens;
    }

    struct _tokens {
        _token_addresses addresses;
        bytes destinations;
        bytes dest_percentage;
        bytes lp;
        bytes single;
    }

    struct _token_addresses {
        bytes dai;
        bytes wftm;
        bytes mim;
        bytes dai_phm_lp;
        bytes spirit;
    }

    struct _treasuryaccounts {
        bytes venturecapital;
        bytes dao;
        bytes reserves;
    }

    struct _vault {
        bytes something;
    }

    struct _routing {
        bytes spirit_router_address;
        bytes spirit_factory_address;
        bytes spirit_gauge_address;
        bytes spirit_gauge_proxy_address;
    }

    struct _bonding_user {
        bytes nonce;
        bytes first_unredeemed_nonce;
    }

    struct _bonding {
        _bonding_user user;
        bytes vestingblocks;
        bytes discount;
        bytes is_redeemed;
        bytes payout;
        bytes vests_at_block;
        bytes is_valid;
    }

    struct _staking {
        bytes rebaseCounter;
        bytes nextRebaseDeadline;
    }

    struct _founder {
        _founder_claims claims;
        _founder_wallet_changes changes;
        bytes vestingStarts;
    }

    struct _founder_claims {
        bytes initialAmount;
        bytes remainingAmount;
        bytes lastClaim;
    }

    struct _founder_wallet_changes {
        bytes newOwner;
    }

    struct _contracts {
        bytes alphaswap;
        bytes founders;
        bytes staking;
        bytes stakingwarmup;
        bytes bonding;
        bytes phm;
        bytes sphm;
        bytes gphm;
        bytes aphm;
        bytes fphm;
        bytes vault;
        bytes treasury;
        bytes spirit_router;
        bytes yearn_router;
        bytes executor;
    }

    struct _governor {
        bytes votingDelay;
        bytes votingPeriod;
        bytes quorumPercentage;
        bytes proposalThreshold;
    }
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "IPhantomERC20.sol";

/**
 * @title IPHM
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IPHM
 */
interface IPHM is IPhantomERC20 {
    function balanceAllDenoms(address user) external view returns(uint256);
    function maxBalancePerWallet() external view returns (uint256);

}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* External Interface Imports */
import {IERC20} from "IERC20.sol";
import {IERC20Permit} from "draft-IERC20Permit.sol";

/**
 * @title IgPHM
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IPhantomERC20
 */
interface IPhantomERC20 is IERC20, IERC20Permit {
    /**
     * @dev mint new tokens
     * @param toUser the owner of the new tokens
     * @param inAmount number of new tokens to be minted
     */
    function mint(address toUser, uint256 inAmount) external;

    /**
     * @dev burn a user's tokens
     * @param fromUser the user whos tokens are to be burned
     * @param inAmount the number of tokens to burn
     */
    function burn(address fromUser, uint256 inAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "IPhantomERC20.sol";

/**
 * @title IsPHM
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IsPHM
 */
interface IsPHM is IPhantomERC20 {

    event Phantom_Rebase(uint256 epochNumber, uint256 rewardYield, uint256 scalingFactor);
    event Phantom_RewardRateUpdate(uint256 oldRewardRate, uint256 newRewardRate);

    function doRebase(uint256 epochNumber) external;
    function updateCompoundingPeriodsPeriodYear(uint256 numPeriods) external;
    function updateRewardRate(uint256 numRewardRate) external;
    function interestPerPeriod() external view returns(uint256);
    function periodsPerYear() external view returns(uint256);
    function secondsPerCompoundingPeriod() external view returns(uint256);
    function scalingFactor() external view returns(uint256);

}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Import */
import {IPhantomERC20} from "IPhantomERC20.sol";

/**
 * @title IgPHM
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IgOHM
 */
interface IgPHM is IPhantomERC20 {

    function enableTransfers() external;
    function balanceFromPHM(uint256 ammount) external view returns (uint256);
    function balanceToPHM(uint256 ammount) external view returns (uint256);
     
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomAlphaSwap
 * @author botulin
 * @notice The Interface for PhantomAlphaSwap
 */
interface IPhantomAlphaSwap {
    function swap(address claimer, uint256 amount) external;
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */


/**
 * @title IPhantomBonding
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IPhantomBonding
 */
interface IPhantomBonding {
    event PhantomBonding_BondCreated(address forUser, uint256 payout, uint256 nonce);
    event PhantomBonding_BondRedeemed(address forUser, uint256 payout, uint256 nonce);
    error PhantomBondingError_IsNotValidBondingToken(address inToken);
    error PhantomBondingError_ExceedsDebtLimit();
    function createBond(address inBonder, uint256 inAmount, address inToken, bytes calldata inBondType) external returns(uint256);
    function redeemBonds(address inBonder, bool autoStake) external returns(uint256);
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomFounders
 * @author botulin
 * @notice The Inteface for PhantomFounders
 */
interface IPhantomFounders {

    /**
     * @dev set the start date for vesting
     */
    function startVesting() external;

    /**
     * @dev add a foudner's wallet to the whitelist with an amount of tokens
     */
    function registerFounder(address founder, uint256 amount) external;

    /**
     * @dev claim fPHM
     */
    function claim(address founder) external;

    /**
     * @dev swap vested fPHM for gPHM
     */
    function exercise(address founder) external;

}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomSpiritRouter
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Interface of PhantomSpiritRouter
 */
interface IPhantomSpiritRouter {

    function getQuote(
        uint256 inAmount,
        address inToken,
        address outToken
    ) external view returns (uint256);

    function swapReceiveMinimum(
        uint256 inAmount,
        uint256 minOutAmount,
        address[] memory path,
        address toUser,
        uint256 deadline,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    function swapSpendMaximum(
        uint256 outAmount,
        uint256 maxInAmount,
        address[] memory path,
        address toUser,
        uint256 deadline,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomStaking
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for PhantomGovernor
 */
interface IPhantomStaking {
    function stake(address inStaker, uint256 inAmount) external;
    function unstake(address inUnstaker, uint256 inAmount) external;
    function wrap(address toUser, uint256 amount) external returns(uint256);
    function unwrap(address toUser, uint256 amount) external returns(uint256);
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/**
 * @title IPhantomStorage
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface of PhantomStorage()
 */
interface IPhantomStorage {

    //=================================================================================================================
    // Errors
    //=================================================================================================================
    
    error PhantomStorage__ContractNotRegistered(address contractAddress);
    error PhantomStorage__NotStorageGuardian(address user);
    error PhantomStorage__NoGuardianInvitation(address user);

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event ContractRegistered(address contractRegistered);
    event GuardianChanged(address oldStorageGuardian, address newStorageGuardian);

    //=================================================================================================================
    // Deployment Status
    //=================================================================================================================

    function getDeployedStatus() external view returns (bool);
    function registerContract(bytes calldata contractName, address contractAddress) external;
    function unregisterContract(bytes calldata contractName) external;

    //=================================================================================================================
    // Guardian
    //=================================================================================================================

    function getGuardian() external view returns(address);
    function sendGuardianInvitation(address _newAddress) external;
    function acceptGuardianInvitation() external;

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    function getAddressArray(bytes32 _key) external view returns (address[] memory);
    function getUintArray(bytes32 _key) external view returns (uint[] memory);
    function getStringArray(bytes32 _key) external view returns (string[] memory);
    function getBytesArray(bytes32 _key) external view returns (bytes[] memory);
    function getBoolArray(bytes32 _key) external view returns (bool[] memory);
    function getIntArray(bytes32 _key) external view returns (int[] memory);
    function getBytes32Array(bytes32 _key) external view returns (bytes32[] memory);

    //=================================================================================================================
    // Mutators
    //=================================================================================================================
    
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    function setAddressArray(bytes32 _key, address[] memory _value) external;
    function setUintArray(bytes32 _key, uint[] memory _value) external;
    function setStringArray(bytes32 _key, string[] memory _value) external;
    function setBytesArray(bytes32 _key, bytes[] memory _value) external;
    function setBoolArray(bytes32 _key, bool[] memory _value) external;
    function setIntArray(bytes32 _key, int[] memory _value) external;
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external;

    //=================================================================================================================
    // Deletion
    //=================================================================================================================

    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    function deleteAddressArray(bytes32 _key) external;
    function deleteUintArray(bytes32 _key) external;
    function deleteStringArray(bytes32 _key) external;
    function deleteBytesArray(bytes32 _key) external;
    function deleteBoolArray(bytes32 _key) external;
    function deleteIntArray(bytes32 _key) external;
    function deleteBytes32Array(bytes32 _key) external;

    //=================================================================================================================
    // Arithmetic
    //=================================================================================================================

    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */


/**
 * @title IPhantomTreasury
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IPhantomTreasury
 */
interface IPhantomTreasury {

    //=================================================================================================================
    // Errors
    //=================================================================================================================

    error PhantomTreasury_InvalidToken(address inToken);
    error PhantomTreasury_InsufficientReserves(uint256 numMint);
    error PhantomTreasury_UnapprovedExternalCall(address target, uint256 value, bytes data);
    error PhantomTreasury_ExternalCallReverted(address target, uint256 value, bytes data);
    error PhantomTreasury_ExternalReturnedInsufficientTokens(uint256 num, address target, uint256 value, bytes data);
    error PhantomTreasury_ExternalReturnedNoTokens(address target, uint256 value, bytes data);
    error PhantomTreasury_PercentagesDoNotAddTo100();
    error PhantomTreasury_LengthsDoNotMatch();
    
    //=================================================================================================================
    // Events
    //=================================================================================================================
    
    event PhantomTreasury_Swap(address inToken, address outToken, address forUser, uint256 amount);
    event PhantomTreasury_SwapBurn(address inToken, address outToken, address forUser, uint256 amount);
    event PhantomTreasury_SwapMint(address inToken, address outToken, address forUser, uint256 amount);
    event PhantomTreasury_Minted(address inToken, address toUser, uint256 amount);
    event PhantomTreasury_Burned(address inToken, address fromUser, uint256 amount);
    event PhantomTreasury_DepositedToVault(address inToken, address fromUser, uint256 amount);
    event PhantomTreasury_WithdrawalFromVault(address inToken, address toUser, uint256 amount);
    event PhantomTreasury_SwapBurnMint(address burnToken, uint256 burnAmount, address forUser, uint256 mintAmount, address mintToken);
    
    //=================================================================================================================
    // Public Functions
    //=================================================================================================================
    /**
     * @dev deposit funds into the treasury
     * @param inDepositor who is depositing the money?
     * @param inAmount how much is being deposited?
     * @param inToken what type of token is being deposited?

     * @return the amount deposited
     */
    function deposit(address inDepositor, uint256 inAmount, address inToken, bytes32[] memory keys,
        uint256[] memory percentages, uint256 mintRatio) external returns (uint256);

    /**
     * @dev Withdraw funds from the treasury
     * @param outWithdrawer who is withdrawing the funds?
     * @param outAmount how much is being withdrawn?
     * @param outToken what type of token is being withdrawn?
     * @return the amount withdrawn
     */
    function withdraw(address outWithdrawer, uint256 outAmount, address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages, uint256 burnRatio) external returns (uint256);

    /**
     * @dev swap some tokens in the treasury for another type of token
     * @param forUser who is doing this swap?
     * @param inAmount amount of tokens to be swapped
     * @param inToken the token type being swapped
     * @param outAmount the amount of new tokens to receive in exchange
     * @param outToken the type of token to receive in exchange

     */
    function swap(
        address forUser,
        uint256 inAmount,
        address inToken,
        uint256 outAmount,
        address outToken,
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    /**
     * @dev swap some tokens in the treasury for another type of token, burning the original tokens
     * @param forUser who is doing this swap?
     * @param burnAmount amount of tokens to be brned
     * @param burnToken the token type being burned
     * @param outAmount the amount of new tokens to receive in exchange
     * @param outToken the type of token to receive in exchange

     */
    function swapBurn(
        address forUser,
        uint256 burnAmount,
        address burnToken,
        uint256 outAmount,
        address outToken,
 
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    /**
     * @dev swap some tokens in the treasury for another type of newly minted tokens
     * @param forUser who is doing this swap?
     * @param inAmount amount of tokens to be swapped
     * @param inToken the token type being swapped
     * @param mintAmount the amount of new tokens to be minted and receive in exchange
     * @param mintToken the type of token to be minted and receive in exchange

     */
    function swapMint(
        address forUser,
        uint256 inAmount,
        address inToken,
        uint256 mintAmount,
        address mintToken,
 
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;

    function swapBurnMint(
        address forUser,
        uint256 burnAmount,
        address burnToken,
        uint256 mintAmount,
        address mintToken,
 
        bytes32[] memory keys,
        uint256[] memory percentages
    ) external;
    function sendToYearn(address vault, uint256 amount, bytes32[] memory keys, uint256[] memory percentages) external;
    function withdrawFromYearn(address vault, uint256 maxShares, uint256 maxLoss, bytes32[] memory keys, uint256[] memory percentages) external;
    function registerReserveToken(address token) external;
    function sumReserves() external view returns (uint256);
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Package Imports */
import { PRBMathUD60x18 } from "PRBMathUD60x18.sol";

/**
 * @title IPhantomVault
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice The Interface for IPhantomVault
 */
interface IPhantomVault {

    //=================================================================================================================
    // Events
    //=================================================================================================================

    event PhantomVault_Withdrawal(address fromUser, uint256 outAmount, address outToken);
    event PhantomVault_Burned(address fromUser, uint256 outAmount, address outToken);

    //=================================================================================================================
    // Functions
    //=================================================================================================================

    /**
     * @dev Withdraw ERC20 tokens from the Vault
     * @param outAmount The number of tokens to be withdrawn
     * @param outToken The type of token to withdraw
     */
    function withdraw(uint256 outAmount, address outToken) external;

    /**
     * @dev Burn ERC20 tokens from the Vault
     * @param burnAmount the number of tokens to be burned
     * @param burnToken The address of the ERC20 token to burn
     */
    function burn(uint256 burnAmount, address burnToken) external;
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/* Internal Interface Imports */
import {IPhantomStorage} from "IPhantomStorage.sol";

/**
 * @title PhantomStorageFactory
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Interface for PhantomStorageFactory
 */

interface IPhantomStorageFactory {
    //=================================================================================================================
    // Errors
    //=================================================================================================================

    error PhantomStorageFactory_ContractAlreadyExists(bytes32 inContractName);
    error PhantomStorageFactory_ContractDoesNotExist(bytes32 inContractName);

    //=================================================================================================================
    // Mutators
    //=================================================================================================================

    function deployStorageContract(bytes32 inContractName) external returns (IPhantomStorage);
    function removeStorageContract(bytes32 inContractName) external returns (bool);

    //=================================================================================================================
    // Accessors
    //=================================================================================================================

    function getStorageContractByName(bytes32 inContractName) external view returns (IPhantomStorage);
}

/* SPDX-License-Identifier: MIT */
pragma solidity =0.8.10;

/** 
 * @title IPhantomStorageMixin
 * @author 0xrebased @ Bonga Bera Capital: https://github.com/BongaBeraCapital
 * @notice Interface of PhantomStorageMixin
 */
interface IPhantomStorageMixin {

    //=================================================================================================================
    // Errors
    //=================================================================================================================
    
    error PhantomStorageMixin__ContractNotFoundByAddressOrIsOutdated(address contractAddress);
    error PhantomStorageMixin__ContractNotFoundByNameOrIsOutdated(bytes32 contractName);
    error PhantomStorageMixin__UserIsNotGuardian(address user);
        

}