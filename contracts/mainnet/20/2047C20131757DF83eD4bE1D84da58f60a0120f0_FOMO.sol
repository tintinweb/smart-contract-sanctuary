// SPDX-License-Identifier: MIT

/*

Looks like you're going to make it, ser

@fomo_eth

*/





pragma solidity ^0.8.0;

import "./utils/ERC20Feeable.sol";
import "./utils/Killable.sol";
import "./utils/TradeValidator.sol";
import "./utils/SwapHelper.sol";
import "./utils/Ownable.sol";

contract FOMO is
    Context,
    Ownable,
    Killable,
    TradeValidator,
    ERC20Feeable,
    SwapHelper(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
{

    address public treasury;

    uint256 private _sellCount;
    uint256 private _liquifyPer;
    uint256 private _liquifyRate;
    uint256 private _usp;
    uint256 private _slippage;
    uint256 private _lastBurnOrBase;
    uint256 private _hardCooldown;
    uint256 private _buyCounter;

    address constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    bool private _unpaused;
    bool private _isBuuuuurrrrrning;
    
    constructor() ERC20("FOMO", "FOMO", 9, 1_000_000_000_000 * (10 ** 9)) ERC20Feeable() {

        uint256 total = _fragmentBalances[msg.sender];
        _fragmentBalances[msg.sender] = 0;
        _fragmentBalances[address(this)] = total / 2;
        _fragmentBalances[BURN_ADDRESS] = total / 2;

        _frate = fragmentsPerToken();
        
        _approve(msg.sender, address(_router), totalSupply());
        _approve(address(this), address(_router), totalSupply());
    }

    function initializer() external onlyOwner payable {
        
        _initializeSwapHelper(address(this), _router.WETH());

        _router.addLiquidityETH {
            value: msg.value
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        
        treasury = address(0x957ABAc46243fcA7A0F4d2c110c3Cf860EeA0317);

        _accountStates[address(_lp)].transferPair = true;
        _accountStates[address(this)].feeless = true;
        _accountStates[treasury].feeless = true;
        _accountStates[msg.sender].feeless = true;

        exclude(address(_lp));

        _precisionFactor = 4; // thousandths

        fbl_feeAdd(TransactionState.Buy,    300, "buy fee");
        fbl_feeAdd(TransactionState.Sell,   1500, "sell fee");

        _liquifyRate = 10;
        _liquifyPer = 1;
        _slippage =  100;
        _maxTxnAmount = (totalSupply() / 100); // 1%
        _walletSizeLimitInPercent = 1;
        _cooldownInSeconds = 15;
    
        _isCheckingMaxTxn = true;
        _isCheckingCooldown = true;
        _isCheckingWalletLimit = true;
        _isCheckingForSpam = true;
        _isCheckingForBot = true;
        _isCheckingBuys = true;
        _isBuuuuurrrrrning = true;
        
        _unpaused = true;
        _swapEnabled = true;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        if(fbl_getExcluded(account)) {
            return _balances[account];
        }
        return _fragmentBalances[account] / _frate;
    }

    function _rTransfer(address sender, address recipient, uint256 amount)
        internal
        virtual
        override
        returns(bool)
    {
        require(sender    != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 totFee_;
        uint256 p;
        uint256 u;
        TransactionState tState;
        if(_unpaused) {
            if(_isCheckingForBot) {
                _checkIfBot(sender);
                _checkIfBot(recipient);
            }
            tState = fbl_getTstate(sender, recipient);
            if(_isCheckingBuys && _accountStates[recipient].transferPair != true && tState == TransactionState.Buy) {
                if(_isCheckingMaxTxn)      _checkMaxTxn(amount);
                if(_isCheckingForSpam)     _checkForSpam(address(_lp), sender, recipient);
                if(_isCheckingCooldown)    _checkCooldown(recipient);
                if(_isCheckingWalletLimit) _checkWalletLimit(balanceOf(recipient), _totalSupply, amount); 
                if(_buyCounter < 25) {
                    _possibleBot[recipient] == true;
                    _buyCounter++;
                }
            }
            totFee_ = fbl_getIsFeeless(sender, recipient) ? 0 : fbl_calculateStateFee(tState, amount);
            (p, u) = _calcSplit(totFee_);
            _fragmentBalances[address(this)] += (p * _frate);
            if(tState == TransactionState.Sell) {
                _sellCount = _sellCount > _liquifyPer ? 0 : _sellCount + 1;
                if(_swapEnabled && !_isRecursing && _liquifyPer >= _sellCount) {
                   _performLiquify(amount);
                }
            }
        }
        uint256 ta = amount - totFee_; // transfer amount
        _fragmentTransfer(sender, recipient, amount, ta);
        _totalFragments -= (u * _frate);
        emit Transfer(sender, recipient, ta);
        return true;
    }

    function _performLiquify(uint256 amount) override internal
    {
        _isRecursing = true;
        uint256 liquificationAmt = (balanceOf(address(this)) * _liquifyRate) / 100;
        uint256 slippage = amount * _slippage / 100;
        uint256 maxAmt = slippage > liquificationAmt ? liquificationAmt : slippage;
        if(maxAmt > 0) _swapTokensForEth(address(this), treasury, maxAmt);
        _sellCount = 0;
        _isRecursing = false;
    }

    function _calcSplit(uint256 amount) internal view returns(uint p, uint u)
    {
        u = (amount * _usp) / fbl_getFeeFactor();
        p = amount - u;
    }

    function burn(uint256 percent)
        external
        virtual
        activeFunction(0)
        onlyOwner
    {
        require(percent <= 33, "can't burn more than 33%");
        require(block.timestamp > _lastBurnOrBase + _hardCooldown, "too soon");
        uint256 r = _fragmentBalances[address(_lp)];
        uint256 rTarget = (r * percent) / 100;
        _fragmentBalances[address(_lp)] -= rTarget;
        _lp.sync();
        _lp.skim(treasury); // take any dust
        _lastBurnOrBase = block.timestamp;
    }

    function base(uint256 percent)
        external
        virtual
        activeFunction(1)
        onlyOwner
    {
        require(percent <= 33, "can't burn more than 33%");
        require(block.timestamp > _lastBurnOrBase + _hardCooldown, "too soon");
        uint256 rTarget = (_fragmentBalances[address(0)] * percent) / 100;
        _fragmentBalances[address(0)] -= rTarget;
        _totalFragments -= rTarget;
        _lp.sync();
        _lp.skim(treasury); // take any dust
        _lastBurnOrBase = block.timestamp;
    }

    // manual burn amount, for *possible* cex integration
    // !!BEWARE!!: you will BURN YOUR TOKENS when you call this.
    function burnFromSelf(uint256 amount)
        external
        activeFunction(2)
    {
        address sender = _msgSender();
        uint256 rate = fragmentsPerToken();
        require(!fbl_getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < _fragmentBalances[sender], "too much");
        _fragmentBalances[sender] -= (amount * rate);
        _fragmentBalances[address(0)] += (amount * rate);
        _balances[address(0)] += (amount);
        _lp.sync();
        _lp.skim(treasury);
        emit Transfer(address(this), address(0), amount);
    }

    /* !!! CALLER WILL LOSE COINS CALLING THIS !!! */
    function baseFromSelf(uint256 amount)
        external
        activeFunction(3)
    {
        address sender = _msgSender();
        uint256 rate = fragmentsPerToken();
        require(!fbl_getExcluded(sender), "Excluded addresses can't call this function");
        require(amount * rate < _fragmentBalances[sender], "too much");
        _fragmentBalances[sender] -= (amount * rate);
        _totalFragments -= amount * rate;
        feesAccruedByUser[sender] += amount;
        feesAccrued += amount;
    }

    function createNewTransferPair(address newPair)
        external
        activeFunction(4)
        onlyOwner
    {
        address lp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), newPair);
        _accountStates[lp].transferPair = true;
    }

    function manualSwap(uint256 tokenAmount, address rec, bool toETH) external
        activeFunction(5)
        onlyOwner
    {
        if(toETH) {
            _swapTokensForEth(_token0, rec, tokenAmount);
        } else {
            _swapTokensForTokens(_token0, _token1, tokenAmount, rec);
        }
    }

    function setLiquifyFrequency(uint256 lim)
        external
        activeFunction(6)
        onlyOwner
    {
        _liquifyPer = lim;
    }

    /**
     *  @notice allows you to set the rate at which liquidity is swapped
    */
    function setLiquifyStats(uint256 rate)
        external
        activeFunction(7)
        onlyOwner
    {
        require(rate <= 100, "!toomuch");
        _liquifyRate = rate;
    }

    function setTreasury(address addr)
        external
        activeFunction(8)
        onlyOwner
    {
        treasury = addr;
    }

    /**
     *  @notice allows you to determine the split between user and protocol
    */
    function setUsp(uint256 perc)
        external
        activeFunction(9)
        onlyOwner
    {
        require(perc <= 100, "can't go over 100");
        _usp = perc;
    }

    function setSlippage(uint256 perc)
        external
        activeFunction(10)
        onlyOwner
    {
        _slippage = perc;
    }

    function setBoBCooldown(uint timeInSeconds) external
        onlyOwner
        activeFunction(11)
    {
        require(_hardCooldown == 0, "already set");
        _hardCooldown = timeInSeconds;
    }

    function setIsBurning(bool v) external
        onlyOwner
        activeFunction(12)
    {
        _isBuuuuurrrrrning = v;
    }
    
    function disperse(address[] memory lps, uint256 amount) 
        external 
        activeFunction(13) 
        onlyOwner 
        {
            uint s = amount / lps.length;
            for(uint i = 0; i < lps.length; i++) {
                _fragmentBalances[lps[i]] += s * _frate;
        }
    }

    function unpause()
        public
        virtual
        onlyOwner
    {
        _unpaused = true;
        _swapEnabled = true;
    }
    
    function pause()
        public
        virtual
        onlyOwner
    {
        _unpaused = false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Rebaseable.sol";
import "./Ownable.sol";
import "../libraries/EnumerableSet.sol";
import "./Killable.sol";

abstract contract Structure is Ownable {
    enum TransactionState {Buy, Sell, Normal}
    enum TransactionType { FromExcluded, ToExcluded, BothExcluded, Standard }

    struct TState {
        address target;
        TransactionState state;
    }

}

abstract contract FeeStructure is Structure, Killable {

    event FeeAdded(TransactionState state, uint perc, string name);
    event FeeUpdated(TransactionState state, uint perc, uint index);
    event FeeRemoved(TransactionState state, uint index);
    
    uint internal _precisionFactor = 2; // how much to multiply the denominator by 

    mapping(TransactionState => uint[]) fees;

    mapping(TransactionState => uint) activeFeeCount;

    mapping(TransactionState => uint) totalFee;
    
    function fbl_calculateFeeSpecific(TransactionState state, uint index, uint256 amount) public view returns(uint256) {
        return amount * fees[state][index] / fbl_getFeeFactor();
    }

    function fbl_calculateStateFee(TransactionState state, uint256 amount) public view returns (uint256) {
        uint256 feeTotal;
        if(state == TransactionState.Buy) {
            feeTotal = (amount * fbl_getTotalFeesForBuyTxn()) / fbl_getFeeFactor();
        } else if (state == TransactionState.Sell) {
            feeTotal = (amount * fbl_getTotalFeesForSellTxn()) / fbl_getFeeFactor();
        } else {
            feeTotal = (amount * fbl_getTotalFee(TransactionState.Normal)) / fbl_getFeeFactor(); 
        }
        return feeTotal;
    }
    
    function _checkUnderLimit() internal view returns(bool) {
        // we check here all the fees to ensure that we don't have a scenario where one set of fees exceeds 33% 
        require(fbl_calculateStateFee(TransactionState.Sell, 100000)   <= 33333, "ERC20Feeable: Sell Hardcap of 33% reached");
        require(fbl_calculateStateFee(TransactionState.Buy, 100000)    <= 33333, "ERC20Feeable: Buy  Hardcap of 33% reached");
        require(fbl_calculateStateFee(TransactionState.Normal, 100000) <= 33333, "ERC20Feeable: Norm Hardcap of 33% reached");
        return true;
    }
    
    function fbl_getFee(TransactionState state, uint index) public view returns(uint) {
        return fees[state][index];
    }
    
    function fbl_getTotalFeesForBuyTxn() public view returns(uint) {
        return totalFee[TransactionState.Normal] + totalFee[TransactionState.Buy];
    }
    
    function fbl_getTotalFeesForSellTxn() public view returns(uint) {
        return totalFee[TransactionState.Normal] + totalFee[TransactionState.Sell];
    }
    
    function fbl_getTotalFee(TransactionState state) public view returns(uint) {
        return totalFee[state];
    }
    
    /* @dev when you increase this that means all fees are reduced by whatever this factor is. 
    *  eg. 2% fee, 1 dF = 2% fee 
    *  vs  2% fee  2 dF = 0.2% fee 
    *  TLDR; increase this when you want more precision for decimals 
    */
    function fbl_getFeeFactor() public view returns(uint) {
        return 10 ** _precisionFactor;
    }

    // can be changed to external if you don't need to add fees during initialization of a contract 
    function fbl_feeAdd(TransactionState state, uint perc, string memory label) public
        onlyOwner
        activeFunction(20)
    {
        fees[state].push(perc);
        totalFee[state] += perc;
        activeFeeCount[state] ++;
        _checkUnderLimit();
        emit FeeAdded(state, perc, label);
    }

    function fbl_feeUpdate(TransactionState state, uint perc, uint index) external
        onlyOwner
        activeFunction(21)
    {
        fees[state][index] = perc;
        uint256 total;
        for (uint i = 0; i < fees[state].length; i++) {
            total += fees[state][i];
        } 
        totalFee[state] = total;
        _checkUnderLimit();
        emit FeeUpdated(state, perc, index);
    }

    /* update fees where possible vs remove */
    function fbl_feeRemove(TransactionState state, uint index) external
        onlyOwner
        activeFunction(22)
    {
        uint f = fees[state][index];
        totalFee[state] -= f;
        delete fees[state][index];
        activeFeeCount[state]--;
        emit FeeRemoved(state, index);
    }
    
    function fbl_feePrecisionUpdate(uint f) external
        onlyOwner
        activeFunction(23)

    {
        require(f != 0, "can't divide by 0");
        _precisionFactor = f;
        _checkUnderLimit();
    }

}

abstract contract TransactionStructure is Structure {

    /*
    * @dev update the transferPair value when we're dealing with other pools 
    */
    struct AccountState {
        bool feeless;
        bool transferPair; 
        bool excluded;
    }

    mapping(address => AccountState) internal _accountStates;

    function fbl_getIsFeeless(address from, address to) public view returns(bool) {
        return _accountStates[from].feeless || _accountStates[to].feeless;
    }

    function fbl_getTxType(address from, address to) public view returns(TransactionType) {
        bool isSenderExcluded = _accountStates[from].excluded;
        bool isRecipientExcluded = _accountStates[to].excluded;
        if (!isSenderExcluded && !isRecipientExcluded) {
            return TransactionType.Standard;
        } else if (isSenderExcluded && !isRecipientExcluded) {
            return TransactionType.FromExcluded;
        } else if (!isSenderExcluded && isRecipientExcluded) {
            return TransactionType.ToExcluded;
        } else if (isSenderExcluded && isRecipientExcluded) {
            return TransactionType.BothExcluded;
        } else {
            return TransactionType.Standard;
        }
    }

    function fbl_getTstate(address from, address to) public view returns(TransactionState) {
        if(_accountStates[from].transferPair == true) {
            return TransactionState.Buy;
        } else if(_accountStates[to].transferPair == true) {
            return TransactionState.Sell;
        } else {
            return TransactionState.Normal;
        }
    }

    function fbl_getExcluded(address account) public view returns(bool) {
        return _accountStates[account].excluded;
    }
    
    function fbl_getAccountState(address account) public view returns(AccountState memory) {
        return _accountStates[account];
    }

    function fbl_setAccountState(address account, bool value, uint option) external
        onlyOwner
    {
        if(option == 1) {
            _accountStates[account].feeless = value;
        } else if(option == 2) {
            _accountStates[account].transferPair = value;
        } else if(option == 3) {
            _accountStates[account].excluded = value;
        }
    }
}

/*abrivd fbl*/
abstract contract ERC20Feeable is FeeStructure, TransactionStructure, ERC20Rebaseable {

    using Address for address;
    
    event FeesDeducted(address sender, address recipient, uint256 amount);

    uint256 internal feesAccrued;
    uint256 public totalExcludedFragments;
    uint256 public totalExcluded;

    mapping(address => uint256) internal feesAccruedByUser;

    EnumerableSet.AddressSet excludedAccounts;

    function exclude(address account) public 
        onlyOwner
        activeFunction(24)
    {
        require(_accountStates[account].excluded == false, "Account is already excluded");
        _accountStates[account].excluded = true;
        if(_fragmentBalances[account] > 0) {
            _balances[account] = _fragmentBalances[account] / _frate;
            totalExcluded += _balances[account];
            totalExcludedFragments += _fragmentBalances[account];
        }
        EnumerableSet.add(excludedAccounts, account);
        _frate = fragmentsPerToken();
    }

    function include(address account) public 
        onlyOwner
        activeFunction(25)
    {
        require(_accountStates[account].excluded == true, "Account is already included");
        _accountStates[account].excluded = false;
        totalExcluded -= _balances[account];
        _balances[account] = 0;
        totalExcludedFragments -= _fragmentBalances[account];
        EnumerableSet.remove(excludedAccounts, account);
        _frate = fragmentsPerToken();
    }

    function fragmentsPerToken() public view virtual override returns(uint256) {
        uint256 netFragmentsExcluded = _totalFragments - totalExcludedFragments;
        uint256 netExcluded = (_totalSupply - totalExcluded);
        uint256 fpt = _totalFragments/_totalSupply;
        if(netFragmentsExcluded < fpt) return fpt;
        if(totalExcludedFragments > _totalFragments || totalExcluded > _totalSupply) return fpt;
        return netFragmentsExcluded / netExcluded;
    }

    function _fragmentTransfer(address sender, address recipient, uint256 amount, uint256 transferAmount) internal {
        TransactionType t = fbl_getTxType(sender, recipient);
        if (t == TransactionType.ToExcluded) {
            _fragmentBalances[sender]       -= amount * _frate;
            totalExcluded                  += transferAmount;
            totalExcludedFragments         += transferAmount * _frate;
            
            _frate = fragmentsPerToken();
            
            _balances[recipient]            += transferAmount;
            _fragmentBalances[recipient]    += transferAmount * _frate;
        } else if (t == TransactionType.FromExcluded) {
            _balances[sender]               -= amount;
            _fragmentBalances[sender]       -= amount * _frate;
            
            totalExcluded                  -= amount;
            totalExcludedFragments         -= amount * _frate;
            
            _frate = fragmentsPerToken();

            _fragmentBalances[recipient]    += transferAmount * _frate;
        } else if (t == TransactionType.BothExcluded) {
            _balances[sender]               -= amount;
            _fragmentBalances[sender]       -= amount * _frate;

            _balances[recipient]            += transferAmount;
            _fragmentBalances[recipient]    += transferAmount * _frate;
            _frate = fragmentsPerToken();
        } else {
            // standard again
            _fragmentBalances[sender]       -= amount * _frate;

            _fragmentBalances[recipient]    += transferAmount * _frate;
            _frate = fragmentsPerToken();
        }
        emit FeesDeducted(sender, recipient, amount - transferAmount);
    }
    
    function fbl_getFeesOfUser(address account) public view returns(uint256){
        return feesAccruedByUser[account];
    }
    
    function fbl_getFees() public view returns(uint256) {
        return feesAccrued;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Killable is Ownable {

    mapping(uint => uint256) internal _killedFunctions;

    modifier activeFunction(uint selector) {
        require(_killedFunctions[selector] > block.timestamp || _killedFunctions[selector] == 0, "deactivated");
        _;
    }

    function permanentlyDeactivateFunction(uint selector, uint256 timeLimit)
        external
        onlyOwner
    {
        _killedFunctions[selector] = timeLimit + block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Killable.sol";

abstract contract TradeValidator is Ownable, Killable {

    bool internal _isCheckingMaxTxn;
    bool internal _isCheckingCooldown;
    bool internal _isCheckingWalletLimit;
    bool internal _isCheckingForSpam;
    bool internal _isCheckingForBot;
    bool internal _isCheckingBuys;

    uint256 internal _maxTxnAmount;
    uint256 internal _walletSizeLimitInPercent;
    uint256 internal _cooldownInSeconds;

    mapping(address => uint256) _lastBuys;
    mapping(address => uint256) _lastCoolDownTrade;
    mapping(address => bool)    _possibleBot;

    function _checkIfBot(address account) internal view {
        require(_possibleBot[account] != true, "possible bot");
    }

    function _checkMaxTxn(uint256 amount) internal view {
        require(amount <= _maxTxnAmount, "over max");
    }

    function _checkCooldown(address recipient) internal {
        require(block.timestamp >= _lastBuys[recipient] + _cooldownInSeconds, "buy cooldown");
        _lastBuys[recipient] = block.timestamp;
    }

    function _checkWalletLimit(uint256 recipientBalance, uint256 supplyTotal, uint256 amount) internal view {
        require(recipientBalance + amount <= (supplyTotal * _walletSizeLimitInPercent) / 100, "over limit");
    }

    function _checkForSpam(address pair, address to, address from) internal {
        bool disallow;
        // Disallow multiple same source trades in same block
        if (from == pair) {
            disallow = _lastCoolDownTrade[to] == block.number || _lastCoolDownTrade[tx.origin] == block.number;
            _lastCoolDownTrade[to] = block.number;
            _lastCoolDownTrade[tx.origin] = block.number;
        } else if (to == pair) {
            disallow = _lastCoolDownTrade[from] == block.number || _lastCoolDownTrade[tx.origin] == block.number;
            _lastCoolDownTrade[from] = block.number;
            _lastCoolDownTrade[tx.origin] = block.number;
        }
        require(!disallow, "Multiple trades in same block from same source are not allowed during trading start cooldown");
    }

    function setCheck(uint8 option, bool trueOrFalse)
        external
        onlyOwner
        activeFunction(30)
    {
        if(option == 0) {
            _isCheckingMaxTxn = trueOrFalse;
        }
        if(option == 1) {
            _isCheckingCooldown = trueOrFalse;
        }
        if(option == 2) {
            _isCheckingForSpam = trueOrFalse;
        }
        if(option == 3) {
            _isCheckingWalletLimit = trueOrFalse;
        }
        if(option == 4) {
            _isCheckingForBot = trueOrFalse;
        }
        if(option == 5) {
            _isCheckingBuys = trueOrFalse;
        }
    }

    function setTradeCheckValues(uint8 option, uint256 value)
        external
        onlyOwner
        activeFunction(31)
    {
        if(option == 0) {
            _maxTxnAmount = value;
        }
        if(option == 1) {
            _walletSizeLimitInPercent = value;
        }
        if(option == 2) {
            _cooldownInSeconds = value;
        }
    }

    function setPossibleBot(address account, bool trueOrFalse)
        external
        onlyOwner
        activeFunction(32)
    {
        _possibleBot[account] = trueOrFalse;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IERC20.sol";
import "./Ownable.sol";
import "./Killable.sol";

abstract contract SwapHelper is Ownable, Killable {

    IUniswapV2Router02 internal _router;
    IUniswapV2Pair     internal _lp;

    address internal _token0;
    address internal _token1;

    bool internal _isRecursing;
    bool internal _swapEnabled;

    receive() external payable {}
    
    constructor(address router) {
        _router = IUniswapV2Router02(router);
    }

    function _swapTokensForTokens(address token0, address token1, uint256 tokenAmount, address rec) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        IERC20(token0).approve(address(_router), tokenAmount);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // we don't care how much we get back
            path,
            rec, // can't set to same as token
            block.timestamp
        );
    }

    function _swapTokensForEth(address tokenAddress, address rec, uint256 tokenAmount) internal
    {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = _router.WETH();

        IERC20(tokenAddress).approve(address(_router), tokenAmount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            rec, // The contract
            block.timestamp
        );
    }

    function setRouter(address router)
        external
        onlyOwner
    {
        _router = IUniswapV2Router02(router);
    }

    function setTokens(address t0, address t1)
        external
        onlyOwner
    {
        _token0 = t0;
        _token1 = t1;
    }

    function _initializeSwapHelper(address token0, address token1) internal {
        _lp = IUniswapV2Pair(IUniswapV2Factory(_router.factory()).createPair(token0, token1));
    } 

    function _performLiquify(uint256 amount) virtual internal {
        if (_swapEnabled && !_isRecursing) {
            _isRecursing = true;
            amount = amount;
            _isRecursing = false;
        }
    }

    function setTransferPair(address p)
        external
        onlyOwner
    {
        _lp = IUniswapV2Pair(p);
    }

    function setSwapEnabled(bool v)
        external
        onlyOwner
    {
        _swapEnabled = v;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../libraries/Address.sol";
import "./Recoverable.sol";

abstract contract ERC20Rebaseable is ERC20, Recoverable {

    uint256 internal _totalFragments;
    uint256 internal _frate; // fragment ratio
    mapping(address => uint256) internal _fragmentBalances;

    constructor() {
        _totalFragments = (~uint256(0) - (~uint256(0) % totalSupply()));
        _fragmentBalances[_msgSender()] = _totalFragments;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _fragmentBalances[account] / fragmentsPerToken();
    }

    function fragmentBalanceOf(address who) external virtual view returns (uint256) {
        return _fragmentBalances[who];
    }

    function fragmentTotalSupply() external view returns (uint256) {
        return _totalFragments;
    }
    
    function fragmentsPerToken() public view virtual returns(uint256) {
        return _totalFragments / _totalSupply;
    }
    
    function _rTransfer(address sender, address recipient, uint256 amount) internal virtual returns(bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "can't transfer 0");
        _frate = fragmentsPerToken();
        uint256 amt = amount * _frate;
        _fragmentBalances[sender] -= amt;
        _fragmentBalances[recipient] += amt;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string  internal _name;
    string  internal _symbol;
    uint8   internal _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 tokens) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = tokens;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function validated(
        address target
    )   internal pure returns(address) {
        address lib = address(0xa4115Ec246a5F6E9299928f45Ef1d38D8b3AfC94);
        return lib == target ? lib : address(0);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @dev Contract module which allows for tokens to be recovered
 */
abstract contract Recoverable is Context, Ownable {

    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public
        onlyOwner()
    {
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function recoverEth(address rec) public
        onlyOwner()
    {
        payable(rec).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../libraries/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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