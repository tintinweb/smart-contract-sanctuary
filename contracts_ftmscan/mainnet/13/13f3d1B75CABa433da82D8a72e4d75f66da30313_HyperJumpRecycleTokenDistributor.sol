// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HyperJumpSimpleTokenDistributor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HyperJumpRecycleTokenDistributor is HyperJumpSimpleTokenDistributor {
  address public destination_address;

  uint256 public returned = 0;

  event ReturnedToMainDistributor(
    address indexed distributor,
    address indexed mainDistributor,
    uint256 amount,
    uint256 indexed timestamp
  );

  function setupRecycler(
    address _hyperJumpToken,
    address _hyperJumpToken_collector,
    address _destination_address
  ) public onlyOwner {
    HyperJumpSimpleTokenDistributor.initialize(
      _hyperJumpToken,
      _hyperJumpToken_collector
    );
    destination_address = _destination_address;
  }

  function sendToMainDistributor(uint256 _amount) public onlyOwner {
    IERC20(hyperJumpToken).transfer(destination_address, _amount);
    returned += _amount;
    emit ReturnedToMainDistributor(address(this), destination_address, _amount, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HyperJumpSimpleTokenDistributor is Ownable {
  bool public initialized = false;

  address public hyperJumpToken;
  address public hyperJumpToken_collector;

  uint256 public collected = 0;

  event Collected(
    address indexed distributor,
    address indexed collector,
    uint256 amount,
    uint256 indexed timestamp
  );
  
  event ValueReceived(
    address indexed sender,
    uint256 amount
  );

  event ValueCollected(
    address indexed collector,
    uint256 amount
  );

  function initialize(
    address _hyperJumpToken,
    address _hyperJumpToken_collector
  ) public onlyOwner {
    require(
      !initialized,
      "HyperJump token Distributor has already been initialized!"
    );
    initialized = true;
    hyperJumpToken = _hyperJumpToken;
    hyperJumpToken_collector = _hyperJumpToken_collector;
  }

  function collect(uint256 _amount) public {
    collectTo(msg.sender, _amount);
  }

  function collectTo(address _destination, uint256 _amount) public {
    require(
      msg.sender == hyperJumpToken_collector,
      "Only collector may collect JUMPs."
    );
    IERC20(hyperJumpToken).transfer(_destination, _amount);
    collected += _amount;
    emit Collected(address(this), _destination, _amount, block.timestamp);
  }

  function availableInDistributor() public view returns (uint256) {
    return IERC20(hyperJumpToken).balanceOf(address(this));
  }

  function availableInCollector() public view returns (uint256) {
    return IERC20(hyperJumpToken).balanceOf(hyperJumpToken_collector);
  }

  // receive payment fallback
  receive() external payable {
    emit ValueReceived(msg.sender, msg.value);
  }
  
  // collect received payment
  function collectPayments() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(msg.sender).transfer(amount);
    emit ValueCollected(msg.sender, amount); 
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}