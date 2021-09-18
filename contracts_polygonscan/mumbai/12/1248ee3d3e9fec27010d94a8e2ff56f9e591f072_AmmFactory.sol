// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Proxy.sol";
import "./Proxiable.sol";
import "./InitializeableAmm.sol";
import "./IAddSeriesToAmm.sol";
import "./ISeriesController.sol";

/// @title AmmFactory
/// @author The Siren Devs
/// @notice Factory contract responsible for AMM creation
contract AmmFactory is OwnableUpgradeable, Proxiable {
    /// @notice Implementation address for the AMM contract - can be upgraded by owner
    address public ammImplementation;

    /// @notice Implementation address for token contracts - can be upgraded by owner
    address public tokenImplementation;

    /// @notice Address of the SeriesController associated with this AmmFactory
    ISeriesController public seriesController;

    /// @notice Mapping of keccak256(abi.encode(address(_underlyingToken), address(_priceToken), address(collateralToken)))
    /// bytes32 keys to AMM (Automated Market Maker) addresses
    /// @dev used to ensure we cannot create AMM's with the same <underlying>-<price>-<collateral> triplet
    mapping(bytes32 => address) public amms;

    /// @notice Emitted when the owner updates the amm implementation address
    event AmmImplementationUpdated(address newAddress);

    /// @notice Emitted when a new AMM is created and initialized
    event AmmCreated(address amm);

    /// @notice Emitted when the owner updates the token implementation address
    event TokenImplementationUpdated(address newAddress);

    /// @notice Setup the state variables for an AmmFactory
    function initialize(
        address _ammImplementation,
        address _tokenImplementation,
        ISeriesController _seriesController
    ) external {
        __AmmFactory_init(
            _ammImplementation,
            _tokenImplementation,
            _seriesController
        );
    }

    /**
     * Initialization function that only allows itself to be called once
     */
    function __AmmFactory_init(
        address _ammImplementation,
        address _tokenImplementation,
        ISeriesController _seriesController
    ) internal initializer {
        // Verify addresses
        require(
            _ammImplementation != address(0x0),
            "Invalid _ammImplementation"
        );
        require(
            _tokenImplementation != address(0x0),
            "Invalid _tokenImplementation"
        );
        require(
            address(_seriesController) != address(0x0),
            "Invalid _seriesController"
        );

        // Save off implementation address
        ammImplementation = _ammImplementation;
        tokenImplementation = _tokenImplementation;
        seriesController = _seriesController;

        // Set up the initialization of the inherited ownable contract
        __Ownable_init();
    }

    /**
     * The owner can update the AMM implementation address that will be used for future AMMs
     */
    function updateAmmImplementation(address newAmmImplementation)
        external
        onlyOwner
    {
        require(
            newAmmImplementation != address(0x0),
            "Invalid newAmmImplementation"
        );

        // Update the address
        ammImplementation = newAmmImplementation;

        // Emit the event
        emit AmmImplementationUpdated(ammImplementation);
    }

    /// @notice The owner can update the token implementation address that will be used for future AMMs
    function updateTokenImplementation(address newTokenImplementation)
        external
        onlyOwner
    {
        require(
            newTokenImplementation != address(0x0),
            "Invalid newTokenImplementation"
        );

        // Update the address
        tokenImplementation = newTokenImplementation;

        // Emit the event
        emit TokenImplementationUpdated(tokenImplementation);
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new AmmFactory implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        require(
            _newImplementation != address(0x0),
            "Invalid _newImplementation"
        );

        _updateCodeAddress(_newImplementation);
    }

    /// @notice Deploy and initializes an AMM
    /// @param _sirenPriceOracle the PriceOracle contract to use for fetching series and settlement prices
    /// @param _underlyingToken The token whose price movements determine the AMM's Series' moneyness
    /// @param _priceToken The token whose units are used for all prices
    /// @param _collateralToken The token used for this AMM's Series' collateral
    /// @param _tradeFeeBasisPoints The fees to charge on option token trades
    function createAmm(
        address _sirenPriceOracle,
        address _ammDataProvider,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        uint16 _tradeFeeBasisPoints
    ) external onlyOwner {
        require(
            address(_sirenPriceOracle) != address(0x0),
            "Invalid _sirenPriceOracle"
        );
        require(
            address(_ammDataProvider) != address(0x0),
            "Invalid _ammDataProvider"
        );
        require(
            address(_underlyingToken) != address(0x0),
            "Invalid _underlyingToken"
        );
        require(address(_priceToken) != address(0x0), "Invalid _priceToken");
        require(
            address(_collateralToken) != address(0x0),
            "Invalid _collateralToken"
        );

        // Verify a amm with this name does not exist
        bytes32 assetPair = keccak256(
            abi.encode(
                address(_underlyingToken),
                address(_priceToken),
                address(_collateralToken)
            )
        );

        require(amms[assetPair] == address(0x0), "AMM name already registered");

        // Deploy a new proxy pointing at the AMM impl
        Proxy ammProxy = new Proxy(ammImplementation);
        InitializeableAmm newAmm = InitializeableAmm(address(ammProxy));

        newAmm.initialize(
            seriesController,
            _sirenPriceOracle,
            _ammDataProvider,
            _underlyingToken,
            _priceToken,
            _collateralToken,
            tokenImplementation,
            _tradeFeeBasisPoints
        );

        // Set owner to msg.sender
        OwnableUpgradeable(address(newAmm)).transferOwnership(msg.sender);

        // Save off the new AMM, this way we don't accidentally create an AMM with a duplicate
        // <underlying>-<price>-<collateral> triplet
        amms[assetPair] = address(newAmm);

        // Emit the event
        emit AmmCreated(address(newAmm));
    }
}