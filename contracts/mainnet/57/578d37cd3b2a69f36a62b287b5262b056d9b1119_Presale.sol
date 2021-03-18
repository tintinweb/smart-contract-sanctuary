// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {
  AggregatorV3Interface
} from '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

contract Presale is Ownable {
  using SafeMath for uint256;

  // ERC20 tokens
  IERC20 public dpx;

  // Structure of each vest
  struct Vest {
    uint256 amount; // the amount of DPX the beneficiary will recieve
    uint256 released; // the amount of DPX released to the beneficiary
    bool ethTransferred; // whether the beneficiary has transferred the eth into the contract
  }

  // The mapping of vested beneficiary (beneficiary address => Vest)
  mapping(address => Vest) public vestedBeneficiaries;

  // beneficiary => eth deposited
  mapping(address => uint256) public ethDeposits;

  // Array of beneficiaries
  address[] public beneficiaries;

  // No. of beneficiaries
  uint256 public noOfBeneficiaries;

  // Whether the contract has been bootstrapped with the DPX
  bool public bootstrapped;

  // Start time of the the vesting
  uint256 public startTime;

  // The duration of the vesting
  uint256 public duration;

  // Price of each DPX token in usd (1e8 precision)
  uint256 public dpxPrice;

  // ETH/USD chainlink price aggregator
  AggregatorV3Interface internal priceFeed;

  constructor(address _priceFeedAddress, uint256 _dpxPrice) {
    require(_priceFeedAddress != address(0), 'Price feed address cannot be 0');
    require(_dpxPrice > 0, 'DPX price has to be higher than 0');
    priceFeed = AggregatorV3Interface(_priceFeedAddress);
    dpxPrice = _dpxPrice;

    addBeneficiary(0x0330414bBF9491445c102A2a8a14adB9b6a25384, uint256(5000).mul(1e18));

    addBeneficiary(0x5FB8b9512684d451D4E585A1a0AabFB48A253C67, uint256(1000).mul(1e18));

    addBeneficiary(0x9846338e0726d317280346c5003Db365745433D7, uint256(1200).mul(1e18));

    addBeneficiary(0x2d9Bd03312814a34E6706bC81A3593788716d16a, uint256(500).mul(1e18));

    addBeneficiary(0x9c5083dd4838E120Dbeac44C052179692Aa5dAC5, uint256(10000).mul(1e18));

    addBeneficiary(0x0E6Aa54f683dFFC3D6BDb4057Bdb47cBc18975E7, uint256(10000).mul(1e18));

    addBeneficiary(0x3E46bb5a8A10c9CA522df0b25036930cb45b0fb3, uint256(6000).mul(1e18));

    addBeneficiary(0xE5442814c0d31bF9f67676B72838C0E64E9c7B4e, uint256(240).mul(1e18));
  }

  /*---- EXTERNAL FUNCTIONS FOR OWNER ----*/

  /**
   * @notice Bootstraps the presale contract
   * @param _startTime the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _dpxAddress address of dpx erc20 token
   */
  function bootstrap(
    uint256 _startTime,
    uint256 _duration,
    address _dpxAddress
  ) external onlyOwner returns (bool) {
    require(_dpxAddress != address(0), 'DPX address is 0');
    require(_duration > 0, 'Duration passed cannot be 0');
    require(_startTime > block.timestamp, 'Start time cannot be before current time');

    startTime = _startTime;
    duration = _duration;
    dpx = IERC20(_dpxAddress);

    uint256 totalDPXRequired;

    for (uint256 i = 0; i < beneficiaries.length; i = i + 1) {
      totalDPXRequired = totalDPXRequired.add(vestedBeneficiaries[beneficiaries[i]].amount);
    }

    require(totalDPXRequired > 0, 'Total DPX required cannot be 0');

    dpx.transferFrom(msg.sender, address(this), totalDPXRequired);

    bootstrapped = true;

    emit Bootstrap(totalDPXRequired);

    return bootstrapped;
  }

  /**
   * @notice Adds a beneficiary to the contract. Only owner can call this.
   * @param _beneficiary the address of the beneficiary
   * @param _amount amount of DPX to be vested for the beneficiary
   */
  function addBeneficiary(address _beneficiary, uint256 _amount) public onlyOwner returns (bool) {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');
    require(_amount > 0, 'Amount should be larger than 0');
    require(!bootstrapped, 'Cannot add beneficiary as contract has been bootstrapped');
    require(vestedBeneficiaries[_beneficiary].amount == 0, 'Cannot add the same beneficiary again');

    beneficiaries.push(_beneficiary);

    vestedBeneficiaries[_beneficiary].amount = _amount;

    noOfBeneficiaries = noOfBeneficiaries.add(1);

    emit AddBeneficiary(_beneficiary, _amount);

    return true;
  }

  /**
   * @notice Updates beneficiary amount. Only owner can call this.
   * @param _beneficiary the address of the beneficiary
   * @param _amount amount of DPX to be vested for the beneficiary
   */
  function updateBeneficiary(address _beneficiary, uint256 _amount) external onlyOwner {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');
    require(!bootstrapped, 'Cannot update beneficiary as contract has been bootstrapped');
    require(
      vestedBeneficiaries[_beneficiary].amount != _amount,
      'New amount cannot be the same as old amount'
    );
    require(
      !vestedBeneficiaries[_beneficiary].ethTransferred,
      'Beneficiary should have not transferred ETH'
    );
    require(_amount > 0, 'Amount cannot be smaller or equal to 0');
    require(vestedBeneficiaries[_beneficiary].amount != 0, 'Beneficiary has not been added');

    vestedBeneficiaries[_beneficiary].amount = _amount;

    emit UpdateBeneficiary(_beneficiary, _amount);
  }

  /**
   * @notice Removes a beneficiary from the contract. Only owner can call this.
   * @param _beneficiary the address of the beneficiary
   * @return whether beneficiary was deleted
   */
  function removeBeneficiary(address payable _beneficiary) external onlyOwner returns (bool) {
    require(_beneficiary != address(0), 'Beneficiary cannot be a 0 address');
    require(!bootstrapped, 'Cannot remove beneficiary as contract has been bootstrapped');
    if (vestedBeneficiaries[_beneficiary].ethTransferred) {
      _beneficiary.transfer(ethDeposits[_beneficiary]);
    }
    for (uint256 i = 0; i < beneficiaries.length; i = i + 1) {
      if (beneficiaries[i] == _beneficiary) {
        noOfBeneficiaries = noOfBeneficiaries.sub(1);

        delete beneficiaries[i];
        delete vestedBeneficiaries[_beneficiary];

        emit RemoveBeneficiary(_beneficiary);

        return true;
      }
    }
    return false;
  }

  /**
   * @notice Withdraws eth deposited into the contract. Only owner can call this.
   */
  function withdraw() external onlyOwner {
    uint256 ethBalance = payable(address(this)).balance;

    payable(msg.sender).transfer(ethBalance);

    emit WithdrawEth(ethBalance);
  }

  /*---- EXTERNAL FUNCTIONS ----*/

  /**
   * @notice Transfers eth from beneficiary to the contract.
   */
  function transferEth() external payable returns (uint256 ethAmount) {
    require(
      !vestedBeneficiaries[msg.sender].ethTransferred,
      'Beneficiary has already transferred ETH'
    );
    require(vestedBeneficiaries[msg.sender].amount > 0, 'Sender is not a beneficiary');

    uint256 ethPrice = getLatestPrice();

    ethAmount = vestedBeneficiaries[msg.sender].amount.mul(dpxPrice).div(ethPrice);

    require(msg.value >= ethAmount, 'Incorrect ETH amount sent');

    if (msg.value > ethAmount) {
      payable(msg.sender).transfer(msg.value.sub(ethAmount));
    }

    ethDeposits[msg.sender] = ethAmount;

    vestedBeneficiaries[msg.sender].ethTransferred = true;

    emit TransferredEth(msg.sender, ethAmount, ethPrice);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() external returns (uint256 unreleased) {
    require(bootstrapped, 'Contract has not been bootstrapped');
    require(vestedBeneficiaries[msg.sender].ethTransferred, 'Beneficiary has not transferred eth');
    unreleased = releasableAmount(msg.sender);

    require(unreleased > 0, 'No releasable amount');

    vestedBeneficiaries[msg.sender].released = vestedBeneficiaries[msg.sender].released.add(
      unreleased
    );

    dpx.transfer(msg.sender, unreleased);

    emit TokensReleased(msg.sender, unreleased);
  }

  /*---- VIEWS ----*/

  /**
   * @notice Calculates the amount that has already vested but hasn't been released yet.
   * @param beneficiary address of the beneficiary
   */
  function releasableAmount(address beneficiary) public view returns (uint256) {
    return vestedAmount(beneficiary).sub(vestedBeneficiaries[beneficiary].released);
  }

  /**
   * @notice Calculates the amount that has already vested.
   * @param beneficiary address of the beneficiary
   */
  function vestedAmount(address beneficiary) public view returns (uint256) {
    uint256 totalBalance = vestedBeneficiaries[beneficiary].amount;

    if (block.timestamp < startTime) {
      return 0;
    } else if (block.timestamp >= startTime.add(duration)) {
      return totalBalance;
    } else {
      uint256 halfTotalBalance = totalBalance.div(2);
      return
        halfTotalBalance.mul(block.timestamp.sub(startTime)).div(duration).add(halfTotalBalance);
    }
  }

  /**
   * @notice Returns the latest price for ETH/USD
   */
  function getLatestPrice() public view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price);
  }

  /*---- EVENTS ----*/

  event TokensReleased(address beneficiary, uint256 amount);

  event AddBeneficiary(address beneficiary, uint256 amount);

  event RemoveBeneficiary(address beneficiary);

  event UpdateBeneficiary(address beneficiary, uint256 amount);

  event TransferredEth(address beneficiary, uint256 ethAmount, uint256 ethPrice);

  event WithdrawEth(uint256 amount);

  event Bootstrap(uint256 totalDPXRequired);
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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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