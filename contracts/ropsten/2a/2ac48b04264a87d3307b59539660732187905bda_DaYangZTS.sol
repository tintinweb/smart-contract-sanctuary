pragma solidity ^0.4.24;
/**
 * @title -jiangnan.cai v0.0.1
 * ┌┬┐┌─┐┌─┐┌┬┐   ╦╦ ╦╔═╗╔╦╗  ┌┬┐┌┐     ┌─┐┌─┐┬
 *  │ ├┤ ├─┤│││   ║║ ║╚═╗ ║   │││├┴┐ ┌┐ │  ├─┤│
 *  ┴ └─┘┴ ┴┴ ┴  ╚╝╚═╝╚═╝ ╩   ┴ ┴┴ ┴ └┘ └─┘┴ ┴┴
 * ===========(0.0.1 test version)===========
 * 
 * ╔═╗┌─┐┌─┐┬┌─┐┬┌─┐┬   ┌───────────┐ ╦ ╦┌─┐┌┐ ╔═╗┬┌┬┐┌─┐ 
 * ║ ║├┤ ├┤ ││  │├─┤│   │ 575364441 │ ║║║├┤ ├┴┐╚═╗│ │ ├┤  
 * ╚═╝└  └  ┴└─┘┴┴ ┴┴─┘ └───────────┘ ╚╩╝└─┘└─┘╚═╝┴ ┴ └─┘  
 * 
 * ┌──────────────────────────────┐ ╔╦╗┬ ┬┌─┐┌┐┌┬┌─┌─┐  ╔╦╗┌─┐
 * │ 严大阳       彭氏家族        │  ║ ├─┤├─┤│││├┴┐└─┐   ║ │ │
 * │ 涂大于       帽子哥          │  ╩ ┴ ┴┴ ┴┘└┘┴ ┴└─┘   ╩ └─┘
 * │ 王三鑫       王六泉          └───────────────────────────┐
 * │ 樊大冰       刘大群          胡三金           刘阿松     │
 * └──────────────────────────────────────────────────────────┘
 * 
 * 
 * This is my first Dapp
 * OK!Let&#39;s start the game.
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner,"Have no legal powerd");
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 contract Factory is Ownable{
    event NewCard(uint id,string name,uint dna);
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 minutes;
    struct Card{
        string name;
        uint dna;
        uint32 level;
        uint32 readyTime;
        uint winCount;
        uint16 lossCount;
        uint16 ad;
    }
    Card[] public cards;
    mapping(uint=>address) cardToOwner;
    mapping(address=>uint) ownerCardCount;
    
    function _createRandomDna(string _name) internal returns(uint){
        uint rand = uint(keccak256(_name));
        return rand % dnaModulus;
    }
    function _createCard(string _name,uint _dna) internal{
        uint id = cards.push(Card(_name, _dna, 1, uint32(now + cooldownTime), 0, 0, 0)) - 1;
        cardToOwner[id] = msg.sender;
        ownerCardCount[msg.sender]++;
        NewCard(id, _name, _dna);
    }
    function createCard(string _name) public {
        require(ownerCardCount[msg.sender]==0);
            uint randDna =  _createRandomDna(_name);
            randDna = randDna - randDna % 100;
            _createCard(_name,randDna);
    }
 }


 contract Attack is Factory{
    uint randNonce = 0;
    uint attackVictoryProbability = 70;

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(now, msg.sender, randNonce)) % _modulus;
    }
    modifier onlyOwnerOf(uint _cardId) {
        require(msg.sender == cardToOwner[_cardId]);
        _;
    }
    function _triggerCooldown(Card storage _card) internal {
        _card.readyTime = uint32(now + cooldownTime);
    }

    function _isReady(Card storage _card) internal view returns (bool) {
        return (_card.readyTime <= now);
    }
    function feedAndMultiply(uint _cardId, uint _targetDna) internal onlyOwnerOf(_cardId) {
        Card storage myCard = cards[_cardId];
        require(_isReady(myCard));
        _targetDna = _targetDna % dnaModulus;
        uint newDna = (myCard.dna + _targetDna) / 2;
        _createCard("NoName", newDna);
        _triggerCooldown(myCard);
    }
    function attack(uint _cardId, uint _targetId) external onlyOwnerOf(_cardId) {
        Card storage myCard = cards[_cardId];
        Card storage enemyCard = cards[_targetId];
        uint rand = randMod(100);
        if (rand <= attackVictoryProbability) {
            myCard.winCount++;
            myCard.level++;
            enemyCard.lossCount++;
            feedAndMultiply(_cardId, enemyCard.dna);
        } else {
            myCard.lossCount++;
            enemyCard.winCount++;
            _triggerCooldown(myCard);
        }
  }
 }
 
  contract Helper is Attack {

  uint levelUpFee = 0.001 ether;

  modifier aboveLevel(uint _level, uint _cardId) {
    require(cards[_cardId].level >= _level);
    _;
  }

  function withdraw() external onlyOwner {
    owner.transfer(this.balance);
  }

  function setLevelUpFee(uint _fee) external onlyOwner {
    levelUpFee = _fee;
  }

  function levelUp(uint _cardId) external payable {
    require(msg.value == levelUpFee);
    cards[_cardId].level++;
  }

  function changeName(uint _cardId, string _newName) external aboveLevel(2, _cardId) onlyOwnerOf(_cardId) {
    cards[_cardId].name = _newName;
  }

  function changeDna(uint _cardId, uint _newDna) external aboveLevel(20, _cardId) onlyOwnerOf(_cardId) {
    cards[_cardId].dna = _newDna;
  }

  function getCardByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerCardCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < cards.length; i++) {
      if (cardToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

}

contract DaYangZTS is Helper, ERC721 {

  using SafeMath for uint256;

  mapping (uint => address) cardApprovals;

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerCardCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return cardToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownerCardCount[_to] = ownerCardCount[_to].add(1);
    ownerCardCount[msg.sender] = ownerCardCount[msg.sender].sub(1);
    cardToOwner[_tokenId] = _to;
    Transfer(_from, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    cardApprovals[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(cardApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}