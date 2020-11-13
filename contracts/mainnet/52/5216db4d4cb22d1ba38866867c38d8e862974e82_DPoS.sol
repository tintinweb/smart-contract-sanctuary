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

// File: openzeppelin-solidity/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
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

// File: contracts/lib/interface/IGovern.sol

pragma solidity 0.5.17;

/**
 * @title Govern interface
 */
interface IGovern {
    enum ParamNames { ProposalDeposit, GovernVoteTimeout, SlashTimeout, MinValidatorNum, MaxValidatorNum, MinStakeInPool, AdvanceNoticePeriod, MigrationTime }

    enum ProposalStatus { Uninitiated, Voting, Closed }

    enum VoteType { Unvoted, Yes, No, Abstain }

    // functions
    function getUIntValue(uint _record) external view returns (uint);

    function getParamProposalVote(uint _proposalId, address _voter) external view returns (VoteType);

    function isSidechainRegistered(address _sidechainAddr) external view returns (bool);

    function getSidechainProposalVote(uint _proposalId, address _voter) external view returns (VoteType);

    function createParamProposal(uint _record, uint _value) external;

    function registerSidechain(address _addr) external;

    function createSidechainProposal(address _sidechainAddr, bool _registered) external;

    // events
    event CreateParamProposal(uint proposalId, address proposer, uint deposit, uint voteDeadline, uint record, uint newValue);

    event VoteParam(uint proposalId, address voter, VoteType voteType);

    event ConfirmParamProposal(uint proposalId, bool passed, uint record, uint newValue);

    event CreateSidechainProposal(uint proposalId, address proposer, uint deposit, uint voteDeadline, address sidechainAddr, bool registered);

    event VoteSidechain(uint proposalId, address voter, VoteType voteType);

    event ConfirmSidechainProposal(uint proposalId, bool passed, address sidechainAddr, bool registered);
}

// File: contracts/lib/Govern.sol

pragma solidity 0.5.17;






/**
 * @title Governance module for DPoS contract
 * @notice Govern contract implements the basic governance logic
 * @dev DPoS contract should inherit this contract
 * @dev Some specific functions of governance are defined in DPoS contract
 */
contract Govern is IGovern, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct ParamProposal {
        address proposer;
        uint256 deposit;
        uint256 voteDeadline;
        uint256 record;
        uint256 newValue;
        ProposalStatus status;
        mapping(address => VoteType) votes;
    }

    struct SidechainProposal {
        address proposer;
        uint256 deposit;
        uint256 voteDeadline;
        address sidechainAddr;
        bool registered;
        ProposalStatus status;
        mapping(address => VoteType) votes;
    }

    IERC20 public celerToken;
    // parameters
    mapping(uint256 => uint256) public UIntStorage;
    mapping(uint256 => ParamProposal) public paramProposals;
    uint256 public nextParamProposalId;
    // registered sidechain addresses
    mapping(address => bool) public registeredSidechains;
    mapping(uint256 => SidechainProposal) public sidechainProposals;
    uint256 public nextSidechainProposalId;

    /**
     * @notice Govern constructor
     * @dev set celerToken and initialize all parameters
     * @param _celerTokenAddress address of the governance token
     * @param _governProposalDeposit required deposit amount for a governance proposal
     * @param _governVoteTimeout voting timeout for a governance proposal
     * @param _slashTimeout the locking time for funds to be potentially slashed
     * @param _minValidatorNum the minimum number of validators
     * @param _maxValidatorNum the maximum number of validators
     * @param _minStakeInPool the global minimum requirement of staking pool for each validator
     * @param _advanceNoticePeriod the time after the announcement and prior to the effective time of an update
     */
    constructor(
        address _celerTokenAddress,
        uint256 _governProposalDeposit,
        uint256 _governVoteTimeout,
        uint256 _slashTimeout,
        uint256 _minValidatorNum,
        uint256 _maxValidatorNum,
        uint256 _minStakeInPool,
        uint256 _advanceNoticePeriod
    ) public {
        celerToken = IERC20(_celerTokenAddress);

        UIntStorage[uint256(ParamNames.ProposalDeposit)] = _governProposalDeposit;
        UIntStorage[uint256(ParamNames.GovernVoteTimeout)] = _governVoteTimeout;
        UIntStorage[uint256(ParamNames.SlashTimeout)] = _slashTimeout;
        UIntStorage[uint256(ParamNames.MinValidatorNum)] = _minValidatorNum;
        UIntStorage[uint256(ParamNames.MaxValidatorNum)] = _maxValidatorNum;
        UIntStorage[uint256(ParamNames.MinStakeInPool)] = _minStakeInPool;
        UIntStorage[uint256(ParamNames.AdvanceNoticePeriod)] = _advanceNoticePeriod;
    }

    /********** Get functions **********/
    /**
     * @notice Get the value of a specific uint parameter
     * @param _record the key of this parameter
     * @return the value of this parameter
     */
    function getUIntValue(uint256 _record) public view returns (uint256) {
        return UIntStorage[_record];
    }

    /**
     * @notice Get the vote type of a voter on a parameter proposal
     * @param _proposalId the proposal id
     * @param _voter the voter address
     * @return the vote type of the given voter on the given parameter proposal
     */
    function getParamProposalVote(uint256 _proposalId, address _voter)
        public
        view
        returns (VoteType)
    {
        return paramProposals[_proposalId].votes[_voter];
    }

    /**
     * @notice Get whether a sidechain is registered or not
     * @param _sidechainAddr the sidechain contract address
     * @return whether the given sidechain is registered or not
     */
    function isSidechainRegistered(address _sidechainAddr) public view returns (bool) {
        return registeredSidechains[_sidechainAddr];
    }

    /**
     * @notice Get the vote type of a voter on a sidechain proposal
     * @param _proposalId the proposal id
     * @param _voter the voter address
     * @return the vote type of the given voter on the given sidechain proposal
     */
    function getSidechainProposalVote(uint256 _proposalId, address _voter)
        public
        view
        returns (VoteType)
    {
        return sidechainProposals[_proposalId].votes[_voter];
    }

    /********** Governance functions **********/
    /**
     * @notice Create a parameter proposal
     * @param _record the key of this parameter
     * @param _value the new proposed value of this parameter
     */
    function createParamProposal(uint256 _record, uint256 _value) external {
        ParamProposal storage p = paramProposals[nextParamProposalId];
        nextParamProposalId = nextParamProposalId + 1;
        address msgSender = msg.sender;
        uint256 deposit = UIntStorage[uint256(ParamNames.ProposalDeposit)];

        p.proposer = msgSender;
        p.deposit = deposit;
        p.voteDeadline = block.number.add(UIntStorage[uint256(ParamNames.GovernVoteTimeout)]);
        p.record = _record;
        p.newValue = _value;
        p.status = ProposalStatus.Voting;

        celerToken.safeTransferFrom(msgSender, address(this), deposit);

        emit CreateParamProposal(
            nextParamProposalId - 1,
            msgSender,
            deposit,
            p.voteDeadline,
            _record,
            _value
        );
    }

    /**
     * @notice Internal function to vote for a parameter proposal
     * @dev Must be used in DPoS contract
     * @param _proposalId the proposal id
     * @param _voter the voter address
     * @param _vote the vote type
     */
    function internalVoteParam(
        uint256 _proposalId,
        address _voter,
        VoteType _vote
    ) internal {
        ParamProposal storage p = paramProposals[_proposalId];
        require(p.status == ProposalStatus.Voting, 'Invalid proposal status');
        require(block.number < p.voteDeadline, 'Vote deadline reached');
        require(p.votes[_voter] == VoteType.Unvoted, 'Voter has voted');

        p.votes[_voter] = _vote;

        emit VoteParam(_proposalId, _voter, _vote);
    }

    /**
     * @notice Internal function to confirm a parameter proposal
     * @dev Must be used in DPoS contract
     * @param _proposalId the proposal id
     * @param _passed proposal passed or not
     */
    function internalConfirmParamProposal(uint256 _proposalId, bool _passed) internal {
        ParamProposal storage p = paramProposals[_proposalId];
        require(p.status == ProposalStatus.Voting, 'Invalid proposal status');
        require(block.number >= p.voteDeadline, 'Vote deadline not reached');

        p.status = ProposalStatus.Closed;
        if (_passed) {
            celerToken.safeTransfer(p.proposer, p.deposit);
            UIntStorage[p.record] = p.newValue;
        }

        emit ConfirmParamProposal(_proposalId, _passed, p.record, p.newValue);
    }

    //
    /**
     * @notice Register a sidechain by contract owner
     * @dev Owner can renounce Ownership if needed for this function
     * @param _addr the sidechain contract address
     */
    function registerSidechain(address _addr) external onlyOwner {
        registeredSidechains[_addr] = true;
    }

    /**
     * @notice Create a sidechain proposal
     * @param _sidechainAddr the sidechain contract address
     * @param _registered the new proposed registration status
     */
    function createSidechainProposal(address _sidechainAddr, bool _registered) external {
        SidechainProposal storage p = sidechainProposals[nextSidechainProposalId];
        nextSidechainProposalId = nextSidechainProposalId + 1;
        address msgSender = msg.sender;
        uint256 deposit = UIntStorage[uint256(ParamNames.ProposalDeposit)];

        p.proposer = msgSender;
        p.deposit = deposit;
        p.voteDeadline = block.number.add(UIntStorage[uint256(ParamNames.GovernVoteTimeout)]);
        p.sidechainAddr = _sidechainAddr;
        p.registered = _registered;
        p.status = ProposalStatus.Voting;

        celerToken.safeTransferFrom(msgSender, address(this), deposit);

        emit CreateSidechainProposal(
            nextSidechainProposalId - 1,
            msgSender,
            deposit,
            p.voteDeadline,
            _sidechainAddr,
            _registered
        );
    }

    /**
     * @notice Internal function to vote for a sidechain proposal
     * @dev Must be used in DPoS contract
     * @param _proposalId the proposal id
     * @param _voter the voter address
     * @param _vote the vote type
     */
    function internalVoteSidechain(
        uint256 _proposalId,
        address _voter,
        VoteType _vote
    ) internal {
        SidechainProposal storage p = sidechainProposals[_proposalId];
        require(p.status == ProposalStatus.Voting, 'Invalid proposal status');
        require(block.number < p.voteDeadline, 'Vote deadline reached');
        require(p.votes[_voter] == VoteType.Unvoted, 'Voter has voted');

        p.votes[_voter] = _vote;

        emit VoteSidechain(_proposalId, _voter, _vote);
    }

    /**
     * @notice Internal function to confirm a sidechain proposal
     * @dev Must be used in DPoS contract
     * @param _proposalId the proposal id
     * @param _passed proposal passed or not
     */
    function internalConfirmSidechainProposal(uint256 _proposalId, bool _passed) internal {
        SidechainProposal storage p = sidechainProposals[_proposalId];
        require(p.status == ProposalStatus.Voting, 'Invalid proposal status');
        require(block.number >= p.voteDeadline, 'Vote deadline not reached');

        p.status = ProposalStatus.Closed;
        if (_passed) {
            celerToken.safeTransfer(p.proposer, p.deposit);
            registeredSidechains[p.sidechainAddr] = p.registered;
        }

        emit ConfirmSidechainProposal(_proposalId, _passed, p.sidechainAddr, p.registered);
    }
}

// File: contracts/DPoS.sol

pragma solidity 0.5.17;












/**
 * @title A DPoS contract shared by every sidechain
 * @notice This contract holds the basic logic of DPoS in Celer's coherent sidechain system
 */
contract DPoS is IDPoS, Ownable, Pausable, WhitelistedRole, Govern {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    enum MathOperation { Add, Sub }

    struct WithdrawIntent {
        uint256 amount;
        uint256 proposedTime;
    }

    struct Delegator {
        uint256 delegatedStake;
        uint256 undelegatingStake;
        mapping(uint256 => WithdrawIntent) withdrawIntents;
        // valid intent range is [intentStartIndex, intentEndIndex)
        uint256 intentStartIndex;
        uint256 intentEndIndex;
    }

    struct ValidatorCandidate {
        bool initialized;
        uint256 minSelfStake;
        uint256 stakingPool; // sum of all delegations to this candidate
        mapping(address => Delegator) delegatorProfiles;
        DPoSCommon.CandidateStatus status;
        uint256 unbondTime;
        uint256 commissionRate; // equal to real commission rate * COMMISSION_RATE_BASE
        uint256 rateLockEndTime; // must be monotonic increasing. Use block number
        // for the announcement of increasing commission rate
        uint256 announcedRate;
        uint256 announcedLockEndTime;
        uint256 announcementTime;
        // for decreasing minSelfStake
        uint256 earliestBondTime;
    }

    mapping(uint256 => address) public validatorSet;
    mapping(uint256 => bool) public usedPenaltyNonce;
    // used in checkValidatorSigs(). mapping has to be storage type.
    mapping(address => bool) public checkedValidators;
    // struct ValidatorCandidate includes a mapping and therefore candidateProfiles can't be public
    mapping(address => ValidatorCandidate) private candidateProfiles;
    mapping(address => uint256) public redeemedMiningReward;

    /********** Constants **********/
    uint256 constant DECIMALS_MULTIPLIER = 10**18;
    uint256 public constant COMMISSION_RATE_BASE = 10000; // 1 commissionRate means 0.01%

    uint256 public dposGoLiveTime; // used when bootstrapping initial validators
    uint256 public miningPool;
    bool public enableWhitelist;
    bool public enableSlash;

    /**
     * @notice Throws if given address is zero address
     * @param _addr address to be checked
     */
    modifier onlyNonZeroAddr(address _addr) {
        require(_addr != address(0), '0 address');
        _;
    }

    /**
     * @notice Throws if DPoS is not valid
     * @dev Need to be checked before DPoS's operations
     */
    modifier onlyValidDPoS() {
        require(isValidDPoS(), 'DPoS is not valid');
        _;
    }

    /**
     * @notice Throws if msg.sender is not a registered sidechain
     */
    modifier onlyRegisteredSidechains() {
        require(isSidechainRegistered(msg.sender), 'Sidechain not registered');
        _;
    }

    /**
     * @notice Check if the sender is in the whitelist
     */
    modifier onlyWhitelist() {
        if (enableWhitelist) {
            require(
                isWhitelisted(msg.sender),
                'WhitelistedRole: caller does not have the Whitelisted role'
            );
        }
        _;
    }

    /**
     * @notice Throws if contract in migrating state
     */
    modifier onlyNotMigrating() {
        require(!isMigrating(), 'contract migrating');
        _;
    }

    /**
     * @notice Throws if amount is smaller than minimum
     */
    modifier minAmount(uint256 _amount, uint256 _min) {
        require(_amount >= _min, 'Amount is smaller than minimum requirement');
        _;
    }

    /**
     * @notice Throws if sender is not validator
     */
    modifier onlyValidator() {
        require(isValidator(msg.sender), 'msg sender is not a validator');
        _;
    }

    /**
     * @notice Throws if candidate is not initialized
     */
    modifier isCandidateInitialized() {
        require(candidateProfiles[msg.sender].initialized, 'Candidate is not initialized');
        _;
    }

    /**
     * @notice DPoS constructor
     * @dev will initialize parent contract Govern first
     * @param _celerTokenAddress address of Celer Token Contract
     * @param _governProposalDeposit required deposit amount for a governance proposal
     * @param _governVoteTimeout voting timeout for a governance proposal
     * @param _slashTimeout the locking time for funds to be potentially slashed
     * @param _minValidatorNum the minimum number of validators
     * @param _maxValidatorNum the maximum number of validators
     * @param _minStakeInPool the global minimum requirement of staking pool for each validator
     * @param _advanceNoticePeriod the wait time after the announcement and prior to the effective date of an update
     * @param _dposGoLiveTimeout the timeout for DPoS to go live after contract creation
     */
    constructor(
        address _celerTokenAddress,
        uint256 _governProposalDeposit,
        uint256 _governVoteTimeout,
        uint256 _slashTimeout,
        uint256 _minValidatorNum,
        uint256 _maxValidatorNum,
        uint256 _minStakeInPool,
        uint256 _advanceNoticePeriod,
        uint256 _dposGoLiveTimeout
    )
        public
        Govern(
            _celerTokenAddress,
            _governProposalDeposit,
            _governVoteTimeout,
            _slashTimeout,
            _minValidatorNum,
            _maxValidatorNum,
            _minStakeInPool,
            _advanceNoticePeriod
        )
    {
        dposGoLiveTime = block.number.add(_dposGoLiveTimeout);
        enableSlash = true;
    }

    /**
     * @notice Update enableWhitelist
     * @param _enable enable whitelist flag
     */
    function updateEnableWhitelist(bool _enable) external onlyOwner {
        enableWhitelist = _enable;
    }

    /**
     * @notice Update enableSlash
     * @param _enable enable slash flag
     */
    function updateEnableSlash(bool _enable) external onlyOwner {
        enableSlash = _enable;
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
     * @notice Vote for a parameter proposal with a specific type of vote
     * @param _proposalId the id of the parameter proposal
     * @param _vote the type of vote
     */
    function voteParam(uint256 _proposalId, VoteType _vote) external onlyValidator {
        internalVoteParam(_proposalId, msg.sender, _vote);
    }

    /**
     * @notice Confirm a parameter proposal
     * @param _proposalId the id of the parameter proposal
     */
    function confirmParamProposal(uint256 _proposalId) external {
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));

        // check Yes votes only now
        uint256 yesVoteStakes;
        for (uint256 i = 0; i < maxValidatorNum; i++) {
            if (getParamProposalVote(_proposalId, validatorSet[i]) == VoteType.Yes) {
                yesVoteStakes = yesVoteStakes.add(candidateProfiles[validatorSet[i]].stakingPool);
            }
        }

        bool passed = yesVoteStakes >= getMinQuorumStakingPool();
        if (!passed) {
            miningPool = miningPool.add(paramProposals[_proposalId].deposit);
        }
        internalConfirmParamProposal(_proposalId, passed);
    }

    /**
     * @notice Vote for a sidechain proposal with a specific type of vote
     * @param _proposalId the id of the sidechain proposal
     * @param _vote the type of vote
     */
    function voteSidechain(uint256 _proposalId, VoteType _vote) external onlyValidator {
        internalVoteSidechain(_proposalId, msg.sender, _vote);
    }

    /**
     * @notice Confirm a sidechain proposal
     * @param _proposalId the id of the sidechain proposal
     */
    function confirmSidechainProposal(uint256 _proposalId) external {
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));

        // check Yes votes only now
        uint256 yesVoteStakes;
        for (uint256 i = 0; i < maxValidatorNum; i++) {
            if (getSidechainProposalVote(_proposalId, validatorSet[i]) == VoteType.Yes) {
                yesVoteStakes = yesVoteStakes.add(candidateProfiles[validatorSet[i]].stakingPool);
            }
        }

        bool passed = yesVoteStakes >= getMinQuorumStakingPool();
        if (!passed) {
            miningPool = miningPool.add(sidechainProposals[_proposalId].deposit);
        }
        internalConfirmSidechainProposal(_proposalId, passed);
    }

    /**
     * @notice Contribute CELR tokens to the mining pool
     * @param _amount the amount of CELR tokens to contribute
     */
    function contributeToMiningPool(uint256 _amount) external whenNotPaused {
        address msgSender = msg.sender;
        miningPool = miningPool.add(_amount);
        celerToken.safeTransferFrom(msgSender, address(this), _amount);

        emit MiningPoolContribution(msgSender, _amount, miningPool);
    }

    /**
     * @notice Redeem mining reward
     * @dev The validation of this redeeming operation should be done by the caller, a registered sidechain contract
     * @dev Here we use cumulative mining reward to simplify the logic in sidechain code
     * @param _receiver the receiver of the redeemed mining reward
     * @param _cumulativeReward the latest cumulative mining reward
     */
    function redeemMiningReward(address _receiver, uint256 _cumulativeReward)
        external
        whenNotPaused
        onlyRegisteredSidechains
    {
        uint256 newReward = _cumulativeReward.sub(redeemedMiningReward[_receiver]);
        require(miningPool >= newReward, 'Mining pool is smaller than new reward');

        redeemedMiningReward[_receiver] = _cumulativeReward;
        miningPool = miningPool.sub(newReward);
        celerToken.safeTransfer(_receiver, newReward);

        emit RedeemMiningReward(_receiver, newReward, miningPool);
    }

    /**
     * @notice Initialize a candidate profile for validator
     * @dev every validator must become a candidate first
     * @param _minSelfStake minimal amount of tokens staked by the validator itself
     * @param _commissionRate the self-declaimed commission rate
     * @param _rateLockEndTime the lock end time of initial commission rate
     */
    function initializeCandidate(
        uint256 _minSelfStake,
        uint256 _commissionRate,
        uint256 _rateLockEndTime
    ) external whenNotPaused onlyWhitelist {
        ValidatorCandidate storage candidate = candidateProfiles[msg.sender];
        require(!candidate.initialized, 'Candidate is initialized');
        require(_commissionRate <= COMMISSION_RATE_BASE, 'Invalid commission rate');

        candidate.initialized = true;
        candidate.minSelfStake = _minSelfStake;
        candidate.commissionRate = _commissionRate;
        candidate.rateLockEndTime = _rateLockEndTime;

        emit InitializeCandidate(msg.sender, _minSelfStake, _commissionRate, _rateLockEndTime);
    }

    /**
     * @notice Apply non-increase-commission-rate changes to commission rate or lock end time,
     *   including decreasing commission rate and/or changing lock end time
     * @dev It can increase lock end time immediately without waiting
     * @param _newRate new commission rate
     * @param _newLockEndTime new lock end time
     */
    function nonIncreaseCommissionRate(uint256 _newRate, uint256 _newLockEndTime)
        external
        isCandidateInitialized
    {
        ValidatorCandidate storage candidate = candidateProfiles[msg.sender];
        require(_newRate <= candidate.commissionRate, 'Invalid new rate');

        _updateCommissionRate(candidate, _newRate, _newLockEndTime);
    }

    /**
     * @notice Announce the intent of increasing the commission rate
     * @param _newRate new commission rate
     * @param _newLockEndTime new lock end time
     */
    function announceIncreaseCommissionRate(uint256 _newRate, uint256 _newLockEndTime)
        external
        isCandidateInitialized
    {
        ValidatorCandidate storage candidate = candidateProfiles[msg.sender];
        require(candidate.commissionRate < _newRate, 'Invalid new rate');

        candidate.announcedRate = _newRate;
        candidate.announcedLockEndTime = _newLockEndTime;
        candidate.announcementTime = block.number;

        emit CommissionRateAnnouncement(msg.sender, _newRate, _newLockEndTime);
    }

    /**
     * @notice Confirm the intent of increasing the commission rate
     */
    function confirmIncreaseCommissionRate() external isCandidateInitialized {
        ValidatorCandidate storage candidate = candidateProfiles[msg.sender];
        require(
            block.number >
                candidate.announcementTime.add(
                    getUIntValue(uint256(ParamNames.AdvanceNoticePeriod))
                ),
            'Still in notice period'
        );

        _updateCommissionRate(candidate, candidate.announcedRate, candidate.announcedLockEndTime);

        delete candidate.announcedRate;
        delete candidate.announcedLockEndTime;
        delete candidate.announcementTime;
    }

    /**
     * @notice update minimal self stake value
     * @param _minSelfStake minimal amount of tokens staked by the validator itself
     */
    function updateMinSelfStake(uint256 _minSelfStake) external isCandidateInitialized {
        ValidatorCandidate storage candidate = candidateProfiles[msg.sender];
        if (_minSelfStake < candidate.minSelfStake) {
            require(candidate.status != DPoSCommon.CandidateStatus.Bonded, 'Candidate is bonded');
            candidate.earliestBondTime = block.number.add(
                getUIntValue(uint256(ParamNames.AdvanceNoticePeriod))
            );
        }
        candidate.minSelfStake = _minSelfStake;
        emit UpdateMinSelfStake(msg.sender, _minSelfStake);
    }

    /**
     * @notice Delegate CELR tokens to a candidate
     * @param _candidateAddr candidate to delegate
     * @param _amount the amount of delegated CELR tokens
     */
    function delegate(address _candidateAddr, uint256 _amount)
        external
        whenNotPaused
        onlyNonZeroAddr(_candidateAddr)
        minAmount(_amount, 1 * DECIMALS_MULTIPLIER) // minimal amount per delegate operation is 1 CELR
    {
        ValidatorCandidate storage candidate = candidateProfiles[_candidateAddr];
        require(candidate.initialized, 'Candidate is not initialized');

        address msgSender = msg.sender;
        _updateDelegatedStake(candidate, _candidateAddr, msgSender, _amount, MathOperation.Add);

        celerToken.safeTransferFrom(msgSender, address(this), _amount);

        emit Delegate(msgSender, _candidateAddr, _amount, candidate.stakingPool);
    }

    /**
     * @notice Candidate claims to become a validator
     */
    function claimValidator() external isCandidateInitialized {
        address msgSender = msg.sender;
        ValidatorCandidate storage candidate = candidateProfiles[msgSender];
        require(
            candidate.status == DPoSCommon.CandidateStatus.Unbonded ||
                candidate.status == DPoSCommon.CandidateStatus.Unbonding,
            'Invalid candidate status'
        );
        require(block.number >= candidate.earliestBondTime, 'Not earliest bond time yet');
        require(
            candidate.stakingPool >= getUIntValue(uint256(ParamNames.MinStakeInPool)),
            'Insufficient staking pool'
        );
        require(
            candidate.delegatorProfiles[msgSender].delegatedStake >= candidate.minSelfStake,
            'Not enough self stake'
        );

        uint256 minStakingPoolIndex;
        uint256 minStakingPool = candidateProfiles[validatorSet[0]].stakingPool;
        require(validatorSet[0] != msgSender, 'Already in validator set');
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));
        for (uint256 i = 1; i < maxValidatorNum; i++) {
            require(validatorSet[i] != msgSender, 'Already in validator set');
            if (candidateProfiles[validatorSet[i]].stakingPool < minStakingPool) {
                minStakingPoolIndex = i;
                minStakingPool = candidateProfiles[validatorSet[i]].stakingPool;
            }
        }
        require(candidate.stakingPool > minStakingPool, 'Not larger than smallest pool');

        address removedValidator = validatorSet[minStakingPoolIndex];
        if (removedValidator != address(0)) {
            _removeValidator(minStakingPoolIndex);
        }
        _addValidator(msgSender, minStakingPoolIndex);
    }

    /**
     * @notice Confirm candidate status from Unbonding to Unbonded
     * @param _candidateAddr the address of the candidate
     */
    function confirmUnbondedCandidate(address _candidateAddr) external {
        ValidatorCandidate storage candidate = candidateProfiles[_candidateAddr];
        require(
            candidate.status == DPoSCommon.CandidateStatus.Unbonding,
            'Candidate not unbonding'
        );
        require(block.number >= candidate.unbondTime, 'Unbonding time not reached');

        candidate.status = DPoSCommon.CandidateStatus.Unbonded;
        delete candidate.unbondTime;
        emit CandidateUnbonded(_candidateAddr);
    }

    /**
     * @notice Withdraw delegated stakes from an unbonded candidate
     * @dev note that the stakes are delegated by the msgSender to the candidate
     * @param _candidateAddr the address of the candidate
     * @param _amount withdrawn amount
     */
    function withdrawFromUnbondedCandidate(address _candidateAddr, uint256 _amount)
        external
        onlyNonZeroAddr(_candidateAddr)
        minAmount(_amount, 1 * DECIMALS_MULTIPLIER)
    {
        ValidatorCandidate storage candidate = candidateProfiles[_candidateAddr];
        require(
            candidate.status == DPoSCommon.CandidateStatus.Unbonded || isMigrating(),
            'invalid status'
        );

        address msgSender = msg.sender;
        _updateDelegatedStake(candidate, _candidateAddr, msgSender, _amount, MathOperation.Sub);
        celerToken.safeTransfer(msgSender, _amount);

        emit WithdrawFromUnbondedCandidate(msgSender, _candidateAddr, _amount);
    }

    /**
     * @notice Intend to withdraw delegated stakes from a candidate
     * @dev note that the stakes are delegated by the msgSender to the candidate
     * @param _candidateAddr the address of the candidate
     * @param _amount withdrawn amount
     */
    function intendWithdraw(address _candidateAddr, uint256 _amount)
        external
        onlyNonZeroAddr(_candidateAddr)
        minAmount(_amount, 1 * DECIMALS_MULTIPLIER)
    {
        address msgSender = msg.sender;

        ValidatorCandidate storage candidate = candidateProfiles[_candidateAddr];
        Delegator storage delegator = candidate.delegatorProfiles[msgSender];

        _updateDelegatedStake(candidate, _candidateAddr, msgSender, _amount, MathOperation.Sub);
        delegator.undelegatingStake = delegator.undelegatingStake.add(_amount);
        _validateValidator(_candidateAddr);

        WithdrawIntent storage withdrawIntent = delegator.withdrawIntents[delegator.intentEndIndex];
        withdrawIntent.amount = _amount;
        withdrawIntent.proposedTime = block.number;
        delegator.intentEndIndex++;

        emit IntendWithdraw(msgSender, _candidateAddr, _amount, withdrawIntent.proposedTime);
    }

    /**
     * @notice Confirm an intent of withdrawing delegated stakes from a candidate
     * @dev note that the stakes are delegated by the msgSender to the candidate
     * @param _candidateAddr the address of the candidate
     */
    function confirmWithdraw(address _candidateAddr) external onlyNonZeroAddr(_candidateAddr) {
        address msgSender = msg.sender;
        Delegator storage delegator = candidateProfiles[_candidateAddr]
            .delegatorProfiles[msgSender];

        uint256 slashTimeout = getUIntValue(uint256(ParamNames.SlashTimeout));
        bool isUnbonded = candidateProfiles[_candidateAddr].status ==
            DPoSCommon.CandidateStatus.Unbonded;
        // for all undelegated withdraw intents
        uint256 i;
        for (i = delegator.intentStartIndex; i < delegator.intentEndIndex; i++) {
            if (
                isUnbonded ||
                delegator.withdrawIntents[i].proposedTime.add(slashTimeout) <= block.number
            ) {
                // withdraw intent is undelegated when the validator becomes unbonded or
                // the slashTimeout for the withdraw intent is up.
                delete delegator.withdrawIntents[i];
                continue;
            }
            break;
        }
        delegator.intentStartIndex = i;
        // for all undelegating withdraw intents
        uint256 undelegatingStakeWithoutSlash;
        for (; i < delegator.intentEndIndex; i++) {
            undelegatingStakeWithoutSlash = undelegatingStakeWithoutSlash.add(
                delegator.withdrawIntents[i].amount
            );
        }

        uint256 withdrawAmt;
        if (delegator.undelegatingStake > undelegatingStakeWithoutSlash) {
            withdrawAmt = delegator.undelegatingStake.sub(undelegatingStakeWithoutSlash);
            delegator.undelegatingStake = undelegatingStakeWithoutSlash;

            celerToken.safeTransfer(msgSender, withdrawAmt);
        }

        emit ConfirmWithdraw(msgSender, _candidateAddr, withdrawAmt);
    }

    /**
     * @notice Slash a validator and its delegators
     * @param _penaltyRequest penalty request bytes coded in protobuf
     */
    function slash(bytes calldata _penaltyRequest)
        external
        whenNotPaused
        onlyValidDPoS
        onlyNotMigrating
    {
        require(enableSlash, 'Slash is disabled');
        PbSgn.PenaltyRequest memory penaltyRequest = PbSgn.decPenaltyRequest(_penaltyRequest);
        PbSgn.Penalty memory penalty = PbSgn.decPenalty(penaltyRequest.penalty);

        ValidatorCandidate storage validator = candidateProfiles[penalty.validatorAddress];
        require(validator.status != DPoSCommon.CandidateStatus.Unbonded, 'Validator unbounded');

        bytes32 h = keccak256(penaltyRequest.penalty);
        require(_checkValidatorSigs(h, penaltyRequest.sigs), 'Validator sigs verification failed');
        require(block.number < penalty.expireTime, 'Penalty expired');
        require(!usedPenaltyNonce[penalty.nonce], 'Used penalty nonce');
        usedPenaltyNonce[penalty.nonce] = true;

        uint256 totalSubAmt;
        for (uint256 i = 0; i < penalty.penalizedDelegators.length; i++) {
            PbSgn.AccountAmtPair memory penalizedDelegator = penalty.penalizedDelegators[i];
            totalSubAmt = totalSubAmt.add(penalizedDelegator.amt);
            emit Slash(
                penalty.validatorAddress,
                penalizedDelegator.account,
                penalizedDelegator.amt
            );

            Delegator storage delegator = validator.delegatorProfiles[penalizedDelegator.account];
            uint256 _amt;
            if (delegator.delegatedStake >= penalizedDelegator.amt) {
                _amt = penalizedDelegator.amt;
            } else {
                uint256 remainingAmt = penalizedDelegator.amt.sub(delegator.delegatedStake);
                delegator.undelegatingStake = delegator.undelegatingStake.sub(remainingAmt);
                _amt = delegator.delegatedStake;
            }
            _updateDelegatedStake(
                validator,
                penalty.validatorAddress,
                penalizedDelegator.account,
                _amt,
                MathOperation.Sub
            );
        }
        _validateValidator(penalty.validatorAddress);

        uint256 totalAddAmt;
        for (uint256 i = 0; i < penalty.beneficiaries.length; i++) {
            PbSgn.AccountAmtPair memory beneficiary = penalty.beneficiaries[i];
            totalAddAmt = totalAddAmt.add(beneficiary.amt);

            if (beneficiary.account == address(0)) {
                // address(0) stands for miningPool
                miningPool = miningPool.add(beneficiary.amt);
            } else if (beneficiary.account == address(1)) {
                // address(1) means beneficiary is msg sender
                celerToken.safeTransfer(msg.sender, beneficiary.amt);
                emit Compensate(msg.sender, beneficiary.amt);
            } else {
                celerToken.safeTransfer(beneficiary.account, beneficiary.amt);
                emit Compensate(beneficiary.account, beneficiary.amt);
            }
        }

        require(totalSubAmt == totalAddAmt, 'Amount not match');
    }

    /**
     * @notice Validate multi-signed message
     * @dev Can't use view here because _checkValidatorSigs is not a view function
     * @param _request a multi-signed message bytes coded in protobuf
     * @return passed the validation or not
     */
    function validateMultiSigMessage(bytes calldata _request)
        external
        onlyRegisteredSidechains
        returns (bool)
    {
        PbSgn.MultiSigMessage memory request = PbSgn.decMultiSigMessage(_request);
        bytes32 h = keccak256(request.msg);

        return _checkValidatorSigs(h, request.sigs);
    }

    /**
     * @notice Get the minimum staking pool of all validators
     * @return the minimum staking pool of all validators
     */
    function getMinStakingPool() external view returns (uint256) {
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));

        uint256 minStakingPool = candidateProfiles[validatorSet[0]].stakingPool;
        for (uint256 i = 0; i < maxValidatorNum; i++) {
            if (validatorSet[i] == address(0)) {
                return 0;
            }
            if (candidateProfiles[validatorSet[i]].stakingPool < minStakingPool) {
                minStakingPool = candidateProfiles[validatorSet[i]].stakingPool;
            }
        }

        return minStakingPool;
    }

    /**
     * @notice Get candidate info
     * @param _candidateAddr the address of the candidate
     * @return initialized whether initialized or not
     * @return minSelfStake minimum self stakes
     * @return stakingPool staking pool
     * @return status candidate status
     * @return unbondTime unbond time
     * @return commissionRate commission rate
     * @return rateLockEndTime commission rate lock end time
     */
    function getCandidateInfo(address _candidateAddr)
        external
        view
        returns (
            bool initialized,
            uint256 minSelfStake,
            uint256 stakingPool,
            uint256 status,
            uint256 unbondTime,
            uint256 commissionRate,
            uint256 rateLockEndTime
        )
    {
        ValidatorCandidate memory c = candidateProfiles[_candidateAddr];

        initialized = c.initialized;
        minSelfStake = c.minSelfStake;
        stakingPool = c.stakingPool;
        status = uint256(c.status);
        unbondTime = c.unbondTime;
        commissionRate = c.commissionRate;
        rateLockEndTime = c.rateLockEndTime;
    }

    /**
     * @notice Get the delegator info of a specific candidate
     * @param _candidateAddr the address of the candidate
     * @param _delegatorAddr the address of the delegator
     * @return delegatedStake delegated stake to this candidate
     * @return undelegatingStake undelegating stakes
     * @return intentAmounts the amounts of withdraw intents
     * @return intentProposedTimes the proposed times of withdraw intents
     */
    function getDelegatorInfo(address _candidateAddr, address _delegatorAddr)
        external
        view
        returns (
            uint256 delegatedStake,
            uint256 undelegatingStake,
            uint256[] memory intentAmounts,
            uint256[] memory intentProposedTimes
        )
    {
        Delegator storage d = candidateProfiles[_candidateAddr].delegatorProfiles[_delegatorAddr];

        uint256 len = d.intentEndIndex.sub(d.intentStartIndex);
        intentAmounts = new uint256[](len);
        intentProposedTimes = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            intentAmounts[i] = d.withdrawIntents[i + d.intentStartIndex].amount;
            intentProposedTimes[i] = d.withdrawIntents[i + d.intentStartIndex].proposedTime;
        }

        delegatedStake = d.delegatedStake;
        undelegatingStake = d.undelegatingStake;
    }

    /**
     * @notice Check this DPoS contract is valid or not now
     * @return DPoS is valid or not
     */
    function isValidDPoS() public view returns (bool) {
        return
            block.number >= dposGoLiveTime &&
            getValidatorNum() >= getUIntValue(uint256(ParamNames.MinValidatorNum));
    }

    /**
     * @notice Check the given address is a validator or not
     * @param _addr the address to check
     * @return the given address is a validator or not
     */
    function isValidator(address _addr) public view returns (bool) {
        return candidateProfiles[_addr].status == DPoSCommon.CandidateStatus.Bonded;
    }

    /**
     * @notice Check if the contract is in migrating state
     * @return contract in migrating state or not
     */
    function isMigrating() public view returns (bool) {
        uint256 migrationTime = getUIntValue(uint256(ParamNames.MigrationTime));
        return migrationTime != 0 && block.number >= migrationTime;
    }

    /**
     * @notice Get the number of validators
     * @return the number of validators
     */
    function getValidatorNum() public view returns (uint256) {
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));

        uint256 num;
        for (uint256 i = 0; i < maxValidatorNum; i++) {
            if (validatorSet[i] != address(0)) {
                num++;
            }
        }
        return num;
    }

    /**
     * @notice Get minimum amount of stakes for a quorum
     * @return the minimum amount
     */
    function getMinQuorumStakingPool() public view returns (uint256) {
        return getTotalValidatorStakingPool().mul(2).div(3).add(1);
    }

    /**
     * @notice Get the total amount of stakes in validators' staking pools
     * @return the total amount
     */
    function getTotalValidatorStakingPool() public view returns (uint256) {
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));

        uint256 totalValidatorStakingPool;
        for (uint256 i = 0; i < maxValidatorNum; i++) {
            totalValidatorStakingPool = totalValidatorStakingPool.add(
                candidateProfiles[validatorSet[i]].stakingPool
            );
        }

        return totalValidatorStakingPool;
    }

    /**
     * @notice Update the commission rate of a candidate
     * @param _candidate the candidate to update
     * @param _newRate new commission rate
     * @param _newLockEndTime new lock end time
     */
    function _updateCommissionRate(
        ValidatorCandidate storage _candidate,
        uint256 _newRate,
        uint256 _newLockEndTime
    ) private {
        require(_newRate <= COMMISSION_RATE_BASE, 'Invalid new rate');
        require(_newLockEndTime >= block.number, 'Outdated new lock end time');

        if (_newRate <= _candidate.commissionRate) {
            require(_newLockEndTime >= _candidate.rateLockEndTime, 'Invalid new lock end time');
        } else {
            require(block.number > _candidate.rateLockEndTime, 'Commission rate is locked');
        }

        _candidate.commissionRate = _newRate;
        _candidate.rateLockEndTime = _newLockEndTime;

        emit UpdateCommissionRate(msg.sender, _newRate, _newLockEndTime);
    }

    /**
     * @notice Update the delegated stake of a delegator to an candidate
     * @param _candidate the candidate
     * @param _delegatorAddr the delegator address
     * @param _amount update amount
     * @param _op update operation
     */
    function _updateDelegatedStake(
        ValidatorCandidate storage _candidate,
        address _candidateAddr,
        address _delegatorAddr,
        uint256 _amount,
        MathOperation _op
    ) private {
        Delegator storage delegator = _candidate.delegatorProfiles[_delegatorAddr];

        if (_op == MathOperation.Add) {
            _candidate.stakingPool = _candidate.stakingPool.add(_amount);
            delegator.delegatedStake = delegator.delegatedStake.add(_amount);
        } else if (_op == MathOperation.Sub) {
            _candidate.stakingPool = _candidate.stakingPool.sub(_amount);
            delegator.delegatedStake = delegator.delegatedStake.sub(_amount);
        } else {
            assert(false);
        }
        emit UpdateDelegatedStake(
            _delegatorAddr,
            _candidateAddr,
            delegator.delegatedStake,
            _candidate.stakingPool
        );
    }

    /**
     * @notice Add a validator
     * @param _validatorAddr the address of the validator
     * @param _setIndex the index to put the validator
     */
    function _addValidator(address _validatorAddr, uint256 _setIndex) private {
        require(validatorSet[_setIndex] == address(0), 'Validator slot occupied');

        validatorSet[_setIndex] = _validatorAddr;
        candidateProfiles[_validatorAddr].status = DPoSCommon.CandidateStatus.Bonded;
        delete candidateProfiles[_validatorAddr].unbondTime;
        emit ValidatorChange(_validatorAddr, ValidatorChangeType.Add);
    }

    /**
     * @notice Remove a validator
     * @param _setIndex the index of the validator to be removed
     */
    function _removeValidator(uint256 _setIndex) private {
        address removedValidator = validatorSet[_setIndex];
        if (removedValidator == address(0)) {
            return;
        }

        delete validatorSet[_setIndex];
        candidateProfiles[removedValidator].status = DPoSCommon.CandidateStatus.Unbonding;
        candidateProfiles[removedValidator].unbondTime = block.number.add(
            getUIntValue(uint256(ParamNames.SlashTimeout))
        );
        emit ValidatorChange(removedValidator, ValidatorChangeType.Removal);
    }

    /**
     * @notice Validate a validator status after stakes change
     * @dev remove this validator if it doesn't meet the requirement of being a validator
     * @param _validatorAddr the validator address
     */
    function _validateValidator(address _validatorAddr) private {
        ValidatorCandidate storage v = candidateProfiles[_validatorAddr];
        if (v.status != DPoSCommon.CandidateStatus.Bonded) {
            // no need to validate the stake of a non-validator
            return;
        }

        bool lowSelfStake = v.delegatorProfiles[_validatorAddr].delegatedStake < v.minSelfStake;
        bool lowStakingPool = v.stakingPool < getUIntValue(uint256(ParamNames.MinStakeInPool));

        if (lowSelfStake || lowStakingPool) {
            _removeValidator(_getValidatorIdx(_validatorAddr));
        }
    }

    /**
     * @notice Check whether validators with more than 2/3 total stakes have signed this hash
     * @param _h signed hash
     * @param _sigs signatures
     * @return whether the signatures are valid or not
     */
    function _checkValidatorSigs(bytes32 _h, bytes[] memory _sigs) private returns (bool) {
        uint256 minQuorumStakingPool = getMinQuorumStakingPool();

        bytes32 hash = _h.toEthSignedMessageHash();
        address[] memory addrs = new address[](_sigs.length);
        uint256 quorumStakingPool;
        bool hasDuplicatedSig;
        for (uint256 i = 0; i < _sigs.length; i++) {
            addrs[i] = hash.recover(_sigs[i]);
            if (checkedValidators[addrs[i]]) {
                hasDuplicatedSig = true;
                break;
            }
            if (candidateProfiles[addrs[i]].status != DPoSCommon.CandidateStatus.Bonded) {
                continue;
            }

            quorumStakingPool = quorumStakingPool.add(candidateProfiles[addrs[i]].stakingPool);
            checkedValidators[addrs[i]] = true;
        }

        for (uint256 i = 0; i < _sigs.length; i++) {
            checkedValidators[addrs[i]] = false;
        }

        return !hasDuplicatedSig && quorumStakingPool >= minQuorumStakingPool;
    }

    /**
     * @notice Get validator index
     * @param _addr the validator address
     * @return the index of the validator
     */
    function _getValidatorIdx(address _addr) private view returns (uint256) {
        uint256 maxValidatorNum = getUIntValue(uint256(ParamNames.MaxValidatorNum));

        for (uint256 i = 0; i < maxValidatorNum; i++) {
            if (validatorSet[i] == _addr) {
                return i;
            }
        }

        revert('No such a validator');
    }
}