/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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


interface BNBPair {
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

contract UDESeedSale is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    
    event UDETransferred(address _holder, uint256 _amount);
    
    struct Investments {
        address _investor;
        uint256 _udeAmount;
        uint256 _busdAmount;
        bool    _isBNB;
    }
    
    struct Investment {
        address _investor;
        uint256 _udeAmount;
        uint256 _udeClaimed;
        uint256 _udeStaked;
        uint256 _busdAmount;
        uint _lastClaimed;
        uint _lastInvested;
    }
    
    mapping (address => Investments[]) public _investors;
    mapping (address => Investment) public _invested;
    mapping (address => uint256) public _totalInvestment;
    
    Investments[] public _allInvestments;
    
    uint256 public _bnbRaised;
    uint256 public _busdRaised;
    uint256 public _udeSold;
    uint256 public _udeSell;
    
    BNBPair public _bnbPair;
    uint256 public MIN_INVEST = 50 * 1e18;
    uint256 public MAX_INVEST = 25000 * 1e18;
    IBEP20 public UDE;
    IBEP20 public BUSD;
    uint256 public _udeRate = 0.01 * 1e18;
    uint256 public _lockedInterval = 5 minutes;
    uint256 public _initialReturn = 25;
    bool public _isSaleLive = false;
    
    modifier onlyWhenSaleIsLive {
        require(_isSaleLive, '[!] Seed Sale For UDE Token is not Live');
        _;
    }
    
    constructor(BNBPair bnbPair, IBEP20 _ude, IBEP20 _busd) public {
        _bnbPair = bnbPair;
        UDE = _ude;
        BUSD = _busd;
    }
    
    function changeSaleState() external onlyOwner {
        _isSaleLive = !_isSaleLive;
    }
    
    function changeMinInvest(uint256 value) external onlyOwner {
        MIN_INVEST = value;
    }
    
    function changeMaxInvest(uint256 value) external onlyOwner {
        MAX_INVEST = value;
    }
    
    function changeUDERate(uint256 value) external onlyOwner {
        _udeRate = value;
    }
    
    function changeUDE(IBEP20 ude) external onlyOwner {
        UDE = ude;
    }
    
    function changeBUSD(IBEP20 busd) external onlyOwner {
        BUSD = busd;
    }
    
    function changeInterval(uint256 value) external onlyOwner {
        _lockedInterval = value;
    }
    
    function getTotalInvestment() external view returns (uint) {
        return _allInvestments.length;
    }
    
    function getInvestments(address _holder) external view returns (uint) {
        return _investors[_holder].length;
    }
    
    function _getBNBRate() internal view returns (uint256) {
        (uint256 res1, uint256 res2, ) = _bnbPair.getReserves();
        return res2.mul(1e18).div(res1);
    }
    
    function getBNBRate() external view returns (uint256) {
        return _getBNBRate();
    }
    
    function _getUDEValue(uint256 _busdValue) internal view returns (uint256) {
        return (_busdValue.mul(1e18).div(_udeRate));
    }
    
    function getUDEValue(uint256 _busdValue) external view returns (uint256) {
        return _getUDEValue(_busdValue);
    }
    
    function _transferUDE(uint256 _busdValue, address _udeHolder, bool _isBNB) internal onlyWhenSaleIsLive {
        uint256 _udeToSend = _getUDEValue(_busdValue);
        uint256 _udeSent = _udeToSend.mul(_initialReturn).div(1e2);
        UDE.safeTransfer(_udeHolder, _udeSent);
        uint256 udeStaked = _udeToSend.sub(_udeSent);
        
        _totalInvestment[_udeHolder] = _totalInvestment[_udeHolder].add(_busdValue);
        Investments memory _investment = Investments(
            _udeHolder,
            _udeToSend,
            _busdValue,
            _isBNB
        );
        _invested[_udeHolder]._investor = _udeHolder;
        _invested[_udeHolder]._udeAmount = _invested[_udeHolder]._udeAmount.add(_udeToSend);
        _invested[_udeHolder]._udeClaimed = _invested[_udeHolder]._udeClaimed.add(_udeSent);
        _invested[_udeHolder]._udeStaked = _invested[_udeHolder]._udeStaked.add(udeStaked);
        _invested[_udeHolder]._busdAmount = _invested[_udeHolder]._busdAmount.add(_busdValue);
        _invested[_udeHolder]._lastClaimed = block.timestamp;
        _invested[_udeHolder]._lastInvested = block.timestamp;
        
        _investors[_udeHolder].push(_investment);
        _allInvestments.push(_investment);
        
        if(_isBNB){
            _bnbRaised = _bnbRaised.add(_busdValue.mul(1e18).div(_getBNBRate()));
        }
        else {
            _busdValue = _busdRaised.add(_busdValue);
        }
        _udeSold = _udeSold.add(_udeToSend);
        _udeSell = _udeSell.add(_udeSent);
        
        emit UDETransferred(_udeHolder, _udeToSend);
    }
    
    function checkInvestValue(uint256 value) internal view returns (bool) {
        bool _returned = (value >= MIN_INVEST && value <= MAX_INVEST);
        require(_returned, '[!] Check minimum and maximum amount to invest');
    }
    
    function checkInvestment(address _udeHolder, uint256 _nowInvesting) internal view returns (bool) {
        uint256 _investment = _totalInvestment[_udeHolder];
        require(_investment.add(_nowInvesting) <= MAX_INVEST, '[!] Investment from a particular exceeds max investment allowed');
    }
    
    function investBNB() external payable {
        uint256 bnbInvesting = msg.value;
        checkInvestValue(bnbInvesting.mul(_getBNBRate()).div(1e18));
        checkInvestment(msg.sender, (bnbInvesting.mul(_getBNBRate())).div(1e18));
        _transferUDE((bnbInvesting.mul(_getBNBRate()).div(1e18)), msg.sender, true);
    }
    
    function investBUSD(uint256 _amount) external {
        uint256 busdInvesting = _amount;
        checkInvestValue(busdInvesting);
        checkInvestment(msg.sender, busdInvesting);
        BUSD.safeTransferFrom(msg.sender, address(this), _amount);
        _transferUDE(busdInvesting, msg.sender, false);
    }
    
    function claimBNB() external onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
    
    function claimBUSD() external onlyOwner {
        BUSD.safeTransfer(msg.sender, BUSD.balanceOf(address(this)));
    }
    
    // Section for locked assets claim after MIN Interval Period of Time with return % of the staked Assets
    
    function _canClaimInvestor(address _investor) internal view returns (bool) {
        uint lastClaimed = _invested[_investor]._lastClaimed;
        return lastClaimed.add(_lockedInterval) <= block.timestamp;
    }
    
    function canClaimInvestor(address _investor) external view returns (bool) {
        return _canClaimInvestor(_investor);
    }
    
    function _hasStakedAssets(address _investor) internal view returns (bool) {
        uint256 udeStaked = _invested[_investor]._udeStaked;
        return udeStaked > 0;
    }
    
    function initClaimFor(address _investor) internal {
        uint256 invested = _invested[_investor]._udeAmount;
        uint256 toClaim = invested.mul(_initialReturn).div(1e2);
        uint256 staked = _invested[_investor]._udeStaked;
        UDE.safeTransfer(_investor, toClaim);
        if(toClaim > staked) {
            _invested[_investor]._udeStaked = 0;
        }
        else {
            _invested[_investor]._udeStaked = _invested[_investor]._udeStaked.sub(toClaim);
        }
        _invested[_investor]._udeClaimed = _invested[_investor]._udeClaimed.add(toClaim);
        _invested[_investor]._lastClaimed = block.timestamp;
        _udeSell = _udeSell.add(toClaim);
        emit UDETransferred(_investor, toClaim);
    }
    
    function claimLockedAssets() external {
        require(_canClaimInvestor(msg.sender), '[~] Cannot claim in locked time interval');
        require(_hasStakedAssets(msg.sender), '[!] No Staked UDE Found');
        initClaimFor(msg.sender);
    }
    
    function initClaimFromOwner(address _investor) external onlyOwner {
        initClaimFor(_investor);
    }
    
    // Emergency and Seed Sale Remaining Tokens
    
    function transferAnyUDE(uint256 _amount) external onlyOwner {
        UDE.safeTransfer(msg.sender, _amount);
    }
    
    function transferUnSoldUDE() external onlyOwner {
        UDE.safeTransfer(msg.sender, UDE.balanceOf(address(this)).sub(_udeSold.sub(_udeSell)));
    }
}