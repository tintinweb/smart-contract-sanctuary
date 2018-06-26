pragma solidity ^0.4.24;
contract SimpleBank {

    /* Fill in the keyword. Hint: We want to protect our users balance from modification*/
    mapping (address => uint) private balances;

    /* Let&#39;s make sure everyone knows who owns the bank. Use the appropriate keyword for this*/
    address public owner;

    // Events - publicize actions to external listeners
    /* Add 2 arguments for this event, an accountAddress and an amount */
    event LogDepositMade(address accountAddress, uint amount);

    // Constructor, can receive one or many variables here; only one allowed
    constructor ()  public {
        /* Set the owner to the creator of this contract */
        owner = msg.sender;
    }

    /// @notice Enroll a customer with the bank, giving them 1000 tokens for free
    /// @return The balance of the user after enrolling
    function enroll() public returns (uint){
      /* Set the sender&#39;s balance to 1000, return the sender&#39;s balance */
      balances[msg.sender] = 1000;
      return balances[msg.sender];
    }

    /// @notice Deposit ether into bank
    /// @return The balance of the user after the deposit is made
    function deposit(uint amount) public returns (uint) {
        /* Add the amount to the user&#39;s balance, call the event associated with a deposit,
          then return the balance of the user */
          balances[msg.sender] += amount;
         emit  LogDepositMade(msg.sender, amount);
          return balances[msg.sender];
    }

    /// @notice Withdraw ether from bank
    /// @dev This does not return any excess ether sent to it
    /// @param withdrawAmount amount you want to withdraw
    /// @return The balance remaining for the user
    function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
        /* If the sender&#39;s balance is at least the amount they want to withdraw,
           Subtract the amount from the sender&#39;s balance, and try to send that amount of ether
           to the user attempting to withdraw. IF the send fails, add the amount back to the user&#39;s balance
           return the user&#39;s balance.*/

           if (balances[msg.sender] >= withdrawAmount) {
            balances[msg.sender] -= withdrawAmount;
            if (!msg.sender.send(withdrawAmount)) {
                balances[msg.sender] += withdrawAmount;
            }
           }

           return balances[msg.sender];
    }

    /// @notice Get balance
    /// @return The balance of the user
    // A SPECIAL KEYWORD prevents function from editing state variables;
    // allows function to run locally/off blockchain
    function balance() public constant returns (uint) {
        /* Get the balance of the sender of this transaction */
        return balances[msg.sender];
    }

    // Fallback function - Called if other functions don&#39;t match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender&#39;s money is transferred to contract
    function () private {
        revert();
    }
}