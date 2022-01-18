/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

contract Wageth {

    /** Game Config **/

    uint constant firstGameTime = 1498323600; // 06/24/2017 @ 5:00pm (UTC)
    uint constant interval = 1 hours;

    /** Game State **/

    uint public gameId = 0;
    address public currentKing;
    uint public highestBet;
    uint public currentPot;
    uint public endOfGame;

    /** Game Events **/

    event Start(uint indexed gameId, uint initialPot, uint endsAt, uint hostFeeDivisor, uint rolloverDivisor);
    event Wager(uint indexed gameId, address bettor);
    event End(uint indexed gameId, address winner, uint pot, uint kingPrize);

    /** Constructor **/

    function hostestWithMostest() private {
        wagethHost = msg.sender;
        newGame(0, (block.timestamp > firstGameTime ? block.timestamp : firstGameTime) + interval);
    }

    /** Payments **/

    function addPaidEtherToPool() private {
        currentPot += msg.value;
    }

    function recordPaidBet() private {
        if (msg.value > highestBet) {
            currentKing = msg.sender;
            highestBet = msg.value;
            endOfGame = block.timestamp + interval;
        }

        emit Wager(gameId, msg.sender);
    }

    function playerBet() payable public {
        require(gameIsActive());
        
        addPaidEtherToPool();
        recordPaidBet();
    }

    function injectIntoPot() isHost payable public {
        // allows the host to add additional funds into the pot to boost the prize without placing a bid themselves

        addPaidEtherToPool();
    }
    
    /** Game Processing **/

    function gameIsActive() public view returns(bool) {
        if (block.timestamp >= firstGameTime) {
            return shouldEndGame() ? false : true;
        } else {
            return false;
        }
    }

    function shouldEndGame() public view returns(bool) {
        return block.timestamp > endOfGame;
    }

    // endGame
    // Ends the game and forces the contract to pay out to the king
    // This method is public so anyone can call to end the game and force the pot to be paid out

    function endGame() public {
        require (shouldEndGame());

        // End current game
        // withdrawals should be made after prizes are awarded by calling the withdrawal method - this prevents recursive attacks + call stack depth attacks

        uint hostFee = currentPot/hostFeeDivisor;
        uint rollover = currentPot/rolloverDivisor;
        uint kingPrize = currentPot - (hostFee + rollover);

        if (currentKing == address(0)) { // if there is no king, rollover the king's prize
            rollover += kingPrize;
        } else { // if there is a king, send their prize
            pendingWithdrawals[currentKing] += kingPrize;
        }

        pendingWithdrawals[wagethHost] += hostFee;

        emit End(gameId, currentKing, currentPot, kingPrize);

        // Start new game

        newGame(rollover);
    }

    function newGame(uint initialPot) private {
        newGame(initialPot, 0);
    }
    function newGame(uint initialPot, uint initialEndTime) private {
        gameId++;

        currentPot = initialPot;
        highestBet = 0;
        currentKing = address(0);
        endOfGame = initialEndTime == 0 ? block.timestamp + interval : initialEndTime;

        updateFees();

        emit Start(gameId, initialPot, endOfGame, hostFeeDivisor, rolloverDivisor);
    }

    /**

    Withdrawals
    To guarantee that users will receive their winnings we implement a withdrawal pattern for payouts
    In endGame prizes are added to pendingWithdrawals until a succesful withdrawal is made

    WagETH's server automatically calls endGame and the withdraw method to award the king their share of the pot without players having to manually ask for their winnings using a contract call

    **/

    mapping(address => uint) pendingWithdrawals;

    function pendingWithdrawalForAddress(address userAddress) public view returns(uint) {
        return pendingWithdrawals[userAddress];
    }

    function withdraw(address payable userAddress) public {
        forceWithdraw(userAddress);
    }
    
    function forceWithdraw(address payable userAddress) isHost public {
        uint amount = pendingWithdrawals[userAddress];
        if (amount == 0) return;

        pendingWithdrawals[userAddress] = 0; // zero the pending withdrawal before sending to prevent re-entrancy attacks
        if (!userAddress.send(amount)) pendingWithdrawals[userAddress] = amount;
    }

    /** 

    Getters 
    All core game data variables are exposed as public, we expose additional methods for fetching game data here

    **/

    function getAll() public view returns(address, uint, uint, uint, uint, uint, uint) {
        return (
            currentKing, 
            currentPot, 
            highestBet, 
            endOfGame, 
            gameId, 
            hostFeeDivisor, 
            rolloverDivisor
        );
    }

    /**

    Fees
    The fees which WagETH charges are variable so that the game can be responsive to market demands
    Fees cannot be changed while a game is in progress - they only apply to the next game
    This keeps the host honest - they cannot arbitrarily take from participants of a high stakes game by changing the fee midgame

    **/

    uint public hostFeeDivisor; 
    uint public rolloverDivisor;

    uint public nextGameHostFeeDivisor = 10; // wageth takes 10% by default
    uint public nextGameRolloverDivisor = 20; // 5% is rolled over by default
    // => king (by default) takes 85% of the pot

    function setHostFeeDivisor(uint newHostFeeDivisor) isHost public {
        nextGameHostFeeDivisor = newHostFeeDivisor;
    }

    function setRolloverDivisor(uint newRolloverDivisor) isHost public {
        nextGameRolloverDivisor = newRolloverDivisor;
    }

    function updateFees() private {
        hostFeeDivisor = nextGameHostFeeDivisor;
        rolloverDivisor = nextGameRolloverDivisor;
    }

    /**

    Host
    The host is the main controller of wageth games who manages fees and markets the game to help build up the pot!

    **/

    address wagethHost;

    modifier isHost() {
        if (msg.sender != wagethHost) revert();
        _;
    }

}