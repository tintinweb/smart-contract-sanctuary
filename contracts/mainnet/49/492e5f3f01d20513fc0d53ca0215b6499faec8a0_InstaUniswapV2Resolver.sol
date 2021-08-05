/**
 *Submitted for verification at Etherscan.io on 2020-07-09
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev get Ethereum address
     */
    function getEthAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

contract UniswapHelpers is Helpers {
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

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function getExpectedBuyAmt(
        address buyAddr,
        address sellAddr,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        address buyAddr,
        address sellAddr,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint[] memory amts = router.getAmountsIn(
            buyAmt,
            paths
        );
        sellAmt = amts[0];
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint expectedAmt,
        TokenInterface sellAddr,
        uint sellAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _sellAmt = convertTo18((sellAddr).decimals(), sellAmt);
        uint _buyAmt = convertTo18(buyAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getSellUnitAmt(
        TokenInterface sellAddr,
        uint expectedAmt,
        TokenInterface buyAddr,
        uint buyAmt,
        uint slippage
    ) internal view returns (uint unitAmt) {
        uint _buyAmt = convertTo18(buyAddr.decimals(), buyAmt);
        uint _sellAmt = convertTo18(sellAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_sellAmt, _buyAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }

    function _getWithdrawUnitAmts(
        TokenInterface tokenA,
        TokenInterface tokenB,
        uint amtA,
        uint amtB,
        uint uniAmt,
        uint slippage
    ) internal view returns (uint unitAmtA, uint unitAmtB) {
        uint _amtA = convertTo18(tokenA.decimals(), amtA);
        uint _amtB = convertTo18(tokenB.decimals(), amtB);
        unitAmtA = wdiv(_amtA, uniAmt);
        unitAmtA = wmul(unitAmtA, sub(WAD, slippage));
        unitAmtB = wdiv(_amtB, uniAmt);
        unitAmtB = wmul(unitAmtB, sub(WAD, slippage));
    }

    function _getWithdrawAmts(
        TokenInterface _tokenA,
        TokenInterface _tokenB,
        uint uniAmt
    ) internal view returns (uint amtA, uint amtB)
    {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");
        TokenInterface uniToken = TokenInterface(exchangeAddr);
        uint share = wdiv(uniAmt, uniToken.totalSupply());
        amtA = wmul(_tokenA.balanceOf(exchangeAddr), share);
        amtB = wmul(_tokenB.balanceOf(exchangeAddr), share);
    }
}


contract Resolver is UniswapHelpers {

    function getBuyAmount(address buyAddr, address sellAddr, uint sellAmt, uint slippage)
    public view returns (uint buyAmt, uint unitAmt)
    {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        buyAmt = getExpectedBuyAmt(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(address buyAddr, address sellAddr, uint buyAmt, uint slippage)
    public view returns (uint sellAmt, uint unitAmt)
    {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        sellAmt = getExpectedSellAmt(address(_buyAddr), address(_sellAddr), buyAmt);
        unitAmt = getSellUnitAmt(_sellAddr, sellAmt, _buyAddr, buyAmt, slippage);
    }

    function getDepositAmount(
        address tokenA,
        address tokenB,
        uint amtA
    ) public view returns (uint amtB, uint unitAmt)
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");
        uint _amtA18 = convertTo18(_tokenA.decimals(), _tokenA.balanceOf(exchangeAddr));
        uint _amtB18 = convertTo18(_tokenB.decimals(), _tokenB.balanceOf(exchangeAddr));
        unitAmt = wdiv(_amtB18, _amtA18);
        amtB = wmul(unitAmt, convertTo18(_tokenA.decimals(), amtA));
        amtB = convert18ToDec(_tokenB.decimals(), amtB);
    }

    function getDepositAmountNewPool(
        address tokenA,
        address tokenB,
        uint amtA,
        uint amtB
    ) public view returns (uint unitAmt)
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr == address(0), "pair-found.");
        uint _amtA18 = convertTo18(_tokenA.decimals(), amtA);
        uint _amtB18 = convertTo18(_tokenB.decimals(), amtB);
        unitAmt = wdiv(_amtB18, _amtA18);
    }

    function getWithdrawAmounts(
        address tokenA,
        address tokenB,
        uint uniAmt,
        uint slippage
    ) public view returns (uint amtA, uint amtB, uint unitAmtA, uint unitAmtB)
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        (amtA, amtB) = _getWithdrawAmts(
            _tokenA,
            _tokenB,
            uniAmt
        );
        (unitAmtA, unitAmtB) = _getWithdrawUnitAmts(
            _tokenA,
            _tokenB,
            amtA,
            amtB,
            uniAmt,
            slippage
        );
    }

    struct TokenPair {
        address tokenA;
        address tokenB;
    }

    struct PoolData {
        uint tokenAShareAmt;
        uint tokenBShareAmt;
        uint uniAmt;
        uint totalSupply;
    }

    function getPosition(
        address owner,
        TokenPair[] memory tokenPairs
    ) public view returns (PoolData[] memory)
    {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        uint _len = tokenPairs.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint i = 0; i < _len; i++) {
            (TokenInterface tokenA, TokenInterface tokenB) = changeEthAddress(tokenPairs[i].tokenA, tokenPairs[i].tokenB);
            address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(
                address(tokenA),
                address(tokenB)
            );
            if (exchangeAddr != address(0)) {
                TokenInterface uniToken = TokenInterface(exchangeAddr);
                uint uniAmt = uniToken.balanceOf(owner);
                uint totalSupply = uniToken.totalSupply();
                uint share = wdiv(uniAmt, totalSupply);
                uint amtA = wmul(tokenA.balanceOf(exchangeAddr), share);
                uint amtB = wmul(tokenB.balanceOf(exchangeAddr), share);
                poolData[i] = PoolData(
                    amtA,
                    amtB,
                    uniAmt,
                    totalSupply
                );
            }
        }
        return poolData;
    }
}

contract InstaUniswapV2Resolver is Resolver {
    string public constant name = "UniswapV2-Resolver-v1";
}