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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBurnableMintableERC721Token is IERC721 {
    function mint(address _to, uint256 _tokeId) external;

    function burn(uint256 _tokenId) external;

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;
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

interface IOwnable {
    function owner() external view returns (address);
}

pragma solidity 0.7.5;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IBurnableMintableERC721Token.sol";

/**
 * @title ERC721BridgeToken
 * @dev template token contract for bridged ERC721 tokens.
 */
contract ERC721BridgeToken is ERC721, IBurnableMintableERC721Token {
    address public bridgeContract;

    constructor(
        string memory _name,
        string memory _symbol,
        address _bridgeContract
    ) ERC721(_name, _symbol) {
        bridgeContract = _bridgeContract;
    }

    /**
     * @dev Throws if sender is not a bridge contract.
     */
    modifier onlyBridge() {
        require(msg.sender == bridgeContract);
        _;
    }

    /**
     * @dev Throws if sender is not a bridge contract or bridge contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner());
        _;
    }

    /**
     * @dev Tells if this contract implements the interface defined by
     * `interfaceId`. See the corresponding EIP165.
     * @return true, if interface is implemented.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;
        bytes4 INTERFACE_ID_ERC721 = 0x80ac58cd;
        bytes4 INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
        bytes4 INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
        return
            interfaceId == INTERFACE_ID_ERC165 ||
            interfaceId == INTERFACE_ID_ERC721 ||
            interfaceId == INTERFACE_ID_ERC721_METADATA ||
            interfaceId == INTERFACE_ID_ERC721_ENUMERABLE;
    }

    /**
     * @dev Stub for preventing unneeded storage writes.
     * All supported interfaces are hardcoded in the supportsInterface function.
     */
    function _registerInterface(bytes4) internal override {}

    /**
     * @dev Mint new ERC721 token.
     * Only bridge contract is authorized to mint tokens.
     * @param _to address of the newly created token owner.
     * @param _tokenId unique identifier of the minted token.
     */
    function mint(address _to, uint256 _tokenId) external override onlyBridge {
        _safeMint(_to, _tokenId);
    }

    /**
     * @dev Burns some ERC721 token.
     * Only bridge contract is authorized to burn tokens.
     * @param _tokenId unique identifier of the burned token.
     */
    function burn(uint256 _tokenId) external override onlyBridge {
        _burn(_tokenId);
    }

    // hack to access private fields in ERC721 contract
    struct MetadataStorage {
        string name;
        string symbol;
    }

    /**
     * @dev Updated bridged token name/symbol parameters.
     * Only bridge owner or bridge itself can call this method.
     * @param _name new name parameter, will be saved as is, without additional suffixes like " from Mainnet".
     * @param _symbol new symbol parameter.
     */
    function setMetadata(string calldata _name, string calldata _symbol) external onlyOwner {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);

        MetadataStorage storage metadata;
        assembly {
            metadata.slot := 6
        }
        metadata.name = _name;
        metadata.symbol = _symbol;
    }

    /**
     * @dev Sets the base URI for all tokens.
     * Can be called by bridge owner after token contract was instantiated.
     * @param _baseURI new base URI.
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    /**
     * @dev Updates the bridge contract address.
     * Can be called by bridge owner after token contract was instantiated.
     * @param _bridgeContract address of the new bridge contract.
     */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        require(_bridgeContract != address(0));
        bridgeContract = _bridgeContract;
    }

    /**
     * @dev Sets the URI for the particular token.
     * Can be called by bridge owner after token bridging.
     * @param _tokenId URI for the bridged token metadata.
     * @param _tokenURI new token URI.
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external override onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @dev Tells the current version of the ERC721 token interfaces.
     */
    function getTokenInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 1, 0);
    }
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
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        // solhint-disable-previous-line no-complex-fallback
        address _impl = implementation();
        require(_impl != address(0));
        assembly {
            /*
                0x40 is the "free memory slot", meaning a pointer to next slot of empty memory. mload(0x40)
                loads the data in the free memory slot, so `ptr` is a pointer to the next slot of empty
                memory. It's needed because we're going to write the return data of delegatecall to the
                free memory slot.
            */
            let ptr := mload(0x40)
            /*
                `calldatacopy` is copy calldatasize bytes from calldata
                First argument is the destination to which data is copied(ptr)
                Second argument specifies the start position of the copied data.
                    Since calldata is sort of its own unique location in memory,
                    0 doesn't refer to 0 in memory or 0 in storage - it just refers to the zeroth byte of calldata.
                    That's always going to be the zeroth byte of the function selector.
                Third argument, calldatasize, specifies how much data will be copied.
                    calldata is naturally calldatasize bytes long (same thing as msg.data.length)
            */
            calldatacopy(ptr, 0, calldatasize())
            /*
                delegatecall params explained:
                gas: the amount of gas to provide for the call. `gas` is an Opcode that gives
                    us the amount of gas still available to execution

                _impl: address of the contract to delegate to

                ptr: to pass copied data

                calldatasize: loads the size of `bytes memory data`, same as msg.data.length

                0, 0: These are for the `out` and `outsize` params. Because the output could be dynamic,
                        these are set to 0, 0 so the output data will not be written to memory. The output
                        data will be read using `returndatasize` and `returdatacopy` instead.

                result: This will be 0 if the call fails and 1 if it succeeds
            */
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            /*

            */
            /*
                ptr current points to the value stored at 0x40,
                because we assigned it like ptr := mload(0x40).
                Because we use 0x40 as a free memory pointer,
                we want to make sure that the next time we want to allocate memory,
                we aren't overwriting anything important.
                So, by adding ptr and returndatasize,
                we get a memory location beyond the end of the data we will be copying to ptr.
                We place this in at 0x40, and any reads from 0x40 will now read from free memory
            */
            mstore(0x40, add(ptr, returndatasize()))
            /*
                `returndatacopy` is an Opcode that copies the last return data to a slot. `ptr` is the
                    slot it will copy to, 0 means copy from the beginning of the return data, and size is
                    the amount of data to copy.
                `returndatasize` is an Opcode that gives us the size of the last return data. In this case, that is the size of the data returned from delegatecall
            */
            returndatacopy(ptr, 0, returndatasize())

            /*
                if `result` is 0, revert.
                if `result` is 1, return `size` amount of data from `ptr`. This is the data that was
                copied to `ptr` from the delegatecall return data
            */
            switch result
                case 0 {
                    revert(ptr, returndatasize())
                }
                default {
                    return(ptr, returndatasize())
                }
        }
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

import "../upgradeability/EternalStorage.sol";

contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
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

import "../interfaces/IUpgradeabilityOwnerStorage.sol";

contract Upgradeable {
    // Avoid using onlyUpgradeabilityOwner name to prevent issues with implementation from proxy contract
    modifier onlyIfUpgradeabilityOwner() {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
        _;
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
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "../Initializable.sol";
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
import "./components/bridged/ERC721TokenProxy.sol";
import "./components/bridged/ERC1155TokenProxy.sol";
import "./components/native/NFTMediatorBalanceStorage.sol";
import "../../tokens/ERC721BridgeToken.sol";

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
     * @param _name name of the native token, name suffix will be appended, if empty, symbol will be used instead.
     * @param _symbol symbol of the bridged token, if empty, name will be used instead.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     * @param _tokenURIs URIs for the bridged token instances.
     */
    function deployAndHandleBridgedNFT(
        address _token,
        string memory _name,
        string memory _symbol,
        address _recipient,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values,
        string[] calldata _tokenURIs
    ) external onlyMediator {
        address bridgedToken = bridgedTokenAddress(_token);
        if (bridgedToken == address(0)) {
            if (bytes(_name).length == 0) {
                if (bytes(_symbol).length > 0) {
                    _name = _transformName(_symbol);
                }
            } else {
                if (bytes(_symbol).length == 0) {
                    _symbol = _name;
                }
                _name = _transformName(_name);
            }
            bridgedToken = _values.length > 0
                ? address(new ERC1155TokenProxy(tokenImageERC1155(), _name, _symbol, address(this)))
                : address(new ERC721TokenProxy(tokenImageERC721(), _name, _symbol, address(this)));
            _setTokenAddressPair(_token, bridgedToken);
        }

        _handleTokens(bridgedToken, false, _recipient, _tokenIds, _values);
        _setTokensURI(bridgedToken, _tokenIds, _tokenURIs);
    }

    /**
     * @dev Handles the bridged token for the already registered token pair.
     * Checks that the bridged token is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC721 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _tokenIds unique ids of the bridged tokens.
     * @param _values amounts of bridged tokens. Should be empty list for ERC721.
     * @param _tokenURIs URIs for the bridged token instances.
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
        require(isRegisteredAsNativeToken(_token));
        require(_tokenIds.length > 0);

        uint256[] memory values = new uint256[](0);

        bytes memory data = _prepareMessage(_token, _receiver, _tokenIds, values);
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _receiver, _tokenIds, values);
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
        require(isRegisteredAsNativeToken(_token));
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
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    uint256 oldBalance = mediatorOwns(_token, _tokenIds[i]);
                    uint256 newBalance = oldBalance.add(_values[i]);
                    require(IERC1155(_token).balanceOf(address(this), _tokenIds[i]) >= newBalance);
                    _setMediatorOwns(_token, _tokenIds[i], newBalance);
                    tokenURIs[i] = _readERC1155TokenURI(_token, _tokenIds[i]);
                }
            } else {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    require(mediatorOwns(_token, _tokenIds[i]) == 0);
                    require(IERC721(_token).ownerOf(_tokenIds[i]) == address(this));
                    _setMediatorOwns(_token, _tokenIds[i], 1);
                    tokenURIs[i] = _readERC721TokenURI(_token, _tokenIds[i]);
                }
            }

            // process token which bridged alternative was already ACKed to be deployed
            if (isBridgedTokenDeployAcknowledged(_token)) {
                require(_tokenIds.length <= MAX_BATCH_BRIDGE_LIMIT);
                return
                    abi.encodeWithSelector(
                        this.handleBridgedNFT.selector,
                        _token,
                        _receiver,
                        _tokenIds,
                        _values,
                        tokenURIs
                    );
            }

            require(_tokenIds.length <= MAX_BATCH_BRIDGE_AND_DEPLOY_LIMIT);

            string memory name = _readName(_token);
            string memory symbol = _readSymbol(_token);

            return
                abi.encodeWithSelector(
                    this.deployAndHandleBridgedNFT.selector,
                    _token,
                    name,
                    symbol,
                    _receiver,
                    _tokenIds,
                    _values,
                    tokenURIs
                );
        }

        // process already known token that is bridged from other chain
        if (_values.length > 0) {
            IBurnableMintableERC1155Token(_token).burn(_tokenIds, _values);
        } else {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IBurnableMintableERC721Token(_token).burn(_tokenIds[i]);
            }
        }
        return abi.encodeWithSelector(this.handleNativeNFT.selector, nativeToken, _receiver, _tokenIds, _values);
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
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    _setMediatorOwns(_token, _tokenIds[i], mediatorOwns(_token, _tokenIds[i]).sub(_values[i]));
                }
                IERC1155(_token).safeBatchTransferFrom(address(this), _recipient, _tokenIds, _values, new bytes(0));
            } else {
                IBurnableMintableERC1155Token(_token).mint(_recipient, _tokenIds, _values);
            }
        } else {
            if (_isNative) {
                for (uint256 i = 0; i < _tokenIds.length; i++) {
                    _setMediatorOwns(_token, _tokenIds[i], 0);
                    IERC721(_token).transferFrom(address(this), _recipient, _tokenIds[i]);
                }
            } else {
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

    /**
     * @dev Internal function for transforming the bridged token name. Appends a side-specific suffix.
     * @param _name bridged token from the other side.
     * @return token name for this side of the bridge.
     */
    function _transformName(string memory _name) internal view returns (string memory) {
        string memory result = string(abi.encodePacked(_name, SUFFIX));
        uint256 size = SUFFIX_SIZE;
        assembly {
            mstore(result, add(mload(_name), size))
        }
        return result;
    }
}

pragma solidity 0.7.5;
// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "./BasicNFTOmnibridge.sol";
import "./components/common/GasLimitManager.sol";

/**
 * @title ForeignNFTOmnibridge
 * @dev Foreign side implementation for multi-token ERC721 mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract ForeignNFTOmnibridge is BasicNFTOmnibridge, GasLimitManager {
    constructor(string memory _suffix) BasicNFTOmnibridge(_suffix) {}

    /**
     * @dev Stores the initial parameters of the mediator.
     * @param _bridgeContract the address of the AMB bridge contract.
     * @param _mediatorContract the address of the mediator contract on the other network.
     * @param _requestGasLimit the gas limit for the message execution.
     * @param _owner address of the owner of the mediator contract.
     * @param _imageERC721 address of the ERC721 token image.
     * @param _imageERC1155 address of the ERC1155 token image.
     */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256 _requestGasLimit,
        address _owner,
        address _imageERC721,
        address _imageERC1155
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setRequestGasLimit(_requestGasLimit);
        _setOwner(_owner);
        _setTokenImageERC721(_imageERC721);
        _setTokenImageERC1155(_imageERC1155);

        setInitialize();

        return isInitialized();
    }

    /**
     * @dev Internal function for sending an AMB message to the mediator on the other side.
     * @param _data data to be sent to the other side of the bridge.
     * @param _useOracleLane always true, not used on this side of the bridge.
     * @return id of the sent message.
     */
    function _passMessage(bytes memory _data, bool _useOracleLane) internal override returns (bytes32) {
        (_useOracleLane);

        return bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), _data, requestGasLimit());
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

import "@openzeppelin/contracts/utils/Address.sol";
import "../../../../upgradeability/Proxy.sol";
import "../../../../interfaces/IOwnable.sol";

/**
 * @title ERC1155TokenProxy
 * @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
 */
contract ERC1155TokenProxy is Proxy {
    // storage layout is copied from ERC1155BridgeToken.sol
    mapping(bytes4 => bool) private _supportedInterfaces;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // not used, kept for correct storage layout representation
    string private _uri;

    string private name;
    string private symbol;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURI;
    address private bridgeContract;

    /**
     * @dev Creates an upgradeable token proxy for ERC1155BridgeToken.sol, initializes its eternalStorage.
     * @param _tokenImage address of the token image used for mirroring all functions.
     * @param _name token name.
     * @param _symbol token symbol.
     * @param _owner address of the owner for this contract.
     */
    constructor(
        address _tokenImage,
        string memory _name,
        string memory _symbol,
        address _owner
    ) {
        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        bridgeContract = _owner; // _owner == HomeOmnibridgeNFT/ForeignOmnibridgeNFT mediator
    }

    /**
     * @dev Retrieves the implementation contract address, mirrored token image.
     * @return impl token image address.
     */
    function implementation() public view override returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }

    /**
     * @dev Updates the implementation contract address.
     * Only the bridge and bridge owner can call this method.
     * @param _implementation address of the new implementation.
     */
    function setImplementation(address _implementation) external {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner());
        require(_implementation != address(0));
        require(Address.isContract(_implementation));
        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _implementation)
        }
    }

    /**
     * @dev Tells the current version of the ERC1155 token proxy interfaces.
     */
    function getTokenProxyInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../../../upgradeability/Proxy.sol";
import "../../../../interfaces/IOwnable.sol";

/**
 * @title ERC721TokenProxy
 * @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
 */
contract ERC721TokenProxy is Proxy {
    // storage layout is copied from ERC721BridgeToken.sol
    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(address => uint256) private _holderTokens;

    //EnumerableMap.UintToAddressMap private _tokenOwners;
    uint256[] private _tokenOwnersEntries;
    mapping(bytes32 => uint256) private _tokenOwnersIndexes;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private name;
    string private symbol;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURI;
    address private bridgeContract;

    /**
     * @dev Creates an upgradeable token proxy for ERC721BridgeToken.sol, initializes its eternalStorage.
     * @param _tokenImage address of the token image used for mirroring all functions.
     * @param _name token name.
     * @param _symbol token symbol.
     * @param _owner address of the owner for this contract.
     */
    constructor(
        address _tokenImage,
        string memory _name,
        string memory _symbol,
        address _owner
    ) {
        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        bridgeContract = _owner; // _owner == HomeOmnibridgeNFT/ForeignOmnibridgeNFT mediator
    }

    /**
     * @dev Retrieves the implementation contract address, mirrored token image.
     * @return impl token image address.
     */
    function implementation() public view override returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }

    /**
     * @dev Updates the implementation contract address.
     * Only the bridge and bridge owner can call this method.
     * @param _implementation address of the new implementation.
     */
    function setImplementation(address _implementation) external {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner());
        require(_implementation != address(0));
        require(Address.isContract(_implementation));
        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _implementation)
        }
    }

    /**
     * @dev Tells the current version of the ERC721 token proxy interfaces.
     */
    function getTokenProxyInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }
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

import "../../../../interfaces/IERC1155TokenReceiver.sol";
import "./BaseRelayer.sol";

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
        bridgeSpecificActionsOnTokenTransfer(msg.sender, _from, _chooseReceiver(_from, _data), _tokenIds, _values);
        return msg.sig;
    }
}

pragma solidity 0.7.5;

import "../../../../interfaces/IBurnableMintableERC721Token.sol";
import "../../../ReentrancyGuard.sol";
import "./BaseRelayer.sol";

/**
 * @title ERC721Relayer
 * @dev Functionality for bridging multiple ERC721 tokens to the other side of the bridge.
 */
abstract contract ERC721Relayer is BaseRelayer, ReentrancyGuard {
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
    ) external returns (bytes4) {
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
        require(!lock());

        setLock(true);
        _token.transferFrom(msg.sender, address(this), _tokenId);
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

        bytes memory data =
            abi.encodeWithSelector(this.fixFailedMessage.selector, _messageId, _token, _sender, _tokenIds, _values);
        _passMessage(data, false);
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

import "../../../BasicAMBMediator.sol";

/**
 * @title GasLimitManager
 * @dev Functionality for determining the request gas limit for AMB execution.
 */
abstract contract GasLimitManager is BasicAMBMediator {
    bytes32 internal constant REQUEST_GAS_LIMIT = 0x2dfd6c9f781bb6bbb5369c114e949b69ebb440ef3d4dd6b2836225eb1dc3a2be; // keccak256(abi.encodePacked("requestGasLimit"))

    /**
     * @dev Sets the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(uint256 _gasLimit) external onlyOwner {
        _setRequestGasLimit(_gasLimit);
    }

    /**
     * @dev Tells the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit() public view returns (uint256) {
        return uintStorage[REQUEST_GAS_LIMIT];
    }

    /**
     * @dev Stores the gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _gasLimit the gas limit for the message execution.
     */
    function _setRequestGasLimit(uint256 _gasLimit) internal {
        require(_gasLimit <= maxGasPerTx());
        uintStorage[REQUEST_GAS_LIMIT] = _gasLimit;
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