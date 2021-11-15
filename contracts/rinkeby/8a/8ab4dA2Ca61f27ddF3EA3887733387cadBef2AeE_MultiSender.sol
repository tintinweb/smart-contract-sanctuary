// SPDX-License-Identifier: MIT
// @nhancv
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IHookSender.sol";

// ---------------------------------------------------------------------
// MultiSender
// Maximum 700 addresses per TX
// ---------------------------------------------------------------------
contract MultiSender is OwnableUpgradeable {
  event LogEthSent(uint total);
  event LogTokenSent(address token, uint total);
  event LogHookSent(address hook);

  uint public txFee;
  uint public VIPFee;

  /**
   * @dev Upgradable initializer
   */
  function __MultiSender_init() public initializer {
    __Ownable_init();
  }

  mapping(address => bool) public vipList;

  function registerVIP() public payable {
    require(msg.value >= VIPFee, "0x00000000001");
    require(!vipList[_msgSender()], "0x00000000017");
    vipList[_msgSender()] = true;
    require(payable(_msgSender()).send(msg.value), "0x00000000002");
  }

  function addToVIPList(address[] memory _vipList) public onlyOwner {
    for (uint i = 0; i < _vipList.length; i++) {
      vipList[_vipList[i]] = true;
    }
  }

  function removeFromVIPList(address[] memory _vipList) public onlyOwner {
    for (uint i = 0; i < _vipList.length; i++) {
      vipList[_vipList[i]] = false;
    }
  }

  function isVIP(address _addr) public view returns (bool) {
    return _addr == owner() || vipList[_addr];
  }

  function setVIPFee(uint _fee) public onlyOwner {
    VIPFee = _fee;
  }

  function setTxFee(uint _fee) public onlyOwner {
    txFee = _fee;
  }

  function ethSendSameValue(address[] memory _to, uint _value) public payable {
    // Validate fee
    uint totalAmount = _to.length * _value;
    uint totalEthValue = msg.value;
    if (isVIP(_msgSender())) {
      require(totalEthValue >= totalAmount, "0x00000000003");
    } else {
      require(totalEthValue >= (totalAmount + txFee), "0x00000000004");
    }

    // Send
    // solhint-disable multiple-sends
    for (uint i = 0; i < _to.length; i++) {
      require(payable(_to[i]).send(_value), "0x00000000005");
    }

    emit LogEthSent(msg.value);
  }

  function ethSendDifferentValue(address[] memory _to, uint[] memory _value) public payable {
    require(_to.length == _value.length, "0x00000000006");

    uint totalEthValue = msg.value;

    // Validate fee
    uint totalAmount = 0;
    for (uint i = 0; i < _to.length; i++) {
      totalAmount = totalAmount + _value[i];
    }

    if (isVIP(_msgSender())) {
      require(totalEthValue >= totalAmount, "0x00000000007");
    } else {
      require(totalEthValue >= (totalAmount + txFee), "0x00000000008");
    }

    // Send
    for (uint i = 0; i < _to.length; i++) {
      require(payable(_to[i]).send(_value[i]), "0x00000000009");
    }

    emit LogEthSent(msg.value);
  }

  function coinSendSameValue(
    address _tokenAddress,
    address[] memory _to,
    uint _value
  ) public payable {
    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee, "0x00000000010");
    }

    // Validate token balance
    IERC20 token = IERC20(_tokenAddress);
    uint tokenBalance = token.balanceOf(_msgSender());
    uint totalAmount = _to.length * _value;
    require(tokenBalance >= totalAmount, "0x00000000011");

    // Send
    for (uint i = 0; i < _to.length; i++) {
      token.transferFrom(_msgSender(), _to[i], _value);
    }

    emit LogTokenSent(_tokenAddress, totalAmount);
  }

  function coinSendDifferentValue(
    address _tokenAddress,
    address[] memory _to,
    uint[] memory _value
  ) public payable {
    require(_to.length == _value.length, "0x00000000012");

    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee, "0x00000000013");
    }

    // Validate token balance
    IERC20 token = IERC20(_tokenAddress);
    uint tokenBalance = token.balanceOf(_msgSender());
    uint totalAmount = 0;
    for (uint i = 0; i < _to.length; i++) {
      totalAmount = totalAmount + _value[i];
    }
    require(tokenBalance >= totalAmount, "0x00000000014");

    // Send
    for (uint i = 0; i < _to.length; i++) {
      token.transferFrom(_msgSender(), _to[i], _value[i]);
    }

    emit LogTokenSent(_tokenAddress, totalAmount);
  }

  function hookSend(address _hookAddress, uint maxLoop) public payable {
    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee, "0x00000000015");
    }

    // Loop
    IHookSender hook = IHookSender(_hookAddress);
    for (uint i = 0; i < maxLoop; i++) {
      require(hook.multiSenderLoop(_msgSender(), i, maxLoop), "0x00000000016");
    }

    emit LogHookSent(_hookAddress);
  }

  function getEthBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  function getTokenBalance(address _tokenAddress) public view returns (uint) {
    IERC20 token = IERC20(_tokenAddress);
    return token.balanceOf(address(this));
  }

  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(owner(), getTokenBalance(_tokenAddress));
  }
}

// SPDX-License-Identifier: MIT
// @nhancv
pragma solidity 0.8.4;

// ---------------------------------------------------------------------
// HookSender
// To make MultiSender can be a unlimited integration
// ---------------------------------------------------------------------
abstract contract IHookSender {
  function multiSenderLoop(
    address caller,
    uint index,
    uint maxLoop
  ) public virtual returns (bool success);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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

