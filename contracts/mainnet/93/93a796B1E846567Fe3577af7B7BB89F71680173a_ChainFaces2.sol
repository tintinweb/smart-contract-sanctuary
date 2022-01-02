// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ChainFaces2Renderer.sol";
import "./ChainFaces2Errors.sol";

contract ChainFaces2 is ERC721, ERC721Enumerable, Ownable {

    /*************************
     COMMON
     *************************/

    // Sale stage enum
    enum Stage {
        STAGE_COMPLETE,
        STAGE_PRESALE,
        STAGE_MAIN_SALE
    }

    bool balanceNotWithdrawn;

    constructor(uint256 _tokenLimit, uint256 _secretCommit, address _renderer, bytes32 _merkleRoot) ERC721("ChainFaces Arena", unicode"ლ⚈෴⚈ლ")  {
        tokenLimit = _tokenLimit;
        secret = _secretCommit;
        merkleRoot = _merkleRoot;
        balanceNotWithdrawn = true;

        // Start in presale stage
        stage = Stage.STAGE_PRESALE;

        renderer = ChainFaces2Renderer(_renderer);

        // Mint ancients
        for (uint256 i = 0; i < 10; i++) {
            _createFace();
        }
    }

    fallback() external payable {}

    /*************************
     TOKEN SALE
     *************************/

    Stage public               stage;
    uint256 public             saleEnds;
    uint256 public immutable   tokenLimit;

    // Merkle distributor values
    bytes32 immutable merkleRoot;
    mapping(uint256 => uint256) private claimedBitMap;

    uint256 public constant saleLength = 60 minutes;
    uint256 public constant salePrice = 0.069 ether;

    uint256 secret;             // Entropy supplied by owner (commit/reveal style)
    uint256 userSecret;         // Pseudorandom entropy provided by minters

    // -- MODIFIERS --

    modifier onlyMainSaleOpen() {
        if (stage != Stage.STAGE_MAIN_SALE || mainSaleComplete()) {
            revert SaleNotOpen();
        }
        _;
    }

    modifier onlyPreSale() {
        if (stage != Stage.STAGE_PRESALE) {
            revert NotPreSaleStage();
        }
        _;
    }

    modifier onlyMainSale() {
        if (stage != Stage.STAGE_MAIN_SALE) {
            revert NotMainSaleStage();
        }
        _;
    }

    modifier onlySaleComplete() {
        if (stage != Stage.STAGE_COMPLETE) {
            revert SaleNotComplete();
        }
        _;
    }

    // -- VIEW METHODS --

    function mainSaleComplete() public view returns (bool) {
        return block.timestamp >= saleEnds || totalSupply() == tokenLimit;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // -- OWNER METHODS --

    // Reveal the faces
    function theGreatReveal(uint256 _secretReveal) external onlyOwner onlyMainSale {
        if (!mainSaleComplete()) {
            revert MainSaleNotComplete();
        }

        if (uint256(keccak256(abi.encodePacked(_secretReveal))) != secret) {
            revert InvalidReveal();
        }

        // Final secret is XOR between the pre-committed secret and the pseudo-random user contributed salt
        secret = _secretReveal ^ userSecret;

        // Won't be needing this anymore
        delete userSecret;

        stage = Stage.STAGE_COMPLETE;
    }

    // Start main sale
    function startMainSale() external onlyOwner onlyPreSale {
        stage = Stage.STAGE_MAIN_SALE;
        saleEnds = block.timestamp + saleLength;
    }

    // Withdraw sale proceeds
    function withdraw() external onlyOwner {
        // Owner can't reneg on bounty
        if (arenaActive()) {
            revert ArenaIsActive();
        }

        balanceNotWithdrawn = false;
        owner().call{value : address(this).balance}("");
    }

    // -- USER METHODS --

    function claim(uint256 _index, uint256 _ogAmount, uint256 _wlAmount, bytes32[] calldata _merkleProof, uint256 _amount) external payable onlyPreSale {
        // Ensure not already claimed
        if (isClaimed(_index)) {
            revert AlreadyClaimed();
        }

        // Prevent accidental claim of 0
        if (_amount == 0) {
            revert InvalidClaimAmount();
        }

        // Check claim amount
        uint256 total = _ogAmount + _wlAmount;
        if (_amount > total) {
            revert InvalidClaimAmount();
        }

        // Check claim value
        uint256 paidClaims = 0;
        if (_amount > _ogAmount) {
            paidClaims = _amount - _ogAmount;
        }
        if (msg.value < paidClaims * salePrice) {
            revert InvalidClaimValue();
        }

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _ogAmount, _wlAmount));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        // Mark it claimed and mint
        _setClaimed(_index);

        for (uint256 i = 0; i < _amount; i++) {
            _createFace();
        }

        _mix();
    }

    // Mint faces
    function createFace() external payable onlyMainSaleOpen {
        uint256 count = msg.value / salePrice;

        if (count == 0) {
            revert InvalidMintValue();
        } else if (count > 20) {
            count = 20;
        }

        // Don't mint more than supply
        if (count + totalSupply() > tokenLimit) {
            count = tokenLimit - totalSupply();
        }

        // Mint 'em
        for (uint256 i = 0; i < count; i++) {
            _createFace();
        }

        _mix();

        // Send any excess ETH back to the caller
        uint256 excess = msg.value - (salePrice * count);
        if (excess > 0) {
            (bool success,) = msg.sender.call{value : excess}("");
            require(success);
        }
    }

    // -- INTERNAL METHODS --

    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _createFace() internal {
        uint256 tokenId = totalSupply();
        _mint(msg.sender, tokenId);
    }

    function _mix() internal {
        // Add some pseudorandom value which will be mixed with the pre-committed secret
        unchecked {
            userSecret += uint256(blockhash(block.number - 1));
        }
    }

    /*************************
     NFT
     *************************/

    modifier onlyTokenExists(uint256 _id) {
        if (!_exists(_id)) {
            revert NonExistentToken();
        }
        _;
    }

    ChainFaces2Renderer public renderer;

    // -- VIEW METHODS --

    function assembleFace(uint256 _id) external view onlyTokenExists(_id) returns (string memory) {
        return renderer.assembleFace(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id));
    }

    function tokenURI(uint256 _id) public view override onlyTokenExists(_id) returns (string memory) {
        return renderer.renderMetadata(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id), roundsSurvived[_id], ownerOf(_id));
    }

    function renderSvg(uint256 _id) external view onlyTokenExists(_id) returns (string memory) {
        uint256 rounds;

        // If face is still in the arena, show them with correct amount of scars
        if (ownerOf(_id) == address(this)) {
            rounds = currentRound;
        } else {
            rounds = roundsSurvived[_id];
        }

        return renderer.renderSvg(stage == Stage.STAGE_COMPLETE, _id, getFinalizedSeed(_id), rounds, ownerOf(_id));
    }

    // -- INTERNAL METHODS --

    function getFinalizedSeed(uint256 _tokenId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(secret, _tokenId)));
    }

    /*************************
     ARENA
     *************************/

    uint256     arenaOpenedBlock;
    uint256     lionsLastFeeding;
    uint256     champion;

    uint256 public currentRound = 0;

    address constant happyFacePlace = 0x7039D65E346FDEEBbc72514D718C88699c74ba4b;
    uint256 public constant arenaWaitBlocks = 6969;
    uint256 public constant blocksPerRound = 69;

    mapping(uint256 => address) warriorDepositor;
    mapping(uint256 => uint256) public roundsSurvived;

    // -- MODIFIERS --

    modifier onlyOpenArena() {
        if (!entryOpen()) {
            revert ArenaEntryClosed();
        }
        _;
    }

    // -- VIEW METHODS --

    struct ArenaInfo {
        uint256 fallen;
        uint256 alive;
        uint256 currentRound;
        uint256 bounty;
        uint256 hunger;
        uint256 nextFeed;
        uint256 champion;
        uint256 entryClosedBlock;
        bool hungry;
        bool open;
        bool active;
        bool gameOver;
    }

    function arenaInfo() external view returns (ArenaInfo memory info) {
        info.fallen = balanceOf(happyFacePlace);
        info.alive = balanceOf(address(this));
        info.currentRound = currentRound;
        info.bounty = address(this).balance;
        info.hunger = howHungryAreTheLions();
        info.champion = champion;
        info.entryClosedBlock = entryClosedBlock();

        if (!theLionsAreHungry()) {
            info.nextFeed = lionsLastFeeding + blocksPerRound - block.number;
        }

        info.hungry = theLionsAreHungry();
        info.open = entryOpen();
        info.active = arenaActive();
        info.gameOver = block.number > info.entryClosedBlock && info.alive <= 1;
    }

    // Return array of msg.senders warriors filtered by alive or fallen
    function myWarriors(bool _alive) external view returns (uint256[] memory) {
        return ownerWarriors(msg.sender, _alive);
    }

    // Return array of owner's warriors filtered by alive or fallen
    function ownerWarriors(address _owner, bool _alive) public view returns (uint256[] memory) {
        address holdingAddress;
        if (_alive) {
            holdingAddress = address(this);
        } else {
            holdingAddress = happyFacePlace;
        }

        uint256 total = balanceOf(holdingAddress);
        uint256[] memory warriors = new uint256[](total);

        uint256 index = 0;

        for (uint256 i = 0; i < total; i++) {
            uint256 id = tokenOfOwnerByIndex(holdingAddress, i);

            if (warriorDepositor[id] == _owner) {
                warriors[index++] = id;
            }
        }

        assembly {
            mstore(warriors, index)
        }

        return warriors;
    }

    function arenaActive() public view returns (bool) {
        return arenaOpenedBlock > 0;
    }

    function entryOpen() public view returns (bool) {
        return arenaActive() && block.number < entryClosedBlock();
    }

    function entryClosedBlock() public view returns (uint256) {
        return arenaOpenedBlock + arenaWaitBlocks;
    }

    function totalSurvivingWarriors() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function howHungryAreTheLions() public view returns (uint256) {
        uint256 totalWarriors = totalSurvivingWarriors();

        if (totalWarriors == 0) {
            return 0;
        }

        uint256 hunger = 1;

        // Calculate how many warriors got eaten (0.2% of warriors > 1000)
        if (totalWarriors >= 2000) {
            uint256 excess = totalWarriors - 1000;
            hunger = excess / 500;
        }

        // Never eat the last man standing
        if (hunger >= totalWarriors) {
            hunger = totalWarriors - 1;
        }

        // Generous upper bound to prevent gas overflow
        if (hunger > 50) {
            hunger = 50;
        }

        return hunger;
    }

    function theLionsAreHungry() public view returns (bool) {
        return block.number >= lionsLastFeeding + blocksPerRound;
    }

    // -- OWNER METHODS --

    function openArena() external payable onlyOwner onlySaleComplete {
        if (arenaActive()) {
            revert ArenaIsActive();
        }
        if (balanceNotWithdrawn) {
            revert BalanceNotWithdrawn();
        }

        // Open the arena
        arenaOpenedBlock = block.number;
        lionsLastFeeding = block.number + arenaWaitBlocks;
    }

    // -- USER METHODS --

    // Can be called every `blocksPerRound` blocks to kill off some eager warriors
    function timeToEat() external {
        if (!arenaActive()) {
            revert ArenaNotActive();
        }
        if (!theLionsAreHungry()) {
            revert LionsNotHungry();
        }

        uint256 totalWarriors = totalSurvivingWarriors();
        if (totalWarriors == 1) {
            revert LastManStanding();
        }
        if (totalWarriors == 0) {
            revert GameOver();
        }

        // The blockhash of every `blocksPerRound` block is used to determine who gets eaten
        uint256 entropyBlock;
        if (block.number - (lionsLastFeeding + blocksPerRound) > 255) {
            // If this method isn't called within 255 blocks of the period end, this is a fallback so we can still progress
            entropyBlock = (block.number / blocksPerRound) * blocksPerRound - 1;
        } else {
            // Use blockhash of every 69th block
            entropyBlock = (lionsLastFeeding + blocksPerRound) - 1;
        }
        uint256 entropy = uint256(blockhash(entropyBlock));
        assert(entropy != 0);

        // Update state
        lionsLastFeeding = block.number;
        currentRound++;

        // Kill off a percentage of warriors
        uint256 killCounter = howHungryAreTheLions();
        bytes memory buffer = new bytes(32);
        for (uint256 i = 0; i < killCounter; i++) {
            uint256 tmp;
            unchecked { tmp = entropy + i; }
            // Gas saving trick to avoid abi.encodePacked
            assembly { mstore(add(buffer, 32), tmp) }
            uint256 whoDied = uint256(keccak256(buffer)) % totalWarriors;
            // Go to your happy place, loser
            uint256 faceToEat = tokenOfOwnerByIndex(address(this), whoDied);
            _transfer(address(this), happyFacePlace, faceToEat);
            // Take one down
            totalWarriors--;
        }

        // Record the champion
        if (totalWarriors == 1) {
            champion = tokenOfOwnerByIndex(address(this), 0);
        }
    }

    function joinArena(uint256 _tokenId) external onlyOpenArena {
        _joinArena(_tokenId);
    }

    function multiJoinArena(uint256[] memory _tokenIds) external onlyOpenArena {
        if (_tokenIds.length > 20) {
            revert InvalidJoinCount();
        }

        for (uint256 i; i < _tokenIds.length; i++) {
            _joinArena(_tokenIds[i]);
        }
    }

    function leaveArena(uint256 _tokenId) external {
        if (warriorDepositor[_tokenId] != msg.sender) {
            revert NotYourWarrior();
        }

        // Can't leave arena if lions are hungry (unless it's the champ and the game is over)
        uint256 survivors = totalSurvivingWarriors();
        if (survivors != 1 && theLionsAreHungry()) {
            revert LionsAreHungry();
        }

        // Can't leave before a single round has passed
        uint256 round = currentRound;
        if (currentRound == 0) {
            revert LeavingProhibited();
        }

        // Record the warrior's achievement
        roundsSurvived[_tokenId] = round;

        // Clear state
        delete warriorDepositor[_tokenId];

        // Return warrior and pay bounty
        uint256 battleBounty = address(this).balance / survivors;
        _transfer(address(this), msg.sender, _tokenId);
        payable(msg.sender).transfer(battleBounty);

        // If this was the second last warrior to leave, the last one left is the champ
        if (survivors == 2) {
            champion = tokenOfOwnerByIndex(address(this), 0);
        }
    }

    // -- INTERNAL METHODS --

    function _joinArena(uint256 _tokenId) internal {
        // Send warrior to the arena
        transferFrom(msg.sender, address(this), _tokenId);
        warriorDepositor[_tokenId] = msg.sender;
    }

    /*************************
     MISC
     *************************/

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

contract ChainFaces2Renderer {

    using Strings for uint256;

    address public constant happyFacePlace = 0x7039D65E346FDEEBbc72514D718C88699c74ba4b;

    // Rendering constants
    string[18] public leftFaceArray = [unicode"ლ", unicode"ᕦ", unicode"(ง", unicode"𐐋", unicode"ᖳ", unicode"Ƹ", unicode"ᛩ", unicode"⦃", unicode"{", unicode"⦗", unicode"〈", unicode"⧼", unicode"|", unicode"〘", unicode"〚", unicode"【", unicode"[", unicode"❪"];
    string[20] public leftEyeArray = [unicode"⚈", unicode"⚙", unicode"⊗", unicode"⋗", unicode" ͡°", unicode"◈", unicode"◬", unicode"≻", unicode"᛫", unicode"⨕", unicode"★", unicode"Ͼ", unicode"ᗒ", unicode"◠", unicode"⊡", unicode"⊙", unicode"▸", unicode"˘", unicode"⦿", unicode"●"];
    string[22] public mouthArray = [unicode"෴", unicode"∪", unicode"ᨏ", unicode"᎔", unicode"᎑", unicode"⋏", unicode"⚇", unicode"_", unicode"۷", unicode"▾", unicode"ᨎ", unicode"ʖ", unicode"ܫ", unicode"໒", unicode"𐑒", unicode"⌴", unicode"‿", unicode"𐠑", unicode"⌒", unicode"◡", unicode"⥿", unicode"⩊"];
    string[20] public rightEyeArray = [unicode"⚈", unicode"⚙", unicode"⊗", unicode"⋖", unicode" ͡°", unicode"◈", unicode"◬", unicode"≺", unicode"᛫", unicode"⨕", unicode"★", unicode"Ͽ", unicode"ᗕ", unicode"◠", unicode"⊡", unicode"⊙", unicode"◂", unicode"˘", unicode"⦿", unicode"●"];
    string[18] public rightFaceArray = [unicode"ლ", unicode"ᕤ", unicode")ง", unicode"𐐙", unicode"ᖰ", unicode"Ʒ", unicode"ᚹ", unicode"⦄", unicode"}", unicode"⦘", unicode"〉", unicode"⧽", unicode"|", unicode"〙", unicode"〛", unicode"】", unicode"]", unicode"❫"];

    uint256[22] rarityArray = [0, 2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135, 152, 170, 189, 209, 230, 252];

    uint256[5][] ancients;

    constructor() {
        ancients.push([0, 0, 0, 0, 0]);
        ancients.push([1, 1, 1, 1, 1]);
        ancients.push([2, 2, 2, 2, 2]);
        ancients.push([3, 3, 3, 3, 3]);
        ancients.push([4, 4, 4, 4, 4]);
        ancients.push([5, 5, 5, 5, 5]);
        ancients.push([6, 6, 6, 6, 6]);
        ancients.push([7, 7, 7, 7, 7]);
        ancients.push([8, 8, 8, 8, 8]);
        ancients.push([9, 9, 9, 9, 9]);
    }

    function getLeftFace(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return leftFaceArray[ancients[id][0]];
        }

        uint256 raritySelector = seed % 189;

        uint256 charSelector = 0;

        for (uint i = 0; i < 18; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return leftFaceArray[charSelector];
    }

    function getLeftEye(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return leftEyeArray[ancients[id][1]];
        }

        uint256 raritySelector = seed % 230;

        uint256 charSelector = 0;

        for (uint i = 0; i < 20; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return leftEyeArray[charSelector];
    }

    function getMouth(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return mouthArray[ancients[id][2]];
        }

        uint256 raritySelector = seed % 275;

        uint256 charSelector = 0;

        for (uint i = 0; i < 22; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return mouthArray[charSelector];
    }

    function getRightEye(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return rightEyeArray[ancients[id][3]];
        }

        uint256 raritySelector = uint256(keccak256(abi.encodePacked(seed))) % 230;

        uint256 charSelector = 0;

        for (uint i = 0; i < 20; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return rightEyeArray[charSelector];
    }

    function getRightFace(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return rightFaceArray[ancients[id][4]];
        }

        uint256 raritySelector = uint256(keccak256(abi.encodePacked(seed))) % 189;

        uint256 charSelector = 0;

        for (uint i = 0; i < 18; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return rightFaceArray[charSelector];
    }

    function assembleFace(bool revealComplete, uint256 id, uint256 seed) public view returns (string memory face) {
        if (!revealComplete) {
            return '(._.)';
        }

        return string(abi.encodePacked(
                getLeftFace(id, seed),
                getLeftEye(id, seed),
                getMouth(id, seed),
                getRightEye(id, seed),
                getRightFace(id, seed)
            ));
    }

    function calculateGolfScore(uint256 id, uint256 seed) public view returns (uint256) {
        if (id < ancients.length) {
            return 0;
        }

        uint256 leftFaceRarity = seed % 189;
        uint256 lefEyeRarity = seed % 230;
        uint256 mouthRarity = seed % 275;
        uint256 rightEyeRarity = uint256(keccak256(abi.encodePacked(seed))) % 230;
        uint256 rightFaceRarity = uint256(keccak256(abi.encodePacked(seed))) % 189;

        uint256 leftFaceGolf = 0;
        uint256 leftEyeGolf = 0;
        uint256 mouthGolf = 0;
        uint256 rightEyeGolf = 0;
        uint256 rightFaceGolf = 0;
        uint256 i = 0;

        for (i = 0; i < 18; i++) {
            if (leftFaceRarity >= rarityArray[i]) {
                leftFaceGolf = i;
            }
        }
        for (i = 0; i < 20; i++) {
            if (lefEyeRarity >= rarityArray[i]) {
                leftEyeGolf = i;
            }
        }
        for (i = 0; i < 22; i++) {
            if (mouthRarity >= rarityArray[i]) {
                mouthGolf = i;
            }
        }
        for (i = 0; i < 20; i++) {
            if (rightEyeRarity >= rarityArray[i]) {
                rightEyeGolf = i;
            }
        }
        for (i = 0; i < 18; i++) {
            if (rightFaceRarity >= rarityArray[i]) {
                rightFaceGolf = i;
            }
        }

        return leftFaceGolf + leftEyeGolf + mouthGolf + rightEyeGolf + rightFaceGolf;
    }

    function calculateSymmetry(uint256 id, uint256 seed) public view returns (string memory) {

        uint256 symCount = 0;

        if (id < ancients.length) {
            symCount = 2;
        } else {
            uint256 leftFaceRarity = seed % 189;
            uint256 lefEyeRarity = seed % 230;
            uint256 rightEyeRarity = uint256(keccak256(abi.encodePacked(seed))) % 230;
            uint256 rightFaceRarity = uint256(keccak256(abi.encodePacked(seed))) % 189;

            uint256 leftFaceIndex = 0;
            uint256 leftEyeIndex = 0;
            uint256 rightEyeIndex = 0;
            uint256 rightFaceIndex = 0;
            uint256 i = 0;

            for (i = 0; i < 18; i++) {
                if (leftFaceRarity >= rarityArray[i]) {
                    leftFaceIndex = i;
                }
            }
            for (i = 0; i < 20; i++) {
                if (lefEyeRarity >= rarityArray[i]) {
                    leftEyeIndex = i;
                }
            }
            for (i = 0; i < 20; i++) {
                if (rightEyeRarity >= rarityArray[i]) {
                    rightEyeIndex = i;
                }
            }
            for (i = 0; i < 18; i++) {
                if (rightFaceRarity >= rarityArray[i]) {
                    rightFaceIndex = i;
                }
            }

            if (leftFaceIndex == rightFaceIndex) {
                symCount = symCount + 1;
            }
            if (leftEyeIndex == rightEyeIndex) {
                symCount = symCount + 1;
            }
        }

        if (symCount == 2) {
            return "100% Symmetry";
        }
        else if (symCount == 1) {
            return "Partial Symmetry";
        }
        else {
            return "No Symmetry";
        }
    }

    function getTextColor(uint256 id) public view returns (string memory) {
        if (id < ancients.length) {
            return 'RGB(148,256,209)';
        } else {
            return 'RGB(0,0,0)';
        }
    }

    function getBackgroundColor(uint256 id, uint256 seed, address owner) public view returns (string memory){
        if (id < ancients.length) {
            return 'RGB(128,128,128)';
        }

        uint256 golf = calculateGolfScore(id, seed);
        uint256 red;
        uint256 green;
        uint256 blue;

        if (owner == happyFacePlace) {
            red = 255;
            green = 128;
            blue = 128;
        }
        else if (golf >= 56) {
            red = 255;
            green = 255;
            blue = 255 - (golf - 56) * 4;
        }
        else {
            red = 255 - (56 - golf) * 4;
            green = 255 - (56 - golf) * 4;
            blue = 255;
        }

        return string(abi.encodePacked("RGB(", red.toString(), ",", green.toString(), ",", blue.toString(), ")"));
    }

    string constant headerText = 'data:application/json;ascii,{"description": "We are warrior ChainFaces. Here to watch over you forever, unless we get eaten by lions.","image":"data:image/svg+xml;base64,';
    string constant attributesText = '","attributes":[{"trait_type":"Golf Score","value":';
    string constant symmetryText = '},{"trait_type":"Symmetry","value":"';
    string constant leftFaceText = '"},{"trait_type":"Left Face","value":"';
    string constant leftEyeText = '"},{"trait_type":"Left Eye","value":"';
    string constant mouthText = '"},{"trait_type":"Mouth","value":"';
    string constant rightEyeText = '"},{"trait_type":"Right Eye","value":"';
    string constant rightFaceText = '"},{"trait_type":"Right Face","value":"';
    string constant arenaDurationText = '"},{"trait_type":"Arena Score","value":';
    string constant ancientText = '},{"trait_type":"Ancient","value":"';
    string constant footerText = '"}]}';

    function renderMetadata(bool revealComplete, uint256 id, uint256 seed, uint256 arenaDuration, address owner) external view returns (string memory) {
        if (!revealComplete) {
            return preRevealMetadata();
        }

        uint256 golfScore = calculateGolfScore(id, seed);

        string memory svg = b64Encode(bytes(renderSvg(true, id, seed, arenaDuration, owner)));

        string memory attributes = string(abi.encodePacked(attributesText, golfScore.toString()));
        attributes = string(abi.encodePacked(attributes, symmetryText, calculateSymmetry(id, seed)));
        attributes = string(abi.encodePacked(attributes, leftFaceText, getLeftFace(id, seed)));
        attributes = string(abi.encodePacked(attributes, leftEyeText, getLeftEye(id, seed)));
        attributes = string(abi.encodePacked(attributes, mouthText, getMouth(id, seed)));
        attributes = string(abi.encodePacked(attributes, rightEyeText, getRightEye(id, seed)));
        attributes = string(abi.encodePacked(attributes, rightFaceText, getRightFace(id, seed)));
        attributes = string(abi.encodePacked(attributes, arenaDurationText, arenaDuration.toString()));

        if (id < ancients.length) {
            attributes = string(abi.encodePacked(attributes, ancientText, 'Ancient'));
        } else {
            attributes = string(abi.encodePacked(attributes, ancientText, 'Not Ancient'));
        }

        attributes = string(abi.encodePacked(attributes, footerText));

        return string(abi.encodePacked(headerText, svg, attributes));
    }

    string constant svg1 = "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400' style='background-color:";
    string constant svg2 = "'>";
    string constant svg3 = "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px' fill='";
    string constant svg4 = "'>";
    string constant svg5 = "</text></svg>";

    function renderSvg(bool revealComplete, uint256 id, uint256 seed, uint256 arenaDuration, address owner) public view returns (string memory) {
        if (!revealComplete) {
            return preRevealSvg();
        }

        string memory face = assembleFace(true, id, seed);
        string memory scars;

        if (arenaDuration > 0) {
            scars = generateScars(arenaDuration, seed);
        }

        return string(abi.encodePacked(svg1, getBackgroundColor(id, seed, owner), svg2, scars, svg3, getTextColor(id), svg4, face, svg5));
    }

    string constant scarSymbol = "<symbol id='scar'><g stroke='RGBA(200,40,40,.35)'><text x='40' y='40' dominant-baseline='middle' text-anchor='middle' font-weight='bold' font-size='22px' fill='RGBA(200,40,40,.45)'>++++++</text></g></symbol>";
    string constant scarPlacement1 = "<g transform='translate(";
    string constant scarPlacement2 = ") scale(";
    string constant scarPlacement3 = ") rotate(";
    string constant scarPlacement4 = ")'><use href='#scar'/></g>";

    function generateScars(uint256 arenaDuration, uint256 seed) internal pure returns (string memory) {
        string memory scars;
        string memory scarsTemp;

        uint256 count = arenaDuration / 10;

        if (count > 500) {
            count = 500;
        }

        for (uint256 i = 0; i < count; i++) {
            string memory scar;

            uint256 scarSeed = uint256(keccak256(abi.encodePacked(seed, i)));

            uint256 scale1 = scarSeed % 2;
            uint256 scale2 = scarSeed % 5;
            if (scale1 == 0) {
                scale2 += 5;
            }
            uint256 xShift = scarSeed % 332;
            uint256 yShift = scarSeed % 354;
            int256 rotate = int256(scarSeed % 91) - 45;

            scar = string(abi.encodePacked(scar, scarPlacement1, xShift.toString(), " ", yShift.toString(), scarPlacement2, scale1.toString(), ".", scale2.toString()));

            if (rotate >= 0) {
                scar = string(abi.encodePacked(scar, scarPlacement3, uint256(rotate).toString(), scarPlacement4));
            } else {
                scar = string(abi.encodePacked(scar, scarPlacement3, "-", uint256(0 - rotate).toString(), scarPlacement4));
            }

            scarsTemp = string(abi.encodePacked(scarsTemp, scar));

            if (i % 10 == 0) {
                scars = string(abi.encodePacked(scars, scarsTemp));
                scarsTemp = "";
            }
        }

        return string(abi.encodePacked(scarSymbol, scars, scarsTemp));
    }

    function preRevealMetadata() internal pure returns (string memory) {
        string memory JSON;
        string memory svg = preRevealSvg();
        JSON = string(abi.encodePacked('data:application/json;ascii,{"description": "We are warrior ChainFaces. Here to watch over you forever, unless we get eaten by lions.","image":"data:image/svg+xml;base64,', b64Encode(bytes(svg)), '"}'));
        return JSON;
    }

    function preRevealSvg() internal pure returns (string memory) {
        return "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400' style='background-color:RGB(255,255,255);'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px'>?????</text></svg>";
    }

    string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function b64Encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = TABLE;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }
        return result;
    }
}

pragma solidity 0.8.7;

// Sale
error SaleNotOpen();
error NotPreSaleStage();
error NotMainSaleStage();
error SaleNotComplete();
error MainSaleNotComplete();
error AlreadyClaimed();
error InvalidClaimValue();
error InvalidClaimAmount();
error InvalidProof();
error InvalidMintValue();

// NFT
error NonExistentToken();

// Reveal
error InvalidReveal();
error BalanceNotWithdrawn();
error BalanceAlreadyWithdrawn();

// Arena
error LeavingProhibited();
error ArenaIsActive();
error ArenaNotActive();
error ArenaEntryClosed();
error LionsNotHungry();
error LionsAreHungry();
error LastManStanding();
error GameOver();
error InvalidJoinCount();
error NotYourWarrior();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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