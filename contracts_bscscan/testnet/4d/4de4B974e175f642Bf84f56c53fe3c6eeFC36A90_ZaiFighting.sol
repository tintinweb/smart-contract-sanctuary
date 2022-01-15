// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces.sol";

contract ZaiFighting is Ownable, ERC721Holder {
    using SafeMath for uint256;

    IAddresses public gameAddresses;
    IERC20 public BZAI;

    constructor(address _BZAI){
        BZAI = IERC20(_BZAI);
    }

    // Monster powers
    struct Powers {
        uint256 water;
        uint256 fire;
        uint256 metal;
        uint256 air;
        uint256 stone;
    }

    uint256[4] public staminaRegenerationDuration = [600,480,360,180]; // in seconds

    uint256 public xpRewardByFight = 200;

    mapping(uint256 => uint256) _fighterStamina;
    mapping(uint256 => uint256) _firstOf5FightTimestamp;

    mapping(uint256 => uint256) public monsterTotalWins;
    mapping(uint256 => uint256) public monsterTotalDraw;
    mapping(uint256 => uint256) public monsterTotalLoss;
    mapping(uint256 => uint256) public monsterTotalFights;

    mapping(uint256 => uint256) public monsterTotalRandomSelected;

    modifier onlyAuth() {
        require(
            gameAddresses.isAuthToManagedNFTs(msg.sender),
             "!Auth");
        _;
    }

    modifier canUseMonster(uint256 _monsterId){
        require(
            IBandZaiNFT(gameAddresses.getMonsterAddress()).ownerOf(_monsterId) == msg.sender ||
            IDelegate(gameAddresses.getDelegateMonsterAddress()).gotDelegationForMonster(_monsterId)
            , "Not your monster nor delegate");
        _;
    }

    function setGameAddresses(address _address) external onlyOwner {
        gameAddresses = IAddresses(_address);
    }

    function setRegenerationDuration(uint256[4] memory _durations) external onlyOwner{
        require(
            _durations[0] <= 1000 &&
            _durations[1] <= 1000 &&
            _durations[2] <= 1000 &&
            _durations[3] <= 1000,
            "excessive durations"
            );
        staminaRegenerationDuration[0] = _durations[0];
        staminaRegenerationDuration[1] = _durations[1];
        staminaRegenerationDuration[2] = _durations[2];
        staminaRegenerationDuration[3] = _durations[3];
    }

    function setXpRewardByFight(uint256 _xp) external onlyOwner{
        xpRewardByFight = _xp;
    }

    function getFighterStamina(uint256 _monsterId) external view returns(uint256){
        (uint256 result, ) = _getFighterStamina(_monsterId);
        return result;
    }

    function _hasEnoughStamina(uint256 _monsterId) internal view returns(bool){
        (uint256 result, ) = _getFighterStamina(_monsterId);
        if(result>0){
            return true;
        }else{
            return false;
        }
    }

    function _getFighterStamina(uint256 _monsterId) internal view returns(uint256 stamina,uint256 added){
        uint256 _result;
        uint256 _added;
        uint256 _monsterState = IBandZaiNFT(gameAddresses.getMonsterAddress()).getMonsterState(_monsterId);
        // if no fight return max stamina : 5
        if(_firstOf5FightTimestamp[_monsterId] == 0){
            _result = 5;
        }else {
            // take the old variable
            _result = _fighterStamina[_monsterId];
            // calculate time passed since the last fight
            uint256 _timeSinceLastFight = block.timestamp.sub(_firstOf5FightTimestamp[_monsterId]);
            // if there is > 1 stamina duration
            if(_timeSinceLastFight >= staminaRegenerationDuration[_monsterState]){
                // calculate number of stamina to add no need modulo cause in solidity 100 / 60 = 1
                _added = _timeSinceLastFight.div(staminaRegenerationDuration[_monsterState]);
                // max stamina is 5
                if(_result.add(_added) >= 5){
                    _result = 5;
                }else{
                    _result = _result.add(_added);
                }           
            } 
        }
        return (_result, _added);
    }

    function _updateStamina(uint256 _monsterId) internal {
        uint256 _monsterState = IBandZaiNFT(gameAddresses.getMonsterAddress()).getMonsterState(_monsterId);
        //reload 
        (uint256 stamina, uint256 added)= _getFighterStamina(_monsterId);
        _fighterStamina[_monsterId] = stamina;
        
        if(stamina == 5){
           _firstOf5FightTimestamp[_monsterId] = block.timestamp; 
        }else{
           _firstOf5FightTimestamp[_monsterId] = _firstOf5FightTimestamp[_monsterId].add(added.mul(staminaRegenerationDuration[_monsterState]));
        }
        // reduce stamina counter
        _fighterStamina[_monsterId] = _fighterStamina[_monsterId].sub(1);
    }

    // _powersType (0: water ; 1: fire ; 2:metal ; 3:air ; 4:stone)
    function initFighting(
        uint256 _monsterId,
        uint256[9] memory _powersType,
        uint256[9] memory _powers,
        uint256[] memory _usedPotions 
        )
        external canUseMonster(_monsterId)
        returns(
            uint256[21] memory result //[0: challengerId,1:myScore, 2:challengerScore, 3-11: PowerTypeByRound, 12-20: PowerUseByRound ]
            ){

        require(_hasEnoughStamina(_monsterId), "Your Monster is exhausted !");
        _updateStamina(_monsterId);

        require(
            _isPowersUsedCorrect(
                _getMonsterPowersByType(_monsterId,_usedPotions),
                _getUsedPowersByType(_powersType,_powers)
            ),"Trying to use more power than had");

        // update stamina
        require(IRanking(gameAddresses.getRankingContract()).updatePlayerRankings(msg.sender));

        IBandZaiNFT IMonster = IBandZaiNFT(gameAddresses.getMonsterAddress());
        IPotions Potions = IPotions(gameAddresses.getPotionAddress());

        uint256[21] memory _toReturn;
        (uint256 monsterLevel, , , , , ) = IMonster.getMonster(_monsterId);

        (uint256 _challengerId, bool _isSameLevel) = 
            ILevelStorage(
                gameAddresses.getLevelStorageAddress())
                .getRandomMonsterFromLevel(monsterLevel);

        _toReturn[0] = _challengerId;

        uint256[20] memory _randoms = _generateRandomDatas(IMonster.ownerOf(_challengerId));
        uint256[5] memory _cPowers = _getchallengerPowers(_challengerId, IMonster, Potions, _usedPotions,_randoms[0]);

        // if not same level, add 3 random pts
        if(!_isSameLevel){
            _cPowers[_randoms[1].mod(5)] = _cPowers[_randoms[0].mod(5)].add(1);
            _cPowers[_randoms[2].mod(5)] = _cPowers[_randoms[1].mod(5)].add(1);
            _cPowers[_randoms[3].mod(5)] = _cPowers[_randoms[2].mod(5)].add(1);
        }

        _toReturn = _getChallengerPattern(_randoms,_cPowers, _toReturn); 

        for(uint256 i = 0 ; i < 9 ; i++){
            if(_winTheRound(_powersType[i],_toReturn[i+3]) == 1){
                _toReturn[1] = _toReturn[1].add(_powers[i]); // My score
            }else if(_winTheRound(_powersType[i],_toReturn[i+3]) == 0){
                _toReturn[2] = _toReturn[2].add(_toReturn[i+12]); //challenger score
            }else if(_winTheRound(_powersType[i],_toReturn[i+3]) == 2){ // draw round (player who have the more point score the difference between)
                if(_powers[i] >= _toReturn[i+12]){
                    _toReturn[1] = _toReturn[1].add(_powers[i].sub(_toReturn[i+12]));
                }else{
                    _toReturn[2] = _toReturn[2].add(_toReturn[i+12].sub(_powers[i]));
                }

            }
        }

        require(_updateCounterWinLoss(_monsterId,_toReturn,_usedPotions,_powers));
        
        return(_toReturn);
    }

    function _getXpToWin(
        uint256[] memory _usedPotions,
        uint256 _monsterId,
        uint256[9] memory _powers)
         internal view returns(uint256){

        uint256 _xp = xpRewardByFight;

        uint256[5] memory powers = _getMonsterPowersByType(_monsterId,_usedPotions);
        uint256 _totalPowers = powers[0].add(powers[1]).add(powers[2]).add(powers[3]).add(powers[4]);
        uint256 _totalUsedPowers;
        for(uint256 i=0 ; i<9 ;i++){
            _totalUsedPowers = _totalUsedPowers.add(_powers[i]);
        }
        _xp = _xp.div(2);
        uint256 _ratio = _xp.div(_totalPowers);
        uint256 _toReduce = _ratio.mul(_totalUsedPowers);
        _xp = _xp.sub(_toReduce);

        if(_usedPotions.length>0){
          for(uint256 i = 0; i < _usedPotions.length; i++){
            uint256[6] memory _potionPowers = IPotions(gameAddresses.getPotionAddress()).getPotionPowers(_usedPotions[i]);
            if(_potionPowers[5] > 0){
                _xp = _xp.add(_potionPowers[5].mul(xpRewardByFight));
            }
          }
        }
        return _xp;
    }

    function _getchallengerPowers(
        uint256 _monsterId,
        IBandZaiNFT IMonster, 
        IPotions Potions, 
        uint256[] memory _usedPotions, 
        uint256 _random) 
        internal returns(uint256[5] memory){
        ( , , , , ,uint256[5] memory _result) = IMonster.getMonster(_monsterId);

        if(_usedPotions.length >= 0){
            for(uint256 i = 0 ; i < _usedPotions.length ; i++){
                Potions.transferFrom(msg.sender,address(this),_usedPotions[i]);
            }
            if(_random.mod(_usedPotions.length) > 0){
                for(uint256 i = 0 ; i < _random.mod(_usedPotions.length); i++){
                    uint256 _index = Potions.tokenOfOwnerByIndex(address(this),_random.mod(Potions.balanceOf(address(this))));
                    uint256[6] memory _potionPowers= Potions.getPotionPowers(_index);
                    Potions.burnPotion(_index);
                    for(uint256 j= 0 ; i<5 ; j++){
                        _result[j] = _result[j].add(_potionPowers[j]);
                    }
                }
            }
        }
        return _result;
    }

    function _updateCounterWinLoss(
        uint256 _monsterId,
        uint256[21] memory _toReturn,
        uint256[] memory _usedPotions,
        uint256[9] memory _powers ) internal returns(bool result){
        monsterTotalFights[_monsterId] = monsterTotalFights[_monsterId].add(1);
        monsterTotalFights[_toReturn[0]] = monsterTotalFights[_toReturn[0]].add(1);
        monsterTotalRandomSelected[_toReturn[0]] = monsterTotalRandomSelected[_toReturn[0]].add(1);

        IBandZaiNFT IMonster = IBandZaiNFT(gameAddresses.getMonsterAddress());
        address _owner = IMonster.ownerOf(_monsterId);

        if(_toReturn[1] > _toReturn[2]){

            monsterTotalWins[_monsterId] = monsterTotalWins[_monsterId].add(1);
            IMonster.updateXp(_monsterId,_getXpToWin(_usedPotions,_monsterId,_powers));
            uint256 _reward = IRewardsWinningFound(gameAddresses.getWinRewardsAddress()).getWinningRewards();

            if(IDelegate(gameAddresses.getDelegateMonsterAddress()).isMonsterDelegated(_monsterId)){
                (address _scholarAddress,,,,uint256 percentageForScholar,) = 
                    IDelegate(gameAddresses.getDelegateMonsterAddress()).getDelegateDatasByMonster(_monsterId);
                
                uint256 _scholarRevenu = _reward.mul(percentageForScholar).div(100);
                uint256 _ownerRevenu = _reward.sub(_scholarRevenu);
                require(BZAI.transfer(_owner, _ownerRevenu));
                return(BZAI.transfer(_scholarAddress, _scholarRevenu));
            } else{
                return(BZAI.transfer(_owner, _reward));
            }

        }else if(_toReturn[1] == _toReturn[2]){
            monsterTotalDraw[_monsterId] = monsterTotalDraw[_monsterId].add(1);
            return true;
        }else if(_toReturn[2] > _toReturn[1]){
            monsterTotalLoss[_monsterId] = monsterTotalLoss[_monsterId].add(1);
            return true;
        }
    }

    function _getChallengerPattern(
        uint256[20] memory _randoms,
        uint256[5] memory _cPowers,
        uint256[21] memory _toReturn
        ) 
        internal pure returns(
            uint256[21] memory result
        ){
            // get a random order like [8,5,3,7,6,1,2,4,0]
            // allows a true random distribution of challenger powers. (not only big hit at begining of fight)
            uint8[9] memory randomOrder = _getRandomOrder(_randoms); 

            for(uint8 i = 0 ; i < 9 ; i++){

                // random type of power
                uint256 _powerType = _randoms[i+4].mod(5);
                // define _toReturn [3 to 11] type of power (fire, water...) 
                uint256 _typeIndex = randomOrder[i]+3;
                // _toReturn [12 to 20] are amount point hit from challenger
                uint256 _powerIndex = randomOrder[i]+12;
                // apply power
                _toReturn[_typeIndex] = _powerType;

                // apply a power points amount only if challenger got more than 0 point in his type of power
                if(_cPowers[_powerType] > 0){
                    // generate random points between 0 to value of challenger points got in this type of power 
                    uint256 _points = _randoms[i+5].mod(_cPowers[_powerType]);
                    // apply points
                    _toReturn[_powerIndex] = _points;   
                    // substrate those points from power points . for not using 2 times the amount of point  
                    _cPowers[_powerType] = _cPowers[_powerType].sub(_points);

                }else{
                    _toReturn[_typeIndex] = 5; // 5 is code for non power hit 
                    _toReturn[_powerIndex] = 0;                 
                }
            }
            return (_toReturn);
    }

    function _getRandomOrder(uint256[20] memory _randoms) internal pure returns(uint8[9]memory){
            uint8[9] memory randomOrder = [0,1,2,3,4,5,6,7,8];
            for(uint256 r = 9 ; r>0 ; r--){
                uint256 randomIndex = _randoms[r].mod(9);
                uint8 _temp = randomOrder[r];
                randomOrder[r] = randomOrder[randomIndex];
                randomOrder[randomIndex] =_temp;
            }
            return randomOrder;
    }

    function _winTheRound(uint256 _myHit, uint256 _challengerHit) internal pure returns(uint8){
        uint8 _result;
        if(
            _myHit == 0 && _challengerHit == 1 ||
            _myHit == 0 && _challengerHit == 2){
                _result = 1;
            } else if(
                _myHit == 1 && _challengerHit == 2 ||
                _myHit == 1 && _challengerHit == 3){
                   _result = 1;
            } else if(
                _myHit == 2 && _challengerHit == 3 ||
                _myHit == 2 && _challengerHit == 4){
                   _result = 1;
            } else if(
                _myHit == 3 && _challengerHit == 4 ||
                _myHit == 3 && _challengerHit == 0){
                   _result = 1;
            } else if(
                _myHit == 4 && _challengerHit == 0 ||
                _myHit == 4 && _challengerHit == 1){
                   _result = 1;
            } else if(_myHit != 5 && _challengerHit == 5){
                    _result = 1;
            } else if(_myHit == _challengerHit){
                _result = 2;
            }else{
                _result = 0;
            }
        return _result;
    }

    function _isPowersUsedCorrect(uint256[5] memory _got, uint256[5] memory _used ) internal pure returns(bool){
        bool _result;
        if(
            _got[0] >= _used[0] &&
            _got[1] >= _used[1] &&
            _got[2] >= _used[2] &&
            _got[3] >= _used[3] &&
            _got[4] >= _used[4] 
            ){
                _result = true;
            }
        return _result;
    }

    function _getUsedPowersByType(uint256[9] memory _powersType,uint256[9] memory _powers)internal pure returns(uint256[5] memory){
        uint256[5] memory usedPowers;
        for(uint256 i = 0 ; i<9 ; i++){
            require(_powersType[i] <= 5, "Power not valid");
            usedPowers[_powersType[i]] = usedPowers[_powersType[i]].add(_powers[i]);
        }
        return usedPowers;
    }

    function _getMonsterPowersByType(uint256 _monsterId,uint256[] memory _potions) internal view returns(uint256[5] memory){
        ( , , , , ,uint256[5] memory _powers) = IBandZaiNFT(gameAddresses.getMonsterAddress()).getMonster(_monsterId);

        for (uint256 i = 0 ; i < _potions.length ; i++){
            uint256[6] memory _potionPowers = IPotions(gameAddresses.getPotionAddress()).getPotionPowers(_potions[i]);
            _powers[0] = _powers[0].add(_potionPowers[0]);
            _powers[1] = _powers[1].add(_potionPowers[1]);
            _powers[2] = _powers[2].add(_potionPowers[2]);
            _powers[3] = _powers[3].add(_potionPowers[3]);
            _powers[4] = _powers[4].add(_potionPowers[4]);
        }
        return _powers;
    }

    // utils

    function _generateRandomDatas(address _user) private returns (uint256[20] memory) {
        uint256 r = IOracle(gameAddresses.getOracleAddress()).getRandom(keccak256(abi.encodePacked(_user,BZAI.balanceOf(address(this)))));
        uint256 [20] memory randoms;
        uint256 _mult = 1000;
        for (uint256 i = 0; i < 20; i++){
            randoms[i] = uint256(r / _mult); 
            _mult = _mult.mul(10);
        }
        return(randoms);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IOracle {
    function getRandom(bytes32 _id) external returns (uint256);
}

interface IBandZaiNFT is IERC721Enumerable {
    function mintMonster(address _to,string memory _name,uint256 _state,string memory _ipfsPath,bytes memory _signature) external returns (uint256);
   
    function updateMonster(uint256 _id,uint256 _attack,uint256 _defense,uint256 _xp) external returns (uint256);

    function burnMonster(uint256 _tokenId) external;

    function getMonsterState(uint256 _tokenId) external view returns (uint256);
    
    function duplicateMonsterStats(uint256 _tokenId)external returns (uint256 _newItemId);

    function updateStatus(uint256 _tokenId, uint256 _newStatusID, uint256 _center) external;

    function updateXp(uint256 _id,uint256 _xp) external returns (uint256 level);

    function updateAttackAndDefense(uint256 _id,uint256 _attack,uint256 _defense) external;

    function isFree(uint256 _tokenId) external view returns(bool);

    function updateAlchemyXp(uint256 _tokenId, uint256 _xpRaised) external;

    function getMonster(uint256 _tokenId)external view returns (
            uint256 level,
            uint256 xp,
            uint256 alchemyXp,
            string memory state,
            string memory URI,
            uint256[5] memory powers 
        );
    
}

interface ILaboratory is IERC721Enumerable{
    function mintLaboratory(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;
}

interface ITraining is IERC721Enumerable{
    function mintTrainingCenter(address _to) external returns (uint256);

    function burnTrainingCenter(uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;
}

interface INursery is IERC721Enumerable{
    function mintNursery(address _to, uint256 _bronzePrice, uint256 _silverPrice, uint256 _goldPrice, uint256 _platinumPrice) external returns (uint256);

    function burnNursery(uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;
}

interface IStaking {
    function receiveFees(uint256 _amount) external;
}

interface IBZAIToken {
    function burnToken(uint256 _amount) external;
}

interface IPayments {
    function payOwner(address _owner, uint256 _value) external returns(bool);

    function distributeFees(uint256 _amount) external returns(bool);
}

interface IEggs is IERC721Enumerable{

    function mintEgg(address _to,uint256 _state,uint256 _maturityDuration) external returns (uint256);

    function burnEgg(uint256 _tokenId) external returns(bool);

    function isMature(uint256 _tokenId) external view returns(bool);

    function getStateIndex(uint256 _tokenId) external view returns (uint256);
}

interface IPotions is IERC721Enumerable{
    function mintPotion(uint256 _fromLab,uint256 _price,uint256 _type, uint256 _power) external returns (uint256);

    function updatePotion(uint256 _tokenId) external; 

    function burnPotion(uint256 _tokenId) external returns(bool);

    function getPotion(uint256 _tokenId) external view returns(address seller, uint256 price, uint256 fromLab);

    function getPotionPowers(uint256 _tokenId) external view returns(uint256[6] memory);

    function buyPotion(address _to, uint256 _type) external returns (uint256);
}

interface IAddresses {
    function getBZAIAddress() external view returns(address);

    function getOracleAddress() external view returns(address);

    function getStakingAddress() external view returns(address); 

    function getMonsterAddress() external view returns(address);

    function getLaboratoryAddress() external view returns(address);

    function getTrainingCenterAddress() external view returns(address);

    function getNurseryAddress() external view returns(address);

    function getPotionAddress() external view returns(address);

    function getTeamAddress() external view returns(address);

    function getGameAddress() external view returns(address);

    function getEggsAddress() external view returns(address);

    function getLotteryAddress() external view returns(address);

    function getPaymentsAddress() external view returns(address);

    function getChallengeRewardsAddress() external view returns(address);

    function getWinRewardsAddress() external view returns(address);

    function getOpenAndCloseAddress() external view returns(address);

    function getAlchemyAddress() external view returns(address);

    function getChickenAddress() external view returns(address);

    function getReserveChallengeAddress() external view returns(address);

    function getReserveWinAddress() external view returns(address);

    function getWinChallengeAddress() external view returns(address);

    function isAuthToManagedNFTs(address _address) external view returns(bool);

    function isAuthToManagedPayments(address _address) external view returns(bool);

    function getLevelStorageAddress() external view returns(address);

    function getRankingContract() external view returns(address);

    function getAuthorizedSigner() external view returns(address);

    function getDelegateMonsterAddress() external view returns(address);
}

interface IOpenAndClose {

    function getLaboCreatingTime(uint256 _tokenId) external view returns(uint256);

    function getNurseryCreatingTime(uint256 _tokenId) external view returns(uint256);

    function canLaboSell(uint256 _tokenId) external view returns (bool);

    function canTrain(uint256 _tokenId) external view returns (bool);

    function canNurserySell(uint256 _tokenId) external view returns (bool);
}

interface IReserveForChalengeRewards {
    function getNextUpdateTimestamp() external view returns(uint256);

    function getRewardFinished() external view returns(bool);

    function updateRewards() external returns(bool);
}

interface IReserveForWinRewards {
    function getNextUpdateTimestamp() external view returns(uint256);

    function getRewardFinished() external view returns(bool);

    function updateRewards() external returns(bool);
}

interface ILevelStorage {
     function addFighter(uint256 _level, uint256 _monsterId) external returns(bool);

     function removeFighter(uint256 _level, uint256 _monsterId) external returns (bool);

     function getLevelLength(uint256 _level) external view returns(uint256);
     
     function getRandomMonsterFromLevel(uint256 _level) external returns(uint256 _monsterId, bool _isLevelRequired);
}

interface IRewardsRankingFound {
    function getDailyRewards() external returns(uint256);

    function getWeeklyRewards() external returns(uint256);
}

interface IRewardsWinningFound {
    function getWinningRewards() external returns(uint256);
}

interface IRanking {
    function updatePlayerRankings(address _user) external returns(bool);
}

interface IDelegate {
    function gotDelegationForMonster(uint256 _monsterId) external view returns(bool);

    function getDelegateDatasByMonster(uint256 _monsterId) external view returns(
        address scholarAddress,
        address monsterOwner,
        uint256 contractDuration,
        uint256 contractEnd,
        uint256 percentageForScholar,
        uint256 lastScholarPlayed
        );

    function isMonsterDelegated(uint256 _monsterId) external view returns(bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}