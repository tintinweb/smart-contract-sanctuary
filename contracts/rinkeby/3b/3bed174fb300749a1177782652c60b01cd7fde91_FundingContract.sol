/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity 0.7.6;
contract FundingContract {
    
    address owner; 
    address[] public contributers;
    mapping(address => uint) public contributerAmount;
    uint public minimumContribution;
    uint public fundingGoal;
    
    constructor(uint _minimumContribution, uint _fundingGoal) public {
        owner = msg.sender;
        minimumContribution = _minimumContribution;
        fundingGoal = _fundingGoal;
    }
    
    function getContributionBalance() external view returns(uint) {
        return (address(this)).balance;
    }
    
    function contribute() external payable {
        
        uint currentBalance = this.getContributionBalance();
  
        require(msg.value >= minimumContribution);
        
        contributers.push(msg.sender);
        contributerAmount[msg.sender] = msg.value;
        
        if(currentBalance >= fundingGoal) {
            address(uint160(owner)).transfer(this.getContributionBalance());
        }
    }
}