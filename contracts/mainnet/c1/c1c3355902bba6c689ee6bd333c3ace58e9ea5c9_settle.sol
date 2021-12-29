/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend, 
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;  //到期日
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;  
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    
    uint256 lastImpliedRate; //fcash的兑换率
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.

    //lastImpliedRate的时滞版本，用于以市场利率对fCash资产进行估值，同时保持对闪电贷款攻击的抵抗力。
    uint256 oracleRate;

    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface{

}


interface Notional {

	//得到用户cash余额 注意是ctoken!!!!
	function getAccountBalance(uint16 currencyId, address account) external view returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime
    );

	function getRateStorage(uint16 currencyId) external view returns (ETHRateStorage memory ethRate, AssetRateStorage memory assetRate);
   
    
	function getAccountContext(address account) external view returns (AccountContext memory);
    
	function settleAccount(address account) external returns (AccountContext memory);

	function getfCashAmountGivenCashAmount(uint16 currencyId,int88 netCashToAccount,uint256 marketIndex,uint256 blockTime) external view returns (int256);

	function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;
        
	function initializeMarkets(uint16 currencyId, bool isFirstInit) external;
    
}

interface ICERC20 {
    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);  
}

struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;//从底层资产到合成资产的汇率（如果需要反转，则已完成）
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals; //底层资产的精度，转换为底层资产的比列
}

struct AccountContext {
    // Used to check when settlement must be triggered on an account
    //下一次结算时间
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    //是否有过贷款
    bytes1 hasDebt;
    // Length of the account's asset array
    // 用户资产数量
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    //  未知
    uint16 bitmapCurrencyId;
    //  未知
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
}

enum AssetStorageState {NoChange, Update, Delete, RevertIfStored}

struct PortfolioAsset {
    // Asset currency id
    uint256 currencyId;
    uint256 maturity; //到期日
    // Asset type, fCash or liquidity token.
    uint256 assetType; //资产类型，有LT 也有fcash
    // fCash amount or liquidity token amount
    int256 notional;      //资产数量，有正数有负数
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

struct BalanceActionWithTrades {
	DepositActionType actionType;
	uint16 currencyId;
	uint256 depositActionAmount;
	uint256 withdrawAmountInternalPrecision;
	bool withdrawEntireCashBalance;
	bool redeemToUnderlying;
	// Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
	bytes32[] trades;
}


/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

enum TokenType {UnderlyingToken, cToken, cETH, Ether, NonMintable}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
}

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
}

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
}



library SafeInt256 {
    int256 private constant _INT256_MIN = type(int256).min;

    
    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require (b == 0 || c / b == a);
        else require (a == 0 || c / a == b);
    }

   
    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }
 
}

contract Owner {

    address private owner;
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract settle  is Owner  {
	uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;

	address constant NotionalAddress = 0x1344A36A1B56144C3Bc62E7757377D288fDE0369;
	using SafeInt256 for int256;

	constructor(){
		
	}

	
	function convertToUnderlying(uint16 currencyId,int256 assetBalance) public view returns (int256) {

		(,AssetRateStorage memory assetRate) = Notional(NotionalAddress).getRateStorage(currencyId);

		int256 rate = AssetRateAdapter(assetRate.rateOracle).getExchangeRateView(); //从外部地址获取兑换率 ctoken与底层资产的兑换率

        // Calculation here represents:
        // rate * balance * internalPrecision / rateDecimals * underlyingPrecision
        int256 underlyingBalance = rate
            .mul(assetBalance)
            .div(1e10)
            .div(int256(uint256(assetRate.underlyingDecimalPlaces)));

        return underlyingBalance;
    }

	//marketIndex 为要兑换的市场，这里千万注意 因为下个市场会变化
	//cashBalance为负数,fcashAmount为负数
	function getPayCashAndFcash(address account,uint16 currencyId,uint256 marketIndex) public view  returns(int256 ,int256) {
		//在这之前市场必须要进行初始化	
		int256 fcashAmount = 0;

		uint256 blockTime = block.timestamp;
		(int256 cashBalanceAsset,,) = Notional(NotionalAddress).getAccountBalance(currencyId,account);
		if(cashBalanceAsset >= 0) { //已经被结算过了
			return (cashBalanceAsset,fcashAmount);  //这里就不继续转换成底层资产了,因为已经不需要结算了
		}

		//注意cashBalanceAsset是ctoken,这里做一次转换
		int256 cashBalance = convertToUnderlying(currencyId,cashBalanceAsset);

		//注意fcashAmount的符号,这里cashBalance为负数 fcashAmount就为正数。如果传错了滑点就会滑向相反的方向，与实际情况不符
		//所以要传入负数 最终结果fcash为负数。这里表示用户要得到正的cash,账户会累计多少负的fcash
		//此处的含义是结算人为了帮助 欠款人 结算 需要付出cashBalance的资金，从而自己需要从市场上借多少fcash
		fcashAmount = Notional(NotionalAddress).getfCashAmountGivenCashAmount(currencyId,int88(-cashBalance),marketIndex,blockTime);

		//因为最终得到正的fcash会稍微有盈余，所以这里可以适当增加fcash的数量

		return (cashBalance,fcashAmount);
	}

	function executeTradesByMultiUser(address[] memory accounts,uint16 currencyId,uint256 maturity) isOwner external {
		//判断时间是否到了可以初始化与清算的时候, maturity为到期日
		uint256 blockTime = block.timestamp;
		require(blockTime >= maturity,"please settle later");
		//判断市场是否需要初始化. 这个必须在getPayCashAndFcash 之前
		_initMaketIfRequired(currencyId);

		for (uint i = 0; i < accounts.length; i++) {
			_executeTrade(accounts[i],currencyId);
		}
	}

	function executeTradesBySingleUser(address account,uint16 currencyId,uint256 maturity) isOwner external {
		//判断时间是否到了可以初始化与清算的时候, maturity为到期日
		uint256 blockTime = block.timestamp;
		require(blockTime >= maturity,"please settle later");
		//判断市场是否需要初始化. 这个必须在getPayCashAndFcash 之前
		_initMaketIfRequired(currencyId);

		_executeTrade(account,currencyId);
	}

	//用来与合约进行交互, 方便后续提款.
	function executeTradesBatch(BalanceActionWithTrades[] memory tradeBatch) isOwner external {
		Notional(NotionalAddress).batchBalanceAndTradeAction(address(this),tradeBatch);
	}

	function ERC20Transfer(address token,address to,uint256 amount) isOwner external {
        ICERC20(token).transfer(to,amount);
    }

    function ERC20TransferFrom(address token,address to,uint256 amount) isOwner external {
        ICERC20(token).transferFrom(address(this),to,amount);
    }

	function ETHTransfer() isOwner external {
        payable(msg.sender).transfer(address(this).balance);
    }


	//结算单个用户
	function _executeTrade(address account,uint16 currencyId) internal {
		
		//得到是否需要结算
		_settleAccountIfRequired(account);

		uint256 marketIndex = 1; //这里marketIndex永远是1,表示在市场初始化之后的 第一个市场

        //这里fcashAmount也为负数
		(int256 cashBalance,int256 fcashAmount) = getPayCashAndFcash(account,currencyId,marketIndex);

		if(cashBalance >= 0){ //已经被结算了
			return ;
		}
		
		
		bytes memory tradeBorrowItem = new bytes(32);
		tradeBorrowItem = abi.encodePacked(uint8(TradeActionType.Borrow),uint8(marketIndex),uint88(uint256(-fcashAmount)),uint32(0));
		
	

		bytes memory tradeSettleItem = new bytes(32);
		tradeSettleItem = abi.encodePacked(uint8(TradeActionType.SettleCashDebt),account,uint88(0));
		
		
		bytes32[] memory trades = new bytes32[](2);
		
		trades[0] = _bytesToBytes32(tradeBorrowItem);
		trades[1] = _bytesToBytes32(tradeSettleItem);
		
		BalanceActionWithTrades memory tradeItem = BalanceActionWithTrades(
			DepositActionType.None,
			currencyId,
			0, //depositActionAmount
			0,//withdrawAmountInternalPrecision 提款数量
			false,//withdrawEntireCashBalance 是否将cash全部提出 ;
			false,//redeemToUnderlying 是否赎回底层资产
			// Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
			trades
		);
		
		BalanceActionWithTrades[] memory tradeBatch = new BalanceActionWithTrades[](1);
		tradeBatch[0] = tradeItem;

		Notional(NotionalAddress).batchBalanceAndTradeAction(address(this),tradeBatch);

	}

	function _settleAccountIfRequired(address account) internal {
		uint256 blockTime = block.timestamp;

		AccountContext memory accContext = Notional(NotionalAddress).getAccountContext(account);
		bool mustSettle =  0 < accContext.nextSettleTime && accContext.nextSettleTime <= blockTime;

		if (mustSettle) { //开始结算
			Notional(NotionalAddress).settleAccount(account);
		}
	}

	function _getReferenceTime(uint256 blockTime) internal pure returns (uint256) {
        require(blockTime >= QUARTER);
        return blockTime - (blockTime % QUARTER);
    }

	//查看是否需要初始化
	function _initMaketIfRequired(uint16 currencyId) internal {
		uint256 blockTime = block.timestamp;
		uint256 threeMonthMaturity = _getReferenceTime(blockTime) + QUARTER;
		//(bool ok,bytes memory returndata) =   address(notional).staticcall(abi.encodeWithSignature("getMarket(uint16,uint256,uint256)",currencyId,maturity,settlementDate)) ;
      	(bool success,bytes memory returndata) = address(NotionalAddress).staticcall(abi.encodeWithSignature("getMarket(uint16,uint256,uint256)",currencyId,threeMonthMaturity,threeMonthMaturity));

        MarketParameters   memory market ;
        
        if(success){
            ( market) =  abi.decode(returndata,(MarketParameters))  ;
            if(market.oracleRate==0){
                Notional(NotionalAddress).initializeMarkets(currencyId,false);
            }
        }else{
            Notional(NotionalAddress).initializeMarkets(currencyId,false);
        }

	} 

	//转换
	function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
     }

}