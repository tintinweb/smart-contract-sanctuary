// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
// import "https://github.com/0xcert/ethereum-erc721/blob/master/src/contracts/tokens/nf-token-metadata.sol";
// import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";

import "./nf-token-metadata.sol";
import "./safemath.sol";
import "./ownable.sol";
// import "./IAttr.sol";

interface IURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract MBNFT is NFTokenMetadata, Ownable, Context {
  using SafeMath for uint256;

  constructor() {
    nftName = "MonsterNFT";
    nftSymbol = "MBNFT";
    updateAdminAddress(_msgSender(), true);
  }
  
  mapping(address => bool) public adminAddress;

  modifier onlyOwnerOrAdminAddress()
  {
    require(adminAddress[_msgSender()], "permission denied");
    _;
  }
  function updateAdminAddress(address newAddress, bool flag) public onlyOwner {
    require(adminAddress[newAddress] != flag, "The adminAddress already has that address");
    adminAddress[newAddress] = flag;
  }
  
  
  
  event Mint(address, uint256);
  function mint(address _to, uint256 tkId, string calldata i) external onlyOwnerOrAdminAddress returns(uint256) {
    super._mint(_to, tkId);
    super._setTokenUri(tkId, i);
    emit Mint(_to, tkId);
    return tkId;
  }
  
  event Burn(uint256);
  function burn(uint256 tokenId) external onlyOwnerOrAdminAddress{
    super._burn(tokenId);
    // nftAttrAddress.delNftInfo(tokenId);
    emit Burn(tokenId);
  }
    
 
  mapping(address => uint256[]) public _ownerTokens;
  // mapping(address => NftInfo[]) public _ownerTokensAndInfo;
  event OwnerTokenRemove(address, uint256, uint256[]);
  
  function tokenOfOwnerGet(address _owner) public view returns (uint256[] memory){
    return _ownerTokens[_owner];
  }
  
  function tokenOfOwnerByIndex(address _owner, uint256 index) public view override returns (uint256 tokenId) {
    return _ownerTokens[_owner][index];
  }

  function tokenByIndex(uint256 index) public view override returns (uint256) {
    return tokens[index];
  }
  
  function _tokenOfOwnerRemove(address owner,uint256 tokenId) internal {
    bool found = false;
    uint j = 0;
    uint lastIndex = _ownerTokens[owner].length - 1;
    for(uint i = 0;i <= lastIndex; i++) {
        if (_ownerTokens[owner][i] == tokenId){
          found = true;
          j = i;
          break;
        }
    } 
    if(found) {
      _ownerTokens[owner][j] = _ownerTokens[owner][lastIndex]; 
      _ownerTokens[owner].pop(); 
    }
    
  }

  function _tokenOfOwnerAdd(address owner, uint256 tokenId) internal {
    _ownerTokens[owner].push(tokenId);
  }
  
  uint256[] internal tokens;
  mapping(uint256 => uint256) internal idToIndex;
  
  function totalSupply()
    external
    view
    override
    returns (uint256)
  {
    return tokens.length;
  }
  
  function _addTokens(uint256 _tokenId) internal {
      tokens.push(_tokenId);
      idToIndex[_tokenId] = tokens.length - 1;
  }
  
  function _delTokens(uint256 _tokenId) internal {
    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];
    tokens[tokenIndex] = lastToken;
    tokens.pop();
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }
  
  function _removeNFToken(address _from, uint256 _tokenId)internal override virtual{
    super._removeNFToken(_from, _tokenId);
    _tokenOfOwnerRemove(_from, _tokenId);
    _delTokens(_tokenId);
  }

  /**
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @dev Assigns a new NFT to owner.
   * @param _to Address to which we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken( address _to, uint256 _tokenId)internal override virtual{
    super._addNFToken(_to, _tokenId);
    _tokenOfOwnerAdd(_to, _tokenId);
    _addTokens(_tokenId);
  }
  
  function baseImage(uint256 _tokenId) public view returns (string memory) {
      return idToUri[_tokenId];
  }
  
  address public tokenUriAddress;
  
  function updateTokenUriAddress(address _addr) public onlyOwnerOrAdminAddress {
      tokenUriAddress = _addr;
  }

  function tokenURI(uint256 _tokenId) external override view returns (string memory){
        if(tokenUriAddress == address(0)) {
            return baseImage(_tokenId);
        }   
        return IURI(tokenUriAddress).tokenURI(_tokenId);
  }
  
}