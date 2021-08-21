// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";
import "./CreatureERC721.sol";
import "./IDung.sol";

interface IMeebit is IERC721, IERC721Enumerable {

}

contract Creature3d is ERC721URIStorage {

    struct Animal {
        Creatures.AnimalType atype; // uint8
        Creatures.Rarity     rarity; // uint8
        uint32     index;
        uint64     birthday;
        uint32     creatureId;
        uint32     meebitId;
        string     name;
    }

    mapping (uint256 => Animal) public animals;
    mapping (uint256 => bool) public allowedRarity;
    Creatures public creatureContract;
    IMeebit public meebitContract;
    IDung public feeContract;
    mapping (uint256 => bool) public usedCreatures;
    uint public feeAmount;

    event Meet(address owner, uint indexed creatureId, uint indexed meebitId, uint indexed creature3dId);

    constructor(
        string memory name_,
        string memory symbol_,
        Creatures _creatureContract,
        IMeebit _meebitContract,
        IDung _feeContract,
        uint _feeAmount
    )
        ERC721(name_, symbol_)
    {
        creatureContract = _creatureContract;
        meebitContract = _meebitContract;
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
        uint32 meebitId
    ) internal {
        _mint(to, tokenId);
        animals[tokenId] = Animal(
            Creatures.AnimalType(_animalType),
            Creatures.Rarity(_rarity),
            index,
            uint64(block.timestamp),
            creatureId,
            meebitId,
            "");
    }

    function setName(uint256 tokenId, string calldata _name) external {
        require(ownerOf(tokenId) == msg.sender, 'Only owner can change name');
        require(bytes(animals[tokenId].name).length == 0, 'The name has already been given');

        animals[tokenId].name = _name;
    }

    function setFee(uint _feeAmount) external onlyOwner {
        require(_feeAmount > feeAmount, "New fee amount must be greater");
        feeAmount = _feeAmount;
    }

    function setAllowedRarity(uint _rarity, bool _allow) public onlyOwner {
        allowedRarity[_rarity] = _allow;
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function canMeet(uint creatureId) public view returns (bool) {
        uint8 rarity;
        (, rarity) = creatureContract.getTypeAndRarity(creatureId);
        if (!allowedRarity[rarity]) {
            return false;
        }

        return !usedCreatures[creatureId];
    }

    function getReadyForMeetCreatures(address _owner) external view returns (uint256[] memory) {
        uint256 rawBalance = creatureContract.balanceOf(_owner);
        uint256[] memory rawCreatures = creatureContract.getUsersTokens(_owner);

        uint256 resultCount = 0;

        for (uint i = 0; i < rawBalance; i++) {
            if (canMeet(rawCreatures[i])) {
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

    function getMeebitUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = meebitContract.balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = meebitContract.tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function baseURI() public view override returns (string memory) {
        return 'http://degens.farm/meta/creatures3d/';
    }

    function meet(uint creatureId, uint meebitId) external {
        require(canMeet(creatureId), 'Creature can not meet');
        require(creatureContract.ownerOf(creatureId) == msg.sender, 'Wrong creature owner');
        require(meebitContract.ownerOf(meebitId) == msg.sender, 'Wrong meebit owner');

        feeContract.transferFrom(msg.sender, address(this), feeAmount);
        feeContract.burn(feeAmount);

        Creatures.AnimalType atype; // uint8
        Creatures.Rarity     rarity; // uint8
        uint32     index;
        (atype, rarity, index, , ) = creatureContract.animals(creatureId);
        uint newTokenId = totalSupply();
        mint(msg.sender, newTokenId, uint8(atype), uint8(rarity), index, uint32(creatureId), uint32(meebitId));

        usedCreatures[creatureId] = true;
        emit Meet(msg.sender, creatureId, meebitId, newTokenId);
    }
}