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
        payable(0x3110b6aBEF9eA6A12518bc4E70F4dBa3Bc0B2073);
    address payable public _marketingAddress =
        payable(0x7F2558be955EbD29Bd07F1cbFA9d18f1619bE879);
    address public immutable _burnAddress =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => IsExcluded) private _isExcluded;

    uint24 private constant DENOMINATOR = 100000;
    uint64 private _tokensToBurnForSellSupport = 1000000000000000; // 1 Million Tokens
    uint64 private _minimumTokensForLiquidation = 100000000000; // 100 Tokens
    uint64 private _minimumBnbForLiquidation = 1000000000000000000; // 1 BNB
    uint64 private _lastSellTime;
    uint128 private constant _MAX = ~uint128(0);
    uint128 private _tokenSupply = 10**9 * 10**9;
    uint128 private _reflectionTotal = (_MAX - (_MAX % _tokenSupply));
    uint128 private _reflectionFeesEarned;

    mapping(address => mapping(address => uint128)) private _allowances;
    mapping(address => uint128) private _tokenBalance;
    mapping(address => uint128) private _reflectionBalance;

    bytes32 private _contractRatesZero;
    bytes32 private _contractRatesOne;
    bytes32 private _feeTrackerZero;
    bytes32 private _feeTrackerOne;

    event TokensReflected(uint256 tokensReflected);
    event BuybackTokens(uint256 bnbIn, uint256 tokensBought);
    event SendToWallet(string wallet, address walletAddress, uint256 bnbForLP);
    event SendTokensToContract(address from, uint256 tokens);
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
        PancakeRouter = pancakeRouter;
        PancakePair = pancakePair;

        // _isExcluded[address(this)].fromFee = true;
        _isExcluded[_marketingAddress].fromFee = true;
        _isExcluded[owner()].fromFee = true;

        _isExcluded[pancakePair].fromReward = true;
        _isExcluded[_burnAddress].fromReward = true;
        _isExcluded[_marketingAddress].fromReward = true;
        _isExcluded[address(this)].fromReward = true;

        _tokenBalance[address(this)] = (_tokenSupply * 15000) / DENOMINATOR; // 15% of initial supply for support stream

        _setTracker(0, 2, uint64((_tokenSupply * 10000) / DENOMINATOR), true);
        _setTracker(0, 3, uint64((_tokenSupply * 5000) / DENOMINATOR), true);

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

    function setTokenBurnAmount(uint64 amount) external onlyOwner {
        if (
            _tokenBalance[address(this)] >= amount &&
            _getTracker(0, 0) >= amount
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
    function internalBurn(uint128 amount) external onlyOwner {
        _verify(_msgSender(), _burnAddress);
        require(
            _tokenBalance[address(this)] >= amount,
            "Balance must be greater than amount"
        );

        if (_getTracker(0, 2) >= amount) {
            _burn(amount);
            _setTracker(0, 2, uint128(amount), false);
        } else if (
            /// Check all token counters, if 0 and tokens in contract we can burn
            _getTracker(0, 0) == 0 &&
            _getTracker(0, 1) == 0 &&
            _getTracker(0, 2) == 0 &&
            _getTracker(0, 3) == 0
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
    function addContractSupportTokens(uint8 index, uint128 amount) external {
        require(index <= 1, "Index too high, must be 0 or 1");

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
        _setTracker(0, index + 2, uint64(amount), true);
        emit Transfer(_msgSender(), address(this), amount);
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
    function setFee(uint8 index, uint16 value) external onlyOwner {
        require(index <= 15, "index too high"); // Instead of lowering bytes32 it can allow up to index 15
        require(value <= 6000, "Must be lower or equal to 6% (6000)");

        index = index * 16;

        _contractRatesZero &= ~(bytes32(bytes2(~uint16(0))) >> index);
        _contractRatesZero |= bytes32(bytes2(value)) >> index;

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
    function setRate(uint8 index, uint32 value) external onlyOwner {
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
        bytes8 contractToggles;
        uint8 bits = 8;
        bytes32 contractRatesZero;
        bytes32 contractRatesOne;

        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 0;
        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 16;
        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 32;
        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 48;
        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 64;
        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 80;
        contractRatesZero |= bytes32(bytes2(uint16(3000))) >> 96;
        contractRatesZero |= bytes32(bytes2(uint16(4000))) >> 112;
        contractRatesZero |= bytes32(bytes2(uint16(4000))) >> 128;
        contractRatesZero |= bytes32(bytes2(uint16(5000))) >> 144;
        contractRatesZero |= bytes32(bytes2(uint16(2000))) >> 160;

        contractRatesOne |= bytes32(bytes4(uint32(34000))) >> 0;
        contractRatesOne |= bytes32(bytes4(uint32(66000))) >> 32;
        contractRatesOne |= bytes32(bytes4(uint32(60000))) >> 64;
        contractRatesOne |= bytes32(bytes4(uint32(40000))) >> 96;
        contractRatesOne |= bytes32(bytes4(uint32(5000))) >> 128;
        contractRatesOne |= bytes32(bytes4(uint32(25000))) >> 160;
        contractRatesOne |= bytes32(bytes4(uint32(50000))) >> 192;
        contractRatesOne |= bytes32(bytes4(uint32(3600))) >> 224;

        contractToggles |= bytes8(bytes1(uint8(1)));
        contractToggles |= bytes8(bytes1(uint8(1))) >> bits;
        contractToggles |= bytes8(bytes1(uint8(1))) >> (2 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (3 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (4 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (5 * bits);
        contractToggles |= bytes8(bytes1(uint8(1))) >> (6 * bits);

        _contractRatesZero = contractRatesZero;
        _contractRatesOne = contractRatesOne;
        _contractToggles = contractToggles;
    }

    /// Timer is in seconds (3600 = 1 hour)
    function settimeForNextSend(uint32 timer) external onlyOwner {
        _setRate(7, timer);
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
     * index values:
     * 0: Top Level Fees + Antiwhale* (0-6%) (*not capped at 6%)
     * 1: Contract sub-level fees (support stream)
     *
     * Index 0 - sub-index values:
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
     * Index 1 - sub-index values:
     * 0: Buy Buyback Burn Rate
     * 1: Buy LP Rate
     * 2: Sell Buyback Burn Rate
     * 3: Sell LP Rate
     * 4: Price Impact Trigger
     * 5: Minimum based on sell price before burning tokens
     * 6: Max amount to buy based on sell price
     * 7: Time in seconds before selling again
     */
    function getRate(uint8 index, uint8 subIndex)
        external
        view
        returns (uint32)
    {
        require(index <= 1, "index to high");

        if (index == 0) {
            require(subIndex <= 15, "subIndex too high");

            return uint16(bytes2(_contractRatesZero << (subIndex * 16)));
        } else {
            require(subIndex <= 9, "subIndex too high");

            return uint32(bytes4(_contractRatesOne << (subIndex * 32)));
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

    function setMinimumBNBForLiquidation(uint64 amount) external onlyOwner {
        _minimumBnbForLiquidation = amount;
    }

    function setMinimumTokensForLiquidation(uint64 amount) external onlyOwner {
        _minimumTokensForLiquidation = amount;
    }

    /**
     * Amount must contain trailing decimal places (9).
     * ex: 1000000001 = 1.000000001 Tokens
     * If liquidateNow is true it will try.
     */
    function liquidateTokensAndDisitrbuteFunds(uint64 amount)
        external
        LockSwap
        onlyOwner
    {
        require(amount > 0, "Amount must be greater than 0");

        uint64 splitTokens = (amount / 3);
        uint128 tokensAvailable = _getTracker(0, 1);
        uint256 initialBnb = address(this).balance;
        uint256 bnbReceived;

        if (amount >= tokensAvailable) {
            uint64 LPTokenPairing = splitTokens / 2;
            _setTracker(0, 1, splitTokens, false);
            _setTracker(0, 2, splitTokens, false);
            _setTracker(0, 3, splitTokens, false);

            approveAllowance(address(this), address(PancakeRouter), amount);

            // generate the Pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = PancakeRouter.WETH();

            // make the swap
            PancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount - LPTokenPairing,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );

            if (address(this).balance > initialBnb)
                bnbReceived = address(this).balance - initialBnb;

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
                    emit SendToWallet("Charity", _charityAddress, thirdsBnb);

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

    function getMinimumTokensForLiquidation() external view returns (uint128) {
        return _minimumTokensForLiquidation;
    }

    function getMinimumBnbForLiquidation() external view returns (uint128) {
        return _minimumBnbForLiquidation;
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
    function getToggle(uint8 subIndex) public view returns (bool) {
        uint8 currentValue = uint8(bytes1(_contractToggles << (subIndex * 8)));
        return (currentValue == 1 || currentValue == 3) ? true : false;
    }

    /**
     * index values:
     * 0: Fee Trackers
     * 1: Self Support Trackers
     *
     * Index 0:
     * 0: Tokens stored for Burning after being bought back
     * 1: Tokens stored for Fees to be sold for BNB & for Liquidity
     * 2: Tokens allocated for Burning (10% supply)
     * 3: Tokens allocated for Liquidity (5% supply)
     *
     * Index 1
     * 0: BNB allocated for charity/marketing (wallets)
     * 1: BNB allocated for Buyback/Liquidity (support stream)
     */
    function getTracker(uint8 index, uint8 subIndex)
        external
        view
        returns (uint128)
    {
        require(index <= 1, "Index must be 0 or 1");

        return _getTracker(index, subIndex);
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

        uint128 reflectionFee;
        uint128 tokenFees;

        if (!_lockSwap) {
            if (_isExcluded[from].fromFee || _isExcluded[to].fromFee) {
                _transferType = TransferType.Excluded;
            } else if (
                _isExcluded[from].forVendor || _isExcluded[to].forVendor
            ) {
                _transferType = TransferType.Vendor;
            } else if (to == PancakePair || from == PancakePair) {
                _transferType = to == PancakePair
                    ? TransferType.Sell
                    : TransferType.Buy;
            } else {
                _transferType = TransferType.Default;
            }

            uint64 supportTokensForBurnAvailable = _getTracker(0, 2);
            uint128 tokensToBurn;

            if (
                getToggle(1) && /// 15% support toggle
                supportTokensForBurnAvailable > 0 &&
                to == PancakePair &&
                _tokenBalance[address(this)] >= amount
            ) {
                // Burn support tokens allocated to contract
                if (supportTokensForBurnAvailable >= amount) {
                    tokensToBurn += amount;
                    _setTracker(0, 2, uint64(amount), false);
                } else {
                    tokensToBurn += supportTokensForBurnAvailable;
                    _setTracker(0, 2, supportTokensForBurnAvailable, false);
                }
            }

            if (_transferType != TransferType.Excluded) {
                uint128 charityFee;
                uint128 marketingFee;
                uint128 supportFee;

                (charityFee, reflectionFee, marketingFee, supportFee) = getFees(
                    amount,
                    false
                );

                tokenFees =
                    charityFee +
                    reflectionFee +
                    marketingFee +
                    supportFee;

                if (to == PancakePair) {
                    (uint128 tokenA, uint128 tokenB, ) = IPancakePair(
                        PancakePair
                    ).getReserves();

                    if (getToggle(2))
                        sellTokens(
                            charityFee + marketingFee + supportFee,
                            supportFee
                        );

                    bool timeForNextSend = uint32(
                        bytes4(_contractRatesOne << 224)
                    ) +
                        _lastSellTime <=
                        block.timestamp;

                    if (
                        timeForNextSend &&
                        address(this).balance >= _minimumBnbForLiquidation
                    ) {
                        _lastSellTime = uint64(block.timestamp);
                        sendAndAddLiquidity(tokenA, tokenB);
                    }

                    if (
                        getToggle(5) /// Buyback/burn Tokens
                    ) {
                        tokensToBurn += buyTokensAndGetBurn(
                            amount,
                            tokenA,
                            tokenB
                        );
                    }
                } else if (tokenFees > 0) {
                    _setTracker(0, 1, tokenFees, true);
                }
            } // _transferType != TransferType.Excluded

            if (!getToggle(6)) {
                _setTracker(0, 0, tokensToBurn, true);
            } else if (tokensToBurn > 0) {
                _burn(tokensToBurn);
            }
        } // !_lockSwap

        finishTransfer(from, to, amount, tokenFees, reflectionFee);
    }

    function sellTokens(uint128 initialTokenFees, uint128 supportFee)
        private
        LockSwap
    {
        (, , , , uint32 buybackRate, uint32 liquidityRate) = getRates();
        uint64 balanceAvailable = _getTracker(0, 1);
        uint128 tokensToSell = initialTokenFees;
        uint128 tokensForLP;
        uint128 extraTokenFees;
        uint128 liquidityFee;

        if (
            _tokenBalance[address(this)] >= balanceAvailable &&
            balanceAvailable >= _minimumTokensForLiquidation
        ) {
            (
                uint128 charityFee,
                ,
                uint128 marketingFee,
                uint128 extraSupportFee
            ) = getFees(_minimumTokensForLiquidation, true);

            uint128 buybackFee = (extraSupportFee * buybackRate) / DENOMINATOR;
            uint128 extraLiquidityFee = (extraSupportFee * liquidityRate) /
                DENOMINATOR;

            extraTokenFees += charityFee + marketingFee + buybackFee;
            tokensToSell += extraTokenFees;

            _setTracker(0, 1, extraTokenFees, false);

            if (extraLiquidityFee > 0) {
                tokensToSell += (extraLiquidityFee / 2);
                tokensForLP += (extraLiquidityFee / 2);
            }
        }

        if (supportFee > 0) {
            liquidityFee = ((supportFee * liquidityRate) / DENOMINATOR) / 2;

            tokensForLP += liquidityFee;
            tokensToSell -= liquidityFee; // Remove half from initialsFees passed in
        }

        /// Tokens allocated for Liquidity Support (initial 5% given to contract)
        uint64 liquiditySupportTokens = _getTracker(0, 3);
        if (getToggle(1) && liquiditySupportTokens > 0) {
            if (liquiditySupportTokens >= liquidityFee) {
                tokensForLP += liquidityFee;
                _setTracker(0, 3, liquidityFee * 2, false);
            } else {
                tokensForLP += (liquiditySupportTokens / 2);
                _setTracker(0, 3, liquiditySupportTokens, false);
            }

            if (tokensForLP > 0) tokensToSell += tokensForLP;
        }

        if (tokensToSell > 0) {
            setBNBTrackers(swapTokensForBNB(tokensToSell));
        }
    }

    function swapTokensForBNB(uint128 tokensToSell)
        private
        returns (uint128 bnbReceived)
    {
        approveAllowance(address(this), address(PancakeRouter), tokensToSell);
        uint256 initialBnb = address(this).balance;

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

        if (address(this).balance > initialBnb) {
            bnbReceived = uint128(address(this).balance - initialBnb);

            emit SwapTokensForBNB(tokensToSell, bnbReceived);
        }
    }

    function setBNBTrackers(uint128 bnbReceived) private {
        (
            uint128 charityFee,
            ,
            uint128 marketingFee,
            uint128 supportFee
        ) = getFees(bnbReceived, true);

        _setTracker(1, 0, charityFee + marketingFee, true);
        _setTracker(1, 1, supportFee, true);
    }

    function buyTokensAndGetBurn(
        uint256 amount,
        uint256 tokenA,
        uint256 tokenB
    ) private LockSwap returns (uint64) {
        bool burnNow;
        uint64 tokensToBurn;
        uint64 initialTokens = uint64(_tokenBalance[address(this)]);
        uint128 bnbNeeded = uint128(
            PancakeRouter.getAmountOut(amount, tokenA, tokenB)
        );
        uint128 bnbAllocatedForBuyback = _getTracker(1, 1, true);
        uint128 bnbForBuy;
        uint128 minBuybackAmount = (bnbNeeded *
            (uint32(bytes4(_contractRatesOne << 160)))) / DENOMINATOR;
        uint128 maxBuybackAmount = (bnbNeeded *
            (uint32(bytes4(_contractRatesOne << 192)))) / DENOMINATOR;
        uint256 bnbBalance = address(this).balance;
        uint256 priceImpact = ((amount * 100000) / tokenA);

        emit Print("Price Impact", priceImpact);
        // Trigger for buyback + possible burn
        if (priceImpact >= uint32(bytes4(_contractRatesOne << 128))) {
            if (
                _getTracker(0, 0) >= _tokensToBurnForSellSupport && // Tokens allocated for burn
                initialTokens >= _tokensToBurnForSellSupport
            ) {
                tokensToBurn += _tokensToBurnForSellSupport;
                initialTokens -= _tokensToBurnForSellSupport;
                _setTracker(0, 0, uint64(tokensToBurn), false);
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
            } else if (bnbBalance >= bnbAllocatedForBuyback) {
                bnbForBuy = bnbAllocatedForBuyback;

                if (getToggle(4)) burnNow = true;
            }
        }

        uint64 tokensBought;
        if (bnbForBuy > 0 && bnbBalance > bnbForBuy) {
            _setTracker(1, 1, bnbForBuy, false);

            buyTokens(bnbForBuy);

            if (_tokenBalance[address(this)] > initialTokens) {
                tokensBought =
                    uint64(_tokenBalance[address(this)]) -
                    initialTokens;

                emit BuybackTokens(bnbForBuy, tokensBought);
            }
        }

        if (burnNow) tokensToBurn += tokensBought;

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
    }

    function sendAndAddLiquidity(uint256 tokenA, uint256 tokenB)
        private
        LockSwap
    {
        (
            uint128 charityBNB, /// Reflection (no BNB)
            ,
            uint128 marketingBNB, /// BNB for supportstream, its split to buyback/liquidity
            uint128 supportBNB
        ) = getFees(_minimumBnbForLiquidation, true);

        (, , , , uint32 buybackRate, uint32 liquidityRate) = getRates();

        if (getToggle(3)) {
            /// Send BNB Toggle
            sendBNB(charityBNB, marketingBNB);
        } else {
            _setTracker(1, 0, charityBNB + marketingBNB, true);
        }

        if (supportBNB > 0) {
            uint128 buybackBNB = (supportBNB * buybackRate) / DENOMINATOR;
            uint128 liquidityBNB = (supportBNB * liquidityRate) / DENOMINATOR;

            _setTracker(1, 1, buybackBNB, true);

            if (getToggle(4)) {
                /// Add Liquidity Toggle
                addLiquidity(liquidityBNB, tokenA, tokenB);
            } else {
                _setTracker(1, 1, liquidityBNB, true);
            }
        }
    }

    function sendBNB(uint128 charityBNB, uint128 marketingBNB) private {
        bool success;

        if (charityBNB > 0)
            (success, ) = _charityAddress.call{value: charityBNB}(new bytes(0));

        if (success) emit SendToWallet("Charity", _charityAddress, charityBNB);

        if (marketingBNB > 0)
            (success, ) = _marketingAddress.call{value: marketingBNB}(
                new bytes(0)
            );

        if (success)
            emit SendToWallet("Marketing", _marketingAddress, marketingBNB);
    }

    function addLiquidity(
        uint128 bnbLpFee,
        uint256 tokenA,
        uint256 tokenB
    ) private {
        (, , , uint32 supportStreamRate, , uint32 liquidityRate) = getRates();
        uint64 tokensAvailable = _getTracker(0, 1);
        uint128 tokenQuote = uint128(
            PancakeRouter.quote(bnbLpFee, tokenB, tokenA)
        );
        uint128 liquidityTokensAvailable;
        if (tokensAvailable > 0 && supportStreamRate > 0) {
            uint128 supportFee = (tokensAvailable * supportStreamRate) /
                DENOMINATOR;
            liquidityTokensAvailable =
                (supportFee * liquidityRate) /
                DENOMINATOR;
        }

        if (
            address(this).balance >= bnbLpFee &&
            liquidityTokensAvailable >= tokenQuote &&
            _tokenBalance[address(this)] >= liquidityTokensAvailable
        ) {
            approveAllowance(address(this), address(PancakeRouter), tokenQuote);

            PancakeRouter.addLiquidityETH{value: bnbLpFee}(
                address(this),
                tokenQuote,
                0,
                0,
                address(this),
                block.timestamp
            );

            emit AddLiquidity(tokenQuote, bnbLpFee, PancakePair);
            _setTracker(0, 1, uint64(tokenQuote), false);
        }
    }

    function finishTransfer(
        address from,
        address to,
        uint128 amount,
        uint128 tokenFees,
        uint128 reflectionFee
    ) private {
        bool antiWhaleCheck = getToggle(0) &&
            to != PancakePair &&
            to != _burnAddress &&
            to != address(this);
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
                uint16(bytes2(_contractRatesZero << 160))) / DENOMINATOR;

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

    function _setTracker(
        uint8 index,
        uint8 subIndex,
        uint128 value,
        bool add
    ) private {
        bool isTrackerOne = index == 1 ? true : false;
        bytes32 tracker = index == 0 ? _feeTrackerZero : _feeTrackerOne;

        if (!isTrackerOne) {
            require(subIndex <= 3, "Subindex must be 3 or less for index 0");

            subIndex *= 64;
        } else {
            require(subIndex <= 1, "Subindex must be 1 or less for index 1");

            subIndex *= 128;
        }

        uint128 oldValue = isTrackerOne
            ? uint128(bytes16(tracker << subIndex))
            : uint64(bytes8(tracker << subIndex));
        uint128 newValue;
        if (add) {
            newValue = oldValue + value;
        } else if (oldValue >= value) {
            newValue = oldValue - value;
        } else if (oldValue < value) {
            newValue = 0;
        }

        if (isTrackerOne) {
            tracker &= ~(bytes32(bytes16(~uint128(0))) >> subIndex);
            tracker |= bytes32(bytes16(uint128(newValue))) >> subIndex;
        } else {
            tracker &= ~(bytes32(bytes8(~uint64(0))) >> subIndex);
            tracker |= bytes32(bytes8(uint64(newValue))) >> subIndex;
        }

        if (index == 0) {
            _feeTrackerZero = tracker;
        } else if (index == 1) {
            _feeTrackerOne = tracker;
        }

        emit TrackerUpdate(index, oldValue, newValue, add);
    }

    function _getTracker(uint8 index, uint8 subIndex)
        private
        view
        returns (uint64)
    {
        require(index == 0, "Index must be 0");

        return uint64(bytes8(_feeTrackerZero << (subIndex * 64)));
    }

    function _getTracker(
        uint8 index,
        uint8 subIndex,
        bool //isBnb
    ) private view returns (uint128) {
        require(index == 1, "Index must be 1");

        return uint128(bytes16(_feeTrackerOne << (subIndex * 128)));
    }

    function _setRate(uint8 subIndex, uint32 value) private {
        subIndex *= 32;

        _contractRatesOne &= ~(bytes32(bytes4(~uint32(0))) >> subIndex);
        _contractRatesOne |= bytes32(bytes4(value)) >> subIndex;

        emit SetRate(1, subIndex, value);
    }

    function getReflectionRate() private view returns (uint128) {
        if (_reflectionTotal > _tokenSupply) {
            return _reflectionTotal / _tokenSupply;
        } else {
            return (_MAX - (_MAX % _tokenSupply)) / _tokenSupply;
        }
    }

    function getFees(uint128 amount, bool liquidatingTokens)
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
            uint128 supportStreamRate,
            ,

        ) = getRates();
        uint128 commonDenominator = getCommonDenominator();

        /// Break down rates to give a percent based off 100% total
        if (liquidatingTokens) {
            if (charityRate > 0)
                charityRate = (charityRate * DENOMINATOR) / commonDenominator;
            if (marketingRate > 0)
                marketingRate =
                    (marketingRate * DENOMINATOR) /
                    commonDenominator;
            if (supportStreamRate > 0)
                supportStreamRate =
                    (supportStreamRate * DENOMINATOR) /
                    commonDenominator;
        }

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

    function getRates()
        private
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint16,
            uint32,
            uint32
        )
    {
        uint16 charityRate;
        uint16 marketingRate;
        uint16 supportStreamRate;
        uint32 buybackRate;
        uint32 liquidityRate;

        uint16 reflectionRate = uint16(bytes2(_contractRatesZero << 16));

        if (_transferType == TransferType.Vendor) {
            reflectionRate = 1500;
            charityRate = 1500;
        } else if (_transferType == TransferType.Default) {
            charityRate = uint16(bytes2(_contractRatesZero));
        }

        if (_transferType == TransferType.Buy) {
            reflectionRate = uint16(bytes2(_contractRatesZero << 48));
            charityRate = uint16(bytes2(_contractRatesZero << 32));
            marketingRate = uint16(bytes2(_contractRatesZero << 64));
            supportStreamRate = uint16(bytes2(_contractRatesZero << 80));

            buybackRate = uint32(bytes4(_contractRatesOne));
            liquidityRate = uint32(bytes4(_contractRatesOne << 32));
        } else if (_transferType == TransferType.Sell) {
            reflectionRate = uint16(bytes2(_contractRatesZero << 112));
            charityRate = uint16(bytes2(_contractRatesZero << 96));
            marketingRate = uint16(bytes2(_contractRatesZero << 128));
            supportStreamRate = uint16(bytes2(_contractRatesZero << 144));

            buybackRate = uint32(bytes4(_contractRatesOne << 64));
            liquidityRate = uint32(bytes4(_contractRatesOne << 96));
        }

        return (
            charityRate,
            reflectionRate,
            marketingRate,
            supportStreamRate,
            buybackRate,
            liquidityRate
        );
    }

    function getCommonDenominator() private view returns (uint32) {
        (
            uint16 charityRate,
            ,
            uint16 marketingRate,
            uint16 supportStreamRate,
            ,

        ) = getRates();

        return charityRate + marketingRate + supportStreamRate;
    }

    function _verify(address from, address to) private pure {
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
    }
}