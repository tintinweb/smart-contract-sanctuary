/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// Source: UniswapV2
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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




pragma solidity >=0.4.22 <0.9.0;

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


/**
 * Deversifi escrow contract for other chains to allow distribution of tokens
 * from mainnet to other networks
 */
contract DVFDepositContract is OwnableUpgradeable {
  mapping(address => bool) public authorized;
  mapping(string => bool) public processedWithdrawalIds;

  modifier _isAuthorized() {
    require(
      authorized[msg.sender],
      "UNAUTHORIZED"
    );
    _;
  }

  modifier _validateWithdrawalId(string calldata withdrawalId) {
    require(
      bytes(withdrawalId).length > 0,
      "Withdrawal ID is required"
    );
    require(
      !processedWithdrawalIds[withdrawalId],
      "Withdrawal ID Already processed"
    );
    _;
  }

  event BridgedDeposit(address indexed user, address indexed token, uint256 amount);
  event BridgedWithdrawal(address indexed user, address indexed token, uint256 amount, string withdrawalId);

  function initialize() public initializer {
    __Ownable_init();
    authorized[_msgSender()] = true;
  }

  /**
    * @dev Deposit ERC20 tokens into the contract address, must be approved
    */
  function deposit(address token, uint256 amount) external {
    TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
    emit BridgedDeposit(msg.sender, token, amount);
  }


  /**
    * @dev Deposit native chain currency into contract address
    */
  function depositNative() external payable {
    emit BridgedDeposit(msg.sender, address(0), msg.value); // Maybe create new events for ETH deposit/withdraw
  }

  /**
    * @dev Deposit ERC20 token into the contract address
    * NOTE: Restricted deposit function for rebalancing
    */
  function addFunds(address token, uint256 amount) external _isAuthorized {
    TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
  }

  /**
    * @dev Deposit native chain currency into the contract address
    * NOTE: Restricted deposit function for rebalancing
    */
  function addFundsNative() external payable _isAuthorized { }

  /**
    * @dev withdraw ERC20 tokens from the contract address
    * NOTE: only for authorized users
    */
  function withdraw(address token, address to, uint256 amount, string calldata withdrawalId) external 
    _isAuthorized 
    _validateWithdrawalId(withdrawalId) 
  {
    processedWithdrawalIds[withdrawalId] = true;
    TransferHelper.safeTransfer(token, to, amount);
    emit BridgedWithdrawal(to, token, amount, withdrawalId);
  }

  /**
    * @dev withdraw native chain currency from the contract address
    * NOTE: only for authorized users
    */
  function withdrawNative(address payable to, uint256 amount, string calldata withdrawalId) external
    _isAuthorized 
    _validateWithdrawalId(withdrawalId) 
  {
    processedWithdrawalIds[withdrawalId] = true;
    removeFundsNative(to, amount);
    emit BridgedWithdrawal(to, address(0), amount, withdrawalId);
  }

  /**
    * @dev withdraw ERC20 token from the contract address
    * NOTE: only for authorized users for rebalancing
    */
  function removeFunds(address token, address to, uint256 amount) external 
    _isAuthorized 
  {
    TransferHelper.safeTransfer(token, to, amount);
  }

  /**
    * @dev withdraw native chain currency from the contract address
    * NOTE: only for authorized users for rebalancing
    */
  function removeFundsNative(address payable to, uint256 amount) public
    _isAuthorized 
  {
    require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");
    to.transfer(amount);
  }

  /**
    * @dev add or remove authorized users
    * NOTE: only owner
    */
  function authorize(address user, bool value) external onlyOwner {
    authorized[user] = value;
  }

  function transferOwner(address newOwner) external onlyOwner {
    authorized[newOwner] = true;
    authorized[owner()] = false;
    transferOwnership(newOwner);
  }

  function renounceOwnership() public view override onlyOwner {
    require(false, "Unable to renounce ownership");
  }
}