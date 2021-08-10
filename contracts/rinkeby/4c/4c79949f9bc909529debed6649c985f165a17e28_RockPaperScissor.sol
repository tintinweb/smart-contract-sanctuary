pragma solidity ^0.4.24;

import "./oraclizeAPI_0.4.sol";

contract RockPaperScissor is usingOraclize {

    address private _contractOwner;
    
    struct GameResult {
        address player;
        uint8 result;  // 0:Tie, 1:Player Win, 2:Player Lose
        uint8 betOption;  // 1:scissor, 2:rock, 3:paper
        uint8 bankerOption;  // 1:scissor, 2:rock, 3:paper
    }
    
    GameResult[] public _gameResults;

    mapping(bytes32 => address) private queryIdToPlayer;
    mapping(bytes32 => uint) private queryIdToBetOption;

    event gameResult(string result,address player,uint playerOption,uint bankerOption);  // 1:scissor, 2:rock, 3:paper
    uint _bankerOption;  // 1:scissor, 2:rock, 3:paper

    constructor() payable public {
        _contractOwner = msg.sender;
        oraclize_setProof(proofType_Ledger);
        //getRandomNumber();
    }

    function __callback(bytes32 _queryId, string _result, bytes _proof) public {
        require(msg.sender == oraclize_cbAddress(),"callback address error!");
        require(oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0,"randomDS verify fail!");
        require(queryIdToPlayer[_queryId] != address(0));
        require(queryIdToBetOption[_queryId] >= 1 && queryIdToBetOption[_queryId] <= 3);

        uint8 result = 0;  // 0:Tie, 1:Player Win, 2:Player Lose
        uint randomNumber = (uint(keccak256(abi.encodePacked(_result))) % 3) + 1;
        _bankerOption = randomNumber;
        
        if(_bankerOption == 1 && queryIdToBetOption[_queryId] == 3) {  // banker win
            result = 2;
        }
        else if(_bankerOption == 2 && queryIdToBetOption[_queryId] == 1) {  // banker win
            result = 2;
        }
        else if(_bankerOption == 3 && queryIdToBetOption[_queryId] == 2) {  // banker win
            result = 2;
        }
        else if(_bankerOption == 1 && queryIdToBetOption[_queryId] == 2) {  // player win
            result = 1;
            //  Transfer 0.2 ether to player
            queryIdToPlayer[_queryId].transfer(0.2 ether);
        }
        else if(_bankerOption == 2 && queryIdToBetOption[_queryId] == 3) {  // player win
            result = 1;
            //  Transfer 0.2 ether to player
            queryIdToPlayer[_queryId].transfer(0.2 ether);
        }
        else if(_bankerOption == 3 && queryIdToBetOption[_queryId] == 1) {  // player win
            result = 1;
            //  Transfer 0.2 ether to player
            queryIdToPlayer[_queryId].transfer(0.2 ether);
        }
        else if(_bankerOption == queryIdToBetOption[_queryId]) {  // Tie
            result = 0;
            //  Transfer 0.1 ether to player
            queryIdToPlayer[_queryId].transfer(0.1 ether);
        }
        else{
            revert();
        }

        _gameResults.push(GameResult(queryIdToPlayer[_queryId],result,uint8(queryIdToBetOption[_queryId]),uint8(_bankerOption)));

          // 0:Tie, 1:Player Win, 2:Player Lose
        if(result == 0) emit gameResult("Tie",queryIdToPlayer[_queryId],queryIdToBetOption[_queryId],_bankerOption);
        else if(result == 1) emit gameResult("Player Win",queryIdToPlayer[_queryId],queryIdToBetOption[_queryId],_bankerOption);
        else if(result == 2) emit gameResult("Player Lose",queryIdToPlayer[_queryId],queryIdToBetOption[_queryId],_bankerOption);
        
        if(address(this).balance <= 0.2 ether){
            selfdestruct(_contractOwner);
        }
    }
    
    function getRandomNumber() private returns(bytes32 queryId) {
        queryId = oraclize_newRandomDSQuery(0, 5, 400000);
        return queryId;
    }
    
    function bet(uint betOption) payable public {
        require(msg.value == 0.1 ether,"You can only bet 0.1 ether!");
        require(betOption >= 1 && betOption <= 3,"Bet option should be between 1~3!");

        bytes32 queryId = getRandomNumber();
        queryIdToBetOption[queryId] = betOption;
        queryIdToPlayer[queryId] = msg.sender;
    }
    
    function bankerRunAway() payable public {
        require(msg.sender == _contractOwner,"Only contract owner can do it!");
        selfdestruct(_contractOwner);
    }

    function getLastGame(address player_) view public returns(uint id, uint8, uint8, uint8) {
        bool findRecord = false;
        GameResult memory gameResult_;
        id = 0;

        for(uint i=0; i<_gameResults.length; i++) {
            if(_gameResults[_gameResults.length-i-1].player != player_)
                continue;

            findRecord = true;
            id = _gameResults.length-i;
            gameResult_.result = _gameResults[_gameResults.length-i-1].result;
            gameResult_.betOption = _gameResults[_gameResults.length-i-1].betOption;
            gameResult_.bankerOption = _gameResults[_gameResults.length-i-1].bankerOption;
        }

        if(findRecord == true)
            return (id,gameResult_.result,gameResult_.betOption,gameResult_.bankerOption);
        else
            return (0,0,0,0);
    }

    function playerGameStatistic(address player_) view public returns(uint tie, uint win, uint lose) {
        uint[3] memory count; // count[0]:Tie, count[1]:Win, count[2]:Lose
        for(uint i=0; i<_gameResults.length; i++) {
            if(_gameResults[i].player != player_)
                continue;
            
            count[_gameResults[i].result]++;
        }

        return (count[0],count[1],count[2]);
    }
}