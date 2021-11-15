// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./asdfMetadata.sol";

contract asdf is ERC721Enumerable, asdfMetadata {
    uint private _counter; // Track the current tokenId
    
    constructor() ERC721("asdf", "ASDF") {
    }
    uint256 price = 90000000000000000; // 0.09 ETH
    uint killswitch = 0;
    // Claim a single token
    function claim() public payable onlyOwner nonReentrant {
        require(paused == 0, "Minting is paused.");
        if (presale == 1){
             require(IERC721(_Loot).balanceOf(msg.sender) > 0, "Presale for Loot holders only!");
        }
        require(_counter < MAX_SUPPLY - 5, "All tokens have been minted!");

        _counter += 1;
        uint tokenId = _counter;
        require(msg.value >= price, "Must send minimum value to claim!");

        if (tokenId == 1){ // First explorer seeds the world
            explorerSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, "Hello, World!"))) % 9999;
        }
        if (seedBlock == 0 && (_counter == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            seedBlock = block.number;
        }
        _safeMint(_msgSender(), tokenId);
    }

    // Claim multiple tokens
    function claimMultiple(uint numTokens) public onlyOwner payable nonReentrant {
        require(paused == 0, "Minting is paused.");
        if (presale == 1){
            require(IERC721(_Loot).balanceOf(msg.sender) > 0, "Presale for Loot holders only!");
        }
        uint base = _counter;
        require(base < (MAX_SUPPLY - numTokens) - 5, "Not enough tokens remaining!");
        require(msg.value >= numTokens * price, "Must send minimum value to claim!");

        if (base == 1){ // First explorer seeds the world
            explorerSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, "Hello, World!"))) % 9999;
        }
        while (_counter < base + numTokens){
            _counter += 1;
            uint tokenId = _counter;
            _safeMint(_msgSender(), tokenId);
        }
        if (seedBlock == 0 && (_counter == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            seedBlock = block.number;
        }
    }
    
    // Allotment of 5 tokens for owner
    function ownerClaim() public nonReentrant onlyOwner {
        require(_counter >= MAX_SUPPLY - 5 && _counter < MAX_SUPPLY, "Owner claim unavailable");
        _counter += 1;
        uint tokenId = _counter;
        _safeMint(owner(), tokenId);

        if (seedBlock == 0 && (_counter == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            seedBlock = block.number;
        }
    }

    // Return an SVG depiction of the token
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(killswitch == 0, "TokenURI is turned off");

        require(initSeed != 0, "Tokens not yet revealed");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return Renderer.render(_assembleParams(tokenId));
    }
    
    function toggleKillswitch() public onlyOwner {
        killswitch = (killswitch + 1) % 2;
    }
    
    // Returns the numerical data used to create the token
    function getTokenRawData(uint256 tokenId) public onlyOwner view returns(int[28][28] memory){
        require(initSeed != 0, "Tokens not yet revealed");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return Renderer.getRaw(_assembleParams(tokenId));
    }
    
    // Returns the numerical data used to create the token, including points of interest
    // Returns a 2d array representing up to 5 points of interest
    // [0-9 value representing POI, xPos, yPos]
    function getTokenPointsOfInterest(uint256 tokenId) public onlyOwner view returns (uint[3][5] memory){
        require(initSeed != 0, "Tokens not yet revealed");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint POIs = _placePointsOfInterest(tokenId, _getRawPointsOfInterest(tokenId));
        uint cur;
        uint count = 0;
        uint[3][5] memory result;
        while (POIs > 0){
            cur = POIs % 100000; // Isolate first 5 digits, i.e., first POI
            result[count] = [cur / 10000, (cur / 100) % 100, cur % 100]; // [0-9 value representing POI, POI xcoord, POI ycoord]
            count += 1;
            POIs = POIs / 100000;
        }
        return result;
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

import "./asdfGenerator.sol";
contract asdfMetadata is asdfGenerator {
    // Returns the numerical data used to create the token
    function _tokenURI(uint tokenId) internal view returns (string memory){
        return Renderer.render(_assembleParams(tokenId));
    }
    function _getTokenRawData(uint256 tokenId) internal view returns(int[28][28] memory){
        require(initSeed != 0, "Tokens not yet revealed");
        return Renderer.getRaw(_assembleParams(tokenId));
    }
    
    // Returns the numerical data used to create the token, including points of interest
    function _getTokenRawDataWithPOIs(uint256 tokenId) internal view returns(int[28][28] memory){
        require(initSeed != 0, "Tokens not yet revealed");

        return Renderer.getRawWithPOIs(_assembleParams(tokenId));
    }

    // Returns a 2d array representing up to 5 points of interest
    // [0-9 value representing POI, xPos, yPos]
    function _getTokenPointsOfInterest(uint256 tokenId) internal view returns (uint[3][5] memory){
        require(initSeed != 0, "Tokens not yet revealed");

        uint POIs = _placePointsOfInterest(tokenId, _getRawPointsOfInterest(tokenId));
        uint cur;
        uint count = 0;
        uint[3][5] memory result;
        //console.log("POIs are %s", POIs);
        while (POIs > 0){
            cur = POIs % 100000; // Isolate first 5 digits, i.e., first POI
            //console.log("Current POI is %s", cur);
            result[count] = [cur / 10000, (cur / 100) % 100, cur % 100]; // [0-9 value representing POI, POI xcoord, POI ycoord]
            count += 1;
            POIs = POIs / 100000;
        }
        return result;
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

import "./asdfAccessControl.sol";
import "./Renderer.sol";

contract asdfGenerator is asdfAccessControl{
    uint256[7] private layerDimensions = [4, 24, 32, 64, 32, 24, 4];
    int256[8] private topology = [int(18000), int(12000), int(4000), -4000, -12000, -20000, -22000, -26000];
    
    string[9] private forest1 = ["O", "o", ".", "_", "+", "-", ">", "}", "~"];
    string[9] private forest2 = ["Y", "T", "^", "+", "=", "-", "*", "_", "."];
    string[9] private mntain1 = ["^", "+", ".", "#", "-", "_", ">", "}", "~"];
    string[9] private mntain2 = ["^", "~", "%", "-", "_", "*", "o", "~", "."];
    string[9] private placeholder1 = ["Y", "T", "^", "+", "=", "-", "*", "_", "."];
    string[9] private placeholder2 = ["^", "+", ".", "#", "-", "_", ">", "}", "~"];
    string[9] private placeholder3 = ["^", "~", "%", "-", "_", "*", "o", "~", "."];
    string[6] private POIChars = ["D", "V", "@", "?", "M", "$"];
    
    string[9] private colors1 = ["#44a900", "#f2b732", "#433626", "#ed5d20", "#786b53", "#b25a1e", "#778385", "#85cfed", "#58859a"];
    string[9] private colors2 = ["#ebdbb2", "#786b53", "#f2b732", "#ed5d20", "#44a900", "#b25a1e", "#85cfed", "#58859a", "#58859a"];
    string[9] private colors3 = ["#9e744d", "#734c4d", "#cda074", "#720102", "#fecf75", "#734c4d", "#979797", "#58859a", "#58859a"];
    string[9] private colors4 = ["#ffffce", "#fecf75", "#720102", "#720102", "#9e744d", "#734c4d", "#979797", "#58859a", "#58859a"];
    string[9] private colors5 = ["#98971a", "#b8bb26", "#a89984", "#cc241d", "#8ec07c", "#689d6a", "#83a598", "#ebdbb2", "#ebdbb2"];
    string[9] private colors6 = ["#ebdbb2", "#928374", "#98971a", "#b8bb26", "#ac7a1a", "#8ec07c", "#689d6a", "#a89984", "#a89984"];
    string[9] private grscale = ["#ffffff", "#e5e5e5", "#cccccc", "#b2b2b2", "#999999", "#4c4c4c", "#323232", "#191919", "#191919"];
    string[9] private drkness = ["#ffffff", "#e5e5e5", "#cccccc", "#b2b2b2", "#242424", "#121212", "#0c0c0c", "#060606", "#060606"];
    string[9] private fantasy = ["#50fa7b", "#ffb86c", "#ff5555", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#6272a4", "#6272a4"];
    
    // Assemble parameters for renderer
    function _assembleParams(uint tokenId) internal view returns(Renderer.Params memory){
        Renderer.Params memory params;
        params.tokenId = tokenId;
        params.layer = _getLayer(tokenId);
        params.dim = layerDimensions[params.layer];
        params.seed = explorerSeed;
        params.rawPOIs = _getRawPointsOfInterest(tokenId);
        params.POIs = _placePointsOfInterest(tokenId, params.rawPOIs);
        // HARDCODING 
        // THESE
        // FOR NOW
        params.chars = forest1; 
        params.cols = colors1;
        params.top = topology;
        params.poiChars = POIChars;
        return params;
    }

    // Determine how many points of interest are located in this map
    // Encoded as # POIs * 100000 plus 3 random digits for each POI
    function _getRawPointsOfInterest(uint tokenId) internal view returns(uint){
        uint POIs = uint(keccak256(abi.encodePacked(initSeed, explorerSeed, tokenId))) % 1000000000;
        if (POIs > 999500000){ // 0.05% get 5
            return POIs % 100000 + 500000;
        } else if (POIs > 979500000){ // 2% get 4
            return POIs % 10000 + 400000;
        } else if (POIs > 929500000){ // 5% get 3
            return POIs % 1000 + 300000;
        } else if (POIs > 679500000){ // 25% get 2
            return POIs % 100 + 200000;
        }
        return 0; // Remainder do not contain POIs
    }
      
    function _placePointsOfInterest(uint tokenId, uint rawPOIs) internal view returns (uint){
        uint nPOIs = rawPOIs / 100000;
        uint placementValidated;
        uint nonce;
        uint px;
        uint py;
        uint duplicateFound;
        uint[5] memory placed;
        uint result = 0;

        for (uint p; p < nPOIs; p++){
            placementValidated = 0;
            while(placementValidated == 0){ 
                nonce = nonce + 1;

                // Choose a spot on the grid, mod 22 + 3 to stay away from edges
                px = 3 + uint(keccak256(abi.encodePacked(tokenId, initSeed, nonce, "px"))) % 22;
                py = 3 + uint(keccak256(abi.encodePacked(tokenId, initSeed, nonce, "py"))) % 22;

                // Check if a POI is already placed in this row or column
                duplicateFound = 0;
                for(uint i = 0; i < 5; i++){
                    if(placed[i] / 100 == px || placed[i] % 100 == py){
                        duplicateFound = 1;
                    }
                }

                // If valid, add to result. each 5 digits of result represent: type of POI[0-9], 2-digit xcoord[0-27] and 2-digit ycoord[0-27]
                if (duplicateFound == 0){
                    placed[p] = px * 100 + py; // Note that we've placed something in this square
                    result = (result * 100000) + (rawPOIs % 10) * 10000 + px * 100 + py;
                    placementValidated = 1;
                }
            }
            rawPOIs = rawPOIs / 10;
        }
        //console.log("POI generation result is %s", result);
        return result;
    }

    // Determine which layer of the world this map is on
    function _getLayer(uint tokenId) internal view returns (uint){
        uint placement = (initSeed + tokenId) % MAX_SUPPLY;
        // Determine layer
        if (placement > 7312){
            return 6;
        } else if (placement > 7296){
            return 0;
        } else if (placement > 6720){
            return 5;
        } else if (placement > 6144){
            return 1;
        } else if (placement > 5120){
            return 4;
        } else if (placement > 4096){
            return 2;
        } else {
            return 3;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract asdfAccessControl is ReentrancyGuard, Ownable {
    address internal _Loot = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7; // To check for Loot ownership
    uint256 presale = 1; // To start, loot holders only
    uint paused = 0;
    uint public INIT_TIMESTAMP;
    uint public REVEAL_TIMESTAMP;
    uint public initSeed;
    uint public seedBlock;
    uint public explorerSeed;
    uint immutable MAX_SUPPLY = 7328;
    
    constructor() Ownable() {
        INIT_TIMESTAMP = block.timestamp;
        REVEAL_TIMESTAMP = INIT_TIMESTAMP; // + 2 hours; // tokenURIs revealed 2hrs after deployment
    }
    // Pause or unpause minting
    function togglePause() public onlyOwner {
        paused = (paused + 1) % 2;
    }

    // Toggle exclusivity for loot holders
    function endPresale() public onlyOwner {
        presale = (presale + 1) % 2;
    }

    // After all tokens are minted or two hours elapse
    // Anyone can make the tokenURIs available by setting the random seed
    function finalizeSeed() public onlyOwner{
        require(initSeed == 0, "Seed is already set");
        require(seedBlock != 0, "Seed block must be set");

        initSeed = uint(blockhash(seedBlock)) % MAX_SUPPLY;
        if (block.number - seedBlock > 255) {
            initSeed = uint(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
    }
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./ToString.sol";
import "./asdfnum.sol";

library Renderer {

    // Struct for passing token information from main to renderer
    struct Params {
        uint         tokenId;
        uint             dim; // Dimensions of map
        uint            seed; // Starting value
        uint            POIs; // Points of interest on map
        uint         rawPOIs; // Raw POI data
        uint           layer; // Where are we in 3d space
        int[8]           top; // Topology for determining character
        string[9]       cols; // Colors
        string[9]      chars; // Characters for topology
        string[6]   poiChars; // Characters for POIs
    }
    
    // Struct for tracking state of the renderer
    struct Context {
        uint              xPos; // X position on the map
        uint              yPos; // Y position on the map
        uint               val; // Current character being drawn
        uint              last; // Last character drawn
        uint[6]      POICounts;
        string        stringId; // String of tokenId
        string       POIString;
        string           class;
        string            char;
        string[33]   rowBuffer; // Buffer for compiling svg rows
        string[30]   svgBuffer; // Buffer for compiling svg
        string[6]     POINames;
        string[7] layerToRealm;
    }
    
    uint constant step = 6619;
    // Translate the topology value to the corresponding character
    // Returns an index into Params.poiChars, which renderer will take mod 9
    function getChar(int256 value, int[8] memory topology) internal pure returns (uint) {
        // POIs are represented by values >= 70000, least significant digit represents type of POI
        // Check if we have a POI and translate to an index. Index will be % 9 to translate to index of Params.poiChars
        if (value > 69999){
            if (value == 70009){
                    return 14;
            } else if (value == 70008){
                return 13;
            } else if (value > 70005){
                return 12;
            } else if (value > 70003){
                return 11;
            } else if (value > 70001){
                return 10;
            } else {
                return 9;
            }
        } else { // No POI, check where this value is in the topology gradient. Return index into Params.chars
            for (uint i = 0; i < 8; i++){
                if (value > topology[i]){
                    return i;
                }
            }
        }
        return 8;
    }

    // Get the raw data for the token without points of interest
    // Returns grid of raw topology data without POIs
    function getRaw(Params memory params) public pure returns (int[28][28] memory){
        int[28][28] memory result;
    	uint xPos;
    	uint yPos = params.seed + (params.tokenId % params.dim) * 28 * step; // Starting Y on the world map
    	for (uint i = 0; i < 28; i++){
    	    xPos = params.seed + params.tokenId / params.dim * 28 * step; // Reset X for row alignment
    	    for (uint j = 0; j < 28; j++) {
    	    	result[i][j] = asdfnum.noise3d(int(yPos), int(xPos), int(params.layer * step)); // get value in 3d space
    	    	xPos += step;
    	    }
            yPos += step;
    	}
    	return result;
    }

    // Get the raw data for the token with points of interest
    // Returns grid of raw topology data with POIs
    function getRawWithPOIs(Params memory params) public pure returns (int[28][28] memory){
        // Start with plain raw data
        int[28][28] memory result = getRaw(params);
        uint POIs = params.POIs;
        uint cur;
        uint row;
        uint col;
        
        // POIs has 25 digits representing 5 possible POIs.
        // Each 5 digits of result represent: 
        // - type of POI[0-9]  (10000s)
        // - 2-digit xcoord[0-27] (1000s and 100s) and 
        // - 2-digit ycoord[0-27] (10s and 1s)
        while (POIs > 0){
            cur = POIs % 100000; // Isolate first 5 digits, i.e., first POI
            row = (cur / 100) % 100;
            col = cur % 100;
            result[row][col] = int(70000 + cur / 10000); // Return 70000 because it exceeds topology bounds, plus the value of the POI
            // Set the surrounding tiles to 0
            result[row-1][col] = 5000;
            result[row+1][col] = 5000;
            result[row][col-1] = 5000;
            result[row][col+1] = 5000;
            POIs = POIs / 100000;
        }
        return result;
    }

    // Render a 28x28 SVG for the TokenURI
    // Returns a TokenURI string
    function render(Params memory params) public pure returns (string memory){
        string[10] memory classes = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
        int[28][28] memory noise = getRawWithPOIs(params);
        Context memory context; 
        context.stringId = ToString.toString(params.tokenId);

        // Start SVG
        // Create style set to minimize chars used for inline styling
        context.svgBuffer[0] = string(abi.encodePacked('<svg viewBox="0 0 270 450" preserveAspectRatio="xMinYMin" xmlns="http://www.w3.org/2000/svg" font-size="16px" font-weight="bold" font-family="monospace"><rect width="100%" height="100%" fill="black" />'
                                    '<style>.a{fill:', 
                                    params.cols[0], 
                                    '}.b{fill:', 
                                    params.cols[1],
                                    '}.c{fill:', 
                                    params.cols[2], 
                                    '}.d{fill:', 
                                    params.cols[3], 
                                    '}.e{fill:', 
                                    params.cols[4], 
                                    '}.f{fill:',
                                    params.cols[5],
                                    '}.g{fill:', 
                                    params.cols[6], 
                                    '}.h{fill:', 
                                    params.cols[7],
                                    '}.i{fill:', 
                                    params.cols[8],
                                    '}.j{fill:#ff0000}</style>'));

        uint col;
        for (uint row = 0; row < 28; row++){
            // Start SVG row with a <text> element
            context.rowBuffer[0] = '<text y="';
            context.rowBuffer[1] = ToString.toString((row + 1) * 16);
            context.rowBuffer[2] = '">';
            // Encode each char in the row in a <tspan>
            for (col = 0; col < 28; col++){
                context.val = getChar(noise[row][col], params.top);
                if (context.val > 8){
                    context.char = params.poiChars[context.val % 9];
                    context.class = classes[9]; 
                } else {
                    context.char = params.chars[context.val];
                    context.class = classes[context.val];
                }
                if (col == 0){ // New row
                    context.rowBuffer[3 + col] =
                        string(abi.encodePacked('<tspan class="', context.class, '">', context.char));
                } else if (context.last == context.val && context.val < 9) { // Repeat char, don't make new <tspan>
                    context.rowBuffer[3 + col] = context.char;
                } else { // New char, close last tspan and make a new one
                    context.rowBuffer[3 + col] =
                        string(abi.encodePacked('</tspan><tspan class="', context.class, '">', context.char));
                }
                context.last = context.val; // Remember last character
    	    }
    	    context.rowBuffer[4 + col] = '</tspan></text>'; // Row finished, close the tags

            // Compile the row into the SVG buffer, part 1 of 4
    	    context.svgBuffer[1 + row] = string(abi.encodePacked(
                                                    context.rowBuffer[0],
                                                    context.rowBuffer[1],
                                                    context.rowBuffer[2],
                                                    context.rowBuffer[3],
                                                    context.rowBuffer[4],
                                                    context.rowBuffer[5],
                                                    context.rowBuffer[6],
                                                    context.rowBuffer[7], 
                                                    context.rowBuffer[8]));

            // Compile the row into the SVG buffer, part 2 of 4
    	    context.svgBuffer[1 + row] = string(abi.encodePacked(
                                                    context.svgBuffer[1+row],
                                                    context.rowBuffer[9],
                                                    context.rowBuffer[10],
                                                    context.rowBuffer[11],
                                                    context.rowBuffer[12],
                                                    context.rowBuffer[13],
                                                    context.rowBuffer[14],
                                                    context.rowBuffer[15], 
                                                    context.rowBuffer[16]));
                                        
            // Compile the row into the SVG buffer, part 3 of 4
    	    context.svgBuffer[1 + row] = string(abi.encodePacked(
                                                    context.svgBuffer[1+row],
                                                    context.rowBuffer[17],
                                                    context.rowBuffer[18],
                                                    context.rowBuffer[19],
                                                    context.rowBuffer[20],
                                                    context.rowBuffer[21],
                                                    context.rowBuffer[22],
                                                    context.rowBuffer[23], 
                                                    context.rowBuffer[24]));

            // Compile the row into the SVG buffer, part 4 of 4
    	    context.svgBuffer[1 + row] = string(abi.encodePacked(
                                                    context.svgBuffer[1+row],
                                                    context.rowBuffer[25],
                                                    context.rowBuffer[26],
                                                    context.rowBuffer[27],
                                                    context.rowBuffer[28],
                                                    context.rowBuffer[29],
                                                    context.rowBuffer[30],
                                                    context.rowBuffer[31], 
                                                    context.rowBuffer[32]));
    	}

        // Done assembling rows
    	context.svgBuffer[29] = '</svg>';
        
        // Assemble SVG, part 1 of 4
        string memory output = string(abi.encodePacked(
                                            context.svgBuffer[0],
                                            context.svgBuffer[1],
                                            context.svgBuffer[2],
                                            context.svgBuffer[3],
                                            context.svgBuffer[4],
                                            context.svgBuffer[5],
                                            context.svgBuffer[6],
                                            context.svgBuffer[7],
                                            context.svgBuffer[8],
                                            context.svgBuffer[9]));

        // Assemble SVG, part 2 of 4
        output = string(abi.encodePacked(
                                output, 
                                context.svgBuffer[10],
                                context.svgBuffer[11],
                                context.svgBuffer[12],
                                context.svgBuffer[13],
                                context.svgBuffer[14],
                                context.svgBuffer[15],
                                context.svgBuffer[16],
                                context.svgBuffer[17], 
                                context.svgBuffer[18]));

        // Assemble SVG, part 3 of 4
        output = string(abi.encodePacked(
                                output, 
                                context.svgBuffer[19],
                                context.svgBuffer[20],
                                context.svgBuffer[21],
                                context.svgBuffer[22],
                                context.svgBuffer[23],
                                context.svgBuffer[24],
                                context.svgBuffer[25],
                                context.svgBuffer[26], 
                                context.svgBuffer[27]));

        // Assemble SVG, part 4 of 4
        output = string(abi.encodePacked(
                                output, 
                                context.svgBuffer[28],
                                context.svgBuffer[29]));
        context.layerToRealm = ["Layer1", "Layer2", "Layer3", "Layer4", "Layer5", "Layer6", "Layer7"];
        context.POINames = ["Dungeon", "Town", "Travel", "NPC", "Monster", "Treasure"];
        uint rawPOIs = params.rawPOIs;
        for (uint p = 0; p < params.rawPOIs / 100000; p++){
            context.POICounts[(rawPOIs % 10) % 6] += 1;
            rawPOIs = rawPOIs / 10;
        }
        for (uint q = 0; q < 6; q++){
            if (context.POICounts[q] > 0){
                context.POIString = string(abi.encodePacked(
                    context.POIString,
                    '{"trait_type":"Contains", "value":"',
                    context.POINames[q],
                    '"},'
                ));
            }
        }

        string memory attributes = string(abi.encodePacked(
                '{"name":"asdf #', 
                context.stringId, 
                '","description": "asdf are world maps generated entirley on chain. Legends and other markers are omitted for others to interpret. Use asdf in any way you want.", "attributes": [{"trait_type":"Realm","value":"',
                context.layerToRealm[params.layer], 
                '"},',
                context.POIString,
                '{"trait_type":"Points of Interest","value":"', 
                ToString.toString(params.rawPOIs / 100000), 
                '"}], "image": "data:image/svg+xml;base64,'
        ));

        // Assemble TokenURI json
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
                attributes, 
                Base64.encode(bytes(output)), 
                '"}'))));

        // Encode to base64
        output = string(abi.encodePacked('data:application/json;base64,', json));
        //console.log("Final gas: %s", gasleft());
        return output;
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
pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ToString {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice An implementation of Perlin Noise that uses 16 bit fixed point arithmetic.
 */
library asdfnum {

    /**
     * @notice Computes the noise value for a 2D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    // function noise2d(int256 x, int256 y) public pure returns (int256) {
    //     int256 temp = ptable(x >> 16 & 0xff /* Unit square X */);

    //     int256 a = ptable((temp >> 8  ) + (y >> 16 & 0xff /* Unit square Y */));
    //     int256 b = ptable((temp & 0xff) + (y >> 16 & 0xff                    ));

    //     x &= 0xffff; // Square relative X
    //     y &= 0xffff; // Square relative Y

    //     int256 u = fade(x);

    //     int256 c = lerp(u, grad2(a >> 8  , x, y        ), grad2(b >> 8  , x-0x10000, y        ));
    //     int256 d = lerp(u, grad2(a & 0xff, x, y-0x10000), grad2(b & 0xff, x-0x10000, y-0x10000));

    //     return lerp(fade(y), c, d);
    // }

    /**
     * @notice Computes the noise value for a 3D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     * @param z the z coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise3d(int256 x, int256 y, int256 z) public pure returns (int256) {
        int256[7] memory scratch = [
            x >> 16 & 0xff,  // Unit cube X
            y >> 16 & 0xff,  // Unit cube Y
            z >> 16 & 0xff,  // Unit cube Z
            0, 0, 0, 0
        ];

        x &= 0xffff; // Cube relative X
        y &= 0xffff; // Cube relative Y
        z &= 0xffff; // Cube relative Z

        // Temporary variables used for intermediate calculations.
        int256 u;
        int256 v;

        v = ptable(scratch[0]);

        u = ptable((v >> 8  ) + scratch[1]);
        v = ptable((v & 0xff) + scratch[1]);

        scratch[3] = ptable((u >> 8  ) + scratch[2]);
        scratch[4] = ptable((u & 0xff) + scratch[2]);
        scratch[5] = ptable((v >> 8  ) + scratch[2]);
        scratch[6] = ptable((v & 0xff) + scratch[2]);

        int256 a;
        int256 b;
        int256 c;

        u = fade(x);
        v = fade(y);

        a = lerp(u, grad3(scratch[3] >> 8, x, y        , z), grad3(scratch[5] >> 8, x-0x10000, y        , z));
        b = lerp(u, grad3(scratch[4] >> 8, x, y-0x10000, z), grad3(scratch[6] >> 8, x-0x10000, y-0x10000, z));
        c = lerp(v, a, b);

        a = lerp(u, grad3(scratch[3] & 0xff, x, y        , z-0x10000), grad3(scratch[5] & 0xff, x-0x10000, y        , z-0x10000));
        b = lerp(u, grad3(scratch[4] & 0xff, x, y-0x10000, z-0x10000), grad3(scratch[6] & 0xff, x-0x10000, y-0x10000, z-0x10000));

        return lerp(fade(z), c, lerp(v, a, b));
    }

    /**
     * @notice Computes the linear interpolation between two values, `a` and `b`, using fixed point arithmetic.
     *
     * @param t the time value of the equation.
     * @param a the lower point.
     * @param b the upper point.
     */
    function lerp(int256 t, int256 a, int256 b) internal pure returns (int256) {
        return a + (t * (b - a) >> 12);
    }

    /**
     * @notice Applies the fade function to a value.
     *
     * @param t the time value of the equation.
     *
     * @dev The polynomial for this function is: 6t^4-15t^4+10t^3.
     */
    function fade(int256 t) internal pure returns (int256) {
        int256 n = ftable(t >> 8);

        // Lerp between the two points grabbed from the fade table.
        (int256 lower, int256 upper) = (n >> 12, n & 0xfff);
        return lower + ((t & 0xff) * (upper - lower) >> 8);
    }

    /**
      * @notice Computes the gradient value for a 2D point.
      *
      * @param h the hash value to use for picking the vector.
      * @param x the x coordinate of the point.
      * @param y the y coordinate of the point.
      */
    // function grad2(int256 h, int256 x, int256 y) internal pure returns (int256) {
    //     h &= 3;

    //     int256 u;
    //     if (h & 0x1 == 0) {
    //         u = x;
    //     } else {
    //         u = -x;
    //     }

    //     int256 v;
    //     if (h < 2) {
    //         v = y;
    //     } else {
    //         v = -y;
    //     }

    //     return u + v;
    // }

    /**
     * @notice Computes the gradient value for a 3D point.
     *
     * @param h the hash value to use for picking the vector.
     * @param x the x coordinate of the point.
     * @param y the y coordinate of the point.
     * @param z the z coordinate of the point.
     */
    function grad3(int256 h, int256 x, int256 y, int256 z) internal pure returns (int256) {
        h &= 0xf;

        int256 u;
        if (h < 8) {
            u = x;
        } else {
            u = y;
        }

        int256 v;
        if (h < 4) {
            v = y;
        } else if (h == 12 || h == 14) {
            v = x;
        } else {
            v = z;
        }

        if ((h & 0x1) != 0) {
            u = -u;
        }

        if ((h & 0x2) != 0) {
            v = -v;
        }

        return u + v;
    }

    /**
     * @notice Gets a subsequent values in the permutation table at an index. The values are encoded
     *         into a single 24 bit integer with the  value at the specified index being the most
     *         significant 12 bits and the subsequent value being the least significant 12 bits.
     *
     * @param i the index in the permutation table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(255).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ptable' script.
     */
    function ptable(int256 i) internal pure returns (int256) {
        i &= 0xff;

        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 38816; } else { return 41097; }
                                } else {
                                    if (i == 2) { return 35163; } else { return 23386; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 23055; } else { return 3971; }
                                } else {
                                    if (i == 6) { return 33549; } else { return 3529; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 51551; } else { return 24416; }
                                } else {
                                    if (i == 10) { return 24629; } else { return 13762; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 49897; } else { return 59655; }
                                } else {
                                    if (i == 14) { return 2017; } else { return 57740; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 35876; } else { return 9319; }
                                } else {
                                    if (i == 18) { return 26398; } else { return 7749; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 17806; } else { return 36360; }
                                } else {
                                    if (i == 22) { return 2147; } else { return 25381; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 9712; } else { return 61461; }
                                } else {
                                    if (i == 26) { return 5386; } else { return 2583; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 6078; } else { return 48646; }
                                } else {
                                    if (i == 30) { return 1684; } else { return 38135; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 63352; } else { return 30954; }
                                } else {
                                    if (i == 34) { return 59979; } else { return 19200; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 26; } else { return 6853; }
                                } else {
                                    if (i == 38) { return 50494; } else { return 15966; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 24316; } else { return 64731; }
                                } else {
                                    if (i == 42) { return 56267; } else { return 52085; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 29987; } else { return 8971; }
                                } else {
                                    if (i == 46) { return 2848; } else { return 8249; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 14769; } else { return 45345; }
                                } else {
                                    if (i == 50) { return 8536; } else { return 22765; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 60821; } else { return 38200; }
                                } else {
                                    if (i == 54) { return 14423; } else { return 22446; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 44564; } else { return 5245; }
                                } else {
                                    if (i == 58) { return 32136; } else { return 34987; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 43944; } else { return 43076; }
                                } else {
                                    if (i == 62) { return 17583; } else { return 44874; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 19109; } else { return 42311; }
                                } else {
                                    if (i == 66) { return 18310; } else { return 34443; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 35632; } else { return 12315; }
                                } else {
                                    if (i == 70) { return 7078; } else { return 42573; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 19858; } else { return 37534; }
                                } else {
                                    if (i == 74) { return 40679; } else { return 59219; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 21359; } else { return 28645; }
                                } else {
                                    if (i == 78) { return 58746; } else { return 31292; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 15571; } else { return 54149; }
                                } else {
                                    if (i == 82) { return 34278; } else { return 59100; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 56425; } else { return 26972; }
                                } else {
                                    if (i == 86) { return 23593; } else { return 10551; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 14126; } else { return 12021; }
                                } else {
                                    if (i == 90) { return 62760; } else { return 10484; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 62566; } else { return 26255; }
                                } else {
                                    if (i == 94) { return 36662; } else { return 13889; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 16665; } else { return 6463; }
                                } else {
                                    if (i == 98) { return 16289; } else { return 41217; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 472; } else { return 55376; }
                                } else {
                                    if (i == 102) { return 20553; } else { return 18897; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 53580; } else { return 19588; }
                                } else {
                                    if (i == 106) { return 33979; } else { return 48080; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 53337; } else { return 22802; }
                                } else {
                                    if (i == 110) { return 4777; } else { return 43464; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 51396; } else { return 50311; }
                                } else {
                                    if (i == 114) { return 34690; } else { return 33396; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 29884; } else { return 48287; }
                                } else {
                                    if (i == 118) { return 40790; } else { return 22180; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 42084; } else { return 25709; }
                                } else {
                                    if (i == 122) { return 28102; } else { return 50861; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 44474; } else { return 47619; }
                                } else {
                                    if (i == 126) { return 832; } else { return 16436; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 13529; } else { return 55778; }
                                } else {
                                    if (i == 130) { return 58106; } else { return 64124; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 31867; } else { return 31493; }
                                } else {
                                    if (i == 134) { return 1482; } else { return 51750; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9875; } else { return 37750; }
                                } else {
                                    if (i == 138) { return 30334; } else { return 32511; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 65362; } else { return 21077; }
                                } else {
                                    if (i == 142) { return 21972; } else { return 54479; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 53198; } else { return 52795; }
                                } else {
                                    if (i == 146) { return 15331; } else { return 58159; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 12048; } else { return 4154; }
                                } else {
                                    if (i == 150) { return 14865; } else { return 4534; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 46781; } else { return 48412; }
                                } else {
                                    if (i == 154) { return 7210; } else { return 10975; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 57271; } else { return 47018; }
                                } else {
                                    if (i == 158) { return 43733; } else { return 54647; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 30712; } else { return 63640; }
                                } else {
                                    if (i == 162) { return 38914; } else { return 556; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 11418; } else { return 39587; }
                                } else {
                                    if (i == 166) { return 41798; } else { return 18141; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 56729; } else { return 39269; }
                                } else {
                                    if (i == 170) { return 26011; } else { return 39847; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 42795; } else { return 11180; }
                                } else {
                                    if (i == 174) { return 44041; } else { return 2433; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 33046; } else { return 5671; }
                                } else {
                                    if (i == 178) { return 10237; } else { return 64787; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 4962; } else { return 25196; }
                                } else {
                                    if (i == 182) { return 27758; } else { return 28239; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 20337; } else { return 29152; }
                                } else {
                                    if (i == 186) { return 57576; } else { return 59570; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 45753; } else { return 47472; }
                                } else {
                                    if (i == 190) { return 28776; } else { return 26842; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 56054; } else { return 63073; }
                                } else {
                                    if (i == 194) { return 25060; } else { return 58619; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 64290; } else { return 8946; }
                                } else {
                                    if (i == 198) { return 62145; } else { return 49646; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 61138; } else { return 53904; }
                                } else {
                                    if (i == 202) { return 36876; } else { return 3263; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 49075; } else { return 45986; }
                                } else {
                                    if (i == 206) { return 41713; } else { return 61777; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 20787; } else { return 13201; }
                                } else {
                                    if (i == 210) { return 37355; } else { return 60409; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 63758; } else { return 3823; }
                                } else {
                                    if (i == 214) { return 61291; } else { return 27441; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 12736; } else { return 49366; }
                                } else {
                                    if (i == 218) { return 54815; } else { return 8117; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 46535; } else { return 51050; }
                                } else {
                                    if (i == 222) { return 27293; } else { return 40376; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 47188; } else { return 21708; }
                                } else {
                                    if (i == 226) { return 52400; } else { return 45171; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 29561; } else { return 31026; }
                                } else {
                                    if (i == 230) { return 12845; } else { return 11647; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 32516; } else { return 1174; }
                                } else {
                                    if (i == 234) { return 38654; } else { return 65162; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 35564; } else { return 60621; }
                                } else {
                                    if (i == 238) { return 52573; } else { return 24030; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 56946; } else { return 29251; }
                                } else {
                                    if (i == 242) { return 17181; } else { return 7448; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 6216; } else { return 18675; }
                                } else {
                                    if (i == 246) { return 62349; } else { return 36224; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 32963; } else { return 49998; }
                                } else {
                                    if (i == 250) { return 20034; } else { return 17111; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 55101; } else { return 15772; }
                                } else {
                                    if (i == 254) { return 40116; } else { return 46231; }
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    /**
     * @notice Gets subsequent values in the fade table at an index. The values are encoded
     *         into a single 16 bit integer with the value at the specified index being the most
     *         significant 8 bits and the subsequent value being the least significant 8 bits.
     *
     * @param i the index in the fade table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(256).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ftable' script.
     */
    function ftable(int256 i) internal pure returns (int256) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 0; } else { return 0; }
                                } else {
                                    if (i == 2) { return 0; } else { return 0; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 0; } else { return 0; }
                                } else {
                                    if (i == 6) { return 0; } else { return 1; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 4097; } else { return 4098; }
                                } else {
                                    if (i == 10) { return 8195; } else { return 12291; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 12292; } else { return 16390; }
                                } else {
                                    if (i == 14) { return 24583; } else { return 28681; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 36874; } else { return 40972; }
                                } else {
                                    if (i == 18) { return 49166; } else { return 57361; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 69651; } else { return 77846; }
                                } else {
                                    if (i == 22) { return 90137; } else { return 102429; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 118816; } else { return 131108; }
                                } else {
                                    if (i == 26) { return 147496; } else { return 163885; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 184369; } else { return 200758; }
                                } else {
                                    if (i == 30) { return 221244; } else { return 245825; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 266311; } else { return 290893; }
                                } else {
                                    if (i == 34) { return 315476; } else { return 344155; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 372834; } else { return 401513; }
                                } else {
                                    if (i == 38) { return 430193; } else { return 462969; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 495746; } else { return 532619; }
                                } else {
                                    if (i == 42) { return 569492; } else { return 606366; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 647335; } else { return 684210; }
                                } else {
                                    if (i == 46) { return 729276; } else { return 770247; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 815315; } else { return 864478; }
                                } else {
                                    if (i == 50) { return 909546; } else { return 958711; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 1011971; } else { return 1061137; }
                                } else {
                                    if (i == 54) { return 1118494; } else { return 1171756; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 1229114; } else { return 1286473; }
                                } else {
                                    if (i == 58) { return 1347928; } else { return 1409383; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 1470838; } else { return 1532294; }
                                } else {
                                    if (i == 62) { return 1597847; } else { return 1667496; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 1737145; } else { return 1806794; }
                                } else {
                                    if (i == 66) { return 1876444; } else { return 1950190; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 2023936; } else { return 2097683; }
                                } else {
                                    if (i == 70) { return 2175526; } else { return 2253370; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 2335309; } else { return 2413153; }
                                } else {
                                    if (i == 74) { return 2495094; } else { return 2581131; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 2667168; } else { return 2753205; }
                                } else {
                                    if (i == 78) { return 2839243; } else { return 2929377; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 3019511; } else { return 3109646; }
                                } else {
                                    if (i == 82) { return 3203877; } else { return 3298108; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 3392339; } else { return 3486571; }
                                } else {
                                    if (i == 86) { return 3584899; } else { return 3683227; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 3781556; } else { return 3883981; }
                                } else {
                                    if (i == 90) { return 3986406; } else { return 4088831; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 4191257; } else { return 4297778; }
                                } else {
                                    if (i == 94) { return 4400204; } else { return 4506727; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 4617345; } else { return 4723868; }
                                } else {
                                    if (i == 98) { return 4834487; } else { return 4945106; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 5055725; } else { return 5166345; }
                                } else {
                                    if (i == 102) { return 5281060; } else { return 5391680; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 5506396; } else { return 5621112; }
                                } else {
                                    if (i == 106) { return 5735829; } else { return 5854641; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 5969358; } else { return 6088171; }
                                } else {
                                    if (i == 110) { return 6206983; } else { return 6321700; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 6440514; } else { return 6563423; }
                                } else {
                                    if (i == 114) { return 6682236; } else { return 6801050; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 6923959; } else { return 7042773; }
                                } else {
                                    if (i == 118) { return 7165682; } else { return 7284496; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 7407406; } else { return 7530316; }
                                } else {
                                    if (i == 122) { return 7653226; } else { return 7776136; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 7899046; } else { return 8021956; }
                                } else {
                                    if (i == 126) { return 8144866; } else { return 8267776; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 8390685; } else { return 8509499; }
                                } else {
                                    if (i == 130) { return 8632409; } else { return 8755319; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 8878229; } else { return 9001139; }
                                } else {
                                    if (i == 134) { return 9124049; } else { return 9246959; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9369869; } else { return 9492778; }
                                } else {
                                    if (i == 138) { return 9611592; } else { return 9734501; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 9853315; } else { return 9976224; }
                                } else {
                                    if (i == 142) { return 10095037; } else { return 10213851; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 10336760; } else { return 10455572; }
                                } else {
                                    if (i == 146) { return 10570289; } else { return 10689102; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 10807914; } else { return 10922631; }
                                } else {
                                    if (i == 150) { return 11041443; } else { return 11156159; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 11270875; } else { return 11385590; }
                                } else {
                                    if (i == 154) { return 11496210; } else { return 11610925; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 11721544; } else { return 11832163; }
                                } else {
                                    if (i == 158) { return 11942782; } else { return 12053400; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 12159923; } else { return 12270541; }
                                } else {
                                    if (i == 162) { return 12377062; } else { return 12479488; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 12586009; } else { return 12688434; }
                                } else {
                                    if (i == 166) { return 12790859; } else { return 12893284; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 12995708; } else { return 13094036; }
                                } else {
                                    if (i == 170) { return 13192364; } else { return 13290691; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 13384922; } else { return 13479153; }
                                } else {
                                    if (i == 174) { return 13573384; } else { return 13667614; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 13757748; } else { return 13847882; }
                                } else {
                                    if (i == 178) { return 13938015; } else { return 14024052; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 14110089; } else { return 14196126; }
                                } else {
                                    if (i == 182) { return 14282162; } else { return 14364101; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 14441945; } else { return 14523884; }
                                } else {
                                    if (i == 186) { return 14601727; } else { return 14679569; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 14753315; } else { return 14827061; }
                                } else {
                                    if (i == 190) { return 14900806; } else { return 14970456; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 15044200; } else { return 15109753; }
                                } else {
                                    if (i == 194) { return 15179401; } else { return 15244952; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 15306407; } else { return 15367862; }
                                } else {
                                    if (i == 198) { return 15429317; } else { return 15490771; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 15548129; } else { return 15605486; }
                                } else {
                                    if (i == 202) { return 15658748; } else { return 15716104; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 15765269; } else { return 15818529; }
                                } else {
                                    if (i == 206) { return 15867692; } else { return 15912760; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 15961923; } else { return 16006989; }
                                } else {
                                    if (i == 210) { return 16047960; } else { return 16093025; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 16129899; } else { return 16170868; }
                                } else {
                                    if (i == 214) { return 16207741; } else { return 16244614; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 16281486; } else { return 16314262; }
                                } else {
                                    if (i == 218) { return 16347037; } else { return 16375716; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 16404395; } else { return 16433074; }
                                } else {
                                    if (i == 222) { return 16461752; } else { return 16486334; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 16510915; } else { return 16531401; }
                                } else {
                                    if (i == 226) { return 16555982; } else { return 16576466; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 16592855; } else { return 16613339; }
                                } else {
                                    if (i == 230) { return 16629727; } else { return 16646114; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 16658406; } else { return 16674793; }
                                } else {
                                    if (i == 234) { return 16687084; } else { return 16699374; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 16707569; } else { return 16719859; }
                                } else {
                                    if (i == 238) { return 16728053; } else { return 16736246; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 16740344; } else { return 16748537; }
                                } else {
                                    if (i == 242) { return 16752635; } else { return 16760828; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 16764924; } else { return 16764925; }
                                } else {
                                    if (i == 246) { return 16769022; } else { return 16773118; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 16773119; } else { return 16777215; }
                                } else {
                                    if (i == 250) { return 16777215; } else { return 16777215; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 16777215; } else { return 16777215; }
                                } else {
                                    if (i == 254) { return 16777215; } else { return 16777215; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

