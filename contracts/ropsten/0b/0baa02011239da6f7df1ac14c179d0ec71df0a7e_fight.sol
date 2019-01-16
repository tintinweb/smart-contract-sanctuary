pragma solidity ^0.4.25;

contract baseRule{
    struct Cat {
        uint32 level;
        uint32 damage;
        uint32 HP;
        uint32 defence;
        uint coolcountdown;
    }
    Cat boss = Cat(9999,9999,9999,9999,0);
    Cat[] internal cats;
    mapping (uint => address) internal catToOwner;
    mapping (address => uint) internal ownerToCat;
    modifier noneCat(address requester) {
        require(catToOwner[ownerToCat[requester]]!=requester);
        _;
    }
    modifier existCat(uint cat) {
        require(catToOwner[cat]!=0);
        _;
    }
    modifier isPlayer(address requester) {
        require(catToOwner[ownerToCat[requester]]==requester);
        _;
    }
    function _triggerCoolCountDown(uint catID) internal{
        cats[catID].coolcountdown = block.timestamp + 15 seconds;
    }
    function _fight(uint catID,Cat catTarget) existCat(catID) internal returns(bool) {
        require(cats[catID].coolcountdown <= block.timestamp,"Your cat is having a rest!!");
        uint64 catTotalCE = cats[catID].level*cats[catID].damage + cats[catID].HP/2 + cats[catID].defence/2;
        uint64 targetTotalCE = catTarget.level*catTarget.damage + catTarget.HP/2 + catTarget.defence/2;
        bool result;
        if(catTotalCE >= targetTotalCE) {
            //vactory reward
            cats[catID].level = cats[catID].level + catTarget.level;
            cats[catID].damage = cats[catID].damage + catTarget.damage;
            cats[catID].HP = cats[catID].HP + catTarget.HP;
            cats[catID].defence = cats[catID].defence + catTarget.defence;
            result = true;
        } else {
            cats[catID].damage = cats[catID].damage - catTarget.damage/2;
            result = false;
        }
        _triggerCoolCountDown(catID);
        return result;
    }
    event vactory(string b64email,string slogan);
}

contract catStore is baseRule {
    function adoptCat() external noneCat(msg.sender) returns(address) {
        uint32 randDamage = uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"damage")))%40 + 59;
        uint32 randHP = uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"HP")))%40 + 59;
        uint32 randDefence = uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"defence")))%40 + 59;
        uint id = cats.push(Cat(1,randDamage,randHP,randDefence,block.timestamp)) - 1;
        catToOwner[id] = msg.sender;
        ownerToCat[msg.sender] = id;
        return msg.sender;
    } 
    function _createRandomMonster(uint32 strengthenIndex) internal view returns(uint32,uint32,uint32,uint32) {
        uint32 monsterLevel = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"level")))%5 + 1);
        uint32 monsterDamage = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"damage")))%50 + 9);
        uint32 monsterHP = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"HP")))%50 + 9);
        uint32 monsterDefence = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"defence")))%50 + 9);
        return (monsterLevel,monsterDamage,monsterHP,monsterDefence);
    }
}

contract fight is catStore {
    bool fightWithBoss = false;
    function fightAlphaMonster() external isPlayer(msg.sender) returns(bool) {
        uint32 strengthenIndex = 1;
        Cat memory alphaMonster;
        (alphaMonster.level,alphaMonster.damage,alphaMonster.HP,alphaMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToCat[msg.sender],alphaMonster);
    }

    function fightBetaMonster() external isPlayer(msg.sender) returns(bool) {
        uint32 strengthenIndex = 4;
        Cat memory betaMonster;
        (betaMonster.level,betaMonster.damage,betaMonster.HP,betaMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToCat[msg.sender],betaMonster);
    }

    function fightAsuriMonster() external isPlayer(msg.sender) returns(bool) {
        uint32 strengthenIndex = 16;
        Cat memory asuriMonster;
        (asuriMonster.level,asuriMonster.damage,asuriMonster.HP,asuriMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToCat[msg.sender],asuriMonster);
    }

    function fightBoss() external isPlayer(msg.sender) returns(bool){
        fightWithBoss = _fight(ownerToCat[msg.sender],boss);
        return fightWithBoss;
    }
    function getFlag(string b64email) external {
        require(keccak256(abi.encodePacked(b64email))!=keccak256(""),"flag不要了吗?");
        require(fightWithBoss == true,"OOOOhhhh nnnnoooo,小老弟?你不把我猫王之王放在眼里-_-||");
        emit vactory(b64email, "6666!");
    }
    function luCat() view existCat(ownerToCat[msg.sender]) external returns(uint32,uint32,uint32,uint32,uint,uint,uint) {
        return (
            cats[ownerToCat[msg.sender]].level,
            cats[ownerToCat[msg.sender]].damage,
            cats[ownerToCat[msg.sender]].HP,
            cats[ownerToCat[msg.sender]].defence,
            cats[ownerToCat[msg.sender]].coolcountdown,
            cats[ownerToCat[msg.sender]].level*cats[ownerToCat[msg.sender]].damage + cats[ownerToCat[msg.sender]].HP/2 + cats[ownerToCat[msg.sender]].defence/2,
            boss.level*boss.damage + boss.HP/2 + boss.defence/2
        );
    }
}