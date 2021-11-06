/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Poll
 * @dev
 */
contract Poll{

  struct PollConfig {
    uint256 startTime;
    uint256 endTime;
    uint256 minHolding;
    uint256 minQuorum;
    uint256 minWinPorcent;
  }

  struct VotingStatus {
    uint256 numVotes;
    uint256 fullWeightVote;
    uint256 weightVotePositive;
    uint256 weightVoteNegative;
  }

    PollConfig public pollConfig;
    VotingStatus private votingStatus;
    address[] public addresses;
    address public owner;

    constructor(uint256 startTime, uint256 endTime, uint256 minHolding, uint256 minQuorum, uint256 minWinPorcent) {

        // validate inputs
        require(startTime>block.timestamp);
        require(endTime>startTime);
        require(minWinPorcent<101);

        owner = msg.sender;

        pollConfig = PollConfig({
            startTime : startTime,
            endTime : endTime,
            minHolding : minHolding,
            minQuorum : minQuorum,
            minWinPorcent : minWinPorcent
        });

        votingStatus = VotingStatus({
           numVotes : 0,
           fullWeightVote : 0,
           weightVotePositive:0,
           weightVoteNegative:0
        });

    }


    function vote(uint userVote) public returns(bool success){
        // validation input
        require (userVote>0&&userVote<3);

        address sender = msg.sender;
        uint256 balance = sender.balance;

        // business validation
        require(balance>pollConfig.minHolding);
        require(block.timestamp>pollConfig.startTime&&block.timestamp<pollConfig.endTime);
        for (uint i=0; i < addresses.length; i++) {
            require (sender!=addresses[i]);

        }


        //vote
        addresses.push(sender);
        votingStatus.numVotes+=1;
        votingStatus.fullWeightVote+=balance;
        if (userVote==1){
            votingStatus.weightVotePositive+=balance;
        } else if (userVote==2){
            votingStatus.weightVoteNegative+=balance;
        }

        return true;
    }


    function getAddressCount() public view returns(uint count) {
        return addresses.length;
    }

    function getAddressBalance(uint row) public view returns(uint256 balance) {
        return addresses[row].balance;
    }

    function getAddressAtRow(uint row) public view returns(address theAddress) {
        return addresses[row];
    }

    function getStartTime() public view returns (uint256){
        return pollConfig.startTime;
    }

    function getEndTime() public view returns (uint256){
        return pollConfig.endTime;
    }

    function getMinHolding() public view returns (uint256){
        return pollConfig.minHolding;
    }

    function getMinQuorum() public view returns (uint256){
        return pollConfig.minQuorum;
    }

    function getMinWinPorcent() public view returns (uint256){
        return pollConfig.minWinPorcent;
    }

    function getFullWeigth() public view returns (uint256){
        if (msg.sender==owner){
            return votingStatus.fullWeightVote;
        } else {
            return 0;
        }
    }
    function getPositiveWeigth() public view returns (uint256){
        if (msg.sender==owner){
            return votingStatus.weightVotePositive;
        } else {
            return 0;
        }
    }
    function getNegativeWeigth() public view returns (uint256){
        if (msg.sender==owner){
            return votingStatus.weightVoteNegative;
        } else {
            return 0;
        }
    }
    function getNumVotes() public view returns (uint256){
        if (msg.sender==owner){
            return votingStatus.numVotes;
        } else {
            return 0;
        }
    }
    function getResult() public view returns (int256){
        if (block.timestamp < pollConfig.endTime){
            return -1;
        }
        if (votingStatus.numVotes < pollConfig.minQuorum){
            return -2;
        }
        if (votingStatus.weightVotePositive > votingStatus.weightVoteNegative){
            if (100*votingStatus.weightVotePositive/votingStatus.fullWeightVote < pollConfig.minWinPorcent){
                return -3;
            } else {
                return 1;
            }
        } else if (votingStatus.weightVotePositive < votingStatus.weightVoteNegative){
            if (100*votingStatus.weightVoteNegative/votingStatus.fullWeightVote < pollConfig.minWinPorcent){
                return -4;
            } else {
                return 2;
            }
        } else {
            return 3;
        }
    }




}