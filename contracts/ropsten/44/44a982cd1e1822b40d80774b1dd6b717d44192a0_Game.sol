pragma solidity ^0.4.25;

contract Game {
    
    using SafeMath for uint256;
    
    //teams
    
    struct Team {
        string name;
    }
    
    mapping (uint256 => Team) public teams;
    mapping (string => bool) private teamNames;
    uint256 public numberOfTeams;
    
    event CreateTeam(address indexed player, string indexed teamName, uint256 indexed teamNumber);
    event JoinTeam(address indexed player, string indexed teamName, uint256 indexed teamNumber);
    event LeaveTeam(address indexed player, string indexed teamName, uint256 indexed teamNumber);
    
    //players
    
    struct Player {
        uint256 team;
        bool joinedTeam;
    }
    
    mapping (address => Player) public addressToPlayers;
    mapping (address => bool) public players;
    uint256 public numberOfPlayers;
    
    event NewPlayer(address indexed player);
    
    //units
    
    struct Unit {
        address owner;
        UnitType unitType;
    }
    
    enum UnitType {
        TYPE1,
        TYPE2,
        TYPE3
    }
    
    mapping(uint256 => mapping(uint256 => uint256)) private skillMap;
    
    mapping (uint256 => Unit) public units;
    uint256 public numberOfUnits;
    uint256 constant public UNIT_COST = 0.0 ether;
    
    event CreateUnit(address indexed player, UnitType indexed unitType);
    
    //fights
    
    struct Fight {
        uint256 blocknumber;
        uint256 attackingUnit;
        uint256 defendingUnit;
    }
    
    mapping (uint256 => Fight) public fights;
    uint256 numberOfFights;
    uint256 numberOfResolvedFights;
    
    event FightStart(address indexed attacker, address indexed defender, uint256 attackingUnit, uint256 defendingUnit);
    event FightOver(address indexed attacker, address indexed defender, uint256 attackingUnit, uint256 defendingUnit, uint256 attackingUnitSkill, uint256 randomNumber);
    
    modifier progressGame()
    {
        //there are no fights to resolve
        if(numberOfResolvedFights == numberOfFights) {return;}
        
        Fight memory fightToResolve = fights[numberOfResolvedFights];
        
        //can&#39;t resolve a fight created within same block
        if(fightToResolve.blocknumber == block.number) {return;}
    
        //can&#39;t resolve fight after 256 blocks
        if(block.number - 256 > fightToResolve.blocknumber) {
            fightToResolve.blocknumber = block.number;
            return;
        }
        
        //resolve fight
        Unit memory attackingUnit = units[fightToResolve.attackingUnit];
        Unit memory defendingUnit = units[fightToResolve.defendingUnit];
        
        uint256 attackingUnitSkill= skillMap[uint256(attackingUnit.unitType)][uint256(defendingUnit.unitType)];
        uint256 randomNumber = uint256(blockhash(fightToResolve.blocknumber)) % 10;
        
        if(attackingUnitSkill >= randomNumber) {
            units[fightToResolve.defendingUnit] = units[numberOfUnits - 1];
        } else {
            units[fightToResolve.attackingUnit] = units[numberOfUnits - 1];
        }
        numberOfUnits--;
        numberOfResolvedFights++;
        
        emit FightOver(attackingUnit.owner, defendingUnit.owner, fightToResolve.attackingUnit, fightToResolve.defendingUnit, attackingUnitSkill, randomNumber);
        _;
    }
    
    modifier managePlayer()
    {
        if(!players[msg.sender]) {
            addressToPlayers[msg.sender] = Player(0, false);
            numberOfPlayers++;
            players[msg.sender] = true;
            
            emit NewPlayer(msg.sender);
        }
        _;
    }
    
    constructor()
        public
    {
        //TYPE1
        skillMap[0][0] = 4;
        skillMap[0][1] = 6;
        skillMap[0][2] = 2;
        
        //TYPE2
        skillMap[1][0] = 2;
        skillMap[1][1] = 4;
        skillMap[1][2] = 6;
        
        //TYPE3
        skillMap[2][0] = 6;
        skillMap[2][1] = 2;
        skillMap[2][2] = 4;
    }
    
    //unit management
    
    function createUnit(UnitType unitType)
        external
        payable
        progressGame
        managePlayer
    {
        require(msg.value == UNIT_COST);
        
        units[numberOfUnits] = Unit(msg.sender, unitType);
        
        numberOfUnits++;
        
        emit CreateUnit(msg.sender, unitType);
    }
    
    function isLegalAttack(uint256 attackingUnit, uint256 defendingUnit)
        private
        view
        returns (bool)
    {
        Player memory attacker = addressToPlayers[units[attackingUnit].owner];
        Player memory defender = addressToPlayers[units[defendingUnit].owner];
        
        //units can only attack each other if at least one of them is teamless or they don&#39;t belong to the same team
        return (!attacker.joinedTeam || !defender.joinedTeam || attacker.team != defender.team);
    }
    
    function attackUnit(uint256 attackingUnit, uint256 defendingUnit)
        external
        progressGame
    {
        //we can&#39;t attack with units that don&#39;t exist
        require(attackingUnit < numberOfUnits && defendingUnit < numberOfUnits);
        
        //we can&#39;t attack with units we don&#39;t control
        require(units[attackingUnit].owner == msg.sender);
        
        //we can&#39;t attack our own units
        require(units[defendingUnit].owner != msg.sender);
        
        //are the units allowed to fight each other?
        require(isLegalAttack(attackingUnit, defendingUnit));
        
        //register Attack (will be resolved later)
        fights[numberOfFights] = Fight(block.number, attackingUnit, defendingUnit);
        numberOfFights++;
        
        emit FightStart(msg.sender, units[defendingUnit].owner, attackingUnit, defendingUnit);
    }
    
    //team management
    
    function createTeam(string name)
        external
        progressGame
        managePlayer
    {
        require(!teamNames[name]);
        
        Player storage player = addressToPlayers[msg.sender];
        
        require(!player.joinedTeam);
        
        player.team = numberOfTeams;
        player.joinedTeam = true;
        
        teams[numberOfTeams] = Team(name);
        
        teamNames[name] = true;
        
        emit CreateTeam(msg.sender, name, numberOfTeams);
        
        numberOfTeams++;
    }
    
    function joinTeam(uint256 teamNumber)
        external
        progressGame
        managePlayer
    {
        require(teamNumber < numberOfTeams);
        
        Player storage player = addressToPlayers[msg.sender];
        
        require(!player.joinedTeam);
        
        player.team = teamNumber;
        player.joinedTeam = true;
        
        emit JoinTeam(msg.sender, teams[teamNumber].name, teamNumber);
    }
    
    function leaveTeam(uint256 teamNumber)
        external
        progressGame
    {   
        Player storage player = addressToPlayers[msg.sender];
        
        require(player.joinedTeam && player.team == teamNumber);
        
        player.joinedTeam = false;
        
        emit LeaveTeam(msg.sender, teams[teamNumber].name, teamNumber);
    }
    
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
}