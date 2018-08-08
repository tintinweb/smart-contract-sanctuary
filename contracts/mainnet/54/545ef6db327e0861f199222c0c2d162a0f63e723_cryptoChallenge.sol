pragma solidity ^0.4.20;

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

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fb9f9e8f9ebb9a83929496819e95d59894">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() public pure returns (string _name);
    function symbol() public pure returns (string _symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract cryptoChallenge is ERC721{
  using SafeMath for uint256;

  event Bought (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  mapping (address => bool) private admins;

  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;

  uint256[] private listedTokens;
  mapping (uint256 => uint256) private bet1OfToken;
  mapping (uint256 => uint256) private bet2OfToken;
  mapping (uint256 => uint256) private bet1deltaOfToken;
  mapping (uint256 => uint256) private bet2deltaOfToken;  
  mapping (uint256 => address) private ownerOfToken;
  mapping (uint256 => address) private owner1OfToken;
  mapping (uint256 => address) private owner2OfToken;
  mapping (uint256 => address) private witnessOfToken;  
  mapping (uint256 => address) private p1OfToken;
  mapping (uint256 => address) private p2OfToken;    
  mapping (uint256 => uint256) private price1OfToken;
  mapping (uint256 => uint256) private price2OfToken;  
  mapping (uint256 => uint256) private free1OfToken;
  mapping (uint256 => uint256) private free2OfToken;
  mapping (uint256 => address) private approvedOfToken;
  mapping (uint256 => uint256) private indexOfId;
  
  function cryptoChallenge () public {
    owner = msg.sender;
    admins[owner] = true;    
  }

  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }

  modifier onlyWitness(uint256 _tokenId) {
    require(msg.sender == witnessOfToken[_tokenId]);
    _;
  }  

  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll () onlyAdmins() public {
   msg.sender.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }

  /* Buying */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(95);
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(96);
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(97);
    } else if (_price < increaseLimit4) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

  function calculateDevCut (uint256 _price) public pure returns (uint256 _devCut) {
     return _price.div(20);
  }

  /*
     Buy a country directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All countries that
     have been listed can be bought by this method. User funds are sent
     directly to the previous owner and are never stored in the contract.
  */
  function buy1 (uint256 _tokenId) payable public {
    require(price1Of(_tokenId) > 0);
    require(owner1Of(_tokenId) != address(0));
    require(msg.value >= price1Of(_tokenId));
    require(owner1Of(_tokenId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    require(now >= free1OfToken[_tokenId]);
    require(now <= free2OfToken[_tokenId]);

    address oldOwner = owner1Of(_tokenId);
    address newOwner = msg.sender;
    uint256 price = price1Of(_tokenId);
    uint256 excess = msg.value.sub(price);

    price1OfToken[_tokenId] = nextPrice1Of(_tokenId);

    uint256 devCut = calculateDevCut(price);
    oldOwner.transfer(price.sub(devCut));

    if (excess > 0) {
      newOwner.transfer(excess);
    }

    owner1OfToken[_tokenId] = newOwner;

  }

  function buy2 (uint256 _tokenId) payable public {
    require(price2Of(_tokenId) > 0);
    require(owner2Of(_tokenId) != address(0));
    require(msg.value >= price2Of(_tokenId));
    require(owner2Of(_tokenId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    require(now >= free1OfToken[_tokenId]);
    require(now <= free2OfToken[_tokenId]);

    address oldOwner = owner2Of(_tokenId);
    address newOwner = msg.sender;
    uint256 price = price2Of(_tokenId);
    uint256 excess = msg.value.sub(price);

    price2OfToken[_tokenId] = nextPrice2Of(_tokenId);

    uint256 devCut = calculateDevCut(price);
    oldOwner.transfer(price.sub(devCut));

    if (excess > 0) {
      newOwner.transfer(excess);
    }

    owner2OfToken[_tokenId] = newOwner;
  }  

  /* ERC721 */

  function name() public pure returns (string _name) {
    return "betsignature";
  }

  function symbol() public pure returns (string _symbol) {
    return "BET";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return listedTokens.length;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;

    for (uint256 i = 0; i < listedTokens.length; i++) {
      if (ownerOf(listedTokens[i]) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return ownerOfToken[_tokenId];
  }

  function owner1Of (uint256 _tokenId) public view returns (address _owner) {
    return owner1OfToken[_tokenId];
  }

  function owner2Of (uint256 _tokenId) public view returns (address _owner) {
    return owner2OfToken[_tokenId];
  }

  function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
    uint256[] memory Tokens = new uint256[](balanceOf(_owner));

    uint256 TokenCounter = 0;
    for (uint256 i = 0; i < listedTokens.length; i++) {
      if (ownerOf(listedTokens[i]) == _owner) {
        Tokens[TokenCounter] = listedTokens[i];
        TokenCounter += 1;
      }
    }

    return Tokens;
  }

  function tokenExists (uint256 _tokenId) public pure returns (bool _exists) {
    return _tokenId == _tokenId;
  }

  function approvedFor(uint256 _tokenId) public view returns (address _approved) {
    return approvedOfToken[_tokenId];
  }

  function approve(address _to, uint256 _tokenId) public {
    require(msg.sender != _to);
    require(tokenExists(_tokenId));
    require(ownerOf(_tokenId) == msg.sender);

    if (_to == 0) {
      if (approvedOfToken[_tokenId] != 0) {
        delete approvedOfToken[_tokenId];
        Approval(msg.sender, 0, _tokenId);
      }
    } else {
      approvedOfToken[_tokenId] = _to;
      Approval(msg.sender, _to, _tokenId);
    }
  }

  /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
  function transfer(address _to, uint256 _tokenId) public {
    require(msg.sender == ownerOf(_tokenId));
    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(approvedFor(_tokenId) == msg.sender);
    _transfer(_from, _to, _tokenId);
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    require(tokenExists(_tokenId));
    require(ownerOf(_tokenId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfToken[_tokenId] = _to;
    approvedOfToken[_tokenId] = 0;

    Transfer(_from, _to, _tokenId);
  }

  /* Read */
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  function price1Of (uint256 _tokenId) public view returns (uint256 _price) {
    return price1OfToken[_tokenId];
  }

  function price2Of (uint256 _tokenId) public view returns (uint256 _price) {
    return price2OfToken[_tokenId];
  }  

  function free1Of (uint256 _tokenId) public view returns (uint256 _free1) {
    return free1OfToken[_tokenId];
  }
  
  function free2Of (uint256 _tokenId) public view returns (uint256 _free2) {
      return free2OfToken[_tokenId];
  }

  function nextPrice1Of (uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(price1Of(_tokenId));
  }

  function nextPrice2Of (uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(price2Of(_tokenId));
  }  

  function witnessOf (uint256 _tokenId) public view returns (address _witness) {
    return witnessOfToken[_tokenId];
  }

  function bet1Of (uint256 _tokenId) public view returns (uint256 _bet1) {
    return bet1OfToken[_tokenId];
  }


  function bet2Of (uint256 _tokenId) public view returns (uint256 _bet2) {
    return bet2OfToken[_tokenId];
  }


  function bet1deltaOf (uint256 _tokenId) public view returns (uint256 _bet1delta) {
    return bet1deltaOfToken[_tokenId];
  }

  function bet2deltaOf (uint256 _tokenId) public view returns (uint256 _bet2delta) {
    return bet2deltaOfToken[_tokenId];
  }

  function p1Of (uint256 _tokenId) public view returns (address _p1Of) {
    return p1OfToken[_tokenId];
  }


  function p2Of (uint256 _tokenId) public view returns (address _p2Of) {
    return p2OfToken[_tokenId];
  }

  function allOf (uint256 _tokenId) external view returns (address _owner1, address _owner2, uint256 _price1, uint256 _price2, uint256 _free1, uint256 _free2, address _witness) {
    return (owner1Of(_tokenId), owner2Of(_tokenId), price1Of(_tokenId), price2Of(_tokenId), free1Of(_tokenId), free2Of(_tokenId), witnessOf(_tokenId));
  }
  
  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
  
function judge(uint256 _tokenId, bool _isP1Win) onlyWitness(_tokenId) public {
    require(price2OfToken[_tokenId] != 0);
    require(now > free2OfToken[_tokenId]);

    uint reward = bet1OfToken[_tokenId] + bet2OfToken[_tokenId];
    reward -= calculateDevCut(reward);
    if (_isP1Win == true) {
      p1OfToken[_tokenId].transfer(reward.mul(bet1OfToken[_tokenId]).div(bet1OfToken[_tokenId] + price1OfToken[_tokenId]));
      owner1OfToken[_tokenId].transfer(reward.mul(price1OfToken[_tokenId]).div(bet1OfToken[_tokenId] + price1OfToken[_tokenId]));
    } else {
      p2OfToken[_tokenId].transfer(reward.mul(bet2OfToken[_tokenId]).div(bet2OfToken[_tokenId] + price2OfToken[_tokenId]));
      owner2OfToken[_tokenId].transfer(reward.mul(price2OfToken[_tokenId]).div(bet2OfToken[_tokenId] + price2OfToken[_tokenId]));
    }
  }

  function accept1(uint256 _tokenId, uint256 _price2) public payable {
    require(msg.sender == p2OfToken[_tokenId]);
    require(msg.value >= bet2OfToken[_tokenId]);
    require(_price2 > 0);
    price2OfToken[_tokenId] = _price2;
  }

  function accept2(uint256 _tokenId) public payable {
    require(msg.sender == p2OfToken[_tokenId]);
    require(msg.value >= bet2deltaOfToken[_tokenId]);
    bet2OfToken[_tokenId] += bet2deltaOfToken[_tokenId];
    bet1deltaOfToken[_tokenId] = bet2deltaOfToken[_tokenId] = 0;
  }

  function cancel1(uint256 _tokenId) public {
    require(msg.sender == p1OfToken[_tokenId]);
    require(price2OfToken[_tokenId] == 0);
    msg.sender.transfer(bet1OfToken[_tokenId]);
  }
  
  function cancel2(uint256 _tokenId) public {
    require(msg.sender == p1OfToken[_tokenId]);
    require(bet1deltaOfToken[_tokenId] != 0);
    msg.sender.transfer(bet1deltaOfToken[_tokenId]);
    bet1deltaOfToken[_tokenId] = 0; 
  }
  
  function issueToken(address p2, address witness, uint256 bet2, uint256 price1, uint256 frozen1, uint256 frozen2) payable public {
    require(msg.value >= 1000);
    require(witness != msg.sender);
    require(witness != p2);
    require(price1 > 0);
    uint i = listedTokens.length;
    bet1OfToken[i] = msg.value;
    bet2OfToken[i] = bet2;
    witnessOfToken[i] = witness;
    p1OfToken[i] = owner1OfToken[i] = msg.sender;  
    p2OfToken[i] = owner2OfToken[i] = p2;    
    price1OfToken[i] = price1;
    free1OfToken[i] = now + frozen1;
    free2OfToken[i] = now + frozen1 + frozen2;
    listedTokens.push(i);
  }

  function addBet(uint256 _tokenId, uint256 _bet2delta) public payable {
    require(msg.sender == p1OfToken[_tokenId]);
    bet1deltaOfToken[_tokenId] = msg.value;
    bet2deltaOfToken[_tokenId] = _bet2delta;
  }
}