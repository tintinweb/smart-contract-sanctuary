pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBridge.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "./RelayRecipient.sol";
import "./utils/Pausable.sol";



contract Portal is RelayRecipient {

    mapping(address => uint) public balanceOf;
    address public bridge;

    enum RequestState { Default, Sent, Reverted}
    enum UnsynthesizeState { Default, Unsynthesized, RevertRequest}

    struct TxState {
    address recipient;
    address chain2address;
    uint256 amount;
    address rtoken;
    RequestState state;
    }

    uint256 requestCount;
    bool public paused;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => UnsynthesizeState) public unsynthesizeStates;


    event SynthesizeRequest(bytes32 indexed _id, address indexed  _from, address indexed _to, uint _amount,address _token);
    event RevertBurnRequest(bytes32 indexed _id, address indexed _to);
    event BurnCompleted(bytes32 indexed _id, address indexed _to, uint _amount,address _token);
    event RevertSynthesizeCompleted(bytes32 indexed _id, address indexed _to, uint _amount, address _token);

    /**
     * init
     */

    function initialize(
        address _bridge, address _trustedForwarder
    ) public virtual initializer {
        __RelayRecipient_init(_trustedForwarder);
        bridge = _bridge;
    }

  modifier onlyBridge {
        require(bridge == msg.sender);
        _;
    }

    // Token -> sToken on a second chain
    function synthesize(address _token, uint256 _amount, address _chain2address, address _receiveSide, address _oppositeBridge, uint _chainID) whenNotPaused external returns (bytes32 txID) {
        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] = balanceOf[_token] + _amount;

        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,address)'))), txID, _token, _amount, _chain2address);
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out,_receiveSide, _oppositeBridge, _chainID);
        TxState storage txState = requests[txID];
        txState.recipient    = _msgSender();
        txState.chain2address    = _chain2address;
        txState.rtoken     = _token;
        txState.amount     = _amount;
        txState.state = RequestState.Sent;

        requestCount +=1;
        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    // Token -> sToken on a second chain withPermit
    function synthesizeWithPermit(bytes calldata _approvalData, address _token, uint256 _amount, address _chain2address, address _receiveSide, address _oppositeBridge, uint _chainID) whenNotPaused external returns (bytes32 txID) {

        (bool _success1, ) = _token.call(_approvalData);
        require(_success1, "Approve call failed");

        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] = balanceOf[_token] + _amount;

        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,address)'))), txID, _token, _amount, _chain2address);
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out,_receiveSide, _oppositeBridge, _chainID);
        TxState storage txState = requests[txID];
        txState.recipient    = _msgSender();
        txState.chain2address    = _chain2address;
        txState.rtoken     = _token;
        txState.amount     = _amount;
        txState.state = RequestState.Sent;

        requestCount +=1;
        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    // can called only by bridge after initiation on a second chain
    function emergencyUnsynthesize(bytes32 _txID) onlyBridge whenNotPaused external{
        TxState storage txState = requests[_txID];
        require(txState.state == RequestState.Sent , 'Portal:state not open or tx does not exist');
        txState.state = RequestState.Reverted; // close
        TransferHelper.safeTransfer(txState.rtoken, txState.recipient, txState.amount);

        emit RevertSynthesizeCompleted(_txID, txState.recipient, txState.amount, txState.rtoken);

    }

    // can called only by bridge after initiation on a second chain
    function unsynthesize(bytes32 _txID, address _token, uint256 _amount, address _to) onlyBridge whenNotPaused external{
        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Portal: syntatic tokens emergencyUnburn");

        TransferHelper.safeTransfer(_token, _to, _amount);
        balanceOf[_token] = balanceOf[_token] - _amount;

        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _to, _amount, _token);
    }

    // Revert burnSyntheticToken() operation, can be called several times
    function emergencyUnburnRequest(bytes32 _txID, address _receiveSide, address _oppositeBridge, uint _chainId) whenNotPaused external {
        require(unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized, "Portal: Real tokens already transfered");
        unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('emergencyUnburn(bytes32)'))),_txID);
        // TODO add payment by token
         IBridge(bridge).transmitRequestV2(out, _receiveSide, _oppositeBridge, _chainId);

        emit RevertBurnRequest(_txID, _msgSender());
    }

    // should be restricted in mainnets
    function changeBridge(address _bridge) onlyOwner external{
        bridge = _bridge;
    }

    function pause() onlyOwner external{
        paused = true;
    }

    function unpause() onlyOwner external{
        paused = false;
    }

    function versionRecipient() view public returns (string memory){
        return "2.0.1";
    }
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

interface IBridge {
     function transmitRequestV2(bytes memory owner, address receiveSide, address oppositeBridge, uint chainID) external  returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract RelayRecipient is  OwnableUpgradeable {
    address private _trustedForwarder;

    function __RelayRecipient_init(address trustedForwarder) internal initializer {
        __Ownable_init();
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {sender := shr(96, calldataload(sub(calldatasize(), 20)))}
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[: msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Initializable {
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
    function __Pausable_init() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

{
  "optimizer": {
    "enabled": false,
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