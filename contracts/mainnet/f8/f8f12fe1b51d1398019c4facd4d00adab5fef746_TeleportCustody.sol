/**
 *Submitted for verification at Etherscan.io on 2021-01-20
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
    constructor () internal {
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

// File: contracts/teleport/ethereum/TeleportAdmin.sol

pragma solidity 0.6.12;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple accounts (admins) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `consumeAuthorization`, which can be applied to your functions to restrict
 * their use to the admins.
 */
contract TeleportAdmin is Ownable {
  // Marks that the contract is frozen or unfrozen (safety kill-switch)
  bool private _isFrozen;

  mapping(address => uint256) private _allowedAmount;

  event AdminUpdated(address indexed account, uint256 allowedAmount);

  // Modifiers

  /**
    * @dev Throw if contract is currently frozen.
    */
  modifier notFrozen() {
    require(
      !_isFrozen,
      "TeleportAdmin: contract is frozen by owner"
    );

    _;
  }

  /**
    * @dev Throw if caller does not have sufficient authorized amount.
    */
  modifier consumeAuthorization(uint256 amount) {
    address sender = _msgSender();
    require(
      allowedAmount(sender) >= amount,
      "TeleportAdmin: caller does not have sufficient authorization"
    );

    _;

    // reduce authorization amount. Underflow cannot occur because we have
    // already checked that admin has sufficient allowed amount.
    _allowedAmount[sender] -= amount;
    emit AdminUpdated(sender, _allowedAmount[sender]);
  }

  /**
    * @dev Checks the authorized amount of an admin account.
    */
  function allowedAmount(address account)
    public
    view
    returns (uint256)
  {
    return _allowedAmount[account];
  }

  /**
    * @dev Returns if the contract is currently frozen.
    */
  function isFrozen()
    public
    view
    returns (bool)
  {
    return _isFrozen;
  }

  /**
    * @dev Owner freezes the contract.
    */
  function freeze()
    public
    onlyOwner
  {
    _isFrozen = true;
  }

  /**
    * @dev Owner unfreezes the contract.
    */
  function unfreeze()
    public
    onlyOwner
  {
    _isFrozen = false;
  }

  /**
    * @dev Updates the admin status of an account.
    * Can only be called by the current owner.
    */
  function updateAdmin(address account, uint256 newAllowedAmount)
    public
    virtual
    onlyOwner
  {
    emit AdminUpdated(account, newAllowedAmount);
    _allowedAmount[account] = newAllowedAmount;
  }

  /**
    * @dev Overrides the inherited method from Ownable.
    * Disable ownership resounce.
    */
  function renounceOwnership()
    public
    override
    onlyOwner
  {
    revert("TeleportAdmin: ownership cannot be renounced");
  }
}

// File: contracts/teleport/ethereum/TetherToken.sol

pragma solidity 0.6.12;

/**
 * @dev Method signature contract for Tether (USDT) because it's not a standard
 * ERC-20 contract and have different method signatures.
 */
interface TetherToken {
  function transfer(address _to, uint _value) external;
  function transferFrom(address _from, address _to, uint _value) external;
}

// File: contracts/teleport/ethereum/TeleportCustody.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Implementation of the TeleportCustody contract.
 *
 * There are two priviledged roles for the contract: "owner" and "admin".
 *
 * Owner: Has the ultimate control of the contract and the funds stored inside the
 *        contract. Including:
 *     1) "freeze" and "unfreeze" the contract: when the TeleportCustody is frozen,
 *        all deposits and withdrawals with the TeleportCustody is disabled. This 
 *        should only happen when a major security risk is spotted or if admin access
 *        is comprimised.
 *     2) assign "admins": owner has the authority to grant "unlock" permission to
 *        "admins" and set proper "unlock limit" for each "admin".
 *
 * Admin: Has the authority to "unlock" specific amount to tokens to receivers.
 */
contract TeleportCustody is TeleportAdmin {
  // USDC
  // ERC20 internal _tokenContract = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  
  // USDT
  TetherToken internal _tokenContract = TetherToken(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  // Records that an unlock transaction has been executed
  mapping(bytes32 => bool) internal _unlocked;
  
  // Emmitted when user locks token and initiates teleport
  event Locked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  // Emmitted when teleport completes and token gets unlocked
  event Unlocked(uint256 amount, address indexed ethereumAddress, bytes32 indexed flowHash);

  /**
    * @dev User locks token and initiates teleport request.
    */
  function lock(uint256 amount, bytes8 flowAddress)
    public
    notFrozen
  {
    address sender = _msgSender();

    // NOTE: Return value should be checked. However, Tether does not have return value.
    _tokenContract.transferFrom(sender, address(this), amount);

    emit Locked(amount, flowAddress, sender);
  }

  // Admin methods

  /**
    * @dev TeleportAdmin unlocks token upon receiving teleport request from Flow.
    */
  function unlock(uint256 amount, address ethereumAddress, bytes32 flowHash)
    public
    notFrozen
    consumeAuthorization(amount)
  {
    _unlock(amount, ethereumAddress, flowHash);
  }

  // Owner methods

  /**
    * @dev Owner unlocks token upon receiving teleport request from Flow.
    * There is no unlock limit for owner.
    */
  function unlockByOwner(uint256 amount, address ethereumAddress, bytes32 flowHash)
    public
    notFrozen
    onlyOwner
  {
    _unlock(amount, ethereumAddress, flowHash);
  }

  // Internal methods

  /**
    * @dev Internal function for processing unlock requests.
    * 
    * There is no way TeleportCustody can check the validity of the target address
    * beforehand so user and admin should always make sure the provided information
    * is correct.
    */
  function _unlock(uint256 amount, address ethereumAddress, bytes32 flowHash)
    internal
  {
    require(ethereumAddress != address(0), "TeleportCustody: ethereumAddress is the zero address");
    require(!_unlocked[flowHash], "TeleportCustody: same unlock hash has been executed");

    _unlocked[flowHash] = true;

    // NOTE: Return value should be checked. However, Tether does not have return value.
    _tokenContract.transfer(ethereumAddress, amount);

    emit Unlocked(amount, ethereumAddress, flowHash);
  }
}