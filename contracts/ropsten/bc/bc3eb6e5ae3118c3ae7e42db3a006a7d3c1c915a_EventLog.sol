pragma solidity ^0.4.24;

contract EventLog {
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
        );
        
    function () payable public {
        address sender = msg.sender;
        sender.transfer(msg.value);
        emit TokenPurchase(msg.sender, msg.sender, msg.value, msg.value * 1000);
    }
}