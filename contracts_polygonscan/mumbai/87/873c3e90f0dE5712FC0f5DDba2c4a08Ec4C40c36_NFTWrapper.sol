// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @dev Edit: Make ERC-721 and ERC-1155 receiver.
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Token interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract NFTWrapper is ERC721Holder, ERC1155Holder {
    /// @dev The state of the underlying ERC 721 token, if any.
    struct ERC721Wrapped {
        address baseToken;
        address source;
        uint256 tokenId;
    }

    /// @dev The state of the underlying ERC 20 token, if any.
    struct ERC20Wrapped {
        address baseToken;
        address source;
        uint256 shares;
        uint256 underlyingTokenAmount;
    }

    /// @dev Emitted when ERC 721 wrapped as an ERC 1155 token is minted.
    event ERC721WrappedToken(
        address indexed baseToken,
        address indexed creator,
        address indexed sourceOfUnderlying,
        uint256 tokenIdOfUnderlying,
        uint256 tokenId,
        string tokenURI
    );

    /// @dev Emitted when an underlying ERC 721 token is redeemed.
    event ERC721Redeemed(
        address indexed baseToken,
        address indexed redeemer,
        address indexed sourceOfUnderlying,
        uint256 tokenIdOfUnderlying,
        uint256 tokenId
    );

    /// @dev Emitted when ERC 20 wrapped as an ERC 1155 token is minted.
    event ERC20WrappedToken(
        address indexed baseToken,
        address indexed creator,
        address indexed sourceOfUnderlying,
        uint256 totalAmountOfUnderlying,
        uint256 shares,
        uint256 tokenId,
        string tokenURI
    );

    /// @dev Emitted when an underlying ERC 20 token is redeemed.
    event ERC20Redeemed(
        address indexed baseToken,
        address indexed redeemer,
        address indexed sourceOfUnderlying,
        uint256 tokenId,
        uint256 tokenAmountReceived,
        uint256 sharesRedeemed
    );

    /// @dev NFT tokenId => state of underlying ERC721 token.
    mapping(address => mapping(uint256 => ERC721Wrapped)) public erc721WrappedTokens;

    /// @dev NFT tokenId => state of underlying ERC20 token.
    mapping(address => mapping(uint256 => ERC20Wrapped)) public erc20WrappedTokens;

    constructor() {}

    /// @dev Wraps an ERC721 NFT as an ERC1155 NFT.
    function wrapERC721(
        uint256 startTokenId,
        address _tokenCreator,
        address[] calldata _nftContracts,
        uint256[] memory _tokenIds,
        string[] calldata _nftURIs
    )
        external
        returns (
            uint256[] memory tokenIds,
            uint256[] memory tokenAmountsToMint,
            uint256 endTokenId
        )
    {
        require(
            _nftContracts.length == _tokenIds.length && _nftContracts.length == _nftURIs.length,
            "NFTWrapper: Unequal number of configs provided."
        );

        address baseToken = msg.sender;

        bool isOwnerOfAll;
        bool isApprovedToTransferAll;

        // Get tokenId
        endTokenId = startTokenId;
        tokenIds = new uint256[](_nftContracts.length);
        tokenAmountsToMint = new uint256[](_nftContracts.length);

        for (uint256 i = 0; i < _nftContracts.length; i += 1) {
            // Check ownership
            isOwnerOfAll = IERC721(_nftContracts[i]).ownerOf(_tokenIds[i]) == _tokenCreator;
            // Check approval
            isApprovedToTransferAll =
                IERC721(_nftContracts[i]).getApproved(_tokenIds[i]) == address(this) ||
                IERC721(_nftContracts[i]).isApprovedForAll(_tokenCreator, address(this));

            // If owns NFT and approved to transfer.
            if (isOwnerOfAll && isApprovedToTransferAll) {
                // Transfer the NFT to this contract.
                IERC721(_nftContracts[i]).safeTransferFrom(_tokenCreator, address(this), _tokenIds[i]);

                // Map the native NFT tokenId to the underlying NFT
                erc721WrappedTokens[baseToken][endTokenId] = ERC721Wrapped({
                    baseToken: baseToken,
                    source: _nftContracts[i],
                    tokenId: _tokenIds[i]
                });

                // Update id
                tokenIds[i] = endTokenId;
                tokenAmountsToMint[i] = 1;
                endTokenId += 1;

                emit ERC721WrappedToken(
                    baseToken,
                    _tokenCreator,
                    _nftContracts[i],
                    _tokenIds[i],
                    endTokenId,
                    _nftURIs[i]
                );
            } else {
                break;
            }
        }

        require(isOwnerOfAll, "NFTWrapper: Only the owner of the NFT can wrap it.");
        require(isApprovedToTransferAll, "NFTWrapper: Must approve the contract to transfer the NFT.");
    }

    /// @dev Wraps ERC20 tokens as ERC1155 NFTs.
    function wrapERC20(
        uint256 startTokenId,
        address _tokenCreator,
        address[] calldata _tokenContracts,
        uint256[] memory _tokenAmounts,
        uint256[] memory _numOfNftsToMint,
        string[] calldata _nftURIs
    ) external returns (uint256[] memory tokenIds, uint256 endTokenId) {
        require(
            _tokenContracts.length == _tokenAmounts.length &&
                _tokenContracts.length == _numOfNftsToMint.length &&
                _tokenContracts.length == _nftURIs.length,
            "NFTWrapper: Unequal number of configs provided."
        );

        address baseToken = msg.sender;

        bool hasBalance;
        bool hasGivenAllowance;

        // Get tokenId
        endTokenId = startTokenId;
        tokenIds = new uint256[](_tokenContracts.length);

        for (uint256 i = 0; i < _tokenContracts.length; i += 1) {
            // Check balance
            hasBalance = IERC20(_tokenContracts[i]).balanceOf(_tokenCreator) >= _tokenAmounts[i];
            // Check allowance
            hasGivenAllowance = IERC20(_tokenContracts[i]).allowance(_tokenCreator, address(this)) >= _tokenAmounts[i];

            if (hasBalance && hasGivenAllowance) {
                require(
                    IERC20(_tokenContracts[i]).transferFrom(_tokenCreator, address(this), _tokenAmounts[i]),
                    "NFTWrapper: Failed to transfer ERC20 tokens."
                );

                // Store wrapped ERC20 token state.
                erc20WrappedTokens[baseToken][endTokenId] = ERC20Wrapped({
                    baseToken: baseToken,
                    source: _tokenContracts[i],
                    shares: _numOfNftsToMint[i],
                    underlyingTokenAmount: _tokenAmounts[i]
                });

                // Update id
                tokenIds[i] = endTokenId;
                endTokenId += 1;

                emit ERC20WrappedToken(
                    baseToken,
                    _tokenCreator,
                    _tokenContracts[i],
                    _tokenAmounts[i],
                    _numOfNftsToMint[i],
                    endTokenId,
                    _nftURIs[i]
                );
            } else {
                break;
            }
        }

        require(hasBalance, "NFTWrapper: Must own the amount of tokens being wrapped.");
        require(hasGivenAllowance, "NFTWrapper: Must approve this contract to transfer tokens.");
    }

    /// @dev Lets a wrapped nft owner redeem the underlying ERC721 NFT.
    function redeemERC721(uint256 _tokenId, address _redeemer) external {
        address baseToken = msg.sender;

        // Transfer the NFT to redeemer
        IERC721(erc721WrappedTokens[baseToken][_tokenId].source).safeTransferFrom(
            address(this),
            _redeemer,
            erc721WrappedTokens[baseToken][_tokenId].tokenId
        );

        emit ERC721Redeemed(
            baseToken,
            _redeemer,
            erc721WrappedTokens[baseToken][_tokenId].source,
            erc721WrappedTokens[baseToken][_tokenId].tokenId,
            _tokenId
        );
    }

    /// @dev Lets the nft owner redeem their ERC20 tokens.
    function redeemERC20(
        uint256 _tokenId,
        uint256 _amount,
        address _redeemer
    ) external {
        address baseToken = msg.sender;

        // Get the ERC20 token amount to distribute
        uint256 amountToDistribute = (erc20WrappedTokens[baseToken][_tokenId].underlyingTokenAmount * _amount) /
            erc20WrappedTokens[baseToken][_tokenId].shares;

        // Transfer the ERC20 tokens to redeemer
        require(
            IERC20(erc20WrappedTokens[baseToken][_tokenId].source).transfer(_redeemer, amountToDistribute),
            "NFTWrapper: Failed to transfer ERC20 tokens."
        );

        emit ERC20Redeemed(
            baseToken,
            _redeemer,
            erc20WrappedTokens[baseToken][_tokenId].source,
            _tokenId,
            amountToDistribute,
            _amount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}