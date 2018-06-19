pragma solidity ^0.4.18;

contract DPOS {
    uint256 public limit;
    address public owner;
    struct VoteItem {
        string content;
        uint agreeNum;
        uint disagreeNum;
    }
    struct VoteRecord {
        address voter;
        bool choice;
    }

    mapping (uint => VoteItem) public voteItems;
    mapping (uint => VoteRecord[]) public voteRecords;

    event Create(uint indexed _id, string indexed _content);
    event Vote(uint indexed _id, address indexed _voter, bool indexed _choice);

    function DPOS() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setLimit(uint256 _limit) public onlyOwner returns (bool) {
        limit = _limit;
        return true;
    }
    
    function lengthOfRecord(uint256 _id) public view returns (uint length) {
        return voteRecords[_id].length;
    }

    function create(uint _id, string _content) public onlyOwner returns (bool) {
        VoteItem memory item = VoteItem({content: _content, agreeNum: 0, disagreeNum: 0});
        voteItems[_id] = item;
        Create(_id, _content);
        return true;
    }

    function vote(uint _id, address _voter, bool _choice) public onlyOwner returns (bool) {
        if (_choice) {
            voteItems[_id].agreeNum += 1;
        } else {
            voteItems[_id].disagreeNum += 1;
        }
        VoteRecord memory record = VoteRecord({voter: _voter, choice: _choice});
        voteRecords[_id].push(record);
        Vote(_id, _voter, _choice);
        return true;
    }
}