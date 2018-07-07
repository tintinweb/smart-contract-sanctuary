pragma solidity ^0.4.18;

contract BalanceOnlyOwner {

    

    /**

     * Contract data.

     */

    uint256 private balance = 0;

    address private owner;

    

    /**

     * modifier to check onlyOwner.

     */

    modifier onlyOwner {

        require (msg.sender == owner);

        _;

    }

    

    /** 

     * Constructor

     */

    function BalanceOnlyOwner() public {

        owner = msg.sender;

    }

    

    /**

     * Function to deposit some amount. Allowed for

     * every account.

     */

    function deposit(uint256 amount) public {

        balance += amount;

    }

    

    /**

     * Function to withdraw the amound. Allowed for

     * only owner.

     */

    function withdraw(uint256 amount) public onlyOwner {

        require(balance <= amount);

        balance -= amount;

    }

    

    /**

     * Return the accumulated balance.

     */

    function getBalance() public constant returns (uint256) {

        return balance;

    }

}