/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.5.0;

// wallet contract
contract simpleDeposit {
    address owner;
    string name;
    uint amount;
    
    /**
     * Address 
     * value
     */    
    address[] depositAddress;
    uint[] depositValues;
    
    constructor(string memory _contractName) public {
        owner = msg.sender;
        name = _contractName;
    }
    
    function deposit() payable public{
        depositAddress.push(msg.sender);
        depositValues.push(msg.value);
        amount = amount + msg.value;
    }
    
    function depoistDetails(address _userAddress) public view returns(uint){
       uint total;
       for(uint index = 0;index < depositAddress.length;index++){
           if(depositAddress[index] == _userAddress){
               total = total+depositValues[index];
           }
       }
       return(total);
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
    }
    
    function withdraw(uint funds) public onlyOwner {
        require(funds <= amount);
        msg.sender.transfer(funds);
        updateBalance(funds);
    }
}