// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICointapLaunchpad.sol";
import "./constants/SharedConstants.sol";
import "./../utils/Whitelist.sol";
import "./../utils/SafeArrayUint.sol";

contract CoinTapLaunchpad is ICoinTapLaunchpad, Ownable, Pausable, Whitelist {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeArrayUint for uint256[];

    /* events */
    event EmergencyWithdraw(address indexed buyer, uint256 indexed amount);
    event WithdrawBNB(address indexed buyer, uint256 indexed amount);
    event Contribute(address indexed buyer, uint256 indexed amount);
    
    /* Address Cointap Factory */
    address public FACTORY_ADDRESS;
    /* Fee emerceny withdraw (%)*/
    uint256 constant EMERGENCY_WITHDRAW_PORTION = 90; // 90%
    uint256 constant DECIMAL_OF_NATIVE_CURRENCY = 10 ** 18; // 1e18

    mapping(address => uint256) private amounts;
    mapping(address => bool[]) private vestingHistories;

    uint256 public capacityBNB;

    /* Launchpad status */
    SharedConstants.Statuses public status;
    /* Launchpad data */
    SharedConstants.LaunchpadData private launchpadData;
    SharedConstants.VestingTimeline private vestingTimeline;
    SharedConstants.Information private information;

    constructor(
        SharedConstants.LaunchpadData memory _launchpadData,
        SharedConstants.VestingTimeline memory _vestingTimeline,
        SharedConstants.Information memory _information,
        address _ownerAddr
    ) {
      /* Pre check data */
      require(_launchpadData.unsoldToken == SharedConstants.UnsoldToken.BURN || _launchpadData.unsoldToken == SharedConstants.UnsoldToken.REFUND, "CoinTapLaunchpad: Presale must be BURN or REFUND");
      require(_launchpadData.startAt > block.timestamp, "CoinTapLaunchpad: Start time must be after now");
      require(_launchpadData.startAt < _launchpadData.endAt, "CoinTapLaunchpad: Start time must be less than end time");
      require(_launchpadData.softCap > 0 &&  _launchpadData.hardCap  > 0, "CoinTapLaunchpad: Soft and Hard cap must be other than 0");
      require(_launchpadData.softCap < _launchpadData.hardCap, "CoinTapLaunchpad: Soft cap must be less than hard cap");
      require(_launchpadData.minBuy > 0 &&  _launchpadData.maxBuy  > 0, "CoinTapLaunchpad: Min and Max must be other than 0");
      require(_launchpadData.minBuy < _launchpadData.maxBuy, "CoinTapLaunchpad: Min buy must be less than Max buy");
      require(_launchpadData.presaleRate > 0, "CoinTapLaunchpad: Presale rate must be greater than 0");
      require(_vestingTimeline.percents.length == _vestingTimeline.durations.length, "CoinTapLaunchpad: Vesting timeline invalid format");
      require(_vestingTimeline.percents.sum() == 100, "CoinTapLaunchpad: Total percents must be equal 100");
      
      /* Set data */
      launchpadData = _launchpadData;
      vestingTimeline = _vestingTimeline;
      information = _information;
      status = SharedConstants.Statuses.COMMING;
      FACTORY_ADDRESS = _msgSender();

      transferOwnership(_ownerAddr);
    }

    /******************************************* Owner function below *******************************************/

    /**
     * @dev cancel launchpad
     */
    function cancel() public override onlyOwner {
      // Check launch do not start yet, owner can cancel it.
      if(block.timestamp < launchpadData.startAt) {
        status = SharedConstants.Statuses.CANCELLED;
      } else {
        // require(block.timestamp < launchpadData.startAt, "CoinTapLaunchpad: Launchpad is started");
        require(block.timestamp > launchpadData.endAt, "CoinTapLaunchpad: Launchpad do not end yet");
        status = SharedConstants.Statuses.CANCELLED;
        // Refund BNB for user
      }
    }

    /**
     * @dev finalize launchpad
     */
    function finalize() public override onlyOwner {
      // require(block.timestamp > launchpadData.endAt, "CoinTapLaunchpad: Launchpad do not end yet");
      require(capacityBNB > launchpadData.softCap, "CoinTapLaunchpad: Capacity BNB user bought less than soft cap");
      // First release token for participant
      status = SharedConstants.Statuses.FINZALIZE;
    }

    /**
     * @dev collect BNB
     */
    function collectBNB() public override onlyOwner {
      payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev withdraw token if launchpad cancelled
     */
    function collectToken() public override onlyOwner {
      require(status == SharedConstants.Statuses.CANCELLED, "CoinTapLaunchpad: Launchpad do not cancel yet");

      IERC20 token = IERC20(launchpadData.token);
      uint256 amount = token.balanceOf(address(this));
      require(amount > 0, "CoinTapLaunchpad: token balance is zero");

      token.safeTransfer(owner(), amount);
    }

    /**
     * @dev cancel launchpad
     */
    function updateInfo(SharedConstants.Information memory _information) public override onlyOwner {
      information = _information;
    }

    /******************************************* Participant function below *******************************************/

    /**
     * @dev Buy token
     */
    function buyToken() public override payable {
      require(block.timestamp > launchpadData.startAt, "CoinTapLaunchpad: Launchpad do not start yet");
      require(block.timestamp < launchpadData.endAt, "CoinTapLaunchpad: Launchpad is ended");
      require(status != SharedConstants.Statuses.CANCELLED, "CoinTapLaunchpad: Launchpad is cancelled");
      require(status != SharedConstants.Statuses.FINZALIZE, "CoinTapLaunchpad: Launchpad is finalized");

      // Check max and hard cap user can buy
      uint256 amount = msg.value;
      require(capacityBNB.add(amount) > launchpadData.hardCap, "CoinTapLaunchpad: The capacity has exceeded the limit");

      address buyer = _msgSender();
      uint256 amountOfUser = amounts[buyer];
      
      require(amountOfUser.add(amount) > launchpadData.maxBuy, "CoinTapLaunchpad: Cannot buy more token because you bought more than max amount");
      require(buyer != address(0), "CoinTapLaunchpad: Buyer is the zero address");
      require(amount > 0, "CoinTapLaunchpad: Amount must be greater than 0");

      amounts[buyer] = amounts[buyer].add(amount);
      capacityBNB = capacityBNB.add(amount);

      // Update status 
      if(status == SharedConstants.Statuses.COMMING) {
        status = SharedConstants.Statuses.OPENING;
      }

      emit Contribute(buyer, amount);
    }

    /**
     * @dev Emergency Withdraw BNB
     */
    function emergencyWithdraw() public payable override {
      require(block.timestamp < launchpadData.endAt, "CoinTapLaunchpad: Launchpad is ended");
      require(status != SharedConstants.Statuses.FINZALIZE, "CoinTapLaunchpad: Launchpad is finalized");

      address buyer = _msgSender();
      
      uint256 amountOfUser = amounts[buyer];
      // Fee 10%
      uint256 amountFinal = amountOfUser.mul(EMERGENCY_WITHDRAW_PORTION).div(100);
      payable(buyer).transfer(amountFinal);
      amounts[buyer] = 0;
      capacityBNB = capacityBNB.sub(amountOfUser);

      emit EmergencyWithdraw(buyer, amountFinal);
    }

    /**
     * @dev Withdraw BNB, no cal fee
     */
    function withdraw() public payable override {
      require(status == SharedConstants.Statuses.CANCELLED, "CoinTapLaunchpad: Launchpad do not cancelled yet");

      address buyer = _msgSender();
      
      uint256 amountOfUser = amounts[buyer];
      payable(buyer).transfer(amountOfUser);

      amounts[buyer] = 0;
      capacityBNB = capacityBNB.sub(amountOfUser);

      emit WithdrawBNB(buyer, amountOfUser);
    }

    /**
     * @dev Amount of address
     */
    function amountOf(address _addr) public view override returns (uint256) {
      return amounts[_addr];
    }

    /**
     * @dev Claim token
     */
    function claim() public override {
      // require(status == SharedConstants.Statuses.FINZALIZE, "CoinTapLaunchpad: Launchpad do not finalized yet");
      address buyer = _msgSender();
      uint256 amountBNB = amounts[buyer];
      // require(amountBNB > 0, "CoinTapLaunchpad: Wallet do not contribute bnb yet");

      uint256 nextOrder = vestingHistories[buyer].length;
      
      uint256 percent = vestingTimeline.percents[nextOrder];
      uint256 duration = vestingTimeline.durations[nextOrder];

      // check duration

      // transfer amount for participant
      uint256 totalAmount = amountBNB.div(DECIMAL_OF_NATIVE_CURRENCY).mul(launchpadData.presaleRate);
      uint256 amount = totalAmount.mul(percent).div(100);
      
      IERC20 token = IERC20(launchpadData.token);
      token.safeTransfer(buyer, amount);

      // set participant claimed
      vestingHistories[buyer].push(true);
    }

    /******************************************* Common function below *******************************************/

    /**
     * @dev Get information of launchpad
     */
    function getLaunchpadData() public view override returns (SharedConstants.LaunchpadData memory) {
      return launchpadData;
    }

    function getLaunchpadInfo() public view override returns (SharedConstants.Information memory) {
      return information;
    }

    function getLaunchpadVesting() public view override returns (SharedConstants.VestingTimeline memory) {
      return vestingTimeline;
    }

    function getVestingHistories(address _addr) public view override returns (bool[] memory) {
      return vestingHistories[_addr];
    }


    /******************************************* Internal function below *******************************************/
    // function _handleUnsoldToken() internal {
    //   if(launchpadData.unsoldToken == SharedConstants.UnsoldToken.BURN) {
        
    //   }

    //   if(launchpadData.unsoldToken == SharedConstants.UnsoldToken.BURN) {
        
    //   }
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender),"Whitelist: address does not exist");
        _;
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

library SafeArrayUint {

    function sum(
        uint256[] memory arr
    ) internal pure returns (uint256) {
        uint i;
        uint256 s = 0;   
        for(i = 0; i < arr.length; i++)
          s = s + arr[i];
        return s;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "./../constants/SharedConstants.sol";
interface ICoinTapLaunchpad { 
  /* Common */
  function getLaunchpadData() external view returns(SharedConstants.LaunchpadData memory);
  function getLaunchpadInfo() external view returns(SharedConstants.Information memory);
  function getLaunchpadVesting() external view returns(SharedConstants.VestingTimeline memory);
  function getVestingHistories(address _addr) external view returns(bool[] memory);
  /* Owner */
  function cancel() external;
  function finalize() external;
  function collectBNB() external;
  function collectToken() external;
  function updateInfo(SharedConstants.Information memory _information) external;
  /* Paticipant */
  function buyToken() external payable;
  function emergencyWithdraw() external payable;
  function withdraw() external payable;
  function claim() external;
  // function claim() external;
  function amountOf(address addr) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library SharedConstants {
    enum Statuses {
        COMMING,
        FINZALIZE,
        CANCELLED,
        OPENING
    }

    enum PresaleType {
        PUBLIC,
        WHITELIST,
        BLABLA
    }

    enum UnsoldToken {
        BURN,
        REFUND
    }

    struct VestingTimeline {
        uint256[] percents;
        uint256[] durations; // seconds
    }

    /* Project infomation, include link discord, twitter, ... */
    struct Information {
        string facebook;
        string discord;
        string twitter;
        string telegram;
        string website;
        string github;
        string instagram;
        string audit;
        string description;
    }

    struct LaunchpadData {
        // Information information;
        /* Token */
        address token;
        UnsoldToken unsoldToken;
        /* Sorf and Hard cap */
        uint256 softCap;
        uint256 hardCap;
        /* Min and Max can buy */
        uint256 minBuy;
        uint256 maxBuy;
        /* Presale time */
        uint256 startAt;
        uint256 endAt;
        /* Rate */
        uint256 presaleRate;

        // VestingTimeline[] vesting;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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