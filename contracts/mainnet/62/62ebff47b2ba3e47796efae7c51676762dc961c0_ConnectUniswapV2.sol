/**
 *Submitted for verification at Etherscan.io on 2020-07-08
*/

pragma solidity ^0.6.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface EventInterface {
    function emitEvent(uint connectorType, uint connectorID, bytes32 eventCode, bytes calldata eventData) external;
}

contract Stores {

    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return memory variable address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
     */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
     */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev emit event on event contract
     */
    function emitEvent(bytes32 eventCode, bytes memory eventData) internal {
        (uint model, uint id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(model, id, eventCode, eventData);
    }

    /**
     * @dev Connector Details.
     */
    function connectorID() public pure returns(uint model, uint id) {
        (model, id) = (1, 30);
    }

}

contract DSMath {
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }


    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract UniswapHelpers is Stores, DSMath {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return uniswap v2 router02 Address
     */
    function getUniswapAddr() internal pure returns (address) {
        return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBalace(address token) internal view returns (uint256 amt) {
        amt = token == getEthAddr() ? address(this).balance : TokenInterface(token).balanceOf(address(this));
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function convertEthToWeth(TokenInterface token, uint amount) internal {
        if(address(token) == getAddressWETH()) token.deposit.value(amount)();
    }

    function convertWethToEth(TokenInterface token, uint amount) internal {
       if(address(token) == getAddressWETH()) {
            token.approve(getAddressWETH(), amount);
            token.withdraw(amount);
        }
    }

    function getExpectedBuyAmt(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        uint[] memory amts = router.getAmountsIn(
            buyAmt,
            paths
        );
        sellAmt = amts[0];
    }

    function checkPair(
        IUniswapV2Router02 router,
        address[] memory paths
    ) internal view {
        address pair = IUniswapV2Factory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(
        address buyAddr,
        address sellAddr
    ) internal pure returns(address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }
}

contract LiquidityHelpers is UniswapHelpers {

    function getMinAmount(
        TokenInterface token,
        uint amt,
        uint slippage
    ) internal view returns(uint minAmt) {
        uint _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint _amt,
        uint unitAmt,
        uint slippage
    ) internal returns (uint _amtA, uint _amtB, uint _liquidity) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);

        _amtA = _amt == uint(-1) ? getTokenBalace(tokenA) : _amt;
        _amtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA)));

        convertEthToWeth(_tokenA, _amtA);
        convertEthToWeth(_tokenB, _amtB);
        _tokenA.approve(address(router), _amtA);
        _tokenB.approve(address(router), _amtB);

       uint minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint minAmtB = getMinAmount(_tokenB, _amtB, slippage);
       (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            now + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint _amt,
        uint unitAmtA,
        uint unitAmtB
    ) internal returns (uint _amtA, uint _amtB, uint _uniAmt) {
        IUniswapV2Router02 router;
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (router, _tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(
            tokenA,
            tokenB,
            _amt
        );
        {
        uint minAmtA = convert18ToDec(_tokenA.decimals(), wmul(unitAmtA, _uniAmt));
        uint minAmtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmtB, _uniAmt));
        (_amtA, _amtB) = router.removeLiquidity(
            address(_tokenA),
            address(_tokenB),
            _uniAmt,
            minAmtA,
            minAmtB,
            address(this),
            now + 1
        );
        }
        convertWethToEth(_tokenA, _amtA);
        convertWethToEth(_tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint _amt
    ) internal returns (IUniswapV2Router02 router, TokenInterface _tokenA, TokenInterface _tokenB, uint _uniAmt) {
        router = IUniswapV2Router02(getUniswapAddr());
        (_tokenA, _tokenB) = changeEthAddress(tokenA, tokenB);
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface uniToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == uint(-1) ? uniToken.balanceOf(address(this)) : _amt;
        uniToken.approve(address(router), _uniAmt);
    }
}

contract UniswapLiquidity is LiquidityHelpers {
    event LogDepositLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint amtA,
        uint amtB,
        uint uniAmount,
        uint getId,
        uint setId
    );

    event LogWithdrawLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint amountA,
        uint amountB,
        uint uniAmount,
        uint getId,
        uint[] setId
    );

    function emitDeposit(
        address tokenA,
        address tokenB,
        uint _amtA,
        uint _amtB,
        uint _uniAmt,
        uint getId,
        uint setId
    ) internal {
        emit LogDepositLiquidity(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setId
        );

        bytes32 _eventCode = keccak256("LogDepositLiquidity(address,address,uint256,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setId
        );
        emitEvent(_eventCode, _eventParam);
    }

    function emitWithdraw(
        address tokenA,
        address tokenB,
        uint _amtA,
        uint _amtB,
        uint _uniAmt,
        uint getId,
        uint[] memory setIds
    ) internal {
        emit LogWithdrawLiquidity(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setIds
        );
        bytes32 _eventCode = keccak256("LogWithdrawLiquidity(address,address,uint256,uint256,uint256,uint256,uint256[])");
        bytes memory _eventParam = abi.encode(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setIds
        );
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Deposit Liquidity.
     * @param tokenA tokenA address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB tokenB address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amtA tokenA amount.
     * @param unitAmt unit amount of amtB/amtA with slippage.
     * @param slippage slippage amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        address tokenA,
        address tokenB,
        uint amtA,
        uint unitAmt,
        uint slippage,
        uint getId,
        uint setId
    ) external payable {
        uint _amt = getUint(getId, amtA);

        (uint _amtA, uint _amtB, uint _uniAmt) = _addLiquidity(
                                            tokenA,
                                            tokenB,
                                            _amt,
                                            unitAmt,
                                            slippage
                                            );
        setUint(setId, _uniAmt);
        emitDeposit(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setId);
    }

    /**
     * @dev Withdraw Liquidity.
     * @param tokenA tokenA address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB tokenB address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param uinAmt uni token amount.
     * @param unitAmtA unit amount of amtA/uinAmt with slippage.
     * @param unitAmtB unit amount of amtB/uinAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setIds Set token amounts at this IDs in `InstaMemory` Contract.
    */
    function withdraw(
        address tokenA,
        address tokenB,
        uint uinAmt,
        uint unitAmtA,
        uint unitAmtB,
        uint getId,
        uint[] calldata setIds
    ) external payable {
        uint _amt = getUint(getId, uinAmt);

        (uint _amtA, uint _amtB, uint _uniAmt) = _removeLiquidity(
            tokenA,
            tokenB,
            _amt,
            unitAmtA,
            unitAmtB
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);
        emitWithdraw(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setIds);
    }
}

contract UniswapResolver is UniswapLiquidity {
    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    /**
     * @dev Buy ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt buying token amount.
     * @param unitAmt unit amount of sellAmt/buyAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function buy(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt)));

        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPair(router, paths);
        uint _expectedAmt = getExpectedSellAmt(router, paths, _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _expectedAmt);
        _sellAddr.approve(address(router), _expectedAmt);

        uint _sellAmt = router.swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 1
        )[0];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        emit LogBuy(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogBuy(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Sell ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == getEthAddr() ? address(this).balance : _sellAddr.balanceOf(address(this));
        }

        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt)));

        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPair(router, paths);
        uint _expectedAmt = getExpectedBuyAmt(router, paths, _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _sellAmt);
        _sellAddr.approve(address(router), _sellAmt);

        uint _buyAmt = router.swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 1
        )[1];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}


contract ConnectUniswapV2 is UniswapResolver {
    string public name = "UniswapV2-v1";
}