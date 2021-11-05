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

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

contract EnglishAuctionReservePriceClonable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    // System settings
    uint8 public percentageIncreasePerBid;
    uint256 public stakingRewardPercentageBasisPoints;
    uint256 public tokenId;
    address public tokenAddress;
    bool public ended = false;
    address public controller;
    address public deployer;
    
    // Current winning bid
    uint256 public lastBid;
    address payable public winning;
    
    uint256 public length;
    uint256 public minimumStartTime;
    uint256 public startTime;
    uint256 public endTime;
    
    address public hausAddress;
    address public stakingSwapContract;
    
    event Bid(address who, uint256 amount);
    event Won(address who, uint256 amount);
    
    function initialize(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _reservePriceWei,
        uint256 _minimumStartTime,
        uint256 _stakingRewardPercentageBasisPoints,
        uint8 _percentageIncreasePerBid,
        address _hausAddress,
        address _stakingSwapContract,
        address _controllerAddress
    ) external {
        require(hausAddress == address(0), "Already initialized");
        require(_hausAddress != address(0));
        tokenAddress = address(_tokenAddress);
        tokenId = _tokenId;
        lastBid = _reservePriceWei;
        percentageIncreasePerBid = _percentageIncreasePerBid;
        stakingSwapContract = _stakingSwapContract;
        hausAddress = _hausAddress;
        controller = _controllerAddress;
        minimumStartTime = _minimumStartTime;
        deployer = _controllerAddress;
        stakingRewardPercentageBasisPoints = _stakingRewardPercentageBasisPoints;
    }
    
    function bid() public payable {
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= minimumStartTime, "Bidding has not opened");
        
        // Give back the last bidders money
        if (winning != address(0)) {
            require(block.timestamp >= startTime, "Auction not started");
            require(block.timestamp < endTime, "Auction ended");
            uint8 base = 100;
            uint256 multiplier = base.add(percentageIncreasePerBid);
            require(msg.value >= lastBid.mul(multiplier).div(100), "Bid too small"); // % increase
            winning.transfer(lastBid);
        } else {
            require(msg.value >= lastBid, "Bid too small"); // no increase required for reserve price to be met
            // First bid, reserve met, start auction
            startTime = block.timestamp;
            length = 24 hours;
            endTime = startTime + length;
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
        // transfer erc1155 to winner
        IERC1155(tokenAddress).safeTransferFrom(address(this), winning, tokenId, 1, new bytes(0x0)); // Will transfer IERC1155 from current owner to new owner
        uint256 stakingReward = address(this).balance.mul(stakingRewardPercentageBasisPoints).div(10000);
        (bool stakingRewardSuccess, ) = stakingSwapContract.call{value: stakingReward}("");
        require(stakingRewardSuccess, "Staking reward transfer failed.");
        (bool successMultisig, ) = hausAddress.call{value: address(this).balance}("");
        require(successMultisig, "Multisig transfer failed.");
        ended = true;
        emit Won(winning, lastBid);
    }
    
    function pull() public {
        require(msg.sender == controller, "must be controller");
        require(!ended, "end already called");
        require(winning == address(0), "There were bids");
        require(!live(), "Auction live");
        // transfer erc1155 to controller
        IERC1155(tokenAddress).safeTransferFrom(address(this), controller, tokenId, 1, new bytes(0x0));
        ended = true;
    }
    
    function live() public view returns(bool) {
        return block.timestamp < endTime;
    }

    function containsAuctionNFT() public view returns(bool) {
        return IERC1155(tokenAddress).balanceOf(address(this), tokenId) > 0;
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}