/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address tokenOwner) virtual public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) virtual public returns (bool success);
    function approve(address spender, uint256 tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeSwapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeSwapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external
    payable
    returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
    external
    payable
    returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public returns(bool) {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        return true;
    }
}

contract CaperCoinToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;

    address public devWallet = address(0);
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public _devFee = 5;
    uint256 public _liquidityFee = 3;
    uint256 private _previousDevFee = _devFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public numTokensSellToAddToLiquidity;

    IPancakeSwapV2Router02 public immutable pancakeSwapV2Router;
    address public pancakeSwapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping (address => bool) private _isExcludedFromFee;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 tokensIntoLiqudity,
        uint256 initialBalance,
        uint256 afterSellBalance,
        uint256 postLiquidityBalance
    );

    constructor() {
        symbol = "CAPER";
        name = "Caper Coin";
        decimals = 18;
        _totalSupply = 1000000000000 * 10**uint256(decimals); // 1 Trillion
        numTokensSellToAddToLiquidity = 1000000 * 10**(decimals); // 1 Million
        balances[msg.sender] = _totalSupply;

        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), _pancakeSwapV2Router.WETH());
        pancakeSwapV2Router = _pancakeSwapV2Router;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // ------------------------------------------ //
    //              Setters & Getters             //
    // ------------------------------------------ //

    function setDevWallet(address newAddress) external onlyOwner() {
        devWallet = newAddress;
    }

    function setExcludeFromFee(address account, bool shouldExclude) public onlyOwner() {
        _isExcludedFromFee[account] = shouldExclude;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner() {
        require(devFee > 0 && devFee < 100, "Invalid Value");
        _devFee = devFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee > 0 && liquidityFee < 100, "Invalid Value");
        _liquidityFee = liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    // ------------------------------------------ //
    //              BEP-20 Functions              //
    // ------------------------------------------ //

    function totalSupply() public override view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }
    
    function mint(address to, uint256 tokens) public onlyOwner returns (bool) {
        _totalSupply.add(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(0), to, tokens);
        return true;
    }
    
    function burn(uint256 tokens) public returns (bool) {
        _totalSupply.sub(tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (
            !inSwapAndLiquify &&
            from != pancakeSwapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));
            
            if (contractTokenBalance >= numTokensSellToAddToLiquidity) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }
        }

        bool exemptFromFee = false;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            exemptFromFee = true;
        }
        _tokenTransfer(from, to, amount, exemptFromFee);
    }

    function removeFees() private {
        _previousDevFee = _devFee;
        _devFee = 0;
        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = 0;
    }

    function restoreFees() private {
        _devFee = _previousDevFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool exemptFromFee) private {
        
        if (exemptFromFee)
            removeFees();

        uint256 devAmount = (amount.mul(_devFee)).div(100);
        uint256 liqudityAmount = (amount.mul(_liquidityFee)).div(100);
        uint256 transferAmount = (amount.sub(devAmount)).sub(liqudityAmount);

        balances[sender] = balances[sender].sub(amount);
        balances[devWallet] = balances[devWallet].add(devAmount);
        balances[address(this)] = balances[address(this)].add(liqudityAmount);
        balances[recipient] = balances[recipient].add(transferAmount);

        if (exemptFromFee)
            restoreFees();
        
	if (devAmount > 0) {
            emit Transfer(sender, devWallet, devAmount);
        }
        if (liqudityAmount > 0) {
            emit Transfer(sender, address(this), liqudityAmount);
        }
        emit Transfer(sender, recipient, transferAmount);
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function _approve(address owner, address spender, uint256 tokens) internal returns(bool) {
        allowed[owner][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        return _approve(msg.sender, spender, tokens);
    }

    function transferFrom(address _from, address to, uint256 tokens) public override returns (bool success) {
        _transfer(_from, to, tokens);
        _approve(_from, msg.sender, allowed[_from][msg.sender].sub(tokens));
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------ //
    //            PanCakeSwap Functions           //
    // ------------------------------------------ //
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        uint256 afterSellBalance = address(this).balance;
        uint256 newBalance = afterSellBalance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        payable(0x40F752B237C8A706aC7Ec01Cb4c2B9c6FEF21f26).transfer(address(this).balance);
        emit SwapAndLiquify(half, otherHalf, initialBalance, afterSellBalance, address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();

        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        // make the swap
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        // add the liquidity
        pancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }
}