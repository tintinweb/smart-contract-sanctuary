// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../external/compound/PriceOracle.sol";
import "../external/compound/CToken.sol";
import "../external/compound/CErc20.sol";

import "./BasePriceOracle.sol";

/**
 * @title MasterPriceOracle
 * @notice Use a combination of price oracles.
 * @dev Implements `PriceOracle`.
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 */
contract MasterPriceOracle is PriceOracle, BasePriceOracle {
    /**
     * @dev Maps underlying token addresses to `PriceOracle` contracts (can be `BasePriceOracle` contracts too).
     */
    mapping(address => PriceOracle) public oracles;

    /**
     * @dev The administrator of this `MasterPriceOracle`.
     */
    address public admin;

    /**
     * @dev Controls if `admin` can overwrite existing assignments of oracles to underlying tokens.
     */
    bool public canAdminOverwrite;

    /**
     * @dev Constructor to initialize state variables.
     * @param underlyings The underlying ERC20 token addresses to link to `_oracles`.
     * @param _oracles The `PriceOracle` contracts to be assigned to `underlyings`.
     * @param _admin The admin who can assign oracles to underlying tokens.
     * @param _canAdminOverwrite Controls if `admin` can overwrite existing assignments of oracles to underlying tokens.
     */
    constructor (address[] memory underlyings, PriceOracle[] memory _oracles, address _admin, bool _canAdminOverwrite) public {
        // Input validation
        require(underlyings.length > 0 && underlyings.length == _oracles.length, "Lengths of both arrays must be equal and greater than 0.");

        // Initialize state variables
        for (uint256 i = 0; i < underlyings.length; i++) oracles[underlyings[i]] = _oracles[i];
        admin = _admin;
        canAdminOverwrite = _canAdminOverwrite;
    }

    /**
     * @dev Sets `_oracles` for `underlyings`.
     */
    function add(address[] calldata underlyings, PriceOracle[] calldata _oracles) external onlyAdmin {
        // Input validation
        require(underlyings.length > 0 && underlyings.length == _oracles.length, "Lengths of both arrays must be equal and greater than 0.");

        // Assign oracles to underlying tokens
        for (uint256 i = 0; i < underlyings.length; i++) {
            if (!canAdminOverwrite) require(address(oracles[underlyings[i]]) == address(0), "Admin cannot overwrite existing assignments of oracles to underlying tokens.");
            oracles[underlyings[i]] = _oracles[i];
        }
    }

    /**
     * @dev Changes the admin and emits an event.
     */
    function changeAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }

    /**
     * @dev Event emitted when `admin` is changed.
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @dev Modifier that checks if `msg.sender == admin`.
     */
    modifier onlyAdmin {
        require(msg.sender == admin, "Sender is not the admin.");
        _;
    }

    /**
     * @notice Returns the price in ETH of the token underlying `cToken`.
     * @dev Implements the `PriceOracle` interface for Fuse pools (and Compound v2).
     * @return Price in ETH of the token underlying `cToken`, scaled by `10 ** (36 - underlyingDecimals)`.
     */
    function getUnderlyingPrice(CToken cToken) external override view returns (uint) {
        // Return 1e18 for ETH
        if (cToken.isCEther()) return 1e18;

        // Get underlying ERC20 token address
        address underlying = address(CErc20(address(cToken)).underlying());

        // Return 1e18 for WETH
        if (underlying == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1e18;

        // Get underlying price from assigned oracle
        require(address(oracles[underlying]) != address(0), "Price oracle not found for this underlying token address.");
        return oracles[underlying].getUnderlyingPrice(cToken);
    }

    /**
     * @dev Attempts to return the price in ETH of `underlying` (implements `BasePriceOracle`).
     */
    function price(address underlying) external override view returns (uint) {
        // Return 1e18 for WETH
        if (underlying == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1e18;

        // Get underlying price from assigned oracle
        require(address(oracles[underlying]) != address(0), "Price oracle not found for this underlying token address.");
        return BasePriceOracle(address(oracles[underlying])).price(underlying);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../external/compound/PriceOracle.sol";

/**
 * @title BasePriceOracle
 * @notice Returns prices of underlying tokens directly without the caller having to specify a cToken address.
 * @dev Implements the `PriceOracle` interface.
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 */
interface BasePriceOracle is PriceOracle {
    /**
     * @notice Get the price of an underlying asset.
     * @param underlying The underlying asset to get the price of.
     * @return The underlying asset price in ETH as a mantissa (scaled by 1e18).
     * Zero means the price is unavailable.
     */
    function price(address underlying) external view returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./CToken.sol";

interface PriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external view returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title Compound's CToken Contract
 * @notice Abstract base for CTokens
 * @author Compound
 */
interface CToken {
    function admin() external view returns (address);
    function adminHasRights() external view returns (bool);
    function fuseAdminHasRights() external view returns (bool);
    function symbol() external view returns (string memory);
    function comptroller() external view returns (address);
    function adminFeeMantissa() external view returns (uint256);
    function fuseFeeMantissa() external view returns (uint256);
    function reserveFactorMantissa() external view returns (uint256);
    function totalReserves() external view returns (uint);
    function totalAdminFees() external view returns (uint);
    function totalFuseFees() external view returns (uint);

    function isCToken() external view returns (bool);
    function isCEther() external view returns (bool);

    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);

    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./CToken.sol";

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
interface CErc20 is CToken {
    function underlying() external view returns (address);
    function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external returns (uint);
}