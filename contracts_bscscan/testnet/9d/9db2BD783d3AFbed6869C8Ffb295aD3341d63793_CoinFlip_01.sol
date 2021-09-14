/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract CoinFlip_01{
    mapping(address=>gamble[]) public gambleList; //lists of gambles by address
    mapping(address=>uint) gambleCount; //number of gambles by account
    mapping(address=>bool)  public isAvailable; //indicates if the address already has a bet
    mapping(address=>bool)  public winners; // list of winner available to claim price
    address burn=0x000000000000000000000000000000000000dEaD; //burn address on ethereum used to fill the first places on the arrays
    address[]  headsLine; //List of address betting high
    address[]  tailsLine; //List of address betting low
    uint ammount = 0.1 ether; //the bet
    address payable owner; // the owner of this contract
    uint betIndex; //current bet being played
    uint headsLineIndex; //indicates how many address are betting high
    uint tailsLineIndex; //indicates how many address are betting low
    uint withdrawableAmmount= 0 ether; //earnings of the owner
    
    struct gamble{
        address player;
        address opponent;
        string choice;
        address winner;
        uint number;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    
    constructor(){
        owner=payable(msg.sender);
        betIndex=1;
        headsLineIndex= 1;
        tailsLineIndex= 1;
        headsLine.push(burn);
        tailsLine.push(burn);
    }

    function enterheadsLine() external payable returns(uint){
        require(msg.value== ammount && isAvailable[msg.sender]==false); //verifying if the ammount is correct and if they dont have anothe ber in this category
        isAvailable[msg.sender]=true;
        headsLine.push(msg.sender);
        headsLineIndex++;
        return play();
    }
    
    function entertailsLine() external payable returns(uint){
        require(msg.value== ammount && isAvailable[msg.sender]==false); //verifying if the ammount is correct and if they dont have anothe ber in this category
        isAvailable[msg.sender]=true;
        tailsLine.push(msg.sender);
        tailsLineIndex++;
        return play();
    }
    
    function play() internal  returns(uint){
        uint randNumber;
        address payable refund;
        if(betIndex<headsLineIndex && betIndex<tailsLineIndex){
            if(isAvailable[headsLine[betIndex]]==true  && isAvailable[tailsLine[betIndex]]==true){
                randNumber=uint(keccak256(abi.encodePacked(block.timestamp, headsLine[betIndex], tailsLine[betIndex])))%10;
                if(randNumber>=5){
                    winners[headsLine[betIndex]]=true;
                    gambleList[headsLine[betIndex]].push(gamble(headsLine[betIndex],tailsLine[betIndex],"heads",headsLine[betIndex],randNumber));
                    gambleList[tailsLine[betIndex]].push(gamble(tailsLine[betIndex],headsLine[betIndex],"tails",headsLine[betIndex],randNumber));
                    gambleCount[headsLine[betIndex]]++;
                    gambleCount[tailsLine[betIndex]]++;
                    isAvailable[tailsLine[betIndex]]=false;//allowing player to enter another bet in this category
            }
                else{
                    winners[tailsLine[betIndex]]=true;
                    gambleList[headsLine[betIndex]].push(gamble(headsLine[betIndex],tailsLine[betIndex],"heads",tailsLine[betIndex],randNumber));
                    gambleList[tailsLine[betIndex]].push(gamble(tailsLine[betIndex],headsLine[betIndex],"tails",tailsLine[betIndex],randNumber));
                    gambleCount[headsLine[betIndex]]++;
                    gambleCount[tailsLine[betIndex]]++;
                    isAvailable[headsLine[betIndex]]=false;//allowing player to enter another bet in this category
                }
            
                withdrawableAmmount= withdrawableAmmount+ 0.0064 ether;
                betIndex++;
            }
            
            else{
                randNumber=10;
                if(isAvailable[headsLine[betIndex]]==true){
                    isAvailable[headsLine[betIndex]]=false;
                    refund=payable(headsLine[betIndex]);
                    refund.transfer(0.1 ether);
                    gambleList[headsLine[betIndex]].push(gamble(headsLine[betIndex],tailsLine[betIndex],"opponent retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleList[tailsLine[betIndex]].push(gamble(tailsLine[betIndex],headsLine[betIndex],"you retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleCount[headsLine[betIndex]]++;
                    gambleCount[tailsLine[betIndex]]++;
                }
                if(isAvailable[tailsLine[betIndex]]==true){
                    isAvailable[tailsLine[betIndex]]=false;
                    refund=payable(tailsLine[betIndex]);
                    refund.transfer(0.1 ether);
                    gambleList[headsLine[betIndex]].push(gamble(headsLine[betIndex],tailsLine[betIndex],"you retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleList[tailsLine[betIndex]].push(gamble(tailsLine[betIndex],headsLine[betIndex],"opponent retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleCount[headsLine[betIndex]]++;
                    gambleCount[tailsLine[betIndex]]++;
                }
                betIndex++;
            }
        }
        else{
            randNumber=11;
        }
        return randNumber;
    }

    function retire() external{
        require(isAvailable[msg.sender]==true);
        address payable quiter= payable(msg.sender);
        isAvailable[msg.sender]=false;
        quiter.transfer(0.0968 ether);
        withdrawableAmmount= withdrawableAmmount+ 0.0032 ether;
    }
    
    function claimPrice() external{
        require(winners[msg.sender]==true);
        address payable winner= payable(msg.sender);
        winner.transfer(0.1936 ether);
        winners[msg.sender]=false;
        isAvailable[msg.sender]=false;
    }
    
    function checkisAvailable() external view returns (bool){
        return isAvailable[msg.sender];
    }
    
    function lastGamble() external view returns (gamble memory){
        require(gambleCount[msg.sender]>=1);
        return gambleList[msg.sender][gambleCount[msg.sender]-1];
    }
    function withdraw() external onlyOwner{
        owner.transfer(withdrawableAmmount);
        withdrawableAmmount=0 ether;
    }
    
    function changeOwner(address _newOwner) external onlyOwner{ //change the owner of the contract
        owner=payable(_newOwner);
    }
}