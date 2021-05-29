// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IStructs.sol";

// for CompFi Interfaces
import "./IERC20.sol";
import "./Ic_or_w_ETH.sol";
import "./IComptroller.sol";

// KyberSwap
import "./IKyberNetworkProxy.sol";


// dYdX flash loan contract
interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
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

abstract contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public virtual view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public virtual;
}

pragma solidity ^0.8.0;

contract DyDxFlashLoan is Structs {
    DyDxPool kDyDxPool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    // address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    // address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    mapping(address => uint256) public currencies;
    
    constructor() {
        currencies[kWETH] = 1;
        currencies[kSAI] = 2;
        currencies[kUSDC] = 3;
        currencies[kDAI] = 4;
    }

    modifier onlyPool() {
        require(msg.sender == address(kDyDxPool), "FlashLoan: could be called by DyDx pool only");
        _;
    }

    function tokenToMarketId(address token) public view returns (uint256 ) {
        
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
}


/**********************************************************
 * Main Contract: PreachersCompFiLqdt
 **********************************************************/
pragma solidity ^0.8.0;

contract PreachersCompFiLqdt is DyDxFlashLoan {
    uint256 public loan;
    IKyberNetworkProxy cKyberProxy = IKyberNetworkProxy(kKyberProxy);

    // Contract owner
    address payable owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }

    constructor() payable {

        // Track the contract owner
        owner = payable(msg.sender);
        
    }

    /*************************************************************************************************************
     * Call this contract function from the external 
     * remote job to perform the liquidation.
     * 
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
        
        // Get the amount of the token in this contracts balance.
        // At least 2 wei is needed for the loan fee.
        uint256 balanceBefore = ERC20(flashToken).balanceOf(address(this));
        
        // Populate the passthru data structure, which will be used
        // by 'callFunction'
        bytes memory data = abi.encode(
            flashToken, 
            flashAmount, 
            balanceBefore,
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
    ) external onlyPool {
	
	    // Decode the parameters in "calldata" as passed by doCompFiLiquidate.
        (address flashToken, 
        uint256 flashAmount, 
        uint256 balanceBefore,
        address targetAccount, 
        address targetToken, 
        uint256 liquidateAmount,
        address collateralToken) = 
			abi.decode(data, (address, uint256, uint256, address, address, 
			uint256, address));

		ERC20 cFlashToken = ERC20(flashToken);

		require(cFlashToken.balanceOf(address(this)) - balanceBefore >=
		    flashAmount ,"contract did not get the loan");
		emit Borrowed(flashToken, cFlashToken.balanceOf(address(this)));
		
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
		uint[] memory ERRORS = ctroll.enterMarkets(cTokens);
		if (ERRORS[0] != 0) {
            revert("01 Comptroller enter Markets for target token failed. ");
		}
		
		if (targetToken == kcETH){
		    c_or_w_ETH ceTargetToken = c_or_w_ETH(targetToken);
		    ceTargetToken.liquidateBorrow{value: flashAmount}
		        (targetAccount, collateralToken);
		} else {
		    cTargetToken.liquidateBorrow(targetAccount, flashAmount, collateralToken);
		}
		require(ctroll.exitMarket(targetToken) == 0, 
		    "Exit Market of target token failed. ");
		 
		// 4. Swap the received collateral tokens back to USDC to repay the flash loan.
		cTokens[0] = collateralToken;
		ERRORS = ctroll.enterMarkets(cTokens);
		require(ERRORS[0] == 0, "02 Comptroller.enter Markets for collateral Token failed.");

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
    
    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
        emit ChangedOwner(owner, newOwner);
    }

    function getTokenBalance(address tokenAddress) public view returns(uint256) {
        ERC20 theToken = ERC20(tokenAddress);
        return theToken.balanceOf(address(this));
    }
    
    function withdraw(address token) public onlyOwner returns(bool) {
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

    event Transfer(address from, address to, uint256 value);
    event Borrowed(address tokenborrowed, uint256 amount);
    event Swapped(address fromtoken, uint256 fromamount,
        address totoken, uint256 toamount);
    event Liquidated(address account, address token, uint256 amount );
    event ChangedOwner(address payable owner, address payable newOwner);
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
            '' // empty hint
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