pragma solidity 0.4.24;


/**
 * (c) SecureVote 2018
 * 
 * This is a library to manage all ballot box functions. The idea is that
 * ballot box contracts should the the _minimum_ code required to be deployed
 * which means most (ideally all) functions should be moved here.
 */


library BBLib {
    using BytesLib for bytes;

    // ballot meta
    uint256 constant BB_VERSION = 6;
    /* 4 deprecated due to insecure vote by proxy
       5 deprecated to
        - add `returns (address)` to submitProxyVote
    */

    // voting settings
    uint16 constant USE_ETH = 1;          // 2^0
    uint16 constant USE_SIGNED = 2;       // 2^1
    uint16 constant USE_NO_ENC = 4;       // 2^2
    uint16 constant USE_ENC = 8;          // 2^3

    // ballot settings
    uint16 constant IS_BINDING = 8192;    // 2^13
    uint16 constant IS_OFFICIAL = 16384;  // 2^14
    uint16 constant USE_TESTING = 32768;  // 2^15

    // other consts
    uint32 constant MAX_UINT32 = 0xFFFFFFFF;

    //// ** Storage Variables

    // struct for ballot
    struct Vote {
        bytes32 voteData;
        bytes32 castTsAndSender;
        bytes extra;
    }

    struct Sponsor {
        address sender;
        uint amount;
    }

    //// ** Events
    event CreatedBallot(bytes32 _specHash, uint64 startTs, uint64 endTs, uint16 submissionBits);
    event SuccessfulVote(address indexed voter, uint voteId);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event DeprecatedContract();


    // The big database struct


    struct DB {
        // Maps to store ballots, along with corresponding log of voters.
        // Should only be modified through internal functions
        mapping (uint256 => Vote) votes;
        uint256 nVotesCast;

        // we need replay protection for proxy ballots - this will let us check against a sequence number
        // note: votes directly from a user ALWAYS take priority b/c they do not have sequence numbers
        // (sequencing is done by Ethereum itself via the tx nonce).
        mapping (address => uint32) sequenceNumber;

        // NOTE - We don&#39;t actually want to include the encryption PublicKey because _it&#39;s included in the ballotSpec_.
        // It&#39;s better to ensure ppl actually have the ballot spec by not including it in the contract.
        // Plus we&#39;re already storing the hash of the ballotSpec anyway...

        // Private key to be set after ballot conclusion - curve25519
        bytes32 ballotEncryptionSeckey;

        // packed contains:
        // 1. Timestamps for start and end of ballot (UTC)
        // 2. bits used to decide which options are enabled or disabled for submission of ballots
        uint256 packed;

        // specHash by which to validate the ballots integrity
        bytes32 specHash;
        // extradata if we need it - allows us to upgrade spechash format, etc
        bytes16 extraData;

        // allow tracking of sponsorship for this ballot & connection to index
        Sponsor[] sponsors;
        IxIface index;

        // deprecation flag - doesn&#39;t actually do anything besides signal that this contract is deprecated;
        bool deprecated;

        address ballotOwner;
        uint256 creationTs;
    }


    // ** Modifiers -- note, these are functions here to allow use as a lib
    function requireBallotClosed(DB storage db) internal view {
        require(now > BPackedUtils.packedToEndTime(db.packed), "!b-closed");
    }

    function requireBallotOpen(DB storage db) internal view {
        uint64 _n = uint64(now);
        uint64 startTs;
        uint64 endTs;
        (, startTs, endTs) = BPackedUtils.unpackAll(db.packed);
        require(_n >= startTs && _n < endTs, "!b-open");
        require(db.deprecated == false, "b-deprecated");
    }

    function requireBallotOwner(DB storage db) internal view {
        require(msg.sender == db.ballotOwner, "!b-owner");
    }

    function requireTesting(DB storage db) internal view {
        require(isTesting(BPackedUtils.packedToSubmissionBits(db.packed)), "!testing");
    }

    /* Library meta */

    function getVersion() external pure returns (uint) {
        // even though this is constant we want to make sure that it&#39;s actually
        // callable on Ethereum so we don&#39;t accidentally package the constant code
        // in with an SC using BBLib. This function _must_ be external.
        return BB_VERSION;
    }

    /* Functions */

    // "Constructor" function - init core params on deploy
    // timestampts are uint64s to give us plenty of room for millennia
    function init(DB storage db, bytes32 _specHash, uint256 _packed, IxIface ix, address ballotOwner, bytes16 extraData) external {
        require(db.specHash == bytes32(0), "b-exists");

        db.index = ix;
        db.ballotOwner = ballotOwner;

        uint64 startTs;
        uint64 endTs;
        uint16 sb;
        (sb, startTs, endTs) = BPackedUtils.unpackAll(_packed);

        bool _testing = isTesting(sb);
        if (_testing) {
            emit TestingEnabled();
        } else {
            require(endTs > now, "bad-end-time");

            // 0x1ff2 is 0001111111110010 in binary
            // by ANDing with subBits we make sure that only bits in positions 0,2,3,13,14,15
            // can be used. these correspond to the option flags at the top, and ETH ballots
            // that are enc&#39;d or plaintext.
            require(sb & 0x1ff2 == 0, "bad-sb");

            // if we give bad submission bits (e.g. all 0s) then refuse to deploy ballot
            bool okaySubmissionBits = 1 == (isEthNoEnc(sb) ? 1 : 0) + (isEthWithEnc(sb) ? 1 : 0);
            require(okaySubmissionBits, "!valid-sb");

            // take the max of the start time provided and the blocks timestamp to avoid a DoS against recent token holders
            // (which someone might be able to do if they could set the timestamp in the past)
            startTs = startTs > now ? startTs : uint64(now);
        }
        require(_specHash != bytes32(0), "null-specHash");
        db.specHash = _specHash;

        db.packed = BPackedUtils.pack(sb, startTs, endTs);
        db.creationTs = now;

        if (extraData != bytes16(0)) {
            db.extraData = extraData;
        }

        emit CreatedBallot(db.specHash, startTs, endTs, sb);
    }

    /* sponsorship */

    function logSponsorship(DB storage db, uint value) internal {
        db.sponsors.push(Sponsor(msg.sender, value));
    }

    /* getters */

    function getVote(DB storage db, uint id) internal view returns (bytes32 voteData, address sender, bytes extra, uint castTs) {
        return (db.votes[id].voteData, address(db.votes[id].castTsAndSender), db.votes[id].extra, uint(db.votes[id].castTsAndSender) >> 160);
    }

    function getSequenceNumber(DB storage db, address voter) internal view returns (uint32) {
        return db.sequenceNumber[voter];
    }

    function getTotalSponsorship(DB storage db) internal view returns (uint total) {
        for (uint i = 0; i < db.sponsors.length; i++) {
            total += db.sponsors[i].amount;
        }
    }

    function getSponsor(DB storage db, uint i) external view returns (address sender, uint amount) {
        sender = db.sponsors[i].sender;
        amount = db.sponsors[i].amount;
    }

    /* ETH BALLOTS */

    // Ballot submission
    // note: if USE_ENC then curve25519 keys should be generated for
    // each ballot (then thrown away).
    // the curve25519 PKs go in the extra param
    function submitVote(DB storage db, bytes32 voteData, bytes extra) external {
        _addVote(db, voteData, msg.sender, extra);
        // set the sequence number to max uint32 to disable proxy submitted ballots
        // after a voter submits a transaction personally - effectivley disables proxy
        // ballots. You can _always_ submit a new vote _personally_ with this scheme.
        if (db.sequenceNumber[msg.sender] != MAX_UINT32) {
            // using an IF statement here let&#39;s us save 4800 gas on repeat votes at the cost of 20k extra gas initially
            db.sequenceNumber[msg.sender] = MAX_UINT32;
        }
    }

    // Boundaries for constructing the msg we&#39;ll validate the signature of
    function submitProxyVote(DB storage db, bytes32[5] proxyReq, bytes extra) external returns (address voter) {
        // a proxy vote (where the vote is submitted (i.e. tx fee paid by someone else)
        // docs for datastructs: https://github.com/secure-vote/tokenvote/blob/master/Docs/DataStructs.md

        bytes32 r = proxyReq[0];
        bytes32 s = proxyReq[1];
        uint8 v = uint8(proxyReq[2][0]);
        // converting to uint248 will truncate the first byte, and we can then convert it to a bytes31.
        // we truncate the first byte because it&#39;s the `v` parm used above
        bytes31 proxyReq2 = bytes31(uint248(proxyReq[2]));
        // proxyReq[3] is ballotId - required for verifying sig but not used for anything else
        bytes32 ballotId = proxyReq[3];
        bytes32 voteData = proxyReq[4];

        // using abi.encodePacked is much cheaper than making bytes in other ways...
        bytes memory signed = abi.encodePacked(proxyReq2, ballotId, voteData, extra);
        bytes32 msgHash = keccak256(signed);
        // need to be sure we are signing the entire ballot and any extra data that comes with it
        voter = ecrecover(msgHash, v, r, s);

        // we need to make sure that this is the most recent vote the voter made, and that it has
        // not been seen before. NOTE: we&#39;ve already validated the BBFarm namespace before this, so
        // we know it&#39;s meant for _this_ ballot.
        uint32 sequence = uint32(proxyReq2);  // last 4 bytes of proxyReq2 - the sequence number
        _proxyReplayProtection(db, voter, sequence);

        _addVote(db, voteData, voter, extra);
    }

    function _addVote(DB storage db, bytes32 voteData, address sender, bytes extra) internal returns (uint256 id) {
        requireBallotOpen(db);

        id = db.nVotesCast;
        db.votes[id].voteData = voteData;
        // pack the casting ts right next to the sender
        db.votes[id].castTsAndSender = bytes32(sender) ^ bytes32(now << 160);
        if (extra.length > 0) {
            db.votes[id].extra = extra;
        }
        db.nVotesCast += 1;
        emit SuccessfulVote(sender, id);
    }

    function _proxyReplayProtection(DB storage db, address voter, uint32 sequence) internal {
        // we want the replay protection sequence number to be STRICTLY MORE than what
        // is stored in the mapping. This means we can set sequence to MAX_UINT32 to disable
        // any future votes.
        require(db.sequenceNumber[voter] < sequence, "bad-sequence-n");
        db.sequenceNumber[voter] = sequence;
    }

    /* Admin */

    function setEndTime(DB storage db, uint64 newEndTime) external {
        uint16 sb;
        uint64 sTs;
        (sb, sTs,) = BPackedUtils.unpackAll(db.packed);
        db.packed = BPackedUtils.pack(sb, sTs, newEndTime);
    }

    function revealSeckey(DB storage db, bytes32 sk) internal {
        db.ballotEncryptionSeckey = sk;
        emit SeckeyRevealed(sk);
    }

    /* Submission Bits (Ballot Classifications) */

    // do (bits & SETTINGS_MASK) to get just operational bits (as opposed to testing or official flag)
    uint16 constant SETTINGS_MASK = 0xFFFF ^ USE_TESTING ^ IS_OFFICIAL ^ IS_BINDING;

    function isEthNoEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_NO_ENC);
    }

    function isEthWithEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_ENC);
    }

    function isOfficial(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_OFFICIAL) == IS_OFFICIAL;
    }

    function isBinding(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_BINDING) == IS_BINDING;
    }

    function isTesting(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & USE_TESTING) == USE_TESTING;
    }

    function qualifiesAsCommunityBallot(uint16 submissionBits) pure internal returns (bool) {
        // if submissionBits AND any of the bits that make this _not_ a community
        // ballot is equal to zero that means none of those bits were active, so
        // it could be a community ballot
        return (submissionBits & (IS_BINDING | IS_OFFICIAL | USE_ENC)) == 0;
    }

    function checkFlags(uint16 submissionBits, uint16 expected) pure internal returns (bool) {
        // this should ignore ONLY the testing/flag bits - all other bits are significant
        uint16 sBitsNoSettings = submissionBits & SETTINGS_MASK;
        // then we want ONLY expected
        return sBitsNoSettings == expected;
    }
}

library BPackedUtils {

    // the uint16 ending at 128 bits should be 0s
    uint256 constant sbMask        = 0xffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffff;
    uint256 constant startTimeMask = 0xffffffffffffffffffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 constant endTimeMask   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000;

    function packedToSubmissionBits(uint256 packed) internal pure returns (uint16) {
        return uint16(packed >> 128);
    }

    function packedToStartTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed >> 64);
    }

    function packedToEndTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed);
    }

    function unpackAll(uint256 packed) internal pure returns (uint16 submissionBits, uint64 startTime, uint64 endTime) {
        submissionBits = uint16(packed >> 128);
        startTime = uint64(packed >> 64);
        endTime = uint64(packed);
    }

    function pack(uint16 sb, uint64 st, uint64 et) internal pure returns (uint256 packed) {
        return uint256(sb) << 128 | uint256(st) << 64 | uint256(et);
    }

    function setSB(uint256 packed, uint16 newSB) internal pure returns (uint256) {
        return (packed & sbMask) | uint256(newSB) << 128;
    }

    // function setStartTime(uint256 packed, uint64 startTime) internal pure returns (uint256) {
    //     return (packed & startTimeMask) | uint256(startTime) << 64;
    // }

    // function setEndTime(uint256 packed, uint64 endTime) internal pure returns (uint256) {
    //     return (packed & endTimeMask) | uint256(endTime);
    // }
}

interface IxIface {}

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don&#39;t need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let&#39;s prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don&#39;t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we&#39;re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin&#39;s length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let&#39;s just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there&#39;s
                //  no said feature for inline assembly loops
                // cb = 1 - don&#39;t breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don&#39;t match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let&#39;s prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there&#39;s
                        //  no said feature for inline assembly loops
                        // cb = 1 - don&#39;t breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}