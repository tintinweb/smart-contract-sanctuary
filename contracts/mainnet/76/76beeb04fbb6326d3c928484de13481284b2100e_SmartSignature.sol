pragma solidity ^0.4.21;

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
/// @author Dieter Shirley <<span class="__cf_email__" data-cfemail="c5a1a0b1a085a4bdacaaa8bfa0abeba6aa">[email&#160;protected]</span>> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() public view returns (string name);
    function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract SmartSignature is ERC721{
  using SafeMath for uint256;

  event Bought (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  
  uint256 counter;
  mapping (uint256 => address) private ownerOfToken;
  mapping (uint256 => uint256) private priceOfToken;
  mapping (uint256 => address) private approvedOfToken;
  mapping (uint256 => address) private creatorOfToken;
  mapping (uint256 => uint256) private parentOfToken;
  mapping (uint256 => uint256) private balanceOfToken;  
  mapping (uint256 => uint256) private free1OfToken; 
  mapping (uint256 => uint256) private free2OfToken; 
   
  function SmartSignature () public {
    owner = msg.sender;
    creatorOfToken[counter] = ownerOfToken[counter] = msg.sender;
    priceOfToken[counter] = 1 ether;
    parentOfToken[counter] = 0;
    free1OfToken[counter] = 0;
    free2OfToken[counter] = 0;    
    counter += 1;    
  }

  /* Modifiers */
  modifier onlyOwner(uint256 _tokenId) {
    require(ownerOfToken[_tokenId] == msg.sender);
    _;
  }
  
  modifier onlyCreator(uint256 _tokenId) {
    require(creatorOfToken[_tokenId] == msg.sender);
    _;
  }  

  modifier onlyRoot() {
    require(creatorOfToken[0] == msg.sender);
    _;
  }

  /* Owner */
  function setCreator (address _creator, uint _tokenId) onlyCreator(_tokenId) public {
    creatorOfToken[_tokenId] = _creator;
  }

  /* Judge Fake Token */
  function judgeFakeToken (uint256 _tokenId) onlyRoot() public {
    creatorOfToken[_tokenId] = msg.sender;
  }

  function judgeFakeTokenAndTransfer (uint256 _tokenId, address _plaintiff) onlyRoot() public {    
    creatorOfToken[_tokenId] = _plaintiff;
  }  

  /* Withdraw */
  function withdrawAllFromRoot () onlyRoot() public {
    uint256 t = balanceOfToken[0];
    balanceOfToken[0] = 0;
    msg.sender.transfer(t);         
  }
  
  function withdrawAllFromToken (uint256 _tokenId) onlyCreator(_tokenId) public {
    uint256 t = balanceOfToken[_tokenId];
    uint256 r = t / 20;
    balanceOfToken[_tokenId] = 0;
    balanceOfToken[parentOfToken[_tokenId]] += r;
    msg.sender.transfer(t - r);      
  }

  function withdrawAmountFromToken (uint256 _tokenId, uint256 t) onlyCreator(_tokenId) public {
    if (t > balanceOfToken[_tokenId]) t = balanceOfToken[_tokenId];
    uint256 r = t / 20;
    balanceOfToken[_tokenId] = 0;
    balanceOfToken[parentOfToken[_tokenId]] += r;
    msg.sender.transfer(t - r); 
  }
  
  function withdrawAll() public {
      require(msg.sender == owner);
      owner.transfer(this.balance);
  }

  /* Buying */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    return _price.mul(117).div(98);
  }

  function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
    return _price.div(20); // 5%
  }

  function buy (uint256 _tokenId) payable public {
    require(priceOf(_tokenId) > 0);
    require(ownerOf(_tokenId) != address(0));
    require(msg.value >= priceOf(_tokenId));
    require(ownerOf(_tokenId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    require(now >= free1OfToken[_tokenId]);

    address oldOwner = ownerOf(_tokenId);
    address newOwner = msg.sender;
    uint256 price = priceOf(_tokenId);
    uint256 excess = msg.value.sub(price);

    _transfer(oldOwner, newOwner, _tokenId);
    priceOfToken[_tokenId] = nextPriceOf(_tokenId);

    Bought(_tokenId, newOwner, price);
    Sold(_tokenId, oldOwner, price);

    // Devevloper&#39;s cut which is left in contract and accesed by
    // `withdrawAll` and `withdrawAmountTo` methods.
    uint256 devCut = calculateDevCut(price);

    // Transfer payment to old owner minus the developer&#39;s cut.
    oldOwner.transfer(price.sub(devCut));
    uint256 shareHolderCut = devCut.div(20);
    ownerOfToken[parentOfToken[_tokenId]].transfer(shareHolderCut);
    balanceOfToken[_tokenId] += devCut.sub(shareHolderCut);

    if (excess > 0) {
      newOwner.transfer(excess);
    }
  }

  /* ERC721 */

  function name() public view returns (string name) {
    return "smartsignature.io";
  }

  function symbol() public view returns (string symbol) {
    return "SSI";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return counter;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 t = 0;
    for (uint256 i = 0; i < counter; i++) {
      if (ownerOf(i) == _owner) {
        t++;
      }
    }
    return t;
  }

  function ownerOf (uint256 _tokenId) public view returns (address _owner) {
    return ownerOfToken[_tokenId];
  }
  
  function creatorOf (uint256 _tokenId) public view returns (address _creator) {
    return creatorOfToken[_tokenId];
  }  
  
  function parentOf (uint256 _tokenId) public view returns (uint256 _parent) {
    return parentOfToken[_tokenId];
  }    
  
  function free1Of (uint256 _tokenId) public view returns (uint256 _free) {
    return free1OfToken[_tokenId];
  }    

  function free2Of (uint256 _tokenId) public view returns (uint256 _free) {
    return free2OfToken[_tokenId];
  }      
  
  function balanceFromToken (uint256 _tokenId) public view returns (uint256 _balance) {
    return balanceOfToken[_tokenId];
  }      
  
  function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
    uint256[] memory tokens = new uint256[](balanceOf(_owner));

    uint256 tokenCounter = 0;
    for (uint256 i = 0; i < counter; i++) {
      if (ownerOf(i) == _owner) {
        tokens[tokenCounter] = i;
        tokenCounter += 1;
      }
    }

    return tokens;
  }

  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return priceOf(_tokenId) > 0;
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

  function priceOf (uint256 _tokenId) public view returns (uint256 _price) {
    return priceOfToken[_tokenId];
  }

  function nextPriceOf (uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_tokenId));
  }

  function allOf (uint256 _tokenId) external view returns (address _owner, address _creator, uint256 _price, uint256 _nextPrice) {
    return (ownerOfToken[_tokenId], creatorOfToken[_tokenId], priceOfToken[_tokenId], nextPriceOf(_tokenId));
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
  
  function changePrice(uint256 _tokenId, uint256 _price, uint256 _frozen1, uint256 _frozen2) onlyOwner(_tokenId) public {
    require(now >= free2OfToken[_tokenId]);
    priceOfToken[_tokenId] = _price;
    free1OfToken[_tokenId] = now + _frozen1;
    free2OfToken[_tokenId] = now + _frozen1 + _frozen2;
  }
  
  function issueToken(uint256 _price, uint256 _frozen1, uint256 _frozen2, uint256 _parent) public {
    require(_parent <= counter);
    creatorOfToken[counter] = ownerOfToken[counter] = msg.sender;
    priceOfToken[counter] = _price;
    parentOfToken[counter] = _parent;
    free1OfToken[counter] = now + _frozen1;
    free2OfToken[counter] = now + _frozen1 + _frozen2;
    counter += 1;
  }  
}