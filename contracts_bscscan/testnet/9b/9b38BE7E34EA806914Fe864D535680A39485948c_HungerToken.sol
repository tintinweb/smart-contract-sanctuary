// SPDX-License-Identifier: X11

/*
    ██╗  ██╗██╗   ██╗███╗   ██╗ ██████╗ ███████╗██████╗
    ██║  ██║██║   ██║████╗  ██║██╔════╝ ██╔════╝██╔══██╗
    ███████║██║   ██║██╔██╗ ██║██║  ███╗█████╗  ██████╔╝
    ██╔══██║██║   ██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██╗
    ██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝███████╗██║  ██║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

            ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
            ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
               ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
               ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
               ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
               ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝

   <Please check out our WhitePaper over at https://<ipfs-hosted-preferred|your-domain>
   to get an overview of our contract!

   Feel free to put any relevant PROJECT INFORMATION HERE>
*/

pragma solidity ^0.8.9;

import "./ThirdParty.sol";

contract HungerToken is Context, IERC20, Ownable {
    using Address for address;

    struct IsExcluded {
        bool fromFee;
        bool fromReward;
        bool forVendor;
    }

    struct LuckyShot {
        bool enabled;
        uint16 chanceToWin;
        uint64 previousWinTime;
        uint64 previousWinAmount;
        uint64 minimumSpendAmount;
        uint128 minimumPoolThreshold;
        address previousWinner;
        uint256 pool;
        uint256 lastRoll;
        uint256 nonce;
    }

    modifier LockSwap() {
        _lockSwap = true;
        _;
        _lockSwap = false;
    }

    bool private _lockSwap;

    bytes16 private _contractRates;
    uint128 private _tokenSupply = 10**9 * 10**9;
    uint128 private _reflectionFeesEarned;

    address private _pancakePair;
    address public immutable burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public charityAddress =
        payable(0x580C0343cb96dd6B4E24Dbe516a5cAbF872A1e9f);
    address payable public marketingAddress =
        payable(0x8a8E03d0C8eA6451A883F27969Cd198D5Dfd371C);

    uint256 private _tokensForInitialSupport;
    uint256 private constant _MAX = ~uint256(0);
    uint256 private _reflectionTotal = (_MAX - (_MAX % _tokenSupply));

    mapping(address => IsExcluded) private _isExcluded;
    mapping(address => uint256) private _tokenBalance;
    mapping(address => uint256) private _reflectionBalance;
    mapping(address => mapping(address => uint256)) private _allowances;

    IPancakeRouter02 private _pancakeRouter;
    LuckyShot public _luckyShot;

    event TokensReflected(uint256 tokensReflected);
    event SendToWallet(string wallet, address walletAddress, uint256 bnbForLP);
    event AddLiquidity(uint256 tokensIn, uint256 bnbIn, address path);
    event SwapTokensForBNB(uint128 amountIn, uint128 amountOut);
    event SetRate(uint32 byteIndex, uint32 value);
    event LuckyShotWon(uint64 amount, uint64 indexed blockTime, address indexed winner);

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
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][_msgSender()];

        _transfer(from, to, amount);

        if (currentAllowance < ~uint256(0)) {
            approveAllowance(
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

    function decreaseAllowance(address spender, uint256 subtractedValue)
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
     * 2: Buy LuckyShot Fee Rate
     * 3: Sell Charity/Marketing/Support Fee Rate
     * 4: Sell Reflection Fee Rate
     * 5: Sell LuckyShot Fee Rate
     * 6: Send Charity/Marketing/Support Fee Rate
     * 7: Anti-Whale Rate (based off supply minus burned tokens)
     */
    function setContractRate(uint16 index, uint16 value) external onlyOwner {
        require(index <= 7, "index too high");

        if(index == 0 || index == 3) {
            require(value <= 18000, "Combined Sell/Buy Fee Rate must be equal to or lower than 18% (18000)");
        } else if (index == 6) {
            require(value <= 12000, "Send Fee Rate must be equal to or lower than 12% (12000)");
        } else if (index != 7) {
            require(value <= 6000, "Reflection/LuckyShot Pool Fee Rate must be equal to or lower than 6% (6000)");
        }

        index *= 16;

        _contractRates &= ~(bytes16(bytes2(~uint16(0))) >> index);
        _contractRates |= bytes16(bytes2(value)) >> index;

        emit SetRate(index, value);
    }

    /// Same as setting setContractRate(7, 0)
    function disableAntiWhale() external onlyOwner {
        _contractRates &= ~(bytes16(bytes2(~uint16(0))) >> 112);

        emit SetRate(112, 0);
    }

    // Enable or disable the luckyShot functionality, must turn fees to 0 or POOL will still get tokens
    function setLotterEnabled(bool enabled) external onlyOwner {
        _luckyShot.enabled = enabled;
    }

    /// Chance BUYER has to win, the higher the chance the easier to win
    function setLuckyShotChance(uint16 chance) external onlyOwner {
        require(chance <= 65535, "Chance must be less than max settable");
        _luckyShot.chanceToWin = chance;
    }

    /// Minimum number of tokens accumulated in the POOL before the luckyShot can be triggered
    function setLuckyShotThreshold(uint128 minimumTokensAccumulated) external onlyOwner {
        _luckyShot.minimumPoolThreshold = minimumTokensAccumulated;
    }

    /// Amount of tokens needed to be spend by BUYER for CHANCE to win.
    function setLuckyShotMinimumSpend(uint64 minimumSpendAmount) external onlyOwner {
        _luckyShot.minimumSpendAmount = minimumSpendAmount;
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
        uint256 tokensMinusInitialSupport;

        unchecked {
            tokensMinusInitialSupport =
                _tokenBalance[address(this)] -
                _tokensForInitialSupport -
                _luckyShot.pool;
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
    function spendAvailableFunds(uint128 amount) external LockSwap onlyOwner {
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
        uint128 charityRate,
        uint128 marketingRate,
        uint128 buybackRate,
        uint128 liquidityRate,
        uint256 amount
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
        uint128 denominator = 100000;

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
            uint256 amountAvailable;
            uint256 tokensForInitialSupport = _tokensForInitialSupport;
            uint256 liquidtyFee = (amount * (liquidityRate * 1000)) / denominator;

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
     * 2: Buy LuckyShot Fee Rate
     * 3: Sell Charity/Marketing/Support Fee Rate
     * 4: Sell Reflection Fee Rate
     * 5: Sell LuckyShot Fee Rate
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

    function pancakePairAddress() external view returns (address) {
        return _pancakePair;
    }

    function pancakeRouterAddress() external view returns (address) {
        return address(_pancakeRouter);
    }

    function initialSupportFunds() external view returns (uint256) {
        return _tokensForInitialSupport;
    }

    // Conveniently displays actual token pool minus its decimal places
    function luckyShotTokens() external view returns (uint256) {
        return _luckyShot.pool / 10**9;
    }

    function projectFundsAvailable() external view returns (uint256) {
        return _tokenBalance[address(this)] - _tokensForInitialSupport - _luckyShot.pool;
    }

    function getTokenAmountFromReflection(uint256 amount)
        external
        view
        returns (uint256)
    {
        require(
            amount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        return amount / _getReflectionRate();
    }

    function getReflectionAmountFromToken(uint256 amount)
        external
        view
        returns (uint256 reflectedAmount)
    {
        reflectedAmount = amount * _getReflectionRate();
        require(
            reflectedAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
    }

    function totalReflectionsEarned() external view returns (uint256) {
        return _reflectionFeesEarned;
    }

    function name() external pure returns (string memory) {
        return "Hunger Token";
    }

    function symbol() external pure returns (string memory) {
        return "HNGR";
    }

    function decimals() external pure returns (uint256) {
        return 9;
    }

    function approveAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _verify(owner, spender);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _reflectionBalance[from] / _getReflectionRate() >= amount ||
                _tokenBalance[from] >= amount,
            "Balance must be greater than amount"
        );
        IsExcluded memory isExcludedFrom = _isExcluded[from];
        IsExcluded memory isExcludedTo = _isExcluded[to];
        uint256 antiWhaleRate = uint16(bytes2(_contractRates << 112));
        bool antiWhaleCheck = antiWhaleRate > 0 &&
            to != _pancakePair &&
            to != burnAddress &&
            to != address(this);
        uint256 reflectionFee;
        uint256 tokenFees;
        uint256 luckyShotFee;

        if (!_lockSwap) {
            uint256 tokensForSelling;

            if (!(isExcludedFrom.fromFee || isExcludedTo.fromFee)) {
                (
                    tokensForSelling,
                    reflectionFee,
                    luckyShotFee
                ) = _splitAndDetermineFees(from, to, amount, [isExcludedFrom, isExcludedFrom]);

                tokenFees = tokensForSelling + reflectionFee + luckyShotFee;
            }
        } // !_lockSwap

        /// Finish Transfer
        uint256 reflectionFeeWithRate = reflectionFee * _getReflectionRate();
        uint256 amountMinusFees = amount - tokenFees;

        if (!isExcludedFrom.fromReward) {
            _reflectionBalance[from] -= (amount * _getReflectionRate());
        } else if (isExcludedFrom.fromReward) {
            _tokenBalance[from] -= amount;
        }

        if (!isExcludedTo.fromReward) {
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
        } else if (isExcludedTo.fromReward) {
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

        if (!_lockSwap)
            _handleLuckyShot(from, to, luckyShotFee, amount);

        if (reflectionFeeWithRate > 0) {
            if (_reflectionTotal >= reflectionFeeWithRate)
                _reflectionTotal -= reflectionFeeWithRate;

            _reflectionFeesEarned += uint128(reflectionFee);
            emit TokensReflected(reflectionFee);
        }

        if (tokenFees > 0) {
            _tokenBalance[address(this)] += tokenFees - reflectionFee;
            emit Transfer(from, address(this), tokenFees - reflectionFee);
        }

        emit Transfer(from, to, amountMinusFees);
    }

    function _handleLuckyShot(
        address from,
        address to,
        uint256 luckyShotFee,
        uint256 amount
    ) private {
        LuckyShot memory luckyShot = _luckyShot;

        luckyShot.pool += luckyShotFee;

        /// BUYS Only, given a chance to win if spending above minimumSpendAmount
        if (
            luckyShot.enabled &&
            from == _pancakePair &&
            luckyShot.pool >= luckyShot.minimumPoolThreshold &&
            amount >= luckyShot.minimumSpendAmount
        ) {
            uint256 reward;
            uint256 luckyShotRewardsCollected = luckyShot.pool;

            // Generates a random number between 1 and 1000
            uint256 random = uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            luckyShot.nonce
                        )
                    )
                ) % 1000
            );
            luckyShot.lastRoll = random + 1;
            luckyShot.nonce++;

            if (luckyShot.lastRoll <= luckyShot.chanceToWin) {
                reward = luckyShotRewardsCollected;
            }

            if (reward > 0) {
                if (_isExcluded[to].fromReward) {
                    _tokenBalance[to] += luckyShotRewardsCollected;
                } else {
                    _reflectionBalance[to] +=
                        luckyShotRewardsCollected *
                        _getReflectionRate();
                }

                luckyShot.pool = 0;
                luckyShot.previousWinner = to;
                luckyShot.previousWinAmount = uint64(luckyShotRewardsCollected);
                luckyShot.previousWinTime = uint64(block.timestamp);
                emit LuckyShotWon(
                    uint64(luckyShotRewardsCollected),
                    uint64(block.timestamp),
                    to
                );

                _tokenBalance[address(this)] -= luckyShotRewardsCollected;
                emit Transfer(address(this), to, luckyShotRewardsCollected);
            }
        }

        _luckyShot = luckyShot;
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

    function _getReflectionRate() private view returns (uint256) {
        if (_reflectionTotal > _tokenSupply) {
            return _reflectionTotal / _tokenSupply;
        } else {
            return (_MAX - (_MAX % _tokenSupply)) / _tokenSupply;
        }
    }

    function _splitAndDetermineFees(
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
        ) = _getRates(from, to, isExcluded);

        if (tokensForSellRate > 0)
            tokensForSellFee = (amount * tokensForSellRate) / denominator;

        if (reflectionRate > 0)
            reflectionFee = (amount * reflectionRate) / denominator;

        if (luckyShotRate > 0)
            luckyShotFee = (amount * luckyShotRate) / denominator;
    }

    function _getRates(address from, address to, IsExcluded[2] memory isExcluded)
        private
        view
        returns (
            uint16 tokensForSellRate,
            uint16 reflectionRate,
            uint16 luckyShotRate
        )
    {
        bytes16 contractRates = _contractRates;

        if (isExcluded[0].forVendor || isExcluded[1].forVendor) {
            tokensForSellRate = 3000;
        } else {
            /// Buy
            if (from == _pancakePair) {
                tokensForSellRate = uint16(bytes2(contractRates));
                reflectionRate = uint16(bytes2(contractRates << 16));
                luckyShotRate = uint16(bytes2(contractRates << 32));

                /// Sell
            } else if (to == _pancakePair) {
                tokensForSellRate = uint16(bytes2(contractRates << 48));
                reflectionRate = uint16(bytes2(contractRates << 64));
                luckyShotRate = uint16(bytes2(contractRates << 80));
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