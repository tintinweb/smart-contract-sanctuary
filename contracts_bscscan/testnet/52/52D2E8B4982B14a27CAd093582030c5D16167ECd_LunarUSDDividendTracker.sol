// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import 'Ownable.sol';
import 'IterableMapping.sol';
import 'DividendPayingToken.sol';
import 'ERC20TokenRecover.sol';
import 'ILunarUSDDividendTracker.sol';

contract LunarUSDDividendTracker is Ownable, DividendPayingToken, ERC20TokenRecover, ILunarUSDDividendTracker {
    using IterableMapping for IterableMapping.Map;

    address public parentToken;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public override lastProcessedIndex;

    mapping(address => bool) public override excludedFromDividends;

    mapping(address => uint256) public override lastClaimTimes;

    address public override deployer;

    uint256 public override claimWait;
    uint256 public override minimumTokenBalanceForDividends;

    /**
     * @dev Throws if called by any account other than the owner or deployer.
     */
    modifier onlyOwnerOrDeployer() {
        require(owner() == _msgSender() || deployer == _msgSender(), 'Ownable: caller is not the owner or deployer');
        _;
    }

    constructor(address dividendToken, address _parentToken)
        DividendPayingToken('LunarUSD Dividend Tracker', 'LUNARDT', dividendToken)
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 10 * (10**9) * (10**18); //must hold 10 billion + tokens

        deployer = _msgSender();
        parentToken = _parentToken;
        transferOwnership(_parentToken);
    }

    //== BEP20 owner function ==
    function getOwner() public view override returns (address) {
        return owner();
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        override(ERC20TokenRecover, IERC20TokenRecover)
        onlyOwner
    {
        require(tokenAddress != dividendToken, 'LunarUSDDividendTracker: Cannot retrieve USDT');
        super.recoverERC20(tokenAddress, tokenAmount);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, 'LunarUSDDividendTracker: No transfers allowed');
    }

    function withdrawDividend() public pure override(DividendPayingToken, IDividendPayingTokenInterface) {
        require(
            false,
            "LunarUSDDividendTracker: Disabled. Use the 'claim' function on the main LunarUSD contract."
        );
    }

    function excludeFromDividends(address account) external override onlyOwnerOrDeployer {
        require(!excludedFromDividends[account], 'LunarUSDDividendTracker: Account already excluded');
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account) external override onlyOwnerOrDeployer {
        require(excludedFromDividends[account], 'LunarUSDDividendTracker: Account not excluded');

        excludedFromDividends[account] = false;
        _setBalance(account, 0);

        emit IncludedInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external override onlyOwnerOrDeployer {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            'LunarUSDDividendTracker: claimWait must be updated to between 1 and 24 hours'
        );
        require(newClaimWait != claimWait, 'LunarUSDDividendTracker: Cannot update claimWait to same value');
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinTokenBalance(uint256 minTokens) external override onlyOwnerOrDeployer {
        minimumTokenBalanceForDividends = minTokens * (10**18);
    }

    function getLastProcessedIndex() external view override returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view override returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public
        view
        override
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
                    ? tokenHoldersMap.keys.length - lastProcessedIndex
                    : 0;
                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
    }

    function getAccountAtIndex(uint256 index)
        external
        view
        override
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) return (address(0), -1, -1, 0, 0, 0, 0, 0);
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return (block.timestamp - lastClaimTime) >= claimWait;
    }

    function ensureBalance(bool _process) external override {
        ensureBalanceForUser(payable(_msgSender()), _process);
    }

    function ensureBalanceForUsers(address payable[] memory accounts, bool _process)
        external
        override
        onlyOwnerOrDeployer
    {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            ensureBalanceForUser(accounts[idx], _process);
        }
    }

    function ensureBalanceForUser(address payable account, bool _process) public override onlyOwnerOrDeployer {
        uint256 balance = IERC20(parentToken).balanceOf(account);

        if (excludedFromDividends[account]) return;

        if (balance != balanceOf(account)) {
            if (balance >= minimumTokenBalanceForDividends) {
                _setBalance(account, balance);
                tokenHoldersMap.set(account, balance);
            } else {
                _setBalance(account, 0);
                tokenHoldersMap.remove(account);
            }
        }

        if (_process) processAccount(account, false);
    }

    function setBalance(address payable account, uint256 newBalance) external override onlyOwner {
        if (excludedFromDividends[account]) return;

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas)
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) gasUsed = gasUsed + (gasLeft - newGasLeft);
            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        override
        onlyOwnerOrDeployer
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}