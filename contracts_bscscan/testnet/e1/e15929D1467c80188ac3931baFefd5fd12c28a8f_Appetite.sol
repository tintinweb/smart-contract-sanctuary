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
        uint128 minimumSpendAmount;
        address previousWinner;
        uint256 lastRoll;
        uint256 nonce;
    }

    modifier LockSwap() {
        _lockSwap = true;
        _;
        _lockSwap = false;
    }

    bool private _lockSwap;

    uint128 private _tokensForInitialSupport;
    uint128 private _tokenSupply = 10**9 * 10**9;
    uint128 private constant _MAX = ~uint128(0);
    uint128 private _reflectionTotal = (_MAX - (_MAX % _tokenSupply));
    uint128 private _reflectionFeesEarned;
    bytes16 private _contractRates;

    address private _pancakePair;
    address public immutable burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public charityAddress =
        payable(0xf54Bf63f4940dc775e55dAa4ca33e342E2A87551);
    address payable public marketingAddress =
        payable(0xF26d52Ba6F2A24C49220Aeb98c4a5b2ab28c715F);

    mapping(address => mapping(address => uint128)) private _allowances;
    mapping(address => uint128) private _tokenBalance;
    mapping(address => uint128) private _reflectionBalance;
    mapping(address => IsExcluded) private _isExcluded;

    IPancakeRouter02 private _pancakeRouter;
    PrizePool public _prizePool;

    event TokensReflected(uint256 tokensReflected);
    event SendToWallet(string wallet, address walletAddress, uint256 bnbForLP);
    event AddLiquidity(uint256 tokensIn, uint256 bnbIn, address path);
    event SwapTokensForBNB(uint128 amountIn, uint128 amountOut);
    event SetRate(uint32 byteIndex, uint32 value);
    event PrizePoolWon(uint64 blockTime, address winner, uint128 amount);

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

        _isExcluded[burnAddress].fromReward = true;
        _isExcluded[pancakePair].fromReward = true;
        _isExcluded[marketingAddress].fromReward = true;
        _isExcluded[address(this)].fromReward = true;

        uint128 initialSupportTokens = (_tokenSupply * 15000) / 100000;
        _tokensForInitialSupport = initialSupportTokens;

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

    function setPancakePairAddress(address newPair) external onlyOwner {
        _pancakePair = newPair;
    }

    function setPancakeRouterAddress(address newRouter) external onlyOwner {
        /// If using a new version it may not be compatible
        /// we will force it to use the V2 interface since that is what this contract is using.
        _pancakeRouter = IPancakeRouter02(newRouter);
    }

    /**
     * Rates used by the contract to determine outcomes
     *
     * 0: Buy Charity/Marketing/Support Fee Rate
     * 1: Buy Reflection Fee Rate
     * 2: Buy PrizePool Fee Rate
     * 3: Sell Charity/Marketing/Support Fee Rate
     * 4: Sell Reflection Fee Rate
     * 5: Sell PrizePool Fee Rate
     * 6: Send Charity/Marketing/Support Fee Rate
     */
    function setIndexRate(uint16 index, uint16 value) external onlyOwner {
        require(index <= 7, "index too high");

        if(index == 1 || index == 3) {
            require(value <= 18000, "Fee Rate be lower or equal to 18% (18000)");
        } else if (index == 6) {
            require(value <= 12000, "Fee Rate be lower or equal to 12% (12000)");
        } else {
            require(value <= 6000, "Fee Rate be lower or equal to 6% (6000)");
        }

        index *= 16;

        _contractRates &= ~(bytes16(bytes2(~uint16(0))) >> index);
        _contractRates |= bytes16(bytes2(value)) >> index;

        emit SetRate(index, value);
    }

    function setAntiWhaleLimit(uint16 limit) external onlyOwner {
        _contractRates &= ~(bytes16(bytes2(~uint16(0))) >> 112);
        _contractRates |= bytes16(bytes2(limit)) >> 112;

        emit SetRate(112, limit);
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
        _prizePool.minimumSpendAmount = minimumSpend;
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account].fromReward, "Account is already included");
        _isExcluded[account].fromReward = false;

        _reflectionBalance[account] =
            _tokenBalance[account] *
            _getReflectionRate();
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
                _getReflectionRate();

            _reflectionBalance[account] = 0;
        }
        _isExcluded[account].fromReward = true;
    }

    /**
     * @param listIndex Must be 0 or 1. 0 = 0 fee list; 1 = 3% vendor list
     */
    function addToFeeList(uint8 listIndex, address account) external onlyOwner {
        require(listIndex <= 1, "Index too high");

        if (listIndex == 0) {
            _isExcluded[account].fromFee = true;
        } else if (listIndex == 1) {
            _isExcluded[account].forVendor = true;
        }
    }

    /**
     * Include back in a fee list, use the same index used for addToFeeList
     *
     * @param listIndex 0 = 0 fee list; 1 = 3% vendor list
     */
    function removeFromFeeList(uint8 listIndex, address account)
        external
        onlyOwner
    {
        require(listIndex <= 1, "Index too high");

        if (listIndex == 0) {
            _isExcluded[account].fromFee = false;
        } else if (listIndex == 1) {
            _isExcluded[account].forVendor = false;
        }
    }

    /// Configures default rates and feature toggles
    function setDefaultRates() external onlyOwner {
        _contractRates &= ~bytes16(~uint128(0));
        _contractRates |=
            bytes16(bytes2(uint16(9000))) |
            (bytes16(bytes2(uint16(2000))) >> 16) |
            (bytes16(bytes2(uint16(1000))) >> 32) |
            (bytes16(bytes2(uint16(12000))) >> 48) |
            (bytes16(bytes2(uint16(3000))) >> 64) |
            (bytes16(bytes2(uint16(1000))) >> 80) |
            (bytes16(bytes2(uint16(6000))) >> 96) |
            (bytes16(bytes2(uint16(2000))) >> 112);
    }

    /// Burn tokens from the initial support stream(0) or extra tokens in contract(1)
    function burnTokens(uint8 index, uint64 amount) external onlyOwner {
        require(index <= 1, "Index must be 0 or 1");
        uint128 tokensMinusInitialSupport;

        unchecked {
            tokensMinusInitialSupport =
                _tokenBalance[address(this)] -
                _tokensForInitialSupport -
                _prizePool.collectedPot;
        }

        if(index == 0) {
            require(
                _tokenBalance[address(this)] >= amount &&
                    _tokensForInitialSupport >= amount,
                "Balance must be greater than amount"
            );

            _burn(amount);
            _tokensForInitialSupport -= amount;
        } else if(tokensMinusInitialSupport >= amount){
            _burn(amount);
        }
    }

    /**
     * Will sell given amount of tokens and split between fee paths
     * including injecting LP automatically so stored BNB is for buyback
     */
    function sellTokens(uint128 amount) external LockSwap onlyOwner {
        uint128 tokensMinusInitialSupport;
        unchecked {
            tokensMinusInitialSupport =
                _tokenBalance[address(this)] -
                _tokensForInitialSupport -
                _prizePool.collectedPot;
        }

        require(
            tokensMinusInitialSupport >= amount &&
                _tokenBalance[address(this)] >= amount,
            "Not enough tokens allowed for swapping"
        );

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
                amount,
                uint128(address(this).balance - initialBnb)
            );
        }
    }

    /**
     * Uses given rates to determine where BNB from the contract is going
     * RATES should be simple small versions totaling to 100 or less. (ex: 25 = 25%).
     *
     * Rates do not need to equal 100 or all be used here are some examples:
     *
     * useContractBNB(30, 30, 30, 5);
     * This will leave 5% BNB inside the contract.
     *
     * useContractBNB(0, 0, 75, 0);
     * This buyback using 75% of the BNB supply, 25% remains
     */
    function useContractBNB(
        uint32 charityRate,
        uint32 marketingRate,
        uint32 buybackRate,
        uint32 liquidityRate,
        uint128 amount
    ) external LockSwap onlyOwner {
        require(
            address(this).balance >= amount,
            "Not enough BNB in the contract"
        );
        require(
            charityRate + marketingRate + buybackRate + liquidityRate <= 100,
            "Total must be less than 100%"
        );
        bool success;
        uint32 denominator = 100000;

        if (charityRate > 0) {
            uint256 charityBNB = (amount * (charityRate * 1000)) / denominator;

            (success, ) = charityAddress.call{value: charityBNB}(new bytes(0));

            if (success)
                emit SendToWallet("Charity", charityAddress, charityBNB);
        }

        if (marketingRate > 0) {
            uint256 marketingBNB = (amount * (marketingRate * 1000)) /
                denominator;

            (success, ) = marketingAddress.call{value: marketingBNB}(
                new bytes(0)
            );

            if (success)
                emit SendToWallet("Marketing", marketingAddress, marketingBNB);
        }

        if (buybackRate > 0) {
            uint256 buybackBNB = (amount * (buybackRate * 1000)) / denominator;
            if (address(this).balance >= buybackBNB) {
                // generate the Pancake pair path of token -> weth
                address[] memory path = new address[](2);
                path[0] = _pancakeRouter.WETH();
                path[1] = address(this);

                // make the swap
                _pancakeRouter
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: buybackBNB
                }(
                    0, // accept any amount of Tokens
                    path,
                    burnAddress,
                    block.timestamp
                );
            }
        }

        if (liquidityRate > 0) {
            uint128 amountAvailable;
            uint128 liquidtyFee = (amount * (liquidityRate * 1000)) /
                denominator;
            uint128 tokensForInitialSupport = _tokensForInitialSupport;

            if (tokensForInitialSupport >= liquidtyFee) {
                amountAvailable = tokensForInitialSupport;
                _tokensForInitialSupport -= liquidtyFee;
            } else {
                unchecked {
                    amountAvailable =
                        _tokenBalance[address(this)] -
                        tokensForInitialSupport -
                        _prizePool.collectedPot;
                }
            }

            if (amountAvailable > 0)
                _addLiquidity(uint128(amountAvailable), liquidtyFee);
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
        return _reflectionBalance[account] / _getReflectionRate();
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

    function circulatingSupply() external view returns (uint256) {
        return _tokenSupply - _tokenBalance[burnAddress];
    }

    /**
     * 0: Buy Charity/Marketing/Support Fee Rate
     * 1: Buy Reflection Fee Rate
     * 2: Buy PrizePool Fee Rate
     * 3: Sell Charity/Marketing/Support Fee Rate
     * 4: Sell Reflection Fee Rate
     * 5: Sell PrizePool Fee Rate
     * 6: Send Charity Rate
     * 7: Send Reflection Rate
     * 8: Anti Whale Rate
     */
    function getContractRates() external view returns (uint16[8] memory) {
        bytes18 contractRates = _contractRates;

        return (
            [
                uint16(bytes2(contractRates)),
                uint16(bytes2(contractRates << 16)),
                uint16(bytes2(contractRates << 32)),
                uint16(bytes2(contractRates << 48)),
                uint16(bytes2(contractRates << 64)),
                uint16(bytes2(contractRates << 80)),
                uint16(bytes2(contractRates << 96)),
                uint16(bytes2(contractRates << 112))
            ]
        );
    }

    function getPancakePairAddress() external view returns (address) {
        return _pancakePair;
    }

    function getPancakeRouterAddress() external view returns (address) {
        return address(_pancakeRouter);
    }

    function getInitialSupportFunds() external view returns (uint128) {
        return _tokensForInitialSupport;
    }

    // Conveniently displays actual token pot minus its decimal places
    function getPrizePoolTokens() external view returns (uint128) {
        return _prizePool.collectedPot / 10**9;
    }

    function getTokensAvailableToSell() external view returns (uint128) {
        return _tokenBalance[address(this)] - _tokensForInitialSupport - _prizePool.collectedPot;
    }

    function getTokenAmountFromReflection(uint128 amount)
        external
        view
        returns (uint128)
    {
        require(
            amount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        return amount / _getReflectionRate();
    }

    function getReflectionAmountFromToken(uint128 amount)
        external
        view
        returns (uint128)
    {
        uint128 reflectedAmount = amount * _getReflectionRate();
        require(
            reflectedAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );

        return reflectedAmount;
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
            _reflectionBalance[from] / _getReflectionRate() >= amount ||
                _tokenBalance[from] >= amount,
            "Balance must be greater than amount"
        );
        uint32 antiWhaleRate = uint16(bytes2(_contractRates << 128));
        bool antiWhaleCheck = antiWhaleRate > 0 &&
            to != _pancakePair &&
            to != burnAddress &&
            to != address(this);
        uint128 reflectionFee;
        uint128 tokenFees;

        if (!_lockSwap) {
            uint128 tokensForSelling;
            uint128 prizePoolFee;

            if (!(_isExcluded[from].fromFee || _isExcluded[to].fromFee)) {
                (
                    tokensForSelling,
                    reflectionFee,
                    prizePoolFee
                ) = _splitAndDetermineFees(amount, from, to);

                tokenFees = tokensForSelling + prizePoolFee + reflectionFee;
            }

            _handlePrizePool(from, to, prizePoolFee, amount);
        } // !_lockSwap

        /// Finish Transfer
        uint128 amountMinusFees = amount - tokenFees;
        uint128 reflectionFeeWithRate = reflectionFee * _getReflectionRate();

        if (!_isExcluded[from].fromReward) {
            _reflectionBalance[from] -= (amount * _getReflectionRate());
        } else if (_isExcluded[from].fromReward) {
            _tokenBalance[from] -= amount;
        }

        if (!_isExcluded[to].fromReward) {
            _reflectionBalance[to] += amountMinusFees * _getReflectionRate();

            if (antiWhaleCheck) {
                require(
                    _reflectionBalance[to] / _getReflectionRate() <=
                        ((_tokenSupply - _tokenBalance[burnAddress]) *
                            antiWhaleRate) /
                            100000,
                    "Receiver Reflection balance exceeds holder limit"
                );
            }
        } else if (_isExcluded[to].fromReward) {
            _tokenBalance[to] += amountMinusFees;

            if (antiWhaleCheck) {
                require(
                    _tokenBalance[to] <=
                        ((_tokenSupply - _tokenBalance[burnAddress]) *
                            antiWhaleRate) /
                            100000,
                    "Receiver Token balance exceeds holder limit"
                );
            }
        }

        if (reflectionFeeWithRate > 0) {
            if (_reflectionTotal >= reflectionFeeWithRate)
                _reflectionTotal -= reflectionFeeWithRate;

            _reflectionFeesEarned += reflectionFee;
            emit TokensReflected(reflectionFee);
        }

        if (tokenFees > 0) {
            _tokenBalance[address(this)] += tokenFees - reflectionFee; // Don't actually get reflections
            emit Transfer(from, address(this), tokenFees);
        }

        emit Transfer(from, to, amountMinusFees);
    }

    function _handlePrizePool(
        address from,
        address to,
        uint128 prizePoolFee,
        uint128 amount
    ) private {
        PrizePool memory prizePool = _prizePool;

        prizePool.collectedPot += prizePoolFee;

        /// BUYS Only, given a chance to win if spending above minimumSpendAmount
        if (
            prizePool.enabled &&
            from == _pancakePair &&
            prizePool.collectedPot >= prizePool.triggerThreshold &&
            amount >= prizePool.minimumSpendAmount
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
                if (_isExcluded[to].fromReward) {
                    _tokenBalance[to] += lotteryRewardsCollected;
                } else {
                    _reflectionBalance[to] +=
                        lotteryRewardsCollected *
                        _getReflectionRate();
                }

                prizePool.collectedPot = 0;
                prizePool.previousWinner = to;
                prizePool.previousWinAmount = lotteryRewardsCollected;
                prizePool.previousWinTime = uint64(block.timestamp);
                emit PrizePoolWon(
                    uint64(block.timestamp),
                    to,
                    lotteryRewardsCollected
                );

                _tokenBalance[address(this)] -= lotteryRewardsCollected;
                emit Transfer(address(this), to, lotteryRewardsCollected);
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

    function _addLiquidity(uint128 tokensAvailable, uint256 bnbAmount) private {
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

    function _burn(uint128 amount) private {
        if (_tokenBalance[address(this)] >= amount) {
            _tokenBalance[address(this)] -= amount;
            _tokenBalance[burnAddress] += amount;

            emit Transfer(address(this), burnAddress, amount);
        }
    }

    function _getReflectionRate() private view returns (uint128) {
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
        view
        returns (
            uint128 tokensForSellFee,
            uint128 reflectionFee,
            uint128 prizePoolFee
        )
    {
        uint32 denominator = 100000;
        (
            uint128 tokensForSellRate,
            uint128 reflectionRate,
            uint128 prizePoolRate
        ) = _getRates(from, to);

        if (tokensForSellRate > 0)
            tokensForSellFee = (amount * tokensForSellRate) / denominator;

        if (reflectionRate > 0)
            reflectionFee = (amount * reflectionRate) / denominator;

        if (prizePoolRate > 0)
            prizePoolFee = (amount * prizePoolRate) / denominator;
    }

    function _getRates(address from, address to)
        private
        view
        returns (
            uint128 tokensForSellRate,
            uint128 reflectionRate,
            uint128 prizePoolRate
        )
    {
        bytes16 contractRates = _contractRates;

        if (_isExcluded[from].forVendor || _isExcluded[to].forVendor) {
            tokensForSellRate = 3000;
        } else {
            /// Buy
            if (from == _pancakePair) {
                tokensForSellRate = uint16(bytes2(contractRates));
                reflectionRate = uint16(bytes2(contractRates << 16));
                prizePoolRate = uint16(bytes2(contractRates << 32));

                /// Sell
            } else if (to == _pancakePair) {
                tokensForSellRate = uint16(bytes2(contractRates << 48));
                reflectionRate = uint16(bytes2(contractRates << 64));
                prizePoolRate = uint16(bytes2(contractRates << 80));
            } else {
                tokensForSellRate = uint16(bytes2(contractRates << 96));
            }
        }
    }

    function _verify(address from, address to) private pure {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
    }
}