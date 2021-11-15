/*

With a dynamic sell limit based on price impact and increasing sell cooldowns and redistribution taxes on consecutive sells, Donut Cat block bots and discourage dumping.

- Token Information
Sells limited to 3% of the Liquidity Pool, < 3% price impact
Sell cooldown increases on consecutive sells, 4 sells within a 24 hours period are allowed

Sell restrictions
First 1 hour restriction ( Bot Protection ) - 6x fee bot sells 
After 1 hour restriction ( Protect liquidity ) - 1x fee on the first sell, increases 2x, 3x, 4x on consecutive sells

Fee Percentages
1. 0.50% Blockchain Developer
2. 1.00% Diamond Hand Corporate Development
3. 1.00% Vip Programs
4. 4.00% BNB Reflection
5. 4.00% Meowington Buyback
6. 0.50% Treats Bot
7. 2.00% Marketing
8. 2.00% Liquidity
9. 2.00% DCAT reflection (auto)

total: 17%

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract DonutCat is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"Donut Cat v2";
    string private constant _symbol = "DCAT";
    uint8 private constant _decimals = 18;

    mapping(address => uint256) private _rOwned; // reflected token owned amount
    mapping(address => uint256) private _tOwned; // addresses token owned amount
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee; // wallets excluded from fee
    mapping(address => bool) private _teamAddresses; // team wallet check list

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**15 * 10**18; // total supply 1,000,000,000,000,000 (1 quadrillion)
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // reflected total supply
    uint256 private constant minBalance = 2 * 10**12 * 10 ** 18;

    uint256 private _tFeeTotal; // total fee of reflection
    uint256 private _teamFee = 1500; // 15% total team fee
    uint256 private _taxFee = 200; // 2% DCAT reflection (auto)
    uint256 private _devFee = 50; // 0.5% developer fee 50 / 10000  - solidity does not handle float number
    uint256 private _volFee = 50; // 0.5% volunteer fee 50 / 10000
    uint256 private _diamondFee = 100; // 1% diamond hand fee 100 / 10000 
    uint256 private _vipFee = 100; // 1% vip fee 100 / 10000
    uint256 private _marketingFee = 200; // 2% marketing fee 200 / 10000
    uint256 private _liquidityFee = 200; // 2% liquidity fee 200 / 10000
    uint256 private _reflectionFee = 400; // 4% reflection fee 400 / 10000
    uint256 private _buybackFee = 400; // 4% buyback fee 400 / 10000

    mapping(address => bool) private bots; // bots blacklist
    mapping(address => uint256) private buycooldown; // buy cooldown time - 30 minutes
    mapping(address => uint256) private sellcooldown;  // sell cooldown time - 1 hour, 2 hours, 6 hours, 1 day
    mapping(address => uint256) private firstsell; // first sell time
    mapping(address => uint256) private sellnumber;  // calculate consecutive sells

    address payable private _developerWallet; // developer wallet address
    address payable private _volunteerWallet; // volunteer wallet address
    address payable private _diamondHandWallet; // diamond hand wallet address
    address payable private _vipWallet; // vip wallet address
    address payable private _marketingWallet; // marketing wallet address
    address payable private _liquidityWallet; // liquidity wallet address
    address payable private _reflectionWallet; // reflection wallet address
    address payable private _buybackWallet; // buyback wallet address

    IUniswapV2Router02 private uniswapV2Router; // pancakeswap v2 router
    address private uniswapV2Pair; // pancakeswap v2 pair

    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;

    uint256 private _maxTxAmount = _tTotal;
    uint256 private _tradeStartTime;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _developerWallet = payable(0x7df6838dC60b060332170fd72F35be73Ce5eC4B7);
        _volunteerWallet = payable(0x99eC082052BC0bfa5FBFc7B9836ee6035931C2E2);
        _diamondHandWallet = payable(0xcDAA088E30155406579eF70981BCD25D5efA82D6);
        _vipWallet = payable(0x1dd64FeD6293A002c38A54130290E7C295765b0C);
        _marketingWallet = payable(0x05FeA64CDA004FB4491349fD7fb8e6255276AB05);
        _liquidityWallet = payable(0xFf437a96EF9E151d6eC33B89Aa7dAC615D3FA1de);
        _reflectionWallet = payable(0xacDEf39425A2bdC07D7A0D4933DED0DecbbBB59F);
        _buybackWallet = payable(0x7df6838dC60b060332170fd72F35be73Ce5eC4B7);

        _rOwned[_msgSender()] = _rTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developerWallet] = _teamAddresses[_developerWallet] = true;
        _isExcludedFromFee[_volunteerWallet] = _teamAddresses[_volunteerWallet] = true;
        _isExcludedFromFee[_diamondHandWallet] = _teamAddresses[_diamondHandWallet] = true;
        _isExcludedFromFee[_vipWallet] = _teamAddresses[_vipWallet] = true;
        _isExcludedFromFee[_marketingWallet] = _teamAddresses[_marketingWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = _teamAddresses[_liquidityWallet] = true;
        _isExcludedFromFee[_reflectionWallet] = _teamAddresses[_reflectionWallet] = true;
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
        _taxFee = 200;
        _teamFee = 1500;
    }
    
    function setMultiFee(uint256 multiplier) private {
        uint256 multi = multiplier;
        if( multi == 0)
            multi = 1;
        _teamFee = _teamFee * multi;
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
                if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                    require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Uniswap only");
                }
            }

            require(!bots[from] && !bots[to]);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(tradingOpen);
                require(amount <= _maxTxAmount);
                require(buycooldown[to] < block.timestamp);

                buycooldown[to] = block.timestamp + (5 seconds);
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                require(amount <= _maxTxAmount);
                require(sellcooldown[from] < block.timestamp);

                if(firstsell[from] + (1 days) < block.timestamp){
                    sellnumber[from] = 0;
                }

                if(_tradeStartTime + (1 hours) > block.timestamp){
                    sellnumber[from] = 6;
                    firstsell[from] = block.timestamp;
                    sellcooldown[from] = firstsell[from] + (1 days);
                }else{
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
                        sellcooldown[from] = block.timestamp + (6 hours);
                    }
                    else if (sellnumber[from] == 3) {
                        sellnumber[from]++;
                        sellcooldown[from] = firstsell[from] + (1 days);
                    }
                }

                // uint256 contractTokenBalance = balanceOf(address(this));

                // if(contractTokenBalance > minBalance){
                //     swapTokensForEth(contractTokenBalance);
                //     uint256 contractETHBalance = address(this).balance - 3 * 10**17;  // Always need 0.3BNB in contract balance for swap and transfer fees.

                //     if (contractETHBalance > 0) { // Send Fee to team when the contract BNB balance is over 1 BNB
                //         sendETHToFee(contractETHBalance);
                //     }
                // }
                
                //setMultiFee(sellnumber[from]);
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
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        _developerWallet.transfer(amount.mul(_devFee).div(2).div(1000)); // 0.5% amount to developer wallet
        _volunteerWallet.transfer(amount.mul(_volFee).div(2).div(1000)); // 0.5% amount to volunteer wallet

        _diamondHandWallet.transfer(amount.mul(_diamondFee).div(2).div(1000)); // 1% amount to diamond hand wallet
        _vipWallet.transfer(amount.mul(_vipFee).div(2).div(1000)); // 1% amount to vip wallet

        _marketingWallet.transfer(amount.mul(_marketingFee).div(2).div(1000)); // 2% amount to marketing wallet
        _liquidityWallet.transfer(amount.mul(_liquidityFee).div(2).div(1000)); // 2% amount to liquidity wallet

        _reflectionWallet.transfer(amount.mul(_reflectionFee).div(2).div(1000)); // 4% amount to reflection wallet
        _buybackWallet.transfer(amount.mul(_buybackFee).div(2).div(1000)); // 4% amount to buyback wallet
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
        _tradeStartTime = block.timestamp;
    }

    function addLiquidity() external onlyOwner() {
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet Router address
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // testnet Router address
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 10**15 * 10**18;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
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

