/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface IBEP20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an BNB balance of at least `value`.
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract SeleneFinance is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tRebaseTotal;
    uint256 private _tCharityTotal;
    uint256 private _tFeeCycle;

    string private constant _name = "Selene";
    string private constant _symbol = "SELENE";
    uint8 private constant _decimals = 9;

    uint256 public _rebaseFee = 0;
    uint256 public _charityFee = 0;
    uint256 public _marketingFee = 0;

    uint256 private _seleneCycle = 0;
    uint256 private _tTradeCycle = 0;
    uint256 private constant _tTradeCycleMax = 7000 * 10**6 * 10**9;

    uint256 public _tradeFee;

    bool private _setTradeFeeTriggered = false;

    address public pancakePair;
    address payable public _charityAddress;
    address payable public _marketingAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 30 * 10**6 * 10**9;

    constructor(
        address payable charityAddress_,
        address payable marketingAddress_
    ) public {
        _charityAddress = charityAddress_;
        _marketingAddress = marketingAddress_;
        _rOwned[_msgSender()] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function _getCycle() public view returns (uint256) {
        return _seleneCycle;
    }

    function _getTradeCycle() public view returns (uint256) {
        return _tTradeCycle;
    }

    function _getTradeCycleMax() public pure returns (uint256) {
        return _tTradeCycleMax;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalCharity() public view returns (uint256) {
        return _tCharityTotal;
    }

    function totalRebase() public view returns (uint256) {
        return _tRebaseTotal;
    }

    function cycleFees() public view returns (uint256) {
        return _tFeeCycle;
    }

    function _transferCharityAndMarketing(uint256 tAmount) private {
        (
            uint256 rCharity,
            uint256 rMarketing,
            uint256 tCharity,
            uint256 tMarketing
        ) = _getCharityMarketingValues(tAmount);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
        _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
        _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRebase,
            uint256 tTransferAmount,
            uint256 tRebase
        ) = _getValues(tAmount);
        (, , uint256 tCharity, uint256 tMarketing) =
            _getCharityMarketingValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burnAndRebase(rRebase, tRebase, tCharity, tMarketing);
        _transferCharityAndMarketing(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    // function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    //     swapAndLiquifyEnabled = _enabled;
    //     emit SwapAndLiquifyEnabledUpdated(_enabled);
    // }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function calculateRebaseFee(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        if (_setTradeFeeTriggered) {
            uint256 amountHalf = _amount.div(2);
            uint256 lastTradeFee = _tradeFee.add(5);
            uint256 tRebaseHalf =
                amountHalf.mul(_tradeFee).div(100).mul(60).div(10**3);
            uint256 tRebaseSecondHalf =
                amountHalf.mul(lastTradeFee).div(100).mul(60).div(10**3);
            uint256 tRebase = tRebaseHalf.add(tRebaseSecondHalf);

            return tRebase;
        } else {
            uint256 tRebase =
                _amount.mul(_tradeFee).div(100).mul(60).div(10**3);

            return tRebase;
        }
    }

    function calculateCharityFee(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        if (_setTradeFeeTriggered) {
            uint256 amountHalf = _amount.div(2);
            uint256 lastTradeFee = _tradeFee.add(5);
            uint256 tCharityHalf =
                amountHalf.mul(_tradeFee).div(100).mul(30).div(10**3);
            uint256 tCharitySecondHalf =
                amountHalf.mul(lastTradeFee).div(100).mul(30).div(10**3);
            uint256 tCharity = tCharityHalf.add(tCharitySecondHalf);

            return tCharity;
        } else {
            uint256 tCharity =
                _amount.mul(_tradeFee).div(100).mul(30).div(10**3);

            return tCharity;
        }
    }

    function calculateMarketingFee(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        if (_setTradeFeeTriggered) {
            uint256 amountHalf = _amount.div(2);
            uint256 lastTradeFee = _tradeFee.add(5);
            uint256 tMarketingHalf =
                amountHalf.mul(_tradeFee).div(10).div(10**3);
            uint256 tMarketingSecondHalf =
                amountHalf.mul(lastTradeFee).div(10).div(10**3);
            uint256 tMarketing = tMarketingHalf.add(tMarketingSecondHalf);

            return tMarketing;
        } else {
            uint256 tMarketing = _amount.mul(_tradeFee).div(10).div(10**3);

            return tMarketing;
        }
    }

    function removeAllFee() private {
        if (_rebaseFee == 0 && _charityFee == 0 && _marketingFee == 0) return;

        _rebaseFee = 0;
        _charityFee = 0;
        _marketingFee = 0;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tRebase) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRebase) =
            _getRValues(tAmount, tRebase, _getRate());
        return (rAmount, rTransferAmount, rRebase, tTransferAmount, tRebase);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        (uint256 tCharity, uint256 tMarketing) =
            _getCharityMarketingTValues(tAmount);
        uint256 tRebase = calculateRebaseFee(tAmount);
        uint256 tTransferAmount =
            tAmount.sub(tRebase).sub(tCharity).sub(tMarketing);
        return (tTransferAmount, tRebase);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tRebase,
        uint256 currentRate
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 rCharity, uint256 rMarketing, , ) =
            _getCharityMarketingValues(tAmount);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRebase = tRebase.mul(currentRate);
        uint256 rTransferAmount =
            rAmount.sub(rRebase).sub(rCharity).sub(rMarketing);
        return (rAmount, rTransferAmount, rRebase);
    }

    function _getCharityMarketingValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tCharity, uint256 tMarketing) =
            _getCharityMarketingTValues(tAmount);
        (uint256 rCharity, uint256 rMarketing) =
            _getCharityMarketingRValues(tCharity, tMarketing, _getRate());
        return (rCharity, rMarketing, tCharity, tMarketing);
    }

    function _getCharityMarketingTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tCharity = calculateCharityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        return (tCharity, tMarketing);
    }

    function _getCharityMarketingRValues(
        uint256 tCharity,
        uint256 tMarketing,
        uint256 currentRate
    ) private pure returns (uint256, uint256) {
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        return (rCharity, rMarketing);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        if (_tradeFee >= 60) {
            _determineFee(amount);
        }

        // indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        _setTradeFeeTriggered = false;
    }

    function _determineFee(uint256 amount) public {
        uint256 partialOfFee = _tTradeCycleMax.div(11);
        _tTradeCycle = _tTradeCycle.add(amount);
        uint256 _tradeFeeNow = _tradeFee;

        if (_tTradeCycle >= (0) && _tTradeCycle < (partialOfFee)) {
            _setTradeFee(110);
        } else if (
            _tTradeCycle >= (partialOfFee) &&
            _tTradeCycle < (partialOfFee.mul(2))
        ) {
            _setTradeFee(105);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(2)) &&
            _tTradeCycle < (partialOfFee.mul(3))
        ) {
            _setTradeFee(100);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(3)) &&
            _tTradeCycle < (partialOfFee.mul(4))
        ) {
            _setTradeFee(95);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(4)) &&
            _tTradeCycle < (partialOfFee.mul(5))
        ) {
            _setTradeFee(90);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(5)) &&
            _tTradeCycle < (partialOfFee.mul(6))
        ) {
            _setTradeFee(85);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(6)) &&
            _tTradeCycle < (partialOfFee.mul(7))
        ) {
            _setTradeFee(80);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(7)) &&
            _tTradeCycle < (partialOfFee.mul(8))
        ) {
            _setTradeFee(75);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(8)) &&
            _tTradeCycle < (partialOfFee.mul(9))
        ) {
            _setTradeFee(70);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(9)) &&
            _tTradeCycle <= (partialOfFee.mul(10))
        ) {
            _setTradeFee(65);
        } else if (
            _tTradeCycle >= (partialOfFee.mul(10)) &&
            _tTradeCycle <= (partialOfFee.mul(11))
        ) {
            _setTradeFee(60);
        }

        if (_tradeFeeNow > _tradeFee) {
            _setTradeFeeTriggered = true;
        }
    }

    function _setTradeFee(uint256 tradeFee) private {
        require(
            tradeFee >= 0 && tradeFee <= 110,
            "tradeFee should be in 0 - 11"
        );
        _tradeFee = tradeFee;
    }

    function _setFeeStage(uint256 tradeFee) external onlyOwner() {
        require(
            _tradeFee >= 0 && _tradeFee <= 110,
            "burnFee should be in 0 - 11"
        );
        _tradeFee = tradeFee;
    }

    function _initializeFinalStage() internal {
        _setTradeFee(0);
    }

    function _burnAndRebase(
        uint256 rFee,
        uint256 tFee,
        uint256 tCharity,
        uint256 tMarketing
    ) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tCharityTotal = _tCharityTotal.add(tCharity);
        _tFeeCycle = _tFeeCycle.add(tFee);
        _tRebaseTotal = _tRebaseTotal.add(tFee);
        _tTradeCycle = _tTradeCycle.add(tFee).add(tCharity).add(tMarketing);
        _tTotal = _tTotal.sub(tFee);

        if (_tTradeCycle >= (_tTradeCycleMax)) {
            _tTradeCycle = _tTradeCycle.sub((_tTradeCycleMax));
            _tTradeCycle = 0;
            _setTradeFee(110);

            _rebase(_tFeeCycle);
        }
    }

    function _rebase(uint256 supplyDelta) internal {
        _seleneCycle = _seleneCycle.add(1);
        _tTotal = _tTotal.add(supplyDelta);
        _tFeeCycle = 0;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRebase,
            uint256 tTransferAmount,
            uint256 tRebase
        ) = _getValues(tAmount);
        (, , uint256 tCharity, uint256 tMarketing) =
            _getCharityMarketingValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burnAndRebase(rRebase, tRebase, tCharity, tMarketing);
        _transferCharityAndMarketing(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRebase,
            uint256 tTransferAmount,
            uint256 tRebase
        ) = _getValues(tAmount);
        (, , uint256 tCharity, uint256 tMarketing) =
            _getCharityMarketingValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burnAndRebase(rRebase, tRebase, tCharity, tMarketing);
        _transferCharityAndMarketing(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRebase,
            uint256 tTransferAmount,
            uint256 tRebase
        ) = _getValues(tAmount);
        (, , uint256 tCharity, uint256 tMarketing) =
            _getCharityMarketingValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _burnAndRebase(rRebase, tRebase, tCharity, tMarketing);
        _transferCharityAndMarketing(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}