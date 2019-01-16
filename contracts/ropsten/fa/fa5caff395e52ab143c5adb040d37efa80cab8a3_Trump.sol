pragma solidity ^0.4.25;

contract Trump {
    struct Player {
        uint256 amountBet;   //下注的金额
        uint256 timeSelected; //竞猜的时间
        uint256 timeSend; //下注的时间
    }

    struct Project {
        uint256 minBet;//设置最小下注金额0.1ETH
        uint256 totalBet; //总下注金额
        uint256 numberOfBets; //已下注人数
        bool isEnd; //此次活动是否结束
        uint256 startTime; //开始时间
        mapping(address => Player) playerInfo;

        address[] players; //玩家数组
        uint256[] players_amount; //玩家下注数组
        uint256[] players_time_select; //玩家竞猜时间数组
        uint256[] players_time_send; //玩家发送时间数组
        address[] firstWinner;
        address[] secondWinner;
        address[] thirdWinner;
        address[] invalidWinner;
    }

    uint256 public turn = 0;
    mapping(uint256 => Project) public project;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function createProject(uint _minBet, uint _startTime) onlyOwner public {
        require(_minBet > 0, "something bad happend");
        if (turn > 0) {
            require(project[turn].isEnd, "something bad happend");
        }
        turn++;
        project[turn].minBet = _minBet;
        project[turn].isEnd = false;
        project[turn].startTime = _startTime;
    }

    function bet(uint256 timeSelect, uint256 timeSend) public payable {
        require(project[turn].isEnd);
        require(msg.value >= project[turn].minBet);
        project[turn].playerInfo[msg.sender].amountBet = msg.value;
        project[turn].playerInfo[msg.sender].timeSelected = timeSelect;
        project[turn].playerInfo[msg.sender].timeSend = timeSend;
        project[turn].numberOfBets++;
        project[turn].players.push(msg.sender);
        project[turn].players_amount.push(msg.value);
        project[turn].players_time_select.push(timeSelect);
        project[turn].players_time_send.push(timeSend);
        project[turn].totalBet += msg.value;
    }

    function getSummary(uint _turn) public view returns (uint, uint, bool, address[], uint256[], uint256[], uint256[], uint, uint, uint){
        uint t = turn;
        if (_turn > 0) {
            t = _turn;
        }
        return (
        project[t].totalBet,
        project[t].numberOfBets,
        project[t].isEnd,
        project[t].players,
        project[t].players_amount,
        project[t].players_time_select,
        project[t].players_time_send,
        project[t].minBet,
        project[t].startTime,
        t
        );
    }

    function getWinner(uint _turn) public view returns (address[], address[], address[]){
        uint t = turn;
        if(_turn > 0){
            t = _turn;
        }
        return (project[t].firstWinner,
        project[t].secondWinner,
        project[t].thirdWinner);
    }

    function endProject() public onlyOwner {
        require(msg.sender == owner, "something bad");
        project[turn].isEnd = true;
    }

    function transferBet(address _address, uint256 _bet) public onlyOwner payable {
        require(_bet > 0, "Something bad");
        _address.transfer(_bet);
    }

    function setFirstWinner(address[] _firstWinner) public onlyOwner {
        project[turn].firstWinner = _firstWinner;
    }

    function setSecondWinner(address[] _secondWinner) public onlyOwner {
        project[turn].secondWinner = _secondWinner;
    }

    function setThirdWinner(address[] _thirdWinner) public onlyOwner {
        project[turn].thirdWinner = _thirdWinner;
    }

}