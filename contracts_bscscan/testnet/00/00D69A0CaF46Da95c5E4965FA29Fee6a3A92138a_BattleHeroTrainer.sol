// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./shared/BattleHeroData.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHero.sol";
import "./shared/DateTime.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * BattleHeroTrainer
 * This contract controls the training of the heroes and their weapons. 
 * In it you can receive PE that, these can be exchanged for BATH  
 */
contract BattleHeroTrainer is DateTime{
    enum Type{
        CHARACTER, 
        WEAPON
    }
    struct TrainPair{
        uint256 character;
        uint256 weapon;        
    }
    struct Training{
        uint[][] pairs;
        uint timestamp;
        uint blockNumber;
        bool exists;
    }
    uint8 public constant pe_decimals = 18;
    uint256 public constant PE_ESCALE = 1 * 10 ** uint256(pe_decimals);
    uint256 public TRAINING_LOCK_TIME = 8600;
    address owner;
    mapping(address => Training) trainings;
    mapping(address => uint256) pe;
    mapping(address => uint256) extraSlots;
    mapping(uint256 => bool) tokenIdTraining;
    BattleHeroData battleHeroData;
    IBattleHeroFactory erc721;
    IBattleHero erc20;
    uint256 MIN_SLOTS  = 3;
    uint256 MAX_SLOTS  = 30;
    uint256 SLOT_PRICE = 500000000000000000;
    using SafeMath for uint256;

    constructor(address bHeroData, address erc721address, address erc20address){            
        owner = msg.sender;
        setBattleHeroData(bHeroData);
        setERC721(erc721address);
        setERC20(erc20address);
    }

    /**
     * @dev Set new contract address for BattleHeroData.
     *
     * Requirements:
     * - `battleHeroDataAddress` cannot be the zero address.     
     * - `sender` is owner
     */
    function setBattleHeroData(address battleHeroDataAddress) public {
        require(msg.sender == owner);
        require(battleHeroDataAddress != address(0));
        battleHeroData = BattleHeroData(battleHeroDataAddress);
    }

    /**
     * @dev Set new contract address for BattleHeroFactory.
     *
     * Requirements:
     * - `battleHeroFactoryAddress` cannot be the zero address.     
     * - `sender` is owner
     */
    function setERC721(address battleHeroFactoryAddress) public {
        require(msg.sender == owner);
        require(battleHeroFactoryAddress != address(0));
        erc721 = IBattleHeroFactory(battleHeroFactoryAddress);
    }

    /**
     * @dev Set new contract address for BattleHero.
     *
     * Requirements:
     * - `battleHeroAddress` cannot be the zero address.     
     * - `sender` is owner
     */
    function setERC20(address battleHeroAddress) public {
        require(msg.sender == owner);
        require(battleHeroAddress != address(0));
        erc20 = IBattleHero(battleHeroAddress);
    }

    /**
     * @dev Modifier for check if contracts are setup
     */
    modifier isSetup() {
        require(address(battleHeroData) != address(0), "Setup not correctly");        
        require(address(erc721) != address(0), "Setup not correctly");        
        require(address(erc20) != address(0), "Setup not correctly");        
        _;
    }

    /**
     * @dev Check if tokenId is weapon or not    
     */
    function isWeapon(uint256 tokenId) public view returns (bool){
        IBattleHeroFactory.Hero memory hero = erc721.heroeOfId(tokenId);
        BattleHeroData.DeconstructedGen memory deconstructed = battleHeroData.deconstructGen(hero.genetic);                        
        return deconstructed._type > 49;
    }

    /**
     * @dev Return current training
     */
    function currentTraining(address _owner) public view returns(Training memory){
        return trainings[_owner];
    }

    /**
     * @dev Buy new train slot
     */
    function buySlot() isSetup public returns(bool){
        require(erc20.balanceOf(msg.sender) >= SLOT_PRICE, "Insufficient BATH balance");
        erc20.burnFrom(msg.sender, SLOT_PRICE);
        extraSlots[msg.sender] = extraSlots[msg.sender].add(1);
        return true;
    }

    /**
     * @dev Return slots for `_owner`
     */
    function getSlots(address _owner) public view returns(uint256){
        uint256 _extraSlots = 0;
        if(extraSlots[_owner] > 0){
                _extraSlots = extraSlots[_owner];
        }
        uint256 _totalExtraSlots = _extraSlots;
        return _totalExtraSlots + MIN_SLOTS;
    }
    
    /**
     * @dev Check if is owner of tokenId
     */
    function isOwner(uint256 tokenId, address _owner) public view returns(bool){
            return erc721.ownerOf(tokenId) == _owner;
    }

    /**
     * @dev Set `pairs` of character <-> weapon to train
     * 
     * Requirements: 
     * - have more slots than pairs length
     * - can not set same weapon or same character twice
     * - index 0 of pair should be character and index 1 of pair should be weapon
     * - check if is owner
     * - check if is currently training
     */
    function train(uint[][] calldata pairs) isSetup public{
        uint256 slots = getSlots(msg.sender);      
        uint256 l     = pairs.length;      
        require(pairs.length <= slots, "Buy more slots");
            for(uint i = 0; i <= l - 1; i++){
                require(tokenIdTraining[pairs[i][1]] != true, "You are setting same weapon twice");
                require(tokenIdTraining[pairs[i][0]] != true, "You are setting same character twice");
                require(isWeapon(pairs[i][1]) == true, "Not a weapon");
                require(isWeapon(pairs[i][0]) == false, "Not a character");
                require(isOwner(pairs[i][1], msg.sender) == true, "You are not owner");
                require(isOwner(pairs[i][0], msg.sender) == true, "You are not owner");                
                tokenIdTraining[pairs[i][1]] = true;
                tokenIdTraining[pairs[i][0]] = true;
            }
        require(trainings[msg.sender].exists != true, "Currently training");        
        trainings[msg.sender] = Training(pairs, block.timestamp, block.number, true);
    }

    /**
     * Do calculation for training pairs
     */
    function calculateTrainingReward(uint[][] calldata pairs) public view returns(uint){            
        return rewardPerTrain(Training(pairs, 0, 0, true));
    }

    /**
     * Cancel current train
     */
    function cancelTrain() public {
        Training memory training = trainings[msg.sender];
        cleanTokenIds(training.pairs);
        delete trainings[msg.sender];    
    }

    /**
     * Claim train
     * Requirements: 
     * - Should pass 24 hours from training start
     */
    function claimTrain() isSetup public {
        Training memory training = trainings[msg.sender];
        uint timestamp           = training.timestamp;     
        uint currentTimestamp    = block.timestamp;
        uint timestampDiff       = currentTimestamp - timestamp;
        if(msg.sender != owner){
            require(timestampDiff >= TRAINING_LOCK_TIME, "You need to wait");
        }
        uint256 reward = rewardPerTrain(training);
        pe[msg.sender] = pe[msg.sender].add(reward);
        cleanTokenIds(training.pairs);
        delete trainings[msg.sender];        
    }

    /**
     * Clean training token ids. Internal use
     */
    function cleanTokenIds(uint[][] memory pairs) internal{
        for(uint i = 0; i <= pairs.length - 1; i++){
                tokenIdTraining[pairs[i][1]] = false;
                tokenIdTraining[pairs[i][0]] = false;
        }
    }

    /**
     * Return balance of PE
     */
    function balanceOfPe(address _owner) public view returns(uint256){
            return pe[_owner];
    }

    /**
     * Calculate reward per training
     */
    function rewardPerTrain(Training memory training) public view returns(uint256){
        uint256 reward = 0;
        uint256 pairsLength = training.pairs.length;
        for(uint256 i = 0; i <= pairsLength - 1; i++){
                uint256 characterId = training.pairs[i][0];
                BattleHeroData.DeconstructedGen memory characterDeconstructed = battleHeroData.deconstructGen(erc721.heroeOfId(characterId).genetic);        
                BattleHeroData.TrainingLevel memory trainingLevelCharacter = battleHeroData.getTrainingLevel(characterDeconstructed._rarity);

                uint256 weaponId = training.pairs[i][1];
                BattleHeroData.DeconstructedGen memory weaponDeconstructed = battleHeroData.deconstructGen(erc721.heroeOfId(weaponId).genetic);        
                BattleHeroData.TrainingLevel memory trainingLevelWeapon = battleHeroData.getTrainingLevel(weaponDeconstructed._rarity);
                        
                uint r = ((((trainingLevelWeapon.level * (trainingLevelWeapon.pct)) + (trainingLevelCharacter.level * (trainingLevelCharacter.pct)))) * PE_ESCALE) / 100;
                reward = reward.add(r);             
        }
        return reward;
    }
}

pragma solidity ^0.8.0;


contract BattleHeroData { 

    struct Rarity{
        uint256 min;
        uint256 max;
        string rarity;        
    }

    struct AssetType{
        uint256 min;
        uint256 max;
        string assetType;
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
    }

    uint minStat = 6;

    Rarity[] rarities;
    AssetType[] assetTypes;    
    
    constructor(){
        rarities.push(Rarity(0   , 4993, "COMMON"));
        rarities.push(Rarity(4994, 8139, "LOW RARE"));
        rarities.push(Rarity(8140, 9611, "RARE"));
        rarities.push(Rarity(9612, 9953, "EPIC"));
        rarities.push(Rarity(9954, 9984, "LEGEND"));
        rarities.push(Rarity(9985, 9999, "MITIC"));

        assetTypes.push(AssetType(0 , 49, "CHARACTER"));
        assetTypes.push(AssetType(50, 99, "WEAPON"));
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
        // Weapon or Character
        string memory _type   = slice(bytes(gen), bytes(gen).length - 2, 2);
        // Which weapon or which character
        string memory _asset  = slice(bytes(gen), bytes(gen).length - 4, 2);
        // Rarity
        string memory _rarity = slice(bytes(gen), bytes(gen).length - 8, 4);
        
        string memory _stat   = slice(bytes(gen), bytes(gen).length - 12, 2);

        return DeconstructedGen(parseInt(_type), parseInt(_asset), parseInt(_rarity), parseInt(_stat));
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

pragma solidity ^0.8.0;

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

pragma solidity ^0.8.0;

contract IBattleHero{
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {}
    function balanceOf(address account) public view virtual returns (uint256) {}
    function allowance(address owner, address spender) public view virtual returns (uint256) {}
    function burn(uint256 amount) public virtual {}
    function burnFrom(address account, uint256 amount) public virtual {}
}

pragma solidity ^0.8.0;

import "./BattleHeroData.sol";

contract IBattleHeroFactory{
    struct Hero{
        address owner;
        string genetic;
        uint bornAt;
        uint256 index;
        bool exists;
        BattleHeroData.DeconstructedGen deconstructed;
    }
    function transferFrom(address from, address buyer, uint256 numTokens) public{}
    function balanceOf(address tokenOwner) public view returns (uint256) {}
    function burn(uint256 _value) public{}
    function allowance(address from, address delegate) public view returns (uint) {}
    function burnFrom(address from, uint256 numTokens) public returns (bool) {}
    function heroeOfId(uint256 tokenId) public view returns(Hero memory) { }
    function ownerOf(uint256 tokenId) public view virtual returns (address) { }
    function mint(address to, string memory genes) public virtual returns(uint){ }
    function isApproved(address to, uint256 tokenId) public view returns (bool){}
    function lockHero(uint256 tokenId ) public{}
    function unlockHero(uint256 tokenId) public {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

