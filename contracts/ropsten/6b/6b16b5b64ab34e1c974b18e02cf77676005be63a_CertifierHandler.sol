pragma solidity ^0.4.24;

contract MultiCertifier {
    function certified(address _who) public view returns(bool);

    function getCertifier(address _who) public view returns(address);
}

contract Owned {
    modifier only_owner {
        require(msg.sender == owner);
        _;
    }

    event NewOwner(address indexed old, address indexed current);

    function setOwner(address _new) public only_owner {
        emit NewOwner(owner, _new);
        owner = _new;
    }

    address public owner = msg.sender;
}

contract CertifierHandler is Owned {
    /// STORAGE

    // The address of the MultiCertifier,
    // set on creation, constant
    MultiCertifier public certifier;

    // A mapping of the pending requests for
    // modification of the certified address
    mapping(address => address) public pending;

    // A mapping of addresses that should not
    // be able to ask for a modification request
    // (currrently limiting to 1 re-certification)
    mapping(address => bool) public locked;

    // Count of the pending requests. This should
    // be 0 most of the time.
    uint public count;

    // The fee the users should be pay, that covers
    // the costs of sending 3 transactions.
    // This fee can be modified by the contract owner.
    uint public fee;

    // The treasury to which the funds are sent
    address public treasury;

    /// EVENTS

    // Emitted when the contract is drained
    event Drained(uint _balance);
    // Emitted when an account is locked
    event Locked(address _who);
    // Emitted when a new fee is set
    event NewFee(uint _oldFee, uint _newFee);
    // Emitted when the treasury is modified
    event NewTreasury(address _oldTreasury, address _newTreasury);
    // Emitted when a new modification request is received
    event Requested(address _sender, address _who);
    // Emitted when a request has been cleared ; meaning the
    // certified account has been transfered
    event Transfered(address _sender, address _who, address _certifier);

    /// MODIFIERS

    modifier only_unlocked(address _who) {
        require(!locked[_who]);
        _;
    }

    /// CONSTRUCTOR

    /// @notice Contructor method of the contract, which
    /// will set the `certifier` address
    /// @param _certifier The address of the main certifier
    /// @param _treasury The address of the treasury
    constructor(address _certifier, address _treasury) public {
        certifier = MultiCertifier(_certifier);
        treasury = _treasury;
    }

    /// @notice Fallback function. Should not be called.
    function () public {
        assert(false);
    }

    /// PUBLIC METHODS

    /// @notice This method will be called by certified
    /// accounts that which to certify another address.
    /// This function can only be called once per user.
    /// After a successful re-certification, these two accounts
    /// are locked, and cannot ask for another re-certification.
    /// @param who The address to which the certification should be
    ///            transfered
    function claim(address who)
    public payable
    only_unlocked(msg.sender)
    only_unlocked(who) {
        // Make sure that the fee is paid
        require(msg.value >= fee);
        // The sender should not have a pending certification transfer
        require(pending[msg.sender] == 0x0);
        // Cannot transfer to 0x0 account
        require(who != 0x0);
        // The sender should already be certified
        require(certifier.certified(msg.sender));
        // The new address shouldn&#39;t already be certified
        require(!certifier.certified(who));
        // Ensure that the owner of the contract is the
        // certifier of the sender
        require(certifier.getCertifier(msg.sender) == owner);

        pending[msg.sender] = who;
        count++;

        // Send the event
        emit Requested(msg.sender, who);

        // Transfer the funds to the treasury
        treasury.transfer(msg.value);
    }

    /// @notice This method is called by the certifier account
    /// in order to remove the pending request of modification
    /// of the certified address.
    /// Anyone can call this method, since it checks that the
    /// pending request has actually gone through (modification
    /// of certification address)
    function settle(address sender) public {
        address who = pending[sender];

        // Ensure that there is a pending transfer
        require(who != 0x0);
        // Ensure that the new address has been certified
        require(certifier.certified(who));
        // Ensure that the old address has been revoked
        require(!certifier.certified(sender));

        // Delete the pending entry
        delete pending[sender];
        count--;

        // Lock the accounts
        locked[sender] = true;
        locked[who] = true;

        // Send the Locked events
        emit Locked(sender);
        emit Locked(who);

        // Send the event
        emit Transfered(sender, who, msg.sender);
    }

    /// RESTRICTED (owner or delegate only) PUBLIC METHODS

    /// @notice Send the current balance to the treasury.
    /// Could be needed if value is sent outside of the `claim`
    /// method (eg. contract suicide)
    function drain() external only_owner {
        emit Drained(address(this).balance);
        treasury.transfer(address(this).balance);
    }

    /// @notice Change the fee, needed if for whatever reason gas price
    /// must be modified. Only the owner of the contract
    /// can execute this method.
    /// @param _fee The new fee
    function setFee(uint _fee) external only_owner {
        emit NewFee(fee, _fee);
        fee = _fee;
    }

    /// @notice The owner can lock an account, which is
    /// basically a blacklist. This shouldn&#39;t be used
    /// often ; but could be useful for re-deployment of
    /// new contract for example.
    /// @param _who The account to lock.
    function setLocked(address _who) external only_owner {
        emit Locked(_who);
        locked[_who] = true;
    }

    /// @notice Change the address of the treasury, the address to which
    /// the payments are forwarded to. Only the owner of the contract
    /// can execute this method.
    /// @param _treasury The new treasury address
    function setTreasury(address _treasury) external only_owner {
        emit NewTreasury(treasury, _treasury);
        treasury = _treasury;
    }
}