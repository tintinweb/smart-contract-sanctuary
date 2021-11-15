pragma solidity ^0.5.12;

import "./zombieMarket.sol";
import "./zombieFeeding.sol";
import "./zombieAttack.sol";
// 僵尸核心，就是僵尸全部合约的整合
contract ZombieCore is ZombieMarket,ZombieFeeding,ZombieAttack {

    string public constant name = "BreedCryptoZombie";
    string public constant symbol = "BCZ";

    function() external payable {
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

}

pragma solidity ^0.5.12;


import "./zombieHelper.sol";
import "./erc721.sol";
// 交易，取走等
contract ZombieOwnership is ZombieHelper, ERC721 {

  mapping (uint => address) zombieApprovals;

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerZombieCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return zombieToOwner[_tokenId];
  }
  // 内部函数，+1-1改地址映射
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    ownerZombieCount[_to] = ownerZombieCount[_to].add(1);
    ownerZombieCount[_from] = ownerZombieCount[_from].sub(1);
    zombieToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    zombieApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(zombieApprovals[_tokenId] == msg.sender); //接收者调用的，所以看是否已授权
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
}

pragma solidity ^0.5.12;

import "./zombieOwnership.sol";
// 交易市场与转移
contract ZombieMarket is ZombieOwnership {
    struct zombieSales{ // 出售者
        address payable seller; // 有钱的转让 payable
        uint price;
    }
    mapping(uint=>zombieSales) public zombieShop;
    uint shopZombieCount;
    uint public tax = 1 finney;// 比ether小3位的单位，这是出售的税金
    uint public minPrice = 1 finney;

    event SaleZombie(uint indexed zombieId,address indexed seller);
    event BuyShopZombie(uint indexed zombieId,address indexed buyer,address indexed seller);

    // 放到mapping里面就行
    function saleMyZombie(uint _zombieId,uint _price)public onlyOwnerOf(_zombieId){
        require(_price>=minPrice+tax,'Your price must > minPrice+tax');
        zombieShop[_zombieId] = zombieSales(msg.sender,_price);
        shopZombieCount = shopZombieCount.add(1);
        emit SaleZombie(_zombieId,msg.sender);
    }
    function buyShopZombie(uint _zombieId)public payable{ //接收eth加payable
        require(msg.value >= zombieShop[_zombieId].price,'No enough money');
        _transfer(zombieShop[_zombieId].seller,msg.sender, _zombieId);
        zombieShop[_zombieId].seller.transfer(msg.value - tax);//收钱的，有去掉tax税收
        delete zombieShop[_zombieId]; // 删除映射节省空间
        shopZombieCount = shopZombieCount.sub(1);
        emit BuyShopZombie(_zombieId,msg.sender,zombieShop[_zombieId].seller);
    }
    function getShopZombies() external view returns(uint[] memory) {
        uint[] memory result = new uint[](shopZombieCount);
        uint counter = 0;
        for (uint i = 0; i < zombies.length; i++) {
            if (zombieShop[i].price != 0) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function setTax(uint _value)public onlyOwner{
        tax = _value;
    }
    function setMinPrice(uint _value)public onlyOwner{
        minPrice = _value;
    }
}

pragma solidity ^0.5.12;

import "./zombieFactory.sol";


// 僵尸助手：僵尸养殖、改名、冷却等
contract ZombieHelper is ZombieFactory {

  uint public levelUpFee = 0.001 ether;

  // 低于一定等级才能升级
  modifier aboveLevel(uint _level, uint _zombieId) {
    require(zombies[_zombieId].level >= _level,'Level is not sufficient');
    _;
  }
  modifier onlyOwnerOf(uint _zombieId) {
    require(msg.sender == zombieToOwner[_zombieId],'Zombie is not yours');
    _;
  }
  function setLevelUpFee(uint _fee) external onlyOwner {
    levelUpFee = _fee;
  }

  function levelUp(uint _zombieId) external payable onlyOwnerOf(_zombieId){
    require(msg.value == levelUpFee,'No enough money');
    zombies[_zombieId].level++; // 等级非常高，不太会溢出
  }

  function changeName(uint _zombieId, string calldata _newName) external  aboveLevel(2, _zombieId) onlyOwnerOf(_zombieId) {
    zombies[_zombieId].name = _newName;
  }

  function getZombiesByOwner(address  _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](ownerZombieCount[_owner]); //定长数组 
    uint counter = 0;
    for (uint i = 0; i < zombies.length; i++) {
      if (zombieToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  // 触发冷却
  function _triggerCooldown(Zombie storage _zombie) internal {
    _zombie.readyTime = uint32(now + cooldownTime) - uint32((now + cooldownTime) % 1 days); // 去掉了 当天过了多少秒，保证在每日0点惊醒更新
  }
  // 是否满足条件
  function _isReady(Zombie storage _zombie) internal view returns (bool) {
      return (_zombie.readyTime <= now);
  }
  // 合体函数，内部调用才行
  function multiply(uint _zombieId, uint _targetDna) internal onlyOwnerOf(_zombieId) {
    Zombie storage myZombie = zombies[_zombieId];
    require(_isReady(myZombie),'Zombie is not ready'); // 必须过了冷却
    _targetDna = _targetDna % dnaModulus; // 限制目标的dna必须在规定位数内
    uint newDna = (myZombie.dna + _targetDna) / 2; // dna 平均值运算
    newDna = newDna - newDna % 10 + 9; // 标记合体产生的dna尾数为9
    _createZombie("NoName", newDna);
    _triggerCooldown(myZombie);
  }


}

pragma solidity ^0.5.12;


import "./zombieHelper.sol";
// 僵尸喂食
contract ZombieFeeding is ZombieHelper {

  function feed(uint _zombieId) public onlyOwnerOf(_zombieId){
    Zombie storage myZombie = zombies[_zombieId];  // 这里带storage 表示 后续修改连指针一起修改 即 所在数组里也修改
    require(_isReady(myZombie));
    zombieFeedTimes[_zombieId] = zombieFeedTimes[_zombieId].add(1);
    _triggerCooldown(myZombie);
    if(zombieFeedTimes[_zombieId] % 10 == 0){  // 喂食到达10的倍数，生成新的僵尸（合体）
        uint newDna = myZombie.dna - myZombie.dna % 10 + 8; //将dna末尾改成8, 代表喂食产生
        _createZombie("zombie's son", newDna);
    }
  }
}

pragma solidity ^0.5.12;

import "./ownable.sol";
import "./safemath.sol";

contract ZombieFactory is Ownable {

  using SafeMath for uint256;

  event NewZombie(uint zombieId, string name, uint dna);

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;
  uint public cooldownTime = 1 days;
  uint public zombiePrice = 0.01 ether;
  uint public zombieCount = 0;

  struct Zombie {
    string name;
    uint dna;
    uint16 winCount;
    uint16 lossCount;
    uint32 level;
    uint32 readyTime; //冷却时间，同类型放一起节省gas
  }

  Zombie[] public zombies;

  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) ownerZombieCount;
  mapping (uint => uint) public zombieFeedTimes;

  function _createZombie(string memory _name, uint _dna) internal {
    uint id = zombies.push(Zombie(_name, _dna, 0, 0, 1, 0)) - 1;  // 累计数量 -1 = 序号
    zombieToOwner[id] = msg.sender;
    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].add(1); //获取随机dna
    zombieCount = zombieCount.add(1);
    
    emit NewZombie(id, _name, _dna);
  }

  // 私有函数通常已下划线开头
  function _generateRandomDna(string memory _str) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(_str,now))) % dnaModulus;
  }

  function createZombie(string memory _name) public{
    require(ownerZombieCount[msg.sender] == 0);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 10;  // 这里dna 的最后一位是0代表铸造出的
    _createZombie(_name, randDna);
  }

  function buyZombie(string memory _name) public payable{
    require(ownerZombieCount[msg.sender] > 0); // 第一个是走createZombie
    require(msg.value >= zombiePrice);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 10 + 1; // 这里dna 的最后一位是1代表买到的
    _createZombie(_name, randDna);
  }

  function setZombiePrice(uint _price) external onlyOwner {
    zombiePrice = _price;
  }

}

pragma solidity ^0.5.12;

import "./zombieHelper.sol";

// 僵尸攻击，随机数+胜率
contract ZombieAttack is ZombieHelper{
    
    uint randNonce = 0;  //每次+1，伪随机数基础
    uint public attackVictoryProbability = 70;
    
    // 获取随机数
    function randMod(uint _modulus) internal returns(uint){
        randNonce++; //即使溢出也有效
        return uint(keccak256(abi.encodePacked(now,msg.sender,randNonce))) % _modulus;
    }
    
    function setAttackVictoryProbability(uint _attackVictoryProbability)public onlyOwner{
        attackVictoryProbability = _attackVictoryProbability;
    }
    
    // 与随机数的比较
    function attack(uint _zombieId,uint _targetId)external onlyOwnerOf(_zombieId) returns(uint){
        require(msg.sender != zombieToOwner[_targetId],'The target zombie is yours!');
        Zombie storage myZombie = zombies[_zombieId];
        require(_isReady(myZombie),'Your zombie is not ready!');
        Zombie storage enemyZombie = zombies[_targetId];
        uint rand = randMod(100);
        if(rand<=attackVictoryProbability){  // 就是数值比大小
            myZombie.winCount++;
            myZombie.level++;
            enemyZombie.lossCount++;
            multiply(_zombieId,enemyZombie.dna);
            return _zombieId;
        }else{
            myZombie.lossCount++;
            enemyZombie.winCount++;
            _triggerCooldown(myZombie);
            return _targetId;
        }
    }
    
}

pragma solidity ^0.5.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.5.12;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,'Must contract owner');
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0),'Must contract owner');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.5.12;

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

