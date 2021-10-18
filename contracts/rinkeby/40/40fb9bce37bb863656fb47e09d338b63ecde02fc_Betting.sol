/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity 0.7.0;

contract Betting {
    
    address bettingAdministrator;
    address payable [] players;
    
     bool paused;
    
    struct Player {
        uint256 matchId;
        uint256 betAmount;
        string bettingType;
        uint256 oddForWinning;
        uint256 potentialWin;
    }
    
    mapping (address => Player) player;
    
    event PlaceBet(address indexed player, uint256 matchId, uint256 betAmount, string bettingType, uint256 oddForWinning);
    event BetWin(address indexed player, uint256 winAmount);
    
    constructor() {
        bettingAdministrator = msg.sender;
    }
    
    modifier onlyBettingAdministrator() {
       require(msg.sender == bettingAdministrator, "You are not Betting Administrator!");
        _;
    }
    
     function noMoreBets(bool _paused) public onlyBettingAdministrator{
        paused = _paused;
    }
  
    function placeBet (uint256 _matchId, string memory _bettingType, uint256 _oddForWinning) payable public {
         require(paused == false, "No more bets!");
        
        if ( msg.value == 0 ether){
            revert("Not enough Ether for bet!");
        }
        
        player[msg.sender].matchId = _matchId;
        player[msg.sender].betAmount = msg.value;
        player[msg.sender].bettingType = _bettingType;
        player[msg.sender].oddForWinning = _oddForWinning;
        player[msg.sender].potentialWin = (msg.value * _oddForWinning);
        
        players.push(msg.sender);
        
        emit PlaceBet(msg.sender, _matchId, msg.value, _bettingType, _oddForWinning);
    }
    
    
    function payWinningBets(uint256 _matchId, string memory _winningType) public onlyBettingAdministrator{
        address payable playerAddress;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 payaout;
        
        for(uint256 i=0; i< players.length; i++) {
            playerAddress = players[i];
            if(player[playerAddress].matchId == _matchId ){
            if(keccak256(abi.encodePacked(player[playerAddress].bettingType)) == keccak256(abi.encodePacked(_winningType))) {
                balanceBefore = address(this).balance; 
                balanceAfter = address(this).balance - player[playerAddress].potentialWin;
                payaout = balanceBefore - balanceAfter;
                 payaout = payaout-(payaout*5/100);
                playerAddress.transfer(payaout);
                
                emit BetWin(playerAddress, payaout);
                }
                delete player[playerAddress];
            }
        }
    }
    
    function depositEtherOnPlatform () public payable onlyBettingAdministrator {
        
    }
    
    function getPlatformBalance() public view returns(uint) {
        return address(this).balance;
    }
}