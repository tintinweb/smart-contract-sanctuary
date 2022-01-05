// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

contract DiceBetTracker {
    uint256 totalHouseMoney;

    // TODO: need to make of type storage
    struct Bet {
        uint256 betAmount;
        address gambler; // might be redundent field
        uint256 dicePick;
        uint256 diceRoll;
        bool isWin;
        uint256 payout;
        bool isFilled;
        // uint256 betTime; // TODO: how to store timestamps?
    }

    Bet[] public bookie;
    mapping(address => Bet[]) public addressToUserBets;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // Anyone can donate to the house
    function fund() public payable {
        totalHouseMoney += msg.value;
    }

    // Gamblers can make their bets as long as the bet amount is less than or equal to 0.5 Eth
    function makeBet(uint256 _dicePick) public payable {
        uint256 halfEth = 5 * 10**18;
        require(msg.value < halfEth, "Bet size must be less than 0.5 Eth");
        Bet storage bet;
        bet.betAmount = msg.value;
        bet.gambler = msg.sender;
        bet.dicePick = _dicePick;
        bet.isFilled = false;
        addressToUserBets[msg.sender].push(bet);
    }

//     House will fill the bet with the outcome of the off-chain dice roll
//     If win the payout will be 2:1 and if loss the house takes the money
    function houseFillBet(uint256 _diceRoll, address gambler)
        public
        payable
        onlyOwner
    {
        Bet memory bet = getBet(gambler);
        if (_diceRoll == bet.dicePick) {
            uint256 oneEth = 10 * 10**18;
            // TODO: add rounding to make sure payout is less than or equal to 1 Eth
            uint256 payout = bet.betAmount * 2;
            require(payout <= oneEth);
            bet.payout = payout;
            bet.isWin = true;
            bet.diceRoll = _diceRoll;
            bet.isFilled = true;
            totalHouseMoney -= payout;
        } else {
            // TODO: need to actually send payout to the gamblers address
            bet.payout = 0;
            bet.isWin = false;
            bet.diceRoll = _diceRoll;
            totalHouseMoney += bet.betAmount;
            bet.isFilled = true;
        }
    }

    function getBet(address gambler) internal returns (Bet memory) {
        Bet[] memory bets = addressToUserBets[gambler];
        bool unfilledBetFound = false;
        Bet memory firstUnfilledBet;
        for (
            uint256 betIndex = 0;
            betIndex < bets.length;
            betIndex++
        ) {
            if (!bets[betIndex].isFilled) {
                unfilledBetFound = true;
                firstUnfilledBet =  bets[betIndex];
                break;
            }
        }
        require(unfilledBetFound, "No unfilled bets found");
        return firstUnfilledBet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Allow the house to withdaw funds as needed
    function withdraw() public payable onlyOwner {
        require(msg.value < totalHouseMoney);
        msg.sender.transfer(msg.value);
        totalHouseMoney -= msg.value;
    }
}