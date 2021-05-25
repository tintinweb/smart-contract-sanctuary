// SPDX-License-Identifier: MIT
// // Degen Farm. Collectible NFT game
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";

contract Creatures is ERC721URIStorage {

    enum AnimalType {
        Cow, Horse, Rabbit, Chicken, Pig, Cat, Dog, Goose, Goat, Sheep,
        Snake, Fish, Frog, Worm, Lama, Mouse, Camel, Donkey, Bee, Duck,
        GenesisEgg // 20
    }
    enum Rarity     {
        Normie, // 0
        Chad,   // 1
        Degen,  // 2
        Unique // 3
    }

    struct Animal {
        AnimalType atype; // uint8
        Rarity     rarity; // uint8
        uint32     index;
        uint64     birthday;
        string     name;
    }

    mapping (uint256 => Animal) public animals;

    mapping(address => bool) public trusted_markets;
    event TrustedMarket(address indexed _market, bool _state);

    constructor(string memory name_,
        string memory symbol_) ERC721(name_, symbol_)  {
    }

    function mint(
        address to,
        uint256 tokenId,
        uint8 _animalType,
        uint8 _rarity,
        uint32 index
        ) external onlyOwner {

        _mint(to, tokenId);
        animals[tokenId] = Animal(AnimalType(_animalType), Rarity(_rarity), index, uint64(block.timestamp), "");
    }

    function setName(uint256 tokenId, string calldata _name) external {
        require(ownerOf(tokenId) == msg.sender, 'Only owner can change name');
        require(bytes(animals[tokenId].name).length == 0, 'The name has already been given');

        animals[tokenId].name = _name;
    }

    function setTrustedMarket(address _market, bool _state) external onlyOwner {
        trusted_markets[_market] = _state;
        emit TrustedMarket(_market, _state);
    }

    function getTypeAndRarity(uint256 _tokenId) external view returns(uint8, uint8) {
        return (uint8(animals[_tokenId].atype), uint8(animals[_tokenId].rarity));
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        //We can return only uint256[] memory
         uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i=0; i < n; i++) {
            result[i]=tokenOfOwnerByIndex(_owner, i);
        }
        return  result;
    }

    function baseURI() public view override returns (string memory) {
        return 'http://degens.farm/meta/creatures/';
    }

    /**
     * @dev Overriding standart function for gas safe traiding with trusted parts like DegenFarm
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `caller` must be added to trustedMarkets.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (trusted_markets[msg.sender]) {
            _transfer(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }

    }
}