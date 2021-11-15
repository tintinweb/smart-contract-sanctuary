// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./IVault.sol";
import "./tokens/IERC20Metadata.sol";

/// @title Reading key data from specified Vault
contract VaultView {
    /// @notice Contains key information about a Vault
    struct Vault {
        address self;
        uint256 liveTime;
        uint256 settleTime;
        int256 underlyingStart;
        int256 underlyingEnd;
        uint256 primaryConversion;
        uint256 complementConversion;
        uint256 protocolFee;
        uint256 authorFeeLimit;
        uint256 state;
        address oracle;
        uint256 oracleDecimals;
        address oracleIterator;
        address collateralSplit;
        bool isPaused;
    }

    /// @notice Contains key information about a derivative token
    struct Token {
        address self;
        string name;
        string symbol;
        uint8 decimals;
        uint256 userBalance;
    }

    /// @notice Contains key information from Derivative Specification
    struct DerivativeSpecification {
        address self;
        string name;
        string symbol;
        uint256 denomination;
        uint256 authorFee;
        uint256 primaryNominalValue;
        uint256 complementNominalValue;
        bytes32[] oracleSymbols;
    }

    // Using vars to avoid stack do deep error
    struct Vars {
        IVault vault;
        IDerivativeSpecification specification;
        IERC20Metadata collateral;
        IERC20 collateralToken;
        IERC20Metadata primary;
        IERC20Metadata complement;
    }

    /// @notice Getting information about a Vault, its derivative tokens and specification
    /// @param _vault vault address
    /// @return vaultData vault-specific information
    /// @return derivativeSpecificationData vault's derivative specification
    /// @return collateralData vault's collateral token metadata
    /// @return lockedCollateralAmount vault's total locked collateral amount
    /// @return primaryData vault's primary token metadata
    /// @return complementData vault's complement token metadata
    function getVaultInfo(address _vault, address _sender)
        external
        view
        returns (
            Vault memory vaultData,
            DerivativeSpecification memory derivativeSpecificationData,
            Token memory collateralData,
            uint256 lockedCollateralAmount,
            Token memory primaryData,
            Token memory complementData
        )
    {
        Vars memory vars;
        vars.vault = IVault(_vault);

        int256 underlyingStarts = 0;
        if (uint256(vars.vault.state()) > 0) {
            underlyingStarts = vars.vault.underlyingStarts(0);
        }

        int256 underlyingEnds = 0;
        if (
            vars.vault.primaryConversion() > 0 ||
            vars.vault.complementConversion() > 0
        ) {
            underlyingEnds = vars.vault.underlyingEnds(0);
        }

        vaultData = Vault(
            _vault,
            vars.vault.liveTime(),
            vars.vault.settleTime(),
            underlyingStarts,
            underlyingEnds,
            vars.vault.primaryConversion(),
            vars.vault.complementConversion(),
            vars.vault.protocolFee(),
            vars.vault.authorFeeLimit(),
            uint256(vars.vault.state()),
            vars.vault.oracles(0),
            AggregatorV3Interface(vars.vault.oracles(0)).decimals(),
            vars.vault.oracleIterators(0),
            vars.vault.collateralSplit(),
            vars.vault.paused()
        );

        vars.specification = vars.vault.derivativeSpecification();
        derivativeSpecificationData = DerivativeSpecification(
            address(vars.specification),
            vars.specification.name(),
            vars.specification.symbol(),
            vars.specification.primaryNominalValue() +
                vars.specification.complementNominalValue(),
            vars.specification.authorFee(),
            vars.specification.primaryNominalValue(),
            vars.specification.complementNominalValue(),
            vars.specification.oracleSymbols()
        );

        vars.collateral = IERC20Metadata(vars.vault.collateralToken());
        vars.collateralToken = IERC20(address(vars.collateral));
        collateralData = Token(
            address(vars.collateral),
            vars.collateral.name(),
            vars.collateral.symbol(),
            vars.collateral.decimals(),
            _sender == address(0) ? 0 : vars.collateralToken.balanceOf(_sender)
        );
        lockedCollateralAmount = vars.collateralToken.balanceOf(_vault);

        vars.primary = IERC20Metadata(vars.vault.primaryToken());
        primaryData = Token(
            address(vars.primary),
            vars.primary.name(),
            vars.primary.symbol(),
            vars.primary.decimals(),
            _sender == address(0)
                ? 0
                : IERC20(address(vars.primary)).balanceOf(_sender)
        );

        vars.complement = IERC20Metadata(vars.vault.complementToken());
        complementData = Token(
            address(vars.complement),
            vars.complement.name(),
            vars.complement.symbol(),
            vars.complement.decimals(),
            _sender == address(0)
                ? 0
                : IERC20(address(vars.complement)).balanceOf(_sender)
        );
    }

    /// @notice Getting vault derivative token balances
    /// @param _owner address for which balances are being extracted
    /// @param _vaults list of all vaults
    /// @return primaries primary token balances
    /// @return complements complement token balances
    function getVaultTokenBalancesByOwner(
        address _owner,
        address[] calldata _vaults
    )
        external
        view
        returns (uint256[] memory primaries, uint256[] memory complements)
    {
        primaries = new uint256[](_vaults.length);
        complements = new uint256[](_vaults.length);

        IVault vault;
        for (uint256 i = 0; i < _vaults.length; i++) {
            vault = IVault(_vaults[i]);
            primaries[i] = IERC20(vault.primaryToken()).balanceOf(_owner);
            complements[i] = IERC20(vault.complementToken()).balanceOf(_owner);
        }
    }

    /// @notice Getting any ERC20 token balances
    /// @param _owner address for which balances are being extracted
    /// @param _tokens list of all tokens
    /// @return balances token balances
    function getERC20BalancesByOwner(address _owner, address[] calldata _tokens)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            balances[i] = IERC20(_tokens[i]).balanceOf(_owner);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

import "./IDerivativeSpecification.sol";

/// @title Derivative implementation Vault
/// @notice A smart contract that references derivative specification and enables users to mint and redeem the derivative
interface IVault {
    enum State { Created, Live, Settled }

    /// @notice start of live period
    function liveTime() external view returns (uint256);

    /// @notice end of live period
    function settleTime() external view returns (uint256);

    /// @notice redeem function can only be called after the end of the Live period + delay
    function settlementDelay() external view returns (uint256);

    /// @notice underlying value at the start of live period
    function underlyingStarts(uint256 index) external view returns (int256);

    /// @notice underlying value at the end of live period
    function underlyingEnds(uint256 index) external view returns (int256);

    /// @notice primary token conversion rate multiplied by 10 ^ 12
    function primaryConversion() external view returns (uint256);

    /// @notice complement token conversion rate multiplied by 10 ^ 12
    function complementConversion() external view returns (uint256);

    /// @notice protocol fee multiplied by 10 ^ 12
    function protocolFee() external view returns (uint256);

    /// @notice limit on author fee multiplied by 10 ^ 12
    function authorFeeLimit() external view returns (uint256);

    // @notice protocol's fee receiving wallet
    function feeWallet() external view returns (address);

    // @notice current state of the vault
    function state() external view returns (State);

    // @notice derivative specification address
    function derivativeSpecification()
        external
        view
        returns (IDerivativeSpecification);

    // @notice collateral token address
    function collateralToken() external view returns (address);

    // @notice oracle address
    function oracles(uint256 index) external view returns (address);

    function oracleIterators(uint256 index) external view returns (address);

    // @notice collateral split address
    function collateralSplit() external view returns (address);

    // @notice derivative's token builder strategy address
    function tokenBuilder() external view returns (address);

    function feeLogger() external view returns (address);

    // @notice primary token address
    function primaryToken() external view returns (address);

    // @notice complement token address
    function complementToken() external view returns (address);

    /// @notice Switch to Settled state if appropriate time threshold is passed and
    /// set underlyingStarts value and set underlyingEnds value,
    /// calculate primaryConversion and complementConversion params
    /// @dev Reverts if underlyingStart or underlyingEnd are not available
    /// Vault cannot settle when it paused
    function settle(uint256[] calldata _underlyingEndRoundHints) external;

    function mintTo(address _recipient, uint256 _collateralAmount) external;

    /// @notice Mints primary and complement derivative tokens
    /// @dev Checks and switches to the right state and does nothing if vault is not in Live state
    function mint(uint256 _collateralAmount) external;

    /// @notice Refund equal amounts of derivative tokens for collateral at any time
    function refund(uint256 _tokenAmount) external;

    function refundTo(address _recipient, uint256 _tokenAmount) external;

    function redeemTo(
        address _recipient,
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external;

    /// @notice Redeems unequal amounts previously calculated conversions if the vault is in Settled state
    function redeem(
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external;

    function paused() external view returns (bool);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
    /// @notice Proof of a derivative specification
    /// @dev Verifies that contract is a derivative specification
    /// @return true if contract is a derivative specification
    function isDerivativeSpecification() external pure returns (bool);

    /// @notice Set of oracles that are relied upon to measure changes in the state of the world
    /// between the start and the end of the Live period
    /// @dev Should be resolved through OracleRegistry contract
    /// @return oracle symbols
    function oracleSymbols() external view returns (bytes32[] memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    /// finds the value closest to a given timestamp
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbols
    function oracleIteratorSymbols() external view returns (bytes32[] memory);

    /// @notice Type of collateral that users submit to mint the derivative
    /// @dev Should be resolved through CollateralTokenRegistry contract
    /// @return collateral token symbol
    function collateralTokenSymbol() external view returns (bytes32);

    /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
    /// and the initial collateral split to the final collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split symbol
    function collateralSplitSymbol() external view returns (bytes32);

    /// @notice Lifecycle parameter that define the length of the derivative's Live period.
    /// @dev Set in seconds
    /// @return live period value
    function livePeriod() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of primary asset
    /// @dev Units of collateral theoretically swappable for 1 unit of primary asset
    /// @return primary nominal value
    function primaryNominalValue() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of complement asset
    /// @dev Units of collateral theoretically swappable for 1 unit of complement asset
    /// @return complement nominal value
    function complementNominalValue() external view returns (uint256);

    /// @notice Minting fee rate due to the author of the derivative specification.
    /// @dev Percentage fee multiplied by 10 ^ 12
    /// @return author fee
    function authorFee() external view returns (uint256);

    /// @notice Symbol of the derivative
    /// @dev Should be resolved through DerivativeSpecificationRegistry contract
    /// @return derivative specification symbol
    function symbol() external view returns (string memory);

    /// @notice Return optional long name of the derivative
    /// @dev Isn't used directly in the protocol
    /// @return long name
    function name() external view returns (string memory);

    /// @notice Optional URI to the derivative specs
    /// @dev Isn't used directly in the protocol
    /// @return URI to the derivative specs
    function baseURI() external view returns (string memory);

    /// @notice Derivative spec author
    /// @dev Used to set and receive author's fee
    /// @return address of the author
    function author() external view returns (address);
}

