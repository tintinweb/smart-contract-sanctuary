// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Context.sol";

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

/*
1. Name  - StrikeX
2. Symbol - STRX 
3. MAX Supply -  1 billion
4. Selling tax 3%  - only applicable for 6 months (0% thereafter)
5. 3% selling tax distribution – 
    * 1.5% to liquidity pool 
    * 1% to team wallet (sent as BNB)
    * 0.5% to ‘buyback’ wallet (sent as BNB)
    * Anti-dump Max Sell no more than 0.5% of supply (5M) over 24 hours – only applicable for 6 months (0% thereafter)
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";

import "./interface/IERC20.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router02.sol";

import "./library/SafeMath.sol";


contract StrikeX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"StrikeX";
    string private constant _symbol = "STRX";
    uint8 private constant _decimals = 9;

    mapping (address => uint256) private _tokenSold;
    mapping (address => uint256) private _startTime;
    mapping (address => uint256) private _blockTime;
    uint256 public _maxSoldAmount = 5 * 10**6 * 10**9;

    mapping(address => uint256) private _rOwned; // reflected token owned amount
    mapping(address => uint256) private _tOwned; // addresses token owned amount
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee; // wallets excluded from fee
    

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**9 * 10**9; // total supply 1,000,000,000 (1 billion)
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // reflected total supply
    uint256 public minBalance = 10 * 10**9;

    uint256 public _tFeeTotal; // total fee of reflection
    uint256 public _taxFee = 0; // 3% Strike reflection (auto)
    uint256 public _contractFee = 300; // 3% total team fee
    
    uint256 public _liquidityFee = 150; // 1.5% liquidity fee 150 / 10000
    uint256 public _teamWalletFee = 100; // 1% team wallet fee
    uint256 public _buybackWalletFee = 50; // 0.5% buyback fee 50 / 10000

    //mapping(address => bool) private bots; // bots blacklist
    

    address payable public _teamWallet; // team wallet address
    address payable public _buybackWallet; // buyback wallet address

    IUniswapV2Router02 public uniswapV2Router; // pancakeswap v2 router
    address public uniswapV2Pair; // pancakeswap v2 pair
 
    bool public inSwap = false;
    bool public swapEnabled = true; 
    uint256 deploymentTime;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        // ropsten test router
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // pancake swap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        // bsc main router
        //0x10ED43C718714eb63d5aA57B78B54704E256024E
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _teamWallet = payable(0x5581f7b5F1133c076b72ea491c6E7e4c52CA1CfE); 
        _buybackWallet = payable(0xA43c9E46735c0a8279a64b46F1Aa43B08d9d4ad0);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamWallet] = true;
        _isExcludedFromFee[_buybackWallet] = true;

        deploymentTime  = block.timestamp;

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
    

    function swapstatus() public view returns (bool) {
        return swapEnabled;
    }

    // function cooldownStatus() public view returns (bool) {
    //     return cooldownEnabled;
    // }

    // function tradingStatus() public view returns (bool) {
    //     return tradingOpen;
    // }

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

    function balanceOf222(address account) public view returns (uint256) {
        return _rOwned[account];
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

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_taxFee == 0 && _contractFee == 0) return;
        _taxFee = 0;
        _contractFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = 300;
        _contractFee = 300;
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
                       
            if(_tokenSold[from] == 0){
                _startTime[from] = block.timestamp;
            }

            _tokenSold[from] = _tokenSold[from] + amount;

            if( block.timestamp < _startTime[from] + (1 days)){
                require(_tokenSold[from] <= _maxSoldAmount, "Sold amount exceeds the maxTxAmount.");
            }else{
                _startTime[from] = block.timestamp;
                _tokenSold[from] = 0;
            }

            //require(!bots[from] && !bots[to]);

            // buy 
            /*
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                // require(tradingOpen);
                // require(amount <= _maxTxAmount);
                // require(buycooldown[to] < block.timestamp);

                // buycooldown[to] = block.timestamp + (5 seconds);
            }
            */

            //if (!inSwap && to == address(uniswapV2Router) && swapEnabled) {
            if (!inSwap && swapEnabled && to == uniswapV2Pair && from != address(this)) {                

                uint256 strikeBalance = balanceOf(address(this));

                if(strikeBalance > minBalance){                    
                    swapTokens(strikeBalance);
                }
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokens(uint256 tokenBalance) private lockTheSwap {
        uint256 liquidityTokens = tokenBalance.div(4); // 0.75%
        uint256 otherBNBTokens = tokenBalance - liquidityTokens; // 2.25%

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(otherBNBTokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 liquidityCapacity = newBalance.div(3);

        addLiqudity(liquidityTokens, liquidityCapacity);

        uint256 teamCapacity = newBalance - liquidityCapacity;
        
        uint256 teamBNB = teamCapacity.mul(2).div(3);
        _teamWallet.transfer(teamBNB);

        uint256 buybackBNB = teamCapacity - teamBNB;
        _buybackWallet.transfer(buybackBNB);

    }

    function swapTokensForEth(uint256 tokenAmount) private{
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addLiqudity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the contract
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    // function openTrading() public onlyOwner {
    //     require(liquidityAdded);
    //     tradingOpen = true;
    // }

    function contractBalanceSwap() external onlyOwner{
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function contractBalanceSend(uint256 amount, address payable _destAddr) external onlyOwner{
        uint256 contractETHBalance = address(this).balance - 1 * 10**17;  // we need 0.1BNB in contract balance for swap and transfer fees.
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tContract) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeContract(tContract);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeContract(uint256 tContract) private {
        uint256 currentRate = _getRate();
        uint256 rContract = tContract.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rContract);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tContract) = _getTValues(tAmount, _taxFee, _contractFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tContract, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tContract);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 contractFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(10000);
        uint256 tContract = tAmount.mul(contractFee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tContract);
        return (tTransferAmount, tFee, tContract);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tContract, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rContract = tContract.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rContract);
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

    function _setMaxSoldAmount(uint256 maxvalue) external onlyOwner {
        _maxSoldAmount = maxvalue;
    }
    function _setMinBalance(uint256 minValue) external onlyOwner {
        minBalance = minValue;
    }
    function _setApplyContractFee(bool isFee) external onlyOwner {
        if(isFee) {
            _contractFee = 300;
        } else {
            _contractFee = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

