// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@1001-digital/erc721-extensions/contracts/WithContractMetaData.sol";
import "@1001-digital/erc721-extensions/contracts/RandomlyAssigned.sol";
import "@1001-digital/erc721-extensions/contracts/WithIPFSMetaData.sol";
import "@1001-digital/erc721-extensions/contracts/WithWithdrawals.sol";
import "@1001-digital/erc721-extensions/contracts/WithSaleStart.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./CryptoPunkInterface.sol";
import "./OneDayPunk.sol";

import "./WithMarketOffers.sol";

// ████████████████████████████████████████████████████████████████████████████████████ //
// ██                                                                                ██ //
// ██                                                                                ██ //
// ██   ██████  ██    ██ ███    ██ ██   ██ ███████  ██████  █████  ██████  ███████   ██ //
// ██   ██   ██ ██    ██ ████   ██ ██  ██  ██      ██      ██   ██ ██   ██ ██        ██ //
// ██   ██████  ██    ██ ██ ██  ██ █████   ███████ ██      ███████ ██████  █████     ██ //
// ██   ██      ██    ██ ██  ██ ██ ██  ██       ██ ██      ██   ██ ██      ██        ██ //
// ██   ██       ██████  ██   ████ ██   ██ ███████  ██████ ██   ██ ██      ███████   ██ //
// ██                                                                                ██ //
// ██                                                                                ██ //
// ████████████████████████████████████████████████████████████████████████████████████ //

contract PunkScape is
    ERC721,
    Ownable,
    WithSaleStart,
    WithWithdrawals,
    WithIPFSMetaData,
    RandomlyAssigned,
    WithMarketOffers,
    WithContractMetaData
{
    uint256 public price = 0.03 ether;
    string constant public provenanceHash = "Qme5GyE2rUHeSSHPeXdvGBAqQdLxzE31J1HTP6aJPJcGgA";
    bool public frozen = false;

    address private cryptoPunksAddress;
    address private oneDayPunkAddress;

    /// Stores the PunkScape that was claimed during
    /// early access for each OneDayPunk.
    mapping(uint256 => uint256) public oneDayPunkToPunkScape;

    /// Instantiate the PunkScape Contract
    constructor(
        address payable _punkscape,
        string memory _cid,
        uint256 _saleStart,
        string memory _contractMetaDataURI,
        address _cryptoPunksAddress,
        address _oneDayPunkAddress
    )
        ERC721("PunkScape", "PS")
        WithIPFSMetaData(_cid)
        WithMarketOffers(_punkscape, 500)
        WithSaleStart(_saleStart)
        RandomlyAssigned(10000, 1)
        WithContractMetaData(_contractMetaDataURI)
    {
        cryptoPunksAddress = _cryptoPunksAddress;
        oneDayPunkAddress = _oneDayPunkAddress;
    }

    /// Claim a PunkScape for a given OneDayPunk during early access.
    /// The scape will be sent to the owner of the OneDayPunk.
    function claimForOneDayPunk(uint256 oneDayPunkId) external payable
        afterSaleStart
        ensureAvailability
    {
        OneDayPunk oneDayPunk = OneDayPunk(oneDayPunkAddress);
        address owner = oneDayPunk.ownerOf(oneDayPunkId);

        require(
            msg.value >= price,
            "Pay up, friend"
        );

        require(
            oneDayPunkToPunkScape[oneDayPunkId] == 0,
            "PunkScape for this OneDayPunk has already been claimed"
        );

        // Get the token ID
        uint256 newScape = nextToken();

        // Redeem the PunkScape for the given OneDayPunk
        oneDayPunkToPunkScape[oneDayPunkId] = newScape;

        // Mint the token
        _safeMint(owner, newScape);
    }

    /// General claiming phase starts 618 minutes after OneDayPunk sale start. Why?
    /// Because that's the amount of time it took for all OneDayPunks to sell out.
    function claimAfter618Minutes(uint256 amount) external payable
        ensureAvailabilityFor(amount)
    {
        uint256 _saleStart = saleStart();

        // General claiming only available 618 minutes after sale start.
        require(
            block.timestamp > (_saleStart + 618 * 60),
            "General claiming phase starts 618 minutes after sale start"
        );

        // Can mint up to three PunkScapes per transaction.
        require(
            amount > 0,
            "Have to mint at least one PunkScape"
        );
        require(
            amount <= 3,
            "Can't mint more than 3 PunkScapes per transaction"
        );
        require(
            msg.value >= (price * amount),
            "Pay up, friend"
        );

        // Within the first 24 hours only OneDayPunk / CryptoPunk holders can mint.
        if (block.timestamp < (_saleStart + 24 * 60 * 60)) {
            CryptoPunks cryptoPunks = CryptoPunks(cryptoPunksAddress);
            OneDayPunk oneDayPunk = OneDayPunk(oneDayPunkAddress);
            require(
                oneDayPunk.balanceOf(msg.sender) == 1 ||
                cryptoPunks.balanceOf(msg.sender) >= 1,
                "You have to own a CryptoPunk or a OneDayPunk to mint a PunkScape"
            );
        }

        // Mint the new tokens
        for (uint256 index = 0; index < amount; index++) {
            uint256 newScape = nextToken();
            _safeMint(msg.sender, newScape);
        }
    }

    /// Allow the contract owner to update the IPFS content identifier until sale starts.
    function setCID(string memory _cid) external onlyOwner {
        require(frozen == false, "Metadata is frozen");

        _setCID(_cid);
    }

    /// Allow the contract owner to freeze the metadata.
    function freezeCID() external onlyOwner {
        frozen = true;
    }

    /// Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId)
        public view override(WithIPFSMetaData, ERC721)
        returns (string memory)
    {
        return WithIPFSMetaData.tokenURI(tokenId);
    }

    /// Configure the baseURI for the tokenURI method
    function _baseURI()
        internal view override(WithIPFSMetaData, ERC721)
        returns (string memory)
    {
        return WithIPFSMetaData._baseURI();
    }

    /// We support the `HasSecondarySalesFees` interface
    function supportsInterface(bytes4 interfaceId)
        public view override(WithMarketOffers, ERC721)
        returns (bool)
    {
        return WithMarketOffers.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author 1001.digital
/// @title Link to your collection's contract meta data right from within your smart contract.
abstract contract WithContractMetaData is Ownable {
    // The URI to the contract meta data.
    string private _contractURI;

    /// Instanciate the contract
    /// @param uri the URL to the contract metadata
    constructor (string memory uri) {
        _contractURI = uri;
    }

    /// Set the contract metadata URI
    /// @param uri the URI to set
    /// @dev the contract metadata should link to a metadata JSON file.
    function setContractURI(string memory uri) public virtual onlyOwner {
        _contractURI = uri;
    }

    /// Expose the contractURI
    /// @return the contract metadata URI.
    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WithLimitedSupply.sol";

/// @author 1001.digital
/// @title Randomly assign tokenIDs from a given set of tokens.
abstract contract RandomlyAssigned is WithLimitedSupply {
    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    // The initial token ID
    uint256 private startFrom;

    /// Instanciate the contract
    /// @param _totalSupply how many tokens this collection should hold
    /// @param _startFrom the tokenID with which to start counting
    constructor (uint256 _totalSupply, uint256 _startFrom)
        WithLimitedSupply(_totalSupply)
    {
        startFrom = _startFrom;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextToken() internal override ensureAvailability returns (uint256) {
        uint256 maxIndex = totalSupply() - tokenCount();
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        // Increment counts
        super.nextToken();

        return value + startFrom;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author 1001.digital
/// @title Handle NFT Metadata stored on IPFS
abstract contract WithIPFSMetaData is ERC721 {
    using Strings for uint256;

    /// @dev The content identifier of the folder containing all JSON files.
    string public cid;

    /// Instantiate the contract
    /// @param _cid the content identifier for the token metadata.
    /// @dev be careful & make sure your metadata is correct - you can't change this
    constructor (string memory _cid) {
        _setCID(_cid);
    }

    /// Get the tokenURI for a tokenID
    /// @param tokenId the token id for which to get the matadata URL
    /// @dev links to the metadata json file on IPFS.
    /// @return the URL to the token metadata file
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // We don't check whether the _baseURI is set like in the OpenZeppelin implementation
        // as we're deploying the contract with the CID.
        return string(abi.encodePacked(
            _baseURI(), "/", tokenId.toString(), "/metadata.json"
        ));
    }

    /// Configure the baseURI for the tokenURI method.
    /// @dev override the standard OpenZeppelin implementation
    /// @return the IPFS base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://", cid));
    }

    /// Set the content identifier for this collection.
    /// @param _cid the new content identifier
    /// @dev update the content identifier for this nft.
    function _setCID(string memory _cid) internal virtual {
        cid = _cid;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author 1001.digital
/// @title An extension that enables the contract owner to withdraw funds stored in the contract.
abstract contract WithWithdrawals is Ownable
{
    /// Withdraws the ETH stored in the contract.
    /// @dev only the owner can withdraw funds.
    function withdraw() onlyOwner public {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author 1001.digital
/// @title An extension that enables the contract owner to set and update the date of a public sale.
abstract contract WithSaleStart is Ownable
{
    // Stores the sale start time
    uint256 private _saleStart;

    /// @dev Emitted when the sale start date changes
    event SaleStartChanged(uint256 time);

    /// @dev Initialize with a given timestamp when to start the sale
    constructor (uint256 time) {
        _saleStart = time;
    }

    /// @dev Sets the start of the sale. Only owners can do so.
    function setSaleStart(uint256 time) public virtual onlyOwner beforeSaleStart {
        _saleStart = time;
        emit SaleStartChanged(time);
    }

    /// @dev Returns the start of the sale in seconds since the Unix Epoch
    function saleStart() public view virtual returns (uint256) {
        return _saleStart;
    }

    /// @dev Returns true if the sale has started
    function saleStarted() public view virtual returns (bool) {
        return _saleStart <= block.timestamp;
    }

    /// @dev Modifier to make a function callable only after sale start
    modifier afterSaleStart() {
        require(saleStarted(), "Sale hasn't started yet");
        _;
    }

    /// @dev Modifier to make a function callable only before sale start
    modifier beforeSaleStart() {
        require(! saleStarted(), "Sale has already started");
        _;
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

interface CryptoPunks {
    function balanceOf(address owner) external view returns(uint256);
    function punkIndexToAddress(uint index) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@1001-digital/erc721-extensions/contracts/RandomlyAssigned.sol";
import "@1001-digital/erc721-extensions/contracts/WithContractMetaData.sol";
import "@1001-digital/erc721-extensions/contracts/WithIPFSMetaData.sol";
import "@1001-digital/erc721-extensions/contracts/OnePerWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./CryptoPunkInterface.sol";

// ====================================================================================================================== //
//    ______     __   __     ______        _____     ______     __  __        ______   __  __     __   __     __  __      //
//   /\  __ \   /\ "-.\ \   /\  ___\      /\  __-.  /\  __ \   /\ \_\ \      /\  == \ /\ \/\ \   /\ "-.\ \   /\ \/ /      //
//   \ \ \/\ \  \ \ \-.  \  \ \  __\      \ \ \/\ \ \ \  __ \  \ \____ \     \ \  _-/ \ \ \_\ \  \ \ \-.  \  \ \  _"-.    //
//    \ \_____\  \ \_\\"\_\  \ \_____\     \ \____-  \ \_\ \_\  \/\_____\     \ \_\    \ \_____\  \ \_\\"\_\  \ \_\ \_\   //
//     \/_____/   \/_/ \/_/   \/_____/      \/____/   \/_/\/_/   \/_____/      \/_/     \/_____/   \/_/ \/_/   \/_/\/_/   //
//                                                                                                                        //
// ====================================================================================================================== //
//                                           10k "ONE DAY I'LL BE A PUNK"-punks                                           //
//                                              limited to one per address                                                //
//                                                    aim high, fren!                                                     //
// ====================================================================================================================== //
contract OneDayPunk is
    ERC721,
    OnePerWallet,
    RandomlyAssigned,
    WithIPFSMetaData,
    WithContractMetaData
{
    address private cryptoPunksAddress;

    // Instantiate the OneDayPunk Contract
    constructor(
        string memory _cid,
        string memory _contractMetaDataURI,
        address _cryptopunksAddress
    )
        ERC721("OneDayPunk", "ODP")
        RandomlyAssigned(10000, 0)
        WithIPFSMetaData(_cid)
        WithContractMetaData(_contractMetaDataURI)
    {
        cryptoPunksAddress = _cryptopunksAddress;
    }

    // Claim a "One Day I'll Be A Punk"-Punk
    function claim() external {
        _claim(msg.sender);
    }

    // Claim a "One Day I'll Be A Punk"-Punk to a specific address
    function claimFor(address to) external {
        _claim(to);
    }

    // Claims a token for a specific address.
    function _claim (address to) internal ensureAvailability onePerWallet(to) {
        CryptoPunks cryptopunks = CryptoPunks(cryptoPunksAddress);
        require(cryptopunks.balanceOf(to) == 0, "You lucky one already have a CryptoPunk.");

        uint256 next = nextToken();

        _safeMint(to, next);
    }

    // Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId)
        public view override(WithIPFSMetaData, ERC721)
        returns (string memory)
    {
        return WithIPFSMetaData.tokenURI(tokenId);
    }

    // Configure the baseURI for the tokenURI method.
    function _baseURI()
        internal view override(WithIPFSMetaData, ERC721)
        returns (string memory)
    {
        return WithIPFSMetaData._baseURI();
    }

    // Mark OnePerWallet implementation as override for ERC721, OnePerWallet
    function _mint(address to, uint256 tokenId) internal override(ERC721, OnePerWallet) {
        OnePerWallet._mint(to, tokenId);
    }

    // Mark OnePerWallet implementation as override for ERC721, OnePerWallet
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, OnePerWallet) {
        OnePerWallet._transfer(from, to, tokenId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@1001-digital/erc721-extensions/contracts/WithFees.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @author 1001.digital
/// @title Implement a basic integrated marketplace with fees
abstract contract WithMarketOffers is ERC721, WithFees {

    event OfferCreated(uint256 indexed tokenId, uint256 indexed value, address indexed to);
    event OfferWithdrawn(uint256 indexed tokenId);
    event Sale(uint256 indexed tokenId, address indexed from, address indexed to, uint256 value);

    struct Offer {
        uint256 price;
        address payable specificBuyer;
    }

    /// @dev All active offers
    mapping (uint256 => Offer) private _offers;

    /// Instantiate the contract
    /// @param _feeRecipient the fee recipient for secondary sales
    /// @param _bps the basis points measure for the fees
    constructor (address payable _feeRecipient, uint256 _bps)
        WithFees(_feeRecipient, _bps)
    {}

    /// @dev All active offers
    function offerFor(uint256 tokenId) external view returns(Offer memory) {
        require(_offers[tokenId].price > 0, "No active offer for this item");

        return _offers[tokenId];
    }

    function _makeOffer(uint256 tokenId, uint256 price, address to) internal {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is neither owner nor approved");
        require(price > 0, "Price should be higher than 0");
        require(price > _offers[tokenId].price, "Price should be higher than existing offer");

        _offers[tokenId] = Offer(price, payable(to));
        emit OfferCreated(tokenId, price, to);
    }

    /// @dev Make a new offer
    function makeOffer(uint256 tokenId, uint256 price) external {
        _makeOffer(tokenId, price, address(0));
    }

    /// @dev Make a new offer to a specific person
    function makeOfferTo(uint256 tokenId, uint256 price, address to) external {
        _makeOffer(tokenId, price, to);
    }

    /// @dev Revoke an active offer
    function cancelOffer(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is neither owner nor approved");
        delete _offers[tokenId];
        emit OfferWithdrawn(tokenId);
    }

    /// @dev Buy an item that is for offer
    function buy(uint256 tokenId) external payable isForSale(tokenId) {
        Offer memory offer = _offers[tokenId];
        address payable seller = payable(ownerOf(tokenId));

        // If it is a private sale, make sure the buyer is the private sale recipient.
        if (offer.specificBuyer != address(0)) {
            require(offer.specificBuyer == msg.sender, "Can't buy a privately offered item");
        }

        require(msg.value >= offer.price, "Price not met");

        // Seller gets msg value - fees set as BPS.
        seller.transfer(msg.value - (offer.price * bps / 10000));

        // We transfer the token.
        _safeTransfer(seller, msg.sender, tokenId, "");
        emit Sale(tokenId, seller, msg.sender, offer.price);
        delete _offers[tokenId];
    }

    /// @dev Check whether the token is for sale
    modifier isForSale(uint256 tokenId) {
        require(_offers[tokenId].price > 0, "Item not for sale");
        _;
    }

    /// We support the `HasSecondarySalesFees` interface
    function supportsInterface(bytes4 interfaceId)
        public view virtual override(WithFees, ERC721)
        returns (bool)
    {
        return WithFees.supportsInterface(interfaceId);
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

import "@openzeppelin/contracts/utils/Counters.sol";

/// @author 1001.digital
/// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract WithLimitedSupply {
    using Counters for Counters.Counter;

    // Keeps track of how many we have minted
    Counters.Counter private _tokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private _totalSupply;

    /// Instanciate the contract
    /// @param totalSupply_ how many tokens this collection should hold
    constructor (uint256 totalSupply_) {
        _totalSupply = totalSupply_;
    }

    /// @dev Get the max Supply
    /// @return the maximum token count
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Get the current token count
    /// @return the created token count
    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    /// @dev Check whether tokens are still available
    /// @return the available token count
    function availableTokenCount() public view returns (uint256) {
        return totalSupply() - tokenCount();
    }

    /// @dev Increment the token count and fetch the latest count
    /// @return the next token id
    function nextToken() internal virtual ensureAvailability returns (uint256) {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return token;
    }

    /// @dev Check whether another token is still available
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    /// @param amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, "Requested number of tokens not available");
        _;
    }
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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@1001-digital/check-address/contracts/CheckAddress.sol";

/// @author 1001.digital
/// @title An extension that enables checking that an address only holds one token.
abstract contract OnePerWallet is ERC721 {
    // Mapping owner address to token
    mapping (address => uint256) private _ownedToken;

    /// Require an externally owned account to only hold one token.
    /// @param wallet the address to check
    /// @dev Only allow one token per wallet
    modifier onePerWallet(address wallet) {
        if (CheckAddress.isExternal(wallet)) {
            require(_ownedToken[wallet] == 0, "Can only hold one token per wallet");
        }

        _;
    }

    /// Require any account on the network to only hold one token.
    /// @param account the address to checkk
    /// @dev Only allow one token per account
    modifier onePerAccount(address account) {
        require(
            msg.sender == tx.origin &&
            _ownedToken[account] == 0,
            "Can only hold one token per account"
        );

        _;
    }

    /// Query the owner of a token.
    /// @param owner the address of the owner
    /// @dev Get the the token of an owner
    function tokenOf(address owner) public view virtual returns (uint256) {
        require(_ownedToken[owner] > 0, "No token for this account.");

        // We subtract 1 as we added 1 to account for 0-index based collections
        return _ownedToken[owner] - 1;
    }

    /// Store `_ownedToken` instead of `_balances`.
    /// @param to the address to which to mint the token
    /// @param tokenId the tokenId that should be minted
    /// @dev overrides the OpenZeppelin `_mint` method to accomodate for our own balance tracker
    function _mint(address to, uint256 tokenId) internal virtual override onePerWallet(to) {
        super._mint(to, tokenId);

        // We add one to account for 0-index based collections
        _ownedToken[to] = tokenId + 1;
    }

    /// Track transfers in `_ownedToken` instead of `_balances`
    /// @param from the address from which to transfer the token
    /// @param to the address to which to transfer the token
    /// @param tokenId the tokenId that is being transferred
    /// @dev overrides the OpenZeppelin `_transfer` method to accomodate for our own balance tracker
    function _transfer(address from, address to, uint256 tokenId) internal virtual override onePerWallet(to) {
        super._transfer(from, to, tokenId);

        _ownedToken[from] = 0;
        // We add one to account for 0-index based collections
        _ownedToken[to] = tokenId + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author 1001.digital
/// @title A helper to distinguish external and contract addresses
library CheckAddress {

    /// Check whether an address is a smart contract.
    /// @param account the address to check
    /// @dev checks if the `extcodesize` of `address` is greater zero
    /// @return true for contracts
    function isContract(address account) external view returns (bool) {
        return getSize(account) > 0;
    }

    /// Check whether an address is an external wallet.
    /// @param account the address to check
    /// @dev checks if the `extcodesize` of `address` is zero
    /// @return true for external wallets
    function isExternal(address account) external view returns (bool) {
        return getSize(account) == 0;
    }

    /// Get the size of the code of an address
    /// @param account the address to check
    /// @dev gets the `extcodesize` of `address`
    /// @return the size of the address
    function getSize(address account) internal view returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./standards/HasSecondarySaleFees.sol";

/// @author 1001.digital
/// @title Implements the various fee standards that are floating around.
/// @dev We need a proper standard for this.
abstract contract WithFees is ERC721, HasSecondarySaleFees {
    // The address to pay fees to
    address payable internal beneficiary;

    // The fee basis points
    uint256 internal bps;

    /// Instanciate the contract
    /// @param _beneficiary the address to send fees to
    /// @param _bps the basis points measure for the fees
    constructor (address payable _beneficiary, uint256 _bps) {
        beneficiary = _beneficiary;
        bps = _bps;
    }

    /// Implement the `HasSecondarySalesFees` Contract
    /// @dev implements the standard pushed by Rarible
    /// @return list of fee recipients, in our case always one
    function getFeeRecipients(uint256) public view override returns (address payable[] memory) {
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = beneficiary;
        return recipients;
    }

    /// Implement the `HasSecondarySalesFees` Contract
    /// @dev implements the standard pushed by Rarible
    /// @return list of fee basis points, in our case always one
    function getFeeBps(uint256) public view override returns (uint256[] memory) {
        uint256[] memory bpsArray = new uint256[](1);
        bpsArray[0] = bps;
        return bpsArray;
    }

    /// Make sure the contract reports that it supportsthe `HasSecondarySalesFees` Interface
    /// @param interfaceId the interface to check
    /// @dev extends the ERC721 method
    /// @return whether the given interface is supported
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
        return interfaceId == type(HasSecondarySaleFees).interfaceId
            || ERC721.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract HasSecondarySaleFees is ERC165 {
    function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);
    function getFeeBps(uint256 id) public view virtual returns (uint256[] memory);
}

