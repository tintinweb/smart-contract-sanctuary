pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "./modules/gas_limit/SelectorTokenGasLimitConnector.sol";

/**
 * @title HomeNFTOmnibridge
 * @dev Home side implementation for multi-token ERC721 mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract HomeNFTOmnibridge is BasicNFTOmnibridge, SelectorTokenGasLimitConnector {
    constructor(address _NFTbIDStorage) BasicNFTOmnibridge(_NFTbIDStorage) {}

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
import "../../BasicNFTOmnibridge.sol";
import "../OmnibridgeModule.sol";

/**
 * @title SelectorTokenGasLimitManager
 * @dev Multi NFT mediator functionality for managing request gas limits.
 */
contract SelectorTokenGasLimitManager is OmnibridgeModule {
    IAMB public bridge;

    uint256 internal defaultGasLimit;
    mapping(bytes4 => uint256) internal selectorGasLimit;
    mapping(bytes4 => mapping(address => uint256)) internal selectorTokenGasLimit;

    /**
     * @dev Initializes this module contract. Intended to be called only once through the proxy pattern.
     * @param _bridge address of the AMB bridge contract to which Omnibridge mediator is connected.
     * @param _mediator address of the Omnibridge contract working with this module.
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
     * @dev Sets the default values for different NFT Omnibridge selectors.
     * @param _gasLimits array with 4 gas limits for the following selectors of the outgoing messages:
     * - deployAndHandleBridgedNFT
     * - handleBridgedNFT
     * - handleNativeNFT
     * - fixFailedMessage
     * Only the owner can call this method.
     */
    function setCommonRequestGasLimits(uint256[] calldata _gasLimits) external onlyOwner validGasLimits(4, _gasLimits) {
        require(_gasLimits[0] >= _gasLimits[1]);
        selectorGasLimit[BasicNFTOmnibridge.deployAndHandleBridgedNFT.selector] = _gasLimits[0];
        selectorGasLimit[BasicNFTOmnibridge.handleBridgedNFT.selector] = _gasLimits[1];
        selectorGasLimit[BasicNFTOmnibridge.handleNativeNFT.selector] = _gasLimits[2];
        selectorGasLimit[FailedMessagesProcessor.fixFailedMessage.selector] = _gasLimits[3];
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
        selectorTokenGasLimit[BasicNFTOmnibridge.handleNativeNFT.selector][_token] = _gasLimits[0];
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
        validGasLimits(2, _gasLimits)
    {
        require(_gasLimits[0] >= _gasLimits[1]);
        selectorTokenGasLimit[BasicNFTOmnibridge.deployAndHandleBridgedNFT.selector][_token] = _gasLimits[0];
        selectorTokenGasLimit[BasicNFTOmnibridge.handleBridgedNFT.selector][_token] = _gasLimits[1];
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
abstract contract OmnibridgeModule is VersionableModule {
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

import "../../../VersionableBridge.sol";

/**
 * @title NFTOmnibridgeInfo
 * @dev Functionality for versioning NFTOmnibridge mediator.
 */
contract NFTOmnibridgeInfo is VersionableBridge {
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
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import {NFT} from "../../../../tokens/ERC721BridgeToken.sol";
import {NFTm} from "../../../../tokens/ERC1155BridgeToken.sol";
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


        string[] memory _tokenUris = new string[](_tokenIds.length);
        address[][] memory _royaltyReceivers = new address[][](_tokenIds.length);
        uint256[][] memory _royaltyAmounts = new uint256[][](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) =
                (_values.length > 0) ?
                NFTm(_token).royaltyInfo(_tokenIds[i]) :
                NFT(_token).royaltyInfo(_tokenIds[i]);

            _tokenUris[i]  =
                (_values.length > 0) ?
                NFTm(_token).tokenURI(_tokenIds[i]) :
                NFT(_token).tokenURI(_tokenIds[i]);

            _royaltyReceivers[i] = royaltyReceivers;
            _royaltyAmounts[i] = royaltyAmounts;
        }

        bytes memory _data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);

        _passMessage(abi.encodeWithSelector(this.fixFailedMessage.selector, _messageId, _token, _sender, _tokenIds, _values, _data),
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
        uint256[] memory _values,
        bytes memory _data
    ) public onlyMediator {
        require(!messageFixed(_messageId));
        require(getMessageChecksum(_messageId) == _messageChecksum(_token, _sender, _tokenIds, _values, _data));

        setMessageFixed(_messageId);
        executeActionOnFixedTokens(_token, _sender, _tokenIds, _values, _data);
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
        uint256[] memory _values,
        bytes memory _data
    ) internal virtual;
}

pragma solidity 0.7.5;

// solhint-disable-next-line compiler-version
pragma abicoder v2;

import {NFT} from "../../../../tokens/ERC721BridgeToken.sol";
import "../../../ReentrancyGuard.sol";
import "./BaseRelayer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

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
            (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) = NFT(msg.sender).royaltyInfo(_tokenId);
            string[] memory _tokenUris = new string[](1);
            address[][] memory _royaltyReceivers = new address[][](1);
            uint256[][] memory _royaltyAmounts = new uint256[][](1);

            _tokenUris[0] = NFT(msg.sender).tokenURI(_tokenId);
            _royaltyReceivers[0] = royaltyReceivers;
            _royaltyAmounts[0] = royaltyAmounts;

            bytes memory data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);
            bridgeSpecificActionsOnTokenTransfer(
                msg.sender,
                _from,
                _chooseReceiver(_from, _data),
                _singletonArray(_tokenId),
                new uint256[](0),
                data
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
        NFT token,
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
    function relayToken(NFT token, uint256 _tokenId) external {
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
        NFT _token,
        address _receiver,
        uint256 _tokenId
    ) internal {
        // This lock is to prevent calling bridgeSpecificActionsOnTokenTransfer twice.
        // When transferFrom is called, after the transfer, the ERC721 token might call onERC721Received from this contract
        // which will call bridgeSpecificActionsOnTokenTransfer.
        require(!lock(), "locked already");

        (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) = _token.royaltyInfo(_tokenId);
        string[] memory _tokenUris = new string[](1);
        address[][] memory _royaltyReceivers = new address[][](1);
        uint256[][] memory _royaltyAmounts = new uint256[][](1);

        _tokenUris[0] = _token.tokenURI(_tokenId);
        _royaltyReceivers[0] = royaltyReceivers;
        _royaltyAmounts[0] = royaltyAmounts;

        bytes memory data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);

        setLock(true);
        _token.safeTransferFrom(msg.sender, address(this), _tokenId, data);
        setLock(false);
        bridgeSpecificActionsOnTokenTransfer(
            address(_token),
            msg.sender,
            _receiver,
            _singletonArray(_tokenId),
            new uint256[](0),
            data
        );
    }
}

pragma solidity 0.7.5;

// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "./BaseRelayer.sol";
import {NFTm} from "../../../../tokens/ERC1155BridgeToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155ReceiverUpgradeable.sol";

/**
 * @title ERC1155Relayer
 * @dev Functionality for bridging multiple ERC1155 tokens to the other side of the bridge.
 */
abstract contract ERC1155Relayer is  ERC1155ReceiverUpgradeable, BaseRelayer {
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
        (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) = NFTm(msg.sender).royaltyInfo(_tokenId);
        string[] memory _tokenUris = new string[](1);
        address[][] memory _royaltyReceivers = new address[][](1);
        uint256[][] memory _royaltyAmounts = new uint256[][](1);

        _tokenUris[0] = NFTm(msg.sender).tokenURI(_tokenId);
        _royaltyReceivers[0] = royaltyReceivers;
        _royaltyAmounts[0] = royaltyAmounts;

        bytes memory data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);

        bridgeSpecificActionsOnTokenTransfer(
            msg.sender,
            _from,
            _chooseReceiver(_from, _data),
            _singletonArray(_tokenId),
            _singletonArray(_value),
            data
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
        string[] memory _tokenUris = new string[](_tokenIds.length);
        address[][] memory _royaltyReceivers = new address[][](_tokenIds.length);
        uint256[][] memory _royaltyAmounts = new uint256[][](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++){
            (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) = NFTm(msg.sender).royaltyInfo(_tokenIds[i]);
            _tokenUris[i] = NFTm(msg.sender).tokenURI(_tokenIds[i]);
            _royaltyReceivers[i] = royaltyReceivers;
            _royaltyAmounts[i] = royaltyAmounts;
        }

        bytes memory data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);

        bridgeSpecificActionsOnTokenTransfer(
            msg.sender,
            _from,
            _chooseReceiver(_from, _data),
            _tokenIds,
            _values,
            data);
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
        uint256[] memory _values,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_token, _sender, _tokenIds, _values, _data));
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
        uint256[] memory _values,
        bytes memory _data
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
import "../../interfaces/IBurnableMintableERC1155Token.sol";
import "./components/common/BridgeOperationsStorage.sol";
import "./components/common/FailedMessagesProcessor.sol";
import "./components/common/NFTBridgeLimits.sol";
import "./components/common/ERC721Relayer.sol";
import "./components/common/ERC1155Relayer.sol";
import "./components/common/NFTOmnibridgeInfo.sol";
import "./components/native/NativeTokensRegistry.sol";
import "./components/native/MetadataReader.sol";
import "./components/bridged/BridgedTokensRegistry.sol";
import "./components/bridged/TokenImageStorage.sol";
import "./components/native/NFTMediatorBalanceStorage.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../../tokens/NFTbIDStorage.sol";

/**
 * @title BasicNFTOmnibridge
 * @dev Commong functionality for multi-token mediator for ERC721 tokens intended to work on top of AMB bridge.
 */
abstract contract BasicNFTOmnibridge is
Initializable,
Upgradeable,
BridgeOperationsStorage,
BridgedTokensRegistry,
NativeTokensRegistry,
NFTOmnibridgeInfo,
NFTBridgeLimits,
MetadataReader,
TokenImageStorage,
ERC721Relayer,
ERC1155Relayer,
NFTMediatorBalanceStorage,
FailedMessagesProcessor
{
    using SafeMath for uint256;

    address public immutable NFTB_ID_STORAGE;

    // Since contract is intended to be deployed under EternalStorageProxy, only constant and immutable variables can be set here
    constructor(address _NFTbIDStorage) {
        if (isHomeBridge()) {
            require(_NFTbIDStorage != address(0));
        }

        NFTB_ID_STORAGE = _NFTbIDStorage;
    }

    function isHomeBridge() public virtual view returns (bool);

    /**
     * @dev Checks if specified token was already bridged at least once and it is registered in the Omnibridge.
     * @param _token address of the token contract.
     * @return true, if token was already bridged.
     */
    function isTokenRegistered(address _token) public view override returns (bool) {
        return isRegisteredAsNativeToken(_token) || nativeTokenAddress(_token) != address(0);
    }

    /**
     * @dev Handles the bridged token for the first time, includes deployment of new ERC721TokenProxy contract.
     * @param _token address of the native ERC721 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     */
    function deployAndHandleBridgedNFT(
        address _token,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlyMediator {
        address bridgedToken = bridgedTokenAddress(_token);
        if (bridgedToken == address(0)) {
            bridgedToken = _values.length > 0
            ? tokenImageERC1155()
            : tokenImageERC721();
            _setTokenAddressPair(_token, bridgedToken);
        }

        _handleTokens(bridgedToken, false, _recipient, _tokenIds, _values, _data);
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
        bytes calldata _data
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);

        _handleTokens(token, false, _recipient, _tokenIds, _values, _data);
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
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlyMediator {
        require(isRegisteredAsNativeToken(_token));

        _setNativeTokenIsRegistered(_token, REGISTERED_AND_DEPLOYED);

        _handleTokens(_token, true, _recipient, _tokenIds, _values, _data);
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

        string[] memory _tokenUris = new string[](_tokenIds.length);
        address[][] memory _royaltyReceivers = new address[][](_tokenIds.length);
        uint256[][] memory _royaltyAmounts = new uint256[][](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) = NFT(_token).royaltyInfo(_tokenIds[i]);

            _tokenUris[i] = NFT(_token).tokenURI(_tokenIds[i]);
            _royaltyReceivers[i] = royaltyReceivers;
            _royaltyAmounts[i] = royaltyAmounts;
        }

        bytes memory _data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values, _data);

        bytes32 _messageId = _passMessage(data, true);

        if (isHomeBridge()) {
            uint256[] memory realTokenIDs = new uint256[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                realTokenIDs[i] = NFTbIDStorage(NFTB_ID_STORAGE).getRealIDERC721(_tokenIds[i]);
            }

            _recordBridgeOperation(_messageId, _token, _receiver, realTokenIDs, _values, _data);
            return;
        }

        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, _values, _data);
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

        string[] memory _tokenUris = new string[](_tokenIds.length);
        address[][] memory _royaltyReceivers = new address[][](_tokenIds.length);
        uint256[][] memory _royaltyAmounts = new uint256[][](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (address[] memory royaltyReceivers, uint256[] memory royaltyAmounts) = NFTm(_token).royaltyInfo(_tokenIds[i]);

            _tokenUris[i] = NFTm(_token).tokenURI(_tokenIds[i]);
            _royaltyReceivers[i] = royaltyReceivers;
            _royaltyAmounts[i] = royaltyAmounts;
        }

        bytes memory _data = abi.encode(_tokenUris, _royaltyReceivers, _royaltyAmounts);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, _values, _data);
        bytes32 _messageId = _passMessage(data, true);

        if (isHomeBridge()) {
            uint256[] memory realTokenIDs = new uint256[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                realTokenIDs[i] = NFTbIDStorage(NFTB_ID_STORAGE).getRealIDERC1155(_tokenIds[i]);
            }

            _recordBridgeOperation(_messageId, _token, _receiver, realTokenIDs, _values, _data);
            return;
        }

        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, _values, _data);
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
        uint256[] memory _values,
        bytes memory _data
    ) internal override {
        if (!isTokenRegistered(_token)) {
            _setNativeTokenIsRegistered(_token, REGISTERED);
        }

        bytes memory data;

        data = _prepareMessage(_token, _receiver, _tokenIds, _values, _data);

        bytes32 _messageId = _passMessage(data, _isOracleDrivenLaneAllowed(_token, _from, _receiver));

        if (isHomeBridge()) {
            uint256[] memory realTokenIDs = new uint256[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (_values.length > 0) {
                    realTokenIDs[i] = NFTbIDStorage(NFTB_ID_STORAGE).getRealIDERC1155(_tokenIds[i]);
                } else {
                    realTokenIDs[i] = NFTbIDStorage(NFTB_ID_STORAGE).getRealIDERC721(_tokenIds[i]);
                }
            }

            _recordBridgeOperation(_messageId, _token, _from, realTokenIDs, _values, _data);
            return;
        }

        _recordBridgeOperation(_messageId, _token, _from, _tokenIds, _values, _data);
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
        uint256[] memory _values,
        bytes memory _data
    ) internal returns (bytes memory) {
        require(_receiver != address(0) && _receiver != mediatorContractOnOtherSide());

        address nativeToken = nativeTokenAddress(_token);

        // process token is native with respect to this side of the bridge
        if (nativeToken == address(0)) {
            if (_values.length > 0) {
                require(_tokenIds.length == _values.length);
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    uint256 oldBalance = mediatorOwns(_token, _tokenIds[i]);
                    uint256 newBalance = oldBalance.add(_values[i]);
                    require(IERC1155Upgradeable(_token).balanceOf(address(this), _tokenIds[i]) >= newBalance);

                    _setMediatorOwns(_token, _tokenIds[i], newBalance);
                }
            } else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    require(mediatorOwns(_token, _tokenIds[i]) == 0);
                    require(IERC721(_token).ownerOf(_tokenIds[i]) == address(this));

                    _setMediatorOwns(_token, _tokenIds[i], 1);
                }
            }

            uint256[] memory realTokenIDs = new uint256[](_tokenIds.length);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (_values.length > 0) {
                    realTokenIDs[i] = NFTbIDStorage(NFTB_ID_STORAGE).getRealIDERC1155(_tokenIds[i]);
                } else {
                    realTokenIDs[i] = NFTbIDStorage(NFTB_ID_STORAGE).getRealIDERC721(_tokenIds[i]);
                }
            }

            // process token which bridged alternative was already ACKed to be deployed
            if (isBridgedTokenDeployAcknowledged(_token)) {
                require(_tokenIds.length <= MAX_BATCH_BRIDGE_LIMIT);
                return (
                abi.encodeWithSelector(
                    this.handleBridgedNFT.selector,
                    _token,
                    _receiver,
                    realTokenIDs,
                    _values,
                    _data
                ));
            }

            require(_tokenIds.length <= MAX_BATCH_BRIDGE_AND_DEPLOY_LIMIT);

            return (
            abi.encodeWithSelector(
                this.deployAndHandleBridgedNFT.selector,
                _token,
                _receiver,
                realTokenIDs,
                _values,
                _data
            ));
        }

        // process already known token that is bridged from other chain
        if (_values.length > 0) {
            IBurnableMintableERC1155Token(_token).burnBatch(_tokenIds, _values);
        } else {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                NFT(_token).burn(_tokenIds[i]);
            }
        }

        return (abi.encodeWithSelector(this.handleNativeNFT.selector, nativeToken, _receiver, _tokenIds, _values, _data));
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
        uint256[] memory _values,
        bytes memory _data
    ) internal override {
        _releaseTokens(_token, nativeTokenAddress(_token) == address(0), _recipient, _tokenIds, _values, _data);
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
        uint256[] calldata _values,
        bytes calldata _data
    ) internal {
        require(isTokenExecutionAllowed(_token));

        _releaseTokens(_token, _isNative, _recipient, _tokenIds, _values, _data);

        emit TokensBridged(_token, _recipient, _tokenIds, _values, messageId());
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
        uint256[] memory _values,
        bytes memory data
    ) internal {
        if (_values.length > 0) {
            require(_tokenIds.length == _values.length);
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (mediatorOwns(_token, _tokenIds[i]) >= _values[i]) {
                        _setMediatorOwns(_token, _tokenIds[i], mediatorOwns(_token, _tokenIds[i]).sub(_values[i]));
                        IERC1155Upgradeable(_token).safeBatchTransferFrom(address(this), _recipient, _tokenIds, _values, new bytes(0));
                    } else {
                        (string[] memory _tokenURIs, address[][] memory _royaltyReceivers, uint256[][] memory _royaltyAmounts) =
                        abi.decode(data, (string[], address[][], uint256[][]));

                        (uint256 newTokenId, uint256 _newTokenAmount) = NFTm(_token).mint(_recipient, _values[i], _tokenURIs[i], _royaltyReceivers[i], _royaltyAmounts[i]);
                        NFTbIDStorage(NFTB_ID_STORAGE).recordIDERC1155(
                            newTokenId,
                            _tokenIds[i]);
                    }
                }
            } else {
                (string[] memory _tokenURIs, address[][] memory _royaltyReceivers, uint256[][] memory _royaltyAmounts) =
                abi.decode(data, (string[], address[][], uint256[][]));
                IBurnableMintableERC1155Token(_token).mintBatchWithID(_recipient, _values, _tokenURIs, _royaltyReceivers, _royaltyAmounts, _tokenIds);
            }
        } else {
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    if (mediatorOwns(_token, _tokenIds[i]) == 1) {
                        _setMediatorOwns(_token, _tokenIds[i], 0);
                        IERC721(_token).transferFrom(address(this), _recipient, _tokenIds[i]);

                    } else {
                        (string[] memory _tokenURIs, address[][] memory _royaltyReceivers, uint256[][] memory _royaltyAmounts) =
                        abi.decode(data, (string[], address[][], uint256[][]));

                        NFTbIDStorage(NFTB_ID_STORAGE).recordIDERC721(
                            NFT(_token).mint(_recipient, _royaltyReceivers[0], _royaltyAmounts[0], _tokenURIs[0]),
                            _tokenIds[i]);
                    }
                }
            } else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    (string[] memory _tokenURIs, address[][] memory _royaltyReceivers, uint256[][] memory _royaltyAmounts) =
                    abi.decode(data, (string[], address[][], uint256[][]));

                    NFT(_token).mintWithID(_recipient, _royaltyReceivers[0], _royaltyAmounts[0], _tokenURIs[0], _tokenIds[i]);
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
        uint256[] memory _values,
        bytes memory _data
    ) internal {
        require(isTokenBridgingAllowed(_token));

        setMessageChecksum(_messageId, _messageChecksum(_token, _sender, _tokenIds, _values, _data));

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IOwnable.sol";

contract NFTbIDStorage {
    address public bridgeContract;
    mapping(uint256 => uint256) bscToRealIDERC721;
    mapping(uint256 => uint256) bscToRealIDERC1155;

    modifier onlyBridge() {
        require(msg.sender == bridgeContract, "can be called only by bridge contract");
        _;
    }

    modifier onlyBridgeOwner() {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner(),  "can be called only by bridge contract or bridge contract owner");
        _;
    }

    constructor(address _bridgeContract) {
        bridgeContract = _bridgeContract;
    }

    function recordIDERC721(uint256 bscID, uint256 realID)
    external
    onlyBridge
    {
        if (bscToRealIDERC721[bscID] == 0){
            bscToRealIDERC721[bscID] = realID;
        }
    }

    function recordIDERC1155(uint256 bscID, uint256 realID)
    external
    onlyBridge
    {
        if (bscToRealIDERC1155[bscID] == 0){
            bscToRealIDERC1155[bscID] = realID;
        }
    }

    function getRealIDERC721(uint256 bscID)
    external
    view
    returns (uint256)
    {
        if (bscToRealIDERC721[bscID] == 0){
            return bscID;
        }

        return bscToRealIDERC721[bscID];
    }

    function getRealIDERC1155(uint256 bscID)
    external
    view
    returns (uint256)
    {
        if (bscToRealIDERC1155[bscID] == 0){
            return bscID;
        }

        return bscToRealIDERC1155[bscID];
    }

    function setBridgeContract(address _bridgeContract)
    external
    onlyBridgeOwner {
        require(_bridgeContract != address(0));
        bridgeContract = _bridgeContract;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IOwnable.sol";

contract NFTBERC2981Enhanced is AccessControlUpgradeable {
    uint256 public constant ROYALTY_PERCENTAGE = 100000;
    uint256 public constant ROYALTY_MAX_COUNT = 10;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    struct RoyaltyInfo {
        address receiver;
        uint256 amount;
    }

    address public bridgeContract;

    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }

    modifier onlyBridgeOwner() {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner(), "restricted to bridge owner");
        _;
    }

    modifier onlyBridge() {
        require(msg.sender == bridgeContract, "restricted to bridge");
        _;
    }

    function initializeNFTBERC2981Enhanced() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function onRoyaltiesReceived(
        address _royaltyRecipient,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    ) external returns (bytes4) {
        emit RoyaltiesReceived(
            _royaltyRecipient,
            _buyer,
            _tokenId,
            _tokenPaid,
            _amount,
            _metadata
        );

        return this.onRoyaltiesReceived.selector;
    }

    function isBurner(address account) public view returns (bool) {
        return hasRole(BURNER_ROLE, account);
    }

    function addBurner(address account) public onlyAdmin {
        grantRole(BURNER_ROLE, account);
    }

    function removeBurner(address account) public onlyAdmin {
        revokeRole(BURNER_ROLE, account);
    }

    function renounceBurner() public {
        renounceRole(BURNER_ROLE, _msgSender());
    }

    function setBridgeContract(address _bridgeContract) external onlyBridgeOwner {
        require(_bridgeContract != address(0), "can't set contract to zero address");
        bridgeContract = _bridgeContract;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IOwnable.sol";

contract NFT is ERC721Burnable, AccessControl {
    uint256 public constant ROYALTY_PERCENTAGE = 100000;
    uint256 public constant ROYALTY_MAX_COUNT = 10;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct RoyaltyInfo {
        address receiver;
        uint256 amount;
    }

    Counters.Counter private tokenIds;

    mapping(uint256 => RoyaltyInfo[]) private royalties;

    address public bridgeContract;
    uint256 public mintLowerBound;
    uint256 public mintHigherBound;

    event Mint(
        address indexed _recipient,
        address[] _royaltyReceivers,
        uint256[] _royaltyAmounts,
        string _metadata
    );

    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }

    modifier onlyBridgeOwner() {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner(), "restricted to bridge owner");
        _;
    }

    modifier onlyBridge() {
        require(msg.sender == bridgeContract, "restricted to bridge");
        _;
    }


    constructor(address _bridgeContract, uint256 _mintMillionNumber) ERC721("NFTb_NFT", "NFTb_NFT") ERC165() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        bridgeContract = _bridgeContract;
        mintLowerBound = _mintMillionNumber.mul(1000000);
        tokenIds._value = mintLowerBound;
        mintHigherBound = tokenIds.current().add(999999);
    }

    function royaltyInfo(uint256 tokenId)
    external
    view
    returns (address[] memory, uint256[] memory)
    {
        RoyaltyInfo[] storage tokenRoyalties = royalties[tokenId];

        address[] memory royaltyReceivers =
        new address[](tokenRoyalties.length);
        uint256[] memory royaltyAmounts = new uint256[](tokenRoyalties.length);

        for (uint256 i = 0; i < tokenRoyalties.length; i++) {
            RoyaltyInfo storage tokenRoyalty = tokenRoyalties[i];
            royaltyReceivers[i] = tokenRoyalty.receiver;
            royaltyAmounts[i] = tokenRoyalty.amount;
        }

        return (royaltyReceivers, royaltyAmounts);
    }

    function onRoyaltiesReceived(
        address _royaltyRecipient,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    ) external returns (bytes4) {
        emit RoyaltiesReceived(
            _royaltyRecipient,
            _buyer,
            _tokenId,
            _tokenPaid,
            _amount,
            _metadata
        );

        return this.onRoyaltiesReceived.selector;
    }

    function mint(
        address recipient_,
        address[] calldata royaltyReceivers_,
        uint256[] calldata royaltyAmounts_,
        string memory metadata_
    ) external returns (uint256) {
        require(recipient_ != address(0x0), "Invalid recipient");
        require(
            royaltyReceivers_.length == royaltyAmounts_.length,
            "Invalid royalty data"
        );
        require(
            royaltyReceivers_.length <= ROYALTY_MAX_COUNT,
            "Royalty receivers max amount exceeded"
        );

        tokenIds.increment();
        uint256 newTokenId = tokenIds.current();

        _safeMint(recipient_, newTokenId);
        _setTokenURI(newTokenId, metadata_);

        for (uint256 i = 0; i < royaltyReceivers_.length; i++) {
            royalties[newTokenId].push(
                RoyaltyInfo(royaltyReceivers_[i], royaltyAmounts_[i])
            );
        }

        emit Mint(recipient_, royaltyReceivers_, royaltyAmounts_, metadata_);

        return newTokenId;
    }

    function mintWithID(
        address recipient_,
        address[] calldata royaltyReceivers_,
        uint256[] calldata royaltyAmounts_,
        string memory metadata_,
        uint256 tokenID_
    ) external onlyBridge returns (uint256) {
        require(recipient_ != address(0x0), "Invalid recipient");
        require(
            royaltyReceivers_.length == royaltyAmounts_.length,
            "Invalid royalty data"
        );
        require(
            royaltyReceivers_.length <= ROYALTY_MAX_COUNT,
            "Royalty receivers max amount exceeded"
        );

        _safeMint(recipient_, tokenID_);
        _setTokenURI(tokenID_, metadata_);

        for (uint256 i = 0; i < royaltyReceivers_.length; i++) {
            royalties[tokenID_].push(
                RoyaltyInfo(royaltyReceivers_[i], royaltyAmounts_[i])
            );
        }

        emit Mint(recipient_, royaltyReceivers_, royaltyAmounts_, metadata_);

        return tokenID_;
    }

    function burn(uint256 tokenId) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || isBurner(_msgSender()),
            "ERC721Burnable: caller is not owner nor approved, nor burner"
        );

        _burn(tokenId);
    }

    function isBurner(address account) public view returns (bool) {
        return hasRole(BURNER_ROLE, account);
    }

    function addBurner(address account) public onlyAdmin {
        grantRole(BURNER_ROLE, account);
    }

    function removeBurner(address account) public onlyAdmin {
        revokeRole(BURNER_ROLE, account);
    }

    function renounceBurner() public {
        renounceRole(BURNER_ROLE, _msgSender());
    }

    function setBridgeContract(address _bridgeContract) external onlyBridgeOwner {
        require(_bridgeContract != address(0), "can't set contract to zero address");
        bridgeContract = _bridgeContract;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./NFTBERC2981Enhanced.sol";
import "../interfaces/IBurnableMintableERC1155Token.sol";

contract NFTm is ERC1155Upgradeable, NFTBERC2981Enhanced, IBurnableMintableERC1155Token {
    string public name;
    string public symbol;
    uint256 public constant MINT_MAX_AMOUNT = 10000;
    mapping(uint256 => RoyaltyInfo[]) private royalties;

    // Optional mapping for token URIs
    mapping(uint256 => string) public _tokenURIs;

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    bool private hasAlreadyMinted;
    uint256 public mintLowerBound;
    uint256 public mintHigherBound;

    event Mint(
        address indexed _recipient,
        uint256 _tokenId,
        uint256 _amount,
        address[] _royaltyReceivers,
        uint256[] _royaltyAmounts
    );

    event MintBatch(
        address indexed _recipient,
        uint256[] _tokenId,
        uint256[] _amount,
        address[][] _royaltyReceivers,
        uint256[][] _royaltyAmounts
    );

    using SafeMath for uint256;

    function initializeNFTm(address _bridgeContract, uint256 _mintMillionNumber) public initializer {
        initializeNFTBERC2981Enhanced();
        __ERC1155_init("");
        name = "NFTB_NFTm";
        symbol = "NFTB_NFTm";
        bridgeContract = _bridgeContract;
        mintLowerBound = _mintMillionNumber.mul(1000000);
        tokenIds._value = mintLowerBound;
        mintHigherBound = mintLowerBound.add(999999);
    }

    function mint(
        address recipient_,
        uint256 amount_,
        string memory metadata_,
        address[] calldata royaltyReceivers_,
        uint256[] calldata royaltyAmounts_
    ) external returns (uint256, uint256) {
        require(recipient_ != address(0x0), "Invalid recipient");
        require(
            royaltyReceivers_.length == royaltyAmounts_.length,
            "Invalid royalty data"
        );
        require(
            royaltyReceivers_.length <= ROYALTY_MAX_COUNT,
            "Royalty receivers max amount exceeded"
        );

        uint256 royaltyPayment;
        for (uint256 i = 0; i < royaltyAmounts_.length; i++) {
            royaltyPayment = royaltyPayment + royaltyAmounts_[i];
        }
        //
        require(
            royaltyPayment * amount_ <= 50 * ROYALTY_PERCENTAGE,
            "Mint max amount exceeded"
        );

        tokenIds.increment();

        uint256 newTokenId = tokenIds.current();

        _mint(recipient_, newTokenId, amount_, "");
        _tokenURIs[newTokenId] = metadata_;

        for (uint256 i = 0; i < royaltyReceivers_.length; i++) {
            royalties[newTokenId].push(
                RoyaltyInfo(royaltyReceivers_[i], royaltyAmounts_[i])
            );
        }

        emit Mint(recipient_, newTokenId, amount_, royaltyReceivers_, royaltyAmounts_);

        return (newTokenId, amount_);
    }

    function mintBatchWithID(
        address recipient_,
        uint256[] memory amounts_,
        string[] memory tokenURIs_,
        address[][] calldata royaltyReceivers_,
        uint256[][] calldata royaltyAmounts_,
        uint256[] memory _tokenIds
    ) external
    override onlyBridge {
        require(_tokenIds.length == amounts_.length, "amounts mismatch");
        require(_tokenIds.length == tokenURIs_.length, "token URIs mismatch");
        require(_tokenIds.length == royaltyReceivers_.length, "royaltyReceivers length mismatch");
        require(recipient_ != address(0x0), "Invalid recipient");
        require(
            royaltyReceivers_.length == royaltyAmounts_.length,
            "Invalid royalty data"
        );
        require(
            royaltyReceivers_.length <= ROYALTY_MAX_COUNT,
            "Royalty receivers max amount exceeded"
        );

        for (uint256 i = 0; i < royaltyAmounts_.length; i++) {
            uint256 royaltyPayment;
            for (uint256 j = 0; j < royaltyAmounts_[i].length; j++) {
                royaltyPayment = royaltyPayment + royaltyAmounts_[i][j];
            }
            require(
                royaltyPayment * amounts_[i] <= 50 * ROYALTY_PERCENTAGE,
                "Mint max amount exceeded"
            );
        }

        if (_tokenIds.length == 1) {
            _mint(recipient_, _tokenIds[0], amounts_[0], "");
            _tokenURIs[_tokenIds[0]] = tokenURIs_[0];
            for (uint256 i = 0; i < royaltyReceivers_[0].length; i++) {
                bool toPush = true;
                for (uint256 j = 0; j < royalties[_tokenIds[0]].length; j++) {
                    if (royalties[_tokenIds[0]][j].receiver == royaltyReceivers_[0][i] && royalties[_tokenIds[0]][j].amount == royaltyAmounts_[0][i]) {
                        toPush = false;
                        break;
                    }
                }

                if (toPush) {
                    royalties[_tokenIds[0]].push(
                        RoyaltyInfo(royaltyReceivers_[0][i], royaltyAmounts_[0][i])
                    );
                }
            }
        } else {
            // Next few lines ensure that the first mint ever happened in his token contract will performed using TransferSingle event
            // Otherwise, NFT marketplaces have issues with indexing bridged token data.
            // On first mint ever (when hasAlreadyMinted is false), last token id from the list is minted using TransferSingle.
            // All over tokens from the list are minted using TransferBatch event.
            // All subsequent operations will always use TransferBatch for operations involving more than 1 token id.
            if (!hasAlreadyMinted) {
                require(_tokenIds.length > 1 && _tokenIds.length == amounts_.length, "length of id to it's amount mismatch");
                uint256 len = _tokenIds.length - 1;
                _mint(recipient_, _tokenIds[len], amounts_[len], new bytes(0));
                assembly {
                    mstore(_tokenIds, len) // _tokenIds.pop()
                    mstore(amounts_, len) // _values.pop()
                }
            }

            _mintBatch(recipient_, _tokenIds, amounts_, new bytes(0));

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _tokenURIs[_tokenIds[i]] = tokenURIs_[i];
            }

            for (uint256 i = 0; i < royaltyReceivers_.length; i++) {
                for (uint256 j = 0; j < royaltyReceivers_[i].length; j++) {
                    bool toPush = true;

                    for (uint256 k = 0; k < royalties[_tokenIds[i]].length; k++) {
                        if (royalties[_tokenIds[i]][k].receiver == royaltyReceivers_[i][j]
                            && royalties[_tokenIds[i]][k].amount == royaltyAmounts_[i][j]) {
                            toPush = false;
                            break;
                        }
                    }

                    if (toPush) {
                        royalties[_tokenIds[i]].push(
                            RoyaltyInfo(royaltyReceivers_[i][j], royaltyAmounts_[i][j])
                        );
                    }
                }
            }
        }
        hasAlreadyMinted = true;
        emit MintBatch(recipient_, _tokenIds, amounts_, royaltyReceivers_, royaltyAmounts_);
    }

    function burn(address account, uint256 id, uint256 amount) public {
        require(
            isApprovedForAll(account, _msgSender()) || isBurner(_msgSender()),
            "caller is not owner nor approved, nor burner"
        );

        _burn(account, id, amount);
    }

    function burnBatch(uint256[] memory _tokenIds, uint256[] memory _values) override external onlyBridge {
        _burnBatch(msg.sender, _tokenIds, _values);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function royaltyInfo(uint256 tokenId)
    external
    view
    returns (address[] memory, uint256[] memory)
    {
        RoyaltyInfo[] storage tokenRoyalties = royalties[tokenId];

        address[] memory royaltyReceivers =
        new address[](tokenRoyalties.length);
        uint256[] memory royaltyAmounts = new uint256[](tokenRoyalties.length);

        for (uint256 i = 0; i < tokenRoyalties.length; i++) {
            RoyaltyInfo storage tokenRoyalty = tokenRoyalties[i];
            royaltyReceivers[i] = tokenRoyalty.receiver;
            royaltyAmounts[i] = tokenRoyalty.amount;
        }

        return (royaltyReceivers, royaltyAmounts);
    }
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
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

interface IBurnableMintableERC1155Token is IERC1155Upgradeable {
    function mintBatchWithID(
        address recipient_,
        uint256[] memory amounts_,
        string[] memory tokenURIs_,
        address[][] calldata royaltyReceivers_,
        uint256[][] calldata royaltyAmounts_,
        uint256[] memory _tokenIds)
    external;

    function burnBatch(uint256[] memory _tokenIds, uint256[] memory _values) external;
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

import "../../utils/Context.sol";
import "./ERC721.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
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

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
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

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155MetadataURIUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(address(0)).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(address(0)).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}