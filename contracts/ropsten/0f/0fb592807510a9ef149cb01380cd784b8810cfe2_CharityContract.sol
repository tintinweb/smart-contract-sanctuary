pragma solidity 0.4.24;

contract CharityContract {
    // Read/write candidate
    address public admin;

    struct User {
        address userAddr;
        string userName;
        string userEmail;
    }

    mapping (address => User) public charityList;    

    mapping (address => uint256) public charityPoints;    

    //constant, not store in ethereum state
    uint256 maxValueDonate = 100000000000000000;
    

    event DonateETH(address indexed _userAddr, uint256 value);

    event Claim(uint256 value);
    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);

    // Constructor
    constructor () public {
        admin = msg.sender;
    }

    function donate() public payable{
        require(isUserExisted(msg.sender));
        require(msg.value + charityPoints[msg.sender] <= maxValueDonate);

        charityPoints[msg.sender] += msg.value;
        emit DonateETH(msg.sender, msg.value);
    }   

    function  claim() public payable{
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
        emit Claim(balance);
    }

    function addUser(address _userAddr,string _userName, string _userEmail) public{
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        charityList[_userAddr] = User(_userAddr,_userName, _userEmail);
        emit AddUser(_userAddr, _userName, _userEmail);
    }

    function removeUser(address _userAddr) public{
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        charityList[_userAddr] = User(0x0,"", "");
        emit RemoveUser(_userAddr);
    }

    function getUserInfo(address _userAddr) constant public returns (address, string, string) {
        User memory user = charityList[_userAddr];
        return (user.userAddr, user.userName, user.userEmail);
    }    

    function isUserExisted(address _userAddr) constant public returns (bool) {
        return  charityList[_userAddr].userAddr == _userAddr;
    }

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}