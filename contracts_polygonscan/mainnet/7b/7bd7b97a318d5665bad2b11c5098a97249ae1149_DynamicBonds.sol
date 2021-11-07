//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Extended.sol";

import "./interfaces/IERC20Extended.sol";
import "./utils/AddressHelper.sol";

/// @title DynamicBonds
contract DynamicBonds is OwnableUpgradeable, PausableUpgradeable {
  using SafeMathUpgradeable for uint256;
  using AddressHelper for address;

  event SetBondTerms(uint256 payoutAvailable, uint256 expiryTimestamp);
  event UpdateBondOption(uint256 index, BondOption bondOption);
  event UpdateBondOptions(uint256[] index, BondOption[] bondOption);
  event AddBondOptions(BondOption[] bondOptions);
  event Deposit(address indexed user, uint256 bondId, uint256 payoutAmount, BondOption bondOption);
  event Claim(address indexed user, uint256 bondId);

  struct BondOption {
    uint256 price; // payout token sell prices in 18 decimals.
    uint256 lockPeriod; // payout token lock period in seconds.
  }
  struct BondTerms {
    // the sale settings
    uint256 payoutAvailable; // amount of payout available to sell for the sale period
    uint256 expiryTimestamp; // when the sale period expires
    BondOption[] bondOptions; // payout sell options. e.g. 0: price for 1 week lockup, 1: price for 1 month lockup, 2: price for 6 months lockup, 3: price for 1 year lockup
  }
  struct Bond {
    // an instance of a bond that’s been issued to a user
    address bondOwner; // bond purchaser
    uint256 lockAmount; // payout token amount that is locked for the user
    BondOption bondOption; // bond option(price and lock period) at which the bond was purchased
    uint256 lockStartedAt; // lock start timestamp
    bool claimed; // if the payout token has been claimed by the user
  }

  address public depositToken; // the inflow token eg. USDC
  address public payoutToken; // the token paid for the principal eg. DHT
  address public treasury; // receives payout token
  uint256 public depositTotal; // the total amount of depositTokens deposited
  uint256 public debtTotal; // tracks the total amount of owed payout tokens
  uint256 public bondNumber; // tracks total number of issued bonds

  BondTerms public bondTerms;
  mapping(uint256 => Bond) public bonds; // get an issued bond
  mapping(address => uint256[]) public userBonds; // get the list of all user issued bond IDs

  uint256 public minBondPrice; // safety to ensure a very low price isn’t set accidentally
  uint256 public maxPayoutAvailable; // safety to ensure a high sell amount isn’t set accidentally

  function initialize(
    address _depositToken,
    address _payoutToken,
    address _treasury,
    uint256 _minBondPrice,
    uint256 _maxPayoutAvailable
  ) external initializer {
    __Ownable_init();
    __Pausable_init();

    depositToken = _depositToken;
    payoutToken = _payoutToken;
    treasury = _treasury;
    minBondPrice = _minBondPrice;
    maxPayoutAvailable = _maxPayoutAvailable;
  }

  // ========== VIEWS ==========

  function bondOptions() external view returns (BondOption[] memory) {
    return bondTerms.bondOptions;
  }

  function getUserBonds(address _user) external view returns (Bond[] memory bondsArray) {
    uint256[] memory bondIds = userBonds[_user];
    bondsArray = new Bond[](bondIds.length);
    for (uint256 i = 0; i < bondIds.length; i++) {
      bondsArray[i] = bonds[bondIds[i]];
    }
  }

  // ========== MUTATIVE FUNCTIONS ==========

  /// @notice Update treasury
  /// @dev owner can set a new treasury address
  /// @param _treasury new treasury address
  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  /// @notice Update minimum principal price
  /// @dev owner can update the minimum principal price
  /// @param _minBondPrice minimum principal price
  function setMinBondPrice(uint256 _minBondPrice) external onlyOwner {
    minBondPrice = _minBondPrice;
  }

  /// @notice Update maximum payout available
  /// @dev owner can update the maximum payout available
  /// @param _maxPayoutAvailable maximum payout available
  function setMaxPayoutAvailable(uint256 _maxPayoutAvailable) external onlyOwner {
    maxPayoutAvailable = _maxPayoutAvailable;
  }

  /// @notice Initializes the bond terms
  /// @dev only owner can set bond terms
  /// @param _payoutAvailable available payout amount
  /// @param _expiryTimestamp expired timestamp
  function setBondTerms(uint256 _payoutAvailable, uint256 _expiryTimestamp) external onlyOwner {
    require(_payoutAvailable <= maxPayoutAvailable, "exceed max available payout");
    require(_expiryTimestamp > block.timestamp, "invalid expiry timestamp");

    bondTerms.payoutAvailable = _payoutAvailable;
    bondTerms.expiryTimestamp = _expiryTimestamp;

    emit SetBondTerms(_payoutAvailable, _expiryTimestamp);
  }

  /// @notice add bond options
  /// @dev only owner can set bond terms
  /// @param _bondOptions bond options
  function addBondOptions(BondOption[] memory _bondOptions) external onlyOwner {
    for (uint256 i = 0; i < _bondOptions.length; i++) {
      require(_bondOptions[i].price >= minBondPrice, "too low payout price");
      bondTerms.bondOptions.push(_bondOptions[i]);
    }

    emit AddBondOptions(_bondOptions);
  }

  /// @notice update bond option
  /// @dev only owner can set bond terms
  /// @param _index bond option index
  /// @param _bondOption bond option
  function _updateBondOption(uint256 _index, BondOption memory _bondOption) internal {
    require(_index < bondTerms.bondOptions.length, "invalid index");
    require(_bondOption.price >= minBondPrice, "too low payout price");
    bondTerms.bondOptions[_index] = _bondOption;
  }

  /// @notice update bond option
  /// @dev only owner can set bond terms
  /// @param _index bond option index
  /// @param _bondOption bond option
  function updateBondOption(uint256 _index, BondOption memory _bondOption) external onlyOwner {
    _updateBondOption(_index, _bondOption);

    emit UpdateBondOption(_index, _bondOption);
  }

  /// @notice update bond options
  /// @dev only owner can set bond terms
  /// @param _indexes bond option index list
  /// @param _bondOptions bond options list
  function updateBondOptions(uint256[] memory _indexes, BondOption[] memory _bondOptions) external onlyOwner {
    require(_indexes.length == _bondOptions.length, "length doesn't match");
    for (uint256 i = 0; i < _indexes.length; i++) {
      _updateBondOption(_indexes[i], _bondOptions[i]);
    }

    emit UpdateBondOptions(_indexes, _bondOptions);
  }

  /// @notice Creates a new bond for the user
  /// @param _payoutAmount payout amount
  /// @param _bondOptionIndex bond option index
  function deposit(
    uint256 _maxDepositAmount,
    uint256 _payoutAmount,
    uint256 _bondOptionIndex
  ) external {
    require(block.timestamp <= bondTerms.expiryTimestamp, "expired");
    require(_payoutAmount <= bondTerms.payoutAvailable, "insufficient available payout");
    require(_bondOptionIndex < bondTerms.bondOptions.length, "invalid bond option index");

    BondOption memory bondOption = bondTerms.bondOptions[_bondOptionIndex];
    require(bondOption.price >= minBondPrice, "too low payout price");

    uint256 depositDecimals = IERC20Extended(depositToken).decimals();
    uint256 payoutDecimals = IERC20Extended(payoutToken).decimals();
    uint256 needToPay = _payoutAmount.mul(bondOption.price).div(1e18).mul(10**depositDecimals).div(10**payoutDecimals);
    require(needToPay <= _maxDepositAmount, "deposit amount exceeded");

    depositToken.tryAssemblyCall(
      abi.encodeWithSelector(IERC20Extended.transferFrom.selector, msg.sender, treasury, needToPay)
    );

    bonds[bondNumber] = Bond({
      bondOwner: msg.sender,
      lockAmount: _payoutAmount,
      bondOption: bondOption,
      lockStartedAt: block.timestamp,
      claimed: false
    });

    userBonds[msg.sender].push(bondNumber);
    bondTerms.payoutAvailable = bondTerms.payoutAvailable.sub(_payoutAmount);
    depositTotal = depositTotal.add(needToPay);
    debtTotal = debtTotal.add(_payoutAmount);

    emit Deposit(msg.sender, bondNumber, _payoutAmount, bondOption);

    bondNumber++;
  }

  /// @notice Transfers lockAmount to bondOwner after lockEndTimestamp
  /// @param _bondId bond index
  function claim(uint256 _bondId) external {
    require(_bondId < bondNumber, "invalid bond index");

    Bond storage bond = bonds[_bondId];
    require(bond.bondOwner == msg.sender, "unauthorized");
    require(bond.lockStartedAt.add(bond.bondOption.lockPeriod) <= block.timestamp, "locked");
    require(!bond.claimed, "already claimed");

    bond.claimed = true;
    debtTotal = debtTotal.sub(bond.lockAmount);
    payoutToken.tryAssemblyCall(abi.encodeWithSelector(IERC20Extended.transfer.selector, msg.sender, bond.lockAmount));

    emit Claim(msg.sender, _bondId);
  }

  /// @notice Withdraw ERC20 tokens
  /// @dev owner can withdraw any erc20 tokens
  /// @param _token ERC20 token address
  /// @param _amount ERC20 token amount to withdraw
  function forceWithdraw(address _token, uint256 _amount) external onlyOwner {
    _token.tryAssemblyCall(abi.encodeWithSelector(IERC20Extended.transfer.selector, msg.sender, _amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMathUpgradeable {
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
pragma solidity 0.7.6;

// With aditional optional views

interface IERC20Extended {
  // ERC20 Optional Views
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  // Views
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function scaledBalanceOf(address user) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  // Mutative functions
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

// import "./BytesLib.sol";

pragma solidity 0.7.6;

/**
 * @title A library for Address utils.
 */
library AddressHelper {
  /**
   * @notice try a contract call via assembly
   * @param to the contract address
   * @param data the call data
   * @return success if the contract call is successful or not
   */
  function tryAssemblyCall(address to, bytes memory data) internal returns (bool success) {
    assembly {
      success := call(gas(), to, 0, add(data, 0x20), mload(data), 0, 0)
      switch iszero(success)
      case 1 {
        let size := returndatasize()
        returndatacopy(0x00, 0x00, size)
        revert(0x00, size)
      }
    }
  }

  /**
   * @notice try a contract delegatecall via assembly
   * @param to the contract address
   * @param data the call data
   * @return success if the contract call is successful or not
   */
  function tryAssemblyDelegateCall(address to, bytes memory data) internal returns (bool success) {
    assembly {
      success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
      switch iszero(success)
      case 1 {
        let size := returndatasize()
        returndatacopy(0x00, 0x00, size)
        revert(0x00, size)
      }
    }
  }

  // /**
  //  * @notice try a contract call
  //  * @param to the contract address
  //  * @param data the call data
  //  * @return success if the contract call is successful or not
  //  */
  // function tryCall(address to, bytes memory data) internal returns (bool) {
  //   (bool success, bytes memory res) = to.call(data);

  //   // Get the revert message of the call and revert with it if the call failed
  //   require(success, _getRevertMsg(res));

  //   return success;
  // }

  // /**
  //  * @dev Get the revert message from a call
  //  * @notice This is needed in order to get the human-readable revert message from a call
  //  * @param response Response of the call
  //  * @return Revert message string
  //  */
  // function _getRevertMsg(bytes memory response) internal pure returns (string memory) {
  //     // If the response length is less than 68, then the transaction failed silently (without a revert message)
  //     if (response.length < 68) return "Transaction reverted silently";
  //     bytes memory revertData = response.slice(4, response.length - 4); // Remove the selector which is the first 4 bytes
  //     return abi.decode(revertData, (string)); // All that remains is the revert string
  // }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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