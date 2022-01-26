/**
 *Submitted for verification at FtmScan.com on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract NFTMarket {
    address immutable private owner;
    uint public tfee;
    address immutable public nft;
    address immutable public token;

    mapping (uint=>address) public sellerMap;
    mapping (uint=>uint) public priceMap;

    uint public minimumPrice = 1e18; 

    constructor (uint tfee_, address nft_, address token_){
        owner = msg.sender;
        tfee = tfee_;
        nft = nft_;
        token = token_;
    }

    event Asked(uint indexed id, address indexed seller, uint price);
    event Bidded(uint indexed id, address indexed seller, address indexed buyer, uint price, uint fee);
    event Cancelled(uint indexed id, address indexed seller);
 
    function setTfee(uint _tfee) external {
        require(msg.sender == owner, "Only owner");

        tfee = _tfee;
    }

    function setMinimumPrice(uint _minimumPrice) external {
        require(msg.sender == owner, "Only owner");

        minimumPrice = _minimumPrice;
    }

    function ask(uint tokenID, uint price) external {
        require(_isApprovedOrOwner(msg.sender, tokenID), "Not approved or owner");
        require(price > minimumPrice, "bad price");

        IERC721(nft).transferFrom(msg.sender, address(this), tokenID);

        sellerMap[tokenID] = msg.sender;
        priceMap[tokenID] = price;

        emit Asked(tokenID, msg.sender, price);
    }

    function bid(uint tokenID, uint _price) external {
        address seller = sellerMap[tokenID]; 
        require(seller != address(0), "Not asked");
        require(seller != msg.sender, "Your own token");

        uint price = priceMap[tokenID];
        require(_price == price, "Price is out of line");
        uint fee = (price * tfee) / 10000;

        IERC721(nft).transferFrom(address(this), msg.sender, tokenID);
        IERC20(token).transferFrom(msg.sender, seller, price - fee);
        IERC20(token).transferFrom(msg.sender, address(this), fee);
        
        sellerMap[tokenID] = address(0);
        priceMap[tokenID] = 0;

        emit Bidded(tokenID, seller, msg.sender, price, fee);
    }

    function cancel(uint tokenID) external {
        address seller = sellerMap[tokenID];

        require(seller == msg.sender, 'Not yours');

        IERC721(nft).transferFrom(address(this), msg.sender, tokenID);
        sellerMap[tokenID] = address(0);
        priceMap[tokenID] = 0;

        emit Cancelled(tokenID, msg.sender);
    }

    function withdrawal(address recipient, uint amount) external {
        require(msg.sender == owner, "Only Owner");

        IERC20(token).transfer(recipient, amount);
    }

    function _isApprovedOrOwner(address operator, uint256 tokenId) private view returns (bool) {
        address TokenOwner = IERC721(nft).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(nft).getApproved(tokenId) == operator || IERC721(nft).isApprovedForAll(TokenOwner, operator));
    }

}