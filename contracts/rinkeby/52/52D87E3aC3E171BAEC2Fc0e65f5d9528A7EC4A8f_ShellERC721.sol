//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ShellFramework.sol";

contract ShellERC721 is ShellFramework, ERC721Upgradeable {
    // for ERC-721s, mint amount must be 1
    error InvalidMintAmount();

    function initialize(
        string calldata name_,
        string calldata symbol_,
        IEngine engine,
        address owner_
    ) external initializer {
        // using the unchained variant since theres no real need to init the
        // erc165 and context stuff from openzep's 721
        __ERC721_init_unchained(name_, symbol_);

        __ShellFramework_init(engine, owner_);
    }

    // ---
    // Standard ERC721 stuff
    // ---

    function name()
        public
        view
        override(IShellFramework, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.name();
    }

    function symbol()
        public
        view
        override(IShellFramework, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.symbol();
    }

    // ---
    // Views powered by engine
    // ---

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return getTokenEngine(tokenId).getTokenURI(this, tokenId);
    }

    // ---
    // Framework functionality
    // ---

    function canSenderForkToken(address sender, uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // owner of a token can always fork
        return ownerOf(tokenId) == sender;
    }

    // ---
    // Engine functionality
    // ---

    function mint(MintEntry calldata entry) external returns (uint256) {
        if (msg.sender != address(getForkEngine(0))) {
            revert SenderNotEngine();
        }

        return _mint(entry);
    }

    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory)
    {
        if (msg.sender != address(getForkEngine(0))) {
            revert SenderNotEngine();
        }

        uint256[] memory tokenIds = new uint256[](entries.length);

        for (uint256 i = 0; i < entries.length; i++) {
            tokenIds[i] = _mint(entries[i]);
        }

        return tokenIds;
    }

    function _mint(MintEntry calldata entry) internal returns (uint256) {
        require(entry.amount == 1, "shell: amount must be 1");
        uint256 tokenId = nextTokenId++;
        _mint(entry.to, tokenId);
        _writeMintData(tokenId, entry);
        return tokenId;
    }

    // ---
    // Introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ShellFramework, ERC721Upgradeable)
        returns (bool)
    {
        return
            ShellFramework.supportsInterface(interfaceId) ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    // ---
    // Wire up the openzep 721 hook to the engine
    // ---

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        getTokenEngine(tokenId).beforeTokenTransfer(
            msg.sender,
            from,
            to,
            tokenId,
            1
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IShellFramework.sol";

// Abstract implementation of the shell framework interface -- can be used as a
// base for all shell collections
abstract contract ShellFramework is IShellFramework, Initializable {
    // fork data
    mapping(uint256 => Fork) private _forks;

    // token id -> fork id
    mapping(uint256 => uint256) private _tokenForks;

    // all stored strings
    mapping(bytes32 => string) private _stringStorage;

    // all stored ints
    mapping(bytes32 => uint256) private _intStorage;

    // token id serial number
    uint256 public nextTokenId;

    // fork id serial number
    uint256 public nextForkId;

    // ensure that the deployed implementation cannot be initialized after
    // deployment. Clones do not trigger the constructor but are manually
    // initted by ShellFactory
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    // used to initialize the clone
    // solhint-disable-next-line func-name-mixedcase
    function __ShellFramework_init(IEngine engine, address owner_)
        internal
        onlyInitializing
    {
        nextTokenId = 1;
        nextForkId = 1;

        // not using createFork for initial fork
        _forks[0].engine = engine;
        _forks[0].owner = owner_;
        engine.afterEngineSet(0);
        emit ForkCreated(0, engine, owner_);
    }

    // ---
    // Fork functionality
    // ---

    function createFork(
        IEngine engine,
        address owner_,
        uint256[] calldata tokenIds
    ) external returns (uint256) {
        if (
            !ERC165Checker.supportsInterface(
                address(engine),
                type(IEngine).interfaceId
            )
        ) {
            revert InvalidEngine();
        }

        uint256 forkId = nextForkId++;
        _forks[forkId].engine = engine;
        _forks[forkId].owner = owner_;
        emit ForkCreated(forkId, engine, owner_);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // calling virtual method to ensure ownership / implementation
            // checks are handled in the token model contract
            forkToken(tokenIds[i], forkId);
        }

        engine.afterEngineSet(forkId);

        return forkId;
    }

    // Set the fork of a specific token. Must be token owner
    function forkToken(uint256 tokenId, uint256 forkId) public override {
        if (!canSenderForkToken(msg.sender, tokenId)) {
            revert SenderCannotFork();
        }

        _forkToken(tokenId, forkId);
    }

    function forkTokens(uint256[] memory tokenIds, uint256 forkId)
        external
        override
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!canSenderForkToken(msg.sender, tokenIds[i])) {
                revert SenderCannotFork();
            }

            _forkToken(tokenIds[i], forkId);
        }
    }

    function canSenderForkToken(address, uint256)
        public
        view
        virtual
        returns (bool)
    {
        // by default, do not allow forking
        return false;
    }

    function _forkToken(uint256 tokenId, uint256 forkId) internal {
        _tokenForks[tokenId] = forkId;
        emit ForkJoined(tokenId, forkId);
    }

    function setForkEngine(uint256 forkId, IEngine engine) external {
        if (msg.sender != _forks[forkId].owner) {
            revert SenderNotForkOwner();
        }

        if (
            !ERC165Checker.supportsInterface(
                address(engine),
                type(IEngine).interfaceId
            )
        ) {
            revert InvalidEngine();
        }

        _forks[forkId].engine = engine;
        emit ForkEngineUpdated(forkId, engine);
        engine.afterEngineSet(forkId);
    }

    function setForkOwner(uint256 forkId, address owner_) external {
        if (msg.sender != _forks[forkId].owner) {
            revert SenderNotForkOwner();
        }

        _forks[forkId].owner = owner_;
        emit ForkOwnerUpdated(forkId, owner_);
    }

    // ---
    // Fork views
    // ---

    function owner() external view returns (address) {
        return _forks[0].owner; // collection owner = fork 0 owner
    }

    function getFork(uint256 forkId) public view returns (Fork memory) {
        return _forks[forkId];
    }

    function getForkEngine(uint256 forkId) public view returns (IEngine) {
        return _forks[forkId].engine;
    }

    function getTokenForkId(uint256 tokenId) public view returns (uint256) {
        return _tokenForks[tokenId];
    }

    function getTokenEngine(uint256 tokenId) public view returns (IEngine) {
        return _forks[_tokenForks[tokenId]].engine;
    }

    // ---
    // Standard mint functionality
    // ---

    function _writeMintData(uint256 tokenId, MintEntry calldata entry)
        internal
    {
        // write engine-provided immutable data

        for (uint256 i = 0; i < entry.options.stringData.length; i++) {
            _writeTokenString(
                StorageLocation.MINT_DATA,
                tokenId,
                entry.options.stringData[i].key,
                entry.options.stringData[i].value
            );
        }

        for (uint256 i = 0; i < entry.options.intData.length; i++) {
            _writeTokenInt(
                StorageLocation.MINT_DATA,
                tokenId,
                entry.options.intData[i].key,
                entry.options.intData[i].value
            );
        }

        // write framework immutable data

        if (entry.options.storeEngine) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "engine",
                uint256(uint160(address(getForkEngine(0))))
            );
        }
        if (entry.options.storeMintedTo) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "mintedTo",
                uint256(uint160(address(entry.to)))
            );
        }
        if (entry.options.storeTimestamp) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "timestamp",
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        }
        if (entry.options.storeBlockNumber) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "blockNumber",
                block.number
            );
        }
    }

    // ---
    // Storage write controller (for engine)
    // ---

    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external {
        _validateForkWrite(location, forkId);
        _writeForkString(location, forkId, key, value);
    }

    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external {
        _validateForkWrite(location, forkId);
        _writeForkInt(location, forkId, key, value);
    }

    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external {
        _validateTokenWrite(location, tokenId);
        _writeTokenString(location, tokenId, key, value);
    }

    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        _validateTokenWrite(location, tokenId);
        _writeTokenInt(location, tokenId, key, value);
    }

    function _validateForkWrite(StorageLocation location, uint256 forkId)
        private
        view
    {
        if (location == StorageLocation.FORK) {
            if (msg.sender != address(getForkEngine(forkId))) {
                revert SenderNotEngine();
            }
            return; // made it
        }

        revert WriteNotAllowed();
    }

    function _validateTokenWrite(StorageLocation location, uint256 tokenId)
        private
        view
    {
        if (location == StorageLocation.ENGINE) {
            if (msg.sender != address(getTokenEngine(tokenId))) {
                revert SenderNotEngine();
            }
            return; // made it
        }

        revert WriteNotAllowed();
    }

    // ---
    // Storage write implementation
    // ---

    function _writeForkString(
        StorageLocation location,
        uint256 forkId,
        string memory key,
        string memory value
    ) private {
        bytes32 storageKey = keccak256(abi.encodePacked(location, forkId, key));
        _stringStorage[storageKey] = value;
        emit ForkStringUpdated(location, forkId, key, value);
    }

    function _writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string memory key,
        uint256 value
    ) private {
        bytes32 storageKey = keccak256(abi.encodePacked(location, forkId, key));
        _intStorage[storageKey] = value;
        emit ForkIntUpdated(location, forkId, key, value);
    }

    function _writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string memory key,
        string memory value
    ) private {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        _stringStorage[storageKey] = value;
        emit TokenStringUpdated(location, tokenId, key, value);
    }

    function _writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string memory key,
        uint256 value
    ) private {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        _intStorage[storageKey] = value;
        emit TokenIntUpdated(location, tokenId, key, value);
    }

    // ---
    // Storage views
    // ---

    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory) {
        bytes32 storageKey = keccak256(abi.encodePacked(location, forkId, key));
        return _stringStorage[storageKey];
    }

    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256) {
        bytes32 storageKey = keccak256(abi.encodePacked(location, forkId, key));
        return _intStorage[storageKey];
    }

    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory) {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        return _stringStorage[storageKey];
    }

    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256) {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        return _intStorage[storageKey];
    }

    // ---
    // Views powered by current engine
    // ---

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return getTokenEngine(tokenId).getRoyaltyInfo(this, tokenId, salePrice);
    }

    // ---
    // introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IShellFramework).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./libraries/IOwnable.sol";
import "./IEngine.sol";

// storage flag
enum StorageLocation {
    INVALID,
    // set by the engine at any time, mutable
    ENGINE,
    // set by the engine during minting, immutable
    MINT_DATA,
    // set by the framework during minting or collection creation, immutable
    FRAMEWORK,
    // set by the engine at any time, siloed to a specific fork
    FORK
}

// string key / value
struct StringStorage {
    string key;
    string value;
}

// int key / value
struct IntStorage {
    string key;
    uint256 value;
}

// data provided when minting a new token
struct MintEntry {
    address to;
    uint256 amount;
    MintOptions options;
}

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Information about a fork
struct Fork {
    IEngine engine;
    address owner;
}

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = TBD
interface IShellFramework is IERC165, IERC2981 {
    // ---
    // Framework errors
    // ---

    // an engine was provided that did no pass the expected erc165 checks
    error InvalidEngine();

    // a write was attempted that is not allowed
    error WriteNotAllowed();

    // an operation was attempted but msg.sender was not the expected engine
    error SenderNotEngine();

    // an operation was attempted but msg.sender was not the fork owner
    error SenderNotForkOwner();

    // a token fork was attempted by an invalid msg.sender
    error SenderCannotFork();

    // ---
    // Framework events
    // ---

    // a fork was created
    event ForkCreated(uint256 forkId, IEngine engine, address owner);

    // a fork had a new engine installed
    event ForkEngineUpdated(uint256 forkId, IEngine engine);

    // a fork had a new owner set
    event ForkOwnerUpdated(uint256 forkId, address owner);

    // a token has been set to a new fork
    event ForkJoined(uint256 tokenId, uint256 forkId);

    // ---
    // Storage events
    // ---

    // A fork string was stored
    event ForkStringUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        string value
    );

    // A fork int was stored
    event ForkIntUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        uint256 value
    );

    // A token string was stored
    event TokenStringUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        string value
    );

    // A token int was stored
    event TokenIntUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Collection base
    // ---

    // called immediately after cloning
    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external;

    // ---
    // General collection info / metadata
    // ---

    // collection owner (fork 0 owner)
    function owner() external view returns (address);

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // next fork id serial number
    function nextForkId() external view returns (uint256);

    // ---
    // Fork functionality
    // ---

    // Create a new fork with a specific engine, fork all the tokenIds to the
    // new engine, and return the fork ID
    function createFork(
        IEngine engine,
        address owner,
        uint256[] calldata tokenIds
    ) external returns (uint256);

    // Set the engine for a specific fork. Must be fork owner
    function setForkEngine(uint256 forkId, IEngine engine) external;

    // Set the fork owner. Must be fork owner
    function setForkOwner(uint256 forkId, address owner) external;

    // Set the fork of a specific token. Must be token owner
    function forkToken(uint256 tokenId, uint256 forkId) external;

    // Set the fork for several tokens. Must own all tokens
    function forkTokens(uint256[] memory tokenIds, uint256 forkId) external;

    // ---
    // Fork views
    // ---

    // Get information about a fork
    function getFork(uint256 forkId) external view returns (Fork memory);

    // Get the collection / canonical engine. getFork(0).engine
    function getForkEngine(uint256 forkId) external view returns (IEngine);

    // Get a token's fork ID
    function getTokenForkId(uint256 tokenId) external view returns (uint256);

    // Get a token's engine. getFork(getTokenForkId(tokenId)).engine
    function getTokenEngine(uint256 tokenId) external view returns (IEngine);

    // Determine if a given msg.sender can fork a token
    function canSenderForkToken(address sender, uint256 tokenId)
        external
        view
        returns (bool);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by collection engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // mint new tokens. Only callable by collection engine
    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage. Only callable by collection engine
    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage. Only callable by collection engine
    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// (semi) standard ownable interface
interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = ??????
interface IEngine is IERC165 {
    // Get the name for this engine
    function name() external pure returns (string memory);

    // Called by the framework to resolve a response for tokenURI method
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the framework to resolve a response for royaltyInfo method
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // collection = msg.sender
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    // Called by the framework whenever an engine is set on a fork, including
    // the collection (fork id = 0). Can be used by engine developers to prevent
    // an engine from being installed in a collection or non-canonical fork if
    // desired
    // collection = msg.sender
    function afterEngineSet(uint256 forkId) external;
}