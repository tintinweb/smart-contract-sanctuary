// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './utils/Ownable.sol';

contract DynamicsToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event Burn(address indexed to, uint256 value);

    struct User {
        uint256 buyCD;
        uint256 sellCD;
        uint256 lastBuy;
        bool exists;
    }

    struct Fees {
        uint256 reflection;
        uint256 project;
        uint256 liquidity;
        uint256 burn;
        uint256 marketing;
    }

    enum FeeLevels {
        LEVEL1,
        LEVEL2,
        LEVEL3,
        LEVEL4,
        LEVEL5
    }

    struct SellFees {
        uint256 saleCoolDownTime;
        uint256 saleCoolDownFee;
        uint256 saleSizeLimitPercent;
        uint256 saleSizeLimitPrice;
    }

    uint256 private buyerDiscountPrice = 2 ether;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => User) private trader;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name = "Dynamics Token";
    string private constant _symbol = "DYNA";
    uint256 private _decimals = 18;

    Fees public buyFees = Fees({reflection: 3, project: 3, liquidity: 2, burn: 2, marketing: 1});
    Fees public transferFees = Fees({reflection: 1, project: 1, liquidity: 1, burn: 0, marketing: 0});
    mapping(FeeLevels => SellFees) public sellFees;

    Fees private previousBuyFees;
    Fees private previousTransferFees;
    SellFees private zeroFees = SellFees(0, 0, 0, 0);
    mapping(FeeLevels => SellFees) private previousSellFees;

    uint256 public _minimumTimeFee = 2;
    uint256 public _minimumSizeFee = 2;

    function initSellFees() private {
        sellFees[FeeLevels.LEVEL1] = SellFees({
            saleCoolDownTime: 1 hours,
            saleCoolDownFee: 50,
            saleSizeLimitPercent: 5,
            saleSizeLimitPrice: 50
        });
        sellFees[FeeLevels.LEVEL2] = SellFees({
            saleCoolDownTime: 6 hours,
            saleCoolDownFee: 40,
            saleSizeLimitPercent: 4,
            saleSizeLimitPrice: 40
        });
        sellFees[FeeLevels.LEVEL3] = SellFees({
            saleCoolDownTime: 12 hours,
            saleCoolDownFee: 30,
            saleSizeLimitPercent: 3,
            saleSizeLimitPrice: 30
        });
        sellFees[FeeLevels.LEVEL4] = SellFees({
            saleCoolDownTime: 24 hours,
            saleCoolDownFee: 20,
            saleSizeLimitPercent: 2,
            saleSizeLimitPrice: 20
        });
        sellFees[FeeLevels.LEVEL5] = SellFees({
            saleCoolDownTime: 48 hours,
            saleCoolDownFee: 10,
            saleSizeLimitPercent: 1,
            saleSizeLimitPrice: 10
        });
    }
    uint256 public sellFeeLevels = 5;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool private sniperDetection = true;
    bool public tradingOpen = false;
    bool private _cooldownEnabled = true;
    uint256 private launchBlock = 0;
    uint256 private buyLimitEnd;

    uint256 public _maxTxAmount;
    uint256 public numTokensSellToAddToLiquidity;
    address payable public _projectWallet;
    address payable public _marketingWallet;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (string memory NAME, uint256 _supply, uint256 _MAXTXAMOUNT, uint256 ADDTOLIQUIDITYTHRESHOLD,
                 address routerAddress, address tokenOwner, address projectWallet, address marketingWallet) payable {
        _name = NAME;
        _tTotal = _supply * 10 ** _decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        _maxTxAmount = _MAXTXAMOUNT * 10 ** _decimals;
        numTokensSellToAddToLiquidity = ADDTOLIQUIDITYTHRESHOLD * 10 ** _decimals;
        _projectWallet = payable(projectWallet);
        _marketingWallet = payable(marketingWallet);

        _rOwned[tokenOwner] = _rTotal;

        initSellFees();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_projectWallet)] = true;

        _owner = tokenOwner;

        _approve(tokenOwner, address(uniswapV2Router), _rTotal);
        emit Transfer(address(0), tokenOwner, _tTotal);
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return uint8(_decimals);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateRouter(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updateLPPair(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Pair), "This pair is already in use");
        emit UpdatePair(newAddress, address(uniswapV2Pair));
        uniswapV2Pair = address(newAddress);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setNumTokensSellToAddToLiquidity(uint256 swapNumber) public onlyOwner {
        numTokensSellToAddToLiquidity = swapNumber * 10 ** _decimals;
    }

    function setMaxTx(uint256 maxTx) public onlyOwner {
        _maxTxAmount = maxTx  * 10 ** _decimals;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeProjectFees(uint256 tProject, uint256 tMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rProject = tProject.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);

        _rOwned[_projectWallet] = _rOwned[_projectWallet].add(rProject);
        _rOwned[_marketingWallet] = _rOwned[_marketingWallet].add(rMarketing);
    }

    function _getTValues(uint256 tAmount, uint256 liquidityFee, uint256 reflectiveFee, uint256 nonReflectiveFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(reflectiveFee).div(100);
        uint256 tLiquidity = tAmount.mul(liquidityFee).div(100);
        uint256 tOtherFees = tAmount.mul(nonReflectiveFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tAmount.sub(tLiquidity).sub(tOtherFees);
        return (tTransferAmount, tFee, tLiquidity, tOtherFees);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tOtherFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rOtherFees = tOtherFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rOtherFees);
        return (rAmount, rTransferAmount, rFee);
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
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function claimEthToProject() public {
        require(_msgSender() == owner() || _msgSender() == _projectWallet, "Account not authorized to call this function");
            payable(_projectWallet).transfer(address(this).balance);
    }

    function removeAllFee() private {
        previousBuyFees = buyFees;
        previousTransferFees = transferFees;
        previousSellFees[FeeLevels.LEVEL1] = sellFees[FeeLevels.LEVEL1];
        previousSellFees[FeeLevels.LEVEL2] = sellFees[FeeLevels.LEVEL2];
        previousSellFees[FeeLevels.LEVEL3] = sellFees[FeeLevels.LEVEL3];
        previousSellFees[FeeLevels.LEVEL4] = sellFees[FeeLevels.LEVEL4];
        previousSellFees[FeeLevels.LEVEL5] = sellFees[FeeLevels.LEVEL5];

        buyFees = Fees(0, 0, 0, 0, 0);
        transferFees = Fees(0, 0, 0, 0, 0);
        sellFees[FeeLevels.LEVEL1] = zeroFees;
        sellFees[FeeLevels.LEVEL2] = zeroFees;
        sellFees[FeeLevels.LEVEL3] = zeroFees;
        sellFees[FeeLevels.LEVEL4] = zeroFees;
        sellFees[FeeLevels.LEVEL5] = zeroFees;
    }

    function restoreAllFee() private {
        buyFees = previousBuyFees;
        transferFees = previousTransferFees;
        sellFees[FeeLevels.LEVEL1] = previousSellFees[FeeLevels.LEVEL1];
        sellFees[FeeLevels.LEVEL2] = previousSellFees[FeeLevels.LEVEL2];
        sellFees[FeeLevels.LEVEL3] = previousSellFees[FeeLevels.LEVEL3];
        sellFees[FeeLevels.LEVEL4] = previousSellFees[FeeLevels.LEVEL4];
        sellFees[FeeLevels.LEVEL5] = previousSellFees[FeeLevels.LEVEL5];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
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

        uint256 tTransferAmount; uint256 tFee; uint256 tLiquidity; uint256 tOther;
        uint256 rAmount; uint256 rTransferAmount; uint256 rFee;

        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        if(!takeFee){
            removeAllFee();
        }
        if(from != owner() && to != owner()) {

            if(!trader[from].exists) {
                trader[from] = User(0,0,0,true);
            }
            if(!trader[to].exists) {
                trader[to] = User(0,0,0,true);
            }

            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(!_isBlacklisted[to], "Address is blacklisted");
                require(tradingOpen || sniperDetection, "Trading not yet enabled.");
                if(sniperDetection && !tradingOpen){
                    _isBlacklisted[to] = true;
                }
                trader[to].lastBuy = block.timestamp;

                if(_cooldownEnabled) {
                    if(block.timestamp < buyLimitEnd + 6 hours){
                        require(msg.value <= 3 ether, "Purchase too large for initial opening hours");
                    } else {
                        require(trader[to].buyCD < block.timestamp, "Your buy cooldown has not expired.");
                        trader[to].buyCD = block.timestamp + (30 seconds);
                    }
                    trader[to].sellCD = block.timestamp + (30 seconds);
                }

                uint256 nonReflectiveFee = buyFees.burn.add(buyFees.project).add(buyFees.marketing);

                (tTransferAmount, tFee, tLiquidity, tOther) = _getTValues(amount, buyFees.liquidity, buyFees.reflection, nonReflectiveFee);

                // Large buy fee discount
                if(msg.value >= buyerDiscountPrice){
                    tFee = tFee.div(2);
                    tLiquidity =tLiquidity.div(2);
                    tOther = tOther.div(2);
                    tTransferAmount = tTransferAmount.add(tOther).add(tLiquidity).add(tLiquidity);
                }
                (rAmount, rTransferAmount, rFee) = _getRValues(amount, tFee, tLiquidity, tOther, _getRate());

                _takeLiquidity(tLiquidity);
                _burn(amount.mul(buyFees.burn).div(100));
                _takeProjectFees(amount.mul(buyFees.project).div(100), amount.mul(buyFees.marketing).div(100));
                _reflectFee(rFee, tFee);

                // sell
            } else if(from != uniswapV2Pair && from != address(uniswapV2Router) && to == uniswapV2Pair) {
                require(!_isBlacklisted[from], "Address is blacklisted");
                require(tradingOpen, "Trading is not enabled yet");
                require(!inSwapAndLiquify);
                if(_cooldownEnabled) {
                    require(trader[from].sellCD < block.timestamp, "Your sell cooldown has not expired.");
                    require(block.timestamp > buyLimitEnd + 6 hours);
                }
                trader[to].sellCD = block.timestamp + (30 seconds);
                trader[to].buyCD = block.timestamp + (30 seconds);

                uint256 timeBasedFee = _minimumTimeFee;
                if(block.timestamp < trader[from].lastBuy + sellFees[FeeLevels.LEVEL1].saleCoolDownTime) {
                    timeBasedFee = sellFees[FeeLevels.LEVEL1].saleCoolDownFee;
                } else if(block.timestamp < trader[from].lastBuy + sellFees[FeeLevels.LEVEL2].saleCoolDownTime) {
                    timeBasedFee = sellFees[FeeLevels.LEVEL2].saleCoolDownFee;
                } else if(block.timestamp < trader[from].lastBuy + sellFees[FeeLevels.LEVEL3].saleCoolDownTime) {
                    timeBasedFee = sellFees[FeeLevels.LEVEL3].saleCoolDownFee;
                } else if(block.timestamp < trader[from].lastBuy + sellFees[FeeLevels.LEVEL4].saleCoolDownTime) {
                    timeBasedFee = sellFees[FeeLevels.LEVEL4].saleCoolDownFee;
                } else if(block.timestamp < trader[from].lastBuy + sellFees[FeeLevels.LEVEL5].saleCoolDownTime) {
                    timeBasedFee = sellFees[FeeLevels.LEVEL5].saleCoolDownFee;
                }

                uint256 sizeBasedFee = _minimumSizeFee;
                if(amount > amountInPool().mul(sellFees[FeeLevels.LEVEL1].saleSizeLimitPercent).div(100)) {
                    sizeBasedFee = sellFees[FeeLevels.LEVEL1].saleSizeLimitPrice;
                } else if(amount > amountInPool().mul(sellFees[FeeLevels.LEVEL2].saleSizeLimitPercent).div(100)) {
                    sizeBasedFee = sellFees[FeeLevels.LEVEL2].saleSizeLimitPrice;
                } else if(amount > amountInPool().mul(sellFees[FeeLevels.LEVEL3].saleSizeLimitPercent).div(100)) {
                    sizeBasedFee = sellFees[FeeLevels.LEVEL3].saleSizeLimitPrice;
                } else if(amount > amountInPool().mul(sellFees[FeeLevels.LEVEL4].saleSizeLimitPercent).div(100)) {
                    sizeBasedFee = sellFees[FeeLevels.LEVEL4].saleSizeLimitPrice;
                } else if(amount > amountInPool().mul(sellFees[FeeLevels.LEVEL5].saleSizeLimitPercent).div(100)) {
                    sizeBasedFee = sellFees[FeeLevels.LEVEL5].saleSizeLimitPrice;
                }

                uint256 finalSaleFee = sizeBasedFee;
                if (sizeBasedFee < timeBasedFee) {
                    finalSaleFee = timeBasedFee;
                }
                (tTransferAmount, tFee, tLiquidity, tOther) = _getTValues(amount, 0, finalSaleFee.div(2), finalSaleFee.div(2));
                (rAmount, rTransferAmount, rFee) = _getRValues(amount, tFee, tLiquidity, tOther, _getRate());
                _takeProjectFees(amount.mul(finalSaleFee.div(200)), 0);
                _reflectFee(rFee, tFee);

                // transfer
            } else {
                uint256 nonReflectiveFee = transferFees.burn.add(transferFees.project).add(transferFees.marketing);

                (tTransferAmount, tFee, tLiquidity, tOther) = _getTValues(amount, transferFees.liquidity, transferFees.reflection, nonReflectiveFee);

                // Large buy fee discount
                if(msg.value >= buyerDiscountPrice){
                    tFee = tFee.div(2);
                    tLiquidity =tLiquidity.div(2);
                    tOther = tOther.div(2);
                    tTransferAmount = tTransferAmount.add(tOther).add(tLiquidity).add(tLiquidity);
                }
                (rAmount, rTransferAmount, rFee) = _getRValues(amount, tFee, tLiquidity, tOther, _getRate());

                _takeLiquidity(tLiquidity);
                _burn(amount.mul(transferFees.burn).div(100));
                _takeProjectFees(amount.mul(transferFees.project).div(100), amount.mul(transferFees.marketing).div(100));
                _reflectFee(rFee, tFee);
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
            bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
            if (
                overMinTokenBalance &&
                !inSwapAndLiquify &&
                from != uniswapV2Pair
            ) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                //add liquidity
                swapAndLiquify(contractTokenBalance);
            }

        } else {
            (tTransferAmount, tFee, tLiquidity, tOther) = _getTValues(amount, 0, 0, 0);
            (rAmount, rTransferAmount, rFee) = _getRValues(amount, tFee, tLiquidity, tOther, _getRate());
        }

        _transferStandard(from, to, rAmount, tTransferAmount, rTransferAmount);

        if(!takeFee){
            restoreAllFee();
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH ->  swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _transferStandard(address sender, address recipient, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function isCooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function _burn(uint256 amount) public {
        _rOwned[address(0)] = _rOwned[address(0)].add(amount);
        emit Burn(address(0), amount);
    }

    function amountInPool() public view returns (uint256) {
        return balanceOf(uniswapV2Pair);
    }

    function updateBlacklist(address ad, bool isBlacklisted) public onlyOwner {
        _isBlacklisted[ad] = isBlacklisted;
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        buyLimitEnd = block.timestamp + (120 seconds);
        launchBlock = block.number;
        swapAndLiquifyEnabled = true;
    }

    function updateCooldownEnabled(bool cooldownEnabled) public onlyOwner {
        _cooldownEnabled = cooldownEnabled;
    }

    function updateBuyerFees(uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee, uint256 marketingFee) public onlyOwner {
        buyFees = Fees({
            reflection: reflectionFee,
            project: projectFee,
            liquidity: liquidityFee,
            burn: burnFee,
            marketing: marketingFee
        });

    }

    function updateTransferFees(uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee, uint256 marketingFee) public onlyOwner {
        transferFees = Fees({
            reflection: reflectionFee,
            project: projectFee,
            liquidity: liquidityFee,
            burn: burnFee,
            marketing: marketingFee
        });
    }

    function updateSellerFees(FeeLevels level, uint256 upperTimeLimitInHours, uint256 timeLimitFeePercent, uint256 saleSizePercent, uint256 saleSizeFee ) public onlyOwner {
        sellFees[level] = SellFees({
            saleCoolDownTime: upperTimeLimitInHours * 1 hours,
            saleCoolDownFee: timeLimitFeePercent,
            saleSizeLimitPercent: saleSizePercent,
            saleSizeLimitPrice: saleSizeFee
        });
    }

    function updateFallbackFees(uint256 minimumTimeBasedFee, uint256 minimumSizeBasedFee) public onlyOwner {
        _minimumTimeFee = minimumTimeBasedFee;
        _minimumSizeFee = minimumSizeBasedFee;
    }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT

//import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/utils/Context.sol';

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
pragma solidity >=0.6.0;
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is not unlockable yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}