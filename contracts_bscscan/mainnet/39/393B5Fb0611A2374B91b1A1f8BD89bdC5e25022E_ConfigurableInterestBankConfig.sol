/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.17;



// Part: BankConfig

interface BankConfig {
  /// @dev Return minimum USD debt size per position.
  function minDebtSize() external view returns (uint);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint);

  /// @dev Return whether the given address is a bigfoot.
  function isBigfoot(address bigfoot) external view returns (bool);

  /// @dev Return whether the given bigfoot accepts more debt. Revert on non-bigfoot.
  function acceptDebt(address bigfoot) external view returns (bool);

  /// @dev Return the work factor for the bigfoot + USD debt, using 1e4 as denom. Revert on non-bigfoot.
  function workFactor(address bigfoot, uint debt) external view returns (uint);

  /// @dev Return the kill factor for the bigfoot + USD debt, using 1e4 as denom. Revert on non-bigfoot.
  function killFactor(address bigfoot, uint debt) external view returns (uint);
}

// Part: BigfootConfig

interface BigfootConfig {
  /// @dev Return whether the given bigfoot accepts more debt.
  function acceptDebt(address bigfoot) external view returns (bool);

  /// @dev Return the work factor for the bigfoot + USD debt, using 1e4 as denom.
  function workFactor(address bigfoot, uint debt) external view returns (uint);

  /// @dev Return the kill factor for the bigfoot + USD debt, using 1e4 as denom.
  function killFactor(address bigfoot, uint debt) external view returns (uint);
}

// Part: InterestModel

interface InterestModel {
  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint);
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: ConfigurableInterestBankConfig.sol

contract ConfigurableInterestBankConfig is BankConfig, Ownable {
  /// The minimum USD debt size per position.
  uint public minDebtSize;
  /// The portion of interests allocated to the reserve pool.
  uint public getReservePoolBps;
  /// The reward for successfully killing a position.
  uint public getKillBps;
  /// Mapping for bigfoot address to its configuration.
  mapping(address => BigfootConfig) public bigfoots;
  /// Interest rate model
  InterestModel public interestModel;

  constructor(address _interestModel) public {
    setParams(10 ether, 1100, 100, InterestModel(_interestModel));
  }

  /// @dev Set all the basic parameters. Must only be called by the owner.
  /// @param _minDebtSize The new minimum debt size value.
  /// @param _reservePoolBps The new interests allocated to the reserve pool value.
  /// @param _killBps The new reward for killing a position value.
  /// @param _interestModel The new interest rate model contract.
  function setParams(uint _minDebtSize, uint _reservePoolBps, uint _killBps, InterestModel _interestModel) public onlyOwner {
    minDebtSize = _minDebtSize;
    getReservePoolBps = _reservePoolBps;
    getKillBps = _killBps;
    interestModel = _interestModel;
  }

  /// @dev Set the configuration for the given bigfoots. Must only be called by the owner.
  function setBigfoots(address[] calldata addrs, BigfootConfig[] calldata configs)
    external
    onlyOwner
  {
    require(addrs.length == configs.length, 'bad length');
    for (uint idx = 0; idx < addrs.length; idx++) {
      bigfoots[addrs[idx]] = configs[idx];
    }
  }

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint) {
    return interestModel.getInterestRate(debt, floating);
  }

  /// @dev Return whether the given address is a bigfoot.
  function isBigfoot(address bigfoot) external view returns (bool) {
    return address(bigfoots[bigfoot]) != address(0);
  }

  /// @dev Return whether the given bigfoot accepts more debt. Revert on non-bigfoot.
  function acceptDebt(address bigfoot) external view returns (bool) {
    return bigfoots[bigfoot].acceptDebt(bigfoot);
  }

  /// @dev Return the work factor for the bigfoot + USD debt, using 1e4 as denom. Revert on non-bigfoot.
  function workFactor(address bigfoot, uint debt) external view returns (uint) {
    return bigfoots[bigfoot].workFactor(bigfoot, debt);
  }

  /// @dev Return the kill factor for the bigfoot + USD debt, using 1e4 as denom. Revert on non-bigfoot.
  function killFactor(address bigfoot, uint debt) external view returns (uint) {
    return bigfoots[bigfoot].killFactor(bigfoot, debt);
  }
}