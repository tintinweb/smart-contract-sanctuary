/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

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

interface IKyberNetworkProxy {

    event ExecuteTrade(
        address indexed trader,
        ERC20 src,
        ERC20 dest,
        address destAddress,
        uint256 actualSrcAmount,
        uint256 actualDestAmount,
        address platformWallet,
        uint256 platformFeeBps
    );

    /// @notice Backward compatible function
    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param walletId Platform wallet address for receiving fees
    /// @param hint Advanced instructions for running the trade 
    /// @return Amount of actual dest tokens in twei
    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param platformWallet Platform wallet address for receiving fees
    /// @param platformFeeBps Part of the trade that is allocated as fee to platform wallet. Ex: 10000 = 100%, 100 = 1%
    /// @param hint Advanced instructions for running the trade 
    /// @return destAmount Amount of actual dest tokens in twei
    function tradeWithHintAndFee(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    /// @notice Backward compatible function
    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param platformWallet Platform wallet address for receiving fees
    /// @return Amount of actual dest tokens in twei
    function trade(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFee(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}

// dYdX flash loan contract
interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

abstract contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public virtual view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public virtual;
}


address constant kETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
// Compound.Finance Comptroller constants
// Note:To call Comptroller functions, use the Comptroller ABI on the Unitroller address.
address constant kUnitroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
address constant kComptroller = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;
address constant kcUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
address constant kcETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

// KyberSwap Proxy contract 
address constant kKyberProxy = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;
// KyberHintHandler (KyberMatchingEngine)
address constant kKybeHint = 0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C;

// dYdX loan currencies
address constant kWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant kSAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
address constant kUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant kDAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

/**********************************************************
 * Main Contract: PreachersCompFiLqdt v1.0.4
 **********************************************************/
contract PreachersCompFiLqdt is Structs {
    IKyberNetworkProxy internal cKyberProxy = IKyberNetworkProxy(kKyberProxy);
    DyDxPool internal kDyDxPool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

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

    // dYdX loan Currencies
    mapping(address => uint256) public currencies;
    
    function tokenToMarketId(address token) internal view returns (uint256 ) {
        
        require(currencies[token] != 0, "FlashLoan: Unsupported token");
        
        return currencies[token] - 1;
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
        address targetAccount, 
        address targetToken, 
        uint256 liquidateAmount,
        // liquidation reimbursement and Reward Token
        address collateralToken
        ) external returns(bool) {
        
        emit PassThru( liquidateAmount );
        
        currencies[kWETH] = 1;
        currencies[kSAI] = 2;
        currencies[kUSDC] = 3;
        currencies[kDAI] = 4;
    
        // Populate the passthru data structure, which will be used
        // by 'callFunction'
        bytes memory data = abi.encode(
            flashToken, 
            flashAmount,
            targetAccount, 
            targetToken, 
            liquidateAmount, 
            collateralToken);
        
        // execution goes to `callFunction`
        // STEP 1
        flashloan(flashToken, flashAmount, data);
        emit Liquidated( targetAccount, targetToken, liquidateAmount );
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
         address targetAccount, 
         address targetToken, 
         uint256 liquidateAmount,
         address collateralToken) = 
			abi.decode(data, (address, uint256, address, address, uint256, address));
		
		ERC20 cFlashToken = ERC20(flashToken);

		emit Borrowed(flashToken, cFlashToken.balanceOf(address(this)));

		require(cFlashToken.balanceOf(address(this)) >= flashAmount ,"Contract did not get the loan");
		
        // function approve(address _spender, uint256 _value) public returns (bool success)
		ERC20 underlying = ERC20(cFlashToken.underlying( )); // get a handle for the underlying asset contract
		require(underlying.approve(address(cFlashToken), flashAmount) == true, 
		    "01 approval failed"); // approve the transfer
		require(cFlashToken.mint(flashAmount) > 0, "01 Mint failed");    // mint the cTokens and assert there is no error
		
		ERC20 cTargetToken = ERC20(targetToken);
        // Step 2. Swap USDC for targetToken
        if (targetToken != kcUSDC) {
    	   require( executeKyberSwap(cFlashToken, flashAmount,
	            cTargetToken, payable(address(this)), 
	            liquidateAmount) > 0, "02 First Token swap failed");
        }
        
        require(cTargetToken.approve(address(this), liquidateAmount) == true,
            "02 approval failed.");
        
        // Step 3. Pay down the amount borrowed by the unsafe account
		// -- Enter the market for the token to be liquidated
		Comptroller ctroll = Comptroller(kUnitroller);

		address[] memory cTokens = new address[](1);
		cTokens[0] = targetToken;
		uint[] memory Errors = ctroll.enterMarkets(cTokens);
		if (Errors[0] != 0) {
            revert("01 Comptroller enter Markets for target token failed. ");
		}
		
		if (targetToken == kcETH){
		    ICorWETH ceTargetToken = ICorWETH(targetToken);
		    ceTargetToken.liquidateBorrow{value: flashAmount}
		        (targetAccount, collateralToken);
		} else {
		    cTargetToken.liquidateBorrow(targetAccount, flashAmount, collateralToken);
		}
		require(ctroll.exitMarket(targetToken) == 0, 
		    "Exit Market of target token failed. ");
		 
		// 4. Swap the received collateral tokens back to USDC to repay the flash loan.
		cTokens[0] = collateralToken;
		Errors = ctroll.enterMarkets(cTokens);
		require(Errors[0] == 0, "02 Comptroller.enter Markets for collateral Token failed.");

		ERC20 cCollateralToken = ERC20(collateralToken);
		require(cCollateralToken.approve(address(this), cCollateralToken.balanceOf(address(this))) == true,
		    "03 Collateral Token approval failed.");
		    
		if (collateralToken != kcUSDC) {
    	   require( executeKyberSwap(cCollateralToken, 
    	        cCollateralToken.balanceOf(address(this)),
	            cTargetToken, payable(address(this)), 
	            899999999999999999) > 0, "02 First Token swap failed");
        }
        
    	// -- Liquidation is completed in flashloan()
    }
    
    function AccountsAssets ( address LAccount ) external view returns ( address[] memory ){
        Comptroller troll = Comptroller(kUnitroller);
        return troll.getAssetsIn( LAccount );
    }
    
    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
        emit ChangedOwner(owner, newOwner);
    }

    function getTokenBalance(address tokenAddress) external view returns(uint256) {
        ERC20 theToken = ERC20(tokenAddress);
        return theToken.balanceOf(address(this));
    }
    
    function getETHBalance( ) external view returns(uint256) {
        ICorWETH theToken = ICorWETH( 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE );
        return theToken.balanceOf(address(this));
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
    
    function fWithdraw(address token) public onlyOwner returns(bool) {
        uint256 tokenBalance;
        // withdrawing Ether
        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if (address(this).balance > 0){
                tokenBalance = address(this).balance;
                payable(msg.sender).transfer(address(this).balance);
            }

        } else {
            ERC20 withdrawToken = ERC20(token);
            if (withdrawToken.balanceOf(address(this)) > 0){
                tokenBalance = withdrawToken.balanceOf(address(this));
                require(withdrawToken.transfer(msg.sender, 
                    (withdrawToken.balanceOf(address(this)))));
            }
        }
        emit Withdrawn(token, tokenBalance);
        return true;
    }

    // All events for this contract
    event Borrowed(address tokenborrowed, uint256 amount);
    event ChangedOwner(address payable owner, address payable newOwner);
    event Liquidated(address account, address token, uint256 amount );
    event PassThru( uint256 liquidateampount );
    event Received(address, uint);
    event Swapped(address fromtoken, uint256 fromamount, address totoken, uint256 toamount);
    event Transfer(address from, address to, uint256 value);
    event Withdrawn(address token, uint256 amount);

    /***************************************************************************
     * KyberSwap functions
    ****************************************************************************/
    /// Swap from srcToken to destToken (including ether)
    function executeKyberSwap( ERC20 cSrcToken, uint256 srcQty, ERC20 cDestToken, 
        address payable destAddress, uint256 maxDestAmount
    ) internal returns ( uint256 ) {
        
        // if not Ethereum
        if (address(cSrcToken) != kETH) {

            // mitigate ERC20 Approve front-running attack, by initially setting
            // allowance to 0
            require(cSrcToken.approve(address(cKyberProxy), 0), "approval to 0 failed");

            // set the spender's token allowance to tokenQty
            require(cSrcToken.approve(address(cKyberProxy), srcQty), "approval to srcQty failed");
        }

        // Get the minimum conversion rate
        uint256 platformFeeBps = 25;    // using the Kyber example https://developer.kyber.network/docs/Integrations-SmartContractGuide/#fetching-rates
        
        uint256 minConversionRate = cKyberProxy.getExpectedRateAfterFee(
            cSrcToken,
            cDestToken,
            srcQty,
            platformFeeBps,
            "" // empty hint
        );
        
        
        /*********************************************************************************
         * function trade(ERC20 src, uint256 srcAmount,
         *  ERC20 dest, address payable destAddress,
         *  uint256 maxDestAmount,    // wei
         * 
         *  uint256 minConversionRate,
         *      Minimum conversion rate (in wei). Trade is canceled if actual rate is lower
         *      Should match makerAssetAmount/takerAssetAmount
         *      This rate means for every 1 srcAmount, a Minimum
         *      of X target Tokens are expected. 
         *      (Source token value / Target Token value) * 10**18 
         * 
         *  address payable platformWallet ) external payable returns (uint256);
        **********************************************************************************/
        // Execute the trade and send to this contract to use to pay down the unsafe account
        uint256 destAmount = cKyberProxy.trade(cSrcToken, srcQty, 
            cDestToken, payable(address(this)), 
            maxDestAmount, 
            minConversionRate,
            // this contract
            destAddress);
          
        emit Swapped(address(cSrcToken), srcQty, address(cDestToken), destAmount);
        return destAmount;
    }
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