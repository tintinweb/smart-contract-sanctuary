// @title User-
// @author oshityoung  - <[email protected]>
// @version 0.1
// @date 2021-12-4
pragma solidity ^0.8.0;

import "./ILog.sol";

contract User {
    enum Identity {guest, student, teacher}//身份
    enum Authority {admin, superAdmin, notAdmin}//权限
    struct User {
        address UserAds;
        string Name;
        uint256 StuNo;
        uint256 Grade;
        bytes32 NameNoHash;
        Authority authority;
        Identity identity;
    }

    address superAdmin;
    address[] allUsers;//按序存储用户address，根据用户address可以用users(address=>User)找到User类信息
    address[] allAdmins;
    mapping(address => User) users;
    ILog iLog;
    constructor(address adrs){
        superAdmin = msg.sender;
        iLog = ILog(adrs);
        //给定address对iLog实例化
        initiateSuperAdmin();
    }
    modifier checkSuperAdminAuthority(){//检查是否拥有超管权限
        require(msg.sender == superAdmin);
        _;
    }
    modifier checkAdminAuthority(){//检查管理员权限
        require(checkIfExist(msg.sender, allAdmins));
        _;
    }
    modifier updateAllUsers(){//更新AllUsers数组
        _;
        allUsers.push(msg.sender);
    }
    modifier updateAllAdmins(address _adrs){//更新AllAdmin数组
        _;
        allAdmins.push(_adrs);
    }
    //TODO:加入超级管理员修改用户信息的功能
    function SuperdminModify(string memory _name, uint256 _stuNo, uint256 _grade, Identity _identity, address ModifiedUser) public returns (bool){
        require((msg.sender == superAdmin), "you aren't superadmin");
        //要求拥有管理员权限
        modifyUserInfo(_name, _stuNo, _grade, _identity, ModifiedUser);
        iLog.addLog_User("User", "Superadmin_Modify_UserInfo", msg.sender, users[msg.sender].Name, true);
        return true;
    }

    function modifyUserInfo(string memory _name, uint256 _stuNo, uint256 _grade, Identity _identity, address ModifiedUser) checkAdminAuthority() public returns (User memory){
        require(checkIfExist(msg.sender, allUsers), "already have this user Address");
        //要求我的账户已经创建，防止绕过前端直接在合约层调用该函数
        users[ModifiedUser].Name = _name;
        users[ModifiedUser].StuNo = _stuNo;
        users[ModifiedUser].Grade = _grade;
        users[ModifiedUser].NameNoHash = keccak256(abi.encode(_stuNo, _name));
        iLog.addLog_User("User", "admin_Modify_UserInfo", msg.sender, users[msg.sender].Name, true);
        return users[ModifiedUser];
    }
    //TODO:放弃或转移超级管理员的功能
    function TransferSuperAdmin(address Received) public returns (bool){
        require((msg.sender == superAdmin), "you aren't superadmin");
        //要求拥有超级管理员权限
        allAdmins[0] = Received;
        superAdmin = Received;
        iLog.addLog_User("User", "TransferSuperAdmin", msg.sender, users[msg.sender].Name, true);
        return true;
    }

    function GiveupSuperadmin() public returns (bool){
        require(msg.sender == superAdmin);
        superAdmin = address(0);
        allAdmins[0] = address(0);
        iLog.addLog_User("User", "GiveupSuperAdmin", msg.sender, users[msg.sender].Name, true);
        return true;
    }

    function modifyMyInfo(string memory _name, uint256 _stuNo, uint256 _grade, Identity _identity) public returns (User memory){
        require(checkIfExist(msg.sender, allUsers), "already have this user Address");
        //要求我的账户已经创建，防止绕过前端直接在合约层调用该函数
        users[msg.sender].Name = _name;
        users[msg.sender].StuNo = _stuNo;
        users[msg.sender].Grade = _grade;
        users[msg.sender].NameNoHash = keccak256(abi.encode(_stuNo, _name));
        iLog.addLog_User("User", "UserModifyHisInfo", msg.sender, users[msg.sender].Name, true);
        return users[msg.sender];
    }

    function initiateUser() updateAllUsers() public returns (User memory){
        require(!checkIfExist(msg.sender, allUsers), "already have this user Address");
        //用户不存在的话就创建并初始化
        User memory user = User(msg.sender, "", 0, 0, bytes32(0), Authority.notAdmin, Identity.guest);
        //直接初始化成非管理员权限
        users[msg.sender] = user;
        iLog.addLog_User("User", "initiateUser", msg.sender, users[msg.sender].Name, true);
        return user;
    }

    function initiateSuperAdmin() updateAllUsers() updateAllAdmins(msg.sender) private returns (User memory){
        User memory user = User(msg.sender, "SuperAdmin", 0, 0, bytes32(0), Authority.superAdmin, Identity.guest);
        users[msg.sender] = user;
        iLog.addLog_User("User", "initiateSuperAdmin", msg.sender, users[msg.sender].Name, true);
        return user;
    }

    function upUserToAdmin(address userAdrs) checkSuperAdminAuthority() updateAllAdmins(userAdrs) public returns (bool)
    {
        require(userAdrs != superAdmin, "superAdmin CANNOT abadon");
        users[userAdrs].authority = Authority.admin;
        iLog.addLog_User("User", "upUserToAdmin", msg.sender, users[msg.sender].Name, true);
        return true;
    }
    // function downAdminToUser(address userAdrs) checkSuperAdminAuthority() public{
    //     require(userAdrs!=superAdmin,"superAdmin CANNOT abadon");
    //     users[userAdrs].authority=Authority.notAdmin;
    // }
    //TODO:加入管理员权限验证
    //TODO:返回的应该是user数组
    function getAllUsers() checkAdminAuthority() public returns (User[] memory){
        User[] memory allUserInfo = new User[](allUsers.length);
        for (uint i = 0; i < allUsers.length; i++) {
            allUserInfo[i] = users[allUsers[i]];
        }
        iLog.addLog_User("User", "getAllAdmins", msg.sender, users[msg.sender].Name, true);
        return allUserInfo;
    }
    //TODO:只有超级管理员能查看 //TODO:返回的应该是user数组
    function getAllAdmins() checkSuperAdminAuthority() public returns (User[] memory){
        User[] memory AllAdminInfo = new User [](allAdmins.length);
        //全局变量可以动态，局部变量需要固定长度;全局变量与局部变量定义数据的方式有点不同
        for (uint i = 0; i < allAdmins.length; i++) {
            AllAdminInfo[i] = users[allAdmins[i]];
        }
        iLog.addLog_User("User", "SuperAdminGetAllAdmins", msg.sender, users[msg.sender].Name, true);
        return AllAdminInfo;
    }
    //TODO:加入管理员权限
    function getUserInfo(address userAdrs) checkAdminAuthority() public returns (User memory, bool){
        if (!checkIfExist(userAdrs, allUsers)) {
            return (users[userAdrs], false);
        } else {
            return (users[userAdrs], true);
        }
        iLog.addLog_User("User", "AdminGetUserInfo", msg.sender, users[msg.sender].Name, true);
    }

    function getMyInfo() public returns (User memory, bool){
        if (!checkIfExist(msg.sender, allUsers)) {
            iLog.addLog_User("User", "getMyInfo", msg.sender, users[msg.sender].Name, false);
            return (users[msg.sender], false);
        } else {
            iLog.addLog_User("User", "getMyInfo", msg.sender, users[msg.sender].Name, true);
            return (users[msg.sender], true);
        }
    }

    function checkIfExist(address adrs, address[] memory adrss) public returns (bool){
        for (uint i = 0; i < adrss.length; i++) {
            if (adrss[i] == adrs) {
                iLog.addLog_User("User", "getMyInfo", msg.sender, users[msg.sender].Name, true);
                return true;
            }
        }
        iLog.addLog_User("User", "upUserToAdmin", msg.sender, users[msg.sender].Name, false);
        return false;
    }
    //==============================string工具函数==============================
    function strConcat(string memory _a, string memory _b) internal returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}