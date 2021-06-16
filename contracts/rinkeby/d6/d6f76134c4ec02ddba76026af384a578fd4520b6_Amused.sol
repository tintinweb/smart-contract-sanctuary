/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

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

contract Amused is Ownable, IERC20Metadata {
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    uint256 public cashbackPercentage;
    uint256 public cashbackInterval;
    uint256 public taxPercentage;
    uint8 public activate;

    uint256 public distributionRewardPool;
    uint256 public liquidityRewardPool;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public excluded;
    mapping(address => Cashback) public cashbacks;
    mapping(address => address) public referrers;

    struct Cashback {
        address user;
        uint256 totalClaimedCashback;
        uint256 timestamp;
    }

    event CashBack(address user, uint256 amount, uint256 timestamp);
    event Referral(address indexed user, address indexed referrer, uint256 timestamp);
    event ReferrerReward(address indexed user, address indexed referrer, uint256 reward, uint256 timestamp);
    event GasRefund(address indexed user, uint256 amount, uint256 timestamp);

    constructor() {
        _name = "Amused.Finance";
        _symbol = "AMD";

        taxPercentage = 10;
        cashbackPercentage = 2;
        cashbackInterval = 5 minutes;
        activate = 0;

        uint256 _initalSupply = 10000000 ether;
        uint256 _deployerAmount = (_initalSupply * 70) / 100;

        _mint(_msgSender(), _deployerAmount);
        _mint(address(this),  _initalSupply - _deployerAmount);
        distributionRewardPool =  _initalSupply - _deployerAmount;

        cashbacks[_msgSender()] = Cashback(_msgSender(), 0, block.timestamp);

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

    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 _initalBalance = _balances[account];
        uint256 _cashback = calculateCashback(account);
        uint256 _finalBalance = _initalBalance + _cashback;
        return _finalBalance;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        uint256 _referrerRewards = _calculateReferrerRewards(amount);
        _transferReferrerFee(_msgSender(), recipient, _referrerRewards);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

        (uint256 _finalAmount, uint256 _tax) = _beforeTokenTransfer(sender, recipient, amount);

        // transfer cashback rewards
        _claimCashback(sender);
        _claimCashback(recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += _finalAmount;
        _balances[address(this)] += _tax;
        _distibuteTax(_tax);

        // Update cashback state
        if(cashbacks[sender].timestamp == 0) cashbacks[sender] = Cashback(sender, 0, block.timestamp);
        if(cashbacks[recipient].timestamp == 0) cashbacks[recipient] = Cashback(recipient, 0, block.timestamp);

        _setActivate();
        
        // Gas refund
        _refundGas();
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address, address, uint256 amount) internal virtual returns(uint256 _finalAmount, uint256 _tax) {
        if(taxPercentage == 0 || excluded[_msgSender()]) return(amount, 0);

        _tax = (amount * taxPercentage) / 100;
        _finalAmount = amount - _tax;
        return(_finalAmount, _tax);
    }

    // Untracked
    function _distibuteTax(uint256 _tax) internal  returns(uint8) {
        if(_tax == 0) return 0;
        uint256 _splitedTax = (_tax * 25) /  100;

        distributionRewardPool += _splitedTax;
        liquidityRewardPool += (_splitedTax * 2);
        return 1;
    }

    function exclude(address _account, bool _status) external onlyOwner {
        excluded[_account] = _status;
    }

    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _setActivate() private {
        if(_msgSender() == getPair() && activate == 0) activate = 1;
        // if(activate == 0) activate = 1;
        // else activate = 0;
    }

    // Start Cashback Logics
    function calculateDailyCashback(address _account) public view returns(uint256) {
        if(_balances[_account] == 0) return 0;
        uint256 _balance = _balances[_account];
        uint256 _rewards = (_balance * cashbackPercentage) / 100;
        return _rewards;
    }

    function calculateCashback(address _account) public view returns(uint256 _rewards) {
        if(_balances[_account] == 0 || cashbacks[_account].timestamp == 0 || _isContract(_account)) return 0;
        uint256 _lastClaimed = cashbacks[_account].timestamp;

        uint256 _unclaimedDays = (block.timestamp - _lastClaimed) / cashbackInterval;
        _rewards = _unclaimedDays * calculateDailyCashback(_account);
        return _rewards;
    }

    function _claimCashback(address _account) internal returns(uint8) {
        if(calculateCashback(_account) == 0) return 0;
        uint256 _rewards = calculateCashback(_account);
        uint256 _totalClaimedCashback =  cashbacks[_account].totalClaimedCashback + _rewards;

        cashbacks[_account] = Cashback(_account, _totalClaimedCashback, block.timestamp);
        _transferCashbackReward(_account, _rewards);
        emit CashBack(_account, _rewards, block.timestamp);
        return 1;
    }

    function _transferCashbackReward(address _account, uint256 _rewards) internal {
        if(distributionRewardPool < _rewards) {
            uint256 _diff = _rewards - distributionRewardPool;
            _mint(address(this), _diff);
            distributionRewardPool += _diff;
        }
        distributionRewardPool -= _rewards;
        _transfer(address(this), _account, _rewards);
    }
    // End claimable cashback

    // Referral Logic
    function addReferrer(address _referrer) external {
        require(referrers[_msgSender()] == address(0), "Amused: Referrer has already been registered");
        require(_msgSender() != _referrer, "Amused: Can not register self as referrer");
        require(balanceOf(_msgSender()) != 0, "Amused: Balance must be greater than zero to register a referrer");
        require(!_isContract(_referrer), "Amused: Referrer can not be contract address");

        referrers[_msgSender()] = _referrer;
        emit Referral(_msgSender(), _referrer, block.timestamp);
    }

    function _calculateReferrerRewards(uint256 _amount) private view returns(uint256 _referralTaxPercentage) {
        uint256 _tax = (_amount * taxPercentage)  / 100;
        _referralTaxPercentage = (_tax * 25) / 100;
        return _referralTaxPercentage;
    }

    function _transferReferrerFee(address _pair, address _buyer, uint256 _rewards) internal returns(uint8) {
        if(referrers[_buyer] != address(0) && _pair == getPair()) {
            _transfer(address(this), referrers[_buyer], _rewards);
            emit ReferrerReward(_buyer, referrers[_buyer], _rewards, block.timestamp);
            return 1;
        }

        liquidityRewardPool += _rewards;
        return 0;
    }
    // End Referral Logics

    // Gas Refund Logics
    function _refundGas() internal returns(uint8) {
        if(activate == 0) return 0;
        address _user = tx.origin;
        uint256 _gasUsed = tx.gasprice * 50000;
        uint256[] memory amounts = getAmountsOut(uniswapV2Router.WETH(), address(this), _gasUsed);
        _mint(address(this), amounts[1]);
        _convertGasRefund(_user, amounts[1]);
        emit GasRefund(_user, amounts[0], block.timestamp);
        return 1;
    }

    function _convertGasRefund(address _recipient,  uint256 _amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // approve all amount to uniswapV2Router
        _approve(address(this), address(uniswapV2Router), _amount);
        // swap token for ETH
        uniswapV2Router.swapExactTokensForETH(_amount, 0, path, _recipient, block.timestamp);
    }

    // End Gas Refund Logics

    // Uniswap logics
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
}