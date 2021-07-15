/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/*
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |   ______     | || |     _____    | || |    _______   | || |  ____  ____  | || | _____  _____ | || |  _________   | || |     _____    | |
| |  |_   _ \    | || |    |_   _|   | || |   /  ___  |  | || | |_   ||   _| | || ||_   _||_   _|| || | |_   ___  |  | || |    |_   _|   | |
| |    | |_) |   | || |      | |     | || |  |  (__ \_|  | || |   | |__| |   | || |  | |    | |  | || |   | |_  \_|  | || |      | |     | |
| |    |  __'.   | || |      | |     | || |   '.___`-.   | || |   |  __  |   | || |  | '    ' |  | || |   |  _|      | || |      | |     | |
| |   _| |__) |  | || |     _| |_    | || |  |`\____) |  | || |  _| |  | |_  | || |   \ `--' /   | || |  _| |_       | || |     _| |_    | |
| |  |_______/   | || |    |_____|   | || |  |_______.'  | || | |____||____| | || |    `.__.'    | || | |_____|      | || |    |_____|   | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
*/
/* SPDX-License-Identifier: Unlicensed */
pragma solidity ^0.8.6;

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
    event Team(address indexed from, address indexed to, uint256 value);
    event Charity(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event DistributedFee(address indexed from, string msg, uint256 value);
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

contract BishuFinance is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Bishu Finance";
    string private constant _symbol = "BishuFi";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFee = 2;
    uint256 private _teamFee = 2;
    // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
    uint256 private _charityFee = 1;
    // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
    uint256 private _burnFee = 1;
    mapping(address => bool) private bots;
    mapping(address => uint256) public buycooldown;
    mapping(address => uint256) public sellcooldown;
    mapping(address => uint256) public firstsell;
    mapping(address => uint256) public sellnumber;
    // made public for transparency
    address payable public _teamAddress;
    address payable public _charityAddress;
    address public _routerAddress;
    address payable public _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    //
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool public tradingOpen = false;
    bool public liquidityAdded = false;
    bool private inSwap = false;
    bool public swapEnabled = false;
    bool public cooldownEnabled = false;
    uint256 public _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(address payable addr1, address payable addr2, address addr3) {
        _teamAddress = addr1;
        _charityAddress = addr2;
        _routerAddress = addr3;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_burnAddress] = true;
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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

    function setIsExcludedFromFee(address _address,bool _isExcluded) external onlyOwner() {
        _isExcludedFromFee[_address] = _isExcluded;
    }    

    function setTeamAddress(address payable _address) external onlyOwner() {
        _teamAddress = _address;
    }

    function setCharityAddress(address payable _address) external onlyOwner() {
        _charityAddress = _address;
    }

    function setRouterAddress(address _address) external onlyOwner() {
        _routerAddress = _address;
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
        _charityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = 2;
        _teamFee = 2;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _charityFee = 1;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _burnFee = 1;
    }

    function setRemoveAllFee() external onlyOwner {
        if (_taxFee == 0 && _teamFee == 0) return;
        _taxFee = 0;
        _teamFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }

    function setRestoreAllFee() external onlyOwner {
        _taxFee = 2;
        _teamFee = 2;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _charityFee = 1;
        // 0.5% fee will be calculated later, number 1 is set because variable cannot store floating point
        _burnFee = 1;
    }
    
    function setFee(uint256 multiplier) private {
        if (multiplier == 0) {
            uint256 tfeeWhole = 3;
            _taxFee = tfeeWhole;
        }
        else if (multiplier == 1) {
            uint256 tfeeWhole = 6;
            _taxFee = tfeeWhole;

        }
        else if (multiplier == 2) {
            uint256 tfeeWhole = 17;
            _taxFee = tfeeWhole;

        }
        else if (multiplier == 3) {
            uint256 tfeeWhole = 24;
            _taxFee = tfeeWhole;

        }
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
        bool takeFee = false;

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to], "You are a bot!");
            
            // cooldown buy handler
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(tradingOpen, "Trading is not open!");
                require(amount <= _maxTxAmount, "Amount larger than max tx amount!");
                require(buycooldown[to] < block.timestamp, "Wait for buy cooldown!");
                buycooldown[to] = block.timestamp + (30 seconds);
                takeFee = true;
            }

            // sell handler
            if (!inSwap && to == uniswapV2Pair && from != address(uniswapV2Router) && swapEnabled) {
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount, "Slippage is over 2.9% or over MaxTxAmount!");
                require(sellcooldown[from] < block.timestamp, "Wait for sell cooldown!");
                if(firstsell[from] + (1 days) < block.timestamp){
                    sellnumber[from] = 0;
                }
                if (sellnumber[from] == 0) {
                    firstsell[from] = block.timestamp;
                    sellcooldown[from] = block.timestamp + (1 hours);
                }
                else if (sellnumber[from] == 1) {
                    sellcooldown[from] = block.timestamp + (2 hours);
                }
                else if (sellnumber[from] == 2) {
                    sellcooldown[from] = block.timestamp + (6 hours);
                }
                else if (sellnumber[from] == 3) {
                    sellcooldown[from] = firstsell[from] + (1 days);
                }
                setFee(sellnumber[from]);
                sellnumber[from]++;
                takeFee = true;
            }

            // block transfer if sell cooldown
            if (to != uniswapV2Pair) {
               require(sellcooldown[from] < block.timestamp, "Wait for sell cooldown!"); 
            }
        }
        
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
        _teamAddress.transfer(amount.div(2));
        _charityAddress.transfer(amount.div(2));
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 3000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        // moved fuction above to reduce stack
        // _getValues //
            // _getTValues
            uint256 tFee = tAmount.mul(_taxFee).div(100);
            uint256 tTeam = tAmount.mul(_teamFee).div(100);
            // 0.5% fee by dividing by 200
            uint256 tCharity = tAmount.mul(_charityFee).div(200);
            uint256 tBurn = tAmount.mul(_burnFee).div(200);
            //
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam).sub(tCharity).sub(tBurn);
            // _getRValues
            uint256 currentRate = _getRate();
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rFee = tFee.mul(currentRate);
            uint256 rTeam = tTeam.mul(currentRate);
            uint256 rCharity = tCharity.mul(currentRate);
            uint256 rBurn = tBurn.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam).sub(rCharity).sub(rBurn);
        //
        _calculateReflectTransfer(sender,recipient,rAmount,rTransferAmount);
        _takeTeam(tTeam);
        _takeCharity(tCharity);
        _takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Team(sender, _teamAddress, tTeam);
        emit Charity(sender, _charityAddress, tCharity);
        emit DistributedFee(sender, "Fee split between all holders!", tFee);
        emit Burn(sender, _burnAddress, tBurn);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[_teamAddress] = _rOwned[_teamAddress].add(rTeam);
    }
    // added charity
    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate = _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
    }
    // added burn
    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rBurn);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    // added to reduce stack
    function _calculateReflectTransfer(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        
       _rOwned[sender] = _rOwned[sender].sub(rAmount);
       _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
    }

    // allow contract to receive deposits
    receive() external payable {}

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