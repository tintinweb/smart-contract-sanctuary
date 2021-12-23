/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.7.0;

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


// File contracts/interfaces/IVault.sol

pragma solidity ^0.7.6;

interface IVault {
  function getRewardTokens() external view returns (address[] memory);

  function balance() external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function claim() external;

  function exit() external;

  function harvest() external;
}


// File contracts/interfaces/IRewardBondDepositor.sol

pragma solidity ^0.7.6;

interface IRewardBondDepositor {
  function currentEpoch()
    external
    view
    returns (
      uint64 epochNumber,
      uint64 startBlock,
      uint64 nextBlock,
      uint64 epochLength
    );

  function rewardShares(uint256 _epoch, address _vault) external view returns (uint256);

  function getVaultsFromAccount(address _user) external view returns (address[] memory);

  function getAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault
  ) external view returns (uint256[] memory);

  function bond(address _vault) external;

  function rebase() external;

  function notifyRewards(address _user, uint256[] memory _amounts) external;
}


// File contracts/Keeper.sol

pragma solidity ^0.7.6;


contract Keeper is Ownable {
  // The address of reward bond depositor.
  address public immutable depositor;

  // Record whether an address can call bond or not
  mapping(address => bool) public isBondWhitelist;
  // Record whether an address can call rebase or not
  mapping(address => bool) public isRebaseWhitelist;

  // A list of vaults. Push only, beware false-positives.
  address[] public vaults;
  // Record whether an address is vault or not.
  mapping(address => bool) public isVault;

  /// @param _depositor The address of reward bond depositor.
  constructor(address _depositor) {
    depositor = _depositor;
  }

  /// @dev bond ald for a list of vaults.
  /// @param _vaults The address list of vaults.
  function bond(address[] memory _vaults) external {
    require(isBondWhitelist[msg.sender], "Keeper: only bond whitelist");

    for (uint256 i = 0; i < _vaults.length; i++) {
      IRewardBondDepositor(depositor).bond(_vaults[i]);
    }
  }

  /// @dev bond ald for all supported vaults.
  function bondAll() external {
    require(isBondWhitelist[msg.sender], "Keeper: only bond whitelist");

    for (uint256 i = 0; i < vaults.length; i++) {
      address _vault = vaults[i];
      if (isVault[_vault]) {
        IRewardBondDepositor(depositor).bond(_vault);
      }
    }
  }

  /// @dev rebase ald
  function rebase() external {
    require(isRebaseWhitelist[msg.sender], "Keeper: only rebase whitelist");

    IRewardBondDepositor(depositor).rebase();
  }

  /// @dev harvest reward for all supported vaults.
  function harvestAll() external {
    for (uint256 i = 0; i < vaults.length; i++) {
      address _vault = vaults[i];
      if (isVault[_vault]) {
        IVault(_vault).harvest();
      }
    }
  }

  /// @dev update the whitelist who can call bond.
  /// @param _users The list of address.
  /// @param status Whether to add or remove.
  function updateBondWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isBondWhitelist[_users[i]] = status;
    }
  }

  /// @dev update the whitelist who can call rebase.
  /// @param _users The list of address.
  /// @param status Whether to add or remove.
  function updateRebaseWhitelist(address[] memory _users, bool status) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      isRebaseWhitelist[_users[i]] = status;
    }
  }

  /// @dev update supported vault
  /// @param _vault The address of vault.
  /// @param status Whether it is add or remove vault.
  function updateVault(address _vault, bool status) external onlyOwner {
    if (status) {
      require(!isVault[_vault], "Keeper: already added");
      isVault[_vault] = true;
      if (!_listContainsAddress(vaults, _vault)) {
        vaults.push(_vault);
      }
    } else {
      require(isVault[_vault], "Keeper: already removed");
      isVault[_vault] = false;
    }
  }

  function _listContainsAddress(address[] storage _list, address _item) internal view returns (bool) {
    uint256 length = _list.length;
    for (uint256 i = 0; i < length; i++) {
      if (_list[i] == _item) return true;
    }
    return false;
  }
}