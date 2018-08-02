pragma solidity ^0.4.24;

/// @title DigixDAO Carbon Voting contract
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

    /// @notice Constructor, accept the number of voting items, and their infos
    /// @param _itemCount Number of voting items
    /// @param _titles List of titles of the voting items
    /// @param _minValues List of min values for the voting items
    /// @param _maxValues List of max values for the voting items
    /// @param _start Start time of the voting (UTC)
    /// @param _end End time of the voting (UTC)
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

    /// @notice Function to case vote in this carbon voting
    /// @dev Every item must be voted on. Reverts if number of votes is
    ///      not equal to the itemCount
    /// @param _votes List of votes on the voting items
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
        uint256 _voterCount = voters.length;
        require(_itemIndex < itemCount);
        _voters = voters;
        _votes = new uint256[](_voterCount);
        for (uint256 i=0;i<_voterCount;i++) {
            _votes[i] = voteItems[_itemIndex].votes[_voters[i]];
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

/// @notice The DigixDAO Carbon Voting contract, this in turn calls the
///         NumberCarbonVoting contract
/// @dev  This contract will be used for carbon voting on
///       minimum DGDs for Moderator status and
///       Rewards pool for Moderators
contract DigixDaoCarbonVoting is NumberCarbonVoting {
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