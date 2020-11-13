// File: @openzeppelin\contracts\token\ERC721\IERC721Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

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

// File: orchestrator\IEthItemOrchestrator.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IEthItemOrchestrator is IERC721Receiver, IERC1155Receiver {

    function factories() external view returns(address[] memory);

    function factory() external view returns(address);

    function setFactory(address newFactory) external;

    function knowledgeBases() external view returns(address[] memory);

    function knowledgeBase() external view returns(address);

    function setKnowledgeBase(address newKnowledgeBase) external;

    function ENSController() external view returns (address);

    function setENSController(address newEnsController) external;

    function transferENS(address receiver, bytes32 domainNode, uint256 domainId, bool reclaimFirst, bool safeTransferFrom, bytes memory payload) external;

    /**
     * @dev GET - The DoubleProxy of the DFO linked to this Contract
     */
    function doubleProxy() external view returns (address);

    /**
     * @dev SET - The DoubleProxy of the DFO linked to this Contract
     * It can be done only through a Proposal in the Linked DFO
     * @param newDoubleProxy the new DoubleProxy address
     */
    function setDoubleProxy(address newDoubleProxy) external;

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the EthItemERC20Wrappers (please see the eth-item-token-standard for further information).
     * It can be done only through a Proposal in the Linked DFO
     */
    function setEthItemInteroperableInterfaceModel(address ethItemInteroperableInterfaceModelAddress) external;

    /**
     * @dev SET - The address of the Native EthItem model.
     * It can be done only through a Proposal in the Linked DFO
     */
    function setNativeModel(address nativeModelAddress) external;

    /**
     * @dev SET - The address of the ERC1155 NFT-Based EthItem model.
     * It can be done only through a Proposal in the Linked DFO
     */
    function setERC1155WrapperModel(address erc1155WrapperModelAddress) external;

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC20 EthItems.
     * It can be done only through a Proposal in the Linked DFO
     */
    function setERC20WrapperModel(address erc20WrapperModelAddress) external;

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC721 EthItems.
     * It can be done only through a Proposal in the Linked DFO
     */
    function setERC721WrapperModel(address erc721WrapperModelAddress) external;

    /**
     * @dev SET - The element useful to calculate the Percentage fee
     * It can be done only through a Proposal in the Linked DFO
     */
    function setMintFeePercentage(uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator) external;

    /**
     * @dev SET - The element useful to calculate the Percentage fee
     * It can be done only through a Proposal in the Linked DFO
     */
    function setBurnFeePercentage(uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) external;

    function createNative(bytes calldata modelInitPayload, string calldata ens)
        external
        returns (address newNativeAddress, bytes memory modelInitCallResponse);

    function createERC20Wrapper(bytes calldata modelInitPayload)
        external
        returns (address newEthItemAddress, bytes memory modelInitCallResponse);
}

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function getStateHolderAddress() external view returns(address);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: orchestrator\IEthItemOrchestratorDependantElement.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


interface IEthItemOrchestratorDependantElement is IERC165 {

    /**
     * @dev GET - The DoubleProxy of the DFO linked to this Contract
     */
    function doubleProxy() external view returns (address);

    /**
     * @dev SET - The DoubleProxy of the DFO linked to this Contract
     * It can be done only by the Factory controller
     * @param newDoubleProxy the new DoubleProxy address
     */
    function setDoubleProxy(address newDoubleProxy) external;

    function isAuthorizedOrchestrator(address operator) external view returns(bool);
}

// File: factory\IEthItemFactory.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @title IEthItemFactory
 * @dev This contract represents the Factory Used to deploy all the EthItems, keeping track of them.
 */
interface IEthItemFactory is IEthItemOrchestratorDependantElement {

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the EthItemERC20Wrappers (please see the eth-item-token-standard for further information).
     */
    function ethItemInteroperableInterfaceModel() external view returns (address ethItemInteroperableInterfaceModelAddress, uint256 ethItemInteroperableInterfaceModelVersion);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the EthItemERC20Wrappers (please see the eth-item-token-standard for further information).
     * It can be done only by the Factory controller
     */
    function setEthItemInteroperableInterfaceModel(address ethItemInteroperableInterfaceModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Native EthItems.
     * Every EthItem will have its own address, but the code will be cloned from this one.
     */
    function nativeModel() external view returns (address nativeModelAddress, uint256 nativeModelVersion);

    /**
     * @dev SET - The address of the Native EthItem model.
     * It can be done only by the Factory controller
     */
    function setNativeModel(address nativeModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC1155 EthItems.
     * Every EthItem will have its own address, but the code will be cloned from this one.
     */
    function erc1155WrapperModel() external view returns (address erc1155WrapperModelAddress, uint256 erc1155WrapperModelVersion);

    /**
     * @dev SET - The address of the ERC1155 NFT-Based EthItem model.
     * It can be done only by the Factory controller
     */
    function setERC1155WrapperModel(address erc1155WrapperModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC20 EthItems.
     */
    function erc20WrapperModel() external view returns (address erc20WrapperModelAddress, uint256 erc20WrapperModelVersion);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC20 EthItems.
     * It can be done only by the Factory controller
     */
    function setERC20WrapperModel(address erc20WrapperModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC721 EthItems.
     */
    function erc721WrapperModel() external view returns (address erc721WrapperModelAddress, uint256 erc721WrapperModelVersion);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC721 EthItems.
     * It can be done only by the Factory controller
     */
    function setERC721WrapperModel(address erc721WrapperModelAddress) external;

    /**
     * @dev GET - The elements (numerator and denominator) useful to calculate the percentage fee to be transfered to the DFO for every new Minted EthItem
     */
    function mintFeePercentage() external view returns (uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator);

    /**
     * @dev SET - The element useful to calculate the Percentage fee
     * It can be done only by the Factory controller
     */
    function setMintFeePercentage(uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator) external;

    /**
     * @dev Useful utility method to calculate the percentage fee to transfer to the DFO for the minted EthItem amount.
     * @param erc20WrapperAmount The amount of minted EthItem
     */
    function calculateMintFee(uint256 erc20WrapperAmount) external view returns (uint256 mintFee, address dfoWalletAddress);

    /**
     * @dev GET - The elements (numerator and denominator) useful to calculate the percentage fee to be transfered to the DFO for every Burned EthItem
     */
    function burnFeePercentage() external view returns (uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator);

    /**
     * @dev SET - The element useful to calculate the Percentage fee
     * It can be done only by the Factory controller
     */
    function setBurnFeePercentage(uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) external;

    /**
     * @dev Useful utility method to calculate the percentage fee to transfer to the DFO for the burned EthItem amount.
     * @param erc20WrapperAmount The amount of burned EthItem
     */
    function calculateBurnFee(uint256 erc20WrapperAmount) external view returns (uint256 burnFee, address dfoWalletAddress);

    /**
     * @dev Business Logic to create a brand-new EthItem.
     * It raises the 'NewNativeCreated' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createNative(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewNativeCreated(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewNativeCreated(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC1155 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC1155Created' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC1155(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC1155Created(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewWrappedERC1155Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC20 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC20Created' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC20(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC20Created(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewWrappedERC20Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC721 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC721Created' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC721(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC721Created(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewWrappedERC721Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);
}

// File: knowledgeBase\IKnowledgeBase.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @title IKnowledgeBase
 * @dev This contract represents the Factory Used to deploy all the EthItems, keeping track of them.
 */
interface IKnowledgeBase is IEthItemOrchestratorDependantElement {

    function setERC20Wrapper(address erc20Wrapper) external;

    function erc20Wrappers() external view returns(address[] memory);

    function erc20Wrapper() external view returns(address);

    function setEthItem(address ethItem) external;

    function isEthItem(address ethItem) external view returns(bool);

    function setWrapped(address wrappedAddress, address ethItem) external;

    function wrapper(address wrappedAddress, uint256 version) external view returns (address ethItem);
}

// File: ens-controller\IENSController.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IENSController is IEthItemOrchestratorDependantElement, IERC721Receiver {

    function attachENS(address ethItem, string calldata ens) external;

    function transfer(address receiver, bytes32 domainNode, uint256 domainId, bool reclaimFirst, bool safeTransferFrom, bytes memory payload) external;

    function data() external view returns(uint256 domainId, bytes32 domainNode);

    event ENSAttached(address indexed ethItem, string indexed ensIndex, string ens);
}

// File: @openzeppelin\contracts\introspection\ERC165.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.2;


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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.2;


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

// File: node_modules\eth-item-token-standard\IERC1155Views.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param objectId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 objectId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param objectId the id of the token whose name you want to know 
     */
    function name(uint256 objectId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param objectId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 objectId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param objectId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 objectId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param objectId the id of the token whose uri you want to know 
     */
    function uri(uint256 objectId) external view returns (string memory);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: node_modules\eth-item-token-standard\IBaseTokenData.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

interface IBaseTokenData {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// File: node_modules\eth-item-token-standard\IERC20Data.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IERC20Data is IBaseTokenData, IERC20 {
    function decimals() external view returns (uint256);
}

// File: node_modules\eth-item-token-standard\IEthItemInteroperableInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IEthItemInteroperableInterface is IERC20, IERC20Data {

    function init(uint256 objectId, string memory name, string memory symbol, uint256 decimals) external;

    function mainInterface() external view returns (address);

    function objectId() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function permitNonce(address sender) external view returns(uint256);

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external;

    function interoperableInterfaceVersion() external pure returns(uint256 ethItemInteroperableInterfaceVersion);
}

// File: eth-item-token-standard\IEthItemMainInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;






interface IEthItemMainInterface is IERC1155, IERC1155Views, IBaseTokenData {

    function init(
        address interoperableInterfaceModel,
        string calldata name,
        string calldata symbol
    ) external;

    function mainInterfaceVersion() external pure returns(uint256 ethItemInteroperableVersion);

    function toInteroperableInterfaceAmount(uint256 objectId, uint256 ethItemAmount) external view returns (uint256 interoperableInterfaceAmount);

    function toMainInterfaceAmount(uint256 objectId, uint256 erc20WrapperAmount) external view returns (uint256 mainInterfaceAmount);

    function interoperableInterfaceModel() external view returns (address, uint256);

    function asInteroperable(uint256 objectId) external view returns (IEthItemInteroperableInterface);

    function emitTransferSingleEvent(address sender, address from, address to, uint256 objectId, uint256 amount) external;

    function mint(uint256 amount, string calldata partialUri)
        external
        returns (uint256, address);

    function burn(
        uint256 objectId,
        uint256 amount
    ) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts
    ) external;

    event NewItem(uint256 indexed objectId, address indexed tokenAddress);
    event Mint(uint256 objectId, address tokenAddress, uint256 amount);
}

// File: orchestrator\EthItemOrchestrator.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;








contract EthItemOrchestrator is IEthItemOrchestrator, ERC165 {

    address private constant ENS_TOKEN_ADDRESS = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;

    address private _doubleProxy;
    address[] private _factories;
    address[] private _knowledgeBases;
    address private _ensController;

    constructor(
        address doubleProxy,
        address[] memory factoriesArray,
        address[] memory knowledgeBasesArray,
        address ensController
    ) public {
        _doubleProxy = doubleProxy;
        _factories = factoriesArray;
        _knowledgeBases = knowledgeBasesArray;
        _ensController = ensController;
    }

    function factories() public view override returns(address[] memory) {
        return _factories;
    }

    function factory() public view override returns(address) {
        return _factories[_factories.length - 1];
    }

    function knowledgeBases() public view override returns(address[] memory) {
        return _knowledgeBases;
    }

    function knowledgeBase() public view override returns(address) {
        return _knowledgeBases[_knowledgeBases.length - 1];
    }

    modifier byDFO virtual {
        require(_isFromDFO(msg.sender), "Unauthorized Action!");
        _;
    }

    function _isFromDFO(address sender) private view returns(bool) {
        IMVDProxy proxy = IMVDProxy(IDoubleProxy(_doubleProxy).proxy());
        if(IMVDFunctionalitiesManager(proxy.getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(sender)) {
            return true;
        }
        return proxy.getMVDWalletAddress() == sender;
    }

    function doubleProxy() public view override returns (address) {
        return _doubleProxy;
    }

    function setDoubleProxy(address newDoubleProxy) public override byDFO {
        _doubleProxy = newDoubleProxy;
        for(uint256 i = 0; i < _factories.length; i++) {
            IEthItemOrchestratorDependantElement element = IEthItemOrchestratorDependantElement(_factories[i]);
            if(element.supportsInterface(this.setDoubleProxy.selector)) {
                element.setDoubleProxy(_doubleProxy);
            }
        }
        for(uint256 i = 0; i < _knowledgeBases.length; i++) {
            IEthItemOrchestratorDependantElement element = IEthItemOrchestratorDependantElement(_knowledgeBases[i]);
            if(element.supportsInterface(this.setDoubleProxy.selector)) {
                element.setDoubleProxy(_doubleProxy);
            }
        }
        if(_ensController != address(0)) {
            IEthItemOrchestratorDependantElement element = IEthItemOrchestratorDependantElement(_ensController);
            if(element.supportsInterface(this.setDoubleProxy.selector)) {
                element.setDoubleProxy(_doubleProxy);
            }
        }
    }

    function ENSController() public override view returns (address) {
        return _ensController;
    }

    function setENSController(address newEnsController) public override byDFO {
        if(newEnsController != address(0)) {
            require(IEthItemOrchestratorDependantElement(newEnsController).doubleProxy() == _doubleProxy, "Wrong Double Proxy");
        }
        _ensController = newEnsController;
    }

    function transferENS(address receiver, bytes32 domainNode, uint256 domainId, bool reclaimFirst, bool safeTransferFrom, bytes memory payload) public override byDFO {
        IENSController(_ensController).transfer(receiver, domainNode, domainId, reclaimFirst, safeTransferFrom, payload);
    }

    function setMintFeePercentage(uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator) public override byDFO {
        for(uint256 i = 0; i < _factories.length; i++) {
            IEthItemFactory element = IEthItemFactory(_factories[i]);
            if(element.supportsInterface(this.setMintFeePercentage.selector)) {
                element.setMintFeePercentage(mintFeePercentageNumerator, mintFeePercentageDenominator);
            }
        }
    }

    function setBurnFeePercentage(uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) public override byDFO {
        for(uint256 i = 0; i < _factories.length; i++) {
            IEthItemFactory element = IEthItemFactory(_factories[i]);
            if(element.supportsInterface(this.setBurnFeePercentage.selector)) {
                element.setBurnFeePercentage(burnFeePercentageNumerator, burnFeePercentageDenominator);
            }
        }
    }

    function setFactory(address newFactory) public override byDFO {
        require(IEthItemOrchestratorDependantElement(newFactory).doubleProxy() == _doubleProxy, "Wrong Double Proxy");
        _factories.push(newFactory);
    }

    function setKnowledgeBase(address newKnowledgeBase) public override byDFO {
        require(IEthItemOrchestratorDependantElement(newKnowledgeBase).doubleProxy() == _doubleProxy, "Wrong Double Proxy");
        _knowledgeBases.push(newKnowledgeBase);
    }

    function setEthItemInteroperableInterfaceModel(address ethItemInteroperableInterfaceModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setEthItemInteroperableInterfaceModel.selector)) {
            element.setEthItemInteroperableInterfaceModel(ethItemInteroperableInterfaceModelAddress);
        }
    }

    function setNativeModel(address nativeModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setNativeModel.selector)) {
            element.setNativeModel(nativeModelAddress);
        }
    }

    function setERC1155WrapperModel(address erc1155WrapperModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setERC1155WrapperModel.selector)) {
            element.setERC1155WrapperModel(erc1155WrapperModelAddress);
        }
    }

    function setERC20WrapperModel(address erc20WrapperModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setERC20WrapperModel.selector)) {
            element.setERC20WrapperModel(erc20WrapperModelAddress);
        }
    }

    function setERC721WrapperModel(address erc721WrapperModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setERC721WrapperModel.selector)) {
            element.setERC721WrapperModel(erc721WrapperModelAddress);
        }
    }

    function onERC1155Received(
        address,
        address owner,
        uint256 objectId,
        uint256 amount,
        bytes memory
    ) public virtual override returns (bytes4) {
        address ethItem = _getOrCreateERC1155Wrapper(msg.sender, objectId);
        IEthItemMainInterface(msg.sender).safeTransferFrom(address(this), ethItem, objectId, amount, "");
        IERC20 item = IEthItemMainInterface(ethItem).asInteroperable(objectId);
        item.transfer(owner, item.balanceOf(address(this)));
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address owner,
        uint256[] memory objectIds,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override returns (bytes4) {
        address ethItem = _getOrCreateERC1155Wrapper(msg.sender, objectIds[0]);
        IEthItemMainInterface(msg.sender).safeBatchTransferFrom(address(this), ethItem, objectIds, amounts, "");
        for(uint256 i = 0; i < objectIds.length; i++) {
            IERC20 item = IEthItemMainInterface(ethItem).asInteroperable(objectIds[i]);
            item.transfer(owner, item.balanceOf(address(this)));
        }
        return this.onERC1155BatchReceived.selector;
    }

    function _getOrCreateERC1155Wrapper(address source, uint256 objectId) private returns(address ethItem) {
        IEthItemFactory currentFactory = IEthItemFactory(factory());
        (,uint256 version) = currentFactory.erc1155WrapperModel();
        ethItem = _checkEthItem(msg.sender, version);
        if(ethItem == address(0)) {
            IKnowledgeBase currentKnowledgeBase = IKnowledgeBase(knowledgeBase());
            currentKnowledgeBase.setEthItem(ethItem = _createERC1155Wrapper(currentFactory, source, objectId));
            currentKnowledgeBase.setWrapped(source, ethItem);
        }
    }

    function _createERC1155Wrapper(IEthItemFactory currentFactory, address source, uint256 objectId) private returns(address ethItem) {
        (string memory name, string memory symbol) = _extractNameAndSymbol(source);
        (bool supportsSpecificName, bool supportsSpecificSymbol, bool supportsSpecificDecimals) = _extractSpecificData(source, objectId);
        bytes memory modelInitPayload = abi.encodeWithSignature("init(address,string,string,bool,bool,bool)", source, name, symbol, supportsSpecificName, supportsSpecificSymbol, supportsSpecificDecimals);
        (ethItem,) = currentFactory.createWrappedERC1155(modelInitPayload);
    }

    function _extractNameAndSymbol(address source) private view returns(string memory name, string memory symbol) {
        IEthItemMainInterface nft = IEthItemMainInterface(source);
        try nft.name() returns(string memory n) {
            name = n;
        } catch {
        }
        try nft.symbol() returns(string memory s) {
            symbol = s;
        } catch {
        }
        if(keccak256(bytes(name)) == keccak256("")) {
            name = _toString(source);
        }
        if(keccak256(bytes(symbol)) == keccak256("")) {
            symbol = _toString(source);
        }
    }

    function _extractSpecificData(address source, uint256 objectId) private view returns(bool supportsSpecificName, bool supportsSpecificSymbol, bool supportsSpecificDecimals) {
        IEthItemMainInterface nft = IEthItemMainInterface(source);
        try nft.name(objectId) returns(string memory value) {
            supportsSpecificName = keccak256(bytes(value)) != keccak256("");
        } catch {
        }
        try nft.symbol(objectId) returns(string memory value) {
            supportsSpecificSymbol = keccak256(bytes(value)) != keccak256("");
        } catch {
        }
        try nft.decimals(objectId) returns(uint256 value) {
            supportsSpecificDecimals = value > 1;
        } catch {
        }
    }

    function onERC721Received(
        address operator,
        address owner,
        uint256 objectId,
        bytes memory payload
    ) public virtual override returns (bytes4) {
        if(msg.sender == ENS_TOKEN_ADDRESS && keccak256(bytes("")) != keccak256(payload)) {
            require(_isFromDFO(operator), "Unauthorized Action");
            IERC721(msg.sender).safeTransferFrom(address(this), _ensController, objectId, payload);
            return this.onERC721Received.selector;
        }
        IEthItemFactory currentFactory = IEthItemFactory(factory());
        (,uint256 version) = currentFactory.erc721WrapperModel();
        address ethItem = _checkEthItem(msg.sender, version);
        if(ethItem == address(0)) {
            IKnowledgeBase currentKnowledgeBase = IKnowledgeBase(knowledgeBase());
            currentKnowledgeBase.setEthItem(ethItem = _createERC721Wrapper(currentFactory, msg.sender));
            currentKnowledgeBase.setWrapped(msg.sender, ethItem);
        }
        IERC721(msg.sender).safeTransferFrom(address(this), ethItem, objectId, "");
        IERC20 item = IEthItemMainInterface(ethItem).asInteroperable(objectId);
        item.transfer(owner, item.balanceOf(address(this)));
        return this.onERC721Received.selector;
    }

    function _checkEthItem(address source, uint256 version) private view returns(address ethItem) {
        for(uint256 i = 0; i < _knowledgeBases.length; i++) {
            ethItem = IKnowledgeBase(_knowledgeBases[i]).wrapper(source, version);
            if(ethItem != address(0)) {
                return ethItem;
            }
        }
    }

    function _createERC721Wrapper(IEthItemFactory currentFactory, address source) private returns(address ethItem) {
        (string memory name, string memory symbol) = _extractNameAndSymbol(source);
        bytes memory modelInitPayload = abi.encodeWithSignature("init(address,string,string)", source, name, symbol);
        (ethItem,) = currentFactory.createWrappedERC721(modelInitPayload);
    }

    function createNative(bytes memory modelInitCallPayload, string memory ens) public override
        returns (address newNativeAddress, bytes memory modelInitCallResponse) {
        (newNativeAddress, modelInitCallResponse) = IEthItemFactory(factory()).createNative(modelInitCallPayload);
        IKnowledgeBase(knowledgeBase()).setEthItem(newNativeAddress);
        if(_ensController != address(0)) {
            IENSController(_ensController).attachENS(newNativeAddress, ens);
        }
    }

    function createERC20Wrapper(bytes memory modelInitPayload) public override byDFO
        returns (address newEthItemAddress, bytes memory modelInitCallResponse) {
        (newEthItemAddress, modelInitCallResponse) = IEthItemFactory(factory()).createWrappedERC20(modelInitPayload);
        IKnowledgeBase currentKnowledgeBase = IKnowledgeBase(knowledgeBase());
        currentKnowledgeBase.setEthItem(newEthItemAddress);
        currentKnowledgeBase.setERC20Wrapper(newEthItemAddress);
    }

    function _toString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}