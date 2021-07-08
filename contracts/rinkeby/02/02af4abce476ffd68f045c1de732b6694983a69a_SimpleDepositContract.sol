/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

contract SimpleDepositContract {
    
    address owner;
    string name;
    uint amount;
    
    // address[] depositAddress;
    // uint[] depositValues;
    
    
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    
    
    // mapping used to store key-value pairs
    mapping(address => uint) public depositDetails;
    
    function updateDeposit(address _sender, uint _depositAmount) internal {
        depositDetails[_sender] += _depositAmount;
    }
    
    function deposit() payable public {
        // depositAddress.push(msg.sender);
        // depositValues.push(msg.value);
        updateDeposit(msg.sender, msg.value);
        amount += msg.value;
    }
    
    // function depositDetails(address _userAddress) public view returns(uint) {
    //     uint total;
        
    //     for (uint i = 0; i < depositAddress.length; i++) {
    //         if (depositAddress[i] == _userAddress) {
    //             total += depositValues[i];
    //         }
    //     }
    //     return total;
    // }
    
    
    
    function checkBalance() public view returns(uint) {
        return amount;
    }
    
    
    
    // modifier to check if requestor is owner of contract
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function updateBalance(uint _amount) internal {
        amount -= _amount;
    }
    
    // only owner of contract is allowed to withdraw funds
    function withdraw(uint funds) public onlyOwner {
        require(funds <= amount);
        msg.sender.transfer(funds);
        updateBalance(funds);
    }
    
}