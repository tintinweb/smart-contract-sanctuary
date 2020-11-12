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
        require((value == 0) || (token.allowance(address(this), spender) == 0));
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

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/lib/interface/ISGN.sol

pragma solidity 0.5.17;

/**
 * @title SGN interface
 */
interface ISGN {
    // functions
    function updateSidechainAddr(bytes calldata _sidechainAddr) external;

    function subscribe(uint _amount) external;

    function redeemReward(bytes calldata _rewardRequest) external;

    // events
    event UpdateSidechainAddr(address indexed candidate, bytes indexed oldSidechainAddr, bytes indexed newSidechainAddr);

    event AddSubscriptionBalance(address indexed consumer, uint amount);

    event RedeemReward(address indexed receiver, uint cumulativeMiningReward, uint serviceReward, uint servicePool);
}

// File: contracts/lib/interface/IDPoS.sol

pragma solidity 0.5.17;

/**
 * @title DPoS interface
 */
interface IDPoS {
    enum ValidatorChangeType { Add, Removal }

    // functions
    function contributeToMiningPool(uint _amount) external;

    function redeemMiningReward(address _receiver, uint _cumulativeReward) external;

    function registerSidechain(address _addr) external;

    function initializeCandidate(uint _minSelfStake, uint _commissionRate, uint _rateLockEndTime) external;

    function announceIncreaseCommissionRate(uint _newRate, uint _newLockEndTime) external;

    function confirmIncreaseCommissionRate() external;

    function nonIncreaseCommissionRate(uint _newRate, uint _newLockEndTime) external;

    function updateMinSelfStake(uint256 _minSelfStake) external;

    function delegate(address _candidateAddr, uint _amount) external;

    function withdrawFromUnbondedCandidate(address _candidateAddr, uint _amount) external;

    function intendWithdraw(address _candidateAddr, uint _amount) external;

    function confirmWithdraw(address _candidateAddr) external;

    function claimValidator() external;

    function confirmUnbondedCandidate(address _candidateAddr) external;

    function slash(bytes calldata _penaltyRequest) external;

    function validateMultiSigMessage(bytes calldata _request) external returns(bool);

    function isValidDPoS() external view returns (bool);

    function isValidator(address _addr) external view returns (bool);

    function getValidatorNum() external view returns (uint);

    function getMinStakingPool() external view returns (uint);

    function getCandidateInfo(address _candidateAddr) external view returns (bool, uint, uint, uint, uint, uint, uint);

    function getDelegatorInfo(address _candidateAddr, address _delegatorAddr) external view returns (uint, uint, uint[] memory, uint[] memory);

    function getMinQuorumStakingPool() external view returns(uint);

    function getTotalValidatorStakingPool() external view returns(uint);

    // TODO: interface can't be inherited, so VoteType is not declared here
    // function voteParam(uint _proposalId, VoteType _vote) external;

    // function confirmParamProposal(uint _proposalId) external;

    // function voteSidechain(uint _proposalId, VoteType _vote) external;

    // function confirmSidechainProposal(uint _proposalId) external;

    // events
    event InitializeCandidate(address indexed candidate, uint minSelfStake, uint commissionRate, uint rateLockEndTime);

    event CommissionRateAnnouncement(address indexed candidate, uint announcedRate, uint announcedLockEndTime);

    event UpdateCommissionRate(address indexed candidate, uint newRate, uint newLockEndTime);

    event UpdateMinSelfStake(address indexed candidate, uint minSelfStake);

    event Delegate(address indexed delegator, address indexed candidate, uint newStake, uint stakingPool);

    event ValidatorChange(address indexed ethAddr, ValidatorChangeType indexed changeType);

    event WithdrawFromUnbondedCandidate(address indexed delegator, address indexed candidate, uint amount);

    event IntendWithdraw(address indexed delegator, address indexed candidate, uint withdrawAmount, uint proposedTime);

    event ConfirmWithdraw(address indexed delegator, address indexed candidate, uint amount);

    event Slash(address indexed validator, address indexed delegator, uint amount);

    event UpdateDelegatedStake(address indexed delegator, address indexed candidate, uint delegatorStake, uint candidatePool);

    event Compensate(address indexed indemnitee, uint amount);

    event CandidateUnbonded(address indexed candidate);

    event RedeemMiningReward(address indexed receiver, uint reward, uint miningPool);

    event MiningPoolContribution(address indexed contributor, uint contribution, uint miningPoolSize);
}

// File: contracts/lib/data/Pb.sol

pragma solidity 0.5.17;

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
        uint i; // count how many ints are there
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

// File: contracts/lib/data/PbSgn.sol

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: sgn.proto
pragma solidity 0.5.17;


library PbSgn {
    using Pb for Pb.Buffer;  // so we can call Pb funcs on Buffer obj

    struct MultiSigMessage {
        bytes msg;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct MultiSigMessage

    function decMultiSigMessage(bytes memory raw) internal pure returns (MultiSigMessage memory m) {
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
                m.msg = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder MultiSigMessage

    struct PenaltyRequest {
        bytes penalty;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct PenaltyRequest

    function decPenaltyRequest(bytes memory raw) internal pure returns (PenaltyRequest memory m) {
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
                m.penalty = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder PenaltyRequest

    struct RewardRequest {
        bytes reward;   // tag: 1
        bytes[] sigs;   // tag: 2
    } // end struct RewardRequest

    function decRewardRequest(bytes memory raw) internal pure returns (RewardRequest memory m) {
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
                m.reward = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder RewardRequest

    struct Penalty {
        uint64 nonce;   // tag: 1
        uint64 expireTime;   // tag: 2
        address validatorAddress;   // tag: 3
        AccountAmtPair[] penalizedDelegators;   // tag: 4
        AccountAmtPair[] beneficiaries;   // tag: 5
    } // end struct Penalty

    function decPenalty(bytes memory raw) internal pure returns (Penalty memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(5);
        m.penalizedDelegators = new AccountAmtPair[](cnts[4]);
        cnts[4] = 0;  // reset counter for later use
        m.beneficiaries = new AccountAmtPair[](cnts[5]);
        cnts[5] = 0;  // reset counter for later use
        
        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.nonce = uint64(buf.decVarint());
            }
            else if (tag == 2) {
                m.expireTime = uint64(buf.decVarint());
            }
            else if (tag == 3) {
                m.validatorAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.penalizedDelegators[cnts[4]] = decAccountAmtPair(buf.decBytes());
                cnts[4]++;
            }
            else if (tag == 5) {
                m.beneficiaries[cnts[5]] = decAccountAmtPair(buf.decBytes());
                cnts[5]++;
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder Penalty

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

    struct Reward {
        address receiver;   // tag: 1
        uint256 cumulativeMiningReward;   // tag: 2
        uint256 cumulativeServiceReward;   // tag: 3
    } // end struct Reward

    function decReward(bytes memory raw) internal pure returns (Reward memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {} // solidity has no switch/case
            else if (tag == 1) {
                m.receiver = Pb._address(buf.decBytes());
            }
            else if (tag == 2) {
                m.cumulativeMiningReward = Pb._uint256(buf.decBytes());
            }
            else if (tag == 3) {
                m.cumulativeServiceReward = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); } // skip value of unknown tag
        }
    } // end decoder Reward

}

// File: contracts/lib/DPoSCommon.sol

pragma solidity 0.5.17;

/**
 * @title DPoS contract common Library
 * @notice Common items used in DPoS contract
 */
library DPoSCommon {
    // Unbonded: not a validator and not responsible for previous validator behaviors if any.
    //   Delegators now are free to withdraw stakes (directly).
    // Bonded: active validator. Delegators have to wait for slashTimeout to withdraw stakes.
    // Unbonding: transitional status from Bonded to Unbonded. Candidate has lost the right of
    //   validator but is still responsible for any misbehaviour done during being validator.
    //   Delegators should wait until candidate's unbondTime to freely withdraw stakes.
    enum CandidateStatus { Unbonded, Bonded, Unbonding }
}

// File: contracts/SGN.sol

pragma solidity 0.5.17;










/**
 * @title Sidechain contract of State Guardian Network
 * @notice This contract implements the mainchain logic of Celer State Guardian Network sidechain
 * @dev specs: https://www.celer.network/docs/celercore/sgn/sidechain.html#mainchain-contracts
 */
contract SGN is ISGN, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public celerToken;
    IDPoS public dPoSContract;
    mapping(address => uint256) public subscriptionDeposits;
    uint256 public servicePool;
    mapping(address => uint256) public redeemedServiceReward;
    mapping(address => bytes) public sidechainAddrMap;

    /**
     * @notice Throws if SGN sidechain is not valid
     * @dev Check this before sidechain's operations
     */
    modifier onlyValidSidechain() {
        require(dPoSContract.isValidDPoS(), 'DPoS is not valid');
        _;
    }

    /**
     * @notice SGN constructor
     * @dev Need to deploy DPoS contract first before deploying SGN contract
     * @param _celerTokenAddress address of Celer Token Contract
     * @param _DPoSAddress address of DPoS Contract
     */
    constructor(address _celerTokenAddress, address _DPoSAddress) public {
        celerToken = IERC20(_celerTokenAddress);
        dPoSContract = IDPoS(_DPoSAddress);
    }

    /**
     * @notice Owner drains one type of tokens when the contract is paused
     * @dev This is for emergency situations.
     * @param _amount drained token amount
     */
    function drainToken(uint256 _amount) external whenPaused onlyOwner {
        celerToken.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Update sidechain address
     * @dev Note that the "sidechain address" here means the address in the offchain sidechain system,
         which is different from the sidechain contract address
     * @param _sidechainAddr the new address in the offchain sidechain system
     */
    function updateSidechainAddr(bytes calldata _sidechainAddr) external {
        address msgSender = msg.sender;

        (bool initialized, , , uint256 status, , , ) = dPoSContract.getCandidateInfo(msgSender);
        require(
            status == uint256(DPoSCommon.CandidateStatus.Unbonded),
            'msg.sender is not unbonded'
        );
        require(initialized, 'Candidate is not initialized');

        bytes memory oldSidechainAddr = sidechainAddrMap[msgSender];
        sidechainAddrMap[msgSender] = _sidechainAddr;

        emit UpdateSidechainAddr(msgSender, oldSidechainAddr, _sidechainAddr);
    }

    /**
     * @notice Subscribe the guardian service
     * @param _amount subscription fee paid along this function call in CELR tokens
     */
    function subscribe(uint256 _amount) external whenNotPaused onlyValidSidechain {
        address msgSender = msg.sender;

        servicePool = servicePool.add(_amount);
        subscriptionDeposits[msgSender] = subscriptionDeposits[msgSender].add(_amount);

        celerToken.safeTransferFrom(msgSender, address(this), _amount);

        emit AddSubscriptionBalance(msgSender, _amount);
    }

    /**
     * @notice Redeem rewards
     * @dev The rewards include both the service reward and mining reward
     * @dev SGN contract acts as an interface for users to redeem mining rewards
     * @param _rewardRequest reward request bytes coded in protobuf
     */
    function redeemReward(bytes calldata _rewardRequest) external whenNotPaused onlyValidSidechain {
        require(
            dPoSContract.validateMultiSigMessage(_rewardRequest),
            'Validator sigs verification failed'
        );

        PbSgn.RewardRequest memory rewardRequest = PbSgn.decRewardRequest(_rewardRequest);
        PbSgn.Reward memory reward = PbSgn.decReward(rewardRequest.reward);
        uint256 newServiceReward = reward.cumulativeServiceReward.sub(
            redeemedServiceReward[reward.receiver]
        );

        require(servicePool >= newServiceReward, 'Service pool is smaller than new service reward');
        redeemedServiceReward[reward.receiver] = reward.cumulativeServiceReward;
        servicePool = servicePool.sub(newServiceReward);

        dPoSContract.redeemMiningReward(reward.receiver, reward.cumulativeMiningReward);
        celerToken.safeTransfer(reward.receiver, newServiceReward);

        emit RedeemReward(
            reward.receiver,
            reward.cumulativeMiningReward,
            newServiceReward,
            servicePool
        );
    }
}