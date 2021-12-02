// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

// usage:
// change the name of the contract, name of the file, remove builds, rework migrations script
// deploy previously adjusting all TBDs
// burn if needed
// add bulksender app address to excluded from fee
// transfer tokens to presale participants
// call getPair and check if the address matches the pair, if not call setPair with correct address
// add liquidity
// lock liquidity
// check if everything works as intended
// renounce

contract TestCoin is Ownable, IERC20Metadata {
    struct LaunchLimit {
        uint256 blockNumber;
        uint256 amount;
    }

    string private constant _name = "BOTS GONNA DIE"; // TBD
    string private constant _symbol = "BGD"; //TBD 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _setCoolDown;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    LaunchLimit[4] private _launchLimits;
    address[] private _excluded;
    address private _admin;
    address private _uniswapV2Pair;
    IUniswapV2Router02 private _uniswapV2Router;
    address payable private _charityWallet;
    address payable private _marketingWallet;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**9 * 10**6; //TBD
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _maxTxAmount;
    uint256 private _numTokensSellToAddToLiquidity;
    uint256 private _tFeeTotal;
    uint16 private _refTax = 20; // Fee for holders TBD
    uint16 private _liqTax = 20; // Fee for liquidity TBD
    uint16 private _charityTax = 30; // Fee for charity TBD
    uint16 private _marketingTax = 30; // Fee for marketing TBD
    uint16 private _previousRefTax = _refTax;
    uint16 private _previousLiqTax = _liqTax;
    uint16 private _previousCharityTax = _charityTax;
    uint16 private _previousMarketingTax = _marketingTax;
    uint16 private _afterLaunchLiqTax = _liqTax;
    uint8 private constant _decimals = 6;
    bool private _swapAndLiquifyEnabled;
    bool private _inSwapAndLiquify;
    bool private _coolDownEnabled;
    bool private _tradingOpen;
    bool private _launchPhase;
    event AdminRightsTransferred(address indexed previousAdmin, address indexed newAdmin);
    event TradingOpened();
    event SwapAndLiquify(uint256 liqValueAddedInEth);

    modifier onlyOwnerOrAdmin {
        require(owner() == _msgSender() || admin() == _msgSender(), "Caller is not the owner nor the admin");
        _;
    }

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function transferAdminRights(address newAdmin) external onlyOwnerOrAdmin {
        require(newAdmin != address(0), "New admin is the zero address");
        _setAdmin(newAdmin);
    }

    function _setAdmin(address newAdmin) private {
        address oldAdmin = admin();
        _admin = newAdmin;
        _isExcludedFromFee[oldAdmin] = false;
        _isExcludedFromFee[newAdmin] = true;
        emit AdminRightsTransferred(oldAdmin, newAdmin);
    }

    receive() external payable {}

    constructor() { 
        _admin = owner();
        _rOwned[owner()] = _rTotal;
        _maxTxAmount = _tTotal/10; // TBD
        _numTokensSellToAddToLiquidity = _tTotal/200; //TBD
        _charityWallet = payable(0xEC14a05386012901b999B5E37913702eeD49bB04); // TBD
        _marketingWallet = payable(0xe2A04244a6D1BdC59a68ae31823f0998C72e80F9); // TBD
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[admin()] = true;
        _approve(owner(), address(_uniswapV2Router), MAX);
        _approve(address(this), address(_uniswapV2Router), MAX);

        emit AdminRightsTransferred(address(0), owner());
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_allowances[sender][_msgSender()] - amount >= 0, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        require(_allowances[_msgSender()][spender] - subtractedValue >= 0, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = 
            _getRValues(tAmount, tFee, tLiquidity, _getRate());
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256, uint256)
    {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate)
        private
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
                return (_rTotal, _tTotal); 
            }
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }

        if (rSupply < _rTotal / _tTotal) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        }
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _refTax / 10**3;
    }

    function _calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount * (_liqTax + _charityTax + _marketingTax) / 10**3;
    }

    function _removeAllFee() private {
        _previousRefTax = _refTax;
        _previousLiqTax = _liqTax;
        _previousCharityTax = _charityTax;
        _previousMarketingTax = _marketingTax;

        _refTax = 0;
        _liqTax = 0;
        _charityTax = 0;
        _marketingTax = 0;
    }

    function _restoreAllFee() private {
        _refTax = _previousRefTax;
        _liqTax = _previousLiqTax;
        _charityTax = _previousCharityTax;
        _marketingTax = _previousMarketingTax;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function _openTrading() private {
        _tradingOpen = true;
        _launchPhase = true;
        _coolDownEnabled = true;
        _swapAndLiquifyEnabled = true;
        _launchLimits[0].blockNumber = block.number + 5;
        _launchLimits[1].blockNumber = block.number + 10;
        _launchLimits[2].blockNumber = block.number + 15;
        _launchLimits[3].blockNumber = block.number + 20;
        _launchLimits[0].amount = _maxTxAmount;
        _launchLimits[1].amount = _tTotal / 1000;
        _launchLimits[2].amount = 2 * _tTotal / 1000;
        _launchLimits[3].amount = 3 * _tTotal / 1000;

        // bots are 90% taxed in the first 3 blocks
        _liqTax = 900 - _refTax - _charityTax - _marketingTax;
        
        emit TradingOpened();
    }

    function failsafeSwapAndLiquify(uint256 amount) external onlyOwnerOrAdmin {
        _swapAndLiquify(amount);
    }

    function recoverTokens(address tokenAddress) external onlyOwnerOrAdmin {
        require(tokenAddress != address(this), "Don't steal from your own contract");
        IERC20Metadata token = IERC20Metadata(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        if(balance > 0) {
            token.transfer(_marketingWallet, balance);
        }
    }
    
    function recoverETH() external onlyOwnerOrAdmin {
        if(address(this).balance > 0) {
            _marketingWallet.transfer(address(this).balance);
        }
    }

    function setCharityWallet(address payable newCharityWallet) external onlyOwnerOrAdmin {
        _charityWallet = newCharityWallet;
    }

    function getCharityWallet() external view returns (address) {
        return _charityWallet;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwnerOrAdmin {
        _marketingWallet = newMarketingWallet;
    }

    function getMarketingWallet() external view returns (address) {
        return _marketingWallet;
    }    

    function setLiquidityFeePercent(uint16 newLiqTax) external onlyOwnerOrAdmin {
        require(newLiqTax <= 5, "New tax cannot exceed 5%");
        _liqTax = 10*newLiqTax;
    }

    function getLiquidityFeePercent() external view returns (uint16) {
        return _liqTax/10;
    }

    function setCharityFeePercent(uint16 newCharityTax) external onlyOwnerOrAdmin {
        require(newCharityTax <= 5, "New tax cannot exceed 5%");
        _charityTax = 10*newCharityTax;
    }

    function getCharityFeePercent() external view returns (uint16) {
        return _charityTax/10;
    }

    function setMarketingFeePercent(uint16 newMarketingTax) external onlyOwnerOrAdmin {
        require(newMarketingTax <= 5, "New tax cannot exceed 5%");
        _marketingTax = 10*newMarketingTax;
    }

    function getMarketingFeePercent() external view returns (uint16) {
        return _marketingTax/10;
    }

    function setRouter(IUniswapV2Router02 newRouter) external onlyOwnerOrAdmin {
        _uniswapV2Router = newRouter;
        _approve(address(this), address(_uniswapV2Router), MAX);
    }

    function getRouter() external view returns (address) {
        return address(_uniswapV2Router);
    }

    function setPair(address newPair) external onlyOwnerOrAdmin {
        _uniswapV2Pair = newPair;
    }

    function getPair() external view returns (address) {
        return _uniswapV2Pair;
    }    

    function setCoolDown(bool isEnabled) external onlyOwnerOrAdmin {
        _coolDownEnabled = isEnabled;
    } 

    function getCoolDown() external view returns (bool) {
        return _coolDownEnabled;
    }    

    function setSwapAndLiquify(bool isEnabled) external onlyOwnerOrAdmin {
        _swapAndLiquifyEnabled = isEnabled;
    } 

    function getSwapAndLiquify() external view returns (bool) {
        return _swapAndLiquifyEnabled;
    }    

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyOwnerOrAdmin {
        require(newMaxTxAmount >= _tTotal/20, "The amount can't be at less than 5%");
        _maxTxAmount = newMaxTxAmount;
    }

    function getMaxTxAmount() external view returns (uint256) {
        return _maxTxAmount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 newNumTokensSellToAddToLiquidity) external onlyOwnerOrAdmin {
        _numTokensSellToAddToLiquidity = newNumTokensSellToAddToLiquidity;
    }

    function getNumTokensSellToAddToLiquidity() external view returns (uint256) {
        return _numTokensSellToAddToLiquidity;
    }    

    function setExcludedFromFee(address account, bool isExcluded) external onlyOwnerOrAdmin {
        _isExcludedFromFee[account] = isExcluded;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setExcludedFromReward(address account, bool isExcluded) external onlyOwnerOrAdmin {
        if(isExcluded) {
            require(!_isExcluded[account], "Account already excluded");
            
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else {
            require(_isExcluded[account],  "Account already included");
            
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
        
        _isExcluded[account] = isExcluded;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0) || _msgSender() == owner(), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
        }

        if(!_tradingOpen && from == owner() && to == _uniswapV2Pair) {
            _openTrading();
        }

        if(_coolDownEnabled) {
            if(from == _uniswapV2Pair) {
                require(_setCoolDown[to] <= block.number, "Cool down, frequent trading not allowed");
                _setCoolDown[to] = block.number + 3;
            } else if(to == _uniswapV2Pair) {
                require(_setCoolDown[from] <= block.number, "Cool down, frequent trading not allowed");
                _setCoolDown[from] = block.number + 3;
            }
        }

        if (_launchPhase && from == _uniswapV2Pair) {
            uint8 phase;
            if(_launchLimits[0].blockNumber >= block.number) {
                phase = 0;
            } else if(_launchLimits[1].blockNumber >= block.number) {
                phase = 1;
            } else if(_launchLimits[2].blockNumber >= block.number) {
                phase = 2;
            } else if(_launchLimits[3].blockNumber >= block.number) {
                phase = 3;
            } else {
                _launchPhase = false;
            }

            if(_launchPhase) {
                require(amount <= _launchLimits[phase].amount, "Don't be so greedy!");
            }
            
            if(phase > 0 || !_launchPhase) {
                _liqTax = _afterLaunchLiqTax;
            }
        }

        if(_swapAndLiquifyEnabled) {
            bool readyToSwapAndLiquify = (balanceOf(address(this)) >= _numTokensSellToAddToLiquidity);
            if (readyToSwapAndLiquify && !_inSwapAndLiquify && to == _uniswapV2Pair) {
                _swapAndLiquify(_numTokensSellToAddToLiquidity);
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        require(amount <= balanceOf(address(this)), "Swap amount exceeds the contract balance");
        if(_liqTax == 0 && _charityTax == 0 && _marketingTax == 0) return;

        // optimize function to call swap only once. calculations for liquidity to not exactly match
        // X*Y=K curve, however, it will be sorted out by the pool. that way gas is saved whenever
        // this function is called
        uint256 initialEthBalance = address(this).balance;
        uint256 tokenSwapAmount = amount * ((_liqTax / 2) + _charityTax + _marketingTax) / 
                                                 (_liqTax + _charityTax + _marketingTax);
        uint256 tokenLiqAmount = amount - tokenSwapAmount;
        _swapTokensForETH(tokenSwapAmount);

        uint256 afterSwapEthBalance = address(this).balance;
        uint256 ethLiq = (afterSwapEthBalance - initialEthBalance) * (_liqTax / 2) / 
                                (_liqTax + _charityTax + _marketingTax);

        if(tokenLiqAmount > 0) {
            // probably there will be slightly less eth than really required by X*Y=K curve hence 
            // the pool will not take the whole tokenLiqAmount. the rest will stay on the balance 
            // for the further swaps. if there was too much ether provided, there would be one 
            // more redundant transfer from the pool back to the contract. save the gas!
            _addLiquidity(tokenLiqAmount, ethLiq);

            // record how much value was added back to the liquidity pool
            emit SwapAndLiquify(2 * (afterSwapEthBalance - address(this).balance));
        }

        // whatever eth left send it to charity and for marketing 
        // (assumed that the most of the eth that wasn't needed was refunded by the pool) 
        // charity/marketing share ratio is respected
        uint256 afterLiqEthBalance = address(this).balance;
        if(_charityTax > 0 && _marketingTax > 0 && afterLiqEthBalance > 0) {
            if(_charityWallet == _marketingWallet) {
                _charityWallet.transfer(afterLiqEthBalance);
            } else {
                _charityWallet.transfer(afterLiqEthBalance * _charityTax / (_charityTax + _marketingTax));
                _marketingWallet.transfer(address(this).balance);
            }
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) _removeAllFee();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
         uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(amount);
        
        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            // standard transfer, both parties are subject to fees
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            // transfer to excluded from fees
            _tOwned[sender]    = _tOwned[sender]    - amount;
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            // transfer from excluded from fees
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        } else {
            // transfer from excluded to excluded from fees
            _tOwned[sender]    = _tOwned[sender]    - amount;
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        }

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);

        if (!takeFee) _restoreAllFee();
    }
}

// SPDX-License-Identifier: GPL3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: GPL3.0

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: GPL3.0

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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