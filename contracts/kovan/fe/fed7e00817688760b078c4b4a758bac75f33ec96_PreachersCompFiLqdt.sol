// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;
// PreachersCompFiLqdt v1.0.17  KOVAN KOVAN KOVAN KOVAN 

import { ILendingPool, ILendingPoolAddressesProvider, IERC20,
    IComptroller, IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair,
    IWETH, CEther, IUniswapV2Callee } from "Interfaces.sol";
import { SafeMath } from "Libraries.sol";

// https://uniswap.org/docs/v2/smart-contracts/router02/
// Same address on Mainnet and Kovan
address constant UNISWAP_ROUTER_ADDRESS = address( 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );
address constant kUniswapV2Factory = address( 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f );

address constant kETH = address( 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE );
address constant ETH = address( 0 );    // preferred by UniSwap

address constant kCETH = address ( 0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72 );    //  Kovan
address constant kWETH = address( 0xd0A1E359811322d97991E03f863a0C30C2cF029C ); // Kovan
address constant kDAI = address( 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa );    // Kovan
address constant kUnitroller = address( 0x5eAe89DC1C671724A672ff0630122ee834098657 );    // Kovan

//address constant kCETH = address ( 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 );    //  Mainnet
//address constant kWETH = address( 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ); // Mainnet
//address constant kUnitroller = address( 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B );    // Mainnet
//address constant kDAI = address( 0x6B175474E89094C44Da98b954EedeAC495271d0F );    // Mainnet


contract PreachersCompFiLqdt {
    
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02( UNISWAP_ROUTER_ADDRESS );
    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory( kUniswapV2Factory ); // same for all networks

    // ACCESS CONTROL
    // Only the `permissionedPairAddress` may call the `uniswapV2Call` function
    address permissionedPairAddress = address( 1 );
    enum SwapType {SimpleLoan, SimpleSwap, TriangularSwap}
    
    // stack too deep
    address lqdtAccount;
    address lqdtToken;
    uint256 lqdtTokenAmount = 0;
    address collateralToken;
    IERC20 cCollateralToken;
    IERC20 G_cCollateralUnderlying;
    address[] cTokens = new address[]( 2 );
    address[] cTokens1 = new address[]( 1 );
    uint256 G_CollatAmt = 0;

   // Contract owner
    address payable public owner;

    // Modifiers
    modifier onlyOwner( ) {
        require( msg.sender == owner, "caller is not the owner!" );
        _;
    }

   constructor( ) {
       owner = payable( msg.sender );
   }
    
    receive( ) external payable {
        emit Received( "Tokens received", msg.sender, msg.value );
    }
    event Received( string, address, uint256 );
    
    /*************************************************************************************************************
     * Call this contract function from the external 
     * remote job to perform the liquidation.
     ************************************************************************************************************/
    function doCompFiLiquidate( 
        // Borrow Account to be liquidated
        address _lqdtAccount,       // Borrower
        address _lqdtToken,         // CompFi CErc20/CEther Token to be liquidated
        address _lqdtUnderlying,    // Token to be flash loaned and minted into _lqdtToken
        uint256 _lqdtAmount,   // Maximum wei allowed of Underlying token for liquidation
        // liquidation reimbursement and Reward Token
        address _collateralToken,   // Tokens to be redeemed to repay flash loan and for reward
        address _collateralUnderlying,  // Cryptocurrency to repay flash loan
        uint256 _Gas                // gas amount ( 3000000 wei? ) for liquidateBorrow
        ) external payable returns( bool ) {
        
        address LqdtUnderlying = _lqdtUnderlying;
        address CollateralUnderlying = _collateralUnderlying;
        // ETH 0x00 is preferred by UniSwap
        if ( address( _lqdtUnderlying ) == kETH ){ LqdtUnderlying = kWETH; }
        if ( address( _collateralUnderlying ) == kETH ){ CollateralUnderlying = kWETH; }
        
        bytes memory _params =
            abi.encode( 
                address( _lqdtAccount ),
                address( _lqdtToken ),
                address( _collateralToken ),
                _Gas );
        
        PreachersSwap( address( LqdtUnderlying ), _lqdtAmount,
            address( CollateralUnderlying ), _params );

        // Transfer any remaining tokens    - verified working for flashtoken
        fWithdraw( _lqdtToken, 1 );
        fWithdraw( _collateralToken, 1 );
        fWithdraw( _lqdtUnderlying, 1 );
        fWithdraw( _collateralUnderlying, 1 );
        fWithdraw( kWETH, 1 );
        fWithdraw( kETH, 1 );

        return true;
    }

    /*****************************************************************************************************/
    /*********************  UNISWAP FLASH SWAP SECTION  **************************************************/
    /*****************************************************************************************************/
    // https://github.com/Austin-Williams/uniswap-flash-swapper/blob/master/contracts/UniswapFlashSwapper.sol
    // @description Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token to flash-borrow, use 0x0 for ETH
    //      _lqdtTokenUnderlying
    // @param _amount, The amount of _tokenBorrow needed
    // @param _tokenPay, The address of the token to use to payback the flash-borrow, use 0x0 for ETH
    //      _collateralUnderlying
    // @param _params, Data that will be passed to the `execute` function
    
    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function PreachersSwap(
        address _tokenBorrow,
        uint256 _amount,
        address _tokenPay,
        bytes memory _userData ) internal {
        
        bool isBorrowingEth;
        bool isPayingEth;
        address tokenBorrow = _tokenBorrow;
        address tokenPay = _tokenPay;

        if ( tokenBorrow == ETH ) {
            isBorrowingEth = true;
            tokenBorrow = kWETH; // we'll borrow WETH from UniswapV2 but then unwrap it for the user
        }
        if ( tokenPay == ETH ) {
            isPayingEth = true;
            tokenPay = kWETH; // we'll wrap the user's ETH before sending it back to UniswapV2
        }

        if ( tokenBorrow == tokenPay ) {
            simpleFlashLoan( tokenBorrow, _amount, isBorrowingEth, isPayingEth, _userData );
            return;
        } else if ( tokenBorrow == kWETH || tokenPay == kWETH ) {
            simpleFlashSwap( tokenBorrow, _amount, tokenPay, isBorrowingEth, isPayingEth, _userData );
            return;
        } else {
            triangularFlashSwap( tokenBorrow, _amount, tokenPay, _userData );
            return;
        }

    }

    // @description This function is used when the user repays with the same token they borrowed
    // @dev This initiates the flash borrow.
    // See `simpleFlashLoanExecute` for the code that executes after the borrow.
    function simpleFlashLoan( address _tokenBorrow, uint256 _amount, bool _isBorrowingEth, 
        bool _isPayingEth, bytes memory _params ) private {
        
        // if WETH is being borrowed, pair it with DAI,     WETH=>DAI, 0xb77098da3262E65739116A6CF9A111DC639b1a0f
        address tokenPay = _tokenBorrow == kWETH ? kDAI : kWETH;
        
        // WETH=>WETH becomes DAI=>WETH
        // to get,create a token pair. they must be sorted less to greater
        (address token0, address token1 ) = _tokenBorrow < tokenPay ?
            (_tokenBorrow, tokenPay) : (tokenPay, _tokenBorrow);

        permissionedPairAddress = uniswapV2Factory.getPair( token0, token1 );
        address pairAddress = permissionedPairAddress; // gas efficiency
        require( pairAddress != address( 0 ), "Requested pair is not available." );
        
        token0 = IUniswapV2Pair( pairAddress ).token0( );
        token1 = IUniswapV2Pair( pairAddress ).token1( );
        
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        
        bytes memory data = abi.encode( 
            SwapType.SimpleLoan,
            _tokenBorrow,
            _amount,
            _tokenBorrow,
            _isBorrowingEth,
            _isPayingEth,
            bytes( "" ),
            _params
        );

        //  PERFORM THE SWAP. This will call the function uniswapV2Call.
        // The swap will be for ????/WETH or for DAI/WETH
        IUniswapV2Pair( pairAddress ).swap( amount0Out, amount1Out, address( this ), data );
        
        return;
    }

     // @description This function is used when either the _tokenBorrow or _tokenPay is kWETH or ETH
    // @dev Since ~all tokens trade against kWETH ( if they trade at all ), we can use a single UniswapV2 pair to
    //     flash-borrow and repay with the requested tokens.
    // @dev This initiates the flash borrow. See `simpleFlashSwapExecute` for the code that executes after the borrow.
    function simpleFlashSwap( 
        address _tokenBorrow,
        uint256 _amount,
        address _tokenPay,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _params
    ) private {
        
        // to get,create a token pair. they must be sorted less to greater
        (address token0, address token1 ) = _tokenBorrow < _tokenPay ?
            (_tokenBorrow, _tokenPay) : (_tokenPay, _tokenBorrow);
            
        permissionedPairAddress = uniswapV2Factory.getPair( token0, token1 );
        address pairAddress = permissionedPairAddress; // gas efficiency
        require( pairAddress != address( 0 ), "Requested pair is not available." );
        
        token0 = IUniswapV2Pair( pairAddress ).token0( );
        token1 = IUniswapV2Pair( pairAddress ).token1( );
        
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode( 
            SwapType.SimpleSwap,
            _tokenBorrow,
            _amount,
            _tokenPay,
            _isBorrowingEth,
            _isPayingEth,
            bytes( "" ),
            _params
        );
        
        // PERFORM THE SWAP. This will call the function uniswapV2Call.
        IUniswapV2Pair( pairAddress ).swap( amount0Out, amount1Out, address( this ), data );
        
        return;
    }


    /*************************************************************************
     * IUniswapV2Pair( pairAddress ).swap
     * fails if 0 of toPay token is borrowed
     * ***********************************************************************
    address public token0 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //DAI
    address public token1 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; //WETH
   // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) public lock {
        
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    /*************************************************************************/



    /**********************************************************************************************
     * @description This function is used when neither the _tokenBorrow nor the _tokenPay is kWETH.
     * @dev Since it is unlikely that the _tokenBorrow/_tokenPay pair has more liquidaity than the
     *      _tokenBorrow/WETH and _tokenPay/WETH pairs, triangular swap has a better chance to
     *      succeed. This is accomplished with 2 swaps. The 1st swaps to WETH ( _tokenBorrow/WETH pair ),
     *      the 2nd swaps from WETH ( _tokenPayTH pair ). However, fees are thereby doubled.
     * 
     * See `triangularFlashSwapExecute` for the code that executes after the borrow.
    ********************************************************************************************/
    function triangularFlashSwap( 
        address _tokenBorrow,
        uint256 _amount,
        address _tokenPay, 
        bytes memory _params ) private {
        
        address token0;
        address token1;
        
        // Get the borrow pair 
        // to get,create a token pair. they must be sorted less to greater
        (token0, token1 ) = _tokenBorrow < kWETH ?
            (_tokenBorrow, kWETH) : (kWETH, _tokenBorrow);
        permissionedPairAddress = uniswapV2Factory.getPair( token0, token1 );
        address borrowPairAddress = permissionedPairAddress;
        require( borrowPairAddress != address( 0 ), "Requested borrow token is not available." );

        // Pay pair
        // to get,create a token pair. they must be sorted less to greater
        (token0, token1 ) = _tokenPay < kWETH ?
            (_tokenPay, kWETH) : (kWETH, _tokenPay);
        permissionedPairAddress = uniswapV2Factory.getPair( token0, token1 );
        address payPairAddress = permissionedPairAddress; // gas efficiency
        require( payPairAddress != address( 0 ), "Requested pay token is not available." );

        // STEP 1: Compute how much kWETH will be needed to get _amount of _tokenBorrow out of
        // the _tokenBorrow/WETH pool
        uint256 pairBalanceTokenBorrowBefore = 
            IERC20( _tokenBorrow ).balanceOf( borrowPairAddress );
        require( pairBalanceTokenBorrowBefore >= _amount, "_amount is too big" );
        
        uint256 pairBalanceTokenBorrowAfter = pairBalanceTokenBorrowBefore - _amount;
        uint256 pairBalanceWeth = IERC20( kWETH ).balanceOf( borrowPairAddress );
        uint256 amountOfWeth = ( ( 1000 * pairBalanceWeth * _amount ) / 
            ( 997 * pairBalanceTokenBorrowAfter ) ) + 1;

        // using a helper function here to avoid "stack too deep" :( 
        triangularFlashSwapHelper( _tokenBorrow, _amount, _tokenPay, borrowPairAddress, 
            payPairAddress, amountOfWeth, _params );
    }

    // @description Helper function for `triangularFlashSwap` to avoid `stack too deep` errors
    function triangularFlashSwapHelper( 
        address _tokenBorrow,
        uint256 _amount,
        address _tokenPay,
        address _borrowPairAddress,
        address _payPairAddress,
        uint256 _amountOfWeth,
        bytes memory _params
    ) private {
        
        // Step 2: Flash-borrow _amountOfWeth kWETH from the _tokenPay/WETH pool
        address token0 = IUniswapV2Pair( _payPairAddress ).token0( );
        address token1 = IUniswapV2Pair( _payPairAddress ).token1( );
        
        uint256 amount0Out = kWETH == token0 ? _amountOfWeth : 0;
        uint256 amount1Out = kWETH == token1 ? _amountOfWeth : 0;
        
        bytes memory triangleData = 
            abi.encode( _borrowPairAddress, _amountOfWeth );
        
        bytes memory data = 
            abi.encode(
                SwapType.TriangularSwap,
                _tokenBorrow,
                _amount,
                _tokenPay, 
                false,
                false,
                triangleData,
                _params );
            
        //  PERFORM THE Pay SWAP. This will call the function uniswapV2Call.
        IUniswapV2Pair( _payPairAddress ).swap( amount0Out, amount1Out, address( this ), data );
        
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
     *      bytes calldata data ) { // local parameter data
     * 
     *  address token0 = IUniswapV2Pair( msg.sender ).token0( ); // fetch the address of token0
     *  address token1 = IUniswapV2Pair( msg.sender ).token1( ); // fetch the address of token1
     * 
     *   // ensure that msg.sender is a V2 pair
     *  assert( msg.sender == IUniswapV2Factory( factoryV2 ).getPair( token0, token1 ) );
     *  ---- rest of the custom actions go here;'
     * }
     * 
    *****************************************************************************************************/
    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call( 
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data ) external {
        
        // access control
        require( msg.sender == permissionedPairAddress, "only permissioned UniswapV2 pair can call" );
        require( _sender == address( this ), "only this contract may initiate" );

        // decode data
        (SwapType _swapType,
         address _tokenBorrow,
         uint256 _amount,
         address _tokenPay,
         bool _isBorrowingEth,
         bool _isPayingEth,
         bytes memory _triangleData,
         bytes memory _userData
        ) = abi.decode( _data, ( SwapType, address, uint256, address, bool, bool, bytes, bytes ) );

        if ( _swapType == SwapType.SimpleLoan ) {
            simpleFlashLoanExecute( _tokenBorrow, _amount, msg.sender, _isBorrowingEth, _isPayingEth, _userData );
        } else if ( _swapType == SwapType.SimpleSwap ) {
            simpleFlashSwapExecute( _tokenBorrow, _amount, _tokenPay, msg.sender, _isBorrowingEth, _isPayingEth, _userData );
        } else {
            triangularFlashSwapExecute( _tokenBorrow, _amount, _tokenPay, msg.sender, _triangleData, _userData );
        }

        // NOOP to silence compiler "unused parameter" warning
        if ( false ) {
            _amount0;
            _amount1;
        }
    }

    // @description This is the code that is called by uniswapV2Call
    // @dev When this code executes, this contract will hold the
    // flash-borrowed _amount of _tokenBorrow.
    function simpleFlashLoanExecute( 
        address _tokenBorrow,
        uint256 _amount,
        address _pairPayAddress,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _userData
    ) private {
        // unwrap kWETH if necessary
        if ( _isBorrowingEth ) {
            IWETH( kWETH ).withdraw( _amount );
        }
        
        // compute amount of tokens that need to be paid back
        uint fee = ((_amount * 3) / 997) + 1;
        uint amountToRepay = _amount + fee;

        address tokenBorrowed = _isBorrowingEth ? ETH : _tokenBorrow;
        address tokenToRepay = _isPayingEth ? ETH : _tokenBorrow;

        // use the swap flash tokens to liquidate the CompFi unhealthy account
        executeLiquidation( tokenBorrowed, _amount, tokenToRepay, amountToRepay, _userData );

        // payback the loan
        // wrap the ETH if necessary
        if ( _isPayingEth ) {
            IWETH( kWETH ).deposit{ value: address( this ).balance }( );
        }
        IERC20( _tokenBorrow ).transfer( _pairPayAddress, G_CollatAmt + 0 );
        
        return;
    }

    // @description This is the code that is executed after `simpleFlashSwap` initiated the flash-borrow
    // @dev When this code executes, this contract will hold the flash-borrowed _amount of _tokenBorrow
    function simpleFlashSwapExecute( 
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        address _pairPayAddress,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _userData
    ) private {
        // unwrap kWETH if necessary
        if ( _isBorrowingEth ) {
            IWETH( kWETH ).withdraw( _amount );
        }
        
        // compute the amount of _tokenPay that needs to be repaid
        // address pairAddress = permissionedPairAddress; // gas efficiency
        uint pairBalanceTokenBorrow = IERC20(_tokenBorrow).balanceOf(_pairPayAddress);
        uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(_pairPayAddress);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amount) / (997 * pairBalanceTokenBorrow)) + 1;

        // get the orignal tokens the user requested
        address tokenBorrowed = _isBorrowingEth ? ETH : _tokenBorrow;
        address tokenToRepay = _isPayingEth ? ETH : _tokenPay;

        // do whatever the user wants
        executeLiquidation( tokenBorrowed, _amount, tokenToRepay, amountToRepay, _userData );

        // payback loan
        // wrap ETH if necessary
        if ( _isPayingEth ){
            IWETH( kWETH ).deposit{ value: G_CollatAmt }( );
        }
        IERC20( _tokenPay ).transfer( _pairPayAddress, G_CollatAmt + 0 );
        
        return;
    }
    
    // @description This is the code that is executed after `triangularFlashSwap` initiated the flash-borrow
    // @dev When this code executes, this contract will hold the amount of kWETH we need in order to get _amount
    //     _tokenBorrow from the _tokenBorrow/WETH pair.
    function triangularFlashSwapExecute( 
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        address _pairPayAddress,
        bytes memory _triangleData,
        bytes memory _userData
    ) private {
        // decode _triangleData
        ( address _borrowPairAddress, uint256 _amountOfWeth ) = 
            abi.decode( _triangleData, ( address, uint256 ) );

        // Step 3: Using a normal swap, trade that kWETH for _tokenBorrow
        // address token0 = IUniswapV2Pair( _borrowPairAddress ).token0( );
        // address token1 = IUniswapV2Pair( _borrowPairAddress ).token1( );
        
        uint256 amount0Out = _tokenBorrow == 
            IUniswapV2Pair( _borrowPairAddress ).token0( ) ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == 
            IUniswapV2Pair( _borrowPairAddress ).token1( )? _amount : 0;
        
        // send our flash-borrowed WETH to the pair
        IERC20( kWETH ).transfer( _borrowPairAddress, _amountOfWeth );
        IUniswapV2Pair(_borrowPairAddress).swap(amount0Out, amount1Out, address(this), bytes(""));

        // compute the amount of _tokenPay that needs to be repaid
        address payPairAddress = permissionedPairAddress; // gas efficiency
        uint pairBalanceWETH = IERC20( kWETH ).balanceOf(payPairAddress);
        uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(payPairAddress);
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amountOfWeth) / (997 * pairBalanceWETH)) + 1;

        // send our flash-borrowed kWETH to the pair
        IERC20( kWETH ).transfer( _borrowPairAddress, _amountOfWeth );
        //  PERFORM THE SWAP. This will call the function uniswapV2Call.
        IUniswapV2Pair( _borrowPairAddress ).swap( amount0Out, amount1Out, address( this ), bytes( "" ) );

        // Step 4: Perform the liquidation
        executeLiquidation( _tokenBorrow, _amount, _tokenPay, amountToRepay, _userData );

        // Step 5: Pay back the flash-borrow to the _tokenPay/WETH pool
        IERC20( _tokenPay ).transfer( _pairPayAddress, amountToRepay );
        
        return;
    }

    // @description This is where the unhealthy CompFi account is liquidated
    // @dev When this function executes, this contract will hold _amount of _tokenBorrow ( LqdtToken ).
    // @dev It is important that, by the end of the execution of this function, this contract holds the necessary
    //     amount of the original _tokenPay ( CollateralToken ) needed to pay back the flash-loan.
    // @dev Paying back the flash-loan happens automatically by the calling function -- do not pay back the loan in this function
    // @dev If you entered `0x0` for _tokenPay when you called `flashSwap`, then make sure this contract holds _amount ETH before this
    //     finishes executing
    // @dev User will override this function on the inheriting contract
    //
    // function executeLiquidation( address _tokenBorrow, uint256 _amount, address _tokenPay, uint256 _amountToRepay, 
    //    bytes memory _params ) internal{
    function executeLiquidation( 
        address _LqdtTokenUnderlying, 
        uint256 _LqdtAmount,
        address _CollateralUnderlying,
        uint _amountToRepay,
        bytes memory _params ) internal{

		IComptroller ctroll = IComptroller( kUnitroller );
        address LqdtAccount;
        address LqdtToken;
        address CollateralToken;
        uint256 iGas = 0;
        
        ( LqdtAccount, LqdtToken, CollateralToken, iGas ) = 
            abi.decode( _params, ( address, address, address, uint256 ) );
        
        address LqdtTokenUnderlying = address( _LqdtTokenUnderlying );
        // if CompFi lqdt is cETH, convert WETH to ETH first, then mint cETH.
        if ( LqdtToken == kCETH ){
            // unwrap WETH
            IWETH( kWETH ).withdraw( _LqdtAmount ); // wei units of ETH?
            LqdtTokenUnderlying = kETH; 
        }
        
        if ( LqdtToken == CollateralToken ){
            cTokens1[0] = LqdtToken;
            ctroll.enterMarkets( cTokens1 );
        } else {
            cTokens[0] = LqdtToken;
            cTokens[1] = CollateralToken;
            ctroll.enterMarkets( cTokens );
        }
        
        // convert the _LqdtTokenUnderlying to a CompFi LqdtToken
        if ( LqdtTokenUnderlying == kETH ){
            // D:\CRYPTO\Liquidation\Compound.Finance\Contracts\examples\
            //  compound-supply-examples-master\solidity-examples\MyContracts.sol
            // function supplyEthToCompound( )
            
    		CEther cToken = CEther( LqdtToken );

            // Convert ETH to cETH needed to liquidate.
            // cEth minted will be ETH supplied/Exchange rate
            cToken.deposit{ value: _LqdtAmount }( );

            // Amount is in units wei, 18 decimals, of underlying asset, not the tokens
            cToken.liquidateBorrow{value: _LqdtAmount, gas: iGas }( LqdtAccount, CollateralToken );
        
        } else {
            IERC20 cLqdtTokenUnderlying = IERC20 ( LqdtTokenUnderlying );

            cLqdtTokenUnderlying.approve( LqdtToken, 0 );  // remove any prior
            cLqdtTokenUnderlying.approve( LqdtToken, _LqdtAmount );  // approve to mint
            
            IERC20 cLqdtToken = IERC20( LqdtToken );
            cLqdtToken.mint( _LqdtAmount ); // Converts Underlying to CompFi cToken

    	    cLqdtToken.liquidateBorrow( LqdtAccount, _LqdtAmount, CollateralToken );
        }
        if ( LqdtToken != CollateralToken ){
            ctroll.exitMarket( LqdtToken );
        }
//        emit Liquidated( LqdtAccount, LqdtToken, _LqdtAmount, CollateralToken, "Liquidated" );
        
        // Redeem the collateral to repay the flash loan
		// convert the CompFi token to the underlying token
        // https://uniswap.org/docs/v2/smart-contract-integration/using-flash-swaps/
        // compute the amount that needs to be repaid
        // the effective fee on the withdrawn amount is .003 / .997 ≈ 0.3009027%
        if ( CollateralToken == kCETH ){
            
            CEther cEther = CEther( kCETH );
     	    cEther.redeem( cEther.balanceOf( address( this ) ) );
     	    
            // ETH just redeemed needs to be wrapped as WETH to repay the flash loan
            IWETH( kWETH ).deposit{ value: _amountToRepay }( );
            
        } else {

            cCollateralToken = IERC20( CollateralToken );
     	    cCollateralToken.redeem( _amountToRepay );
        }

        ctroll.exitMarket( CollateralToken );
        
        if ( false ){ _CollateralUnderlying = _CollateralUnderlying; }
        
        return;
    }

    /********************************************************************************************/
    /***********************  END OF SWAP EXECUTE FUNCTIONS  ***********************************/
    /********************************************************************************************/
    
    /***************  End of UNISWAP functions  **********************************************************/
    
    
    /*************************************************************************************/
    function fWithdraw( address _token, uint256 _iApprove ) payable public returns( bool ) {
        uint256 tokenBalance = 0;
        
        if ( address( _token ) == kETH ){
            tokenBalance = address( this ).balance;
            if ( tokenBalance > 0 ){
                owner.transfer( tokenBalance );
            }
        } else {

            IERC20 cWithdrawToken = IERC20( _token );
            if ( cWithdrawToken.balanceOf( address( this ) ) > 0 ){
                tokenBalance = cWithdrawToken.balanceOf( address( this ) );
                if ( _iApprove == 1 ) {
                    cWithdrawToken.approve( address( this ), tokenBalance );
                }
                return cWithdrawToken.transfer( owner, tokenBalance );
            }
        }
        return false; // nothing was withdrawn
    }
/*********************************************************************
    function ContractTokenBalance( address _token ) public view returns ( uint256 _amount ){
        uint256 iBalance = 0;
        address inToken = address( _token );
        
        if ( address( inToken ) == kETH ){
            iBalance = address( this ).balance;
        } else {
            IERC20 cToken = IERC20( inToken );
            iBalance = cToken.balanceOf( address( this ) );
        }
        return iBalance;
    }

    function AccountLiquidity( address _account ) public view returns ( uint, uint, uint ){
        
        IComptroller cTroll = IComptroller( kUnitroller );

        return ( cTroll.getAccountLiquidity( address( _account ) ) );
    }
    
    function AccountAssets( address _account ) public view returns ( address[] memory ){
        
        IComptroller cTroll = IComptroller( kUnitroller );

        return ( cTroll.getAssetsIn( address( _account ) ) );
    }

    
    function AccountTokenBalance( address _account, address _token ) public view returns ( uint256 _amount ){
        uint256 iBalance = 0;
        address InAccount = address( _account );
        address inToken = address( _token );
        
        if ( address( inToken ) == kETH ){
            iBalance = InAccount.balance;
        } else {
            IERC20 cToken = IERC20( inToken );
            iBalance = cToken.balanceOf( InAccount );
        }
        return iBalance;
    }

    function RedeemUnderling( address _Token ) public payable returns ( uint256, address ){
        uint256 inBalance = 0;
        uint256 outBalance = 0;
        address inToken = address( _Token );
        address outToken;

        if ( inToken == kCETH ){
            CEther cInToken = CEther( inToken );
            inBalance = cInToken.balanceOf( address( this ) );
            outBalance = cInToken.redeem( inBalance );
            outToken = kETH;
        } else {
            IERC20 cInToken = IERC20( inToken );
            inBalance = cInToken.balanceOf( address( this ) );
            outBalance = cInToken.redeem( inBalance );
            outToken = address( cInToken.underlying( ) );
        }
        return ( outBalance, outToken );
    }
    
    event Borrowed( address _tokenBorrowed, uint256 _tokenBalance,
        uint256 _flashAmount, address _initiator );
    event Liquidated( address _account, address _token, uint256 _amount,
        address _collateralToken, string _name );

    function getReserves(
        address tokenA,
        address tokenB)
        public view returns (uint reserveA, uint reserveB) {
        
        // sort tokens
        (address token0,) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        address calcPair = address( uint160( uint( keccak256( abi.encodePacked(
            hex'ff',
            kUniswapV2Factory,
            keccak256( abi.encodePacked( address( tokenA ), address( tokenB ) ) ),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ) ) ) ) );
            
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair( calcPair ).getReserves();
        
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        
        return (reserveA, reserveB);
    }
    
    function GetPair( address _token0, address _token1) public{
        
        (address token0, address token1 ) = _token0 < _token1 ?
            (_token0, _token1) : (_token1, _token0);
            
        permissionedPairAddress = uniswapV2Factory.getPair( token0, token1 );
        address pairAddress = permissionedPairAddress; // gas efficiency

        token0 = IUniswapV2Pair( pairAddress ).token0( );
        token1 = IUniswapV2Pair( pairAddress ).token1( );
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair( pairAddress ).getReserves();

        emit PairInfo( token0, reserve0, token1, reserve1, pairAddress, "PairInfo" );
        return;
    }
    event PairInfo( address tokenA, uint256 reserveA,
        address tokenB, uint256 reserveB, address pairAddress, string _eventname );
*************************************************************************/    
}