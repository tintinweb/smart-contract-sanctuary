/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

// File contracts/CactiToken.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

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

// File @uniswap/v2-periphery/contracts/interfaces/[email protected]beta.0

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

// File @uniswap/v2-core/contracts/interfaces/[email protected]

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract BPContract{
    function protect( address sender, address receiver, uint256 amount ) external virtual;
}

contract CACTI is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    BPContract public BP;
    bool private swapping;
    bool public bpEnabled;
    bool public BPDisabledForever = false;
    bool public canSwapAndLiquify = true;

    string private constant NAME = "Cacti";
    string private constant SYMBOL = "CACTI";
    uint8 private constant DECIMALS = 18;

    mapping(address => uint256) private rewards;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping (address => bool) public blacklist;
    mapping(address => bool) private excludedFromFees;

    mapping (address => bool) public excludeFromLiquify;

    uint public blacklistTime;
    
    uint256 private constant ACTUAL_TOTAL = 100_000_000 * 1e18;
    uint256 private marketingFeeTotal;
    uint256 private lpFeeTotal;

    uint256 public taxPercentage = 5;
    uint256 public marketingTaxAlloc = 20;
    uint256 public lpTaxAlloc = 80;
    uint256 public totalTaxAlloc = marketingTaxAlloc.add(lpTaxAlloc);
    uint256 public swapTokensAtAmount = 5000 * (10**18);

    address public marketingAddress = address(0);

    event UpdateMarkingFee(uint256 fee);
    event UpdateLiquidtyPoolFee(uint256 fee);
    event UpdateOperationsFee(uint256 fee);
    event UpdateBuybackFee(uint256 fee);
    event UpdateBountiesFee(uint256 fee);
    event UpdateDaoTreasuryFee(uint256 fee);
    event ExcludeFromFees(address indexed account);
    event IncludeInFees(address indexed account);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SetExcludeFromLiquify(address indexed pair, bool indexed value);
    
    constructor(address _marketingAddress) {
        // testnet router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        // mainnet router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        
        rewards[msg.sender] = ACTUAL_TOTAL;

        _setExcludeFromLiquify(uniswapV2Pair, true);

        excludeFromFees(_marketingAddress);
        excludeFromFees(_msgSender());
        excludeFromFees(address(this));

        marketingAddress = _marketingAddress;
        blacklistTime = block.timestamp + 3 days;
    }

    receive() external payable {}

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() external pure override returns (uint256) {
        return ACTUAL_TOTAL;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return rewards[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function isExcludedFromFees(address _account) external view returns (bool) {
        return excludedFromFees[_account];
    }

    function excludeFromFees(address _account) public onlyOwner() {
        require(!excludedFromFees[_account], "Account is already excluded from fee");
        excludedFromFees[_account] = true;
        emit ExcludeFromFees(_account);
    }

    function includeInFees(address _account) public onlyOwner() {
        require(excludedFromFees[_account], "Account is already included in fee");
        excludedFromFees[_account] = false;
        emit IncludeInFees(_account);
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);

        _approve(
        _sender,
            _msgSender(),
            allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance")
        );

        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, allowances[_msgSender()][_spender].add(_addedValue));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            _spender,
            allowances[_msgSender()][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function totalFees() external view returns (uint256) {
        return marketingFeeTotal.add(lpFeeTotal);
    }

    function totalMarketingFees() external view returns (uint256) {
        return marketingFeeTotal;
    }

    function totalLpFees() external view returns (uint256) {
        return lpFeeTotal;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _updateMarketingFee(address _sender, uint256 _marketingFee) private {
        if (marketingAddress == address(0)) {
            return;
        }

        marketingFeeTotal = marketingFeeTotal.add(_marketingFee);
        rewards[marketingAddress] = rewards[marketingAddress].add(_marketingFee);

        emit Transfer(_sender, marketingAddress, _marketingFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH 
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function switchSwapAndLiquify() external onlyOwner {
        canSwapAndLiquify = !canSwapAndLiquify;
    }

    function _updateLpFee(address _sender, uint256 _lpFee) private {
        if (uniswapV2Pair == address(0)) {
            return;
        }

        lpFeeTotal = lpFeeTotal.add(_lpFee);
        // Transfering the lp fee to the contract, in order to make a swap.
        rewards[address(this)] = rewards[address(this)].add(_lpFee);
        emit Transfer(_sender, address(this), _lpFee);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(!blacklist[_sender] && !blacklist[_recipient], "THE ADDRESS IS BLACKLISTED");
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        if (bpEnabled && !BPDisabledForever){
            BP.protect(_sender, _recipient, _amount);
        }

        uint256 fee = 0;
        if (!excludedFromFees[_sender] && !excludedFromFees[_recipient]) {
            // update fees
            fee = _getFee(_amount); 
            uint256 marketingFee = _getMarketingFee(fee);
            uint256 lpFee = _getLpFee(fee);

            _updateMarketingFee(_sender, marketingFee);
            _updateLpFee(_sender, lpFee);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(
            canSwap &&
            !swapping &&
            canSwapAndLiquify &&
            !excludeFromLiquify[_sender] 
        ) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }

        _transferWithRewards(_sender, _recipient, _amount, fee);
    }

    function _transferWithRewards(
        address _sender,
        address _recipient,
        uint256 _amount,
        uint256 _fee 
    ) private {
        rewards[_sender] = rewards[_sender].sub(_amount);
        rewards[_recipient] = rewards[_recipient].add(_amount).sub(_fee);

        emit Transfer(_sender, _recipient, _amount.sub(_fee));
    }

    function _originalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        rewards[sender] = rewards[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        rewards[recipient] = rewards[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _getActualValues(uint256 _actualAmount) private view returns (uint256) {
        uint256 actualFee = _getFee(_actualAmount);
        uint256 actualTransferAmount = _actualAmount.sub(actualFee);
        return actualTransferAmount;
    }

    function _getFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxPercentage).div(100);
    }

    function _getMarketingFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(marketingTaxAlloc).div(totalTaxAlloc);
    }

    function _getLpFee(uint256 _tax) private view returns (uint256) {
        return _tax.mul(lpTaxAlloc).div(totalTaxAlloc);
    }

    function _claimRemainingFunds() external onlyOwner {
        _transfer(address(this), owner(), balanceOf(address(this)));
        payable(address(owner())).transfer(address(this).balance);
    }

    function multiBlacklist(address[] memory addresses) external onlyOwner {
        require(block.timestamp <= blacklistTime, "BLACKLISTTIME: INVALID");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != uniswapV2Pair, "CAN'T BLACKLIST PAIR ADDRESS");
            blacklist[addresses[i]] = true;
        }
    }

    function multiRemoveFromBlacklist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * (10**18);
    }

    function _setExcludeFromLiquify(address pair, bool value) private {
        require(excludeFromLiquify[pair] != value, "Automated market maker pair is already set to that value");
        excludeFromLiquify[pair] = value;

        emit SetExcludeFromLiquify(pair, value);
    }

    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage >= 0 && _taxPercentage <= 10, "Value is outside of range 0-10");
        taxPercentage = _taxPercentage;
    }

    function setTaxAllocations(
        uint256 _marketingTaxAlloc,
        uint256 _lpTaxAlloc
    ) external onlyOwner {
        totalTaxAlloc = _marketingTaxAlloc.add(_lpTaxAlloc);
        // totalTaxAlloc Should be always 100
        require(totalTaxAlloc == 100, "totalTaxAlloc is less than 100");
        marketingTaxAlloc = _marketingTaxAlloc;
        lpTaxAlloc = _lpTaxAlloc;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "Marketing address can't be the zero address");
        marketingAddress = _marketingAddress;
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        require(_pair != address(0), "LP address can't be the zero address");
        uniswapV2Pair = _pair;
    }

    function setBPAddrss(address _bp) external onlyOwner {
        require(address(BP)== address(0), "Can only be initialized once");
        BP = BPContract(_bp);
    }

    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled;
    }

    function setBotProtectionDisableForever() external onlyOwner{
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }
}