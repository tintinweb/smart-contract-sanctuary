/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * block.timestamp has built in overflow checking.
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
        return msg.data;
    }
}


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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;


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


interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _newThresholdADesired,
        uint256 _newThresholdBDesired,
        uint256 _newThresholdAMin,
        uint256 _newThresholdBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 _newThresholdA,
            uint256 _newThresholdB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 _newThresholdTokenDesired,
        uint256 _newThresholdTokenMin,
        uint256 _newThresholdETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 _newThresholdToken,
            uint256 _newThresholdETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 _newThresholdAMin,
        uint256 _newThresholdBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 _newThresholdA, uint256 _newThresholdB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 _newThresholdTokenMin,
        uint256 _newThresholdETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 _newThresholdToken, uint256 _newThresholdETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 _newThresholdAMin,
        uint256 _newThresholdBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 _newThresholdA, uint256 _newThresholdB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 _newThresholdTokenMin,
        uint256 _newThresholdETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 _newThresholdToken, uint256 _newThresholdETH);

    function swapExactTokensForTokens(
        uint256 _newThresholdIn,
        uint256 _newThresholdOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _newThresholds);

    function swapTokensForExactTokens(
        uint256 _newThresholdOut,
        uint256 _newThresholdInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _newThresholds);

    function swapExactETHForTokens(
        uint256 _newThresholdOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory _newThresholds);

    function swapTokensForExactETH(
        uint256 _newThresholdOut,
        uint256 _newThresholdInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _newThresholds);

    function swapExactTokensForETH(
        uint256 _newThresholdIn,
        uint256 _newThresholdOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _newThresholds);

    function swapETHForExactTokens(
        uint256 _newThresholdOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory _newThresholds);

    function quote(
        uint256 _newThresholdA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 _newThresholdB);

    function get_newThresholdOut(
        uint256 _newThresholdIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 _newThresholdOut);

    function get_newThresholdIn(
        uint256 _newThresholdOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 _newThresholdIn);

    function get_newThresholdsOut(uint256 _newThresholdIn, address[] calldata path)
        external
        view
        returns (uint256[] memory _newThresholds);

    function get_newThresholdsIn(uint256 _newThresholdOut, address[] calldata path)
        external
        view
        returns (uint256[] memory _newThresholds);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 _newThresholdTokenMin,
        uint256 _newThresholdETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 _newThresholdETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 _newThresholdTokenMin,
        uint256 _newThresholdETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 _newThresholdETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 _newThresholdIn,
        uint256 _newThresholdOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 _newThresholdOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 _newThresholdIn,
        uint256 _newThresholdOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

pragma solidity ^0.8.0;

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 _newThreshold0, uint256 _newThreshold1);
    event Burn(
        address indexed sender,
        uint256 _newThreshold0,
        uint256 _newThreshold1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 _newThreshold0In,
        uint256 _newThreshold1In,
        uint256 _newThreshold0Out,
        uint256 _newThreshold1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 _newThreshold0, uint256 _newThreshold1);

    function swap(
        uint256 _newThreshold0Out,
        uint256 _newThreshold1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // // calculates the CREATE2 address for a pair without making any external calls
    // function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    //     (address token0, address token1) = sortTokens(tokenA, tokenB);
    //     pair = address(uint(keccak256(abi.encodePacked(
    //             hex'ff',
    //             factory,
    //             keccak256(abi.encodePacked(token0, token1)),
    //             hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
    //         ))));
    // }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        address pair = IPancakeFactory(factory).getPair(token0, token1);
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        //uint256 twos = -denominator & denominator;
        
        //fix from stack overflow: https://ethereum.stackexchange.com/a/96646
        uint256 twos = denominator & (~denominator + 1);
        
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function withdraw(uint wad) external;
}

interface IPancakeMasterChef {
    event Deposit( address indexed user,uint256 indexed pid,uint256 amount ) ;
    event EmergencyWithdraw( address indexed user,uint256 indexed pid,uint256 amount ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event Withdraw( address indexed user,uint256 indexed pid,uint256 amount ) ;
    function BONUS_MULTIPLIER(  ) external view returns (uint256 ) ;
    function add( uint256 _allocPoint,address _lpToken,bool _withUpdate ) external   ;
    function cake(  ) external view returns (address ) ;
    function cakePerBlock(  ) external view returns (uint256 ) ;
    function deposit( uint256 _pid,uint256 _amount ) external   ;
    function dev( address _devaddr ) external   ;
    function devaddr(  ) external view returns (address ) ;
    function emergencyWithdraw( uint256 _pid ) external   ;
    function enterStaking( uint256 _amount ) external   ;
    function getMultiplier( uint256 _from,uint256 _to ) external view returns (uint256 ) ;
    function leaveStaking( uint256 _amount ) external   ;
    function massUpdatePools(  ) external   ;
    function migrate( uint256 _pid ) external   ;
    function migrator(  ) external view returns (address ) ;
    function owner(  ) external view returns (address ) ;
    function pendingCake( uint256 _pid,address _user ) external view returns (uint256 ) ;
    function poolInfo( uint256 poolId ) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare) ;
    function poolLength(  ) external view returns (uint256 ) ;
    function renounceOwnership(  ) external   ;
    function set( uint256 _pid,uint256 _allocPoint,bool _withUpdate ) external   ;
    function setMigrator( address _migrator ) external   ;
    function startBlock(  ) external view returns (uint256 ) ;
    function syrup(  ) external view returns (address ) ;
    function totalAllocPoint(  ) external view returns (uint256 ) ;
    function transferOwnership( address newOwner ) external   ;
    function updateMultiplier( uint256 multiplierNumber ) external   ;
    function updatePool( uint256 _pid ) external   ;
    function userInfo( uint256 ,address  ) external view returns (uint256 amount, uint256 rewardDebt) ;
    function withdraw( uint256 _pid,uint256 _amount ) external   ;
}

//=========================================================================================


contract A_SmartStakeCore is Ownable, Pausable {
    //
    // IMPORTS
    //
    
    using SafeMath for uint256;
    using FullMath for uint256;
    
    //
    // PROPERTIES
    //

    uint256 constant private _max = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    address payable public _smartStakeAgentAddress;
    uint256 public _wethDepositThreshold;

    uint256 public _gasFeeAmount;
    uint256 public _gasFeeAmountFactor;
    
    uint256 public _pcsV2TransactionExpirySeconds;
    IPancakeRouter02 public _pcsV2Router;
    IPancakeMasterChef public _pcsV2MasterChef;

    mapping (address => bool) private _whitelistAddresses;
    bool public _whitelistEnabled;
    
    uint constant public _farmsTotal = 50;
    uint public _farmsActive;
    uint256[_farmsTotal] public _farms;

    uint256 private _fundSharesTotal;
    mapping (address => uint256) private _fundShares;
    mapping (address => uint256) private _depositedBnb;
    bool public _fundReconcileOnDeposit; //enables deposits to auto harvest cake and reinvest
    bool public _fundReconcileOnWithdraw; //eables withdrawls to auto harvest cake and reinvest
    uint256 public _fundLastReconciledTimestamp; 
    uint256 private _fundTotalValueLocked;
    
    struct PortfolioInfo {
        uint256 totalValueLocked;
        uint256 totalPendingValue; 
        uint256 netAssetValue;
        uint256 totalShares;
        uint256 depositedBnb; 
        
        address walletAddress;
        uint256 walletShares; 
        uint256 walletValue;
    }
    
    event BnbWithdrawn(address destination, uint256 amount);
    event BaseTokensWithdrawn(address destination, uint256 amount);
    event StakeDeposit(address depositor, address assignTo, uint256 principal, uint256 fee, uint256 shares);

    constructor() {
        //set agent address to owner by default
        _smartStakeAgentAddress = payable(0x2AA952C42aBF8CbeB7c6123e8A0A82033E614711);
        
        //create a uniswap pair for this new token
        _pcsV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _pcsV2MasterChef = IPancakeMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
        _pcsV2TransactionExpirySeconds = 300; //5 minutes

        //_wethDepositThreshold = 1000000000000000000;
        _wethDepositThreshold = 25000000000000;

        //set up fees
        _gasFeeAmount = 15;
        _gasFeeAmountFactor = 1000;

        //set up fund
        _fundTotalValueLocked = 0;
        _fundSharesTotal = 0;
        _fundReconcileOnDeposit = true;
        _fundReconcileOnWithdraw = true;

        //enable whitelist
        _whitelistEnabled = true;
        _whitelistAddresses[owner()] = true;
    }
    
    //
    // PUBLIC FUNCTIONS
    //

    function getLiquidityValue(address tokenA, address tokenB, uint256 liquidityAmount ) public view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        IPancakeFactory factory = IPancakeFactory(_pcsV2Router.factory());
        (uint256 reservesA, uint256 reservesB) = PancakeLibrary.getReserves(_pcsV2Router.factory(), tokenA, tokenB);
        IPancakePair pair = IPancakePair(factory.getPair(tokenA, tokenB));
        bool feeOn = IPancakeFactory(factory).feeTo() != address(0);
        uint kLast = feeOn ? pair.kLast() : 0;
        uint totalSupply = pair.totalSupply();
        
        if (feeOn && kLast > 0) {
            uint rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            uint rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator1 = totalSupply;
                uint numerator2 = rootK.sub(rootKLast);
                uint denominator = rootK.mul(5).add(rootKLast);
                uint feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }
        return (reservesA.mulDiv(liquidityAmount, totalSupply), reservesB.mulDiv(liquidityAmount, totalSupply));
    }


    function getTokenContractBalance(address tokenAddress) external view returns(uint256) {
        return IBEP20(tokenAddress).balanceOf(address(this));
    }

    function getCakeBalance() internal view returns (uint256 cakeValue, uint256 bnbValue) {
        uint256 totalCake = 0;
        for (uint i = 0; i < _farmsTotal; i++) {
            if (_farms[i] > 0) {
                totalCake += _pcsV2MasterChef.pendingCake(_farms[i], address(this));
            }
        }

        uint256 totalBnb = 0;
        if (totalCake > 0) {
            IPancakePair cakeBnbPair = IPancakePair(IPancakeFactory(_pcsV2Router.factory()).getPair(_pcsV2MasterChef.cake(), _pcsV2Router.WETH()));
            (uint256 tokenAReserves, uint256 tokenBReserves,) = cakeBnbPair.getReserves();
            totalBnb = PancakeLibrary.quote(totalCake, tokenBReserves, tokenAReserves);
        }

        return (totalCake, totalBnb);
    }

    function getPortfolioAssetBalance() internal view returns (uint256 bnbValue) {
        uint256 bnbVal = 0;
        for (uint i = 0; i < _farmsTotal; i++) {
            if (_farms[i] > 0) {
                //get lp token contract
                (address lpPairAddress,,,) = _pcsV2MasterChef.poolInfo(_farms[i]);
                IPancakePair lpPair = IPancakePair(lpPairAddress);
                
                //retrieve pair address for LP token from masterchef
                (uint256 lockedLpBalance,) = _pcsV2MasterChef.userInfo(_farms[i], address(this));
                
                //check for lp balance on lp contract and add to masterchef locked amount
                uint256 lpBalance = lpPair.balanceOf(address(this));
                lpBalance += lockedLpBalance;
                
                //calculate bnb value
                if (lpBalance > 0) {
                    (uint256 tokenAAmount, uint256 tokenBAmount) = getLiquidityValue(lpPair.token0(), lpPair.token1(), lpBalance);
                    (uint256 tokenAReserves, uint256 tokenBReserves,) = lpPair.getReserves();

                    if (lpPair.token0() == _pcsV2Router.WETH()) { 
                        bnbVal += tokenAAmount; 
                        bnbVal += PancakeLibrary.quote(tokenBAmount, tokenBReserves, tokenAReserves);
                    }
                    else if (lpPair.token1() == _pcsV2Router.WETH()) {
                        bnbVal += tokenBAmount; 
                        bnbVal += PancakeLibrary.quote(tokenAAmount, tokenAReserves, tokenBReserves);
                    }
                }
            }
        }
        
        return bnbVal;
    }

    function getPortfolio(address wallet) public view returns(PortfolioInfo memory portfolio) {
        (,uint256 pendingCakeInBnb) = getCakeBalance();
        
        PortfolioInfo memory p;
        p.totalValueLocked = getPortfolioAssetBalance();
        p.totalPendingValue = pendingCakeInBnb; 
        p.netAssetValue = p.totalValueLocked.add(pendingCakeInBnb);
        p.depositedBnb = _depositedBnb[wallet]; 
        p.totalShares = _fundSharesTotal;

        p.walletAddress = wallet;
        if (p.totalShares > 0) {
            p.walletShares = _fundShares[wallet];
            p.walletValue = p.netAssetValue.mulDiv(p.totalShares, p.walletShares);
        }
        
        return p;
    }

    function getFundSharesForAddress(address depositor) external view returns (uint256 shares, uint256 totalShares) {
        return (_fundShares[depositor], _fundSharesTotal);
    }

    function stake(address assignTo) public payable whenNotPaused {
        if (_whitelistEnabled == true) {
            require(_whitelistAddresses[msg.sender] == true, "Sender is not whitelisted.");
        }
        require(msg.value >= _wethDepositThreshold, "Amount does not meet minimum investment threshold.");
        
        //send % to smart stake agent for fees
        uint256 feeAmount = msg.value.mulDiv(_gasFeeAmount, _gasFeeAmountFactor);
        (bool success,) = _smartStakeAgentAddress.call{value: feeAmount}("");
        require(success == true, "Failed to transfer fee.");

        //take remaining amount for depositing into smart stake
        uint256 depositAmount = msg.value - feeAmount;
        
        //calculate and increment shares based on liquidity added
        uint256 tvl = getPortfolioAssetBalance();
        (,uint256 tpv) = getCakeBalance();
        uint256 nav = tvl.add(tpv);

        // (,,uint256 netAssetValue) = getPortfolio(address(this));
        uint256 newShareAmount;
        if (_fundSharesTotal == 0) { newShareAmount = 10000; }
        else { newShareAmount = depositAmount.mulDiv(newShareAmount, nav); }
        _depositedBnb[assignTo] += depositAmount;
        _fundShares[assignTo] += newShareAmount;
        _fundSharesTotal += newShareAmount;
        // _fundTotalValueLocked += depositAmount;

        //harvest cake and reinvest
        if (_fundReconcileOnDeposit == true) {
            reconcileInternal(depositAmount);
        } else {
            invest(depositAmount);
        }

        //send event with result
        emit StakeDeposit(msg.sender, assignTo, depositAmount, feeAmount, newShareAmount);
    }

    function unstake(uint256 shares, address wallet) public {
        address outputAddress = wallet;
        uint256 walletShareBalance = _fundShares[outputAddress];
        require(shares > 0 && shares <= _fundSharesTotal && shares <= walletShareBalance, "Invalid number of shares specified.");

        //calculate ratio of total portfolio to liquidate
        uint256 unstakeRatio = shares.mul(_fundSharesTotal);
        uint256 unstakeBnb = 0;
        
        //harvest any cake
        if (_fundReconcileOnWithdraw == true) {
            reconcileInternal(0);
        }
        
        //unstake from each farm proportionally using the unstakeRatio
        for (uint i = 0; i < _farmsTotal; i++) {
            if (_farms[i] > 0) {
                //get farm details
                (uint256 lockedLpBalance,) = _pcsV2MasterChef.userInfo(_farms[i], address(this));
                
                //only withdraw from farms that have tokens
                if (lockedLpBalance > 0) {
                    (address lpPairAddress,,,) = _pcsV2MasterChef.poolInfo(_farms[i]);
                    IPancakePair lpPair = IPancakePair(lpPairAddress);
                    
                    //calculate amount and withdraw
                    uint256 lpToWithdraw = lockedLpBalance.mul(unstakeRatio);
                    _pcsV2MasterChef.withdraw(_farms[i], lpToWithdraw);
                    
                    //remove liquidity
                    (uint256 amountLiquidated) = _pcsV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(address(lpPair), lpToWithdraw, 0, 0, outputAddress, block.timestamp + _pcsV2TransactionExpirySeconds);
                    unstakeBnb += amountLiquidated;
                }
            }
        }
        
        //update portfolio amounts
        _depositedBnb[msg.sender] -= unstakeBnb;
        _fundSharesTotal -= shares;
    }

    function reconcile() public {
        reconcileInternal(0);
    }

    //
    // INTERNAL FUNCTIONS
    //

    function reconcileInternal(uint256 amount) internal {
        uint256 balance = amount;

        //harvest cake
        for (uint i = 0; i < _farmsTotal; i++) {
            if (_farms[i] > 0) {
                uint256 pendingCake = _pcsV2MasterChef.pendingCake(_farms[i], address(this));
                if (pendingCake > 0) { 
                    //there's no explicit harvest function, instead you deposit 0
                    _pcsV2MasterChef.deposit(_farms[i], 0); 
                }
            }
        }

        //liquidate tokens and add to balance to invest
        IBEP20 cake = IBEP20(_pcsV2MasterChef.cake());
        if (cake.balanceOf(address(this)) > 0) {
            uint256 bnbBefore = address(this).balance;
            liquidateTokensForETH(cake, 0);
            uint256 bnbAfter = address(this).balance;
            uint256 newBnb = bnbAfter-bnbBefore;
            balance += newBnb;
        }

        //only invest if we have had a deposit or harvest
        if (balance > 0) {
            invest(balance);
        }

        //update last reconciled timestamp
        _fundLastReconciledTimestamp = block.timestamp;
    }

    function invest(uint256 amount) internal {
        //check to see if there are farms to invest in
        require(_farmsActive > 0, "There are no active farms to invest in.");

        //calculate investment
        uint256 investmentPortionAmount = amount.div(_farmsActive);
        
        //invest in each farm
        for (uint i = 0; i < _farmsTotal; i++) {
            if (_farms[i] > 0) {
                (address lpPairAddress,,,) = _pcsV2MasterChef.poolInfo(_farms[i]);
                
                //convert portion to LP tokens
                uint256 liquidity = buyLpTokens(lpPairAddress, investmentPortionAmount);
                
                //deposit into LP pool
                IBEP20 token = IBEP20(lpPairAddress);
                if (token.allowance(address(this), address(_pcsV2Router)) < liquidity) {
                    token.approve(address(_pcsV2MasterChef), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                }

                _pcsV2MasterChef.deposit(_farms[i], liquidity);
            }
        }
    }

    function buyLpTokens(address pairTokenAddress, uint256 amount) internal returns (uint256 lpTokens){
        require(amount > 0, "Requested amount must be greater than 0.");
        IPancakePair lpPair = IPancakePair(pairTokenAddress);
        IBEP20 token;
        if (lpPair.token0() == _pcsV2Router.WETH()) { token = IBEP20(lpPair.token1()); }
        else { token = IBEP20(lpPair.token0()); }

        //approve contracts
        if (token.allowance(address(this), address(_pcsV2Router)) < amount) {
            token.approve(address(_pcsV2Router), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }

        //get accurate half values
        uint256 tokenBudgetEth = amount.div(2);
        uint256 lpBudgetEth = amount.sub(tokenBudgetEth);

        //get balance of token first
        uint256 tokenBalanceStart = token.balanceOf(address(this));
        
        //swap into token
        (uint256 reserveA, uint256 reserveB,) = lpPair.getReserves();
        uint256 tokenQuote = PancakeLibrary.quote(tokenBudgetEth, reserveA, reserveB);
        address[] memory path = new address[](2);
        path[0] = _pcsV2Router.WETH();
        path[1] = address(token);
        _pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokenBudgetEth}(tokenQuote.mulDiv(90, 100), path, address(this), block.timestamp + _pcsV2TransactionExpirySeconds);

        //get balance again
        uint256 tokenBalanceEnd = token.balanceOf(address(this));
        uint256 newTokens = tokenBalanceEnd.sub(tokenBalanceStart);

        //pass difference into add liquidityeth
        (,, uint256 liquidity) = _pcsV2Router.addLiquidityETH{value: lpBudgetEth}(address(token), newTokens, 0, 0, address(this), block.timestamp + _pcsV2TransactionExpirySeconds);

        //TODO: send remaining tokens to sweep account

        return liquidity;
    }
    
    function liquidateTokensForETH(IBEP20 token, uint256 amount) internal {
        //get number of tokens to sell
        uint256 contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance > 0, "Token contract balance must be greater than zero.");
        require(amount <= contractTokenBalance, "Requested amount is greater than token contract balance.");
        uint256 txAmount = amount;
        if (txAmount == 0) { txAmount = contractTokenBalance; }

        //exchange base token to eth
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = _pcsV2Router.WETH();

        //approve pcs router to trade max amount of tokens on the token contract
        if (token.allowance(address(this), address(_pcsV2Router)) < txAmount) {
            token.approve(address(_pcsV2Router), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }

        //perform swap using 0 is basically a swap at market price
        _pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(txAmount, 0, path, address(this), (block.timestamp + 500));
    }


    //
    // AGENT FUNCTIONS
    //

    modifier onlyExchangeAgentOrOwner() {
        require(_smartStakeAgentAddress == msg.sender || owner() == msg.sender, "Calling address is not the nominated agent or contract owner.");
        _;
    }

    function forceLiquidateTokensForETH(IBEP20 token, uint256 amount) public onlyExchangeAgentOrOwner {
        liquidateTokensForETH(token, amount);
    }


    //
    // ADMIN FUNCTIONS
    //

    function setSmartStakeFarmAddress(uint index, uint256 poolId) public onlyOwner {
        //update farm at correct index
        if (poolId > 0) {
            (address lpPairAddress,,,) = _pcsV2MasterChef.poolInfo(poolId);
            require(lpPairAddress != address(0), "Invalid pool ID.");
        }
        _farms[index] = poolId;
        
        //update farms count
        uint farmsCount = 0;
        for (uint i = 0; i < _farmsTotal; i++) {
            if (_farms[i] > 0) { 
                farmsCount += 1;
            }
        }

        //update value if required
        if (_farmsActive != farmsCount) { _farmsActive = farmsCount; }
        
        //TODO: Emit event for farm change
    }

    function setSmartStakeAgentAddress(address payable newAddress) public onlyOwner {
        _smartStakeAgentAddress = newAddress;
    }

    function setBnbDepositThreshold (uint256 newThreshold) public onlyOwner {
        _wethDepositThreshold = newThreshold;
    }

    function setPancakeSwapTransactionExpirySeconds(uint256 durationSeconds) public onlyOwner {
        _pcsV2TransactionExpirySeconds = durationSeconds;
    }

    function enableWhitelist() public onlyOwner {
        _whitelistEnabled = true;
    }


    function disableWhitelist() public onlyOwner {
        _whitelistEnabled = false;
    }


    function setWhitelistStatus(address inputAddress, bool status) public onlyOwner {
        _whitelistAddresses[inputAddress] = status;
    }

    function setReconcileOnDepositStatus(bool status) public onlyOwner {
        _fundReconcileOnDeposit = status;
    }

    function setReconcileOnWithdrawStatus(bool status) public onlyOwner {
        _fundReconcileOnDeposit = status;
    }

    function withdrawBnb(address payable outputAddress, uint256 amount) external onlyOwner {
        //if 0 specified, withdraw all bnb
        uint256 txAmount = amount;
        if (txAmount == 0) { txAmount = address(this).balance; }
        require(address(this).balance >= txAmount, "Contract doesn't have enough BNB.");
        
        //transfer BNB to specified address
        bool success = false;
        (success, ) = outputAddress.call{value: txAmount}("");
        require(success, "Transfer failed.");
        emit BnbWithdrawn(outputAddress, txAmount);
    }
    
    function withdrawBEP20Token(address tokenAddress, address outputAddress, uint256 amount) public onlyOwner {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Not enough tokens to withdraw.");

        //if 0 passed in, withdraw all tokens
        uint256 txAmount = amount;
        if (txAmount == 0) { txAmount = balance; }
        
        require(token.transferFrom(address(this), outputAddress, txAmount), "Token transfer transfer failed.");
    }
    
    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner(), "You are not the owner");

        //liquidate everything and withdraw to owner wallet
        // if (_farmsActive > 0) {
        //     for (uint i = 0; i < _farmsTotal; i++) {
        //         if (_farms[i] > 0) {
        //             (address lpPairAddress,,,) = _pcsV2MasterChef.poolInfo(_farms[i]);
        //             IPancakePair lpPair = IPancakePair(lpPairAddress);


        //             if (lpPair.token)
        //         }
        //     }
        // }

        selfdestruct(_to);
    }

    receive() external payable {  }
}