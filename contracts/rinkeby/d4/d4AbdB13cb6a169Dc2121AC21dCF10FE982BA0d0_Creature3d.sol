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
        uint32     index;
        uint64     birthday;
        uint32     chadId;
        uint32     meebitId;
        string     name;
    }

    mapping (uint256 => Animal) public animals;
    Creatures public creatureContract;
    IMeebit public meebitContract;
    IDung public megadungContract;
    mapping (uint256 => bool) public usedChads;
    uint constant MEGADUNG_FEE = 1 ether; // TODO: replace with 1000

    event Meet(address owner, uint indexed chadId, uint indexed meebitId, uint indexed creature3dId);

    constructor(
        string memory name_,
        string memory symbol_,
        Creatures _creatureContract,
        IMeebit _meebitContract,
        IDung _megadungContract
    )
        ERC721(name_, symbol_)
    {
        creatureContract = _creatureContract;
        meebitContract = _meebitContract;
        megadungContract = _megadungContract;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint8 _animalType,
        uint32 index,
        uint32 chadId,
        uint32 meebitId
    ) internal {
        _mint(to, tokenId);
        animals[tokenId] = Animal(Creatures.AnimalType(_animalType), index, uint64(block.timestamp), chadId, meebitId, "");
    }

    function setName(uint256 tokenId, string calldata _name) external {
        require(ownerOf(tokenId) == msg.sender, 'Only owner can change name');
        require(bytes(animals[tokenId].name).length == 0, 'The name has already been given');

        animals[tokenId].name = _name;
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function canMeet(uint chadId) public view returns (bool) {
        uint8 rarity;
        (, rarity) = creatureContract.getTypeAndRarity(chadId);
        if ((Creatures.Rarity)(rarity) != Creatures.Rarity.Chad) {
            return false;
        }

        return !usedChads[chadId];
    }

    function getReadyForMeetChads(address _owner) external view returns (uint256[] memory) {
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

    function meet(uint chadId, uint meebitId) external {
        require(canMeet(chadId), 'Chad can not meet');
        require(creatureContract.ownerOf(chadId) == msg.sender, 'Wrong chad owner');
        require(meebitContract.ownerOf(meebitId) == msg.sender, 'Wrong meebit owner');

        megadungContract.transferFrom(msg.sender, address(this), MEGADUNG_FEE);
        megadungContract.burn(MEGADUNG_FEE);

        Creatures.AnimalType atype; // uint8
        Creatures.Rarity     rarity; // uint8
        uint32     index;
        (atype, rarity, index, , ) = creatureContract.animals(chadId);
        uint newTokenId = totalSupply();
        mint(msg.sender, newTokenId, uint8(atype), index, uint32(chadId), uint32(meebitId));

        usedChads[chadId] = true;
        emit Meet(msg.sender, chadId, meebitId, newTokenId);
    }
}