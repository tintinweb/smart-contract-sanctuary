pragma solidity ^0.4.25;

/**
 * The purpose of this contract is to provide a mechanism to verify that a contract is valid
 */

contract SmartIdentityRegistry {

    address private owner;
    uint constant PENDING = 0;
    uint constant ACTIVE = 1;
    uint constant REJECTED = 2;

    /**
     * Constructor of the registry.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * The SIContract structure: every SIContract is composed of:
     * - Hash of contract bytecode
     * - Account that submitted the address
     * - Status - 0 = pending, 1 = active, 2 = rejected.
     */
    struct SIContract {
        bytes32 hash;
        address submitter;
        uint status;
    }

    /**
     * Mapping for contract registry.
     */
    mapping(bytes32 => SIContract) public sicontracts;

    /**
     * The only permission worth setting; doing the reverse is pointless as a contract
     * owner can interact with the contract as an anonymous third party simply by using
     * another public key address.
     */
    modifier onlyBy(address _account) {
        if (msg.sender != _account) {
            revert();
        }
        _;
    }

    /**
     * Anyone can submit a contract for acceptance into a registry.
     */
    function submitContract(bytes32 _contractHash) public returns(bool) {
        var sicontract = sicontracts[_contractHash];
        sicontract.hash = _contractHash;
        sicontract.submitter = msg.sender;
        sicontract.status = PENDING;
        return true;
    }

    /**
     * Only the registry owner (ideally multi-sig) can approve a contract.
     */
    function approveContract(bytes32 _contractHash) public onlyBy(owner) returns(bool) {
        var sicontract = sicontracts[_contractHash];
        sicontract.status = ACTIVE;
        return true;
    }

    /**
     * Only the registry owner (ideally multi-sig) can reject a contract.
     */
    function rejectContract(bytes32 _contractHash) public onlyBy(owner) returns(bool) {
        var sicontract = sicontracts[_contractHash];
        sicontract.status = REJECTED;
        return true;
    }

    /**
     * Only the registry owner and original submitter can delete a contract.
     * A contract in the rejected list cannot be removed.
     */
    function deleteContract(bytes32 _contractHash) public returns(bool) {
        var sicontract = sicontracts[_contractHash];
        if (sicontract.status != REJECTED) {
            if (sicontract.submitter == msg.sender) {
                if (msg.sender == owner) {
                    delete sicontracts[_contractHash];
                    return true;
                }
            }
        } else {
            revert();
        }
    }

    /**
     * This is the public registry function that contracts should use to check
     * whether a contract is valid. It&#39;s defined as a function, rather than .call
     * so that the registry owner can choose to charge based on their reputation
     * of managing good contracts in a registry.
     *
     * Using a function rather than a call also allows for better management of
     * dependencies when a chain forks, as the registry owner can choose to kill
     * the registry on the wrong fork to stop this function executing.
     */
    function isValidContract(bytes32 _contractHash) public view returns(bool) {
        if (sicontracts[_contractHash].status == ACTIVE) {
            return true;
        }
        if (sicontracts[_contractHash].status == REJECTED) {
            revert();
        } else {
            return false;
        }
    }

    /**
     * Kill function to end a registry (useful for hard forks).
     */
    function kill() public onlyBy(owner) returns(uint) {
        suicide(owner);
    }

    /***********************************************************************************************/
    // The purpose of this contract is to enable the following logic to be used in other contracts:

    /**
     * Check Identity is valid using modifier.
     *
     * This will also serve as protection against forks, because at the time the chain forks,
     * we can kill the registry, which will then &#39;invalidate&#39; the identities that are stored
     * on the old chain.
     */

    /**
     * modifier checkIdentity(address identity, address registry) return (bool) {
     *  if ( registry.isValidContract(identity) != 1 ) {
     *    revert();
     *    _;
     *  }
     * }
     */

    // We recommend using checkIdentity(0x23424234242242) on your contracts.

    /***********************************************************************************************/
}