// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../oracle/interfaces/FinderInterface.sol";
import "./IBridge.sol";
import "../oracle/implementation/Constants.sol";

/**
 * @title Simple implementation of the OracleInterface used to communicate price request data cross-chain between
 * EVM networks. Can be extended either into a "Source" or "Sink" oracle that specializes in making and resolving
 * cross-chain price requests, respectivly. The "Source" Oracle is the originator or source of price resolution data
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

    // Mapping of encoded price requests {identifier, time, ancillaryData} to Price objects.
    mapping(bytes32 => Price) internal prices;

    // Finder to provide addresses for DVM system contracts.
    FinderInterface public finder;

    event PriceRequestAdded(
        address indexed requester,
        uint8 indexed chainID,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );
    event PushedPrice(
        address indexed pusher,
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
     * @notice Enqueues a request (if a request isn't already present) for the given (identifier, time, ancillary data)
     * pair. Will revert if request has been requested already.
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
            emit PriceRequestAdded(msg.sender, chainID, identifier, time, ancillaryData);
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
        emit PushedPrice(msg.sender, chainID, identifier, time, ancillaryData, lookup.price);
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

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./BeaconOracle.sol";
import "../oracle/interfaces/OracleAncillaryInterface.sol";
import "../oracle/interfaces/RegistryInterface.sol";

/**
 * @title Extension of BeaconOracle that is intended to be deployed on non-Mainnet networks to give financial
 * contracts on those networks the ability to trigger cross-chain price requests to the Mainnet DVM. Also has the
 * ability to receive published prices from Mainnet. This contract can be treated as the "DVM" for a non-Mainnet
 * network, because a calling contract can request and access a resolved price request from this contract.
 * @dev The intended client of this contract is an OptimisticOracle on a non-Mainnet network that needs price
 * resolution secured by the DVM on Mainnet. If a registered contract, such as the OptimisticOracle, calls
 * `requestPrice()` on this contract, then it will call the network's Bridge contract to signal to an off-chain
 * relayer to bridge a price request to Mainnet.
 */
contract SinkOracle is BeaconOracle, OracleAncillaryInterface {
    // Chain ID of the Source Oracle that will communicate this contract's price request to the DVM on Mainnet.
    uint8 public destinationChainID;

    constructor(
        address _finderAddress,
        uint8 _chainID,
        uint8 _destinationChainID
    ) BeaconOracle(_finderAddress, _chainID) {
        destinationChainID = _destinationChainID;
    }

    // This assumes that the local network has a Registry that resembles the Mainnet registry.
    modifier onlyRegisteredContract() {
        RegistryInterface registry = RegistryInterface(finder.getImplementationAddress(OracleInterfaces.Registry));
        require(registry.isContractRegistered(msg.sender), "Caller must be registered");
        _;
    }

    /***************************************************************
     * Bridging a Price Request to L1:
     ***************************************************************/

    /**
     * @notice This is the first method that should be called in order to bridge a price request to Mainnet.
     * @dev Can be called only by a Registered contract that is allowed to make DVM price requests. Will mark this
     * price request as Requested, and therefore able to receive the ultimate price resolution data, and also
     * calls the local Bridge's deposit() method which will emit a Deposit event in order to signal to an off-chain
     * relayer to begin the cross-chain process.
     */
    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public override onlyRegisteredContract() {
        bytes32 priceRequestId = _encodePriceRequest(currentChainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        if (lookup.state != RequestState.NeverRequested) {
            // Clients expect that `requestPrice` does not revert if a price is already requested, so return gracefully.
            return;
        } else {
            _requestPrice(currentChainID, identifier, time, ancillaryData);

            // Initiate cross-chain price request, which should lead the `Bridge` to call `validateDeposit` on this
            // contract.
            _getBridge().deposit(
                destinationChainID,
                getResourceId(),
                formatMetadata(currentChainID, identifier, time, ancillaryData)
            );
        }
    }

    /**
     * @notice This method will ultimately be called after `requestPrice` calls `Bridge.deposit()`, which will call
     * `GenericHandler.deposit()` and ultimately this method.
     * @dev This method should basically check that the `Bridge.deposit()` was triggered by a valid price request,
     * specifically one that has not resolved yet and was called by a registered contract. Without this check,
     * `Bridge.deposit()` could be called by non-registered contracts to make price requests to the DVM.
     */
    function validateDeposit(
        uint8 sinkChainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public {
        // Advance state so that directly calling Bridge.deposit will revert and not emit a duplicate `Deposit` event.
        _finalizeRequest(sinkChainID, identifier, time, ancillaryData);
    }

    /***************************************************************
     * Responding to Price Request Resolution from L1:
     ***************************************************************/

    /**
     * @notice This method will ultimately be called after a `publishPrice` has been bridged cross-chain from Mainnet
     * to this network via an off-chain relayer. The relayer will call `Bridge.executeProposal` on this local network,
     * which call `GenericHandler.executeProposal()` and ultimately this method.
     * @dev This method should publish the price data for a requested price request. If this method fails for some
     * reason, then it means that the price was never requested. Can only be called by the `GenericHandler`.
     */
    function executePublishPrice(
        uint8 sinkChainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) public onlyGenericHandlerContract() {
        _publishPrice(sinkChainID, identifier, time, ancillaryData, price);
        _finalizePublish(sinkChainID, identifier, time, ancillaryData);
    }

    /**
     * @notice Returns whether a price has resolved for the request.
     * @return True if a price is available, False otherwise. If true, then getPrice will succeed for the request.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract() returns (bool) {
        bytes32 priceRequestId = _encodePriceRequest(currentChainID, identifier, time, ancillaryData);
        return prices[priceRequestId].state == RequestState.Resolved;
    }

    /**
     * @notice Returns resolved price for the request.
     * @return int256 Price, or reverts if no resolved price for any reason.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract() returns (int256) {
        bytes32 priceRequestId = _encodePriceRequest(currentChainID, identifier, time, ancillaryData);
        Price storage lookup = prices[priceRequestId];
        require(lookup.state == RequestState.Resolved, "Price has not been resolved");
        return lookup.price;
    }

    /**
     * @notice Convenience method to get cross-chain Bridge resource ID linking this contract with the SourceOracle.
     * @dev More details about Resource ID's here: https://chainbridge.chainsafe.io/spec/#resource-id
     * @return bytes32 Hash containing the chain ID of the SourceOracle.
     */
    function getResourceId() public view returns (bytes32) {
        return keccak256(abi.encode("Oracle", destinationChainID));
    }

    /**
     * @notice This helper method is useful for calling Bridge.deposit().
     * @dev GenericHandler.deposit() expects data to be formatted as:
     *     len(data)                              uint256     bytes  0  - 64
     *     data                                   bytes       bytes  64 - END
     */
    function formatMetadata(
        uint8 chainID,
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public pure returns (bytes memory) {
        bytes memory metadata = abi.encode(chainID, identifier, time, ancillaryData);
        return abi.encodePacked(metadata.length, metadata);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for a registry of contracts and contract creators.
 */
interface RegistryInterface {
    /**
     * @notice Registers a new contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties an array of addresses who become parties in the contract.
     * @param contractAddress defines the address of the deployed contract.
     */
    function registerContract(address[] calldata parties, address contractAddress) external;

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view returns (bool);

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view returns (address[] memory);

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view returns (address[] memory);

    /**
     * @notice Adds a party to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be added to the contract.
     */
    function addPartyToContract(address party) external;

    /**
     * @notice Removes a party member to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be removed from the contract.
     */
    function removePartyFromContract(address party) external;

    /**
     * @notice checks if an address is a party in a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) external view returns (bool);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 199
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}