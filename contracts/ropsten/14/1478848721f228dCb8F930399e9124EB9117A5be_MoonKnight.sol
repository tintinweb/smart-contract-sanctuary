//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMoonKnight.sol";
import "../interfaces/IEquipment.sol";
import "../interfaces/IPet.sol";
import "../utils/AcceptedToken.sol";

contract MoonKnight is IMoonKnight, ERC721, AcceptedToken, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint private constant BPS = 10000;

    IEquipment public equipmentContract;
    IPet public petContract;

    uint public floorPriceInBps = 200;
    uint public marketFeeInBps = 22;
    uint public serviceFeeInToken = 1e20;
    string private _uri;

    Version[] public versions;
    mapping(uint => uint) public knightsOnSale;
    mapping(uint => mapping(address => uint)) public knightsWithOffers;
    mapping(string => bool) public reservedNames;

    Knight[] private _knights;
    mapping(uint => uint) private _knightsWithPet;
    mapping(uint => EnumerableSet.UintSet) private _knightSkills;

    constructor(
        IEquipment equipmentAddress,
        IERC20 tokenAddress,
        string memory baseURI,
        uint maxSupply,
        uint salePrice,
        uint startTime,
        uint revealTime,
        string memory provenance
    ) ERC721("MoonKnight", "KNIGHT") AcceptedToken(tokenAddress) {
        equipmentContract = equipmentAddress;
        _uri = baseURI;
        versions.push(Version(0, 0, maxSupply, salePrice, startTime, revealTime, provenance));
    }

    modifier onlyKnightOwner(uint knightId) {
        require(ownerOf(knightId) == msg.sender, "MoonKnight: not knight owner");
        _;
    }

    function setEquipmentContract(IEquipment equipmentAddress) external onlyOwner {
        require(address(equipmentAddress) != address(0), "MoonKnight: zero address");
        equipmentContract = equipmentAddress;
    }

    function setPetContract(IPet petAddress) external onlyOwner {
        require(address(petAddress) != address(0), "MoonKnight: zero address");
        petContract = petAddress;
    }

    function setFloorPriceAndMarketFeeInBps(uint floorPrice, uint marketFee) external onlyOwner {
        require(floorPrice + marketFee <= BPS, "MoonKnight: invalid total BPS");

        floorPriceInBps = floorPrice;
        marketFeeInBps = marketFee;
    }

    function setServiceFee(uint value) external onlyOwner {
        serviceFeeInToken = value;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function addNewVersion(
        uint maxSupply,
        uint salePrice,
        uint startTime,
        uint revealTime,
        string memory provenance
    ) external onlyOwner {
        uint latestVersionId = getLatestVersion();
        Version memory latestVersion = versions[latestVersionId];

        require(latestVersion.currentSupply == latestVersion.maxSupply, "MoonKnight: current version is not ended");

        versions.push(Version(0, 0, maxSupply, salePrice, startTime, revealTime, provenance));
        emit NewVersionAdded(latestVersionId + 1);
    }

    function claimMoonKnight(uint versionId, uint amount) external override payable {
        Version storage version = versions[versionId];
        uint floorPrice = version.salePrice * 1000 / BPS;

        require(amount > 0 && amount <= 50, "MoonKnight: amount out of range");
        require(block.timestamp >= version.startTime, "MoonKnight: Sale has not started");
        require(version.currentSupply + amount <= version.maxSupply, "MoonKnight: sold out");
        require(msg.value == version.salePrice * amount, "MoonKnight: incorrect value");

        for (uint i = 0; i < amount; i++) {
            uint knightId = _createKnight(floorPrice);
            _safeMint(msg.sender, knightId);
        }

        version.currentSupply += amount;

        (bool isSuccess,) = owner().call{value: msg.value - (floorPrice * amount)}("");
        require(isSuccess, "MoonKnight: transfer failed");

        if (version.startingIndex == 0 && (version.currentSupply == version.maxSupply || block.timestamp >= version.revealTime)) {
            _finalizeStartingIndex(versionId, version);
        }
    }

    function changeKnightName(
        uint knightId,
        string memory newName
    ) external override onlyKnightOwner(knightId) collectTokenAsFee(serviceFeeInToken, owner()) {
        require(_validateStr(newName), "MoonKnight: invalid name");
        require(reservedNames[newName] == false, "MoonKnight: name already exists");

        Knight storage knight = _knights[knightId];

        // If already named, de-reserve current name
        if (bytes(knight.name).length > 0) {
            reservedNames[knight.name] = false;
        }

        knight.name = newName;
        reservedNames[newName] = true;

        emit NameChanged(knightId, newName);
    }

    function equipItems(uint knightId, uint[] memory itemIds) external override onlyKnightOwner(knightId) {
        _setKnightEquipment(knightId, itemIds, false);

        equipmentContract.putItemsIntoStorage(msg.sender, itemIds);

        emit ItemsEquipped(knightId, itemIds);
    }

    function removeItems(uint knightId, uint[] memory itemIds) external override onlyKnightOwner(knightId) {
        _setKnightEquipment(knightId, itemIds, true);

        equipmentContract.returnItems(msg.sender, itemIds);

        emit ItemsUnequipped(knightId, itemIds);
    }

    function addFloorPriceToKnight(uint knightId) external override payable {
        Knight storage knight = _knights[knightId];
        uint newFloorPrice = knight.floorPrice + msg.value;

        require(msg.value > 0, "MoonKnight: no value sent");
        require(newFloorPrice <= 100 ether, "MoonKnight: cannot add more");
        require(acceptedToken.balanceOf(msg.sender) >= serviceFeeInToken, "MoonKnight: insufficient token balance");

        knight.floorPrice = newFloorPrice;
        acceptedToken.safeTransferFrom(msg.sender, owner(), serviceFeeInToken);

        emit KnightPriceIncreased(knightId, newFloorPrice, serviceFeeInToken);
    }

    function sacrificeKnight(uint knightId) external override nonReentrant onlyKnightOwner(knightId) {
        Knight storage knight = _knights[knightId];
        uint amount = knight.floorPrice;

        knight.floorPrice = 0;
        _burn(knightId);

        (bool isSuccess,) = msg.sender.call{value: amount}("");
        require(isSuccess, "MoonKnight: refund failed");
    }

    function list(uint knightId, uint price) external override onlyKnightOwner(knightId) {
        require(price >= _knights[knightId].floorPrice, "MoonKnight: under floor price");

        knightsOnSale[knightId] = price;

        emit KnightListed(knightId, price);
    }

    function delist(uint knightId) external override onlyKnightOwner(knightId) {
        require(knightsOnSale[knightId] > 0, "MoonKnight: not listed");

        knightsOnSale[knightId] = 0;

        emit KnightDelisted(knightId);
    }

    function buy(uint knightId) external override payable nonReentrant {
        uint price = knightsOnSale[knightId];
        address seller = ownerOf(knightId);
        address buyer = msg.sender;

        require(price > 0, "MoonKnight: not on sale");
        require(msg.value == price, "MoonKnight: incorrect value");
        require(buyer != seller, "MoonKnight: cannot buy your own Knight");

        _makeTransaction(knightId, buyer, seller, price);

        emit KnightBought(knightId, buyer, seller, price);
    }

    function offer(uint knightId, uint offerValue) external override nonReentrant payable {
        address buyer = msg.sender;
        uint currentOffer = knightsWithOffers[knightId][buyer];
        bool needRefund = offerValue < currentOffer;
        uint requiredValue = needRefund ? 0 : offerValue - currentOffer;

        require(buyer != ownerOf(knightId), "MoonKnight: owner cannot offer");
        require(offerValue != currentOffer, "MoonKnight: same offer");
        require(msg.value == requiredValue, "MoonKnight: sent value incorrect");

        knightsWithOffers[knightId][buyer] = offerValue;

        if (needRefund) {
            uint returnedValue = currentOffer - offerValue;

            (bool success,) = buyer.call{value: returnedValue}("");
            require(success, "MoonKnight: transfer failed");
        }

        emit KnightOffered(knightId, buyer, offerValue);
    }

    function takeOffer(
        uint knightId,
        address buyer,
        uint minPrice
    ) external override nonReentrant onlyKnightOwner(knightId) {
        uint offeredValue = knightsWithOffers[knightId][buyer];
        address seller = msg.sender;

        require(offeredValue >= _knights[knightId].floorPrice, "MoonKnight: under floor price");
        require(offeredValue >= minPrice, "MoonKnight: less than min price");
        require(buyer != seller, "MoonKnight: cannot buy your own Knight");

        knightsWithOffers[knightId][buyer] = 0;

        _makeTransaction(knightId, buyer, seller, offeredValue);

        emit KnightBought(knightId, buyer, seller, offeredValue);
    }

    function cancelOffer(uint knightId) external override nonReentrant {
        address sender = msg.sender;
        uint offerValue = knightsWithOffers[knightId][sender];

        require(offerValue > 0, "MoonKnight: no offer found");

        knightsWithOffers[knightId][sender] = 0;

        (bool success,) = sender.call{value: offerValue}("");
        require(success, "MoonKnight: transfer failed");

        emit KnightOfferCanceled(knightId, sender);
    }

    function learnSkill(uint knightId, uint skillId) external override onlyKnightOwner(knightId) {
        IEquipment.ItemType itemType = equipmentContract.getItemType(skillId);
        EnumerableSet.UintSet storage skills = _knightSkills[knightId];

        require(itemType == IEquipment.ItemType.SKILL_BOOK, "MoonKnight: invalid skill book");

        bool isSuccess = skills.add(skillId);
        if (!isSuccess) revert("MoonKnight: already learned");

        uint[] memory skillIds = new uint[](1);
        skillIds[0] = skillId;
        equipmentContract.putItemsIntoStorage(msg.sender, skillIds);

        emit SkillLearned(knightId, skillId);
    }

    function adoptPet(uint knightId, uint petId) external override onlyKnightOwner(knightId) {
        require(address(petContract) != address(0), "MoonKnight: invalid pet contract");
        require(petContract.ownerOf(petId) == msg.sender, "MoonKnight: not pet owner");

        _knightsWithPet[knightId] = petId;
        petContract.bindPet(petId);

        emit PetAdopted(knightId, petId);
    }

    function abandonPet(uint knightId) external override onlyKnightOwner(knightId) {
        uint petId = _knightsWithPet[knightId];

        require(petId != 0, "MoonKnight: no pet");

        _knightsWithPet[knightId] = 0;
        petContract.releasePet(petId);

        emit PetReleased(knightId, petId);
    }

    function levelUp(uint knightId, uint amount) external override onlyOperator {
        require(amount > 0, "MoonKnight: invalid amount");

        Knight storage knight = _knights[knightId];
        uint newLevel = knight.level + amount;

        knight.level = newLevel;

        emit KnightLeveledUp(knightId, newLevel, amount);
    }

    function finalizeDuelResult(
        uint winningKnightId,
        uint losingKnightId,
        uint penaltyInBps
    ) external override onlyOperator {
        require(penaltyInBps <= BPS, "MoonKnight: invalid penalty BPS");

        Knight storage winningKnight = _knights[winningKnightId];
        Knight storage losingKnight = _knights[losingKnightId];
        uint baseFloorPrice = winningKnight.floorPrice > losingKnight.floorPrice ? losingKnight.floorPrice : winningKnight.floorPrice;

        uint penaltyAmount = baseFloorPrice * penaltyInBps / BPS;

        winningKnight.floorPrice += penaltyAmount;
        losingKnight.floorPrice -= penaltyAmount;

        emit DuelConcluded(winningKnightId, losingKnightId, penaltyAmount);
    }

    function getKnight(uint knightId) external view override returns (
        string memory name,
        uint level,
        uint floorPrice,
        uint pet,
        uint[] memory skills,
        uint[9] memory equipment
    ) {
        Knight memory knight = _knights[knightId];

        uint skillCount = _knightSkills[knightId].length();
        uint[] memory skillIds = new uint[](skillCount);
        for (uint i = 0; i < skillCount; i++) {
            skillIds[i] = _knightSkills[knightId].at(i);
        }

        name = knight.name;
        level = knight.level;
        floorPrice = knight.floorPrice;
        pet = _knightsWithPet[knightId];
        skills = skillIds;
        equipment = [
            knight.mainWeapon,
            knight.subWeapon,
            knight.headgear,
            knight.armor,
            knight.footwear,
            knight.pants,
            knight.gloves,
            knight.mount,
            knight.troop
        ];
    }

    function getKnightLevel(uint knightId) external view override returns (uint) {
        return _knights[knightId].level;
    }

    function getLatestVersion() public view returns (uint) {
        return versions.length - 1;
    }

    function totalSupply() external view returns (uint) {
        return _knights.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _makeTransaction(uint knightId, address buyer, address seller, uint price) private {
        Knight storage knight = _knights[knightId];
        uint floorPrice = price * floorPriceInBps / BPS;
        uint marketFee = price * marketFeeInBps / BPS;
        uint newPrice = knight.floorPrice + floorPrice;

        knightsOnSale[knightId] = 0;
        knight.floorPrice = newPrice;

        (bool transferToSeller,) = seller.call{value: price - (floorPrice + marketFee)}("");
        require(transferToSeller, "MoonKnight: transfer to seller failed");

        (bool isSuccess,) = owner().call{value: marketFee}("");
        require(isSuccess, "MoonKnight: transfer to treasury failed");

        _transfer(seller, buyer, knightId);

        emit KnightPriceIncreased(knightId, newPrice, floorPrice);
    }

    function _createKnight(uint floorPrice) private returns (uint knightId) {
        _knights.push(Knight("", 1, floorPrice, 0, 0, 0, 0, 0, 0, 0, 0, 0));
        knightId = _knights.length - 1;
        emit KnightCreated(knightId, floorPrice);
    }

    function _setKnightEquipment(uint knightId, uint[] memory itemIds, bool isRemove) private {
        require(knightsOnSale[knightId] == 0, "MoonKnight: cannot change items while on sale");
        require(itemIds.length > 0, "MoonKnight: no item");

        Knight storage knight = _knights[knightId];
        bool[] memory itemSet = new bool[](9);

        for (uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            uint updatedItemId = isRemove ? 0 : itemId;
            IEquipment.ItemType itemType = equipmentContract.getItemType(itemId);

            require(itemId != 0, "MoonKnight: invalid id");
            require(itemType != IEquipment.ItemType.SKILL_BOOK, "MoonKnight: cannot equip skill book");
            require(!itemSet[uint(itemType)], "MoonKnight: duplicate item type");

            if (itemType == IEquipment.ItemType.MAIN_WEAPON) {
                require(isRemove ? knight.mainWeapon == itemId : knight.mainWeapon == 0, "MoonKnight : invalid mainWeapon");
                knight.mainWeapon = updatedItemId;
                itemSet[uint(IEquipment.ItemType.MAIN_WEAPON)] = true;
            } else if (itemType == IEquipment.ItemType.SUB_WEAPON) {
                require(isRemove ? knight.subWeapon == itemId : knight.subWeapon == 0, "MoonKnight : invalid subWeapon");
                knight.subWeapon = updatedItemId;
                itemSet[uint(IEquipment.ItemType.SUB_WEAPON)] = true;
            } else if (itemType == IEquipment.ItemType.HEADGEAR) {
                require(isRemove ? knight.headgear == itemId : knight.headgear == 0, "MoonKnight : invalid headgear");
                knight.headgear = updatedItemId;
                itemSet[uint(IEquipment.ItemType.HEADGEAR)] = true;
            } else if (itemType == IEquipment.ItemType.ARMOR) {
                require(isRemove ? knight.armor == itemId : knight.armor == 0, "MoonKnight : invalid armor");
                knight.armor = updatedItemId;
                itemSet[uint(IEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IEquipment.ItemType.FOOTWEAR) {
                require(isRemove ? knight.footwear == itemId : knight.footwear == 0, "MoonKnight : invalid footwear");
                knight.footwear = updatedItemId;
                itemSet[uint(IEquipment.ItemType.FOOTWEAR)] = true;
            } else if (itemType == IEquipment.ItemType.PANTS) {
                require(isRemove ? knight.pants == itemId : knight.pants == 0, "MoonKnight : invalid pants");
                knight.pants = updatedItemId;
                itemSet[uint(IEquipment.ItemType.PANTS)] = true;
            } else if (itemType == IEquipment.ItemType.GLOVES) {
                require(isRemove ? knight.gloves == itemId : knight.gloves == 0, "MoonKnight : invalid gloves");
                knight.gloves = updatedItemId;
                itemSet[uint(IEquipment.ItemType.GLOVES)] = true;
            } else if (itemType == IEquipment.ItemType.MOUNT) {
                require(isRemove ? knight.mount == itemId : knight.mount == 0, "MoonKnight : invalid mount");
                knight.mount = updatedItemId;
                itemSet[uint(IEquipment.ItemType.MOUNT)] = true;
            } else if (itemType == IEquipment.ItemType.TROOP) {
                require(isRemove ? knight.troop == itemId : knight.troop == 0, "MoonKnight : invalid troop");
                knight.troop = updatedItemId;
                itemSet[uint(IEquipment.ItemType.TROOP)] = true;
            }
        }
    }

    function _finalizeStartingIndex(uint versionId, Version storage version) private {
        uint startingIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % version.maxSupply;
        if (startingIndex == 0) startingIndex = startingIndex + 1;
        version.startingIndex = startingIndex;

        emit StartingIndexFinalized(versionId, startingIndex);
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function _validateStr(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 20) return false;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

    constructor () {
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMoonKnight {
    struct Knight {
        string name;
        uint level;
        uint floorPrice;
        uint mainWeapon;
        uint subWeapon;
        uint headgear;
        uint armor;
        uint footwear;
        uint pants;
        uint gloves;
        uint mount;
        uint troop;
    }

    struct Version {
        uint startingIndex;
        uint currentSupply;
        uint maxSupply;
        uint salePrice;
        uint startTime;
        uint revealTime;
        string provenance; // This is the provenance record of all MoonKnight artworks in existence.
    }

    event KnightCreated(uint indexed knightId, uint floorPrice);
    event KnightListed(uint indexed knightId, uint price);
    event KnightDelisted(uint indexed knightId);
    event KnightBought(uint indexed knightId, address buyer, address seller, uint price);
    event KnightOffered(uint indexed knightId, address buyer, uint price);
    event KnightOfferCanceled(uint indexed knightId, address buyer);
    event KnightPriceIncreased(uint indexed knightId, uint floorPrice, uint increasedAmount);
    event NameChanged(uint indexed knightId, string newName);
    event PetAdopted(uint indexed knightId, uint indexed petId);
    event PetReleased(uint indexed knightId, uint indexed petId);
    event SkillLearned(uint indexed knightId, uint indexed skillId);
    event ItemsEquipped(uint indexed knightId, uint[] itemIds);
    event ItemsUnequipped(uint indexed knightId, uint[] itemIds);
    event KnightLeveledUp(uint indexed knightId, uint level, uint amount);
    event DuelConcluded(uint indexed winningKnightId, uint indexed losingKnightId, uint penaltyAmount);
    event StartingIndexFinalized(uint versionId, uint startingIndex);
    event NewVersionAdded(uint versionId);

    /**
     * @notice Claims moon knights when it's on presale phase.
     */
    function claimMoonKnight(uint versionId, uint amount) external payable;

    /**
     * @notice Changes a knight's name.
     *
     * Requirements:
     * - `newName` must be a valid string.
     * - `newName` is not duplicated to other.
     * - Token required: `serviceFeeInToken`.
     */
    function changeKnightName(uint knightId, string memory newName) external;

    /**
     * @notice Anyone can call this function to manually add `floorPrice` to a knight.
     *
     * Requirements:
     * - `msg.value` must not be zero.
     * - knight's `floorPrice` must be under `floorPriceCap`.
     * - Token required: `serviceFeeInToken` * value
     */
    function addFloorPriceToKnight(uint knightId) external payable;

    /**
     * @notice Owner equips items to their knight by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the knight.
     */
    function equipItems(uint knightId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their knight. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - caller must be owner of the knight.
     */
    function removeItems(uint knightId, uint[] memory itemIds) external;

    /**
     * @notice Burns a knight to claim its `floorPrice`.
     *
     * - Not financial advice: DONT DO THAT.
     * - Remember to remove all items before calling this function.
     */
    function sacrificeKnight(uint knightId) external;

    /**
     * @notice Lists a knight on sale.
     *
     * Requirements:
     * - `price` cannot be under knight's `floorPrice`.
     * - Caller must be the owner of the knight.
     */
    function list(uint knightId, uint price) external;

    /**
     * @notice Delist a knight on sale.
     */
    function delist(uint knightId) external;

    /**
     * @notice Instant buy a specific knight on sale.
     *
     * Requirements:
     * - Target knight must be currently on sale.
     * - Sent value must be exact the same as current listing price.
     */
    function buy(uint knightId) external payable;

    /**
     * @notice Gives offer for a knight.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint knightId, uint offerValue) external payable;

    /**
     * @notice Owner take an offer to sell their knight.
     *
     * Requirements:
     * - Cannot take offer under knight's `floorPrice`.
     * - Offer value must be at least equal to `minPrice`.
     */
    function takeOffer(uint knightId, address offerAddr, uint minPrice) external;

    /**
     * @notice Cancels an offer for a specific knight.
     */
    function cancelOffer(uint knightId) external;

    /**
     * @notice Learns a skill for given Knight.
     */
    function learnSkill(uint knightId, uint skillId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint knightId, uint petId) external;

    /**
     * @notice Abandons a Pet attached to a Knight.
     */
    function abandonPet(uint knightId) external;

    /**
     * @notice Operators can level up a Knight
     */
    function levelUp(uint knightId, uint amount) external;

    /**
     * @notice Finalizes the battle aftermath of 2 knights.
     */
    function finalizeDuelResult(uint winningKnightId, uint losingKnightId, uint penaltyInBps) external;

    /**
     * @notice Gets knight information.
     */
    function getKnight(uint knightId) external view returns (
        string memory name,
        uint level,
        uint floorPrice,
        uint pet,
        uint[] memory skills,
        uint[9] memory equipment
    );

    /**
     * @notice Gets current level of given knight.
     */
    function getKnightLevel(uint knightId) external view returns (uint);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEquipment {
    enum ItemType { MAIN_WEAPON, SUB_WEAPON, HEADGEAR, ARMOR, FOOTWEAR, PANTS, GLOVES, MOUNT, TROOP, SKILL_BOOK }
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }

    struct Item {
        string name;
        uint16 maxSupply;
        uint16 minted;
        uint16 burnt;
        uint8 tier;
        uint8 upgradeAmount;
        ItemType itemType;
        Rarity rarity;
    }

    event ItemCreated(uint indexed itemId, string name, uint16 maxSupply, ItemType itemType, Rarity rarity);
    event ItemUpgradable(uint indexed itemId, uint indexed nextTierItemId, uint8 upgradeAmount);

    /**
     * @notice Create an item.
     */
    function createItem(string memory name, uint16 maxSupply, ItemType itemType, Rarity rarity) external;

    /**
     * @notice Add next tier item to existing one.
     */
    function addNextTierItem(uint itemId, uint8 upgradeAmount) external;

    /**
     * @notice Burns the same items to upgrade its tier.
     *
     * Requirements:
     * - sufficient token balance.
     * - Item must have its next tier.
     * - Sender's balance must have at least `upgradeAmount`
     */
    function upgradeItem(uint itemId) external;

    /**
     * @notice Pays some fee to get random items.
     */
    function rollEquipmentGacha(uint vendorId, uint amount) external;

    /**
     * @notice Mints items and returns true if it's run out of stock.
     */
    function mint(address account, uint itemId, uint16 amount) external returns (bool);

    /**
     * @notice Burns ERC1155 equipment since it is equipped to the knight.
     */
    function putItemsIntoStorage(address account, uint[] memory itemIds) external;

    /**
     * @notice Returns ERC1155 equipment back to the owner.
     */
    function returnItems(address account, uint[] memory itemIds) external;

    /**
     * @notice Gets item information.
     */
    function getItem(uint itemId) external view returns (Item memory item);

    /**
     * @notice Gets item type.
     */
    function getItemType(uint itemId) external view returns (ItemType);

    /**
     * @notice Check if item is out of stock.
     */
    function isOutOfStock(uint itemId, uint16 amount) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPet {
    /**
     * @notice Temporarily burn a pet.
     */
    function bindPet(uint petId) external;

    /**
     * @notice Release given pet back into user inventory.
     */
    function releasePet(uint petId) external;

    /**
     * @notice Gets owner of given pet.
     */
    function ownerOf(uint petId) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./PermissionGroup.sol";

contract AcceptedToken is PermissionGroup {
    using SafeERC20 for IERC20;

    // Token to be used in the ecosystem.
    IERC20 public acceptedToken;

    constructor(IERC20 tokenAddress) {
        acceptedToken = tokenAddress;
    }

    modifier collectTokenAsFee(uint amount, address destAddr) {
        require(acceptedToken.balanceOf(msg.sender) >= amount, "AcceptedToken: insufficient token balance");
        _;
        acceptedToken.safeTransferFrom(msg.sender, destAddr, amount);
    }

    /**
     * @dev Sets accepted token using in the ecosystem.
     */
    function setAcceptedTokenContract(IERC20 tokenAddr) external onlyOwner {
        require(address(tokenAddr) != address(0), "AcceptedToken: zero address");
        acceptedToken = tokenAddr;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    /**
    * @notice Removes an address as operator.
    */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }
}

