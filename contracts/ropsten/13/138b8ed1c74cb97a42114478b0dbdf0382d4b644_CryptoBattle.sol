pragma solidity ^0.4.23;

/**
* @title CryptoBattle Contract
* @dev The Game of the Year
*/

contract CryptoBattle {
    address public owner; // Contract owner address

    // Стоимость 1 очка оумения в эфире
    uint public skillPointCost = 1;

    mapping (address => uint256) public scores;
    uint public battlesCount = 0;
    uint public heroesCount = 0;
    uint public minBet = 100;
    uint public basePoints = 1;
    uint public baseStamina = 2;
    uint public baseStrength = 1;

    string public constant name = &#39;CryptoBattle v0.0.1&#39;;
    
    mapping (address => Hero) public heroes;
    mapping (uint => Battle) public battles;

    struct Hero {
        uint id;
        string name;
        uint strength;
        uint stamina;
        uint agility;
        uint initiative;
        uint battles_num;
        uint wins_num;
        uint free_points;
    }
    
    struct Battle {
        address from;
        uint from_health;
        address to;
        uint to_health;
        uint bet;
        BattleStatus status;
        bool turnFrom;
        address winner;
    }
    
    enum BattleStatus {
        WaitingOpponent,
        InProgress,
        Finished
    }

    enum Ability {
        MeleeAttack,
        RangeAttack,
        MagicAttack,
        Fireball,
        IceRain,
        Poison,
        Heal
    }

    enum HeroClass {
        Warrior,
        Rouge,
        Mage
    }

    // Ability[] constant warrior_abilities = [];

    //
    // Events
    // This generates a publics event on the blockchain that will notify clients

    event BattleStatusChanged(uint battle_id, BattleStatus status); // ?
    event BattleCreated(uint battle_id, address from, uint bet);
    event BattleStarted(uint battle_id, address to);
    event Attack(uint battle_id, address attacker, uint force);
    event BattleFinished(uint battle_id, address winner, address loser);

    //
    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBattleParticipant(uint _battle_id) {
        Battle memory battle = battles[_battle_id];
        require(msg.sender == battle.from || msg.sender == battle.to);
        _;
    }

    modifier onlySenderTurn(uint _battle_id) {
        Battle memory battle = battles[_battle_id];
        require(msg.sender == (battle.turnFrom ? battle.from : battle.to));
        _;
    }

    modifier haveHero(address _address) {
        require(heroes[_address].id > 0);
        _;
    }

    //
    // Functions
    // 

    // Constructor
    constructor() public {
        owner = msg.sender;
    }

    //создание Героя
    function createHero(string _name, uint _strength, uint _stamina, uint _agility, uint _initiative) public
    {
        require(safeAdd(_strength, _stamina, _agility, _initiative) <= basePoints);

        heroes[msg.sender] = Hero({
            id: ++heroesCount,
            name: _name,
            strength: _strength + baseStrength,
            stamina: _stamina + baseStamina,
            agility: _agility,
            initiative: _initiative, 
            battles_num: 0,
            wins_num: 0,
            free_points: 0
        });
    }

    function arrangeFreePoints(uint _strength, uint _stamina, uint _agility, uint _initiative) public
    haveHero(msg.sender)
    {
        require(safeAdd(_strength, _stamina, _agility, _initiative) <= heroes[msg.sender].free_points);

        heroes[msg.sender].strength += _strength;
        heroes[msg.sender].stamina += _stamina;
        heroes[msg.sender].agility += _agility;
        heroes[msg.sender].initiative += _initiative;
    }
    
    //создание Битвы
    function createBattle(uint _bet)
    public payable returns (uint) 
    {
        require(msg.value == _bet);
        uint battleID = battlesCount++;
        battles[battleID] = Battle({
            from: msg.sender,
            from_health: heroes[msg.sender].stamina,
            to: address(0),
            to_health: 0,
            bet: _bet,
            status: BattleStatus.WaitingOpponent,
            turnFrom: true,
            winner: address(0)
        });
        emit BattleCreated(battleID, msg.sender, _bet);
        return battleID;
    }


    function joinBattle(uint _battle_id) public payable {
        Battle memory b = battles[_battle_id];

        require(b.from != msg.sender);
        require(b.to == address(0));
        require(msg.value == b.bet);

        battles[_battle_id].to = msg.sender;
        battles[_battle_id].to_health = heroes[msg.sender].stamina;
        battles[_battle_id].status = BattleStatus.InProgress;

        if(heroes[msg.sender].initiative > heroes[b.from].initiative) {
            battles[_battle_id].turnFrom = false;
        }

        emit BattleStarted(_battle_id, msg.sender);
    }


    function attack(uint _battle_id) public
    onlySenderTurn(_battle_id)
    {
        Battle memory b = battles[_battle_id];
        address attacker = msg.sender;
        address defender = ( b.from == attacker ? b.to : b.from );

        uint force = heroes[attacker].strength;
        
        if( getChance(5, heroes[defender].agility) ) {
            force = 0;
        }

        if (b.turnFrom) {
            battles[_battle_id].to_health = subZero(b.to_health, force);
            if (subZero(b.to_health, force) == 0) { finishBattle(_battle_id, attacker, defender); }
        } else {
            battles[_battle_id].from_health = subZero(b.from_health, force);
            if (subZero(b.from_health, force) == 0) { finishBattle(_battle_id, attacker, defender); }
        }

        battles[_battle_id].turnFrom = !b.turnFrom;
        emit Attack(_battle_id, attacker, force);
    }
    
    
    function getChance(uint _blockshift, uint _agility) public view returns(bool) {
        uint max = 100;

        uint chance = 2;
        if(_agility < max) {
            chance = max - _agility;
        } 
        
        uint val = uint(blockhash(block.number - _blockshift)) % chance + 1;
     
        return (val == 1);
    }


    function finishBattle(uint _battle_id, address _attacker, address _defender) internal {
        // Battle memory b = battles[_battle_id];

        heroes[_attacker].battles_num += 1;
        heroes[_attacker].wins_num += 1;
        heroes[_attacker].free_points += heroes[_defender].stamina;
        // _attacker + bet
        battles[_battle_id].status = BattleStatus.Finished;
        battles[_battle_id].winner = _attacker;
        
        _attacker.transfer( safeMul(battles[_battle_id].bet, 2) );
        
        emit BattleFinished(_battle_id, _attacker, _defender);
    }
    
    
    function setBasePoints(uint _basePoints) public onlyOwner {
        basePoints = _basePoints;
    }
    
    function setBaseStrength(uint _val) public onlyOwner {
        baseStrength = _val;
    }
    
    function setBaseStamina(uint _val) public onlyOwner {
        baseStamina = _val;
    }
    
    
    function getRandomValue(uint _blockshift) public view returns (uint) {
        return uint(blockhash(block.number - _blockshift)) % 2 + 1;
    }

    // function useAbility(uint _battle_id, Ability _ability) public
    // onlyBattleParticipant(_battle_id)
    // onlyCorrectTurn(_battle_id)
    // {
    //     if (_ability == Ability.MeleeAttack) {
    //         // ...
    //         return;
    //     }

    //     if (_ability == Ability.RangeAttack) {

    //     }
    // }


    function withdrawEther(address _to) public
    onlyOwner
    {
        _to.transfer(address(this).balance);
    }

    function setSkillPointCost(uint _cost) public
    onlyOwner
    {
        skillPointCost = _cost;
    }

    function getHeroLevel(address _address) public view
    haveHero(_address)
    returns(uint)
    {
        return getLevel(heroes[_address]);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function subZero(uint a, uint b) internal pure returns (uint) {
        if(b <= a) {
            return 0;
        } else {
            return a - b;
        }
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function safeAdd(uint a, uint b, uint c, uint d) internal pure
    returns (uint)
    {
        return safeAdd(
            safeAdd(a, b),
            safeAdd(c, d)
        );
    }

    ///suicide & send funds to owner
    function destroy() public { 
        if (msg.sender == owner) {
          selfdestruct(owner);
        }
    }


    ////// Some safe pure functions

    function getSumSkills(Hero _hero) private pure
    returns(uint)
    {
        return safeAdd(
            _hero.strength,
            _hero.stamina,
            _hero.agility,
            _hero.initiative
        );
    }

    function getLevel(Hero _hero) private pure
    returns(uint)
    {
        return safeAdd(
            getSumSkills(_hero),
            _hero.free_points
        );
    }
}