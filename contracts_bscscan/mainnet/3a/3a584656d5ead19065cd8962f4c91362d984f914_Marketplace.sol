/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

pragma solidity 0.8.6;

// "SPDX-License-Identifier: MIT"

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


abstract contract ERC721Interface {
  function approve(address to, uint256 tokenId) public virtual;
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract Marketplace is IERC721Receiver, Owned {
    using SafeMath for uint;

    uint256 public minPrice;
    uint256 public sellId;
    uint256 public period;
    uint256 public fee;
    uint256 public feeDenominator;
    address public feeAddr;
    
    event Sell(uint256 sellId, address contractAddress, uint256 tokenId, uint256 price, uint256 endTime);
    event Bid(uint256 sellId, uint256 price, address bidder);
    event Abort(uint256 sellId);
    event Extend(uint256 sellId, uint256 endTime);
    event Get(uint256 sellId);
    event Payout(uint256 sellId);
    event Verify(address sender, string code);
    
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
        fee = 3; // 0.3%
        feeDenominator = 1000;
        feeAddr == 0x0000000024D5cbdd18b5dFA7A72fA3C0d18FF4B9;
        minPrice = 10**uint(16);
        period = 600;
    }
    
    function sellInfo(uint256 Id) public view returns (address seller, address contractAddress, uint256 tokenId, uint256 currentPrice, uint256 saleEndTime, address bidder, uint256 bids) {
        return (sale[Id].seller, sale[Id].contr, sale[Id].tokenId, sale[Id].price, sale[Id].endtime, sale[Id].bidder, sale[Id].bids);
    }
    
    function isSellActive(uint256 Id) public view returns (bool active, bool payout) {
        return (sale[Id].active, sale[Id].payout);
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
        emit Sell(sellId,contractAddress, tokenId, price, block.timestamp.add(sellTime));
        sellId = sellId.add(1);
        return sellId.sub(1);
    }
    
    function bid(uint256 Id) public payable {
        require(sale[Id].active);
        require(msg.value > sale[Id].price, "BID IS TOO LOW");
        require(block.timestamp < sale[Id].endtime, "AUCTION IS FINISHED");
        if (sale[Id].bids != 0) {
            (bool succ, ) = payable(sale[Id].bidder).call{value: sale[Id].price }("");
            require(succ, "TRANSFER FAILED"); }
        sale[Id].bidder = msg.sender;
        sale[Id].price = msg.value;
        sale[Id].bids = sale[Id].bids.add(1);
        
        emit Bid(Id, msg.value, msg.sender);
    }
    
    function abort(uint256 Id) public {
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(sale[Id].bids == 0, "CANNOT ABORT, SALE HAVE BIDS");
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Abort(Id);
    }
    
    function extendSell(uint256 Id, uint256 extendTime) public {
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(sale[Id].bids == 0, "CANNOT EXTEND, SALE HAVE BIDS");
        require(extendTime >= period, "EXTENDED PERIOD TOO LOW");
        sale[Id].endtime = block.timestamp.add(extendTime);
        emit Extend(Id, block.timestamp.add(extendTime));
    }
    
    function sellerGet(uint256 Id) public {
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(block.timestamp > sale[Id].endtime, "AUCTION IS NOT FINISHED");
        require(sale[Id].bids != 0, "NO BIDS - NO PAYOUTS");
        require(!sale[Id].payout, "ALREADY PAYED");
        pay(sale[Id].seller,sale[Id].price);
        sale[Id].payout = true;
        emit Payout(Id); 
    }

    function get(uint256 Id) public {
        require(sale[Id].bidder == msg.sender, "YOU ARE NOT A WINNER");
        require(block.timestamp > sale[Id].endtime, "AUCTION IS NOT FINISHED");
        // send ether to the seller
        if (sale[Id].payout == false) {
        pay(sale[Id].seller,sale[Id].price);
        sale[Id].payout = true;
        emit Payout(Id); }
        // send token to the winner
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Get(Id);
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function pay(address seller, uint256 amount) internal {
        (bool succ1, ) = payable(seller).call{value: amount.div(feeDenominator).mul(uint256(feeDenominator).sub(fee))}("");
        require(succ1, "TRANSFER1 FAILED");
        (bool succ2, ) = payable(feeAddr).call{value: amount.div(feeDenominator).mul(fee)}("");
        require(succ2, "TRANSFER2 FAILED");
    }
    
    function changeFee(uint _fee) public onlyOwner {
        require(_fee <= 10); // 1%
        fee = _fee;
    }
    
    function changeFeeAddr(address _feeAddr) public onlyOwner {
        feeAddr = _feeAddr;
    }
    
    function verification(string memory code) public {
        emit Verify(msg.sender, code);
    }
}