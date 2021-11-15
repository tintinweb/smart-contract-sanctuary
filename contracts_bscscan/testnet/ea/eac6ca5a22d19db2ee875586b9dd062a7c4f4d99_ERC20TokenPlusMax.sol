/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool)
    {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly
        {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getTime() public view returns (uint256)
    {
        return block.timestamp;
    }
}

interface IUniswapV2Factory
{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair
{
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01
{
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}





contract ERC20TokenPlusMax is Context, IERC20Metadata, Ownable {
    
    using SafeMath for uint256;                                             // SafeMath library.
    using Address for address;                                              // Address library.

    event _Receive(address _sender, uint256 _amount);                       // events receiver.
    event Burn(address indexed account, uint256 amount);                    // events burn.
    event Logg(address indexed _acct);                                      // events logs.

    mapping(address => uint256) private _balances;                          // addresses balances storage.
    mapping(address => mapping(address => uint256)) private _allowances;    // addresses allowances storage.
    mapping(address => bool) private accountsExcludedFromFees;              // addresses exluded from fee storage.

    address _owner;                                                         // address _owner.
    uint256 private _timeTokenLaunched;                                     // token launch timestamp.

    

    string private constant _name = "Trinity1";                             // token name.
    string private constant _symbol = "tnt";                                // token symbol.
    uint8 private constant _decimals = 9;                                   // token decimals.
    uint256 private  _totalTokens;                                          // token total supply.

    bool _isInitialized = false;                                            // is token initialized, ddfaut => false.
    bool isBurnEnabled = true;                                              // burnable true or false, ddfaut => true.
    bool isMarketingFeeFundEnabled = true;                                  // marketing fee true or false, ddfaut => true.
    bool isDevFundFeeEnabled = true;                                        // dev fee true or false, ddfaut => true.


    uint256 burnFeeInPercent = 1;                                           // burn fee percentage value.
    uint256 buyBurnFee = 0;                                                 // buy burn fee percentage value.
    uint256 sellBurnFee = 1;                                                // sell burn fee true or false.
    uint256 private _burnTokens = 0;                                        // acuumulated burn fee.

    uint256 devFundFeeInPercent = 5;                                        // dev fee percentage value.
    uint256 buyDevFee = 0;                                                  // buy dev fee percentage value.
    uint256 sellDevFee = 1;                                                 // sell dev fee percentage value.
    uint256 private _devTokens = 0;                                         // acuumulated dev fee.

    uint256 private constant _maxHighTaxTime = 1 days;                      // Max time for handling sell.
    uint256 marketingFundFeeInPercent = 5;                                  // marketing fee true or false
    uint256 buyMarketingFee = 0;                                            // buy marketing fee true or false
    uint256 sellMarketingFee = 1;                                           // sell marketing fee true or false
    uint256 private _marketingTokens = 0;                                   // acuumulated marketing fee


    bool private _taxesEnabled = true;                                      // global tax handler for enableing/disabling all taxes, default => true.

    bool isSwapAndLiquifyLocked;                                            // check if swap and is locked, default => undefined.
    address liquidityOwnerAddress;                                          // liquidity owner address,  default =>  owner.
    uint256 private _liquidityTokens;                                       // liquidity tokens, default => undefined and unused
    address payable foundersDevAndMarketingAddress;                         // founders dev and marketing wallet address. default => owner.
    uint256 private foundersSwapAmountFees;                                 // founders swap total collected BNB.
    
    address payable devAndMarketingFundAddress;
    uint256 private totalAmountForDevAndMarketing;
    
    address private addressV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;       // uniswap V2Router production addreess.
    IUniswapV2Router02 public  uniswapV2Router;                                         // uniswap V2Router
    address public  uniswapV2Pair;                                                      // uniswapV 2Pair




    constructor()  {
    
        uint256 totalInitialSupply = 2 * 10 ** 9 * 10 ** _decimals;

        _mint(_msgSender(), totalInitialSupply);
    
        
        devAndMarketingFundAddress =  payable(msg.sender);
        liquidityOwnerAddress = msg.sender;
        
        accountsExcludedFromFees[address(this)] = true;
        accountsExcludedFromFees[owner()] = true;
        accountsExcludedFromFees[foundersDevAndMarketingAddress] = true;

      


        if (block.chainid == 1 || block.chainid == 3 || block.chainid == 42) {//ethereum based chains (uniswap)

            uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        } else if (block.chainid == 97) {// bsc testnet pancake testnet

            uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        } else if (block.chainid == 56) {// bsc main net pancake mainnet

            uniswapV2Router = IUniswapV2Router02(addressV2Router);

        } else {
            revert("Unsupported chain Id");
        }

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());


        _timeTokenLaunched = block.timestamp;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalTokens;
    }

 function getDevMarketingWal() external view returns (address) {
        return devAndMarketingFundAddress;
    }
    
    function getTotalFee() public view returns (uint256){
        uint256 fee = 0;
        if(!_taxesEnabled){
            return fee;
        }
        if (isBurnEnabled) {fee += burnFeeInPercent;}
        if (isDevFundFeeEnabled) {fee += devFundFeeInPercent;}
        if (isMarketingFeeFundEnabled) {fee += marketingFundFeeInPercent;}
        return fee;
    }
    
     /**
     * get totalAmountForDevAndMarketing
     */
    function getTotalAmountForDevAndMarketing () public view returns(uint256) {
        return totalAmountForDevAndMarketing;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }


    function setEnableBurn(bool _option) public onlyOwner() {
        isBurnEnabled = _option;
    }


    function setEnableDevFundFee(bool _option) public onlyOwner() {
        isDevFundFeeEnabled = _option;
    }

    function setEnableMarketingFundFee(bool _option) public onlyOwner() {
        isMarketingFeeFundEnabled = _option;
    }

    function setDevFundFee(uint256 _value) public onlyOwner() {
        devFundFeeInPercent = _value;
    }

    function setDevBuyFee(uint256 _value) public onlyOwner() {
        buyDevFee = _value;
    }

    function setDevSellFee(uint256 _value) public onlyOwner() {
        sellDevFee = _value;
    }

    function setBurnFee(uint256 _value) public onlyOwner() {
        burnFeeInPercent = _value;
    }

    function setBurnFeeBuy(uint256 _value) public onlyOwner() {
        buyBurnFee = _value;
    }

    function setBurnFeeSell(uint256 _value) public onlyOwner() {
        sellBurnFee = _value;
    }

    function setMarketingFundFee(uint256 _value) public onlyOwner() {
        marketingFundFeeInPercent = _value;
    }

    function setMarketingFeeBuy(uint256 _value) public onlyOwner() {
        buyMarketingFee = _value;
    }

    function setMarketingFeeSell(uint256 _value) public onlyOwner() {
        sellMarketingFee = _value;
    }
    //set dev and marketing fund  wallet
    function setDevAndMarketingAddress(address payable _wallet) external onlyOwner {
        foundersDevAndMarketingAddress = _wallet;
    }
      //set dev and marketing fund  wallet
    function setDevAndMarketingFundWallet(address payable _wallet) external onlyOwner {
        devAndMarketingFundAddress = _wallet;
    }


    event LaunchTaxChanged(uint256 marketingfee);

    function setInitialLaunchTaxes(uint256 amount) public onlyOwner()
    {
        require(getTime() < _timeTokenLaunched + _maxHighTaxTime, "Past Allowed High Tax Period");
        require(amount < 670, "Can't exceed maximum sell tax of 80%");
        sellMarketingFee = amount;
        emit LaunchTaxChanged(sellMarketingFee);
    }


    function getTotalBuyFee() public view returns (uint256){
        uint256 fee = 0;
        if (!_taxesEnabled) return fee;
        // if the tax is disabled no fee is 0;
        if (isBurnEnabled) fee += buyBurnFee;
        // if the burn is enabled add to fee;
        if (isDevFundFeeEnabled) fee += buyDevFee;
        // if the dev is enabled add to fee;
        if (isMarketingFeeFundEnabled) fee += buyMarketingFee;
        // if the marketing is enabled add to fee;
        return fee;
        // returns total fee from enabled fees (burn, dev, marketing).
    }


    function getTotalSellFee() public view returns (uint256){
        uint256 fee = 0;
        if (!_taxesEnabled) return fee;
        // if the tax is disabled no fee is 0;
        if (isBurnEnabled) fee += sellBurnFee;
        // if the burn is enabled add sell burn fee to total fee;
        if (isDevFundFeeEnabled) fee += sellDevFee;
        // if the dev is enabled add sell dev fee to total fee;
        if (isMarketingFeeFundEnabled) fee += sellMarketingFee;
        // if the marketing is enabled  add sell marketing fee to total fee;
        return fee;
        // returns total fee from enabled fees (burn, dev, marketing).
    }

    function excludeFromFees(address _account) public onlyOwner() returns (bool){
        accountsExcludedFromFees[_account] = true;
        return true;
    }

    function removeExcludedFromFees(address _account) public onlyOwner() returns (bool){
        delete accountsExcludedFromFees[_account];
        return true;
    }

    function isExcludedFromFees(address _account) public view returns (bool){
        return accountsExcludedFromFees[_account];
    }


    function getTotalAmountFoundersSwapFee() public view returns (uint256) {
        return foundersSwapAmountFees;
    }

    event TaxesEnabled(bool enabled);

    function takeTaxes(bool _enabled) external onlyOwner
    {
        _taxesEnabled = _enabled;
        emit TaxesEnabled(_taxesEnabled);
    }

    function computePercentageToAmount(uint256 percentageValue, uint256 amount) private pure returns (uint256) {
        return amount * (percentageValue.mul(100)) / 10_000;
    }



    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalTokens = _totalTokens.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }


    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalTokens = _totalTokens.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev toggle swap and add liquidity mode
    */
    modifier lockSwapAndLiquify {
        isSwapAndLiquifyLocked = true;
        _;
        isSwapAndLiquifyLocked = false;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(amount > 0, "Amount cannot be less than 0");
        require(_balances[sender] >= amount, "Insufficient balance");

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 amountToTransfer = amount;
        if (_taxesEnabled) {
            amountToTransfer = _preProcessTransfer(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender].sub(amountToTransfer, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountToTransfer);

        emit Transfer(sender, recipient, amountToTransfer);
    }



     function _preProcessTransfer(address sender, address recipient, uint256 amount) private returns(uint256) {

        if(isExcludedFromFees(sender) || isExcludedFromFees(recipient) || isSwapAndLiquifyLocked){
            return amount;
        }

        //uint256 originalAmount = amount;

        //lets get totalTax to deduct
        uint256 totalFeeToDeduct =  computePercentageToAmount(getTotalFee(), amount);

        uint256 amountWithFee = amount.sub(totalFeeToDeduct);

        //process burn
        if(burnFeeInPercent > 0 && isBurnEnabled) {
            uint256 _amountToBurn = computePercentageToAmount(burnFeeInPercent, amount);
            _burn(sender, _amountToBurn);
        } //end process burn

        uint256 _devMarketingLiquidityAmount;
        uint256 _devAndMarketingAmount;
        //uint256 _liquidityFeeAmount;

        /*if(isLiquidityEnabled && liquidityFeeInPercent > 0) {
            _liquidityFeeAmount = computePecentToAmount(liquidityFeeInPercent, amount);
            _devMarketingLiquidityAmount += _liquidityFeeAmount;
        }*/

        if(isDevFundFeeEnabled && devFundFeeInPercent > 0){
            _devAndMarketingAmount = computePercentageToAmount(devFundFeeInPercent, amount);
            _devMarketingLiquidityAmount += _devAndMarketingAmount;
        }

        if(isMarketingFeeFundEnabled && marketingFundFeeInPercent > 0){
            uint256 marketingAmt = computePercentageToAmount(marketingFundFeeInPercent, amount);
            _devAndMarketingAmount += marketingAmt;
            _devMarketingLiquidityAmount += marketingAmt;
        }

        if(_devMarketingLiquidityAmount > 0){
            _balances[sender] = _balances[sender].sub(_devMarketingLiquidityAmount);
            _balances[address(this)] = _balances[address(this)].add(_devMarketingLiquidityAmount);
        }

        /*if(_liquidityFeeAmount > 0) {

            totalAmountToLiquidify = totalAmountToLiquidify + _liquidityFeeAmount;

            if(sender != uniswapV2Pair && totalAmountToLiquidify > 0) {

                //take snapshot
                uint256 amounToLiquidify = totalAmountToLiquidify;

                //lets swap and provide liquidity
                swapAndLiquify(amounToLiquidify);

                //lets
                totalAmountToLiquidify = totalAmountToLiquidify.sub(amounToLiquidify);
            } //end if

        } //end if
        */

        //if dev and marketing is there
        if(_devAndMarketingAmount > 0){

            totalAmountForDevAndMarketing = totalAmountForDevAndMarketing.add(_devAndMarketingAmount);

            if(sender != uniswapV2Pair && totalAmountForDevAndMarketing > 0) {

                isSwapAndLiquifyLocked = true;

                uint256 _currentDevAndMarketingAmountSnapShot = totalAmountForDevAndMarketing;

                uint256 swappedBNBAmount = swapTokenForBNB(_currentDevAndMarketingAmountSnapShot);

                if(swappedBNBAmount > 0) {
                    devAndMarketingFundAddress.call{value: swappedBNBAmount}("");
                }

                totalAmountForDevAndMarketing = totalAmountForDevAndMarketing.sub(_currentDevAndMarketingAmountSnapShot);

                isSwapAndLiquifyLocked = false;
            } //end if

        } //end if dev and marketing amt


        return amountWithFee;

    }
    function setV2UniswapRouter(address _uniswapV2Contract) public onlyOwner() {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Contract);
    }


    /**
        * @dev add liquidity
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private
    {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
    address(this),
    tokenAmount,
    0, // Slippage is unavoidable
    0, // Slippage is unavoidable
    owner(),
    getTime()
    );
    } //end add liquidity
    /**
     * @dev swap and add liquidity
     */
    function swapAndLiquify(uint256 _tokenAmount) private lockSwapAndLiquify {

        require(_tokenAmount > 0, "Amount cannot be 0");

        uint256 tokenAmountHalf = _tokenAmount.div(2);

        //lets swap to get some base asset
        uint256 swappedBNBAmount = swapTokenForBNB(tokenAmountHalf);

        addLiquidity(tokenAmountHalf, swappedBNBAmount);

    } //end

    /**
     * add lets add initial liquidity
     */

    event LiquidityAddedToLP(uint256 tokensAdded);

    function addLiquidityPoolTokensToLP(uint256 amount) external onlyOwner {
        require(amount <= _liquidityTokens, "Not enough to liquify");

        // split the contract balance into halves
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // Enough liquidity???
        swapTokenForBNB(half);

        uint256 newBalance = address(this).balance - initialBalance;
        if (newBalance > 0)
        {
            _balances[address(this)] = _balances[address(this)] - amount;
            _liquidityTokens = _liquidityTokens - amount;
            addLiquidity(otherHalf, newBalance);
            emit LiquidityAddedToLP(amount);
        }

    }



    function swapTokenForBNB(uint256 _tokenAmount) private returns (uint256) {


        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        uint256 bnbCurrentBalance = address(this).balance;

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amoun
            path,
            address(this),
            (block.timestamp + 10)
        ) {
           return uint256(address(this).balance.sub(bnbCurrentBalance));
        } catch {
            return 0;
        }
    }

    event ChangeRouter(address router, address pair);

    function changeRouterVersion(address _router) external onlyOwner returns (address _pair)
    {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        
            _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
            if (_pair == address(0))
            {
                // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            }
        
                // Set the router/pair of the contract variables
            uniswapV2Pair = _pair;
            uniswapV2Router = _uniswapV2Router;
            accountsExcludedFromFees[address(uniswapV2Router)] = true;
            emit ChangeRouter(address(uniswapV2Router), address(uniswapV2Pair));
    }

    receive() external payable {
    emit _Receive(msg.sender, msg.value);
    }

    fallback () external payable {}


}