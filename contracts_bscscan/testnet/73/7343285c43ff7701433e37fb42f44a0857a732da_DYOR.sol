/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function rNGfm99RfAqifzEoqjYY9NPszcDnpChRWu(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function rNGfm99RfAqifzEoqjYY9NPszcDnpChRWu(
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

interface SafeToken {
    function withdraw(address _token, uint256 _amount) external;
    function withdrawBNB(uint256 _amount) external;
}

contract DYOR is Context, IERC20, Ownable, SafeToken {
    using SafeMath for uint256;

    // User data
    struct userData {
        address userAddress;
        uint256 totalWon;
        uint256 lastWon;
        uint256 index;
        bool tokenOwner;
    }

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromLottery;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => userData) private userByAddress;
    mapping(uint256 => userData) private userByIndex;

    address[] private _excluded;
    address payable public _marketingWallet = payable(0x9E1F668B894Ccef835433828f692992233eEe457);
    address payable public safeManager;

    // An address used to transiently store the pot.
    // We can store the pot in memory, but an address allows us
    // to use the existing fee transfer abstractions as-is.
    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;

    string private _name     = "DO YOUR OWN RESEARCH";
    string private _symbol   = "DYOR";
    uint8 private  _decimals = 9;
    
    uint256 private _totalSupply = 1000000 * 10**_decimals;
    
    uint256 public  _totalFee     = 8;
    uint256 public  _marketingFee = 2; // marketing wallet
    uint256 public  _potFee       = 3; // pot fees
    
    uint256 public _buyFee        = 5;
    
    uint256 private _previousTotalFee = _totalFee;

    // 0.2%
    uint256 public _maxTxAmount = _totalSupply.mul(1).div(500);
    uint256 private minimumTokensBeforeSwap = _maxTxAmount.div(10);
    uint256 private buyBackUpperLimit = 2 * 10**18;

    // Last person who won, and the amount.
    uint256 private lastWinner_value;
    address private lastWinner_address;

    // -- Global stats --
    uint256 private _allWon;
    uint256 private _countUsers = 0;
    uint8 private w_rt = 0;
    uint256 private _txCounter = 0;

    // Lottery variables.
    uint256 private transactionsSinceLastLottery = 0;
    uint256 public potBalance = 0;
    uint256 public winAmount = 888000000000000000000;
    // auto liquidity
    IUniswapV2Router02 public uniswapV2Router;
    address            public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapBNBForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForBNB(
        uint256 amountIn,
        address[] path
    );
    bool public buyBackEnabled = true;

    event LotteryWon(address winner, uint256 amount);
    event LotterySkipped(address skippedAddress, uint256 _potAmount);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {

        // Give owner all the tokens
        _balances[owner()] = _totalSupply;

        // uniswap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // exclude system contracts
        _isExcludedFromFee[owner()]          = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_marketingWallet] = true;

        _isExcludedFromLottery[uniswapV2Pair] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[_burnAddress] = true;

        safeManager = _msgSender();

        emit Transfer(address(0), owner(), _totalSupply);
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
        return _balances[account];
    }

    function isUser(address userAddress) private view returns(bool isIndeed)
    {
        return userByAddress[userAddress].tokenOwner;
    }
    
    
    function insertUser(address userAddress, uint winnings) internal returns(uint256 index) {
        if (_isExcludedFromLottery[userAddress]) {
            return index;
        }

        userByAddress[userAddress] = userData(userAddress, winnings, winnings, _countUsers, true);
        userByIndex[_countUsers] = userData(userAddress, winnings, winnings, _countUsers, true);
        index = _countUsers;
        _countUsers += 1;

        return index;
    }

    function getUserAtIndex(uint index) private view returns(address userAddress)
    {
        return userByIndex[index].userAddress;
    }

    function getTotalWon(address userAddress) external view returns(uint totalWon) {
        return userByAddress[userAddress].totalWon;
    }

    function getLastWon(address userAddress) external view returns(uint lastWon) {
        return userByAddress[userAddress].lastWon;
    }

    function getTotalWon() external view returns(uint256) {
        return _allWon;
    }

    function getCirculatingSupply() public view returns(uint256){
        uint256 _bBurn = _balances[_burnAddress];
        return _totalSupply.sub(_bBurn);
    }

    function addWinner(address userAddress, uint256 _lastWon) internal {

        lastWinner_value = _lastWon;
        lastWinner_address = userAddress;
    }

    function getLastWinner() external view returns (address, uint256) {
        return (lastWinner_address, lastWinner_value);
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setFeesPercent(uint256 totalFee,uint256 marketingFee, uint256 buyFee,uint256 potFee) external onlyOwner {
        _totalFee = totalFee;
        _marketingFee = marketingFee;
        _buyFee = buyFee;
        _potFee = potFee;
    }

    function setMaxTx(uint256 maxTx) external onlyOwner {
        _maxTxAmount = maxTx;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function setMarketingAddress(address payable _marketingAddress) external onlyOwner() {
        _marketingWallet = _marketingAddress;
    }

    function setWinAmount(uint256 _winAmount) external onlyOwner() {
        winAmount = _winAmount;
    }

    receive() external payable {}

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if receiver is uniswap pair.
        */
        uint256 contractTokenBalance = _balances[address(this)];

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        // Buyback when transaction is selling
        bool isOverMinTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            
            // swap token to BNB for buyback when it's over minimum swap
            if (isOverMinTokenBalance) {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }
            // buy back 1% if balance bnb is exceed upper limit
            uint256 buyBackBalance = address(this).balance.sub(potBalance);
            if (buyBackEnabled && buyBackBalance > uint256(1 * 10**18)) {
                
                if (buyBackBalance > buyBackUpperLimit)
                    buyBackBalance = buyBackUpperLimit;
                
                buyBackTokens(buyBackBalance.div(100));
            }
        }
        bool changeFee = false;
        //if any account belongs to _isExcludedFromFee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            removeAllFee();
            changeFee = true;
        } else if(from == uniswapV2Pair){ // fee will be discounted when user buy token
            changeBuyingFee();
            changeFee = true;
        }
        
        _tokenTransfer(from, to, amount);
        
        if(changeFee)
            restoreAllFee();
    }
    
    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
       
        uint256 initialBalance = address(this).balance;
        swapTokensForBnb(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        //Send to Marketing address
        transferToAddressETH(_marketingWallet, transferredBalance.div(_totalFee).mul(_marketingFee));
        potBalance = potBalance.add(transferredBalance.div(_totalFee).mul(_potFee));
    }
    
    function buyBackTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {
    	    swapBnbForTokens(amount);
	    }
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );

        emit SwapTokensForBNB(tokenAmount, path);
    }

    function swapBnbForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            _burnAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapBNBForTokens(amount, path);
    }

    function changeBuyingFee() private {
        _previousTotalFee = _totalFee;
        _totalFee = _buyFee;
    }
    
        
    function removeAllFee() private {
        if(_totalFee == 0) return;
        
        _previousTotalFee = _totalFee;        
        _totalFee = 0;
    }
    
    function restoreAllFee() private {
        _totalFee = _previousTotalFee;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        feeData memory fd = _getValues(amount);

        _balances[sender]    = _balances[sender].sub(fd.tAmount);
        _balances[recipient] = _balances[recipient].add(fd.tTransferAmount);

        _balances[address(this)] = _balances[address(this)].add(fd.tFee);
        _handleLottery(recipient);
        emit Transfer(sender, address(this), fd.tFee);
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    struct feeData {

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tFee;
    }

    function _getValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory fd;
        fd.tAmount = tAmount;
        fd.tFee = tAmount.mul(_totalFee).div(100);
        fd.tTransferAmount = tAmount.sub(fd.tFee);
        return fd;
    }

    function random(uint256 _totalPlayers, uint8 _w_rt) private view returns (uint256) {

        uint256 w_rnd_c_1 = block.number.add(_txCounter).add(_totalPlayers);
        uint256 w_rnd_c_2 = _totalSupply.add(_allWon);
        uint256 _rnd = 0;
        if (_w_rt == 0) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), w_rnd_c_1, blockhash(block.number.sub(2)), w_rnd_c_2)));
        } else if (_w_rt == 1) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)),blockhash(block.number.sub(2)), blockhash(block.number.sub(3)),w_rnd_c_1)));
        } else if (_w_rt == 2) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), blockhash(block.number.sub(2)), w_rnd_c_1, blockhash(block.number.sub(3)))));
        } else if (_w_rt == 3) {
            _rnd = uint(keccak256(abi.encodePacked(w_rnd_c_1, blockhash(block.number.sub(1)), blockhash(block.number.sub(3)), w_rnd_c_2)));
        } else if (_w_rt == 4) {
            _rnd = uint(keccak256(abi.encodePacked(w_rnd_c_1, blockhash(block.number.sub(1)), w_rnd_c_2, blockhash(block.number.sub(2)), blockhash(block.number.sub(3)))));
        } else if (_w_rt == 5) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), w_rnd_c_2, blockhash(block.number.sub(3)), w_rnd_c_1)));
        } else {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), w_rnd_c_2, blockhash(block.number.sub(2)), w_rnd_c_1, blockhash(block.number.sub(2)))));
        }
        _rnd = _rnd % _totalPlayers;
        return _rnd;
    }


    function _handleLottery(address recipient) private returns (bool) {

        if (_countUsers == 0) {
            // Register the user if needed.
            if(!isUser(recipient)) {
                insertUser(recipient, 0);
            }

            return true;
        }

        // Increment counter
        transactionsSinceLastLottery = transactionsSinceLastLottery.add(1);


        uint256 _pot = potBalance;

        // Lottery time, but for real this time though
        if (_pot > winAmount) {

            uint256 _randomWinner = random(_countUsers, w_rt);
            address _winnerAddress = getUserAtIndex(_randomWinner);
            uint256 _balanceWinner = _balances[_winnerAddress];

            // You can only win if you own WINALAMBO and have 0.5% curculation supply
            uint256 _minBalance = _totalSupply
                .div(500);

            if (_balanceWinner >= _minBalance) {
                // Reward the winner handsomely.
                potBalance = 0;
                payable(_winnerAddress).transfer(_pot);

                emit LotteryWon(_winnerAddress, _pot);
                uint winnings = userByAddress[_winnerAddress].totalWon;
                uint256 totalWon = winnings.add(_pot);

                // Update user stats
                userByAddress[_winnerAddress].lastWon = _pot;
                userByAddress[_winnerAddress].totalWon = totalWon;
                uint256 _index = userByAddress[_winnerAddress].index;
                userByIndex[_index].lastWon = _pot;
                userByIndex[_index].totalWon = totalWon;

                // Update global stats
                addWinner(_winnerAddress, _pot);
                _allWon = _allWon.add(_pot);

                // Reset count and lottery pool.
                transactionsSinceLastLottery = 0;
            }
            else {
                // No one won, and the next winner is going to be even richer!
                emit LotterySkipped(_winnerAddress, _pot);
            }
        }

        // Register the user if needed.
        if(!isUser(recipient)) {
            insertUser(recipient, 0);
        }

        _txCounter += 1;

        return true;
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function withdraw(address _token, uint256 _amount) external override{
        require(msg.sender == safeManager);
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function withdrawBNB(uint256 _amount) external override{
        require(msg.sender == safeManager);
        _msgSender().transfer(_amount);
    }
}