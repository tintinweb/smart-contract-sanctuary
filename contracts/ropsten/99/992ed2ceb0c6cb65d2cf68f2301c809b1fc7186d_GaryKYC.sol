pragma solidity 0.4.24;

contract GaryKYC {
    
    struct User {
        string userName;
        string userEmail;
        bool isVerified;
    }
    
    address public adminAddr;
    mapping (address => User) public userMap;
    
    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);
    event TransferAdmin(address _newAdminAddr);
    
    constructor () public {
        adminAddr = msg.sender;
    }
    
    function addUser(address _userAddr, string _userName, string _userEmail) public {
        require(
            msg.sender == address(adminAddr),
            "Only admin can add user."
        );
        userMap[_userAddr] = User(_userName, _userEmail, true);
        emit AddUser(_userAddr, _userName, _userEmail);
    }
    
    function removeUser(address _userAddr) public {
        require(
            msg.sender == address(adminAddr),
            "Only admin can remove user."
        );
        userMap[_userAddr] = User("", "", false);
        emit RemoveUser(_userAddr);
    }
    
    function getUserInfo(address _userAddr) constant public returns (string, string, bool) {
        User memory result = userMap[_userAddr];
        return (result.userName, result.userEmail, result.isVerified);
    }
    
    function isUserKYCed(address _userAddr) constant public returns (bool) {
        return userMap[_userAddr].isVerified;
    }
    
    function transferAdmin(address _newAdminAddr) public {
        require(
            msg.sender == address(adminAddr),
            "Only admin can transfer admin"
        );
        
        adminAddr = _newAdminAddr;
        emit TransferAdmin(_newAdminAddr);
    }
}