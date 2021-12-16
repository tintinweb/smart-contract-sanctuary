/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;





interface IUniswapRouter {

   function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

        function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts)  ;
        function getAmountsIn(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts)  ;
        function swapTokensForExactTokens(uint256 amountOut , uint256 amountInMax, address[] calldata path , address to , uint256 deadline) external returns(uint256[] memory amounts);
}



interface IUniSwapFactory{

    function getPair(address token0, address token1) external view  returns (address);
}

interface IUniSwapPair {

    function totalSupply()
        external
        view
        returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IOracleHub {

    function showOracleAddress(
        address token
    )
        external
        view
        returns (address);
}


interface IChainlink{

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (int256);
}

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);
}


contract SwapOptimizer {
    IOracleHub public constant ORACLE_HUB =
        IOracleHub(0xe81C9f94C8A9F92150481589E836980146448719);
    address public constant QUICKSWAPFACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    uint256 public constant BABYPRECISION = 10**4;
    uint256 public constant PRECISION = 10**18;
    address[3] public popularTokenArray;
    address public constant QUICKSWAPROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant SUSHISWAPROUTER =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public constant SUSHISWAPFACTORY =
        0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    mapping(uint256 => address[]) path;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

   // uint256[] placeHolderType;

 //   constructor(address[] memory popularTokenPairs) {
  //      for (uint256 i = 0; i < popularTokenPairs.length; i++) {
  //          popularTokenArray[i] = popularTokenPairs[i];
  //      }
 //   }

    function popularTokenFill(address token1, address token2, address token3) external{
        popularTokenArray[0]= token1;
        popularTokenArray[1] = token2;
        popularTokenArray[2] = token3;

    }

    function isStableCoin(address _token) external pure returns (bool) {
        if (_token == USDC || _token == USDT || _token == DAI) {
            return true;
        } else {
            return false;
        }
    }

    function returnPath(
        address _source,
        address _destination,
        uint256 _amount,
        uint256 _slippage
    ) public view returns (address[] memory) {
        address dockSource;
        address dockDestination;

        uint256 currentAmountOutput;
        uint256 safeOutputAmount;
        address pairAddress;

        pairAddress = IUniSwapFactory(QUICKSWAPFACTORY).getPair(
            _destination,
            _source
        );

        if (pairAddress != 0x0000000000000000000000000000000000000000) {
            address[] memory returnArray = new address[](2);
            returnArray[0] = _source;
            returnArray[1] = _destination;
            uint256[] memory output = IUniswapRouter(QUICKSWAPROUTER)
                .getAmountsOut(_amount, returnArray);
            currentAmountOutput = output[output.length - 1];
            safeOutputAmount = calcMaxInOrMinOutPutAmount(
                _amount,
                _source,
                _destination,
                _slippage,
                false
            );
            if (currentAmountOutput >= safeOutputAmount) {
                return returnArray; // evtl dann bei bot nicht address(this) sondern addresse von bot?
            }
        }

        for (uint256 i = 0; i < popularTokenArray.length; i++) {
            pairAddress = IUniSwapFactory(QUICKSWAPFACTORY).getPair(
                popularTokenArray[i],
                _source
            );

            if (pairAddress != 0x0000000000000000000000000000000000000000) {
                dockSource = popularTokenArray[i];
                for (uint256 k = 0; k < popularTokenArray.length; k++) {
                    pairAddress = IUniSwapFactory(QUICKSWAPFACTORY).getPair(
                        popularTokenArray[k],
                        _destination
                    );

                    if (
                        pairAddress !=
                        0x0000000000000000000000000000000000000000
                    ) {
                        dockDestination = popularTokenArray[k];
                        if (dockDestination == dockSource) {
                            address[] memory returnArray = new address[](3);
                            returnArray[0] = _source;
                            returnArray[1] = dockDestination;
                            returnArray[2] = _destination;
                            uint256[] memory output = IUniswapRouter(
                                QUICKSWAPROUTER
                            ).getAmountsOut(_amount, returnArray);
                            currentAmountOutput = output[output.length - 1];
                            safeOutputAmount = calcMaxInOrMinOutPutAmount(
                                _amount,
                                _source,
                                _destination,
                                _slippage,
                                false
                            );
                            if (currentAmountOutput >= safeOutputAmount) {
                                //  IUniswapRouter(QUICKSWAPROUTER).swapExactTokensForTokens(_amount,safeOutputAmount,path[block.timestamp],address(this), block.timestamp);      // evtl dann bei bot nicht address(this) sondern addresse von bot?
                                return returnArray;
                            }

                            // execute Swap with prepared Path
                        } else {
                            address[] memory returnArray = new address[](4);
                            returnArray[0] = _source;
                            returnArray[1] = dockSource;
                            returnArray[2] = dockDestination;
                            returnArray[3] = _destination;
                            uint256[] memory output = IUniswapRouter(
                                QUICKSWAPROUTER
                            ).getAmountsOut(_amount, returnArray);
                            currentAmountOutput = output[output.length - 1];
                            safeOutputAmount = calcMaxInOrMinOutPutAmount(
                                _amount,
                                _source,
                                _destination,
                                _slippage,
                                false
                            );

                            if (currentAmountOutput >= safeOutputAmount) {
                                //  IUniswapRouter(QUICKSWAPROUTER).swapExactTokensForTokens(_amount,safeOutputAmount,path[block.timestamp],address(this), block.timestamp);      // evtl dann bei bot nicht address(this) sondern addresse von bot?
                                return returnArray;
                            }
                            // execute Swap with prepared Path
                        }
                    }
                }
            }
        }
        address[] memory empty;
        return empty;
    }





    function determineSeaSaw(
        address[] memory _collateralTokens,
        address[] memory _debtTokens,
        uint256[] memory _collateralAmounts,
        uint256[] memory _debtAmounts,
        uint256 _slippage
       
    ) external returns (uint256[] memory, bytes[] memory) {

    
        require(
            _collateralTokens.length == _collateralAmounts.length &&
                _debtTokens.length == _debtAmounts.length,
            "tokentypes and lengths must be equal"
        );
        bytes[] memory placeHolderSwap = new bytes[](60);
        uint256[] memory placeHolderType = new uint256[](60);
        uint256 currentAmount;
        
        uint256 safeInPutAmount;
      //  address[] memory relevantPath;
        uint256 i=0;
        uint256 k=0;
        
        while (_debtAmounts[_debtAmounts.length -1] > 0)  {
           
            
            address[] memory relevantPath = new address[](returnPath(
                _collateralTokens[k],
                        _debtTokens[i],
                        _collateralAmounts[i],
                        _slippage
                    ).length);
            relevantPath=returnPath(
                _collateralTokens[k],
                        _debtTokens[i],
                        _collateralAmounts[i],
                        _slippage
                    );

        //    uint256[] memory inputCheck = IUniswapRouter(QUICKSWAPROUTER)
        //        .getAmountsIn(_collateralAmounts[i],relevantPath);
            currentAmount = amountFeedbackInput(relevantPath,_collateralAmounts[i]);
            safeInPutAmount = calcMaxInOrMinOutPutAmount(
                _collateralAmounts[k],
                _collateralTokens[k],
                _debtTokens[i],
                _slippage,
                true
            );
            if (currentAmount > safeInPutAmount) {
                placeHolderSwap[i] = abi.encode(
                    _debtTokens[i],
                    safeInPutAmount,
                    relevantPath,
                    address(this),
                    block.timestamp+3600
                );
                placeHolderType[i] =0 ; // 0 means swapForExact  1, swapExactFor , 2 - stableSwap
                _debtAmounts[i]=0;
                _collateralAmounts[i]=_collateralAmounts[i]-safeInPutAmount;
                i=i+1;
                delete relevantPath;
               

            } else {

         //       uint256[] memory outPutCheck = IUniswapRouter(QUICKSWAPROUTER)
        //        .getAmountsOut(_debtAmounts[i],relevantPath);

              //  currentAmount = amountFeedbackOutput(relevantPath,_debtAmounts[i]); not needed?
                placeHolderType[i] =1;
                safeInPutAmount = calcMaxInOrMinOutPutAmount(
                _debtAmounts[i],
                _collateralTokens[k],
                _debtTokens[i],
                _slippage,
                false
            );
            placeHolderSwap[i] = abi.encode(
                    _collateralAmounts[k],
                    safeInPutAmount,
                    relevantPath,
                    address(this),
                    block.timestamp+3600
                );
                _collateralAmounts[k] =0;
                _debtAmounts[i]= _debtAmounts[i]-safeInPutAmount;
            k=k+1;
            delete relevantPath;
            


            }

        }
        
        uint256[] memory returnArray1 = new uint256[](k+i);
        bytes[] memory returnArray2 = new bytes[](k+i);
        i=0;
       for (i; i < returnArray1.length; i++) {

                returnArray1[i] = placeHolderType[i];
                returnArray2[i] = placeHolderSwap[i];
            }


        return (returnArray1,returnArray2);
    }

 
    function executeSeaSawWithFunctionSignatures(bytes[] memory _signatures , uint256[] memory _swapTypes )external {
        require (_signatures.length == _swapTypes.length,"signatures and swapTypes must have same array length");
        uint256 amountOut;
        uint256 amountInMax;
        address benefactor;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] memory path1;


        for (uint256 x = 0; x < _signatures.length; x++) {



        }

          for (uint256 i = 0; i < _signatures.length; i++) {
              if (_swapTypes[i] == 0){
              (amountOut,amountInMax, path1, benefactor, deadline)=abi.decode(_signatures[i],(uint256,uint256,address[] , address, uint256));
                IUniswapRouter(QUICKSWAPROUTER).swapTokensForExactTokens(amountOut,amountInMax, path1, benefactor, deadline);
                delete path1;
              }
            else{

                if (_swapTypes[i]==1){
                    (amountIn,amountOutMin, path1, benefactor, deadline)=abi.decode(_signatures[i],(uint256,uint256,address[] , address, uint256));
                    IUniswapRouter(QUICKSWAPROUTER).swapExactTokensForTokens(amountIn,amountOutMin, path1, benefactor, deadline);

                    delete path1;
                }else{


                }
            }

    }}


function approveRouters()external{
    IERC20(ETH).approve(QUICKSWAPROUTER,1000000000000000000000000000000000000);
    IERC20(WMATIC).approve(QUICKSWAPROUTER,1000000000000000000000000000000000000);
    IERC20(USDT).approve(QUICKSWAPROUTER,1000000000000000000000000000000000000);
    IERC20(USDC).approve(QUICKSWAPROUTER,1000000000000000000000000000000000000);
    IERC20(WBTC).approve(QUICKSWAPROUTER,1000000000000000000000000000000000000);
    IERC20(DAI).approve(QUICKSWAPROUTER,1000000000000000000000000000000000000);
   
} 
















    function amountFeedbackOutput(address[] memory _path, uint256 _amount)  internal view returns(uint256) {


        
            uint256[] memory inputCheck = IUniswapRouter(QUICKSWAPROUTER)
                .getAmountsOut(_amount,_path);
            uint256[] memory returnArray = new uint256[](inputCheck.length);

            for (uint256 i = 0; i < returnArray.length; i++) {

                returnArray[i] = inputCheck[i];
            }
                return returnArray[0];
    }
  function amountFeedbackInput(address[] memory _path, uint256 _amount) internal view returns(uint256 ) {


        
            uint256[] memory inputCheck = IUniswapRouter(QUICKSWAPROUTER)
                .getAmountsIn(_amount,_path);
            uint256[] memory returnArray = new uint256[](inputCheck.length);

            for (uint256 i = 0; i < returnArray.length; i++) {

                returnArray[i] = inputCheck[i];
            }
                return returnArray[returnArray.length-1];
    }


    function calcMaxInOrMinOutPutAmount(
        uint256 _inputAmount,
        address _from,
        address _destination,
        uint256 _slippage,
        bool _maxIn
    ) internal view returns (uint256) {
        // careful! if u want MaxInput for swapTokensForExactTokens inputAmount is the exactTokenAmount etc. !!!
        uint256 DestinationTokenPrep;
        address oracleFrom = ORACLE_HUB.showOracleAddress(_from);
        address oracleDestination = ORACLE_HUB.showOracleAddress(_destination);

        uint256 diffFrom = 10**(18 - IERC20(_from).decimals());
        uint256 diffTo = 10**(18 - IERC20(_destination).decimals());

        uint256 chainlinkDiffFrom = 10 **
            (18 - IChainlink(oracleFrom).decimals());
        uint256 chainlinkDiffDestination = 10 **
            (18 - IChainlink(oracleDestination).decimals());

        uint256 evaluateFrom = uint256(IChainlink(oracleFrom).latestAnswer()) *
            chainlinkDiffFrom *
            _inputAmount *
            diffFrom;

        if (_maxIn == true) {
            DestinationTokenPrep =
                ((10000 + _slippage) * evaluateFrom) /
                (uint256(IChainlink(oracleDestination).latestAnswer()) *
                    chainlinkDiffDestination);
        } else {
            DestinationTokenPrep =
                ((10000 - _slippage) * evaluateFrom) /
                (uint256(IChainlink(oracleDestination).latestAnswer()) *
                    chainlinkDiffDestination);
        }

        uint256 DestinationAmount = DestinationTokenPrep /
            (BABYPRECISION * diffTo);

        return DestinationAmount;
    }
}