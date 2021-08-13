/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity 0.8.1;


interface IBlackhole {
    function nextMinimumBet() external view returns(uint256);
    function bet() external payable;
    function win() external;
}
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

contract Greenhole is IBlackhole {
    
    address public previousWinner;
    address public feeTo;
    address public currentLeader;
    uint256 public currentBet;//amount of current bet in wei
    uint256 public lastBet;//time of last bet in seconds
    bool public currentGame;
    UBI[] public ubis;

    event NewBet(uint256 amount, address newLeader);
    event NewGameStarted(uint256 amount, address creator, address ubi);
    event Winrar(uint256 amount, address winner);
    
    constructor() {
        previousWinner = msg.sender;
        feeTo = msg.sender;
    }

    modifier onlyPreviousWinner() {
        require(msg.sender == previousWinner, "You aren't the previous winner");
        _;
    }

    function setFeeTo(address destination) public onlyPreviousWinner {
        feeTo = destination;
    }

    function nextMinimumBet() public override view returns(uint256) {
        if (currentGame) {
            return currentBet+1;
        } else {
            return 1000;
        }
    }
    
    function currentUBI() public view returns (UBI) {
        return ubis[ubis.length - 1];
    }

    function startNewGame() internal {
            currentGame = true;
            ubis.push(new UBI());
            emit NewGameStarted(msg.value, msg.sender, address(currentUBI()));
    }

    function bet() public override payable {
        require(msg.value >= nextMinimumBet(), "bet more");
        if (!currentGame) {
           startNewGame();
        }
        uint256 amount = msg.value;
        payable(feeTo).transfer(amount / 1000);
        uint256 ubiAmount = (amount / 20) * 7;
        currentUBI().addBidder(msg.sender, ubiAmount);
        payable(currentUBI().addy()).transfer(ubiAmount);
        currentBet = amount;
        lastBet = block.timestamp;
        currentLeader = msg.sender;
        emit NewBet(amount, msg.sender);
    }

    function win() public override {
        require(block.timestamp >= lastBet + 1 hours, "must be leader for 60 minutes to collect");
        require(msg.sender == currentLeader);
        emit Winrar(address(this).balance, msg.sender);
        payable(msg.sender).transfer(address(this).balance);
        currentUBI().endGame(msg.sender);
        currentGame = false;
        currentBet = 0;
        previousWinner = msg.sender;
        feeTo = msg.sender;
    }
    
    function claimUBI(uint256 index) public {
        currentUBI().claim();
    }
    

}