/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.0 <0.9.0;

//Use 0.8.3

contract Token {
    function changeArtistAddress(address newAddress) external {}
    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool){}
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ApolloDAO is Context {

    Token public immutable apolloToken;

    event newDaoNomination(address indexed newDAO, address indexed nominator);

    struct newDAONomination {
    uint256 timeOfNomination;
    address nominator;
    uint256 votesFor;
    uint256 votesAgainst;
    bool votingClosed;
    }

    struct DAOVotes {
        uint256 voteCount;
        bool votedFor;
    }

    mapping (address => newDAONomination) private newDAONominations;
    mapping (address => mapping (address => DAOVotes)) private lockedVotes;

    uint256 public constant daoVotingDuration = 300;
    uint256 public constant minimumDAOBalance = 20000000000 * 10**9;
    uint256 public totalLockedVotes;
    uint256 public activeDaoNominations;

    address public approvedNewDAO = address(0);
    uint256 public constant daoUpdateDelay = 300;
    uint256 public daoApprovedTime;


    constructor (address tokenAddress) {
        apolloToken = Token(tokenAddress);
    }


    function voteForDAONomination (uint256 voteAmount, address newDAO, bool voteFor) external {
        require(newDAONominations[newDAO].timeOfNomination > 0 , "There is no DAO Nomination for this address");
        require(lockedVotes[_msgSender()][newDAO].voteCount == 0, "User already voted on this nomination");
        require(approvedNewDAO == address(0), "There is already an approved new DAO");
        apolloToken.transferFrom(_msgSender(), address(this), voteAmount);
        totalLockedVotes += voteAmount;
        lockedVotes[_msgSender()][newDAO].voteCount += voteAmount;
        lockedVotes[_msgSender()][newDAO].votedFor = voteFor;
        if(voteFor){
            newDAONominations[newDAO].votesFor += voteAmount;
        } else {
            newDAONominations[newDAO].votesAgainst += voteAmount;
        }
    }

    function withdrawNewDAOVotes (address newDAO) external {
        uint256 currentVoteCount = lockedVotes[_msgSender()][newDAO].voteCount;
        require(currentVoteCount > 0 , "You have not cast votes for this nomination");
        require((totalLockedVotes - currentVoteCount) >= 0, "Withdrawing would take DAO balance below expected rewards amount");
        apolloToken.transfer(_msgSender(), currentVoteCount);

        totalLockedVotes -= currentVoteCount;
        lockedVotes[_msgSender()][newDAO].voteCount -= currentVoteCount;

        if(lockedVotes[_msgSender()][newDAO].votedFor){
            newDAONominations[newDAO].votesFor -= currentVoteCount;
        } else {
            newDAONominations[newDAO].votesAgainst -= currentVoteCount;
        }

    }

    function nominateNewDAO (address newDAO) external {
        require(apolloToken.balanceOf(_msgSender()) >= minimumDAOBalance , "Nominator does not own enough APOOLLO");
        newDAONominations[newDAO] = newDAONomination(
            {
                timeOfNomination: block.timestamp,
                nominator: _msgSender(),
                votesFor: 0,
                votesAgainst: 0,
                votingClosed: false
            }
        );
        activeDaoNominations += 1;
        emit newDaoNomination(newDAO, _msgSender());
    }

    function closeNewDAOVoting (address newDAO) external {
        require(block.timestamp > (newDAONominations[newDAO].timeOfNomination + daoVotingDuration), "We have not passed the minimum voting duration");
        require(!newDAONominations[newDAO].votingClosed, "Voting has already closed for this nomination");
        require(approvedNewDAO == address(0), "There is already an approved new DAO");

        if(newDAONominations[newDAO].votesFor > newDAONominations[newDAO].votesAgainst){
            approvedNewDAO = newDAO;
            daoApprovedTime = block.timestamp;
        }
        activeDaoNominations -= 1;
        newDAONominations[newDAO].votingClosed = true;
    }

    function updateDAOAddress() external {
        require(approvedNewDAO != address(0),"There is not an approved new DAO");
        require(block.timestamp > (daoApprovedTime + daoUpdateDelay), "We have finished the delay for an approved DAO");
        apolloToken.changeArtistAddress(approvedNewDAO);
    }

    function daoNominationTime(address dao) external view returns (uint256){
        return newDAONominations[dao].timeOfNomination;
    }

    function daoNominationNominator(address dao) external view returns (address){
        return newDAONominations[dao].nominator;
    }

    function daoNominationVotesFor(address dao) external view returns (uint256){
        return newDAONominations[dao].votesFor;
    }

    function daoNominationVotesAgainst(address dao) external view returns (uint256){
        return newDAONominations[dao].votesAgainst;
    }

    function daoNominationVotingClosed(address dao) external view returns (bool){
        return newDAONominations[dao].votingClosed;
    }

    function checkAddressVoteAmount(address voter, address dao) external view returns (uint256){
        return lockedVotes[voter][dao].voteCount;
    }

    function checkAddressVotedFor(address voter, address dao) external view returns (bool){
        return lockedVotes[voter][dao].votedFor;
    }



}