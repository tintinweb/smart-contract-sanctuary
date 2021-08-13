/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity 0.8.1;


contract UBI {
    mapping(address=>bool) public bidders;
    uint256 public totalBidders;
    uint256 public totalAmount;
    address public game;
    bool public claimable;

    constructor() public {
        game = msg.sender;
    }

    modifier onlyGame() {
        require(msg.sender == game, "only the game itself can do this");
        _;
    }

    function addBidder(address bidder, uint256 amount) public onlyGame {
        if (!bidders[bidder]) {
            bidders[bidder] = true;
            totalBidders = totalBidders + 1;
        }
        totalAmount = totalAmount + amount;
    }

    function endGame(address winner) public onlyGame {
        bidders[winner] = false;
        claimable = true;
        totalBidders = totalBidders - 1;
    }

    function eachGets() public view returns (uint256) {
        return totalAmount / totalBidders;
    }

    function claim() public onlyGame {
        require(claimable, "game isn't over yet");
        require(bidders[tx.origin], "theres nothing for you here");
        bidders[tx.origin] = false;
        if (eachGets() > addy().balance) {
            payable(tx.origin).transfer(addy().balance);
        } else {
            require(payable(tx.origin).send(eachGets()), "send failed");
        }
    }
    
    function addy() public view returns(address payable) {
        return payable(address(this));
    }
    
    fallback() external payable {
        
    }
}