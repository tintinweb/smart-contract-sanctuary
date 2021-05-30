/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;


/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IGenericHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}, {depositFunctionSig}, and {executeFunctionSig}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param depositFunctionDepositerOffset Depositer address position offset in the metadata, in bytes.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint depositFunctionDepositerOffset,
        bytes4 executeFunctionSig) external;
}

/**
    @title Handles generic deposits and deposit executions.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract GenericHandler is IGenericHandler {
    address public _bridgeAddress;

    struct DepositRecord {
        uint8   _destinationChainID;
        address _depositer;
        bytes32 _resourceID;
        bytes   _metaData;
    }

    // depositNonce => Deposit Record
    mapping (uint8 => mapping(uint64 => DepositRecord)) public _depositRecords;

    // resourceID => contract address
    mapping (bytes32 => address) public _resourceIDToContractAddress;

    // contract address => resourceID
    mapping (address => bytes32) public _contractAddressToResourceID;

    // contract address => deposit function signature
    mapping (address => bytes4) public _contractAddressToDepositFunctionSignature;

    // contract address => depositer address position offset in the metadata
    mapping (address => uint256) public _contractAddressToDepositFunctionDepositerOffset;
 
    // contract address => execute proposal function signature
    mapping (address => bytes4) public _contractAddressToExecuteFunctionSignature;

    // token contract address => is whitelisted
    mapping (address => bool) public _contractWhitelist;

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    function _onlyBridge() private {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
        @param initialResourceIDs Resource IDs used to identify a specific contract address.
        These are the Resource IDs this contract will initially support.
        @param initialContractAddresses These are the addresses the {initialResourceIDs} will point to, and are the contracts that will be
        called to perform deposit and execution calls.
        @param initialDepositFunctionSignatures These are the function signatures {initialContractAddresses} will point to,
        and are the function that will be called when executing {deposit}
        @param initialDepositFunctionDepositerOffsets These are the offsets of depositer positions, inside of metadata used to call
        {initialContractAddresses} when executing {deposit}
        @param initialExecuteFunctionSignatures These are the function signatures {initialContractAddresses} will point to,
        and are the function that will be called when executing {executeProposal}

        @dev {initialResourceIDs}, {initialContractAddresses}, {initialDepositFunctionSignatures},
        and {initialExecuteFunctionSignatures} must all have the same length. Also,
        values must be ordered in the way that that index x of any mentioned array
        must be intended for value x of any other array, e.g. {initialContractAddresses}[0]
        is the intended address for {initialDepositFunctionSignatures}[0].
     */
    constructor(
        address          bridgeAddress,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        bytes4[]  memory initialDepositFunctionSignatures,
        uint256[] memory initialDepositFunctionDepositerOffsets,
        bytes4[]  memory initialExecuteFunctionSignatures
    ) public {
        require(initialResourceIDs.length == initialContractAddresses.length,
            "initialResourceIDs and initialContractAddresses len mismatch");

        require(initialContractAddresses.length == initialDepositFunctionSignatures.length,
            "provided contract addresses and function signatures len mismatch");

        require(initialDepositFunctionSignatures.length == initialExecuteFunctionSignatures.length,
            "provided deposit and execute function signatures len mismatch");

        require(initialDepositFunctionDepositerOffsets.length == initialExecuteFunctionSignatures.length,
            "provided depositer offsets and function signatures len mismatch");

        _bridgeAddress = bridgeAddress;

        for (uint256 i = 0; i < initialResourceIDs.length; i++) {
            _setResource(
                initialResourceIDs[i],
                initialContractAddresses[i],
                initialDepositFunctionSignatures[i],
                initialDepositFunctionDepositerOffsets[i],
                initialExecuteFunctionSignatures[i]);
        }
    }

    /**
        @param depositNonce This ID will have been generated by the Bridge contract.
        @param destId ID of chain deposit will be bridged to.
        @return DepositRecord which consists of:
        - _destinationChainID ChainID deposited tokens are intended to end up on.
        - _resourceID ResourceID used when {deposit} was executed.
        - _depositer Address that initially called {deposit} in the Bridge contract.
        - _metaData Data to be passed to method executed in corresponding {resourceID} contract.
    */
    function getDepositRecord(uint64 depositNonce, uint8 destId) external view returns (DepositRecord memory) {
        return _depositRecords[destId][depositNonce];
    }

    /**
        @notice First verifies {_resourceIDToContractAddress}[{resourceID}] and
        {_contractAddressToResourceID}[{contractAddress}] are not already set,
        then sets {_resourceIDToContractAddress} with {contractAddress},
        {_contractAddressToResourceID} with {resourceID},
        {_contractAddressToDepositFunctionSignature} with {depositFunctionSig},
        {_contractAddressToDepositFunctionDepositerOffset} with {depositFunctionDepositerOffset},
        {_contractAddressToExecuteFunctionSignature} with {executeFunctionSig},
        and {_contractWhitelist} to true for {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param depositFunctionDepositerOffset Depositer address position offset in the metadata, in bytes.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) external onlyBridge override {

        _setResource(resourceID, contractAddress, depositFunctionSig, depositFunctionDepositerOffset, executeFunctionSig);
    }

    /**
        @notice A deposit is initiatied by making a deposit in the Bridge contract.
        @param destinationChainID Chain ID deposit is expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param depositer Address of the account making deposit in the Bridge contract.
        @param data Consists of: {resourceID}, {lenMetaData}, and {metaData} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  64 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToDepositFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
     */
    function deposit(bytes32 resourceID, uint8 destinationChainID, uint64 depositNonce, address depositer, bytes calldata data) external onlyBridge {
        uint256      lenMetadata;
        bytes memory metadata;

        lenMetadata = abi.decode(data, (uint256));
        metadata = bytes(data[32:32 + lenMetadata]);

        address contractAddress = _resourceIDToContractAddress[resourceID];
        uint256 depositerOffset = _contractAddressToDepositFunctionDepositerOffset[contractAddress];
        if (depositerOffset > 0) {
            uint256 metadataDepositer;
            // Skipping 32 bytes of length prefix and depositerOffset bytes.
            assembly {
                metadataDepositer := mload(add(add(metadata, 32), depositerOffset))
            }
            // metadataDepositer contains 0xdepositerAddressdepositerAddressdeposite************************
            // Shift it 12 bytes right:   0x000000000000000000000000depositerAddressdepositerAddressdeposite
            require(depositer == address(metadataDepositer >> 96), 'incorrect depositer in the data');
        }

        require(_contractWhitelist[contractAddress], "provided contractAddress is not whitelisted");

        bytes4 sig = _contractAddressToDepositFunctionSignature[contractAddress];
        if (sig != bytes4(0)) {
            bytes memory callData = abi.encodePacked(sig, metadata);
            (bool success,) = contractAddress.call(callData);
            require(success, "call to contractAddress failed");
        }

        _depositRecords[destinationChainID][depositNonce] = DepositRecord(
            destinationChainID,
            depositer,
            resourceID,
            metadata
        );
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        @param data Consists of {resourceID}, {lenMetaData}, and {metaData}.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  32 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToExecuteFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external onlyBridge {
        uint256      lenMetadata;
        bytes memory metaData;

        lenMetadata = abi.decode(data, (uint256)); 
        metaData = bytes(data[32:32 + lenMetadata]);

        address contractAddress = _resourceIDToContractAddress[resourceID];
        require(_contractWhitelist[contractAddress], "provided contractAddress is not whitelisted");

        bytes4 sig = _contractAddressToExecuteFunctionSignature[contractAddress];
        if (sig != bytes4(0)) {
            bytes memory callData = abi.encodePacked(sig, metaData);
            (bool success,) = contractAddress.call(callData);
            require(success, "delegatecall to contractAddress failed");
        }
    }

    function _setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) internal {
        _resourceIDToContractAddress[resourceID] = contractAddress;
        _contractAddressToResourceID[contractAddress] = resourceID;
        _contractAddressToDepositFunctionSignature[contractAddress] = depositFunctionSig;
        _contractAddressToDepositFunctionDepositerOffset[contractAddress] = depositFunctionDepositerOffset;
        _contractAddressToExecuteFunctionSignature[contractAddress] = executeFunctionSig;

        _contractWhitelist[contractAddress] = true;
    }

    /**
        @notice Used to update the _bridgeAddress.
        @param newBridgeAddress Address of the updated _bridgeAddress.
     */
    function updateBridgeAddress(address newBridgeAddress) external onlyBridge {
        require(_bridgeAddress != newBridgeAddress, "the updated address is the same with the old");

        _bridgeAddress = newBridgeAddress;
    }

}