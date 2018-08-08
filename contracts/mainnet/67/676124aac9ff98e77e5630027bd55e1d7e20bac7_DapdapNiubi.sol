pragma solidity ^0.4.24;

/**
* Issued by
*   __                        __                                     
*  /\ \                      /\ \                       __           
*  \_\ \     __     _____    \_\ \     __     _____    /\_\    ___   
*  /&#39;_` \  /&#39;__`\  /\ &#39;__`\  /&#39;_` \  /&#39;__`\  /\ &#39;__`\  \/\ \  / __`\ 
* /\ \L\ \/\ \L\.\_\ \ \L\ \/\ \L\ \/\ \L\.\_\ \ \L\ \__\ \ \/\ \L\ \
* \ \___,_\ \__/.\_\\ \ ,__/\ \___,_\ \__/.\_\\ \ ,__/\_\\ \_\ \____/
*  \/__,_ /\/__/\/_/ \ \ \/  \/__,_ /\/__/\/_/ \ \ \/\/_/ \/_/\/___/ 
*                    \ \_\                     \ \_\                
*                     \/_/                      \/_/                
*
* dapdapToken(dapdap)
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

  function max(uint a, uint b) internal pure returns (uint) {
    if (a > b) return a;
    else return b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    if (a < b) return a;
    else return b;
  }
}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="771312031237160f1e181a0d1219591418">[email&#160;protected]</a>> (https://github.com/dete)
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
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract DapdapNiubi is ERC721{
  using SafeMath for uint256;

  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  mapping (address=>bool) admins;
  mapping (uint => address) public mapOwnerOfMedal;
  mapping (uint256 => address) public approvedOfItem;

  // typeId 
  // 0 for bronze 
  // 1 for silver 
  // 2 for gold
  // 3 for diamond
  // 4 for starlight
  // 5 for king
  struct Medal {
      uint medalId;
      uint typeId;
      address owner;
  }

  Medal[] public listedMedal;

  function DapdapNiubi() public {
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

  function getMedalInfo(uint medalId) public view returns(uint, uint, address) {
      require(medalId<listedMedal.length);
      Medal memory medal = listedMedal[medalId];
      return (medal.medalId, medal.typeId, medal.owner);
  }

  // 4. synthesis system
  function issueMedal(address userAddress) public onlyAdmins {
      Medal memory medal = Medal(listedMedal.length, 0, userAddress);
      mapOwnerOfMedal[listedMedal.length] = userAddress;
      listedMedal.push(medal);
    }
    
    function issueSuperMetal(address userAddress, uint typeId) public onlyOwner {
        require(typeId<=5);
        Medal memory medal = Medal(listedMedal.length, typeId, userAddress);
        mapOwnerOfMedal[listedMedal.length] = userAddress;
        listedMedal.push(medal);
    }

  function mergeMedal(uint medalId1, uint medalId2) public {
      require(medalId1 < listedMedal.length);
      require(medalId2 < listedMedal.length);
      require(listedMedal[medalId1].owner == msg.sender);
      require(listedMedal[medalId2].owner == msg.sender);
      require(listedMedal[medalId1].typeId == listedMedal[medalId2].typeId);
      require(listedMedal[medalId1].typeId <= 4);
      
      uint newTypeId = listedMedal[medalId1].typeId + 1;
      require(newTypeId <= 5);
      // generate medal
      listedMedal[medalId1].owner = address(0);
      listedMedal[medalId2].owner = address(0);
      mapOwnerOfMedal[medalId1] = address(0);
      Medal memory medal = Medal(listedMedal.length, newTypeId, msg.sender);
      mapOwnerOfMedal[listedMedal.length] = msg.sender;
      listedMedal.push(medal);
    }

  function getContractBalance() public view returns(uint) {
      return address(this).balance;
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

  function name() public pure returns (string) {
    return "dapdap.io";
  }

  function symbol() public pure returns (string) {
    return "DAPDAP";
  }

  function totalSupply() public view returns (uint256) {
    return listedMedal.length;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint counter = 0;

    for (uint i = 0; i < listedMedal.length; i++) {
      if (ownerOf(listedMedal[i].medalId) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf (uint256 _itemId) public view returns (address _owner) {
    return mapOwnerOfMedal[_itemId];
  }

  function tokensOf (address _owner) public view returns (uint[]) {
    uint[] memory result = new uint[](balanceOf(_owner));

    uint256 itemCounter = 0;
    for (uint256 i = 0; i < listedMedal.length; i++) {
      if (ownerOf(i) == _owner) {
        result[itemCounter] = listedMedal[i].medalId;
        itemCounter += 1;
      }
    }
    return result;
  }

  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    return mapOwnerOfMedal[_itemId] != address(0);
  }

  function approvedFor(uint256 _itemId) public view returns (address _approved) {
    return approvedOfItem[_itemId];
  }

  function approve(address _to, uint256 _itemId) public {
    require(msg.sender != _to);
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == msg.sender);

    if (_to == 0) {
      if (approvedOfItem[_itemId] != 0) {
        delete approvedOfItem[_itemId];
        emit Approval(msg.sender, 0, _itemId);
      }
    } else {
      approvedOfItem[_itemId] = _to;
      emit Approval(msg.sender, _to, _itemId);
    }
  }

  /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
  function transfer(address _to, uint256 _itemId) public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint256 _itemId) public {
    require(approvedFor(_itemId) == msg.sender);
    _transfer(_from, _to, _itemId);
  }

  function _transfer(address _from, address _to, uint256 _itemId) internal {
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == _from);
    require(_to != address(0));
    require(_to != address(this));
    
    mapOwnerOfMedal[_itemId] = _to;
    listedMedal[_itemId].owner = _to;
    approvedOfItem[_itemId] = 0;

    emit Transfer(_from, _to, _itemId);
  }

  /* Read */
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
}

interface IItemRegistry {
  function itemsForSaleLimit (uint256 _from, uint256 _take) external view returns (uint256[] _items);
  function ownerOf (uint256 _itemId) external view returns (address _owner);
  function priceOf (uint256 _itemId) external view returns (uint256 _price);
}