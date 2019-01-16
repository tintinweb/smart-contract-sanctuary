pragma solidity 0.4.24;

contract KyberRealtion {
    address public admin;
    
    struct User {
        address userAddr;
        string userName;
        string userEmail;
    }
    
    struct Relation {
        address memberAddr;
        address leaderAddr;
    }
    
    mapping (address => User) public companyUserMap;
    mapping (address => Relation) public leaderOfMap;
    
    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);
    event SetRelation(address indexed _memberAddr, address _leaderAddr);
    event RemoveRelation(address indexed _memberAddr);
    
    constructor () public {
        admin = msg.sender;
    }
    
    function addUser(address _userAddr, string _userName, string _userEmail) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        companyUserMap[_userAddr] = User(_userAddr, _userName, _userEmail);
        emit AddUser(_userAddr, _userName, _userEmail);
    }
    
    function removeUser(address _userAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        companyUserMap[_userAddr] = User(0x0, "", "");
        emit RemoveUser(_userAddr);
    }
    
    function getUserInfo(address _userAddr) constant public returns (address, string, string) {
        User memory user = companyUserMap[_userAddr];
        return (user.userAddr, user.userName, user.userEmail);
    }
    
    function isUserKyc(address _userAddr) constant public returns (bool) {
        return companyUserMap[_userAddr].userAddr == _userAddr;
    }
    
    function transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }
    
    function setRelation(address _memberAddr, address _leaderAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        leaderOfMap[_memberAddr] = Relation(_memberAddr, _leaderAddr);
        emit SetRelation(_memberAddr, _leaderAddr);
    }
    
    function removeRelation(address _memberAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        leaderOfMap[_memberAddr] = Relation(0x0, 0x0);
        emit RemoveRelation(_memberAddr);
    }
    
    function getRelation(address _memberAddr) constant public returns (address) {
        Relation memory relation = leaderOfMap[_memberAddr];
        return (relation.leaderAddr);
    }
}