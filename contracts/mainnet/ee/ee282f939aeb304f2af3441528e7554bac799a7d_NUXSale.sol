/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface INUXAsset {
    function availableBalanceOf(address _holder) external view returns(uint);
    function scheduleReleaseStart() external;
    function transferLock(address _to, uint _value) external;
    function publicSaleTransferLock(address _to, uint _value) external;
    function locked(address _holder) external view returns(uint, uint);
    function preSaleScheduleReleaseStart() external;
    function preSaleTransferLock(address _to, uint _value) external;
}

contract NUXConstants {
    uint constant NUX = 10**18;
}

contract Readable {
    function since(uint _timestamp) internal view returns(uint) {
        if (not(passed(_timestamp))) {
            return 0;
        }
        return block.timestamp - _timestamp;
    }

    function passed(uint _timestamp) internal view returns(bool) {
        return _timestamp < block.timestamp;
    }

    function not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }
}

library ExtraMath {
    function toUInt32(uint _a) internal pure returns(uint32) {
        require(_a <= uint32(-1), 'uint32 overflow');
        return uint32(_a);
    }

    function toUInt40(uint _a) internal pure returns(uint40) {
        require(_a <= uint40(-1), 'uint40 overflow');
        return uint40(_a);
    }

    function toUInt64(uint _a) internal pure returns(uint64) {
        require(_a <= uint64(-1), 'uint64 overflow');
        return uint64(_a);
    }

    function toUInt128(uint _a) internal pure returns(uint128) {
        require(_a <= uint128(-1), 'uint128 overflow');
        return uint128(_a);
    }
}

contract NUXSale is Ownable, NUXConstants, Readable {
    using SafeERC20 for IERC20;
    using ExtraMath for *;
    using SafeMath for *;
    INUXAsset public NUXAsset;
    address payable public treasury;


    struct State {
        uint32 etherPriceUSD;
        uint40 minimumDepositUSD;
        uint40 maximumDepositUSD;
        uint64 totalDepositedInUSD;
        uint32 nextDepositId;
        uint32 clearedDepositId;
    }
    State private _state;
    mapping(uint => Deposit) public deposits;

    uint public constant SALE_START = 1612278000; // Tuesday, February 2, 2021 3:00:00 PM UTC
    uint public constant SALE_END = SALE_START + 84 hours; // Saturday, February 6, 2021 3:00:00 PM UTC

    struct Deposit {
        address payable user;
        uint amount;
        uint clearing1;
        uint clearing2;
        uint clearing3;
        uint clearing4;
    }

    event DepositEvent(address _from, uint _value);
    event ETHReturned(address _to, uint _amount);
    event ETHPriceSet(uint _usdPerETH);
    event Cleared();
    event ClearingPaused(uint _lastDepositId);
    event TreasurySet(address _treasury);

    modifier onlyTreasury {
        require(msg.sender == treasury, 'Only treasury');
        _;
    }

    constructor(INUXAsset _nux, address payable _treasury) public {
        NUXAsset = _nux;
        treasury = _treasury;
    }

    function etherPriceUSD() public view returns(uint) {
        return _state.etherPriceUSD;
    }

    function minimumDepositUSD() public view returns(uint) {
        return _state.minimumDepositUSD;
    }

    function maximumDepositUSD() public view returns(uint) {
        return _state.maximumDepositUSD;
    }

    function totalDepositedInUSD() public view returns(uint) {
        return _state.totalDepositedInUSD;
    }

    function nextDepositId() public view returns(uint) {
        return _state.nextDepositId;
    }

    function clearedDepositId() public view returns(uint) {
        return _state.clearedDepositId;
    }

    function setETHPrice(uint _usdPerETH) public onlyOwner {
        State memory state = _state;
        require(state.etherPriceUSD == 0, 'Already set');
        state.etherPriceUSD = _usdPerETH.toUInt32();
        state.minimumDepositUSD = (_usdPerETH / 10).toUInt40(); // 0.1 ETH
        state.maximumDepositUSD = (50 * _usdPerETH).toUInt40(); // 50 ETH
        _state = state;
        emit ETHPriceSet(_usdPerETH);
    }

    function setTreasury(address payable _treasury) public onlyOwner {
        require(_treasury != address(0), 'Zero address not allowed');
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    function saleStarted() public view returns(bool) {
        return passed(SALE_START);
    }

    function tokensSold() public view returns(uint) {
        return totalDepositedInUSD() * NUX / getSalePrice();
    }

    function saleEnded() public view returns(bool) {
        return passed(SALE_END) || _isTokensSold(getSalePrice(), totalDepositedInUSD());
    }

    function _saleEnded(uint _salePrice, uint _totalDeposited) private view returns(bool) {
        return passed(SALE_END) || _isTokensSold(_salePrice, _totalDeposited);
    }

    function ETHToUSD(uint _value) public view returns(uint) {
        return _ETHToUSD(_value, etherPriceUSD());
    }

    function _ETHToUSD(uint _value, uint _etherPrice) private pure returns(uint) {
        return (_value * _etherPrice) / 1 ether;
    }

    function USDtoETH(uint _value) public view returns(uint) {
        return (_value * 1 ether) / etherPriceUSD();
    }

    function USDToNUX(uint _value) public view returns(uint) {
        return (_value * NUX) / getSalePrice();
    }

    function NUXToUSD(uint _value) public view returns(uint) {
        return (_value * getSalePrice()) / NUX;
    }

    function ETHToNUX(uint _value) public view returns(uint) {
        return _ETHToNUX(_value, etherPriceUSD(), getSalePrice());
    }

    function NUXToETH(uint _value) public view returns(uint) {
        return _NUXToETH(_value, etherPriceUSD(), getSalePrice());
    }

    function _ETHToNUX(uint _value, uint _ethPrice, uint _salePrice) private pure returns(uint) {
        return _value * _ethPrice / _salePrice;
    }

    function _NUXToETH(uint _value, uint _ethPrice, uint _salePrice) private pure returns(uint) {
        return _value * _salePrice / _ethPrice;
    }

    function getSalePrice() public view returns(uint) {
        return _getSalePrice(totalDepositedInUSD());
    }

    function _getSalePrice(uint _totalDeposited) private view returns(uint) {
        if (_isTokensSold(2500000, _totalDeposited) || not(passed(SALE_START + 12 hours))) {
            return 2500000; // 2.5 USD
        } else if (_isTokensSold(1830000, _totalDeposited) || not(passed(SALE_START + 24 hours))) {
            return 1830000; // 1.83 USD
        } else if (_isTokensSold(1350000, _totalDeposited) || not(passed(SALE_START + 36 hours))) {
            return 1350000; // 1.35 USD
        } else if (_isTokensSold(990000, _totalDeposited) || not(passed(SALE_START + 48 hours))) {
            return 990000; // 0.99 USD
        } else if (_isTokensSold(730000, _totalDeposited) || not(passed(SALE_START + 60 hours))){
            return 730000; // 0.73 USD
        } else if (_isTokensSold(530000, _totalDeposited) || not(passed(SALE_START + 72 hours))) {
            return 530000; // 0.53 USD
        } else {
            return 350000; // 0.35 USD
        }
    }

    function _isTokensSold(uint _price, uint _totalDeposited) internal pure returns(bool) {
        return ((_totalDeposited * NUX) / _price) >= (4000000 * NUX);
    }

    function () external payable {
        if (msg.sender == treasury) {
            return;
        }
        _deposit();
    }

    function depositETH() public payable {
        _deposit();
    }

    function _deposit() internal {
        State memory state = _state;
        treasury.transfer(msg.value);
        uint usd = _ETHToUSD(msg.value, state.etherPriceUSD);
        require(saleStarted(), 'Public sale not started yet');
        require(not(_saleEnded(_getSalePrice(state.totalDepositedInUSD), state.totalDepositedInUSD)), 'Public sale already ended');
        require(usd >= uint(state.minimumDepositUSD), 'Minimum deposit not met');
        require(usd <= uint(state.maximumDepositUSD), 'Maximum deposit reached');

        deposits[state.nextDepositId] = Deposit(msg.sender, msg.value, 1, 1, 1, 1);
        state.nextDepositId = (state.nextDepositId.add(1)).toUInt32();

        state.totalDepositedInUSD = (state.totalDepositedInUSD.add(usd)).toUInt64();
        _state = state;
        emit DepositEvent(msg.sender, msg.value);
    }

    function clearing() public onlyOwner {
        State memory state = _state;
        uint salePrice = _getSalePrice(state.totalDepositedInUSD);
        require(_saleEnded(salePrice, state.totalDepositedInUSD), 'Public sale not ended yet');
        require(state.nextDepositId > state.clearedDepositId, 'Clearing finished');
        INUXAsset nuxAsset = NUXAsset;

        (, uint lockedBalance) = nuxAsset.locked(address(this));
        for (uint i = state.clearedDepositId; i < state.nextDepositId; i++) {
            if (gasleft() < 500000) {
                state.clearedDepositId = i.toUInt32();
                _state = state;
                emit ClearingPaused(i);
                return;
            }
            Deposit memory deposit = deposits[i];
            delete deposits[i];

            uint nux = _ETHToNUX(deposit.amount, state.etherPriceUSD, salePrice);
            if (lockedBalance >= nux) {
                nuxAsset.publicSaleTransferLock(deposit.user, nux);
                lockedBalance = lockedBalance - nux;
            } else if (lockedBalance > 0) {
                nuxAsset.publicSaleTransferLock(deposit.user, lockedBalance);
                uint tokensLeftToETH = nux - lockedBalance;
                uint ethAmount = _NUXToETH(tokensLeftToETH, state.etherPriceUSD, salePrice);
                lockedBalance = 0;
                deposit.user.transfer(ethAmount);
                emit ETHReturned(deposit.user, ethAmount);
            } else {
                deposit.user.transfer(deposit.amount);
                emit ETHReturned(deposit.user, deposit.amount);
            }
        }
        state.clearedDepositId = state.nextDepositId;

        if (lockedBalance > 0) {
            nuxAsset.publicSaleTransferLock(address(0), lockedBalance);
        }

        _state = state;
        emit Cleared();
    }

    function recoverTokens(IERC20 _token, address _to, uint _value) public onlyTreasury {
        _token.safeTransfer(_to, _value);
    }

    function recoverETH() public onlyTreasury {
        treasury.transfer(address(this).balance);
    }

}