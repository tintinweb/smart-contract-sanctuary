pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "./BasicNFTBridge.sol";
import "./modules/gas_limit/SelectorTokenGasLimitConnector.sol";

/**
 * @title HomeNFTBridge
 * @dev Home side implementation for multi-token ERC721 mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract HomeNFTBridge is BasicNFTBridge, SelectorTokenGasLimitConnector {
    constructor(string memory _suffix) BasicNFTBridge(_suffix) {}

    /**
     * @dev Stores the initial parameters of the mediator.
     * @param _bridgeContract the address of the AMB bridge contract.
     * @param _mediatorContract the address of the mediator contract on the other network.
     * @param _gasLimitManager the gas limit manager contract address.
     * @param _owner address of the owner of the mediator contract.
     * @param _imageERC721 address of the ERC721 token image.
     * @param _imageERC1155 address of the ERC1155 token image.
     */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        address _gasLimitManager,
        address _owner,
        address _imageERC721,
        address _imageERC1155
    ) external onlyRelevantSender initializer {
        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setGasLimitManager(_gasLimitManager);
        _setOwner(_owner);
        _setTokenImageERC721(_imageERC721);
        _setTokenImageERC1155(_imageERC1155);
    }

    /**
     * @dev Internal function for sending an AMB message to the mediator on the other side.
     * @param _data data to be sent to the other side of the bridge.
     * @param _useOracleLane true, if the message should be sent to the oracle driven lane.
     * @return id of the sent message.
     */
    function _passMessage(bytes memory _data, bool _useOracleLane) internal override returns (bytes32) {
        address executor = mediatorContractOnOtherSide();
        uint256 gasLimit = _chooseRequestGasLimit(_data);
        IAMB bridge = bridgeContract();

        return
        _useOracleLane
        ? bridge.requireToPassMessage(executor, _data, gasLimit)
        : bridge.requireToConfirmMessage(executor, _data, gasLimit);
    }


    function isHomeBridge() public override view returns (bool){
        return true;
    }
}

pragma solidity 0.7.5;

import "../../../../interfaces/IAMB.sol";
import "../../BasicNFTBridge.sol";
import "../BridgeModule.sol";

/**
 * @title SelectorTokenGasLimitManager
 * @dev Multi NFT mediator functionality for managing request gas limits.
 */
contract SelectorTokenGasLimitManager is BridgeModule {
    IAMB public bridge;

    uint256 internal defaultGasLimit;
    mapping(bytes4 => uint256) internal selectorGasLimit;
    mapping(bytes4 => mapping(address => uint256)) internal selectorTokenGasLimit;

    /**
     * @dev Initializes this module contract. Intended to be called only once through the proxy pattern.
     * @param _bridge address of the AMB bridge contract to which bridge mediator is connected.
     * @param _mediator address of the bridge contract working with this module.
     * @param _gasLimit default gas limit for the message execution.
     */
    function initialize(
        IAMB _bridge,
        IOwnable _mediator,
        uint256 _gasLimit
    ) external {
        require(address(mediator) == address(0));

        require(_gasLimit <= _bridge.maxGasPerTx());
        mediator = _mediator;
        bridge = _bridge;
        defaultGasLimit = _gasLimit;
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Throws if provided gas limit is greater then the maximum allowed gas limit in the AMB contract.
     * @param _gasLimit gas limit value to check.
     */
    modifier validGasLimit(uint256 _gasLimit) {
        require(_gasLimit <= bridge.maxGasPerTx());
        _;
    }

    /**
     * @dev Throws if one of the provided gas limits is greater then the maximum allowed gas limit in the AMB contract.
     * @param _length expected length of the _gasLimits array.
     * @param _gasLimits array of gas limit values to check, should contain exactly _length elements.
     */
    modifier validGasLimits(uint256 _length, uint256[] calldata _gasLimits) {
        require(_gasLimits.length == _length);
        uint256 maxGasLimit = bridge.maxGasPerTx();
        for (uint256 i = 0; i < _length; i++) {
            require(_gasLimits[i] <= maxGasLimit);
        }
        _;
    }

    /**
     * @dev Sets the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(uint256 _gasLimit) external onlyOwner validGasLimit(_gasLimit) {
        defaultGasLimit = _gasLimit;
    }

    /**
     * @dev Sets the selector-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _selector method selector of the outgoing message payload.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(bytes4 _selector, uint256 _gasLimit) external onlyOwner validGasLimit(_gasLimit) {
        selectorGasLimit[_selector] = _gasLimit;
    }

    /**
     * @dev Sets the token-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _selector method selector of the outgoing message payload.
     * @param _token address of the native token that is used in the first argument of handleBridgedTokens/handleNativeTokens.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(
        bytes4 _selector,
        address _token,
        uint256 _gasLimit
    ) external onlyOwner validGasLimit(_gasLimit) {
        selectorTokenGasLimit[_selector][_token] = _gasLimit;
    }

    /**
     * @dev Tells the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit() public view returns (uint256) {
        return defaultGasLimit;
    }

    /**
     * @dev Tells the selector-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _selector method selector for the passed message.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(bytes4 _selector) public view returns (uint256) {
        return selectorGasLimit[_selector];
    }

    /**
     * @dev Tells the token-specific gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _selector method selector for the passed message.
     * @param _token address of the native token that is used in the first argument of handleBridgedTokens/handleNativeTokens.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(bytes4 _selector, address _token) public view returns (uint256) {
        return selectorTokenGasLimit[_selector][_token];
    }

    /**
     * @dev Tells the gas limit to use for the message execution by the AMB bridge on the other network.
     * @param _data calldata to be used on the other side of the bridge, when execution a message.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit(bytes memory _data) external view returns (uint256) {
        bytes4 selector;
        address token;
        assembly {
            // first 4 bytes of _data contain the selector of the function to be called on the other side of the bridge.
            // mload(add(_data, 4)) loads selector to the 28-31 bytes of the word.
            // shl(28 * 8, x) then used to correct the padding of the selector, putting it to 0-3 bytes of the word.
            selector := shl(224, mload(add(_data, 4)))
            // handleBridgedTokens/handleNativeTokens/... passes bridged token address as the first parameter.
            // it is located in the 4-35 bytes of the calldata.
            // 36 = bytes length padding (32) + selector length (4)
            token := mload(add(_data, 36))
        }
        uint256 gasLimit = selectorTokenGasLimit[selector][token];
        if (gasLimit == 0) {
            gasLimit = selectorGasLimit[selector];
            if (gasLimit == 0) {
                gasLimit = defaultGasLimit;
            }
        }
        return gasLimit;
    }

    /**
     * @dev Sets the default values for different NFT Bridge selectors.
     * @param _gasLimits array with 4 gas limits for the following selectors of the outgoing messages:
     * - deployAndHandleBridgedNFT
     * - handleBridgedNFT
     * - handleNativeNFT
     * - fixFailedMessage
     * Only the owner can call this method.
     */
    function setCommonRequestGasLimits(uint256[] calldata _gasLimits) external onlyOwner validGasLimits(3, _gasLimits) {
        require(_gasLimits[0] >= _gasLimits[1]);
//        selectorGasLimit[BasicNFTBridge.deployAndHandleBridgedNFT.selector] = _gasLimits[0];
        selectorGasLimit[BasicNFTBridge.handleBridgedNFT.selector] = _gasLimits[0];
        selectorGasLimit[BasicNFTBridge.handleNativeNFT.selector] = _gasLimits[1];
        selectorGasLimit[FailedMessagesProcessor.fixFailedMessage.selector] = _gasLimits[2];
    }

    /**
     * @dev Sets the request gas limits for some specific token bridged from Foreign side of the bridge.
     * @param _token address of the native token contract on the Foreign side.
     * @param _gasLimits array with 1 gas limit for the following selectors of the outgoing messages:
     * - handleNativeNFT
     * Only the owner can call this method.
     */
    function setBridgedTokenRequestGasLimits(address _token, uint256[] calldata _gasLimits)
        external
        onlyOwner
        validGasLimits(1, _gasLimits)
    {
        selectorTokenGasLimit[BasicNFTBridge.handleNativeNFT.selector][_token] = _gasLimits[0];
    }

    /**
     * @dev Sets the request gas limits for some specific token native to the Home side of the bridge.
     * @param _token address of the native token contract on the Home side.
     * @param _gasLimits array with 2 gas limits for the following selectors of the outgoing messages:
     * - deployAndHandleBridgedNFT
     * - handleBridgedNFT
     * Only the owner can call this method.
     */
    function setNativeTokenRequestGasLimits(address _token, uint256[] calldata _gasLimits)
        external
        onlyOwner
        validGasLimits(1, _gasLimits)
    {
        require(_gasLimits[0] >= _gasLimits[1]);
//        selectorTokenGasLimit[BasicNFTBridge.deployAndHandleBridgedNFT.selector][_token] = _gasLimits[0];
        selectorTokenGasLimit[BasicNFTBridge.handleBridgedNFT.selector][_token] = _gasLimits[0];
    }
}

pragma solidity 0.7.5;

import "../../../Ownable.sol";
import "./SelectorTokenGasLimitManager.sol";
import "../../../BasicAMBMediator.sol";

/**
 * @title SelectorTokenGasLimitConnector
 * @dev Connectivity functionality that is required for using gas limit manager.
 */
abstract contract SelectorTokenGasLimitConnector is Ownable, BasicAMBMediator {
    bytes32 internal constant GAS_LIMIT_MANAGER_CONTRACT =
        0x5f5bc4e0b888be22a35f2166061a04607296c26861006b9b8e089a172696a822; // keccak256(abi.encodePacked("gasLimitManagerContract"))

    /**
     * @dev Updates an address of the used gas limit manager contract.
     * @param _manager address of gas limit manager contract.
     */
    function setGasLimitManager(address _manager) external onlyOwner {
        _setGasLimitManager(_manager);
    }

    /**
     * @dev Retrieves an address of the gas limit manager contract.
     * @return address of the gas limit manager contract.
     */
    function gasLimitManager() public view returns (SelectorTokenGasLimitManager) {
        return SelectorTokenGasLimitManager(addressStorage[GAS_LIMIT_MANAGER_CONTRACT]);
    }

    /**
     * @dev Internal function for updating an address of the used gas limit manager contract.
     * @param _manager address of gas limit manager contract.
     */
    function _setGasLimitManager(address _manager) internal {
        require(_manager == address(0) || Address.isContract(_manager));
        addressStorage[GAS_LIMIT_MANAGER_CONTRACT] = _manager;
    }

    /**
     * @dev Tells the gas limit to use for the message execution by the AMB bridge on the other network.
     * @param _data calldata to be used on the other side of the bridge, when execution a message.
     * @return the gas limit for the message execution.
     */
    function _chooseRequestGasLimit(bytes memory _data) internal view returns (uint256) {
        SelectorTokenGasLimitManager manager = gasLimitManager();
        return address(manager) == address(0) ? maxGasPerTx() : manager.requestGasLimit(_data);
    }
}

pragma solidity 0.7.5;

/**
 * @title VersionableModule
 * @dev Interface for Omnibridge module versioning.
 */
interface VersionableModule {
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "./VersionableModule.sol";
import "../../../interfaces/IOwnable.sol";

/**
 * @title OmnibridgeModule
 * @dev Common functionality for Omnibridge extension non-upgradeable module.
 */
abstract contract BridgeModule is VersionableModule {
    IOwnable public mediator;

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == mediator.owner());
        _;
    }
}

pragma solidity 0.7.5;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title NativeTokensRegistry
 * @dev Functionality for keeping track of registered native tokens.
 */
contract NativeTokensRegistry is EternalStorage {
    uint256 internal constant REGISTERED = 1;
    uint256 internal constant REGISTERED_AND_DEPLOYED = 2;

    /**
     * @dev Checks if for a given native token, the deployment of its bridged alternative was already acknowledged.
     * @param _token address of native token contract.
     * @return true, if bridged token was already deployed.
     */
    function isBridgedTokenDeployAcknowledged(address _token) public view returns (bool) {
        return uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] == REGISTERED_AND_DEPLOYED;
    }

    /**
     * @dev Checks if a given token is a bridged token that is native to this side of the bridge.
     * @param _token address of token contract.
     * @return message id of the send message.
     */
    function isRegisteredAsNativeToken(address _token) public view returns (bool) {
        return uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] > 0;
    }

    /**
     * @dev Internal function for marking native token as registered.
     * @param _token address of the token contract.
     * @param _state registration state.
     */
    function _setNativeTokenIsRegistered(address _token, uint256 _state) internal {
        if (uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] != _state) {
            uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] = _state;
        }
    }
}

pragma solidity 0.7.5;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title NFTMediatorBalanceStorage
 * @dev Functionality for storing expected mediator balance for native tokens.
 */
contract NFTMediatorBalanceStorage is EternalStorage {
    /**
     * @dev Tells amount of owned tokens recorded at this mediator. More strict than regular token.ownerOf()/token.balanceOf() checks,
     * since does not take into account forced tokens.
     * @param _token address of token contract.
     * @param _tokenId id of the new owned token.
     * @return amount of owned tokens, 0 or 1 for ERC721 NFTs.
     */
    function mediatorOwns(address _token, uint256 _tokenId) public view returns (uint256 amount) {
        bytes32 key = _getStorageKey(_token, _tokenId);
        assembly {
            amount := sload(key)
        }
    }

    /**
     * @dev Updates ownership information for the particular token.
     * @param _token address of token contract.
     * @param _tokenId id of the new owned token.
     * @param _value amount of owned tokens, 0 or 1 for ERC721 NFTs.
     */
    function _setMediatorOwns(
        address _token,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        bytes32 key = _getStorageKey(_token, _tokenId);
        assembly {
            sstore(key, _value)
        }
    }

    function _getStorageKey(address _token, uint256 _tokenId) private pure returns (bytes32) {
        // same as boolStorage[keccak256(abi.encodePacked("mediatorOwns", _token, _tokenId))]
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked("mediatorOwns", _token, _tokenId)), uint256(4)));
    }
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "../../../Ownable.sol";

/**
 * @title MetadataReader
 * @dev Functionality for reading metadata from ERC721/ERC1155 tokens.
 */
contract MetadataReader is Ownable {
    /**
     * @dev Sets the custom metadata for the given ERC721/ERC1155 token.
     * Only owner can call this method.
     * Useful when original NFT token does not implement neither name() nor symbol() methods.
     * @param _token address of the token contract.
     * @param _name custom name for the token contract.
     * @param _symbol custom symbol for the token contract.
     */
    function setCustomMetadata(
        address _token,
        string calldata _name,
        string calldata _symbol
    ) external onlyOwner {
        stringStorage[keccak256(abi.encodePacked("customName", _token))] = _name;
        stringStorage[keccak256(abi.encodePacked("customSymbol", _token))] = _symbol;
    }

    /**
     * @dev Internal function for reading ERC721/ERC1155 token name.
     * Use custom predefined name in case name() function is not implemented.
     * @param _token address of the ERC721/ERC1155 token contract.
     * @return name for the token.
     */
    function _readName(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(IERC721Metadata.name.selector));
        return status ? abi.decode(data, (string)) : stringStorage[keccak256(abi.encodePacked("customName", _token))];
    }

    /**
     * @dev Internal function for reading ERC721/ERC1155 token symbol.
     * Use custom predefined symbol in case symbol() function is not implemented.
     * @param _token address of the ERC721/ERC1155 token contract.
     * @return symbol for the token.
     */
    function _readSymbol(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(IERC721Metadata.symbol.selector));
        return status ? abi.decode(data, (string)) : stringStorage[keccak256(abi.encodePacked("customSymbol", _token))];
    }

    /**
     * @dev Internal function for reading ERC721 token URI.
     * @param _token address of the ERC721 token contract.
     * @param _tokenId unique identifier for the token.
     * @return token URI for the particular token, if any.
     */
    function _readERC721TokenURI(address _token, uint256 _tokenId) internal view returns (string memory) {
        (bool status, bytes memory data) =
            _token.staticcall(abi.encodeWithSelector(IERC721Metadata.tokenURI.selector, _tokenId));
        return status ? abi.decode(data, (string)) : "";
    }

    /**
     * @dev Internal function for reading ERC1155 token URI.
     * @param _token address of the ERC1155 token contract.
     * @param _tokenId unique identifier for the token.
     * @return token URI for the particular token, if any.
     */
    function _readERC1155TokenURI(address _token, uint256 _tokenId) internal view returns (string memory) {
        (bool status, bytes memory data) =
            _token.staticcall(abi.encodeWithSelector(IERC1155MetadataURI.uri.selector, _tokenId));
        return status ? abi.decode(data, (string)) : "";
    }
}

pragma solidity 0.7.5;

import "../../../Ownable.sol";

/**
 * @title NFTBridgeLimits
 * @dev Functionality for keeping track of bridging limits for multiple ERC721 tokens.
 */
abstract contract NFTBridgeLimits is Ownable {
    // token == 0x00..00 represents global restriction applied for all tokens
    event TokenBridgingDisabled(address indexed token, bool disabled);
    event TokenExecutionDisabled(address indexed token, bool disabled);

    /**
     * @dev Checks if specified token was already bridged at least once.
     * @param _token address of the token contract.
     * @return true, if token was already bridged.
     */
    function isTokenRegistered(address _token) public view virtual returns (bool);

    /**
     * @dev Disabled bridging operations for the particular token.
     * @param _token address of the token contract, or address(0) for configuring the global restriction.
     * @param _disable true for disabling.
     */
    function disableTokenBridging(address _token, bool _disable) external onlyOwner {
        require(_token == address(0) || isTokenRegistered(_token));
        boolStorage[keccak256(abi.encodePacked("bridgingDisabled", _token))] = _disable;
        emit TokenBridgingDisabled(_token, _disable);
    }

    /**
     * @dev Disabled execution operations for the particular token.
     * @param _token address of the token contract, or address(0) for configuring the global restriction.
     * @param _disable true for disabling.
     */
    function disableTokenExecution(address _token, bool _disable) external onlyOwner {
        require(_token == address(0) || isTokenRegistered(_token));
        boolStorage[keccak256(abi.encodePacked("executionDisabled", _token))] = _disable;
        emit TokenExecutionDisabled(_token, _disable);
    }

    /**
     * @dev Tells if the bridging operations for the particular token are allowed.
     * @param _token address of the token contract.
     * @return true, if bridging operations are allowed.
     */
    function isTokenBridgingAllowed(address _token) public view returns (bool) {
        bool isDisabled = boolStorage[keccak256(abi.encodePacked("bridgingDisabled", _token))];
        if (isDisabled || _token == address(0)) {
            return !isDisabled;
        }
        return isTokenBridgingAllowed(address(0));
    }

    /**
     * @dev Tells if the execution operations for the particular token are allowed.
     * @param _token address of the token contract.
     * @return true, if execution operations are allowed.
     */
    function isTokenExecutionAllowed(address _token) public view returns (bool) {
        bool isDisabled = boolStorage[keccak256(abi.encodePacked("executionDisabled", _token))];
        if (isDisabled || _token == address(0)) {
            return !isDisabled;
        }
        return isTokenExecutionAllowed(address(0));
    }
}

pragma solidity 0.7.5;

import "../../../VersionableBridge.sol";

/**
 * @title NFTBridgeInfo
 * @dev Functionality for versioning NFTBridge mediator.
 */
contract NFTBridgeInfo is VersionableBridge {
    event TokensBridgingInitiated(
        address indexed token,
        address indexed sender,
        uint256[] tokenIds,
        uint256[] values,
        bytes32 indexed messageId
    );
    event TokensBridged(
        address indexed token,
        address indexed recipient,
        uint256[] tokenIds,
        uint256[] values,
        bytes32 indexed messageId
    );

    /**
     * @dev Tells the bridge interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getBridgeInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (3, 1, 0);
    }

    /**
     * @dev Tells the bridge mode that this contract supports.
     * @return _data 4 bytes representing the bridge mode
     */
    function getBridgeMode() external pure override returns (bytes4 _data) {
        return 0xca7fc3dc; // bytes4(keccak256(abi.encodePacked("multi-nft-to-nft-amb")))
    }
}

pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "../../../BasicAMBMediator.sol";
import "./BridgeOperationsStorage.sol";

/**
 * @title FailedMessagesProcessor
 * @dev Functionality for fixing failed bridging operations.
 */
abstract contract FailedMessagesProcessor is BasicAMBMediator, BridgeOperationsStorage {
    event FailedMessageFixed(bytes32 indexed messageId, address token);

    /**
     * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
     * fix/roll back the transferred assets on the other network.
     * It is important to specify parameters very carefully.
     * Please, take exact values from the TokensBridgingInitiated event. Otherwise, execution will revert.
     * @param _messageId id of the message which execution failed.
     * @param _token address of the bridged token on the other side of the bridge.
     * @param _sender address of the tokens sender on the other side.
     * @param _tokenIds ids of the sent tokens.
     * @param _values amounts of tokens sent.
     */
    function requestFailedMessageFix(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external {
        require(_tokenIds.length > 0);
        require(_values.length == 0 || _tokenIds.length == _values.length);

        IAMB bridge = bridgeContract();
        require(!bridge.messageCallStatus(_messageId));
        require(bridge.failedMessageReceiver(_messageId) == address(this));
        require(bridge.failedMessageSender(_messageId) == mediatorContractOnOtherSide());

        _passMessage(abi.encodeWithSelector(this.fixFailedMessage.selector, _messageId, _token, _sender, _tokenIds, _values),
            false);
    }

    /**
     * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
     * Compares the reconstructed message checksum with the original one. Revert if message params were altered.
     * @param _messageId id of the message which execution failed on this side of the bridge.
     * @param _token address of the bridged token on this side of the bridge.
     * @param _sender address of the tokens sender on this side of the bridge.
     * @param _tokenIds ids of the sent tokens.
     * @param _values amounts of tokens sent.
     */
    function fixFailedMessage(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) public onlyMediator {
        require(!messageFixed(_messageId));
        require(getMessageChecksum(_messageId) == _messageChecksum(_token, _sender, _tokenIds, _values));

        setMessageFixed(_messageId);
        executeActionOnFixedTokens(_token, _sender, _tokenIds, _values);
        emit FailedMessageFixed(_messageId, _token);
    }

    /**
     * @dev Tells if a message sent to the AMB bridge has been fixed.
     * @return bool indicating the status of the message.
     */
    function messageFixed(bytes32 _messageId) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))];
    }

    /**
     * @dev Sets that the message sent to the AMB bridge has been fixed.
     * @param _messageId of the message sent to the bridge.
     */
    function setMessageFixed(bytes32 _messageId) internal {
        boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))] = true;
    }

    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal virtual;
}

pragma solidity 0.7.5;

// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "../../../ReentrancyGuard.sol";
import "./BaseRelayer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC721Relayer
 * @dev Functionality for bridging multiple ERC721 tokens to the other side of the bridge.
 */
abstract contract ERC721Relayer is IERC721Receiver, BaseRelayer, ReentrancyGuard {
    /**
     * @dev ERC721 transfer callback function.
     * @param _from address of token sender.
     * @param _tokenId id of the transferred token.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        if (!lock()) {
            bridgeSpecificActionsOnTokenTransfer(
                msg.sender,
                _from,
                _chooseReceiver(_from, _data),
                _singletonArray(_tokenId),
                new uint256[](0)
            );
        }
        return msg.sig;
    }

    /**
     * @dev Initiate the bridge operation for some token from msg.sender.
     * The user should first call Approve method of the ERC721 token.
     * @param token bridged token contract address.
     * @param _receiver address that will receive the token on the other network.
     * @param _tokenId id of the token to be transferred to the other network.
     */
    function relayToken(
        IERC721 token,
        address _receiver,
        uint256 _tokenId
    ) external {
        _relayToken(token, _receiver, _tokenId);
    }

    /**
     * @dev Initiate the bridge operation for some token from msg.sender to msg.sender on the other side.
     * The user should first call Approve method of the ERC721 token.
     * @param token bridged token contract address.
     * @param _tokenId id of token to be transferred to the other network.
     */
    function relayToken(IERC721 token, uint256 _tokenId) external {
        _relayToken(token, msg.sender, _tokenId);
    }

    /**
     * @dev Validates that the token amount is inside the limits, calls transferFrom to transfer the token to the contract
     * and invokes the method to burn/lock the token and unlock/mint the token on the other network.
     * The user should first call Approve method of the ERC721 token.
     * @param _token bridge token contract address.
     * @param _receiver address that will receive the token on the other network.
     * @param _tokenId id of the token to be transferred to the other network.
     */
    function _relayToken(
        IERC721 _token,
        address _receiver,
        uint256 _tokenId
    ) internal {
        // This lock is to prevent calling bridgeSpecificActionsOnTokenTransfer twice.
        // When transferFrom is called, after the transfer, the ERC721 token might call onERC721Received from this contract
        // which will call bridgeSpecificActionsOnTokenTransfer.
        require(!lock(), "locked already");

        setLock(true);
        _token.safeTransferFrom(msg.sender, address(this), _tokenId);
        setLock(false);
        bridgeSpecificActionsOnTokenTransfer(
            address(_token),
            msg.sender,
            _receiver,
            _singletonArray(_tokenId),
            new uint256[](0)
        );
    }
}

pragma solidity 0.7.5;

// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "./BaseRelayer.sol";
import "../../../../interfaces/IBurnableMintableERC1155Token.sol";
import "../../../../interfaces/IERC1155TokenReceiver.sol";

/**
 * @title ERC1155Relayer
 * @dev Functionality for bridging multiple ERC1155 tokens to the other side of the bridge.
 */
abstract contract ERC1155Relayer is IERC1155TokenReceiver, BaseRelayer {
    // max batch size, so that deployAndHandleBridgedNFT fits in 1.000.000 gas
    uint256 internal constant MAX_BATCH_BRIDGE_AND_DEPLOY_LIMIT = 14;
    // max batch size, so that handleBridgedNFT fits in 1.000.000 gas
    uint256 internal constant MAX_BATCH_BRIDGE_LIMIT = 19;

    /**
     * @dev ERC1155 transfer callback function.
     * @param _from address of token sender.
     * @param _tokenId id of the transferred token.
     * @param _value amount of received tokens.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onERC1155Received(
        address,
        address _from,
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        bridgeSpecificActionsOnTokenTransfer(
            msg.sender,
            _from,
            _chooseReceiver(_from, _data),
            _singletonArray(_tokenId),
            _singletonArray(_value)
        );
        return msg.sig;
    }

    /**
     * @dev ERC1155 transfer callback function.
     * @param _from address of token sender.
     * @param _tokenIds unique ids of the received tokens.
     * @param _values amounts of received tokens.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        require(_tokenIds.length == _values.length);
        require(_tokenIds.length > 0);
        bridgeSpecificActionsOnTokenTransfer(
            msg.sender,
            _from,
            _chooseReceiver(_from, _data),
            _tokenIds,
            _values
        );
        return msg.sig;
    }
}

pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title BridgeOperationsStorage
 * @dev Functionality for storing processed bridged operations.
 */
abstract contract BridgeOperationsStorage is EternalStorage {
    /**
     * @dev Set bridged message checksum.
     * @param _messageId id of the sent AMB message.
     * @param _checksum checksum of the bridge operation.
     */
    function setMessageChecksum(bytes32 _messageId, bytes32 _checksum) internal {
        uintStorage[keccak256(abi.encodePacked("messageChecksum", _messageId))] = uint256(_checksum);
    }

    /**
     * @dev Tells the bridged message checksum.
     * @param _messageId id of the sent AMB message.
     * @return saved message checksum associated with the given message id.
     */
    function getMessageChecksum(bytes32 _messageId) internal view returns (bytes32) {
        return bytes32(uintStorage[keccak256(abi.encodePacked("messageChecksum", _messageId))]);
    }

    /**
     * @dev Calculates message checksum, used for verifying correctness of the given parameters when fixing message.
     * @param _token address of the bridged token contract on this side current side of the bridge.
     * @param _sender address of the tokens sender.
     * @param _tokenIds list of ids of sent tokens.
     * @param _values list of sent token amounts. Should be an empty array for ERC721 tokens.
     * @return message checksum.
     */
    function _messageChecksum(
        address _token,
        address _sender,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_token, _sender, _tokenIds, _values));
    }
}

pragma solidity 0.7.5;

import "../../../../libraries/Bytes.sol";

/**
 * @title BaseRelayer
 * @dev Basic functionality for relaying different NFT tokens to the other side of the bridge.
 */
abstract contract BaseRelayer {
    /**
     * @dev Helper function for alternative receiver feature. Chooses the actual receiver out of sender and passed data.
     * @param _from address of the token sender.
     * @param _data passed data in the transfer message.
     * @return recipient address of the receiver on the other side.
     */
    function _chooseReceiver(address _from, bytes memory _data) internal pure returns (address recipient) {
        recipient = _from;
        if (_data.length > 0) {
            require(_data.length == 20);
            recipient = Bytes.bytesToAddress(_data);
        }
    }

    /**
     * @dev Wraps a given uint256 value into an array with a single element.
     * @param _value argument to wrap.
     * @return wrapper array.
     */
    function _singletonArray(uint256 _value) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = _value;
        return array;
    }

    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal virtual;
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../../Ownable.sol";

/**
 * @title TokenImageStorage
 * @dev Storage functionality for working with ERC721/ERC1155 image contract.
 */
contract TokenImageStorage is Ownable {
    bytes32 internal constant ERC721_TOKEN_IMAGE_CONTRACT =
        0x20b8ca26cc94f39fab299954184cf3a9bd04f69543e4f454fab299f015b8130f; // keccak256(abi.encodePacked("tokenImageContract"))
    bytes32 internal constant ERC1155_TOKEN_IMAGE_CONTRACT =
        0x02e1d283efd236e8b97cefe072f0c863fa2db9f9ba42b0eca53ab31c49067a67; // keccak256(abi.encodePacked("erc1155tokenImageContract"))

    /**
     * @dev Updates address of the used ERC721 token image.
     * Only owner can call this method.
     * @param _image address of the new token image.
     */
    function setTokenImageERC721(address _image) external onlyOwner {
        _setTokenImageERC721(_image);
    }

    /**
     * @dev Updates address of the used ERC1155 token image.
     * Only owner can call this method.
     * @param _image address of the new token image.
     */
    function setTokenImageERC1155(address _image) external onlyOwner {
        _setTokenImageERC1155(_image);
    }

    /**
     * @dev Tells the address of the used ERC721 token image.
     * @return address of the used token image.
     */
    function tokenImageERC721() public view returns (address) {
        return addressStorage[ERC721_TOKEN_IMAGE_CONTRACT];
    }

    /**
     * @dev Tells the address of the used ERC1155 token image.
     * @return address of the used token image.
     */
    function tokenImageERC1155() public view returns (address) {
        return addressStorage[ERC1155_TOKEN_IMAGE_CONTRACT];
    }

    /**
     * @dev Internal function for updating address of the used ERC721 token image.
     * @param _image address of the new token image.
     */
    function _setTokenImageERC721(address _image) internal {
        require(Address.isContract(_image));
        addressStorage[ERC721_TOKEN_IMAGE_CONTRACT] = _image;
    }

    /**
     * @dev Internal function for updating address of the used ERC1155 token image.
     * @param _image address of the new token image.
     */
    function _setTokenImageERC1155(address _image) internal {
        require(Address.isContract(_image));
        addressStorage[ERC1155_TOKEN_IMAGE_CONTRACT] = _image;
    }
}

pragma solidity 0.7.5;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title BridgedTokensRegistry
 * @dev Functionality for keeping track of registered bridged token pairs.
 */
contract BridgedTokensRegistry is EternalStorage {
    event NewTokenRegistered(address indexed nativeToken, address indexed bridgedToken);

    /**
     * @dev Retrieves address of the bridged token contract associated with a specific native token contract on the other side.
     * @param _nativeToken address of the native token contract on the other side.
     * @return address of the deployed bridged token contract.
     */
    function bridgedTokenAddress(address _nativeToken) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("homeTokenAddress", _nativeToken))];
    }

    /**
     * @dev Retrieves address of the native token contract associated with a specific bridged token contract.
     * @param _bridgedToken address of the created bridged token contract on this side.
     * @return address of the native token contract on the other side of the bridge.
     */
    function nativeTokenAddress(address _bridgedToken) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("foreignTokenAddress", _bridgedToken))];
    }

    /**
     * @dev Internal function for updating a pair of addresses for the bridged token.
     * @param _nativeToken address of the native token contract on the other side.
     * @param _bridgedToken address of the created bridged token contract on this side.
     */
    function _setTokenAddressPair(address _nativeToken, address _bridgedToken) internal {
        addressStorage[keccak256(abi.encodePacked("homeTokenAddress", _nativeToken))] = _bridgedToken;
        addressStorage[keccak256(abi.encodePacked("foreignTokenAddress", _bridgedToken))] = _nativeToken;

        emit NewTokenRegistered(_nativeToken, _bridgedToken);
    }
}

pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "../Upgradeable.sol";
import "../../interfaces/IBurnableMintableERC721Token.sol";
import "../../interfaces/IBurnableMintableERC1155Token.sol";
import "./components/common/BridgeOperationsStorage.sol";
import "./components/common/FailedMessagesProcessor.sol";
import "./components/common/NFTBridgeLimits.sol";
import "./components/common/ERC721Relayer.sol";
import "./components/common/ERC1155Relayer.sol";
import "./components/common/NFTBridgeInfo.sol";
import "./components/native/NativeTokensRegistry.sol";
import "./components/native/MetadataReader.sol";
import "./components/bridged/BridgedTokensRegistry.sol";
import "./components/bridged/TokenImageStorage.sol";
import "./components/native/NFTMediatorBalanceStorage.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title BasicNFTBridge
 * @dev Commong functionality for multi-token mediator for ERC721 tokens intended to work on top of AMB bridge.
 */
abstract contract BasicNFTBridge is
Initializable,
Upgradeable,
BridgeOperationsStorage,
BridgedTokensRegistry,
NativeTokensRegistry,
NFTBridgeInfo,
NFTBridgeLimits,
MetadataReader,
TokenImageStorage,
ERC721Relayer,
ERC1155Relayer,
NFTMediatorBalanceStorage,
FailedMessagesProcessor
{
    using SafeMath for uint256;


    // Workaround for storing variable up-to-32 bytes suffix
    uint256 private immutable SUFFIX_SIZE;
    bytes32 private immutable SUFFIX;

    // Since contract is intended to be deployed under EternalStorageProxy, only constant and immutable variables can be set here
    constructor(string memory _suffix) {
        require(bytes(_suffix).length <= 32);
        bytes32 suffix;
        assembly {
            suffix := mload(add(_suffix, 32))
        }
        SUFFIX = suffix;
        SUFFIX_SIZE = bytes(_suffix).length;
    }

    function isHomeBridge() public virtual view returns (bool);


    /**
     * @dev Checks if specified token was already bridged at least once and it is registered in the bridge.
     * @param _token address of the token contract.
     * @return true, if token was already bridged.
     */
    function isTokenRegistered(address _token) public view override returns (bool) {
        return isRegisteredAsNativeToken(_token) || nativeTokenAddress(_token) != address(0);
    }

    /**
     * @dev Handles the bridged token for the already registered token pair.
     * Checks that the bridged token is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC721 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function handleBridgedNFT(
        address _token,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        string[] calldata _tokenURIs
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);

        _handleTokens(token, false, _recipient, _tokenIds, _values);
        _setTokensURI(token, _tokenIds, _tokenURIs);
    }

    /**
     * @dev Handles the bridged token that are native to this chain.
     * Checks that the bridged token is inside the execution limits and invokes the Unlock accordingly.
     * @param _token address of the native ERC721 token contract.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function handleNativeNFT(
        address _token,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external onlyMediator {
        require(isRegisteredAsNativeToken(_token));

        _setNativeTokenIsRegistered(_token, REGISTERED_AND_DEPLOYED);

        _handleTokens(_token, true, _recipient, _tokenIds, _values);
    }

    /**
     * @dev Allows to pre-set the bridged token contract for not-yet bridged token.
     * Only the owner can call this method.
     * @param _nativeToken address of the token contract on the other side that was not yet bridged.
     * @param _bridgedToken address of the bridged token contract.
     */
    function setCustomTokenAddressPair(address _nativeToken, address _bridgedToken) external onlyOwner {
        require(Address.isContract(_bridgedToken));
        require(!isTokenRegistered(_bridgedToken));
        require(bridgedTokenAddress(_nativeToken) == address(0));
        // Unfortunately, there is no simple way to verify that the _nativeToken address
        // does not belong to the bridged token on the other side,
        // since information about bridged tokens addresses is not transferred back.
        // Therefore, owner account calling this function SHOULD manually verify on the other side of the bridge that
        // nativeTokenAddress(_nativeToken) == address(0) && isTokenRegistered(_nativeToken) == false.

        if (isHomeBridge()) {
            _setNativeTokenIsRegistered(_nativeToken, REGISTERED_AND_DEPLOYED);
        }

        _setTokenAddressPair(_nativeToken, _bridgedToken);
    }

    /**
     * @dev Allows to send to the other network some ERC721 token that can be forced into the contract
     * without the invocation of the required methods. (e. g. regular transferFrom without a call to onERC721Received)
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses.
     * @param _token address of the token contract.
     * @param _receiver the address that will receive the token on the other network.
     * @param _tokenIds unique ids of the bridged tokens.
     */
    function fixMediatorBalanceERC721(
        address _token,
        address _receiver,
        uint256[] calldata _tokenIds
    ) external onlyIfUpgradeabilityOwner {
        require(isTokenRegistered(_token));
        require(_tokenIds.length > 0);

        uint256[] memory _values = new uint256[](0);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values);

        bytes32 _messageId = _passMessage(data, true);

        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, _values);
    }

    /**
     * @dev Allows to send to the other network some ERC1155 token that can be forced into the contract
     * without the invocation of the required methods.
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses.
     * @param _token address of the token contract.
     * @param _receiver the address that will receive the token on the other network.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values corresponding amounts of the bridged tokens.
     */
    function fixMediatorBalanceERC1155(
        address _token,
        address _receiver,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external onlyIfUpgradeabilityOwner {
        require(isTokenRegistered(_token));
        require(_tokenIds.length == _values.length);
        require(_tokenIds.length > 0);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values);
        bytes32 _messageId = _passMessage(data, true);

        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, _values);
    }

    /**
     * @dev Executes action on deposit of ERC721 token.
     * @param _token address of the ERC721 token contract.
     * @param _from address of token sender.
     * @param _receiver address of token receiver on the other side.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal override {
        if (!isTokenRegistered(_token)) {
            _setNativeTokenIsRegistered(_token, REGISTERED);
        }

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values);

        bytes32 _messageId = _passMessage(data, _isOracleDrivenLaneAllowed(_token, _from, _receiver));

        _recordBridgeOperation(_messageId, _token, _from, _tokenIds, _values);
    }

    /**
     * @dev Constructs the message to be sent to the other side. Burns/locks bridged token.
     * @param _token bridged token address.
     * @param _receiver address of the tokens receiver on the other side.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _prepareMessage(
        address _token,
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal returns (bytes memory) {
        require(_receiver != address(0) && _receiver != mediatorContractOnOtherSide());

        address nativeToken = nativeTokenAddress(_token);

        // process token is native with respect to this side of the bridge
        if (nativeToken == address(0)) {
            string[] memory tokenURIs = new string[](_tokenIds.length);
            if (_values.length > 0) {
                require(_tokenIds.length == _values.length);
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    uint256 oldBalance = mediatorOwns(_token, _tokenIds[i]);
                    uint256 newBalance = oldBalance.add(_values[i]);
                    require(IBurnableMintableERC1155Token(_token).balanceOf(address(this), _tokenIds[i]) >= newBalance);
                    _setMediatorOwns(_token, _tokenIds[i], newBalance);
                    tokenURIs[i] = _readERC1155TokenURI(_token, _tokenIds[i]);
                }
            } else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    require(mediatorOwns(_token, _tokenIds[i]) == 0);
                    require(IBurnableMintableERC721Token(_token).ownerOf(_tokenIds[i]) == address(this));
                    _setMediatorOwns(_token, _tokenIds[i], 1);
                    tokenURIs[i] = _readERC721TokenURI(_token, _tokenIds[i]);
                }
            }

            // process token which bridged alternative was already ACKed to be deployed
            require(isBridgedTokenDeployAcknowledged(_token));
            require(_tokenIds.length <= MAX_BATCH_BRIDGE_LIMIT);
            return (
            abi.encodeWithSelector(
                this.handleBridgedNFT.selector,
                _token,
                _receiver,
                _receiver,
                _tokenIds,
                _values,
                tokenURIs
            ));
        }

        // process already known token that is bridged from other chain
        if (_values.length > 0) {
            IBurnableMintableERC1155Token(_token).burn(_tokenIds, _values);
        } else {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IBurnableMintableERC721Token(_token).burn(_tokenIds[i]);
            }
        }

        return (abi.encodeWithSelector(this.handleNativeNFT.selector, nativeToken, _receiver, _tokenIds, _values));
    }

    /**
     * @dev Unlock/Mint back the bridged token that was bridged to the other network but failed.
     * @param _token address that bridged token contract.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal override {
        _releaseTokens(_token, nativeTokenAddress(_token) == address(0), _recipient, _tokenIds, _values);
    }

    /**
     * @dev Handles the bridged token that came from the other side of the bridge.
     * Checks that the operation is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _token token contract address on this side of the bridge.
     * @param _isNative true, if given token is native to this chain and Unlock should be used.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _handleTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) internal {
        require(isTokenExecutionAllowed(_token));

        _releaseTokens(_token, _isNative, _recipient, _tokenIds, _values);

        emit TokensBridged(_token, _recipient, _tokenIds, _values, messageId());
    }

    /**
     * Internal function for setting token URI for the bridged token instance.
     * @param _token address of the token contract.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _tokenURIs URIs for the bridged token instances.
     */
    function _setTokensURI(
        address _token,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (bytes(_tokenURIs[i]).length > 0) {
                IBurnableMintableERC721Token(_token).setTokenURI(_tokenIds[i], _tokenURIs[i]);
            }
        }
    }

    /**
     * Internal function for unlocking/minting some specific ERC721 token.
     * @param _token address of the token contract.
     * @param _isNative true, if the token contract is native w.r.t to the bridge.
     * @param _recipient address of the tokens receiver.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _releaseTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal {
        if (_values.length > 0) {
            require(_tokenIds.length == _values.length);
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (mediatorOwns(_token, _tokenIds[i]) >= _values[i]) {
                        _setMediatorOwns(_token, _tokenIds[i], mediatorOwns(_token, _tokenIds[i]).sub(_values[i]));
                        IBurnableMintableERC1155Token(_token).safeTransferFrom(address(this), _recipient, _tokenIds[i], _values[i], new bytes(0));
                    } else {
                        uint256[] memory _tempTokenIds = new uint256[](1);
                        uint256[] memory _tempValues = new uint256[](1);
                        _tempTokenIds[0] = _tokenIds[i];
                        _tempValues[0] = _values[i];
                        IBurnableMintableERC1155Token(_token).mint(_recipient, _tempTokenIds, _tempValues);
                    }
                }
            } else {
                IBurnableMintableERC1155Token(_token).mint(_recipient, _tokenIds, _values);
            }
        } else {
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (mediatorOwns(_token, _tokenIds[i]) == 1) {
                        _setMediatorOwns(_token, _tokenIds[i], 0);
                        IBurnableMintableERC721Token(_token).transferFrom(address(this), _recipient, _tokenIds[i]);
                    } else {
                        IBurnableMintableERC721Token(_token).mint(_recipient, _tokenIds[i]);
                    }
                }
            }
            else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    IBurnableMintableERC721Token(_token).mint(_recipient, _tokenIds[i]);
                }
            }
        }
    }

    /**
     * @dev Internal function for recording bridge operation for further usage.
     * Recorded information is used for fixing failed requests on the other side.
     * @param _messageId id of the sent message.
     * @param _token bridged token address.
     * @param _sender address of the tokens sender.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function _recordBridgeOperation(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal {
        require(isTokenBridgingAllowed(_token));

        setMessageChecksum(_messageId, _messageChecksum(_token, _sender, _tokenIds, _values));

        emit TokensBridgingInitiated(_token, _sender, _tokenIds, _values, _messageId);
    }

    /**
     * @dev Checks if bridge operation is allowed to use oracle driven lane.
     * @param _token address of the token contract on the foreign side of the bridge.
     * @param _sender address of the tokens sender on the home side of the bridge.
     * @param _receiver address of the tokens receiver on the foreign side of the bridge.
     * @return true, if message can be forwarded to the oracle-driven lane.
     */
    function _isOracleDrivenLaneAllowed(
        address _token,
        address _sender,
        address _receiver
    ) internal view virtual returns (bool) {
        (_token, _sender, _receiver);
        return true;
    }
}

pragma solidity 0.7.5;

interface VersionableBridge {
    function getBridgeInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );

    function getBridgeMode() external pure returns (bytes4);
}

pragma solidity 0.7.5;

import "../interfaces/IUpgradeabilityOwnerStorage.sol";

contract Upgradeable {
    // Avoid using onlyUpgradeabilityOwner name to prevent issues with implementation from proxy contract
    modifier onlyIfUpgradeabilityOwner() {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
        _;
    }
}

pragma solidity 0.7.5;

contract ReentrancyGuard {
    function lock() internal view returns (bool res) {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            res := sload(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92) // keccak256(abi.encodePacked("lock"))
        }
    }

    function setLock(bool _lock) internal {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92, _lock) // keccak256(abi.encodePacked("lock"))
        }
    }
}

pragma solidity 0.7.5;

import "../upgradeability/EternalStorage.sol";
import "../interfaces/IUpgradeabilityOwnerStorage.sol";

/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
     * @dev Throws if called through proxy by any account other than contract itself or an upgradeability owner.
     */
    modifier onlyRelevantSender() {
        (bool isProxy, bytes memory returnData) =
            address(this).staticcall(abi.encodeWithSelector(UPGRADEABILITY_OWNER));
        require(
            !isProxy || // covers usage without calling through storage proxy
                (returnData.length == 32 && msg.sender == abi.decode(returnData, (address))) || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner the address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

pragma solidity 0.7.5;

import "./Ownable.sol";
import "../interfaces/IAMB.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BasicAMBMediator
 * @dev Basic storage and methods needed by mediators to interact with AMB bridge.
 */
abstract contract BasicAMBMediator is Ownable {
    bytes32 internal constant BRIDGE_CONTRACT = 0x811bbb11e8899da471f0e69a3ed55090fc90215227fc5fb1cb0d6e962ea7b74f; // keccak256(abi.encodePacked("bridgeContract"))
    bytes32 internal constant MEDIATOR_CONTRACT = 0x98aa806e31e94a687a31c65769cb99670064dd7f5a87526da075c5fb4eab9880; // keccak256(abi.encodePacked("mediatorContract"))

    /**
     * @dev Throws if caller on the other side is not an associated mediator.
     */
    modifier onlyMediator {
        _onlyMediator();
        _;
    }

    /**
     * @dev Internal function for reducing onlyMediator modifier bytecode overhead.
     */
    function _onlyMediator() internal view {
        IAMB bridge = bridgeContract();
        require(msg.sender == address(bridge));
        require(bridge.messageSender() == mediatorContractOnOtherSide());
    }

    /**
     * @dev Sets the AMB bridge contract address. Only the owner can call this method.
     * @param _bridgeContract the address of the bridge contract.
     */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        _setBridgeContract(_bridgeContract);
    }

    /**
     * @dev Sets the mediator contract address from the other network. Only the owner can call this method.
     * @param _mediatorContract the address of the mediator contract.
     */
    function setMediatorContractOnOtherSide(address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_mediatorContract);
    }

    /**
     * @dev Get the AMB interface for the bridge contract address
     * @return AMB interface for the bridge contract address
     */
    function bridgeContract() public view returns (IAMB) {
        return IAMB(addressStorage[BRIDGE_CONTRACT]);
    }

    /**
     * @dev Tells the mediator contract address from the other network.
     * @return the address of the mediator contract.
     */
    function mediatorContractOnOtherSide() public view virtual returns (address) {
        return addressStorage[MEDIATOR_CONTRACT];
    }

    /**
     * @dev Stores a valid AMB bridge contract address.
     * @param _bridgeContract the address of the bridge contract.
     */
    function _setBridgeContract(address _bridgeContract) internal {
        require(Address.isContract(_bridgeContract));
        addressStorage[BRIDGE_CONTRACT] = _bridgeContract;
    }

    /**
     * @dev Stores the mediator contract address from the other network.
     * @param _mediatorContract the address of the mediator contract.
     */
    function _setMediatorContractOnOtherSide(address _mediatorContract) internal {
        addressStorage[MEDIATOR_CONTRACT] = _mediatorContract;
    }

    /**
     * @dev Tells the id of the message originated on the other network.
     * @return the id of the message originated on the other network.
     */
    function messageId() internal view returns (bytes32) {
        return bridgeContract().messageId();
    }

    /**
     * @dev Tells the maximum gas limit that a message can use on its execution by the AMB bridge on the other network.
     * @return the maximum gas limit value.
     */
    function maxGasPerTx() internal view returns (uint256) {
        return bridgeContract().maxGasPerTx();
    }

    function _passMessage(bytes memory _data, bool _useOracleLane) internal virtual returns (bytes32);
}

pragma solidity 0.7.5;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

pragma solidity 0.7.5;

/**
 * @title Bytes
 * @dev Helper methods to transform bytes to other solidity types.
 */
library Bytes {
    /**
     * @dev Truncate bytes array if its size is more than 20 bytes.
     * NOTE: This function does not perform any checks on the received parameter.
     * Make sure that the _bytes argument has a correct length, not less than 20 bytes.
     * A case when _bytes has length less than 20 will lead to the undefined behaviour,
     * since assembly will read data from memory that is not related to the _bytes argument.
     * @param _bytes to be converted to address type
     * @return addr address included in the firsts 20 bytes of the bytes array in parameter.
     */
    function bytesToAddress(bytes memory _bytes) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}

pragma solidity 0.7.5;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);
}

pragma solidity 0.7.5;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBurnableMintableERC721Token is IERC721 {
    function mint(address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBurnableMintableERC1155Token is IERC1155 {
    function mint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external;

    function burn(uint256[] calldata _tokenId, uint256[] calldata _values) external;
}

pragma solidity 0.7.5;

interface IAMB {
    event UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData);
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event CollectedSignatures(
        address authorityResponsibleForRelay,
        bytes32 messageHash,
        uint256 numberOfCollectedSignatures
    );
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );
    event RelayedMessage(address indexed sender, address indexed executor, bytes32 indexed messageId, bool status);

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId) external view returns (address);

    function failedMessageSender(bytes32 _messageId) external view returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}