//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract OneOfXL1 is IERC721Metadata, IERC721Enumerable {
    string public override name = "1 of X";
    string public override symbol = "1/X";
    string public contractURI = "";
    uint256 public registrationPrice = 0;
    address private signerAddress;
    address payable private payoutAddress;

    string private constant ERR_NOT_AUTHORIZED = "e1";
    string private constant ERR_BAD_REQUEST = "e2";
    string private constant ERR_BAD_RECEIVER = "e4";

    mapping(address => bool) public administrators;
    mapping(address => bool) public minters;
    mapping(uint256 => address) private tokenApprovals;
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => string) public override tokenURI;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    mapping(address => uint256[]) public addressToTokenIds;
    mapping(uint256 => uint256) internal tokenIdToIndexInOwner;
    mapping(uint256 => uint256) internal tokenIdToIndex;

    uint256[] public indexToTokenId;

    constructor() {
        signerAddress = _msgSender();
        payoutAddress = payable(_msgSender());
        administrators[signerAddress] = true;
    }

    modifier onlyAdmin() {
        require(administrators[_msgSender()], ERR_NOT_AUTHORIZED);
        _;
    }

    modifier onlyMinter() {
        require(minters[_msgSender()], ERR_NOT_AUTHORIZED);
        _;
    }

    function setAdmin(address addr, bool isAdmin) public onlyAdmin {
        administrators[addr] = isAdmin;
    }

    function setMinter(address addr, bool isMinter) public onlyAdmin {
        minters[addr] = isMinter;
    }

    function setContractURI(string memory uri) public onlyAdmin {
        contractURI = uri;
    }

    function balanceOf(address addr) external view returns (uint256 balance) {
        return addressToTokenIds[addr].length;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        return tokenOwners[tokenId];
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        require(_exists(tokenId), ERR_BAD_REQUEST);
        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return operatorApprovals[owner][operator];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = tokenOwners[tokenId];
        require(owner != address(0), ERR_BAD_REQUEST);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        _safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        require(isApprovedOrOwner(_msgSender(), tokenId), ERR_NOT_AUTHORIZED);
        _safeTransfer(from, to, tokenId, "");
    }

    function approve(address to, uint256 tokenId) external override {
        require(_exists(tokenId), ERR_BAD_REQUEST);
        address owner = ownerOf(tokenId);
        require(
            (to != owner && _msgSender() == owner) ||
                isApprovedForAll(owner, _msgSender()),
            ERR_BAD_REQUEST
        );
        _approve(to, tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return indexToTokenId.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId)
    {
        require(addressToTokenIds[owner].length > index, ERR_BAD_REQUEST);
        return addressToTokenIds[owner][index];
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory tokenId)
    {
        return addressToTokenIds[owner];
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(indexToTokenId.length > index, ERR_BAD_REQUEST);
        return indexToTokenId[index];
    }

    function getChainID() external view returns (uint256) {
        uint256 id;

        assembly {
            id := chainid()
        }

        return id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function mint(
        address addr,
        uint256 tokenId,
        string calldata uri
    ) external onlyMinter {
        tokenURI[tokenId] = uri;
        _mint(addr, tokenId);
    }

    // private

    function _mint(address to, uint256 tokenId) internal {
        _addToAddress(tokenId, to);
        tokenIdToIndex[tokenId] = indexToTokenId.length;
        indexToTokenId.push(tokenId);

        emit Transfer(address(0), to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            ERR_BAD_RECEIVER
        );
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        require(isApprovedOrOwner(_msgSender(), tokenId), ERR_NOT_AUTHORIZED);
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            ERR_BAD_RECEIVER
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(ownerOf(tokenId) == from && to != address(0), ERR_BAD_REQUEST);
        delete tokenApprovals[tokenId];

        _removeFromAddress(tokenId, from);
        _addToAddress(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _removeFromAddress(uint256 tokenId, address from) internal {
        delete tokenOwners[tokenId];

        uint256 tokenIndex = tokenIdToIndexInOwner[tokenId];

        addressToTokenIds[from][tokenIndex] = addressToTokenIds[from][
            addressToTokenIds[from].length - 1
        ];
        addressToTokenIds[from].pop();

        delete tokenIdToIndexInOwner[tokenId];
    }

    function _addToAddress(uint256 tokenId, address to) internal {
        tokenOwners[tokenId] = to;
        tokenIdToIndexInOwner[tokenId] = addressToTokenIds[to].length;
        addressToTokenIds[to].push(tokenId);
    }

    function _approve(address to, uint256 tokenId) private {
        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, ERR_BAD_REQUEST);
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(ERR_BAD_RECEIVER);
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

    function _msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function _burn(uint256 tokenId) private {
        delete tokenApprovals[tokenId];
        address owner = ownerOf(tokenId);

        _removeFromAddress(tokenId, owner);

        uint256 tokenIndex = tokenIdToIndex[tokenId];
        indexToTokenId[tokenIndex] = indexToTokenId[indexToTokenId.length - 1];
        indexToTokenId.pop();

        delete tokenIdToIndex[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
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