// SPDX-License-Identifier: UNLICENSED
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IPeaNFT.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

contract PeaCombat is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum CombatResult {
        LOSE,
        WIN
    }

    enum Monster {
        CANAL, // 80%
        GRAVE, // 60%
        SAVAGE, // 40%
        MAGMA, // 20%
        DRAGON, // 20%
        BARON // 20%
    }

    event CombatEvent(
        uint256 indexed tokenId,
        Monster monster,
        address user,
        CombatResult result
    );

    struct CombatSession {
        uint256 tokenId;
        Monster monster;
        CombatResult result;
        uint256 time;
    }
    uint256[8] private seeds;
    uint256 private seeders;
    bytes32 private seedKey;

    IERC20 public peaToken;
    IPeaNFT public peaNFT;

    uint256 public timeLimitCombat = 24 hours;
    uint256[6] public limitCombat = [2, 4, 6, 8, 10, 15];
    uint256[6] public rewardBonus = [50, 50, 50, 50, 50, 50];
    uint256[6] public baseRewardMonster = [100, 200, 300, 400, 500, 600];
    bool public paused;

    mapping(uint256 => uint256[]) public combatSessionsTime;
    mapping(address => CombatSession[]) public combatSessions;

    constructor(IERC20 _peaToken, address _peaNFT) {
        peaToken = _peaToken;
        peaNFT = IPeaNFT(_peaNFT);
    }

    function combatTimes(uint256 _tokenId) public view returns (uint256) {
        return combatSessionsTime[_tokenId].length;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setTimeLimitCombat(uint256 _timeLimitCombat) public onlyOwner {
        timeLimitCombat = _timeLimitCombat;
    }

    function setLimitCombat(uint256[6] memory _limitCombat) public onlyOwner {
        limitCombat = _limitCombat;
    }

    function setRewardBonus(uint256[6] memory _rewardBonus) public onlyOwner {
        rewardBonus = _rewardBonus;
    }

    function setBaseReward(uint256[6] memory _baseRewardMonster)
        public
        onlyOwner
    {
        baseRewardMonster = _baseRewardMonster;
    }

    function generateRandom() public {
        seeders++;
        for (uint256 index = 0; index < 8; index++) {
            bytes32 _bytes32 = keccak256(
                abi.encodePacked(
                    block.timestamp - (index + seeders),
                    index + seeders
                )
            );
            seeds[index] = _random(uint256(_bytes32), 8);
        }
    }

    function getRandom(uint256 _any, uint256 _length)
        internal
        view
        returns (uint256)
    {
        uint256 index = uint8(
            _random(uint256(keccak256(abi.encode(_any, seedKey))), _length)
        );
        while (index >= 8) {
            index /= 2;
        }
        return
            _random(
                uint256(keccak256(abi.encode(seeds[index], seedKey))),
                _length
            );
    }

    function combatReward(
        uint256 _winRate,
        uint8 _peaLevel,
        uint256 _monsterLevel
    ) private view returns (uint256) {
        uint256 bonusPercentage = rewardBonus[_peaLevel - 1];
        uint256 baseReward = baseRewardMonster[_monsterLevel];

        return
            (
                baseReward
                    .add(uint256(100).sub(_winRate))
                    .mul(bonusPercentage + 100)
                    .div(100)
            ) * 10**18;
    }

    function getWinRate(uint256 _level, uint256 _monsterLevel, uint256 winRateRnd)
        private
        pure
        returns (uint256)
    {
        uint256 _monsterRate = _monsterLevel == 0 ? 80 
                            : (_monsterLevel == 1 ? 70
                            : (_monsterLevel == 2 ? 60
                            : (_monsterLevel == 3 ? 50
                            : (_monsterLevel == 4 ? 40
                            : (_monsterLevel == 5 ? 30 : 30
                            )))));

        uint256 _lvRate = _level == 0 ? 20 
                       : (_level == 1 ? 30
                       : (_level == 2 ? 40
                       : (_level == 3 ? 50
                       : (_level == 4 ? 85
                       : (_level == 5 ? 95 : 20
                       )))));

        return winRateRnd.add(_monsterRate.add(_lvRate).div(2));
    }

    function nextTimeToCombat(uint256 _tokenId, uint256 _peaLevel)
        public
        view
        returns (uint256)
    {
        uint256[] storage sessions = combatSessionsTime[_tokenId];
        uint256 limit = limitCombat[_peaLevel];
        uint256 times = sessions.length;
        uint256 waitTime = 0;

        if (times >= limit) {
            uint256 afterTime = sessions[times - limit].add(timeLimitCombat);
            if (afterTime > block.timestamp) {
                waitTime = afterTime.sub(block.timestamp);
            }
        }
        return waitTime;
    }

    function combat(uint256 _tokenId, Monster _monster) external {
        require(!paused, "Combat is paused");
        require(peaToken.balanceOf(address(this)) > 0, "No reward");

        require(peaNFT.ownerOf(_tokenId) == _msgSender(), "not own");
        if (Address.isContract(_msgSender()) || _msgSender() != tx.origin) {
            revert("not accept here");
        }

        IPeaNFT.Pean memory _pean = peaNFT.getPean(_tokenId);
        uint8 peaChamp = uint8(_pean.champ);
        uint8 peaLevel = uint8(_pean.level);

        require(peaChamp > 0, "require champ, not a gem");
        if (nextTimeToCombat(_tokenId, peaLevel) > 0) {
            revert("wait to next turn");
        }

        CombatResult result = CombatResult.LOSE;
        uint256 monsterLevel = uint256(_monster);
        uint256 rnd = getRandom(_tokenId.add(monsterLevel), 4).div(100);
        uint256 winRate = getWinRate(uint256(peaLevel), monsterLevel, rnd.div(10));

        if (rnd < winRate) {
            result = CombatResult.WIN;
            uint256 reward = combatReward(winRate, peaLevel, monsterLevel);
            safeReward(_msgSender(), reward);
        }

        combatSessionsTime[_tokenId].push(block.timestamp);

        combatSessions[_msgSender()].push(
            CombatSession({
                tokenId: _tokenId,
                monster: _monster,
                result: result,
                time: block.timestamp
            })
        );
        generateRandom();
        emit CombatEvent(_tokenId, _monster, _msgSender(), result);
    }

    function safeReward(address _receiver, uint256 _amount) internal {
        uint256 balance = peaToken.balanceOf(address(this));
        // console.log("receiver %s reward %s", _receiver, _amount);
        if (balance > 0) {
            if (balance >= _amount) {
                peaToken.transfer(_receiver, _amount);
            } else {
                peaToken.transfer(_receiver, balance);
            }
        }
    }

    function safuToken(address _receiver, uint256 _amount) public onlyOwner {
        uint256 balance = peaToken.balanceOf(address(this));
        // console.log("receiver %s reward %s", _receiver, _amount);
        if (balance > 0) {
            if (balance >= _amount) {
                peaToken.transfer(_receiver, _amount);
            } else {
                peaToken.transfer(_receiver, balance);
            }
        }
    }

    function userCombats(address _user) public view returns (uint256) {
        return combatSessions[_user].length;
    }

    function _random(uint256 _id, uint256 _length)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        (block.timestamp - block.number),
                        _id,
                        _length,
                        uint256(keccak256(abi.encodePacked(block.coinbase))),
                        (uint256(keccak256(abi.encodePacked(msg.sender))))
                    )
                )
            ) % (10**_length);
    }
}