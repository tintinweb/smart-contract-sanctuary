/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

contract MyNFT {
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

contract MyToken {
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address tokenOwner) public view returns (uint) {}
    function transfer(address receiver, uint numTokens) public returns (bool) {}
    function approve(address delegate, uint numTokens) public returns (bool) {}
    function allowance(address owner, address delegate) public view returns (uint) {}
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {}
}

contract BuyNFT {
    address private nftAddress = 0x00458cac4861Eca7431ab24a605816E304c229B9;
    address private erc20Address = 0xcfB9B623f4d7df8250a63238fD31800Db444c947;

    mapping(uint256 => bool) private allowSell;
    mapping(uint256 => uint256) private sellPrice;

    event Transaction(address _from, address _to, uint256 _tokenId);

    function setPrice(uint256 _tokenId, uint256 _price) external {
        require(MyNFT(nftAddress).ownerOf(_tokenId) == msg.sender);
        allowSell[_tokenId] = true;
        sellPrice[_tokenId] = _price;
    }

    function getPrice(uint256 _tokenId) external view returns (uint256){
        require(allowSell[_tokenId]);
        return sellPrice[_tokenId];
    }

    function buyNFT(uint256 _tokenId) external {
        require(allowSell[_tokenId]);
        require(MyToken(erc20Address).balanceOf(msg.sender) >= sellPrice[_tokenId]);
        MyToken(erc20Address).transferFrom(MyNFT(nftAddress).ownerOf(_tokenId), msg.sender, sellPrice[_tokenId]);
        MyNFT(nftAddress).safeTransferFrom(MyNFT(nftAddress).ownerOf(_tokenId), msg.sender, _tokenId);
        allowSell[_tokenId] = false;

        emit Transaction(MyNFT(nftAddress).ownerOf(_tokenId), msg.sender, _tokenId);
    }
}