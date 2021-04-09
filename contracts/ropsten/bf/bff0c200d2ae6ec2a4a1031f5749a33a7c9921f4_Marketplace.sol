/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity 0.8.3;

// "SPDX-License-Identifier: MIT"

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}

abstract contract ERC721Interface {
  function approve(address to, uint256 tokenId) public virtual;
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract Marketplace is IERC721Receiver {
    using SafeMath for uint;

    uint256 public minPrice;
    uint256 public sellId;
    uint256 period;
    
    event Sell(uint256 sellId, address contractAddress, uint256 tokenId, uint256 price, uint256 sellTime);
    event Bid(uint256 sellId, uint256 price);
    event Abort(uint256 sellId);
    event Get(uint256 sellId);
    event Payout(uint256 sellId);
    
    struct Sales {
        address seller;
        address contr;
        address bidder;
        uint256 tokenId;
        uint256 price;
        uint256 endtime;
        uint256 bids;
        bool    active;
        bool    payout;
    }
    
    mapping (uint256 => Sales) sale;
    
    constructor() {
        minPrice = 10**uint(16);
        period = 600;
    }
    
    function sellInfo(uint256 Id) public view returns (address seller, address contractAddress, uint256 tokenId, uint256 currentPrice, uint256 saleEndTime, address bidder, uint256 bids) {
        return (sale[Id].seller, sale[Id].contr, sale[Id].tokenId, sale[Id].price, sale[Id].endtime, sale[Id].bidder, sale[Id].bids);
    }
    
    function isSellActive(uint256 Id) public view returns (bool) {
        return (sale[Id].active);
    }

    function sell(address contractAddress, uint256 tokenId, address from, uint256 price, uint256 sellTime) public returns (uint256 Id) { 
        require(price >= minPrice, "SELL PRICE TOO LOW");
        require(sellTime >= period, "AUCTION PERIOD TOO LOW");
        
        ERC721Interface(contractAddress).safeTransferFrom(from, address(this), tokenId);
        
        sale[sellId].active = true;
        sale[sellId].payout = false;
        sale[sellId].seller = msg.sender;
        sale[sellId].contr = contractAddress;
        sale[sellId].tokenId = tokenId;
        sale[sellId].price = price;
        sale[sellId].endtime = block.timestamp.add(sellTime);
       
        emit Sell(sellId,contractAddress, tokenId, price, sellTime);
        sellId = sellId.add(1);
        return sellId.sub(1);
    }
    
    function bid(uint256 Id) public payable {
        require(sale[Id].active);
        require(msg.value > sale[Id].price, "BID IS TOO LOW");
        require(block.timestamp < sale[Id].endtime, "AUCTION IS FINISHED");
        
        if (sale[Id].bids != 0) {
            (bool succ, ) = payable(sale[Id].bidder).call{value: sale[Id].price }("");
            require(succ, "TRANSFER FAILED");
        }

        sale[Id].bidder = msg.sender;
        sale[Id].price = msg.value;
        sale[Id].bids = sale[Id].bids.add(1);
        
        emit Bid(Id, msg.value);
    }
    
    function abort(uint256 Id) public {
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(sale[Id].bids == 0, "CANNOT ABORT, SALE HAVE BIDS");
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Abort(Id);
    }
    
    function ownerGet(uint256 Id) public {
        require(block.timestamp > sale[Id].endtime, "AUCTION IS NOT FINISHED");
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(sale[Id].bids != 0);
        require(sale[Id].payout = false);
        
        (bool succ, ) = payable(sale[Id].seller).call{value: sale[Id].price}("");
        require(succ, "TRANSFER FAILED");
        emit Payout(Id); 
        sale[sellId].payout = true;
    }

    function get(uint256 Id) public {
        require(sale[Id].bidder == msg.sender, "YOU ARE NOT A WINNER");
        require(block.timestamp > sale[Id].endtime, "AUCTION IS NOT FINISHED");
        
        // send ether to the seller
        if (sale[sellId].payout = false) {
        (bool succ, ) = payable(sale[Id].seller).call{value: sale[Id].price}("");
        require(succ, "TRANSFER FAILED");
        emit Payout(Id); }
        sale[sellId].payout = true;
        
        // send token to the winner
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Get(Id);
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    // REMOVE IN DEV

    function transferAnyERC721Token(address contractAddress, address from, address to, uint256 tokenId) public {
        ERC721Interface(contractAddress).safeTransferFrom(from, to, tokenId);
    }

}