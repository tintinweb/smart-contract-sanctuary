/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

library Address
{
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

interface IERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out,address indexed to);
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

abstract contract Context
{
    function _msgSender() internal view virtual returns (address payable)
    {
        return payable(msg.sender);
    }
}

contract Ownable is Context
{
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()
    {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address)
    {
        return _owner;
    }

    function isOwner(address who) public view returns (bool)
    {
        return _owner == who;
    }

    modifier onlyOwner()
    {
        require(isOwner(_msgSender()), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        require(
            newOwner != _owner,
            "Ownable: new owner is already the owner"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256)
    {
        return block.timestamp;
    }
}

contract VetterToken is Context, Ownable, IERC20
{
    using Address for address;

    address private _rankContract;

    modifier onlyRankContract()
    {
        require(_msgSender() == _rankContract, "caller is not the rank contract");
        _;
    }

    string private constant _name = "V Test Token";
    string private constant _symbol = "VTEST";
    // string private constant _name = "Vetter Token";
    // string private constant _symbol = "VETTER";
    uint8 private constant _decimals = 9;

    address constant private deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable private participatoryAddress = payable(0x3636413005a394800F5E4B9fbF194521F3ac40F2);  // External Participatory Pool Address (to send the BNB to when auto selling)
    address payable private vetterAddress = payable(0x3636413005a394800F5E4B9fbF194521F3ac40F2);         // External Vetter Pool Address (to send the BNB to when auto selling)
    address payable private liquidityAddress = payable(0x3636413005a394800F5E4B9fbF194521F3ac40F2);      // Liquidity Address (to send the initial Tokens to)
    address payable private reflectionAddress = payable(0x3636413005a394800F5E4B9fbF194521F3ac40F2);     // External Vetter Pool Address (to send the BNB to when auto selling)
    //(0x10ED43C718714eb63d5aA57B78B54704E256024E); // ROPSTEN or HARDHAT
    //(0x10ED43C718714eb63d5aA57B78B54704E256024E); // BSC Mainnet
    //(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSC Testnet
    address payable constant private addressV2Router = payable(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    address private presaleAddress = deadAddress; // External presale address

    //uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalTokens =         4 * 10**9 * 10**_decimals;      // 4 Billion Tokens
    uint256 private constant _initialFounder =      2 * 10**8 * 10**_decimals;      // 200 Million Tokens
    uint256 private constant _initialStable =       2 * 10**8 * 10**_decimals;      // 200 Million Tokens
    uint256 private constant _initialPrivateSale =  2290909091 * 10**_decimals;     // 2.3 Billion Tokens
    uint256 private constant _initialPreSale =      654545455 * 10**_decimals;      // 645 Million Tokens
    uint256 private constant _initialLiquidity =    654545455 * 10**_decimals;      // 645 Million Tokens

    mapping(uint256 => uint256) private _tiers;     // The actual tier levels (number of Tokens needed per Tier)
    uint256 private _numberOfTiers = 4;     // Used to control tier levels for DAPP access (0 - number of tier inclusive) [Tier 0 is always 0 tokens]
    uint256 private constant _initialTier1 = 10000;
    uint256 private constant _initialTier2 = 100000;
    uint256 private constant _initialTier3 = 250000;
    uint256 private constant _initialTier4 = 500000;

    mapping(address => uint256) private _tokensOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    struct Founder
    {
        address payable _founder;
        uint256 _percentage;
    }

    // TODO: make arrays public to iterate...?
    mapping (address => bool) private _architects;
    Founder[] private _founderList;
    uint256 private constant _initialFounderLock = 365;
    uint256 private constant _founderRelease = 30;
    //uint256 private constant _initialFounderLock = 365 days;                            // Time to the first token release
    //uint256 private constant _founderRelease = 30 days;                                 // Days to the next token release after the first
    uint256 private constant _founderPercentPerPeriod = 10;                             // The percentage of the founder pool released over time...
    uint256 private _timeTokenLaunched;                                                 // When the contract was created...

    uint256 private _founderTokens = _initialFounder;                                   // Track them until they are sent out...timed release
    uint256 private _stableTokens = _initialStable;                                     // Track them until they are sent out...timed release
    uint256 private _privateSaleTokens = _initialPrivateSale;                           // Track them until they are sent out...air dropped
    uint256 private _presaleAndLiquidityTokens = _initialPreSale + _initialLiquidity;   // Track them until they are sent out...sent to presale provider

    struct Share
    {
        address _wallet;    // Who was in the sale
        uint256 _shares;    // This is based upon 1 share = 0.01 BNB
        bool _private;      // Used to determine airdropped amounts
        bool _active;       // Used to determine if still qualified for stablizer token releases
        uint256 _minTokens; // Lowest Level to remain active for stablizer token releases
    }

    uint256 private constant _stableRelease = 90;              // Days between each token release
    //uint256 private constant _stableRelease = 90 days;              // Days between each token release
    uint256 private _stablePercent = 10;                            // The percentage of the stable pool to release next
    uint256 private _stablePeriod = 0;                              // Which period we are currently in
    Share[] private _stableList;                                    // List of addresses for stable coin releases
    mapping (address => uint256) private _stableIndex;              // Index of address in list

    mapping (address => uint256) private _admins;                   // 0 = No, 1 = reviewer only, 2 = full admin

    bool private _taxesEnabled = false;

    uint256 private _marketingBuyTax = 50;              // (stored at 10x so 5% is 50)
    uint256 private _marketingSellTax = 50;             // (stored at 10x so 5% is 50)
    uint256 private constant _marketTaxCap = 50;        // 5% max
    uint256 private _marketingTokens;                   // store of vetter tokens

    uint256 private _participitoryBuyTax = 20;          // (stored at 10x so 2% is 20)
    uint256 private _participitorySellTax = 50;         // (stored at 10x so 5% is 50)
    uint256 private constant _participitoryCap = 50;    // 5% max
    uint256 private _participitoryTokens;               // store of vetter tokens not sent out as BNB
    event ParticipitoryRewarded(address indexed to, uint256 value);

    uint256 private _vetterBuyTax = 20;                 // (stored at 10x so 2% is 20)
    uint256 private _vetterSellTax = 50;                // (stored at 10x so 5% is 50)
    uint256 private constant _vetterCap = 50;           // 5% max
    uint256 private _vetterTokens;                      // store of vetter tokens not sent out as BNB
    uint256 private _vetterReserve;                     // Vetter to keep on hand...set to 0 initially
    mapping (address => uint256) private _vetters;      // Vetter Type: 0 = not vetter, 1 = full vetter, 2 = trial vetter
    address[] _vetterList;                              // Vetter List
    event VetterRewarded(address indexed to, uint256 value);

    uint256 private _liquidityBuyTax = 20;              // (stored at 10x so 2% is 20)
    uint256 private _liquiditySellTax = 20;             // (stored at 10x so 2% is 20)
    uint256 private constant _liquidityCap = 20;        // 2% max
    uint256 private _liquidityTokens;                   // store of vetter tokens not sent out as BNB or added to liquidity
    //bool private inSwapForLiquidity;

    // TODO: Determine whether to use a date based real distribution...or a single time must claim or lose distribution
    uint256 private _reflectionBuyTax = 10;             // (stored at 10x so 1% is 10)
    uint256 private _reflectionSellTax = 10;            // (stored at 10x so 1% is 10)
    uint256 private constant _reflectionCap = 20;       // 2% max
    uint256 private constant _reflectionMin = 10;       // 1% min
    uint256 private _reflectionTokens;                  // store of vetter tokens not sent out as BNB
    // address[] _reflectionsTo;                           // Reflection addresses added to so we can run during distributions [who can get reflections = green+ ever]
    // mapping (address => uint256) private _reflIndex;    // Index of address in reflection list

    struct Royalties
    {
        uint256 whenAvailable;
        uint256 amountToClaim;
    }
    uint256 _numRoyaltyHolders;
    Royalties[] _distributions;
    mapping (address => uint256) private _royaltyIndex; // Addresses in royalty list to time last claimed
    event RoyaltyClaimed(address indexed to, uint256 received);

    event TipSent(address indexed from, address indexed to, uint256 value);

    // modifier lockTheSwap
    // {
    //     inSwapForLiquidity = true;
    //     _;
    //     inSwapForLiquidity = false;
    // }

    constructor()
    {
        // Distribute the tokens...
        _tokensOwned[address(this)] = _totalTokens - _presaleAndLiquidityTokens;
        _tokensOwned[owner()] = _presaleAndLiquidityTokens;
        _presaleAndLiquidityTokens = 0;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(addressV2Router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        addOrAdjustVetter(owner(), true);
        _isExcludedFromFee[addressV2Router] = true;
        _isExcludedFromFee[participatoryAddress] = true;
        _isExcludedFromFee[vetterAddress] = true;
        _isExcludedFromFee[liquidityAddress] = true;
        _isExcludedFromFee[reflectionAddress] = true;

        _tiers[1] = _initialTier1;
        _tiers[2] = _initialTier2;
        _tiers[3] = _initialTier3;
        _tiers[4] = _initialTier4;

        _timeTokenLaunched = block.timestamp;

        emit Transfer(address(0), address(this), _totalTokens - _presaleAndLiquidityTokens);
        emit Transfer(address(0), owner(), _presaleAndLiquidityTokens);
    }

    /* IERC20 */
    function totalSupply() external pure override returns (uint256)
    {
        return _totalTokens;
    }

    // Only show the number of tokens they have POST sales tax (unless they are excluded) so they only get paid for the discounted number
    // of tokens when they sell on Pancake Swap, etc.
    //
    // Any time a taxed account transfers (sells tokens) we will actually take the untaxed number (which is higher) from their account
    // See the _preTaxAmount function for this reversal...
    // When taxes are turned off...or they are not a taxed account...we just show the actual number of tokens they own as their balance.
    function balanceOf(address account) public view override returns (uint256)
    {
        if(_isExcludedFromFee[account] || !_taxesEnabled || (account == presaleAddress)) return _tokensOwned[account];
        else return _tokensOwned[account] - ((_tokensOwned[account] * getTotalSellTax()) / 1000);
    }

    // We need to actually remove more tokens than they get paid for in order to tax the sale properly...
    // Reverse a Percentage Formula: ((PostTaxAmt * 100) / (100 - TaxRate))
    // But...our tax rate is 10x to allow for as low as 0.1 % so we use 1000 rather than 100 here
    // If we were to allow for 0.01 % then this has to be adjusted as well...
    function _preTaxAmount(address who, uint256 amount) private view returns(uint256)
    {
        if(_isExcludedFromFee[who] || !_taxesEnabled || (who == presaleAddress)) return amount;
        else return amount * (1000 / (uint256(1000) - getTotalSellTax()));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256)
    {
        return _allowances[owner][spender];
    }

    // Account for the correct amount to be approved since they only see the post tax amount in their wallet
    function approve(address spender, uint256 amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        //_approve(_msgSender(), spender, _preTaxAmount(spender, amount));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool)
    {
        //require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");
        require(_preTaxAmount(sender, amount) <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");

        // Send the amount...
        _transfer(sender, recipient, amount);

        // Remove the amount they are allowed to send in the future...
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - _preTaxAmount(sender, amount));
        //_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    /* IUniswapV2Factory */

    /* IUniswapV2Pair */
    function name() external pure returns (string memory)
    {
        return _name;
    }

    function symbol() external pure returns (string memory)
    {
        return _symbol;
    }

    function decimals() external pure returns (uint8)
    {
        return _decimals;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool)
    {
        require(subtractedValue <= _allowances[_msgSender()][spender], "ERC20: transfer amount exceeds allowance");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private
    {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            getTime()
        );
    }

    function _approve(address owner, address spender, uint256 amount) private
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    struct TaxValues
    {
        uint256 marketing;
        uint256 participatory;
        uint256 vetter;
        uint256 liquidity;
        uint256 reflection;
    }

    function _transfer(address from, address to, uint256 amount) private
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 actualSellAmt = _preTaxAmount(from, amount);
        require(actualSellAmt <= _tokensOwned[from], "Transfer amount would exceed balance");

        _tokensOwned[from] = _tokensOwned[from] - actualSellAmt;

        uint256 remaining = actualSellAmt;
        // TaxValues memory taxes;

        if(_taxesEnabled && !_isExcludedFromFee[from] && (from != presaleAddress))
        {
            // (taxes.marketing, taxes.participatory, taxes.vetter, taxes.liquidity, taxes.reflection) = getSellTaxes(remaining);
            // remaining = remaining - taxes.marketing - taxes.participatory - taxes.vetter - taxes.liquidity - taxes.reflection;
            remaining = _handleSellTax(remaining);
        }

        if(_taxesEnabled && !_isExcludedFromFee[to])
        {
            // TaxValues memory buyTax;
            // (buyTax.marketing, buyTax.participatory, buyTax.vetter, buyTax.liquidity, buyTax.reflection) = getBuyTaxes(remaining);
            // remaining = remaining - buyTax.marketing - buyTax.participatory - buyTax.vetter - buyTax.liquidity - buyTax.reflection;
            // taxes.marketing = taxes.marketing + buyTax.marketing;
            // taxes.participatory = taxes.participatory + buyTax.participatory;
            // taxes.vetter = taxes.vetter + buyTax.vetter;
            // taxes.liquidity = taxes.liquidity + buyTax.liquidity;
            // taxes.reflection = taxes.reflection + buyTax.reflection;
            remaining = _handleBuyTax(remaining);
        }

        _tokensOwned[to] = _tokensOwned[to] + remaining;
        emit Transfer(from, to, actualSellAmt);

        // Add the taxed tokens to the contract...
        if(actualSellAmt > remaining) _tokensOwned[address(this)] = _tokensOwned[address(this)] + (actualSellAmt - remaining);

        // Process the taxes...
        // if(taxes.marketing > 0) swapMarketingTokens(taxes.marketing);
        // if(taxes.participatory > 0) swapParticipatoryTokens(taxes.participatory);
        // if(taxes.vetter > 0) swapVetterTokens(taxes.vetter);
        // if(taxes.liquidity > 0)
        // {
        //     if (!inSwapForLiquidity && from != uniswapV2Pair) swapLiquidityTokens(taxes.liquidity);
        //     else _liquidityTokens = _liquidityTokens + taxes.liquidity;
        // }
        // if(taxes.reflection > 0) swapReflectionTokens(taxes.reflection);

        // Save time if these are all gone now...
        if(_stableTokens > 0)
        {
            // Check if still eligible for stable rewards...
            if(_stableIndex[from] > 0)
            {
                // Handle the normal case in the list...won't catch the case where the first entry is actually supposed to be index 0
                if(_tokensOwned[from] < _stableList[_stableIndex[from]]._minTokens) _stableList[_stableIndex[from]]._active = false;
            }
            else if(_stableList.length > 0 && _stableList[0]._wallet == from)
            {
                // Special case for first element in the list...
                if(_tokensOwned[from] < _stableList[0]._minTokens) _stableList[0]._active = false;
            }
        }
    }

    function swapMarketingTokens(uint256 amount) external onlyArchitect
    {
        require(amount <= _marketingTokens, "Not enough tokens to convert");

        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(amount);
        uint256 transferredBalance = address(this).balance - initialBalance;
        if (transferredBalance == 0) return;

        _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
        _marketingTokens = _marketingTokens - amount;

        // Send to Marketing addresses controlled by the founder list
        uint256 remaining = transferredBalance;
        for(uint256 index = 0; index < _founderList.length; index++)
        {
            uint256 sendAmt = (transferredBalance * _founderList[index]._percentage) / 100;
            transferBNBToAddress(_founderList[index]._founder, sendAmt);
            remaining = remaining - sendAmt;
        }
        // Should not be any left if the founder list is set up correctly...
        if(remaining > 0) transferBNBToAddress(payable(owner()), remaining);
    }

    // function swapParticipatoryPoolTokens(uint256 amount) external onlyArchitect
    // {
    //     require(amount <= _participitoryTokens, "Not enough to swap");
    //     require(_participitoryTokens > _participitoryReserve, "Can't reduce pool below reserve amount");

    //     uint256 swapAmt = amount;
    //     if(_participitoryTokens - swapAmt < _participitoryReserve)
    //     {
    //         swapAmt = _participitoryTokens - _participitoryReserve;
    //     }

    //     uint256 initialBalance = address(this).balance;
    //     swapTokensForBNB(swapAmt);
    //     uint256 transferredBalance = address(this).balance - initialBalance;
    //     if (transferredBalance == 0) return;

    //     // Send to participitory address
    //     removeContractCount(swapAmt, swapAmt,0,0,0,0,0,0,0);
    //     transferBNBToAddress(participatoryAddress, transferredBalance);
    // }

    // function swapParticipatoryTokens(uint256 amount) private
    // {
    //     uint256 swapAmt = (amount * _collectParticipitory) / 100;
    //     uint256 remaining = amount - swapAmt;
    //     if(remaining > 0) _participitoryTokens = _participitoryTokens + remaining;

    //     if(_participitoryTokens < _participitoryReserve)
    //     {
    //         uint256 diff = _participitoryReserve - _participitoryTokens;
    //         if(diff > swapAmt)
    //         {
    //             _participitoryTokens = _participitoryTokens + swapAmt;
    //             swapAmt = 0;
    //         }
    //         else
    //         {
    //             _participitoryTokens = _participitoryTokens + diff;
    //             swapAmt = swapAmt - diff;
    //         }
    //     }
    //     if(swapAmt > 0)
    //     {
    //         uint256 initialBalance = address(this).balance;
    //         swapTokensForBNB(swapAmt);
    //         uint256 transferredBalance = address(this).balance - initialBalance;
    //         if (transferredBalance == 0)
    //         {
    //             _participitoryTokens = _participitoryTokens + swapAmt;
    //         }
    //         else
    //         {
    //             transferBNBToAddress(participatoryAddress, transferredBalance);
    //             removeContractCount(swapAmt, 0,0,0,0,0,0,0,0);
    //         }
    //     }
    // }

    function swapVetterPoolTokens(uint256 amount) external onlyArchitect
    {
        require(amount <= _vetterTokens, "Not enough to swap");
        require(_vetterTokens > _vetterReserve, "Can't reduce pool below reserve amount");

        uint256 swapAmt = amount;
        if(_vetterTokens - swapAmt < _vetterReserve)
        {
            swapAmt = _vetterTokens - _vetterReserve;
        }

        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(swapAmt);
        uint256 transferredBalance = address(this).balance - initialBalance;
        if (transferredBalance == 0) return;

        // Send to vetter address
        _tokensOwned[address(this)] = _tokensOwned[address(this)] - swapAmt;
        _vetterTokens = _vetterTokens - swapAmt;
        transferBNBToAddress(vetterAddress, transferredBalance);
    }

    // function swapVetterTokens(uint256 amount) private
    // {
    //     uint256 swapAmt = (amount * _collectVetterPool) / 100;
    //     uint256 remaining = amount - swapAmt;
    //     if(remaining > 0) _vetterTokens = _vetterTokens + remaining;

    //     if(_vetterTokens < _vetterReserve)
    //     {
    //         uint256 diff = _vetterReserve - _vetterTokens;
    //         if(diff > swapAmt)
    //         {
    //             _vetterTokens = _vetterTokens + swapAmt;
    //             swapAmt = 0;
    //         }
    //         else
    //         {
    //             _vetterTokens = _vetterTokens + diff;
    //             swapAmt = swapAmt - diff;
    //         }
    //     }
    //     if(swapAmt > 0)
    //     {
    //         uint256 initialBalance = address(this).balance;
    //         swapTokensForBNB(swapAmt);
    //         uint256 transferredBalance = address(this).balance - initialBalance;
    //         if (transferredBalance == 0)
    //         {
    //             _vetterTokens = _vetterTokens + swapAmt;
    //         }
    //         else
    //         {
    //             transferBNBToAddress(vetterAddress, transferredBalance);
    //             removeContractCount(swapAmt,0,0,0,0,0,0,0,0);
    //         }
    //     }
    // }

    function pullLiquidityPoolTokens(uint256 amount) external onlyArchitect
    {
        require(amount <= _liquidityTokens, "Not enough to pull");

        // Send to liquidity address
        _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
        _liquidityTokens = _liquidityTokens - amount;
        _tokensOwned[liquidityAddress] = _tokensOwned[liquidityAddress] + amount;
    }

    function swapLiquidityPoolTokens(uint256 amount) external onlyArchitect
    {
        require(amount <= _liquidityTokens, "Not enough to swap");

        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(amount);
        uint256 transferredBalance = address(this).balance - initialBalance;
        if (transferredBalance == 0) return;

        // Send to liquidity address
        _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
        _liquidityTokens = _liquidityTokens - amount;
        transferBNBToAddress(liquidityAddress, transferredBalance);
    }

    function addLiquidityPoolTokensToLP(uint256 amount) external onlyArchitect
    {
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
        if(swapTokensForBNB(half))
        {
            uint256 newBalance = address(this).balance - initialBalance;
            if(newBalance > 0)
            {
                _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
                _liquidityTokens = _liquidityTokens - amount;
                addLiquidity(otherHalf, newBalance);
            }
        }
    }

    // function swapLiquidityTokens(uint256 amount) private lockTheSwap
    // {
    //     uint256 swapAmt = (amount * _collectLiquidity) / 100;
    //     uint256 remaining = amount - swapAmt;
    //     if(remaining > 0) _liquidityTokens = _liquidityTokens + remaining;

    //     // split the contract balance into halves
    //     uint256 half = swapAmt / 2;
    //     uint256 otherHalf = swapAmt - half;

    //     // capture the contract's current BNB balance.
    //     // this is so that we can capture exactly the amount of BNB that the
    //     // swap creates, and not make the liquidity event include any BNB that
    //     // has been manually sent to the contract
    //     uint256 initialBalance = address(this).balance;

    //     // Enough liquidity???
    //     if(swapTokensForBNB(half))
    //     {
    //         uint256 newBalance = address(this).balance - initialBalance;
    //         if(newBalance > 0)
    //         {
    //             removeContractCount(swapAmt,0,0,0,0,0,0,0,0);
    //             addLiquidity(otherHalf, newBalance);
    //         }
    //     }
    // }

    // function swapReflectionPoolTokens(uint256 amount) external onlyArchitect
    // {
    //     require(amount <= _reflectionTokens, "Not enough to swap");
    //     require(_reflectionTokens > _reflectionReserve, "Can't reduce pool below reserve amount");

    //     uint256 swapAmt = amount;
    //     if(_reflectionTokens - swapAmt < _reflectionReserve)
    //     {
    //         swapAmt = _reflectionTokens - _reflectionReserve;
    //     }

    //     uint256 initialBalance = address(this).balance;
    //     swapTokensForBNB(swapAmt);
    //     uint256 transferredBalance = address(this).balance - initialBalance;
    //     if (transferredBalance == 0) return;

    //     // Send to vetter address
    //     removeContractCount(swapAmt,0,0,0,swapAmt,0,0,0,0);
    //     transferBNBToAddress(reflectionAddress, transferredBalance);
    // }

    // function swapReflectionTokens(uint256 amount) private
    // {
    //     uint256 swapAmt = (amount * _collectReflections) / 100;
    //     uint256 remaining = amount - swapAmt;
    //     if(remaining > 0) _reflectionTokens = _reflectionTokens + remaining;

    //     if(_reflectionTokens < _reflectionReserve)
    //     {
    //         uint256 diff = _reflectionReserve - _reflectionTokens;
    //         if(diff > swapAmt)
    //         {
    //             _reflectionTokens = _reflectionTokens + swapAmt;
    //             swapAmt = 0;
    //         }
    //         else
    //         {
    //             _reflectionTokens = _reflectionTokens + diff;
    //             swapAmt = swapAmt - diff;
    //         }
    //     }
    //     if(swapAmt > 0)
    //     {
    //         uint256 initialBalance = address(this).balance;
    //         swapTokensForBNB(swapAmt);
    //         uint256 transferredBalance = address(this).balance - initialBalance;
    //         if (transferredBalance == 0)
    //         {
    //             _reflectionTokens = _reflectionTokens + swapAmt;
    //         }
    //         else
    //         {
    //             transferBNBToAddress(reflectionAddress, transferredBalance);
    //             removeContractCount(swapAmt,0,0,0,0,0,0,0,0);
    //         }
    //     }
    // }

    // Just converts the tokens held by the contract itself to BNB...from whatever pool holds them...and gives them to the spcified wallet address
    function swapTokensForBNB(uint256 tokenAmount) private returns (bool status)
    {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(allowance(address(this), address(uniswapV2Router)) < tokenAmount)
        {
          _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }

        // Make the swap
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,              // Accept any amount of ETH
            path,
            address(this),
            getTime()
        )
        {
          return true;
        }
        catch
        {
          return false;
        }
    }

    // function getBuyTaxes(uint256 starting) public view returns(uint256,uint256,uint256,uint256,uint256)
    // {
    //     return (
    //         (starting * _marketingBuyTax) / 1000,
    //         (starting * _participitoryBuyTax) / 1000,
    //         (starting * _vetterBuyTax) / 1000,
    //         (starting * _liquidityBuyTax) / 1000,
    //         (starting * _reflectionBuyTax) / 1000
    //     );
    // }

    function _handleBuyTax(uint256 starting) private returns(uint256)
    {
        uint256 remaining = starting;

        uint256 tax = (starting * _marketingBuyTax) / 1000;
        _marketingTokens = _marketingTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _participitoryBuyTax) / 1000;
        _participitoryTokens = _participitoryTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _vetterBuyTax) / 1000;
        _vetterTokens = _vetterTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _liquidityBuyTax) / 1000;
        _liquidityTokens = _liquidityTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _reflectionBuyTax) / 1000;
        _reflectionTokens = _reflectionTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        return remaining;
    }

    // function getSellTaxes(uint256 starting) public view returns(uint256,uint256,uint256,uint256,uint256)
    // {
    //     return (
    //         (starting * _marketingSellTax) / 1000,
    //         (starting * _participitorySellTax) / 1000,
    //         (starting * _vetterSellTax) / 1000,
    //         (starting * _liquiditySellTax) / 1000,
    //         (starting * _reflectionSellTax) / 1000
    //     );
    // }

    function _handleSellTax(uint256 starting) private returns(uint256)
    {
        uint256 remaining = starting;

        uint256 tax = (starting * _marketingSellTax) / 1000;
        _marketingTokens = _marketingTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _participitorySellTax) / 1000;
        _participitoryTokens = _participitoryTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _vetterSellTax) / 1000;
        _vetterTokens = _vetterTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _liquiditySellTax) / 1000;
        _liquidityTokens = _liquidityTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        tax = (starting * _reflectionSellTax) / 1000;
        _reflectionTokens = _reflectionTokens + tax;
        //_tokensOwned[address(this)] = _tokensOwned[address(this)] + tax;
        remaining = remaining - tax;

        return remaining;
    }

    function takeTaxes(bool _enabled) external onlyArchitect
    {
        _taxesEnabled = _enabled;
    }

    function setAllTaxes(uint256 marketingBuy, uint256 marketingSell, uint256 participatoryBuy, uint256 participatorySell, uint256 vetterBuy, uint256 vetterSell, uint256 liquidityBuy, uint256 liquiditySell, uint256 reflectionBuy, uint256 reflectionSell) public onlyArchitect
    {
        require(marketingBuy <= _marketTaxCap && marketingSell <= _marketTaxCap, "Marketing Tax Exceeds Cap");
        require(participatoryBuy <= _participitoryCap && participatorySell <= _participitoryCap, "Participatory Tax Exceeds Cap");
        require(vetterBuy <= _vetterCap && vetterSell <= _vetterCap, "Vetter Tax Exceeds Cap");
        require(liquidityBuy <= _liquidityCap && liquiditySell <= _liquidityCap, "Liquidity Tax Exceeds Cap");
        require(reflectionBuy <= _reflectionCap && reflectionSell <= _reflectionCap, "Reflection Tax Exceeds Cap");
        require(reflectionBuy >= _reflectionMin && reflectionSell >= _reflectionMin, "Reflection Tax Below Minimum");

        _marketingBuyTax = marketingBuy;
        _marketingSellTax = marketingSell;

        _participitoryBuyTax = participatoryBuy;
        _participitorySellTax = participatorySell;

        _vetterBuyTax = vetterBuy;
        _vetterSellTax = vetterSell;

        _liquidityBuyTax = liquidityBuy;
        _liquiditySellTax = liquiditySell;

        _reflectionBuyTax = reflectionBuy;
        _reflectionSellTax = reflectionSell;
    }

    // Bot measure to deincentivize selling early...
    // Ignores the normal caps we have in place...
    function setInitialLaunchTaxes() public onlyArchitect
    {
        _taxesEnabled = true;
        _marketingBuyTax = 50;
        _marketingSellTax = 50;
        _participitoryBuyTax = 20;
        _participitorySellTax = 50;
        _vetterBuyTax = 20;
        _vetterSellTax = 170;
        _liquidityBuyTax = 20;
        _liquiditySellTax = 20;
        _reflectionBuyTax = 10;
        _reflectionSellTax = 10;
    }

    function getTotalBuyTax() public view returns (uint256)
    {
        return(_marketingBuyTax + _participitoryBuyTax + _vetterBuyTax + _liquidityBuyTax + _reflectionBuyTax);
    }

    function getTotalSellTax() public view returns (uint256)
    {
        return(_marketingSellTax + _participitorySellTax + _vetterSellTax + _liquiditySellTax + _reflectionSellTax);
    }

    function setVetterReserve(uint256 vetter) public onlyArchitect
    {
        _vetterReserve = vetter;
    }

    function rewardParticipatory(address to, uint256 amount) external onlyRankContract
    {
        require(amount <= _participitoryTokens, "Not enough to reward");

        // Send participitory to them
        _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
        _participitoryTokens = _participitoryTokens - amount;
        _tokensOwned[to] = _tokensOwned[to] + amount;
        emit Transfer(address(this), to, amount);
        emit ParticipitoryRewarded(to, amount);
    }

    function rewardVetter(address to, uint256 amount) external onlyRankContract
    {
        require(amount <= _vetterTokens, "Not enough to reward");

        // Send vetter to them
        _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
        _vetterTokens = _vetterTokens - amount;
        _tokensOwned[to] = _tokensOwned[to] + amount;
        emit Transfer(address(this), to, amount);
        emit VetterRewarded(to, amount);
    }

    // Return the current tracking of the size of initial tokens created in pools as well as taxed pools...
    // Values:
    //  0) Total the contract still holds
    //  1) Contract Tokens allocated to Founder Pool
    //  2) Contract Tokens allocated to Stable Pool
    //  3) Contract Tokens allocated to Private Airdrop Pool
    //  4) Contract Tokens allocated to Presale/Liquidity Pool
    //  5) Marketing Tokens Held by the contract
    //  6) Participatory Tokens Held by the contract
    //  7) Vetter Tokens Held by the contract
    //  8) Liquidity Tokens Held by the contract
    //  9) Reflection Tokens Held by the contract
    function getPoolSize() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    {
        return (balanceOf(address(this)), _founderTokens, _stableTokens, _privateSaleTokens, _presaleAndLiquidityTokens, _marketingTokens, _participitoryTokens, _vetterTokens, _liquidityTokens, _reflectionTokens);
    }

    // Account for over and under amounts...
    // function distributePresaleTokens(address where, uint256 amount, bool allowOver) external onlyArchitect
    // {
    //     require(_presaleAndLiquidityTokens > 0, "Already distributed the Presale and Liquidity Tokens");

    //     if(amount > _presaleAndLiquidityTokens && !allowOver) revert("Not enough tokens to send");

    //     if(amount > _presaleAndLiquidityTokens)
    //     {
    //         // If this is the case...pull them from the private pool...
    //         uint256 diff = _presaleAndLiquidityTokens - amount;
    //         if(diff > _privateSaleTokens) revert("Not enough tokens to send");

    //         _privateSaleTokens = _privateSaleTokens - diff;
    //         _presaleAndLiquidityTokens = _presaleAndLiquidityTokens + diff;
    //     }

    //     if(amount < _presaleAndLiquidityTokens)
    //     {
    //         // If this is the case...add them to the private pool...
    //         uint256 diff = _presaleAndLiquidityTokens - amount;
    //         _presaleAndLiquidityTokens = _presaleAndLiquidityTokens - diff;
    //         _privateSaleTokens = _privateSaleTokens + diff;
    //     }

    //     _tokensOwned[where] = _tokensOwned[where] + _presaleAndLiquidityTokens;
    //     removeContractCount(_presaleAndLiquidityTokens,0,0,0,0,0,_presaleAndLiquidityTokens,0,0);
    //     presaleAddress = where;
    //     _isExcludedFromFee[where] = true;
    //     emit Transfer(address(this), where, amount);
    // }

    function setPresaleAddress(address who) external onlyArchitect
    {
        presaleAddress = who;
        _isExcludedFromFee[who] = true;
    }

    function isExcludedFromFee(address account) external view returns (bool)
    {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyArchitect
    {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyArchitect
    {
        _isExcludedFromFee[account] = false;
    }

    function getSellBnBAmount(uint256 tokenAmount) public view returns (uint256)
    {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory amounts = uniswapV2Router.getAmountsOut(tokenAmount, path);

        return amounts[1];
    }

    function setParticipatoryAddress(address _participatoryAddress) external onlyArchitect
    {
        participatoryAddress = payable(_participatoryAddress);
        _isExcludedFromFee[participatoryAddress] = true;
    }

    function setVetterAddress(address _vetterAddress) external onlyArchitect
    {
        vetterAddress = payable(_vetterAddress);
        _isExcludedFromFee[vetterAddress] = true;
    }

    function setLiquidityAddress(address _liquidityAddress) external onlyArchitect
    {
        liquidityAddress = payable(_liquidityAddress);
        _isExcludedFromFee[liquidityAddress] = true;
    }

    function setReflectionAddress(address _reflectionAddress) external onlyArchitect
    {
        reflectionAddress = payable(_reflectionAddress);
        _isExcludedFromFee[reflectionAddress] = true;
    }

    // Used to get BNB from the contract...
    function transferBNBToAddress(address payable recipient, uint256 amount) private
    {
        recipient.transfer(amount);
    }

    function getPairAddress() external view onlyOwner returns (address)
    {
        return uniswapV2Pair;
    }

    // Used when Pancake Swap is upgraded to a new version...
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
        _isExcludedFromFee[address(uniswapV2Router)] = true;
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    // Used to get random tokens sent to this address out to a wallet...
    function transferForeignToken(address _token, address _to) external onlyArchitect returns (bool _sent)
    {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function _setRankContract(address _contractAddress) external onlyOwner
    {
        _rankContract = _contractAddress;
    }

    // Is wallet in list of architects
    function isArchitect(address who) public view returns(bool)
    {
        return _architects[who];
    }

    // Add a new wallet address to list
    function addArchitect(address who, uint256 percentage) external onlyArchitect
    {
        require(percentage <= 100,"Bad Percentage Provided");
        require(!_architects[who],"Architect Already Added");

        _architects[who] = true;
        _founderList.push(Founder(payable(who), percentage));
        _isExcludedFromFee[who] = true;
        addOrAdjustVetter(who, true);

        // _reflIndex[who] = _reflectionsTo.length;
        // _reflectionsTo.push(who);
        if(_royaltyIndex[who] > 0) return;
        _royaltyIndex[who] = getTime();
        _numRoyaltyHolders = _numRoyaltyHolders + 1;
    }

    // Remove a wallet address from list
    function removeArchitect(address who) external onlyArchitect
    {
        require(_architects[who],"Not an Architect");

        _architects[who] = false;
        removeVetter(who);

        for(uint256 index = 0; index < _founderList.length; index++)
        {
            // Find the entry in the list...
            if(_founderList[index]._founder == who)
            {
                // Move the last entry to this position...
                _founderList[index] = _founderList[_founderList.length-1];
                // Remove the last element to shrink the array down...
                _founderList.pop();
                break;
            }
        }
    }

    // Add a new wallet address to list
    function adjustArchitect(address who, uint256 percentage) external onlyArchitect
    {
        require(percentage <= 100,"Bad Percentage Provided");
        require(_architects[who],"Not an Architect");

        for(uint256 index = 0; index < _founderList.length; index++)
        {
            // Find the entry in the list...
            if(_founderList[index]._founder == who)
            {
                _founderList[index]._percentage = percentage;
                break;
            }
        }
    }

    function distributeFounderTokens() external onlyArchitect
    {
        // First check if we are past the initial lock period...
        if(getTime() < _timeTokenLaunched + _initialFounderLock) return;

        uint256 totalUnlocked = 0;
        uint256 periods = 0;
        while((totalUnlocked < 100) && (getTime() > (_timeTokenLaunched + _initialFounderLock + (_founderRelease * periods))))
        {
            totalUnlocked = totalUnlocked + _founderPercentPerPeriod;
            periods++;
        }

        if(periods < 1) return;

        // We may have sent some out already...so determine how many we can give out that are left now...
        // Use FounderCurrent - ShouldBeRemaining where ShouldBeRemaining = InitialAmount - AmountToDistribute
        // where AmountToDistribute = NumberOfPeriods * TokensPerPeriod
        // where TokensPerPeriod = PercentageOfOriginal
        uint256 tokensPerPeriod = (_initialFounder * _founderPercentPerPeriod) / 100;
        uint256 tokensToDistribute = _founderTokens - (_initialFounder - (periods * tokensPerPeriod));

        // Now hand them out...
        for(uint256 index = 0; index < _founderList.length; index++)
        {
            uint256 amount = (tokensToDistribute * _founderList[index]._percentage) / 100;
            _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
            _founderTokens = _founderTokens - amount;
            _tokensOwned[_founderList[index]._founder] = _tokensOwned[_founderList[index]._founder] + amount;
            emit Transfer(address(this), _founderList[index]._founder, amount);
        }
    }

    modifier onlyArchitect()
    {
        require(isArchitect(_msgSender()) || isOwner(_msgSender()), "Caller is not an architect.");
        _;
    }

    // Is wallet in list of admins
    function isAdmin(address who) public view returns(bool)
    {
        return _admins[who] > 0;
    }

    function isFullAdmin(address who) public view returns(bool)
    {
        return _admins[who] > 1;
    }

    // Add a new wallet address to list
    function addAdmin(address who, bool full) external onlyArchitect
    {
        if(full) _admins[who] = 2;
        else _admins[who] = 1;
    }

    // Remove a wallet address from list
    function removeAdmin(address who) external onlyArchitect
    {
        //require(who != owner(), "Cannot remove the contract owner from the list.");
        //require(!isArchitect(who), "Cannot remove the architects from the list.");
        _admins[who] = 0;
    }

    modifier onlyAdmin()
    {
        require(isFullAdmin(_msgSender()) || isArchitect(_msgSender()) || isOwner(_msgSender()), "Caller is not an admin.");
        _;
    }

    // Is wallet in list of vetters
    function isVetter(address who) public view returns(bool)
    {
        return _vetters[who] > 0;
    }

    // Is wallet in list of trial vetters
    function isTrialVetter(address who) public view returns(bool)
    {
        return _vetters[who] == 2;
    }

    // Is wallet in list of full vetters
    function isFullVetter(address who) public view returns(bool)
    {
        return _vetters[who] == 1;
    }

    // Add a new wallet address to list
    function addOrAdjustVetter(address who, bool full) public onlyAdmin
    {
        if(full) _vetters[who] = 1;
        else _vetters[who] = 2;
        _vetterList.push(who);
    }

    // Remove a wallet address from list
    function removeVetter(address who) public onlyAdmin
    {
        if(isArchitect(_msgSender()))
        {
            _vetters[who] = 0;
            return;
        }

        require(!isArchitect(who), "Cannot remove the architects from the list.");
        _vetters[who] = 0;
    }

    function addToStableList(address _wallet, uint256 _shares, bool _private, bool _active) external onlyArchitect
    {
        bool active = _active;
        if(_shares == 0) active = false;
        _stableIndex[_wallet] = _stableList.length;
        _stableList.push(Share(_wallet,_shares,_private,active,0));
    }

    function getStableListEntry(address who) view external returns(uint256, bool, bool, uint256)
    {
        Share memory s = _stableList[_stableIndex[who]];
        return (s._shares, s._private, s._active, s._minTokens);
    }

    function adjustStableListEnrty(address _wallet, uint256 _shares, bool _private, bool _active, uint256 _minTokens) external onlyArchitect
    {
        bool active = _active;
        if(_shares == 0) active = false;
        _stableList[_stableIndex[_wallet]]._shares = _shares;
        _stableList[_stableIndex[_wallet]]._private = _private;
        _stableList[_stableIndex[_wallet]]._active = active;
        _stableList[_stableIndex[_wallet]]._minTokens = _minTokens;
    }

    function getStableShares() public view returns(uint256)
    {
        uint256 shares = 0;
        for(uint256 index = 0; index < _stableList.length; index++)
        {
            if(_stableList[index]._active) shares = shares + _stableList[index]._shares;
        }
        return shares;
    }

    function getPrivateShares() public view returns(uint256)
    {
        uint256 shares = 0;
        for(uint256 index = 0; index < _stableList.length; index++)
        {
            if(_stableList[index]._active && _stableList[index]._private) shares = shares + _stableList[index]._shares;
        }
        return shares;
    }

    function distributeStableTokens() external onlyArchitect
    {
        require(_stableTokens > 0, "Stable Token Distribution Already Happened");

        // First check if we are past the lock period...
        if(getTime() < _timeTokenLaunched + (_stableRelease * (_stablePeriod + 1))) return;

        _stablePeriod = _stablePeriod + 1;

        uint256 tokensThisPeriod = (_initialStable * (_stablePeriod * _stablePercent)) / 100;
        uint256 tokensPerShare = tokensThisPeriod / getStableShares();

        // Now hand them out...
        for(uint256 index = 0; index < _stableList.length; index++)
        {
            if(_stableList[index]._active)
            {
                uint256 amount = tokensPerShare * _stableList[index]._shares;
                _tokensOwned[_stableList[index]._wallet] = _tokensOwned[_stableList[index]._wallet] + amount;
                _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
                _stableTokens = _stableTokens - amount;
                _stableList[index]._minTokens = _stableList[index]._minTokens + amount;
                emit Transfer(address(this), _stableList[index]._wallet, amount);
            }
        }

        // Be sure on the final stage that all of the tokens were distributed...
        if(_stablePeriod > 3 && _stableTokens > 0)
        {
            _participitoryTokens = _participitoryTokens + _stableTokens;
            _stableTokens = 0;
        }
    }

    function airdropPrivateTokens() external onlyArchitect
    {
        require(_privateSaleTokens > 0, "AirDrop Already Happened");

        uint256 tokensPerShare = _privateSaleTokens / getPrivateShares();

        // Now hand them out...
        for(uint256 index = 0; index < _stableList.length; index++)
        {
            if(_stableList[index]._private)
            {
                uint256 amount = tokensPerShare * _stableList[index]._shares;
                _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
                _privateSaleTokens = _privateSaleTokens - amount;
                _tokensOwned[_stableList[index]._wallet] = _tokensOwned[_stableList[index]._wallet] + amount;
                _stableList[index]._minTokens = _stableList[index]._minTokens + amount;
                emit Transfer(address(this), _stableList[index]._wallet, amount);
            }
        }
        // Should not be any left, but make sure it is cleared out...
        if(_privateSaleTokens > 0)
        {
            _participitoryTokens = _participitoryTokens + _privateSaleTokens;
            _privateSaleTokens = 0;
        }
    }

    // Return the number of tiers currently in use
    function _getMaxTier() view public returns(uint256)
    {
        return _numberOfTiers;
    }

    // Get the number of tokens needed at a specified Tier
    function _getTierLevel(uint256 level) view public returns(uint256)
    {
        require(level <= _getMaxTier(),"Not a Valid Tier Level");
        return _tiers[level];
    }

    // Get the token counts for all tier levels
    function _getAllTiers() view public returns(uint256[] memory)
    {
        uint256 maxTier = _getMaxTier();
        uint256[] memory tierLevels = new uint256[](maxTier + 1);
        for(uint256 level = 0; level <= maxTier; level++)
        {
            tierLevels[level] = _tiers[level];
        }
        return tierLevels;
    }

    // Set the number of tokens needed at a specified Tier
    function _setTierLevel(uint256 level, uint256 newAmount) external onlyArchitect
    {
        require(level <= _getMaxTier(),"Not a Valid Tier Level");
        _tiers[level] = newAmount;
    }

    // Add to tier count and set the number of tokens needed
    function _addNewTier(uint256 newAmount) external onlyArchitect
    {
        _numberOfTiers = _numberOfTiers + 1;
        _tiers[_numberOfTiers] = newAmount;
    }

    // Return the Tier of a wallet address by tokens held
    function _getWalletTier(address who) view public returns(uint256)
    {
        uint256 whoBal = balanceOf(who);
        if(whoBal > 0)
        {
            for(uint256 level = _getMaxTier(); level > 0; level--)
            {
                if(whoBal > _getTierLevel(level)) return level;
            }
        }
        return 0;
    }

    // Return Tier and Access Information (wallet tier, owner, architect, admin, reviewer, trial vetter, full vetter, active in stable pool)
    function _getUserInfo(address who) view external returns(uint256, uint256, bool, bool, bool, bool, bool)
    {
        return (_getWalletTier(who), _tokensOwned[who], isArchitect(who), isFullAdmin(who), isAdmin(who), isTrialVetter(who), isFullVetter(who));
    }

    function transferTipAmount(address from, address to, uint256 amount) external onlyRankContract
    {
        _transfer(from, to, amount);
        emit TipSent(from, to, amount);
    }

    function addToReflections(address who) external onlyRankContract
    {
        if(_royaltyIndex[who] > 0) return;

        // _reflIndex[who] = _reflectionsTo.length;
        // _reflectionsTo.push(who);

        _royaltyIndex[who] = getTime();
        _numRoyaltyHolders = _numRoyaltyHolders + 1;
    }

    // function distributeReflectionTokens() external onlyArchitect
    // {
    //     require(_reflectionTokens > 0, "Nothing to Distribute");
    //     uint256 holders = _reflectionsTo.length;
    //     require(holders > 0, "Noone to Distribute to");
    //     uint256 amount = _reflectionTokens / holders;

    //     _tokensOwned[address(this)] = _tokensOwned[address(this)] - _reflectionTokens;
    //     _reflectionTokens = 0;
    //     for(uint256 index = 0; index < holders; index++)
    //     {
    //         _tokensOwned[_reflectionsTo[index]] = _tokensOwned[_reflectionsTo[index]] + amount;
    //         emit Transfer(address(this), _reflectionsTo[index], amount);
    //     }
    // }

    function distributeRoyaltyTokens() external onlyArchitect
    {
        require(_reflectionTokens > 0, "Nothing to Distribute");
        require(_numRoyaltyHolders > 0, "Noone to Distribute to");
        uint256 amount = _reflectionTokens / _numRoyaltyHolders;
        _distributions.push(Royalties(getTime(), amount));
    }

    function chechRoyaltyAmount() public view returns(uint256)
    {
        uint256 lastTime = _royaltyIndex[_msgSender()];
        if(lastTime < 1) return 0;

        uint256 available = 0;
        for(uint256 index = 0; index < _distributions.length; index++)
        {
            if(_distributions[index].whenAvailable > lastTime) available = available + _distributions[index].amountToClaim;
        }
        return available;
    }

    function claimRoyalties() external
    {
        require(_royaltyIndex[_msgSender()] > 0, "Not a Royalty Holder");
        uint256 amount = chechRoyaltyAmount();
        require(amount > 0, "No Royalty To Claim");

        _tokensOwned[address(this)] = _tokensOwned[address(this)] - amount;
        _reflectionTokens = _reflectionTokens - amount;
        _tokensOwned[_msgSender()] = _tokensOwned[_msgSender()] + amount;
        emit Transfer(address(this), _msgSender(), amount);
        emit RoyaltyClaimed(_msgSender(), amount);
    }
}