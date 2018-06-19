pragma solidity ^0.4.16;

contract PlayerToken {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens);
    function createPlayer(uint32[7] _skills, uint256 _position, address _owner) public returns (uint256);
    function getPlayer(uint256 playerId) public view returns(uint32 talent, uint32 tactics, uint32 dribbling, uint32 kick,
       uint32 speed, uint32 pass, uint32 selection);
    function getPosition(uint256 _playerId) public view returns(uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract CatalogPlayers {
    function getBoxPrice(uint256 _league, uint256 _position) public view returns (uint256);
    function getLengthClassPlayers(uint256 _league, uint256 _position) public view returns (uint256);
    function getClassPlayers(uint256 _league, uint256 _position, uint256 _index) public view returns(uint32[7] skills);
    function incrementCountSales(uint256 _league, uint256 _position) public;
    function getCountSales(uint256 _league, uint256 _position) public view returns(uint256);
}

contract Team {
    uint256 public countPlayersInPosition;
    uint256[] public teamsIds;

    function createTeam(string _name, string _logo, uint256 _minSkills, uint256 _minTalent, address _owner, uint256 _playerId) public returns(uint256 _teamId);
    function getPlayerTeam(uint256 _playerId) public view returns(uint256);
    function getOwnerTeam(address _owner) public view returns(uint256);
    function getCountPlayersOfOwner(uint256 _teamId, address _owner) public view returns(uint256 count);
    function getCountPosition(uint256 _teamId, uint256 _position) public view returns(uint256);
    function joinTeam(uint256 _teamId, address _owner, uint256 _playerId, uint256 _position) public;
    function isTeam(uint256 _teamId) public view returns(bool);
    function leaveTeam(uint256 _teamId, address _owner, uint256 _playerId, uint256 _position) public;
    function getTeamPlayers(uint256 _teamId) public view returns(uint256[]);
    function getCountPlayersOfTeam(uint256 _teamId) public view returns(uint256);
    function getPlayerIdOfIndex(uint256 _teamId, uint256 index) public view returns (uint256);
    function getCountTeams() public view returns(uint256);
    function getTeamSumSkills(uint256 _teamId) public view returns(uint256 sumSkills);
    function getMinSkills(uint256 _teamId) public view returns(uint256);
    function getMinTalent(uint256 _teamId)  public view returns(uint256);


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


contract FMWorld is FMWorldAccessControl {

    address public playerTokenAddress;
    address public catalogPlayersAddress;
    address public teamAddress;

    address private lastPlayerOwner = address(0x0);

    uint256 public balanceForReward;
    uint256 public deposits;
    
    uint256 public countPartnerPlayers;

    mapping (uint256 => uint256) public balancesTeams;
    mapping (address => uint256) public balancesInternal;

    bool public calculatedReward = true;
    uint256 public lastCalculationRewardTime;

    modifier isCalculatedReward() {
        require(calculatedReward);
        _;
    }

    function setPlayerTokenAddress(address _playerTokenAddress) public onlyCEO {
        playerTokenAddress = _playerTokenAddress;
    }

    function setCatalogPlayersAddress(address _catalogPlayersAddress) public onlyCEO {
        catalogPlayersAddress = _catalogPlayersAddress;
    }

    function setTeamAddress(address _teamAddress) public onlyCEO {
        teamAddress = _teamAddress;
    }

    function FMWorld(address _catalogPlayersAddress, address _playerTokenAddress, address _teamAddress) public {
        catalogPlayersAddress = _catalogPlayersAddress;
        playerTokenAddress = _playerTokenAddress;
        teamAddress = _teamAddress;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;

        lastCalculationRewardTime = now;
    }

    function openBoxPlayer(uint256 _league, uint256 _position) external notPause isCalculatedReward payable returns (uint256 _price) {
        if (now > 1525024800) revert();
        
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        CatalogPlayers catalogPlayers = CatalogPlayers(catalogPlayersAddress);

        _price = catalogPlayers.getBoxPrice(_league, _position);
        
        balancesInternal[msg.sender] += msg.value;
        if (balancesInternal[msg.sender] < _price) {
            revert();
        }
        balancesInternal[msg.sender] = balancesInternal[msg.sender] - _price;

        uint256 _classPlayerId = _getRandom(catalogPlayers.getLengthClassPlayers(_league, _position), lastPlayerOwner);
        uint32[7] memory skills = catalogPlayers.getClassPlayers(_league, _position, _classPlayerId);

        playerToken.createPlayer(skills, _position, msg.sender);
        lastPlayerOwner = msg.sender;
        balanceForReward += msg.value / 2;
        deposits += msg.value / 2;
        catalogPlayers.incrementCountSales(_league, _position);

        if (now - lastCalculationRewardTime > 24 * 60 * 60 && balanceForReward > 10 ether) {
            calculatedReward = false;
        }
    }

    function _getRandom(uint256 max, address addAddress) view internal returns(uint256) {
        return (uint256(block.blockhash(block.number-1)) + uint256(addAddress)) % max;
    }
    
    function _requireTalentSkills(uint256 _playerId, PlayerToken playerToken, uint256 _minTalent, uint256 _minSkills) internal view returns(bool) {
        var (_talent, _tactics, _dribbling, _kick, _speed, _pass, _selection) = playerToken.getPlayer(_playerId);
        if ((_talent < _minTalent) || (_tactics + _dribbling + _kick + _speed + _pass + _selection < _minSkills)) return false; 
        return true;
    }

    function createTeam(string _name, string _logo, uint32 _minTalent, uint32 _minSkills, uint256 _playerId) external notPause isCalculatedReward
    {
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        Team team = Team(teamAddress);
        require(playerToken.ownerOf(_playerId) == msg.sender);
        require(team.getPlayerTeam(_playerId) == 0);
        require(team.getOwnerTeam(msg.sender) == 0);
        require(_requireTalentSkills(_playerId, playerToken, _minTalent, _minSkills));
        team.createTeam(_name, _logo, _minTalent, _minSkills, msg.sender, _playerId);
    }

    function joinTeam(uint256 _playerId, uint256 _teamId) external notPause isCalculatedReward
    {
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        Team team = Team(teamAddress);
        require(playerToken.ownerOf(_playerId) == msg.sender);
        require(team.isTeam(_teamId));
        require(team.getPlayerTeam(_playerId) == 0);
        require(team.getOwnerTeam(msg.sender) == 0 || team.getOwnerTeam(msg.sender) == _teamId);
        uint256 _position = playerToken.getPosition(_playerId);
        require(team.getCountPosition(_teamId, _position) < team.countPlayersInPosition());
        require(_requireTalentSkills(_playerId, playerToken, team.getMinTalent(_teamId), team.getMinSkills(_teamId)));

        _calcTeamBalance(_teamId, team, playerToken);
        team.joinTeam(_teamId, msg.sender, _playerId, _position);
    }

    function leaveTeam(uint256 _playerId, uint256 _teamId) external notPause isCalculatedReward
    {
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        Team team = Team(teamAddress);
        require(playerToken.ownerOf(_playerId) == msg.sender);
        require(team.getPlayerTeam(_playerId) == _teamId);
        _calcTeamBalance(_teamId, team, playerToken);
        uint256 _position = playerToken.getPosition(_playerId);
        team.leaveTeam(_teamId, msg.sender, _playerId, _position);
    }

    function withdraw(address _sendTo, uint _amount) external onlyCEO returns(bool) {
        if (_amount > deposits) {
            return false;
        }
        deposits -= _amount;
        _sendTo.transfer(_amount);
        return true;
    }

    function _calcTeamBalance(uint256 _teamId, Team team, PlayerToken playerToken) internal returns(bool){
        if (balancesTeams[_teamId] == 0) {
            return false;
        }
        uint256 _countPlayers = team.getCountPlayersOfTeam(_teamId);
        for(uint256 i = 0; i < _countPlayers; i++) {
            uint256 _playerId = team.getPlayerIdOfIndex(_teamId, i);
            address _owner = playerToken.ownerOf(_playerId);
            balancesInternal[_owner] += balancesTeams[_teamId] / _countPlayers;
        }
        balancesTeams[_teamId] = 0;
        return true;
    }

    function withdrawEther() external returns(bool) {
        Team team = Team(teamAddress);
        uint256 _teamId = team.getOwnerTeam(msg.sender);
        if (balancesTeams[_teamId] > 0) {
            PlayerToken playerToken = PlayerToken(playerTokenAddress);
            _calcTeamBalance(_teamId, team, playerToken);
        }
        if (balancesInternal[msg.sender] == 0) {
            return false;
        }
        msg.sender.transfer(balancesInternal[msg.sender]);
        balancesInternal[msg.sender] = 0;

    }
    
    function createPartnerPlayer(uint256 _league, uint256 _position, uint256 _classPlayerId, address _toAddress) external notPause isCalculatedReward onlyC {
        if (countPartnerPlayers >= 300) revert();
        
        PlayerToken playerToken = PlayerToken(playerTokenAddress);
        CatalogPlayers catalogPlayers = CatalogPlayers(catalogPlayersAddress);

        uint32[7] memory skills = catalogPlayers.getClassPlayers(_league, _position, _classPlayerId);

        playerToken.createPlayer(skills, _position, _toAddress);
        countPartnerPlayers++;
    }

    function calculationTeamsRewards(uint256[] orderTeamsIds) public onlyC {
        Team team = Team(teamAddress);
        if (team.getCountTeams() < 50) {
            lastCalculationRewardTime = now;
            calculatedReward = true;
            return;
        }
        
        if (orderTeamsIds.length != team.getCountTeams()) { 
            revert();
        }
        
        for(uint256 teamIndex = 0; teamIndex < orderTeamsIds.length - 1; teamIndex++) {
            if (team.getTeamSumSkills(orderTeamsIds[teamIndex]) < team.getTeamSumSkills(orderTeamsIds[teamIndex + 1])) {
                revert();
            }
        }
        uint256 k;
        for(uint256 i = 1; i < 51; i++) {
            if (i == 1) { k = 2000; } 
            else if (i == 2) { k = 1400; }
            else if (i == 3) { k = 1000; }
            else if (i == 4) { k = 600; }
            else if (i == 5) { k = 500; }
            else if (i == 6) { k = 400; }
            else if (i == 7) { k = 300; }
            else if (i >= 8 && i <= 12) { k = 200; }
            else if (i >= 13 && i <= 30) { k = 100; }
            else if (i >= 31) { k = 50; }
            balancesTeams[orderTeamsIds[i - 1]] = balanceForReward * k / 10000;
        }
        balanceForReward = 0;
        lastCalculationRewardTime = now;
        calculatedReward = true;
    }

    function getSumWithdrawals() public view returns(uint256 sum) {
        for(uint256 i = 0; i < 51; i++) {
             sum += balancesTeams[i + 1];
        }
    }

    function getBalance() public view returns (uint256 balance) {
        uint256 balanceTeam = getBalanceTeam(msg.sender);
        return balanceTeam + balancesInternal[msg.sender];
    }
    
    function getBalanceTeam(address _owner) public view returns(uint256 balanceTeam) {
        Team team = Team(teamAddress);
        uint256 _teamId = team.getOwnerTeam(_owner);
        if (_teamId == 0) {
            return 0;
        }
        uint256 _countPlayersOwner = team.getCountPlayersOfOwner(_teamId, _owner);
        uint256 _countPlayers = team.getCountPlayersOfTeam(_teamId);
        balanceTeam = balancesTeams[_teamId] / _countPlayers * _countPlayersOwner;
    }

}