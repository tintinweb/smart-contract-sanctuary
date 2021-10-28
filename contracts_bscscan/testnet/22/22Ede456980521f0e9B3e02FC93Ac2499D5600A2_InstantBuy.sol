/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract InstantBuy
{
    uint PRICE_CONVERT_DECIMALS = 18;
    uint256 ONE_HUNDRED = 100000000000000000000;

    address public networkcoinaddress;
    address public owner;
    address public feeTo;
    address public chainWrapToken;
    address public swapFactory;

    //Instant Buy Price in BUSD
    // mapping(address => uint256) public instantbuyprice;

    //Instant Buy: Allow To Buy Token (0/1 = false/true)
    mapping(address => uint) public instantbuyallowtobuytoken;

    //Token Fee Percent
    mapping(address => uint256) public tokenfeepercent;

    event OnBuy(address tokenSource, address tokenDestination, uint256 quotePrice, uint256 txPrice, uint256 buyFee, uint256 amountReceived);

    constructor() {
        owner = msg.sender;
        feeTo = owner;
        networkcoinaddress = address(0x1110000000000000000100000000000000000111);

        /*
        56: WBNB
        1: WETH9
        43114: WAVAX
        97: WBNB testnet
        */
        chainWrapToken = block.chainid == 56 ?  address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) : 
                    (block.chainid == 1 ?       address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) : 
                    (block.chainid == 43114 ?   address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) : 
                    (block.chainid == 97 ?      address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd) : 
                                                address(0) ) ) );

        /*
        56: PancakeFactory
        1: UniswapV2Factory
        43114: PangolinFactory
        97: PancakeFactory testnet
        */
        swapFactory = block.chainid == 56 ?     address(0xBCfCcbde45cE874adCB698cC183deBcF17952812) : 
                    (block.chainid == 1 ?       address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) : 
                    (block.chainid == 43114 ?   address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88) : 
                    (block.chainid == 97 ?      address(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc) : 
                                                address(0) ) ) );
    }

    function supplyNetworkCoin() payable external {
        require(msg.sender == owner, 'FN'); //Forbidden
        // nothing else to do!
    }

    function transferFund(ERC20 token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Withdraw of deposit value
        if(address(token) != networkcoinaddress)
        {
            //Withdraw token
            token.transfer(to, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(to).transfer(amountInWei);
        }
    }

    function setOwner(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        owner = newValue;
        return true;
    }

    function setFeeTo(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        feeTo = newValue;
        return true;
    }

    function setNetworkCoinAddress(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinaddress = newValue;
        return true;
    }

    // function getInstantBuyPrice(address tokenAddress) external view returns (uint256 value)
    // {
    //     return instantbuyprice[tokenAddress];
    // }

    // function setInstantBuyPrice(address tokenAddress, uint256 newValue) external returns (bool success)
    // {
    //     require(msg.sender == owner, 'FN'); //Forbidden

    //     instantbuyprice[tokenAddress] = newValue;
    //     return true;
    // }

    function getInstantBuyFee(address tokenAddress) external view returns (uint256 value)
    {
        return tokenfeepercent[tokenAddress];
    }

    function setInstantBuyFee(address tokenAddress, uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        tokenfeepercent[tokenAddress] = newValue;
        return true;
    }

    // function getInstantBuyPriceQuote(address tokenAddressSource, address tokenAddressDestination) public view returns (uint256 value)
    // {
    //     if(instantbuyprice[tokenAddressSource] == 0)
    //     {
    //         return 0;
    //     }

    //     if(instantbuyprice[tokenAddressDestination] == 0)
    //     {
    //         return 0;
    //     }

    //     uint256 result = safeDivFloat(instantbuyprice[tokenAddressSource], instantbuyprice[tokenAddressDestination], PRICE_CONVERT_DECIMALS);

    //     return result;
    // }

    function getInstantBuyPriceQuote(address source, address destination) public view returns (uint256 value)
    {
        uint256 result;

        if(swapFactory == address(0))
        {
            return result;
        }

        if(source == networkcoinaddress)
        {
            source = chainWrapToken;
        }

        if(destination == networkcoinaddress)
        {
            destination = chainWrapToken;
        }

        address pairLP = IUniswapV2Factory(swapFactory).getPair(source, destination);

        if(pairLP == address(0))
        {
            return result;
        }

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairLP).getReserves();

        if(reserve0 == 0 || reserve1 == 0)
        {
            return result;
        }

        if(IUniswapV2Pair(pairLP).token0() == source)
        {
            result = SafeMath.safeDivFloat(reserve1, reserve0, ERC20(source).decimals());
        }
        else
        {
            result = SafeMath.safeDivFloat(reserve0, reserve1, ERC20(source).decimals());
        }

        return result;
    }

    function getInstantBuyTokenAllowedToBuy(address tokenAddress) external view returns (bool value)
    {
        return instantbuyallowtobuytoken[tokenAddress] == 1;
    }

    function setInstantBuyTokenAllowedToBuy(address tokenAddress, uint newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        instantbuyallowtobuytoken[tokenAddress] = newValue;
        return true;
    }

    function getBuyForecast(address tokenSource, address tokenDestination, uint256 amountInWei) external view returns (uint256 value)
    {
        uint256 feePercent = tokenfeepercent[tokenDestination]; //Eg 10% (10000000000000000000)
        uint256 fee = 0;
        if(feePercent > 0)
        {
            fee = SafeMath.safeDiv(SafeMath.safeMul(amountInWei, feePercent), ONE_HUNDRED);
            amountInWei = SafeMath.safeSub(amountInWei, fee);
        }

        uint256 quote = getInstantBuyPriceQuote(tokenSource, tokenDestination);
        uint256 result = SafeMath.safeMulFloat( quote, amountInWei, PRICE_CONVERT_DECIMALS);

        return result;
    }

    function getBuyForecastWithFee(address tokenSource, address tokenDestination, uint256 amountInWei) external view returns (uint256 value)
    {
        uint256 quote = getInstantBuyPriceQuote(tokenSource, tokenDestination);
        uint256 result = SafeMath.safeMulFloat( quote, amountInWei, PRICE_CONVERT_DECIMALS);

        return result;
    }

    function instantBuyUsingToken(address tokenSource, address tokenDestination, uint256 amountInWei) external returns (bool success)
    {
        require(ERC20(tokenSource).allowance(msg.sender, address(this)) >= amountInWei, "AL"); //STAKE: Check the token allowance. Use approve function.
        // require(instantbuyprice[tokenSource] > 0, "SNI"); //STAKE: Token Source not initialized
        // require(instantbuyprice[tokenDestination] > 0, "DNI"); //STAKE: Token Destination not initialized
        require(instantbuyallowtobuytoken[tokenDestination] == 1, "N"); //STAKE: Token not allowed to buy
        require(amountInWei > 0, "ZERO"); //STAKE: Zero Amount

        //Receive payment
        ERC20(tokenSource).transferFrom(msg.sender, feeTo, amountInWei);

        //Reduce admin fee to swap
        uint256 feePercent = tokenfeepercent[tokenDestination]; //Eg 10% (10000000000000000000)
        uint256 fee = 0;
        if(feePercent > 0)
        {
            require(feePercent <= ONE_HUNDRED, "IF"); //STAKE: Invalid percent fee value

            fee = SafeMath.safeDiv(SafeMath.safeMul(amountInWei, feePercent), ONE_HUNDRED);
            amountInWei = SafeMath.safeSub(amountInWei, fee);
        }

        //Send paid token amount
        uint256 quote = getInstantBuyPriceQuote(tokenSource, tokenDestination);
        uint256 result = SafeMath.safeMulFloat( quote, amountInWei, PRICE_CONVERT_DECIMALS);

        uint256 contractBalance = ERC20(tokenDestination).balanceOf(address(this));
        require(contractBalance >= result, "NE"); //STAKE: Not enough balance

        ERC20(tokenDestination).transfer(msg.sender, result);

        //Event Buy Trigger: tokenSource, tokenDestination, quotePrice, txPrice, buyFee, amountReceived
        emit OnBuy(tokenSource, tokenDestination, quote, amountInWei, fee, result);

        return true;
    }

    function instantBuyUsingNetworkCoin(address tokenDestination) external payable returns (bool success)
    {
        require(instantbuyallowtobuytoken[tokenDestination] == 1, "N"); //STAKE: Token not allowed to buy
        require(msg.value > 0, "ZERO"); //STAKE: Zero Amount

        //Receive payment
        payable(feeTo).transfer(msg.value);

        //Reduce admin fee to swap
        uint256 feePercent = tokenfeepercent[tokenDestination]; //Eg 10% (10000000000000000000)
        uint256 fee = 0;
        uint256 amountInWei = msg.value;
        if(feePercent > 0)
        {
            require(feePercent <= ONE_HUNDRED, "IF"); //STAKE: Invalid percent fee value

            fee = SafeMath.safeDiv(SafeMath.safeMul(amountInWei, feePercent), ONE_HUNDRED);
            amountInWei = SafeMath.safeSub(amountInWei, fee);
        }

        //Send paid token amount
        //uint256 quote = safeDivFloat(instantbuyprice[networkcoinaddress], instantbuyprice[tokenDestination], PRICE_CONVERT_DECIMALS);
        uint256 quote = getInstantBuyPriceQuote(networkcoinaddress, tokenDestination);
        uint256 result = SafeMath.safeMulFloat( quote, amountInWei, PRICE_CONVERT_DECIMALS);

        uint256 contractBalance = ERC20(tokenDestination).balanceOf(address(this));
        require(contractBalance >= result, "NE"); //STAKE: Not enough balance

        ERC20(tokenDestination).transfer(msg.sender, result);

        //Event Buy Trigger: tokenSource, tokenDestination, quotePrice, txPrice, buyFee, amountReceived
        emit OnBuy(networkcoinaddress, tokenDestination, quote, amountInWei, fee, result);

        return true;
    }

    function setChainWrapToken(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        chainWrapToken = newValue;
    }

    function setSwapFactory(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        swapFactory = newValue;
    }

}

// *****************************************************
// **************** SAFE MATH FUNCTIONS ****************
// *****************************************************
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeDivFloat(uint256 a, uint256 b, uint256 decimals) internal pure returns (uint256)
    {
        return safeDiv(safeMul(a, safePow(10,decimals)), b);
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}