/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.3;

abstract contract Helper {
    function getHighestBid() public virtual view returns (uint);
    function setHighestBid(uint) public virtual;
}

contract Bid {
    address public manager;
    address helperAddress;
    mapping(address => uint) canWithdraw;
    address highestBidder;
    Helper helper;
    bool isBidOpen =  true;

    constructor() {
        manager = msg.sender;
    }

    function enterBidding() public payable {
        uint highestBid = helper.getHighestBid();
        require(msg.value > highestBid, "Highest Bid is greater");
        require(isBidOpen);
        canWithdraw[highestBidder] = highestBid;
        helper.setHighestBid(msg.value);
        highestBidder = msg.sender;
    }

    function closeBid() public managerOnly returns (uint,address){
        isBidOpen = false;
        uint bid = helper.getHighestBid();
        return (bid,highestBidder);
    }

    function setHelperAddress(address _helperAddress) public {
        helperAddress = _helperAddress;
        helper = Helper(helperAddress);
    }

    function withdraw() public payable {
        require(msg.sender != highestBidder);
        uint amount = canWithdraw[msg.sender];
        if(amount!=0){
            payable(msg.sender).transfer(amount);
        }
        }
    modifier managerOnly {
        require(msg.sender == manager);
        _;
    }

    }