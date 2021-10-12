// SPDX-License-Identifier: X11

/*
     █████╗ ██████╗ ██████╗ ███████╗████████╗██╗████████╗███████╗
    ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██║╚══██╔══╝██╔════╝
    ███████║██████╔╝██████╔╝█████╗     ██║   ██║   ██║   █████╗
    ██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝     ██║   ██║   ██║   ██╔══╝
    ██║  ██║██║     ██║     ███████╗   ██║   ██║   ██║   ███████╗
    ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝   ╚═╝   ╚═╝   ╚═╝   ╚══════╝

    If you want to update to Project name and keep the cool "art" -- https://www.coolgenerator.com/ascii-text-generator
    ^ remove the comment with the link after

   Please check out our WhitePaper over at https://<ipfs-hosted-preferred|your-domain>
   to get an overview of our contract!

   Feel free to put any relevant PROJECT INFORMATION HERE
*/

pragma solidity ^0.8.9;

import "./ThirdParty.sol";

contract Appetite is Context, IERC20, Ownable {
    using Address for address;

    enum SellOperation {
        None,
        SellAndSend,
        Liquidity
    }

    struct IsExcluded {
        bool fromFee;
        bool fromReward;
        bool forVendor;
    }

    struct PrizePool {
        bool enabled;
        uint16 chanceToWin;
        uint64 previousWinTime;
        uint128 collectedPot;
        uint128 previousWinAmount;
        uint128 triggerThreshold;
        uint128 minimiumSpendAmount;
        address previousWinner;
        uint256 lastRoll;
        uint256 nonce;
    }

    bool private _lockSwap;

    bytes8 private _contractToggles;

    uint24 private constant _DENOMINATOR = 100000;
    uint128 private constant _MAX = ~uint128(0);
    uint128 private _tokenSupply = 10**9 * 10**9;
    uint128 private _reflectionTotal = (_MAX - (_MAX % _tokenSupply));
    uint128 private _reflectionFeesEarned;

    address private immutable _pancakePair;
    address public immutable _burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public charityAddress =
        payable(0xf54Bf63f4940dc775e55dAa4ca33e342E2A87551);
    address payable public marketingAddress =
        payable(0xF26d52Ba6F2A24C49220Aeb98c4a5b2ab28c715F);

    mapping(address => mapping(address => uint128)) private _allowances;
    mapping(address => uint128) private _tokenBalance;
    mapping(address => uint128) private _reflectionBalance;
    mapping(address => IsExcluded) private _isExcluded;
    bytes32[2] private _contractRates;

    IPancakeRouter02 private immutable _pancakeRouter;
    SellOperation private _sellOperation = SellOperation.None;
    PrizePool public _prizePool;
    uint64 private _tokensForInitialSupport;

    event TokensReflected(uint256 tokensReflected);
    event BuybackTokens(uint256 bnbIn);
    event SendToWallet(string wallet, address walletAddress, uint256 bnbForLP);
    event PriceImpact(uint256 priceImpact, uint128 tokensSold);
    event AddLiquidity(uint256 tokensIn, uint256 bnbIn, address path);
    event SwapTokensForBNB(uint128 amountIn, uint128 amountOut);
    event ContractFeatureToggled(uint8 index, uint8 value, bool enabled);
    event SetRate(uint8 index, uint8 subIndex, uint32 value);
    event TrackerUpdate(
        uint8 trackerIndex,
        uint128 oldValue,
        uint128 newValue,
        bool added
    );
    event PrizePoolWon(uint64 blockTime, address winner, uint128 amount);

    event Print(string name, uint256 value);

    modifier LockSwap() {
        _lockSwap = true;
        _;
        _lockSwap = false;
    }

    constructor() {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            // 0x10ED43C718714eb63d5aA57B78B54704E256024E // (mainnet)
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 // (testnet router)
        );
        address pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());
        _pancakeRouter = pancakeRouter;
        _pancakePair = pancakePair;

        approveAllowance(address(this), address(pancakeRouter), ~uint128(0));

        _isExcluded[marketingAddress].fromFee = true;
        _isExcluded[owner()].fromFee = true;

        _isExcluded[pancakePair].fromReward = true;
        _isExcluded[_burnAddress].fromReward = true;
        _isExcluded[marketingAddress].fromReward = true;
        _isExcluded[address(this)].fromReward = true;

        uint128 initialSupportTokens = (_tokenSupply * 15000) / _DENOMINATOR;
        _tokensForInitialSupport = uint64(initialSupportTokens);

        _tokenBalance[address(this)] = initialSupportTokens; // 15% of initial supply
        _tokenBalance[marketingAddress] = _tokenSupply - initialSupportTokens;

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
        _verify(_msgSender(), to);
        _transfer(_msgSender(), to, uint128(amount));
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][_msgSender()];

        _transfer(from, to, uint128(amount));

        if (currentAllowance < ~uint256(0)) {
            approveAllowance(
                from,
                _msgSender(),
                _allowances[from][_msgSender()] -= uint128(amount)
            );
        }

        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        approveAllowance(_msgSender(), spender, uint128(amount));
        return true;
    }

    function increaseAllowance(address spender, uint128 addedValue)
        external
        virtual
        returns (bool)
    {
        approveAllowance(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] += addedValue
        );

        return true;
    }

    function decreaseAllowance(address spender, uint128 subtractedValue)
        external
        virtual
        returns (bool)
    {
        if (subtractedValue > _allowances[_msgSender()][spender]) {
            subtractedValue = _allowances[_msgSender()][spender]; // Zero's out the allowance
        }

        approveAllowance(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] -= subtractedValue
        );
        return true;
    }

    function setCharityAddress(address newAddress) external onlyOwner {
        charityAddress = payable(newAddress);
    }

    function setMarketingAddress(address newAddress) external onlyOwner {
        marketingAddress = payable(newAddress);
    }

    /**
     * Low end rates used internally and capped at 6%
     *
     * 0: Buy Charity Fee Rate
     * 1: Buy Reflection Fee Rate
     * 2: Buy Marketing Fee Rate
     * 3: Buy PrizePool Fee rate
     * 4: Buy Support Stream Fee Rate
     * 5: Sell Charity Fee Rate
     * 6: Sell Reflection Fee Rate
     * 7: Sell Marketing Fee Rate
     * 8: Sell PrizePool Fee rate
     * 9: Sell Support Stream Fee Rate
     */
    function setRateIndexZero(uint8 index, uint16 value) external onlyOwner {
        require(index <= 9, "index too high");
        require(value <= 6000, "Must be lower or equal to 6% (6000)");
        bytes32[2] storage contractRates = _contractRates;

        contractRates[0] &= ~(bytes32(bytes2(~uint16(0))) >> (index * 16));
        contractRates[0] |= bytes32(bytes2(value)) >> (index * 16);

        emit SetRate(0, index, value);
    }

    /**
     * Index 0, 1 and 2, 3 are linked to match 100%
     *
     * 0: Support Stream Buyback/Burn Fee Rate (0-100)
     * 1: Support Stream LP Fee Rate (0-100)
     * 2: Burn rate for sell amount from initial Support
     * 3: Send Charity Fee Rate
     * 4: Send Reflection Fee Rate
     * 5: Anti Whale Max Rate
     */
    function setRateIndexOne(uint8 index, uint32 value) external onlyOwner {
        require(index <= 5, "index too high");
        if (index <= 1)
            require(value <= _DENOMINATOR, "Value for rate must be less than 100000 (100%)");

        if (index == 0 || index == 1) {
            if (index == 0) {
                _setRateIndexOne(0, value);
                _setRateIndexOne(1, _DENOMINATOR - value);
            } else {
                _setRateIndexOne(0, _DENOMINATOR - value);
                _setRateIndexOne(1, value);
            }
        } else {
            _setRateIndexOne(index, value);
        }
    }

    /**
     * Anti Whale: Max wallet holding limit enforced
     * 15% Support Burn: Burns tokens based on sell by user from contract
     * 15% Support LP: Uses tokens from contract to double the LP support
     * Sell Tokens: When disabled no tokens will be sold automatically
     * Send BNB: When disabled no tokens will be sent out automatically
     * Add Liquidity: When disabled no auto LP support
     * Buyback Tokens: When disabled will not buy back tokens to store for burns
     */
    function setToggle(uint8 index, bool value) external onlyOwner {
        index *= 8;
        uint8 currentValue = uint8(bytes1(_contractToggles << index));
        require(currentValue <= 1, "Feature Locked");
        uint8 newValue = value == true ? 1 : 0;

        _contractToggles &= ~(bytes8(bytes1(~uint8(0))) >> index);
        _contractToggles |= bytes8(bytes1(newValue)) >> index;

        emit ContractFeatureToggled(index, newValue, value);
    }

    function setLotteryStatus(bool enabled) external onlyOwner {
        _prizePool.enabled = enabled;
    }

    function setLotteryChance(uint16 chance) external onlyOwner {
        require(chance <= 65535, "Chance must be less than max settable");
        _prizePool.chanceToWin = chance;
    }

    function setLotteryThreshold(uint128 minimumPrizePot) external onlyOwner {
        _prizePool.triggerThreshold = minimumPrizePot;
    }

    function setLotteryMinimumSpend(uint128 minimumSpend) external onlyOwner {
        _prizePool.minimiumSpendAmount = minimumSpend;
    }

    /**
     * Locks the boolean forever
     */
    function lockToggle(uint8 index) external onlyOwner {
        index = index * 8;

        uint8 currentValue = uint8(bytes1(_contractToggles << index));
        require(currentValue <= 1, "Feature already locked");
        uint8 newValue = currentValue == 0 ? 2 : 3;

        _contractToggles &= ~(bytes8(bytes1(~uint8(0))) >> index);
        _contractToggles |= bytes8(bytes1(newValue)) >> index;

        emit ContractFeatureToggled(
            index,
            newValue,
            newValue == 3 ? true : false
        );
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account].fromReward, "Account is already included");
        _isExcluded[account].fromReward = false;

        _reflectionBalance[account] =
            _tokenBalance[account] *
            getReflectionRate();
        _reflectionTotal += _reflectionBalance[account];
        _tokenBalance[account] = 0;
    }

    function excludeFromReward(address account) external onlyOwner {
        require(
            !_isExcluded[account].fromReward,
            "Account is already excluded"
        );
        require(
            !_isExcluded[account].fromReward,
            "Account is already excluded"
        );

        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] =
                _reflectionBalance[account] /
                getReflectionRate();

            if (_reflectionTotal >= _reflectionBalance[account])
                _reflectionTotal -= _reflectionBalance[account];

            _reflectionBalance[account] = 0;
        }
        _isExcluded[account].fromReward = true;
    }

    /**
     * @param listIndex Must be 0 or 1. 0 = 0 fee list; 1 = 3% vendor list
     */
    function excludeFromFee(address account, uint8 listIndex)
        external
        onlyOwner
    {
        require(listIndex <= 1, "Index too high");

        if (listIndex == 0) {
            _isExcluded[account].fromFee = true;
        } else if (listIndex == 1) {
            _isExcluded[account].forVendor = true;
        }
    }

    /**
     * Include back in a fee list, use the same index used for excludeFromFee
     *
     * @param listIndex 0 = 0 fee list; 1 = 3% vendor list
     */
    function includeInFee(address account, uint8 listIndex) external onlyOwner {
        require(listIndex <= 1, "Index too high");

        if (listIndex == 0) {
            _isExcluded[account].fromFee = false;
        } else if (listIndex == 1) {
            _isExcluded[account].forVendor = false;
        }
    }

    /// Configures default rates and feature toggles
    function setDefaultValues() external onlyOwner {
        bytes32[2] storage contractRates = _contractRates;

        contractRates[0] &= ~bytes32(~uint256(0));
        contractRates[0] |=
            bytes32(bytes2(uint16(3000))) |
            (bytes32(bytes2(uint16(2000))) >> 16) |
            (bytes32(bytes2(uint16(3000))) >> 32) |
            (bytes32(bytes2(uint16(1000))) >> 48) |
            (bytes32(bytes2(uint16(3000))) >> 64) |
            (bytes32(bytes2(uint16(3000))) >> 80) |
            (bytes32(bytes2(uint16(3000))) >> 96) |
            (bytes32(bytes2(uint16(4000))) >> 112) |
            (bytes32(bytes2(uint16(1000))) >> 128) |
            (bytes32(bytes2(uint16(5000))) >> 144);

        contractRates[1] &= ~bytes32(~uint256(0));
        contractRates[1] |=
            bytes32(bytes4(uint32(60000))) |
            (bytes32(bytes4(uint32(40000))) >> 32) |
            (bytes32(bytes4(uint32(50000))) >> 64) |
            (bytes32(bytes4(uint32(3000))) >> 96) |
            (bytes32(bytes4(uint32(3000))) >> 128) |
            (bytes32(bytes4(uint32(2000))) >> 160);

        bytes3 contractToggles;
        uint8 bits = 8;
        contractToggles &= ~bytes3(~uint24(0));
        contractToggles |= bytes3(bytes1(uint8(1)));
        contractToggles |= bytes3(bytes1(uint8(1))) >> bits;
        contractToggles |= bytes3(bytes1(uint8(1))) >> (2 * bits);

        _contractToggles = contractToggles;
    }

    /**
     * Add or burn tokens from the initial support stream.
     * Burn tokens from any extra tokens found in the contract
     *
     * @param index 0 or 1 and only used for initialSupport set to 0 otherwise
     * @param initialSupport false will try to burn extra tokens
     * @param amount The amount of tokens trying to be burned
     *
     * Index values:
     * 0: Add amount to initial support stream (15% stream)
     * 1: Burn amount directly
     */
    function burnTokens(
        uint8 index,
        bool initialSupport,
        uint64 amount
    ) external LockSwap onlyOwner {
        uint64 tokensForSupport = _tokensForInitialSupport;

        if (initialSupport) {
            require(index <= 1, "Index must be 0 or 1");

            if (index == 0) {
                tokensForSupport += amount;
            } else {
                require(
                    _tokenBalance[address(this)] >= amount &&
                        tokensForSupport >= amount,
                    "Balance must be greater than amount"
                );

                _burn(amount);
                tokensForSupport -= amount;
            }
        } else {
            uint64 tokensMinusInitialSupport = uint64(
                _tokenBalance[address(this)]
            ) - tokensForSupport;

            require(
                _tokenBalance[address(this)] >= amount &&
                    tokensMinusInitialSupport >= amount,
                "Not enough unallocated tokens for burning"
            );

            _burn(amount);
            tokensForSupport -= uint64(amount);
        }

        _tokensForInitialSupport = tokensForSupport;
    }

    /**
     * Will sell given amount of tokens and split between fee paths
     * including injecting LP automatically so stored BNB is for buyback
     */
    function sellTokensSendAndInjectLP(
        uint8 charityRate,
        uint8 marketingRate,
        uint8 buybackRate,
        uint8 liquidityRate,
        uint64 amount
    ) external LockSwap onlyOwner {
        uint64 tokensMinusInitialSupport = uint64(
            _tokenBalance[address(this)]
        ) - _tokensForInitialSupport;

        require(
            _tokenBalance[address(this)] >= amount &&
                tokensMinusInitialSupport >= amount,
            "Not enough tokens allowed for swapping"
        );
        require(
            charityRate + marketingRate + buybackRate + liquidityRate <= 100,
            "Total for charity can not be greater than 100%"
        );

        bool success;
        uint128 bnbReceived = _sellTokensForBNB(amount);

        if (charityRate > 0) {
            uint128 charityBNB = (bnbReceived * charityRate) / 100;

            (success, ) = charityAddress.call{value: charityBNB}(new bytes(0));

            if (success) {
                emit SendToWallet("Charity", charityAddress, charityBNB);
            }
        }

        if (marketingRate > 0) {
            uint128 marketingBNB = (bnbReceived * marketingRate) / 100;

            (success, ) = marketingAddress.call{value: marketingBNB}(
                new bytes(0)
            );
            if (success)
                emit SendToWallet("Marketing", marketingAddress, marketingBNB);
        }

        if (buybackRate > 0) {
            (uint128 tokenA, uint128 tokenB) = _getReserves();
            uint128 bnbNeeded = uint128(
                _pancakeRouter.getAmountOut(
                    (bnbReceived * buybackRate) / 100,
                    tokenA,
                    tokenB
                )
            );

            _buyTokensAndBurn(bnbNeeded);
        }

        if (liquidityRate > 0) {
            _addLiquidity(
                tokensMinusInitialSupport,
                (bnbReceived * liquidityRate) / 100
            );
        }
    }

    /**
     * Index values:
     * 0: Split the amount and send to charity/marketing
     * 1: Buyback and burn
     * 2: Use amount to check for availble tokens and inject LP
     */
    function useContractBNB(uint8 index, uint128 amount)
        external
        LockSwap
        onlyOwner
    {
        require(index <= 2, "Index must be 0-2");

        require(
            address(this).balance >= amount,
            "Not enough BNB in the contract"
        );

        if (index == 0) {
            _sendBNB(amount / 2, amount / 2);
        } else if (index == 1) {
            _buyTokensAndBurn(amount);
        } else if (
            index == 2 &&
            _tokenBalance[address(this)] > _tokensForInitialSupport
        ) {
            _addLiquidity(
                _tokenBalance[address(this)] - _tokensForInitialSupport,
                amount
            );
        }
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
        return _reflectionBalance[account] / getReflectionRate();
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account].fromReward;
    }

    function isExcludedFromFee(address account)
        external
        view
        returns (string memory)
    {
        string memory feesExcludedFrom;

        if (_isExcluded[account].fromFee) feesExcludedFrom = "Send/Receive";

        if (_isExcluded[account].forVendor) {
            feesExcludedFrom = string(
                abi.encodePacked(feesExcludedFrom, " Vendor")
            );
        }

        return feesExcludedFrom;
    }

    function totalSupply() external view override returns (uint256) {
        return _tokenSupply;
    }

    /**
     * Buy Charity Fee Rate
     * Buy Reflection Fee Rate
     * Buy Marketing Fee Rate
     * Buy PrizePool Fee rate
     * Buy Support Stream Fee Rate
     * Sell Charity Fee Rate
     * Sell Reflection Fee Rate
     * Sell Marketing Fee Rate
     * Sell PrizePool Fee rate
     * Sell Support Stream Fee Rate
     */
    function getRatesIndexZero() external view returns (uint16[10] memory) {
        bytes32[2] memory contractRates = _contractRates;

        return (
            [
                uint16(bytes2(contractRates[0])),
                uint16(bytes2(contractRates[0] << 16)),
                uint16(bytes2(contractRates[0] << 32)),
                uint16(bytes2(contractRates[0] << 48)),
                uint16(bytes2(contractRates[0] << 64)),
                uint16(bytes2(contractRates[0] << 80)),
                uint16(bytes2(contractRates[0] << 96)),
                uint16(bytes2(contractRates[0] << 112)),
                uint16(bytes2(contractRates[0] << 128)),
                uint16(bytes2(contractRates[0] << 144))
            ]
        );
    }

    /**
     * Buy Buyback Burn Rate (0-100)
     * Buy LP Rate (0-100)
     * Sell Buyback Burn Rate (0-100)
     * Sell LP Rate (0-100)
     * Price Impact Trigger (0-)
     * Minimum based on sell price before burning tokens
     * Max amount to buy based on sell price
     * Initial Burn rate based off token sell amount
     */
    function getRatesIndexOne() external view returns (uint32[6] memory) {
        bytes32[2] memory contractRates = _contractRates;

        return [
            uint32(bytes4(contractRates[1])),
            uint32(bytes4(contractRates[1] << 32)),
            uint32(bytes4(contractRates[1] << 64)),
            uint32(bytes4(contractRates[1] << 96)),
            uint32(bytes4(contractRates[1] << 128)),
            uint32(bytes4(contractRates[1] << 160))
        ];
    }

    function getPancakePairAddress() external view returns (address) {
        return _pancakePair;
    }

    function getPancakeRouterAddress() external view returns (address) {
        return address(_pancakeRouter);
    }

    /**
     * 0 & 2 = Disabled
     * 1 & 3 = Enabled
     *
     * 2 & 3 are values that have been locked forever in this state.
     */
    function getToggleValues() external view returns (uint8[3] memory) {
        bytes8 toggles = _contractToggles;

        return [
            uint8(bytes1(toggles)),
            uint8(bytes1(toggles << 8)),
            uint8(bytes1(toggles << 16))
        ];
    }

    /// Values tracking Tokens/BNB for internal functions
    function getInitialSupportFunds() external view returns (uint128) {
        return _tokensForInitialSupport;
    }

    function getLotteryTokens() public view returns (uint256) {
        return _prizePool.collectedPot;
    }

    function tokenFromReflection(uint256 amount)
        external
        view
        returns (uint256)
    {
        require(
            amount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        return amount / getReflectionRate();
    }

    function totalReflectionsEarned() external view returns (uint256) {
        return _reflectionFeesEarned;
    }

    function name() external pure returns (string memory) {
        return "Token Name";
    }

    function symbol() external pure returns (string memory) {
        return "SYMB";
    }

    function decimals() external pure returns (uint256) {
        return 9;
    }

    function approveAllowance(
        address owner,
        address spender,
        uint128 amount
    ) private {
        _verify(owner, spender);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint128 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _reflectionBalance[from] / getReflectionRate() >= amount ||
                _tokenBalance[from] >= amount,
            "Balance must be greater than amount"
        );
        bytes8 toggles = _contractToggles;
        uint128 reflectionFee;
        uint128 tokenFees;
        address pancakePair = _pancakePair;
        bytes32[2] memory contractRates = _contractRates;

        if (!_lockSwap) {
            uint128 charityFee;
            uint128 marketingFee;
            uint128 prizePoolFee;
            uint128 supportStreamFee;

            (
                charityFee,
                reflectionFee,
                marketingFee,
                prizePoolFee,
                supportStreamFee
            ) = _splitAndDetermineFees(amount, from, to);

            tokenFees +=
                charityFee +
                reflectionFee +
                marketingFee +
                prizePoolFee +
                supportStreamFee;

            if (to == pancakePair) {
                uint64 tokensForInitialSupport = _tokensForInitialSupport;

                _initialSupportBurn(
                    tokensForInitialSupport,
                    uint64(amount),
                    contractRates[1]
                );

                if (supportStreamFee > 0) {
                    _tokenBalance[address(this)] += supportStreamFee;
                    emit Transfer(from, address(this), supportStreamFee);

                    _sellSupportFeeAndInjectLP(
                        toggles,
                        tokensForInitialSupport,
                        supportStreamFee,
                        contractRates[1]
                    );
                }
            }

            if (prizePoolFee > 0) _handlePrizePool(from, prizePoolFee, amount);
        } // !_lockSwap

        bool antiWhaleCheck = _getToggle(toggles, 0) &&
            to != pancakePair &&
            to != _burnAddress &&
            to != address(this);

        _finishTransfer(
            antiWhaleCheck,
            from,
            to,
            amount,
            reflectionFee,
            tokenFees,
            contractRates[1]
        );
    }

    function _initialSupportBurn(
        uint64 tokensForInitialSupport,
        uint64 amount,
        bytes32 contractRatesOne
    ) private {
        uint32 burnRate = uint32(bytes4(contractRatesOne << 64));
        if (
            burnRate > 0 &&
            _tokenBalance[address(this)] >= amount &&
            tokensForInitialSupport >= amount
        ) {
            uint64 amountToBurn = (amount * burnRate) / _DENOMINATOR;

            // Burn support tokens allocated to contract
            if (tokensForInitialSupport >= amountToBurn) {
                _burn(amountToBurn);
                tokensForInitialSupport -= amountToBurn;
            }
        }

        _tokensForInitialSupport = tokensForInitialSupport;
    }

    /// supportFee > 0
    function _sellSupportFeeAndInjectLP(
        bytes8 toggles,
        uint64 tokensForInitialSupport,
        uint128 supportStreamFee,
        bytes32 contractRatesOne
    ) private LockSwap {
        bool initialSupportLP = _getToggle(toggles, 1);
        uint32 liquidityRate = uint32(bytes4(contractRatesOne << 32));
        uint128 tokensForLP;

        if (liquidityRate > 0)
            tokensForLP = initialSupportLP
                ? _setExtraLPTokens(
                    liquidityRate,
                    tokensForInitialSupport,
                    supportStreamFee
                )
                : ((supportStreamFee * liquidityRate) / _DENOMINATOR) / 2;
        uint128 bnbReceived = _sellTokensForBNB(supportStreamFee - tokensForLP);
        uint128 liquidityBNB;

        if (bnbReceived > 0) {
            liquidityBNB = _getLiquidityFee(
                initialSupportLP,
                bnbReceived,
                contractRatesOne
            );
        }

        if (
            _getToggle(toggles, 2) &&
            _tokenBalance[address(this)] >= _tokensForInitialSupport
        ) {
            _addLiquidity(
                _tokenBalance[address(this)] - _tokensForInitialSupport,
                liquidityBNB
            );
        }
    }

    function _setExtraLPTokens(
        uint32 liquidityRate,
        uint64 tokensForInitialSupport,
        uint128 supportFee
    ) private returns (uint128 tokensForLP) {
        tokensForLP = ((supportFee * liquidityRate) / _DENOMINATOR) / 2;

        if (tokensForInitialSupport > 0) {
            if (tokensForInitialSupport >= tokensForLP) {
                tokensForLP *= 2;
                tokensForInitialSupport -= uint64(tokensForLP);
            }
        }

        _tokensForInitialSupport = tokensForInitialSupport;
    }

    function _handlePrizePool(
        address from,
        uint128 prizePoolFee,
        uint128 amount
    ) private {
        PrizePool memory prizePool = _prizePool;

        prizePool.collectedPot += prizePoolFee;

        if (
            prizePool.enabled &&
            from == _pancakePair &&
            prizePool.collectedPot >= prizePool.triggerThreshold &&
            amount >= prizePool.minimiumSpendAmount
        ) {
            uint128 reward;
            uint128 lotteryRewardsCollected = prizePool.collectedPot;

            // Generates a random number between 1 and 1000
            uint256 random = uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            prizePool.nonce
                        )
                    )
                ) % 1000
            );
            prizePool.lastRoll = random + 1;
            prizePool.nonce++;

            if (prizePool.lastRoll <= prizePool.chanceToWin) {
                reward = lotteryRewardsCollected;
            }

            if (reward > 0) {
                if (_isExcluded[from].fromReward) {
                    _tokenBalance[from] += lotteryRewardsCollected;
                } else {
                    _reflectionBalance[from] +=
                        lotteryRewardsCollected *
                        getReflectionRate();
                }

                prizePool.collectedPot = 0;
                prizePool.previousWinner = from;
                prizePool.previousWinAmount = lotteryRewardsCollected;
                prizePool.previousWinTime = uint64(block.timestamp);
                emit PrizePoolWon(
                    uint64(block.timestamp),
                    from,
                    lotteryRewardsCollected
                );
                emit Transfer(address(this), from, lotteryRewardsCollected);
            }
        }

        _prizePool = prizePool;
    }

    function _getReserves()
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

    function sortTokens(address tokenA, address tokenB)
        private
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function _sellTokensForBNB(uint128 tokensToSell)
        private
        returns (uint128 bnbReceived)
    {
        uint256 initialBnb = address(this).balance;

        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        // make the swap
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSell,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        if (address(this).balance > initialBnb) {
            bnbReceived = uint128(address(this).balance - initialBnb);

            emit SwapTokensForBNB(tokensToSell, bnbReceived);
        }
    }

    function _sendBNB(uint128 charityBNB, uint128 marketingBNB) private {
        bool success;

        if (charityBNB > 0) {
            (success, ) = charityAddress.call{value: charityBNB}(new bytes(0));

            if (success) {
                emit SendToWallet("Charity", charityAddress, charityBNB);
            }
        }

        if (marketingBNB > 0) {
            (success, ) = marketingAddress.call{value: marketingBNB}(
                new bytes(0)
            );
            if (success)
                emit SendToWallet("Marketing", marketingAddress, marketingBNB);
        }
    }

    /// Buys tokens and immediately sends them to the burn address
    function _buyTokensAndBurn(uint128 bnbAmount) private {
        if (address(this).balance >= bnbAmount) {
            // generate the Pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = _pancakeRouter.WETH();
            path[1] = address(this);

            // make the swap
            _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: bnbAmount
            }(
                0, // accept any amount of Tokens
                path,
                _burnAddress,
                block.timestamp
            );

            emit BuybackTokens(bnbAmount);
        }
    }

    function _addLiquidity(uint128 tokensAvailable, uint128 bnbAmount) private {
        (uint128 tokenA, uint128 tokenB) = _getReserves();
        uint128 tokenQuote = uint128(
            _pancakeRouter.quote(bnbAmount, tokenB, tokenA)
        );

        if (tokensAvailable < tokenQuote) {
            uint128 bnbQuote = uint128(
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

    function _finishTransfer(
        bool antiWhaleCheck,
        address from,
        address to,
        uint128 amount,
        uint128 reflectionFee,
        uint128 tokenFees,
        bytes32 contractRatesOne
    ) private {
        uint128 amountMinusFees = amount - tokenFees;
        uint128 reflectionFeeWithRate = reflectionFee * getReflectionRate();
        uint128 antiWhaleLimit = (_tokenSupply *
                uint16(bytes2(contractRatesOne << 160))) / _DENOMINATOR;

        if (!_isExcluded[from].fromReward) {
            _reflectionBalance[from] -= (amount * getReflectionRate());
        } else if (_isExcluded[from].fromReward) {
            _tokenBalance[from] -= amount;
        }

        if (!_isExcluded[to].fromReward) {
            _reflectionBalance[to] += amountMinusFees * getReflectionRate();

            if (antiWhaleCheck) {
                require(
                    _reflectionBalance[to] / getReflectionRate() <=
                        antiWhaleLimit,
                    "Receiver balance exceeds holder limit"
                );
            }

        } else if (_isExcluded[to].fromReward) {
            _tokenBalance[to] += amountMinusFees;

            if (antiWhaleCheck) {
                require(
                    _tokenBalance[to] <=
                        antiWhaleLimit,
                    "Receiver balance exceeds holder limit"
                );
            }
        }

        if (reflectionFeeWithRate > 0) {
            if (_reflectionTotal >= reflectionFeeWithRate)
                _reflectionTotal -= reflectionFeeWithRate;

            _reflectionFeesEarned += reflectionFee;
            emit TokensReflected(reflectionFee);
        }

        emit Transfer(from, to, amountMinusFees);
    }

    function _burn(uint128 amount) private {
        _verify(_msgSender(), _burnAddress);

        require(
            _tokenSupply >= amount,
            "Not enough tokens in supply to burn the amount requested"
        );

        uint128 amountWithReflections = amount * getReflectionRate();
        if (_reflectionTotal >= amountWithReflections)
            _reflectionTotal -= amountWithReflections;

        _tokenSupply -= amount;
        _tokenBalance[address(this)] -= amount;
        _tokenBalance[_burnAddress] += amount;

        emit Transfer(address(this), _burnAddress, amount);
    }

    function _setRateIndexOne(uint8 subIndex, uint32 value) private {
        bytes32[2] storage contractRates = _contractRates;
        subIndex *= 32;

        contractRates[1] &= ~(bytes32(bytes4(~uint32(0))) >> subIndex);
        contractRates[1] |= bytes32(bytes4(value)) >> subIndex;

        emit SetRate(1, subIndex, value);
    }

    function getReflectionRate() private view returns (uint128) {
        if (_reflectionTotal > _tokenSupply) {
            return _reflectionTotal / _tokenSupply;
        } else {
            return (_MAX - (_MAX % _tokenSupply)) / _tokenSupply;
        }
    }

    function _splitAndDetermineFees(
        uint128 amount,
        address from,
        address to
    )
        private
        returns (
            uint128 charityFee,
            uint128 reflectionFee,
            uint128 marketingFee,
            uint128 prizePoolFee,
            uint128 supportStreamFee
        )
    {
        uint24 denominator = _DENOMINATOR;
        (
            uint128 charityRate,
            uint128 reflectionRate,
            uint128 marketingRate,
            uint128 prizePoolRate,
            uint128 supportStreamRate
        ) = _getRates(from, to);

        if (charityRate > 0) {
            charityFee = (amount * charityRate) / denominator;

            _tokenBalance[charityAddress] += charityFee;
            emit Transfer(address(this), charityAddress, charityFee);
        }

        if (reflectionRate > 0)
            reflectionFee = (amount * reflectionRate) / denominator;

        if (marketingRate > 0) {
            marketingFee = (amount * marketingRate) / denominator;

            _tokenBalance[marketingAddress] += marketingFee;
            emit Transfer(address(this), marketingAddress, marketingFee);
        }

        if (prizePoolRate > 0)
            prizePoolFee = (amount * prizePoolRate) / denominator;

        if (supportStreamRate > 0)
            supportStreamFee = (amount * supportStreamRate) / denominator;
    }

    function _getRates(address from, address to)
        private
        view
        returns (
            uint16 charityRate,
            uint16 reflectionRate,
            uint16 marketingRate,
            uint16 prizePoolRate,
            uint16 supportStreamRate
        )
    {
        IsExcluded memory isExcludedFrom = _isExcluded[from];
        IsExcluded memory isExcludedTo = _isExcluded[to];
        bytes32[2] memory contractRates = _contractRates;

        if (!(isExcludedFrom.fromFee || isExcludedTo.fromFee)) {
            if (isExcludedFrom.forVendor || isExcludedTo.forVendor) {
                reflectionRate = 1500;
                charityRate = 1500;
            } else {
                charityRate = uint16(bytes2(contractRates[1] << 96));
                reflectionRate = uint16(bytes2(contractRates[1] << 128));

                /// Buy
                if (from == _pancakePair) {
                    charityRate = uint16(bytes2(contractRates[0]));
                    reflectionRate = uint16(bytes2(contractRates[0] << 16));
                    marketingRate = uint16(bytes2(contractRates[0] << 32));
                    prizePoolRate = uint16(bytes2(contractRates[0] << 48));
                    supportStreamRate = uint16(bytes2(contractRates[0] << 64));

                /// Sell
                } else if (to == _pancakePair) {
                    charityRate = uint16(bytes2(contractRates[0] << 80));
                    reflectionRate = uint16(bytes2(contractRates[0] << 96));
                    marketingRate = uint16(bytes2(contractRates[0] << 112));
                    prizePoolRate = uint16(bytes2(contractRates[0] << 128));
                    supportStreamRate = uint16(bytes2(contractRates[0] << 144));
                }
            }
        }
    }

    function _getToggle(bytes8 toggles, uint8 index)
        private
        pure
        returns (bool)
    {
        uint8 currentValue = uint8(bytes1(toggles << (index * 8)));
        return (currentValue == 1 || currentValue == 3) ? true : false;
    }

    function _getLiquidityFee(
        bool addExtraLPSupport,
        uint128 bnbToSplit,
        bytes32 contractRatesOne
    ) private pure returns (uint128 liquidityFee) {
        uint32 commonDenominator = uint32(bytes4(contractRatesOne)); // Buyback rate
        uint32 liquidityRate = uint32(bytes4(contractRatesOne << 32));

        if (liquidityRate > 0) {
            if (!addExtraLPSupport) liquidityRate /= 2;
            commonDenominator += liquidityRate;

            liquidityFee =
                ((bnbToSplit * (liquidityRate * _DENOMINATOR)) /
                    commonDenominator) /
                _DENOMINATOR;
        }
    }

    function _verify(address from, address to) private pure {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
    }
}