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

// File: contracts/lib/ledgerlib/LedgerBalanceLimit.sol

pragma solidity ^0.5.1;


/**
 * @title Ledger Balance Limit Library
 * @notice CelerLedger library about balance limits
 */
library LedgerBalanceLimit {
    /**
     * @notice Set the balance limits of given tokens
     * @param _self storage data of CelerLedger contract
     * @param _tokenAddrs addresses of the tokens (address(0) is for ETH)
     * @param _limits balance limits of the tokens
     */
    function setBalanceLimits(
        LedgerStruct.Ledger storage _self,
        address[] calldata _tokenAddrs,
        uint[] calldata _limits
    )
        external
    {
        require(_tokenAddrs.length == _limits.length, "Lengths do not match");
        for (uint i = 0; i < _tokenAddrs.length; i++) {
            _self.balanceLimits[_tokenAddrs[i]] = _limits[i];
        }
    }

    /**
     * @notice Disable balance limits of all tokens
     * @param _self storage data of CelerLedger contract
     */
    function disableBalanceLimits(LedgerStruct.Ledger storage _self) external {
        _self.balanceLimitsEnabled = false;
    }

    /**
     * @notice Enable balance limits of all tokens
     * @param _self storage data of CelerLedger contract
     */
    function enableBalanceLimits(LedgerStruct.Ledger storage _self) external {
        _self.balanceLimitsEnabled = true;
    }

    /**
     * @notice Return balance limit of given token
     * @param _self storage data of CelerLedger contract
     * @param _tokenAddr query token address
     * @return token balance limit
     */
    function getBalanceLimit(
        LedgerStruct.Ledger storage _self,
        address _tokenAddr
    )
        external
        view
        returns(uint)
    {
        return _self.balanceLimits[_tokenAddr];
    }

    /**
     * @notice Return balanceLimitsEnabled
     * @param _self storage data of CelerLedger contract
     * @return balanceLimitsEnabled
     */
    function getBalanceLimitsEnabled(LedgerStruct.Ledger storage _self) external view returns(bool) {
        return _self.balanceLimitsEnabled;
    }
}