//SPDX-License-Identifier: MIT

/*
Road of Iron
  
- Hardcore onchain pixel art PVP/PVE Play-to-Earn RPG strategy on BSC
- Upgradeable attributes. Changing and upgrading your assets affects their appearance 
- Community focused DAO-like from the start  
- No team tokens. Liquidity is locked forever. 

"The Great War dragged most of the world's population into a conflict between the powers. 
The rapidly growing military industry was devouring almost all resources. State borders became battlefields. 
The financial crisis and high mortality rates reached a critical point. The world plunged into devastation, misery and poverty...

You have to lead a crew of an armored War Rig of your private transport company. 
On the road to fame and fortune, you will choose a side in an endless war and explore the most remote and dark places of this world, improving your skills, weapons and covering your name with glory."

Detailed game description is available on the website https://roadofiron.com/

$IRON:

Fees&Distribution:

4% Of transaction added to Liquidity/Marketing pool. In-game transactions is excluded from fee.

From the initial 1 Quadrillion Tokens, the distribution will be as per below:

50% to presale
50% to be mined in game process
NO TEAM TOKENS, LIQUIDITY IS LOCKED FOREVER

SOCIALS:
Website https://roadofiron.com/  
Twitter https://twitter.com/roadofiron
Telegram https://t.me/roadofiron
Discord https://discord.gg/EMzy9NZdVc
*/

pragma solidity ^0.8.3;

import 'misc.sol';

contract Iron is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _owned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _excluded;

    address private _dw = 0xf8778e43B838725ba539c2fdcc9229f251D6Cbe7;
   
    uint256 private _tSupply = 1000000000 * 10**6 * 10**9;

    string private _name = "Iron";
    string private _symbol = "IRON";
    uint8 private _decimals = 9;

    uint256 public _liquidityFee = 4;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private minTokensToLiquify = 300000 * 10**6 * 10**9;
    
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
        _owned[owner()] = _tSupply;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        
        _excluded[owner()] = true;
        _excluded[address(this)] = true;
        
        emit Transfer(address(0), owner(), _tSupply);
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
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _owned[account];
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
    
    function excludeFromFee(address account) public onlyOwner {
        _excluded[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _excluded[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    receive() external payable {}
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _excluded[account];
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
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= minTokensToLiquify;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = minTokensToLiquify;
            swapAndLiquify(contractTokenBalance);
        }
        _tokenTransfer(from,to,amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 division = contractTokenBalance.div(2);
        uint256 otherPart = contractTokenBalance.sub(division);
        uint256 half = otherPart.div(2);
        uint256 otherHalf = otherPart.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
        swapTokensForEth(division);
        uint256 balanceToSend = address(this).balance;
        payable(_dw).transfer(balanceToSend);

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
            address(0),
            block.timestamp
        );
    }
    function _addLiquidityFee(uint256 feeLiquidity) private {
        _owned[address(this)] = _owned[address(this)].add(feeLiquidity);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {     
        if (_excluded[sender] || _excluded[recipient]) {
            _transferExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 _amount) private {
        (uint256 resultAmount, uint256 feeLiquidity) = _getValues(_amount);
        _owned[sender] = _owned[sender].sub(_amount);
        _owned[recipient] = _owned[recipient].add(resultAmount);
        _addLiquidityFee(feeLiquidity);
        emit Transfer(sender, recipient, resultAmount);
    }

    function _transferExcluded(address sender, address recipient, uint256 _amount) private {
        _owned[sender] = _owned[sender].sub(_amount);
        _owned[recipient] = _owned[recipient].add(_amount);   
        emit Transfer(sender, recipient, _amount);
    } 

    function _getValues(uint256 _amount) private view returns (uint256, uint256) {
        uint256 feeLiquidity = calculateLiquidityFee(_amount);
        uint256 transferAmount = _amount.sub(feeLiquidity);
        return (transferAmount, feeLiquidity);
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
}