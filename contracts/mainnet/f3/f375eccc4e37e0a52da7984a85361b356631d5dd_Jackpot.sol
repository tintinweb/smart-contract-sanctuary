pragma solidity ^0.4.18;

contract Jackpot {

    uint64 public nextJackpotTime;
    bool public jackpotPaused;
    address public owner;
    uint public jackpotPersent = 100;
    uint public  winnerLimit = 1;
    uint public JackpotPeriods = 1;
    address public diceRollAddress;

    mapping (uint=>address) public winnerHistory;
    address[] public tempPlayer;

    event SendJackpotSuccesss(address indexed winner, uint amount, uint JackpotPeriods);
    event OwnerTransfer(address SentToAddress, uint AmountTransferred);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDiceRoll {
        require(msg.sender == diceRollAddress);
        _;
    }

    modifier jackpotAreActive {
        require(!jackpotPaused);
        _;
    }

    
    constructor() public {
        owner = msg.sender;
    }
    

    function() external payable {

    }

    function getWinnerHistory(uint periods) external view returns(address){
        return winnerHistory[periods];
    }

    function addPlayer(address add) public onlyDiceRoll jackpotAreActive{
        tempPlayer.push(add);
        
    }

    function createWinner() public onlyOwner jackpotAreActive {
        require(tempPlayer.length > 0);
        uint random = rand() % tempPlayer.length;
        address winner = tempPlayer[random];
        winnerHistory[JackpotPeriods] = winner;
        uint64 tmNow = uint64(block.timestamp);
        nextJackpotTime = tmNow + 72000;
        tempPlayer.length = 0;
        sendJackpot(winner, address(this).balance * jackpotPersent / 1000);
        JackpotPeriods += 1;
    }


    function sendJackpot(address winner, uint256 amount) internal {
        require(address(this).balance > amount);
        emit SendJackpotSuccesss(winner, amount,JackpotPeriods);
        winner.transfer(amount);
        
    }

    function seTJackpotPersent(uint newPersent) external onlyOwner{
        require(newPersent > 0 && newPersent < 1000);
        jackpotPersent = newPersent;
    }

    function rand() internal view returns (uint256) {
        return uint256(keccak256(msg.sender, blockhash(block.number - 1), block.coinbase, block.difficulty));
    }


    function ownerPauseJackpot(bool newStatus) public onlyOwner{
        jackpotPaused = newStatus;
    }

    function ownerSetdiceRollAddress(address add) public onlyOwner {
        diceRollAddress = add;
    }

    function ownerTransferEther(address sendTo, uint amount) public onlyOwner{    
        sendTo.transfer(amount);
        emit OwnerTransfer(sendTo, amount);
    }

}