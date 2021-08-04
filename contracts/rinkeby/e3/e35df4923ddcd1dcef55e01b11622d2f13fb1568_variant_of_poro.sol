/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.5.10;

contract baseRule{
    struct Poro {
        uint level;
        uint damage;  //损害
        uint HP;
        uint defence;  //防御
        uint coolcountdown;   //冷却倒计时
    }
    Poro boss = Poro(9999,9999,9999,9999,0);
    Poro[] public poros;   //结构体数组
    mapping (uint => address) internal poroToOwner;
    mapping (address => uint) internal ownerToPoro;
    modifier nonePoro(address requester) {
        require(poroToOwner[ownerToPoro[requester]]!=requester, "You already have a poro!");
        _;
    }
    modifier isPlayer(address requester) {
        require(poroToOwner[ownerToPoro[requester]]==requester,"Please adopt your poro first.");
        _;
    }
    function _triggerCoolCountDown(uint poroID) internal{
        poros[poroID].coolcountdown = block.timestamp + 10 seconds;
    }
    function _fight(uint poroID,Poro memory poroTarget) internal returns(bool) {
        require(poros[poroID].coolcountdown <= block.timestamp,"Your poro is having a rest!!");

        uint poroTotalCE = poros[poroID].level*poros[poroID].damage + poros[poroID].HP/2 + poros[poroID].defence/2;
        uint targetTotalCE = poroTarget.level*poroTarget.damage + poroTarget.HP/2 + poroTarget.defence/2;
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
}


contract poroStore is baseRule {

    function adoptPoro() external nonePoro(msg.sender) {
        uint randDamage = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"damage")))%40 + 59;
        uint randHP = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"HP")))%40 + 59;
        uint randDefence = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"defence")))%40 + 59;
        uint id = poros.push(Poro(1,randDamage,randHP,randDefence,block.timestamp)) - 1;
        poroToOwner[id] = msg.sender;
        ownerToPoro[msg.sender] = id;
    }

    function _createRandomMonster(uint strengthenIndex) internal view returns(uint,uint,uint,uint) {
        uint monsterLevel = strengthenIndex*(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"level")))%5 + 1);
        uint monsterDamage = strengthenIndex*(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"damage")))%50 + 9);
        uint monsterHP = strengthenIndex*(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"HP")))%50 + 9);
        uint monsterDefence = strengthenIndex*(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,"defence")))%50 + 9);
        return (monsterLevel,monsterDamage,monsterHP,monsterDefence);
    }
}


contract variant_of_poro is poroStore {
    bool public fightWithBoss = false;

    function fightEtherMonster() external isPlayer(msg.sender) returns(bool) {
        uint strengthenIndex = 1;
        Poro memory etherMonster;
        (etherMonster.level,etherMonster.damage,etherMonster.HP,etherMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToPoro[msg.sender],etherMonster);
    }

    function fightZeroMonster() external isPlayer(msg.sender) returns(bool) {
        uint strengthenIndex = 4;
        Poro memory zeroMonster;
        (  zeroMonster.level,zeroMonster.damage, zeroMonster.HP,  zeroMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToPoro[msg.sender],  zeroMonster);
    }

    function fightAsuriMonster() external isPlayer(msg.sender) returns(bool) {
        uint strengthenIndex = 16;
        Poro memory asuriMonster;
        (asuriMonster.level,asuriMonster.damage,asuriMonster.HP,asuriMonster.defence) = _createRandomMonster(strengthenIndex);
        return _fight(ownerToPoro[msg.sender],asuriMonster);
    }

    function fightBoss() external isPlayer(msg.sender) returns(bool){
        fightWithBoss = _fight(ownerToPoro[msg.sender],boss);
        return fightWithBoss;
    }

    function luPoro() view isPlayer(msg.sender) external returns(uint,uint,uint,uint,uint,uint) {
        return (
        poros[ownerToPoro[msg.sender]].level,
        poros[ownerToPoro[msg.sender]].damage,
        poros[ownerToPoro[msg.sender]].HP,
        poros[ownerToPoro[msg.sender]].defence,

        poros[ownerToPoro[msg.sender]].level*poros[ownerToPoro[msg.sender]].damage + poros[ownerToPoro[msg.sender]].HP/2 + poros[ownerToPoro[msg.sender]].defence/2,

        boss.level*boss.damage + boss.HP/2 + boss.defence/2
        );
    }

    function isWin() public view returns(bool){
        return fightWithBoss;
    }

    function deleteMyPoro() external isPlayer(msg.sender) {
        delete poroToOwner[ownerToPoro[msg.sender]];
        delete poros[ownerToPoro[msg.sender]];
        delete ownerToPoro[msg.sender];
    }
}