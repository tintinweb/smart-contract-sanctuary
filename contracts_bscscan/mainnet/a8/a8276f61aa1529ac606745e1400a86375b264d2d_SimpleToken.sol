/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

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


interface IDexRouter {
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


interface IDexFactory {
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

contract SimpleToken is IBEP20, Auth {

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "DenozToken";
    string constant _symbol = "DENOZ";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100;
	uint256 public _maxWalletAmount = _totalSupply / 50;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    // Fees and the denomintar to be divided by, by default (n / 10000).
    uint256 liquidityFee = 0;
    uint256 marketingFee = 700;
	uint256 devFee = 300;
	uint256 burnFee = 200;
    uint256 totalFee = liquidityFee + marketingFee + devFee + burnFee;
    uint256 feeDenominator = 10000;

    // Address that receives the LP newly created.
    address public autoLiquidityReceiver; 

    // Address that receives the marketing and development funds.
    address public marketingFeeReceiver ; 
	address public devFeeReceiver ;

    IDexRouter public router;
    address public pair;

    uint256 public launchedAt;
	bool private tradingDisabledOnce = false;
	bool private tradingDisabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor() Auth(msg.sender) {
        router = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //router = IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDexFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
			require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount > 0);
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        
        checkTxLimit(sender, recipient, amount);

        if (shouldSwapBack()) {
            swapBack();
        }

        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            require(sender == owner, "Only the owner can be the first to add liquidity.");
            launch();
        }

		require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient] && sender == pair, "TX Limit Exceeded");
		// Max wallet check.
		if (sender != owner
            && recipient != owner
            && !isTxLimitExempt[recipient]
            && recipient != ZERO 
            && recipient != DEAD 
            && recipient != pair 
            && recipient != address(this)
        ) {
            uint256 newBalance = balanceOf(recipient) + amount;
            require(newBalance <= _maxWalletAmount, "Exceeds max wallet.");
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee() public view returns (uint256) {
        if (block.number - launchedAt < 3) {
            return feeDenominator - 1;
        }
        return totalFee;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * (getTotalFee() - burnFee) / feeDenominator;
		uint256 burnAmount = 0;
		if (burnFee > 0) {
			burnAmount = amount * burnFee / feeDenominator;
			emit Transfer(sender, DEAD, burnAmount);
		}

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount - burnAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // We swap half the tokens for BNB, max slippage.
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
		uint256 bnbFee = totalFee - burnFee;

        if (marketingFee > 0 && marketingFeeReceiver != address(this)) {
            uint256 amountBNBMarketing = amountBNB * marketingFee / bnbFee;
            payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        }

		if (devFee > 0 && devFeeReceiver != address(this)) {
            uint256 amountBNBDev = amountBNB * devFee / bnbFee;
            payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        }
    }

	function rescue() external {
        payable(owner).transfer(address(this).balance);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

	function setWalletLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWalletAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
		devFee = _devFee;
        totalFee = _liquidityFee + marketingFee + devFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _devFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
		devFeeReceiver = _devFeeReceiver;
    }

    event AutoLiquify(uint256 amountBNB, uint256 autoBuybackAmount);
}