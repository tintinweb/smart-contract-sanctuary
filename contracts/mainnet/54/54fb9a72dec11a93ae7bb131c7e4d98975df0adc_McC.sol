/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

/**

Food-Chain Capital: $McC
- You buy on Ethereum, hodl and receive the profits of $McCapital's Holders.

Tokenomics:
5% of each buy/sell goes to existing holders.
8% of each buy/sell goes into to His Majesty's treasury.


Telegram:
https://t.me/FoodChainCapital

SPDX-License-Identifier: UNLICENSED 
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
        if(a == 0) {
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

contract McC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;
    
    mapping (address => User) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"FoodChainCapital";
    string private constant _symbol = unicode"McC";
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 5;
    uint256 private _teamFee = 8;
    uint256 private _launchTime;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _maxBuyAmount;
    uint256 public maxWallet =  _tTotal * 2 / 100; 
    
    address payable private _FeeAddress;
    address payable private _FeeAddress2;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private _cooldownEnabled = true;
    bool private inSwap = false;
    uint256 private buyLimitEnd;

    

    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }

    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable FeeAddress, address payable FeeAddress2) {
        _FeeAddress = FeeAddress;
        _FeeAddress2 = FeeAddress2;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _isExcludedFromFee[FeeAddress] = true;
        _isExcludedFromFee[FeeAddress2] = true;
        
        _isBlackListedBot[address(0x66f049111958809841Bbe4b81c034Da2D953AA0c)] = true;
        _blackListedBots.push(address(0x66f049111958809841Bbe4b81c034Da2D953AA0c));
        
        _isBlackListedBot[address(0x000000005736775Feb0C8568e7DEe77222a26880)] = true;
        _blackListedBots.push(address(0x000000005736775Feb0C8568e7DEe77222a26880));
        
        _isBlackListedBot[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
        _blackListedBots.push(address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40));
        
        _isBlackListedBot[address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D)] = true;
        _blackListedBots.push(address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D));

        _isBlackListedBot[address(0xbcC7f6355bc08f6b7d3a41322CE4627118314763)] = true;
        _blackListedBots.push(address(0xbcC7f6355bc08f6b7d3a41322CE4627118314763));

        _isBlackListedBot[address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d)] = true;
        _blackListedBots.push(address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d));

        _isBlackListedBot[address(0x000000000035B5e5ad9019092C665357240f594e)] = true;
        _blackListedBots.push(address(0x000000000035B5e5ad9019092C665357240f594e));

        _isBlackListedBot[address(0x1315c6C26123383a2Eb369a53Fb72C4B9f227EeC)] = true;
        _blackListedBots.push(address(0x1315c6C26123383a2Eb369a53Fb72C4B9f227EeC));

        _isBlackListedBot[address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D)] = true;
        _blackListedBots.push(address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D));

        _isBlackListedBot[address(0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C)] = true;
        _blackListedBots.push(address(0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C));

        _isBlackListedBot[address(0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA)] = true;
        _blackListedBots.push(address(0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA));
        
        _isBlackListedBot[address(0x42c1b5e32d625b6C618A02ae15189035e0a92FE7)] = true;
        _blackListedBots.push(address(0x42c1b5e32d625b6C618A02ae15189035e0a92FE7));

        _isBlackListedBot[address(0xA94E56EFc384088717bb6edCccEc289A72Ec2381)] = true;
        _blackListedBots.push(address(0xA94E56EFc384088717bb6edCccEc289A72Ec2381));

        _isBlackListedBot[address(0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31)] = true;
        _blackListedBots.push(address(0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31));

        _isBlackListedBot[address(0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27)] = true;
        _blackListedBots.push(address(0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27));

        _isBlackListedBot[address(0xEE2A9147ffC94A73f6b945A6DB532f8466B78830)] = true;
        _blackListedBots.push(address(0xEE2A9147ffC94A73f6b945A6DB532f8466B78830));

        _isBlackListedBot[address(0xdE2a6d80989C3992e11B155430c3F59792FF8Bb7)] = true;
        _blackListedBots.push(address(0xdE2a6d80989C3992e11B155430c3F59792FF8Bb7));

        _isBlackListedBot[address(0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da)] = true;
        _blackListedBots.push(address(0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da));

        _isBlackListedBot[address(0x5136a9A5D077aE4247C7706b577F77153C32A01C)] = true;
        _blackListedBots.push(address(0x5136a9A5D077aE4247C7706b577F77153C32A01C));

        _isBlackListedBot[address(0x0E388888309d64e97F97a4740EC9Ed3DADCA71be)] = true;
        _blackListedBots.push(address(0x0E388888309d64e97F97a4740EC9Ed3DADCA71be));

        _isBlackListedBot[address(0x255D9BA73a51e02d26a5ab90d534DB8a80974a12)] = true;
        _blackListedBots.push(address(0x255D9BA73a51e02d26a5ab90d534DB8a80974a12));

        _isBlackListedBot[address(0xA682A66Ea044Aa1DC3EE315f6C36414F73054b47)] = true;
        _blackListedBots.push(address(0xA682A66Ea044Aa1DC3EE315f6C36414F73054b47));

        _isBlackListedBot[address(0x80e09203480A49f3Cf30a4714246f7af622ba470)] = true;
        _blackListedBots.push(address(0x80e09203480A49f3Cf30a4714246f7af622ba470));

        _isBlackListedBot[address(0x12e48B837AB8cB9104C5B95700363547bA81c8a4)] = true;
        _blackListedBots.push(address(0x12e48B837AB8cB9104C5B95700363547bA81c8a4));

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
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
        require(!_isBlackListedBot[to], "You have no power here!");
        require(!_isBlackListedBot[msg.sender], "You have no power here!");

        if(from != owner() && to != owner()) {
            if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }

            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                _taxFee = 5;
                _teamFee = 8;
                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                        cooldown[to].buy = block.timestamp + (15 seconds);
                    }
                }
            }

            // sell
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
                _taxFee = 5;
                _teamFee = 8;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            
            if(!inSwap && from != uniswapV2Pair && tradingOpen) {
                if(contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
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
        _FeeAddress.transfer(amount.div(2));
        _FeeAddress2.transfer(amount.div(2));
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function addLiquidity() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxBuyAmount = 10000000000 * 10**9; // 1% TX LIMIT 
        _launchTime = block.timestamp;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        buyLimitEnd = block.timestamp + (300 seconds);
    }

    function manualswap() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _FeeAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }
    
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function excludeAccount(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function isBlackListed(address account) public view returns (bool) {
        return _isBlackListedBot[account];
    }
    
    function addBotToBlackList(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not blacklist Uniswap router.');
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;
        _blackListedBots.push(account);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 100)/1e9, "Cannot set maxWallet lower than 2%");
        maxWallet = newNum * (10**9);
    }
    
    function removeBotFromBlackList(address account) external onlyOwner() {
        require(_isBlackListedBot[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackListedBots.length; i++) {
            if (_blackListedBots[i] == account) {
                _blackListedBots[i] = _blackListedBots[_blackListedBots.length - 1];
                _isBlackListedBot[account] = false;
                _blackListedBots.pop();
                break;
            }
        }
    }
    
    function setExcludeFromFee(address account, bool excluded) external onlyOwner() {
        _isExcludedFromFee[account] = excluded;
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].buy;
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }
}