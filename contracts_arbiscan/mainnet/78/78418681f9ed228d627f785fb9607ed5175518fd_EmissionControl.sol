// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
@title BadgerDAO Emission Control
@author jintao.eth
@notice Emission Control is the on chain source of truth for Badger Boost parameters.
The two parameters exposed by mission control: 
- Token Weight
- Boosted Emission Rate
The token weight determines the percentage contribution to native or non native balances.
The boosted emission rate determines the percentage of Badger that is emitted according to
boost versus a pro rata emission.
@dev All operations must be conducted by an emission control manager.
The deployer is the original manager and can add or remove managers as needed.
*/
contract EmissionControl is Ownable {
  event TokenWeightChanged(address indexed _token, uint256 indexed _weight);
  event TokenBoostedEmissionChanged(
    address indexed _vault,
    uint256 indexed _weight
  );

  uint256 public constant MAX_BPS = 10_000;
  mapping(address => bool) public manager;
  mapping(address => uint256) public tokenWeight;
  mapping(address => uint256) public boostedEmissionRate;

  modifier onlyManager() {
    require(manager[msg.sender], "!manager");
    _;
  }

  constructor(address _vault) {
    manager[msg.sender] = true;
    tokenWeight[0xE9C12F06F8AFFD8719263FE4a81671453220389c] = 5_000;
    transferOwnership(_vault);
  }

  /// @param _manager address to add as manager
  function addManager(address _manager) external onlyOwner {
    manager[_manager] = true;
  }

  /// @param _manager address to remove as manager
  function removeManager(address _manager) external onlyOwner {
    manager[_manager] = false;
  }

  /// @param _token token address to assign weight
  /// @param _weight weight in bps
  function setTokenWeight(address _token, uint256 _weight)
    external
    onlyManager
  {
    require(_weight <= MAX_BPS, "INVALID_WEIGHT");
    tokenWeight[_token] = _weight;
    emit TokenWeightChanged(_token, _weight);
  }

  /// @param _vault vault address to assign boosted emission rate
  /// @param _weight rate in bps
  function setBoostedEmission(address _vault, uint256 _weight)
    external
    onlyManager
  {
    require(_weight <= MAX_BPS, "INVALID_WEIGHT");
    boostedEmissionRate[_vault] = _weight;
    emit TokenBoostedEmissionChanged(_vault, _weight);
  }

  /// @param _vault vault address to look up pro rata emission rate
  /// @dev convenience function for exposing the opposite mapping
  function proRataEmissionRate(address _vault) external view returns (uint256) {
    return MAX_BPS - boostedEmissionRate[_vault];
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