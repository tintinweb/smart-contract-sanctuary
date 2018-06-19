pragma solidity ^0.4.16;

// copyright <span class="__cf_email__" data-cfemail="fb9894958f9a988fbbbe8f939e899e969495d5989496">[email&#160;protected]</span>

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = true;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}


contract EtheremonRankData is BasicAccessControl {

    struct PlayerData {
        address trainer;
        uint32 point;
        uint32 energy;
        uint lastClaim;
        uint32 totalWin;
        uint32 totalLose;
        uint64[6] monsters;
    }
    
    mapping(uint32 => PlayerData) players;
    mapping(address => uint32) playerIds;
    
    uint32 public totalPlayer = 0;
    uint32 public startingPoint = 1200;
    
    // only moderators
    /*
    TO AVOID ANY BUGS, WE ALLOW MODERATORS TO HAVE PERMISSION TO ALL THESE FUNCTIONS AND UPDATE THEM IN EARLY BETA STAGE.
    AFTER THE SYSTEM IS STABLE, WE WILL REMOVE OWNER OF THIS SMART CONTRACT AND ONLY KEEP ONE MODERATOR WHICH IS ETHEREMON BATTLE CONTRACT.
    HENCE, THE DECENTRALIZED ATTRIBUTION IS GUARANTEED.
    */
    
    function updateConfig(uint32 _startingPoint) onlyModerators external {
        startingPoint = _startingPoint;
    }
    
    function setPlayer(address _trainer, uint64 _a0, uint64 _a1, uint64 _a2, uint64 _s0, uint64 _s1, uint64 _s2) onlyModerators external returns(uint32 playerId){
        require(_trainer != address(0));
        playerId = playerIds[_trainer];
        
        bool isNewPlayer = false;
        if (playerId == 0) {
            totalPlayer += 1;
            playerId = totalPlayer;
            playerIds[_trainer] = playerId;
            isNewPlayer = true;
        }
        
        PlayerData storage player = players[playerId];
        if (isNewPlayer)
            player.point = startingPoint;
        player.trainer = _trainer;
        player.monsters[0] = _a0;
        player.monsters[1] = _a1;
        player.monsters[2] = _a2;
        player.monsters[3] = _s0;
        player.monsters[4] = _s1;
        player.monsters[5] = _s2;
    }
    
    function updatePlayerPoint(uint32 _playerId, uint32 _totalWin, uint32 _totalLose, uint32 _point) onlyModerators external {
        PlayerData storage player = players[_playerId];
        player.point = _point;
        player.totalWin = _totalWin;
        player.totalLose = _totalLose;
    }
    
    function updateEnergy(uint32 _playerId, uint32 _energy, uint _lastClaim) onlyModerators external {
        PlayerData storage player = players[_playerId];
        player.energy = _energy;
        player.lastClaim = _lastClaim;
    }
    
    // read access 
    function getPlayerData(uint32 _playerId) constant external returns(address trainer, uint32 totalWin, uint32 totalLose, uint32 point, 
        uint64 a0, uint64 a1, uint64 a2, uint64 s0, uint64 s1, uint64 s2, uint32 energy, uint lastClaim) {
        PlayerData memory player = players[_playerId];
        return (player.trainer, player.totalWin, player.totalLose, player.point, player.monsters[0], player.monsters[1], player.monsters[2], 
            player.monsters[3], player.monsters[4], player.monsters[5], player.energy, player.lastClaim);
    }
    
    function getPlayerDataByAddress(address _trainer) constant external returns(uint32 playerId, uint32 totalWin, uint32 totalLose, uint32 point,
        uint64 a0, uint64 a1, uint64 a2, uint64 s0, uint64 s1, uint64 s2, uint32 energy, uint lastClaim) {
        playerId = playerIds[_trainer];
        PlayerData memory player = players[playerId];
        totalWin = player.totalWin;
        totalLose = player.totalLose;
        point = player.point;
        a0 = player.monsters[0];
        a1 = player.monsters[1];
        a2 = player.monsters[2];
        s0 = player.monsters[3];
        s1 = player.monsters[4];
        s2 = player.monsters[5];
        energy = player.energy;
        lastClaim = player.lastClaim;
    }
    
    function isOnBattle(address _trainer, uint64 _objId) constant external returns(bool) {
        uint32 playerId = playerIds[_trainer];
        if (playerId == 0)
            return false;
        PlayerData memory player = players[playerId];
        for (uint i = 0; i < player.monsters.length; i++)
            if (player.monsters[i] == _objId)
                return true;
        return false;
    }

    function getPlayerPoint(uint32 _playerId) constant external returns(address trainer, uint32 totalWin, uint32 totalLose, uint32 point) {
        PlayerData memory player = players[_playerId];
        return (player.trainer, player.totalWin, player.totalLose, player.point);
    }
    
    function getPlayerId(address _trainer) constant external returns(uint32 playerId) {
        return playerIds[_trainer];
    }

    function getPlayerEnergy(uint32 _playerId) constant external returns(address trainer, uint32 energy, uint lastClaim) {
        PlayerData memory player = players[_playerId];
        trainer = player.trainer;
        energy = player.energy;
        lastClaim = player.lastClaim;
    }
    
    function getPlayerEnergyByAddress(address _trainer) constant external returns(uint32 playerId, uint32 energy, uint lastClaim) {
        playerId = playerIds[_trainer];
        PlayerData memory player = players[playerId];
        energy = player.energy;
        lastClaim = player.lastClaim;
    }
}