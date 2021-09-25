// SPDX-License-Identifier: X11

/*
                )      )          )
      *   )  ( /(   ( /(       ( /(
    ` )  /(  )\())  )\()) (    )\())
     ( )(_))((_)\ |((_)\  )\  ((_)\
    (_(_())   ((_)|_ ((_)((_)  _((_)
    |_   _|  / _ \| |/ / | __|| \| |
      | |   | (_) | ' <  | _| | .` |
      |_|    \___/ _|\_\ |___||_|\_|
    If you want to update to Project name and keep the cool "art" -- https://www.coolgenerator.com/ascii-text-generator
    ^ remove the comment with the link after

   Please check out our WhitePaper over at https://<ipfs-hosted-preferred|your-domain>
   to get an overview of our contract!

   Feel free to put any relevant PROJECT INFORMATION HERE
*/

pragma solidity ^0.8.7;

import "./ThirdParty.sol";

contract Token is Context, IERC20, Ownable {
    using Address for address;

    enum TransferType {
        Default,
        Buy,
        Sell,
        Excluded,
        Vendor
    }

    struct IsExcluded {
        bool fromFee;
        bool fromReward;
        bool forVendor;
    }

    TransferType private _transferType = TransferType.Default;
    bool private _lockSwap;

    bytes8 private _contractToggles;

    IPancakeRouter02 public immutable PancakeRouter;
    address public immutable PancakePair;

    address payable public _charityAddress =
        payable(0x0195966A6A66F581655A5c3AE19E17af83780D69);
    address payable public _marketingAddress =
        payable(0xF26d52Ba6F2A24C49220Aeb98c4a5b2ab28c715F);
    address public immutable _burnAddress =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _tokenBalance;
    mapping(address => uint256) private _reflectionBalance;
    mapping(address => IsExcluded) private _isExcluded;

    bytes32 private _contractFees;
    bytes32 private _contractRates;
    bytes32 private _feeTracker;
    bytes32 private _selfSupportTrackers;
    bytes32 private _contractReserves;

    uint24 private constant DENOMINATOR = 100000;
    uint64 private _tokensToBurnForSellSupport = 1000000000000000; // 1 Million Tokens
    uint64 private _minimumTokensForLiquidation = 1000000000000000; // 1 Million Tokens
    uint256 private _tokenSupply = 10**9 * 10**9;
    uint256 private constant _MAX = ~uint256(0);
    uint256 private _reflectionTotal;
    uint256 private _reflectionSupply;
    uint256 private _reflectionFeesEarned;

    event TokensReflected(uint256 tokensToSell);
    event BuybackTokens(uint256 bnbIn, uint256 tokensBought);
    event SendToWallet(string wallet, address walletAddress, uint256 bnbForLP);
    event SendTokensToContract(address from, uint256 tokens);
    event AddLiquidity(uint256 tokensIn, uint256 bnbIn, address path);
    event SwapTokensForBNB(uint256 amountIn, uint256 amountOut);
    event ContractFeatureToggled(uint8 index, uint8 value, bool enabled);
    event SetRate(uint8 subIndex, uint8 index, uint32 value);
    event TrackerUpdate(
        bytes32 tracker,
        uint128 oldValue,
        uint128 newValue,
        bool added
    );

    event Print(string name);
    event Print(string name, uint256 value);
    event Print(string name, bool value);

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
        PancakeRouter = pancakeRouter;
        PancakePair = pancakePair;

        // _isExcluded[address(this)].fromFee = true;
        _isExcluded[_marketingAddress].fromFee = true;
        _isExcluded[owner()].fromFee = true;

        _isExcluded[pancakePair].fromReward = true;
        _isExcluded[_marketingAddress].fromReward = true;
        _isExcluded[address(this)].fromReward = true;

        _tokenBalance[address(this)] = (_tokenSupply * 15000) / DENOMINATOR; // 15% of initial supply for support stream

        setTracker(1, 0, uint64((_tokenSupply * 10000) / DENOMINATOR), true);
        setTracker(1, 1, uint64((_tokenSupply * 5000) / DENOMINATOR), true);

        _tokenBalance[_marketingAddress] =
            _tokenSupply -
            _tokenBalance[address(this)];

        emit Transfer(address(0), address(this), _tokenBalance[address(this)]);
        emit Transfer(
            address(0),
            _marketingAddress,
            _tokenBalance[_marketingAddress]
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
        _transfer(from, to, amount);
        approveAllowance(
            from,
            _msgSender(),
            _allowances[from][_msgSender()] -= amount
        );

        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        approveAllowance(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
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

    function setTokenBurnAmount(uint64 amount) external onlyOwner {
        if (
            _tokenBalance[address(this)] >= amount &&
            getTokenFeeTracker(0) >= amount
        ) {
            _burn(amount);
        }
        _tokensToBurnForSellSupport = amount;
    }

    function setCharityAddress(address newAddress) external onlyOwner {
        _charityAddress = payable(newAddress);
    }

    function setMarketingAddress(address newAddress) external onlyOwner {
        _marketingAddress = payable(newAddress);
    }

    /**
     * Burn tokens via the self support funds
     * or any remaining tokens if internal token trackers are at 0
     */
    function internalBurn(uint256 amount) external onlyOwner {
        _verify(_msgSender(), _burnAddress);
        require(
            _tokenBalance[address(this)] >= amount,
            "Balance must be greater than amount"
        );

        if (getSelfSupportTracker(0) >= uint64(amount)) {
            _burn(amount);
            setTracker(1, 0, uint64(amount), false);
        } else if (
            getSelfSupportTracker(0) == 0 &&
            getSelfSupportTracker(1) == 0 &&
            getTokenFeeTracker(0) == 0 &&
            getTokenFeeTracker(1) == 0 &&
            getTokenFeeTracker(2) == 0 &&
            getTokenFeeTracker(3) == 0
        ) {
            _burn(amount);
        }
    }

    /**
     * Add tokens to burn or liquidity pool to Contract Self Support
     * 0 = Burn Tokens; 1 = Liquidity Support
     *
     * Self Support Tokens require getToggle(1) to be True
     */
    function addContractburnSupportTokens(uint8 index, uint256 amount)
        external
    {
        require(index <= 1, "Index too high");

        _verify(_msgSender(), _burnAddress);
        require(
            _reflectionBalance[_msgSender()] / getReflectionRate() >= amount ||
                _tokenBalance[_msgSender()] >= amount,
            "Balance must be greater than amount"
        );

        if (!_isExcluded[_msgSender()].fromReward) {
            _reflectionBalance[_msgSender()] -= amount * getReflectionRate();
        } else {
            _tokenBalance[_msgSender()] -= amount;
        }

        _tokenBalance[address(this)] += amount;

        setTracker(1, index, uint64(amount), true);
        emit Transfer(_msgSender(), address(this), amount);
    }

    /**
     * 0: Send Charity *Fee*
     * 1: Send Reflection *Fee*
     * 2: Buy Charity *Fee*
     * 3: Buy Reflection *Fee*
     * 4: Buy Marketing *Fee*
     * 5: Buy Support Stream *Fee*
     * 6: Sell Charity *Fee*
     * 7: Sell Reflection *Fee*
     * 8: Sell Marketing *Fee*
     * 9: Sell Support Stream *Fee*
     * 10: Anti Whale
     */
    function setFee(uint8 index, uint16 value) external onlyOwner {
        require(index <= 15, "index too high");
        require(value <= 6000, "Must be lower or equal to 6% (6000)");

        index = index * 16;

        _contractFees &= ~(bytes32(bytes2(~uint16(0))) >> index);
        _contractFees |= bytes32(bytes2(value)) >> index;

        emit SetRate(0, index, value);
    }

    /**
     * 0: Buy Buyback Burn Rate (0-100)
     * 1: Buy LP Rate (0-100)
     * 2: Sell Buyback Burn Rate (0-100)
     * 3: Sell LP Rate (0-100)
     * 4: Price Impact Trigger (0-)
     * 5: Minimum based on sell price before burning tokens* **
     * 6: Max amount to buy based on sell price*
     */
    function setRate(uint8 index, uint32 value) external onlyOwner {
        require(index <= 9, "index too high");
        if (index <= 3) require(value <= DENOMINATOR, "Value for rate too high");

        if (index == 0 || index == 1) {
            if (index == 0) {
                _setRate(0, value);
                _setRate(1, DENOMINATOR - value);
            } else {
                _setRate(0, DENOMINATOR - value);
                _setRate(1, value);
            }
        } else if (index == 2 || index == 3) {
            if (index == 2) {
                _setRate(2, value);
                _setRate(3, DENOMINATOR - value);
            } else {
                _setRate(2, DENOMINATOR - value);
                _setRate(3, value);
            }
        } else {
            _setRate(index, value);
        }
    }

    /**
     * 0: Anti Whale
     * 1: Contract Self Support
     * 2: Liquidation Support
     * 3: Buyback Tokens
     * 4: Burn Tokens
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

    /**
     * Locks the boolean forever; 2 = Disabled; 3 = Enabled
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
        _reflectionSupply += _tokenBalance[account];
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
            if (_reflectionTotal > _reflectionBalance[account])
                _reflectionTotal -= _reflectionBalance[account];

            if (_reflectionSupply > _tokenBalance[account])
                _reflectionSupply -= _tokenBalance[account];

            _reflectionBalance[account] = 0;
        }
        _isExcluded[account].fromReward = true;
    }

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

    function includeInFee(address account, uint8 listIndex) external onlyOwner {
        require(listIndex <= 1, "Index too high");

        if (listIndex == 0) {
            _isExcluded[account].fromFee = false;
        } else if (listIndex == 1) {
            _isExcluded[account].forVendor = false;
        }
    }

    function setDefaultFees() external onlyOwner {
        bytes32 contractFees;
        bytes32 contractRates;

        contractFees |= bytes32(bytes2(uint16(3000))) >> 0;
        contractFees |= bytes32(bytes2(uint16(3000))) >> 16;
        contractFees |= bytes32(bytes2(uint16(3000))) >> 32;
        contractFees |= bytes32(bytes2(uint16(3000))) >> 48;
        contractFees |= bytes32(bytes2(uint16(3000))) >> 64;
        contractFees |= bytes32(bytes2(uint16(3000))) >> 80;
        contractFees |= bytes32(bytes2(uint16(3000))) >> 96;
        contractFees |= bytes32(bytes2(uint16(4000))) >> 112;
        contractFees |= bytes32(bytes2(uint16(4000))) >> 128;
        contractFees |= bytes32(bytes2(uint16(5000))) >> 144;
        contractFees |= bytes32(bytes2(uint16(2000))) >> 160;

        contractRates |= bytes32(bytes4(uint32(34000))) >> 0;
        contractRates |= bytes32(bytes4(uint32(66000))) >> 32;
        contractRates |= bytes32(bytes4(uint32(60000))) >> 64;
        contractRates |= bytes32(bytes4(uint32(40000))) >> 96;
        contractRates |= bytes32(bytes4(uint32(5000))) >> 128;
        contractRates |= bytes32(bytes4(uint32(25000))) >> 160;
        contractRates |= bytes32(bytes4(uint32(50000))) >> 192;

        _contractFees = contractFees;
        _contractRates = contractRates;
    }

    function setDefaultToggles() external onlyOwner {
        bytes8 contractToggles;
        uint8 bits = 8;

        contractToggles |= bytes8(bytes1(uint8(1)));
        contractToggles |= bytes8(bytes1(uint8(1))) >> bits;
        contractToggles |= bytes8(bytes1(uint8(1))) >> (2 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (3 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (4 * bits);

        _contractToggles = contractToggles;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function totalSupply() external view override returns (uint256) {
        return _tokenSupply;
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

    /**
     * subIndex values:
     * 0: Contract Fees
     * 1: Contract sub-level fees (support stream)
     *
     * index0 values:
     * 0: Send Charity Fee
     * 1: Send Reflection Fee
     * 2: Buy Charity Fee
     * 3: Buy Reflection Fee
     * 4: Buy Marketing Fee
     * 5: Buy Support Stream Fee
     * 6: Sell Charity Fee
     * 7: Sell Reflection Fee
     * 8: Sell Marketing Fee
     * 9: Sell Support Stream Fee
     * 10: Anti Whale % based of total supply
     *
     * index1 values:
     * 0: Buy Buyback Burn Rate
     * 1: Buy LP Rate
     * 2: Sell Buyback Burn Rate
     * 3: Sell LP Rate
     * 4: Price Impact Trigger
     * 5: Minimum based on sell price before burning tokens
     * 6: Max amount to buy based on sell price
     */
    function getRate(uint8 subIndex, uint8 index)
        external
        view
        returns (uint32)
    {
        require(subIndex <= 1, "subIndex to high");

        if (subIndex == 1) {
            require(index <= 9, "index too high");

            return uint32(bytes4(_contractRates << (index * 32)));
        } else {
            require(index <= 15, "index too high");

            return uint16(bytes2(_contractFees << (index * 16)));
        }
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

    /**
     * Amount must contain trailing decimal places (9).
     * ex: 1000000001 = 1.000000001 Tokens
     * If liquidateNow is true it will try.
     */
    function setMinimumTokensForLiquidation(uint64 amount, bool liquidateNow)
        external
        onlyOwner
    {
        require(amount >= 3, "Amount must be 3 or more");
        if (!liquidateNow) {
            _minimumTokensForLiquidation = amount;
        } else {
            uint64 splitTokens = (amount / 3);
            uint64 charityTokensAvailable = getTokenFeeTracker(1);
            uint64 marketingTokensAvailable = getTokenFeeTracker(2);
            uint64 liquidityTokensAvailable = getTokenFeeTracker(3);
            uint256 initialBNB = address(this).balance;
            uint256 bnbReceived;

            if (
                charityTokensAvailable >= splitTokens &&
                marketingTokensAvailable >= splitTokens &&
                liquidityTokensAvailable >= splitTokens
            ) {
                uint64 LPTokenPairing = splitTokens / 2;
                setTracker(0, 1, splitTokens, false);
                setTracker(0, 2, splitTokens, false);
                setTracker(0, 3, splitTokens, false);

                approveAllowance(address(this), address(PancakeRouter), amount);

                // generate the Pancake pair path of token -> weth
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = PancakeRouter.WETH();

                // make the swap
                PancakeRouter
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        amount - LPTokenPairing,
                        0, // accept any amount of ETH
                        path,
                        address(this),
                        block.timestamp
                    );

                if (address(this).balance > initialBNB)
                    bnbReceived = address(this).balance - initialBNB;

                if (bnbReceived > 0) {
                    uint256 thirdsBnb = bnbReceived / 3;

                    PancakeRouter.addLiquidityETH{value: thirdsBnb}(
                        address(this),
                        LPTokenPairing,
                        0, //(tokensForLP * 49950) / DENOMINATOR,
                        0, //(bnbForLP * 49990) / DENOMINATOR,
                        address(this),
                        block.timestamp
                    );

                    emit AddLiquidity(LPTokenPairing, thirdsBnb, PancakePair);

                    (bool success, ) = _charityAddress.call{value: thirdsBnb}(
                        new bytes(0)
                    );

                    if (success)
                        emit SendToWallet(
                            "Charity",
                            _charityAddress,
                            thirdsBnb
                        );

                    (success, ) = _marketingAddress.call{value: thirdsBnb}(
                        new bytes(0)
                    );

                    if (success)
                        emit SendToWallet(
                            "Marketing",
                            _marketingAddress,
                            thirdsBnb
                        );
                }
            }
        }
    }

    function getMinimumbnbQuoteForSell() external view returns (uint128) {
        return _minimumTokensForLiquidation;
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

    /**
     * 0 & 2 = Disabled
     * 1 & 3 = Enabled
     * 2 & 3 are values meaning those toggles have been locked.
     */
    function getToggle(uint8 index) public view returns (bool) {
        uint8 currentValue = uint8(bytes1(_contractToggles << (index * 8)));
        return (currentValue == 1 || currentValue == 3) ? true : false;
    }

    /**
     * subIndex values:
     * 0: Fee Trackers
     * 1: Self Support Trackers
     *
     * Fee Tracker values:
     * 0: Tokens for Burning
     * 1: Tokens for Charity
     * 2: Tokens for Marketing
     * 3: Tokens for LP injection
     *
     * index1 values:
     * 0: Tokens for Burning (10% supplied to contract on deploy)
     * 1: Tokens for LP (5% supplied to contract on deploy)
     * 2: BNB for Buyback
     */
    function getTracker(uint8 subIndex, uint8 index)
        external
        view
        returns (uint128)
    {
        require(subIndex <= 1, "Index too high");

        if (subIndex == 0) {
            return getTokenFeeTracker(index);
        } else {
            if (index == 2) {
                return getSelfSupportTracker(index, true);
            } else {
                return getSelfSupportTracker(index);
            }
        }
    }

    function approveAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _verify(owner, spender);
        require(
            _tokenBalance[owner] >= amount ||
                _reflectionBalance[owner] >= amount,
            "Not enough initialTokens to allow"
        );

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
            _reflectionBalance[from] / getReflectionRate() >= amount ||
                _tokenBalance[from] >= amount,
            "Balance must be greater than amount"
        );

        if (_isExcluded[from].fromFee || _isExcluded[to].fromFee) {
            _transferType = TransferType.Excluded;
        } else if (_isExcluded[from].forVendor || _isExcluded[to].forVendor) {
            _transferType = TransferType.Vendor;
        } else if (to == PancakePair || from == PancakePair) {
            _transferType = to == PancakePair
                ? TransferType.Sell
                : TransferType.Buy;
        } else {
            _transferType = TransferType.Default;
        }

        /// Toggle 1 enables 10% given to contract on deploy for burning
        /// Self Support Tracker 0 is tokens allocated for burning
        uint64 supportTokensForBurnAvailable = getSelfSupportTracker(0);
        uint64 tokenFees;
        uint64 reflectionFee;
        bool burnSupport = getToggle(1) && supportTokensForBurnAvailable > 0;

        if (!_lockSwap && _transferType != TransferType.Excluded) {
            uint16 reflectionRate = uint16(bytes2(_contractFees << 16));
            if (_transferType == TransferType.Vendor) {
                reflectionRate = 1500;
            } else if (_transferType == TransferType.Buy) {
                reflectionRate = uint16(bytes2(_contractFees << 48));
            } else if (_transferType == TransferType.Sell) {
                reflectionRate = uint16(bytes2(_contractFees << 112));
            }

            if (reflectionRate > 0) {
                reflectionFee = (uint64(amount) * reflectionRate) / DENOMINATOR;
                tokenFees += reflectionFee;
            }

            if (
                burnSupport &&
                _transferType == TransferType.Sell &&
                _tokenBalance[address(this)] >= amount
            ) {
                // Burn support tokens allocated to contract
                if (supportTokensForBurnAvailable >= amount) {
                    _burn(amount);
                    setTracker(1, 0, uint64(amount), false);
                } else {
                    _burn(supportTokensForBurnAvailable);
                    setTracker(1, 0, supportTokensForBurnAvailable, false);
                }
            }

            (uint256 tokenA, uint256 tokenB, ) = IPancakePair(PancakePair)
                .getReserves();

            tokenFees += getFeesAndMaybeLiquidate(amount, tokenA, tokenB);

            uint64 tokensToBurn;
            if (
                getToggle(3) && _transferType != TransferType.Buy // Buyback Tokens
            ) {
                tokensToBurn = uint64(
                    maybeBuybackAndGetBurn(
                        amount - tokenFees,
                        tokenA,
                        tokenB,
                        burnSupport
                    )
                );
            }

            if (
                getToggle(4) && // Burn Tokens
                tokensToBurn > 0 &&
                _tokenBalance[address(this)] >= tokensToBurn
            ) {
                _burn(tokensToBurn);
            }
        }

        finishTransfer(from, to, tokenFees, reflectionFee, amount);
    }

    function maybeBuybackAndGetBurn(
        uint256 amount,
        uint256 tokenA,
        uint256 tokenB,
        bool burnSupport
    ) private LockSwap returns (uint64) {
        bool burnNow;
        uint64 tokensToBurn;
        uint64 initialTokens = uint64(_tokenBalance[address(this)]);
        uint128 bnbNeeded = uint128(
            PancakeRouter.getAmountOut(amount, tokenA, tokenB)
        );
        uint128 bnbAllocatedForBuyback = getSelfSupportTracker(2, true);
        uint128 bnbForBuy;
        uint128 minBuybackAmount = (bnbNeeded *
            (uint32(bytes4(_contractRates << 160)))) / DENOMINATOR;
        uint128 maxBuybackAmount = (bnbNeeded *
            (uint32(bytes4(_contractRates << 192)))) / DENOMINATOR;
        uint256 bnbBalance = address(this).balance;
        uint256 priceImpact = ((amount * 100000) / tokenA);

        // Trigger for buyback + possible burn
        if (priceImpact > uint32(bytes4(_contractRates << 128))) {
            if (
                getToggle(4) &&
                getTokenFeeTracker(0) >= _tokensToBurnForSellSupport && // Tokens allocated for burn
                initialTokens >= _tokensToBurnForSellSupport
            ) {
                tokensToBurn += _tokensToBurnForSellSupport;
                initialTokens -= _tokensToBurnForSellSupport;
                setTracker(0, 0, uint64(tokensToBurn), false);
            }

            if (
                bnbBalance >= minBuybackAmount &&
                bnbAllocatedForBuyback >= minBuybackAmount
            ) {
                if (bnbAllocatedForBuyback > maxBuybackAmount) {
                    bnbForBuy = maxBuybackAmount;
                } else {
                    bnbForBuy = bnbAllocatedForBuyback;
                }
            } else if (bnbBalance >= bnbNeeded) {
                bnbForBuy = bnbNeeded;

                if (getToggle(4)) burnNow = true;
            } else if (
                bnbAllocatedForBuyback < minBuybackAmount &&
                bnbBalance >= bnbAllocatedForBuyback
            ) {
                bnbForBuy = bnbAllocatedForBuyback;

                if (getToggle(4)) burnNow = true;
            }
        }

        uint64 tokensBought;

        if (bnbForBuy > 0 && bnbBalance > bnbForBuy) {
            buyTokens(bnbForBuy);

            if (_tokenBalance[address(this)] > initialTokens) {
                tokensBought =
                    uint64(_tokenBalance[address(this)]) -
                    initialTokens;

                emit BuybackTokens(bnbForBuy, tokensBought);
            }
        }

        if (burnNow && !burnSupport) {
            tokensToBurn += tokensBought;
        }

        if (!burnNow && tokensBought > 0) {
            setTracker(0, 0, uint64(tokensBought), true);
        }

        return tokensToBurn;
    }

    function buyTokens(uint128 bnbForBuy) private {
        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = PancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        PancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbForBuy
        }(
            0, // accept any amount of Tokens
            path,
            _burnAddress,
            block.timestamp
        );

        setTracker(1, 2, bnbForBuy, false);
    }

    function getBaseRates(uint256 amount)
        private
        view
        returns (
            uint16,
            uint16,
            uint64,
            uint64
        )
    {
        uint16 charityRate;
        uint16 marketingRate;

        if (_transferType == TransferType.Vendor) {
            charityRate = 1500;
        } else if (_transferType == TransferType.Default) {
            charityRate = uint16(bytes2(_contractFees));
        } else if (_transferType == TransferType.Buy) {
            charityRate = uint16(bytes2(_contractFees << 32));
            marketingRate = uint16(bytes2(_contractFees << 64));
        } else if (_transferType == TransferType.Sell) {
            charityRate = uint16(bytes2(_contractFees << 96));
            marketingRate = uint16(bytes2(_contractFees << 128));
        }

        return (
            charityRate,
            marketingRate,
            (uint64(amount) * charityRate) / DENOMINATOR,
            marketingRate > 0
                ? ((uint64(amount) * marketingRate) / DENOMINATOR)
                : 0
        );
    }

    function getSupportRates(uint256 amount)
        private
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint64,
            uint64,
            uint64
        )
    {
        uint32 supportStreamRate;
        uint32 buybackRate;
        uint32 liquidityRate;

        if (_transferType == TransferType.Buy) {
            supportStreamRate = uint16(bytes2(_contractFees << 80));
            buybackRate = uint32(bytes4(_contractRates));
            liquidityRate = uint32(bytes4(_contractRates << 32));
        } else if (_transferType == TransferType.Sell) {
            supportStreamRate = uint16(bytes2(_contractFees << 144));
            buybackRate = uint32(bytes4(_contractRates << 64));
            liquidityRate = uint32(bytes4(_contractRates << 96));
        }

        uint64 supportStreamFee;
        if (supportStreamRate > 0)
            supportStreamFee = uint64(
                (amount * supportStreamRate) / DENOMINATOR
            );

        return (
            supportStreamRate,
            buybackRate,
            liquidityRate,
            supportStreamFee,
            uint64((supportStreamFee * buybackRate) / DENOMINATOR),
            uint64((supportStreamFee * liquidityRate) / DENOMINATOR)
        );
    }

    function getFeesAndMaybeLiquidate(
        uint256 amount,
        uint256 tokenA,
        uint256 tokenB
    ) private LockSwap returns (uint64) {
        uint64 charityTokensAvailableToSell = getTokenFeeTracker(1);
        bool sellExtraTokens;

        (, , uint64 charityFee, uint64 marketingFee) = getBaseRates(amount);
        (, , , , uint64 buyBackFee, uint64 liquidityFee) = getSupportRates(
            amount
        );
        uint64 tokensToSell = charityFee;
        uint64 tokensForLP = liquidityFee;

        if (getToggle(2) && _transferType != TransferType.Buy) {
            /// Check against our setting `_minimumTokensForLiquidation` to see if we are selling extra tokens
            sellExtraTokens = liquidateExtraTokens();
            if (sellExtraTokens) tokensToSell += _minimumTokensForLiquidation;

            if (_transferType == TransferType.Sell) {
                tokensToSell += marketingFee;
                tokensToSell += buyBackFee;

                /// Tokens allocated for Liquidity Support (initial 5% given to contract)
                uint64 liquiditySupportTokens = getSelfSupportTracker(1);
                if (getToggle(1) && tokensForLP > 0) {
                    if (liquiditySupportTokens > tokensForLP) {
                        tokensForLP += liquidityFee;
                        setTracker(1, 1, liquidityFee, false);
                    } else {
                        tokensForLP += liquiditySupportTokens;
                        setTracker(1, 1, liquiditySupportTokens, false);
                    }
                    tokensToSell += (tokensForLP / 2);
                }

                uint256 bnbForExtraLiquidation;
                if (tokensToSell > 0) {
                    if (sellExtraTokens) {
                        // Get a BNB quote for the extra tokens we are liquidating outside of the normal transaction fees
                        bnbForExtraLiquidation = PancakeRouter.quote(
                            _minimumTokensForLiquidation,
                            tokenA,
                            tokenB
                        );
                    }

                    _tokenBalance[address(this)] +=
                        charityFee +
                        marketingFee +
                        buyBackFee +
                        liquidityFee;

                    sellTokensAndDistributeBNB(
                        amount,
                        tokensToSell,
                        bnbForExtraLiquidation,
                        false
                    );
                }
            } else if (tokensToSell > 0) {
                if (
                    charityTokensAvailableToSell >= _minimumTokensForLiquidation
                ) {
                    tokensToSell += _minimumTokensForLiquidation;
                }

                sellTokensAndDistributeBNB(amount, tokensToSell, 0, true);
            }

            if (tokensForLP > 0) {
                addLiquidity(tokensForLP / 2, tokenA, tokenB);
            }
        }

        if (
            _transferType != TransferType.Sell ||
            (_transferType == TransferType.Sell && !sellExtraTokens)
        ) {
            setTracker(0, 0, buyBackFee, true);
            setTracker(0, 1, charityFee, true);
            setTracker(0, 2, marketingFee, true);
            setTracker(0, 3, tokensForLP / 2, true);

            _tokenBalance[address(this)] +=
                charityFee +
                marketingFee +
                buyBackFee +
                tokensForLP;
        }

        return charityFee + marketingFee + buyBackFee + liquidityFee;
    }

    function liquidateExtraTokens() private returns (bool) {
        bool sellExtraTokens;
        uint64 splitTokens;
        uint64 supportTokenSplit;
        uint64 burnTokensAvailable = getTokenFeeTracker(0);
        uint64 charityTokensAvailable = getTokenFeeTracker(1);
        uint64 marketingTokensAvailable = getTokenFeeTracker(2);
        uint64 liquidityTokensAvailable = getTokenFeeTracker(3);

        if (_minimumTokensForLiquidation >= 3) {
            splitTokens = _minimumTokensForLiquidation / 3;
            supportTokenSplit = splitTokens / 2;
        }

        if (
            splitTokens > 0 &&
            charityTokensAvailable >= splitTokens &&
            marketingTokensAvailable >= splitTokens &&
            burnTokensAvailable >= supportTokenSplit &&
            liquidityTokensAvailable >= supportTokenSplit
        ) {
            setTracker(0, 0, supportTokenSplit, false); // Remove Tokens for Charity
            setTracker(0, 1, splitTokens, false); // Remove Tokens for Charity
            setTracker(0, 2, splitTokens, false); // Remove Tokens for Marketing
            setTracker(0, 3, supportTokenSplit, false); // Remove Tokens for LP
            sellExtraTokens = true;
        }

        return sellExtraTokens;
    }

    function sellTokensAndDistributeBNB(
        uint256 amount,
        uint256 tokensToSell,
        uint256 bnbForExtraLiquidation,
        bool onlyCharity
    ) private {
        approveAllowance(address(this), address(PancakeRouter), tokensToSell);
        uint256 initialBNB = address(this).balance;
        uint256 bnbReceived;

        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeRouter.WETH();

        // make the swap
        PancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSell,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        if (address(this).balance > initialBNB)
            bnbReceived = address(this).balance - initialBNB;

        if (bnbReceived > 0) {
            if (onlyCharity) {
                sendBNB(
                    amount,
                    bnbReceived,
                    0,
                    bnbForExtraLiquidation,
                    onlyCharity
                );
            } else {
                if (bnbReceived > bnbForExtraLiquidation) {
                    bnbReceived -= bnbForExtraLiquidation;
                }

                uint256 supportBNB = (bnbReceived * 41666) / DENOMINATOR;

                (, uint64 buybackRate, , , , ) = getSupportRates(amount);

                if (buybackRate > 0)
                    setTracker(
                        1,
                        2,
                        uint128((supportBNB * buybackRate) / DENOMINATOR),
                        true
                    );

                sendBNB(
                    amount,
                    bnbReceived,
                    supportBNB,
                    bnbForExtraLiquidation,
                    false
                );

                emit SwapTokensForBNB(tokensToSell, bnbReceived);
            }
        }
    }

    function sendBNB(
        uint256 amount,
        uint256 bnbReceived,
        uint256 supportBNB,
        uint256 bnbForExtraLiquidation,
        bool onlyCharity
    ) private {
        bool success;
        (uint16 charityRate, uint16 marketingRate, , ) = getBaseRates(amount);
        uint128 splitBNB;
        uint256 charityBNB;
        uint256 marketingBNB;

        /// Extract the extra BNB used from the extra tokens swapped
        if (
            bnbForExtraLiquidation >= 3 && bnbReceived > bnbForExtraLiquidation
        ) {
            // 3 Gwei to split at the lowest decimal evenly
            splitBNB = uint128(bnbForExtraLiquidation / 3);
        }

        if (onlyCharity) {
            charityBNB = bnbReceived;
        } else if (
            _transferType != TransferType.Buy && bnbReceived > supportBNB
        ) {
            if (splitBNB > 0) setTracker(1, 2, splitBNB, true);

            if (charityRate > 0)
                charityBNB =
                    (((bnbReceived - supportBNB) * charityRate) + splitBNB) /
                    DENOMINATOR;

            if (marketingRate > 0)
                marketingBNB =
                    (((bnbReceived - supportBNB) * marketingRate) + splitBNB) /
                    DENOMINATOR;

            if (marketingBNB > 0)
                (success, ) = _marketingAddress.call{value: marketingBNB}(
                    new bytes(0)
                );

            if (success)
                emit SendToWallet("Marketing", _marketingAddress, marketingBNB);
        }

        if (charityBNB > 0)
            (success, ) = _charityAddress.call{value: charityBNB}(new bytes(0));

        if (success) emit SendToWallet("Charity", _charityAddress, charityBNB);
    }

    function addLiquidity(
        uint128 tokensForLP,
        uint256 tokenA,
        uint256 tokenB
    ) private {
        approveAllowance(address(this), address(PancakeRouter), tokensForLP);

        uint256 bnbForLP = PancakeRouter.quote(tokensForLP, tokenA, tokenB);

        if (
            address(this).balance >= bnbForLP &&
            _tokenBalance[address(this)] >= getTokenFeeTracker(3) // Tokens saved in tracker for LP
        ) {
            PancakeRouter.addLiquidityETH{value: bnbForLP}(
                address(this),
                tokensForLP,
                0, //(tokensForLP * 49950) / DENOMINATOR,
                0, //(bnbForLP * 49990) / DENOMINATOR,
                address(this),
                block.timestamp
            );

            emit AddLiquidity(tokensForLP, bnbForLP, PancakePair);
        }
    }

    function finishTransfer(
        address from,
        address to,
        uint64 tokenFees,
        uint64 reflectionFee,
        uint256 amount
    ) private {
        uint256 amountMinusFees = amount - tokenFees;
        uint256 reflectionAmountEarned = amountMinusFees * getReflectionRate();

        if (!_isExcluded[from].fromReward) {
            _reflectionBalance[from] -= (amount * getReflectionRate());
        } else if (_isExcluded[from].fromReward) {
            _tokenBalance[from] -= amount;
        }

        if (!_isExcluded[to].fromReward) {
            _reflectionBalance[to] += reflectionAmountEarned;
        } else if (_isExcluded[to].fromReward) {
            _tokenBalance[to] += amountMinusFees;
        }

        if (getToggle(0)) {
            uint256 antiWhaleLimit = (_tokenSupply *
                uint16(bytes2(_contractFees << 160))) / DENOMINATOR;

            if (_transferType != TransferType.Sell)
                require(
                    _reflectionBalance[to] / getReflectionRate() <=
                        antiWhaleLimit &&
                        _tokenBalance[to] <= antiWhaleLimit,
                    "Receiver balance exceeds holder limit"
                );
        }

        /// Equals out the reflection total/supply since initially they are 0'd
        /// All tokens allocated at launch are given to a non-reward wallet so we will add rewards
        /// as tokens are sent to reward allowed wallets, reflection fee's will adjust the actual rate overall
        if (!_isExcluded[from].fromReward && _isExcluded[to].fromReward) {
            if (_reflectionTotal > amount) _reflectionTotal -= reflectionAmountEarned;
            if (_reflectionSupply > reflectionAmountEarned)
                _reflectionSupply -= amountMinusFees;
        } else if (
            _isExcluded[from].fromReward && !_isExcluded[to].fromReward
        ) {
            _reflectionTotal += reflectionAmountEarned;
            _reflectionSupply += amountMinusFees;
        }

        if (reflectionFee > 0) {
            uint256 reflectionFeeWithRate = reflectionFee * getReflectionRate();

            if (_reflectionTotal > reflectionFeeWithRate)
                _reflectionTotal -= reflectionFeeWithRate;

            _reflectionFeesEarned += reflectionFee;
            emit TokensReflected(reflectionFee);
        }

        if (tokenFees > 0) emit Transfer(from, address(this), tokenFees);
        emit Transfer(from, to, amountMinusFees);
    }

    function _burn(uint256 amount) private {
        uint256 reflectionAmount = amount * getReflectionRate();

        if (_reflectionTotal >= reflectionAmount)
            _reflectionTotal -= reflectionAmount;
        if (_reflectionSupply >= amount) _reflectionSupply -= amount;

        _tokenSupply -= amount;
        _tokenBalance[address(this)] -= amount;
        _tokenBalance[_burnAddress] += amount;

        emit Transfer(address(this), _burnAddress, amount);
    }

    /// Sets internal trackers used to keep track of which tokens are being used where.
    function setTracker(
        uint8 subIndex,
        uint8 index,
        uint128 value,
        bool add
    ) private {
        bytes32 tracker = subIndex == 0 ? _feeTracker : _selfSupportTrackers;
        bool bnbTracker = subIndex == 1 && index == 2;
        index *= 64;

        uint128 oldValue = bnbTracker
            ? uint128(bytes16(tracker << index))
            : uint64(bytes8(tracker << index));
        uint128 newValue;
        if (add) {
            newValue = oldValue + value;
        } else if (oldValue >= value) {
            newValue = oldValue - value;
        } else if (oldValue < value) {
            newValue = 0;
        }

        if (!bnbTracker) {
            tracker &= ~(bytes32(bytes8(~uint64(0))) >> index);
            tracker |= bytes32(bytes8(uint64(newValue))) >> index;
        } else {
            tracker &= ~(bytes32(bytes16(~uint128(0))) >> index);
            tracker |= bytes32(bytes16(uint128(newValue))) >> index;
        }

        if (subIndex == 0) {
            _feeTracker = tracker;
        } else if (subIndex == 1) {
            _selfSupportTrackers = tracker;
        }

        emit TrackerUpdate(tracker, oldValue, newValue, add);
    }

    function _setRate(uint8 index, uint32 value) private {
        index *= 32;

        _contractRates &= ~(bytes32(bytes4(~uint32(0))) >> index);
        _contractRates |= bytes32(bytes4(value)) >> index;

        emit SetRate(1, index, value);
    }

    function getReflectionRate() private view returns (uint256) {
        uint256 reflectionTotal = _reflectionTotal;
        uint256 reflectionSupply = _reflectionSupply;

        if (
            reflectionTotal <= reflectionSupply ||
            reflectionTotal < 1 ||
            reflectionSupply < 1
        ) {
            reflectionSupply = 10**9 * 10**9;
            reflectionTotal = (_MAX - (_MAX % _tokenSupply));
        }

        return reflectionTotal / reflectionSupply;
    }

    function getTokenFeeTracker(uint8 index) private view returns (uint64) {
        return uint64(bytes8(_feeTracker << (index * 64)));
    }

    function getSelfSupportTracker(uint8 index) private view returns (uint64) {
        return uint64(bytes8(_selfSupportTrackers << (index * 64)));
    }

    function getSelfSupportTracker(
        uint8 index,
        bool //isBnb
    ) private view returns (uint128) {
        return uint128(bytes16(_selfSupportTrackers << (index * 64)));
    }

    function _verify(address from, address to) private pure {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
    }
}