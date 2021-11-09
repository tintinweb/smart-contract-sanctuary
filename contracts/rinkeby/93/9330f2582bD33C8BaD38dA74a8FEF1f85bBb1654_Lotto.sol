//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Lotto{
    address public manager;
    uint public prizePool;
    address[] public participants;
    mapping (uint => address) public choiceToParticipants;
    uint public participantsCount=0;
    uint randNonce = 0;
    uint public range;
    bool public isStarted= false;
    uint public managementFee;


    modifier onlyManager(){
        require(msg.sender==manager,"fuck off bitch");
        _;
    }

    modifier gameStarted(){
        require(isStarted,"The game was not started yet");
        _;
    }

    constructor() {
        manager=msg.sender;
    }

    function startTheGame(uint _initialPrize,uint _range,uint _fee) external payable onlyManager(){
        require(msg.value==_initialPrize,"please send ether as the initial prize");
        require(_initialPrize>10**15,"the minmum initial prize is 0,001 ether");
        require(_fee>0&&_fee<100);
        prizePool=_initialPrize;
        range=_range;
        managementFee=_fee;
        isStarted=true;
    }

    function participate(uint _choice) payable external gameStarted{
        require(msg.sender!= manager,"manager can not participate");
        prizePool+=msg.value;
        choiceToParticipants[_choice]=msg.sender;
        participantsCount++;
    }

    function chooseARandomNumber(uint _limit) internal gameStarted returns(uint){
        require(_limit>=2,"choose a bigger number");
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)))%_limit;
        randNonce++;     
        return rand;
    }

    function pickWinner()internal onlyManager gameStarted returns (address payable){
        uint winningNumber = chooseARandomNumber(range);
        return payable(choiceToParticipants[winningNumber]);
    }

    function endTheGame() external onlyManager gameStarted {
        address payable winner = pickWinner();
        (bool sent, ) = winner.call{value: prizePool*(100-managementFee)/100}("");
        require(sent, "Failed to send the prize.");
        isStarted=false;
        
    }


}