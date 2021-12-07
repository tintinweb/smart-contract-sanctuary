/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

/*
  _____  _                                 _  ____
 |  __ \(_)                               | |/ __ \
 | |  | |_  __ _ _ __ ___   ___  _ __   __| | |  | |
 | |  | | |/ _` | '_ ` _ \ / _ \| '_ \ / _` | |  | |
 | |__| | | (_| | | | | | | (_) | | | | (_| | |__| |
 |_____/|_|\__,_|_| |_| |_|\___/|_| |_|\__,_|\___\_\

 DiamondQ uses the new revolutionary "Q" contract that benefits holders
 and punishes "paper hands". The timing of each buy is tracked by the
 contract, the longer you hold the tokens the less tax you pay on a sell.
 The extra tokens that are taxed are simply sent to the burn wallet so all
 holders benefit even more by the supply becoming more and more scarce.

 Buy tax:
     Tax is the same no matter the time:
         5% to the house wallet
 Sell tax:
     If selling within 7 days:
         5% sent to the house wallet
         25% sent to the burn wallet
     If selling within 7-14 days:
         5% sent to the house wallet
         15% sent to the burn wallet
     If selling within 14-21 days:
         5% sent to the house wallet
         5% sent the burn wallet
     If selling after 21 days:
         5% sent to the house wallet

 Author: @HizzleDev
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

interface IERC20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

contract DiamondQ is Context, IERC20, Ownable {
    struct TimedTransactions {
        uint[] txBlockTimes;
        mapping (uint => uint256) timedTxAmount;
        uint256 totalBalance;
    }

    // Track the transaction history of the user
    mapping (address => TimedTransactions) private _timedTransactionsMap;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _onlyDiamondHandTxs;

    uint256 constant DEFAULT_HOUSE_FEE = 5;
    uint256 private _currentHouseFee = 5;

    uint256 constant DEFAULT_PAPER_HAND_FEE = 25;
    uint256 private _currentPaperHandFee = 25;
    uint256 private _paperHandTime = 7 days;

    uint256 constant DEFAULT_GATE1_FEE = 15;
    uint256 private _currentGate1Fee = 15;
    uint256 private _gate1Time = 14 days;

    uint256 constant DEFAULT_GATE2_FEE = 5;
    uint256 private _currentGate2Fee = 5;
    uint256 private _gate2Time = 21 days;

    string private _name = "DiamondQ";
    string private _symbol = "DIQ";
    uint8 private _decimals = 9;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // This unix time is used to aggregate all transaction block times. It is over 21 days and therefore will
    // trigger the lowest tax rate possible
    uint256 constant OVER_21_DAYS_BLOCK_TIME = 1577836800;

    // Prevent reentrancy by only allowing one swap at a time
    bool swapInProgress;

    modifier lockTheSwap {
        swapInProgress = true;
        _;
        swapInProgress = false;
    }

    bool private _swapEnabled = true;
    bool private _burnEnabled = true;

    uint256 private _totalTokens = 1000 * 10**6 * 10**9;
    uint256 private _minTokensBeforeSwap = 1000 * 10**3 * 10**9;

    address payable private _houseContract = payable(0x6E73733642485b8EABFe89D2dbd844dcBc52122d);
    address private _deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        //Pancake Swap V2 address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        // Add initial balances
        _timedTransactionsMap[owner()].totalBalance = _totalTokens;
        _timedTransactionsMap[owner()].txBlockTimes.push(OVER_21_DAYS_BLOCK_TIME);
        _timedTransactionsMap[owner()].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = _totalTokens;

        // Track balance in the dead wallet
        _timedTransactionsMap[_deadAddress].totalBalance = 0;
        _timedTransactionsMap[_deadAddress].txBlockTimes.push(OVER_21_DAYS_BLOCK_TIME);
        _timedTransactionsMap[_deadAddress].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = 0;

        // Exclude contract and owner from fees to prevent contract functions from having a tax
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_houseContract] = true;

        emit Transfer(address(0), _msgSender(), _totalTokens);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalTokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _timedTransactionsMap[account].totalBalance;
    }

    function balanceLessThan7Days(address account) external view returns (uint256) {
        uint256 totalTokens = 0;

        for (uint i = 0; i < _timedTransactionsMap[account].txBlockTimes.length; i++) {
            uint txTime = _timedTransactionsMap[account].txBlockTimes[i];
            uint256 tokensAtTime = _timedTransactionsMap[account].timedTxAmount[txTime];

            // Only add up balance in the last 7 days
            if (txTime > block.timestamp - _paperHandTime) {
                totalTokens = totalTokens + tokensAtTime;
            }
        }

        return totalTokens;
    }

    function balanceBetween7And14Days(address account) external view returns (uint256) {
        uint256 totalTokens = 0;

        for (uint i = 0; i < _timedTransactionsMap[account].txBlockTimes.length; i++) {
            uint txTime = _timedTransactionsMap[account].txBlockTimes[i];
            uint256 tokensAtTime = _timedTransactionsMap[account].timedTxAmount[txTime];

            // Only add up balance in the last 7-14 days
            if (txTime < block.timestamp - _paperHandTime && txTime > block.timestamp - _gate1Time) {
                totalTokens = totalTokens + tokensAtTime;
            }
        }

        return totalTokens;
    }

    function balanceBetween14And21Days(address account) external view returns (uint256) {
        uint256 totalTokens = 0;

        for (uint i = 0; i < _timedTransactionsMap[account].txBlockTimes.length; i++) {
            uint txTime = _timedTransactionsMap[account].txBlockTimes[i];
            uint256 tokensAtTime = _timedTransactionsMap[account].timedTxAmount[txTime];

            // Only add up balance in the last 14-21 days
            if (txTime < block.timestamp - _gate1Time && txTime > block.timestamp - _gate2Time) {
                totalTokens = totalTokens + tokensAtTime;
            }
        }

        return totalTokens;
    }

    function balanceOver21Days(address account) public view returns (uint256) {
        uint256 totalTokens = 0;

        for (uint i = 0; i < _timedTransactionsMap[account].txBlockTimes.length; i++) {
            uint txTime = _timedTransactionsMap[account].txBlockTimes[i];
            uint256 tokensAtTime = _timedTransactionsMap[account].timedTxAmount[txTime];

            // Only add up balance over the last 21 days
            if (txTime < block.timestamp - _gate2Time) {
                totalTokens = totalTokens + tokensAtTime;
            }
        }

        return totalTokens;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Selective competitions are based on "diamond hand only" and transfers will only be allowed
        // when the tokens are in the "diamond hand" group
        bool isOnlyDiamondHandTx = _onlyDiamondHandTxs[from] || _onlyDiamondHandTxs[to];
        if (isOnlyDiamondHandTx) {
            require(balanceOver21Days(from) >= amount, "Insufficient diamond hand token balance");
        }

        // Reduce balance of sending including calculating and removing all taxes
        uint256 transferAmount = _reduceSenderBalance(from, to, amount);

        // Increase balance of the recipient address
        _increaseRecipientBalance(to, transferAmount, isOnlyDiamondHandTx);

        emit Transfer(from, to, transferAmount);
    }

    function _reduceSenderBalance(address sender, address recipient, uint256 initialTransferAmount) private returns (uint256) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(initialTransferAmount > 0, "Transfer amount must be greater than zero");

        // Keep track of the tokens that haven't had a tax calculated against them
        uint256 remainingTokens = initialTransferAmount;

        // Keep track of the amount of tokens that are to be burned
        uint256 taxedBurnTokens = 0;

        // Keep track of the index for which tokens still exist in the bucket
        uint lastIndexToDelete = 0;

        // Loop over the blockTimes
        for (uint i = 0; i < _timedTransactionsMap[sender].txBlockTimes.length; i++) {
            uint txTime = _timedTransactionsMap[sender].txBlockTimes[i];
            uint256 tokensAtTime = _timedTransactionsMap[sender].timedTxAmount[txTime];

            // If there are more tokens purchased at the current time than those that are remaining to
            // fulfill the tokens at this transaction then only use the remainingTokens
            if (tokensAtTime > remainingTokens) {
                tokensAtTime = remainingTokens;
            } else {
                // There are more elements to iterate through
                lastIndexToDelete = i + 1;
            }

            // Depending on when the tokens were bought, tax the correct amount. This is proportional
            // to when the user bought each set of tokens.
            if (txTime > block.timestamp - _paperHandTime) {
                taxedBurnTokens = taxedBurnTokens + ((tokensAtTime * _currentPaperHandFee) / 100);
            } else if (txTime > block.timestamp - _gate1Time) {
                taxedBurnTokens = taxedBurnTokens + ((tokensAtTime * _currentGate1Fee) / 100);
            } else if (txTime > block.timestamp - _gate2Time) {
                taxedBurnTokens = taxedBurnTokens + ((tokensAtTime * _currentGate2Fee) / 100);
            }

            // Decrease the tokens in the map
            _timedTransactionsMap[sender].timedTxAmount[txTime] = _timedTransactionsMap[sender].timedTxAmount[txTime] - tokensAtTime;

            remainingTokens = remainingTokens - tokensAtTime;

            // If there are no more tokens to sell then exit the loop
            if (remainingTokens == 0) {
                break;
            }
        }

        _sliceBlockTimeArray(sender, lastIndexToDelete);

        // Update the senders balance
        _timedTransactionsMap[sender].totalBalance = _timedTransactionsMap[sender].totalBalance - initialTransferAmount;

        // Only burn tokens if the burn is enabled, the sender address is not excluded and it is performed on a sell
        if (!_burnEnabled || _isExcludedFromFees[sender] || _isExcludedFromFees[recipient] || recipient != uniswapV2Pair) {
            taxedBurnTokens = 0;
        }

        if (taxedBurnTokens > 0) {
            _timedTransactionsMap[_deadAddress].totalBalance = _timedTransactionsMap[_deadAddress].totalBalance + taxedBurnTokens;
            _timedTransactionsMap[_deadAddress].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = _timedTransactionsMap[_deadAddress].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] + taxedBurnTokens;
        }

        uint256 taxedHouseTokens = _calculateHouseFee(initialTransferAmount);

        // Always collect house tokens unless address is excluded
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            taxedHouseTokens = 0;
        }

        // Add taxed tokens to the contract total
        _increaseTaxBalance(taxedHouseTokens);

        uint256 contractTokenBalance = balanceOf(address(this));

        // Only swap tokens when threshold has been met, a swap isn't already in progress,
        // the swap is enabled and never on a buy
        if (
            contractTokenBalance >= _minTokensBeforeSwap &&
            !swapInProgress &&
            _swapEnabled &&
            sender != uniswapV2Pair
        ) {
            // Always swap a set amount of tokens to prevent large dumps
            _swapTokensForHouse(_minTokensBeforeSwap);
        }

        // The amount to be transferred is the initial amount minus the taxed and burned tokens
        return initialTransferAmount - taxedHouseTokens - taxedBurnTokens;
    }

    function _increaseTaxBalance(uint256 amount) private {
        _timedTransactionsMap[address(this)].totalBalance = _timedTransactionsMap[address(this)].totalBalance + amount;
        _timedTransactionsMap[address(this)].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = _timedTransactionsMap[address(this)].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] + amount;
    }

    function _increaseRecipientBalance(address recipient, uint256 transferAmount, bool isDiamondHandOnlyTx) private {
        _aggregateOldTransactions(recipient);

        _timedTransactionsMap[recipient].totalBalance = _timedTransactionsMap[recipient].totalBalance + transferAmount;

        uint256 totalTxs = _timedTransactionsMap[recipient].txBlockTimes.length;

        if (isDiamondHandOnlyTx) {
            // If it's the first transaction then just add the oldest time to the map and array
            if (totalTxs < 1) {
                _timedTransactionsMap[recipient].txBlockTimes.push(OVER_21_DAYS_BLOCK_TIME);
                _timedTransactionsMap[recipient].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = transferAmount;
                return;
            }

            // If the first position in the array is already the oldest block time then just increase the value in the map
            if (_timedTransactionsMap[recipient].txBlockTimes[0] == OVER_21_DAYS_BLOCK_TIME) {
                _timedTransactionsMap[recipient].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = _timedTransactionsMap[recipient].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] + transferAmount;
                return;
            }

            // Shift the array with the oldest block time in the 0 position and add the value in the map
            _timedTransactionsMap[recipient].txBlockTimes.push(_timedTransactionsMap[recipient].txBlockTimes[totalTxs - 1]);
            for (uint i = totalTxs - 1; i > 0; i--) {
                _timedTransactionsMap[recipient].txBlockTimes[i] = _timedTransactionsMap[recipient].txBlockTimes[i - 1];
            }
            _timedTransactionsMap[recipient].txBlockTimes[0] = OVER_21_DAYS_BLOCK_TIME;
            _timedTransactionsMap[recipient].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = transferAmount;
            return;
        }

        if (totalTxs < 1) {
            _timedTransactionsMap[recipient].txBlockTimes.push(block.timestamp);
            _timedTransactionsMap[recipient].timedTxAmount[block.timestamp] = transferAmount;
            return;
        }

        uint256 lastTxTime = _timedTransactionsMap[recipient].txBlockTimes[totalTxs - 1];

        // If transaction was within the past 12 hours then keep as part of the same bucket for efficiency
        if (lastTxTime > block.timestamp - 12 hours) {
            _timedTransactionsMap[recipient].timedTxAmount[lastTxTime] = _timedTransactionsMap[recipient].timedTxAmount[lastTxTime] + transferAmount;
            return;
        }

        _timedTransactionsMap[recipient].txBlockTimes.push(block.timestamp);
        _timedTransactionsMap[recipient].timedTxAmount[block.timestamp] = transferAmount;
    }

    function _calculateHouseFee(uint256 initialAmount) private view returns (uint256) {
        return (initialAmount * _currentHouseFee) / 100;
    }

    function _swapTokensForHouse(uint256 tokensToSwap) private lockTheSwap {
        uint256 initialBalance = address(this).balance;

        // Swap to BNB and send to house wallet
        _swapTokensForEth(tokensToSwap);

        // Total BNB that has been swapped
        uint256 bnbSwapped = address(this).balance - initialBalance;

        // Transfer the BNB to the house contract
        (bool success, ) = _houseContract.call{value:bnbSwapped}("");
        require(success, "Unable to send to house contract");
    }

    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function setBurnEnabled(bool enabled) external onlyOwner {
        _burnEnabled = enabled;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        _swapEnabled = enabled;
    }

    function removeHouseFee() external onlyOwner {
        _currentHouseFee = 0;
    }

    function reinstateHouseFee() external onlyOwner {
        _currentHouseFee = DEFAULT_HOUSE_FEE;
    }

    function removeBurnFees() external onlyOwner {
        _currentPaperHandFee = 0;
        _currentGate1Fee = 0;
        _currentGate2Fee = 0;
    }

    function reinstateBurnFees() external onlyOwner {
        _currentPaperHandFee = DEFAULT_PAPER_HAND_FEE;
        _currentGate1Fee = DEFAULT_GATE1_FEE;
        _currentGate2Fee = DEFAULT_GATE2_FEE;
    }

    function removeAllFees() external onlyOwner {
        _currentHouseFee = 0;
        _currentPaperHandFee = 0;
        _currentGate1Fee = 0;
        _currentGate2Fee = 0;
    }

    function reinstateAllFees() external onlyOwner {
        _currentHouseFee = DEFAULT_HOUSE_FEE;
        _currentPaperHandFee = DEFAULT_PAPER_HAND_FEE;
        _currentGate1Fee = DEFAULT_GATE1_FEE;
        _currentGate2Fee = DEFAULT_GATE2_FEE;
    }

    // Update minimum tokens accumulated on the contract before a swap is performed
    function updateMinTokensBeforeSwap(uint256 newAmount) external onlyOwner {
        uint256 circulatingTokens = _totalTokens - balanceOf(_deadAddress);

        // The maximum tokens before swap is 1% of the circulating supply
        uint256 maxTokensBeforeSwap = circulatingTokens / 100;
        uint256 newMinTokensBeforeSwap = newAmount * 10**9;

        require(newMinTokensBeforeSwap < maxTokensBeforeSwap, "Amount must be less than 1 percent of the circulating supply");
        _minTokensBeforeSwap = newMinTokensBeforeSwap;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function addToOnlyDiamondHandTxs(address account) public onlyOwner {
        _onlyDiamondHandTxs[account] = true;
    }

    function removeFromOnlyDiamondHandTxs(address account) public onlyOwner {
        _onlyDiamondHandTxs[account] = false;
    }

    // If there is a PCS upgrade then add the ability to change the router and pairs to the new version
    function changeRouterVersion(address _router) public onlyOwner returns (address) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        address newPair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(newPair == address(0)){
            // Pair doesn't exist
            newPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }
        // Set the new pair
        uniswapV2Pair = newPair;

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;

        return newPair;
    }

    // Check all transactions and group transactions older than 21 days into their own bucket
    function _aggregateOldTransactions(address sender) private {
        uint256 totalBlockTimes = _timedTransactionsMap[sender].txBlockTimes.length;

        if (totalBlockTimes < 1) {
            return;
        }

        uint256 oldestBlockTime = block.timestamp - _gate2Time;

        // If the first transaction is not yet 21 days old then do not aggregate
        if (_timedTransactionsMap[sender].txBlockTimes[0] > oldestBlockTime) {
            return;
        }

        uint lastAggregateIndex = 0;
        uint256 totalTokens = 0;
        for (uint i = 0; i < totalBlockTimes; i++) {
            uint256 txBlockTime = _timedTransactionsMap[sender].txBlockTimes[i];

            if (txBlockTime > oldestBlockTime) {
                break;
            }

            totalTokens = totalTokens + _timedTransactionsMap[sender].timedTxAmount[txBlockTime];
            lastAggregateIndex = i;
        }

        _sliceBlockTimeArray(sender, lastAggregateIndex);

        _timedTransactionsMap[sender].txBlockTimes[0] = OVER_21_DAYS_BLOCK_TIME;
        _timedTransactionsMap[sender].timedTxAmount[OVER_21_DAYS_BLOCK_TIME] = totalTokens;
    }

    // _sliceBlockTimeArray removes elements before the provided index from the transaction block
    // time array for the given account. This is in order to keep an ordered list of transaction block
    // times.
    function _sliceBlockTimeArray(address account, uint indexFrom) private {
        uint oldArrayLength = _timedTransactionsMap[account].txBlockTimes.length;

        if (indexFrom <= 0) return;

        if (indexFrom >= oldArrayLength) {
            while (_timedTransactionsMap[account].txBlockTimes.length != 0) {
                _timedTransactionsMap[account].txBlockTimes.pop();
            }
            return;
        }

        uint newArrayLength = oldArrayLength - indexFrom;

        uint counter = 0;
        for (uint i = indexFrom; i < oldArrayLength; i++) {
            _timedTransactionsMap[account].txBlockTimes[counter] = _timedTransactionsMap[account].txBlockTimes[i];
            counter++;
        }

        while (newArrayLength != _timedTransactionsMap[account].txBlockTimes.length) {
            _timedTransactionsMap[account].txBlockTimes.pop();
        }
    }
}