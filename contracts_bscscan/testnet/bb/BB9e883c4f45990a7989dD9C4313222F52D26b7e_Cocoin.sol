// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

pragma abicoder v2;

/**
@dev interfaces/models */
import "./interface/IERC20.sol";
import "./interface/IPancakeRouter02.sol";
import "./interface/ICommunityBooster.sol";
import "./interface/IPancakeFactory.sol";
/**
@dev libraries
 */
import "./lib/SafeMath.sol";
import "./lib/Address.sol";
import "./lib/SafeERC20.sol";
import "./lib/Events.sol";

/**
@dev utils
 */
import "./utils/Ownable.sol";
import "./utils/Types.sol";

contract Cocoin is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    // string public constant name = "Cocoin";
    // string public constant symbol = "COCO";
    uint8 public constant decimals = 9;
    uint256 private constant _MAX_UINT = ~uint256(0);

    TokenStats internal _stats =
        TokenStats((_MAX_UINT - _MAX_UINT.mod(10e23)), 10e23, 0, 0, 0, 0);
    TaxRates internal _taxRates = TaxRates(2, 2, 2, 2, 2, 0, 10);
    Vaults internal _vaults;

    uint256 internal tokenLiquidityThreshold = 50e14;
    bool private _isProvidingLiquidity = true;
    bool private _liquidityMutex = false;
    bool private _isUpdatingHolderCount = false;
    uint256 startDate;
    uint256 private additionalLaunchTax = 15;
    uint256 private dayScale = 15;

    IPancakeRouter02 public immutable router;
    address public immutable pair;

    ICommunityBooster public communityBooster;

    mapping(address => Balances) private _balances;
    mapping(address => ExemptionStats) private _exemptions;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

    // constructor
    constructor() {
        address deployer = _msgSender();
        TokenStats storage stats = _stats;
        address pancakeRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

        uint256 initialRate = _stats.totalReflection.div(_stats.totalTokens);
        uint256 tokensToBurn = _stats.totalTokens.div(2);
        uint256 reflectionToBurn = tokensToBurn.mul(initialRate);
        stats.totalTokens = _stats.totalTokens.sub(tokensToBurn);
        stats.totalReflection = _stats.totalReflection.sub(reflectionToBurn);

        _balances[deployer].reflection = stats.totalReflection;
        emit Transfer(address(0), deployer, _stats.totalTokens);
        emit Events.Burn(tokensToBurn);

        IPancakeRouter02 _router = IPancakeRouter02(pancakeRouter);
        router = _router;

        _exemptions[deployer].isExcludedFromFee = true;
        _exemptions[address(this)].isExcludedFromFee = true;

        pair = IPancakeFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
    }

    // fallbacks
    receive() external payable {}

    // external
    function totalSupply() external pure override returns (uint256) {
        return 10e23;
    }

    function circulatingSupply() external view returns (uint256) {
        return _stats.totalTokens;
    }

    function totalFees() external view returns (uint256) {
        return _stats.totalFees;
    }

    function additionalTaxAmount() external view returns (uint256) {
        uint256 dayCount = (block.timestamp - startDate) / 86400;
        uint256 earlyAddon = 0;

        if (dayCount <= dayScale) {
            earlyAddon =
                (dayScale - dayCount) *
                additionalLaunchTax.div(dayScale);
        }

        return earlyAddon;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "Cocoin: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        require(
            (amount == 0) || (_allowances[_msgSender()][spender] == 0),
            "Cocoin: approve from non-zero to non-zero allowance"
        );
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 value)
        external
        returns (bool)
    {
        uint256 newValue = allowance(_msgSender(), spender).add(value);
        _approve(_msgSender(), spender, newValue);
        return true;
    }

    function setStartDate(uint256 _startDate) public onlyOwner {
        require(startDate == 0, "startDate has already been set");
        startDate = _startDate;
    }

    function setAdditionalTaxValue(uint256 _launchTax, uint256 _dayscale)
        public
        onlyOwner
    {
        additionalLaunchTax = _launchTax;
        dayScale = _dayscale;
    }

    function decreaseAllowance(address spender, uint256 value)
        external
        returns (bool)
    {
        uint256 oldValue = allowance(_msgSender(), spender);
        require(
            oldValue >= value,
            "Cocoin: cannot decrease allowance below zero"
        );
        uint256 newValue = oldValue.sub(value);
        _approve(_msgSender(), spender, newValue);
        return true;
    }

    function setVaultsAddresses(
        address charity,
        address marketing,
        address community
    ) external onlyOwner {
        Vaults storage vaults = _vaults;

        vaults.charityVault = charity;
        vaults.marketingVault = marketing;
        vaults.communityBoostVault = community;

        _exemptions[vaults.charityVault].isExcluded = true;
        _exemptions[vaults.marketingVault].isExcluded = true;
        _exemptions[vaults.communityBoostVault].isExcluded = true;

        emit Events.VaultsUpdated(charity, marketing, community);
    }

    function updateTaxes(TaxRates calldata newTaxRates) external onlyOwner {
        _taxRates = newTaxRates;

        emit Events.TaxRatesUpdated(_taxRates.totalTaxRate);
    }

    function setCommunityBooster(address booster) external onlyOwner {
        communityBooster = ICommunityBooster(booster);

        emit Events.CommunityBoosterUpdated(booster);
    }

    function updateLiquidityThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 0, "Cocoin: Cannot set threshold to zero");
        tokenLiquidityThreshold = threshold;

        emit Events.LiquidityThresholdUpdated(tokenLiquidityThreshold);
    }

    function updateLiquidityProvisionState(bool state) external onlyOwner {
        _isProvidingLiquidity = state;

        emit Events.LiquidityProvisionStateChanged(_isProvidingLiquidity);
    }

    function updateHolderStatisticState(bool state) external onlyOwner {
        _isUpdatingHolderCount = state;

        emit Events.CountingHoldersStateChanged(_isUpdatingHolderCount);
    }

    function updateAccountExclusionState(
        address account,
        bool excludeFromReward,
        bool excludeFromFees
    ) external onlyOwner {
        TokenStats storage stats = _stats;
        if (excludeFromReward && !_exemptions[account].isExcluded) {
            _balances[account].tokens = tokenFromReflection(
                _balances[account].reflection
            );
            stats.totalExcludedReflection = _stats.totalExcludedReflection.add(
                _balances[account].reflection
            );
            stats.totalExcludedTokens = _stats.totalExcludedTokens.add(
                _balances[account].tokens
            );
        }
        if (!excludeFromReward && _exemptions[account].isExcluded) {
            stats.totalExcludedReflection = _stats.totalExcludedReflection.sub(
                _balances[account].reflection
            );
            stats.totalExcludedTokens = _stats.totalExcludedTokens.sub(
                _balances[account].tokens
            );

            _balances[account].tokens = 0;
        }

        _exemptions[account].isExcludedFromFee = excludeFromFees;
        _exemptions[account].isExcluded = excludeFromReward;

        emit Events.AccountExclusionStateChanged(
            account,
            excludeFromReward,
            excludeFromFees
        );
    }

    // public

    function balanceOf(address account) public view override returns (uint256) {
        if (_exemptions[account].isExcluded) return _balances[account].tokens;
        return tokenFromReflection(_balances[account].reflection);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function reflectionFromToken(uint256 amountTokens, bool deductFees)
        public
        view
        returns (uint256)
    {
        require(
            amountTokens <= _stats.totalTokens,
            "Cocoin: amount must be less than total supply"
        );
        (CalculationParameters memory params, ) = calculateValues(
            amountTokens,
            deductFees,
            address(0)
        );
        return params.reflectionTransferAmount;
    }

    // internal
    function tokenFromReflection(uint256 reflectionAmount)
        internal
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _stats.totalReflection,
            "Cocoin: amount has to be less or equal to total reflection"
        );
        uint256 rate = calculateReflectionRate();

        return reflectionAmount.div(rate);
    }

    function calculateValues(
        uint256 tokenAmount,
        bool isTakingFees,
        address from
    )
        internal
        view
        returns (CalculationParameters memory, TaxCalculationParameters memory)
    {
        uint256 rate = calculateReflectionRate();

        CalculationParameters memory params = CalculationParameters(0, 0, 0);
        TaxCalculationParameters memory taxParams = TaxCalculationParameters(
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        taxParams = isTakingFees
            ? calculateTaxes(_taxRates, tokenAmount, rate, from)
            : taxParams;

        params.reflectionAmount = tokenAmount.mul(rate);

        if (isTakingFees) {
            params.tokenTransferAmount = tokenAmount.sub(taxParams.tokenTaxSum);
            params.reflectionTransferAmount = params.reflectionAmount.sub(
                taxParams.reflectionTaxSum
            );
        } else {
            params.tokenTransferAmount = tokenAmount;
            params.reflectionTransferAmount = params.reflectionAmount;
        }

        return (params, taxParams);
    }

    function calculateReflectionRate() internal view returns (uint256) {
        (
            uint256 reflectionSupply,
            uint256 tokenSupply
        ) = calculateActualSupply();

        return reflectionSupply.div(tokenSupply);
    }

    function calculateTaxes(
        TaxRates memory taxes,
        uint256 tokenAmount,
        uint256 rate,
        address from
    ) internal view returns (TaxCalculationParameters memory) {
        TaxCalculationParameters memory params;

        uint256 dayCount = (block.timestamp - startDate) / 86400;
        uint256 earlyAddon;

        if (from != address(pair) && dayCount <= dayScale) {
            earlyAddon =
                (dayScale - dayCount) *
                additionalLaunchTax.div(dayScale);
        }

        params.instantBoostValue = tokenAmount.mul(taxes.instantBoost).div(100);
        params.instantBoostReflectionValue = params.instantBoostValue.mul(rate);

        params.charityValue = tokenAmount.mul(taxes.charity).div(100);
        params.charityReflectionValue = params.charityValue.mul(rate);

        params.marketingValue = tokenAmount.mul(taxes.marketing).div(100);
        params.marketingReflectionValue = params.marketingValue.mul(rate);

        params.liquidityValue = tokenAmount.mul(taxes.liquidity).div(100);
        params.liquidityReflectionValue = params.liquidityValue.mul(rate);

        params.burnValue = tokenAmount.mul(taxes.burn).div(100);
        params.burnReflectionValue = params.burnValue.mul(rate);

        params.communityBoostValue = tokenAmount.mul(taxes.communityBoost).div(
            100
        );
        params.communityBoostReflectionValue = params.communityBoostValue.mul(
            rate
        );

        params.tokenTaxSum = tokenAmount
            .mul(taxes.totalTaxRate + earlyAddon)
            .div(100);
        params.reflectionTaxSum = params.tokenTaxSum.mul(rate);

        return params;
    }

    function calculateActualSupply() internal view returns (uint256, uint256) {
        uint256 reflectionSupply = _stats.totalReflection;
        uint256 tokenSupply = _stats.totalTokens;

        reflectionSupply = reflectionSupply.sub(_stats.totalExcludedReflection);
        tokenSupply = tokenSupply.sub(_stats.totalExcludedTokens);

        if (reflectionSupply < _stats.totalReflection.div(_stats.totalTokens))
            return (_stats.totalReflection, _stats.totalTokens);

        return (reflectionSupply, tokenSupply);
    }

    function extendedTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        bool isFromExcluded = _exemptions[sender].isExcluded;
        bool isToExcluded = _exemptions[recipient].isExcluded;

        bool takeFees = !(_exemptions[sender].isExcludedFromFee ||
            _exemptions[recipient].isExcludedFromFee);

        if (isFromExcluded || isToExcluded) {
            extendedTransferExcluded(
                sender,
                recipient,
                amount,
                isToExcluded,
                isFromExcluded,
                takeFees
            );
        } else {
            extendedTransferStandard(sender, recipient, amount, takeFees);
        }
    }

    function extendedTransferStandard(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFees
    ) internal {
        (
            CalculationParameters memory params,
            TaxCalculationParameters memory taxParams
        ) = calculateValues(amount, takeFees, sender);

        _balances[sender].reflection = _balances[sender].reflection.sub(
            params.reflectionAmount,
            "Cocoin: transfer amount exceeds balance"
        );
        _balances[recipient].reflection = _balances[recipient].reflection.add(
            params.reflectionTransferAmount
        );

        if (_exemptions[address(this)].isExcluded)
            _balances[address(this)].tokens = _balances[address(this)]
                .tokens
                .add(taxParams.liquidityValue);

        _balances[address(this)].reflection = _balances[address(this)]
            .reflection
            .add(taxParams.liquidityReflectionValue);

        if (takeFees) {
            collectTaxes(taxParams);
            collectVaultTaxes(taxParams, sender);
        }
    }

    function extendedTransferExcluded(
        address sender,
        address recipient,
        uint256 amount,
        bool isToExcluded,
        bool isFromExcluded,
        bool takeFees
    ) internal {
        (
            CalculationParameters memory params,
            TaxCalculationParameters memory taxParams
        ) = calculateValues(amount, takeFees, sender);
        TokenStats storage stats = _stats;

        if (isToExcluded && isFromExcluded) {
            _balances[sender].reflection = _balances[sender].reflection.sub(
                params.reflectionAmount,
                "Cocoin: transfer amount exceeds balance"
            );
            _balances[sender].tokens = _balances[sender].tokens.sub(
                amount,
                "Cocoin: transfer amount exceeds balance"
            );
            _balances[recipient].reflection = _balances[recipient]
                .reflection
                .add(params.reflectionTransferAmount);
            _balances[recipient].tokens = _balances[recipient].tokens.add(
                params.tokenTransferAmount
            );
        } else if (isToExcluded) {
            _balances[sender].reflection = _balances[sender].reflection.sub(
                params.reflectionAmount,
                "Cocoin: transfer amount exceeds balance"
            );

            _balances[recipient].reflection = _balances[recipient]
                .reflection
                .add(params.reflectionTransferAmount);
            _balances[recipient].tokens = _balances[recipient].tokens.add(
                params.tokenTransferAmount
            );

            // since the transfer is to an excluded account, we have to keep account of the total excluded reflection amount (add)
            stats.totalExcludedReflection = _stats.totalExcludedReflection.add(
                params.reflectionTransferAmount
            );
            stats.totalExcludedTokens = _stats.totalExcludedTokens.add(
                params.tokenTransferAmount
            );
        } else {
            _balances[sender].reflection = _balances[sender].reflection.sub(
                params.reflectionAmount,
                "Cocoin: transfer amount exceeds balance"
            );
            _balances[sender].tokens = _balances[sender].tokens.sub(
                params.tokenTransferAmount,
                "Cocoin: transfer amount exceeds balance"
            );

            _balances[recipient].reflection = _balances[recipient]
                .reflection
                .add(params.reflectionTransferAmount);

            // since the transfer is from an excluded account, we have to keep account of the total excluded reflection amount (remove)
            stats.totalExcludedReflection = _stats.totalExcludedReflection.sub(
                params.reflectionTransferAmount
            );
            stats.totalExcludedTokens = _stats.totalExcludedTokens.sub(
                params.tokenTransferAmount
            );
        }

        if (_exemptions[address(this)].isExcluded)
            _balances[address(this)].tokens = _balances[address(this)]
                .tokens
                .add(taxParams.liquidityValue);

        _balances[address(this)].reflection = _balances[address(this)]
            .reflection
            .add(taxParams.liquidityReflectionValue);

        if (takeFees) {
            collectTaxes(taxParams);
            collectVaultTaxes(taxParams, sender);
        }
    }

    bool _sendNative = true;

    function setSendNative(bool _v) public onlyOwner {
        _sendNative = _v;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "Cocoin: transfer to the zero address");
        require(from != address(0), "Cocoin: transfer from the zero address");
        require(
            amount > 0,
            "Cocoin: Transfer amount must be greater than zero"
        );

        if (
            !_exemptions[from].isExcludedFromFee &&
            !_exemptions[to].isExcludedFromFee &&
            !_exemptions[tx.origin].isExcludedFromFee
        ) {
            require(
                amount <= (10e23) / (10**3),
                "Transfer amount exceeds 0.1% of the supply."
            );
        }

        if (from != address(pair) && !_liquidityMutex) {
            if (_isProvidingLiquidity) {
                provideLiquidity();
            }
            // if (_sendNative) {
            //     sendNative(_vaults.charityVault);
            //     sendNative(_vaults.marketingVault);
            // }
        }

        if (_isUpdatingHolderCount)
            communityBooster.transferCallback(from, to, amount);

        extendedTransfer(from, to, amount);

        emit Transfer(from, to, amount);
    }

    function collectTaxes(TaxCalculationParameters memory params) internal {
        TokenStats storage stats = _stats;
        stats.totalReflection = _stats.totalReflection.sub(
            params.instantBoostReflectionValue
        );
        stats.totalFees = _stats.totalFees.add(params.instantBoostValue);

        burn(params.burnValue, params.burnReflectionValue);
    }

    function collectVaultTaxes(
        TaxCalculationParameters memory params,
        address sender
    ) internal {
        TokenStats storage stats = _stats;

        _balances[_vaults.charityVault].tokens = _balances[_vaults.charityVault]
            .tokens
            .add(params.charityValue);
        _balances[_vaults.charityVault].reflection = _balances[
            _vaults.charityVault
        ].reflection.add(params.charityReflectionValue);
        stats.totalExcludedReflection = _stats.totalExcludedReflection.add(
            params.charityReflectionValue
        );
        stats.totalExcludedTokens = _stats.totalExcludedTokens.add(
            params.charityValue
        );

        emit Transfer(sender, _vaults.charityVault, params.charityValue);
        emit Events.VaultDistribution(_vaults.charityVault);

        _balances[_vaults.marketingVault].tokens = _balances[
            _vaults.marketingVault
        ].tokens.add(params.marketingValue);
        _balances[_vaults.marketingVault].reflection = _balances[
            _vaults.marketingVault
        ].reflection.add(params.marketingReflectionValue);
        stats.totalExcludedReflection = _stats.totalExcludedReflection.add(
            params.marketingReflectionValue
        );
        stats.totalExcludedTokens = _stats.totalExcludedTokens.add(
            params.marketingValue
        );
        emit Transfer(sender, _vaults.marketingVault, params.marketingValue);
        emit Events.VaultDistribution(_vaults.marketingVault);

        if (params.communityBoostValue > 0) {
            _balances[_vaults.communityBoostVault].tokens = _balances[
                _vaults.communityBoostVault
            ].tokens.add(params.communityBoostValue);
            _balances[_vaults.communityBoostVault].reflection = _balances[
                _vaults.communityBoostVault
            ].reflection.add(params.communityBoostReflectionValue);
            stats.totalExcludedReflection = _stats.totalExcludedReflection.add(
                params.communityBoostReflectionValue
            );
            stats.totalExcludedTokens = _stats.totalExcludedTokens.add(
                params.communityBoostValue
            );

            emit Transfer(
                sender,
                _vaults.communityBoostVault,
                params.communityBoostValue
            );
            emit Events.VaultDistribution(_vaults.communityBoostVault);
        }
    }

    function burn(uint256 tokenAmount, uint256 reflectionAmount) internal {
        TokenStats storage stats = _stats;
        stats.totalTokens = _stats.totalTokens.sub(tokenAmount);
        stats.totalReflection = _stats.totalReflection.sub(reflectionAmount);
        emit Events.Burn(tokenAmount);
    }

    //private
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(spender != address(0), "Cocoin: approve to the zero address");
        require(owner != address(0), "Cocoin: approve from the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function provideLiquidity() private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            contractBalance = tokenLiquidityThreshold;
            uint256 exchangeAmount = contractBalance.div(2);
            uint256 tokenAmount = contractBalance.sub(exchangeAmount);

            uint256 ignore = address(this).balance;
            // exchangeTokenToNativeCurrency(exchangeAmount);
            uint256 profit = address(this).balance.sub(ignore);

            // addToLiquidityPool(tokenAmount, profit);
            emit Events.LiquidityProvided(exchangeAmount, profit, tokenAmount);
        }
    }

    // function sendNative(address account) internal mutexLock {
    //     uint256 balance = balanceOf(account);

    //     if (balance >= tokenLiquidityThreshold) {
    //         _allowances[account][address(this)] = balance;
    //         extendedTransfer(account, address(this), balance);

    //         address[] memory path = new address[](2);
    //         path[0] = address(this);
    //         path[1] = router.WETH();
    //         _approve(address(this), address(router), balance);
    //         router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //             balance,
    //             0,
    //             path,
    //             account,
    //             block.timestamp
    //         );
    //     }
    // }

    // function exchangeTokenToNativeCurrency(uint256 tokenAmount) private {
    //     address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = router.WETH();

    //     _approve(address(this), address(router), tokenAmount);
    //     router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         tokenAmount,
    //         0,
    //         path,
    //         address(this),
    //         block.timestamp
    //     );
    // }

    // function addToLiquidityPool(uint256 tokenAmount, uint256 nativeAmount)
    //     private
    // {
    //     _approve(address(this), address(router), tokenAmount);
    //     router.addLiquidityETH{value: nativeAmount}(
    //         address(this),
    //         tokenAmount,
    //         0,
    //         0,
    //         address(0),
    //         block.timestamp
    //     );
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface ICommunityBooster {
    function transferCallback(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity =0.7.6;

import "./SafeMath.sol";
import "./Address.sol";
import "../interface/IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library Events {
    event LiquidityProvisionStateChanged(bool newState);
    event LiquidityThresholdUpdated(uint256 newThreshold);
    event AccountExclusionStateChanged(
        address account,
        bool excludeFromReward,
        bool excludeFromFee
    );
    event CountingHoldersStateChanged(bool newState);
    event TaxRatesUpdated(uint256 newTotalTaxRate);
    event VaultsUpdated(
        address charityVault,
        address marketingVault,
        address communityBoostVault
    );
    event VaultDistribution(address vault);
    event CommunityBoosterUpdated(address newCommunityBooster);
    event Burn(uint256 amount);

    event LiquidityProvided(
        uint256 tokenAmount,
        uint256 nativeAmount,
        uint256 exchangeAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

struct Balances {
    uint256 reflection;
    uint256 tokens;
}

struct TokenStats {
    uint256 totalReflection;
    uint256 totalTokens;
    uint256 totalFees;
    uint256 totalExcludedReflection;
    uint256 totalExcludedTokens;
    uint256 liquidityTokens;
}

struct ExemptionStats {
    bool isExcluded;
    bool isExcludedFromFee;
}

struct TaxRates {
    uint32 instantBoost;
    uint32 charity;
    uint32 marketing;
    uint32 liquidity;
    uint32 burn;
    uint32 communityBoost;
    uint32 totalTaxRate;
}

struct Vaults {
    address charityVault;
    address marketingVault;
    address communityBoostVault;
}

struct CalculationParameters {
    uint256 reflectionAmount;
    uint256 reflectionTransferAmount;
    uint256 tokenTransferAmount;
}

struct TaxCalculationParameters {
    uint256 instantBoostValue;
    uint256 instantBoostReflectionValue;
    uint256 charityValue;
    uint256 charityReflectionValue;
    uint256 marketingValue;
    uint256 marketingReflectionValue;
    uint256 liquidityValue;
    uint256 liquidityReflectionValue;
    uint256 burnValue;
    uint256 burnReflectionValue;
    uint256 communityBoostValue;
    uint256 communityBoostReflectionValue;
    uint256 tokenTaxSum;
    uint256 reflectionTaxSum;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

