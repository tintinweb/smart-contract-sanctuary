/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract AddOrder {

    struct Order {
        uint256 orderId;
        address addr;
        address from;
        address to;
        uint256 tokenId;
        uint256 price;
        bool onSale;
    }

    Order[] public orderList;

    function addOrder(address _contractAddr,address _tokenOwner, uint256 _tokenId, uint256 _price) public {
        uint256 size = orderList.length;

        Order memory o = Order({
        orderId : size,
        addr: _contractAddr,
        from : _tokenOwner,
        to : address(0),
        tokenId : _tokenId,
        price : _price,
        onSale : true});

        orderList.push(o);
    }

    function endOrder(uint256 _orderId,address _tokenOwner) public{
        Order memory o=orderList[_orderId];
        require(o.from==_tokenOwner);
        
        o.onSale=false;
        orderList[_orderId]=o;
    }

    function buyToken(uint256 _orderId) public payable{
        Order memory o=orderList[_orderId];
        uint256 price=o.price;
        require(price==msg.value,"pay amount wrong");
        
        address contractAddr=o.addr;
        address from =o.from;
        address to = msg.sender;
        uint256 tokenId=o.tokenId;
        
        TestNft nft=TestNft(contractAddr);
        nft.transferFrom(from,to,tokenId);
        
        address payable pay=payable(from);
        pay.transfer(msg.value);
        
        o.onSale=false;
        orderList[_orderId]=o;
    }

    function getSize() public view returns (uint256){
        return orderList.length;
    }
}

abstract contract TestNft {
    function transferFrom(address _from, address _to, uint256 _tokenId) external virtual;
}