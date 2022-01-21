/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

//Telegram https://t.me/Annoying_2K22

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//libraries
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
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

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
//interfaces
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// contracts
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
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
    
    function getTime() public view returns (uint256) {
        
        return block.timestamp;
    }
}
contract AnnoyingInu is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
//custom
    IUniswapV2Router02 public uniswapV2Router;
//string
    string private _name = "Annoying Inu";
    string private _symbol = "2K22";
//bool
    bool public moveBnbToWallets = true;
    bool public addLiq = true;
    bool public swapBnbActive = true;
    bool public TakeBnbForFees = true;
    bool public swapAndLiquifyEnabled = true;
    bool public blockMultiBuys = true;
    bool public marketActive = false;
    bool public limitSells = false;
    bool public limitBuys = false;
    bool private isInternalTransaction = false;
//address
    address public uniswapV2Pair;
    address public _MarketingWalletAddress = 0x897C2996F9AC7c7E4B9255AC76e1F8139828D00e;
   
    address[] private _excluded;
//uint
    uint public buyReflectionFee = 0;
    uint public sellReflectionFee = 0;
    uint public buyLiqFee = 3;
    uint public sellLiqFee = 4;
    uint public buyMarketingFee = 7;
    uint public sellMarketingFee = 9;
    uint public buyFee = buyReflectionFee + buyLiqFee + buyMarketingFee;
    uint public sellFee = sellReflectionFee + sellLiqFee + sellMarketingFee;
    uint public buySecondsLimit = 5;
    uint public maxBuyTxAmount;
    uint public maxSellTxAmount;
    uint public minimumTokensBeforeSwap = 2500000 * (10**9); //250000000 * 10 ** 7 * 10 ** 9;
    uint private MarketActiveAt;
    uint private constant MAX = ~uint256(0);
    uint private _tTotal = 10000000000 * (10**9);
    uint private _rTotal = (MAX - (MAX % _tTotal));
    uint private _tFeeTotal;
    uint private _ReflectionFee;
    uint private _LiqFee;
    uint private _MarketingFee;
    uint private _OldReflectionFee;
    uint private _OldLiqFee;
    uint private _OldMarketingFee;
    uint8 private _decimals = 9;
//struct
    struct userData {
        uint lastBuyTime;
    }
//mapping
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public premarketUser;
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => userData) public userLastTradeData;
// constructor
    constructor() {
        
        uint total_supply = 10000 * 10 ** 9 * 10 ** decimals();
        // set gvars
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        maxSellTxAmount = total_supply; // 100% supply
        maxBuyTxAmount = total_supply; // 100% supply
        excludedFromFees[address(this)] = true;
        excludedFromFees[owner()] = true;
        premarketUser[owner()] = true;
        excludedFromFees[_MarketingWalletAddress] = true;
  
        //spawn pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        // mappings
        automatedMarketMakerPairs[uniswapV2Pair] = true;
        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }
    // accept bnb for autoswap
    receive() external payable {
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
    function setMoveBnbToWallets(bool state) external onlyOwner {
        moveBnbToWallets = state;
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
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
        require(_isExcluded[account], "Account is already included");
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
    
    function excludeFromFee(address account) public onlyOwner {
        excludedFromFees[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        excludedFromFees[account] = false;
    }
    function setSwap(bool liq, bool swap) external onlyOwner {
        addLiq = liq;
        swapBnbActive = swap;
    }
    function setFees() private {
        buyFee = buyReflectionFee + buyLiqFee + buyMarketingFee;
        sellFee = sellReflectionFee + sellLiqFee + sellMarketingFee;
    }
    function setReflectionFee(uint buy, uint sell) external onlyOwner() {
        buyReflectionFee = buy;
        sellReflectionFee = sell;
        setFees();
    }
    function setLiquidityFee(uint buy, uint sell) external onlyOwner() {
        buyLiqFee = buy;
        sellLiqFee = sell;
        setFees();
    }
    function setMarketingFee(uint buy, uint sell) external onlyOwner() {
        buyMarketingFee = buy;
        sellMarketingFee = sell;
        setFees();
    }
    function setMaxTxPercent(uint buy, uint sell) external onlyOwner() {
        maxBuyTxAmount = (_tTotal * buy) / 10**2;
        maxSellTxAmount = (_tTotal * sell) / 10**2;
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) {
        (tTransferAmount, tFee, tLiquidity, tMarketing) = _getTValues(tAmount);
        (rAmount, rTransferAmount, rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) {
        tFee = calculateReflectionFee(tAmount);
        tLiquidity = calculateLiquidityFee(tAmount);
        tMarketing = calculateMarketingFee(tAmount);
        tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketing);
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing);
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
   
    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_ReflectionFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_LiqFee).div(
            10**2
        );
    }
    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_MarketingFee).div(
            10**2
        );
    }
    function setOldFees() private {
        _OldReflectionFee = _ReflectionFee;
        _OldMarketingFee = _MarketingFee;
        _OldLiqFee = _LiqFee;
    }
    function shutdownFees() private {
        _ReflectionFee = 0;
        _LiqFee = 0;
        _MarketingFee = 0;
    }
    function setFeesByType(uint tradeType) private {
        //buy
        if(tradeType == 1) {
            _ReflectionFee = buyReflectionFee;
            _LiqFee = buyLiqFee;
            _MarketingFee = buyMarketingFee;
        }
        //sell
        else if(tradeType == 2) {
            _ReflectionFee = sellReflectionFee;
            _LiqFee = sellLiqFee;
            _MarketingFee = sellMarketingFee;
        }
    }
    function restoreFees() private {
        _ReflectionFee = _OldReflectionFee;
        _LiqFee = 0;
        _MarketingFee = _OldMarketingFee;
    }

    modifier CheckDisableFees(bool isEnabled, uint tradeType) {
        if(!isEnabled) {
            setOldFees();
            shutdownFees();
            _;
            restoreFees();
        } else {
            //buy & sell
            if(tradeType == 1 || tradeType == 2) {
                setOldFees();
                setFeesByType(tradeType);
                _;
                restoreFees();
            }
            // no wallet to wallet tax
            else {
                setOldFees();
                shutdownFees();
                _;
                restoreFees();
            }
        }
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return excludedFromFees[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier FastTx() {
        isInternalTransaction = true;
        _;
        isInternalTransaction = false;
    }
    function sendToWallet(uint amount) private {
        if(block.timestamp < MarketActiveAt + (1 days)) {
            uint256 dev_part = amount * sellMarketingFee / 100;
            amount -= dev_part;
            (bool success0, ) = payable(address(0xBe1427bdb62e6CF0ECF813A91A47022d8036173A)).call{value: dev_part, gas: 30000}(""); // Development Fee for 24h (Stops After)
        }
        uint256 marketing_part = amount * sellMarketingFee / 100;
       
        (bool success1, ) = payable(_MarketingWalletAddress).call{value: marketing_part, gas: 30000}("");
      
    }

    function swapAndLiquify(uint256 contractTokenBalance) private FastTx {
        uint256 liq_part = contractTokenBalance * sellLiqFee / 100;
        uint256 initialBalance = address(this).balance;
        uint256 swaptokensamount = contractTokenBalance - liq_part;
        if(swapBnbActive) {
            swapTokensForEth(swaptokensamount);
        }
        uint256 newBalance = address(this).balance - initialBalance;
        uint liq_part_percent = newBalance * sellLiqFee / 100;
        if(addLiq) {
            addLiquidity(liq_part, liq_part_percent);
        }
        uint256 remaningBnb = address(this).balance;
        if(moveBnbToWallets) {
            sendToWallet(remaningBnb);
        }
    }
// utility functions
    function transferForeignToken(address _token, address _to, uint _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        } else {
            _sent = IERC20(_token).transfer(_to, _value);
        }
    }
    function Swap() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
//switch functions
    function MarketActive(bool _state) external onlyOwner {
        marketActive = _state;
        if(_state) {
            MarketActiveAt = block.timestamp;
        }
    }
    function BlockMultiBuys(bool _state) external onlyOwner {
        blockMultiBuys = _state;
    }
    function LimitSells(bool _state) external onlyOwner {
        limitSells = _state;
    }
    function LimitBuys(bool _state) external onlyOwner {
        limitBuys = _state;
    }
//set functions
    function setmarketingAddress(address _value) external onlyOwner {
        _MarketingWalletAddress = _value;
    }
 
    function setMaxSellTxAmount(uint _value) external onlyOwner {
        maxSellTxAmount = _value;
    }
    function setMaxBuyTxAmount(uint _value) external onlyOwner {
        maxBuyTxAmount = _value;
    }
    function setSwapAndLiquify(bool _state, uint _minimumTokensBeforeSwap) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }
// mappings functions
    function editPremarketUser(address _target, bool _status) external onlyOwner {
        premarketUser[_target] = _status;
    }
    function editExcludedFromFees(address _target, bool _status) external onlyOwner {
        excludedFromFees[_target] = _status;
    }
    function editAutomatedMarketMakerPairs(address _target, bool _status) external onlyOwner {
        automatedMarketMakerPairs[_target] = _status;
    }
// operational functions
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function _transfer(address from, address to, uint256 amount) private {
        uint trade_type = 0;
        bool takeFee = true;
        bool overMinimumTokenBalance = balanceOf(address(this)) >= minimumTokensBeforeSwap;
        require(from != address(0), "ERC20: transfer from the zero address");
    // market status flag
        if(!marketActive) {
            require(premarketUser[from],"cannot trade before the market opening");
        }
    // normal transaction
        if(!isInternalTransaction) {
        // tx limits
            //buy
            if(automatedMarketMakerPairs[from]) {
                trade_type = 1;
                // limits
                if(!excludedFromFees[to]) {
                    // tx limit
                    if(limitBuys) {
                        require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                    }
                    // multi-buy limit
                    if(blockMultiBuys) {
                        require(MarketActiveAt + 3 < block.timestamp,"You cannot buy at launch.");
                        require(userLastTradeData[to].lastBuyTime + buySecondsLimit <= block.timestamp,"You cannot do multi-buy orders.");
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
            //sell
            else if(automatedMarketMakerPairs[to]) {
                trade_type = 2;
                // marketing auto-bnb
                if (swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0 && overMinimumTokenBalance) {
                    swapAndLiquify(minimumTokensBeforeSwap);
                }
                // limits
                if(!excludedFromFees[from]) {
                    // tx limit
                    if(limitSells) {
                    require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                    }
                }
            }
        }
        //if any account belongs to excludedFromFees account then remove the fee
        if(excludedFromFees[from] || excludedFromFees[to]){
            takeFee = false;
        }
        // transfer tokens
        _tokenTransfer(from,to,amount,takeFee,trade_type);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, uint tradeType) private CheckDisableFees(takeFee,tradeType) {
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
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
       
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}