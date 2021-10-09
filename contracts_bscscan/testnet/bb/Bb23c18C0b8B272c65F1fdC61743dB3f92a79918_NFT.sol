// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
// import "https://github.com/0xcert/ethereum-erc721/blob/master/src/contracts/tokens/nf-token-metadata.sol";
// import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";

import "./nf-token-metadata.sol";
import "./safemath.sol";
import "./ownable.sol";
// import "./IAttr.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// contract NFT is NFTokenMetadata, Ownable, Context, Attr {
contract NFT is NFTokenMetadata, Ownable, Context {
  using SafeMath for uint256;

  constructor() {
    nftName = "testMonsterNFT";
    nftSymbol = "TMNFT";
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
  
  // function tokenOfOwnerGetAndInfo(address _owner)external returns (NftInfo[] memory){
  //    delete _ownerTokensAndInfo[_owner];
  //    for (uint256 i = 0; i < _ownerTokens[_owner].length; i++){
  //        uint256 tokenId = _ownerTokens[_owner][i];
  //        NftInfo memory info = nftAttrAddress.getNftInfoMap(tokenId);
  //        _ownerTokensAndInfo[_owner].push(info);
  //    }
  //    return _ownerTokensAndInfo[_owner];
  // }
  
  function _tokenOfOwnerRemove(address owner,uint256 tokenId) internal returns(bool){
    uint256[] memory tokenList = _ownerTokens[owner];
  
    delete _ownerTokens[owner];
    for(uint i = 0;i < tokenList.length; i++) {
        uint256 el = tokenList[i];
        if (el != tokenId){
            _ownerTokens[owner].push(el);
        }
    }
    emit OwnerTokenRemove(owner, tokenId, _ownerTokens[owner]);
    return true;
        
  }
  function _tokenOfOwnerAdd(address owner, uint256 tokenId) internal returns(bool){
      _ownerTokens[owner].push(tokenId);
      return true;
  }
  
  uint256[] internal tokens;
  mapping(uint256 => uint256) internal idToIndex;
  
  function totalSupply()
    external
    view
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
  
}