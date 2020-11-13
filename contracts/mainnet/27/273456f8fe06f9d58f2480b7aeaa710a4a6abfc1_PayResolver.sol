// File: contracts/lib/data/Pb.sol

pragma solidity ^0.5.0;

// runtime proto sol library
library Pb {
    enum WireType { Varint, Fixed64, LengthDelim, StartGroup, EndGroup, Fixed32 }

    struct Buffer {
        uint idx;  // the start index of next read. when idx=b.length, we're done
        bytes b;   // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf) internal pure returns (uint tag, WireType wiretype) {
        uint v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
	// have to create array for (maxtag+1) size. cnts[tag] = occurrences
	// should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint maxtag) internal pure returns (uint[] memory cnts) {
        uint originalIdx = buf.idx;
        cnts = new uint[](maxtag+1);  // protobuf's tags are from 1 rather than 0
        uint tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint v) {
        bytes10 tmp;  // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b;  // get buf.b mem addr to use in assembly
        v = buf.idx;  // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint i=0; i<10; i++) {
            assembly {
                b := byte(i, tmp)  // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint len = decVarint(buf);
        uint end = buf.idx + len;
        require(end <= buf.b.length);  // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b;  // get buf.b mem addr to use in assembly
        uint bStart;
        uint bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint i=0; i<len; i+=32) {
            assembly{
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf) internal pure returns (uint[] memory t) {
        uint len = decVarint(buf);
        uint end = buf.idx + len;
        require(end <= buf.b.length);  // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint[] memory tmp = new uint[](len);
        uint i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint[](i); // init t with correct length
        for (uint j=0; j<i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) { decVarint(buf); }
        else if (wire == WireType.LengthDelim) {
            uint len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length);  // avoid overflow
        } else { revert(); }  // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32);  // b's length must be smaller than or equal to 32
        assembly { v := mload(add(b, 32)) }  // load all 32bytes to v
        v = v >> (8 * (32 - b.length));  // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly { v := div(mload(add(b, 32)), 0x1000000000000000000000000) }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly { v := mload(add(b, 32)) }
    }

    // uint[] to uint8[]
    function uint8s(uint[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = uint8(arr[i]); }
    }

    function uint32s(uint[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = uint32(arr[i]); }
    }

    function uint64s(uint[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = uint64(arr[i]); }
    }

    function bools(uint[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = arr[i]!=0; }
    }
}

// File: contracts/lib/data/PbChain.sol

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: chain.proto
pragma solidity ^0.5.0;


library PbChain {
    using Pb for Pb.Buffer;  // so we can call Pb funcs on Buffer obj

    struct OpenChannelRequest {
        bytes channelInitializer;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct OpenChannelRequest

    function decOpenChannelRequest(bytes memory raw) internal pure returns (OpenChannelRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.channelInitializer = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder OpenChannelRequest

    struct CooperativeWithdrawRequest {
        bytes withdrawInfo;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct CooperativeWithdrawRequest

    function decCooperativeWithdrawRequest(bytes memory raw) internal pure returns (CooperativeWithdrawRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.withdrawInfo = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder CooperativeWithdrawRequest

    struct CooperativeSettleRequest {
        bytes settleInfo;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct CooperativeSettleRequest

    function decCooperativeSettleRequest(bytes memory raw) internal pure returns (CooperativeSettleRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.settleInfo = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder CooperativeSettleRequest

    struct ResolvePayByConditionsRequest {
        bytes condPay;   // tag: 1
        bytes[] hashPreimages;   // tag: 2
    } // end struct ResolvePayByConditionsRequest

    function decResolvePayByConditionsRequest(bytes memory raw) internal pure returns (ResolvePayByConditionsRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.hashPreimages = new bytes[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.condPay = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.hashPreimages[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder ResolvePayByConditionsRequest

    struct SignedSimplexState {
        bytes simplexState;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct SignedSimplexState

    function decSignedSimplexState(bytes memory raw) internal pure returns (SignedSimplexState memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.simplexState = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder SignedSimplexState

    struct SignedSimplexStateArray {
        SignedSimplexState[] signedSimplexStates;   // tag: 1
    } // end struct SignedSimplexStateArray

    function decSignedSimplexStateArray(bytes memory raw) internal pure returns (SignedSimplexStateArray memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(1);
        m.signedSimplexStates = new SignedSimplexState[](cnts[1]);
        cnts[1] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.signedSimplexStates[cnts[1]] = decSignedSimplexState(buf.decBytes());
                cnts[1]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder SignedSimplexStateArray

    struct ChannelMigrationRequest {
        bytes channelMigrationInfo;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct ChannelMigrationRequest

    function decChannelMigrationRequest(bytes memory raw) internal pure returns (ChannelMigrationRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.channelMigrationInfo = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder ChannelMigrationRequest

}

// File: contracts/lib/data/PbEntity.sol

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: entity.proto
pragma solidity ^0.5.0;


library PbEntity {
    using Pb for Pb.Buffer;  // so we can call Pb funcs on Buffer obj

    enum TokenType { INVALID, ETH, ERC20 }

    // TokenType[] decode function
    function TokenTypes(uint[] memory arr) internal pure returns (TokenType[] memory t) {
        t = new TokenType[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = TokenType(arr[i]); }
    }

    enum TransferFunctionType { BOOLEAN_AND, BOOLEAN_OR, BOOLEAN_CIRCUIT, NUMERIC_ADD, NUMERIC_MAX, NUMERIC_MIN }

    // TransferFunctionType[] decode function
    function TransferFunctionTypes(uint[] memory arr) internal pure returns (TransferFunctionType[] memory t) {
        t = new TransferFunctionType[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = TransferFunctionType(arr[i]); }
    }

    enum ConditionType { HASH_LOCK, DEPLOYED_CONTRACT, VIRTUAL_CONTRACT }

    // ConditionType[] decode function
    function ConditionTypes(uint[] memory arr) internal pure returns (ConditionType[] memory t) {
        t = new ConditionType[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = ConditionType(arr[i]); }
    }

    struct AccountAmtPair {
        address account;   // tag: 1
        uint256 amt;   // tag: 2
    } // end struct AccountAmtPair

    function decAccountAmtPair(bytes memory raw) internal pure returns (AccountAmtPair memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.account = Pb._address(buf.decBytes());
            }
            else if (tag == 2) {
                m.amt = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder AccountAmtPair

    struct TokenInfo {
        TokenType tokenType;   // tag: 1
        address tokenAddress;   // tag: 2
    } // end struct TokenInfo

    function decTokenInfo(bytes memory raw) internal pure returns (TokenInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.tokenType = TokenType(buf.decVarint());
            }
            else if (tag == 2) {
                m.tokenAddress = Pb._address(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder TokenInfo

    struct TokenDistribution {
        TokenInfo token;   // tag: 1
        AccountAmtPair[] distribution;   // tag: 2
    } // end struct TokenDistribution

    function decTokenDistribution(bytes memory raw) internal pure returns (TokenDistribution memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.distribution = new AccountAmtPair[](cnts[2]);
        cnts[2] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.token = decTokenInfo(buf.decBytes());
            }
            else if (tag == 2) {
                m.distribution[cnts[2]] = decAccountAmtPair(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder TokenDistribution

    struct TokenTransfer {
        TokenInfo token;   // tag: 1
        AccountAmtPair receiver;   // tag: 2
    } // end struct TokenTransfer

    function decTokenTransfer(bytes memory raw) internal pure returns (TokenTransfer memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.token = decTokenInfo(buf.decBytes());
            }
            else if (tag == 2) {
                m.receiver = decAccountAmtPair(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder TokenTransfer

    struct SimplexPaymentChannel {
        bytes32 channelId;   // tag: 1
        address peerFrom;   // tag: 2
        uint seqNum;   // tag: 3
        TokenTransfer transferToPeer;   // tag: 4
        PayIdList pendingPayIds;   // tag: 5
        uint lastPayResolveDeadline;   // tag: 6
        uint256 totalPendingAmount;   // tag: 7
    } // end struct SimplexPaymentChannel

    function decSimplexPaymentChannel(bytes memory raw) internal pure returns (SimplexPaymentChannel memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.peerFrom = Pb._address(buf.decBytes());
            }
            else if (tag == 3) {
                m.seqNum = uint(buf.decVarint());
            }
            else if (tag == 4) {
                m.transferToPeer = decTokenTransfer(buf.decBytes());
            }
            else if (tag == 5) {
                m.pendingPayIds = decPayIdList(buf.decBytes());
            }
            else if (tag == 6) {
                m.lastPayResolveDeadline = uint(buf.decVarint());
            }
            else if (tag == 7) {
                m.totalPendingAmount = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder SimplexPaymentChannel

    struct PayIdList {
        bytes32[] payIds;   // tag: 1
        bytes32 nextListHash;   // tag: 2
    } // end struct PayIdList

    function decPayIdList(bytes memory raw) internal pure returns (PayIdList memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.payIds = new bytes32[](cnts[1]);
        cnts[1] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.payIds[cnts[1]] = Pb._bytes32(buf.decBytes());
                cnts[1]++;
            }
            else if (tag == 2) {
                m.nextListHash = Pb._bytes32(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder PayIdList

    struct TransferFunction {
        TransferFunctionType logicType;   // tag: 1
        TokenTransfer maxTransfer;   // tag: 2
    } // end struct TransferFunction

    function decTransferFunction(bytes memory raw) internal pure returns (TransferFunction memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.logicType = TransferFunctionType(buf.decVarint());
            }
            else if (tag == 2) {
                m.maxTransfer = decTokenTransfer(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder TransferFunction

    struct ConditionalPay {
        uint payTimestamp;   // tag: 1
        address src;   // tag: 2
        address dest;   // tag: 3
        Condition[] conditions;   // tag: 4
        TransferFunction transferFunc;   // tag: 5
        uint resolveDeadline;   // tag: 6
        uint resolveTimeout;   // tag: 7
        address payResolver;   // tag: 8
    } // end struct ConditionalPay

    function decConditionalPay(bytes memory raw) internal pure returns (ConditionalPay memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(8);
        m.conditions = new Condition[](cnts[4]);
        cnts[4] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.payTimestamp = uint(buf.decVarint());
            }
            else if (tag == 2) {
                m.src = Pb._address(buf.decBytes());
            }
            else if (tag == 3) {
                m.dest = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.conditions[cnts[4]] = decCondition(buf.decBytes());
                cnts[4]++;
            }
            else if (tag == 5) {
                m.transferFunc = decTransferFunction(buf.decBytes());
            }
            else if (tag == 6) {
                m.resolveDeadline = uint(buf.decVarint());
            }
            else if (tag == 7) {
                m.resolveTimeout = uint(buf.decVarint());
            }
            else if (tag == 8) {
                m.payResolver = Pb._address(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder ConditionalPay

    struct CondPayResult {
        bytes condPay;   // tag: 1
        uint256 amount;   // tag: 2
    } // end struct CondPayResult

    function decCondPayResult(bytes memory raw) internal pure returns (CondPayResult memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.condPay = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.amount = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder CondPayResult

    struct VouchedCondPayResult {
        bytes condPayResult;   // tag: 1
        bytes sigOfSrc;   // tag: 2
        bytes sigOfDest;   // tag: 3
    } // end struct VouchedCondPayResult

    function decVouchedCondPayResult(bytes memory raw) internal pure returns (VouchedCondPayResult memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.condPayResult = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigOfSrc = bytes(buf.decBytes());
            }
            else if (tag == 3) {
                m.sigOfDest = bytes(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder VouchedCondPayResult

    struct Condition {
        ConditionType conditionType;   // tag: 1
        bytes32 hashLock;   // tag: 2
        address deployedContractAddress;   // tag: 3
        bytes32 virtualContractAddress;   // tag: 4
        bytes argsQueryFinalization;   // tag: 5
        bytes argsQueryOutcome;   // tag: 6
    } // end struct Condition

    function decCondition(bytes memory raw) internal pure returns (Condition memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.conditionType = ConditionType(buf.decVarint());
            }
            else if (tag == 2) {
                m.hashLock = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 3) {
                m.deployedContractAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.virtualContractAddress = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 5) {
                m.argsQueryFinalization = bytes(buf.decBytes());
            }
            else if (tag == 6) {
                m.argsQueryOutcome = bytes(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder Condition

    struct CooperativeWithdrawInfo {
        bytes32 channelId;   // tag: 1
        uint seqNum;   // tag: 2
        AccountAmtPair withdraw;   // tag: 3
        uint withdrawDeadline;   // tag: 4
        bytes32 recipientChannelId;   // tag: 5
    } // end struct CooperativeWithdrawInfo

    function decCooperativeWithdrawInfo(bytes memory raw) internal pure returns (CooperativeWithdrawInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.seqNum = uint(buf.decVarint());
            }
            else if (tag == 3) {
                m.withdraw = decAccountAmtPair(buf.decBytes());
            }
            else if (tag == 4) {
                m.withdrawDeadline = uint(buf.decVarint());
            }
            else if (tag == 5) {
                m.recipientChannelId = Pb._bytes32(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder CooperativeWithdrawInfo

    struct PaymentChannelInitializer {
        TokenDistribution initDistribution;   // tag: 1
        uint openDeadline;   // tag: 2
        uint disputeTimeout;   // tag: 3
        uint msgValueReceiver;   // tag: 4
    } // end struct PaymentChannelInitializer

    function decPaymentChannelInitializer(bytes memory raw) internal pure returns (PaymentChannelInitializer memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.initDistribution = decTokenDistribution(buf.decBytes());
            }
            else if (tag == 2) {
                m.openDeadline = uint(buf.decVarint());
            }
            else if (tag == 3) {
                m.disputeTimeout = uint(buf.decVarint());
            }
            else if (tag == 4) {
                m.msgValueReceiver = uint(buf.decVarint());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder PaymentChannelInitializer

    struct CooperativeSettleInfo {
        bytes32 channelId;   // tag: 1
        uint seqNum;   // tag: 2
        AccountAmtPair[] settleBalance;   // tag: 3
        uint settleDeadline;   // tag: 4
    } // end struct CooperativeSettleInfo

    function decCooperativeSettleInfo(bytes memory raw) internal pure returns (CooperativeSettleInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(4);
        m.settleBalance = new AccountAmtPair[](cnts[3]);
        cnts[3] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.seqNum = uint(buf.decVarint());
            }
            else if (tag == 3) {
                m.settleBalance[cnts[3]] = decAccountAmtPair(buf.decBytes());
                cnts[3]++;
            }
            else if (tag == 4) {
                m.settleDeadline = uint(buf.decVarint());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder CooperativeSettleInfo

    struct ChannelMigrationInfo {
        bytes32 channelId;   // tag: 1
        address fromLedgerAddress;   // tag: 2
        address toLedgerAddress;   // tag: 3
        uint migrationDeadline;   // tag: 4
    } // end struct ChannelMigrationInfo

    function decChannelMigrationInfo(bytes memory raw) internal pure returns (ChannelMigrationInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.fromLedgerAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 3) {
                m.toLedgerAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.migrationDeadline = uint(buf.decVarint());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder ChannelMigrationInfo

}

// File: contracts/lib/interface/IPayRegistry.sol

pragma solidity ^0.5.1;

/**
 * @title PayRegistry interface
 */
interface IPayRegistry {
    function calculatePayId(bytes32 _payHash, address _setter) external pure returns(bytes32);

    function setPayAmount(bytes32 _payHash, uint _amt) external;

    function setPayDeadline(bytes32 _payHash, uint _deadline) external;

    function setPayInfo(bytes32 _payHash, uint _amt, uint _deadline) external;

    function setPayAmounts(bytes32[] calldata _payHashes, uint[] calldata _amts) external;

    function setPayDeadlines(bytes32[] calldata _payHashes, uint[] calldata _deadlines) external;

    function setPayInfos(bytes32[] calldata _payHashes, uint[] calldata _amts, uint[] calldata _deadlines) external;

    function getPayAmounts(
        bytes32[] calldata _payIds,
        uint _lastPayResolveDeadline
    ) external view returns(uint[] memory);

    function getPayInfo(bytes32 _payId) external view returns(uint, uint);

    event PayInfoUpdate(bytes32 indexed payId, uint amount, uint resolveDeadline);
}

// File: contracts/lib/interface/IPayResolver.sol

pragma solidity ^0.5.1;

/**
 * @title PayResolver interface
 */
interface IPayResolver {
    function resolvePaymentByConditions(bytes calldata _resolvePayRequest) external;

    function resolvePaymentByVouchedResult(bytes calldata _vouchedPayResult) external;

    event ResolvePayment(bytes32 indexed payId, uint amount, uint resolveDeadline);
}

// File: contracts/lib/interface/IBooleanCond.sol

pragma solidity ^0.5.0;

/**
 * @title BooleanCond interface
 */
interface IBooleanCond {
    function isFinalized(bytes calldata _query) external view returns (bool);
    
    function getOutcome(bytes calldata _query) external view returns (bool);
}

// File: contracts/lib/interface/INumericCond.sol

pragma solidity ^0.5.0;

/**
 * @title NumericCond interface
 */
interface INumericCond {
    function isFinalized(bytes calldata _query) external view returns (bool);
    
    function getOutcome(bytes calldata _query) external view returns (uint);
}

// File: contracts/lib/interface/IVirtContractResolver.sol

pragma solidity ^0.5.1;

/**
 * @title VirtContractResolver interface
 */
interface IVirtContractResolver {
    function deploy(bytes calldata _code, uint _nonce) external returns (bool);
    
    function resolve(bytes32 _virtAddr) external view returns (address);

    event Deploy(bytes32 indexed virtAddr);
}

// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/cryptography/ECDSA.sol

pragma solidity ^0.5.0;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/PayResolver.sol

pragma solidity ^0.5.1;











/**
 * @title Pay Resolver contract
 * @notice Payment resolver with different payment resolving logics.
 */
contract PayResolver is IPayResolver {
    using SafeMath for uint;
    using ECDSA for bytes32;

    IPayRegistry public payRegistry;
    IVirtContractResolver public virtResolver;

    /**
     * @notice Pay registry constructor
     * @param _registryAddr address of pay registry
     * @param _virtResolverAddr address of virtual contract resolver
     */
    constructor(address _registryAddr, address _virtResolverAddr) public {
        payRegistry = IPayRegistry(_registryAddr);
        virtResolver = IVirtContractResolver(_virtResolverAddr);
    }

    /**
     * @notice Resolve a payment by onchain getting its condition outcomes
     * @dev HASH_LOCK should only be used for establishing multi-hop payments,
     *   and is always required to be true for all transfer function logic types.
     *   a pay with no condition or only true HASH_LOCK conditions will use max transfer amount.
     *   The preimage order should align at the order of HASH_LOCK conditions in condition array.
     * @param _resolvePayRequest bytes of PbChain.ResolvePayByConditionsRequest
     */
    function resolvePaymentByConditions(bytes calldata _resolvePayRequest) external {
        PbChain.ResolvePayByConditionsRequest memory resolvePayRequest = 
            PbChain.decResolvePayByConditionsRequest(_resolvePayRequest);
        PbEntity.ConditionalPay memory pay = PbEntity.decConditionalPay(resolvePayRequest.condPay);

        // onchain resolve this payment and get result
        uint amount;
        PbEntity.TransferFunctionType funcType = pay.transferFunc.logicType;
        if (funcType == PbEntity.TransferFunctionType.BOOLEAN_AND) {
            amount = _calculateBooleanAndPayment(pay, resolvePayRequest.hashPreimages);
        } else if (funcType == PbEntity.TransferFunctionType.BOOLEAN_OR) {
            amount = _calculateBooleanOrPayment(pay, resolvePayRequest.hashPreimages);
        } else if (_isNumericLogic(funcType)) {
            amount = _calculateNumericLogicPayment(pay, resolvePayRequest.hashPreimages, funcType);
        } else {
            // TODO: support more transfer function types
            assert(false);
        }

        bytes32 payHash = keccak256(resolvePayRequest.condPay);
        _resolvePayment(pay, payHash, amount);
    }

    /**
     * @notice Resolve a payment by submitting an offchain vouched result
     * @param _vouchedPayResult bytes of PbEntity.VouchedCondPayResult
     */
    function resolvePaymentByVouchedResult(bytes calldata _vouchedPayResult) external {
        PbEntity.VouchedCondPayResult memory vouchedPayResult = 
            PbEntity.decVouchedCondPayResult(_vouchedPayResult);
        PbEntity.CondPayResult memory payResult = 
            PbEntity.decCondPayResult(vouchedPayResult.condPayResult);
        PbEntity.ConditionalPay memory pay = PbEntity.decConditionalPay(payResult.condPay);

        require(
            payResult.amount <= pay.transferFunc.maxTransfer.receiver.amt,
            "Exceed max transfer amount"
        );
        // check signatures
        bytes32 hash = keccak256(vouchedPayResult.condPayResult).toEthSignedMessageHash();
        address recoveredSrc = hash.recover(vouchedPayResult.sigOfSrc);
        address recoveredDest = hash.recover(vouchedPayResult.sigOfDest);
        require(
            recoveredSrc == address(pay.src) && recoveredDest == address(pay.dest),
            "Check sigs failed"
        );

        bytes32 payHash = keccak256(payResult.condPay);
        _resolvePayment(pay, payHash, payResult.amount);
    }

    /**
     * @notice Internal function of resolving a payment with given amount
     * @param _pay conditional pay
     * @param _payHash hash of serialized condPay
     * @param _amount payment amount to resolve
     */
    function _resolvePayment(
        PbEntity.ConditionalPay memory _pay,
        bytes32 _payHash,
        uint _amount
    )
        internal
    {
        uint blockNumber = block.number;
        require(blockNumber <= _pay.resolveDeadline, "Passed pay resolve deadline in condPay msg");

        bytes32 payId = _calculatePayId(_payHash, address(this));
        (uint currentAmt, uint currentDeadline) = payRegistry.getPayInfo(payId);

        // should never resolve a pay before or not reaching onchain resolve deadline
        require(
            currentDeadline == 0 || blockNumber <= currentDeadline,
            "Passed onchain resolve pay deadline"
        );

        if (currentDeadline > 0) {
            // currentDeadline > 0 implies that this pay has been updated
            // payment amount must be monotone increasing
            require(_amount > currentAmt, "New amount is not larger");

            if (_amount == _pay.transferFunc.maxTransfer.receiver.amt) {
                // set resolve deadline = current block number if amount = max
                payRegistry.setPayInfo(_payHash, _amount, blockNumber);
                emit ResolvePayment(payId, _amount, blockNumber);
            } else {
                // should not update the onchain resolve deadline if not max amount
                payRegistry.setPayAmount(_payHash, _amount);
                emit ResolvePayment(payId, _amount, currentDeadline);
            }
        } else {
            uint newDeadline;
            if (_amount == _pay.transferFunc.maxTransfer.receiver.amt) {
                newDeadline = blockNumber;
            } else {
                newDeadline = Math.min(
                    blockNumber.add(_pay.resolveTimeout),
                    _pay.resolveDeadline
                );
                // 0 is reserved for unresolved status of a payment
                require(newDeadline > 0, "New resolve deadline is 0");
            }

            payRegistry.setPayInfo(_payHash, _amount, newDeadline);
            emit ResolvePayment(payId, _amount, newDeadline);
        }
    }

    /**
     * @notice Calculate the result amount of BooleanAnd payment
     * @param _pay conditional pay
     * @param _preimages preimages for hash lock conditions
     * @return pay amount
     */
    function _calculateBooleanAndPayment(
        PbEntity.ConditionalPay memory _pay,
        bytes[] memory _preimages
    )
        internal
        view
        returns(uint)
    {
        uint j = 0;
        bool hasFalseContractCond = false;
        for (uint i = 0; i < _pay.conditions.length; i++) {
            PbEntity.Condition memory cond = _pay.conditions[i];
            if (cond.conditionType == PbEntity.ConditionType.HASH_LOCK) {
                require(keccak256(_preimages[j]) == cond.hashLock, "Wrong preimage");
                j++;
            } else if (
                cond.conditionType == PbEntity.ConditionType.DEPLOYED_CONTRACT || 
                cond.conditionType == PbEntity.ConditionType.VIRTUAL_CONTRACT
            ) {
                address addr = _getCondAddress(cond);
                IBooleanCond dependent = IBooleanCond(addr);
                require(dependent.isFinalized(cond.argsQueryFinalization), "Condition is not finalized");

                if (!dependent.getOutcome(cond.argsQueryOutcome)) {
                    hasFalseContractCond = true;
                }
            } else {
                assert(false);
            }
        }

        if (hasFalseContractCond) {
            return 0;
        } else {
            return _pay.transferFunc.maxTransfer.receiver.amt;
        }
    }

    /**
     * @notice Calculate the result amount of BooleanOr payment
     * @param _pay conditional pay
     * @param _preimages preimages for hash lock conditions
     * @return pay amount
     */
    function _calculateBooleanOrPayment(
        PbEntity.ConditionalPay memory _pay,
        bytes[] memory _preimages
    )
        internal
        view
        returns(uint)
    {
        uint j = 0;
        // whether there are any contract based conditions, i.e. DEPLOYED_CONTRACT or VIRTUAL_CONTRACT
        bool hasContractCond = false;
        bool hasTrueContractCond = false;
        for (uint i = 0; i < _pay.conditions.length; i++) {
            PbEntity.Condition memory cond = _pay.conditions[i];
            if (cond.conditionType == PbEntity.ConditionType.HASH_LOCK) {
                require(keccak256(_preimages[j]) == cond.hashLock, "Wrong preimage");
                j++;
            } else if (
                cond.conditionType == PbEntity.ConditionType.DEPLOYED_CONTRACT || 
                cond.conditionType == PbEntity.ConditionType.VIRTUAL_CONTRACT
            ) {
                address addr = _getCondAddress(cond);
                IBooleanCond dependent = IBooleanCond(addr);
                require(dependent.isFinalized(cond.argsQueryFinalization), "Condition is not finalized");

                hasContractCond = true;
                if (dependent.getOutcome(cond.argsQueryOutcome)) {
                    hasTrueContractCond = true;
                }
            } else {
                assert(false);
            }
        }

        if (!hasContractCond || hasTrueContractCond) {
            return _pay.transferFunc.maxTransfer.receiver.amt;
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate the result amount of numeric logic payment,
     *   including NUMERIC_ADD, NUMERIC_MAX and NUMERIC_MIN
     * @param _pay conditional pay
     * @param _preimages preimages for hash lock conditions
     * @param _funcType transfer function type
     * @return pay amount
     */
    function _calculateNumericLogicPayment(
        PbEntity.ConditionalPay memory _pay,
        bytes[] memory _preimages,
        PbEntity.TransferFunctionType _funcType
    )
        internal
        view
        returns(uint)
    {
        uint amount = 0;
        uint j = 0;
        bool hasContractCond = false;
        for (uint i = 0; i < _pay.conditions.length; i++) {
            PbEntity.Condition memory cond = _pay.conditions[i];
            if (cond.conditionType == PbEntity.ConditionType.HASH_LOCK) {
                require(keccak256(_preimages[j]) == cond.hashLock, "Wrong preimage");
                j++;
            } else if (
                cond.conditionType == PbEntity.ConditionType.DEPLOYED_CONTRACT || 
                cond.conditionType == PbEntity.ConditionType.VIRTUAL_CONTRACT
            ) {
                address addr = _getCondAddress(cond);
                INumericCond dependent = INumericCond(addr);
                require(dependent.isFinalized(cond.argsQueryFinalization), "Condition is not finalized");

                if (_funcType == PbEntity.TransferFunctionType.NUMERIC_ADD) {
                    amount = amount.add(dependent.getOutcome(cond.argsQueryOutcome));
                } else if (_funcType == PbEntity.TransferFunctionType.NUMERIC_MAX) {
                    amount = Math.max(amount, dependent.getOutcome(cond.argsQueryOutcome));
                } else if (_funcType == PbEntity.TransferFunctionType.NUMERIC_MIN) {
                    if (hasContractCond) {
                        amount = Math.min(amount, dependent.getOutcome(cond.argsQueryOutcome));
                    } else {
                        amount = dependent.getOutcome(cond.argsQueryOutcome);
                    }
                } else {
                    assert(false);
                }
                
                hasContractCond = true;
            } else {
                assert(false);
            }
        }

        if (hasContractCond) {
            require(amount <= _pay.transferFunc.maxTransfer.receiver.amt, "Exceed max transfer amount");
            return amount;
        } else {
            return _pay.transferFunc.maxTransfer.receiver.amt;
        }
    }

    /**
     * @notice Get the contract address of the condition
     * @param _cond condition
     * @return contract address of the condition
     */
    function _getCondAddress(PbEntity.Condition memory _cond) internal view returns(address) {
        // We need to take into account that contract may not be deployed.
        // However, this is automatically handled for us
        // because calling a non-existent function will cause an revert.
        if (_cond.conditionType == PbEntity.ConditionType.DEPLOYED_CONTRACT) {
            return _cond.deployedContractAddress;
        } else if (_cond.conditionType == PbEntity.ConditionType.VIRTUAL_CONTRACT) {
            return virtResolver.resolve(_cond.virtualContractAddress);
        } else {
            assert(false);
        }
    }

    /**
     * @notice Check if a function type is numeric logic
     * @param _funcType transfer function type
     * @return true if it is a numeric logic, otherwise false
     */
    function _isNumericLogic(PbEntity.TransferFunctionType _funcType) internal pure returns(bool) {
        return _funcType == PbEntity.TransferFunctionType.NUMERIC_ADD ||
            _funcType == PbEntity.TransferFunctionType.NUMERIC_MAX ||
            _funcType == PbEntity.TransferFunctionType.NUMERIC_MIN;
    }

    /**
     * @notice Calculate pay id
     * @param _payHash hash of serialized condPay
     * @param _setter payment info setter, i.e. pay resolver
     * @return calculated pay id
     */
    function _calculatePayId(bytes32 _payHash, address _setter) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_payHash, _setter));
    }
}