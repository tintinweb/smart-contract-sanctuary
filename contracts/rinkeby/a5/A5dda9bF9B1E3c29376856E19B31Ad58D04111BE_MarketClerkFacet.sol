// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../../interfaces/IMarketClerk.sol";
import "../../diamond/DiamondLib.sol";
import "../MarketControllerBase.sol";
import "../MarketControllerLib.sol";

/**
 * @title MarketClerkFacet
 *
 * @notice Manages consignments for the Seen.Haus contract suite.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketClerkFacet is IMarketClerk, MarketControllerBase, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized() {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.clerkFacet, "Initializer: contract is already initialized");
        mci.clerkFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register IMarketClerk,
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IMarketClerk).interfaceId);
        DiamondLib.addSupportedInterface(type(IERC1155ReceiverUpgradeable).interfaceId);
        DiamondLib.addSupportedInterface(type(IERC721ReceiverUpgradeable).interfaceId);
    }

    /**
     * @notice The nextConsignment getter
     * @dev does not increment counter
     */
    function getNextConsignment()
    external
    override
    view
    returns (uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.nextConsignment;
    }

    /**
     * @notice The consignment getter
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return consignment - the consignment struct
     */
    function getConsignment(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns (Consignment memory consignment)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        consignment = mcs.consignments[_consignmentId];
    }

    /**
     * @notice Get the remaining supply of the given consignment.
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return  uint256 - the remaining supply held by the MarketController
     */
    function getSupply(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns(uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        Consignment storage consignment = mcs.consignments[_consignmentId];
        return consignment.multiToken
            ? IERC1155Upgradeable(consignment.tokenAddress).balanceOf(address(this), consignment.tokenId)
            : consignment.released ? 0 : 1;

    }

    /**
     * @notice Is the caller the consignor of the given consignment?
     *
     * Reverts if consignment doesn't exist
     *
     * @param _account - the _account to check
     * @param _consignmentId - the id of the consignment
     * @return  bool - true if caller is consignor
     */
    function isConsignor(uint256 _consignmentId, address _account)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns(bool)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.consignors[_consignmentId] == _account;
    }

    /**
     * @notice Registers a new consignment for sale or auction.
     *
     * Emits a ConsignmentRegistered event.
     *
     * Reverts if:
     *  - Token is multi-token and supply hasn't been transferred to this contract
     *  - Token is not multi-token and contract doesn't implement ERC-721
     *  - Token is not multi-token and this contract is not owner of tokenId
     *  - Token is not multi-token and the supply is not 1
     *
     * @param _market - the market for the consignment. See {SeenTypes.Market}
     * @param _consignor - the address executing the consignment transaction
     * @param _seller - the seller of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _supply - the amount of the token being consigned
     *
     * @return consignment - the registered consignment
     */
    function registerConsignment(
        Market _market,
        address _consignor,
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _supply
    )
    external
    override
    onlyRole(MARKET_HANDLER)
    returns (Consignment memory consignment)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Check whether this is a multi token NFT
        bool multiToken = IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId);

        // Ensure consigned asset has been transferred to this this contract
        if (multiToken)  {

            // Ensure the consigned token supply has been transferred to this contract
            require( IERC1155Upgradeable(_tokenAddress).balanceOf(address(this), _tokenId) == _supply, "MarketController must own token" );

        } else {

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Ensure the consigned token has been transferred to this contract
            require(IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId) == (address(this)), "MarketController must own token");

            // Ensure the supply is set to 1
            require(_supply == 1, "Invalid supply for token");

        }

        // Get the id for the new consignment and increment counter
        uint256 id = mcs.nextConsignment++;

        // Create and store the consignment
        consignment = Consignment(
            _market,
            MarketHandler.Unhandled,
            _seller,
            _tokenAddress,
            _tokenId,
            _supply,
            id,
            multiToken,
            false
        );
        mcs.consignments[id] = consignment;

        // Associate the consignor
        mcs.consignors[id] = _consignor;

        // Notify listeners of state change
        emit ConsignmentRegistered(_consignor, _seller , consignment);
    }

    /**
     * @notice Update consignment to indicate it has been marketed
     *
     * Emits a ConsignmentMarketed event.
     *
     * Reverts if:
     *  - _marketHandler of value Unhandled is passed into this function. See {SeenTypes.MarketHandler}.
     *  - consignment has already been marketed (has a marketHandler other than Unhandled). See {SeenTypes.MarketHandler}.
     *
     * @param _consignmentId - the id of the consignment
     */
    function marketConsignment(uint256 _consignmentId, MarketHandler _marketHandler)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        require(_marketHandler != MarketHandler.Unhandled, "Consignment can't be marketed without a valid handler");

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // A consignment can only be marketed once, should currently be Unhandled
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment has already been marketed");

        // Update the consignment
        consignment.marketHandler = _marketHandler;

        // Consignor address
        address consignor = mcs.consignors[_consignmentId];

        // Notify listeners of state change
        emit ConsignmentMarketed(consignor, consignment.seller, consignment.id);
    }

    /**
     * @notice Release an amount of the consigned token balance to a given address
     *
     * Emits a ConsignmentReleased event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *  - consignment has already been released
     *  - consignment is multi-token and supply is not adequate
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of the consigned supply (must be 1 for ERC721 tokens)
     * @param _releaseTo - the address to transfer the consigned token balance to
     */
    function releaseConsignment(uint256 _consignmentId, uint256 _amount, address _releaseTo)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Ensure the consignment has not been released
        require(!consignment.released, "Consigned token has already been released");

        // Handle transfer, marking of consignment
        if (consignment.multiToken) {

            // Get the current supply
            uint256 supply = IERC1155Upgradeable(consignment.tokenAddress).balanceOf(address(this), consignment.tokenId);

            // Ensure this contract holds enough supply
            require(supply >= _amount, "Consigned token supply less than amount");

            // Mark the consignment when the entire supply has been released
            if (supply == _amount) consignment.released = true;

            // Transfer a balance of the token from the MarketController to the recipient
            IERC1155Upgradeable(consignment.tokenAddress).safeTransferFrom(
                address(this),
                _releaseTo,
                consignment.tokenId,
                _amount,
                new bytes(0x0)
            );

        } else {

            // Mark the single-token consignment released
            consignment.released = true;

            // Transfer the token from the MarketController to the recipient
            IERC721Upgradeable(consignment.tokenAddress).safeTransferFrom(
                address(this),
                _releaseTo,
                consignment.tokenId
            );

        }

        // Notify watchers about state change
        emit ConsignmentReleased(consignment.id, _amount, _releaseTo);

    }

    /**
     * @notice Set the type of Escrow Ticketer to be used for a consignment
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentTicketerSet event.
     *
     * Reverts if consignment doesn't exist     *
     *
     * @param _consignmentId - the id of the consignment
     * @param _ticketerType - the type of ticketer to use. See: {SeenTypes.Ticketer}
     */
    function setConsignmentTicketer(uint256 _consignmentId, Ticketer _ticketerType)
    external
    override
    onlyRole(ESCROW_AGENT)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Set the ticketer for the consignment if not different
        if (_ticketerType != mcs.consignmentTicketers[_consignmentId]) {

            // Set the ticketer for the consignment
            mcs.consignmentTicketers[_consignmentId] = _ticketerType;

            // Notify listeners of state change
            emit ConsignmentTicketerChanged(_consignmentId, _ticketerType);

        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "../domain/SeenTypes.sol";

/**
 * @title IMarketClerk
 *
 * @notice Manages consignments for the Seen.Haus contract suite.
 *
 * The ERC-165 identifier for this interface is: 0xdab9a74c
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IMarketClerk is IERC1155ReceiverUpgradeable, IERC721ReceiverUpgradeable {

    /// Events
    event ConsignmentTicketerChanged(uint256 consignmentId, SeenTypes.Ticketer indexed ticketerType);
    event ConsignmentRegistered(address indexed consignor, address indexed seller, SeenTypes.Consignment consignment);
    event ConsignmentMarketed(address indexed consignor, address indexed seller, uint256 indexed consignmentId);
    event ConsignmentReleased(uint256 indexed consignmentId, uint256 amount, address releasedTo);

    /**
     * @notice The nextConsignment getter
     */
    function getNextConsignment() external view returns (uint256);

    /**
     * @notice The consignment getter
     */
    function getConsignment(uint256 _consignmentId) external view returns (SeenTypes.Consignment memory);

    /**
     * @notice Get the remaining supply of the given consignment.
     *
     * @param _consignmentId - the id of the consignment
     * @return uint256 - the remaining supply held by the MarketController
     */
    function getSupply(uint256 _consignmentId) external view returns(uint256);

    /**
     * @notice Is the caller the consignor of the given consignment?
     *
     * @param _account - the _account to check
     * @param _consignmentId - the id of the consignment
     * @return  bool - true if caller is consignor
     */
    function isConsignor(uint256 _consignmentId, address _account) external view returns(bool);

    /**
     * @notice Registers a new consignment for sale or auction.
     *
     * Emits a ConsignmentRegistered event.
     *
     * @param _market - the market for the consignment. See {SeenTypes.Market}
     * @param _consignor - the address executing the consignment transaction
     * @param _seller - the seller of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _supply - the amount of the token being consigned
     *
     * @return Consignment - the registered consignment
     */
    function registerConsignment(
        SeenTypes.Market _market,
        address _consignor,
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _supply
    )
    external
    returns(SeenTypes.Consignment memory);

    /**
      * @notice Update consignment to indicate it has been marketed
      *
      * Emits a ConsignmentMarketed event.
      *
      * Reverts if consignment has already been marketed.
      * A consignment is considered as marketed if it has a marketHandler other than Unhandled. See: {SeenTypes.MarketHandler}
      *
      * @param _consignmentId - the id of the consignment
      */
    function marketConsignment(uint256 _consignmentId, SeenTypes.MarketHandler _marketHandler) external;

    /**
     * @notice Release the consigned item to a given address
     *
     * Emits a ConsignmentReleased event.
     *
     * Reverts if caller is does not have MARKET_HANDLER role.
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of the consigned supply to release
     * @param _releaseTo - the address to transfer the consigned token balance to
     */
    function releaseConsignment(uint256 _consignmentId, uint256 _amount, address _releaseTo) external;

    /**
     * @notice Set the type of Escrow Ticketer to be used for a consignment
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentTicketerSet event.
     * Reverts if consignment is not registered.
     *
     * @param _consignmentId - the id of the consignment
     * @param _ticketerType - the type of ticketer to use. See: {SeenTypes.Ticketer}
     */
    function setConsignmentTicketer(uint256 _consignmentId, SeenTypes.Ticketer _ticketerType) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactor/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {

        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;

        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;

        // The number of function selectors in selectorSlots
        uint16 selectorCount;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;

        // The Seen.Haus AccessController
        IAccessControlUpgradeable accessController;

    }

    /**
     * @notice Get the Diamond storage slot
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Add a supported interface to the Diamond
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId] || false;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./MarketControllerLib.sol";
import "../diamond/DiamondLib.sol";
import "../../domain/SeenTypes.sol";
import "../../domain/SeenConstants.sol";

/**
 * @title MarketControllerBase
 *
 * @notice Provides domain and common modifiers to MarketController facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
abstract contract MarketControllerBase is SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the consignment exists
     *
     * Reverts if the consignment does not exist
     */
    modifier consignmentExists(uint256 _consignmentId) {

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Make sure the consignment exists
        require(_consignmentId < mcs.nextConsignment, "Consignment does not exist");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender), "Access denied, caller doesn't have role");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../domain/SeenTypes.sol";

/**
 * @title MarketControllerLib
 *
 * @dev Provides access to the the MarketController Storage and Intializer slots for MarketController facets
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library MarketControllerLib {

    bytes32 constant MARKET_CONTROLLER_STORAGE_POSITION = keccak256("seen.haus.market.controller.storage");
    bytes32 constant MARKET_CONTROLLER_INITIALIZERS_POSITION = keccak256("seen.haus.market.controller.initializers");

    struct MarketControllerStorage {

        // the address of the Seen.Haus NFT contract
        address nft;

        // the address of the xSEEN ERC-20 Seen.Haus staking contract
        address payable staking;

        // the address of the Seen.Haus multi-sig wallet
        address payable multisig;

        // address of the Seen.Haus lots-based escrow ticketing contract
        address lotsTicketer;

        // address of the Seen.Haus items-based escrow ticketing contract
        address itemsTicketer;

        // the default escrow ticketer type to use for physical consignments unless overridden with setConsignmentTicketer
        SeenTypes.Ticketer defaultTicketerType;

        // the minimum amount of xSEEN ERC-20 a caller must hold to participate in VIP events
        uint256 vipStakerAmount;

        // the percentage that will be taken as a fee from the net of a Seen.Haus sale or auction (after royalties)
        uint16 feePercentage;         // 1.75% = 175, 100% = 10000

        // the maximum percentage of a Seen.Haus sale or auction that will be paid as a royalty
        uint16 maxRoyaltyPercentage;  // 1.75% = 175, 100% = 10000

        // the minimum percentage a Seen.Haus auction bid must be above the previous bid to prevail
        uint16 outBidPercentage;      // 1.75% = 175, 100% = 10000

        // next consignment id
        uint256 nextConsignment;

        // consignment id => consignment
        mapping(uint256 => SeenTypes.Consignment) consignments;

        // consignmentId to consignor address
        mapping(uint256 => address) consignors;

        // consignment id => ticketer type
        mapping(uint256 => SeenTypes.Ticketer) consignmentTicketers;

    }

    struct MarketControllerInitializers {

        // MarketConfigFacet initialization state
        bool configFacet;

        // MarketClerkFacet initialization state
        bool clerkFacet;

    }

    function marketControllerStorage() internal pure returns (MarketControllerStorage storage mcs) {
        bytes32 position = MARKET_CONTROLLER_STORAGE_POSITION;
        assembly {
            mcs.slot := position
        }
    }

    function marketControllerInitializers() internal pure returns (MarketControllerInitializers storage mci) {
        bytes32 position = MARKET_CONTROLLER_INITIALIZERS_POSITION;
        assembly {
            mci.slot := position
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenTypes
 *
 * @notice Enums and structs used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenTypes {

    enum Market {
        Primary,
        Secondary
    }

    enum MarketHandler {
        Unhandled,
        Auction,
        Sale
    }

    enum Clock {
        Live,
        Trigger
    }

    enum Audience {
        Open,
        Staker,
        VipStaker
    }

    enum Outcome {
        Pending,
        Closed,
        Canceled
    }

    enum State {
        Pending,
        Running,
        Ended
    }

    enum Ticketer {
        Default,
        Lots,
        Items
    }

    struct Token {
        address payable creator;
        uint16 royaltyPercentage;
        bool isPhysical;
        uint256 id;
        uint256 supply;
        string uri;
    }

    struct Consignment {
        Market market;
        MarketHandler marketHandler;
        address payable seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 supply;
        uint256 id;
        bool multiToken;
        bool released;
    }

    struct Auction {
        address payable buyer;
        uint256 consignmentId;
        uint256 start;
        uint256 duration;
        uint256 reserve;
        uint256 bid;
        Clock clock;
        State state;
        Outcome outcome;
    }

    struct Sale {
        uint256 consignmentId;
        uint256 start;
        uint256 price;
        uint256 perTxCap;
        State state;
        Outcome outcome;
    }

    struct EscrowTicket {
        uint256 amount;
        uint256 consignmentId;
        uint256 id;
        string itemURI;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondCut
 *
 * @notice Diamond Facet management
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and
     * optionally execute a function with delegatecall
     *
     * _calldata is executed with delegatecall on _init
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title SeenConstants
 *
 * @notice Constants used by the Seen.Haus contract ecosystem.
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract SeenConstants {

    // Endpoint will serve dynamic metadata composed of ticket and ticketed item's info
    string internal constant ESCROW_TICKET_URI = "https://seen.haus/ticket/metadata/";

    // Access Control Roles
    bytes32 internal constant ADMIN = keccak256("ADMIN");                   // Deployer and any other admins as needed
    bytes32 internal constant SELLER = keccak256("SELLER");                 // Approved sellers amd Seen.Haus reps
    bytes32 internal constant MINTER = keccak256("MINTER");                 // Approved artists and Seen.Haus reps
    bytes32 internal constant ESCROW_AGENT = keccak256("ESCROW_AGENT");     // Seen.Haus Physical Item Escrow Agent
    bytes32 internal constant MARKET_HANDLER = keccak256("MARKET_HANDLER"); // Market Handler contracts
    bytes32 internal constant UPGRADER = keccak256("UPGRADER");             // Performs contract upgrades

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200,
    "details": {
      "yul": true
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}