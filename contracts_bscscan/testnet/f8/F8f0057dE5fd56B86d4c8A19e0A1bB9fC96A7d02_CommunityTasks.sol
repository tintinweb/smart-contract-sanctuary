/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract CommunityTasks
{
    uint256 ONE_HUNDRED = 100000000000000000000;

    address public owner;
    address public chainWrapToken;
    address public swapFactory;
    address public swapRouter;
    address public internalToken;
    address public usdToken;
    address public backendSetter;

    uint public leaderboardLength;
    mapping (uint => address) public leaderboard;
    
    // uint256 public bag;

    // Player => social network => social network user id
    mapping(address => mapping(uint => string)) private playerSocialNetworkId;

    // Player => task => timestamp to expire
    mapping(address => mapping(uint => uint)) private playerTaskExpiration;

    // Player => task => task completed (0 = false | 1 = true)
    mapping(address => mapping(uint => uint)) private playerTaskCompleted;

    // Player => task => task claimed (0 = false | 1 = true)
    mapping(address => mapping(uint => uint)) private playerTaskClaimed;

    // Player => claimed amount
    mapping(address => uint256) private playerClaimedAmount;

    // Player => claimed amount in USD
    mapping(address => uint256) private playerClaimedAmountInUSD;

    // Player => claim time history
    mapping(address => uint[]) private playerClaimTimeHistory;

    // Player => claim using internal token history
    mapping(address => uint[]) private playerClaimUsingInternalTokenHistory;

    // Player => claim amount history
    mapping(address => uint256[]) private playerClaimAmountHistory;

    // Player => claim amount in USD history
    mapping(address => uint256[]) private playerClaimAmountInUSDHistory;

    // Player => claim task history
    mapping(address => uint[]) private playerClaimTaskHistory;

    // Task => percent amount
    mapping(uint => uint256) private taskPaymentPercentOfBag;

    // Task => Recurrent
    mapping(uint => uint) private taskRecurrent;

    constructor() 
    {
        owner = msg.sender;
        backendSetter = owner;
        leaderboardLength = 20;

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



        /*
        56: BUSD
        137: PUSD
        1: BUSD Ethereum
        43114: USDT
        97: BUSD testnet
        */
        usdToken = block.chainid == 56 ?        address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) : 
                    (block.chainid == 137 ?     address(0x9aF3b7DC29D3C4B1A5731408B6A9656fA7aC3b72) : 
                    (block.chainid == 1 ?       address(0x4Fabb145d64652a948d72533023f6E7A623C7C53) : 
                    (block.chainid == 43114 ?   address(0xde3A24028580884448a5397872046a019649b084) : 
                    (block.chainid == 97 ?      address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee) : 
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

    // function supplyBag(uint256 amountInWei) external
    // {
    //     require(msg.sender == owner, 'FN'); //Forbidden

    //     require(IERC20(internalToken).allowance(msg.sender, address(this)) >= amountInWei, "ALINT"); //BET: Check the internal token allowance. Use approve function.
    //     IERC20(internalToken).transferFrom(msg.sender, address(this), amountInWei);
    //     // bag = SafeMath.safeAdd(bag, amountInWei);
    // }

    function getBag() external view returns (uint256)
    {
        return IERC20(internalToken).balanceOf(address(this));
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

    /* *****************************
            COMMON FUNCTIONS
    *  *****************************/

    function setOwner(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        owner = newValue;
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

    function setUSDToken(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        usdToken = newValue;
    }

    function setBackendSetter(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        backendSetter = newValue;
    }

    function setLeaderboardLength(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        leaderboardLength = newValue;
    }

    function updateLeaderboardScore(address player) private
    {
        // if the score is too low, don't update
        if ( playerClaimedAmount[leaderboard[leaderboardLength-1]]  >= playerClaimedAmount[msg.sender]) return;

        // loop through the leaderboard
        for (uint ix = 0; ix < leaderboardLength; ix++) 
        {
            // find where to insert the new score
            if ( playerClaimedAmount[leaderboard[ix]] < playerClaimedAmount[msg.sender]) 
            {
                // shift leaderboard
                address currentUser = leaderboard[ix];
                for (uint jx = ix+1; jx < leaderboardLength+1; jx++) 
                {
                    address nextUser = leaderboard[jx];
                    leaderboard[jx] = currentUser;
                    currentUser = nextUser;
                }

                // insert
                leaderboard[ix] = player;

                // delete last from list
                delete leaderboard[leaderboardLength];
            }
        }
    }

    function getTaskPaymentPercentOfBag(uint task) external view returns (uint256)
    {
        return taskPaymentPercentOfBag[task];
    }

    function setTaskPaymentPercentOfBag(uint task, uint256 percentValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        taskPaymentPercentOfBag[task] = percentValue;
    }

    function getTaskRecurrent(uint task) external view returns (uint256)
    {
        return taskRecurrent[task];
    }

    function setTaskRecurrent(uint task, uint recurrentValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        taskRecurrent[task] = recurrentValue;
    }

    function getTaskOnchainData(uint task) external view returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](2);

        result[0] = taskPaymentPercentOfBag[task];
        result[1] = taskRecurrent[task];

        return result;
    }

    /* *****************************
            PLAYER FUNCTIONS
    *  *****************************/
    function setSocialNetworkId(uint socialNetwork, string memory newValue) external
    {
        playerSocialNetworkId[msg.sender][socialNetwork] = newValue;
    }

    function getSocialNetworkId(uint socialNetwork) external view returns (string memory)
    {
        return playerSocialNetworkId[msg.sender][socialNetwork];
    }

    function getPlayerTaskClaimed(uint task) external view returns (uint)
    {
        return playerTaskClaimed[msg.sender][task];
    }

    function getPlayerTaskExpiration(uint task) external view returns (uint)
    {
        return playerTaskExpiration[msg.sender][task];
    }

    function getPlayerClaimedAmount() external view returns (uint256)
    {
        return playerClaimedAmount[msg.sender];
    }

    function getPlayerClaimedAmountInUSD() external view returns (uint256)
    {
        return playerClaimedAmountInUSD[msg.sender];
    }

    function getPlayerTaskCompleted(uint task) external view returns (uint)
    {
        return playerTaskCompleted[msg.sender][task];
    }

    function getPlayerTaskOnchainData(uint task) external view returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](3);

        result[0] = playerTaskCompleted[msg.sender][task];
        result[1] = playerTaskExpiration[msg.sender][task];
        result[2] = playerTaskClaimed[msg.sender][task];

        return result;
    }


    function claim(uint task, uint directInternalToken) external
    {
        require(playerTaskExpiration[msg.sender][task] != 0, "INACTIVE"); //Inactive task
        require(block.timestamp <= playerTaskExpiration[msg.sender][task], "TIMEOVER"); //Task time over
        require(playerTaskCompleted[msg.sender][task] == 1, "UNFINISHED"); //Unfinished task
        require(playerTaskClaimed[msg.sender][task] == 0, "CLAIMED"); //Unfinished task

        uint256 bag = IERC20(internalToken).balanceOf(address(this));
        uint256 amountToReceiveInInternalToken = SafeMath.safeDiv(SafeMath.safeMul(bag, taskPaymentPercentOfBag[task]), ONE_HUNDRED);
        
        // Send internal token to player address
        systemWithdraw(msg.sender, internalToken, amountToReceiveInInternalToken, 0);

        uint256 usdAmountOutMin = getAmountOutMin(internalToken, usdToken, amountToReceiveInInternalToken);

        // If player wants to receive in original deposit token, do swap
        if(directInternalToken == 0)
        {
            swap(internalToken, usdToken, amountToReceiveInInternalToken, usdAmountOutMin, msg.sender);
        }

        playerClaimedAmount[msg.sender] = SafeMath.safeAdd(playerClaimedAmount[msg.sender], amountToReceiveInInternalToken);
        playerClaimedAmountInUSD[msg.sender] = SafeMath.safeAdd(playerClaimedAmountInUSD[msg.sender], usdAmountOutMin);

        playerClaimTimeHistory[msg.sender].push(block.timestamp);
        playerClaimUsingInternalTokenHistory[msg.sender].push(directInternalToken);
        playerClaimAmountHistory[msg.sender].push(amountToReceiveInInternalToken);
        playerClaimAmountInUSDHistory[msg.sender].push(usdAmountOutMin);
        playerClaimTaskHistory[msg.sender].push(task);

        playerTaskClaimed[msg.sender][task] = 1;

        updateLeaderboardScore(msg.sender);
    }

    function getClaimHistorySize(address player) external view returns (uint)
    {
        return playerClaimTimeHistory[player].length;
    }

    function getClaimHistory(address player, uint index) external view returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](5);

        result[0] = playerClaimTimeHistory[player][index];
        result[1] = playerClaimUsingInternalTokenHistory[player][index];
        result[2] = playerClaimAmountHistory[player][index];
        result[3] = playerClaimAmountInUSDHistory[player][index];
        result[4] = playerClaimTaskHistory[player][index];

        return result;
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

    /* *****************************
            BACKEND FUNCTIONS
    *  *****************************/
    function setupPlayerTask(uint task, address player, uint amountInSeconds) external
    {
        require(msg.sender == owner || msg.sender == backendSetter, 'FN'); //Forbidden
        require(block.timestamp > playerTaskExpiration[player][task], "RUNNING"); //Task is running

        // Completed tasks must be marked as Recurrent to be reapplied
        if(playerTaskCompleted[player][task] == 1)
        {
            require(taskRecurrent[task] == 1, 'NOTRECURRENT');
        }

        playerTaskExpiration[player][task] = SafeMath.safeAdd(block.timestamp, amountInSeconds);
        playerTaskClaimed[player][task] = 0;
        playerTaskCompleted[player][task] = 0;
    }

    function setPlayerTaskExpiration(uint task, address player, uint amountInSeconds) external
    {
        require(msg.sender == owner || msg.sender == backendSetter, 'FN'); //Forbidden

        playerTaskExpiration[player][task] = SafeMath.safeAdd(block.timestamp, amountInSeconds);
    }

    function setPlayerTaskCompleted(uint task, address player, uint value) external
    {
        require(msg.sender == owner || msg.sender == backendSetter, 'FN'); //Forbidden

        playerTaskCompleted[player][task] = value;
    }




}


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