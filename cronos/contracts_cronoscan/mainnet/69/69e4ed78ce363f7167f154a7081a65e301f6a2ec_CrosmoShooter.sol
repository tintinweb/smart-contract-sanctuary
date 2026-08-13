/**
 *Submitted for verification at cronoscan.com on 2022-06-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

// File: contracts/3_Ballot.sol



pragma solidity 0.8.13;



interface IERC721 {
  function balanceOf(address) external view returns (uint256);
  function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
  function ownerOf(uint256) external view returns (address);
  function hasSpecificTypePilot(address, uint8) external view returns (bool);
}

contract CrosmoShooter is Ownable {
  
  struct CraftStatus {
    uint256 lastUpdated;
    uint8 tier;
    uint8 damagedLevel;
  }
  
  mapping(uint256 => CraftStatus) public craftStatus;

  uint256[5] public UPGRADE_COST = [1000 ether, 4000 ether, 10000 ether, 24000 ether, 44000 ether];
  uint256 public REPAIRE_COOLDOWN = 10 minutes;

  uint256 public scale = 10 ** 6;

  mapping(address => uint256) public rewardBalance;

  IERC20 public crosmoToken;
  IERC721 public crosmoCraft;
  IERC721 public crosmoStation;
  IERC721 public crosmoPilot;

  constructor(address _crosmoToken, address _crosmoCraft) {
    crosmoToken = IERC20(_crosmoToken);
    crosmoCraft = IERC721(_crosmoCraft);
  }

  function playSession(uint256 score, address player, uint256 craftID) external onlyOwner {
    require(crosmoCraft.ownerOf(craftID) == player, "Can't play with other's craft");
    updateCraftStatus(craftID);
    require(craftStatus[craftID].damagedLevel < 5, "Craft is damaged");
    uint256 reward = score * scale;
    uint256 bonus = reward * 5 / 100;
    bool stationToken = hasCrosmoStation(player);
    if (stationToken == true) {
      reward = reward + bonus;
    }
    if (address(crosmoPilot) != address(0) && crosmoPilot.hasSpecificTypePilot(player, 1) == true) {
      reward = reward + bonus;
    }
    rewardBalance[player] += reward;
    if (stationToken == false) {
      craftStatus[craftID].damagedLevel += 1;
    }
  }

  function upgradeCraft(uint256 craftID) external {
    uint8 tier = craftStatus[craftID].tier;
    // require(CraftToken.ownerOf(craftID) == msg.sender, "Only owner")
    require(tier != 5, "No more tier");
    uint256 upgradeCost = UPGRADE_COST[tier];
    if (address(crosmoPilot) != address(0) && crosmoPilot.hasSpecificTypePilot(msg.sender, 2) == true) {
      upgradeCost = upgradeCost * 95 / 100;
    } 
    require(crosmoToken.balanceOf(msg.sender) >= UPGRADE_COST[tier], "Not enough balance to upgrade");
    crosmoToken.transferFrom(msg.sender, address(this), UPGRADE_COST[tier]);
    craftStatus[craftID].tier = craftStatus[craftID].tier + 1;
  }

  function hasCrosmoStation(address player) public view returns (bool){
    if (address(crosmoStation) != address(0) && crosmoStation.balanceOf(player) > 0)
      return true;
    return false;
  }

  function updateCraftStatus(uint256 craftID) public {
    uint256 currentTime = block.timestamp;
    uint256 elapsedTime = currentTime - craftStatus[craftID].lastUpdated;
    uint256 elapsedEpoch = elapsedTime / REPAIRE_COOLDOWN;
    if (craftStatus[craftID].damagedLevel >= elapsedEpoch)
      craftStatus[craftID].damagedLevel = craftStatus[craftID].damagedLevel - (uint8)(elapsedEpoch);
    else
      craftStatus[craftID].damagedLevel = 0;
    craftStatus[craftID].lastUpdated = currentTime;
  }

  function getCraftStatus(uint256 craftID) public view returns (uint256, uint8, uint8) {
    uint256 currentTime = block.timestamp;
    uint256 elapsedTime = currentTime - craftStatus[craftID].lastUpdated;
    uint256 elapsedEpoch = elapsedTime / REPAIRE_COOLDOWN;
    uint8 damagedLevel = 5;
    if (craftStatus[craftID].damagedLevel >= elapsedEpoch)
      damagedLevel = craftStatus[craftID].damagedLevel - (uint8)(elapsedEpoch);
    else
      damagedLevel = 0;
    return (craftStatus[craftID].lastUpdated, craftStatus[craftID].tier, damagedLevel);
  }

  function getRewardBalance(address _player) public view returns (uint256) {
    return rewardBalance[_player];
  }

  function claimReward() external {
    require(rewardBalance[msg.sender] > 0, "No reward balance to claim");
    uint256 balance = rewardBalance[msg.sender];
    rewardBalance[msg.sender] = 0;
    crosmoToken.transfer(msg.sender, balance);
  }

  function withdrawToken(uint256 amount) external onlyOwner {
    crosmoToken.transfer(msg.sender, amount);
  }

  function setCrosmoStation(address _station) external onlyOwner {
    crosmoStation = IERC721(_station);
  }

  function setCrosmoPilot(address _pilot) external onlyOwner {
    crosmoPilot = IERC721(_pilot);
  }
}