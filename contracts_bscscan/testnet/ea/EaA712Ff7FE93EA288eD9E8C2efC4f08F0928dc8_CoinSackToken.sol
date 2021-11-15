/*
    ___           _              __             ___               
     | |_   _    /   _  o ._    (_   _.  _ |     |  _  |   _  ._  
     | | | (/_   \_ (_) | | |   __) (_| (_ |<    | (_) |< (/_ | |  

    ------------------ABOUT THE COIN SACK TOKEN------------------
    Token Features:
    - Standard 15% transfer fee
    - Instant sell fee of 35% when tokens are held for < 30 days
    - Refi static holder rewards
    - Strategic reserve with automatic token buyback capabilities
    - Ability to reinject bought-back tokens as liquidity 
    - Automatically liquidated management fee

    Tokenomics:
    - Total supply of 100 billion tokens
    - 3 Decimal point fungibility
    - Standard 15% transfer fee distributed as follows:
        8% strategic reserve liquidation
        3% management liquidation
        4% refi holder rewards distribution
    - Instant 35% sell fee distributed as follows:
        20% strategic reserve liquidation
        5% management liquidation
        10% refi holder rewards distribution

    Development To-dos:
    - add automatic token buyback capabilities
    - refactor token events
    - major token function structure refactor?
    - add end token presale management method

*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;



// import contract context
import './contexts/Manageable.sol';

// import solidity interfaces
import './interfaces/IBEP20.sol';
import './interfaces/IPancakeFactory.sol';
import './interfaces/IPancakePair.sol';
import './interfaces/IPancakeRouter02.sol';

// import solidity libraries
import './libraries/SafeMath.sol';
import './libraries/Address.sol';



// The Coin Sack Token Smart Contract
contract CoinSackToken is IBEP20, Manageable {
    
    // use SafeMath & Address libraries
    using SafeMath for uint256;
    using Address for address;


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
    uint256 public _managementFeeStandard = 3;
    uint256 public _reserveFeeStandard = 8;
    uint256 public _reflectionsFeeStandard = 4;

    uint256 public _reserveFeeInstant = 20;
    uint256 public _managementFeeInstant = 5;
    uint256 public _reflectionsFeeInstant = 10;
    uint256 public _instantFeesTimeout = 5400; // 1.5 hours  // 2592000; // 30 days

    uint256 public _standardFeesTotal = _managementFeeStandard + _reserveFeeStandard + _reflectionsFeeStandard;
    uint256 public _instantFeesTotal = _managementFeeInstant + _reserveFeeInstant + _reflectionsFeeInstant;

    mapping (address => mapping (uint256 => uint256)) private _txTimestamps;
    mapping (address => mapping (uint256 => uint256)) private _txAmounts;
    mapping (address => uint256) private _tSubjectToInstantFees;


    // pancake router & pair 
    IPancakeRouter02 public immutable _pancakeRouter;
    IPancakePair public immutable _pancakePair;


    // management fees reciever
    address payable public _managementAddress;


    // auto fee liquification
    bool public _isAutoFeeLiquifyEnabled = false;
    uint256 public _minPendingFeesForLiquidation = 500 * 10**_decimals;
    bool private _isInternalLiquifyLocked = false;
    uint256 private _pendingManagementFeesForLiquidation = 0;
    uint256 private _pendingReserveFeesForLiquidation = 0;



    /* @dev: Coin Sack Token contract constructor */
    constructor() {
        // initialize pancake router & pair
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // testnet pancake router
        //IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet pancake router
        _pancakeRouter = pancakeRouter;
        IPancakePair pancakePair = IPancakePair(IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH()));
        _pancakePair = pancakePair;

        // exclude pancake pair from reflections
        _isExcludedFromReflections[address(pancakePair)] = true;
        _excludedFromReflections.push(address(pancakePair));

        // exclude token contract from fees, limits, & reflections
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromReflections[address(this)] = true;
        _excludedFromReflections.push(address(this));

        // set management address; exclude from fees, limits, & reflections
        _managementAddress = _msgSender();
        _isExcludedFromFees[_managementAddress] = true;
        _isExcludedFromLimits[_managementAddress] = true;
        _isExcludedFromReflections[_managementAddress] = true;
        _excludedFromReflections.push(_managementAddress);

        // give initial token supply to management address
        _tOwned[_managementAddress] = _tTotal;
        emit Transfer(address(0), _managementAddress, _tTotal);
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
        _approve(owner, _msgSender(), _tAllowances[owner][_msgSender()].sub(amount, "transfer amount exceeds spender's allowance"));
        _transfer(owner, to, amount);
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
        require(from != address(0), "cannot transfer tokens from the zero address");
        require(to != address(0), "cannot transfer tokens to the zero address");
        require(tAmount > 0, "cannot transfer zero tokens");
        require(tAmount <= _maxTransferAmount || !_areLimitsEnabled || _isExcludedFromLimits[from] || _isExcludedFromLimits[to], "transfer amount exceeds transaction limit");

        uint256 fromAccountTBalance = balanceOf(from);
        require(fromAccountTBalance >= tAmount, "insufficent from account token balance");

        uint256 currentReflectionRate = _getCurrentReflectionRate();

        // calculate transaction fee amounts
        uint256 tManagementFeeAmount;
        uint256 tReserveFeeAmount;
        uint256 tReflectionsFeeAmount;
        if(!_areFeesEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            tManagementFeeAmount = 0;
            tReserveFeeAmount = 0;
            tReflectionsFeeAmount = 0;
        } else if(to == address(_pancakePair)) {
            while(_txAmounts[from][0] != 0 && _txTimestamps[from][0] + _instantFeesTimeout <= block.timestamp) {
                _tSubjectToInstantFees[from] = _tSubjectToInstantFees[from].sub(_txAmounts[from][0]);
                for(uint256 i = 0; _txAmounts[from][i] != 0; i++) {
                    _txAmounts[from][i] = _txAmounts[from][i+1];
                    _txTimestamps[from][i] = _txTimestamps[from][i+1];
                }
            }

            uint256 tAmountFreeFromInstantFees = fromAccountTBalance.sub(_tSubjectToInstantFees[from]);
            if(tAmount > tAmountFreeFromInstantFees) {
                uint256 tAmountSubjectToInstantFees = tAmount.sub(tAmountFreeFromInstantFees);
                tManagementFeeAmount = tAmountFreeFromInstantFees.mul(_managementFeeStandard).div(100).add(tAmountSubjectToInstantFees.mul(_managementFeeInstant).div(100));
                tReserveFeeAmount = tAmountFreeFromInstantFees.mul(_reserveFeeStandard).div(100).add(tAmountSubjectToInstantFees.mul(_reserveFeeInstant).div(100));
                tReflectionsFeeAmount = tAmountFreeFromInstantFees.mul(_reflectionsFeeStandard).div(100).add(tAmountSubjectToInstantFees.mul(_reflectionsFeeInstant).div(100));
            } else {
                tManagementFeeAmount = tAmount.mul(_managementFeeStandard).div(100);
                tReserveFeeAmount = tAmount.mul(_reserveFeeStandard).div(100);
                tReflectionsFeeAmount = tAmount.mul(_reflectionsFeeStandard).div(100);
            }
        } else {
            tManagementFeeAmount = tAmount.mul(_managementFeeStandard).div(100);
            tReserveFeeAmount = tAmount.mul(_reserveFeeStandard).div(100);
            tReflectionsFeeAmount = tAmount.mul(_reflectionsFeeStandard).div(100);
        }

        // calculate token / reflection transfer amounts with fees taken
        uint256 tTransferAmount = tAmount.sub(tManagementFeeAmount).sub(tReserveFeeAmount).sub(tReflectionsFeeAmount);
        uint256 rAmount = tAmount.mul(currentReflectionRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentReflectionRate);

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
        
        // track new tokens subject to instant fees
        if(to != address(_pancakePair) && !_isExcludedFromFees[to] && _areFeesEnabled) { 
            _tSubjectToInstantFees[to] = _tSubjectToInstantFees[to].add(tTransferAmount);
            uint k = 0;
            while(_txAmounts[to][k] != 0){
                k++;
            }
            _txAmounts[to][k] = tTransferAmount;
            _txTimestamps[to][k] = block.timestamp;
        }

        // publish transfer event
        emit Transfer(from, to, tTransferAmount);
        
        // distribute fees
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && _areFeesEnabled){
            if(_isAutoFeeLiquifyEnabled) {
                _pendingManagementFeesForLiquidation = _pendingManagementFeesForLiquidation.add(tManagementFeeAmount);
                _pendingReserveFeesForLiquidation = _pendingReserveFeesForLiquidation.add(tReserveFeeAmount);

                _tOwned[address(this)] = _tOwned[address(this)].add(tManagementFeeAmount + tReserveFeeAmount);

                if(!_isInternalLiquifyLocked && (_pendingManagementFeesForLiquidation + _pendingReserveFeesForLiquidation) >= _minPendingFeesForLiquidation){
                    _liquidateFeesInternal(_pendingManagementFeesForLiquidation, _pendingReserveFeesForLiquidation);
                    _pendingManagementFeesForLiquidation = 0;
                    _pendingReserveFeesForLiquidation = 0;
                }
            } else {
                _tOwned[address(this)] = _tOwned[address(this)].add(tReserveFeeAmount);
                if(_isExcludedFromReflections[_managementAddress]){
                    _tOwned[_managementAddress] = _tOwned[_managementAddress].add(tManagementFeeAmount);
                } else {
                    _rOwned[_managementAddress] = _rOwned[_managementAddress].add(tManagementFeeAmount.mul(currentReflectionRate));
                }
            }
        
            _rTotal = _rTotal.sub(tReflectionsFeeAmount.mul(currentReflectionRate));
        }
        
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
    function _liquidateFeesInternal(uint256 tManagementFeeAmount, uint256 tReserveFeeAmount) private internalLiquifyLock() {
        uint256 tTotalFeeAmount = tManagementFeeAmount + tReserveFeeAmount;

        uint256 preSwapContractBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _approve(address(this), address(_pancakeRouter), tTotalFeeAmount);
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tTotalFeeAmount, 0, path, address(this), block.timestamp);

        uint256 postSwapBalance = address(this).balance;

        uint256 owedToManagement = postSwapBalance.sub(preSwapContractBalance).mul(tManagementFeeAmount).div(tTotalFeeAmount);
        _managementAddress.transfer(owedToManagement);
    }

    /* @dev: perform a token buyback using reserve BNB */
    function _buybackTokens(uint256 reserveWETHToUse) private internalLiquifyLock() {
        require(address(this).balance >= reserveWETHToUse, "Not enough WETH in reserve");

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: reserveWETHToUse}(0, path, address(this), block.timestamp.add(300));
    }

    /* @dev: perform a token reinjection using reserve tokens / BNB */
    function _reinjectTokensAsLiquidity(uint256 reserveWETHToUse, uint256 reserveTokenToUse) private {
        require(address(this).balance >= reserveWETHToUse, "Not enough WETH in reserve");
        require(balanceOf(address(this)) >= reserveTokenToUse, "Not enough token in reserve");

        _approve(address(this), address(_pancakeRouter), reserveTokenToUse);

        _pancakeRouter.addLiquidityETH{value: reserveWETHToUse}(address(this), reserveTokenToUse, 0, 0, address(this), block.timestamp);
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
        require(account != address(this), "Cannot include token address in fees");
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
        require(account != address(this), "Cannot include token address in limits");
        _isExcludedFromLimits[account] = false;
        return true;
    }


    /* @dev: */
    function setManagementAddress(address managementAddress) public onlyManagement() returns (bool) {
        _managementAddress = payable(managementAddress);

        _isExcludedFromFees[_managementAddress] = true;
        _isExcludedFromReflections[_managementAddress] = true;
        _isExcludedFromLimits[_managementAddress] = true;

        return true;
    }

    /* @dev: */
    function setFeesEnabled(bool areFeesEnabled) public onlyManagement() returns (bool) {
        _areFeesEnabled = areFeesEnabled;
        return true;
    }

    /* @dev: */
    function setManagementFeeStandard(uint256 managementFeeStandard) public onlyManagement() returns (bool) {
        require(_standardFeesTotal - _managementFeeStandard + managementFeeStandard <= 100, "Total standard fees cannot exceed 100");

        _managementFeeStandard = managementFeeStandard;
        _standardFeesTotal = _managementFeeStandard + _reserveFeeStandard + _reflectionsFeeStandard;

        return true;
    }

    /* @dev: */
    function setManagementFeeInstant(uint256 managementFeeInstant) public onlyManagement() returns (bool) {
        require(_instantFeesTotal - _managementFeeInstant + managementFeeInstant <= 100, "Total instant fees cannot exceed 100");

        _managementFeeInstant = managementFeeInstant;
        _instantFeesTotal = _managementFeeInstant + _reserveFeeInstant + _reflectionsFeeInstant;

        return true;
    }

    /* @dev: */
    function setReserveFeeStandard(uint256 reserveFeeStandard) public onlyManagement() returns (bool) {
        require(_standardFeesTotal - _reserveFeeStandard + reserveFeeStandard <= 100, "Total standard fees cannot exceed 100");

        _reserveFeeStandard = reserveFeeStandard;
        _standardFeesTotal = _managementFeeStandard + _reserveFeeStandard + _reflectionsFeeStandard;

        return true;
    }

    /* @dev: */
    function setReserveFeeInstant(uint256 reserveFeeInstant) public onlyManagement() returns (bool) {
        require(_instantFeesTotal - _reserveFeeInstant + reserveFeeInstant <= 100, "Total instant fees cannot exceed 100");

        _reserveFeeInstant = reserveFeeInstant;
        _instantFeesTotal = _managementFeeInstant + _reserveFeeInstant + _reflectionsFeeInstant;

        return true;
    }

    /* @dev: */
    function setReflectionsFeeStandard(uint256 reflectionsFeeStandard) public onlyManagement() returns (bool) {
        require(_standardFeesTotal - _reflectionsFeeStandard + reflectionsFeeStandard <= 100, "Total standard fees cannot exceed 100");

        _reflectionsFeeStandard = reflectionsFeeStandard;
        _standardFeesTotal = _managementFeeStandard + _reserveFeeStandard + _reflectionsFeeStandard;

        return true;
    }

    /* @dev: */
    function setReflectionsFeeInstant(uint256 reflectionsFeeInstant) public onlyManagement() returns (bool) {
        require(_instantFeesTotal - _reflectionsFeeInstant + reflectionsFeeInstant <= 100, "Total instant fees cannot exceed 100");

        _reflectionsFeeInstant = reflectionsFeeInstant;
        _instantFeesTotal = _managementFeeInstant + _reserveFeeInstant + _reflectionsFeeInstant;

        return true;
    }

    /* @dev: */
    function setInstantFeesTimeout(uint256 instantFeesTimeout) public onlyManagement() returns (bool) {
        _instantFeesTimeout = instantFeesTimeout;
        return true;
    }

    /* @dev: */
    function setAutoLiquifyEnabled(bool isAutoLiquifyEnabled) public onlyManagement() returns (bool) {
        _isAutoFeeLiquifyEnabled = isAutoLiquifyEnabled;
        return true;
    }

    /* @dev: */
    function setMinPendingFeesForLiquidation(uint256 minPendingFeesForLiquidation) public onlyManagement() returns (bool) {
        _minPendingFeesForLiquidation = minPendingFeesForLiquidation;
        return true;
    }

    /* @dev: */
    function setLimitsEnabled(bool areLimitsEnabled) public onlyManagement() returns (bool) {
        _areLimitsEnabled = areLimitsEnabled;
        return true;
    }

    /* @dev: */
    function setMaxTransferAmount(uint256 maxTransferAmount) public onlyManagement() returns (bool) {
        require(maxTransferAmount <= _tTotal, "Max transfer amount cannot exceed token supply");

        _maxTransferAmount = maxTransferAmount;

        return true;
    }

    /* @dev: */
    function performManualBuyback(uint256 reserveWETHToUse) public onlyManagement() returns (bool) {
        _buybackTokens(reserveWETHToUse);
        return true;
    }

    /* @dev: */
    function performManualLiquidityReinjecton(uint256 reserveWETHToUse, uint256 reserveTokenToUse) public onlyManagement() returns (bool) {
        _reinjectTokensAsLiquidity(reserveWETHToUse, reserveTokenToUse);
        return true;
    }



    /* @dev: */
    modifier internalLiquifyLock() {
        _isInternalLiquifyLocked = true;
        _;
        _isInternalLiquifyLocked = false;
    }



    /* @dev: payable recieve method for recieving BNB */
    receive() external payable { }

}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

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

pragma solidity ^0.8.6;

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

