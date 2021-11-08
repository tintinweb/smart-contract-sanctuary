pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IKyber.sol";
import "./interfaces/UniswapExchangeInterface.sol";

contract Trader {
    using SafeERC20 for IERC20;

    // Mainnet: (Old) IKyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755)
    IKyber public kyberProxy;

    address public sai; // Mainnet: 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public owner;
    address public uniswap; // Mainnet: 0x09cabEC1eAd1c0Ba254B09efb3EE13841712bE14

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    constructor(address _kyberNetworkProxy, address _sai, address _uniswap) public {
        kyberProxy = IKyber(_kyberNetworkProxy);
        owner = msg.sender;
        sai = _sai;
        uniswap = _uniswap;
    }

    // Allow contract to receive Ether
    function() external payable {}

    function kyberSwap(
        IKyber _kyberNetworkProxy,
        IERC20 token,
        uint256 tokenQty,
        address destAddress
    ) internal returns (uint256) {
        token.safeTransferFrom(msg.sender, address(this), tokenQty);
        token.approve(address(kyberProxy), 0);
        token.approve(address(kyberProxy), tokenQty);
        uint256 destAmount = kyberProxy.tradeWithHint(
            IERC20(sai),
            tokenQty,
            IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
            address(this),
            8000000000000000000000000000000000000000000000000000000000000000,
            0,
            0x0000000000000000000000000000000000000004,
            "PERM"
        );
        return destAmount;
    }

    function buyKyberSellUniswap(
        address _fromToken,
        address _uniswap,
        uint256 _amount
    ) internal returns (bool) {
        uint256 _ethAmount = kyberSwap(
            kyberProxy,
            IERC20(_fromToken),
            _amount,
            msg.sender
        );
        UniswapExchangeInterface(_uniswap).ethToTokenSwapInput.value(
            _ethAmount
        )(1, block.timestamp);
        return true;
    }

    function arb(uint256 _amount) internal {
        buyKyberSellUniswap(
            sai,
            uniswap,
            _amount
        );
    }

    function withdrawFunds() public onlyOwner {
        msg.sender.transfer(address(this).balance);
        IERC20 saiInstance = IERC20(sai);
        saiInstance.safeTransfer(msg.sender, saiInstance.balanceOf(address(this)));
    }
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract UniswapExchangeInterface {
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;

    function tokenAddress() external view returns (address token);

    function factoryAddress() external view returns (address factory);

    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);

    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);

    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256 eth_sold);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);

    function getTokenToEthOutputPrice(uint256 eth_bought)
        external
        view
        returns (uint256 tokens_sold);

    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);

    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);

    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256 eth_sold);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 eth_sold);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);

    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256 tokens_sold);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 tokens_sold);

    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_sold);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_sold);

    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_bought);

    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_bought);

    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_sold);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function setup(address token_addr) external;
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKyber {
    function maxGasPrice() external view returns (uint256);

    function getUserCapInWei(address user) external view returns (uint256);

    function getUserCapInTokenWei(address user, IERC20 token)
        external
        view
        returns (uint256);

    function enabled() external view returns (bool);

    function info(bytes32 id) external view returns (uint256);

    function getExpectedRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function swapEtherToToken(IERC20 token, uint256 minRate)
        external
        returns (uint256);

    function swapTokenToEther(
        IERC20 token,
        uint256 tokenQty,
        uint256 minRate
    ) external returns (uint256);
}

pragma solidity ^0.5.5;

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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