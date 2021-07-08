/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

contract simpleDeposit{
    address owner;
    string name;
    uint amount;
    address[] depositAddress;
    
    struct userDetails {
        string userName;
        address userAddress;
    }
    
    userDetails userdetails;
    
    //mapping is used to store key value pairs
    mapping(address => uint) public depositDetails;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function updateDeposit(address _sender, uint _value) internal {
        depositDetails[_sender] += _value;
    }
    
    function deposit(string memory _userName) payable public {
        userdetails.userName = _userName;
        userdetails.userAddress = msg.sender;
        depositAddress.push(msg.sender);
        updateDeposit(msg.sender, msg.value);
        amount = amount + msg.value;
    }   
    
    function checkBalance() public view returns(uint){
        return amount;
    }
    
    function withDraw() public isOwner {
        msg.sender.transfer(amount);
        updateBalance(amount);
    }
    
    function updateBalance(uint _wamount) internal {
        amount = amount - _wamount;
        for(uint i = 0; i < depositAddress.length; i++){
            depositDetails[depositAddress[i]] = 0;
        }
    }
    
    function getuserDetails() public view returns(address, string memory){
        return (userdetails.userAddress, userdetails.userName);
    }
    
}