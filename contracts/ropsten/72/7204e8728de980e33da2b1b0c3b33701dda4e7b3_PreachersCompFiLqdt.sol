/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/**********************************************************
 * Main Contract: PreachersCompFiLqdt v1.0.10
 **********************************************************/
pragma solidity ^0.8.4;

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
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}
/************************** AAVE 
contract Flashloan is FlashLoanReceiverBase {
    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}
}
**************************/

// AAVE  https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol
interface ILendingPool {
  function addressesProvider () external view returns ( address );
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
  function getReserves () external view;
}

// AAVE https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPoolAddressesProvider.sol
/**
    @title ILendingPoolAddressesProvider interface
    @notice provides the interface to fetch the LendingPoolCore address
 */
interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);
    function getLendingPool() external view returns (address);
}


interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token (externally)
      Sell,      // sell an amount of some token (externally)
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
  function liquidateBorrow ( address borrower, uint256 repayAmount, address cTokenCollateral ) external returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function decimals (  ) external view returns ( uint256 );
  function mint ( uint256 mintAmount ) external returns ( uint256 );
  function symbol (  ) external view returns ( string memory );
  function totalSupply ( ) external view returns (uint256 supply);
  function transfer ( address dst, uint256 amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
  function underlying (  ) external view returns ( address );
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface ICorWETH {
  function liquidateBorrow ( address borrower, address cTokenCollateral ) external payable;
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function decimals (  ) external view returns ( uint256 );
  function symbol (  ) external view returns ( string memory );
  function totalSupply( ) external view returns (uint256 supply);
  function transfer ( address dst, uint256 amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

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
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
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
    ) external returns (uint256 destAmount);

    function swapEtherToToken(ERC20 token, uint256 minConversionRate)
        external
        payable
        returns (uint256 destAmount);

    function swapTokenToToken(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        uint256 minConversionRate
    ) external returns (uint256 destAmount);
}

interface IKyberNetworkProxy {
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view 
        returns (uint expectedRate, uint worstRate);
}

// dYdX flash loan contract
interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

abstract contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public virtual view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public virtual;
}

/******************************************************************************************
 * addresses at https://github.com/compound-finance/compound-protocol/tree/master/networks
*******************************************************************************************/

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


address constant kETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


/*********************************************************************************************
address constant kUnitroller = 0x5eAe89DC1C671724A672ff0630122ee834098657; // Kovan
address constant kComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B; // Kovan
address constant kcUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;   // Kovan
address constant kcETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;   // Kovan
address constant kUSDC = 0x03226d9241875DbFBfE0e814ADF54151e4F3fd4B;   // Kovan

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

address constant kBAT = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;	// Kovan
address constant kKNC = 0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2;	// Kovan
address constant kDAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;	// Kovan
address constant kMANA = 0xcb78b457c1F79a06091EAe744aA81dc75Ecb1183;	// Kovan
address constant kMKR = 0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD;	// Kovan
address constant kOMG = 0xdB7ec4E4784118D9733710e46F7C83fE7889596a;	// Kovan
address constant kPOLY = 0xd92266fd053161115163a7311067F0A4745070b5;	// Kovan
address constant kREP = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;	// Kovan
address constant kSAI = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;	// Kovan
address constant kSALT = 0x6fEE5727EE4CdCBD91f3A873ef2966dF31713A04;	// Kovan
address constant kSNT = 0x4c99B04682fbF9020Fcb31677F8D8d66832d3322;	// Kovan
address constant kWETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;	// Kovan
address constant kZIL = 0xAb74653cac23301066ABa8eba62b9Abd8a8c51d6;	// Kovan
****************************************************************************************/

// address constant kETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

/**********************************************************
// Compound.Finance Comptroller constants
// Note:To call Comptroller functions, use the Comptroller ABI on the Unitroller address.
address constant kUnitroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;  // Mainnet
address constant kComptroller = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074; // Mainnet
address constant kcUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;   // Mainnet
address constant kcETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;   // Mainnet

// KyberSwap Proxy contract 
address constant kKyberProxy = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e; // Mainnet


// KyberHintHandler (KyberMatchingEngine)
address constant kKybeHint = 0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C;

//  Mainnet currencies
address constant kWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant kSAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
address constant kUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant kDAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
**********************************************************/

/**********************************************************
 * Main Contract: PreachersCompFiLqdt v1.0.10
 **********************************************************/
contract PreachersCompFiLqdt is Structs {
    DyDxPool kDyDxPool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    // Contract owner
    address payable public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }

    constructor() payable {

        // Track the contract owner
        owner = payable(msg.sender);
        
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function tokenToMarketId(address token) internal pure returns (uint256 ) {
        uint256 iCurrency = 99;
        
        if(token == kWETH) {
            iCurrency= 0;
        } else if (token == kSAI) {
            iCurrency = 1;
        } else if (token == kUSDC) {
            iCurrency = 2;
        } else if (token == kDAI) {
            iCurrency = 3;
        }
        
        require(iCurrency < 99, "FlashLoan: Unsupported token");
        
        return iCurrency;
    }


    /***************************************************************************
     * the DyDx will call `callFunction(address sender, Info memory accountInfo,
     * bytes memory data) public` after during `operate` call
     ***************************************************************************/
    function flashloan(address token, uint256 amount, bytes memory data)
        internal
    {
        ERC20(token).approve(address(kDyDxPool), amount + 1);

        Info[] memory infos = new Info[](1);

        ActionArgs[] memory args = new ActionArgs[](3);

        infos[0] = Info(address(this), 0);

        AssetAmount memory wamt = AssetAmount(
            false,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount
        );
        
        ActionArgs memory withdraw;
        withdraw.actionType = ActionType.Withdraw;
        withdraw.accountId = 0;
        withdraw.amount = wamt;
        withdraw.primaryMarketId = tokenToMarketId(token);
        withdraw.otherAddress = address(this);

        args[0] = withdraw;

        ActionArgs memory call;
        call.actionType = ActionType.Call;
        call.accountId = 0;
        call.otherAddress = address(this);
        call.data = data;

        args[1] = call;

        ActionArgs memory deposit;
        AssetAmount memory damt = AssetAmount(
            true,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount + 1
        );
        deposit.actionType = ActionType.Deposit;
        deposit.accountId = 0;
        deposit.amount = damt;
        deposit.primaryMarketId = tokenToMarketId(token);
        deposit.otherAddress = address(this);

        args[2] = deposit;

        kDyDxPool.operate(infos, args);
    }

    /*************************************************************************************************************
     * Call this contract function from the external 
     * remote job to perform the liquidation.
     ************************************************************************************************************/
    function doCompFiLiquidate(
        //loan information
        address flashToken, 
        uint256 flashAmount,
        // Borrow Account to be liquidated
        address lqdtAccount, 
        address lqdtToken, 
        uint256 lqdtAmount,
        // liquidation reimbursement and Reward Token
        address collateralToken,
        uint iCashOnHand
        ) external returns(bool) {
        
        // emit PassThru( liquidateAmount );
        
        // Populate the passthru data structure, which will be used
        // by 'callFunction'.
        bytes memory data = abi.encode(
            flashToken, 
            flashAmount,
            lqdtAccount, 
            lqdtToken, 
            lqdtAmount, 
            collateralToken);
        
        // execution goes to `callFunction`
        // STEP 1
        if (iCashOnHand == 0){
            flashloan(flashToken, flashAmount, data);
        } else {    // no flashloan
            cashOnHand( data );
        }
        
        return true;
    }
    
    
    function cashOnHand( bytes memory data ) internal returns ( bool ){
	    // Decode the parameters in "calldata" as passed by doCompFiLiquidate.
        (address flashToken, 
         uint256 flashAmount, 
         address lqdtAccount, 
         address lqdtToken, 
         uint256 lqdtAmount,
         address collateralToken) = 
			abi.decode(data, (address, uint256, address, address, uint256, address));
		
		ERC20 cFlashToken = ERC20(flashToken);

		emit Borrowed(flashToken, cFlashToken.balanceOf(address(this)));

		require(cFlashToken.balanceOf(address(this)) >= flashAmount ,"Contract did not get the loan");
		
        // Swap flash loan for targetToken
		ERC20 cLqdtToken = ERC20(lqdtToken);
        if ( lqdtToken != flashToken ) {

    	    require( executeKyberSwap( flashToken, flashAmount,
	            lqdtToken ) > 0, "02 First Token swap failed");

        }
        
        // Approve tokens to be used to pay the lqdtAmount
        if (lqdtToken != kETH){
            require(cLqdtToken.approve(address(this), lqdtAmount) == true,
                "02 approval failed.");
        }
        
        // Step 3. Pay down the amount borrowed by the unsafe account
		// -- Enter the market for the token to be liquidated
		Comptroller ctroll = Comptroller(kUnitroller);

		address[] memory cTokens = new address[](1);
		cTokens[0] = lqdtToken;
		uint[] memory Errors = ctroll.enterMarkets(cTokens);
		require(Errors[0] == 0, "01 Comptroller enter Markets for target token failed. ");
		
		if (lqdtToken == kcETH){
		    ICorWETH ceLqdtToken = ICorWETH(lqdtToken);
		    ceLqdtToken.liquidateBorrow{value: lqdtAmount}(lqdtAccount, collateralToken);
		} else {
		    cLqdtToken.liquidateBorrow(lqdtAccount, lqdtAmount, collateralToken);
		}
		require(ctroll.exitMarket(lqdtToken) == 0, "Exit Market of target token failed. ");
		 
		// 4. Swap the received collateral tokens back to flashToken to repay the flash loan.
		cTokens[0] = collateralToken;
		Errors = ctroll.enterMarkets(cTokens);
		require(Errors[0] == 0, "02 Comptroller.enter Markets for collateral Token failed.");

	 	if ( collateralToken != flashToken ) {
	 	    ERC20 cCollateralToken = ERC20(collateralToken);
		    
    	   require( executeKyberSwap(collateralToken, 
    	        cCollateralToken.balanceOf(address(this)),
	            flashToken ) > 0, "02 Back to Flash Token swap failed");
        }
        
    	// -- Liquidation is completed
    	return true;
    }
    
    
    /**************************************************************************************
     * Preacher's Method II
     * 
     * 1. Obtain Flash Loan in USDC from dYdX in the amount of equal value in the 
     * liquidation amount.
     * 2. If the liquidate token is cUSDC, skip to step (3). Otherwise, swap (Kyber) the 
     * USDC for an equal value of the liquidate tokens.
     * 3. Pay down the liquidate amount, liquidateBorrow(). CompFi will award an equal 
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
        (address flashToken, 
         uint256 flashAmount, 
         address lqdtAccount, 
         address lqdtToken, 
         uint256 lqdtAmount,
         address collateralToken) = 
			abi.decode(data, (address, uint256, address, address, uint256, address));
		
		ERC20 cFlashToken = ERC20(flashToken);

		emit Borrowed(flashToken, cFlashToken.balanceOf(address(this)));

		require(cFlashToken.balanceOf(address(this)) >= flashAmount ,"Contract did not get the loan");
		
        // Swap flash loan for targetToken
		ERC20 cLqdtToken = ERC20(lqdtToken);
        if ( lqdtToken != flashToken ) {

    	    require( executeKyberSwap( flashToken, flashAmount,
	            lqdtToken ) > 0, "02 First Token swap failed");

        }
        
        // Approve tokens to be used to pay the lqdtAmount
        if (lqdtToken != kETH){
            require(cLqdtToken.approve(address(this), lqdtAmount) == true,
                "02 approval failed.");
        }
        
        // Step 3. Pay down the amount borrowed by the unsafe account
		// -- Enter the market for the token to be liquidated
		Comptroller ctroll = Comptroller(kUnitroller);

		address[] memory cTokens = new address[](1);
		cTokens[0] = lqdtToken;
		uint[] memory Errors = ctroll.enterMarkets(cTokens);
		require(Errors[0] == 0, "01 Comptroller enter Markets for target token failed. ");
		
		if (lqdtToken == kcETH){
		    ICorWETH ceLqdtToken = ICorWETH(lqdtToken);
		    ceLqdtToken.liquidateBorrow{value: lqdtAmount}(lqdtAccount, collateralToken);
		} else {
		    cLqdtToken.liquidateBorrow(lqdtAccount, lqdtAmount, collateralToken);
		}
		require(ctroll.exitMarket(lqdtToken) == 0, "Exit Market of target token failed. ");
		 
		// 4. Swap the received collateral tokens back to flashToken to repay the flash loan.
		cTokens[0] = collateralToken;
		Errors = ctroll.enterMarkets(cTokens);
		require(Errors[0] == 0, "02 Comptroller.enter Markets for collateral Token failed.");

	 	if ( collateralToken != flashToken ) {
	 	    ERC20 cCollateralToken = ERC20(collateralToken);
		    
    	   require( executeKyberSwap(collateralToken, 
    	        cCollateralToken.balanceOf(address(this)),
	            flashToken ) > 0, "02 Back to Flash Token swap failed");
        }
        
    	// -- Liquidation is completed in flashloan()
    	
    } /*************** Liquidation completed *****************************************************/
    
    
    
    
    /***************************************************************************
     * KyberSwap functions
    ****************************************************************************/
    // Swap from srcToken to destToken (including ether)
    function executeKyberSwap( address SrcToken, uint256 srcQty, address DestToken ) 
            public returns ( uint256 ) {

        ISimpleKyberProxy cSimpleKyberProxy = ISimpleKyberProxy( kKyberNetworkProxy );
        IKyberNetworkProxy cKyberProxy = IKyberNetworkProxy( kKyberNetworkProxy );

        ERC20 cSrcToken = ERC20(SrcToken);
        ERC20 cDestToken = ERC20(DestToken);
        uint256 destAmount = 0;
        uint256 minConversionRate = 0;

        ( minConversionRate,  ) = 
            cKyberProxy.getExpectedRate( cSrcToken, cDestToken, srcQty );
        
        // If the source token is not ETH (ie. an ERC20 token), the user is 
		// required to first call the ERC20 approve function to give an allowance
		// to the smart contract executing the transferFrom function.
        if (SrcToken == kETH) {
            
            destAmount = cSimpleKyberProxy.swapEtherToToken{value: srcQty}(cDestToken, minConversionRate);

        } else {
            
            // mitigate ERC20 Approve front-running attack, by initially setting
            // allowance to 0
            require(cSrcToken.approve(kKyberNetworkProxy, 0), "approval to 0 failed");

            // set the spender's token allowance to srcQty
            require(cSrcToken.approve(kKyberNetworkProxy, srcQty), "approval to srcQty failed");
            
            if (DestToken == kETH) {
                
                destAmount = cSimpleKyberProxy.swapTokenToEther( cSrcToken, srcQty, minConversionRate );
                
            } else {
                
                destAmount = cSimpleKyberProxy.swapTokenToToken( cSrcToken, srcQty, cDestToken, minConversionRate );
                
            }

        }

        return destAmount;
    }

    function AccountNoAssets ( address LAccount ) external view returns ( uint ){
        Comptroller troll = Comptroller(kUnitroller);
        return troll.getAssetsIn( LAccount ).length;
    }
    
    function AccountAssetByNo ( address LAccount , uint AssetNo ) external view returns
    ( uint, address ){
        Comptroller troll = Comptroller(kUnitroller);
        address[] memory assetAddresses = troll.getAssetsIn( LAccount );
        address assetNoAddress = assetAddresses[AssetNo];
        return (AssetNo, assetNoAddress);
    }
 
    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
        // emit ChangedOwner(owner, newOwner);
    }

    function getTokenBalance(address tokenAddress) external view returns(uint256) {
        ERC20 theToken = ERC20(tokenAddress);
        uint256 tknBalance = theToken.balanceOf(address(this));
        return tknBalance;
    }
    
    function getETHBalance( ) external view returns(uint256) {
        ICorWETH theToken = ICorWETH( kETH );
        uint256 tknBalance = theToken.balanceOf(address(this));
        return tknBalance;
    }
    
    function getCloseFactor() external view returns (uint256)  {
        Comptroller troll = Comptroller(kUnitroller);
        return troll.closeFactorMantissa();
    }
    
    function VerifyAccountLiquidity( address laccount ) external view 
        returns ( uint256, uint256, uint256 ) {
        
        Comptroller troll = Comptroller(kUnitroller);
        
        return troll.getAccountLiquidity(laccount);
    }
    
    function fWithdraw(address token, uint iApprove) public onlyOwner returns(bool) {
        uint256 tokenBalance;
        // withdrawing Ether
        if (token == kETH) {
            if (address(this).balance > 0){
                tokenBalance = address(this).balance;
                payable(msg.sender).transfer(address(this).balance);
            }

        } else {
            ERC20 cWithdrawToken = ERC20(token);
            if (cWithdrawToken.balanceOf(address(this)) > 0){
                tokenBalance = cWithdrawToken.balanceOf(address(this));
                if (iApprove == 1) {
                    require(cWithdrawToken.approve(address(this), tokenBalance) == true,
                        "fWithdraw approval failed.");
                }
                
                require(cWithdrawToken.transfer(msg.sender, 
                    cWithdrawToken.balanceOf( address(this) )));
            }
        }
        return true;
    }
	
	/**  AAVE
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
	 * from https://github.com/aave/flashloan-box/blob/Remix/contracts/utils/Withdrawable.sol
     */
    function f2withdraw(address _assetAddress) public onlyOwner {
        uint assetBalance;
        if (_assetAddress == kETH) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            owner.transfer(assetBalance);
        } else {
            assetBalance = ERC20(_assetAddress).balanceOf(address(this));
            ERC20(_assetAddress).transfer(owner, assetBalance);
        }
        emit LogWithdraw(owner, _assetAddress, assetBalance);
    }

    // All events for this contract
    /*************************** cut gas fee
    event ChangedOwner(address payable owner, address payable newOwner);
    event Liquidated(address account, address token, uint256 amount );
    event PassThru( uint256 liquidateampount );
    event Transfer(address from, address to, uint256 value);
    event Withdrawn(address token, uint256 amount);
    *****************************/
	event LogWithdraw( address indexed _from, address indexed _assetAddress, uint amount );
    event Borrowed(address tokenborrowed, uint256 amount);
    event Received(address, uint);
    event Swapped(address fromtoken, uint256 fromamount, address totoken, uint256 toamount);
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