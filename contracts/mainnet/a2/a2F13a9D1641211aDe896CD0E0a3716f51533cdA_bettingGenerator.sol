pragma solidity ^0.4.23;



contract bettingGenerator{
    address[] public deployedSportEvent;
    address _teamAccount = 0x1b2a07BE84d8914526b51ce72bEDDB312656058e;
    function createSportEvent(string _nameEvent,uint8 _feePercentage,uint _endTime) public {
        require(msg.sender == _teamAccount);
        deployedSportEvent.push(new sportEvent(_nameEvent,_feePercentage,_teamAccount,_endTime));       
    }

    function getDeployedEvents() public view returns (address[]){
        return deployedSportEvent;
    }
    
}

contract sportEvent{
    bool eventEnded = false;
    uint256 endTime;
    address public manager ;
    uint8 public devPercentage;
    string public name;
    mapping(address => uint) public index;

    struct Player{
        
        uint[12] betsValue;
        address playerAddress;
        uint totalPlayerBet;
        
    }
    Player[] private Bettors;
    constructor(string nameEvent,uint8 feePercentage,address teamAccount,uint eventEndTime) public{
        manager = teamAccount;
        name = nameEvent;
        devPercentage = feePercentage;
        Bettors.push(
            Player(
                [uint256 (0),0,0,0,0,0,0,0,0,0,0,0],
                address(this),
                0
        ));
        endTime = eventEndTime;

    }
    function enterEvent(uint[12] playerValue) external payable{
        require(validPurchase());
        require(
            msg.value == (playerValue[0] + playerValue[1]+playerValue[2]+playerValue[3]+playerValue[4]+playerValue[5]+playerValue[6]+playerValue[7]+playerValue[8]+playerValue[9]+playerValue[10]+playerValue[11])
        );
        
        Bettors[0].totalPlayerBet += msg.value;
        for(uint a = 0;a<12;a++){
            Bettors[0].betsValue[a] += playerValue[a];    
        }
        
        
        if(index[msg.sender] == 0){ 
            Bettors.push(Player(playerValue,msg.sender,msg.value));
            index[msg.sender] = Bettors.length-1;
        }
        else{ 
            Player storage bettor = Bettors[index[msg.sender]];
            bettor.totalPlayerBet += msg.value;
            for(uint b = 0;b<12;b++){
                bettor.betsValue[b] += playerValue[b];    
            }

        }
   
    }


    function splitWinnings(uint winnerIndex) public {
        require(!eventEnded);
        require(msg.sender == manager);
        uint devFee = devPercentage*Bettors[0].totalPlayerBet/100;
        manager.transfer(devFee);
        uint newBalance = address(this).balance;
        uint16 winnersCount;
        uint share = 0;
        for(uint l = 1; l<Bettors.length ;l++){
            if(Bettors[l].betsValue[winnerIndex]>0){
                share = Bettors[l].betsValue[winnerIndex]*newBalance/Bettors[0].betsValue[winnerIndex];
                (Bettors[l].playerAddress).transfer(share);
                winnersCount++;
            }
        }
        if(winnersCount==0){
            for(uint g = 1; g<Bettors.length ;g++){
                
                share=Bettors[g].totalPlayerBet*newBalance/Bettors[0].totalPlayerBet;
                (Bettors[g].playerAddress).transfer(share);
        }
        }
        eventEnded = true;

    }
    
    function getDetails() public view returns(string ,uint,uint8){
        return (
                name,
                address(this).balance,
                devPercentage
            );
    }
    function validPurchase()  internal  view
        returns(bool) 
    {
        bool withinPeriod = now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool nonInvalidAccount = msg.sender != 0;
        return withinPeriod && nonZeroPurchase && nonInvalidAccount;
    }
}