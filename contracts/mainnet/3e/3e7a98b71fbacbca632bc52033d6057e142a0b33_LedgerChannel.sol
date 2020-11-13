// File: contracts/lib/interface/ICelerWallet.sol

pragma solidity ^0.5.1;

/**
 * @title CelerWallet interface
 */
interface ICelerWallet {
    function create(address[] calldata _owners, address _operator, bytes32 _nonce) external returns(bytes32);

    function depositETH(bytes32 _walletId) external payable;

    function depositERC20(bytes32 _walletId, address _tokenAddress, uint _amount) external;
    
    function withdraw(bytes32 _walletId, address _tokenAddress, address _receiver, uint _amount) external;

    function transferToWallet(bytes32 _fromWalletId, bytes32 _toWalletId, address _tokenAddress, address _receiver, uint _amount) external;

    function transferOperatorship(bytes32 _walletId, address _newOperator) external;

    function proposeNewOperator(bytes32 _walletId, address _newOperator) external;

    function drainToken(address _tokenAddress, address _receiver, uint _amount) external;

    function getWalletOwners(bytes32 _walletId) external view returns(address[] memory);

    function getOperator(bytes32 _walletId) external view returns(address);

    function getBalance(bytes32 _walletId, address _tokenAddress) external view returns(uint);

    function getProposedNewOperator(bytes32 _walletId) external view returns(address);

    function getProposalVote(bytes32 _walletId, address _owner) external view returns(bool);

    event CreateWallet(bytes32 indexed walletId, address[] indexed owners, address indexed operator);

    event DepositToWallet(bytes32 indexed walletId, address indexed tokenAddress, uint amount);

    event WithdrawFromWallet(bytes32 indexed walletId, address indexed tokenAddress, address indexed receiver, uint amount);

    event TransferToWallet(bytes32 indexed fromWalletId, bytes32 indexed toWalletId, address indexed tokenAddress, address receiver, uint amount);

    event ChangeOperator(bytes32 indexed walletId, address indexed oldOperator, address indexed newOperator);

    event ProposeNewOperator(bytes32 indexed walletId, address indexed newOperator, address indexed proposer);

    event DrainToken(address indexed tokenAddress, address indexed receiver, uint amount);
}

// File: contracts/lib/interface/IEthPool.sol

pragma solidity ^0.5.1;

/**
 * @title EthPool interface
 */
interface IEthPool {
    function deposit(address _receiver) external payable;

    function withdraw(uint _value) external;

    function approve(address _spender, uint _value) external returns (bool);

    function transferFrom(address _from, address payable _to, uint _value) external returns (bool);

    function transferToCelerWallet(address _from, address _walletAddr, bytes32 _walletId, uint _value) external returns (bool);

    function increaseAllowance(address _spender, uint _addedValue) external returns (bool);

    function decreaseAllowance(address _spender, uint _subtractedValue) external returns (bool);

    function balanceOf(address _owner) external view returns (uint);

    function allowance(address _owner, address _spender) external view returns (uint);

    event Deposit(address indexed receiver, uint value);
    
    // transfer from "from" account inside EthPool to real "to" address outside EthPool
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint value);
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

// File: contracts/lib/ledgerlib/LedgerStruct.sol

pragma solidity ^0.5.1;





/**
 * @title Ledger Struct Library
 * @notice CelerLedger library defining all used structs
 */
library LedgerStruct {
    enum ChannelStatus { Uninitialized, Operable, Settling, Closed, Migrated }

    struct PeerState {
        uint seqNum;
        // balance sent out to the other peer of the channel, no need to record amtIn
        uint transferOut;
        bytes32 nextPayIdListHash;
        uint lastPayResolveDeadline;
        uint pendingPayOut;
    }

    struct PeerProfile {
        address peerAddr;
        // the (monotone increasing) amount that this peer deposit into this channel
        uint deposit;
        // the (monotone increasing) amount that this peer withdraw from this channel
        uint withdrawal;
        PeerState state;
    }

    struct WithdrawIntent {
        address receiver;
        uint amount;
        uint requestTime;
        bytes32 recipientChannelId;
    }

    // Channel is a representation of the state channel between peers which puts the funds
    // in CelerWallet and is hosted by a CelerLedger. The status of a state channel can
    // be migrated from one CelerLedger instance to another CelerLedger instance with probably
    // different operation logic.
    struct Channel {
        // the time after which peers can confirmSettle and before which peers can intendSettle
        uint settleFinalizedTime;
        uint disputeTimeout;
        PbEntity.TokenInfo token;
        ChannelStatus status;
        // record the new CelerLedger address after channel migration
        address migratedTo;
        // only support 2-peer channel for now
        PeerProfile[2] peerProfiles;
        uint cooperativeWithdrawSeqNum;
        WithdrawIntent withdrawIntent;
    }

    // Ledger is a host to record and operate the activities of many state
    // channels with specific operation logic.
    struct Ledger {
        // ChannelStatus => number of channels
        mapping(uint => uint) channelStatusNums;
        IEthPool ethPool;
        IPayRegistry payRegistry;
        ICelerWallet celerWallet;
        // per channel deposit limits for different tokens
        mapping(address => uint) balanceLimits;
        // whether deposit limits of all tokens have been enabled
        bool balanceLimitsEnabled;
        mapping(bytes32 => Channel) channelMap;
    }
}

// File: contracts/lib/interface/ICelerLedger.sol

pragma solidity ^0.5.1;



/**
 * @title CelerLedger interface
 * @dev any changes in this interface must be synchronized to corresponding libraries
 * @dev events in this interface must be exactly same in corresponding used libraries
 */
interface ICelerLedger {
    /********** LedgerOperation related functions and events **********/
    function openChannel(bytes calldata _openChannelRequest) external payable;

    function deposit(bytes32 _channelId, address _receiver, uint _transferFromAmount) external payable;

    function depositInBatch(
        bytes32[] calldata _channelIds,
        address[] calldata _receivers,
        uint[] calldata _transferFromAmounts
    ) external;

    function snapshotStates(bytes calldata _signedSimplexStateArray) external;

    function intendWithdraw(bytes32 _channelId, uint _amount, bytes32 _recipientChannelId) external;
    
    function confirmWithdraw(bytes32 _channelId) external;

    function vetoWithdraw(bytes32 _channelId) external;
    
    function cooperativeWithdraw(bytes calldata _cooperativeWithdrawRequest) external;
    
    function intendSettle(bytes calldata _signedSimplexStateArray) external;
    
    function clearPays(bytes32 _channelId, address _peerFrom, bytes calldata _payIdList) external;
    
    function confirmSettle(bytes32 _channelId) external;
    
    function cooperativeSettle(bytes calldata _settleRequest) external;
    
    function getChannelStatusNum(uint _channelStatus) external view returns(uint);

    function getEthPool() external view returns(address);

    function getPayRegistry() external view returns(address);

    function getCelerWallet() external view returns(address);

    event OpenChannel(
        bytes32 indexed channelId,
        uint tokenType,
        address indexed tokenAddress,
        // TODO: there is an issue of setting address[2] as indexed. Need to fix and make this indexed
        address[2] peerAddrs,
        uint[2] initialDeposits
    );

    // TODO: there is an issue of setting address[2] as indexed. Need to fix and make this indexed
    event Deposit(bytes32 indexed channelId, address[2] peerAddrs, uint[2] deposits, uint[2] withdrawals);

    event SnapshotStates(bytes32 indexed channelId, uint[2] seqNums);

    event IntendSettle(bytes32 indexed channelId, uint[2] seqNums);

    event ClearOnePay(bytes32 indexed channelId, bytes32 indexed payId, address indexed peerFrom, uint amount);

    event ConfirmSettle(bytes32 indexed channelId, uint[2] settleBalance);

    event ConfirmSettleFail(bytes32 indexed channelId);

    event IntendWithdraw(bytes32 indexed channelId, address indexed receiver, uint amount);

    event ConfirmWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals
    );

    event VetoWithdraw(bytes32 indexed channelId);

    event CooperativeWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals,
        uint seqNum
    );

    event CooperativeSettle(bytes32 indexed channelId, uint[2] settleBalance);
    /********** End of LedgerOperation related functions and events **********/


    /********** LedgerChannel related functions and events **********/
    function getSettleFinalizedTime(bytes32 _channelId) external view returns(uint);

    function getTokenContract(bytes32 _channelId) external view returns(address);

    function getTokenType(bytes32 _channelId) external view returns(PbEntity.TokenType);

    function getChannelStatus(bytes32 _channelId) external view returns(LedgerStruct.ChannelStatus);

    function getCooperativeWithdrawSeqNum(bytes32 _channelId) external view returns(uint);

    function getTotalBalance(bytes32 _channelId) external view returns(uint);

    function getBalanceMap(bytes32 _channelId) external view returns(address[2] memory, uint[2] memory, uint[2] memory);

    function getChannelMigrationArgs(bytes32 _channelId) external view returns(uint, uint, address, uint);

    function getPeersMigrationInfo(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory
    );

    function getDisputeTimeout(bytes32 _channelId) external view returns(uint);

    function getMigratedTo(bytes32 _channelId) external view returns(address);

    function getStateSeqNumMap(bytes32 _channelId) external view returns(address[2] memory, uint[2] memory);

    function getTransferOutMap(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory
    );

    function getNextPayIdListHashMap(bytes32 _channelId) external view returns(
        address[2] memory,
        bytes32[2] memory
    );

    function getLastPayResolveDeadlineMap(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory
    );

    function getPendingPayOutMap(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory
    );

    function getWithdrawIntent(bytes32 _channelId) external view returns(address, uint, uint, bytes32);
    /********** End of LedgerChannel related functions and events **********/


    /********** LedgerBalanceLimit related functions and events **********/
    function setBalanceLimits(address[] calldata _tokenAddrs, uint[] calldata _limits) external;

    function disableBalanceLimits() external;

    function enableBalanceLimits() external;

    function getBalanceLimit(address _tokenAddr) external view returns(uint);

    function getBalanceLimitsEnabled() external view returns(bool);
    /********** End of LedgerBalanceLimit related functions and events **********/


    /********** LedgerMigrate related functions and events **********/
    function migrateChannelTo(bytes calldata _migrationRequest) external returns(bytes32);

    function migrateChannelFrom(address _fromLedgerAddr, bytes calldata _migrationRequest) external;

    event MigrateChannelTo(bytes32 indexed channelId, address indexed newLedgerAddr);

    event MigrateChannelFrom(bytes32 indexed channelId, address indexed oldLedgerAddr);
    /********** End of LedgerMigrate related functions and events **********/
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

// File: contracts/lib/ledgerlib/LedgerChannel.sol

pragma solidity ^0.5.1;






/**
 * @title Ledger Channel Library
 * @notice CelerLedger library about Channel struct
 * @dev this can be included in LedgerOperation to save some gas,
 *   however, keep this for now for clearness.
 */
library LedgerChannel {
    using SafeMath for uint;
    using ECDSA for bytes32;

    /**
     * @notice Get channel confirm settle open time
     * @param _c the channel being used
     * @return channel confirm settle open time
     */
    function getSettleFinalizedTime(LedgerStruct.Channel storage _c) public view returns(uint) {
        return _c.settleFinalizedTime;
    }

    /**
     * @notice Get channel token contract address
     * @param _c the channel being used
     * @return channel token contract address
     */
    function getTokenContract(LedgerStruct.Channel storage _c) public view returns(address) {
        return _c.token.tokenAddress;
    }

    /**
     * @notice Get channel token type
     * @param _c the channel being used
     * @return channel token type
     */
    function getTokenType(LedgerStruct.Channel storage _c) public view returns(PbEntity.TokenType) {
        return _c.token.tokenType;
    }

    /**
     * @notice Get channel status
     * @param _c the channel being used
     * @return channel status
     */
    function getChannelStatus(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(LedgerStruct.ChannelStatus)
    {
        return _c.status;
    }

    /**
     * @notice Get cooperative withdraw seqNum
     * @param _c the channel being used
     * @return cooperative withdraw seqNum
     */
    function getCooperativeWithdrawSeqNum(LedgerStruct.Channel storage _c) public view returns(uint) {
        return _c.cooperativeWithdrawSeqNum;
    }

    /**
     * @notice Return one channel's total balance amount
     * @param _c the channel
     * @return channel's balance amount
     */
    function getTotalBalance(LedgerStruct.Channel storage _c) public view returns(uint) {
        uint balance = _c.peerProfiles[0].deposit
            .add(_c.peerProfiles[1].deposit)
            .sub(_c.peerProfiles[0].withdrawal)
            .sub(_c.peerProfiles[1].withdrawal);
        return balance;
    }

    /**
     * @notice Return one channel's balance info (depositMap and withdrawalMap)
     * @dev Solidity can't directly return an array of struct for now
     * @param _c the channel
     * @return addresses of peers in the channel
     * @return corresponding deposits of the peers (with matched index)
     * @return corresponding withdrawals of the peers (with matched index)
     */
    function getBalanceMap(LedgerStruct.Channel storage _c) public view
        returns(address[2] memory, uint[2] memory, uint[2] memory)
    {
        address[2] memory peerAddrs = [_c.peerProfiles[0].peerAddr, _c.peerProfiles[1].peerAddr];
        uint[2] memory deposits = [_c.peerProfiles[0].deposit, _c.peerProfiles[1].deposit];
        uint[2] memory withdrawals = [_c.peerProfiles[0].withdrawal, _c.peerProfiles[1].withdrawal];
        return (peerAddrs, deposits, withdrawals);
    }

    /**
     * @notice Return channel-level migration arguments
     * @param _c the channel to be viewed
     * @return channel dispute timeout
     * @return channel tokey type converted to uint
     * @return channel token address
     * @return sequence number of cooperative withdraw
     * @dev related to Ledger Migration
     */
    function getChannelMigrationArgs(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(uint, uint, address, uint)
    {
        return (
            _c.disputeTimeout,
            uint(_c.token.tokenType),
            _c.token.tokenAddress,
            _c.cooperativeWithdrawSeqNum
        );
    }

    /**
     * @notice Return migration info of the peers in the channel
     * @param _c the channel to be viewed
     * @return peers' addresses
     * @return peers' deposits
     * @return peers' withdrawals
     * @return peers' state sequence numbers
     * @return peers' transferOut map
     * @return peers' pendingPayOut map
     * @dev related to Ledger Migration
     */
    function getPeersMigrationInfo(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(
        address[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory
    )
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].deposit, peerProfiles[1].deposit],
            [peerProfiles[0].withdrawal, peerProfiles[1].withdrawal],
            [peerProfiles[0].state.seqNum, peerProfiles[1].state.seqNum],
            [peerProfiles[0].state.transferOut, peerProfiles[1].state.transferOut],
            [peerProfiles[0].state.pendingPayOut, peerProfiles[1].state.pendingPayOut]
        );
    }

    /**
     * @notice Return channel's dispute timeout
     * @param _c the channel to be viewed
     * @return channel's dispute timeout
     */
    function getDisputeTimeout(LedgerStruct.Channel storage _c) external view returns(uint) {
        return _c.disputeTimeout;
    }

    /**
     * @notice Return channel's migratedTo address
     * @param _c the channel to be viewed
     * @return channel's migratedTo address
     */
    function getMigratedTo(LedgerStruct.Channel storage _c) external view returns(address) {
        return _c.migratedTo;
    }

    /**
     * @notice Return state seqNum map of a duplex channel
     * @param _c the channel to be viewed
     * @return peers' addresses
     * @return two simplex state sequence numbers
     */
    function getStateSeqNumMap(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.seqNum, peerProfiles[1].state.seqNum]
        );
    }

    /**
     * @notice Return transferOut map of a duplex channel
     * @param _c the channel to be viewed
     * @return peers' addresses
     * @return transferOuts of two simplex channels
     */
    function getTransferOutMap(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.transferOut, peerProfiles[1].state.transferOut]
        );
    }

    /**
     * @notice Return nextPayIdListHash map of a duplex channel
     * @param _c the channel to be viewed
     * @return peers' addresses
     * @return nextPayIdListHashes of two simplex channels
     */
    function getNextPayIdListHashMap(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(address[2] memory, bytes32[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.nextPayIdListHash, peerProfiles[1].state.nextPayIdListHash]
        );
    }

    /**
     * @notice Return lastPayResolveDeadline map of a duplex channel
     * @param _c the channel to be viewed
     * @return peers' addresses
     * @return lastPayResolveDeadlines of two simplex channels
     */
    function getLastPayResolveDeadlineMap(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.lastPayResolveDeadline, peerProfiles[1].state.lastPayResolveDeadline]
        );
    }

    /**
     * @notice Return pendingPayOut map of a duplex channel
     * @param _c the channel to be viewed
     * @return peers' addresses
     * @return pendingPayOuts of two simplex channels
     */
    function getPendingPayOutMap(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.pendingPayOut, peerProfiles[1].state.pendingPayOut]
        );
    }

    /**
     * @notice Return the withdraw intent info of the channel
     * @param _c the channel to be viewed
     * @return receiver of the withdraw intent
     * @return amount of the withdraw intent
     * @return requestTime of the withdraw intent
     * @return recipientChannelId of the withdraw intent
     */
    function getWithdrawIntent(
        LedgerStruct.Channel storage _c
    )
        external
        view
        returns(address, uint, uint, bytes32)
    {
        LedgerStruct.WithdrawIntent memory withdrawIntent = _c.withdrawIntent;
        return (
            withdrawIntent.receiver,
            withdrawIntent.amount,
            withdrawIntent.requestTime,
            withdrawIntent.recipientChannelId
        );
    }

    /**
     * @notice Import channel migration arguments from old CelerLedger contract
     * @param _c the channel to be viewed
     * @param _fromLedgerAddr old ledger address to import channel config from
     * @param _channelId ID of the channel to be viewed
     * @dev related to Ledger Migration
     */
    function _importChannelMigrationArgs(
        LedgerStruct.Channel storage _c,
        address payable _fromLedgerAddr,
        bytes32 _channelId
    )
        internal
    {
        uint tokenType;
        (
            _c.disputeTimeout,
            tokenType,
            _c.token.tokenAddress,
            _c.cooperativeWithdrawSeqNum
        ) = ICelerLedger(_fromLedgerAddr).getChannelMigrationArgs(_channelId);
        _c.token.tokenType = PbEntity.TokenType(tokenType);
    }

    /**
     * @notice import channel peers' migration info from old CelerLedger contract
     * @param _c the channel to be viewed
     * @param _fromLedgerAddr old ledger address to import channel config from
     * @param _channelId ID of the channel to be viewed
     * @dev related to Ledger Migration
     */
    function _importPeersMigrationInfo(
        LedgerStruct.Channel storage _c,
        address payable _fromLedgerAddr,
        bytes32 _channelId
    )
        internal
    {
        (
            address[2] memory peersAddrs,
            uint[2] memory deposits,
            uint[2] memory withdrawals,
            uint[2] memory seqNums,
            uint[2] memory transferOuts,
            uint[2] memory pendingPayOuts
        ) = ICelerLedger(_fromLedgerAddr).getPeersMigrationInfo(_channelId);

        for (uint i = 0; i < 2; i++) {
            LedgerStruct.PeerProfile storage peerProfile = _c.peerProfiles[i];
            peerProfile.peerAddr = peersAddrs[i];
            peerProfile.deposit = deposits[i];
            peerProfile.withdrawal = withdrawals[i];
            peerProfile.state.seqNum = seqNums[i];
            peerProfile.state.transferOut = transferOuts[i];
            peerProfile.state.pendingPayOut = pendingPayOuts[i];
        }
    }

    /**
     * @notice Get the seqNums of two simplex channel states
     * @param _c the channel
     */
    function _getStateSeqNums(LedgerStruct.Channel storage _c) internal view returns(uint[2] memory) {
        return [_c.peerProfiles[0].state.seqNum, _c.peerProfiles[1].state.seqNum];
    }

    /**
     * @notice Check if _addr is one of the peers in channel _c
     * @param _c the channel
     * @param _addr the address to check
     * @return is peer or not
     */
    function _isPeer(LedgerStruct.Channel storage _c, address _addr) internal view returns(bool) {
        return _addr == _c.peerProfiles[0].peerAddr || _addr == _c.peerProfiles[1].peerAddr;
    }

    /**
     * @notice Get peer's ID
     * @param _c the channel
     * @param _peer address of peer
     * @return peer's ID
     */
     function _getPeerId(LedgerStruct.Channel storage _c, address _peer) internal view returns(uint) {
        if (_peer == _c.peerProfiles[0].peerAddr) {
            return 0;
        } else if (_peer == _c.peerProfiles[1].peerAddr) {
            return 1;
        } else {
            revert("Nonexist peer");
        }
    }

    /**
     * @notice Check the correctness of one peer's signature
     * @param _c the channel
     * @param _h the hash of the message signed by the peer
     * @param _sig signature of the peer
     * @return message is signed by one of the peers or not
     */
    function _checkSingleSignature(
        LedgerStruct.Channel storage _c,
        bytes32 _h,
        bytes memory _sig
    )
        internal
        view
        returns(bool)
    {
        address addr = _h.toEthSignedMessageHash().recover(_sig);
        return _isPeer(_c, addr);
    }

    /**
     * @notice Check the correctness of the co-signatures
     * @param _c the channel
     * @param _h the hash of the message signed by the peers
     * @param _sigs signatures of the peers
     * @return message are signed by both peers or not
     */
    function _checkCoSignatures(
        LedgerStruct.Channel storage _c,
        bytes32 _h,
        bytes[] memory _sigs
    )
        internal
        view
        returns(bool)
    {
        if (_sigs.length != 2) {
            return false;
        }

        // check signature
        bytes32 hash = _h.toEthSignedMessageHash();
        address addr;
        for (uint i = 0; i < 2; i++) {
            addr = hash.recover(_sigs[i]);
            // enforce the order of sigs consistent with ascending addresses
            if (addr != _c.peerProfiles[i].peerAddr) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Validate channel final balance
     * @dev settleBalance = deposit - withdrawal + transferIn - transferOut
     * @param _c the channel
     * @return (balance is valid, settle balance)
     */
    function _validateSettleBalance(LedgerStruct.Channel storage _c)
        internal
        view
        returns(bool, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        uint[2] memory settleBalance = [
            peerProfiles[0].deposit.add(peerProfiles[1].state.transferOut),
            peerProfiles[1].deposit.add(peerProfiles[0].state.transferOut)
        ];
        for (uint i = 0; i < 2; i++) {
            uint subAmt = peerProfiles[i].state.transferOut.add(peerProfiles[i].withdrawal);
            if (settleBalance[i] < subAmt) {
                return (false, [uint(0), uint(0)]);
            }

            settleBalance[i] = settleBalance[i].sub(subAmt);
        }

        return (true, settleBalance);
    }

    /**
     * @notice Update record of one peer's withdrawal amount
     * @param _c the channel
     * @param _receiver receiver of this new withdrawal
     * @param _amount amount of this new withdrawal
     * @param _checkBalance check the balance if this is true
     */
    function _addWithdrawal(
        LedgerStruct.Channel storage _c,
        address _receiver,
        uint _amount,
        bool _checkBalance
    )
        internal
    {
        // this implicitly require receiver be a peer
        uint rid = _getPeerId(_c, _receiver);
        _c.peerProfiles[rid].withdrawal = _c.peerProfiles[rid].withdrawal.add(_amount);
        if (_checkBalance) {
            require(getTotalBalance(_c) >= 0);
        }
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

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: contracts/lib/ledgerlib/LedgerOperation.sol

pragma solidity ^0.5.1;










/**
 * @title Ledger Operation Library
 * @notice CelerLedger library of basic ledger operations
 * @dev This library doesn't need "withdraw pattern" because both peers must be
 *   External Owned Accounts(EOA) since their signatures are required in openChannel.
 */
library LedgerOperation {
    using SafeMath for uint;
    using Address for address;
    using SafeERC20 for IERC20;
    using LedgerChannel for LedgerStruct.Channel;

    /**
     * @notice Open a state channel through auth withdraw message
     * @dev library function can't be payable but can read msg.value in caller's context
     * @param _self storage data of CelerLedger contract
     * @param _openRequest bytes of open channel request message
     */
    function openChannel(
        LedgerStruct.Ledger storage _self,
        bytes calldata _openRequest
    )
        external
    {
        PbChain.OpenChannelRequest memory openRequest =
            PbChain.decOpenChannelRequest(_openRequest);
        PbEntity.PaymentChannelInitializer memory channelInitializer =
            PbEntity.decPaymentChannelInitializer(openRequest.channelInitializer);
        require(channelInitializer.initDistribution.distribution.length == 2, "Wrong length");
        require(block.number <= channelInitializer.openDeadline, "Open deadline passed");
        
        PbEntity.TokenInfo memory token = channelInitializer.initDistribution.token;
        uint[2] memory amounts = [
            channelInitializer.initDistribution.distribution[0].amt,
            channelInitializer.initDistribution.distribution[1].amt
        ];
        address[2] memory peerAddrs = [
            channelInitializer.initDistribution.distribution[0].account,
            channelInitializer.initDistribution.distribution[1].account
        ];
        // enforce ascending order of peers' addresses to simplify contract code
        require(peerAddrs[0] < peerAddrs[1], "Peer addrs are not ascending");

        ICelerWallet celerWallet = _self.celerWallet;
        bytes32 h = keccak256(openRequest.channelInitializer);
        (
            bytes32 channelId,
            LedgerStruct.Channel storage c
        ) = _createWallet(_self, celerWallet, peerAddrs, h);

        c.disputeTimeout = channelInitializer.disputeTimeout;
        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Operable);
        c.token = _validateTokenInfo(token);
        c.peerProfiles[0].peerAddr = peerAddrs[0];
        c.peerProfiles[0].deposit = amounts[0];
        c.peerProfiles[1].peerAddr = peerAddrs[1];
        c.peerProfiles[1].deposit = amounts[1];

        require(c._checkCoSignatures(h, openRequest.sigs), "Check co-sigs failed");

        emit OpenChannel(channelId, uint(token.tokenType), token.tokenAddress, peerAddrs, amounts);

        uint amtSum = amounts[0].add(amounts[1]);
        // if total deposit is 0
        if (amtSum == 0) {
            require(msg.value == 0, "msg.value is not 0");
            return;
        }

        // if total deposit is larger than 0
        if (_self.balanceLimitsEnabled) {
            require(amtSum <= _self.balanceLimits[token.tokenAddress], "Balance exceeds limit");
        }

        if (token.tokenType == PbEntity.TokenType.ETH) {
            uint msgValueReceiver = channelInitializer.msgValueReceiver;
            require(msg.value == amounts[msgValueReceiver], "msg.value mismatch");
            if (amounts[msgValueReceiver] > 0) {
                celerWallet.depositETH.value(amounts[msgValueReceiver])(channelId);
            }

            // peer ID of non-msgValueReceiver
            uint pid = uint(1).sub(msgValueReceiver);
            if (amounts[pid] > 0) {
                _self.ethPool.transferToCelerWallet(
                    peerAddrs[pid],
                    address(celerWallet),
                    channelId,
                    amounts[pid]
                );
            }
        } else if (token.tokenType == PbEntity.TokenType.ERC20) {
            require(msg.value == 0, "msg.value is not 0");

            IERC20 erc20Token = IERC20(token.tokenAddress);
            for (uint i = 0; i < 2; i++) {
                if (amounts[i] == 0) { continue; }

                erc20Token.safeTransferFrom(peerAddrs[i], address(this), amounts[i]);
            }
            erc20Token.safeApprove(address(celerWallet), amtSum);
            celerWallet.depositERC20(channelId, address(erc20Token), amtSum);
        } else {
            assert(false);
        }
    }

    /**
     * @notice Deposit ETH or ERC20 tokens into the channel
     * @dev total deposit amount = msg.value(must be 0 for ERC20) + _transferFromAmount.
     *   library function can't be payable but can read msg.value in caller's context.
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     * @param _receiver address of the receiver
     * @param _transferFromAmount amount of funds to be transfered from EthPool for ETH
     *   or ERC20 contract for ERC20 tokens
     */
    function deposit(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _receiver,
        uint _transferFromAmount
    )
        external
    {
        uint msgValue = msg.value;
        // this implicitly require _receiver be a peer
        _addDeposit(_self, _channelId, _receiver, _transferFromAmount.add(msgValue));
        
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        if (c.token.tokenType == PbEntity.TokenType.ETH) {
            if (msgValue > 0) {
                _self.celerWallet.depositETH.value(msgValue)(_channelId);
            }
            if (_transferFromAmount > 0) {
                _self.ethPool.transferToCelerWallet(
                    msg.sender,
                    address(_self.celerWallet),
                    _channelId,
                    _transferFromAmount
                );
            }
        } else if (c.token.tokenType == PbEntity.TokenType.ERC20) {
            require(msgValue == 0, "msg.value is not 0");

            IERC20 erc20Token = IERC20(c.token.tokenAddress);
            erc20Token.safeTransferFrom(msg.sender, address(this), _transferFromAmount);
            erc20Token.safeApprove(address(_self.celerWallet), _transferFromAmount);
            _self.celerWallet.depositERC20(_channelId, address(erc20Token), _transferFromAmount);
        } else {
            assert(false);
        }
    }

    /**
     * @notice Store signed simplex states on-chain as checkpoints
     * @dev simplex states in this array are not necessarily in the same channel,
     *   which means snapshotStates natively supports multi-channel batch processing.
     *   This function only updates seqNum, transferOut, pendingPayOut of each on-chain
     *   simplex state. It can't ensure that the pending pays will be cleared during
     *   settling the channel, which requires users call intendSettle with the same state.
     *   TODO: wait for Solidity's support to replace SignedSimplexStateArray with bytes[].
     * @param _self storage data of CelerLedger contract
     * @param _signedSimplexStateArray bytes of SignedSimplexStateArray message
     */
    function snapshotStates(
        LedgerStruct.Ledger storage _self,
        bytes calldata _signedSimplexStateArray
    )
        external
    {
        PbChain.SignedSimplexStateArray memory signedSimplexStateArray =
            PbChain.decSignedSimplexStateArray(_signedSimplexStateArray);
        uint simplexStatesNum = signedSimplexStateArray.signedSimplexStates.length;

        // snapshot each state
        PbEntity.SimplexPaymentChannel memory simplexState =
            PbEntity.decSimplexPaymentChannel(signedSimplexStateArray.signedSimplexStates[0].simplexState);
        for (uint i = 0; i < simplexStatesNum; i++) {
            bytes32 currentChannelId = simplexState.channelId;
            LedgerStruct.Channel storage c = _self.channelMap[currentChannelId];

            require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");

            bytes32 stateHash = keccak256(signedSimplexStateArray.signedSimplexStates[i].simplexState);
            bytes[] memory sigs = signedSimplexStateArray.signedSimplexStates[i].sigs;
            require(c._checkCoSignatures(stateHash, sigs), "Check co-sigs failed");
            uint peerFromId = c._getPeerId(simplexState.peerFrom);
            LedgerStruct.PeerState storage state = c.peerProfiles[peerFromId].state;
            require(simplexState.seqNum > state.seqNum, "seqNum error");

            // no need to update nextPayIdListHash and lastPayResolveDeadline for snapshot purpose
            state.seqNum = simplexState.seqNum;
            state.transferOut = simplexState.transferToPeer.receiver.amt;
            state.pendingPayOut = simplexState.totalPendingAmount;

            if (i == simplexStatesNum.sub(1)) {
                emit SnapshotStates(currentChannelId, c._getStateSeqNums());
            } else if (i < simplexStatesNum.sub(1)) {
                simplexState = PbEntity.decSimplexPaymentChannel(
                    signedSimplexStateArray.signedSimplexStates[i+1].simplexState
                );
                // enforce channelIds of simplex states are ascending
                require(currentChannelId <= simplexState.channelId, "Non-ascending channelIds");
                if (currentChannelId < simplexState.channelId) {
                    emit SnapshotStates(currentChannelId, c._getStateSeqNums());
                }
            } else {
                assert(false);
            }
        }
    }

    /**
     * @notice Intend to withdraw funds from channel
     * @dev only peers can call intendWithdraw
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     * @param _amount amount of funds to withdraw
     * @param _recipientChannelId withdraw to receiver address if 0,
     *   otherwise deposit to receiver address in the recipient channel
     */
    function intendWithdraw(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        uint _amount,
        bytes32 _recipientChannelId
    )
        external
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        LedgerStruct.PeerProfile[2] storage peerProfiles = c.peerProfiles;
        LedgerStruct.WithdrawIntent storage withdrawIntent = c.withdrawIntent;
        address receiver = msg.sender;
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        // withdrawIntent.receiver is address(0) if and only if there is no pending WithdrawIntent,
        // because withdrawIntent.receiver may only be set as msg.sender which can't be address(0).
        require(withdrawIntent.receiver == address(0), "Pending withdraw intent exists");

        // check withdraw limit
        // this implicitly requires receiver be a peer
        uint rid = c._getPeerId(receiver);
        uint pid = uint(1).sub(rid);
        uint withdrawLimit = peerProfiles[rid].deposit
            .add(peerProfiles[pid].state.transferOut)
            .sub(peerProfiles[rid].withdrawal)
            .sub(peerProfiles[rid].state.transferOut)
            .sub(peerProfiles[rid].state.pendingPayOut);
        require(_amount <= withdrawLimit, "Exceed withdraw limit");

        withdrawIntent.receiver = receiver;
        withdrawIntent.amount = _amount;
        withdrawIntent.requestTime = block.number;
        withdrawIntent.recipientChannelId = _recipientChannelId;

        emit IntendWithdraw(_channelId, receiver, _amount);
    }

    /**
     * @notice Confirm channel withdrawal
     * @dev anyone can confirm a withdrawal intent
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     */
    function confirmWithdraw(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId
    )
        external
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        require(c.withdrawIntent.receiver != address(0), "No pending withdraw intent");
        require(
            block.number >= c.withdrawIntent.requestTime.add(c.disputeTimeout),
            "Dispute not timeout"
        );

        address receiver = c.withdrawIntent.receiver;
        uint amount = c.withdrawIntent.amount;
        bytes32 recipientChannelId = c.withdrawIntent.recipientChannelId;
        delete c.withdrawIntent;

        // don't need to check balance because intendWithdraw() has already checked withdraw limit
        // this implicitly require receiver be a peer
        c._addWithdrawal(receiver, amount, false);
        
        (, uint[2] memory deposits, uint[2] memory withdrawals) = c.getBalanceMap();
        emit ConfirmWithdraw(_channelId, amount, receiver, recipientChannelId, deposits, withdrawals);

        _withdrawFunds(_self, _channelId, receiver, amount, recipientChannelId);
    }

    /**
     * @notice Veto current withdrawal intent
     * @dev only peers can veto a withdrawal intent;
     *   peers can veto a withdrawal intent even after (requestTime + disputeTimeout)
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     */
    function vetoWithdraw(LedgerStruct.Ledger storage _self, bytes32 _channelId) external {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        require(c.withdrawIntent.receiver != address(0), "No pending withdraw intent");
        require(c._isPeer(msg.sender), "msg.sender is not peer");

        delete c.withdrawIntent;

        emit VetoWithdraw(_channelId);
    }

    /**
     * @notice Cooperatively withdraw specific amount of deposit
     * @param _self storage data of CelerLedger contract
     * @param _cooperativeWithdrawRequest bytes of cooperative withdraw request message
     */
    function cooperativeWithdraw(
        LedgerStruct.Ledger storage _self,
        bytes calldata _cooperativeWithdrawRequest
    )
        external
    {
        PbChain.CooperativeWithdrawRequest memory cooperativeWithdrawRequest =
            PbChain.decCooperativeWithdrawRequest(_cooperativeWithdrawRequest);
        PbEntity.CooperativeWithdrawInfo memory withdrawInfo =
            PbEntity.decCooperativeWithdrawInfo(cooperativeWithdrawRequest.withdrawInfo);
        bytes32 channelId = withdrawInfo.channelId;
        bytes32 recipientChannelId = withdrawInfo.recipientChannelId;
        LedgerStruct.Channel storage c = _self.channelMap[channelId];

        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        bytes32 h = keccak256(cooperativeWithdrawRequest.withdrawInfo);
        require(
            c._checkCoSignatures(h, cooperativeWithdrawRequest.sigs),
            "Check co-sigs failed"
        );
        // require an increment of exactly 1 for seqNum of each cooperative withdraw request
        require(
            withdrawInfo.seqNum.sub(c.cooperativeWithdrawSeqNum) == 1,
            "seqNum error"
        );
        require(block.number <= withdrawInfo.withdrawDeadline, "Withdraw deadline passed");

        address receiver = withdrawInfo.withdraw.account;
        c.cooperativeWithdrawSeqNum = withdrawInfo.seqNum;
        uint amount = withdrawInfo.withdraw.amt;

        // this implicitly require receiver be a peer
        c._addWithdrawal(receiver, amount, true);

        (, uint[2] memory deposits, uint[2] memory withdrawals) = c.getBalanceMap();
        emit CooperativeWithdraw(
            channelId,
            amount,
            receiver,
            recipientChannelId,
            deposits,
            withdrawals,
            withdrawInfo.seqNum
        );

        _withdrawFunds(_self, channelId, receiver, amount, recipientChannelId);
    }

    /**
     * @notice Intend to settle channel(s) with an array of signed simplex states
     * @dev simplex states in this array are not necessarily in the same channel,
     *   which means intendSettle natively supports multi-channel batch processing.
     *   A simplex state with non-zero seqNum (non-null state) must be co-signed by both peers,
     *   while a simplex state with seqNum=0 (null state) only needs to be signed by one peer.
     *   TODO: wait for Solidity's support to replace SignedSimplexStateArray with bytes[].
     * @param _self storage data of CelerLedger contract
     * @param _signedSimplexStateArray bytes of SignedSimplexStateArray message
     */
    function intendSettle(
        LedgerStruct.Ledger storage _self,
        bytes calldata _signedSimplexStateArray
    )
        external
    {
        PbChain.SignedSimplexStateArray memory signedSimplexStateArray =
            PbChain.decSignedSimplexStateArray(_signedSimplexStateArray);
        uint simplexStatesNum = signedSimplexStateArray.signedSimplexStates.length;

        PbEntity.SimplexPaymentChannel memory simplexState =
            PbEntity.decSimplexPaymentChannel(signedSimplexStateArray.signedSimplexStates[0].simplexState);
        for (uint i = 0; i < simplexStatesNum; i++) {
            bytes32 currentChannelId = simplexState.channelId;
            LedgerStruct.Channel storage c = _self.channelMap[currentChannelId];
            require(
                c.status == LedgerStruct.ChannelStatus.Operable ||
                c.status == LedgerStruct.ChannelStatus.Settling,
                "Channel status error"
            );
            require(
                c.settleFinalizedTime == 0 || block.number < c.settleFinalizedTime,
                "Settle has already finalized"
            );
            
            bytes32 stateHash = keccak256(signedSimplexStateArray.signedSimplexStates[i].simplexState);
            bytes[] memory sigs = signedSimplexStateArray.signedSimplexStates[i].sigs;

            if (simplexState.seqNum > 0) {  // non-null state
                require(c._checkCoSignatures(stateHash, sigs), "Check co-sigs failed");
                uint peerFromId = c._getPeerId(simplexState.peerFrom);
                LedgerStruct.PeerState storage state = c.peerProfiles[peerFromId].state;
                // ensure each state can be intendSettle at most once
                if (c.status == LedgerStruct.ChannelStatus.Operable) {
                    // "==" is the case of cooperative on-chain checkpoint
                    require(simplexState.seqNum >= state.seqNum, "seqNum error");
                } else if (c.status == LedgerStruct.ChannelStatus.Settling) {
                    require(simplexState.seqNum > state.seqNum, "seqNum error");
                } else {
                    assert(false);
                }

                // update simplexState-dependent fields
                // no need to update pendingPayOut since channel settle process doesn't use it
                state.seqNum = simplexState.seqNum;
                state.transferOut = simplexState.transferToPeer.receiver.amt;
                state.nextPayIdListHash = simplexState.pendingPayIds.nextListHash;
                state.lastPayResolveDeadline = simplexState.lastPayResolveDeadline;
                _clearPays(_self, currentChannelId, peerFromId, simplexState.pendingPayIds.payIds);
            } else if (simplexState.seqNum == 0) {  // null state
                // this implies both stored seqNums are 0
                require(c.settleFinalizedTime == 0, "intendSettle before");
                require(
                    sigs.length == 1 && c._checkSingleSignature(stateHash, sigs[0]),
                    "Check sig failed"
                );
            } else {
                assert(false);
            }

            if (i == simplexStatesNum.sub(1)) {
                _updateOverallStatesByIntendState(_self, currentChannelId);
            } else if (i < simplexStatesNum.sub(1)) {
                simplexState = PbEntity.decSimplexPaymentChannel(
                    signedSimplexStateArray.signedSimplexStates[i+1].simplexState
                );
                // enforce channelIds of simplex states are ascending
                require(currentChannelId <= simplexState.channelId, "Non-ascending channelIds");
                if (currentChannelId < simplexState.channelId) {
                    _updateOverallStatesByIntendState(_self, currentChannelId);
                }
            } else {
                assert(false);
            }
        }
    }

    /**
     * @notice Read payment results and add results to corresponding simplex payment channel
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     * @param _peerFrom address of the peer who send out funds
     * @param _payIdList bytes of a pay id list
     */
    function clearPays(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _peerFrom,
        bytes calldata _payIdList
    )
        external
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Settling, "Channel status error");
        uint peerFromId = c._getPeerId(_peerFrom);

        bytes32 listHash = keccak256(_payIdList);
        LedgerStruct.PeerState storage state = c.peerProfiles[peerFromId].state;
        require(state.nextPayIdListHash == listHash, "List hash mismatch");

        PbEntity.PayIdList memory payIdList = PbEntity.decPayIdList(_payIdList);
        state.nextPayIdListHash = payIdList.nextListHash;
        _clearPays(_self, _channelId, peerFromId, payIdList.payIds);
    }

    /**
     * @notice Confirm channel settlement
     * @dev This must be alled after settleFinalizedTime
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     */
    function confirmSettle(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId
    )
        external
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        LedgerStruct.PeerProfile[2] storage peerProfiles = c.peerProfiles;
        uint blockNumber = block.number;
        require(c.status == LedgerStruct.ChannelStatus.Settling, "Channel status error");
        // require no new intendSettle can be called
        require(blockNumber >= c.settleFinalizedTime, "Settle is not finalized");

        // require channel status of current intendSettle has been finalized,
        // namely all payments have already been either cleared or expired
        // TODO: here we should use (lastPayResolveDeadline + clear safe margin)
        //   instead of lastPayResolveDeadline to avoid race condition between clearPays
        //   and confirmSettle, which may lead to different settle balance. Add this safe
        //   margin to the value of lastPayResolveDeadline for now as a temporary solution.
        require(
            (peerProfiles[0].state.nextPayIdListHash == bytes32(0) ||
                blockNumber > peerProfiles[0].state.lastPayResolveDeadline) &&
            (peerProfiles[1].state.nextPayIdListHash == bytes32(0) ||
                blockNumber > peerProfiles[1].state.lastPayResolveDeadline),
            "Payments are not finalized"
        );

        (bool validBalance, uint[2] memory settleBalance) = c._validateSettleBalance();
        if (!validBalance) {
            _resetDuplexState(_self, c);
            emit ConfirmSettleFail(_channelId);
            return;
        }

        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Closed);

        emit ConfirmSettle(_channelId, settleBalance);

        // Withdrawal from Contracts pattern is needless here,
        // because peers need to sign messages which implies that they can't be contracts
        _batchTransferOut(
            _self,
            _channelId,
            c.token.tokenAddress,
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            settleBalance
        );
    }

    /**
     * @notice Cooperatively settle the channel
     * @param _self storage data of CelerLedger contract
     * @param _settleRequest bytes of cooperative settle request message
     */
    function cooperativeSettle(
        LedgerStruct.Ledger storage _self,
        bytes calldata _settleRequest
    )
        external
    {
        PbChain.CooperativeSettleRequest memory settleRequest =
            PbChain.decCooperativeSettleRequest(_settleRequest);
        PbEntity.CooperativeSettleInfo memory settleInfo =
            PbEntity.decCooperativeSettleInfo(settleRequest.settleInfo);
        bytes32 channelId = settleInfo.channelId;
        LedgerStruct.Channel storage c = _self.channelMap[channelId];
        require(
            c.status == LedgerStruct.ChannelStatus.Operable ||
            c.status == LedgerStruct.ChannelStatus.Settling,
            "Channel status error"
        );

        bytes32 h = keccak256(settleRequest.settleInfo);
        require(c._checkCoSignatures(h, settleRequest.sigs), "Check co-sigs failed");

        address[2] memory peerAddrs = [c.peerProfiles[0].peerAddr, c.peerProfiles[1].peerAddr];
        require(
            settleInfo.seqNum > c.peerProfiles[0].state.seqNum &&
                settleInfo.seqNum > c.peerProfiles[1].state.seqNum,
            "seqNum error"
        );
        require(settleInfo.settleDeadline >= block.number, "Settle deadline passed");
        // require distribution is consistent with the order of peerAddrs in channel
        require(
            settleInfo.settleBalance[0].account == peerAddrs[0] &&
                settleInfo.settleBalance[1].account == peerAddrs[1],
            "Settle accounts mismatch"
        );

        uint[2] memory settleBalance = [
            settleInfo.settleBalance[0].amt,
            settleInfo.settleBalance[1].amt
        ];
        require(settleBalance[0].add(settleBalance[1]) == c.getTotalBalance(), "Balance sum mismatch");

        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Closed);

        emit CooperativeSettle(channelId, settleBalance);

        _batchTransferOut(_self, channelId, c.token.tokenAddress, peerAddrs, settleBalance);
    }

    /**
     * @notice Return channel number of given status in this contract
     * @param _self storage data of CelerLedger contract
     * @param _channelStatus query channel status converted to uint
     * @return channel number of the status
     */
    function getChannelStatusNum(
        LedgerStruct.Ledger storage _self,
        uint _channelStatus
    )
        external
        view
        returns(uint)
    {
        return _self.channelStatusNums[_channelStatus];
    }

    /**
     * @notice Return EthPool used by this CelerLedger contract
     * @param _self storage data of CelerLedger contract
     * @return EthPool address
     */
    function getEthPool(LedgerStruct.Ledger storage _self) external view returns(address) {
        return address(_self.ethPool);
    }

    /**
     * @notice Return PayRegistry used by this CelerLedger contract
     * @param _self storage data of CelerLedger contract
     * @return PayRegistry address
     */
    function getPayRegistry(LedgerStruct.Ledger storage _self) external view returns(address) {
        return address(_self.payRegistry);
    }

    /**
     * @notice Return CelerWallet used by this CelerLedger contract
     * @param _self storage data of CelerLedger contract
     * @return CelerWallet address
     */
    function getCelerWallet(LedgerStruct.Ledger storage _self) external view returns(address) {
        return address(_self.celerWallet);
    }

    /**
     * @notice create a wallet for a new channel
     * @param _self storage data of CelerLedger contract
     * @param _w celer wallet
     * @param _peers peers of the new channel
     * @param _nonce nonce for creating the wallet
     * @return channel id, which is same as the created wallet id
     * @return storage pointer of the channel
     */
    function _createWallet(
        LedgerStruct.Ledger storage _self,
        ICelerWallet _w,
        address[2] memory _peers,
        bytes32 _nonce
    )
        internal
        returns(bytes32, LedgerStruct.Channel storage)
    {
        address[] memory owners = new address[](2);
        owners[0] = _peers[0];
        owners[1] = _peers[1];
        // it is safe to use abi.encodePacked() with only one dynamic variable
        // use walletId as channelId
        bytes32 channelId = _w.create(owners, address(this), _nonce);
        // 0 is reserved for non-channel indication
        require(channelId != bytes32(0), "channelId gets 0");
        LedgerStruct.Channel storage c = _self.channelMap[channelId];
        // No harm in having this check in case of keccak256 being broken 
        require(c.status == LedgerStruct.ChannelStatus.Uninitialized, "Occupied channelId");

        return (channelId, c);
    }

    /**
     * @notice Internal function to add deposit of a channel
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     * @param _receiver address of the receiver
     * @param _amount the amount to be deposited
     */
    function _addDeposit(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _receiver,
        uint _amount
    )
        internal
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");

        // this implicitly require _receiver be a peer
        uint rid = c._getPeerId(_receiver);
        if (_self.balanceLimitsEnabled) {
            require(
                _amount.add(c.getTotalBalance()) <= _self.balanceLimits[c.token.tokenAddress],
                "Balance exceeds limit"
            );
        }

        c.peerProfiles[rid].deposit = c.peerProfiles[rid].deposit.add(_amount);

        (
            address[2] memory peerAddrs,
            uint[2] memory deposits,
            uint[2] memory withdrawals
        ) = c.getBalanceMap();
        emit Deposit(_channelId, peerAddrs, deposits, withdrawals);
    }

    /**
     * @notice Internal function to transfer funds out in batch
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     * @param _tokenAddr address of tokens to be transferred out
     * @param _receivers the addresses of token receivers
     * @param _amounts the amounts to be transferred
     */
    function _batchTransferOut(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _tokenAddr,
        address[2] memory _receivers,
        uint[2] memory _amounts
    )
        internal
    {
        for (uint i = 0; i < 2; i++) {
            if (_amounts[i] == 0) { continue; }

            _self.celerWallet.withdraw(_channelId, _tokenAddr, _receivers[i], _amounts[i]);
        }
    }

    /**
     * @notice Internal function to withdraw funds out of the channel
     * @param _self storage data of CelerLedger contract
     * @param _channelId ID of the channel
     * @param _receiver address of the receiver of the withdrawn funds
     * @param _amount the amount of the withdrawn funds
     * @param _recipientChannelId ID of the recipient channel
     */
    function _withdrawFunds(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _receiver,
        uint _amount,
        bytes32 _recipientChannelId
    )
        internal
    {
        if (_amount == 0) { return; }

        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        if (_recipientChannelId == bytes32(0)) {
            _self.celerWallet.withdraw(_channelId, c.token.tokenAddress, _receiver, _amount);
        } else {
            LedgerStruct.Channel storage recipientChannel = _self.channelMap[_recipientChannelId];
            require(
                c.token.tokenType == recipientChannel.token.tokenType &&
                    c.token.tokenAddress == recipientChannel.token.tokenAddress,
                "Token mismatch of recipient channel"
            );
            _addDeposit(_self, _recipientChannelId, _receiver, _amount);

            // move funds from one channel's wallet to another channel's wallet
            _self.celerWallet.transferToWallet(
                _channelId,
                _recipientChannelId,
                c.token.tokenAddress,
                _receiver,
                _amount
            );
        }
    }

    /**
     * @notice Reset the state of the channel
     * @param _self storage data of CelerLedger contract
     * @param _c the channel
     */
    function _resetDuplexState(
        LedgerStruct.Ledger storage _self,
        LedgerStruct.Channel storage _c
    )
        internal
    {
        delete _c.settleFinalizedTime;
        _updateChannelStatus(_self, _c, LedgerStruct.ChannelStatus.Operable);
        delete _c.peerProfiles[0].state;
        delete _c.peerProfiles[1].state;
        // reset possibly remaining WithdrawIntent freezed by previous intendSettle()
        delete _c.withdrawIntent;
    }

    /**
     * @notice Clear payments by their hash array
     * @param _self storage data of CelerLedger contract
     * @param _channelId the channel ID
     * @param _peerId ID of the peer who sends out funds
     * @param _payIds array of pay ids to clear
     */
    function _clearPays(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        uint _peerId,
        bytes32[] memory _payIds
    )
        internal
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        uint[] memory outAmts = _self.payRegistry.getPayAmounts(
            _payIds,
            c.peerProfiles[_peerId].state.lastPayResolveDeadline
        );

        uint totalAmtOut = 0;
        for (uint i = 0; i < outAmts.length; i++) {
            totalAmtOut = totalAmtOut.add(outAmts[i]);
            emit ClearOnePay(_channelId, _payIds[i], c.peerProfiles[_peerId].peerAddr, outAmts[i]);
        }
        c.peerProfiles[_peerId].state.transferOut =
            c.peerProfiles[_peerId].state.transferOut.add(totalAmtOut);
    }

    /**
     * @notice Update overall states of a duplex channel
     * @param _self storage data of CelerLedger contract
     * @param _channelId the channel ID
     */
    function _updateOverallStatesByIntendState(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId
    )
        internal
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        c.settleFinalizedTime = block.number.add(c.disputeTimeout);
        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Settling);

        emit IntendSettle(_channelId, c._getStateSeqNums());
    }

    /**
     * @notice Update status of a channel
     * @param _self storage data of CelerLedger contract
     * @param _c the channel
     * @param _newStatus new channel status
     */
    function _updateChannelStatus(
        LedgerStruct.Ledger storage _self,
        LedgerStruct.Channel storage _c,
        LedgerStruct.ChannelStatus _newStatus
    )
        internal
    {
        if (_c.status == _newStatus) {
            return;
        }

        // update counter of old status
        if (_c.status != LedgerStruct.ChannelStatus.Uninitialized) {
            _self.channelStatusNums[uint(_c.status)] = _self.channelStatusNums[uint(_c.status)].sub(1);
        }

        // update counter of new status
        _self.channelStatusNums[uint(_newStatus)] = _self.channelStatusNums[uint(_newStatus)].add(1);

        _c.status = _newStatus;
    }

    /**
     * @notice Validate token info
     * @param _token token info to be validated
     * @return validated token info
     */
    function _validateTokenInfo(PbEntity.TokenInfo memory _token)
        internal
        view
        returns(PbEntity.TokenInfo memory)
    {
        if (_token.tokenType == PbEntity.TokenType.ETH) {
            require(_token.tokenAddress == address(0));
        } else if (_token.tokenType == PbEntity.TokenType.ERC20) {
            require(_token.tokenAddress != address(0));
            require(_token.tokenAddress.isContract());
        } else {
            assert(false);
        }

        return _token;
    }

    event OpenChannel(
        bytes32 indexed channelId,
        uint tokenType,
        address indexed tokenAddress,
        // TODO: there is an issue of setting address[2] as indexed. Need to fix and make this indexed
        address[2] peerAddrs,
        uint[2] initialDeposits
    );

    // TODO: there is an issue of setting address[2] as indexed. Need to fix and make this indexed
    event Deposit(bytes32 indexed channelId, address[2] peerAddrs, uint[2] deposits, uint[2] withdrawals);

    event SnapshotStates(bytes32 indexed channelId, uint[2] seqNums);

    event IntendSettle(bytes32 indexed channelId, uint[2] seqNums);

    event ClearOnePay(bytes32 indexed channelId, bytes32 indexed payId, address indexed peerFrom, uint amount);

    event ConfirmSettle(bytes32 indexed channelId, uint[2] settleBalance);

    event ConfirmSettleFail(bytes32 indexed channelId);

    event IntendWithdraw(bytes32 indexed channelId, address indexed receiver, uint amount);

    event ConfirmWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals
    );

    event VetoWithdraw(bytes32 indexed channelId);

    event CooperativeWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals,
        uint seqNum
    );

    event CooperativeSettle(bytes32 indexed channelId, uint[2] settleBalance);
}