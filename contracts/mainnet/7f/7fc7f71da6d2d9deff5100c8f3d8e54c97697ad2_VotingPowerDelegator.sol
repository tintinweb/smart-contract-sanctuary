pragma solidity ^0.4.24;

// Delegate voting power for stake based voting and governance.
// Enables safe in-app voting participation, by letting users
// delegate their cold wallet VP to a convenient hot wallet.
contract VotingPowerDelegator {
    // delegator => beneficiary
    mapping (address => address) public delegations;
    mapping (address => uint)    public delegatedAt;
    event Delegated(address delegator, address beneficiary);

    constructor() public { }

    function delegate(address beneficiary) public {
        if (beneficiary == msg.sender) {
            beneficiary = 0;
        }
        delegations[msg.sender] = beneficiary;
        delegatedAt[msg.sender] = now;
        emit Delegated(msg.sender, beneficiary);
    }

    function () public payable {
        revert();
    }
}