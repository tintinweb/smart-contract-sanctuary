/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File openzeppelin-solidity-2.3.0/contracts/ownership/[email protected]

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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


// File openzeppelin-solidity-2.3.0/contracts/utils/[email protected]

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


// File openzeppelin-solidity-2.3.0/contracts/math/[email protected]

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// File contracts/5/interfaces/IERC20Interface.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}


// File contracts/5/libs/SafeToken.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return IERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return IERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, "!safeTransferETH");
    }
}


// File contracts/5/interfaces/IStrategy.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IStrategy {
    /// @dev Execute worker strategy. Take LP tokens + debt token. Return LP tokens or debt token.
    /// @param user The original user that is interacting with the operator.
    /// @param borrowToken The token user want borrow.
    /// @param borrow The amount user borrow from bank.
    /// @param debt The user's total debt, for better decision making context.
    /// @param data Extra calldata information passed along to this strategy.
    /// @return token and amount need transfer back.
    function execute(
        address user,
        address borrowToken,
        uint256 borrow,
        uint256 debt,
        bytes calldata data
    ) external payable;
}


// File contracts/interfaces/IWHT.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface IWHT {
    function balanceOf(address user) external returns (uint256);

    function approve(address to, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}


// File contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/interfaces/IUniswapV2Router02.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Router02 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/interfaces/ISwapMining.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface ISwapMining {
    function swap(
        address account,
        address input,
        address output,
        uint256 amount
    ) external returns (bool);

    /// The user withdraws all the transaction rewards of the pool
    function takerWithdraw() external;

    /// Get rewards from users in the current pool
    /// @param pid pid of pair.
    function getUserReward(uint256 pid) external view returns (uint256, uint256);
}


// File contracts/5/MdexStrategyWithdrawMinimizeTrading.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;









contract MdexStrategyWithdrawMinimizeTrading is Ownable, ReentrancyGuard, IStrategy {
    using SafeToken for address;
    using SafeMath for uint256;

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public wht;

    /// @dev Create a new withdraw minimize trading strategy instance for mdx.
    /// @param _router The mdx router smart contract.
    constructor(IUniswapV2Router02 _router) public {
        factory = IUniswapV2Factory(_router.factory());
        router = _router;
        // wht = _router.WHT();
    }

    /// @dev Execute worker strategy. Take LP tokens. Return debt token + token want back.
    /// @param user User address to withdraw liquidity.
    /// @param borrowToken The token user borrow from bank.
    /// @param debt User's debt amount.
    /// @param data Extra calldata information passed along to this strategy.
    function execute(
        address user,
        address borrowToken,
        uint256, /* borrow */
        uint256 debt,
        bytes calldata data
    ) external payable nonReentrant {

        // 1. Find out lpToken and liquidity.
        // whichWantBack: 0:token0;1:token1;2:token what surplus.
        (address token0, address token1, uint256 whichWantBack) = abi.decode(data, (address, address, uint256));

        // is borrowToken is ht.
        bool isBorrowHt = borrowToken == address(0);
        borrowToken = isBorrowHt ? wht : borrowToken;

        // the relative token when token0 or token1 is ht.
        address htRelative = address(0);
        {
            if (token0 == address(0)) {
                token0 = wht;
                htRelative = token1;
            }
            if (token1 == address(0)) {
                token1 = wht;
                htRelative = token0;
            }
        }
        require(borrowToken == token0 || borrowToken == token1, "borrowToken not token0 and token1");
        require(
            whichWantBack == uint256(0) || whichWantBack == uint256(1) || whichWantBack == uint256(2),
            "whichWantBack not in (0,1,2)"
        );

        address tokenUserWant = whichWantBack == uint256(0) ? token0 : token1;
        IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(token0, token1));
        token0 = lpToken.token0();
        token1 = lpToken.token1();

        {


            lpToken.approve(address(router), uint256(- 1));
            router.removeLiquidity(token0, token1, lpToken.balanceOf(address(this)), 0, 0, address(this), now);
        }
        {
            address tokenRelative = borrowToken == token0 ? token1 : token0;


            swapIfNeed(borrowToken, tokenRelative, debt);

            if (isBorrowHt) {
                IWHT(wht).withdraw(debt);
                SafeToken.safeTransferETH(msg.sender, debt);
            } else {
                SafeToken.safeTransfer(borrowToken, msg.sender, debt);
            }
        }



        // 2. swap remaining token to what user want.
        if (whichWantBack != uint256(2)) {
            address tokenAnother = tokenUserWant == token0 ? token1 : token0;
            uint256 anotherAmount = tokenAnother.myBalance();
            if (anotherAmount > 0) {
                tokenAnother.safeApprove(address(router), 0);
                tokenAnother.safeApprove(address(router), uint256(- 1));

                address[] memory path = new address[](2);
                path[0] = tokenAnother;
                path[1] = tokenUserWant;
                router.swapExactTokensForTokens(anotherAmount, 0, path, address(this), now);
            }
        }

        // 3. send all tokens back.
        if (htRelative == address(0)) {
            token0.safeTransfer(user, token0.myBalance());
            token1.safeTransfer(user, token1.myBalance());
        } else {
            safeUnWrapperAndAllSend(wht, user);
            safeUnWrapperAndAllSend(htRelative, user);
        }
    }

    /// swap if need.
    function swapIfNeed(
        address borrowToken,
        address tokenRelative,
        uint256 debt
    ) internal {
        uint256 borrowTokenAmount = borrowToken.myBalance();
        if (debt > borrowTokenAmount) {
            tokenRelative.safeApprove(address(router), uint256(- 1));
            uint256 remainingDebt = debt.sub(borrowTokenAmount);
            address[] memory path = new address[](2);
            path[0] = tokenRelative;
            path[1] = borrowToken;



            router.swapTokensForExactTokens(remainingDebt, tokenRelative.myBalance(), path, address(this), now);
            tokenRelative.safeApprove(address(router), 0);
        }
    }

    /// get token balance, if is WHT un wrapper to HT and send to 'to'
    function safeUnWrapperAndAllSend(address token, address to) internal {
        uint256 total = SafeToken.myBalance(token);
        if (total > 0) {
            if (token == wht) {
                IWHT(wht).withdraw(total);
                SafeToken.safeTransferETH(to, total);
            } else {
                SafeToken.safeTransfer(token, to, total);
            }
        }
    }

    /// @param minter The address of MDex SwapMining contract.
    /// @param pid pid pid of pair in SwapMining config.
    function getSwapReward(address minter, uint256 pid) public view returns (uint256, uint256) {
        ISwapMining swapMining = ISwapMining(minter);
        return swapMining.getUserReward(pid);
    }

    /// @param minter The address of MDex SwapMining contract.
    /// @param token Token of reward. Result of pairOfPid(lpTokenAddress)
    function swapMiningReward(address minter, address token) external onlyOwner {
        ISwapMining swapMining = ISwapMining(minter);
        swapMining.takerWithdraw();
        token.safeTransfer(msg.sender, token.myBalance());
    }

    /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
    /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
    /// @param to The address to send the tokens to.
    /// @param value The number of tokens to transfer to `to`.
    function recover(
        address token,
        address to,
        uint256 value
    ) external onlyOwner nonReentrant {
        token.safeTransfer(to, value);
    }

    function() external payable {}
}