// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import {MintWhitelist} from "./Mint.sol";

/*
 * Dev by @_MrCode_
 *
 *
 * ██╗░░░░░░█████╗░░██████╗  ██╗░░░██╗███████╗░██████╗░░█████╗░░██████╗
 * ██║░░░░░██╔══██╗██╔════╝  ██║░░░██║██╔════╝██╔════╝░██╔══██╗██╔════╝
 * ██║░░░░░███████║╚█████╗░  ╚██╗░██╔╝█████╗░░██║░░██╗░███████║╚█████╗░
 * ██║░░░░░██╔══██║░╚═══██╗  ░╚████╔╝░██╔══╝░░██║░░╚██╗██╔══██║░╚═══██╗
 * ███████╗██║░░██║██████╔╝  ░░╚██╔╝░░███████╗╚██████╔╝██║░░██║██████╔╝
 * ╚══════╝╚═╝░░╚═╝╚═════╝░  ░░░╚═╝░░░╚══════╝░╚═════╝░╚═╝░░╚═╝╚═════╝░
 *
 * ██╗███╗░░██╗███████╗███████╗██████╗░███╗░░██╗░█████╗░  ██████╗░███████╗░█████╗░██████╗░███████╗██████╗░░██████╗
 * ██║████╗░██║██╔════╝██╔════╝██╔══██╗████╗░██║██╔══██╗  ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
 * ██║██╔██╗██║█████╗░░█████╗░░██████╔╝██╔██╗██║██║░░██║  ██████╔╝█████╗░░███████║██████╔╝█████╗░░██████╔╝╚█████╗░
 * ██║██║╚████║██╔══╝░░██╔══╝░░██╔══██╗██║╚████║██║░░██║  ██╔══██╗██╔══╝░░██╔══██║██╔═══╝░██╔══╝░░██╔══██╗░╚═══██╗
 * ██║██║░╚███║██║░░░░░███████╗██║░░██║██║░╚███║╚█████╔╝  ██║░░██║███████╗██║░░██║██║░░░░░███████╗██║░░██║██████╔╝
 * ╚═╝╚═╝░░╚══╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░
 *
 */

contract VegasReapersContract is MintWhitelist {
    /// @notice constructor
    constructor(
        address[5] memory receiverAddresses_,
        uint256[5] memory receiverPercentages_,
        uint256 firstPaymentRemaining_
    ) ERC721("Vegas Reapers", "VGS") {
        firstPaymentRemaining = firstPaymentRemaining_;

        receiverAddresses = receiverAddresses_;
        receiverPercentages = receiverPercentages_;
        for (uint8 i = 0; i < receiverAddresses_.length; i++) {
            addressToIndex[receiverAddresses_[i]] = i + 1;
        }

        royaltyStages.push(RoyaltyStage(block.timestamp, 0, 0, 0, 0));

        // reserve first 1 tokens for the team
        for (uint256 tokenId = 1; tokenId <= 11; tokenId++) {
            setTokenId(tokenId);
        }

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return _owners[tokenId] != address(0);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./MerkleProof.sol";
import "./Royalties.sol";

abstract contract BaseMint is Royalties {
    using SafeMath for uint256;

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @param from address from which to transfer the token
     * @param to address to which to transfer the token
     * @param tokenId to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _updateTokenOwners(from, to, tokenId);
        _tryToChangeRoyaltyStage();
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @param from address from which to transfer the token
     * @param to address to which to transfer the token
     * @param tokenId to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _updateTokenOwners(from, to, tokenId);
        _tryToChangeRoyaltyStage();
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Mint n tokens for an address
     * @param to address to mint tokens for
     * @param count_ number of tokens to mint
     */
    function mintNTokensFor(address to, uint8 count_)
        public
        payable
        nonReentrant
    {
        require(publicMintingStarted, NOT_STARTED);
        _internalMint(to, count_, false);
    }

    /**
     * @dev Mint new tokens
     * @param count_ the number of tokens to be minted
     */
    function _internalMint(
        address to,
        uint8 count_,
        bool addRoles
    ) internal {
        require(!paused(), "Minting is paused");
        require(count_ > 0, CANT_MINT);

        uint256 startCount;

        if (addRoles) {
            require(
                numberOfMintedWhitelistTokens + count_ <= MAX_WHITELIST_TOKENS,
                "Cant mint more"
            );
            numberOfMintedWhitelistTokens += count_;

            startCount = numberOfMintedTokensFor[msg.sender] - count_;
            require(
                msg.value == MINT_PRICE_WHITELIST.mul(count_),
                WRONG_BALANCE
            );
        } else {
            require(msg.value == MINT_PRICE.mul(count_), WRONG_BALANCE);
            require(count_ <= MAX_TOKENS_PER_PURCHASE, TOO_MANY);
            require(
                totalSupply() + count_ <=
                    MAX_TOKENS - MAX_RESERVED_TOKENS + mintedReservedTokens,
                TOO_MANY
            );
        }

        for (uint8 i = 0; i < count_; i++) {
            uint256 tokenId = randomId();
            if (addRoles) {
                startCount++;
                tokenRoles[tokenId] = startCount == 1
                    ? ROLE_LION
                    : ROLE_INFERNAL;
            }
            _mintToken(to, tokenId);
        }

        distributePayout(count_);
    }

    /**
     * @dev Mint token for an address
     * @param to address to mint token for
     */
    function _mintRandomToken(address to) internal {
        uint256 tokenId = randomId();
        _mintToken(to, tokenId);
    }

    /**
     * @dev Mint token for an address
     * @param to address to mint token for
     * @param tokenId to be minted
     */
    function _mintToken(address to, uint256 tokenId) internal {
        uint256 currentIndex = ownerTokenList[msg.sender].length;
        ownerTokenList[to].push(tokenId);
        ownedTokensDetails[to][tokenId] = NFTDetails(
            tokenId,
            currentIndex,
            block.timestamp,
            0
        );
        royaltyStages[getLastRoyaltyStageIndex()].totalSupply++;
        _safeMint(to, tokenId);
    }

    function distributePayout(uint8 count_) internal {
        uint256 value = msg.value;
        if (firstPaymentRemaining > 0) {
            address reserve = receiverAddresses[receiverAddresses.length - 1];
            if (value > firstPaymentRemaining) {
                value -= firstPaymentRemaining;
                sendValueTo(reserve, firstPaymentRemaining);
                firstPaymentRemaining = 0;
            } else {
                firstPaymentRemaining -= value;
                sendValueTo(reserve, value);
                return;
            }
        }
        if (
            currentMaxTokensBeforeAutoWithdraw + count_ <
            MAX_TOKENS_BEFORE_AUTO_WITHDRAW &&
            totalSupply() + count_ <
            MAX_TOKENS - MAX_RESERVED_TOKENS + mintedReservedTokens
        ) {
            currentMaxTokensBeforeAutoWithdraw += count_;
            for (uint8 i; i < receiverAddresses.length; i++) {
                currentTeamBalance[i] += (value * receiverPercentages[i]) / 100;
            }
            return;
        }

        currentMaxTokensBeforeAutoWithdraw = 0;
        for (uint8 i; i < receiverAddresses.length; i++) {
            uint256 valueToSend = (value * receiverPercentages[i]) / 100;
            valueToSend += currentTeamBalance[i];
            currentTeamBalance[i] = 0;

            sendValueTo(receiverAddresses[i], valueToSend);
        }
    }

    /**
     * @dev Change token owner details mappings
     */
    function _updateTokenOwners(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint256 currentIndex = ownerTokenList[to].length;
        ownerTokenList[to].push(tokenId);
        ownedTokensDetails[to][tokenId] = NFTDetails(
            tokenId,
            currentIndex,
            block.timestamp,
            0
        );

        _withdrawRoyaltyOfTokenTo(from, from, tokenId);

        NFTDetails storage details = ownedTokensDetails[from][tokenId];
        details.endTime = block.timestamp;

        uint256[] storage fromList = ownerTokenList[from];
        fromList[details.index] = fromList[fromList.length - 1];
        fromList.pop();
    }
}

abstract contract MintReserve is BaseMint {
    function canMintReserved(uint256 count_) internal view {
        require(
            mintedReservedTokens + count_ <= MAX_RESERVED_TOKENS,
            CANT_MINT
        );
    }

    /**
     * @dev Mint reserved team tokens to a specific address
     * @param to addresses to mint token for
     * @param tokenIds numbers of tokens to be minted
     */
    function mintReservedTeamTokensTo(
        address[] memory to,
        uint256[] memory tokenIds
    ) public onlyOwner {
        require(to.length == tokenIds.length, WRONG_LENGTH);
        canMintReserved(to.length);
        mintedReservedTokens += tokenIds.length;
        for (uint256 i; i < to.length; i++) {
            _mintToken(to[i], tokenIds[i]);
        }
    }

    /**
     * @dev Mint reserved tokens to a specific address
     * @param to address to mint token for
     * @param counts numbers of tokens to be minted
     */
    function mintReservedTokensTo(address[] memory to, uint8[] memory counts)
        public
        onlyOwner
    {
        uint256 totalCount;
        for (uint256 i; i < counts.length; i++) {
            totalCount += counts[i];
        }
        canMintReserved(totalCount);
        mintedReservedTokens += totalCount;
        for (uint256 i; i < to.length; i++) {
            address to_ = to[i];
            for (uint256 j; j < counts[i]; j++) {
                _mintRandomToken(to_);
            }
        }
    }
}

abstract contract MintWhitelist is MintReserve, MerkleProof {
    using SafeMath for uint256;

    function startPublicMinting() public onlyOwner {
        require(!publicMintingStarted, ALREADY_ENABLED);
        whitelistMintingStarted = false;
        publicMintingStarted = true;
    }

    function flipWhitelistMinting() public onlyOwner {
        whitelistMintingStarted = !whitelistMintingStarted;
    }

    /**
     * @dev Mint a free token
     * @param to addresses to mint token for
     * @param proof to check if is whitelisted
     */
    function mintForFee(address to, bytes32[] memory proof)
        public
        nonReentrant
    {
        hasValidProof(proof, merkleRootMintFree);
        require(!claimedFree[msg.sender], CANT_MINT);
        claimedFree[msg.sender] = true;
        _mintToken(to, randomId());
    }

    /**
     * @dev Mint a free token
     * @param to addresses to mint token for
     * @param proof to check if is whitelisted
     */
    function mintWhitelist(
        address to,
        uint8 count,
        bytes32[] memory proof
    ) public payable nonReentrant {
        hasValidProof(proof, merkleRoot);
        require(
            numberOfMintedTokensFor[msg.sender] + count <=
                MAX_WHITELIST_PER_PURCHASE,
            "Cant mint more"
        );
        increaseAddressCount(count);
        _internalMint(to, count, true);
    }

    /**
     * @dev Mint one token if it has gold tokens
     * @param to address to mint tokens for
     * @param proof to check if is whitelisted
     */
    function mintForFreeWithGold(address to, bytes32[] memory proof)
        public
        payable
        nonReentrant
    {
        hasValidProof(proof, merkleRootGoldMintFree);
        require(!claimedGoldFree[msg.sender], CANT_MINT);
        claimedGoldFree[msg.sender] = true;
        canMintFromGold(1);
        increaseAddressCount(1);
        _internalMint(to, 1, true);
    }

    /**
     * @dev Whitelist mint tokens to a specific address
     * @param to address to mint token for
     * @param count_ number of tokens to mint
     */
    function mintWhitelistGoldTo(address to, uint8 count_)
        public
        payable
        nonReentrant
    {
        require(whitelistMintingStarted, NOT_STARTED);
        require(count_ > 0, "Mint more");

        canMintFromGold(count_);
        increaseAddressCount(count_);
        _internalMint(to, count_, true);
    }

    function increaseAddressCount(uint256 count_) internal {
        uint256 currentMintedTokens = count_ +
            numberOfMintedTokensFor[msg.sender];
        numberOfMintedTokensFor[msg.sender] = currentMintedTokens;

        addressRoles[msg.sender] = currentMintedTokens == 1
            ? ROLE_LION
            : ROLE_INFERNAL;
    }

    function canMintFromGold(uint256 count_) internal {
        uint256[] memory tokenIds = soulToken.goldTokensByOwner(msg.sender);
        require(tokenIds.length > 0, CANT_MINT);

        uint256 tempCount = count_;

        uint256 finalCount;
        for (uint256 i; i < tokenIds.length; i++) {
            if (finalCount == count_) {
                break;
            }
            uint256 tokenId = tokenIds[i];
            uint256 oldTokensCount = goldTokenUsed[tokenId];
            uint256 tokensToMint = MAX_PRE_SALE_TOKENS - oldTokensCount;

            if (tokensToMint > tempCount) {
                tokensToMint = tempCount;
            }

            uint8 mintedTokensForGold = uint8(oldTokensCount + tokensToMint);
            goldTokenUsed[tokenId] = mintedTokensForGold;
            soulToken.setGoldRole(tokenId, mintedTokensForGold);

            finalCount += tokensToMint;
            tempCount -= tokensToMint;
        }

        require(finalCount == count_, "can't mint for gold");
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
abstract contract MerkleProof is Ownable {
    string private MERKLE_CHANGES_DISABLED = "MerkleRoot changes are disabled";

    // merkle tree root used to validate if the sender can mint
    bytes32 public merkleRootMintFree;
    bytes32 public merkleRootGoldMintFree;
    bytes32 public merkleRoot;

    /**
     * @dev Set the merkle tree mint free root hash
     * @param merkleRoot_ hash to save
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * @dev Set the merkle tree mint free root hash
     * @param merkleRootMintFree_ hash to save
     */
    function setMerkleRootMintFree(bytes32 merkleRootMintFree_)
        external
        onlyOwner
    {
        merkleRootMintFree = merkleRootMintFree_;
    }

    /**
     * @dev Set the merkle tree gold mint free root hash
     * @param merkleRootGoldMintFree_ hash to save
     */
    function setMerkleRootGoldMintFree(bytes32 merkleRootGoldMintFree_)
        external
        onlyOwner
    {
        merkleRootGoldMintFree = merkleRootGoldMintFree_;
    }

    /**
     * @dev Returns true if a leaf can be proved to be a part of a Merkle tree
     * defined by root. For this, a proof must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     * @param proof hashes to validate
     * @param merkleRoot_ merkle root to compare with
     */
    function hasValidProof(bytes32[] memory proof, bytes32 merkleRoot_)
        internal
        view
    {
        bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            computedHash = keccak256(
                computedHash <= proofElement
                    ? abi.encodePacked(computedHash, proofElement)
                    : abi.encodePacked(proofElement, computedHash)
            );
        }

        // Check if the computed hash (root) is equal to the provided root
        require(computedHash == merkleRoot_, "the proof is not valid");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Balances.sol";

abstract contract Royalties is Balances, ReentrancyGuard {
    using SafeMath for uint256;

    function getValidRoyaltyIndex() private view returns (uint8 index) {
        index = addressToIndex[msg.sender];
        require(index > 0, NO_ACCESS);
    }

    function withdrawTeamMemberRoyaltyTo(address to, uint256 valueToWithdraw)
        public
    {
        uint8 index = getValidRoyaltyIndex() - 1;
        uint256 value = currentTeamRoyalty[index];
        require(value > 0, NO_BALANCE);
        require(value >= valueToWithdraw, TOO_MANY);

        valueToWithdraw = valueToWithdraw > 0 ? valueToWithdraw : value;
        currentTeamRoyalty[index] = value - valueToWithdraw;
        totalRoyaltyWithdrawed += valueToWithdraw;

        depositor.withdrawTo(to, valueToWithdraw);
    }

    /**
     * @dev Change the interval when the royalties can be shared
     * @param royaltyInterval_ time to collect royalties
     */
    function changeRoyaltyInterval(uint256 royaltyInterval_) public onlyOwner {
        require(royaltyInterval != royaltyInterval_, SAME_VALUE);
        royaltyInterval = royaltyInterval_;
    }

    /**
     * @dev Create a new royalty stage to collecty royalties
     * Current stage would become available for royalty withdrawing
     */
    function nextRoyaltyStage() public onlyOwner {
        require(canChangeRoyaltyStage(), DISABLED_CHANGES);
        _nextRoyaltyStage();
    }

    /**
     * @dev Get last royalty stage index
     */
    function getLastRoyaltyStageIndex() internal view returns (uint256) {
        return royaltyStages.length - 1;
    }

    /**
     * @dev Create a new royalty stage
     */
    function _nextRoyaltyStage() private {
        uint256 valueAdded = address(depositor).balance -
            (totalRoyaltyAdded - totalRoyaltyWithdrawed);
        totalRoyaltyAdded += valueAdded;

        uint256 communityRoyalty = valueAdded / 5; // 20%

        uint256 teamRoyalty = valueAdded - communityRoyalty;
        for (uint8 i; i < receiverAddresses.length; i++) {
            currentTeamRoyalty[i] +=
                (teamRoyalty * receiverPercentages[i]) /
                100;
        }

        uint256 lastIndex = getLastRoyaltyStageIndex();
        royaltyStages[lastIndex].endDate = block.timestamp;
        royaltyStages[lastIndex].amount = communityRoyalty;
        royaltyStages[lastIndex].totalSupply = totalSupply();

        royaltyStages.push(RoyaltyStage(block.timestamp, 0, 0, 0, 0));
    }

    /**
     * @dev Check if a new royalty stage can be created
     */
    function canChangeRoyaltyStage() private view returns (bool) {
        RoyaltyStage memory lastStage = royaltyStages[
            getLastRoyaltyStageIndex()
        ];
        uint256 valueAdded = address(depositor).balance -
            (totalRoyaltyAdded - totalRoyaltyWithdrawed);
        return
            valueAdded > 0 &&
            (block.timestamp - lastStage.startDate) >= royaltyInterval;
    }

    /**
     * @dev Create a new royalty stage if it's possible on each mint/transfer
     * Used when tokens are transferred
     */
    function _tryToChangeRoyaltyStage() internal {
        if (canChangeRoyaltyStage()) {
            _nextRoyaltyStage();
        }
    }

    /**
     * @dev Withdraw royalties for all royalty stages that the sender didn't collect royalties
     * The royalties are based on the tokens that the sender holded on each royalty stage
     * @param to address that will receive the royalty
     * @param inputTokenId for which to collect royalties
     */
    function withdrawRoyaltyOfTokenTo(address to, uint256 inputTokenId) public {
        _withdrawRoyaltyOfTokenTo(msg.sender, to, inputTokenId);
    }

    function _withdrawRoyaltyOfTokenTo(
        address from,
        address to,
        uint256 inputTokenId
    ) internal {
        uint256 userLastIndex = ownerRoyaltyStageIndex[from];
        uint256 lastIndex = getLastRoyaltyStageIndex();
        require(userLastIndex < lastIndex, NO_BALANCE);

        bool hasInputToken = inputTokenId > 0;

        uint256 royaltyAmount;
        for (uint256 i = userLastIndex; i < lastIndex; i++) {
            RoyaltyStage memory stage = royaltyStages[i];
            if (stage.amount == 0) {
                continue;
            }
            uint256 eligibleTokenCount;
            uint256 n = hasInputToken ? 1 : ownerTokenList[from].length;
            for (uint256 j; j < n; j++) {
                uint256 tokenId;
                if (hasInputToken) {
                    tokenId = inputTokenId;
                } else {
                    tokenId = ownerTokenList[from][j];
                }
                if (royaltyTokenClaimed[i][tokenId]) {
                    continue;
                }

                NFTDetails memory details = ownedTokensDetails[from][tokenId];
                if (
                    stage.startDate <= details.starTime &&
                    details.endTime < stage.endDate
                ) {
                    eligibleTokenCount++;
                    royaltyTokenClaimed[i][tokenId] = true;
                }
            }
            if (eligibleTokenCount == 0) {
                continue;
            }
            royaltyStages[i].totalWithdrawals += eligibleTokenCount;
            royaltyAmount +=
                (stage.amount / stage.totalSupply) *
                eligibleTokenCount;
        }
        require(royaltyAmount > 0, NO_BALANCE);

        if (!hasInputToken) {
            ownerRoyaltyStageIndex[from] = lastIndex;
        }

        totalRoyaltyWithdrawed += royaltyAmount;

        depositor.withdrawTo(to, royaltyAmount);
    }

    function withdrawUnclaimedRoyaltyTo(address to)
        public
        onlyOwner
        nonReentrant
    {
        uint256 royaltyToWitdraw;
        for (
            uint256 i = unclaimedRoyaltyStageIndex;
            i < royaltyStages.length;
            i++
        ) {
            RoyaltyStage memory stage = royaltyStages[i];
            if ((block.timestamp - stage.startDate) < WITHDRAW_ROYALTY_TIME) {
                unclaimedRoyaltyStageIndex = i;
                break;
            }
            uint256 unclaimedCount = stage.totalSupply - stage.totalWithdrawals;
            if (unclaimedCount == 0) {
                continue;
            }
            royaltyStages[i].totalWithdrawals = stage.totalSupply;
            royaltyToWitdraw +=
                unclaimedCount *
                (stage.amount / stage.totalSupply);
        }

        require(royaltyToWitdraw > 0, NO_BALANCE);

        totalRoyaltyWithdrawed += royaltyToWitdraw;

        depositor.withdrawTo(to, royaltyToWitdraw);
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./Base.sol";

abstract contract Balances is Base {
    function withdrawTeamMemberBalanceTo(address to, uint256 valueToWithdraw)
        public
    {
        uint8 index = getValidIndex() - 1;
        uint256 value = currentTeamBalance[index];
        require(value > 0, NO_BALANCE);
        require(value >= valueToWithdraw, TOO_MANY);
        valueToWithdraw = valueToWithdraw > 0 ? valueToWithdraw : value;
        currentTeamBalance[index] = value - valueToWithdraw;
        sendValueTo(to, valueToWithdraw);
    }

    function getValidIndex() internal view returns (uint8 index) {
        index = addressToIndex[msg.sender];
        require(index > 0, NO_ACCESS);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./Fields.sol";

abstract contract Base is
    Ownable,
    Fields,
    ERC165Storage,
    ERC721Pausable,
    ERC721Enumerable
{
    /*
     * accepts ether sent with no txData
     */
    receive() external payable {}

    /*
     * refuses ether sent with txData that does not match any function signature in the contract
     */
    fallback() external {}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
        super._unpause();
    }

    function setDepositor(IDepositor depositor_) public onlyOwner {
        depositor = depositor_;
    }

    function setSoulToken(ISoulToken soulToken_) public onlyOwner {
        soulToken = soulToken_;
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the ProxyRegistry of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev baseURI for computing {tokenURI}. Empty by default, can be overwritten
     * in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC165Storage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Send an amount of value to a specific address
     * @param to_ address that will receive the value
     * @param value to be sent to the address
     */
    function sendValueTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, FUNCTION_CALL_ERROR);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Pausable, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Set the baseURI to a given uri
     * @param baseURI_ string to save
     */
    function changeBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Get the list of tokens for a specific owner
     * @param _owner address to retrieve token ids for
     */
    function tokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * @dev Withdraw remaining contract balance to owner
     */
    function withdrawRemainingContractBalance() public onlyOwner {
        uint256 remainingBalance = address(this).balance;
        for (uint8 i; i < currentTeamBalance.length; i++) {
            remainingBalance -= currentTeamBalance[i];
        }
        require(remainingBalance > 0, NO_BALANCE);
        sendValueTo(owner(), remainingBalance);
    }

    /**
     * Get random index and save it
     */
    function randomId() internal returns (uint256) {
        uint256 totalSize = 1000 -
            totalSupply() -
            numberOfReservedTeamCustomTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    block.coinbase,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;

        totalSize--;
        uint256 value;

        uint256 currentValue = indices[index];
        if (currentValue != 0) {
            value = currentValue;
        } else {
            value = index;
        }
        uint16 currentLastValue = indices[totalSize];
        // Move last value to selected position
        if (currentLastValue == 0) {
            // Array position not initialized, so use position
            indices[index] = uint16(totalSize);
        } else {
            // Array position holds a value so use that
            indices[index] = currentLastValue;
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    /**
     * Set token index id
     */
    function setTokenId(uint256 tokenId) internal {
        uint256 totalSize = 1000 - totalSupply() - tokenId;
        indices[tokenId - 1] = uint16(totalSize);
        nonce++;
        numberOfReservedTeamCustomTokens++;
    }

    function limitMaxWhitelistTokensTo(uint256 maxTokens) public onlyOwner {
        MAX_WHITELIST_TOKENS = maxTokens;
    }

    function limitMaxTokensTo(uint256 maxTokens) public onlyOwner {
        require(
            totalSupply() + MAX_RESERVED_TOKENS - mintedReservedTokens <=
                maxTokens,
            "Invalid number of tokens"
        );
        MAX_TOKENS = maxTokens;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDepositor {
    function getContractBalance() external view returns (uint256);

    function withdrawTo(address to_, uint256 value) external;
}

interface ISoulToken {
    function goldTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setGoldRole(uint256 tokenId, uint256 numberOfMintedTokens)
        external;
}

contract Fields {
    // struct that holds information about when a token was created/transferred
    struct NFTDetails {
        uint256 tokenId;
        uint256 index;
        uint256 starTime;
        uint256 endTime;
    }
    // struct that holds information about royalty stages to reward token owners
    struct RoyaltyStage {
        uint256 startDate;
        uint256 endDate;
        uint256 amount;
        uint256 totalSupply;
        uint256 totalWithdrawals;
    }

    // nonce to be used on generating the random token id
    uint16 nonce;
    uint16[1000] indices;

    // maximum number of tokens that can be minted. can be changed to lower number
    uint256 internal MAX_TOKENS = 1000;
    uint256 internal MAX_WHITELIST_TOKENS = 500;
    uint256 internal MAX_WHITELIST_PER_PURCHASE = 5;
    // maximum number of tokens that can be minted in a single transaction
    uint256 internal constant MAX_TOKENS_PER_PURCHASE = 15;
    // maximum number of tokens that can be minted at pre-sale
    uint256 internal constant MAX_PRE_SALE_TOKENS = 10;
    // max number of reserved tokens
    uint256 internal constant MAX_RESERVED_TOKENS = 60;
    // minted reserved tokens
    uint256 internal mintedReservedTokens;

    uint256 internal firstPaymentRemaining;

    // the price to mint a token
    uint256 internal constant MINT_PRICE = 0.06 ether;
    uint256 internal constant MINT_PRICE_WHITELIST = 0.04 ether;

    uint8 internal currentMaxTokensBeforeAutoWithdraw;
    uint8 internal constant MAX_TOKENS_BEFORE_AUTO_WITHDRAW = 25;

    uint8 numberOfReservedTeamCustomTokens;

    uint256 public numberOfMintedWhitelistTokens;

    bool public whitelistMintingStarted = true;

    bool public publicMintingStarted;

    string internal constant ROLE_LION = "LION";
    string internal constant ROLE_INFERNAL = "INFERNAL";
    mapping(address => string) public addressRoles;
    mapping(uint256 => string) public tokenRoles;
    mapping(address => uint256) public numberOfMintedTokensFor;
    mapping(uint256 => uint8) goldTokenUsed;

    mapping(address => bool) internal claimedFree;
    mapping(address => bool) internal claimedGoldFree;
    mapping(address => uint8) internal mintedWhitelist;

    // receiver address to ge the funds
    address[5] internal receiverAddresses;
    // receiver percentage of total funds
    uint256[5] internal receiverPercentages;
    // current balance to withdraw from contract by a specific address
    uint256[5] internal currentTeamBalance;
    // mapping from address to index of receiverAddresses array
    mapping(address => uint8) internal addressToIndex;

    // current royalty to withdraw from contract by a specific address
    uint256[5] internal currentTeamRoyalty;
    // mapping from address to index of royalty receiverAddresses array
    mapping(address => uint8) internal addressRoyaltyToIndex;

    // the baseURI for token metadata
    string internal baseURI;

    // mapping from owner to list of token ids
    mapping(address => uint256[]) internal ownerTokenList;
    // mapping from token ID to token details of the owner tokens list
    mapping(address => mapping(uint256 => NFTDetails))
        internal ownedTokensDetails;
    // mapping from owner address to the stage index to start collecting royalties
    mapping(address => uint256) internal ownerRoyaltyStageIndex;

    // the interval in which royalty gets collected
    uint256 public royaltyInterval = 4 weeks;
    // royalty stage details
    RoyaltyStage[] public royaltyStages;
    // mapping from owner address to the stage index to start collecting royalties
    mapping(uint256 => mapping(uint256 => bool)) internal royaltyTokenClaimed;

    // total royalty added to the depositor
    uint256 internal totalRoyaltyAdded;
    // total royalty withdrawed
    uint256 internal totalRoyaltyWithdrawed;

    // index from which the owner will withdraw the unclaimed rewards;
    uint256 internal unclaimedRoyaltyStageIndex;
    uint256 internal constant WITHDRAW_ROYALTY_TIME = 365 days;

    IDepositor internal depositor;
    ISoulToken internal soulToken;

    string internal constant SAME_VALUE = "same value";
    string internal constant WRONG_BALANCE = "wrong balance";
    string internal constant DISABLED_CHANGES = "disabled changes";
    string internal constant NO_BALANCE = "no balance";
    string internal constant WRONG_LENGTH = "wrong length";
    string internal constant TOO_MANY = "too many";
    string internal constant NOT_STARTED = "not started";
    string internal constant NO_ACCESS = "no access";
    string internal constant CANT_MINT = "can't mint";
    string internal constant ALREADY_ENABLED = "already enabled";
    string internal constant FUNCTION_CALL_ERROR =
        "Function call not successful";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}