// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./RNDProvider.sol";


contract Roulette is RNDProvider {

    address payable public casino;

    uint256 public maxBet = 1 ether;
    uint256 internal maxBetRatio = 1000;

    struct Bet {
        address payable addr;
        uint amount;
        uint betId;
        uint betNumber;
    }

    uint internal constant NUMBER = 0;
    uint internal constant ODD = 1;
    uint internal constant EVEN = 2;
    uint internal constant RED = 3;
    uint internal constant BLACK = 4;

    uint[] internal red_numbers = [32, 19, 21, 25, 34, 27, 36, 30, 23, 5, 16, 1, 14, 9, 18, 7, 12, 3];
    uint[] internal black_numbers = [15, 4, 2, 17, 6, 13, 11, 8, 10, 24, 33, 20, 31, 22, 29, 28, 35, 26];

    mapping(bytes32 => Bet[]) public allBets;

    mapping(bytes32 => address) public spinRequests;


    uint256 internal randomResult;
    uint256 public spinResult;


    bytes32 public testValue;

    constructor()
    {
        casino = payable(msg.sender);
        maxBet = address(this).balance / maxBetRatio;
    }

    modifier checkMaxBet{
        require(msg.value <= maxBet, "This bet exceed max possible bet");
        _;
    }
    modifier checkEmptyBet{
        require(msg.value > 0, "You can't bet zero money");
        _;
    }


    function spinWheel() payable public {
        // Get address of sender
        address payable bettor;
        bettor = payable(msg.sender);

        // Generate the keyHash
        bytes32 requestId = bytes32(abi.encodePacked(msg.sender));

        require(allBets[requestId].length > 0, "Place atleast one bet");
        require(spinRequests[requestId] == address(0), "Spin was already sent");

        spinRequests[requestId] = msg.sender;

        testValue = requestId;

        getRandomNumber(requestId);
    }

    /** 
     * Requests randomness from an Oracle
     */
    function getRandomNumber(bytes32 requestId) internal {
        requestRandomness(requestId);
    }

    /**
     * Callback function used by Oracle to return random value
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override{
        randomResult = randomness;

        //calculate spin result
        uint _spinResult = randomResult % 36;

        //display spin result to public (only works if low volume)
        spinResult = _spinResult;

        delete spinRequests[requestId];

        // find all bets from this player

        for (uint i = 0; i < allBets[requestId].length; i++) {
            Bet memory b = allBets[requestId][i];

            if (b.addr == payable(msg.sender)) {
                (bool is_win, uint multi) = isWin(b.betId, b.betNumber, _spinResult);
                if (is_win) {
                    (bool sent, ) = b.addr.call{value: b.amount * multi}("");
                    require (sent, "failed to send ether to winner :(");
                }
            }
        }

        // delete used bets
        delete allBets[requestId];


        maxBet = address(this).balance / maxBetRatio;

    }

    function isWin(uint betId, uint betNum, uint resultNum) internal view returns (bool, uint) {
        // NUMBER BET CHECK
        if (betId == NUMBER) {
            if (betNum == resultNum) {
                return (true, 36);
            }
        }
        if (betId == ODD && resultNum != 0) {
            if (resultNum % 2 == 1) {
                return (true, 2);
            }
        }
        if (betId == EVEN) {
            if (resultNum % 2 == 0) {
                return (true, 2);
            }
        }
        if (betId == RED) {
            for (uint i = 0; i < red_numbers.length; i++) {
                if (red_numbers[i] == resultNum) {
                    return (true, 2);
                }
            }
        }
        if (betId == BLACK) {
            for (uint i = 0; i < black_numbers.length; i++) {
                if (black_numbers[i] == resultNum) {
                    return (true, 2);
                }
            }
        }
        return (false, 0);
    }

    function getRequestId() internal view returns (bytes32) {
        return bytes32(abi.encodePacked(msg.sender));
    }


    function addBalance() external payable {
        maxBet = address(this).balance / maxBetRatio;
    }

    function withdrawWei(uint wei_amount) public {
        casino.transfer(wei_amount);
        maxBet = address(this).balance / maxBetRatio;
    }


    function betNumber(uint bet_num) payable public checkMaxBet checkEmptyBet {
        address payable bettor;
        bettor = payable(msg.sender);

        Bet memory cur_bet = Bet(bettor, msg.value, NUMBER, bet_num);
        allBets[getRequestId()].push(cur_bet);
    }

    function betOdd() payable public checkMaxBet checkEmptyBet {
        address payable bettor;
        bettor = payable(msg.sender);

        Bet memory cur_bet = Bet(bettor, msg.value, ODD, 0);
        allBets[getRequestId()].push(cur_bet);
    }

    function betEven() payable public checkMaxBet checkEmptyBet {
        address payable bettor;
        bettor = payable(msg.sender);

        Bet memory cur_bet = Bet(bettor, msg.value, EVEN, 0);
        allBets[getRequestId()].push(cur_bet);
    }

    function betRed() payable public checkMaxBet checkEmptyBet {
        address payable bettor;
        bettor = payable(msg.sender);

        Bet memory cur_bet = Bet(bettor, msg.value, RED, 0);
        allBets[getRequestId()].push(cur_bet);
    }

    function betBlack() payable public checkMaxBet checkEmptyBet {
        address payable bettor;
        bettor = payable(msg.sender);

        Bet memory cur_bet = Bet(bettor, msg.value, BLACK, 0);
        allBets[getRequestId()].push(cur_bet);
    }

}