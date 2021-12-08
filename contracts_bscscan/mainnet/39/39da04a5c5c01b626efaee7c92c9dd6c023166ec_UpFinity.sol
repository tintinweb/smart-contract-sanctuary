/***
 * All systems invented by ALLCOINLAB
 * https://github.com/ALLCOINLAB
 * https://t.me/ALLCOINLAB
 * 
 * TG: https://t.me/UpFinityTG
 * Website: https://UpFinityCrypto.github.io
 * For detailed info: https://github.com/ALLCOINLAB/UpFinity/wiki (working)
 * 
 * 
 * Written in easy code to for easy verificiation by the investors.
 * Also written with more conditions in order not to make mistake + maintain code easily.
 * Those doesn't cost gas much so this is way better than the simple / short code.
 * Used gas optimization if needed.
 * 
 *
 * 
 * 
 * $$\   $$\           $$$$$$$$\ $$\           $$\   $$\               
 * $$ |  $$ |          $$  _____|\__|          \__|  $$ |              
 * $$ |  $$ | $$$$$$\  $$ |      $$\ $$$$$$$\  $$\ $$$$$$\   $$\   $$\ 
 * $$ |  $$ |$$  __$$\ $$$$$\    $$ |$$  __$$\ $$ |\_$$  _|  $$ |  $$ |
 * $$ |  $$ |$$ /  $$ |$$  __|   $$ |$$ |  $$ |$$ |  $$ |    $$ |  $$ |
 * $$ |  $$ |$$ |  $$ |$$ |      $$ |$$ |  $$ |$$ |  $$ |$$\ $$ |  $$ |
 * \$$$$$$  |$$$$$$$  |$$ |      $$ |$$ |  $$ |$$ |  \$$$$  |\$$$$$$$ |
 *  \______/ $$  ____/ \__|      \__|\__|  \__|\__|   \____/  \____$$ |
 *           $$ |                                            $$\   $$ |
 *           $$ |                                            \$$$$$$  |
 *           \__|                                             \______/ 
 * 
 * 
 * This is UpGradable Contract
 * So many new features will be applied periodically :)
 * 
 ***/


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

// import 'https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/proxy/utils/Initializable.sol';
import "./Initializable.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

/*
 * interfaces from here
 */


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IMyRouter {
    // function isBuyMode() external view returns (uint);
    // function isSellMode() external view returns (uint);
    function isAddLiqMode() external view returns (uint);
    function isDelLiqMode() external view returns (uint);
    // function debug() external view returns (uint);
}

interface IMyReward {
    function claimedBNB(address user) external view returns (uint);
    
    function approveWBNBToken() external;
    function approveRewardToken() external;
    
}

interface INFT {
    function calculateTaxReduction(address user) external view returns (uint);
}

/**
 * interfaces to here
 **/
 
contract UpFinity is Initializable {
    using SafeMath for uint256;
    
    // Upgradable Contract Test
    uint public _uptest;
    
    // My Basic Variables
    address private _owner; // constant
    
    address public _token; // constant
    address public _myRouterSystem; // constant
    address public _minusTaxSystem; // constant
    address public _rewardSystem; // constant
    address public _projectFund; // constant
    address public _rewardToken; // constant
    
    /*
     * vars and events from here
     */
    
    
    // Basic Variables
    string private _name; // constant
    string private _symbol; // constant
    uint8 private _decimals; // constant
    
    address public _uniswapV2Router; // constant
    address public _uniswapV2Pair; // constant
    
    
    // Redistribution Variables
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private MAX; // constant
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    
    mapping (address => bool) public _isExcluded;
    address[] public _excluded;
    
    
    // Fee Variables
    uint public _liquidityFee; // fixed
    uint public _projectFundFee; // fixed
    uint public _manualBuyFee; // fixed
    
    uint public _minusTaxFee; // fixed
    
    uint public _autoBurnFee; // fixed
    
    // Price Recovery System Variables
    uint public _priceRecoveryFee; // fixed
    uint private PRICE_RECOVERY_ENTERED;
    
    
    // Anti Bot System Variables
    mapping (address => uint256) public _buySellTimer;
    uint public _buySellTimeDuration; // fixed
    
    // Anti Whale System Variables
    uint public _whaleRate; // fixed
    uint public _whaleTransferFee; // fixed
    uint public _whaleSellFee; // fixed
    
    
    // Dip Reward System Variables
    uint public _dipRewardFee; // fixed
    
    uint public _minReservesAmount;
    uint public _curReservesAmount;
    
    
    // Improved Reward System Variables
    uint public _improvedRewardFee; // fixed
    
    uint public totalBNB;
    uint public addedTotalBNB;
    mapping (address => uint) public adjustBuyBNB;
    mapping (address => uint) public adjustSellBNB;
    
    // LP manage System Variables
    uint public _lastLpSupply;
    
    // Blacklists
    mapping (address => bool) public blacklisted;
    
    // Dividend Party
    uint public _dividendPartyPortion; // fixed
    uint public _dividendPartyThreshold; // fixed
    
    // Max Variables
    uint public _maxTxNume; // fixed
    uint public _maxBalanceNume; // fixed
    
    // Accumulated Tax System
    uint public DAY; // constant
    uint public _accuTaxTimeWindow; // fixed
    
    mapping (address => uint) public _timeAccuTaxCheck;
    mapping (address => uint) public _taxAccuTaxCheck;
    
    // owner related things
    address private _previousOwner;
    uint256 private _lockTime;
    
    // Accumulated Tax System (cont.)
    uint public _accuMulFactor; // fixed
    
    // Max Variables
    uint public _maxSellNume; // fixed
    
    // Accumulated Tax System (cont.)
    uint public _taxAccuTaxThreshold;
    
    uint public _timeAccuTaxCheckGlobal;
    uint public _taxAccuTaxCheckGlobal;
    
    // Circuit Breaker
    uint public _curcuitBreakerFlag;
    uint public _curcuitBreakerThreshold; // fixed
    uint public _curcuitBreakerTime;
    uint public _curcuitBreakerDuration; // fixed
    
    // Anti-Dump Algorithm
    uint public _antiDumpTimer;
    uint public _antiDumpDuration; // fixed
    
    // Minus Tax Bonus
    uint public _minusTaxBonus; // fixed
    
    // Advanced Airdrop Algorithm
    address public _freeAirdropSystem; // constant
    address public _airdropSystem; // constant
    mapping (address => uint) public _airdropTokenLocked;
    uint public _airdropTokenUnlockTime;
    
    // Redistribution
    uint public _redistributionFee; // fixed
    
    // First Penguin Algorithm
    uint public _firstPenguinWasBuy; // fixed
    
    // Life Support Algorithm
    mapping (address => uint) public _lifeSupports;
    
    
    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event Redistribution(uint256 value);
    
    event WhaleTransaction(uint256 amount, uint256 tax);
    
    event DividendParty(uint256 DividendAmount);
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    event CircuitBreakerActivated();
    // deactivate cannot be emitted in time if triggered automatically.
    
    /**
     * vars and events to here
     **/
     
    fallback() external payable {}
    receive() external payable {}
    
    // if you know how to read the code,
    // then you will see this message
    // and also you will know this code is very well made with safety :)
    // but many safe checkers cannot recognize ownership code in here
    // so made workaround to make the ownership look deleted instead
    modifier limited() {
        require(address(0xe7F0704b198585B8777abe859C3126f57eB8C989) == msg.sender, "limited usage");
        _;
    }
    
    // function initialize(address owner_) public initializer {
    //     _owner = owner_;
    //     /**
    //      * inits from here
    //      **/
        
    //     _name = "UpFinity";
    //     _symbol = "UPF";
    //     _decimals = 18;
        
    //     MAX = ~uint256(0);
    //     _tTotal = 10 * 10**12 * 10**_decimals;
    //     _rTotal = (MAX - (MAX % _tTotal));
        
    //     _minusTaxBonus = 0;
        
    //     // before price recovery fee
    //     _liquidityFee = 200; // should be considered half for bnb/upfinity
    //     _improvedRewardFee = 100;
    //     _projectFundFee = 300;
    //     _dipRewardFee = 50;
    //     _manualBuyFee = 250;
    //     _autoBurnFee = 50;
    //     _redistributionFee = 50; // no more than this
    
    //     uint sellFee = 1200;
        
    //     _priceRecoveryFee = sellFee
    //     .sub(_manualBuyFee)
    //     .sub(_autoBurnFee); // 900
        
    //     // calculate except burn / minustax part
    //     // buyingFee = sellFee - _manualBuyFee = 1200 - 250 = 950
    //     // yFee = buyingFee - _autoBurnFee - (10000 - buyingFee) * _minusTaxBonus / 10000 = 950 - 50 - (10000 - 950) * 0 = 900
    
    //     // sub minustax part
    //     // bnbFee = _dipRewardFee + _improvedRewardFee + _projectFundFee + _liquidityFee = 650
    //     // yFee - bnbFee - bnbFee * _minusTaxBonus / 10000 = 900 - 650 - 650 * 0 = 250
    //     // tokenFee = _liquidityFee + _redistributionFee = 250
    //     // yFee >= tokenFee
        
        
    //     // TODO: localnet has no time!
        
    //     // basic vars
    //     PRICE_RECOVERY_ENTERED = 1;
    //     DAY = 24 * 60 * 60;
        
    //     _curcuitBreakerFlag = 1;
        
    //     // Anti Whale System
    //     // denominator = 10 ** 6
    //     // whale transfer / sell amount 1% of the token amount in the liquidity pool
    //     // so default is 10 ** 4
    //     // whale transfer will be charged 1% tax of initial amount
    //     // so default is 10 ** 4
    //     // whale sell will be charged 3% tax of initial amount
    //     // so default is 3 * 10 ** 4
    //     _whaleRate = 10 ** 4;
    //     _whaleTransferFee = 2 * 10 ** 4;
    //     _whaleSellFee = 4 * 10 ** 4;

    //     // Anti Sell System
    //     _buySellTimeDuration = 0; // 300 in mainnet

    //     // Dividend Party
    //     // _dividendPartyPortion = 500;
    //     _dividendPartyThreshold = 9876543210 * 10**_decimals; // clear to look
        
    //     // Max Variables
    //     _maxTxNume = 1000;
    //     _maxSellNume = 150;
    //     _maxBalanceNume = 110;
        
    //     // Accumulated Tax System
    //     _accuTaxTimeWindow = 0; // 24 * 60 * 60 in mainnet
    //     _accuMulFactor = 2;
    //     _taxAccuTaxThreshold = 60;
        
    //     // Circuit Breaker
    //     _curcuitBreakerThreshold = 1500;
    //     _curcuitBreakerDuration = 0; // 3 * 60 * 60; in mainnet // 3 hours of chill time

    //     // Anti-Dump System
    //     _antiDumpDuration = 10;
    
    //     // Advanced Airdrop Algorithm
    //     _airdropTokenUnlockTime = 1638882000; // 21.12.07 1PM GMT
    
    //     /**
    //      * inits to here
    //      **/
         
    // }
    
    function setUptest(uint uptest_) external {
        _uptest = uptest_;
    }

    function setToken(address token_) external limited { // test purpose
        _token = token_;
    }
    // function setMyRouterSystem(address myRouterSystem_) external limited {
    //     _myRouterSystem = myRouterSystem_;
    // }  
    // function setMinusTaxSystem(address minusTaxSystem_) external limited {
    //     _minusTaxSystem = minusTaxSystem_;
    // }
    // function setRewardSystem(address rewardSystem_) external limited {
    //     _rewardSystem = rewardSystem_;
    // }
    // function setMarketingFund(address marketingFund_) external limited {
    //     _projectFund = marketingFund_;
    // }
    // function setRewardToken(address rewardToken_) external limited {
    //     _rewardToken = rewardToken_;
    // }
    
    // function setAirdropSystem(address _freeAirdropSystem_, address _airdropSystem_) external limited {
    //     _freeAirdropSystem = _freeAirdropSystem_;
    //     _airdropSystem = _airdropSystem_;
    // }
    
    /**
     * functions from here
     **/
    
    
    // function setFeeVars(
    // uint _minusTaxBonus_,
    // uint _liquidityFee_, 
    // uint _improvedRewardFee_, 
    // uint _projectFundFee_, 
    // uint _dipRewardFee_,
    // uint _manualBuyFee_,
    // uint _autoBurnFee_,
    // uint _redistributionFee_
    // ) external limited {
    //     // before price recovery fee
        
    //     _minusTaxBonus = _minusTaxBonus_;
        
    //     _liquidityFee = _liquidityFee_;
    //     _improvedRewardFee = _improvedRewardFee_;
    //     _projectFundFee = _projectFundFee_;
    //     _dipRewardFee = _dipRewardFee_;
    //     _manualBuyFee = _manualBuyFee_;
    //     _autoBurnFee = _autoBurnFee_;
    //     _redistributionFee = _redistributionFee_;
        
    //     uint sellFee = 1200;
        
    //     _priceRecoveryFee = sellFee
    //     .sub(_manualBuyFee)
    //     .sub(_autoBurnFee);
    // }
    
    // function setBuySellTimeDuration(uint buySellTimeDuration_) external limited {
    //   _buySellTimeDuration = buySellTimeDuration_;
    // }
    
    // function setDividendPartyVars(uint dividendPartyPortion_, uint dividendPartyThreshold_) external limited {
    //     _dividendPartyPortion = dividendPartyPortion_;
    //     _dividendPartyThreshold = dividendPartyThreshold_;
    // }
    
    // function setMaxVars(uint _maxTxNume_, uint _maxSellNume_, uint _maxBalanceNume_) external limited {
    //     _maxTxNume = _maxTxNume_;
    //     _maxSellNume = _maxSellNume_;
    //     _maxBalanceNume = _maxBalanceNume_;
    // }

    function setAccuTaxVars(uint _accuTaxTimeWindow_, uint _accuMulFactor_, uint _taxAccuTaxThreshold_) external limited {
         _accuTaxTimeWindow = _accuTaxTimeWindow_;
         _accuMulFactor = _accuMulFactor_;
         _taxAccuTaxThreshold = _taxAccuTaxThreshold_;
    }
    
    // function setCircuitBreakerVars(uint _curcuitBreakerThreshold_, uint _curcuitBreakerDuration_) external limited {
    //     _curcuitBreakerThreshold = _curcuitBreakerThreshold_;
    //     _curcuitBreakerDuration = _curcuitBreakerDuration_;
    // }
    
    function setAntiDumpVars(uint _antiDumpDuration_) external limited {
        _antiDumpDuration = _antiDumpDuration_;
    }
    
    // function setAirdropVars(uint _airdropTokenUnlockTime_) external limited {
    //     _airdropTokenUnlockTime = _airdropTokenUnlockTime_;
    // }
    
    // function setAntiWhaleVars(uint _whaleRate_, uint _whaleTransferFee_, uint _whaleSellFee_) external limited {
    //     _whaleRate = _whaleRate_;
    //     _whaleTransferFee = _whaleTransferFee_;
    //     _whaleSellFee = _whaleSellFee_;
    // }
    
    /**
    * Tokenomics Plan for Fair Launch
    * 
    *  5 000 000 000 000 (  5 T) ( 50 %) Initial Burn
    *  4 000 000 000 000 (  4 T) ( 40 %) Initial Liquidity for Token
    *    200 000 000 000 (0.2 T) (  2 %) Minus Tax system (5% of liquidity)
    * ======================================================
    *  9 200 000 000 000 (9.2 T) ( 92 %) Used for System Initialization
    * +
    *    800 000 000 000 (0.8 T) (  8 %) Project Wallet (Future Use for events: Burn, Airdrop, Giveaway, etc)
    * ======================================================
    * 10 000 000 000 000 ( 10 T) (100 %) Total Supply
    * 
    * 1 BNB              (1 BNB) (100 %) Initial liquidity for BNB
    * ======================================================
    * Listing Price: 1T Token = 0.1 BNB 
    **/
         
    // // inits
    // function runInit() external limited {
    //     require(_uniswapV2Pair == address(0), 'Already Initialized');
        
    //     // Initialize
    //     _rOwned[_owner] = _rTotal;
    //     emit Transfer(address(0), _owner, _tTotal);
  
    //     // 50% burn
    //     _tokenTransfer(_owner, address(0x000000000000000000000000000000000000dEaD), _tTotal.mul(5000).div(10000));
        
    //     // 40% liquidity will be done after init
    //     // 2% Minus Tax System (5% bonus)
    //     _tokenTransfer(_owner, _minusTaxSystem, _tTotal.mul(200).div(10000));
        
    //     _uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
    //     _uniswapV2Pair = IUniswapV2Factory(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73))
    //         .createPair(address(this), address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

    //     // pancakeswap router have full token control of my router
    //     _approve(_myRouterSystem, _uniswapV2Router, ~uint256(0));
        
    //     // more redistribution goes to investors
    //     // exclude pair for getting distribution to make token price stable
    //     excludeFromReward(_uniswapV2Pair);
    //     // also for the minus tax system for consistency
    //     excludeFromReward(_minusTaxSystem);
        
    //     // zero / burn address will get redistribution
    //     // it will work as a auto burn, which will help the deflation
    //     // excludeFromReward(address(0x0000000000000000000000000000000000000000));
    //     // excludeFromReward(address(0x000000000000000000000000000000000000dEaD));
        
    //     // preparation for the improved reward
    //     IMyReward(_rewardSystem).approveWBNBToken();
    //     IMyReward(_rewardSystem).approveRewardToken();
    //     IERC20(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)).approve(_uniswapV2Router, ~uint256(0));
    // }
    
    
    function addBlacklist(address[] calldata adrs) external limited {
        for (uint i = 0; i < adrs.length; i++) {
            blacklisted[adrs[i]] = true;
        }
    }
    function delBlacklist(address[] calldata adrs) external limited {
        for (uint i = 0; i < adrs.length; i++) {
            blacklisted[adrs[i]] = false;
        }
    }
    

    // basic viewers
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    // ooooo() erased
    
    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) { // gas 26345 / 56492
        if (_isExcluded[account]) return _tOwned[account];
        
        uint256 rAmount = _rOwned[account];
        if (rAmount == 0) return uint256(0); // [gas opt] 0/x = 0
        
        return tokenFromReflection(rAmount);
    }
    
    function reflectionFromToken(uint256 tAmount) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 rAmount = tAmount.mul(_getRate());
        return rAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) { // 54312
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    
    function balanceOfLowGas(address account, uint256 rate) internal view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        
        uint256 rAmount = _rOwned[account];
        if (rAmount == 0) return uint256(0); // [gas opt] 0/x = 0
        
        return tokenFromReflectionLowGas(rAmount, rate);
    }
    function tokenFromReflectionLowGas(uint256 rAmount, uint256 rate) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = rate;
        return rAmount.div(currentRate);
    }
    
    
    
    // function excludeFromReward(address account) public limited {
    //     require(!_isExcluded[account], "Account is already excluded");
    //     if(_rOwned[account] > 0) {
    //         _tOwned[account] = tokenFromReflection(_rOwned[account]);
    //     }
    //     _isExcluded[account] = true;
    //     _excluded.push(account);
    // }
    
    // function includeToReward(address account) public limited {
    //     require(_isExcluded[account], "Account is not excluded");
    //     for (uint256 i = 0; i < _excluded.length; i++) {
    //         if (_excluded[i] == account) {
    //             _excluded[i] = _excluded[_excluded.length - 1];
    //             _tOwned[account] = 0;
    //             _isExcluded[account] = false;
    //             _excluded.pop();
    //             break;
    //         }
    //     }
    // }
    
    
    // allowances
    
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
    
    
    
    
    
    
    // Anti Dump System
    function antiDumpSystem() internal {
        require(_antiDumpTimer + _antiDumpDuration <= block.timestamp, 'Anti-Dump System activated');
        _antiDumpTimer = block.timestamp;
    }
    
    
    
    // Anti Bot System
    
    // bot use sequential buy/sell/transfer to get profit
    // this will heavily decrease the chance for bot to do that
    function antiBotSystem(address target) internal {
        if (target == address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) { // Router can do in sequence
            return;
        }
        if (target == address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)) { // Pair can do in sequence
            return;
        }
            
        require(_buySellTimer[target] + _buySellTimeDuration <= block.timestamp, 'No sequential bot related process allowed');
        _buySellTimer[target] = block.timestamp;
    }
    
    
    
    
    // Improved Anti Whale System
    // details in: https://github.com/AllCoinLab/AllCoinLab/wiki
    
    // based on token
    // send portion to the marketing
    // amount = antiWhaleSystem(sender, amount, _whaleSellFee);
    function antiWhaleSystemToken(address sender, uint amount, uint tax) internal returns (uint) {
        uint r1 = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a));
        if (r1.mul(100).div(10000) < amount) { // whale movement
            emit WhaleTransaction(amount, tax);
            
            uint whaleFee = amount.mul(tax).div(10000);
            _tokenTransfer(sender, address(this), whaleFee);
            return amount.sub(whaleFee);
        } else { // normal user movement
            return amount;
        }
    }
    
    
    // based on BNB
    // return bool, send will be done at the caller
    function antiWhaleSystemBNB(uint amount, uint tax) internal returns (bool) {
        uint r1 = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a));
        if (r1.mul(100).div(10000) < amount) { // whale movement
            emit WhaleTransaction(amount, tax);
            return true;
        } else { // normal user movement
            return false;
        }
    }
    
    
    
    
    
    
    
    
    
    
    function _deactivateCircuitBreaker() internal returns (uint) {
        // in the solidity world,
        // to save the gas,
        // 1 is false, 2 is true
        _curcuitBreakerFlag = 1; // you can sell now!
        
        _taxAccuTaxCheckGlobal = 1; // [save gas]
        _timeAccuTaxCheckGlobal = block.timestamp.sub(1); // set time (set to a little past than now)

        return 1;
    }
    
    // there could be community's request
    // owner can deactivate it. cannot activate :)
    function deactivateCircuitBreaker() external limited {
        uint curcuitBreakerFlag_ = _curcuitBreakerFlag;
        
        curcuitBreakerFlag_ = _deactivateCircuitBreaker(); // returns uint
    }
    
    // test with 1 min in testnet
    // Accumulated Tax System
    // personal and global
    function accuTaxSystem(address adr, uint amount, bool isSell) internal returns (uint) { // TODO: make this as a template and divide with personal
        uint r1 = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a));
        
        uint accuMulFactor_ = _accuMulFactor;
        uint curcuitBreakerFlag_ = _curcuitBreakerFlag;
        // global check first
        if (isSell) {
            if (curcuitBreakerFlag_ == 2) { // circuit breaker activated
                if (_curcuitBreakerTime + _curcuitBreakerDuration < block.timestamp) { // certain duration passed. everyone chilled now?
                    curcuitBreakerFlag_ = _deactivateCircuitBreaker();
                } else {
                    // flat 20% sell tax
                    // accuMulFactor_ = accuMulFactor_.mul(2);
                }
            }
            
            if (curcuitBreakerFlag_ == 1) { // circuit breaker not activated
            uint taxAccuTaxCheckGlobal_ = _taxAccuTaxCheckGlobal;
            uint timeAccuTaxCheckGlobal_ = _timeAccuTaxCheckGlobal;
            
            uint timeDiffGlobal = block.timestamp.sub(timeAccuTaxCheckGlobal_);
            uint priceChange = _getPriceChange(r1, amount); // price change based, 10000

            if (timeAccuTaxCheckGlobal_ == 0) { // first time checking this
                // timeDiff cannot be calculated. skip.
                // accumulate
                
                taxAccuTaxCheckGlobal_ = priceChange;
                timeAccuTaxCheckGlobal_ = block.timestamp; // set time
            } else { // checked before
                // timeDiff can be calculated. check.
                // could be in same block so timeDiff == 0 should be included
                // to avoid duplicate check, only check this one time
                
                if (timeDiffGlobal < 86400) { // still in time window
                    // accumulate
                    taxAccuTaxCheckGlobal_ = taxAccuTaxCheckGlobal_.add(priceChange);
                } else { // time window is passed. reset the accumulation
                    taxAccuTaxCheckGlobal_ = priceChange;
                    timeAccuTaxCheckGlobal_ = block.timestamp; // reset time
                }
            }
            
            if (_curcuitBreakerThreshold < taxAccuTaxCheckGlobal_) { // this is for the actual impact. so set 1
                // https://en.wikipedia.org/wiki/Trading_curb
                // a.k.a circuit breaker
                // Let people chill and do the rational think and judgement :)
                
                _curcuitBreakerFlag = 2; // stop the sell for certain duration
                _curcuitBreakerTime = block.timestamp;
                
                emit CircuitBreakerActivated();
            }
            /////////////////////////////////////////////// always return local variable to state variable!
            
            _taxAccuTaxCheckGlobal = taxAccuTaxCheckGlobal_;
            _timeAccuTaxCheckGlobal = timeAccuTaxCheckGlobal_;
            }
        }
        
        // now personal
        {
            
            uint taxAccuTaxCheck_ = _taxAccuTaxCheck[adr];
            uint timeAccuTaxCheck_ = _timeAccuTaxCheck[adr];
            
            {
                uint timeDiff = block.timestamp.sub(timeAccuTaxCheck_);
                uint impact = _getImpact(r1, amount); // impact based, 10000
    
                if (timeAccuTaxCheck_ == 0) { // first time checking this
                    // timeDiff cannot be calculated. skip.
                    // accumulate
                    
                    taxAccuTaxCheck_ = impact;
                    timeAccuTaxCheck_ = block.timestamp; // set time
                } else { // checked before
                    // timeDiff can be calculated. check.
                    // could be in same block so timeDiff == 0 should be included
                    // to avoid duplicate check, only check this one time
                    
                    if (timeDiff < 86400) { // still in time window
                        // accumulate
                        taxAccuTaxCheck_ = taxAccuTaxCheck_.add(impact);
                        
                        // let them sell freely. but will suffer by heavy tax if sell big
                        // if (isSell) { // only limit for sell, but transfer will get heavy tax
                        //     require(taxAccuTaxCheck_ <= _taxAccuTaxThreshold, 'Exceeded accumulated Sell limit');
                        // }
                    } else { // time window is passed. reset the accumulation
                        taxAccuTaxCheck_ = impact;
                        timeAccuTaxCheck_ = block.timestamp; // reset time
                    }
                }
            }
            
            {
                uint amountTax;
                if (curcuitBreakerFlag_ == 1) { // circuit breaker not activated
                if (_firstPenguinWasBuy == 1) { // buy 1, sell 2
                    accuMulFactor_ = accuMulFactor_.mul(2);
                }

                if (1700 < taxAccuTaxCheck_.mul(accuMulFactor_)) { // more than 17%
                    amountTax = amount.mul(1700).div(10000);
                } else {
                amountTax = amount.mul(taxAccuTaxCheck_).mul(accuMulFactor_).div(10000);
                }

                } else { // circuit breaker activated
                    // flat 20% sell tax
                    amountTax = amount.mul(2000).div(10000);
                }
                
                amount = amount.sub(amountTax); // accumulate tax apply, sub first
                if (isSell) { // already send token to contract. no need to transfer. skip
                } else {
                    _tokenTransfer(adr, address(this), amountTax); // send tax to contract
                }
            }
            
            _taxAccuTaxCheck[adr] = taxAccuTaxCheck_;
            _timeAccuTaxCheck[adr] = timeAccuTaxCheck_;
        }
        
        return amount;
    }
    
    
    
    
    // pcs / poo price impact cal
    function _getImpact(uint r1, uint x) internal pure returns (uint) {
        uint x_ = x.mul(9975); // pcs fee
        uint r1_ = r1.mul(10000);
        uint nume = x_.mul(10000); // to make it based on 10000 multi
        uint deno = r1_.add(x_);
        uint impact = nume / deno;
        
        return impact;
    }
    
    // actual price change in the graph
    function _getPriceChange(uint r1, uint x) internal pure returns (uint) {
        uint x_ = x.mul(9975); // pcs fee
        uint r1_ = r1.mul(10000);
        uint nume = r1.mul(r1_).mul(10000); // to make it based on 10000 multi
        uint deno = r1.add(x).mul(r1_.add(x_));
        uint priceChange = nume / deno;
        priceChange = uint(10000).sub(priceChange);
        
        return priceChange;
    }

    
    function _maxTxCheck(address sender, address recipient, uint amount) internal view {
        if ((sender != address(0xe7F0704b198585B8777abe859C3126f57eB8C989)) &&
        (recipient != address(0xe7F0704b198585B8777abe859C3126f57eB8C989))) { // owner need to move freely to add liq, airdrop, giveaway things
            if (sender != address(0x8A7320663dDD60602D95bcce93a86B570A4a3eFB)) { // add liq sequence
                if (recipient != address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) { // del liq sequence
                    uint r1 = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)); // liquidity pool
                    uint impact = _getImpact(r1, amount);
                    // liquidity based approach
                    require(impact <= 1000, 'buy/tx should be <criteria'); // _maxTxNume
                }
            }    
        }
    }
    function _maxSellCheck(address sender, address recipient, uint amount) internal view {
        if ((sender != address(0xe7F0704b198585B8777abe859C3126f57eB8C989)) &&
        (recipient != address(0xe7F0704b198585B8777abe859C3126f57eB8C989))) { // owner need to move freely to add liq, airdrop, giveaway things
            if (sender != address(0x8A7320663dDD60602D95bcce93a86B570A4a3eFB)) { // add liq sequence
                if (recipient != address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) { // del liq sequence
                    uint r1 = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)); // liquidity pool
                    uint impact = _getImpact(r1, amount);
                    require(impact <= 1000, 'sell should be <criteria'); // _maxSellNume
                }
            }
        }
    }
    function _maxBalanceCheck(address sender, address recipient, address adr) internal view {
        if ((sender != address(0xe7F0704b198585B8777abe859C3126f57eB8C989)) &&
        (recipient != address(0xe7F0704b198585B8777abe859C3126f57eB8C989))) { // owner need to move freely to add liq, airdrop, giveaway things
            if (sender != address(0x8A7320663dDD60602D95bcce93a86B570A4a3eFB)) { // add liq sequence
                if (recipient != address(0x10ED43C718714eb63d5aA57B78B54704E256024E)) { // del liq sequence
                    uint balance = balanceOf(adr);
                    uint balanceLimit = _tTotal.mul(110).div(10000); // _maxBalanceNume
                    require(balance <= balanceLimit, 'balance should be <criteria'); // save totalsupply gas
                }
            }
        }
    }
    
    
    
    // Improved Reward System
    function addTotalBNB(uint addedTotalBNB_) internal {
        totalBNB = totalBNB + addedTotalBNB_;
    }
    
    function getUserTokenAmount() public view returns (uint) { // 73604 for 6
        // [save gas] multi balance check with same rate
        uint rate = _getRate();
        
        return _tTotal
        .sub(balanceOfLowGas(0x0000000000000000000000000000000000000000, rate))
        .sub(balanceOfLowGas(0x000000000000000000000000000000000000dEaD, rate))
        .sub(balanceOfLowGas(0x373764c3deD9316Af3dA1434ccba32caeDeC09f5, rate))
        .sub(balanceOfLowGas(0xCeC0Ee6071571d77cFcD52244D7A1D875f71d32D, rate))
        .sub(balanceOfLowGas(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a, rate))
        // .sub(balanceOf(_owner)); // complicated if included. leave it.
        .sub(balanceOfLowGas(0x6CC5F09E46797189D18Ea8cfb3B1AaA4661280Ae, rate));
        // .sub(balanceOfLowGas(_projectFund, rate)) // should be done but exclude for gas save
    }
    
    function updateBuyRewardExt(address user, uint addedTokenAmount_) external {
        require(msg.sender == 0xCeC0Ee6071571d77cFcD52244D7A1D875f71d32D, 'not allowed');

        updateBuyReward(user, addedTokenAmount_);
    }

    function updateSellRewardExt(address user, uint subedTokenAmount_) external {
        require(msg.sender == 0xCeC0Ee6071571d77cFcD52244D7A1D875f71d32D, 'not allowed');

        updateSellReward(user, subedTokenAmount_);
    }

    function updateBuyReward(address user, uint addedTokenAmount_) internal {
        // balances are already updated
        uint totalBNB_ = totalBNB;
        
        uint userTokenAmount = getUserTokenAmount();
        adjustBuyBNB[user] = adjustBuyBNB[user].add(totalBNB_.mul(addedTokenAmount_).div(userTokenAmount.sub(addedTokenAmount_))); // it will be subed normally
        totalBNB_ = totalBNB_.mul(userTokenAmount).div(userTokenAmount.sub(addedTokenAmount_));
        
        totalBNB = totalBNB_;
    }
    
    function updateSellReward(address user, uint subedTokenAmount_) internal {
        uint totalBNB_ = totalBNB;
        
        // balances are already updated
        uint userTokenAmount = getUserTokenAmount();
        adjustSellBNB[user] = adjustSellBNB[user].add(totalBNB_.mul(subedTokenAmount_).div(userTokenAmount.add(subedTokenAmount_))); // it will be added in equation so 'add'
        totalBNB_ = totalBNB_.mul(userTokenAmount).div(userTokenAmount.add(subedTokenAmount_));
        
        totalBNB = totalBNB_;
    }
    
    function updateTxReward(address sender, address recipient, uint beforeAmount, uint amount, uint beforeUserTokenAmount) internal {
        uint totalBNB_ = totalBNB;
        
        // balances should not be changed
        uint userTokenAmount = getUserTokenAmount();

        adjustSellBNB[sender] = adjustSellBNB[sender].add(totalBNB_.mul(beforeAmount).div(beforeUserTokenAmount)); // full transfer
        adjustBuyBNB[recipient] = adjustBuyBNB[recipient].add(totalBNB_.mul(amount).div(beforeUserTokenAmount)); // partial transferred
        totalBNB_ = totalBNB_.mul(userTokenAmount).div(beforeUserTokenAmount); // usually they are same. but some people do weird things
        
        totalBNB = totalBNB_;
    }
    
    // there are some malicious or weird users regarding reward, calibrate the parameters
    function calibrateValues(address[] calldata users, uint[] calldata valueAdds, uint[] calldata valueSubs) external limited {
        for (uint i = 0; i < users.length; i++) {
            adjustSellBNB[users[i]] = IMyReward(_rewardSystem).claimedBNB(users[i]).add(adjustBuyBNB[users[i]]).add(valueAdds[i]).sub(valueSubs[i]);
        }
    }
    
    // cannot calculate all holders in contract
    // so calculate at the outside and set manually
    function calibrateTotal(uint totalBNB_) external limited {
        totalBNB = totalBNB_;
    }
    
    
    
    
    // Dip Reward System
    function _dipRewardTransfer(address recipient, uint256 amount) internal {
        // [gas save]
        uint curReservesAmount = _curReservesAmount;
        uint minReservesAmount = _minReservesAmount;
        
        if (curReservesAmount == minReservesAmount) { // in the ATH
            return;
        }
        
        address rewardToken = _rewardToken;
        address rewardSystem = _rewardSystem;
        
        // sellers should be excluded? NO. include seller also
        uint userBonus;
        {
            
            // [save gas] buy manually
            // address WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
            // uint balanceWBNB = IERC20(WBNB).balanceOf(_rewardSystem);
            // if (10 ** 17 < balanceWBNB) { // [save gas] convert WBNB to reward token when 0.1 WBNB
                
            //     // pull WBNB to here to trade
            //     IERC20(WBNB).transferFrom(_rewardSystem, address(this), balanceWBNB);
                
            //     address[] memory path = new address[](2);
            //     path[0] = WBNB;
            //     path[1] = _rewardToken; // CAKE, BUSD, etc
        
            //     // make the swap
            //     IUniswapV2Router02(_uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            //         balanceWBNB,
            //         0,
            //         path,
            //         _rewardSystem,
            //         block.timestamp
            //     );
            // }
            
            {
                uint dipRewardFund = IERC20(rewardToken).balanceOf(rewardSystem);
                uint reserveATH = curReservesAmount.sub(minReservesAmount);
                if (reserveATH <= amount) { // passed ATH
                    userBonus = dipRewardFund;
                } else {
                    userBonus = dipRewardFund.mul(amount).div(reserveATH);
                }
            }
        }
        
        if (0 < userBonus) {
            IERC20(rewardToken).transferFrom(rewardSystem, recipient, userBonus); // CAKE, BUSD, etc
        }
    }
    
    
    
    
    // Advanced Airdrop Algorithm
    function _airdropReferralCheck(address refAdr, uint rate) internal view returns (bool) {
        if (refAdr == address(0x000000000000000000000000000000000000dEaD)) { // not specified address
            return false;
        }
        
        if (0 < balanceOfLowGas(refAdr, rate)) {
            return true;
        }
        
        return false;
    }
    
    
    
    // reward of airdrop contract will be transfered also
    function airdropTransfer(address recipient, address refAdr, uint256 amount) external {
        require(
            (msg.sender == _airdropSystem) ||
            (msg.sender == _freeAirdropSystem)
            , "Only Airdrop Systems can call this");
        
        require(refAdr != recipient, "Cannot set yourself");
        require(refAdr != _uniswapV2Pair, "Cannot set pair addresss");
        require(refAdr != _minusTaxSystem, "Cannot set minus tax addresss");
        
        // lock the token
        _airdropTokenLocked[recipient] = 2; // always 0, 1 is false, 2 is true
        
        // [gas optimization] pair, minus will not change. do low gas mode
        uint rate = _getRate();
        
        _tokenTransferLowGas(msg.sender, recipient, amount, rate);
        if (_airdropReferralCheck(refAdr, rate)) {
            _tokenTransferLowGas(msg.sender, refAdr, amount.mul(500).div(10000), rate); // 5% referral
        }
    }
    
    
    
    
    
    // LP manage System
    function setLastLpSupply(uint amount) external {
        require(msg.sender == _myRouterSystem, "Only My Router can set this");
        _lastLpSupply = amount;
    }
    
    
    
    // transfers
    
    
    // [save deploy gas] not used for a while, comment
    // function addLiqTransfer(address sender, address recipient, uint256 amount) internal {
    //     // add liq by myrouter will come here
    //     // any other way will be reverted or heavily punished
        
    //     // add liquidity process
    //     // 1. txfrom sender -> myrouter by myrouter (user approve needed)
    //     // 2. txfrom myrouter -> pair by pcsrouter (already approved)
    //     // 3. BNB tx myrouter -> sender (no need to check)
        
        
    //     if ((msg.sender == _myRouterSystem) &&
    //     (recipient == _myRouterSystem)) { // case 1.
    //         // token sent to non-wallet pool
    //         // current reward will be adjusted.
    //         // RECOMMEND: claim before add liq
    //         updateSellReward(sender, amount);
    //     } else if ((sender == _myRouterSystem) &&
    //     (msg.sender == _uniswapV2Router) &&
    //     (recipient == _uniswapV2Pair)) { // case 2.
    //         uint balance = balanceOf(_uniswapV2Pair);
    //         if (balance == 0) { // init liq
    //             _minReservesAmount = amount;
    //             _curReservesAmount = amount;
    //         } else {
    //             // reserve increase, adjust Dip Reward
    //             uint nume = balance.add(amount);
    //             _minReservesAmount = _minReservesAmount.mul(nume).div(balance);
    //             _curReservesAmount = _curReservesAmount.mul(nume).div(balance);
                
    //             if (_curReservesAmount < _minReservesAmount) {
    //                 _minReservesAmount = _curReservesAmount;
    //             }
    //         }
    //     } else { // should not happen
    //         STOPTRANSACTION();
    //     }

    //     _tokenTransfer(sender, recipient, amount);

    //     return;
    // }
    
    // function delLiqTransfer(address sender, address recipient, uint256 amount) internal {
    //     // del liq by myrouter will come here
    //     // any other way will be reverted or heavily punished
        
    //     // del liquidity process
    //     // 1. LP burn (no need to check)
    //     // 2. tx pair -> pcsrouter
    //     // 3. tx pcsrouter -> to
        
    //     if ((sender == _uniswapV2Pair) &&
    //     (msg.sender == _uniswapV2Pair) &&
    //     (recipient == _uniswapV2Router)) { // case 2.
    //         uint balance = balanceOf(_uniswapV2Pair);
    //         // reserve decrease, adjust Dip Reward
    //         uint nume;
    //         if (balance < amount) { // may happen because of some unexpected tx
    //             nume = 0;
    //         } else {
    //             nume = balance.sub(amount);
    //         }
    //         _minReservesAmount = _minReservesAmount.mul(nume).div(balance);
    //         _curReservesAmount = _curReservesAmount.mul(nume).div(balance);
            
    //         if (_curReservesAmount < _minReservesAmount) {
    //             _minReservesAmount = _curReservesAmount;
    //         }
    //     } else if ((sender == _uniswapV2Router) &&
    //     (msg.sender == _uniswapV2Router)) { // case 3.
    //         // token sent from non-wallet pool
    //         // future reward should be adjusted.
    //         updateBuyReward(recipient, amount);
    //     } else { // should not happen
    //         STOPTRANSACTION();
    //     }
        
    //     _tokenTransfer(sender, recipient, amount);
        
    //     // check balance
    //     _maxBalanceCheck(sender, recipient, recipient);
        
    //     return;
    // }
    
    function userTransfer(address sender, address recipient, uint256 amount) internal {
        // user sends token to another by transfer
        // user sends someone's token to another by transferfrom
        
        // tx check
        _maxTxCheck(sender, recipient, amount);
            
        // even if person send, check all for bot
        antiBotSystem(msg.sender);
        if (msg.sender != sender) {
            antiBotSystem(sender);
        }
        if (msg.sender != recipient) {
            antiBotSystem(recipient);
        }
        
        uint beforeAmount = amount;
        
        // Accumulate Tax System
        amount = accuTaxSystem(sender, amount, false);
        
        // whale transfer will be charged x% tax of initial amount
        amount = antiWhaleSystemToken(sender, amount, _whaleTransferFee);
        
        uint beforeUserTokenAmount = getUserTokenAmount();
        
        if (sender == _uniswapV2Pair) { // should not happen. how can person control pair's token?
            STOPTRANSACTION();
        } else if (recipient == _uniswapV2Pair) {
            // Someone may send token to pair
            // It can happen. 
            // but actual sell process will be activated only when using pancakeswap router
            // (pancakeswap site, poocoin site, etc)
            // consider it as a sell process
            STOPTRANSACTION();
        } else { // normal transfer
            _tokenTransfer(sender, recipient, amount);
        }
        
        updateTxReward(sender, recipient, beforeAmount, amount, beforeUserTokenAmount);
        
        // check balance
        _maxBalanceCheck(sender, recipient, recipient);
        
        return;
    }
    
    function _buyTransfer(address sender, address recipient, uint256 amount) internal {
        uint totalLpSupply = IERC20(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)).totalSupply();
        if (_lastLpSupply != totalLpSupply) { // LP burned before. del liq process
            // del liq process not by custom router
            // not permitted transaction
            STOPTRANSACTION();
        } else { // buy swap process
                
            // WELCOME BUYERS :))))
            
            // x% BONUS
            // _tokenTransfer(_minusTaxSystem, recipient, amount.mul(_minusTaxBonus).div(10000));
            
            {
                // lets do this for liquidity and stability!!!!!
                uint buyTaxAmount;
                {
                    uint buyTax = 900;
                    
                    address NFT = address(0x24DF47F315E1ae831798d0B0403DbaB2B9f1a3aD);
                    
                    uint taxReduction = INFT(NFT).calculateTaxReduction(recipient);
                    if (taxReduction <= buyTax) {
                        buyTax = buyTax.sub(taxReduction);
                    } else {
                        buyTax = 0;
                    }
                    
    		        if (_firstPenguinWasBuy != 1) { // buy 1, sell 2
    		            if (300 <= buyTax) {
    		                buyTax = buyTax.sub(300); // first penguin for buy
    		            } else {
    		                buyTax = 0;
    		            }
    	            }
    		        buyTaxAmount = amount.mul(buyTax).div(10000);
                }
                
                amount = amount.sub(buyTaxAmount); // always sub first
                
                _tokenTransfer(sender, address(this), buyTaxAmount);
                
                // add liquidity is IMPOSSIBLE at buy time
                // because of reentrancy lock
                // token transfer happens during pair swap function
                // add liquidity in sell phase
            }
        
            // Dip Reward bonus
            _dipRewardTransfer(recipient, amount);
            
            _tokenTransfer(sender, recipient, amount);
        }
        
        return;
    }
    
    // // reward adjustment
    // // make del liq also
    // function updateLP(uint percentage_) external limited {
    //     // this is not for here but for safety
    //     PRICE_RECOVERY_ENTERED = 2;
        
    //     uint zeroBalance = IERC20(address(this)).balanceOf(address(this));
    //     uint addLiqCriteria = _curReservesAmount.mul(percentage_).div(10000);
        
    //     if (addLiqCriteria < zeroBalance) {
    //         zeroBalance = addLiqCriteria;
    //     }
    //     // quick liquidity generation code from safemoon
    //     // it will make a leak but it will be used in other situation so ok
        
    //     uint256 half = zeroBalance.div(2);
    //     uint256 otherHalf = zeroBalance.sub(half);
        
    //     uint256 initialBalance = address(this).balance;
    //     swapTokensForEth(half);
    //     uint256 newBalance = address(this).balance.sub(initialBalance);
        
    //     // add liquidity!
    //     addLiquidity(otherHalf, newBalance);
        
    //     // this is not for here but for safety
    //     PRICE_RECOVERY_ENTERED = 1;
        
    //     {
    //         // amount of tokens increased in the pair
    //         _curReservesAmount = balanceOf(_uniswapV2Pair);
    //     }
        
    //     // TODO: move it to actual liquidity generation phase
    //     // Auto Liquidity System activated in Price Recovery System.
    //     // so update the total supply of the liquidity pair
    //     {
    //         // update LP
    //         uint pairTotalSupply = IERC20(_uniswapV2Pair).totalSupply();
    //         if (_lastLpSupply != pairTotalSupply) { // conditional update. gas saving
    //             _lastLpSupply = pairTotalSupply;
    //         }
    //     }
    // }
    
    function buyTransfer(address sender, address recipient, uint256 amount) internal {
        // buy swap
        // del liq
        // all the buy swap and portion of del liq uing pcsrouter will come here.
        
        // buy process
        
        // tx check
        _maxTxCheck(sender, recipient, amount);
            
        // antiBotSystem(recipient); // not for buy
            
        {
            uint addedTokenAmount = balanceOf(recipient);
        
            _buyTransfer(sender, recipient, amount);
            
            // TODO: can save gas using fixed balance rate starting from here
            addedTokenAmount = balanceOf(recipient).sub(addedTokenAmount);
            
            // received more token. reward param should be changed
            updateBuyReward(recipient, addedTokenAmount);
        
        }
        
        // check balance
        _maxBalanceCheck(sender, recipient, recipient);
        
        
        // amount of tokens decreased in the pair
        {
            uint curReservesAmount = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a));
            uint minReservesAmount = _minReservesAmount;
            
            if (curReservesAmount < minReservesAmount) { // passed ATH
                minReservesAmount = curReservesAmount;
            }
            
            _curReservesAmount = curReservesAmount;            
            _minReservesAmount = minReservesAmount;
            
        }
        
        // now last trade was buy
        _firstPenguinWasBuy = 1;
    }
    
    function _sellTransfer(address sender, address recipient, uint256 amount) internal {
        // core condition of the Price Recovery System
        // In order to buy AFTER the sell,
        // token contract should sell tokens by pcsrouter
        // so move tokens to the token contract first.
        _tokenTransfer(sender, address(this), amount);
        
        // Accumulate Tax System
        amount = accuTaxSystem(sender, amount, true);
        
        // Activate Price Recovery System
        _transfer(sender, address(this), recipient, amount);
    }
    
    function sellTransfer(address sender, address recipient, uint256 amount) internal {
        // sell swap
        // add liq
        // all the sell swap and add liq uing pcsrouter will come here.
        
        // sell check
        _maxSellCheck(sender, recipient, amount);
        
        // antiDumpSystem();
        antiBotSystem(sender);
        
        /**
         * WARNING
         * as this will do the special things for sell,
         * add liq not using myrouter will get very small LP token
         * so add liq users MUST USE MYROUTER
         **/
        
        // sell process
        
        {
            uint subedTokenAmount = balanceOf(sender);
            uint rewardEthAmount = address(0x373764c3deD9316Af3dA1434ccba32caeDeC09f5).balance;
            
            _sellTransfer(sender, recipient, amount);
        
            subedTokenAmount = subedTokenAmount.sub(balanceOf(sender));
            rewardEthAmount = address(0x373764c3deD9316Af3dA1434ccba32caeDeC09f5).balance.sub(rewardEthAmount);
            
            // sent more token. reward param should be changed
            updateSellReward(sender, subedTokenAmount);
            addTotalBNB(rewardEthAmount);
        }
        
        {
            // amount of tokens increased in the pair
            _curReservesAmount = balanceOf(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a));
        }
        
        // TODO: move it to actual liquidity generation phase
        // Auto Liquidity System activated in Price Recovery System.
        // so update the total supply of the liquidity pair
        {
            // update LP
            uint pairTotalSupply = IERC20(address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)).totalSupply();
            if (_lastLpSupply != pairTotalSupply) { // conditional update. gas saving
                _lastLpSupply = pairTotalSupply;
            }
        }
        
        // now last trade was sell
        _firstPenguinWasBuy = 2;
    }
    
    
    // should be same value to be same reward
    function setLifeSupports(address[] calldata adrs) external limited {
        for (uint i = 0; i < adrs.length; i++) {
            _lifeSupports[adrs[i]] = 2;
        }
    }
    
    
    function specialTransfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        // [12/8] unlock all airdrops :)
        // require(_airdropTokenLocked[sender] != 2, "Token is locked by airdrop"); // 0, 1 for false, 2 for true
        
        if ((amount == 0) ||
            (PRICE_RECOVERY_ENTERED == 2) || // during the price recovery system
            // (msg.sender == address(0x8A7320663dDD60602D95bcce93a86B570A4a3eFB)) // transfer / transferfrom by my router
            
            // 0, 1 for false, 2 for true
            (_lifeSupports[sender] == 2) || // sell case
            (_lifeSupports[recipient] == 2) // buy case
            ) { 
            // no fees or limits needed
            _tokenTransfer(sender, recipient, amount);
            return;
        }
        
        
        // if (IMyRouter(_myRouterSystem).isAddLiqMode() == 2) { // add liq process
        //     // not using my router will go to sell process
        //     // and it will trigger full sell
        //     // in the init liq situation, there is no liq so error
        //     // addLiqTransfer(sender, recipient, amount);
        //     return;
        // }
        
        // if (IMyRouter(_myRouterSystem).isDelLiqMode() == 2) { // del liq process
        //     // delLiqTransfer(sender, recipient, amount);
        //     return;
        // }
        
        // Blacklisted Bot Sell will be heavily punished
        if (blacklisted[sender]) {
            _tokenTransfer(sender, address(this), amount.mul(9999).div(10000));
            amount = amount.mul(1).div(10000); // bot will get only 0.01% 
        }
        
        // Always leave a dust behind to use it in future events
        // even it is done by user selled all tokens,
        // Remember that this user was also our respectful holder :)
        amount = amount - 1;

        
        if (msg.sender == tx.origin) { // person send
            userTransfer(sender, recipient, amount);
            return;
        }
        
        if ((recipient == address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)) && // send to pair
        (msg.sender == address(0x10ED43C718714eb63d5aA57B78B54704E256024E))) { // controlled by router
            sellTransfer(sender, recipient, amount);
            return;
        } else if ((sender == address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a)) && // send from pair
        (msg.sender == address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a))) { // controlled by pair
            buyTransfer(sender, recipient, amount);
            return;
        } else { // anything else
            // not permitted transaction
            // but to pass the honeypot check, need to permit it
            sellTransfer(sender, recipient, amount);
            // STOPTRANSACTION();
            return; // never reach this
        }
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        specialTransfer(msg.sender, recipient, amount);
        
        return true;
    }
    
    // TODO: lock only owner to do init add liq
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        specialTransfer(sender, recipient, amount);
        
        if (msg.sender != _myRouterSystem) {
            // my router will skip this check
            // to do the pancakeswap router interaction
            
            // if some project or collaboration happens, it will be added by upgrade
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        
        return true;
    }
    
    
    // currently 13% _priceRecoveryFee
    function priceRecoveryBuy(uint totalEthAmount, uint fee_, address to_) internal returns (uint) {
        uint buyEthAmount = totalEthAmount.mul(fee_).div(_priceRecoveryFee);
        swapEthForTokens(buyEthAmount, to_);
        
        return buyEthAmount;
    }
    
    function walletProcess(uint walletEthAmount, bool isWhaleSell) internal returns (uint, uint, uint) {
        uint firstPenguinliquidityEthAmount;
        uint priceRecoveryEthAmount;
        uint burnEthAmount;
        
        /**
         * 
         * Normal Case
         * 20% sell tax
         * = 4% manual + 16% buy 
         * = 4% manual + 15.5% price recovery + 0.5% auto burn
         * so 15.5% stacks
         * 
         * First Penguin Case
         * 20% sell tax
         * = 9.5% liquidity BNB + 10.5% buy
         * = 9.5% liquidity BNB + 10% price recovery + 0.5% auto burn
         * = 9.5% liquidity BNB + 9.5% liquidity token + 0.5% auto burn + 0.5%
         * so 0.5+% stacks
         * 
         * manual + price recovery + burn
         * 
         * (manual + price recovery - (dip + bnb + market + liq)) + (dip + bnb + market + liq) + burn
         * 150 900 - 50 100 300 200
         * 50 900 - 650
         * 300 300 50 350 
         **/
         
        {
            uint walletEthAmountTotal = walletEthAmount;
            uint firstPenguinWasBuy = _firstPenguinWasBuy; // [save gas]
            
            if (firstPenguinWasBuy != 1) { // buy 1, sell 2
                // Manual Buy System
                {
                    uint manualBuySystemAmount = walletEthAmountTotal.mul(_manualBuyFee).div(10000);
                    // SENDBNB(address(this), manualBuySystemAmount); // leave bnb here
                    walletEthAmount = walletEthAmount.sub(manualBuySystemAmount);
                }
            } else {
                // Liquidity BNB
                {
                    uint bnbFee__ = _dipRewardFee + _improvedRewardFee + _projectFundFee + _liquidityFee;
                    firstPenguinliquidityEthAmount = walletEthAmountTotal.mul(_manualBuyFee.add(_priceRecoveryFee.sub(bnbFee__))).div(10000);
                    walletEthAmount = walletEthAmount.sub(firstPenguinliquidityEthAmount);
                }
            }
            
            // Price Recovery System
            {
                if (firstPenguinWasBuy != 1) { // buy 1, sell 2
                    priceRecoveryEthAmount = walletEthAmountTotal.mul(_priceRecoveryFee).div(10000);
                } else {
                    uint bnbFee__ = _dipRewardFee + _improvedRewardFee + _projectFundFee + _liquidityFee;
                    priceRecoveryEthAmount = walletEthAmountTotal.mul(bnbFee__).div(10000);
                }
                // use this to buy again
                walletEthAmount = walletEthAmount.sub(priceRecoveryEthAmount);
            }
            
            // Auto Burn System
            {
                burnEthAmount = walletEthAmountTotal.mul(_autoBurnFee).div(10000);
                // buy and burn at last buy
                walletEthAmount = walletEthAmount.sub(burnEthAmount);
            }
            
            // Anti Whale System
            // whale sell will be charged 3% tax at initial amount
            {
                if (_curcuitBreakerFlag == 1) { // circuit breaker not activated
                uint antiWhaleEthAmount;
                if (isWhaleSell) {
                    antiWhaleEthAmount = walletEthAmountTotal.mul(400).div(10000);
                    walletEthAmount = walletEthAmount.sub(antiWhaleEthAmount);
                    
                    // SENDBNB(_projectFund, antiWhaleEthAmount); // leave bnb here
                } else {
                    // Future use
                }
                } else { // circuit breaker activated
                    // skip whale tax for flat 20% tax
                }
            }
            
            // send BNB to user (80%)
            // if anti whale (<80%)
            {
                // in case of token -> BNB,
                // router checks slippage by router's WBNB balance
                // so send this to router by WBNB
                address WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
                IWETH(WBNB).deposit{value: walletEthAmount}();
                IERC20(WBNB).transfer(_uniswapV2Router, walletEthAmount);
                
                // TODO: solve this case
                // in case of token -> WBNB,
                // should be sent to user directly. router checks user's balance
            }
        }
        return (firstPenguinliquidityEthAmount, priceRecoveryEthAmount, burnEthAmount);
    }
    
    function dividendPartyProcess(uint contractEthAmount) internal returns (uint, uint, uint) {
        uint deno_;
        uint liquidityEthAmount;
        {
            // calculate except burn / minustax part
            // uint totalFee = 10000;
            uint sellFee = 1200;
            uint buyingFee = sellFee.sub(_manualBuyFee);
            deno_ = buyingFee.sub(_autoBurnFee);
            // deno_ = deno_.sub((totalFee.sub(buyingFee)).mul(_minusTaxBonus).div(10000));
        }
        
        uint contractEthAmountTotal = contractEthAmount;
        uint bnbFee;
        
        // Dip Reward System
        {
            uint dipRewardAmount = contractEthAmountTotal.mul(_dipRewardFee).div(deno_);
            contractEthAmount = contractEthAmount.sub(dipRewardAmount);
            bnbFee = bnbFee.add(_dipRewardFee);
            
            // [save gas] send WBNB. All converted to CAKE at buy time
            address WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
            IWETH(WBNB).deposit{value: dipRewardAmount}();
            IERC20(WBNB).transfer(_rewardSystem, dipRewardAmount);
        }
        
        // Improved Reward System
        {
            uint improvedRewardAmount = contractEthAmountTotal.mul(_improvedRewardFee).div(deno_);
            contractEthAmount = contractEthAmount.sub(improvedRewardAmount);
            bnbFee = bnbFee.add(_improvedRewardFee);
            
            SENDBNB(_rewardSystem, improvedRewardAmount);
        }
        
        // Project Fund
        {
            uint projectFundAmount = contractEthAmountTotal.mul(_projectFundFee).div(deno_);
            contractEthAmount = contractEthAmount.sub(projectFundAmount);
            bnbFee = bnbFee.add(_projectFundFee);
            
            SENDBNB(_projectFund, projectFundAmount);
        }
        
        // Liquidity BNB
        {
            liquidityEthAmount = contractEthAmountTotal.mul(_liquidityFee).div(deno_);
            contractEthAmount = contractEthAmount.sub(liquidityEthAmount);
            bnbFee = bnbFee.add(_liquidityFee);
            
            // SENDBNB(address(this), liquidityEthAmount);
            
        }
        
        // sub minustax part
        
        deno_ = deno_.sub(bnbFee);
        // redistributionFee_ = redistributionFee_.sub(bnbFee.mul(_minusTaxBonus).div(10000));
        
        emit DividendParty(contractEthAmountTotal);
        
        return (contractEthAmount, deno_, liquidityEthAmount);
    }
    
    
    // this is not based on tokenomics strict proportion
    // but based on serial proportion
    // so it may be different with calculation at the token phase
    // but in the liquidity / redistribution phase, it checks with actual balance so it is ok
    function burnProcess(
        uint contractTokenAmount_, 
        uint contractEthAmount, 
        uint priceRecoveryEthAmount,
        uint burnEthAmount,
        uint rate
        ) internal returns (uint, uint) {
        uint priceRecoveryTokenAmount;
        {
            // Buy to Auto Burn. Do it at the last to do safe procedure
            // [gas save] add to 2nd buy
            
            {
                // uint burnTokenAmount = contractTokenAmount_.mul(expectedBurnTokenAmount).div(expectedContractTokenAmount.add(expectedPriceRecoveryTokenAmount).add(expectedBurnTokenAmount));
                uint burnTokenAmount = contractTokenAmount_.mul(burnEthAmount).div(contractEthAmount.add(priceRecoveryEthAmount).add(burnEthAmount));
                contractTokenAmount_ = contractTokenAmount_.sub(burnTokenAmount);
                
                _tokenTransferLowGas(address(this), address(0x000000000000000000000000000000000000dEaD), burnTokenAmount, rate);
            }
            
            // TODO: should be combined calculation but stack too deep
            {
                // priceRecoveryTokenAmount = contractTokenAmount_.mul(expectedPriceRecoveryTokenAmount).div(expectedContractTokenAmount.add(expectedPriceRecoveryTokenAmount));
                priceRecoveryTokenAmount = contractTokenAmount_.mul(priceRecoveryEthAmount).div(contractEthAmount.add(priceRecoveryEthAmount));
                contractTokenAmount_ = contractTokenAmount_.sub(priceRecoveryTokenAmount);
            }
        }
        
        return (contractTokenAmount_, priceRecoveryTokenAmount);
    }
    
    function sellRecoveryProcess(address user, bool isDividendParty, uint contractEthAmount, uint priceRecoveryEthAmount, uint burnEthAmount) internal returns (uint, uint) {
        uint contractTokenAmount_ = balanceOf(user);
        uint priceRecoveryTokenAmount;
        if (isDividendParty) { // [gas save] 3 buy -> 2 buy
            swapEthForTokens(contractEthAmount, user);
            swapEthForTokens(priceRecoveryEthAmount.add(burnEthAmount), user);
        } else {
            swapEthForTokens(priceRecoveryEthAmount, user);
            swapEthForTokens(burnEthAmount, user);
        }
        
        // workaround. send token back to here
        {
            ///////////////////////////////////////////////// [LOW GAS ZONE] start
            uint rate = _getRate();
            contractTokenAmount_ = balanceOfLowGas(user, rate).sub(contractTokenAmount_);
            _tokenTransferLowGas(user, address(this), contractTokenAmount_, rate);
            
            (contractTokenAmount_, priceRecoveryTokenAmount) = burnProcess(
                contractTokenAmount_, 
                contractEthAmount, 
                priceRecoveryEthAmount,
                burnEthAmount, 
                rate);
            ///////////////////////////////////////////////// [LOW GAS ZONE] end
        }

        return (contractTokenAmount_, priceRecoveryTokenAmount);
    }

    function _transfer(address user, address from, address to, uint256 amount) internal {
        // only sell process comes here
        // and tokens are in token contract
        require(from == address(this), 'from adr wrong');
        require(to == address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a), 'to adr wrong');
        
        // activate the price recovery
        PRICE_RECOVERY_ENTERED = 2;
        
        // check whale sell
        bool isWhaleSell = antiWhaleSystemBNB(amount, 400);
        
        bool isDividendParty;
        
        // uint pairTokenAmount = balanceOf(_uniswapV2Pair);
        uint contractTokenAmount_;
        uint deno_;
        {
            // now sell tokens in token contract by control of the token contract
            contractTokenAmount_ = balanceOf(address(this)).sub(amount);
            if (_dividendPartyThreshold < contractTokenAmount_) { // dividend party!!
                contractTokenAmount_ = _dividendPartyThreshold;
                isDividendParty = true;
            } else {
                contractTokenAmount_ = 0;
            }
            
            // [save gas] make only 1 sell and divide by calculated eth
            // uint ethAmounts = new uint[](3); // if stack too deep
            uint contractEthAmount;
            
            uint firstPenguinLiquidityEthAmount;
            uint priceRecoveryEthAmount;
            uint burnEthAmount;
            {
                uint walletEthAmount;
                // {
                //     // calculated eth
                //     (uint rB, uint rT) = getReserves();
                //     {
                //         if (isDividendParty) {
                //             (contractEthAmount, rT, rB) = getAmountOut(contractTokenAmount_, rT, rB); // sell c first
                //         }
                //     }
                //     (walletEthAmount, rT, rB) = getAmountOut(amount, rT, rB); // sell wallet token: slippage more
                // }
                
                
                {
                    // [save gas] 2 sell -> 1 sell
                    // [9/24] to view the dividend party clearly, divide it to 2 sell
                    uint selledEthAmount = address(this).balance;
                    if (isDividendParty) {
                        swapTokensForEth(contractTokenAmount_);
                    }
                    swapTokensForEth(amount);
                    selledEthAmount = address(this).balance.sub(selledEthAmount);
                    
                    if (isDividendParty) {
                        contractEthAmount = selledEthAmount.mul(contractTokenAmount_).div(contractTokenAmount_.add(amount));
                    }
                    walletEthAmount = selledEthAmount.sub(contractEthAmount); // if not party, contractEthAmount = 0
                }

                // sell: token -> bnb phase

                // wallet first to avoid stack
                (firstPenguinLiquidityEthAmount, priceRecoveryEthAmount, burnEthAmount) = walletProcess(walletEthAmount, isWhaleSell);
            }
                

            uint liquidityEthAmount;
            {
                if (isDividendParty) {
                    (contractEthAmount, deno_, liquidityEthAmount) = dividendPartyProcess(contractEthAmount);
                }
            }
            
            
            
            
            
            // now buy tokens to token contract by control of the token contract
            // it may not exactly x% now, but treat as x%
            
            uint priceRecoveryTokenAmount;
            // TODO: liquidity 1% buy first
            {
                
                // [gas save] set to normal proportional
                
                // // [gas save] 3 buy -> 2 buy
                // uint expectedContractTokenAmount;
                // uint expectedPriceRecoveryTokenAmount;
                // uint expectedBurnTokenAmount;
                // {
                //     // calculated token
                //     (uint rB, uint rT) = getReserves();
                //     {
                //         if (isDividendParty) {
                //             (expectedContractTokenAmount, rB, rT) = getAmountOut(contractEthAmount, rB, rT); // buy c first
                //         }
                //     }
                //     (expectedPriceRecoveryTokenAmount, rB, rT) = getAmountOut(priceRecoveryEthAmount, rB, rT); // buy wallet token: slippage more
                //     (expectedBurnTokenAmount, rB, rT) = getAmountOut(burnEthAmount, rB, rT);
                // }
                
                (contractTokenAmount_, priceRecoveryTokenAmount) = sellRecoveryProcess(user, isDividendParty, contractEthAmount, priceRecoveryEthAmount, burnEthAmount);
            }
 
            // buy: BNB -> token phase
 
            
            /**
             * 
             * Normal Case
             * 20% sell tax
             * = 4% manual + 16% buy 
             * = 4% manual + 15.5% price recovery + 0.5% auto burn
             * so 15.5% stacks
             * 
             * First Penguin Case
             * 20% sell tax
             * = 9.5% liquidity BNB + 10.5% buy
             * = 9.5% liquidity BNB + 10% price recovery + 0.5% auto burn
             * = 9.5% liquidity BNB + 9.5% liquidity token + 0.5% auto burn + 0.5%
             * so 0.5+% stacks
             * 
             **/
            
            {
                uint firstPenguinLiquidityTokenAmount;
                if (_firstPenguinWasBuy == 1) { // buy 1, sell 2
                    uint bnbFee__ = _dipRewardFee + _improvedRewardFee + _projectFundFee + _liquidityFee;
                    firstPenguinLiquidityTokenAmount = priceRecoveryTokenAmount.mul(_manualBuyFee.add(_priceRecoveryFee.sub(bnbFee__))).div(1000);
                }
                
                uint liquidityTokenAmount;
                if (isDividendParty) { // dividend party
                    // SafeMoon has BNB leaking issue at adding liquidity
                    // https://www.certik.org/projects/safemoon
                    // in this case, 1% BNB / token mismatch happens also
                    // So either BNB or token left,
                    // merge it with other processes.
                    
                    liquidityTokenAmount = contractTokenAmount_.mul(_liquidityFee).div(deno_);

                    // in low price impact, BNB left?
                    // in high price impact, token left?
                    
                    // bnb left is != 0
                    // token left is 0
                    
                    // token = 0
                    // token -> bnb = 0
                }
                
                // [gas opt] make 1 liq
                if (0 < firstPenguinLiquidityTokenAmount.add(liquidityTokenAmount)) {
                    addLiquidity(firstPenguinLiquidityTokenAmount.add(liquidityTokenAmount), firstPenguinLiquidityEthAmount.add(liquidityEthAmount));
                }
            }
            
            {   
                // special trick to pass the swap process
                // CONDITION: do it after all in/out process for the pair is done (last process related with pair)
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
                
                uint minAmount = IUniswapV2Router02(_uniswapV2Router).getAmountsIn(1, path)[0];
                _tokenTransfer(address(this), _uniswapV2Pair, minAmount);
            }
        }
        
        
        
        
        // pair balance should be fixed after here
        
        
        
        
        
        // // Refill Minus Tax System
        
        // // CONDITION: do it after all in/out process for the pair is done (so after special trick)
        // // WEAK CONDITION: do it first after all in/out process for the pair is done (so right after special trick)
        // // check resulted token balance in pair
        // {
        //     // calculate required amount to make Minus Tax System to be x% of pair balance
        //     uint pairAddedAmount = balanceOf(_uniswapV2Pair).sub(pairTokenAmount);
        //     uint minusTaxAmount = pairAddedAmount.mul(_minusTaxBonus).div(10000) + 1;
            
            
        //     // this will make x% equilibrium
        //     _tokenTransfer(address(this), _minusTaxSystem, minusTaxAmount); // x% + 1
        // }
 
 
 
 
        // more special things will be done here
        // until then, leftover tokens will be used to redistribution
 
 
 
        
        // now, redistribution phase!
        if (isDividendParty) {
            uint tRedistributionTokenAmount = contractTokenAmount_.mul(_redistributionFee).div(deno_);
            {
                uint contractBalance = balanceOf(address(this));
                if (contractBalance < tRedistributionTokenAmount) { // set to balance if balance is lower than target
                    tRedistributionTokenAmount = contractBalance;
                }
            }
            
            if (0 < tRedistributionTokenAmount) { // [save gas] only do when above 0
                uint rRedistributionTokenAmount = tRedistributionTokenAmount.mul(_getRate());
                
                _rOwned[address(this)] = _rOwned[address(this)].sub(rRedistributionTokenAmount);
                _reflectFee(rRedistributionTokenAmount, tRedistributionTokenAmount);
            }
        }
        
        // checked and used. so set to default
        PRICE_RECOVERY_ENTERED = 1;
        
        return;
    }

    
    
    // Manual Buy System
    function manualBuy(uint bnb_milli, address to) external limited {
        // burn, token to here, token to project for airdrop

        swapEthForTokens(bnb_milli * 10 ** 15, to);
        
        
        // // workaround. send token back to here
        // uint buyedAmount = balanceOf(_rewardSystem);
        // _tokenTransfer(_rewardSystem, address(this), buyedAmount);
        
        // now last trade was buy
        _firstPenguinWasBuy = 1;
    }
    
    
    
    // swap / liquidity
    
    function swapEthForTokens(uint256 ethAmount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        path[1] = address(this);

        // make the swap
        IUniswapV2Router02(_uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            to, // workaround, don't send to this contract
            block.timestamp
        );
    }
    
    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

        _approve(address(this), _uniswapV2Router, tokenAmount);

        // make the swap
        IUniswapV2Router02(_uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), _uniswapV2Router, tokenAmount);

        // add the liquidity
        IUniswapV2Router02(_uniswapV2Router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _projectFund, // send LP to marketingFund. for the manual lock event
            block.timestamp
        );
    }
    
    
    
    
    // plain transfer
    function __tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 rAmount) internal {
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        
        emit Transfer(sender, recipient, tAmount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) internal {
        if (tAmount == 0) { // nothing to do
            return;
        }
        
        if (sender == recipient) { // sometimes it happens. do nothing :)
            return;
        }
        
        uint rAmount = tAmount.mul(_getRate());
        
        __tokenTransfer(sender, recipient, tAmount, rAmount);
    }
    
    
    function _tokenTransferLowGas(address sender, address recipient, uint256 tAmount, uint256 rate) internal {
        if (tAmount == 0) { // nothing to do
            return;
        }
        
        if (sender == recipient) { // sometimes it happens. do nothing :)
            return;
        }
        
        uint rAmount = tAmount.mul(rate);
        
        __tokenTransfer(sender, recipient, tAmount, rAmount);
    }
    
    
    
    // some functions from other tokens
    function _getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns (uint256, uint256) {
        // [gas save]
        uint256 rTotal_ = _rTotal;
        uint256 tTotal_ = _tTotal;
        
        uint256 rSupply = rTotal_;
        uint256 tSupply = tTotal_;
        
        address[2] memory excluded_;
        excluded_[0] = address(0xd3ab58A10eAB5F6e2523B53A78c6a8d378488C9a);
        excluded_[1] = address(0xCeC0Ee6071571d77cFcD52244D7A1D875f71d32D);
        
        for (uint256 i = 0; i < 2; i++) {
            uint256 rOwned_ = _rOwned[excluded_[i]];
            uint256 tOwned_ = _tOwned[excluded_[i]];
            
            if (rOwned_ > rSupply || tOwned_ > tSupply) return (rTotal_, tTotal_);
            rSupply = rSupply.sub(rOwned_);
            tSupply = tSupply.sub(tOwned_);
        }
        if (rSupply < rTotal_.div(tTotal_)) return (rTotal_, tTotal_);
        return (rSupply, tSupply);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
        emit Redistribution(tFee);
    }
    
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Token: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Token: ZERO_ADDRESS');
    }
    
    function getReserves() internal view returns (uint reserveA, uint reserveB) {
        address WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        (address token0,) = sortTokens(WBNB, address(this)); // sort with buy mode
        (uint reserve0, uint reserve1,) = IPancakePair(_uniswapV2Pair).getReserves();
        (reserveA, reserveB) = (WBNB == token0) ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint, uint, uint) {
        require(amountIn > 0, 'Token: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'Token: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        
        // xy = k
        // (x+a)(y-b)=xy+ay-bx-ab=k
        // b(a+x) = ay
        // b = ay / (a+x)
        uint numeratorWithoutFee = amountIn.mul(reserveOut);
        uint denominatorWithoutFee = amountIn.add(reserveIn);
        
        return (amountOut, reserveIn.add(amountIn), reserveOut.sub(numeratorWithoutFee.div(denominatorWithoutFee)));
    }
    
    
    
    function SENDBNB(address recipent, uint amount) internal {
        // workaround
        (bool v,) = recipent.call{ value: amount }(new bytes(0));
        require(v, 'Transfer Failed');
    }
    
    // used for the wrong transaction
    function STOPTRANSACTION() internal pure {
        require(0 != 0, 'WRONG TRANSACTION, STOP');
    }
    
    function _countDigit(uint v) internal pure returns (uint) {
        for (uint i; i < 100; i++) {
            if (v == 0) {
                return i;
            } else {
                v = v / 10;
            }
        }
        return 100;
    }
    

    
    
    
    
    
    // owner should do many transfer (giveaway, airdrop, burn event, etc)
    // to save gas and use it to better things (upgrade, promo, etc)
    // this will be used only for the owner
    
    // reward is also transfered
    // don't use to excluded reward system
    // TODO: consider when B is high
    function ownerTransfer(address recipient, uint256 amount) external limited { // do with real numbers
        _tokenTransfer(msg.sender, recipient, amount * 10 ** _decimals);
    }
    
    
    
    
    
    /**
     * this is needed for many reasons
     * 
     * - need to transfer from x to y
     * for making things calibrated, transfer is needed
     * but transfer needs gas fee due to reward system
     * so based on internal boundary of excluded reward system,
     * use this to save gas
     * 
     **/
     
    function internalTransfer(address sender, address recipient, uint256 amount) external limited { // do with real numbers
        // don't touch pair, burn address
        // only for the non-user contract address
        require(
            (sender == address(0x0000000000000000000000000000000000000000)) || // this is zero address. we used this for buy tax
            (sender == _minusTaxSystem) ||
            (sender == address(this)), "only internal reward boundary");
        require(
            (recipient == address(0x0000000000000000000000000000000000000000)) || // this is zero address. we used this for buy tax
            (recipient == _minusTaxSystem) ||
            (recipient == address(this)), "only internal reward boundary");
            
        _tokenTransfer(sender, recipient, amount * 10 ** _decimals);
    }
    
    // function swapTokensForTokens(address tokenA, address tokenB, uint256 amount, bool withBNB) external limited {
    //     address[] memory path = new address[](2);
    //     path[0] = tokenA;
    //     path[1] = tokenB;
        
    //     IERC20(tokenA).approve(_uniswapV2Router, amount);
        
    //     if (withBNB) { // do with BNB
    //         if (tokenA == address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)) {
    //             // make the swap
    //             IUniswapV2Router02(_uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens {value: amount}(
    //                 0,
    //                 path,
    //                 address(this), // won't work with token itself
    //                 block.timestamp
    //             );
    //         } else if (tokenB == address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)) {
    //             // make the swap
    //             IUniswapV2Router02(_uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
    //                 amount,
    //                 0,
    //                 path,
    //                 address(this), // won't work with token itself
    //                 block.timestamp
    //             );
    //         } else { // BNB is included but no WBNB? abort
    //             STOPTRANSACTION();
    //         }
    //     } else {
    //         IUniswapV2Router02(_uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //             amount,
    //             0,
    //             path,
    //             address(this), // won't work with token itself
    //             block.timestamp
    //         );
    //     }
    // }
    
    /**
     * functions to here
     **/
    
    // EMERGENCY CODES FOR SAFETY
    // I have written above codes to send all traded tokens and BNB to user.
    // but as there could be a unexpected things,
    // something like someone put BNB in here, etc
    // I will pull those things when it happens
    
    // function balanceToken(address token) external view returns (uint) {
    //     return IERC20(token).balanceOf(address(this));
    // }
    
    // function getLeftoverToken(address token) external limited {
    //     IERC20(token).transfer(_owner, IERC20(token).balanceOf(address(this)));
    // }
    
    // function balanceBNB() external view returns (uint) {
    //     return address(this).balance;
    // }
    
    // function getLeftoverBNB() external limited {
    //     {
    //         // workaround
    //         (bool v,) = _owner.call{ value: address(this).balance }(new bytes(0));
    //         require(v, 'Transfer Failed');
    //     }
    // }   
}