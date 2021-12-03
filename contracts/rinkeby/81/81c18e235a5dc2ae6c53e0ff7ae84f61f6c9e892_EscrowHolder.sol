/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.8.7;


contract EscrowHolder {
    address public user_A;
    address public user_B;
    uint public amount;
    bool public isTaskComplete = false;

    modifier shoulBeSentBy(address _required_initiator) {
        require(_required_initiator == msg.sender, "You are not authorized to perform this action");
        _;
    }

    function initiate(address _recipient, uint _amount) external payable {
        require(_amount == msg.value, "Amount is not equal to the supplied balance");

        user_A = msg.sender;
        user_B = _recipient;
        amount = _amount;
    }

    function reportCompletion() external shoulBeSentBy(user_B) {
        isTaskComplete = true;
    }

    function approveFunding() external shoulBeSentBy(user_A)  {
        require(isTaskComplete == true, "Task hasn't been reported as complete by recipient");
        isTaskComplete = false;
        payable(user_B).transfer(amount);
    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

}