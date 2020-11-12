// File: @aragon/os/contracts/lib/token/ERC20.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @aragon/os/contracts/apps/disputable/IAgreement.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract IAgreement {

    event ActionSubmitted(uint256 indexed actionId, address indexed disputable);
    event ActionClosed(uint256 indexed actionId);
    event ActionChallenged(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionSettled(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionDisputed(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionAccepted(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionVoided(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionRejected(uint256 indexed actionId, uint256 indexed challengeId);

    enum ChallengeState {
        Waiting,
        Settled,
        Disputed,
        Rejected,
        Accepted,
        Voided
    }

    function newAction(uint256 _disputableActionId, bytes _context, address _submitter) external returns (uint256);

    function closeAction(uint256 _actionId) external;

    function challengeAction(uint256 _actionId, uint256 _settlementOffer, bool _finishedSubmittingEvidence, bytes _context) external;

    function settleAction(uint256 _actionId) external;

    function disputeAction(uint256 _actionId, bool _finishedSubmittingEvidence) external;
}

// File: @aragon/os/contracts/lib/standards/ERC165.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}

// File: @aragon/os/contracts/apps/disputable/IDisputable.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;





contract IDisputable is ERC165 {
    // Includes setAgreement, onDisputableActionChallenged, onDisputableActionAllowed,
    // onDisputableActionRejected, onDisputableActionVoided, getAgreement, canChallenge, and canClose methods:
    bytes4 internal constant DISPUTABLE_INTERFACE_ID = bytes4(0xf3d3bb51);

    event AgreementSet(IAgreement indexed agreement);

    function setAgreement(IAgreement _agreement) external;

    function onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) external;

    function onDisputableActionAllowed(uint256 _disputableActionId) external;

    function onDisputableActionRejected(uint256 _disputableActionId) external;

    function onDisputableActionVoided(uint256 _disputableActionId) external;

    function getAgreement() external view returns (IAgreement);

    function canChallenge(uint256 _disputableActionId) external view returns (bool);

    function canClose(uint256 _disputableActionId) external view returns (bool);
}

// File: @aragon/os/contracts/acl/IACL.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

// File: @aragon/os/contracts/common/IVaultRecoverable.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

// File: @aragon/os/contracts/kernel/IKernel.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;




interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}


// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 appId, address app) public;
    function getApp(bytes32 namespace, bytes32 appId) public view returns (address);
}

// File: @aragon/os/contracts/apps/IAragonApp.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract IAragonApp {
    // Includes appId and kernel methods:
    bytes4 internal constant ARAGON_APP_INTERFACE_ID = bytes4(0x54053e6c);

    function kernel() public view returns (IKernel);
    function appId() public view returns (bytes32);
}

// File: @aragon/os/contracts/common/UnstructuredStorage.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

// File: @aragon/os/contracts/apps/AppStorage.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;





contract AppStorage is IAragonApp {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION = 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION = 0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

    function kernel() public view returns (IKernel) {
        return IKernel(KERNEL_POSITION.getStorageAddress());
    }

    function appId() public view returns (bytes32) {
        return APP_ID_POSITION.getStorageBytes32();
    }

    function setKernel(IKernel _kernel) internal {
        KERNEL_POSITION.setStorageAddress(address(_kernel));
    }

    function setAppId(bytes32 _appId) internal {
        APP_ID_POSITION.setStorageBytes32(_appId);
    }
}

// File: @aragon/os/contracts/acl/ACLSyntaxSugar.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

// File: @aragon/os/contracts/common/Uint256Helpers.sol

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: @aragon/os/contracts/common/TimeHelpers.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// File: @aragon/os/contracts/common/Initializable.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;




contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

// File: @aragon/os/contracts/common/Petrifiable.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract Petrifiable is Initializable {
    // Use block UINT256_MAX (which should be never) as the initializable date
    uint256 internal constant PETRIFIED_BLOCK = uint256(-1);

    function isPetrified() public view returns (bool) {
        return getInitializationBlock() == PETRIFIED_BLOCK;
    }

    /**
    * @dev Function to be called by top level contract to prevent being initialized.
    *      Useful for freezing base contracts when they're used behind proxies.
    */
    function petrify() internal onlyInit {
        initializedAt(PETRIFIED_BLOCK);
    }
}

// File: @aragon/os/contracts/common/Autopetrified.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}

// File: @aragon/os/contracts/common/ConversionHelpers.sol

pragma solidity ^0.4.24;


library ConversionHelpers {
    string private constant ERROR_IMPROPER_LENGTH = "CONVERSION_IMPROPER_LENGTH";

    function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {
        // Force cast the uint256[] into a bytes array, by overwriting its length
        // Note that the bytes array doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 byteLength = _input.length * 32;
        assembly {
            output := _input
            mstore(output, byteLength)
        }
    }

    function dangerouslyCastBytesToUintArray(bytes memory _input) internal pure returns (uint256[] memory output) {
        // Force cast the bytes array into a uint256[], by overwriting its length
        // Note that the uint256[] doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 intsLength = _input.length / 32;
        require(_input.length == intsLength * 32, ERROR_IMPROPER_LENGTH);

        assembly {
            output := _input
            mstore(output, intsLength)
        }
    }
}

// File: @aragon/os/contracts/common/ReentrancyGuard.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

// File: @aragon/os/contracts/common/EtherTokenConstant.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

// File: @aragon/os/contracts/common/IsContract.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

// File: @aragon/os/contracts/common/SafeERC20.sol

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;



library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }

    /**
    * @dev Static call into ERC20.totalSupply().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticTotalSupply(ERC20 _token) internal view returns (uint256) {
        bytes memory totalSupplyCallData = abi.encodeWithSelector(_token.totalSupply.selector);

        (bool success, uint256 totalSupply) = staticInvoke(_token, totalSupplyCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return totalSupply;
    }
}

// File: @aragon/os/contracts/common/VaultRecoverable.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;







contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

// File: @aragon/os/contracts/evmscript/IEVMScriptExecutor.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

// File: @aragon/os/contracts/evmscript/IEVMScriptRegistry.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    */
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script) public view returns (IEVMScriptExecutor);
}

// File: @aragon/os/contracts/kernel/KernelConstants.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract KernelAppIds {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_APP_ID = apmNamehash("kernel");
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = apmNamehash("acl");
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = apmNamehash("vault");
    */
    bytes32 internal constant KERNEL_CORE_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
}


contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

// File: @aragon/os/contracts/evmscript/EVMScriptRunner.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;







contract EVMScriptRunner is AppStorage, Initializable, EVMScriptRegistryConstants, KernelNamespaceConstants {
    string private constant ERROR_EXECUTOR_UNAVAILABLE = "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED = "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(address indexed executor, bytes script, bytes input, bytes returnData);

    function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getEVMScriptRegistry().getScriptExecutor(_script));
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(bytes _script, bytes _input, address[] _blacklist)
        internal
        isInitialized
        protectState
        returns (bytes)
    {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(sig, _script, _input, _blacklist);

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas,                // forward all gas
                executor,           // address
                add(data, 0x20),    // calldata start
                mload(data),        // calldata length
                0,                  // don't write output (we'll handle this ourselves)
                0                   // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    // Need at least 0x40 bytes returned for properly ABI-encoded bytes values,
                    // revert with "EVMRUN_EXECUTOR_INVALID_RETURN"
                    // See remix: doing a `revert("EVMRUN_EXECUTOR_INVALID_RETURN")` always results in
                    // this memory layout
                    mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                    mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                    mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // reason length
                    mstore(add(output, 0x44), 0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000) // reason

                    revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                }
                default {
                    // Copy result
                    //
                    // Needs to perform an ABI decode for the expected `bytes` return type of
                    // `executor.execScript()` as solidity will automatically ABI encode the returned bytes as:
                    //    [ position of the first dynamic length return value = 0x20 (32 bytes) ]
                    //    [ output length (32 bytes) ]
                    //    [ output content (N bytes) ]
                    //
                    // Perform the ABI decode by ignoring the first 32 bytes of the return data
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize)) // free mem ptr set
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}

// File: @aragon/os/contracts/apps/AragonApp.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;










// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is ERC165, AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
    * @dev Check whether an action can be performed by a sender for a particular role on this app
    * @param _sender Sender of the call
    * @param _role Role on this app
    * @param _params Permission params for the role
    * @return Boolean indicating whether the sender has the permissions to perform the action.
    *         Always returns false if the app hasn't been initialized yet.
    */
    function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return linkedKernel.hasPermission(
            _sender,
            address(this),
            _role,
            ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
        );
    }

    /**
    * @dev Get the recovery vault for the app
    * @return Recovery vault address for the app
    */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == ARAGON_APP_INTERFACE_ID;
    }
}

// File: @aragon/os/contracts/lib/math/SafeMath64.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted for uint64, pragma ^0.4.24, and satisfying our linter rules
// Also optimized the mul() implementation, see https://github.com/aragon/aragonOS/pull/417

pragma solidity ^0.4.24;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/os/contracts/apps/disputable/DisputableAragonApp.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;







contract DisputableAragonApp is IDisputable, AragonApp {
    /* Validation errors */
    string internal constant ERROR_SENDER_NOT_AGREEMENT = "DISPUTABLE_SENDER_NOT_AGREEMENT";
    string internal constant ERROR_AGREEMENT_STATE_INVALID = "DISPUTABLE_AGREEMENT_STATE_INVAL";

    // This role is used to protect who can challenge actions in derived Disputable apps. However, it is not required
    // to be validated in the app itself as the connected Agreement is responsible for performing the check on a challenge.
    // bytes32 public constant CHALLENGE_ROLE = keccak256("CHALLENGE_ROLE");
    bytes32 public constant CHALLENGE_ROLE = 0xef025787d7cd1a96d9014b8dc7b44899b8c1350859fb9e1e05f5a546dd65158d;

    // bytes32 public constant SET_AGREEMENT_ROLE = keccak256("SET_AGREEMENT_ROLE");
    bytes32 public constant SET_AGREEMENT_ROLE = 0x8dad640ab1b088990c972676ada708447affc660890ec9fc9a5483241c49f036;

    // bytes32 internal constant AGREEMENT_POSITION = keccak256("aragonOS.appStorage.agreement");
    bytes32 internal constant AGREEMENT_POSITION = 0x6dbe80ccdeafbf5f3fff5738b224414f85e9370da36f61bf21c65159df7409e9;

    modifier onlyAgreement() {
        require(address(_getAgreement()) == msg.sender, ERROR_SENDER_NOT_AGREEMENT);
        _;
    }

    /**
    * @notice Challenge disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be challenged
    * @param _challengeId Identifier of the challenge in the context of the Agreement
    * @param _challenger Address that submitted the challenge
    */
    function onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) external onlyAgreement {
        _onDisputableActionChallenged(_disputableActionId, _challengeId, _challenger);
    }

    /**
    * @notice Allow disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be allowed
    */
    function onDisputableActionAllowed(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionAllowed(_disputableActionId);
    }

    /**
    * @notice Reject disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be rejected
    */
    function onDisputableActionRejected(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionRejected(_disputableActionId);
    }

    /**
    * @notice Void disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be voided
    */
    function onDisputableActionVoided(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionVoided(_disputableActionId);
    }

    /**
    * @notice Set Agreement to `_agreement`
    * @param _agreement Agreement instance to be set
    */
    function setAgreement(IAgreement _agreement) external auth(SET_AGREEMENT_ROLE) {
        IAgreement agreement = _getAgreement();
        require(agreement == IAgreement(0) && _agreement != IAgreement(0), ERROR_AGREEMENT_STATE_INVALID);

        AGREEMENT_POSITION.setStorageAddress(address(_agreement));
        emit AgreementSet(_agreement);
    }

    /**
    * @dev Tell the linked Agreement
    * @return Agreement
    */
    function getAgreement() external view returns (IAgreement) {
        return _getAgreement();
    }

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == DISPUTABLE_INTERFACE_ID;
    }

    /**
    * @dev Internal implementation of the `onDisputableActionChallenged` hook
    * @param _disputableActionId Identifier of the action to be challenged
    * @param _challengeId Identifier of the challenge in the context of the Agreement
    * @param _challenger Address that submitted the challenge
    */
    function _onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionRejected` hook
    * @param _disputableActionId Identifier of the action to be rejected
    */
    function _onDisputableActionRejected(uint256 _disputableActionId) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionAllowed` hook
    * @param _disputableActionId Identifier of the action to be allowed
    */
    function _onDisputableActionAllowed(uint256 _disputableActionId) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionVoided` hook
    * @param _disputableActionId Identifier of the action to be voided
    */
    function _onDisputableActionVoided(uint256 _disputableActionId) internal;

    /**
    * @dev Register a new disputable action in the Agreement
    * @param _disputableActionId Identifier of the action in the context of the Disputable
    * @param _context Link to human-readable context for the given action
    * @param _submitter Address that submitted the action
    * @return Unique identifier for the created action in the context of the Agreement
    */
    function _registerDisputableAction(uint256 _disputableActionId, bytes _context, address _submitter) internal returns (uint256) {
        IAgreement agreement = _ensureAgreement();
        return agreement.newAction(_disputableActionId, _context, _submitter);
    }

    /**
    * @dev Close disputable action in the Agreement
    * @param _actionId Identifier of the action in the context of the Agreement
    */
    function _closeDisputableAction(uint256 _actionId) internal {
        IAgreement agreement = _ensureAgreement();
        agreement.closeAction(_actionId);
    }

    /**
    * @dev Tell the linked Agreement
    * @return Agreement
    */
    function _getAgreement() internal view returns (IAgreement) {
        return IAgreement(AGREEMENT_POSITION.getStorageAddress());
    }

    /**
    * @dev Tell the linked Agreement or revert if it has not been set
    * @return Agreement
    */
    function _ensureAgreement() internal view returns (IAgreement) {
        IAgreement agreement = _getAgreement();
        require(agreement != IAgreement(0), ERROR_AGREEMENT_STATE_INVALID);
        return agreement;
    }
}

// File: @aragon/os/contracts/forwarding/IAbstractForwarder.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


/**
* @title Abstract forwarder interface
* @dev This is the base interface for all forwarders.
*      Forwarding allows separately installed applications (smart contracts implementing the forwarding interface) to execute multi-step actions via EVM scripts.
*      You should only support the forwarding interface if your "action step" is asynchronous (e.g. requiring a delay period or a voting period).
*      Note: you should **NOT** directly inherit from this interface; see one of the other, non-abstract interfaces available.
*/
contract IAbstractForwarder {
    enum ForwarderType {
        NOT_IMPLEMENTED,
        NO_CONTEXT,
        WITH_CONTEXT
    }

    /**
    * @dev Tell whether the proposed forwarding path (an EVM script) from the given sender is allowed.
    *      However, this is not a strict guarantee of safety: the implemented `forward()` method is
    *      still allowed to revert even if `canForward()` returns true for the same parameters.
    * @return True if the sender's proposed path is allowed
    */
    function canForward(address sender, bytes evmScript) external view returns (bool);

    /**
    * @dev Tell the forwarder type
    * @return Forwarder type
    */
    function forwarderType() external pure returns (ForwarderType);

    /**
    * @dev Report whether the implementing app is a forwarder
    *      Required for backwards compatibility with aragonOS 4
    * @return Always true
    */
    function isForwarder() external pure returns (bool) {
        return true;
    }
}

// File: @aragon/os/contracts/forwarding/IForwarderWithContext.sol

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;



/**
* @title Forwarder interface requiring context information
* @dev This forwarder interface allows for additional context to be attached to the action by the sender.
*/
contract IForwarderWithContext is IAbstractForwarder {
    /**
    * @dev Forward an EVM script with an attached context
    */
    function forward(bytes evmScript, bytes context) external;

    /**
    * @dev Tell the forwarder type
    * @return Always 2 (ForwarderType.WITH_CONTEXT)
    */
    function forwarderType() external pure returns (ForwarderType) {
        return ForwarderType.WITH_CONTEXT;
    }
}

// File: @aragon/os/contracts/lib/math/SafeMath.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/minime/contracts/ITokenController.sol

pragma solidity ^0.4.24;

/// @dev The token controller contract must implement these functions


interface ITokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) external payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) external returns(bool);
}

// File: @aragon/minime/contracts/MiniMeToken.sol

pragma solidity ^0.4.24;

/*
    Copyright 2016, Jordi Baylina
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MiniMeToken Contract
/// @author Jordi Baylina
/// @dev This token contract's goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO's
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.


contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    address public controller;

    function Controlled()  public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController  public {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data
    ) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "MMT_0.1"; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeToken(
        MiniMeTokenFactory _tokenFactory,
        MiniMeToken _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount)
                return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != 0) && (_to != address(this)));
        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            // Adding the ` == true` makes the linter shut up so...
            require(ITokenController(controller).onTransfer(_from, _to, _amount) == true);
        }
        // First update the balance array with the new value for the address
        //  sending the tokens
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
        // Then update the balance array with the new value for the address
        //  receiving the tokens
        var previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
        // An event to make the transfer easy to find on the blockchain
        Transfer(_from, _to, _amount);
        return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            // Adding the ` == true` makes the linter shut up so...
            require(ITokenController(controller).onApprove(msg.sender, _spender, _amount) == true);
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        _spender.receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) public returns(MiniMeToken)
    {
        uint256 snapshot = _snapshotBlock == 0 ? block.number - 1 : _snapshotBlock;

        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            snapshot,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
        );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), snapshot);
        return cloneToken;
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        require(_value <= uint128(-1));

        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0)
            return false;

        assembly {
            size := extcodesize(_addr)
        }

        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () external payable {
        require(isContract(controller));
        // Adding the ` == true` makes the linter shut up so...
        require(ITokenController(controller).proxyPayment.value(msg.value)(msg.sender) == true);
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController public {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


////////////////
// MiniMeTokenFactory
////////////////

/// @dev This contract is used to generate clone contracts from a contract.
///  In solidity this is the way to create a contract from a contract of the
///  same class
contract MiniMeTokenFactory {
    event NewFactoryCloneToken(address indexed _cloneToken, address indexed _parentToken, uint _snapshotBlock);

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createCloneToken(
        MiniMeToken _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken)
    {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
        );

        newToken.changeController(msg.sender);
        NewFactoryCloneToken(address(newToken), address(_parentToken), _snapshotBlock);
        return newToken;
    }
}

// File: contracts/DisputableVoting.sol

/*
 * SPDX-License-Identifier:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;







contract DisputableVoting is IForwarderWithContext, DisputableAragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    // bytes32 public constant CREATE_VOTES_ROLE = keccak256("CREATE_VOTES_ROLE");
    bytes32 public constant CREATE_VOTES_ROLE = 0xe7dcd7275292e064d090fbc5f3bd7995be23b502c1fed5cd94cfddbbdcd32bbc;

    // bytes32 public constant CHANGE_VOTE_TIME_ROLE = keccak256("CHANGE_VOTE_TIME_ROLE");
    bytes32 public constant CHANGE_VOTE_TIME_ROLE = 0xbc5d8ebc0830a2fed8649987b8263de1397b7fa892f3b87dc2d8cad35c691f86;

    // bytes32 public constant CHANGE_SUPPORT_ROLE = keccak256("CHANGE_SUPPORT_ROLE");
    bytes32 public constant CHANGE_SUPPORT_ROLE = 0xf3a5f71f3cb50dae9454dd13cdf0fd1b559f7e20d63c08902592486e6d460c90;

    // bytes32 public constant CHANGE_QUORUM_ROLE = keccak256("CHANGE_QUORUM_ROLE");
    bytes32 public constant CHANGE_QUORUM_ROLE = 0xa3f675280fb3c54662067f92659ca1ee3ef7c1a7f2a6ff03a5c4228aa26b6a82;

    // bytes32 public constant CHANGE_DELEGATED_VOTING_PERIOD_ROLE = keccak256("CHANGE_DELEGATED_VOTING_PERIOD_ROLE");
    bytes32 public constant CHANGE_DELEGATED_VOTING_PERIOD_ROLE = 0x59ba415d96e104e6483d76b79d9cd09941d04e229adcd62d7dc672c93975a19d;

    // bytes32 public constant CHANGE_EXECUTION_DELAY_ROLE = keccak256("CHANGE_EXECUTION_DELAY_ROLE");
    bytes32 public constant CHANGE_EXECUTION_DELAY_ROLE = 0x5e3a3edc315e366a0cc5c94ca94a8f9bbc2f1feebb2ef7704bfefcff0cdc4ee7;

    // bytes32 public constant CHANGE_QUIET_ENDING_ROLE = keccak256("CHANGE_QUIET_ENDING_ROLE");
    bytes32 public constant CHANGE_QUIET_ENDING_ROLE = 0x4f885d966bcd49734218a6e280d58c840b86e8cc13610b21ebd46f0b1da362c2;

    uint256 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10^16; 100% = 10^18
    uint256 public constant MAX_VOTES_DELEGATION_SET_LENGTH = 70;

    // Validation errors
    string private constant ERROR_NO_VOTE = "VOTING_NO_VOTE";
    string private constant ERROR_VOTE_TIME_ZERO = "VOTING_VOTE_TIME_ZERO";
    string private constant ERROR_TOKEN_NOT_CONTRACT = "VOTING_TOKEN_NOT_CONTRACT";
    string private constant ERROR_SETTING_DOES_NOT_EXIST = "VOTING_SETTING_DOES_NOT_EXIST";
    string private constant ERROR_CHANGE_QUORUM_TOO_BIG = "VOTING_CHANGE_QUORUM_TOO_BIG";
    string private constant ERROR_CHANGE_SUPPORT_TOO_SMALL = "VOTING_CHANGE_SUPPORT_TOO_SMALL";
    string private constant ERROR_CHANGE_SUPPORT_TOO_BIG = "VOTING_CHANGE_SUPPORT_TOO_BIG";
    string private constant ERROR_INVALID_DELEGATED_VOTING_PERIOD = "VOTING_INVALID_DLGT_VOTE_PERIOD";
    string private constant ERROR_INVALID_QUIET_ENDING_PERIOD = "VOTING_INVALID_QUIET_END_PERIOD";
    string private constant ERROR_INVALID_EXECUTION_SCRIPT = "VOTING_INVALID_EXECUTION_SCRIPT";

    // Workflow errors
    string private constant ERROR_CANNOT_FORWARD = "VOTING_CANNOT_FORWARD";
    string private constant ERROR_NO_TOTAL_VOTING_POWER = "VOTING_NO_TOTAL_VOTING_POWER";
    string private constant ERROR_CANNOT_VOTE = "VOTING_CANNOT_VOTE";
    string private constant ERROR_NOT_REPRESENTATIVE = "VOTING_NOT_REPRESENTATIVE";
    string private constant ERROR_PAST_REPRESENTATIVE_VOTING_WINDOW = "VOTING_PAST_REP_VOTING_WINDOW";
    string private constant ERROR_DELEGATES_EXCEEDS_MAX_LEN = "VOTING_DELEGATES_EXCEEDS_MAX_LEN";
    string private constant ERROR_CANNOT_PAUSE_VOTE = "VOTING_CANNOT_PAUSE_VOTE";
    string private constant ERROR_VOTE_NOT_PAUSED = "VOTING_VOTE_NOT_PAUSED";
    string private constant ERROR_CANNOT_EXECUTE = "VOTING_CANNOT_EXECUTE";

    enum VoterState { Absent, Yea, Nay }

    enum VoteStatus {
        Normal,                         // A vote in a "normal" state of operation (not one of the below)--note that this state is not related to the vote being open
        Paused,                         // A vote that is paused due to it having an open challenge or dispute
        Cancelled,                      // A vote that has been explicitly cancelled due to a challenge or dispute
        Executed                        // A vote that has been executed
    }

    struct Setting {
        // "Base" duration of each vote -- vote lifespans may be adjusted by pause and extension durations
        uint64 voteTime;

        // Required voter support % (yes power / voted power) for a vote to pass
        // Expressed as a percentage of 10^18; eg. 10^16 = 1%, 10^18 = 100%
        uint64 supportRequiredPct;

        // Required voter quorum % (yes power / total power) for a vote to pass
        // Expressed as a percentage of 10^18; eg. 10^16 = 1%, 10^18 = 100%
        // Must be <= supportRequiredPct to avoid votes being impossible to pass
        uint64 minAcceptQuorumPct;

        // Duration from the start of a vote that representatives are allowed to vote on behalf of principals
        // Must be <= voteTime; duration is bound as [)
        uint64 delegatedVotingPeriod;

        // Duration before the end of a vote to detect non-quiet endings
        // Must be <= voteTime; duration is bound as [)
        uint64 quietEndingPeriod;

        // Duration to extend a vote in case of non-quiet ending
        uint64 quietEndingExtension;

        // Duration to wait before a passed vote can be executed
        // Duration is bound as [)
        uint64 executionDelay;
    }

    struct VoteCast {
        VoterState state;
        address caster;                                     // Caster of the vote (only stored if caster was not the representative)
    }

    struct Vote {
        uint256 yea;                                        // Voting power for
        uint256 nay;                                        // Voting power against
        uint256 totalPower;                                 // Total voting power (based on the snapshot block)

        uint64 startDate;                                   // Datetime when the vote was created
        uint64 snapshotBlock;                               // Block number used to check voting power on attached token
        VoteStatus status;                                  // Status of the vote

        uint256 settingId;                                  // Identification number of the setting applicable to the vote
        uint256 actionId;                                   // Identification number of the associated disputable action on the attached Agreement

        uint64 pausedAt;                                    // Datetime when the vote was paused
        uint64 pauseDuration;                               // Duration of the pause (only updated once resumed)
        uint64 quietEndingExtensionDuration;                // Duration a vote was extended due to non-quiet endings
        VoterState quietEndingSnapshotSupport;              // Snapshot of the vote's support at the beginning of the first quiet ending period

        bytes32 executionScriptHash;                        // Hash of the EVM script attached to the vote
        mapping (address => VoteCast) castVotes;            // Mapping of voter address => more information about their cast vote
    }

    MiniMeToken public token;                               // Token for determining voting power; we assume it's not malicious

    uint256 public settingsLength;                          // Number of settings created
    mapping (uint256 => Setting) internal settings;         // List of settings indexed by ID (starting at 0)

    uint256 public votesLength;                             // Number of votes created
    mapping (uint256 => Vote) internal votes;               // List of votes indexed by ID (starting at 0)
    mapping (address => address) internal representatives;  // Mapping of voter => allowed representative

    event NewSetting(uint256 settingId);
    event ChangeVoteTime(uint64 voteTime);
    event ChangeSupportRequired(uint64 supportRequiredPct);
    event ChangeMinQuorum(uint64 minAcceptQuorumPct);
    event ChangeDelegatedVotingPeriod(uint64 delegatedVotingPeriod);
    event ChangeQuietEndingConfiguration(uint64 quietEndingPeriod, uint64 quietEndingExtension);
    event ChangeExecutionDelay(uint64 executionDelay);

    event StartVote(uint256 indexed voteId, address indexed creator, bytes context, bytes executionScript);
    event PauseVote(uint256 indexed voteId, uint256 indexed challengeId);
    event ResumeVote(uint256 indexed voteId);
    event CancelVote(uint256 indexed voteId);
    event ExecuteVote(uint256 indexed voteId);
    event QuietEndingExtendVote(uint256 indexed voteId, bool passing);

    event CastVote(uint256 indexed voteId, address indexed voter, bool supports, address caster);
    event ChangeRepresentative(address indexed voter, address indexed representative);
    event ProxyVoteFailure(uint256 indexed voteId, address indexed voter, address indexed representative);

    /**
    * @notice Initialize Disputable Voting with `_token.symbol(): string` for governance, a voting duration of `@transformTime(_voteTime)`, minimum support of `@formatPct(_supportRequiredPct)`%, minimum acceptance quorum of `@formatPct(_minAcceptQuorumPct)`%, a delegated voting period of `@transformTime(_delegatedVotingPeriod), and a execution delay of `@transformTime(_executionDelay)`
    * @param _token MiniMeToken Address that will be used as governance token
    * @param _voteTime Base duration a vote will be open for voting
    * @param _supportRequiredPct Required support % (yes power / voted power) for a vote to pass; expressed as a percentage of 10^18
    * @param _minAcceptQuorumPct Required quorum % (yes power / total power) for a vote to pass; expressed as a percentage of 10^18
    * @param _delegatedVotingPeriod Duration from the start of a vote that representatives are allowed to vote on behalf of principals
    * @param _quietEndingPeriod Duration to detect non-quiet endings
    * @param _quietEndingExtension Duration to extend a vote in case of non-quiet ending
    * @param _executionDelay Duration to wait before a passed vote can be executed
    */
    function initialize(
        MiniMeToken _token,
        uint64 _voteTime,
        uint64 _supportRequiredPct,
        uint64 _minAcceptQuorumPct,
        uint64 _delegatedVotingPeriod,
        uint64 _quietEndingPeriod,
        uint64 _quietEndingExtension,
        uint64 _executionDelay
    )
        external
    {
        initialized();

        require(isContract(_token), ERROR_TOKEN_NOT_CONTRACT);
        token = _token;

        (Setting storage setting, ) = _newSetting();
        _changeVoteTime(setting, _voteTime);
        _changeSupportRequiredPct(setting, _supportRequiredPct);
        _changeMinAcceptQuorumPct(setting, _minAcceptQuorumPct);
        _changeDelegatedVotingPeriod(setting, _delegatedVotingPeriod);
        _changeQuietEndingConfiguration(setting, _quietEndingPeriod, _quietEndingExtension);
        _changeExecutionDelay(setting, _executionDelay);
    }

    /**
    * @notice Change vote time to `@transformTime(_voteTime)`
    * @param _voteTime New vote time
    */
    function changeVoteTime(uint64 _voteTime) external authP(CHANGE_VOTE_TIME_ROLE, arr(uint256(_voteTime))) {
        Setting storage setting = _newCopiedSettings();
        _changeVoteTime(setting, _voteTime);
    }

    /**
    * @notice Change required support to `@formatPct(_supportRequiredPct)`%
    * @param _supportRequiredPct New required support; expressed as a percentage of 10^18
    */
    function changeSupportRequiredPct(uint64 _supportRequiredPct) external authP(CHANGE_SUPPORT_ROLE, arr(uint256(_supportRequiredPct))) {
        Setting storage setting = _newCopiedSettings();
        _changeSupportRequiredPct(setting, _supportRequiredPct);
    }

    /**
    * @notice Change minimum acceptance quorum to `@formatPct(_minAcceptQuorumPct)`%
    * @param _minAcceptQuorumPct New minimum acceptance quorum; expressed as a percentage of 10^18
    */
    function changeMinAcceptQuorumPct(uint64 _minAcceptQuorumPct) external authP(CHANGE_QUORUM_ROLE, arr(uint256(_minAcceptQuorumPct))) {
        Setting storage setting = _newCopiedSettings();
        _changeMinAcceptQuorumPct(setting, _minAcceptQuorumPct);
    }

    /**
    * @notice Change delegated voting period to `@transformTime(_delegatedVotingPeriod)`
    * @param _delegatedVotingPeriod New delegated voting period
    */
    function changeDelegatedVotingPeriod(uint64 _delegatedVotingPeriod) external authP(CHANGE_DELEGATED_VOTING_PERIOD_ROLE, arr(uint256(_delegatedVotingPeriod))) {
        Setting storage setting = _newCopiedSettings();
        _changeDelegatedVotingPeriod(setting, _delegatedVotingPeriod);
    }

    /**
    * @notice Change quiet ending period to `@transformTime(_quietEndingPeriod)` with extensions of `@transformTime(_quietEndingExtension)`
    * @param _quietEndingPeriod New quiet ending period
    * @param _quietEndingExtension New quiet ending extension
    */
    function changeQuietEndingConfiguration(uint64 _quietEndingPeriod, uint64 _quietEndingExtension)
        external
        authP(CHANGE_QUIET_ENDING_ROLE, arr(uint256(_quietEndingPeriod), uint256(_quietEndingExtension)))
    {
        Setting storage setting = _newCopiedSettings();
        _changeQuietEndingConfiguration(setting, _quietEndingPeriod, _quietEndingExtension);
    }

    /**
    * @notice Change execution delay to `@transformTime(_executionDelay)`
    * @param _executionDelay New execution delay
    */
    function changeExecutionDelay(uint64 _executionDelay) external authP(CHANGE_EXECUTION_DELAY_ROLE, arr(uint256(_executionDelay))) {
        Setting storage setting = _newCopiedSettings();
        _changeExecutionDelay(setting, _executionDelay);
    }

    /**
    * @notice Create a new vote about "`_context`"
    * @param _executionScript Action (encoded as an EVM script) that will be allowed to execute if the vote passes
    * @param _context Additional context for the vote, also used as the disputable action's context on the attached Agreement
    * @return Identification number of the newly created vote
    */
    function newVote(bytes _executionScript, bytes _context) external auth(CREATE_VOTES_ROLE) returns (uint256) {
        return _newVote(_executionScript, _context);
    }

    /**
    * @notice Vote `_supports ? 'yes' : 'no'` in vote #`_voteId`
    * @dev Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote
    * @param _supports Whether voter supports the vote
    */
    function vote(uint256 _voteId, bool _supports) external {
        Vote storage vote_ = _getVote(_voteId);
        require(_canVote(vote_, msg.sender), ERROR_CANNOT_VOTE);

        _castVote(vote_, _voteId, _supports, msg.sender, address(0));
    }

    /**
    * @notice Vote `_supports ? 'yes' : 'no'` in vote #`_voteId` on behalf of delegated voters
    * @dev Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote
    * @param _supports Whether the representative supports the vote
    * @param _voters Addresses of the delegated voters to vote on behalf of
    */
    function voteOnBehalfOf(uint256 _voteId, bool _supports, address[] _voters) external {
        require(_voters.length <= MAX_VOTES_DELEGATION_SET_LENGTH, ERROR_DELEGATES_EXCEEDS_MAX_LEN);

        Vote storage vote_ = _getVote(_voteId);
        // Note that the period for representatives to vote can never go into a quiet ending
        // extension, and so we don't need to check other timing-based pre-conditions
        require(_canRepresentativesVote(vote_), ERROR_PAST_REPRESENTATIVE_VOTING_WINDOW);

        for (uint256 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            require(_hasVotingPower(vote_, voter), ERROR_CANNOT_VOTE);
            require(_isRepresentativeOf(voter, msg.sender), ERROR_NOT_REPRESENTATIVE);

            if (!_hasCastVote(vote_, voter)) {
                _castVote(vote_, _voteId, _supports, voter, msg.sender);
            } else {
                emit ProxyVoteFailure(_voteId, voter, msg.sender);
            }
        }
    }

    /**
    * @notice Execute vote #`_voteId`
    * @dev Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote
    * @param _executionScript Action (encoded as an EVM script) to be executed, must match the one used when the vote was created
    */
    function executeVote(uint256 _voteId, bytes _executionScript) external {
        Vote storage vote_ = _getVote(_voteId);
        require(_canExecute(vote_), ERROR_CANNOT_EXECUTE);
        require(vote_.executionScriptHash == keccak256(_executionScript), ERROR_INVALID_EXECUTION_SCRIPT);

        vote_.status = VoteStatus.Executed;
        _closeDisputableAction(vote_.actionId);

        // Add attached Agreement to blacklist to disallow the stored EVMScript from directly calling
        // the Agreement from this app's context (e.g. maliciously closing a different action)
        address[] memory blacklist = new address[](1);
        blacklist[0] = address(_getAgreement());
        runScript(_executionScript, new bytes(0), blacklist);
        emit ExecuteVote(_voteId);
    }

    /**
    * @notice `_representative == 0x0 ? 'Set your voting representative to ' + _representative : 'Remove your representative'`
    * @param _representative Address of the representative who is allowed to vote on behalf of the sender. Use the zero address for none.
    */
    function setRepresentative(address _representative) external isInitialized {
        representatives[msg.sender] = _representative;
        emit ChangeRepresentative(msg.sender, _representative);
    }

    // Forwarding external fns

    /**
    * @notice Create a vote to execute the desired action
    * @dev IForwarderWithContext interface conformance.
    *      This app (as a DisputableAragonApp) is required to be the initial step in the forwarding chain.
    * @param _evmScript Action (encoded as an EVM script) that will be allowed to execute if the vote passes
    * @param _context Additional context for the vote, also used as the disputable action's context on the attached Agreement
    */
    function forward(bytes _evmScript, bytes _context) external {
        require(_canForward(msg.sender, _evmScript), ERROR_CANNOT_FORWARD);
        _newVote(_evmScript, _context);
    }

    // Forwarding getter fns

    /**
    * @dev Tell if an address can forward actions (by creating a vote)
    *      IForwarderWithContext interface conformance
    * @param _sender Address intending to forward an action
    * @param _evmScript EVM script being forwarded
    * @return True if the address is allowed create a vote containing the action
    */
    function canForward(address _sender, bytes _evmScript) external view returns (bool) {
        return _canForward(_sender, _evmScript);
    }

    // Disputable getter fns

    /**
    * @dev Tell if a vote can be challenged
    *      Called by the attached Agreement when a challenge is requested for the associated vote
    * @param _voteId Identification number of the vote being queried
    * @return True if the vote can be challenged
    */
    function canChallenge(uint256 _voteId) external view returns (bool) {
        Vote storage vote_ = _getVote(_voteId);
        // Votes can only be challenged once
        return vote_.pausedAt == 0 && _isVoteOpenForVoting(vote_, settings[vote_.settingId]);
    }

    /**
    * @dev Tell if a vote can be closed
    *      Called by the attached Agreement when the action associated with the vote is requested to be manually closed
    * @param _voteId Identification number of the vote being queried
    * @return True if the vote can be closed
    */
    function canClose(uint256 _voteId) external view returns (bool) {
        Vote storage vote_ = _getVote(_voteId);
        return (_isNormal(vote_) || _isExecuted(vote_)) && _hasEnded(vote_, settings[vote_.settingId]);
    }

    // Getter fns

    /**
    * @dev Tell the information for a setting
    *      Initialization check is implicitly provided by `_getSetting()` as new settings can only be
    *      created via `change*()` functions which require initialization
    * @param _settingId Identification number of the setting
    * @return voteTime Base vote duration
    * @return supportRequiredPct Required support % (yes power / voted power) for a vote to pass; expressed as a percentage of 10^18
    * @return minAcceptQuorumPct Required quorum % (yes power / total power) for a vote to pass; expressed as a percentage of 10^18
    * @return delegatedVotingPeriod Duration of the delegated voting period
    * @return quietEndingPeriod Duration to detect non-quiet endings
    * @return quietEndingExtension Duration to extend a vote in case of non-quiet ending
    * @return executionDelay Duration to wait before a passed vote can be executed
    */
    function getSetting(uint256 _settingId)
        external
        view
        returns (
            uint64 voteTime,
            uint64 supportRequiredPct,
            uint64 minAcceptQuorumPct,
            uint64 delegatedVotingPeriod,
            uint64 quietEndingPeriod,
            uint64 quietEndingExtension,
            uint64 executionDelay
        )
    {
        Setting storage setting = _getSetting(_settingId);
        voteTime = setting.voteTime;
        supportRequiredPct = setting.supportRequiredPct;
        minAcceptQuorumPct = setting.minAcceptQuorumPct;
        delegatedVotingPeriod = setting.delegatedVotingPeriod;
        quietEndingPeriod = setting.quietEndingPeriod;
        quietEndingExtension = setting.quietEndingExtension;
        executionDelay = setting.executionDelay;
    }

    /**
    * @dev Tell the information for a vote
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote
    * @return yea Voting power for
    * @return nay Voting power against
    * @return totalPower Total voting power available (based on the snapshot block)
    * @return startDate Datetime when the vote was created
    * @return snapshotBlock Block number used to check voting power on attached token
    * @return status Status of the vote
    * @return settingId Identification number of the setting applicable to the vote
    * @return actionId Identification number of the associated disputable action on the attached Agreement
    * @return pausedAt Datetime when the vote was paused
    * @return pauseDuration Duration of the pause (only updated once resumed)
    * @return quietEndingExtensionDuration Duration a vote was extended due to non-quiet endings
    * @return quietEndingSnapshotSupport Snapshot of the vote's support at the beginning of the first quiet ending period
    * @return executionScriptHash Hash of the EVM script attached to the vote
    */
    function getVote(uint256 _voteId)
        external
        view
        returns (
            uint256 yea,
            uint256 nay,
            uint256 totalPower,
            uint64 startDate,
            uint64 snapshotBlock,
            VoteStatus status,
            uint256 settingId,
            uint256 actionId,
            uint64 pausedAt,
            uint64 pauseDuration,
            uint64 quietEndingExtensionDuration,
            VoterState quietEndingSnapshotSupport,
            bytes32 executionScriptHash
        )
    {
        Vote storage vote_ = _getVote(_voteId);

        yea = vote_.yea;
        nay = vote_.nay;
        totalPower = vote_.totalPower;
        startDate = vote_.startDate;
        snapshotBlock = vote_.snapshotBlock;
        status = vote_.status;
        settingId = vote_.settingId;
        actionId = vote_.actionId;
        pausedAt = vote_.pausedAt;
        pauseDuration = vote_.pauseDuration;
        quietEndingExtensionDuration = vote_.quietEndingExtensionDuration;
        quietEndingSnapshotSupport = vote_.quietEndingSnapshotSupport;
        executionScriptHash = vote_.executionScriptHash;
    }

    /**
    * @dev Tell the state of a voter for a vote
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote
    * @param _voter Address of the voter being queried
    * @return state Voter's cast state being queried
    * @return caster Address of the vote's caster
    */
    function getCastVote(uint256 _voteId, address _voter) external view returns (VoterState state, address caster) {
        Vote storage vote_ = _getVote(_voteId);
        state = _voterState(vote_, _voter);
        caster = _voteCaster(vote_, _voter);
    }

    /**
    * @dev Tell if a voter can participate in a vote
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote being queried
    * @param _voter Address of the voter being queried
    * @return True if the voter can participate in the vote
    */
    function canVote(uint256 _voteId, address _voter) external view returns (bool) {
        return _canVote(_getVote(_voteId), _voter);
    }

    /**
    * @dev Tell if a representative can vote on behalf of delegated voters in a vote
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote being queried
    * @param _voters Addresses of the delegated voters being queried
    * @param _representative Address of the representative being queried
    * @return True if the representative can vote on behalf of the delegated voters in the vote
    */
    function canVoteOnBehalfOf(uint256 _voteId, address[] _voters, address _representative) external view returns (bool) {
        require(_voters.length <= MAX_VOTES_DELEGATION_SET_LENGTH, ERROR_DELEGATES_EXCEEDS_MAX_LEN);

        Vote storage vote_ = _getVote(_voteId);
        if (!_canRepresentativesVote(vote_)) {
            return false;
        }

        for (uint256 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            if (!_hasVotingPower(vote_, voter) || !_isRepresentativeOf(voter, _representative) || _hasCastVote(vote_, voter)) {
                return false;
            }
        }

        return true;
    }

    /**
    * @dev Tell if a vote can be executed
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote being queried
    * @return True if the vote can be executed
    */
    function canExecute(uint256 _voteId) external view returns (bool) {
        return _canExecute(_getVote(_voteId));
    }

    /**
    * @dev Tell if a vote is open for voting
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Identification number of the vote being queried
    * @return True if the vote is open for voting
    */
    function isVoteOpenForVoting(uint256 _voteId) external view returns (bool) {
        Vote storage vote_ = _getVote(_voteId);
        Setting storage setting = settings[vote_.settingId];
        return _isVoteOpenForVoting(vote_, setting);
    }

    /**
    * @dev Tell if a vote currently allows representatives to vote for delegated voters
    *      Initialization check is implicitly provided by `_getVote()` as new votes can only be
    *      created via `newVote()`, which requires initialization
    * @param _voteId Vote identifier
    * @return True if the vote currently allows representatives to vote
    */
    function canRepresentativesVote(uint256 _voteId) external view returns (bool) {
        Vote storage vote_ = _getVote(_voteId);
        return _canRepresentativesVote(vote_);
    }

    /**
    * @dev Tell if a representative currently represents another voter
    * @param _voter Address of the delegated voter being queried
    * @param _representative Address of the representative being queried
    * @return True if the representative currently represents the voter
    */
    function isRepresentativeOf(address _voter, address _representative) external view isInitialized returns (bool) {
        return _isRepresentativeOf(_voter, _representative);
    }

    // DisputableAragonApp callback implementations

    /**
    * @dev Received when a vote is challenged
    * @param _voteId Identification number of the vote
    * @param _challengeId Identification number of the challenge associated to the vote on the attached Agreement
    */
    function _onDisputableActionChallenged(uint256 _voteId, uint256 _challengeId, address /* _challenger */) internal {
        Vote storage vote_ = _getVote(_voteId);
        require(_isNormal(vote_), ERROR_CANNOT_PAUSE_VOTE);

        vote_.status = VoteStatus.Paused;
        vote_.pausedAt = getTimestamp64();
        emit PauseVote(_voteId, _challengeId);
    }

    /**
    * @dev Received when a vote was ruled in favour of the submitter
    * @param _voteId Identification number of the vote
    */
    function _onDisputableActionAllowed(uint256 _voteId) internal {
        Vote storage vote_ = _getVote(_voteId);
        require(_isPaused(vote_), ERROR_VOTE_NOT_PAUSED);

        vote_.status = VoteStatus.Normal;
        vote_.pauseDuration = getTimestamp64().sub(vote_.pausedAt);
        emit ResumeVote(_voteId);
    }

    /**
    * @dev Received when a vote was ruled in favour of the challenger
    * @param _voteId Identification number of the vote
    */
    function _onDisputableActionRejected(uint256 _voteId) internal {
        Vote storage vote_ = _getVote(_voteId);
        require(_isPaused(vote_), ERROR_VOTE_NOT_PAUSED);

        vote_.status = VoteStatus.Cancelled;
        vote_.pauseDuration = getTimestamp64().sub(vote_.pausedAt);
        emit CancelVote(_voteId);
    }

    /**
    * @dev Received when a vote was ruled as void
    * @param _voteId Identification number of the vote
    */
    function _onDisputableActionVoided(uint256 _voteId) internal {
        // When a challenged vote is ruled as voided, it is considered as being allowed.
        // This could be the case for challenges where the attached Agreement's arbitrator refuses to rule the case.
        _onDisputableActionAllowed(_voteId);
    }

    // Internal fns

    /**
    * @dev Create a new empty setting instance
    * @return New setting's instance
    * @return New setting's identification number
    */
    function _newSetting() internal returns (Setting storage setting, uint256 settingId) {
        settingId = settingsLength++;
        setting = settings[settingId];
        emit NewSetting(settingId);
    }

    /**
    * @dev Create a copy of the current settings as a new setting instance
    * @return New setting's instance
    */
    function _newCopiedSettings() internal returns (Setting storage) {
        (Setting storage to, uint256 settingId) = _newSetting();
        Setting storage from = _getSetting(settingId - 1);
        to.voteTime = from.voteTime;
        to.supportRequiredPct = from.supportRequiredPct;
        to.minAcceptQuorumPct = from.minAcceptQuorumPct;
        to.delegatedVotingPeriod = from.delegatedVotingPeriod;
        to.quietEndingPeriod = from.quietEndingPeriod;
        to.quietEndingExtension = from.quietEndingExtension;
        to.executionDelay = from.executionDelay;
        return to;
    }

    /**
    * @dev Change vote time
    * @param _setting Setting instance to update
    * @param _voteTime New vote time
    */
    function _changeVoteTime(Setting storage _setting, uint64 _voteTime) internal {
        require(_voteTime > 0, ERROR_VOTE_TIME_ZERO);

        _setting.voteTime = _voteTime;
        emit ChangeVoteTime(_voteTime);
    }

    /**
    * @dev Change the required support
    * @param _setting Setting instance to update
    * @param _supportRequiredPct New required support; expressed as a percentage of 10^18
    */
    function _changeSupportRequiredPct(Setting storage _setting, uint64 _supportRequiredPct) internal {
        require(_setting.minAcceptQuorumPct <= _supportRequiredPct, ERROR_CHANGE_SUPPORT_TOO_SMALL);
        require(_supportRequiredPct < PCT_BASE, ERROR_CHANGE_SUPPORT_TOO_BIG);

        _setting.supportRequiredPct = _supportRequiredPct;
        emit ChangeSupportRequired(_supportRequiredPct);
    }

    /**
    * @dev Change the minimum acceptance quorum
    * @param _setting Setting instance to update
    * @param _minAcceptQuorumPct New acceptance quorum; expressed as a percentage of 10^18
    */
    function _changeMinAcceptQuorumPct(Setting storage _setting, uint64 _minAcceptQuorumPct) internal {
        require(_minAcceptQuorumPct <= _setting.supportRequiredPct, ERROR_CHANGE_QUORUM_TOO_BIG);

        _setting.minAcceptQuorumPct = _minAcceptQuorumPct;
        emit ChangeMinQuorum(_minAcceptQuorumPct);
    }

    /**
    * @dev Change the delegated voting period
    * @param _setting Setting instance to update
    * @param _delegatedVotingPeriod New delegated voting period
    */
    function _changeDelegatedVotingPeriod(Setting storage _setting, uint64 _delegatedVotingPeriod) internal {
        require(_delegatedVotingPeriod <= _setting.voteTime, ERROR_INVALID_DELEGATED_VOTING_PERIOD);

        _setting.delegatedVotingPeriod = _delegatedVotingPeriod;
        emit ChangeDelegatedVotingPeriod(_delegatedVotingPeriod);
    }

    /**
    * @dev Change the quiet ending configuration
    * @param _setting Setting instance to update
    * @param _quietEndingPeriod New quiet ending period
    * @param _quietEndingExtension New quiet ending extension
    */
    function _changeQuietEndingConfiguration(Setting storage _setting, uint64 _quietEndingPeriod, uint64 _quietEndingExtension) internal {
        require(_quietEndingPeriod <= _setting.voteTime, ERROR_INVALID_QUIET_ENDING_PERIOD);

        _setting.quietEndingPeriod = _quietEndingPeriod;
        _setting.quietEndingExtension = _quietEndingExtension;
        emit ChangeQuietEndingConfiguration(_quietEndingPeriod, _quietEndingExtension);
    }

    /**
    * @dev Change the execution delay
    * @param _setting Setting instance to update
    * @param _executionDelay New execution delay
    */
    function _changeExecutionDelay(Setting storage _setting, uint64 _executionDelay) internal {
        _setting.executionDelay = _executionDelay;
        emit ChangeExecutionDelay(_executionDelay);
    }

    /**
    * @dev Create a new vote
    * @param _executionScript Action (encoded as an EVM script) that will be allowed to execute if the vote passes
    * @param _context Additional context for the vote, also used as the disputable action's context on the attached Agreement
    * @return voteId Identification number for the newly created vote
    */
    function _newVote(bytes _executionScript, bytes _context) internal returns (uint256 voteId) {
        uint64 snapshotBlock = getBlockNumber64() - 1; // avoid double voting in this very block
        uint256 totalPower = token.totalSupplyAt(snapshotBlock);
        require(totalPower > 0, ERROR_NO_TOTAL_VOTING_POWER);

        voteId = votesLength++;

        Vote storage vote_ = votes[voteId];
        vote_.totalPower = totalPower;
        vote_.startDate = getTimestamp64();
        vote_.snapshotBlock = snapshotBlock;
        vote_.status = VoteStatus.Normal;
        vote_.settingId = _getCurrentSettingId();
        vote_.executionScriptHash = keccak256(_executionScript);

        // Notify the attached Agreement about the new vote; this is mandatory in making the vote disputable
        // Note that we send `msg.sender` as the action's submitter--the attached Agreement may expect to be able to pull funds from this account
        vote_.actionId = _registerDisputableAction(voteId, _context, msg.sender);

        emit StartVote(voteId, msg.sender, _context, _executionScript);
    }

    /**
    * @dev Cast a vote
    *      Assumes all eligibility checks have passed for the given vote and voter
    * @param _vote Vote instance
    * @param _voteId Identification number of vote
    * @param _supports Whether principal voter supports the vote
    * @param _voter Address of principal voter
    * @param _caster Address of vote caster, if voting via representative
    */
    function _castVote(Vote storage _vote, uint256 _voteId, bool _supports, address _voter, address _caster) internal {
        Setting storage setting = settings[_vote.settingId];
        if (_hasStartedQuietEndingPeriod(_vote, setting)) {
            _ensureQuietEnding(_vote, setting, _voteId);
        }

        uint256 yeas = _vote.yea;
        uint256 nays = _vote.nay;
        uint256 voterStake = token.balanceOfAt(_voter, _vote.snapshotBlock);

        VoteCast storage castVote = _vote.castVotes[_voter];
        VoterState previousVoterState = castVote.state;

        // If voter had previously voted, reset their vote
        // Note that votes can only be changed once by the principal voter to overrule their representative's vote
        if (previousVoterState == VoterState.Yea) {
            yeas = yeas.sub(voterStake);
        } else if (previousVoterState == VoterState.Nay) {
            nays = nays.sub(voterStake);
        }

        if (_supports) {
            yeas = yeas.add(voterStake);
        } else {
            nays = nays.add(voterStake);
        }

        _vote.yea = yeas;
        _vote.nay = nays;
        castVote.state = _voterStateFor(_supports);
        castVote.caster = _caster;
        emit CastVote(_voteId, _voter, _supports, _caster == address(0) ? _voter : _caster);
    }

    /**
    * @dev Ensure we keep track of the information related for detecting a quiet ending
    * @param _vote Vote instance
    * @param _setting Setting instance applicable to the vote
    * @param _voteId Identification number of the vote
    */
    function _ensureQuietEnding(Vote storage _vote, Setting storage _setting, uint256 _voteId) internal {
        bool isAccepted = _isAccepted(_vote, _setting);

        if (_vote.quietEndingSnapshotSupport == VoterState.Absent) {
            // If we do not have a snapshot of the support yet, simply store the given value.
            // Note that if there are no votes during the quiet ending period, it is obviously impossible for the vote to be flipped and
            // this snapshot is never stored.
            _vote.quietEndingSnapshotSupport = _voterStateFor(isAccepted);
        } else {
            // We are calculating quiet ending extensions via "rolling snapshots", and so we only update the vote's cached duration once
            // the last period is over and we've confirmed the flip.
            if (getTimestamp() >= _lastComputedVoteEndDate(_vote, _setting)) {
                _vote.quietEndingExtensionDuration = _vote.quietEndingExtensionDuration.add(_setting.quietEndingExtension);
                emit QuietEndingExtendVote(_voteId, isAccepted);
            }
        }
    }

    /**
    * @dev Fetch a setting's instance by identification number
    * @return Identification number of the current setting
    */
    function _getSetting(uint256 _settingId) internal view returns (Setting storage) {
        require(_settingId < settingsLength, ERROR_SETTING_DOES_NOT_EXIST);
        return settings[_settingId];
    }

    /**
    * @dev Tell the identification number of the current setting
    * @return Identification number of the current setting
    */
    function _getCurrentSettingId() internal view returns (uint256) {
        // No need for SafeMath, note that a new setting is created during initialization
        return settingsLength - 1;
    }

    /**
    * @dev Fetch a vote instance by identification number
    * @param _voteId Identification number of the vote
    * @return Vote instance
    */
    function _getVote(uint256 _voteId) internal view returns (Vote storage) {
        require(_voteId < votesLength, ERROR_NO_VOTE);
        return votes[_voteId];
    }

    /**
    * @dev Tell if a voter can participate in a vote.
    *      Note that a voter cannot change their vote once cast, except by the principal voter to overrule their representative's vote.
    * @param _vote Vote instance being queried
    * @param _voter Address of the voter being queried
    * @return True if the voter can participate a certain vote
    */
    function _canVote(Vote storage _vote, address _voter) internal view returns (bool) {
        Setting storage setting = settings[_vote.settingId];
        return _isVoteOpenForVoting(_vote, setting) && _hasVotingPower(_vote, _voter) && _voteCaster(_vote, _voter) != _voter;
    }

    /**
    * @dev Tell if a vote currently allows representatives to vote for delegated voters
    * @param _vote Vote instance being queried
    * @return True if the vote currently allows representatives to vote
    */
    function _canRepresentativesVote(Vote storage _vote) internal view returns (bool) {
        return _isNormal(_vote) && !_hasFinishedDelegatedVotingPeriod(_vote, settings[_vote.settingId]);
    }

    /**
    * @dev Tell if a vote can be executed
    * @param _vote Vote instance being queried
    * @return True if the vote can be executed
    */
    function _canExecute(Vote storage _vote) internal view returns (bool) {
        // If the vote is executed, paused, or cancelled, it cannot be executed
        if (!_isNormal(_vote)) {
            return false;
        }

        Setting storage setting = settings[_vote.settingId];

        // If the vote is still open, it cannot be executed
        if (!_hasEnded(_vote, setting)) {
            return false;
        }

        // If the vote's execution delay has not finished yet, it cannot be executed
        if (!_hasFinishedExecutionDelay(_vote, setting)) {
            return false;
        }

        // Check the vote has enough support and has reached the min quorum
        return _isAccepted(_vote, setting);
    }

    /**
    * @dev Tell if a vote is in a "normal" non-exceptional state
    * @param _vote Vote instance being queried
    * @return True if the vote is normal
    */
    function _isNormal(Vote storage _vote) internal view returns (bool) {
        return _vote.status == VoteStatus.Normal;
    }

    /**
    * @dev Tell if a vote is paused
    * @param _vote Vote instance being queried
    * @return True if the vote is paused
    */
    function _isPaused(Vote storage _vote) internal view returns (bool) {
        return _vote.status == VoteStatus.Paused;
    }

    /**
    * @dev Tell if a vote was executed
    * @param _vote Vote instance being queried
    * @return True if the vote was executed
    */
    function _isExecuted(Vote storage _vote) internal view returns (bool) {
        return _vote.status == VoteStatus.Executed;
    }

    /**
    * @dev Tell if a vote is currently accepted
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return True if the vote is accepted
    */
    function _isAccepted(Vote storage _vote, Setting storage _setting) internal view returns (bool) {
        uint256 yeas = _vote.yea;
        uint256 nays = _vote.nay;
        uint64 supportRequiredPct = _setting.supportRequiredPct;
        uint64 minimumAcceptanceQuorumPct = _setting.minAcceptQuorumPct;
        return _isValuePct(yeas, yeas.add(nays), supportRequiredPct) &&
               _isValuePct(yeas, _vote.totalPower, minimumAcceptanceQuorumPct);
    }

    /**
    * @dev Tell if a vote is open for voting
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return True if the vote is open for voting
    */
    function _isVoteOpenForVoting(Vote storage _vote, Setting storage _setting) internal view returns (bool) {
        return _isNormal(_vote) && !_hasEnded(_vote, _setting);
    }

    /**
    * @dev Tell if a vote has ended
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return True if the vote has ended
    */
    function _hasEnded(Vote storage _vote, Setting storage _setting) internal view returns (bool) {
        return getTimestamp() >= _currentVoteEndDate(_vote, _setting);
    }

    /**
    * @dev Tell if a vote's delegated voting period has finished
    *      This function doesn't ensure that the vote is still open
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return True if the vote's delegated voting period has finished
    */
    function _hasFinishedDelegatedVotingPeriod(Vote storage _vote, Setting storage _setting) internal view returns (bool) {
        uint64 baseDelegatedVotingPeriodEndDate = _vote.startDate.add(_setting.delegatedVotingPeriod);

        // If the vote was paused before the delegated voting period ended, we need to extend it
        uint64 pausedAt = _vote.pausedAt;
        uint64 pauseDuration = _vote.pauseDuration;
        uint64 actualDeletedVotingEndDate = pausedAt != 0 && pausedAt < baseDelegatedVotingPeriodEndDate
            ? baseDelegatedVotingPeriodEndDate.add(pauseDuration)
            : baseDelegatedVotingPeriodEndDate;

        return getTimestamp() >= actualDeletedVotingEndDate;
    }

    /**
    * @dev Tell if a vote's quiet ending period has started
    *      This function doesn't ensure that the vote is still open
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return True if the vote's quiet ending period has started
    */
    function _hasStartedQuietEndingPeriod(Vote storage _vote, Setting storage _setting) internal view returns (bool) {
        uint64 voteBaseEndDate = _baseVoteEndDate(_vote, _setting);
        uint64 baseQuietEndingPeriodStartDate = voteBaseEndDate.sub(_setting.quietEndingPeriod);

        // If the vote was paused before the quiet ending period started, we need to delay it
        uint64 pausedAt = _vote.pausedAt;
        uint64 pauseDuration = _vote.pauseDuration;
        uint64 actualQuietEndingPeriodStartDate = pausedAt != 0 && pausedAt < baseQuietEndingPeriodStartDate
            ? baseQuietEndingPeriodStartDate.add(pauseDuration)
            : baseQuietEndingPeriodStartDate;

        return getTimestamp() >= actualQuietEndingPeriodStartDate;
    }

    /**
    * @dev Tell if a vote's execution delay has finished
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return True if the vote's execution delay has finished
    */
    function _hasFinishedExecutionDelay(Vote storage _vote, Setting storage _setting) internal view returns (bool) {
        uint64 endDate = _currentVoteEndDate(_vote, _setting);
        return getTimestamp() >= endDate.add(_setting.executionDelay);
    }

    /**
    * @dev Calculate the original end date of a vote
    *      It does not consider extensions from pauses or the quiet ending mechanism
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return Datetime of the vote's original end date
    */
    function _baseVoteEndDate(Vote storage _vote, Setting storage _setting) internal view returns (uint64) {
        return _vote.startDate.add(_setting.voteTime);
    }

    /**
    * @dev Tell the last computed end date of a vote.
    *      It considers extensions from pauses and the quiet ending mechanism.
    *      We call this the "last computed end date" because we use the currently cached quiet ending extension, which may be off-by-one from reality
    *      because it is only updated on the first vote in a new extension (which may never happen).
    *      The pause duration will only be included after the vote has "resumed" from its pause, as we do not know how long the pause will be in advance.
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return Datetime of the vote's last computed end date
    */
    function _lastComputedVoteEndDate(Vote storage _vote, Setting storage _setting) internal view returns (uint64) {
        uint64 endDateAfterPause = _baseVoteEndDate(_vote, _setting).add(_vote.pauseDuration);
        return endDateAfterPause.add(_vote.quietEndingExtensionDuration);
    }

    /**
    * @dev Calculate the current end date of a vote.
    *      It considers extensions from pauses and the quiet ending mechanism.
    *      We call this the "current end date" because it takes into account a posssibly "missing" quiet ending extension that was not cached with the vote.
    *      The pause duration will only be included after the vote has "resumed" from its pause, as we do not know how long the pause will be in advance.
    * @param _vote Vote instance being queried
    * @param _setting Setting instance applicable to the vote
    * @return Datetime of the vote's current end date
    */
    function _currentVoteEndDate(Vote storage _vote, Setting storage _setting) internal view returns (uint64) {
        uint64 lastComputedEndDate = _lastComputedVoteEndDate(_vote, _setting);

        // The last computed end date is correct if we have not passed it yet or if no flip was detected in the last extension
        if (getTimestamp() < lastComputedEndDate || !_wasFlipped(_vote)) {
            return lastComputedEndDate;
        }

        // Otherwise, since the last computed end date was reached and included a flip, we need to extend the end date by one more period
        return lastComputedEndDate.add(_setting.quietEndingExtension);
    }

    /**
    * @dev Tell if a vote was flipped in its most recent quiet ending period
    *      This function assumes that it will only be called after the most recent quiet ending period has already ended
    * @param _vote Vote instance being queried
    * @return True if the vote was flipped
    */
    function _wasFlipped(Vote storage _vote) internal view returns (bool) {
        // If there was no snapshot taken, it means no one voted during the quiet ending period. Thus, it cannot have been flipped.
        VoterState snapshotSupport = _vote.quietEndingSnapshotSupport;
        if (snapshotSupport == VoterState.Absent) {
            return false;
        }

        // Otherwise, we calculate if the vote was flipped by comparing its current acceptance state to its last state at the start of the extension period
        bool wasInitiallyAccepted = snapshotSupport == VoterState.Yea;
        Setting storage setting = settings[_vote.settingId];
        uint256 currentExtensions = _vote.quietEndingExtensionDuration / setting.quietEndingExtension;
        bool wasAcceptedBeforeLastFlip = wasInitiallyAccepted != (currentExtensions % 2 != 0);
        return wasAcceptedBeforeLastFlip != _isAccepted(_vote, setting);
    }

    /**
    * @dev Tell if a voter has voting power for a vote
    * @param _vote Vote instance being queried
    * @param _voter Address of the voter being queried
    * @return True if the voter has voting power for a certain vote
    */
    function _hasVotingPower(Vote storage _vote, address _voter) internal view returns (bool) {
        return token.balanceOfAt(_voter, _vote.snapshotBlock) > 0;
    }

    /**
    * @dev Tell if a voter has cast their choice in a vote (by themselves or via a representative)
    * @param _vote Vote instance being queried
    * @param _voter Address of the voter being queried
    * @return True if the voter has cast their choice in the vote
    */
    function _hasCastVote(Vote storage _vote, address _voter) internal view returns (bool) {
        return _voterState(_vote, _voter) != VoterState.Absent;
    }

    /**
    * @dev Tell the state of a voter for a vote
    * @param _vote Vote instance being queried
    * @param _voter Address of the voter being queried
    * @return Voting state of the voter
    */
    function _voterState(Vote storage _vote, address _voter) internal view returns (VoterState) {
        return _vote.castVotes[_voter].state;
    }

    /**
    * @dev Tell the caster of a voter on a vote
    * @param _vote Vote instance being queried
    * @param _voter Address of the voter being queried
    * @return Address of the vote's caster
    */
    function _voteCaster(Vote storage _vote, address _voter) internal view returns (address) {
        if (!_hasCastVote(_vote, _voter)) {
            return address(0);
        }

        address _caster = _vote.castVotes[_voter].caster;
        return _caster == address(0) ? _voter : _caster;
    }

    /**
    * @dev Tell if a representative currently represents another voter
    * @param _voter Address of the delegated voter being queried
    * @param _representative Address of the representative being queried
    * @return True if the representative currently represents the voter
    */
    function _isRepresentativeOf(address _voter, address _representative) internal view returns (bool) {
        return representatives[_voter] == _representative;
    }

    /**
    * @dev Tell if an address can forward actions
    * @param _sender Address intending to forward an action
    * @return True if the address can create votes
    */
    function _canForward(address _sender, bytes) internal view returns (bool) {
        IAgreement agreement = _getAgreement();
        // To make sure the sender address is reachable by ACL oracles, we need to pass it as the first argument.
        // Permissions set with ANY_ENTITY do not provide the original sender's address into the ACL Oracle's `grantee` argument.
        return agreement != IAgreement(0) && canPerform(_sender, CREATE_VOTES_ROLE, arr(_sender));
    }

    /**
    * @dev Calculates whether a given value is greater than a percentage of its total
    * @param _value Numerator
    * @param _total Divisor
    * @param _pct Required percentage necessary, expressed as a percentage of 10^18
    * @return True if the value is above the required percentage
    */
    function _isValuePct(uint256 _value, uint256 _total, uint256 _pct) internal pure returns (bool) {
        if (_total == 0) {
            return false;
        }

        uint256 computedPct = _value.mul(PCT_BASE) / _total;
        return computedPct > _pct;
    }

    /**
    * @dev Translate a voter's support into a voter state
    * @param _supports Whether voter supports the vote
    * @return Voter state, as an enum
    */
    function _voterStateFor(bool _supports) internal pure returns (VoterState) {
        return _supports ? VoterState.Yea : VoterState.Nay;
    }
}