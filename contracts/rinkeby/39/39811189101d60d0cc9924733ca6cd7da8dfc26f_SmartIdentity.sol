/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity ^0.4.0;

/**
 * The contract is a Smart ID, and all derived 'Smart IDs' should match the bytecode
 * of a known 'good SmartIdentity' version. See the 'SmartIdentityRegistry' contract
 * for a mechanism for verifying valid SmartIdentities.
 */

contract SmartIdentity {

    address private owner;
    address private override;
    uint private blocklock;
    string public encryptionPublicKey;
    string public signingPublicKey;

    uint constant BLOCK_HEIGHT = 20;
    uint constant ERROR_EVENT = 1;
    uint constant WARNING_EVENT = 2;
    uint constant SIG_CHANGE_EVENT = 3;
    uint constant INFO_EVENT = 4;
    uint constant DEBUG_EVENT = 5;

    mapping(bytes32 => Attribute) public attributes;

    /**
     * Constructor of the Smart Identity
     */
    function SmartIdentity() {
        owner = msg.sender;
        override = owner;
        blocklock = block.number - BLOCK_HEIGHT;
    }

    /**
     * Modifier to place a constraint on the user calling a function
     */
    modifier onlyBy(address _account) {
        if (msg.sender != _account) {
            revert();
        }
        _;
    }

    /**
     * Modifier to prevent change if the block height is too low.
     * This has been set at 20 for testing purposes, and should
     * be made longer to better protect the contract from significant
     * ownership changes.
     */
    modifier checkBlockLock() {
        if (blocklock + BLOCK_HEIGHT > block.number) {
            revert();
        }
        _;
    }

    /**
     * Modifier to set the blocklock.
     */
    modifier blockLock() {
        blocklock = block.number;
        _;
    }

    /**
     * The attribute structure: every attribute is composed of:
     * - Attribute hash
     * - Endorsements
     */
    struct Attribute {
        bytes32 hash;
        mapping(bytes32 => Endorsement) endorsements;
    }

    /**
     * The endorsement structure: every endorsement is composed of:
     * - Endorser address
     * - Endorsement hash
     * - Accepted Status - true if the user has accepted the endorsement
     */
    struct Endorsement {
        address endorser;
        bytes32 hash;
        bool accepted;
    }

    /**
     * This event is used for standard change notification messages and outputs the following:
     * - owner of the contract
     * - event status level
     * - event message body
     */
    event ChangeNotification(address indexed sender, uint status, bytes32 notificationMsg);

    /**
     * This function is used to send events.
     * Status Level Scale:
     *  1   Error: error conditions
     *  2   Warning: warning conditions
     *  3   Significant Change: Significant change to condition
     *  4   Informational: informational messages
     *  5   Verbose: debug-level messages
     */
    function sendEvent(uint _status, bytes32 _notification) internal returns(bool) {
        ChangeNotification(owner, _status, _notification);
        return true;
    }

    /**
     * This function gives the override address the ability to change owner.
     * This could allow the identity to be moved to a multi-sig contract.
     * See https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol
     * for a multi-sig wallet example.
     */
    function setOwner(address _newowner) onlyBy(override) checkBlockLock() blockLock() returns(bool) {
        owner = _newowner;
        sendEvent(SIG_CHANGE_EVENT, "Owner has been changed");
        return true;
    }

    /**
     * Cosmetic function for the override account holder to check that their
     * permissions on the contract have been set correctly.
     */
    function getOwner() onlyBy(override) returns(address) {
        return owner;
    }

    /**
     * The override address is another ethereum address that can reset the owner.
     * In practice this could either be another multi-sig account, or another
     * smart contract that this control could be delegated to.
     */
    function setOverride(address _override) onlyBy(owner) checkBlockLock() blockLock() returns(bool) {
        override = _override;
        sendEvent(SIG_CHANGE_EVENT, "Override has been changed");
        return true;
    }

    /**
     * This function removes the override by the owner - if trust between the identity
     * holder and the new account ends.
     */
    function removeOverride() onlyBy(owner) checkBlockLock() blockLock() returns(bool) {
        override = owner;
        sendEvent(SIG_CHANGE_EVENT, "Override has been removed");
        return true;
    }

    /**
     * Adds an attribute, with an empty list of endorsements.
     */
    function addAttribute(bytes32 _hash) onlyBy(owner) checkBlockLock() returns(bool) {
        var attribute = attributes[_hash];
        if (attribute.hash == _hash) {
            sendEvent(SIG_CHANGE_EVENT, "A hash exists for the attribute");
            revert();
        }
        attribute.hash = _hash;
        sendEvent(INFO_EVENT, "Attribute has been added");
        return true;
    }

    /**
     * This updates an attribute by removing the old one first, and then
     * adding the new one. The event log should hold the record of the
     * transaction so at a future date it should be possible to traverse
     * the history of an attribute against the blockchain.
     */
    function updateAttribute(bytes32 _oldhash, bytes32 _newhash) onlyBy(owner) checkBlockLock() returns(bool) {
        sendEvent(DEBUG_EVENT, "Attempting to update attribute");
        removeAttribute(_oldhash);
        addAttribute(_newhash);
        sendEvent(SIG_CHANGE_EVENT, "Attribute has been updated");
        return true;
    }

    /**
     * Removes an attribute from a contract.
     */
    function removeAttribute(bytes32 _hash) onlyBy(owner) checkBlockLock() returns(bool) {
        var attribute = attributes[_hash];
        if (attribute.hash != _hash) {
            sendEvent(WARNING_EVENT, "Hash not found for attribute");
            revert();
        }
        delete attributes[_hash];
        sendEvent(SIG_CHANGE_EVENT, "Attribute has been removed");
        return true;
    }

    /**
     * Adds an endorsement to an attribute; must provide a valid attributeHash.
     * See the docs for off-chain transfer of the encrypted endorsement information.
     */
    function addEndorsement(bytes32 _attributeHash, bytes32 _endorsementHash) returns(bool) {
        var attribute = attributes[_attributeHash];
        if (attribute.hash != _attributeHash) {
            sendEvent(ERROR_EVENT, "Attribute doesn't exist");
            revert();
        }
        var endorsement = attribute.endorsements[_endorsementHash];
        if (endorsement.hash == _endorsementHash) {
            sendEvent(ERROR_EVENT, "Endorsement already exists");
            revert();
        }
        endorsement.hash = _endorsementHash;
        endorsement.endorser = msg.sender;
        endorsement.accepted = false;
        sendEvent(INFO_EVENT, "Endorsement has been added");
        return true;
    }

    /**
     * Owner can mark an endorsement as accepted.
     */
    function acceptEndorsement(bytes32 _attributeHash, bytes32 _endorsementHash) onlyBy(owner) returns(bool) {
        var attribute = attributes[_attributeHash];
        var endorsement = attribute.endorsements[_endorsementHash];
        endorsement.accepted = true;
        sendEvent(SIG_CHANGE_EVENT, "Endorsement has been accepted");
    }

    /**
     * Checks that an endorsement _endorsementHash exists for the attribute _attributeHash.
     */
    function checkEndorsementExists(bytes32 _attributeHash, bytes32 _endorsementHash) returns(bool) {
        var attribute = attributes[_attributeHash];
        if (attribute.hash != _attributeHash) {
            sendEvent(ERROR_EVENT, "Attribute doesn't exist");
            return false;
        }
        var endorsement = attribute.endorsements[_endorsementHash];
        if (endorsement.hash != _endorsementHash) {
            sendEvent(ERROR_EVENT, "Endorsement doesn't exist");
            return false;
        }
        if (endorsement.accepted == true) {
            sendEvent(INFO_EVENT, "Endorsement exists for attribute");
            return true;
        } else {
            sendEvent(ERROR_EVENT, "Endorsement hasn't been accepted");
            return false;
        }
    }

    /**
     * Allows only the person who gave the endorsement the ability to remove it.
     */
    function removeEndorsement(bytes32 _attributeHash, bytes32 _endorsementHash) returns(bool) {
        var attribute = attributes[_attributeHash];
        var endorsement = attribute.endorsements[_endorsementHash];
        if (msg.sender == endorsement.endorser) {
            delete attribute.endorsements[_endorsementHash];
            sendEvent(SIG_CHANGE_EVENT, "Endorsement removed");
            return true;
        }
        if (msg.sender == owner && endorsement.accepted == false) {
            delete attribute.endorsements[_endorsementHash];
            sendEvent(SIG_CHANGE_EVENT, "Endorsement denied");
            return true;
        }
        sendEvent(SIG_CHANGE_EVENT, "Endorsement removal failed");
        revert();
    }

    /**
     * Allows only the account owner to create or update encryptionPublicKey.
     * Only 1 encryptionPublicKey is allowed per account, therefore use same set
     * method for both create and update.
     */
    function setEncryptionPublicKey(string _myEncryptionPublicKey) onlyBy(owner) checkBlockLock() returns(bool) {
        encryptionPublicKey = _myEncryptionPublicKey;
        sendEvent(SIG_CHANGE_EVENT, "Encryption key added");
        return true;
    }

    /**
     * Allows only the account owner to create or update signingPublicKey.
     * Only 1 signingPublicKey allowed per account, therefore use same set method
     * for both create and update.
     */
    function setSigningPublicKey(string _mySigningPublicKey) onlyBy(owner) checkBlockLock() returns(bool) {
        signingPublicKey = _mySigningPublicKey;
        sendEvent(SIG_CHANGE_EVENT, "Signing key added");
        return true;
    }

    /**
     * Kills the contract and prevents further actions on it.
     */
    function kill() onlyBy(owner) returns(uint) {
        suicide(owner);
        sendEvent(WARNING_EVENT, "Contract killed");
    }
}