/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

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


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File contracts/TesPreSale.sol

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TesPresale is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 remainAmount;
        uint256 phaseOneTES;
        uint256 phaseTwoTES;
        uint256 phaseOneBNB;
        uint256 phaseTwoBNB;
    }

    uint256 public constant MAX_DURATION = 72 hours; // 3 days
    uint256 public constant MAX_LOCK_PERIOD = 504 hours; // 21 days
    uint256 public startTime;
    uint256 public endTime;
    uint256 public unlockTime;

    IBEP20 public TES;

    uint public    phase = 1;
    uint256 public priceRate = 1400;
    uint256 public presaleTotalSale;
    uint256 public presaleLocking;
    uint256 public presaleRelease;

    uint256 public duration = 72 hours; // 3 days
    uint256 public lockPeriod = 504 hours; // 21 days
    uint256 public totalPresale = 10000000 ether;

    bool public isPresaleStopped = false;
    bool public isPresalePaused = false;

    mapping(address => UserInfo) public buyers;

    // event
    event Buy(address receiver, uint amount, uint amountTes);
    event UnlockPresale(address _buyer, uint _amount);
    constructor(
        IBEP20 _presaleToken,
        uint256 _startTime,
        uint256 _endTime
    ) {
        startTime = _startTime;
        endTime = _endTime;
        TES = IBEP20(_presaleToken);
        require(endTime >= startTime);
    }
    function BNB2TES(uint _amountBNB) public view returns(uint _amountTes) {
        uint256 tesAmount = _amountBNB.mul(priceRate);
        return tesAmount;
    }
    function _buy(uint256 _amount,uint256 _bnb) internal {
        if(phase == 1){
            buyers[msg.sender].phaseOneTES = buyers[msg.sender].phaseOneTES.add(_amount);
            buyers[msg.sender].phaseOneBNB = buyers[msg.sender].phaseOneBNB.add(_bnb);
        }else{
            buyers[msg.sender].phaseTwoTES = buyers[msg.sender].phaseTwoTES.add(_amount);
            buyers[msg.sender].phaseTwoBNB = buyers[msg.sender].phaseTwoBNB.add(_bnb);
        }
        buyers[msg.sender].amount = buyers[msg.sender].amount.add(_amount);
        buyers[msg.sender].remainAmount = buyers[msg.sender].remainAmount.add(_amount);
        presaleLocking = presaleLocking.add(_amount);
        presaleTotalSale = presaleTotalSale.add(_amount);
    }
    function buy() public payable {
        require(isPresaleStopped != true, 'Presale is stopped');
        require(isPresalePaused != true, 'Presale is paused');
        require(validPurchase(), 'Its not a valid purchase');
        uint256 amountTes = BNB2TES(msg.value);
        payable(owner()).transfer(msg.value);
        _buy(amountTes, msg.value);
        emit Buy(msg.sender, msg.value, amountTes);
    }
    function unlockPresaleTime() public view returns(uint) {
        return unlockTime;
    }
    function getRemainPresale() public view returns(uint) {
        return totalPresale.sub(presaleLocking);
    }
    function unlockAmount() public view returns (uint256) {
        uint256 totalAmount = buyers[msg.sender].amount;
        uint256 remainAmount = buyers[msg.sender].remainAmount;
        // console.log('block.timestamp');
        // console.log(block.timestamp);
        // console.log('unlockTime');
        // console.log(unlockTime);
        if (block.timestamp < unlockTime) {
            return 0;
        }
        if (remainAmount == 0) {
            return 0;
        }
        // console.log('remainAmount');
        // console.log(remainAmount);
        // calculate amount of 3 days passed since base unlock time;
        uint diff = (block.timestamp - unlockTime).div(duration);
        // console.log('diff');
        // console.log(diff);
        uint week = lockPeriod.div(duration);
        // console.log('week');
        // console.log(week);
        if (diff > week) {
            return remainAmount;
        }
        // calculate amount of unrestricted within distributed 3 days.
        uint256 unrestricted = totalAmount.mul(3000).div(10000) + totalAmount.mul(1000).div(10000) * diff;
        // console.log('unrestricted');
        // console.log(unrestricted);
        if (unrestricted > totalAmount) {
            unrestricted = totalAmount;
        }
        // console.log('unrestricted');
        // console.log(unrestricted);
        uint256 amount;
        // calculate total amount including those not from distribution
        if (unrestricted.add(remainAmount) < totalAmount) {
            amount = 0;
        } else {
            amount = unrestricted.sub(totalAmount.sub(remainAmount));
        }
        // console.log('amount');
        // console.log(amount);
        return amount;
    }
    function unlockPresale() public {
        require(block.timestamp >= unlockPresaleTime() && buyers[msg.sender].remainAmount > 0, 'Invalid unlockPresale');
        uint256 _unlockAmount = unlockAmount();
        // console.log('_unlockAmount');
        // console.log(_unlockAmount);
        if (_unlockAmount > buyers[msg.sender].remainAmount) {
            _unlockAmount = buyers[msg.sender].remainAmount;
        }
        TES.transfer(msg.sender, _unlockAmount);
        buyers[msg.sender].remainAmount = buyers[msg.sender].remainAmount.sub(_unlockAmount);
        presaleLocking = presaleLocking.sub(_unlockAmount);
        presaleRelease = presaleRelease.add(_unlockAmount);
        emit UnlockPresale(msg.sender, buyers[msg.sender].amount);
    }
    function withdraw(address _address) public onlyOwner {
        uint tokenBalanceOfContract = getRemainingToken();
        TES.transfer(_address, tokenBalanceOfContract.sub(presaleLocking));
    }
    function validPurchase() internal returns (bool) {
        // console.log(block.timestamp);
        // console.log(startTime);
        // console.log(endTime);
        // console.log(msg.value);
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

    function setDuration(uint256 _duration) public onlyOwner returns (bool) {
        require(_duration > 0, "setDuration: invalid value");
        require(_duration <= MAX_DURATION, "setDuration: duration cannot be more than MAX_DURATION");
        duration = _duration;
        return true;
    }

    function setLockPeriod(uint256 _lockPeriod) public onlyOwner returns (bool) {
        require(_lockPeriod > 0, "setLockPeriod: invalid value");
        require(_lockPeriod <= MAX_LOCK_PERIOD, "setLockPeriod: lockPeriod cannot be more than MAX_LOCK_PERIOD");
        lockPeriod = _lockPeriod;
        return true;
    }

    function setPriceRate(uint256 _priceRate) public onlyOwner returns (bool) {
        require(isPresalePaused == true, 'Presale is not paused');
        priceRate = _priceRate;
        return true;
    }

    function setPhase(uint256 _phase) public onlyOwner returns (bool) {
        require(isPresalePaused == true, 'Presale is not paused');
        phase = _phase;
        return true;
    }

    function pausePresale() public onlyOwner returns (bool) {
        isPresalePaused = true;
        return isPresalePaused;
    }

    function resumePresale() public onlyOwner returns (bool) {
        isPresalePaused = false;
        return !isPresalePaused;
    }

    function stopPresale() public onlyOwner returns (bool) {
        isPresaleStopped = true;
        return true;
    }

    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        return true;
    }
    function setStartTime(uint256 _startTime) public onlyOwner returns (bool) {
        startTime = _startTime;
        return true;
    }
    function setUnlockTime(uint256 _unlockTime) public onlyOwner returns (bool) {
        unlockTime = _unlockTime;
        return true;
    }
    function setEndTime(uint256 _endTime) public onlyOwner returns (bool) {
        endTime = _endTime;
        return true;
    }
    function recoverLostBNB() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    /**
    * @dev Get the remaining amount of token user can receive.
    * @return Uint256 the amount of token that user can reveive.
    */
    function getRemainingToken() public view returns (uint256) {
        return TES.balanceOf(address(this));
    }
}