pragma solidity ^0.4.18;

contract UserInfoContract {
    address _creator;
    
    /*** EVENTS ***/
    event AddUser(uint32 userId,uint64 securityCode);
    
    struct User {
        uint32 _userId;
        uint64 _securityCode;
    }
    
    mapping (uint32 => User) _users;
    
    modifier onlyCreate() {
        require(msg.sender == _creator);
        _;
    }

    function UserInfoContract() public {
        _creator = msg.sender;
    }

    function createUser(uint32 userId,uint64 securityCode) public onlyCreate returns (uint32) {
        User memory _user = User({
                                    _userId: userId,
                                    _securityCode: securityCode
                                    });
        _users[userId] = _user;
        AddUser(userId,securityCode);
        return userId;
    }

    function getUser(uint32 userId) public view returns (uint64) {
        User storage user = _users[userId];
        return user._securityCode;
    }
}