/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.4.0;

contract LotteryFor10 {
      address[] users; 
    mapping(address => bool) participated;
    uint256 public constant WAIT_BLOCKS_LIMIT = 3 ;
    uint256 public registeredCount ;
    uint256 public _registeredLimit ;
    uint256 constant REGISTERING_PARTICIPANTS = 1;
    uint256 constant REGISTERING_FINISHED = 2;
    uint256 constant WAITING_FOR_RANDOMNESS = 3;
    uint256 constant SOLVING_LOTERRY = 4;
    uint256 constant LOTTERY_SOLVED = 5;
    uint256 public waitingStartBlockNumber;
    bool public lotterySolved;
    
    constructor(uint256 _limit) public{
        waitingStartBlockNumber = 0;
        registeredCount = 0;//good habit not to rely on defaults if You do not have to
        _registeredLimit = _limit;
    }
    
    
    
    function () public payable{
        
        if(getStage(block.number)==REGISTERING_PARTICIPANTS){
            processAddingUser(msg.sender);
        }
        else{ // this else is crutial so we never enter two stages in same call
            if(getStage(block.number)==REGISTERING_FINISHED){
                require(msg.value == 0,"no additional stake allowed");
                waitingStartBlockNumber = block.number;
                emit ClosingList(waitingStartBlockNumber);
            }
            else{
                if(getStage(block.number)==WAITING_FOR_RANDOMNESS){
                        require(msg.value == 0,"no additional stake allowed");
                        
                        revert("To little time passed, wait at least WAIT_BLOCKS_LIMIT ");
                }
                else{
                    if(getStage(block.number)==SOLVING_LOTERRY){
                        require(msg.value == 0,"no additional stake allowed");
                        processSolvingLottery(block.number);
                    }
                    else{        
                        revert("Lottery Closed ");
                    }
                }
            }
        }
    }
    
    
    function getStage(uint256 blockNum) private view returns(uint256) {
        if(registeredCount<_registeredLimit){
            return REGISTERING_PARTICIPANTS;
        }
        else{
            if(waitingStartBlockNumber==0 //start waiting block has been never set
                || blockNum-waitingStartBlockNumber>=256 //start waiting block has been set long time ago
                ){
                return REGISTERING_FINISHED;
            }
            else
            {
                if(blockNum-waitingStartBlockNumber<WAIT_BLOCKS_LIMIT){
                    return WAITING_FOR_RANDOMNESS;
                }
                else{
                    if(lotterySolved == true){
                        return LOTTERY_SOLVED;
                    }
                    else{
                        return SOLVING_LOTERRY;
                    }
                }
            }
        }
    }
    
    function processAddingUser(address sender) private{
        require(msg.value==1 finney,"Must send 0.001 ether");
        require(participated[sender]==false,"One address can pericipate only once");
        require(registeredCount<_registeredLimit,"ups getStage() do not work");
        participated[sender] = true;
        users.push(sender);
        registeredCount = registeredCount+1;
        emit UserRegistered(sender);
    }
    
    function processSolvingLottery(uint256 blockNum) private{
        uint256 luckyNumber = uint256(blockhash(waitingStartBlockNumber+WAIT_BLOCKS_LIMIT));
        luckyNumber = luckyNumber % _registeredLimit;
        users[luckyNumber].transfer(address(this).balance);
        emit UseRewarded(users[luckyNumber],blockNum);
        lotterySolved = true;
    }
    
    event ClosingList(uint256 blockNum);
    event UserRegistered(address adr);
    event UseRewarded(address adr,uint256 blockNum);
}