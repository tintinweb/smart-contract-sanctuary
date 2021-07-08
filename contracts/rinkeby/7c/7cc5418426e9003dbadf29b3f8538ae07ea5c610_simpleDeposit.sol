/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

contract simpleDeposit{
    address owner;
    string name;
    uint amount;
    
    // address[] depositAddress;
    // uint[] depositValues;
    
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
    
    function deposit() payable public {
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
    
    function checkBalance() public view returns(uint){
        return amount;
    }
    
    function withDraw(uint funds) public isOwner {
        if(funds <= amount){
            msg.sender.transfer(funds);
            updateBalance(funds);
        }
    }
    
    function updateBalance(uint _wamount) internal {
        amount = amount - _wamount;
    }
}