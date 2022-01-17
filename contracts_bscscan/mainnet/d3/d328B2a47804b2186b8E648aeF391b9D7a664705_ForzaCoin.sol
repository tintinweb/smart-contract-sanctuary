// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './interfaces/IBEP20.sol';
import './extensions/TokensLiquify.sol';
import './extensions/DevWallet.sol';
import './extensions/MarketingWallet.sol';
import './extensions/FeeManager.sol';
import './extensions/AntiWhale.sol';
import './extensions/RTValues.sol';
import './extensions/TokenRecover.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract ForzaCoin is
    IBEP20,
    Ownable,
    TokensLiquify,
    DevWallet,
    MarketingWallet,
    FeeManager,
    AntiWhale,
    RTValues,
    TokenRecover
{
    using EnumerableSet for EnumerableSet.AddressSet;

    struct AccountStatus {
        bool feeExcluded;
        bool accountLimitExcluded;
        bool transferLimitExcluded;
        bool blacklistedBot;
        uint256 swapCooldown;
    }

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _excludedFromReward;
    mapping(address => AccountStatus) private statuses;

    uint256 private _tTotal;
    uint256 private _rTotal;

    string public constant override name = 'FORZA Coin';
    string public constant override symbol = 'FORZA';
    uint8 public constant override decimals = 18;

    uint256 public tFeeTotal;
    uint256 public tBurnTotal;
    uint256 public tLiquidityTotal;

    uint256 public launchTime;

    event RewardExclusion(address indexed account, bool isExcluded);
    event FeeExclusion(address indexed account, bool isExcluded);
    event AccountLimitExclusion(address indexed account, bool isExcluded);
    event TransferLimitExclusion(address indexed account, bool isExcluded);

    constructor(
        address owner,
        address router,
        address devWalletAddress,
        address marketingWalletAddress,
        uint256 totalTokenSupply,
        uint256 givenAccountLimitPercentage,
        uint256 givenAccountLimitPercentageFactor,
        uint256 givenTransferLimitPercentage,
        uint256 givenTransferLimitPercentageFactor,
        bool testMode
    ) {
        // Set initial settings
        _tTotal = totalTokenSupply * 1e18;
        _rTotal = (type(uint256).max - (type(uint256).max % _tTotal));
        accountLimitPercentage.percentage = givenAccountLimitPercentage;
        accountLimitPercentage.percentageFactor = givenAccountLimitPercentageFactor;
        singleTransferLimitPercentage.percentage = givenTransferLimitPercentage;
        singleTransferLimitPercentage.percentageFactor = givenTransferLimitPercentageFactor;
        swapCooldownDuration = 1 minutes;
        minAmountToLiquify = 10000 * (10**uint256(decimals));

        // Transfer ownership to given address
        transferOwnership(owner);

        // Set router and create swap pair
        if (!testMode) {
            _setRouterAddress(router);
        }

        // Set dev wallett
        _setDevWalletAddress(devWalletAddress);

        // Set marketing wallett
        _setMarketingWalletAddress(marketingWalletAddress);

        // Exclude the owner and this contract from transfer restrictions
        statuses[owner] = AccountStatus(true, true, true, false, 0);
        statuses[address(this)] = AccountStatus(true, true, true, false, 0);

        // Exclude swap pair and swap router from account limit
        statuses[swapPair].accountLimitExcluded = true;
        statuses[address(swapRouter)].accountLimitExcluded = true;

        // Assign initial supply to the owner
        _rOwned[owner] = _rTotal;
        emit Transfer(address(0), owner, _tTotal);
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf(account);
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function getAccountStatus(address account)
        external
        view
        returns (
            bool,
            bool,
            bool,
            bool,
            bool
        )
    {
        return (
            _isExcludedFromReward(account),
            statuses[account].feeExcluded,
            statuses[account].accountLimitExcluded,
            statuses[account].transferLimitExcluded,
            statuses[account].blacklistedBot
        );
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function reflect(uint256 tAmount) external {
        address account = msg.sender;
        require(!_isExcludedFromReward(account), 'Reflect from excluded address');
        require(_balanceOf(account) >= tAmount, 'Reflect amount exceeds sender balance');

        uint256 currentRate = _getRate();
        _rOwned[account] = _rOwned[account] - (tAmount * currentRate);
        _reflectFeeAndBurn(tAmount, 0, currentRate);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _approve(account, msg.sender, _allowances[account][msg.sender] - amount);
        _burn(account, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= _tTotal, 'Amount must be less than supply');
        uint256 currentRate = _getRate();
        if (!deductTransferFee) {
            return tAmount * currentRate;
        } else {
            (uint256 rTransferAmount, , , , , , ) = _getValues(tAmount, currentRate);
            return rTransferAmount;
        }
    }

    // Owner functions
    function launch() external onlyOwner {
        launchTime = block.timestamp;
        isLiquifyingEnabled = true;
    }

    function setRewardExclusion(address account, bool isExcluded) external onlyOwner {
        if (!isExcluded && _excludedFromReward.remove(account)) {
            _rOwned[account] = _tOwned[account] * _getRate();
            _tOwned[account] = 0;
            emit RewardExclusion(account, false);
        } else if (isExcluded) {
            require(account != address(this), 'Cannot exclude coin contract');
            if (!_excludedFromReward.contains(account)) {
                if (_rOwned[account] > 0) {
                    _tOwned[account] = _tokenFromReflection(_rOwned[account]);
                }
                _excludedFromReward.add(account);
                emit RewardExclusion(account, true);
            }
        }
    }

    function setFeeExclusion(address account, bool isExcluded) external onlyOwner {
        statuses[account].feeExcluded = isExcluded;
        emit FeeExclusion(account, isExcluded);
    }

    function setAccountLimitExclusion(address account, bool isExcluded) external onlyOwner {
        statuses[account].accountLimitExcluded = isExcluded;
        emit AccountLimitExclusion(account, isExcluded);
    }

    function setTransferLimitExclusion(address account, bool isExcluded) external onlyOwner {
        statuses[account].transferLimitExcluded = isExcluded;
        emit TransferLimitExclusion(account, isExcluded);
    }

    function setBotsBlacklisting(address[] memory bots, bool isBlacklisted) external onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            statuses[bots[i]].blacklistedBot = isBlacklisted;
        }
    }

    function _isExcludedFromReward(address account) private view returns (bool) {
        return _excludedFromReward.contains(account);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'Approve from the zero address');
        require(spender != address(0), 'Approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _balanceOf(address account) private view returns (uint256) {
        if (_isExcludedFromReward(account)) return _tOwned[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function _burn(address account, uint256 tAmount) private {
        require(account != address(0), 'Burn from the zero address');
        require(_balanceOf(account) >= tAmount, 'Burn amount exceeds balance');

        uint256 currentRate = _getRate();
        _rOwned[account] = _rOwned[account] - (tAmount * currentRate);
        if (_isExcludedFromReward(account)) {
            _tOwned[account] = _tOwned[account] - tAmount;
        }
        _reflectFeeAndBurn(0, tAmount, currentRate);
        emit Transfer(account, address(0), tAmount);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, 'Amount must be less than total reflections');
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), 'Transfer from the zero address');
        require(recipient != address(0), 'Transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');

        _blacklistFrontRunners(sender);

        _checkBotBlacklisting(sender, recipient);
        _checkTransferLimit(sender, amount);
        _checkAccountLimit(recipient, amount, _balanceOf(recipient));
        _checkSwapCooldown(sender, recipient);

        _tokenTransfer(sender, recipient, amount);

        _liquifyTokens(sender);
    }

    function _blacklistFrontRunners(address sender) private {
        if (launchTime == 0 || block.timestamp < launchTime + 5 seconds) {
            if (sender != swapPair && sender != address(swapRouter) && !statuses[sender].feeExcluded) {
                statuses[sender].blacklistedBot = true;
            }
        }
    }

    function _checkBotBlacklisting(address sender, address recipient) private view {
        require(!statuses[sender].blacklistedBot, 'Sender is blacklisted');
        require(!statuses[recipient].blacklistedBot, 'Recipient is blacklisted');
    }

    function _checkTransferLimit(address sender, uint256 amount) private view {
        if (!statuses[sender].transferLimitExcluded) {
            require(
                amount <= _getSingleTransferLimit(_totalSupply(), singleTransferLimitPercentage),
                'Transfer amount exceeds the limit'
            );
        }
    }

    function _checkAccountLimit(
        address recipient,
        uint256 amount,
        uint256 recipientBalance
    ) private view {
        if (!statuses[recipient].accountLimitExcluded) {
            require(
                recipientBalance + amount <= _getAccountLimit(_totalSupply(), accountLimitPercentage),
                'Recipient has reached account tokens limit'
            );
        }
    }

    function _checkSwapCooldown(address sender, address recipient) private {
        if (swapCooldownDuration > 0 && sender == swapPair && recipient != address(swapRouter)) {
            require(statuses[recipient].swapCooldown < block.timestamp, 'Swap is cooling down');
            statuses[recipient].swapCooldown = block.timestamp + swapCooldownDuration;
        }
    }

    function _liquifyTokens(address sender) private {
        uint256 amountToLiquify = _balanceOf(address(this));
        if (
            isLiquifyingEnabled && !_isInSwapAndLiquify() && sender != swapPair && amountToLiquify >= minAmountToLiquify
        ) {
            uint256 singleTransferLimit = _getSingleTransferLimit(_totalSupply(), singleTransferLimitPercentage);
            if (amountToLiquify > singleTransferLimit) {
                amountToLiquify = singleTransferLimit;
            }
            // approve router to transfer tokens to cover all possible scenarios
            _approve(address(this), address(swapRouter), amountToLiquify);
            _swapAndLiquify(amountToLiquify, owner());
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool disableFee = statuses[sender].feeExcluded || statuses[recipient].feeExcluded;

        if (_isExcludedFromReward(sender) && !_isExcludedFromReward(recipient)) {
            _transferFromExcluded(sender, recipient, amount, disableFee);
        } else if (!_isExcludedFromReward(sender) && _isExcludedFromReward(recipient)) {
            _transferToExcluded(sender, recipient, amount, disableFee);
        } else if (_isExcludedFromReward(sender) && _isExcludedFromReward(recipient)) {
            _transferBothExcluded(sender, recipient, amount, disableFee);
        } else {
            _transferStandard(sender, recipient, amount, disableFee);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn,
            uint256 tDevFee,
            uint256 tMarketingFee
        ) = _getValues(tAmount, currentRate, disableFee);
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _takeDevFee(tDevFee, currentRate);
        _takeMarketingFee(tMarketingFee, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity, tDevFee, tMarketingFee);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn,
            uint256 tDevFee,
            uint256 tMarketingFee
        ) = _getValues(tAmount, currentRate, disableFee);
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _takeDevFee(tDevFee, currentRate);
        _takeMarketingFee(tMarketingFee, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity, tDevFee, tMarketingFee);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn,
            uint256 tDevFee,
            uint256 tMarketingFee
        ) = _getValues(tAmount, currentRate, disableFee);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _takeDevFee(tDevFee, currentRate);
        _takeMarketingFee(tMarketingFee, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity, tDevFee, tMarketingFee);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn,
            uint256 tDevFee,
            uint256 tMarketingFee
        ) = _getValues(tAmount, currentRate, disableFee);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _takeDevFee(tDevFee, currentRate);
        _takeMarketingFee(tMarketingFee, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity, tDevFee, tMarketingFee);
    }

    function _emitTransfers(
        address sender,
        address recipient,
        uint256 tTransferAmount,
        uint256 tBurn,
        uint256 tLiquidity,
        uint256 tDevFee,
        uint256 tMarketingFee
    ) private {
        emit Transfer(sender, recipient, tTransferAmount);
        if (tBurn > 0) {
            emit Transfer(sender, address(0), tBurn);
        }
        if (tLiquidity > 0) {
            emit Transfer(sender, address(this), tLiquidity);
        }
        if (tDevFee > 0) {
            emit Transfer(sender, devWalletAddress, tDevFee);
        }
        if (tMarketingFee > 0) {
            emit Transfer(sender, marketingWalletAddress, tMarketingFee);
        }
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 currentRate) private {
        _rOwned[address(this)] = _rOwned[address(this)] + (tLiquidity * currentRate);
        if (_isExcludedFromReward(address(this))) {
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        }
        tLiquidityTotal = tLiquidityTotal + tLiquidity;
    }

    function _reflectFeeAndBurn(
        uint256 tFee,
        uint256 tBurn,
        uint256 currentRate
    ) private {
        _rTotal = _rTotal - (tFee * currentRate) - (tBurn * currentRate);
        tBurnTotal = tBurnTotal + tBurn;
        tFeeTotal = tFeeTotal + tFee;
        _tTotal = _tTotal - tBurn;
    }

    function _getValues(uint256 tAmount, uint256 currentRate)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _getValues(tAmount, currentRate, false);
    }

    function _getValues(
        uint256 tAmount,
        uint256 currentRate,
        bool disableFee
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        TValues memory tValues = _getTValues(tAmount, disableFee);

        uint256 rTransferAmount = tAmount * currentRate;
        //these need to be split in different functions to avoid stack too deep errors
        rTransferAmount = _getRTransferAmountFirst(rTransferAmount, tValues.tFee, tValues.tLiquidity, currentRate);
        rTransferAmount = _getRTransferAmountSecond(
            rTransferAmount,
            tValues.tBurn,
            tValues.tDevFee,
            tValues.tMarketingFee,
            currentRate
        );

        return (
            rTransferAmount,
            tValues.tTransferAmount,
            tValues.tFee,
            tValues.tLiquidity,
            tValues.tBurn,
            tValues.tDevFee,
            tValues.tMarketingFee
        );
    }

    function _getTValues(uint256 tAmount, bool disableFee) private view returns (TValues memory) {
        TValues memory tValues;

        if (disableFee) {
            tValues.tTransferAmount = tAmount;
            tValues.tFee = 0;
            tValues.tLiquidity = 0;
            tValues.tBurn = 0;
            tValues.tDevFee = 0;
            tValues.tMarketingFee = 0;
            return tValues;
        }

        uint256 tFee = (tAmount * tFeePercent) / 100;
        uint256 tLiquidity = (tAmount * tLiquidityPercent) / 100;
        uint256 tBurn = (tAmount * tBurnPercent) / 100;
        uint256 tDevFee = (tAmount * tDevFeePercent) / 100;
        uint256 tMarketingFee = (tAmount * tMarketingFeePercent) / 100;
        uint256 tTransferAmount = tAmount - tFee - tLiquidity - tBurn - tDevFee - tMarketingFee;

        tValues.tTransferAmount = tTransferAmount;
        tValues.tFee = tFee;
        tValues.tLiquidity = tLiquidity;
        tValues.tBurn = tBurn;
        tValues.tDevFee = tDevFee;
        tValues.tMarketingFee = tMarketingFee;

        return tValues;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromReward.length(); i++) {
            address excluded = _excludedFromReward.at(i);
            if (_rOwned[excluded] > rSupply || _tOwned[excluded] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[excluded];
            tSupply = tSupply - _tOwned[excluded];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _totalSupply() private view returns (uint256) {
        return _tTotal;
    }

    function getTotalFeePercentage() public view returns (uint256) {
        return tFeePercent + tLiquidityPercent + tBurnPercent + tDevFeePercent + tMarketingFeePercent;
    }

    //START dev wallet
    function setDevWalletAddress(address devWallet) external onlyOwner {
        _setDevWalletAddress(devWallet);
    }

    function _setDevWalletAddress(address devWallet) internal {
        delete statuses[devWalletAddress];
        statuses[devWallet] = AccountStatus(true, true, true, false, 0);
        _setDevWallet(devWallet);
    }

    function _takeDevFee(uint256 tDevFee, uint256 currentRate) private {
        uint256 rDevFee = tDevFee * currentRate;
        _rOwned[devWalletAddress] = _rOwned[devWalletAddress] + rDevFee;
        if (_isExcludedFromReward(devWalletAddress)) {
            _tOwned[devWalletAddress] = _tOwned[devWalletAddress] + tDevFee;
        }
    }

    //END dev wallet

    //START marketing wallet
    function setMarketingWalletAddress(address marketingWallet) external onlyOwner {
        _setMarketingWalletAddress(marketingWallet);
    }

    function _setMarketingWalletAddress(address marketingWallet) internal {
        delete statuses[marketingWalletAddress];
        statuses[marketingWallet] = AccountStatus(true, true, true, false, 0);
        _setMarketingWallet(marketingWallet);
    }

    function _takeMarketingFee(uint256 tMarketingFee, uint256 currentRate) private {
        uint256 rMarketingFee = tMarketingFee * currentRate;
        _rOwned[marketingWalletAddress] = _rOwned[marketingWalletAddress] + rMarketingFee;
        if (_isExcludedFromReward(marketingWalletAddress)) {
            _tOwned[marketingWalletAddress] = _tOwned[marketingWalletAddress] + tMarketingFee;
        }
    }

    //END marketing wallet

    //START anti whale
    function getAccountLimit() external view returns (uint256) {
        return _getAccountLimit(_totalSupply(), accountLimitPercentage);
    }

    function getSingleTransferLimit() external view returns (uint256) {
        return _getSingleTransferLimit(_totalSupply(), singleTransferLimitPercentage);
    }
    //END anti whale
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.9;

import '../interfaces/IPancakeFactory.sol';
import '../interfaces/IPancakeRouter02.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TokensLiquify is Ownable {
    bool private isInSwapAndLiquify;

    IPancakeRouter02 public swapRouter;
    address public swapPair;

    bool public isLiquifyingEnabled;
    uint256 public minAmountToLiquify;

    event TokensSwapped(uint256 tokensSwapped, uint256 bnbReceived);
    event TokensLiquified(uint256 tokensLiquified, uint256 bnbLiquified, uint256 lpMinted);

    receive() external payable {}

    function withdrawFunds(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function switchLiquifying() external onlyOwner {
        isLiquifyingEnabled = !isLiquifyingEnabled;
    }

    function setMinAmountToLiquify(uint256 amount) external onlyOwner {
        minAmountToLiquify = amount;
    }

    function setRouterAddress(address routerAddress_) external onlyOwner {
        _setRouterAddress(routerAddress_);
    }

    function _isInSwapAndLiquify() internal view returns (bool) {
        return isInSwapAndLiquify;
    }

    function _setRouterAddress(address routerAddress_) internal {
        IPancakeRouter02 _swapRouter = IPancakeRouter02(routerAddress_);
        swapPair = IPancakeFactory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        swapRouter = _swapRouter;
    }

    function _swapAndLiquify(uint256 tokenAmount, address lpReceiver) internal {
        isInSwapAndLiquify = true;
        uint256 firstHalf = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - firstHalf;
        uint256 bnbReceived = _swapTokensForBNB(firstHalf);
        _addLiquidity(otherHalf, bnbReceived, lpReceiver);
        isInSwapAndLiquify = false;
    }

    function _swapTokensForBNB(uint256 tokenAmount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        uint256 balance = address(this).balance;
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
        uint256 newBalance = address(this).balance;
        uint256 bnbReceived = newBalance - balance;
        emit TokensSwapped(tokenAmount, bnbReceived);
        return bnbReceived;
    }

    function _addLiquidity(
        uint256 tokenAmount,
        uint256 bnbAmount,
        address lpReceiver
    ) private {
        (uint256 amountToken, uint256 amountBNB, uint256 liquidity) = swapRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiver,
            block.timestamp
        );
        emit TokensLiquified(amountToken, amountBNB, liquidity);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

contract DevWallet is Ownable {
    address public devWalletAddress;

    function _setDevWallet(address devWallet) internal {
        devWalletAddress = devWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

contract MarketingWallet is Ownable {
    address public marketingWalletAddress;

    function _setMarketingWallet(address marketingWallet) internal {
        marketingWalletAddress = marketingWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

contract FeeManager is Ownable {
    struct Fees {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tDev;
        uint256 tMarketing;
    }

    uint256 public constant MAX_REFLECTION_FEE_PERCENT = 4;
    uint256 public constant MAX_BURN_FEE_PERCENT = 1;
    uint256 public constant MAX_LIQUIDITY_FEE_PERCENT = 4;
    uint256 public constant MAX_DEV_FEE_PERCENT = 1;
    uint256 public constant MAX_MARKETING_FEE_PERCENT = 2;

    uint256 public tFeePercent = MAX_REFLECTION_FEE_PERCENT;
    uint256 public tBurnPercent = MAX_BURN_FEE_PERCENT;
    uint256 public tLiquidityPercent = MAX_LIQUIDITY_FEE_PERCENT;
    uint256 public tDevFeePercent = MAX_DEV_FEE_PERCENT;
    uint256 public tMarketingFeePercent = MAX_MARKETING_FEE_PERCENT;

    function setFees(
        uint256 reflectionFeePercent,
        uint256 burnFeePercent,
        uint256 liquidityFeePercent,
        uint256 devFeePercent,
        uint256 marketingFeePercent
    ) external onlyOwner {
        if (reflectionFeePercent <= MAX_REFLECTION_FEE_PERCENT) {
            tFeePercent = reflectionFeePercent;
        } else {
            tFeePercent = MAX_REFLECTION_FEE_PERCENT;
        }

        if (burnFeePercent <= MAX_BURN_FEE_PERCENT) {
            tBurnPercent = burnFeePercent;
        } else {
            tBurnPercent = MAX_BURN_FEE_PERCENT;
        }

        if (liquidityFeePercent <= MAX_LIQUIDITY_FEE_PERCENT) {
            tLiquidityPercent = liquidityFeePercent;
        } else {
            tLiquidityPercent = MAX_LIQUIDITY_FEE_PERCENT;
        }

        if (devFeePercent <= MAX_DEV_FEE_PERCENT) {
            tDevFeePercent = devFeePercent;
        } else {
            tDevFeePercent = MAX_DEV_FEE_PERCENT;
        }

        if (marketingFeePercent <= MAX_MARKETING_FEE_PERCENT) {
            tMarketingFeePercent = marketingFeePercent;
        } else {
            tMarketingFeePercent = MAX_MARKETING_FEE_PERCENT;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

contract AntiWhale is Ownable {
    //this is used to be able to have decimal percentages to target whatever supply we want
    struct Percentage {
        uint256 percentage;
        uint256 percentageFactor;
    }

    Percentage public accountLimitPercentage;
    Percentage public singleTransferLimitPercentage;
    uint256 public swapCooldownDuration;

    function _getAccountLimit(uint256 currentSupply, Percentage memory _accountLimitPercentage)
        internal
        pure
        returns (uint256)
    {
        uint256 accountLimit = (currentSupply * _accountLimitPercentage.percentage) /
            _accountLimitPercentage.percentageFactor;
        if (accountLimit > currentSupply) {
            return currentSupply;
        }
        return accountLimit;
    }

    function _getSingleTransferLimit(uint256 currentSupply, Percentage memory _singleTransferLimitPercentage)
        internal
        pure
        returns (uint256)
    {
        uint256 singleTransferLimit = (currentSupply * _singleTransferLimitPercentage.percentage) /
            _singleTransferLimitPercentage.percentageFactor;
        if (singleTransferLimit > currentSupply) {
            return currentSupply;
        }
        return singleTransferLimit;
    }

    function setAccountLimitPercentage(uint256 _accountLimitPercentage, uint256 _accountLimitPercentageFactor)
        external
        onlyOwner
    {
        _checkPercentageValues(_accountLimitPercentage, _accountLimitPercentageFactor);
        accountLimitPercentage.percentage = _accountLimitPercentage;
        accountLimitPercentage.percentageFactor = _accountLimitPercentageFactor;
    }

    function setSingleTransferLimitPercentage(
        uint256 _singleTransferLimitPercentage,
        uint256 _singleTransferLimitPercentageFactor
    ) external onlyOwner {
        _checkPercentageValues(_singleTransferLimitPercentage, _singleTransferLimitPercentageFactor);
        singleTransferLimitPercentage.percentage = _singleTransferLimitPercentage;
        singleTransferLimitPercentage.percentageFactor = _singleTransferLimitPercentageFactor;
    }

    function _checkPercentageValues(uint256 percentage, uint256 percentageFactor) private pure {
        require(percentage > 0, 'percentage must be greater than 0');
        require(percentageFactor > 0, 'percentageFactor must be greater than 0');
    }

    function setSwapCooldownDuration(uint256 _swapCooldownDuration) external onlyOwner {
        swapCooldownDuration = _swapCooldownDuration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract RTValues {
    struct Values {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tDev;
        uint256 tMarketing;
    }

    struct TValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tDevFee;
        uint256 tMarketingFee;
    }

    function _getRTransferAmountFirst(
        uint256 rAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    ) internal pure returns (uint256) {
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        return rAmount - rFee - rLiquidity;
    }

    function _getRTransferAmountSecond(
        uint256 rAmount,
        uint256 tBurn,
        uint256 tDevFee,
        uint256 tMarketingFee,
        uint256 currentRate
    ) internal pure returns (uint256) {
        uint256 rBurn = tBurn * currentRate;
        uint256 rDevFee = tDevFee * currentRate;
        uint256 rMarketingFee = tMarketingFee * currentRate;
        return rAmount - rBurn - rDevFee - rMarketingFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title TokenRecover
 * @dev Allow to recover any BEP20 sent into the contract for error
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverToken(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
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
library EnumerableSet {
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

// Source:
// https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol

pragma solidity ^0.8.9;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

// Source:
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol

pragma solidity ^0.8.9;

import './IPancakeRouter01.sol';

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

// Source:
// https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol

pragma solidity ^0.8.9;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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