pragma solidity ^0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The isOwner constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function isOwner() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/*** Dennis & Bani welcome you ***/
contract EtherCup is Ownable {

  // NOTE: Player is our global term used to describe unique tokens

  using SafeMath for uint256;

  /*** EVENTS ***/
  event NewPlayer(uint tokenId, string name);
  event TokenSold(uint256 tokenId, uint256 oldPrice, address prevOwner, address winner, string name);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);


  /*** CONSTANTS ***/
  uint256 private price = 0.01 ether;
  uint256 private priceLimitOne = 0.05 ether;
  uint256 private priceLimitTwo = 0.5 ether;
  uint256 private priceLimitThree = 2 ether;
  uint256 private priceLimitFour = 5 ether;


  /*** STORAGE ***/
  mapping (uint => address) public playerToOwner;
  mapping (address => uint) ownerPlayerCount;
  mapping (uint256 => uint256) public playerToPrice;
  mapping (uint => address) playerApprovals;

  // The address of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;

  /*** DATATYPES ***/
  struct Player {
    string name;
  }

  Player[] public players;


  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyOwnerOf(uint _tokenId) {
    require(msg.sender == playerToOwner[_tokenId]);
    _;
  }

  /*** CONSTRUCTOR ***/
  // In newer versions use "constructor() public {  };" instead of "function PlayerLab() public {  };"
  constructor() public {
    ceoAddress = msg.sender;

  }

  /*** CEO ***/
  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }


  /*** CREATE PLAYERS ***/
  function createNewPlayer(string _name) public onlyCEO {
    _createPlayer(_name, price);
  }

  function _createPlayer(string _name, uint256 _price) internal {
    uint id = players.push(Player(_name)) - 1;
    playerToOwner[id] = msg.sender;
    ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].add(1);
    emit NewPlayer(id, _name);

    playerToPrice[id] = _price;
  }


  /*** Buy ***/
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < priceLimitOne) {
      return _price.mul(200).div(95); // < 0.05
    } else if (_price < priceLimitTwo) {
      return _price.mul(175).div(95); // < 0.5
    } else if (_price < priceLimitThree) {
      return _price.mul(150).div(95); // < 2
    } else if (_price < priceLimitFour) {
      return _price.mul(125).div(95); // < 5
    } else {
      return _price.mul(115).div(95); // >= 5
    }
  }

  function calculateDevCut (uint256 _price) public pure returns (uint256 _devCut) {
    return _price.mul(5).div(100);

  }

  function purchase(uint256 _tokenId) public payable {

    address oldOwner = playerToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = playerToPrice[_tokenId];
    uint256 purchaseExcess = msg.value.sub(sellingPrice);

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);
    playerToPrice[_tokenId] = nextPriceOf(_tokenId);

    // Devevloper&#39;s cut which is left in contract and accesed by
    // `withdrawAll` and `withdrawAmountTo` methods.
    uint256 devCut = calculateDevCut(sellingPrice);

    uint256 payment = sellingPrice.sub(devCut);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    if (purchaseExcess > 0){
        newOwner.transfer(purchaseExcess);
    }


    emit TokenSold(_tokenId, sellingPrice, oldOwner, newOwner, players[_tokenId].name);
  }

  /*** Withdraw Dev Cut ***/
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll () onlyCEO() public {
    ceoAddress.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyCEO() public {
    ceoAddress.transfer(_amount);
  }

  function showDevCut () onlyCEO() public view returns (uint256) {
    return address(this).balance;
  }


  /*** ***/
  function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
    return playerToPrice[_tokenId];
  }

  function priceOfMultiple(uint256[] _tokenIds) public view returns (uint256[]) {
    uint[] memory values = new uint[](_tokenIds.length);

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      values[i] = priceOf(_tokenIds[i]);
    }
    return values;
  }

  function nextPriceOf(uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_tokenId));
  }

  /*** ERC721 ***/
  function totalSupply() public view returns (uint256 total) {
    return players.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerPlayerCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return playerToOwner[_tokenId];
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    playerApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {

    ownerPlayerCount[_to] = ownerPlayerCount[_to].add(1);
    ownerPlayerCount[_from] = ownerPlayerCount[_from].sub(1);
    playerToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPlayers = totalSupply();
      uint256 resultIndex = 0;

      uint256 playerId;
      for (playerId = 0; playerId <= totalPlayers; playerId++) {
        if (playerToOwner[playerId] == _owner) {
          result[resultIndex] = playerId;
          resultIndex++;
        }
      }
      return result;
    }
  }

}

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
 // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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