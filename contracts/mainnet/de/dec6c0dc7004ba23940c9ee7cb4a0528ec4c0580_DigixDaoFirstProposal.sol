pragma solidity ^0.4.24;

/// @title DigixDAO&#39;s 2nd Carbon Voting contracts
/// @author Digix Holdings

/// @notice NumberCarbonVoting contract, generalized carbon voting contract
contract NumberCarbonVoting {
    uint256 public start;
    uint256 public end;
    struct VoteItem {
        bytes32 title;
        uint256 minValue;
        uint256 maxValue;
        mapping (address => uint256) votes;
    }

    mapping(uint256 => VoteItem) public voteItems;
    uint256 public itemCount;

    mapping(address => bool) public voted;
    address[] public voters;

    constructor (
        uint256 _itemCount,
        bytes32[] _titles,
        uint256[] _minValues,
        uint256[] _maxValues,
        uint256 _start,
        uint256 _end
    )
        public
    {
        itemCount = _itemCount;
        for (uint256 i=0;i<itemCount;i++) {
            voteItems[i].title = _titles[i];
            voteItems[i].minValue = _minValues[i];
            voteItems[i].maxValue = _maxValues[i];
        }
        start = _start;
        end = _end;
    }

    function vote(uint256[] _votes) public {
        require(_votes.length == itemCount);
        require(now >= start && now < end);

        address voter = msg.sender;
        if (!voted[voter]) {
            voted[voter] = true;
            voters.push(voter);
        }

        for (uint256 i=0;i<itemCount;i++) {
            require(_votes[i] >= voteItems[i].minValue && _votes[i] <= voteItems[i].maxValue);
            voteItems[i].votes[voter] = _votes[i];
        }
    }

    function getAllVoters() public view
        returns (address[] _voters)
    {
        _voters = voters;
    }

    function getVotesForItem(uint256 _itemIndex) public view
        returns (address[] _voters, uint256[] _votes)
    {
        return getVotesForItemFromVoterIndex(_itemIndex, 0, voters.length);
    }


    /// @dev get votes for a subset of _count voters, from _voterIndex
    function getVotesForItemFromVoterIndex(uint256 _itemIndex, uint256 _voterIndex, uint256 _count) public view
        returns (address[] _voters, uint256[] _votes)
    {
        require(_itemIndex < itemCount);
        require(_voterIndex < voters.length);

        _count = min(voters.length - _voterIndex, _count);
        _voters = new address[](_count);
        _votes = new uint256[](_count);
        for (uint256 i=0;i<_count;i++) {
            _voters[i] = voters[_voterIndex + i];
            _votes[i] = voteItems[_itemIndex].votes[_voters[i]];
        }
    }

    function min(uint256 _a, uint256 _b) returns (uint256 _min) {
        _min = _a;
        if (_b < _a) {
            _min = _b;
        }
    }

    function getVoteItemDetails(uint256 _itemIndex) public view
        returns (bytes32 _title, uint256 _minValue, uint256 _maxValue)
    {
        _title = voteItems[_itemIndex].title;
        _minValue = voteItems[_itemIndex].minValue;
        _maxValue = voteItems[_itemIndex].maxValue;
    }

    function getUserVote(address _voter) public view
        returns (uint256[] _votes, bool _voted)
    {
        _voted = voted[_voter];
        _votes = new uint256[](itemCount);
        for (uint256 i=0;i<itemCount;i++) {
            _votes[i] = voteItems[i].votes[_voter];
        }
    }
}

/// @notice the actual carbon voting contract, specific to DigixDAO&#39;s 2nd carbon voting: DigixDAO&#39;s first proposal
contract DigixDaoFirstProposal is NumberCarbonVoting {
    constructor (
        uint256 _itemCount,
        bytes32[] _titles,
        uint256[] _minValues,
        uint256[] _maxValues,
        uint256 _start,
        uint256 _end
    ) public NumberCarbonVoting(
        _itemCount,
        _titles,
        _minValues,
        _maxValues,
        _start,
        _end
    ) {
    }
}