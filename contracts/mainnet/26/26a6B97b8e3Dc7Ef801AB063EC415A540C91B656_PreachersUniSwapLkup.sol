// SPDX-License-Identifier: agpl-3.0
// PreachersUniSwapLkup v1.0.13
// Mainnet 0x26a6B97b8e3Dc7Ef801AB063EC415A540C91B656
// Kovan 7446 bytes  0x41b120BA589947E364f5123b7BF2dAcDf4E3f61E
pragma solidity ^0.8.6;

import {IComptroller, IUniswapV2Factory, IUniswapV2Pair, IERC20} from "LkupInterfaces.sol";

// https://uniswap.org/docs/v2/smart-contracts/router02/
// Same address on Mainnet and Kovan
address constant UNISWAP_ROUTER_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
address constant kUniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
                                            
//address constant kETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
address constant ETH = address(0);    // preferred by UniSwap

//address constant kWETH = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);           // Kovan
//address constant kUnitroller = address( 0x5eAe89DC1C671724A672ff0630122ee834098657 );   // Kovan

address constant kUnitroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);   // Mainnet
address constant kWETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);         // Mainnet


contract PreachersUniSwapLkup {

    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory(kUniswapV2Factory); // same for all networks

    function GetPair(address _tokenA, address _tokenB) public view returns(string memory sResp){
        
        (address token0, address token1) = _tokenA < _tokenB ?
            (_tokenA, _tokenB) : (_tokenB, _tokenA);
            
        address pairAddress = 
            IUniswapV2Factory(kUniswapV2Factory).getPair(token0, token1);

        uint256 token0Balance = 0;
        uint256 token1Balance = 0;
        
        if (pairAddress != address(0)){
            token0Balance = IERC20(token0).balanceOf(pairAddress);
            token1Balance = IERC20(token1).balanceOf(pairAddress);
        }
        
        // Pairaddress: xxx, tokenA balance: xxx, tokenB balance: xxx
        string memory sResp1 = joinStr(joinStr("Pair address: ", address2str(pairAddress)), ", Token A: ");
        
        string memory sResp2 = joinStr(joinStr(address2str(_tokenA), " : "),
            uint2str(_tokenA == token0 ? token0Balance : token1Balance));
            
        string memory sResp3 = joinStr(joinStr(joinStr(", Token B: ", address2str(_tokenB)), " : "),
            uint2str(_tokenB == token0 ? token0Balance : token1Balance));
            
        sResp = joinStr(joinStr(sResp1, sResp2), sResp3);
	}

    function GetTriPair(address _tokenBorrow, address _tokenPay) public pure returns(string memory sResp) {
        
        (address token0, address token1) = _tokenBorrow < kWETH ?
            (_tokenBorrow, kWETH) : (kWETH, _tokenBorrow);
        address borrowPairAddress = GetUniPairAddress(token0, token1);
        
        
        (token0, token1) = _tokenPay < kWETH ?
            (_tokenPay, kWETH) : (kWETH, _tokenPay);
        address payPairAddress = GetUniPairAddress(token0, token1);
        
        sResp = joinStr("Borrow: ",joinStr(joinStr(address2str(borrowPairAddress), ", Pay: "),
            address2str(payPairAddress)));
    }

    function CreateTriPair(address tokenA, address tokenB)
        public  returns(string memory sResp){
            
        // Does _tokenA => kWETH pair exist?
        (address token0, address token1) = tokenA < kWETH ?
            (tokenA, kWETH) : (kWETH, tokenA);
        
        address PairAddressA = uniswapV2Factory.getPair(token0, token1);
        if (PairAddressA == address(0)){
            PairAddressA = uniswapV2Factory.createPair(token0, token1);
        }
        
        (token0, token1) = tokenB < kWETH ?
            (tokenB, kWETH) : (kWETH, tokenB);
        
        address PairAddressB = uniswapV2Factory.getPair(token0, token1);
        if (PairAddressB == address(0)){
            PairAddressB = uniswapV2Factory.createPair(token0, token1);
        }
        
        // emit PairAddr(borrowPairAddress, payPairAddress);
        sResp = joinStr(joinStr(joinStr("PairA: ", address2str(PairAddressA)), ", PairB: "),
            address2str(PairAddressB));
        
    }
    
    function getReserves(address tokenA, address tokenB) external view 
        returns(string memory sResp){
            
        // return "tokenA: reservesA, tokenB: reservesB"
        if (tokenA == kWETH || tokenB == kWETH){
            (address token0, address token1) = tokenA < tokenB ?
                (tokenA, tokenB) : (tokenB, tokenA);
            
            (uint256 reserves0, uint reserves1) =
                getReserves(kUniswapV2Factory, token0, token1);

            sResp = joinStr("Token A - ",joinStr(joinStr(joinStr(address2str(tokenA), " reserves: "),
                uint2str(token0 == tokenA ? reserves0 : reserves1)), ", Token B - "));
            sResp = joinStr(sResp, joinStr(joinStr(address2str(tokenB), " reserves: "),
                uint2str(token0 == tokenB ? reserves0 : reserves1)));
            
        } else {

            (address token0, address token1) = tokenA < kWETH ?
                (tokenA, kWETH) : (kWETH, tokenA);
            
            (uint256 reserves0, uint reserves1) =
                getReserves(kUniswapV2Factory, token0, token1);

            sResp = joinStr("Token A - ",joinStr(joinStr(joinStr(address2str(tokenA), " reserves: "),
                uint2str(token0 == tokenA ? reserves0 : reserves1)), ", Token B - "));

            (token0, token1) = tokenB < kWETH ?
                (tokenB, kWETH) : (kWETH, tokenB);
            
            (reserves0, reserves1) =
                getReserves(kUniswapV2Factory, token0, token1);

            sResp = joinStr(sResp, joinStr(joinStr(address2str(tokenB), " reserves: "),
                uint2str(token0 == tokenA ? reserves0 : reserves1)));
        }
    }
    
    function GetUniPairAddress(address token0, address token1) public pure returns(address _pair){
        
        address PairAddress = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            kUniswapV2Factory,
            keccak256(abi.encodePacked(address(token0), address(token1))),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
         )))));
        return PairAddress;
    }
    
    function GetTriPairSupply(address _token1, address _token2)
        public view returns(string memory sResp){
        
        uint256 Supply1 = 0;
        uint256 Supply2 = 0;

        (address token0, address token1) = _token1 < kWETH ?
            (_token1, kWETH) : (kWETH, _token1);
        address borrowPairAddress = GetUniPairAddress(token0, token1);
        if (borrowPairAddress != address(0)){
            IUniswapV2Pair Pair1 = IUniswapV2Pair(borrowPairAddress);

            Supply1 = Pair1.totalSupply();
        } else {
            Supply1 = 99;
        }
        
        (token0, token1) = _token2 < kWETH ?
            (_token2, kWETH) : (kWETH, _token2);
        address payPairAddress = GetUniPairAddress(token0, token1);
        if (payPairAddress != address(0)){
            IUniswapV2Pair Pair2 = IUniswapV2Pair(payPairAddress);

            Supply2 = Pair2.totalSupply();
        } else {
            Supply2 = 99;
        }
        sResp = joinStr(joinStr("Supply1 ", uint2str(Supply1)),joinStr(", Supply2 ", uint2str(Supply2)));
    }
    
    function GetTriPairBalance(address _token1, address _token2) public view
        returns (string memory sResp){
        
        uint256 Balance1 = 0;
        uint256 Balance2 = 0;
        
        (address token0, address token1) = _token1 < kWETH ?
            (_token1, kWETH) : (kWETH, _token1);
        address borrowPairAddress = GetUniPairAddress(token0, token1);
        if (borrowPairAddress == address(0)){
            Balance1 = 99;
        } else {
            Balance1 = IERC20(_token1).balanceOf(borrowPairAddress);
        }
        
        (token0, token1) = _token2 < kWETH ?
            (_token2, kWETH) : (kWETH, _token2);
        address payPairAddress = GetUniPairAddress(token0, token1);
        if (payPairAddress == address(0)){
            Balance2 = 99;
        } else {
            Balance2 = IERC20(_token2).balanceOf(payPairAddress);
        }

        sResp = joinStr(joinStr(joinStr("Balance1: ",uint2str(Balance1)), ", Balance2: "),
            uint2str(Balance2));
    }
    
    function AccountLiquidity(address _account) public view returns (string memory sResp){

        IComptroller cTroll = IComptroller(kUnitroller);
        
        // possible error code (semi-opaque),
        //        account liquidity in excess of collateral requirements,
        //        account shortfall below collateral requirements)
        (uint errorCode, uint excess, uint shortfall) = cTroll.getAccountLiquidity(address(_account));
        
        sResp = joinStr(joinStr(joinStr(joinStr(joinStr("Error: ", uint2str(errorCode)), ", Excess: "),
            uint2str(excess)), ", Shortfall: "), uint2str(shortfall));
            
        if (errorCode == 0 && excess == 0 && shortfall > 0){
            sResp = joinStr(sResp, " == LIQUIDATE");
        }

	}

    
    function uint2str(uint256 _i) internal pure returns (string memory str){
        if (_i == 0){
            return "0";
        }
        
        uint256 j = _i;
        uint256 length;
        
        while (j != 0){
            length++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        
        while (j != 0){
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        
        str = string(bstr);
    }
    
    function joinStr(string memory sm0, string memory sm1) 
        internal pure returns (string memory)
    {
        return string(abi.encodePacked(sm0, sm1));
    }
    
    function address2str(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        
        return string(s);
        
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // from UniswapV2Library
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) 
        internal view returns (uint reserveA, uint reserveB) {
            
        address token0 = tokenA < tokenB ? tokenA : tokenB;
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address( uint160( uint( keccak256( abi.encodePacked(
            hex'ff',
            factory,
            keccak256( abi.encodePacked( address( token0 ), address( token1 ) ) ),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ) ) ) ) );
            
        /*******************
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
        *******************/
    }

    /*****************************
     * @notice Checks if the liquidation should be allowed to occur
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
    ******************/
    function isLiquidationAllowed(address lqdtToken, address cTokenCollateral, address account, uint256 lqdtAmount)
    public {
        
        IComptroller cTroll = IComptroller(kUnitroller);

        //uint allowed = cTroll.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
        emit LqdtAllowed(cTroll.liquidateBorrowAllowed(lqdtToken, address(cTokenCollateral),
            address(this), account, lqdtAmount));
    }
    event LqdtAllowed(uint isAllowed);
 

}