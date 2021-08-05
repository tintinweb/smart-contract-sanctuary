// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";
import "./CreatureERC721.sol";

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

    constructor(string memory name_, string memory symbol_, Creatures _creatureContract, IMeebit _meebitContract)
        ERC721(name_, symbol_)
    {
        creatureContract = _creatureContract;
        meebitContract = _meebitContract;
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
        //We can return only uint256[] memory
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function getMeebitUsersTokens(address _owner) external view returns (uint256[] memory) {
        //We can return only uint256[] memory
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
        // TODO: checks
        // TODO: dung payment
        Creatures.AnimalType atype; // uint8
        Creatures.Rarity     rarity; // uint8
        uint32     index;
        (atype, rarity, index, , ) = creatureContract.animals(chadId);
        mint(msg.sender, totalSupply(), uint8(atype), index, uint32(chadId), uint32(meebitId));
        // TODO: save used
    }
}