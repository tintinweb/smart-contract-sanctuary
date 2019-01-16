pragma solidity 0.4.24;

contract KyberKyc {
    address public admin;
    
    struct User {
        address userAddr;
        string userName;
        string userEmail;
    }
    
    mapping (address => User) public companyUserMap;
    
    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);
    
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
}