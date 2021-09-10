/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract DefiBetX2_01e{
    mapping(address=>gamble[]) public gambleList; //lists of gambles by address
    mapping(address=>uint) gambleCount; //number of gambles by account
    mapping(address=>bool)  state01; //indicates if the address already has a bet
    address burn=0x000000000000000000000000000000000000dEaD; //burn address on ethereum used to fill the first places on the arrays
    address[]  high01; //List of address betting high
    address[]  low01; //List of address betting low
    uint ammount01 = 0.1 ether; //the bet
    address payable owner; // the owner of this contract
    uint index01; //current bet being played
    uint highIndex01; //indicates how many address are betting high
    uint lowIndex01; //indicates how many address are betting low
    uint withdrawableAmmount= 0 ether; //earnings of the owner
    
    struct gamble{
        address player;
        address opponent;
        uint bet;
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
        index01=1;
        highIndex01= 1;
        lowIndex01= 1;
        high01.push(burn);
        low01.push(burn);
    }

    function enterHigh01() external payable returns(uint){
        require(msg.value== ammount01 && state01[msg.sender]==false); //verifying if the ammount is correct and if they dont have anothe ber in this category
        state01[msg.sender]=true;
        high01.push(msg.sender);
        highIndex01++;
        return play01();
    }
    
    function enterLow01() external payable returns(uint){
        require(msg.value== ammount01 && state01[msg.sender]==false); //verifying if the ammount is correct and if they dont have anothe ber in this category
        state01[msg.sender]=true;
        low01.push(msg.sender);
        lowIndex01++;
        return play01();
    }
    
    function play01() internal  returns(uint){
        uint randNumber;
        address payable winner;
        address payable refund;
        if(index01<highIndex01 && index01<lowIndex01){
            if(state01[high01[index01]]==true  && state01[low01[index01]]==true){
                randNumber=uint(keccak256(abi.encodePacked(block.timestamp, high01[index01], low01[index01])))%10;
                if(randNumber>=5){
                    winner =payable(high01[index01]);
                    gambleList[high01[index01]].push(gamble(high01[index01],low01[index01],0.1 ether,"high",high01[index01],randNumber));
                    gambleList[low01[index01]].push(gamble(low01[index01],high01[index01],0.1 ether,"low",high01[index01],randNumber));
                    gambleCount[high01[index01]]++;
                    gambleCount[low01[index01]]++;
            }
                else{
                    winner =payable(low01[index01]); 
                    gambleList[high01[index01]].push(gamble(high01[index01],low01[index01],0.1 ether,"high",low01[index01],randNumber));
                    gambleList[low01[index01]].push(gamble(low01[index01],high01[index01],0.1 ether,"low",low01[index01],randNumber));
                    gambleCount[high01[index01]]++;
                    gambleCount[low01[index01]]++;
                }
            
                winner.transfer(0.1932 ether); //transfering funds to the winner
                withdrawableAmmount= withdrawableAmmount+ 0.0064 ether;
                state01[high01[index01]]=false;//allowing player to enter another bet in this category
                state01[low01[index01]]=false;//allowing player to enter another bet in this category
                index01++;
            }
            
            else{
                randNumber=10;
                if(state01[high01[index01]]==true){
                    state01[high01[index01]]=false;
                    refund=payable(high01[index01]);
                    refund.transfer(0.1 ether);
                    gambleList[high01[index01]].push(gamble(high01[index01],low01[index01],0.1 ether,"opponent retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleList[low01[index01]].push(gamble(low01[index01],high01[index01],0.1 ether,"you retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleCount[high01[index01]]++;
                    gambleCount[low01[index01]]++;
                }
                if(state01[low01[index01]]==true){
                    state01[low01[index01]]=false;
                    refund=payable(low01[index01]);
                    refund.transfer(0.1 ether);
                    gambleList[high01[index01]].push(gamble(high01[index01],low01[index01],0.1 ether,"you retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleList[low01[index01]].push(gamble(low01[index01],high01[index01],0.1 ether,"opponent retired",0x000000000000000000000000000000000000dEaD,randNumber));
                    gambleCount[high01[index01]]++;
                    gambleCount[low01[index01]]++;
                }
                index01++;
            }
        }
        else{
            randNumber=11;
        }
        return randNumber;
    }

    function retire01() external{
        require(state01[msg.sender]==true);
        address payable quiter= payable(msg.sender);
        state01[msg.sender]=false;
        quiter.transfer(0.0968 ether);
        withdrawableAmmount= withdrawableAmmount+ 0.0032 ether;
    }
    
    function checkState01() external view returns (bool){
        return state01[msg.sender];
    }
    function lastGambleNumber() external view returns (uint){
        require(gambleCount[msg.sender]>=1);
        return gambleList[msg.sender][gambleCount[msg.sender]-1].number;
    }
    function lastGambleOpponent() external view returns (address){
        require(gambleCount[msg.sender]>=1);
        return gambleList[msg.sender][gambleCount[msg.sender]-1].opponent;
    }
    function lastGambleChoice() external view returns (string memory){
        require(gambleCount[msg.sender]>=1);
        return gambleList[msg.sender][gambleCount[msg.sender]-1].choice;
    }
    function lastGamble() external view returns (gamble memory){
        require(gambleCount[msg.sender]>=1);
        return gambleList[msg.sender][gambleCount[msg.sender]-1];
    }
    function withdraw() external onlyOwner{
        owner.transfer(withdrawableAmmount);
    }
    
    function changeOwner(address _newOwner) external onlyOwner{ //change the owner of the contract
        owner=payable(_newOwner);
    }
}