pragma solidity ^0.4.11;

/// @title Splitter
/// @author 0xcaff (Martin Charles)
/// @notice An ethereum smart contract to split received funds between a number
/// of outputs.
contract Splitter {
    // Mapping between addresses and how much money they have withdrawn. This is
    // used to calculate the balance of each account. The public keyword allows
    // reading from the map but not writing to the map using the
    // amountsWithdrew(address) method of the contract. It&#39;s public mainly for
    // testing.
    mapping(address => uint) public amountsWithdrew;

    // A set of parties to split the funds between. They are initialized in the
    // constructor.
    mapping(address => bool) public between;

    // The number of ways incoming funds will we split.
    uint public count;

    // The total amount of funds which has been deposited into the contract.
    uint public totalInput;

    // This is the constructor of the contract. It is called at deploy time.

    /// @param addrs The address received funds will be split between.
    function Splitter(address[] addrs) {
        count = addrs.length;

        for (uint i = 0; i < addrs.length; i++) {
            // loop over addrs and update set of included accounts
            address included = addrs[i];
            between[included] = true;
        }
    }

    // To save on transaction fees, it&#39;s beneficial to withdraw in one big
    // transaction instead of many little ones. That&#39;s why a withdrawl flow is
    // being used.

    /// @notice Withdraws from the sender&#39;s share of funds and deposits into the
    /// sender&#39;s account. If there are insufficient funds in the contract, or
    /// more than the share is being withdrawn, throws, canceling the
    /// transaction.
    /// @param amount The amount of funds in wei to withdraw from the contract.
    function withdraw(uint amount) {
        Splitter.withdrawInternal(amount, false);
    }

    /// @notice Withdraws all funds available to the sender and deposits them
    /// into the sender&#39;s account.
    function withdrawAll() {
        Splitter.withdrawInternal(0, true);
    }

    // Since `withdrawInternal` is internal, it isn&#39;t in the ABI and can&#39;t be
    // called from outside of the contract.

    /// @notice Checks whether the sender is allowed to withdraw and has
    /// sufficient funds, then withdraws.
    /// @param requested The amount of funds in wei to withdraw from the
    /// contract. If the `all` parameter is true, the `amount` parameter is
    /// ignored. If funds are insufficient, throws.
    /// @param all If true, withdraws all funds the sender has access to from
    /// this contract.
    function withdrawInternal(uint requested, bool all) internal {
        // Require the withdrawer to be included in `between` at contract
        // creation time.
        require(between[msg.sender]);

        // Decide the amount to withdraw based on the `all` parameter.
        uint available = Splitter.balance();
        uint transferring = 0;

        if (all) { transferring = available; }
        else { available = requested; }

        // Ensures the funds are available to make the transfer, otherwise
        // throws.
        require(transferring <= available);

        // Updates the internal state, this is done before the transfer to
        // prevent re-entrancy bugs.
        amountsWithdrew[msg.sender] += transferring;

        // Transfer funds from the contract to the sender. The gas for this
        // transaction is paid for by msg.sender.
        msg.sender.transfer(transferring);
    }

    // We do integer division (floor(a / b)) when calculating each share, because
    // solidity doesn&#39;t have a decimal number type. This means there will be a
    // maximum remainder of count - 1 wei locked in the contract. We ignore this
    // because it is such a small amount of ethereum (1 Wei = 10^(-18)
    // Ethereum). The extra Wei can be extracted by depositing an amount to make
    // totalInput evenly divisable between count parties.

    /// @notice Gets the amount of funds in Wei available to the sender.
    function balance() constant returns (uint) {
        if (!between[msg.sender]) {
            // The sender of the message isn&#39;t part of the split. Ignore them.
            return 0;
        }

        // `share` is the amount of funds which are available to each of the
        // accounts specified in the constructor.
        uint share = totalInput / count;
        uint withdrew = amountsWithdrew[msg.sender];
        uint available = share - withdrew;

        assert(available >= 0 && available <= share);

        return available;
    }

    // This function will be run when a transaction is sent to the contract
    // without any data. It is minimal to save on gas costs.
    function() payable {
        totalInput += msg.value;
    }
}