// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";
import "./CreatureERC721.sol";
import "./IDung.sol";

interface IWizard is IERC721, IERC721Enumerable {

}

contract FarmWizards is ERC721URIStorage {

    struct Animal {
        Creatures.AnimalType atype; // uint8
        Creatures.Rarity     rarity; // uint8
        uint32     index;
        uint64     birthday;
        uint32     creatureId;
        uint32     wizardId;
        string     name;
    }

    mapping (uint256 => Animal) public animals;
    mapping (uint256 => bool) public allowedRarity;
    Creatures public creatureContract;
    IWizard public wizardContract;
    IDung public feeContract;
    mapping (uint256 => bool) public usedCreatures;
    uint public feeAmount;
    mapping (uint8 => uint[]) allowedWizardsBitmap;

    event Meet(address owner, uint indexed creatureId, uint indexed wizardId, uint indexed newTokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        Creatures _creatureContract,
        IWizard _wizardContract,
        IDung _feeContract,
        uint _feeAmount
    )
    ERC721(name_, symbol_)
    {
        creatureContract = _creatureContract;
        wizardContract = _wizardContract;
        feeContract = _feeContract;
        feeAmount = _feeAmount;
        setAllowedRarity(0, true);
        setAllowedRarity(1, true);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint8 _animalType,
        uint8 _rarity,
        uint32 index,
        uint32 creatureId,
        uint32 wizardId
    ) internal {
        _mint(to, tokenId);
        animals[tokenId] = Animal(
            Creatures.AnimalType(_animalType),
            Creatures.Rarity(_rarity),
            index,
            uint64(block.timestamp),
            creatureId,
            wizardId,
            "");
    }

    function setName(uint256 tokenId, string calldata _name) external {
        require(ownerOf(tokenId) == msg.sender, 'Only owner can change name');
        require(bytes(animals[tokenId].name).length == 0, 'The name has already been given');

        animals[tokenId].name = _name;
    }

    function setAllowedWizardsBitmap(uint8 atype, uint[] calldata _allowedWizardsBitmap) external onlyOwner {
        allowedWizardsBitmap[atype] = _allowedWizardsBitmap;
    }

    function setFee(uint _feeAmount) external onlyOwner {
        require(_feeAmount > feeAmount, "New fee amount must be greater");
        feeAmount = _feeAmount;
    }

    function setAllowedRarity(uint _rarity, bool _allow) public onlyOwner {
        allowedRarity[_rarity] = _allow;
    }

    function canMeetCreature(uint creatureId) public view returns (bool) {
        uint8 rarity;
        (, rarity) = creatureContract.getTypeAndRarity(creatureId);
        if (!allowedRarity[rarity]) {
            return false;
        }

        return !usedCreatures[creatureId];
    }

    function canMeetWizard(uint8 atype, uint wizardId) public view returns (bool) {
        uint bitWordIndex = wizardId/256;
        if (bitWordIndex >= allowedWizardsBitmap[atype].length) {
            return false;
        }
        uint bitWord = allowedWizardsBitmap[atype][bitWordIndex];
        uint indexInWord = wizardId%256;
        return (bitWord & (1 << indexInWord)) != 0;
    }

    function baseURI() public pure override returns (string memory) {
        return 'http://degens.farm/meta/wizards/';
    }

    function meet(uint creatureId, uint wizardId) external {
        require(canMeetCreature(creatureId), 'Creature can not meet');
        require(creatureContract.ownerOf(creatureId) == msg.sender, 'Wrong creature owner');
        require(wizardContract.ownerOf(wizardId) == msg.sender, 'Wrong wizard owner');

        feeContract.transferFrom(msg.sender, address(this), feeAmount);
        feeContract.burn(feeAmount);

        Creatures.AnimalType atype; // uint8
        Creatures.Rarity     rarity; // uint8
        uint32     index;
        (atype, rarity, index, , ) = creatureContract.animals(creatureId);

        require(canMeetWizard(uint8(atype), wizardId), 'Wizard can not meet');

        uint newTokenId = totalSupply();
        mint(msg.sender, newTokenId, uint8(atype), uint8(rarity), index, uint32(creatureId), uint32(wizardId));

        usedCreatures[creatureId] = true;
        emit Meet(msg.sender, creatureId, wizardId, newTokenId);
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function getReadyForMeetCreatures(address _owner) external view returns (uint256[] memory) {
        uint256 rawBalance = creatureContract.balanceOf(_owner);
        uint256[] memory rawCreatures = creatureContract.getUsersTokens(_owner);

        uint256 resultCount = 0;

        for (uint i = 0; i < rawBalance; i++) {
            if (canMeetCreature(rawCreatures[i])) {
                rawCreatures[resultCount] = rawCreatures[i];
                resultCount++;
            }
        }

        uint256[] memory result = new uint256[](resultCount);
        for (uint16 i = 0; i < resultCount; i++) {
            result[i] = rawCreatures[i];
        }

        return result;
    }


    function getReadyForMeetWizards(uint8 atype, address _owner) external view returns (uint256[] memory) {
        uint256 rawBalance = wizardContract.balanceOf(_owner);
        uint256[] memory rawCreatures = new uint256[](rawBalance);
        uint256 resultCount = 0;

        for (uint i = 0; i < rawBalance; i++) {
            uint tokenId = wizardContract.tokenOfOwnerByIndex(_owner, i);
            if (canMeetWizard(atype, tokenId)) {
                rawCreatures[resultCount] = tokenId;
                resultCount++;
            }
        }

        uint256[] memory result = new uint256[](resultCount);
        for (uint16 i = 0; i < resultCount; i++) {
            result[i] = rawCreatures[i];
        }

        return result;
    }

    function getWizardUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = wizardContract.balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = wizardContract.tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }
}