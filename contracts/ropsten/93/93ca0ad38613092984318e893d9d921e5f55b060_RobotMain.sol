pragma solidity ^0.4.18;

contract Ownable 
{
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public
    onlyOwner 
    {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    //function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


//pseudorandom
contract Random {
    uint256 private primeNumber = 370103;

    function toBytes(uint256 x) private pure returns (bytes b) {
        b = new bytes(32);
        assembly
        {
            mstore(add(b, 32), x)
        }
    }

    function prime(uint256 current) private pure returns (bool)
    {
        if(current % 2 == 0)
        {
            if(current == 2) return true;
            else return false;
        }

        for(uint256 i = 3; i * i <= current; i += 2)
        {
            if(current % i == 0) return false;
        }
        return true;
    }

    function nextPrime(uint256 current) private pure returns (uint256)
    {
        current++;
        while(!prime(current))
        {
            current++;
        }
        if(current < 380103)
        {
            return current;
        }
        else
        {
            return current = 4099;
        }
    }
    function random(uint256 modulo) internal view returns (uint256)
    {
        primeNumber = nextPrime(primeNumber); 
        return (uint256((keccak256(toBytes(primeNumber))) ^
        (keccak256(toBytes(gasleft()))) ^
        (keccak256(toBytes(block.difficulty))) ^
        (keccak256(toBytes(block.timestamp)))) % primeNumber) % (modulo + 1);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused external returns (bool)
    {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() onlyOwner whenPaused external returns (bool)
    {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract RobotBase is Ownable, Random {
    
    enum ComponentTypes  {Head, Body, Arms, Legs, Weapon} 

    uint256 internal totalRobots = 0;
    uint256 internal currentBackId = 1;

    struct Component {
        ComponentTypes dtype;
        uint256 agility;
        uint256 attack;
        uint256 health;
        uint256 usedByRobotId;
        uint256 genom;
    }

    struct Robot {
        uint256 attack;
        uint256 max_health;
        int     health;
        //uint256 stamina;//TODO: current & max
        uint256 agility;
        //uint256 ability;
        //uint256 element;
        uint256 wins;
        uint256 loses;
        uint256 mobsDefeated;
        bool dead;
        uint256 xp;
    }  

    mapping (uint256 => Robot) robots;
    mapping (uint256 => address) robotIdToOwner;
    mapping (uint256 => uint256) robotIdToApprovedToFight;
    mapping (uint256 => address) robotIdToApproved;
    mapping (address => uint256) ownerToNumberOfRobots;
    mapping (address => mapping(uint256 => Component)) ownerToComponents;
    mapping (address => uint256) ownerToComponentsBackId;
    mapping (uint256 => uint256[5]) robotIdToComponentsId;

    function firstEmptyId() external view returns (uint256)
    {
        for(uint256 robotId = 1; robotId < currentBackId; ++robotId)
        {
            if(robots[robotId].dead)
            {
                return robotId;
            }
        }
        return robotId;
    }
    
    function getRobot(uint256 _attack, uint256 _health, uint256 _agility) internal returns (uint256)
    {
        robots[currentBackId] = Robot
        ({
            attack : _attack, //9 + random(2),
            max_health : _health, //90 + random(20),
            health : int256(_health),
            //stamina : 0,
            agility : _agility, //5 + random(10),
            //ability : 0,
            //element : 0,
            wins : 0,
            loses : 0,
            mobsDefeated : 0,
            dead : false,
            xp : 0
        });
        totalRobots++;
        return currentBackId++;
        
    }
    function getComponent(uint256 _dtype, uint256 _attack, uint256 _health, uint256 _agility) internal returns (uint256)
    {
        ownerToComponents[msg.sender][ownerToComponentsBackId[msg.sender]] = Component
        ({
            dtype : ComponentTypes(_dtype),
            attack : _attack,
            health : _health,
            agility : _agility,
            usedByRobotId : 0,
            genom : random(370100)
        });
        return ownerToComponentsBackId[msg.sender]++;
    }
}

contract RobotOwnership is RobotBase, ERC721, Pausable
{
    string public constant name = "Robots";
    string public constant symbol = "RB";

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if(_to != address(0))
        {
            ownerToNumberOfRobots[_to]++;
        }

        robotIdToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownerToNumberOfRobots[_from]--;
            delete robotIdToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return robotIdToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return robotIdToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        robotIdToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownerToNumberOfRobots[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return totalRobots;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = robotIdToOwner[_tokenId];
        require(owner != address(0));
    }

    event TokenDestruction(uint256 tokenId);

    function _destroyRobot(uint256 robotId) internal
    {
        robots[robotId].dead = true;
        totalRobots--;
        for(uint256 i = 0; i < 5; ++i)
        {
            ownerToComponents[msg.sender][robotIdToComponentsId[robotId][i]].usedByRobotId = 0;
        }
        _transfer(robotIdToOwner[robotId], address(0), robotId);
        emit TokenDestruction(robotId);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[])
    {
        uint256[] memory res = new uint256[](ownerToNumberOfRobots[owner]);
        uint256 cnt = 0;
        for(uint256 robotId = 1; robotId < currentBackId; ++robotId)
        {
            if(robotIdToOwner[robotId] == _owner)
            {
                res[cnt++] = robotId;
            }
            if(cnt == ownerToNumberOfRobots[owner])
            {
                break;
            }
        }
        return res;
    }

    function numberOfMyComponents() external view returns(uint256)
    {
        return (ownerToComponentsBackId[msg.sender]);
    }

    function numberOfComponents(address owner) external view returns(uint256)
    {
        return (ownerToComponentsBackId[owner]);
    }
    
    function viewMyComponent(uint256 id) external view 
    returns(
        uint256 dtype,
        uint256 agility,
        uint256 attack,
        uint256 health,
        uint256 usedByRobotId,
        uint256 genom)
    {
        dtype = uint256(ownerToComponents[msg.sender][id].dtype);
        agility = ownerToComponents[msg.sender][id].agility;
        attack = ownerToComponents[msg.sender][id].attack;
        health = ownerToComponents[msg.sender][id].health;
        usedByRobotId = ownerToComponents[msg.sender][id].usedByRobotId;
        genom = ownerToComponents[msg.sender][id].genom;
       
    }
    function viewComponent(address owner, uint256 id) external view
    returns(
        uint256 dtype,
        uint256 agility,
        uint256 attack,
        uint256 health,
        uint256 usedByRobotId,
        uint256 genom)
    {
        dtype = uint256(ownerToComponents[owner][id].dtype);
        agility = ownerToComponents[owner][id].agility;
        attack = ownerToComponents[owner][id].attack;
        health = ownerToComponents[owner][id].health;
        usedByRobotId = ownerToComponents[owner][id].usedByRobotId;
        genom = ownerToComponents[owner][id].genom;
    }

}

contract RobotCollection is RobotOwnership {
    event Collection(uint256 head, uint256 body, uint256 arms, uint256 legs, uint256 weapon);
    function collectRobot(uint256 idOfHead, uint256 idOfBody, uint256 idOfArms, uint256 idOfLegs, uint256 idOfWeapon) external
    {
        Component storage head = ownerToComponents[msg.sender][idOfHead];
        Component storage body = ownerToComponents[msg.sender][idOfBody];
        Component storage arms = ownerToComponents[msg.sender][idOfArms];
        Component storage legs = ownerToComponents[msg.sender][idOfLegs];
        Component storage weapon = ownerToComponents[msg.sender][idOfWeapon];

        require(head.dtype == ComponentTypes.Head);
        require(body.dtype == ComponentTypes.Body);
        require(arms.dtype == ComponentTypes.Arms);
        require(legs.dtype == ComponentTypes.Legs);
        require(weapon.dtype == ComponentTypes.Weapon);

        require(head.usedByRobotId == 0 || robots[head.usedByRobotId].dead == true);
        require(body.usedByRobotId == 0 || robots[body.usedByRobotId].dead == true);
        require(arms.usedByRobotId == 0 || robots[arms.usedByRobotId].dead == true);
        require(legs.usedByRobotId == 0 || robots[legs.usedByRobotId].dead == true);
        require(weapon.usedByRobotId == 0 || robots[weapon.usedByRobotId].dead == true);

        uint256 newRobotId = getRobot(
        head.attack + body.attack + arms.attack + legs.attack + weapon.attack,
        head.health + body.health + arms.health + legs.health + weapon.health,
        head.agility + body.agility + arms.agility + legs.agility + weapon.agility);
        //robot. = head. + body. + arms. + legs. + weapon.;
        
        
        head.usedByRobotId = newRobotId;
        robotIdToComponentsId[newRobotId][0] = idOfHead;
        body.usedByRobotId = newRobotId;
        robotIdToComponentsId[newRobotId][1] = idOfBody;
        arms.usedByRobotId = newRobotId;
        robotIdToComponentsId[newRobotId][2] = idOfArms;
        legs.usedByRobotId = newRobotId;
        robotIdToComponentsId[newRobotId][3] = idOfLegs;
        weapon.usedByRobotId = newRobotId;
        robotIdToComponentsId[newRobotId][4] = idOfWeapon;
        emit Collection(idOfHead, idOfBody, idOfArms, idOfLegs, idOfWeapon);
        _transfer(address(0), msg.sender, newRobotId++);
    }
}


contract RobotFight is RobotCollection {
    // fight with another robot returns 1 if win and 0 otherwise
    event Fight(uint256 winner, uint256 loser);
    event FightApproval(uint256 tokenId, uint256 _address);
    function approveToFight(uint256 yourRobotId, uint256 opponentRobotId) external
    {
        require(_owns(msg.sender, yourRobotId));
        robotIdToApprovedToFight[yourRobotId] = opponentRobotId;
    }
    function declineFightApproval(uint256 yourRobotId) external
    {
        require(_owns(msg.sender, yourRobotId));
        robotIdToApprovedToFight[yourRobotId] = 0;
    }

    function endFight(uint256 winnerId, uint256 loserId) private
    {
        robots[winnerId].wins++;
        robots[winnerId].xp += 5;
        robots[loserId].loses++;
        robots[loserId].xp += 2;
        emit Fight(winnerId, loserId);
    }

    function fight(uint256 idOfRed, uint256 idOfBlue) public returns (bool)
    {
        require(gasleft() >= 600000);
        require(idOfBlue != 0);
        require(idOfRed != 0);
        require(idOfBlue != idOfRed);
        require(_owns(msg.sender, idOfRed));
        require(robotIdToApprovedToFight[idOfBlue] == idOfRed && robotIdToApprovedToFight[idOfRed] == idOfBlue);
        robotIdToApprovedToFight[idOfBlue] = 0;
        robotIdToApprovedToFight[idOfRed] = 0;
        Robot memory red = robots[idOfRed];
        Robot memory blue = robots[idOfBlue];
        
        // UR - unstable rate
        uint256 blueUR = blue.attack/2;
        uint256 redUR = red.attack/2;
        if(blueUR == 0)
        {
            blueUR = 1;
        }
        if(redUR == 0)
        {
            redUR = 1;
        }

        
        while(red.health > 0 && blue.health > 0)
        {
            if(random(blue.agility + red.agility) < blue.agility)
            {
                blue.health -= int256(red.attack + random(redUR));
                if(blue.health <= 0)
                {
                    endFight(idOfRed, idOfBlue);
                    return true;
                }
                red.health -= int256(blue.attack + random(blueUR));
            }
            else
            {
                red.health -= int256(blue.attack + random(blueUR));
                if(red.health <= 0)
                {
                    endFight(idOfBlue, idOfRed);
                    return false;
                }
                blue.health -= int256(red.attack + random(redUR));
            }
        }

        if(red.health <= 0)
        {
            endFight(idOfBlue, idOfRed);
            return false;
        }
        else
        {
            endFight(idOfRed, idOfBlue);
            return true;
        }
        
    }
    //TODO allowance
    function hardcoreBattleWith(uint256 idOfRed, uint256 idOfBlue) external
    {
        if(fight(idOfRed, idOfBlue) == true)
        {
            _destroyRobot(idOfBlue);
        }
        else
        {
            _destroyRobot(idOfRed);
        }
    }
}

contract MobFarm is RobotFight
{
    event MobFight(uint256 robotId, uint256 difficulty, bool win);
    function endFight(uint256 difficulty, uint256 robotId, bool result) private
    {
        uint256 xp;
        if(difficulty == 0)
        {
            xp = 1;
        }
        else if(difficulty == 1)
        {
            xp = 3;
        }
        else if(difficulty == 2)
        {
            xp = 5;
        }
        else if(difficulty == 3)
        {
            xp = 10;
        }
        else if(difficulty == 4)
        {
            xp = 15;
        }
        if(result == true)
        {
            robots[robotId].mobsDefeated++;
            robots[robotId].xp += xp;
        }
        else
        {
            if(difficulty < 3)
            {
                robots[robotId].xp += xp/2;
            }
            else
            {
                robots[robotId].xp += xp/4;
            }
        }
        emit MobFight(robotId, difficulty, result);
        // emit event
    }
    //0 - easy
    //1 - normal
    //2 - hard
    //3 - insane
    //4 - extra
    function fightWIthMob(uint256 difficulty, uint256 yourRobotId) external
    {
        require(_owns(msg.sender, yourRobotId));
        Robot memory mob = robots[yourRobotId];
        Robot memory robot = robots[yourRobotId];
        if(difficulty == 0)
        {
            mob.attack -= 1;
            mob.max_health -= 5;
            mob.health -= 5;
        }
        else if(difficulty == 1)
        {
            mob.attack -= 1;
        }
        else if(difficulty == 3)
        {
            mob.health += 5;
            mob.attack += 1;
        }
        else if(difficulty == 4)
        {
            mob.attack += 2;
            mob.health += 10;
        }

        uint256 mobUR = mob.attack;
        uint256 robotUR = robot.attack;
        
        while(mob.health > 0 && robot.health > 0)
        {
            if(random(mob.agility + robot.agility - 1) < mob.agility)
            {
                robot.health -= int256(mob.attack + random(mobUR));
                if(robot.health <= 0)
                {
                    break;
                }
                mob.health -= int256(robot.attack + random(robotUR));
            }
            else
            {
                mob.health -= int256(robot.attack + random(robotUR));
                if(mob.health <= 0)
                {
                    break;
                }
                robot.health -= int256(mob.attack + random(mobUR));
            }
        }
        if(robot.health <= 0)
        {
            endFight(difficulty, yourRobotId, false);
        }
        else
        {
            endFight(difficulty, yourRobotId, true);
        }
    }
    
        
}


contract RobotUpgrade is MobFarm
{
    function upgradeHealth(uint256 robotId, uint256 amountOfHealth) external 
    {
        require(amountOfHealth != 0);
        require(robots[robotId].xp/amountOfHealth > 0); // 1xp = 1 hp
        robots[robotId].xp -= amountOfHealth;
        robots[robotId].health += int256(amountOfHealth);
        robots[robotId].max_health += amountOfHealth;
    }
    
    function udgradeAttack(uint256 robotId, uint256 amountOfAttack) external
    {
        require(amountOfAttack != 0);        
        require((10 * robots[robotId].xp)/amountOfAttack > 0); // 10xp = 1 att
        robots[robotId].xp -= 10 * amountOfAttack;
        robots[robotId].attack += amountOfAttack;
    }
    
    function upgradeAgility(uint256 robotId, uint256 amountOfAgility) external
    {
        require(amountOfAgility != 0);
        require(robots[robotId].xp/amountOfAgility > 0); // 1xp = 1 agl
        robots[robotId].xp -= amountOfAgility;
        robots[robotId].agility += amountOfAgility;
    }
}


contract RobotMain is RobotUpgrade
{
    uint256 public getComponentFee = 1 finney;
    uint256 public getRobotFee = 5 finney;

    function setFees(uint256 detailFeeInFinney) external
    {
        getComponentFee = detailFeeInFinney;
        require((5 * detailFeeInFinney) / 5 == detailFeeInFinney);
        getRobotFee = 5 * detailFeeInFinney;
    }

    function getStandardRobot() external payable
    {
        //require(tokenId <= totalRobots);
        //require(tokenId == 0 || robots[tokenId].dead == true);
        require(msg.value >= getRobotFee);
        uint256 tokenId = getRobot(25, 250, 25);
        _transfer(address(0), msg.sender, tokenId);
    }
    
    event ComponentTransfer(address from, address to, uint256 previousId, uint256 newId);
    function getStandardComponent(uint256 dType) external payable
    {
        require(msg.value >= getComponentFee);
        uint256 idOfComponent = getComponent(dType, 5, 5, 50);
        emit ComponentTransfer(address(0), msg.sender, 0, idOfComponent);
    }

    function withdrawAll() external onlyOwner
    {
        owner.transfer(address(this).balance);
    }

    function robotInfo(uint256 robotId) external view 
    returns (uint256 attack,
    uint256 health,
    uint256 agility,
    uint256 wins,
    uint256 mobsDefeated,
    uint256 xp)
    {
        Robot storage current = robots[robotId];
        if(current.dead == true || robotId >= currentBackId)
        {
            return (0, 0, 0, 0, 0, 0);
        }
        if(robotId == 0)
        {
            return (999999, 999999, 999999, 0, 0, 1100100);
        }
        attack = current.attack;
        health = current.max_health;
        agility = current.agility;
        mobsDefeated = current.mobsDefeated;
        wins = current.wins;
        xp = current.xp;
        
    }
    function destroyRobot(uint256 robotId) public
    {
        require(_owns(msg.sender, robotId));
        _destroyRobot(robotId);
    }
}