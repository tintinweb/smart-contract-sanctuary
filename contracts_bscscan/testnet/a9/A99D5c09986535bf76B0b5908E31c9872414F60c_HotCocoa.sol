// SPDX-License-Identifier: X11

/*
    ██╗  ██╗ ██████╗ ████████╗ ██████╗ ██████╗  ██████╗ ██████╗  █████╗
    ██║  ██║██╔═══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔════╝██╔═══██╗██╔══██╗
    ███████║██║   ██║   ██║   ██║     ██║   ██║██║     ██║   ██║███████║
    ██╔══██║██║   ██║   ██║   ██║     ██║   ██║██║     ██║   ██║██╔══██║
    ██║  ██║╚██████╔╝   ██║   ╚██████╗╚██████╔╝╚██████╗╚██████╔╝██║  ██║
    ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝

    If you want to update to Project name and keep the cool "art" -- https://www.coolgenerator.com/ascii-text-generator
    ^ remove the comment with the link after

   Please check out our WhitePaper over at https://<ipfs-hosted-preferred|your-domain>
   to get an overview of our contract!

   Feel free to put any relevant PROJECT INFORMATION HERE
*/

pragma solidity ^0.8.9;

import "./ThirdParty.sol";

contract HotCocoa is Context, IERC20, Ownable {
    using Address for address;

    enum SellOperation {
        None,
        SellAndSend,
        Liquidity
    }

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

    struct Trackers {
        uint128 tokensForInitialSupport;
        uint128 tokensForSelling;
        uint128 tokensForLiquidity;
        uint128 bnbForCharity;
        uint128 bnbForMarketing;
        uint128 bnbForBuyback;
        uint128 bnbForLiquidity;
    }

    bool private _lockSwap;

    bytes8 private _contractToggles;

    uint24 private constant DENOMINATOR = 100000;
    uint64 private _tokenSellTriggerAmount = 1000000000000; // 1000 Tokens
    uint64 private _bnbSendAndLiquifyAmount = 1000000000000000000; // 1 BNB
    uint128 private constant _MAX = ~uint128(0);
    uint128 private _tokenSupply = 10**9 * 10**9;
    uint128 private _reflectionTotal = (_MAX - (_MAX % _tokenSupply));
    uint128 private _reflectionFeesEarned;

    address private immutable _pancakePair;
    address public immutable _burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public _charityAddress =
        payable(0xf54Bf63f4940dc775e55dAa4ca33e342E2A87551);
    address payable public _marketingAddress =
        payable(0xF26d52Ba6F2A24C49220Aeb98c4a5b2ab28c715F);

    mapping(address => mapping(address => uint128)) private _allowances;
    mapping(address => uint128) private _tokenBalance;
    mapping(address => uint128) private _reflectionBalance;
    mapping(address => IsExcluded) private _isExcluded;
    bytes32[3] private _contractRates;

    IPancakeRouter02 private immutable _pancakeRouter;
    SellOperation private _sellOperation = SellOperation.None;
    Trackers private _trackers;

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

        _isExcluded[_marketingAddress].fromFee = true;
        _isExcluded[owner()].fromFee = true;

        _isExcluded[pancakePair].fromReward = true;
        _isExcluded[_burnAddress].fromReward = true;
        _isExcluded[_marketingAddress].fromReward = true;
        _isExcluded[address(this)].fromReward = true;

        uint128 initialSupportTokens = (_tokenSupply * 15000) / DENOMINATOR;
        _trackers.tokensForInitialSupport = uint64(initialSupportTokens);

        _tokenBalance[address(this)] = initialSupportTokens; // 15% of initial supply
        _tokenBalance[_marketingAddress] = _tokenSupply - initialSupportTokens;

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

    /**
     * Add tokens to burn or liquidity pool to Contract Self Support
     *
     * Self Support Tokens require _getToggle(1) to be Enabled (true)
     * for these tokens to be applied internally
     */
    function addContractSupportTokens(uint128 amount) external {
        _verify(_msgSender(), _burnAddress);

        if (!_isExcluded[_msgSender()].fromReward) {
            require(
                _reflectionBalance[_msgSender()] / getReflectionRate() >=
                    amount,
                "Balance must be greater than amount"
            );

            _reflectionBalance[_msgSender()] -= amount * getReflectionRate();
        } else {
            require(
                _tokenBalance[_msgSender()] >= amount,
                "Balance must be greater than amount"
            );

            _tokenBalance[_msgSender()] -= amount;
        }

        _tokenBalance[address(this)] += amount;

        /// In the tracker 2 is for Burn, 3 is for Support
        _trackers.tokensForInitialSupport += uint64(amount);
        emit Transfer(_msgSender(), address(this), amount);
    }

    function setBNBSendAndLiquifyAmount(uint64 amount) external onlyOwner {
        _bnbSendAndLiquifyAmount = amount;
    }

    function setTokenSellTriggerAmount(uint64 amount) external onlyOwner {
        _tokenSellTriggerAmount = amount;
    }

    function setCharityAddress(address newAddress) external onlyOwner {
        _charityAddress = payable(newAddress);
    }

    function setMarketingAddress(address newAddress) external onlyOwner {
        _marketingAddress = payable(newAddress);
    }

    /**
     * Low end rates used internally and capped at 6%
     *
     * 0: Send Charity Rate
     * 1: Send Reflection Rate
     * 2: Buy Charity Rate
     * 3: Buy Reflection Rate
     * 4: Buy Marketing Rate
     * 5: Buy Support Stream Rate
     * 6: Sell Charity Rate
     * 7: Sell Reflection Rate
     * 8: Sell Marketing Rate
     * 9: Sell Support Stream Rate
     * 10: Anti Whale Rate
     */
    function setRateIndexZero(uint8 index, uint16 value) external onlyOwner {
        require(index <= 15, "index too high"); // Instead of lowering bytes32 it can allow up to index 15
        require(value <= 6000, "Must be lower or equal to 6% (6000)");
        bytes32[3] storage contractRates = _contractRates;

        contractRates[0] &= ~(bytes32(bytes2(~uint16(0))) >> (index * 16));
        contractRates[0] |= bytes32(bytes2(value)) >> (index * 16);

        emit SetRate(0, index, value);
    }

    /**
     * Index 0, 1 and 2, 3 are linked to match 100%
     *
     * 0: Buy Buyback Burn Rate (0-100)
     * 1: Buy LP Rate (0-100)
     * 2: Sell Buyback Burn Rate (0-100)
     * 3: Sell LP Rate (0-100)
     * 4: Price Impact Trigger
     * 5: Minimum based on sell price before burning tokens
     * 6: Max amount to buy based on sell price
     * 7: Time in seconds before sending/adding LP again
     */
    function setRateIndexOne(uint8 index, uint32 value) external onlyOwner {
        require(index <= 9, "index too high");
        if (index <= 3)
            require(value <= DENOMINATOR, "Value for rate too high");

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

    /// Rates used for dividing tokens/bnb during sells/sends
    function setRateIndexTwo(
        uint32 charityRate,
        uint32 marketingRate,
        uint32 buybackRate,
        uint32 liquidityRate
    ) external onlyOwner {
        bytes32[3] storage contractRates = _contractRates;

        contractRates[2] &= ~(bytes12(~uint96(0)));
        contractRates[2] |= bytes12(bytes4(charityRate));
        contractRates[2] |= bytes12(bytes4(marketingRate)) >> 32;
        contractRates[2] |= bytes12(bytes4(buybackRate)) >> 64;
        contractRates[2] |= bytes12(bytes4(liquidityRate)) >> 96;
    }

    /**
     * 0: Anti Whale
     * 1: 15% Support Funds
     * 2: Sell Tokens
     * 3: Send BNB
     * 4: Add Liquidity
     * 5: Buyback Tokens
     * 6: Burn Tokens
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

    /// Initial Burn rate based off token sell amount (default: 50000 (50%))
    function setInitialBurnRate(uint32 burnRate) external onlyOwner {
        require(
            burnRate > 0,
            "Can not set burnrate to 0, turn off toggle 1 instead"
        );

        _setRate(7, burnRate);
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
     * @param listIndex Must be 0 or 1.  0 = 0 fee list; 1 = 3% vendor list
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
        bytes32[3] storage contractRates = _contractRates;

        contractRates[0] &= ~bytes32(~uint256(0));
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 0;
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 16;
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 32;
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 48;
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 64;
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 80;
        contractRates[0] |= bytes32(bytes2(uint16(3000))) >> 96;
        contractRates[0] |= bytes32(bytes2(uint16(4000))) >> 112;
        contractRates[0] |= bytes32(bytes2(uint16(4000))) >> 128;
        contractRates[0] |= bytes32(bytes2(uint16(5000))) >> 144;
        contractRates[0] |= bytes32(bytes2(uint16(2000))) >> 160;

        contractRates[1] &= ~bytes32(~uint256(0));
        contractRates[1] |= bytes32(bytes4(uint32(34000))) >> 0;
        contractRates[1] |= bytes32(bytes4(uint32(66000))) >> 32;
        contractRates[1] |= bytes32(bytes4(uint32(60000))) >> 64;
        contractRates[1] |= bytes32(bytes4(uint32(40000))) >> 96;
        contractRates[1] |= bytes32(bytes4(uint32(5000))) >> 128;
        contractRates[1] |= bytes32(bytes4(uint32(25000))) >> 160;
        contractRates[1] |= bytes32(bytes4(uint32(50000))) >> 192;
        contractRates[1] |= bytes32(bytes4(uint32(50000))) >> 224;

        contractRates[2] &= ~bytes16(~uint128(0));
        contractRates[2] |= bytes16(bytes4(uint32(28570)));
        contractRates[2] |= bytes16(bytes4(uint32(33330))) >> 32;
        contractRates[2] |= bytes16(bytes4(uint32(19050))) >> 64;
        contractRates[2] |= bytes16(bytes4(uint32(19050))) >> 96;

        bytes8 contractToggles = bytes8(bytes1(uint8(1)));
        uint8 bits = 8;
        contractToggles |= bytes8(bytes1(uint8(1))) >> bits;
        contractToggles |= bytes8(bytes1(uint8(1))) >> (2 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (3 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (4 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (5 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (6 * bits);

        _contractToggles = contractToggles;
    }

    /**
     * Burn tokens via the self support funds
     * or any remaining tokens if internal token trackers are at 0
     */
    function internalBurn(uint128 amount) external onlyOwner {
        _verify(_msgSender(), _burnAddress);
        require(
            _tokenBalance[address(this)] >= amount,
            "Balance must be greater than amount"
        );
        Trackers storage trackers = _trackers;

        if (uint128(trackers.tokensForInitialSupport) >= amount) {
            _burn(amount);
            trackers.tokensForInitialSupport -= uint64(amount);
        } else if (
            /// Check all token counters, if 0 and tokens in contract we can burn
            trackers.tokensForInitialSupport == 0 &&
            trackers.tokensForSelling == 0 &&
            trackers.tokensForLiquidity == 0
        ) {
            _burn(amount);
        }
    }

    /// Sell tokens and send bnb to wallets
    function swapTokensForBNBAndSend(uint128 amount) public LockSwap onlyOwner {
        Trackers memory trackers = _trackers;
        require(
            trackers.tokensForSelling >= amount,
            "Not enough tokens allowed for swapping"
        );

        bytes32 contractRatesTwo = _contractRates[2];

        uint32 liquidityRate = uint32(bytes4(contractRatesTwo << 96));
        uint128 liquidityFee;
        if (liquidityRate > 0) {
            liquidityFee = (amount * liquidityRate) / DENOMINATOR;

            trackers.tokensForLiquidity -= liquidityFee;
        }

        trackers.tokensForSelling -= amount;

        trackers = _setBNBTrackers(
            false,
            _sellTokensForBNB(amount),
            trackers,
            contractRatesTwo
        );

        trackers = _sendBNB(trackers);

        _trackers = trackers;
    }

    /// Uses available BNB from Liquidity Tracker to try and inject LP
    function addLiquidity() external LockSwap onlyOwner {
        Trackers memory trackers = _trackers;
        (uint128 tokenA, uint128 tokenB) = getReserves();

        trackers = _addLiquidity(trackers, tokenA, tokenB);

        _trackers = trackers;
    }

    /**
     * Index values:
     * 0: Add amount to initial support stream (15% stream)
     * 1: Burn amount directly
     * 2: Sell amount of tokens and split using sell rates
     */
    function useUnallocatedTokens(uint8 index, uint128 amount)
        external
        LockSwap
        onlyOwner
    {
        require(index <= 2, "Index must be 0-2");
        Trackers storage trackers = _trackers;
        int128 unallocatedTokenCheck = int128(_tokenBalance[address(this)]) -
            int128(trackers.tokensForInitialSupport) -
            int128(trackers.tokensForSelling) -
            int128(trackers.tokensForLiquidity);

        require(
            unallocatedTokenCheck > 0 &&
                uint128(unallocatedTokenCheck) >= amount,
            "Not enough Unallocated tokens"
        );
        if (index == 0) {
            trackers.tokensForInitialSupport += amount;
        } else if (index == 1) {
            _burn(amount);
        } else if (index == 2) {
            swapTokensForBNBAndSend(amount);
        }
    }

    /**
     * Index values:
     * 0: Split the amount and send to charity/marketing
     * 1: Buyback and burn
     * 2: Use amount to check for availble tokens and inject LP
     */
    function useUnallocatedBNB(uint8 index, uint128 amount)
        external
        LockSwap
        onlyOwner
    {
        require(index <= 2, "Index must be 0-2");
        Trackers storage trackers = _trackers;
        int128 unallocatedBNBCheck = int128(uint128(address(this).balance)) -
            int128(trackers.bnbForCharity) -
            int128(trackers.bnbForMarketing) -
            int128(trackers.bnbForBuyback) -
            int128(trackers.bnbForLiquidity);

        require(
            unallocatedBNBCheck > 0 && uint128(unallocatedBNBCheck) >= amount,
            "Not enough Unallocated BNB"
        );

        (uint128 tokenA, uint128 tokenB) = getReserves();

        if (index == 0) {
            bool success;
            uint128 splitAmount = amount / 2;

            (success, ) = _charityAddress.call{value: splitAmount}(
                new bytes(0)
            );

            if (success)
                emit SendToWallet("Charity", _charityAddress, splitAmount);

            (success, ) = _marketingAddress.call{value: splitAmount}(
                new bytes(0)
            );

            if (success)
                emit SendToWallet("Marketing", _marketingAddress, splitAmount);
        } else if (index == 1) {
            _buyTokensAndBurn(amount);
        } else if (index == 2) {
            _addLiquidity(trackers, tokenA, tokenB);
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

    function getRatesIndexZero() external view returns (uint16[11] memory) {
        bytes32[3] memory contractRates = _contractRates;

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
                uint16(bytes2(contractRates[0] << 144)),
                uint16(bytes2(contractRates[0] << 160))
            ]
        );
    }

    function getRatesIndexOne() external view returns (uint32[8] memory) {
        bytes32[3] memory contractRates = _contractRates;

        return [
            uint32(bytes4(contractRates[1])),
            uint32(bytes4(contractRates[1] << 32)),
            uint32(bytes4(contractRates[1] << 64)),
            uint32(bytes4(contractRates[1] << 96)),
            uint32(bytes4(contractRates[1] << 128)),
            uint32(bytes4(contractRates[1] << 160)),
            uint32(bytes4(contractRates[1] << 192)),
            uint32(bytes4(contractRates[1] << 224))
        ];
    }

    function getRatesIndexTwo() external view returns (uint32[4] memory) {
        bytes32[3] memory contractRates = _contractRates;

        return [
            uint32(bytes4(contractRates[2])),
            uint32(bytes4(contractRates[2] << 32)),
            uint32(bytes4(contractRates[2] << 64)),
            uint32(bytes4(contractRates[2] << 96))
        ];
    }

    function getPancakePairAddress() external view returns (address) {
        return _pancakePair;
    }

    function getPancakeRouterAddress() external view returns (address) {
        return address(_pancakeRouter);
    }

    function getTokenSellTriggerAmount() external view returns (uint128) {
        return _tokenSellTriggerAmount;
    }

    function getBNBSendAndLiquifyAmount() external view returns (uint128) {
        return _bnbSendAndLiquifyAmount;
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
     *
     * 2 & 3 are values that have been locked forever in this state.
     */
    function getToggleValue() external view returns (uint8[7] memory) {
        bytes8 toggles = _contractToggles;

        return [
            uint8(bytes1(toggles)),
            uint8(bytes1(toggles << 8)),
            uint8(bytes1(toggles << 16)),
            uint8(bytes1(toggles << 24)),
            uint8(bytes1(toggles << 32)),
            uint8(bytes1(toggles << 40)),
            uint8(bytes1(toggles << 48))
        ];
    }

    /// Values tracking Tokens/BNB for internal functions
    function getTrackers() external view returns (uint128[7] memory) {
        Trackers memory trackers = _trackers;

        return [
            trackers.tokensForInitialSupport,
            trackers.tokensForSelling,
            trackers.tokensForLiquidity,
            trackers.bnbForCharity,
            trackers.bnbForMarketing,
            trackers.bnbForBuyback,
            trackers.bnbForLiquidity
        ];
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
        uint128 tokenFees;
        uint128 reflectionFee;
        address pancakePair = _pancakePair;
        Trackers memory trackers = _trackers;
        bytes32[3] memory contractRates = _contractRates;

        if (!_lockSwap) {
            TransferType transferType = _getTransferType(from, to, pancakePair);

            if (
                _getToggle(toggles, 1) && to == pancakePair /// 15% Support Burn Ttoggle
            ) {
                trackers = _initialSupportBurn(
                    trackers,
                    amount,
                    contractRates[1]
                );
            }

            if (transferType != TransferType.Excluded) {
                uint128 charityFee;
                uint128 marketingFee;
                uint128 supportFee;

                (
                    charityFee,
                    reflectionFee,
                    marketingFee,
                    supportFee
                ) = _getInitialFees(amount, transferType);

                tokenFees =
                    charityFee +
                    reflectionFee +
                    marketingFee +
                    supportFee;

                if (tokenFees > 0) {
                    trackers = _setTokenTrackers(
                        trackers,
                        charityFee,
                        marketingFee,
                        supportFee,
                        transferType
                    );
                }

                if (to == pancakePair) {
                    _handleOperations(toggles, trackers, amount, contractRates);
                }
            } // _transferType != TransferType.Excluded
        } // !_lockSwap

        bool antiWhaleCheck = _getToggle(toggles, 0) &&
            to != pancakePair &&
            to != _burnAddress &&
            to != address(this);

        _trackers = trackers;

        finishTransfer(
            antiWhaleCheck,
            from,
            to,
            amount,
            tokenFees,
            reflectionFee,
            contractRates[0]
        );
    }

    function _initialSupportBurn(
        Trackers memory trackers,
        uint128 amount,
        bytes32 contractRatesOne
    ) private returns (Trackers memory) {
        if (
            _tokenBalance[address(this)] >= amount &&
            trackers.tokensForInitialSupport >= amount
        ) {
            uint128 amountToBurn = (amount *
                uint32(bytes4(contractRatesOne << 224))) / DENOMINATOR;

            // Burn support tokens allocated to contract
            if (trackers.tokensForInitialSupport >= amountToBurn) {
                _burn(amountToBurn);
                trackers.tokensForInitialSupport -= amountToBurn;
            } else {
                _burn(trackers.tokensForInitialSupport);
                trackers.tokensForInitialSupport -= trackers
                    .tokensForInitialSupport;
            }
        }

        return trackers;
    }

    function _handleOperations(
        bytes8 toggles,
        Trackers memory trackers,
        uint128 amount,
        bytes32[3] memory contractRates
    ) private LockSwap {
        uint64 tokensToSell = _tokenSellTriggerAmount;
        uint128 tokensAvailable = trackers.tokensForSelling;
        SellOperation sellOperation = _sellOperation;

        if (
            _getToggle(toggles, 3) && /// Sell Tokens Toggle
            tokensAvailable >= tokensToSell &&
            _tokenBalance[address(this)] >= tokensToSell &&
            sellOperation == SellOperation.None
        ) {
            sellOperation = SellOperation.SellAndSend;

            trackers = _prepAndSellTokens(
                _getToggle(toggles, 2),
                trackers,
                tokensToSell,
                contractRates[2]
            );

            /// Send BNB Toggle
            if (_getToggle(toggles, 4)) trackers = _sendBNB(trackers);
        }

        (uint128 tokenA, uint128 tokenB) = getReserves();

        if (
            /// Add Liquidity
            _getToggle(toggles, 5) && sellOperation == SellOperation.Liquidity
        ) {
            trackers = _addLiquidity(trackers, tokenA, tokenB);
        }

        if (
            _getToggle(toggles, 6) /// Buyback/burn Tokens
        ) {
            trackers = _maybeBuybackAndBurn(
                amount,
                tokenA,
                tokenB,
                trackers,
                contractRates[1]
            );
        }

        setNextOperation(sellOperation);
    }

    function getReserves()
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

    function _prepAndSellTokens(
        bool addExtraLPSupport,
        Trackers memory trackers,
        uint128 tokensToSell,
        bytes32 contractRatesTwo
    ) private returns (Trackers memory) {
        uint32 liquidityRate = uint32(bytes4(contractRatesTwo << 96));
        uint128 liquidityFee;
        if (liquidityRate > 0) {
            liquidityFee = ((tokensToSell * liquidityRate) / DENOMINATOR) / 2;
            tokensToSell -= liquidityFee;
            trackers.tokensForLiquidity += liquidityFee;
        }

        trackers.tokensForSelling -= tokensToSell;

        if (addExtraLPSupport && trackers.tokensForInitialSupport > 0) {
            uint128 tokensForLP;

            if (trackers.tokensForInitialSupport >= liquidityFee) {
                tokensForLP += liquidityFee;
            } else {
                tokensForLP += (trackers.tokensForInitialSupport / 2);
            }

            if (tokensForLP > 0) {
                trackers.tokensForInitialSupport -= (tokensForLP * 2);
                trackers.tokensForLiquidity += tokensForLP;
                tokensToSell += tokensForLP;
            }
        }

        trackers = _setBNBTrackers(
            addExtraLPSupport,
            _sellTokensForBNB(tokensToSell),
            trackers,
            contractRatesTwo
        );

        return trackers;
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

    function _sendBNB(Trackers memory trackers)
        private
        returns (Trackers memory)
    {
        bool success;
        uint128 charityBNB = trackers.bnbForCharity;
        uint128 marketingBNB = trackers.bnbForMarketing;

        if (charityBNB > 0 && address(this).balance >= charityBNB) {
            (success, ) = _charityAddress.call{value: charityBNB}(new bytes(0));

            if (success) {
                trackers.bnbForCharity -= charityBNB;

                emit SendToWallet("Charity", _charityAddress, charityBNB);
            }
        }

        if (marketingBNB > 0 && address(this).balance >= marketingBNB) {
            (success, ) = _marketingAddress.call{value: marketingBNB}(
                new bytes(0)
            );
            if (success) {
                trackers.bnbForMarketing -= marketingBNB;

                emit SendToWallet("Marketing", _marketingAddress, marketingBNB);
            }
        }

        return trackers;
    }

    function _maybeBuybackAndBurn(
        uint128 amount,
        uint256 tokenA,
        uint256 tokenB,
        Trackers memory trackers,
        bytes32 contractRatesOne
    ) private returns (Trackers memory) {
        uint128 bnbNeeded = uint128(
            _pancakeRouter.getAmountOut(amount, tokenA, tokenB)
        );
        uint128 bnbAllocatedForBuyback = trackers.bnbForBuyback;
        uint128 bnbForBuy;
        uint24 denominator = DENOMINATOR;
        uint128 minBuybackAmount = (bnbNeeded *
            (uint32(bytes4(contractRatesOne << 160)))) / denominator;
        uint128 maxBuybackAmount = (bnbNeeded *
            (uint32(bytes4(contractRatesOne << 192)))) / denominator;
        uint256 priceImpact = ((amount * denominator) / tokenA);

        // Trigger for buyback + possible burn
        if (priceImpact >= uint32(bytes4(contractRatesOne << 128))) {
            emit PriceImpact(priceImpact, amount);
            if (bnbAllocatedForBuyback >= minBuybackAmount) {
                if (bnbAllocatedForBuyback > maxBuybackAmount) {
                    bnbForBuy = maxBuybackAmount;
                } else {
                    bnbForBuy = bnbAllocatedForBuyback;
                }

                if (address(this).balance >= bnbForBuy) {
                    trackers.bnbForBuyback -= bnbForBuy;

                    _buyTokensAndBurn(bnbForBuy);
                }
            }
        }

        return trackers;
    }

    /// Buys tokens and immediately sends them to the burn address
    function _buyTokensAndBurn(uint128 bnbForBuy) private {
        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbForBuy
        }(
            0, // accept any amount of Tokens
            path,
            _burnAddress,
            block.timestamp
        );

        emit BuybackTokens(bnbForBuy);
    }

    function _addLiquidity(
        Trackers memory trackers,
        uint256 tokenA,
        uint256 tokenB
    ) private returns (Trackers memory) {
        uint128 liquidityBNB = trackers.bnbForLiquidity;
        uint128 liquidityTokensAvailable = trackers.tokensForLiquidity;
        uint128 tokenQuote = uint128(
            _pancakeRouter.quote(liquidityBNB, tokenB, tokenA)
        );

        if (
            address(this).balance >= liquidityBNB &&
            _tokenBalance[address(this)] >= liquidityTokensAvailable &&
            liquidityTokensAvailable >= tokenQuote
        ) {
            _pancakeRouter.addLiquidityETH{value: liquidityBNB}(
                address(this),
                tokenQuote,
                0,
                0,
                address(this),
                block.timestamp
            );

            emit AddLiquidity(tokenQuote, liquidityBNB, _pancakePair);
            trackers.tokensForLiquidity -= tokenQuote;
            trackers.bnbForLiquidity -= liquidityBNB;
        }

        return trackers;
    }

    function setNextOperation(SellOperation sellOperation) private {
        if (sellOperation == SellOperation.SellAndSend) {
            sellOperation = SellOperation.Liquidity;
        } else if (sellOperation == SellOperation.Liquidity) {
            sellOperation = SellOperation.None;
        }

        _sellOperation = sellOperation;
    }

    function finishTransfer(
        bool antiWhaleCheck,
        address from,
        address to,
        uint128 amount,
        uint128 tokenFees,
        uint128 reflectionFee,
        bytes32 contractRatesZero
    ) private {
        uint128 amountMinusFees = amount - tokenFees;
        uint128 reflectionFeeWithRate = reflectionFee * getReflectionRate();

        if (!_isExcluded[from].fromReward) {
            _reflectionBalance[from] -= (amount * getReflectionRate());
        } else if (_isExcluded[from].fromReward) {
            _tokenBalance[from] -= amount;
        }

        if (!_isExcluded[to].fromReward) {
            _reflectionBalance[to] += amountMinusFees * getReflectionRate();
        } else if (_isExcluded[to].fromReward) {
            _tokenBalance[to] += amountMinusFees;
        }

        if (antiWhaleCheck) {
            uint128 antiWhaleLimit = (_tokenSupply *
                uint16(bytes2(contractRatesZero << 160))) / DENOMINATOR;

            require(
                _reflectionBalance[to] / getReflectionRate() <=
                    antiWhaleLimit &&
                    _tokenBalance[to] <= antiWhaleLimit,
                "Receiver balance exceeds holder limit"
            );
        }

        if (reflectionFeeWithRate > 0) {
            if (_reflectionTotal >= reflectionFeeWithRate)
                _reflectionTotal -= reflectionFeeWithRate;

            _reflectionFeesEarned += reflectionFee;
            emit TokensReflected(reflectionFee);
        }

        if (tokenFees > 0) {
            /// Contract does not receive reflection fees
            _tokenBalance[address(this)] += tokenFees - reflectionFee;
            emit Transfer(from, address(this), tokenFees);
        }

        emit Transfer(from, to, amountMinusFees);
    }

    function _burn(uint128 amount) private {
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

    function _setRate(uint8 subIndex, uint32 value) private {
        bytes32[3] storage contractRates = _contractRates;
        subIndex *= 32;

        contractRates[1] &= ~(bytes32(bytes4(~uint32(0))) >> subIndex);
        contractRates[1] |= bytes32(bytes4(value)) >> subIndex;

        emit SetRate(1, subIndex, value);
    }

    function _getTransferType(
        address from,
        address to,
        address pancakePair
    ) private view returns (TransferType) {
        IsExcluded memory isExcludedFrom = _isExcluded[from];
        IsExcluded memory isExcludedTo = _isExcluded[to];
        TransferType transferType = TransferType.Default;

        if (isExcludedFrom.fromFee || isExcludedTo.fromFee) {
            transferType = TransferType.Excluded;
        } else if (isExcludedFrom.forVendor || isExcludedTo.forVendor) {
            transferType = TransferType.Vendor;
        } else if (to == pancakePair || from == pancakePair) {
            transferType = to == pancakePair
                ? TransferType.Sell
                : TransferType.Buy;
        }

        return transferType;
    }

    function _setTokenTrackers(
        Trackers memory trackers,
        uint128 charityFee,
        uint128 marketingFee,
        uint128 supportFee,
        TransferType transferType
    ) private view returns (Trackers memory) {
        uint24 denominator = DENOMINATOR;
        (uint32 buybackRate, uint32 liquidityRate) = _getSupportRates(
            transferType
        );
        uint128 liquidityFee;
        uint128 buybackFee;

        if (supportFee > 0) {
            /// Take only half liquidity to add for selling, store the other half
            liquidityFee = ((supportFee * liquidityRate) / denominator) / 2;
            buybackFee = (supportFee * buybackRate) / denominator;

            trackers.tokensForLiquidity += liquidityFee;
        }

        trackers.tokensForSelling +=
            charityFee +
            marketingFee +
            buybackFee +
            liquidityFee;

        return trackers;
    }

    function getReflectionRate() private view returns (uint128) {
        if (_reflectionTotal > _tokenSupply) {
            return _reflectionTotal / _tokenSupply;
        } else {
            return (_MAX - (_MAX % _tokenSupply)) / _tokenSupply;
        }
    }

    function _getInitialFees(uint128 amount, TransferType transferType)
        private
        view
        returns (
            uint128 charityFee,
            uint128 reflectionFee,
            uint128 marketingFee,
            uint128 supportStreamFee
        )
    {
        (
            uint128 charityRate,
            uint128 reflectionRate,
            uint128 marketingRate,
            uint128 supportStreamRate
        ) = _getRates(transferType);

        if (charityRate > 0) {
            charityFee = (amount * charityRate) / DENOMINATOR;
        }

        if (reflectionRate > 0) {
            reflectionFee = (amount * reflectionRate) / DENOMINATOR;
        }

        if (marketingRate > 0) {
            marketingFee = (amount * marketingRate) / DENOMINATOR;
        }

        if (supportStreamRate > 0) {
            supportStreamFee = (amount * supportStreamRate) / DENOMINATOR;
        }
    }

    function _getRates(TransferType transferType)
        private
        view
        returns (
            uint16 charityRate,
            uint16 reflectionRate,
            uint16 marketingRate,
            uint16 supportStreamRate
        )
    {
        bytes32 contractRatesZero = _contractRates[0];

        reflectionRate = uint16(bytes2(contractRatesZero << 16));
        charityRate = uint16(bytes2(contractRatesZero));

        if (transferType == TransferType.Vendor) {
            reflectionRate = 1500;
            charityRate = 1500;
        }

        if (transferType == TransferType.Buy) {
            reflectionRate = uint16(bytes2(contractRatesZero << 48));
            charityRate = uint16(bytes2(contractRatesZero << 32));
            marketingRate = uint16(bytes2(contractRatesZero << 64));
            supportStreamRate = uint16(bytes2(contractRatesZero << 80));
        } else if (transferType == TransferType.Sell) {
            reflectionRate = uint16(bytes2(contractRatesZero << 112));
            charityRate = uint16(bytes2(contractRatesZero << 96));
            marketingRate = uint16(bytes2(contractRatesZero << 128));
            supportStreamRate = uint16(bytes2(contractRatesZero << 144));
        }
    }

    function _getSupportRates(TransferType transferType)
        private
        view
        returns (uint32 buybackRate, uint32 liquidityRate)
    {
        bytes32 contractRatesOne = _contractRates[1];

        if (transferType == TransferType.Buy) {
            buybackRate = uint32(bytes4(contractRatesOne));
            liquidityRate = uint32(bytes4(contractRatesOne << 32));
        } else if (transferType == TransferType.Sell) {
            buybackRate = uint32(bytes4(contractRatesOne << 64));
            liquidityRate = uint32(bytes4(contractRatesOne << 96));
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

    function _setBNBTrackers(
        bool addExtraLPSupport,
        uint128 bnbReceived,
        Trackers memory trackers,
        bytes32 contractRatesTwo
    ) private pure returns (Trackers memory) {
        if (bnbReceived > 0) {
            (
                uint128 charityFee,
                uint128 marketingFee,
                uint128 buybackFee,
                uint128 liquidityFee
            ) = _getBNBFees(addExtraLPSupport, bnbReceived, contractRatesTwo);

            trackers.bnbForCharity += charityFee;
            trackers.bnbForMarketing += marketingFee;
            trackers.bnbForBuyback += buybackFee;
            trackers.bnbForLiquidity += liquidityFee;
        }

        return trackers;
    }

    function _getBNBFees(
        bool addExtraLPSupport,
        uint128 bnbToSplit,
        bytes32 contractRatesTwo
    )
        private
        pure
        returns (
            uint128 charityFee,
            uint128 marketingFee,
            uint128 buybackFee,
            uint128 liquidityFee
        )
    {
        uint24 denominator = DENOMINATOR;
        uint32 charityRate = uint32(bytes4(contractRatesTwo));
        uint32 marketingRate = uint32(bytes4(contractRatesTwo << 32));
        uint32 buybackRate = uint32(bytes4(contractRatesTwo << 64));
        uint32 liquidityRate = uint32(bytes4(contractRatesTwo << 96));
        uint32 commonDenominator = charityRate + marketingRate + buybackRate;

        if (liquidityRate > 0) {
            if (!addExtraLPSupport) liquidityRate /= 2;
            commonDenominator += liquidityRate;

            liquidityFee =
                ((bnbToSplit * (liquidityRate * denominator)) /
                    commonDenominator) /
                denominator;
        }

        if (charityRate > 0) {
            charityFee =
                ((bnbToSplit * (charityRate * denominator)) /
                    commonDenominator) /
                denominator;
        }

        if (marketingRate > 0) {
            marketingFee =
                ((bnbToSplit * (marketingRate * denominator)) /
                    commonDenominator) /
                denominator;
        }

        if (buybackRate > 0) {
            buybackFee =
                ((bnbToSplit * (buybackRate * denominator)) /
                    commonDenominator) /
                denominator;
        }
    }

    function _verify(address from, address to) private pure {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
    }
}