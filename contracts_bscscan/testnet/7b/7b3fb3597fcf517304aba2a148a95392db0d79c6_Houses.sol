// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./MinterRole.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./IHousesNFT.sol";

contract Houses is Context, Ownable, MinterRole, Pausable, ERC721, IHousesNFT {
    using SafeMath for uint256;
    
    // multiplier range for 'luxury', 'durability', and 'luck' attributes. from 0.95 to 1.3
    uint256 constant private MULTIPLIER_MIN = 95;   //0.95
    uint256 constant private MULTIPLIER_MAX = 130;  //1.3
    // base values for buildingPeirod of 6 levels
    uint256 private _level1BuildingPeriod = 30 minutes;
    uint256 private _level2BuildingPeriod = 1 hours;
    uint256 private _level3BuildingPeriod = 2 hours;
    uint256 private _level4BuildingPeriod = 5 hours;
    uint256 private _level5BuildingPeriod = 24 hours;
    uint256 private _level6BuildingPeriod = 720 hours;
    // base values for area of 6 levels (unit in m^2, square meters)
    uint256 private _level1Area = 1;
    uint256 private _level2Area = 1;
    uint256 private _level3Area = 2;
    uint256 private _level4Area = 4;
    uint256 private _level5Area = 16;
    uint256 private _level6Area = 400;
    // base values for luxury of 6 levels
    uint256 private _level1Luxury = 1;
    uint256 private _level2Luxury = 5;
    uint256 private _level3Luxury = 25;
    uint256 private _level4Luxury = 80;
    uint256 private _level5Luxury = 700;
    uint256 private _level6Luxury = 10000;
    // base values for durability of 6 levels
    uint256 private _level1Durability = 6;
    uint256 private _level2Durability = 6;
    uint256 private _level3Durability = 24;
    uint256 private _level4Durability = 72;
    uint256 private _level5Durability = 168;
    uint256 private _level6Durability = 2000;
    // base values for luck of 6 levels (base *10 to be initeger)
    uint256 private _level1Luck = 10;  //1
    uint256 private _level2Luck = 12;  //1.2
    uint256 private _level3Luck = 15;  //1.5
    uint256 private _level4Luck = 20;  //2
    uint256 private _level5Luck = 40;  //4
    uint256 private _level6Luck = 500; //50
    // base values for rentingPeriod of 6 levels
    uint256 private _allLevelRentingPeriod = 8 hours;
    // base values for protectingPeriod of 6 levels
    uint256 private _allLevelProtectingPeriod = 5 minutes;

    struct attributes {
        uint256 level;
        uint256 buildingPeriod;
        uint256 area;
        uint256 luxury;
        uint256 durability;
        uint256 luck;
        uint256 rentingPeriod;
        uint256 protectingPeriod;
    }

    // house's tokenId => attributes
    mapping(uint256 => attributes) private houseAttributes;
    // event of set a house's attribute when the house is minted
    event SetHouseAttributes(uint256 indexed tokenId, uint256 indexed level);

    constructor() ERC721("Bino Houses", "Bhouses") public {

    }

    function safeMint(address to, uint256 tokenId, uint256 level) public virtual override onlyMinter {
        require(level >= 1 && level <=6, "level is not in the range of [1, 6]");
        _safeMint(to, tokenId);
        _setHouseAttributes(tokenId, level);
    }

    function burn(uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    function checkHouseLevel(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.level;
    }

    function checkHouseBulidingPeriod(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.buildingPeriod;
    }

    function checkHouseArea(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.area;
    }

    function checkHouseLuxury(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.luxury;
    }

    function checkHouseDurability(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.durability;
    }

    function checkHouseLuck(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.luck;
    }

    function checkHouseRentingPeriod(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.rentingPeriod;
    }

    function checkHouseProtectingPeriod(uint256 tokenId) public override view returns (uint256) {
        require(_exists(tokenId), "check house attributes for nonexistent tokenId");
        attributes storage thisHouse = houseAttributes[tokenId];
        return thisHouse.protectingPeriod;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function _setHouseAttributes(uint256 tokenId, uint256 level) private {
        attributes storage thisHouse = houseAttributes[tokenId];

        thisHouse.level = level;
        thisHouse.rentingPeriod = _allLevelRentingPeriod;
        thisHouse.protectingPeriod = _allLevelProtectingPeriod;
        if (level == 1) {
            thisHouse.buildingPeriod = _level1BuildingPeriod;
            thisHouse.area = _level1Area;
            // multiply by a random MULTIPLIER
            thisHouse.luxury = _level1Luxury.mul(_getRandomMultiplier());
            thisHouse.durability = _level1Durability.mul(_getRandomMultiplier());
            thisHouse.luck = _level1Luck.mul(_getRandomMultiplier());
        } else if (level == 2) {
            thisHouse.buildingPeriod = _level2BuildingPeriod;
            thisHouse.area = _level2Area;
            // multiply by a random MULTIPLIER
            thisHouse.luxury = _level2Luxury.mul(_getRandomMultiplier());
            thisHouse.durability = _level2Durability.mul(_getRandomMultiplier());
            thisHouse.luck = _level2Luck.mul(_getRandomMultiplier());
        } else if (level == 3) {
            thisHouse.buildingPeriod = _level3BuildingPeriod;
            thisHouse.area = _level3Area;
            // multiply by a random MULTIPLIER
            thisHouse.luxury = _level3Luxury.mul(_getRandomMultiplier());
            thisHouse.durability = _level3Durability.mul(_getRandomMultiplier());
            thisHouse.luck = _level3Luck.mul(_getRandomMultiplier());
        } else if (level == 4) {
            thisHouse.buildingPeriod = _level4BuildingPeriod;
            thisHouse.area = _level4Area;
            // multiply by a random MULTIPLIER
            thisHouse.luxury = _level4Luxury.mul(_getRandomMultiplier());
            thisHouse.durability = _level4Durability.mul(_getRandomMultiplier());
            thisHouse.luck = _level4Luck.mul(_getRandomMultiplier());
        } else if (level == 5) {
            thisHouse.buildingPeriod = _level5BuildingPeriod;
            thisHouse.area = _level5Area;
            // multiply by a random MULTIPLIER
            thisHouse.luxury = _level5Luxury.mul(_getRandomMultiplier());
            thisHouse.durability = _level5Durability.mul(_getRandomMultiplier());
            thisHouse.luck = _level5Luck.mul(_getRandomMultiplier());
        } else {
            thisHouse.buildingPeriod = _level6BuildingPeriod;
            thisHouse.area = _level6Area;
            // multiply by a random MULTIPLIER
            thisHouse.luxury = _level6Luxury.mul(_getRandomMultiplier());
            thisHouse.durability = _level6Durability.mul(_getRandomMultiplier());
            thisHouse.luck = _level6Luck.mul(_getRandomMultiplier());
        }

        emit SetHouseAttributes(tokenId, level);
    }

    // generate a random integer between MULTIPLIER_MIN to MULTIPLIER_MAX
    function _getRandomMultiplier() private view returns (uint256) {
        // randomSeed % (130 - 95 + 1) => randomInt = [0, 35]
        uint256 randomInt = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(block.number.sub(1))),
                    uint256(block.coinbase),
                    block.difficulty,
                    block.timestamp,
                    totalSupply()
                )
            )
        ).mod(MULTIPLIER_MAX.sub(MULTIPLIER_MIN).add(1));
        return randomInt.add(MULTIPLIER_MIN);
    }
}