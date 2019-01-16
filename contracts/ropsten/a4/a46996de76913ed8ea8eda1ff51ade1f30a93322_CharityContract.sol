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
    
    uint256 maxCap = 100000000000000000;
    
    event AddUser(address indexed _userAddress, string _userName, string _userEmail);
    event Donate(address indexed _userAddress, uint256 _value);
    
    constructor(){
        admin = msg.sender;
        // msg.value
        // msg.blockNumber
        // msg.gasPrice 
    }
    
    function transferAdmin(address _adminAddr) public {
        require(msg.sender == admin);
        admin = _adminAddr;
        //require, assert
    }
    
    function addUser(address _userAddress, string _userName, string _userEmail){
        require(msg.sender == admin);
        charityList[_userAddress] = User(_userAddress, _userName, _userEmail);
        emit AddUser(_userAddress, _userName, _userEmail);
    }
    
    function isUserKyced(address _userAddress) constant public returns(bool){
        return charityList[_userAddress].userAddr == _userAddress;
        // 0x0, "", 0, default value 
        //optimatize
    }
    
    function removeUser(address _userAddres){
        require(msg.sender == admin);
        charityList[_userAddres] = User(0x0,"","");
    }
    
    function donate() public{
        require(isUserKyced(msg.sender));
        require(charityPoint[msg.sender] + msg.value < maxCap);
        
        charityPoint[msg.sender] += msg.value;
        emit Donate(msg.sender, msg.value);
    }
    
    function claim() public payable{
        require(msg.sender == admin);
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
}