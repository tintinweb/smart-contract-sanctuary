pragma solidity ^0.4.16;

contract PlayerToken {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] ownerTokens);
    function createPlayer(uint32[7] _skills, uint256 _position, address _owner) public returns (uint256);
    function getPlayer(uint256 playerId) public view returns(uint32 talent, uint32 tactics, uint32 dribbling, uint32 kick,
       uint32 speed, uint32 pass, uint32 selection);
    function getPosition(uint256 _playerId) public view returns(uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}


contract FMWorldAccessControl {
    address public ceoAddress;
    address public cooAddress;

    bool public pause = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyC() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress
        );
        _;
    }

    modifier notPause() {
        require(!pause);
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }


    function setPause(bool _pause) external onlyC {
        pause = _pause;
    }


}


contract Team is FMWorldAccessControl
{
    struct TeamStruct {
        string name;
        string logo;
        uint256[] playersIds;
        uint256 minSkills;
        uint256 minTalent;
        mapping(uint256 => uint256) countPositions;
    }

    uint256 public countPlayersInPosition;

    mapping(uint256 => TeamStruct) public teams;

    uint256[] public teamsIds;

    mapping (uint256 => uint256) mapPlayerTeam;

    mapping (address => uint256) mapOwnerTeam;

    address public playerTokenAddress;

    function Team(address _playerTokenAddress) public {
        countPlayersInPosition = 4;
        playerTokenAddress = _playerTokenAddress;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function setName(uint256 _teamId, string _name) external onlyCEO {
        teams[_teamId].name = _name;
    }

    function setLogo(uint256 _teamId, string _logo) external onlyCEO {
        teams[_teamId].logo = _logo;
    }


    function getTeamSumSkills(uint256 _teamId) public view returns(uint256 sumSkills) {
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        uint256 l = teams[_teamId].playersIds.length;
        for (uint256 _playerIndex = 0; _playerIndex < l; _playerIndex++) {
            var (_talent, _tactics, _dribbling, _kick, _speed, _pass, _selection) = playerToken.getPlayer(teams[_teamId].playersIds[_playerIndex]);
            sumSkills +=  _tactics + _dribbling + _kick + _speed + _pass + _selection;
        }
    }

    function setPlayerTokenAddress(address _playerTokenAddress) public onlyCEO {
        playerTokenAddress = _playerTokenAddress;
    }

    function getPlayerIdOfIndex(uint256 _teamId, uint256 index) public view returns (uint256) {
        return teams[_teamId].playersIds[index];
    }

    function getCountTeams() public view returns(uint256) {
        return teamsIds.length;
    }

    function getAllTeamsIds() public view returns(uint256[]) {
        return teamsIds;
    }

    function setCountPlayersInPosition(uint256 _countPlayersInPosition) public onlyCEO {
        countPlayersInPosition = _countPlayersInPosition;
    }
    
    function getMinSkills(uint256 _teamId) public view returns(uint256) {
        return teams[_teamId].minSkills;
    }
    
    function getMinTalent(uint256 _teamId)  public view returns(uint256) {
        return teams[_teamId].minTalent;
    }

    function getTeam(uint256 _teamId) public view returns(string _name, string _logo, uint256 _minSkills, uint256 _minTalent,
        uint256 _countPlayers, uint256 _countPositionsGk, uint256 _countPositionsDf, uint256 _countPositionsMd, uint256 _countPositionsFw) {
        _name = teams[_teamId].name;
        _logo = teams[_teamId].logo;
        _minSkills = teams[_teamId].minSkills;
        _minTalent = teams[_teamId].minTalent;
        _countPlayers = teams[_teamId].playersIds.length;
        _countPositionsGk = teams[_teamId].countPositions[1];
        _countPositionsDf = teams[_teamId].countPositions[2];
        _countPositionsMd = teams[_teamId].countPositions[3];
        _countPositionsFw = teams[_teamId].countPositions[4];
    }

    function createTeam(string _name, string _logo, uint256 _minTalent, uint256 _minSkills, address _owner, uint256 _playerId) public onlyCOO returns(uint256 _teamId) {
        _teamId = teamsIds.length + 1;
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        uint256 _position = playerToken.getPosition(_playerId);
        teams[_teamId].name = _name;
        teams[_teamId].minSkills = _minSkills;
        teams[_teamId].minTalent = _minTalent;
        teams[_teamId].logo = _logo;
        teamsIds.push(_teamId);
        _addOwnerPlayerToTeam(_teamId, _owner, _playerId, _position);
    }

    function getPlayerTeam(uint256 _playerId) public view returns(uint256) {
        return mapPlayerTeam[_playerId];
    }

    function getOwnerTeam(address _owner) public view returns(uint256) {
        return mapOwnerTeam[_owner];
    }

    function isTeam(uint256 _teamId) public view returns(bool) {
        if (teams[_teamId].minTalent == 0) {
            return false;
        }
        return true;
    }

    function getTeamPlayers(uint256 _teamId) public view returns(uint256[]) {
        return teams[_teamId].playersIds;
    }

    function getCountPlayersOfOwner(uint256 _teamId, address _owner) public view returns(uint256 count) {
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        for (uint256 i = 0; i < teams[_teamId].playersIds.length; i++) {
            if (playerToken.ownerOf(teams[_teamId].playersIds[i]) == _owner) {
                count++;
            }
        }
    }

    function getCountPlayersOfTeam(uint256 _teamId) public view returns(uint256) {
        return teams[_teamId].playersIds.length;
    }

    function getCountPosition(uint256 _teamId, uint256 _position) public view returns(uint256) {
        return teams[_teamId].countPositions[_position];
    }


    function _addOwnerPlayerToTeam(uint256 _teamId, address _owner, uint256 _playerId, uint256 _position) internal {
        teams[_teamId].playersIds.push(_playerId);
        teams[_teamId].countPositions[_position] += 1;
        mapOwnerTeam[_owner] = _teamId;
        mapPlayerTeam[_playerId] = _teamId;
    }

    function joinTeam(uint256 _teamId, address _owner, uint256 _playerId, uint256 _position) public onlyCOO {
        _addOwnerPlayerToTeam(_teamId, _owner, _playerId, _position);
    }

    function leaveTeam(uint256 _teamId, address _owner, uint256 _playerId, uint256 _position) public onlyCOO {
        PlayerToken playerToken = PlayerToken(playerTokenAddress);

        delete mapPlayerTeam[_playerId];
        //

        teams[_teamId].countPositions[_position] -= 1;
        //

        for (uint256 i = 0; i < teams[_teamId].playersIds.length; i++) {
            if (teams[_teamId].playersIds[i] == _playerId) {
                _removePlayer(_teamId, i);
                break;
            }
        }

        bool isMapOwnerTeamDelete = true;
        for (uint256 pl = 0; pl < teams[_teamId].playersIds.length; pl++) {
            if (_owner == playerToken.ownerOf(teams[_teamId].playersIds[pl])) {
                isMapOwnerTeamDelete = false;
                break;
            }
        }

        if (isMapOwnerTeamDelete) {
            delete mapOwnerTeam[_owner];
        }
    }

    function _removePlayer(uint256 _teamId, uint256 index) internal {
        if (index >= teams[_teamId].playersIds.length) return;

        for (uint i = index; i<teams[_teamId].playersIds.length-1; i++){
            teams[_teamId].playersIds[i] = teams[_teamId].playersIds[i+1];
        }
        delete teams[_teamId].playersIds[teams[_teamId].playersIds.length-1];
        teams[_teamId].playersIds.length--;
    }



}