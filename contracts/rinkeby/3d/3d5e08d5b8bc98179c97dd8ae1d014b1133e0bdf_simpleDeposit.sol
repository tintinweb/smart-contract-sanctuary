/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

// wallet contract
contract simpleDeposit {
    address owner;
    string name;
    uint amount;
    address[] depositAddress;
    
    struct userDetails {
        string userName;
        address userAddress;
    }
    
    userDetails ud;
    
    mapping(address => uint) public depositDetails;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    function updateDepost(address _sender,uint _value) internal {
        depositDetails[_sender] += _value;
    }
    
    function deposit(string memory _userName) payable public{
        ud.userName = _userName;
        ud.userAddress = msg.sender;
        depositAddress.push(msg.sender);
        updateDepost(msg.sender, msg.value);
        amount = amount + msg.value;
    }

    function checkBalance() public view returns(uint){
        return amount;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function updateBalance(uint _wamount) internal {
        amount = amount - _wamount;
        for(uint i = 0; i< depositAddress.length; i++){
            depositDetails[depositAddress[i]] = 0;
        }
    }

    function getuserDetails() public view returns(address, string memory){
        return(ud.userAddress, ud.userName);
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(amount);
        updateBalance(amount);
    }
}