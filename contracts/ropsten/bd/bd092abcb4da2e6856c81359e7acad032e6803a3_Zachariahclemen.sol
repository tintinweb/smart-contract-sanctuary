/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.8.4;

contract Zachariahclemen
{
    mapping(uint256 => mapping(address => uint256)) public tryToAddressToBalance;
    mapping(uint256 => uint256) public tryToEndDate;
    mapping(uint256 => uint256) public tryToBalance;
    mapping(uint256 => bool) public tryToGoalReached;
    uint256 public currentTry;
    
    address owner;
    address payable receiver;
    
    constructor(address payable _receiver, uint256 _endDate)
    {
        require(block.timestamp + _endDate > block.timestamp, "End date is in the past");
        
        owner = msg.sender;
        receiver = _receiver;
        
        tryToEndDate[currentTry] = block.timestamp + _endDate;
    }
    
    receive() payable external
    {
        require(tryToEndDate[currentTry] > block.timestamp, "Try is done");
        require(!tryToGoalReached[currentTry], "Goal is already reached");
        
        tryToAddressToBalance[currentTry][msg.sender] += msg.value;
        tryToBalance[currentTry] += msg.value;
        
        if(tryToBalance[currentTry] >= 2 ether)
        {
            receiver.transfer(tryToBalance[currentTry]);
            tryToGoalReached[currentTry] = true;
        }
    }
    
    function withdraw(uint256 _try) external
    {
        require(block.timestamp > tryToEndDate[_try], "Try is not finished yet");
        require(!tryToGoalReached[_try], "Try is finished");
        
        payable(msg.sender).transfer(tryToAddressToBalance[_try][msg.sender]);
    }
    
    function refresh(uint256 _endDate) external
    {
        require(block.timestamp > tryToEndDate[currentTry], "Previous try not done yet");
        require(msg.sender == owner);
        
        currentTry += 1;
        tryToEndDate[currentTry] = block.timestamp + _endDate;
    }
}