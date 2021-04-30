/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// File: contracts/oracle/interfaces/FinderInterface.sol

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

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

// File: contracts/chainbridge/IBridge.sol

pragma solidity ^0.6.0;

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

// File: contracts/oracle/implementation/Constants.sol

pragma solidity ^0.6.0;

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

// File: contracts/oracle/interfaces/OracleAncillaryInterface.sol

pragma solidity ^0.6.0;

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

// File: contracts/chainbridge/BeaconOracle.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;





/**
 * @title Simple implementation of the OracleInterface used to communicate price request data cross-chain between
 * EVM networks. Can be extended either into a "Source" or "Sink" oracle that specializes in making and resolving
 * cross-chain price requests, respectivly. The "Source" Oracle is the originator or source of price resolution data
 * and can only resolve prices already published by the DVM. The "Sink" Oracle receives the price resolution data
 * from the Source Oracle and makes it available on non-Mainnet chains. The "Sink" Oracle can also be used to trigger
 * price requests from the DVM on Mainnet.
 */
abstract contract BeaconOracle is OracleAncillaryInterface {
    enum RequestState { NeverRequested, Requested, Resolved }

    struct Price {
        RequestState state;
        int256 price;
    }

    // Mapping of encoded price requests {identifier, time, ancillaryData} to Price objects.
    mapping(bytes32 => Price) internal prices;

    // Finder to provide addresses for DVM system contracts.
    FinderInterface public finder;

    // Chain ID for this Beacon Oracle. Used to construct ResourceID along with this contract address.
    uint8 public chainID;

    event PriceRequestAdded(address indexed requester, bytes32 indexed identifier, uint256 time, bytes ancillaryData);
    event PushedPrice(
        address indexed pusher,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        int256 price
    );

    /**
     * @notice Constructor.
     * @param _finderAddress finder to use to get addresses of DVM contracts.
     */
    constructor(address _finderAddress, uint8 _chainID) public {
        finder = FinderInterface(_finderAddress);
        chainID = _chainID;
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
     * @notice Returns whether a price has resolved for the request.
     * @return True if a price is available, False otherwise. If true, then getPrice will succeed for the request.
     */

    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override returns (bool) {
        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        if (lookup.state == RequestState.Resolved) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Returns resolved price for the request.
     * @return int256 Price, or reverts if no resolved price for any reason.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override returns (int256) {
        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.Resolved, "Price has not been resolved");
        return lookup.price;
    }

    /**
     * @notice Enqueues a request (if a request isn't already present) for the given (identifier, time, ancillary data)
     * pair. Will revert if request has been requested already.
     */
    function _requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) internal {
        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.NeverRequested, "Price has already been requested");
        // New query, change state to Requested:
        lookup.state = RequestState.Requested;
        emit PriceRequestAdded(msg.sender, identifier, time, ancillaryData);
    }

    /**
     * @notice Publishes price for a requested query. Will revert if request hasn't been requested yet or has been
     * resolved already.
     */
    function _publishPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) internal {
        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.Requested, "Price request is not currently pending");
        lookup.price = price;
        lookup.state = RequestState.Resolved;
        emit PushedPrice(msg.sender, identifier, time, ancillaryData, lookup.price);
    }

    /**
     * @notice Returns Bridge contract on network.
     */
    function _getBridge() internal view returns (IBridge) {
        return IBridge(finder.getImplementationAddress(OracleInterfaces.Bridge));
    }

    /**
     * @notice Returns the convenient way to store price requests, uniquely identified by {identifier, time,
     * ancillaryData }.
     */
    function _encodePriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(identifier, time, ancillaryData));
    }
}

// File: contracts/chainbridge/SourceOracle.sol

pragma solidity ^0.6.0;


/**
 * @title Simple implementation of the OracleInterface that is intended to be deployed on Mainnet and used
 * to communicate price request data cross-chain with Sink Oracles on non-Mainnet networks. An Admin can publish
 * prices to this oracle. An off-chain relayer can subsequently see when prices are published and signal to publish
 * those prices to any non-Mainnet Sink Oracles.
 * @dev This contract should be able to make price requests to the DVM, and the Admin capable of making and publishing
 * price reqests should be an off-chain relayer capable of detecting signals from the non-Mainnet Sink Oracles.
 */
/**
 * @title Extension of BeaconOracle that is intended to be deployed on Mainnet to give financial
 * contracts on non-Mainnet networks the ability to trigger cross-chain price requests to the Mainnet DVM. This contract
 * is responsible for triggering price requests originating from non-Mainnet, and broadcasting resolved price data
 * back to those networks.
 * @dev The intended client of this contract is some off-chain bot watching for resolved price events on the DVM. Once
 * that bot sees a price has resolved, it can call `publishPrice()` on this contract which will call the local Bridge
 * contract to signal to an off-chain relayer to bridge a price request to another network.
 */
contract SourceOracle is BeaconOracle {
    constructor(address _finderAddress, uint8 _chainID) public BeaconOracle(_finderAddress, _chainID) {}

    /***************************************************************
     * Publishing Price Request Data from Mainnet:
     ***************************************************************/

    /***************************************************************
     * Bridging a Price Request to Mainnet:
     ***************************************************************/

    /**
     * @notice This is the first method that should be called in order to publish a price request to another network
     * marked by `destinationChainID`.
     * @dev Can only be called with the same `price` that has been resolved for this request on the DVM. Will call the
     * local Bridge's deposit() method which will emit a Deposit event in order to signal to an off-chain
     * relayer to begin the cross-chain process.
     */
    function publishPrice(
        uint8 destinationChainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) public {
        require(_getOracle().hasPrice(identifier, time, ancillaryData), "DVM has not resolved price");
        require(_getOracle().getPrice(identifier, time, ancillaryData) == price, "DVM resolved different price");
        _publishPrice(identifier, time, ancillaryData, price);

        // Call Bridge.deposit() to initiate cross-chain publishing of price request.
        _getBridge().deposit(
            destinationChainID,
            getResourceId(),
            _formatMetadata(identifier, time, ancillaryData, price)
        );
    }

    /**
     * @notice This method will ultimately be called after `publishPrice` calls `Bridge.deposit()`, which will call
     * `GenericHandler.deposit()` and ultimately this method.
     * @dev This method should basically check that the `Bridge.deposit()` was triggered by a valid publish event.
     */
    function validateDeposit(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) public view {
        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.Resolved, "Price has not been published");
    }

    /**
     * @notice This method will ultimately be called after a `requestPrice` has been bridged cross-chain from
     * non-Mainnet to this network via an off-chain relayer. The relayer will call `Bridge.executeProposal` on this
     * local network, which call `GenericHandler.executeProposal()` and ultimately this method.
     * @dev This method should prepare this oracle to receive a published price and then forward the price request
     * to the DVM. Can only be called by the `GenericHandler`.
     */

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public override onlyGenericHandlerContract() {
        _requestPrice(identifier, time, ancillaryData);
        _getOracle().requestPrice(identifier, time, ancillaryData);
    }

    /**
     * @notice Convenience method to get cross-chain Bridge resource ID linking this contract with its SinkOracles.
     * @dev More details about Resource ID's here: https://chainbridge.chainsafe.io/spec/#resource-id
     * @return bytes32 Hash containing this stored chain ID.
     */
    function getResourceId() public view returns (bytes32) {
        return keccak256(abi.encode("Oracle", chainID));
    }

    /**
     * @notice Return DVM for this network.
     */
    function _getOracle() internal view returns (OracleAncillaryInterface) {
        return OracleAncillaryInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    /**
     * @notice This helper method is useful for calling Bridge.deposit().
     * @dev GenericHandler.deposit() expects data to be formatted as:
     *     len(data)                              uint256     bytes  0  - 64
     *     data                                   bytes       bytes  64 - END
     */
    function _formatMetadata(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) internal view returns (bytes memory) {
        bytes memory metadata = abi.encode(identifier, time, ancillaryData, price);
        return abi.encodePacked(metadata.length, metadata);
    }
}