// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "OwnerOrAuthorized.sol";
import "CryptoCardsMessages.sol";
import "CryptoCardsStorage.sol";
import "CryptoCardsFactory.sol";

contract CryptoCards is ERC721Enumerable, OwnerOrAuthorized {
    using Strings for uint256;

    bool public paused;
    CryptoCardsMessages public messages;
    CryptoCardsStorage public store;
    CryptoCardsFactory public factory;

    event CardsMinted(address to, uint256 symbol, uint256[] ids);
    event DeckMinted(address to, uint256 symbol);
    event HandMinted(address to, uint256[5] ids, uint256 handId);
    event ModifiedCardMinted(address to, uint256 id);

    constructor(
        string memory _name,
        string memory _symbol,
        address _messages,
        address _storage,
        address _factory
    ) ERC721(_name, _symbol) {
        messages = CryptoCardsMessages(_messages);
        store = CryptoCardsStorage(_storage);
        factory = CryptoCardsFactory(_factory);
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return store.baseURI();
    }

    function _mintCards(
        address _to,
        uint256 _mintAmount,
        uint256 _symbol,
        uint256 _modifierCard
    ) internal {
        uint256[] memory cardIds = factory.createCards(
            _mintAmount,
            _symbol,
            _modifierCard
        );
        for (uint256 i = 0; i < cardIds.length; i++) {
            _safeMint(_to, cardIds[i]);
        }

        emit CardsMinted(_to, _symbol, cardIds);
    }

    function _addCreatorRewards(
        uint256 _symbol,
        uint256 _modifierCard,
        uint256 _mintingCost
    ) internal {
        uint32 rewardPercentage = store.rewardPercentage();
        uint256 rewardAmount = (_mintingCost * rewardPercentage) / 100;

        // If card(s) were minted using modifier card then add
        // reward amount to modifier card creator's balance (excluding contract owner)
        if (_modifierCard > 0) {
            address creator = store.getModifierCardCreator(_modifierCard);
            if (creator != address(0) && creator != owner()) {
                store.addCreatorRewardTransaction(
                    creator,
                    _modifierCard,
                    0,
                    rewardAmount,
                    0
                );
            }
        } else {
            // Otherwise add to reward amount to symbol creator's balance (excluding contract owner)
            address creator = store.getSymbolCreator(_symbol);
            if (creator != address(0) && creator != owner()) {
                store.addCreatorRewardTransaction(
                    creator,
                    0,
                    _symbol,
                    rewardAmount,
                    0
                );
            }
        }
    }

    function _checkMintingParams(address _to, uint256 _mintCost) internal {
        if (msg.sender != owner()) {
            require(!paused, messages.notAvailable());
            require(msg.value >= _mintCost, messages.notEnoughFunds());
        }
        require(_to != address(0), messages.zeroAddress());
    }

    // Public
    function burn(uint256 _tokenId) public {
        require(!paused, messages.notAvailable());
        require(ownerOf(_tokenId) == msg.sender, messages.mustBeOwner());

        // Hand?
        if (store.getHandOwner(_tokenId) == msg.sender) {
            uint256[5] memory hand = store.getHandCards(_tokenId);

            // Re-allocate cards back to sender
            for (uint256 i = 0; i < hand.length; i++) {
                _safeMint(msg.sender, hand[i]);
            }

            store.setHandOwner(_tokenId, address(0));
            store.setHandCards(
                _tokenId,
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
            );
        }
        _burn(_tokenId);
    }

    function mintCards(
        address _to,
        uint256 _mintAmount,
        uint256 _symbol,
        uint256 _modifierCard
    ) public payable {
        uint256 mintingCost = _modifierCard > 0
            ? (store.cardCost() * 2 * _mintAmount)
            : (store.cardCost() * _mintAmount);
        _checkMintingParams(_to, mintingCost);

        require(store.getSymbolInUse(_symbol), messages.symbolNotFound());
        if (_modifierCard > 0) {
            require(
                ownerOf(_modifierCard) == msg.sender,
                messages.mustBeOwner()
            );
        }

        _mintCards(_to, _mintAmount, _symbol, _modifierCard);
        _addCreatorRewards(_symbol, _modifierCard, mintingCost);
    }

    function mintDeck(address _to, uint256 _symbol) public payable {
        _checkMintingParams(_to, store.deckCost());

        if (msg.sender != owner()) {
            require(store.getDeckMintUnlocking() == 0, messages.notAvailable());
        }
        require(!store.getSymbolInUse(_symbol), messages.symbolInUse());

        // Add new symbol
        store.addSymbol(_to, _symbol);

        // Create initial shuffled deck
        factory.createDeck(_symbol);

        // Mint cards to new deck owner
        _mintCards(_to, store.maxMintAmount(), _symbol, 0);

        store.resetDeckMintUnlocking();

        emit DeckMinted(_to, _symbol);
    }

    function mintHand(address _to, uint256[5] memory _tokenIds) public payable {
        _checkMintingParams(_to, store.handCost());

        uint256 supply = store.getTotalCards();
        require(supply + 1 <= store.maxSupply(), messages.exceedsSupply());
        require(_tokenIds.length == 5, messages.fiveCardsRequired());

        // Check that the sender is the owner of all the cards
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0, messages.fiveCardsRequired());
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                messages.mustBeOwner()
            );
        }

        // Save tokenIds of cards in the data property
        uint256 data = (_tokenIds[0] & 0xFFFFFF) |
            ((_tokenIds[1] & 0xFFFFFF) << 24) |
            ((_tokenIds[2] & 0xFFFFFF) << 48) |
            ((_tokenIds[3] & 0xFFFFFF) << 72) |
            ((_tokenIds[4] & 0xFFFFFF) << 96);

        uint256 handTokenId = store.addCard(
            factory.createCard(DecodedCard(HAND_CARD, 0, 0, 0, 0, 0, 0), data)
        );
        _safeMint(_to, handTokenId);

        // Burn cards so that they cannot be minted into a hand again.
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
        }

        store.setHandOwner(handTokenId, _to);

        // Save the tokenIds that form the hand so they can be re-instated if the hand is ever burnt
        store.setHandCards(handTokenId, _tokenIds);

        emit HandMinted(_to, _tokenIds, handTokenId);
    }

    function mintModifiedCard(
        address _to,
        uint256 _originalCard,
        uint256 _modifierCard
    ) public payable {
        _checkMintingParams(_to, store.cardCost() * 2);

        require(ownerOf(_originalCard) == msg.sender, messages.mustBeOwner());
        require(ownerOf(_modifierCard) == msg.sender, messages.mustBeOwner());

        uint256 cardId = factory.createModifiedCard(
            _originalCard,
            _modifierCard
        );
        _safeMint(_to, cardId);
        _addCreatorRewards(0, _modifierCard, store.cardCost() * 2);

        emit ModifiedCardMinted(_to, cardId);
    }

    function mintModifierCard(
        address _to,
        string memory _name,
        uint256 _value,
        uint256 _background,
        uint256 _foreground,
        uint256 _color,
        uint256 _flags,
        bytes memory _data
    ) public payable returns (uint256) {
        _checkMintingParams(_to, store.modifierCost());

        require(bytes(_name).length > 0, messages.nameRequired());
        require(
            store.getModifierCardIdByName(_name) == 0,
            messages.modifierNameAlreadyInUse()
        );
        require(_data.length <= 256, messages.dataLengthExceeded());

        uint256 newCardId = factory.createModifierCard(
            _value,
            _background,
            _foreground,
            _color,
            _flags
        );
        _safeMint(_to, newCardId);
        store.addModifierCard(newCardId, _to, _name, _data);
        return newCardId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), messages.erc721InvalidTokenId());

        bool usePermanentStorage = store.getUsePermanentStorage(tokenId);
        string memory currentBaseURI = usePermanentStorage
            ? store.permanentStorageBaseURI()
            : _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        usePermanentStorage
                            ? store.permanentStorageExtension()
                            : store.baseExtension()
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function getCreatorRewardsBalance(address _creator)
        public
        view
        returns (uint256)
    {
        return store.getCreatorRewardsBalance(_creator);
    }

    function getCreatorRewards(address _creator)
        public
        view
        returns (Reward[] memory)
    {
        return store.getCreatorRewards(_creator);
    }

    function withdrawRewardBalance() public payable {
        uint256 contractBalance = address(this).balance;
        uint256 callerRewards = getCreatorRewardsBalance(msg.sender);
        require(callerRewards < contractBalance, messages.notEnoughFunds());
        store.addCreatorRewardTransaction(msg.sender, 0, 0, 0, callerRewards);
        require(payable(msg.sender).send(callerRewards));
    }

    // Only owner
    function setPaused(bool _value) public onlyOwner {
        paused = _value;
    }

    function getNetBalance() public view onlyOwner returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 totalCreatorRewards = store.getTotalRewardsBalance();
        return contractBalance - totalCreatorRewards;
    }

    function withdrawNetBalance() public payable onlyOwner {
        uint256 ownerBalance = getNetBalance();
        require(ownerBalance > 0, messages.notEnoughFunds());
        require(payable(msg.sender).send(ownerBalance));
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Enumerable.sol";

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

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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

import "IERC165.sol";

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

import "IERC721.sol";

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

import "IERC165.sol";

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

import "IERC721.sol";

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

// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "Ownable.sol";

contract OwnerOrAuthorized is Ownable {
    mapping(address => bool) private _authorized;

    event AuthorizationAdded(address indexed addressAdded);
    event AuthorizationRemoved(address addressRemoved);

    constructor() Ownable() {
        _authorized[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than an authorized user (includes owner).
     */
    modifier onlyAuthorized() {
        require(
            checkAuthorization(_msgSender()),
            "OwnOwnerOrAuthorized: caller is not authorized"
        );
        _;
    }

    function addAuthorization(address _address) public onlyOwner {
        _authorized[_address] = true;
        emit AuthorizationAdded(_address);
    }

    function removeAuthorization(address _address) public {
        require(
            owner() == _msgSender() || _authorized[_address] == true,
            "OwnOwnerOrAuthorized: caller is not authorized"
        );
        delete _authorized[_address];
        emit AuthorizationRemoved(_address);
    }

    function checkAuthorization(address _address) public view returns (bool) {
        return owner() == _address || _authorized[_address] == true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

contract CryptoCardsMessages {
    string public notAvailable = "Feature not currently available";
    string public mintAmount = "Mint Amount";
    string public exceedsSupply = "Supply exceeded";
    string public exceedsDeckSupply = "Deck supply exceeded";
    string public fiveCardsRequired = "Five cards required";
    string public zeroAddress = "Zero address";
    string public mustBeOwner = "Must be owner";
    string public notEnoughFunds = "Not enough funds";
    string public existingModifier = "Modifier exists";
    string public nameRequired = "Name required";
    string public modifierUsage = "Modifier usage exceeded";
    string public modifierNotFound = "Modifier not found";
    string public erc721InvalidTokenId = "URI query for nonexistent token";
    string public symbolInUse = "Symbol already exists";
    string public symbolNotFound = "Symbol not found";
    string public missingShuffledDeck = "Missing shuffled deck for symbol";
    string public modifierDataFull = "The card cannot accept further modifiers";
    string public modifierNameAlreadyInUse =
        "The specified name is already in use";
    string public dataLengthExceeded = "Data length (256 bytes) exceeded";
}

// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "OwnerOrAuthorized.sol";

uint256 constant MODIFIER_CARD = 0x40;
uint256 constant HAND_CARD = 0x20;
uint256 constant BITOFFSET_SUIT = 8;
uint256 constant BITOFFSET_BACKGROUND = 16;
uint256 constant BITOFFSET_FOREGROUND = 48;
uint256 constant BITOFFSET_COLOR = 80;
uint256 constant BITOFFSET_SYMBOL = 112;
uint256 constant BITOFFSET_FLAGS = 144;
uint256 constant DEFAULT_BACKGROUND = 0xff00a300;
uint256 constant DEFAULT_MODIFIER_BACKGROUND = 0xff1a1a1a;
uint256 constant DEFAULT_FOREGROUND = 0xff000000;
uint256 constant DEFAULT_COLOR = 0xffffffff;
uint256 constant FLAGS_SET_BACKGROUND = 1;
uint256 constant FLAGS_SET_FOREGROUND = 2;
uint256 constant FLAGS_SET_COLOR = 4;
uint256 constant FLAGS_DATA_APPEND = 8;
bytes constant PRE_SHUFFLED_DECK = hex"190E0F1E2722111D02040B2E13331209150100240A180D16321B25260C312A07282C1C0820142B101A17293006052F2D23211F03";

/*  attributes = [
        bytes 0: value  0..0xC = Card face value | 0x40 = Modifier Card | 0x20 = Hand Card
        bytes 1: suit
        bytes 2..5: background
        bytes 6..9: foreground
        bytes 10..13: color
        bytes 14..17: symbol
        bytes 18..31: modifier flags; on a modifier card this specifies how the data will be applied:
            0x1 = background copied from modifier card
            0x2 = foreground copied from modifier card
            0x4 = color copied from modifier card
            0x8 = modifiers will be appended with modifier card id instead of overwritten
    ]
    modifiers: [32 bytes] essentially an array of modifier ids (16 bit)
*/
struct Card {
    uint256 attributes;
    uint256 modifiers;
}

struct ModifierCard {
    address creator;
    uint256 usageCount;
    string name;
    bytes data; // Seems to be a 256 byte limit??
}

struct Reward {
    uint256 timestamp;
    uint256 modifierCardId;
    uint256 symbolId;
    int256 value;
}

contract CryptoCardsStorage is OwnerOrAuthorized {
    bytes private preShuffledDeck = PRE_SHUFFLED_DECK;
    string public baseURI;
    string public baseExtension;
    string public permanentStorageBaseURI;
    string public permanentStorageExtension;
    uint256 public cardCost = 0.1 ether;
    uint256 public handCost = 1 ether;
    uint256 public deckCost = 10 ether;
    uint256 public modifierCost = 2 ether;
    uint256 private deckMintUnlocking = 100;
    uint256 public defaultDeckMintUnlocking = 200;
    uint32 public maxCardsPerDeck = 1000;
    uint32 public maxModifierUsage = 100;
    uint32 public maxSupply = 65535; // Hard limit due to 16 bit numbers use to store modifier ids on cards
    uint32 public maxMintAmount = 10;
    uint32 public rewardPercentage = 50;
    Card[] public cards;
    uint256[] public symbols;
    uint256[] public modifiers;
    address[] public creators;

    // Mapping hand tokenId to owner address
    mapping(uint256 => address) public handOwners;

    // Mapping hand tokenId to card tokenIds used to mint hand
    mapping(uint256 => uint256[5]) private handCards;

    // Mapping deck => card count
    mapping(uint256 => uint256) public deckCardCounts;

    // Mapping modifier card id to data
    mapping(uint256 => ModifierCard) public modifierCards;

    // Mapping modifier card name to id
    mapping(string => uint256) public modifierCardNames;

    // Mapping symbol in use
    mapping(uint256 => bool) private symbolInUse;

    // Mapping symbol to creator
    mapping(uint256 => address) private symbolCreators;

    // Mapping creator to rewards
    mapping(address => Reward[]) private creatorRewards;

    // Mapping creator to reward balance
    mapping(address => uint256) private creatorRewardsBalance;

    // Mapping creator to known
    mapping(address => bool) private knownCreators;

    // Mapping symbol to shuffled deck
    mapping(uint256 => bytes) private shuffledDecks;

    // Mapping tokenId to TokenUri uses permanent storage
    mapping(uint256 => bool) public usePermanentStorage;

    constructor(string memory _initBaseURI, string memory _initExtension)
        OwnerOrAuthorized()
    {
        baseURI = _initBaseURI;
        baseExtension = _initExtension;
        permanentStorageBaseURI = _initBaseURI;
        permanentStorageExtension = _initExtension;
    }

    function addCard(Card memory _card)
        external
        onlyAuthorized
        returns (uint256)
    {
        cards.push(_card);
        uint256 symbol = (_card.attributes >> BITOFFSET_SYMBOL) & 0xFFFFFFFF;
        deckCardCounts[symbol]++;
        return cards.length - 1;
    }

    function addSymbol(address _creator, uint256 _symbol)
        external
        onlyAuthorized
    {
        if (!symbolInUse[_symbol]) {
            symbolInUse[_symbol] = true;
            symbolCreators[_symbol] = _creator;
            symbols.push(_symbol);
        }
    }

    function addModifierCard(
        uint256 _cardId,
        address _creator,
        string calldata _name,
        bytes calldata _data
    ) external onlyAuthorized {
        modifierCards[_cardId] = ModifierCard(_creator, 0, _name, _data);
        modifierCardNames[_name] = _cardId;
        modifiers.push(_cardId);
    }

    function addCreatorRewardTransaction(
        address _creator,
        uint256 _modifierCard,
        uint256 _symbol,
        uint256 _amountIn,
        uint256 _amountOut
    ) external onlyAuthorized {
        Reward[] storage rewards = creatorRewards[_creator];
        rewards.push(
            Reward(
                block.timestamp,
                _modifierCard,
                _symbol,
                int256(_amountIn) - int256(_amountOut)
            )
        );
        creatorRewardsBalance[_creator] += _amountIn;
        creatorRewardsBalance[_creator] -= _amountOut;
        if (knownCreators[_creator] == false) {
            knownCreators[_creator] = true;
            creators.push(_creator);
        }
    }

    function decrementDeckMintUnlocking() external onlyAuthorized {
        if (deckMintUnlocking > 0) {
            deckMintUnlocking--;
        }
    }

    function getCard(uint256 _cardId) external view returns (Card memory) {
        return cards[_cardId];
    }

    function getCreators() external view returns (address[] memory) {
        return creators;
    }

    function getCreatorRewards(address _creator)
        external
        view
        onlyAuthorized
        returns (Reward[] memory)
    {
        return creatorRewards[_creator];
    }

    function getCreatorRewardsBalance(address _creator)
        external
        view
        onlyAuthorized
        returns (uint256)
    {
        return creatorRewardsBalance[_creator];
    }

    function getDeckCardCount(uint256 _deckId) external view returns (uint256) {
        return deckCardCounts[_deckId];
    }

    function getDeckMintUnlocking()
        external
        view
        onlyAuthorized
        returns (uint256)
    {
        return deckMintUnlocking;
    }

    function getHandOwner(uint256 _handId) external view returns (address) {
        return handOwners[_handId];
    }

    function getHandCards(uint256 _handId)
        external
        view
        returns (uint256[5] memory)
    {
        return handCards[_handId];
    }

    function getModifierCardCreator(uint256 _cardId)
        external
        view
        returns (address)
    {
        return modifierCards[_cardId].creator;
    }

    function getModifierCardData(uint256 _cardId)
        external
        view
        returns (bytes memory)
    {
        return modifierCards[_cardId].data;
    }

    function getModifierCardIdByName(string calldata _name)
        external
        view
        returns (uint256)
    {
        return modifierCardNames[_name];
    }

    function getModifierCardInUse(uint256 _cardId)
        external
        view
        returns (bool)
    {
        return modifierCards[_cardId].creator != address(0);
    }

    function getModifierCardName(uint256 _cardId)
        external
        view
        returns (string memory)
    {
        return modifierCards[_cardId].name;
    }

    function getModifierCardUsageCount(uint256 _cardId)
        external
        view
        returns (uint256)
    {
        return modifierCards[_cardId].usageCount;
    }

    function getModifiers() external view returns (uint256[] memory) {
        return modifiers;
    }

    function getPreshuffledDeck()
        external
        view
        onlyAuthorized
        returns (bytes memory)
    {
        return preShuffledDeck;
    }

    function getShuffledDeck(uint256 _symbol)
        external
        view
        onlyAuthorized
        returns (bytes memory)
    {
        return shuffledDecks[_symbol];
    }

    function getSymbolInUse(uint256 _symbol) external view returns (bool) {
        return symbolInUse[_symbol];
    }

    function getSymbolCreator(uint256 _symbol) external view returns (address) {
        return symbolCreators[_symbol];
    }

    function getSymbols() external view returns (uint256[] memory) {
        return symbols;
    }

    function getTotalActiveModifiers() external view returns (uint256) {
        uint256 result;
        for (uint256 i; i < modifiers.length; i++) {
            if (modifierCards[i].usageCount < maxModifierUsage) {
                result++;
            }
        }
        return result;
    }

    function getTotalCards() external view returns (uint256) {
        return cards.length;
    }

    function getTotalModifiers() external view returns (uint256) {
        return modifiers.length;
    }

    function getTotalSymbols() external view returns (uint256) {
        return symbols.length;
    }

    function getTotalRewardsBalance() external view returns (uint256) {
        uint256 result;
        for (uint256 i; i < creators.length; i++) {
            if (creators[i] != address(0)) {
                result += creatorRewardsBalance[creators[i]];
            }
        }
        return result;
    }

    function getUsePermanentStorage(uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return usePermanentStorage[_tokenId];
    }

    function incrementModifierCardUsageCount(uint256 _cardId)
        external
        onlyAuthorized
    {
        modifierCards[_cardId].usageCount++;
    }

    function resetDeckMintUnlocking() external onlyAuthorized {
        deckMintUnlocking = defaultDeckMintUnlocking;
    }

    function setDeckMintUnlocking(uint256 _value) external onlyAuthorized {
        deckMintUnlocking = _value;
    }

    function setDefaultDeckMintUnlocking(uint256 _value)
        external
        onlyAuthorized
    {
        defaultDeckMintUnlocking = _value;
    }

    function setBaseURIAndExtension(
        string memory _newBaseURI,
        string memory _newBaseExtension
    ) external onlyAuthorized {
        baseURI = _newBaseURI;
        baseExtension = bytes(_newBaseExtension).length <= 1
            ? ""
            : _newBaseExtension;
    }

    function setPermanentStorageBaseURIAndExtension(
        string memory _newBaseURI,
        string memory _newExtension
    ) external onlyAuthorized {
        permanentStorageBaseURI = _newBaseURI;
        permanentStorageExtension = bytes(_newExtension).length <= 1
            ? ""
            : _newExtension;
    }

    function setCard(uint256 _cardId, Card calldata _value)
        external
        onlyAuthorized
    {
        cards[_cardId] = _value;
    }

    function setCosts(
        uint256 _cardCost,
        uint256 _handCost,
        uint256 _deckCost,
        uint256 _modifierCost
    ) external onlyAuthorized {
        cardCost = _cardCost;
        handCost = _handCost;
        deckCost = _deckCost;
        modifierCost = _modifierCost;
    }

    function setHandCards(uint256 _handId, uint256[5] calldata _cards)
        external
        onlyAuthorized
    {
        handCards[_handId] = _cards;
    }

    function setHandOwner(uint256 _handId, address _owner)
        external
        onlyAuthorized
    {
        handOwners[_handId] = _owner;
    }

    function setLimits(
        uint32 _maxMintAmount,
        uint32 _maxModifierUsage,
        uint32 _maxCardsPerDeck,
        uint32 _maxSupply
    ) external onlyAuthorized {
        if (_maxMintAmount > 0) maxMintAmount = _maxMintAmount;
        if (_maxModifierUsage > 0) maxModifierUsage = _maxModifierUsage;
        if (_maxCardsPerDeck > 0) maxCardsPerDeck = _maxCardsPerDeck;
        if (_maxSupply > 0) maxSupply = _maxSupply > 65535 ? 65535 : _maxSupply;
    }

    function setPreshuffledDeck(bytes memory _value) external onlyAuthorized {
        preShuffledDeck = _value;
    }

    function setRewardPercentage(uint32 _value) external onlyAuthorized {
        if (_value > 0 && _value <= 100) {
            rewardPercentage = _value;
        }
    }

    function setShuffledDeck(uint256 _symbol, bytes memory _value)
        external
        onlyAuthorized
    {
        shuffledDecks[_symbol] = _value;
    }

    function setUsePermanentStorage(uint256 _tokenId, bool _value)
        external
        onlyAuthorized
    {
        usePermanentStorage[_tokenId] = _value;
    }
}

// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "OwnerOrAuthorized.sol";
import "CryptoCardsMessages.sol";
import "CryptoCardsStorage.sol";

struct DecodedCard {
    uint256 value;
    uint256 suit;
    uint256 background;
    uint256 foreground;
    uint256 color;
    uint256 symbol;
    uint256 modifierFlags;
}

contract CryptoCardsFactory is OwnerOrAuthorized {
    CryptoCardsMessages messages;
    CryptoCardsStorage store;
    uint256 private psuedoRandomSeed;

    uint256[] private CARD_BACKGROUND_COLORS = [
        0xff99b433,
        0xff00a300,
        0xff1e7145,
        0xffff0097,
        0xff9f00a7,
        0xff7e3878,
        0xff603cba,
        0xff1d1d1d,
        0xff00aba9,
        0xff2d89ef,
        0xff2b5797,
        0xffffc40d,
        0xffe3a21a,
        0xffda532c,
        0xffee1111,
        0xffb91d47
    ];

    constructor(address _messages, address _storage) OwnerOrAuthorized() {
        messages = CryptoCardsMessages(_messages);
        store = CryptoCardsStorage(_storage);
    }

    // Internal
    function _encodeCardAttributes(
        uint256 _value,
        uint256 _suit,
        uint256 _background,
        uint256 _foreground,
        uint256 _color,
        uint256 _symbol,
        uint256 _modifierFlags
    ) internal pure returns (uint256) {
        return
            _value |
            (_suit << BITOFFSET_SUIT) |
            (_background << BITOFFSET_BACKGROUND) |
            (_foreground << BITOFFSET_FOREGROUND) |
            (_color << BITOFFSET_COLOR) |
            (_symbol << BITOFFSET_SYMBOL) |
            (_modifierFlags << BITOFFSET_FLAGS);
    }

    function _createRandomCard(uint256 _symbol) internal returns (uint256) {
        uint256 nextCardIndex = store.getDeckCardCount(_symbol);
        bytes memory shuffledCards = store.getShuffledDeck(_symbol);

        require(shuffledCards.length > 0, messages.missingShuffledDeck());

        // Good enough psuedo-random number; only used for background
        unchecked {
            psuedoRandomSeed = psuedoRandomSeed == 0
                ? uint256(blockhash(block.number - 1)) + 1
                : psuedoRandomSeed + uint256(blockhash(block.number - 1)) + 1;
        }
        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, psuedoRandomSeed)
            )
        );

        uint8 nextCard = uint8(shuffledCards[nextCardIndex % 52]);
        uint256 value = nextCard % 13;
        uint256 suit = nextCard / 13;
        uint256 background = CARD_BACKGROUND_COLORS[randomValue % 16];

        return
            store.addCard(
                createCard(
                    DecodedCard(
                        value,
                        suit,
                        background,
                        DEFAULT_FOREGROUND,
                        DEFAULT_COLOR,
                        _symbol,
                        0
                    ),
                    0
                )
            );
    }

    function _modifyCard(uint256 _baseCardId, uint256 _modifierCardId)
        internal
    {
        Card memory baseCard = store.getCard(_baseCardId);
        Card memory modifierCard = store.getCard(_modifierCardId);

        uint256 value = baseCard.attributes & 0xFF;
        uint256 suit = (baseCard.attributes >> BITOFFSET_SUIT) & 0xFF;
        uint256 background = (baseCard.attributes >> BITOFFSET_BACKGROUND) &
            0xFFFFFFFF;
        uint256 foreground = (baseCard.attributes >> BITOFFSET_FOREGROUND) &
            0xFFFFFFFF;
        uint256 color = (baseCard.attributes >> BITOFFSET_COLOR) & 0xFFFFFFFF;
        uint256 symbol = (baseCard.attributes >> BITOFFSET_SYMBOL) & 0xFFFFFFFF;
        uint256 modifierFlags = modifierCard.attributes >> BITOFFSET_FLAGS;

        // background
        if (modifierFlags & FLAGS_SET_BACKGROUND == FLAGS_SET_BACKGROUND) {
            background =
                (modifierCard.attributes >> BITOFFSET_BACKGROUND) &
                0xFFFFFFFF;
        }

        // foreground
        if (modifierFlags & FLAGS_SET_FOREGROUND == FLAGS_SET_FOREGROUND) {
            foreground =
                (modifierCard.attributes >> BITOFFSET_FOREGROUND) &
                0xFFFFFFFF;
        }

        // color
        if (modifierFlags & FLAGS_SET_COLOR == FLAGS_SET_COLOR) {
            color = (modifierCard.attributes >> BITOFFSET_COLOR) & 0xFFFFFFFF;
        }

        // modifiers
        if (modifierFlags & FLAGS_DATA_APPEND == FLAGS_DATA_APPEND) {
            // append
            require(
                (baseCard.modifiers & (uint256(0xFFFF) << (32 * 8))) == 0,
                messages.modifierDataFull()
            );
            baseCard.modifiers =
                (baseCard.modifiers << 16) |
                (_modifierCardId & 0xFFFF);
        } else {
            // overwrite
            baseCard.modifiers = _modifierCardId;
        }

        baseCard.attributes = _encodeCardAttributes(
            value,
            suit,
            background,
            foreground,
            color,
            symbol,
            modifierFlags
        );
        store.setCard(_baseCardId, baseCard);
        store.incrementModifierCardUsageCount(_modifierCardId);
    }

    // Public
    function createCard(DecodedCard memory _cardValues, uint256 _data)
        public
        onlyAuthorized
        returns (Card memory)
    {
        return
            Card(
                _encodeCardAttributes(
                    _cardValues.value,
                    _cardValues.suit,
                    _cardValues.background,
                    _cardValues.foreground,
                    _cardValues.color,
                    _cardValues.symbol,
                    _cardValues.modifierFlags
                ),
                _data
            );
    }

    function createCards(
        uint256 _count,
        uint256 _symbol,
        uint256 _modifierCardId
    ) external onlyAuthorized returns (uint256[] memory) {
        uint256 supply = store.getTotalCards();
        uint256 deckSupply = store.getDeckCardCount(_symbol);

        require(_count > 0, messages.mintAmount());
        require(_count <= store.maxMintAmount(), messages.mintAmount());
        require(supply + _count <= store.maxSupply(), messages.exceedsSupply());
        require(
            deckSupply + _count <= store.maxCardsPerDeck(),
            messages.exceedsSupply()
        );

        if (_modifierCardId > 0) {
            require(
                store.getModifierCardUsageCount(_modifierCardId) + _count <
                    store.maxModifierUsage(),
                messages.modifierUsage()
            );
            require(
                store.getModifierCardInUse(_modifierCardId) == true,
                messages.modifierNotFound()
            );
        }

        uint256[] memory result = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            result[i] = _createRandomCard(_symbol);
            if (_modifierCardId > 0) {
                _modifyCard(result[i], _modifierCardId);
            }
        }
        return result;
    }

    // Create an array of 52 values and shuffle
    function createDeck(uint256 _symbol) external onlyAuthorized {
        bytes memory a = store.getPreshuffledDeck();

        unchecked {
            psuedoRandomSeed = psuedoRandomSeed == 0
                ? uint256(blockhash(block.number - 1)) + 1
                : psuedoRandomSeed + uint256(blockhash(block.number - 1)) + 1;
        }

        // Shuffle
        for (uint256 sourceIndex; sourceIndex < 52; sourceIndex++) {
            uint256 destIndex = sourceIndex +
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            msg.sender,
                            psuedoRandomSeed
                        )
                    )
                ) % (52 - sourceIndex));
            bytes1 temp = a[destIndex];
            a[destIndex] = a[sourceIndex];
            a[sourceIndex] = temp;
        }

        store.setShuffledDeck(_symbol, a);
    }

    function createModifiedCard(
        uint256 _originalCardId,
        uint256 _modifierCardId
    ) external onlyAuthorized returns (uint256) {
        uint256 supply = store.getTotalCards();
        require(supply + 1 <= store.maxSupply(), messages.exceedsSupply());

        if (_modifierCardId > 0) {
            require(
                store.getModifierCardUsageCount(_modifierCardId) <
                    store.maxModifierUsage(),
                messages.modifierUsage()
            );
            require(
                store.getModifierCardInUse(_modifierCardId) == true,
                messages.modifierNotFound()
            );
        }

        Card memory originalCard = store.getCard(_originalCardId);
        uint256 clonedCardId = store.addCard(
            Card(originalCard.attributes, originalCard.modifiers)
        );
        _modifyCard(clonedCardId, _modifierCardId);
        return clonedCardId;
    }

    function createModifierCard(
        uint256 _value,
        uint256 _background,
        uint256 _foreground,
        uint256 _color,
        uint256 _flags
    ) external onlyAuthorized returns (uint256) {
        require(
            store.getTotalCards() + 1 <= store.maxSupply(),
            messages.exceedsSupply()
        );

        Card memory card = createCard(
            DecodedCard(
                _value | MODIFIER_CARD,
                0,
                (_flags & FLAGS_SET_BACKGROUND) == FLAGS_SET_BACKGROUND
                    ? _background
                    : DEFAULT_MODIFIER_BACKGROUND,
                (_flags & FLAGS_SET_FOREGROUND) == FLAGS_SET_FOREGROUND
                    ? _foreground
                    : DEFAULT_FOREGROUND,
                (_flags & FLAGS_SET_COLOR) == FLAGS_SET_COLOR
                    ? _color
                    : DEFAULT_COLOR,
                0,
                _flags
            ),
            0
        );

        return store.addCard(card);
    }
}