// SPDX-License-Identifier: UNLICENSED
// Author: The Defi Network
// Copyright 2021

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IPresaleFactory.sol";
import "./Presale.sol";

/**
  @dev The PresaleFactory Smart contract forms the basis of a tiered launchpad
  and allows launch of multiple presales while making sure presalers are have
  staked their tokens for an appropriate amount of time
 */
contract PresaleFactory is IPresaleFactory, Ownable {
  using SafeMath for uint256;
  
  //
  // GLOBAL VARS
  //

  // The native token of the Launchpad
  address public override nativeToken;
  // The address stablecoin in which presales are conducted
  address public override stablecoinAddress;
  // Total presales
  uint256 public override presaleTotal = 0;
  // Minimum blocks needed to stake
  uint256 public override minBlocksStaked;
  
  // Staking tiers
  // Diamond Tier = 50000 Tokens
  uint256 public override tierDiamond = 50000 ether;
  // Platinum Tier = 25000 Tokens
  uint256 public override tierPlatinum = 25000 ether;
  // Gold Tier = 15000 Tokens
  uint256 public override tierGold = 15000 ether;
  // Silver Tier = 5000 Tokens
  uint256 public override tierSilver = 5000 ether;
  // Bronze Tier = 2000 Tokens
  uint256 public override tierBronze = 2000 ether;
  
  //
  // MAPPINGS
  //

  /**
   * @notice Map of an id to a presale address
  */
  mapping(uint256 => address) public override presaleMap; 

  /**
   * @notice Map of staker to amount staked block
  */
  mapping(address => uint256) public override stakedBlock;

  /**
   * @notice Map of staker to amount staked block
  */
  mapping(address => uint256) public override stakedAmount;

  //
  // FUNCTIONS
  //

  /**
   * @notice Initialize the factory contract with the native token
   * @param _stablecoinAddress The address of then stablecoin
   * @param _nativeToken The address of then native token
   * @param _minBlocksStaked The address of then native token
   */
  constructor(
    address _stablecoinAddress, 
    address _nativeToken, 
    uint256 _minBlocksStaked
  ) {
    nativeToken = _nativeToken;
    minBlocksStaked = _minBlocksStaked;
    stablecoinAddress = _stablecoinAddress;
  }


  /**
   * @notice Creates and initializes a Presale contract
   * @param _projectOwner Address owning the project
   * @param _tokenAddress The token getting pre-sold
   * @param _tokenAmount The amount of tokens getting pre-sold
   * @param _price The price per ETH at presale
   * @param _startBlock The starting block of the presale
   * @param _endBlock The ending block of the presale
   * @param _softCap The soft cap the project intends to hit
   * @param _hardCap The hard cap the project intends to hit
   * @param _allocation The amount of stablecoin that could be used to buy in
   * @return uint256 The id of the presale
   * @return uint256 The address of the presale
   */
  function createPresale(
    address _projectOwner, address _tokenAddress, uint256 _tokenAmount,
    uint256 _price, uint256 _startBlock, uint256 _endBlock, 
    uint256 _softCap, uint256 _hardCap, uint256 _allocation
  ) override external onlyOwner returns (uint256, address) {
    // Checking if start block is lesser than end block
    require(_startBlock < _endBlock, 
      "PresaleFactory::createPresale: Start block can't exceed end block");
    // Checking if soft cap block is lesser than hard cap
    require(_softCap <= _hardCap, 
      "PresaleFactory::createPresale: Soft cap can't exceed hard cap");
    // Checking if min buy is less than all tier's max buys

    uint256 tokenAmount = _tokenAmount;

    // Check if smart contract has permission to transfer presale tokens
    require(IERC20(_tokenAddress).allowance(_msgSender(), address(this)) >=
      tokenAmount, "PresaleFactory::stake: Allowance amount low");

    // Deploying presale
    Presale presale = new Presale(
      stablecoinAddress, _projectOwner, _tokenAddress, tokenAmount, _price, 
      _startBlock, _endBlock, _softCap, _hardCap, _allocation
    );

    uint256 presaleId = presaleTotal;
    address presaleAddress = address(presale);

    // Transfer presale tokens from owner to presale address
    IERC20(_tokenAddress).transferFrom(
      _msgSender(), presaleAddress, tokenAmount
    );

    // Adding presale to map
    presaleMap[presaleId] = presaleAddress;
    // Incrementing total number of presales created
    presaleTotal = presaleTotal.add(1);
    // Emitting event of presale acreation    
    emit PresaleCreated(presaleId, presaleAddress);

    // Returning the presale id and address
    return (presaleId, presaleAddress);
  }

  /**
   * @notice Allows staking of the native token
   * @param _stakeAmount The amount of tokens needed to be staked   
   * @return uint256 Returns the total amount still staked
   */
  function stake(uint256 _stakeAmount) external override returns (uint256) {
    // Check if smart contract has permission to transfer native tokens
    require(IERC20(nativeToken).allowance(_msgSender(), address(this)) >=
      _stakeAmount, "PresaleFactory::stake: Allowance amount low");
    
    // Adding stake amount to map
    stakedAmount[_msgSender()] = stakedAmount[_msgSender()].add(_stakeAmount);
    // Transferring the token to the contract
    IERC20(nativeToken).transferFrom(_msgSender(), address(this), _stakeAmount);
    // Set last stake block to current block
    stakedBlock[_msgSender()] = block.number;
    // Emitting event that user has staked
    emit Staked(_msgSender(), _stakeAmount);

    // Returning the total amount still staked
    return stakedAmount[_msgSender()];
  }

  /**
   * @notice Allows unstaking of the staked native token
   * @param _unstakeAmount The amount of tokens needed to be unstaked
   * @return uint256 Returns the total amount still staked
   */
  function unstake(uint256 _unstakeAmount) external override returns (uint256) {
    // Adding stake amount to map
    stakedAmount[_msgSender()] = stakedAmount[_msgSender()].sub(_unstakeAmount);
    // Transferring the token to the contract
    IERC20(nativeToken).transfer(_msgSender(), _unstakeAmount);
    // Set last stake block to current block
    stakedBlock[_msgSender()] = block.number;
    // Emitting event that user has unstaked
    emit Unstaked(_msgSender(), _unstakeAmount);

    // Returning the total amount still staked
    return stakedAmount[_msgSender()];
  }

  /**
   * @notice Changes the amount of blocks needed to be staked by the users
   * @param _minBlocksStaked The minimum blocks needed to stake
   */
  function setMinBlocksStaked(uint256 _minBlocksStaked) 
  external override onlyOwner {
    minBlocksStaked = _minBlocksStaked;
  }

  /**
   * @notice Disable minimum amount of XPad needed staked for presale
   */
  function disableTiers() external override onlyOwner {
    tierBronze = 0 ether;
    tierSilver = 0 ether;
    tierGold = 0 ether;
    tierPlatinum = 0 ether;
    tierDiamond = 0 ether;
  }

  /**
   * @notice Enable minimum amount of XPad needed staked for presale
   */
  function enableTiers() external override onlyOwner {
    tierBronze = 2000 ether;
    tierSilver = 5000 ether;
    tierGold = 15000 ether;
    tierPlatinum = 25000 ether;
    tierDiamond = 50000 ether;
  }

  /**
   * @notice Withdraw the funds from a particular presale
   * @param _id The presale
   */
  function withdrawPresaleFunds(uint256 _id) external override onlyOwner {
    IPresale(presaleMap[_id]).withdrawFunds(payable(owner()));
  }

  /**
   * @notice Withdraw the unsold tokens from a particular presale
   * @param _id The presale
   */
  function withdrawUnsoldTokens(uint256 _id) external override onlyOwner {
    IPresale(presaleMap[_id]).withdrawUnsoldTokens(owner());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Author: The Defi Network
// Copyright 2021

pragma solidity ^0.8.4;

/**
  @dev The IPresaleFactory interface includes all the functions for the 
  PresaleFactory smart contract, and can be used by contract makers to freely
  interact with any iteration of the PresaleFactory Smart Contract
 */
interface IPresaleFactory {
  //
  // FUNCTIONS
  //

  /**
   * @notice Creates and initializes a Presale contract
   * @param _projectOwner Address owning the project
   * @param _tokenAddress The token getting pre-sold
   * @param _tokenAmount The amount of tokens getting pre-sold
   * @param _price The price per stablecoin at presale
   * @param _startBlock The starting block of the presale
   * @param _endBlock The ending block of the presale
   * @param _softCap The soft cap the project intends to hit
   * @param _hardCap The hard cap the project intends to hit
   * @param _allocation The amount that could be used to buy in
   * @return uint256 The id of the presale
   * @return uint256 The address of the presale
   */
  function createPresale(
    address _projectOwner,
    address _tokenAddress,
    uint256 _tokenAmount,
    uint256 _price,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _softCap,
    uint256 _hardCap,
    uint256 _allocation
  ) external returns (uint256, address);

  /**
   * @notice Allows staking of the native token
   * @param _stakeAmount The amount of tokens needed to be staked   
   * @return uint256 Returns the total amount still staked
   */
  function stake(uint256 _stakeAmount) external returns (uint256);

  /**
   * @notice Allows unstaking of the staked native token
   * @param _unstakeAmount The amount of tokens needed to be unstaked
   * @return uint256 Returns the total amount still staked
   */
  function unstake(uint256 _unstakeAmount) external returns (uint256);

  /**
   * @notice Changes the amount of blocks needed to be staked by the users
   * @param _minBlocksStaked The minimum blocks needed to stake
   */
  function setMinBlocksStaked(uint256 _minBlocksStaked) external;

  /**
   * @notice Withdraw the funds from a particular presale
   * @param _id The presale
   */
  function withdrawPresaleFunds(uint256 _id) external;

  /**
   * @notice Withdraw the unsold tokens from a particular presale
   * @param _id The presale
   */
  function withdrawUnsoldTokens(uint256 _id) external;

  /**
   * @notice Disable minimum amount of XPad needed staked for presale
   */
  function disableTiers() external;

  /**
   * @notice Enable minimum amount of XPad needed staked for presale
   */
  function enableTiers() external;

  //
  // VIEW FUNCTIONS
  //

  /**
   * @notice Returns the presale address based on the id
   * @param _id The id of the presale
   * @return address The address of the presale
   */
  function presaleMap(uint256 _id) external view returns (address);

  /**
   * @notice The total number of presales created
   * @param _staker The address of the staker
   * @return uint256 The block when the staker staked
   */
  function stakedBlock(address _staker) external view returns (uint256);

  /**
   * @notice The total number of presales created
   * @param _staker The address of the staker
   * @return uint256 The amount the staker
   */
  function stakedAmount(address _staker) external view returns (uint256);

  /**
   * @notice The total number of presales created
   * @return uint256 The address of the presale
   */
  function presaleTotal() external view returns (uint256);

  /**
   * @notice The address of the native token
   * @return adress The address of the native token
   */
  function nativeToken() external view returns (address);

  /**
   * @notice The address of the stablecoin in which presale is conducted
   * @return adress The address of stablecoin
   */
  function stablecoinAddress() external view returns (address);
  
  /**
   * @notice The minimum number of blocks needed to be staked to be in a tier
   * @return uint256 The number of blocks
   */
  function minBlocksStaked() external view returns (uint256);

  /**
   * @notice The total number of tokens required to be staked to be in Diamond
   * Tier 
   * @return uint256 The number of tokens
   */
  function tierDiamond() external view returns (uint256);

  /**
   * @notice The total number of tokens required to be staked to be in Platinum
   * Tier
   * @return uint256 The number of tokens
   */
  function tierPlatinum() external view returns (uint256);

  /**
   * @notice The total number of tokens required to be staked to be in tier Gold
   * Tier
   * @return uint256 The number of tokens
   */
  function tierGold() external view returns (uint256);
  
  /**
   * @notice The total number of tokens required to be staked to be in Silver
   * Tier
   * @return uint256 The number of tokens
   */
  function tierSilver() external view returns (uint256);

    /**
   * @notice The total number of tokens required to be staked to be in Bronze
   * Tier
   * @return uint256 The number of tokens
   */
  function tierBronze() external view returns (uint256);

  //
  // EVENTS
  //

  /**
   * @notice Emitted on presale creation
   * @param _id Id of the presale
   * @param _presaleAddress Address of the presale
   */
  event PresaleCreated(uint256 _id, address _presaleAddress);
 
  /**
   * @notice Emitted on staking
   * @param _staker The address of the staker
   * @param _stakedAmount The amount staked
   */
  event Staked(address _staker, uint256 _stakedAmount);
  
  /**
   * @notice Emitted on unstaking
   * @param _unstaker The address of the unstaker
   * @param _unstakedAmount The amount unstaked
   */
  event Unstaked(address _unstaker, uint256 _unstakedAmount);
}

// SPDX-License-Identifier: UNLICENSED
// Author: The Defi Network
// Copyright 2021

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IPresale.sol";
import "./IPresaleFactory.sol";

contract Presale is IPresale, Ownable {
  using SafeMath for uint256;

  //
  // GLOBAL VARS
  //
  
  // Address owning the project
  address public override projectOwner;
  // The token getting pre-sold
  address public override tokenAddress;
  // The amount of tokens getting pre-sold
  uint256 public override tokenAmount;
  // The price per Stablecoin at presale
  uint256 public override price;
  // The starting block of the presale
  uint256 public override startBlock;
  // The ending block of the presale
  uint256 public override endBlock;
  // The softcap the project intends to hit
  uint256 public override softCap;
  // The hard cap the project intends to hit
  uint256 public override hardCap;
  // The minimum amount that could be used to buy in
  uint256 public override allocation;

  // The factory
  IPresaleFactory public factory;
  // The stablecoin
  IERC20 public stablecoin;


  // 
  // MAPPINGS
  //

  /**
   * @notice Mapping for tokens bought by the address
   */
  mapping(address => uint256) public override tokensBought;

  /**
   * @notice Mapping for address if it has claimed or not
   */
  mapping(address => bool) public override hasClaimed;

  /**
   * @notice Mapping for a tier to the token allocation it has
   */
  mapping(Tier => uint256) public override tierAllocation;

  /**
   * @notice Mapping a tier to the max buy per address
   */
  mapping(Tier => uint256) public override tierWalletAllocation;


  //
  // FUNCTIONS
  //

  /**
   * @notice Initialize a Presale contract
   * @param _projectOwner Address owning the project
   * @param _tokenAddress The token getting pre-sold
   * @param _tokenAmount The amount of tokens getting pre-sold
   * @param _price The price per Stablecoin at presale
   * @param _startBlock The starting block of the presale
   * @param _endBlock The ending block of the presale
   * @param _softCap The soft cap the project intends to hit
   * @param _hardCap The hard cap the project intends to hit
   * @param _allocation The amount that could be used to buy in
   */
  constructor(
    address _stableCoinAddress, address _projectOwner, address _tokenAddress, 
    uint256 _tokenAmount, uint256 _price, uint256 _startBlock, 
    uint256 _endBlock, uint256 _softCap, uint256 _hardCap, uint256 _allocation 
  ) {
    // Initalize presale variables
    projectOwner = _projectOwner;
    tokenAddress = _tokenAddress;
    tokenAmount = _tokenAmount;
    price = _price;
    startBlock = _startBlock;
    endBlock = _endBlock;
    softCap = _softCap;
    hardCap = _hardCap;
    allocation = _allocation;

    factory = IPresaleFactory(owner());
    stablecoin = IERC20(_stableCoinAddress);

    // Set tier allocations
    _setTierAllocations();
    _setTierWalletAllocations();
  }
  
  /**
   * @notice Allows a user to participate in the presale and buy the token
   * @param _tokenAmount The amount of tokens the user wants to buy
   */
  function buy(uint256 _tokenAmount) external override payable {
    // Check if presale has began
    require(block.number >= startBlock, "Presale::buy: Presale hasn't started");
    // Check if presale has ended
    require(block.number < endBlock, "Presale::buy: Presale has ended");

    // Will hardcap be hit on this purchase
    require(stablecoin.balanceOf(address(this))
      .add(_tokenAmount.mul(price)) < hardCap, 
      "Presale::buy: Hardcap has been hit"
    );

    // Transferring stablecoin from user's wallet
    stablecoin.transferFrom(
      _msgSender(), address(this), _tokenAmount.mul(price)
    );

    // Check the user's tier
    Tier userTier = _determineTier(_msgSender());
    require(tierAllocation[userTier] >= _tokenAmount, 
      "Presale::buy: The allocation for the tier has been exhausted");

    // Add to the tokens bought by the user
    tokensBought[_msgSender()] = tokensBought[_msgSender()].add(_tokenAmount);
    // Remove tokens from the user's tier
    tierAllocation[userTier] = tierAllocation[userTier].sub(_tokenAmount);

    // Check if token amount is same as tiered wallet allocation
    require(tokensBought[_msgSender()] == tierWalletAllocation[userTier]
      .mul(price), 
      "Presale::buy: Tokens bought should be same as wallet allocation");
  }

  /**
   * @notice Allows a user to claim tokens after presale if the softcap was hit
   */
  function claimTokens() external override {
    require(block.number > endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(stablecoin.balanceOf(address(this)) >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(hasClaimed[_msgSender()] , 
      "Presale::claimTokens: Address has already claimed tokens");
    
    // Transfer the tokens bought
    IERC20(tokenAddress).transfer(_msgSender(), tokensBought[_msgSender()]);
    // User has now claimed
    hasClaimed[_msgSender()] = true;
  }

  /**
   * @notice Allows a user to claim ETH after presale if the softcap wasn't hit
   */
  function claimStable() external override {
    require(block.number >= endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(stablecoin.balanceOf(address(this)) < softCap, 
      "Presale::claimStable: Soft cap was hit");
    require(hasClaimed[_msgSender()] , 
      "Presale::claimStable: Address has already claimed stable");

    // Transfer the Stablecoin sent
    stablecoin.transfer(_msgSender(), tokensBought[_msgSender()].mul(price));
    // User has now claimed
    hasClaimed[_msgSender()] = true;
  }

  /**
   * @notice Function to withdraw funds to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawFunds(address _payee) external override onlyOwner {
    require(block.number >= endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(stablecoin.balanceOf(address(this)) >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(stablecoin.balanceOf(address(this)) > 0, 
      "Presale::withdrawFunds: No Stablecoin in contract");
    
    stablecoin.transfer(_payee, tokensBought[_msgSender()].mul(price));  
  }

  /**
   * @notice Function to withdraw unsold tokens to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawUnsoldTokens(address _payee) external override onlyOwner {
    require(block.number >= endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(stablecoin.balanceOf(address(this)) >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(stablecoin.balanceOf(address(this)) > 0, 
      "Presale::withdrawFunds: No Stablecoin in contract");
    
    IERC20(tokenAddress).transfer(
      _payee, IERC20(tokenAddress).balanceOf(address(this)));
  }

  //
  // INTERNAL FUNCTIONS
  //

  /**
   * @notice Sets the tier allocation in the constructor
   */
  function _setTierAllocations() internal {
    tierAllocation[Tier.BRONZE] = tokenAmount.mul(5).div(100);
    tierAllocation[Tier.SILVER] = tokenAmount.mul(10).div(100);
    tierAllocation[Tier.GOLD] = tokenAmount.mul(15).div(100);
    tierAllocation[Tier.PLATINUM] = tokenAmount.mul(20).div(100);
    tierAllocation[Tier.DIAMOND] = tokenAmount.mul(50).div(100);
    tierAllocation[Tier.NONE] = 0;
  }

  /**
   * @notice Sets the tier max buy per address in the constructor
   */
  function _setTierWalletAllocations() internal {
    tierWalletAllocation[Tier.BRONZE] = allocation;
    tierWalletAllocation[Tier.SILVER] = allocation.mul(2);
    tierWalletAllocation[Tier.GOLD] = allocation.mul(3);
    tierWalletAllocation[Tier.PLATINUM] = allocation.mul(45).div(10);
    tierWalletAllocation[Tier.DIAMOND] = allocation.mul(9);
    tierWalletAllocation[Tier.NONE] = 0;
  }


  /**
   * @notice Determines the tier of a user based on the amount staked and 
   * block they staked/unstaked at
   * @param _staker The user who's tier needs to be determined
   */
  function _determineTier(address _staker) internal view returns(Tier) {
    // Need to stake for atleast 1500 blocks for belonging in Tier
    if (factory.stakedBlock(_staker)
      .add(factory.minBlocksStaked()) > startBlock) {
      return Tier.NONE;
    }

    // Return tiers based on amount staked
    if (factory.stakedAmount(_staker) >= factory.tierDiamond()) {
      return Tier.DIAMOND;
    } else if (factory.stakedAmount(_staker) >= factory.tierPlatinum()) {
      return Tier.PLATINUM;
    } else if (factory.stakedAmount(_staker) >= factory.tierGold()) {
      return Tier.GOLD;
    } else if (factory.stakedAmount(_staker) >= factory.tierSilver()) {
      return Tier.SILVER;
    } else if (factory.stakedAmount(_staker) >= factory.tierBronze()) {
      return Tier.BRONZE;
    } else {
      return Tier.NONE;
    }
  }  

  receive() payable external {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Author: The Defi Network
// Copyright 2021

pragma solidity ^0.8.4;

interface IPresale {
  //
  // ENUMS
  //

  /**
   * @notice Tiering system for presale
   */
  enum Tier {
    DIAMOND,
    PLATINUM,
    GOLD,
    SILVER,
    BRONZE,
    NONE
  }

  //
  // VIEW FUNCTIONS
  //

  /**
   * @notice The address owning the project being presold
   * @return address The project owner address
   */
  function projectOwner() external view returns (address);

  /**
   * @notice The address owning the project being presold
   * @return address The project owner address
   */
  function tokenAddress() external view returns (address);

  /**
   * @notice The amount of tokens to be pre-sold
   * @return uint256 The amount of tokens
   */
  function tokenAmount() external view returns (uint256);

  /**
   * @notice The price of tokens per Stablecoin
   * @return uint256 The token price
   */
  function price() external view returns (uint256);

  /**
   * @notice The block when the presale begins
   * @return uint256 The block number
   */
  function startBlock() external view returns (uint256);

  /**
   * @notice The block when the presale ends
   * @return uint256 The block number
   */
  function endBlock() external view returns (uint256);

  /**
   * @notice The soft cap the project intends to hit
   * @return uint256 The amount in ETH
   */
  function softCap() external view returns (uint256);

  /**
   * @notice The hard cap the project intends to hit
   * @return uint256 The amount in ETH
   */
  function hardCap() external view returns (uint256);

  /**
   * @notice The amount of stablecoin that could be used to buy in
   * @return uint256 The amount in ETH
   */
  function allocation() external view returns (uint256);

  /**
   * @notice Returns the number of tokens bought by a wallet
   * @param _wallet The wallet address
   * @return uint256 Number of tokens
   */
  function tokensBought(address _wallet) external view returns (uint256);

  /**
   * @notice Returns the if address has claimed or not
   * @param _wallet The wallet address
   * @return bool Has wallet claimed?
   */
  function hasClaimed(address _wallet) external view returns (bool);

  /**
   * @notice Returns the number of tokens in allocation for a tier
   * @param _tier The user's tier
   * @return uint256 Number of tokens
   */
  function tierAllocation(Tier _tier) external view returns (uint256);

  /**
   * @notice Returns the maximum amount that can be put in per tier
   * @param _tier The user's tier
   * @return uint256 Total monetary value in stablecoin
   */
  function tierWalletAllocation(Tier _tier) external view returns (uint256);

  //
  // FUNCTIONS
  //

  /**
   * @notice Allows a user to participate in the presale and buy the token
   * @param _tokenAmount The amount of tokens the user wants to buy
   */
  function buy(uint256 _tokenAmount) external payable;

  /**
   * @notice Allows a user to claim tokens after presale if the softcap was hit
   */
  function claimTokens() external;

  /**
   * @notice Allows a user to claim ETH if the softcap wasn't hit
   */
  function claimStable() external;

  /**
   * @notice Function to withdraw funds to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawFunds(address _payee) external;

  /**
   * @notice Function to withdraw unsold tokens to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawUnsoldTokens(address _payee) external;

}

