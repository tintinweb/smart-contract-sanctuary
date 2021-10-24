// SPDX-License-Identifier: X11
pragma solidity ^0.8.9;

import "./ThirdParty.sol";

contract TTT is Context, IERC20, Ownable {
    using Address for address;

    struct ContractRates {
        uint16 combinedBuyRate;
        uint16 reflectionBuyRate;
        uint16 luckyShotBuyRate;
        uint16 combinedSellRate;
        uint16 reflectionSellRate;
        uint16 luckyShotSellRate;
        uint16 combinedSendRate;
        uint16 antiWhaleRate;
    }

    struct IsExcluded {
        bool fromFee;
        bool fromReward;
        bool forVendor;
    }

    struct LuckyShot {
        bool enabled;
        uint16 chanceToWin;
        uint64 minimumSpendAmount;
        uint128 minimumPoolThreshold;
        address previousWinner;
        uint256 previousWinAmount;
        uint256 previousWinTime;
        uint256 pool;
        uint256 lastRoll;
        uint256 rolls;
    }

    struct Reflections {
        uint256 totalSupply;
        uint256 inCirculation;
        uint256 reflectionFeesEarned;
    }

    modifier LockSwap() {
        _lockSwap = true;
        _;
        _lockSwap = false;
    }

    bool private _lockSwap;

    ContractRates private _contractRates;

    uint128 private constant _MAX = ~uint128(0);
    uint128 private _tokenSupply = 10**9 * 10**9;

    address private _pancakePair;
    address private immutable _burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public charityAddress =
        payable(0x327DA8EC0c636284561501123450d740C37C2933);
    address payable public marketingAddress =
        payable(0x7F2558be955EbD29Bd07F1cbFA9d18f1619bE879);
    address private _projectLayer2;

    uint256 private _tokensForInitialSupport;

    mapping(address => IsExcluded) private _isExcluded;
    mapping(address => uint256) private _tokenBalance;
    mapping(address => uint256) private _reflectionBalance;
    mapping(address => mapping(address => uint256)) private _allowances;

    Reflections private _reflections;
    IPancakeRouter02 private _pancakeRouter;
    LuckyShot private _luckyShot;

    event TokensReflected(uint256 tokensReflected);
    event SendToWallet(string wallet, address walletAddress, uint256 bnbForLP);
    event AddLiquidity(uint256 tokensIn, uint256 bnbIn, address path);
    event SwapTokensForBNB(uint128 amountIn, uint128 amountOut);
    event SetRates(
        uint16 combinedBuyRate,
        uint16 reflectionBuyRate,
        uint16 luckyShotBuyRate,
        uint16 combinedSellRate,
        uint16 reflectionSellRate,
        uint16 luckyShotSellRate,
        uint16 combinedSendRate,
        uint16 antiWhaleRate
    );
    event SetRates(uint16 antiWhalerate);
    event LuckyShotWon(
        address indexed winner,
        uint256 indexed blockTime,
        uint256 amount
    );

    constructor() {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            // 0x10ED43C718714eb63d5aA57B78B54704E256024E // (mainnet)
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 // (testnet router)
        );
        _pancakeRouter = pancakeRouter;
        address pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());
        _pancakePair = pancakePair;

        __approveAllowance(address(this), address(pancakeRouter), ~uint256(0));

        _isExcluded[marketingAddress].fromFee = true;
        _isExcluded[owner()].fromFee = true;
        _isExcluded[address(this)].fromFee = true;

        _isExcluded[_burnAddress].fromReward = true;
        _isExcluded[pancakePair].fromReward = true;
        _isExcluded[marketingAddress].fromReward = true;
        _isExcluded[address(this)].fromReward = true;

        uint128 initialSupportTokens = (_tokenSupply * 15000) / 100000;
        _tokensForInitialSupport = initialSupportTokens;

        _tokenBalance[address(this)] = initialSupportTokens; // 15% of initial supply
        _tokenBalance[marketingAddress] = _tokenSupply - initialSupportTokens;

        _projectLayer2 = address(this);

        emit Transfer(address(0), address(this), _tokenBalance[address(this)]);
        emit Transfer(
            address(0),
            marketingAddress,
            _tokenBalance[marketingAddress]
        );
    }

    receive() external payable {}

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        __verify(_msgSender(), to);
        __transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][_msgSender()];

        __transfer(from, to, amount);

        if (currentAllowance < ~uint256(0)) {
            __approveAllowance(
                from,
                _msgSender(),
                _allowances[from][_msgSender()] -= amount
            );
        }

        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        __approveAllowance(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        __approveAllowance(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] += addedValue
        );

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        if (subtractedValue > _allowances[_msgSender()][spender]) {
            subtractedValue = _allowances[_msgSender()][spender]; // Zero's out the allowance
        }

        __approveAllowance(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] -= subtractedValue
        );
        return true;
    }

    /// Only Owner methods
    /**
     * Can only be in 1 fee list
     * @param listIndex 0 = 0% fee list; 1 = 3% vendor list
     */
    function _addToFeeList(uint8 listIndex, address account)
        external
        onlyOwner
    {
        require(listIndex <= 1, "Index too high");

        if (listIndex == 0) {
            _isExcluded[account].fromFee = true;
            _isExcluded[account].forVendor = false;
        } else if (listIndex == 1) {
            _isExcluded[account].forVendor = true;
            _isExcluded[account].fromFee = false;
        }
    }

    /**
     * Include address back in a transactions fees
     */
    function _removeFromFeeLists(address account) external onlyOwner {
        _isExcluded[account].fromFee = false;
        _isExcluded[account].forVendor = false;
    }

    function _addToRewards(address account) external onlyOwner {
        require(_isExcluded[account].fromReward, "Account is already included");

        uint256 tokenBalance = _tokenBalance[account];

        if (tokenBalance > 0) {
            _reflectionBalance[account] = tokenBalance * __getReflectionRate();

            _reflections.inCirculation += _reflectionBalance[account];
            _reflections.totalSupply += tokenBalance;

            _tokenBalance[account] = 0;
        }
        _isExcluded[account].fromReward = false;
    }

    function _removeFromRewards(address account) external onlyOwner {
        require(
            !_isExcluded[account].fromReward,
            "Account is already excluded"
        );

        uint256 reflectionBalance = _reflectionBalance[account];

        if (reflectionBalance > 0) {
            _tokenBalance[account] = reflectionBalance / __getReflectionRate();

            unchecked {
                _reflections.inCirculation -= reflectionBalance;
                _reflections.totalSupply -= _tokenBalance[account];
            }

            _reflectionBalance[account] = 0;
        }
        _isExcluded[account].fromReward = true;
    }

    function _setContractRates(
        uint16 combinedBuyRate,
        uint16 reflectionBuyRate,
        uint16 luckyShotBuyRate,
        uint16 combinedSellRate,
        uint16 reflectionSellRate,
        uint16 luckyShotSellRate,
        uint16 combinedSendRate,
        uint16 antiWhaleRate
    ) external onlyOwner {
        ContractRates storage contractRates = _contractRates;

        require(
            combinedBuyRate <= 15000 && combinedSellRate <= 15000,
            "Combined Sell/Buy Fee Rate must be equal to or lower than 15% (15000)"
        );
        require(
            combinedSendRate <= 10000,
            "Send Fee Rate must be equal to or lower than 10% (10000)"
        );
        require(
            reflectionBuyRate <= 5000 &&
                luckyShotBuyRate <= 5000 &&
                reflectionSellRate <= 5000 &&
                luckyShotSellRate <= 5000,
            "Reflection/LuckyShot Pool Fee Rate must be equal to or lower than 6% (6000)"
        );

        contractRates.combinedBuyRate = combinedBuyRate;
        contractRates.reflectionBuyRate = reflectionBuyRate;
        contractRates.luckyShotBuyRate = luckyShotBuyRate;

        contractRates.combinedSellRate = combinedSellRate;
        contractRates.reflectionSellRate = reflectionSellRate;
        contractRates.luckyShotSellRate = luckyShotSellRate;

        contractRates.combinedSendRate = combinedSendRate;

        contractRates.antiWhaleRate = antiWhaleRate;

        emit SetRates(
            combinedBuyRate,
            reflectionBuyRate,
            luckyShotBuyRate,
            combinedSellRate,
            reflectionSellRate,
            luckyShotSellRate,
            combinedSendRate,
            antiWhaleRate
        );
    }

    /// Same as setting _setContractRates(7, 0)
    function _turnOffAntiWhale() external onlyOwner {
        _contractRates.antiWhaleRate = 0;

        emit SetRates(0);
    }

    function _setCharityAddress(address newAddress) external onlyOwner {
        charityAddress = payable(newAddress);
    }

    function _setMarketingAddress(address newAddress) external onlyOwner {
        marketingAddress = payable(newAddress);
    }

    function _setProjectLayer2Address(address layer2Address)
        external
        onlyOwner
    {
        require(layer2Address.isContract(), "Address must be a contract");

        _isExcluded[layer2Address].fromReward = true;
        _isExcluded[layer2Address].fromFee = true;
        _projectLayer2 = layer2Address;
    }

    /// Configures default rates
    function _setsDefaultRates() external onlyOwner {
        _contractRates.combinedBuyRate = 9000;
        _contractRates.reflectionBuyRate = 2000;
        _contractRates.luckyShotBuyRate = 1000;
        _contractRates.combinedSellRate = 12000;
        _contractRates.reflectionSellRate = 3000;
        _contractRates.luckyShotSellRate = 1000;
        _contractRates.combinedSendRate = 6000;
        _contractRates.antiWhaleRate = 2000;
    }

    /**
     * Will sell given amount of tokens to be used by `useContractBNB`
     */
    function _spendAvailableFunds(uint256 amount) external onlyOwner {
        if (!_lockSwap) {
            uint256 tokensMinusInitialSupport;
            unchecked {
                tokensMinusInitialSupport =
                    _tokenBalance[address(this)] -
                    _tokensForInitialSupport -
                    _luckyShot.pool;
            }

            require(
                tokensMinusInitialSupport >= amount &&
                    _tokenBalance[address(this)] >= amount,
                "Not enough tokens allowed for swapping"
            );

            __swapTokens(amount);
        }
    }

    /**
     * Uses given rates to determine where BNB from the contract is going
     * RATES should be simple small versions totaling to 100 or less. (ex: 25 = 25%).
     *
     * Rates do not need to equal 100 or all be used here are some examples:
     *
     * useContractBNB(30, 30, 30, 5, <random avaiable BNB amount>);
     * This will leave 5% BNB inside the contract.
     *
     * useContractBNB(0, 0, 75, 0, <random avaiable BNB amount>);
     * This buyback using 75% of the BNB supply, 25% remains
     */
    function _useContractBNB(
        uint128 charityRate,
        uint128 marketingRate,
        uint128 buybackRate,
        uint128 liquidityRate,
        uint256 amount
    ) external onlyOwner {
        if (!_lockSwap) {
            require(
                address(this).balance >= amount,
                "Not enough BNB in the contract"
            );
            require(
                charityRate + marketingRate + buybackRate + liquidityRate <=
                    100,
                "Total must be less than 100%"
            );

            bool success;

            if (charityRate > 0) {
                uint256 charityBNB = (amount * (charityRate * 1000)) / 100000;

                (success, ) = charityAddress.call{value: charityBNB}(
                    new bytes(0)
                );

                if (success)
                    emit SendToWallet("Charity", charityAddress, charityBNB);
            }

            if (marketingRate > 0) {
                uint256 marketingBNB = (amount * (marketingRate * 1000)) /
                    100000;

                (success, ) = marketingAddress.call{value: marketingBNB}(
                    new bytes(0)
                );

                if (success)
                    emit SendToWallet(
                        "Marketing",
                        marketingAddress,
                        marketingBNB
                    );
            }

            if (buybackRate > 0) {
                __buybackAndBurn(buybackRate, amount);
            }

            if (liquidityRate > 0) {
                uint256 amountAvailable;
                uint256 tokensForInitialSupport = _tokensForInitialSupport;
                uint256 liquidtyFee = (amount * (liquidityRate * 1000)) /
                    100000;

                if (tokensForInitialSupport >= liquidtyFee) {
                    amountAvailable = tokensForInitialSupport;
                    _tokensForInitialSupport -= liquidtyFee;
                } else {
                    unchecked {
                        amountAvailable =
                            _tokenBalance[address(this)] -
                            tokensForInitialSupport -
                            _luckyShot.pool;
                    }
                }

                if (amountAvailable > 0)
                    __addLiquidity(amountAvailable, liquidtyFee);
            }
        }
    }

    /// Burn tokens from the initial support stream(0) or extra tokens in contract(1)
    function burnTokens(uint8 index, uint64 amount) external onlyOwner {
        require(index <= 1, "Index must be 0 or 1");
        uint256 tokensMinusInitialSupport;

        unchecked {
            tokensMinusInitialSupport =
                _tokenBalance[address(this)] -
                _tokensForInitialSupport -
                _luckyShot.pool;
        }

        if (index == 0) {
            require(
                _tokenBalance[address(this)] >= amount &&
                    _tokensForInitialSupport >= amount,
                "Balance must be greater than amount"
            );

            __burn(amount);
            _tokensForInitialSupport -= amount;
        } else if (tokensMinusInitialSupport >= amount) {
            __burn(amount);
        }
    }

    /**
     * Setup Lucky Shot variables, must turn fees to 0 or POOL will still get tokens.
     *
     * @param chance Chance BUYER has to win, the higher the chance the easier to win
     * @param enabled Enable or disable the luckyShot functionality
     * @param minimumSpendAmount Amount of tokens needed to be spend by BUYER for CHANCE to win.
     * @param minimumTokensAccumulated Minimum number of tokens accumulated in the POOL before the luckyShot can be triggered
     */
    function luckyShotConfig(
        bool enabled,
        uint16 chance,
        uint64 minimumSpendAmount,
        uint128 minimumTokensAccumulated
    ) external onlyOwner {
        require(chance <= 65535, "Chance must be less than max settable");

        _luckyShot.enabled = enabled;
        _luckyShot.chanceToWin = chance;
        _luckyShot.minimumSpendAmount = minimumSpendAmount;
        _luckyShot.minimumPoolThreshold = minimumTokensAccumulated;
    }

    function pancakePairAddress(address newPair) external onlyOwner {
        _pancakePair = newPair;
    }

    function pancakeRouterAddress(address newRouter) external onlyOwner {
        /// If using a new version it may not be compatible
        /// we will force it to use the V2 interface since that is what this contract is using.
        _pancakeRouter = IPancakeRouter02(newRouter);
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        if (_isExcluded[account].fromReward) return _tokenBalance[account];
        return _reflectionBalance[account] / __getReflectionRate();
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account].fromReward;
    }

    function getFeeStatus(address account)
        external
        view
        returns (string memory)
    {
        string memory feesExcludedFrom;

        if (_isExcluded[account].fromFee) {
            feesExcludedFrom = "Excluded from All Fees";
        } else if (_isExcluded[account].forVendor) {
            feesExcludedFrom = "Has Vendor Fee";
        }

        return feesExcludedFrom;
    }

    function burnAddress() external view returns (address) {
        return _burnAddress;
    }

    function circulatingSupply() external view returns (uint256) {
        return _tokenSupply - _tokenBalance[_burnAddress];
    }

    function getContractRates() external view returns (ContractRates memory) {
        return
            ContractRates(
                _contractRates.combinedBuyRate,
                _contractRates.reflectionBuyRate,
                _contractRates.luckyShotBuyRate,
                _contractRates.combinedSellRate,
                _contractRates.reflectionSellRate,
                _contractRates.luckyShotSellRate,
                _contractRates.combinedSendRate,
                _contractRates.antiWhaleRate
            );
    }

    function getLuckyShot() external view returns (LuckyShot memory) {
        return
            LuckyShot(
                _luckyShot.enabled,
                _luckyShot.chanceToWin,
                _luckyShot.minimumSpendAmount,
                _luckyShot.minimumPoolThreshold,
                _luckyShot.previousWinner,
                _luckyShot.previousWinAmount,
                _luckyShot.previousWinTime,
                _luckyShot.pool,
                _luckyShot.lastRoll,
                _luckyShot.rolls
            );
    }

    function getLayer2Address() external view returns (address) {
        return _projectLayer2;
    }

    function getPancakePair() external view returns (address) {
        return _pancakePair;
    }

    function getPancakeRouter() external view returns (address) {
        return address(_pancakeRouter);
    }

    function getTokenAmountFromReflection(uint256 amount)
        external
        view
        returns (uint256)
    {
        return amount / __getReflectionRate();
    }

    function getReflectionAmountFromToken(uint256 amount)
        external
        view
        returns (uint256 reflectedAmount)
    {
        reflectedAmount = amount * __getReflectionRate();
    }

    function initialSupportFunds() external view returns (uint256) {
        return _tokensForInitialSupport;
    }

    // Conveniently displays actual token pool minus its decimal places
    function luckyShotTokens() external view returns (uint256) {
        return _luckyShot.pool / 10**9;
    }

    function projectFundsAvailable() external view returns (uint256) {
        return
            _tokenBalance[address(this)] -
            _tokensForInitialSupport -
            _luckyShot.pool;
    }

    function totalReflectionsEarned() external view returns (uint256) {
        return _reflections.reflectionFeesEarned;
    }

    function totalSupply() external view override returns (uint256) {
        return _tokenSupply;
    }

    function name() external pure returns (string memory) {
        return "The Token";
    }

    function symbol() external pure returns (string memory) {
        return "TTT";
    }

    function decimals() external pure returns (uint256) {
        return 9;
    }

    function __approveAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        __verify(owner, spender);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function __transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 reflectionRate = __getReflectionRate();
        require(
            _reflectionBalance[from] / reflectionRate >= amount ||
                _tokenBalance[from] >= amount,
            "Balance must be greater than amount"
        );
        address tokenWallet = _projectLayer2;
        uint256 reflectionFee;
        uint256 luckyShotFee;
        uint256 tokensForSelling;
        IsExcluded memory isExcludedFrom = _isExcluded[from];
        IsExcluded memory isExcludedTo = _isExcluded[to];

        if (!(isExcludedFrom.fromFee || isExcludedTo.fromFee)) {
            (
                tokensForSelling,
                reflectionFee,
                luckyShotFee
            ) = __splitAndDetermineFees(
                from,
                to,
                amount,
                [isExcludedFrom, isExcludedTo]
            );
        }

        __transferAndReflect(
            from,
            to,
            amount,
            tokensForSelling + reflectionFee + luckyShotFee,
            reflectionFee,
            reflectionRate,
            [isExcludedFrom, isExcludedTo]
        );

        /// Add Lucky Shot fee, if Buy will give chance to win
        /// BUYS Only, given a chance to win if spending above minimumSpendAmount
        if (
            _luckyShot.enabled &&
            from == _pancakePair &&
            amount >= _luckyShot.minimumSpendAmount
        ) __handleLuckyShotRoll(isExcludedTo.fromReward, to);

        if (luckyShotFee > 0) _luckyShot.pool += luckyShotFee;

        /// Take Fees
        if (tokensForSelling > 0) {
            _tokenBalance[tokenWallet] += tokensForSelling;
            emit Transfer(from, tokenWallet, tokensForSelling);
        }
    }

    function __transferAndReflect(
        address from,
        address to,
        uint256 amount,
        uint256 tokenFees,
        uint256 reflectionFee,
        uint256 reflectionRate,
        IsExcluded[2] memory isExcluded
    ) private {
        uint256 antiWhaleRate = _contractRates.antiWhaleRate;
        bool antiWhaleCheck = antiWhaleRate > 0 && // Anti-whale Rate
            to != _pancakePair &&
            to != _burnAddress &&
            to != address(this);
        uint256 amountMinusFees = amount - tokenFees;
        Reflections memory reflections = _reflections;

        /// Take total amount from sender
        if (!isExcluded[0].fromReward) {
            _reflectionBalance[from] -= (amount * reflectionRate);

            if (isExcluded[1].fromReward) {
                unchecked {
                    reflections.inCirculation -= ((amountMinusFees +
                        reflectionFee) * reflectionRate);
                    reflections.totalSupply -= amountMinusFees + reflectionFee;
                }
            }
        } else {
            _tokenBalance[from] -= amount;

            if (!isExcluded[1].fromReward) {
                reflections.inCirculation += ((amountMinusFees +
                    reflectionFee) * reflectionRate);
                reflections.totalSupply += amountMinusFees + reflectionFee;
            }
        }

        /// Give amount minus fees to receiver
        if (!isExcluded[1].fromReward) {
            _reflectionBalance[to] += (amountMinusFees * reflectionRate);

            if (antiWhaleCheck) {
                require(
                    _reflectionBalance[to] / reflectionRate <=
                        ((_tokenSupply - _tokenBalance[_burnAddress]) *
                            antiWhaleRate) /
                            100000,
                    "Receiver Reflection balance exceeds holder limit"
                );
            }
        } else {
            _tokenBalance[to] += amountMinusFees;

            if (antiWhaleCheck) {
                require(
                    _tokenBalance[to] <=
                        ((_tokenSupply - _tokenBalance[_burnAddress]) *
                            antiWhaleRate) /
                            100000,
                    "Receiver Token balance exceeds holder limit"
                );
            }
        }

        emit Transfer(from, to, amount - tokenFees);

        uint256 reflectionFeeWithRate = reflectionFee * reflectionRate;
        if (reflectionFeeWithRate > 0) {
            if (reflections.inCirculation >= reflectionFeeWithRate)
                reflections.inCirculation -= reflectionFeeWithRate;

            reflections.reflectionFeesEarned += reflectionFee;
            emit TokensReflected(reflectionFee);
        }

        _reflections = reflections;
    }

    function __handleLuckyShotRoll(bool isExcludedFromRewardCheck, address to)
        private
    {
        address winner;
        uint256 timestamp = block.timestamp;
        LuckyShot memory luckyShot = _luckyShot;
        uint256 luckyShotRewardsCollected;
        uint256 poolAmount;
        uint256 previousWinAmount;
        uint256 previousWinTime;

        if (luckyShot.pool >= luckyShot.minimumPoolThreshold) {
            // Generates a random number between 1 and 1000
            luckyShot.lastRoll = __roll(timestamp);
            luckyShot.rolls++;

            if (luckyShot.lastRoll <= luckyShot.chanceToWin)
                luckyShotRewardsCollected = luckyShot.pool;
        }



        if (luckyShotRewardsCollected > 0) {
            if (!isExcludedFromRewardCheck) {
                _reflectionBalance[to] += (luckyShotRewardsCollected *
                    __getReflectionRate());

                _reflections.inCirculation += (luckyShotRewardsCollected *
                    __getReflectionRate());
                _reflections.totalSupply += luckyShotRewardsCollected;
            } else {
                _tokenBalance[to] += luckyShotRewardsCollected;
            }

            emit Transfer(address(this), to, luckyShotRewardsCollected);
            emit LuckyShotWon(to, timestamp, luckyShotRewardsCollected);

          poolAmount = 0;
          winner = to;
          previousWinAmount = luckyShotRewardsCollected;
          previousWinTime = timestamp;
        } else {
          poolAmount = luckyShot.pool + 1 - 1;
          winner = luckyShot.previousWinner;
          previousWinAmount = luckyShot.previousWinAmount + 1 - 1;
          previousWinTime = luckyShot.previousWinTime + 1 - 1;
        }

        luckyShot.pool = poolAmount;
        luckyShot.previousWinner = winner;
        luckyShot.previousWinAmount = previousWinAmount;
        luckyShot.previousWinTime = previousWinTime;

        _luckyShot = luckyShot;
    }

    function __roll(uint256 timestamp)
        private
        view
        returns (uint256 randomNumber)
    {
        randomNumber = uint256(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        timestamp,
                        _luckyShot.lastRoll
                    )
                )
            ) % 1000
        );

        randomNumber += 1;
    }

    function __swapTokens(uint256 amount) private LockSwap {
        uint256 initialBnb = address(this).balance;

        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        // make the swap
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        if (address(this).balance > initialBnb) {
            emit SwapTokensForBNB(
                uint128(amount),
                uint128(address(this).balance - initialBnb)
            );
        }
    }

    function __buybackAndBurn(uint128 buybackRate, uint256 amount)
        private
        LockSwap
    {
        uint256 buybackBNB = (amount * (buybackRate * 1000)) / 100000;

        if (address(this).balance >= buybackBNB) {
            // generate the Pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = _pancakeRouter.WETH();
            path[1] = address(this);

            // make the swap
            _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: buybackBNB
            }(
                0, // accept any amount of Tokens
                path,
                _burnAddress,
                block.timestamp
            );
        }
    }

    function __addLiquidity(uint256 tokensAvailable, uint256 bnbAmount)
        private
        LockSwap
    {
        (uint128 tokenA, uint128 tokenB) = __getReserves();
        uint256 tokenQuote = uint256(
            _pancakeRouter.quote(bnbAmount, tokenB, tokenA)
        );

        if (tokensAvailable < tokenQuote) {
            uint256 bnbQuote = uint256(
                _pancakeRouter.quote(tokensAvailable, tokenA, tokenB)
            );

            if (address(this).balance >= bnbQuote) {
                bnbAmount = bnbQuote;
                tokenQuote = tokensAvailable;
            }
        }

        if (tokensAvailable >= tokenQuote) {
            _pancakeRouter.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenQuote,
                0,
                0,
                address(this),
                block.timestamp
            );

            emit AddLiquidity(tokenQuote, bnbAmount, _pancakePair);
        }
    }

    function __burn(uint64 amount) private {
        if (_tokenBalance[address(this)] >= amount) {
            _tokenBalance[address(this)] -= amount;
            _tokenBalance[_burnAddress] += amount;

            emit Transfer(address(this), _burnAddress, amount);
        }
    }

    function __getReserves()
        private
        view
        returns (uint128 reserveA, uint128 reserveB)
    {
        address tokenA = address(this);
        (address token0, ) = sortTokens(tokenA, _pancakeRouter.WETH());
        (uint128 reserve0, uint128 reserve1, ) = IPancakePair(_pancakePair)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function __getReflectionRate() private view returns (uint256) {
        if (
            _reflections.inCirculation > 0 &&
            _reflections.inCirculation >= _reflections.totalSupply
        ) {
            return _reflections.inCirculation / _reflections.totalSupply;
        } else {
            return (_MAX - (_MAX % _tokenSupply)) / _tokenSupply;
        }
    }

    function __splitAndDetermineFees(
        address from,
        address to,
        uint256 amount,
        IsExcluded[2] memory isExcluded
    )
        private
        view
        returns (
            uint256 tokensForSellFee,
            uint256 reflectionFee,
            uint256 luckyShotFee
        )
    {
        uint32 denominator = 100000;
        (
            uint256 tokensForSellRate,
            uint256 reflectionRate,
            uint256 luckyShotRate
        ) = __getRates(from, to, isExcluded);

        if (tokensForSellRate > 0)
            tokensForSellFee = (amount * tokensForSellRate) / denominator;

        if (reflectionRate > 0)
            reflectionFee = (amount * reflectionRate) / denominator;

        if (luckyShotRate > 0)
            luckyShotFee = (amount * luckyShotRate) / denominator;
    }

    function __getRates(
        address from,
        address to,
        IsExcluded[2] memory isExcluded
    )
        private
        view
        returns (
            uint16 tokensForSellRate,
            uint16 reflectionRate,
            uint16 luckyShotRate
        )
    {
        ContractRates memory contractRates = _contractRates;

        if (isExcluded[0].forVendor || isExcluded[1].forVendor) {
            tokensForSellRate = 3000;
        } else {
            /// Buy
            if (from == _pancakePair) {
                tokensForSellRate = contractRates.combinedBuyRate;
                reflectionRate = contractRates.reflectionBuyRate;
                luckyShotRate = contractRates.luckyShotBuyRate;

                /// Sell
            } else if (to == _pancakePair) {
                tokensForSellRate = contractRates.combinedSellRate;
                reflectionRate = contractRates.reflectionSellRate;
                luckyShotRate = contractRates.luckyShotSellRate;
            } else {
                tokensForSellRate = contractRates.combinedSendRate;
            }
        }
    }

    function sortTokens(address tokenA, address tokenB)
        private
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function __verify(address from, address to) private pure {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
    }
}