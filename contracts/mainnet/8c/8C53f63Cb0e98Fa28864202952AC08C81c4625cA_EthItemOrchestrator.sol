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
    function setEthItemERC20WrapperModel(address ethItemERC20WrapperModelAddress) external;

    /**
     * @dev SET - The address of the ERC1155 NFT-Based EthItem model.
     * It can be done only through a Proposal in the Linked DFO
     */
    function setERC1155Model(address erc1155ModelAddress) external;

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

    function createERC1155(bytes calldata modelInitPayload)
        external
        returns (address newNFT1155Address, bytes memory modelInitCallResponse);
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

// File: knowledgeBase\IKnowledgeBase.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @title IKnowledgeBase
 * @dev This contract represents the Factory Used to deploy all the EthItems, keeping track of them.
 */
interface IKnowledgeBase is IEthItemOrchestratorDependantElement {

    function setEthItem(address ethItem) external;

    function isEthItem(address ethItem) external view returns(bool);

    function setWrapped(address wrappedAddress, address ethItem) external;

    function wrapper(address wrappedAddress, uint256 version) external returns (address ethItem);
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

// File: orchestrator\EthItemOrchestrator.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;





contract EthItemOrchestrator is IEthItemOrchestrator, ERC165 {

    address private _doubleProxy;
    address[] private _factories;
    address[] private _knowledgeBases;

    constructor(
        address doubleProxy,
        address[] memory factoriesArray,
        address[] memory knowledgeBasesArray
    ) public {
        _doubleProxy = doubleProxy;
        _factories = factoriesArray;
        _knowledgeBases = knowledgeBasesArray;
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
        require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized Action!");
        _;
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

    function setEthItemERC20WrapperModel(address ethItemERC20WrapperModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setEthItemERC20WrapperModel.selector)) {
            element.setEthItemERC20WrapperModel(ethItemERC20WrapperModelAddress);
        }
    }

    function setERC1155Model(address erc1155ModelAddress) public override byDFO {
        IEthItemFactory element = IEthItemFactory(factory());
        if(element.supportsInterface(this.setERC1155Model.selector)) {
            element.setERC1155Model(erc1155ModelAddress);
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
        address operator,
        address owner,
        uint256 objectId,
        uint256 amount,
        bytes memory
    ) public virtual override returns (bytes4) {
        IEthItemFactory element = IEthItemFactory(factory());
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address owner,
        uint256[] memory objectIds,
        uint256[] memory amounts,
        bytes memory payload
    ) public virtual override returns (bytes4) {
        for(uint256 i = 0; i < objectIds.length; i++) {
            onERC1155Received(operator, owner, objectIds[i], amounts[i], payload);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address operator,
        address owner,
        uint256 objectId,
        bytes memory payload
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function createERC1155(bytes memory modelInitCallPayload) public override
        returns (address newNFT1155Address, bytes memory modelInitCallResponse) {
        (newNFT1155Address, modelInitCallResponse) = IEthItemFactory(factory()).createERC1155(modelInitCallPayload);
        IKnowledgeBase(knowledgeBase()).setEthItem(newNFT1155Address);
    }
}