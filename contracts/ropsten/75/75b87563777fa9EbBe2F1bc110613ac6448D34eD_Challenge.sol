/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * Challenge script
 * Can be used in conjunction with a real-world challenge. Once the challenge attempt has been accepted by the current champion, 
 * the challenger becomes the new champion and gets added to the hall of fame.
 */

contract Challenge{
    
    address private champion;
    string private champion_name;
    address private challenger;
    string private challenger_name;
    bool private challengeattempted;
    
    //keep track of a hall of fame of champmions
    event NewChampion(address indexed newChampion, string indexed newChampionName);
    
    //the champion gets initiated as the creator of the contract in the constructor
    constructor(){
        champion = msg.sender;
        champion_name = "First Champion";
        challengeattempted = false;
    }
    
    //If the champion agrees that the challenge has been won, it can call this function to pass the stick and name the challenger the new champion.
    function acceptChallengeOutcome() public{
        require(
            msg.sender == champion,
            "Only the champion can accept the outcome of the challenge"
            );
        if (challengeattempted) {
            champion = challenger;
            champion_name = challenger_name;
            challenger = address(0);
            emit NewChampion(champion, champion_name);
        }
    }
    
    //Attempt a challenge. This function can be expanded to contain an actual challenge, or can just be used as administrative bookkeeping for a real-world challenge.
    function attemptChallenge(string memory name) public{
        require(
            challengeattempted == false,
            "Challenge has already been attempted. Wait until the next Champion is announced or the challenge is invalidated."
        );
        challengeattempted = true;
        challenger = msg.sender;
        challenger_name = name;
    }
    
    //If the champion disagrees with the outcome of the the challenge attempt, he can invalidate the attempt.
    function invalidateChallengeAttempt() public{
        require(
            msg.sender == champion,
            "Only the champion can invalidate the current outcome"
            );
        challengeattempted = false;
    }
    
    function getChampion() external view returns (string memory, address){
        return (champion_name, champion);
    }
    
    function getChallenger() external view returns (string memory, address){
        return (challenger_name, challenger);
    }
    
    function isChallengeAttempted() external view returns (bool){
        return challengeattempted;
    }
}