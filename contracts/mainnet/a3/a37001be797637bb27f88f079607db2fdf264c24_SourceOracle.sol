/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/oracle/interfaces/FinderInterface.sol

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}


// File contracts/chainbridge/IBridge.sol

pragma solidity ^0.8.0;

/**
    @title Interface for Bridge contract.
    @dev Copied directly from here: https://github.com/ChainSafe/chainbridge-solidity/releases/tag/v1.0.0 except for 
         the addition of `deposit()` so that this contract can be called from Sink and Source Oracle contracts.
    @author ChainSafe Systems.
 */
interface IBridge {
    /**
        @notice Exposing getter for {_chainID} instead of forcing the use of call.
        @return uint8 The {_chainID} that is currently set for the Bridge contract.
     */
    function _chainID() external returns (uint8);

    function deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data
    ) external;
}


// File contracts/oracle/implementation/Constants.sol

pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
}


// File contracts/chainbridge/BeaconOracle.sol

pragma solidity ^0.8.0;



/**
 * @title Simple implementation of the OracleInterface used to communicate price request data cross-chain between
 * EVM networks. Can be extended either into a "Source" or "Sink" oracle that specializes in making and resolving
 * cross-chain price requests, respectively. The "Source" Oracle is the originator or source of price resolution data
 * and can only resolve prices already published by the DVM. The "Sink" Oracle receives the price resolution data
 * from the Source Oracle and makes it available on non-Mainnet chains. The "Sink" Oracle can also be used to trigger
 * price requests from the DVM on Mainnet.
 */
abstract contract BeaconOracle {
    enum RequestState { NeverRequested, PendingRequest, Requested, PendingResolve, Resolved }

    struct Price {
        RequestState state;
        int256 price;
    }

    // Chain ID for this Oracle.
    uint8 public currentChainID;

    // Mapping of encoded price requests {chainID, identifier, time, ancillaryData} to Price objects.
    mapping(bytes32 => Price) internal prices;

    // Finder to provide addresses for DVM system contracts.
    FinderInterface public finder;

    event PriceRequestAdded(uint8 indexed chainID, bytes32 indexed identifier, uint256 time, bytes ancillaryData);
    event PushedPrice(
        uint8 indexed chainID,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        int256 price
    );

    /**
     * @notice Constructor.
     * @param _finderAddress finder to use to get addresses of DVM contracts.
     */
    constructor(address _finderAddress, uint8 _chainID) {
        finder = FinderInterface(_finderAddress);
        currentChainID = _chainID;
    }

    // We assume that there is only one GenericHandler for this network.
    modifier onlyGenericHandlerContract() {
        require(
            msg.sender == finder.getImplementationAddress(OracleInterfaces.GenericHandler),
            "Caller must be GenericHandler"
        );
        _;
    }

    /**
     * @notice Enqueues a request (if a request isn't already present) for the given (chainID, identifier, time,
     * ancillary data) combination. Will only emit an event if the request has never been requested.
     */
    function _requestPrice(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) internal {
        bytes32 priceRequestId = _encodePriceRequest(chainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        if (lookup.state == RequestState.NeverRequested) {
            lookup.state = RequestState.PendingRequest;
            emit PriceRequestAdded(chainID, identifier, time, ancillaryData);
        }
    }

    /**
     * @notice Derived contract needs call this method in order to advance state from PendingRequest --> Requested
     * before _publishPrice can be called.
     */
    function _finalizeRequest(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) internal {
        bytes32 priceRequestId = _encodePriceRequest(chainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.PendingRequest, "Price has not been requested");
        lookup.state = RequestState.Requested;
    }

    /**
     * @notice Publishes price for a requested query. Will revert if request hasn't been requested yet or has been
     * resolved already.
     */
    function _publishPrice(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) internal {
        bytes32 priceRequestId = _encodePriceRequest(chainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.Requested, "Price request is not currently pending");
        lookup.price = price;
        lookup.state = RequestState.PendingResolve;
        emit PushedPrice(chainID, identifier, time, ancillaryData, lookup.price);
    }

    function _finalizePublish(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) internal {
        bytes32 priceRequestId = _encodePriceRequest(chainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.PendingResolve, "Price has not been published");
        lookup.state = RequestState.Resolved;
    }

    /**
     * @notice Returns Bridge contract on network.
     */
    function _getBridge() internal view returns (IBridge) {
        return IBridge(finder.getImplementationAddress(OracleInterfaces.Bridge));
    }

    /**
     * @notice Returns the convenient way to store price requests, uniquely identified by {chainID, identifier, time,
     * ancillaryData }.
     */
    function _encodePriceRequest(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(chainID, identifier, time, ancillaryData));
    }
}


// File contracts/oracle/interfaces/OracleAncillaryInterface.sol

pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (int256);
}


// File contracts/chainbridge/SourceOracle.sol

pragma solidity ^0.8.0;


/**
 * @title Extension of BeaconOracle that is intended to be deployed on Mainnet to give financial
 * contracts on non-Mainnet networks the ability to trigger cross-chain price requests to the Mainnet DVM. This contract
 * is responsible for triggering price requests originating from non-Mainnet, and broadcasting resolved price data
 * back to those networks. Technically, this contract is more of a Proxy than an Oracle, because it does not implement
 * the full Oracle interface including the getPrice and requestPrice methods. It's goal is to shuttle price request
 * functionality between L2 and L1.
 * @dev The intended client of this contract is some off-chain bot watching for resolved price events on the DVM. Once
 * that bot sees a price has resolved, it can call `publishPrice()` on this contract which will call the local Bridge
 * contract to signal to an off-chain relayer to bridge a price request to another network.
 * @dev This contract must be a registered financial contract in order to call DVM methods.
 */
contract SourceOracle is BeaconOracle {
    /**
     * @notice Constructor.
     * @param _finderAddress Address of Finder that this contract uses to locate Bridge.
     * @param _chainID Chain ID for this contract.
     */
    constructor(address _finderAddress, uint8 _chainID) BeaconOracle(_finderAddress, _chainID) {}

    /***************************************************************
     * Publishing Price Request Data to L2:
     ***************************************************************/

    /**
     * @notice This is the first method that should be called in order to publish a price request to another network
     * marked by `sinkChainID`.
     * @dev Publishes the DVM resolved price for the price request, or reverts if not resolved yet. Will call the
     * local Bridge's deposit() method which will emit a Deposit event in order to signal to an off-chain
     * relayer to begin the cross-chain process.
     * @param sinkChainID Chain ID of SinkOracle that this price should ultimately be sent to.
     * @param identifier Identifier of price request to resolve.
     * @param time Timestamp of price request to resolve.
     * @param ancillaryData extra data of price request to resolve.
     */
    function publishPrice(
        uint8 sinkChainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public {
        require(_getOracle().hasPrice(identifier, time, ancillaryData), "DVM has not resolved price");
        int256 price = _getOracle().getPrice(identifier, time, ancillaryData);
        _publishPrice(sinkChainID, identifier, time, ancillaryData, price);

        // Initiate cross-chain price request, which should lead the `Bridge` to call `validateDeposit` on this
        // contract.
        _getBridge().deposit(
            sinkChainID,
            getResourceId(),
            formatMetadata(sinkChainID, identifier, time, ancillaryData, price)
        );
    }

    /**
     * @notice This method will ultimately be called after `publishPrice` calls `Bridge.deposit()`, which will call
     * `GenericHandler.deposit()` and ultimately this method.
     * @dev This method should basically check that the `Bridge.deposit()` was triggered by a valid publish event.
     * @param sinkChainID Chain ID of SinkOracle that this price should ultimately be sent to.
     * @param identifier Identifier of price request to resolve.
     * @param time Timestamp of price request to resolve.
     * @param ancillaryData extra data of price request to resolve.
     * @param price Price resolved on DVM to send to SinkOracle.
     */
    function validateDeposit(
        uint8 sinkChainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) public {
        bytes32 priceRequestId = _encodePriceRequest(sinkChainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.price == price, "Unexpected price published");
        // Advance state so that directly calling Bridge.deposit will revert and not emit a duplicate `Deposit` event.
        _finalizePublish(sinkChainID, identifier, time, ancillaryData);
    }

    /***************************************************************
     * Responding to a Price Request from L2:
     ***************************************************************/

    /**
     * @notice This method will ultimately be called after a `requestPrice` has been bridged cross-chain from
     * non-Mainnet to this network via an off-chain relayer. The relayer will call `Bridge.executeProposal` on this
     * local network, which call `GenericHandler.executeProposal()` and ultimately this method.
     * @dev This method should prepare this oracle to receive a published price and then forward the price request
     * to the DVM. Can only be called by the `GenericHandler`.
     * @param sinkChainID Chain ID of SinkOracle that originally sent price request.
     * @param identifier Identifier of price request.
     * @param time Timestamp of price request.
     * @param ancillaryData extra data of price request.
     */

    function executeRequestPrice(
        uint8 sinkChainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public onlyGenericHandlerContract() {
        _requestPrice(sinkChainID, identifier, time, ancillaryData);
        _finalizeRequest(sinkChainID, identifier, time, ancillaryData);
        _getOracle().requestPrice(identifier, time, ancillaryData);
    }

    /**
     * @notice Convenience method to get cross-chain Bridge resource ID linking this contract with its SinkOracles.
     * @dev More details about Resource ID's here: https://chainbridge.chainsafe.io/spec/#resource-id
     * @return bytes32 Hash containing this stored chain ID.
     */
    function getResourceId() public view returns (bytes32) {
        return keccak256(abi.encode("Oracle", currentChainID));
    }

    /**
     * @notice Return DVM for this network.
     */
    function _getOracle() internal view returns (OracleAncillaryInterface) {
        return OracleAncillaryInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    /**
     * @notice This helper method is useful for shaping metadata that is passed into Bridge.deposit() that will
     * ultimately be used to publish a price on the SinkOracle.
     * @dev GenericHandler.deposit() expects data to be formatted as:
     *     len(data)                              uint256     bytes  0  - 32
     *     data                                   bytes       bytes  64 - END
     * @param chainID Chain ID of SinkOracle to publish price to.
     * @param identifier Identifier of price request to publish.
     * @param time Timestamp of price request to publish.
     * @param ancillaryData extra data of price request to publish.
     * @return bytes Formatted metadata.
     */
    function formatMetadata(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) public pure returns (bytes memory) {
        bytes memory metadata = abi.encode(chainID, identifier, time, ancillaryData, price);
        return abi.encodePacked(metadata.length, metadata);
    }
}