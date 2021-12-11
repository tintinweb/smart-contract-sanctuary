//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IChainLinkAggregator.sol";

contract DCAChainLink is Ownable {
    IUniswapV2Router02 private Uniswap;
    IChainLinkAggregator private ChainLinkAggregator;
    uint256 private slippage;
    bool private isactive;
    uint256 private fee;

    struct Task {
        address owner;
        address from;
        address to;
        uint256 amount;
        uint64 lastExecuted;
        uint64 delay;
        uint64 intervals;
        uint64 count;
    }

    event NewTask(
        uint256 id,
        address from,
        address to,
        uint256 amount,
        uint64 delay,
        uint64 intervals,
        address owner,
        uint64 lastExecuted,
        uint64 count
    );
    event DeleteTask(uint256 id);

    event TaskExecuted(uint256 id, uint64 count, uint64 lastExecuted);

    event Log(string message);

    Task[] private tasks;
    uint256[] private deletedtasks;

    constructor(
        address _swapRouter,
        address _chainLinkAggregator,
        uint256 _fee
    ) {
        Uniswap = IUniswapV2Router02(_swapRouter);
        ChainLinkAggregator = IChainLinkAggregator(_chainLinkAggregator);
        slippage = 3;
        isactive = true;
        fee = _fee;
    }

    function getRouter() public view returns (address) {
        return address(Uniswap);
    }

    function getAggregator() public view returns (address) {
        return address(ChainLinkAggregator);
    }

    function setRouter(address _swapRouter) public {
        Uniswap = IUniswapV2Router02(_swapRouter);
    }

    function setAggregator(address _chainLinkAggregator) public {
        ChainLinkAggregator = IChainLinkAggregator(_chainLinkAggregator);
    }

    function updateSlippage(uint256 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function deactivateContract() external onlyOwner {
        isactive = false;
    }

    function activateContract() external onlyOwner {
        isactive = true;
    }

    function collectFees(address payable _receiver) external onlyOwner {
        _receiver.transfer(payable(address(this)).balance);
    }

    function newTask(
        address _from,
        address _to,
        uint256 _amount,
        uint64 _delay,
        uint64 _intervals
    ) public payable returns (bool) {
        require(
            IERC20(_from).allowance(msg.sender, address(this)) >=
                _amount * _intervals,
            "newTask : No Allowance"
        );
        // take fees
        require(msg.value >= fee * _intervals, "newTask : No Fee");
        // Check for deleted Tasks;
        uint256 id;
        if (deletedtasks.length == 0) {
            // no deleted tasks, Insert new Task
            id = tasks.length;
            tasks.push(
                Task(msg.sender, _from, _to, _amount, 0, _delay, _intervals, 0)
            );
        } else {
            // there are deleted tasks, Replace a deleted task with new Task
            id = deletedtasks[deletedtasks.length - 1];
            tasks[id] = Task(
                msg.sender,
                _from,
                _to,
                _amount,
                0,
                _delay,
                _intervals,
                0
            );
            deletedtasks.pop();
        }
        emit NewTask(
            id,
            _from,
            _to,
            _amount,
            _delay,
            _intervals,
            msg.sender,
            0,
            0
        );
        return true;
    }

    function deleteTask(uint256 _taskid) public returns (bool) {
        require(
            msg.sender == tasks[_taskid].owner,
            "Only the owner can delete a task"
        );
        delete tasks[_taskid];
        deletedtasks.push(_taskid);
        emit DeleteTask(_taskid);
        return true;
    }

    function checkTask(uint256 _taskid) public view returns (bool) {
        Task memory task = tasks[_taskid];
        return (task.intervals != 0 &&
            uint64(block.timestamp) - task.lastExecuted > task.delay &&
            task.count < task.intervals &&
            IERC20(task.from).balanceOf(task.owner) >= task.amount &&
            IERC20(task.from).allowance(task.owner, address(this)) >=
            task.amount);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (!isactive) return (false, bytes(""));
        uint256 index = abi.decode(checkData, (uint256)) * 100;
        upkeepNeeded = false;
        for (
            uint256 i = index;
            upkeepNeeded == false && i < index + 1000 && i < tasks.length;
            i++
        ) {
            if (checkTask(i)) {
                return (true, abi.encode(i));
            }
        }
    }

    function performUpkeep(bytes calldata performData) external {
        uint256 taskid = abi.decode(performData, (uint256));
        Task memory task = tasks[taskid];
        require(
            isactive &&
                task.intervals != 0 &&
                uint64(block.timestamp) - task.lastExecuted > task.delay &&
                task.count < task.intervals &&
                IERC20(task.from).balanceOf(task.owner) >= task.amount,
            "PUK : Chech failed"
        );

        tasks[taskid].count++;
        IERC20(task.from).transferFrom(task.owner, address(this), task.amount);
        if (
            IERC20(task.from).allowance(address(this), address(Uniswap)) <
            task.amount
        ) IERC20(task.from).approve(address(Uniswap), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = task.from;
        path[1] = task.to;

        uint256 minOut = (uint256(
            ChainLinkAggregator.getPrice(task.from, task.to)
        ) *
            task.amount *
            (100 - slippage)) / 10**20;

        // console.log("minOut", minOut);

        try
            Uniswap.swapExactTokensForTokens(
                task.amount,
                minOut,
                path,
                task.owner,
                block.timestamp
            )
        {
            //nothing to do here
        } catch Error(string memory error) {
            emit Log(error);
        }

        if (task.count == task.intervals) {
            deleteTask(taskid);
        }
        emit TaskExecuted(taskid, task.count + 1, uint64(block.timestamp));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IChainLinkAggregator {
    function getPrice(address _token1, address _token2) external view returns (int256);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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