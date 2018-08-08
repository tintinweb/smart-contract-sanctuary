pragma solidity ^0.4.18;

contract Ownable 
{
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // rewrite constructor depends on architecture
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
    function totalSupply() public view returns (uint256 total);//
    function balanceOf(address _owner) public view returns (uint256 balance);//
    function ownerOf(uint256 _tokenId) external view returns (address owner);//
    function approve(address _to, uint256 _tokenId) external;//
    function transfer(address _to, uint256 _tokenId) external;//
    function transferFrom(address _from, address _to, uint256 _tokenId) external;//

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
    uint256 private primeNumber = 4099;

    function bytesToUint256(bytes data) private pure returns (uint256 res)
    {
        assembly
        {
            res := mload(add(data, 0x20))
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
        if(current < 10000)
        {
            return current;
        }
        else
        {
            return current = 4099;
        }
    }
    function random(uint256 modulo) internal returns (uint256)
    {
        // to control random you need:
        // 1) mine block with this tx and set perfect values for you
        // 2) know current prime number in contract
        // 3) perfectly calculate gas
        // good luck
        primeNumber = nextPrime(primeNumber); 
        return ((bytesToUint256(abi.encodePacked(primeNumber)) ^
        bytesToUint256(abi.encodePacked(gasleft())) ^
        bytesToUint256(abi.encodePacked(block.difficulty)) ^
        bytesToUint256(abi.encodePacked(block.timestamp))) % primeNumber) % (modulo + 1);
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

contract RobotBase is Ownable {
    
    enum ComponentTypes  {Head, Body, Arms, Legs, Weapon} 

    uint256 internal totalRobots = 0;
    uint256 internal currentBackId = 1;

    struct Component {
        ComponentTypes dtype;
        uint256 agility;
        uint256 attack;
        uint256 health;
        uint256 usedByRobotId;
    }

    struct Robot {
        uint256 attack;
        uint256 max_health;
        int     health;
        uint256 stamina;//TODO: current & max
        uint256 agility;
        uint256 ability;
        uint256 element;
        uint256 wins;
        uint256 loses;
        bool dead;
    }  

    mapping (uint256 => Robot) robots;

    mapping (address => mapping(uint256 => Component)) ownerToComponents;

    mapping (uint256 => address) robotIdToOwner;
    mapping (uint256 => uint256) robotIdToApprovedToFight;
    mapping (uint256 => address) robotIdToApproved;
    mapping (address => uint256) ownerToNumberOfRobots;

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

    
    function _destroyRobot(uint256 robotId) internal
    {
        robots[robotId].dead = true;
        totalRobots--;
    }
    
}

contract RobotOwnership is RobotBase, ERC721, Pausable
{
    string public constant name = "Robots";
    string public constant symbol = "RB";

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerToNumberOfRobots[_to]++;
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
        //whenNotPaused
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
        //whenNotPaused
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
        //whenNotPaused
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


}

contract RobotCollection is RobotOwnership {
    function collectRobot(uint256 idOfHead, uint256 idOfBody, uint256 idOfArms, uint256 idOfLegs, uint256 idOfWeapon) external
    {
        Robot memory robot;
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

        require(head.usedByRobotId == 0);
        require(body.usedByRobotId == 0);
        require(arms.usedByRobotId == 0);
        require(legs.usedByRobotId == 0);
        require(weapon.usedByRobotId == 0);

        robot.attack = head.attack + body.attack + arms.attack + legs.attack + weapon.attack;
        robot.max_health = head.health + body.health + arms.health + legs.health + weapon.health;
        robot.agility = head.agility + body.agility + arms.agility + legs.agility + weapon.agility;
        robots[currentBackId] = robot;
        head.usedByRobotId = currentBackId;
        body.usedByRobotId = currentBackId;
        arms.usedByRobotId = currentBackId;
        legs.usedByRobotId = currentBackId;
        weapon.usedByRobotId = currentBackId;
        _transfer(address(0), msg.sender, currentBackId++);
        //robot. = head. + body. + arms. + legs. + weapon.;
    }
}

//contract RobotUpgrade is RobotBase {}

contract RobotFight is RobotCollection, Random {
    // fight with another robot returns 1 if win and 0 otherwise
    event Fight(uint256 winner, uint256 loser);
    function approveToFight(uint256 yourRobotId, uint256 opponentRobotId) external
    {
        require(_owns(msg.sender, yourRobotId));
        robotIdToApprovedToFight[yourRobotId] = opponentRobotId;
    }
    function declineApproval(uint256 yourRobotId) external
    {
        require(_owns(msg.sender, yourRobotId));
        robotIdToApprovedToFight[yourRobotId] = 0;
    }
    function fight(uint256 idOfRed, uint256 idOfBlue) public returns (bool)
    {
        require(idOfBlue != 0);
        require(idOfRed != 0);
        require(idOfBlue != idOfRed);
        require(_owns(msg.sender, idOfRed));
        require(robotIdToApprovedToFight[idOfBlue] == idOfRed && robotIdToApprovedToFight[idOfRed] == idOfBlue);
        robotIdToApprovedToFight[idOfBlue] = 0;
        robotIdToApprovedToFight[idOfRed] == 0;
        Robot storage red = robots[idOfRed];
        Robot storage blue = robots[idOfBlue];
        
        // UR - unstable rate
        uint256 blueUR = blue.attack/3;
        uint256 redUR = red.attack/3;
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
                    red.wins++;
                    blue.loses++;
                    //restoring health at this stage of development
                    blue.health = int256(blue.max_health);
                    red.health = int256(red.max_health);
                    emit Fight(idOfRed, idOfBlue);
                    return true;
                }
                red.health -= int256(blue.attack + random(blueUR));
            }
            else
            {
                red.health -= int256(blue.attack + random(blueUR));
                if(red.health <= 0)
                {
                    red.loses++;
                    blue.wins++;
                    //restoring health at this stage of development
                    blue.health = int256(blue.max_health);
                    red.health = int256(red.max_health);
                    emit Fight(idOfBlue, idOfRed);
                    return false;
                }
                blue.health -= int256(red.attack + random(redUR));
            }
        }
        if(red.health <= 0)
        {
            red.loses++;
            blue.wins++;
            //restoring health at this stage of development
            blue.health = int256(blue.max_health);
            red.health = int256(red.max_health);
            emit Fight(idOfBlue, idOfRed);
            return false;
        }
        else
        {
            blue.loses++;
            red.wins++;
            //restoring health at this stage of development
            blue.health = int256(blue.max_health);
            red.health = int256(red.max_health);
            emit Fight(idOfRed, idOfBlue);
            return true;
        }
        
    }
    //TODO allowance
    function hardcoreBattleWith(uint256 idOfRed, uint256 idOfBlue) external returns (bool)
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


contract RobotMain is RobotFight {

    /*constructor() public
    {
        /*Robot memory newRobot = Robot({
            attack : 999999,
            max_health : 999999,
            health : 0,
            stamina : 0,
            agility : 999999,
            ability : 0,
            element : 0,
            wins : 0,
            loses : 0,
            dead : false
        });
        totalRobots++;
        robots[currentBackId] = newRobot;
        //_transfer(address(0), this, currentBackId++);
    }*/

    function getStandartRobot(uint256 tokenId) external
    {
        require(tokenId <= totalRobots);
        require(tokenId == 0 || robots[tokenId].dead == true);
        Robot memory newRobot = Robot({
            attack : 25,//9 + random(2),
            max_health : 250,//90 + random(20),
            health : 0,
            stamina : 0,
            agility : 25,//5 + random(10),
            ability : 0,
            element : 0,
            wins : 0,
            loses : 0,
            dead : false
        });
        newRobot.health = int256(newRobot.max_health);
        totalRobots++;
        if(tokenId == 0)
        {
            robots[currentBackId] = newRobot;
            _transfer(address(0), msg.sender, currentBackId++);
        }
        else
        {
            robots[tokenId] = newRobot;
            _transfer(address(0), msg.sender, tokenId);
        }
            

    }
    function getStandartComponent(uint256 idOfComponent, uint256 dType) external
    {
        require(ownerToComponents[msg.sender][idOfComponent].usedByRobotId == 0);
        Component memory newComponent = Component({
            dtype : ComponentTypes(dType),
            agility : 5,
            attack : 5,
            health : 50,
            usedByRobotId : 0
        });
        ownerToComponents[msg.sender][idOfComponent] = newComponent;
    }

    function robotInfo(uint256 robotId) external view returns(uint256 attack, uint256 health, uint256 agility, uint256 winPercentage)
    {
        Robot storage current = robots[robotId];
        if(current.dead == true || robotId >= currentBackId)
        {
            return (0, 0, 0, 0);
        }
        if(robotId == 0)
        {
            return (999999, 999999, 999999, 1100100);
        }
        attack = current.attack;
        health = current.max_health;
        agility = current.agility;
        if(current.wins + current.loses > 0)
        {
            winPercentage = (100 * current.wins) / (current.wins + current.loses);
        }
        else
        {
            winPercentage = 100;
        }
        
    }
    function destroyRobot(uint256 robotId) public
    {
        require(_owns(msg.sender, robotId));
        _destroyRobot(robotId);
    }
}