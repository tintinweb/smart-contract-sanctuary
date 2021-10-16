// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./LootGenerator.sol";
import "./MoreLoot.sol";
import "./Random.sol";

contract ReLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    struct Loot {
        int[5][8] equipment;
        bool exist;
        bool lock;
    }
    
    LootGenerator _lootGenerator;
    TemporalLoot _moreLoot;
    uint256 private _seed;
    uint256 private _commissionPerItem;
    uint256 private _claimDIYPrice;
    uint256 private _allowMaxTokenId;
    uint[] private _probability;
    uint private _extraProbability;
    string _secretKey;
    mapping(uint256 => Loot) private _reloots;

    function setLock(uint256 tokenId, bool flag) external {
        require(msg.sender == ownerOf(tokenId), "Err: reloot that is not own");
        _reloots[tokenId].lock = flag;
    }

    function getLock(uint256 tokenId) external view returns(bool) {
        require(_exists(tokenId), "Err: nonexistent token");
        return _reloots[tokenId].lock;
    }

    function getSecretKey() external view onlyOwner returns(string memory) {
        return _secretKey;
    }

    function setSecretKey(string memory secretKey) external onlyOwner {
        require(bytes(secretKey).length >= 10, "Err: secret key length is less 10");
        _secretKey = secretKey;
    }

    function getclaimDIYPrice() external view returns(uint256) {
        return _claimDIYPrice;
    }

    function setclaimDIYPrice(uint256 claimDIYPrice) external onlyOwner {
        _claimDIYPrice = claimDIYPrice;
    }

    function getExtraProbability() external view returns(uint) {
        return _extraProbability;
    }

    function setExtraProbability(uint extraProbability) external onlyOwner {
        _extraProbability = extraProbability;
    }

    function getProbability() external view returns(uint[] memory) {
        return _probability;
    }

    function setProbability(uint[] memory probability) external onlyOwner {
        _probability = probability;
    }

    function getCommissionPerItem() external view returns(uint256){
        return _commissionPerItem;
    }

    function setCommissionPerItem(uint256 commissionPerItem) external onlyOwner {
        _commissionPerItem = commissionPerItem;
    }

    function getAllowMaxTokenId() external view returns(uint256){
        return _allowMaxTokenId;
    }

    function setAllowMaxTokenId(uint256 allowMaxTokenId) external onlyOwner {
        _allowMaxTokenId = allowMaxTokenId;
    }

    // function getArmor(uint256 tokenId, uint256 idx) public view returns(string memory){
    //     Loot memory loot = _reloots[tokenId];
    //     if (!loot.exist) {
    //         return "";
    //     }
        
    //     return _lootGenerator.getEquipment(loot.equipment[idx], idx);
    // }

    function getEquipmentVector(uint256 tokenId, uint256 idx) external view returns(int[5] memory){
        Loot memory loot = _reloots[tokenId];
        if (!loot.exist) {
           return [int(-1),-1,-1,-1,-1];
        }

        return loot.equipment[idx];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        Loot memory loot = _reloots[tokenId];
        if (!loot.exist) {
            return "";
        }
        
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = _lootGenerator.getEquipment(loot.equipment[0], 0);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = _lootGenerator.getEquipment(loot.equipment[1], 1);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = _lootGenerator.getEquipment(loot.equipment[2], 2);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = _lootGenerator.getEquipment(loot.equipment[3], 3);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = _lootGenerator.getEquipment(loot.equipment[4], 4);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = _lootGenerator.getEquipment(loot.equipment[5], 5);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = _lootGenerator.getEquipment(loot.equipment[6], 6);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = _lootGenerator.getEquipment(loot.equipment[7], 7);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', tokenId.toString(), '", "description": "More Loot is additional randomized adventurer gear generated and stored on chain. Maximum supply is dynamic, increasing at 1/10th of Ethereum\'s block rate. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use More Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

       return output;
    //     Loot memory loot = _reloots[tokenId];
    //     if (!loot.exist) {
    //         return "";
    //     }
    //    string[8] memory part;
    //    part[0] = _lootGenerator.getEquipment(loot.equipment[0], 0);
    //    part[1] = _lootGenerator.getEquipment(loot.equipment[1], 1);
    //    part[2] = _lootGenerator.getEquipment(loot.equipment[2], 2);
    //    part[3] = _lootGenerator.getEquipment(loot.equipment[3], 3);
    //    part[4] = _lootGenerator.getEquipment(loot.equipment[4], 4);
    //    part[5] = _lootGenerator.getEquipment(loot.equipment[5], 5);
    //    part[6] = _lootGenerator.getEquipment(loot.equipment[6], 6);
    //    part[7] = _lootGenerator.getEquipment(loot.equipment[7], 7);

    //    string memory output = string(abi.encodePacked(part[0], '#', part[1], '#', part[2], '#', part[3], '#', part[4], '#', part[5], '#', part[6], '#', part[7]));
    //    return output;  
    }
    
    function claim(uint256 tokenId) public nonReentrant {
        // require(tokenId > 8000 && tokenId < (block.number / 10) + 1, "Token ID invalid");
        require(tokenId <= _allowMaxTokenId, "Err: Token ID invalid");
        _safeMint(_msgSender(), tokenId);
        _reloots[tokenId].equipment[0] = _lootGenerator.mint(tokenId, 0);
        _reloots[tokenId].equipment[1] = _lootGenerator.mint(tokenId, 1);
        _reloots[tokenId].equipment[2] = _lootGenerator.mint(tokenId, 2);
        _reloots[tokenId].equipment[3] = _lootGenerator.mint(tokenId, 3);
        _reloots[tokenId].equipment[4] = _lootGenerator.mint(tokenId, 4);
        _reloots[tokenId].equipment[5] = _lootGenerator.mint(tokenId, 5);
        _reloots[tokenId].equipment[6] = _lootGenerator.mint(tokenId, 6);
        _reloots[tokenId].equipment[7] = _lootGenerator.mint(tokenId, 7);
        _reloots[tokenId].exist = true;
    }

    function claimDIYWithID(uint256 sign, uint256 tokenId, int[5][8] memory equipment) public payable {
        require(sign == Random.toHash(_msgSender(), _secretKey), "Err: sign is invaild");
        require(_claimDIYPrice == msg.value, "Err: insufficient payment");
        require(tokenId <= _allowMaxTokenId, "Err: Token ID invalid");
        mint(tokenId, equipment);
    }

    function compareEquipment(int[5] memory equipmentA, int[5] memory equipmentB) internal pure returns(bool){
        for (uint i = 0; i < equipmentA.length; i++) {
            if (equipmentA[i] != equipmentB[i]) {
                return false;
            }
        }
        return true;
    }

    function validate(uint256 tokenIdA, uint256 tokenIdB) internal view {
        require(msg.sender == ownerOf(tokenIdA), "Err: reloot that is not own");
        require(msg.sender == ownerOf(tokenIdB), "Err: reloot that is not own");
        require(tokenIdA != tokenIdB, "Err: can not compose same reloot");
    }

    function composeRe(uint256 tokenIdA, uint256 tokenIdB, uint[] memory idxs, bool burn) public payable {
        validate(tokenIdA, tokenIdB);
        require(idxs.length > 0 && idxs.length <= 8, "Err: idxs length is invalid");
        require(idxs.length * _commissionPerItem <= msg.value, "Err: insufficient payment");

        Loot memory lootA = _reloots[tokenIdA];
        Loot memory lootB = _reloots[tokenIdB];

        bool[] memory unsameArmorFlag = new bool[](8);
        uint unsameArmor;
        for (uint i = 0; i < idxs.length; i++) {
            if (!compareEquipment(lootA.equipment[idxs[i]], lootB.equipment[idxs[i]])) {
                if (!unsameArmorFlag[idxs[i]]) {
                    unsameArmorFlag[idxs[i]] = true;
                    unsameArmor++;
                }  
            }
        }

        uint[] memory unsameArmorIdx = new uint[](unsameArmor);
        uint j;
        for (uint i = 0; i < unsameArmorFlag.length; i++) {
            if (unsameArmorFlag[i]) {
                unsameArmorIdx[j] = i;
                j++; 
            }
        }

        shuffle(unsameArmorIdx);
        uint extra = _extraProbability;
        if (!burn) {
            extra = 0;
        } 

        for (uint i = 0; i < unsameArmorIdx.length; i++) {
            if (ProbabilityGenerator(_probability[i]+extra)) {
                _reloots[tokenIdA].equipment[unsameArmorIdx[i]] = lootB.equipment[unsameArmorIdx[i]];
            }
        }

        if (msg.value != 0) {
            address payable owner = payable(owner());
            owner.transfer(msg.value);
        }
      
        if (burn) {
            //_burn(tokenIdB);
            super.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenIdB);
            //delete _reloots[tokenIdB];
        }
    }

    function ProbabilityGenerator(uint x) internal returns(bool){
        _seed++;
        if (Random.randNum(_seed, 100) < x) {
            return true;
        }
        return false;
    }

    function shuffle(uint[] memory arr) internal view {
        for (uint256 i = 0; i < arr.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (arr.length - i);
            uint256 temp = arr[n];
            arr[n] = arr[i];
            arr[i] = temp;
        }
    }

    function mint(uint256 tokenId, int[5][8] memory equipment) internal {
        require(_lootGenerator.validateEquipmentIdx(equipment[0], 0), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[1], 1), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[2], 2), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[3], 3), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[4], 4), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[5], 5), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[6], 6), "Err: invaild reloot");
        require(_lootGenerator.validateEquipmentIdx(equipment[7], 7), "Err: invaild reloot");
        _safeMint(_msgSender(), tokenId);
        _reloots[tokenId].equipment = equipment;
        _reloots[tokenId].exist = true;
    }

    function burnMoreLoot(uint256 tokenId, int[5][8] memory equipment) external returns(uint256) {
        require(msg.sender == _moreLoot.ownerOf(tokenId), "Err: more loot that is not own");
        uint256 relootTokenId = tokenId;
        while (_exists(relootTokenId)) {
            relootTokenId += 1;
        }
        require(relootTokenId <= _allowMaxTokenId, "Err: Token ID invalid");
        mint(relootTokenId, equipment);
        _moreLoot.safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId);
        return relootTokenId;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!_reloots[tokenId].lock, "Err: reloot is locked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(!_reloots[tokenId].lock, "Err: reloot is locked");
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(!_reloots[tokenId].lock, "Err: reloot is locked");
        super.safeTransferFrom(from, to, tokenId, _data);
    }


    constructor(string memory secretKey, address lootGenerator, address moreLoot, uint256 allowMaxTokenId, uint256 commissionPerItem, uint256 claimDIYPrice, uint[] memory probability, uint extraProbability) ERC721("ReLoot", "RELOOT") Ownable() {
        require(probability.length == 8, "Err: probability must have 8 elements");
        require(lootGenerator != address(0), "Err: input addr is addr(0)");
        require(moreLoot != address(0), "Err: input addr is addr(0)");
        _lootGenerator = LootGenerator(lootGenerator);
        _moreLoot = TemporalLoot(moreLoot);
        _allowMaxTokenId = allowMaxTokenId;
        _commissionPerItem = commissionPerItem;
        _probability = probability;
        _extraProbability = extraProbability;
        _secretKey = secretKey;
        _claimDIYPrice = claimDIYPrice;
        _seed = Random.randNum(0, 1000000);
    }
}