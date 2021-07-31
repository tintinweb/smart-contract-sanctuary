// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./common/Ownable.sol";
import "./common/Pausable.sol";
import "./common/DailyLimit.sol";
import "./interfaces/IRelay.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISettingsRegistry.sol";
import { ScaleStruct } from "./common/Scale.struct.sol";

import "./common/Scale.sol";
import "./common/SafeMath.sol";

pragma experimental ABIEncoderV2;

contract TokenIssuing is DailyLimit, Ownable, Pausable, Initializable {

    event MintRingEvent(address recipient, uint256 value, bytes32 accountId);
    event MintKtonEvent(address recipient, uint256 value, bytes32 accountId);
    event MintTokenEvent(address token, address recipient, uint256 value, bytes32 accountId);
    event VerifyProof(uint32 darwiniaBlockNumber);

    bytes public storageKey;

    ISettingsRegistry public registry;
    IRelay public relay;

    // Record the block height that has been verified
    mapping(uint32 => bool) history;

    bytes[] darwiniaLockEventsStorageKeys;
    uint32[] darwiniaUpgradeBlockNumber;

    function initialize(address _registry, address _relay, bytes memory _key) public initializer {
        ownableConstructor();
        pausableConstructor();

        relay = IRelay(_relay);
        registry = ISettingsRegistry(_registry);

        storageKey = _key;
    }

    function getHistory(uint32 blockNumber) public view returns (bool) {
      return history[blockNumber];
    }

    // The last step of the cross-chain of darwinia to ethereum, the user needs to collect some signatures and proofs after the darwinia network lock token.
    // This call will append mmr root and verify mmr proot, events proof, and mint token by decoding events. If this mmr root is already included in the relay contract, the contract will skip verifying mmr root msg, saving gas.

    // message - bytes4 prefix + uint32 mmr-index + bytes32 mmr-root
    // signatures - the signatures for mmr-root msg
    // root, MMRIndex - mmr root for the block
    // blockNumber, blockHeader - The block where the lock token event occurred in darwinia network
    // can be fetched by api.rpc.chain.getHeader('block hash') 
    // peaks, siblings - mmr proof for the blockNumber
    // eventsProofStr - mpt proof for events
    // Vec<Vec<u8>> encoded by Scale codec
    function appendRootAndVerifyProof(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    )
      public
      whenNotPaused
    {
      // If the root of this index already exists in the mmr root pool, 
      // skip append root to save gas
      if(relay.getMMRRoot(MMRIndex) == bytes32(0)) {
        relay.appendRoot(message, signatures);
      }

      verifyProof(root, MMRIndex, blockHeader, peaks, siblings, eventsProofStr);
    }

    function verifyProof(
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) 
      public
      whenNotPaused
    {
        uint32 blockNumber = Scale.decodeBlockNumberFromBlockHeader(blockHeader);

        require(!history[blockNumber], "TokenIssuing:: verifyProof:  The block has been verified");

        bytes memory matchedStorageKey = getMatchedStorageKey(blockNumber);

        Input.Data memory data = Input.from(relay.verifyRootAndDecodeReceipt(root, MMRIndex, blockNumber, blockHeader, peaks, siblings, eventsProofStr, matchedStorageKey));
        
        ScaleStruct.LockEvent[] memory events = Scale.decodeLockEvents(data);

        address ring = registry.addressOf(bytes32("CONTRACT_RING_ERC20_TOKEN"));
        address kton = registry.addressOf(bytes32("CONTRACT_KTON_ERC20_TOKEN"));

        uint256 len = events.length;

        for( uint i = 0; i < len; i++ ) {
          ScaleStruct.LockEvent memory item = events[i];
          uint256 value = decimalsConverter(item.value);
          if(item.token == ring) {
            expendDailyLimit(ring, value);
            IERC20(ring).mint(item.recipient, value);

            emit MintRingEvent(item.recipient, value, item.sender);
          }

          if (item.token == kton) {
            expendDailyLimit(kton, value);
            IERC20(kton).mint(item.recipient, value);

            emit MintKtonEvent(item.recipient, value, item.sender);
          }
        }

        history[blockNumber] = true;
        emit VerifyProof(blockNumber);
    }

    function getMatchedStorageKey(uint32 blockNumber) public returns (bytes memory) {
      for( uint i = darwiniaUpgradeBlockNumber.length - 1; i >= 0; i-- ) {
        if(darwiniaUpgradeBlockNumber[i] <= blockNumber) {
          return darwiniaLockEventsStorageKeys[i];
        }
      }
    }

    // The token decimals in Crab, Darwinia Netowrk is 9, in Ethereum Network is 18.
    function decimalsConverter(uint256 darwiniaValue) public pure returns (uint256) {
      return SafeMath.mul(darwiniaValue, 1000000000);
    }

    /// ==== onlyOwner ==== 
    function setStorageKey(bytes memory key) public onlyOwner {
      storageKey = key;
    } 

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function setDailyLimit(address token, uint amount) public onlyOwner  {
        _setDailyLimit(token, amount);
    }

    function changeDailyLimit(address token, uint amount) public onlyOwner  {
        _changeDailyLimit(token, amount);
    }

    function setDarwiniaUpgradeBlockNumber(uint256 index, uint32 upgradeBlockNumber, bytes memory key) public onlyOwner {
      darwiniaLockEventsStorageKeys[index] = key;
      darwiniaUpgradeBlockNumber[index] = upgradeBlockNumber;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function ownableConstructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function pausableConstructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

/// @title relay with daily limit - Allows the relay to mint token in a daily limit.
contract DailyLimit {

    event DailyLimitChange(address token, uint dailyLimit);

    mapping(address => uint) public dailyLimit;
    mapping(address => uint) public lastDay;
    mapping(address => uint) public spentToday;

    /// ==== Internal functions ==== 

    /// @dev Contract constructor sets initial owners, required number of confirmations and daily mint limit.
    /// @param _token Token address.
    /// @param _dailyLimit Amount in wei, which can be mint without confirmations on a daily basis.
    function _setDailyLimit(address _token, uint _dailyLimit)
        internal
    {
        dailyLimit[_token] = _dailyLimit;
    }

    /// @dev Allows to change the daily limit.
    /// @param _token Token address.
    /// @param _dailyLimit Amount in wei.
    function _changeDailyLimit(address _token, uint _dailyLimit)
        internal
    {
        dailyLimit[_token] = _dailyLimit;
        emit DailyLimitChange(_token, _dailyLimit);
    }

    /// @dev Allows to change the daily limit.
    /// @param token Token address.
    /// @param amount Amount in wei.
    function expendDailyLimit(address token, uint amount)
        internal
    {
        require(isUnderDailyLimit(token, amount), "DailyLimit:: expendDailyLimit: Out ot daily limit.");
        spentToday[token] += amount;
    }

    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param token Token address.
    /// @param amount Amount to calc.
    /// @return Returns if amount is under daily limit.
    function isUnderDailyLimit(address token, uint amount)
        internal
        returns (bool)
    {
        if (now > lastDay[token] + 24 hours) {
            lastDay[token] = now;
            spentToday[token] = 0;
        }

        if (spentToday[token] + amount > dailyLimit[token] || spentToday[token] + amount < spentToday[token]) {
          return false;
        }
            
        return true;
    }

    /// ==== Web3 call functions ==== 

    /// @dev Returns maximum withdraw amount.
    /// @param token Token address.
    /// @return Returns amount.
    function calcMaxWithdraw(address token)
        public
        view
        returns (uint)
    {
        if (now > lastDay[token] + 24 hours) {
          return dailyLimit[token];
        }

        if (dailyLimit[token] < spentToday[token]) {
          return 0;
        }

        return dailyLimit[token] - spentToday[token];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

pragma experimental ABIEncoderV2;

interface IRelay {
      function verifyRootAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes calldata blockHeader,
        bytes32[] calldata peaks,
        bytes32[] calldata siblings,
        bytes calldata proofstr,
        bytes calldata key
    ) external view returns (bytes memory);

     function appendRoot(
        bytes calldata message,
        bytes[] calldata signatures
    ) external;

    function getMMRRoot(uint32 index) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address _who) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function mint(address _to, uint256 _value) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

interface ISettingsRegistry {
    function addressOf(bytes32 _propertyName) external view returns (address);
    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library ScaleStruct {
    struct LockEvent {
        bytes2 index;
        bytes32 sender;
        address recipient;
        address token;
        uint128 value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Input.sol";
import "./Bytes.sol";
import { ScaleStruct } from "./Scale.struct.sol";

pragma experimental ABIEncoderV2;

library Scale {
    using Input for Input.Data;
    using Bytes for bytes;

    // Vec<Event>    Event = <index, Data>   Data = {accountId, EthereumAddress, types, Balance}
    // bytes memory hexData = hex"102403d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27ddac17f958d2ee523a2206206994597c13d831ec700000e5fa31c00000000000000000000002404d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27ddac17f958d2ee523a2206206994597c13d831ec70100e40b5402000000000000000000000024038eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48b20bd5d04be54f870d5c0d3ca85d82b34b8364050000d0b72b6a000000000000000000000024048eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48b20bd5d04be54f870d5c0d3ca85d82b34b8364050100c817a8040000000000000000000000";
    function decodeLockEvents(Input.Data memory data)
        internal
        pure
        returns (ScaleStruct.LockEvent[] memory)
    {
        uint32 len = decodeU32(data);
        ScaleStruct.LockEvent[] memory events = new ScaleStruct.LockEvent[](len);

        for(uint i = 0; i < len; i++) {
            events[i] = ScaleStruct.LockEvent({
                index: data.decodeBytesN(2).toBytes2(0),
                sender: decodeAccountId(data),
                recipient: decodeEthereumAddress(data),
                token: decodeEthereumAddress(data),
                value: decodeBalance(data)
            });
        }

        return events;
    }

    /** Header */
    // export interface Header extends Struct {
    //     readonly parentHash: Hash;
    //     readonly number: Compact<BlockNumber>;
    //     readonly stateRoot: Hash;
    //     readonly extrinsicsRoot: Hash;
    //     readonly digest: Digest;
    // }
    function decodeStateRootFromBlockHeader(
        bytes memory header
    ) internal pure returns (bytes32 root) {
        uint8 offset = decodeCompactU8aOffset(header[32]);
        assembly {
            root := mload(add(add(header, 0x40), offset))
        }
        return root;
    }

    function decodeBlockNumberFromBlockHeader(
        bytes memory header
    ) internal pure returns (uint32 blockNumber) {
        Input.Data memory data = Input.from(header);
        
        // skip parentHash(Hash)
        data.shiftBytes(32);

        blockNumber = decodeU32(data);
    }

    // little endian
    function decodeMMRRoot(Input.Data memory data) 
        internal
        pure
        returns (bytes memory prefix, bytes4 methodID, uint32 width, bytes32 root)
    {
        prefix = decodePrefix(data);
        methodID = data.decodeBytes4();
        width = decodeU32(data);
        root = data.decodeBytes32();
    }

    function decodeAuthorities(Input.Data memory data)
        internal
        pure
        returns (bytes memory prefix, bytes4 methodID, uint32 nonce, address[] memory authorities)
    {
        prefix = decodePrefix(data);
        methodID = data.decodeBytes4();
        nonce = decodeU32(data);

        uint authoritiesLength = decodeU32(data);

        authorities = new address[](authoritiesLength);
        for(uint i = 0; i < authoritiesLength; i++) {
            authorities[i] = decodeEthereumAddress(data);
        }
    }

    // decode authorities prefix
    // (crab, darwinia)
    function decodePrefix(Input.Data memory data) 
        internal
        pure
        returns (bytes memory prefix) 
    {
        prefix = decodeByteArray(data);
    }

    // decode Ethereum address
    function decodeEthereumAddress(Input.Data memory data) 
        internal
        pure
        returns (address addr) 
    {
        bytes memory bys = data.decodeBytesN(20);
        assembly {
            addr := mload(add(bys,20))
        } 
    }

    // decode Balance
    function decodeBalance(Input.Data memory data) 
        internal
        pure
        returns (uint128) 
    {
        bytes memory balance = data.decodeBytesN(16);
        return uint128(reverseBytes16(balance.toBytes16(0)));
    }

    // decode darwinia network account Id
    function decodeAccountId(Input.Data memory data) 
        internal
        pure
        returns (bytes32 accountId) 
    {
        accountId = data.decodeBytes32();
    }

    // decodeReceiptProof receives Scale Codec of Vec<Vec<u8>> structure, 
    // the Vec<u8> is the proofs of mpt
    // returns (bytes[] memory proofs)
    function decodeReceiptProof(Input.Data memory data) 
        internal
        pure
        returns (bytes[] memory proofs) 
    {
        proofs = decodeVecBytesArray(data);
    }

    // decodeVecBytesArray accepts a Scale Codec of type Vec<Bytes> and returns an array of Bytes
    function decodeVecBytesArray(Input.Data memory data)
        internal
        pure
        returns (bytes[] memory v) 
    {
        uint32 vecLenght = decodeU32(data);
        v = new bytes[](vecLenght);
        for(uint i = 0; i < vecLenght; i++) {
            uint len = decodeU32(data);
            v[i] = data.decodeBytesN(len);
        }
        return v;
    }

    // decodeByteArray accepts a byte array representing a SCALE encoded byte array and performs SCALE decoding
    // of the byte array
    function decodeByteArray(Input.Data memory data)
        internal
        pure
        returns (bytes memory v)
    {
        uint32 len = decodeU32(data);
        if (len == 0) {
            return v;
        }
        v = data.decodeBytesN(len);
        return v;
    }

    // decodeU32 accepts a byte array representing a SCALE encoded integer and performs SCALE decoding of the smallint
    function decodeU32(Input.Data memory data) internal pure returns (uint32) {
        uint8 b0 = data.decodeU8();
        uint8 mode = b0 & 3;
        require(mode <= 2, "scale decode not support");
        if (mode == 0) {
            return uint32(b0) >> 2;
        } else if (mode == 1) {
            uint8 b1 = data.decodeU8();
            uint16 v = uint16(b0) | (uint16(b1) << 8);
            return uint32(v) >> 2;
        } else if (mode == 2) {
            uint8 b1 = data.decodeU8();
            uint8 b2 = data.decodeU8();
            uint8 b3 = data.decodeU8();
            uint32 v = uint32(b0) |
                (uint32(b1) << 8) |
                (uint32(b2) << 16) |
                (uint32(b3) << 24);
            return v >> 2;
        }
    }

    // encodeByteArray performs the following:
    // b -> [encodeInteger(len(b)) b]
    function encodeByteArray(bytes memory src)
        internal
        pure
        returns (bytes memory des, uint256 bytesEncoded)
    {
        uint256 n;
        (des, n) = encodeU32(uint32(src.length));
        bytesEncoded = n + src.length;
        des = abi.encodePacked(des, src);
    }

    // encodeU32 performs the following on integer i:
    // i  -> i^0...i^n where n is the length in bits of i
    // if n < 2^6 write [00 i^2...i^8 ] [ 8 bits = 1 byte encoded  ]
    // if 2^6 <= n < 2^14 write [01 i^2...i^16] [ 16 bits = 2 byte encoded  ]
    // if 2^14 <= n < 2^30 write [10 i^2...i^32] [ 32 bits = 4 byte encoded  ]
    function encodeU32(uint32 i) internal pure returns (bytes memory, uint256) {
        // 1<<6
        if (i < 64) {
            uint8 v = uint8(i) << 2;
            bytes1 b = bytes1(v);
            bytes memory des = new bytes(1);
            des[0] = b;
            return (des, 1);
            // 1<<14
        } else if (i < 16384) {
            uint16 v = uint16(i << 2) + 1;
            bytes memory des = new bytes(2);
            des[0] = bytes1(uint8(v));
            des[1] = bytes1(uint8(v >> 8));
            return (des, 2);
            // 1<<30
        } else if (i < 1073741824) {
            uint32 v = uint32(i << 2) + 2;
            bytes memory des = new bytes(4);
            des[0] = bytes1(uint8(v));
            des[1] = bytes1(uint8(v >> 8));
            des[2] = bytes1(uint8(v >> 16));
            des[3] = bytes1(uint8(v >> 24));
            return (des, 4);
        } else {
            revert("scale encode not support");
        }
    }

    // convert BigEndian to LittleEndian 
    function reverseBytes16(bytes16 input) internal pure returns (bytes16 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function decodeCompactU8aOffset(bytes1 input0) public pure returns (uint8) {
        bytes1 flag = input0 & bytes1(hex"03");
        if (flag == hex"00") {
            return 1;
        } else if (flag == hex"01") {
            return 2;
        } else if (flag == hex"02") {
            return 4;
        }
        uint8 offset = (uint8(input0) >> 2) + 4 + 1;
        return offset;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Bytes.sol";

library Input {
    using Bytes for bytes;

    struct Data {
        uint256 offset;
        bytes raw;
    }

    function from(bytes memory data) internal pure returns (Data memory) {
        return Data({offset: 0, raw: data});
    }

    modifier shift(Data memory data, uint256 size) {
        require(data.raw.length >= data.offset + size, "Input: Out of range");
        _;
        data.offset += size;
    }

    function shiftBytes(Data memory data, uint256 size) internal pure {
        require(data.raw.length >= data.offset + size, "Input: Out of range");
        data.offset += size;
    }

    function finished(Data memory data) internal pure returns (bool) {
        return data.offset == data.raw.length;
    }

    function peekU8(Data memory data) internal pure returns (uint8 v) {
        return uint8(data.raw[data.offset]);
    }

    function decodeU8(Data memory data)
        internal
        pure
        shift(data, 1)
        returns (uint8 value)
    {
        value = uint8(data.raw[data.offset]);
    }

    function decodeU16(Data memory data) internal pure returns (uint16 value) {
        value = uint16(decodeU8(data));
        value |= (uint16(decodeU8(data)) << 8);
    }

    function decodeU32(Data memory data) internal pure returns (uint32 value) {
        value = uint32(decodeU16(data));
        value |= (uint32(decodeU16(data)) << 16);
    }

    function decodeBytesN(Data memory data, uint256 N)
        internal
        pure
        shift(data, N)
        returns (bytes memory value)
    {
        value = data.raw.substr(data.offset, N);
    }

    function decodeBytes4(Data memory data) internal pure shift(data, 4) returns(bytes4 value) {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;

        assembly {
            value := mload(add(add(raw, 32), offset))
        }
    }

    function decodeBytes32(Data memory data) internal pure shift(data, 32) returns(bytes32 value) {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;

        assembly {
            value := mload(add(add(raw, 32), offset))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import {Memory} from "./Memory.sol";

library Bytes {
    uint256 internal constant BYTES_HEADER_SIZE = 32;

    // Checks if two `bytes memory` variables are equal. This is done using hashing,
    // which is much more gas efficient then comparing each byte individually.
    // Equality means that:
    //  - 'self.length == other.length'
    //  - For 'n' in '[0, self.length)', 'self[n] == other[n]'
    function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint addr;
        uint addr2;
        assembly {
            addr := add(self, /*BYTES_HEADER_SIZE*/32)
            addr2 := add(other, /*BYTES_HEADER_SIZE*/32)
        }
        equal = Memory.equals(addr, addr2, self.length);
    }

    // Copies a section of 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that 'startIndex <= self.length'
    // The length of the substring is: 'self.length - startIndex'
    function substr(bytes memory self, uint256 startIndex)
        internal
        pure
        returns (bytes memory)
    {
        require(startIndex <= self.length);
        uint256 len = self.length - startIndex;
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function substr(
        bytes memory self,
        uint256 startIndex,
        uint256 len
    ) internal pure returns (bytes memory) {
        require(startIndex + len <= self.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Combines 'self' and 'other' into a single array.
    // Returns the concatenated arrays:
    //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // The length of the new array is 'self.length + other.length'
    function concat(bytes memory self, bytes memory other)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory ret = new bytes(self.length + other.length);
        uint256 src;
        uint256 srcLen;
        (src, srcLen) = Memory.fromBytes(self);
        uint256 src2;
        uint256 src2Len;
        (src2, src2Len) = Memory.fromBytes(other);
        uint256 dest;
        (dest, ) = Memory.fromBytes(ret);
        uint256 dest2 = dest + srcLen;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
        return ret;
    }

    function toBytes32(bytes memory self)
        internal
        pure
        returns (bytes32 out)
    {
        require(self.length >= 32, "Bytes:: toBytes32: data is to short.");
        assembly {
            out := mload(add(self, 32))
        }
    }

    function toBytes16(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes16 out)
    {
        for (uint i = 0; i < 16; i++) {
            out |= bytes16(byte(self[offset + i]) & 0xFF) >> (i * 8);
        }
    }

    function toBytes4(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes4)
    {
        bytes4 out;

        for (uint256 i = 0; i < 4; i++) {
            out |= bytes4(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function toBytes2(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes2)
    {
        bytes2 out;

        for (uint256 i = 0; i < 2; i++) {
            out |= bytes2(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library Memory {

    uint internal constant WORD_SIZE = 32;

	// Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'

    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }
	// Returns a memory pointer to the data portion of the provided bytes array.
	function dataPtr(bytes memory bts) internal pure returns (uint addr) {
		assembly {
			addr := add(bts, /*BYTES_HEADER_SIZE*/32)
		}
	}

	// Creates a 'bytes memory' variable from the memory address 'addr', with the
	// length 'len'. The function will allocate new memory for the bytes array, and
	// the 'len bytes starting at 'addr' will be copied into that new memory.
	function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
		bts = new bytes(len);
		uint btsptr;
		assembly {
			btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
		}
		copy(addr, btsptr, len);
	}
	
	// Copies 'self' into a new 'bytes memory'.
	// Returns the newly created 'bytes memory'
	// The returned bytes will be of length '32'.
	function toBytes(bytes32 self) internal pure returns (bytes memory bts) {
		bts = new bytes(32);
		assembly {
			mstore(add(bts, /*BYTES_HEADER_SIZE*/32), self)
		}
	}

	// Copy 'len' bytes from memory address 'src', to address 'dest'.
	// This function does not check the or destination, it only copies
	// the bytes.
	function copy(uint src, uint dest, uint len) internal pure {
		// Copy word-length chunks while possible
		for (; len >= WORD_SIZE; len -= WORD_SIZE) {
			assembly {
				mstore(dest, mload(src))
			}
			dest += WORD_SIZE;
			src += WORD_SIZE;
		}

		// Copy remaining bytes
		uint mask = 256 ** (WORD_SIZE - len) - 1;
		assembly {
			let srcpart := and(mload(src), not(mask))
			let destpart := and(mload(dest), mask)
			mstore(dest, or(destpart, srcpart))
		}
	}

	// This function does the same as 'dataPtr(bytes memory)', but will also return the
	// length of the provided bytes array.
	function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
		len = bts.length;
		assembly {
			addr := add(bts, /*BYTES_HEADER_SIZE*/32)
		}
	}
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}