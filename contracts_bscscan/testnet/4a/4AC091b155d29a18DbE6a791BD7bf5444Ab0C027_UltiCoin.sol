// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './extensions/TokensLiquify.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/*
 *    |  \  |  \|  \      |        \|      \       /      \           |  \
 *    | $$  | $$| $$       \$$$$$$$$ \$$$$$$      |  $$$$$$\  ______   \$$ _______
 *    | $$  | $$| $$         | $$     | $$        | $$   \$$ /      \ |  \|       \
 *    | $$  | $$| $$         | $$     | $$        | $$      |  $$$$$$\| $$| $$$$$$$\
 *    | $$  | $$| $$         | $$     | $$        | $$   __ | $$  | $$| $$| $$  | $$
 *    | $$__/ $$| $$_____    | $$    _| $$_       | $$__/  \| $$__/ $$| $$| $$  | $$
 *     \$$    $$| $$     \   | $$   |   $$ \       \$$    $$ \$$    $$| $$| $$  | $$
 *      \$$$$$$  \$$$$$$$$    \$$    \$$$$$$        \$$$$$$   \$$$$$$  \$$ \$$   \$$
 */

contract UltiCoin is IERC20, Ownable, TokensLiquify {
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

    uint256 private _tTotal = 250 * 1e9 * 1e18;
    uint256 private _rTotal = (type(uint256).max - (type(uint256).max % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tLiquidityTotal;

    uint256 private _tFeePercent = 2;
    uint256 private _tBurnPercent = 2;
    uint256 private _tLiquidityPercent = 2;

    string public constant name = 'ULTI Coin';
    string public constant symbol = 'ULTI';
    uint8 public constant decimals = 18;

    uint256 public accountLimit;
    uint256 public singleTransferLimit;
    uint256 public swapCooldownDuration;

    uint256 public launchTime;

    event RewardExclusion(address indexed account, bool isExcluded);
    event FeeExclusion(address indexed account, bool isExcluded);
    event AccountLimitExclusion(address indexed account, bool isExcluded);
    event TransferLimitExclusion(address indexed account, bool isExcluded);

    constructor(address owner, address router) {
        // Transfer ownership to given address
        transferOwnership(owner);

        // Set router and create swap pair
        _setRouterAddress(router);

        // Exclude the owner and this contract from transfer restrictions
        statuses[owner] = AccountStatus(true, true, true, false, 0);
        statuses[address(this)] = AccountStatus(true, true, true, false, 0);

        // Exclude swap pair and swap router from account limit
        statuses[swapPair].accountLimitExcluded = true;
        statuses[address(swapRouter)].accountLimitExcluded = true;

        // Set initial settings
        accountLimit = 200 * 10e6 * (10**uint256(decimals));
        singleTransferLimit = 10 * 10e6 * (10**uint256(decimals));
        swapCooldownDuration = 1 minutes;
        minAmountToLiquify = 5000 * (10**uint256(decimals));

        // Assign initial supply to the owner
        _rOwned[owner] = _rTotal;
        emit Transfer(address(0), owner, _tTotal);
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

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurned() external view returns (uint256) {
        return _tBurnTotal;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _excludedFromReward.contains(account);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return statuses[account].feeExcluded;
    }

    function isExcludedFromAccountLimit(address account) external view returns (bool) {
        return statuses[account].accountLimitExcluded;
    }

    function isExcludedFromTransferLimit(address account) external view returns (bool) {
        return statuses[account].transferLimitExcluded;
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

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, 'Transfer amount exceeds allowance');
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function reflect(uint256 tAmount) external {
        address account = msg.sender;
        require(!isExcludedFromReward(account), 'Reflect from excluded address');
        require(_balanceOf(account) >= tAmount, 'Reflect amount exceeds sender balance');

        uint256 currentRate = _getRate();
        _rOwned[account] = _rOwned[account] - (tAmount * currentRate);
        _reflectFeeAndBurn(tAmount, 0, currentRate);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, 'Burn amount exceeds allowance');
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, 'Decreased allowance below zero');
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= _tTotal, 'Amount must be less than supply');
        uint256 currentRate = _getRate();
        if (!deductTransferFee) {
            return tAmount * currentRate;
        } else {
            (uint256 rTransferAmount, , , , ) = _getValues(tAmount, currentRate);
            return rTransferAmount;
        }
    }

    // Owner functions

    function setTax(
        uint256 feePercent,
        uint256 burnPercent,
        uint256 liquidityPercent
    ) external onlyOwner {
        _tFeePercent = feePercent;
        _tBurnPercent = burnPercent;
        _tLiquidityPercent = liquidityPercent;
    }

    function setAccountLimit(uint256 amount) external onlyOwner {
        accountLimit = amount;
    }

    function setSingleTransferLimit(uint256 amount) external onlyOwner {
        singleTransferLimit = amount;
    }

    function setSwapCooldownDuration(uint256 duration) external onlyOwner {
        swapCooldownDuration = duration;
    }

    function launch() external onlyOwner {
        launchTime = block.timestamp;
        isLiquifyingEnabled = true;
    }

    function setRewardExclusion(address account, bool isExcluded) external onlyOwner {
        if (!isExcluded && _excludedFromReward.remove(account)) {
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
        if (isExcludedFromReward(account)) return _tOwned[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function _burn(address account, uint256 tAmount) private {
        require(account != address(0), 'Burn from the zero address');
        require(_balanceOf(account) >= tAmount, 'Burn amount exceeds balance');

        uint256 currentRate = _getRate();
        _rOwned[account] = _rOwned[account] - (tAmount * currentRate);
        if (isExcludedFromReward(account)) {
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
        _checkTransferLimit(sender, recipient, amount);
        _checkAccountLimit(recipient, amount, _balanceOf(recipient));
        _checkSwapCooldown(sender, recipient, swapPair, address(swapRouter));

        _liquifyTokens(sender);

        _tokenTransfer(sender, recipient, amount);
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

    function _checkTransferLimit(
        address sender,
        address recipient,
        uint256 amount
    ) private view {
        if (!statuses[sender].transferLimitExcluded && !statuses[recipient].transferLimitExcluded) {
            require(amount <= singleTransferLimit, 'Transfer amount exceeds the limit');
        }
    }

    function _checkAccountLimit(
        address recipient,
        uint256 amount,
        uint256 recipientBalance
    ) private view {
        if (!statuses[recipient].accountLimitExcluded) {
            require(recipientBalance + amount <= accountLimit, 'Recipient has reached account tokens limit');
        }
    }

    function _checkSwapCooldown(
        address sender,
        address recipient,
        address swapPair,
        address swapRouter
    ) private {
        if (swapCooldownDuration > 0 && sender == swapPair && recipient != swapRouter) {
            require(statuses[recipient].swapCooldown < block.timestamp, 'Swap is cooling down');
            statuses[recipient].swapCooldown = block.timestamp + swapCooldownDuration;
        }
    }

    function _liquifyTokens(address sender) private {
        uint256 amountToLiquify = _balanceOf(address(this));
        if (
            isLiquifyingEnabled && !_isInSwapAndLiquify() && sender != swapPair && amountToLiquify >= minAmountToLiquify
        ) {
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

        if (isExcludedFromReward(sender) && !isExcludedFromReward(recipient)) {
            _transferFromExcluded(sender, recipient, amount, disableFee);
        } else if (!isExcludedFromReward(sender) && isExcludedFromReward(recipient)) {
            _transferToExcluded(sender, recipient, amount, disableFee);
        } else if (!isExcludedFromReward(sender) && !isExcludedFromReward(recipient)) {
            _transferStandard(sender, recipient, amount, disableFee);
        } else if (isExcludedFromReward(sender) && isExcludedFromReward(recipient)) {
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
        (uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) =
            _getValues(tAmount, currentRate, disableFee);
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) =
            _getValues(tAmount, currentRate, disableFee);
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) =
            _getValues(tAmount, currentRate, disableFee);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool disableFee
    ) private {
        uint256 currentRate = _getRate();
        (uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) =
            _getValues(tAmount, currentRate, disableFee);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - (tAmount * currentRate);
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity, currentRate);
        _reflectFeeAndBurn(tFee, tBurn, currentRate);
        _emitTransfers(sender, recipient, tTransferAmount, tBurn, tLiquidity);
    }

    function _emitTransfers(
        address sender,
        address recipient,
        uint256 tTransferAmount,
        uint256 tBurn,
        uint256 tLiquidity
    ) private {
        emit Transfer(sender, recipient, tTransferAmount);
        if (tBurn > 0) {
            emit Transfer(sender, address(0), tBurn);
        }
        if (tLiquidity > 0) {
            emit Transfer(sender, address(this), tLiquidity);
        }
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 currentRate) private {
        _rOwned[address(this)] = _rOwned[address(this)] + (tLiquidity * currentRate);
        if (isExcludedFromReward(address(this))) {
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        }
    }

    function _reflectFeeAndBurn(
        uint256 tFee,
        uint256 tBurn,
        uint256 currentRate
    ) private {
        _rTotal = _rTotal - (tFee * currentRate) - (tBurn * currentRate);
        _tBurnTotal = _tBurnTotal + tBurn;
        _tFeeTotal = _tFeeTotal + tFee;
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
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(tAmount, disableFee);
        return (
            _getRTransferAmount(tAmount, tFee, tLiquidity, tBurn, currentRate),
            tTransferAmount,
            tFee,
            tLiquidity,
            tBurn
        );
    }

    function _getTValues(uint256 tAmount, bool disableFee)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (disableFee) {
            return (tAmount, 0, 0, 0);
        }

        uint256 tFee = (tAmount * _tFeePercent) / 100;
        uint256 tLiquidity = (tAmount * _tLiquidityPercent) / 100;
        uint256 tBurn = (tAmount * _tBurnPercent) / 100;
        uint256 tTransferAmount = tAmount - tFee - tLiquidity - tBurn;
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRTransferAmount(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBurn,
        uint256 currentRate
    ) private pure returns (uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rBurn = tBurn * currentRate;
        return rAmount - rFee - rLiquidity - rBurn;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TokensLiquify is Ownable {
    bool private isInSwapAndLiquify;

    bool public isLiquifyingEnabled;

    IUniswapV2Router02 public swapRouter;
    address public swapPair;

    uint256 public minAmountToLiquify;

    event TokensSwapped(uint256 tokensSwapped, uint256 ethReceived);
    event TokensLiquified(uint256 tokensLiquified, uint256 ethLiquified, uint256 lpMinted);

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
        IUniswapV2Router02 _swapRouter = IUniswapV2Router02(routerAddress_);
        swapPair = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        swapRouter = _swapRouter;
    }

    function _swapAndLiquify(uint256 tokenAmount, address lpReceiver) internal {
        isInSwapAndLiquify = true;
        uint256 firstHalf = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - firstHalf;
        uint256 ethReceived = _swapTokensForETH(firstHalf);
        _addLiquidity(otherHalf, ethReceived, lpReceiver);
        isInSwapAndLiquify = false;
    }

    function _swapTokensForETH(uint256 tokenAmount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        uint256 balance = address(this).balance;
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint256 newBalance = address(this).balance;
        uint256 ethReceived = newBalance - balance;
        emit TokensSwapped(tokenAmount, ethReceived);
        return ethReceived;
    }

    function _addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address lpReceiver
    ) private {
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) =
            swapRouter.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                lpReceiver,
                block.timestamp
            );
        emit TokensLiquified(amountToken, amountETH, liquidity);
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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

// Source:
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.8.6;

interface IUniswapV2Factory {
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
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.8.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

// Source:
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity ^0.8.6;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

