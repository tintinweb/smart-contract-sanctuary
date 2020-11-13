pragma solidity 0.5.17;

import {IBondedECDSAKeepFactory} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeepFactory.sol";

/// @title Bonded ECDSA keep factory selection strategy.
/// @notice The strategy defines the algorithm for selecting a factory. tBTC
/// uses two bonded ECDSA keep factories, selecting one of them for each new
/// deposit being opened.
interface KeepFactorySelector {

    /// @notice Selects keep factory for the new deposit.
    /// @param _seed Request seed.
    /// @param _keepStakedFactory Regular, KEEP-stake based keep factory.
    /// @param _fullyBackedFactory Fully backed, ETH-bond-only based keep factory.
    /// @return The selected keep factory.
    function selectFactory(
        uint256 _seed,
        IBondedECDSAKeepFactory _keepStakedFactory,
        IBondedECDSAKeepFactory _fullyBackedFactory
    ) external view returns (IBondedECDSAKeepFactory);
}

/// @title Bonded ECDSA keep factory selection library.
/// @notice tBTC uses two bonded ECDSA keep factories: one based on KEEP stake
/// and ETH bond, and another based only on ETH bond. The library holds
/// a reference to both factories as well as a reference to a selection strategy
/// deciding which factory to choose for the new deposit being opened.
library KeepFactorySelection {

    struct Storage {
        uint256 requestCounter;

        IBondedECDSAKeepFactory selectedFactory;

        KeepFactorySelector factorySelector;

        // Standard ECDSA keep factory: KEEP stake and ETH bond.
        // Guaranteed to be set for initialized factory.
        IBondedECDSAKeepFactory keepStakedFactory;

        // Fully backed ECDSA keep factory: ETH bond only.
        IBondedECDSAKeepFactory fullyBackedFactory;
    }

    /// @notice Initializes the library with the default KEEP-stake-based
    /// factory. The default factory is guaranteed to be set and this function
    /// must be called when creating contract using this library.
    /// @dev This function can be called only one time.
    function initialize(
        Storage storage _self,
        IBondedECDSAKeepFactory _defaultFactory
    ) public {
        require(
            address(_self.keepStakedFactory) == address(0),
            "Already initialized"
        );

        _self.keepStakedFactory = IBondedECDSAKeepFactory(_defaultFactory);
        _self.selectedFactory = _self.keepStakedFactory;
    }

    /// @notice Returns the selected keep factory.
    /// This function guarantees that the same factory is returned for every
    /// call until selectFactoryAndRefresh is executed. This lets to evaluate
    /// open keep fee estimate on the same factory that will be used later for
    /// opening a new keep (fee estimate and open keep requests are two
    /// separate calls).
    /// @return Selected keep factory. The same vale will be returned for every
    /// call of this function until selectFactoryAndRefresh is executed.
    function selectFactory(
        Storage storage _self
    ) public view returns (IBondedECDSAKeepFactory) {
        return _self.selectedFactory;
    }

    /// @notice Returns the selected keep factory and refreshes the choice
    /// for the next select call. The value returned by this function has been
    /// evaluated during the previous call. This lets to return the same value
    /// from selectFactory and selectFactoryAndRefresh, thus, allowing to use
    /// the same factory for which open keep fee estimate was evaluated (fee
    /// estimate and open keep requests are two separate calls).
    /// @return Selected keep factory.
    function selectFactoryAndRefresh(
        Storage storage _self
    ) external returns (IBondedECDSAKeepFactory) {
        IBondedECDSAKeepFactory factory = selectFactory(_self);
        refreshFactory(_self);

        return factory;
    }

    /// @notice Sets the minimum bondable value required from the operator to
    /// join the sortition pool for tBTC.
    /// @param _minimumBondableValue The minimum bond value the application
    /// requires from a single keep.
    /// @param _groupSize Number of signers in the keep.
    /// @param _honestThreshold Minimum number of honest keep signers.
    function setMinimumBondableValue(
        Storage storage _self,
        uint256 _minimumBondableValue,
        uint256 _groupSize,
        uint256 _honestThreshold
    ) external {
        if (address(_self.keepStakedFactory) != address(0)) {
            _self.keepStakedFactory.setMinimumBondableValue(
                _minimumBondableValue,
                _groupSize,
                _honestThreshold
            );
        }
        if (address(_self.fullyBackedFactory) != address(0)) {
            _self.fullyBackedFactory.setMinimumBondableValue(
                _minimumBondableValue,
                _groupSize,
                _honestThreshold
            );
        }
    }

    /// @notice Refreshes the keep factory choice. If either ETH-bond-only factory
    /// or selection strategy is not set, KEEP-stake factory is selected.
    /// Otherwise, calls selection strategy providing addresses of both
    /// factories to make a choice. Additionally, passes the selection seed
    /// evaluated from the current request counter value.
    function refreshFactory(Storage storage _self) internal {
        if (
            address(_self.fullyBackedFactory) == address(0) ||
            address(_self.factorySelector) == address(0)
        ) {
            // KEEP-stake factory is guaranteed to be there. If the selection
            // can not be performed, this is the default choice.
            _self.selectedFactory = _self.keepStakedFactory;
            return;
        }

        _self.requestCounter++;
        uint256 seed = uint256(
            keccak256(abi.encodePacked(address(this), _self.requestCounter))
        );
        _self.selectedFactory = _self.factorySelector.selectFactory(
            seed,
            _self.keepStakedFactory,
            _self.fullyBackedFactory
        );

        require(
            _self.selectedFactory == _self.keepStakedFactory ||
                _self.selectedFactory == _self.fullyBackedFactory,
            "Factory selector returned unknown factory"
        );
    }

    /// @notice Sets addresses of the keep factories and the selection strategy
    /// contracts.
    /// KeepFactorySelection can work without the keep factory selection
    /// strategy set, always selecting the default KEEP-stake-based factory.
    /// Once both fully-backed keep factory and factory selection strategy are
    /// set, KEEP-stake-based factory is no longer the default choice and it is
    /// up to the selection strategy to decide which factory should be chosen.
    /// @dev Can be called multiple times! It's responsibility of a contract
    /// using this library to limit and protect updates.
    /// @param _keepStakedFactory Address of the regular, KEEP-stake based keep
    /// factory.
    /// @param _fullyBackedFactory Address of the fully-backed, ETH-bond-only based
    /// keep factory.
    /// @param _factorySelector Address of the keep factory selection strategy.
    function setFactories(
        Storage storage _self,
        address _keepStakedFactory,
        address _fullyBackedFactory,
        address _factorySelector
    ) internal {
        require(
            address(_keepStakedFactory) != address(0),
            "Invalid KEEP-staked factory address"
        );

        _self.keepStakedFactory = IBondedECDSAKeepFactory(_keepStakedFactory);
        _self.fullyBackedFactory = IBondedECDSAKeepFactory(_fullyBackedFactory);
        _self.factorySelector = KeepFactorySelector(_factorySelector);
    }
}
