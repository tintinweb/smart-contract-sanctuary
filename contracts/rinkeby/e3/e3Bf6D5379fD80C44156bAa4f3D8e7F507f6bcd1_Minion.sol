/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.8.0;

contract Minion{
    
    mapping(address => uint256) private contributionAmount;
    mapping(address => bool) private pwned;
    address public owner;
    uint256 private constant MINIMUM_CONTRIBUTION = (1 ether)/10;
    uint256 private constant MAXIMUM_CONTRIBUTION = (1 ether)/5;
    
    constructor(){
        owner = msg.sender;
    }

    function isContract(address account) internal view returns(bool){
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    
    function pwn() external payable{
        require(tx.origin != msg.sender, "Well we are not allowing EOAs, sorry");
        require(!isContract(msg.sender), "Well we don't allow Contracts either");
        require(msg.value >= MINIMUM_CONTRIBUTION, "Minimum Contribution needed is 0.1 ether");
        require(msg.value <= MAXIMUM_CONTRIBUTION, "How did you get so much money? Max allowed is 0.5 ether");
        require(block.timestamp % 120 >= 0 && block.timestamp % 120 < 60, "Not the right time");
        contributionAmount[msg.sender] += msg.value;
        
        if(contributionAmount[msg.sender] >= 1 ether){
            pwned[msg.sender] = true;
            
        }
    }
    
    function verify(address account) external view returns(bool){
     require(account != address(0), "You trynna trick me?");
     return pwned[account];
    }
    
    function retrieve() external{
        require(msg.sender == owner, "Are you the owner?");
        require(address(this).balance > 0, "No balance, you greedy hooman");
        payable(owner).transfer(address(this).balance);
    }

    function timeVal() external view returns(uint256){
        return block.timestamp;
    }
}