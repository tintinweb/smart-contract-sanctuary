/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 < 0.8.0;

contract ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address){}
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{}
    function approve(address _approved, uint256 _tokenId) external payable{}
}

contract ERC20 {
    function balanceOf(address tokenOwner) public view returns (uint) {}
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {}
    function approve(address delegate, uint numTokens) public returns (bool) {}
}

contract marketPlace {

  address private ADMIN = msg.sender;
  ERC721 private nftAddress = ERC721(0xcE016D273CFc1AD01F52adE439F6c73Fc8B4069d);
  ERC20 private tokenAddress = ERC20(0x370B21D93ED4BC3748E10541EEF3fCaa58038924);

  mapping(uint256 => uint256) tokenPriceDict;

  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId, uint256 _price);

  function setTokenPrice(uint256 _tokenId, uint256 _tokenPrice) public {
    require(msg.sender != address(0));
    require(nftAddress.ownerOf(_tokenId) == msg.sender, "You are not owner of this token");
    // require(ERC721(ERC721Address).ownerOf(_tokenId) == msg.sender, "You are not owner of this token");
    require(_tokenPrice > 0);

    nftAddress.approve(address(this), _tokenId);
    tokenPriceDict[_tokenId] = _tokenPrice;
  }

  function removeTokenForSell(uint256 _tokenId) public {
    require(msg.sender != address(0));
    require(nftAddress.ownerOf(_tokenId) == msg.sender, "You are not owner of this token");
    // require(ERC721(ERC721Address).ownerOf(_tokenId) == msg.sender, "You are not owner of this token");

    delete tokenPriceDict[_tokenId];
  }

  function checkTokenPrice(uint256 _tokenId) public view returns (uint) {
    return tokenPriceDict[_tokenId];
  }

  function purchaseToken(uint256 _tokenId) public {
    require(msg.sender != address(0));
    require(tokenPriceDict[_tokenId] > 0, "Token not for sell");
    uint256 _tokenPrice = tokenPriceDict[_tokenId];

    require(tokenAddress.balanceOf(msg.sender) >= _tokenPrice, "Don't have enough token");
    address tokenOwner = nftAddress.ownerOf(_tokenId);
    tokenAddress.approve(address(this), _tokenPrice);
    tokenAddress.transferFrom(msg.sender, tokenOwner, _tokenPrice);
    nftAddress.transferFrom(tokenOwner, msg.sender, _tokenId);
    // require(ERC20(ERC20Address).balanceOf(msg.sender) >= _tokenPrice, "Don't have enough token");
    // address tokenOwner = ERC721(ERC721Address).ownerOf(_tokenId);
    // ERC20(ERC20Address).transferFrom(msg.sender, tokenOwner, _tokenPrice);
    // ERC721(ERC721Address).transferFrom(tokenOwner, msg.sender, _tokenId);
    delete tokenPriceDict[_tokenId];

    emit Transfer(tokenOwner, msg.sender, _tokenId, _tokenPrice);
  }

}