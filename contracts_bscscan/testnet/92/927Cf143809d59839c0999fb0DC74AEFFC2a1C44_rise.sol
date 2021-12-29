/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// Copyright (c) 2021 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.
/*
The EverRise token is the keystone in the EverRise Ecosytem of dApps
 and the overaching key that unlocks multi-blockchain unification via
 the EverBridge.

On EverRise token txns 6% buyback and business development fees are collected
* 4% for token Buyback from the market, 
     with bought back tokens directly distributed as staking rewards
* 2% for Business Development (Development, Sustainability and Marketing)

 ________                              _______   __
/        |                            /       \ /  |
$$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______
$$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
$$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
$$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
$$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
$$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
$$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/

Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities, and our partners, can help protect your investors
and help your project grow: https://www.everrise.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFromWithPermit(
        address sender,
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IEverStake {
    function createRewards(address acount, uint256 tAmount) external;

    function deliver(uint256 tAmount) external;

    function getTotalAmountStaked() external view returns (uint256);

    function getTotalRewardsDistributed() external view returns (uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// helper methods for discovering LP pair addresses
library PairHelper {
    bytes private constant token0Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token0.selector);
    bytes private constant token1Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token1.selector);

    function token0(address pair) internal view returns (address) {
        return token(pair, token0Selector);
    }

    function token1(address pair) internal view returns (address) {
        return token(pair, token1Selector);
    }

    function token(address pair, bytes memory selector)
        private
        view
        returns (address)
    {
        // Do not check if pair is not a contract to avoid warning in txn log
        if (!isContract(pair)) return address(0); 

        (bool success, bytes memory data) = pair.staticcall(selector);

        if (success && data.length >= 32) {
            return abi.decode(data, (address));
        }
        
        return address(0);
    }

    function isContract(address account) private view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != accountHash && codehash != 0x0);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _buybackOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBuybackOwner() {
        require(
            _buybackOwner == _msgSender(),
            "Ownable: caller is not the buyback owner"
        );
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _buybackOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Allow contract ownership and access to contract onlyOwner functions
    // to be locked using EverOwn with control gated by community vote.
    //
    // EverRise ($RISE) stakers become voting members of the
    // decentralized autonomous organization (DAO) that controls access
    // to the token contract via the EverRise Ecosystem dApp EverOwn
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferBuybackOwnership(address newOwner)
        external
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_buybackOwner, newOwner);
        _buybackOwner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function buybackOwner() public view returns (address) {
        return _buybackOwner;
    }
}

contract rise is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using PairHelper for address;

    struct TransferDetails {
        uint112 balance0;
        uint112 balance1;
        uint32 blockNumber;
        address to;
        address origin;
    }

    address payable public businessDevelopmentAddress =
        payable(0x0c313A5d3f29aeB8a28D66f69b873edC117f2450); // Business Development Address
    address public stakingAddress;
    address public everMigrateAddress;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private lastCoolDownTrade;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isEverRiseEcosystemContract;
    address[] public allEcosystemContracts;

    mapping(address => bool) private _isAuthorizedSwapToken;
    address[] public allAuthorizedSwapTokens;

    uint256 private constant MAX = ~uint256(0);

    string private constant _name = "Rise";
    string private constant _symbol = "RIS";
    // Large data type for maths
    uint256 private constant _decimals = 18;
    // Short data type for decimals function (no per function conversion)
    uint8 private constant _decimalsShort = uint8(_decimals);
    // Golden supply
    uint256 private constant _tTotal = 7_1_618_033_988 * 10**_decimals;

    uint256 private _holders = 0;

    // Fee and max txn are set by setTradingEnabled
    // to allow upgrading balances to arrange their wallets
    // and stake their assets before trading start
    uint256 public liquidityFee = 0;
    uint256 private _previousLiquidityFee = liquidityFee;
    uint256 private _maxTxAmount = _tTotal;
    
    uint256 private constant _tradeStartLiquidityFee = 6;
    uint256 private _tradeStartMaxTxAmount = _tTotal.div(1000); // Max txn 0.1% of supply

    uint256 public businessDevelopmentDivisor = 2;

    uint256 private minimumTokensBeforeSwap = 5 * 10**6 * 10**_decimals;
    uint256 private buyBackUpperLimit = 10 * 10**18;
    uint256 private buyBackTriggerTokenLimit = 1 * 10**6 * 10**_decimals;
    uint256 private buyBackMinAvailability = 1 * 10**18; //1 BNB

    uint256 private buyVolume = 0;
    uint256 private sellVolume = 0;
    uint256 public totalBuyVolume = 0;
    uint256 public totalSellVolume = 0;
    uint256 public totalVolume = 0;
    uint256 private nextBuybackAmount = 0;
    uint256 private buyBackTriggerVolume = 100 * 10**6 * 10**_decimals;

    uint256 private tradingStart = MAX;
    uint256 private tradingStartCooldown = MAX;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.
    uint256 private constant _FALSE = 1;
    uint256 private constant _TRUE = 2;

    uint256 private _checkingTokens;
    uint256 private _inSwapAndLiquify;

    // Infrequently set booleans
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = false;
    bool public liquidityLocked = false;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    IEverStake stakeToken;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    TransferDetails lastTransfer;

    event BuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event SwapTokensForTokens(uint256 amountIn, address[] path);

    event ExcludeFromFeeUpdated(address account);
    event IncludeInFeeUpdated(address account);

    event LiquidityFeeUpdated(uint256 prevValue, uint256 newValue);
    event MaxTxAmountUpdated(uint256 prevValue, uint256 newValue);
    event BusinessDevelopmentDivisorUpdated(
        uint256 prevValue,
        uint256 newValue
    );
    event MinTokensBeforeSwapUpdated(uint256 prevValue, uint256 newValue);
    event BuybackMinAvailabilityUpdated(uint256 prevValue, uint256 newValue);

    event TradingEnabled();
    event BuyBackAndRewardStakers(uint256 amount);
    event BuybackUpperLimitUpdated(uint256 prevValue, uint256 newValue);
    event BuyBackTriggerTokenLimitUpdated(uint256 prevValue, uint256 newValue);

    event RouterAddressUpdated(address prevAddress, address newAddress);
    event BusinessDevelopmentAddressUpdated(
        address prevAddress,
        address newAddress
    );
    event StakingAddressUpdated(address prevAddress, address newAddress);
    event EverMigrateAddressUpdated(address prevAddress, address newAddress);

    event EverRiseEcosystemContractAdded(address contractAddress);
    event EverRiseEcosystemContractRemoved(address contractAddress);

    event HoldersIncreased(uint256 prevValue, uint256 newValue);
    event HoldersDecreased(uint256 prevValue, uint256 newValue);

    event AuthorizedSwapTokenAdded(address tokenAddress);
    event AuthorizedSwapTokenRemoved(address tokenAddress);

    event LiquidityLocked();
    event LiquidityUnlocked();

    event StakingIncreased(uint256 amount);
    event StakingDecreased(uint256 amount);

    modifier lockTheSwap() {
        require(_inSwapAndLiquify != _TRUE);
        _inSwapAndLiquify = _TRUE;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _inSwapAndLiquify = _FALSE;
    }

    modifier tokenCheck() {
        require(_checkingTokens != _TRUE);
        _checkingTokens = _TRUE;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _checkingTokens = _FALSE;
    }

    constructor(address _stakingAddress, address routerAddress) {
        require(
            _stakingAddress != address(0),
            "_stakingAddress should not be to the zero address"
        );
        require(
            routerAddress != address(0),
            "routerAddress should not be the zero address"
        );


        // The values being non-zero value makes deployment a bit more expensive,
        // but in exchange the refund on every call to modifiers will be lower in
        // amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to
        // increase the likelihood of the full refund coming into effect.
        _checkingTokens = _FALSE;
        _inSwapAndLiquify = _FALSE;

        stakingAddress = _stakingAddress;
        stakeToken = IEverStake(_stakingAddress);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Pancakeswap router mainnet - BSC
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //Sushiswap router mainnet - Polygon
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uniswap V2 router mainnet - ETH
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff); //Quickswap V2 router mainnet - Polygon
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        _tOwned[_msgSender()] = _tTotal;
        // Track holder change
        _holders = 1;
        emit HoldersIncreased(0, 1);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _everRiseEcosystemContractAdd(_stakingAddress);
        authorizedSwapTokenAdd(address(this));
        authorizedSwapTokenAdd(uniswapV2Router.WETH());

        emit Transfer(address(0), _msgSender(), _tTotal);
        lockLiquidity();
    }

    // Function to receive ETH when msg.data is be empty
    // Receives ETH from uniswapV2Router when swapping
    receive() external payable {}

    // Fallback function to receive ETH when msg.data is not empty
    fallback() external payable {}

    function transferBalance() external onlyOwner {
        _msgSender().transfer(address(this).balance);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function transferFromWithPermit(
        address sender,
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        permit(sender, _msgSender(), amount, deadline, v, r, s);
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function manualBuyback(uint256 amount, uint256 numOfDecimals)
        external
        onlyBuybackOwner
    {
        require(amount > 0 && numOfDecimals >= 0, "Invalid Input");

        uint256 value = amount.mul(10**18).div(10**numOfDecimals);

        uint256 tokensReceived = swapETHForTokensNoFee(
            address(this),
            stakingAddress,
            value
        );

        //Distribute the rewards to the staking pool
        distributeStakingRewards(tokensReceived);
    }

    function swapTokens(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 numOfDecimals,
        uint256 fromTokenDecimals
    ) external onlyBuybackOwner {
        require(_isAuthorizedSwapToken[fromToken], "fromToken is not an authorized token");
        require(_isAuthorizedSwapToken[toToken], "toToken is not an authorized token");

        uint256 actualAmount = amount
            .mul(10**fromTokenDecimals)
            .div(10**numOfDecimals);

        if (toToken == uniswapV2Router.WETH()) {
            swapTokensForEth(fromToken, address(this), actualAmount);
        } else if (fromToken == uniswapV2Router.WETH()) {
            swapETHForTokens(toToken, address(this), actualAmount);
        } else {
            swapTokensForTokens(
                fromToken,
                toToken,
                address(this),
                actualAmount
            );
        }
    }

    function lockLiquidity() public onlyOwner {
        liquidityLocked = true;
        emit LiquidityLocked();
    }

    function unlockLiquidity() external onlyOwner {
        liquidityLocked = false;
        emit LiquidityUnlocked();
    }

    function excludeFromFee(address account) external onlyOwner {
        require(
            !_isExcludedFromFee[account],
            "Account is not excluded for fees"
        );

        _excludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        require(
            _isExcludedFromFee[account],
            "Account is not included for fees"
        );

        _includeInFee(account);
    }

    function setLiquidityFeePercent(uint256 liquidityFeeRate) external onlyOwner {
        require(liquidityFeeRate <= 10, "liquidityFeeRate should be less than 10%");

        uint256 prevValue = liquidityFee;
        liquidityFee = liquidityFeeRate;
        emit LiquidityFeeUpdated(prevValue, liquidityFee);
    }

    function setMaxTxAmount(uint256 txAmount) external onlyOwner {
        uint256 prevValue = _maxTxAmount;
        _maxTxAmount = txAmount;
        emit MaxTxAmountUpdated(prevValue, txAmount);
    }

    function setBusinessDevelopmentDivisor(uint256 divisor) external onlyOwner {
        require(
            divisor <= liquidityFee,
            "Business Development divisor should be less than liquidity fee"
        );

        uint256 prevValue = businessDevelopmentDivisor;
        businessDevelopmentDivisor = divisor;
        emit BusinessDevelopmentDivisorUpdated(
            prevValue,
            businessDevelopmentDivisor
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap)
        external
        onlyOwner
    {
        uint256 prevValue = minimumTokensBeforeSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(prevValue, minimumTokensBeforeSwap);
    }

    function setBuybackUpperLimit(uint256 buyBackLimit, uint256 numOfDecimals)
        external
        onlyBuybackOwner
    {
        uint256 prevValue = buyBackUpperLimit;
        buyBackUpperLimit = buyBackLimit
            .mul(10**18)
            .div(10**numOfDecimals);
        emit BuybackUpperLimitUpdated(prevValue, buyBackUpperLimit);
    }

    function setBuybackTriggerTokenLimit(uint256 buyBackTriggerLimit)
        external
        onlyBuybackOwner
    {
        uint256 prevValue = buyBackTriggerTokenLimit;
        buyBackTriggerTokenLimit = buyBackTriggerLimit;
        emit BuyBackTriggerTokenLimitUpdated(
            prevValue,
            buyBackTriggerTokenLimit
        );
    }

    function setBuybackMinAvailability(uint256 amount, uint256 numOfDecimals)
        external
        onlyBuybackOwner
    {
        uint256 prevValue = buyBackMinAvailability;
        buyBackMinAvailability = amount
            .mul(10**18)
            .div(10**numOfDecimals);
        emit BuybackMinAvailabilityUpdated(prevValue, buyBackMinAvailability);
    }

    function setBuyBackEnabled(bool _enabled) public onlyBuybackOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setTradingEnabled(uint256 _tradeStartDelay, uint256 _tradeStartCoolDown) external onlyOwner {
        require(_tradeStartDelay < 10, "tradeStartDelay should be less than 10 minutes");
        require(_tradeStartCoolDown < 120, "tradeStartCoolDown should be less than 120 minutes");
        require(_tradeStartDelay < _tradeStartCoolDown, "tradeStartDelay must be less than tradeStartCoolDown");
        // Can only be called once
        require(tradingStart == MAX && tradingStartCooldown == MAX, "Trading has already started");
        // Set initial values
        liquidityFee = _tradeStartLiquidityFee;
        _previousLiquidityFee = liquidityFee;
        _maxTxAmount = _tradeStartMaxTxAmount;

        setBuyBackEnabled(true);
        setSwapAndLiquifyEnabled(true);
        // Add time buffer to allow switching on trading on every chain
        // before announcing to community
        tradingStart = block.timestamp + _tradeStartDelay * 1 minutes;
        tradingStartCooldown = tradingStart + _tradeStartCoolDown * 1 minutes;
        // Announce to blockchain immediately, even though trades
        // can't start until delay passes (snipers no sniping)
        emit TradingEnabled();
    }

    function setBusinessDevelopmentAddress(address _businessDevelopmentAddress)
        external
        onlyOwner
    {
        require(
            _businessDevelopmentAddress != address(0),
            "_businessDevelopmentAddress should not be the zero address"
        );

        address prevAddress = businessDevelopmentAddress;
        businessDevelopmentAddress = payable(_businessDevelopmentAddress);
        emit BusinessDevelopmentAddressUpdated(
            prevAddress,
            _businessDevelopmentAddress
        );
    }

    function setEverMigrateAddress(address _everMigrateAddress)
        external
        onlyOwner
    {
        require(
            _everMigrateAddress != address(0),
            "_everMigrateAddress should not be the zero address"
        );

        address prevAddress = everMigrateAddress;
        everMigrateAddress = _everMigrateAddress;
        emit EverMigrateAddressUpdated(prevAddress, _everMigrateAddress);

        _everRiseEcosystemContractAdd(_everMigrateAddress);
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        require(
            _stakingAddress != address(0),
            "_stakingAddress should not be to zero address"
        );

        address prevAddress = stakingAddress;
        stakingAddress = _stakingAddress;
        stakeToken = IEverStake(_stakingAddress);
        emit StakingAddressUpdated(prevAddress, _stakingAddress);

        _everRiseEcosystemContractAdd(_stakingAddress);
    }

    function setRouterAddress(address routerAddress) external onlyOwner {
        require(
            routerAddress != address(0),
            "routerAddress should not be the zero address"
        );

        address prevAddress = address(uniswapV2Router);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        emit RouterAddressUpdated(prevAddress, routerAddress);
    }

    function everRiseEcosystemContractAdd(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "contractAddress should not be the zero address");
        require(contractAddress != address(this), "EverRise token should not be added as an Ecosystem contract");
        require(
            !_isEverRiseEcosystemContract[contractAddress],
            "contractAddress is already included as an EverRise Ecosystem contract"
        );

        _everRiseEcosystemContractAdd(contractAddress);
    }

    function everRiseEcosystemContractRemove(address contractAddress) external onlyOwner {
        require(
            _isEverRiseEcosystemContract[contractAddress],
            "contractAddress is not included as EverRise Ecosystem contract"
        );

        _isEverRiseEcosystemContract[contractAddress] = false;

        for (uint256 i = 0; i < allEcosystemContracts.length; i++) {
            if (allEcosystemContracts[i] == contractAddress) {
                allEcosystemContracts[i] = allEcosystemContracts[allEcosystemContracts.length - 1];
                allEcosystemContracts.pop();
                break;
            }
        }

        emit EverRiseEcosystemContractRemoved(contractAddress);
        _includeInFee(contractAddress);
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 balance0 = _balanceOf(account);
        if (
            !inSwapAndLiquify() &&
            lastTransfer.blockNumber == uint32(block.number) &&
            account == lastTransfer.to
        ) {
            // Balance being checked is same address as last to in _transfer
            // check if likely same txn and a Liquidity Add
            _validateIfLiquidityAdd(account, uint112(balance0));
        }

        return balance0;
    }

    function maxTxAmount() external view returns (uint256) {
        if (isTradingEnabled() && inTradingStartCoolDown()) {
            uint256 maxTxn = maxTxCooldownAmount();
            return maxTxn < _maxTxAmount ? maxTxn : _maxTxAmount;
        }

        return _maxTxAmount;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function getTotalAmountStaked() external view returns (uint256)
    {
        return stakeToken.getTotalAmountStaked();
    }

    function getTotalRewardsDistributed() external view returns (uint256)
    {
        return stakeToken.getTotalRewardsDistributed();
    }

    function holders() external view returns (uint256) {
        return _holders;
    }

    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function buyBackUpperLimitAmount() external view returns (uint256) {
        return buyBackUpperLimit;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function allEcosystemContractsLength() external view returns (uint) {
        return allEcosystemContracts.length;
    }

    function allAuthorizedSwapTokensLength() external view returns (uint) {
        return allAuthorizedSwapTokens.length;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimalsShort;
    }

    function authorizedSwapTokenAdd(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "tokenAddress should not be the zero address");
        require(!_isAuthorizedSwapToken[tokenAddress], "tokenAddress is already an authorized token");

        _isAuthorizedSwapToken[tokenAddress] = true;
        allAuthorizedSwapTokens.push(tokenAddress);

        emit AuthorizedSwapTokenAdded(tokenAddress);
    }

    function authorizedSwapTokenRemove(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(this), "cannot remove this contract from authorized tokens");
        require(tokenAddress != uniswapV2Router.WETH(), "cannot remove the WETH type contract from authorized tokens");
        require(_isAuthorizedSwapToken[tokenAddress], "tokenAddress is not an authorized token");

        _isAuthorizedSwapToken[tokenAddress] = false;

        for (uint256 i = 0; i < allAuthorizedSwapTokens.length; i++) {
            if (allAuthorizedSwapTokens[i] == tokenAddress) {
                allAuthorizedSwapTokens[i] = allAuthorizedSwapTokens[allAuthorizedSwapTokens.length - 1];
                allAuthorizedSwapTokens.pop();
                break;
            }
        }

        emit AuthorizedSwapTokenRemoved(tokenAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function isTradingEnabled() public view returns (bool) {
        // Trading has been set and has time buffer has elapsed
        return tradingStart < block.timestamp;
    }

    function inTradingStartCoolDown() public view returns (bool) {
        // Trading has been started and the cool down period has elapsed
        return tradingStartCooldown >= block.timestamp;
    }

    function maxTxCooldownAmount() public pure returns (uint256) {
        return _tTotal.div(2000);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
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
        require(from != to, "Transfer to and from addresses the same");
        require(!inTokenCheck(), "Invalid reentrancy from token0/token1 balanceOf check");

        address _owner = owner();
        bool isIgnoredAddress = from == _owner || to == _owner ||
             _isEverRiseEcosystemContract[from] || _isEverRiseEcosystemContract[to];
        
        bool _isTradingEnabled = isTradingEnabled();

        require(amount <= _maxTxAmount || isIgnoredAddress || !_isTradingEnabled,
            "Transfer amount exceeds the maxTxAmount");
        
        address _pair = uniswapV2Pair;
        require(_isTradingEnabled || isIgnoredAddress || (from != _pair && to != _pair),
            "Trading is not enabled");

        bool notInSwapAndLiquify = !inSwapAndLiquify();
        if (_isTradingEnabled && inTradingStartCoolDown() && !isIgnoredAddress && notInSwapAndLiquify) {
            validateDuringTradingCoolDown(to, from, amount);
        }

        uint256 contractTokenBalance = _balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;

        bool contractAction = _isTradingEnabled &&
            notInSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            to == _pair;

        // Following block is for the contract to convert the tokens to ETH and do the buy back
        if (contractAction) {
            if (overMinimumTokenBalance) {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }
            if (buyBackEnabled &&
                address(this).balance > buyBackMinAvailability &&
                buyVolume.add(sellVolume) > buyBackTriggerVolume
            ) {
                if (nextBuybackAmount > address(this).balance) {
                    // Don't try to buyback more than is available.
                    // For example some "ETH" balance may have been
                    // temporally switched to stable coin in crypto-market
                    // downturn using swapTokens, for switching back later
                    nextBuybackAmount = address(this).balance;
                }

                if (nextBuybackAmount > 0) {
                    uint256 tokensReceived = buyBackTokens(nextBuybackAmount);
                    //Distribute the rewards to the staking pool
                    distributeStakingRewards(tokensReceived);
                    nextBuybackAmount = 0; //reset the next buyback amount
                    buyVolume = 0; //reset the buy volume
                    sellVolume = 0; // reset the sell volume
                }
            }
        }

        if (_isTradingEnabled) {
            // Compute Sell Volume and set the next buyback amount
            if (to == _pair) {
                sellVolume = sellVolume.add(amount);
                totalSellVolume = totalSellVolume.add(amount);
                if (amount > buyBackTriggerTokenLimit) {
                    uint256 balance = address(this).balance;
                    if (balance > buyBackUpperLimit) balance = buyBackUpperLimit;
                    nextBuybackAmount = nextBuybackAmount.add(balance.div(100));
                }
            }
            // Compute Buy Volume
            else if (from == _pair) {
                buyVolume = buyVolume.add(amount);
                totalBuyVolume = totalBuyVolume.add(amount);
            }
            
            totalVolume = totalVolume.add(amount);
        }

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        // For safety Liquidity Adds should only be done by an owner, 
        // and transfers to and from EverRise Ecosystem contracts
        // are not considered LP adds
        if (isIgnoredAddress || buybackOwner() == _msgSender()) {
            // Clear transfer data
            _clearTransferIfNeeded();
        } else if (notInSwapAndLiquify) {
            // Not in a swap during a LP add, so record the transfer details
            _recordPotentialLiquidityAddTransaction(to);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _recordPotentialLiquidityAddTransaction(address to)
        private
        tokenCheck {
        uint112 balance0 = uint112(_balanceOf(to));
        address token1 = to.token1();
        if (token1 == address(this)) {
            // Switch token so token1 is always other side of pair
            token1 = to.token0();
        }

        uint112 balance1;
        if (token1 == address(0)) {
            // Not a LP pair, or not yet (contract being created)
            balance1 = 0;
        } else {
            balance1 = uint112(IERC20(token1).balanceOf(to));
        }

        lastTransfer = TransferDetails({
            balance0: balance0,
            balance1: balance1,
            blockNumber: uint32(block.number),
            to: to,
            origin: tx.origin
        });
    }

    function _clearTransferIfNeeded() private {
        // Not Liquidity Add or is owner, clear data from same block to allow balanceOf
        if (lastTransfer.blockNumber == uint32(block.number)) {
            // Don't need to clear if different block
            lastTransfer = TransferDetails({
                balance0: 0,
                balance1: 0,
                blockNumber: 0,
                to: address(0),
                origin: address(0)
            });
        }
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(address(this), address(this), contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        //Send to Business Development address
        transferToAddressETH(
            businessDevelopmentAddress,
            transferredBalance
                .mul(businessDevelopmentDivisor)
                .div(liquidityFee)
        );
    }

    function buyBackTokens(uint256 amount)
        private
        lockTheSwap
        returns (uint256)
    {
        uint256 tokensReceived;
        if (amount > 0) {
            tokensReceived = swapETHForTokensNoFee(
                address(this),
                stakingAddress,
                amount
            );
        }
        return tokensReceived;
    }

    function swapTokensForEth(
        address tokenAddress,
        address toAddress,
        uint256 tokenAmount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            toAddress, // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokensNoFee(
        address tokenAddress,
        address toAddress,
        uint256 amount
    ) private returns (uint256) {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
        return amounts[1];
    }

    function swapETHForTokens(
        address tokenAddress,
        address toAddress,
        uint256 amount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function swapTokensForTokens(
        address fromTokenAddress,
        address toTokenAddress,
        address toAddress,
        uint256 tokenAmount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = fromTokenAddress;
        path[1] = uniswapV2Router.WETH();
        path[2] = toTokenAddress;

        IERC20(fromTokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Tokens
            path,
            toAddress, // The contract
            block.timestamp.add(120)
        );

        emit SwapTokensForTokens(tokenAmount, path);
    }

    function distributeStakingRewards(uint256 amount) private {
        if (amount > 0) {
            stakeToken.createRewards(address(this), amount);
            stakeToken.deliver(amount);

            emit BuyBackAndRewardStakers(amount);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        _actualTokenTransfer(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    function _actualTokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(tAmount);

        uint256 senderBefore = _tOwned[sender];
        uint256 senderAfter = senderBefore.sub(tAmount);
        _tOwned[sender] = senderAfter;

        uint256 recipientBefore = _tOwned[recipient];
        uint256 recipientAfter = recipientBefore.add(tTransferAmount);
        _tOwned[recipient] = recipientAfter;

        // Track holder change
        if (recipientBefore == 0 && recipientAfter > 0) {
            uint256 holdersBefore = _holders;
            uint256 holdersAfter = holdersBefore.add(1);
            _holders = holdersAfter;

            emit HoldersIncreased(holdersBefore, holdersAfter);
        }

        if (senderBefore > 0 && senderAfter == 0) {
            uint256 holdersBefore = _holders;
            uint256 holdersAfter = holdersBefore.sub(1);
            _holders = holdersAfter;

            emit HoldersDecreased(holdersBefore, holdersAfter);
        }

        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);

        if (recipient == stakingAddress) {
            // Increases by the amount entering staking (transfer - fees)
            // Howver, fees should be zero for staking so same as full amount.
            emit StakingIncreased(tTransferAmount);
        } else if (sender == stakingAddress) {
            // Decreases by the amount leaving staking (full amount)
            emit StakingDecreased(tAmount);
        }
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        require(deadline >= block.timestamp, "EverRise: EXPIRED");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        if (v < 27) {
            v += 27;
        } else if (v > 30) {
            digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        }
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "EverRise: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 beforeAmount = _tOwned[address(this)];
        uint256 afterAmount = beforeAmount.add(tLiquidity);
        _tOwned[address(this)] = afterAmount;

        // Track holder change
        if (beforeAmount == 0 && afterAmount > 0) {
            uint256 holdersBefore = _holders;
            uint256 holdersAfter = holdersBefore.add(1);
            _holders = holdersAfter;

            emit HoldersIncreased(holdersBefore, holdersAfter);
        }
    }

    function removeAllFee() private {
        if (liquidityFee == 0) return;

        _previousLiquidityFee = liquidityFee;

        liquidityFee = 0;
    }

    function restoreAllFee() private {
        liquidityFee = _previousLiquidityFee;
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function _everRiseEcosystemContractAdd(address contractAddress) private {
        if (_isEverRiseEcosystemContract[contractAddress]) return;

        _isEverRiseEcosystemContract[contractAddress] = true;
        allEcosystemContracts.push(contractAddress);

        emit EverRiseEcosystemContractAdded(contractAddress);
        _excludeFromFee(contractAddress);
    }

    function _excludeFromFee(address account) private {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFeeUpdated(account);
    }

    function _includeInFee(address account) private {
        _isExcludedFromFee[account] = false;
        emit IncludeInFeeUpdated(account);
    }

    function validateDuringTradingCoolDown(address to, address from, uint256 amount) private {
        address pair = uniswapV2Pair;
        bool disallow;

        // Disallow multiple same source trades in same block
        if (from == pair) {
            disallow = lastCoolDownTrade[to] == block.number || lastCoolDownTrade[tx.origin] == block.number;
            lastCoolDownTrade[to] = block.number;
            lastCoolDownTrade[tx.origin] = block.number;
        } else if (to == pair) {
            disallow = lastCoolDownTrade[from] == block.number || lastCoolDownTrade[tx.origin] == block.number;
            lastCoolDownTrade[from] = block.number;
            lastCoolDownTrade[tx.origin] = block.number;
        }

        require(!disallow, "Multiple trades in same block from same source are not allowed during trading start cooldown");

        require(amount <= maxTxCooldownAmount(), "Max transaction is 0.05% of total supply during trading start cooldown");
    }

    function inSwapAndLiquify() private view returns (bool) {
        return _inSwapAndLiquify == _TRUE;
    }

    function inTokenCheck() private view returns (bool) {
        return _checkingTokens == _TRUE;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(liquidityFee).div(10**2);
    }

    function _balanceOf(address account) private view returns (uint256) {
        return _tOwned[account];
    }

    // account must be recorded in _transfer and same block
    function _validateIfLiquidityAdd(address account, uint112 balance0)
        private
        view
    {
        // Test to see if this tx is part of a Liquidity Add
        // using the data recorded in _transfer
        TransferDetails memory _lastTransfer = lastTransfer;
        if (_lastTransfer.origin == tx.origin) {
            // May be same transaction as _transfer, check LP balances
            address token1 = account.token1();

            if (token1 == address(this)) {
                // Switch token so token1 is always other side of pair
                token1 = account.token0();
            }

            // Not LP pair
            if (token1 == address(0)) return;

            uint112 balance1 = uint112(IERC20(token1).balanceOf(account));

            if (balance0 > _lastTransfer.balance0 &&
                balance1 > _lastTransfer.balance1) {
                // Both pair balances have increased, this is a Liquidty Add
                require(false, "Liquidity can be added by the owner only");
            } else if (balance0 < _lastTransfer.balance0 &&
                balance1 < _lastTransfer.balance1)
            {
                // Both pair balances have decreased, this is a Liquidty Remove
                require(!liquidityLocked, "Liquidity cannot be removed while locked");
            }
        }
    }
}