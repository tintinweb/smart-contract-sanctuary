// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/UniswapInterface.sol";
import "./libraries/RFIFeeCalculator.sol";
import "./utils/Errors.sol";

/*
 * Por Token
 * Web: https://portoken.com 
 * Telegram: https://t.me/portumacommunity
 * Twitter: https://twitter.com/portumatoken
 * Instagram: https://www.instagram.com/portumatoken/
 * Linkedin: https://www.linkedin.com/company/portumatoken/
 * 
 * Total Supply: 10,000,000,000
 * Max Transaction Amount: 50,000,000 (0.5% of Total Supply)
 *
 *
 * first month sale conditions
 * Sell within 1 days  : %30 (%15 marketing, %5 Burn, %10 RFI) = Slippage Min: 43
 * Sell within 21 days : %20 (%10 marketing, %5 burn, %5 RFI) = Slippage Min: 25
 * Sell within 30 days : %10 (%7 marketing, %1 burn, %2 RFI) = Slippage Min: 11
 * sell after 30 days  : %5  (%4 marketing, %0.5 burn, %0.5 RFI) = Slippage Min: 6
 *
 * Ownership will be transfered to a Gnosis Multi Sig Wallet
 */

/// @title PorToken Token
/// @author WeCare Labs - https://wecarelabs.org
/// @notice Contract Has first month sell conditions by tiers defining the taken fee
contract PorToken is Initializable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using RFIFeeCalculator for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // structs
    EnumerableSetUpgradeable.AddressSet internal rewardExcludedList;
    RFIFeeCalculator.taxTiers internal taxTiers;
    RFIFeeCalculator.feeData internal feeData;
    RFIFeeCalculator.transactionFee internal fees;

    uint256 internal constant MAX = type(uint256).max;

    uint256 internal _tTotal;
    uint256 internal _rTotal;

    uint256 internal _tFeeTotal;
    uint256 internal _maxTxAmount;

    uint256 internal _start_timestamp;
    address internal _marketingWallet;
    uint256 internal _marketingFeeCollected;
    uint256 internal _swapMarketingAtAmount; // = 1 * 10**6 * 10**_decimals;

    IUniswapV2Router02 internal uniswapV2Router;
    address internal uniswapV2Pair;
    bool internal tradingIsEnabled;

    // Reflection Owned
    mapping(address => uint256) internal _rOwned;
    // Token Owned
    mapping(address => uint256) internal _tOwned;
    // is address allowed to spend on behalf
    mapping(address => mapping(address => uint256)) internal _allowances;
    // is address excluded from fee taken
    mapping(address => bool) internal _isExcludedFromFee;
    // is address exluded from Maximum transaction amount
    mapping(address => bool) internal _isExcludedFromMaxTx;
    // is address Blacklisted?
    mapping(address => bool) internal _isBlacklisted;
    // store automatic market maker pairs.
    mapping(address => bool) internal automatedMarketMakerPairs;
    // check ıf swap in progress
    bool internal inSwap;

    bool internal locked;

    // modifiers
    modifier lockTheSwap {
        if (inSwap) revert noReentrancyOnSwap();

        inSwap = true;
        _;
        inSwap = false;
    }

    // Events
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event ResetStartTimestamp(uint256 newStartTimestamp);
    event SetBurnFee(uint256 newStartTimestamp);
    event SetHolderFee(uint256 newHolderFee);
    event SetMarketingFee(uint256 newMarketingFee);
    event SetMarketingWallet(address marketingWallet);
    event SetTeamWallet(address teamWalletAddress);
    event SetSwapMarketingAtAmount(uint256 amount);
    event ExcludeFromReward(address account);
    event IncludeInReward(address account);
    event CreateETHSwapPair(address routerAddress);
    event SetMaxTxAmount(uint256 amount);
    event ExcludeFromFee(address account);
    event IncludeInFee(address account);
    event SetTradingStatus(bool status);
    event MarketingFeeSent(uint256 amount);
    event BlacklistStatusChanged(address indexed account, bool value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("Portuma", "POR");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1e10 * 10 ** decimals());

        __initializeParams();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }

    receive() external payable {}

    // initialize the additional parameter on contract deploy
    function __initializeParams() initializer internal onlyOwner {
        _tTotal = super.totalSupply();
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[owner()] = _rTotal;

        _maxTxAmount = _tTotal * 50 / 1e4; //Max Transaction: 50 Milion (0.5%)
        _swapMarketingAtAmount = 1 * 1e6 * 10**decimals();

        /// Standard Fees
        feeData = RFIFeeCalculator.feeData(0.5 * 1e2, 0.5 * 1e2, 4 * 1e2);

        taxTiers.time = [24, 504, 720];
        // 24 = 1 day, 168 = 7 days, 504 = 21 days, 720 = 30 days
        taxTiers.tax[0] = RFIFeeCalculator.feeData(5 * 1e2, 10 * 1e2, 15 * 1e2);
        taxTiers.tax[1] = RFIFeeCalculator.feeData(5 * 1e2, 5 * 1e2, 10 * 1e2);
        taxTiers.tax[2] = RFIFeeCalculator.feeData(1 * 1e2, 2 * 1e2, 7 * 1e2);

        _start_timestamp = block.timestamp;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxTx[owner()] = true;

        rewardExcludedList.add(address(0xdead));
        rewardExcludedList.add(address(0));
        rewardExcludedList.add(address(this));

        /// Will be active after presale
        tradingIsEnabled = false;

        locked = false;
    }

    /***********************************|
    |              Overrides            |
    |__________________________________*/
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (rewardExcludedList.contains(account)) return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        if(account == address(0)) revert AddressIsZero(account);

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf(account);
        if(amount > accountBalance) revert AmountExceedsAccountBalance();

        bool feeDeducted = rewardExcludedList.contains(account);
        uint256 rAmount = reflectionFromToken(amount, feeDeducted);
        _rTotal -= rAmount;
        _tTotal -= amount;
        
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /***********************************|
    |           Write Functions         |
    |__________________________________*/
    function setMaxTxAmount(uint256 _maxAmount) external onlyOwner {
        if (_maxAmount > totalSupply()) revert MaxTransactionAmountExeeds(_maxAmount, totalSupply());

        _maxTxAmount = _maxAmount;
        emit SetMaxTxAmount(_maxAmount);
    }

    function excludeFromReward(address account) external onlyOwner {
        if (rewardExcludedList.contains(account)) revert AccountAlreadyExcludedFromReward(account);

        _excludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        if (!rewardExcludedList.contains(account)) revert AccountAlreadyIncludedInReward(account);

        rewardExcludedList.remove(account);

        emit IncludeInReward(account);
    }

    function excludeFromFee(address account) external onlyOwner {
        if (_isExcludedFromFee[account]) revert AccountAlreadyExcludedFromFee(account);

        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        if (!_isExcludedFromFee[account]) revert AccountAlreadyIncludedInFee(account);

        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    /// newStartTimestamp: in seconds
    function resetStartTimestamp(uint256 newStartTimestamp) external onlyOwner {
        _start_timestamp = newStartTimestamp;

        emit ResetStartTimestamp(newStartTimestamp);
    }

    /// newBurnFee: 100 = 1.00%
    function setBurnFee(uint256 newBurnFee) external onlyOwner {
        feeData.burnFee = newBurnFee;

        emit SetBurnFee(newBurnFee);
    }

    /// newHolderFee: 100 = 1.00%
    function setHolderFee(uint256 newHolderFee) external onlyOwner {
        feeData.holderFee = newHolderFee;

        emit SetHolderFee(newHolderFee);
    }

     /// newMarketingFee: 100 = 1.00%
    function setMarketingFee(uint256 newMarketingFee) external onlyOwner {
        feeData.marketingFee = newMarketingFee;

        emit SetMarketingFee(newMarketingFee);
    }
    
    function setSwapMarketingAtAmount(uint256 amount) external onlyOwner {
        if (amount <= 0) revert AmountIsZero();

        _swapMarketingAtAmount = amount;
        emit SetSwapMarketingAtAmount(amount);
    }

    function setMarketingWallet(address marketingWalletAddress) external onlyOwner {
        if (marketingWalletAddress == address(0)) revert AddressIsZero(marketingWalletAddress);
        
        _marketingWallet = marketingWalletAddress;
        _isExcludedFromFee[marketingWalletAddress] = true;

        emit SetMarketingWallet(marketingWalletAddress);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        if (automatedMarketMakerPairs[pair] == value) revert MarketMakerAlreadySet(pair, value);

        _setAutomatedMarketMakerPair(pair, value);
    }

    function createETHSwapPair(address _routerAddress) external onlyOwner {
        if (uniswapV2Pair > address(0)) revert PairAlreadySet(uniswapV2Pair);
        if (_routerAddress == address(0)) revert AddressIsZero(_routerAddress);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);        
        uniswapV2Router = _uniswapV2Router;
        _excludeFromReward(_routerAddress);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        emit CreateETHSwapPair(_routerAddress);
    }

    function setUniswapRouter(address _addr) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_addr);
        uniswapV2Router = _uniswapV2Router;

        _excludeFromReward(_addr);
    }

    function setUniswapPair(address _addr) external onlyOwner {
        if (_addr == address(0)) revert AddressIsZero(_addr);
        if (uniswapV2Pair == _addr) revert PairAlreadySet(_addr); 
        
        uniswapV2Pair = _addr;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }

    function setTradingIsEnabled(bool value) external onlyOwner {
        if (tradingIsEnabled == value) revert TradingStatusAlreadySet(value);

        tradingIsEnabled = value;
        emit SetTradingStatus(value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        if (_isBlacklisted[account] == value) revert BlaclistStatusAlreadySet(account, value);

        _isBlacklisted[account] = value;

        emit BlacklistStatusChanged(account, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) internal {
        if (automatedMarketMakerPairs[pair] == value) return;
        
        automatedMarketMakerPairs[pair] = value;

        _excludeFromReward(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _excludeFromReward(address account) internal {
        if (!rewardExcludedList.contains(account)) {
            if (_rOwned[account] > 0) _tOwned[account] = tokenFromReflection(_rOwned[account]);

            rewardExcludedList.add(account);

            emit ExcludeFromReward(account);
        }
    }

    /***********************************|
    |            Read Functions         |
    |__________________________________*/
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        if (rAmount > _rTotal) revert AmountExceedsTotalReflection(rAmount);

        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        if (tAmount > _tTotal) revert AmountExceedsTotalSupply(tAmount);
        uint256 tss = block.timestamp - _start_timestamp;
        
        RFIFeeCalculator.transactionFee memory f = tAmount.calculateFees(_getRate(), feeData, false, taxTiers, tss);
        if (!deductTransferFee) return f.rAmount;
        
        return f.rTransferAmount;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return rewardExcludedList.contains(account);
    }

    function getBurnFee() external view returns (uint256) {
        return feeData.burnFee;
    }

    function getHolderFee() external view returns (uint256) {
        return feeData.holderFee;
    }

    function getMarketingFee() external view returns (uint256) {
        return feeData.marketingFee;
    }

    function getTaxTiers() external view returns (uint256[] memory) {
        return taxTiers.time;
    }

    function getTradingStatus() external view returns (bool) {
        return tradingIsEnabled;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function getMaxTxAmount() external view returns (uint256) {
        return _maxTxAmount;
    }

    function getStartTime() external view returns (uint256) {
        return _start_timestamp;
    }

    function _getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        
        return rSupply / tSupply;
    }

    // Get current supply for Reflection
    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        uint256 excludedLength = rewardExcludedList.length();
        uint256 i = 0;

        do {
            address excludedAddress = rewardExcludedList.at(i);
            if (_rOwned[excludedAddress] > rSupply || _tOwned[excludedAddress] > tSupply) return (_rTotal, _tTotal);

            rSupply -= _rOwned[excludedAddress];
            tSupply -= _tOwned[excludedAddress];

            i += 1;
        } while (i < excludedLength); // less Gas usage than for and while

        if (rSupply < _rTotal /_tTotal) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    /***********************************|
   |          General Functions         |
   |__________________________________*/
    function getCurrentBurnFeeOnSale() external view returns (uint256 fee) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        return RFIFeeCalculator.getCurrentBurnFeeOnSale(time_since_start, taxTiers, feeData);
    }

    function getCurrentHolderFeeOnSale() external view returns (uint256 fee) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        return RFIFeeCalculator.getCurrentHolderFeeOnSale(time_since_start, taxTiers, feeData);
    }

    function getCurrentMarketingFeeOnSale() external view returns (uint256 fee) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        return RFIFeeCalculator.getCurrentMarketingFeeOnSale(time_since_start, taxTiers, feeData);
    }

    function calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 10**4;
    }
    
    /***********************************|
    |        Transfer Functions         |
    |__________________________________*/
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        _beforeTokenTransfer(sender, recipient, amount);

        _validateTransfer(sender, recipient, amount);

        // if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = true;
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) takeFee = false;

        bool isSell = false;
        if (sender != address(uniswapV2Router) && automatedMarketMakerPairs[recipient] && takeFee) isSell = true;

        _tokenTransfer(sender, recipient, amount, takeFee, isSell);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /// Validate Transaction Data
    function _validateTransfer(address sender, address recipient, uint256 amount) internal view {
        if (sender == address(0) || recipient == address(0)) revert SenderOrRecipientAddressIsZero(sender, recipient);
        if (_isBlacklisted[sender] || _isBlacklisted[recipient]) revert SenderOrRecipientBlacklisted(sender, recipient);
        if (amount <= 0) revert AmountIsZero();
        if (!tradingIsEnabled && (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient])) revert TradingNotStarted();

        if (!_isExcludedFromMaxTx[sender] && !_isExcludedFromMaxTx[recipient]) {
            if(amount > _maxTxAmount) revert MaxTransactionAmountExeeds(_maxTxAmount, amount);
        }

        uint256 curentSenderBalance = balanceOf(sender);
        if (amount > curentSenderBalance) revert InsufficientBalance(curentSenderBalance, amount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) internal {
        uint256 transferAmount = amount;
        uint256 currentRate = _getRate();

        if (takeFee) {
            uint256 tss = block.timestamp - _start_timestamp;
            RFIFeeCalculator.transactionFee memory f = amount.calculateFees(currentRate, feeData, isSell, taxTiers, tss);
            // Take Reflect Fee
            _takeReflectionFee(sender, recipient, f);
            _reflectTotal(f.rFee, f.tFee);

            if (f.tMarketing > 0) {
                _takeTransactionFee(_marketingWallet, f.tMarketing, f.currentRate);
                emit Transfer(sender, _marketingWallet, f.tMarketing);
            }

            if (f.tBurn > 0) {
                // _takeTransactionFee(address(0), f.tBurn, f.currentRate);
                _rTotal -= f.rBurn;
                _tTotal -= f.tBurn;

                emit Transfer(sender, address(0), f.tBurn);
            }

            transferAmount = f.tTransferAmount;
        } else {
            uint256 reflectionAmount = transferAmount * currentRate;
            RFIFeeCalculator.transactionFee memory nofee = RFIFeeCalculator.transactionFee(
                reflectionAmount, reflectionAmount, 0, 0, 0, transferAmount, transferAmount, 0, 0, 0, currentRate
            );
            _takeReflectionFee(sender, recipient, nofee);
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function _takeReflectionFee(address sender, address recipient, RFIFeeCalculator.transactionFee memory f) internal {
        _rOwned[sender] -= f.rAmount;
        _rOwned[recipient] += f.rTransferAmount;

        if (rewardExcludedList.contains(sender)) _tOwned[sender] -= f.tAmount;
        if (rewardExcludedList.contains(recipient)) _tOwned[recipient] += f.tTransferAmount;
    }

    function _takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) internal {
        uint256 rAmount = tAmount * currentRate;
        _rOwned[to] += rAmount;

        if (rewardExcludedList.contains(to)) _tOwned[to] += tAmount;
    }

    function _reflectTotal(uint256 rFee, uint256 tFee) internal {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    /***********************************|
    |            External Calls         |
    |__________________________________*/
    function swapAndSendTokensForMarketing(uint256 tokenAmount) internal lockTheSwap {
        if (_marketingWallet == address(0)) return;

        if (tokenAmount > _marketingFeeCollected) {
            tokenAmount = _marketingFeeCollected;
        }

        _marketingFeeCollected -= tokenAmount;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        emit MarketingFeeSent(tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _marketingWallet,
            block.timestamp + 360
        );
    }

    // Send ERC20 Tokens to Multisig wallet
    function withdrawERC20(address _recipient, address _ERC20address, uint256 _amount) external onlyOwner returns (bool) {
        if (_ERC20address == address(this)) revert CannotTransferContractTokens();
        return IERC20Upgradeable(_ERC20address).transfer(_recipient, _amount);
    }

    // Send Contract BNB/ETH Balance to Multisig wallet
    function transferBalance() external onlyOwner returns (bool) {
        (bool success,) = owner().call{value: address(this).balance}("");
        
        return success;
    }

    function withdrawContractTokens() external onlyOwner returns (bool) {
        uint256 contractBalance = balanceOf(address(this));
        uint256 currentRate = _getRate();

        if (contractBalance > 0) {
            uint256 rAmount = contractBalance * currentRate;
            _rOwned[_marketingWallet] += rAmount;

            if (rewardExcludedList.contains(_marketingWallet)) _tOwned[_marketingWallet] += contractBalance;

            _tOwned[address(this)] = 0;

            emit Transfer(address(this), _marketingWallet, contractBalance);
        }

        return true;
    }

    function multiTransfer(address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
        address from = msg.sender;
        uint256 addrLength = addresses.length;
        uint256 tokenLength = tokens.length;
        if (addrLength > 750) revert MaxLengthExeeds(750);
        if (addrLength != tokenLength) revert MismatchLength(addrLength, tokenLength);

        uint256 senderBalance = balanceOf(from);
        uint256 totalToken = 0;
        for (uint i = 0; i < addrLength; i++) {
            totalToken += tokens[i];

            if (totalToken >= senderBalance) revert AmountExceedsAccountBalance();
        }

        for (uint i = 0; i < addrLength; i++) {
            uint256 currentRate = _getRate();
            uint256 transferAmount = tokens[i];
            uint256 reflectionAmount = transferAmount * currentRate;
            
            RFIFeeCalculator.transactionFee memory nofee = RFIFeeCalculator.transactionFee(
                reflectionAmount, reflectionAmount, 0, 0, 0, transferAmount, transferAmount, 0, 0, 0, currentRate
            );

            _takeReflectionFee(from, addresses[i], nofee);
            emit Transfer(from, addresses[i], transferAmount);
        }
    }

    function makeMM(address[] calldata addresses, bool _value) external onlyOwner {
        uint256 addrLength = addresses.length;

        for (uint i = 0; i < addrLength; i++) {
            _isExcludedFromFee[addresses[i]] = _value;
        }
    }

    function fixBurn() external onlyOwner {
        require(!locked);

        uint256 _totalSupply = 1e10 * 10 ** decimals();
        uint256 _tBurn = balanceOf(address(0));
        uint256 _rBurn = _tBurn * _getRate();

        _rOwned[address(0)] = _rOwned[address(0)] - _rBurn;
        _tOwned[address(0)] = _tOwned[address(0)] - _tBurn;
        _rTotal = _rTotal - _rBurn;
        _tTotal = _totalSupply - _tBurn;
        locked = true;
    }

    function getTOwned(address account) external view onlyOwner returns (uint256) {
        return _tOwned[account];
    }

    function getROwned(address account) external view onlyOwner returns (uint256) {
        return _rOwned[account];
    }

    // Current Version of the implementation
    function version() external pure virtual returns (string memory) {
        return '1.0.3';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.2;

library RFIFeeCalculator {
    uint256 private constant HOUR = 60 * 60;

    struct feeData {
        uint256 burnFee;
        uint256 holderFee;
        uint256 marketingFee; 
    }

    struct transactionFee {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rMarketing;
        uint256 rBurn;

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tMarketing;
        uint256 tBurn;

        uint256 currentRate;
    }

    struct taxTiers {
        uint256[] time;
        mapping(uint256 => feeData) tax;
    }

    function calculateFees(
        uint256 amount,
        uint256 rate,
        feeData memory fd,
        bool isSell,
        taxTiers storage tt,
        uint256 tss
    ) internal view returns (transactionFee memory) {
        transactionFee memory tf;
        tf.currentRate = rate;

        tf.tAmount    = amount;
        tf.tBurn      = calculateFee(amount, isSell ? getCurrentBurnFeeOnSale(tss, tt, fd) : fd.burnFee);
        tf.tFee       = calculateFee(amount, isSell ? getCurrentHolderFeeOnSale(tss, tt, fd) : fd.holderFee);
        tf.tMarketing = calculateFee(amount, isSell ? getCurrentMarketingFeeOnSale(tss, tt, fd) : fd.marketingFee);
        
        tf.tTransferAmount = amount - tf.tFee - tf.tMarketing - tf.tBurn;
        
        tf.rAmount     = tf.tAmount * tf.currentRate;
        tf.rBurn       = tf.tBurn * tf.currentRate;
        tf.rFee        = tf.tFee * tf.currentRate;
        tf.rMarketing  = tf.tMarketing * tf.currentRate;

        tf.rTransferAmount = tf.rAmount - tf.rFee - tf.rMarketing - tf.rBurn;

        return tf;
    }

    function calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 10**4;
    }

    function getCurrentBurnFeeOnSale(
        uint256 time_since_start,
        taxTiers storage tt,
        feeData memory fd
    ) internal view returns (uint256 fee) {
        fee = fd.burnFee;
        if (time_since_start < tt.time[0] * HOUR) {
            fee = tt.tax[0].burnFee;
        } else if (time_since_start < tt.time[1] * HOUR) {
            fee = tt.tax[1].burnFee;
        } else if (time_since_start < tt.time[2] * HOUR) {
            fee = tt.tax[2].burnFee;
        }
    }

    function getCurrentHolderFeeOnSale(
        uint256 time_since_start,
        taxTiers storage tt,
        feeData memory fd
    ) internal view returns (uint256 fee) {
        fee = fd.holderFee;
        if (time_since_start < tt.time[0] * HOUR) {
            fee = tt.tax[0].holderFee;
        } else if (time_since_start < tt.time[1] * HOUR) {
            fee = tt.tax[1].holderFee;
        } else if (time_since_start < tt.time[2] * HOUR) {
            fee = tt.tax[2].holderFee;
        }
    }

    function getCurrentMarketingFeeOnSale(
        uint256 time_since_start,
        taxTiers storage tt,
        feeData memory fd
    ) internal view returns (uint256 fee) {
        fee = fd.marketingFee;
        if (time_since_start < tt.time[0] * HOUR) {
            fee = tt.tax[0].marketingFee;
        } else if (time_since_start < tt.time[1] * HOUR) {
            fee = tt.tax[1].marketingFee;
        } else if (time_since_start < tt.time[2] * HOUR) {
            fee =  tt.tax[2].marketingFee;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// Insufficient balance for transfer. Needed `required` but only
/// `available` available.
/// @param available balance available.
/// @param required requested amount to transfer.
error InsufficientBalance(uint256 available, uint256 required);

/// Maximum allowed transaction amount should not be more than the defined limit
/// @param limit defined limit
/// @param sent requested amount
error MaxTransactionAmountExeeds(uint256 limit, uint256 sent);

/// Requested address is already excluded from Reward(RFI)
/// @param account requested address
error AccountAlreadyExcludedFromReward(address account);

/// Requested address is already included in Reward(RFI)
/// @param account requested address
error AccountAlreadyIncludedInReward(address account);

/// Requested address is already excluded from paying fees
/// @param account requested address
error AccountAlreadyExcludedFromFee(address account);

/// Requested address is already included in paying fees
/// @param account requested address
error AccountAlreadyIncludedInFee(address account);

/// Requested address can not be Zero address
/// @param account requested address
error AddressIsZero(address account);

/// Requested amount can not be zero
error AmountIsZero();

/// Requested address is already in the market makers list
/// @param pair requested address
/// @param value requested value
error MarketMakerAlreadySet(address pair, bool value);

/// Requested pair address is already set
/// @param pair requested address
error PairAlreadySet(address pair);

/// Requested trading status value is already set
/// @param value requested value
error TradingStatusAlreadySet(bool value);

/// Requested status value is already set in Blaclist for this account
/// @param account requested address
/// @param value requested value
error BlaclistStatusAlreadySet(address account, bool value);

/// Requested amount exceeds the total reflection amount
/// @param amount requested amount
error AmountExceedsTotalReflection(uint256 amount);

/// Requested amount exceeds the total supply amount
/// @param amount requedted amount
error AmountExceedsTotalSupply(uint256 amount);

/// Requested addresses can not be Zero address
/// @param sender requested sender address
/// @param recipient requested recipient address
error SenderOrRecipientAddressIsZero(address sender, address recipient);

/// Requested addresses in the blacklist
/// @param sender requested sender address
/// @param recipient requested recipient address
error SenderOrRecipientBlacklisted(address sender, address recipient);

/// Trading status is currently not activated
error TradingNotStarted();

/// Requested contract tokens can not be transferred out
error CannotTransferContractTokens();

/// Requested amount exceeds the total balance of rrequested account
error AmountExceedsAccountBalance();

/// Reentrancy check on swapping
error noReentrancyOnSwap();

/// Giving list exceeds the max length
/// @param maxLength Allowed max length
error MaxLengthExeeds(uint256 maxLength);

/// giving data lengths are not equal
/// @param aLength A side length
/// @param bLength B side length
error MismatchLength(uint256 aLength, uint256 bLength);

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}