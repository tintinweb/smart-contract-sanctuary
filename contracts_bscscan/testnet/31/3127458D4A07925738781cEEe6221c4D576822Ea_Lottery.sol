/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Lottery {

    address public owner;
    IERC20 lotteryToken;
    uint256 public entryAmount;
    uint public currentRoundId;
    address[] public participants;
    Round[] public roundsList;

    enum State {RUNNING,CLOSING,ENDED}
    State state;

    struct Round {
        uint id;
        uint256 pooledAmount;
    }

    mapping(address => bool) userEnteredActualLottery;
    mapping(uint => Round[]) rounds;


    constructor(address _lotteryToken, uint256 _entryAmount) {
        owner = msg.sender;
        lotteryToken = IERC20(_lotteryToken);
        entryAmount = _entryAmount;
        currentRoundId = 0;
        state = State.RUNNING;
        Round memory newRound = Round(currentRoundId,0);
        roundsList.push(newRound);
    }


    function getCurrentRound() public view returns (Round memory) {
        return roundsList[currentRoundId];
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function createLottery() onlyOwner public {
        require(state == State.ENDED, 'You cant run new lottery while there is one running');
        currentRoundId++;
        Round memory newRound = Round(currentRoundId,0);
        roundsList.push(newRound);
        state = State.RUNNING;
    }

    function closeEntry() private {
        state = State.CLOSING;
    }

    function enterLottery() external {
        require(!userEnteredActualLottery[msg.sender], 'Already entered');
        require(state == State.RUNNING, 'Lottery not running');
        lotteryToken.transferFrom(msg.sender, address(this), entryAmount);
        userEnteredActualLottery[msg.sender] = true;
        roundsList[currentRoundId].pooledAmount += entryAmount;
        participants.push(msg.sender);
        if(participants.length > 1) {
            closeEntry();
        }
    }

    function isParticipant(address _user) public view returns(bool) {
        return userEnteredActualLottery[_user];
    }

    function getParticipants() public view returns(address[] memory) {
        return participants;
    }

    function sendFundsToWinner() onlyOwner external payable {
        require(state == State.CLOSING, 'Can only send funds to winner while closing lottery');
        uint winner = _randomModulo(participants.length);
        lotteryToken.transfer(participants[winner],lotteryToken.balanceOf(address(this)));
        delete participants;
        state = State.ENDED;
    }

    function transferOwnership(address _newOwner) onlyOwner public{
        owner = _newOwner;
    }

    function changeEntryAmount(uint256 _entryAmount) onlyOwner public {
        entryAmount = _entryAmount;
    }

     function _randomModulo(uint modulo) view internal returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % modulo;
    }


}