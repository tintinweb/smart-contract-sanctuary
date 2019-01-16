pragma solidity 0.4.24;

contract CharityContract{
    address public admin;
    struct User{
        address userAddr;
        string userName;
        string userEmail;
    }
    mapping (address => User) charityList;
    mapping (address => uint256) charityPoint;
    
    uint256 maxValueDonate = 10000000000000000;
    
    event AddUser(address indexed _userAddr, string _userName, string _userEmail);
    event RemoveUser(address indexed _userAddr);
    event DonateETH(address indexed _userAddr, uint256);
    
    constructor(){
        admin = msg.sender;
    }
    
    function transferAdmin(address _adminAddr) public{
        require(msg.sender == admin);
        admin = _adminAddr;
    }
    function addUser(address _userAddr, string _userName, string _userEmail) public{
        require(msg.sender == admin);
        charityList[_userAddr] = User(_userAddr, _userName, _userEmail);
        emit AddUser(_userAddr, _userName, _userEmail);
    }
    
    function removeUser(address _userAddr) public{
        require(msg.sender == admin);
        charityList[_userAddr] = User(0x0, "", "");
        emit RemoveUser(_userAddr);
    }
    
    function isUserExisted(address _userAddr) constant public returns (bool){
        return charityList[_userAddr].userAddr == _userAddr;
    }
    
    function donate() public{
        require(isUserExisted(msg.sender));
        require(msg.value + charityPoint[msg.sender] <= maxValueDonate);
        
        charityPoint[msg.sender] += msg.value;
        emit DonateETH(msg.sender, msg.value);
    }
    
    function claim() payable{
        require(msg.sender == admin);
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
}