// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IRebaseToken is IERC20 {
    function rebase(
        uint256 epoch,
        uint256 numerator,
        uint256 denominator
    ) external returns (uint256);
}

interface IUniswapV2Pair {
    function sync() external;
}

contract UniPriceRebaseInvoker is Ownable {
    using SafeMath for uint256;

    uint256 private _epoch;
    uint256 private _startTime;
    uint256 private _interval;

    uint256 private _targetPrice;
    uint256 private _minPrice;
    uint256 private _maxPrice;

    IRebaseToken private _token;
    IERC20 private _usdt;
    IERC20 private _eth;

    IUniswapV2Pair private _tokenUsdtPair;
    IUniswapV2Pair private _tokenEthPair;
    IUniswapV2Pair private _ethUsdtPair;

    modifier onlyCanRebase() {
        uint256 epoch = currentEpoch();
        require(epoch > _epoch, "Rebase: current epoch is rebased");
        if (owner() != address(0x0)) {
            require(owner() == _msgSender(), "Rebase: caller is not the owner");
        }
        _;
    }

    constructor() public {
        _startTime = 1599004800;
        _interval = 86400;

        _targetPrice = 10**6;
        _minPrice = 96 * 10**4;
        _maxPrice = 106 * 10**4;

        _token = IRebaseToken(
            address(0x95DA1E3eECaE3771ACb05C145A131Dca45C67FD4)
        );
        _usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        _eth = IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

        _tokenUsdtPair = IUniswapV2Pair(
            address(0xFBC57CE413631dd910457f4476AFAC4D8590dA00)
        );

        _tokenEthPair = IUniswapV2Pair(
            address(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852)
        );

        _ethUsdtPair = IUniswapV2Pair(
            address(0xFBC57CE413631dd910457f4476AFAC4D8590dA00)
        );
    }

    function epoch() public view returns (uint256) {
        return _epoch;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function interval() public view returns (uint256) {
        return _interval;
    }

    function targetPrice() public view returns (uint256) {
        return _targetPrice;
    }

    function minPrice() public view returns (uint256) {
        return _minPrice;
    }

    function maxPrice() public view returns (uint256) {
        return _maxPrice;
    }

    function token() public view returns (IRebaseToken) {
        return _token;
    }

    function usdt() public view returns (IERC20) {
        return _usdt;
    }

    function eth() public view returns (IERC20) {
        return _eth;
    }

    function tokenUsdtPair() public view returns (IUniswapV2Pair) {
        return _tokenUsdtPair;
    }

    function tokenEthPair() public view returns (IUniswapV2Pair) {
        return _tokenEthPair;
    }

    function ethUsdtPair() public view returns (IUniswapV2Pair) {
        return _ethUsdtPair;
    }

    function currentEpoch() public view returns (uint256) {
        return now.sub(_startTime).div(_interval);
    }

    function ethToUsdt(uint256 amount) public view returns (uint256) {
        uint256 usdtAmount = _usdt.balanceOf(address(_ethUsdtPair));
        uint256 ethAmount = _eth.balanceOf(address(_ethUsdtPair));
        return amount.mul(usdtAmount).mul(10**12).div(ethAmount);
    }

    function getPrice() public view returns (uint256) {
        uint256 usdtAmount = _usdt.balanceOf(address(_tokenUsdtPair));
        uint256 tokenAmount = _token.balanceOf(address(_tokenUsdtPair));

        usdtAmount = usdtAmount.add(
            ethToUsdt(_eth.balanceOf(address(_tokenEthPair)))
        );
        tokenAmount = tokenAmount.add(_token.balanceOf(address(_tokenEthPair)));
        return usdtAmount.mul(10**12).mul(_targetPrice).div(tokenAmount);
    }

    function _rebase(uint256 rebaseEepoch) private {
        uint256 price = getPrice();
        if (price >= _minPrice && price <= _maxPrice) {
            return;
        }
        uint256 denumerator = _targetPrice;
        if (price > _targetPrice) {
            denumerator = _targetPrice.add(
                price.sub(_targetPrice).mul(10).div(100)
            );
        } else {
            denumerator = _targetPrice.sub(
                _targetPrice.sub(price).mul(10).div(100)
            );
        }
        _token.rebase(rebaseEepoch, _targetPrice, denumerator);
        _tokenUsdtPair.sync();
        _tokenEthPair.sync();
    }

    function rebase() external onlyCanRebase {
        uint256 rebaseEepoch = currentEpoch();
        _rebase(rebaseEepoch);
        _epoch = rebaseEepoch;
    }
}