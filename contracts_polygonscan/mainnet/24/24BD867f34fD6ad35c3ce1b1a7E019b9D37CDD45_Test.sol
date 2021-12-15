//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PolygonArbitrageBot.sol";
import "./Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Test is Ownable, PolygonArbitrageBot {



    constructor()
    {
        transferOwnership(msg.sender);
    }


    function getBalances() view external returns(string memory)
    {
        string memory result = "Balances\n\n";

        for (uint256 i = 0; i < topLevelTokens.length; i++)
        {
            address fiToken = topLevelTokens[i];
            
            result = string(abi.encodePacked(result, PolygonTokens.tokenNamesM[fiToken], " \t", _uintToString(PolygonTokenTools.getBalance(fiToken)), "\n"));
        }

        return result;
    }

    function smashIt(uint256 _amount) external
    {
        _polygonArbitrageBotSmashIt(_amount);
    }

    function displayValidOptions(uint256 _amount) view external returns(string memory)
    {
        string memory result = "Options\n\n";

        PolygonArbitrageOption[] memory options = _polygonArbitrageBotGetValidOptions(_amount);

        for (uint256 i = 0; i < options.length; i++)
        {
            PolygonArbitrageOption memory fiOption = options[i];

            result = string(abi.encodePacked(result, _createOptionString(fiOption)));
        }

        return result;
    }

    function _createOptionString(PolygonArbitrageOption memory option) view internal returns(string memory)
    {
        if (option.isValid == false)
        {
            return "No valid arbitrage trade found.";
        }

        uint256 usdcGainedValue = option.tokenAmountDifference;

        if (option.aToB.tokenIn != PolygonTokens.tokenUSDC)
        {
            usdcGainedValue = _polygonTradingHubGetDefaultDEXTradingAmountOut(option.aToB.tokenIn, PolygonTokens.tokenUSDC, option.tokenAmountDifference);
        }

        string memory zeroString = "";
        uint256 usdcCents = usdcGainedValue % 1000000;

        if (usdcCents == 0)
        {
            zeroString = "000000";
        }
        else if (usdcCents < 10)
        {
            zeroString = "00000";
        }
        else if (usdcCents < 100)
        {
            zeroString = "0000";
        }
        else if (usdcCents < 1000)
        {
            zeroString = "000";
        }
        else if (usdcCents < 10000)
        {
            zeroString = "00";
        }
        else if (usdcCents < 100000)
        {
            zeroString = "0";
        }

        string memory row0 = string(abi.encodePacked("Pair: \t\t\t", PolygonTokens.tokenNamesM[option.aToB.tokenIn], " / ", PolygonTokens.tokenNamesM[option.aToB.tokenOut], "\n"));
        string memory row1 = string(abi.encodePacked("Exchange: \t\t", uniswapV2ExchangesNames[option.aToB.exchange], " / ", uniswapV2ExchangesNames[option.bToA.exchange], "\n"));
        string memory row2 = string(abi.encodePacked("Gain percentage: \t", _uintToString(option.tokenAmountDifferencePercentage1000 / 1000), ".", _uintToString(option.tokenAmountDifferencePercentage1000 % 1000), " %\n"));
        string memory row3 = string(abi.encodePacked("Gain USDC: \t\t", _uintToString(usdcGainedValue / 1000000), ".", zeroString, _uintToString(usdcCents), " $\n\n"));


        return string(abi.encodePacked(row0, row1, row2, row3));
    }






    function renounceOwnership() override public pure
    {

    }

    function withdraw() external onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }

    function transferTokens(address _tokenAddress) external onlyOwner
    {
        // Used for "rescue" tokens
        IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./PolygonTradingHub.sol";
import "./Library.sol";
import "hardhat/console.sol";




contract PolygonArbitrageBot is PolygonTradingHub {


    struct PolygonAbitrageIntent {
        address tokenA;
        address tokenB;
    }

    struct PolygonArbitrageOption {
        PolygonTradeForecast aToB;
        PolygonTradeForecast bToA;
        uint256 tokenAmountDifference;
        uint256 tokenAmountDifferencePercentage1000;
        bool isValid;
    }

    mapping(uint256 => PolygonAbitrageIntent) abitrageIntents;
    uint256 abitrageIntentsLength = 0;

    function quickSort(PolygonArbitrageOption[] memory arr, uint left, uint right) pure internal {
    uint i = left;
    uint j = right;
    if (i == j) return;
    uint pivot = arr[uint(left + (right - left) / 2)].tokenAmountDifferencePercentage1000;
    while (i <= j) {
        while (arr[uint(i)].tokenAmountDifferencePercentage1000 < pivot) i++;
        while (pivot < arr[uint(j)].tokenAmountDifferencePercentage1000) j--;
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(arr, left, j);
    if (i < right)
        quickSort(arr, i, right);
}

    constructor()
    {
        for (uint256 i = 0; i < topLevelTokens.length; i++)
        {
            address fiToken = topLevelTokens[i];

            _polygonArbitrageBotConvertAddTopLevelTradingToken(fiToken);
        }

    }

    function _polygonArbitrageBotConvertAddTopLevelTradingToken(address _token) private
    {
        for (uint256 i = 0; i < PolygonTokens.tokens.length; i++)
        {
            address fiToken = PolygonTokens.tokens[i];

            if (fiToken == _token)
            {
                continue;
            }

            abitrageIntents[abitrageIntentsLength].tokenA = _token;
            abitrageIntents[abitrageIntentsLength].tokenB = fiToken;
            abitrageIntentsLength++;
        }
    }

    function _polygonArbitrageBotSmashIt(uint256 _amount) internal returns(bool)
    {
        PolygonArbitrageOption memory bestOption = _polygonArbitrageBotGetBestOption(_amount);

        return _polygonArbitrageBotPerformSwapIfValuable(bestOption);
    }

    function _polygonArbitrageBotPerformSwapIfValuable(PolygonArbitrageOption memory _option) internal returns(bool)
    {
        if (_option.isValid == false)
        {
            return false;
        }

        uint256 initialBalanceA = PolygonTokenTools.getBalance(_option.aToB.tokenIn);
        uint256 initialBalanceB = PolygonTokenTools.getBalance(_option.bToA.tokenOut);

        _polygonTradingHubSwapToken(_option.aToB.exchange, _option.aToB.tokenIn, _option.aToB.tokenOut, _option.aToB.tokenInAmount);

        uint256 newBalanceB = PolygonTokenTools.getBalance(_option.aToB.tokenOut);

        _polygonTradingHubSwapToken(_option.bToA.exchange, _option.bToA.tokenIn, _option.bToA.tokenOut, newBalanceB - initialBalanceB);

        uint256 newBalanceA = PolygonTokenTools.getBalance(_option.bToA.tokenOut);

        if (newBalanceA < initialBalanceA)
        {
            revert("Arbitrage trade was unsuccessful.");
        }
        
        return true;
    }

    function _polygonArbitrageBotGetBestOption(uint256 _amount) internal view returns(PolygonArbitrageOption memory)
    {
        PolygonArbitrageOption memory bestOption;

        for (uint256 i = 0; i < abitrageIntentsLength; i++)
        {
            PolygonAbitrageIntent memory fiIntent = abitrageIntents[i];

            PolygonArbitrageOption memory fiOption = _polygonArbitrageBotFindOption(fiIntent.tokenA, fiIntent.tokenB, _amount);

            if (fiOption.isValid && fiOption.tokenAmountDifferencePercentage1000 > bestOption.tokenAmountDifferencePercentage1000)
            {
                bestOption = fiOption;
            }
        }

        return bestOption;
    }

    function _polygonArbitrageBotGetValidOptions(uint256 _amount) internal view returns(PolygonArbitrageOption[] memory)
    {
        PolygonArbitrageOption[] memory validOptions = new PolygonArbitrageOption[](1000);
        uint256 arrayCount = 0;

        for (uint256 i = 0; i < abitrageIntentsLength; i++)
        {
            PolygonAbitrageIntent memory fiIntent = abitrageIntents[i];

            PolygonArbitrageOption memory fiOption = _polygonArbitrageBotFindOption(fiIntent.tokenA, fiIntent.tokenB, _amount);

            if (fiOption.isValid)
            {
                validOptions[arrayCount] = fiOption;
                arrayCount++;
            }
        }

        PolygonArbitrageOption[] memory trimmedResult = new PolygonArbitrageOption[](arrayCount);

        for (uint j = 0; j < trimmedResult.length; j++)
        {
            trimmedResult[j] = validOptions[j];
        }

        if (arrayCount > 0)
        {
            quickSort(trimmedResult, uint256(0), uint256(trimmedResult.length - 1));
        }

        return trimmedResult;
    }

    function _polygonArbitrageBotFindOption(address _tokenA, address _tokenB, uint256 _usdcValue) internal view returns(PolygonArbitrageOption memory)
    {
        // console.log("PolygonArbitrageBot - find best option. tokenA: %s, tokenB: %s, usdcValue: %d", PolygonTokens.getTokenName(_tokenA), PolygonTokens.getTokenName(_tokenB), _usdcValue);

        PolygonArbitrageOption memory option;
        uint256 tokenAAmount = _usdcValue;

        if (_tokenA != PolygonTokens.tokenUSDC)
        {
            tokenAAmount = _polygonTradingHubGetDefaultDEXTradingAmountIn(_tokenA, PolygonTokens.tokenUSDC, _usdcValue, true);

            if (tokenAAmount == MAX_INT || tokenAAmount == 0)
            {
                option.isValid = false;

                console.log("PolygonArbitrageBot - ERROR pair: %s/USDC is not available at default DEX.", PolygonTokens.tokenNamesM[_tokenA]);

                return option;
            }
        }

        // console.log("PolygonArbitrageBot - needed tokenA amount: %d", tokenAAmount);

        PolygonTradeForecast memory forecastAToB = _polygonTradingHubGetBestTradeForecast(_tokenA, _tokenB, tokenAAmount);

        if (forecastAToB.tokenOutAmount == 0)
        {
            option.isValid = false;

            return option;
        }

        PolygonTradeForecast memory forecastBToA = _polygonTradingHubGetBestTradeForecast(_tokenB, _tokenA, forecastAToB.tokenOutAmount);

        if (forecastBToA.tokenOutAmount <= forecastAToB.tokenInAmount)
        {
            option.isValid = false;

            return option;
        }

        option.aToB = forecastAToB;
        option.bToA = forecastBToA;
        option.tokenAmountDifference = forecastBToA.tokenOutAmount - forecastAToB.tokenInAmount;
        option.tokenAmountDifferencePercentage1000 = (option.tokenAmountDifference * 1000 * 100) / forecastAToB.tokenInAmount;
        option.isValid = true;

        console.log("PolygonArbitrageBot - pair: %s/%s percentageGain: %d", PolygonTokens.tokenNamesM[forecastAToB.tokenIn], PolygonTokens.tokenNamesM[forecastAToB.tokenOut], option.tokenAmountDifferencePercentage1000);

        return option;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

uint256 constant MAX_INT = type(uint256).max;

enum kNetwork
{
    polygon
}

struct TradingToken {
    IERC20 token;
    address tokenAddress;
    bool spendingIsApproved;
    kNetwork network;
}

function _calculatePercentage1000PriceImpact(uint256 _amountPer100Mille, uint256 _amount) pure returns(uint256)
{
    uint256 amountThatShouldBe = _amountPer100Mille * 100000;

    if (amountThatShouldBe < _amount)
    {
        return 0;
    }

    uint256 tokenDifference = amountThatShouldBe - _amount;

    uint256 result = (tokenDifference * 1000 * 100) / _amount;

    return result;
}

function _calculatePercent(uint amount, uint percentage) pure returns(uint)
{
    // Return 1% of amount
    uint _100 = 100e18;
    uint _1 = 1e18;

    return ((amount * _1 * percentage) / _100);
}

function _createAddressPath(address _addressA, address _addressB) pure returns(address[] memory)
{
    address[] memory path = new address[](2);
    path[0] = _addressA;
    path[1] = _addressB;

    return path;
}

function _uintToString(uint _i) pure returns (string memory)
{
    if (_i == 0)
    {
        return "0";
    }

    uint j = _i;
    uint len;

    while (j != 0)
    {
        len++;
        j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint k = len;

    while (_i != 0)
    {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }

    return string(bstr);
}

library PolygonTokenTools {

    function getBalance(address token) internal view returns(uint256)
    {
        return IERC20(token).balanceOf(address(this));
    }

}

contract LibraryContract {

    struct PolygonTokensStruct {
        address[] tokens;
        mapping(address => string) tokenNamesM;
        address tokenUSDC;
        address tokenWMATIC;
        address tokenWETH;
        address tokenMiMATIC;
        address tokenDAI;
        address tokenUSDT;
    }

    PolygonTokensStruct internal PolygonTokens;

    address[] internal topLevelTokens;

    address uniswapV2DefaultExchange;
    address[] internal uniswapV2Exchanges;
    mapping(address => string) uniswapV2ExchangesNames;

    constructor()
    {
        uniswapV2DefaultExchange = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

        uniswapV2Exchanges.push(uniswapV2DefaultExchange);
        uniswapV2ExchangesNames[uniswapV2DefaultExchange] = "QuickSwap";

        uniswapV2Exchanges.push(0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc);
        uniswapV2ExchangesNames[0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc] = "CafeSwap";

        uniswapV2Exchanges.push(0x5C6EC38fb0e2609672BDf628B1fD605A523E5923);
        uniswapV2ExchangesNames[0x5C6EC38fb0e2609672BDf628B1fD605A523E5923] = "JetSwap";

        uniswapV2Exchanges.push(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        uniswapV2ExchangesNames[0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506] = "SushiSwap";

        uniswapV2Exchanges.push(0xaD340d0CD0B117B0140671E7cB39770e7675C848);
        uniswapV2ExchangesNames[0xaD340d0CD0B117B0140671E7cB39770e7675C848] = "Honey Swap";

        uniswapV2Exchanges.push(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
        uniswapV2ExchangesNames[0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607] = "Ape Swap";

        uniswapV2Exchanges.push(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429);
        uniswapV2ExchangesNames[0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429] = "DFYN";

        uniswapV2Exchanges.push(0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25);
        uniswapV2ExchangesNames[0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25] = "Cometh";

        uniswapV2Exchanges.push(0x94930a328162957FF1dd48900aF67B5439336cBD);
        uniswapV2ExchangesNames[0x94930a328162957FF1dd48900aF67B5439336cBD] = "Polycat";

        


        PolygonTokens.tokenUSDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        PolygonTokens.tokenWMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        PolygonTokens.tokenWETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        PolygonTokens.tokenMiMATIC = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
        PolygonTokens.tokenDAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        PolygonTokens.tokenUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

        topLevelTokens.push(PolygonTokens.tokenUSDC);
        topLevelTokens.push(PolygonTokens.tokenWMATIC);
        topLevelTokens.push(PolygonTokens.tokenWETH);
        topLevelTokens.push(PolygonTokens.tokenMiMATIC);
        topLevelTokens.push(PolygonTokens.tokenDAI);
        topLevelTokens.push(PolygonTokens.tokenUSDT);


        PolygonTokens.tokens.push(PolygonTokens.tokenUSDC);
        PolygonTokens.tokenNamesM[PolygonTokens.tokenUSDC] = "USDC";

        PolygonTokens.tokens.push(PolygonTokens.tokenWMATIC);
        PolygonTokens.tokenNamesM[PolygonTokens.tokenWMATIC] = "WMATIC";
        
        PolygonTokens.tokens.push(PolygonTokens.tokenWETH);
        PolygonTokens.tokenNamesM[PolygonTokens.tokenWETH] = "WETH";
        
        PolygonTokens.tokens.push(PolygonTokens.tokenMiMATIC);
        PolygonTokens.tokenNamesM[PolygonTokens.tokenMiMATIC] = "miMATIC";
        
        PolygonTokens.tokens.push(PolygonTokens.tokenDAI);
        PolygonTokens.tokenNamesM[PolygonTokens.tokenDAI] = "DAI";
        
        PolygonTokens.tokens.push(PolygonTokens.tokenUSDT);
        PolygonTokens.tokenNamesM[PolygonTokens.tokenUSDT] = "USDT";
        
        PolygonTokens.tokens.push(0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3);
        PolygonTokens.tokenNamesM[0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3] = "BNB";
        
        PolygonTokens.tokens.push(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6);
        PolygonTokens.tokenNamesM[0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6] = "WBTC";
        
        PolygonTokens.tokens.push(0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7);
        PolygonTokens.tokenNamesM[0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7] = "BUSD";
        
        PolygonTokens.tokens.push(0x692597b009d13C4049a947CAB2239b7d6517875F);
        PolygonTokens.tokenNamesM[0x692597b009d13C4049a947CAB2239b7d6517875F] = "UST";
        
        PolygonTokens.tokens.push(0xAdA58DF0F643D959C2A47c9D4d4c1a4deFe3F11C);
        PolygonTokens.tokenNamesM[0xAdA58DF0F643D959C2A47c9D4d4c1a4deFe3F11C] = "CRO";
        
        PolygonTokens.tokens.push(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);
        PolygonTokens.tokenNamesM[0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39] = "ChainLink";
        
        PolygonTokens.tokens.push(0xb33EaAd8d922B1083446DC23f610c2567fB5180f);
        PolygonTokens.tokenNamesM[0xb33EaAd8d922B1083446DC23f610c2567fB5180f] = "Uniswap";
        
        PolygonTokens.tokens.push(0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683);
        PolygonTokens.tokenNamesM[0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683] = "SAND";
        
        PolygonTokens.tokens.push(0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4);
        PolygonTokens.tokenNamesM[0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4] = "Decentraland";
        
        PolygonTokens.tokens.push(0x23fE1Ee2f536427B7e8aC02FB037A7f867037Fe8);
        PolygonTokens.tokenNamesM[0x23fE1Ee2f536427B7e8aC02FB037A7f867037Fe8] = "TORN Token";
        
        PolygonTokens.tokens.push(0xe6E320b7bB22018D6CA1F4D8cea1365eF5d25ced);
        PolygonTokens.tokenNamesM[0xe6E320b7bB22018D6CA1F4D8cea1365eF5d25ced] = "Litentry";
        
        PolygonTokens.tokens.push(0x780053837cE2CeEaD2A90D9151aA21FC89eD49c2);
        PolygonTokens.tokenNamesM[0x780053837cE2CeEaD2A90D9151aA21FC89eD49c2] = "Rarible";
        
        PolygonTokens.tokens.push(0x65A05DB8322701724c197AF82C9CaE41195B0aA8);
        PolygonTokens.tokenNamesM[0x65A05DB8322701724c197AF82C9CaE41195B0aA8] = "FOX";
        
        PolygonTokens.tokens.push(0x438B28C5AA5F00a817b7Def7cE2Fb3d5d1970974);
        PolygonTokens.tokenNamesM[0x438B28C5AA5F00a817b7Def7cE2Fb3d5d1970974] = "Bluzelle";
        
        PolygonTokens.tokens.push(0xc6480Da81151B2277761024599E8Db2Ad4C388C8);
        PolygonTokens.tokenNamesM[0xc6480Da81151B2277761024599E8Db2Ad4C388C8] = "Decentral Games Governance";
        
        PolygonTokens.tokens.push(0x1631244689EC1fEcbDD22fb5916E920dFC9b8D30);
        PolygonTokens.tokenNamesM[0x1631244689EC1fEcbDD22fb5916E920dFC9b8D30] = "OVR";
        
        PolygonTokens.tokens.push(0xE3322702BEdaaEd36CdDAb233360B939775ae5f1);
        PolygonTokens.tokenNamesM[0xE3322702BEdaaEd36CdDAb233360B939775ae5f1] = "Tellor Tributes";
        
        PolygonTokens.tokens.push(0x07CC1cC3628Cc1615120DF781eF9fc8EC2feAE09);
        PolygonTokens.tokenNamesM[0x07CC1cC3628Cc1615120DF781eF9fc8EC2feAE09] = "BetProtocolToken";
        
        PolygonTokens.tokens.push(0x0cD022ddE27169b20895e0e2B2B8A33B25e63579);
        PolygonTokens.tokenNamesM[0x0cD022ddE27169b20895e0e2B2B8A33B25e63579] = "EverRise";
        
        PolygonTokens.tokens.push(0xb5106A3277718eCaD2F20aB6b86Ce0Fee7A21F09);
        PolygonTokens.tokenNamesM[0xb5106A3277718eCaD2F20aB6b86Ce0Fee7A21F09] = "pBREW";
        
        PolygonTokens.tokens.push(0x1A1A5D121D5EbEBD0761D95E332E7f57AC4462a9);
        PolygonTokens.tokenNamesM[0x1A1A5D121D5EbEBD0761D95E332E7f57AC4462a9] = "MOCHA";
        
        PolygonTokens.tokens.push(0x845E76A8691423fbc4ECb8Dd77556Cb61c09eE25);
        PolygonTokens.tokenNamesM[0x845E76A8691423fbc4ECb8Dd77556Cb61c09eE25] = "pWINGS";
        
        PolygonTokens.tokens.push(0xE0339c80fFDE91F3e20494Df88d4206D86024cdF);
        PolygonTokens.tokenNamesM[0xE0339c80fFDE91F3e20494Df88d4206D86024cdF] = "Dogelon";
        
        PolygonTokens.tokens.push(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);
        PolygonTokens.tokenNamesM[0x580A84C73811E1839F75d86d75d88cCa0c241fF4] = "Qi Dao";
        
        PolygonTokens.tokens.push(0xB6bcae6468760bc0CDFb9C8ef4Ee75C9dd23e1Ed);
        PolygonTokens.tokenNamesM[0xB6bcae6468760bc0CDFb9C8ef4Ee75C9dd23e1Ed] = "pNetwork";
        
        PolygonTokens.tokens.push(0x4e78011Ce80ee02d2c3e649Fb657E45898257815);
        PolygonTokens.tokenNamesM[0x4e78011Ce80ee02d2c3e649Fb657E45898257815] = "Klima Dao";
        
        PolygonTokens.tokens.push(0x1646C835d70F76D9030DF6BaAeec8f65c250353d);
        PolygonTokens.tokenNamesM[0x1646C835d70F76D9030DF6BaAeec8f65c250353d] = "Hedera";
        
        PolygonTokens.tokens.push(0xC250e9987A032ACAC293d838726C511E6E1C029d);
        PolygonTokens.tokenNamesM[0xC250e9987A032ACAC293d838726C511E6E1C029d] = "Otter Clam";
        
        PolygonTokens.tokens.push(0x67Ce67ec4fCd4aCa0Fcb738dD080b2a21ff69D75);
        PolygonTokens.tokenNamesM[0x67Ce67ec4fCd4aCa0Fcb738dD080b2a21ff69D75] = "SwissBorg";
        
        PolygonTokens.tokens.push(0x61299774020dA444Af134c82fa83E3810b309991);
        PolygonTokens.tokenNamesM[0x61299774020dA444Af134c82fa83E3810b309991] = "Render Token";
        
        PolygonTokens.tokens.push(0x3066818837c5e6eD6601bd5a91B0762877A6B731);
        PolygonTokens.tokenNamesM[0x3066818837c5e6eD6601bd5a91B0762877A6B731] = "UMA Voting Token v1";
        
        PolygonTokens.tokens.push(0x282d8efCe846A88B159800bd4130ad77443Fa1A1);
        PolygonTokens.tokenNamesM[0x282d8efCe846A88B159800bd4130ad77443Fa1A1] = "Ocean Token";
        
        PolygonTokens.tokens.push(0x6Bf2eb299E51Fc5DF30Dec81D9445dDe70e3F185);
        PolygonTokens.tokenNamesM[0x6Bf2eb299E51Fc5DF30Dec81D9445dDe70e3F185] = "Serum";
        
        PolygonTokens.tokens.push(0xde799636aF0d8D65a17AAa83b66cBBE9B185EB01);
        PolygonTokens.tokenNamesM[0xde799636aF0d8D65a17AAa83b66cBBE9B185EB01] = "INVERSE";
        
        PolygonTokens.tokens.push(0xD1e6354fb05bF72A8909266203dAb80947dcEccF);
        PolygonTokens.tokenNamesM[0xD1e6354fb05bF72A8909266203dAb80947dcEccF] = "Cryption Network Token";
        
        PolygonTokens.tokens.push(0xEde1B77C0Ccc45BFa949636757cd2cA7eF30137F);
        PolygonTokens.tokenNamesM[0xEde1B77C0Ccc45BFa949636757cd2cA7eF30137F] = "Wrapped Filecoin";
        
        PolygonTokens.tokens.push(0x8f18dC399594b451EdA8c5da02d0563c0b2d0f16);
        PolygonTokens.tokenNamesM[0x8f18dC399594b451EdA8c5da02d0563c0b2d0f16] = "moonwolf.io";
        
        PolygonTokens.tokens.push(0x46D502Fac9aEA7c5bC7B13C8Ec9D02378C33D36F);
        PolygonTokens.tokenNamesM[0x46D502Fac9aEA7c5bC7B13C8Ec9D02378C33D36F] = "WolfSafePoorPeople";
        
        PolygonTokens.tokens.push(0xCa4992F01B63C7cEB98505946b79D7D8855449F9);
        PolygonTokens.tokenNamesM[0xCa4992F01B63C7cEB98505946b79D7D8855449F9] = "DESTRUCTION";


        
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Library.sol";
import "./trader/UniSwapV2Trader.sol";

contract PolygonTradingHub is LibraryContract, UniSwapV2Trader {

    struct PolygonTradeForecast {
        address exchange;
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct PolygonTradeForecastABICompatible {
        string exchange;
        string tokenIn;
        string tokenOut;
        string tokenInAmount;
        string tokenOutAmount;
    }

    function _polygonTradingHubConvertForecastToABICompatible(PolygonTradeForecast memory _forecast) internal view returns(PolygonTradeForecastABICompatible memory)
    {
        PolygonTradeForecastABICompatible memory forecast;

        forecast.exchange = uniswapV2ExchangesNames[_forecast.exchange];
        forecast.tokenIn = PolygonTokens.tokenNamesM[_forecast.tokenIn];
        forecast.tokenOut = PolygonTokens.tokenNamesM[_forecast.tokenOut];
        forecast.tokenInAmount = _uintToString(_forecast.tokenInAmount);
        forecast.tokenOutAmount = _uintToString(_forecast.tokenOutAmount);

        return forecast;
    }

    function _polygonTradingHubGetBestTradeForecast(address _tokenIn, address _tokenOut, uint256 _amount) internal view returns(PolygonTradeForecast memory)
    {
        PolygonTradeForecast[] memory forecasts = _polygonTradingHubGetAllForcasts(_tokenIn, _tokenOut, _amount);
        PolygonTradeForecast memory bestForecast;

        bestForecast.tokenOutAmount = 0;

        for (uint256 i = 0; i < forecasts.length; i++)
        {
            PolygonTradeForecast memory fiForecast = forecasts[i];

            if (fiForecast.tokenOutAmount > bestForecast.tokenOutAmount)
            {
                bestForecast = fiForecast;
            }
        }

        return bestForecast;
    }

    function _polygonTradingHubGetAllForcasts(address _tokenIn, address _tokenOut, uint256 _amount) internal view returns(PolygonTradeForecast[] memory)
    {
        PolygonTradeForecast[] memory forecasts = new PolygonTradeForecast[](uniswapV2Exchanges.length);

        for (uint256 i = 0; i < uniswapV2Exchanges.length; i++)
        {
            forecasts[i] = _polygonTradingHubGetForcast(uniswapV2Exchanges[i], _tokenIn, _tokenOut, _amount);
        }

        return forecasts;
    }

    function _polygonTradingHubGetDefaultDEXTradingAmountIn(address _tokenIn, address _tokenOut, uint256 _amount, bool checkMultiplePaths) internal view returns(uint256)
    {
        uint256 amountIn = _uniSwapV2RouterGetAmountIn(uniswapV2DefaultExchange, _tokenIn, _tokenOut, _amount);

        if (checkMultiplePaths == false)
        {
            return amountIn;
        }

        if (amountIn >= 0 && amountIn != MAX_INT)
        {
            return amountIn;
        }

        address[] memory path = new address[](3);
        path[0] = _tokenIn;
        path[1] = PolygonTokens.tokenWMATIC;
        path[2] = _tokenOut;

        amountIn = _uniSwapV2RouterGetAmountInByPath(uniswapV2DefaultExchange, path, _amount);

        if (amountIn >= 0 && amountIn != MAX_INT)
        {
            return amountIn;
        }

        path[1] = PolygonTokens.tokenWETH;

        amountIn = _uniSwapV2RouterGetAmountInByPath(uniswapV2DefaultExchange, path, _amount);

        return amountIn;
    }

    function _polygonTradingHubGetDefaultDEXTradingAmountOut(address _tokenIn, address _tokenOut, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOut(uniswapV2DefaultExchange, _tokenIn, _tokenOut, _amount);
    }

    function _polygonTradingHubSwapToken(address _exchange, address _tokenIn, address _tokenOut, uint256 _amount) internal returns(bool)
    {
        return _uniSwapV2RouterSwapToken(_exchange, _tokenIn, _tokenOut, _amount);
    }

    function _polygonTradingHubGetForcast(address _exchange, address _tokenIn, address _tokenOut, uint256 _amount) internal view returns(PolygonTradeForecast memory)
    {
        PolygonTradeForecast memory forecast;

        forecast.exchange = _exchange;
        forecast.tokenIn = _tokenIn;
        forecast.tokenOut = _tokenOut;
        forecast.tokenInAmount = _amount;
        forecast.tokenOutAmount = _uniSwapV2RouterGetAmountOut(_exchange, _tokenIn, _tokenOut, _amount);

        return forecast;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../interfaces/IUniSwapV2Router02.sol";
import "../Library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract UniSwapV2Trader is LibraryContract {

    uint constant MAX_SLIPPAGE = 50;

    mapping(address => IUniSwapV2Router02) private exchanges;

    constructor()
    {
        for(uint256 i; i < uniswapV2Exchanges.length; i++)
        {
            exchanges[uniswapV2Exchanges[i]] = IUniSwapV2Router02(uniswapV2Exchanges[i]);
        }
    }

    function _uniSwapV2RouterGetAmountOut(address _exchange, address _tokenInAddress, address _tokenOutAddress, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountOutByPath(_exchange, _createAddressPath(_tokenInAddress, _tokenOutAddress), _amount);
    }

    function _uniSwapV2RouterGetAmountIn(address _exchange, address _tokenInAddress, address _tokenOutAddress, uint256 _amount) internal view returns(uint256)
    {
        return _uniSwapV2RouterGetAmountInByPath(_exchange, _createAddressPath(_tokenInAddress, _tokenOutAddress), _amount);
    }

    function _uniSwapV2RouterGetAmountOutByPath(address _exchange, address[] memory _path, uint256 _amount) internal view returns(uint256)
    {
        // console.log("UniSwapV2Trader - Get amount out. tokenIn: %o tokenOut: %o amount: %d", _path[0], _path[_path.length - 1], _amount);

        try exchanges[_exchange].getAmountsOut(_amount, _path) returns(uint256[] memory _amountsOut)
        {
            // console.log("UniSwapV2Trader - out: %d", _amountsOut[_amountsOut.length - 1]);

            return _amountsOut[_amountsOut.length - 1];
        }
        catch (bytes memory)
        {

        }

        // console.log("ERROR - UniSwapV2Trader - out: 0");

        return 0;
    }

    function _uniSwapV2RouterGetAmountInByPath(address _exchange, address[] memory _path, uint256 _amount) internal view returns(uint256)
    {
        // console.log("UniSwapV2Trader - Get amount in. tokenIn: %o tokenOut: %o amount: %d", _path[0], _path[_path.length - 1], _amount);

        try exchanges[_exchange].getAmountsIn(_amount, _path) returns(uint256[] memory _amountsIn)
        {
            // console.log("UniSwapV2Trader - in: %d", _amountsIn[0]);

            return _amountsIn[0];
        }
        catch (bytes memory)
        {

        }

        // console.log("ERROR - UniSwapV2Trader - in: %d", MAX_INT);

        return MAX_INT;
    }



    function _uniSwapV2RouterSwapToken(address _exchange, address _tokenInAddress, address _tokenOutAddress, uint256 _amount) internal returns(bool)
    {
        if (_amount == 0)
        {
            return false;
        }


        _uniSwapV2RouterApproveSpending(_exchange, _tokenInAddress);

        uint256 _inBalance = IERC20(_tokenInAddress).balanceOf(address(this));

        require(_inBalance >= _amount, "Not enough tokens available for swap");

        address[] memory path = _createAddressPath(_tokenInAddress, _tokenOutAddress);

        uint256 amountOut = _uniSwapV2RouterGetAmountOutByPath(_exchange, path, _amount);

        // slippage
        uint256 minAmount = amountOut - _calculatePercent(amountOut, MAX_SLIPPAGE); 
        address receiver = address(this);

        try exchanges[_exchange].swapExactTokensForTokens(_amount, minAmount, path, receiver, block.timestamp) returns(uint256[] memory _amountsOut)
        {
            return _amountsOut[1] != 0;
        }
        catch (bytes memory)
        {

        }

        return false;
    }


    function _uniSwapV2RouterApproveSpending(address _exchange, address _tokenAddress) private
    {
        IERC20(_tokenAddress).approve(_exchange, MAX_INT);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniSwapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}