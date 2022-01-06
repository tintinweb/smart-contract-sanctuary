// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IDexFactory.sol";
import "../interfaces/IDexPair.sol";
import "../interfaces/IERC20Extras.sol";
import "./IGovPriceConsumer.sol";
import "../admin/admininterfaces/IGovWorldAdminRegistry.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../admin/admininterfaces/IGovWorldProtocolRegistry.sol";
import "../claimtoken/IGovClaimToken.sol";


contract GovPriceConsumer is IGovPriceConsumer {
    
    using SafeMath for *;

    mapping(address => ChainlinkDataFeed) public usdPriceAggrigators;
    //mapping of approved dexRouter ID to router address
    mapping(uint256 => address) public routerAddress;
    //chainlink feed token addresses
    address[] public allFeedTokensContractChainlink;

    address[] public allFeedTokenAddress;
   
    IGovWorldAdminRegistry govWorldAdminRegistry;
    IGovWorldProtocolRegistry govProtocolRegistry;
    IGovClaimToken govClaimTokenContract;
    IUniswapV2Router02 swapRouterv2;

    AggregatorV3Interface internal networkCoinUsdPriceFeed;

    // TODO adding stable coin price feed address to the usdPriceAggrigators //CHAINLINK RINKEBY STABLE COIN FEED ENABLED
    // TODO uncomment array part for the stable cons chainlink feed tokens
    constructor(
        address _govWorldAdminRegistry,
        // address[] memory _stableFeedTokens,
        address _stableFeedTokens,
        // address[] memory _chainLinkFeedContracts,
        address _chainLinkFeedContracts,
        // bool[] memory _enabled,
        bool _enabled,
        // uint256[] memory _decimals) {
        uint256 _decimals,
        address _swapRouterv2,
        address _govProtocolRegistry,
        address _govClaimToken

        ) {
        
        // require(_govWorldAdminRegistry != address(0), "GPC: Admin Contract Must be provided");
        // require(_stableFeedTokens.length > 0, "GPCPriceConsumer: No tokens provided for price feed");
        // require(_chainLinkFeedContracts.length > 0, "GPC: No price feed chainlink contract address provided");
        // require(_stableFeedTokens.length == _chainLinkFeedContracts.length, "GPC: Price feed tokens and contracts should be of same length");
        // require(_enabled.length == _decimals.length, "GPC: Length not match");
        
        govWorldAdminRegistry = IGovWorldAdminRegistry(_govWorldAdminRegistry);
        govProtocolRegistry = IGovWorldProtocolRegistry(_govProtocolRegistry);
        govClaimTokenContract = IGovClaimToken(_govClaimToken);
        
        // for(uint256 i = 0 ; i < _stableFeedTokens.length; i++){
           usdPriceAggrigators[_stableFeedTokens] = ChainlinkDataFeed(AggregatorV3Interface(_chainLinkFeedContracts), _enabled, _decimals);
           allFeedTokensContractChainlink.push(_chainLinkFeedContracts);
           allFeedTokenAddress.push(_stableFeedTokens);
           emit PriceFeedAdded(_stableFeedTokens,  _chainLinkFeedContracts, _enabled, _decimals);
        //    }   
        swapRouterv2 = IUniswapV2Router02(_swapRouterv2); 
        networkCoinUsdPriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);       

    }

     modifier onlyPriceFeedTokenRole(address admin) {
        require(govWorldAdminRegistry.isAddTokenRole(admin),
            "GPC: No admin right to add price feed tokens.");
        _;
    }

    /**
    @dev chainlink feed token address check if it's already added
     */
    function _isAddedChainlinkFeedAddress(address _chainlinkFeedAddress)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allFeedTokensContractChainlink.length; i++) {
            if (allFeedTokensContractChainlink[i] == _chainlinkFeedAddress) {
                return true;
            }
        }
        return false;
    } 

    /**
    @dev Adds a new token for which getLatestUsdPrice or getLatestUsdPrices can be called.
    *@param _tokenAddress The new token for price feed.
    *@param _chainlinkFeedAddress chainlink feed address 
    *@param _enabled    if true then enabled
    *@param _decimals decimals of the chainlink price feed
    */

    function addUsdPriceAggrigator(
        address _tokenAddress,
        address _chainlinkFeedAddress,
        bool _enabled,
        uint256 _decimals
      )
        external
        onlyPriceFeedTokenRole(msg.sender)
    {
        require(!_isAddedChainlinkFeedAddress(_chainlinkFeedAddress), "GPC: already added price feed");
        usdPriceAggrigators[_tokenAddress] = ChainlinkDataFeed(AggregatorV3Interface(_chainlinkFeedAddress), _enabled, _decimals);
        allFeedTokensContractChainlink.push(_chainlinkFeedAddress);
        allFeedTokenAddress.push(_tokenAddress);

        emit PriceFeedAdded( _tokenAddress, _chainlinkFeedAddress, _enabled, _decimals);
    }

    /**
    @dev Adds a new tokens in bulk for getlatestPrice or getLatestUsdPrices can be called
    @param _tokenAddress the new tokens for the price feed
    @param _chainlinkFeedAddress The contract address of the chainlink aggregator
    @param  _enabled price feed enabled or not
    @param  _decimals of the chainlink feed address
     */

    function addUsdPriceAggrigatorBulk(
        address[] memory _tokenAddress,
        address[] memory  _chainlinkFeedAddress,
        bool[] memory _enabled,
        uint256[] memory _decimals
         
        )
        external
        onlyPriceFeedTokenRole(msg.sender)
    {   
        
        require((_tokenAddress.length == _chainlinkFeedAddress.length) && (_enabled.length == _decimals.length));
        for(uint256 i = 0 ; i < _tokenAddress.length; i++){
            require(!_isAddedChainlinkFeedAddress(_chainlinkFeedAddress[i]), "GPC: already added price feed");
            this.addUsdPriceAggrigator(_tokenAddress[i], _chainlinkFeedAddress[i], _enabled[i], _decimals[i]);
            allFeedTokensContractChainlink.push(_chainlinkFeedAddress[i]);
            allFeedTokenAddress.push(_tokenAddress[i]);
        }
        emit PriceFeedAddedBulk(_tokenAddress, _chainlinkFeedAddress, _enabled, _decimals);
    }
   

    /**
    @dev Removes a token for which getLatestUsdPrice or getLatestUsdPrices can not be called now.
    *@param _tokenAddress The token for price feed.
    */
    function removePriceAggrigator(address _tokenAddress )
        external
        onlyPriceFeedTokenRole(msg.sender)
    {
        delete (usdPriceAggrigators[_tokenAddress]);
        emit PriceFeedRemoved(_tokenAddress);
    }
    
    /**
     * Use chainlink PriceAggrigator to fetch prices of the already added feeds.
     */
    function getLatestUsdPriceFromChainlink(address priceFeedToken) 
        external 
        view 
        override
        returns (int,uint8) 
    {
        (,int price,,,) = usdPriceAggrigators[priceFeedToken].usdPriceAggrigator.latestRoundData();
        uint8 decimals = usdPriceAggrigators[priceFeedToken].usdPriceAggrigator.decimals();

        return (price, decimals);
    }

    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken) 
        external 
        view
        override 
        returns (
            address[] memory tokens,  
            int[] memory prices,
            uint8[] memory decimals
        ) 
    {
        decimals = new uint8[](priceFeedToken.length);
        tokens = new address[](priceFeedToken.length);
        prices = new int[](priceFeedToken.length);
        for(uint i = 0 ; i< priceFeedToken.length ; i++){
            (,int price,,,) = usdPriceAggrigators[priceFeedToken[i]].usdPriceAggrigator.latestRoundData();
            decimals[i] = usdPriceAggrigators[priceFeedToken[i]].usdPriceAggrigator.decimals();
            tokens[i] = priceFeedToken[i];
            prices[i] = price;
        }
        return (tokens, prices, decimals);
    }
    
    /**
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _amount address of alt
     */
    function getDexTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
        ) external view override returns (uint256) {
        
        Market memory marketData = govProtocolRegistry.getSingleApproveToken(_alt);
        
        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(marketData.dexRouter);

        IDexPair pair;

        if(marketData.dexRouter != address(0x0)) {
        pair = IDexPair(IDexFactory(swapRouter.factory()).getPair(_stable, _alt));
        }
         else {
        pair = IDexPair(IDexFactory(swapRouterv2.factory()).getPair(_stable, _alt));
        
        }
        uint256 token0Decimals = IERC20Extras(pair.token0()).decimals();
        uint256 token1Decimals = IERC20Extras(pair.token1()).decimals();

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pair.token0() == _stable) {
            
            uint256 resD = res0 * (10**token1Decimals);//18+18  decimals
            return (_amount.mul(resD.div(res1))).div(10**token1Decimals); // (18+(18-18))-18 = 0 = stable coin decimals

        } else {

            uint256 resD = res1 * (10**token0Decimals);
            return (_amount.mul(resD.div(res0))).div(10**token0Decimals); // 
        }
    }

    function getClaimTokenPrice(
        address _stable,
        address _claimToken,
        uint256 _amount
        ) external view override returns (uint256) {
        
        require(govClaimTokenContract.isClaimToken(_claimToken), "GPC: not approved claim token");
        ClaimTokenData memory claimTokenData = govClaimTokenContract.getClaimTokensData(_claimToken);
        
        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(claimTokenData.dexRouter);

        IDexPair pair;

        if(claimTokenData.dexRouter != address(0x0)) {
        pair = IDexPair(IDexFactory(swapRouter.factory()).getPair(_stable, _claimToken));
        }
         else {
        pair = IDexPair(IDexFactory(swapRouterv2.factory()).getPair(_stable, _claimToken));
        
        }
        uint256 token0Decimals = IERC20Extras(pair.token0()).decimals();
        uint256 token1Decimals = IERC20Extras(pair.token1()).decimals();

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pair.token0() == _stable) {
            
            uint256 resD = res0 * (10**token1Decimals);//18+18  decimals
            return (_amount.mul(resD.div(res1))).div(10**token1Decimals); // (18+(18-18))-18 = 0 = stable coin decimals

        } else {

            uint256 resD = res1 * (10**token0Decimals);
            return (_amount.mul(resD.div(res0))).div(10**token0Decimals); // 
        }
    }

    /**
    @dev this function will get the price of native token and will assign the price according to the derived SUN tokens
    @param _claimToken address of the approved claim token
    @param _sunToken address of the SUN token
     */
    function getSUNTokenPrice(address _claimToken, address _stable, address _sunToken, uint256 _amount) external view override returns(uint256) {

        require(govClaimTokenContract.isClaimToken(_claimToken), "GPC: not approved claim token");
        ClaimTokenData memory claimTokenData = govClaimTokenContract.getClaimTokensData(_claimToken);
        
        address sunTokenAddress;
        uint256 sunTokenPricePercentage;
        uint256 claimTokenPrice = this.getClaimTokenPrice(_stable, _claimToken, _amount);

        for(uint i = 0; i < claimTokenData.sunTokens.length; i++) {
            if(claimTokenData.sunTokens[i] == _sunToken) {
                sunTokenAddress = claimTokenData.sunTokens[i];
                sunTokenPricePercentage = claimTokenData.sunTokenPricePercentage[i];
            }
        }
        
        return (claimTokenPrice.mul(sunTokenPricePercentage)).div(10000);
        
    } 

     /**
     * Use chainlink PriceAggrigator to fetch prices of the network coin.
     */
    function getNetworkPriceFromChainlinkinUSD() 
        external 
        view 
        override
        returns (int) 
    {
        (,int price,,,) = networkCoinUsdPriceFeed.latestRoundData();
        return price;
    }

    
    function getSwapData(
        address _collateralToken,
        uint256  _collateralAmount,
        address _borrowStableCoin
    ) external view override returns(uint,uint) {

        Market memory marketData = govProtocolRegistry.getSingleApproveToken(_collateralToken);
        
        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(marketData.dexRouter);

        IDexPair pair;

        if(marketData.dexRouter != address(0x0)) {
        pair = IDexPair(IDexFactory(swapRouter.factory()).getPair(_borrowStableCoin, _collateralToken));
        }
         else {
        pair = IDexPair(IDexFactory(swapRouterv2.factory()).getPair(_borrowStableCoin, _collateralToken));
        
        }

        (uint256 reserveIn,  uint256 reserveOut,) = IDexPair(pair).getReserves();
        uint amountOut = swapRouter.getAmountOut(_collateralAmount, reserveIn, reserveOut);
        uint amountIn = swapRouter.getAmountIn(amountOut, reserveIn, reserveOut);
        return (amountIn, amountOut);
    }

    function getNetworkCoinSwapData(
        address _collateralToken,
        uint256  _collateralAmount,
        address _borrowStableCoin
    ) external view override returns(uint,uint){

        Market memory marketData = govProtocolRegistry.getSingleApproveToken(_collateralToken);
        
        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(marketData.dexRouter);

        IDexPair pair;
        //get pair address of the altcoin and stable address 
        if(marketData.dexRouter != address(0x0)) {
            pair = IDexPair(IDexFactory(swapRouter.factory()).getPair(_collateralToken, _borrowStableCoin));
        }
         else {
            pair = IDexPair(IDexFactory(swapRouterv2.factory()).getPair(_collateralToken, _borrowStableCoin));
        
        }
        (uint256 reserveIn,  uint256 reserveOut,) = IDexPair(pair).getReserves();
        uint amountOut = swapRouter.getAmountOut(_collateralAmount, reserveOut, reserveIn);
        uint amountIn = swapRouter.getAmountIn(amountOut, reserveOut, reserveIn);
        return (amountIn, amountOut);
    }

    function getSwapInterface(address _approvedCollateralToken) external view override returns (address)
    {
        Market memory marketData = govProtocolRegistry.getSingleApproveToken(_approvedCollateralToken);
        
        // swap router address uniswap or sushiswap or any uniswap like modal dex
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(marketData.dexRouter);
        return address(swapRouter);
    }

    function getSwapInterfaceForETH() external view override returns (address)
    {
        return address(swapRouterv2);
    }

    function isChainlinFeedEnabled(address _tokenAddress) external view override returns(bool) {

        return usdPriceAggrigators[_tokenAddress].enabled;

    }

    function getusdPriceAggrigators(address _tokenAddress) external view override returns(ChainlinkDataFeed  memory) {
        return usdPriceAggrigators[_tokenAddress];
    }


    function getAllChainlinkAggiratorsContract() external view override returns(address[] memory) {
        return allFeedTokensContractChainlink;
    }

    function getAllGovAggiratorsTokens() external view override returns(address[] memory) {
        return allFeedTokenAddress;
    }

    function WETHAddress() external view override returns(address) {
        return swapRouterv2.WETH();
    }

/**
    @dev Calculates LTV based on dex token price
    @param _stakedCollateralAmounts ttoken amounts
    @param _stakedCollateralTokens token contracts.
    @param _loanAmount total borrower loan amount in borrowed token.
     */
    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts, 
        address[] memory _stakedCollateralTokens, 
        address  _borrowedToken,
        uint256 _loanAmount
    )
        external
        view
        override
        returns (uint256)
    {
        //IERC20Extras stableDecimals = IERC20Extras(stkaedCollateralTokens);
        uint256 totalCollateralInBorrowedToken;
        
        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
            
            uint256 collatetralInBorrowed;
            address claimToken = govClaimTokenContract.getClaimTokenofSUNToken(_stakedCollateralTokens[i]);

            if(govClaimTokenContract.isClaimToken(claimToken)) {
                 collatetralInBorrowed = collatetralInBorrowed.add(this.getSUNTokenPrice(claimToken,_borrowedToken, _stakedCollateralTokens[i], _stakedCollateralAmounts[i]));
            } else {
                 collatetralInBorrowed = collatetralInBorrowed.add(this.getAltCoinPriceinStable(_borrowedToken, _stakedCollateralTokens[i], _stakedCollateralAmounts[i]));
            }

           totalCollateralInBorrowedToken = totalCollateralInBorrowedToken.add(collatetralInBorrowed); 
        }
        return
            (totalCollateralInBorrowedToken.mul(100)).div(
                _loanAmount
            );
    }

    /**
    @dev function to get altcoin amount in stable coin.
    @param _stableCoin of the altcoin
    @param _altCoin address of the stable
    @param _collateralAmount amount of altcoin
     */
    function getAltCoinPriceinStable(
        address _stableCoin, 
        address _altCoin, 
        uint256 _collateralAmount
        ) external view override returns(uint256) 
        {
    
        uint256 collateralAmountinStable;
        if(this.isChainlinFeedEnabled(_altCoin) && this.isChainlinFeedEnabled(_stableCoin)) {
               
                (int collateralChainlinkUsd, uint8 atlCoinDecimals) = this.getLatestUsdPriceFromChainlink(_altCoin);
                uint256 collateralUsd = (uint256(collateralChainlinkUsd) * _collateralAmount).div(atlCoinDecimals); 
                (int priceFromChainLinkinStable, uint8 stableDecimals) = this.getLatestUsdPriceFromChainlink(_stableCoin);
                collateralAmountinStable = collateralAmountinStable.add(collateralUsd.div(uint256(priceFromChainLinkinStable)).mul(stableDecimals));
                return collateralAmountinStable;
        }
        else {
                collateralAmountinStable = collateralAmountinStable.add(this.getDexTokenPrice(_stableCoin, _altCoin, _collateralAmount));
                return collateralAmountinStable;
        } 
        
    }


   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
interface IDexFactory {
    
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IDexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface  IERC20Extras{
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 struct ChainlinkDataFeed {
    AggregatorV3Interface usdPriceAggrigator;
    bool enabled;
    uint256 decimals;
}

interface IGovPriceConsumer {

   
    event PriceFeedAdded(address indexed token, address usdPriceAggrigator, bool enabled, uint256 decimals);
    event PriceFeedAddedBulk(address[] indexed tokens, address[] chainlinkFeedAddress, bool[] enabled, uint256[] decimals);
    event PriceFeedRemoved(address indexed token);
    

    
    /**
     * Use chainlink PriceAggrigator to fetch prices of the already added feeds.
     */
    function getLatestUsdPriceFromChainlink(address priceFeedToken)  external view returns (int,uint8); 

    /**
    @dev multiple token prices fetch
    @param priceFeedToken multi token price fetch
    */
    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken) external view returns (
            address[] memory tokens,  
            int[] memory prices,
            uint8[] memory decimals
        );

    function getNetworkPriceFromChainlinkinUSD() external view returns (int);

    function getSwapData(
        address _collateralToken,
        uint256  _collateralAmount,
        address _borrowStableCoin
    ) external view returns(uint,uint);

    function getNetworkCoinSwapData(
        address _collateralToken,
        uint256  _collateralAmount,
        address _borrowStableCoin
    ) external view returns(uint,uint);
    
    function getSwapInterface(address _collateralTokenAddress) external view returns (address);

    function getSwapInterfaceForETH() external view returns (address);

    /**
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _amount address of alt
     */
    function getDexTokenPrice(address _stable, address _alt, uint256 _amount) external view returns (uint256);

    //check wether token feed for this token is enabled or not
    function isChainlinFeedEnabled(address _tokenAddress) external view returns(bool);

    function getusdPriceAggrigators(address _tokenAddress) external view returns(ChainlinkDataFeed  memory);

    function getAllChainlinkAggiratorsContract() external view returns(address[] memory);

    function getAllGovAggiratorsTokens() external view returns(address[] memory);

    function WETHAddress() external view returns(address);

    function getAltCoinPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    function getClaimTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
        ) external view returns (uint256);

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts, 
        address[] memory _stakedCollateralTokens, 
        address  _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256);

     function getSUNTokenPrice(
         address _claimToken,
         address _stable,
         address _sunToken,
         uint256 _amount) 
        external view returns(uint256);

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;

        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin)external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

     //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns(bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// Token Market Data
struct Market {
    address dexRouter;
    bool isSP;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
    bool isMint;
    bool isClaimToken;
}


interface IGovWorldProtocolRegistry {
    
    
    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param  _market of the _tokenAddress
    */
    function addTokens(address[] memory _tokenAddress, Market[] memory _market)
        external;

    /**
     *@dev function to update the token market data
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _marketData struct to update the token market
     */
    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external;

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetokens(address[] memory _removeTokenAddress) external;


    /**
    @dev add sp wallet to the mapping approvedSps
    @param _tokenAddress token contract address
    @param _walletAddress sp wallet address to add  
    */

    function addSp(address _tokenAddress, address _walletAddress) external;

    /**
    @dev remove sp wallet from mapping
    @param _tokenAddress token address as a key to remove sp
    @param _removeWalletAddress sp wallet address to be removed 
    */

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external;

    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external;

    /**
     *@dev function to update the sp wallet
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _oldWalletAddress old wallet address to be updated
     *@param _newWalletAddress new wallet address
     */
    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external;

    /**
    @dev external function update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external;

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external;

    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns(uint256);
    function getThresholdPercentage() external view returns(uint256);
    function getAutosellPercentage() external view returns(uint256);

    function getAdminWalletPercentage() external view returns(uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getTokenMarket() external view returns(address[] memory);

    function getAdminFeeWallet() external view returns(address);

    function getSingleTokenSps(address _tokenAddress) external view returns (address[] memory);

    function isAddedSPWallet(
        address _tokenAddress,
        address _walletAddress
    ) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

struct ClaimTokenData {
        address[] sunTokens;
        uint256[] sunTokenPricePercentage;
        address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
}

interface IGovClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress) external view returns (ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}