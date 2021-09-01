/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/*

With a dynamic sell limit based on price impact and increasing sell cooldowns and redistribution taxes on consecutive sells, HotDoge v2 block bots and discourage dumping.

- Token Information
Sell cooldown increases on consecutive sells, 3 sells within a 4 hours period are allowed

Sell restriction ( Protect liquidity ) - 1x fee on the first sell, increases 2x, 3x on consecutive sells

Fee Percentages
1. 1.50% Diamond Hand Corporate Development
2. 1.50% Vip Programs
3. 3.00% HOTDOGE Reflection (auto)
4. 3.00% Astro Buyback
5. 1.50% Treats Bot
6. 2.00% Marketing
7. 2.50% Liquidity

total: 15%

Supply 1,000,000,000,000,000 (1 quadrillion)

SPDX-License-Identifier: MIT
*/

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

////////////////////////////////////////////
///////// PancakeSwap Interfaces ///////////
////////////////////////////////////////////

interface IPancakeswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IPancakeswapV2Router01 {
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

interface IPancakeswapV2Router02 is IPancakeswapV2Router01 {

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

contract HotDoge is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"HotDoge v3";
    string private constant _symbol = "HOTDOGE";
    uint8 private constant _decimals = 18;

    mapping(address => uint256) private _rOwned; // reflected token owned amount
    mapping(address => uint256) private _tOwned; // addresses token owned amount
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee; // wallets excluded from fee
    mapping(address => bool) private _teamAddresses; // team wallet check list

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**15 * 10**18; // total supply 1,000,000,000,000,000 (1 quadrillion)
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // reflected total supply
    uint256 private constant minBalance = 4 * 10**11 * 10 ** 18;

    uint256 private _tFeeTotal; // total fee of reflection
    uint256 private _teamFee = 1200; // 12% total team fee
    uint256 private _taxFee = 300; // 3% HotDoge reflection (auto)
    uint256 private _volFee = 150; // 1.5% volunteer, treat bots fee 50 / 10000
    uint256 private _diamondFee = 150; // 1.5% diamond hand fee 150 / 10000 
    uint256 private _vipFee = 150; // 1.5% vip fee 150 / 10000
    uint256 private _marketingFee = 200; // 2% marketing fee 200 / 10000
    uint256 private _liquidityFee = 250; // 2.5% liquidity fee 250 / 10000
    uint256 private _buybackFee = 300; // 3% buyback fee 300 / 10000

    mapping(address => bool) private bots; // bots blacklist
    mapping(address => uint256) private buycooldown; // buy cooldown time - 30 minutes
    mapping(address => uint256) private sellcooldown;  // sell cooldown time - 1 hour, 2 hours, 4 hours
    mapping(address => uint256) private firstsell; // first sell time
    mapping(address => uint256) private sellnumber;  // calculate consecutive sells

    address payable private _volunteerWallet; // volunteer and treats bot wallet address
    address payable private _diamondHandWallet; // diamond hand wallet address
    address payable private _vipWallet; // vip wallet address
    address payable private _marketingWallet; // marketing wallet address
    address payable private _liquidityWallet; // liquidity wallet address
    address payable private _buybackWallet; // buyback wallet address

    IPancakeswapV2Router02 private pancakeswapV2Router; // pancakeswap v2 router
    address private pancakeswapV2Pair; // pancakeswap v2 pair

    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;

    uint256 private _maxTxAmount = _tTotal;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _volunteerWallet = payable(0x4F9e768639d85EB2e569EDcb3a6e5f392D284524);
        _diamondHandWallet = payable(0x0d4cb32BDE8125422927010D23c3E9bc32F0bE77);
        _vipWallet = payable(0xD635793aeA59bE35a04e1E61F5761f4A9305408b);
        _marketingWallet = payable(0x88eB1507Ee468eaA3f73Ec91a74A6B962E4DB33C);
        _liquidityWallet = payable(0xF2F4E0cD8FaC460Aa5aC4a2df6C234E8d83A28f1);
        _buybackWallet = payable(0x41F71eFb2a6c7ce78b8bf27BfcBe7fB4595F797C);

        _rOwned[_msgSender()] = _rTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_volunteerWallet] = _teamAddresses[_volunteerWallet] = true;
        _isExcludedFromFee[_diamondHandWallet] = _teamAddresses[_diamondHandWallet] = true;
        _isExcludedFromFee[_vipWallet] = _teamAddresses[_vipWallet] = true;
        _isExcludedFromFee[_marketingWallet] = _teamAddresses[_marketingWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = _teamAddresses[_liquidityWallet] = true;
        _isExcludedFromFee[_buybackWallet] = _teamAddresses[_buybackWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
    
    function liquiditystatus() public view returns (bool) {
        return liquidityAdded;
    }

    function swapstatus() public view returns (bool) {
        return swapEnabled;
    }

    function cooldownStatus() public view returns (bool) {
        return cooldownEnabled;
    }

    function tradingStatus() public view returns (bool) {
        return tradingOpen;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_taxFee == 0 && _teamFee == 0) return;
        _taxFee = 0;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = 300;
        _teamFee = 1200;
    }
    
    function setMultiFee(uint256 multiplier) private {
        _teamFee = _teamFee * multiplier;
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

        if (from != owner() && to != owner()) {
            if (cooldownEnabled) {
                if (from != address(this) && to != address(this) && from != address(pancakeswapV2Router) && to != address(pancakeswapV2Router)) {
                    require(_msgSender() == address(pancakeswapV2Router) || _msgSender() == pancakeswapV2Pair,"ERR: PancakeSwap only");
                }
            }

            require(!bots[from] && !bots[to]);

            if (from == pancakeswapV2Pair && to != address(pancakeswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(tradingOpen);
                require(amount <= _maxTxAmount);
                require(buycooldown[to] < block.timestamp);

                buycooldown[to] = block.timestamp + (5 seconds);
            }

            if (!inSwap && from != pancakeswapV2Pair && swapEnabled) {
                require(amount <= _maxTxAmount);
                require(sellcooldown[from] < block.timestamp);

                if(firstsell[from] + (4 hours) < block.timestamp){
                    sellnumber[from] = 0;
                }

                if (sellnumber[from] == 0) {
                    sellnumber[from]++;
                    firstsell[from] = block.timestamp;
                    sellcooldown[from] = block.timestamp + (1 hours);
                }
                else if (sellnumber[from] == 1) {
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (2 hours);
                }
                else if (sellnumber[from] == 2) {
                    sellnumber[from]++;
                    sellcooldown[from] = block.timestamp + (4 hours);
                }

                uint256 contractTokenBalance = balanceOf(address(this));

                if(contractTokenBalance > minBalance){
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance - 3 * 10**17;  // Always need 0.3BNB in contract balance for swap and transfer fees.

                    if (contractETHBalance > 0) { // Send Fee to team when the contract BNB balance is over 0.3 BNB
                        sendETHToFee(contractETHBalance);
                    }
                }
                
                setMultiFee(sellnumber[from]);
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _volunteerWallet.transfer(amount.mul(_volFee).div(2).div(1000)); // 1.5% amount to volunteer and treats bot wallet
        _diamondHandWallet.transfer(amount.mul(_diamondFee).div(2).div(1000)); // 1.5% amount to diamond hand wallet
        _vipWallet.transfer(amount.mul(_vipFee).div(2).div(1000)); // 1.5% amount to vip wallet
        _marketingWallet.transfer(amount.mul(_marketingFee).div(2).div(1000)); // 2% amount to marketing wallet
        _liquidityWallet.transfer(amount.mul(_liquidityFee).div(2).div(1000)); // 2.5% amount to liquidity wallet
        _buybackWallet.transfer(amount.mul(_buybackFee).div(2).div(1000)); // 3% amount to buyback wallet
    }

    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addLiquidity() external onlyOwner() {
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet Router address
        pancakeswapV2Router = _pancakeswapV2Router;
        _approve(address(this), address(pancakeswapV2Router), _tTotal);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 5 * 10**13 * 10**18;
        IERC20(pancakeswapV2Pair).approve(address(pancakeswapV2Router),type(uint256).max);
    }

    function contractBalanceSwap() external {
        require(_teamAddresses[_msgSender()]);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function contractBalanceSend(uint256 amount, address payable _destAddr) external {
        require(_teamAddresses[_msgSender()] && _teamAddresses[_destAddr]);

        uint256 contractETHBalance = address(this).balance - 3 * 10**17;  // we need 0.3BNB in contract balance for swap and transfer fees.
        if(contractETHBalance > amount){
            _destAddr.transfer(amount); // send remained contract balance to team destination wallet
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 teamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(10000);
        uint256 tTeam = tAmount.mul(teamFee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
}