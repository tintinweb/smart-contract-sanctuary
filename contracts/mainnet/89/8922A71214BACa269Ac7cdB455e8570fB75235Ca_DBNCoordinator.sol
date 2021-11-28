//SPDX-License-Identifier: MIT
//Copyright 2021 Louis Sobel
pragma solidity ^0.8.0;

/*

    88888888ba,   88888888ba  888b      88 88888888888 888888888888
    88      `"8b  88      "8b 8888b     88 88               88
    88        `8b 88      ,8P 88 `8b    88 88               88
    88         88 88aaaaaa8P' 88  `8b   88 88aaaaa          88
    88         88 88""""""8b, 88   `8b  88 88"""""          88
    88         8P 88      `8b 88    `8b 88 88               88
    88      .a8P  88      a8P 88     `8888 88               88
    88888888Y"'   88888888P"  88      `888 88               88



https://dbnft.io
Generate NFTs by compiling the DBN language to EVM opcodes, then
deploying a contract that can render your art as a bitmap.

> Line 0 0 100 100
         ╱               
        ╱                
       ╱                 
      ╱                  
     ╱                   
    ╱                    
   ╱                     
  ╱                      
 ╱                       
╱                        
*/


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./DBNERC721Enumerable.sol"; 
import "./OpenSeaTradable.sol"; 
import "./OwnerSignedTicketRestrictable.sol"; 

import "./Drawing.sol";
import "./Token.sol";
import "./Serialize.sol";

/**
 * @notice Compile DBN drawings to Ethereum Virtual Machine opcodes and deploy the code as NFT art.
 * @dev This contract implements the ERC721 (including Metadata and Enumerable extensions)
 * @author Louis Sobel
 */
contract DBNCoordinator is Ownable, DBNERC721Enumerable, OpenSeaTradable, OwnerSignedTicketRestrictable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
     * @dev There's two ~types of tokenId out of the 10201 (101x101) total tokens
     *        - 101 "allowlisted ones" [0, 100]
     *        - And "Open" ones        [101, 10200]
     *      Minting of the allowlisted ones is through mintTokenId function
     *      Minting of the Open ones is through plain mint
     */
    uint256 private constant LAST_ALLOWLISTED_TOKEN_ID = 100;
    uint256 private constant LAST_TOKEN_ID = 10200;

    /**
     * @dev Event emitted when a a token is minted, linking the token ID
     *      to the address of the deployed drawing contract
     */
    event DrawingDeployed(uint256 tokenId, address addr);

    // Configuration
    enum ContractMode { AllowlistOnly, Open }
    ContractMode private _contractMode;
    uint256 private _mintPrice;
    string private _baseExternalURI;

    address payable public recipient;
    bool public recipientLocked;

    // Minting
    Counters.Counter private _tokenIds;
    mapping (uint256 => address) private _drawingAddressForTokenId;

    /**
     * @dev Initializes the contract
     * @param owner address to immediately transfer the contract to
     * @param baseExternalURI URL (like https//dbnft.io/dbnft/) to which
     *        tokenIDs will be appended to get the `external_URL` metadata field
     * @param openSeaProxyRegistry address of the opensea proxy registry, will
     *        be saved and queried in isAllowedForAll to facilitate opensea listing
     */
    constructor(
        address owner,
        string memory baseExternalURI,
        address payable _recipient,
        address openSeaProxyRegistry
    ) ERC721("Design By Numbers NFT", "DBNFT") {
        transferOwnership(owner);

        _baseExternalURI = baseExternalURI;
        _contractMode = ContractMode.AllowlistOnly;

        // first _open_ token id
        _tokenIds._value = LAST_ALLOWLISTED_TOKEN_ID + 1;

        // initial mint price
        _mintPrice = 0;

        // initial recipient
        recipient = _recipient;

        // set up the opensea proxy registry
        _setOpenSeaRegistry(openSeaProxyRegistry);
    }


    /******************************************************************************************
     *      _____ ____  _   _ ______ _____ _____ 
     *     / ____/ __ \| \ | |  ____|_   _/ ____|
     *    | |   | |  | |  \| | |__    | || |  __ 
     *    | |   | |  | | . ` |  __|   | || | |_ |
     *    | |___| |__| | |\  | |     _| || |__| |
     *     \_____\____/|_| \_|_|    |_____\_____|
     *
     * Functions for configuring / interacting with the contract itself
     */

    /**
     * @notice The current "mode" of the contract: either AllowlistOnly (0) or Open (1).
     *         In AllowlistOnly mode, a signed ticket is required to mint. In Open mode,
     *         minting is open to all.
     */
    function getContractMode() public view returns (ContractMode) {
        return _contractMode;
    }

    /**
     * @notice Moves the contract mode to Open. Only the owner can call this. Once the
     *         contract moves to Open, it cannot be moved back to AllowlistOnly
     */
    function openMinting() public onlyOwner {
        _contractMode = ContractMode.Open;
    }

    /**
     * @notice Returns the current cost to mint. Applies to either mode.
     *         (And of course, this does not include gas ⛽️)
     */
    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    /**
     * @notice Sets the cost to mint. Only the owner can call this.
     */
    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    /**
     * @notice Sets the recipient. Cannot be called after the recipient is locked.
     *         Only the owner can call this.
     */
    function setRecipient(address payable to) public onlyOwner {
        require(!recipientLocked, "RECIPIENT_LOCKED");
        recipient = to;
    }

    /**
     * @notice Prevents any future changes to the recipient.
     *         Only the owner can call this.
     * @dev This enables post-deploy configurability of the recipient,
     *      combined with the ability to lock it in to facilitate
     *      confidence as to where the funds will be able to go.
     */
    function lockRecipient() public onlyOwner {
        recipientLocked = true;
    }

    /**
     * @notice Disburses the contract balance to the stored recipient.
     *         Only the owner can call this.
     */
    function disburse() public onlyOwner {
        recipient.transfer(address(this).balance);
    }


    /******************************************************************************************
     *     __  __ _____ _   _ _______ _____ _   _  _____ 
     *    |  \/  |_   _| \ | |__   __|_   _| \ | |/ ____|
     *    | \  / | | | |  \| |  | |    | | |  \| | |  __ 
     *    | |\/| | | | | . ` |  | |    | | | . ` | | |_ |
     *    | |  | |_| |_| |\  |  | |   _| |_| |\  | |__| |
     *    |_|  |_|_____|_| \_|  |_|  |_____|_| \_|\_____|
     *
     * Functions for minting tokens!
     */

    /**
     * @notice Mints a token by deploying the given drawing bytecode
     * @param bytecode The bytecode of the drawing to mint a token for.
     *        This bytecode should have been created by the DBN Compiler, otherwise
     *        the behavior of this function / the subsequent token is undefined.
     *
     * Requires passed value of at least the current mint price.
     * Will revert if there are no more tokens available or if the current contract
     * mode is not yet Open.
     */
    function mint(bytes memory bytecode) public payable {
        require(_contractMode == ContractMode.Open, "NOT_OPEN");

        uint256 tokenId = _tokenIds.current();
        require(tokenId <= LAST_TOKEN_ID, 'SOLD_OUT');
        _tokenIds.increment();

        _mintAtTokenId(bytecode, tokenId);
    }

    /**
     * @notice Mints a token at the specific token ID by deploying the given drawing bytecode.
     *         Requires passing a ticket id and a signature generated by the contract owner
     *         granting permission for the caller to mint the specific token ID.
     * @param bytecode The bytecode of the drawing to mint a token for
     *        This bytecode should have been created by the DBN Compiler, otherwise
     *        the behavior of this function / the subsequent token is undefined.
     * @param tokenId The token ID to mint. Needs to be in the range [0, LAST_ALLOWLISTED_TOKEN_ID]
     * @param ticketId The ID of the ticket; included as part of the signed data
     * @param signature The bytes of the signature that must have been generated
     *        by the current owner of the contract.
     *
     * Requires passed value of at least the current mint price.
     */
    function mintTokenId(
        bytes memory bytecode,
        uint256 tokenId,
        uint256 ticketId,
        bytes memory signature
    ) public payable onlyWithTicketFor(tokenId, ticketId, signature) {
        require(tokenId <= LAST_ALLOWLISTED_TOKEN_ID, 'WRONG_TOKENID_RANGE');

        _mintAtTokenId(bytecode, tokenId);
    }

    /**
     * @dev Internal function that does the actual minting for both open and allowlisted mint
     * @param bytecode The bytecode of the drawing to mint a token for
     * @param tokenId The token ID to mint
     */
    function _mintAtTokenId(
        bytes memory bytecode,
        uint256 tokenId
    ) internal {
        require(msg.value >= _mintPrice, "WRONG_PRICE");

        // Deploy the drawing
        address addr = Drawing.deploy(bytecode, tokenId);

        // Link the token ID to the drawing address
        _drawingAddressForTokenId[tokenId] = addr;

        // Mint the token (to the sender)
        _safeMint(msg.sender, tokenId);

        emit DrawingDeployed(tokenId, addr);
    }


    /**
     * @notice Allows gas-less trading on OpenSea by safelisting the ProxyRegistry of the user
     * @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
     * @inheritdoc ERC721
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator) || _isOwnersOpenSeaProxy(owner, operator);
    }


    /******************************************************************************************
     *     _______ ____  _  ________ _   _   _____  ______          _____  ______ _____   _____  
     *    |__   __/ __ \| |/ /  ____| \ | | |  __ \|  ____|   /\   |  __ \|  ____|  __ \ / ____| 
     *       | | | |  | | ' /| |__  |  \| | | |__) | |__     /  \  | |  | | |__  | |__) | (___   
     *       | | | |  | |  < |  __| | . ` | |  _  /|  __|   / /\ \ | |  | |  __| |  _  / \___ \  
     *       | | | |__| | . \| |____| |\  | | | \ \| |____ / ____ \| |__| | |____| | \ \ ____) | 
     *       |_|  \____/|_|\_\______|_| \_| |_|  \_\______/_/    \_\_____/|______|_|  \_\_____/  
     *
     * Functions for reading / querying tokens
     */

    /**
     * @dev Helper that gets the address for a given token and reverts if it is not present
     * @param tokenId the token to get the address of
     */
    function _addressForToken(uint256 tokenId) internal view returns (address) {
        address addr = _drawingAddressForTokenId[tokenId];
        require(addr != address(0), "UNKNOWN_ID");

        return addr;
    }

    /**
     * @dev Helper that pulls together the metadata struct for a given token
     * @param tokenId the token to get the metadata for
     * @param addr the address of its drawing contract
     */
    function _getMetadata(uint256 tokenId, address addr) internal view returns (Token.Metadata memory) {
        string memory tokenIdAsString = tokenId.toString();

        return Token.Metadata(
            string(abi.encodePacked("DBNFT #", tokenIdAsString)),
            string(Drawing.description(addr)),
            string(abi.encodePacked(_baseExternalURI, tokenIdAsString)),
            uint256(uint160(addr)).toHexString()
        );
    }

    /**
     * @notice The ERC721 tokenURI of the given token as an application/json data URI
     * @param tokenId the token to get the tokenURI of
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        address addr = _addressForToken(tokenId);
        (, bytes memory bitmapData) = Drawing.render(addr);

        Token.Metadata memory metadata = _getMetadata(tokenId, addr);
        return Serialize.tokenURI(bitmapData, metadata);
    }

    /**
     * @notice Returns the metadata of the token, without the image data, as a JSON string
     * @param tokenId the token to get the metadata of
     */
    function tokenMetadata(uint256 tokenId) public view returns (string memory) {
        address addr = _addressForToken(tokenId);
        Token.Metadata memory metadata = _getMetadata(tokenId, addr);
        return Serialize.metadataAsJSON(metadata);
    }

    /**
     * @notice Returns the underlying bytecode of the drawing contract
     * @param tokenId the token to get the drawing bytecode of
     */
    function tokenCode(uint256 tokenId) public view returns (bytes memory) {
        address addr = _addressForToken(tokenId);
        return addr.code;
    }

    /**
     * @notice Renders the token and returns an estimate of the gas used and the bitmap data itself
     * @param tokenId the token to render
     */
    function renderToken(uint256 tokenId) public view returns (uint256, bytes memory) {
        address addr = _addressForToken(tokenId);
        return Drawing.render(addr);
    }

    /**
     * @notice Returns a list of which tokens in the [0, LAST_ALLOWLISTED_TOKEN_ID]
     *         have already been minted.
     */
    function mintedAllowlistedTokens() public view returns (uint256[] memory) {
        uint8 count = 0;
        for (uint8 i = 0; i <= LAST_ALLOWLISTED_TOKEN_ID; i++) {
            if (_exists(i)) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        count = 0;
        for (uint8 i = 0; i <= LAST_ALLOWLISTED_TOKEN_ID; i++) {
            if (_exists(i)) {
                result[count] = i;
                count++;
            }
        }

        return result;
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev Modified copy of OpenZeppelin ERC721 Enumerable.
 * 
 * Changes:
 *  - gets rid of _removeTokenFromAllTokensEnumeration: no burns (saves space)
 *  - adds public accessor for the allTokens array
 */
abstract contract DBNERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

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
        require(index < ERC721.balanceOf(owner), "OWNER_INDEX_OOB");
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
        require(index < DBNERC721Enumerable.totalSupply(), "GLOBAL_INDEX_OOB");
        return _allTokens[index];
    }

    /**
     * @notice Get a list of all minted tokens.
     * @dev No guarantee of order.
     */
    function allTokens() public view returns (uint256[] memory) {
        return _allTokens;
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

        if (to != from) {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// Based off of https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/
///   - but removes the _contractURI bits
///   - and makes it abstract
/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's
///      gas-less trading and contractURI support
abstract contract OpenSeaTradable {
    address private _proxyRegistry;

    /// @notice Returns the current OS proxyRegistry address registered
    function openSeaProxyRegistry() public view returns (address) {
        return _proxyRegistry;
    }

    /// @notice Helper allowing OpenSea gas-less trading by verifying who's operator
    ///         for owner
    /// @dev Allows to check if `operator` is owner's OpenSea proxy on eth mainnet / rinkeby
    ///      or to check if operator is OpenSea's proxy contract on Polygon and Mumbai
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function _isOwnersOpenSeaProxy(address owner, address operator) internal virtual view
        returns (bool)
    {
        address proxyRegistry_ = _proxyRegistry;

        // if we have a proxy registry
        if (proxyRegistry_ != address(0)) {
            address ownerProxy = ProxyRegistry(proxyRegistry_).proxies(owner);
            return ownerProxy == operator;
        }

        return false;
    }


    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal virtual {
        _proxyRegistry = proxyRegistryAddress;
    }
}

contract ProxyRegistry {
    mapping(address => address) public proxies;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev Implements a mixin that uses ECDSA cryptography to restrict token minting to "ticket"-holders.
 *      This allows off-chain, gasless allowlisting of minting.
 * 
 * A "Ticket" is a logical tuple of:
 *   - the Token ID
 *   - the address of a minter
 *   - the address of the token contract
 *   - a ticket ID (random number)
 * 
 * By signing this tuple, the owner of the contract can grant permission to a specific address
 * to mint a specific token ID at that specific token contract.
 */
abstract contract OwnerSignedTicketRestrictable is Ownable {
    // Mapping to enable (very basic) ticket revocation
    mapping (uint256 => bool) private _revokedTickets;

    /**
     * @dev Throws if the given signature, signed by the contract owner, does not grant
     *      the transaction sender a ticket to mint the given tokenId
     * @param tokenId the ID of the token to check
     * @param ticketId the ID of the ticket (included in signature)
     * @param signature the bytes of the signature to use for verification
     * 
     * This delegates straight into the checkTicket public function.
     */
    modifier onlyWithTicketFor(uint256 tokenId, uint256 ticketId, bytes memory signature) {
        checkTicket(msg.sender, tokenId, ticketId, signature);
        _;
    }

    /**
     * @notice Check the validity of a signature
     * @dev Throws if the given signature wasn't signed by the contract owner for the
     *      "ticket" described by address(this) and the passed parameters
     *      (or if the ticket ID is revoked)
     * @param minter the address of the minter in the ticket
     * @param tokenId the token ID of the ticket
     * @param ticketId the ticket ID
     * @param signature the bytes of the signature
     * 
     * Reuse of a ticket is prevented by existing controls preventing double-minting.
     */
    function checkTicket(
        address minter,
        uint256 tokenId,
        uint256 ticketId,
        bytes memory signature
    ) public view {
        bytes memory params = abi.encode(
            address(this),
            minter,
            tokenId,
            ticketId
        );
        address addr = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(params)),
            signature
        );

        require(addr == owner(), "BAD_SIGNATURE");
        require(!_revokedTickets[ticketId], "TICKET_REVOKED");
    }

    /**
     * @notice Revokes the given ticket IDs, preventing them from being used in the future
     * @param ticketIds the ticket IDs to revoke
     * @dev This can do nothing if the ticket ID has already been used, but
     *      this function gives an escape hatch for accidents, etc.
     */
    function revokeTickets(uint256[] calldata ticketIds) public onlyOwner {
        for (uint i=0; i<ticketIds.length; i++) {
            _revokedTickets[ticketIds[i]] = true;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BitmapHeader.sol";

/**
 * @dev Internal helper library to encapsulate interactions with a "Drawing" contract
 */
library Drawing {
    /**
     * @dev Deploys the given bytecode as a drawing contract
     * @param bytecode The bytecode to pass to the CREATE opcode
     *        Must have been generated by the DBN compiler for predictable results.
     * @param tokenId The tokenId to inject into the bytecode
     * @return the address of the newly created contract
     * 
     * Will also inject the given tokenID into the bytecode before deploy so that
     * It is available in the deployed contract's context via a codecopy.
     * 
     * The bytecode passed needs to be _deploy_ bytecode (so end up returning the
     * actual bytecode). If any issues occur with the CREATE the transaction
     * will fail with an assert (consuming all remaining gas). Detailed reasoning inline.
     */
    function deploy(bytes memory bytecode, uint256 tokenId) internal returns (address) {
        // First, inject the token id into the bytecode.
        // The end of the bytecode is [2 bytes token id][32 bytes ipfs hash]
        // (and we get the tokenID in in bigendian)
        // This clearly assumes some coordination with the compiler (leaving this space blank!)
        bytecode[bytecode.length - 32 - 2] = bytes1(uint8((tokenId & 0xFF00) >> 8));
        bytecode[bytecode.length - 32 - 1] = bytes1(uint8(tokenId & 0xFF));

        address addr;
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        /*
        if addr is zero, a few things could have happened:
            a) out-of-gas in the create (which gets forwarded [current*(63/64) - 32000])
            b) other exceptional halt (call stack too deep, invalid jump, etc)
            c) revert from the create

        in a): we should drain all existing gas and effectively bubble up the out of gas.
               this makes sure that gas estimators do the right thing
        in b): this is a nasty situation, so let's just drain away our gas anyway (true assert)
        in c): pretty much same as b) — this is a bug in the passed bytecode, and we should fail.
               that said, we _could_ check the μo return buffer for REVERT data, but no need for now. 

        So no matter what, we want to "assert" the addr is not zero
        */
        assert(addr != address(0));

        return addr;
    }

    /**
     * @dev Renders the specified drawing contract as a bitmap
     * @param addr The address of the drawing contract
     * @return an estimation of the gas used and the 10962 bytes of the bitmap
     * 
     * It calls the "0xBD" opcode of the drawing to get just the bitmap pixel data;
     * the bitmap header is generated within this calling contract. This is to ensure
     * that even if the deployed drawing doesn't conform to the DBN-drawing spec,
     * a valid bitmap will always be returned.
     * 
     * To further ensure that a valid bitmap is always returned, if the call
     * to the drawing contract reverts, a bitmap will still be returned
     * (though with the center pixel set to "55" to facilitate debugging)
     */ 
    function render(address addr) internal view returns (uint256, bytes memory) {
        uint bitmapLength = 10962;
        uint headerLength = 40 + 14 + 404;
        uint pixelDataLength = (10962 - headerLength);

        bytes memory result = new bytes(bitmapLength);
        bytes memory input = hex"BD";

        uint256 startGas = gasleft();

        BitmapHeader.writeTo(result);
        uint resultOffset = 0x20 + headerLength; // after the header (and 0x20 for the dynamic byte length)

        assembly {
            let success := staticcall(
                gas(),
                addr,
                add(input, 0x20),
                1,
                0, // return dst, but we're using the returnbuffer
                0  // return length (we're using the returnbuffer)
            )

            let dataDst := add(result, resultOffset)
            switch success
            case 1 {
                // Render call succeeded!
                // copy min(returndataize, pixelDataLength) from the returnbuffer
                // in happy path: returndatasize === pixeldatalength
                //   -> then great, either
                // unexpected (too little data): returndatasize < pixeldatalength
                //   -> then we mustn't copy too much from the buffer! (use returndatasize)
                // unexpected (too much data): returndatasize > pixeldatalength
                //   -> then we mustn't overflow our result! (use pixeldatalength)
                let copySize := returndatasize()
                if gt(copySize, pixelDataLength) {
                    copySize := pixelDataLength
                }
                returndatacopy(
                    dataDst, // dst offset
                    0,       // src offset
                    copySize // length
                )
            }
            case 0 {
                // Render call failed :/
                // Leave a little indicating pixel to hopefully help debugging
                mstore8(
                    add(dataDst, 5250), // location of the center pixel (50 * 104 + 50)
                    0x55
                )
            }
        }

        // this overestimates _some_, but that's fine
        uint256 endGas = gasleft();

        return ((startGas - endGas), result);
    }

    /**
     * @dev Gets the description stored in the code of a drawing contract
     * @param addr The address of the drawing contract
     * @return a (possibly empty) string description of the drawing
     * 
     * It calls the "0xDE" opcode of the drawing to get its description.
     * If the call fails, it will return an empty string.
     */
    function description(address addr) internal view returns (string memory) {
        (bool success, bytes memory desc) = addr.staticcall(hex"DE");
        if (success) {
            return string(desc);
        } else {
            return "";
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Namespace to encapsulate a "Metadata" struct for a drawing
 */
library Token {
    struct Metadata { 
       string name;
       string description;
       string externalUrl;
       string drawingAddress;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Base64.sol";

/**
 * @dev Internal library encapsulating JSON / Token URI serialization
 */
library Serialize {
    /**
     * @dev Generates a ERC721 TokenURI for the given data
     * @param bitmapData The raw bytes of the drawing's bitmap
     * @param metadata The struct holding information about the drawing
     * @return a string application/json data URI containing the token information
     * 
     * We do _not_ base64 encode the JSON. This results in a slightly non-compliant
     * data URI, because of the commas (and potential non-URL-safe characters).
     * Empirically, this is fine: and re-base64-encoding everything would use
     * gas and time and is not worth it.
     * 
     * There's also a few ways we could encode the image in the metadata JSON:
     *  1. image/bmp data url in the `image` field (base64-encoded given binary data)
     *  2. raw svg data in the `image_data` field
     *  3. image/svg data url in the `image` field (containing a base64-encoded image, but not itself base64-encoded)
     *  4. (3), but with another layer of base64 encoding
     * Through some trial and error, (1) does not work with Rarible or OpenSea. The rest do. (4) would be yet another
     * layer of base64 (taking time, so is not desirable), (2) uses a potentially non-standard field, so we use (3).
     */
    function tokenURI(bytes memory bitmapData, Token.Metadata memory metadata) internal pure returns (string memory) {
        string memory imageKey = "image";
        bytes memory imageData = _svgDataURI(bitmapData);

        string memory fragment = _metadataJSONFragmentWithoutImage(metadata);
        return string(abi.encodePacked(
            'data:application/json,',
            fragment,
            // image data :)
            '","', imageKey, '":"', imageData, '"}'
        ));
    }

    /**
     * @dev Returns just the metadata of the image (no bitmap data) as a JSON string
     * @param metadata The struct holding information about the drawing
     */
    function metadataAsJSON(Token.Metadata memory metadata) internal pure returns (string memory) {
        string memory fragment = _metadataJSONFragmentWithoutImage(metadata);
        return string(abi.encodePacked(
            fragment,
            '"}'
        ));
    }

    /**
     * @dev Returns a partial JSON string with the metadata of the image.
     *      Used by both the full tokenURI and the plain-metadata serializers.
     * @param metadata The struct holding information about the drawing
     */
    function _metadataJSONFragmentWithoutImage(Token.Metadata memory metadata) internal pure returns (string memory) {
        return string(abi.encodePacked(
            // name
            '{"name":"',
                metadata.name,

            // description
            '","description":"',
                metadata.description,

            // external_url
            '","external_url":"',
                metadata.externalUrl,

            // code address
            '","drawing_address":"',
                metadata.drawingAddress
        ));
    }


   /**
     * @dev Generates a data URI of an SVG containing an <image> tag containing the given bitmapData
     * @param bitmapData The raw bytes of the drawing's bitmap
     */
    function _svgDataURI(bytes memory bitmapData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "data:image/svg+xml,",
            "<svg xmlns='http://www.w3.org/2000/svg' width='303' height='303'><image width='303' height='303' style='image-rendering: pixelated' href='",
            "data:image/bmp;base64,",
            Base64.encode(bitmapData),
            "'/></svg>"
        );
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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Library encapsulating logic to generate the header + palette for a bitmap.
 * 
 * Uses the "40-byte" header format, as described at
 * http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm
 * 
 * Note that certain details (width, height, palette size, file size) are hardcoded
 * based off the DBN-specific assumptions of 101x101 with 101 shades of grey.
 * 
 */
library BitmapHeader {

    bytes32 internal constant HEADER1 = 0x424dd22a000000000000ca010000280000006500000065000000010008000000;
    bytes22 internal constant HEADER2 = 0x00000000000000000000000000006500000000000000;

    /**
     * @dev Writes a 458 byte bitmap header + palette to the given array
     * @param output The destination array. Gets mutated!
     */
    function writeTo(bytes memory output) internal pure {

        assembly {
            mstore(add(output, 0x20), HEADER1)
            mstore(add(output, 0x40), HEADER2)
        }

        // palette index is "DBN" color : [0, 100]
        // map that to [0, 255] via:
        // 255 - ((255 * c) / 100)
        for (uint i = 0; i < 101; i++) {
            bytes1 c = bytes1(uint8(255 - ((255 * i) / 100)));
            uint o = i*4 + 54; // after the header
            output[o] = c;
            output[o + 1] = c;
            output[o + 2] = c;
        }

        
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Helper library for base64-encoding bytes
 */
library Base64 {

    uint256 internal constant ALPHA1 = 0x4142434445464748494a4b4c4d4e4f505152535455565758595a616263646566;
    uint256 internal constant ALPHA2 = 0x6768696a6b6c6d6e6f707172737475767778797a303132333435363738392b2f;

    /**
     * @dev Encodes the given bytearray to base64
     * @param input The input data
     * @return the output data
     */
    function encode(bytes memory input) internal pure returns (bytes memory) {
        if (input.length == 0) {
            return input;
        }

        bytes memory output = new bytes(_encodedLength(input.length));

        uint remaining = input.length;

        assembly {
            let src := add(input, 0x20)
            let dst := add(output, 0x20)

            // chunk loop
            for {} gt(remaining, 0) {} {
                let chunk := shr(16, mload(src))
                let processing := 30
                let sixtetCounter := 240 // 30 * 8

                if lt(remaining, 30) {
                    processing := remaining

                    // slide right by 30–#remaining bytes (shl by 3 to get bits)
                    chunk := shr(shl(3, sub(30, remaining)), chunk)

                    // but now it needs to be nudge to the left by a few bits,
                    // to make sure total number of bits is multiple of 6
                    // 0 mod 3: nudge 0 bits
                    // 1 mod 3: nudge 4 bits
                    // 2 mod 3: nudge 2 bits
                    // we take advantage that this is the same as
                    // (v * 4) % 6
                    // this is empirically true, though I don't remember the number theory proving it
                    let nudgeBits := mulmod(remaining, 4, 6)
                    chunk := shl(nudgeBits, chunk)

                    // initial sixtet (remaining * 8 + nudge)
                    sixtetCounter := add(shl(3, remaining), nudgeBits)
                }

                remaining := sub(remaining, processing)
                src := add(src, processing)

                // byte loop
                for {} gt(sixtetCounter, 0) {} {
                    sixtetCounter := sub(sixtetCounter, 6)
                    let val := shr(sixtetCounter, and(shl(sixtetCounter, 0x3F), chunk))

                    let alpha := ALPHA1
                    if gt(val, 0x1F) {
                        alpha := ALPHA2
                        val := sub(val, 0x20)
                    }
                    let char := byte(val, alpha)
                    mstore8(dst, char)
                    dst := add(dst, 1)
                }
            }

            // padding depending on input length % 3
            switch mod(mload(input), 3)
            case 1 {
                // two pads
                mstore8(dst, 0x3D) // 0x3d is =
                mstore8(add(1, dst), 0x3D) // 0x3d is =
            }
            case 2 {
                // one pad
                mstore8(dst, 0x3D)
            }
        }

        return output;
    }

    /**
     * @dev Helper to get the length of the output data
     * 
     * Implements Ceil(inputLength / 3) * 4
     */
    function _encodedLength(uint inputLength) internal pure returns (uint) {
        return ((inputLength + 2) / 3) * 4;
    }
}