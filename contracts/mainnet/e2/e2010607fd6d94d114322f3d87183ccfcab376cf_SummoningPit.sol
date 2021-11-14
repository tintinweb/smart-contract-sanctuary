/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

//
//  _____                                                 _   _ ______ _______
//  / ____|                                               | \ | |  ____|__   __|
// | (___  _   _ _ __ ___  _ __ ___   ___  _ __   ___ _ __|  \| | |__     | |
//  \___ \| | | | '_ ` _ \| '_ ` _ \ / _ \| '_ \ / _ \ '__| . ` |  __|    | |
//  ____) | |_| | | | | | | | | | | | (_) | | | |  __/ |  | |\  | |       | |
// |_____/ \__,_|_| |_| |_|_| |_| |_|\___/|_| |_|\___|_|  |_| \_|_|       |_|
//
// SummonerNFT
// https://summonernft.io/
// https://twitter.com/SummonerNFT

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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

// File contracts/SummoningPit.sol
pragma solidity ^0.8.4;

interface MintableToken {
  function mint(address _to, uint256 _amount) external;
}

contract SummoningPit is Ownable {
  uint256 constant ONE = 1.00E18;

  mapping(address => uint256) public totalHarvestedByProject;
  mapping(address => uint256) public lastHarvested;
  mapping(uint256 => uint256) public manaHarvestedInBlock;
  MintableToken manaToken;
  uint256 public totalHarvested;
  uint256 public maxManaPerBlock;
  uint256 public manaPerCollection;
  uint256 public period;
  bool public isPaused;

  constructor(address tokenAddress, uint256 harvestPeriod) {
    manaPerCollection = ONE;
    maxManaPerBlock = ONE;
    period = harvestPeriod;
    manaToken = MintableToken(tokenAddress);
  }

  modifier isNotPaused() {
    require(!isPaused, "Summoning pit is closed");
    _;
  }

  function _mintMana(address harvester, uint256 amount) internal {
    require(
      lastHarvested[harvester] + period <= block.number,
      "Wait before harvesting more"
    );
    require(
      manaHarvestedInBlock[block.number] + manaPerCollection <= maxManaPerBlock,
      "Mana fully harvested"
    );
    lastHarvested[harvester] = block.number;
    manaHarvestedInBlock[block.number] += manaPerCollection;
    totalHarvested += amount;
    manaToken.mint(harvester, amount);
  }

  function harvest() public isNotPaused {
    _mintMana(msg.sender, manaPerCollection);
  }

  function harvest(address project) public isNotPaused {
    _mintMana(msg.sender, manaPerCollection);
    totalHarvestedByProject[project] += manaPerCollection;
  }

  function nextHarvestBlock(address user)
    public
    view
    isNotPaused
    returns (uint256)
  {
    return
      lastHarvested[user] + period > block.number
        ? lastHarvested[user] + period
        : 0;
  }

  // Admin functions
  function setPause(bool _pause) public onlyOwner {
    isPaused = _pause;
  }

  function setManaPerCollection(uint256 _manaPerCollection) public onlyOwner {
    manaPerCollection = _manaPerCollection;
  }

  function setMaxManaPerBlock(uint256 _maxManaPerBlock) public onlyOwner {
    maxManaPerBlock = _maxManaPerBlock;
  }

  function setPeriod(uint256 _period) public onlyOwner {
    period = _period;
  }
}