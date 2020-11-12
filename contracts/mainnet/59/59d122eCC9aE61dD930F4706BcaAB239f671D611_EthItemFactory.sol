// File: @openzeppelin\contracts\introspection\IERC165.sol

// SPDX-License-Identifier: MIT

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
    function ethItemERC20WrapperModel() external view returns (address ethItemERC20WrapperModelAddress);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the EthItemERC20Wrappers (please see the eth-item-token-standard for further information).
     * It can be done only by the Factory controller
     */
    function setEthItemERC20WrapperModel(address ethItemERC20WrapperModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the ERC1155 NFT-Based EthItems.
     * Every EthItem will have its own address, but the code will be cloned from this one.
     */
    function erc1155Model() external view returns (address erc1155ModelAddress, uint256 erc1155ModelVersion);

    /**
     * @dev SET - The address of the ERC1155 NFT-Based EthItem model.
     * It can be done only by the Factory controller
     */
    function setERC1155Model(address erc1155ModelAddress) external;

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
     * It raises the 'NewERC1155Created' event.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createERC1155(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewERC1155Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC1155 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC1155Created' event.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC1155(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC1155Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC20 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC20Created' event.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC20(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC20Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC721 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC721Created' event.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC721(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC721Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);
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


interface IERC20Data is IBaseTokenData {
    function decimals() external view returns (uint256);
}

// File: node_modules\eth-item-token-standard\IERC20NFTWrapper.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IERC20NFTWrapper is IERC20, IERC20Data {

    function init(uint256 objectId, string memory name, string memory symbol, uint256 decimals) external;

    function mainWrapper() external view returns (address);

    function objectId() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;
}

// File: eth-item-token-standard\IEthItem.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;






interface IEthItem is IERC1155, IERC1155Views, IBaseTokenData {

    function init(
        address eRC20NFTWrapperModel,
        string calldata name,
        string calldata symbol
    ) external;

    function toERC20WrapperAmount(uint256 objectId, uint256 ethItemAmount) external view returns (uint256 erc20WrapperAmount);

    function toEthItemAmount(uint256 objectId, uint256 erc20WrapperAmount) external view returns (uint256 ethItemAmount);

    function erc20NFTWrapperModel() external view returns (address);

    function asERC20(uint256 objectId) external view returns (IERC20NFTWrapper);

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

    event Mint(uint256 objectId, address tokenAddress, uint256 amount);
}

// File: models\common\IEthItemModelBase.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev This interface contains the commonn data provided by all the EthItem models
 */
interface IEthItemModelBase is IEthItem {

    /**
     * @dev Contract Initialization, the caller of this method should be a Contract containing the logic to provide the EthItemERC20WrapperModel to be used to create ERC20-based objectIds
     * @param name the chosen name for this NFT
     * @param symbol the chosen symbol (Ticker) for this NFT
     */
    function init(string calldata name, string calldata symbol) external;

    /**
     * @return modelVersionNumber The version number of the Model, it should be progressive
     */
    function modelVersion() external pure returns(uint256 modelVersionNumber);

    /**
     * @return factoryAddress the address of the Contract which initialized this EthItem
     */
    function factory() external view returns(address factoryAddress);
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

// File: orchestrator\EthItemOrchestratorDependantElement.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



abstract contract EthItemOrchestratorDependantElement is IEthItemOrchestratorDependantElement, ERC165 {

    string internal constant ETHITEM_ORCHESTRATOR_AUTHORIZED_KEY_PREFIX = "ehtitem.orchestrator.authorized";

    address internal _doubleProxy;

    constructor(address doubleProxy) public {
        _doubleProxy = doubleProxy;
        _registerInterfaces();
        _registerSpecificInterfaces();
    }

    function _registerInterfaces() internal {
        _registerInterface(this.setDoubleProxy.selector);
    }

    function _registerSpecificInterfaces() internal virtual;

    modifier byOrchestrator virtual {
        require(isAuthorizedOrchestrator(msg.sender), "Unauthorized Action!");
        _;
    }

    function doubleProxy() public view override returns(address) {
        return _doubleProxy;
    }

    function setDoubleProxy(address newDoubleProxy) public override byOrchestrator {
        _doubleProxy = newDoubleProxy;
    }

    function isAuthorizedOrchestrator(address operator) public view override returns(bool) {
        return IStateHolder(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getStateHolderAddress()).getBool(_toStateHolderKey(ETHITEM_ORCHESTRATOR_AUTHORIZED_KEY_PREFIX, _toString(operator)));
    }

    function _toStateHolderKey(string memory a, string memory b) internal pure returns(string memory) {
        return _toLowerCase(string(abi.encodePacked(a, ".", b)));
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

    function _toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }
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
    function getBool(string calldata varName) external view returns (bool);
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: factory\EthItemFactory.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;




contract EthItemFactory is IEthItemFactory, EthItemOrchestratorDependantElement {

    uint256[] private _mintFeePercentage;
    uint256[] private _burnFeePercentage;
    address private _ethItemERC20WrapperModelAddress;
    address private _erc1155ModelAddress;
    address private _erc1155WrapperModelAddress;
    address private _erc721WrapperModelAddress;
    address private _erc20WrapperModelAddress;

    constructor(
        address doubleProxy,
        address ethItemERC20WrapperModelAddress,
        address erc1155ModelAddress,
        address erc1155WrapperModelAddress,
        address erc721WrapperModelAddress,
        address erc20WrapperModelAddress,
        uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator,
        uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) public EthItemOrchestratorDependantElement(doubleProxy) {
        _ethItemERC20WrapperModelAddress = ethItemERC20WrapperModelAddress;
        _erc1155ModelAddress = erc1155ModelAddress;
        _erc1155WrapperModelAddress = erc1155WrapperModelAddress;
        _erc721WrapperModelAddress = erc721WrapperModelAddress;
        _erc20WrapperModelAddress = erc20WrapperModelAddress;
        _mintFeePercentage = new uint256[](2);
        _mintFeePercentage[0] = mintFeePercentageNumerator;
        _mintFeePercentage[1] = mintFeePercentageDenominator;
        _burnFeePercentage = new uint256[](2);
        _burnFeePercentage[0] = burnFeePercentageNumerator;
        _burnFeePercentage[1] = burnFeePercentageDenominator;
    }

    function _registerSpecificInterfaces() internal virtual override {
        _registerInterface(this.setEthItemERC20WrapperModel.selector);
        _registerInterface(this.setERC1155Model.selector);
        _registerInterface(this.setERC1155WrapperModel.selector);
        _registerInterface(this.setERC20WrapperModel.selector);
        _registerInterface(this.setERC721WrapperModel.selector);
        _registerInterface(this.setMintFeePercentage.selector);
        _registerInterface(this.setBurnFeePercentage.selector);
        _registerInterface(this.createERC1155.selector);
        _registerInterface(this.createWrappedERC1155.selector);
        _registerInterface(this.createWrappedERC20.selector);
        _registerInterface(this.createWrappedERC721.selector);
    }

    function ethItemERC20WrapperModel() public override view returns (address ethItemERC20WrapperModelAddress) {
        return _ethItemERC20WrapperModelAddress;
    }

    function setEthItemERC20WrapperModel(address ethItemERC20WrapperModelAddress) public override byOrchestrator {
        _ethItemERC20WrapperModelAddress = ethItemERC20WrapperModelAddress;
    }

    function erc1155Model() public override view returns (address erc1155ModelAddress, uint256 erc1155ModelVersion) {
        return (_erc1155ModelAddress, IEthItemModelBase(_erc1155ModelAddress).modelVersion());
    }

    function setERC1155Model(address erc1155ModelAddress) public override byOrchestrator {
        _erc1155ModelAddress = erc1155ModelAddress;
    }

    function erc1155WrapperModel() public override view returns (address erc1155WrapperModelAddress, uint256 erc1155WrapperModelVersion) {
        return (_erc1155WrapperModelAddress, IEthItemModelBase(_erc1155WrapperModelAddress).modelVersion());
    }

    function setERC1155WrapperModel(address erc1155WrapperModelAddress) public override byOrchestrator {
        _erc1155WrapperModelAddress = erc1155WrapperModelAddress;
    }

    function erc20WrapperModel() public override view returns (address erc20WrapperModelAddress, uint256 erc20WrapperModelVersion) {
        return (_erc20WrapperModelAddress, IEthItemModelBase(_erc20WrapperModelAddress).modelVersion());
    }

    function setERC20WrapperModel(address erc20WrapperModelAddress) public override byOrchestrator {
        _erc20WrapperModelAddress = erc20WrapperModelAddress;
    }

    function erc721WrapperModel() public override view returns (address erc721WrapperModelAddress, uint256 erc721WrapperModelVersion) {
        return (_erc721WrapperModelAddress, IEthItemModelBase(_erc721WrapperModelAddress).modelVersion());
    }

    function setERC721WrapperModel(address erc721WrapperModelAddress) public override byOrchestrator {
        _erc721WrapperModelAddress = erc721WrapperModelAddress;
    }

    function mintFeePercentage() public override view returns (uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator) {
        return (_mintFeePercentage[0], _mintFeePercentage[1]);
    }

    function setMintFeePercentage(uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator) public override byOrchestrator {
        _mintFeePercentage[0] = mintFeePercentageNumerator;
        _mintFeePercentage[1] = mintFeePercentageDenominator;
    }

    function calculateMintFee(uint256 amountInDecimals) public override view returns (uint256 mintFee, address dfoWalletAddress) {
        if(_mintFeePercentage[0] == 0 || _mintFeePercentage[1] == 0) {
            return (0, address(0));
        }
        mintFee = ((amountInDecimals * _mintFeePercentage[0]) / _mintFeePercentage[1]);
        require(mintFee > 0, "Inhexistent mint fee, amount too low.");
        dfoWalletAddress = IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress();
    }

    function burnFeePercentage() public override view returns (uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) {
        return (_burnFeePercentage[0], _burnFeePercentage[1]);
    }

    function setBurnFeePercentage(uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) public override byOrchestrator {
        _burnFeePercentage[0] = burnFeePercentageNumerator;
        _burnFeePercentage[1] = burnFeePercentageDenominator;
    }

    function calculateBurnFee(uint256 amountInDecimals) public override view returns (uint256 burnFee, address dfoWalletAddress) {
        if(_burnFeePercentage[0] == 0 || _burnFeePercentage[1] == 0) {
            return (0, address(0));
        }
        burnFee = ((amountInDecimals * _burnFeePercentage[0]) / _burnFeePercentage[1]);
        require(burnFee > 0, "Inhexistent burn fee, amount too low.");
        dfoWalletAddress = IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress();
    }

    function createERC1155(bytes memory modelInitCallPayload) public override byOrchestrator returns (address newNFT1155Address, bytes memory modelInitCallResponse) {
        bool modelInitCallResult = false;
        (modelInitCallResult, modelInitCallResponse) = (newNFT1155Address = _clone(_erc1155ModelAddress)).call(modelInitCallPayload);
        require(modelInitCallResult, "Model Init call failed");
        emit NewERC1155Created(_erc1155ModelAddress, IEthItemModelBase(_erc1155ModelAddress).modelVersion(), newNFT1155Address, msg.sender);
    }

    function createWrappedERC1155(bytes memory modelInitCallPayload) public override byOrchestrator returns (address newNFT1155Address, bytes memory modelInitCallResponse) {
        bool modelInitCallResult = false;
        (modelInitCallResult, modelInitCallResponse) = (newNFT1155Address = _clone(_erc1155WrapperModelAddress)).call(modelInitCallPayload);
        require(modelInitCallResult, "Model Init call failed");
        emit NewWrappedERC1155Created(_erc1155WrapperModelAddress, IEthItemModelBase(_erc1155WrapperModelAddress).modelVersion(), newNFT1155Address, msg.sender);
    }

    function createWrappedERC20(bytes memory modelInitCallPayload) public override byOrchestrator returns (address newERC20Address, bytes memory modelInitCallResponse) {
        bool modelInitCallResult = false;
        (modelInitCallResult, modelInitCallResponse) = (newERC20Address = _clone(_erc20WrapperModelAddress)).call(modelInitCallPayload);
        require(modelInitCallResult, "Model Init call failed");
        emit NewWrappedERC20Created(_erc20WrapperModelAddress, IEthItemModelBase(_erc20WrapperModelAddress).modelVersion(), newERC20Address, msg.sender);
    }

    function createWrappedERC721(bytes memory modelInitCallPayload) public override byOrchestrator returns (address newERC721Address, bytes memory modelInitCallResponse) {
        bool modelInitCallResult = false;
        (modelInitCallResult, modelInitCallResponse) = (newERC721Address = _clone(_erc721WrapperModelAddress)).call(modelInitCallPayload);
        require(modelInitCallResult, "Model Init call failed");
        emit NewWrappedERC721Created(_erc721WrapperModelAddress, IEthItemModelBase(_erc721WrapperModelAddress).modelVersion(), newERC721Address, msg.sender);
    }

    function _clone(address original) internal returns (address copy) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(original, 0x1000000000000000000)
                )
            )
            copy := create(0, 0, 32)
            switch extcodesize(copy)
                case 0 {
                    invalid()
                }
        }
    }
}