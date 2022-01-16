/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Treasury.sol


pragma solidity ^0.8.0;


contract OpenHeadTreasury is Ownable {
  uint8 constant public MIN_WEEKLY_SHARE = 10;
  uint8 constant public MIN_MONTHLY_SHARE = 50;

  address payable immutable public weeklyRaffles;
  address payable immutable public monthlyRaffles;
  address payable public teamAddr;

  uint8 public weeklyShare;
  uint8 public monthlyShare;

  constructor(address payable _weeklyRaffles, address payable _monthlyRaffles, address payable _teamAddr) {
    weeklyRaffles = _weeklyRaffles;
    monthlyRaffles = _monthlyRaffles;
    teamAddr = _teamAddr;

    weeklyShare = MIN_WEEKLY_SHARE;
    monthlyShare = MIN_MONTHLY_SHARE;
  }

  function setWeeklyShare(uint8 percentage) external onlyOwner {
    require(percentage >= MIN_WEEKLY_SHARE, "Share cant be lower than minimum");
    require((percentage + monthlyShare) <= 100, "Total share can't be higher than 100%");

    weeklyShare = percentage;
  }

  function setMonthlyShare(uint8 percentage) external onlyOwner {
    require(percentage >= MIN_MONTHLY_SHARE, "Share cant be lower than minimum");
    require((percentage + weeklyShare) <= 100, "Total share can't be higher than 100%");

    monthlyShare = percentage;
  }

  function setTeamAddress(address payable _teamAddr) external onlyOwner {
    teamAddr = _teamAddr;
  }

  receive() external payable {
    uint balance = msg.value;
    uint monthly = balance * monthlyShare / 100;
    uint weekly = balance * weeklyShare / 100;
    uint rest = balance - monthly - weekly;

    (bool monthlySuccess, ) = monthlyRaffles.call{value: monthly}("");
    require(monthlySuccess, "Transfer failed.");

    (bool weeklySuccess, ) = weeklyRaffles.call{value: weekly}("");
    require(weeklySuccess, "Transfer failed.");

    (bool teamSuccess, ) = teamAddr.call{value: rest}("");
    require(teamSuccess, "Transfer failed.");
  }
}