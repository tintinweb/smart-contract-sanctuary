/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/**********************************************************
 * Main Contract: PreachersCompFiLqdt v1.0.12 KOVAN
 **********************************************************/
pragma solidity ^0.8.5;

// AAVE
// import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/FlashLoanReceiverBase.sol";
// import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPoolAddressesProvider.sol";
// import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";

/**
* @title IFlashLoanReceiver interface
* @notice Interface for the Aave fee IFlashLoanReceiver.
* @author Aave
* @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
**/
interface IFlashLoanReceiver {
    function executeOperation( address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params ) external;
}
/************************** AAVE 
contract Flashloan is FlashLoanReceiverBase {
    constructor( address _addressProvider ) FlashLoanReceiverBase( _addressProvider ) public {}
}
**************************/

// AAVE  https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol
interface ILendingPool {
  function addressesProvider ( ) external view returns ( address );
  function deposit ( address _reserve, uint256 _amount, uint16 _referralCode ) external payable;
  function redeemUnderlying ( address _reserve, address _user, uint256 _amount ) external;
  function borrow ( address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode ) external;
  function repay ( address _reserve, uint256 _amount, address _onBehalfOf ) external payable;
  function swapBorrowRateMode ( address _reserve ) external;
  function rebalanceFixedBorrowRate ( address _reserve, address _user ) external;
  function setUserUseReserveAsCollateral ( address _reserve, bool _useAsCollateral ) external;
  function liquidationCall ( address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken ) external payable;
  function flashLoan ( address _receiver, address _reserve, uint256 _amount, bytes calldata _params ) external;
  function getReserveConfigurationData ( address _reserve ) external view returns ( uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive );
  function getReserveData ( address _reserve ) external view returns ( uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp );
  function getUserAccountData ( address _user ) external view returns ( uint256 totalLiquidityETH, uint256 totalCollateralETH, uint256 totalBorrowsETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor );
  function getUserReserveData ( address _reserve, address _user ) external view returns ( uint256 currentATokenBalance, uint256 currentUnderlyingBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled );
  function getReserves ( ) external view;
}

// AAVE https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPoolAddressesProvider.sol
/**
    @title ILendingPoolAddressesProvider interface
    @notice provides the interface to fetch the LendingPoolCore address
 */
interface ILendingPoolAddressesProvider {
    function getLendingPoolCore( ) external view returns ( address payable );
    function getLendingPool( ) external view returns ( address );
}


interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token ( externally )
      Sell,      // sell an amount of some token ( externally )
      Trade,     // trade tokens against another account
      Liquidate, // liquidate an undercollateralized or expiring account
      Vaporize,  // use excnt is denominated in wei
      Call       // send arbitrary data to an address
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    enum AssetDenomination { Wei, Par }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

interface ERC20 {
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
  function allowance( address owner, address spender ) external view returns ( uint256 );
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
  function approve ( address spender, uint256 amount ) external returns ( bool );
    /**
     * @dev Returns the amount of tokens owned by `account`.
     **/
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function borrow( uint borrowAmount ) external returns ( uint );
  function borrowBalanceCurrent( address account ) external returns ( uint );
  function borrowBalanceStored( address account ) external view returns ( uint256 );
  function decimals (   ) external view returns ( uint256 );
  function exchangeRateCurrent(  ) external returns ( uint );
  function getAccountSnapshot( address account ) external view returns ( uint, uint, uint, uint );
  function liquidateBorrow ( address borrower, uint256 repayAmount, address cTokenCollateral ) external returns ( uint256 );
  /************
   * The mint function transfers an asset into the CompFi protocol, which begins 
   * accumulating interest based on the current Supply Rate for the asset. 
   * The user receives a quantity of cTokens equal to the underlying 
   * tokens supplied, divided by the current Exchange Rate.
   * **********/
  function mint ( uint256 mintAmount ) external returns ( uint256 );
  /**********
   * redeem function converts a specified quantity of cTokens into the underlying asset, 
   * and returns them to the user.
   * redeemTokens - numberr of tokens to convert to the underlying token.
   * RETURN: 0 on success, otherwise an Error code.
   * ********/
  function redeem( uint redeemTokens ) external returns ( uint );
  /**
   * redeem underlying function converts cTokens into a specified quantity of the 
   * underlying asset, and returns them to the user.
   * redeemAmount - number of underlying tokens desired, depends on the exchange rate
   **/
  function redeemUnderlying( uint redeemAmount ) external returns ( uint );
  /******************
   * The repay function transfers an asset into the protocol,
   * reducing the user's borrow balance.
   * RETURN: 0 on success, otherwise an Error code.
   * ****************/
  function repayBorrow( uint repayAmount ) external returns ( uint );
  function repayBorrowBehalf( address borrower, uint repayAmount ) external returns ( uint );
  function symbol (  ) external view returns ( string memory );
    /**
     * @dev Returns the amount of tokens in existence.
     */
  function totalSupply ( ) external view returns ( uint256 supply );
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transfer ( address dst, uint256 amount ) external returns ( bool );
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
  function underlying (  ) external view returns ( address );
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
  event Approval( address indexed _owner, address indexed _spender, uint256 _value );
    /**
     * @dev Emitted when `value` tokens are moved from one account ( `from` ) to
     * another ( `to` ).
     *
     * Note that `value` may be zero.
     */
  event Transfer( address indexed from, address indexed to, uint256 value );
}

/*************************************
interface ICorWETH {
  function liquidateBorrow ( address borrower, address cTokenCollateral ) external payable;
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function decimals (  ) external view returns ( uint256 );
  function symbol (  ) external view returns ( string memory );
  function totalSupply( ) external view returns ( uint256 supply );
  function transfer ( address dst, uint256 amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
  event Approval( address indexed _owner, address indexed _spender, uint256 _value );
}
************************************/

interface Comptroller {

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param cToken The cToken to check
     * @return True if the account is in the asset, otherwise false.
     */
  function checkMembership ( address account, address cToken ) external view returns ( bool );
  
    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
  function closeFactorMantissa (  ) external view returns ( uint256 );

  function enterMarkets ( address[] memory cTokens ) external returns ( uint256[] memory );

  function exitMarket ( address cTokenAddress ) external returns ( uint256 );

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return ( possible error code ( semi-opaque ),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements )
     */
  function getAccountLiquidity ( address account ) external view returns ( uint256, uint256, uint256 );

  function getAllMarkets (  ) external view returns ( address[] memory );

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
  function getAssetsIn ( address account ) external view returns ( address[] memory );

  function liquidateBorrowAllowed ( address cTokenBorrowed, address cTokenCollateral, address liquidator, address borrower, uint256 repayAmount ) external returns ( uint256 );

  function liquidateBorrowVerify ( address cTokenBorrowed, address cTokenCollateral, address liquidator, address borrower, uint256 actualRepayAmount, uint256 seizeTokens ) external;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
  function liquidationIncentiveMantissa (  ) external view returns ( uint256 );
}

interface ISimpleKyberProxy {
    function swapTokenToEther( 
        ERC20 token,
        uint256 srcAmount,
        uint256 minConversionRate
    ) external returns ( uint256 destAmount );

    function swapEtherToToken( ERC20 token, uint256 minConversionRate )
        external
        payable
        returns ( uint256 destAmount );

    function swapTokenToToken( 
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        uint256 minConversionRate
    ) external returns ( uint256 destAmount );
}

interface IKyberNetworkProxy {
    /// @notice Rate units ( 10 ** 18 ) => destQty ( twei ) / srcQty ( twei ) * 10 ** 18
    function getExpectedRate( ERC20 src, ERC20 dest, uint srcQty ) external view 
        returns ( uint expectedRate, uint worstRate );
}

// dYdX flash loan contract
interface ISoloMargin {
    function operate( Account.Info[] memory accounts, Actions.ActionArgs[] memory actions ) external;
}

abstract contract DyDxPool is Structs {
    function getAccountWei( Info memory account, uint256 marketId ) public virtual view returns ( Wei memory );
    function operate( Info[] memory, ActionArgs[] memory ) public virtual;
}

address constant kETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


/******************************************************************************************
 * addresses at https://github.com/compound-finance/compound-protocol/tree/master/networks
*******************************************************************************************/
/***************************** Ropsten ********************************************************
//    "Ropsten Contracts"
address constant kCompoundLens = 0xEF11D1eff9C559B47B921dFFfF1e3A147e84E283;  // Ropsten
address constant kZRX = 0xc0e2D7d9279846B80EacdEa57220AB2333BC049d;  // Ropsten
address constant kWBTC = 0x442Be68395613bDCD19778e761f03261ec46C06D;  // Ropsten
address constant kUSDT = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;  // Ropsten
address constant kUSDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;  // Ropsten
address constant kSAI = 0x63F7AB2f24322Ae2eaD6b971Cb9a71A1CC2eee03;  // Ropsten
address constant kREP = 0xb1cBa8b721C7a241b9AD08C17F328886B014ACfE;  // Ropsten
address constant kDAI = 0x31F42841c2db5173425b5223809CF3A38FEde360;  // Ropsten
address constant kBAT = 0x50390975D942E83D661D4Bde43BF73B0ef27b426;  // Ropsten
address constant kFauceteer = 0x9C3F0FC85EF9144412388e7E952eb505e2c4a10F;  // Ropsten
address constant kPriceFeed = 0xb90c96607b45f9bB7509861A1CE77Cb8a72EdFB2;  // Ropsten
address constant kComp = 0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075;  // Ropsten
address constant kTimelock = 0x2079A734292094702f4D7D64A59e980c20652Cae;  // Ropsten
address constant kPriceData = 0x466dcF37201199792102A8fB12876Df60B4B2731;  // Ropsten
address constant kWETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;  // Ropsten
address constant kUniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;  // Ropsten
address constant kuni = 0xC8F88977E21630Cf93c02D02d9E8812ff0DFC37a;  // Ropsten
address constant kGovernorAlpha = 0x0782ccc8912A177ac6b9287394e71dAacf779B83;  // Ropsten
address constant kGovernorBravo = 0x087e98B40f988E0E1D1de476b2b8d2271Ac84B33;  // Ropsten
address constant kPair_ETH_ZRX = 0x5c40A4596519EfEA94231E6346aeD20A7CF2B587;  // Ropsten
address constant kPair_COMP_ETH = 0xdA68B0BC70e177d82c4AA308654C79dc97bD8466;  // Ropsten
address constant kPair_DAI_ETH = 0x084375803b1661c40934dCc4E82B7d9A29c0Bc66;  // Ropsten
address constant kPair_WBTC_ETH = 0x8f5e4BFCFC4ed5b42167E5A087246CBc75A27a1c;  // Ropsten
address constant kPair_REP_ETH = 0x921B3E9eD380e0A6AF99Ec019382aDfe154cab0a;  // Ropsten
address constant kPair_BAT_ETH = 0x392f8f7B580981EEBb94056ffefEd0adE4698695;  // Ropsten
address constant kPair_ETH_USDC = 0xd07CBEC4b1BFFFf9557967668e40ef7b125614F8;  // Ropsten
address constant kStdComptrollerG4 = 0x0F7b5f9dd2457884aE5fe4b1604c4A54a3097689;  // Ropsten
address constant kUnitroller = 0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152;  // Ropsten
address constant kcZRX = 0x6B8b0D7875B4182Fb126877023fB93b934dD302A;  // Ropsten
address constant kcWBTC = 0x541c9cB0E97b77F142684cc33E8AC9aC17B1990F;  // Ropsten
address constant kcUSDT = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;  // Ropsten
address constant kcUSDC = 0x2973e69b20563bcc66dC63Bde153072c33eF37fe;  // Ropsten
address constant kcETH = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;  // Ropsten
address constant kcSAI = 0x7Ac65E0f6dBA0EcB8845f17d07bF0776842690f8;  // Ropsten
address constant kcREP = 0x2862065D57749f1576F48eF4393eb81c45fC2d88;  // Ropsten
address constant kcDAI = 0xbc689667C13FB2a04f09272753760E38a95B998C;  // Ropsten
address constant kcBAT = 0xaF50a5A6Af87418DAC1F28F9797CeB3bfB62750A;  // Ropsten
address constant kReservoir = 0xC84BaE82A99459b81f13298c5b64F094Bff1F96d;  // Ropsten
address constant kopen_oracle = 0x67dEcEb223d2dB9B1e2018f5efC2fbdF484A79b7;  // Ropsten
address constant kMaximillion = 0x8f4abdBA752aa40F6BeEaD5d3ba2b648c7B4606B;  // Ropsten
address constant kcCOMP = 0x70014768996439F71C041179Ffddce973a83EEf2;  // Ropsten
address constant kg6 = 0x3031CdF18ad861B7C241a589e73D543380F5eb01;  // Ropsten
address constant kcUNI = 0x65280b21167BBD059221488B7cBE759F9fB18bB5;  // Ropsten
address constant kComptroller = 0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152;  // Ropsten
address constant kPriceOracleProxy = 0xb90c96607b45f9bB7509861A1CE77Cb8a72EdFB2;  // Ropsten
address constant kPriceFeedPoster = 0x83563ba7F1B093aae57Fe876f8D870f8a1508886;  // Ropsten
address constant kStarport = 0xD905AbBA1C5Ea48c0598bE9F3f8ae31290B58613;  // Ropsten
address constant kCASH = 0xc65a4A1855d314033530A29Ab993A1717879E5BF;  // Ropsten
address constant kStarportImpl = 0xed5DdA5976ec5F29910426d7876eBD6f307e0934;  // Ropsten
address constant kCashImpl = 0x1ffe465b3c82499e1C637c02EFECD128B7B454CF;  // Ropsten
address constant kProxyAdmin = 0xd418B3A7c4a2b9d60fF8dDf9E94a8b75Aa3f60A5;  // Ropsten


// KyberNetwork Ropsten addresses: https://developer.kyber.network/docs/Environments-Ropsten/
address constant kKyberNetworkProxy = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;  // Ropsten
address constant kKyberNetwork = 0x753FE1914dB38EE744E071BAaDd123F50F9c8E46;  // Ropsten
address constant kKyberReserve = 0xEB52Ce516a8d054A574905BDc3D4a176D3a2d51a;  // Ropsten
**********************************************************************************************/

/****************************************************************************************/
//    "Kovan Contracts"

//      dYdX SoloMargin Contract
address constant kDyDxPool = 0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE;    // Kovan

address constant kComp = 0x61460874a7196d6a22D1eE4922473664b3E95270;    // Kovan
address constant kCompoundLens = 0x08CcdB87966C4C7c3Ce7dA8C103c8E14627753D0;    // Kovan
address constant kStdComptrollerG1 = 0x670d9C026025Ce445D7517EBD9e3dE770527D44d;    // Kovan
address constant kcErc20Delegate = 0x04356935Dc49753aD1Afb8EeebD0ae473eF1D6AB;    // Kovan
address constant kZRX = 0x162c44e53097e7B5aaE939b297ffFD6Bf90D1EE3;    // Kovan
address constant kWBTC = 0xd3A691C852CDB01E281545A27064741F0B7f6825;    // Kovan
address constant kUSDT = 0x07de306FF27a2B630B1141956844eB1552B956B5;    // Kovan
address constant kUSDC = 0xb7a4F3E9097C08dA09517b5aB877F7a917224ede;    // Kovan
address constant kSAI = 0xD1308F63823221518Ec88EB209CBaa1ac182105f;    // Kovan
address constant kREP = 0x50DD65531676F718B018De3dc48F92B53D756996;    // Kovan
address constant kDAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;    // Kovan
address constant kBAT = 0x482dC9bB08111CB875109B075A40881E48aE02Cd;    // Kovan
address constant kFauceteer = 0x916518711a75a98Ac00e8E3386d036F7eA56A484;    // Kovan
address constant kPriceFeed = 0xbBdE93962Ca9fe39537eeA7380550ca6845F8db7;    // Kovan
address constant kStdComptrollerG3 = 0xbDF4D9A65023CAf0DaDa604cf46C44D5aab0bb0C;    // Kovan
address constant kTimelock = 0xE3e07F4F3E2F5A5286a99b9b8DEed08B8e07550B;    // Kovan
address constant kJug = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;    // Kovan
address constant kPot = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;    // Kovan
address constant kcDaiDelegate = 0xC8016288dB9dFE5a1cA2503879dCDE8807377186;    // Kovan
address constant kUnitroller = 0x5eAe89DC1C671724A672ff0630122ee834098657;    // Kovan
address constant kcZRX = 0xAf45ae737514C8427D373D50Cd979a242eC59e5a;    // Kovan
address constant kcWBTC = 0xa1fAA15655B0e7b6B6470ED3d096390e6aD93Abb;    // Kovan
address constant kcUSDT = 0x3f0A0EA2f86baE6362CF9799B523BA06647Da018;    // Kovan
address constant kcUSDC = 0x4a92E71227D294F041BD82dd8f78591B75140d63;    // Kovan
address constant kcETH = 0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72;    // Kovan
address constant kcSAI = 0xb3f7fB482492f4220833De6D6bfCC81157214bEC;    // Kovan
address constant kcREP = 0xA4eC170599a1Cf87240a35b9B1B8Ff823f448b57;    // Kovan
address constant kcBAT = 0x4a77fAeE9650b09849Ff459eA1476eaB01606C7a;    // Kovan
address constant kReservoir = 0x33deD5C4eA51dBC7AF955396839655EFe13E3F1b;    // Kovan
address constant kGovernorAlpha = 0x665a5f09716d63D9256934855b0CE2056a5C4Cf8;    // Kovan
address constant kGovernorBravo = 0x100044C436dfb66FF106157970bC89f243411Ffd;    // Kovan
address constant kMaximillion = 0xC363f83902Ac614F318b04771d21D25aC0d73be5;    // Kovan
address constant kcDAI = 0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD;    // Kovan
address constant kStdComptrollerG2 = 0xd026627b0D6326dbA5f3c9ecbca1545dB8CD3486;    // Kovan
address constant kStdComptrollerG4 = 0x35cf8e1F268680Db66119DAe1bffEa136491939a;    // Kovan
address constant kKNC = 0x99e467eCe562E00D1e8f17F67E5485CF97b306EB;    // Kovan
address constant kLINK = 0x1674E2c454275bC1AE9EA30A110d6C937039eA9c;    // Kovan
address constant kPriceData = 0x4819cFa37f57A1f2BCfa9daa8b971d00faf83600;    // Kovan
address constant kWETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;    // Kovan
address constant kUniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;    // Kovan
address constant kPair_ETH_ZRX = 0x503EeEeaD9A30ca4bA71750060ca3bBd69da2677;    // Kovan
address constant kPair_ETH_KNC = 0xEbdEA7AeEf046a366c0E5a83BCe5fAeA82194eea;    // Kovan
address constant kPair_COMP_ETH = 0x0fd905006e24458e8b8eC1607433aF9d1498b6C1;    // Kovan
address constant kPair_LINK_ETH = 0x1372144c1ac4d16d7f99C69f04E5c158d29CCf15;    // Kovan
address constant kPair_DAI_ETH = 0x9Df79A39Defca2f3635637A085A56cfcBac5Ee84;    // Kovan
address constant kPair_WBTC_ETH = 0x34212cA2d386Bf8C543552889B8C0D47365fe96a;    // Kovan
address constant kPair_REP_ETH = 0x74853144626d7171FdeDfd3E0D4ed52d718A4eca;    // Kovan
address constant kPair_BAT_ETH = 0x574300Af7ff45485254538303718Cc7B032d1f30;    // Kovan
address constant kPair_ETH_USDC = 0x4e8d753812879407f8341105eef9a43fc8f350A2;    // Kovan
address constant koracle = 0x37ac0cb24b5DA520B653A5D94cFF26EB08d4Dc02;    // Kovan
address constant kCrowdProposalFactory = 0x1CcD74460eE10f25c3A24c08972F39215393Fa58;    // Kovan
address constant kComptroller = 0x5eAe89DC1C671724A672ff0630122ee834098657;    // Kovan
address constant kPriceFeedPoster = 0x83563ba7F1B093aae57Fe876f8D870f8a1508886;    // Kovan
address constant kCommunityComptroller = 0xA06058e40d6a6Dd0D5Dc4c6C394864BCA74d3002;    // Kovan
address constant kPriceOracle = 0x37ac0cb24b5DA520B653A5D94cFF26EB08d4Dc02;    // Kovan
address constant kPriceOracleProxy = 0x37ac0cb24b5DA520B653A5D94cFF26EB08d4Dc02;    // Kovan

// Kyber Kovan Test Network
address constant kKyberNetworkProxy = 0xc153eeAD19e0DBbDb3462Dcc2B703cC6D738A37c; // KOVAN
	// IKyberNetworkProxy: Fetch rates and execute trades
address constant kKyberNetworkProxyV1 = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // KOVAN

address constant kKyberStorage = 0xB18D90bE9ADD2a6c9F2c3943B264c3dC86E30cF5; // KOVAN
	// IKyberStorage: Get reserve IDs for building hints

address constant kKyberHintHandler = 0x9Cf739155941A3A7964E711543A8BC902613fF17; // KOVAN
	// IKyberHint: Building and parsing hints

address constant kKyberFeeHandlerETH = 0xA943b542D1d5683d3454bD0D7EE86C48F36eCFd5; // KOVAN
	// IKyberFeeHandler: Claim staker rewards, reserve rebates or platform fees

address constant kKyberReserve = 0x45460BD0f9a68b98Bf1f5c478B7584E057e32eF5; // KOVAN
	// IKyberReserve: Fetch rates of a specific reserve

address constant kConversionRates = 0x6B2e614977F893baddf3AA704698BD71BEf9CeFF; // KOVAN

address constant kMANA = 0xcb78b457c1F79a06091EAe744aA81dc75Ecb1183;	// Kovan
address constant kMKR = 0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD;	// Kovan
address constant kOMG = 0xdB7ec4E4784118D9733710e46F7C83fE7889596a;	// Kovan
address constant kPOLY = 0xd92266fd053161115163a7311067F0A4745070b5;	// Kovan
address constant kSALT = 0x6fEE5727EE4CdCBD91f3A873ef2966dF31713A04;	// Kovan
address constant kSNT = 0x4c99B04682fbF9020Fcb31677F8D8d66832d3322;	// Kovan
address constant kZIL = 0xAb74653cac23301066ABa8eba62b9Abd8a8c51d6;	// Kovan
/****************************************************************************************/

// address constant kETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

/**********************************************************
 *   Mainnet  *  * 
 * ********************************************************/
/****************************************************************************************

//      dYdX SoloMargin contract
address constant kDyDxPool = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;    // Mainnet

address constant kBase0bps_Slope2000bps = 0xc64C4cBA055eFA614CE01F4BAD8A9F519C4f8FaB;    // Mainnet
address constant kBase200bps_Slope1000bps = 0x0C3F8Df27e1A00b47653fDE878D68D35F00714C0;    // Mainnet
address constant kBase200bps_Slope2000bps_Jump20000bps_Kink90 = 0x6bc8fE27D0c7207733656595e73c0D5Cf7AfaE36;    // Mainnet
address constant kBase200bps_Slope2000bps_Jump8000bps_Kink90 = 0x40C0C2c565335fa9C4235aC8E1CbFE2c97BAC13A;    // Mainnet
address constant kBase200bps_Slope222bps_Kink90_Jump40 = 0x5562024784cc914069d67D89a28e3201bF7b57E7;    // Mainnet
address constant kBase200bps_Slope3000bps = 0xBAE04CbF96391086dC643e842b517734E214D698;    // Mainnet
address constant kBase500bps_Slope1200bps = 0xa1046abfc2598F48C44Fb320d281d3F3c0733c9a;    // Mainnet
address constant kBase500bps_Slope1500bps = 0xD928c8eAD620Bb316D2cEfe3CAF81dC2dec6Ff63;    // Mainnet
address constant kBAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;    // Mainnet
address constant kcBAT = 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E;    // Mainnet
address constant kcDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;    // Mainnet
address constant kcDaiDelegate = 0xbB8bE4772fAA655C255309afc3c5207aA7b896Fd;    // Mainnet
address constant kcETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;    // Mainnet
address constant kComp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;    // Mainnet
address constant kCompoundLens = 0xA6c8D1c55951e8AC44a0EaA959Be5Fd21cc07531;    // Mainnet
address constant kComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;    // Mainnet
address constant kcREP = 0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1;    // Mainnet
address constant kCrowdProposalFactory = 0xB5212a2fa63c1863b9e8670e2A6D420d0309c502;    // Mainnet
address constant kcSAI = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;    // Mainnet
address constant kcUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;    // Mainnet
address constant kcUniDelegate = 0x338f7e5d19d9953b76dD81446B142C2D9fE03482;    // Mainnet
address constant kcUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;    // Mainnet
address constant kcUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;    // Mainnet
address constant kcUsdtDelegate = 0x976aa93ca5Aaa569109f4267589c619a097f001D;    // Mainnet
address constant kcWBTC = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;    // Mainnet
address constant kcZRX = 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407;    // Mainnet
address constant kDAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;    // Mainnet
address constant kDSR_Kink_9000bps_Jump_12000bps_AssumedRF_20000bps = 0x000000007675b5E1dA008f037A0800B309e0C493;    // Mainnet
address constant kDSR_Kink_9000bps_Jump_12000bps_AssumedRF_500bps = 0xec163986cC9a6593D6AdDcBFf5509430D348030F;    // Mainnet
address constant kDSR_Updateable = 0xfeD941d39905B23D6FAf02C8301d40bD4834E27F;    // Mainnet
address constant kGovernorAlpha = 0xc0dA01a04C3f3E0be433606045bB7017A7323E38;    // Mainnet
address constant kGovernorBravoDelegate = 0xAAAaaAAAaaaa8FdB04F544F4EEe52939CddCe378;    // Mainnet
address constant kGovernorBravoDelegator = 0xc0Da02939E1441F497fd74F78cE7Decb17B66529;    // Mainnet
address constant kIRM_UNI_Updateable = 0xd88B94128Ff2B8Cf2d7886cd1C1E46757418cA2A;    // Mainnet
address constant kIRM_USDC_Updateable = 0xD8EC56013EA119E7181d231E5048f90fBbe753c0;    // Mainnet
address constant kIRM_USDT_Updateable = 0xFB564da37B41b2F6B6EDcc3e56FbF523bD9F2012;    // Mainnet
address constant kKNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;    // Mainnet
address constant kLINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;    // Mainnet
address constant kMaximillion = 0xf859A1AD94BcF445A406B892eF0d3082f4174088;    // Mainnet
address constant kPair_BAT_ETH = 0xB6909B960DbbE7392D405429eB2b3649752b4838;    // Mainnet
address constant kPair_COMP_ETH = 0xCFfDdeD873554F362Ac02f8Fb1f02E5ada10516f;    // Mainnet
address constant kPair_DAI_ETH = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;    // Mainnet
address constant kPair_ETH_KNC = 0xf49C43Ae0fAf37217bDcB00DF478cF793eDd6687;    // Mainnet
address constant kPair_ETH_USDC = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;    // Mainnet
address constant kPair_ETH_ZRX = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;    // Mainnet
address constant kPair_LINK_ETH = 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974;    // Mainnet
address constant kPair_REP_ETH = 0xec2D2240D02A8cf63C3fA0B7d2C5a3169a319496;    // Mainnet
address constant kPair_WBTC_ETH = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;    // Mainnet
address constant kPoster = 0x3c6809319201b978D821190Ba03fA19A3523BD96;    // Mainnet
address constant kPriceData = 0xc629C26dcED4277419CDe234012F8160A0278a79;    // Mainnet
address constant kPriceFeed = 0x922018674c12a7F0D394ebEEf9B58F186CdE13c1;    // Mainnet
address constant kPriceFeedPoster = 0x83563ba7F1B093aae57Fe876f8D870f8a1508886;    // Mainnet
address constant kPriceOracle = 0x02557a5E05DeFeFFD4cAe6D83eA3d173B272c904;    // Mainnet
address constant kPriceOracleProxy = 0xDDc46a3B076aec7ab3Fc37420A8eDd2959764Ec4;    // Mainnet
address constant kREP = 0x1985365e9f78359a9B6AD760e32412f4a445E862;    // Mainnet
address constant kReservoir = 0x2775b1c75658Be0F640272CCb8c72ac986009e38;    // Mainnet
address constant kSAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;    // Mainnet
address constant kStdComptroller = 0x62F18C451af964197341d3c86D27e98C41BB8fcC;    // Mainnet
address constant kStdComptroller_2_6 = 0x97BD4Cc841FC999194174cd1803C543247a014fe;    // Mainnet
address constant kStdComptrollerG2 = 0xf592eF673057a451c49c9433E278c5d59b56132c;    // Mainnet
address constant kStdComptrollerG3 = 0x9D0a0443FF4bB04391655B8cD205683d9fA75550;    // Mainnet
address constant kStdComptrollerG4 = 0xAf601CbFF871d0BE62D18F79C31e387c76fa0374;    // Mainnet
address constant kStdComptrollerG5 = 0x7b5e3521a049C8fF88e6349f33044c6Cc33c113c;    // Mainnet
address constant kStdComptrollerG6 = 0x7d47d3f06A9C10576bc5DC87ceFbf3288F96Ea04;    // Mainnet
address constant kStdComptrollerG7 = 0xbe7616B06f71e363A310Aa8CE8aD99654401ead7;    // Mainnet
address constant kTimelock = 0x6d903f6003cca6255D85CcA4D3B5E5146dC33925;    // Mainnet
address constant kUNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;    // Mainnet
address constant kUniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;    // Mainnet
address constant kUnitroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;    // Mainnet
address constant kUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;    // Mainnet
address constant kUSDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;    // Mainnet
address constant kWBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;    // Mainnet
address constant kZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;    // Mainnet


// KyberSwap Proxy contract 
address constant kKyberNetworkProxy = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e; // Mainnet
address constant kKyberStorage = 0xC8fb12402cB16970F3C5F4b48Ff68Eb9D1289301; // Mainnet
address constant kKyberNetwork = 0x7C66550C9c730B6fdd4C03bc2e73c5462c5F7ACC; // Mainnet


// KyberHintHandler ( KyberMatchingEngine )
address constant kKybeHint = 0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C; // Mainnet

//  Mainnet currencies
address constant kWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet
****************************************************************************************/
/**********************************************************/

/**********************************************************
 * Primary Contract: PreachersCompFiLqdt v1.0.12 KOVAN
 **********************************************************/
contract PreachersCompFiLqdt is Structs {
    DyDxPool dydxPool = DyDxPool( kDyDxPool );
    // uint public iExitNo;

    // Contract owner
    address payable public owner;

    // Modifiers
    modifier onlyOwner( ) {
        require( msg.sender == owner, "caller is not the owner!" );
        _;
    }

    constructor( ) payable {

        // Track the contract owner
        owner = payable( msg.sender );
        
    }
    
    receive( ) external payable {
        emit Received( msg.sender, msg.value );
    }

    function tokenToMarketId( address _token ) internal pure returns ( uint256 ) {
        uint256 iCurrency = 99;
        
        if( _token == kWETH ) {
            iCurrency= 0;
        } else if ( _token == kSAI ) {
            iCurrency = 1;
        } else if ( _token == kUSDC ) {
            iCurrency = 2;
        } else if ( _token == kDAI ) {
            iCurrency = 3;
        }
        
        require( iCurrency < 99, "FlashLoan: Unsupported token" );
        
        return iCurrency;
    }


    /***************************************************************************
     * the DyDx will call `callFunction( address sender, Info memory accountInfo,
     * bytes memory data ) public` after during `operate` call
     ***************************************************************************/
    function flashloan( address _token, uint256 _amount, bytes memory data )
        internal
    {
        ERC20( _token ).approve( address( dydxPool ), _amount + 1 );

        Info[] memory infos = new Info[]( 1 );

        ActionArgs[] memory args = new ActionArgs[]( 3 );

        infos[0] = Info( address( this ), 0 );

        AssetAmount memory wamt = AssetAmount( 
            false,
            AssetDenomination.Wei,
            AssetReference.Delta,
            _amount
        );
        
        ActionArgs memory withdraw;
        withdraw.actionType = ActionType.Withdraw;
        withdraw.accountId = 0;
        withdraw.amount = wamt;
        withdraw.primaryMarketId = tokenToMarketId( _token );
        withdraw.otherAddress = address( this );

        args[0] = withdraw;

        ActionArgs memory call;
        call.actionType = ActionType.Call;
        call.accountId = 0;
        call.otherAddress = address( this );
        call.data = data;

        args[1] = call;

        ActionArgs memory deposit;
        AssetAmount memory damt = AssetAmount( 
            true,
            AssetDenomination.Wei,
            AssetReference.Delta,
            _amount + 1
        );
        deposit.actionType = ActionType.Deposit;
        deposit.accountId = 0;
        deposit.amount = damt;
        deposit.primaryMarketId = tokenToMarketId( _token );
        deposit.otherAddress = address( this );

        args[2] = deposit;

        dydxPool.operate( infos, args );
    }

    /*************************************************************************************************************
     * Call this contract function from the external 
     * remote job to perform the liquidation.
     ************************************************************************************************************/
    function doCompFiLiquidate( 
        //loan information, preferably WETH
        address _flashToken, 
        uint256 _flashAmount,
        // Borrow Account to be liquidated
        address _lqdtAccount, 
        address _lqdtToken, 
        uint256 _lqdtTokenAmount,
        // liquidation reimbursement and Reward Token
        address _collateralToken
        // uint iCashOnHand
        ) external returns( bool ) {
        
        // emit PassThru( liquidateAmount );
        
        // Populate the passthru data structure, which will be used
        // by 'callFunction'.
        bytes memory data = abi.encode( 
            _flashToken, 
            _flashAmount,
            _lqdtAccount, 
            _lqdtToken, 
            _lqdtTokenAmount, 
            _collateralToken );

        flashloan( _flashToken, _flashAmount, data );

        return true;
    }
    

    /**************************************************************************************
     * Preacher's Method II
     * 
     * 1. Obtain Flash Loan in USDC from dYdX in the amount of equal value in the 
     * liquidation amount.
     * 2. If the liquidate token is cUSDC, skip to step ( 3 ). Otherwise, swap ( Kyber ) the 
     * USDC for an equal value of the liquidate tokens.
     * 3. Pay down the liquidate amount, liquidateBorrow( ). CompFi will award an equal 
     * value from the unsafe account's collateral + incentive reward.
     * 4. Swap the received collateral tokens for USDC.
     * 5. Repay the flash loan with the USDC.
     * 6. Transfer what is left of the USDC to the Msg.sender.
     * 
     **************************************************************************************/
    function callFunction( 
        address, /* sender */
        Info calldata, /* accountInfo */
        bytes calldata data
    ) external {
	
	    // Decode the parameters in "calldata" as passed by doCompFiLiquidate.
        (address _flashToken, 
         uint256 _flashAmount, 
         address _lqdtAccount, 
         address _lqdtToken, 
         uint256 _lqdtTokenAmount,
         address _collateralToken ) = 
			abi.decode( data, ( address, uint256, address, address, uint256, address ) );
		
		ERC20 cFlashToken = ERC20( _flashToken );
		uint256 iRedeemed = 0;

		emit Borrowed( _flashToken, cFlashToken.balanceOf( address(this) ) );

		require( cFlashToken.balanceOf( address(this) ) >= _flashAmount ,"Contract did not get the loan" );
		
        // Swap flash loan for targetToken
		ERC20 cLqdtToken = ERC20( _lqdtToken );
		
		if ( _flashToken != _lqdtToken ){
		    
	        iRedeemed = _flashAmount;
    		// if the underlying of both is the same, such as for WETH and cETH, 
    		// KyberSwap is not needed.
		    if ( cFlashToken.underlying() == cLqdtToken.underlying() ){
		        if ( _flashToken == cFlashToken.underlying() ){
		            cFlashToken.approve( _lqdtToken, iRedeemed );
		        } else {
    		        // convert the flash loan token to the underlying currency
		            iRedeemed = cFlashToken.redeem( _flashAmount );
		            ERC20 cUnderlying = ERC20( cFlashToken.underlying() );
		            cUnderlying.approve( _lqdtToken, iRedeemed );  // approve to mint
		        }
		        
	            cLqdtToken.mint( iRedeemed ); // Converts Underlying to CompFi cToken
	            // Ready for liquidateBorrow
		      
		    } else {
		        // The flash loan token and liquidate token are not the same and have 
		        //  diferent underlying tokens. Swap is required.
		        // dYdX loan was in WETH, USDC or DAI
		        iRedeemed = _flashAmount;
		        if ( _flashToken != cFlashToken.underlying() ) {
		            // swap loaned currency for liquidate token's underlying
		            iRedeemed = cFlashToken.redeem( _flashAmount ); // Now underlying tokens
		        }
		        // swap _flashToken underlying for_lqdtToken 

		        require( executeKyberSwap( cFlashToken.underlying(), iRedeemed,
		            cLqdtToken.underlying(), 999999999999999999999999999 ) > 0, "06 Token swap failed" );
	            
                // Use the underlying to mint the _lqdtTokens
                ERC20 cLqdtUnderlying = ERC20( cLqdtToken.underlying() );
                cLqdtUnderlying.approve( _lqdtToken, _lqdtTokenAmount );
                cLqdtToken.mint( _lqdtTokenAmount );
                // Ready for liquidateBorrow
            }
		}

        // Step 3. Pay down the amount borrowed by the unsafe account
		// -- Enter the market for the token to be liquidated
		Comptroller ctroll = Comptroller( kUnitroller );

		address[] memory cTokens = new address[]( 1 );
		cTokens[0] = _lqdtToken;
		uint[] memory Errors = ctroll.enterMarkets( cTokens );
		require( Errors[0] == 0, "09 Comptroller enter Markets for target token failed. " );
		
		if (cLqdtToken.balanceOf( address(this) ) < _lqdtTokenAmount ) {
		    _lqdtTokenAmount = cLqdtToken.balanceOf( address(this) );
		}
		
	    _lqdtTokenAmount = cLqdtToken.liquidateBorrow( _lqdtAccount, _lqdtTokenAmount, 
	        _collateralToken );
	    emit Liquidated( _lqdtAccount, _lqdtToken, _lqdtTokenAmount );

		require( ctroll.exitMarket( _lqdtToken ) == 0, "Exit Market of target token failed. " );
		 
		// 4. Swap the received collateral tokens back to _flashToken to repay the flash loan.
		// Redeem underlying, swap if not the same
 	    ERC20 cCollateralToken = ERC20( _collateralToken );  // Repayment + Reward
 	    cCollateralToken.redeem( cCollateralToken.balanceOf( address(this) ) );
 	    cCollateralToken = ERC20( cCollateralToken.underlying() );
 	    
 	    if ( _flashToken == address( cCollateralToken ) ){
 	        // Done. Return to repay the loan
 	        return;
 	    }

        // Swap is required
		   
        executeKyberSwap( address( cCollateralToken ),
	        cCollateralToken.balanceOf( address(this) ),
	        _flashToken, 999999999999999999999999999 );

        // -- Liquidation is completed in flashloan( )
    	
    } /*************** Liquidation completed *****************************************************/
    
    
    /***************************************************************************
     * KyberSwap functions
    ****************************************************************************/
    // Swap from srcToken to destToken ( including ether )
    function executeKyberSwap( address _SrcToken, uint256 _SrcQty, address _DestToken,
        uint256 _lqdtTokenAmount ) 
            public returns ( uint256 ) {

        uint256 destAmount = 99;
        uint256 minConversionRate = 0;
        
        ISimpleKyberProxy cSimpleKyberProxy = ISimpleKyberProxy( kKyberNetworkProxy );
        IKyberNetworkProxy cKyberProxy = IKyberNetworkProxy( kKyberNetworkProxy );


        ERC20 cSrcToken = ERC20( _SrcToken );
        ERC20 cDestToken = ERC20( _DestToken );

        ( minConversionRate,  ) = 
            cKyberProxy.getExpectedRate( cSrcToken, cDestToken, _SrcQty );
        
        if ( minConversionRate == 0 ) { minConversionRate = _lqdtTokenAmount/_SrcQty; }

        // If the source token is not ETH ( ie. an ERC20 token ), the user is 
		// required to first call the ERC20 approve function to give an allowance
		// to the smart contract executing the transferFrom function.
        if ( _SrcToken == kETH ) {
            
            destAmount = cSimpleKyberProxy.swapEtherToToken{value: _SrcQty}( cDestToken, minConversionRate );
            
            if ( destAmount > _lqdtTokenAmount ) {destAmount = _lqdtTokenAmount;}

        } else {
            
            // mitigate ERC20 Approve front-running attack, by initially setting
            // allowance to 0
            require( cSrcToken.approve( kKyberNetworkProxy, 0 ), "approval to 0 failed" );

            // set the spender's token allowance to srcQty
            require( cSrcToken.approve( kKyberNetworkProxy, _SrcQty ), "approval to srcQty failed" );
            
            if ( _DestToken == kETH ) {
                
                destAmount = cSimpleKyberProxy.swapTokenToEther( cSrcToken, _SrcQty, minConversionRate );
                
                if ( destAmount > _lqdtTokenAmount ) {destAmount = _lqdtTokenAmount;}

            } else {
                
                destAmount = cSimpleKyberProxy.swapTokenToToken( cSrcToken, _SrcQty, cDestToken, minConversionRate );
                
                if ( destAmount > _lqdtTokenAmount ) {destAmount = _lqdtTokenAmount;}
            }

        }

        return destAmount;
    }

    function minConversionRates( 
        address _srcToken,
        uint256 _srcQuantity,
        address _destToken ) public view  
        returns( uint256 _minConversionRt, uint256 _worstRate ){
        
        uint256 minConversionRt = 0;
        uint256 worstRate = 0;
        
        IKyberNetworkProxy cKyberProxy = IKyberNetworkProxy( kKyberNetworkProxy );
        ERC20 cSrcToken = ERC20( _srcToken );
        ERC20 cDestToken = ERC20( _destToken );
        
        ( minConversionRt,  worstRate ) = 
            cKyberProxy.getExpectedRate( cSrcToken, cDestToken, _srcQuantity );

        return( minConversionRt, worstRate );
    }

    function AccountNoAssets ( address _Account ) external view returns ( uint ){
        Comptroller troll = Comptroller( kUnitroller );
        return troll.getAssetsIn( _Account ).length;
    }
    
    function AccountAssetByNo ( address _Account , uint _AssetNo ) external view returns
    ( uint, address ){
        Comptroller cTroll = Comptroller( kUnitroller );
        address[] memory assetAddresses = cTroll.getAssetsIn( _Account );
        address assetNoAddress = assetAddresses[ _AssetNo ];
        return ( _AssetNo, assetNoAddress );
    }
 
    function changeOwner( address payable _newOwner ) public onlyOwner {
        owner = _newOwner;
        emit ChangedOwner( owner, _newOwner );
    }

    function getTokenBalance( address _token ) external view returns( uint256 ) {
        ERC20 cToken = ERC20( _token );
        uint256 tknBalance = cToken.balanceOf( address( this ) );
        return tknBalance;
    }
    
    function getETHBalance( ) external view returns( uint256 ) {
        return address( this ).balance;
    }
    
    function getCloseFactor( ) external view returns ( uint256 )  {
        Comptroller troll = Comptroller( kUnitroller );
        return troll.closeFactorMantissa( );
    }
    
    function VerifyAccountLiquidity( address _account ) external view 
        returns ( uint256, uint256, uint256 ) {
        
        Comptroller troll = Comptroller( kUnitroller );
        
        return troll.getAccountLiquidity( _account );
    }
    
    function VerifyLiquiditationAllowed( 
        address _TokenBorrowed, 
        address _TokenCollateral, 
        address _liquidator, 
        address _borrower, 
        uint256 _repayAmount )  public onlyOwner returns ( uint256 ) {
        
        Comptroller cTroll = Comptroller( kUnitroller );

        uint256 temp = cTroll.liquidateBorrowAllowed ( _TokenBorrowed, _TokenCollateral, _liquidator,
            _borrower, _repayAmount );
        return temp;
    }

    function fWithdraw( address _token, uint _iApprove ) public onlyOwner returns( bool ) {
        uint256 tokenBalance;
        // withdrawing Ether
        if ( _token == kETH ) {
            if ( address( this ).balance > 0 ){
                tokenBalance = address( this ).balance;
                payable( msg.sender ).transfer( address( this ).balance );
            }

        } else {
            ERC20 cWithdrawToken = ERC20( _token );
            if ( cWithdrawToken.balanceOf( address( this ) ) > 0 ){
                tokenBalance = cWithdrawToken.balanceOf( address( this ) );
                if ( _iApprove == 1 ) {
                    require( cWithdrawToken.approve( address( this ), tokenBalance ) == true,
                        "fWithdraw approval failed." );
                }
                
                require( cWithdrawToken.transfer( msg.sender, 
                    cWithdrawToken.balanceOf( address( this ) ) ) );
            }
        }
        return true;
    }
	
	/***************************************************************************
	 * AAVE
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
	 * from https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Withdrawable.sol
    ****************************************************************************/
    

    // All events for this contract
    /*************************** cut gas fee
	event LogWithdraw( address indexed _from, address indexed _assetAddress, uint amount );
    event PassThru( uint256 liquidateampount );
    event StepNo ( uint iStep );
    event Swapp( uint256 srcTokenBalance, uint256 srcQty, address destToken, uint256 minConversionRate );
    event Transfer( address from, address to, uint256 value );
    event Withdrawn( address token, uint256 amount );
    *****************************/
    event Borrowed( address tokenborrowed, uint256 amount );
    event ChangedOwner( address payable owner, address payable newOwner );
    event Liquidated( address account, address token, uint256 amount );
    event Received( address, uint );
    event Swapped( address fromtoken, uint256 fromamount, address totoken, uint256 toamount );
}

// These definitions are taken from across multiple dydx contracts, and are
// limited to just the bare minimum necessary to make flash loans work.
library Types {
    enum AssetDenomination { Wei, Par }
    enum AssetReference { Delta, Target }
    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Actions {
    enum ActionType {
        Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}