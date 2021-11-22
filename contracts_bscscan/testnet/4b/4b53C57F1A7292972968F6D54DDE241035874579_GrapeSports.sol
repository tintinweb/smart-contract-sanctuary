/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERCProxy {
    function proxyType() external pure returns (uint256 proxyTypeId);
    function implementation() external view returns (address codeAddr);
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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
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
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  
    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
    
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
    
        //this is the address we are going to send the output tokens to
        address to,
    
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external returns (uint[] memory amounts);
}

contract GrapeSports {
    
    uint256 ONE_HUNDRED = 100000000000000000000;
    // address public networkcoinaddress;
    address public owner;
    address public feeTo;
    address public matchResultSetter;
    address public chainWrapToken;
    address public swapFactory;
    address public swapRouter;
    address public internalToken;
    uint256 public participationAwardAmount;
    
    // Fixture List
    uint[] private fixturelist;

    // Fixture => Season
    mapping(uint => uint) private fixtureSeason;

    // Fixture => League
    mapping(uint => uint) private fixtureLeague;

    // Fixture => 0 = false | 1 = true
    mapping(uint => uint) private fixtureBetOpened;

    // Fixture => Timestamp
    mapping(uint => uint256) private fixtureBetCloseTime;

    // Fixture => Percent
    mapping(uint => uint256) private fixtureTreasuryFeePercent;
    
    // Fixture => Percent
    mapping(uint => uint256) private fixturePercentOfTreasuryFeeForParticipationAward;

    // Fixture => Percent
    mapping(uint => uint256) private fixturePercentOfParticipationAwardBagToPayForLosers;

    // Fixture => Amount
    mapping(uint => uint256) private fixturePoolTeamHome;
    
    // Fixture => Amount
    mapping(uint => uint256) private fixturePoolTeamAway;

    // Fixture => Amount
    mapping(uint => uint256) private fixturePoolDraw;

    // Fixture => Result Position
    mapping(uint => uint) private fixtureMatchResultPosition;

    // Fixture => Player => Bet Amount
    mapping(uint => mapping(address => uint256)) private fixturePlayerBetAmount;

    // Fixture => Player => Bet Amount
    mapping(uint => mapping(address => uint256)) private fixturePlayerBetAmountInDepositToken;

    // Fixture => Player => Token
    mapping(uint => mapping(address => address)) private fixturePlayerBetToken;

    // Fixture => Player => Position
    mapping(uint => mapping(address => uint)) private fixturePlayerBetPosition;

    // Fixture => Player => Claimed
    mapping(uint => mapping(address => uint)) private fixturePlayerClaimed;

    //Events
    event OnBet(address player, uint fixture, uint betPosition, address tokenBet, uint256 amountTokenInWei, uint256 betAmount);
    event OnWinnerClaim(address player, uint fixture, uint betPosition, uint256 receivedAmount, address receivedToken);
    event OnLoserClaim(address player, uint fixture, uint betPosition, uint256 receivedAmount, address receivedToken);

    constructor() 
    {
        owner = msg.sender;
        feeTo = owner;
        matchResultSetter = owner;
        // networkcoinaddress = address(0x1110000000000000000100000000000000000111);

        // GRAPE
        internalToken = block.chainid == 56 ?  address(0xb699390735ed74e2d89075b300761daE34b4b36B) : 
                    (block.chainid == 137 ?     address(0x17757dcE604899699b79462a63dAd925B82FE221) :
                    (block.chainid == 1 ?       address(0) : 
                    (block.chainid == 43114 ?   address(0x17757dcE604899699b79462a63dAd925B82FE221) : 
                    (block.chainid == 97 ?      address(0x76B9660C78Cf4fB6bC3E489cEc37cb538ab54daE) : 
                                                address(0) ) ) ) );

        /*
        56: WBNB
        137: WMATIC
        1: WETH9
        43114: WAVAX
        97: WBNB testnet
        */
        chainWrapToken = block.chainid == 56 ?  address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) : 
                    (block.chainid == 137 ?     address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270) :
                    (block.chainid == 1 ?       address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) : 
                    (block.chainid == 43114 ?   address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) : 
                    (block.chainid == 97 ?      address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd) : 
                                                address(0) ) ) ) );

        /*
        56: PancakeFactory
        137: SushiSwap
        1: UniswapV2Factory
        43114: PangolinFactory
        97: PancakeFactory testnet
        */
        swapFactory = block.chainid == 56 ?     address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73) : 
                    (block.chainid == 137 ?     address(0xc35DADB65012eC5796536bD9864eD8773aBc74C4) : 
                    (block.chainid == 1 ?       address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) : 
                    (block.chainid == 43114 ?   address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88) : 
                    (block.chainid == 97 ?      address(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc) : 
                                                address(0) ) ) ) );

        /*
        56: PancakeFactory
        137: SushiSwap UniswapV2Router02
        1: UniswapV2Router02
        43114: Pangolin Router
        97: PancakeRouter testnet
        */
        swapRouter = block.chainid == 56 ?      address(0x10ED43C718714eb63d5aA57B78B54704E256024E) : 
                    (block.chainid == 137 ?     address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506) : 
                    (block.chainid == 1 ?       address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) : 
                    (block.chainid == 43114 ?   address(0x44771c71250D303d32E638c1c7ca7d00135cd65f) : 
                    (block.chainid == 97 ?      address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3) : 
                                                address(0) ) ) ) );
    }

    /* *****************************
            VAULT FUNCTIONS
    *  *****************************/

    function transferFund(address token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        doTransferFund(0, token, to, amountInWei);
    }

    function transferFundProxied(address token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        doTransferFund(1, token, to, amountInWei);
    }

    function doTransferFund(uint isProxy, address token, address to, uint256 amountInWei) internal
    {
        //Withdraw of deposit value
        // if(token != networkcoinaddress)
        if(token != chainWrapToken)
        {
            //Withdraw token
            if(isProxy == 0)
            {
                IERC20(token).transfer(to, amountInWei);
            }
            else
            {
                address backgroundToken = IERCProxy(token).implementation();
                IERC20(backgroundToken).transfer(to, amountInWei);
            }
        }
        else
        {
            //Withdraw Network Coin
            payable(to).transfer(amountInWei);
        }
    }

    function supplyParticipationAwardBag(uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        require(IERC20(internalToken).allowance(msg.sender, address(this)) >= amountInWei, "ALINT"); //BET: Check the internal token allowance. Use approve function.
        IERC20(internalToken).transferFrom(msg.sender, address(this), amountInWei);
        participationAwardAmount = SafeMath.safeAdd(participationAwardAmount, amountInWei);
    }

    function setParticipationAwardAmount(uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        participationAwardAmount = newValue;
    }

    function supplyPool(uint fixture, uint position, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        require(IERC20(internalToken).allowance(msg.sender, address(this)) >= amountInWei, "ALINT"); //BET: Check the internal token allowance. Use approve function.
        IERC20(internalToken).transferFrom(msg.sender, address(this), amountInWei);

        if(position == 1)
        {
            fixturePoolTeamHome[fixture] = SafeMath.safeAdd(fixturePoolTeamHome[fixture], amountInWei);
        }
        else if(position == 2)
        {
            fixturePoolTeamAway[fixture] = SafeMath.safeAdd(fixturePoolTeamAway[fixture], amountInWei);
        }
        else if(position == 3)
        {
            fixturePoolDraw[fixture] = SafeMath.safeAdd(fixturePoolDraw[fixture], amountInWei);
        }
        else
        {
            revert("INVPOS"); //Invalid Position
        }
    }

    function setPool(uint fixture, uint position, uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        if(position == 1)
        {
            fixturePoolTeamHome[fixture] = newValue;
        }
        else if(position == 2)
        {
            fixturePoolTeamAway[fixture] = newValue;
        }
        else if(position == 3)
        {
            fixturePoolDraw[fixture] = newValue;
        }
        else
        {
            revert("INVPOS"); //Invalid Position
        }
    }


    /* *****************************
            COMMON FUNCTIONS
    *  *****************************/

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

    function setMatchResultSetter(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        matchResultSetter = newValue;
        return true;
    }

    // function setNetworkCoinAddress(address newValue) external returns (bool success)
    // {
    //     require(msg.sender == owner, 'FN'); //Forbidden

    //     networkcoinaddress = newValue;
    //     return true;
    // }

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

    function setSwapRouter(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        swapRouter = newValue;
    }

    function setInternalToken(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        internalToken = newValue;
    }

    /* **********************************************************
            SPORTS BLOCK DATA FUNCTIONS
    *  **********************************************************/

    function getFixtureListSize() external view returns (uint)
    {
        return fixturelist.length;
    }

    function getFixtureListItemAt(uint ix) external view returns (uint)
    {
        return fixturelist[ix];
    }

    function getFixtureData(uint fixture, address player) external view returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](20);

        result[0] = fixtureSeason[fixture];                                         // getFixtureSeasonAndLeague
        result[1] = fixtureLeague[fixture];                                         // getFixtureSeasonAndLeague
        result[2] = fixtureBetOpened[fixture];                                      // getFixtureBetOpened
        result[3] = fixtureTreasuryFeePercent[fixture];                             // getFixtureTreasuryFeePercent
        result[4] = fixtureBetCloseTime[fixture];                                   // getFixtureBetCloseTime
        result[5] = fixturePercentOfTreasuryFeeForParticipationAward[fixture];      // getFixturePercentOfTreasuryFeeForParticipationAward
        result[6] = fixturePercentOfParticipationAwardBagToPayForLosers[fixture];   // getFixturePercentOfParticipationAwardBagToPayForLosers
        result[7] = fixturePoolTeamHome[fixture];                                   // getFixturePoolTeamHome
        result[8] = fixturePoolTeamAway[fixture];                                   // getFixturePoolTeamAway
        result[9] = fixturePoolDraw[fixture];                                       // getFixturePoolDraw
        result[10] = fixtureMatchResultPosition[fixture];                           // getFixtureMatchResultPosition
        result[11] = getFixtureBetMultiplyPoolTeamHome(fixture);                    // getFixtureBetMultiplyPoolTeamHome
        result[12] = getFixtureBetMultiplyPoolTeamAway(fixture);                    // getFixtureBetMultiplyPoolTeamAway
        result[13] = getFixtureBetMultiplyPoolDraw(fixture);                        // getFixtureBetMultiplyPoolDraw
        result[14] = getParticipationAwardToClaim(fixture);                         // getParticipationAwardToClaim
        result[15] = getFixtureCloseTimeLeft(fixture);                              // getFixtureCloseTimeLeft

        if(player != address(0))
        {
            result[16] = fixturePlayerBetAmount[fixture][player];                   // getFixturePlayerBetAmount
            result[17] = fixturePlayerBetAmountInDepositToken[fixture][player];     // getFixturePlayerBetAmountInDepositToken
            result[18] = fixturePlayerBetPosition[fixture][player];                 // getFixturePlayerBetPosition
            result[19] = fixturePlayerClaimed[fixture][player];                     // getFixturePlayerClaimed
        }

        return result;
    }

    function getFixtureSeasonAndLeague(uint fixture) external view returns (uint[] memory)
    {
        uint[] memory result = new uint[](2);

        result[0] = fixtureSeason[fixture];
        result[1] = fixtureLeague[fixture];

        return result;
    }

    function getFixtureBetOpened(uint fixture) external view returns (uint)
    {
        return fixtureBetOpened[fixture];
    }

    function setFixtureBetOpened(uint fixture, uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        fixtureBetOpened[fixture] = newValue;
    }

    function getFixtureTreasuryFeePercent(uint fixture) external view returns (uint256)
    {
        return fixtureTreasuryFeePercent[fixture];
    }

    function setFixtureTreasuryFeePercent(uint fixture, uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        fixtureTreasuryFeePercent[fixture] = newValue;
    }

    function getFixturePercentOfTreasuryFeeForParticipationAward(uint fixture) external view returns (uint256)
    {
        return fixturePercentOfTreasuryFeeForParticipationAward[fixture];
    }

    function setFixturePercentOfTreasuryFeeForParticipationAward(uint fixture, uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        fixturePercentOfTreasuryFeeForParticipationAward[fixture] = newValue;
    }

    function getFixturePercentOfParticipationAwardBagToPayForLosers(uint fixture) external view returns (uint256)
    {
        return fixturePercentOfParticipationAwardBagToPayForLosers[fixture];
    }

    function setFixturePercentOfParticipationAwardBagToPayForLosers(uint fixture, uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        fixturePercentOfParticipationAwardBagToPayForLosers[fixture] = newValue;
    }

    function getFixtureBetCloseTime(uint fixture) external view returns (uint256)
    {
        return fixtureBetCloseTime[fixture];
    }

    function setFixtureBetCloseTime(uint fixture, uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        fixtureBetCloseTime[fixture] = newValue;
    }

    function getFixturePoolTeamHome(uint fixture) external view returns (uint256)
    {
        return fixturePoolTeamHome[fixture];
    }

    function getFixturePoolTeamAway(uint fixture) external view returns (uint256)
    {
        return fixturePoolTeamAway[fixture];
    }

    function getFixturePoolDraw(uint fixture) external view returns (uint256)
    {
        return fixturePoolDraw[fixture];
    }

    function getFixturePlayerBetAmount(uint fixture, address player) external view returns (uint256)
    {
        return fixturePlayerBetAmount[fixture][player];
    }

    function getFixturePlayerBetAmountInDepositToken(uint fixture, address player) external view returns (uint256)
    {
        return fixturePlayerBetAmountInDepositToken[fixture][player];
    }

    function getFixturePlayerBetToken(uint fixture, address player) external view returns (address)
    {
        return fixturePlayerBetToken[fixture][player];
    }

    function getFixturePlayerBetPosition(uint fixture, address player) external view returns (uint)
    {
        return fixturePlayerBetPosition[fixture][player];
    }

    function getFixturePlayerClaimed(uint fixture, address player) external view returns (uint)
    {
        return fixturePlayerClaimed[fixture][player];
    }

    function getFixtureMatchResultPosition(uint fixture) external view returns (uint)
    {
        return fixtureMatchResultPosition[fixture];
    }

    /* **********************************************************
            SPORTS CALCULATION FUNCTIONS
    *  **********************************************************/
    function getFixtureBetMultiplyPoolTeamHome(uint fixture) public view returns (uint256)
    {
        if(fixturePoolTeamHome[fixture] == 0)
        {
            return 0;
        }

        uint256 decimals = IERC20(internalToken).decimals();
        uint256 betAmount = SafeMath.safeAdd(SafeMath.safeAdd(fixturePoolTeamHome[fixture], fixturePoolTeamAway[fixture]), fixturePoolDraw[fixture]);
        uint256 betMultiply = SafeMath.safeDivFloat(betAmount, fixturePoolTeamHome[fixture], decimals);
        return betMultiply;
    }

    function getFixtureBetMultiplyPoolTeamAway(uint fixture) public view returns (uint256)
    {
        if(fixturePoolTeamAway[fixture] == 0)
        {
            return 0;
        }

        uint256 decimals = IERC20(internalToken).decimals();
        uint256 betAmount = SafeMath.safeAdd(SafeMath.safeAdd(fixturePoolTeamHome[fixture], fixturePoolTeamAway[fixture]), fixturePoolDraw[fixture]);
        uint256 betMultiply = SafeMath.safeDivFloat(betAmount, fixturePoolTeamAway[fixture], decimals);
        return betMultiply;
    }

    function getFixtureBetMultiplyPoolDraw(uint fixture) public view returns (uint256)
    {
        if(fixturePoolDraw[fixture] == 0)
        {
            return 0;
        }

        uint256 decimals = IERC20(internalToken).decimals();
        uint256 betAmount = SafeMath.safeAdd(SafeMath.safeAdd(fixturePoolTeamHome[fixture], fixturePoolTeamAway[fixture]), fixturePoolDraw[fixture]);
        uint256 betMultiply = SafeMath.safeDivFloat(betAmount, fixturePoolDraw[fixture], decimals);
        return betMultiply;
    }

    function getRewardValueWithTreasuryFee(uint fixture, uint position, uint256 betAmount) public view returns (uint256)
    {
        uint256 prizeValue = getRewardValue(fixture, position, betAmount);
        uint256 treasuryFee = getTreasuryFee(fixture, prizeValue);
        return SafeMath.safeSub(prizeValue, treasuryFee);
    }

    function getParticipationAwardValueFromFee(uint fixture, uint position, uint256 betAmount) public view returns (uint256)
    {
        uint256 prizeValue = getRewardValue(fixture, position, betAmount);
        uint256 treasuryFee = getTreasuryFee(fixture, prizeValue);
        uint256 participationAwardPart = 0;

        uint256 participationAwardPercent = fixturePercentOfTreasuryFeeForParticipationAward[fixture];

        if(participationAwardPercent > 0)
        {
            participationAwardPart = SafeMath.safeDiv(SafeMath.safeMul(treasuryFee, participationAwardPercent), ONE_HUNDRED);
        }

        if(participationAwardPart > treasuryFee)
        {
            participationAwardPart = treasuryFee;
        }

        return participationAwardPart;
    }

    function getRewardValue(uint fixture, uint position, uint256 betAmount) public view returns (uint256)
    {
        uint256 multiplyValue = 0;
        if(position == 1)
        {
            multiplyValue = getFixtureBetMultiplyPoolTeamHome(fixture);
        }
        else if(position == 2)
        {
            multiplyValue = getFixtureBetMultiplyPoolTeamAway(fixture);
        }
        else if(position == 3)
        {
            multiplyValue = getFixtureBetMultiplyPoolDraw(fixture);
        }

        uint256 result = SafeMath.safeMul(betAmount, multiplyValue);
        return result;
    }

    function getParticipationAwardToClaim(uint fixture) public view returns (uint256)
    {
        uint256 result = 0;
        uint256 participationAwardPercent = fixturePercentOfParticipationAwardBagToPayForLosers[fixture];
        if(participationAwardPercent > 0)
        {
            result = SafeMath.safeDiv(SafeMath.safeMul(participationAwardAmount, participationAwardPercent), ONE_HUNDRED);
        }
        
        if(result > participationAwardAmount)
        {
            result = participationAwardAmount;
        }

        return result;
    }

    function getTreasuryFee(uint fixture, uint256 prizeValue) public view returns (uint256)
    {
        uint256 result = 0;
        uint256 feePercent = fixtureTreasuryFeePercent[fixture];

        if(feePercent > 0)
        {
            result = SafeMath.safeDiv(SafeMath.safeMul(prizeValue, feePercent), ONE_HUNDRED);
        }

        if(result > prizeValue)
        {
            result = prizeValue;
        }

        return result;
    }

    function getFixtureCloseTimeLeft(uint fixture) public view returns (uint256)
    {
        if(fixtureBetCloseTime[fixture] <= block.timestamp)
        {
            return 0;
        }

        return SafeMath.safeSub(fixtureBetCloseTime[fixture], block.timestamp);
    }

    // function getBetMultiplyPoolSimulation(uint256 betAmount, uint256 betPoolAmount) external pure returns (uint256)
    // {
    //     uint256 decimals = 18;
    //     uint256 betMultiply = SafeMath.safeDivFloat(betAmount, betPoolAmount, decimals);
    //     return betMultiply;
    // }

    // function getCloseTimeLeftSimulation(uint256 closeTimestamp) external view returns (uint256)
    // {
    //     if(closeTimestamp <= block.timestamp)
    //     {
    //         return 0;
    //     }

    //     return SafeMath.safeSub(closeTimestamp, block.timestamp);
    // }

    /* **********************************************************
            SPORTS MATCH
    *  **********************************************************/

    // betCloseTime in Timestamp => Javascript Date to Timestamp: new Date(2021, 11, 21).getTime() / 1000
    function matchSetup(uint season, uint league, uint fixture, uint forceBetToBeOpened, uint256 treasuryFeePercent, uint256 percentOfTreasuryFeeForParticipationAward, uint256 percentOfParticipationAwardBagToPayForLosers, uint256 betCloseTime) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        // First time fixture setup check to create structure
        if(fixtureBetCloseTime[fixture] == 0)
        {
            fixturelist.push(fixture);
            fixtureSeason[fixture] = season;
            fixtureLeague[fixture] = league;
        }

        if(forceBetToBeOpened == 1)
        {
            fixtureBetOpened[fixture] = 1;
        }

        fixtureTreasuryFeePercent[fixture] = treasuryFeePercent;
        fixturePercentOfTreasuryFeeForParticipationAward[fixture] = percentOfTreasuryFeeForParticipationAward;
        fixturePercentOfParticipationAwardBagToPayForLosers[fixture] = percentOfParticipationAwardBagToPayForLosers;
        fixtureBetCloseTime[fixture] = betCloseTime;
    }

    function setMatchResult(uint fixture, uint position) external
    {
        require(msg.sender == owner || msg.sender == matchResultSetter, 'FN'); //Forbidden

        fixtureMatchResultPosition[fixture] = position;
        fixtureBetOpened[fixture] = 0;
        fixtureBetCloseTime[fixture] = block.timestamp;
    }

    /* **********************************************************
            SPORTS BET DEPOSIT
    *  **********************************************************/

    // betPosition: 0 = UNDEFINED | 1 = HOME | 2 = AWAY | 3 = DRAW
    function bet(uint fixture, uint betPosition, address tokenBet, uint256 amountInWei) external
    {
        require(fixtureMatchResultPosition[fixture] == 0, "OVER"); //BET: Bet over, already has result
        require(getFixtureCloseTimeLeft(fixture) > 0, "TIMEOVER"); //BET: Time over for bet
        require(IERC20(tokenBet).allowance(msg.sender, address(this)) >= amountInWei, "AL"); //BET: Check the token allowance. Use approve function.
        require(fixtureBetOpened[fixture] == 1, "N"); //BET: Fixture not opened
        require(amountInWei > 0, "ZERO"); //BET: Zero Amount
        require(fixturePlayerBetToken[fixture][msg.sender] == address(0) || fixturePlayerBetToken[fixture][msg.sender] == tokenBet, "DIFFTK"); // Cannot bet same fixture using multiple tokens
        require(fixturePlayerBetPosition[fixture][msg.sender] == 0 || fixturePlayerBetPosition[fixture][msg.sender] == betPosition, "DIFFBET"); // Cannot bet same fixture using different bet position

        uint256 betAmount = 0;

        // Already is not internal token, swap to internal token before receive
        if(tokenBet != internalToken)
        {
            uint256 amountOutMin = getAmountOutMin(tokenBet, internalToken, amountInWei);
            require(amountOutMin > 0, "EMPTYLP");

            swap(tokenBet, internalToken, amountInWei, amountOutMin, msg.sender);
            betAmount = amountOutMin;
        }
        else
        {
            betAmount = amountInWei;
        }

        //Store position, token amount and token address used by player
        fixturePlayerBetPosition[fixture][msg.sender] = betPosition;
        fixturePlayerBetToken[fixture][msg.sender] = tokenBet;
        fixturePlayerBetAmount[fixture][msg.sender] = betAmount;
        fixturePlayerBetAmountInDepositToken[fixture][msg.sender] = amountInWei;

        require( IERC20(internalToken).balanceOf(msg.sender) >= betAmount, "LOWBALANCE" ); //Low balance after swap

        //Receive deposit to this contract 
        require(IERC20(internalToken).allowance(msg.sender, address(this)) >= betAmount, "ALINT"); //BET: Check the internal token allowance. Use approve function.
        IERC20(internalToken).transferFrom(msg.sender, address(this), betAmount);

        if(betPosition == 1) // HOME
        {
            fixturePoolTeamHome[fixture] = SafeMath.safeAdd(fixturePoolTeamHome[fixture], betAmount);
        }
        else if(betPosition == 2) // AWAY
        {
            fixturePoolTeamAway[fixture] = SafeMath.safeAdd(fixturePoolTeamAway[fixture], betAmount);
        }
        else if(betPosition == 3) // DRAW
        {
            fixturePoolDraw[fixture] = SafeMath.safeAdd(fixturePoolDraw[fixture], betAmount);
        }


        emit OnBet(msg.sender, fixture, betPosition, tokenBet, amountInWei, betAmount);
    }

    function betUsingNetworkCoin(uint fixture, uint betPosition) external payable
    {
        require(fixtureMatchResultPosition[fixture] == 0, "OVER"); //BET: Bet over, already has result
        require(getFixtureCloseTimeLeft(fixture) > 0, "TIMEOVER"); //BET: Time over for bet
        require(fixtureBetOpened[fixture] == 1, "N"); //BET: Fixture not opened
        require(msg.value > 0, "ZERO"); //STAKE: Zero Amount
        require(fixturePlayerBetToken[fixture][msg.sender] == address(0) || fixturePlayerBetToken[fixture][msg.sender] == chainWrapToken, "DIFFTK"); // Cannot bet same fixture using multiple tokens
        require(fixturePlayerBetPosition[fixture][msg.sender] == 0 || fixturePlayerBetPosition[fixture][msg.sender] == betPosition, "DIFFBET"); // Cannot bet same fixture using different bet position

        uint256 amountInWei = msg.value;

        uint256 amountOutMin = getAmountOutMin(chainWrapToken, internalToken, amountInWei);
        swapNetworkCoinToToken(internalToken, amountOutMin, msg.sender);

        //Store position, token amount and token address used by player
        fixturePlayerBetPosition[fixture][msg.sender] = betPosition;
        fixturePlayerBetToken[fixture][msg.sender] = chainWrapToken;
        fixturePlayerBetAmount[fixture][msg.sender] = amountOutMin;
        fixturePlayerBetAmountInDepositToken[fixture][msg.sender] = amountInWei;

        require( IERC20(internalToken).balanceOf(msg.sender) >= amountOutMin, "LOWBALANCE" ); //Low balance after swap

        //Receive deposit to this contract 
        require(IERC20(internalToken).allowance(msg.sender, address(this)) >= amountOutMin, "ALINT"); //BET: Check the internal token allowance. Use approve function.
        IERC20(internalToken).transferFrom(msg.sender, address(this), amountOutMin);

        if(betPosition == 1) // HOME
        {
            fixturePoolTeamHome[fixture] = SafeMath.safeAdd(fixturePoolTeamHome[fixture], amountOutMin);
        }
        else if(betPosition == 2) // AWAY
        {
            fixturePoolTeamAway[fixture] = SafeMath.safeAdd(fixturePoolTeamAway[fixture], amountOutMin);
        }
        else if(betPosition == 3) // DRAW
        {
            fixturePoolDraw[fixture] = SafeMath.safeAdd(fixturePoolDraw[fixture], amountOutMin);
        }


        emit OnBet(msg.sender, fixture, betPosition, chainWrapToken, amountInWei, amountOutMin);
    }

    /* **********************************************************
            SPORTS BET WITHDRAW
    *  **********************************************************/

    function winnerClaim(uint fixture, uint directInternalToken) external
    {
        require(fixtureMatchResultPosition[fixture] != 0, "LIVE"); //BET: Bet without result
        require(getFixtureCloseTimeLeft(fixture) == 0, "TIMELIVE"); //BET: Bet time not finished
        require(fixtureBetOpened[fixture] == 0, "OPENED"); //BET: Bet is opened
        require(fixturePlayerBetToken[fixture][msg.sender] != address(0), "NOTOKEN"); // BET: Without deposited token
        require(fixturePlayerBetPosition[fixture][msg.sender] != 0, "NOPOS"); // BET: No bet position
        require(fixturePlayerBetAmount[fixture][msg.sender] > 0, "NOVALUE");  // BET: No bet deposited value
        require(fixtureMatchResultPosition[fixture] == fixturePlayerBetPosition[fixture][msg.sender], "LOSE");  // BET: You are not the winner
        require(fixturePlayerClaimed[fixture][msg.sender] == 0, "ALREADYCLAIMED");  // BET: Claim already executed

        uint256 amountToReceiveInInternalTokenWithoutFee = getRewardValue(fixture, fixtureMatchResultPosition[fixture], fixturePlayerBetAmount[fixture][msg.sender]);
        uint256 amountToReceiveInInternalToken = getRewardValueWithTreasuryFee(fixture, fixtureMatchResultPosition[fixture], fixturePlayerBetAmount[fixture][msg.sender]);
        uint256 feeValue = SafeMath.safeSub(amountToReceiveInInternalTokenWithoutFee, amountToReceiveInInternalToken);
        uint256 participationAwardFromFree = getParticipationAwardValueFromFee(fixture, fixtureMatchResultPosition[fixture], fixturePlayerBetAmount[fixture][msg.sender]);
        
        uint256 receivedAmount = amountToReceiveInInternalToken;
        address receivedToken = internalToken;

        // Send internal token to player address
        systemWithdraw(msg.sender, internalToken, amountToReceiveInInternalToken, 0);

        // If there is any fee to send to feeto otherwise everything goes to participation award
        if(feeValue > participationAwardFromFree)
        {
            //Send fee to FeeTo address
            IERC20(internalToken).transfer(feeTo, SafeMath.safeSub(feeValue, participationAwardFromFree));
        }

        // If there is any participation award value to store in bag
        if(participationAwardFromFree > 0)
        {
            participationAwardAmount = SafeMath.safeAdd(participationAwardAmount, participationAwardFromFree);
        }

        // If player wants to receive in original deposit token, do swap
        if(directInternalToken == 0)
        {
            address claimToken = fixturePlayerBetToken[fixture][msg.sender];
            uint256 amountOutMin = getAmountOutMin(internalToken, claimToken, amountToReceiveInInternalToken);
            swap(internalToken, claimToken, amountToReceiveInInternalToken, amountOutMin, msg.sender);

            receivedAmount = amountOutMin;
            receivedToken = claimToken;
        }

        // Mark player as claimed player
        fixturePlayerClaimed[fixture][msg.sender] = 1;

        emit OnWinnerClaim(msg.sender, fixture, fixturePlayerBetPosition[fixture][msg.sender], receivedAmount, receivedToken);
    }

    function loserClaim(uint fixture, uint directInternalToken) external
    {
        require(fixtureMatchResultPosition[fixture] != 0, "LIVE"); //BET: Bet without result
        require(getFixtureCloseTimeLeft(fixture) == 0, "TIMELIVE"); //BET: Bet time not finished
        require(fixtureBetOpened[fixture] == 0, "OPENED"); //BET: Bet is opened
        require(fixturePlayerBetToken[fixture][msg.sender] != address(0), "NOTOKEN"); // BET: Without deposited token
        require(fixturePlayerBetPosition[fixture][msg.sender] != 0, "NOPOS"); // BET: No bet position
        require(fixturePlayerBetAmount[fixture][msg.sender] > 0, "NOVALUE");  // BET: No bet deposited value
        require(fixtureMatchResultPosition[fixture] != fixturePlayerBetPosition[fixture][msg.sender], "WIN");  // BET: You won, you must to use winnerClaim
        require(fixturePlayerClaimed[fixture][msg.sender] == 0, "ALREADYCLAIMED");  // BET: Claim already executed

        uint256 amountToReceiveInInternalToken = getParticipationAwardToClaim(fixture);
        
        uint256 receivedAmount = amountToReceiveInInternalToken;
        address receivedToken = internalToken;

        // Send internal token to player address
        systemWithdraw(msg.sender, internalToken, amountToReceiveInInternalToken, 0);

        // If player wants to receive in original deposit token, do swap
        if(directInternalToken == 0)
        {
            address claimToken = fixturePlayerBetToken[fixture][msg.sender];
            uint256 amountOutMin = getAmountOutMin(internalToken, claimToken, amountToReceiveInInternalToken);
            swap(internalToken, claimToken, amountToReceiveInInternalToken, amountOutMin, msg.sender);

            receivedAmount = amountOutMin;
            receivedToken = claimToken;
        }

        // Mark player as claimed player
        fixturePlayerClaimed[fixture][msg.sender] = 1;

        emit OnLoserClaim(msg.sender, fixture, fixturePlayerBetPosition[fixture][msg.sender], receivedAmount, receivedToken);
    }

    function systemWithdraw(address player, address token, uint256 amountInWei, uint isProxyToken) internal 
    {
        address tokenToProcess = token;
        if(isProxyToken == 1 && address(tokenToProcess) != chainWrapToken)
        {
            tokenToProcess = IERCProxy(token).implementation();
        }

        uint sourceBalance;
        if(address(tokenToProcess) != chainWrapToken)
        {
            //Balance in Token
            sourceBalance = IERC20(tokenToProcess).balanceOf(address(this));
        }
        else
        {
            //Balance in Network Coin
            sourceBalance = address(this).balance;
        }

        require(sourceBalance >= amountInWei, "LW"); //VAULT: Too low reserve to withdraw the requested amount

        //Withdraw of deposit value
        if(tokenToProcess != chainWrapToken)
        {
            //Withdraw token
            IERC20(tokenToProcess).transfer(player, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(player).transfer(amountInWei);
        }
    }

    /* **********************************************************
            SWAP FUNCTIONS
    *  **********************************************************/

    function swapNetworkCoinToToken(address _tokenOut, uint256 _amountOutMin, address _to) public payable
    {
        address[] memory path;
        path = new address[](2);
        path[0] = chainWrapToken;
        path[1] = _tokenOut;


        IUniswapV2Router(swapRouter).swapExactETHForTokens{value:msg.value}(_amountOutMin, path, _to, block.timestamp);
    }

    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) public 
    {
        if(_tokenIn != chainWrapToken)
        {
            require( IERC20(_tokenIn).balanceOf(msg.sender) >= _amountIn, "LOWSWAPBALANCE" ); //Low balance before swap

            //first we need to transfer the amount in tokens from the msg.sender to this contract
            //this contract will have the amount of in tokens
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
            //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
            //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
            IERC20(_tokenIn).approve(swapRouter, _amountIn);
        }

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;

        if (_tokenIn == chainWrapToken || _tokenOut == chainWrapToken) 
        {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } 
        else 
        {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = chainWrapToken;
            path[2] = _tokenOut;
        }

        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        if (_tokenOut == chainWrapToken)
        {
            IUniswapV2Router(swapRouter).swapExactTokensForETH(_amountIn, _amountOutMin, path, _to, block.timestamp);
        }
        else
        {
            IUniswapV2Router(swapRouter).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
        }

    }

    //this function will return the minimum amount from a swap
    //input the 3 parameters below and it will return the minimum amount out
    //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256) 
    {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == chainWrapToken || _tokenOut == chainWrapToken) 
        {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } 
        else 
        {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = chainWrapToken;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(swapRouter).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
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