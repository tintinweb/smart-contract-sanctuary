/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

contract simpleDeposit {
    address owner;
    string name;
    uint amount;
    // uint index;
    
    address[] depositAddress;
    
    uint[] depositValues;

    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    mapping(address => uint) public depositDetails;
    
    function updateDeposit(address _sender, uint _value) internal {
        depositDetails[_sender] += _value;
    }
    
    function receiveDeposit() payable public {
        // depositAddress.push(msg.sender);
        // depositValues.push(msg.value);
        updateDeposit(msg.sender, msg.value);
        amount = amount + msg.value;
    }
    
    // function depositDetails(address _userAddress) public view returns(uint) {
    //     uint total;
    //     for (uint index = 0; index < depositAddress.length; index++) {
    //         if (depositAddress[index] == _userAddress) {
    //           total = total + depositValues[index]; 
    //         }
    //     }
    //     return (total);
    // }
    
    function checkBalance() public view returns(uint) {
        return amount;
    }
    
    function updateBalance(uint _wamount) internal {
        amount = amount - _wamount;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw(uint funds) public onlyOwner {
        // if(funds <= amount) {
        //     msg.sender.transfer(funds);
        //     updateBalance(funds);
        // }
        
        require(funds<=amount);
        msg.sender.transfer(funds);
        updateBalance(funds);
    }
}