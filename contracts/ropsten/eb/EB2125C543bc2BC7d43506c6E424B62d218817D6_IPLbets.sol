/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity ^0.4.11;

contract Ownable {
    
    address owner;
    address public ceoAddress;
  
    function Ownable() {
        owner = msg.sender;
        ceoAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"You are not Owner");
        _;
    }
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress,"You are not CEO");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
        owner = newOwner;
        }
    }
    
    function setCEO(address _newCEO) public onlyOwner {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

}

contract IPLbets is Ownable{
    
    uint256 minimumBet = 10 finney;
    uint256 totalteam1Bet;
    uint256 totalteam2Bet;
    
    struct Match {
        
        uint8 matchid;
        string team1;
        string team2;
        uint betEndTime;
    }
    
    struct Player {
        
        uint256 amountBet;
        uint8 teamSelected;
        bool betted;
    }
    
    address[] totalPlayers;

    Match matchDetails;
    
    mapping(address => Player) playerInfo;
    
    function setMatchDetails (uint8 _matchid, string memory _team1, string memory _team2, uint _betEndTime) public onlyCEO {
        matchDetails = Match(_matchid, _team1, _team2,_betEndTime);
    }
    
    function viewMatchDetails() public view returns(uint8,string,string,uint){
       return (matchDetails.matchid,matchDetails.team1,matchDetails.team2,matchDetails.betEndTime);
    }
    
    function viewTotalPlayers() public view returns(uint){
        return totalPlayers.length;
    }
    
    function viewTotalBets() public view returns(uint){
        return totalteam1Bet + totalteam2Bet;
    }
    
    function viewPlayerAmount(address _address) public view returns(uint256){
        return (playerInfo[_address].amountBet);
    }
    
    function viewPlayerTeam(address _address) public view returns(uint8){
        return (playerInfo[_address].teamSelected);
    }

    
    function bet(uint8 _teamSelected) public payable {
        
        require(_teamSelected == 1 || _teamSelected == 2, "Selection should be either 1 or 2");
        require(now <= matchDetails.betEndTime,"Betting Time has ended");
        require(msg.value >= minimumBet,"Minimum bet should be 0.01 Ether");

        if (_teamSelected == 1){
            
            if(playerInfo[msg.sender].betted){
                require(playerInfo[msg.sender].teamSelected == 1,"No Team Change Allowed");
                totalteam1Bet += msg.value;
            }
            
            else{
                totalteam1Bet += msg.value;
                totalPlayers.push(msg.sender);
            }
        }
        
        else{
            if(playerInfo[msg.sender].betted){
                require(playerInfo[msg.sender].teamSelected == 2,"No Team Change Allowed");
                totalteam2Bet += msg.value;
            }
            
            else{
                totalteam2Bet += msg.value;
                totalPlayers.push(msg.sender);
            }
            
        }
        
        playerInfo[msg.sender].amountBet += msg.value;
        playerInfo[msg.sender].teamSelected = _teamSelected;
        playerInfo[msg.sender].betted = true;
    }
    
    function distributeRewards(uint8 _winner) public onlyCEO {
        
        require(_winner == 1 || _winner ==2, "Winner should be either 1 or 2");
        
        uint totalWinBet;
        uint totalLostBet;
        
        if(_winner == 1){
            totalWinBet = totalteam1Bet;
            totalLostBet = totalteam2Bet;
            
        }else{
            totalWinBet = totalteam2Bet;
            totalLostBet = totalteam1Bet;
        }
        
        for(uint256 i = 0; i < totalPlayers.length; i++){
            if(playerInfo[totalPlayers[i]].teamSelected == _winner){
                uint amount = ((playerInfo[totalPlayers[i]].amountBet*(9000+(totalLostBet*9000/totalWinBet)))/10000);
                totalPlayers[i].transfer(amount);
            }
            
            delete playerInfo[totalPlayers[i]];
            
        }
        
        owner.transfer(address(this).balance);
        delete totalteam1Bet;
        delete totalteam2Bet;
        delete matchDetails;
        delete totalPlayers;

    }
    
    

}