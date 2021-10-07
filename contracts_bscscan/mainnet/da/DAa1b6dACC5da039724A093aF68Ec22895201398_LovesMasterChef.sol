/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity 0.6.12;


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

interface IReferral {

    function addReferrer(address _user, address _referrer) external;

    function addRewards(address _user, string memory _type, uint256 _total) external;

    function getRewards(address _user, string memory _type) external view returns (uint256);

    function getReferrer(address _user) external view returns (address);

    function getReferralsCount(address _referrer) external view returns (uint256);

}

abstract contract OwnerRole {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

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

abstract contract MinterRole {
    mapping(address => bool) private minters;

    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    constructor () public {
        addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Minterable: caller is not the minter");
        _;
    }

    function isMinter(address _minter) external view virtual returns (bool) {
        return minters[_minter];
    }

    function addMinter(address _minter) public virtual {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) public virtual {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }
}

abstract contract OperatorRole {
    mapping(address => bool) private operators;

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    constructor () public {
        addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function isOperator(address _minter) external view virtual returns (bool) {
        return operators[_minter];
    }

    function addOperator(address _operator) public virtual {
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }

    function removeOperator(address _operator) public virtual {
        operators[_operator] = false;
        emit OperatorRemoved(_operator);
    }
}

abstract contract BEP20e is OwnerRole, MinterRole, OperatorRole {
    using SafeMath for uint256;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public burnFee;
    uint256 public marketingFee;
    uint256 public buybackFee;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public marketingAddress;
    IUniswapV2Router02 public router;
    address public pair;
    IReferral public referral;

    uint256 public buybackBalance;
    uint256 public marketingBalance;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    bool private inSwap;

    bool public marketingSwapEnabled = false;
    uint256 public minMarketingSwapAmount = 1000000000000000000;
    uint256 public maxMarketingSwapAmount = 1500000000000000000;

    bool public swapEnabled = false;
    uint256 public minSwapAmount = 1000000000000000000;
    uint256 public maxSwapAmount = 1500000000000000000;

    bool public buybackEnabled = false;
    uint256 public minBalanceRequired = 1000000000000000000;
    uint256 public minBuybackSellAmount = 1000000000000000000;
    uint256 public maxBuybackAmount = 1500000000000000000;

    mapping(address => bool) private lpTokens;
    mapping(address => bool) private excludedFromFee;
    mapping(address => bool) private excludedFromAntiWhale;

    uint256 public antiWhaleTxAmountRate = 50; // 0.5%
    bool public antiWhaleEnabled = true;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event SwapETHForTokens(uint256 amountIn, address[] path);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(string memory _name, string memory _symbol, address _router, IReferral _referral) public {
        name = _name;
        symbol = _symbol;

        marketingAddress = msg.sender;

        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        referral = _referral;

        lpTokens[pair] = true;

        setExcludedFromFee(msg.sender, true);
        setExcludedFromAntiWhale(msg.sender, true);

        setExcludedFromFee(address(this), true);
        setExcludedFromAntiWhale(address(this), true);
    }

    function balanceOf(address _account) public view virtual returns (uint256) {
        return balances[_account];
    }

    function allowance(address _from, address _to) external view virtual returns (uint256) {
        return allowances[_from][_to];
    }

    function mint(address _to, uint256 _amount) external virtual onlyMinter {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external virtual {
        _burn(msg.sender, _amount);
    }

    function approve(address _to, uint256 _amount) external virtual returns (bool) {
        require(_amount > 0, "BEP20: amount is greater than zero");

        _approve(msg.sender, _to, _amount);
        return true;
    }

    function addBuybackBalance(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "BEP20: add amount exceeds balance");
        require(_amount > 0, "BEP20: amount is greater than zero");

        _transferAmount(msg.sender, address(this), _amount);

        buybackBalance = buybackBalance.add(_amount);
    }

    function transfer(address _to, uint256 _amount) external virtual returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external virtual returns (bool) {
        require(allowances[_from][msg.sender] >= _amount, "BEP20: transfer amount exceeds allowance");

        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, allowances[_from][msg.sender].sub(_amount));

        return true;
    }

    function increaseAllowance(address _to, uint256 _amount) external virtual returns (bool) {
        require(_amount > 0, "BEP20: amount is greater than zero");

        uint256 total = allowances[msg.sender][_to].add(_amount);
        _approve(msg.sender, _to, total);
        return true;
    }

    function decreaseAllowance(address _to, uint256 _amount) external virtual returns (bool) {
        require(allowances[msg.sender][_to] >= _amount, "BEP20: decreased allowance below zero");
        require(_amount > 0, "BEP20: amount is greater than zero");

        uint256 total = allowances[msg.sender][_to].sub(_amount);
        _approve(msg.sender, _to, total);
        return true;
    }

    function calcFee(uint256 _amount, uint256 _percent) public pure returns (uint256) {
        return _amount.mul(_percent).div(10000);
    }

    function totalSupplyWithoutDeadBalance() public view returns (uint256) {
        return totalSupply.sub(balanceOf(deadAddress));
    }

    function maxAntiWhaleTxAmount() public view returns (uint256) {
        return calcFee(totalSupplyWithoutDeadBalance(), antiWhaleTxAmountRate);
    }

    function buyback(uint256 _amount) public onlyOperator {
        uint256 balance = address(this).balance;

        require(_amount > 0, "BEP20: amount is greater than zero");
        require(balance >= _amount, "BEP20: buyback amount is too big");

        if (!inSwap) {
            _buyback(_amount);
        }
    }

    function swapMarketing(uint256 _amount) public onlyOperator {
        require(_amount > 0, "BEP20: amount is greater than zero");
        require(marketingBalance >= _amount, "BEP20: amount is too big");

        if (!inSwap) {
            _swapMarketing(_amount);
        }
    }

    function swapBuyback(uint256 _amount) public onlyOperator {
        require(_amount > 0, "BEP20: amount is greater than zero");
        require(buybackBalance >= _amount, "BEP20: amount is too big");

        if (!inSwap) {
            _swapBuyback(_amount);
        }
    }

    function setMarketingAddress(address _marketingAddress) external virtual onlyOperator {
        require(marketingAddress != address(0), "BEP20: zero address");

        marketingAddress = _marketingAddress;
    }

    function setMarketingSwapEnabled(bool _marketingSwapEnabled) external onlyOperator {
        marketingSwapEnabled = _marketingSwapEnabled;
    }

    function setMinMarketingSwapAmount(uint256 _minMarketingSwapAmount) external onlyOperator {
        minMarketingSwapAmount = _minMarketingSwapAmount;
    }

    function setMaxMarketingSwapAmount(uint256 _maxMarketingSwapAmount) external onlyOperator {
        maxMarketingSwapAmount = _maxMarketingSwapAmount;
    }

    function setSwapEnabled(bool _swapEnabled) external onlyOperator {
        swapEnabled = _swapEnabled;
    }

    function setMinSwapAmount(uint256 _minSwapAmount) external onlyOperator {
        minSwapAmount = _minSwapAmount;
    }

    function setMaxSwapAmount(uint256 _maxSwapAmount) external onlyOperator {
        maxSwapAmount = _maxSwapAmount;
    }

    function setBuybackEnabled(bool _buybackEnabled) external onlyOperator {
        buybackEnabled = _buybackEnabled;
    }

    function setMinBalanceRequired(uint256 _minBalanceRequired) external onlyOperator {
        minBalanceRequired = _minBalanceRequired;
    }

    function setMinBuybackSellAmount(uint256 _minBuybackSellAmount) external onlyOperator {
        minBuybackSellAmount = _minBuybackSellAmount;
    }

    function setMaxBuybackAmount(uint256 _maxBuybackAmount) external onlyOperator {
        maxBuybackAmount = _maxBuybackAmount;
    }

    function isLpToken(address _address) public view returns (bool) {
        return lpTokens[_address];
    }

    function setLpToken(address _address, bool _isLpToken) external onlyOperator {
        require(_address != address(0), "BEP20: invalid LP address");
        require(_address != pair, "BEP20: exclude bnb pair");

        lpTokens[_address] = _isLpToken;
    }

    function isExcludedFromFee(address _address) public view returns (bool) {
        return excludedFromFee[_address];
    }

    function setExcludedFromFee(address _address, bool _isExcludedFromFee) public onlyOperator {
        excludedFromFee[_address] = _isExcludedFromFee;
    }

    function isExcludedFromAntiWhale(address _address) public view returns (bool) {
        return excludedFromAntiWhale[_address];
    }

    function setExcludedFromAntiWhale(address _address, bool _isExcludedFromAntiWhale) public onlyOperator {
        excludedFromAntiWhale[_address] = _isExcludedFromAntiWhale;
    }

    function setAntiWhaleTxAmountRate(uint256 _antiWhaleTxAmountRate) external onlyOperator {
        require(_antiWhaleTxAmountRate <= 500 && _antiWhaleTxAmountRate >= 50, "BEP20: invalid _antiWhaleTxAmountRate");
        antiWhaleTxAmountRate = _antiWhaleTxAmountRate;
    }

    function setAntiWhaleEnabled(bool _antiWhaleEnabled) external onlyOperator {
        antiWhaleEnabled = _antiWhaleEnabled;
    }

    function addMinter(address _minter) public onlyOwner override(MinterRole) {
        super.addMinter(_minter);
    }

    function removeMinter(address _minter) public onlyOwner override(MinterRole) {
        super.removeMinter(_minter);
    }

    function addOperator(address _operator) public onlyOwner override(OperatorRole) {
        super.addOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner override(OperatorRole) {
        super.removeOperator(_operator);
    }

    function setReferral(IReferral _referral) external onlyOwner {
        referral = _referral;
    }

    receive() external payable {}

    function _buyback(uint256 _amount) internal {
        _swapETHForTokens(_amount, deadAddress);
    }

    function _swapMarketing(uint256 _marketingSwapAmount) internal {
        _swapTokensForEth(_marketingSwapAmount, marketingAddress);
        marketingBalance = marketingBalance.sub(_marketingSwapAmount);
    }

    function _swapBuyback(uint256 _swapAmount) internal {
        _swapTokensForEth(_swapAmount, address(this));
        buybackBalance = buybackBalance.sub(_swapAmount);
    }

    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "BEP20: mint to the zero address");
        require(_amount > 0, "BEP20: amount is greater than zero");

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: burn from the zero address");
        require(_amount > 0, "BEP20: amount is greater than zero");
        require(balances[_from] >= _amount, "BEP20: burn amount exceeds balance");

        _transferAmount(_from, deadAddress, _amount);
    }

    function _approve(address _from, address _to, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: approve from the zero address");
        require(_to != address(0), "BEP20: approve to the zero address");

        allowances[_from][_to] = _amount;
        emit Approval(_from, _to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: transfer from the zero address");
        require(_to != address(0), "BEP20: transfer to the zero address");
        require(balances[_from] >= _amount, "BEP20: transfer amount exceeds balance");
        require(_amount > 0, "BEP20: amount is greater than zero");

        if (antiWhaleEnabled && !isExcludedFromAntiWhale(_from) && !isExcludedFromAntiWhale(_to) && !isLpToken(_from)) {
            require(_amount <= maxAntiWhaleTxAmount(), "BEP20: transfer amount exceeds the maxAntiWhaleTxAmount");
        }

        uint256 calculatedAmount = _amount;
        uint256 burnFeeAmount = 0;
        uint256 marketingFeeAmount = 0;
        uint256 buybackFeeAmount = 0;

        if (!inSwap && !(isExcludedFromFee(_from) || isExcludedFromFee(_to))) {
            burnFeeAmount = calcFee(_amount, burnFee);
            if (burnFeeAmount > 0) {
                address referrer = address(0);
                if (isLpToken(_from) && !isLpToken(_to)) {
                    referrer = referral.getReferrer(_to);
                } else if (!isLpToken(_from) && isLpToken(_to)) {
                    referrer = referral.getReferrer(_from);
                } else {
                    referrer = referral.getReferrer(_from);
                }

                if (referrer != address(0)) {
                    _transferAmount(_from, referrer, burnFeeAmount);
                    referral.addRewards(referrer, "token", burnFeeAmount);
                } else {
                    _transferAmount(_from, address(this), burnFeeAmount);
                    buybackBalance = buybackBalance.add(burnFeeAmount);
                }
            }

            marketingFeeAmount = calcFee(_amount, marketingFee);
            if (marketingFeeAmount > 0) {
                _transferAmount(_from, address(this), marketingFeeAmount);
                marketingBalance = marketingBalance.add(marketingFeeAmount);
            }

            buybackFeeAmount = calcFee(_amount, buybackFee);
            if (buybackFeeAmount > 0) {
                _transferAmount(_from, address(this), buybackFeeAmount);
                buybackBalance = buybackBalance.add(buybackFeeAmount);
            }

            if (!isLpToken(_from)) {
                if (marketingSwapEnabled && marketingBalance >= minMarketingSwapAmount && minMarketingSwapAmount > 0) {
                    uint256 marketingSwapAmount = marketingBalance > maxMarketingSwapAmount ? maxMarketingSwapAmount : marketingBalance;
                    if (marketingSwapAmount > 0 && marketingSwapAmount <= balanceOf(address(this))) {
                        _swapMarketing(marketingSwapAmount);
                    }
                }

                if (swapEnabled && buybackBalance >= minSwapAmount && minSwapAmount > 0) {
                    uint256 swapAmount = buybackBalance > maxSwapAmount ? maxSwapAmount : buybackBalance;
                    if (swapAmount > 0 && swapAmount <= balanceOf(address(this))) {
                        _swapBuyback(swapAmount);
                    }
                }

                uint256 balance = address(this).balance;
                if (buybackEnabled && balance >= minBalanceRequired && minBalanceRequired > 0 && _amount >= minBuybackSellAmount && isLpToken(_to)) {
                    uint256 buybackAmount = balance > maxBuybackAmount ? maxBuybackAmount : balance;
                    if (buybackAmount > 0) {
                        _buyback(buybackAmount);
                    }
                }
            }

            calculatedAmount = calculatedAmount.sub(burnFeeAmount).sub(marketingFeeAmount).sub(buybackFeeAmount);
        }

        _transferAmount(_from, _to, calculatedAmount);
    }

    function _transferAmount(address _from, address _to, uint256 _amount) internal virtual {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    function _swapTokensForEth(uint256 _tokenAmount, address _recipient) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), _tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            _recipient,
            block.timestamp
        );

        emit SwapTokensForETH(_tokenAmount, path);
    }

    function _swapETHForTokens(uint256 amount, address _recipient) internal lockTheSwap {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : amount}(
            0, // accept any amount of Tokens
            path,
            _recipient, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

}

// SPDX-License-Identifier: MIT
contract LovesMasterChef is OwnerRole {
    using SafeMath for uint256;

    BEP20e public token;
    IReferral public referral;
    uint256 public referralRate = 300; // 3%

    uint256 public tokensPerBlock;
    uint256 public BONUS_MULTIPLIER = 1;
    uint256 public startBlock;
    uint256 public totalAllocPoint;
    uint256 public totalAllocPoint2;

    address public marketingAddress;

    struct PoolInfo {
        IBEP20 token;
        uint256 total;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokensPerShare;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 harvestInterval; // Harvest interval in seconds
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardLockedUp;
        uint256 nextHarvestAvailable; // When can the user harvest again.
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(BEP20e _token, uint256 _tokensPerBlock, uint256 _startBlock, IReferral _referral) public {
        token = _token;
        tokensPerBlock = _tokensPerBlock;
        startBlock = _startBlock;
        referral = _referral;

        marketingAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getMultiplier(uint256 _blockFrom, uint256 _blockTo) public view returns (uint256) {
        return _blockTo.sub(_blockFrom).mul(BONUS_MULTIPLIER);
    }

    function calcFee(uint256 _amount, uint256 _percent) public pure returns (uint256) {
        return _amount.mul(_percent).div(10000);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.total == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokensReward = multiplier.mul(tokensPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        if (tokensReward > 0) {
            token.mint(address(this), tokensReward);
            token.mint(address(marketingAddress), calcFee(tokensReward, 900));
        }

        pool.accTokensPerShare = pool.accTokensPerShare.add(tokensReward.mul(1e12).div(pool.total));
        pool.lastRewardBlock = block.number;
    }

    function pending(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accTokensPerShare = pool.accTokensPerShare;

        if (block.number > pool.lastRewardBlock && pool.total != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 treeReward = multiplier.mul(tokensPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

            accTokensPerShare = accTokensPerShare.add(treeReward.mul(1e12).div(pool.total));
        }

        uint256 total = user.amount.mul(accTokensPerShare).div(1e12).sub(user.rewardDebt);

        return total.add(user.rewardLockedUp);
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestAvailable;
    }

    function _send(IBEP20 _token, address _to, uint256 _amount) internal {
        _token.transfer(_to, _amount);
    }

    function harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestAvailable == 0) {
            user.nextHarvestAvailable = block.timestamp.add(pool.harvestInterval);
        }

        if (user.amount > 0) {
            uint256 pendingTokens = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingTokens > 0) {
                if (canHarvest(_pid, msg.sender)) {
                    uint256 totalRewards = pendingTokens.add(user.rewardLockedUp);

                    user.rewardLockedUp = 0;
                    user.nextHarvestAvailable = block.timestamp.add(pool.harvestInterval);

                    if (totalRewards > 0) {
                        safeTokenTransfer(msg.sender, totalRewards);
                    }
                } else {
                    user.rewardLockedUp = user.rewardLockedUp.add(pendingTokens);
                }
            }
        } else {
            if (canHarvest(_pid, msg.sender)) {
                uint256 totalRewards = user.rewardLockedUp;

                user.rewardLockedUp = 0;
                user.nextHarvestAvailable = block.timestamp.add(pool.harvestInterval);

                if (totalRewards > 0) {
                    safeTokenTransfer(msg.sender, totalRewards);
                }
            }
        }
    }

    function deposit(uint256 _pid, uint256 _amount, address _referrer) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        harvest(_pid);

        if (_amount > 0) {
            if (referral.getReferrer(msg.sender) == address(0) && _referrer != address(0) && _referrer != msg.sender) {
                referral.addReferrer(msg.sender, _referrer);
            }

            uint256 oldBalance = tokenBalanceOf(address(pool.token), address(this));
            pool.token.transferFrom(msg.sender, address(this), _amount);
            uint256 newBalance = tokenBalanceOf(address(pool.token), address(this));

            _amount = newBalance.sub(oldBalance);

            if (pool.depositFee > 0) {
                uint256 totalDepositFeeAmount = calcFee(_amount, pool.depositFee);

                // marketing
                if (tokenBalanceOf(address(pool.token), address(this)) >= totalDepositFeeAmount) {
                    _send(pool.token, marketingAddress, totalDepositFeeAmount);
                    _amount = _amount.sub(totalDepositFeeAmount);
                }
            }

            user.amount = user.amount.add(_amount);
            pool.total = pool.total.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount);

        updatePool(_pid);

        harvest(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.total = pool.total.sub(_amount);

            if (pool.withdrawFee > 0) {
                uint256 withdrawFeeAmount = calcFee(_amount, pool.withdrawFee);

                _send(pool.token, marketingAddress, withdrawFeeAmount);
                _amount = _amount.sub(withdrawFeeAmount);
            }

            _send(pool.token, msg.sender, _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;

        if (amount > 0) {
            user.amount = 0;
            user.rewardDebt = 0;
            user.rewardLockedUp = 0;
            user.nextHarvestAvailable = 0;

            pool.total = pool.total.sub(amount);

            if (pool.withdrawFee > 0) {
                uint256 withdrawFeeAmount = calcFee(amount, pool.withdrawFee);

                _send(pool.token, marketingAddress, withdrawFeeAmount);
                amount = amount.sub(withdrawFeeAmount);
            }

            _send(pool.token, msg.sender, amount);

            emit EmergencyWithdraw(msg.sender, _pid, amount);
        }
    }

    function tokenBalanceOf(address _token, address _address) internal view returns (uint256) {
        return IBEP20(_token).balanceOf(_address);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = tokenBalanceOf(address(token), address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        if (_amount > 0) {
            token.transfer(_to, _amount);

            address referrer = referral.getReferrer(_to);
            if (referrer != address(0)) {
                uint256 totalRewards = calcFee(_amount, referralRate);
                if (totalRewards > 0) {
                    referral.addRewards(referrer, "master-chef", totalRewards);
                    token.mint(address(this), totalRewards);
                    token.transfer(referrer, totalRewards);
                }
            }
        }
    }

    function add(IBEP20 _token, uint256 _allocPoint, uint256 _depositFee, uint256 _withdrawFee, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFee >= 0 && _depositFee <= 1000);
        require(_withdrawFee >= 0 && _withdrawFee <= 500);
        require(_harvestInterval <= 15 days);

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
        token : _token,
        total : 0,
        allocPoint : _allocPoint,
        lastRewardBlock : block.number > startBlock ? block.number : startBlock,
        accTokensPerShare : 0,
        depositFee : _depositFee,
        withdrawFee : _withdrawFee,
        harvestInterval : _harvestInterval
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFee, uint256 _withdrawFee, uint256 _harvestInterval, bool _withUpdate) external onlyOwner {
        require(_depositFee >= 0 && _depositFee <= 1000);
        require(_withdrawFee >= 0 && _withdrawFee <= 500);
        require(_harvestInterval <= 15 days);

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].withdrawFee = _withdrawFee;
        poolInfo[_pid].harvestInterval = _harvestInterval;

        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    function setReferralRate(uint256 _rate) external onlyOwner {
        require(_rate >= 0 && _rate <= 1000);
        referralRate = _rate;
    }

    function setBonusMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier > 0);
        BONUS_MULTIPLIER = _multiplier;
    }

    function updateMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function updateTokensPerBlock(uint256 _tokensPerBlock) external onlyOwner {
        massUpdatePools();
        tokensPerBlock = _tokensPerBlock;
    }

    function setReferral(IReferral _referral) external onlyOwner {
        referral = _referral;
    }

}