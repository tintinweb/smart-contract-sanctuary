/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;


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
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address _payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface PoolInterface {
    function swapExactAmountIn(address, address, address, uint, address, uint) external returns (uint, uint);

    function swapExactAmountOut(address, address, uint, address, uint, address, uint) external returns (uint, uint);

    function calcInGivenOut(uint, uint, uint, uint, uint, uint) external pure returns (uint);

    function calcOutGivenIn(uint, uint, uint, uint, uint, uint) external pure returns (uint);

    function getDenormalizedWeight(address) external view returns (uint);

    function getBalance(address) external view returns (uint);

    function getSwapFee() external view returns (uint);

    function gulp(address) external;

    function calcDesireByGivenAmount(address, address, uint256, uint256) view external returns (uint);

    function calcPoolSpotPrice(address, address, uint256, uint256) external view returns (uint256);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    function approve(address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);

    function deposit() external payable;

    function withdraw(uint) external;
}

interface RegistryInterface {
    function getBestPoolsWithLimit(address, address, uint) external view returns (address[] memory);
}

contract ExchangeProxy is Ownable {

    using SafeMath for uint256;

    struct Pool {
        address pool;
        uint tokenBalanceIn;
        uint tokenWeightIn;
        uint tokenBalanceOut;
        uint tokenWeightOut;
        uint swapFee;
        uint effectiveLiquidity;
    }

    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint swapAmount; // tokenInAmount / tokenOutAmount
        uint limitReturnAmount; // minAmountOut / maxAmountIn
        uint maxPrice;
    }

    TokenInterface weth;
    RegistryInterface registry;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint private constant BONE = 10 ** 18;

    constructor(address _weth) public {
        weth = TokenInterface(_weth);
    }

    function setRegistry(address _registry) external onlyOwner {
        registry = RegistryInterface(_registry);
    }

    function batchSwapExactIn(
        Swap[] memory swaps,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut
    )
    public payable
    returns (uint totalAmountOut)
    {
        address from = msg.sender;
        if (isETH(tokenIn)) {
            require(msg.value >= totalAmountIn, "ERROR_ETH_IN");
            weth.deposit.value(totalAmountIn)();
            from = address(this);
        }
        uint _totalSwapIn = 0;
        for (uint i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            require(swap.tokenIn == address(tokenIn) || (swap.tokenIn == address(weth) && isETH(tokenIn)), "ERR_TOKENIN_NOT_MATCH");
            safeTransferFrom(swap.tokenIn, from, swap.pool, swap.swapAmount);
            address _to = (swap.tokenOut == address(weth) && isETH(tokenOut)) ? address(this) : msg.sender;
            PoolInterface pool = PoolInterface(swap.pool);
            (uint tokenAmountOut,) = pool.swapExactAmountIn(
                msg.sender,
                swap.tokenIn,
                swap.tokenOut,
                swap.limitReturnAmount,
                _to,
                swap.maxPrice
            );
            if (_to != msg.sender) {
                transferAll(tokenOut, tokenAmountOut);
            }
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
            _totalSwapIn = _totalSwapIn.add(swap.swapAmount);
        }
        require(_totalSwapIn == totalAmountIn, "ERR_TOTAL_AMOUNT_IN");
        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");
        if (isETH(tokenIn) && msg.value > _totalSwapIn) {
            (bool xfer,) = msg.sender.call.value(msg.value.sub(_totalSwapIn))("");
            require(xfer, "ERR_ETH_FAILED");
        }
    }

    function batchSwapExactOut(
        Swap[] memory swaps,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint maxTotalAmountIn
    )
    public payable
    returns (uint totalAmountIn)
    {
        address from = msg.sender;
        if (isETH(tokenIn)) {
            weth.deposit.value(msg.value)();
            from = address(this);
        }
        for (uint i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            uint tokenAmountIn = getAmountIn(swap);
            swap.tokenIn = isETH(tokenIn) ? address(weth) : swap.tokenIn;
            safeTransferFrom(swap.tokenIn, from, swap.pool, tokenAmountIn);
            address _to = (swap.tokenOut == address(weth) && isETH(tokenOut)) ? address(this) : msg.sender;
            PoolInterface pool = PoolInterface(swap.pool);
            pool.swapExactAmountOut(
                msg.sender,
                swap.tokenIn,
                swap.limitReturnAmount,
                swap.tokenOut,
                swap.swapAmount,
                _to,
                swap.maxPrice
            );
            if (_to != msg.sender) {
                transferAll(tokenOut, swap.swapAmount);
            }
            totalAmountIn = tokenAmountIn.add(totalAmountIn);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");
        if (isETH(tokenIn) && msg.value > totalAmountIn) {
            transferAll(tokenIn, msg.value.sub(totalAmountIn));
        }
    }

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut
    )
    public payable
    returns (uint totalAmountOut)
    {
        uint totalSwapAmount = 0;
        address from = msg.sender;
        if (isETH(tokenIn)) {
            require(msg.value >= totalAmountIn, "ERROR_ETH_IN");
            weth.deposit.value(totalAmountIn)();
            from = address(this);
        }
        for (uint i = 0; i < swapSequences.length; i++) {
            totalSwapAmount = totalSwapAmount.add(swapSequences[i][0].swapAmount);
            require(swapSequences[i][0].tokenIn == address(tokenIn) || (isETH(tokenIn) && swapSequences[i][0].tokenIn == address(weth)), "ERR_TOKENIN_NOT_MATCH");
            safeTransferFrom(swapSequences[i][0].tokenIn, from, swapSequences[i][0].pool, swapSequences[i][0].swapAmount);

            uint tokenAmountOut;
            for (uint k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                PoolInterface pool = PoolInterface(swap.pool);
                address _to;
                if (k < swapSequences[i].length - 1) {
                    _to = swapSequences[i][k + 1].pool;
                } else {
                    require(swap.tokenOut == address(tokenOut) || (swap.tokenOut == address(weth) && isETH(tokenOut)), "ERR_OUTCOIN_NOT_MATCH");
                    _to = (swap.tokenOut == address(weth) && isETH(tokenOut)) ? address(this) : msg.sender;
                }
                (tokenAmountOut,) = pool.swapExactAmountIn(
                    msg.sender,
                    swap.tokenIn,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    _to,
                    swap.maxPrice
                );
                if (k == swapSequences[i].length - 1 && _to != msg.sender) {
                    transferAll(tokenOut, tokenAmountOut);
                }
            }
            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }
        require(totalSwapAmount == totalAmountIn, "ERR_TOTAL_AMOUNT_IN");
        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");
        if (isETH(tokenIn) && msg.value > totalSwapAmount) {
            (bool xfer,) = msg.sender.call.value(msg.value.sub(totalAmountIn))("");
            require(xfer, "ERR_ETH_FAILED");
        }
    }

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint maxTotalAmountIn
    )
    public payable
    returns (uint totalAmountIn)
    {
        address from = msg.sender;
        if (isETH(tokenIn)) {
            require(msg.value >= maxTotalAmountIn, "ERROR_ETH_IN");
            weth.deposit.value(msg.value)();
            from = address(this);
        }

        for (uint i = 0; i < swapSequences.length; i++) {
            uint[] memory amountIns = getAmountsIn(swapSequences[i]);
            swapSequences[i][0].tokenIn = isETH(tokenIn) ? address(weth) : swapSequences[i][0].tokenIn;
            safeTransferFrom(swapSequences[i][0].tokenIn, from, swapSequences[i][0].pool, amountIns[0]);

            for (uint j = 0; j < swapSequences[i].length; j++) {
                Swap memory swap = swapSequences[i][j];
                PoolInterface pool = PoolInterface(swap.pool);
                address _to;
                if (j < swapSequences[i].length - 1) {
                    _to = swapSequences[i][j + 1].pool;
                } else {
                    require(swap.tokenOut == address(tokenOut) || (swap.tokenOut == address(weth) && isETH(tokenOut)), "ERR_OUTCOIN_NOT_MATCH");
                    _to = (swap.tokenOut == address(weth) && isETH(tokenOut)) ? address(this) : msg.sender;
                }
                uint _tokenOut = j < swapSequences[i].length - 1 ? amountIns[j + 1] : swap.swapAmount;
                pool.swapExactAmountOut(
                    msg.sender,
                    swap.tokenIn,
                    amountIns[j],
                    swap.tokenOut,
                    _tokenOut,
                    _to,
                    swap.maxPrice
                );
                if (j == swapSequences[i].length - 1 && _to != msg.sender) {
                    transferAll(tokenOut, _tokenOut);
                }
            }
            totalAmountIn = totalAmountIn.add(amountIns[0]);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");
        if (isETH(tokenIn) && msg.value > totalAmountIn) {
            transferAll(tokenIn, msg.value.sub(totalAmountIn));
        }
    }

    function getBalance(TokenInterface token) internal view returns (uint) {
        if (isETH(token)) {
            return weth.balanceOf(address(this));
        } else {
            return token.balanceOf(address(this));
        }
    }

    function transferAll(TokenInterface token, uint amount) internal{
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            weth.withdraw(amount);
            (bool xfer,) = msg.sender.call.value(amount)("");
            require(xfer, "ERR_ETH_FAILED");
        } else {
            safeTransfer(address(token), msg.sender, amount);
        }
    }

    function isETH(TokenInterface token) internal pure returns (bool) {
        return (address(token) == ETH_ADDRESS);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    // given an output amount of an asset and pool, returns a required input amount of the other asset
    function getAmountIn(Swap memory swap) internal view returns (uint amountIn) {
        require(swap.swapAmount > 0, 'ExchangeProxy: INSUFFICIENT_OUTPUT_AMOUNT');
        PoolInterface pool = PoolInterface(swap.pool);
        amountIn = pool.calcDesireByGivenAmount(
            swap.tokenIn,
            swap.tokenOut,
            0,
            swap.swapAmount
        );
        uint256 spotPrice = pool.calcPoolSpotPrice(
            swap.tokenIn,
            swap.tokenOut,
            0,
            0
        );
        require(spotPrice <= swap.maxPrice, "ERR_LIMIT_PRICE");
    }

    // performs chained getAmountIn calculations on any number of pools
    function getAmountsIn(Swap[] memory swaps) internal view returns (uint[] memory amounts) {
        require(swaps.length >= 1, 'ExchangeProxy: INVALID_PATH');
        amounts = new uint[](swaps.length);
        uint i = swaps.length - 1;
        while (i > 0) {
            Swap memory swap = swaps[i];
            amounts[i] = getAmountIn(swap);
            require(swaps[i].tokenIn == swaps[i - 1].tokenOut, "ExchangeProxy: INVALID_PATH");
            swaps[i - 1].swapAmount = amounts[i];
            i--;
        }
        amounts[0] = getAmountIn(swaps[0]);
    }

    function() external payable {}

}