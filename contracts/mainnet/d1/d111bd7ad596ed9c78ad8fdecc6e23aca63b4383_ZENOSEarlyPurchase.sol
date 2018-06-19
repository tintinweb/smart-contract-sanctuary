pragma solidity ^0.4.7;

contract AbstractZENOSCrowdsale {
    function crowdsaleStartingBlock() constant returns (uint256 startingBlock) {}
}

/// @title EarlyPurchase contract - Keep track of purchased amount by Early Purchasers
/// Project by ZENOS Team (http://www.thezenos.com/)
/// This smart contract developed by Starbase - Token funding & payment Platform for innovative projects <support[at]starbase.co>

contract ZENOSEarlyPurchase {
    /*
     *  Properties
     */
    string public constant PURCHASE_AMOUNT_UNIT = &#39;ETH&#39;;    // Ether
    address public owner;
    EarlyPurchase[] public earlyPurchases;
    uint public earlyPurchaseClosedAt;

    /*
     *  Types
     */
    struct EarlyPurchase {
        address purchaser;
        uint amount;        // Amount in Wei( = 1/ 10^18 Ether)
        uint purchasedAt;   // timestamp
    }

    /*
     *  External contracts
     */
    AbstractZENOSCrowdsale public zenOSCrowdsale;


    /*
     *  Modifiers
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    modifier onlyBeforeCrowdsale() {
        if (address(zenOSCrowdsale) != 0 &&
            zenOSCrowdsale.crowdsaleStartingBlock() > 0)
        {
            throw;
        }
        _;
    }

    modifier onlyEarlyPurchaseTerm() {
        if (earlyPurchaseClosedAt > 0) {
            throw;
        }
        _;
    }

    /// @dev Contract constructor function
    function ZENOSEarlyPurchase() {
        owner = msg.sender;
    }

    /*
     *  Contract functions
     */
    /// @dev Returns early purchased amount by purchaser&#39;s address
    /// @param purchaser Purchaser address
    function purchasedAmountBy(address purchaser)
        external
        constant
        returns (uint amount)
    {
        for (uint i; i < earlyPurchases.length; i++) {
            if (earlyPurchases[i].purchaser == purchaser) {
                amount += earlyPurchases[i].amount;
            }
        }
    }

    /// @dev Returns total amount of raised funds by Early Purchasers
    function totalAmountOfEarlyPurchases()
        constant
        returns (uint totalAmount)
    {
        for (uint i; i < earlyPurchases.length; i++) {
            totalAmount += earlyPurchases[i].amount;
        }
    }

    /// @dev Returns number of early purchases
    function numberOfEarlyPurchases()
        external
        constant
        returns (uint)
    {
        return earlyPurchases.length;
    }

    /// @dev Append an early purchase log
    /// @param purchaser Purchaser address
    /// @param amount Purchase amount
    /// @param purchasedAt Timestamp of purchased date
    function appendEarlyPurchase(address purchaser, uint amount, uint purchasedAt)
        internal
        onlyBeforeCrowdsale
        onlyEarlyPurchaseTerm
        returns (bool)
    {

        if (purchasedAt == 0 || purchasedAt > now) {
            throw;
        }

        earlyPurchases.push(EarlyPurchase(purchaser, amount, purchasedAt));
        return true;
    }

    /// @dev Close early purchase term
    function closeEarlyPurchase()
        external
        onlyOwner
        returns (bool)
    {
        earlyPurchaseClosedAt = now;
    }

    /// @dev Setup function sets external crowdsale contract&#39;s address
    /// @param zenOSCrowdsaleAddress Token address
    function setup(address zenOSCrowdsaleAddress)
        external
        onlyOwner
        returns (bool)
    {
        if (address(zenOSCrowdsale) == 0) {
            zenOSCrowdsale = AbstractZENOSCrowdsale(zenOSCrowdsaleAddress);
            return true;
        }
        return false;
    }

    function withdraw(uint withdrawalAmount) onlyOwner {
          if(!owner.send(withdrawalAmount)) throw;  // send collected ETH to ZENOS team
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

    /// @dev By sending Ether to the contract, early purchase will be recorded.
    function () payable {
        appendEarlyPurchase(msg.sender, msg.value, block.timestamp);
    }
}