pragma solidity ^0.4.24;

/*
    Two roles: depositHolder, depositSubmitter
    depositHolder:
        Can choose to either confiscate or return the amount deposited.
        Must specify the DepositSubmitter upon construction.
    depositSubmitter:
        Puts some ether in, and otherwise has no control over the contract.
*/

contract DepositManager {
    address public depositHolder;
    address public depositSubmitter;
    
    event EtherDeposited(uint amount);
    event EtherReturned(uint amount);
    event EtherConfiscated(uint amount);
    
    // constructor will set depositHolder as msg.sender, and takes
    // as an argument the intended depositSubmitter
    constructor(address _depositSubmitter) public {
        depositHolder = msg.sender;
        
        depositSubmitter = _depositSubmitter;
    }
    
    function deposit() external payable {
        require(msg.sender == depositSubmitter);
        
        emit EtherDeposited(msg.value);
    }
    
    function returnDeposit() external {
        require(msg.sender == depositHolder);
        
        uint totalBalance = address(this).balance;
        depositSubmitter.transfer(totalBalance);
        
        emit EtherReturned(totalBalance);
    }
    
    function confiscateDeposit() external {
        require(msg.sender == depositHolder);
        
        uint totalBalance = address(this).balance;
        depositHolder.transfer(totalBalance);
        
        emit EtherConfiscated(totalBalance);
    }
}