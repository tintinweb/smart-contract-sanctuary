/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Starbet {
    using SafeMath for uint256;
    
    // Contract owner
    address payable public owner;
    
    // Added bets to the match
    Bet[] public bets;
    address payable[] public fullWinners;
    address payable[] public partialWinners;
    
    // Record number of bets per address
    mapping (address => uint) recordedBets;

    // Save prizes for individuals
    uint public fullPrizeIndividual = 0;
    uint public partialPrizeIndividual = 0;
    
    // Some setup
    uint constant FULL_PERCENT = 40;
    uint constant PARTIAL_PERCENT = 40;
    uint constant MAX_BETS_FOR_ADDRESS = 5;
    uint constant BET_PRIZE = 0.00075 ether; // 750000 gwei
    
    // Added jackpot (if exists)
    uint public jackpotValue = 0;
    
    struct Bet {
        address payable player;
        string home;
        string away;
    }
    
    event AddBet(address sender, string home, string away);
    event Prizing(uint winners, uint division, string kind);
    event Check(Bet thisBet, string home, string away, string kind);
    event Process(uint fullWinners, uint partialWinners, uint balance);

    constructor() {
        owner = payable(msg.sender);
    }
    
    // Owner can add a jackpot into the contract
    function jackpot() public payable {
        require(msg.sender == owner);
        jackpotValue = msg.value;
    }
    
    // Enter a new bet
    function join(string memory home, string memory away) public payable {
        require(msg.value == BET_PRIZE, 'Price not met');
        require(recordedBets[msg.sender] < MAX_BETS_FOR_ADDRESS, 'Too many bets from this address');
        
        bets.push(Bet({
            player: payable(msg.sender),
            home: home,
            away: away
        }));
        
        recordedBets[msg.sender] += 1;
        
        emit AddBet(msg.sender, home, away);
    }
    
    // Get actual balance
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getFullPrize() public view returns(uint) {
        uint finalBalance = getBalance();
        return SafeMath.div((FULL_PERCENT * finalBalance), 100);
    }
    function getPartialPrize() public view returns(uint) {
        uint finalBalance = getBalance();
        return SafeMath.div((FULL_PERCENT * finalBalance), 100);
    }
    
    // Owner can pick the contract winners. This method will distribute prizes
    function winner(string memory home, string memory away) public {
        require(msg.sender == owner);
        
        for (uint i = 0; i < bets.length; i++) {
            Bet memory thisBet = bets[i];
            
            if (compareStrings(thisBet.home,home) && compareStrings(thisBet.away,away)) {
                emit Check(thisBet, home, away, "full");
                fullWinners.push(thisBet.player);
            } else if (compareStrings(thisBet.home,home) || compareStrings(thisBet.away,away)) {
                emit Check(thisBet, home, away, "partial");
                partialWinners.push(thisBet.player);
            } else {
                emit Check(thisBet, home, away, "none");
            }
        }
        
        emit Process(fullWinners.length, partialWinners.length, getBalance());
        
        // Setup prizing
        uint fullPrize = getFullPrize();
        uint partialPrize = getPartialPrize();
        
        // FullWinners distribution
        if (fullWinners.length > 0) {
            fullPrizeIndividual = SafeMath.div(fullPrize, fullWinners.length);
            emit Prizing(fullPrize, fullPrizeIndividual, 'full');
                   
            for (uint i = 0; i < fullWinners.length; i++) {
                address payable thisAddress = fullWinners[i];
                thisAddress.transfer(fullPrizeIndividual);
            }
        }
        
        // PartialWinners distribution
        if (partialWinners.length > 0) {
            partialPrizeIndividual = SafeMath.div(partialPrize, partialWinners.length);
            emit Prizing(partialPrize, partialPrizeIndividual, 'partial');
        
            for (uint i = 0; i < partialWinners.length; i++) {
                address payable thisAddress = partialWinners[i];
                thisAddress.transfer(partialPrizeIndividual);
            }
        }
        
        // Remaining distribution
        owner.transfer(getBalance());
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}