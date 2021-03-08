/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

//MainNet Deployment: 0x8316b082621cfedab95bf4a44a1d4b64a6ffc336

//orfeed.org oracle aggregator


pragma experimental ABIEncoderV2;

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);

    function getUserCapInWei(address user) external view returns(uint);

    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);

    function enabled() external view returns(bool);

    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns(uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) external payable returns(uint);

    function swapEtherToToken(ERC20 token, uint minRate) external payable returns(uint);

    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns(uint);
}

interface Kyber {
    function getOutputAmount(ERC20 from, ERC20 to, uint256 amount) external view returns(uint256);

    function getInputAmount(ERC20 from, ERC20 to, uint256 amount) external view returns(uint256);
}

interface eventsSyncInterface {
    function getEventResult(string eventName, string source) external view returns(string);

}

interface Uniswap {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns(uint256);

    function getEthToTokenOutputPrice(uint256 tokensBought) external view returns(uint256);

    function getTokenToEthInputPrice(uint256 tokensSold) external view returns(uint256);

    function getTokenToEthOutputPrice(uint256 ethBought) external view returns(uint256);
}

interface ERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


// Oracle Feed Contract
contract orfeed {

    address owner;
    mapping(string => address) freeRateTokenSymbols;

  
    address ethTokenAddress;

    address tokenPriceOracleAddress;

    address tokenPriceOracleAddress2;


    IKyberNetworkProxy ki;
    Kyber kyber;
    Uniswap uniswap;
    ERC20 ethToken;
    
    address ethAddress;
    address kncAddress;



    // Functions with this modifier can only be executed by the owner DAO
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    //free ERC20 rates. Can be changed/updated by ownerDAO
    constructor() public payable {
        // freeRateTokenSymbols['SAI'] = 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359;
        // freeRateTokenSymbols['DAI'] = 0x6b175474e89094c44da98b954eedeac495271d0f;
        // freeRateTokenSymbols['USDC'] = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;
        // freeRateTokenSymbols['MKR'] = 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2;
        // freeRateTokenSymbols['LINK'] = 0x514910771af9ca656af840dff83e8264ecf986ca;
        // freeRateTokenSymbols['BAT'] = 0x0d8775f648430679a709e98d2b0cb6250d2887ef;
        // freeRateTokenSymbols['WBTC'] = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;
        // freeRateTokenSymbols['BTC'] = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;
        // freeRateTokenSymbols['OMG'] = 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07;
        // freeRateTokenSymbols['ZRX'] = 0xe41d2489571d322189246dafa5ebde1f4699f498;
        // freeRateTokenSymbols['TUSD'] = 0x0000000000085d4780B73119b644AE5ecd22b376;
        // ETH is typically always better off as 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        // freeRateTokenSymbols['ETH'] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        // freeRateTokenSymbols['WETH'] = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        // freeRateTokenSymbols['ETH2'] = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        // freeRateTokenSymbols['SNX'] = 0xc011a72400e58ecd99ee497cf89e3775d4bd732f;
        // freeRateTokenSymbols['CSAI'] = 0xf5dce57282a584d2746faf1593d3121fcac444dc;
        // freeRateTokenSymbols['CUSDC'] = 0x39aa39c021dfbae8fac545936693ac917d5e7563;
        // freeRateTokenSymbols['KNC'] = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
        kncAddress = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
        // freeRateTokenSymbols['USDT'] = 0xdac17f958d2ee523a2206206994597c13d831ec7;
        // freeRateTokenSymbols['GST1'] = 0x88d60255F917e3eb94eaE199d827DAd837fac4cB;
        // freeRateTokenSymbols['GST2'] = 0x0000000000b3F879cb30FE243b4Dfee438691c04;

        //commented list of tokens added post deployment

        //freeRateTokenSymbols['LEND'] = 0x80fb784b7ed66730e8b1dbd9820afd29931aab03;
        //freeRateTokenSymbols['ADAI'] = 0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d;
        //freeRateTokenSymbols['REP'] =  0x1985365e9f78359a9B6AD760e32412f4a445E862;
        //freeRateTokenSymbols['ZIL'] =  0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27;
        //freeRateTokenSymbols['AST'] =  0x27054b13b1b798b345b591a4d22e6562d47ea75a;
        //freeRateTokenSymbols['HOT'] =  0x6c6ee5e31d828de241282b9606c8e98ea48526e2;
        //freeRateTokenSymbols['KCS'] =  0x039b5649a59967e3e936d7471f9c3700100ee1ab;
        //freeRateTokenSymbols['MXM'] =  0x8e766f57f7d16ca50b4a0b90b88f6468a09b0439;
        //freeRateTokenSymbols['CRO'] =  0xa0b73e1ff0b80914ab6fe0444e65848c4c34450b;
        //freeRateTokenSymbols['BNB'] =  0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
        //freeRateTokenSymbols['BNT'] =  0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c;
        //freeRateTokenSymbols['HT'] =  0x6f259637dcd74c767781e37bc6133cd6a68aa161;
        //freeRateTokenSymbols['PAX'] =  0x8e870d67f660d95d5be530380d0ec0bd388289e1;
        //freeRateTokenSymbols['CDAI'] =  0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        //freeRateTokenSymbols['CSAI'] =  0xf5dce57282a584d2746faf1593d3121fcac444dc;
        //freeRateTokenSymbols['USDT'] = 0xdac17f958d2ee523a2206206994597c13d831ec7;
        //freeRateTokenSymbols['SUSD'] = 0x57ab1e02fee23774580c119740129eac7081e9d3;
        //freeRateTokenSymbols['SEUR'] = 0xd71ecff9342a5ced620049e616c5035f1db98620;
        //freeRateTokenSymbols['SGBP'] = 0x97fe22e7341a0cd8db6f6c021a24dc8f4dad855f;
        //freeRateTokenSymbols['SETH'] = 0x57ab1e02fee23774580c119740129eac7081e9d3;
        //freeRateTokenSymbols['SJPY'] = 0xf6b1c627e95bfc3c1b4c9b825a032ff0fbf3e07d;
        //freeRateTokenSymbols['PAY'] = 0xB97048628DB6B661D4C2aA833e95Dbe1A905B280;



        //erc20 price oracle address. Can be changed by DAO
        tokenPriceOracleAddress = 0xd719c34261e099Fdb33030ac8909d5788D3039C4;

        tokenPriceOracleAddress2 = 0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244;


        ethTokenAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


        ethToken = ERC20(ethTokenAddress);



        // ki = IKyberNetworkProxy(tokenPriceOracleAddress);

        // kyber = Kyber(tokenPriceOracleAddress); // Kyber oracle

        // uniswap = Uniswap(tokenPriceOracleAddress2);

        owner = msg.sender;
    }

    function() public payable {
        uint256 val = msg.value;
        address sender = msg.sender;
        revert();
    }


    function getExchangeRateEd(uint256 amount) public returns(uint) {
        ki = IKyberNetworkProxy(0xd719c34261e099Fdb33030ac8909d5788D3039C4);
        (uint expectedRate, uint slippageRate) = ki.getExpectedRate(ERC20(ethAddress), ERC20(kncAddress), amount);
        return expectedRate;
    }
}