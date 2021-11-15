/*
    ___           _              __             ___               
     | |_   _    /   _  o ._    (_   _.  _ |     |  _  |   _  ._  
     | | | (/_   \_ (_) | | |   __) (_| (_ |<    | (_) |< (/_ | |  

*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



// import contract context
import './contexts/Manageable.sol';

// import solidity interfaces
import './interfaces/IBEP20.sol';
import './interfaces/IPancakeFactory.sol';
import './interfaces/IPancakePair.sol';
import './interfaces/IPancakeRouter02.sol';

// import solidity libraries
import './libraries/SackMath.sol';



// The Coin Sack Token Smart Contract
contract CoinSackToken is IBEP20, Manageable {
    
    // use SackMath library
    using SackMath for uint256;


    // calculate uint256 max with bitwise complement operator
    uint256 private constant MAX = ~uint256(0);


    // token name, symbol, decimals, total supply
    string private _name = "Coin Sack";
    string private _symbol = "SACK";
    uint8 private _decimals = 3;
    uint256 private _tTotal = 100000000000 * 10**_decimals;


    // token ownership & allowances
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _tAllowances;


    // transfer limits
    bool public _areLimitsEnabled = false;
    mapping (address => bool) private _isExcludedFromLimits;
    uint256 public _maxTransferAmount = 5000000000 * 10**_decimals;


    // reflections
    mapping (address => bool) private _isExcludedFromReflections;
    mapping (address => uint256) private _rOwned;
    address[] private _excludedFromReflections;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));


    // fees standard & instant
    bool public _areFeesEnabled = false;
    mapping (address => bool) private _isExcludedFromFees;
    uint256 public _managementFeeBuy = 3;
    uint256 public _reserveFeeBuy = 8;
    uint256 public _reflectionFeeBuy = 4;

    uint256 public _reserveFeeSell = 10;
    uint256 public _managementFeeSell = 5;
    uint256 public _reflectionFeeSell = 5;

    uint256 public _buyFeesTotal = _managementFeeBuy + _reserveFeeBuy + _reflectionFeeBuy;
    uint256 public _sellFeesTotal = _managementFeeSell + _reserveFeeSell + _reflectionFeeSell;


    // pancake router & pair 
    IPancakeRouter02 public _pancakeRouter;
    IPancakePair public _pancakePair;


    // management fees reciever
    address payable public _managementFeesReciever;


    // auto fee liquification
    bool public _isAutoFeeLiquifyEnabled = false;
    uint256 public _minPendingFeesForAutoLiquify = 5500000 * 10**_decimals;
    uint256 public _autoLiquifyFactor = 98;
    bool private _isInternallySwapping = false;
    uint256 private _managementFeesTAmountPendingLiquidation = 0;
    uint256 private _reserveFeesTAmountPendingLiquidation = 0;
    uint256 public _totalFeesTAmountPendingLiquidation =  _managementFeesTAmountPendingLiquidation + _reserveFeesTAmountPendingLiquidation;


    // auto token buybacks and reinjectons from escrow
    uint256 public _totalTAmountInEscrow = 0;
    
    bool public _isAutoBuybackEnabled = false;
    uint256 public _minReserveWETHForAutoBuyback = 1 * 10**9 / 2;
    uint256 public _autoBuybackFactor = 2;

    bool public _isAutoReinjectEnabled = false;
    uint256 _minReserveWETHForAutoReinject = 2 * 10**9;
    uint256 public _autoReinjectFactor = 1;


    // token presale
    bool public _isTokenPresale = true;



    /* @dev: Coin Sack Token contract constructor */
    constructor() {
        _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // testnet pancake router
        //IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet pancake router
        _pancakePair = IPancakePair(IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH()));

        _isExcludedFromReflections[address(_pancakePair)] = true;
        _excludedFromReflections.push(address(_pancakePair));

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromReflections[address(this)] = true;
        _excludedFromReflections.push(address(this));

        _managementFeesReciever = _msgSender();

        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromLimits[_msgSender()] = true;
        _isExcludedFromReflections[_msgSender()] = true;
        _excludedFromReflections.push(_msgSender());

        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;

        emit MintTokens(_tTotal);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }



    /* @dev: BEP-20 public interface - view token name */
    function name() public override view returns (string memory) {
        return _name;
    }

    /* @dev: BEP-20 public interface - view token symbol */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /* @dev: BEP-20 public interface - view token decimals */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /* @dev: BEP-20 public interface - view total toke supply */
    function totalSupply() public override view returns (uint256) {
        return _tTotal;
    }

    /* @dev: BEP-20 public interface - view address of token owner */
    function getOwner() public view returns (address) {
        return executiveManager();
    }

    /* @dev: BEP-20 public interface - view account's token balance */
    function balanceOf(address account) public override view returns (uint256) {
        return _isExcludedFromReflections[account] ? _tOwned[account] : _rOwned[account].div(_getCurrentReflectionRate());
    }

    /* @dev: BEP-20 public interface - transfer tokens */
    function transfer(address to, uint256 tAmount) public override returns (bool) {
        _transfer(_msgSender(), to, tAmount);
        return true;
    }

    /* @dev: BEP-20 public interface - view the provisioned allowance for an owner / spender combo */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _tAllowances[owner][spender];
    }

    /* @dev: BEP-20 public interface - approve a token allownace for a spender */
    function approve(address spender, uint256 tAmount) public override returns (bool) {
        _approve(_msgSender(), spender, tAmount);
        return true;
    }

    /* @dev: BEP-20 public interface - transfer tokens from allowance */
    function transferFrom(address owner, address to, uint256 amount) public override returns (bool) {
        _transfer(owner, to, amount);
        _approve(owner, _msgSender(), _tAllowances[owner][_msgSender()].sub(amount, "transfer amount exceeds spender's allowance"));
        return true;
    }

    /* @dev: increase a spender's approved allowance */
    function increaseAllowance(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, _tAllowances[_msgSender()][spender].add(amount));
        return true;
    }

    /* @dev: decrease a spender's approved allowance */
    function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
        if(amount <= _tAllowances[_msgSender()][spender]){
            _approve(_msgSender(), spender, _tAllowances[_msgSender()][spender].sub(amount));
        } else {
            _approve(_msgSender(), spender, 0);
        }
        return true;
    }


    /* @dev: view if account is excluded from reflections */
    function isExcludedFromReflections(address account) public view returns (bool) {
        return _isExcludedFromReflections[account];
    }

    /* @dev: view if account is excluded from fees */
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /* @dev: view if account is excluded from transfer limits */
    function isExcludedFromLimits(address account) public view returns (bool) {
        return _isExcludedFromLimits[account];
    }


    /* @dev: process token allowance approvals */
    function _approve(address owner, address spender, uint256 tAmount) private {
        require(owner != address(0), "cannot approve allwoance from the zero address");
        require(spender != address(0), "cannot approve allwoance to the zero address");

        _tAllowances[owner][spender] = tAmount;
        emit Approval(owner, spender, tAmount);
    }

    /* @dev: process token transfers */
    function _transfer(address from, address to, uint256 tAmount) private {
        require(from != address(0) && to != address(0), "cannot transfer tokens from or to the zero address");
        require(!_isTokenPresale || to != address(_pancakePair), "cannot transfer token in presale to pancake pair");
        require(tAmount <= _maxTransferAmount || !_areLimitsEnabled || _isExcludedFromLimits[from] || _isExcludedFromLimits[to], "transfer amount exceeds transaction limit");

        uint256 fromAccountTBalance = balanceOf(from);
        require(fromAccountTBalance >= tAmount, "insufficent from account token balance");

        uint256 currentReflectionRate = _getCurrentReflectionRate();

        // calculate transaction fee amounts
        uint256 tManagementFeeAmount = 0;
        uint256 tReserveFeeAmount = 0;
        uint256 tReflectionsFeeAmount = 0;
        if(_areFeesEnabled && !(_isExcludedFromFees[from] || _isExcludedFromFees[to])) {
            if(from == address(_pancakePair)){
                tManagementFeeAmount = tAmount.mul(_managementFeeBuy).div(100);
                tReserveFeeAmount = tAmount.mul(_reserveFeeBuy).div(100);
                tReflectionsFeeAmount = tAmount.mul(_reflectionFeeBuy).div(100);
            } else if (to == address(_pancakePair)){
                tManagementFeeAmount = tAmount.mul(_managementFeeSell).div(100);
                tReserveFeeAmount = tAmount.mul(_reserveFeeSell).div(100);
                tReflectionsFeeAmount = tAmount.mul(_reflectionFeeSell).div(100);
            }
        }

        // calculate token / reflection transfer amounts with fees taken
        uint256 tTransferAmount = tAmount.sub(tManagementFeeAmount).sub(tReserveFeeAmount).sub(tReflectionsFeeAmount);
        uint256 rAmount = tAmount.mul(currentReflectionRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentReflectionRate);
        
        // distribute fees
        if(_areFeesEnabled && !(_isExcludedFromFees[to] || _isExcludedFromFees[from])){
            if(_isAutoFeeLiquifyEnabled && !_isInternallySwapping) {
                if((_managementFeesTAmountPendingLiquidation + _reserveFeesTAmountPendingLiquidation) >= _minPendingFeesForAutoLiquify){ // && to == address(_pancakePair) ???
                    _liquidateFees(_autoLiquifyFactor);
                }
            }

            _tOwned[address(this)] = _tOwned[address(this)].add(tManagementFeeAmount + tReserveFeeAmount);
            _rOwned[address(this)] = _rOwned[address(this)].add((tManagementFeeAmount + tReserveFeeAmount).mul(currentReflectionRate));

            emit TakeFees(tManagementFeeAmount + tReserveFeeAmount);

            _managementFeesTAmountPendingLiquidation = _managementFeesTAmountPendingLiquidation.add(tManagementFeeAmount);
            _reserveFeesTAmountPendingLiquidation = _reserveFeesTAmountPendingLiquidation.add(tReserveFeeAmount);
            _totalFeesTAmountPendingLiquidation = _managementFeesTAmountPendingLiquidation + _reserveFeesTAmountPendingLiquidation;

            _totalTAmountInEscrow = balanceOf(address(this)).sub(_totalFeesTAmountPendingLiquidation);

            _rTotal = _rTotal.sub(tReflectionsFeeAmount.mul(currentReflectionRate));
            emit ReflectTokens(tReflectionsFeeAmount);
        }

        // perform auto token buybacks and token reinjectons from escrow
        if(to == address(_pancakePair) && !_isInternallySwapping){
            if(_isAutoBuybackEnabled && address(this).balance >= _minReserveWETHForAutoBuyback){
                _buybackTokens(_autoBuybackFactor);
            }

            if(_isAutoReinjectEnabled && address(this).balance >= _minReserveWETHForAutoReinject){
                _reinjectTokensFromEscrow(_autoReinjectFactor);
            }
        }
        

        // process transfer of tokens / reflections
        if(_isExcludedFromReflections[from] && !_isExcludedFromReflections[to]){
            _tOwned[from] = _tOwned[from].sub(tAmount);
            _rOwned[from] = _rOwned[from].sub(rAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);
        } else if(!_isExcludedFromReflections[from] && _isExcludedFromReflections[to]) {
            _rOwned[from] = _rOwned[from].sub(rAmount);
            _tOwned[to] = _tOwned[to].add(tTransferAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);
        } else if(_isExcludedFromReflections[from] && _isExcludedFromReflections[to]) {
            _tOwned[from] = _tOwned[from].sub(tAmount);
            _rOwned[from] = _rOwned[from].sub(rAmount);
            _tOwned[to] = _tOwned[to].add(tTransferAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);
        } else {
            _rOwned[from] = _rOwned[from].sub(rAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);
        }

        emit Transfer(from, to, tTransferAmount);
    }

    /* @dev: internally view the current tokens to reflections rate*/
    function _getCurrentReflectionRate() private view returns (uint256) {
        (uint256 rSupplyCurrent, uint256 tSupplyCurrent) = _getCurrentSupplies();
        return rSupplyCurrent.div(tSupplyCurrent);
    }

    /* @dev: internally view the current supplies of reflections & tokens */
    function _getCurrentSupplies() private view returns (uint256, uint256) {
        uint256 rSupplyCurrent = _rTotal;
        uint256 tSupplyCurrent = _tTotal;
        for(uint256 i = 0; i < _excludedFromReflections.length; i++) {
            if(_rOwned[_excludedFromReflections[i]] > rSupplyCurrent || _tOwned[_excludedFromReflections[i]] > tSupplyCurrent) {
                return (_rTotal, _tTotal);
            }
            rSupplyCurrent = rSupplyCurrent.sub(_rOwned[_excludedFromReflections[i]]);
            tSupplyCurrent = tSupplyCurrent.sub(_tOwned[_excludedFromReflections[i]]);
        }
        if(rSupplyCurrent < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }
        return (rSupplyCurrent, tSupplyCurrent);
    }

    /* @dev: internally liquidate tokens during transfers */
    function _liquidateFees(uint256 liquifyFactor) private internalSwapLock() {
        require(liquifyFactor <= 100, "liquify factor cannot exceed 100");

        uint256 tManagementFeesAmountToLiquidate = _managementFeesTAmountPendingLiquidation.mul(liquifyFactor).div(100);
        uint256 tReserveFeesAmountToLiquidate = _reserveFeesTAmountPendingLiquidation.mul(liquifyFactor).div(100);
        
        uint256 tTotalFeesAmountToLiquidate = tManagementFeesAmountToLiquidate + tReserveFeesAmountToLiquidate;

        uint256 preSwapContractBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _approve(address(this), address(_pancakeRouter), tTotalFeesAmountToLiquidate);
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tTotalFeesAmountToLiquidate, 0, path, address(this), block.timestamp);

        emit SwapTokensForETH(tTotalFeesAmountToLiquidate, path);
        
        _managementFeesTAmountPendingLiquidation = _managementFeesTAmountPendingLiquidation.sub(tManagementFeesAmountToLiquidate);
        _reserveFeesTAmountPendingLiquidation = _reserveFeesTAmountPendingLiquidation.sub(tReserveFeesAmountToLiquidate);
        _totalFeesTAmountPendingLiquidation = _managementFeesTAmountPendingLiquidation + _reserveFeesTAmountPendingLiquidation;

        _totalTAmountInEscrow = balanceOf(address(this)).sub(_totalFeesTAmountPendingLiquidation);

        uint256 postSwapContractBalanceDifference = address(this).balance.sub(preSwapContractBalance);

        _managementFeesReciever.transfer(postSwapContractBalanceDifference.mul(tManagementFeesAmountToLiquidate).div(tTotalFeesAmountToLiquidate));
    }

    /* @dev: perform a token buyback using reserve BNB */
    function _buybackTokens(uint256 buybackFactor) private internalSwapLock() {
        require(buybackFactor <= 100, "buyback factor cannot exceed 100");

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);

        uint256 reserveWETHToUse = address(this).balance.mul(buybackFactor).div(100);

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: reserveWETHToUse}(0, path, address(this), block.timestamp.add(300));

        emit SwapETHForTokens(reserveWETHToUse, path);

        _totalTAmountInEscrow = balanceOf(address(this)).sub(_totalFeesTAmountPendingLiquidation);
    }

    /* @dev: perform a token reinjection using reserve tokens / BNB */
    function _reinjectTokensFromEscrow(uint256 reinjectFactor) private {
        require(reinjectFactor <= 100, "reinject factor acnnot exceed 100");

        uint256 reserveWETHToUse = address(this).balance.mul(reinjectFactor).div(100);
        (uint112 reserve0, uint112 reserve1,) = _pancakePair.getReserves();
        uint256 reserveTokensToUse = _pancakeRouter.getAmountOut(reserveWETHToUse, reserve1, reserve0);

        if(reserveWETHToUse > balanceOf(address(this))){
            reserveWETHToUse = balanceOf(address(this));
        }

        _approve(address(this), address(_pancakeRouter), reserveTokensToUse);
        _pancakeRouter.addLiquidityETH{value: reserveWETHToUse}(address(this), reserveTokensToUse, 0, 0, address(this), block.timestamp);

        emit AddLiquidity(reserveWETHToUse, reserveTokensToUse);
    }


    /* @dev: exclude account from reflections */
    function excludeFromReflections(address account) public onlyManagement() returns (bool) {
        require(!_isExcludedFromReflections[account], "account is already excluded from reflections");
        if(_rOwned[account] > 0) {
            _tOwned[account] = _rOwned[account].div(_getCurrentReflectionRate());
        }
        _isExcludedFromReflections[account] = true;
        _excludedFromReflections.push(account);
        return true;
    }

    /* @dev: include account in reflections */
    function includeInReflections(address account) public onlyManagement() returns (bool) {
        require(account != address(this), "cannot include token address in reflections");
        require(account != address(_pancakePair), "cannot include pancake pair in reflections");
        require(_isExcludedFromReflections[account], "account is already included in reflections");
        for(uint256 i = 0; i < _excludedFromReflections.length; i++) {
            if(_excludedFromReflections[i] == account){
                _excludedFromReflections[i] = _excludedFromReflections[_excludedFromReflections.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReflections[account] = false;
                _excludedFromReflections.pop();
                break;
            }
        }
        return true;
    }

    /* @dev: */
    function excludeFromFees(address account) public onlyManagement() returns (bool) {
        _isExcludedFromFees[account] = true;
        return true;
    }

    /* @dev: */
    function includeInFees(address account) public onlyManagement() returns (bool) {
        require(account != address(this), "cannot include token address in fees");
        _isExcludedFromFees[account] = false;
        return true;
    }

    /* @dev: */
    function excludeFromLimits(address account) public onlyManagement() returns (bool) {
        _isExcludedFromLimits[account] = true;
        return true;
    }

    /* @dev: */
    function includeInLimits(address account) public onlyManagement() returns (bool) {
        require(account != address(this), "cannot include token address in limits");
        _isExcludedFromLimits[account] = false;
        return true;
    }


    /* @dev: */
    function setManagementFeesReciever(address managementFeesReciever) public onlyManagement() returns (bool) {
        _managementFeesReciever = payable(managementFeesReciever);
        return true;
    }

    /* @dev: */
    function setFeesEnabled(bool areFeesEnabled) public onlyManagement() returns (bool) {
        require(!_isTokenPresale, "cannot enable fees for token in presale");
        _areFeesEnabled = areFeesEnabled;
        if(!areFeesEnabled){
            _isAutoFeeLiquifyEnabled = false;
        }
        return true;
    }

    /* @dev: */
    function setManagementFeeBuy(uint256 managementFeeBuy) public onlyManagement() returns (bool) {
        require(_buyFeesTotal - _managementFeeBuy + managementFeeBuy <= 25, "total buy fees cannot exceed 25");
        _managementFeeBuy = managementFeeBuy;
        _buyFeesTotal = _managementFeeBuy + _reserveFeeBuy + _reflectionFeeBuy;
        return true;
    }

    /* @dev: */
    function setManagementFeeSell(uint256 managementFeeSell) public onlyManagement() returns (bool) {
        require(_sellFeesTotal - _managementFeeSell + managementFeeSell <= 25, "total sell fees cannot exceed 25");
        _managementFeeSell = managementFeeSell;
        _sellFeesTotal = _managementFeeSell + _reserveFeeSell + _reflectionFeeSell;
        return true;
    }

    /* @dev: */
    function setReserveFeeBuy(uint256 reserveFeeBuy) public onlyManagement() returns (bool) {
        require(_buyFeesTotal - _reserveFeeBuy + reserveFeeBuy <= 25, "total buy fees cannot exceed 25");
        _reserveFeeBuy = reserveFeeBuy;
        _buyFeesTotal = _managementFeeBuy + _reserveFeeBuy + _reflectionFeeBuy;
        return true;
    }

    /* @dev: */
    function setReserveFeeSell(uint256 reserveFeeSell) public onlyManagement() returns (bool) {
        require(_sellFeesTotal - _reserveFeeSell + reserveFeeSell <= 25, "total sell fees cannot exceed 25");
        _reserveFeeSell = reserveFeeSell;
        _sellFeesTotal = _managementFeeSell + _reserveFeeSell + _reflectionFeeSell;
        return true;
    }

    /* @dev: */
    function setReflectionsFeeBuy(uint256 reflectionsFeeBuy) public onlyManagement() returns (bool) {
        require(_buyFeesTotal - _reflectionFeeBuy + reflectionsFeeBuy <= 25, "total buy fees cannot exceed 25");
        _reflectionFeeBuy = reflectionsFeeBuy;
        _buyFeesTotal = _managementFeeBuy + _reserveFeeBuy + _reflectionFeeBuy;
        return true;
    }

    /* @dev: */
    function setReflectionsFeeSell(uint256 reflectionsFeeSell) public onlyManagement() returns (bool) {
        require(_sellFeesTotal - _reflectionFeeSell + reflectionsFeeSell <= 125, "total sell fees cannot exceed 25");
        _reflectionFeeSell = reflectionsFeeSell;
        _sellFeesTotal = _managementFeeSell + _reserveFeeSell + _reflectionFeeSell;
        return true;
    }

    /* @dev: */
    function setAutoLiquifyEnabled(bool isAutoLiquifyEnabled) public onlyManagement() returns (bool) {
        require(_areFeesEnabled, "cannot enable auto fee liquify when fees are disabled");
        _isAutoFeeLiquifyEnabled = isAutoLiquifyEnabled;
        return true;
    }

    /* @dev: */
    function setAutoLiquifyFactor(uint256 autoLiquifyFactor) public onlyManagement() returns (bool) {
        require(autoLiquifyFactor <= 100, "auto liquify factor cannot eceed 100");
        _autoLiquifyFactor = autoLiquifyFactor;
        return true;
    }

    /* @dev: */
    function setMinPendingFeesForAutoLiquify(uint256 minPendingFeesForAutoLiquify) public onlyManagement() returns (bool) {
        _minPendingFeesForAutoLiquify = minPendingFeesForAutoLiquify;
        return true;
    }

    /* @dev: */
    function setAutoBuybackEnabled(bool isAutoBuybackEnabled) public onlyManagement() returns (bool) {
        require(!_isTokenPresale, "cannot enable auto buyback for token in presale");
        _isAutoBuybackEnabled = isAutoBuybackEnabled;
        return true;
    }

    /* @dev: */
    function setMinReserveWETHForAutoBuyback(uint256 minReserveWETHForAutoBuyback) public onlyManagement() returns (bool) {
        _minReserveWETHForAutoBuyback = minReserveWETHForAutoBuyback;
        return true;
    }

    /* @dev: */
    function setAutoBuybackFactor(uint256 autoBuybackFactor) public onlyManagement() returns (bool) {
        require(autoBuybackFactor <= 100, "auto buyback factor cannot exceed 100");
        _autoBuybackFactor = autoBuybackFactor;
        return true;
    }

    /* @dev: */
    function setAutoReinjectEnabled(bool isAutoReinjectEnabled) public onlyManagement() returns (bool) {
        require(!_isTokenPresale, "cannot enable auto reinject for token in presale");
        _isAutoReinjectEnabled = isAutoReinjectEnabled;
        return true;
    }

    /* @dev: */
    function setMinReserveWETHForAutoReinject(uint256 minReserveWETHForAutoReinject) public onlyManagement() returns (bool) {
        _minReserveWETHForAutoReinject = minReserveWETHForAutoReinject;
        return true;
    }

    /* @dev: */
    function setAutoReinjectFactor(uint256 autoReinjectFactor) public onlyManagement() returns (bool){
        require(autoReinjectFactor <= 100, "auto reinject factor cannot exceed 100");
        _autoReinjectFactor = autoReinjectFactor;
        return true;
    }

    /* @dev: */
    function setLimitsEnabled(bool areLimitsEnabled) public onlyManagement() returns (bool) {
        require(!_isTokenPresale, "cannot enable limits for token in presale");
        _areLimitsEnabled = areLimitsEnabled;
        return true;
    }

    /* @dev: */
    function setMaxTransferAmount(uint256 maxTransferAmount) public onlyManagement() returns (bool) {
        require(maxTransferAmount <= _tTotal, "max transfer amount cannot exceed token supply");
        _maxTransferAmount = maxTransferAmount;
        return true;
    }

    /* @dev: */
    function performManualBuyback(uint256 buybackFactor) public onlyManagement() returns (bool) {
        require(buybackFactor <= 100, "buyback factor cannot exceed 100");
        _buybackTokens(address(this).balance.mul(buybackFactor).div(100));
        return true;
    }

    /* @dev: */
    function performManualTokenReinjectonFromEscrow(uint256 reinjectFactor) public onlyManagement() returns (bool) {
        _reinjectTokensFromEscrow(reinjectFactor);
        return true;
    }

    /* @dev: */
    function performManualFeeLiquidation(uint256 liquifyFactor) public onlyManagement() returns (bool) {
        _liquidateFees(liquifyFactor);
        return true;
    }

    
    /* @dev */
    function endTokenPresaleAndInjectInitialLiquidity() public payable onlyManagement() returns (bool) {
        require(_isTokenPresale, "token must be in presale");

        _isTokenPresale = false;

        _transfer(_msgSender(), address(this), balanceOf(_msgSender()));

        uint256 amountTokensToInject = balanceOf(address(this));
        _approve(address(this), address(_pancakeRouter), amountTokensToInject);
        _pancakeRouter.addLiquidityETH{value: msg.value}(address(this), amountTokensToInject, 0, 0, address(this), block.timestamp);

        emit AddLiquidity(msg.value, amountTokensToInject);

        _areLimitsEnabled = true;
        _areFeesEnabled = true;
        _isAutoFeeLiquifyEnabled = true;
        _isAutoBuybackEnabled = true;
        _isAutoReinjectEnabled = true;

        emit EndPresale();

        return true;
    }



    /* @dev: */
    modifier internalSwapLock() {
        _isInternallySwapping = true;
        _;
        _isInternallySwapping = false;
    }



    /* @dev: payable recieve method for recieving BNB */
    receive() external payable { }



    /* @dev: */
    event SwapTokensForETH(uint256 amountTokens, address[] path);

    /* @dev: */
    event SwapETHForTokens(uint256 amountWETH, address[] path);

    /* @dev : */
    event AddLiquidity(uint256 amountWETH, uint256 amountTokens);

    /* @dev: */
    event MintTokens(uint256 amountTokens);

    /* @dev: */
    event EndPresale();

    /* @dev: */
    event TakeFees(uint256 amountTokens);

    /* @dev: */
    event ReflectTokens(uint256 amountTokens);

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract Callable {

    constructor() { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
    
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import './Callable.sol';


contract Manageable is Callable {

    address private _executiveManager;
    mapping(address => bool) private _isManager;
    address[] private _managers;

    bool private _managementIsLocked = false;
    uint256 private _managementUnlockTime = 0;



    constructor () {
        _executiveManager = _msgSender();
        _isManager[_executiveManager] = true;
        _managers.push(_executiveManager);

        emit ManagerAdded(_executiveManager);
        emit ExecutiveManagerChanged(address(0), _executiveManager);
    }



    function executiveManager() public view returns (address) {
        return _executiveManager;
    }

    function isManager(address account) public view returns (bool) {
        return _isManager[account];
    }

    function managementIsLocked() public view returns (bool) {
        return _managementIsLocked;
    }

    function timeToManagementUnlock() public view returns (uint256) {
        return block.timestamp >= _managementUnlockTime ? 0 : _managementUnlockTime - block.timestamp;
    }
    
    function addManager(address newManager) public onlyExecutive() returns (bool) {
        require(!_isManager[newManager], "Account is already a manager");
        require(newManager != address(0), "0 address cannot be made manager");

        _isManager[newManager] = true;
        _managers.push(newManager);

        emit ManagerAdded(newManager);

        return true;
    }

    function removeManager(address managerToRemove) public onlyExecutive() returns (bool) {
        require(_isManager[managerToRemove], "Account is already not a manager");
        require(managerToRemove != _executiveManager, "Executive manager cannot be removed");

        _isManager[managerToRemove] = false;
        for(uint256 i = 0; i < _managers.length; i++) {
            if(_managers[i] == managerToRemove){
                _managers[i] = _managers[_managers.length - 1];
                _managers.pop();
                break;
            }
        }

        emit ManagerRemoved(managerToRemove);

        return true;
    }

    function changeExecutiveManager(address newExecutiveManager) public onlyExecutive() returns (bool) {
        require(_isManager[newExecutiveManager], "New executive must already be a manager");
        require(newExecutiveManager != _executiveManager, "Manager is already the executive");

        emit ExecutiveManagerChanged(_executiveManager, newExecutiveManager);

        _executiveManager = newExecutiveManager;

        return true;
    }

    function lockManagement(uint256 lockDuration) public onlyExecutive() returns (bool) {
        _managementIsLocked = true;
        _managementUnlockTime = block.timestamp + lockDuration;

        emit ManagementLocked(lockDuration);

        return true;
    }

    function unlockManagement() public onlyExecutive() returns (bool) {
        _managementIsLocked = false;
        _managementUnlockTime = 0;

        emit ManagementUnlocked();

        return true;
    }

    function renounceManagement() public onlyExecutive() returns (bool) {
        while(_managers.length > 0) {
            _isManager[_managers[_managers.length - 1]] = false;

            emit ManagerRemoved(_managers[_managers.length - 1]);

            if(_managers[_managers.length - 1] == _executiveManager){
                emit ExecutiveManagerChanged(_executiveManager, address(0));
                _executiveManager = address(0);
            }

            _managers.pop();
        }

        emit ManagementRenounced();

        return true;
    }



    event ManagerAdded(address addedManager);
    event ManagerRemoved(address removedManager);
    event ExecutiveManagerChanged(address indexed previousExecutiveManager, address indexed newExecutiveManager);
    event ManagementLocked(uint256 lockDuration);
    event ManagementUnlocked();
    event ManagementRenounced();



    modifier onlyExecutive() {
        require(_msgSender() == _executiveManager, "Caller is not the executive manager");
        require(!_managementIsLocked || block.timestamp >= _managementUnlockTime, "Management is locked");
        _;
    }

    modifier onlyManagement() {
        require(_isManager[_msgSender()], "Caller is not a manager");
        require(!_managementIsLocked, "Management is locked");
        _;
    }

}

/* ------------------BEP-20 TOEKN INTERFACE------------------ */
/* https://github.com/binance-chain/BEPs/blob/master/BEP20.md */


// SPDX-License-Identifier: CC0
pragma solidity >=0.5.0;


interface IBEP20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IPancakeFactory {

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

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IPancakePair {

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

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.2;

interface IPancakeRouter01 {

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

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
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
pragma solidity ^0.8.6;


library SackMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if(b >= a){
            return 0;
        }
        uint256 c = a - b;
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }



    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        uint256 c = a / b;
        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "modulo by zero");
        return a % b;
    }

}

