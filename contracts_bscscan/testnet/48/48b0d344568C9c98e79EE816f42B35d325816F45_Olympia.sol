/*
Olympia

Total Supply:
    100,000,000,000 $OLP

Taxes:
    Buy Tax: 12.0%
        2.0% Auto Liquidity
        3.0% BNB Rewards
        3.0% Marketing
        2.0% Team
        2.0% Provider

    Sell Tax: 14.0%
        2.0% Auto Liquidity
        3.0% BNB Rewards
        5.0% Marketing
        2.0% Team
        2.0% Provider

Features:
    Manual Blacklist Function
    
 *
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
//import "./interfaces/IReflectionDistributor.sol";
import "./ReflectionDistributor.sol";
import "./libraries/SafeMath.sol";

contract Olympia is ERC20, Ownable {
    using SafeMath for uint256;

    struct Fees {
        uint256 liquidityFeesPerTenThousand;
        uint256 teamFeesPerTenThousand;
        uint256 providerFeesPerTenThousand;
        uint256 marketingFeesPerTenThousand;
        uint256 reflectionFeesPerTenThousand;
    }
    
    address private _router;
    address private _pair;

    mapping (address => bool) private _isAutomatedMarketMakerPairs;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isBlacklisted;
    
    bool private _isBuying;
    Fees private _buyFees;
    Fees private _sellFees;

    //uint256 public _swapThreshold = 5_000_000 * 10 ** decimals(); // 50M $OLP ( 0.05% )
    uint256 public _swapThreshold = 0 * 10 ** decimals();
    uint256 public _gasForProcessing = 300_000; // 300K

    address private _deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private _teamWallet;
    address private _providerWallet;
    address private _marketingWallet;
    address private _reflectionDistributor;

    bool private _inSwap;
    modifier swapping()
    {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event ReflectionDistributorUpdated(address indexed previousAddress, address indexed newAddress);
    event UpdateUniswapV2Router(address indexed previousAddress, address indexed newAddress);
    event UpdateMarketingWallet(address indexed previousWallet, address indexed newWallet);
    event UpdateTeamWallet(address indexed previousWallet, address indexed newWallet);
    event UpdateProviderWallet(address indexed previousWallet, address indexed newWallet);
    event LiquidityBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event TeamBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event ProviderBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event MarketingBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event ReflectionBuyFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event BuyFeesUpdated(
        uint256 previousLiquidityFeesPerTenThousand, uint256 newLiquidityFeesPerTenThousand,
        uint256 previousTeamFeesPerTenThousand, uint256 newTeamFeesPerTenThousand,
        uint256 previousProviderFeesPerTenThousand, uint256 newProviderFeesPerTenThousand,
        uint256 previousMarketingFeesPerTenThousand, uint256 newMarketingFeesPerTenThousand,
        uint256 previousReflectionFeesPerTenThousand, uint256 newReflectionFeesPerTenThousand);
    event LiquiditySellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event TeamSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event ProviderSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event MarketingSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event ReflectionSellFeesUpdated(uint256 previousFeesPerTenThousand, uint256 newFeesPerTenThousand);
    event SellFeesUpdated(
        uint256 previousLiquidityFeesPerTenThousand, uint256 newLiquidityFeesPerTenThousand,
        uint256 previousTeamFeesPerTenThousand, uint256 newTeamFeesPerTenThousand,
        uint256 previousProviderFeesPerTenThousand, uint256 newProviderFeesPerTenThousand,
        uint256 previousMarketingFeesPerTenThousand, uint256 newMarketingFeesPerTenThousand,
        uint256 previousReflectionFeesPerTenThousand, uint256 newReflectionFeesPerTenThousand);
    event FeesSentToWallet(address indexed wallet, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event ReflectionDistributed();
    event ReflectionDistributed2(address indexed sender, address indexed recipient);

    constructor(
        address newRouter,
        address newTeamWallet,
        address newProviderWallet,
        address newMarketingWallet,
        address distributor) ERC20("Olympia", "OLP") {
        _router = newRouter;
    	_teamWallet = newTeamWallet;
    	_providerWallet = newProviderWallet;
    	_marketingWallet = newMarketingWallet;
    	_reflectionDistributor = distributor;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 routerObject = IUniswapV2Router02(_router);
        _pair = IUniswapV2Factory(routerObject.factory()).createPair(address(this), routerObject.WETH());
        _setAutomatedMarketMakerPair(_pair, true);

        // Buy fees
        _buyFees.liquidityFeesPerTenThousand = 200; // 2.00%
        _buyFees.teamFeesPerTenThousand = 200; // 2.00%
        _buyFees.providerFeesPerTenThousand = 200; // 2.00%
        _buyFees.marketingFeesPerTenThousand = 300; // 3.00%
        _buyFees.reflectionFeesPerTenThousand = 300; // 3.00%

        // Sell fees
        _sellFees.liquidityFeesPerTenThousand = 200; // 2.00%
        _sellFees.teamFeesPerTenThousand = 200; // 2.00%
        _sellFees.providerFeesPerTenThousand = 200; // 2.00%
        _sellFees.marketingFeesPerTenThousand = 500; // 5.00%
        _sellFees.reflectionFeesPerTenThousand = 300; // 3.00%

        _mint(owner(), 100_000_000_000 * 10 ** decimals()); // 100B $OLP
    }

    receive() external payable {
  	}
    
    function router() external view returns (address) {
        return _router;
    }

    function pair() external view returns (address) {
        return _pair;
    }

    function reflectionDistributor() external view returns (address) {
        return _reflectionDistributor;
    }

    function isAutomatedMarketMakerPair(address account) external view returns (bool) {
        return _isAutomatedMarketMakerPairs[account];
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function buyFees() public view returns (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 providerFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 reflectionFeesPerTenThousand,
        uint256 totalFeePerTenThousand) {
        return (
            _buyFees.liquidityFeesPerTenThousand,
            _buyFees.teamFeesPerTenThousand,
            _buyFees.providerFeesPerTenThousand,
            _buyFees.marketingFeesPerTenThousand,
            _buyFees.reflectionFeesPerTenThousand,
            totalBuyFees());
    }

    function totalBuyFees() public view returns (uint256) {
        return (
            _buyFees.liquidityFeesPerTenThousand
                .add(_buyFees.teamFeesPerTenThousand)
                .add(_buyFees.providerFeesPerTenThousand)
                .add(_buyFees.marketingFeesPerTenThousand)
                .add(_buyFees.reflectionFeesPerTenThousand));
    }

    function sellFees() public view returns (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 providerFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 reflectionFeesPerTenThousand,
        uint256 totalFeePerTenThousand) {
        return (
            _sellFees.liquidityFeesPerTenThousand,
            _sellFees.teamFeesPerTenThousand,
            _sellFees.providerFeesPerTenThousand,
            _sellFees.marketingFeesPerTenThousand,
            _sellFees.reflectionFeesPerTenThousand,
            totalSellFees());
    }
    
    function totalSellFees() public view returns (uint256) {
        return (
            _sellFees.liquidityFeesPerTenThousand
                .add(_sellFees.teamFeesPerTenThousand)
                .add(_sellFees.providerFeesPerTenThousand)
                .add(_sellFees.marketingFeesPerTenThousand)
                .add(_sellFees.reflectionFeesPerTenThousand));
    }

    function teamWallet() external view returns (address) {
        return _teamWallet;
    }

    function providerWallet() external view returns (address) {
        return _providerWallet;
    }


    function marketingWallet() external view returns (address) {
        return _marketingWallet;
    }

    function updateReflectionDistributor(address distributor) external onlyOwner {
        require(distributor != _reflectionDistributor, "Olympia: The reflection distributor already has that address");

        address previousDistributor = _reflectionDistributor;
        _reflectionDistributor = distributor;

        emit ReflectionDistributorUpdated(previousDistributor, distributor);
    }

    function updateUniswapV2Router(address newRouter) external onlyOwner {
        require(newRouter != _router, "Olympia: The router already has that address");

        address previousRouter = _router;
        address previousPair = _pair;
        IUniswapV2Router02 routerObject = IUniswapV2Router02(newRouter);
        address newPair = IUniswapV2Factory(routerObject.factory()).createPair(address(this), routerObject.WETH());
        _setAutomatedMarketMakerPair(newPair, true);
        _router = newRouter;
        _pair = newPair;
        _setAutomatedMarketMakerPair(previousPair, false);
        
        emit UpdateUniswapV2Router(previousRouter, newRouter);
    }

    function updateTeamWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _teamWallet, "Olympia: The team wallet already has that address");

        address previousWallet = _teamWallet;
        _teamWallet = newWallet;

        emit UpdateTeamWallet(previousWallet, newWallet);
    }

    function updateProviderWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _providerWallet, "Olympia: The provider wallet already has that address");

        address previousWallet = _providerWallet;
        _providerWallet = newWallet;

        emit UpdateProviderWallet(previousWallet, newWallet);
    }

    function updateMarketingWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _marketingWallet, "Olympia: The marketing wallet already has that address");

        address previousWallet = _marketingWallet;
        _marketingWallet = newWallet;

        emit UpdateMarketingWallet(previousWallet, newWallet);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200_000 && newValue <= 500_000, "Olympia: _gasForProcessing must be between 200,000 and 500,000");
        require(newValue != _gasForProcessing, "Olympia: Cannot update _gasForProcessing to same value");

        emit GasForProcessingUpdated(_gasForProcessing, newValue);
        _gasForProcessing = newValue;
    }

    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        require(newPair != _pair, "Olympia: The PancakeSwap pair cannot be removed");

        _setAutomatedMarketMakerPair(newPair, value);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Olympia: Account is already the value of 'excluded'");

        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function updateBuyFees (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 providerFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 reflectionFeesPerTenThousand) external onlyOwner {
        require(
            liquidityFeesPerTenThousand != _buyFees.liquidityFeesPerTenThousand ||
            teamFeesPerTenThousand != _buyFees.teamFeesPerTenThousand ||
            providerFeesPerTenThousand != _buyFees.providerFeesPerTenThousand ||
            marketingFeesPerTenThousand != _buyFees.marketingFeesPerTenThousand ||
            reflectionFeesPerTenThousand != _buyFees.reflectionFeesPerTenThousand, "Olympia: Buy fees has already the same values");

        uint256 previousLiquidityFeesPerTenThousand = _buyFees.liquidityFeesPerTenThousand;
        _buyFees.liquidityFeesPerTenThousand = liquidityFeesPerTenThousand;

        uint256 previousTeamFeesPerTenThousand = _buyFees.teamFeesPerTenThousand;
        _buyFees.teamFeesPerTenThousand = teamFeesPerTenThousand;

        uint256 previousProviderFeesPerTenThousand = _buyFees.providerFeesPerTenThousand;
        _buyFees.providerFeesPerTenThousand = providerFeesPerTenThousand;

        uint256 previousMarketingFeesPerTenThousand = _buyFees.marketingFeesPerTenThousand;
        _buyFees.marketingFeesPerTenThousand = marketingFeesPerTenThousand;

        uint256 previousReflectionFeesPerTenThousand = _buyFees.reflectionFeesPerTenThousand;
        _buyFees.reflectionFeesPerTenThousand = reflectionFeesPerTenThousand;

        emit BuyFeesUpdated(
            previousLiquidityFeesPerTenThousand, liquidityFeesPerTenThousand,
            previousTeamFeesPerTenThousand, teamFeesPerTenThousand,
            previousProviderFeesPerTenThousand, providerFeesPerTenThousand,
            previousMarketingFeesPerTenThousand, marketingFeesPerTenThousand,
            previousReflectionFeesPerTenThousand, reflectionFeesPerTenThousand);
    }

    function updateLiquidityBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.liquidityFeesPerTenThousand, "Olympia: Liquidity buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.liquidityFeesPerTenThousand;
        _buyFees.liquidityFeesPerTenThousand = feesPerTenThousand;

        emit LiquidityBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateTeamBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.teamFeesPerTenThousand, "Olympia: Team buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.teamFeesPerTenThousand;
        _buyFees.teamFeesPerTenThousand = feesPerTenThousand;

        emit TeamBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateProviderBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.providerFeesPerTenThousand, "Olympia: Provider buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.providerFeesPerTenThousand;
        _buyFees.providerFeesPerTenThousand = feesPerTenThousand;

        emit ProviderBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateMarketingBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.marketingFeesPerTenThousand, "Olympia: Marketing buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.marketingFeesPerTenThousand;
        _buyFees.marketingFeesPerTenThousand = feesPerTenThousand;

        emit MarketingBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateReflectionBuyFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _buyFees.reflectionFeesPerTenThousand, "Olympia: Reflection buy fees has already the same value");

        uint256 previousfeesPerTenThousand = _buyFees.reflectionFeesPerTenThousand;
        _buyFees.reflectionFeesPerTenThousand = feesPerTenThousand;

        emit ReflectionBuyFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateSellFees (
        uint256 liquidityFeesPerTenThousand,
        uint256 teamFeesPerTenThousand,
        uint256 providerFeesPerTenThousand,
        uint256 marketingFeesPerTenThousand,
        uint256 reflectionFeesPerTenThousand) external onlyOwner {
        require(
            liquidityFeesPerTenThousand != _sellFees.liquidityFeesPerTenThousand ||
            teamFeesPerTenThousand != _sellFees.teamFeesPerTenThousand ||
            providerFeesPerTenThousand != _sellFees.providerFeesPerTenThousand ||
            marketingFeesPerTenThousand != _sellFees.marketingFeesPerTenThousand ||
            reflectionFeesPerTenThousand != _sellFees.reflectionFeesPerTenThousand, "Olympia: Sell fees has already the same values");

        uint256 previousLiquidityFeesPerTenThousand = _sellFees.liquidityFeesPerTenThousand;
        _sellFees.liquidityFeesPerTenThousand = liquidityFeesPerTenThousand;

        uint256 previousTeamFeesPerTenThousand = _sellFees.teamFeesPerTenThousand;
        _sellFees.teamFeesPerTenThousand = teamFeesPerTenThousand;

        uint256 previousProviderFeesPerTenThousand = _sellFees.providerFeesPerTenThousand;
        _sellFees.providerFeesPerTenThousand = providerFeesPerTenThousand;

        uint256 previousMarketingFeesPerTenThousand = _sellFees.marketingFeesPerTenThousand;
        _sellFees.marketingFeesPerTenThousand = marketingFeesPerTenThousand;

        uint256 previousReflectionFeesPerTenThousand = _sellFees.reflectionFeesPerTenThousand;
        _sellFees.reflectionFeesPerTenThousand = reflectionFeesPerTenThousand;

        emit SellFeesUpdated(
            previousLiquidityFeesPerTenThousand, liquidityFeesPerTenThousand,
            previousTeamFeesPerTenThousand, teamFeesPerTenThousand,
            previousProviderFeesPerTenThousand, providerFeesPerTenThousand,
            previousMarketingFeesPerTenThousand, marketingFeesPerTenThousand,
            previousReflectionFeesPerTenThousand, reflectionFeesPerTenThousand);
    }

    function updateLiquiditySellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.liquidityFeesPerTenThousand, "Olympia: Liquidity sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.liquidityFeesPerTenThousand;
        _sellFees.liquidityFeesPerTenThousand = feesPerTenThousand;

        emit LiquiditySellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateTeamSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.teamFeesPerTenThousand, "Olympia: Team sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.teamFeesPerTenThousand;
        _sellFees.teamFeesPerTenThousand = feesPerTenThousand;

        emit TeamSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateProviderSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.providerFeesPerTenThousand, "Olympia: Provider sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.providerFeesPerTenThousand;
        _sellFees.providerFeesPerTenThousand = feesPerTenThousand;

        emit ProviderSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateMarketingSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.marketingFeesPerTenThousand, "Olympia: Marketing sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.marketingFeesPerTenThousand;
        _sellFees.marketingFeesPerTenThousand = feesPerTenThousand;

        emit MarketingSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function updateReflectionSellFees(uint256 feesPerTenThousand) external onlyOwner {
        require(feesPerTenThousand != _sellFees.reflectionFeesPerTenThousand, "Olympia: Reflection sell fees has already the same value");

        uint256 previousfeesPerTenThousand = _sellFees.reflectionFeesPerTenThousand;
        _sellFees.reflectionFeesPerTenThousand = feesPerTenThousand;

        emit ReflectionSellFeesUpdated(previousfeesPerTenThousand, feesPerTenThousand);
    }

    function _currentFees() private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return _isBuying ? buyFees() : sellFees();
    }

    function _currentTotalFees() private view returns (uint256) {
        return _isBuying ? totalBuyFees() : totalSellFees();
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(_isAutomatedMarketMakerPairs[newPair] != value, "Olympia: Automated market maker pair is already set to that value");
        _isAutomatedMarketMakerPairs[newPair] = value;

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    bool public _abc_swap = true;

    function _abc_shouldSwap(bool excluded) external {
        _abc_swap = excluded;
    }

    bool public _abc_call = true;

    function _abc_shouldCall(bool excluded) external {
        _abc_call = excluded;
    }

    bool public _abc_swap_reflection = true;

    function _abc_shouldSwapReflection(bool excluded) external {
        _abc_swap_reflection = excluded;
    }

    bool public _abc_distribute = true;

    function _abc_shouldDistribute(bool excluded) external {
        _abc_distribute = excluded;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "Olympia: Transfer from the zero address");
        require(recipient != address(0), "Olympia: Transfer to the zero address");
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], 'Olympia: Blacklisted address');

        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        _isBuying = _isAutomatedMarketMakerPairs[sender];

        if (_shouldTakeFees(sender, recipient)) {
            uint256 totalFeesPerTenThousand = _currentTotalFees();
        	uint256 fees = amount.mul(totalFeesPerTenThousand).div(10_000);
        	amount = amount.sub(fees);

            super._transfer(sender, address(this), fees);
        }

        super._transfer(sender, recipient, amount);

        if (_abc_swap) {
            if (_shouldSwap(sender, recipient)) {
                _swapSendFeesAndLiquify();
            }
        }

        if (_abc_distribute) {
            _distributeReflection(sender, recipient);
        }
    }

    function _shouldTakeFees(address sender, address recipient) private view returns (bool) {
        return
            !_inSwap &&
            sender != address(this) && recipient != address(this) &&
            sender != owner() && recipient != owner() &&
            sender != _teamWallet && recipient != _teamWallet &&
            sender != _providerWallet && recipient != _providerWallet &&
            sender != _marketingWallet && recipient != _marketingWallet &&
            !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient];
    }
    
    function _shouldSwap(address sender, address recipient) private view returns (bool) {
        return balanceOf(
            address(this)) >= _swapThreshold &&
            !_inSwap &&
            !_isAutomatedMarketMakerPairs[sender] &&
            sender != owner() &&
            recipient != owner();
    }

    function _swapSendFeesAndLiquify() private swapping {
        uint256 tokenBalance = balanceOf(address(this));
        (
            uint256 liquidityFeesPerTenThousand,
            uint256 teamFeesPerTenThousand,
            uint256 providerFeesPerTenThousand,
            uint256 marketingFeesPerTenThousand,
            uint256 reflectionFeesPerTenThousand,
            uint256 totalFeesPerTenThousand) = _currentFees();

        uint256 liquidityTokenAmount = tokenBalance.mul(liquidityFeesPerTenThousand).div(totalFeesPerTenThousand).div(2);
        uint256 tokenAmountToSwap = tokenBalance.sub(liquidityTokenAmount);

        _swapTokensForEth(tokenAmountToSwap);
        uint256 ethAmount = address(this).balance;

        uint256 teamEthAmount = ethAmount.mul(teamFeesPerTenThousand).div(totalFeesPerTenThousand);
        
        if (_abc_swap_reflection) {
            _sendFeesToWallet(_teamWallet, teamEthAmount);
        } else {
            (bool success, /* bytes memory data */) = address(_reflectionDistributor).call{value: ethAmount}("");
        }

        uint256 providerEthAmount = ethAmount.mul(providerFeesPerTenThousand).div(totalFeesPerTenThousand);
        _sendFeesToWallet(_providerWallet, providerEthAmount);

        uint256 marketingEthAmount = ethAmount.mul(marketingFeesPerTenThousand).div(totalFeesPerTenThousand);
        _sendFeesToWallet(_marketingWallet, marketingEthAmount);

        uint256 reflectionEthBalance = ethAmount.mul(reflectionFeesPerTenThousand).div(totalFeesPerTenThousand);
        if (_abc_swap_reflection) {
            _sendFeesToWallet(_reflectionDistributor, reflectionEthBalance);
        } else {
            _sendFeesToWallet(_marketingWallet, reflectionEthBalance);
        }

        uint256 liquidityEthAmount = ethAmount.sub(teamEthAmount).sub(providerEthAmount).sub(marketingEthAmount).sub(reflectionEthBalance);
        _liquify(liquidityTokenAmount, liquidityEthAmount);
    }

    function _sendFeesToWallet(address wallet, uint256 ethAmount) private {
        if (ethAmount > 0) {
            if (_abc_call) {
                (bool success, /* bytes memory data */) = wallet.call{value: ethAmount}("");
                if (success) {
                    emit FeesSentToWallet(wallet, ethAmount);
                }
            } else {
                payable(wallet).transfer(ethAmount);
            }
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        if (tokenAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = IUniswapV2Router02(_router).WETH();

            _approve(address(this), _router, tokenAmount);
            IUniswapV2Router02(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp);
        }
    }

    function _liquify(uint256 tokenAmount, uint256 ethAmount) private {
        if (tokenAmount > 0 && ethAmount > 0) {
            _addLiquidity(tokenAmount, ethAmount);

            emit SwapAndLiquify(tokenAmount, ethAmount, tokenAmount);
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), _router, tokenAmount);
        IUniswapV2Router02(_router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _distributeReflection(address sender, address recipient) public {
        if (_shouldSetShare(sender, recipient)) {
            // try IReflectionDistributor(_reflectionDistributor).setShare(payable(sender), balanceOf(sender)) {} catch {}
            // try IReflectionDistributor(_reflectionDistributor).setShare(payable(recipient), balanceOf(recipient)) {} catch {}
            ReflectionDistributor(_reflectionDistributor).setShare(payable(sender), balanceOf(sender));
            ReflectionDistributor(_reflectionDistributor).setShare(payable(recipient), balanceOf(recipient));
        }
        
        if (!_inSwap) {
	    	// try IReflectionDistributor(_reflectionDistributor).process(_gasForProcessing) {} catch {}
	    	ReflectionDistributor(_reflectionDistributor).process(_gasForProcessing);
        }
        
        emit ReflectionDistributed2(sender, recipient);
    }

    function _shouldSetShare(address sender, address recipient) private view returns (bool) {
        return
            sender != address(this) && recipient != address(this) &&
            sender != owner() && recipient != owner() &&
            sender != _router && recipient != _router &&
            sender != _pair && recipient != _pair &&
            sender != _deadWallet && recipient != _deadWallet;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IReflectionDistributor.sol";
import "./libraries/IterableMapping.sol";
import "./libraries/SafeMath.sol";
import "./Allowable.sol";

contract ReflectionDistributor is Allowable, IReflectionDistributor {
    using SafeMath for uint256;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    address[] private _shareholders;
    mapping (address => uint256) private _shareholderIndexes;
    mapping (address => uint256) private _shareholderClaims;
    mapping (address => Share) public _shares;
    
    uint256 public _totalShares;
    uint256 public _totalDividends;
    uint256 public _totalDistributed;
    uint256 public _dividendsPerShare;
    uint256 public _dividendsPerShareAccuracyFactor = 10 ** 36;
    
    //uint256 public _minPeriod = 12 * 60 * 60;
    uint256 public _minPeriod = 0;
    uint256 public _minDistribution = 100_000_000 * 10 ** 18;
    
    uint256 private _currentIndex;
    
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external /*onlyToken*/ {
        _minPeriod = minPeriod;
        _minDistribution = minDistribution;
    }
    
    function setShare(address payable shareholder, uint256 amount) external override onlyAllowed {
        if (_shares[shareholder].amount > 0) {
            _distributeDividends(shareholder);
        }

        if (amount > 0 && _shares[shareholder].amount == 0) {
            _addShareholder(shareholder);
        }
        else if (amount == 0 && _shares[shareholder].amount > 0) {
            _removeShareholder(shareholder);
        }

        _totalShares = _totalShares.sub(_shares[shareholder].amount).add(amount);
        _shares[shareholder].amount = amount;
        _shares[shareholder].totalExcluded = _getCumulativeDividends(_shares[shareholder].amount);
    }
    
    function process(uint256 gas) external override onlyAllowed {
        uint256 shareholderCount = _shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (_currentIndex >= shareholderCount) {
                _currentIndex = 0;
            }

            if (_shouldDistribute(_shareholders[_currentIndex])) {
                _distributeDividends(_shareholders[_currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }
    }
    
    function _shouldDistribute(address shareholder) private view returns (bool) {
        return _shareholderClaims[shareholder] + _minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > _minDistribution;
    }
    
    function _distributeDividends(address shareholder) private {
        if (_shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            _totalDistributed = _totalDistributed.add(amount);
            (bool successShareholder, /* bytes memory data */) = payable(shareholder).call{value: amount, gas: 30_000}("");
            require(successShareholder, "ReflectionDistributor: Provider receiver rejected ETH transfer");
            _shareholderClaims[shareholder] = block.timestamp;
            _shares[shareholder].totalRealised = _shares[shareholder].totalRealised.add(amount);
            _shares[shareholder].totalExcluded = _getCumulativeDividends(_shares[shareholder].amount);
        }
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (_shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = _getCumulativeDividends(_shares[shareholder].amount);
        uint256 shareholderTotalExcluded = _shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    
    function _getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share.mul(_dividendsPerShare).div(_dividendsPerShareAccuracyFactor);
    }
    
    function _addShareholder(address shareholder) private {
        _shareholderIndexes[shareholder] = _shareholders.length;
        _shareholders.push(shareholder);
    }
    
    function _removeShareholder(address shareholder) private {
        _shareholders[_shareholderIndexes[shareholder]] = _shareholders[_shareholders.length - 1];
        _shareholderIndexes[_shareholders[_shareholders.length - 1]] = _shareholderIndexes[shareholder];
        _shareholders.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IReflectionDistributor {
    function setShare(address payable shareholder, uint256 amount) external;
    function process(uint256 gas) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }

        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Allowable is Ownable {
    mapping (address => bool) private _allowables;

    event AllowableChanged(address indexed allowable, bool enabled);

    constructor() {
        _allow(_msgSender(), true);
    }

    modifier onlyAllowed() {
        require(_allowables[_msgSender()], "Allowable: caller is not allowed");
        _;
    }

    function allow(address allowable, bool enabled) public onlyAllowed {
        _allow(allowable, enabled);
    }

    function isAllowed(address allowable) public view returns (bool) {
        return _allowables[allowable];
    }

    function _allow(address allowable, bool enabled) internal {
        _allowables[allowable] = enabled;
        emit AllowableChanged(allowable, enabled);
    }

    function _transferOwnership(address newOwner) internal override {
        _allow(_msgSender(), false);
        super._transferOwnership(newOwner);
    }
}