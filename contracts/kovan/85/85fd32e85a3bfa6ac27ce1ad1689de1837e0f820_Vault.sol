/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// File: contracts/Vault.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//This code was initially produced by the Ethereum 25 Index.

//HIGH PRIORITY: SET THE MASTER ADDRESS WHEN YOU DEPLOY THIS FOR REAL. ALSO REMEMBER TO SET THE RECEIPT TOKEN ADDRESS
//WORKFLOW:
//1. DEPLOY TOKEN
//2. ENTER VAULT TOKEN ADDRESS IN VAULT CODE
//3. DEPLOY VAULT
//4. SET MASTER ADDRESS FOR TOKEN

//Etherscan web addresses are, for some reason, not case sensitive (maybe they cant be) but addresses are. that's a problem.

//Medium priority:
//Create events for everything
//Make all your private functions internal if it is cheaper or comparable on gas fees
//Is reentrancy guard necessary for sendViaCall?
//Should I enable optimization when compiling?
//Make the smart contract calls not be denominated in the smallest unit for user-facing functions
//Ensure that your math regarding proportions (all the multiplication and division operations) are safe and do not overflow nor degrade precision.
//Convert all uint256's to uint128 to save space.
//When doing any multiplication such as price calculation, use uint256 to be safe.
//Make sure every require has a message
//Ensure that when a withdraw occurs, the ETH allocation does not drop below 5%. If it does, trigger a rebalance. Put in the "user manual" to not withdraw more than 5% of the fund's assets at once.
//Implement MATIC price functionality.
//sloads are incredibly expensive don't do them, dont store stuff in storage
//See if you could put in zero fee exchange instead
//Gas fee should be prioritized to minimize rebalancing, at least at first, maybe once it scales we optimize otherwise

//Low priority:
//Get listed on CMC
//Make your code all-around cleaner and more consistent

// ["0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"]

interface IIndexToken {
    function totalSupply() external view returns (uint256);
    function mint(address _to, uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);
    function decimals() external view returns (uint8);
}

interface IPortfolioToken {
    function balanceOf(address vault) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
    function WETH() external pure returns (address); //This can be replaced with literal once deployed to mainnet, if necessary
}

interface IWETH {
    function balanceOf(address vault) external view returns (uint);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract Vault 
{
    //DAI, MKR, UNI
    //tokens:  ["0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", "0xaC94Ea989f6955C67200DD67F0101e1865A560Ea", "0x9b6Ff80Ff8348852d5281de45E66B7ED36E7B8a9"]
    //oracles: ["0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541", "0x0B156192e04bAD92B6C1C13cf8739d14D78D5701", "0x17756515f112429471F86f98D5052aCB6C47f6ee"]
    // ["0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", "0xaC94Ea989f6955C67200DD67F0101e1865A560Ea", "0x9b6Ff80Ff8348852d5281de45E66B7ED36E7B8a9"], ["0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541", "0x0B156192e04bAD92B6C1C13cf8739d14D78D5701", "0x17756515f112429471F86f98D5052aCB6C47f6ee"]
    address[] public tokens = new address[](NUMBER_OF_ASSETS);
    address[] public oracles = new address[](NUMBER_OF_ASSETS);
    uint public constant NUMBER_OF_ASSETS = 3; //if you want to save gas, replace all constants with the literals. This will save both on publishing and running
    uint public constant INITIAL_TOKEN_AMOUNT = 100000000000000000000; //This is 100 tokens.
    uint public NEGLIGIBLE_AMOUNT_OF_WEI = 1000000000000000000; //This is 10^18. 1 ETH, which is about $2500 at the time of this being written.
    address public constant ETH_USD_ORACLE = address(0x9326BFA02ADD2366b30bacB125260Af641031331); //Necessary for Polygon check. Maybe pass this in to the necessary functions, and declare it at the start of the function it's needed in.
    address public constant POLYGON_ORACLE_ADDRESS = address(0x0);
    address public constant UNISWAP_API_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //This address is the same on testnets too.
    constructor(
        uint160[] memory tokenAddresses,
        uint160[] memory oracleAddresses
    ) {
        require(tokenAddresses.length == oracleAddresses.length, "Token addresses different number than oracle addresses");
        require(tokenAddresses.length == NUMBER_OF_ASSETS, "Token addresses different number than number of assets");
        for (uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            tokens[i] = address(tokenAddresses[i]);
            oracles[i] = address(oracleAddresses[i]);
        }
    }
    
    function deposit() public payable {
        address RECEIPT_TOKEN_ADDRESS = address(0x59c81baD67E3c90D1C2524DD00efB48c7d41811A);
        uint256 oldTokenSupply = getReceiptTokenTotalSupply(RECEIPT_TOKEN_ADDRESS); //this will be denominated in the smallest denomination of the new ERC-20 receipt token
        uint256 receiptTokensOwed;
        if (oldTokenSupply == 0) {
            receiptTokensOwed = INITIAL_TOKEN_AMOUNT; //This ensures that the first depositor gets some tokens.
        } else {
            uint256 depositValue = msg.value;
            uint256 newVaultValue = calculateValueOfVault();
            receiptTokensOwed = (depositValue * oldTokenSupply) / (newVaultValue - depositValue);
        }
        mint(msg.sender, receiptTokensOwed, RECEIPT_TOKEN_ADDRESS);
    }
    
    function withdraw(address payable customer, uint256 tokenValue, address RECEIPT_TOKEN_ADDRESS) private {
        uint256 weiOwed = (calculateValueOfVault() * tokenValue) / getReceiptTokenTotalSupply(RECEIPT_TOKEN_ADDRESS);
        if (IIndexToken(RECEIPT_TOKEN_ADDRESS).burnFrom(customer, tokenValue)) {
            sendViaCall(customer, weiOwed);
        }
    }
    
    function sendViaCall(address payable _to, uint256 amount) private {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function receiveApproval(address payable _from, uint256 _value, address _token) external {
        withdraw(_from, _value, _token); //it is possible to remove this function and riectly integrate withdraw() into the IndexToken contract. Then, make approveAndCall() the standard function again.
    }
    
    function mint(address customer, uint256 value, address RECEIPT_TOKEN_ADDRESS) private {
        IIndexToken(RECEIPT_TOKEN_ADDRESS).mint(customer, value); //consider adding events and figuring out how they work. Everything important needs to be broadcasted
    }
    
    function calculateValueOfVault() private view returns (uint256 currentValueOfVault) {
        (, uint256 totalValueOfTokens) = getCurrentDistribution();
        uint256 weiInVault = address(this).balance;
        return totalValueOfTokens + weiInVault;
    }
    
    function getReceiptTokenTotalSupply(address RECEIPT_TOKEN_ADDRESS) private view returns (uint256 totalSupply) {
        return IIndexToken(RECEIPT_TOKEN_ADDRESS).totalSupply();
    }
    
    function rebalancePortfolio() public returns (bool success)
    {
        uint256 totalValueOfVault = calculateValueOfVault();
        int256 idealWeiAmount = (int256)(totalValueOfVault / 10);
        uint256 currentWeiAmount = address(this).balance;
        int256 excessWei = (int256)(currentWeiAmount) - idealWeiAmount; //Can likely simplify the next three lines by substituting variables for these lines.
        uint256 currentAssetValue = totalValueOfVault - currentWeiAmount;
        uint256 goalAssetValue = (uint256)((int256)(currentAssetValue) + excessWei);
        uint256[] memory idealAssetDistribution = calculateIdealDistribution(goalAssetValue);
        (uint256[] memory currentAssetDistribution, ) = getCurrentDistribution();
        //require(idealAssetDistribution.length == currentAssetDistribution.length, "Ideal and current distribution different lengths");
        //require(idealAssetDistribution.length == NUMBER_OF_ASSETS, "Ideal distribution length different than number of assets");
        int256[] memory amountToBuyOfEach = new int256[](NUMBER_OF_ASSETS);
        //int256 totalCheck = 0;
        for(uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            //console.log(string(amountToBuyOfEach.length));
            amountToBuyOfEach[i] = (int256)(idealAssetDistribution[i]) - (int256)(currentAssetDistribution[i]);
            //totalCheck = totalCheck + amountToBuyOfEach[i];
        }
        
        //The amount of wei difference between the two should be less than NUMBER_OF_ASSETS, because of imprecise division (Solidity can't handle decimals)
        
        //require(totalCheck >= excessWei - (int256)(NUMBER_OF_ASSETS) && totalCheck <= excessWei + (int256)(NUMBER_OF_ASSETS), "Sum of amount to buy does not approximately equal total");
        
        //Note that selling must occur before buying in the case of extreme scenarios where we do not have enough ETH in reserve to buy it all.
        //wrapVaultETH();
        for(uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            if(amountToBuyOfEach[i] * -1 > (int256)(NEGLIGIBLE_AMOUNT_OF_WEI)) {
                sellToken(tokens[i], oracles[i], (uint256)(amountToBuyOfEach[i] * -1));
            }
        }
        for(uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            if(amountToBuyOfEach[i] > (int256)(NEGLIGIBLE_AMOUNT_OF_WEI)) {
                buyToken(tokens[i], oracles[i], (uint256)(amountToBuyOfEach[i]));
            }
        }
        //unwrapVaultETH();
        return true;
    }
    
    function wrapVaultETH() private {
        IWETH(IUniswap(UNISWAP_API_ADDRESS).WETH()).deposit{value: address(this).balance}();
        //require(address(this).balance == 0, "Wrapping ETH failed");
    }
    
    function unwrapVaultETH() private {
        address WETHAddress = IUniswap(UNISWAP_API_ADDRESS).WETH();
        IWETH(WETHAddress).withdraw(IWETH(WETHAddress).balanceOf(address(this)));
        //require(IWETH(WETHAddress).balanceOf(address(this)) == 0, "Unwrapping ETH failed");
    }
    
    function sellToken(address tokenAddress, address oracleAddress, uint256 amountToSellInWei) private {
        uint maxTokensToSell = (amountToSellInWei + (amountToSellInWei / 10)) / getPriceOfTokenInWei(oracleAddress); //We will be willing to sell up to 10% more than the expected amount of tokens.
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = IUniswap(UNISWAP_API_ADDRESS).WETH();
        IUniswap(UNISWAP_API_ADDRESS).swapTokensForExactETH(amountToSellInWei, maxTokensToSell, path, address(this), block.timestamp + 600);
    }
    
    function buyToken(address tokenAddress, address oracleAddress, uint256 amountToBuyInWei) private {
        uint minTokensToBuy = (amountToBuyInWei - (amountToBuyInWei / 10)) / getPriceOfTokenInWei(oracleAddress); //We will be willing to buy as little as 90% of the expected amount of tokens.
        address[] memory path = new address[](2);
        path[0] = IUniswap(UNISWAP_API_ADDRESS).WETH();
        path[1] = tokenAddress;
        IUniswap(UNISWAP_API_ADDRESS).swapExactETHForTokens{value: amountToBuyInWei}(minTokensToBuy, path, address(this), block.timestamp + 600);
    }
    
    //The values in this function are measured in wei. This function sums the wei values of all the tokens as well.
    function getCurrentDistribution() private view returns (uint256[] memory distribution, uint256 totalValueOfTokens) {
        uint256[] memory distrib = new uint256[](NUMBER_OF_ASSETS);
        uint256 totalValue = 0;
        for(uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            distrib[i] = getVaultAmountOfToken(tokens[i]) * getPriceOfTokenInWei(oracles[i]);
            totalValue = totalValue + distrib[i];
        }
        return (distrib, totalValue);
    }
    
    //The values in this function are measured in wei.
    function calculateIdealDistribution(uint256 totalAssetValue) private view returns (uint256[] memory distribution) {
        uint256[] memory distrib = new uint256[](NUMBER_OF_ASSETS);
        uint256[] memory marketCaps = new uint256[](NUMBER_OF_ASSETS);
        uint256 combinedMarketCap = 0;
        for(uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            marketCaps[i] = getTotalSupplyOfToken(tokens[i]) * getPriceOfTokenInWei(oracles[i]);
            combinedMarketCap = combinedMarketCap + marketCaps[i];
        }
        for(uint i = 0; i < NUMBER_OF_ASSETS; i++) {
            distrib[i] = (marketCaps[i] * totalAssetValue) / combinedMarketCap;
        }
        return distrib;
    }
    
    function getTotalSupplyOfToken(address tokenAddress) private view returns (uint256 totalSupply) {
        return 1000;//IPortfolioToken(tokenAddress).totalSupply();
    }
    
    function getVaultAmountOfToken(address tokenAddress) private view returns (uint256 vaultAmount) {
        return IPortfolioToken(tokenAddress).balanceOf(address(this));
    }
    
    function getPriceOfTokenInWei(address oracleAddress) private view returns (uint256 price) {
        if(oracleAddress == POLYGON_ORACLE_ADDRESS) {
            return IOracle(oracleAddress).latestAnswer() / IOracle(ETH_USD_ORACLE).latestAnswer(); //MATIC is a special case because there isn't an MATIC-ETH oracle currently.
        }
        return 1000;//return IOracle(oracleAddress).latestAnswer();
    }
}