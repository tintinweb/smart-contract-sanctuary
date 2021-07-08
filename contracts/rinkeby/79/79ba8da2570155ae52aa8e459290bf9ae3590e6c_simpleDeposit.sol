/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

contract simpleDeposit {
    address owner;
    string name;
    uint amount;

    address[] depositAddress;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    mapping(address => uint) public depositDetails;
    
    function updateDeposit(address _sender, uint _value) internal {
        depositDetails[_sender] += _value;
    }
    
    function receiveDeposit() payable public {
        updateDeposit(msg.sender, msg.value);
        amount = amount + msg.value;
    }
    
    function checkBalance() public view returns(uint) {
        return amount;
    }
    
    function updateBalance(uint _wamount) internal {
        amount = amount - _wamount;
        for (uint i = 0; i < depositAddress.length; i++) {
            depositDetails[depositAddress[i]] = 0;
        }
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() public onlyOwner {
        // if(funds <= amount) {
        //     msg.sender.transfer(funds);
        //     updateBalance(funds);
        // }
        
        // require(funds<=amount);
        msg.sender.transfer(amount);
        updateBalance(amount);
    }
}