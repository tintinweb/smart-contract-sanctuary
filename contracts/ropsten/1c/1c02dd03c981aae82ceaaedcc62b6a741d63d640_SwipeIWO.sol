/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

    function burn(uint256 amount) external returns(bool);

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SwipeIWO is Ownable {
    struct WhiteList {
        bool isWhite;
        uint256 maxAllowance;
    }

    // Use SafeMath for uint256 and SafeERC20 for IERC20
    using SafeMath for uint256;
 
    // Address For BaseToken. e.x: SXP
    address private _baseToken;
    // Address For SaleToken. e.x: STRK
    address private _saleToken;
    // Rate STRK To SXP
    uint256 private _saleRate;
    // Is Sale, Only set with owner
    bool private _isSale;
    // Sale Start Time
    uint256 private _startTime;
    // Sale End Time
    uint256 private _endTime;
    // Maximum Base Token Amount
    uint256 private _maxBaseAmount;
    // Minimum Base Token Amount
    uint256 private _minBaseAmount;
    // Limit Base Token Amount
    uint256 private _limitBaseAmount;

    // baseAmount with each address
    mapping(address => uint256) _baseAmounts;
    mapping(address => WhiteList) _whiteList;

    modifier isNoContract() {
        require(
            Address.isContract(_msgSender()) == false,
            "Contract is not allowed on SwipeIWO"
        );
        _;
    }

    modifier isNotWhite(uint256 newSaleAmount) {
        require(_whiteList[_msgSender()].isWhite, "You're not allowed to purchased");
        require(
            _baseAmounts[_msgSender()].add(newSaleAmount) <= _whiteList[_msgSender()].maxAllowance,
            "You can not purchase more than maxAllowance"
        );
        _;
    }

    /**
     * @dev Check IWO is not Over
     */
    modifier isNotOver() {
        require(_isSale, "SwipeIWO is sale over");
        require(block.timestamp >= _startTime, "SwipeIWO is not started yet");
        require(block.timestamp <= _endTime, "SwipeIWO is already finished");
        require(IERC20(_baseToken).balanceOf(address(this)) <= _limitBaseAmount, "Already sold out.");
        _;
    }

    /**
     * @dev Check IWO is Over
     */
    modifier isOver() {
        require(!_isSale || block.timestamp < _startTime || block.timestamp > _endTime || IERC20(_baseToken).balanceOf(address(this)) > _limitBaseAmount, "SwipeIWO is not finished yet");
        _;
    }

    event PurchaseToken(address indexed account, uint256 baseAmount, uint256 saleAmount);
    
    constructor() {
        // Initialize the base&sale Tokens
        _baseToken = address(0);
        _saleToken = address(0);

        // Initialize the rate&isSale, should be divide 1e18 when purchase
        _saleRate = 1e18;
        _isSale = false;

        // Initialize the start&end time
        _startTime = block.timestamp;
        _endTime = block.timestamp;

        // Initialize the max&min base amount
        _minBaseAmount = 1e18;
        _maxBaseAmount = 1e18;

        // Initialize the baseLimitAmount
        _limitBaseAmount = 1e18;
    }

    /**
     * @dev Get White Status
     */
    function getWhiteStatus(address userAddress) public view returns (bool, uint256) {
        return (
            _whiteList[userAddress].isWhite,
            _whiteList[userAddress].maxAllowance
        );
    }

    /**
     * @dev Set White Statuses, only owner call it
     */
    function setWhiteStatus(address[] memory userAddressList, WhiteList[] memory userInfoList) external onlyOwner returns (bool) {
        require(userAddressList.length == userInfoList.length, "The lengths of arrays should be same.");

        for (uint i = 0; i < userAddressList.length; i += 1) {
            _whiteList[userAddressList[i]] = userInfoList[i];
        }

        return true;
    }

    /**
     * @dev Get Base Token
     */
    function getBaseToken() public view returns (address) {
        return _baseToken;
    }

    /**
     * @dev Set Base Token, only owner call it
     */
    function setBaseToken(address baseToken) external onlyOwner {
        require(baseToken != address(0), "BaseToken should be not 0x0");
        _baseToken = baseToken;
    }

    /**
     * @dev Get Sale Token
     */
    function getSaleToken() public view returns (address) {
        return _saleToken;
    }

    /**
     * @dev Set Sale Token, only owner call it
     */
    function setSaleToken(address saleToken) external onlyOwner {
        require(saleToken != address(0), "SaleToken should be not 0x0");
        _saleToken = saleToken;
    }

    /**
     * @dev Get Sale Rate
     */
    function getSaleRate() public view returns (uint256) {
        return _saleRate;
    }

    /**
     * @dev Set Sale Rate, only owner call it
     */
    function setSaleRate(uint256 saleRate) external onlyOwner {
        _saleRate = saleRate;
    }

    /**
     * @dev Get IsSale
     */
    function getIsSale() public view returns (bool) {
        return _isSale;
    }

    /**
     * @dev Set IsSale, only owner call it
     */
    function setIsSale(bool isSale) external onlyOwner {
        _isSale = isSale;
    }

    /**
     * @dev Get IWO Start Time
     */
    function getStartTime() public view returns (uint256) {
        return _startTime;
    }

    /**
     * @dev Set IWO Start Time, only owner call it
     */
    function setStartTime(uint256 startTime) external onlyOwner {
        _startTime = startTime;
    }

    /**
     * @dev Get IWO End Time
     */
    function getEndTime() public view returns (uint256) {
        return _endTime;
    }

    /**
     * @dev Set End Time, only owner call it
     */
    function setEndTime(uint256 endTime) external onlyOwner {
        require(endTime > _startTime, "EndTime should be over than startTime");
        _endTime = endTime;
    }

    /**
     * @dev Get MinBase Amount
     */
    function getMinBaseAmount() public view returns (uint256) {
        return _minBaseAmount;
    }

    /**
     * @dev Set MinBase Amount, only owner call it
     */
    function setMinBaseAmount(uint256 minBaseAmount) external onlyOwner {
        _minBaseAmount = minBaseAmount;
    }

    /**
     * @dev Get MaxBase Amount
     */
    function getMaxBaseAmount() public view returns (uint256) {
        return _maxBaseAmount;
    }

    /**
     * @dev Set MaxBase Amount, only owner call it
     */
    function setMaxBaseAmount(uint256 maxBaseAmount) external onlyOwner {
        require(maxBaseAmount > _minBaseAmount, "MaxBaseAmount should be over than minBaseAmount");
        _maxBaseAmount = maxBaseAmount;
    }

    /**
     * @dev Get LimitBase Amount
     */
    function getLimitBaseAmount() public view returns (uint256) {
        return _limitBaseAmount;
    }

    /**
     * @dev Set LimitBase Amount, only owner call it
     */
    function setLimitBaseAmount(uint256 limitBaseAmount) external onlyOwner {
        _limitBaseAmount = limitBaseAmount;
    }

    /**
     * @dev Check IsIWO On Status
     */
    function isIWOOn() public view returns (bool) {
        if (_isSale &&
            block.timestamp >= _startTime &&
            block.timestamp <= _endTime &&
            IERC20(_baseToken).balanceOf(address(this)) <= _limitBaseAmount) {
                return true;
            }
        return false;
    }

    /**
     * @dev Set Allocation Amount with Sale Token, only owner call it
            Should approve the amount before call this function
     */
    function allocationAmount(uint256 amount) external onlyOwner returns (bool) {
        require(IERC20(_saleToken).balanceOf(address(_msgSender())) >= amount, "Owner should have more than amount with Sale Token");

        IERC20(_saleToken).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        return true;
    }

    /**
     * @dev Burn baseToken, only owner call it
     */
    function burnBaseToken(uint256 burnAmount) external onlyOwner returns (bool) {
        require(IERC20(_baseToken).balanceOf(address(this)) >= burnAmount, "Burn Amount should be less than balance of contract");

        IERC20(_baseToken).burn(burnAmount);

        return true;
    }

    /**
     * @dev Withdraw Base Token, only owner call it
     */
    function withdrawBaseToken(address withdrawAddress) external onlyOwner returns (bool) {
        uint256 baseBalance = IERC20(_baseToken).balanceOf(address(this));
        require(baseBalance > 0, "The Base balance of contract should be more than zero");

        IERC20(_baseToken).transfer(withdrawAddress, baseBalance);

        return true;
    }

    /**
     * @dev Withdraw Sale Token, only owner call it
     */
    function withdrawSaleToken(address withdrawAddress) external onlyOwner returns (bool) {
        uint256 saleBalance = IERC20(_saleToken).balanceOf(address(this));
        require(saleBalance > 0, "The Sale balance of contract should be more than zero");

        IERC20(_saleToken).transfer(withdrawAddress, saleBalance);

        return true;
    }
    
    /**
     * @dev Purchase Sale Token
            Should approve the baseToken before purchase
     */
    function purchaseSaleToken(uint256 baseAmountForSale)
        external
        isNoContract
        isNotOver
        isNotWhite(baseAmountForSale)
        returns (bool)
    {
        // Check min&max base amount
        uint256 currentBaseTotalAmount = IERC20(_baseToken).balanceOf(address(this));
        // Get Sale Amount
        uint256 saleAmount = baseAmountForSale.mul(_saleRate).div(1e18);

        require(baseAmountForSale >= _minBaseAmount, "Purchase Amount should be more than minBaseAmount");
        require(_baseAmounts[_msgSender()].add(baseAmountForSale) <= _maxBaseAmount, "Purchase Amount should be less than maxBaseAmount");
        require(currentBaseTotalAmount.add(baseAmountForSale) <= _limitBaseAmount, "Total Base Amount shoould be less than baseLimitAmount");
        require(IERC20(_saleToken).balanceOf(address(this)) >= saleAmount, "The contract should have saleAmount with saleToken at least");

        // Update baseAmounts
        _baseAmounts[_msgSender()] = _baseAmounts[_msgSender()].add(baseAmountForSale);

        // TransferFrom baseToken from msgSender to Contract
        IERC20(_baseToken).transferFrom(
            _msgSender(),
            address(this),
            baseAmountForSale
        );

        // Send Sale Token to msgSender
        IERC20(_saleToken).transfer(
            _msgSender(),
            saleAmount
        );

        emit PurchaseToken(_msgSender(), baseAmountForSale, saleAmount);

        return true;
    }
}