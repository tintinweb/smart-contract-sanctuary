/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

/**
 *Submitted for verifiporoion at Etherscan.io on 2018-12-22
*/

pragma solidity ^0.4.25;

contract baseRule{
    struct Poro {
        uint32 level;
        uint32 damage;
        uint32 HP;
        uint32 defence;
        uint coolcountdown;
    }
    Poro boss = Poro(9999,9999,9999,9999,0);
    Poro[] internal poros;
    mapping (uint => address) internal poroToOwner;
    mapping (address => uint) internal ownerToPoro;
    modifier nonePoro(address requester) {
        require(poroToOwner[ownerToPoro[requester]]!=requester);
        _;
    }
    modifier isPlayer(address requester) {
        require(poroToOwner[ownerToPoro[requester]]==requester,"Please adopt your poro first.");
        _;
    }
    function _triggerCoolCountDown(uint poroID) internal{
        poros[poroID].coolcountdown = block.timestamp + 20 seconds;
    }
    function _fight(uint poroID,Poro poroTarget) internal returns(bool) {
        require(poros[poroID].coolcountdown <= block.timestamp,"Your poro is having a rest!!");

        uint64 poroTotalCE = poros[poroID].level*poros[poroID].damage + poros[poroID].HP/2 + poros[poroID].defence/2;
        uint64 targetTotalCE = poroTarget.level*poroTarget.damage + poroTarget.HP/2 + poroTarget.defence/2;
        bool result;
        if(poroTotalCE < targetTotalCE) {

            if(poroTarget.level!=9999) {
                poros[poroID].damage = poros[poroID].damage - poroTarget.damage/2;
                result = false;
            }
        } else {


            poros[poroID].level = poros[poroID].level + poroTarget.level;
            poros[poroID].damage = poros[poroID].damage + poroTarget.damage;
            poros[poroID].HP = poros[poroID].HP + poroTarget.HP;
            poros[poroID].defence = poros[poroID].defence + poroTarget.defence;
            result = true;
        }

        _triggerCoolCountDown(poroID);
        return result;
    }
    event vactory(string b64email,string slogan);
}


contract poroStore is baseRule {

    function adoptPoro() external nonePoro(msg.sender) {

        uint32 randDamage = uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"damage")))%40 + 59;
        uint32 randHP = uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"HP")))%40 + 59;
        uint32 randDefence = uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"defence")))%40 + 59;

        uint id = poros.push(Poro(1,randDamage,randHP,randDefence,block.timestamp)) - 1;
        poroToOwner[id] = msg.sender;
        ownerToPoro[msg.sender] = id;
    } 

    function _createRandomMonster(uint32 strengthenIndex) internal view returns(uint32,uint32,uint32,uint32) {
        uint32 monsterLevel = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"level")))%5 + 1);
        uint32 monsterDamage = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"damage")))%50 + 9);
        uint32 monsterHP = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"HP")))%50 + 9);
        uint32 monsterDefence = strengthenIndex*(uint32(keccak256(abi.encodePacked(block.timestamp,msg.sender,"defence")))%50 + 9);
        return (monsterLevel,monsterDamage,monsterHP,monsterDefence);
    }
}


contract variant_of_poro is poroStore {
    bool fightWithBoss = false;

    function fightEtherMonster() external isPlayer(msg.sender) returns(bool) {
        uint32 strengthenIndex = 1;
        Poro memory etherMonster;
        (etherMonster.level,etherMonster.damage,etherMonster.HP,etherMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToPoro[msg.sender],etherMonster);
    }

    function fightZeroMonster() external isPlayer(msg.sender) returns(bool) {
        uint32 strengthenIndex = 4;
        Poro memory zeroMonster;
        (  zeroMonster.level,zeroMonster.damage, zeroMonster.HP,  zeroMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToPoro[msg.sender],  zeroMonster);
    }

    function fightAsuriMonster() external isPlayer(msg.sender) returns(bool) {
        uint32 strengthenIndex = 16;
        Poro memory asuriMonster;
        (asuriMonster.level,asuriMonster.damage,asuriMonster.HP,asuriMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToPoro[msg.sender],asuriMonster);
    }

    function fightBoss() external isPlayer(msg.sender) returns(bool){
        fightWithBoss = _fight(ownerToPoro[msg.sender],boss);
        return fightWithBoss;
    }

    function getFlag(string b64email) external {

        require(fightWithBoss == true, "little boy, Don't you put poro's king in your eyes?");
        require(keccak256(abi.encodePacked(b64email))!=keccak256(""),"gie gie, your flag is sending ~");
        emit vactory(b64email, "get flag!");
    }

    function luPoro() constant isPlayer(msg.sender) external returns(uint32,uint32,uint32,uint32,uint,uint) {
        return (
            poros[ownerToPoro[msg.sender]].level,
            poros[ownerToPoro[msg.sender]].damage,
            poros[ownerToPoro[msg.sender]].HP,
            poros[ownerToPoro[msg.sender]].defence,

            poros[ownerToPoro[msg.sender]].level*poros[ownerToPoro[msg.sender]].damage + poros[ownerToPoro[msg.sender]].HP/2 + poros[ownerToPoro[msg.sender]].defence/2,

            boss.level*boss.damage + boss.HP/2 + boss.defence/2
        );
    }

    function deleteMyPoro() external isPlayer(msg.sender) {
        delete poroToOwner[ownerToPoro[msg.sender]];
        delete poros[ownerToPoro[msg.sender]];
        delete ownerToPoro[msg.sender];
    }
}