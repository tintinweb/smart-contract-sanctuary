/**
 *Submitted for verification at Etherscan.io on 2021-06-04
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

/*
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

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract EthanolX01 is Ownable, IERC20Metadata {
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router;
    
    string private _name;
    string private _symbol;
    
    uint256 private _totalSupply;
    
    uint256 public startBlock;
    uint256 private _cashbackInterval;
    uint256 private _initialDitributionAmount;
    uint256 public ditributionRewardsPool;
    uint256 public taxPercentage;
    uint256 private _activateRefund;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => Cashback) public cashbacks;
    mapping(address => bool) public excluded;
    
    struct Cashback {
        address user;
        uint256 timestamp;
        uint256 totalClaimedRewards;
    }
    
    event CashBackClaimed(address indexed user, uint256 indexed amount, uint256 timestamp);
    event Refund(address user, uint256 amount, uint256 timestamp);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    constructor() {
        _name = "EthanolX";
        _symbol = "ENOX";
        
        uint256 _initialSupply = 1000000 ether;
        uint256 _minterAmount = (_initialSupply * 40) / 100;
        uint256 _ditributionAmount = (_initialSupply * 60) / 100;
        
        startBlock = block.timestamp;
        _cashbackInterval = 5 minutes;
        taxPercentage =  50;
        _activateRefund = 0;

        _initialDitributionAmount = _ditributionAmount;
        ditributionRewardsPool = _ditributionAmount;

        _mint(_msgSender(), _minterAmount);
        _mint(address(this), _ditributionAmount);

        // instantiate uniswapV2Router & uniswapV2Factory
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());

        // create uniswap pair for ENOX-WETH
        uniswapV2Factory.createPair(address(this), uniswapV2Router.WETH());

        // exclude deployer and uniswapV2Router from tax
        excluded[address(uniswapV2Router)] = true;
        excluded[getPair()] = true;
    }

    receive() external payable {  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns(uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns(uint256) {
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
        _claimCashback(_msgSender());
        // transfer token from caller to recipient
        _transfer(_msgSender(), recipient, amount);
        // refund gas used by caller
        _refundsBuySellGasFee();
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        // claim accumulated cashbacks for sender and the recipient
        _claimCashback(sender);
        _claimCashback(recipient);
        // transfer token from caller to recipient
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

       // refund gas used by caller
        _refundsBuySellGasFee();

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }



    function setExcludedStatus(address _account, bool _status) external onlyOwner {
        excluded[_account] = _status;
    }

    function activateRefund() external onlyOwner {
        require(_activateRefund == 0, "EthanolX: Gas refund have already been activated");
        _activateRefund = 1;
    }

    function contractEthBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function _calculateTax(uint256 _amount) internal view returns(uint256 _finalAmount, uint256 _tax) {
        if(taxPercentage == 0) return(_amount, 0);
        _tax = (_amount * taxPercentage) / 100;
        _finalAmount = _amount - _tax;
        return(_finalAmount, _tax);
    }

    function calculateRewards(address _account) public view returns(uint256) {
        if(_balances[_account] == 0) return 0;

        uint256 _lastClaimedTime = 0;

        /* 
            This logic sets the initial claimedTime to the timestamp the contract was deployed.
            Since the cashbacks[_account].timestamp will always be zero for all users when the contract is being deployed
        */
        cashbacks[_account].timestamp == 0 
            ? _lastClaimedTime = startBlock 
            : _lastClaimedTime = cashbacks[_account].timestamp;

        uint256 _unclaimedDays = (block.timestamp - _lastClaimedTime) / _cashbackInterval;
        uint256 _rewards = _unclaimedDays * calculateDailyCashback(_account);
        return _rewards;
    }

    function calculateDailyCashback(address _account) public view returns(uint256 _rewardsPerDay) {
        uint256 _holderBalance = _balances[_account];
        _rewardsPerDay = (_holderBalance * 2) / 100;
        return _rewardsPerDay;
    }

    function _claimCashback(address _account) internal returns(bool) {
        if(excluded[_account]) return false;

        uint256 _totalClaimedRewards = cashbacks[_account].totalClaimedRewards;

        uint256 _rewards = _transferRewards(_account);
        cashbacks[_account] = Cashback(_account, block.timestamp, _totalClaimedRewards + _rewards);
        emit CashBackClaimed(_account, _rewards, block.timestamp);
        return true;
    }

    function _transferRewards(address _account) private returns(uint256) {
        uint256 _rewards = calculateRewards(_account);
        uint256 _thirtyPercent = (_initialDitributionAmount * 30) / 100;
        uint256 _diff = _initialDitributionAmount - ditributionRewardsPool;

        if(ditributionRewardsPool < (_initialDitributionAmount - _thirtyPercent))  {
            _mint(address(this), _diff);
            ditributionRewardsPool += _diff;

        }
        ditributionRewardsPool -= _rewards;
        _transfer(address(this), _account, _rewards);
        return _rewards;
    }

    function _refundsBuySellGasFee() internal returns(uint8) {
        if(_activateRefund  == 0 || _msgSender() != address(uniswapV2Router)) return 0;
        // tx.origin => sender of the transaction
        address _caller = tx.origin;
        uint256 _gasRefund = _calclateRefundFee();
        _mint(_caller, _gasRefund);

        emit Refund(_caller, _gasRefund, block.timestamp);
        return 1;
    }

    function _calclateRefundFee() internal view returns(uint256) {
        uint256[] memory amounts;
        uint256 _gasUsed = 50 gwei * 210000;
        amounts = getAmountsOut(uniswapV2Router.WETH(), address(this), _gasUsed);
        return amounts[1];
    }

    function getAmountsOut(address token1, address token2, uint256 _amount) public view returns(uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        amounts = uniswapV2Router.getAmountsOut(_amount, path);
        return amounts;
    }

    function getPair() public view returns(address pair) {
        pair = uniswapV2Factory.getPair(address(this), uniswapV2Router.WETH());
        return pair;
    }

    function swapExactTokensForETH(address to, uint256 tokenAmount) public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // transfer tokens from caller to contract
        _transfer(_msgSender(), address(this), tokenAmount);

        // approve all transferred amount to uniswapV2Router
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // swap ENOX for ETH
        uniswapV2Router.swapExactTokensForETH(tokenAmount, 0, path, to, block.timestamp);
    }

    function swapExactETHForTokens() public payable {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            _msgSender(),
            block.timestamp
        );
    }

    function addLiquidityETH(uint256 tokenAmount) public payable {
        // transfer tokens from caller to contract
        _transfer(_msgSender(), address(this), tokenAmount);
        // approve all transferred amount to uniswapV2Router
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0,
            _msgSender(),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount) public {
        // transfer tokens from caller to contract
        _transfer(_msgSender(), address(this), tokenAmount);
        // approve all transferred amount to uniswapV2Router
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uint256 _half = tokenAmount / 2;

        address[] memory path = new address[](2);
        uint256[] memory amounts = getAmountsOut(address(this), uniswapV2Router.WETH(), _half);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        IWETH(uniswapV2Router.WETH()).approve(address(uniswapV2Router), amounts[1]);

        uniswapV2Router.swapExactTokensForTokens(_half, 0, path, owner(), block.timestamp);
        require(
            IWETH(uniswapV2Router.WETH()).allowance(_msgSender(), address(this)) > amounts[1], 
            "EthanolX: insufficient allowance from owner() address to EthanolX contract"
        );
        IWETH(uniswapV2Router.WETH()).transferFrom(owner(), address(this), amounts[1]);

        uniswapV2Router.addLiquidity(
            address(this),
            uniswapV2Router.WETH(),
            _half,
            amounts[1],
            0,
            0,
            owner(),
            block.timestamp
        );
    }


    // SafeMoon copied contract
    function swapAndLiquify(uint256 tokenAmount) public {
        // split the contract balance into halves
        uint256 half = tokenAmount / 2;

        uint256[] memory amounts = getAmountsOut(address(this), uniswapV2Router.WETH(), half);

        // transfeer tokens from caller to address(this)
        _transfer(_msgSender(), address(this), tokenAmount);
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // add liquidity to uniswap
        uniswapV2Router.addLiquidityETH{value: amounts[1]}(
            address(this),
            half,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _msgSender(),
            block.timestamp
        );
        emit SwapAndLiquify(half, amounts[1], half);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETH(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function fundAdminWallet(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    function withdrawETH() external onlyOwner {
        (bool _success, ) = payable(_msgSender()).call{ value: address(this).balance }(bytes(""));
        require(_success, "EthanolX: ETH withdrawal failed");
    }
}