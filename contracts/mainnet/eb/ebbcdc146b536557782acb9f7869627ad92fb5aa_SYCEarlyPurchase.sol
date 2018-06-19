pragma solidity ^0.4.7;

contract AbstractSYCCrowdsale {
}

/// @title EarlyPurchase contract - Keep track of purchased amount by Early Purchasers
/// Project by SynchroLife Team (https://synchrolife.org)
/// This smart contract developed by Starbase - Token funding & payment Platform for innovative projects <support[at]starbase.co>

contract SYCEarlyPurchase {
    /*
     *  Properties
     */
    string public constant PURCHASE_AMOUNT_UNIT = &#39;ETH&#39;;    // Ether
    uint public constant WEI_MINIMUM_PURCHASE = 1 * 10 ** 18;
    uint public constant WEI_MAXIMUM_EARLYPURCHASE = 2 * 10 ** 18;
    address public owner;
    EarlyPurchase[] public earlyPurchases;
    uint public earlyPurchaseClosedAt;
    uint public totalEarlyPurchaseRaised;

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
    AbstractSYCCrowdsale public sycCrowdsale;


    /*
     *  Modifiers
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
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
    function SYCEarlyPurchase() {
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
        onlyEarlyPurchaseTerm
        returns (bool)
    {
        if (purchasedAt == 0 || purchasedAt > now) {
            throw;
        }

        if (purchasedAt == 0 || purchasedAt > now) {
            throw;
        }

        if(totalEarlyPurchaseRaised + amount >= WEI_MAXIMUM_EARLYPURCHASE){
           purchaser.send(totalEarlyPurchaseRaised + amount - WEI_MAXIMUM_EARLYPURCHASE);
           earlyPurchases.push(EarlyPurchase(purchaser, WEI_MAXIMUM_EARLYPURCHASE - totalEarlyPurchaseRaised, purchasedAt));
           totalEarlyPurchaseRaised += WEI_MAXIMUM_EARLYPURCHASE - totalEarlyPurchaseRaised;
        }
        else{
           earlyPurchases.push(EarlyPurchase(purchaser, amount, purchasedAt));
           totalEarlyPurchaseRaised += amount;
        }

        if(totalEarlyPurchaseRaised >= WEI_MAXIMUM_EARLYPURCHASE){
            closeEarlyPurchase();
        }
        return true;
    }

    /// @dev Close early purchase term
    function closeEarlyPurchase()
        onlyOwner
        returns (bool)
    {
        earlyPurchaseClosedAt = now;
    }

    /// @dev Setup function sets external crowdsale contract&#39;s address
    /// @param sycCrowdsaleAddress Token address
    function setup(address sycCrowdsaleAddress)
        external
        onlyOwner
        returns (bool)
    {
        if (address(sycCrowdsale) == 0) {
            sycCrowdsale = AbstractSYCCrowdsale(sycCrowdsaleAddress);
            return true;
        }
        return false;
    }

    function withdraw(uint withdrawalAmount) onlyOwner {
          if(!owner.send(withdrawalAmount)) throw;  // send collected ETH to SynchroLife team
    }

    function withdrawAll() onlyOwner {
          if(!owner.send(this.balance)) throw;  // send all collected ETH to SynchroLife team
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

    /// @dev By sending Ether to the contract, early purchase will be recorded.
    function () payable{
        require(msg.value >= WEI_MINIMUM_PURCHASE);
        appendEarlyPurchase(msg.sender, msg.value, block.timestamp);
    }
}