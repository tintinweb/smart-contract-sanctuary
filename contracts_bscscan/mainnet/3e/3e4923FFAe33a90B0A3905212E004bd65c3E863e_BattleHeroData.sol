pragma solidity ^0.8.0;


contract BattleHeroData { 

    enum Asset{
        CHARACTER, 
        WEAPON
    }

    enum Rare{
        COMMON,
        LOW_RARE,
        RARE,
        EPIC,
        LEGEND,
        MITIC      
    }

    struct Rarity{
        uint256 min;
        uint256 max;
        string rarity;
        Rare rare;
    }

    struct AssetType{
        uint256 min;
        uint256 max;
        string assetType;
        Asset asset;
    }
    

    struct TrainingLevel { 
        uint256 min;
        uint256 max;
        uint256 level;
        uint256 pct;
    }


  
    struct DeconstructedGen{
        uint256 _type;
        uint256 _asset;
        uint256 _rarity;
        uint256 _stat;
        uint256 _transferible;
    }

    uint minStat = 6;

    Rarity[] rarities;
    AssetType[] assetTypes;    
    
    constructor(){
        
        rarities.push(Rarity(0   , 4993, "COMMON", Rare.COMMON));
        rarities.push(Rarity(4994, 8139, "LOW RARE", Rare.LOW_RARE));
        rarities.push(Rarity(8140, 9611, "RARE", Rare.RARE));
        rarities.push(Rarity(9612, 9953, "EPIC", Rare.EPIC));
        rarities.push(Rarity(9954, 9984, "LEGEND", Rare.LEGEND));
        rarities.push(Rarity(9985, 9999, "MITIC", Rare.MITIC));

        assetTypes.push(AssetType(0 , 49, "CHARACTER", Asset.CHARACTER));
        assetTypes.push(AssetType(50, 99, "WEAPON", Asset.WEAPON));
    }

    function getCommonLevels() public pure returns(TrainingLevel[16] memory){
        TrainingLevel[16] memory _levels;
        _levels[1] = TrainingLevel(0  , 331,  1, 15);          
        _levels[2] = TrainingLevel(332, 664,  2, 15);
        _levels[3] = TrainingLevel(665, 997,  3, 15);
        _levels[4] = TrainingLevel(998, 1330, 4, 15);
        _levels[5] = TrainingLevel(1331, 1663, 5, 15);
        _levels[6] = TrainingLevel(1664, 1996, 6, 15);
        _levels[7] = TrainingLevel(1997, 2329, 7, 15);
        _levels[8] = TrainingLevel(2330, 2662, 8, 15);
        _levels[9] = TrainingLevel(2663, 2995, 9, 15);
        _levels[10] = TrainingLevel(2996, 3328, 10, 15);
        _levels[11] = TrainingLevel(3329, 3661, 11, 15);
        _levels[12] = TrainingLevel(3662, 3994, 12, 15);
        _levels[13] = TrainingLevel(3995, 4327, 13, 15);
        _levels[14] = TrainingLevel(4328, 4660, 14, 15);
        _levels[15] = TrainingLevel(4661, 4993, 15, 15);
        return _levels;
    }

    function getLowRareLevels() public pure returns(TrainingLevel[16] memory){
        TrainingLevel[16] memory _levels;
        _levels[1] = TrainingLevel(4994, 5199, 16, 30);
        _levels[2] = TrainingLevel(5200, 5409, 17, 30);
        _levels[3] = TrainingLevel(5410, 5619, 18, 30);
        _levels[4] = TrainingLevel(5620, 5829, 19, 30);
        _levels[5] = TrainingLevel(5830, 6039, 20, 30);
        _levels[6] = TrainingLevel(6040, 6249, 21, 30);
        _levels[7] = TrainingLevel(6250, 6459, 22, 30);
        _levels[8] = TrainingLevel(6460, 6669, 23, 30);
        _levels[9] = TrainingLevel(6670, 6879, 24, 30);
        _levels[10] = TrainingLevel(6880, 7089, 25, 30);
        _levels[11] = TrainingLevel(7090, 7299, 26, 30);
        _levels[12] = TrainingLevel(7300, 7509, 27, 30);
        _levels[13] = TrainingLevel(7510, 7719, 28, 30);
        _levels[14] = TrainingLevel(7720, 7929, 29, 30);
        _levels[15] = TrainingLevel(7930, 8139, 30, 30);
        return _levels;
    }

    function getRareLevels() public pure returns(TrainingLevel[16] memory){
        TrainingLevel[16] memory _levels;
        _levels[1] = TrainingLevel(8140, 8225, 31, 35);
        _levels[2] = TrainingLevel(8226, 8324, 32, 35);
        _levels[3] = TrainingLevel(8325, 8423, 33, 35);
        _levels[4] = TrainingLevel(8424, 8522, 34, 35);
        _levels[5] = TrainingLevel(8523, 8621, 35, 35);
        _levels[6] = TrainingLevel(8622, 8720, 36, 35);
        _levels[7] = TrainingLevel(8721, 8819, 37, 35);
        _levels[8] = TrainingLevel(8820, 8918, 38, 35);
        _levels[9] = TrainingLevel(8919, 9017, 39, 35);
        _levels[10] = TrainingLevel(9018, 9116, 40, 35);
        _levels[11] = TrainingLevel(9117, 9215, 41, 35);
        _levels[12] = TrainingLevel(9216, 9314, 42, 35);
        _levels[13] = TrainingLevel(9315, 9413, 43, 35);
        _levels[14] = TrainingLevel(9414, 9512, 44, 35);
        _levels[15] = TrainingLevel(9513, 9611, 45, 35);
        return _levels;
    }

    function getEpicLevels() public pure returns(TrainingLevel[16] memory){
        TrainingLevel[16] memory _levels;
        _levels[1] = TrainingLevel(9612, 9631, 46, 40);
        _levels[2] = TrainingLevel(9632, 9654, 47, 40);
        _levels[3] = TrainingLevel(9655, 9677, 48, 40);
        _levels[4] = TrainingLevel(9678, 9700, 49, 40);
        _levels[5] = TrainingLevel(9701, 9723, 50, 40);
        _levels[6] = TrainingLevel(9724, 9746, 51, 40);
        _levels[7] = TrainingLevel(9747, 9769, 52, 40);
        _levels[8] = TrainingLevel(9770, 9792, 53, 40);
        _levels[9] = TrainingLevel(9793, 9815, 54, 40);
        _levels[10] = TrainingLevel(9816, 9838, 55, 40);
        _levels[11] = TrainingLevel(9839, 9861, 56, 40);
        _levels[12] = TrainingLevel(9862, 9884, 57, 40);
        _levels[13] = TrainingLevel(9885, 9907, 58, 40);
        _levels[14] = TrainingLevel(9908, 9930, 59, 40);
        _levels[15] = TrainingLevel(9931, 9953, 60, 40);
        return _levels;
    }

    function getLegendLevels() public pure returns(TrainingLevel[16] memory){
        TrainingLevel[16] memory _levels;
        _levels[1] = TrainingLevel(9954, 9956, 61, 70);
        _levels[2] = TrainingLevel(9957, 9958, 62, 70);
        _levels[3] = TrainingLevel(9959, 9960, 63, 70);
        _levels[4] = TrainingLevel(9961, 9962, 64, 70);
        _levels[5] = TrainingLevel(9963, 9964, 65, 70);
        _levels[6] = TrainingLevel(9965, 9966, 66, 70);
        _levels[7] = TrainingLevel(9967, 9968, 67, 70);
        _levels[8] = TrainingLevel(9969, 9970, 68, 70);
        _levels[9] = TrainingLevel(9971, 9972, 69, 70);
        _levels[10] = TrainingLevel(9973, 9974, 70, 70);
        _levels[11] = TrainingLevel(9975, 9976, 71, 70);
        _levels[12] = TrainingLevel(9977, 9978, 72, 70);
        _levels[13] = TrainingLevel(9979, 9980, 73, 70);
        _levels[14] = TrainingLevel(9981, 9982, 74, 70);
        _levels[15] = TrainingLevel(9983, 9984, 75, 70);
        return _levels;
    }

    function getMiticLevels() public pure returns(TrainingLevel[16] memory){
        TrainingLevel[16] memory _levels;
        _levels[1] = TrainingLevel(9985, 9985, 76, 120);
        _levels[2] = TrainingLevel(9986, 9986, 77, 120);
        _levels[3] = TrainingLevel(9987, 9987, 78, 120);
        _levels[4] = TrainingLevel(9988, 9988, 79, 120);
        _levels[5] = TrainingLevel(9989, 9989, 80, 120);
        _levels[6] = TrainingLevel(9990, 9990, 81, 120);
        _levels[7] = TrainingLevel(9991, 9991, 82, 120);
        _levels[8] = TrainingLevel(9992, 9992, 83, 120);
        _levels[9] = TrainingLevel(9993, 9993, 84, 120);
        _levels[10] = TrainingLevel(9994, 9994, 85, 120);
        _levels[11] = TrainingLevel(9995, 9995, 86, 120);
        _levels[12] = TrainingLevel(9996, 9996, 87, 120);
        _levels[13] = TrainingLevel(9997, 9997, 88, 120);
        _levels[14] = TrainingLevel(9998, 9998, 89, 120);
        _levels[15] = TrainingLevel(9999, 9999, 90, 120);
        return _levels;
    }
    
    function getLevels(Rarity memory _rarity) public pure returns(TrainingLevel[16] memory){
        if(strcmp(_rarity.rarity, "COMMON")){
            return getCommonLevels();
        }
        if(strcmp(_rarity.rarity, "LOW RARE")){
            return getLowRareLevels();
        }
        if(strcmp(_rarity.rarity, "RARE")){
            return getRareLevels();
        }
        if(strcmp(_rarity.rarity, "EPIC")){
            return getEpicLevels();
        }
        if(strcmp(_rarity.rarity, "LEGEND")){
            return getLegendLevels();
        }
        if(strcmp(_rarity.rarity, "MITIC")){
            return getMiticLevels();
        }
        TrainingLevel[16] memory _empty;
        return _empty;
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    
    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    function getTrainingLevel(uint256 gen) public view returns(TrainingLevel memory){
        TrainingLevel memory trainingLevelSelected;
        Rarity memory rarity = getRarity(gen);
        for(uint256 i = 1; i <= 15; i++){
            TrainingLevel memory _trainingLevel = getLevels(rarity)[i];
             if(gen >= _trainingLevel.min && gen <= _trainingLevel.max){
                 trainingLevelSelected = _trainingLevel;
             }
        }
        return trainingLevelSelected;
    }

    function getRarity(uint256 gen) public view returns(Rarity memory){        
        Rarity memory r;        
        for(uint256 i = 0; i <= rarities.length - 1; i++){            
            Rarity memory _rarity = rarities[i];
            if(gen >= _rarity.min && gen <= _rarity.max){
                r = _rarity;
            }
        }
        return r;
    }
    
    function getAssetType(uint256 gen) public view returns(AssetType memory){
        AssetType memory assetType;        
        for(uint256 i = 0; i <= assetTypes.length - 1; i++){
            AssetType memory _assetType = assetTypes[i];
            if(gen >= _assetType.min && gen <= _assetType.max){
                assetType = _assetType;
            }
        }
        return assetType;
    }
    
    function deconstructGen(string calldata gen) public pure returns(DeconstructedGen memory){
        require(bytes(gen).length >= 12, "Gen length is not correctly");
        // Weapon or Character
        string memory _type   = slice(bytes(gen), bytes(gen).length - 2, 2);
        // Which weapon or which character
        string memory _asset  = slice(bytes(gen), bytes(gen).length - 4, 2);
        // Rarity
        string memory _rarity = slice(bytes(gen), bytes(gen).length - 8, 4);
        
        string memory _transferible   = slice(bytes(gen), bytes(gen).length - 12, 2);
        
        string memory _stat = slice(bytes(gen), bytes(gen).length - 14, 2);
        
        return DeconstructedGen(parseInt(_type), parseInt(_asset), parseInt(_rarity), parseInt(_stat), parseInt(_transferible));
    }

    function parseInt(string memory _a)
        public
        pure
        returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((uint8(bresult[i]) >= 48)&&(uint8(bresult[i]) <= 57)){                
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint8(bresult[i]) == 46) decimals = true;
        }
        return mint;
    }
    
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
        ) public pure returns (string memory){
        bytes memory tempBytes;
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return string(tempBytes);
    }

}

