/*
@website https://boogie.finance
@authors Proof, sol_dev, Zoma, Mr Fahrenheit, Boogie
@auditors Aegis DAO, Sherlock Security
*/

pragma solidity ^0.6.12;

import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './IUniswapV2Router02.sol';
import './BOOGIE.sol';
import './Rave.sol';


contract Bar is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 staked; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 uniRewardDebt; // UNI staking reward debt. See explanation below.
        uint256 claimed; // Tracks the amount of BOOGIE claimed by the user.
        uint256 uniClaimed; // Tracks the amount of UNI claimed by the user.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        IERC20 lpToken; // Address of LP token contract.
        uint256 apr; // Fixed APR for the pool. Determines how many BOOGIEs to distribute per block.
        uint256 lastBoogieRewardBlock; // Last block number that BOOGIE rewards were distributed.
        uint256 accBoogiePerShare; // Accumulated BOOGIEs per share, times 1e12. See below.
        uint256 accUniPerShare; // Accumulated UNIs per share, times 1e12. See below.
        address uniStakeContract; // Address of UNI staking contract (if applicable).
    }

    // We do some fancy math here. Basically, any point in time, the amount of BOOGIEs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.staked * pool.accBoogiePerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accBoogiePerShare` (and `lastBoogieRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `staked` amount gets updated.
    //   4. User's `rewardDebt` gets updated.

    // The BOOGIE TOKEN!
    BOOGIE public boogie;
    // The address of the BOOGIE-ETH Uniswap pool
    address public boogiePoolAddress;
     // The Rave staking contract
    Rave public rave;
    // The Uniswap v2 Router
    IUniswapV2Router02 internal uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // The UNI Staking Rewards Factory
    // Most code related to UNI staking was removed due to the end of UNI staking
    // I was planning on implementing SUSHI staking at one point, but decided not to because income would be fairly minimal
    //StakingRewardsFactory internal uniStakingFactory = StakingRewardsFactory(0x3032Ab3Fa8C01d786D29dAdE018d7f2017918e12);
    // The UNI Token
    //IERC20 internal uniToken = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    // The WETH Token
    IERC20 internal weth;

    // Dev address, commented out since the dev cut for staking was removed
    //address payable public devAddress;

    // Contract where the tokens allocated for the referral bonus will be sent
    address public referralAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => bool) public existingPools;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Mapping of whitelisted contracts so that certain contracts like the Aegis pool can interact with the Bar contract
    mapping(address => bool) public contractWhitelist;
    // The block number when BOOGIE mining starts.
    uint256 public startBlock;
    // Becomes true once the BOOGIE-ETH Uniswap is created (no sooner than 500 blocks after launch)
    bool public boogiePoolActive = false;
    // The staking fees collected during the first 500 blocks will seed the BOOGIE-ETH Uniswap pool
    uint256 public initialBoogiePoolETH  = 0;
    // 10% of every deposit into any secondary pool (not BOOGIE-ETH) will be converted to BOOGIE (on Uniswap) and sent to the Rave staking contract which becomes active and starts distributing the accumulated BOOGIE to stakers once the max supply is hit
    uint256 public boogieSentToRave = 0;

    //Removed donation stuff
    //uint256 public donatedETH = 0;
    //uint256 internal constant minimumDonationAmount = 25 * 10**18;
    //mapping(address => address) internal donaters;
    //mapping(address => uint256) internal donations;

    // Approximate number of blocks per year - assumes 13 second blocks
    uint256 internal constant APPROX_BLOCKS_PER_YEAR  = uint256(uint256(365 days) / uint256(13 seconds));
    // The default APR for each pool will be 1,000%
    uint256 internal constant DEFAULT_APR = 1000;
    // There will be a 1000 block Soft Launch in which BOOGIE is minted to each pool at a static rate to make the start as fair as possible
    uint256 internal constant SOFT_LAUNCH_DURATION = 1000;
    // During the Soft Launch, all pools except for the BOOGIE-ETH pool will mint 20 BOOGIE per block. Once it's activated, the BOOGIE-ETH pool will mint the same amount of BOOGIE per block as all of the other pools combined until the end of the Soft Launch
    uint256 internal constant SOFT_LAUNCH_BOOGIE_PER_BLOCK = 20 * 10**18;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 boogieAmount, uint256 uniAmount);
    event ClaimAll(address indexed user, uint256 boogieAmount, uint256 uniAmount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event BoogieBuyback(address indexed user, uint256 ethSpentOnBoogie, uint256 boogieBought);
    event BoogiePoolActive(address indexed user, uint256 boogieLiquidity, uint256 ethLiquidity);

    constructor(
        BOOGIE _boogie,
        //address payable _devAddress,
        uint256 _startBlock
    ) public {
        boogie = _boogie;
        //devAddress = _devAddress;
        startBlock = _startBlock;
        weth = IERC20(uniswapRouter.WETH());

        // Calculate the address the BOOGIE-ETH Uniswap pool will exist at
        address uniswapfactoryAddress = uniswapRouter.factory();
        address boogieAddress = address(boogie);
        address wethAddress = address(weth);

        // token0 must be strictly less than token1 by sort order to determine the correct address
        (address token0, address token1) = boogieAddress < wethAddress ? (boogieAddress, wethAddress) : (wethAddress, boogieAddress);

        boogiePoolAddress = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            uniswapfactoryAddress,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        ))));

        _addInitialPools();
    }
    
    receive() external payable {}

    // Internal function to add a new LP Token pool
    function _addPool(address _token, address _lpToken) internal {

        uint256 apr = DEFAULT_APR;
        if (_token == address(boogie)) apr = apr * 5;

        uint256 lastBoogieRewardBlock = block.number > startBlock ? block.number : startBlock;

        poolInfo.push(
            PoolInfo({
                token: IERC20(_token),
                lpToken: IERC20(_lpToken),
                apr: apr,
                lastBoogieRewardBlock: lastBoogieRewardBlock,
                accBoogiePerShare: 0,
                accUniPerShare: 0,
                uniStakeContract: address(0)
            })
        );

        existingPools[_lpToken] = true;
    }

    // Internal function that adds all of the pools that will be available at launch. Called by the constructor
    function _addInitialPools() internal {

        _addPool(address(boogie), boogiePoolAddress); // BOOGIE-ETH

        //Removed 6 pools due to their low liquidity (or getting hacked, in the case of PICKLE)
        _addPool(0xdAC17F958D2ee523a2206206994597C13D831ec7, 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852); // ETH-USDT
        _addPool(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11); // DAI-ETH
        _addPool(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc); // USDC-ETH
        _addPool(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940); // WBTC-ETH
        _addPool(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xd3d2E2692501A5c9Ca623199D38826e513033a17); // UNI-ETH
        _addPool(0x514910771AF9Ca656af840dff83E8264EcF986CA, 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974); // LINK-ETH
        _addPool(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, 0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f); // AAVE-ETH
        _addPool(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F, 0x43AE24960e5534731Fc831386c07755A2dc33D47); // SNX-ETH
        _addPool(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, 0xC2aDdA861F89bBB333c90c492cB837741916A225); // MKR-ETH
        _addPool(0xc00e94Cb662C3520282E6f5717214004A7f26888, 0xCFfDdeD873554F362Ac02f8Fb1f02E5ada10516f); // COMP-ETH
        _addPool(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, 0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28); // YFI-ETH
        _addPool(0xba100000625a3754423978a60c9317c58a424e3D, 0xA70d458A4d9Bc0e6571565faee18a48dA5c0D593); // BAL-ETH
        _addPool(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b, 0x4d5ef58aAc27d99935E5b6B4A6778ff292059991); // DPI-ETH
        _addPool(0xD46bA6D942050d489DBd938a2C909A5d5039A161, 0xc5be99A02C6857f9Eac67BbCE58DF5572498F40c); // AMPL-ETH
        _addPool(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39, 0x55D5c232D921B9eAA6b37b5845E439aCD04b4DBa); // HEX-ETH
        _addPool(0x93ED3FBe21207Ec2E8f2d3c3de6e058Cb73Bc04d, 0x343FD171caf4F0287aE6b87D75A8964Dc44516Ab); // PNK-ETH
        //_addPool(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5, 0xdc98556Ce24f007A5eF6dC1CE96322d65832A819); // PICKLE-ETH
        _addPool(0x84294FC9710e1252d407d3D80A84bC39001bd4A8, 0x0C5136B5d184379fa15bcA330784f2d5c226Fe96); // NUTS-ETH
        //_addPool(0x821144518dfE9e7b44fCF4d0824e15e8390d4637, 0x490B5B2489eeFC4106C69743F657e3c4A2870aC5); // ATIS-ETH
        //_addPool(0xB9464ef80880c5aeA54C7324c0b8Dd6ca6d05A90, 0xa8D0f6769AB020877f262D8Cd747c188D9097d7E); // LOCK-ETH
        //_addPool(0x926dbD499d701C61eABe2d576e770ECCF9c7F4F3, 0xC7c0EDf0b5f89eff96aF0E31643Bd588ad63Ea23); // aDAO-ETH
        //_addPool(0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E, 0x260E069deAd76baAC587B5141bB606Ef8b9Bab6c); // SHUF-ETH
        //_addPool(0x9720Bcf5a92542D4e286792fc978B63a09731CF0, 0x08538213596fB2c392e9c5d4935ad37645600a57); // OTBC-ETH
        _addPool(0xEEF9f339514298C6A857EfCfC1A762aF84438dEE, 0x23d15EDceb5B5B3A23347Fa425846DE80a2E8e5C); // HEZ-ETH
        
    }

    // Get the pending BOOGIEs for a user from 1 pool
    function _pendingBoogie(uint256 _pid, address _user) internal view returns (uint256) {
        if (_pid == 0 && boogiePoolActive != true) return 0;

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accBoogiePerShare = pool.accBoogiePerShare;
        uint256 lpSupply = _getPoolSupply(_pid);

        if (block.number > pool.lastBoogieRewardBlock && lpSupply != 0) {
            uint256 boogieReward = _calculateBoogieReward(_pid, lpSupply);

            // Make sure that boogieReward won't push the total supply of BOOGIE past boogie.MAX_SUPPLY()
            uint256 boogieTotalSupply = boogie.totalSupply();
            if (boogieTotalSupply.add(boogieReward) >= boogie.MAX_SUPPLY()) {
                boogieReward = boogie.MAX_SUPPLY().sub(boogieTotalSupply);
            }

            accBoogiePerShare = accBoogiePerShare.add(boogieReward.mul(1e12).div(lpSupply));
        }

        return user.staked.mul(accBoogiePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Calculate the current boogieReward for a specific pool
    function _calculateBoogieReward(uint256 _pid, uint256 _lpSupply) internal view returns (uint256 boogieReward) {
        
        if (boogie.maxSupplyHit() != true) {

            PoolInfo memory pool = poolInfo[_pid];

            uint256 multiplier = block.number - pool.lastBoogieRewardBlock;
                
            // There will be a 1000 block Soft Launch where BOOGIE is minted at a static rate to make things as fair as possible
            if (block.number < startBlock + SOFT_LAUNCH_DURATION) {

                // The BOOGIE-ETH pool isn't active until the Uniswap pool is created, which can't happen until at least 500 blocks have passed. Once active, it mints 500 BOOGIE per block (the same amount of BOOGIE per block as all of the other pools combined) until the Soft Launch ends
                if (_pid != 0) {
                    // For the first 1000 blocks, give 20 BOOGIE per block to all other pools that have staked LP tokens
                    boogieReward = multiplier * SOFT_LAUNCH_BOOGIE_PER_BLOCK;
                } else if (boogiePoolActive == true) {
                    boogieReward = multiplier * 25 * SOFT_LAUNCH_BOOGIE_PER_BLOCK;
                }
            
            } else if (_pid != 0 && boogiePoolActive != true) {
                // Keep minting 20 tokens per block since the Soft Launch is over but the BOOGIE-ETH pool still isn't active (would only be due to no one calling the activateBoogiePool function)
                boogieReward = multiplier * SOFT_LAUNCH_BOOGIE_PER_BLOCK;
            } else if (boogiePoolActive == true) { 
                // Afterwards, give boogieReward based on the pool's fixed APR.
                // Fast low gas cost way of calculating prices since this can be called every block.
                uint256 boogiePrice = _getBoogiePrice();
                uint256 lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / pool.lpToken.totalSupply(); 
                uint256 scaledTotalLiquidityValue = _lpSupply * lpTokenPrice;
                boogieReward = multiplier * ((pool.apr * scaledTotalLiquidityValue / boogiePrice) / APPROX_BLOCKS_PER_YEAR) / 100;
            }

        }

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Internal view function to get all of the stored data for a single pool
    function _getPoolData(uint256 _pid) internal view returns (address, address, bool, uint256, uint256, uint256, uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        return (address(pool.token), address(pool.lpToken), pool.uniStakeContract != address(0), pool.apr, pool.lastBoogieRewardBlock, pool.accBoogiePerShare, pool.accUniPerShare);
    }

    // View function to see all of the stored data for every pool on the frontend
    function _getAllPoolData() internal view returns (address[] memory, address[] memory, bool[] memory, uint[] memory, uint[] memory, uint[2][] memory) {
        uint256 length = poolInfo.length;
        address[] memory tokenData = new address[](length);
        address[] memory lpTokenData = new address[](length);
        bool[] memory isUniData = new bool[](length);
        uint[] memory aprData = new uint[](length);
        uint[] memory lastBoogieRewardBlockData = new uint[](length);
        uint[2][] memory accTokensPerShareData = new uint[2][](length);

        for (uint256 pid = 0; pid < length; ++pid) {
            (tokenData[pid], lpTokenData[pid], isUniData[pid], aprData[pid], lastBoogieRewardBlockData[pid], accTokensPerShareData[pid][0], accTokensPerShareData[pid][1]) = _getPoolData(pid);
        }

        return (tokenData, lpTokenData, isUniData, aprData, lastBoogieRewardBlockData, accTokensPerShareData);
    }

    // Internal view function to get all of the extra data for a single pool
    function _getPoolMetadataFor(uint256 _pid, address _user, uint256 _boogiePrice) internal view returns (uint[17] memory poolMetadata) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 totalSupply;
        uint256 totalLPSupply;
        uint256 stakedLPSupply;
        uint256 tokenPrice;
        uint256 lpTokenPrice;
        uint256 totalLiquidityValue;
        uint256 boogiePerBlock;

        if (_pid != 0 || boogiePoolActive == true) {
            totalSupply = pool.token.totalSupply();
            totalLPSupply = pool.lpToken.totalSupply();
            stakedLPSupply = _getPoolSupply(_pid);

            tokenPrice = 10**uint256(pool.token.decimals()) * weth.balanceOf(address(pool.lpToken)) / pool.token.balanceOf(address(pool.lpToken));
            lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / totalLPSupply; 
            totalLiquidityValue = stakedLPSupply * lpTokenPrice / 1e18;
        }

        // Only calculate with fixed apr after the Soft Launch
        if (block.number >= startBlock + SOFT_LAUNCH_DURATION) {
            boogiePerBlock = ((pool.apr * 1e18 * totalLiquidityValue / _boogiePrice) / APPROX_BLOCKS_PER_YEAR) / 100;
        } else {
            if (_pid != 0) {
                boogiePerBlock = SOFT_LAUNCH_BOOGIE_PER_BLOCK;
            } else if (boogiePoolActive == true) {
                boogiePerBlock = 25 * SOFT_LAUNCH_BOOGIE_PER_BLOCK;
            }
        }

        // Global pool information
        poolMetadata[0] = totalSupply;
        poolMetadata[1] = totalLPSupply;
        poolMetadata[2] = stakedLPSupply;
        poolMetadata[3] = tokenPrice;
        poolMetadata[4] = lpTokenPrice;
        poolMetadata[5] = totalLiquidityValue;
        poolMetadata[6] = boogiePerBlock;
        poolMetadata[7] = pool.token.decimals();

        // User pool information
        if (_pid != 0 || boogiePoolActive == true) {
            UserInfo memory _userInfo = userInfo[_pid][_user];
            poolMetadata[8] = pool.token.balanceOf(_user);
            poolMetadata[9] = pool.token.allowance(_user, address(this));
            poolMetadata[10] = pool.lpToken.balanceOf(_user);
            poolMetadata[11] = pool.lpToken.allowance(_user, address(this));
            poolMetadata[12] = _userInfo.staked;
            poolMetadata[13] = _pendingBoogie(_pid, _user);
            //poolMetadata[14] = _pendingUni(_pid, _user);
            poolMetadata[15] = _userInfo.claimed;
            //poolMetadata[16] = _userInfo.uniClaimed;
        }
    }

    // View function to see all of the extra pool data (token prices, total staked supply, total liquidity value, etc) on the frontend
    function _getAllPoolMetadataFor(address _user) internal view returns (uint[17][] memory allMetadata) {
        uint256 length = poolInfo.length;

        // Extra data for the frontend
        allMetadata = new uint[17][](length);

        // We'll need the current BOOGIE price to make our calculations
        uint256 boogiePrice = _getBoogiePrice();

        for (uint256 pid = 0; pid < length; ++pid) {
            allMetadata[pid] = _getPoolMetadataFor(pid, _user, boogiePrice);
        }
    }

    // View function to see all of the data for all pools on the frontend
    function getAllPoolInfoFor(address _user) external view returns (address[] memory tokens, address[] memory lpTokens, bool[] memory isUnis, uint[] memory aprs, uint[] memory lastBoogieRewardBlocks, uint[2][] memory accTokensPerShares, uint[17][] memory metadatas) {
        (tokens, lpTokens, isUnis, aprs, lastBoogieRewardBlocks, accTokensPerShares) = _getAllPoolData();
        metadatas = _getAllPoolMetadataFor(_user);
    }

    // Internal view function to get the current price of BOOGIE on Uniswap
    function _getBoogiePrice() internal view returns (uint256 boogiePrice) {
        uint256 boogieBalance = boogie.balanceOf(boogiePoolAddress);
        if (boogieBalance > 0) {
            boogiePrice = 10**18 * weth.balanceOf(boogiePoolAddress) / boogieBalance;
        }
    }

    // View function to show all relevant platform info on the frontend
    function getAllInfoFor(address _user) external view returns (bool poolActive, uint256[8] memory info) {
        poolActive = boogiePoolActive;
        info[0] = blocksUntilLaunch();
        info[1] = blocksUntilBoogiePoolCanBeActivated();
        info[2] = blocksUntilSoftLaunchEnds();
        info[3] = boogie.totalSupply();
        info[4] = _getBoogiePrice();
        if (boogiePoolActive) {
            info[5] = IERC20(boogiePoolAddress).balanceOf(address(boogie));
        }
        info[6] = boogieSentToRave;
        info[7] = boogie.balanceOf(_user);
    }
    
    // View function to see the total number of tokens claimed from all pools for a particular user, used by Referral.sol
    function getTotalNumTokensClaimed(address _user) external view returns (uint256 numTokensClaimed) {
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo memory user = userInfo[pid][_user];
            numTokensClaimed += user.claimed;
        }
    }

    // View function to see the number of blocks remaining until launch on the frontend
    function blocksUntilLaunch() public view returns (uint256) {
        if (block.number >= startBlock) return 0;
        else return startBlock.sub(block.number);
    }

    // View function to see the number of blocks remaining until the BOOGIE pool can be activated on the frontend
    function blocksUntilBoogiePoolCanBeActivated() public view returns (uint256) {
        uint256 boogiePoolActivationBlock = startBlock + SOFT_LAUNCH_DURATION.div(2);
        if (block.number >= boogiePoolActivationBlock) return 0;
        else return boogiePoolActivationBlock.sub(block.number);
    }

    // View function to see the number of blocks remaining until the Soft Launch ends on the frontend
    function blocksUntilSoftLaunchEnds() public view returns (uint256) {
        uint256 softLaunchEndBlock = startBlock + SOFT_LAUNCH_DURATION;
        if (block.number >= softLaunchEndBlock) return 0;
        else return softLaunchEndBlock.sub(block.number);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = (boogiePoolActive == true ? 0 : 1); pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    // Removed code for the UNI staking rewards contract due to the end of UNI staking
    function updatePool(uint256 _pid) public {
        require(msg.sender == tx.origin || msg.sender == owner() || contractWhitelist[msg.sender] == true, "no contracts"); // Prevent flash loan attacks that manipulate prices.
        
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = _getPoolSupply(_pid);

        // Only update the pool if the max BOOGIE supply hasn't been hit
        if (boogie.maxSupplyHit() != true) {
            
            if ((block.number <= pool.lastBoogieRewardBlock) || (_pid == 0 && boogiePoolActive != true)) {
                return;
            }
            if (lpSupply == 0) {
                pool.lastBoogieRewardBlock = block.number;
                return;
            }

            uint256 boogieReward = _calculateBoogieReward(_pid, lpSupply);

            // Make sure that boogieReward won't push the total supply of BOOGIE past boogie.MAX_SUPPLY()
            uint256 boogieTotalSupply = boogie.totalSupply();
            if (boogieTotalSupply.add(boogieReward) >= boogie.MAX_SUPPLY()) {
                boogieReward = boogie.MAX_SUPPLY().sub(boogieTotalSupply);
            }

            // boogie.mint(devAddress, boogieReward.div(10)); Not minting 10% to the devs like Sushi, Sashimi, and Takeout do

            if (boogieReward > 0) {
                boogie.mint(address(this), boogieReward);
                pool.accBoogiePerShare = pool.accBoogiePerShare.add(boogieReward.mul(1e12).div(lpSupply));
                pool.lastBoogieRewardBlock = block.number;
            }

            if (boogie.maxSupplyHit() == true) {
                rave.activate();
            }
        }
    }

    // Internal view function to get the amount of LP tokens staked in the specified pool
    function _getPoolSupply(uint256 _pid) internal view returns (uint256 lpSupply) {
        PoolInfo memory pool = poolInfo[_pid];
        lpSupply = pool.lpToken.balanceOf(address(this));
    }

    // Deposits LP tokens in the specified pool to start earning the user BOOGIE
    function deposit(uint256 _pid, uint256 _amount) external {
        depositFor(_pid, msg.sender, _amount);
    }

    // Deposits LP tokens in the specified pool on behalf of another user
    function depositFor(uint256 _pid, address _user, uint256 _amount) public {
        require(msg.sender == tx.origin || contractWhitelist[msg.sender] == true, "no contracts");
        require(boogie.maxSupplyHit() != true, "pools closed");
        require(_pid != 0 || boogiePoolActive == true, "boogie pool not active");
        require(_amount > 0, "deposit something");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // The sender needs to give approval to the Bar contract for the specified amount of the LP token first
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        // Claim any pending BOOGIE and UNI
        _claimRewardsFromPool(_pid, _user);
        
        // Each pool has a 10% staking fee. If staking in the BOOGIE-ETH pool, 100% of the fee gets permanently locked in the BOOGIE contract (gives BOOGIE liquidity forever).
        // If staking in any other pool, 100% of the fee is used to buyback BOOGIE which is sent to the Rave staking contract where it will start getting distributed to stakers after the max supply is hit
        // The team is never minted or rewarded BOOGIE for any reason to keep things as fair as possible.
        uint256 stakingFeeAmount = _amount.div(10);
        uint256 remainingUserAmount = _amount.sub(stakingFeeAmount);

        // The user is depositing to the BOOGIE-ETH pool so permanently lock all of the LP tokens from the staking fee in the BOOGIE contract
        if (_pid == 0) {
            pool.lpToken.transfer(address(boogie), stakingFeeAmount);
        } else {
            // Remove the liquidity from the pool
            uint256 deadline = block.timestamp + 5 minutes;
            pool.lpToken.safeApprove(address(uniswapRouter), 0);
            pool.lpToken.safeApprove(address(uniswapRouter), stakingFeeAmount);
            uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(address(pool.token), stakingFeeAmount, 0, 0, address(this), deadline);

            // Swap the ERC-20 token for ETH
            uint256 tokensToSwap = pool.token.balanceOf(address(this));
            require(tokensToSwap > 0, "bad token swap");
            address[] memory poolPath = new address[](2);
            poolPath[0] = address(pool.token);
            poolPath[1] = address(weth);
            pool.token.safeApprove(address(uniswapRouter), 0);
            pool.token.safeApprove(address(uniswapRouter), tokensToSwap);
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensToSwap, 0, poolPath, address(this), deadline);

            uint256 ethBalanceAfterSwap = address(this).balance;
            //uint256 teamFeeAmount; //No dev fee, unlike Surf

            // If boogiePoolActive == true then perform a buyback of BOOGIE using all of the ETH in the contract and then send it to the Rave staking contract. 
            // Otherwise, the ETH will be used to seed the initial liquidity in the BOOGIE-ETH Uniswap pool when activateBoogiePool is called
            if (boogiePoolActive == true) {
                require(ethBalanceAfterSwap > 0, "bad eth swap");

                // The BOOGIE-ETH pool is active, so let's use the ETH to buyback BOOGIE and send it to the Rave staking contract
                uint256 boogieBought = _buyBoogie(ethBalanceAfterSwap);

                // Send the BOOGIE rewards to the Rave staking contract
                boogieSentToRave += boogieBought;
                _safeBoogieTransfer(address(rave), boogieBought);
            }
        }

        // Add the remaining amount to the user's staked balance
        uint256 _currentRewardDebt = 0;
        if (boogiePoolActive != true) {
            _currentRewardDebt = user.staked.mul(pool.accBoogiePerShare).div(1e12).sub(user.rewardDebt);
        }
        user.staked = user.staked.add(remainingUserAmount);
        user.rewardDebt = user.staked.mul(pool.accBoogiePerShare).div(1e12).sub(_currentRewardDebt);

        emit Deposit(_user, _pid, _amount);
    }

    // Internal function that buys back BOOGIE with the amount of ETH specified
    function _buyBoogie(uint256 _amount) internal returns (uint256 boogieBought) {
        uint256 ethBalance = address(this).balance;
        if (_amount > ethBalance) _amount = ethBalance;
        if (_amount > 0) {
            uint256 deadline = block.timestamp + 5 minutes;
            address[] memory boogiePath = new address[](2);
            boogiePath[0] = address(weth);
            boogiePath[1] = address(boogie);
            uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: _amount}(0, boogiePath, address(this), deadline);
            boogieBought = amounts[1];
        }
        if (boogieBought > 0) emit BoogieBuyback(msg.sender, _amount, boogieBought);
    }

    // Internal function to claim earned BOOGIE and UNI from Bar. Claiming won't work until boogiePoolActive == true
    function _claimRewardsFromPool(uint256 _pid, address _user) internal {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (boogiePoolActive != true || user.staked == 0) return;

        uint256 userBoogiePending = user.staked.mul(pool.accBoogiePerShare).div(1e12).sub(user.rewardDebt);
        if (userBoogiePending > 0) {
            user.claimed += userBoogiePending;
            _safeBoogieTransfer(_user, userBoogiePending);
        }

        if (userBoogiePending > 0) {
            emit Claim(_user, _pid, userBoogiePending, 0); //userUniPending
        }
    }

    // Claim all earned BOOGIE and UNI from a single pool. Claiming won't work until boogiePoolActive == true
    function claim(uint256 _pid) public {
        require(boogiePoolActive == true, "boogie pool not active");
        updatePool(_pid);
        _claimRewardsFromPool(_pid, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        user.rewardDebt = user.staked.mul(pool.accBoogiePerShare).div(1e12);
    }

    // Claim all earned BOOGIE and UNI from all pools. Claiming won't work until boogiePoolActive == true
    function claimAll() public {
        require(boogiePoolActive == true, "boogie pool not active");

        uint256 totalPendingBoogieAmount = 0;
        
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.staked > 0) {
                updatePool(pid);

                PoolInfo storage pool = poolInfo[pid];
                uint256 accBoogiePerShare = pool.accBoogiePerShare;

                uint256 pendingPoolBoogieRewards = user.staked.mul(accBoogiePerShare).div(1e12).sub(user.rewardDebt);
                user.claimed += pendingPoolBoogieRewards;
                totalPendingBoogieAmount = totalPendingBoogieAmount.add(pendingPoolBoogieRewards);
                user.rewardDebt = user.staked.mul(accBoogiePerShare).div(1e12);
            }
        }
        require(totalPendingBoogieAmount > 0, "nothing to claim"); 

        if (totalPendingBoogieAmount > 0) _safeBoogieTransfer(msg.sender, totalPendingBoogieAmount);
        emit ClaimAll(msg.sender, totalPendingBoogieAmount, 0); //totalPendingUniAmount
    }

    // Withdraw LP tokens and earned BOOGIE from Bar. Withdrawing won't work until boogiePoolActive == true
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(boogiePoolActive == true, "boogie pool not active");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0 && user.staked >= _amount, "withdraw: not good");
        
        updatePool(_pid);

        // Claim any pending BOOGIE
        _claimRewardsFromPool(_pid, msg.sender);
        PoolInfo memory pool = poolInfo[_pid];

        user.staked = user.staked.sub(_amount);
        user.rewardDebt = user.staked.mul(pool.accBoogiePerShare).div(1e12);

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Convenience function to allow users to migrate all of their staked BOOGIE-ETH LP tokens from Bar to the Rave staking contract after the max supply is hit. Migrating won't work until rave.active() == true
    function migrateBOOGIELPtoRave() public {
        require(rave.active() == true, "rave not active");
        UserInfo storage user = userInfo[0][msg.sender];
        uint256 amountToMigrate = user.staked;
        require(amountToMigrate > 0, "migrate: not good");
        
        updatePool(0);

        // Claim any pending BOOGIE
        _claimRewardsFromPool(0, msg.sender);

        user.staked = 0;
        user.rewardDebt = 0;

        poolInfo[0].lpToken.safeApprove(address(rave), 0);
        poolInfo[0].lpToken.safeApprove(address(rave), amountToMigrate);
        rave.stakeFor(msg.sender, amountToMigrate);
        emit Withdraw(msg.sender, 0, amountToMigrate);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 staked = user.staked;
        require(staked > 0, "no tokens");

        PoolInfo memory pool = poolInfo[_pid];
        
        user.staked = 0;
        user.rewardDebt = 0;

        pool.lpToken.safeTransfer(address(msg.sender), staked);
        emit EmergencyWithdraw(msg.sender, _pid, staked);
    }

    // Internal function to safely transfer BOOGIE in case there is a rounding error
    function _safeBoogieTransfer(address _to, uint256 _amount) internal {
        uint256 boogieBalance = boogie.balanceOf(address(this));
        if (_amount > boogieBalance) _amount = boogieBalance;
        boogie.transfer(_to, _amount);
    }

    // Creates the BOOGIE-ETH Uniswap pool and adds the initial liqudity that will be permanently locked. Can be called by anyone, but no sooner than 500 blocks after launch. 
    function activateBoogiePool() public {
        require(boogiePoolActive == false, "already active");
        require(msg.sender == tx.origin, "no contracts");
        require(block.number > startBlock + SOFT_LAUNCH_DURATION.div(2), "too soon");
        uint256 initialEthLiquidity = address(this).balance;
        require(initialEthLiquidity > 0, "need ETH");

        massUpdatePools();

        // The ETH raised from the staking fees collected before boogiePoolActive == true is used to seed the ETH side of the BOOGIE-ETH Uniswap pool.
        // Mint 500,000 new BOOGIE to seed the BOOGIE liquidity in the BOOGIE-ETH Uniswap pool + referral bonus
        uint256 initialMintAmount = 500000 * 10**18;
        boogie.mint(address(this), initialMintAmount);

        uint256 initialBoogieLiquidity = initialMintAmount.div(2); //Allocate 250k tokens to seed the BOOGIE liquidity in the BOOGIE-ETH Uniswap pool
        uint256 referralBonusAmount = initialMintAmount.div(2); //Allocate 250k tokens for referral bonus

        // Add the liquidity to the BOOGIE-ETH Uniswap pool
        boogie.approve(address(uniswapRouter), initialBoogieLiquidity);
        ( , , uint256 lpTokensReceived) = uniswapRouter.addLiquidityETH{value: initialEthLiquidity}(address(boogie), initialBoogieLiquidity, 0, 0, address(this), block.timestamp + 5 minutes);

        // Activate the BOOGIE-ETH pool
        initialBoogiePoolETH = initialEthLiquidity;
        boogiePoolActive = true;

        // Permanently lock the LP tokens in the BOOGIE contract
        IERC20(boogiePoolAddress).transfer(address(boogie), lpTokensReceived);
        //Send the other half of the tokens to the referral bonus contract
        _safeBoogieTransfer(referralAddress, referralBonusAmount);

        emit BoogiePoolActive(msg.sender, initialBoogieLiquidity, initialEthLiquidity);
    }

    //////////////////////////
    // Governance Functions //
    //////////////////////////
    // The following functions can only be called by the owner (the BOOGIE token holder governance contract)

    // Sets the address of the Rave staking contract that bought BOOGIE gets sent to for distribution to stakers once the max supply is hit
    function setRaveContract(Rave _rave) public onlyOwner {
        rave = _rave;
    }

    // Sets the address of the referral contract that 250k tokens are sent to once activateBoogiePool() is called 
    function setReferralAddress(address _address) public onlyOwner {
        referralAddress = _address;
    }

    // Sets the new starting block, used for if I need to delay the launch since I don't want to launch in the middle of a BTC correction
    //function setStartingBlock(uint256 _startBlock) public onlyOwner {
    //    require(_startBlock > block.number); //The starting block must be after the current block
    //    startBlock = _startBlock;
    //}

    // Add a new LP Token pool
    function addPool(address _token, address _lpToken, uint256 _apr) public onlyOwner {
        require(boogie.maxSupplyHit() != true);
        require(existingPools[_lpToken] != true, "pool exists");

        _addPool(_token, _lpToken);
        if (_apr != DEFAULT_APR) poolInfo[poolInfo.length-1].apr = _apr;
    }

    // Update the given pool's APR
    function setApr(uint256 _pid, uint256 _apr) public onlyOwner {
        require(boogie.maxSupplyHit() != true);
        updatePool(_pid);
        poolInfo[_pid].apr = _apr;
    }

    // Add a contract to the whitelist so that it can interact with Bar. This is needed for the Aegis pool contract to be able to stake on behalf of everyone in the pool.
    // We want limited interaction from contracts due to the growing "flash loan" trend that can be used to dramatically manipulate a token's price in a single block.
    function addToWhitelist(address _contractAddress) public onlyOwner {
        contractWhitelist[_contractAddress] = true;
    }

    // Remove a contract from the whitelist
    function removeFromWhitelist(address _contractAddress) public onlyOwner {
        contractWhitelist[_contractAddress] = false;
    }
}