// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;
// PreachersCompFiLqdt v1.0.28  KOVAN     USDC-USDC

import {IERC20,
    IComptroller, IUniswapV2Router01, IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair,
    IWETH, CEther, IUniswapV2Callee} from "Interfaces.sol";
import {UniswapV2Library} from "Libraries.sol";

// https://uniswap.org/docs/v2/smart-contracts/router02/
// Same address on Mainnet and Kovan
address constant kUniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

// address constant kETHe = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
// address constant kETH0 = address(0x0000000000000000000000000000000000000000);    // preferred by UniSwap
address constant kETH = address(0x0);    // preferred by UniSwap

//address constant kComptroller = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074; // Mainnet
//address constant kCETH = address (0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);    //  Mainnet
//address constant kDAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);    // Mainnet
//address constant kWETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    /**************** CHECK AccountLiquidity  ********************************/

address constant kComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B; // Kovan
address constant kCETH = address (0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72);    //  Kovan
address constant kDAI = address(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);    // Kovan
address constant kWETH = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);	// Kovan


contract PreachersCompFiLqdt {
    
    bool internal _notEntered;

    struct varStack {
        address LqdtAccount;
        address tokenBorrow;      // Lqdt Borrow
        address tokenBUnderlying;
        address tokenPay;           // Collateral
        address tokenPUnderlying;
        address UniSwapPairAddress;
        address sender;
        uint256 lqdtAmount;
        uint256 amountToRepay;
        uint256 gas;
    }
    varStack gVars;

    
//    IUniswapV2Factory constant uniswapV2Factory = 
//        IUniswapV2Factory(kUniswapV2Factory); // same for all networks

    // ACCESS CONTROL

    bool bMintCTokens = true;
    bool bApproveRedeem = false;
    bool bTransferApprove = true;

    // Contract owner
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }
    
    receive() external payable {}
    
    fallback() external payable {}

    /*************************************************************************************************************
     * Call this contract function from the external 
     * remote job to perform the liquidation.
     ************************************************************************************************************/
    function doCompFiLiquidate(
        // Borrow Account to be liquidated
        address _lqdtAccount,       // Borrower
        address _lqdtToken,         // CompFi CErc20/CEther Token to be liquidated
        address _lqdtUnderlying,    // Token to be flash loaned and minted into _lqdtToken
        uint256 _lqdtAmount,   // Maximum allowed of Underlying token for liquidation
        // liquidation reimbursement and Reward Token
        address _collateralToken,   // Tokens to be redeemed to repay flash loan and for reward
        address _collateralUnderlying,  // Cryptocurrency to repay flash loan
        uint256 _Gas               // gas amount (3000000 wei?) for liquidateBorrow
      ) public {
        
        require(_lqdtToken == _collateralToken && _lqdtToken != kETH, "ERC20 TO same ERC20 allowed");
        
        gVars.tokenBUnderlying = address(_lqdtUnderlying);
        gVars.tokenPUnderlying = address(_collateralUnderlying);
        gVars.lqdtAmount = _lqdtAmount;
        gVars.LqdtAccount = _lqdtAccount;
        
        gVars.tokenBorrow = _lqdtToken;
        gVars.tokenPay = kWETH;     // Pair w/WETH to get a usable UNISWAP pair
        gVars.amountToRepay = 0;
        gVars.gas = _Gas;
        
        bytes memory _params = abi.encode(" ");
    
        (address token0, address token1) = gVars.tokenBorrow < gVars.tokenPay ?
            (gVars.tokenBorrow, gVars.tokenPay) : (gVars.tokenPay, gVars.tokenBorrow);

        // permissionedPairAddress = uniswapV2Factory.getPair(_tokenBorrow, tokenPay);
        gVars.UniSwapPairAddress = 
            IUniswapV2Factory(kUniswapV2Factory).getPair(token0, token1);

        require(gVars.UniSwapPairAddress != address(0), "Requested pair is not available.");
        
        token0 = IUniswapV2Pair(gVars.UniSwapPairAddress).token0();
        token1 = IUniswapV2Pair(gVars.UniSwapPairAddress).token1();
        
        //  PERFORM THE SWAP. This will call the function uniswapV2Call.
        // The swap will be for any ERC20 to WETH
        // The swap will be made for 0 WETH and Lqdt amount of the ERC20
        IUniswapV2Pair(gVars.UniSwapPairAddress).swap(
            gVars.tokenBorrow == token0 ? gVars.lqdtAmount : 0,
            gVars.tokenBorrow == token1 ? gVars.lqdtAmount : 0,
            address(this), _params);

        /*************************************************************************/
    
        // leave no currency behind
        OwnerWithdraw(gVars.tokenPay, 1);

        OwnerWithdraw(gVars.tokenPUnderlying, 1);
        
        delete gVars;
        
        _notEntered = true;

        return;
	}
	


    /********************************************************************************************/
    /***********************  START OF SWAP EXECUTE FUNCTIONS  ***********************************/
    /********************************************************************************************/

    /*****************************************************************************************************
     * THIS FUNCTION IS CALLED BY THE IUniswapV2Pair.swap FUNCTION BY NAME AND PARAMETERS
     *                  --------------------------------------
     * Repayment
     * At the end of following uniswapV2Call, there must return enough tokens to repay the pair to make
     * it whole. Specifically, this means that the product of the pair reserves after the swap,
     * discounting all token amounts sent by 0.3% LP fee, must be greater than before.
     * 
     * msg.sender is the swap pair address
     * function uniswapV2Call(
     *      address sender,         // this contract
     *      uint amount0,           // amount of token0
     *      uint amount1,           // amount of token1
     *      bytes calldata data) {// local parameter data
     * 
     *  address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
     *  address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
     * 
     *   // ensure that msg.sender is a V2 pair
     *  assert(msg.sender == IUniswapV2Factory(factoryV2).getPair(token0, token1));
     *  ---- rest of the custom actions go here;'
     *}
     * 
    *****************************************************************************************************/
    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data) external payable {

        gVars.sender = _sender;

        // access control
        require(msg.sender == gVars.UniSwapPairAddress,
            "Preacher says: y'all need to git from this here uniswapV2Call");
        require(gVars.sender == address(this),
            "Woe Nelly! Preacher says: only this here contract may holler this here uniswapV2Call");
        
        // compute amount of tokens that need to be paid back
        // uint fee = ((gVars.lqdtAmount * 3)/997) + 1;
        gVars.amountToRepay = gVars.lqdtAmount + (((gVars.lqdtAmount * 3)/997) + 1);

        // use the swap flash tokens to liquidate the CompFi unhealthy account
        ExecuteLiquidation();

        // payback the loan
        RepayLoan();

        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
            _data;
		}
        
        return;
	}
    

    // @description This is where the unhealthy CompFi account is liquidated
    // @dev When this function executes, this contract will hold _amount of _tokenBorrow (LqdtToken).

    function ExecuteLiquidation() public payable noReentrancy {
            
        // access control
        require(msg.sender == gVars.UniSwapPairAddress,
            "Preacher says: y'all need to git from ExecuteLiquidation");
        require(gVars.sender == address(this),
            "Woe Nelly! Preacher says: only this contract may initiate this here ExecuteLiquidation");

		IERC20 cLqdtTokenUnderlying = IERC20 (gVars.tokenBUnderlying);

        IERC20 cLqdtToken = IERC20(gVars.tokenBorrow);
            
    	if (bMintCTokens){
            cLqdtTokenUnderlying.approve(gVars.tokenBorrow, 0);  // reset amount
            cLqdtTokenUnderlying.approve(gVars.tokenBorrow, gVars.lqdtAmount);  // approve to liquidate

    	    cLqdtToken.mint(gVars.lqdtAmount);
    	   	require(cLqdtToken.balanceOf(address(this)) >= gVars.lqdtAmount,
    	   	    "Preacher says: come back when you larn mintin'");
        		    
            cLqdtToken.approve(gVars.tokenBorrow, 0);  // reset amount
            cLqdtToken.approve(gVars.tokenBorrow, gVars.lqdtAmount);  // approve to liquidate
    		
    		cLqdtToken.liquidateBorrow(gVars.LqdtAccount, gVars.lqdtAmount, gVars.tokenPay);

            cLqdtToken.approve(gVars.tokenBorrow, 0);  // reset amount
 		} else {
 		    
            cLqdtTokenUnderlying.approve(gVars.tokenBUnderlying, 0);  // reset amount
            cLqdtTokenUnderlying.approve(gVars.tokenBUnderlying, gVars.lqdtAmount);  // approve to liquidate

    		cLqdtTokenUnderlying.liquidateBorrow(gVars.LqdtAccount, gVars.lqdtAmount, gVars.tokenPay);

            cLqdtTokenUnderlying.approve(gVars.tokenBUnderlying, 0);  // reset amount
 		}

        
        return;
	}


	function RepayLoan() public payable {
	        
        // access control
        require(msg.sender == gVars.UniSwapPairAddress, "Preacher says: y'all need to get from RepayLoan");
        require(gVars.sender == address(this),
            "Woe Nelly! Preacher says: only this contract may initiate a RepayLoan");

	    // Redeem the collateral to repay the flash loan
		// convert the CompFi token to the underlying token

        IERC20 cCollateralToken = IERC20(gVars.tokenPay);

        if ( cCollateralToken.balanceOf(address(this)) > 0){
                // redeem all
                
            if(bApproveRedeem){
                cCollateralToken.approve(gVars.tokenPay, 0);
                cCollateralToken.approve(gVars.tokenPay, cCollateralToken.balanceOf(address(this)));
            }
            
            cCollateralToken.redeem(cCollateralToken.balanceOf(address(this)));
            
            if(bApproveRedeem){
                cCollateralToken.approve(gVars.tokenPay, 0);
            }
        }

        IERC20 cTokenToRepay = IERC20(gVars.tokenPay);    // underlying Collateral
        require(cTokenToRepay.balanceOf(address(this)) >= gVars.amountToRepay,
            "Preacher says: looks like we're a few dollars short");

        // tried gVars.UniSwapPairAddress, failed
        // tried gVars.tokenPay, failed
        // trying address(this)
        // try kUniswapV2Factory
        cTokenToRepay.approve(address(this), 0);
        cTokenToRepay.approve(address(this), gVars.amountToRepay);

        // Repay Uniswap
        cTokenToRepay.transfer(gVars.UniSwapPairAddress, gVars.amountToRepay);
        
        cTokenToRepay.approve(address(this), 0);

    }


    /********************************************************************************************/
    /***********************  END OF SWAP EXECUTE FUNCTIONS  ***********************************/
    /********************************************************************************************/
    
    /***************  End of UNISWAP functions  **********************************************************/

    /*************************************************************************************/
    function OwnerWithdraw(address _token, uint256 _iApprove) public payable returns(bool) {
        require( msg.sender == owner,
            "Preacher says: what made you think this money was yoes?" );

        uint256 tokenBalance = 0;
        
        if (address(_token) == kETH){
            tokenBalance = address(this).balance;
            if (tokenBalance > 0){
                owner.transfer(tokenBalance);
                return true;
    		}
		} else {

            IERC20 cWithdrawToken = IERC20(_token);
            if (cWithdrawToken.balanceOf(address(this)) > 0){
                tokenBalance = cWithdrawToken.balanceOf(address(this));
                if (_iApprove == 1) {   // approval to transfer to owner appears
                    // to be unnecessary
                    cWithdrawToken.approve(address(this), 0);
                    cWithdrawToken.approve(address(this), type(uint256).max);
        		}
        		cWithdrawToken.transfer(owner, tokenBalance);
                return true;
    		}
		}
        return false; // nothing was withdrawn
	}

    function GetPair(address _token0, address _token1) public {
        
        (address token0, address token1) = _token0 < _token1 ?
            (_token0, _token1) : (_token1, _token0);
            
        address pairAddress = 
            IUniswapV2Factory(kUniswapV2Factory).getPair(token0, token1);

        token0 = IUniswapV2Pair(pairAddress).token0();
        token1 = IUniswapV2Pair(pairAddress).token1();
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
        
        uint256 token0PairBalance = IERC20(token0).balanceOf(pairAddress);
        uint256 token1PairBalance = IERC20(token1).balanceOf(pairAddress);

        emit PairInfo(token0, reserve0, token1, reserve1,
            pairAddress, token0PairBalance, token1PairBalance, "PairInfo");
        return;
	}
    event PairInfo(address tokenA, uint256 reserveA,
        address tokenB, uint256 reserveB, address pairAddress, uint256, uint256, string _eventname);
        
    function AccountLiquidity(address _account) public view returns (uint256, uint256, uint256){

        IComptroller cTroll = IComptroller(kComptroller);

        return cTroll.getAccountLiquidity(address(_account));
	}
    
    function SetLck(uint _set) public returns (bool){
        require( msg.sender == owner, "caller is not the owner!" );
        // in case lock is left on or needs to be locked
        if (_set == 1){ // Unlock
        
            if (_notEntered){_notEntered = true;}

		} else {        // Lock application
		    
            if (_notEntered){_notEntered = false;}

		}
        return _notEntered;
	}
	
	function SetFlags(uint _bMint, uint _bApproveRedeem, uint _bTransferApprove) public {

	    require( msg.sender == owner, "caller is not the owner!" );

	    if (_bMint == 1){
	        bMintCTokens = true;
	    } else if (_bMint == 2){
	        bMintCTokens = false;
	    }
	
	    if (_bApproveRedeem == 1){
	        bApproveRedeem = true;
	    } else if (_bApproveRedeem == 2){
	        bApproveRedeem = false;
	    }
	            
	    if (_bTransferApprove == 1){
	        bTransferApprove = true;
	    } else if (_bTransferApprove == 2){
	        bTransferApprove = false;
	    }
    }
	
    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier noReentrancy() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /*************************************************************************/    
}