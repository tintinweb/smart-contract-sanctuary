pragma solidity ^0.4.18;


contract UserInfo {
    address _creator;
    /*** EVENTS ***/
    event AddUser(uint userId,uint256 userHash, uint64 birthDay, uint64 balabalabala);
    
    
    struct User {
        uint256 userHash;
        uint64 birthDay;
        uint64 balabalabala;
    }

    User[] users;
    
    modifier onlyCreate() {
        require(msg.sender == _creator);
        _;
    }

    function UserInfo() public {
        _creator = msg.sender;
    }

    function getUserCount() public view returns(uint) {
        return users.length;
    }

    function createUser(uint256 _userHash,uint64 _birthDay,uint64 _balabalabala) public onlyCreate returns (uint userId) {
        User memory _user = User({
                                    userHash: _userHash,
                                    birthDay: _birthDay,
                                    balabalabala: _balabalabala
                                    });
        
        users.push(_user);
        uint userid = users.length - 1;
        AddUser(userid,_userHash,_birthDay, _balabalabala);
        return userid;
    }

    function getUser(uint64 _userId) public view returns (
                                            uint userId,
                                            uint256 userHash,
                                            uint64 birthDay,
                                            uint64 balabalabala
                                            ) {
        User storage user = users[_userId];
        userId = _userId;
        userHash = user.userHash;
        birthDay = user.birthDay;
        balabalabala = user.balabalabala;
                                            
    }

}