/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 < 0.8.0;

contract ERC721 {
    address private owner = msg.sender;
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external onlyOwner {}
    function getTokenURI(uint256 _tokenId) external view returns (string memory){}
    function balanceOf(address _owner) external view returns (uint256){}
    function ownerOf(uint256 _tokenId) external view returns (address){}
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable{}
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{}
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{}
    function approve(address _approved, uint256 _tokenId) external payable{}
    function setApprovalForAll(address _operator, bool _approved) external{}
    function getApproved(uint256 _tokenId) external view returns (address){}
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){}
}

contract ERC20 {
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address tokenOwner) public view returns (uint) {}
    function transfer(address receiver, uint numTokens) public returns (bool) {}
    function approve(address delegate, uint numTokens) public returns (bool) {}
    function allowance(address owner, address delegate) public view returns (uint) {}
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {}
}

contract marketPlace {

  address ADMIN = msg.sender;
  ERC721 public nftAddress;
  ERC20 public tokenAddress;

  mapping(uint256 => uint256) tokenPriceDict;

  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId, uint256 _price);

  constructor(address _nftAddress, address _tokenAddress) {
    require(_nftAddress != address(0));
    require(_tokenAddress != address(0));
    nftAddress = ERC721(_nftAddress);
    tokenAddress = ERC20(_tokenAddress);
  }

  function setTokenPrice(uint256 _tokenId, uint256 _tokenPrice) public {
    require(msg.sender != address(0));
    require(nftAddress.ownerOf(_tokenId) == msg.sender, "You are not owner of this token");
    require(_tokenPrice > 0);

    nftAddress.approve(ADMIN, _tokenId);
    tokenPriceDict[_tokenId] = _tokenPrice;
  }

  function checkTokenPrice(uint256 _tokenId) public view returns (uint) {
    return tokenPriceDict[_tokenId];
  }

  function purchaseToken(uint256 _tokenId) public {
    require(msg.sender != address(0));
    require(tokenPriceDict[_tokenId] > 0);
    uint256 _tokenPrice = tokenPriceDict[_tokenId];

    require(tokenAddress.balanceOf(msg.sender) >= _tokenPrice, "Don't have enough token");
    address tokenOwner = nftAddress.ownerOf(_tokenId);
    tokenAddress.transferFrom(msg.sender, tokenOwner, _tokenPrice);
    nftAddress.transferFrom(tokenOwner, msg.sender, _tokenId);
    delete tokenPriceDict[_tokenId];

    emit Transfer(tokenOwner, msg.sender, _tokenId, _tokenPrice);
  }

}