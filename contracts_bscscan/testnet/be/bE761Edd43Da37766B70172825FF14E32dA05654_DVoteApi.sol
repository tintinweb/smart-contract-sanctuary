/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

struct Poll {
    uint256 pollId;
    uint256 foundationPrizePool;
    uint256 additionalPrizePool;
    uint256 numberOfVote;
    uint256 amountOfVote;
    string title;
    string context;
    string[] url;
    string[] options;
    uint earningsRatio; // denominator 10000
    uint creationTime;
    uint endTime;
    uint level;
    bool isQualified;
    bool isFinished;
    address sender;
}

struct PollSimple {
    uint256 pollId;
    string title;
    string context;
    uint creationTime;
    uint endTime;
    uint level;
    address sender;
}

struct PollVoterRecord {
    uint256 voterId;
    uint256 pollId;
    uint256 optionId;
    uint256 amount;
    uint256 income;
    uint time;
    bool isFinished;
    address sender;
}

interface DVote {

    function createPoll(string memory __title, string memory __context, uint __endTime, string[] memory __options, string[] memory __url, uint __level, uint256 __additionalPrizePool, address __sender) external returns (bool);

    function vote(uint256 __pollId, uint __index, uint256 __amount, address __sender) external returns (bool);

    function receiveVotingProfit(uint256 __voterId, address __sender) external returns (uint256 amount, uint256 income);

    /*****************************************/

    function getPollsLength() external view returns (uint256);

    function getPoll(uint256 __pollId) external view returns (Poll memory);

    function getPollVotingInfo(uint256 __pollId) external view returns (uint256[] memory numberOfOptions, uint256[] memory amountOfOptions);

    function getPollVotingDetailCount10Desc(uint256 __pollId, uint256 __index) external view returns(uint256[10] memory);

    function getUserVoteStatistical(address __sender) external view returns (uint256 totalAmount, uint256 totalIncome, uint256 totalNumber);

    function getUserVoteIdOfPolls(uint256 __pollId, address __sender) external view returns (uint256);

    function getUserCreatePollRecordsLength(address __sender) external view returns (uint256);

    function getUserCreatePollRecord(address __sender, uint __index) external view returns (uint256);

    function getPollsInTheVoteLength() external view returns (uint256);

    function getPollsInTheVote(uint __index) external view returns (uint256);

    function getPollsVotingClosedLength() external view returns (uint256);

    function getPollsVotingClosed(uint __index) external view returns (uint256);

    function getPollVoterRecordsLength() external view returns (uint256);

    function getPollVoterRecord(uint256 __voterId) external view returns (PollVoterRecord memory);

    function getUserVoterRecordsLength(address __sender) external view returns (uint256);

    function getUserVoterRecords(address __sender, uint __index) external view returns (uint256);

    function getDVoteInfo() external view returns (uint256 totalPublisherConsumption, uint256 totalPoolConsumption, uint256 totalVoterConsumption);
}

contract DVoteApi {

    address private _owner;
    address private _body;
    DVote private _dvote;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (address __dvote) {
        _owner = msg.sender;
        _body = __dvote;
        _dvote = DVote(__dvote);
    }

    function createPoll(string memory __title, string memory __context, uint __endTime, string[] memory __options, string[] memory __url, uint __level, uint256 __additionalPrizePool) external returns (bool)
    {
        return _dvote.createPoll(__title, __context, __endTime, __options, __url, __level, __additionalPrizePool, msg.sender);
    }

    function vote(uint256 __pollId, uint __index, uint256 __amount) external returns (bool)
    {
        return _dvote.vote(__pollId, __index, __amount, msg.sender);
    }

    function receiveVotingProfit(uint256 __voterId) external returns (uint256 amount, uint256 income)
    {
        return _dvote.receiveVotingProfit(__voterId, msg.sender);
    }

    /*****************************************/

    function getDVoteAddress() external view returns (address)
    {
        return _body;
    }

    function getPollsLength() external view returns (uint256)
    {
        return _dvote.getPollsLength();
    }

    function getPollInfo(uint256 __pollId) external view returns (Poll memory poll, uint256[] memory numberOfOptions, uint256[] memory amountOfOptions)
    {
        poll = _dvote.getPoll(__pollId);
        (numberOfOptions, amountOfOptions) = _dvote.getPollVotingInfo(__pollId);
    }

    function getPollVotingDetailCount10Desc(uint256 __pollId, uint256 __index) external view returns(PollVoterRecord[10] memory list)
    {
        uint256[10] memory voterIds = _dvote.getPollVotingDetailCount10Desc(__pollId, __index);
        for (uint i=0; i<10; i++)
        {
            list[i] = _dvote.getPollVoterRecord(voterIds[i]);
        }
    }
    function getUserVoteStatistical(address __sender) external view returns (uint256 totalAmount, uint256 totalIncome, uint256 totalNumber)
    {
        return _dvote.getUserVoteStatistical(__sender);
    }

    function getUserVoteIdOfPolls(uint256 __pollId, address __sender) external view returns (uint256)
    {
        return _dvote.getUserVoteIdOfPolls(__pollId, __sender);
    }

    function getUserCreatePollRecordsLength(address __sender) external view returns (uint256)
    {
        return _dvote.getUserCreatePollRecordsLength(__sender);
    }

    function getPollsInTheVoteLength() external view returns (uint256)
    {
        return _dvote.getPollsInTheVoteLength();
    }

    function getPollSimple(uint256 __pollId) internal view returns (PollSimple memory)
    {
        Poll memory _poll = _dvote.getPoll(__pollId);
        return PollSimple({
            pollId:_poll.pollId,
            title:_poll.title,
            context:_poll.context,
            creationTime:_poll.creationTime,
            endTime:_poll.endTime,
            level:_poll.level,
            sender:_poll.sender
        });
    }

    function getPollsInTheVoteCount10(uint __index) external view returns (PollSimple[10] memory list)
    {
        uint length = _dvote.getPollsInTheVoteLength();
        if (__index < length)
        {
            uint256 begin = __index;
            uint256 end = length;
            if (__index + 10 < length)
            {
                end = __index + 10;
            }
            uint j = 0;
            for (uint256 i=begin; i<end; i++)
            {
                list[j] = getPollSimple(_dvote.getPollsInTheVote(i));
                j++;
            }
        }
    }

    function getPollsVotingClosedLength() external view returns (uint256)
    {
        return _dvote.getPollsVotingClosedLength();
    }

    function getPollsVotingClosedCount10Desc(uint index) external view returns (PollSimple[10] memory list)
    {
        uint length = _dvote.getPollsInTheVoteLength();
        if (index > 0 && index <= length)
        {
            uint begin = index-1;
            uint end = 0;
            if (index >= 10)
            {
                end = index-10;
            }
            uint j = 0;
            uint i = begin;
            while(true)
            {
                list[j] = getPollSimple(_dvote.getPollsVotingClosed(i));
                if (i == end) break;
                i--;
                j++;
            }
        }
    }

    function getPollVoterRecord(uint256 __pollId, address __sender) external view returns (PollVoterRecord memory)
    {
        uint256 __voterId = _dvote.getUserVoteIdOfPolls(__pollId, __sender);
        return _dvote.getPollVoterRecord(__voterId);
    }

    function getDVoteInfo() external view returns (uint256 totalPublisherConsumption, uint256 totalPoolConsumption, uint256 totalVoterConsumption)
    {
        return _dvote.getDVoteInfo();
    }
}