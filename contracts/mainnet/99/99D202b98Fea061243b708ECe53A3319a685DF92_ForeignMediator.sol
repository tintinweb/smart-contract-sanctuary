// File: bridge-contracts/contracts/upgradeability/EternalStorage.sol

pragma solidity 0.4.24;

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

// File: bridge-contracts/contracts/upgradeable_contracts/Initializable.sol

pragma solidity 0.4.24;


contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = keccak256(abi.encodePacked("isInitialized"));
    bytes32 internal constant DEPLOYED_AT_BLOCK = keccak256(abi.encodePacked("deployedAtBlock"));

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }

    function deployedAtBlock() external view returns (uint256) {
        return uintStorage[DEPLOYED_AT_BLOCK];
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: bridge-contracts/contracts/upgradeable_contracts/Sacrifice.sol

pragma solidity 0.4.24;

contract Sacrifice {
    constructor(address _recipient) public payable {
        selfdestruct(_recipient);
    }
}

// File: bridge-contracts/contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.4.24;



contract Claimable {
    bytes4 internal constant TRANSFER = 0xa9059cbb; // transfer(address,uint256)

    modifier validAddress(address _to) {
        require(_to != address(0));
        /* solcov ignore next */
        _;
    }

    function claimValues(address _token, address _to) internal {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        if (!_to.send(value)) {
            (new Sacrifice).value(value)(_to);
        }
    }

    function claimErc20Tokens(address _token, address _to) internal {
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        safeTransfer(_token, _to, balance);
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        bytes memory returnData;
        bool returnDataResult;
        bytes memory callData = abi.encodeWithSelector(TRANSFER, _to, _value);
        assembly {
            let result := call(gas, _token, 0x0, add(callData, 0x20), mload(callData), 0, 32)
            returnData := mload(0)
            returnDataResult := mload(0)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }

        // Return data is optional
        if (returnData.length > 0) {
            require(returnDataResult);
        }
    }
}

// File: bridge-contracts/contracts/interfaces/IUpgradeabilityOwnerStorage.sol

pragma solidity 0.4.24;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// File: bridge-contracts/contracts/upgradeable_contracts/Upgradeable.sol

pragma solidity 0.4.24;


contract Upgradeable {
    // Avoid using onlyUpgradeabilityOwner name to prevent issues with implementation from proxy contract
    modifier onlyIfUpgradeabilityOwner() {
        require(msg.sender == IUpgradeabilityOwnerStorage(this).upgradeabilityOwner());
        /* solcov ignore next */
        _;
    }
}

// File: bridge-contracts/contracts/libraries/Bytes.sol

pragma solidity 0.4.24;

library Bytes {
    function bytesToBytes32(bytes _bytes) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_bytes, 32))
        }
    }
}

// File: bridge-contracts/contracts/interfaces/IAMB.sol

pragma solidity 0.4.24;

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageCallStatus(bytes32 _txHash) external view returns (bool);
    function failedMessageDataHash(bytes32 _txHash) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _txHash) external view returns (address);
    function failedMessageSender(bytes32 _txHash) external view returns (address);
    function requireToPassMessage(address _contract, bytes _data, uint256 _gas) external;
}

// File: bridge-contracts/contracts/upgradeable_contracts/Ownable.sol

pragma solidity 0.4.24;


/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
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
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("owner"))];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256(abi.encodePacked("owner"))] = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: contracts/mediator/AMBMediator.sol

pragma solidity 0.4.24;





contract AMBMediator is EternalStorage, Ownable {
    bytes32 internal constant BRIDGE_CONTRACT = keccak256(abi.encodePacked("bridgeContract"));
    bytes32 internal constant MEDIATOR_CONTRACT = keccak256(abi.encodePacked("mediatorContract"));
    bytes32 internal constant REQUEST_GAS_LIMIT = keccak256(abi.encodePacked("requestGasLimit"));

    function setBridgeContract(address _bridgeContract) external onlyOwner {
        _setBridgeContract(_bridgeContract);
    }

    function _setBridgeContract(address _bridgeContract) internal {
        require(AddressUtils.isContract(_bridgeContract));
        addressStorage[BRIDGE_CONTRACT] = _bridgeContract;
    }

    function bridgeContract() public view returns (IAMB) {
        return IAMB(addressStorage[BRIDGE_CONTRACT]);
    }

    function setMediatorContractOnOtherSide(address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_mediatorContract);
    }

    function _setMediatorContractOnOtherSide(address _mediatorContract) internal {
        addressStorage[MEDIATOR_CONTRACT] = _mediatorContract;
    }

    function mediatorContractOnOtherSide() public view returns (address) {
        return addressStorage[MEDIATOR_CONTRACT];
    }

    function setRequestGasLimit(uint256 _requestGasLimit) external onlyOwner {
        _setRequestGasLimit(_requestGasLimit);
    }

    function _setRequestGasLimit(uint256 _requestGasLimit) internal {
        require(_requestGasLimit <= bridgeContract().maxGasPerTx());
        uintStorage[REQUEST_GAS_LIMIT] = _requestGasLimit;
    }

    function requestGasLimit() public view returns (uint256) {
        return uintStorage[REQUEST_GAS_LIMIT];
    }
}

// File: contracts/kitty/ERC721.sol

pragma solidity 0.4.24;
/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// File: contracts/mediator/ERC721Bridge.sol

pragma solidity 0.4.24;




contract ERC721Bridge is EternalStorage {
    bytes32 internal constant ERC721_TOKEN = keccak256(abi.encodePacked("erc721token"));

    function erc721token() public view returns (ERC721) {
        return ERC721(addressStorage[ERC721_TOKEN]);
    }

    function setErc721token(address _token) internal {
        require(AddressUtils.isContract(_token));
        addressStorage[ERC721_TOKEN] = _token;
    }
}

// File: contracts/mediator/BasicMediator.sol

pragma solidity 0.4.24;







contract BasicMediator is Initializable, AMBMediator, ERC721Bridge, Upgradeable, Claimable {
    event FailedMessageFixed(bytes32 indexed dataHash, address recipient, uint256 tokenId);

    bytes32 internal constant NONCE = keccak256(abi.encodePacked("nonce"));
    bytes4 internal constant GET_KITTY = 0xe98b7f4d; // getKitty(uint256)

    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        address _erc721token,
        uint256 _requestGasLimit,
        address _owner
    ) external returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        setErc721token(_erc721token);
        _setRequestGasLimit(_requestGasLimit);
        setOwner(_owner);
        setNonce(keccak256(abi.encodePacked(address(this))));
        setInitialize();

        return isInitialized();
    }

    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (1, 0, 0);
    }

    function getBridgeMode() external pure returns (bytes4 _data) {
        return bytes4(keccak256(abi.encodePacked("nft-to-nft-amb")));
    }

    function transferToken(address _from, uint256 _tokenId) external {
        ERC721 token = erc721token();
        address to = address(this);

        token.transferFrom(_from, to, _tokenId);
        bridgeSpecificActionsOnTokenTransfer(_from, _tokenId);
    }

    /**
    *  getKitty(uint256) returns:
    *       bool isGestating,
    *       bool isReady,
    *       uint256 cooldownIndex,
    *       uint256 nextActionAt,
    *       uint256 siringWithId,
    *       uint256 birthTime,
    *       uint256 matronId,
    *       uint256 sireId,
    *       uint256 generation,
    *       uint256 genes
    **/
    function getMetadata(uint256 _tokenId) internal view returns (bytes memory metadata) {
        bytes memory callData = abi.encodeWithSelector(GET_KITTY, _tokenId);
        address tokenAddress = erc721token();
        metadata = new bytes(320);
        assembly {
            let result := call(gas, tokenAddress, 0x0, add(callData, 0x20), mload(callData), 0, 0)
            returndatacopy(add(metadata, 0x20), 0, returndatasize)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }
    }

    function nonce() internal view returns (bytes32) {
        return Bytes.bytesToBytes32(bytesStorage[NONCE]);
    }

    function setNonce(bytes32 _hash) internal {
        bytesStorage[NONCE] = abi.encodePacked(_hash);
    }

    function setMessageHashTokenId(bytes32 _hash, uint256 _tokenId) internal {
        uintStorage[keccak256(abi.encodePacked("messageHashTokenId", _hash))] = _tokenId;
    }

    function messageHashTokenId(bytes32 _hash) internal view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("messageHashTokenId", _hash))];
    }

    function setMessageHashRecipient(bytes32 _hash, address _recipient) internal {
        addressStorage[keccak256(abi.encodePacked("messageHashRecipient", _hash))] = _recipient;
    }

    function messageHashRecipient(bytes32 _hash) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("messageHashRecipient", _hash))];
    }

    function setMessageHashFixed(bytes32 _hash) internal {
        boolStorage[keccak256(abi.encodePacked("messageHashFixed", _hash))] = true;
    }

    function messageHashFixed(bytes32 _hash) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageHashFixed", _hash))];
    }

    function requestFailedMessageFix(bytes32 _txHash) external {
        require(!bridgeContract().messageCallStatus(_txHash));
        require(bridgeContract().failedMessageReceiver(_txHash) == address(this));
        require(bridgeContract().failedMessageSender(_txHash) == mediatorContractOnOtherSide());
        bytes32 dataHash = bridgeContract().failedMessageDataHash(_txHash);

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, dataHash);
        bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), data, requestGasLimit());
    }

    function claimTokens(address _token, address _to) public onlyIfUpgradeabilityOwner validAddress(_to) {
        claimValues(_token, _to);
    }

    function fixFailedMessage(bytes32 _dataHash) external;

    function bridgeSpecificActionsOnTokenTransfer(address _from, uint256 _tokenId) internal;
}

// File: contracts/interfaces/IHomeMediator.sol

pragma solidity 0.4.24;

interface IHomeMediator {
    function handleBridgedTokens(address _recipient, uint256 _tokenId, bytes _metadata, bytes32 _nonce) external;
}

// File: contracts/mediator/ForeignMediator.sol

pragma solidity 0.4.24;



contract ForeignMediator is BasicMediator {
    function passMessage(address _from, uint256 _tokenId) internal {
        bytes memory metadata = getMetadata(_tokenId);

        bytes4 methodSelector = IHomeMediator(0).handleBridgedTokens.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _from, _tokenId, metadata, nonce());

        bytes32 dataHash = keccak256(data);
        setMessageHashTokenId(dataHash, _tokenId);
        setMessageHashRecipient(dataHash, _from);
        setNonce(dataHash);

        bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), data, requestGasLimit());
    }

    function handleBridgedTokens(
        address _recipient,
        uint256 _tokenId,
        bytes32 /* _nonce */
    ) external {
        require(msg.sender == address(bridgeContract()));
        require(bridgeContract().messageSender() == mediatorContractOnOtherSide());
        erc721token().transfer(_recipient, _tokenId);
    }

    function bridgeSpecificActionsOnTokenTransfer(address _from, uint256 _tokenId) internal {
        passMessage(_from, _tokenId);
    }

    function fixFailedMessage(bytes32 _dataHash) external {
        require(msg.sender == address(bridgeContract()));
        require(bridgeContract().messageSender() == mediatorContractOnOtherSide());
        require(!messageHashFixed(_dataHash));

        address recipient = messageHashRecipient(_dataHash);
        uint256 tokenId = messageHashTokenId(_dataHash);

        setMessageHashFixed(_dataHash);
        erc721token().transfer(recipient, tokenId);

        emit FailedMessageFixed(_dataHash, recipient, tokenId);
    }
}