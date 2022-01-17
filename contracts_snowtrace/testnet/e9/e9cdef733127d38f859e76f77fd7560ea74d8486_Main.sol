/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IScoreOracle {
    function getPlayerScore() external returns (uint256);
    function setPlayerScore(uint256 _score, uint256 _id) external ;

    function setMasterAddress() external returns (address);
}

contract Main {
    struct Player {
        uint id;
        address playerAddress;
        bool isPlaying;
        uint score;
        bool isReward;
    }

    address[] public whiteListedPlayers;

    mapping(address => Player) public players;
    uint scoreTarget = 500;
    //uint score;
    uint rewardPool;
    bool statusPauseReward = false;

    //public

    function addWhiteListedPlayer(address _address) private {
        whiteListedPlayers.push(_address);
    }

    function enter() public {
        if(players[msg.sender].playerAddress == msg.sender){
            players[msg.sender].isPlaying = true;
            players[msg.sender].score = 0;
            players[msg.sender].isReward = false;
        } else {
            Player memory player = Player({
                id: block.number,
                playerAddress: msg.sender,
                isPlaying: true,
                score: 0,
                isReward: false
            });
            players[msg.sender] = player;
            addWhiteListedPlayer(msg.sender);
        }
    }

    function getStatusPauseReward() public view returns(bool){
        return statusPauseReward;
    }

    function getRewardPool() public view returns(uint){
        return address(this).balance;
    }

    function getScoreTarget() public view returns(uint){
        return scoreTarget;
    }

    function getPlayerScore(address _address) public view returns(uint){
        return players[_address].score;
    }

    //admin

    function setScoreTarget(uint _scoreTarget) public onlyOwner {
        scoreTarget = _scoreTarget;
    }

    function collectRewardPool() public onlyOwner payable{
        rewardPool = address(this).balance;
        require(rewardPool>0);
        payable(owner).transfer(rewardPool);
    }

    function pauseRewardPool() public onlyOwner {
        statusPauseReward = true;
    }

    function unPauseRewardPool() public onlyOwner {
        statusPauseReward = false;
    }

    /*function setPlayerScore(address _address ,uint playerScore) public returns(uint){
        score = playerScore;
        players[_address].score = playerScore;
        return score;
    }*/

    function addReward() public payable {
        require(msg.value > 0.1 ether);
        rewardPool = address(this).balance;
    }

    function reward(address _address) public {
        require(rewardPool > 0.1 ether && players[_address].score>=scoreTarget, "Check the rewardPool or the playerScore is under the minimum score.");
        rewardPool = address(this).balance;
        if(statusPauseReward==false && players[_address].isPlaying){
            payable(_address).transfer(0.1 ether);
            players[_address].score=0;
        }
        //score=0;
        players[_address].score = 0;
        players[_address].isReward = true;
        players[_address].isPlaying = false;

    }




    address private oracleAddress;
    IScoreOracle private oracleInstance;
    function setOracleInstanceAddress (address _oracleInstanceAddress) public onlyOwner {
        oracleAddress = _oracleInstanceAddress;
        oracleInstance = IScoreOracle(oracleAddress);
        emit newOracleAddressEvent(oracleAddress);
    }

    event newOracleAddressEvent(address oracleAddress);
    event ReceivedNewRequestIdEvent(uint256 id);
    event ScoreUpdatedEvent(uint256 score, uint256 id);

    uint private playerScore = 0;
    address public owner = msg.sender;
    address private _oracleAddress;
    mapping(uint256=>bool) myRequests;

    

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not authorized to call this function.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "You are not authorized to call this function.");
        _;
    }

    function requestScore() public {
        uint256 id = oracleInstance.getPlayerScore();
        myRequests[id] = true;
        emit ReceivedNewRequestIdEvent(id);
    }

    function updateScore(uint _score, uint _id, address _address) public{
        oracleInstance.setPlayerScore(_score, _id);
        players[_address].score = _score;
    }

    function callback(uint256 _score, uint256 _id) public onlyOracle {
        require(myRequests[_id], "This request is not in my pending list.");
        playerScore = _score;
        delete myRequests[_id];
        emit ScoreUpdatedEvent(_score, _id);
    }

    //-------------------------------------------------------> First Version

    function setMasterAddress() public onlyOwner {
        oracleInstance.setMasterAddress();
    }

    function displayScore() public view returns (uint) {
        return playerScore;
    }

    /*function setOracle(address _address) public onlyOwner returns(address) {
        _oracleAddress = _address;
        return _oracleAddress;
    }
    
    function saveScore() public {
        playerScore = IScoreOracle(_oracleAddress).saveScore();
    }

    function sendEth(address _to) public payable {
        payable(_to).transfer(msg.value);
    }

    function returnBalance() public returns(uint) {
        uint balance = IScoreOracle(_oracleAddress).returnBalance();
        return balance;
    }

    function returnSender() public returns(address){
        address sender = IScoreOracle(_oracleAddress).returnSender();
        return sender;
    }

    event returnBalanceEvent(uint balance);
    event returnSenderEvent(address sender);*/
}