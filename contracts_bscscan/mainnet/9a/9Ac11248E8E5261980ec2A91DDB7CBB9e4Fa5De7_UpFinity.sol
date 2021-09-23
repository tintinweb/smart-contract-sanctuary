/***
 * All systems here is invented by AllCoinLab
 * https://github.com/AllCoinLab
 * 
 * For brief info: https://AllCoinLab.github.io
 * For detailed info: https://github.com/ALlCoinLab/UpFinity (working)
 * 
 * 
 * Written in easy code to for easy verificiation by the investors.
 * Also written with more conditions in order not to make mistake + maintain code easily.
 * Those doesn't cost gas much so this is way better than the simple / short code.
 * Used gas optimization if needed.
 * 
 ***/


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/proxy/utils/Initializable.sol 
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
    function approveWBNBToken() external;
    function approveRewardToken() external;
}
/**
 * interfaces to here
 **/
 
contract UpFinity is Initializable {
    using SafeMath for uint256;
    
    // Upgradable Contract Test
    uint public _uptest;
    
    // My Basic Variables
    address public _owner;
    
    address public _token;
    address public _myRouterSystem;
    address public _minusTaxSystem;
    address public _rewardSystem;
    address public _projectFund;
    address public _rewardToken;
    
    /*
     * vars and events from here
     */
    
    
    // Basic Variables
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    address public _uniswapV2Router;
    address public _uniswapV2Pair;
    
    
    // Redistribution Variables
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private MAX;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    
    // Fee Variables
    uint public _liquidityFee;
    uint public _projectFundFee;
    uint public _manualBuyFee;
    
    uint public _minusTaxFee;
    
    uint public _autoBurnFee;
    
    // Price Recovery System Variables
    uint public _priceRecoveryFee;
    uint private PRICE_RECOVERY_ENTERED;
    
    
    // Anti Bot System Variables
    mapping (address => uint256) public _buySellTimer;
    uint public _buySellTimeDuration;
    
    // Anti Whale System Variables
    uint public _whaleRate;
    uint public _whaleTransferFee;
    uint public _whaleSellFee;
    
    
    // Dip Reward System Variables
    uint public _dipRewardFee;
    
    uint public _minReservesAmount;
    uint public _curReservesAmount;
    
    
    // Improved Reward System Variables
    uint public _improvedRewardFee;
    
    uint public totalBNB;
    uint public addedTotalBNB;
    mapping (address => uint) public adjustBuyBNB;
    mapping (address => uint) public adjustSellBNB;
    
    // LP manage System Variables
    uint public _lastLpSupply;
    
    // Blacklists
    mapping (address => bool) public blacklisted;
    
    // Dividend Party
    uint public _dividendPartyPortion;
    
    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event Redistribution(uint256 value);
    
    event WhaleTransaction(uint256 amount, uint256 tax);
    
    /**
     * vars and events to here
     **/
     
    fallback() external payable {}
    receive() external payable {}
    
    modifier onlyOwner {
        require(_owner == msg.sender, 'Only Owner can do this!!!!!!');
        _;
    }
    
    function initialize(address owner_) public initializer {
        _owner = owner_;
        /**
         * inits from here
         **/
        
        _name = "UpFinity";
        _symbol = "UPF";
        _decimals = 18;
        
        MAX = ~uint256(0);
        _tTotal = 10 * 10**12 * 10**_decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        
        
        
        uint sellFee = 2000;
        
        
        // before price recovery fee
        _liquidityFee = 100;
        _improvedRewardFee = 300;
        _projectFundFee = 300;
        _dipRewardFee = 100;
        _manualBuyFee = 400;
        _autoBurnFee = 50;
        
        _priceRecoveryFee = sellFee
        .sub(_manualBuyFee)
        .sub(_autoBurnFee);
        
        
        // check with balance increase, minimum 4.2%
        // _minusTaxFee
        // redistribute with leftovers, minimum 2.9%
        // _redistributionFee;
        
        PRICE_RECOVERY_ENTERED = 1;
        
        _buySellTimeDuration = 5; // TODO: change it to 60

        // Anti Whale System
        // denominator = 10 ** 6
        // whale transfer / sell amount 1% of the token amount in the liquidity pool
        // so default is 10 ** 4
        // whale transfer will be charged 1% tax of initial amount
        // so default is 10 ** 4
        // whale sell will be charged 3% tax of initial amount
        // so default is 3 * 10 ** 4
        _whaleRate = 10 ** 4;
        _whaleTransferFee = 10 ** 4;
        _whaleSellFee = 3 * 10 ** 4;
        
        // Dividend Party
        _dividendPartyPortion = 500;
        
        
        /**
         * inits to here
         **/
         
    }
    
    function setUptest(uint uptest_) external {
        _uptest = uptest_;
    }

    function setToken(address token_) external onlyOwner {
        _token = token_;
    }
    function setMyRouterSystem(address myRouterSystem_) external onlyOwner {
        _myRouterSystem = myRouterSystem_;
    }  
    function setMinusTaxSystem(address minusTaxSystem_) external onlyOwner {
        _minusTaxSystem = minusTaxSystem_;
    }
    function setRewardSystem(address rewardSystem_) external onlyOwner {
        _rewardSystem = rewardSystem_;
    }
    function setMarketingFund(address marketingFund_) external onlyOwner {
        _projectFund = marketingFund_;
    }
    function setRewardToken(address rewardToken_) external onlyOwner {
        _rewardToken = rewardToken_;
    }
    
    /**
     * functions from here
     **/
    
    function setDividendPartyPortion(uint dividendPartyPortion_) external onlyOwner {
        _dividendPartyPortion = dividendPartyPortion_;
    }
    
    function setBuySellTimeDuration(uint buySellTimeDuration_) external onlyOwner {
      _buySellTimeDuration = buySellTimeDuration_;
    }
    
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
         
    // inits
    function runInit() external onlyOwner {
        require(_uniswapV2Pair == address(0), 'Already Initialized');
        
        // Initialize
        _rOwned[_owner] = _rTotal;
        emit Transfer(address(0), _owner, _tTotal);
  
        // 50% burn
        _tokenTransfer(_owner, address(0x000000000000000000000000000000000000dEaD), _tTotal.mul(5000).div(10000));
        
        // 40% liquidity will be done after init
        // 2% Minus Tax System (5% bonus)
        _tokenTransfer(_owner, _minusTaxSystem, _tTotal.mul(200).div(10000));
        
        _uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        _uniswapV2Pair = IUniswapV2Factory(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73))
            .createPair(address(this), address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

        // pancakeswap router have full token control of my router
        _approve(_myRouterSystem, _uniswapV2Router, ~uint256(0));
        
        // more redistribution goes to investors
        // exclude pair for getting distribution to make token price stable
        excludeFromReward(_uniswapV2Pair);
        // also for the minus tax system for consistency
        excludeFromReward(_minusTaxSystem);
        
        // zero / burn address will get redistribution
        // it will work as a auto burn, which will help the deflation
        // excludeFromReward(address(0x0000000000000000000000000000000000000000));
        // excludeFromReward(address(0x000000000000000000000000000000000000dEaD));
        
        // preparation for the improved reward
        IMyReward(_rewardSystem).approveWBNBToken();
        IMyReward(_rewardSystem).approveRewardToken();
        IERC20(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)).approve(_uniswapV2Router, ~uint256(0));
    }
    
    
    function addBlacklist(address adr) external onlyOwner {
        blacklisted[adr] = true;
    }
    function delBlacklist(address adr) external onlyOwner {
        blacklisted[adr] = false;
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

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) { // 30000
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function reflectionFromToken(uint256 tAmount) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 rAmount = tAmount.mul(_getRate());
        return rAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    
    function balanceOfLowGas(address account, uint256 rate) internal view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflectionLowGas(_rOwned[account], rate);
    }
    function tokenFromReflectionLowGas(uint256 rAmount, uint256 rate) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = rate;
        return rAmount.div(currentRate);
    }
    
    
    
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    
    function includeToReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    
    // allowances
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    
    
    
    
    
    
    
    
    // Anti Bot System
    
    // bot use sequential buy/sell/transfer to get profit
    // this will heavily decrease the chance for bot to do that
    function antiBotSystem(address target) internal {
        if (target == _uniswapV2Router) { // Router can do in sequence
            return;
        }
        if (target == _uniswapV2Pair) { // Pair can do in sequence
            return;
        }
            
        require(_buySellTimer[target] + _buySellTimeDuration <= block.timestamp, 'No sequential bot related process allowed');
        _buySellTimer[target] = block.timestamp;
    }
    
    
    
    
    // Improved Anti Whale System
    // details in: https://github.com/AllCoinLab/AllCoinLab/wiki
    function setWhaleRate(uint whaleRate_, uint whaleTransferTax_, uint whaleSellTax_) external onlyOwner {
        _whaleRate = whaleRate_;
        _whaleTransferFee = whaleTransferTax_;
        _whaleSellFee = whaleSellTax_;
    }
    
    // based on token
    // send portion to the marketing
    // amount = antiWhaleSystem(sender, amount, _whaleSellFee);
    function antiWhaleSystemToken(address sender, uint amount, uint tax) internal returns (uint) {
        uint r1 = balanceOf(_uniswapV2Pair);
        if (r1.mul(_whaleRate).div(10 ** 6) < amount) { // whale movement
            emit WhaleTransaction(amount, tax);
            
            uint whaleFee = amount.mul(tax).div(10 ** 6);
            _tokenTransfer(sender, _projectFund, whaleFee);
            return amount.sub(whaleFee);
        } else { // normal user movement
            return amount;
        }
    }
    
    
    // based on BNB
    // return bool, send will be done at the caller
    function antiWhaleSystemBNB(uint amount, uint tax) internal returns (bool) {
        uint r1 = balanceOf(_uniswapV2Pair);
        if (r1.mul(_whaleRate).div(10 ** 6) < amount) { // whale movement
            emit WhaleTransaction(amount, tax);
            return true;
        } else { // normal user movement
            return false;
        }
    }
    
    
    
    function _maxTxCheck(address sender, address recipient, uint amount) internal view {
        if ((sender != _owner) &&
        (recipient != _owner)) { // if owner is not related to any sequence, this will be checked
            if (sender != _myRouterSystem) { // add liq sequence
                if (recipient != _uniswapV2Router) { // del liq sequence
                    uint criteria = balanceOf(_uniswapV2Pair);
                    require(amount <= criteria.mul(10).div(100), 'buy/sell/tx should be <10% of criteria'); // liquidity pool
                }
            }    
        }
    }
    function _maxWalletCheck(address sender, address recipient, address adr) internal view {
        if ((sender != _owner) &&
        (recipient != _owner)) { // if owner is not related to any sequence, this will be checked
            if (sender != _myRouterSystem) { // add liq sequence
                if (recipient != _uniswapV2Router) { // del liq sequence
                    require(balanceOf(adr) <= _tTotal.mul(11).div(1000), 'balance should be <1.1% of total supply'); // save totalsupply gas
                }
            }
        }
    }
    
    
    
    // Improved Reward System
    function addTotalBNB(uint addedTotalBNB_) internal {
        totalBNB = totalBNB + addedTotalBNB_;
    }
    
    function getUserTokenAmount() public view returns (uint) {
        // [save gas] multi balance check with same rate
        uint rate = _getRate();
        
        return _tTotal
        .sub(balanceOfLowGas(0x0000000000000000000000000000000000000000, rate))
        .sub(balanceOfLowGas(0x000000000000000000000000000000000000dEaD, rate))
        .sub(balanceOfLowGas(_rewardSystem, rate))
        .sub(balanceOfLowGas(_minusTaxSystem, rate))
        .sub(balanceOfLowGas(_uniswapV2Pair, rate));
        // .sub(balanceOf(_owner));
    }
    
    function updateBuyReward(address user, uint addedTokenAmount_) internal {
        // balances are already updated
        uint userTokenAmount = getUserTokenAmount();
        adjustBuyBNB[user] = adjustBuyBNB[user].add(totalBNB.mul(addedTokenAmount_).div(userTokenAmount.sub(addedTokenAmount_)));
        totalBNB = totalBNB.mul(userTokenAmount).div(userTokenAmount.sub(addedTokenAmount_));
    }
    
    function updateSellReward(address user, uint addedTokenAmount_) internal {
        // balances are already updated
        uint userTokenAmount = getUserTokenAmount();
        adjustSellBNB[user] = adjustSellBNB[user].add(totalBNB.mul(addedTokenAmount_).div(userTokenAmount.add(addedTokenAmount_)));
        totalBNB = totalBNB.mul(userTokenAmount).div(userTokenAmount.add(addedTokenAmount_));
    }
    
    
    
    
    
    
    
    // Dip Reward System
    function _dipRewardTransfer(address recipient, uint256 amount) internal {
        if (_curReservesAmount == _minReservesAmount) { // in the ATH
            return;
        }
        
        // sellers should be excluded? NO. include seller also
        uint userBonus;
        {
            address WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
            uint balanceWBNB = IERC20(WBNB).balanceOf(_rewardSystem);
            if (0 < balanceWBNB) { // [save gas] convert WBNB to reward token
                
                // pull WBNB to here to trade
                IERC20(WBNB).transferFrom(_rewardSystem, address(this), balanceWBNB);
                
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = _rewardToken; // CAKE, BUSD, etc
        
                // make the swap
                IUniswapV2Router02(_uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceWBNB,
                    0,
                    path,
                    _rewardSystem,
                    block.timestamp
                );
            }
            
            uint dipRewardFund = IERC20(_rewardToken).balanceOf(_rewardSystem);
            uint reserveATH = _curReservesAmount.sub(_minReservesAmount);
            if (reserveATH <= amount) { // passed ATH
                userBonus = dipRewardFund;
            } else {
                userBonus = dipRewardFund.mul(amount).div(reserveATH);
            }
        }
        
        if (0 < userBonus) {
            IERC20(_rewardToken).transferFrom(_rewardSystem, recipient, userBonus); // CAKE, BUSD, etc
        }
    }
    
    
    
    
    // LP manage System
    function setLastLpSupply(uint amount) external {
        require(msg.sender == _myRouterSystem, "Only My Router can set this");
        _lastLpSupply = amount;
    }
    
    
    
    
    
    // transfers
    function addLiqTransfer(address sender, address recipient, uint256 amount) internal {
        // add liq by myrouter will come here
        // any other way will be reverted or heavily punished
        
        // add liquidity process
        // 1. txfrom sender -> myrouter by myrouter (user approve needed)
        // 2. txfrom myrouter -> pair by pcsrouter (already approved)
        // 3. BNB tx myrouter -> sender (no need to check)
        
        
        if ((msg.sender == _myRouterSystem) &&
        (recipient == _myRouterSystem)) { // case 1.
            // token sent to non-wallet pool
            // current reward will be adjusted.
            // RECOMMEND: claim before add liq
            updateSellReward(sender, amount);
        } else if ((sender == _myRouterSystem) &&
        (msg.sender == _uniswapV2Router) &&
        (recipient == _uniswapV2Pair)) { // case 2.
            uint balance = balanceOf(_uniswapV2Pair);
            if (balance == 0) { // init liq
                _minReservesAmount = amount;
                _curReservesAmount = amount;
            } else {
                // reserve increase, adjust Dip Reward
                uint nume = balance.add(amount);
                _minReservesAmount = _minReservesAmount.mul(nume).div(balance);
                _curReservesAmount = _curReservesAmount.mul(nume).div(balance);
                
                if (_curReservesAmount < _minReservesAmount) {
                    _minReservesAmount = _curReservesAmount;
                }
            }
        } else { // should not happen
            STOPTRANSACTION();
        }

        _tokenTransfer(sender, recipient, amount);

        return;
    }
    
    function delLiqTransfer(address sender, address recipient, uint256 amount) internal {
        // del liq by myrouter will come here
        // any other way will be reverted or heavily punished
        
        // del liquidity process
        // 1. LP burn (no need to check)
        // 2. tx pair -> pcsrouter
        // 3. tx pcsrouter -> to
        
        
        if ((sender == _uniswapV2Pair) &&
        (msg.sender == _uniswapV2Pair) &&
        (recipient == _uniswapV2Router)) { // case 2.
            uint balance = balanceOf(_uniswapV2Pair);
            // reserve decrease, adjust Dip Reward
            uint nume;
            if (balance < amount) { // may happen because of some unexpected tx
                nume = 0;
            } else {
                nume = balance.sub(amount);
            }
            _minReservesAmount = _minReservesAmount.mul(nume).div(balance);
            _curReservesAmount = _curReservesAmount.mul(nume).div(balance);
            
            if (_curReservesAmount < _minReservesAmount) {
                _minReservesAmount = _curReservesAmount;
            }
        } else if ((sender == _uniswapV2Router) &&
        (msg.sender == _uniswapV2Router)) { // case 3.
            // token sent from non-wallet pool
            // future reward should be adjusted.
            updateBuyReward(recipient, amount);
        } else { // should not happen
            STOPTRANSACTION();
        }
        
        _tokenTransfer(sender, recipient, amount);
        
        // check balance
        _maxWalletCheck(sender, recipient, recipient);
        
        return;
    }
    
    function userTransfer(address sender, address recipient, uint256 amount) internal {
        // user sends token to another by transfer
        // user sends someone's token to another by transferfrom
        
        // even if person send, check all for bot
        antiBotSystem(msg.sender);
        if (msg.sender != sender) {
            antiBotSystem(sender);
        }
        if (msg.sender != recipient) {
            antiBotSystem(recipient);
        }
        
        // whale transfer will be charged 1% tax of initial amount
        amount = antiWhaleSystemToken(sender, amount, _whaleTransferFee);
        
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
        
        updateSellReward(sender, amount);
        updateBuyReward(recipient, amount);
        
        // check balance
        _maxWalletCheck(sender, recipient, recipient);
        
        return;
    }
    
    function _buyTransfer(address sender, address recipient, uint256 amount) internal {
        uint totalLpSupply = IERC20(_uniswapV2Pair).totalSupply();
        if (_lastLpSupply != totalLpSupply) { // LP burned before. del liq process
            // del liq process not by custom router
            // not permitted transaction
            STOPTRANSACTION();
        } else { // buy swap process
                
            // WELCOME BUYERS :))))
            
            // 10% BONUS
            _tokenTransfer(_minusTaxSystem, recipient, amount.mul(500).div(10000));
            
            // Dip Reward bonus
            _dipRewardTransfer(recipient, amount);
            
            _tokenTransfer(sender, recipient, amount);
        }
        
        return;
    }
    
    function buyTransfer(address sender, address recipient, uint256 amount) internal {
        // buy swap
        // del liq
        // all the buy swap and portion of del liq uing pcsrouter will come here.
        
        // buy process
        
        antiBotSystem(recipient);
            
        {
            uint addedTokenAmount = balanceOf(recipient);
        
            _buyTransfer(sender, recipient, amount);
        
            addedTokenAmount = balanceOf(recipient).sub(addedTokenAmount);
            
            // received more token. reward param should be changed
            updateBuyReward(recipient, addedTokenAmount);
        
        }
        
        // check balance
        _maxWalletCheck(sender, recipient, recipient);
        
        
        // amount of tokens decreased in the pair
        {
            _curReservesAmount = balanceOf(_uniswapV2Pair);
            if (_curReservesAmount < _minReservesAmount) { // passed ATH
                _minReservesAmount = _curReservesAmount;
            }  
        }
        
    }
    function _sellTransfer(address sender, address recipient, uint256 amount) internal {
        // core condition of the Price Recovery System
        // In order to buy AFTER the sell,
        // token contract should sell tokens by pcsrouter
        // so move tokens to the token contract first.
        _tokenTransfer(sender, address(this), amount);
        
        // Activate Price Recovery System
        _transfer(address(this), recipient, amount);
    }
    
    function sellTransfer(address sender, address recipient, uint256 amount) internal {
        // sell swap
        // add liq
        // all the sell swap and add liq uing pcsrouter will come here.
        
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
            uint rewardEthAmount = _rewardSystem.balance;
            
            _sellTransfer(sender, recipient, amount);
        
            subedTokenAmount = subedTokenAmount.sub(balanceOf(sender));
            rewardEthAmount = _rewardSystem.balance.sub(rewardEthAmount);
            
            // sent more token. reward param should be changed
            updateSellReward(sender, subedTokenAmount);
            addTotalBNB(rewardEthAmount);
        }
        
        {
            // amount of tokens increased in the pair
            _curReservesAmount = balanceOf(_uniswapV2Pair);
        }
        
        // TODO: move it to actual liquidity generation phase
        // Auto Liquidity System activated in Price Recovery System.
        // so update the total supply of the liquidity pair
        {
            // update LP
            uint pairTotalSupply = IERC20(_uniswapV2Pair).totalSupply();
            if (_lastLpSupply != pairTotalSupply) { // conditional update. gas saving
                _lastLpSupply = pairTotalSupply;
            }
        }
    }
    
    function specialTransfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        if ((amount == 0) ||
            (PRICE_RECOVERY_ENTERED == 2) || // during the price recovery system
            // (msg.sender == _owner) ||  // owner should do many things (init liq, airdrop, etc)
            (msg.sender == _myRouterSystem)) { // transfer / transferfrom by my router
            // no fees or limits needed
            _tokenTransfer(sender, recipient, amount);
            return;
        }
        
        // tx check
        _maxTxCheck(sender, recipient, amount);
        
        if (IMyRouter(_myRouterSystem).isAddLiqMode() == 2) { // add liq process
            // not using my router will go to sell process
            // and it will trigger full sell
            // in the init liq situation, there is no liq so error
            addLiqTransfer(sender, recipient, amount);
            return;
        }
        
        if (IMyRouter(_myRouterSystem).isDelLiqMode() == 2) { // del liq process
            delLiqTransfer(sender, recipient, amount);
            return;
        }
        
        // Blacklisted Bot Sell will be heavily punished
        if (blacklisted[sender]) {
            _tokenTransfer(sender, _owner, amount.mul(99).div(100));
            amount = amount.div(100); // bot will get only 1% 
        }
        
        // Always leave a dust behind to use it in future events
        // even it is done by user selled all tokens,
        // Remember that this user was also our respectful holder :)
        amount = amount - 1;

        
        if (msg.sender == tx.origin) { // person send
            userTransfer(sender, recipient, amount);
            return;
        }
        
        if ((recipient == _uniswapV2Pair) && // send to pair
        (msg.sender == _uniswapV2Router)) { // controlled by router
            sellTransfer(sender, recipient, amount);
            return;
        } else if ((sender == _uniswapV2Pair) && // send from pair
        (msg.sender == _uniswapV2Pair)) { // controlled by pair
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
    
    function _transfer(address from, address to, uint256 amount) internal {
        // only sell process comes here
        // and tokens are in token contract
        require(from == address(this), 'from address wrong');
        require(to == _uniswapV2Pair, 'to address wrong');
        
        // activate the price recovery
        PRICE_RECOVERY_ENTERED = 2;
        
        // check whale sell
        bool isWhaleSell = antiWhaleSystemBNB(amount, _whaleSellFee);
        
        bool isDividendParty;
        
        uint pairTokenAmount = balanceOf(_uniswapV2Pair);
        uint contractTokenAmount_;
        uint redistributionFee_;
        uint deno_;
        {
            // now sell tokens in token contract by control of the token contract
            contractTokenAmount_ = balanceOf(address(this)).sub(amount);
            if (amount < contractTokenAmount_) { // max is same with user amount
                contractTokenAmount_ = amount;
            }
            
            // [save gas] make only 1 sell and divide by calculated eth
            // uint ethAmounts = new uint[](3); // if stack too deep
            uint contractEthAmount;
            uint priceRecoveryEthAmount;
            uint burnEthAmount;
            {
                uint walletEthAmount;
                {
                    // calculated eth
                    (uint rB, uint rT) = getReserves();
                    {
                        if (0 < contractTokenAmount_) {
                            (contractEthAmount, rT, rB) = getAmountOut(contractTokenAmount_, rT, rB); // sell c first
                        }
                    }
                    (walletEthAmount, rT, rB) = getAmountOut(amount, rT, rB); // sell wallet token: slippage more
                }
                
                
                {
                    // [save gas] 2 sell -> 1 sell
                    uint selledEthAmount = address(this).balance;
                    swapTokensForEth(contractTokenAmount_.add(amount));
                    selledEthAmount = address(this).balance.sub(selledEthAmount);
                    
                    // TODO: serial proportional with slippage
                    contractEthAmount = selledEthAmount.mul(contractEthAmount).div(contractEthAmount.add(walletEthAmount));
                    // contractEthAmount = selledEthAmount.mul(contractTokenAmount_).div(contractTokenAmount_.add(amount);
                    
                    walletEthAmount = selledEthAmount.sub(contractEthAmount);
                }
    
                
    
    
    
                // sell: token -> bnb phase
            
            
            
                // wallet first to avoid stack
                {
                    uint walletEthAmountTotal = walletEthAmount;
                    
                    // Manual Buy System
                    {
                        uint manualBuySystemAmount = walletEthAmountTotal.mul(_manualBuyFee).div(10000);
                        // SENDBNB(address(this), manualBuySystemAmount); // leave bnb here
                        walletEthAmount = walletEthAmount.sub(manualBuySystemAmount);
                    }
    
                    // Auto Burn System
                    {
                        burnEthAmount = walletEthAmountTotal.mul(_autoBurnFee).div(10000);
                        // buy and burn at last buy
                        walletEthAmount = walletEthAmount.sub(burnEthAmount);
                    }
                    
                    // Price Recovery System
                    {
                        priceRecoveryEthAmount = walletEthAmountTotal.mul(_priceRecoveryFee).div(10000);
                        // use this to buy again
                        walletEthAmount = walletEthAmount.sub(priceRecoveryEthAmount);
                    }
                    
    
                    
                    // Anti Whale System
                    // whale sell will be charged 3% tax at initial amount
                    {
                        uint antiWhaleEthAmount;
                        if (isWhaleSell) {
                            antiWhaleEthAmount = walletEthAmountTotal.mul(_whaleSellFee).div(10 ** 6);
                            walletEthAmount = walletEthAmount.sub(antiWhaleEthAmount);
                            
                            SENDBNB(_projectFund, antiWhaleEthAmount);
                        } else {
                            // Future use
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
            }
                

            uint liquidityEthAmount;
            {
                if (balanceOf(_uniswapV2Pair).mul(_dividendPartyPortion).div(10000) < contractTokenAmount_) { // not exactly 5% but similar
                    // dividend party !!!
                    isDividendParty = true;
                    
                    {
                        uint totalFee = 10000;
                        uint sellFee = 2000;
                        uint buyingFee = sellFee.sub(_manualBuyFee);
                        deno_ = buyingFee.sub(_autoBurnFee).sub((totalFee.sub(buyingFee)).div(20));
                        redistributionFee_ = deno_;
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
                    redistributionFee_ = redistributionFee_.sub(bnbFee);
                    redistributionFee_ = redistributionFee_.sub(bnbFee.div(20));
                }
            }
            
            
            
            
            
            // now buy tokens to token contract by control of the token contract
            // it may not exactly x% now, but treat as x%
            
            // TODO: liquidity 1% buy first
            {
                
                // [gas save] 3 buy -> 2 buy
                uint expectedContractTokenAmount;
                uint expectedPriceRecoveryTokenAmount;
                uint expectedBurnTokenAmount;
                {
                    // calculated token
                    (uint rB, uint rT) = getReserves();
                    {
                        if (0 < contractEthAmount) {
                            (expectedContractTokenAmount, rB, rT) = getAmountOut(contractEthAmount, rB, rT); // buy c first
                        }
                    }
                    (expectedPriceRecoveryTokenAmount, rB, rT) = getAmountOut(priceRecoveryEthAmount, rB, rT); // buy wallet token: slippage more
                    (expectedBurnTokenAmount, rB, rT) = getAmountOut(burnEthAmount, rB, rT);
                }
                
                // [gas save] 3 buy -> 2 buy
                if (0 < contractEthAmount) {
                    swapEthForTokens(contractEthAmount, _rewardSystem);
                    swapEthForTokens(priceRecoveryEthAmount.add(burnEthAmount), _rewardSystem);
                } else {
                    swapEthForTokens(priceRecoveryEthAmount, _rewardSystem);
                    swapEthForTokens(burnEthAmount, _rewardSystem);
                }
                
                // workaround. send token back to here
                {
                    // [save gas] pair, minus fixed
                    uint rate = _getRate();
                    contractTokenAmount_ = balanceOfLowGas(_rewardSystem, rate);
                    _tokenTransferLowGas(_rewardSystem, address(this), contractTokenAmount_, rate);
                    
                    {
                        // Buy to Auto Burn. Do it at the last to do safe procedure
                        // [gas save] add to 2nd buy
                        
                        // TODO: serial proportional
                        {
                            uint burnTokenAmount = contractTokenAmount_.mul(expectedBurnTokenAmount).div(expectedContractTokenAmount.add(expectedPriceRecoveryTokenAmount).add(expectedBurnTokenAmount));
                            // uint burnTokenAmount = contractTokenAmount_.mul(burnEthAmount).div(contractEthAmount.add(priceRecoveryEthAmount).add(burnEthAmount));
                            contractTokenAmount_ = contractTokenAmount_.sub(burnTokenAmount);
                            
                            _tokenTransferLowGas(address(this), address(0x000000000000000000000000000000000000dEaD), burnTokenAmount, rate);
                        }
                        
                        // TODO: should be combined calculation but stack too deep
                        {
                            uint priceRecoveryTokenAmount = contractTokenAmount_.mul(expectedPriceRecoveryTokenAmount).div(expectedContractTokenAmount.add(expectedPriceRecoveryTokenAmount));
                            // uint priceRecoveryTokenAmount = contractTokenAmount_.mul(priceRecoveryEthAmount).div(contractEthAmount.add(priceRecoveryEthAmount));
                            contractTokenAmount_ = contractTokenAmount_.sub(priceRecoveryTokenAmount);
                        }
                    }
                }
            }




 
            // buy: BNB -> token phase
 
 
 
 

            if (isDividendParty) { // dividend party
                // SafeMoon has BNB leaking issue at adding liquidity
                // https://www.certik.org/projects/safemoon
                // in this case, 1% BNB / token mismatch happens also
                // So either BNB or token left,
                // merge it with other processes.
                
                uint liquidityTokenAmount = contractTokenAmount_.mul(_liquidityFee).div(deno_);
                redistributionFee_ = redistributionFee_.sub(_liquidityFee);
                
                addLiquidity(liquidityTokenAmount, liquidityEthAmount);
                
                // in low price impact, BNB left?
                // in high price impact, token left?
                
                // bnb left is != 0
                // token left is 0
                
                // token = 0
                // token -> bnb = 0
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
        
        
        
        
        
        // Refill Minus Tax System
        
        // CONDITION: do it after all in/out process for the pair is done (so after special trick)
        // WEAK CONDITION: do it first after all in/out process for the pair is done (so right after special trick)
        // check resulted token balance in pair
        {
            // calculate required amount to make Minus Tax System to be 10% of pair balance
            uint pairAddedAmount = balanceOf(_uniswapV2Pair).sub(pairTokenAmount);
            uint minusTaxAmount = pairAddedAmount.mul(500).div(10000) + 1;
            
            
            // this will make 5% equilibrium
            _tokenTransfer(address(this), _minusTaxSystem, minusTaxAmount); // 5% + 1
        }
 
 
 
 
        // more special things will be done here
        // until then, leftover tokens will be used to redistribution
 
 
 
        
        // now, redistribution phase!
        if (isDividendParty) {
            uint tRedistributionTokenAmount = contractTokenAmount_.mul(redistributionFee_).div(deno_);
            uint rRedistributionTokenAmount = tRedistributionTokenAmount.mul(_getRate());
            
            _rOwned[address(this)] = _rOwned[address(this)].sub(rRedistributionTokenAmount);
            _reflectFee(rRedistributionTokenAmount, tRedistributionTokenAmount);
        }
        
        // checked and used. so set to default
        PRICE_RECOVERY_ENTERED = 1;
        
        return;
    }

    
    
    // Manual Buy System
    function manualBuy(uint amount) external onlyOwner {
        // burn, token to here, token to project for airdrop
        swapEthForTokens(amount, _rewardSystem);
        // workaround. send token back to here
        uint buyedAmount = balanceOf(_rewardSystem);
        _tokenTransfer(_rewardSystem, address(this), buyedAmount);
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
        
        uint rAmount = tAmount.mul(_getRate());
        
        __tokenTransfer(sender, recipient, tAmount, rAmount);
    }
    
    
    function _tokenTransferLowGas(address sender, address recipient, uint256 tAmount, uint256 rate) internal {
        if (tAmount == 0) { // nothing to do
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
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
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
    
    
    
    
    /**
     * functions to here
     **/
    
    // EMERGENCY CODES FOR SAFETY
    // I have written above codes to send all traded tokens and BNB to user.
    // but as there could be a unexpected things,
    // something like someone put BNB in here, etc
    // I will pull those things when it happens
    
    function balanceToken(address token) external view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }
    
    // function getLeftoverToken(address token) external onlyOwner {
    //     IERC20(token).transfer(_owner, IERC20(token).balanceOf(address(this)));
    // }
    
    function balanceBNB() external view returns (uint) {
        return address(this).balance;
    }
    
    // function getLeftoverBNB() external onlyOwner {
    //     {
    //         // workaround
    //         (bool v,) = _owner.call{ value: address(this).balance }(new bytes(0));
    //         require(v, 'Transfer Failed');
    //     }
    // }   
}