/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

pragma solidity 0.8.0;

contract Dbank{
    
    // state variables
    string bankName = "Decentralised Bank";             // default - empty string
    bool   isActive;                                    // default - false
    uint   contractBalance;                             // default - 0
    uint   amountTransacted;                            // default - 0
    uint8  feePercent = 2;
    
    struct User{
        uint8 age;
        address userAddress;
        string name;
    }
    User[] public users;
    
    address public owner;
    
    constructor () {
        owner = msg.sender;
    }
    
    // Contract Logic
    
    function registerUser(uint8 _age, address _accountAddress, string memory _name) public {
        User memory user = User(_age, _accountAddress, _name);
        users.push(user);
    }
    
    function functionArray() public pure returns(uint[5] memory) {
        uint[5] memory array;
        // array.push();
        // array.pop();
        //array[0] = 10;
        array[1] = 210;
        array[2] = 30;
        
        return array;
    }
    
    function getUser(uint index) public view returns(User memory) {
        return users[index];
    }
    
    function popUser() public {
        users.pop();
    }
    
    function usersCount() public view returns(uint){
        return users.length;
    }
    
    function remove(uint index) public {
        delete users[index];
    }
    
    function sendFunds(address payable _receiver) public payable {
        uint feeAmount = ((msg.value*100)*uint256(feePercent))/10000;
        uint transferableAmount = msg.value - feeAmount;
        contractBalance  += feeAmount;
        amountTransacted += transferableAmount;
        _receiver.transfer(transferableAmount);
    }
    
    function withdraw() public {
        uint transferableAmount = contractBalance;
        contractBalance -= contractBalance;
        payable(owner).transfer(transferableAmount);
    }
    
    function getContractBalance() public view returns(uint) {
        return contractBalance;
    }
    
    function getBalance(address _contract) public view returns(uint) {
        return _contract.balance;
    }
    
    function calculateFee(uint _value) public pure returns(uint) {
        return ((_value*100)*2)/10000;
    }
}