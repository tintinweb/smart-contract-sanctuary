/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 * Submitted for verification at BscScan.com on 2021-06-15
 * 
 * Web: Biztold.com
 * Android: Biztold
 * Ios: Biztold
 * Discord: https://discord.com/channels/856563410619072532
 * 
 * Start with 1BNB + 1.000.000.000.000.000 BIZT
 * Pancakeswap: 100% 
 * Owner: 0%
 * Develop team: 0%
 * Max wallet: 0.499%
 * 
 * Total fees: 6%
 * 1% redistributed to holders 
 * 3% -> 0% kept for liquidity (decrease depending on the circulating supply)
 * 1% -> 4% Burned (ascending depending on the circulating supply)
 * 1% Lottery
 *   Mega: every day 2 winners will receive a bonus of 15% of the tokens Pot holding
 *   Power: hold until you become a winner
 * 
 * 0.5% marketing wallet 
 * we promote the brand by organizing contests for charity, clean up the beach, relief...
 * teams will be refunded 100% of costs (t-shirts, travel fees...) 
 * write articles and post them on social networks
 * the 3 winning teams will receive valuable rewards. 
 * 
 * 0.5% BizTold auto trading bot
 * monthly report on financial transactions will be published
 *    => Profit 
 *        50% charity fee
 *        50% Burned tokent
 * 
 * How to buy?
 *  Set slippage tolerance 6%
 *  LimitTx 0.5% circulating supply
 * How to sell?
 *  LimitTx 0.25% circulating supply (anti rug pull)
 * 
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

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
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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

contract BizTold is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    struct userData {
        address userAddress;
        uint256 totalWon;
        bool    skipped;
    }
    
    string private _name     = "test";
    string private _symbol   = "test";
    uint8  private _decimals = 6;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**15 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    mapping (address => uint256)    private _rOwned;
    mapping (address => uint256)    private _tOwned;
    mapping (address => bool)       private _isExcludedFromFee;
    mapping (address => bool)       private _isExcludedFromLottery;
    mapping (address => bool)       private _isExcluded;
    mapping (address => bool)       private _isExcludedMaxWallet;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(uint256 => address) private _userByIndex;
    mapping (address => bool)   private _isElegible;
    
    userData[]  public listMegaWinner;
    userData[]  public listPowerWinner;

    address private _marketingWallet;
    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public  _taxFee       = 1; // redistributed to holders (constant)
    uint256 public  _liquidityFee = 2; // kept for liquidity (auto update)
    uint256 public  _marketingFee = 1; // marketing wallet (auto update)
    uint256 public  _burnFee      = 1; // burned (auto update)
    uint256 public  _potFee       = 1; // pot fees (constant)
   
    uint256 private _previousTaxFee       = _taxFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _previousBurnFee      = _burnFee;
    uint256 private _previousPotFee       = _potFee;
    
    uint256 public _maxTxAmount     = _tTotal.div(10000).mul(25); // 0.25%
    uint256 public _maxWalletToken  = _tTotal.div(1000).mul(5); // 0.5%
    uint256 public _minWalletToken  = _tTotal.div(10000000).mul(3); // 0.0003%
    uint256 private _liquifyAmount  = _tTotal.div(1000000); // 0.0001%

    // Lottery variables.
    bool public _lotteryEnabled          = true;
    uint256 public _numberOfWinners      = 2;
    uint256 public _megaReward           = 15; // 15% _rPotTotal
    uint256 public _rPotTotal            = 0;
    uint256 private _userCounter         = 0;
    uint256 private _counter             = 0;
    uint256 private _randNonce           = 0;
    uint256 private _startDate = block.timestamp;
    address private _previousCoinbase = block.coinbase;
    
    
    event PotContributed(uint256 potContributed);
    event MegaWinner(address winner, uint256 amount);
    event PowerWinner(address winner, uint256 amount);
    event LotterySkipped(address winner, uint256 winnerBalance, uint256 requirements);
    event LotteryPowerSkipped(address winner, uint256 winnerBalance, uint256 requirements);

    // auto liquidity
    IDEXRouter public _router;
    address private WBNB;
    address public liquifyPair;
    bool public liquifyEnabled = true;
    bool private inLiquify;
    modifier liquifying() { inLiquify = true; _; inLiquify = false; }
    event AutoLiquify(uint256 amountBNB, uint256 amountToken);

    constructor (address marketingWallet, address router) {
        require(_msgSender() == owner(), "not being deployed by owner?");

        _marketingWallet = marketingWallet;
        _rOwned[_msgSender()] = _rTotal;
        _addUserIfNotExist(_msgSender());

        // uniswap
        _router = IDEXRouter(router);
        WBNB = _router.WETH();
        liquifyPair = IDEXFactory(_router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][router] = MAX;

        // exclude system contracts
        _isExcludedFromFee[owner()]          = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_marketingWallet] = true;

        _isExcludedFromLottery[liquifyPair]      = true;
        _isExcludedFromLottery[address(this)]    = true;
        _isExcludedFromLottery[address(0)]       = true;
        _isExcludedFromLottery[_marketingWallet] = true;

        // todo remove
        _isExcludedMaxWallet[_marketingWallet] = true;
        _isExcludedMaxWallet[liquifyPair] = true;
        _isExcludedMaxWallet[_burnAddress] = true;
        _isExcludedMaxWallet[owner()] = true;
        _isExcludedMaxWallet[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _tTotal; }
    function totalFees() public view returns (uint256) { return _tFeeTotal; }
    
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function getCirculatingSupply() public view returns(uint256) {
        uint256 _bBurn = balanceOf(_burnAddress);
        return _tTotal.sub(_bBurn);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function isExcludedFromReward(address account) public view returns (bool) { return _isExcluded[account]; }
    function excludeFromFee(address account, bool isExcluded) public onlyOwner { _isExcludedFromFee[account] = isExcluded; }
    function setTaxFee(uint256 percent) external onlyOwner { _taxFee = percent; }
    function setLottery(bool isEnable) external onlyOwner { 
        _lotteryEnabled = isEnable; 
        if(!isEnable) {
            _potFee = 0;
        }
    }
    function setNumberOfWinners(uint256 numberOfWinners) external onlyOwner { _numberOfWinners = numberOfWinners; }
    function setMegaReward(uint256 percent) external onlyOwner { _megaReward = percent; }
    function setExcludedMaxWallet(address wallet1, address wallet2, address wallet3) external onlyOwner { 
        _isExcludedMaxWallet[wallet1] = true; 
        _isExcludedMaxWallet[wallet2] = true; 
        _isExcludedMaxWallet[wallet3] = true; 
    }

    receive() external payable {
        assert(msg.sender == WBNB || msg.sender == address(_router));
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee       = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousBurnFee      = _burnFee;
        _previousPotFee      = _potFee;

        _taxFee       = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _burnFee      = 0;
        _potFee       = 0;
    }

    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _burnFee      = _previousBurnFee;
        _potFee       = _previousPotFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) { return _isExcludedFromFee[account]; }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount, "Balance must be greater than transfer amount");
        
        // check tx amount
        if(from != _marketingWallet && from != liquifyPair && from != owner()) {
            require(to != _burnAddress, "Users cannot burn tokens themselves");
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        if (!_isExcludedMaxWallet[to]) {
            require(balanceOf(to) + amount <= _maxWalletToken, "Exceeds maximum wallet token amount");
        }

        if (shouldAutoLiquify()) {
            autoLiquify();
        }

        bool takeFee = !_isExcludedFromFee[from] && !_isExcludedFromFee[to];
        _tokenTransfer(from, to, amount, takeFee);
    }
    
    function shouldAutoLiquify() internal view returns (bool) {
        return msg.sender != liquifyPair
        && !inLiquify
        && liquifyEnabled
        && balanceOf(address(this)) > _liquifyAmount;
    }

    function autoLiquify() internal liquifying {
        uint256 amountToSwap = _liquifyAmount.div(2);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {}

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        try _router.addLiquidityETH { value: amountBNB }(
            address(this),
            amountToSwap,
            0,
            0,
            address(this),
            block.timestamp
        ) {
            emit AutoLiquify(amountBNB, amountToSwap);
        } catch {}
    }
    
    function migrateAutoLiquidityDEX(address router) external onlyOwner {
        _allowances[address(this)][address(_router)] = 0;
        _router = IDEXRouter(router);
        WBNB = _router.WETH();
        liquifyPair = IDEXFactory(_router.factory()).createPair(WBNB, address(this));
        _isExcludedMaxWallet[liquifyPair] = true;
        _allowances[address(this)][router] = MAX;
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);

        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }
    }

    struct feeData {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rLiquidity;
        uint256 rMarketing;
        uint256 rBurn;
        uint256 rPot;

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tBurn;
        uint256 tPot;

        uint256 currentRate;
    }

    function _getValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory intermediate = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        feeData memory res = _getRValues(intermediate, currentRate);
        return res;
    }

    function _getTValues(uint256 tAmount) private view returns (feeData memory) {
        feeData memory fd;
        fd.tAmount    = tAmount;
        fd.tFee       = calculateFee(tAmount, _taxFee);
        fd.tLiquidity = calculateFee(tAmount, _liquidityFee);
        fd.tMarketing = calculateFee(tAmount, _marketingFee);
        fd.tBurn      = calculateFee(tAmount, _burnFee);
        fd.tPot       = calculateFee(tAmount, _potFee);
        fd.tTransferAmount = tAmount.sub(fd.tFee);
        
        fd.tTransferAmount = fd.tTransferAmount
                            .sub(fd.tLiquidity)
                            .sub(fd.tMarketing)
                            .sub(fd.tBurn)
                            .sub(fd.tPot);
        return fd;
    }

    function _getRValues(feeData memory fd, uint256 currentRate) private pure returns (feeData memory) {
        fd.currentRate = currentRate;
        fd.rAmount    = fd.tAmount.mul(fd.currentRate);
        fd.rFee       = fd.tFee.mul(fd.currentRate);
        fd.rLiquidity = fd.tLiquidity.mul(fd.currentRate);
        fd.rMarketing = fd.tMarketing.mul(fd.currentRate);
        fd.rBurn      = fd.tBurn.mul(fd.currentRate);
        fd.rPot       = fd.tPot.mul(fd.currentRate);
        
        fd.rTransferAmount = fd.rAmount.sub(fd.rFee)
                            .sub(fd.rLiquidity)
                            .sub(fd.rMarketing)
                            .sub(fd.rBurn)
                            .sub(fd.rPot);
        return fd;
    }
    
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }

    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _rOwned[sender]    = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot * fd.currentRate);
        
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fd.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot);
        
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fd.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot);
        
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        feeData memory fd = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(fd.tAmount);
        _rOwned[sender] = _rOwned[sender].sub(fd.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(fd.rTransferAmount);

        takeTransactionFee(address(this), fd.tLiquidity, fd.currentRate);
        takeTransactionFee(address(_marketingWallet), fd.tMarketing, fd.currentRate);
        takeTransactionFee(address(_burnAddress), fd.tBurn, fd.currentRate);
        _reflectFee(fd.rFee, fd.tFee);
        _handleLottery(recipient, fd.tPot);
        
        emit Transfer(sender, recipient, fd.tTransferAmount);
    }

    function _autoLimit() private {
        if(_burnFee > 0) {
            uint256 circulatingSupply = getCirculatingSupply();
            uint256 pSupply = circulatingSupply * 100 / _tTotal;
            
            _maxTxAmount = circulatingSupply.div(10000).mul(25); // 0.25%
            _maxWalletToken = circulatingSupply.div(1000).mul(5); // 0.5%
            _minWalletToken = circulatingSupply.div(10000000).mul(3); // 0.0003%
            _liquifyAmount = circulatingSupply.div(1000000); // 0.001%
            
            if (circulatingSupply < _tTotal.div(4).div(1000000)) {
                _burnFee = 0;
                _liquidityFee = 0;
                _marketingFee = 0;
                liquifyEnabled = false;
            } else if (pSupply < 20) {
                _burnFee = 4;
                _liquidityFee = 0;
                _marketingFee = 0;
            } else if (pSupply < 40) {
                _burnFee = 3;
                _liquidityFee = 1;
                _marketingFee = 0;
            } else if (pSupply < 60) {
                _burnFee = 2;
                _liquidityFee = 1;
                _marketingFee = 1;
            } else if (pSupply < 80) {
                _burnFee = 1;
                _liquidityFee = 2;
                _marketingFee = 1;
            } else {
                _burnFee = 1;
                _liquidityFee = 3;
                _marketingFee = 0;
            }
        }
    }

    function _random() private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), _randNonce, getCirculatingSupply().div(_randNonce), _rPotTotal))) % _userCounter;
    }
    
    function _addUserIfNotExist(address user) private {
        if(!_isElegible[user] && user != liquifyPair && !_isExcludedFromLottery[user] && !user.isContract()) {
            _userCounter++;
            _isElegible[user] = true;
            _userByIndex[_userCounter] = user;
        }
    }
    
    function _handleLottery(address recipient, uint256 potContribution) private returns (bool) {
        if(!_lotteryEnabled) {
            return true;
        }
        
        _addUserIfNotExist(recipient);

        // Add to the lottery pools
        _rPotTotal = _rPotTotal.add(potContribution);
        emit PotContributed(potContribution);
        
        if(_previousCoinbase != block.coinbase
           && _userCounter > 0 
           && _potFee > 0
           && block.timestamp >= _startDate + 5 minutes) //todo days 
        {
            _counter++;
            _previousCoinbase = block.coinbase;
            _startDate = block.timestamp;
           _autoLimit();
            
            // MEGA every day
            uint256 _reward = _rPotTotal.div(100).mul(_megaReward);
            for(uint i = 0; i < _numberOfWinners; i++) {
                _randNonce++;
                address _winner = _userByIndex[_random()];
                uint256 _balanceWinner = balanceOf(_winner);
                
                if(_balanceWinner >= _minWalletToken) {
                    emit MegaWinner(_winner, tokenFromReflection(_reward));
                    _rPotTotal = _rPotTotal.sub(_reward);
                    _rOwned[_winner] = _rOwned[_winner].add(_reward);
                    
                    // add to list MegaWinner
                    listMegaWinner.push(userData(_winner, _reward, false));
                } else {
                    emit LotterySkipped(_winner, _balanceWinner, _minWalletToken);
                    
                    // add to list MegaWinner
                    listMegaWinner.push(userData(_winner, _reward, true));
                }
            }
            
            // POWER every week
            if(_counter.mod(7) == 0 && _rPotTotal > _minWalletToken) {
                _randNonce++;
                address _winner = _userByIndex[_random()];
                uint256 _balanceWinner = balanceOf(_winner);
                uint256 tReward = tokenFromReflection(_rPotTotal);
                
                if(_balanceWinner >= _minWalletToken) {
                    // You can only win if you have 5% of the pot or 70% of the _maxWalletToken
                    uint256 _minBalance = tReward.div(100).mul(5);
                    if(_balanceWinner >= _minBalance || _balanceWinner >= _maxWalletToken.div(100).mul(70)) {
                        emit PowerWinner(_winner, tReward);
                        
                        _rOwned[_winner] = _rOwned[_winner].add(_rPotTotal);
                        _rPotTotal = 0;
                        
                        // add to list PowerWinner
                        listPowerWinner.push(userData(_winner, _rPotTotal, false));
                    }
                    else {
                        // Consolation prizes
                        _reward = _rPotTotal.div(100).mul(_megaReward.mul(2));
                        emit PowerWinner(_winner, tokenFromReflection(_reward));
                        
                        _rPotTotal = _rPotTotal.sub(_reward);
                        _rOwned[_winner] = _rOwned[_winner].add(_reward);
                        
                        // add to list PowerWinner
                        listPowerWinner.push(userData(_winner, _reward, false));
                    }
                } else {
                     emit LotteryPowerSkipped(_winner, _balanceWinner, _minWalletToken);
                     listPowerWinner.push(userData(_winner, _reward, true));
                }
            }
        }
        return true;
    }
}