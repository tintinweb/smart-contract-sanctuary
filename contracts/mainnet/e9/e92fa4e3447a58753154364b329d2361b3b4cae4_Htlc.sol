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

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract Htlc is DSMath {
    using ECRecovery for bytes32;

    // TYPES

    // ATL Authority timelocked contract
    struct Multisig { // Locked by authority approval (earlyResolve), time (timoutResolve) or conversion into an atomic swap
        address owner; // Owns ether deposited in multisig
        address authority; // Can approve earlyResolve of funds out of multisig
        uint deposit; // Amount deposited by owner in this multisig
        uint unlockTime; // Multisig expiration timestamp in seconds
    }

    struct AtomicSwap { // Locked by secret (regularTransfer) or time (reclaimExpiredSwaps)
        bytes32 msigId; // Corresponding multisigId
        address initiator; // Initiated this swap
        address beneficiary; // Beneficiary of this swap
        uint amount; // If zero then swap not active anymore
        uint fee; // Fee amount to be paid to multisig authority
        uint expirationTime; // Swap expiration timestamp in seconds
        bytes32 hashedSecret; // sha256(secret), hashed secret of swap initiator
    }

    // FIELDS

    address constant FEE_RECIPIENT = 0x478189a0aF876598C8a70Ce8896960500455A949;
    uint constant MAX_BATCH_ITERATIONS = 25; // Assumption block.gaslimit around 7500000
    mapping (bytes32 => Multisig) public multisigs;
    mapping (bytes32 => AtomicSwap) public atomicswaps;
    mapping (bytes32 => bool) public isAntecedentHashedSecret;

    // EVENTS

    event MultisigInitialised(bytes32 msigId);
    event MultisigReparametrized(bytes32 msigId);
    event AtomicSwapInitialised(bytes32 swapId);

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
        multisigs[msigId].deposit = sub(multisigs[msigId].deposit, amount);
        if (multisigs[msigId].deposit == 0)
            delete multisigs[msigId];
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
        // Require not own authority and non-zero ether amount are sent
        require(msg.sender != authority);
        require(msg.value > 0);
        // Create unique multisig identifier
        msigId = keccak256(
            msg.sender,
            authority,
            msg.value,
            unlockTime
        );
        emit MultisigInitialised(msigId);
        // Create multisig
        Multisig storage multisig = multisigs[msigId];
        if (multisig.deposit == 0) { // New or empty multisig
            // Create new multisig
            multisig.owner = msg.sender;
            multisig.authority = authority;
        }
        // Adjust balance and locktime
        reparametrizeMultisig(msigId, unlockTime);
    }

    /**
    @notice Inititate/extend multisig unlockTime and/or initiate/refund multisig deposit
    @dev Can increase deposit and/or unlockTime but not owner or authority
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @param unlockTime Lock Ether until unlockTime in seconds.
    */
    function reparametrizeMultisig(bytes32 msigId, uint unlockTime)
        public
        payable
    {
        require(multisigs[msigId].owner == msg.sender);
        Multisig storage multisig = multisigs[msigId];
        multisig.deposit = add(multisig.deposit, msg.value);
        assert(multisig.unlockTime <= unlockTime); // Can only increase unlockTime
        multisig.unlockTime = unlockTime;
        emit MultisigReparametrized(msigId);
    }

    /**
    @notice Withdraw ether from the multisig. Equivalent to EARLY_RESOLVE in Nimiq
    @dev the signature is generated using web3.eth.sign() over the unique msigId
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @param amount Return this amount from this contract to owner
    @param sig bytes signature of the not transaction sending Authority
    */
    function earlyResolve(bytes32 msigId, uint amount, bytes sig)
        public
    {
        // Require: msg.sender == (owner or authority)
        require(
            multisigs[msigId].owner == msg.sender ||
            multisigs[msigId].authority == msg.sender
        );
        // Require: valid signature from not msg.sending authority
        address otherAuthority = multisigs[msigId].owner == msg.sender ?
            multisigs[msigId].authority :
            multisigs[msigId].owner;
        require(otherAuthority == msigId.toEthSignedMessageHash().recover(sig));
        // Return to owner
        spendFromMultisig(msigId, amount, multisigs[msigId].owner);
    }

    /**
    @notice Withdraw ether and delete the htlc swap. Equivalent to TIMEOUT_RESOLVE in Nimiq
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @dev Only refunds owned multisig deposits
    */
    function timeoutResolve(bytes32 msigId, uint amount)
        public
    {
        // Require time has passed
        require(now >= multisigs[msigId].unlockTime);
        // Return to owner
        spendFromMultisig(msigId, amount, multisigs[msigId].owner);
    }

    /**
    @notice First or second stage of atomic swap.
    @param msigId Unique (owner, authority, balance != 0) multisig identifier
    @param beneficiary Beneficiary of this swap
    @param amount Convert this amount from multisig into swap
    @param fee Fee amount to be paid to multisig authority
    @param expirationTime Swap expiration timestamp in seconds; not more than 1 day from now
    @param hashedSecret sha256(secret), hashed secret of swap initiator
    @return swapId Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifier
    */
    function convertIntoHtlc(bytes32 msigId, address beneficiary, uint amount, uint fee, uint expirationTime, bytes32 hashedSecret)
        public
        returns (bytes32 swapId)
    {
        // Require owner with sufficient deposit
        require(multisigs[msigId].owner == msg.sender);
        require(multisigs[msigId].deposit >= amount + fee); // Checks for underflow
        require(
            now <= expirationTime &&
            expirationTime <= min(now + 1 days, multisigs[msigId].unlockTime)
        ); // Not more than 1 day or unlockTime
        require(amount > 0); // Non-empty amount as definition for active swap
        require(!isAntecedentHashedSecret[hashedSecret]);
        isAntecedentHashedSecret[hashedSecret] = true;
        // Account in multisig balance
        multisigs[msigId].deposit = sub(multisigs[msigId].deposit, add(amount, fee));
        // Create swap identifier
        swapId = keccak256(
            msigId,
            msg.sender,
            beneficiary,
            amount,
            fee,
            expirationTime,
            hashedSecret
        );
        emit AtomicSwapInitialised(swapId);
        // Create swap
        AtomicSwap storage swap = atomicswaps[swapId];
        swap.msigId = msigId;
        swap.initiator = msg.sender;
        swap.beneficiary = beneficiary;
        swap.amount = amount;
        swap.fee = fee;
        swap.expirationTime = expirationTime;
        swap.hashedSecret = hashedSecret;
        // Transfer fee to fee recipient
        FEE_RECIPIENT.transfer(fee);
    }

    /**
    @notice Batch execution of convertIntoHtlc() function
    */
    function batchConvertIntoHtlc(
        bytes32[] msigIds,
        address[] beneficiaries,
        uint[] amounts,
        uint[] fees,
        uint[] expirationTimes,
        bytes32[] hashedSecrets
    )
        public
        returns (bytes32[] swapId)
    {
        require(msigIds.length <= MAX_BATCH_ITERATIONS);
        for (uint i = 0; i < msigIds.length; ++i)
            convertIntoHtlc(
                msigIds[i],
                beneficiaries[i],
                amounts[i],
                fees[i],
                expirationTimes[i],
                hashedSecrets[i]
            ); // Gas estimate `infinite`
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
        require(sha256(secret) == atomicswaps[swapId].hashedSecret);
        uint amount = atomicswaps[swapId].amount;
        address beneficiary = atomicswaps[swapId].beneficiary;
        // Delete swap
        delete atomicswaps[swapId];
        // Execute swap
        beneficiary.transfer(amount);
    }

    /**
    @notice Batch exection of regularTransfer() function
    */
    function batchRegularTransfers(bytes32[] swapIds, bytes32[] secrets)
        public
    {
        require(swapIds.length <= MAX_BATCH_ITERATIONS);
        for (uint i = 0; i < swapIds.length; ++i)
            regularTransfer(swapIds[i], secrets[i]); // Gas estimate `infinite`
    }

    /**
    @notice Reclaim an expired, non-empty swap into a multisig
    @dev Transfer swap amount to beneficiary of swap and fee to authority
    @param msigId Unique (owner, authority, balance != 0) multisig identifier to which deposit expired swaps
    @param swapId Unique (initiator, beneficiary, amount, fee, expirationTime, hashedSecret) swap identifier
    */
    function reclaimExpiredSwap(bytes32 msigId, bytes32 swapId)
        public
    {
        // Require: msg.sender == ower or authority
        require(
            multisigs[msigId].owner == msg.sender ||
            multisigs[msigId].authority == msg.sender
        );
        // Require msigId matches swapId
        require(msigId == atomicswaps[swapId].msigId);
        // Require: is expired
        require(now >= atomicswaps[swapId].expirationTime);
        uint amount = atomicswaps[swapId].amount;
        delete atomicswaps[swapId];
        multisigs[msigId].deposit = add(multisigs[msigId].deposit, amount);
    }

    /**
    @notice Batch exection of reclaimExpiredSwaps() function
    */
    function batchReclaimExpiredSwaps(bytes32 msigId, bytes32[] swapIds)
        public
    {
        require(swapIds.length <= MAX_BATCH_ITERATIONS); // << block.gaslimit / 88281
        for (uint i = 0; i < swapIds.length; ++i)
            reclaimExpiredSwap(msigId, swapIds[i]); // Gas estimate 88281
    }
}