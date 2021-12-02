/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

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

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

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
    uint32 readyTime;
  }

  Zombie[] public zombies;

  mapping (uint => address) public zombieToOwner;
  mapping (address => uint) ownerZombieCount;
  mapping (uint => uint) public zombieFeedTimes;

  function _createZombie(string memory _name, uint _dna) internal {
    uint id = zombies.push(Zombie(_name, _dna, 0, 0, 1, 0)) - 1;
    zombieToOwner[id] = msg.sender;
    ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].add(1);
    zombieCount = zombieCount.add(1);
    emit NewZombie(id, _name, _dna);
  }

  function _generateRandomDna(string memory _str) private view returns (uint) {
    return uint(keccak256(abi.encodePacked(_str,now))) % dnaModulus;
  }

  function createZombie(string memory _name) public{
    require(ownerZombieCount[msg.sender] == 0);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 10;
    _createZombie(_name, randDna);
  }

  function buyZombie(string memory _name) public payable{
    require(ownerZombieCount[msg.sender] > 0);
    require(msg.value >= zombiePrice);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 10 + 1;
    _createZombie(_name, randDna);
  }

  function setZombiePrice(uint _price) external onlyOwner {
    zombiePrice = _price;
  }

}
    
contract ZombieHelper is ZombieFactory{
    uint levelUpFee = 0.001 ether;
    modifier aboveLevel(uint _level,uint _zombieId){
        require(zombies[_zombieId].level>=_level);
        _;
    }

    modifier onlyOwnerOf(uint _zombieId){
        require(msg.sender == zombieToOwner[_zombieId]);
        _;
    }

    function setLevelUpFee(uint _fee) external onlyOwner{
        levelUpFee = _fee;
    }

    function levelUp(uint _zombieId) external payable{
        require(msg.value>=levelUpFee);
        zombies[_zombieId].level++;
    }

    function changeName(uint _zombieId,string calldata _newName) external aboveLevel(2,_zombieId) onlyOwnerOf(_zombieId){
        zombies[_zombieId].name = _newName;
    }

    function getZombiesByOwner(address _owner) external view returns(uint[] memory){
        uint[] memory result = new uint[](ownerZombieCount[_owner]);
        uint counter = 0;
        for (uint i=0;i<zombies.length;i++){
            if (zombieToOwner[i]==_owner){
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function _triggerColldown(Zombie storage _zombie) internal{
        _zombie.readyTime = uint32(now+cooldownTime)- uint32((now+cooldownTime)% 1 days);
    }

    function _isReady(Zombie storage _zombie) internal view returns (bool){
        return (_zombie.readyTime<=now); 
    }

    function multiply(uint _zombieId,uint _targetDna) internal onlyOwnerOf(_zombieId){
        Zombie storage myZombie = zombies[_zombieId];
        require(_isReady(myZombie));
        _targetDna = _targetDna%dnaModulus;
        uint newDna = (myZombie.dna+_targetDna)/2;
        newDna = newDna - newDna%10+9;
        _createZombie("NoName",newDna);
        _triggerColldown(myZombie);
    }
}

contract ZombieFeeding is ZombieHelper{
    function feed(uint _zombieId) public onlyOwnerOf(_zombieId){
        Zombie storage myZombie = zombies[_zombieId];
        require(_isReady(myZombie));
        zombieFeedTimes[_zombieId] = zombieFeedTimes[_zombieId].add(1);
        _triggerColldown(myZombie);
        if (zombieFeedTimes[_zombieId]%10==0){
            uint newDna = myZombie.dna - myZombie.dna%10 + 8;
            _createZombie("zombie's son",newDna);
        }
    }
}

contract ZombieAttack is ZombieHelper{
    uint randNonce = 0;
    uint attackVictoryProbability = 70;
    function randMod(uint _modulus) internal returns(uint){
        randNonce++;
        return uint(keccak256(abi.encodePacked(now,msg.sender,randNonce)))%_modulus;
    }

    function setAttackVictoryProbability(uint _attackVictoryProbability) public onlyOwner{
        attackVictoryProbability = _attackVictoryProbability;
    }

    function attack(uint _zombieId,uint _tragetId) external onlyOwnerOf(_zombieId){
        Zombie storage myZombie = zombies[_zombieId];
        Zombie storage enemyZombie = zombies[_tragetId];
        uint rand = randMod(100);
        if (rand<=attackVictoryProbability){
            myZombie.winCount++;
            myZombie.level++;
            enemyZombie.lossCount++;
            multiply(_zombieId,enemyZombie.dna);
        }else{
            myZombie.lossCount++;
            enemyZombie.winCount++;
            _triggerColldown(myZombie);
        }
    }
}

contract ZombieOwnership is ZombieHelper,ERC721{

  mapping(uint=>address) zombieApprovals;
  function balanceOf(address _owner) public view returns (uint256 _balance){
      return ownerZombieCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner){
      return zombieToOwner[_tokenId];
  }

  function _transfer(address _from,address _to,uint256 _tokenId) internal{
      ownerZombieCount[_from] = ownerZombieCount[_from].sub(1);
      ownerZombieCount[_to] = ownerZombieCount[_to].add(1);
      zombieToOwner[_tokenId] = _to;
      emit Transfer(_from,_to,_tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public{
      _transfer(msg.sender,_to,_tokenId);

  }
  function approve(address _to, uint256 _tokenId) public{
      zombieApprovals[_tokenId] = _to;
      emit Approval(msg.sender,_to,_tokenId);
  }
  function takeOwnership(uint256 _tokenId) public{
      require(zombieApprovals[_tokenId]==msg.sender);
      address owner = ownerOf(_tokenId);
      _transfer(owner,msg.sender,_tokenId);
  }
}

contract ZombieMarket is ZombieOwnership{
    uint public tax = 1 finney;
    uint public minPrice = 1 finney;

    struct zombieSales{
        address payable seller;
        uint price;
    }

    mapping(uint => zombieSales) public zombieShop;
    event SaleZombie(uint indexed zombieId,address indexed seller);
    event BuyShopZombie(uint indexed zombieId,address indexed buyer,address indexed seller);

    function saleMyZombie(uint _zombieId,uint _price) public onlyOwnerOf(_zombieId){
        require(_price>=minPrice+tax);
        zombieShop[_zombieId] = zombieSales(msg.sender,_price);
        emit SaleZombie(_zombieId,msg.sender);
    }

    function buyShopZombie(uint _zombieId) public payable{
        zombieSales memory _zombieSales = zombieShop[_zombieId];
        require(msg.value>=_zombieSales.price);
        _transfer(_zombieSales.seller,msg.sender,_zombieId);
        _zombieSales.seller.transfer(msg.value-tax);
        delete zombieShop[_zombieId];
        emit BuyShopZombie(_zombieId,msg.sender,_zombieSales.seller);
    }

    function setTax(uint _value) public onlyOwner{
        tax = _value;
    }

    function setMinPrice(uint _value) public onlyOwner{
        minPrice = _value;
    }
}

contract ZombieCore is ZombieMarket,ZombieFeeding,ZombieAttack{
    string public constant name = "MyCryptoZombie";
    string public constant symbol = "MCZ";
    function () external payable{

    }

    function withdraw() external onlyOwner{
        owner.transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns(uint){
        return address(this).balance;
    }
}