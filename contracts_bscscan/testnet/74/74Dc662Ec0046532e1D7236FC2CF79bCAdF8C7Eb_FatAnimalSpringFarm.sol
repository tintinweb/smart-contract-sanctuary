// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IFatAnimalNFT.sol";
import "./interfaces/IFatAnimalFood.sol";
import "./interfaces/IFatAnimalRewardDistributor.sol";
import "./interfaces/IFatAnimalSaha.sol";

contract FatAnimalSpringFarm is ERC721Holder, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  enum Season {
    None,       // 0
    Spring,     // 1
    Summer,     // 2
    Autumn,     // 3
    Winter      // 4
  }

  uint256 public constant MAX_PLATFORM_FEE = 3000; // 3%;

  IERC20 public immutable fat;
  address public immutable fatNFT;
  address public immutable fatFood;
  address public immutable rewardDistributor;
  address public immutable sahaLogic;

  struct UserInfo {
    uint256 ep;
    uint256 rewardDebt;
    uint256 earned;
    uint256 rewarded;
    uint256 foodBonus;
    uint256 foodExpiration;
    uint256 foodId;
    uint256 lastActive;
    uint256[5][3] slot;
  }

  mapping(address => UserInfo) public userInfo;

  uint256 private totalEp;
  uint256 private accFatPerEp;
  uint256 private lastRewardBlock;
  uint256 private farmId;
  uint256 private season;

  uint256 private _platformFee;
  uint256 private _accPlatformFee;
  address private _collector;

  event LogUpdateFarm(uint256 lastRewardBlock, uint256 totalEP, uint256 accFatPerEp);
  event LogUpdateUser(address indexed user, uint256 reward, uint256 deducted);
  event Harvest(address indexed user, uint256 reward);
  event RemoveAllAnimal(address indexed user);
  event Sync(address indexed user, uint256 prevEP, uint256 currentBaseEP, uint256 currentNetEP);
  event EatFood(address indexed user, uint256 foodId, uint256 duration, uint256 bonus);
  event UpdateAnimal(address indexed user, uint256[5][3] slot);

  event SetFee(uint256 fee);
  event SetCollector(address collector);
  event CollectFee(uint256 platformFee);

  constructor (
    IERC20 _fat,
    address _fatNFT,
    address _fatFood,
    address _rewardDistributor,
    address _sahaLogic,
    address _treasury
  ) {
    fat = _fat;
    fatNFT = _fatNFT;
    fatFood = _fatFood;
    rewardDistributor = _rewardDistributor;
    sahaLogic = _sahaLogic;
    season = uint256(Season.Spring);
    farmId = season - 1;
    _platformFee = 3000;
    _collector = _treasury;
  }

  modifier onlyCollector() {
    require(_msgSender() == _collector, "FatAnimalFarm: not the collector");
    _;
  }

  modifier onlyEOA() {
    require(_msgSender() == tx.origin, "FatAnimalFarm: not EOA");
    _;
  }

  modifier validAddress(address _addr) {
    require(_addr != address(0), "FatAnimalFarm: Invalid address");
    _;
  }

  function _safeFatTransfer(address _to, uint256 _amount) private {
    uint256 fatBal = fat.balanceOf(address(this));
    if (_amount <= fatBal) {
      fat.transfer(_to, _amount);
    }
  }

  function _updatePool() private {
    uint256 _reward;

    if (block.number <= lastRewardBlock) {
      return;
    }
    if (totalEp == 0) {
      lastRewardBlock = block.number;
      return;
    }
    _reward = IFatAnimalRewardDistributor(rewardDistributor).distribute(farmId);
    lastRewardBlock = block.number;
    if (_reward > 0) {
      accFatPerEp = accFatPerEp.add(_reward.mul(1e12).div(totalEp));
    }
    emit LogUpdateFarm(lastRewardBlock, totalEp, accFatPerEp);
  }

  function _stackAnimal(
    uint256[5][3] memory _slot
  )
  private
  pure
  returns (uint256[] memory) {
    uint256[] memory _stack = new uint256[](15);
    uint256 _counter = 0;
    for (uint256 _i = 0; _i < 3; _i++) {
      for (uint256 _j = 0; _j < 5; _j++) {
        _stack[_counter] = _slot[_i][_j];
        _counter += 1;
      }
    }
    return _stack;
  }

  function _difference(
    uint256[] memory _old,
    uint256[] memory _new
  )
  private
  pure
  returns (uint256[] memory)
  {
    require(_old.length <= 15 && _new.length <= 15, "FatAnimalFarm: Invalid length");
    uint256[] memory _outFromOld = new uint256[](15);
    for (uint256 _i = 0; _i < _old.length; _i++) {
      bool _found = false;
      for (uint256 _j = 0; _j < _new.length && !_found; _j++) {
        if (_old[_i] == _new[_j]) {
          _found = true;
        }
      }

      if (!_found) {
        _outFromOld[_i] = _old[_i];
      }
    }
    return _outFromOld;
  }

  function _harvest() internal {
    uint256 _deducted;
    uint256 _foodReward;
    uint256 pending;

    UserInfo storage user = userInfo[_msgSender()];
    _updatePool();

    if (user.ep > 0 || user.foodBonus > 0) {
      pending = user.ep.mul(accFatPerEp).div(1e12).sub(user.rewardDebt);
      _foodReward = pending.mul(user.foodBonus).div(user.ep);
      if (user.foodExpiration < block.number && user.foodBonus > 0) {
        _deducted = _foodReward.mul(block.number.sub(user.foodExpiration)).div(block.number.sub(user.lastActive));
        user.foodBonus = 0;
        user.foodExpiration = 0;
        user.foodId = 0;
        if (pending > _deducted) {
          pending = pending.sub(_deducted);
        }
      }

      if (pending > 0) {
        user.rewarded = user.rewarded.add(pending);
        emit LogUpdateUser(_msgSender(), pending, _deducted);
      }
    }
  }

  function harvest()
  external
  onlyEOA
  nonReentrant
  {
    uint256 _prevEP;
    uint256 _newEP;
    uint256 _baseEP;
    uint256 _pending;

    _harvest();

    UserInfo storage user = userInfo[_msgSender()];
    if (user.rewarded > 0) {
      if (_platformFee > 0) {
        _accPlatformFee = _accPlatformFee.add(user.rewarded.mul(_platformFee).div(1e5));
      }
      _pending = user.rewarded.mul(1e5 - _platformFee).div(1e5);
      _safeFatTransfer(_msgSender(), _pending);
      user.earned = user.earned.add(_pending);
      user.rewarded = 0;
      emit Harvest(_msgSender(), _pending);
    }

    user.lastActive = block.number;
    _prevEP = user.ep;
    (_baseEP, _newEP) = calculateEPByUser(_msgSender());

    user.ep = _newEP;
    user.rewardDebt = user.ep.mul(accFatPerEp).div(1e12);
    totalEp = totalEp.sub(_prevEP).add(_newEP);

    emit Sync(_msgSender(), _prevEP, _baseEP, totalEp);
  }

  function addFood(uint256 _foodId)
  external
  onlyEOA
  nonReentrant
  {
    uint256 _duration;
    uint256 _eatingPower;
    uint256 _prevEP;
    uint256 _newEP;
    uint256 _baseEP;

    require(userInfo[_msgSender()].foodExpiration < block.number, "FatAnimalFarm: Already have food");
    require(_foodId > 0, "FatAnimalFarm: Invalid food Id");
    IFatAnimalFood(fatFood).safeTransferFrom(_msgSender(), address(0x000000000000000000000000000000000000dEaD), _foodId);

    _harvest();

    (_duration, _eatingPower, ) = IFatAnimalFood(fatFood).getFood(_foodId);
    UserInfo storage user = userInfo[_msgSender()];
    user.foodBonus = _eatingPower;
    user.foodExpiration = block.number + _duration;
    user.foodId = _foodId;
    user.lastActive = block.number;

    _prevEP = user.ep;
    (_baseEP, _newEP) = calculateEPByUser(_msgSender());
    user.ep = _newEP;

    user.rewardDebt = user.ep.mul(accFatPerEp).div(1e12);
    totalEp = totalEp.sub(_prevEP).add(_newEP);

    emit Sync(_msgSender(), _prevEP, _baseEP, totalEp);
    emit EatFood(_msgSender(), _foodId, _duration, _eatingPower);
  }

  function addAnimal(uint256[5][3] memory _slot)
  external
  onlyEOA
  nonReentrant
  {
    _harvest();

    UserInfo storage user = userInfo[_msgSender()];
    uint256[] memory _oldStack = _stackAnimal(user.slot);
    uint256[] memory _newStack = _stackAnimal(_slot);
    uint256[] memory _pendingAdd;
    uint256[] memory _pendingRemove;
    uint256 _prevEP;
    uint256 _newEP;
    uint256 _baseEP;

    user.lastActive = block.number;
    user.slot = _slot;
    _pendingRemove = _difference(_oldStack, _newStack);
    _pendingAdd = _difference(_newStack, _oldStack);

    _prevEP = user.ep;
    (_baseEP, _newEP) = calculateEPByUser(_msgSender());

    user.ep = _newEP;
    user.rewardDebt = user.ep.mul(accFatPerEp).div(1e12);
    totalEp = totalEp.sub(_prevEP).add(_newEP);

    for (uint256 _i = 0; _i < 15; _i++) {
      if (_pendingRemove[_i] > 0) {
        IFatAnimalNFT(fatNFT).safeTransferFrom(address(this), _msgSender(), _pendingRemove[_i]);
      }
      if (_pendingAdd[_i] > 0) {
        IFatAnimalNFT(fatNFT).safeTransferFrom(_msgSender(), address(this), _pendingAdd[_i]);
      }
    }

    emit Sync(_msgSender(), _prevEP, _baseEP, totalEp);
    emit UpdateAnimal(_msgSender(), _slot);
  }

  function removeAllAnimal()
  external
  onlyEOA
  nonReentrant
  {
    UserInfo storage user = userInfo[_msgSender()];
    uint256[] memory _stack = _stackAnimal(user.slot);
    uint256 _prevEP;
    uint256 _newEP;
    uint256 _baseEP;

    _harvest();

    delete user.slot;
    user.lastActive = block.number;
    _prevEP = user.ep;
    (_baseEP, _newEP) = calculateEPByUser(_msgSender());

    user.ep = _newEP;
    user.rewardDebt = user.ep.mul(accFatPerEp).div(1e12);
    totalEp = totalEp.sub(_prevEP).add(_newEP);

    for (uint256 _i = 0; _i < 15; _i++) {
      if (_stack[_i] > 0) {
        IFatAnimalNFT(fatNFT).safeTransferFrom(address(this), _msgSender(), _stack[_i]);
      }
    }

    emit Sync(_msgSender(), _prevEP, _baseEP, totalEp);
    emit RemoveAllAnimal(_msgSender());
  }

  function setFee(uint256 _fee)
  external
  onlyOwner
  {
    require(_fee >= 0, "FatAnimalFarm: fee is too low");
    require(_fee <= MAX_PLATFORM_FEE, "FatAnimalFarm: fee is too high");
    _platformFee = _fee;
    emit SetFee(_fee);
  }

  function setCollector(address _feeTo)
  external
  onlyOwner
  validAddress(_feeTo)
  {
    _collector = _feeTo;
    emit SetCollector(_feeTo);
  }

  function collectFee()
  external
  onlyCollector
  {
    _safeFatTransfer(_msgSender(), _accPlatformFee);
    emit CollectFee(_accPlatformFee);

    _accPlatformFee = 0;
  }

  function collector() external view returns (address) {
    return _collector;
  }

  function accPlatformFee() external view returns (uint256) {
    return _accPlatformFee;
  }

  function pendingFat(address _user) external view returns (uint256) {
    uint256 _deducted;
    uint256 _foodReward;
    uint256 _pending;
    uint256 _accFatPerEp = accFatPerEp;
    UserInfo memory user = userInfo[_user];

    if (block.number > lastRewardBlock && totalEp != 0) {
      uint256 fatReward = IFatAnimalRewardDistributor(rewardDistributor).getPending(farmId);
      _accFatPerEp = _accFatPerEp.add(fatReward.mul(1e12).div(totalEp));
    }

    if (user.ep > 0 || user.foodBonus > 0) {
      _pending = user.ep.mul(_accFatPerEp).div(1e12).sub(user.rewardDebt);
      _foodReward = _pending.mul(user.foodBonus).div(user.ep);
      if (user.foodExpiration < block.number && user.foodBonus > 0) {
        _deducted = _foodReward.mul(block.number.sub(user.foodExpiration)).div(block.number.sub(user.lastActive));
        user.foodBonus = 0;
        user.foodExpiration = 0;
        user.foodId = 0;
        if (_pending > _deducted) {
          _pending = _pending.sub(_deducted);
        }
      }
    }

    _pending = _pending.add(user.rewarded);

    return _pending.mul(1e5 - _platformFee).div(1e5);
  }

  function getAccFatPerEp() external view returns (uint256) {
    return accFatPerEp;
  }

  function getCurrentFood(address _user) external view returns (bool, uint256, uint256, uint256){
    bool _isActive;
    uint256 _bonus;
    uint256 _expiration;
    uint256 _id;

    _isActive = userInfo[_user].foodExpiration > block.number;
    _bonus = userInfo[_user].foodBonus;
    _expiration = userInfo[_user].foodExpiration;
    _id = userInfo[_user].foodId;
    return (_isActive, _bonus, _expiration, _id);
  }

  function getCurrentUserEP(address _user) external view returns (uint256) {
    uint256 _foodBonus;
    if (userInfo[_user].foodExpiration > block.number) {
      return userInfo[_user].ep;
    } else {
      if (userInfo[_user].foodBonus > 0) {
        _foodBonus = userInfo[_user].foodBonus;
      }
      return userInfo[_user].ep.sub(_foodBonus);
    }
  }

  function getCurrentUserAnimal(address _user) external view returns (uint256[5][3] memory){
    return userInfo[_user].slot;
  }

  function getFatAllocation() external view returns (uint256) {
    uint256 _currentSeason = IFatAnimalRewardDistributor(rewardDistributor).currentSeason();
    return IFatAnimalRewardDistributor(rewardDistributor).getSeason(_currentSeason, farmId);
  }

  function getTotalEp() external view returns (uint256) {
    return totalEp;
  }

  function calculateEPById(uint256[5][3] memory _animalId, uint256 _foodId) public view returns (uint256, uint256) {
    uint256[5][3] memory _EPDeck;
    uint256[5][3] memory _familyDeck;
    uint256[5][3] memory _elementDeck;
    uint256 _baseEP;
    uint256 _netEP;
    uint256 _element;
    uint256 _family;
    uint256 _eatingPower;

    for (uint256 _i = 0; _i < 3; _i++) {
      for (uint256 _j = 0; _j < 5; _j++) {
        if (_animalId[_i][_j] > 0) {
          (, _element, _family, _eatingPower,) = IFatAnimalNFT(fatNFT).getAnimal(_animalId[_i][_j]);
          _EPDeck[_i][_j] = _eatingPower;
          _familyDeck[_i][_j] = _family + 1;
          _elementDeck[_i][_j] = _element + 1;
        }
      }
    }
    (_baseEP, _netEP) = IFatAnimalSaha(sahaLogic).getUserAnimalEP(_EPDeck, _familyDeck, _elementDeck, season);

    if (_foodId > 0) {
      (, _eatingPower,) = IFatAnimalFood(fatFood).getFood(_foodId);
    } else {
      _eatingPower = 0;
    }
    return (_baseEP, _netEP.add(_eatingPower));
  }

  function calculateEPByUser(address _user) public view returns (uint256, uint256) {
    uint256 _foodId;
    UserInfo memory user = userInfo[_user];
    if (user.foodExpiration > block.number) {
      _foodId = user.foodId;
    }
    return calculateEPById(user.slot, _foodId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFatAnimalFood {
  function generate(address _master, uint256 _duration, uint256 _eatingPower, uint256 _geneId) external;

  function getFood(uint256 _id) external view returns (uint256, uint256, uint256);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFatAnimalNFT {
  function generate(address _master, uint256 _adult, uint256 _element, uint256 _family, uint256 _eatingPower, uint256 _geneId) external;

  function getAnimal(uint256 _geneId) external view returns (uint256, uint256, uint256, uint256, uint256);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFatAnimalRewardDistributor {
  function distribute(uint256 _id) external returns (uint256);

  function currentSeason() external view returns (uint256);

  function getFarm(uint256 _id) external view returns (address);

  function getPending(uint256 _id) external view returns (uint256);

  function getSeason(uint256 _currentSeason, uint256 _season) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFatAnimalSaha {
  function getUserAnimalEP(
    uint256[5][3] memory _baseEP,
    uint256[5][3] memory _family,
    uint256[5][3] memory _element,
    uint256 _season
  ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}