pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBridge.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "./RelayRecipient.sol";
import "./utils/IWrapper.sol";
import "./SymbHelper.sol";

/** @title A contract that synthesizes tokens
* @notice In order to create a synthetic representation on another network, the user must call synthesize function here
* @dev All function calls are currently implemented without side effects 
*/
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
    uint public nativeTokenPrice;
    address public wrapper;
    SymbHelper public symbHelper;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => UnsynthesizeState) public unsynthesizeStates;

    event SynthesizeRequest(bytes32 indexed id, address indexed  from, address indexed to, uint amount,address token);
    event RevertBurnRequest(bytes32 indexed id, address indexed to);
    event BurnCompleted(bytes32 indexed id, address indexed to, uint amount,address token);
    event RevertSynthesizeCompleted(bytes32 indexed id, address indexed to, uint amount, address token);

    /**
     * init
     */

    function initialize(
        address _bridge, address _trustedForwarder, address _wrapper
    ) public virtual initializer {
        __RelayRecipient_init(_trustedForwarder);
        bridge = _bridge;
        nativeTokenPrice = 10000000000000000; // 0.01 of native token
        wrapper = _wrapper;
        symbHelper = new SymbHelper();
    }

    modifier onlyBridge {
        require(bridge == msg.sender);
        _;
    }

    function sendSynthesizeRequest(address _token, uint256 _amount, address _chain2address, address _receiveSide, address _oppositeBridge, uint _chainID) whenNotPaused  internal returns (bytes32 txID){
        balanceOf[_token] = balanceOf[_token] + _amount;
        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,uint256,address)'))), txID, _token, block.chainid, _amount, _chain2address);
        IBridge(bridge).transmitRequestV2(out,_receiveSide, _oppositeBridge, _chainID);
        TxState storage txState = requests[txID];
        txState.recipient    = _msgSender();
        txState.chain2address    = _chain2address;
        txState.rtoken     = _token;
        txState.amount     = _amount;
        txState.state = RequestState.Sent;

        requestCount += 1;
        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    /** @notice Sends synthesize request
    * @dev Token -> sToken on a second chain
    * @param _token The address of the token that the user wants to synthesize
    * @param _amount Number of tokens to synthesize
    * @param _chain2address The address to which the user wants to receive the synth asset on another network
    * @param _receiveSide Synthesis address on another network
    * @param _oppositeBridge Bridge address on another network
    * @param _chainID Chain id of the network where synthesization will take place 
    */
    function synthesize(address _token, uint256 _amount, address _chain2address, address _receiveSide, address _oppositeBridge, uint _chainID) whenNotPaused payable external returns (bytes32 txID) {
        require(msg.value == nativeTokenPrice, "Symb: Not enough money");
        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        sendSynthesizeRequest(_token, _amount, _chain2address, _receiveSide, _oppositeBridge, _chainID);
    }


    /// @notice Native -> sToken on a second chain
    function synthesizeNative(address _chain2address, address _receiveSide, address _oppositeBridge, uint _chainID) whenNotPaused payable external returns (bytes32 txID) {
        uint256 amount =  msg.value - nativeTokenPrice;
        require(amount > 0, "Symb: Not enough money");
        symbHelper.depositToWrapper{value: amount}(wrapper);
        sendSynthesizeRequest(wrapper, amount, _chain2address, _receiveSide, _oppositeBridge, _chainID);
    }

    /** @notice Token -> sToken on a second chain withPermit
    * @param _approvalData Allowance to spend tokens
    */
    function synthesizeWithPermit(bytes calldata _approvalData, address _token, uint256 _amount, address _chain2address, address _receiveSide, address _oppositeBridge, uint _chainID) whenNotPaused external payable returns (bytes32 txID) {
        require(msg.value == nativeTokenPrice, "Symb: Not enough money");
        (bool _success1, ) = _token.call(_approvalData);
        require(_success1, "Symb: Approve call failed");

        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        sendSynthesizeRequest(_token, _amount, _chain2address, _receiveSide, _oppositeBridge, _chainID);
    }

    function unlockAssets(address _token, uint256 _amount, address _to) internal{
        if (_token == wrapper) {
            symbHelper.withdrawFromWrapper(wrapper, _amount, _to);
        } else {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
    }

    /** @notice Emergency unsynthesize
    * @dev Can called only by bridge after initiation on a second chain
    * @dev If a transaction arrives at the synthesization chain with an already completed revert synthesize contract will fail this transaction,
    * since the state was changed during the call to the desynthesis request
    * @param _txID the synthesize transaction that was received from the event when it was originally called synthesize on the Portal contract 
    */
    function revertSynthesize(bytes32 _txID) onlyBridge whenNotPaused external{
        TxState storage txState = requests[_txID];
        require(txState.state == RequestState.Sent , 'Symb: state not open or tx does not exist');
        txState.state = RequestState.Reverted; // close
        balanceOf[txState.rtoken] = balanceOf[txState.rtoken] - txState.amount;

        unlockAssets(txState.rtoken, txState.amount, txState.recipient);

        emit RevertSynthesizeCompleted(_txID, txState.recipient, txState.amount, txState.rtoken);
    }

    function unsynthesize(bytes32 _txID, address _token, uint256 _amount, address _to) onlyBridge whenNotPaused external{
        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Symb: syntatic tokens emergencyUnburn");
        balanceOf[_token] = balanceOf[_token] - _amount;

        unlockAssets(_token, _amount, _to);

        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _to, _amount, _token);
    }

    /** @notice Revert burnSyntheticToken() operation
    * @dev Can called only by bridge after initiation on a second chain
    * @dev Further, this transaction also enters the relay network and is called on the other side under the method "revertBurn"
    * @param _txID the synthesize transaction that was received from the event when it was originally called burn on the Synthesize contract
    * @param _receiveSide Synthesis address on another network
    * @param _oppositeBridge Bridge address on another network
    * @param _chainId Chain id of the network 
    */
    function revertBurnRequest(bytes32 _txID, address _receiveSide, address _oppositeBridge, uint _chainId) whenNotPaused payable external {
        require(unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized, "Symb: Real tokens already transfered");
        require(msg.value == nativeTokenPrice, "Symb: Not enough money");
        unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('emergencyUnburn(bytes32)'))),_txID);
        IBridge(bridge).transmitRequestV2(out, _receiveSide, _oppositeBridge, _chainId);

        emit RevertBurnRequest(_txID, _msgSender());
    }

    // todo should be restricted in mainnets
    function changeBridge(address _bridge) onlyOwner external{
        bridge = _bridge;
    }

    function pause() onlyOwner external{
        paused = true;
    }

    function unpause() onlyOwner external{
        paused = false;
    }

    function changeBridgePrice(uint256 _newPrice) onlyOwner external{
        nativeTokenPrice = _newPrice;
    }

    function withdrawBridgeFee(address payable _to) external onlyOwner {
        _to.transfer((address(this).balance));
    }

    receive() external payable {}

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrapper is IERC20{
    function deposit() external payable;
    function withdraw(uint amount) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/IWrapper.sol";

contract SymbHelper is Ownable{

    function depositToWrapper(address wrapper) payable onlyOwner external{
        IWrapper(wrapper).deposit{value: msg.value}();
    }

    function withdrawFromWrapper(address wrapper, uint amount, address recipient) onlyOwner external {
        IWrapper(wrapper).withdraw(amount);
        address payable payer = payable(recipient);
        payer.transfer(amount);
    }
    receive() external payable {}
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

