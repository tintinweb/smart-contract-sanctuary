// SPDX-License-Identifier: UNLICENSED
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

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract EnglishAuctionPropy {
    using SafeMath for uint256;

    // System settings
    address public deployer;
    uint256 public id;
    address public token;
    bool public ended = false;
    mapping (address => bool) private blacklistedBidders;
    
    // Current winning bid
    uint256 public lastBid;
    address payable public winning;
    
    uint256 public length;
    uint256 public startTime;
    uint256 public endTime;
    
    address payable public haus;
    address payable public seller;
    
    event Bid(address who, uint256 amount);
    event Won(address who, uint256 amount);
    
    constructor(uint256 _id, uint256 _startTime) public {
        token = address(0x2dbC375B35c5A2B6E36A386c8006168b686b70D3);
        id = _id;
        startTime = _startTime;
        length = 24 hours;
        endTime = startTime + length;
        lastBid = 7.5 ether;
        seller = payable(address(0x36228C2A182101e4Cb8a6519C0689b0d75775587));
        haus = payable(address(0x15884D7a5567725E0306A90262ee120aD8452d58));
        deployer = msg.sender;
    }
    
    function bid() public payable {
        require(blacklistedBidders[msg.sender] == false, "blacklisted address");
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= startTime, "Auction not started");
        require(block.timestamp < endTime, "Auction ended");
        require(msg.value >= lastBid.mul(102).div(100), "Bid too small"); // 2% increase
        
        // Give back the last bidders money
        if (winning != address(0)) {
            winning.transfer(lastBid);
        }
        
        if (endTime - now < 15 minutes) {
            endTime = now + 15 minutes;
        }
        
        lastBid = msg.value;
        winning = msg.sender;
        emit Bid(msg.sender, msg.value);
    }
    
    function end() public {
        require(!ended, "end already called");
        require(winning != address(0), "no bids");
        require(!live(), "Auction live");
        // transfer erc721 to winner
        IERC721(token).safeTransferFrom(address(seller), winning, id); // Will transfer ERC721 from current owner to new owner
        uint256 balance = address(this).balance;
        uint256 hausFee = balance.div(20);
        haus.transfer(hausFee);
        seller.transfer(address(this).balance);
        ended = true;
        emit Won(winning, lastBid);
    }

    function addToBlacklist(address _toBlacklist) public {
        require(msg.sender == deployer, "must be deployer");
        blacklistedBidders[_toBlacklist] = true;
    }

    function removeFromBlacklist(address _toBlacklist) public {
        require(msg.sender == deployer, "must be deployer");
        blacklistedBidders[_toBlacklist] = false;
    }
    
    function live() public view returns(bool) {
        return block.timestamp < endTime;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}