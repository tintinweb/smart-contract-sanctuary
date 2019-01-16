pragma solidity 0.4.24;

contract StackKYC {
    // Read/write candidate
    address public admin;

    struct User {
        address userAddr;
        string userName;
        string userEmail;
    }

    mapping (address => User) public stackUserMap;    

    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);

    // Constructor
    constructor () public {
        admin = msg.sender;
    }

    function addUser(string _userName, string _userEmail) public{        
        require(
            stackUserMap[msg.sender].userAddr == 0x0,
            "This user have been added."
        );
        stackUserMap[msg.sender] = User(msg.sender, _userName, _userEmail);
        emit AddUser(msg.sender, _userName, _userEmail);
    }

    function removeUser(address _userAddr) public{
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        stackUserMap[_userAddr] = User(0x0,"", "");
        emit RemoveUser(_userAddr);
    }

    function getUserInfo(address _userAddr) constant public returns (address, string, string) {
        User memory user = stackUserMap[_userAddr];
        return (user.userAddr, user.userName, user.userEmail);
    }    

    function isUserExisted(address _userAddr) constant public returns (bool) {
        return  stackUserMap[_userAddr].userAddr == _userAddr;
    }

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}