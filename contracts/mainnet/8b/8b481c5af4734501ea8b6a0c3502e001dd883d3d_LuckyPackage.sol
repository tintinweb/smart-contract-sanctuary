pragma solidity ^0.4.21;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author MinakoKojima (https://github.com/lychees)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Optional
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract LuckyPackage is ERC721{

  event Bought (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event RollDice(address indexed playerAddr, address indexed prizeIssuer, uint prizeId);

  address private owner;
  mapping (address => bool) private admins;

  uint256 private tokenSize;
  mapping (uint256 => address) private ownerOfToken;
  mapping (uint256 => address) private approvedOfToken;
  
  struct Package {
      uint256 tokenId;
      uint256 ratio;
      address issuer;
  }
  Package[] private package;
  uint256 private packageSize;
  uint256 private sigmaRatio;
  
  function LuckyPackage() public {
    owner = msg.sender;
    admins[owner] = true;    
    sigmaRatio = 0;
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
     msg.sender.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }

  /* ERC721 */

  function name() public view returns (string _name) {
    return "luckyDraw";
  }

  function symbol() public view returns (string _symbol) {
    return "LCY";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return tokenSize;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;

    for (uint256 i = 0; i < tokenSize; i++) {
      if (ownerOf(i) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf (uint256 _tokenId) public view returns (address _owner) {
    return ownerOfToken[_tokenId];
  }

  function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
    uint256[] memory Tokens = new uint256[](balanceOf(_owner));

    uint256 TokenCounter = 0;
    for (uint256 i = 0; i < tokenSize; i++) {
      if (ownerOf(i) == _owner) {
        Tokens[TokenCounter] = i;
        TokenCounter += 1;
      }
    }

    return Tokens;
  }

  function approvedFor(uint256 _tokenId) public view returns (address _approved) {
    return approvedOfToken[_tokenId];
  }

  function approve(address _to, uint256 _tokenId) public {
    require(msg.sender != _to);
    require(ownerOf(_tokenId) == msg.sender);

    if (_to == 0) {
      if (approvedOfToken[_tokenId] != 0) {
        delete approvedOfToken[_tokenId];
        emit Approval(msg.sender, 0, _tokenId);
      }
    } else {
      approvedOfToken[_tokenId] = _to;
      emit Approval(msg.sender, _to, _tokenId);
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
    require(ownerOf(_tokenId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfToken[_tokenId] = _to;
    approvedOfToken[_tokenId] = 0;

    emit Transfer(_from, _to, _tokenId);
  }

  /* Read */
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  function allOf (uint256 _tokenId) external view returns (address _owner) {
    return (ownerOf(_tokenId));
  }

  /* Read */
  
  function getAllPackage() public view returns (uint256[] _id, uint256[] _ratio, address[] _issuer) {
    uint256[] memory ID = new uint[](packageSize);
    uint256[] memory RATIO = new uint[](packageSize);
    address[] memory ISSUER = new address[](packageSize);
    for (uint i = 0; i < packageSize; i++) {
      ID[i] = package[i].tokenId;
      RATIO[i] = package[i].ratio;
      ISSUER[i] = package[i].issuer;
    }
    return (ID, RATIO, ISSUER);
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
  
  function putIntoPackage(uint256 _tokenId, uint256 _ratio, address _issuer) onlyAdmins() public {      
      Issuer issuer = Issuer(_issuer);
      require(issuer.ownerOf(_tokenId) == msg.sender);
      issuer.transferFrom(msg.sender, address(this), _tokenId);      
      
      if (packageSize >= package.length) {
          package.push(Package(_tokenId, _ratio, _issuer));
      } else {
        package[packageSize].tokenId = _tokenId;
        package[packageSize].ratio = _ratio;
        package[packageSize].issuer = _issuer;
      }

      packageSize += 1;
      sigmaRatio += _ratio;
  }
  
  function rollDice(uint256 _tokenId) public {
      require(msg.sender == ownerOfToken[_tokenId]);
      require(packageSize > 0);
      
      /* recycle the token. */
      _transfer(msg.sender, owner, _tokenId);
      
      /* get a random number. */
      uint256 result = uint(keccak256(block.timestamp + block.difficulty)); // assume result is the random number
      result %= sigmaRatio;
      uint256 rt;
      for (uint256 i = 0; i < packageSize; i++) {
          if (result >= package[i].ratio) {
              result -= package[i].ratio;
          } else {
              rt = i;
              break;
          }
      }
      
      /* transfer  */
      Issuer issuer = Issuer(package[rt].issuer);
      issuer.transfer(msg.sender, package[rt].tokenId);
      
      /* remove */
      sigmaRatio -= package[rt].ratio;
      package[rt] = package[packageSize-1];
      packageSize -= 1;
      
      emit RollDice(msg.sender, package[rt].issuer, package[rt].tokenId);
  }
  
  /* Issue */
  function issueToken(uint256 _count) onlyAdmins() public {
    uint256 l = tokenSize;
    uint256 r = tokenSize + _count;
    for (uint256 i = l; i < r; i++) {
      ownerOfToken[i] = msg.sender;
    } 
    tokenSize += _count;    
  }
  function issueTokenAndTransfer(uint256 _count, address to) onlyAdmins() public {
    uint256 l = tokenSize;
    uint256 r = tokenSize + _count;
    for (uint256 i = l; i < r; i++) {
      ownerOfToken[i] = to;
    }      
    tokenSize += _count;    
  }    
  function issueTokenAndApprove(uint256 _count, address to) onlyAdmins() public {
    uint256 l = tokenSize;
    uint256 r = tokenSize + _count;
    for (uint256 i = l; i < r; i++) {
      ownerOfToken[i] = msg.sender;
      approve(to, i);
    }          
    tokenSize += _count;
  }    
}

interface Issuer {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;  
  function transfer(address _to, uint256 _tokenId) external;
  function ownerOf (uint256 _tokenId) external view returns (address _owner);
}