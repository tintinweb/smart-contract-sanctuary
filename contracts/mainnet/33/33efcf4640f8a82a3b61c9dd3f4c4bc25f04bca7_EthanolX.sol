/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

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

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract EthanolX is Ownable, IERC20Metadata {
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    uint256 public startTime;
    uint256 private _cashbackInterval;
    uint256 private _initialDitributionAmount;
    uint256 public ditributionRewardsPool;
    uint256 public liquidityRewardsPool;
    uint256 public taxPercentage;
    uint8 public activateFeatures;

    uint256 public stabilizingRewardsPool;
    uint8 public lastStabilizeAction;
    uint256 private _stabilizeTokenAmount;
    
    address public referralWallet;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => Cashback) public cashbacks;
    mapping(address => bool) public excluded;
    mapping(address => address) public referrers;
    mapping(address => uint256) public weeklyPayouts;

    struct Cashback {
        address user;
        uint256 timestamp;
        uint256 totalClaimedRewards;
    }
    
    event CashBackClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event Refund(address indexed user, uint256 amount, uint256 timestamp);
    event SwapAndAddLiquidity(address indexed sender, uint256 tokensSwapped, uint256 ethReceived);
    event Referral(address indexed user, address indexed referrer, uint256 timestamp);
    event Stablize(string action, uint256 tokenAmount, uint256 ethAmount, uint256 timestamp);

    constructor(address _referralWallet) {
        _name = "EthanolX";
        _symbol = "ENOX";
        
        uint256 _initialSupply = 10000000 ether;
        uint256 _minterAmount = (_initialSupply * 70) / 100;
        uint256 _ditributionAmount = (_initialSupply * 30) / 100;
        
        startTime = block.timestamp;
        _cashbackInterval = 24 hours;
        taxPercentage =  8;
        activateFeatures = 0;
        lastStabilizeAction = 0;
        _stabilizeTokenAmount = 1000 ether;

        _initialDitributionAmount = _ditributionAmount;
        ditributionRewardsPool = _ditributionAmount;

        _mint(_msgSender(), _minterAmount);
        _mint(address(this), _ditributionAmount);
        
        referralWallet = _referralWallet;

        /* 
            instantiate uniswapV2Router & uniswapV2Factory
            uniswapV2Router address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            pancakeswapV2Router address: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        */
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());

        // create ENOX -> WETH pair
        uniswapV2Factory.createPair(address(this), uniswapV2Router.WETH());

        excluded[address(this)] = true;
        excluded[address(uniswapV2Router)] = true;
        excluded[address(uniswapV2Factory)] = true;
        excluded[getPair()] = true;
    }

    receive() external payable {  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        uint256 _initialBalance = _balances[account];
        uint256 _finalBalance = _initialBalance + calculateRewards(account);
        return _finalBalance;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        // claim accumulated cashbacks
        _claimCashback(recipient);
        // transfer token from caller to recipient
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        // claim accumulated cashbacks for sender and the recipient
        _claimCashback(sender);
        _claimCashback(recipient);

        // transfer token from sender to recipient
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // calculate tax from transferred amount
        (uint256 _finalAmount, uint256 _tax) = _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += _finalAmount;
        _balances[address(this)] += _tax;
        _distributeTax(_tax);

        /*
            Note:: A static "startTime" might lead to an unforseen _cashback bug in the future.
            A way of mitigating this is to automaticaly update the startTime every 24 hours on deployment
        */
        if((block.timestamp - startTime) >= _cashbackInterval) startTime = block.timestamp;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address, address, uint256 amount) internal virtual returns(uint256 _finalAmount, uint256 _tax) {
        if(taxPercentage == 0 || activateFeatures == 0 || excluded[_msgSender()]) return(amount, 0);

        _tax = (amount * 8) / 100;
        _finalAmount = amount - _tax;
        return(_finalAmount, _tax);
    }
 


    function setActivateFeatures() external onlyOwner {
        if(activateFeatures == 0) activateFeatures = 1;
        else activateFeatures = 0;
    }

    function setExcluded(address _account, bool _status) external onlyOwner {
        excluded[_account] = _status;
    }

    function setTransferFee(uint256 _amount) public onlyOwner {
        taxPercentage = _amount;
    }

    function _distributeTax(uint256 _amount) internal returns(uint8) {
        if(getPair() == address(0) || activateFeatures == 0 || _amount == 0) return 0;
        uint256 _splitedAmount = _amount / 4; 

        /* 
            Add twice of the _splitedAmount to ditributionRewardsPool, 
            this will later be deducted as referrer's rewards
        */
        ditributionRewardsPool += (_splitedAmount * 2);
        stabilizingRewardsPool += _splitedAmount;
        liquidityRewardsPool += _splitedAmount;
        _balances[referralWallet] += _splitedAmount;
        return 1;
    }

    function injectLpToken() public onlyOwner returns(uint8) {
        if(liquidityRewardsPool == 0) return 0;
        _addLiquidity(liquidityRewardsPool);
        return 1;
    }
    
    function withdrawLpToken() external onlyOwner {
        _transfer(address(this), _msgSender(), liquidityRewardsPool);
        liquidityRewardsPool = 0;
    }

    // Start CashBack Logics
    function setCashbackInterval(uint256 _value) external onlyOwner {
        _cashbackInterval = _value;
    }

    function _claimCashback(address _account) internal returns(uint8) {
        if(calculateRewards(_account) == 0) return 0;
        uint256 _totalClaimedRewards = cashbacks[_account].totalClaimedRewards;

        uint256 _rewards = _transferRewards(_account);
        cashbacks[_account] = Cashback(_account, block.timestamp, _totalClaimedRewards + _rewards);
        emit CashBackClaimed(_account, _rewards, block.timestamp);
        return 1;
    }

    function calculateRewards(address _account) public view returns(uint256) {
        // should return zero is _account has zero balance || _account => contract address
        if(_balances[_account] == 0 || _isContract(_account) || _cashbackInterval == 0) return 0;

        uint256 _lastClaimedTime = 0;

        /* 
            This logic sets the initial claimedTime to the timestamp the contract was deployed.
            Since the cashbacks[_account].timestamp will always be zero for all users when the contract is being deployed
        */
        cashbacks[_account].timestamp == 0 
            ? _lastClaimedTime = startTime 
            : _lastClaimedTime = cashbacks[_account].timestamp;

        // calculates for the unclaimed days using (current time - last claimed time) / cashbackInterval (24 hours on deployment)
        uint256 _unclaimedDays = (block.timestamp - _lastClaimedTime) / _cashbackInterval;
        uint256 _rewards = _unclaimedDays * calculateDailyCashback(_account);
        return _rewards;
    }

    function calculateDailyCashback(address _account) public view returns(uint256 _rewardsPerDay) {
        uint256 _accountBalance = _balances[_account];
        _rewardsPerDay = (_accountBalance * 2) / 100;
        return _rewardsPerDay;
    }

    function _transferRewards(address _account) private returns(uint256) {
        uint256 _rewards = calculateRewards(_account);
        uint256 _seventyPercent = (ditributionRewardsPool * 70) / 100;
        uint256 _diff = ditributionRewardsPool - _initialDitributionAmount;

        if(ditributionRewardsPool <= _seventyPercent) {
            _mint(address(this), _diff);
            ditributionRewardsPool += _diff;
        } if(_rewards > ditributionRewardsPool) {
            _mint(address(this), _rewards);
            ditributionRewardsPool += _rewards;
        }

        ditributionRewardsPool -= _rewards;
        _transfer(address(this), _account, _rewards);
        return _rewards;
    }
    // End CashBack Logics

    // Referral Logics
    function registerReferrer(address _referrer) external {
        require(referrers[_msgSender()] == address(0), "EthanolX: Referrer has already been registered");
        require(_msgSender() != _referrer, "EthanolX: Can not register self as referrer");
        require(balanceOf(_msgSender()) != 0, "EthanolX: Balance must be greater than zero to register a referrer");
        require(!_isContract(_referrer), "EthanolX: Referrer can not be contract address");

        referrers[_msgSender()] = _referrer;
        emit Referral(_msgSender(), _referrer, block.timestamp);
    }

    // End Referral Logics

    // Stabilizing mechanism
    function stabilize() public onlyOwner {
        _stab();
    }
    
    function _stab() internal returns(uint8 _res) {
        address[] memory path = new address[](2);
        uint256[] memory amounts;
        /* 
            lastStabilizeAction == 0 => Swap ENOX -> ETH
            lastStabilizeAction == 1 => Swap ETH -> ENOX
        */
        if(lastStabilizeAction == 0) {
            if(stabilizingRewardsPool < _stabilizeTokenAmount) return 0;
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            amounts = getAmountsOut(address(this), uniswapV2Router.WETH(), _stabilizeTokenAmount);

            // approve _stabilizeTokenAmount to be swapped for ETH
            _approve(address(this), address(uniswapV2Router), _stabilizeTokenAmount);

            // swap ENOX => ETH
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_stabilizeTokenAmount, 0, path, address(this), block.timestamp);

            // re-set global state variable
            stabilizingRewardsPool -= _stabilizeTokenAmount;
            lastStabilizeAction = 1;
            emit Stablize("SELL", _stabilizeTokenAmount, amounts[1], block.timestamp);

        } else {
            path[0] = uniswapV2Router.WETH();
            path[1] = address(this);
            amounts = getAmountsOut(address(this), uniswapV2Router.WETH(), _stabilizeTokenAmount);
            // swap ETH => ENOX
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amounts[1]}(
                0,
                path,
                owner(),
                block.timestamp
            );
            _transfer(owner(), address(this), amounts[0]);
            // re-set global state variable
            stabilizingRewardsPool += _stabilizeTokenAmount;
            lastStabilizeAction = 0;
            emit Stablize("BUY", amounts[0], amounts[1], block.timestamp);
            return 1;
        }
    }
    
    function withdrawStabilizeRewards() public onlyOwner {
        _transfer(address(this), _msgSender(), stabilizingRewardsPool);
        stabilizingRewardsPool = 0;
    }

    function setStabilizeTokenAmount(uint256 _amount) external onlyOwner {
        _stabilizeTokenAmount = _amount;
    }

    function getStabilizeTokenAmount() external view returns(uint256) {
        return _stabilizeTokenAmount;
    }
    // End stabilizing mechanism

    // Uniswap Trade Logics
    function getPair() public view returns(address pair) {
        pair = uniswapV2Factory.getPair(address(this), uniswapV2Router.WETH());
        return pair;
    }

    function getAmountsOut(address token1, address token2, uint256 _amount) public view returns(uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        amounts = uniswapV2Router.getAmountsOut(_amount, path);
        return amounts;
    }

    function _addLiquidity(uint256 tokenAmount) private {
        uint256 _half = tokenAmount / 2;

        address[] memory path = new address[](2);
        uint256[] memory amounts = getAmountsOut(address(this), uniswapV2Router.WETH(), _half);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // approve transferred amount to uniswapV2Router
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _half, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );

        uniswapV2Router.addLiquidityETH{value: amounts[1]}(
            address(this),
            _half,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit SwapAndAddLiquidity(owner(), _half, amounts[1]);
    }

    function withdrawETH() external onlyOwner {
        (bool _success, ) = payable(_msgSender()).call{ value: address(this).balance }(bytes(""));
        require(_success, "EthanolX: ETH withdrawal failed");
    }

    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}