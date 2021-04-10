// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IAMB.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseAMBMediator is Ownable {

    IAMB public bridge;
    address public mediatorOnOtherSide;
    uint public requestGasLimit;

    constructor(IAMB _bridge) {
        bridge = _bridge;
        requestGasLimit = _bridge.maxGasPerTx();
    }

    /**
    * @dev Throws if caller on the other side is not an associated mediator.
    */
    modifier onlyMediatorOnOtherSide {
        require(msg.sender == address(bridge), "sender should be AMB");
        require(bridge.messageSender() == mediatorOnOtherSide, "originator should be associated mediator");
        _;
    }

    function setRequestGasLimit(uint256 _requestGasLimit) external onlyOwner {
        require(_requestGasLimit <= bridge.maxGasPerTx());
        requestGasLimit = _requestGasLimit;
    }

    function setMediatorOnOtherSide(address _mediatorOnOtherSide) external onlyOwner {
        require(_mediatorOnOtherSide != address(0), "mediator cannot be null");
        mediatorOnOtherSide = _mediatorOnOtherSide;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../mainchain/StarSystemMaps.sol";
import "./MainchainAMBMediator.sol";

contract ChainAssigner is Ownable {

    IERC721 public starSystems;
    StarSystemMaps public starSystemMaps;
    mapping(uint => uint) public assignedChainIds; // [sysId] => [chainId]
    mapping(uint => address) public chainMediators; // [chainId] => [mediator]

    event ChainMediatorChanged(uint indexed _chainId, address _mediator);
    event StarSystemAssigned(uint indexed _sysId, uint indexed _chainId, address _recipient, bytes32 messageId);
    event StarSystemUnassigned(uint indexed _sysId, uint indexed _chainId);

    constructor(IERC721 _starSystems, StarSystemMaps _starSystemMaps) {
        starSystems = _starSystems;
        starSystemMaps = _starSystemMaps;
    }

    function setChainMediator(uint _chainId, address _mediator) external onlyOwner {
        chainMediators[_chainId] = _mediator;
        emit ChainMediatorChanged(_chainId, _mediator);
    }

    function assignStarSystem(uint _sysId, address _recipient, uint _chainId) external {
        require(_recipient != address(0), "_recipient should not be null");
        require(msg.sender == starSystems.ownerOf(_sysId), "sender should be system owner");
        address mediator = chainMediators[_chainId];
        require(mediator != address(0), "unsupported chain");
        uint currChainId = assignedChainIds[_sysId];
        require(currChainId == 0 || currChainId == _chainId || chainMediators[currChainId] == address(0), "system must be unassigned first");
        bytes32 messageId = MainchainAMBMediator(mediator).assignStarSystem(_sysId, _recipient, starSystemMaps.mapOf(_sysId));
        if(currChainId != _chainId) {
            assignedChainIds[_sysId] = _chainId;
        }
        emit StarSystemAssigned(_sysId, _chainId, _recipient, messageId);
    }

    function unassignStarSystem(uint _sysId, uint _chainId, bytes32 _sysMap) external {
        address mediator = chainMediators[_chainId];
        require(msg.sender == ((mediator != address(0)) ? mediator : starSystems.ownerOf(_sysId)), "sender should be chain mediator");
        require(assignedChainIds[_sysId] == _chainId, "_sysId is not assigned to _chainId");
        assignedChainIds[_sysId] = 0;
        if(_sysMap != starSystemMaps.mapOf(_sysId)) {
            starSystemMaps.setMap(_sysId, _sysMap); // sync map from sidechain to mainchain
        }
        emit StarSystemUnassigned(_sysId, _chainId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes calldata _data, uint256 _gas) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);

    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./SidechainAMBMediator.sol";
import "./ChainAssigner.sol";

contract MainchainAMBMediator is BaseAMBMediator {
    ChainAssigner public /*immutable*/ assigner;

    constructor(
        ChainAssigner _assigner, 
        IAMB _bridge
    ) 
        BaseAMBMediator(_bridge) 
    {
        assigner = _assigner;
    }

    // ETH -> xDAI

    // todo: make _sysMap a generic _metadata bytes array
    function assignStarSystem(uint _sysId, address _recipient, bytes32 _sysMap) external returns (bytes32 _messageId) {
        require(msg.sender == address(assigner), "sender should be chain assigner");
        bytes4 methodSelector = SidechainAMBMediator.assignStarSystem.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _sysId, _recipient, _sysMap);
        _messageId = bridge.requireToPassMessage(mediatorOnOtherSide, data, requestGasLimit);
    }

    // xDAI -> ETH

    function unassignStarSystem(uint _sysId, bytes32 _sysMap) external onlyMediatorOnOtherSide {
        assigner.unassignStarSystem(_sysId, bridge.destinationChainId(), _sysMap);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./BaseAMBMediator.sol";
import "./MainchainAMBMediator.sol";
import "../sidechain/StarSystemData.sol";

contract SidechainAMBMediator is BaseAMBMediator {
    StarSystemData public starSystemData;

    constructor(
        StarSystemData _starSystemData, 
        IAMB _bridge
    ) 
        BaseAMBMediator(_bridge) 
    {
        starSystemData = _starSystemData;
    }

    function setStarSystemData(StarSystemData _starSystemData) external onlyOwner {
        starSystemData = _starSystemData;
    }

    // ETH -> xDAI

    function assignStarSystem(uint _sysId, address _recipient, bytes32 _sysMap) external onlyMediatorOnOtherSide {
        starSystemData.setSystemData(_sysId, _recipient, _sysMap);
    }

    // xDAI -> ETH

    function unassignStarSystem(uint _sysId) external {
        require(msg.sender == starSystemData.ownerOf(_sysId), "sender should be system owner");
        bytes4 methodSelector = MainchainAMBMediator.unassignStarSystem.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _sysId, starSystemData.mapOf(_sysId));
        /*bytes32 _messageId =*/ bridge.requireToPassMessage(mediatorOnOtherSide, data, requestGasLimit);
        starSystemData.clearSystemData(_sysId);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemMaps is Ownable {

    mapping(address => bool) public mapEditors;
    mapping(uint => bytes32) public maps; // [sysId]

    event MapSet(uint indexed _sysId, bytes32 _newMap);

    function mapOf(uint _sysId) external view returns (bytes32) { 
        return maps[_sysId]; 
    }

    function setMapEditor(address _editor, bool _added) external onlyOwner { 
        mapEditors[_editor] = _added; 
    }

    function setMap(uint _sysId, bytes32 _sysMap) external {
        require(mapEditors[msg.sender], "Unauthorised to change system map");
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        maps[_sysId] = _sysMap;
        emit MapSet(_sysId, _sysMap);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemData is Ownable {

    struct SysData {
        bytes32 map;
        address owner;
    }

    uint public numSystems;
    mapping(uint => SysData) public sysData; // [sysId]
    mapping(address => bool) public dataEditors;

    event StarSystemMapSet(uint indexed _sysId, bytes32 _newMap);
    event StarSystemOwnerSet(uint indexed _sysId, address indexed _owner);
    event StarSystemDataCleared(uint indexed _sysId);

    modifier onlyDataEditor {
        require(dataEditors[msg.sender], "Unauthorised to change system data");
        _;
    }

    function ownerOf(uint _sysId) public view returns (address) { return sysData[_sysId].owner; }
    function mapOf(uint _sysId) external view returns (bytes32) { return sysData[_sysId].map; }

    function setDataEditor(address _editor, bool _added) external onlyOwner { 
        dataEditors[_editor] = _added; 
    }

    function setOwner(uint _sysId, address _owner) public onlyDataEditor {
        require(_owner != address(0), "_owner cannot be null");
        if(ownerOf(_sysId) == address(0)) {
            numSystems++;
        }
        sysData[_sysId].owner = _owner;
        emit StarSystemOwnerSet(_sysId, _owner);
    }

    function setMap(uint _sysId, bytes32 _sysMap) public onlyDataEditor {
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        sysData[_sysId].map = _sysMap;
        emit StarSystemMapSet(_sysId, _sysMap);
    }

    function setSystemData(uint _sysId, address _owner, bytes32 _sysMap) external onlyDataEditor {
        setOwner(_sysId, _owner);
        setMap(_sysId, _sysMap);
    }

    function clearSystemData(uint _sysId) external onlyDataEditor {
        require(ownerOf(_sysId) != address(0), "system data not set");
        numSystems--;
        delete sysData[_sysId];
        emit StarSystemDataCleared(_sysId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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