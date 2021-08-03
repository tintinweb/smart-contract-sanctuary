/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract RockPaperScissors {

    uint constant ROCK = 1;
    uint constant PAPER = 2;
    uint constant SCISSORS = 3;
    uint public fomoEndTime;
    uint public fomoBalance;

    uint[] public priceToPlay;
    
    address private owner;
    address public lastUpdateFomo;

    mapping(uint => bool) public checkPrice;
    mapping(uint => address[2]) public playersPerPrice;
    mapping(address => uint) public stakeAmountPerUser;
    mapping(uint => mapping(uint8 => uint8)) public choicePerPlayer;
    mapping(uint8 => mapping(uint8 => uint8)) private states;

    constructor() {
        owner = msg.sender;
        states[1][1] = 0;
        states[1][2] = 2;
        states[1][3] = 1;
        states[2][1] = 1;
        states[2][2] = 0;
        states[2][3] = 2;
        states[3][1] = 2;
        states[3][2] = 1;
        states[3][3] = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier isBetable() {
        require(checkPrice[msg.value], "Undefined eth amount");
        require(playersPerPrice[msg.value][0] == address(0) || playersPerPrice[msg.value][1] == address(0), "the room is full");
        _;
    }

    modifier isPlayer() {
        uint stakeAmount = stakeAmountPerUser[msg.sender];
        require(msg.sender == playersPerPrice[stakeAmount][0] || msg.sender == playersPerPrice[stakeAmount][1], "You did not bet");
        _;
    }

    modifier isValidChoice(uint8 _choice) {
        require(_choice == 1 || _choice == 2 || _choice == 3, "Undefined selector");
        _;
    }

    function setPrices(uint[] calldata prices) public onlyOwner {
        priceToPlay = prices;
        for (uint i = 0; i < prices.length; i++) {
            checkPrice[prices[i]] = true;
        }
    }

    function setOwner(address newOnwer) public onlyOwner {
        owner = newOnwer;
    }

    function bet() public payable isBetable {
        if (playersPerPrice[msg.value][0] == address(0)) {
            playersPerPrice[msg.value][0] = msg.sender;
        } else {
            playersPerPrice[msg.value][1] = msg.sender;
        }
        if (fomoEndTime == 0) {
            fomoEndTime = block.timestamp + 3600;
        } else if (fomoEndTime <= block.timestamp) {
            fomoBalance = 0;
            payable(lastUpdateFomo).transfer(fomoBalance);
            fomoEndTime = 0;
        } else {
            if (msg.value >= fomoBalance / 10) {
                fomoEndTime = block.timestamp + 3600;
            }
        }
        lastUpdateFomo = msg.sender;
        stakeAmountPerUser[msg.sender] = msg.value;
    }

    function play(uint8 choice) public isPlayer isValidChoice(choice) {
        uint stakeAmount = stakeAmountPerUser[msg.sender];
        if (msg.sender == playersPerPrice[stakeAmount][0]) {
            choicePerPlayer[stakeAmount][0] = choice;
        } else if (msg.sender == playersPerPrice[stakeAmount][1]) {
            choicePerPlayer[stakeAmount][1] = choice;
            uint8 result = states[choicePerPlayer[stakeAmount][0]][choicePerPlayer[stakeAmount][1]];
            if (result == 0) {
                payable(playersPerPrice[stakeAmount][0]).transfer(stakeAmount);
                payable(playersPerPrice[stakeAmount][1]).transfer(stakeAmount);
            } else if (result == 1) {
                payable(playersPerPrice[stakeAmount][0]).transfer(2*stakeAmount*95/100);
                fomoBalance += 2 * stakeAmount * 5 / 100;
            } else if (result ==2) {
                payable(playersPerPrice[stakeAmount][1]).transfer(2*stakeAmount*95/100);
                fomoBalance += 2 * stakeAmount * 5 / 100;
            }
            playersPerPrice[stakeAmount][0] = address(0);
            playersPerPrice[stakeAmount][1] = address(0);
            choicePerPlayer[stakeAmount][0] = 0;
            choicePerPlayer[stakeAmount][1] = 0;
        }
    }
}