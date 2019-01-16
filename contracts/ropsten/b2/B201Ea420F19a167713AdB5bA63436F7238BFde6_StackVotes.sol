pragma solidity 0.4.24;

contract StackVotes {
    // Read/write candidate
    address public admin;

    mapping (address => uint8) public userVotes;        
        
    event VoteUser(address _user, address _voter, uint256 _isUpVote );

    // Constructor
    constructor () public {
        admin = msg.sender;
    }

    function votesUser(address _user, uint256 _isUpVote) public{        
        if (_isUpVote == 1){
            userVotes[_user]  = userVotes[_user] + 1;    
        }else{
            userVotes[_user]  = userVotes[_user] - 1;    
        }
        emit VoteUser(_user, msg.sender, _isUpVote);
    }

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}