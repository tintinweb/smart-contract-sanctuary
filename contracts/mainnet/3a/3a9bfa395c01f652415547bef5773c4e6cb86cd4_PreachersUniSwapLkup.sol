// SPDX-License-Identifier: agpl-3.0
// PreachersUniSwapLkup v1.0.10
pragma solidity ^0.8.6;

import { IERC20, IUniswapV2Router02, IUniswapV2Factory,
    IUniswapV2Pair, IWETH } from "Interfaces.sol";

// https://uniswap.org/docs/v2/smart-contracts/router02/
// Same address on Mainnet and Kovan
address constant UNISWAP_ROUTER_ADDRESS = address( 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );
address constant kUniswapV2Factory = address( 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f );

address constant kETH = address( 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE );
address constant ETH = address( 0 );    // preferred by UniSwap

// address constant kWETH = address( 0xd0A1E359811322d97991E03f863a0C30C2cF029C ); // Kovan
address constant kWETH = address( 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ); // Mainnet


contract PreachersUniSwapLkup {

    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory( kUniswapV2Factory ); // same for all networks


    function GetTriPair( address _tokenBorrow, address _tokenPay ) public {
        
        address borrowPairAddress = GetUniPairAddress( address( _tokenBorrow ), kWETH );
        address payPairAddress = GetUniPairAddress( address( _tokenPay ), kWETH );
        
        emit PairAddr( borrowPairAddress, payPairAddress );

        return;
    }
    
    function CreateTriPair( address _tokenBorrow, address _tokenPay )
        public {
            
        // Does _tokenBorrow => kWETH pair exist?
        address TokenBorrow = address( _tokenBorrow );
        address TokenPay = address( _tokenPay );
        
        address borrowPairAddress = uniswapV2Factory.getPair( TokenBorrow, kWETH );
        if ( borrowPairAddress == address( 0 ) ){
            borrowPairAddress = uniswapV2Factory.createPair( TokenBorrow, kWETH );
        }
        
        address payPairAddress = uniswapV2Factory.getPair( TokenPay, kWETH );
        if ( payPairAddress == address( 0 ) ){
            payPairAddress = uniswapV2Factory.createPair( TokenPay, kWETH );
        }
        
        emit PairAddr( borrowPairAddress, payPairAddress );
        return;
        
    }
    
    function GetUniPairAddress( address token0, address token1 ) public pure returns( address _pair ){
        
        address PairAddress = address( uint160( uint( keccak256( abi.encodePacked(
            hex'ff',
            kUniswapV2Factory,
            keccak256( abi.encodePacked( address( token0 ), address( token1 ) ) ),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ) ) ) ) );
        return PairAddress;
    }
    
    function GetTriPairSupply( address _tokenBorrow, address _tokenPay ) public {
        
        address TokenBorrow = address( _tokenBorrow );
        address TokenPay = address( _tokenPay );
        
        uint256 Supply1 = 0;
        uint256 Supply2 = 0;

        address borrowPairAddress = GetUniPairAddress( TokenBorrow, kWETH );
        if ( borrowPairAddress != address( 0 )){
            IUniswapV2Pair Pair1 = IUniswapV2Pair( borrowPairAddress );

            Supply1 = Pair1.totalSupply();
        } else {
            Supply1 = 99;
        }
        
        address payPairAddress = GetUniPairAddress( TokenPay, kWETH );
        if ( payPairAddress != address( 0 )){
            IUniswapV2Pair Pair2 = IUniswapV2Pair( payPairAddress );

            Supply2 = Pair2.totalSupply();
        } else {
            Supply2 = 99;
        }
        emit Pair( Supply1, Supply2 );
        return;
    }
    
    function GetTriPairBalance( address _tokenBorrow, address _tokenPay ) public
        returns ( uint256 _Balance1, uint256 _Balance2 ){
        
        address TokenBorrow = address( _tokenBorrow );
        address TokenPay = address( _tokenPay );

        uint256 Balance1 = 0;
        uint256 Balance2 = 0;
        
        address borrowPairAddress = GetUniPairAddress( TokenBorrow, kWETH );
        if ( borrowPairAddress != address( 0 )){
            Balance1 = IERC20( TokenBorrow ).balanceOf( borrowPairAddress );
        } else {
            Balance1 = 99;
        }
        
        address payPairAddress = GetUniPairAddress( TokenPay, kWETH );
        if ( payPairAddress != address( 0 )){
            Balance2 = IERC20( TokenPay ).balanceOf( payPairAddress );
        } else {
            Balance2 = 99;
        }
        emit Pair( Balance1, Balance2 );
        return ( Balance1, Balance2 );
    
    }
    event Pair( uint256 amount1, uint256 _amount2 );
    event PairAddr( address Pair1, address Pair2 );
}