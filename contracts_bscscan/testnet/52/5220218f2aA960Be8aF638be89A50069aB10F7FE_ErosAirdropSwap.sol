/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity 0.6.12;


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

abstract contract BEP20 is OwnerRole, MinterRole {
    using SafeMath for uint256;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
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

    function totalSupplyWithoutDeadBalance() public view returns (uint256) {
        return totalSupply.sub(balanceOf(deadAddress));
    }

    function addMinter(address _minter) public onlyOwner override(MinterRole) {
        super.addMinter(_minter);
    }

    function removeMinter(address _minter) public onlyOwner override(MinterRole) {
        super.removeMinter(_minter);
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

        _transferAmount(_from, _to, _amount);
    }

    function _transferAmount(address _from, address _to, uint256 _amount) internal virtual {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
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

interface IReferral {

    function addReferrer(address _user, address _referrer) external;

    function addRewards(address _user, string memory _type, uint256 _total) external;

    function getRewards(address _user, string memory _type) external view returns (uint256);

    function getReferrer(address _user) external view returns (address);

    function getReferralsCount(address _referrer) external view returns (uint256);

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

    receive() external payable {}

    function _buyback(uint256 _amount) internal {
        _swapETHForTokens(_amount, deadAddress);
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

        if (antiWhaleEnabled && !isExcludedFromAntiWhale(_from) && !isExcludedFromAntiWhale(_to)) {
            require(_amount <= maxAntiWhaleTxAmount(), "BEP20: transfer amount exceeds the maxAntiWhaleTxAmount");
        }

        uint256 calculatedAmount = _amount;
        uint256 burnFeeAmount = 0;
        uint256 marketingFeeAmount = 0;
        uint256 buybackFeeAmount = 0;

        if (!inSwap && !(isExcludedFromFee(_from) || isExcludedFromFee(_to))) {
            burnFeeAmount = calcFee(_amount, burnFee);
            if (burnFeeAmount > 0) {
                address referrer = referral.getReferrer(msg.sender);
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

            if (marketingSwapEnabled && marketingBalance >= minMarketingSwapAmount && minMarketingSwapAmount > 0) {
                uint256 marketingSwapAmount = marketingBalance > maxMarketingSwapAmount ? maxMarketingSwapAmount : marketingBalance;
                if (marketingSwapAmount > 0 && marketingSwapAmount <= balanceOf(address(this))) {
                    _swapTokensForEth(marketingSwapAmount, marketingAddress);
                    marketingBalance = marketingBalance.sub(marketingSwapAmount);
                }
            }

            if (swapEnabled && buybackBalance >= minSwapAmount && minSwapAmount > 0) {
                uint256 swapAmount = buybackBalance > maxSwapAmount ? maxSwapAmount : buybackBalance;
                if (swapAmount > 0 && swapAmount <= balanceOf(address(this))) {
                    _swapTokensForEth(swapAmount, address(this));
                    buybackBalance = buybackBalance.sub(swapAmount);
                }
            }

            uint256 balance = address(this).balance;
            if (buybackEnabled && balance >= minBalanceRequired && minBalanceRequired > 0 && _amount >= minBuybackSellAmount && isLpToken(_to)) {
                uint256 buybackAmount = balance > maxBuybackAmount ? maxBuybackAmount : balance;
                if (buybackAmount > 0) {
                    _buyback(buybackAmount);
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
contract ErosAirdropSwap {

    BEP20e public token;
    BEP20 public airdropToken;

    event Swap(address indexed _address, uint256 _amount);

    constructor(BEP20e _token, BEP20 _airdropToken) public {
        token = _token;
        airdropToken = _airdropToken;
    }

    function swap(uint256 _amount) external {
        airdropToken.transferFrom(msg.sender, airdropToken.deadAddress(), _amount);
        token.mint(msg.sender, _amount);
        emit Swap(msg.sender, _amount);
    }

}