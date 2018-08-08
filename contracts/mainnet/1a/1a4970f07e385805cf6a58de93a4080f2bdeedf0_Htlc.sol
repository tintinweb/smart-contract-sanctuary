pragma solidity ^0.4.13;

library ECRecovery {

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * @dev and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            hash
        );
    }
}

contract Htlc {
    using ECRecovery for bytes32;

    // TYPES

    struct Multisig { // Locked by time and/or authority approval for HTLC conversion or earlyResolve
        address owner; // Owns funds deposited in multisig,
        address authority; // Can approve earlyResolve of funds out of multisig
        uint deposit; // Amount deposited by owner in this multisig
        uint unlockTime; // Multisig expiration timestamp in seconds
    }

    struct AtomicSwap { // HTLC swap used for regular transfers
        address initiator; // Initiated this swap
        address beneficiary; // Beneficiary of this swap
        uint amount; // If zero then swap not active anymore
        uint fee; // Fee amount to be paid to multisig authority
        uint expirationTime; // Swap expiration timestamp in seconds
        bytes32 hashedSecret; // sha256(secret), hashed secret of swap initiator
    }

    // FIELDS

    address constant FEE_RECIPIENT = 0x0E5cB767Cce09A7F3CA594Df118aa519BE5e2b5A;
    mapping (bytes32 => Multisig) public hashIdToMultisig;
    mapping (bytes32 => AtomicSwap) public hashIdToSwap;

    // EVENTS

    // TODO add events for all public functions

    // MODIFIERS

    // METHODS

    /**
    @notice Send ether out of this contract to multisig owner and update or delete entry in multisig mapping
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @param amount Spend this amount of ether
    */
    function spendFromMultisig(bytes32 msigId, uint amount, address recipient)
        internal
    {
        // Require sufficient deposit amount; Prevents buffer underflow
        require(amount <= hashIdToMultisig[msigId].deposit);
        hashIdToMultisig[msigId].deposit -= amount;
        if (hashIdToMultisig[msigId].deposit == 0) {
            // Delete multisig
            delete hashIdToMultisig[msigId];
            assert(hashIdToMultisig[msigId].deposit == 0);
        }
        // Transfer recipient
        recipient.transfer(amount);
    }

    /**
    @notice Send ether out of this contract to swap beneficiary and update or delete entry in swap mapping
    @param swapId Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifier
    @param amount Spend this amount of ether
    */
    function spendFromSwap(bytes32 swapId, uint amount, address recipient)
        internal
    {
        // Require sufficient swap amount; Prevents buffer underflow
        require(amount <= hashIdToSwap[swapId].amount);
        hashIdToSwap[swapId].amount -= amount;
        if (hashIdToSwap[swapId].amount == 0) {
            // Delete swap
            delete hashIdToSwap[swapId];
            assert(hashIdToSwap[swapId].amount == 0);
        }
        // Transfer to recipient
        recipient.transfer(amount);
    }

    // PUBLIC METHODS

    /**
    @notice Initialise and reparametrize Multisig
    @dev Uses msg.value to fund Multisig
    @param authority Second multisig Authority. Usually this is the Exchange.
    @param unlockTime Lock Ether until unlockTime in seconds.
    @return msigId Unique (owner, authority, balance != 0) multisig identifier
    */
    function initialiseMultisig(address authority, uint unlockTime)
        public
        payable
        returns (bytes32 msigId)
    {
        // Require not own authority and ether are sent
        require(msg.sender != authority);
        require(msg.value > 0);
        msigId = keccak256(
            msg.sender,
            authority,
            msg.value,
            unlockTime
        );

        Multisig storage multisig = hashIdToMultisig[msigId];
        if (multisig.deposit == 0) { // New or empty multisig
            // Create new multisig
            multisig.owner = msg.sender;
            multisig.authority = authority;
        }
        // Adjust balance and locktime
        reparametrizeMultisig(msigId, unlockTime);
    }

    /**
    @notice Deposit msg.value ether into a multisig and set unlockTime
    @dev Can increase deposit and/or unlockTime but not owner or authority
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @param unlockTime Lock Ether until unlockTime in seconds.
    */
    function reparametrizeMultisig(bytes32 msigId, uint unlockTime)
        public
        payable
    {
        Multisig storage multisig = hashIdToMultisig[msigId];
        assert(
            multisig.deposit + msg.value >=
            multisig.deposit
        ); // Throws on overflow.
        multisig.deposit += msg.value;
        assert(multisig.unlockTime <= unlockTime); // Can only increase unlockTime
        multisig.unlockTime = unlockTime;
    }

    // TODO allow for batch convertIntoHtlc
    /**
    @notice Convert swap from multisig to htlc mode
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @param beneficiary Beneficiary of this swap
    @param amount Convert this amount from multisig into swap
    @param fee Fee amount to be paid to multisig authority
    @param expirationTime Swap expiration timestamp in seconds; not more than 1 day from now
    @param hashedSecret sha3(secret), hashed secret of swap initiator
    @return swapId Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifier
    */
    function convertIntoHtlc(bytes32 msigId, address beneficiary, uint amount, uint fee, uint expirationTime, bytes32 hashedSecret)
        public
        returns (bytes32 swapId)
    {
        // Require owner with sufficient deposit
        require(hashIdToMultisig[msigId].owner == msg.sender);
        require(hashIdToMultisig[msigId].deposit >= amount + fee); // Checks for underflow
        require(now <= expirationTime && expirationTime <= now + 86400); // Not more than 1 day
        require(amount > 0); // Non-empty amount as definition for active swap
        // Account in multisig balance
        hashIdToMultisig[msigId].deposit -= amount + fee;
        swapId = keccak256(
            msg.sender,
            beneficiary,
            amount,
            fee,
            expirationTime,
            hashedSecret
        );
        // Create swap
        AtomicSwap storage swap = hashIdToSwap[swapId];
        swap.initiator = msg.sender;
        swap.beneficiary = beneficiary;
        swap.amount = amount;
        swap.fee = fee;
        swap.expirationTime = expirationTime;
        swap.hashedSecret = hashedSecret;
        // Transfer fee to multisig.authority
        hashIdToMultisig[msigId].authority.transfer(fee);
    }

    // TODO calc gas limit
    /**
    @notice Withdraw ether and delete the htlc swap. Equivalent to REGULAR_TRANSFER in Nimiq
    @dev Transfer swap amount to beneficiary of swap and fee to authority
    @param swapIds Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifiers
    @param secrets Hashed secrets of htlc swaps
    */
    function batchRegularTransfer(bytes32[] swapIds, bytes32[] secrets)
        public
    {
        for (uint i = 0; i < swapIds.length; ++i)
            regularTransfer(swapIds[i], secrets[i]);
    }

    /**
    @notice Withdraw ether and delete the htlc swap. Equivalent to REGULAR_TRANSFER in Nimiq
    @dev Transfer swap amount to beneficiary of swap and fee to authority
    @param swapId Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifier
    @param secret Hashed secret of htlc swap
    */
    function regularTransfer(bytes32 swapId, bytes32 secret)
        public
    {
        // Require valid secret provided
        require(sha256(secret) == hashIdToSwap[swapId].hashedSecret);
        // Execute swap
        spendFromSwap(swapId, hashIdToSwap[swapId].amount, hashIdToSwap[swapId].beneficiary);
        spendFromSwap(swapId, hashIdToSwap[swapId].fee, FEE_RECIPIENT);
    }

    /**
    @notice Reclaim all the expired, non-empty swaps into a multisig
    @dev Transfer swap amount to beneficiary of swap and fee to authority
    @param msigId Unique (owner, authority, balance != 0) multisig identifier to which deposit expired swaps
    @param swapIds Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifiers
    */
    function batchReclaimExpiredSwaps(bytes32 msigId, bytes32[] swapIds)
        public
    {
        for (uint i = 0; i < swapIds.length; ++i)
            reclaimExpiredSwaps(msigId, swapIds[i]);
    }

    /**
    @notice Reclaim an expired, non-empty swap into a multisig
    @dev Transfer swap amount to beneficiary of swap and fee to authority
    @param msigId Unique (owner, authority, balance != 0) multisig identifier to which deposit expired swaps
    @param swapId Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifier
    */
    function reclaimExpiredSwaps(bytes32 msigId, bytes32 swapId)
        public
    {
        // Require: msg.sender == ower or authority
        require(
            hashIdToMultisig[msigId].owner == msg.sender ||
            hashIdToMultisig[msigId].authority == msg.sender
        );
        // TODO! link msigId to swapId
        // Require: is expired
        require(now >= hashIdToSwap[swapId].expirationTime);
        uint amount = hashIdToSwap[swapId].amount;
        assert(hashIdToMultisig[msigId].deposit + amount >= amount); // Throws on overflow.
        delete hashIdToSwap[swapId];
        hashIdToMultisig[msigId].deposit += amount;
    }

    /**
    @notice Withdraw ether and delete the htlc swap. Equivalent to EARLY_RESOLVE in Nimiq
    @param hashedMessage bytes32 hash of unique swap hash, the hash is the signed message. What is recovered is the signer address.
    @param sig bytes signature, the signature is generated using web3.eth.sign()
    */
    function earlyResolve(bytes32 msigId, uint amount, bytes32 hashedMessage, bytes sig)
        public
    {
        // Require: msg.sender == ower or authority
        require(
            hashIdToMultisig[msigId].owner == msg.sender ||
            hashIdToMultisig[msigId].authority == msg.sender
        );
        // Require: valid signature from not tx.sending authority
        address otherAuthority = hashIdToMultisig[msigId].owner == msg.sender ?
            hashIdToMultisig[msigId].authority :
            hashIdToMultisig[msigId].owner;
        require(otherAuthority == hashedMessage.recover(sig));

        spendFromMultisig(msigId, amount, hashIdToMultisig[msigId].owner);
    }

    /**
    @notice Withdraw ether and delete the htlc swap. Equivalent to TIMEOUT_RESOLVE in Nimiq
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @dev Only refunds owned multisig deposits
    */
    function timeoutResolve(bytes32 msigId, uint amount)
        public
    {
        // Require sufficient amount and time passed
        require(hashIdToMultisig[msigId].deposit >= amount);
        require(now >= hashIdToMultisig[msigId].unlockTime);

        spendFromMultisig(msigId, amount, hashIdToMultisig[msigId].owner);
    }

    // TODO add timelocked selfdestruct function for initial version
}