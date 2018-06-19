pragma solidity ^0.4.0;

contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
}

contract Resolver {
    function setAddr(bytes32 nodeHash, address addr);
}
contract ReverseRegistrar {
    function claim(address owner) returns (bytes32 node);
}


/**
 *  FireflyRegistrar
 *
 *  This registrar allows arbitrary labels below the root node for a fixed minimum fee.
 *  Labels must conform to the regex /^[a-z0-9-]{4, 20}$/.
 *
 *  Admin priviledges:
 *    - change the admin
 *    - change the fee
 *    - change the default resolver
 *    - withdrawl funds
 *
 *  This resolver should is designed to be self-contained, so that in the future
 *  switching to a new Resolver should not impact this one.
 *
 */
contract FireflyRegistrar {
     // namehash(&#39;addr.reverse&#39;)
     bytes32 constant RR_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    // Admin triggered events
    event adminChanged(address oldAdmin, address newAdmin);
    event feeChanged(uint256 oldFee, uint256 newFee);
    event defaultResolverChanged(address oldResolver, address newResolver);
    event didWithdraw(address target, uint256 amount);

    // Registration
    event nameRegistered(bytes32 indexed nodeHash, address owner, uint256 fee);

    // Donations
    event donation(bytes32 indexed nodeHash, uint256 amount);

    AbstractENS _ens;
    Resolver _defaultResolver;

    address _admin;
    bytes32 _nodeHash;

    uint256 _fee;

    uint256 _totalPaid = 0;
    uint256 _nameCount = 0;

    mapping (bytes32 => uint256) _donations;

    function FireflyRegistrar(address ens, bytes32 nodeHash, address defaultResolver) {
        _ens = AbstractENS(ens);
        _nodeHash = nodeHash;
        _defaultResolver = Resolver(defaultResolver);

        _admin = msg.sender;

        _fee = 0.1 ether;

        // Give the admin access to the reverse entry
        ReverseRegistrar(_ens.owner(RR_NODE)).claim(_admin);
    }

    /**
     *  setAdmin(admin)
     *
     *  Change the admin of this contract. This should be used shortly after
     *  deployment and live testing to switch to a multi-sig contract.
     */
    function setAdmin(address admin) {
        if (msg.sender != _admin) { throw; }

        adminChanged(_admin, admin);
        _admin = admin;

        // Give the admin access to the reverse entry
        ReverseRegistrar(_ens.owner(RR_NODE)).claim(admin);

        // Point the resolved addr to the new admin
        Resolver(_ens.resolver(_nodeHash)).setAddr(_nodeHash, _admin);
    }

    /**
     *  setFee(fee)
     *
     *  This is useful if the price of ether sky-rockets or plummets, but
     *  for the most part should remain unused
     */
    function setFee(uint256 fee) {
        if (msg.sender != _admin) { throw; }
        feeChanged(_fee, fee);
        _fee = fee;
    }

    /**
     *  setDefaultResolver(resolver)
     *
     *  Allow the admin to change the default resolver that is setup with
     *  new name registrations.
     */
    function setDefaultResolver(address defaultResolver) {
        if (msg.sender != _admin) { throw; }
        defaultResolverChanged(_defaultResolver, defaultResolver);
        _defaultResolver = Resolver(defaultResolver);
    }

    /**
     *  withdraw(target, amount)
     *
     *  Allow the admin to withdrawl funds.
     */
    function withdraw(address target, uint256 amount) {
        if (msg.sender != _admin) { throw; }
        if (!target.send(amount)) { throw; }
        didWithdraw(target, amount);
    }

    /**
     *  register(label)
     *
     *  Allows anyone to send *fee* ether to the contract with a name to register.
     *
     *  Note: A name must match the regex /^[a-z0-9-]{4,20}$/
     */
    function register(string label) payable {

        // Check the label is legal
        uint256 position;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(label)

            // The first character position is the beginning of the second word
            position := add(label, 1)
        }

        // Labels must be at least 4 characters and at most 20 characters
        if (length < 4 || length > 20) { throw; }

        // Only allow /^[a-z0-9-]*$/
        for (uint256 i = 0; i < length; i++) {
            uint8 c;
            assembly { c := and(mload(position), 0xFF) }
            //       &#39;a&#39;         &#39;z&#39;           &#39;0&#39;         &#39;9&#39;           &#39;-&#39;
            if ((c < 0x61 || c > 0x7a) && (c < 0x30 || c > 0x39) && c != 0x2d) {
                throw;
            }
            position++;
        }

        // Paid too little; participants may pay more (as a donation)
        if (msg.value < _fee) { throw; }

        // Compute the label and node hash
        var labelHash = sha3(label);
        var nodeHash = sha3(_nodeHash, labelHash);

        // This is already owned in ENS
        if (_ens.owner(nodeHash) != address(0)) { throw; }

        // Make this registrar the owner (so we can set it up before giving it away)
        _ens.setSubnodeOwner(_nodeHash, labelHash, this);

        // Set up the default resolver and point to the sender
        _ens.setResolver(nodeHash, _defaultResolver);
        _defaultResolver.setAddr(nodeHash, msg.sender);

        // Now give it to the sender
        _ens.setOwner(nodeHash, msg.sender);

        _totalPaid += msg.value;
        _nameCount++;

        _donations[nodeHash] += msg.value;

        nameRegistered(nodeHash, msg.sender, msg.value);
        donation(nodeHash, msg.value);
    }

    /**
     *  donate(nodeHash)
     *
     *  Allow a registered name to donate more and get attribution. This may
     *  be useful if special limited edition Firefly devices are awarded to
     *  certain tiers of donors or such.
     */
    function donate(bytes32 nodeHash) payable {
        _donations[nodeHash] += msg.value;
        donation(nodeHash, msg.value);
    }

    /**
     *  config()
     *
     *  Get the configuration of this registrar.
     */
    function config() constant returns (address ens, bytes32 nodeHash, address admin, uint256 fee, address defaultResolver) {
        ens = _ens;
        nodeHash = _nodeHash;
        admin = _admin;
        fee = _fee;
        defaultResolver = _defaultResolver;
    }

    /**
     *  stats()
     *
     *  Get some statistics for this registrar.
     */
    function stats() constant returns (uint256 nameCount, uint256 totalPaid, uint256 balance) {
        nameCount = _nameCount;
        totalPaid = _totalPaid;
        balance = this.balance;
    }

    /**
     *  donations(nodeHash)
     *
     *  Returns the amount of donations a nodeHash has provided.
     */
    function donations(bytes32 nodeHash) constant returns (uint256 donation) {
        return _donations[nodeHash];
    }

    /**
     *  fee()
     *
     *  The current fee forregistering a name.
     */
    function fee() constant returns (uint256 fee) {
        return _fee;
    }

    /**
     *  Allow anonymous donations.
     */
    function () payable {
        _donations[0] += msg.value;
        donation(0, msg.value);
    }
}