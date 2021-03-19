/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-07
*/

// SPDX-License-Identifier: MIT

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

// File: contracts/teleport/ethereum/Ownable.sol

// Modified from github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol

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
 * onlyOwner, which can be applied to your functions to restrict their use to
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
    * onlyOwner functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
    * @dev Transfers ownership of the contract to a new account (newOwner).
    * Can only be called by the current owner.
    */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/teleport/ethereum/TeleportAdmin.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple accounts (admins) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * consumeAuthorization, which can be applied to your functions to restrict
 * their use to the admins.
 */
contract TeleportAdmin is Ownable {
  mapping(address => uint256) private _allowedAmount;

  event AdminUpdated(address indexed account, uint256 allowedAmount);

  /**
    * @dev Checks the authorized amount of an admin account.
    */
  function allowedAmount(address account) public view returns (uint256) {
    return _allowedAmount[account];
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

    // reduce authorization amount
    _allowedAmount[sender] -= amount;
    emit AdminUpdated(sender, _allowedAmount[sender]);
  }

  /**
    * @dev Updates the admin status of an account.
    * Can only be called by the current owner.
    */
  function updateAdmin(address account, uint256 allowedAmount) public virtual onlyOwner {
    emit AdminUpdated(account, allowedAmount);
    _allowedAmount[account] = allowedAmount;
  }
}

// File: contracts/teleport/ethereum/TetherToken.sol

pragma solidity ^0.6.0;

contract ERC20Token {
    function transfer(address _to, uint _value) public {}
    function transferFrom(address _from, address _to, uint _value) public {}
}

// File: contracts/teleport/ethereum/TeleportCustody.sol

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract TeleportCustody is TeleportAdmin {
  ERC20Token private _tokenContract = ERC20Token(0x938912CDdC3343695337D5c576dEE1c7952B1173);

  // Records that an unlock transaction has been executed
  mapping(bytes32 => bool) private _unlocked;
  
  // Emmitted when user locks token and initiates teleport
  event Locked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  // Emmitted when teleport completes and token gets unlocked
  event Unlocked(uint256 amount, address indexed ethereumAddress, bytes32 indexed flowHash);

  // Emmitted when token contract is updated
  event TokenContractUpdated(address indexed tokenAddress);

  /**
    * @dev User locks token and initiates teleport request.
    */
  function lock(uint256 amount, bytes8 flowAddress)
    public
  {
    address sender = _msgSender();
    _tokenContract.transferFrom(sender, address(this), amount);
    emit Locked(amount, flowAddress, sender);
  }

  /**
    * @dev Admin unlocks token upon receiving teleport request from Flow.
    */
  function unlock(uint256 amount, address ethereumAddress, bytes32 flowHash)
    public
    consumeAuthorization(amount)
  {
    require(ethereumAddress != address(0), "TeleportCustody: ethereumAddress is the zero address");
    require(!_unlocked[flowHash], "TeleportCustody: same unlock hash has been executed");

    _tokenContract.transfer(ethereumAddress, amount);
    _unlocked[flowHash] = true;
    emit Unlocked(amount, ethereumAddress, flowHash);
  }

  // Owner methods

  /**
    * @dev Owner withdraws token from lockup contract.
    */
  function withdraw(uint256 amount)
    public
    onlyOwner
  {
    _tokenContract.transfer(owner(), amount);
  }

  /**
    * @dev Owner updates the target lockup token address.
    */
  function updateTokenAddress(address tokenAddress)
    public
    onlyOwner
  {
    _tokenContract = ERC20Token(tokenAddress);
  }
}