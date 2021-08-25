/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

interface obcproto {

    function noSandwich(address sender, address recipient, address pairAd) external returns (bool);

    function toggle() external returns(bool);

    function isActive() external view returns(bool);

    function setProtected(address prot) external;
}

contract RugBomb is Context, IERC20{

    //RugBomb tokenomics stuff
    mapping (uint256 => uint) private _epochTimestamp;
    mapping (uint16 => uint16) private _epochTax;
    mapping (uint16 => uint16) private _epochBurn;
    uint16 private _epoch;
    uint16 private _flatBuyFee = 3;
    bool private _liquifying;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 10 * 10**6 * 10**18; //ten million total supply

    string private _name = "RugBomb";
    string private _symbol = "RUGBOMB";
    uint8 private _decimals = 18;

    //hardcoded addresses - full transparency
    address payable private _devWallet = payable(0x8c750Cf74267476421A7b6E85E53BE47c003c20e); 
    address private _lpWallet = 0x570a4FbCAA21C7Cb2a1A04fa3724b023b801C1f3;
    address payable private _buyBackWallet = payable(0xc78A2f1E6a5d1E3C6152D4270985fC70C6dE9eDb);
    address private _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //canonical address for Uniswap Router02
    address private _pairAd = address(0);
    address private _obcAddress = 0xCE6c65764111337324ca3617D681c0616a4EDed2; //address for the BotCannon

    IUniswapV2Router02 private UniV2Router;
    obcproto private OBC;

    constructor() {
        _epoch = 0;
        _epochTimestamp[0] = 1629993600;
        _epochTimestamp[1] = 1630015200;
        _epochTimestamp[2] = 1630036800;
        _epochTimestamp[3] = 1630058400;
        _epochTimestamp[4] = 1630076400;
        _epochTimestamp[5] = 1630080000;
        _epochTax[0] = 5;
        _epochTax[1] = 4;
        _epochTax[2] = 3;
        _epochTax[3] = 2;
        _epochTax[4] = 0;
        _epochBurn[0] = 20;
        _epochBurn[1] = 16;
        _epochBurn[2] = 12;
        _epochBurn[3] = 8;
        _epochBurn[4] = 0;
        _balances[_lpWallet] = _totalSupply;
        OBC = obcproto(_obcAddress);
        UniV2Router = IUniswapV2Router02(_uniRouter);
    }

    modifier noRecursion {
        _liquifying = true;
        _;
        _liquifying = false;
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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        //first, we check to be sure epoch is set correctly
        _checkEpoch();

        //next, the BotCannon for sandwich prevention. this isn't a fucking deli.
        require (!OBC.noSandwich(sender, recipient, _pairAd));
        
        //one-time set pair address during addLiquidity, since that should be the first use of this function
        if (_pairAd == address(0) && sender != address(0)) {
            _pairAd = recipient; 
        }

        //ensure we're within the 24 hour countdown, unless it's the LP or the Uni router(for add/removeLiquidity)
        if (sender != _lpWallet && recipient != _lpWallet && recipient != _uniRouter)
        {
            require (block.timestamp >= _epochTimestamp[0] && block.timestamp <= _epochTimestamp[5], "RugBomb: No trades at this time");
            //token limit for first 15 minutes
            require (amount <= (_totalSupply * 5 / 1000) || block.timestamp > 1629994500);
        }
        

        //the usual ERC20 checks
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "Transfer = 0");
        
        //set defaults for fallback
        uint256 amountRemaining = amount;
        uint256 taxes = 0;
        uint256 buyBack = 0;

        //logic for buys
        if (sender == _pairAd && recipient != _lpWallet && recipient != _uniRouter && recipient != _buyBackWallet)
        {
            if (_epoch < 4) taxes = amount * _flatBuyFee / 100;
            amountRemaining = amount - taxes;
        }
        //logic for sells
        if (recipient == _pairAd && sender != _lpWallet && sender != address(this))
        {
            taxes = amount * _epochTax[_epoch] / 100;
            amountRemaining = amount - taxes;

            buyBack = amount * _epochBurn[_epoch] / 100;
            amountRemaining = amountRemaining - buyBack;
        }
        
        _balances[address(this)] += buyBack;        
        if (_balances[address(this)] > 100 * 10**18 && !_liquifying && recipient == _pairAd){
            if (_balances[address(this)] >= buyBack && buyBack > 100 * 10**18) 
                liquidateTokens(buyBack, _buyBackWallet);
        } 

        _balances[address(this)] += taxes;
        if (_balances[address(this)] > 100 * 10**18 && !_liquifying && recipient == _pairAd){
            uint256 _liqAmount = _balances[address(this)];
            if (_liqAmount > amount * 10 / 100) _liqAmount = amount * 10 / 100;
            liquidateTokens(_liqAmount, _devWallet);
        }
        //_balances[_devWallet] += taxes;
        //_balances[address(0)] += burn;
        _balances[recipient] += amountRemaining;
        _balances[sender] -= amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _checkEpoch() private {
        if (_epoch == 0 && block.timestamp >= _epochTimestamp[1]) _epoch = 1;
        if (_epoch == 1 && block.timestamp >= _epochTimestamp[2]) _epoch = 2;
        if (_epoch == 2 && block.timestamp >= _epochTimestamp[3]) _epoch = 3;
        if (_epoch == 3 && block.timestamp >= _epochTimestamp[4]) _epoch = 4;
        if (_epoch == 4 && block.timestamp >= _epochTimestamp[5]) _epoch = 5;
    }

    function currentEpoch() public view returns (uint16){
        return _epoch;
    }

    function pairAddr() public view returns (address){
        return _pairAd;
    }

    function sendETH(uint256 amount, address payable _to) private {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function liquidateTokens(uint256 amount, address payable recipient) private noRecursion {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();

        _approve(address(this), _uniRouter, amount);
        uint256 approval = _allowances[address(this)][_uniRouter];
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);

        if (address(this).balance > 0) sendETH(address(this).balance, recipient);
    }

    function emergencyWithdrawETH() external {
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        (bool sent, bytes memory data) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}