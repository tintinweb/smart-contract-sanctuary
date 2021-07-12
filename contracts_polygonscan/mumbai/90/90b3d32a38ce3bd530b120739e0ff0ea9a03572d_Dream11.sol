/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.4.24;

interface IERC20{
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external;
}

contract Dream11{
    
    struct team{
        uint[11] players;
    }
    mapping(address => uint[11]) public teams;
    address[] public participants;
    mapping(address => bool) public isParticipating;
    mapping(uint => uint) points;
    uint totalFunds;
    team[] participatingTeams;
    uint fundAmount;
    address USDT = 0xd8e23e4C2E69305C4177488B79248F328dEb64a8;
    address companyAddress = 0x0fc1Fb5Eb6f1F1D17507F08eDB5807B66C705F5e;
    uint public winningPoints;
    address public winner;
    bool public resultDeclared;
    
    event CreateTeam(address indexed player, uint[11] team);
    event EnterContest(address indexed player, uint amount);
    event ResultDeclared(uint[] players, uint[] points);
    event Claim(address indexed player, uint amount);
    
    function addTeam(uint[11] _team) public{
        teams[msg.sender] = _team;
        CreateTeam(msg.sender, _team);
    }
    
    function addFunds() public{
        IERC20(USDT).transferFrom(msg.sender, address(this), 50e6);
        participants.push(msg.sender);
        isParticipating[msg.sender] = true;
        EnterContest(msg.sender, 50e6);
    }
    
    function matchPoints(uint[] _players, uint[] _points) public{
        for(uint i=0;i< _players.length; i++){
          points[_players[i]] = _points[i];   
        }
        IERC20(USDT).transfer(companyAddress, 5e6);
        findWinner();
        resultDeclared = true;
        ResultDeclared(_players,_points);
    }
    
    function findWinner() internal {
        uint total;
        uint winningPoints = 0;
        for(uint i=0; i< participants.length; i++){
            total = 0;
            for(uint j=0; j<teams[participants[i]].length; j++){
                total += points[teams[participants[i]][j]];
            }
            if(total > winningPoints){
                winningPoints = total;
                winner = participants[i];
            }
        }
    }
    
    function claimRewards() public {
        require(msg.sender == winner);
        IERC20(USDT).transfer(msg.sender, 95e6); 
        Claim(msg.sender, 95e6);
    }
    
    function getTeam(address player) public view returns(uint[11]){
        return teams[player];
    }
    
    function calculatePoints(address player) public view returns(uint){
      uint[11] memory team = teams[player];
      uint totalPoints;
      for(uint i=0;i<11;i++){
          totalPoints += points[team[i]];
      }
      return totalPoints;
    }
    
    function getTotalParticipants() public view returns (uint){
        return participants.length;
    }
    
}