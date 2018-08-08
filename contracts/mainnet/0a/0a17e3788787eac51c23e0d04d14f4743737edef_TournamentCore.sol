pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
   @title ERC827 interface, an extension of ERC20 token standard

   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

contract AccessControl {
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress || 
            msg.sender == ceoAddress || 
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

interface RandomInterface {

  function maxRandom() public returns (uint256 randomNumber);

  function random(uint256 _upper) public returns (uint256 randomNumber);

  function randomNext(uint256 _seed, uint256 _upper) public pure returns(uint256, uint256);
}

contract PlayerInterface {
    function checkOwner(address _owner, uint32[11] _ids) public view returns (bool);
    function queryPlayerType(uint32[11] _ids) public view returns (uint32[11] playerTypes);
    function queryPlayer(uint32 _id) public view returns (uint16[8]);
    function queryPlayerUnAwakeSkillIds(uint32[11] _playerIds) public view returns (uint16[11] playerUnAwakeSkillIds);
    function tournamentResult(uint32[3][11][32] _playerAwakeSkills) public;
}

/// @title TournamentBase contract for BS.
contract TournamentBase {

    event Enter(address user, uint256 fee, uint8 defenceCount, uint8 midfieldCount, uint8 forwardCount, uint32[11] playerIds);
    event CancelEnter(address user);
    event StartCompetition(uint256 id, uint256 time, address[32] users);
    event CancelCompetition(uint256 id);
    event Sponsor(address user, uint256 competitionId, address target, uint256 fee);
    
    event Ball(uint256 competitionId, uint8 gameIndex, address user, uint32 playerId, uint8 time);
    event Battle(uint256 competitionId, uint8 gameIndex, address userA, uint8 scoreA, address userB, uint8 scoreB);
    event Champion(uint256 competitionId, address user);
    event EndCompetition(uint256 competitionId, uint256 totalReward, uint256 totalWeight, uint8[32] teamWinCounts);

    event Reward(uint256 competitionId, address target, uint8 winCount, address user, uint256 sponsorAmount, uint256 amount);

    uint256 public minEnterFee = 100*(10**18);
    //uint256 public constant sponsorInterval = 1 hours;
    uint32[5] public operatingCosts = [100, 100, 120, 160, 240];

    struct Team {
      uint256 fees;
      uint32[11] playerIds;
      uint16[11] playerAtkWeights;
      uint128 index;
      TeamStatus status;
      uint16 attack;
      uint16 defense;
      uint16 stamina;
    }

    enum TeamStatus { Normal, Enter, Competition }
    enum PlayerPosType { GoalKeeper, Defence, Midfield, Forward }
    enum CompetitionStatus { None, Start, End, Cancel }

    struct SponsorsInfo {
        mapping(address => uint256) sponsors;
        uint256 totalAmount;
    }

    struct CompetitionInfo {
        uint256 totalReward;
        uint256 totalWeight;
        uint8[32] teamWinCounts;
        address[32] users;
        //uint64 startTime;
        CompetitionStatus status;
        uint8 userCount;
    }

    mapping (address => Team) public userToTeam;
    address[] teamUserInfo;

    uint256 nextCompetitionId;
    mapping (uint256 => CompetitionInfo) public competitionInfos;
    mapping (uint256 => mapping (uint256 => SponsorsInfo)) public sponsorInfos;

    PlayerInterface bsCoreContract;
    RandomInterface randomContract;
    ERC827 public joyTokenContract;
}

contract PlayerSkill {
    enum SkillType { Undefined, WinGamesInOneTournament, ScoreInOneGame, ScoreInOneTournament, 
        FanOfPlayerID, ChampionWithPlayerID, HattricksInOneTuournament, Terminator,
        LonelyKiller, VictoryBringer, Saver, ICanDoBetterTournament, ICanDoBetter, 
        LearnFromFailure, LearnFromFailureTournament}

    struct SkillConfig {
        SkillType skillType;
        uint32 target;
        uint8 addAttri;
    }

    function _getSkill(uint16 skillId) internal pure returns(uint16, uint16) {
        return (skillId >> 2, (skillId & 0x03));
    }

    function triggerSkill(uint32[11][32] _playerIds, uint8[32] _teamWinCounts, uint8[4][31] _gameScores,
            uint8[3][3][31] _gameBalls, uint8[5][11][32] _playerBalls, uint16[11][32] _playerUnAwakeSkillIds,
            uint32[3][11][32] _playerAwakeSkills) internal pure {

        SkillConfig[35] memory skillConfigs = _getSkillConfigs();
        for (uint8 i = 0; i < 32; i++) {
            for (uint8 j = 0; j < 11; j++) {
                uint16 skillId = _playerUnAwakeSkillIds[i][j];
                if (skillId > 0) {
                    uint16 addAttriType;
                    (skillId, addAttriType) = _getSkill(skillId);
                    SkillConfig memory skillConfig = skillConfigs[skillId];

                    if (skillConfig.skillType != SkillType.Undefined) {
                        if (_triggerSkill(skillConfig, i, j, _teamWinCounts, _gameScores, _gameBalls, _playerBalls)){
                            _playerAwakeSkills[i][j][0] = _playerIds[i][j];
                            _playerAwakeSkills[i][j][1] = addAttriType;
                            _playerAwakeSkills[i][j][2] = skillConfig.addAttri;
                        }
                    }
                }
            }
        }
    }

    function _getSkillConfigs() internal pure returns(SkillConfig[35]) {
        return [
            SkillConfig(SkillType.Undefined, 0, 0),
            SkillConfig(SkillType.WinGamesInOneTournament,1,1),
            SkillConfig(SkillType.WinGamesInOneTournament,2,2),
            SkillConfig(SkillType.WinGamesInOneTournament,3,3),
            SkillConfig(SkillType.WinGamesInOneTournament,4,4),
            SkillConfig(SkillType.WinGamesInOneTournament,5,5),
            SkillConfig(SkillType.ScoreInOneGame,1,1),
            SkillConfig(SkillType.ScoreInOneGame,2,3),
            SkillConfig(SkillType.ScoreInOneGame,3,5),
            SkillConfig(SkillType.ScoreInOneGame,4,7),
            SkillConfig(SkillType.ScoreInOneGame,5,10),
            SkillConfig(SkillType.ScoreInOneTournament,10,3),
            SkillConfig(SkillType.ScoreInOneTournament,13,4),
            SkillConfig(SkillType.ScoreInOneTournament,16,5),
            SkillConfig(SkillType.ScoreInOneTournament,20,8),
            SkillConfig(SkillType.VictoryBringer,1,4),
            SkillConfig(SkillType.VictoryBringer,3,6),
            SkillConfig(SkillType.VictoryBringer,5,8),
            SkillConfig(SkillType.Saver,1,5),
            SkillConfig(SkillType.Saver,3,7),
            SkillConfig(SkillType.Saver,5,10),
            SkillConfig(SkillType.HattricksInOneTuournament,1,3),
            SkillConfig(SkillType.HattricksInOneTuournament,3,6),
            SkillConfig(SkillType.HattricksInOneTuournament,5,10),
            SkillConfig(SkillType.Terminator,1,5),
            SkillConfig(SkillType.Terminator,3,8),
            SkillConfig(SkillType.Terminator,5,12),
            SkillConfig(SkillType.LonelyKiller,1,5),
            SkillConfig(SkillType.LonelyKiller,3,7),
            SkillConfig(SkillType.LonelyKiller,5,10),
            SkillConfig(SkillType.ICanDoBetterTournament,15,0),
            SkillConfig(SkillType.ICanDoBetter,5,0),
            SkillConfig(SkillType.LearnFromFailure,5,5),
            SkillConfig(SkillType.LearnFromFailureTournament,15,8),
            SkillConfig(SkillType.ChampionWithPlayerID,0,5)
        ];
    }

    function _triggerSkill(SkillConfig memory _skillConfig, uint8 _teamIndex, uint8 _playerIndex,
            uint8[32] _teamWinCounts, uint8[4][31] _gameScores, uint8[3][3][31] _gameBalls,
            uint8[5][11][32] _playerBalls) internal pure returns(bool) {

        uint256 i;
        uint256 accumulateValue = 0;
        if (SkillType.WinGamesInOneTournament == _skillConfig.skillType) {
            return _teamWinCounts[_teamIndex] >= _skillConfig.target;
        }

        if (SkillType.ScoreInOneGame == _skillConfig.skillType) {
            for (i = 0; i < 5; i++) {
                if (_playerBalls[_teamIndex][_playerIndex][i] >= _skillConfig.target) {
                    return true;
                }
            }
            return false;
        }

        if (SkillType.ScoreInOneTournament == _skillConfig.skillType) {
            for (i = 0; i < 5; i++) {
                accumulateValue += _playerBalls[_teamIndex][_playerIndex][i];
            }
            return accumulateValue >= _skillConfig.target;
        }


/*         if (SkillType.ChampionWithPlayerID == _skillConfig.skillType) {
            if (_teamWinCounts[_teamIndex] >= 5) {
                for (i = 0; i < 11; i++) {
                    if (_playerIds[i] == _skillConfig.target) {
                        return true;
                    }
                }
            }
            return false;
        } */

        if (SkillType.HattricksInOneTuournament == _skillConfig.skillType) {
            for (i = 0; i < 5; i++) {
                if (_playerBalls[_teamIndex][_playerIndex][i] >= 3) {
                    accumulateValue++;
                }
            }

            return accumulateValue >= _skillConfig.target;
        }

        if (SkillType.Terminator == _skillConfig.skillType) {
            for (i = 0; i < 31; i++) {
                if ((_gameScores[i][0] == _teamIndex && _gameScores[i][2] == _gameScores[i][3]+1)
                    || (_gameScores[i][1] == _teamIndex && _gameScores[i][2]+1 == _gameScores[i][3])) {
                    if (_gameBalls[i][2][1] == _teamIndex && _gameBalls[i][2][2] == _playerIndex) {
                        accumulateValue++;
                    }
                }
            }

            return accumulateValue >= _skillConfig.target;
        }

        if (SkillType.LonelyKiller == _skillConfig.skillType) {
            for (i = 0; i < 31; i++) {
                if ((_gameScores[i][0] == _teamIndex && _gameScores[i][2] == 1 && _gameScores[i][3] == 0)
                    || (_gameScores[i][1] == _teamIndex && _gameScores[i][2] == 0 && _gameScores[i][3] == 1)) {
                    if (_gameBalls[i][2][1] == _teamIndex && _gameBalls[i][2][2] == _playerIndex) {
                        accumulateValue++;
                    }
                }
            }

            return accumulateValue >= _skillConfig.target;
        }

        if (SkillType.VictoryBringer == _skillConfig.skillType) {
            for (i = 0; i < 31; i++) {
                if ((_gameScores[i][0] == _teamIndex && _gameScores[i][2] > _gameScores[i][3])
                    || (_gameScores[i][1] == _teamIndex && _gameScores[i][2] < _gameScores[i][3])) {
                    if (_gameBalls[i][0][1] == _teamIndex && _gameBalls[i][0][2] == _playerIndex) {
                        accumulateValue++;
                    }
                }
            }

            return accumulateValue >= _skillConfig.target;
        }

        if (SkillType.Saver == _skillConfig.skillType) {
            for (i = 0; i < 31; i++) {
                if (_gameBalls[i][1][1] == _teamIndex && _gameBalls[i][1][2] == _playerIndex) {
                    accumulateValue++;
                }
            }
            return accumulateValue >= _skillConfig.target;
        }

        if (SkillType.ICanDoBetterTournament == _skillConfig.skillType) {
            for (i = 0; i < 31; i++) {
                if (_gameScores[i][0] == _teamIndex) {
                    accumulateValue += _gameScores[i][3];
                }

                if (_gameScores[i][1] == _teamIndex) {
                    accumulateValue += _gameScores[i][2];
                }
            }
            return accumulateValue >= _skillConfig.target;
        }

        if (SkillType.ICanDoBetter == _skillConfig.skillType) {
            for (i = 0; i < 31; i++) {
                if ((_gameScores[i][0] == _teamIndex && _gameScores[i][3] >= _skillConfig.target)
                    || (_gameScores[i][1] == _teamIndex && _gameScores[i][2] >= _skillConfig.target)) {
                    return true;
                }
            }
            return false;
        }

        if (SkillType.LearnFromFailure == _skillConfig.skillType && _teamIndex == 0) {
            for (i = 0; i < 31; i++) {
                if ((_gameScores[i][0] == _teamIndex && _gameScores[i][3] >= _skillConfig.target)
                    || (_gameScores[i][1] == _teamIndex && _gameScores[i][2] >= _skillConfig.target)) {
                    return true;
                }
            }
            return false;
        }

        if (SkillType.LearnFromFailureTournament == _skillConfig.skillType && _teamIndex == 0) {
            for (i = 0; i < 31; i++) {
                if (_gameScores[i][0] == _teamIndex) {
                    accumulateValue += _gameScores[i][3];
                }

                if (_gameScores[i][1] == _teamIndex) {
                    accumulateValue += _gameScores[i][2];
                }
            }
            return accumulateValue >= _skillConfig.target;
        }
    }
}

contract TournamentCompetition is TournamentBase, PlayerSkill {

    uint256 constant rangeParam = 90;
    uint256 constant halfBattleMinutes = 45;
    uint256 constant minBattleMinutes = 2;

    struct BattleTeam {
        uint16[11] playerAtkWeights;
        uint16 attack;
        uint16 defense;
        uint16 stamina;
    }
    struct BattleInfo {
        uint256 competitionId;
        uint256 seed;
        uint256 maxRangeA;
        uint256 maxRangeB;
        uint8[32] teamIndexs;
        BattleTeam[32] teamInfos;
        uint32[11][32] allPlayerIds;
        address addressA;
        address addressB;
        uint8 roundIndex;
        uint8 gameIndex;
        uint8 teamLength;
        uint8 indexA;
        uint8 indexB;
    }

    function competition(uint256 _competitionId, CompetitionInfo storage ci, uint8[32] _teamWinCounts, uint32[3][11][32] _playerAwakeSkills) internal {
        uint8[4][31] memory gameScores;
        uint8[3][3][31] memory gameBalls;
        uint8[5][11][32] memory playerBalls;
        uint16[11][32] memory playerUnAwakeSkillIds;

        BattleInfo memory battleInfo;
        battleInfo.competitionId = _competitionId;
        battleInfo.seed = randomContract.maxRandom();
        battleInfo.teamLength = uint8(ci.userCount);
        for (uint8 i = 0; i < battleInfo.teamLength; i++) {
            battleInfo.teamIndexs[i] = i;
        }

        _queryBattleInfo(ci, battleInfo, playerUnAwakeSkillIds);
        while (battleInfo.teamLength > 1) {
            _battle(ci, battleInfo, gameScores, gameBalls, playerBalls);
            for (i = 0; i < battleInfo.teamLength; i++) {
                _teamWinCounts[battleInfo.teamIndexs[i]] += 1;
            }
        }
        address winner = ci.users[battleInfo.teamIndexs[0]];
        Champion(_competitionId, winner);

        triggerSkill(battleInfo.allPlayerIds, _teamWinCounts, gameScores, 
            gameBalls, playerBalls, playerUnAwakeSkillIds, _playerAwakeSkills);
    }

    function _queryBattleInfo(CompetitionInfo storage ci, BattleInfo memory _battleInfo, uint16[11][32] memory _playerUnAwakeSkillIds) internal view {
        for (uint8 i = 0; i < _battleInfo.teamLength; i++) {

            Team storage team = userToTeam[ci.users[i]];
            _battleInfo.allPlayerIds[i] = team.playerIds;

            _battleInfo.teamInfos[i].playerAtkWeights = team.playerAtkWeights;
            _battleInfo.teamInfos[i].attack = team.attack;
            _battleInfo.teamInfos[i].defense = team.defense;
            _battleInfo.teamInfos[i].stamina = team.stamina;

            _playerUnAwakeSkillIds[i] = bsCoreContract.queryPlayerUnAwakeSkillIds(_battleInfo.allPlayerIds[i]);

            // uint256[3] memory teamAttrs;
            // (teamAttrs, _battleInfo.teamInfos[i].playerAtkWeights) = _calTeamAttribute(ci.users[i], team.defenceCount, team.midfieldCount, team.forwardCount, _battleInfo.allPlayerIds[i]);   

            // _battleInfo.teamInfos[i].attack = uint16(teamAttrs[0]);
            // _battleInfo.teamInfos[i].defense = uint16(teamAttrs[1]);
            // _battleInfo.teamInfos[i].stamina = uint16(teamAttrs[2]);
        }
    }

    function _battle(CompetitionInfo storage _ci, BattleInfo _battleInfo, uint8[4][31] _gameScores,
            uint8[3][3][31] _gameBalls, uint8[5][11][32] _playerBalls) internal {
        uint8 resultTeamLength = 0;
        for (uint8 i = 0; i < _battleInfo.teamLength; i+=2) {
            uint8 a = _battleInfo.teamIndexs[i];
            uint8 b = _battleInfo.teamIndexs[i+1];
            uint8 scoreA;
            uint8 scoreB;
            _battleInfo.indexA = a;
            _battleInfo.indexB = b;
            _battleInfo.addressA = _ci.users[a];
            _battleInfo.addressB = _ci.users[b];
            (scoreA, scoreB) = _battleTeam(_battleInfo, _gameScores, _gameBalls, _playerBalls);
            if (scoreA > scoreB) {
                _battleInfo.teamIndexs[resultTeamLength++] = a;
            } else {
                _battleInfo.teamIndexs[resultTeamLength++] = b;
            }
            Battle(_battleInfo.competitionId, _battleInfo.gameIndex, _battleInfo.addressA, scoreA, _battleInfo.addressB, scoreB);
        }

        _battleInfo.roundIndex++;
        _battleInfo.teamLength = resultTeamLength;
    }

    function _battleTeam(BattleInfo _battleInfo, uint8[4][31] _gameScores, uint8[3][3][31] _gameBalls, 
            uint8[5][11][32] _playerBalls) internal returns (uint8 scoreA, uint8 scoreB) {
        BattleTeam memory _aTeam = _battleInfo.teamInfos[_battleInfo.indexA];
        BattleTeam memory _bTeam = _battleInfo.teamInfos[_battleInfo.indexB];
        _battleInfo.maxRangeA = 5 + rangeParam*_bTeam.defense/_aTeam.attack;
        _battleInfo.maxRangeB = 5 + rangeParam*_aTeam.defense/_bTeam.attack;
        //DebugRange(_a, _b, _aTeam.attack, _aTeam.defense, _aTeam.stamina, _bTeam.attack, _bTeam.defense, _bTeam.stamina, maxRangeA, maxRangeB);
        //DebugRange2(maxRangeA, maxRangeB);
        _battleScore(_battleInfo, 0, _playerBalls, _gameBalls);

        _battleInfo.maxRangeA = 5 + rangeParam*(uint256(_bTeam.defense)*uint256(_bTeam.stamina)*(100+uint256(_aTeam.stamina)))/(uint256(_aTeam.attack)*uint256(_aTeam.stamina)*(100+uint256(_bTeam.stamina)));
        _battleInfo.maxRangeB = 5 + rangeParam*(uint256(_aTeam.defense)*uint256(_aTeam.stamina)*(100+uint256(_bTeam.stamina)))/(uint256(_bTeam.attack)*uint256(_bTeam.stamina)*(100+uint256(_aTeam.stamina)));
        //DebugRange2(maxRangeA, maxRangeB);
        _battleScore(_battleInfo, halfBattleMinutes, _playerBalls, _gameBalls);

        uint8 i = 0;
        for (i = 0; i < 11; i++) {
            scoreA += _playerBalls[_battleInfo.indexA][i][_battleInfo.roundIndex];
            scoreB += _playerBalls[_battleInfo.indexB][i][_battleInfo.roundIndex];
        }
        if (scoreA == scoreB) {
            _battleInfo.maxRangeA = 5 + rangeParam * (uint256(_bTeam.defense)*uint256(_bTeam.stamina)*uint256(_bTeam.stamina)*(100+uint256(_aTeam.stamina))*(100+uint256(_aTeam.stamina)))/(uint256(_aTeam.attack)*uint256(_aTeam.stamina)*uint256(_aTeam.stamina)*(100+uint256(_bTeam.stamina))*(100+uint256(_bTeam.stamina)));
            _battleInfo.maxRangeB = 5 + rangeParam * (uint256(_aTeam.defense)*uint256(_aTeam.stamina)*uint256(_aTeam.stamina)*(100+uint256(_bTeam.stamina))*(100+uint256(_bTeam.stamina)))/(uint256(_bTeam.attack)*uint256(_bTeam.stamina)*uint256(_bTeam.stamina)*(100+uint256(_aTeam.stamina))*(100+uint256(_aTeam.stamina)));
            //DebugRange2(maxRangeA, maxRangeB);
            (scoreA, scoreB) = _battleOvertimeScore(_battleInfo, scoreA, scoreB, _playerBalls, _gameBalls);
        }

        _gameScores[_battleInfo.gameIndex][0] = _battleInfo.indexA;
        _gameScores[_battleInfo.gameIndex][1] = _battleInfo.indexB;
        _gameScores[_battleInfo.gameIndex][2] = scoreA;
        _gameScores[_battleInfo.gameIndex][3] = scoreB;
        _battleInfo.gameIndex++;
    }

    function _battleScore(BattleInfo _battleInfo, uint256 _timeoffset, uint8[5][11][32] _playerBalls, uint8[3][3][31] _gameBalls) internal {
        uint256 _battleMinutes = 0;
        while (_battleMinutes < halfBattleMinutes - minBattleMinutes) {
            bool isAWin;
            uint256 scoreTime;
            uint8 index;
            (isAWin, scoreTime) = _battleOneScore(_battleInfo);
            _battleMinutes += scoreTime;
            if (_battleMinutes <= halfBattleMinutes) {
                uint8 teamIndex;
                address addressWin;

                if (isAWin) {
                    teamIndex = _battleInfo.indexA;
                    addressWin = _battleInfo.addressA;
                } else {
                    teamIndex = _battleInfo.indexB;
                    addressWin = _battleInfo.addressB;
                }

                (_battleInfo.seed, index) = _randBall(_battleInfo.seed, _battleInfo.teamInfos[teamIndex].playerAtkWeights);
                uint32 playerId = _battleInfo.allPlayerIds[teamIndex][index];
                Ball(_battleInfo.competitionId, _battleInfo.gameIndex+1, addressWin, playerId, uint8(_timeoffset+_battleMinutes));
                _playerBalls[teamIndex][index][_battleInfo.roundIndex]++;
                _onBall(_battleInfo.gameIndex, teamIndex, index, uint8(_timeoffset+_battleMinutes), _gameBalls);
            }
        }
    }

    function _battleOneScore(BattleInfo _battleInfo) internal view returns(bool, uint256) {
        uint256 tA;
        (_battleInfo.seed, tA) = randomContract.randomNext(_battleInfo.seed, _battleInfo.maxRangeA-minBattleMinutes+1);
        tA += minBattleMinutes;
        uint256 tB;
        (_battleInfo.seed, tB) = randomContract.randomNext(_battleInfo.seed, _battleInfo.maxRangeB-minBattleMinutes+1);
        tB += minBattleMinutes;
        if (tA < tB || (tA == tB && _battleInfo.seed % 2 == 0)) {
           return (true, tA);
        } else {
           return (false, tB);
        }
    }

    function _randBall(uint256 _seed, uint16[11] memory _atkWeight) internal view returns(uint256, uint8) {
        uint256 rand;
        (_seed, rand) = randomContract.randomNext(_seed, _atkWeight[_atkWeight.length-1]);
        rand += 1;
        for (uint8 i = 0; i < _atkWeight.length; i++) {
            if (_atkWeight[i] >= rand) {
                return (_seed, i);
            }
        }
    }

    function _onBall(uint8 _gameIndex, uint8 _teamIndex, uint8 _playerIndex, uint8 _time, uint8[3][3][31] _gameBalls) internal pure {
        if (_gameBalls[_gameIndex][0][0] == 0) {
            _gameBalls[_gameIndex][0][0] = _time;
            _gameBalls[_gameIndex][0][1] = _teamIndex;
            _gameBalls[_gameIndex][0][2] = _playerIndex;
        }

        _gameBalls[_gameIndex][2][0] = _time;
        _gameBalls[_gameIndex][2][1] = _teamIndex;
        _gameBalls[_gameIndex][2][2] = _playerIndex;
    }

    function _onOverTimeBall(uint8 _gameIndex, uint8 _teamIndex, uint8 _playerIndex, uint8 _time, uint8[3][3][31] _gameBalls) internal pure {
        _gameBalls[_gameIndex][1][0] = _time;
        _gameBalls[_gameIndex][1][1] = _teamIndex;
        _gameBalls[_gameIndex][1][2] = _playerIndex;
    }

    function _battleOvertimeScore(BattleInfo _battleInfo, uint8 _scoreA, uint8 _scoreB,
            uint8[5][11][32] _playerBalls, uint8[3][3][31] _gameBalls) internal returns(uint8 scoreA, uint8 scoreB) {
        bool isAWin;
        uint8 index;
        uint256 scoreTime;
        (isAWin, scoreTime) = _battleOneScore(_battleInfo);
        scoreTime = scoreTime % 30 + 90;
        uint8 teamIndex;
        address addressWin;
        if (isAWin) {
            teamIndex = _battleInfo.indexA;
            scoreA = _scoreA + 1;
            scoreB = _scoreB;

            addressWin = _battleInfo.addressA;
        } else {
            teamIndex = _battleInfo.indexB;
            scoreA = _scoreA;
            scoreB = _scoreB + 1;

            addressWin = _battleInfo.addressB;
        }

        (_battleInfo.seed, index) = _randBall(_battleInfo.seed, _battleInfo.teamInfos[teamIndex].playerAtkWeights);
        uint32 playerId = _battleInfo.allPlayerIds[teamIndex][index];
        Ball(_battleInfo.competitionId, _battleInfo.gameIndex+1, addressWin, playerId, uint8(scoreTime));
        _playerBalls[teamIndex][index][_battleInfo.roundIndex]++;

        _onBall(_battleInfo.gameIndex, teamIndex, index, uint8(scoreTime), _gameBalls);
        _onOverTimeBall(_battleInfo.gameIndex, teamIndex, index, uint8(scoreTime), _gameBalls);
    }
}

contract TournamentInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isTournament() public pure returns (bool);
    function isPlayerIdle(address _owner, uint256 _playerId) public view returns (bool);
}

/// @title Tournament contract for BS.
contract TournamentCore is TournamentInterface, TournamentCompetition, AccessControl {

    using SafeMath for uint256;
    function TournamentCore(address _joyTokenContract, address _bsCoreContract, address _randomAddress, address _CFOAddress) public {

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        cfoAddress = _CFOAddress;

        randomContract = RandomInterface(_randomAddress);

        joyTokenContract = ERC827(_joyTokenContract);
        bsCoreContract = PlayerInterface(_bsCoreContract);

        nextCompetitionId = 1;
    }

    function isTournament() public pure returns (bool) {
        return true;
    }

    function setMinEnterFee(uint256 minFee) external onlyCEO {
        minEnterFee = minFee;
    }

    function setOperatingCost(uint32[5] costs) external onlyCEO {
        operatingCosts = costs;
    }

    function getOperationCost(uint256 teamCount) public view returns (uint256) {
        uint256 cost = 0;
        if (teamCount <= 2) {
            cost = operatingCosts[0];
        } else if(teamCount <= 4) {
            cost = operatingCosts[1];
        } else if(teamCount <= 8) {
            cost = operatingCosts[2];
        } else if(teamCount <= 16) {
            cost = operatingCosts[3];
        } else {
            cost = operatingCosts[4];
        }
        return cost.mul(10**18);
    }

    function isPlayerIdle(address _owner, uint256 _playerId) public view returns (bool) {
        Team storage teamInfo = userToTeam[_owner];
        for (uint256 i = 0; i < teamInfo.playerIds.length; i++) {
            if (teamInfo.playerIds[i] == _playerId) {
                return false;
            }
        }

        return true;
    }

    function enter(address _sender, uint256 _fees, uint8 _defenceCount, uint8 _midfieldCount, uint8 _forwardCount,
            uint32[11] _playerIds) external whenNotPaused {
        require(_fees >= minEnterFee);
        require(_playerIds.length == 11);
        require(_defenceCount >= 1 && _defenceCount <= 5);
        require(_midfieldCount >= 1 && _midfieldCount <= 5);
        require(_forwardCount >= 1 && _forwardCount <= 5);
        require(_defenceCount + _midfieldCount + _forwardCount == 10);

        require(msg.sender == address(joyTokenContract) || msg.sender == _sender);

        require(joyTokenContract.transferFrom(_sender, address(this), _fees));

        uint32[11] memory ids = _playerIds;
        _insertSortMemory(ids);
        for (uint256 i = 0; i < 11 - 1; i++) {
            require(ids[i] < ids[i + 1]);
        }

        require(bsCoreContract.checkOwner(_sender, _playerIds));
        uint32[11] memory playerTypes = bsCoreContract.queryPlayerType(_playerIds);
        _insertSortMemory(playerTypes);
        for (i = 0; i < 11 - 1; i++) {
            if (playerTypes[i] > 0) {
                break;
            }
        }
        for (; i < 11 - 1; i++) {
            require(playerTypes[i] < playerTypes[i + 1]);
        }

        Team storage teamInfo = userToTeam[_sender];
        require(teamInfo.status == TeamStatus.Normal);
        enterInner(_sender, _fees, _defenceCount, _midfieldCount, _forwardCount, _playerIds, teamInfo);

        Enter(_sender, _fees, _defenceCount, _midfieldCount, _forwardCount, _playerIds);
    }

    function cancelEnter(address _user) external onlyCOO {
        Team storage teamInfo = userToTeam[_user];
        require(teamInfo.status == TeamStatus.Enter);
        uint256 fees = teamInfo.fees;
        uint128 index = teamInfo.index;
        require(teamUserInfo[index-1] == _user);
        if (index < teamUserInfo.length) {
            address user = teamUserInfo[teamUserInfo.length-1];
            teamUserInfo[index-1] = user;
            userToTeam[user].index = index;
        }
        teamUserInfo.length--;
        delete userToTeam[_user];

        require(joyTokenContract.transfer(_user, fees));
        CancelEnter(_user);
    }

    function cancelAllEnter() external onlyCOO {
        for (uint256 i = 0; i < teamUserInfo.length; i++) {
            address user = teamUserInfo[i];
            Team storage teamInfo = userToTeam[user];
            require(teamInfo.status == TeamStatus.Enter);
            uint256 fees = teamInfo.fees;

            // uint256 index = teamInfo.index;
            // require(teamUserInfo[index-1] == user);

            delete userToTeam[user];

            require(joyTokenContract.transfer(user, fees));
            CancelEnter(user);
        }
        teamUserInfo.length = 0;
    }

    function enterInner(address _sender, uint256 _value, uint8 _defenceCount, uint8 _midfieldCount, uint8 _forwardCount,
        uint32[11] _playerIds, Team storage _teamInfo) internal {

        uint16[11] memory playerAtkWeights;
        uint256[3] memory teamAttrs;
        (teamAttrs, playerAtkWeights) = _calTeamAttribute(_defenceCount, _midfieldCount, _forwardCount, _playerIds);
        uint256 teamIdx = teamUserInfo.length++;
        teamUserInfo[teamIdx] = _sender;
        _teamInfo.status = TeamStatus.Enter;

        require((teamIdx + 1) == uint256(uint128(teamIdx + 1)));
        _teamInfo.index = uint128(teamIdx + 1);

        _teamInfo.attack = uint16(teamAttrs[0]);
        _teamInfo.defense = uint16(teamAttrs[1]);
        _teamInfo.stamina = uint16(teamAttrs[2]);

        _teamInfo.playerIds = _playerIds;
        _teamInfo.playerAtkWeights = playerAtkWeights;

        _teamInfo.fees = _value;
    }

    function getTeamAttribute(uint8 _defenceCount, uint8 _midfieldCount, uint8 _forwardCount,
        uint32[11] _playerIds) external view returns (uint256 attack, uint256 defense, uint256 stamina) {
        uint256[3] memory teamAttrs;
        uint16[11] memory playerAtkWeights;
        (teamAttrs, playerAtkWeights) = _calTeamAttribute(_defenceCount, _midfieldCount, _forwardCount, _playerIds);
        attack = teamAttrs[0];
        defense = teamAttrs[1];
        stamina = teamAttrs[2];
    }

    function _calTeamAttribute(uint8 _defenceCount, uint8 _midfieldCount, uint8 _forwardCount,
        uint32[11] _playerIds) internal view returns (uint256[3] _attrs, uint16[11] _playerAtkWeights) {

        uint256[3][11] memory playerAttrs;

        _getAttribute(_playerIds, 0, PlayerPosType.GoalKeeper, 1, 0, playerAttrs);
        uint8 startIndex = 1;
        uint8 i;
        for (i = startIndex; i < startIndex + _defenceCount; i++) {
            _getAttribute(_playerIds, i, PlayerPosType.Defence, _defenceCount, i - startIndex, playerAttrs);
        }
        startIndex = startIndex + _defenceCount;
        for (i = startIndex; i < startIndex + _midfieldCount; i++) {
            _getAttribute(_playerIds, i, PlayerPosType.Midfield, _midfieldCount, i - startIndex, playerAttrs);
        }
        startIndex = startIndex + _midfieldCount;
        for (i = startIndex; i < startIndex + _forwardCount; i++) {
            _getAttribute(_playerIds, i, PlayerPosType.Forward, _forwardCount, i - startIndex, playerAttrs);
        }

        uint16 lastAtkWeight = 0;
        for (i = 0; i < _playerIds.length; i++) {
            _attrs[0] += playerAttrs[i][0];
            _attrs[1] += playerAttrs[i][1];
            _attrs[2] += playerAttrs[i][2];
            _playerAtkWeights[i] = uint16(lastAtkWeight + playerAttrs[i][0] / 10000);
            lastAtkWeight = _playerAtkWeights[i];
        }

        _attrs[0] /= 10000;
        _attrs[1] /= 10000;
        _attrs[2] /= 10000;
    }

    function _getAttribute(uint32[11] _playerIds, uint8 _i, PlayerPosType _type, uint8 _typeSize, uint8 _typeIndex, uint256[3][11] playerAttrs)
    internal view {
        uint8 xPos;
        uint8 yPos;
        (xPos, yPos) = _getPos(_type, _typeSize, _typeIndex);

        uint16[8] memory a = bsCoreContract.queryPlayer(_playerIds[_i]);
        uint256 aWeight;
        uint256 dWeight;
        (aWeight, dWeight) = _getWeight(yPos);
        uint256 sWeight = 100 - aWeight - dWeight;
        if (_type == PlayerPosType.GoalKeeper && a[5] == 1) {
            dWeight += dWeight;
        }
        uint256 xWeight = 50;
        if (xPos + 1 >= a[4] && xPos <= a[4] + 1) {
            xWeight = 100;
        }
        playerAttrs[_i][0] = (a[1] * aWeight * xWeight);
        playerAttrs[_i][1] = (a[2] * dWeight * xWeight);
        playerAttrs[_i][2] = (a[3] * sWeight * xWeight);
    }

    function _getWeight(uint256 yPos) internal pure returns (uint256, uint256) {
        if (yPos == 0) {
            return (5, 90);
        }
        if (yPos == 1) {
            return (10, 80);
        }
        if (yPos == 2) {
            return (10, 70);
        }
        if (yPos == 3) {
            return (10, 60);
        }
        if (yPos == 4) {
            return (20, 30);
        }
        if (yPos == 5) {
            return (20, 20);
        }
        if (yPos == 6) {
            return (30, 20);
        }
        if (yPos == 7) {
            return (60, 10);
        }
        if (yPos == 8) {
            return (70, 10);
        }
        if (yPos == 9) {
            return (80, 10);
        }
    }

    function _getPos(PlayerPosType _type, uint8 _size, uint8 _index) internal pure returns (uint8, uint8) {
        uint8 yPosOffset = 0;
        if (_type == PlayerPosType.GoalKeeper) {
            return (3, 0);
        }
        if (_type == PlayerPosType.Midfield) {
            yPosOffset += 3;
        }
        if (_type == PlayerPosType.Forward) {
            yPosOffset += 6;
        }
        if (_size == 5) {
            if (_index == 0) {
                return (0, 2 + yPosOffset);
            }
            if (_index == 1) {
                return (2, 2 + yPosOffset);
            }
            if (_index == 2) {
                return (4, 2 + yPosOffset);
            }
            if (_index == 3) {
                return (6, 2 + yPosOffset);
            } else {
                return (3, 3 + yPosOffset);
            }
        }
        if (_size == 4) {
            if (_index == 0) {
                return (0, 2 + yPosOffset);
            }
            if (_index == 1) {
                return (2, 2 + yPosOffset);
            }
            if (_index == 2) {
                return (4, 2 + yPosOffset);
            } else {
                return (6, 2 + yPosOffset);
            }
        }
        if (_size == 3) {
            if (_index == 0) {
                return (1, 2 + yPosOffset);
            }
            if (_index == 1) {
                return (3, 2 + yPosOffset);
            } else {
                return (5, 2 + yPosOffset);
            }
        }
        if (_size == 2) {
            if (_index == 0) {
                return (2, 2 + yPosOffset);
            } else {
                return (4, 2 + yPosOffset);
            }
        }
        if (_size == 1) {
            return (3, 2 + yPosOffset);
        }
    }

    ///
    function start(uint8 _minTeamCount) external onlyCOO whenNotPaused returns (uint256) {
        require(teamUserInfo.length >= _minTeamCount);

        uint256 competitionId = nextCompetitionId++;
        CompetitionInfo storage ci = competitionInfos[competitionId];
        //ci.startTime = uint64(now);
        ci.status = CompetitionStatus.Start;

        //randomize the last _minTeamCount(=32) teams, and take them out.
        uint256 i;
        uint256 startI = teamUserInfo.length - _minTeamCount;
        uint256 j;
        require(ci.users.length >= _minTeamCount);
        ci.userCount = _minTeamCount;
        uint256 seed = randomContract.maxRandom();
        address[32] memory selectUserInfo;
        for (i = startI; i < teamUserInfo.length; i++) {
            selectUserInfo[i - startI] = teamUserInfo[i];
        }
        i = teamUserInfo.length;
        teamUserInfo.length = teamUserInfo.length - _minTeamCount;
        for (; i > startI; i--) {

            //random from 0 to i
            uint256 m;
            (seed, m) = randomContract.randomNext(seed, i);

            //take out [m], put into competitionInfo
            address user;
            if (m < startI) {
                user = teamUserInfo[m];
            } else {
                user = selectUserInfo[m-startI];
            }
            ci.users[j] = user;
            Team storage teamInfo = userToTeam[user];
            teamInfo.status = TeamStatus.Competition;
            teamInfo.index = uint128(competitionId);

            SponsorsInfo storage si = sponsorInfos[competitionId][j];
            si.sponsors[user] = (si.sponsors[user]).add(teamInfo.fees);
            si.totalAmount = (si.totalAmount).add(teamInfo.fees);

            //exchange [i - 1] and [m]
            if (m != i - 1) {

                user = selectUserInfo[i - 1 - startI];
            
                if (m < startI) {
                    teamUserInfo[m] = user;
                    userToTeam[user].index = uint128(m + 1);
                } else {
                    selectUserInfo[m - startI] = user;
                }
            }

            //delete [i - 1]
            //delete teamUserInfo[i - 1];
            j++;
        }

        StartCompetition(competitionId, now, ci.users);

        return competitionId;
    }

    function sponsor(address _sender, uint256 _competitionId, uint256 _teamIdx, uint256 _count) external whenNotPaused returns (bool) {
        require(msg.sender == address(joyTokenContract) || msg.sender == _sender);

        CompetitionInfo storage ci = competitionInfos[_competitionId];
        require(ci.status == CompetitionStatus.Start);
        //require(now < ci.startTime + sponsorInterval);

        require(joyTokenContract.transferFrom(_sender, address(this), _count));

        require(_teamIdx < ci.userCount);
        address targetUser = ci.users[_teamIdx];
        Team storage teamInfo = userToTeam[targetUser];
        require(teamInfo.status == TeamStatus.Competition);
        
        SponsorsInfo storage si = sponsorInfos[_competitionId][_teamIdx];
        si.sponsors[_sender] = (si.sponsors[_sender]).add(_count);
        si.totalAmount = (si.totalAmount).add(_count);

        Sponsor(_sender, _competitionId, targetUser, _count);
    }

    function reward(uint256 _competitionId, uint256 _teamIdx) external whenNotPaused {
        require(_teamIdx < 32);

        SponsorsInfo storage si = sponsorInfos[_competitionId][_teamIdx];
        uint256 baseValue = si.sponsors[msg.sender];
        require(baseValue > 0);
        CompetitionInfo storage ci = competitionInfos[_competitionId];
        if (ci.status == CompetitionStatus.Cancel) {
            // if (msg.sender == ci.users[_teamIdx]) {
            //     Team storage teamInfo = userToTeam[msg.sender];
            //     require(teamInfo.index == _competitionId && teamInfo.status == TeamStatus.Competition);
            //     delete userToTeam[msg.sender];
            // }
            delete si.sponsors[msg.sender];
            require(joyTokenContract.transfer(msg.sender, baseValue));
        } else if (ci.status == CompetitionStatus.End) {
            require(ci.teamWinCounts[_teamIdx] > 0);

            uint256 rewardValue = baseValue.mul(_getWinCountWeight(ci.teamWinCounts[_teamIdx]));
            rewardValue = ci.totalReward.mul(rewardValue) / ci.totalWeight;
            rewardValue = rewardValue.add(baseValue);

            Reward(_competitionId, ci.users[_teamIdx], ci.teamWinCounts[_teamIdx], msg.sender, baseValue, rewardValue);

            delete si.sponsors[msg.sender];

            require(joyTokenContract.transfer(msg.sender, rewardValue));
        }
    }

    function competition(uint256 _id) external onlyCOO whenNotPaused {
        CompetitionInfo storage ci = competitionInfos[_id];
        require(ci.status == CompetitionStatus.Start);

        uint8[32] memory teamWinCounts;
        uint32[3][11][32] memory playerAwakeSkills;
        TournamentCompetition.competition(_id, ci, teamWinCounts, playerAwakeSkills);

        _reward(_id, ci, teamWinCounts);

        bsCoreContract.tournamentResult(playerAwakeSkills);

        for (uint256 i = 0; i < ci.userCount; i++) {
            delete userToTeam[ci.users[i]];
        }
    }

    function cancelCompetition(uint256 _id) external onlyCOO {
        CompetitionInfo storage ci = competitionInfos[_id];
        require(ci.status == CompetitionStatus.Start);
        ci.status = CompetitionStatus.Cancel;

        for (uint256 i = 0; i < ci.userCount; i++) {
            //Team storage teamInfo = userToTeam[ci.users[i]];
            //require(teamInfo.index == _id && teamInfo.status == TeamStatus.Competition);

            delete userToTeam[ci.users[i]];
        }

        CancelCompetition(_id);
    }

    function _getWinCountWeight(uint256 _winCount) internal pure returns (uint256) {
        if (_winCount == 0) {
            return 0;
        }

        if (_winCount == 1) {
            return 1;
        }

        if (_winCount == 2) {
            return 2;
        }

        if (_winCount == 3) {
            return 3;
        }

        if (_winCount == 4) {
            return 4;
        }

        if (_winCount >= 5) {
            return 8;
        }
    }

    function _reward(uint256 _competitionId, CompetitionInfo storage ci, uint8[32] teamWinCounts) internal {
        uint256 totalReward = 0;
        uint256 totalWeight = 0;
        uint256 i;
        for (i = 0; i < ci.userCount; i++) {
            if (teamWinCounts[i] == 0) {
                totalReward = totalReward.add(sponsorInfos[_competitionId][i].totalAmount);
            } else {
                uint256 weight = sponsorInfos[_competitionId][i].totalAmount;
                weight = weight.mul(_getWinCountWeight(teamWinCounts[i]));
                totalWeight = totalWeight.add(weight);
            }
        }

        uint256 cost = getOperationCost(ci.userCount);

        uint256 ownerCut;
        if (totalReward > cost) {
            ownerCut = cost.add((totalReward - cost).mul(3)/100);
            totalReward = totalReward.sub(ownerCut);
        } else {
            ownerCut = totalReward;
            totalReward = 0;
        }

        require(joyTokenContract.transfer(cfoAddress, ownerCut));

        ci.totalReward = totalReward;
        ci.totalWeight = totalWeight;
        ci.teamWinCounts = teamWinCounts;
        ci.status = CompetitionStatus.End;

        EndCompetition(_competitionId, totalReward, totalWeight, teamWinCounts);
    }

    function _insertSortMemory(uint32[11] arr) internal pure {
        uint256 n = arr.length;
        uint256 i;
        uint32 key;
        uint256 j;

        for (i = 1; i < n; i++) {
            key = arr[i];

            for (j = i; j > 0 && arr[j-1] > key; j--) {
                arr[j] = arr[j-1];
            }

            arr[j] = key;
        }
    }

    function getTeam(address _owner) external view returns (uint256 index, uint256 fees, uint32[11] playerIds,
            uint16[11] playerAtkWeights, TeamStatus status, uint16 attack, uint16 defense, uint16 stamina) {
        Team storage teamInfo = userToTeam[_owner];
        index = teamInfo.index;
        fees = teamInfo.fees;
        playerIds = teamInfo.playerIds;
        playerAtkWeights = teamInfo.playerAtkWeights;
        status = teamInfo.status;
        attack = teamInfo.attack;
        defense = teamInfo.defense;
        stamina = teamInfo.stamina;
    }

    function getCompetitionInfo(uint256 _id) external view returns (uint256 totalReward, uint256 totalWeight,
            address[32] users, uint8[32] teamWinCounts, uint8 userCount, CompetitionStatus status) {
        CompetitionInfo storage ci = competitionInfos[_id];
        //startTime = ci.startTime;
        totalReward = ci.totalReward;
        totalWeight = ci.totalWeight;
        users = ci.users;
        teamWinCounts = ci.teamWinCounts;
        userCount = ci.userCount;
        status = ci.status;
    }
}