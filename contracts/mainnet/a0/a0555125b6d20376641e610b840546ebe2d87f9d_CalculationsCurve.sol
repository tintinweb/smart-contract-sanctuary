/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Ownable {
    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
    function coins(uint256 arg0) external view returns (address);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address arg0)
        external
        view
        returns (address);

    function get_underlying_coins(address arg0)
        external
        view
        returns (address[8] memory);

    function get_virtual_price_from_lp_token(address arg0)
        external
        view
        returns (uint256);
}

interface ICryptoPool {
    function balances(uint256) external view returns (uint256);

    function price_oracle(uint256) external view returns (uint256);

    // Some crypto pools only consist of 2 coins, one of which is usd so 
    // it can be assumed that the price oracle doesn't need an argument
    // and the price of the oracle refers to the other coin.
    // This function is mutually exclusive with the price_oracle function that takes 
    // an argument of the index of the coin, only one will be present on the pool
    function price_oracle() external view returns (uint256);

    function coins(uint256) external view returns (address);
}

interface ILp {
    function totalSupply() external view returns (uint256);
}

interface IOracle {
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);

    function usdcAddress() external view returns (address);
}

interface IYearnAddressesProvider {
    function addressById(string memory) external view returns (address);
}

interface ICurveAddressesProvider {
    function get_registry() external view returns (address);

    function get_address(uint256) external view returns (address);
}

interface ICalculationsChainlink {
    function oracleNamehashes(address) external view returns (bytes32);
}

contract CalculationsCurve is Ownable {
    address public yearnAddressesProviderAddress;
    address public curveAddressesProviderAddress;
    IYearnAddressesProvider internal yearnAddressesProvider;
    ICurveAddressesProvider internal curveAddressesProvider;

    constructor(
        address _yearnAddressesProviderAddress,
        address _curveAddressesProviderAddress
    ) {
        yearnAddressesProviderAddress = _yearnAddressesProviderAddress;
        curveAddressesProviderAddress = _curveAddressesProviderAddress;
        yearnAddressesProvider = IYearnAddressesProvider(
            _yearnAddressesProviderAddress
        );
        curveAddressesProvider = ICurveAddressesProvider(
            _curveAddressesProviderAddress
        );
    }

    function updateYearnAddressesProviderAddress(address _yearnAddressesProviderAddress) external onlyOwner {
        yearnAddressesProviderAddress = _yearnAddressesProviderAddress;
        yearnAddressesProvider = IYearnAddressesProvider(
            _yearnAddressesProviderAddress
        );
    }

    function updateCurveAddressesProviderAddress(address _curveAddressesProviderAddress) external onlyOwner {
        curveAddressesProviderAddress = _curveAddressesProviderAddress;
        curveAddressesProvider = ICurveAddressesProvider(
            _curveAddressesProviderAddress
        );
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(yearnAddressesProvider.addressById("ORACLE"));
    }

    function curveRegistry() internal view returns (ICurveRegistry) {
        return ICurveRegistry(curveAddressesProvider.get_registry());
    }
    
    function cryptoPoolRegistry() internal view returns (ICurveRegistry) {
        return ICurveRegistry(curveAddressesProvider.get_address(5));
    }

    function getCurvePriceUsdc(address lpAddress)
        public
        view
        returns (uint256)
    {
        if (isLpCryptoPool(lpAddress)) {
            return cryptoPoolLpPriceUsdc(lpAddress);
        }
        uint256 basePrice = getBasePrice(lpAddress);
        uint256 virtualPrice = getVirtualPrice(lpAddress);
        IERC20 usdc = IERC20(oracle().usdcAddress());
        uint256 decimals = usdc.decimals();
        uint256 decimalsAdjustment = 18 - decimals;
        uint256 priceUsdc = (virtualPrice *
            basePrice *
            (10**decimalsAdjustment)) / 10**(decimalsAdjustment + 18);
        return priceUsdc;
    }

    function cryptoPoolLpTotalValueUsdc(address lpAddress)
        public
        view
        returns (uint256)
    {
        address poolAddress = getPoolFromLpToken(lpAddress);

        address[] memory underlyingTokensAddresses = cryptoPoolUnderlyingTokensAddressesByPoolAddress(poolAddress);
        uint256 totalValue;
        for (
            uint256 tokenIdx;
            tokenIdx < underlyingTokensAddresses.length;
            tokenIdx++
        ) {
            uint256 tokenValueUsdc = cryptoPoolTokenAmountUsdc(
                poolAddress,
                tokenIdx
            );
            totalValue += tokenValueUsdc;
        }
        return totalValue;
    }

    function cryptoPoolLpPriceUsdc(address lpAddress)
        public
        view
        returns (uint256)
    {
        uint256 totalValueUsdc = cryptoPoolLpTotalValueUsdc(lpAddress);
        uint256 totalSupply = ILp(lpAddress).totalSupply();
        uint256 priceUsdc = (totalValueUsdc * 10**18) / totalSupply;
        return priceUsdc;
    }

    struct TokenAmount {
        address tokenAddress;
        string tokenSymbol;
        uint256 amountUsdc;
    }

    function cryptoPoolTokenAmountsUsdc(address poolAddress)
        public
        view
        returns (TokenAmount[] memory)
    {
        address[] memory underlyingTokensAddresses = cryptoPoolUnderlyingTokensAddressesByPoolAddress(poolAddress);
        TokenAmount[] memory _tokenAmounts = new TokenAmount[](
            underlyingTokensAddresses.length
        );
        for (
            uint256 tokenIdx;
            tokenIdx < underlyingTokensAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = underlyingTokensAddresses[tokenIdx];
            string memory tokenSymbol = IERC20(tokenAddress).symbol();
            uint256 amountUsdc = cryptoPoolTokenAmountUsdc(
                poolAddress,
                tokenIdx
            );
            _tokenAmounts[tokenIdx] = TokenAmount({
                tokenAddress: tokenAddress,
                tokenSymbol: tokenSymbol,
                amountUsdc: amountUsdc
            });
        }
        return _tokenAmounts;
    }

    function cryptoPoolTokenAmountUsdc(address poolAddress, uint256 tokenIdx)
        public
        view
        returns (uint256)
    {
        ICryptoPool pool = ICryptoPool(poolAddress);
        address tokenAddress = pool.coins(tokenIdx);
        uint8 decimals = IERC20(tokenAddress).decimals();
        uint256 tokenPrice = oracle().getPriceUsdcRecommended(tokenAddress);
        uint256 tokenValueUsdc = pool.balances(tokenIdx) * tokenPrice / 10 ** decimals;
        return tokenValueUsdc;
    }

    function cryptoPoolUnderlyingTokensAddressesByPoolAddress(
        address poolAddress
    ) public view returns (address[] memory) {
        uint256 numberOfTokens;
        address[] memory _tokensAddresses = new address[](8);
        for (uint256 coinIdx; coinIdx < 8; coinIdx++) {
            (bool success, bytes memory data) = address(poolAddress).staticcall(
                abi.encodeWithSignature("coins(uint256)", coinIdx)
            );
            if (success) {
                address tokenAddress = abi.decode(data, (address));
                _tokensAddresses[coinIdx] = tokenAddress;
                numberOfTokens++;
            } else {
                break;
            }
        }
        bytes memory encodedAddresses = abi.encode(_tokensAddresses);
        assembly {
            mstore(add(encodedAddresses, 0x40), numberOfTokens)
        }
        address[] memory filteredAddresses = abi.decode(
            encodedAddresses,
            (address[])
        );
        return filteredAddresses;
    }

    function getBasePrice(address lpAddress) public view returns (uint256) {
        address poolAddress = getPoolFromLpToken(lpAddress);
        address underlyingCoinAddress = getUnderlyingCoinFromPool(poolAddress);
        uint256 basePriceUsdc = oracle().getPriceUsdcRecommended(
            underlyingCoinAddress
        );
        return basePriceUsdc;
    }

    // should not be used with lpAddresses that are from the crypto swap registry
    function getVirtualPrice(address lpAddress) public view returns (uint256) {
        return curveRegistry().get_virtual_price_from_lp_token(lpAddress);
    }

    function isCurveLpToken(address lpAddress) public view returns (bool) {
        address poolAddress = getPoolFromLpToken(lpAddress);
        bool tokenHasCurvePool = poolAddress != address(0);
        return tokenHasCurvePool;
    }

    function isLpCryptoPool(address lpAddress) public view returns (bool) {
        address poolAddress = getPoolFromLpToken(lpAddress);

        if (poolAddress != address(0)) {
            return isPoolCryptoPool(poolAddress);
        }

        return false;
    }

    function isPoolCryptoPool(address poolAddress) public view returns (bool) {
        (bool success, ) = address(poolAddress).staticcall(
            abi.encodeWithSignature("price_oracle(uint256)", 0)
        );

        if (success) {
            return true;
        }

        (bool successNoParams, ) = address(poolAddress).staticcall(
            abi.encodeWithSignature("price_oracle()")   
        );

        return successNoParams;
    }

    function getPoolFromLpToken(address lpAddress) public view returns (address) {
        address poolAddress = curveRegistry().get_pool_from_lp_token(lpAddress);

        if (poolAddress != address(0)) {
            return poolAddress;
        }

        return cryptoPoolRegistry().get_pool_from_lp_token(lpAddress);
    }

    function isBasicToken(address tokenAddress) public view returns (bool) {
        return
            ICalculationsChainlink(
                yearnAddressesProvider.addressById("CALCULATIONS_CHAINLINK")
            ).oracleNamehashes(tokenAddress) != bytes32(0);
    }

    // should not be used with pools from the crypto pool registry
    function getUnderlyingCoinFromPool(address poolAddress)
        public
        view
        returns (address)
    {
        address[8] memory coins = curveRegistry().get_underlying_coins(
            poolAddress
        );

        return getPreferredCoinFromCoins(coins);
    }

    function getPreferredCoinFromCoins(address[8] memory coins)
        internal
        view
        returns (address)
    {
        // Look for preferred coins (basic coins)
        address preferredCoinAddress;
        for (uint256 coinIdx = 0; coinIdx < 8; coinIdx++) {
            address coinAddress = coins[coinIdx];
            if (coinAddress != address(0) && isBasicToken(coinAddress)) {
                preferredCoinAddress = coinAddress;
                break;
            } else if (coinAddress != address(0)) {
                preferredCoinAddress = coinAddress;
            }
            // Found preferred coin and we're at the end of the token array
            if (
                (preferredCoinAddress != address(0) &&
                    coinAddress == address(0)) || coinIdx == 7
            ) {
                break;
            }
        }
        return preferredCoinAddress;
    }

    function getPriceUsdc(address assetAddress) public view returns (uint256) {
        if (isCurveLpToken(assetAddress)) {
            return getCurvePriceUsdc(assetAddress);
        }
        
        ICurvePool pool = ICurvePool(assetAddress);
        uint256 virtualPrice = pool.get_virtual_price();
        address[8] memory coins;
        for (uint i = 0; i < 8; i++) {
            try pool.coins(i) returns (address coin) {
                coins[i] = coin;
            } catch {}
        }
        address preferredCoin = getPreferredCoinFromCoins(coins);
        uint256 price = oracle().getPriceUsdcRecommended(preferredCoin);
        if (price == 0) {
            revert();
        }
        return price * virtualPrice / 10 ** 18;
    }
}