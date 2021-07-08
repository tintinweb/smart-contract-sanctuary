/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

contract SimpleDepositContract {
    
    address owner;
    string name;
    uint amount;
    address[] depositAddress;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    
    
    function checkBalance() public view returns(uint) {
        return amount;
    }
    
    
    
    // mapping used to store key-value pairs
    mapping(address => uint) public depositDetails;
    
    function updateDeposit(address _sender, uint _depositAmount) internal {
        depositDetails[_sender] += _depositAmount;
    }
    
    function deposit() payable public {
        depositAddress.push(msg.sender);
        updateDeposit(msg.sender, msg.value);
        amount += msg.value;
    }
    
    
    
    // modifier to check if requestor is owner of contract
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function updateBalance(uint _amount) internal {
        amount -= _amount;
        for (uint i = 0; i < depositAddress.length; i++) {
            depositDetails[depositAddress[i]] = 0;
        }
    }
    
    // only owner of contract is allowed to withdraw funds
    function withdraw() public onlyOwner {
        msg.sender.transfer(amount);
        updateBalance(amount);
    }
    
}