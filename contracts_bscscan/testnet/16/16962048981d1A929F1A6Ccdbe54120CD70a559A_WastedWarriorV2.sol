//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/IWastedWarrior.sol";
import "./utils/AcceptedToken.sol";
import "./interfaces/IWastedEquipment.sol";
import "./interfaces/IWastedPet.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract WastedWarriorV2 is
    IWastedWarrior,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    AcceptedToken
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMathUpgradeable for uint256;

    modifier onlyWarriorOwner(uint256 warriorId) {
        require(
            ownerOf(warriorId) == msg.sender,
            "WAW: Caller isn't owner of warrior"
        );
        _;
    }

    modifier onlyNotBlacklist(uint256 warriorId) {
        require(blacklist[warriorId] == false, "WaW: not eligible");
        _;
    }

    IWastedEquipment public wastedEquipment;
    IWastedPet public wastedPet;
    Warrior[] private _warriors;

    uint256 private PERCENT;
    uint256 public marketFeeInPercent;
    uint256 public serviceFeeInToken;
    uint256 public plasticPackageFee;
    uint256 public steelPackageFee;
    uint256 public goldPackageFee;
    uint256 public platinumPackageFee;
    uint256 public maxLevel;
    string private _uri;

    mapping(uint256 => bool) public blacklist;
    mapping(address => Collaborator) public collaborators;
    mapping(uint256 => uint256) public warriorsOnSale;
    mapping(uint256 => mapping(address => uint256)) public warriorsOffers;
    mapping(string => bool) public usedNames;
    mapping(uint256 => uint256) public rarityPackagesOfWarrior;

    mapping(uint256 => uint256) private _warriorsWithPet;

    function initialize(
        IWastedEquipment equipmentAddress,
        IERC20Upgradeable tokenAccept,
        string memory baseURI
    ) public initializer {
        __ERC721_init_unchained("WastedWarrior", "WAW");
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        AcceptedToken.initialize(tokenAccept);
        wastedEquipment = equipmentAddress;
        _uri = baseURI;
        PERCENT = 100;
        marketFeeInPercent = 20;
        serviceFeeInToken = 1e20;
        plasticPackageFee = 0.1 * 1e18;
        steelPackageFee = 0.25 * 1e18;
        goldPackageFee = 0.4 * 1e18;
        platinumPackageFee = 1 * 1e18;
        maxLevel = 100;
    }

    function addWarriorToBlacklist(uint256 warriorId) external onlyOwner {
        require(warriorId < _warriors.length, "WAW: warrior invalid");
        blacklist[warriorId] = true;
        warriorsOnSale[warriorId] = 0;
        emit AddWarriorToBlacklist(warriorId);
    }

    function removeWarriorFromBlacklist(uint256 warriorId) external onlyOwner {
        require(warriorId < _warriors.length, "WAW: warrior invalid");
        blacklist[warriorId] = false;
        emit RemoveWarriorFromBlacklist(warriorId);
    }

    function setWastedEquipment(IWastedEquipment wastedEquipmentAddress)
        external
        onlyOwner
    {
        require(address(wastedEquipmentAddress) != address(0));
        wastedEquipment = wastedEquipmentAddress;
    }

    function setWastedPet(IWastedPet wastedPetAddress) external onlyOwner {
        require(address(wastedPetAddress) != address(0));
        wastedPet = wastedPetAddress;
    }

    /**
     * @notice function to set market fee.
     *
     * Requirements:
     * - onlyOwner.
     */
    function setMarketFeeInPercent(uint256 marketFee) external onlyOwner {
        require(marketFee < PERCENT, "WAW: invalid");
        marketFeeInPercent = marketFee;
    }

    /**
     * @notice function to set service fee.
     *
     * Requirements:
     * - onlyOwner.
     */
    function setServiceFee(uint256 value) external onlyOwner {
        serviceFeeInToken = value;
    }

    /**
     * @notice function to set normal package fee.
     *
     * Requirements:
     * - onlyOwner.
     */
    function setPlasticPackageFee(uint256 newPlasticPackageFee)
        external
        onlyOwner
    {
        plasticPackageFee = newPlasticPackageFee;
    }

    /**
     * @notice get plastic package fee.
     */
    function getPlasticPackageFee() external view override returns (uint256) {
        return plasticPackageFee;
    }

    /**
     * @notice function to set rare package fee.
     *
     * Requirements:
     * - onlyOwner.
     */
    function setSteelPackageFee(uint256 newSteelPackageFee) external onlyOwner {
        steelPackageFee = newSteelPackageFee;
    }

    /**
     * @notice get steel package fee.
     */
    function getSteelPackageFee() external view override returns (uint256) {
        return steelPackageFee;
    }

    /**
     * @notice function to set epic package fee.
     *
     * Requirements:
     * - onlyOwner.
     */
    function setGoldPackageFee(uint256 newGoldPackageFee) external onlyOwner {
        goldPackageFee = newGoldPackageFee;
    }

    /**
     * @notice get gold package fee.
     */
    function getGoldPackageFee() external view override returns (uint256) {
        return goldPackageFee;
    }

    /**
     * @notice function to set platinum package fee.
     *
     * Requirements:
     * - onlyOwner.
     */
    function setPlatinumPackageFee(uint256 newPlatinumPackageFee)
        external
        onlyOwner
    {
        platinumPackageFee = newPlatinumPackageFee;
    }

    /**
     * @notice get platinum package fee.
     */
    function getPlatinumPackageFee() external view override returns (uint256) {
        return platinumPackageFee;
    }

    function getInfoCollaborator(address addressCollab)
        external
        view
        override
        returns (Collaborator memory)
    {
        return collaborators[addressCollab];
    }

    function setMaxLevel(uint256 newMaxLevel) external onlyOwner {
        maxLevel = newMaxLevel;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function getWarrior(uint256 warriorId)
        external
        view
        override
        returns (
            string memory name,
            bool isBreed,
            bool isFusion,
            uint256 level,
            uint256 pet,
            uint256[3] memory equipment
        )
    {
        Warrior memory warrior = _warriors[warriorId];

        name = warrior.name;
        level = warrior.level;
        isBreed = warrior.isBreed;
        isFusion = warrior.isFusion;
        pet = _warriorsWithPet[warriorId];
        equipment = [warrior.weapon, warrior.armor, warrior.accessory];
    }

    function getWarriorLevel(uint256 warriorId)
        external
        view
        override
        returns (uint256)
    {
        return _warriors[warriorId].level;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function listing(uint256 warriorId, uint256 price)
        external
        override
        onlyNotBlacklist(warriorId)
        onlyWarriorOwner(warriorId)
    {
        Warrior memory warrior = _warriors[warriorId];
        require(price > 0, "WAW: invalid price");
        require(
            warrior.weapon == 0 && warrior.armor == 0 && warrior.accessory == 0,
            "WAW: remove first"
        );
        require(_warriorsWithPet[warriorId] == 0, "WAW: abandonPet first");

        warriorsOnSale[warriorId] = price;

        emit WarriorListed(warriorId, price);
    }

    function _makeTransaction(
        uint256 warriorId,
        address buyer,
        address seller,
        uint256 price
    ) private {
        uint256 marketFee = (price * marketFeeInPercent) / PERCENT;

        warriorsOnSale[warriorId] = 0;

        (bool isTransferToSeller, ) = seller.call{value: price - marketFee}("");
        require(isTransferToSeller);

        (bool isTransferToTreasury, ) = owner().call{value: marketFee}("");
        require(isTransferToTreasury);

        _transfer(seller, buyer, warriorId);
    }

    function _createWarrior(
        bool isBreed,
        bool isFusion,
        uint256 packageType,
        address buyer
    ) private returns (uint256 warriorId) {
        _warriors.push(Warrior("", 1, 0, 0, 0, isBreed, isFusion));
        warriorId = _warriors.length - 1;

        emit WarriorCreated(warriorId, isBreed, isFusion, packageType, buyer);
    }

    function _removeWastedEquipment(uint256 warriorId, uint256[] memory itemIds)
        private
    {
        require(
            warriorsOnSale[warriorId] == 0,
            "WAW: cannot change items while on sale"
        );
        require(itemIds.length > 0, "WAW: no item supply");

        Warrior storage warrior = _warriors[warriorId];
        bool[] memory itemSet = new bool[](3);

        for (uint256 i = 0; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];
            IWastedEquipment.ItemType itemType = wastedEquipment
                .getWastedItemType(itemId);
            require(itemId != 0, "WAW: invalid itemId");
            require(!itemSet[uint256(itemType)], "WAW: duplicate itemType");

            if (itemType == IWastedEquipment.ItemType.WEAPON) {
                require(warrior.weapon == itemId, "WAW: invalid weapon");
                warrior.weapon = 0;
                itemSet[uint256(IWastedEquipment.ItemType.WEAPON)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ARMOR) {
                require(warrior.armor == itemId, "WAW: invalid armor");
                warrior.armor = 0;
                itemSet[uint256(IWastedEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ACCESSORY) {
                require(warrior.accessory == itemId, "WAW: invalid accessory");
                warrior.accessory = 0;
                itemSet[uint256(IWastedEquipment.ItemType.ACCESSORY)] = true;
            } else {
                require(false, "WAW: invalid item type");
            }
        }
    }

    function _setWastedEquipment(uint256 warriorId, uint256[] memory itemIds)
        private
    {
        require(warriorsOnSale[warriorId] == 0, "WAW: cannot change");
        require(itemIds.length > 0, "WAW: no item supply");

        Warrior storage warrior = _warriors[warriorId];
        bool[] memory itemSet = new bool[](3);

        for (uint256 i = 0; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];

            IWastedEquipment.ItemType itemType = wastedEquipment
                .getWastedItemType(itemId);

            require(itemId != 0, "WAW: invalid itemId");
            require(!itemSet[uint256(itemType)], "WAW: duplicated");
            require(
                wastedEquipment.ownerOf(itemId) == msg.sender,
                "WAW: only owner"
            );

            if (itemType == IWastedEquipment.ItemType.WEAPON) {
                require(warrior.weapon == 0, "WAW:invalid");
                warrior.weapon = itemId;
                itemSet[uint256(IWastedEquipment.ItemType.WEAPON)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ARMOR) {
                require(warrior.armor == 0, "WAW: invalid");
                warrior.armor = itemId;
                itemSet[uint256(IWastedEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ACCESSORY) {
                require(warrior.accessory == 0, "WAW: invalid");
                warrior.accessory = itemId;
                itemSet[uint256(IWastedEquipment.ItemType.ACCESSORY)] = true;
            } else {
                require(false, "WAW: invalid");
            }
        }
    }

    function updateCollaborator(
        address collaborator,
        uint256 totalSupplyPlasticPackages,
        uint256 totalSupplySteelPackages,
        uint256 totalSupplyGoldPackages,
        uint256 totalSupplyPlatinumPackages
    ) external onlyOwner {
        require(
            totalSupplyPlasticPackages != 0 &&
                totalSupplySteelPackages != 0 &&
                totalSupplyGoldPackages != 0 &&
                totalSupplyPlatinumPackages != 0,
            "WAW: invalid"
        );

        Collaborator storage collabInfo = collaborators[collaborator];
        collabInfo.totalSupplyPlasticPackages = totalSupplyPlasticPackages;
        collabInfo.totalSupplySteelPackages = totalSupplySteelPackages;
        collabInfo.totalSupplyGoldPackages = totalSupplyGoldPackages;
        collabInfo.totalSupplyPlatinumPackages = totalSupplyPlatinumPackages;
    }

    function addCollaborator(
        address collaborator,
        uint256 totalSupplyPlasticPackages,
        uint256 totalSupplySteelPackages,
        uint256 totalSupplyGoldPackages,
        uint256 totalSupplyPlatinumPackages
    ) external override onlyOwner {
        require(
            totalSupplyPlasticPackages != 0 &&
                totalSupplySteelPackages != 0 &&
                totalSupplyGoldPackages != 0 &&
                totalSupplyPlatinumPackages != 0,
            "WAW: invalid"
        );

        collaborators[collaborator] = Collaborator(
            totalSupplyPlasticPackages,
            totalSupplySteelPackages,
            totalSupplyGoldPackages,
            totalSupplyPlatinumPackages,
            0,
            0,
            0,
            0
        );
    }

    function _validateStr(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 20) return false;

        // Leading space
        if (b[0] == 0x20) return false;

        // Trailing space
        if (b[b.length - 1] == 0x20) return false;

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
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

    function delist(uint256 warriorId)
        external
        override
        onlyWarriorOwner(warriorId)
    {
        require(warriorsOnSale[warriorId] > 0, "WAW: not on sale");
        warriorsOnSale[warriorId] = 0;

        emit WarriorDelisted(warriorId);
    }

    function buy(uint256 warriorId)
        external
        payable
        override
        onlyNotBlacklist(warriorId)
        nonReentrant
    {
        uint256 price = warriorsOnSale[warriorId];
        address seller = ownerOf(warriorId);
        address buyer = msg.sender;

        require(buyer != seller);
        require(price > 0, "WAW: not on sale");
        require(msg.value == price, "WAW: not enough");

        _makeTransaction(warriorId, buyer, seller, price);

        emit WarriorBought(warriorId, buyer, seller, price);
    }

    function offer(uint256 warriorId, uint256 offerPrice)
        external
        payable
        override
        onlyNotBlacklist(warriorId)
        nonReentrant
    {
        address buyer = msg.sender;
        uint256 currentOffer = warriorsOffers[warriorId][buyer];
        bool needRefund = offerPrice < currentOffer;
        uint256 requiredValue = needRefund ? 0 : offerPrice - currentOffer;

        require(buyer != ownerOf(warriorId), "WAW: cannot offer");
        require(offerPrice != currentOffer, "WAW: same offer");
        require(msg.value == requiredValue, "WAW: value invalid");

        warriorsOffers[warriorId][buyer] = offerPrice;

        if (needRefund) {
            uint256 returnedValue = currentOffer - offerPrice;

            (bool success, ) = buyer.call{value: returnedValue}("");
            require(success);
        }

        emit WarriorOffered(warriorId, buyer, offerPrice);
    }

    function acceptOffer(uint256 warriorId, address buyer)
        external
        override
        nonReentrant
        onlyWarriorOwner(warriorId)
    {
        uint256 offeredPrice = warriorsOffers[warriorId][buyer];
        address seller = msg.sender;

        require(buyer != seller, "Wasted: invalid buyer");

        warriorsOffers[warriorId][buyer] = 0;

        _makeTransaction(warriorId, buyer, seller, offeredPrice);

        emit WarriorBought(warriorId, buyer, seller, offeredPrice);
    }

    function abortOffer(uint256 warriorId) external override nonReentrant {
        address caller = msg.sender;
        uint256 offerPrice = warriorsOffers[warriorId][caller];

        require(offerPrice > 0, "WAW: not found");

        warriorsOffers[warriorId][caller] = 0;

        (bool success, ) = caller.call{value: offerPrice}("");
        require(success);

        emit WarriorOfferCanceled(warriorId, caller);
    }

    function levelUp(uint256 warriorId, uint256 amount)
        external
        override
        onlyOperator
    {
        Warrior storage warrior = _warriors[warriorId];
        uint256 newLevel = warrior.level.add(amount);

        require(amount > 0);
        require(newLevel <= maxLevel, "WAW: invalid");

        warrior.level = newLevel;

        emit WarriorLeveledUp(warriorId, newLevel, amount);
    }

    function adoptPet(uint256 warriorId, uint256 petId)
        external
        override
        onlyNotBlacklist(warriorId)
        onlyWarriorOwner(warriorId)
    {
        require(wastedPet.ownerOf(petId) == msg.sender, "WAW: not pet owner");
        require(_warriorsWithPet[warriorId] == 0, "WAW: invalid");

        _warriorsWithPet[warriorId] = petId;
        wastedPet.bindPet(petId);

        emit PetAdopted(warriorId, petId);
    }

    function abandonPet(uint256 warriorId)
        external
        override
        onlyNotBlacklist(warriorId)
        onlyWarriorOwner(warriorId)
    {
        uint256 petId = _warriorsWithPet[warriorId];

        require(petId != 0, "WAW: couldn't found pet");

        _warriorsWithPet[warriorId] = 0;
        wastedPet.releasePet(petId);

        emit PetReleased(warriorId, petId);
    }

    function rename(uint256 warriorId, string memory replaceName)
        external
        override
        onlyNotBlacklist(warriorId)
        onlyWarriorOwner(warriorId)
        collectTokenAsFee(serviceFeeInToken, owner())
    {
        require(_validateStr(replaceName), "WAW: invalid");
        require(usedNames[replaceName] == false, "WAW: name exist");

        Warrior storage warrior = _warriors[warriorId];

        if (bytes(warrior.name).length > 0) {
            usedNames[warrior.name] = false;
        }

        warrior.name = replaceName;
        usedNames[replaceName] = true;

        emit NameChanged(warriorId, replaceName);
    }

    function equipItems(uint256 warriorId, uint256[] memory itemIds)
        external
        override
        onlyNotBlacklist(warriorId)
        onlyWarriorOwner(warriorId)
    {
        _setWastedEquipment(warriorId, itemIds);

        wastedEquipment.putItemsIntoStorage(msg.sender, itemIds);

        emit ItemsEquipped(warriorId, itemIds);
    }

    function removeItems(uint256 warriorId, uint256[] memory itemIds)
        external
        override
        onlyNotBlacklist(warriorId)
        onlyWarriorOwner(warriorId)
    {
        _removeWastedEquipment(warriorId, itemIds);

        wastedEquipment.returnItems(msg.sender, itemIds);

        emit ItemsRemoved(warriorId, itemIds);
    }

    function mintFor(
        address buyer,
        uint256 amount,
        uint256 rarityPackage
    ) external override {
        Collaborator storage collabInfo = collaborators[msg.sender];

        require(rarityPackage >= 1 && rarityPackage <= 4, "WAW: invalid");

        if (rarityPackage == uint256(IWastedWarrior.PackageRarity.PLASTIC)) {
            require(
                collabInfo.mintedPlasticPackages.add(amount) <=
                    collabInfo.totalSupplyPlasticPackages,
                "WAW: sold out"
            );
            collabInfo.mintedPlasticPackages = collabInfo
                .mintedPlasticPackages
                .add(amount);
        } else if (
            rarityPackage == uint256(IWastedWarrior.PackageRarity.STEEL)
        ) {
            require(
                collabInfo.mintedSteelPackages.add(amount) <=
                    collabInfo.totalSupplySteelPackages,
                "WAW: sold out"
            );
            collabInfo.mintedSteelPackages = collabInfo.mintedSteelPackages.add(
                amount
            );
        } else if (
            rarityPackage == uint256(IWastedWarrior.PackageRarity.GOLD)
        ) {
            require(
                collabInfo.mintedGoldPackages.add(amount) <=
                    collabInfo.totalSupplyGoldPackages,
                "WAW: sold out"
            );
            collabInfo.mintedGoldPackages = collabInfo.mintedGoldPackages.add(
                amount
            );
        } else if (
            rarityPackage == uint256(IWastedWarrior.PackageRarity.PLATINUM)
        ) {
            require(
                collabInfo.mintedPlatinumPackages.add(amount) <=
                    collabInfo.totalSupplyPlatinumPackages,
                "WAW: sold out"
            );
            collabInfo.mintedPlatinumPackages = collabInfo
                .mintedPlatinumPackages
                .add(amount);
        }

        for (uint256 i = 0; i < amount; i++) {
            uint256 warriorId = _createWarrior(
                false,
                false,
                rarityPackage,
                buyer
            );
            rarityPackagesOfWarrior[warriorId] = rarityPackage;
            _safeMint(buyer, warriorId);
        }
    }

    function breedingWarrior(
        uint256 fatherId,
        uint256 motherId,
        address owner
    ) external override onlyOperator {
        require(fatherId != motherId);
        require(ownerOf(fatherId) == owner && ownerOf(motherId) == owner);

        uint256 warriorId = _createWarrior(true, false, 0, owner);
        _safeMint(owner, warriorId);

        emit BreedingWarrior(fatherId, motherId, warriorId, owner);
    }

    function fusionWarrior(
        uint256 firstWarriorId,
        uint256 secondWarriorId,
        address owner
    ) external override onlyOperator {
        require(firstWarriorId != secondWarriorId);
        require(
            ownerOf(firstWarriorId) == owner &&
                ownerOf(secondWarriorId) == owner
        );

        uint256 warriorId = _createWarrior(false, true, 0, owner);
        _safeMint(owner, warriorId);

        _burn(firstWarriorId);
        _burn(secondWarriorId);

        emit FusionWarrior(firstWarriorId, secondWarriorId, warriorId, owner);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PermissionGroup is OwnableUpgradeable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     *
     * Requirements:
     * - only Owner of contract.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    /**
     * @notice Removes an address as operator.
     *
     * Requirements:
     * - only Owner of contract.
     */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./PermissionGroup.sol";

contract AcceptedToken is Initializable, PermissionGroup {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Token to be used in the ecosystem.
    IERC20Upgradeable public acceptedToken;

    function initialize(IERC20Upgradeable tokenAddress) public initializer {
        acceptedToken = tokenAddress;
    }

    modifier collectTokenAsFee(uint256 amount, address destAddress) {
        require(
            acceptedToken.balanceOf(msg.sender) >= amount,
            "AcceptedToken: insufficient token balance"
        );
        _;
        acceptedToken.safeTransferFrom(msg.sender, destAddress, amount);
    }

    function collectTokenAsPrice(uint256 amount, address destAddress) public {
        require(
            acceptedToken.balanceOf(msg.sender) >= amount,
            "AcceptedToken: insufficient token balance"
        );
        acceptedToken.safeTransferFrom(msg.sender, destAddress, amount);
    }

    /**
     * @dev Sets accepted token using in the ecosystem.
     */
    function setAcceptedTokenContract(IERC20Upgradeable tokenAddr)
        external
        onlyOwner
    {
        require(address(tokenAddr) != address(0));
        acceptedToken = tokenAddr;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IWastedWarrior {
    enum PackageRarity {
        NONE,
        PLASTIC,
        STEEL,
        GOLD,
        PLATINUM
    }

    event WarriorCreated(
        uint256 indexed warriorId,
        bool isBreed,
        bool isFusion,
        uint256 indexed packageType,
        address indexed buyer
    );
    event WarriorListed(uint256 indexed warriorId, uint256 price);
    event WarriorDelisted(uint256 indexed warriorId);
    event WarriorBought(
        uint256 indexed warriorId,
        address buyer,
        address seller,
        uint256 price
    );
    event WarriorOffered(
        uint256 indexed warriorId,
        address buyer,
        uint256 price
    );
    event WarriorOfferCanceled(uint256 indexed warriorId, address buyer);
    event NameChanged(uint256 indexed warriorId, string newName);
    event PetAdopted(uint256 indexed warriorId, uint256 indexed petId);
    event PetReleased(uint256 indexed warriorId, uint256 indexed petId);
    event ItemsEquipped(uint256 indexed warriorId, uint256[] itemIds);
    event ItemsRemoved(uint256 indexed warriorId, uint256[] itemIds);
    event WarriorLeveledUp(
        uint256 indexed warriorId,
        uint256 level,
        uint256 amount
    );
    event BreedingWarrior(
        uint256 indexed fatherId,
        uint256 indexed motherId,
        uint256 newId,
        address owner
    );
    event FusionWarrior(
        uint256 indexed firstWarriorId,
        uint256 indexed secondWarriorId,
        uint256 newId,
        address owner
    );
    event AddWarriorToBlacklist(uint256 warriorId);
    event RemoveWarriorFromBlacklist(uint256 warriorId);

    struct Collaborator {
        uint256 totalSupplyPlasticPackages;
        uint256 totalSupplySteelPackages;
        uint256 totalSupplyGoldPackages;
        uint256 totalSupplyPlatinumPackages;
        uint256 mintedPlasticPackages;
        uint256 mintedSteelPackages;
        uint256 mintedGoldPackages;
        uint256 mintedPlatinumPackages;
    }

    struct Warrior {
        string name;
        uint256 level;
        uint256 weapon;
        uint256 armor;
        uint256 accessory;
        bool isBreed;
        bool isFusion;
    }

    /**
     * @notice add collaborator info.
     *
     */
    function addCollaborator(
        address collaborator,
        uint256 totalSupplyPlasticPackages,
        uint256 totalSupplySteelPackages,
        uint256 totalSupplyGoldPackages,
        uint256 totalSupplyPlatinumPackages
    ) external;

    /**
     * @notice get collaborator info.
     *
     */
    function getInfoCollaborator(address addressCollab)
        external
        view
        returns (Collaborator memory);

    /**
     * @notice Gets warrior information.
     *
     * @dev Prep function for staking.
     */
    function getWarrior(uint256 warriorId)
        external
        view
        returns (
            string memory name,
            bool isBreed,
            bool isFusion,
            uint256 level,
            uint256 pet,
            uint256[3] memory equipment
        );

    /**
     * @notice get plastic package fee.
     */
    function getPlasticPackageFee() external view returns (uint256);

    /**
     * @notice get steel package fee.
     */
    function getSteelPackageFee() external view returns (uint256);

    /**
     * @notice get gold package fee.
     */
    function getGoldPackageFee() external view returns (uint256);

    /**
     * @notice get platinum package fee.
     */
    function getPlatinumPackageFee() external view returns (uint256);

    /**
     * @notice Function can level up a Warrior.
     *
     * @dev Prep function for staking.
     */
    function levelUp(uint256 warriorId, uint256 amount) external;

    /**
     * @notice Get current level of given warrior.
     *
     * @dev Prep function for staking.
     */
    function getWarriorLevel(uint256 warriorId) external view returns (uint256);

    /**
     * @notice mint warrior for specific address.
     *
     * @dev Function take 3 arguments are address of buyer, amount, rarityPackage.
     *
     * Requirements:
     * - onlyCollaborator
     */
    function mintFor(
        address buyer,
        uint256 amount,
        uint256 rarityPackage
    ) external;

    /**
     * @notice Function to change Warrior's name.
     *
     * @dev Function take 2 arguments are warriorId, new name of warrior.
     *
     * Requirements:
     * - `replaceName` must be a valid string.
     * - `replaceName` is not duplicated.
     * - You have to pay `serviceFeeToken` to change warrior's name.
     */
    function rename(uint256 warriorId, string memory replaceName) external;

    /**
     * @notice Owner equips items to their warrior by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the warrior.
     */
    function equipItems(uint256 warriorId, uint256[] memory itemIds) external;

    /**
     * @notice Owner removes items from their warrior. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - Caller must be owner of the warrior.
     */
    function removeItems(uint256 warriorId, uint256[] memory itemIds) external;

    /**
     * @notice Lists a warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     */
    function listing(uint256 warriorId, uint256 price) external;

    /**
     * @notice Remove from a list on sale.
     */
    function delist(uint256 warriorId) external;

    /**
     * @notice Instant buy a specific warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     * - Target warrior must be currently on sale time.
     * - Sent value must be exact the same as current listing price.
     * - Owner cannot buy.
     */
    function buy(uint256 warriorId) external payable;

    /**
     * @notice Gives offer for a warrior.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint256 warriorId, uint256 offerPrice) external payable;

    /**
     * @notice Owner accept an offer to sell their warrior.
     */
    function acceptOffer(uint256 warriorId, address buyer) external;

    /**
     * @notice Abort an offer for a specific warrior.
     */
    function abortOffer(uint256 warriorId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint256 warriorId, uint256 petId) external;

    /**
     * @notice Abandons a Pet attached to a warrior.
     */
    function abandonPet(uint256 warriorId) external;

    /**
     * @notice Burn two warriors to create one new warrior.
     *
     * @dev Prep function for fusion
     *
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function fusionWarrior(
        uint256 firstWarriorId,
        uint256 secondWarriorId,
        address owner
    ) external;

    /**
     * @notice Breed based on two warriors.
     *
     * @dev Prep function for breed
     *
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function breedingWarrior(
        uint256 fatherId,
        uint256 motherId,
        address owner
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IWastedPet {
    /**
     * @notice Temporarily burn a pet.
     */
    function bindPet(uint256 petId) external;

    /**
     * @notice Release given pet back into user inventory.
     */
    function releasePet(uint256 petId) external;

    /**
     * @notice Gets owner of given pet.
     */
    function ownerOf(uint256 petId) external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IWastedEquipment {
    // Event required.
    enum ItemType {
        WEAPON,
        ARMOR,
        ACCESSORY
    } // 3 types of equipments.
    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }
    event ItemCreated(
        uint256 indexed itemId,
        string name,
        uint16 maxSupply,
        ItemType itemType,
        Rarity rarity
    );
    event ItemUpgradable(
        uint256 indexed itemId,
        uint256 indexed nextTierItemId,
        uint8 upgradeAmount
    );
    event ItemUpdated(uint256 itemId);

    struct WastedItem {
        ItemType itemType;
        Rarity rarity;
        string name;
        uint16 maxSupply;
        uint16 minted;
        uint16 burnt;
        uint8 star;
        uint8 requireAmountToUpgrade;
    }

    /**
     * @notice Roll equipments.
     *
     * Requirements:
     * -  Fee token is required.
     */
    function rollWastedEquipment(uint256 vendorId, uint256 amount) external;

    /**
     * @notice Burns ERC1155 equipment since it is equipped to the knight.
     */
    function putItemsIntoStorage(address account, uint256[] memory itemIds)
        external;

    /**
     * @notice Check if item is out of stock.
     */
    function isOutOfStock(uint256 itemId, uint16 amount)
        external
        view
        returns (bool);

    /**
     * @notice Create an wasted item.
     */
    function createWastedItem(
        string memory name,
        uint16 maxSupply,
        ItemType itemType,
        Rarity rarity
    ) external;

    /**
     * @notice Returns ERC1155 equipment back to the owner.
     */
    function returnItems(address account, uint256[] memory itemIds) external;

    /**
     * @notice Add next star of item to existing one.
     *
     * Requirements:
     *  - Only operator of system.
     */
    function addNextStar(uint256 itemId, uint8 upgradeAmount) external;

    /**
     * @notice Burns the same items to upgrade its star.
     *
     * Requirements:
     * - `servicesFeeInToken` is required.
     * - Item must have its next tier.
     * - Caller's balance must have at least `upgradeAmount` to upgrade item.
     */
    function upgradeWastedItem(uint256 itemId) external;

    /**
     * @notice Get informations of item by itemId
     */

    function getWastedItem(uint256 itemId)
        external
        view
        returns (WastedItem memory item);

    /**
     * @notice Gets wasted item type.
     */
    function getWastedItemType(uint256 itemId) external view returns (ItemType);

    /**
     * @notice Gets owner of given pet.
     */
    function ownerOf(uint256 itemId) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}