// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BabyCrocZERC721.sol";

interface ISwamp {
    function burn(address _from, uint256 _amount) external;
    function updateBabyCroczReward(address _from, address _to) external;
} 

interface ICrocZ {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BabyCrocZ is BabyCrocZERC721 {

    modifier croczOwner(uint256 croczId) {
        require(CrocZ.ownerOf(croczId) == msg.sender, "Cannot interact with a CrocZ you do not own");
        _;
    }

    modifier babyCroczOwner(uint256 croczId) {
        require(ownerOf(croczId) == msg.sender, "Cannot interact with a BabyCrocZ you do not own");
        _;
    }

    ISwamp public Swamp;
    ICrocZ public CrocZ;
    
    uint256 public BREEDING_PRICE = 500 ether;
    uint256 public ROLL_PRICE = 125 ether;
    bool public breedingActive = false;

    mapping(uint256 => uint256) public babyCrocZ;
    mapping(uint256 => uint256) public babyTime;
    mapping (address => uint256) public balanceBaby;

    event CroczBreeding(uint256 croczId, uint256 parent1, uint256 parent2);

    constructor(string memory name, string memory symbol, uint256 supply) BabyCrocZERC721(name, symbol, supply) {}

    function breed(uint256 parent1, uint256 parent2) external croczOwner(parent1) croczOwner(parent2) {
        uint256 supply = totalSupply();
        require(supply < maxSupply,                               "Cannot breed any more baby CrocZ");
        require(parent1 != parent2,                               "Must select two unique parents");
        require(breedingActive,                                  "Breeding not active yet!");

        Swamp.burn(msg.sender, BREEDING_PRICE);
        uint256 croczId = babyCount;
        babyCrocZ[croczId] = 2;
        babyCount++;
        babyTime[croczId] = block.timestamp;
        _safeMint(msg.sender, croczId);
        balanceBaby[msg.sender]++;
        emit CroczBreeding(croczId, parent1, parent2);
    }

    function reRoll(uint256 croczId) external babyCroczOwner(croczId) {
        uint256 supply = totalSupply();
        require(supply < maxSupply,                               "Cannot roll any more baby CrocZ");
        require(breedingActive,                                  "Breeding not active yet!");
        require(block.timestamp <= babyTime[croczId] + 86400,   "Cannot roll baby again");

        Swamp.burn(msg.sender, ROLL_PRICE);
        _burn(croczId);
        uint256 token = babyCount;
        babyCrocZ[token] = 2;
        babyCount++;
        babyTime[token] = 1;
        _safeMint(msg.sender, token);
        balanceBaby[msg.sender]++;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < maxSupply) {
            Swamp.updateBabyCroczReward(from, to);
            balanceBaby[from]--;
            balanceBaby[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (tokenId < maxSupply) {
            Swamp.updateBabyCroczReward(from, to);
            balanceBaby[from]--;
            balanceBaby[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    function setBreedingPrice(uint256 newBreedingPrice) public onlyOwner {
        BREEDING_PRICE = newBreedingPrice;
    }
    
    function setRollPrice(uint256 newRollPrice) public onlyOwner {
        ROLL_PRICE = newRollPrice;
    }

    function setSwamp(address swampAddress) external onlyOwner {
        Swamp = ISwamp(swampAddress);
    }

    function setCrocZ(address croczAddress) external onlyOwner {
        CrocZ = ICrocZ(croczAddress);
    }

    function toggleBreeding() public onlyOwner {
        breedingActive = !breedingActive;
    }
}