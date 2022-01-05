/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TimelockStake
{
    uint256 ONE_HUNDRED = 100000000000000000000;
    uint256 ONE_YEAR = 31536000;

    address public owner;
    address public chainWrapToken;
    address public swapFactory;
    address public swapRouter;
    address public usdToken;

    uint private poolSeed;
    uint[] private pools;
    mapping(uint => uint) private poolOffchainId;
    mapping(uint => address) private poolStakingToken;
    mapping(uint => uint) private poolPeriod;
    mapping(uint => uint256) private poolAPR;
    mapping(uint => uint) private poolLocked;
    mapping(uint => uint) private poolDepositDisabled;
    mapping(uint => uint256) private poolStakedAmount;
    mapping(uint => address[]) private poolPlayers;
    
    mapping(uint => mapping(address => uint)) private isPoolPlayer;

    mapping(uint => mapping(address => uint256)) private playerStakedAmount; // Total of staked
    mapping(uint => mapping(address => uint256[])) private playerStakeRecordAmount; // Amount of Stake record
    mapping(uint => mapping(address => uint[])) private playerStakeRecordStartTime; // End Date of Stake record
    mapping(uint => mapping(address => uint[])) private playerStakeRecordEndTime; // End Date of Stake record

    constructor() 
    {
        owner = msg.sender;

        poolSeed = 1;

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
        POOL MANAGEMENT
    *  *****************************/
    function createPool(uint offchainId, address stakingToken, uint period, uint256 apr, uint locked) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        uint poolID = poolSeed;
        poolSeed++;

        pools.push(poolID);

        poolOffchainId[poolID] = offchainId;
        poolStakingToken[poolID] = stakingToken;
        poolPeriod[poolID] = period;
        poolAPR[poolID] = apr;
        poolLocked[poolID] = locked;
        poolDepositDisabled[poolID] = 0;
        poolStakedAmount[poolID] = 0;
        delete poolPlayers[poolID]; //Clear array
    }

    function setPoolDisabledDeposit(uint poolID, uint disabledValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID
        poolDepositDisabled[poolID] = disabledValue;
    }

    function setPoolOffchainId(uint poolID, uint offchainId) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID
        poolOffchainId[poolID] = offchainId;
    }

    function destroyPool(uint poolID) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID

        // Force Redeem/Withdraw
        for(uint ix = 0; ix < poolPlayers[poolID].length; ix++)
        {
            address player = poolPlayers[poolID][ix];

            if(playerStakedAmount[poolID][player] > 0)
            {
                // Withdraw playerStakedAmount[poolID][player] to player
                IERC20(poolStakingToken[poolID]).transfer(player, playerStakedAmount[poolID][player]);

                // Redeem tokens
                for(uint ixRecord = 0; ixRecord < playerStakeRecordAmount[poolID][player].length; ixRecord++)
                {
                    uint startTime = playerStakeRecordStartTime[poolID][player][ixRecord];
                    // uint expectedEndTime = playerStakeRecordEndTime[poolID][player][ixRecord];
                    uint forcedEndTime = block.timestamp;
                    uint256 stakePeriod = SafeMath.safeSub(forcedEndTime, startTime);
                    (, , uint256 redeemable) = getInterestReward(playerStakeRecordAmount[poolID][player][ixRecord], poolAPR[poolID], stakePeriod);
                    
                    IERC20(poolStakingToken[poolID]).transfer(player, redeemable);
                }

                // Reset pool player status
                isPoolPlayer[poolID][player] = 0;
                playerStakedAmount[poolID][player] = 0;

                // Clear player stake records
                delete playerStakeRecordAmount[poolID][player];
                delete playerStakeRecordStartTime[poolID][player];
                delete playerStakeRecordEndTime[poolID][player];

            }
        }

        // Reset mapping values
        poolOffchainId[poolID] = 0;
        poolStakingToken[poolID] = address(0);
        poolPeriod[poolID] = 0;
        poolAPR[poolID] = 0;
        poolLocked[poolID] = 0;
        poolDepositDisabled[poolID] = 0;
        poolStakedAmount[poolID] = 0;
        delete poolPlayers[poolID]; //Clear array

        // Remove from pools array
        for(uint ixToRemove = 0; ixToRemove < pools.length; ixToRemove++)
        {
            if(pools[ixToRemove] == poolID)
            {
                //Swap index to last
                uint poolsCount = pools.length;
                if(poolsCount > 1)
                {
                    pools[ixToRemove] = pools[poolsCount - 1];
                }

                //Delete dirty last
                if(poolsCount > 0)
                {
                    pools.pop();
                }

                break;
            }
        }

    }

    /* *****************************
        POOL READING
    *  *****************************/
    function getVaultBalance(address token) external view returns (uint256)
    {
        return IERC20(token).balanceOf(address(this));
    }

    function getPoolsSize() external view returns (uint)
    {
        return pools.length;
    }

    function getPoolByIndex(uint poolIndex) external view returns (uint256[] memory, address)
    {
        return getPool( pools[poolIndex] );
    }

    function getPool(uint poolID) public view returns (uint256[] memory, address)
    {
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID

        uint256[] memory resultNumbers = new uint256[](8);
        resultNumbers[0] = poolID; // Pool ID
        resultNumbers[1] = poolOffchainId[poolID]; // Offchain ID
        resultNumbers[2] = poolPeriod[poolID]; // Stake Period
        resultNumbers[3] = poolAPR[poolID]; // APR
        resultNumbers[4] = poolLocked[poolID]; // Locked Mode
        resultNumbers[5] = poolDepositDisabled[poolID]; // Deposit Disabled
        resultNumbers[6] = poolStakedAmount[poolID]; // Amount in stake
        resultNumbers[7] = poolPlayers[poolID].length; // Total of players

        return (resultNumbers, poolStakingToken[poolID]);
    }

    function getPlayerStake(uint poolID, address player) external view returns (uint256[] memory)
    {
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID

        uint256[] memory resultNumbers = new uint256[](2);

        if(isPoolPlayer[poolID][player] == 0)
        {
            return resultNumbers;
        }

        resultNumbers[0] = playerStakedAmount[poolID][player]; // Total of staked
        resultNumbers[1] = playerStakeRecordAmount[poolID][player].length; // Total of stake records

        return resultNumbers;
    }

    function getPlayerStakeRecord(uint poolID, address player, uint index) external view returns (uint256[] memory)
    {
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID

        uint256[] memory resultNumbers = new uint256[](6);

        if(isPoolPlayer[poolID][player] == 0)
        {
            return resultNumbers;
        }

        if(playerStakeRecordAmount[poolID][player].length == 0)
        {
            return resultNumbers;
        }

        resultNumbers[0] = index < playerStakeRecordAmount[poolID][player].length ? playerStakeRecordAmount[poolID][player][index] : 0; // Amount in record
        resultNumbers[1] = index < playerStakeRecordStartTime[poolID][player].length ? playerStakeRecordStartTime[poolID][player][index] : 0; // Start time
        resultNumbers[2] = index < playerStakeRecordEndTime[poolID][player].length ? playerStakeRecordEndTime[poolID][player][index] : 0; // End time
        resultNumbers[3] = index < playerStakeRecordEndTime[poolID][player].length ? getPlayerStakeRecordLockedToWithdraw(poolID, player, index) : 1; // Locked to withdraw

        uint256 redeemableForNow;
        uint256 redeemableForEnd;
        uint startTime = playerStakeRecordStartTime[poolID][player][index];
        uint expectedEndTime = playerStakeRecordEndTime[poolID][player][index];
        uint forcedEndTime = block.timestamp;
        
        uint256 stakePeriodForNow = SafeMath.safeSub(forcedEndTime, startTime);
        (, ,redeemableForNow) = getInterestReward(playerStakeRecordAmount[poolID][player][index], poolAPR[poolID], stakePeriodForNow);

        uint256 stakePeriodForEnd = SafeMath.safeSub(expectedEndTime, startTime);
        (, ,redeemableForEnd) = getInterestReward(playerStakeRecordAmount[poolID][player][index], poolAPR[poolID], stakePeriodForEnd);
        
        resultNumbers[4] = index < playerStakeRecordEndTime[poolID][player].length ? redeemableForNow : 0; // Earned for now
        resultNumbers[5] = index < playerStakeRecordEndTime[poolID][player].length ? redeemableForEnd : 0; // Earned for end

        return resultNumbers;
    }

    function getPlayerStakeRecordLockedToWithdraw(uint poolID, address player, uint index) public view returns (uint)
    {
        if(poolLocked[poolID] == 0)
        {
            return 0;
        }

        uint expectedEndTime = playerStakeRecordEndTime[poolID][player][index];

        if(block.timestamp >= expectedEndTime)
        {
            return 0;
        }

        return 1;

    }

    function getPlayerIsInPool(uint poolID, address player) external view returns (uint)
    {
        return isPoolPlayer[poolID][player];
    }

    function getPoolPlayerByIndex(uint poolID, uint index) external view returns (address)
    {
        return poolPlayers[poolID][index];
    }

    function getInterestReward(uint256 stakedAmount, uint256 apr, uint stakePeriod) public view returns (uint256, uint256, uint256)
    {
        uint256 annualReward = SafeMath.safeDiv(SafeMath.safeMul(stakedAmount, apr), ONE_HUNDRED);
        uint256 amountInYears = SafeMath.safeDivFloat(stakePeriod, ONE_YEAR, 18);
        uint256 reward = SafeMath.safeMulFloat(annualReward, amountInYears, 18);
        
        return (annualReward, amountInYears, reward);
    }

    /* *****************************
        POOL PLAYER SET
    *  *****************************/
    function poolStakeDeposit(uint poolID, uint amount) external
    {
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID
        require(poolPeriod[poolID] > 0, "InvPPeriod"); // Invalid Pool Period
        require(poolDepositDisabled[poolID] == 0, "Disabled"); // Pool Deposit Disabled 

        //Approve (outside): allowed[msg.sender][spender] (sender = my account, spender = stake token address)
        uint256 allowance = IERC20(poolStakingToken[poolID]).allowance(msg.sender, address(this));
        require(allowance >= amount, "AL"); //STAKE: Check the token allowance. Use approve function.

        // Update Pool Information
        poolStakedAmount[poolID] = SafeMath.safeAdd(poolStakedAmount[poolID], amount);

        // Update Player Information
        playerStakedAmount[poolID][msg.sender] = SafeMath.safeAdd(playerStakedAmount[poolID][msg.sender], amount);

        // Record generation
        playerStakeRecordAmount[poolID][msg.sender].push(amount);
        playerStakeRecordStartTime[poolID][msg.sender].push(block.timestamp);
        playerStakeRecordEndTime[poolID][msg.sender].push( SafeMath.safeAdd(block.timestamp, poolPeriod[poolID] ) );

        // Set player as pool player
        if(isPoolPlayer[poolID][msg.sender] == 0)
        {
            poolPlayers[poolID].push(msg.sender);
            isPoolPlayer[poolID][msg.sender] = 1;
        }

        // Receive deposit token value
        IERC20(poolStakingToken[poolID]).transferFrom(msg.sender, address(this), amount);
    }

    function poolStakeWithdraw(uint poolID, uint poolRecordIndex) external
    {
        _poolStakeWithdraw(poolID, poolRecordIndex, msg.sender);
    }

    function _poolStakeWithdraw(uint poolID, uint poolRecordIndex, address player) internal
    {
        require(poolStakingToken[poolID] != address(0), "InvPId"); // Invalid Pool ID
        require(poolPeriod[poolID] > 0, "InvPPeriod"); // Invalid Pool Period
        require(isPoolPlayer[poolID][player] == 1, "NotInStake"); // Not in Stake
        require(playerStakeRecordAmount[poolID][player].length > 0, "NoRecords"); // No Stake Records
        require(poolRecordIndex < playerStakeRecordAmount[poolID][player].length, "InvIndex"); // Invalid Record Index

        uint256 amountToUnstake = playerStakeRecordAmount[poolID][player][poolRecordIndex];
        require(amountToUnstake > 0, "EmptyRecord"); // Empty Record

        uint expectedEndTime = playerStakeRecordEndTime[poolID][player][poolRecordIndex];
        if(poolLocked[poolID] == 1)
        {
            require(block.timestamp >= expectedEndTime, "Locked"); // Locked Stake Record
        }

        // Update Pool Information
        poolStakedAmount[poolID] = SafeMath.safeSub(poolStakedAmount[poolID], amountToUnstake);

        // Update Player Information
        playerStakedAmount[poolID][player] = SafeMath.safeSub(playerStakedAmount[poolID][player], amountToUnstake);

        // Get stake start time before record clean
        uint startTime = playerStakeRecordStartTime[poolID][player][poolRecordIndex];

        // Record removal
        removeStakeRecord(poolID, player, poolRecordIndex);

        // Remove user as player if user is no longer in pool stake
        if(playerStakeRecordAmount[poolID][player].length == 0)
        {
            isPoolPlayer[poolID][player] = 0;
            removePlayerFromPool(poolID, player);
        }

        // Withdraw amountToUnstake to player
        IERC20(poolStakingToken[poolID]).transfer(player, amountToUnstake);

        // Redeem tokens
        uint occuredEndTime = block.timestamp;
        uint256 stakePeriod = SafeMath.safeSub(occuredEndTime, startTime);
        (, , uint256 redeemable) = getInterestReward(amountToUnstake, poolAPR[poolID], stakePeriod);
        IERC20(poolStakingToken[poolID]).transfer(player, redeemable);
    }

    function removeStakeRecord(uint poolID, address player, uint index) internal
    {
        uint count = playerStakeRecordAmount[poolID][player].length;

        // ***** REMOVE playerStakeRecordAmount record
        // Swap index to last
        if(count > 1)
        {
            playerStakeRecordAmount[poolID][player][index] = playerStakeRecordAmount[poolID][player][count - 1];
            playerStakeRecordStartTime[poolID][player][index] = playerStakeRecordStartTime[poolID][player][count - 1];
            playerStakeRecordEndTime[poolID][player][index] = playerStakeRecordEndTime[poolID][player][count - 1];
        }

        // Delete dirty last
        if(count > 0)
        {
            playerStakeRecordAmount[poolID][player].pop();
            playerStakeRecordStartTime[poolID][player].pop();
            playerStakeRecordEndTime[poolID][player].pop();
        }
    }

    function removePlayerFromPool(uint poolID, address player) internal
    {
        uint count = poolPlayers[poolID].length;

        for(uint ix = 0; ix < count; ix++)
        {
            if(poolPlayers[poolID][ix] == player)
            {
                // Swap index to last
                if(count > 1)
                {
                    poolPlayers[poolID][ix] = poolPlayers[poolID][count - 1];
                }

                // Delete dirty last
                if(count > 0)
                {
                    poolPlayers[poolID].pop();
                }

                break;
            }
        }
    }

    /* *****************************
        SUDO
    *  *****************************/

    function forcePlayerToWithdraw(uint poolID, uint poolRecordIndex, address player) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        _poolStakeWithdraw(poolID, poolRecordIndex, player);
    }

    function forcePlayerToWithdrawWholePool(uint poolID, address player) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        uint poolSize = playerStakeRecordAmount[poolID][player].length;

        if(poolSize == 0)
        {
            return;
        }

        for(uint ixRecord = 0; ixRecord < poolSize; ixRecord++)
        {
            _poolStakeWithdraw(poolID, 0, player); //Always remove from first (zero index)
        }
    }

    function transferFund(address token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Withdraw token
        IERC20(token).transfer(to, amountInWei);
    }

    function transferNetworkCoinFund(address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Withdraw Network Coin
        payable(to).transfer(amountInWei);
    }

    function erasePlayerDataInPool(uint poolID, address player) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        
        poolStakedAmount[poolID] = SafeMath.safeSub(poolStakedAmount[poolID], playerStakedAmount[poolID][player]);

        // Reset pool player status
        isPoolPlayer[poolID][player] = 0;
        playerStakedAmount[poolID][player] = 0;

        // Clear player stake records
        delete playerStakeRecordAmount[poolID][player];
        delete playerStakeRecordStartTime[poolID][player];
        delete playerStakeRecordEndTime[poolID][player];

        // Remove user from pool player list
        removePlayerFromPool(poolID, player);
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

    function setUSDToken(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        usdToken = newValue;
    }


    /* **********************************************************
            SWAP FUNCTIONS
    *  **********************************************************/

    function getUSDPrice(address token, uint256 amount, uint multihopWithWrapToken) external view returns (uint256)
    {
        uint256 result = getAmountOutMin(token, usdToken, amount, multihopWithWrapToken);
        return result;
    }

    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn, uint multihopWithWrapToken) public view returns (uint256) 
    {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == chainWrapToken || _tokenOut == chainWrapToken || multihopWithWrapToken == 0) 
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