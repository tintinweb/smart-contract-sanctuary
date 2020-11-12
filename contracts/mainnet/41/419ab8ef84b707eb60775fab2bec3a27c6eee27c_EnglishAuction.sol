pragma solidity ^0.6.7;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

contract EnglishAuction {
    using SafeMath for uint256;

    // System settings
    uint256 public id;
    address public token;
    bool public ended = false;
    uint256 public startBidTime;
    address payable public haus;
    address payable public seller;
    uint256 public bidLength = 12 hours;
    uint256 public auctionLength = 3 days;
    uint256 public minIncrease = 0.1 ether;

    // Current winning bid
    uint256 public lastBid;
    uint256 public lastBidTime;
    address payable public winning;

    event Bid(address who, uint256 amount);
    event Won(address who, uint256 amount);

    constructor(uint256 _start, address payable _seller, address payable _haus) public {
        token = address(0x13bAb10a88fc5F6c77b87878d71c9F1707D2688A);
        id = 5;
        startBidTime = _start;
        lastBid = 10 ether;
        seller = _seller;
        haus = _haus;
    }

    function bid() public payable {
        require(block.timestamp < startBidTime.add(auctionLength), "Auction ended");
        require(msg.value >= lastBid.add(minIncrease), "Bid too small");

        // Give back the last bidders money
        if (lastBidTime != 0) {
            require(block.timestamp < lastBidTime.add(bidLength), "Auction ended");
            winning.transfer(lastBid);
        }

        lastBid = msg.value;
        winning = msg.sender;
        lastBidTime = block.timestamp;

        emit Bid(msg.sender, msg.value);
    }

    function end() public {
        require(!ended, "end already called");
        require(lastBidTime != 0, "no bids");
        require(block.timestamp >= lastBidTime.add(bidLength) || block.timestamp >= startBidTime.add(auctionLength), "Auction live");

        // transfer erc1155 to winner
        IERC1155(token).safeTransferFrom(address(this), winning, id, 1, new bytes(0x0));

        uint256 balance = address(this).balance;
        uint256 hausFee = balance.div(20).mul(3);
        haus.transfer(hausFee);
        seller.transfer(address(this).balance);

        ended = true;

        emit Won(winning, lastBid);
    }

    function pull() public {
        require(!ended, "end already called");
        require(lastBidTime == 0, "There were bids");
        require(block.timestamp >= startBidTime.add(auctionLength), "Auction live");

        // transfer erc1155 to seller
        IERC1155(token).safeTransferFrom(address(this), seller, id, 1, new bytes(0x0));

        ended = true;
    }

    function live() external view returns(bool) {
        if (block.timestamp < lastBidTime.add(bidLength) && block.timestamp < startBidTime.add(auctionLength)) {
            return true;
        }
        return false;
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}