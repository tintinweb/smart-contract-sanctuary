/**
 *  Coffee
 *
 *  Just a very simple example of deploying a contract at a vanity address
 *  across several chains.
 *
 *  See: https://blog.ricmoo.com/contract-addresses-549074919ec8
 *
 */

pragma solidity ^0.4.20;

contract Coffee {

    address _owner;

    uint48 _mgCaffeine;
    uint48 _count;

    function Coffee() {
        _owner = msg.sender;
    }

    /**
     *   Allow the owner to change the account that controls this contract.
     *
     *   We may wish to use powerful computers that may be public or
     *   semi-public to compute the private key we use to deploy the contract,
     *   to a vanity adddress. So once deployed, we want to move it to a
     *   cold-storage key.
     */
    function setOwner(address owner) {
        require(msg.sender == _owner);
        _owner = owner;
    }

    /**
     *   status()
     *
     *   Returns the number of drinks and amount of caffeine this contract
     *   has been responsible for installing into the developer.
     */
    function status() public constant returns (uint48 count, uint48 mgCaffeine) {
        count = _count;
        mgCaffeine = _mgCaffeine;
    }

    /**
     *  withdraw(amount, count, mgCaffeine)
     *
     *  Withdraws funds from this contract to the owner, indicating how many drinks
     *  and how much caffeine these funds will be used to install into the develoepr.
     */
    function withdraw(uint256 amount, uint8 count, uint16 mgCaffeine) public {
        require(msg.sender == _owner);
        _owner.transfer(amount);
        _count += count;
        _mgCaffeine += mgCaffeine;
    }

    // Let this contract accept payments
    function () public payable { }
}