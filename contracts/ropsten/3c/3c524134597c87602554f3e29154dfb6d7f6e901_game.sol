pragma solidity ^0.4.20;

contract game {
    
    address public owner;
    uint8 private decimals = 18;//小数
    uint256 public mininumBet = 1*10**(uint256(decimals)-3);//
    uint256 public totalBet;
    uint256 public numberOfBets;
    uint256 constant public maxAmountOfBets=4;
    uint256 public numberGenerated;
    uint256 public winnerEtherAmount;
    address[] public players;
    
    struct Player{
        uint256 amontBets;
        uint256 numberSelected;
    }
    
    mapping(address=>Player) public playerInfo;
    
    
    function bet(uint256 numberSelected)public payable{
        require(!checkPlayerExists(msg.sender));
        require(numberSelected >= 1 && numberSelected <=10);
        require(msg.value >= mininumBet);
        require(numberOfBets<=maxAmountOfBets);
        
        playerInfo[msg.sender].amontBets = msg.value;
        playerInfo[msg.sender].numberSelected = numberSelected;
        numberOfBets++;
        players.push(msg.sender);
        totalBet += msg.value;
        
        if(numberOfBets>=maxAmountOfBets) generateNumberWinner();
    }
    
    
    function checkPlayerExists(address player) public constant returns(bool){
        for(uint8 i = 0 ; i < players.length ; i++ ){
            if( players[i]==player ) return true;
        }
        return false;
    }
    
    function generateNumberWinner() private{
        numberGenerated = (block.number % 10 +1);// bu an quan 
        distributePrizze(numberGenerated);
    }
    
    function distributePrizze(uint256 numberWinner) private{
        address[maxAmountOfBets] memory winners;
        bool hasWiner=false;
        uint256 count = 0;
        for(uint16 i = 0 ; i<players.length;++i){
            address playerAddress = players[i];
            if(playerInfo[i].numberSelected==numberWinner){
                winners[count]=playerAddress;
                count++;
            }
            delete playerInfo[playerAddress];
        }
        
        if(count==0){
            count = maxAmountOfBets;
            hasWiner = false;
        }else{
            hasWiner= true;
        }
        
        winnerEtherAmount = totalBet*95/100/count;
        
        for(uint16 j = 0; j < count ; j ++){
            if(hasWiner){
                if(winners[j]!=address(0)) winners[j].transfer(winnerEtherAmount);
            }else{
                if(players[j]!=address(0)) players[j].transfer(winnerEtherAmount);
            }
        }
        players.length = 0;
        totalBet=0;
        numberOfBets=0;
        
    }
}