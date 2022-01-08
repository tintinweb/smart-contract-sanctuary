/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity ^0.5.0;

contract Voting{
    //candidate registration
    //election start
    //voters voting 
    //result announce
    
    string[] candName = new string[](2);
    mapping(string=>uint256) noOfVotes; 
    mapping (string=>bool) isValidCandidate;
    constructor() public{
        candName[0] = "Rahul";
        candName[1] = "Kiran";
        isValidCandidate["Rahul"] = true;
        isValidCandidate["Kiran"] = true;
    }
    mapping (address=>bool) isVoted;

    modifier isValidVoterMod(address accAddr) {
        // return true;
        require(!isVoted[accAddr],"already voted");
        _;
    }

    function voting(string memory _candName) isValidVoterMod(msg.sender) public {
        require(isValidCandidate[_candName],"not a valid candidate");
        require(isEleStarted,"election not started");
        require(eleStartTime+ 10 minutes> block.timestamp,"election got over");

        uint256 noOfVotesSoFar =  noOfVotes[_candName];
        noOfVotes[_candName] = noOfVotesSoFar+1;
        isVoted[msg.sender]= true;
    }

    function noOfVSF(string memory _candName) public view returns(uint256){
        return noOfVotes[_candName];
    }

    uint256 eleStartTime;
    bool isEleStarted = false;

    function setEleStartTime() public {
        require(!isEleStarted,"election started");
        eleStartTime = block.timestamp;
        isEleStarted = true;
    }

    function result() public view returns(uint256) {
        if(isEleStarted){
            if(eleStartTime+ 10 minutes < block.timestamp) { //isElection Ended
                if(noOfVotes["Rahul"]>noOfVotes["Kiran"]){
                    return 1; //rahul 
                }
                else if(noOfVotes["Kiran"]>noOfVotes["Rahul"]){
                    return 2; //karan 
                }
                else {
                    return 3; // tie 
                }
            }
            else{
                return 4;//election isn't ended
            }
        }
        else{
            return 0; //election not started
        }
    }
}