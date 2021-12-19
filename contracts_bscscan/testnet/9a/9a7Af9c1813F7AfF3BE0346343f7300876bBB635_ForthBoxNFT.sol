/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) view external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Counters {
    struct Counter {
        uint256 _value;
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {counter._value += 1;}
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IStakingRewards {
    function stakeFresh(address ownerAdrr,uint256 tokenId) external;
    function ownerTokenId(uint256 tokenId) external view returns (address);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
interface IUniswapV2Router01 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)external view returns (uint256[] memory amounts);
}
contract ReentrancyGuard {
    uint256 private _guardCounter;
    constructor () {
        _guardCounter = 1;
    }
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ERC721 is Context,ERC165, IERC721, IERC721Metadata,IERC721Receiver,Ownable {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping (address => bool) private _Is_WhiteContractArr;
    address[] private _WhiteContractArr;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "FBXNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function isWhiteContract(address account) public view returns (bool) {
        if(!account.isContract()) return true;
        return _Is_WhiteContractArr[account];
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(  _msgSender() == owner || isApprovedForAll(owner, _msgSender()),"ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(address from,address to,uint256 tokenId,bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to,uint256 tokenId,bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(address from,address to,uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteContractArr.length;
    }
    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteContractArr.length, "ForthBoxNFT: no ith White Adress");
        return _WhiteContractArr[ith];
    }
    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteContractArr[account], "ForthBoxNFT:Account is already White list");
        require(account.isContract(), "ForthBoxNFT: not Contract Adress");
        _Is_WhiteContractArr[account] = true;
        _WhiteContractArr.push(account);
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteContractArr[account], "ForthBoxNFT:Account is already out White list");
        for (uint i = 0; i < _WhiteContractArr.length; i++){
            if (_WhiteContractArr[i] == account){
                _WhiteContractArr[i] = _WhiteContractArr[_WhiteContractArr.length - 1];
                _WhiteContractArr.pop();
                _Is_WhiteContractArr[account] = false;
                break;
            }
        }
    }

    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory _data) private view returns (bool) {
        if (to.isContract()){
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval){
              return retval == IERC721Receiver.onERC721Received.selector;
            }
            catch (bytes memory reason){
                if (reason.length == 0){
                  revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else{
                  assembly {revert(add(32, reason), mload(reason))}
                }
            }
        } else {
            return true;
        }
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function tokenOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 num = ERC721.balanceOf(owner);
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<num; ++i) {
            Token_list[i] =_ownedTokens[owner][i];
        }
        return Token_list;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    function onERC721Received(address,address,uint256,bytes memory) public view virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
         return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ForthBoxNFT is ERC721Enumerable,ReentrancyGuard  {
   using Strings for uint256;
   using SafeMath for uint256;
   using Counters for Counters.Counter;
   using SafeERC20 for IERC20;

   Counters.Counter private _tokenIds;
   string private _baseURIextended;
   string private _imageAdress;
   struct sNftPropertys {
     string tokenURI;
       uint256 value;
       uint256[7] propertys;
       uint256 lastUpdateTime;
   }
    uint256 maxValue=108;

   mapping(uint256 => sNftPropertys) private _NftPropertys;

   struct sInviter {
       address inviter;
       uint256 inviterNum;
       uint256 benefitsInvitation_FBX;
       uint256 benefitsInvitation_Forth;
   }
   mapping(address => sInviter) private _inviters;
   mapping(address => uint256) private _mintNum;

   uint256 public usdt_FeedPrice = 20*10**18;
   uint256 private FBX_feedingProportion=90;
   uint256 private FeedFBXPrice = 233*10**18;
   uint256 private FeedForhtPrice = 4*10**17;
   IERC20 public FBXToken;
   IERC20 public ForthToken;
   address public FundAdress;

   bool public bChangePriceAuto = false;
   address public usdtAddress;// 0x55d398326f99059fF775485246999027B3197955;
   IUniswapV2Router01 private pancakeRouter01;//0x10ED43C718714eb63d5aA57B78B54704E256024E

   uint256 public totlaFeedUsdt=0;

   IStakingRewards public DeFi_NFT_FBXToken;
   bool private bFreshDeFiNFT = false;

   uint256[7] public upgradePropertysFBXPrice=[10**19,10**19,10**19,10**19,10**19,10**19,10**19];
  event Feed(address indexed feeder,uint256 tokenId);
  event Feeds(address indexed feeder,uint256[] tokenIds);
  event Upgrade_Propertys(address indexed owner,uint256 tokenId,uint256 ith,uint256 degree);
  event AddInviters(address indexed owner,address indexed Inviter);

  constructor () ERC721("ForthBox Ham NFT", "Ham NFT") {
  }

  //---view---//
  function _baseURI() internal view virtual override returns (string memory) {
      return _baseURIextended;
  }
  function bExistsID(uint256 tokenId) public view returns (bool) {
      return _exists(tokenId);
  }
  function getBenefitsInvitation_FBX(address address1) public view returns(uint256){
     return _inviters[address1].benefitsInvitation_FBX;
  }
  function getInviterNum(address address1) public view returns(uint256){
     return _inviters[address1].inviterNum;
  }
  function getBenefitsInvitation_Forth(address address1) public view returns(uint256){
     return _inviters[address1].benefitsInvitation_Forth;
  }
  function getValueByTokenId(uint256 tokenId) external view returns(uint256){
     require(_exists(tokenId), "ERC721: Existent ID");
     return _NftPropertys[tokenId].value;
  }
  function getPropertysByTokenId(uint256 tokenId) external view returns(uint256[] memory){
     require(_exists(tokenId), "ERC721: Existent ID");
     uint256 num = _NftPropertys[tokenId].propertys.length;
     uint256[] memory Token_list = new uint256[](uint256(num));
    for(uint256 i=0; i<num; ++i) {
        Token_list[i] =_NftPropertys[tokenId].propertys[i];
    }
     return Token_list;
  }
  struct sNftPro {
      uint256 ID;
      uint256 value;
      uint256 hashrate;
      uint256 lastUpdateTime;
      uint256[7] propertys;
  }
  function getPropertiesByTokenIds(uint256[] calldata tokenIdArr ) external view returns(uint256[] memory){
      for(uint256 i=0; i<tokenIdArr.length; ++i) {
        require(_exists(tokenIdArr[i]), "ERC721: Existent ID");
      }
     uint256[] memory tPropertyArr = new uint256[](uint256(11*tokenIdArr.length));
     uint256 ith=0;
     for(uint256 i=0; i<tokenIdArr.length; ++i) {
       tPropertyArr[ith] = tokenIdArr[i]; ith++;
       tPropertyArr[ith] =_NftPropertys[tokenIdArr[i]].value; ith++;
       tPropertyArr[ith] = getHashrateByTokenId(tokenIdArr[i]); ith++;
       tPropertyArr[ith] =_NftPropertys[tokenIdArr[i]].lastUpdateTime; ith++;
      for(uint256 j=0; j<7; ++j){
          tPropertyArr[ith] = _NftPropertys[tokenIdArr[i]].propertys[j]; ith++;
      }
     }
     return tPropertyArr;
  }


  function getHashrateByTokenId(uint256 tokenId) public view returns(uint256)  {
     require(_exists(tokenId), "ERC721: Existent ID");
     if(_NftPropertys[tokenId].value==0){
        return 1;
     }
     if(_NftPropertys[tokenId].value<=9){
        return _NftPropertys[tokenId].value.mul(200);
     }
     if(_NftPropertys[tokenId].value<=44){
        return (_NftPropertys[tokenId].value.mul(100)).add(900);
     }
     if(_NftPropertys[tokenId].value<=87){
        return (_NftPropertys[tokenId].value.mul(200)).sub(3500);
     }
     if(_NftPropertys[tokenId].value<=maxValue){
        return (_NftPropertys[tokenId].value.mul(100)).add(5200);
     }
     return 0;
  }
  function getLastUpdateTimeByTokenId(uint256 tokenId) external view returns(uint256){
     require(_exists(tokenId), "ERC721: Existent ID");
     return _NftPropertys[tokenId].lastUpdateTime;
  }
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory){
    require(_exists(tokenId), "FBXNFT: URI query for nonexistent token");
    string memory base = _baseURI();
    string memory imageAdress = _imageAdress;
    uint256 H = getHashrateByTokenId(tokenId);
    string memory json1;
    if (bytes(base).length != 0) {
          json1 = string(abi.encodePacked(
            '{"name":"ForthBoxNFT",',
            '"description":"Platform NFT",',
            '"image":"',imageAdress, '",',
            '"base":"',base, '",',
            '"id":',Strings.toString(tokenId), ',',
            '"degree":',Strings.toString(_NftPropertys[tokenId].value), ',',
            '"hashrate":',Strings.toString(H), ','
            ));
      }
      else
      {
          json1 = string(abi.encodePacked(
            '{"name":"ForthBoxNFT",',
            '"description":"Platform NFT",',
            '"image":"',imageAdress, '",',
            '"id":',Strings.toString(tokenId), ',',
            '"degree":',Strings.toString(_NftPropertys[tokenId].value), ',',
            '"hashrate":',Strings.toString(H), ','
            ));
      }
    string memory json2 = string(abi.encodePacked(
        '"property":[',Strings.toString(_NftPropertys[tokenId].propertys[0]), ',',
        Strings.toString(_NftPropertys[tokenId].propertys[1]), ',',
        Strings.toString(_NftPropertys[tokenId].propertys[2]), ',',
        Strings.toString(_NftPropertys[tokenId].propertys[3]), ','
        ));
    string memory json3 = string(abi.encodePacked(
        Strings.toString(_NftPropertys[tokenId].propertys[4]), ',',
        Strings.toString(_NftPropertys[tokenId].propertys[5]), ',',
        Strings.toString(_NftPropertys[tokenId].propertys[6]), ']'
        ));
    string memory jsonAll = string(abi.encodePacked(
        json1,json2,json3,'}'
        ));
    return jsonAll;
  }

  function getPathUsdtToFBX() private view returns (address[] memory) {
     address[] memory path = new address[](2);
     path[0] = address(FBXToken);
     path[1] = usdtAddress;
     return path;
   }
   function getPathUsdtToForth() private view returns (address[] memory) {
      address[] memory path = new address[](2);
      path[0] = address(ForthToken);
      path[1] = usdtAddress;
      return path;
    }
  function getUsdtFBXForthPrice() public view returns (uint256,uint256) {
      uint256[] memory price1 = pancakeRouter01.getAmountsOut(10**18,getPathUsdtToFBX());
      uint256[] memory price2 = pancakeRouter01.getAmountsOut(10**18,getPathUsdtToForth());
      return (price1[1],price2[1]);
  }
  function getUsdtFBXPrice() public view returns (uint256) {
      uint256[] memory price1 = pancakeRouter01.getAmountsOut(10**18,getPathUsdtToFBX());
      return price1[1];
  }
  function getFBXFeedingProportion(uint256 price) public view returns (uint256 ) {
    if(!bChangePriceAuto){
       return FBX_feedingProportion;
    }else{
        uint256 feedingProportion=85;
        if(price<=15*10**15) {
          feedingProportion = 90;
          return feedingProportion;
        }
        if(price<=30*10**15){
          feedingProportion = 80;
          return feedingProportion;
        }
        if(price<=60*10**15){
          feedingProportion = 70;
          return feedingProportion;
        }
        if(price<=80*10**15){
          feedingProportion = 60;
          return feedingProportion;
        }
        if(price<=1*10**17){
          feedingProportion = 50;
          return feedingProportion;
        }
        if(price<=3*10**17){
          feedingProportion = 40;
          return feedingProportion;
        }
        if(price<=5*10**17){
          feedingProportion = 30;
          return feedingProportion;
        }
        if(price<=9*10**17){
          feedingProportion = 20;
          return feedingProportion;
        }
        feedingProportion = 10;
        return feedingProportion;
    }
  }
  function feedFBXForthPrice() public view returns (uint256,uint256) {
    if(!bChangePriceAuto){
       return (FeedFBXPrice,FeedForhtPrice);
    }else{
      uint256 tUsdt2FBX = 100*10**18;
      uint256 tUsdt2Forth = 1*10**18;
      (tUsdt2FBX,tUsdt2Forth) = getUsdtFBXForthPrice();
      uint256 feedingProportion =  getFBXFeedingProportion(tUsdt2FBX);
      uint256 tFeedFBXPrice = usdt_FeedPrice.mul(feedingProportion).div(100).mul(10**18).div(tUsdt2FBX);
      uint256 tFeedFothPrice=100;
      tFeedFothPrice = usdt_FeedPrice.mul(tFeedFothPrice.sub(feedingProportion)).div(100).mul(10**18).div(tUsdt2Forth);
      return (tFeedFBXPrice,tFeedFothPrice);
    }
  }
  function feedFBXOnlyPrice() public view returns (uint256) {
    if(!bChangePriceAuto){
       return FeedFBXPrice.mul(100).div(FBX_feedingProportion);
    }else{
      uint256 tFeedFBXPrice = usdt_FeedPrice.mul(10**18).div(getUsdtFBXPrice());
      return tFeedFBXPrice;
    }
  }
  function getParameters(address account) public view returns (uint256[] memory){
      uint256[] memory paraList = new uint256[](uint256(8));
      paraList[0]=totlaFeedUsdt;
      uint256 tFeedFBXPrice;
      uint256 tFeedForhtPrice;
      (tFeedFBXPrice,tFeedForhtPrice) = feedFBXForthPrice();
      paraList[1]=tFeedFBXPrice;
      paraList[2]=tFeedForhtPrice;
      paraList[3]=totalSupply();
      paraList[4]=getBenefitsInvitation_FBX(account);
      paraList[5]=getBenefitsInvitation_Forth(account);
      paraList[6]=getInviterNum(account);
      if(!bChangePriceAuto){
        paraList[7]=FeedFBXPrice;
      }else{
        paraList[7]=getUsdtFBXPrice();
      }
      return paraList;
  }

  //---write---//
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
      super._beforeTokenTransfer(from, to, tokenId);
  }
  function _burn(uint256 tokenId) internal override(ERC721) {
      super._burn(tokenId);
      delete _NftPropertys[tokenId];
  }
  function burnNFT(uint256 tokenId) public returns (uint256) {
      require(_msgSender() == ownerOf(tokenId),"ForthBoxNFT: Only the owner of this Token could Burn It!");
      _burn(tokenId);
      return tokenId;
  }
  function mintNFT_AddInviter(address Inviter) public returns (uint256) {
      require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
      addInviters(Inviter);
      return mintNFT();
  }
  function mintNFTs(uint256 num) public {
      require(num<=100, "ForthBoxNFT: num exceed 100!");
      require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
      for(uint256 i=0; i<num; ++i) {
          _mintNFT();
      }
      return;
  }
  function mintNFT() public returns (uint256) {
      require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
      return _mintNFT();
  }
  function _mintNFT() internal returns (uint256) {
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      _mint(_msgSender(), newItemId);
      _NftPropertys[newItemId].value=0;
      _mintNum[_msgSender()] = _mintNum[_msgSender()].add(1);
      return newItemId;
  }
  function transNFT(address _to,uint256 tokenId) public returns (uint256) {
      require(_msgSender() == ownerOf(tokenId),"ForthBoxNFT: Only the owner of this Token could transfer It!");
      require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
      _transfer(_msgSender(),_to,tokenId);
      return tokenId;
  }

  function feed_Foth_FBXs(uint256[] calldata tokenIds) nonReentrant public{
      require(tokenIds.length<=100, "ForthBoxNFT: num exceed 100!");
      require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
      _feedPay_Foth_FBX(tokenIds.length);
      for(uint256 i=0; i<tokenIds.length; ++i) {
          _feed_Foth_FBX(tokenIds[i]);
      }
      emit Feeds(_msgSender(), tokenIds);
      return;
  }
  function feed_Foth_FBX(uint256 tokenId) nonReentrant public{
      require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
      _feedPay_Foth_FBX(1);
      _feed_Foth_FBX(tokenId);
      emit Feed(_msgSender(), tokenId);
      return;
  }
  function _feed_Foth_FBX(uint256 tokenId) internal{
      if(_msgSender() != ownerOf(tokenId)){
         if(bFreshDeFiNFT){
           require(_msgSender() == DeFi_NFT_FBXToken.ownerTokenId(tokenId), "ForthBoxNFT: 1 Only the owner of this Token could feed it");
         }
         else{
           require(_msgSender() == ownerOf(tokenId), "ForthBoxNFT: 2 Only the owner of this Token could feed it");
         }
      }
      require(_exists(tokenId), "ERC721: Existent ID");
      require(block.timestamp >= _NftPropertys[tokenId].lastUpdateTime + 12*3600,"ForthBoxNFT: onwer can only feed once in 12 hours!");
      require(_NftPropertys[tokenId].value<maxValue, "ForthBoxNFT: exceed max Degree");

     _NftPropertys[tokenId].value=_NftPropertys[tokenId].value.add(1);
     _NftPropertys[tokenId].lastUpdateTime = block.timestamp;

     if(bFreshDeFiNFT && _msgSender() != ownerOf(tokenId)){
        DeFi_NFT_FBXToken.stakeFresh(_msgSender(),tokenId);
     }
     return ;
  }
  function _feedPay_Foth_FBX(uint256 num) internal{
     uint256 tFeedFBXPrice;
     uint256 tFeedForhtPrice;
     (tFeedFBXPrice,tFeedForhtPrice) = feedFBXForthPrice();
     tFeedFBXPrice = tFeedFBXPrice.mul(num);
     tFeedForhtPrice = tFeedForhtPrice.mul(num);
     address address1 =  _inviters[_msgSender()].inviter;
     if(address1==address(0)){
         FBXToken.safeTransferFrom(_msgSender(), address(0), tFeedFBXPrice);
         ForthToken.safeTransferFrom(_msgSender(), FundAdress, tFeedForhtPrice);
     }
     else{
       address address2 =  _inviters[address1].inviter;
       if(address2==address(0))
       {
           FBXToken.safeTransferFrom(_msgSender(), address1, tFeedFBXPrice.mul(10).div(100));
           FBXToken.safeTransferFrom(_msgSender(), address(0), tFeedFBXPrice.mul(90).div(100));

           ForthToken.safeTransferFrom(_msgSender(), address1, tFeedForhtPrice.mul(10).div(100));
           ForthToken.safeTransferFrom(_msgSender(), FundAdress, tFeedForhtPrice.mul(90).div(100));

           _inviters[address1].benefitsInvitation_FBX = _inviters[address1].benefitsInvitation_FBX.add(tFeedFBXPrice.mul(10).div(100));
           _inviters[address1].benefitsInvitation_Forth = _inviters[address1].benefitsInvitation_Forth.add(tFeedForhtPrice.mul(10).div(100));
       }
       else
       {
         FBXToken.safeTransferFrom(_msgSender(), address1, tFeedFBXPrice.mul(10).div(100));
         FBXToken.safeTransferFrom(_msgSender(), address2, tFeedFBXPrice.mul(5).div(100));
         FBXToken.safeTransferFrom(_msgSender(),address(0),tFeedFBXPrice.mul(85).div(100));

         ForthToken.safeTransferFrom(_msgSender(), address1, tFeedForhtPrice.mul(10).div(100));
         ForthToken.safeTransferFrom(_msgSender(), address2, tFeedForhtPrice.mul(5).div(100));
         ForthToken.safeTransferFrom(_msgSender(), FundAdress,tFeedForhtPrice.mul(85).div(100));

         _inviters[address1].benefitsInvitation_FBX = _inviters[address1].benefitsInvitation_FBX.add(tFeedFBXPrice.mul(10).div(100));
         _inviters[address1].benefitsInvitation_Forth = _inviters[address1].benefitsInvitation_Forth.add(tFeedForhtPrice.mul(10).div(100));

         _inviters[address2].benefitsInvitation_FBX = _inviters[address2].benefitsInvitation_FBX.add(tFeedFBXPrice.mul(5).div(100));
         _inviters[address2].benefitsInvitation_Forth = _inviters[address2].benefitsInvitation_Forth.add(tFeedForhtPrice.mul(5).div(100));
       }
     }
     totlaFeedUsdt =totlaFeedUsdt.add(usdt_FeedPrice.mul(num));
  }
  function upgrade_Propertys(uint256 tokenId,uint256 ith,uint256 degree) nonReentrant external{
       require(_exists(tokenId), "ForthBoxNFT: Existent ID");
       require(ith<7, "ForthBoxNFT: Existent ith");
       require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");

       FBXToken.safeTransferFrom(_msgSender(), FundAdress, upgradePropertysFBXPrice[ith].mul(degree));
       _NftPropertys[tokenId].propertys[ith]=_NftPropertys[tokenId].propertys[ith].add(degree);
       emit Upgrade_Propertys(_msgSender(),tokenId,ith,degree);
  }
  function addInviters(address Inviter) internal{
       require(_msgSender() != Inviter,"ForthBoxNFT: Inviter cannot be self!");
       require(Inviter != address(0), "ForthBoxNFT: Inviter cannot be zero address!");
       require(isWhiteContract(_msgSender()), "ForthBoxNFT: Contract not in white list!");
       if(_mintNum[_msgSender()] > 0) return;

       if(_inviters[_msgSender()].inviter!= address(0) && _inviters[_inviters[_msgSender()].inviter].inviterNum>0){
           _inviters[_inviters[_msgSender()].inviter].inviterNum = _inviters[_inviters[_msgSender()].inviter].inviterNum.sub(1);
       }
       _inviters[_msgSender()].inviter = Inviter;
       _inviters[Inviter].inviterNum = _inviters[Inviter].inviterNum.add(1);
       emit AddInviters(_msgSender(),Inviter);
  }

  //---write onlyOwner---//
  function setTokens(address tFBXToken,address tForhToken,address fund_Adress) external onlyOwner {
      FBXToken = IERC20(tFBXToken);
      ForthToken = IERC20(tForhToken);
      FundAdress = fund_Adress;
  }
  function setTokensDeFi(address tDeFi_NFT_FBXToken,bool tBFreshDeFiNFT) external onlyOwner {
      DeFi_NFT_FBXToken = IStakingRewards(tDeFi_NFT_FBXToken);
      bFreshDeFiNFT = tBFreshDeFiNFT;
  }
  function setChangePriceTokens(address tUsdtAddress,address tPancakeRouter01,bool tbChangePriceAuto) external onlyOwner {
      usdtAddress = tUsdtAddress;
      pancakeRouter01 = IUniswapV2Router01(tPancakeRouter01);
      bChangePriceAuto = tbChangePriceAuto;
  }
  function setFeedUsdtPrice(uint256 tUsdt_FeedPrice) external onlyOwner {
      usdt_FeedPrice = tUsdt_FeedPrice;
  }
  function setBaseURI(string memory baseURI_) external onlyOwner {
      _baseURIextended = baseURI_;
  }
  function setImageAdress(string memory imageAdress) external onlyOwner {
      _imageAdress = imageAdress;
  }
  function setFeed_Price(uint256 newFeedFBXPrice,uint256 newFeedFothPrice) onlyOwner public{
      FeedFBXPrice = newFeedFBXPrice;
      FeedForhtPrice = newFeedFothPrice;
  }

  function setupgradePropertysFBXPrice(uint256[] calldata FBXPriceArr) onlyOwner external{
      require(FBXPriceArr.length==7, "ForthBoxNFT:length of FBXPriceArr is not 7");
      for (uint256 i=0; i < FBXPriceArr.length; i++){
          upgradePropertysFBXPrice[i]=FBXPriceArr[i];
      }
  }

  function setFBX_feedingProportion(uint256 newFBX_feedingProportion) onlyOwner public{
      FBX_feedingProportion = newFBX_feedingProportion;
  }

}