//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICryptoHero.sol";
import "../interfaces/IEquipment.sol";

contract CryptoHero is ICryptoHero, ERC721, Ownable {
    // The total supply of heroes.
    uint public constant TOTAL_HERO = 10000;

    // The maximum heroes representing a single token symbol.
    uint public constant MAX_HERO_PER_SYMBOL = 5;

    // 1 Basis Point = 0.01%.
    uint public constant BPS = 10000;

    // Timestamp when the sale will begin.
    uint public constant SALE_START_TIMESTAMP = 1611846000;

    // Time after which heroes are randomized and allotted
    uint public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 14);

    uint256 public constant MAX_NFT_SUPPLY = 10000;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    // Contract for interacting with ERC1155 items.
    IEquipment public equipmentContract;

    // Base URI for fetching metadata.
    string public baseURI;

    // BPS adds to hero's floor price.
    uint public floorPriceInBps = 200;

    // BPS adds to development fund.
    uint public marketFeeInBps = 22;

    // Mapping from hero to currently on sale price.
    mapping(uint => uint) public heroesOnSale;

    // Mapping from hero to all addresses with offer.
    mapping(uint => mapping(address => uint)) public heroesWithOffers;

    // Mapping from hero's name to its availability.
    mapping(string => bool) public reservedNames;

    // Mapping from token symbol to a list of heroes.
    mapping(string => uint[]) public symbolToHeroes;

    // Mapping from hero to its information
    Hero[] private _heroes;

    // The initial price at the start of the sale.
    uint private _initialSalePrice;

    constructor(
        IEquipment equipmentAddress_,
        string memory baseURI_,
        uint initialSalePrice_
    ) ERC721("CryptoHero", "HERO") {
        equipmentContract = IEquipment(equipmentAddress_);
        baseURI = baseURI_;
        _initialSalePrice = initialSalePrice_;
    }

    modifier onlyOwnerOf(uint heroId) {
        require(ownerOf(heroId) == _msgSender());
        _;
    }

    function setEquipmentContract(IEquipment equipmentContract_) external onlyOwner {
        equipmentContract = equipmentContract_;
    }

    function setFloorPricePercentage(uint value) external onlyOwner {
        floorPriceInBps = value;
    }

    function setMarketFeePercentage(uint value) external onlyOwner {
        marketFeeInBps = value;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() external {
        require(startingIndex == 0, "CryptoHero: Starting index is already set");
        require(startingIndexBlock != 0, "CryptoHero: Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % TOTAL_HERO;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % TOTAL_HERO;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function getCurrentSalePrice() public view returns (uint) {
        uint currentSupply = _heroes.length;

        require(block.timestamp >= SALE_START_TIMESTAMP, "CryptoHero: sale has not started");
        require(currentSupply < TOTAL_HERO, "CryptoHero: sale has already ended");

        if (currentSupply >= 9000) {
            return _initialSalePrice * 39 / 10;
        }  else if (currentSupply >= 8000) {
            return _initialSalePrice * 37 / 10;
        }  else if (currentSupply >= 7000) {
            return _initialSalePrice * 34 / 10;
        } else if (currentSupply >= 6000) {
            return _initialSalePrice * 3;
        } else if (currentSupply >= 5000) {
            return _initialSalePrice * 28 / 10;
        } else if (currentSupply >= 4000) {
            return _initialSalePrice * 25 / 10;
        } else if (currentSupply >= 3000) {
            return _initialSalePrice * 2;
        } else if (currentSupply >= 2000) {
            return _initialSalePrice * 15 / 10;
        } else {
            return _initialSalePrice;
        }
    }

    /**
     * @dev See {ICryptoHero-getHero}.
     */
    function getHero(uint heroId) external view override returns (
        string memory name,
        string memory symbol,
        bool isAlive,
        uint8 level,
        uint floorPrice,
        uint[8] memory equipment
    ) {
        Hero memory hero = _heroes[heroId];

        name = hero.name;
        symbol = hero.symbol;
        level = hero.level;
        isAlive = _exists(heroId);
        floorPrice = hero.floorPrice;
        equipment = [hero.weaponMain, hero.weaponSub, hero.headgear, hero.armor, hero.footwear, hero.pants, hero.glove, hero.pet];
    }

    /**
     * @dev See {ICryptoHero-addFloorPriceToHero}.
     */
    function addFloorPriceToHero(uint heroId) external override payable {
        require(msg.value > 0, "CryptoHero: no value sent");
        require(_heroes[heroId].floorPrice < 100 ether, "CryptoHero: cannot add more");

        _heroes[heroId].floorPrice += msg.value;
    }

    /**
     * @dev See {ICryptoHero-claimHero}.
     */
    function claimHero() external override payable {
        uint currentPrice = getCurrentSalePrice();

        require(_heroes.length < TOTAL_HERO, "CryptoHero: all heroes have been claimed");
        require(msg.value == currentPrice, "CryptoHero: sent value does not match");

        uint floorPrice = currentPrice * floorPriceInBps / BPS;
        uint heroId = _createHero(floorPrice);
        _safeMint(_msgSender(), heroId);

        (bool transferResult,) = payable(owner()).call{value: currentPrice - floorPrice}("");
        require(transferResult, "CryptoHero: transfer to development fund failed");

        if (startingIndexBlock == 0 && (_heroes.length == TOTAL_HERO || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev See {ICryptoHero-changeHeroName}.
     */
    function changeHeroName(uint heroId, string memory newName) external override onlyOwnerOf(heroId) {
        require(_validateStr(newName, false) == true, "CryptoHero: name is invalid");
        require(sha256(bytes(_heroes[heroId].name)) != sha256(bytes(newName)), "CryptoHero: same name detected");
        require(reservedNames[newName] == false, "CryptoHero: name already exists");

        Hero storage hero = _heroes[heroId];

        // If already named, de-reserve current name
        if (bytes(hero.name).length > 0) {
            reservedNames[hero.name] = false;
        }

        hero.name = newName;
        reservedNames[newName] = true;
    }

    /**
     * @dev See {ICryptoHero-attachSymbolToHero}.
     */
    function attachSymbolToHero(uint heroId, string memory symbol) external override onlyOwnerOf(heroId) {
        require(_validateStr(symbol, true) == true, "CryptoHero: symbol is invalid");
        require((bytes(_heroes[heroId].symbol).length == 0), "CryptoHero: symbol already attached");
        require(symbolToHeroes[symbol].length < MAX_HERO_PER_SYMBOL, "CryptoHero: symbol has been taken");

        Hero storage hero = _heroes[heroId];

        hero.symbol = symbol;
        symbolToHeroes[symbol].push(heroId);
    }

    /**
     * @dev See {ICryptoHero-equipItems}.
     */
    function equipItems(uint heroId, uint[] memory itemIds, EquipmentSlot[] memory slots) external override onlyOwnerOf(heroId) {
        require(itemIds.length == slots.length, "CryptoHero: itemIds and slots length mismatch");

        Hero storage hero = _heroes[heroId];

        for (uint8 i = 0; i < itemIds.length; i++) {
            if (slots[i] == EquipmentSlot.WEAPON_MAIN) {
                hero.weaponMain = itemIds[i];
            } else if (slots[i] == EquipmentSlot.WEAPON_SUB) {
                hero.weaponSub = itemIds[i];
            } else if (slots[i] == EquipmentSlot.HEADGEAR) {
                hero.headgear = itemIds[i];
            } else if (slots[i] == EquipmentSlot.ARMOR) {
                hero.armor = itemIds[i];
            } else if (slots[i] == EquipmentSlot.FOOTWEAR) {
                hero.footwear = itemIds[i];
            } else if (slots[i] == EquipmentSlot.PANTS) {
                hero.pants = itemIds[i];
            } else if (slots[i] == EquipmentSlot.GLOVE) {
                hero.glove = itemIds[i];
            } else if (slots[i] == EquipmentSlot.PET) {
                hero.pet = itemIds[i];
            }
        }

        equipmentContract.burnItems(_msgSender(), itemIds);
    }

    /**
     * @dev See {ICryptoHero-removeItems}.
     */
    function removeItems(uint heroId, EquipmentSlot[] memory slots) external override onlyOwnerOf(heroId) {
        uint[] memory itemIds;
        Hero storage hero = _heroes[heroId];

        for (uint8 i = 0; i < slots.length; i++) {
            if (slots[i] == EquipmentSlot.WEAPON_MAIN) {
                if (hero.weaponMain == 0) continue;
                itemIds[i] = hero.weaponMain;
                hero.weaponMain = 0;
            } else if (slots[i] == EquipmentSlot.WEAPON_SUB) {
                if (hero.weaponSub == 0) continue;
                itemIds[i] = hero.weaponSub;
                hero.weaponSub = 0;
            } else if (slots[i] == EquipmentSlot.HEADGEAR) {
                if (hero.headgear == 0) continue;
                itemIds[i] = hero.headgear;
                hero.headgear = 0;
            } else if (slots[i] == EquipmentSlot.ARMOR) {
                if (hero.armor == 0) continue;
                itemIds[i] = hero.armor;
                hero.armor = 0;
            } else if (slots[i] == EquipmentSlot.FOOTWEAR) {
                if (hero.footwear == 0) continue;
                itemIds[i] = hero.footwear;
                hero.footwear = 0;
            } else if (slots[i] == EquipmentSlot.PANTS) {
                if (hero.pants == 0) continue;
                itemIds[i] = hero.pants;
                hero.pants = 0;
            } else if (slots[i] == EquipmentSlot.GLOVE) {
                if (hero.glove == 0) continue;
                itemIds[i] = hero.glove;
                hero.glove = 0;
            } else if (slots[i] == EquipmentSlot.PET) {
                if (hero.pet == 0) continue;
                itemIds[i] = hero.pet;
                hero.pet = 0;
            }
        }

        equipmentContract.mintItems(_msgSender(), itemIds);
    }

    /**
     * @dev See {ICryptoHero-sacrificeHero}.
     */
    function sacrificeHero(uint heroId) external override onlyOwnerOf(heroId) {
        Hero storage hero = _heroes[heroId];
        uint amount = hero.floorPrice;

        hero.floorPrice = 0;
        _burn(heroId);

        (bool success, ) = _msgSender().call{ value: amount }("");
        require(success, "CryptoHero: refund failed");
    }

    /**
     * @dev See {ICryptoHero-list}.
     */
    function list(uint heroId, uint price) external override onlyOwnerOf(heroId) {
        require(price >= _heroes[heroId].floorPrice, "CryptoHero: price cannot be under hero's floor price");

        heroesOnSale[heroId] = price;
    }

    /**
     * @dev See {ICryptoHero-buy}.
     */
    function buy(uint heroId) external override payable {
        uint price = heroesOnSale[heroId];

        require(price > 0, "CryptoHero: given hero is not on sale");
        require(msg.value == price, "CryptoHero: sent value does not match");

        _makeTransaction(heroId, _msgSender(), ownerOf(heroId), price);
    }

    /**
     * @dev See {ICryptoHero-offer}.
     */
    function offer(uint heroId) external override payable {
        require(_msgSender() != ownerOf(heroId), "CryptoHero: owner cannot offer");
        require(msg.value >= _heroes[heroId].floorPrice, "CryptoHero: offer cannot be under hero's floor price");

        heroesWithOffers[heroId][_msgSender()] = msg.value;
    }

    /**
     * @dev See {ICryptoHero-takeOffer}.
     */
    function takeOffer(uint heroId, address offerAddr, uint minPrice) external override onlyOwnerOf(heroId) {
        uint offerValue = heroesWithOffers[heroId][_msgSender()];

        require(offerValue >= _heroes[heroId].floorPrice, "CryptoHero: cannot take offer under hero's floor price");
        require(offerValue >= minPrice, "CryptoHero: offer value must be at least equal to min price");

        heroesWithOffers[heroId][offerAddr] = 0;

        _makeTransaction(heroId, offerAddr, _msgSender(), offerValue);
    }

    /**
     * @dev See {ICryptoHero-cancelOffer}.
     */
    function cancelOffer(uint heroId) external override {
        address sender = _msgSender();
        uint offerValue = heroesWithOffers[heroId][sender];

        require(offerValue > 0, "CryptoHero: no offer found");

        heroesWithOffers[heroId][sender] = 0;

        (bool success,) = payable(sender).call{value: offerValue}("");
        require(success, "CryptoHero: transfer fund failed");
    }

    function _makeTransaction(uint heroId, address buyer, address seller, uint price) private {
        uint floorPrice = price * floorPriceInBps / BPS;
        uint marketFee = price * marketFeeInBps / BPS;

        heroesOnSale[heroId] = 0;
        _heroes[heroId].floorPrice += floorPrice;

        (bool transferToSeller,) = payable(seller).call{value: price - (floorPrice + marketFee)}("");
        require(transferToSeller, "CryptoHero: transfer fund to seller failed");

        (bool transferToTreasury,) = payable(owner()).call{value: marketFee}("");
        require(transferToTreasury, "CryptoHero: transfer fund to treasury failed");

        _transfer(seller, buyer, heroId);
    }

    function _createHero(uint floorPrice) private returns (uint) {
        uint nextId = _heroes.length + 1;

        _heroes[nextId] = Hero("", "", 1, floorPrice, 0, 0, 0, 0, 0, 0, 0, 0);

        return nextId;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function _validateStr(string memory str, bool isSymbol) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 20) return false;
        if (isSymbol && b.length > 5) return false;

        // Leading space
        if (b[0] == 0x20) return false;

        // Trailing space
        if (b[b.length - 1] == 0x20) return false;

        bytes1 lastChar = b[0];

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            // Cannot contain continuous spaces
            if (char == 0x20 && lastChar == 0x20) return false;

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICryptoHero {
    enum EquipmentSlot { WEAPON_MAIN, WEAPON_SUB, HEADGEAR, ARMOR, FOOTWEAR, PANTS, GLOVE, PET }

    struct Hero {
        string name;
        string symbol;
        uint8 level;
        uint floorPrice;
        uint weaponMain;
        uint weaponSub;
        uint headgear;
        uint armor;
        uint footwear;
        uint pants;
        uint glove;
        uint pet;
    }

    /**
     * @notice Gets hero information.
     */
    function getHero(uint heroId) external view returns (
        string memory name,
        string memory symbol,
        bool isAlive,
        uint8 level,
        uint floorPrice,
        uint[8] memory equipment
    );

    /**
     * @notice Claims a hero when it's on presale phase.
     */
    function claimHero() external payable;

    /**
     * @notice Changes a hero's name.
     */
    function changeHeroName(uint heroId, string memory newName) external;

    /**
     * @notice Anyone can call this function to manually add `floorPrice` to a hero.
     *
     * Requirements:
     * - `msg.value` must not be zero.
     * - hero's `floorPrice` must be under 100 ether.
     */
    function addFloorPriceToHero(uint heroId) external payable;

    /**
     * @notice Attaches a token symbol to a hero. Cannot be changed once it's set.
     */
    function attachSymbolToHero(uint heroId, string memory symbol) external;

    /**
     * @notice Owner equips items to their hero by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the hero.
     * - `itemIds` and `slots` array length must be the same.
     */
    function equipItems(uint heroId, uint[] memory itemIds, EquipmentSlot[] memory slots) external;

    /**
     * @notice Owner removes items from their hero. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - caller must be owner of the hero.
     */
    function removeItems(uint heroId, EquipmentSlot[] memory slots) external;

    /**
     * @notice Burns a hero to claim its `floorPrice`. *Not financial advice: DONT DO THAT*
     */
    function sacrificeHero(uint heroId) external;

    /**
     * @notice Lists your hero on sale.
     *
     * Requirements:
     * - `price` cannot be under hero's `floorPrice`.
     * - Caller must be the owner of the hero.
     */
    function list(uint heroId, uint price) external;

    /**
     * @notice Instant buy a specific hero on sale.
     *
     * Requirements:
     * - Target hero must be currently on sale.
     * - Sent value must be exact the same as current listing price.
     */
    function buy(uint heroId) external payable;

    /**
     * @notice Gives offer for a hero.
     *
     * Requirements:
     * - Owner cannot offer.
     * - Offer cannot be under hero's `floorPrice`.
     */
    function offer(uint heroId) external payable;

    /**
     * @notice Owner take an offer to sell their hero.
     *
     * Requirements:
     * - Cannot take offer under hero's `floorPrice`.
     * - Offer value must be at least equal to `minPrice`.
     */
    function takeOffer(uint heroId, address offerAddr, uint minPrice) external;

    /**
     * @notice Cancels an offer for a specific hero.
     */
    function cancelOffer(uint heroId) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEquipment {
    enum EquipmentSlot { WEAPON_MAIN, WEAPON_SUB, HEADGEAR, ARMOR, FOOTWEAR, PANTS, GLOVE, PET }
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }

    struct Item {
        string name;
        uint8 tier;
        uint8 numberToUpgrade;
        uint circulatingSupply;
        uint maxSupply;
        EquipmentSlot slot;
        Rarity rarity;
    }

    /**
     * @notice Gets item information.
     */
    function getItem(uint itemId) external view returns (
        string memory name,
        uint8 tier,
        uint8 numberToUpgrade,
        uint circulatingSupply,
        uint maxSupply,
        EquipmentSlot slot,
        Rarity rarity
    );

    /**
     * @notice Create an item.
     */
    function createItem(string memory name, uint maxSupply, EquipmentSlot slot, Rarity rarity) external;

    /**
     * @notice Add next tier item to existing one.
     */
    function addNextTierItem(uint itemId, uint8 numberToUpgrade) external;

    /**
     * @notice Refunds ERC1155 equipment back to the owner.
     */
    function mintItems(address account, uint256[] memory itemIds) external;

    /**
     * @notice Burns ERC1155 equipment since it is equipped to the hero.
     */
    function burnItems(address account, uint256[] memory itemIds) external;

    /**
     * @notice Burns the same items to upgrade its tier.
     */
    function upgradeItem(uint itemId) external payable;
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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