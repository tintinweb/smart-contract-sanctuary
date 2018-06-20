pragma solidity ^0.4.18;

contract GeneScience {

    uint256 public randomSeed = 1;

    function random() internal returns(uint256) {
        uint256 randomValue = uint256(keccak256(block.timestamp, uint256(randomSeed * block.difficulty)));
        randomSeed = uint256(randomValue * block.number);
        return randomValue;
    }

    //基因种类
    uint8 public geneKind = 8;

    //合约拥有者
    address public owner;

    address public dogCore;

    bool public isGeneScience = true;

    function GeneScience(address _dogCore) public {
        dogCore = _dogCore;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setKittyCoreAddress(address newDogCore) public onlyOwner {
        if (newDogCore != address(0)) {
            dogCore = newDogCore;
        }
    }

    function setGeneKind(uint8 value) public onlyOwner {
        if (value >= 12) {
            geneKind = 12;
        } else if (value <= 1) {
            geneKind = 1;
        } else {
            geneKind = value;
        }
    }

    function convertGeneArray(uint256 gene) internal returns(uint8[48]) {
        uint8[48] memory geneArray;
        uint8 index = 0;
        uint8 length = 4 * geneKind;
        for (index = 0; index < length; index++) {
            uint256 geneItem = gene % (2 ** uint256((5 * (index + 1))));
            geneItem /= (2 ** uint256(5 * index));
            geneArray[index] = uint8(geneItem);
        }
        for (index = 0; index < geneKind; index++) {
            uint8 size = 4 * index;
            uint8 probably = 12;
            for (uint8 item = 3; item > 0; item--) {
                uint8 randomValue = uint8(random() % 16);
                if (randomValue >= probably) {
                    (geneArray[size + item], geneArray[size + item - 1]) = (geneArray[size + item - 1], geneArray[size + item]);
                }
            }
        }
        return geneArray;
    }

    function convertGene(uint8[48] geneArray) internal view returns(uint256) {
        uint256 gene = uint256(geneArray[0]);
        uint8 length = 4 * geneKind;
        for (uint8 index = 1; index < length; index++) {
            uint256 geneItem = uint256(geneArray[index]);
            gene += geneItem << (index * 5);
        }
        return gene;
    }

    function mixGenes(uint256 matronGene, uint256 sireGene, uint256 targetBlock) public returns (uint256) {
        require(msg.sender == dogCore || msg.sender == owner);
        
        randomSeed = uint256(randomSeed * targetBlock);

        uint8[48] memory matronGeneArray = convertGeneArray(matronGene);
        uint8[48] memory sireGeneArray = convertGeneArray(sireGene);
        uint8[48] memory babyGeneArray;

        uint8 length = 4 * geneKind;
        uint8 probably = 8;
        for (uint8 index = 0; index < length; index++) {
            uint8 randomValue = uint8(random() % 16);
            if (randomValue < probably) {
                babyGeneArray[index] = matronGeneArray[index];
            } else {
                babyGeneArray[index] = sireGeneArray[index];
            }
        }
        return convertGene(babyGeneArray);
    }
}