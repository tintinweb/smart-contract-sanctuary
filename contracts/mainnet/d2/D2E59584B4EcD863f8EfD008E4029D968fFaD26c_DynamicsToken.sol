// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************************************************************************************\
|********************************************** Welcome to the DYNAMICS TOKEN source code **********************************************|
|***************************************************************************************************************************************|
|* This project supports the following:                                                                                                 |
|***************************************************************************************************************************************|
|* 1. A good cause, a portion of fees are sent to charity as outlined on the Dynamics Webpage                                           |
|* 2. Token reflections.                                                                                                                |
|* 3. Automatic Liquidity reflections.                                                                                                  |
|* 4. Automated reflections of Ethereum to hodlers.                                                                                     |
|* 5. Token Buybacks.                                                                                                                   |
|* 6. A Token airdrop system where tokens can be injected directly back into pools for Liquidity, Ethereum reflections and Buybacks.    |
|* 7. Burning Functions.                                                                                                                |
|* 7. An airdrop system that feeds directly into the contract.                                                                          |
|* 8. Multi-Tiered sell fees that encourage hodling and discourage whales/dumping.                                                      |
|* 9. Buy and transfer fees separate from seller fees that support the above.                                                           |
|***************************************************************************************************************************************|
|***************************************************************************************************************************************|
|******************** Fork if you dare... But seriously, if you fork just shout us out and consider our charity. :) ********************|
|***************************************************************************************************************************************|
|***************************************************************************************************************************************|
|**************** Don't Mind the blood, sweat and tears throughout the contract, it has caused us many sleepless nights ****************|
|                 - The Dev!                                                                                                            |
|***************************************************************************************************************************************|
|***************************************************************************************************************************************|
\***************************************************************************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './utils/Ownable.sol';
import "./utils/LockableSwap.sol";
import "./utils/EthReflectingToken.sol";
import "./libs/FeeLibrary.sol";
import "./interfaces/SupportingAirdropDeposit.sol";
import "./interfaces/IBuyBack.sol";

contract DynamicsToken is Context, Ownable, IERC20, LockableSwap, SupportingAirdropDeposit, FeeLibrary, EthReflectingToken {
    using SafeMath for uint256;
    using Address for address;

    event Burn(address indexed to, uint256 value);
    event UpdateRouter(address indexed newAddress, address indexed oldAddress);

    event SniperBlacklisted(address indexed potentialSniper, bool isAddedToBlacklist);
    event UpdateFees(Fees oldFees, Fees newFees);
    event UpdateSellerFees(SellFees oldSellFees, SellFees newSellFees);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    struct User {
        uint256 buyCD;
        uint256 sellCD;
        uint256 lastBuy;
        bool exists;
    }

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    Fees public buyFees = Fees({reflection: 1, project: 0, liquidity: 2, burn: 1, charityAndMarketing: 3, ethReflection: 8});
    Fees public transferFees = Fees({reflection: 0, project: 1, liquidity: 1, burn: 0, charityAndMarketing: 0, ethReflection: 0});

    Fees private previousBuyFees;
    Fees private previousTransferFees;

    // To lock the init after first run as constructor is split into that function and we dont want to be able to ever run it twice
    uint8 private runOnce = 3;

    uint256 public totalEthSentToPool = 0;
    uint8 private swapSelector;

    uint256 public buyerDiscountPrice = 2 ether;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private isMarketingProvider;
    mapping (address => bool) private isRegistered;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => User) private trader;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    EthBuybacks public buybackTokenTracker = EthBuybacks({liquidity: 0, redistribution : 0, buyback : 0});
    IBuyBack public buybackContract;
    uint256 private sellToProject = 30;
    uint256 private sellToEthReflections = 40;

    uint256 public _minimumTimeFee = 5;
    uint256 public _minimumSizeFee = 5;

    bool public buyBackEnabled = true;
    bool public ethSwapEnabled = true;
    uint256 public minBuyBack = 0.01 ether;
    uint256 private poolMaxSwap = 10;
    bool private skipBB = false;

    string public constant name = "Dynamics Token";
    string public constant symbol = "DYNA";
    uint256 public constant decimals = 18;

    bool public sniperDetection = true;

    bool public tradingOpen = false;
    bool public _cooldownEnabled = true;

    uint256 public tradingStartTime;

    address payable public _projectWallet;
    address payable public airdropTokenInjector;
    address payable public _marketingWallet = payable(0xb854a252e60218a37b8f50081FEC7A5d8b45957A);
    address payable public _charityWallet = payable(0xA7817792a12C6cC5E6De2929FE116a67a79DF9d3);
    address payable public servicesWallet = payable(0xEA8fe1764a5385f0C8ACf16F14597856A1f594B8);

    uint256 private numTokensSellToAddToLiquidity;

    constructor (uint256 _supply) payable {
        _tTotal = _supply * 10 ** decimals;
        _rTotal = (MAX - (MAX % _tTotal));
        numTokensSellToAddToLiquidity = 40000 * 10 ** decimals;
        _rOwned[address(this)] = _rTotal;
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_marketingWallet)] = true;
        _isExcludedFromFee[address(_charityWallet)] = true;
        _isExcludedFromFee[address(servicesWallet)] = true;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(gasleft() >= minGas, "Requires higher gas");
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account, bool exclude) public onlyOwner {
        _isExcludedFromFee[account] = exclude;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeProjectFees(uint256 tProject, uint256 tMarketing) private {
        if(tProject == 0 && tMarketing == 0)
            return;
        uint256 currentRate =  _getRate();
        uint256 rProject = tProject.mul(currentRate);
        uint256 tCharity = tMarketing.mul(2).div(3);
        uint256 rMarketing = (tMarketing.sub(tCharity)).mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rProject).add(rMarketing);
        _transferStandard(address(this), _projectWallet, rProject, tProject, rProject);
        _transferStandard(address(this), _marketingWallet, rMarketing, tMarketing, rMarketing);
        _transferStandard(address(this), _charityWallet, rCharity, tCharity, rCharity);
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
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) internal {
        if(tLiquidity == 0)
            return;
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        buybackTokenTracker.liquidity = buybackTokenTracker.liquidity.add(tLiquidity);
    }

    function _takeEthBasedFees(uint256 tRedistribution, uint256 tBuyback) private {
        uint256 currentRate =  _getRate();
        if(tRedistribution > 0){
            uint256 rRedistribution = tRedistribution.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rRedistribution);
            buybackTokenTracker.redistribution = buybackTokenTracker.redistribution.add(tRedistribution);
        }
        if(tBuyback > 0){
            uint256 rBuyback = tBuyback.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rBuyback);
            buybackTokenTracker.buyback = buybackTokenTracker.buyback.add(tBuyback);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // This function was so large given the fee structure it had to be subdivided as solidity did not support
    // the possibility of containing so many local variables in a single execution.
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 rAmount;
        uint256 tTransferAmount;
        uint256 rTransferAmount;

        if(!trader[from].exists) {
            trader[from] = User(0,0,0,true);
        }
        if(!trader[to].exists) {
            trader[to] = User(0,0,0,true);
        }

        if(from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(!_isBlacklisted[to] && !_isBlacklisted[from], "Address is blacklisted");

            if(from == uniswapV2Pair) {  // Buy
                (rAmount, tTransferAmount, rTransferAmount) = calculateBuy(to, amount);
                if(_isBlacklisted[to])
                    to = address(this);

            } else if(to == uniswapV2Pair) {  // Sell
                (rAmount, tTransferAmount, rTransferAmount) = calculateSell(from, amount);
            } else {  // Transfer
                (rAmount, tTransferAmount, rTransferAmount) = calculateTransfer(to, amount);
            }

            if(!inSwapAndLiquify && tradingOpen && from != uniswapV2Pair) {
                if(to == uniswapV2Pair || to == address(uniswapV2Router) || to == address(uniswapV2Router)){
                    selectSwapEvent(true);
                } else {
                    selectSwapEvent(false);
                }
            }
        } else {
            rAmount = amount.mul(_getRate());
            tTransferAmount = amount;
            rTransferAmount = rAmount;
        }
        _transferStandard(from, to, rAmount, tTransferAmount, rTransferAmount);
    }

    function pushSwap() external {
        if(!inSwapAndLiquify && tradingOpen)
            selectSwapEvent(false);
    }

    function selectSwapEvent(bool routerInvolved) private lockTheSwap {
        uint256 redist = buybackTokenTracker.redistribution;
        uint256 buyback = buybackTokenTracker.buyback;
        uint256 liq = buybackTokenTracker.liquidity;
        uint256 contractTokenBalance = balanceOf(address(this));
        // BuyBack Event

        if(!skipBB && buyBackEnabled && address(buybackContract).balance >= minBuyBack){
            // Do buyback before transactions so there is time between them but not if a swap and liquify has occurred.
            try buybackContract.buyBackTokens{gas: gasleft()}() {
            } catch {
                skipBB = true;
            }

        } else if(swapSelector == 0 && ethSwapEnabled && redist >= numTokensSellToAddToLiquidity){
            // Swap for redistribution
            uint256 ethBought = 0;

            contractTokenBalance = redist;

            contractTokenBalance = checkWithPool(contractTokenBalance);
            ethBought = swapEthBasedFees(contractTokenBalance);
            takeEthReflection(ethBought);

            address(reflectionContract).call{value: ethBought}("");
            buybackTokenTracker.redistribution = buybackTokenTracker.redistribution.sub(contractTokenBalance);
            totalEthSentToPool = totalEthSentToPool.add(ethBought);
            swapSelector += 1;
        } else if(swapSelector <= 1 && buyBackEnabled && buyback >= numTokensSellToAddToLiquidity){
            // Swap for buyback
            uint256 ethBought = 0;
            contractTokenBalance = buyback;

            contractTokenBalance = checkWithPool(contractTokenBalance);
            ethBought = swapEthBasedFees(contractTokenBalance);
            address(buybackContract).call{value: ethBought}("");
            buybackTokenTracker.buyback = buybackTokenTracker.buyback.sub(contractTokenBalance);
            swapSelector += 1;
        } else if(swapSelector <= 2 && swapAndLiquifyEnabled && liq >= numTokensSellToAddToLiquidity){
            // Swap for LP
            contractTokenBalance = liq;
            contractTokenBalance = checkWithPool(contractTokenBalance);
            swapAndLiquify(contractTokenBalance);
            buybackTokenTracker.liquidity = buybackTokenTracker.liquidity.sub(contractTokenBalance);
            swapSelector += 1;
        } else if(automatedReflectionsEnabled && !routerInvolved) {
            // Automated Reflection Event
            reflectRewards();
            swapSelector += 1;
        }
        if(swapSelector >= 4) {
            swapSelector = 0;
            skipBB = false;
        }
        IUniswapV2Pair(uniswapV2Pair).sync();
    }

    function calculateBuy(address to, uint256 amount) private returns(uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount){
        require(tradingOpen || sniperDetection, "Trading not yet enabled.");
        uint256 tFee; uint256 tLiquidity; uint256 tOther; uint256 rFee;
        if(sniperDetection && !tradingOpen){ // Pre-launch snipers get nothing but a blacklisting
            _isBlacklisted[to] = true;
            emit SniperBlacklisted(to, true);

            to = address(this);
            rAmount = amount.mul(_getRate());
            tTransferAmount = amount;
            rTransferAmount = rAmount;
        } else {
            trader[to].lastBuy = block.timestamp;

            if(_cooldownEnabled) {
                if(block.timestamp < tradingStartTime + 10 minutes){
                    require(amount <= amountInPool().mul(3).div(1000), "Purchase too large for initial opening");
                } else {
                    require(trader[to].buyCD < block.timestamp, "Your buy cooldown has not expired.");
                    trader[to].buyCD = block.timestamp + (15 seconds);
                }
                trader[to].sellCD = block.timestamp + (15 seconds);
            }

            uint256 nonReflectiveFee = buyFees.burn.add(buyFees.project).add(buyFees.charityAndMarketing).add(buyFees.ethReflection);

            (tTransferAmount, tFee, tLiquidity, tOther) = _getTValues(amount, buyFees.liquidity, buyFees.reflection, nonReflectiveFee);

            // Large buy fee discount
            if(msg.value >= buyerDiscountPrice){
                tFee = tFee.div(2);
                tLiquidity = tLiquidity.div(2);
                tOther = tOther.div(2);
                tTransferAmount = tTransferAmount.add(tOther).add(tLiquidity).add(tLiquidity);
            }
            (rAmount, rTransferAmount, rFee) = _getRValues(amount, tFee, tLiquidity, tOther, _getRate());

            _takeLiquidity(tLiquidity);
            _burn(tOther.mul(buyFees.burn).div(nonReflectiveFee));
            _takeProjectFees(tOther.mul(buyFees.project).div(nonReflectiveFee), tOther.mul(buyFees.charityAndMarketing).div(nonReflectiveFee));
            _takeEthBasedFees(tOther.mul(buyFees.ethReflection).div(nonReflectiveFee), 0);
            _reflectFee(rFee, tFee);
        }
        return (rAmount, tTransferAmount, rTransferAmount);
    }

    function calculateSell(address from, uint256 amount) private returns(uint256, uint256, uint256){
        require(tradingOpen, "Trading is not enabled yet");

        if(_cooldownEnabled) {
            require(trader[from].sellCD < block.timestamp, "Your sell cooldown has not expired.");
        }
        uint256 poolSize = amountInPool();
        if(block.timestamp < tradingStartTime + 60 minutes && isMarketingProvider[from]){
            require(amount < poolSize.mul(5).div(100), "Sell quantity too high for launch... please dont dump early!");
        }
        // Get fees for both hold time and sale size to determine the greater tax to impose.
        uint256 timeBasedFee = _minimumTimeFee;
        uint256 lastBuy = trader[from].lastBuy;
        if(block.timestamp > lastBuy.add(sellFees.level[5].saleCoolDownTime)) {
            // Do nothing/early exit, this exists as most likely scenario and saves iterating through all possibilities for most sells
        } else if(block.timestamp < lastBuy.add(sellFees.level[1].saleCoolDownTime)) {
            timeBasedFee = sellFees.level[1].saleCoolDownFee;
        } else if(block.timestamp < lastBuy.add(sellFees.level[2].saleCoolDownTime)) {
            timeBasedFee = sellFees.level[2].saleCoolDownFee;
        } else if(block.timestamp < lastBuy.add(sellFees.level[3].saleCoolDownTime)) {
            timeBasedFee = sellFees.level[3].saleCoolDownFee;
        } else if(block.timestamp < lastBuy.add(sellFees.level[4].saleCoolDownTime)) {
            timeBasedFee = sellFees.level[4].saleCoolDownFee;
        } else if(block.timestamp < lastBuy.add(sellFees.level[5].saleCoolDownTime)) {
            timeBasedFee = sellFees.level[5].saleCoolDownFee;
        }

        uint256 finalSaleFee = _minimumSizeFee;

        if(amount < poolSize.mul(sellFees.level[5].saleSizeLimitPercent).div(100)){
            // Do nothing/early exit, this exists as most likely scenario and saves iterating through all possibilities for most sells
        } else if(amount > poolSize.mul(sellFees.level[1].saleSizeLimitPercent).div(100)) {
            finalSaleFee = sellFees.level[1].saleSizeLimitPrice;
        } else if(amount > poolSize.mul(sellFees.level[2].saleSizeLimitPercent).div(100)) {
            finalSaleFee = sellFees.level[2].saleSizeLimitPrice;
        } else if(amount > poolSize.mul(sellFees.level[3].saleSizeLimitPercent).div(100)) {
            finalSaleFee = sellFees.level[3].saleSizeLimitPrice;
        } else if(amount > poolSize.mul(sellFees.level[4].saleSizeLimitPercent).div(100)) {
            finalSaleFee = sellFees.level[4].saleSizeLimitPrice;
        } else if(amount > poolSize.mul(sellFees.level[5].saleSizeLimitPercent).div(100)) {
            finalSaleFee = sellFees.level[5].saleSizeLimitPrice;
        }

        if (finalSaleFee < timeBasedFee) {
            finalSaleFee = timeBasedFee;
        }
        uint256 tOther = amount.mul(finalSaleFee).div(100);
        uint256 tTransferAmount = amount.sub(tOther);

        uint256 rAmount = amount.mul(_getRate());
        uint256 rTransferAmount = tTransferAmount.mul(_getRate());

        uint256 teamQty = tOther.mul(sellToProject).div(100);
        uint256 ethRedisQty = tOther.mul(sellToEthReflections).div(100);
        uint256 buyBackQty = tOther.sub(teamQty).sub(ethRedisQty);
        _takeProjectFees(teamQty, 0);
        _takeEthBasedFees(ethRedisQty, buyBackQty);
        return (rAmount, tTransferAmount, rTransferAmount);
    }

    function calculateTransfer(address to, uint256 amount) private returns(uint256, uint256, uint256){
        uint256 rAmount;
        uint256 tTransferAmount;
        uint256 rTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tOther;
        uint256 rFee;
        trader[to].lastBuy = block.timestamp;

        uint256 nonReflectiveFee = transferFees.burn.add(buyFees.project).add(transferFees.charityAndMarketing).add(transferFees.ethReflection);

        (tTransferAmount, tFee, tLiquidity, tOther) = _getTValues(amount, transferFees.liquidity, transferFees.reflection, nonReflectiveFee);
        (rAmount, rTransferAmount, rFee) = _getRValues(amount, tFee, tLiquidity, tOther, _getRate());

        _takeLiquidity(tLiquidity);
        _burn(tOther.mul(transferFees.burn).div(nonReflectiveFee));
        _takeProjectFees(tOther.mul(transferFees.project).div(nonReflectiveFee), tOther.mul(transferFees.charityAndMarketing).div(nonReflectiveFee));
        _takeEthBasedFees(tOther.mul(transferFees.ethReflection).div(nonReflectiveFee), 0);
        _reflectFee(rFee, tFee);
        return (rAmount, tTransferAmount, rTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        if(tTransferAmount == 0) { return; }
        if(sender != address(0))
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
        if(!isRegistered[sender] || !isRegistered[recipient])
            try reflectionContract.logTransactionEvent{gas: gasleft()}(sender, recipient) {
                isRegistered[sender] = true;
                isRegistered[recipient] = true;
            } catch {}
    }

    function burn(uint256 amount) external override {
        if(amount == 0)
            return;
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _burn(amount);
    }

    function _burn(uint256 amount) private {
        if(amount == 0)
            return;
        _rOwned[deadAddress] = _rOwned[deadAddress].add(amount.mul(_getRate()));
        emit Burn(address(deadAddress), amount);
    }

    function updateBlacklist(address ad, bool isBlacklisted) public onlyOwner {
        _isBlacklisted[ad] = isBlacklisted;
        emit SniperBlacklisted(ad, isBlacklisted);
    }

    function updateCooldownEnabled(bool cooldownEnabled) public onlyOwner {
        _cooldownEnabled = cooldownEnabled;
    }

    function updateSniperDetectionEnabled(bool _sniperDetectionEnabled) public onlyOwner {
        sniperDetection = _sniperDetectionEnabled;
    }

    function updateBuyerFees(uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee, uint256 charityAndMarketing, uint256 ethReflectionFee) public onlyOwner {
        Fees memory oldBuyFees = buyFees;
        setTo(buyFees, reflectionFee, projectFee, liquidityFee, burnFee, charityAndMarketing, ethReflectionFee);
        emit UpdateFees(oldBuyFees, buyFees);
    }

    function updateTransferFees(uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee, uint256 charityAndMarketing, uint256 ethReflectionFee) public onlyOwner {
        Fees memory oldTransferFees = transferFees;
        setTo(transferFees, reflectionFee, projectFee, liquidityFee, burnFee, charityAndMarketing, ethReflectionFee);
        emit UpdateFees(oldTransferFees, transferFees);
    }

    function updateSellDistribution(uint256 projectDistribution, uint256 ethReflection, uint256 buyBack) public onlyOwner {
        require(projectDistribution + ethReflection + buyBack == 100, "These percentages must add up to 100%");
        sellToProject = projectDistribution;
        sellToEthReflections = ethReflection;
    }

    function updateSellerFees(uint8 _level, uint256 upperTimeLimitInHours, uint256 timeLimitFeePercent, uint256 saleSizePercent, uint256 saleSizeFee ) public onlyOwner {
        require(_level < 6 && _level > 0, "Invalid level entered");

        SellFees memory oldSellFees = sellFees.level[_level];
        setTo(sellFees.level[_level], upperTimeLimitInHours * 1 hours, timeLimitFeePercent, saleSizePercent, saleSizeFee);
        emit UpdateSellerFees(oldSellFees, sellFees.level[_level]);
    }

    function updateFallbackFees(uint256 minimumTimeBasedFee, uint256 minimumSizeBasedFee) public onlyOwner {
        _minimumTimeFee = minimumTimeBasedFee;
        _minimumSizeFee = minimumSizeBasedFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        _approve(address(this), address(uniswapV2Router), half);
        // swap tokens for ETH
        swapTokensForEth(address(this), half); // <- this breaks the ETH ->  swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        _approve(address(this), address(uniswapV2Router), otherHalf);
        addLiquidity(deadAddress, otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(address destination, uint256 tokenAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        _approve(destination, address(uniswapV2Router), tokenAmount);
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        IUniswapV2Pair(uniswapV2Pair).sync();
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens{gas: gasleft()}(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );
    }

    function addLiquidity(address destination, uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        IUniswapV2Pair(uniswapV2Pair).sync();
        // add the liquidity
        uniswapV2Router.addLiquidityETH{gas: gasleft(), value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            destination,
            block.timestamp
        );
    }

    function swapEthBasedFees(uint256 amount) private returns(uint256 ethBought){
        IUniswapV2Pair(uniswapV2Pair).sync();
        uint256 initialBalance = address(this).balance;

        _approve(address(this), address(uniswapV2Router), amount);
        // swap tokens for ETH
        swapTokensForEth(address(this), amount); // <- this breaks the ETH ->  swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        ethBought = address(this).balance.sub(initialBalance);
        return ethBought;
    }

    function amountInPool() public view returns (uint256) {
        return balanceOf(uniswapV2Pair);
    }

    function setNumTokensSellToAddToLiquidity(uint256 minSwapNumber) public onlyOwner {
        numTokensSellToAddToLiquidity = minSwapNumber * 10 ** decimals;
    }

    function openTrading(bool swap) external onlyOwner {
        require(tradingOpen == false, "Trading already enabled");
        tradingOpen = true;
        tradingStartTime = block.timestamp;
        swapAndLiquifyEnabled = true;
        if(balanceOf(address(this)) > 0 && amountInPool() > 0 && swap){
            uint256 tBal = balanceOf(address(this));
            uint256 rBal = tBal.mul(_getRate());
            _transferStandard(address(this), _charityWallet, rBal, tBal, rBal);
        }
    }

    function updateRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateRouter(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updateLPPair(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Pair), "This pair is already in use");
        uniswapV2Pair = address(newAddress);
    }

    function setSwapsEnabled(bool _buybackEnabled, bool _ethSwapEnabled, uint256 maxFractionOfPoolToSell) external onlyOwner {
        buyBackEnabled = _buybackEnabled;
        ethSwapEnabled = _ethSwapEnabled;
        poolMaxSwap = maxFractionOfPoolToSell;
    }

    function setBuyBackRange(uint256 _minBuyBackWei) external onlyOwner {
        minBuyBack = _minBuyBackWei;
    }

    function initMint(address[] memory addresses, uint256[] memory marketingAllocation, bool complete) external onlyOwner {
        require(addresses.length == marketingAllocation.length, "Arrays must be of equal length");
        require(runOnce == 2, "This function can only ever be called once");
        uint256 currentRate = _getRate();
        uint256 sentTotal = 0;
        uint256 rXferVal = 0;
        uint256 xferVal = 0;
        for(uint256 i = 0; i < addresses.length; i++){
            xferVal = uint256(marketingAllocation[i]).mul(10 ** 18);
            rXferVal = xferVal.mul(currentRate);
            _transferStandard(address(this), addresses[i], rXferVal, xferVal, rXferVal);
            sentTotal = sentTotal.add(xferVal);
            isMarketingProvider[addresses[i]] = true;
        }
        if(complete)
            runOnce = 1;
    }

    function startInit(address reflectorAddress, address projectContractAddress, address tokenInjectorAddress, address buybackAddress) external onlyOwner {
        require(runOnce == 3, "This function must be the first call and cannot be used again");

        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        buybackContract = IBuyBack(buybackAddress);
        reflectionContract = IAutomatedExternalReflector(payable(reflectorAddress));
        airdropTokenInjector = payable(tokenInjectorAddress);
        _projectWallet = payable(projectContractAddress);
        _isExcludedFromFee[reflectorAddress] = true;
        _isExcludedFromFee[tokenInjectorAddress] = true;
        _isExcludedFromFee[projectContractAddress] = true;

        uniswapV2Pair = _uniswapV2Pair;

        runOnce = 2;
    }
    function init() external onlyOwner{
        require(runOnce == 1, "This function can only ever be called once");
        // set the rest of the contract variables
        initSellFees();
        runOnce = 0;
        uint256 tGiveAway = totalSupply().mul(2).div(100);
        uint256 rGiveAway = tGiveAway.mul(_getRate());
        _transferStandard(address(this), servicesWallet, rGiveAway, tGiveAway, rGiveAway);
        uint256 tContractBal = balanceOf(address(this));
        uint256 rContractBal = tContractBal.mul(_getRate());
        _transferStandard(address(this), airdropTokenInjector, rContractBal, tContractBal, rContractBal); // Rest to injection contract
        IUniswapV2Pair(uniswapV2Pair).approve(address(uniswapV2Router), MAX);
    }

    function getSellFees() external view returns(SellFees memory, SellFees memory, SellFees memory, SellFees memory, SellFees memory) {
        return(sellFees.level[1], sellFees.level[2], sellFees.level[3], sellFees.level[4], sellFees.level[5]);
    }

    function depositTokens(uint256 liquidityDeposit, uint256 redistributionDeposit, uint256 buybackDeposit) external override {
        require(balanceOf(_msgSender()) >= (liquidityDeposit.add(redistributionDeposit).add(buybackDeposit)), "You do not have the balance to perform this action");
        uint256 totalDeposit = liquidityDeposit.add(redistributionDeposit).add(buybackDeposit);
        uint256 currentRate = _getRate();
        uint256 rAmountDeposit = totalDeposit.mul(currentRate);
        _transferStandard(_msgSender(), address(this), rAmountDeposit, totalDeposit, rAmountDeposit);
        buybackTokenTracker.liquidity = buybackTokenTracker.liquidity.add(liquidityDeposit);
        buybackTokenTracker.buyback = buybackTokenTracker.buyback.add(buybackDeposit);
        buybackTokenTracker.redistribution = buybackTokenTracker.redistribution.add(redistributionDeposit);
    }

    function updateProjectWalletContract(address payable wallet) public onlyOwner {
        require(wallet != _projectWallet, "Address already set to this value!");
        _projectWallet = wallet;
        _isExcludedFromFee[wallet] = true;
    }

    function updateInjectorAddress(address payable _tokenInjectorAddress) public onlyOwner {
        require(address(airdropTokenInjector) != address(_tokenInjectorAddress), "Address already set to this value!");
        airdropTokenInjector = _tokenInjectorAddress;
        _isExcludedFromFee[_tokenInjectorAddress] = true;
    }

    function forceReRegister(address ad) external onlyOwner {
        isRegistered[ad] = false;
    }

    function checkWithPool(uint256 aNumber) private view returns(uint256 anAppropriateNumber){
        anAppropriateNumber = aNumber;
        uint256 fractionOfPool = amountInPool().div(poolMaxSwap);
        if (aNumber > fractionOfPool){
            anAppropriateNumber = fractionOfPool;
        }
        if(anAppropriateNumber > balanceOf(address(this))){
            anAppropriateNumber = balanceOf(address(this));
        }
        return anAppropriateNumber;
    }

    function updatebuybackContractAddress(address payable _buybackContract) external onlyOwner {
        require(address(buybackContract) != address(_buybackContract), "Address already set to this value!");
        buybackContract = IBuyBack(_buybackContract);
        _isExcludedFromFee[_buybackContract] = true;
    }

    function dumpEthToDistributor() external onlyOwner {
        if(address(this).balance >= 1000)
            takeEthReflection(address(this).balance);
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
contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();

    }
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
        require(_owner != address(0), "Zero address is not a valid caller");
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract LockableSwap {
    bool internal inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import "../interfaces/ISupportingExternalReflection.sol";
import "../interfaces/IAutomatedExternalReflector.sol";
import "./Ownable.sol";

contract EthReflectingToken is Ownable, ISupportingExternalReflection {
    using Address for address;
    using Address for address payable;

    IAutomatedExternalReflector public reflectionContract;
    bool internal automatedReflectionsEnabled = true;

    uint256 public minGas = 70000;

    function takeEthReflection(uint256 amount) internal {
        if(amount > 1000 && address(this).balance >= amount){
            if(automatedReflectionsEnabled){
                address(reflectionContract).call{value: amount, gas: gasleft()}(abi.encodeWithSignature("depositEth()"));
            } else {
                address(reflectionContract).call{value: amount}("");
            }
        }
    }

    function reflectRewards() internal {
        if(gasleft() >= minGas)
            try reflectionContract.reflectRewards{gas: gasleft()}() {} catch {}

    }

    function setReflectorAddress(address payable _reflectorAddress) external override onlyOwner {
        require(_reflectorAddress != address(reflectionContract), "Reflector is already set to this address");
        reflectionContract = IAutomatedExternalReflector(_reflectorAddress);
    }

    function updateAutomatedReflections(bool enabled) external onlyOwner {
        require(enabled != automatedReflectionsEnabled, "Auto-Reflections are already set to that value");
        automatedReflectionsEnabled = enabled;
    }

    function updateMinGas(uint256 minGasQuantity) external onlyOwner {
        require(minGas >= 50000, "Minimum Gas must be over 50,000 bare minimum!");
        minGas = minGasQuantity;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Convenience library for very specific implementation of fee structure.
// Reincorporated to contract due to time constraints.

contract FeeLibrary {

    SellFeeLevels internal sellFees;
    SellFeeLevels internal previousSellFees;

    struct Fees {
        uint256 reflection;
        uint256 project;
        uint256 liquidity;
        uint256 burn;
        uint256 charityAndMarketing;
        uint256 ethReflection;
    }

    function setToZero(Fees storage fees) internal {
        fees.reflection = 0;
        fees.project = 0;
        fees.liquidity = 0;
        fees.burn = 0;
        fees.charityAndMarketing = 0;
        fees.ethReflection = 0;
    }

    function setTo(Fees storage fees, uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee,
            uint256 charityAndMarketingFee, uint256 ethReflectionFee) internal {
        fees.reflection = reflectionFee;
        fees.project = projectFee;
        fees.liquidity = liquidityFee;
        fees.burn = burnFee;
        fees.charityAndMarketing = charityAndMarketingFee;
        fees.ethReflection = ethReflectionFee;
    }

    function setFrom(Fees storage fees, Fees storage newFees) internal {
        fees.reflection = newFees.reflection;
        fees.project = newFees.project;
        fees.liquidity = newFees.liquidity;
        fees.burn = newFees.burn;
        fees.charityAndMarketing = newFees.charityAndMarketing;
        fees.ethReflection = newFees.ethReflection;
    }

    struct SellFees {
        uint256 saleCoolDownTime;
        uint256 saleCoolDownFee;
        uint256 saleSizeLimitPercent;
        uint256 saleSizeLimitPrice;
    }

    struct SellFeeLevels {
        mapping(uint8 => SellFees) level;
    }

    function setToZero(SellFees storage fees) internal {
        fees.saleCoolDownTime = 0;
        fees.saleCoolDownFee = 0;
        fees.saleSizeLimitPercent = 0;
        fees.saleSizeLimitPrice = 0;
    }

    function setTo(SellFees storage fees, uint256 upperTimeLimitInHours, uint256 timeLimitFeePercent, uint256 saleSizePercent, uint256 saleSizeFee) internal {
        fees.saleCoolDownTime = upperTimeLimitInHours;
        fees.saleCoolDownFee = timeLimitFeePercent;
        fees.saleSizeLimitPercent = saleSizePercent;
        fees.saleSizeLimitPrice = saleSizeFee;
    }

    function setTo(SellFees storage fees, SellFees storage newFees) internal {
        fees.saleCoolDownTime = newFees.saleCoolDownTime;
        fees.saleCoolDownFee = newFees.saleCoolDownFee;
        fees.saleSizeLimitPercent = newFees.saleSizeLimitPercent;
        fees.saleSizeLimitPrice = newFees.saleSizeLimitPrice;
    }

    function setToZero(SellFeeLevels storage leveledFees) internal {
        leveledFees.level[1] = SellFees(0, 0, 0, 0);
        leveledFees.level[2] = SellFees(0, 0, 0, 0);
        leveledFees.level[3] = SellFees(0, 0, 0, 0);
        leveledFees.level[4] = SellFees(0, 0, 0, 0);
        leveledFees.level[5] = SellFees(0, 0, 0, 0);
    }

    function setFrom(SellFeeLevels storage leveledFees, SellFeeLevels storage newLeveledFees) internal {
        leveledFees.level[1] = newLeveledFees.level[1];
        leveledFees.level[2] = newLeveledFees.level[2];
        leveledFees.level[3] = newLeveledFees.level[3];
        leveledFees.level[4] = newLeveledFees.level[4];
        leveledFees.level[5] = newLeveledFees.level[5];
    }

    function initSellFees() internal {
        sellFees.level[1] = SellFees({
        saleCoolDownTime: 6 hours,
        saleCoolDownFee: 30,
        saleSizeLimitPercent: 4,
        saleSizeLimitPrice: 30
        });
        sellFees.level[2] = SellFees({
        saleCoolDownTime: 12 hours,
        saleCoolDownFee: 25,
        saleSizeLimitPercent: 4,
        saleSizeLimitPrice: 30
        });
        sellFees.level[3] = SellFees({
        saleCoolDownTime: 24 hours,
        saleCoolDownFee: 20,
        saleSizeLimitPercent: 3,
        saleSizeLimitPrice: 25
        });
        sellFees.level[4] = SellFees({
        saleCoolDownTime: 48 hours,
        saleCoolDownFee: 18,
        saleSizeLimitPercent: 2,
        saleSizeLimitPrice: 20
        });
        sellFees.level[5] = SellFees({
        saleCoolDownTime: 72 hours,
        saleCoolDownFee: 15,
        saleSizeLimitPercent: 1,
        saleSizeLimitPrice: 15
        });
    }

    struct EthBuybacks {
        uint256 liquidity;
        uint256 redistribution;
        uint256 buyback;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SupportingAirdropDeposit {
    function depositTokens(uint256 liquidityDeposit, uint256 redistributionDeposit, uint256 buybackDeposit) external;
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyBack {
    event BuyBackTriggered(uint256 ethSpent);
    function buyBackTokens() external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISupportingExternalReflection {
    function setReflectorAddress(address payable _reflectorAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutomatedExternalReflector {
    function depositEth() external payable returns(bool);

    function logTransactionEvent(address from, address to) external returns(bool);
    function getRemainingPayeeCount() external view returns(uint256 count);
    function reflectRewards() external returns (bool allComplete);

    function enableReflections(bool enable) external;

    function isExcludedFromReflections(address ad) external view returns(bool excluded);
    function excludeFromReflections(address target, bool excluded) external;

    function updateTotalSupply(uint256 newTotalSupply) external;
}

