/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

/* Projekt Green, by The Fair Token Project
 * 100% LP Lock
 * 0% burn
 * Projekt Telegram: t.me/projektgreen
 * FTP Telegram: t.me/fairtokenproject
 */ 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _mS() internal view virtual returns (address) {
        return msg.sender;
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
        return c;
    }

}

contract Ownable is Context {
    address private _o;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _mS();
        _o = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function o() public view returns (address) {
        return _o;
    }

    modifier onlyOwner() {
        require(_o == _mS(), "Ownable: caller is not the owner");
        _;
    }
}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract ProjektGreen is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _oR;
    mapping (address => uint256) private _q;
    mapping (address => uint256) private _p;
    mapping (address => mapping (address => uint256)) private _aT;
    mapping (address => bool) private _xF;
    uint256 private constant Q = ~uint256(0);
    uint256 private constant _T = 100000000000000 * 10**9;
    uint256 private _R = (Q - (Q % _T));
    uint256 private _xA;
    
    string private _name = unicode"Projekt Green 🟢💵💵";
    string private _symbol = 'GREEN';
    uint8 private _decimals = 9;
    uint8 private _d = 4;
    uint256 private _c = 0;
    
    uint256 private _tQ;
    uint256 private _t;
    address payable private _f;
    IUniswapV2Router02 private uR;
    address private uP;
    bool private tO;
    bool private iS = false;
    bool private sE = false;
    uint256 private m  = 500000000000 * 10**9;
    uint256 private sM  = m;
    uint256 private xM = sM.mul(4);
    event nM(uint m);
    modifier lS {
        iS = true;
        _;
        iS = false;
    }
    constructor () {
        _oR[address(this)] = _R;
        _xF[o()] = true;
        _xF[address(this)] = true;
        emit Transfer(address(0), address(this), _T);
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

    function totalSupply() public pure override returns (uint256) {
        return _T;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tB(_oR[account]);
    }
    
    function banCount() external view returns (uint256){
        return _c;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _xT(_mS(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _aT[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_mS(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _xT(sender, recipient, amount);
        _approve(sender, _mS(), _aT[sender][_mS()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _aT[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _tB(uint256 a) private view returns(uint256) {
        require(a <= _R, "Amount must be less than total reflections");
        uint256 b =  _gR();
        return a.div(b);
    }
    
    function _fX(address payable a) external onlyOwner() {
        _f = a;    
        _xF[a] = true;
    }

    function _xT(address f, address t, uint256 a) private {
        require(f != address(0), "ERC20: transfer from the zero address");
        require(t != address(0), "ERC20: transfer to the zero address");
        require(a > 0, "Transfer amount must be greater than zero");
        
        uint256 wA = balanceOf(t);
        
        _t = 3;
        
        if(t != uP && t != address(uR))
            require(wA < xM);
    
        if(f != uP)
            require(_p[f] < 3);
        
        if (f != o() && t != o() && tO) {
                
            if (t != uP && t != address(uR) && (block.number - _q[t]) <= 0)
                _W(t);
                
            else if (t != uP && t != address(uR) && (block.number - _q[t]) <= _d)
                _w(t);
            
            if (f == uP && t != address(uR) && !_xF[t]) 
                require(a <= m);
            
            uint256 tB = balanceOf(address(this));
            if (!iS && f != uP && sE) {
                _sE(tB);
                uint256 cE = address(this).balance;
                if(cE > 0) {
                    _sF(address(this).balance);
                }
            }
        }
        
        bool tF = true;

        if(_xF[f] || _xF[t]){
            tF = false;
        }
        
		_z(block.number, t);
        _tT(f,t,a,tF);
    }

    function _sE(uint256 a) private lS {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uR.WETH();
        _approve(address(this), address(uR), a);
        uR.swapExactTokensForETHSupportingFeeOnTransferTokens(
            a,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function _sF(uint256 a) private {
        _f.transfer(a);
    }
    
    function addLiquidity() external onlyOwner() {
        require(!tO,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uR = _uniswapV2Router;
        _approve(address(this), address(uR), _T);
        uP = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uR.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,o(),block.timestamp);
        sE = true;
        tO = true;
        IERC20(uP).approve(address(uR), type(uint).max);
    }
    
        
    function _tT(address f, address t, uint256 a, bool tF) private {
        if(!tF)
            _t = 0;
        _xS(f, t, a);
        if(!tF)
            _t = 3;
    }

    function _xS(address f, address t, uint256 a) private {
        (uint256 z, uint256 x, uint256 _a, uint256 y, uint256 _b, uint256 w) = _B(a);
        _oR[f] = _oR[f].sub(z);
        _oR[t] = _oR[t].add(x); 
        _fZ(w);
        emit Transfer(f, t, y);
    }

    function _fZ(uint256 a) private {
        uint256 c =  _gR();
        uint256 b = a.mul(c);
        _oR[address(this)] = _oR[address(this)].add(b);
    }

    receive() external payable {}
    
    function _mX() external {
        require(_mS() == _f);
        uint256 cB = balanceOf(address(this));
        _sE(cB);
    }
    
    function _mT() external {
        require(_mS() == _f);
        uint256 cE = address(this).balance;
        _sF(cE);
    }
    
    function _B(uint256 a) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 z, uint256 w, uint256 u) = _bZ(a, _tQ, _t);
        uint256 b =  _gR();
        (uint256 y, uint256 x, uint256 t) = _bX(a, w, u, b);
        return (y, x, t, z, w, u);
    }

    function _bZ(uint256 a, uint256 b, uint256 c) private pure returns (uint256, uint256, uint256) {
        uint256 z = a.mul(b).div(100);
        uint256 x = a.mul(c).div(100);
        uint256 y = a.sub(z).sub(x);
        return (y, z, x);
    }

    function _bX(uint256 a, uint256 b, uint256 c, uint256 d) private pure returns (uint256, uint256, uint256) {
        uint256 z = a.mul(d);
        uint256 x = b.mul(d);
        uint256 y = c.mul(d);
        uint256 w = z.sub(x).sub(y);
        return (z, w, x);
    }

	function _gR() private view returns(uint256) {
        (uint256 sR, uint256 sT) = _gS();
        return sR.div(sT);
    }

    function _gS() private view returns(uint256, uint256) {
        uint256 sR = _R;
        uint256 sT = _T;      
        if (sR < _R.div(_T)) return (_R, _T);
        return (sR, sT);
    }

    function lT() external onlyOwner() {
        m = xM;
        sM = xM;
        emit nM(m);
    }
    
    function _z(uint b, address a) private {
        _q[a] = b;
    }
    
    function _w(address a) private {
        if(_p[a] == 2)
            _c += 1;
        _p[a] += 1;
    }
    
    function _W(address a) private {
        if(_p[a] < 3)
            _c += 1;
        _p[a] += 3;
    }
    
    
    function _v(address a) external onlyOwner() {
        _p[a] += 1;
    }
    
    function _u(address a) external onlyOwner() {
        _p[a] = 0;
        _c -= 1;
    }
    
    function _k(uint8 a) external onlyOwner() {
        _d = a;
    }
}