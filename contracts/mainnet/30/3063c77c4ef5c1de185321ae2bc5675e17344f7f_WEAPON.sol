/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.8.0;


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


contract WEAPON is Context, IERC20{

    uint256 private _txLimit;
    uint256 private _limitTime;
    
    bool private _swapping;

    bool public tradingEnabled = false;
    bool public stakingEnabled = false;

    mapping (address => bool) private _isPool;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _stakedBalances;
    mapping (address => uint256) private _stakeExpireTime;
    mapping (address => uint256) private _stakeBeginTime;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 10 * 10**6 * 10**9; 

    string private _name = "Megaweapon";
    string private _symbol = "$WEAPON";
    uint8 private _decimals = 9;
    uint8 private _buyTax = 10;
    uint8 private _sellTax = 10;

    address private _lp;
    address payable private _devWallet;
    address payable private _stakingContract;
    address private _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private _pair = address(0);

    IUniswapV2Router02 private UniV2Router;

    constructor(address dev) {
        _lp = _msgSender();
        _balances[_lp] = _totalSupply;
        UniV2Router = IUniswapV2Router02(_uniRouter);
        _devWallet = payable(dev);
    }

    event Stake(address indexed _staker, uint256 amount, uint256 stakeTime, uint256 stakeExpire);
    event Reconcile(address indexed _staker, uint256 amount, bool isLoss);


    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return availableBalanceOf(account);
    }

    function stakedBalanceOf(address account) public view returns (uint256) {
        if (stakingEnabled && _stakeExpireTime[account] > block.timestamp) {
            return _stakedBalances[account];    
        }
        else return 0;        
    }

    function availableBalanceOf(address account) public view returns (uint256) {
        if (stakingEnabled && _stakeExpireTime[account] > block.timestamp) {
            return _balances[account] - _stakedBalances[account];    
        }
        else return _balances[account];     
    }

    function isStaked(address account) public view returns (bool) {
        if (stakingEnabled && _stakeExpireTime[account] > block.timestamp && _stakedBalances[account] > 0){
            return true;
        }
        else return false;
    }

    function getStake(address account) public view returns (uint256, uint256, uint256) {
        if (stakingEnabled && _stakeExpireTime[account] > block.timestamp && _stakedBalances[account] > 0)
            return (_stakedBalances[account], _stakeBeginTime[account], _stakeExpireTime[account]);
        else return (0,0,0);
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(availableBalanceOf(sender) >= amount, "$WEAPON: transfer exceeds unstaked balance");
        require(amount > 0, "$WEAPON: cannot transfer zero");

        uint256 taxedAmount = amount;
        uint256 tax = 0;
    
        if (_isPool[sender] == true && recipient != _lp && recipient != _uniRouter) {
            require (block.timestamp > _limitTime || amount <= 50000 * 10**9, "$WEAPON: max tx limit");
            require (block.number > _txLimit, "$WEAPON: trading not enabled");
            tax = amount * _buyTax / 100;
            taxedAmount = amount - tax;
            _balances[address(this)] += tax;
        }
        if (_isPool[recipient] == true && sender != _lp && sender != _uniRouter){ 
            require (block.number > _txLimit, "$WEAPON: trading not enabled");
            require (block.timestamp > _limitTime || amount <= 50000 * 10**9, "$WEAPON: max tx limit");
            tax = amount * _sellTax / 100;
            taxedAmount = amount - tax;
            _balances[address(this)] += tax;

            if (_balances[address(this)] > 100 * 10**9 && !_swapping) {
                uint256 _swapAmount = _balances[address(this)];
                if (_swapAmount > amount * 40 / 100) _swapAmount = amount * 40 / 100;
                _tokensToETH(_swapAmount);
            }
        }
    
        _balances[recipient] += taxedAmount;
        _balances[sender] -= amount;

        emit Transfer(sender, recipient, amount);
    }

    function stake(uint256 amount, uint256 unstakeTime) external {
        require (stakingEnabled, "$WEAPON: staking currently not enabled"); 
        require (unstakeTime > (block.timestamp + 85399),"$WEAPON: minimum stake time 24 hours"); 
        require (unstakeTime >= _stakeExpireTime[_msgSender()], "$WEAPON: new stake time cannot be shorter");
        require (availableBalanceOf(_msgSender()) >= amount, "$WEAPON: stake exceeds available balance");
        require (amount > 0, "$WEAPON: cannot stake 0 tokens");

        if (_stakeExpireTime[_msgSender()] > block.timestamp) _stakedBalances[_msgSender()] = _stakedBalances[_msgSender()] + amount;
        else _stakedBalances[_msgSender()] = amount;
        _stakeExpireTime[_msgSender()] = unstakeTime;
        _stakeBeginTime[_msgSender()] = block.timestamp;

        emit Stake(_msgSender(), amount, block.timestamp, unstakeTime);
    }

    function reconcile(address[] calldata account, uint256[] calldata amount, bool[] calldata isLoss) external {
        require (_msgSender() == _stakingContract, "$WEAPON: Unauthorized");
        uint i = 0;
        uint max = account.length;
        while (i < max) {
            if (isLoss[i] == true) {
                if (_stakedBalances[account[i]] > amount[i]) _stakedBalances[account[i]] = _stakedBalances[account[i]] - amount[i];
                else _stakedBalances[account[i]] = 0;
                _balances[account[i]] = _balances[account[i]] - amount[i];
            }
            else { 
                _stakedBalances[account[i]] = _stakedBalances[account[i]] + amount[i];
                _balances[account[i]] = _balances[account[i]] + amount[i];
            }

            emit Reconcile(account[i], amount[i], isLoss[i]);
            i++;
        }
    }

    function mint(uint256 amount, address recipient) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        require (block.timestamp > 1640995200, "$WEAPON: too soon");
        _totalSupply = _totalSupply + amount;
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(address(0), recipient, amount);
    }

    function toggleStaking() external {
        require (_msgSender() == _devWallet || _msgSender() == _stakingContract, "$WEAPON: Unauthorized");
        require (_stakingContract != address(0), "$WEAPON: staking contract not set");
        if (stakingEnabled == true) stakingEnabled = false;
        else stakingEnabled = true;
    }

    function lockedAndLoaded(uint txLimit) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        require (tradingEnabled == false, "$WEAPON: already loaded, sucka");
        tradingEnabled = true;
        _setTxLimit(txLimit, block.number);
    }

    function setStakingContract(address addr) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        _stakingContract = payable(addr);
    }

    function getStakingContract() public view returns (address) {
        return _stakingContract;
    }

    function reduceBuyTax(uint8 newTax) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        require (newTax < _buyTax, "$WEAPON: new tax must be lower");
        _buyTax = newTax;
    }

    function reduceSellTax(uint8 newTax) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        require (newTax < _sellTax, "$WEAPON: new tax must be lower");
        _sellTax = newTax;
    }

    function setPool(address addr) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unuthorized");
        _isPool[addr] = true;
    }
    
    function isPool(address addr) public view returns (bool){
        return _isPool[addr];
    }

    function _setTxLimit(uint256 txLimit, uint256 limitBegin) private {
        _txLimit = limitBegin + txLimit;
        _limitTime = block.timestamp + 1800;
    }

    function _transferETH(uint256 amount, address payable _to) private {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _tokensToETH(uint256 amount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();

        _approve(address(this), _uniRouter, amount);
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);

        if (address(this).balance > 0) 
        {
            if (stakingEnabled) {
                uint stakingShare = address(this).balance * 20 / 100;
                _transferETH(stakingShare, _stakingContract);
            }
            _transferETH(address(this).balance, _devWallet);
        }
    }
    
    function failsafeTokenSwap(uint256 amount) external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        _tokensToETH(amount);
    }

    function failsafeETHtransfer() external {
        require (_msgSender() == _devWallet, "$WEAPON: Unauthorized");
        (bool sent, bytes memory data) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}