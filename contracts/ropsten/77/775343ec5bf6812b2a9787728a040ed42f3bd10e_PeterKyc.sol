pragma solidity 0.4.24;

contract PeterKyc {
    // Read/write user
    address public admin;
    
    struct User {
        address userAddr;
        string userName;
        string userEmail;
    }
    
    // cau truc du lieu. Map giua user va dia chi cua ho
    mapping (address => User) public companyUserMap;
    
    // event co 2 tac dung 1) de biet tx da di den dau 2) log de check lai lich su cua giao dich
    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);
    
    //constructor nguoi deploy contract se la admin cua SC nay
    constructor () public {
        admin = msg.sender;
    }
    
    function addUser(address _userAddr, string _userName, string _userEmail) public{
        // chi co admin moi goi duoc function nay
        require(
            msg.sender == address(admin),
            "Only admin can call this."
            );
            companyUserMap[_userAddr] = User( _userAddr, _userName, _userEmail);
    }
    
    function removeUser(address _userAddr) public{
        require(
            msg.sender == address(admin),
            "Only admin can call this."
            );
            companyUserMap[_userAddr] = User(0x0, "", "");
    }
    
    // function read thi cho them ham constant de ko lam blockchain thay doi
    function isUserExisted(address _userAddr) constant public returns (bool) {
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