pragma solidity ^0.4.24;

contract UpDownVotes {
    mapping(address => uint8) private _votes;

    string private _url;
    uint256 private _upVotes;
    uint256 private _downVotes;

    constructor(string url) public {
        require( bytes(url).length > 0 );
        _url = url;
        _upVotes = 0;
        _downVotes = 0;
    }
    
    function upVote() public {
        require ( _votes[msg.sender] == 0 );
        _votes[msg.sender] = 1;
        _upVotes = _upVotes + 1;
    }

    function downVote() public {
        require ( _votes[msg.sender] == 0 );
        _votes[msg.sender] = 1;
        _downVotes = _downVotes + 1;
    }
    
    function getUpVotes() public view returns(uint256) {
        return _upVotes;
    }
    
    function getDownVotes() public view returns(uint256) {
        return _downVotes;
    }
    
    function getUrl() public view returns(string) {
        return _url;
    }
}