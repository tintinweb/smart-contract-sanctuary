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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;

interface ISwapRouter is IUniswapV2Router01 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}



contract EpicBuy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable public TEAM_ADDRESS = payable(0x9b0f526c781A16E9F8577D736F68C4F73c42B93A);
    address public immutable BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public lastSale;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromSellCoolDown;
    mapping (address => bool) private _excludedFromAntiWhale;
    mapping (address => bool) private _swapPairs;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "EpicBuy";
    string private _symbol = "EPIC";
    uint8 private _decimals = 9;

    struct AddressFee {
        bool enable;
        uint256 _taxFee;
        uint256 _liquidityFee;
        uint256 _buyTaxFee;
        uint256 _buyLiquidityFee;
        uint256 _sellTaxFee;
        uint256 _sellLiquidityFee;
        uint256 _coolDownPeriod;
    }

    struct SellHistories {
        uint256 time;
        uint256 bnbAmount;
    }

    uint256 public _taxFee = 4;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _buyTaxFee = 4;
    uint256 public _buyLiquidityFee = 10;

    uint256 public _sellTaxFee = 8;
    uint256 public _sellLiquidityFee = 17;

    uint256 public _startTimeForSwap;
    uint256 public _intervalMinutesForSwap = 1 * 1 minutes;

    uint256 public _buyBackRangeRate = 80;

    // Fee per address
    mapping (address => AddressFee) public _addressFees;

    uint256 public marketingDivisor = 3;
    // max transfer amount rate in basis points divide by 1000000
    uint32 public maxTransferAmountRate = 0;
    // 1 billion being the smallest antiwhale
    uint256 public MIN_MAX_TRANSFER_AMOUNT = 1000000000 * 10**9; // 1 billion minimum max
    bool public coolDownEnabled = true;
    uint256 public coolDownPeriod = 30 minutes;
    uint256 public MAX_COOL_DOWN = 7 days;
    uint256 private _maxTransferAmount = 1000000 * 10**6 * 10**9; // 1 trillion
    uint256 private minimumTokensBeforeSwap = 50000 * 10**6 * 10**9; // 50B
    uint256 public buyBackSellLimit = 1 * 10**14;

    // this can only be enabled once (should be after presale is over and liquidity added)
    bool public tradingEnabled;

    // LookBack into historical sale data
    SellHistories[] public _sellHistories;
    bool public _isAutoBuyBack = true;
    uint256 public _buyBackDivisor = 10;
    uint256 public _buyBackTimeInterval = 5 minutes;
    uint256 public _buyBackMaxTimeForHistories = 24 * 60 minutes;

    ISwapRouter public swapRouter;
    address public swapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = true;

    bool public _isEnabledBuyBackAndBurn = true;

    event BuyBackEnabledUpdated(bool enabled);
    event AutoBuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event BuyBack(uint256 amount);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0 && isSwapPair(recipient)) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "AntiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    // mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    // testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    constructor (address routerAddress) {
        _rOwned[_msgSender()] = _rTotal;
        ISwapRouter _swapRouter = ISwapRouter(routerAddress);

        swapPair = ISwapFactory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        addSwapPair(swapPair);
        swapRouter = _swapRouter;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromSellCoolDown[owner()] = true;
        _isExcludedFromSellCoolDown[address(this)] = true;
        _excludedFromAntiWhale[owner()] = true;
        _excludedFromAntiWhale[address(this)] = true;

        _startTimeForSwap = block.timestamp;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isSwapPair(address account) public view returns (bool){

        return _swapPairs[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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
    ) private antiWhale(from, to, amount){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // this is to prevent others from adding liquidity before the team can to set the price
        require(tradingEnabled || isExcludedFromFee(from) || isExcludedFromFee(to), "Trading not enabled");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if (to == swapPair && balanceOf(swapPair) > 0) {
            SellHistories memory sellHistory;
            sellHistory.time = block.timestamp;
            sellHistory.bnbAmount = _getSellBnBAmount(amount);

            _sellHistories.push(sellHistory);
        }

        // Sell tokens for ETH (if not in inSwapAndLiquify && isEnabled && we have liquidity
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(swapPair) > 0) {
            // if is sell
            if (to == swapPair) {
                // if we have enough for swapping and it's past the waiting period
                if (overMinimumTokenBalance && _startTimeForSwap + _intervalMinutesForSwap <= block.timestamp) {
                    _startTimeForSwap = block.timestamp;
                    contractTokenBalance = minimumTokensBeforeSwap;
                    swapTokens(contractTokenBalance); // swap for bnb
                }

                // if buyback is enabled
                if (buyBackEnabled) {

                    uint256 balance = address(this).balance;

                    uint256 _bBSLimitMax = buyBackSellLimit;

                    // auto buy back enabled
                    if (_isAutoBuyBack) {

                        uint256 sumBnbAmount = 0;
                        uint256 startTime = block.timestamp - _buyBackTimeInterval;
                        uint256 cnt = 0;

                        for (uint i = 0; i < _sellHistories.length; i ++) {

                            if (_sellHistories[i].time >= startTime) {
                                sumBnbAmount = sumBnbAmount.add(_sellHistories[i].bnbAmount);
                                cnt = cnt + 1;
                            }
                        }

                        if (cnt > 0 && _buyBackDivisor > 0) {
                            _bBSLimitMax = sumBnbAmount.div(cnt).div(_buyBackDivisor);
                        }

                        _removeOldSellHistories();
                    }

                    uint256 _bBSLimitMin = _bBSLimitMax.mul(_buyBackRangeRate).div(100);

                    uint256 _bBSLimit = _bBSLimitMin + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (_bBSLimitMax - _bBSLimitMin + 1);

                    if (balance > _bBSLimit) {
                        buyBackTokens(_bBSLimit);
                    }
                }
            }

        }

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        else{
            // Buy
            if(isSwapPair(from)){
                removeAllFee();
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee;
            }
            // Sell
            if(isSwapPair(to)){
                require(canSell(from), "SellCoolDown: Cool down period not yet passed");
                removeAllFee();
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee;
                lastSale[from] = block.timestamp;
            }
            // If from account has a special fee
            if(_addressFees[from].enable){
                removeAllFee();
                _taxFee = _addressFees[from]._taxFee;
                _liquidityFee = _addressFees[from]._liquidityFee;

                // Sell
                if(isSwapPair(to)){
                    _taxFee = _addressFees[from]._sellTaxFee;
                    _liquidityFee = _addressFees[from]._sellLiquidityFee;
                }
            }
            else{
                // If buy account has a special fee
                if(_addressFees[to].enable){
                    //buy
                    removeAllFee();
                    if(isSwapPair(from)){
                        _taxFee = _addressFees[to]._buyTaxFee;
                        _liquidityFee = _addressFees[to]._buyLiquidityFee;
                    }
                }
            }
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function canSell(address account) internal view returns(bool) {
        if(!coolDownEnabled || _isExcludedFromSellCoolDown[account]){
            return true;
        }
        uint256 accountCoolDownPeriod =  _addressFees[account].enable ? _addressFees[account]._coolDownPeriod : coolDownPeriod;
        return lastSale[account].add(accountCoolDownPeriod) <= block.timestamp;
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        // Send to Team address
        transferToAddressETH(TEAM_ADDRESS, transferredBalance.mul(marketingDivisor).div(100));
    }


    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }

    function triggerBuyBack(uint256 amount) external onlyOwner {
        emit BuyBack(amount);
        buyBackTokens(amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // Make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    // Return actual supply of epic
    function epicSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(BURN_ADDRESS));
    }

    function swapETHForTokens(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(this);

        // Make the swap
        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of Tokens
            path,
            BURN_ADDRESS, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapRouter), tokenAmount);

        // Add the liquidity
        swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    /**
    * @dev Returns the max transfer amount.
    */
    function maxTransferAmount() public view returns (uint256) {
        // we can either use a percentage of supply
        if(maxTransferAmountRate > 0){
            return epicSupply().mul(maxTransferAmountRate).div(1000000);
        }
        // or we can just set an actual number
        return _maxTransferAmount;
    }

    /**
    * @dev Update the max transfer amount rate.
    * Can only be called by the current operator.
    */
    function setMaxTransferAmountRate(uint32 _maxTransferAmountRate) public onlyOwner {
        require(_maxTransferAmountRate <= 1000000, "EPIC::setMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
    * @dev Returns the address is excluded from antiWhale or not.
    */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
    * @dev Exclude or include an address from antiWhale.
    * Can only be called by the current owner.
    */
    function setExcludedFromAntiWhale(address _account, bool excluded) public onlyOwner {
        _excludedFromAntiWhale[_account] = excluded;
    }

    /**
    * @dev Returns the address is excluded from antiWhale or not.
    */
    function isExcludedFromSellCoolDown(address _account) public view returns (bool) {
        return _isExcludedFromSellCoolDown[_account];
    }

    /**
    * @dev Exclude or include an address from sell cool down.
    * Can only be called by the current owner.
    */
    function setExcludedFromSellCoolDown(address _account, bool excluded) public onlyOwner {
        _isExcludedFromSellCoolDown[_account] = excluded;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _getSellBnBAmount(uint256 tokenAmount) private view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = swapRouter.WETH();

        uint[] memory amounts = swapRouter.getAmountsOut(tokenAmount, path);

        return amounts[1];
    }

    function _removeOldSellHistories() private {
        uint256 i = 0;
        uint256 maxStartTimeForHistories = block.timestamp - _buyBackMaxTimeForHistories;

        for (uint256 j = 0; j < _sellHistories.length; j ++) {

            if (_sellHistories[j].time >= maxStartTimeForHistories) {

                _sellHistories[i].time = _sellHistories[j].time;
                _sellHistories[i].bnbAmount = _sellHistories[j].bnbAmount;

                i = i + 1;
            }
        }

        uint256 removedCnt = _sellHistories.length - i;

        for (uint256 j = 0; j < removedCnt; j ++) {

            _sellHistories.pop();
        }

    }

    function SetBuyBackMaxTimeForHistories(uint256 newMinutes) external onlyOwner {
        _buyBackMaxTimeForHistories = newMinutes * 1 minutes;
    }

    function SetBuyBackDivisor(uint256 newDivisor) external onlyOwner {
        _buyBackDivisor = newDivisor;
    }

    function GetBuyBackTimeInterval() public view returns(uint256) {
        return _buyBackTimeInterval.div(60);
    }

    function SetBuyBackTimeInterval(uint256 newMinutes) external onlyOwner {
        _buyBackTimeInterval = newMinutes * 1 minutes;
    }

    function SetBuyBackRangeRate(uint256 newPercent) external onlyOwner {
        require(newPercent <= 100, "The value must not be larger than 100.");
        _buyBackRangeRate = newPercent;
    }

    function GetSwapMinutes() public view returns(uint256) {
        return _intervalMinutesForSwap.div(60);
    }

    function SetSwapMinutes(uint256 newMinutes) external onlyOwner {
        _intervalMinutesForSwap = newMinutes * 1 minutes;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setBuyFee(uint256 buyTaxFee, uint256 buyLiquidityFee) external onlyOwner {
        _buyTaxFee = buyTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
    }

    function setSellFee(uint256 sellTaxFee, uint256 sellLiquidityFee) external onlyOwner {
        _sellTaxFee = sellTaxFee;
        _sellLiquidityFee = sellLiquidityFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setBuyBackSellLimit(uint256 buyBackSellSetLimit) external onlyOwner {
        buyBackSellLimit = buyBackSellSetLimit;
    }

    function setMaxTransferAmount(uint256 amount) external onlyOwner {
        require(amount >= MIN_MAX_TRANSFER_AMOUNT, 'Cannot be less than 1B');
        maxTransferAmountRate = 0;
        _maxTransferAmount = amount;
    }

    function setMarketingDivisor(uint256 divisor) external onlyOwner {
        marketingDivisor = divisor;
    }

    function setNumTokensSellToAddToBuyBack(uint256 _minimumTokensBeforeSwap) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        TEAM_ADDRESS = payable(_marketingAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function setAutoBuyBackEnabled(bool _enabled) public onlyOwner {
        _isAutoBuyBack = _enabled;
        emit AutoBuyBackEnabledUpdated(_enabled);
    }

    function setCoolDownPeriod(uint256 timePeriod) public onlyOwner {
        require(timePeriod <= MAX_COOL_DOWN, "can not be greater than MAX_COOL_DOWN");
        coolDownPeriod = timePeriod;
    }

    function enableTrading() public onlyOwner {
        tradingEnabled = true;
    }

    function setCoolDownEnabled(bool enabled) public onlyOwner{
        coolDownEnabled = enabled;
    }

    function prepareForPreSale(address ifoAddress) external onlyOwner {
        setSwapAndLiquifyEnabled(false);
        _isExcludedFromFee[ifoAddress] = true;
        excludeFromReward(ifoAddress);
    }

    function afterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
        _maxTransferAmount = 168888888888 * 10**9;
        enableTrading();
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function changeRouterVersion(address _router) public onlyOwner returns(address _pair) {
        ISwapRouter _uniswapV2Router = ISwapRouter(_router);

        _pair = ISwapFactory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist
            _pair = ISwapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }
        swapPair = _pair;
        addSwapPair(_pair);

        // Set the router of the contract variables
        swapRouter = _uniswapV2Router;
    }

    function addSwapPair(address _pair) public {
        _swapPairs[_pair] = true;
    }

    function removeSwapPair(address _pair) public {
        _swapPairs[_pair] = false;
    }

    // To recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function recoverTokens(address _token, address _to) public onlyOwner returns(bool _sent){
        require(_token != address(this), "Can not be epic token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function setAddressFee(address _address, bool _enable, uint256 _addressTaxFee, uint256 _addressLiquidityFee, uint256 _coolDownPeriod) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._taxFee = _addressTaxFee;
        _addressFees[_address]._liquidityFee = _addressLiquidityFee;
        _addressFees[_address]._coolDownPeriod = _coolDownPeriod;
    }

    function setAddressCoolDownPeriod(address _address, bool enable, uint _coolDownPeriod) external onlyOwner{
        _addressFees[_address].enable = enable;
        _addressFees[_address]._coolDownPeriod = _coolDownPeriod;
    }

    function setBuyAddressFee(address _address, bool _enable, uint256 _addressTaxFee, uint256 _addressLiquidityFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._buyTaxFee = _addressTaxFee;
        _addressFees[_address]._buyLiquidityFee = _addressLiquidityFee;
    }

    function setSellAddressFee(address _address, bool _enable, uint256 _addressTaxFee, uint256 _addressLiquidityFee) external onlyOwner {
        _addressFees[_address].enable = _enable;
        _addressFees[_address]._sellTaxFee = _addressTaxFee;
        _addressFees[_address]._sellLiquidityFee = _addressLiquidityFee;
    }

}

