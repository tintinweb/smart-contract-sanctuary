/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view virtual returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view virtual returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public virtual;
  function approve(address _to, uint256 _tokenId) public virtual;
  function takeOwnership(uint256 _tokenId) public virtual;
}

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;
contract zombieFactory is Ownable{
    event Newzombie(uint zombieId,uint rare,uint energy,uint typeID,string _typeName);
    uint  cooldownTime = 60; //rare 5 cooldownTime
    uint public zombiePrice = 1*10**10;
    uint public minPrice = 1*10**10;
    uint  mintax = 1*10**10;
    uint  marketFee = 6;
    uint  pveReward = 1*10**10;
    struct Mythicalcreatures{
        string typeName;
    }

    struct Zombie{
        uint zombieId;
        uint32 typeID;
        uint32 attributeID;
        uint32 rare;
        uint32 energy;
        uint32 level;
        uint32 readyForPVETime;
        uint32 readyForPVPTime;
        uint32 isMarketing;
        uint32 isBattling;
        uint32 winCount;
        string name;
        string typeName;
    }
    struct Boss{
        uint32 bossId;
        uint32 typeId;
        uint32 attributeID;
        uint32 rare;
        uint32 isready;
        uint32 reward;
        uint32 level;
        uint32 energy;
        string name;
    }

    struct ZombieType{
        uint32 typeId;
        uint32 rare;
        string typeName;
    }
    Boss[] public boss;
    Zombie[] public zombies;
    ZombieType[] public zombieTypesRareOne;
    ZombieType[] public zombieTypesRareTwo;
    ZombieType[] public zombieTypesRareThree;
    ZombieType[] public zombieTypesRareFour;
    ZombieType[] public zombieTypesRareFive;
    mapping(uint=>address) public zombieToOwner;
    mapping(address=>uint) public ownerZombieCount;
    //mapping(uint=>string)  public mythicalcreaturesToName;
    uint public typeCount;
    uint public zombieCount;
    uint modules =500;
    uint  randNonce;
    function _randMod(uint _modules, uint _targetCount) public returns(uint){
        randNonce++;
        return  modules =(uint(keccak256(abi.encodePacked(_modules+1,block.timestamp,_msgSender(),randNonce))) % _targetCount)+1;
    }



    function _createZombieType(uint32 _typeId,uint32 _rare,string memory _typeName) public onlyOwner  {
        //uint _typeId = zombieTypes.length-1;
        if(_rare ==1){
            zombieTypesRareOne.push(ZombieType(_typeId,_rare,_typeName));
        }
        if(_rare ==2){
            zombieTypesRareTwo.push(ZombieType(_typeId,_rare,_typeName));
        }
        if(_rare ==3){
            zombieTypesRareThree.push(ZombieType(_typeId,_rare,_typeName));
        }
        if(_rare ==4){
            zombieTypesRareFour.push(ZombieType(_typeId,_rare,_typeName));
        }
        if(_rare ==5){
            zombieTypesRareFive.push(ZombieType(_typeId,_rare,_typeName));
        }
        typeCount = zombieTypesRareOne.length+zombieTypesRareTwo.length+zombieTypesRareThree.length+zombieTypesRareFour.length+zombieTypesRareFive.length;
    }
    function _createBoss(uint32 _Id,uint32 _typeId, uint32 _attributeId,uint32 _rare,uint32 _isready,uint32 _reward,uint32 _level, uint32 _energy,string memory _name) public  onlyOwner{
        boss.push(Boss(_Id,_typeId,_attributeId,_rare,_isready,_reward,_level,_energy,_name));

    }
    function _resetBoss(uint32 _Id,uint32 _isready,uint32 _reward) public onlyOwner{
        boss[_Id].isready = _isready;
        boss[_Id].reward = _reward;
    }
    function _getRare(uint _rand) public  pure returns(uint){
        uint _rare;
        if(_rand<=400){
            _rare = 1;
        }
        if(_rand >400 && _rand<=690){
            _rare = 2;
        }
        if(_rand >690 && _rand<=890){
            _rare = 3;
        }
        if(_rand>890 && _rand<=990){
            _rare = 4;
        }
        if(_rand>990 && _rand<=1000){
            _rare = 5;
        }
        return _rare;
    }
    function _getTypeId(uint32 _rare) public   returns(uint32,string memory){
        require(_rare >=1 && _rare <=5, "error here!");
        uint32 _typeId;
        string memory _typeName;
        if(_rare ==1){
            _typeId = zombieTypesRareOne[_randMod(modules,zombieTypesRareOne.length)-1].typeId;
            _typeName = zombieTypesRareOne[_randMod(modules,zombieTypesRareOne.length)-1].typeName;
        }
        if(_rare ==2){
            _typeId = zombieTypesRareTwo[_randMod(modules,zombieTypesRareTwo.length)-1].typeId;
            _typeName = zombieTypesRareTwo[_randMod(modules,zombieTypesRareTwo.length)-1].typeName;
        }
        if(_rare ==3){
            _typeId = zombieTypesRareThree[_randMod(modules,zombieTypesRareThree.length)-1].typeId;
            _typeName = zombieTypesRareThree[_randMod(modules,zombieTypesRareThree.length)-1].typeName;
        }
        if(_rare ==4){
            _typeId = zombieTypesRareFour[_randMod(modules,zombieTypesRareFour.length)-1].typeId;
            _typeName = zombieTypesRareFour[_randMod(modules,zombieTypesRareFour.length)-1].typeName;
        }
        if(_rare ==5){
            _typeId = zombieTypesRareFive[_randMod(modules,zombieTypesRareFive.length)-1].typeId;
            _typeName = zombieTypesRareFive[_randMod(modules,zombieTypesRareFive.length)-1].typeName;
        }
        return (_typeId,_typeName);
    }
    function _createZombie(string memory _name) public  {
        require(typeCount>0);
        uint _zombieId = zombies.length;
        uint32 _rand = uint32(_randMod(modules,1000));
        uint32 _rare = uint32(_getRare(_rand));
        uint32 _typeID ;
        uint32 _attributeID = uint32(_randMod(modules,5));
        //uint32 _rare = uint32(zombieTypes[_zombieId].rare);
        uint32 _energy = uint32(_randMod(modules,_rare*100)+_rare*100);
        string memory _typeName ;
        (_typeID,_typeName)= _getTypeId(_rare);
        zombies.push(Zombie(_zombieId,_typeID,_attributeID,_rare,_energy,0,0,0,0,0,0,_name,_typeName));
        zombieToOwner[_zombieId] = _msgSender();
        ownerZombieCount[_msgSender()] = ownerZombieCount[_msgSender()]+1;
        zombieCount = zombieCount+1;
        emit Newzombie(_zombieId,_rare,_energy,_typeID,_typeName);
    }
    function buyZombie(string memory _name) public payable{
        require (msg.value >= zombiePrice);
        _createZombie(_name);
    }
    function setZombiePrice(uint _price) external onlyOwner{
        zombiePrice = _price;
    }
}


pragma solidity ^0.8.0;
contract zombieHelper is zombieFactory{
    address  deadAddress = 0x000000000000000000000000000000000000dEaD;
    modifier onlyOwnerOf(uint _zombieId){
        require(_msgSender() == zombieToOwner[_zombieId]);
        _;
    }
    modifier multiplyOnlyOwnerOf(uint _zombieId, uint _targetId){
        require(_msgSender() == zombieToOwner[_zombieId] && _msgSender() == zombieToOwner[_targetId],'this zombie is not yours');
        _;
    }

    function levelUp(uint _zombieId) internal onlyOwnerOf(_zombieId){
        if(zombies[_zombieId].level < 300){
            zombies[_zombieId].level+1;
            zombies[_zombieId].energy++;
        }
        if(zombies[_zombieId].level >= 300){
            zombies[_zombieId].level = 300;
        }
    }
    function changeName(uint _zombieId, string calldata _newName)public onlyOwnerOf(_zombieId){
        zombies[_zombieId].name = _newName;
    }
    function getZombiesByOwner(address _owner)external view returns(uint[] memory ){
        uint[] memory results = new uint[](ownerZombieCount[_owner]);
        uint counter =0;
        for (uint i = 0;i<=zombies.length;i++){
            if(zombieToOwner[i] == _owner){
                results[counter] = i;
                counter++;
            }
        }
        return results;
    }
    function _triggerPVECooldown(Zombie memory _zombie) internal view {
        _zombie.readyForPVETime = uint32(block.timestamp + (cooldownTime/_zombie.rare)) ;
    }
    function _triggerPVPCooldown(Zombie memory _zombie) internal view {
        _zombie.readyForPVPTime = uint32(block.timestamp + (cooldownTime/_zombie.rare)) ;
    }
    function setPVECooldown(uint _zombieId) public onlyOwnerOf(_zombieId){
        zombies[_zombieId].readyForPVETime =uint32(block.timestamp + cooldownTime/zombies[_zombieId].rare) ;
    }
    function setPVPCooldown(uint _zombieId) public onlyOwnerOf(_zombieId){
        zombies[_zombieId].readyForPVPTime =uint32(block.timestamp + cooldownTime/zombies[_zombieId].rare) ;
    }
    function getPVECooldown(uint _zombieId) public view onlyOwnerOf(_zombieId) returns(uint){
        return zombies[_zombieId].readyForPVETime;
    }
    function getPVPCooldown(uint _zombieId) public view onlyOwnerOf(_zombieId) returns(uint){
        return zombies[_zombieId].readyForPVPTime;
    }

    function _isReadyForPVE(uint _zombieId) internal view returns (bool) {
      return (zombies[_zombieId].readyForPVETime <= block.timestamp);
    }

    function _isReadyForPVP(uint _zombieId) internal view returns (bool) {
      return (zombies[_zombieId].readyForPVPTime <= block.timestamp);
    }

    function fusionRare(uint32 _rareOne,uint32 _rareTwo) public returns(uint32){
        uint32 _Rare;
        if (_rareOne>_rareTwo){
            _Rare = _rareOne;
        }else{
            _Rare = _rareTwo;
        }
        uint32 _rare;
        uint32 _rand =uint32(_randMod(modules,100));
        if(_rareOne !=4 && _rareTwo != 4){
            if(_rand<2){
                _rare = _Rare+2;
            }
            if(_rand >=2 && _rand<(9-_Rare)*10+10){
                _rare = _Rare+1;
            }else{
                _rare =_Rare;
            }
        }
        if(_rareOne ==4 || _rareTwo == 4){
            if(_rand<(9-_Rare)*10+10){
                _rare =5;
            }else{
                _rare=4;
            }
        }
        return _rare;
    }

    function multiply(uint _zombieId, uint _targetId) public multiplyOnlyOwnerOf(_zombieId,_targetId) {
        require(zombies[_zombieId].rare<5 && zombies[_targetId].rare<5);
        Zombie storage myZombie = zombies[_zombieId];
        Zombie storage targetZombie = zombies[_targetId];
        require(myZombie.isBattling == 0 && myZombie.isMarketing ==0 && targetZombie.isBattling ==0 && targetZombie.isMarketing ==0  ,'Zombie is not ready');
        uint _newZombieId = zombies.length;
        uint32 _rare = fusionRare(myZombie.rare,targetZombie.rare);
        uint32 _typeID;
        uint32 _attributeID = uint32(_randMod(modules,5));
        uint32 _energy = uint32(_randMod(modules,_rare*100)+_rare*100);
        string memory _typeName ;
        (_typeID,_typeName)= _getTypeId(_rare);
        zombies.push(Zombie(_newZombieId,_typeID,_attributeID,_rare,_energy,0,0,0,0,0,0,"Noname",_typeName));
        zombieToOwner[_zombieId] = _msgSender();
        ownerZombieCount[_msgSender()] = ownerZombieCount[_msgSender()]+1;
        zombieCount = zombieCount+1;
        zombieToOwner[myZombie.zombieId] = deadAddress;
        zombieToOwner[targetZombie.zombieId] = deadAddress;
        ownerZombieCount[_msgSender()]--;
        emit Newzombie(_zombieId,_rare,_energy,_typeID,_typeName);
    }
}


pragma solidity ^0.8.0;
contract zombieOwnership is zombieHelper, ERC721 {
  mapping (uint => address) zombieApprovals;
  function balanceOf(address _owner) public view override returns (uint256 _balance) {
    return ownerZombieCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view override returns (address _owner) {
    return zombieToOwner[_tokenId];
  }
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownerZombieCount[_to] = ownerZombieCount[_to]+1;
    ownerZombieCount[_from] = ownerZombieCount[_from]-1;
    zombieToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public override onlyOwnerOf(_tokenId) {
    _transfer(_msgSender(), _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public override onlyOwnerOf(_tokenId) {
    zombieApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public override {
    require(zombieApprovals[_tokenId] == _msgSender());
    address owner = ownerOf(_tokenId);
    _transfer(owner, _msgSender(), _tokenId);
  }
}


pragma solidity ^0.8.0;
contract zombieMarket is zombieOwnership {
    struct zombieSales{
        address payable seller;
        uint price;
    }
    mapping(uint=>zombieSales) public zombieShop;
    uint shopzombieCount;
    event SaleZombie(uint indexed zombieId,address indexed seller);
    event BuyShopZombie(uint indexed zombieId,address indexed buyer,address indexed seller);
    function saleMyZombie(uint _zombieId,uint _price)public onlyOwnerOf(_zombieId){
        require(zombies[_zombieId].isBattling == 0 && zombies[_zombieId].isMarketing == 0);
        require(_price>=minPrice+mintax);
        zombieShop[_zombieId] = zombieSales(payable(_msgSender()),_price);
        shopzombieCount = shopzombieCount+1;
        zombies[_zombieId].isMarketing=1;
        emit SaleZombie(_zombieId,_msgSender());
    }
    function buyShopZombie(uint _zombieId)public payable{
        require(msg.value >= zombieShop[_zombieId].price,'No enough money');
        require(zombieShop[_zombieId].seller != _msgSender() ,'It is your zombie');
        _transfer(zombieShop[_zombieId].seller,_msgSender(), _zombieId);
        zombieShop[_zombieId].seller.transfer((msg.value *(100 - marketFee))/100) ;
        delete zombieShop[_zombieId];
        shopzombieCount = shopzombieCount-1;
        zombies[_zombieId].isMarketing = 0;
        emit BuyShopZombie(_zombieId,_msgSender(),zombieShop[_zombieId].seller);
    }
    function getShopZombies() external view returns(uint[] memory) {
        uint[] memory result = new uint[](shopzombieCount);
        uint counter = 0;
        for (uint i = 0; i < zombies.length; i++) {
            if (zombieShop[i].price != 0) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function setMarketFee(uint _value) public onlyOwner{
        marketFee = _value;
    }
    function setMinPrice(uint _value) public onlyOwner{
        minPrice = _value;
    }
}


pragma solidity ^0.8.0;
contract zombieBattlefiled is zombieOwnership {
     struct battlefieldJoiner{
        address payable joiner;
        uint caculateTime;
        uint isReadyForClaim;
        uint rewardProportion;
    }
    event JoinbattleField(uint indexed zombieId,address indexed joiner);
    event LeavebattleField(uint indexed zombieId,address indexed joiner);
    uint battleFieldCount;
    uint  battleReward = 1000;
    mapping(uint=>battlefieldJoiner) public battleField;
    function setBattleReward(uint _battleReward) public onlyOwner {
        battleReward = _battleReward;
    }

    function getReward(uint _zombieId) public view returns(uint){
        uint reward=((block.timestamp - battleField[_zombieId].caculateTime)*battleReward*zombies[_zombieId].energy*battleField[_zombieId].rewardProportion) / 100;
        return reward;
    }
    function claimTokens(uint _zombieId) public onlyOwnerOf(_zombieId){
        require(zombies[_zombieId].isBattling ==1);
        require(block.timestamp-battleField[_zombieId].caculateTime >86400,'Clamin tokens must be > 1days');
        payable(_msgSender()).transfer(getReward(_zombieId));
        battleField[_zombieId].caculateTime = block.timestamp;
    }

    function joinBattlefield(uint _zombieId)public onlyOwnerOf(_zombieId){
        require(zombies[_zombieId].isMarketing == 0 && zombies[_zombieId].isBattling == 0);
        battleField[_zombieId] = battlefieldJoiner(payable(_msgSender()),block.timestamp,0,100);
        zombies[_zombieId].isBattling =1;
        battleFieldCount = battleFieldCount+1;
        emit JoinbattleField(_zombieId,_msgSender());
    }
    function leaveBattlefield(uint _zombieId) public onlyOwnerOf(_zombieId){
        require(zombies[_zombieId].isMarketing == 0 && zombies[_zombieId].isBattling == 1);
        claimTokens(_zombieId);
        delete battleField[_zombieId];
        zombies[_zombieId].isBattling = 0;
        battleField[_zombieId].caculateTime = 0;
        battleFieldCount = battleFieldCount-1;
        emit LeavebattleField(_zombieId,_msgSender());
    }
    function getBattlefieldZombies() external view returns(uint[] memory) {
        uint[] memory result = new uint[](battleFieldCount);
        uint counter = 0;
        for (uint i = 0; i < zombies.length; i++) {
            if (battleField[i].caculateTime != 0) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

}

pragma solidity ^0.8.0;
contract zombieAttack is zombieHelper,zombieBattlefiled{
    uint  attacPlayerkVictoryProbability = 7000;
    uint  attacBosskVictoryProbability = 5000;
    function setAttackPlayerVictoryProbability(uint _attacPlayerkVictoryProbability)internal onlyOwner{
        attacPlayerkVictoryProbability = _attacPlayerkVictoryProbability;
    }
     function setAttackBossVictoryProbability(uint _attacBosskVictoryProbability)internal onlyOwner{
        attacBosskVictoryProbability = _attacBosskVictoryProbability;
    }
    function gettAttackPlayerVictoryProbability(uint _myZombieId, uint _targetId) internal view returns(uint){
        uint _attacPlayerkVictoryProbability = attacPlayerkVictoryProbability;
        if((zombies[_myZombieId].attributeID >zombies[_targetId].attributeID) && (zombies[_myZombieId].attributeID -zombies[_targetId].attributeID ==1)){
            _attacPlayerkVictoryProbability = _attacPlayerkVictoryProbability + 200;
        }
        if((zombies[_myZombieId].attributeID == 1) && zombies[_targetId].attributeID == 5){
            _attacPlayerkVictoryProbability = _attacPlayerkVictoryProbability + 200;
        }
        if((zombies[_myZombieId].energy>zombies[_targetId].energy)){
            _attacPlayerkVictoryProbability = _attacPlayerkVictoryProbability + (zombies[_myZombieId].energy - zombies[_targetId].energy);
        }
        if((zombies[_myZombieId].level>zombies[_targetId].level)){
            _attacPlayerkVictoryProbability = _attacPlayerkVictoryProbability + (zombies[_myZombieId].level - zombies[_targetId].level);
        }
        return _attacPlayerkVictoryProbability;
    }
    function gettAttackBossVictoryProbability(uint _myZombieId, uint _bossId) internal view returns(uint){
        uint _attacBosskVictoryProbability = attacBosskVictoryProbability;
        if((zombies[_myZombieId].attributeID > boss[_bossId].attributeID) && (zombies[_myZombieId].attributeID - boss[_bossId].attributeID == 1)){
            _attacBosskVictoryProbability = _attacBosskVictoryProbability + 200;
        }
        if((zombies[_myZombieId].attributeID == 1) && boss[_bossId].attributeID == 5){
            _attacBosskVictoryProbability = _attacBosskVictoryProbability + 200;
        }
        if((zombies[_myZombieId].energy>boss[_bossId].energy)){
            _attacBosskVictoryProbability = _attacBosskVictoryProbability + (zombies[_myZombieId].energy - boss[_bossId].energy);
        }
        if((zombies[_myZombieId].level>boss[_bossId].level)){
            _attacBosskVictoryProbability = _attacBosskVictoryProbability + (zombies[_myZombieId].level - boss[_bossId].level);
        }
        return _attacBosskVictoryProbability;
    }
    function attackPlayer(uint zombieId,uint _targetId)external onlyOwnerOf(zombieId) returns(bool){
        require(zombies[zombieId].isBattling == 1 && zombies[_targetId].isBattling == 1,'zombie is not in the battlefield');
        require(_msgSender() != zombieToOwner[_targetId] && _isReadyForPVE(zombies[zombieId].zombieId),'target zombie is yours');
        Zombie storage myZombie = zombies[zombieId];
        Zombie storage enemyZombie = zombies[_targetId];
        uint _attacPlayerkVictoryProbability = gettAttackPlayerVictoryProbability(myZombie.zombieId,enemyZombie.zombieId);
        uint _rand = _randMod(modules,10000);
        if(_rand<=_attacPlayerkVictoryProbability){
            myZombie.level++;
            myZombie.winCount++;
            _triggerPVPCooldown(myZombie);
            payable(_msgSender()).transfer((pveReward *(100 - marketFee))/100);
            battleField[zombieId].rewardProportion = battleField[zombieId].rewardProportion+enemyZombie.rare;
            if(battleField[_targetId].rewardProportion>50){
                battleField[_targetId].rewardProportion = battleField[_targetId].rewardProportion-enemyZombie.rare;
            }else{
                battleField[_targetId].rewardProportion = 50;
            }
            return true;
        }else{
            _triggerPVPCooldown(myZombie);
            battleField[_targetId].rewardProportion = battleField[_targetId].rewardProportion+myZombie.rare;
            if(battleField[zombieId].rewardProportion>50){
                battleField[zombieId].rewardProportion = battleField[zombieId].rewardProportion-myZombie.rare;
            }else{
                battleField[zombieId].rewardProportion = 50;
            }
            enemyZombie.winCount++;
            return false;
        }
    }
    function attackBoss(uint zombieId,uint _BossId) external onlyOwnerOf(zombieId) returns(bool){
        require(boss[_BossId].isready == 1 && _isReadyForPVE(zombies[zombieId].zombieId));
        Boss storage enemyBoss = boss[_BossId];
        Zombie storage myZombie = zombies[zombieId];
        uint _attacBosskVictoryProbability = gettAttackBossVictoryProbability(myZombie.zombieId,enemyBoss.bossId);
        uint _rand = _randMod(modules,10000);
        if(_rand<=_attacBosskVictoryProbability){
            myZombie.level++;
            _triggerPVECooldown(myZombie);
            payable(_msgSender()).transfer((enemyBoss.reward *(100 - marketFee))/100);
            return true;
        }else{
            _triggerPVECooldown(myZombie);
            return false;
        }
    }
}



pragma solidity ^0.8.0;
contract ZombieCore is zombieMarket,zombieAttack {
    string public  name = "MyCryptoZombieNFT";
    string public  symbol = "MCB";
    receive() external payable { }
    //function withdraw() external onlyOwner {
    //    owner.transfer(address(this).balance);
    //}
    function checkBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }
}