// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "./UniSwapCommon.sol";

interface IERC20 {
    function balanceOf(address account) external returns (uint256);
}

contract LUCK is Context, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string public constant name = "LUCK";
    string public constant symbol = "LUCK";

    uint256 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => bool) _isExcludedFromFee;

    uint256 public _liquidityFee = 3;

    uint256 private _previousLiquidityFee = _liquidityFee;

    IUniswapV2Router02 public uniswapV2Router02;
    // address public uniswapV2Pair;

    uint256 constant TOTAL = 800_000_000 * 10**18;
    uint256 public _maxTxAmount = 8_000_000 * 10**18; //1% * total
    uint256 private numTokensToSwap = 120_000 * 10**18; //1.5% * 1% * total

    bool swapAndLiquifyEnabled;
    bool inSwapAndLiquify;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity,
        address pair
    );

    event SwapAndCharged(
        uint256 token,
        uint256 liquidAmount,
        uint256 bnbLiquidity
    );

    event ExcludedFromFee(address account);
    event IncludedToFee(address account);
    event UpdateFees(uint256 liquidityFee);
    event UpdatedMaxTxAmount(uint256 maxTxAmount);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    //pool's info
    mapping(address => uint256) private _poolIndexMap;
    address[] private _poolArray;

    address public SQUID;

    constructor() {
        // Test Net
        IUniswapV2Router02 _uniswapV2Router02 = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        SQUID = 0x8AC0E69f96CE8095125fCc9e3eE0Dd8e4Fd9cfbd;
        // Mian Net
        // IUniswapV2Router02 _uniswapV2Router02 = IUniswapV2Router02(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // );
        // SQUID = 0x87230146E138d3F296a9a77e497A2A83012e9Bc5;
        address uniswapV2PairEth = IUniswapV2Factory(
            _uniswapV2Router02.factory()
        ).createPair(address(this), _uniswapV2Router02.WETH());

        markPool(uniswapV2PairEth);
        address uniswapV2PairSquid = IUniswapV2Factory(
            _uniswapV2Router02.factory()
        ).createPair(address(this), SQUID);
        markPool(uniswapV2PairSquid);

        // set the rest of the contract variables
        uniswapV2Router02 = _uniswapV2Router02;

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _mint(_msgSender(), TOTAL);
    }

    function totalSupply() external pure returns (uint256) {
        return TOTAL;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to] &&
            !inSwapAndLiquify &&
            from != address(uniswapV2Router02) &&
            ((isPool(from) && balanceOf(from) > 0) ||
                (isPool(to) && balanceOf(to) > 0))
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensToSwap;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !isPool(from) &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensToSwap;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        if ((isPool(from) &&  balanceOf(from) > 0) || isPool(to) &&  balanceOf(to) > 0) {
            takeFee = true;
        }
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function isPool(address _pool) internal view returns (bool) {
        return _poolIndexMap[_pool] != 0;
    }

    function markPool(address _pool) internal returns (uint256) {
        if (_poolIndexMap[_pool] != 0) {
            return _poolIndexMap[_pool];
        }
        _poolArray.push(_pool);
        _poolIndexMap[_pool] = _poolArray.length;
        return _poolArray.length;
    }

    function removePool(address _pool) internal {
        require(isPool(_pool), "no exists");
        uint256 index = _poolIndexMap[_pool];
        require(index > 0, "invalid index");
        if (index < _poolArray.length) {
            _poolArray[index - 1] = _poolArray[_poolArray.length - 1];
            _poolIndexMap[_poolArray[index - 1]] = index;
            index = _poolArray.length;
        }
        delete _poolIndexMap[_pool];
        _poolArray.pop();
    }

    function sizeOfPool() internal view returns (uint256) {
        return _poolArray.length;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setFees(uint256 liquidityFee) external onlyOwner {
        require(_liquidityFee != liquidityFee);
        _liquidityFee = liquidityFee;
        emit UpdateFees(liquidityFee);
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
        emit UpdatedMaxTxAmount(maxTxAmount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _getFeeValues(uint256 tAmount) private view returns (uint256) {
        uint256 fee = (tAmount * _liquidityFee) / 10**2;
        uint256 tTransferAmount = tAmount - fee;
        return tTransferAmount;
    }

    function _swapAndLiquify(uint256 contractTokenBalance, address pair)
        private
    {
        IUniswapV2Pair _pair = IUniswapV2Pair(pair);
        address otherHalfToken = _pair.token0() != address(this)
            ? address(this)
            : _pair.token1();

        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = IERC20(otherHalfToken).balanceOf(
            address(this)
        );
        // swap tokens for ETH
        swapTokensForTokens(half, otherHalfToken); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = IERC20(otherHalfToken).balanceOf(address(this)) -
            initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance, otherHalfToken);

        emit SwapAndLiquify(half, newBalance, otherHalf, pair);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        contractTokenBalance = contractTokenBalance / _poolArray.length;
        for (uint256 i = _poolArray.length; --i > 0; ) {
            _swapAndLiquify(contractTokenBalance, _poolArray[i]);
        }
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function swapTokensForTokens(uint256 tokenAmount, address otherHalfToken)
        private
    {
        // generate the pancakeswap pair path of token -> token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = otherHalfToken;

        _approve(address(this), address(uniswapV2Router02), tokenAmount);

        // make the swap
        uniswapV2Router02.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 otherTokenAmount,
        address otherHalfToken
    ) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router02), tokenAmount);
        // approve token transfer to cover all possible scenarios
        _approve(otherHalfToken, address(uniswapV2Router02), otherTokenAmount);
        // add the liquidity
        uniswapV2Router02.addLiquidity(
            address(this),
            otherHalfToken,
            tokenAmount,
            otherTokenAmount,
            0,// slippage is unavoidable
            0,// slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function removeAllFee() private {
        if (_liquidityFee == 0) return;
        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        uint256 tTransferAmount = _getFeeValues(amount);
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + tTransferAmount;
        _balances[address(this)] =
            _balances[address(this)] +
            amount -
            tTransferAmount;
        emit Transfer(sender, recipient, tTransferAmount);
        if (!takeFee) restoreAllFee();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}